/***************************************************************************************************************************************
 * NAME   : ValidateCompletedWO_WOHelper
 * DESCRIPTION  : Class to Validate Completed Work Order
 *           DCP-49669 : To validate the Completion of a WO with Elevation status as Open
 *    
 * @AUTHOR : Vatsal Shah
 * @DATE   : 28-February-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vatsal Shah            28-February-2022       Initial Version
 * Chaitanya Karthik      28-August-2023         CMCM-1355 - Created a new method validateInstalledProductStatus.
 * Nancy                  02-13-2024             CMCM-5307: Work Order Trigger Query Optimization
 */

public with sharing class ValidateCompletedWO_WOHelper {
  
    public static final String STRING_STATUS = 'Open';
    public static final String HOT_SITE = 'Hot Site';
    //CMCM-5307 - Start
    public static List<Elevations__c> elevationList = new List<Elevations__c>();
    public static List<Elevations__c> lstElevCategory = new List<Elevations__c>();
    public static Map<Id, SVMXC__Installed_Product__c> mapIPIdToIPRecord = new Map<Id, SVMXC__Installed_Product__c>();
    //CMCM-5307 - End
    /*
    *  @AUTHOR:  Vatsal  
    *  @DESCRIPTION: Method to Validate Completion of Work Order for Elevations with Elevation Status = 'Open'
    *  @PARAM :  Sobject : List of Sobject and Map of Sobject      
    *  @RETURN:  void
    */
    
    public static void verifyWorkOrderStatus(List<Sobject> records, Map<Id, Sobject> oldRecords) {
        Set<Id> workOrderIdSet = new Set<Id>();
        set<Id> elevationIds =  new set<Id>();
        set<Id> setElevationIds =  new set<Id>();

        for(SVMXC__Service_Order__c sObjRecord : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c oldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(sObjRecord.Id));
            if(sObjRecord.SVMXC__Order_Status__c == 'Completed' && sObjRecord.SVMXC__Order_Status__c != oldWorkOrder.SVMXC__Order_Status__c){
                workOrderIdSet.add(sObjRecord.Id);
                if(sObjRecord.Technical_Elevation__c != NULL){
                    elevationIds.add(sObjRecord.Technical_Elevation__c);
                }
                if(sObjRecord.Account_Elevation__c != NULL){
                    elevationIds.add(sObjRecord.Account_Elevation__c);
                }
            }
            if(sObjRecord.Account_Elevation__c != NULL){
                setElevationIds.add(sObjRecord.Account_Elevation__c);
            }

        }

        //CMCM-5307 - Add empty check for WO trigger Optimization
        if(elevationList.isEmpty()  || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            ElevationsSelector objElevationSelector = new ElevationsSelector();
            elevationList =  objElevationSelector.selectElevationByElevationStatus(elevationIds, STRING_STATUS);
        }
        if(lstElevCategory.isEmpty()  || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            ElevationsSelector objElevSelector = new ElevationsSelector();
            lstElevCategory =  objElevSelector.selectElevationByCategory(setElevationIds, HOT_SITE);
        }
        
        Map<Id,Elevations__c> mapRelatedElevations = new Map<Id,Elevations__c> (elevationList);
        Map<Id,Elevations__c> mapNewRelatedElevations = new Map<Id,Elevations__c> (lstElevCategory);
        for(SVMXC__Service_Order__c sObjRecord : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c oldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(sObjRecord.Id));
            if(sObjRecord.SVMXC__Order_Status__c == 'Completed' && sObjRecord.SVMXC__Order_Status__c != oldWorkOrder.SVMXC__Order_Status__c 
            && ((sObjRecord.Technical_Elevation__c != Null && mapRelatedElevations.containsKey(sObjRecord.Technical_Elevation__c)) || 
                (sObjRecord.Account_Elevation__c != Null && mapRelatedElevations.containsKey(sObjRecord.Account_Elevation__c))))
            {
                sObjRecord.addError(system.label.Elevation_Work_Order_Validation_Message);
            }
            if(!lstElevCategory.isEmpty() && lstElevCategory != null && sObjRecord.Account_Elevation__c != null){
                if((sObjRecord.Business_Impact_to_Customer__c == null || String.isBlank(sObjRecord.Business_Impact_to_Customer__c) ||
                    sObjRecord.Business_Impact_to_Illumina__c == null || String.isBlank(sObjRecord.Business_Impact_to_Illumina__c) ) &&
                    mapNewRelatedElevations.get(sObjRecord.Account_Elevation__c).Elevation_Category__c == HOT_SITE){                    
                    sObjRecord.addError(system.label.Elevation_Hot_Site_Validation_Message);
                }
            }
        }

    }

    /*******************************************************************************************************
    * @description DCP-47686 OQ PQ IQ/OQ required: Checkbox instead of Labor Line addition
    * @param records New list of records
    * @return
    * @example
    */
    public static void validateCompletedWOLaborLines(List<Sobject> records, Map<Id, Sobject> oldRecords, List<SVMXC__Service_Order_Line__c> lstWDsForCompletionWOs) {
        Map<String, Boolean> workDetailsValidateMap = new Map<String, Boolean>();
        Map<Id, SVMXC__Service_Order__c> completedWOWithQRMap = new Map<Id, SVMXC__Service_Order__c>();

        completedWOWithQRMap = generateCompletedMapWithQR(records, oldRecords);

        if(!completedWOWithQRMap.isEmpty()) {
            for(SVMXC__Service_Order_Line__c workDetail : lstWDsForCompletionWOs) {
                if(new List<String> {WorkOrders.STRING_WOD_ACTIVITY_TYPE_PQ, WorkOrders.STRING_WOD_ACTIVITY_TYPE_IQ_OQ, WorkOrders.STRING_WOD_ACTIVITY_TYPE_OQ}.contains(workDetail.SVMXC__Activity_Type__c) 
                    && !WorkOrders.STRING_WORK_DETAIL_LINE_STATUS_CANCELED.equals(workDetail.SVMXC__Line_Status__c) 
                    && workDetail.Labor_Numeric__c > 0) {

                    validateCompletedWOLines(workDetail,workDetailsValidateMap);
                }
            }

            for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>) completedWOWithQRMap.values()) {
                String qrValues = '';
                String activityTypes = '';

                qrValues = processQRValues(objWorkOrder, workDetailsValidateMap);
                activityTypes = qrValues.replace(' ' + WorkOrders.STRING_REQUIRED, '');
                if(String.isNotBlank(qrValues) && String.isNotBlank(activityTypes)) {
                    throwErrorQR(objWorkOrder, qrValues, activityTypes);
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description DCP-47686 OQ PQ IQ/OQ required: Add Error
    * @param objWorkOrder Work Order Record
    * @param qualReqValue Value from Qualification Requirements field
    * @param activityTypes Value from Activity Type on Work Details
    * @return Qualification Requirements Message
    * @example
    */
    public static String processQRValues(SVMXC__Service_Order__c objWorkOrder, Map<String, Boolean> workDetailsValidateMap) {
        String qrValues = '';

        for(String qrValue : objWorkOrder.Qualification_Requirements__c.split(WorkOrders.SEMICOLON)) {
            String activityType = qrValue.replace(WorkOrders.STRING_REQUIRED, '').trim();
            if(!workDetailsValidateMap.containsKey(objWorkOrder.Id + WorkOrders.SEMICOLON + activityType)) {
                qrValues += String.isBlank(qrValues) ? qrValue : ', ' + qrValue;
            }
        }
        return qrValues;
    }

    /*******************************************************************************************************
    * @description DCP-47686 OQ PQ IQ/OQ required: Add Error
    * @param objWorkOrder Work Order Record
    * @param qualReqValue Value from Qualification Requirements field
    * @param activityTypes Value from Activity Type on Work Details
    * @return
    * @example
    */
    public static void throwErrorQR(SVMXC__Service_Order__c objWorkOrder, String qrValues,  String activityTypes) {
        String errorTypesQR = 'OQ or type IQ/OQ';
        
        if(qrValues.contains(WorkOrders.STRING_WOD_ACTIVITY_TYPE_OQ) && !qrValues.contains(WorkOrders.STRING_WOD_ACTIVITY_TYPE_IQ_OQ)) {
            String laborlinesType = activityTypes.replace(WorkOrders.STRING_WOD_ACTIVITY_TYPE_OQ, errorTypesQR);
            objWorkOrder.addError(String.format(Label.MandatoryLaborLineError, new List<String>{qrValues, activityTypes, laborlinesType}));
        } else {
            objWorkOrder.addError(String.format(Label.MandatoryLaborLineError, new List<String>{qrValues, activityTypes, activityTypes}));
        }
    }  
    

    /*******************************************************************************************************
    * @description DCP-47686 OQ PQ IQ/OQ required: Add Error
    * @param objWorkOrder Work Order Record
    * @param qualReqValue Value from Qualification Requirements field
    * @param activityTypes Value from Activity Type on Work Details
    * @return
    * @example
    */
    public static Map<Id, SVMXC__Service_Order__c> generateCompletedMapWithQR(List<Sobject> records, Map<Id, Sobject> oldRecords) {
        Map<Id, SVMXC__Service_Order__c> completedWOWithQRMap = new Map<Id, SVMXC__Service_Order__c>();

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>) records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));

            if(objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c 
                && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED
                && String.isNotBlank(objWorkOrder.Qualification_Requirements__c)) {
                    completedWOWithQRMap.put(objWorkOrder.Id, objWorkOrder);
            }
        }
        return completedWOWithQRMap;
    }

    /*******************************************************************************************************
    * @description DCP-47686 OQ PQ IQ/OQ required: Checkbox instead of Labor Line addition
    * @param workDetail - SVMXC__Service_Order_Line__c
    * @return - void
    */
    private static void validateCompletedWOLines(SVMXC__Service_Order_Line__c workDetail,  Map<String, Boolean> workDetailsValidateMap) {

        String key = workDetail.SVMXC__Service_Order__c + WorkOrders.SEMICOLON + workDetail.SVMXC__Activity_Type__c;
        if(!workDetailsValidateMap.containsKey(key)) {
            workDetailsValidateMap.put(key, true);
        }
        if(workDetail.SVMXC__Activity_Type__c == WorkOrders.STRING_WOD_ACTIVITY_TYPE_IQ_OQ) {
            key = workDetail.SVMXC__Service_Order__c + WorkOrders.SEMICOLON + WorkOrders.STRING_WOD_ACTIVITY_TYPE_OQ;
            if(!workDetailsValidateMap.containsKey(key)) {
                workDetailsValidateMap.put(key , true);
            }    
        }
    }
    
    /*******************************************************************************************************
    * @description CMCM-1355 - Validate if Work Order Status is changing to 'Completed' and if IP does not have status of 'Scrapped' , 'Decommissioned' or 'Returned' 
    * 
    */
    
    public static void validateInstalledProductStatus(List<SObject> records, Map<Id, SObject> oldRecords) {
        set<Id> setInstalledProductIds = New Set<Id>();
       
    for (SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>) records) {
        if(objWorkOrder.SVMXC__Component__c != NULL){
        setInstalledProductIds.add(objWorkOrder.SVMXC__Component__c);
        }
    }    
    //CMCM-5307 - Add empty check for WO trigger Optimization 
    if(mapIPIdToIPRecord.isEmpty()  || Feature.isOn(System.label.Feature_Work_Order_Optimization)){           
        mapIPIdToIPRecord = new Map<Id, SVMXC__Installed_Product__c>(new InstalledProductsSelector().selectInstalledProductsFromIds(setInstalledProductIds));
    }
    
    for (SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>) records) {
        SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c) (oldRecords.get(objWorkOrder.Id));
 
            SVMXC__Installed_Product__c objInstalledProduct = mapIPIdToIPRecord.get(objWorkOrder.SVMXC__Component__c);

        if (objInstalledProduct != null &&
            objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c &&
            objWorkOrder.SVMXC__Order_Status__c == 'Completed' &&
            objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeTradeinEOL &&
            (objInstalledProduct.SVMXC__Status__c != 'Scrapped' && objInstalledProduct.SVMXC__Status__c != 'Decommissioned' && objInstalledProduct.SVMXC__Status__c != 'Returned')) {
            objWorkOrder.addError(System.label.WorkOrderIPStatusValidation);
        }
     }
    }
}
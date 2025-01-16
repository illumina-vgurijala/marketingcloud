/**
* @author Sheikh Shahnawaz
* @date 20th June 2022
*
* @description DCP-43632 Helper Class for Work Order Trigger to validate Install Work Order has mandatory IB attributes information 
* filled when completing it
* @testclass: TestValidateInstallWOOnComplete

* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhinav                  01-Sep-2022            DCP-56521: updating validateInstallWorkOrderOnComplete for new TA Template and fields
* Shivani                  24-11-2022             DCP-57074: Add new family and use custom metadata Code Parameters for Required TA
* Rohan                    22-Dec-2022            DCP-58075: Bypass Needs Updating Validation for Acceptance Forecast of 0% - Instrument DOA
* Saikiran                 01-Aug-2023            CMCM261  :  validation for required IB Technical Attributes at PM Work Order Completion.
* Nancy                    13-Feb-2024            CMCM-5307 Work Order Trigger Query Optimization
* Yash                     16-Dec-2024            CMCM-10597 Work Order Trigger Optimization part3
*/ 

public with sharing class ValidateInstallWOOnComplete_WOHelper {
    public static final String STRING_WORK_ORDER_STATUS_COMPLETED = 'Completed';
    public static final String INSTALLATION_TYPE = 'Installation';
    //DCP-58075 start
    public static final String ACCEPTANCE_FORECAST =  '0% - Instrument DOA';
    //DCP-58075 end

    //CMCM-5307 - Start
    public static List<SVMXC__Service_Order__c> workOrderList = new List<SVMXC__Service_Order__c>();
    public static List<SVMXC__SM_Attributes_Template__c>  listTemplates = new List<SVMXC__SM_Attributes_Template__c>();
    public static List<SVMXC__Installed_Product__c> listOfRetrievedIP = new List<SVMXC__Installed_Product__c>();
    //CMCM-5307 - End
    public static final Map<String,List<String>> MAP_TEMPLATE_MANDATORY_FIELDS = new Map<String,List<String>> ();
    /**
     *  DCP-43632
     *  @author Sheikh Shahnawaz
     *  @description -Validate Install Work Order when completing
     *  @modified by Abhinav on 1-Sep-2022 for DCP-56521
     *  @modified by Sai on 1-Aug-2023 for CMCM-261
     **/
    public static void validateInstallWorkOrderOnComplete(Map<Id, SObject> oldRecords, List<sObject> records) {
        Set<Id> setInstallProductId = new Set<Id>();
        // Start - CMCM-10597
        List<SVMXC__Service_Order__c> completedWOs = new List<SVMXC__Service_Order__c> ();
        for(SVMXC__Service_Order__c woRecord : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c oldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(woRecord.Id));
            if(woRecord.SVMXC__Order_Status__c != oldWorkOrder.SVMXC__Order_Status__c &&
                (woRecord.SVMXC__Order_Status__c == 'Closed' || woRecord.SVMXC__Order_Status__c == STRING_WORK_ORDER_STATUS_COMPLETED) &&
                woRecord.SVMXC__Component__c!=null &&
                (woRecord.SVMXC__Order_Type__c == INSTALLATION_TYPE|| woRecord.SVMXC__Order_Type__c == Label.WorkOrderTypeBillableInstall || (woRecord.SVMXC__Order_Type__c == 'Preventative Maintenance')))
            {
                completedWOs.add(woRecord); 
            }
        }
        // End - CMCM-10597

        if(!completedWOs.isEmpty() && completedWOs != null) {
            //START - DCP-57074
            Map<String, String> mapFamilyToTemplate = new Map<String, String>();  //Map of Product Family to Template Name
            Set<String> setProductFamilyName = new Set<String>(); 

            //START - CMCM-261 - Implemented Required_TA_Families which has all in a asingle CMD and creating a Map.
            List<Code_Parameter__mdt> cParam = new CodeParametersSelector().selectCodeParameterByDeveloperNameLike('Required_TA_Families');
            Code_Parameter__mdt codeParam = cParam[0];
            List<String> picklistValues = codeParam.PickListValue__c.split(',');
            List<String> textValues = codeParam.Values_Text__c.split(',');
            
            if(picklistValues.size() == textValues.size()) {
                for(Integer i=0; i<picklistValues.size(); i++){
                    setProductFamilyName.add(picklistValues[i].trim());
                    mapFamilyToTemplate.put(picklistValues[i].trim(), textValues[i].trim());
                }
            }
            //END - DCP-57074
            Set<Id> setWorkOrderIds = new Set<Id>();
            for(SVMXC__Service_Order__c sObjRecord : completedWOs){
                setWorkOrderIds.add(sObjRecord.Id);
            }
            WorkOrdersSelector workOrdersSelector = new WorkOrdersSelector();
            //CMCM-5307 - Add empty check for WO trigger Optimization
            if (workOrderList.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                workOrderList = WorkOrdersSelector.selectWorkOrdersFromIds(setWorkOrderIds);
            }
            Map<Id, SVMXC__Service_Order__c> mapWOIdToWO = new Map<Id, SVMXC__Service_Order__c>();
            for (SVMXC__Service_Order__c workOrder : workOrderList) {
                mapWOIdToWO.put(workOrder.Id, workOrder);
            }
            //END - CMCM-261

            for(SVMXC__Service_Order__c sObjRecord : completedWOs) {
                SVMXC__Service_Order__c oldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(sObjRecord.Id));
                // added one statement (sObjRecord.SVMXC__Order_Type__c == Label.WorkOrderTypeBillableInstall) by Dhairya Shah for CMCM - 9198
                if(sObjRecord.SVMXC__Order_Status__c != oldWorkOrder.SVMXC__Order_Status__c && (sObjRecord.SVMXC__Order_Status__c == 'Closed' || sObjRecord.SVMXC__Order_Status__c == STRING_WORK_ORDER_STATUS_COMPLETED)
                && sObjRecord.SVMXC__Component__c!=null && (sObjRecord.SVMXC__Order_Type__c == INSTALLATION_TYPE|| sObjRecord.SVMXC__Order_Type__c == Label.WorkOrderTypeBillableInstall || (sObjRecord.SVMXC__Order_Type__c == 'Preventative Maintenance' && MapWOIdToWO.get(sObjRecord.Id).SVMXC__Component__r.SVMXC__Status__c == 'Installed') )){
                    setInstallProductId.add(sObjRecord.SVMXC__Component__c);
                }
            }
            //CMCM-5307 - Add empty check for WO trigger Optimization
            if(!setInstallProductId.isEmpty()){
                if (listTemplates.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                    listTemplates = new SMAttributesTemplateSelector().getTemplates(new Set<String>(mapFamilyToTemplate.values()));
                }
                for(SVMXC__SM_Attributes_Template__c objTemplate : listTemplates){
                    string strJson = objTemplate.SVMXC__SM_Template_Json__c;
                    ValidateInstallWOOnComplete_WOHelper.TechnicalAttributeTemplateWrapper wrapper = (TechnicalAttributeTemplateWrapper)JSON.deserialize( strJson , TechnicalAttributeTemplateWrapper.class);
                    TechnicalAttributeTemplateWrapper clonedWrapper = new TechnicalAttributeTemplateWrapper();
                    list<TechnicalAttributeFields> clonedlist = new list<TechnicalAttributeFields>();
                    clonedlist.addall(wrapper.fields);
                    clonedWrapper.fields = clonedlist;
                    for(TechnicalAttributeFields objAttrFields : clonedWrapper.fields){
                        retrieveMandatoryFields(objAttrFields,objTemplate);
                    }
                }
                String query = 'Select Id,SVMXC__Product__c ,SVMXC__Product__r.Family, (Select Id,SVMXC__SM_Attr_Name__c,SVMXC__SM_Attr_Value__c from SVMXC__Technical_Attributes__r ),(Select SVMXC__SM_Instance_Template_Id__c,SVMXC__SM_Installed_Product_Id__c,SVMXC__SM_Attr_Payload__c from SVMXC__IB_Attributes_Template_Instance__r) from  SVMXC__Installed_Product__c where Id IN : setInstallProductId AND SVMXC__Product__c!=null AND SVMXC__Product__r.Family IN : setProductFamilyName';   
                //CMCM-5307 - Add empty check for WO trigger Optimization
                if (listOfRetrievedIP .isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                    listOfRetrievedIP = (List<SVMXC__Installed_Product__c>) Database.query(query);
                }
                if(listOfRetrievedIP!=null && !listOfRetrievedIP.isEmpty()) {
                    Set<Id> listOfIpIdsMissingInfo = new Set<Id>();
                    listOfIpIdsMissingInfo = filterInstallProductsWithMissingInfo(listOfRetrievedIP, mapFamilyToTemplate);
                    addErrorMessageToWO(completedWOs,listOfIpIdsMissingInfo);
                }
            }
        }
    }

     /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - @DESCRIPTION -  The methods checks the Install products has mandatory IB Tech Attributes info filled or not.
    **/
    private static void addErrorMessageToWO(List<SVMXC__Service_Order__c> completedWOs, Set<Id> listOfIpIdsMissingInfo) {
        if(listOfIpIdsMissingInfo!=null && !listOfIpIdsMissingInfo.isEmpty()) {
            for(SVMXC__Service_Order__c objWO : completedWOs) {
                if(objWO.SVMXC__Component__c!=null && listOfIpIdsMissingInfo.contains(objWO.SVMXC__Component__c) && objWO.Acceptance_Forecast_in_Current_Quarter__c != ACCEPTANCE_FORECAST){
                    objWO.addError(System.Label.Check_Required_Technical_Attributes_Error_Message);
                }
            }
        }
    }
    /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - @DESCRIPTION -  The methods checks the Install products has mandatory IB Tech Attributes info filled or not.
    **/
    private static Set<Id> filterInstallProductsWithMissingInfo( List<SVMXC__Installed_Product__c> listOfRetrievedIP, Map<String, String> mapFamilyToTemplate) {
        Set<Id> listOfIpIdsMissingInfo = new Set<Id>();
        for(SVMXC__Installed_Product__c objIP : listOfRetrievedIP){
            Boolean isAttributeInfoMissing = false;
            if(objIP.SVMXC__Technical_Attributes__r!=null && !objIP.SVMXC__Technical_Attributes__r.isEmpty()){
                String key = mapFamilyToTemplate.containsKey(objIP.SVMXC__Product__r.Family) ? mapFamilyToTemplate.get(objIP.SVMXC__Product__r.Family) : '';
                for(SVMXC__SM_IB_Technical_Attributes__c objTechAttribute : objIP.SVMXC__Technical_Attributes__r){
                    if(MAP_TEMPLATE_MANDATORY_FIELDS.containsKey(key) && MAP_TEMPLATE_MANDATORY_FIELDS.get(key).contains(objTechAttribute.SVMXC__SM_Attr_Name__c) && (objTechAttribute.SVMXC__SM_Attr_Value__c == null || objTechAttribute.SVMXC__SM_Attr_Value__c == 'Needs Updating' || objTechAttribute.SVMXC__SM_Attr_Value__c == '')){
                        isAttributeInfoMissing = true;
                        break;
                    }
                }
                if(isAttributeInfoMissing){
                    listOfIpIdsMissingInfo.add(objIP.Id);
                    break;
                }
            }else{
                listOfIpIdsMissingInfo.add(objIP.Id);
            }
        }
        return listOfIpIdsMissingInfo;
    }
    /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - @DESCRIPTION -  The methods checks the required fields on the template and add them into a map with template title as key
    **/
    private static void retrieveMandatoryFields(TechnicalAttributeFields objAttrFields, SVMXC__SM_Attributes_Template__c objTemplate ) {
        for(TechnicalAttributes objTechAttr : objAttrFields.technicalAttributes){
            if(objTechAttr.req!=null &&  objTechAttr.req == '1' && (objTechAttr.format=='Picklist' || objTechAttr.format=='Text')) {
                list<String> lstLabels = new List<String>();
                if(MAP_TEMPLATE_MANDATORY_FIELDS.containsKey(objTemplate.SVMXC__SM_Title__c)){
                    lstLabels.addAll(MAP_TEMPLATE_MANDATORY_FIELDS.get(objTemplate.SVMXC__SM_Title__c));
                }
                lstLabels.add(objTechAttr.label);
                MAP_TEMPLATE_MANDATORY_FIELDS.put(objTemplate.SVMXC__SM_Title__c,lstLabels);
            }
        }
        
    }
     /*
     * Description - Wrapper Class TechnicalAttributeTemplateWrapper
     */
    public class TechnicalAttributeTemplateWrapper{
        public List<TechnicalAttributeFields> fields{get;set;}
    }
    /*
     * Description - Wrapper Class TechnicalAttributeFields
     */
    public class TechnicalAttributeFields{
        public String title {get;set;}
        public String description {get;set;}
        public List<TechnicalAttributes> technicalAttributes {get;set;}
    }
    
    /*
     * Description - Wrapper Class TechnicalAttributes
     */
    public class TechnicalAttributes{
        public String label {get;set;}
        public String type {get;set;}
        public String sequence {get;set;}
        public String defaultValue {get;set;}
        public String req {get;set;}
        public String unit {get;set;}
        public String readOnly {get;set;}
        public String format {get;set;}
    }
}
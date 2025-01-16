/***************************************************************************************************************************************
 * NAME   : ServiceUtilityCollection
 * DESCRIPTION  : Collection of reusable utility methods  
 * @AUTHOR : Debalina
 * @DATE   : 08-Jun-2018  
 *  
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Debalina             08-Jun-2018             Initial Version. 
 * Ritika               10-Jun-2018             Added methods for fetchAccountRoles, checkTechniciansCalendar, fetchNextAvilableEngineer. 
 * Debalina             13-Jun-2018             803 Code Review Comments
 * Debalina             14-June-2018            802/803 Code review Changes Customer_Solutions_User__c from Account_Technician_Role__c
 * Veerendra            16-June-2018            817,823 Added Entitlement process for Cases and Work Orders
 * Soumya               10-Sept-2018            Added sendEmailWhenLOASigned() Method
 
 * Biswajeet            25-June-2022            CMSI-69 Instrumentation of class
 * Shivani Jain         22nd August 2022        DCP-50068 Add a new field for handling more products for Missing products Functionality
 * Abhishek Yadav       8th Feb 2024            CMCM-269 product on cases Functionality
 * Abhishek Yadav       4th March 2024          CMCM-273 product on cases Functionality
 * Namrata              26th Feb 2024           INC0521085-Contract Coverage Checkbox on Case
 * Dhairya              2nd April 2024          CMCM-6517 (CMCM-9)
 * Priya Mukherjee      30th April 2024         CMCM-2846 Modify implementation related to Missing product functionality
****************************************************************************************************************************************/ 
public with sharing class ServiceUtilityCollection {
    private static final String LOG_TITLE = 'ServiceUtilityCollection'; //CMCP-16
    public static final String STRING_LABEL_PARTNER_PRIMARY_FSE = 'Partner Primary Field Service Engineer';
    public static final String STRING_LABEL_PARTNER_SECONDARY_FSE = 'Partner Secondary Field Service Engineer';
    public static final String STRING_LABEL_CHANNEL_PARTNER_REC_TYPE = 'Indirect Partner';
    public static final String STRING_CHANNEL_PARTNER_TYPE_VAD = 'Value Added Distributor';
    public static final String STRING_CHANNEL_PARTNER_TYPE_SP = 'Service Partner';
    public static final String STRING_LABEL_PRIMARY_FSE = 'Primary Field Service Engineer';
    public static final String STRING_LABEL_SECONDARY_FSE = 'Secondary Field Service Engineer';
    public static final String STRING_LABEL_FSM = 'Field Service Manager';
    public static final String STRING_CASE_API_NAME = 'Case';
    public static final String STRING_WORKORDER_API_NAME = 'SVMXC__Service_Order__c';
    public static final String STRING_IPKEY_API_NAME = 'SVMXC__Installed_Product__c';
    public static final String STRING_LOCATION_API_NAME = 'SVMXC__Site__c';
    public static final String STRING_WORK_ORDER_STATUS_ASSIGNED = 'Assigned';
	public static final String STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED = 'Assignment Accepted';
    public static final String STRING_EMAIL_TEMPLATE_API_NAME = 'Work_Order_Send_Signed_LOA';
    public static final String STRING_TO_EMAIL_ADDRESS = 'TestSalesforceServiceAccount@illumina.com';
	public static final String STRING_SAP_INTEGRATION_USER = 'SAP Service Integration';
	public static final string STRING_LABEL_INSTALLATION = 'Installation';
    public static final String STRING_LABEL_PARTNER_PRIMARY_FAS='Partner Primary Field Application Scientist';
    public static final String STRING_LABEL_PRIMARY_FAS='Primary Field Application Scientist';
    public static final String STRING_LABEL_CHANGETYPE_DECREASE = 'Decrease';
    public static final String STRING_LABEL_CHANGETYPE_INCREASE = 'Increase';
    public static final String STRING_DAY_OF_WEEK_FRIDAY = 'Friday';
	public static final String STRING_DAY_OF_WEEK_SATURDAY = 'Saturday';
	public static final String STRING_PRODUCT_C = 'SVMXC__Product__c';
	public static final String STRING_WARNING_MESSAGE_C = 'Warning_Message__c';
	public static final String STRING_PARTS_ONLY = 'Parts Only';
	public static final String STRING_SVMXC_STATUS_ACTIVE = 'Active';
	public static final Integer INTEGER_STRING_LENGTH = 255;
	public static final Integer INTEGER_PROD_LENGTH = 150;
    public static boolean hasupdateran=false;
    public static final String STRING_CASE = 'Case__c';
    public static final String STRING_WORK_ORDER = 'Work_Order__c';
    public static final String STRING_INSTALL_PRODUCT = 'Installed_Product__c';
    public static final String STRING_LOCATION = 'Location__c';
    public static final String STRING_SUBSCRIPTION = 'Subscription__c'; 
    public static final String STRING_ASSOCIATED_PRODUCT = 'Associated_Product__c'; 
    public static final String STRING_SERVICE_CONTRACT ='SVMXC__Service_Contract__c';
    public static List<Group> lstQueues = new List<Group>();

    //CMCM-8086 - Start
    public static List<SVMXC__Site__c> siteRecords = new List<SVMXC__Site__c>();
    public static List<SVMXC__Service_Contract_Products__c> lstCoveredProduct = new List<SVMXC__Service_Contract_Products__c>();
    public static List<SVMXC__Service_Contract_Sites__c> lstCoveredLocation = new List<SVMXC__Service_Contract_Sites__c>();
    public static List<SVMXC__Service_Group_Members__c> lstFieldSupports = new List<SVMXC__Service_Group_Members__c>();
    public static List<Associated_Product__c> listEleAP = new List<Associated_Product__c>();
    public static List<Associated_Product__c> lstEntitlementAPList1 = new List<Associated_Product__c>();
    public static List<Applied_Contract__c> existingEntitlements1 = new  List<Applied_Contract__c>();
    public static List<Applied_Contract__c> existingEntitlements = new  List<Applied_Contract__c>();
    public static List<SVMXC__Service_Contract__c> consumableContractList = new List<SVMXC__Service_Contract__c>();
    public static List <SVMXC__Service_Contract_Products__c> coveredProductList = new List <SVMXC__Service_Contract_Products__c>();
    public static List<SVMXC__PM_Plan__c> lstPMPlan = new List<SVMXC__PM_Plan__c>();
    public static List<SVMXC__Service_Contract__c> lstContracts = new List<SVMXC__Service_Contract__c>();
    public static final String WO_FEATURE_FLAG = 'WOOptimization';
    //CMCM-8086 - End
    public static List<Applied_Contract__c> toBeDeletedAppliedContract = new List<Applied_Contract__c>();   
    public static List<Business_Hours_Setting__mdt> businessHoursSettingMdtList = new List<Business_Hours_Setting__mdt>();
    public static final String STRING_DEFAULT_BUSINESS_HOUR_SETTING = 'Default_Business_Hour_Setting';
    public static List<Event> technicianEventList = new List<Event>();
    public static List<SVMXC__Service_Group_Product__c> activeProductList = new List<SVMXC__Service_Group_Product__c>();
    public static List<SVMXC__Work_Order_Resource__c> lstWOR = new List<SVMXC__Work_Order_Resource__c>();//CMCM-12168

    //CMCM-6541 related to CMCM-9
    public static final String STRING_COMPANY = 'SVMXC__Company__c';
    public static Map<Id,Set<Id>> mapAcntToSiteIds = new Map<Id,Set<Id>>();
    public static List<Applied_Contract__c> lstEntitlement;
    public static boolean recurssionCheck = false;
    //CMCM-273 
    public static Set<id> setCaseIdsCoverage = new Set<Id>();
    //DCP-47396
    public static final Integer INTEGER_MIN_MINUTES = 0; 
    /* METHOD NAME    : getWorkOrderMap
     * DESCRIPTION    : fetch Map<Id, SVMXC__Service_Order__c>
     * RETURN TYPE    : Map<Id, SVMXC__Service_Order__c>
     * PARAMETER      : List<SVMXC__Service_Order__c> lstWorkOrder
    */
    public static Map<Id, SVMXC__Service_Order__c> getWorkOrderMap(List<SVMXC__Service_Order__c> lstWorkOrder){
      ilib_LogEvent.push(LOG_TITLE + '.getWorkOrderMap'); //CMSI-69
      Map<Id, SVMXC__Service_Order__c> mapWOIdToWorkOrder = new Map<Id, SVMXC__Service_Order__c>();
      for(SVMXC__Service_Order__c objWO : lstWorkOrder){
        mapWOIdToWorkOrder.put(objWO.Id,objWO);
      }
      //ilib_LogEvent.message('mapWOIdToWorkOrder :'+mapWOIdToWorkOrder.keyset());
      ilib_LogEvent.message((mapWOIdToWorkOrder != Null ? String.valueof(mapWOIdToWorkOrder.keySet()):'Map is empty')); //CMSI-69
      ilib_LogEvent.pop(); //CMSI-69
      return mapWOIdToWorkOrder;
    }
    
    /* METHOD NAME    : getAPIName
     * DESCRIPTION    : fetch object API name
     * RETURN TYPE    : String object API name 
     * PARAMETER      : sRecordId
    */
    public static String getAPIName(Id idRecordId){
        ilib_LogEvent.push(LOG_TITLE + '.getAPIName'); //CMSI-69
        ilib_LogEvent.info('Record ID :'+idRecordId); //CMSI-69
        String strObjectName = '';
        try{
            Schema.SObjectType sobjectType = idRecordId.getSObjectType();
            strObjectName = sobjectType.getDescribe().getName();
            ilib_LogEvent.message('strObjectName :'+strObjectName); 
        }catch(Exception ex){
             System.debug('Exception on Class : ServiceUtilityCollection - getAPIName, Error : ' +
                ex.getMessage() +
                ' Line Number : ' +
                ex.getLineNumber() +
                ' Cause : ' +
                ex.getCause() +
                ' Type : ' +
                ex.getTypeName());
        }
        ilib_LogEvent.pop(); //CMSI-69
        return strObjectName;
    }

	/*
    * getObjectPrefix 
    * Returns prefix of an object
    * author : Ritika M
    * @params : strObjectAPIName, a string representing the API name of an object
    * @return : prefix of the object
    */
    public static String getObjectPrefix(String strObjectAPIName){
        ilib_LogEvent.push(LOG_TITLE + '.getObjectPrefix'); //CMSI-69
        ilib_LogEvent.info('strObjectAPIName :'+strObjectAPIName); //CMSI-69
        Schema.DescribeSObjectResult sObjectDescribe  = Schema.getGlobalDescribe().get(strObjectAPIName).getDescribe();
        String keyPrefix = sObjectDescribe.getKeyPrefix();
        ilib_LogEvent.info('keyPrefix :'+keyPrefix); //CMSI-69
        ilib_LogEvent.pop(); //CMSI-69
        return keyPrefix;
    }
	
    /*
    * getRecordTypeMap 
    * Returns a map of Record Type Name to Record Type Id
    * author : Debalina
    * @params : strObjectAPIName--> a string representing the API name of an object, 
    * setRecTypes--> Set Record Types needed
    * @return : a map of object fields
    */
    /*public static Map<String,String> getRecordTypeMap(String strObjAPIName, 
                                                      Set<String> setRecTypes){
        Map<String,String> mapRecordTypeNameToId = new Map<String,String>();

        for(RecordType objRecType : [SELECT Id,Name,DeveloperName 
                                         FROM RecordType 
                                         WHERE SobjectType =:strObjAPIName 
                                        AND DeveloperName IN: setRecTypes]){
            mapRecordTypeNameToId.put(objRecType.Name, String.valueOf(objRecType.Id));

        }  
        return mapRecordTypeNameToId;
    }*/

     /*
    * getFieldMap 
    * Returns a map of fields of an object
    * author : Debalina
    * @params : strObjectAPIName, a string representing the API name of an object
    * @return : a map of object fields
    */
    /*public static map<String, Schema.SObjectField> getFieldMap(String strObjectAPIName){
                
        //From the Object Api name retrieving the SObject
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(strObjectAPIName);
        Sobject objectName = targetType.newSObject();
        //grab the sobject that was passed
        Schema.sObjectType objectType = objectName.getSObjectType(); 
        //describe the sobject
        Schema.DescribeSObjectResult sobjectDescribe = objectType.getDescribe(); 
        //get a map of fields for the passed sobject
        map<String, Schema.SObjectField> mapField = sobjectDescribe.fields.getMap(); 
      
        return mapField;
    }*/

    /* METHOD NAME    : getAPIName
     * DESCRIPTION    : fetch object API name
     * RETURN TYPE    : String object API name 
     * PARAMETER      : sRecordId
    */
    public static Id getEmailTemplate(String strDeveloperName){
        ilib_LogEvent.push(LOG_TITLE + '.getEmailTemplate'); //CMSI-69
        ilib_LogEvent.info('strDeveloperName :'+strDeveloperName); //CMSI-69
        Id idEmailTemplate = null;
        try{
            List<EmailTemplate> lstEmailTemplate = [SELECT DeveloperName,
                                                          Id
                                                       FROM EmailTemplate 
                                                       WHERE DeveloperName =:strDeveloperName 
                                                      LIMIT 1];
            if(!lstEmailTemplate.isEmpty()){
                idEmailTemplate = lstEmailTemplate[0].Id;
                //System.debug('idEmailTemplate--->'+idEmailTemplate);
                ilib_LogEvent.info('idEmailTemplate--->'+idEmailTemplate); //CMSI-69
            }
            ilib_LogEvent.pop(); //CMSI-69
        }catch(Exception ex){
             System.debug('Exception on Class : ServiceUtilityCollection - getEmailTemplate, Error : ' +
                ex.getMessage() +
                ' Line Number : ' +
                ex.getLineNumber() +
                ' Cause : ' +
                ex.getCause() +
                ' Type : ' +
                ex.getTypeName());
        }
        
        return idEmailTemplate;
    }
	
	/*
    * getPicklistValuesWrapper 
    * Returns a map of fields of an object
    * author : Debalina
    * @params : strObjectAPIName, a string representing the API name of an object
                strFieldName--> field API name and strSelectLabel --> label select
    * @return : a List of PickListValueWrapper
    */
    /*public static List<PickListValueWrapper> getPicklistValuesWrapper(String strObjectAPIName, String strFieldName,String strSelectLabel){ 
        Map<String, Schema.SObjectField> mapField = getFieldMap(strObjectAPIName);
        Schema.DescribeFieldResult field = mapField.get(strFieldName).getDescribe();
        List<PickListValueWrapper> lstPickvals = new List<PickListValueWrapper>();
        if(field.getType() == Schema.DisplayType.Picklist){
            list<Schema.PicklistEntry> lstPickListValues = mapField.get(strFieldName).getDescribe().getPickListValues(); 
            //for all values in the picklist list
            for (Schema.PicklistEntry a : lstPickListValues) 
                //add the value  to our final list 
                lstPickvals.add(new PickListValueWrapper(a.getValue(), a.getLabel()));
            
        }
        return lstPickvals;
    }*/

    /* METHOD NAME    : getRecordTypeId
     * DESCRIPTION    : fetch RecordTypeId
     * RETURN TYPE    : Id
     * PARAMETER      : strObjName -API name,sRecordTypeName-Record Type name
    */
    public static Id getRecordTypeId(String strObjName, String strRecordTypeName){
        ilib_LogEvent.push(LOG_TITLE + '.getRecordTypeId');//CMSI-69
        ilib_LogEvent.info('strObjName :'+strObjName);//CMSI-69
        ilib_LogEvent.info('strRecordTypeName :'+strRecordTypeName);//CMSI-69
        Id idrecTypeId = null;
        if(String.isNotBlank(strObjName) && String.isNotBlank(strRecordTypeName)){
            idrecTypeId= Schema.getGlobalDescribe().get(strObjName).getDescribe().getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId();
            ilib_LogEvent.info('idrecTypeId--->'+idrecTypeId);//CMSI-69
        }  
        ilib_LogEvent.pop();//CMSI-69
        return idrecTypeId;  
    }

    /* METHOD NAME    : getSelectedRecordTypes
     * DESCRIPTION    : fetch Record Types
     * RETURN TYPE    : Id
     * PARAMETER      : strObjName -API name,sRecordTypeName-Record Type name
    */
    /*public static List<RecordType> getSelectedRecordTypes(String strObjName,List<String> lstRecordTypeNames){
        List<RecordType> lstRecordTypes = new List<RecordType>();
        if(String.isNotBlank(strObjName)){
           lstRecordTypes = [SELECT Id,Name,DeveloperName 
                             FROM RecordType 
                             WHERE SobjectType =:strObjName 
                             AND DeveloperName IN: lstRecordTypeNames];
        }  
        return lstRecordTypes;  
    }*/

    /* METHOD NAME    : insertEntitlement
     * DESCRIPTION    : Entitle Case and Work Order
     * @DATE          : 11-Jun-2018  
     * RETURN TYPE    : List of Entitlements
     * PARAMETER      : List<sObject>, Old Map<sObject>, List<fieldAPInames> which will be used to compare the Covered Product and Covered Location
    */
    public static List<Applied_Contract__c> insertEntitlement(List<sObject> lstSObject,  Set<Id> setInstalledProductIds , Set<Id> setlocationIds, List<String> lstFieldAPIname)
    {
        ilib_LogEvent.push(LOG_TITLE + '.insertEntitlement'); //CMSI-69
        ilib_LogEvent.info('lstSObject :'+UtilsCollection.getSetOfIds(lstSObject));//CMSI-69
        ilib_LogEvent.info('setInstalledProductIds :'+setInstalledProductIds);//CMSI-69
        ilib_LogEvent.info('setlocationIds :'+setlocationIds);//CMSI-69
        ilib_LogEvent.info('lstFieldAPIname :'+lstFieldAPIname);//CMSI-69
        List<Applied_Contract__c> lstNewEntitlements = new List<Applied_Contract__c>();
        if ((setInstalledProductIds != null && !setInstalledProductIds.isEmpty()) || (setlocationIds != null && !setlocationIds.isEmpty()) || (WorkOrders.setAcntIds != null && !WorkOrders.setAcntIds.isEmpty())) {
            // Prepare the list of new entitlements to be inserted as well as old entitlements to be deleted when the Installed Porduct/Location are changed in Case/Work Order.
           Map<Id, List<SVMXC__Service_Contract_Sites__c>> idToCoveredLocations = new Map<Id, List<SVMXC__Service_Contract_Sites__c>>();
            // Create the map of Covered Products/Covered Location
            Map<Id, List<SVMXC__Service_Contract_Products__c>> idToCoveredProducts = new Map<Id, List<SVMXC__Service_Contract_Products__c>>();
            idToCoveredProducts = prepareInstallProductData(setInstalledProductIds);
            String sObjectName = !lstSObject.isEmpty() ? getAPIName(lstSObject.get(0).Id) : '';
            if (sObjectName != STRING_ASSOCIATED_PRODUCT) {
                idToCoveredLocations = insertLocationEntitlement(setlocationIds);
            }
            if(lstSObject != null && !lstSObject.isEmpty()) {
                lstNewEntitlements = iterateOversObject(lstSObject , idToCoveredProducts , idToCoveredLocations , lstFieldAPIname);
            }
            ilib_LogEvent.message('List of Service Order updated'+UtilsCollection.getSetOfIds(lstNewEntitlements)); //CMSI-69
        }
        ilib_LogEvent.pop(); //CMSI-69
        // Return List of new Entitlements records
        return lstNewEntitlements;
    }

    private static List<Applied_Contract__c> iterateOversObject(List<sObject> lstSObject , Map<Id, List<SVMXC__Service_Contract_Products__c>> idToCoveredProducts , Map<Id, List<SVMXC__Service_Contract_Sites__c>> idToCoveredLocations , List<String> lstFieldAPIname) {
        String sObjectName = !lstSObject.isEmpty() ? getAPIName(lstSObject.get(0).Id) : '';
        List<Applied_Contract__c> lstNewEntitlements = new List<Applied_Contract__c>();
        Set<Id> setCaseIds = new Set<Id>();
        Set<Id> setWorkOrderIds = new Set<Id>();
        Set<Id> associatedProductIds = new Set<Id>();
        //CMCM-6541 related to CMCM-9 ---->START based on Account Ids fetached all the Locations Ids and Map with each Account Id
        if(WorkOrders.setAcntIds!=null && !WorkOrders.setAcntIds.isEmpty()){
            if(siteRecords.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
                siteRecords = new LocationsSelector().selectLocationsFromAccountIds(WorkOrders.setAcntIds);
            }
            for(SVMXC__Site__c siteRec : siteRecords){
                set<Id> tempSiteIds = new set<Id>();
                if(mapAcntToSiteIds.containsKey(siteRec.SVMXC__Account__c)){
                    tempSiteIds.addAll(mapAcntToSiteIds.get(siteRec.SVMXC__Account__c));
                    tempSiteIds.add(siteRec.Id);
                    mapAcntToSiteIds.put(siteRec.SVMXC__Account__c,tempSiteIds);
                }else{
                    tempSiteIds.add(siteRec.Id);
                    mapAcntToSiteIds.put(siteRec.SVMXC__Account__c,tempSiteIds);
                }
            }
        }
        //CMCM-6541 related to CMCM-9--> END
        for (sObject sObjectRec : lstSObject) {
            if(idToCoveredLocations !=null ||  idToCoveredProducts !=null){
                List<Applied_Contract__c> lstEntitlements = getNewEntitlements(lstFieldAPIname, sObjectRec, idToCoveredProducts, idToCoveredLocations);
                if(lstEntitlements != null && !lstEntitlements.isEmpty()) {
                    lstNewEntitlements.addAll(lstEntitlements);
                }
            }
            if (sObjectName != STRING_ASSOCIATED_PRODUCT) {
                setCaseIds.add(sObjectRec.Id);
                setWorkOrderIds.add(sObjectRec.Id);
            } else {
                associatedProductIds.add(sObjectRec.Id);
            }
        }
        deletePreviousEntitlements(setCaseIds , setWorkOrderIds , associatedProductIds);
        return lstNewEntitlements;
    }

    private static void deletePreviousEntitlements(Set<Id> setCaseIds , Set<Id> setWorkOrderIds , Set<Id> associatedProductIds) {
        list<Applied_Contract__c> lstEntitlementsToBeDeleted = new list<Applied_Contract__c>();
        // Delete the previous Entitlements for Cases and Work Orders
        if ((setCaseIds != null && !setCaseIds.isEmpty()) || (setWorkOrderIds != null && !setWorkOrderIds.isEmpty())) {
            lstEntitlementsToBeDeleted = new AppliedContractsSelector().selectEntitlements(setCaseIds, setWorkOrderIds);
        }
        if(lstEntitlementsToBeDeleted != null && !lstEntitlementsToBeDeleted.isEmpty()) {
            delete lstEntitlementsToBeDeleted;
        } else if (associatedProductIds != null && !associatedProductIds.isEmpty()) {
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().deleteAppliedContract(associatedProductIds);
        }
    }
    private static Map<Id, List<SVMXC__Service_Contract_Products__c>> prepareInstallProductData(Set<Id> setInstalledProductIds) {
        Map<Id, List<SVMXC__Service_Contract_Products__c>> idToCoveredProducts = new Map<Id, List<SVMXC__Service_Contract_Products__c>>();
        
	    if(setInstalledProductIds!=null && !setInstalledProductIds.isEmpty() && (lstCoveredProduct.isEmpty() || Feature.isOn(WO_FEATURE_FLAG))) {
                lstCoveredProduct = new CoveredProductSelector().selectActiveCoveredProducts(setInstalledProductIds);
        }

        if(lstCoveredProduct!=null && !lstCoveredProduct.IsEmpty()) {
            idToCoveredProducts = UtilsCollection.getMapOfIdToSObjects(lstCoveredProduct, STRING_IPKEY_API_NAME);
        }
        return idToCoveredProducts;
    }  
    private static Map<Id, List<SVMXC__Service_Contract_Sites__c>> insertLocationEntitlement(Set<Id> setlocationIds) {
        Map<Id, List<SVMXC__Service_Contract_Sites__c>> idToCoveredLocations = new Map<Id, List<SVMXC__Service_Contract_Sites__c>>();
        if(WorkOrders.lstCoveredLocations != null && !WorkOrders.lstCoveredLocations.IsEmpty()) {
            lstCoveredLocation = WorkOrders.lstCoveredLocations;
        }
        else if(lstCoveredLocation.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
            lstCoveredLocation = new CoveredLocationSelector().selectCoveredLocForLocAndAcc(setlocationIds,WorkOrders.setAcntIds);
        }
        if(lstCoveredLocation!=null && !lstCoveredLocation.IsEmpty()) {
                idToCoveredLocations = UtilsCollection.getMapOfIdToSObjects(lstCoveredLocation, STRING_LOCATION_API_NAME);
        }
        return idToCoveredLocations;
    }
    private static List<Applied_Contract__c> getNewEntitlements(List<String> lstFieldAPIname, sObject recSObject, Map<Id, List<SVMXC__Service_Contract_Products__c>> idToCoveredProducts, Map<Id, List<SVMXC__Service_Contract_Sites__c>> idToCoveredLocations) {
        Schema.SObjectType workOrderObjectType = Schema.SVMXC__Service_Order__c.getSObjectType();
        ilib_LogEvent.push(LOG_TITLE + '.getNewEntitlements'); //CMSI-69        
        List<Applied_Contract__c> lstNewEntitlements = new List<Applied_Contract__c>();
        List<List<sObject>> lstCoveredProductAndCoveredLocation = new List<List<sObject>>();
        // Determine the Active Service Contract by matching the Installed Product of Case/Work Order with Covered Product's Installed Product
        if(idToCoveredProducts !=null && !idToCoveredProducts.isEmpty()) {
            lstCoveredProductAndCoveredLocation.add(idToCoveredProducts.get((id)recSObject.get(lstFieldAPIname[0])));
        }
        if(idToCoveredLocations !=null && !idToCoveredLocations.isEmpty()) {
            if(idToCoveredLocations.get((id)recSObject.get(lstFieldAPIname[1]))!=null){ //NULL CHECK CMCM-6541 (CMCM-9)
            lstCoveredProductAndCoveredLocation.add(idToCoveredLocations.get((id)recSObject.get(lstFieldAPIname[1])));
            }
            //CMCM-6541 related to CMCM-9 assign covered location based on Account field
            if(mapAcntToSiteIds!=null && !mapAcntToSiteIds.isEmpty() && recSObject.getSObjectType() == workOrderObjectType && mapAcntToSiteIds.get((id)recSObject.get(STRING_COMPANY)) != null){
                for(Id siteId : mapAcntToSiteIds.get((id)recSObject.get(STRING_COMPANY))){
                    lstCoveredProductAndCoveredLocation.add(idToCoveredLocations.get(siteId));
                }
            }
            
        }
        if (lstCoveredProductAndCoveredLocation != null && !lstCoveredProductAndCoveredLocation.isEmpty()) {
            lstNewEntitlements = prepareForInstallProduct(lstCoveredProductAndCoveredLocation, recSObject);
        }
        ilib_LogEvent.message('List of Service Order updated'+UtilsCollection.getSetOfIds(lstNewEntitlements)); //CMSI-69
        ilib_LogEvent.pop(); //CMSI-69
        return lstNewEntitlements;
    }
    private static List<Applied_Contract__c> prepareForInstallProduct(List<List<sObject>> lstCoveredProductAndCoveredLocation , sObject recSObject) {
        List<Applied_Contract__c> lstNewEntitlements = new List<Applied_Contract__c>();
        for(integer i = 0 ; i<lstCoveredProductAndCoveredLocation.size() ; i++) {
            if(lstCoveredProductAndCoveredLocation[i] != null) {
                for ( sObject cpcl : lstCoveredProductAndCoveredLocation[i] ) {
                    Applied_Contract__c objEntitlement = initAppliedContract(cpcl , recSObject);
                    if(objEntitlement!=null){
                        lstNewEntitlements.add(objEntitlement);
                    }
                }
            } 
        }
        return lstNewEntitlements;
    } 
    private static Applied_Contract__c initAppliedContract(sObject cpcl , sObject recSObject) {
        String sObjectName = getAPIName(recSObject.Id);
        Applied_Contract__c objEntitlement; //changed CMCM-6517 bug of CMCM-9
        if(WorkOrders.setServContractIds!= null && !WorkOrders.setServContractIds.contains((Id)cpcl.get(STRING_SERVICE_CONTRACT))){
            objEntitlement = new Applied_Contract__c(); //INITIALISED INSIDE IF CONDITION
            objEntitlement.Service_Contract__c = (Id)cpcl.get(STRING_SERVICE_CONTRACT);
            WorkOrders.setServContractIds.add((Id)cpcl.get(STRING_SERVICE_CONTRACT));//CMCM-6517 filtering duplicate records to prevent the creation of Applied contract recs
            if (sObjectName != STRING_ASSOCIATED_PRODUCT) {
                string strObjectName = getAPIName(recSObject.Id);
                objEntitlement.Case_Number__c = strObjectName == STRING_CASE_API_NAME ? (Id)recSobject.get('Id') : null;
                objEntitlement.Work_Order__c = strObjectName == STRING_WORKORDER_API_NAME ? (Id)recSObject.get('Id') : null;
                objEntitlement.Applied_Contract_Source__c = strObjectName == STRING_WORKORDER_API_NAME ?'WO Location/Account':null; // Added by Dhairya Shah for CMCM-7287
            } else {
                objEntitlement.Associated_Product__c = (Id)recSObject.get('Id');
                objEntitlement.Case_Number__c = (Id)recSobject.get(STRING_CASE) != null ? (Id)recSobject.get(STRING_CASE) : null;
                objEntitlement.Work_Order__c = (Id)recSObject.get(STRING_WORK_ORDER) != null ? (Id)recSObject.get(STRING_WORK_ORDER) : null;
                objEntitlement.Applied_Contract_Source__c = 'Associated Product'; // Added by Dhairya Shah for CMCM-7287
            }
            objEntitlement.Record_Creation_Source__c = 'Backend Code'; //INC0229339
        }
        return objEntitlement;
    }   
    /* METHOD NAME    : fetchAccountRoles
     * DESCRIPTION    : fetch the roles and thier correspding technicians associated with an Account
     * PARAMETER      : setAccountId - set of account ids for which the technician roles are to be fetched
     *                  setRoleNames - roles for which to be queried
     * PARAMETER      : Map<Id,Map<String,Account_to_Field_Support__c>>  -Map of account Id versus Map of technician role and technician
    */
    public static Map<Id,Map<String,Account_to_Field_Support__c>> fetchAccountRoles(Set<String> setAccountId, Set<String> setRoleNames){
        ilib_LogEvent.push(LOG_TITLE + '.fetchAccountRoles'); //CMSI-69
        ilib_LogEvent.info('setAccountId :'+setAccountId);//CMSI-69
        ilib_LogEvent.info('setRoleNames :'+setRoleNames);//CMSI-69
        Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToRole = new Map<Id,Map<String,Account_to_Field_Support__c>>();
        for(Account_to_Field_Support__c objAccountTechnicianRole : [SELECT Id, 
                                                                  Name, 
                                                                  Account__c, 
                                                                  User_Role__c, 
                                                                  User__c,
                                                                  Salesforce_User_ID__c,
                                  User__r.Related_User_Email__c,
                                  User__r.Name,
								  User__r.SVMXC__Email__c,
                                  User__r.SVMXC__Active__c,
                                  Account__r.Account_Group__c,
                                  User__r.SVMXC__Salesforce_User__r.Email,
                                                                  User__r.SVMXC__Salesforce_User__c,
                                  User__r.SVMXC__Salesforce_User__r.TimeZoneSidKey //DCP-25273
                                                                  FROM Account_to_Field_Support__c 
                                                                  WHERE Account__c IN:setAccountId 
                                                                  AND User_Role__c IN:setRoleNames
                                                                  AND Active__c = true])
        {
            Map<String,Account_to_Field_Support__c> roleToTechnican = accountIdToRole.get(objAccountTechnicianRole.Account__c);
            if(roleToTechnican == null){
                roleToTechnican = new Map<String,Account_to_Field_Support__c>();
            }
            roleToTechnican.put(objAccountTechnicianRole.User_Role__c, objAccountTechnicianRole);
            accountIdToRole.put(objAccountTechnicianRole.Account__c, roleToTechnican);
            ilib_LogEvent.message((accountIdToRole != Null ? String.valueof(accountIdToRole.keySet()):'Map is empty'));
        }
        ilib_LogEvent.pop();//CMSI-69
        return accountIdToRole;
    }
    
     /* METHOD NAME    : fetchBusinessHoursMetadata
    * DESCRIPTION    : fetch the business hours settings for the org.
    * RETURN TYPE    : List<Business_Hours_Setting__mdt>
    */
    public static List<Business_Hours_Setting__mdt> fetchBusinessHoursMetadata(){
        ilib_LogEvent.push(LOG_TITLE + '.fetchBusinessHoursMetadata');//CMSI-69
        if(businessHoursSettingMdtList == null || businessHoursSettingMdtList.isEmpty() && !String.isBlank(STRING_DEFAULT_BUSINESS_HOUR_SETTING)){
            businessHoursSettingMdtList = new BusinessHoursSettingMetadataSelector().selectDefaultBusinessHourSetting(STRING_DEFAULT_BUSINESS_HOUR_SETTING);
        }
        ilib_LogEvent.pop();//CMSI-69
        return businessHoursSettingMdtList;
    }
    
    /* METHOD NAME    : fetchNextAvailableEngineer
    * DESCRIPTION    : check for the engineer in the hierarchy whose calendar is free
    * RETURN TYPE    : List<SVMXC__Service_Order__c>
    * PARAMETER      : objWorkorder - work orde for which technician is to be checked
    *                   roleToTechnican - map of role to technician
    *                   setUnavailableTechnician - set of unavailable technicians
    */
   public static List<SVMXC__Service_Order__c> fetchNextAvailableEngineer(SVMXC__Service_Order__c objWorkorder, Map<String,Account_to_Field_Support__c> roleToTechnican, 
                                                 Set<Id> setUnavailableTechnician, Map<Id, Id> mapWorkOrderCaseOwner, Map<Id,Set<Id>> technicianToExertise,
                                                 List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata)
    {
        ilib_LogEvent.push(LOG_TITLE + '.fetchNextAvailableEngineer');//CMSI-69
		
        List<SVMXC__Service_Order__c> lstNonDispatchWorkOrder = new List<SVMXC__Service_Order__c>();
		Boolean boolFoundFSE = false;
			
		//condition to check assignment to be assigned to Channel Partner Field Service Engineer
        if(objWorkorder.Partner_Installation_WO__c == true){
			 //check if support user with Channel Partner Primary Field Service Engineer
                if(objWorkorder.Field_Support_User_Role__c == null ){
                    objWorkorder.Field_Support_User_Role__c = STRING_LABEL_PARTNER_PRIMARY_FSE; 
                    if(roleToTechnican != null && roleToTechnican.containsKey(STRING_LABEL_PARTNER_PRIMARY_FSE) && 
                       roleToTechnican.get(STRING_LABEL_PARTNER_PRIMARY_FSE) != null && 
                       !setUnavailableTechnician.contains(roleToTechnican.get(STRING_LABEL_PARTNER_PRIMARY_FSE).User__r.SVMXC__Salesforce_User__c) 
                       ){
                           objWorkorder.SVMXC__Order_Status__c =  STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED;
                           objWorkorder.SVMXC__Group_Member__c = roleToTechnican.get(STRING_LABEL_PARTNER_PRIMARY_FSE).User__c;
                           objWorkorder.ownerId = roleToTechnican.get(STRING_LABEL_PARTNER_PRIMARY_FSE).User__r.SVMXC__Salesforce_User__c;
                           objWorkorder.Date_Time_Assigned__c = system.now();
                           setAutoRejectionDates(objWorkorder,lstBusinessHoursMetadata, roleToTechnican.get(STRING_LABEL_PARTNER_PRIMARY_FSE).User__r.SVMXC__Salesforce_User__r.TimeZoneSidKey);//DCP-25273
                           boolFoundFSE = true;
                       }
                }
                
                //check if support user with Channel Partner Secondary Field Service Engineer
                if(!boolFoundFSE && objWorkorder.Field_Support_User_Role__c == STRING_LABEL_PARTNER_PRIMARY_FSE){
                    objWorkorder.Field_Support_User_Role__c = STRING_LABEL_PARTNER_SECONDARY_FSE;
                    if(roleToTechnican != null && roleToTechnican.containsKey(STRING_LABEL_PARTNER_SECONDARY_FSE) && 
                       roleToTechnican.get(STRING_LABEL_PARTNER_SECONDARY_FSE) != null && 
                       !setUnavailableTechnician.contains(roleToTechnican.get(STRING_LABEL_PARTNER_SECONDARY_FSE).User__r.SVMXC__Salesforce_User__c) 
                       )
                    {   
                        objWorkorder.SVMXC__Order_Status__c =  STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED;
                        objWorkorder.SVMXC__Group_Member__c = roleToTechnican.get(STRING_LABEL_PARTNER_SECONDARY_FSE).User__c;
                        objWorkorder.ownerId = roleToTechnican.get(STRING_LABEL_PARTNER_SECONDARY_FSE).User__r.SVMXC__Salesforce_User__c;
                        objWorkorder.Date_Time_Assigned__c = system.now();
                        setAutoRejectionDates(objWorkorder,lstBusinessHoursMetadata, roleToTechnican.get(STRING_LABEL_PARTNER_SECONDARY_FSE).User__r.SVMXC__Salesforce_User__r.TimeZoneSidKey); //DCP-25273 
                        boolFoundFSE = true;
                    } 
                } 
		}else{
        //check if support user with Primary Field Service Engineer
        if(objWorkorder.Field_Support_User_Role__c == null ){
            objWorkorder.Field_Support_User_Role__c = STRING_LABEL_PRIMARY_FSE;
            if(roleToTechnican != null && roleToTechnican.containsKey(STRING_LABEL_PRIMARY_FSE) && 
               roleToTechnican.get(STRING_LABEL_PRIMARY_FSE) != null && 
               !setUnavailableTechnician.contains(roleToTechnican.get(STRING_LABEL_PRIMARY_FSE).User__r.SVMXC__Salesforce_User__c) &&
               technicianToExertise.containsKey(roleToTechnican.get(STRING_LABEL_PRIMARY_FSE).User__c)  &&
               technicianToExertise.get(roleToTechnican.get(STRING_LABEL_PRIMARY_FSE).User__c).contains(objWorkorder.SVMXC__Product__c))
            {
                objWorkorder.SVMXC__Order_Status__c =  STRING_WORK_ORDER_STATUS_ASSIGNED ;
                objWorkorder.SVMXC__Group_Member__c = roleToTechnican.get(STRING_LABEL_PRIMARY_FSE).User__c;
                objWorkorder.ownerId = roleToTechnican.get(STRING_LABEL_PRIMARY_FSE).User__r.SVMXC__Salesforce_User__c;
				objWorkorder.Date_Time_Assigned__c = system.now();
                setAutoRejectionDates(objWorkorder,lstBusinessHoursMetadata, roleToTechnican.get(STRING_LABEL_PRIMARY_FSE).User__r.SVMXC__Salesforce_User__r.TimeZoneSidKey);//DCP-25273  
                boolFoundFSE = true;
            }
        }
        //check if support user with Secondary Field Service Engineer
        if(!boolFoundFSE && objWorkorder.Field_Support_User_Role__c == STRING_LABEL_PRIMARY_FSE){ 
            objWorkorder.Field_Support_User_Role__c = STRING_LABEL_SECONDARY_FSE;
            if(roleToTechnican != null && roleToTechnican.containsKey(STRING_LABEL_SECONDARY_FSE) && 
               roleToTechnican.get(STRING_LABEL_SECONDARY_FSE) != null && 
               !setUnavailableTechnician.contains(roleToTechnican.get(STRING_LABEL_SECONDARY_FSE).User__r.SVMXC__Salesforce_User__c) &&
               technicianToExertise.containsKey(roleToTechnican.get(STRING_LABEL_SECONDARY_FSE).User__c)  &&
               technicianToExertise.get(roleToTechnican.get(STRING_LABEL_SECONDARY_FSE).User__c).contains(objWorkorder.SVMXC__Product__c))
            {   
                objWorkorder.SVMXC__Order_Status__c =  STRING_WORK_ORDER_STATUS_ASSIGNED ;
                objWorkorder.SVMXC__Group_Member__c = roleToTechnican.get(STRING_LABEL_SECONDARY_FSE).User__c;
                objWorkorder.ownerId = roleToTechnican.get(STRING_LABEL_SECONDARY_FSE).User__r.SVMXC__Salesforce_User__c;
				objWorkorder.Date_Time_Assigned__c = system.now();
                setAutoRejectionDates(objWorkorder,lstBusinessHoursMetadata, roleToTechnican.get(STRING_LABEL_SECONDARY_FSE).User__r.SVMXC__Salesforce_User__r.TimeZoneSidKey);  //DCP-25273  
                boolFoundFSE = true;
            } 
        } 
        //check if support user with FSM
        if(!boolFoundFSE && objWorkorder.Field_Support_User_Role__c == STRING_LABEL_SECONDARY_FSE){
            objWorkorder.Field_Support_User_Role__c = STRING_LABEL_FSM;
            if(roleToTechnican != null && roleToTechnican.containsKey(STRING_LABEL_FSM) && 
               roleToTechnican.get(STRING_LABEL_FSM) != null && 
               !setUnavailableTechnician.contains(roleToTechnican.get(STRING_LABEL_FSM).User__r.SVMXC__Salesforce_User__c))
            {
                objWorkorder.SVMXC__Order_Status__c =  STRING_WORK_ORDER_STATUS_ASSIGNED ;
                objWorkorder.SVMXC__Group_Member__c = roleToTechnican.get(STRING_LABEL_FSM).User__c;
                objWorkorder.ownerId = roleToTechnican.get(STRING_LABEL_FSM).User__r.SVMXC__Salesforce_User__c;
				objWorkorder.Date_Time_Assigned__c = system.now();
                setAutoRejectionDates(objWorkorder,lstBusinessHoursMetadata, roleToTechnican.get(STRING_LABEL_FSM).User__r.SVMXC__Salesforce_User__r.TimeZoneSidKey);//DCP-25273  
                boolFoundFSE = true;
            } 
        }
		
		}
        
        if(!boolFoundFSE && objWorkorder.Field_Support_User_Role__c == STRING_LABEL_FSM ){
            lstNonDispatchWorkOrder.add(objWorkorder);
            objWorkorder.Field_Support_User_Role__c = '';
            objWorkorder.SVMXC__Group_Member__c = null;
            if(mapWorkOrderCaseOwner != null && mapWorkOrderCaseOwner.containsKey(objWorkorder.Id) && 
            mapWorkOrderCaseOwner.get(objWorkorder.Id) != null)
            {
                objWorkorder.ownerId = mapWorkOrderCaseOwner.get(objWorkorder.Id); 
            }
            else if(objWorkorder.Original_Owner__c != null){
                objWorkorder.ownerId = objWorkorder.Original_Owner__c; 
            }
			else{
                objWorkorder.ownerId = userInfo.getUserId();            
            }
        }
        if(!boolFoundFSE){
            objWorkorder.Is_Auto_Dispatch__c = false;
        }
        ilib_LogEvent.info('lstBusinessHoursMetadata :'+UtilsCollection.getSetOfIds(lstBusinessHoursMetadata)); //CMSI-69
        ilib_LogEvent.pop();//CMSI-69
        return lstNonDispatchWorkOrder;
    }
    
    //DCP-25273
    private static datetime getUserDateTime(string timeZoneId, DateTime dt){
        ilib_LogEvent.push(LOG_TITLE + '.getUserDateTime');//CMSI-69
        Timezone tz = Timezone.getTimeZone(timeZoneId);
        Integer offSet = tz.getoffset(dt);
        ilib_LogEvent.pop();//CMSI-69
        return dt.addseconds(offSet/1000);
    }
	
    /* METHOD NAME    : setAutoRejectionDates
    * DESCRIPTION    : set the next Rejection date based on business hours
    * RETURN TYPE    : N/A
    * PARAMETER      : objWorkorder - work order for which rejection date is to be set
    *                   lstBusinessHoursMetadata - business hours setting in the org
    */
    public static void setAutoRejectionDates(SVMXC__Service_Order__c objWorkorder,List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata, string timeZoneId){//DCP-25273
        ilib_LogEvent.push(LOG_TITLE + '.setAutoRejectionDates'); //CMSI-69
        ilib_LogEvent.info('objWorkorder :'+objWorkorder); //CMSI-69
        ilib_LogEvent.info('lstBusinessHoursMetadata :'+lstBusinessHoursMetadata); //CMSI-69
        ilib_LogEvent.info('timeZoneId :'+timeZoneId); //CMSI-69
        if(!lstBusinessHoursMetadata.isEmpty() && objWorkorder.Date_Time_Assigned__c != null){
            Business_Hours_Setting__mdt objBusinessHour = lstBusinessHoursMetadata[0];
            DateTime dTTechCurrTime = getUserDateTime(timeZoneId, system.now());// DCP-25273
            DateTime dayStartDateTime = date.newInstance(dTTechCurrTime.year(), dTTechCurrTime.month(), dTTechCurrTime.day());// DCP-25273
            dayStartDateTime = dayStartDateTime.addHours(Integer.valueOf(objBusinessHour.StartTimeOfTheDay__c));
            DateTime dayEndDateTime = date.newInstance(dTTechCurrTime.year(), dTTechCurrTime.month(), dTTechCurrTime.day()); // DCP-25273 
            dayEndDateTime = dayEndDateTime.addHours(Integer.valueOf(objBusinessHour.EndHourOfTheDay__c)); 
            checkNextAvailableSLATime(objWorkorder, dayStartDateTime, dayEndDateTime, Integer.valueOf(objBusinessHour.Rejection_Hour_For_SLA_Next_Day__c), 
                                        'Rejection_DateTime_for_SLA_Next_Day__c', timeZoneId);//DCP-25273
            checkNextAvailableSLATime(objWorkorder, dayStartDateTime, dayEndDateTime, Integer.valueOf(objBusinessHour.Rejection_Hour_For_SLA_Post_Next_Day__c), 
                                        'Rejection_DateTime_for_SLA_Post_Next_Day__c', timeZoneId);//DCP-25273
        }
        ilib_LogEvent.pop(); //CMSI-69
    }
    
    /* METHOD NAME    : checkNextAvailableSLATime
    * DESCRIPTION    : check the next Rejection SLA date based on business hours
    * RETURN TYPE    : N/A
    * PARAMETER      : objWorkorder - work order for which rejection date is to be set
    *                   dayStartDateTime - business start date time
    *                   dayEndDateTime - businesss end date time
    * 					intRejectionHours - hours after the assigned date for which date needs to be fetched
    * 					strSLAField - rejection field, which needs to be set on the Work Order
    */
	
    @TestVisible private static void checkNextAvailableSLATime(SVMXC__Service_Order__c objWorkorder, DateTime dayStartDateTime, DateTime dayEndDateTime ,
                                                    Integer intRejectionHours, String strSLAField, string timeZoneId)//DCP-25273)
    {
        ilib_LogEvent.push(LOG_TITLE + '.checkNextAvailableSLATime'); //CMSI-69
        //The date/tume assigned will be returned in GMT tiemzone, get the offset from the local time zone
        Integer offset = Timezone.getTimeZone(timeZoneId).getOffset(objWorkorder.Date_Time_Assigned__c);//DCP-25273
        //Set the actual assigned date based on current user' time zone
        Datetime assignedDate = getUserDateTime(timeZoneId, objWorkorder.Date_Time_Assigned__c);//objWorkorder.Date_Time_Assigned__c.addSeconds(offset/1000); DCP-25273
        //Get the SLA time for auto rejection in current user's timezone
        Datetime slaDateTime = assignedDate.addHours(intRejectionHours);
        //Get the day of the week 
        String dayOfWeek = assignedDate.format('EEEE');
        Integer intAddDays = 1;
        if(dayOfWeek == STRING_DAY_OF_WEEK_FRIDAY){
            intAddDays = 3;
        }else if(dayOfWeek == STRING_DAY_OF_WEEK_SATURDAY){
            intAddDays = 2;
        }
        if(slaDateTime >= dayStartDateTime && slaDateTime <= dayEndDateTime){
            objWorkorder.put(strSLAField,slaDateTime.addSeconds(-offset/1000));
        }
        //Else if the Rejection SLA is before the start time, then set the time after start time
        else if(slaDateTime < dayStartDateTime){
            objWorkorder.put(strSLAField,dayStartDateTime.addHours(intRejectionHours).addSeconds(-offset/1000));
        }
        //Else if the Rejection SLA is after the end time, also the assigned date is after the end time
        //then set the time for the next business day
        else if(slaDateTime > dayEndDateTime && assignedDate > dayEndDateTime){
            objWorkorder.put(strSLAField,dayStartDateTime.addDays(intAddDays).addHours(intRejectionHours).addSeconds(-offset/1000));
        }
        //Else if the Rejection SLA is after the end time, but the assigned date is before the end time
        //then calucate the time diffeence and set the time for the next business day
        else if(slaDateTime > dayEndDateTime && assignedDate < dayEndDateTime){
            Decimal hoursDifference = ((slaDateTime.getTime())/1000/60/60.0) - ((dayEndDateTime.getTime())/1000/60/60.0);
            objWorkorder.put(strSLAField,dayStartDateTime.addDays(intAddDays)
                .addHours(Integer.valueOf(hoursDifference.round(system.RoundingMode.CEILING)))
                .addSeconds(-offset/1000));
        }
        ilib_LogEvent.pop(); //CMSI-69
    }

    
    /* METHOD NAME    : checkTechniciansExpertise
     * DESCRIPTION    : check for the technicians expertise is valid
     * RETURN TYPE    : Map<Id,Set<Id>> - map of technician versus their product expertise
     * PARAMETER      : accountIdToFSERoles - Map of account Id versus Map of technician role and technician
    */
    public static Map<Id,Set<Id>> checkTechniciansExpertise(Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles){
        ilib_LogEvent.push(LOG_TITLE + '.checkTechniciansExpertise');
        ilib_LogEvent.info('accountIdToFSERoles :'+(!accountIdToFSERoles.isEmpty() ? String.valueOf(accountIdToFSERoles.keySet()) : 'Map is Empty')); //CMSI-69
        Map<Id,Set<Id>> technicianToProductExpertise = new Map<Id,Set<Id>>();
        Set<Id> setTechnicianToCheckExpertise = new Set<Id>();
        for(Id idAccount : accountIdToFSERoles.keySet()){
            for(Account_to_Field_Support__c accountTechnician : accountIdToFSERoles.get(idAccount).values()){
                setTechnicianToCheckExpertise.add(accountTechnician.User__c);
            }
        }
        if((activeProductList == null && activeProductList.isEmpty()) && setTechnicianToCheckExpertise != null && setTechnicianToCheckExpertise.size() > 0){
            activeProductList = new ProductServicedSelector().getCertifiedTechnicianProducts(setTechnicianToCheckExpertise);
        }
		if(activeProductList != null && activeProductList.size() > 0){
            //DCP-42718 - Added Active Checkbox check.
			for(SVMXC__Service_Group_Product__c objExpertise : activeProductList)
			{   
				if(!technicianToProductExpertise.containsKey(objExpertise.SVMXC__Group_Member__c)){
					technicianToProductExpertise.put(objExpertise.SVMXC__Group_Member__c, new Set<Id>());
				} 
				technicianToProductExpertise.get(objExpertise.SVMXC__Group_Member__c).add(objExpertise.SVMXC__Product__c);
			}
            ilib_LogEvent.message((technicianToProductExpertise != Null ? String.valueof(technicianToProductExpertise.keySet()):'Map is empty')); //CMSI-69
		}
        ilib_LogEvent.pop(); //CMSI-69
        return technicianToProductExpertise; 
    }
	
	/*
    * PickListValueWrapper
    * Wrapper class to represent picklist value and API value
    * author : Debalina
    */
    /*public class PickListValueWrapper {
    public String sKey,sValue;
        public PickListValueWrapper (String sValue) {
            this.sKey = sValue;
            this.sValue = sValue;
        }

        public PickListValueWrapper (String sKey, String sValue) {
            this.sKey = sKey;
            this.sValue = sValue;
        }
    }*/
	
	 /* METHOD NAME    : sendEmailWhenLOASigned
     * DESCRIPTION    : send a email with the signed Letter of Acceptance as attachment
     * RETURN TYPE    : void
     * PARAMETER      : map<id,SVMXC__Service_Order__c>
     * Author       : Soumya           
    */
    /*public static void sendEmailWhenLOASigned(map<id,SVMXC__Service_Order__c> idToWorkOrder){
         List<Messaging.SingleEmailMessage> lstEmails = new List<Messaging.SingleEmailMessage>();
         for(id idAttachment : idToWorkOrder.keySet()){
        
            EmailTemplate templateInstance = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{STRING_EMAIL_TEMPLATE_API_NAME})[0];
            Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {STRING_TO_EMAIL_ADDRESS,idToWorkOrder.get(idAttachment).Customer_Representative__c}; 
            String[] ccAddresses = new String[] {idToWorkOrder.get(idAttachment).Illumina_Representative__c};
            objEmail.setToAddresses(toAddresses);
            objEmail.setCcAddresses(ccAddresses);
            objEmail.setTargetObjectId(idToWorkOrder.get(idAttachment).Customer_Representative__c);
            objEmail.setWhatId(idToWorkOrder.get(idAttachment).id);
            objEmail.setTemplateId(templateInstance.id);
            objEmail.setEntityAttachments(new id[] {idAttachment});
            lstEmails.add(objEmail);
         }
            Messaging.sendEmail(lstEmails);
            
    }*/

    /* METHOD NAME    : checkCompatibleProductsInFRUList
     * DESCRIPTION    : Check whether the product selected is compatible as per FRU list
     * RETURN TYPE    : void
     * PARAMETER      : List<sObject> lstChildRecords - list of child records (part order line / work order line) which have been created / updated
                        Map<Id, sObject> parentMap - Parent record Id versus parent record
                        String parentFieldName - Field name of the parent record i.e. Work Order / Part Order
                        Set<Id> setProductsIdsSelected - Set of Product Ids which have been selected in Part Order Line/ Work Order Line
                        String typeCheck - the check needs to be performed for Parts/ Tools
    * Author       : Ritika           
    */
    public static void checkCompatibleProductsInFRUList(List<sObject> lstChildRecords, Map<Id, sObject> parentMap, Map<Id, sobject> oldRecords, 
                                                        String strParentFieldName, Set<Id> setProductsIdsSelected, set<String> setTypeCheck)
    {
        
        ilib_LogEvent.push(LOG_TITLE + '.checkCompatibleProductsInFRUList'); //CMSI-69
        ilib_LogEvent.info('lstChildRecords : '+UtilsCollection.getSetOfIds(lstChildRecords));//CMSI-69
        ilib_LogEvent.info('parentMap : ' + (parentMap != Null ? String.valueof(parentMap.keySet()):'Null'));//CMSI-69
        ilib_LogEvent.info('oldRecords : ' + (oldRecords != Null ? String.valueof(oldRecords.keySet()):'Null'));//CMSI-69
        ilib_LogEvent.info('strParentFieldName : '+strParentFieldName);//CMSI-69
        ilib_LogEvent.info('setProductsIdsSelected : '+setProductsIdsSelected);//CMSI-69
        ilib_LogEvent.info('setTypeCheck : '+setTypeCheck);//CMSI-69

        //Get the sobjec type for Work Order and Parts Order
        Schema.SObjectType workOrderObjectType = Schema.SVMXC__Service_Order__c.getSObjectType();
        Schema.SObjectType partsOrderObjectType = Schema.SVMXC__RMA_Shipment_Order__c.getSObjectType();
       
        SVMXC__Service_Order__c objPOWorkOrder = new SVMXC__Service_Order__c();
        Case objPOCase = new Case();

        Map<Id,ID> workOrderIdToBOMId = new Map<Id,Id>();
        Map<Id,ID> caseIdToBOMId = new Map<Id,Id>();
        Set<Id> setDefaultServiceBOMToBeFetched = new Set<Id>();

        Map<Id, Id> productIdToDefaultServiceBOMId = new Map<Id,Id>();
        Map<Id, Set<Id>> serviceBOMIDToFRULProductSet = new Map<Id, Set<Id>>();

        Map<Id,sObject> mapParentToBeUpdated = new Map<Id,sObject>();

        //Fetch the associated parent records and create its map
        Map<Id,Product2> productIdToRecordMap = new Map<Id,Product2>(new ProductsSelector().selectProducts(setProductsIdsSelected));
        ilib_LogEvent.info('productIdToRecordMap : ' + (productIdToRecordMap != Null ? String.valueof(productIdToRecordMap.keySet()):'Null'));

        //Iterate on the Parent records, and get the Service BOM associate with its Installed Product / Product
        for (Id idParent: parentMap.keyset()) {
            sObject objParent = parentMap.get(idParent);
            ilib_LogEvent.message('objParent : '+objParent);
            if(parentMap.get(idParent).getSObjectType() == workOrderObjectType){
                objPOWorkOrder = (SVMXC__Service_Order__c)objParent;
            }else if(parentMap.get(idParent).getSObjectType() == partsOrderObjectType){
                objPOWorkOrder = (SVMXC__Service_Order__c)objParent.getSobject('SVMXC__Service_Order__r');
            }
            ilib_LogEvent.message('objPOWorkOrder : '+objPOWorkOrder);
            objPOCase = (Case)objParent.getSobject('SVMXC__Case__r');
            ilib_LogEvent.message('objPOCase : '+objPOCase);
            //If the child record has associated Work Order, then check if its Installed Product has an Active Service BOM associated with it
            if(objPOWorkOrder != null && objPOWorkOrder.SVMXC__Component__c != null && 
            objPOWorkOrder.SVMXC__Component__r.Service_Bill_Of_Materials__c != null && 
            objPOWorkOrder.SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c)
            {
                workOrderIdToBOMId.put(objPOWorkOrder.Id, objPOWorkOrder.SVMXC__Component__r.Service_Bill_Of_Materials__c);
                serviceBOMIDToFRULProductSet.put(objPOWorkOrder.SVMXC__Component__r.Service_Bill_Of_Materials__c,new Set<Id>());
            }
            //If the child record has associated Case, then check if its Installed Product has an Active Service BOM associated with it
            //This would be applicable only for Parts Order Line (as POL could have a blank Work Order)
            else if(objPOCase != null && objPOCase.SVMXC__Component__c != null && 
            objPOCase.SVMXC__Component__r.Service_Bill_Of_Materials__c != null && objPOCase.SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c)
            {      
                caseIdToBOMId.put(objPOCase.Id, objPOCase.SVMXC__Component__r.Service_Bill_Of_Materials__c);
                serviceBOMIDToFRULProductSet.put(objPOCase.SVMXC__Component__r.Service_Bill_Of_Materials__c,new Set<Id>());
            }
            //If the Work Order does not have an active Service BOM, create a set for which default Service BOM needs to be fetched.
            else if(objPOWorkOrder != null && objPOWorkOrder.SVMXC__Product__c != null){
                setDefaultServiceBOMToBeFetched.add(objPOWorkOrder.SVMXC__Product__c);
            }
            //If the Case does not have an active Service BOM, create a set for which default Service BOM needs to be fetched.
            else if(objPOCase != null && objPOCase.SVMXC__Product__c != null){
                setDefaultServiceBOMToBeFetched.add(objPOCase.SVMXC__Product__c);
            } 
        } 
        ilib_LogEvent.info('workOrderIdToBOMId : ' + (workOrderIdToBOMId != Null ? String.valueof(workOrderIdToBOMId.keySet()):'Null'));//CMSI-69
        ilib_LogEvent.info('caseIdToBOMId : ' + (caseIdToBOMId != Null ? String.valueof(caseIdToBOMId.keySet()):'Null'));//CMSI-69
        ilib_LogEvent.info('setDefaultServiceBOMToBeFetched : '+setDefaultServiceBOMToBeFetched);//CMSI-69
        //Fetch default service BOM
        for(Service_Bill_Of_Materials__c objServiceBOM : new ServiceBOMsSelector().selectDefaultServiceBOMsForProduct(setDefaultServiceBOMToBeFetched))
        {
            productIdToDefaultServiceBOMId.put(objServiceBOM.Product__c, objServiceBOM.Id);
            serviceBOMIDToFRULProductSet.put(objServiceBOM.Id,new Set<Id>());
        }
        ilib_LogEvent.info('productIdToDefaultServiceBOMId : ' + (productIdToDefaultServiceBOMId != Null ? String.valueof(productIdToDefaultServiceBOMId.keySet()):'Null'));
        ilib_LogEvent.info('serviceBOMIDToFRULProductSet : ' + (serviceBOMIDToFRULProductSet != Null ? String.valueof(serviceBOMIDToFRULProductSet.keySet()):'Null'));
        //Fetch FRU list, related to the Service BOMs 
        for (FRU_List__c objFRU: new FRUListSelector().selectFRUListForServiceBOM(serviceBOMIDToFRULProductSet.keySet(), setTypeCheck))
        { 
            Set<Id> setFRUProduct = serviceBOMIDToFRULProductSet.get(objFRU.Service_Bill_Of_Materials__c);  
            setFRUProduct.add(objFRU.ERP_Product__c);
            ilib_LogEvent.message('setFRUProduct : '+setFRUProduct);
            serviceBOMIDToFRULProductSet.put(objFRU.Service_Bill_Of_Materials__c, setFRUProduct);
        }  
        ilib_LogEvent.info('serviceBOMIDToFRULProductSet : ' + (serviceBOMIDToFRULProductSet != Null ? String.valueof(serviceBOMIDToFRULProductSet.keySet()):'Null'));
        //Iterate on child records and check if the product selected is in FRU list or not
        for (sObject objChild : lstChildRecords) {
            sObject objParent = parentMap.get((Id)objChild.get(strParentFieldName));
			ilib_LogEvent.message('objParent : '+objParent);
			//DCP-31083
            String ivdUpgradeTypeOnCaseIP = '';
            String ivdUpgradeTypeOnWorkOrderIP = '';
            String ivdUpgradeTypeonIP = '';
			
            Product2 objSelectedProduct = productIdToRecordMap.get((Id)objChild.get(STRING_PRODUCT_C));
            ilib_LogEvent.message('objSelectedProduct : '+objSelectedProduct);
            Product2 objParentProduct = new Product2(); 
            if(objParent.getSObjectType() == workOrderObjectType){
                objPOWorkOrder = (SVMXC__Service_Order__c)parentMap.get((Id)objParent.get('Id'));
				
            }else if(objParent.getSObjectType() == partsOrderObjectType){
                objPOWorkOrder = (SVMXC__Service_Order__c)parentMap.get((Id)objParent.get('Id')).getSobject('SVMXC__Service_Order__r');
            }
            if(objPOWorkOrder != null){
                objParentProduct = objPOWorkOrder.SVMXC__Product__r;
				//DCP-31083
                ivdUpgradeTypeonIP=objPOWorkOrder.SVMXC__Component__r.Installed_Product_Upgrade_Type__c;
            }else if(objPOCase != null){
                objParentProduct = objPOCase.SVMXC__Product__r;
				//DCP-31083
                 ivdUpgradeTypeonIP=objPOWorkOrder.SVMXC__Component__r.Installed_Product_Upgrade_Type__c;
            }
            ilib_LogEvent.message('ivdUpgradeTypeonIP : '+ivdUpgradeTypeonIP);
            ilib_LogEvent.message('objParentProduct : '+objParentProduct);
            objPOCase = (Case)parentMap.get((Id)objParent.get('Id')).getSobject('SVMXC__Case__r');
			ilib_LogEvent.message('objPOCase : '+objPOCase);
			//DCP-31083
            if(objPOWorkOrder != null && objPOWorkOrder.SVMXC__Component__c != null && 
            objPOWorkOrder.SVMXC__Component__r.Installed_Product_Upgrade_Type__c != null){
                ivdUpgradeTypeOnWorkOrderIP=objPOWorkOrder.SVMXC__Component__r.Installed_Product_Upgrade_Type__c;
                ilib_LogEvent.message('ivdUpgradeTypeOnWorkOrderIP : '+ivdUpgradeTypeOnWorkOrderIP);
            }
            
            if(objPOCase  != null && objPOCase.SVMXC__Component__c != null && objPOCase.SVMXC__Component__r.Installed_Product_Upgrade_Type__c != null){
                ivdUpgradeTypeOnCaseIP=objPOCase.SVMXC__Component__r.Installed_Product_Upgrade_Type__c;
                ilib_LogEvent.message('ivdUpgradeTypeOnCaseIP : '+ivdUpgradeTypeOnCaseIP);
            }
            //If the child record has associated work order and an active Serivce BOM is found
            if(objPOWorkOrder != null && workOrderIdToBOMId!= null && workOrderIdToBOMId.containsKey(objPOWorkOrder.Id)){
                isProductFoundInFRUList(objChild, objParent, workOrderIdToBOMId.get(objPOWorkOrder.Id), serviceBOMIDToFRULProductSet, objSelectedProduct, objParentProduct, mapParentToBeUpdated, oldRecords, productIdToRecordMap, ivdUpgradeTypeOnWorkOrderIP);
            }
            //If the child record has associated case and an active Serivce BOM is found
            else if(objPOCase != null && caseIdToBOMId != null && caseIdToBOMId.containsKey(objPOCase.Id)){
                isProductFoundInFRUList(objChild, objParent, caseIdToBOMId.get(objPOCase.Id), serviceBOMIDToFRULProductSet, objSelectedProduct, objParentProduct, mapParentToBeUpdated, oldRecords, productIdToRecordMap,ivdUpgradeTypeOnCaseIP);
            }
            //If the child record has associated work order and a default Serivce BOM is found
            else if(objPOWorkOrder != null && objPOWorkOrder.get(STRING_PRODUCT_C) != null &&
                productIdToDefaultServiceBOMId.containsKey((Id)objPOWorkOrder.get(STRING_PRODUCT_C)))
            {
                isProductFoundInFRUList(objChild, objParent, productIdToDefaultServiceBOMId.get((Id)objPOWorkOrder.get(STRING_PRODUCT_C)), serviceBOMIDToFRULProductSet, objSelectedProduct, objParentProduct, mapParentToBeUpdated, oldRecords, productIdToRecordMap,ivdUpgradeTypeOnWorkOrderIP);
            }
            //If the child record has associated case and an active Serivce BOM is found
            else if(objPOCase != null && objPOCase.get(STRING_PRODUCT_C) != null &&
                productIdToDefaultServiceBOMId.containsKey((Id)objPOCase.get(STRING_PRODUCT_C)))
            {
                isProductFoundInFRUList(objChild, objParent, productIdToDefaultServiceBOMId.get((Id)objPOCase.get(STRING_PRODUCT_C)), serviceBOMIDToFRULProductSet, objSelectedProduct, objParentProduct, mapParentToBeUpdated, oldRecords, productIdToRecordMap,ivdUpgradeTypeOnCaseIP);
            }
            //If no Service BOM record found
            else{
			//DCP-31083
            /* @description DCP-47691 - Added condition for Regulatory Type 'EUA'
            */
                if((objParentProduct != null && objParentProduct.Regulatory_Type__c != null && (objParentProduct.Regulatory_Type__c.Contains('DX') || objParentProduct.Regulatory_Type__c.Contains('EUA')) && (String.IsBlank(ivdUpgradeTypeonIP)|| ivdUpgradeTypeonIP=='NONE')) || (!String.IsBlank(ivdUpgradeTypeonIP) && ivdUpgradeTypeonIP=='IVD') ){
                    if(!UserInfo.getName().EqualsIgnoreCase(STRING_SAP_INTEGRATION_USER))
                    objChild.addError(System.label.FRU_List_Trigger_Error_Message_IVD);
                }else{
                    objChild.put(STRING_WARNING_MESSAGE_C,System.label.FRU_List_Trigger_Error_Message_Non_IVD);
                     string strProductName = objSelectedProduct!=null?(string)objSelectedProduct.get('Name'):'';
                    updateFRUWarningMessageOnParent(objChild, objParent, oldRecords, mapParentToBeUpdated, productIdToRecordMap, '\r\n Warning for part ' +strProductName+ ' : ' + System.label.FRU_List_Trigger_Error_Message_Non_IVD);
                }
            }   
        }
        ilib_LogEvent.info('mapParentToBeUpdated : ' + (mapParentToBeUpdated != Null ? String.valueof(mapParentToBeUpdated.keySet()):'Null'));//CMSI-69
        if(!mapParentToBeUpdated.values().isEmpty() && !hasupdateran){
            if(Trigger.isUpdate){
                hasupdateran=true;
            }
            update mapParentToBeUpdated.values();
        }
        ilib_LogEvent.pop();//CMSI-69
    }

    /* METHOD NAME    : isProductFoundInFRUList
     * DESCRIPTION    : Check whether the FRU list has a product. If not add error
     * RETURN TYPE    : void
     * PARAMETER      : sObject objChild - child object which has been created / updated
                        Id serviceBOMId - active Service BOM found
                        Map<Id, Set<Id>> serviceBOMIDToFRULProductSet - Service BOM Id versus its FRU list
                        Product2 objSelectedProduct - product associated woth child object
    * Author       : Ritika           
    */
    private static void isProductFoundInFRUList(sObject objChild, sObject objParent, Id serviceBOMId, Map<Id, Set<Id>> serviceBOMIDToFRULProductSet, 
                                                Product2 objSelectedProduct, Product2 objParentProduct, Map<Id,sObject> mapParentToBeUpdated,
                                                Map<Id, sobject> oldRecords, Map<Id,Product2> productIdToRecordMap,String ivdUpgradeTypeonIP){
        ilib_LogEvent.push(LOG_TITLE + '.isProductFoundInFRUList'); //CMSI-69
        Set<Id> setFRUProduct = serviceBOMIDToFRULProductSet.get(serviceBOMId);
        ilib_LogEvent.info('setFRUProduct : '+setFRUProduct);
        if(objSelectedProduct != null && setFRUProduct != null && !setFRUProduct.contains(objSelectedProduct.Id)){
            if(objParentProduct !=null){
				if((String.IsBlank(ivdUpgradeTypeonIP)|| ivdUpgradeTypeonIP=='NONE'  ) && objParentProduct.Regulatory_Type__c != null && 
                (objParentProduct.Regulatory_Type__c.Contains('DX') || objParentProduct.Regulatory_Type__c.Contains('EUA')) || (!String.IsBlank(ivdUpgradeTypeonIP) && ivdUpgradeTypeonIP=='IVD')){
                    if(!UserInfo.getName().EqualsIgnoreCase(STRING_SAP_INTEGRATION_USER))
					objChild.addError(System.label.FRU_List_Trigger_Error_Message_IVD);
				}else{
					objChild.put(STRING_WARNING_MESSAGE_C,System.label.FRU_List_Trigger_Error_Message_Non_IVD);
					updateFRUWarningMessageOnParent(objChild, objParent, oldRecords, mapParentToBeUpdated, productIdToRecordMap, '\r\n Warning for part ' + objSelectedProduct.get('Name') + ' : ' + System.label.FRU_List_Trigger_Error_Message_Non_IVD);
				}

			}
        }else{
            objChild.put(STRING_WARNING_MESSAGE_C,'');
            updateFRUWarningMessageOnParent(objChild, objParent, oldRecords, mapParentToBeUpdated, productIdToRecordMap, '');
        }
        ilib_LogEvent.info('objChild : '+objChild);//CMSI-69
        ilib_LogEvent.pop();//CMSI-69
    }

    /* METHOD NAME    : updateFRUWarningMessageOnParent
     * DESCRIPTION    : Update the error message on parent object
     * RETURN TYPE    : void
     * Author       : Ritika           
    */
    private static void updateFRUWarningMessageOnParent(sObject objChild, sObject objParent, Map<Id, sobject> oldRecords, map<ID,sObject> mapParentToBeUpdated, 
                                            Map<Id,Product2> productIdToRecordMap, String strParentWarningMessage){
        ilib_LogEvent.push(LOG_TITLE + '.updateFRUWarningMessageOnParent');//CMSI-69
        ilib_LogEvent.info('objChild : '+objChild); //CMSI-69
        ilib_LogEvent.info('objParent : '+objParent);//CMSI-69
        ilib_LogEvent.info('strParentWarningMessage : '+strParentWarningMessage);//CMSI-69
        ilib_LogEvent.info('oldRecords : ' + (oldRecords != Null ? String.valueof(oldRecords.keySet()):'Null'));//CMSI-69
        ilib_LogEvent.info('mapParentToBeUpdated : ' + (mapParentToBeUpdated != Null ? String.valueof(mapParentToBeUpdated.keySet()):'Null'));//CMSI-69
        ilib_LogEvent.info('productIdToRecordMap : ' + (productIdToRecordMap != Null ? String.valueof(productIdToRecordMap.keySet()):'Null'));//CMSI-69
        String parentWarningMessage = (String)objParent.get(STRING_WARNING_MESSAGE_C) != null ? (String)objParent.get(STRING_WARNING_MESSAGE_C) : '';
        ilib_LogEvent.info('parentWarningMessage : '+parentWarningMessage);//CMSI-69
        if(oldRecords == null){
            objParent.put(STRING_WARNING_MESSAGE_C, parentWarningMessage + strParentWarningMessage);
        }else if(oldRecords != null && oldRecords.get((Id)objChild.get('Id')) != null){
            sObject objOldRecord = oldRecords.get((Id)objChild.get('Id'));
            String strWarningMessageRegex = '^.*Warning for part '+ productIdToRecordMap.get((Id)objOldRecord.get(STRING_PRODUCT_C)).Name + '.*.$';
            Pattern objPattern = Pattern.compile(strWarningMessageRegex); 
            ilib_LogEvent.info('objOldRecord : '+objOldRecord);
            ilib_LogEvent.info('strWarningMessageRegex : '+strWarningMessageRegex);
            ilib_LogEvent.info('objPattern : '+objPattern);
            if(parentWarningMessage.contains('\r\n')){
                for(String strIndividualError : parentWarningMessage.split('\r\n')){
                    Matcher objMatcher = objPattern.matcher(strIndividualError);
                    Boolean boolPatternMatchResult = objMatcher.matches();
                    ilib_LogEvent.message('objMatcher : '+objMatcher);
                    ilib_LogEvent.message('boolPatternMatchResult : '+string.valueOf(boolPatternMatchResult)); 
                    if(boolPatternMatchResult){
                        parentWarningMessage = parentWarningMessage.replaceFirst(strIndividualError, '');
                        ilib_LogEvent.message('parentWarningMessage : '+parentWarningMessage);
                        objParent.put(STRING_WARNING_MESSAGE_C, parentWarningMessage + strParentWarningMessage);
                        break;
                    }
                } 
            }else{
                Matcher objMatcher = objPattern.matcher(parentWarningMessage);
                Boolean boolPatternMatchResult = objMatcher.matches(); 
                ilib_LogEvent.fine('objMatcher : '+objMatcher);
                ilib_LogEvent.fine('boolPatternMatchResult : '+string.valueOf(boolPatternMatchResult));
                if(boolPatternMatchResult){
                    parentWarningMessage = ''; 
                    ilib_LogEvent.fine('parentWarningMessage : '+parentWarningMessage);
                    objParent.put(STRING_WARNING_MESSAGE_C, parentWarningMessage + strParentWarningMessage);
                }
            }
        }
        ilib_LogEvent.info('updated objParent : '+objParent);//CMSI-69
        ilib_LogEvent.info('updated parentWarningMessage : '+parentWarningMessage);//CMSI-69
		if(parentWarningMessage != (String)objParent.get(STRING_WARNING_MESSAGE_C)){
			mapParentToBeUpdated.put(objParent.Id,objParent);
		}
        ilib_LogEvent.info('updated mapParentToBeUpdated : ' + (mapParentToBeUpdated != Null ? String.valueof(mapParentToBeUpdated.keySet()):'Null'));//CMSI-69
        ilib_LogEvent.pop();//CMSI-69
    }
	
	/* METHOD NAME    : updateCurrentActiveContractOnIP
     * DESCRIPTION    : Update the Current Active Service Contract on the Installed Product
     * RETURN TYPE    : void
     * Author         : Shashank Singhal           
    */
	public static void updateCurrentActiveContractOnIP(set<Id> setInstalledProductIds){
		ilib_LogEvent.push(LOG_TITLE + '.updateCurrentActiveContractOnIP');//CMSI-69
        ilib_LogEvent.info('setInstalledProductIds : '+setInstalledProductIds);//CMSI-69
        map<Id, List<SVMXC__Service_Contract_Products__c>> mapIdtoListCoveredProducts = new map<Id, List<SVMXC__Service_Contract_Products__c>>();
		set<string> setItemNumbers = new set<string>();
		map<string, Integer> mapServiceLevelToRank = new map<string, Integer>();
		map<string, Integer> mapMaterialNumberToRank = new map<string, Integer>();
		List<SVMXC__Installed_Product__c> lstInstalledProducts = new List<SVMXC__Installed_Product__c>();
		for(SVMXC__Service_Contract_Products__c objCoveredProduct:new CoveredProductSelector().selectActiveCoveredProductsForIP(setInstalledProductIds)){
			if(!mapIdtoListCoveredProducts.containsKey(objCoveredProduct.SVMXC__Installed_Product__c)){
				mapIdtoListCoveredProducts.put(objCoveredProduct.SVMXC__Installed_Product__c, new List<SVMXC__Service_Contract_Products__c>());
			}
			mapIdtoListCoveredProducts.get(objCoveredProduct.SVMXC__Installed_Product__c).add(objCoveredProduct);
			
			if(objCoveredProduct.SVMXC__Service_Contract__r.SVMXC__Service_Plan__c != null && 
            objCoveredProduct.SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c != null){
				setItemNumbers.add(string.valueOf(objCoveredProduct.SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c));
			}
		}
		system.debug(mapIdtoListCoveredProducts);
        system.debug(setItemNumbers);
        ilib_LogEvent.info('mapIdtoListCoveredProducts : ' + (mapIdtoListCoveredProducts != Null ? String.valueof(mapIdtoListCoveredProducts.keySet()):'Null'));//CMSI-69
		ilib_LogEvent.info('setItemNumbers : '+setItemNumbers);//CMSI-69
        for(ServiceLevelRanking__mdt objServiceLevelRank:[Select MasterLabel, DeveloperName, Rank__c from ServiceLevelRanking__mdt]){
			mapServiceLevelToRank.put(objServiceLevelRank.MasterLabel, Integer.valueOf(objServiceLevelRank.Rank__c));
		}
		system.debug(mapServiceLevelToRank);
        ilib_LogEvent.info('mapServiceLevelToRank : ' + (mapServiceLevelToRank != Null ? String.valueof(mapServiceLevelToRank.keySet()):'Null'));
		if(!setItemNumbers.isEmpty()){
			for(Product2 objProd: new ProductsSelector().selectProductsForMaterialNumber(setItemNumbers)){
				if(objProd.Service_Level__c != null 
				&& mapServiceLevelToRank.containsKey(objProd.Service_Level__c)){
					mapMaterialNumberToRank.put(objProd.Material_Number__c, mapServiceLevelToRank.get(objProd.Service_Level__c));
				}else{
					mapMaterialNumberToRank.put(objProd.Material_Number__c, 1);
				}
			}
		}
		system.debug(mapMaterialNumberToRank);
		ilib_LogEvent.info('mapMaterialNumberToRank : ' + (mapMaterialNumberToRank != Null ? String.valueof(mapMaterialNumberToRank.keySet()):'Null'));//CMSI-69
		for(Id idInstalledProd:setInstalledProductIds){
			SVMXC__Installed_Product__c objIP = new SVMXC__Installed_Product__c(Id = idInstalledProd);
			Id idCurrentActiveServiceContract = null;
			integer intHighestRank = 0;
			if(mapIdtoListCoveredProducts.containsKey(idInstalledProd)){
                idCurrentActiveServiceContract = mapIdtoListCoveredProducts.get(idInstalledProd)[0].SVMXC__Service_Contract__c;
                if(mapIdtoListCoveredProducts.get(idInstalledProd)[0].SVMXC__Service_Contract__r.SVMXC__Service_Plan__c != null 
				  && mapIdtoListCoveredProducts.get(idInstalledProd)[0].SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c != null 
                  && mapMaterialNumberToRank.containsKey(string.valueOf(mapIdtoListCoveredProducts.get(idInstalledProd)[0].SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c))){
                       intHighestRank = mapMaterialNumberToRank.get(string.valueOf(mapIdtoListCoveredProducts.get(idInstalledProd)[0].SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c));
                   }
                for(SVMXC__Service_Contract_Products__c objCoveredProduct:mapIdtoListCoveredProducts.get(idInstalledProd)){
					if(objCoveredProduct.SVMXC__Service_Contract__r.SVMXC__Service_Plan__c != null 
					&& objCoveredProduct.SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c != null 
					&& mapMaterialNumberToRank.containsKey(string.valueOf(objCoveredProduct.SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c)) 
					&& mapMaterialNumberToRank.get(string.valueOf(objCoveredProduct.SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c)) > intHighestRank){
							intHighestRank = mapMaterialNumberToRank.get(string.valueOf(objCoveredProduct.SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c));
							idCurrentActiveServiceContract = objCoveredProduct.SVMXC__Service_Contract__c;
						}
				}
			}
			objIP.Currently_Active_Service_Contract__c = idCurrentActiveServiceContract;
			lstInstalledProducts.add(objIP);
		}
		ilib_LogEvent.info('lstInstalledProducts : '+UtilsCollection.getSetOfIds(lstInstalledProducts));//CMSI-69
		if(!lstInstalledProducts.isEmpty()){
			update lstInstalledProducts;
		}
		ilib_LogEvent.pop();//CMSI-69
	}
	
	/* METHOD NAME    : updateLatestExpiringContractOnIP
     * DESCRIPTION    : Update the Latest Expiring Service Contract on the Installed Product
     * RETURN TYPE    : void
     * Author         : Shashank Singhal           
    */
	public static void updateLatestExpiringContractOnIP(set<Id> setInstalledProductIds){
		ilib_LogEvent.push(LOG_TITLE + '.updateLatestExpiringContractOnIP');//CMSI-69
        ilib_LogEvent.info('setInstalledProductIds : '+setInstalledProductIds);//CMSI-69
        map<Id, Id> mapInstalledProductIdToLatestContractId = new map<Id, Id>();
		List<SVMXC__Installed_Product__c> lstInstalledProducts = new List<SVMXC__Installed_Product__c>();
		for(SVMXC__Service_Contract_Products__c objCoveredProduct:new CoveredProductSelector().selectOrderedCoveredProductsByContractEndDate(setInstalledProductIds)){
			if(!mapInstalledProductIdToLatestContractId.containsKey(objCoveredProduct.SVMXC__Installed_Product__c)){
				mapInstalledProductIdToLatestContractId.put(objCoveredProduct.SVMXC__Installed_Product__c, objCoveredProduct.SVMXC__Service_Contract__c);
			}
		}
		ilib_LogEvent.info('mapInstalledProductIdToLatestContractId : ' + (mapInstalledProductIdToLatestContractId != Null ? String.valueof(mapInstalledProductIdToLatestContractId.keySet()):'Null'));//CMSI-69
		for(Id idInstalledProd:setInstalledProductIds){
			SVMXC__Installed_Product__c objIP = new SVMXC__Installed_Product__c(Id = idInstalledProd);
			Id idLatestExpiringServiceContract = null;
			if(mapInstalledProductIdToLatestContractId.containsKey(idInstalledProd)){
				idLatestExpiringServiceContract = mapInstalledProductIdToLatestContractId.get(idInstalledProd);
			}
			objIP.Latest_Expiring_Service_Contract__c = idLatestExpiringServiceContract;
			lstInstalledProducts.add(objIP);
		}
		ilib_LogEvent.info('lstInstalledProducts : '+UtilsCollection.getSetOfIds(lstInstalledProducts));//CMSI-69
		if(!lstInstalledProducts.isEmpty()){
			update lstInstalledProducts;
		}
        ilib_LogEvent.pop();//CMSI-69
	}
	
	/* METHOD NAME    : addBussinessDays
     * DESCRIPTION    : Logic to add bussiness days on Onsite Response Due Date
     * RETURN TYPE    : void
     * Author         : Mandeep Singh           
    */
	public static Datetime addBussinessDays(Datetime onsiteResponseDate, Integer daysToAdd){ 
		ilib_LogEvent.push(LOG_TITLE + '.addBussinessDays()');//CMSI-69
		ilib_LogEvent.info('onsiteResponseDate : '+String.valueOf(onsiteResponseDate));//CMSI-69
		ilib_LogEvent.info('daysToAdd : '+String.valueOf(daysToAdd));//CMSI-69
		onsiteResponseDate = BusinessHours.nextStartDate(system.label.Onsite_Response_Business_Hour_Id, onsiteResponseDate);
    
        for (Integer elapsed = 0; elapsed < daysToAdd; elapsed++){
            onsiteResponseDate = onsiteResponseDate.addDays(1);
            if (!BusinessHours.isWithin(system.label.Onsite_Response_Business_Hour_Id, onsiteResponseDate))
                onsiteResponseDate = BusinessHours.nextStartDate(system.label.Onsite_Response_Business_Hour_Id, onsiteResponseDate);
        }
        TimeZone tz = UserInfo.getTimeZone();
        integer offset = tz.getOffset(onsiteResponseDate)/(60  * 1000);
        //onsiteResponseDate = onsiteResponseDate.addMinutes(-offset);
        Time targetTime = Time.newInstance(23, 59, 0, 0);
        onsiteResponseDate = Datetime.newInstanceGmt(onsiteResponseDate.dateGMT(), targetTime).addMinutes(-offset);
		ilib_LogEvent.info('onsiteResponseDate updated value : '+String.valueOf(onsiteResponseDate));//CMSI-69
		ilib_LogEvent.pop();//CMSI-69
        return onsiteResponseDate;
    }

     /*
    *  @AUTHOR:  Soumya
    *  @DESCRIPTION: To find the Field Support from User
    *  @PARAM :  Set of Owner Ids 
    *  return : Map of User and Field Support Ids
    */ 
     public static Map<id,id> fieldSupportFromUser(set<id> setUserIds){
		ilib_LogEvent.push(LOG_TITLE + '.fieldSupportFromUser()');//CMSI-69
		ilib_LogEvent.info('setUserIds : '+setUserIds);//CMSI-69
       Map<id,id> idUserToFieldSupportMap = new Map<id,id>(); 
        if(setUserIds.size()>0 && (lstFieldSupports.isEmpty() || Feature.isOn(WO_FEATURE_FLAG))){
            lstFieldSupports = new TechniciansSelector().selectTechniciansMatchingUsers(setUserIds);
        }
            if(lstFieldSupports.size()>0){
                for(SVMXC__Service_Group_Members__c objTechnician:lstFieldSupports){
                    if(!idUserToFieldSupportMap.containsKey(objTechnician.SVMXC__Salesforce_User__c))
                        idUserToFieldSupportMap.put(objTechnician.SVMXC__Salesforce_User__c,objTechnician.id);
                }
            }
		ilib_LogEvent.info('idUserToFieldSupportMap : '+(idUserToFieldSupportMap !=NULL ? String.valueOf(idUserToFieldSupportMap.keySet()) : 'NULL'));//CMSI-69
		ilib_LogEvent.pop();//CMSI-69
        return idUserToFieldSupportMap;
    }
       /* Class NAME    : ServiceSystemUtilityCollection
        *  UPDATE         : INC0203149 : Moved it to inner class as FSEs do not have accees to all Events and query needs to run in without sharing mode
        */ 
    public without sharing class ServiceSystemUtilityCollection {
        
        /* METHOD NAME    : checkTechniciansCalendar
        * DESCRIPTION    : check for the technicians whose calendar is not free now.
                    
        * UPDATE         : INC0203149 : Moved it to inner class as FSEs do not have accees to all Events and query needs to run in without sharing mode
        * RETURN TYPE    : Set<Id> - set of technician ids whose calendar is not free
        * PARAMETER      : accountIdToFSERoles - Map of account Id versus Map of technician role and technician
        */
        public Set<Id> checkTechniciansCalendar(Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles){

            ilib_LogEvent.push(LOG_TITLE + '.checkTechniciansCalendar()');//CMSI-69
            ilib_LogEvent.info('accountIdToFSERoles-->: '+accountIdToFSERoles);//CMSI-69
            Set<Id> setTechnicianToCheckCalendar = new Set<Id>();
            for(Id idAccount : accountIdToFSERoles.keySet()){
                for(Account_to_Field_Support__c accountTechnician : accountIdToFSERoles.get(idAccount).values()){
                    setTechnicianToCheckCalendar.add(accountTechnician.User__r.SVMXC__Salesforce_User__c);
                }
            }
            ilib_LogEvent.info('setTechnicianToCheckCalendar-->: '+setTechnicianToCheckCalendar);//CMSI-69
            Set<Id> setUnavailableTechnician = new Set<Id>();
            if((technicianEventList == null || technicianEventList.isEmpty()) && setTechnicianToCheckCalendar != null && setTechnicianToCheckCalendar.size() > 0){
                technicianEventList = new EventsSelector().getTechnicianCalender(system.now(), system.now(), setTechnicianToCheckCalendar, '%unavailable%');
            }
			if(technicianEventList != null && !technicianEventList.isEmpty()){
				for(Event objTechnicianEvent : technicianEventList)
				{
					setUnavailableTechnician.add(objTechnicianEvent.OwnerId);
				}
                ilib_LogEvent.info('setUnavailableTechnician-->: '+setUnavailableTechnician);//CMSI-69
			}
            ilib_LogEvent.pop();//CMSI-69  
            return setUnavailableTechnician; 
        }
		/**
         * DCP-17063
         *  @author Nitin Sood
         *  @description - get the existing work orders linked with a case with which a new work order is getting created
         * Update: INC0235280: Moved it to inner class as Channel partner users do not have access to all workorders and query needs to run in without sharing mode
         **/
        public Set<Id> getOtherWorkOrdersForSameCase(Set<Id> setCaseIds){
            ilib_LogEvent.push(LOG_TITLE + '.getOtherWorkOrdersForSameCase()');//CMSI-69 
            ilib_LogEvent.info('setCaseIds-->: '+setCaseIds);//CMSI-69 
            Set<Id> setExistingWORelatedCaseIds = new Set<Id>();
            if(setCaseIds.size() > 0){
                for(SVMXC__Service_Order__c objWorkOrder :  [Select Id,SVMXC__Case__c from SVMXC__Service_Order__c where SVMXC__Case__c in:setCaseIds]){
                    setExistingWORelatedCaseIds.add(objWorkOrder.SVMXC__Case__c);
                }
                ilib_LogEvent.info('setExistingWORelatedCaseIds-->: '+setExistingWORelatedCaseIds);//CMSI-69    
            }
            ilib_LogEvent.pop();//CMSI-69 
            return setExistingWORelatedCaseIds;
        }
        /*
        *  DCP-25271   
        *  @AUTHOR:  Digvijay
        *  @DESCRIPTION: To Populate the Work Order Resource Owner of Work Order 
                        --> Moved to service utility collection inner class from workorders class for executing in system context as part of incident
        *  @PARAM :  Set of Work Orders and List WO Resource Ids (in case of deletion) 
        *  return : void
        */ 
        public void insertWOResourceRecord(List<SVMXC__Service_Order__c> lstWorkOrders ,List<SVMXC__Work_Order_Resource__c> lstWORtobedel,List<SVMXC__Work_Order_Resource__c> lstWORtobeupdated){
            ilib_LogEvent.push(LOG_TITLE + '.insertWOResourceRecord()');//CMSI-69
            ilib_LogEvent.info('lstWorkOrders-->: '+UtilsCollection.getSetOfIds(lstWorkOrders));//CMSI-69
            ilib_LogEvent.info('lstWORtobedel-->: '+UtilsCollection.getSetOfIds(lstWORtobedel));//CMSI-69
            ilib_LogEvent.info('lstWORtobeupdated-->: '+UtilsCollection.getSetOfIds(lstWORtobeupdated));//CMSI-69
            set<String> setaccountToFetchAccToFieldSupp=new set<String>();  
            Set<String> setFSERoles = new Set<String>();//{'Primary Field Service Engineer','Primary Field Application Scientist'};
            Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles=new Map<Id,Map<String,Account_to_Field_Support__c>>();  
            List<SVMXC__Work_Order_Resource__c> lstWOResources=new List<SVMXC__Work_Order_Resource__c>();
            
            //delete WOR when Field Support is updated to null on Work Order
            if(lstWORtobedel!=null && lstWORtobedel.size()>0)
                delete lstWORtobedel;
            
            //update WOR when Field support or Schdelued Date is updated on Work Order.
            if(lstWORtobeupdated!=null && !lstWORtobeupdated.IsEmpty())
                lstWOResources.addAll(lstWORtobeupdated);
               
            ilib_LogEvent.info('lstWOResources-->: '+UtilsCollection.getSetOfIds(lstWOResources));//CMSI-69
              
            if(lstWorkOrders!=null){
                for(SVMXC__Service_Order__c objWorkOrder : lstWorkOrders){
                    if(objWorkOrder.SVMXC__Order_Type__c == STRING_LABEL_INSTALLATION || objWorkOrder.SVMXC__Order_Type__c == Label.WorkOrderTypeBillableInstall){
                        // setaccountToFetchAccToFieldSupp.add(objWorkOrder.SVMXC__Company__c);
                        if(objWorkOrder.Partner_Installation_WO__c == true){               
                            setaccountToFetchAccToFieldSupp.add(objWorkOrder.Account_Sold_To__c);
                            //DCP-30846
                            setFSERoles.add(STRING_LABEL_PARTNER_PRIMARY_FSE);
                            setFSERoles.add(STRING_LABEL_PARTNER_PRIMARY_FAS);
                        }else {
                            setaccountToFetchAccToFieldSupp.add(objWorkOrder.SVMXC__Company__c);
                            setFSERoles.add(STRING_LABEL_PRIMARY_FSE);
                            setFSERoles.add(STRING_LABEL_PRIMARY_FAS);
                        }  
                    }  
                    ilib_LogEvent.info('setFSERoles-->: '+setFSERoles);//CMSI-69   
                }
                  
                //fetch Account to Field Support for Work Order Account's   
                if(!setaccountToFetchAccToFieldSupp.isEmpty())
                    accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(setaccountToFetchAccToFieldSupp, setFSERoles);
                 
                 
                 /*
                 logic to insert WOR records.
                 Field Support on WO is inserted as Primary WOR for Non-Installtion Work orders.
                 Primary FSE and Primary FAS are inserted as WOR for installation Work orders
                 */
                 
                for(SVMXC__Service_Order__c objWorkOrder : lstWorkOrders){ 
                    //Field Support on WO is inserted as Primary WOR record.
                    //instead of trigger.insert, use lstWORtobeupdated & lstWORtobedel as null. These both lists passed as null from insert.
                    //in update they can be empty but cannot be null as they are initialized as a new reference.
                    if( (objWorkOrder.SVMXC__Order_Type__c == STRING_LABEL_INSTALLATION || objWorkOrder.SVMXC__Order_Type__c == Label.WorkOrderTypeBillableInstall ) && (lstWORtobeupdated == null && lstWORtobedel ==null)){
                        
                        Map<String,Account_to_Field_Support__c> mapAccToFieldSupport=new Map<String,Account_to_Field_Support__c>();
                        if(objWorkOrder.Partner_Installation_WO__c == true){ 
                            //DCP-30846
                            mapAccToFieldSupport=accountIdToFSERoles.get(objWorkOrder.Account_Sold_To__c);
                        }else{
                            mapAccToFieldSupport=accountIdToFSERoles.get(objWorkOrder.SVMXC__Company__c);
                        }
                        
                        if(mapAccToFieldSupport!=null){
                            for(String key:mapAccToFieldSupport.keyset()){
                                Account_to_Field_Support__c objFieldSupport=mapAccToFieldSupport.get(key);
                                if(objFieldSupport!=null ){
                                    SVMXC__Work_Order_Resource__c objWOResource=new SVMXC__Work_Order_Resource__c();
                                    objWOResource.SVMXC__Work_Order__c=objWorkOrder.id;
                                    objWOResource.SVMXC__Group_Member__c=objFieldSupport.User__c;
                                    //DCP-30846
                                    if(objFieldSupport.User_Role__c==STRING_LABEL_PRIMARY_FSE || objFieldSupport.User_Role__c==STRING_LABEL_PARTNER_PRIMARY_FSE){
                                        objWOResource.Primary__c=true;
                                        objWOResource.Schedule_Date_Time__c=objWorkOrder.SVMXC__Scheduled_Date_Time__c;
                                    }
                                    lstWOResources.add(objWOResource);
                                    
                                }
                            }
                        }
                        
                    }else if(objWorkOrder.SVMXC__Group_Member__c!=null){
                        SVMXC__Work_Order_Resource__c objWOResource=new SVMXC__Work_Order_Resource__c();
                        objWOResource.SVMXC__Work_Order__c=objWorkOrder.id;
                        objWOResource.SVMXC__Group_Member__c=objWorkOrder.SVMXC__Group_Member__c;
                        objWOResource.Schedule_Date_Time__c=objWorkOrder.SVMXC__Scheduled_Date_Time__c;
                        objWOResource.Primary__c=true;
                        lstWOResources.add(objWOResource);
                    }
                }
            }   
            if(lstWOResources!=null && !lstWOResources.isEmpty())
               upsert lstWOResources;
			   ilib_LogEvent.info('lstWOResources updated : '+UtilsCollection.getSetOfIds(lstWOResources));//CMSI-69
			   ilib_LogEvent.pop();//CMSI-69
        }

         /**
        * Method : fetchWOResource
        * Description : This method queries for the work order resources for a set of workorders
                        Added to fix the "Technician already exists in the work order resource list" error.
        * return: List of Work order resources
        **/
        public List<SVMXC__Work_Order_Resource__c> fetchWOResource(Set<Id> setWorkOrderIdforWOR){
			ilib_LogEvent.push(LOG_TITLE + '.fetchWOResource()');//CMSI-69
			ilib_LogEvent.info('setWorkOrderIdforWOR : '+setWorkOrderIdforWOR);//CMSI-69
            if(!setWorkOrderIdforWOR.isEmpty() && (lstWOR == null ||lstWOR.isEmpty())) {//CMCM-12168
                lstWOR = new WorkOrderResourceSelector().selectWorkOrderResources(setWorkOrderIdforWOR);
            }
            System.debug('lstWOR-->'+lstWOR);
			ilib_LogEvent.info('lstWOR : '+UtilsCollection.getSetOfIds(lstWOR));//CMSI-69
			ilib_LogEvent.pop();//CMSI-69
            return lstWOR;
        }
              

        /*
        *  #CMCM-273   
        *  @AUTHOR: Abhishek yadav
        *  @DESCRIPTION: To Populate entitlements on associated product (moving the code to without sharing so that the case update works if the cases are created by Charker user)
        *  @PARAM :  Set of associated Product Ids, boolean to check if it is update or insert
        *  return : void
        */    
        public void insertAppliedContractEntitlement(set<Id> associatedProductIds) {
            if(recurssionCheck == false){
                recurssionCheck = true;
                new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertUpdateAppliedContractEntitlement(associatedProductIds, true);
            }
        }
        /*
        *  #CMCM-273   
        *  @AUTHOR: Abhishek yadav
        *  @DESCRIPTION: To Populate entitlements on associated product (moving the code to without sharing so that the case update works if the cases are created by Charker user)
        *  @PARAM :  Set of associated Product Ids 
        *  return : void
        */ 
        public void updateAppliedContractEntitlement(set<Id> associatedProductIds) {
            if(recurssionCheck == false){
                recurssionCheck = true;
                new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertUpdateAppliedContractEntitlement(associatedProductIds, false);
            }
        }
         /*
        *  #CMCM-273   
        *  @AUTHOR: Abhishek yadav
        *  @DESCRIPTION: To Populate entitlements on associated product (moving the code to without sharing so that the case update works if the cases are created by Charker user)
        *  @PARAM :  Set of associated Product Ids 
        *  return : void
        */ 
        public void insertUpdateAppliedContractEntitlement(set<Id> associatedProductIds, boolean isInsert) {
            ilib_LogEvent.push(LOG_TITLE + '.insertUpdateAppliedContractEntitlement');
            ilib_LogEvent.info('associatedProductIds :'+associatedProductIds);
            List<String> lstFieldAPINames = new List<String>();
            lstFieldAPINames.add('Installed_Product__c');
            Set<Id> installproductIds = new Set<id>();
            Set<Id> setlocationIds = new Set<Id>();
            Set<Id> subscriptionIds = new Set<id>();
            List<Associated_Product__c> lstEntitlementAPList = new List<Associated_Product__c>();
            Map<Id,Associated_Product__c> associatedProdMap = new Map<Id,Associated_Product__c>();
            if(associatedProductIds!=null && !associatedProductIds.isEmpty()){
                lstEntitlementAPList = new ServiceUtilityCollection.ServiceSystemUtilityCollection().getAPRecords(associatedProductIds, installproductIds, setlocationIds, subscriptionIds, associatedProdMap);
            }
            
            if(lstEntitlementAPList!=null && !lstEntitlementAPList.isEmpty()){
                if(lstEntitlement == null || lstEntitlement.isEmpty()){
                    lstEntitlement = new List<Applied_Contract__c>();
                    lstEntitlement = ServiceUtilityCollection.insertEntitlement(lstEntitlementAPList, installproductIds , setlocationIds , lstFieldAPINames);
                }
                if(subscriptionIds!=null && associatedProdMap!=null && !associatedProdMap.isEmpty()) {
                    List<Applied_Contract__c> subscriptionEntitlementList = ServiceUtilityCollection.insertEntitlementForSubscription(subscriptionIds, associatedProdMap);
                    if(subscriptionEntitlementList!=null && !subscriptionEntitlementList.isEmpty()) {
                        lstEntitlement.addAll(subscriptionEntitlementList);
                    }
                }
            }
            if(lstEntitlement!=null && !lstEntitlement.isEmpty()){
                new ServiceUtilityCollection.ServiceSystemUtilityCollection().dmlOperation(lstEntitlement, isInsert);
            }
          
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }

        /*CMCM-6517 (CMCM-9 bug) Resolving NPath
        //Parameters: Set<Id>, List<Associated_Product__c>Set<Id> installproductIds = new Set<id>(), Set<Id> setlocationIds = new Set<Id>() , Set<Id> subscriptionIds = new Set<id>();
        //return List<Associated_Product__c>
        */
        public List<Associated_Product__c> getAPRecords(set<Id> associatedProductIds,  Set<Id> installproductIds, Set<Id> setlocationIds, Set<Id> subscriptionIds, Map<Id,Associated_Product__c> associatedProdMap){
            if(listEleAP.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
                listEleAP = new AssociatedProductSelector().selectAPwithIds(associatedProductIds);
            }
                if(listEleAP!=null && !listEleAP.isEmpty()){
                    for(Associated_Product__c objAP : listEleAP) {
                        if (objAP.Installed_Product__c != null) {
                            installproductIds.add(objAP.Installed_Product__c);
                        }
                        if (objAP.Subscription__c != null && objAP.Subscription__r.Status__c == STRING_SVMXC_STATUS_ACTIVE) {
                            subscriptionIds.add(objAP.Subscription__c);
                        }
                        if(objAP.Case__c != null) {
                            setCaseIdsCoverage.add(objAP.Case__c);
                        }
                        associatedProdMap.put(objAP.Id , objAP);
                    }
                }
            return listEleAP;
        }

        /*CMCM-6517 (CMCM-9 bug) Resolving NPath
        //Parameters: List<Applied_Contract__c>, boolean
        //return void
        */
        public void dmlOperation(List<Applied_Contract__c> lstEntitlement, boolean isInsert){
            if (lstEntitlement!=null && !lstEntitlement.isEmpty() && isInsert == true) {
                system.debug('DS_lstEntitlement INSERT-->'+lstEntitlement);
                INSERT lstEntitlement;
            }

            if (lstEntitlement!=null && !lstEntitlement.isEmpty() && isInsert == false) {
                system.debug('DS_lstEntitlement UPDATE-->'+lstEntitlement);
                INSERT lstEntitlement;
            }
        }

        /*
        *  #CMCM-273   
        *  @AUTHOR: Abhishek yadav
        *  @DESCRIPTION: To Populate entitlements on associated product (moving the code to without sharing so that the case update works if the cases are created by Charker user)
        *  @PARAM :  Set of associated Product Ids and Set of Subscription Ids
        *  return : void
        */ 
        public void deleteAppliedContractEntitlement(Set<Id> setAppliedContractIds) {
            if (setAppliedContractIds != null && !setAppliedContractIds.isEmpty()) {
                List<Id> recordsToBeDeleted = new List<Id>();
                recordsToBeDeleted.addAll(setAppliedContractIds);
                Database.delete(recordsToBeDeleted);
            }
        }
        /*
        *  #CMCM-273   
        *  @AUTHOR: Abhishek yadav
        *  @DESCRIPTION: To delete the Applied Contract
        *  @PARAM :  Set of associated Product Ids 
        *  return : void
        */
        public void deleteAppliedContract(Set<Id> associatedProductIds) {
            ilib_LogEvent.push(LOG_TITLE + '.deleteAppliedContract');
            ilib_LogEvent.info('associatedProductIds :'+associatedProductIds);
            if ((associatedProductIds != null && !associatedProductIds.isEmpty()) || toBeDeletedAppliedContract.isEmpty()) {
                toBeDeletedAppliedContract = new AppliedContractsSelector().selectAssociatedProductEntitlements(associatedProductIds);
            }
            if (toBeDeletedAppliedContract != null && !toBeDeletedAppliedContract.isEmpty()) {
                delete toBeDeletedAppliedContract;
            }
            ilib_LogEvent.pop();
        }
        /*
        *  #CMCM-269   
        *  @AUTHOR: Abhishek yadav
        *  @DESCRIPTION: To Populate entitlements on associated product (moving the code to without sharing so that the case update works if the cases are created by Charker user)
        *  @PARAM :  Set of associated Product Ids 
        *  return : void
        */    
        public void insertConsumableWarrantyContract(set<Id> associatedProductIds) {
            ilib_LogEvent.push(LOG_TITLE + '.insertConsumableWarrantyContract');
            ilib_LogEvent.info('associatedProductIds :'+associatedProductIds);
            Set<Id> caseIds = new Set<Id>();
            Set<Id> workOrderIds = new Set<id>();
            if(lstEntitlementAPList1.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
                lstEntitlementAPList1 = new AssociatedProductSelector().selectAPwithIds(associatedProductIds);
            }
            for(Associated_Product__c objAP : lstEntitlementAPList1) {
                if (objAP.Case__c != null) {
                    caseIds.add(objAP.Case__c);
                }
                if (objAP.Work_Order__c != null) {
                    workOrderIds.add(objAP.Work_Order__c);
                }
            }
            if(existingEntitlements1.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
                existingEntitlements1 = new AppliedContractsSelector().selectEntitlements(caseIds, workOrderIds);
            }
            ilib_LogEvent.message('existingEntitlements1--' + existingEntitlements1);
            // insert applied contract
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertConsumable(existingEntitlements1 , lstEntitlementAPList1);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        
        /*
        *  #CMCM-269   
        *  @AUTHOR: Abhishek yadav
        *  @DESCRIPTION: To Populate entitlements on associated product (moving the code to without sharing so that the case update works if the cases are created by Charker user)
        *  @PARAM :  Set of Case Ids & Set of work order Ids
        *  return : void
        */    
        public void updateConsumableWarrantyContract(set<Id> caseIds , Set<Id> workOrderIds) {
            ilib_LogEvent.push(LOG_TITLE + '.insertConsumableWarrantyContract');
            ilib_LogEvent.info('caseIds '+ caseIds  + ' workOrderIds '+workOrderIds);
            List<Associated_Product__c> lstEntitlementAPList = new List<Associated_Product__c>();
            Map<Id,List<Associated_Product__c>> caseworkOrderIdAssociatedProductMap = new Map<Id,List<Associated_Product__c>>();
            lstEntitlementAPList = new AssociatedProductSelector().selectAPwithCaseWOIds(caseIds , workOrderIds);
            for (Associated_Product__c ap : lstEntitlementAPList) {
                List<Associated_Product__c> apList;
                Id key = ap.Case__c != null ? ap.Case__c : ap.Work_Order__c;
                
                if (!caseworkOrderIdAssociatedProductMap.containsKey(key)) {
                    apList = new List<Associated_Product__c>();
                    caseworkOrderIdAssociatedProductMap.put(key, apList);
                } else {
                    apList = caseworkOrderIdAssociatedProductMap.get(key);
                }
                
                apList.add(ap);
                caseworkOrderIdAssociatedProductMap.put(key, apList);
            }
            ilib_LogEvent.message('caseworkOrderIdAssociatedProductMap--' + caseworkOrderIdAssociatedProductMap);
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().updateDeleteConsumableWarrantyContract(caseworkOrderIdAssociatedProductMap);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        /*
        *  #CMCM-269   
        *  @AUTHOR: Abhishek yadav
        *  @DESCRIPTION: To Populate entitlements on associated product (moving the code to without sharing so that the case update works if the cases are created by Charker user)
        *  @PARAM :  Set of associated Product Ids , Set of Case Ids & Set of work order Ids
        *  return : void
        */    
        public void deleteConsumableWarrantyContract(set<Id> associatedProductIds , set<Id> caseIds , Set<Id> workOrderIds) {
            ilib_LogEvent.push(LOG_TITLE + '.deleteConsumableWarrantyContract');
            ilib_LogEvent.info('associatedProductIds ' + associatedProductIds + 'caseIds ' + caseIds + ' workOrderIds '+workOrderIds);
            List<Associated_Product__c> lstEntitlementAPList = new List<Associated_Product__c>();
            Map<Id,List<Associated_Product__c>> caseworkOrderIdAssociatedProductMap = new Map<Id,List<Associated_Product__c>>();
            List<Applied_Contract__c> lstEntitlementsToBeDeleted = new  List<Applied_Contract__c>();
            lstEntitlementAPList = new AssociatedProductSelector().selectAPwithCaseWOIds(caseIds , workOrderIds);
            for (Associated_Product__c ap : lstEntitlementAPList) {
                List<Associated_Product__c> apList;
                Id key = ap.Case__c != null ? ap.Case__c : ap.Work_Order__c;
                if (!associatedProductIds.contains(ap.Id)) {
                    if (!caseworkOrderIdAssociatedProductMap.containsKey(key)) {
                        apList = new List<Associated_Product__c>();
                        caseworkOrderIdAssociatedProductMap.put(key, apList);
                    } else {
                        apList = caseworkOrderIdAssociatedProductMap.get(key);
                    }
                    
                    apList.add(ap);
                    caseworkOrderIdAssociatedProductMap.put(key, apList);
                }
            }
            lstEntitlementsToBeDeleted = new AppliedContractsSelector().selectEntitlements(caseIds, workOrderIds);
            ilib_LogEvent.message('lstEntitlementsToBeDeleted--' + lstEntitlementsToBeDeleted);
            if(lstEntitlementsToBeDeleted != null && !lstEntitlementsToBeDeleted.isEmpty()) {
                new ServiceUtilityCollection.ServiceSystemUtilityCollection().deleteConsumableAppliedContract(lstEntitlementsToBeDeleted);
            }
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().updateDeleteConsumableWarrantyContract(caseworkOrderIdAssociatedProductMap);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        /*
        *  #CMCM-269   
        *  @AUTHOR: Abhishek yadav
        *  @DESCRIPTION: To Populate entitlements on associated product (moving the code to without sharing so that the case update works if the cases are created by Charker user)
        *  @PARAM :  Map<Id,List<Associated_Product__c>> caseworkOrderIdAssociatedProductMap
        *  return : void
        */    
        public void updateDeleteConsumableWarrantyContract(Map<Id,List<Associated_Product__c>> caseworkOrderIdAssociatedProductMap) {
            Set<Id> toBeCreatedAppliedContract = new Set<Id>();
            Set<Id> toBeDeletedCaseWOIds = new Set<Id>();
            List<Applied_Contract__c> lstEntitlementsToBeDeleted = new  List<Applied_Contract__c>();
            List<Associated_Product__c> toBeCreatedAPList = new List<Associated_Product__c>();
            for (Id caseworkOrderId : caseworkOrderIdAssociatedProductMap.keySet()) {
                Boolean isConsumable = false;
                List<Associated_Product__c> associatedProdList = caseworkOrderIdAssociatedProductMap.get(caseworkOrderId);
                isConsumable = isConsumables(associatedProdList);
                if (isConsumable) {
                    toBeCreatedAppliedContract.add(caseworkOrderId);
                    toBeCreatedAPList.add(associatedProdList.get(0));
                } else {
                    toBeDeletedCaseWOIds.add(caseworkOrderId);
                }
            }
            ilib_LogEvent.message('toBeCreatedAppliedContract--' + toBeCreatedAppliedContract);
            ilib_LogEvent.message('toBeDeletedCaseWOIds--' + toBeDeletedCaseWOIds);
            if(existingEntitlements.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
                existingEntitlements = new AppliedContractsSelector().selectEntitlements(toBeCreatedAppliedContract, toBeCreatedAppliedContract);
            }
            lstEntitlementsToBeDeleted = new AppliedContractsSelector().selectEntitlements(toBeDeletedCaseWOIds, toBeDeletedCaseWOIds);
            ilib_LogEvent.message('existingEntitlements--' + existingEntitlements);
            ilib_LogEvent.message('lstEntitlementsToBeDeleted--' + lstEntitlementsToBeDeleted);
            if(lstEntitlementsToBeDeleted != null && !lstEntitlementsToBeDeleted.isEmpty()) {
                new ServiceUtilityCollection.ServiceSystemUtilityCollection().deleteConsumableAppliedContract(lstEntitlementsToBeDeleted);
            }
            // insert applied contract
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertConsumable(existingEntitlements , toBeCreatedAPList);
        }
        private Boolean isConsumables(List<Associated_Product__c> associatedProductList) {
            for (Associated_Product__c associatedprod : associatedProductList) {
                if (associatedprod.Material_Class__c == 'Consumables' && associatedprod.Product_Lot_Number__c != null && associatedprod.Expired_Date__c != null && associatedprod.Is_Expired__c == false) {
                    return true;
                }
            }
            return false;
        }
    /*
    *  #CMCM-269   
    *  @AUTHOR: Abhishek yadav
    *  @DESCRIPTION: get Consumble contract
    *  @PARAM :  void
    *  return : Id of Service Contract
    */   
    public String getConsumbleContract() {
        Integer currentYear = System.today().year(); 
        String externalId = 'Consumable Contract '+currentYear +'%';
        if(consumableContractList.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
            consumableContractList = new ServiceContractSelector().selectServiceContractByExternalId(externalId);
        }
        return !consumableContractList.isEmpty() ? consumableContractList.get(0).Id : null;
    }
    /*
    *  #CMCM-269   
    *  @AUTHOR: Abhishek yadav
    *  @DESCRIPTION: insert applied contract
    *  @PARAM :  List<Applied_Contract__c> existingEntitlements , List<Associated_Product__c> lstEntitlementAPList
    *  return : void
    */   
    public void insertConsumable (List<Applied_Contract__c> existingEntitlements , List<Associated_Product__c> lstEntitlementAPList) {
        ServiceUtilityCollection.ServiceSystemUtilityCollection serviceUtilCollection = new ServiceUtilityCollection.ServiceSystemUtilityCollection();
        String consumableContractId;
        Map<Id, Applied_Contract__c> appliedContractMap = new Map<Id, Applied_Contract__c>();
        Map<Id,Applied_Contract__c> lstEntitlementMap = new  Map<Id,Applied_Contract__c>();
        consumableContractId = new ServiceUtilityCollection.ServiceSystemUtilityCollection().getConsumbleContract();
            // Populate the appliedContractMap with the existing entitlements
            for (Applied_Contract__c appliedContract : existingEntitlements) {
                // Use Case Number or Work Order as the key
                if (appliedContract.Service_Contract__c == consumableContractId) {
                    Id key = appliedContract.Case_Number__c != null ? appliedContract.Case_Number__c : appliedContract.Work_order__c;
                    appliedContractMap.put(key, appliedContract);
                }
            }
            // Check each Associated_Product__c and put to lstEntitlementMap if not found in appliedContractMap
            for (Associated_Product__c objAP : lstEntitlementAPList) {
                Id key = objAP.case__c != null ? objAP.case__c : objAP.Work_Order__c;
                
                if (!appliedContractMap.containsKey(key)) {
                    lstEntitlementMap.put(key,serviceUtilCollection.initInsertConsumable(objAP));
                }
            }
            ilib_LogEvent.message('appliedContractMap--' + appliedContractMap);
        	ilib_LogEvent.message('lstEntitlementMap--' + lstEntitlementMap);
            if (lstEntitlementMap!=null && !lstEntitlementMap.isEmpty()) {
                insert lstEntitlementMap.values();
            }
    }
    /*
    *  #CMCM-269   
    *  @AUTHOR: Abhishek yadav
    *  @DESCRIPTION: insert applied contract
    *  @PARAM :  Associated_Product__c objAP
    *  return : Applied_Contract__c
    */   
    public Applied_Contract__c initInsertConsumable (Associated_Product__c objAP) {
        Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.Service_Contract__c = new ServiceUtilityCollection.ServiceSystemUtilityCollection().getConsumbleContract();
        objEntitlement.Work_Order__c = objAP.Work_Order__c != null ? objAP.Work_Order__c : null;
        objEntitlement.Case_Number__c = objAP.case__c != null ? objAP.case__c : null;
        objEntitlement.Applied_Contract_Source__c = 'Associated Product'; // Added by Dhairya Shah for CMCM-7287
        objEntitlement.Record_Creation_Source__c = 'Backend Code';
        return objEntitlement;
    }
    /*
    *  #CMCM-269   
    *  @AUTHOR: Abhishek yadav
    *  @DESCRIPTION: delete applied contract
    *  @PARAM :  List<Applied_Contract__c> existingEntitlements
    *  return : void
    */ 
    public void deleteConsumableAppliedContract(List<Applied_Contract__c>lstEntitlementsToBeDeleted ) {
        String consumableContractId;
        consumableContractId = new ServiceUtilityCollection.ServiceSystemUtilityCollection().getConsumbleContract();
        List<Applied_Contract__c> consumableContracttoBedeleted = new List<Applied_Contract__c>();
        for (Applied_Contract__c appliedContract : lstEntitlementsToBeDeleted) {
                if(appliedContract.Service_Contract__c == consumableContractId) {
                    consumableContracttoBedeleted.add(appliedContract);
                }
        }
        if (consumableContracttoBedeleted!=null && !consumableContracttoBedeleted.isEmpty()) {
            delete consumableContracttoBedeleted;
        }
    }
    }
   
    /**
    *  @author Soumya Sahu
    *  @description Fetch the Queue Ids from Set of Queue Names
    *  @param Set of Queue Names
    *  @return List of Queues  
    **/
    public static List<Group> getQueueFromName(Set<string> setQueueDeveloperNames) 
    {
        ilib_LogEvent.push(LOG_TITLE + '.getQueueFromName');//CMSI-69
        ilib_LogEvent.info('setQueueDeveloperNames :'+setQueueDeveloperNames);//CMSI-69
        List<String> listDevName = new List<String>();
        listDevName.addAll(setQueueDeveloperNames);
        if(lstQueues.isEmpty()){
            lstQueues = new GroupsSelector().getQueueIdbyDeveloperName(listDevName,'Queue');
        }
        ilib_LogEvent.info(lstQueues != null ? String.valueOf(UtilsCollection.getSetOfIds(lstQueues)) : 'List is Empty');//CMSI-69
        ilib_LogEvent.pop();//CMSI-69
        //Refactor PB :: Work_Order_Assignment_for_Quote_Creation
        return lstQueues;
    }

    /**
*  @author Tapas 
*  @description classify entitlements based on line types viz. parts, labor, consumable included
*  @param list of entitlements 
*  @return void
**/
    public static  Map<String, Map<Id,Applied_Contract__c>> classifyEntitlementsByLineTypesIncluded(List<Applied_Contract__c> lstEntitlement) 
    {
        ilib_LogEvent.push(LOG_TITLE + '.classifyEntitlementsByLineTypesIncluded');//CMSI-69
        ilib_LogEvent.info('lstEntitlement :'+lstEntitlement);//CMSI-69
        map<Id,Applied_Contract__c> mapWOIdConsContract = new map<Id,Applied_Contract__c>();
        map<Id,Applied_Contract__c> mapWOIdSpareContract = new map<Id,Applied_Contract__c>();
        map<Id,Applied_Contract__c> mapWOIdPartsOnlyContract = new map<Id,Applied_Contract__c>();
        map<Id,Applied_Contract__c> mapWOIdLaborContract = new map<Id,Applied_Contract__c>();
        Map<String, Map<Id,Applied_Contract__c>> mapLineTypeToContractsMap = new Map<String, Map<Id,Applied_Contract__c>>();
        
        for(Applied_Contract__c appContract : lstEntitlement)
        {
            if(appContract.Service_Contract__r.SVMXC__Service_Plan__r.Name == STRING_PARTS_ONLY)
                mapWOIdPartsOnlyContract.put(appContract.Work_order__c, appContract);
            if(appContract.Service_Contract__r.Consumables_Included__c)
                mapWOIdConsContract.put(appContract.Work_order__c, appContract);
            if(appContract.Service_Contract__r.Parts_Included__c)
                mapWOIdSpareContract.put(appContract.Work_order__c, appContract);
            if(appContract.Service_Contract__r.Labor_Included__c)
                mapWOIdLaborContract.put(appContract.Work_order__c, appContract);
        }
        mapLineTypeToContractsMap.put('Parts Only', mapWOIdPartsOnlyContract);
        mapLineTypeToContractsMap.put('Consumable', mapWOIdConsContract);
        mapLineTypeToContractsMap.put('Spare', mapWOIdSpareContract);
        mapLineTypeToContractsMap.put('Labor', mapWOIdLaborContract); 
        ilib_LogEvent.message((mapLineTypeToContractsMap != Null ? String.valueof(mapLineTypeToContractsMap.keySet()):'Map is empty')); //CMSI-69      
        ilib_LogEvent.pop();//CMSI-69
        return mapLineTypeToContractsMap;
    } 

      /*
    *  @AUTHOR: Service Max
    *  @DESCRIPTION: to create pm plan from pm offerings 
    *  @PARAM :  List<SVMXC__Service_Contract__c> newList
    *  @RETURN:  void
    */
	
	public static void createPMPlansFromPMOfferings(Set<Id> setContractIds){
        ilib_LogEvent.push(LOG_TITLE + '.createPMPlansFromPMOfferings');//CMSI-69
        ilib_LogEvent.info('setContractIds :'+setContractIds);//CMSI-69
        Set<Id> setSCwithCoveredProduct = new Set<Id>();
        
        //Check if the covered product exists for the contract
        if(coveredProductList.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
            coveredProductList = new CoveredProductSelector().selectCoveredProductsForServiceContracts(setContractIds);
        }
        for(SVMXC__Service_Contract_Products__c coveredProduct : coveredProductList){
            if(coveredProduct.SVMXC__Installed_Product__c != null && coveredProduct.SVMXC__Installed_Product__r.SVMXC__Product__r.Condition_Type__c != 'Loaner' && coveredProduct.SVMXC__Installed_Product__r.SVMXC__Product__r.Serial_Number_Profile__c != 'I02'){
           		setSCwithCoveredProduct.add(coveredProduct.SVMXC__Service_Contract__c);
            }else{
                setContractIds.remove(coveredProduct.SVMXC__Service_Contract__c);
            } 
        }
        ilib_LogEvent.message((setSCwithCoveredProduct != Null ? String.valueof(setSCwithCoveredProduct):'Set is empty'));//CMSI-69
        //Check if there is an Active PM plan already added to the Service Contract
        if(lstPMPlan.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
            lstPMPlan = new PreventiveMaintenancePlansSelector().selectPMPlanForSMC(setContractIds);
        }
        for(SVMXC__PM_Plan__c objPMPlan : lstPMPlan){
            if(objPMPlan.SVMXC__Status__c == STRING_SVMXC_STATUS_ACTIVE){    
                setContractIds.remove(objPMPlan.SVMXC__Service_Contract__c);
            }
        } 
        ilib_LogEvent.message((setContractIds != Null ? String.valueof(setContractIds):'Set is empty'));//CMSI-69
        //Iterate on the service contracts which are active and not in the set to be by passed.
        if(lstContracts.isEmpty() || Feature.isOn(WO_FEATURE_FLAG)){
            lstContracts = new ServiceContractSelector().selectServiceContractsByStatus(setContractIds, 'Active');
        }
        if(!lstContracts.isEmpty()){
            List<List<SVMXC__Service_Contract__c>> result = new List<List<SVMXC__Service_Contract__c>>();
            //call splitlist method to split the list into smaller chunks of size 50.
            splitList(lstContracts, 10, result);
            //queueable thread
            ilib_Queueablethread  queueableThread =new ilib_Queueablethread('createPMPlans');
            //iterate over list of chunks
            for(List<SVMXC__Service_Contract__c> contractsBatch : result){
                System.debug('contractsBatch-->'+contractsBatch);
                //enqueue job
                queueableThread.logandQueue(new PMPlanCreationQueueable(contractsBatch, setSCwithCoveredProduct), 'PMPlanCreationQueueable','createPMPlansForPMOfferings');
            }
            if(queueableThread != null && !queueableThread.lstQueueableJobs.isEmpty()){
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
            }
        }     
        ilib_LogEvent.pop();   //CMSI-69
    } 
    /*
    *  @AUTHOR: Service Max
    *  @DESCRIPTION: to create pm plan from pm offerings 
    *  @PARAM :  List<SVMXC__Service_Contract__c> newList, Set<Id> setSCwithCoveredProduct
    *  @RETURN:  void
    */
    public static void pMPlanCreation(List<SVMXC__Service_Contract__c> lstContracts, Set<Id> setSCwithCoveredProduct){
        ilib_LogEvent.push(LOG_TITLE + '.pMPlanCreation');//CMSI-69
        ilib_LogEvent.info('lstContracts :'+lstContracts);//CMSI-69
        ilib_LogEvent.info('setSCwithCoveredProduct :'+setSCwithCoveredProduct);//CMSI-69
        for(SVMXC__Service_Contract__c contract: lstContracts){
            if(setSCwithCoveredProduct.contains(contract.Id)){
                String contractEndDate = contract.SVMXC__End_Date__c.year()+'-'+contract.SVMXC__End_Date__c.month()+'-'+contract.SVMXC__End_Date__c.day();
                    
                //Builing Request to invoke the managed package webservice o;lkpo;jlio0-=
                SVMXC.INTF_WebServicesDef.INTF_TargetRecord targetTemp = new SVMXC.INTF_WebServicesDef.INTF_TargetRecord();
                SVMXC.INTF_WebServicesDef.INTF_StringMap tempStringMap1 = new SVMXC.INTF_WebServicesDef.INTF_StringMap('SVMX_recordId',contract.Id);
                SVMXC.INTF_WebServicesDef.INTF_StringMap tempStringMap2 = new SVMXC.INTF_WebServicesDef.INTF_StringMap('Id',contract.Id);
                SVMXC.INTF_WebServicesDef.INTF_StringMap tempStringMap3 = new SVMXC.INTF_WebServicesDef.INTF_StringMap('SVMXC__End_Date__c',contractEndDate);
                targetTemp.stringMap.add(tempStringMap1);
                
                targetTemp.headerRecord.objName = STRING_SERVICE_CONTRACT;
                
                SVMXC.INTF_WebServicesDef.INTF_Record recordstemp = new SVMXC.INTF_WebServicesDef.INTF_Record();
                recordstemp.targetRecordAsKeyValue.add(tempStringMap2);
                recordstemp.targetRecordAsKeyValue.add(tempStringMap3);
                recordstemp.targetRecordId=contract.Id;
                targetTemp.headerRecord.records.add(recordstemp);
                SVMXC.INTF_WebServicesDef.INTF_ActivateContract(targetTemp);
            }
        }
        ilib_LogEvent.pop(); //CMSI-69
    }
    /**
     * Method: splitList
     * Description: It splits the given list into smaller chunks based on the splitsize
     * params: List<object> items, splitsize and List<List<Object>> result
     * return: void
     **/
    public static void splitList(List<Object> items, Integer splitSize, List<List<Object>> result) {
        ilib_LogEvent.push(LOG_TITLE + '.splitList');//CMSI-69
        ilib_LogEvent.info('items :'+items);//CMSI-69
        ilib_LogEvent.info('splitSize :'+splitSize);//CMSI-69
        ilib_LogEvent.info('result :'+result);//CMSI-69
        List<Object> protoList = items.clone();
        protoList.clear();
        List<Object> tempList = protoList.clone();
        Integer index = 0;
        Integer count = 0;
        Integer size = items.size();
        //iterate over the items 
        while(index < size) {
            tempList.add(items[index++]);
            count++;
            //split the list add to another one if it reaches splisize.
            if(count == splitSize) {
                //add the all the smaaler chunks to result
                result.add(tempList);
                tempList = protoList.clone();
                count = 0;
            }
        }
        if(!tempList.isEmpty()) {
            result.add(tempList);
            ilib_LogEvent.info('result :'+result);//CMSI-69
        }
        ilib_LogEvent.pop(); //CMSI-69
    }
              /**
*  @author Debanka
*  @description To create files from attachment
*  @return void
**/
    public static void createFilesFromAttachment(Attachment attach){
        ilib_LogEvent.push(LOG_TITLE + '.createFilesFromAttachment');//CMSI-69
        ilib_LogEvent.info('attachment :'+attach);//CMSI-69
       //Insert ContentVersion
    ContentVersion cVersion = new ContentVersion();
    cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
    cVersion.PathOnClient = attach.Name;//File name with extention
    cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.
    cVersion.OwnerId = attach.OwnerId;//Owner of the file
    cVersion.Title = attach.Name;//Name of the file
    cVersion.VersionData = attach.Body;//File content
    Insert cVersion;
 
   //After saved the Content Verison, get the ContentDocumentId
     Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
 
   //Insert ContentDocumentLink
   ContentDocumentLink cDocLink = new ContentDocumentLink();
   cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
   cDocLink.LinkedEntityId = attach.ParentId;//Add attachment parentId
   cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
   cDocLink.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
   Insert cDocLink;
   ilib_LogEvent.info('cDocLink :'+cDocLink);//CMSI-69
   ilib_LogEvent.pop(); //CMSI-69
    }	

         /*
          *  @AUTHOR:  
          *  @DESCRIPTION: createTransationHistoryRecord
          *  return : void
          */
    public static SVMXC__Stock_History__c createTransationHistoryRecord(String changeType, SVMXC__Product_Stock__c productStockRecord, SVMXC__Product_Serial__c stockSerialRecord, String status, String transactionType, Decimal transactionQuantity){
        ilib_LogEvent.push(LOG_TITLE + '.createTransationHistoryRecord');//CMSI-69
        ilib_LogEvent.info('changeType :'+changeType);//CMSI-69
        ilib_LogEvent.info('productStockRecord :'+productStockRecord);//CMSI-69
        ilib_LogEvent.info('stockSerialRecord :'+stockSerialRecord);//CMSI-69
        ilib_LogEvent.info('transactionType :'+transactionType);//CMSI-69
        ilib_LogEvent.info('transactionQuantity :'+transactionQuantity);//CMSI-69
        SVMXC__Stock_History__c stockHistory = new SVMXC__Stock_History__c();
        stockHistory.SVMXC__Change_Type__c = changeType;
        stockHistory.SVMXC__Changed_By__c = UserInfo.getUserId();
        stockHistory.SVMXC__Date_Changed__c = System.Now();
        stockHistory.SVMXC__Product__c = productStockRecord.SVMXC__Product__c;
        stockHistory.SVMXC__Product_Stock__c = productStockRecord.Id;
        stockHistory.SVMXC__Location__c = productStockRecord.SVMXC__Location__c;
        if(productStockRecord.SVMXC__Quantity2__c != null){
            if(changeType == STRING_LABEL_CHANGETYPE_INCREASE){
                stockHistory.SVMXC__Quantity_before_change2__c = productStockRecord.SVMXC__Quantity2__c - transactionQuantity;
            }else if(changeType == STRING_LABEL_CHANGETYPE_DECREASE){
                stockHistory.SVMXC__Quantity_before_change2__c = productStockRecord.SVMXC__Quantity2__c + transactionQuantity;
            }
            stockHistory.SVMXC__Quantity_after_change2__c = productStockRecord.SVMXC__Quantity2__c;
        }else{
            stockHistory.SVMXC__Quantity_before_change2__c = 0;
            stockHistory.SVMXC__Quantity_after_change2__c = 0;
        }
        stockHistory.SVMXC__Status__c = status; 
        stockHistory.SVMXC__Transaction_Type__c = transactionType;
        stockHistory.SVMXC__Product_Serial__c = stockSerialRecord != null ? stockSerialRecord.Id : null;
        stockHistory.SVMXC__Transaction_Quantity2__c = transactionQuantity;
        stockHistory.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('SVMXC__Stock_History__c','Stock History');
        ilib_LogEvent.info('stockHistory ID'+stockHistory.Id);//CMSI-69
        ilib_LogEvent.pop(); //CMSI-69
        return stockHistory;
    }

    /**
     *  @author Tapas
     *  @description RITM0503667, called from PartsORderdataReceiver/EquipmentMasterDataReceiver. 
     * 	Sends email to GFSL if shipped Part missing in SFDC, also adds those values to Missing_Products__c
     *  @Release - Aug2021
     *  this method is covered in TestPartsOrderDataReceiver.testPartsOrderUpdateHTTPPostForMissingProduct() class
     * Modified - DCP-50068 - added logic for a new field and separated email and missing products update functioanlity
     * Modified - CMCM-2846 - added logic to replace custom settings Missing_Products__c with custom object Missing_Product__c
     **/
    public static void sendEmailToGFSLAndStoreProdExtId(Set<String> productExtIds){
        ilib_LogEvent.push(LOG_TITLE + '.sendEmailToGFSLAndStoreProdExtId'); 
        ilib_LogEvent.info('productExtIds : ' + productExtIds); 
        system.debug('Inside sendEmailToGFSLAndStoreProdExtId');
        Set<String> existingProductIds = new Set<String>();
        for (Missing_Product__c existingProd : [SELECT Product_External_Id__c FROM Missing_Product__c  where Product_External_Id__c in : productExtIds ]) {
            existingProductIds.add(existingProd.Product_External_Id__c);
        }
        system.debug('existingProductIds=='+ existingProductIds);
        List<Missing_Product__c> newProducts = new List<Missing_Product__c>();
        for (String prodId : productExtIds) {
            if (!existingProductIds.contains(prodId)) {
                Missing_Product__c newProd = new Missing_Product__c(Product_External_Id__c = prodId);
                newProducts.add(newProd);
            }
        }
        system.debug('newProducts=='+ newProducts);
        if (!newProducts.isEmpty()) {
            insert newProducts;
        }
        system.debug('Number of new Missing Product records created=='+ newProducts.size());
        ilib_LogEvent.info('Number of new Missing Product records created: ' + newProducts.size());
    
        if (Feature.isOn('MissingProductNotificationsToGFSL')) {
            system.debug('Before sendEmailToGFSL');
            sendEmailToGFSL(productExtIds);
        }
    
        ilib_LogEvent.pop(); 
    }
    
    /*******************************************************************************************************
    * @description DCP-50068 - send Email to GFSL for Missing Products
    * @param productExtIds Set<String>
    * @param productExtIds String
    * @return void
    * Modified - CMCM-2846 - added logic to replace custom settings Missing_Products__c with custom object Missing_Product__c
    */
    private static void sendEmailToGFSL(Set<String> productExtIds) {
        system.debug('Inside sendEmailToGFSL');
        List<Messaging.SingleEmailMessage>  lstEmails = new List<Messaging.SingleEmailMessage>();
        String emailBodyGFSL = 'Following products are missing in SFDC, which is impacting inventory count and auto debrief for Field. We request to sync the missing products.';
        String htmlBodyGFSL = 'Hi, <br><br>' + emailBodyGFSL + '<br><br>List of product(s):';
        for(String prodExtId :  productExtIds){
            htmlBodyGFSL += '<br>' + prodExtId;
        }
        htmlBodyGFSL += '<br><br>Thanks,<br>GIS';
        system.debug('htmlBodyGFSL=='+ htmlBodyGFSL);
        SendEmailNotification.EmailConditionsWrapper objWrapGFSL = new SendEmailNotification.EmailConditionsWrapper();
        objWrapGFSL.lstToAddresses = new List<String>{System.Label.GFSL_Email_Address};
        objWrapGFSL.subject = 'Action Required: Material(s) missing in DCP';
        objWrapGFSL.htmlEmailBody = htmlBodyGFSL;
        lstEmails.add(SendEmailNotification.sendEmailWithEmailConditionsWrapper(objWrapGFSL));
        Messaging.SendEmailResult[] lstResults = Messaging.sendEmail(lstEmails,false); 
        system.debug('lstResults=='+ lstResults);
    }

    /* METHOD NAME    : convertHoursToMinutes
     * DESCRIPTION    : fetch string total time in HH:MM and convert it to Minute
     * RETURN TYPE    : Integer
     * PARAMETER      : String hoursValue
    */
    public static integer convertHoursToMinutes(String hoursValue){
        ilib_LogEvent.push(LOG_TITLE + '.convertHoursToMinutes');//CMSI-69
        ilib_LogEvent.info('hoursValue :'+hoursValue);//CMSI-69
        Integer totalMinutes = 0;
        if(!string.isBlank(hoursValue)){
        List<String> hoursAndMinute = hoursValue.split(':');
        totalMinutes = (Integer.valueOf(hoursAndMinute[0]) * 60) + (hoursAndMinute.size() > 1 ? Integer.valueOf(hoursAndMinute[1]) : 0);
        }
        ilib_LogEvent.info('total minutes'+totalMinutes);//CMSI-69
        ilib_LogEvent.pop(); //CMSI-69
        return totalMinutes;
    }

    /* METHOD NAME    : convertMinutesToHours
     * DESCRIPTION    : fetch Integer total minutes and convert it to String in the form HH:MM
     * RETURN TYPE    : String
     * PARAMETER      : Integer minuteValue
    */
    public static string convertMinutesToHours(Integer minuteValue){
        ilib_LogEvent.push(LOG_TITLE + '.convertMinutesToHours');//CMSI-69
        ilib_LogEvent.info('minuteValue :'+minuteValue);//CMSI-69
        Integer totalHours = 0;
        Integer totalMinutes = 0;
        totalHours = minutevalue/60;
        totalMinutes = math.mod(minutevalue,60);
        if(totalMinutes > INTEGER_MIN_MINUTES){
         ilib_LogEvent.info('Total Hours :'+totalHours);//CMSI-69
         ilib_LogEvent.pop();//CMSI-69
         return string.valueof(totalHours+':'+totalMinutes);
        }
        else{
         ilib_LogEvent.pop();//CMSI-69
         return string.valueof(totalHours);
        }
    }
	
	/*
    *  @author:  Vignesh Sethuramalingam    
    *  @description: Utility method to Due date time based on time interval and Business hours metadata. 
    *  @return : void
    */ 
	public static DateTime calculateDueTimeOnWorkingHours(Timezone paramTZ , Business_Hours_Setting__mdt paramBusinessHour , DateTime paramStartTime ,Integer paramSecToCalculate ){
		Integer secToCalculate = paramSecToCalculate;
		Timezone tz = paramTZ;
		Business_Hours_Setting__mdt objBusinessHour = paramBusinessHour;
		Integer longOffsetInSeconds = tz.getOffset(paramStartTime)/1000;
		Datetime loggedUserTime = paramStartTime.addseconds(longOffsetInSeconds);
		Datetime estimatedTime = loggedUserTime.addSeconds(secToCalculate) ;
		Datetime todayWorkStartTime = ((DateTime)Date.newInstance(loggedUserTime.year(), loggedUserTime.month(), loggedUserTime.day())).addHours(Integer.valueOf(objBusinessHour.StartTimeOfTheDay__c));
		Datetime todayWorkEndTime = ((DateTime)Date.newInstance(loggedUserTime.year(), loggedUserTime.month(), loggedUserTime.day())).addHours(Integer.valueOf(objBusinessHour.EndHourOfTheDay__c));
		Datetime acceptanceDueDate ;

		String dayOfWeek = paramStartTime.format('EEEE');
		Integer intAddDays = 1;
		if(dayOfWeek == STRING_DAY_OF_WEEK_FRIDAY){
			intAddDays = 3;
		}else if(dayOfWeek == STRING_DAY_OF_WEEK_SATURDAY){
			intAddDays = 2;
		}
		Datetime nextStartDate = todayWorkStartTime.addDays(intAddDays);

		//Scenario 1: If the Schedule falls between working Hours
		if(loggedUserTime >= todayWorkStartTime && estimatedTime <= todayWorkEndTime){
			acceptanceDueDate = estimatedTime;
		}// Scenario 2: If the schedule happened before user's working Hours.
		else if(loggedUserTime < todayWorkStartTime){
			acceptanceDueDate = todayWorkStartTime.addSeconds(secToCalculate);
		}// Scenario 3: If the schedule happened after user's working Hours.
		else if(loggedUserTime > todayWorkEndTime){
			acceptanceDueDate = nextStartDate.addSeconds(secToCalculate);
		}//Scenario 4: If the schedule happened partially in Working Hours.
		else if(loggedUserTime > todayWorkStartTime && loggedUserTime < todayWorkEndTime &&  estimatedTime > todayWorkEndTime ){
			Integer timeInSecSpend = secToCalculate - (Integer.valueOf((todayWorkEndTime.getTime() - loggedUserTime.getTime())/1000));
			acceptanceDueDate = nextStartDate.addSeconds(timeInSecSpend);
		}
		return acceptanceDueDate.addSeconds(0-longOffsetInSeconds) ;


	}

    /**
    * @description :insertEntitlementForSubscription DCP-52634
    * @param setSubscriptionIds 
    * @param sobjectIdBYSobjectDetails 
    * @return List<Applied_Contract__c> 
    **/
    public static List<Applied_Contract__c> insertEntitlementForSubscription(Set<Id> setSubscriptionIds, Map<Id,Sobject> sobjectIdBYSobjectDetails){
        List<Applied_Contract__c> entitlementList = new List<Applied_Contract__c>();
        String sObjectName = !sobjectIdBYSobjectDetails.isEmpty() ? getAPIName(sobjectIdBYSobjectDetails.keySet().iterator().next()) : '';
        Set<Id> toBeDeletedCaseWOIds = new Set<Id>();
        Set<Id> associatedProductIds = new Set<Id>();
        if(!sobjectIdBYSobjectDetails.isEmpty()) {
            for(Sobject sobjectObj : sobjectIdBYSobjectDetails.values()) {
                if (sObjectName == STRING_ASSOCIATED_PRODUCT) {
                    associatedProductIds.add(sobjectObj.Id);
                } else {
                    toBeDeletedCaseWOIds.add(sobjectObj.Id);
                }
            }
        }
        for(Id subIdObj : setSubscriptionIds) {
            for(Sobject sobjectObj : sobjectIdBYSobjectDetails.values()) {
                string strObjectName = getAPIName(sobjectObj.Id);
                if((Id)sobjectObj.get('Subscription__c') == subIdObj) {
                    Applied_Contract__c ap = initContract(sobjectObj , strObjectName , sObjectName);
                     entitlementList.add(ap);
                }
            }
        }
        deletePreviousEntitlements(toBeDeletedCaseWOIds , toBeDeletedCaseWOIds , associatedProductIds);
        return entitlementList;
    }
    private static Applied_Contract__c initContract(Sobject sobjectObj, String strObjectName , String sObjectName) {
        Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.Service_Contract__c = (Id)sobjectObj.get('Subscription__c');
        if (sObjectName != STRING_ASSOCIATED_PRODUCT) {
            objEntitlement.Case_Number__c = strObjectName == STRING_CASE_API_NAME ? sobjectObj.Id : null; 
            objEntitlement.Work_Order__c = strObjectName == STRING_WORKORDER_API_NAME ? sobjectObj.Id : null;
        } else {
            objEntitlement.Associated_Product__c = (Id)sobjectObj.get('id');
            objEntitlement.Case_Number__c = (Id)sobjectObj.get('Case__c') != null ? (Id)sobjectObj.get('Case__c') : null;
            objEntitlement.Work_Order__c = (Id)sobjectObj.get('Work_Order__c') != null ? (Id)sobjectObj.get('Work_Order__c') : null;  
        }
        objEntitlement.Record_Creation_Source__c = 'Backend Code';
        return objEntitlement;
     }
}

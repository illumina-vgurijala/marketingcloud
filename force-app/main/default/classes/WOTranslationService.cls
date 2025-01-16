/**
* @author Romi Taskar
* @date 20 September 2022
*
* @description DCP-52923 Helper Class for Work Order Handler for populating Shipping Location Address while creating Parts Order
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Developer                      Date                Description
* Romi Taskar               20 September 2022        [DCP-56432] WO Translation Tool: WO Completion
* --------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/ 
global with sharing Class WOTranslationService { 

    public static final String DELIMITER = '@&%#';
    private static final String MESSAGETYPE_ERROR = 'SVMX_ERROR';
    private static final String MESSAGETYPE_SUCCESS = 'SVMX_SUCCESS';
    private static final Integer INTEGRATION_LENGTH_LIMIT = 19000;
    private final static String STRING_LANGUAGE_ISO_JAPAN = 'ja';
    private final static String STRING_LANGUAGE_ISO_CHINA = 'zh_CN';
    private final static String STRING_NULL = 'null';
    private static final String LOG_TITLE = 'WOTranslationService';
    private static final String PS_FIELD_COMPLIANCE_REVIEW = 'Field_Compliance_Review';
    public static String concatKey; // added by dhairya shah for CMCM - 2180
    
   /*******************************************************************************************************
    * @description : [DCP-56432] WO Translation Tool: WO Completion
    * @param : SVMXC.SFM_WrapperDef.SFM_TargetRecord
    * @return : SVMXC.SFM_WrapperDef.SFM_PageData
    */
    webservice static SVMXC.SFM_WrapperDef.SFM_PageData handleTranslationAction(SVMXC.SFM_WrapperDef.SFM_TargetRecord request) { 

        ilib_LogEvent.push(LOG_TITLE + '.handleTranslationAction()');
        ilib_LogEvent.message('request: ' + request);
        SVMXC.SFM_WrapperDef.SFM_PageData pagedata = new SVMXC.SFM_WrapperDef.SFM_PageData(); 
        Map<String,Schema.SObjectType> allobj = new Map<String, Schema.SObjectType>(); 
        Map<String, Schema.SObjectType> gd = new Map<String, Schema.SObjectType>(); 
        gd = Schema.getGlobalDescribe(); 

        if(!gd.isEmpty()) { 
            for(Schema.SObjectType s : gd.values()) { 
               Schema.DescribeSObjectResult result = s.getDescribe(); 
               allobj.put(result.getName(), s); 
            } 
        } 
        SVMXC.SFM_ServicesDef def = new SVMXC.SFM_ServicesDef();
        Sobject headerSobj = def.SFM_Page_GetHeaderRecord(request, allobj);
        SVMXC__Service_Order__c objWO = new SVMXC__Service_Order__c(); 
        objWO = (SVMXC__Service_Order__c) headerSobj; 
        
        if(objWO.Account_Country__c != Label.CountryJapan && objWO.Account_Country__c != Label.TerritoryRegionChina) {
            pagedata.response.message = Label.WOTranslationToolAvailability; 
            pagedata.response.success = false; 
            pagedata.response.messageType = MESSAGETYPE_ERROR; 
            return pagedata; 
        }

        //if else condition added by Dhairya Shah for CMCM - 2180
            concatKey =  objWO.SVMX_PS_Subject__c + DELIMITER + objWO.Additional_Detail__c;

        if (concatKey.length() >= INTEGRATION_LENGTH_LIMIT) {
            pagedata.response.message = Label.WOTranslationfieldlimit; 
            pagedata.response.success = false; 
            pagedata.response.messageType = MESSAGETYPE_ERROR; 
            return pagedata; 
        }          

        checkEnglishTranslationDesc(objWO);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        
        return getResponseCallout(objWO, def, request, allobj, concatKey);
        
    }

    /*******************************************************************************************************
    * @description : Calling Integration class
    * @return : SVMXC.SFM_WrapperDef.SFM_PageData
    */

    private static SVMXC.SFM_WrapperDef.SFM_PageData getResponseCallout(SVMXC__Service_Order__c objWO, SVMXC.SFM_ServicesDef def, 
                                SVMXC.SFM_WrapperDef.SFM_TargetRecord request, Map<String,Schema.SObjectType> allobj, String concatKey) {
        SVMXC.SFM_WrapperDef.SFM_PageData pagedata = new SVMXC.SFM_WrapperDef.SFM_PageData(); 
        String languageISO = '';

        if(Label.CountryJapan.equalsIgnoreCase(objWO.Account_Country__c)) {
            languageISO = STRING_LANGUAGE_ISO_JAPAN;
        } else if (Label.TerritoryRegionChina.equalsIgnoreCase(objWO.Account_Country__c)) {
            languageISO = STRING_LANGUAGE_ISO_CHINA;
        }

        WOTranslationDataSender sender = new WOTranslationDataSender(languageISO, objWO.id, concatKey);
        WOTranslationDataSender.WOResponseWrapper responseWrapper = sender.fetchWOTranslations();
        //if condition added by Dhairya Shah for CMCM-2180
        if(responseWrapper.isSuccess) {
            objWO.English_Translation_Subject__c = responseWrapper.woObj.English_Translation_Subject__c == STRING_NULL ? null : responseWrapper.woObj.English_Translation_Subject__c;
            objWO.English_Translation_Additional_Detail__c = responseWrapper.woObj.English_Translation_Additional_Detail__c == STRING_NULL ? null : responseWrapper.woObj.English_Translation_Additional_Detail__c;

            Map<String,List<Sobject>> detailSobjectMap = new Map<String, List<Sobject>>(); 
            detailSobjectMap = def.SFM_Page_GetDetailRecords(request, allobj); 
            pagedata = def.SFM_Page_BuildResponse(request, objWO, detailSobjectMap); 
            pagedata.response.message = responseWrapper.message; 
            pagedata.response.success = responseWrapper.isSuccess; 
            pagedata.response.messageType = MESSAGETYPE_SUCCESS; 
            return pagedata;
        } else {
            pagedata.response.message = responseWrapper.message; 
            pagedata.response.success = responseWrapper.isSuccess; 
            pagedata.response.messageType = MESSAGETYPE_ERROR; 
            return pagedata; 
        }
    }

   /**
    * @description : Check the Existing_English_Translations_data__c to true
    * @param objWO
    **/
    public static void checkEnglishTranslationDesc(SVMXC__Service_Order__c objWO){
        // 2180 new changes add in if else by Dhairya Shah new AC changes
        if((String.isNotEmpty(objWO.English_Translation_Subject__c) || String.isNotEmpty(objWO.English_Translation_Additional_Detail__c))){
            objWO.Existing_English_Translations_data__c = true;
        }
    }

    /*******************************************************************************************************
    * @description : [DCP-56432] This is getting called from before Page Event of 'Convert WO to Completed' SFM
    * @param : SVMXC.SFM_WrapperDef.SFM_TargetRecord
    * @return : SVMXC.SFM_WrapperDef.SFM_PageData
    */
    webservice static SVMXC.SFM_WrapperDef.SFM_PageData throwErrorForBlankTranslation(SVMXC.SFM_WrapperDef.SFM_TargetRecord request) { 

        ilib_LogEvent.push(LOG_TITLE + '.throwErrorForBlankTranslation()');
        ilib_LogEvent.message('request: ' + request);

        SVMXC.SFM_WrapperDef.SFM_PageData pagedata = new SVMXC.SFM_WrapperDef.SFM_PageData(); 
        Map<String,Schema.SObjectType> allobj = new Map<String, Schema.SObjectType>(); 
        Map<String, Schema.SObjectType> gd = new Map<String, Schema.SObjectType>(); 
        gd = Schema.getGlobalDescribe(); 

        if(!gd.isEmpty()) { 
            for(Schema.SObjectType s : gd.values()) { 
               Schema.DescribeSObjectResult result = s.getDescribe(); 
               allobj.put(result.getName(), s); 
            } 
        } 
        SVMXC.SFM_ServicesDef def = new SVMXC.SFM_ServicesDef();
        Sobject headerSobj = def.SFM_Page_GetHeaderRecord(request, allobj);
        SVMXC__Service_Order__c objWO = new SVMXC__Service_Order__c(); 
        objWO = (SVMXC__Service_Order__c) headerSobj;


        PermissionSetAssignmentQuery psQuery = new PermissionSetAssignmentQuery();
        Boolean isPSAssigned = psQuery.queryPSFieldComplianceReview();
        
        //2180-NEWCHANGES
        if(objWO.Account_Country__c == Label.TerritoryRegionChina 
        && objWO.Logged_In_User_Profile__c != Label.ProfileFieldCompliance
        && objWO.Logged_In_User_Profile__c != Label.ProfileCustomerService && !isPSAssigned
        && (String.isEmpty(objWO.English_Translation_Subject__c) || String.isEmpty(objWO.English_Translation_Additional_Detail__c))){
            
            if(isBiCase(objWO) || String.isEmpty(objWO.English_Translation_Subject__c)){
            pagedata.response.message =  Label.WOTranslationfieldstoBefilled;
            pagedata.response.success = false; 
            pagedata.response.messageType = MESSAGETYPE_ERROR; 
            return pagedata; 
            }
        }
       return pagedata; 

    }



  /*******************************************************************************************************
    * @description :  checks if case associated with WO is BI case or Not
    return true if its BI case and return false if there is no case or case with diffrent record type than BI 
    */ 
    static Boolean  isBiCase(SVMXC__Service_Order__c  objWO){
        Id caseRecordTypeBI = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();

        if(objWO.SVMXC__Case__c==null)
        return false;
        
        Case caseObj=[select id,RecordTypeId from case where id=:objWO.SVMXC__Case__c limit 1]; 
        return caseObj.RecordTypeId==caseRecordTypeBI;
    }

    /*******************************************************************************************************
    * @description : Inner Query to query Permission Set Assignment in system context
    */    
    public without sharing class PermissionSetAssignmentQuery {
        /*******************************************************************************************************
        * @description : Query Permission Sets
        */  
        public Boolean queryPSFieldComplianceReview() {
            Id loggedInUser = UserInfo.getUserId();
            List<PermissionSetAssignment> lstPermissionSets = [SELECT id FROM PermissionSetAssignment WHERE AssigneeId =: loggedInUser AND PermissionSet.Name = : PS_FIELD_COMPLIANCE_REVIEW];
            return lstPermissionSets != NULL && !lstPermissionSets.isEmpty();
        }
    }
}
/**
 *    @author Prashanth
 *    @date   4-Dec-2020
 *    @description: Controller Class for LWC knowledgeCreationMasterComponent, knowledgeRecordSelection, knowledgeCreationChild
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Prashanth                   04-Dec-2020           Original version
 *    Adyasha Satapathy           04-Dec-2020           Consolidated methods
 *    Adyasha Satapathy           22-Feb-2021           DCP-45279, Icon Name Update
 *    Abhinav Gupta               18-May-2022           DCP-49920, Knowledge Creation prepopulation from Case
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class KnowledgeCreationMasterController {
    public static final String STRING_DCP_KNOWLEDGESOURCE = 'DCP'; //DCP-45279 --> Added as part of Hypercare 
    private static final String LOG_TITLE = 'KnowledgeCreationMasterController'; //DCP-49920
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs'; //DCP-49920
    /**
    *  @author Prashanth
    *  @description Entry method for fetch page layout [Re-used MDG controller as funtionality remains same]
    *  @param record type id
    *  @return String
    **/
    @AuraEnabled 
    public static String loadPage(String recordTypeID)
    {
        try
        {
            String strRecorrdTypeId = recordTypeID;
            String strPageLayoutName = 'Knowledge__kav-'+MasterDataRequestController.getPageLayoutAssignment(strRecorrdTypeId);
            return JSON.serialize(MasterDataRequestController.getPageLayoutMetadata(strPageLayoutName));
        }
        catch(Exception e){
            errorHandling(e);
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    /**
    *  @author Prashanth
    *  @description Method to fetch Knowledge Record Type details
    *  @param object Api  name
    *  @return List
    **/
    @AuraEnabled(cacheable=true)
    public static List<RecordTypeData> getRecordTypeData(String objectApiName)
    {
        List<RecordTypeData> lstRecordTypeData=new List<RecordTypeData>();
        Set<String> setRecordTypeNames=new Set<String>();
        try{
            if(!String.isBlank(objectApiName)){
                Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(objectApiName).getDescribe(); 
                Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
                for(Schema.RecordTypeInfo obj:rtMapByName.values()){
                    if(obj.isAvailable() && obj.isActive() && !obj.isMaster()){
                        setRecordTypeNames.add(obj.getDeveloperName());
                    }
                }

                for(RecordType objRecType:[SELECT Id,  Name, DeveloperName, Description FROM RecordType 
                                            WHERE DeveloperName in:setRecordTypeNames  and SobjectType = 'Knowledge__kav']){
                        String strLabel=objRecType.Name;
                        String strId=objRecType.Id;
                        String strDescription= objRecType.Description; 
                                    
                        RecordTypeData  objRecordType=New RecordTypeData(strDescription,strLabel,strId,objRecType.DeveloperName);
                        lstRecordTypeData.add(objRecordType);
                    }
            }
            system.debug(lstRecordTypeData);
            return lstRecordTypeData;
        }
        catch(Exception e)
        {
            errorHandling(e);
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    /**
    *  @author Prashanth
    *  @description wrapper class
    **/
    public class RecordTypeData
    {
        @AuraEnabled
        public String strRecordTypeDescription;
        @AuraEnabled
        public String strRecordTypeLabel;
        @AuraEnabled
        public String strRecordTypeId;
        @AuraEnabled
        public String strImageName;

        /**
        *  @author Prashanth
        *  @description Get Record Type details
        *  @param record type description, record type label, record type id, developer name
        **/
        public RecordTypeData(String strRecordTypeDescription,String strRecordTypeLabel,String strRecordTypeId,String strDeveloperName)
        {
            this.strRecordTypeDescription=strRecordTypeDescription;
            this.strRecordTypeLabel=strRecordTypeLabel;
            this.strRecordTypeId=strRecordTypeId;
            this.strImageName='Icon_'+STRING_DCP_KNOWLEDGESOURCE+'_'+strDeveloperName+'.svg';
        }
    }
    /**
    *  @author KD
    *  @description Get Record Type ID
    *  @param Record Id
    **/
    @AuraEnabled
    public static string fetchRecordTypeID(String strKnowledgeId){
        try {
            Id idKnowledgeId = Id.valueOf(strKnowledgeId);
            return new KnowledgeArticlesSelector().selectById(new Set<Id>{idKnowledgeId})[0].RecordTypeId;
        } catch (Exception e) {
            errorHandling(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    *  @author KD
    *  @description Error Handling 
    *  @param Exception
    **/
    public static void errorHandling(Exception e){
        System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
        System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
        System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
        System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
        System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
    }

    /**
    *  @author Abhinav
    *  @description Get Case details for DCP-49920
    *  @param Case Id
    *  Created Date - 18 May 2022
    **/
    @AuraEnabled
    public static List<Case> getCaseValues(Id caseId){
        ilib_LogEvent.push(LOG_TITLE + 'getCaseValues');
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.getCaseValues');
        }
        List<Case> casesDetails = new List<Case>();
        try{
            Set<Id> caseIds = new Set<Id>();
            caseIds.add(caseId);
            CasesSelector cs = new CasesSelector();
            casesDetails = cs.selectCasesByCaseIdSetForQualtrics(caseIds);
        }
        catch (Exception e) {
            errorHandling(e);
            throw new AuraHandledException(e.getMessage());
        }
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(casesDetails.size());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return casesDetails;
    }

}
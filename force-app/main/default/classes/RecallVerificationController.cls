/**************************************************************************************************************************************
* NAME   : RecallVerificationController
* DESCRIPTION  : Domain class for RecallVerification LWC.
* Test Class : TestRecallVerificationController.cls
*  
*                    
* @AUTHOR : Abhishek Yadav
* @DATE   : 17-Jul-2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav         17-Jul-2024         Initial Version. Added logic for CMCM-7516.
****************************************************************************************************************************************/
public with sharing class RecallVerificationController {
    private static final String LOG_TITLE = 'RecallVerificationController';
    private static final String ERROR_MESSAGE = 'getCaseRecord error message';
    private static final String GET_LINE = 'getCaseRecord get line';
    private static final String GET_CAUSE = 'getCaseRecord get cause';
    private static final String OBJ_CASE = 'Case';
    private static Map<String,String> caseIdNFileNameMap = new Map<String,String>();
    private static Map<Id,String> caseIdNContentDocumentLinkMap = new Map<Id,String>();

    /**Method to get Case list */
    @AuraEnabled
    public static List<CaseWrapper> getCaseRecord(Id caseId) {
        ilib_LogEvent.push(LOG_TITLE + '.getCaseRecord()');
        ilib_LogEvent.message('caseId--' + caseId);
        try {
            Map<Id,Case> caseMap = new Map<Id,Case>();
            List<Field_Action_Item__c> facList = new List<Field_Action_Item__c>();
            Map<Id,String> caseIdNFANMap = new Map<Id,String>();
            Set<Id> setCaseIds = new Set<Id>();
            setCaseIds.add(caseId);
            String strCondition = 'Id IN : setCaseIds AND RecordType.Name = \'Service Request\' AND Recall__c = true AND Status != \'Closed\'';
            caseMap = new Map<Id,Case>(new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,null,buildQuery(),null,strCondition,null,null));
            facList = new FieldActionItemsSelector().selectFieldActionItemsByCaseId(new Set<Id>{caseId});
            if(facList != null && !facList.isEmpty()) {
                caseIdNFANMap.put(facList.get(0).Case__c , facList.get(0).Name);
            }
            ilib_LogEvent.message('caseMap--' + caseMap);
            ilib_LogEvent.message('facList--' + facList);
            ilib_LogEvent.pop();
            return getCaseWrapperList(caseMap, caseIdNFANMap);
        } Catch(Exception e) {
            ilib_LogEvent.message(ERROR_MESSAGE+'--' + e.getMessage());
            ilib_LogEvent.message(GET_LINE+'--' + e.getLineNumber());
            ilib_LogEvent.message(GET_CAUSE+'--' + e.getCause());
            ilib_LogEvent.pop();
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**Method to get wrapper list for UI Table */
    public static List<CaseWrapper> getCaseWrapperList(Map<Id,Case> caseMap , Map<Id,String> caseIdNFANMap) {
        ilib_LogEvent.push(LOG_TITLE + '.getCaseWrapperList()');
        List<CaseWrapper> lstCaseWrapper = new List<CaseWrapper>();
            for(Id caseId : caseMap.keySet()) {
                Case caseRecord = caseMap.get(caseId);
                CaseWrapper caseobj = new CaseWrapper
                    (caseId,
                    caseMap.get(caseId).CaseNumber,
                    '',
                    '',
                    getMapValue(caseIdNFANMap, caseId),
                    getFieldValue(caseRecord.Case_Owner_Name__c),
                    null,
                    getFieldValue(caseRecord.Status),
                    getFieldValue(caseRecord.Account != null ? caseRecord.Account.Name : null),
                    getFieldValue(caseRecord.Contact_Name__c),
                    getFieldValue(caseRecord.Subject),
                    getFieldValue(caseRecord.Recall_Acknowledgement_Status__c));
                    lstCaseWrapper.add(caseobj);
            }
        ilib_LogEvent.message('lstCaseWrapper--' + lstCaseWrapper);
        ilib_LogEvent.pop(); 
        return lstCaseWrapper;
    }
    private static String getMapValue(Map<Id, String> mapData, Id key) {
        return mapData != null && mapData.containsKey(key) ? mapData.get(key) : '';
    }
    private static String getMapData(Map<String, String> mapData, String key) {
        return mapData != null && mapData.containsKey(key) ? mapData.get(key) : '';
    }
    private static String getFieldValue(String field) {
        return field != null ? field : '';
    }
    /**
    *  CMCM-7516
    *  @author : Abhishek Yadav
    *  @description - Link the File with Cases
    **/
    @AuraEnabled
    public static void linkFileWithCases(String contentDocumentId , List<String> litsOfCase) {
        ilib_LogEvent.push(LOG_TITLE + '.linkFileWithCases()');
        ilib_LogEvent.message('contentDocumentId--' + contentDocumentId);
        ilib_LogEvent.message('litsOfCase--' + litsOfCase);
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        try {
            for(String caseId : litsOfCase) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocumentId;
                cdl.LinkedEntityId = caseId;
                cdl.ShareType = 'V';
                cdlList.add(cdl);
            }
            if(cdlList != null && !cdlList.isEmpty()) {
                Database.insert(cdlList, false);
            }
            ilib_LogEvent.pop(); 
        } Catch(Exception e) {
            ilib_LogEvent.message(ERROR_MESSAGE+'--' + e.getMessage());
            ilib_LogEvent.message(GET_LINE+'--' + e.getLineNumber());
            ilib_LogEvent.message(GET_CAUSE+'--' + e.getCause());
            ilib_LogEvent.pop(); 
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    *  CMCM-7516
    *  @author : Abhishek Yadav
    *  @description - fetch the File with Cases
    **/
    @AuraEnabled
    public static List<CaseWrapper> fetchFileWithCase(String caseId) {
        ilib_LogEvent.push(LOG_TITLE + '.fetchFileWithCase()');
        ilib_LogEvent.message('caseId--' + caseId);
        try {
            List<ContentDocumentLink> listOfCDL = new List<ContentDocumentLink>();
            set<Id> lstContentDocumentIds = new set<Id>();
            List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>();
            Set<Id> setCaseIds = new Set<Id>();
            Map<Id,Case> caseMap = new Map<Id,Case>();
            listOfCDL = new ContentDocumentLinksSelector().selectByQuoteId(new Set<Id>{caseId});
            for(ContentDocumentLink objcdl : listOfCDL) {
                lstContentDocumentIds.add(objcdl.ContentDocument.id);
            }
            if(lstContentDocumentIds != null && !lstContentDocumentIds.isEmpty()) {
                lstCDL = new ContentDocumentLinksSelector().selectContentDocLinkByConDocId(lstContentDocumentIds);
            }
            for(ContentDocumentLink cdl : lstCDL) {
                String sObjectName = cdl.LinkedEntityId.getSObjectType().getDescribe().getName();
                if(sObjectName == OBJ_CASE) {
                    setCaseIds.add(cdl.LinkedEntityId);
                }
                caseIdNFileNameMap.put(cdl.Id+''+cdl.LinkedEntityId , cdl.ContentDocument.Title);
                caseIdNContentDocumentLinkMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
            if(setCaseIds != null && !setCaseIds.isEmpty()) {
                String strCondition = 'Id IN : setCaseIds AND RecordType.Name = \'Service Request\' AND Recall__c = true';
                caseMap = new Map<Id,Case>(new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,null,buildQuery(),null,strCondition,null,null));
            }
            ilib_LogEvent.message('listOfCDL--' + listOfCDL);
            ilib_LogEvent.message('lstCDL--' + lstCDL);
            ilib_LogEvent.message('caseMap--' + caseMap);
            ilib_LogEvent.message('caseIdNFileNameMap--' + caseIdNFileNameMap);
            ilib_LogEvent.pop();
            return getCaseWrapperViewList(caseMap, lstCDL);
        } Catch(Exception e) {
            ilib_LogEvent.message(ERROR_MESSAGE+'--' + e.getMessage());
            ilib_LogEvent.message(GET_LINE+'--' + e.getLineNumber());
            ilib_LogEvent.message(GET_CAUSE+'--' + e.getCause());
            ilib_LogEvent.pop();
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**Method to get wrapper list for UI Table */
    public static List<CaseWrapper> getCaseWrapperViewList(Map<Id,Case> caseMap , List<ContentDocumentLink> lstCDL) {
        ilib_LogEvent.push(LOG_TITLE + '.getCaseWrapperViewList()');
        List<CaseWrapper> lstCaseWrapper = new List<CaseWrapper>();
        if(lstCDL != null && !lstCDL.isEmpty()) {
            for(ContentDocumentLink objcdl : lstCDL) {
                String sObjectName = objcdl.LinkedEntityId.getSObjectType().getDescribe().getName();
                if(sObjectName == OBJ_CASE && caseMap.containskey(objcdl.LinkedEntityId)) {
                    Case caseRecord = caseMap.get(objcdl.LinkedEntityId);
                    System.debug('caseRecord '+caseRecord);
                    CaseWrapper caseobj = new CaseWrapper
                    (objcdl.LinkedEntityId,
                    caseMap.get(objcdl.LinkedEntityId).CaseNumber,
                    getMapData(caseIdNFileNameMap, objcdl.Id+''+objcdl.LinkedEntityId),
                    getMapValue(caseIdNContentDocumentLinkMap , objcdl.LinkedEntityId),
                    '',
                    getFieldValue(caseRecord.Case_Owner_Name__c),
                    objcdl.SystemModstamp.format(),
                    getFieldValue(caseRecord.Status),
                    getFieldValue(caseRecord.Account != null ? caseRecord.Account.Name : null),
                    getFieldValue(caseRecord.Contact_Name__c),
                    getFieldValue(caseRecord.Subject),
                    getFieldValue(caseRecord.Recall_Acknowledgement_Status__c));
                    lstCaseWrapper.add(caseobj);
                }
            }
        }
    ilib_LogEvent.message('lstCaseWrapper--' + lstCaseWrapper);
    ilib_LogEvent.pop(); 
    return lstCaseWrapper;
    }
    /**
    *  CMCM-7516
    *  @author : Abhishek Yadav
    *  @description - fetch the Case with Account Id
    **/
    @AuraEnabled
    public static List<CaseWrapper> fetchCaseWithAccountId(String accountId) {
        ilib_LogEvent.push(LOG_TITLE + '.fetchCaseWithAccountId()');
        ilib_LogEvent.message('accountId--' + accountId);
        try {
            Map<Id,Case> caseMap = new Map<Id,Case>();
            List<Field_Action_Item__c> facList = new List<Field_Action_Item__c>();
            Map<Id,List<Field_Action_Item__c>> caseIdNFANMap = new Map<Id,List<Field_Action_Item__c>>();
            Map<Id,String> caseIdNFANNameMap = new Map<Id,String>();
            Set<Id> setCaseIds = new Set<Id>();
            setCaseIds.add(accountId);
            String strCondition = 'AccountId = :setCaseIds AND RecordType.Name = \'Service Request\' AND Recall__c = true AND Status != \'Closed\'';
            caseMap = new Map<Id,Case>(new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,null,buildQuery(),null,strCondition,null,null));
            facList = new FieldActionItemsSelector().selectFieldActionItemsByCaseId(caseMap.keySet());
            if(facList != null && !facList.isEmpty()) {
                for(Field_Action_Item__c fci : facList) {
                    List<Field_Action_Item__c> tempFAIList;
                    if(caseIdNFANMap.containsKey(fci.Case__c)) {
                        tempFAIList = caseIdNFANMap.get(fci.Case__c);
                    } else {
                        tempFAIList = new List<Field_Action_Item__c>();
                    }
                    tempFAIList.add(fci);
                    caseIdNFANMap.put(fci.Case__c , tempFAIList);
                }
                if(caseIdNFANMap != null && !caseIdNFANMap.isEmpty()) {
                    for(Id csId : caseIdNFANMap.keySet()) {
                        List<Field_Action_Item__c> tempFAI = caseIdNFANMap.get(csId);
                        caseIdNFANNameMap.put(csId , tempFAI.get(0).Name);
                    }
                }
            }
            ilib_LogEvent.pop(); 
            return getCaseWrapperList(caseMap, caseIdNFANNameMap);
        } Catch(Exception e) {
            ilib_LogEvent.message(ERROR_MESSAGE+'--' + e.getMessage());
            ilib_LogEvent.message(GET_LINE+'--' + e.getLineNumber());
            ilib_LogEvent.message(GET_CAUSE+'--' + e.getCause());
            ilib_LogEvent.pop(); 
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**Wrapper class */
    public class CaseWrapper {
        @AuraEnabled
        public  String caseId;
        @AuraEnabled
        public  String caseNumber;
        @AuraEnabled
        public  String fileName;
        @AuraEnabled
        public  String contentDocumentLink;
        @AuraEnabled
        public  String fanNumber;
        @AuraEnabled
        public  String ownerName;
        @AuraEnabled
        public String dateTimeStamp;
        @AuraEnabled
        public String caseStatus;
        @AuraEnabled
        public String accountName;
        @AuraEnabled
        public String contactName;
        @AuraEnabled
        public String caseSubject;
        @AuraEnabled
        public String recallAcknowledgementStatus;
        
        /**Constructor */
        public CaseWrapper(String caseId, String caseNumber, String fileName, String contentDocumentLink, String fanNumber, String ownerName, String dateTimeStamp, String caseStatus, String accountName, String contactName, String caseSubject, String recallAcknowledgementStatus) {
            this.caseId = caseId;
            this.caseNumber = caseNumber;
            this.fileName = fileName;
            this.contentDocumentLink = contentDocumentLink;
            this.fanNumber = fanNumber;
            this.ownerName = ownerName;
            this.dateTimeStamp = dateTimeStamp;
            this.caseStatus = caseStatus;
            this.accountName = accountName;
            this.contactName = contactName;
            this.caseSubject = caseSubject;
            this.recallAcknowledgementStatus = recallAcknowledgementStatus;
        }
    }
    private static Set<String> buildQuery() {
        Set<String> setFieldToQuery = new Set<String>();
        setFieldToQuery.add('Id');
        setFieldToQuery.add('CaseNumber');
        setFieldToQuery.add('Case_Owner_Name__c');
        setFieldToQuery.add('Status');
        setFieldToQuery.add('Account.Name');
        setFieldToQuery.add('Contact_Name__c');
        setFieldToQuery.add('Subject');
        setFieldToQuery.add('Recall_Acknowledgement_Status__c');
        return setFieldToQuery;
    }
}
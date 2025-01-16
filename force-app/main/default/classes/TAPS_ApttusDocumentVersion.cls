/**
 *    @author Illumina
 *    @description    TAPS_ApttusDocumentVersion object type class 
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date                    Description    
 *    Ashwin Kumar                  12-Apr-2022             INC0387946 - Moved SOQL query to fix Too many SOQL queries issue 
 *    Jitesh Lakhwani               6-July-2022             Code Scan fixes of Comments
 *    Rajbabu Boopalan              22-Dec-2023             CMCM-4122 - fix SOQL 201 error
 *   ---------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class TAPS_ApttusDocumentVersion extends TAPS_ComposedBase implements TAPS_IObjectsCustom {
    private static final String LOG_TITLE = 'TAPS_ApttusDocumentVersion';

    /**
    *@description : this will return the Document Version sObjectType. 
    *@return SObjectType 
    */
    public override SObjectType getObjectType()
    {
        return Apttus__DocumentVersion__c.sObjectType;
    }

    /**
    *@description : This method creates an map of 1 document related to the set of accounts
    *@param  : Set<Id> recordIds - document version record id's
    *@return : Map<Id, Set<Id>> - map of document id and accounts (example: document_1_id -> <acc_1_Id,acc_2_Id.....>, document_2_id -> <acc_1_Id,acc_2_Id.....>)
    */
    public override Map<Id, Set<Id>> mapRecordToAccountsCustom(Set<Id> recordIds)
    {
        // get agreements these docs are linked to
        List<Apttus__DocumentVersion__c> docs = [SELECT Id, Apttus__AgreementId__c
            FROM Apttus__DocumentVersion__c
            WHERE Id IN :recordIds];

        Map<Id, Id> agreementIdToDocId = new Map<Id, Id>();
        for (Apttus__DocumentVersion__c dv : docs)
        {
            agreementIdToDocId.put(dv.Apttus__AgreementId__c, dv.Id);
        }

        // get accounts linked to those agreements
        List<Agreement_Account_Relationship__c> rels = [SELECT Agreement__c, Account__c
            FROM Agreement_Account_Relationship__c
            WHERE Agreement__c IN :agreementIdToDocId.keySet()];

        Map<Id, Set<Id>> recordIdToAccountIds = new Map<Id, Set<Id>>();
        for (Agreement_Account_Relationship__c rel : rels)
        {
            Id docId = agreementIdToDocId.get(rel.Agreement__c);
            if (!recordIdToAccountIds.containsKey(docId))
                recordIdToAccountIds.put(docId, new Set<Id>());
            recordIdToAccountIds.get(docId).add(rel.Account__c);
        }

        return recordIdToAccountIds;
    }

    /**
    *@description : This method will return the document id's based on accounts id
    *@param  :Set<Id> accountIds - Account id's
    *@return : Set<Id> - Set of document id
    */
    public override Set<Id> getRecordIdsFromAccountIdsCustom(Set<Id> accountIds)
    {
        // get agreements that the accounts are linked to
        List<Agreement_Account_Relationship__c> rels = [SELECT Agreement__c
            FROM Agreement_Account_Relationship__c
            WHERE Account__c IN :accountIds];
        Set<Id> agreementIds = UtilsCollection.getSetOfIds(rels, 'Agreement__c');

        // get docs linked to those agreements
        List<Apttus__DocumentVersion__c> docVersions = [SELECT Id
            FROM Apttus__DocumentVersion__c
            WHERE Apttus__AgreementId__c IN :agreementIds];

        Set<Id> ids = UtilsCollection.getSetOfIds(docVersions);
        return ids;
    }

    /**
    *@description : This method will return same set id's which were passed as modified records cannot be updated for this object
    *@param  : Set<Id> modifiedRecordIds
    *@return : Set<Id> - Set of document id
    */
    public override Set<Id> getRecordIdsFromModifiedRecordIdsCustom(Set<Id> modifiedRecordIds)
    {
        // modified records can't be updated for this object
        return modifiedRecordIds;
    }

    /**
    *@description : this will return the document version Share sObjectType. 
    *@return SObjectType 
    */
    public override SObjectType getShareObjectType()
    {
        return Apttus__DocumentVersion__Share.sObjectType;
    }

    /**
    *@description : this will return the document version share object parent field name  
    *@param  : None
    *@return : String : document version share parent id field name : ParentId
    */
    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }

    /**
    *@description : this will create the Document share object record and will return it  
    *@param  : Id recordId, Id userId
    *@return : SObject 
    */
    /*public override SObject createSharingRecord(Id recordId, Id userId)
    {
        Set<Id> setDocs = new Set<Id>{recordId};
        List<Apttus__DocumentVersion__c> lstDocs = new DocumentVersionSelector().selectDocVersion(setDocs);
        if(lstDocs[0].Agreement_Record_Type__c == System.label.RecordTypeIlluminaLabServices) {
            return null;
        }else{
            Apttus__DocumentVersion__Share share = new Apttus__DocumentVersion__Share(
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            RowCause = Schema.Apttus__DocumentVersion__Share.RowCause.Manual
            );
            share.put(getShareParentFieldName(), recordId);
            return share;
        }
    }*/

    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : Method to create and return list of Apttus__DocumentVersion__Share records (with edit access) based on
    *  Map<Id, Set<Id>> recordIdToUserIdsMap passed in the parameter for CMCM-4122
    *  @Param       : Map<Id, Set<Id>> recordIdToUserIdsMap 
    *  @Return      : List<SObject>
    */
    public void createSharingRecord(Map<Id, Set<Id>> recordIdToUserIdsMap) {   
        ilib_LogEvent.push(LOG_TITLE + '.createSharingRecord');
        Set<Id> setDocs = new Set<Id>();
        // Create a list of SObjects to store the share records
        List<SObject> shareRecords = new List<SObject>();
        Map<Id, Set<Id>> recordIdToUserIdsFilteredMap = new Map<Id, Set<Id>>();
        Set<Id> userIdSet = new Set<Id>();
        for(Id recordId : recordIdToUserIdsMap.keySet()) {  
            if(recordId == null || recordIdToUserIdsMap.get(recordId) == null || recordIdToUserIdsMap.get(recordId).size() == 0)   continue;
            for(Id userId : recordIdToUserIdsMap.get(recordId)) {
                userIdSet.add(userId);
            }
            recordIdToUserIdsFilteredMap.put(recordId, userIdSet);
        }

        setDocs = recordIdToUserIdsFilteredMap.keySet();
        List<Apttus__DocumentVersion__c> lstDocs = new DocumentVersionSelector().selectDocVersion(setDocs);
        ilib_LogEvent.info('number of SOQL queries used:' + limits.getQueries());
        ilib_LogEvent.info('number of SOQL queries available:' + limits.getLimitQueries());
        ilib_LogEvent.info('List Size:' + lstDocs.size());
        for(Apttus__DocumentVersion__c documentVar : lstDocs) {
            if(documentVar.Agreement_Record_Type__c != System.label.RecordTypeIlluminaLabServices) {
                for(Id userId : recordIdToUserIdsFilteredMap.get(documentVar.Id)) {
				    Apttus__DocumentVersion__Share shareRec = new Apttus__DocumentVersion__Share();
					shareRec.ParentId = documentVar.Id;
					shareRec.UserOrGroupId = userId;
					shareRec.AccessLevel = 'Edit';
					shareRec.RowCause = Schema.Apttus__DocumentVersion__Share.RowCause.Manual;
					shareRecords.add(shareRec);
                }
            }
            else continue;
        }

        if(!shareRecords.isEmpty()) {
            List<Database.SaveResult> allResults = Database.insert(shareRecords, false);
            for(Integer i = 0; i < allResults.size(); i++) {
                Database.SaveResult res = allResults.get(i);
                if(!res.isSuccess()) {
                    documentDmlError(res.getErrors());
                }else {
                    ilib_LogEvent.message('TAPS: share inserted successfully for ' + shareRecords.get(i));
                }
            }
        }
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : Method to log DML errors for CMCM-4122
    *  @Param       : SObject objShare, List<Database.Error> errors
    *  @Return      : void
    */
    @TestVisible
    private static void documentDmlError(List<Database.Error> errors) {
            String allErrorsString = '';
            for(Database.Error e : errors) {
                allErrorsString += e.getMessage() + '\n\n';
            }
            ilib_LogEvent.push('documentDmlError');
            ilib_LogEvent.error('Error Description' + allErrorsString +'----');
            ilib_LogEvent.pop();	
        }

    /**
    * @description filter by role in territory to only include certain sales roles
    * @params Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds
    * @return Map<Id, Set<Id>> 
    **/ 

    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }

    /**
    * @description filter by records related to account id's
    * @params Map<Id, Set<Id>> recordIdToAccountIds
    * @return Set<Id> 
    **/ 

    public override Set<Id> filterRecordsRelatedToAccount(Map<Id, Set<Id>> recordIdToAccountId) 
    {
        Set<Id> setFilteredDocumentVersions = new Set<Id>();                    //INC0387946
        if (!recordIdToAccountId.isEmpty()) {
            for (Apttus__DocumentVersion__c objDocVersion : new DocumentVersionSelector().selectDocVersion(recordIdToAccountId.keySet())) {
                if (!TAPS_ApttusAgreements.AGRR_REC_TYPES_TO_EXCLUDE.contains(objDocVersion.Agreement_Record_Type__c)) {
                    setFilteredDocumentVersions.add(objDocVersion.Id);           //INC0387946
                }
            }
        }
        return setFilteredDocumentVersions;
    }

}
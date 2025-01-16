/*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description: Class which contains methods related to Apttus__APTS_Agreement__c metadata, method to create
    *  Apttus__APTS_Agreement__Share records and to filter Sales Users by role in Territory
    *  Modification Log:
    *    ---------------------------------------------------------------------------------------------------------------------------
    *         Developer                      Date                Description         
    *         Todd Newman                                      Initial Version
    *         Nesar Mohan                 2022-03-30           CodeScan Fix 
    *         Rajbabu Boopalan            2023-12-20           CMCM-4122 
    *         Rajbabu Boopalan            2024-02-08           CMCM-5707 
    *    ---------------------------------------------------------------------------------------------------------------------------
    */

public without sharing class TAPS_ApttusAgreements extends TAPS_ComposedBase implements TAPS_IObjectsJunction {
    public static final Set<String> AGRR_REC_TYPES_TO_EXCLUDE = new Set<String>{System.label.RecordTypePartnershipAgreement, System.label.RecordTypeQualityAgreement};
    private static final String LOG_TITLE = 'TAPS_ApttusAgreements';
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the sObject Type of Apttus__APTS_Agreement__c
    *  @Param       : None
    *  @Return      : SObjectType
    */

    public override SObjectType getObjectType()
    {
        return Apttus__APTS_Agreement__c.sObjectType;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Junction object api name between Apttus__APTS_Agreement__c and Account
    *  @Param       : None
    *  @Return      : String
    */

    public override String getJunctionTableName()
    {
        return 'Agreement_Account_Relationship__c';
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Junction field api name between Apttus__APTS_Agreement__c and Agreement_Account_Relationship__c
    *  @Param       : None
    *  @Return      : String
    */

    public override String getKeyFieldName()
    {
        return 'Agreement__c';
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Junction field api name between Agreement_Account_Relationship__c and Account
    *  @Param       : None
    *  @Return      : String
    */

    public override String getValueFieldName()
    {
        return 'Account__c';
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the sObject Type of Apttus__APTS_Agreement__Share
    *  @Param       : None
    *  @Return      : SObjectType
    */

    public override SObjectType getShareObjectType()
    {
        return Apttus__APTS_Agreement__Share.sObjectType;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the ParentId field of Apttus__APTS_Agreement__Share
    *  @Param       : None
    *  @Return      : String
    */

    public override String getShareParentFieldName()
    {
        return 'ParentId';
    }
    
    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : Method to create and return list of Apttus__APTS_Agreement__Share records (with edit access) based on
    *  Map<Id, Set<Id>> recordIdToUserIdsMap passed in the parameter for CMCM-4122
    *  @Param       : Map<Id, Set<Id>> recordIdToUserIdsMap 
    *  @Return      : List<SObject>
    */
    public void createSharingRecord(Map<Id, Set<Id>> recordIdToUserIdsMap) {   
        ilib_LogEvent.push(LOG_TITLE + '.createSharingRecord');
        Set<Id> setAgreements = new Set<Id>();
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

        setAgreements = recordIdToUserIdsFilteredMap.keySet();
        List<Apttus__APTS_Agreement__c> lstAgreements = new ApttusAgreementSelectors().selectAgreements(setAgreements);
        ilib_LogEvent.info('number of SOQL queries used:' + limits.getQueries());
        ilib_LogEvent.info('number of SOQL queries available:' + limits.getLimitQueries());
        ilib_LogEvent.info('List Size:' + lstAgreements.size());
        for(Apttus__APTS_Agreement__c agreementVar : lstAgreements) {
            if(agreementVar.RecordType.DeveloperName != System.label.RecordTypeIlluminaLabServices) {
                for(Id userId : recordIdToUserIdsFilteredMap.get(agreementVar.Id)) {
				    Apttus__APTS_Agreement__Share shareRec = new Apttus__APTS_Agreement__Share();
					shareRec.ParentId = agreementVar.Id;
					shareRec.UserOrGroupId = userId;
					shareRec.AccessLevel = 'Edit';
					shareRec.RowCause = Schema.Apttus__APTS_Agreement__Share.RowCause.Manual;
					shareRecords.add(shareRec);
                }
            }
            else continue;
        }
        Integer dmlRecordLimit = Limits.getLimitDMLRows() - Limits.getDmlRows();

        if(!shareRecords.isEmpty()) {
            // CMCM-5707 check record count
            if(shareRecords.size() <= dmlRecordLimit){
                List<Database.SaveResult> allResults = Database.insert(shareRecords, false);
                ApexExceptions.emitSaveErrors(allResults, 'TAPS_ApttusAgreements');
            } else{
                // More than 10K records. Call the batch job to create sharing records
                ilib_LogEvent.message('More than 10K records. Call batch TAPS_BatchCreate');
                createShareRecordsInBatch(shareRecords);
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : Method to handle more than 10K share records
    *  @Param       : List<SObject>
    *  @Return      : void
    */
    @TestVisible
    private void createShareRecordsInBatch(List<SObject> shareRecords) {
        // More than 10K records. Call the batch job to create sharing records
        Integer batchSize = 2000;
        BatchDMLService batchDMLService = new BatchDMLService(shareRecords, BatchDMLService.dmlOperation.DML_INSERT, batchSize);
        batchDMLService.runBatchDML();
    }
    
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to filter by role in territory to only include certain sales roles
    *  @Param       : three parameters of type Map<Id, Set<Id>> 
    *  @Return      : Map<Id, Set<Id>>
    */
    public override Map<Id, Set<Id>> filterTerritoryIdToUserIds(Map<Id, Set<Id>> territoryIdToUserIds, Map<Id, Set<Id>> accountIdToTerritoryIds, Map<Id, Set<Id>> recordIdToAccountIds)
    {
        // filter by role in territory to only include certain sales roles
        return filterSalesUsersByRoleInTerritory(territoryIdToUserIds);
    }
/**
 * @actor illumina
 * @description :-
 */
    public override Set<Id> filterRecordsRelatedToAccount(Map<Id, Set<Id>> recordIdToAccountId) 
    {
        Set<Id> setFilteredAgreements = new Set<Id>();              //INC0387946
        if (!recordIdToAccountId.isEmpty()) {
            for (Apttus__APTS_Agreement__c objAgr : new ApttusAgreementSelectors().selectAgreements(recordIdToAccountId.keySet())) {
                if (!AGRR_REC_TYPES_TO_EXCLUDE.contains(objAgr.RecordType.DeveloperName)) {
                    setFilteredAgreements.add(objAgr.Id);           //INC0387946
                }
            }
        }
        return setFilteredAgreements;
    }

}
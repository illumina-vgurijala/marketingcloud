// NOTE: is without sharing because createSharingRecords() and deleteSharingRecords() require it to work properly
/***************************************************************************************************************************************
* NAME   : InstalledProductsService 
* Test class coverage for 75%: TestBatchToUpdateIPiSeq, TestBatchUpdateCaseStatus, TestCheckDCIR_POLHelper, TestCoveredProductsQueueable, TestFANRecordListController,
                                TestInstalledProductsService, TestTAPS_Locations, TestUpdatePendingReview_POLHelper.
* Test class coverage for 90%: TestBatchToUpdateIPiSeq, TestBatchUpdateCaseStatus, TestCheckDCIR_POLHelper, TestCoveredProductsQueueable, TestFANRecordListController,
                                TestInstalledProductsService, TestTAPS_Locations, TestUpdatePendingReview_POLHelper.
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                    DATE                    DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Gerardo Garcia           2023-12-07                  CMCM-4772 Fix "Too many query rows: 50001 "
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class InstalledProductsService {
    private static final String LOG_TITLE = 'InstalledProductsService';
    private static final Integer RUN_BATCH_THRESHOLD = 100;
    public static final String NULLSTR = 'Null';


		/*
         * description - getUCsAffiliatedWithDistributor method
		 * return - Set<Id>
         */ 
    public static Set<Id> getUCsAffiliatedWithDistributor(Set<Id> accountIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.getUCsAffiliatedWithDistributor()');
        Set<Id> ucIds = new Set<Id>();

        // get distributor users associated with the distributor accounts
        List<User> indirectUsers = [SELECT Id, AccountId FROM User WHERE AccountId IN :accountIds AND IsActive = true];
        if (indirectUsers.size() == 0){
            ilib_LogEvent.info('ucIds : '+ucIds);
            ilib_LogEvent.pop();
            return ucIds;
        }

        // get territories associated to the distributor users
        Set<Id> indirectUserIds = UtilsCollection.getSetOfIds(indirectUsers, 'Id');
        ilib_LogEvent.info('indirectUserIds : '+indirectUserIds);
        List<UserTerritory2Association> indirectUserAssociations = new UserTerritory2AssociationSelector().selectByUserIds(indirectUserIds);

        // get accounts (assumed to be UC) associated to territories
        Set<Id> indirectTerritoryIds = UtilsCollection.getSetOfIds(indirectUserAssociations, 'Territory2Id');
        ilib_LogEvent.info('indirectTerritoryIds : '+indirectTerritoryIds);
        List<ObjectTerritory2Association> accountAssociations = new ObjectTerritory2AssociationsSelector().selectByTerritoryId(indirectTerritoryIds);
        ilib_LogEvent.pop();
        return UtilsCollection.getSetOfIds(accountAssociations, 'ObjectId');
    }

		/*
         * description - shareWithDistributorUsers method
		 * return - Boolean
         */
    public static Boolean shareWithDistributorUsers(Set<Id> distributorIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.shareWithDistributorUsers()');
        
        Boolean hasRunPartnerSharing = false;
        
        if (distributorIds == null || distributorIds.size() == 0) {
            ilib_LogEvent.info('hasRunPartnerSharing : '+hasRunPartnerSharing);
            ilib_LogEvent.pop();
            return hasRunPartnerSharing;
        }

        Set<Id> ucIds = getUCsAffiliatedWithDistributor(distributorIds);
        ilib_LogEvent.info('ucIds : '+ucIds);
        System.debug('SHARE: ucIds ' + ucIds);
        ilib_LogEvent.pop();
        return shareWithDistibutorUsersByUC(ucIds);
    }

    /**
     * @description - Share Installed Product Records by given accouts
     * @param Set<id> ucIds. Accounts ids for ultimate consignment
     * @return - Boolean True if there is Installed Products to share.
     */
    public static Boolean shareWithDistibutorUsersByUC(Set<Id> ucIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.shareWithDistibutorUsersByUC()');
        Integer numAffectedProducts = [SELECT COUNT() FROM SVMXC__Installed_Product__c WHERE SVMXC__Company__c IN :ucIds];
        ilib_LogEvent.message('SHARE: numAffectedProducts ' + numAffectedProducts);

        if (numAffectedProducts == 0){
            ilib_LogEvent.info('Returning : False');
            ilib_LogEvent.pop();
            return false;
        }
        // if the number of UCs is large run a batch
        if (numAffectedProducts > RUN_BATCH_THRESHOLD)
        {
            ilib_LogEvent.info('InstalledProductsBatchIndirectSharing is about to start with accountIds: '+ ucIds);
            // when in a test method, this variable will be set until the test is really ready to roll
            // this prevents the batch from being executed during test data setup 
            //if (!TestInstalledProducts.SETTING_UP_TEST_NOW)
                Database.executeBatch(new InstalledProductsBatchIndirectSharing(ucIds));
        }
        else
        {
            List<SVMXC__Installed_Product__c> affectedProducts = [SELECT Id, SVMXC__Company__c, SVMXC__Product__c FROM SVMXC__Installed_Product__c WHERE SVMXC__Company__c IN :ucIds];
            shareWithDistributorUsers(affectedProducts);
        }
        ilib_LogEvent.info('Returning : True');
        ilib_LogEvent.pop();
        return true;
    }

		/*
         * description - shareWithDistributorUsers method
		 * return - void
         */
    public static void shareWithDistributorUsers(List<SVMXC__Installed_Product__c> installedProducts)
    {
        ilib_LogEvent.push(LOG_TITLE + '.shareWithDistributorUsers()');
        Set<Id> setRecordIds = UtilsCollection.getSetOfIds(installedProducts, 'Id');
        Map<Id, Set<Id>> recordIdToUserIds = mapRecordIdToUserIds(installedProducts);
        ilib_LogEvent.info('setRecordIds : '+setRecordIds);
        ilib_LogEvent.info('recordIdToUserIds : '+recordIdToUserIds);
        List<SVMXC__Installed_Product__Share> extantShares = [SELECT Id, ParentId, UserOrGroupId FROM SVMXC__Installed_Product__Share WHERE ParentId IN :setRecordIds AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Distributor__c];

        // map record -> user from existing share records
        Map<Id, Set<Id>> existingRecordIdToUserIds = UtilsCollection.getMapOfIdToIds(extantShares, 'ParentId', 'UserOrGroupId');
        ilib_LogEvent.info('existingRecordIdToUserIds : '+existingRecordIdToUserIds);
        // maps for shares to create/delete
        Map<Id, Set<Id>> recordIdToNewShares = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> recordIdToObsoleteShares = new Map<Id, Set<Id>>();

        // compare (incoming) recordIdToUserIds with existingRecordIdToUserIds
        for (Id recordId : setRecordIds)
        {
            // start with existing records
            Set<Id> usersWhoWillHaveShares = (recordIdToUserIds.containsKey(recordId) ? recordIdToUserIds.get(recordId) : new Set<Id>());
            Set<Id> usersWhoAlreadyHaveShares = (existingRecordIdToUserIds.containsKey(recordId) ? existingRecordIdToUserIds.get(recordId) : new Set<Id>());

            // Remove the existing users from the to-be users
            // what remains will be added
            Set<Id> usersToGiveSharesTo = new Set<Id>(usersWhoWillHaveShares);
            usersToGiveSharesTo.removeAll(usersWhoAlreadyHaveShares);
            recordIdToNewShares.put(recordId, usersToGiveSharesTo);

            // Remove the to-be users from the old set
            // what remains will be deleted
            Set<Id> usersToTakeSharesFrom = new Set<Id>(usersWhoAlreadyHaveShares);
            usersToTakeSharesFrom.removeAll(usersWhoWillHaveShares);
            recordIdToObsoleteShares.put(recordId, usersToTakeSharesFrom);
            ilib_LogEvent.message('SHARE: for rec ' + recordId + ': willhave/alreadyhas/newshares/goneshares counts ' + usersWhoWillHaveShares.size() + '/' + usersWhoAlreadyHaveShares.size() + '/' + recordIdToNewShares.size() + '/' + recordIdToObsoleteShares.size());
        }

        ilib_LogEvent.info('SHARE: removing ' + recordIdToObsoleteShares.size() + ' shares: ' + recordIdToObsoleteShares);
        ilib_LogEvent.info('SHARE: adding ' + recordIdToNewShares.size() + ' shares: ' + recordIdToNewShares);

        removeSharingRecords(recordIdToObsoleteShares);
        createSharingRecords(recordIdToNewShares);
        ilib_LogEvent.pop();
    }

		/*
         * description - mapRecordIdToUserIds method
		 * return - Map<Id, Set<Id>>
         */
    public static Map<Id, Set<Id>> mapRecordIdToUserIds(List<SVMXC__Installed_Product__c> installedProducts)
    {
        ilib_LogEvent.push(LOG_TITLE + '.mapRecordIdToUserIds()');
        Map<Id, Set<Id>> idToUserIds = new Map<Id, Set<Id>>();

        Map<Id, Product2> idToProduct = queryProductDetails(installedProducts);
        ilib_LogEvent.info('idToProduct : ' +  (idToProduct != Null ? String.valueof(idToProduct.keySet()):NULLSTR));
        List<ObjectTerritory2Association> indirectTerritoryAssociations = queryIndirectTerritories(installedProducts);

        // hold set of indirect territory IDs
        Set<Id> indirectLeafTerritoryIds = UtilsCollection.getSetOfIds(indirectTerritoryAssociations, 'Territory2Id');

        // map UC to indirect territory IDs
        Map<Id, Set<Id>> ucIdToIndirectTerritoryIds = UtilsCollection.getMapOfIdToIds(indirectTerritoryAssociations, 'ObjectId', 'Territory2Id');
        ilib_LogEvent.info('SHARE: ucIdToIndirectTerritoryIds: ' + ucIdToIndirectTerritoryIds);

        Map<Id, Set<Id>> indirectTerritoryIdToUserIds = mapIndirectTerritoryIdToUserIds(indirectLeafTerritoryIds);
        ilib_LogEvent.info('SHARE: indirectTerritoryIdToUserIds: ' + indirectTerritoryIdToUserIds);

        // query for distributor users and accounts
        Map<Id, User> idToIndirectUser = new Map<Id, User>(queryDistributorUsers(indirectTerritoryIdToUserIds));
        Map<Id, Account> idToDistributorAccount = new Map<Id, Account>(queryDistributorAccounts(idToIndirectUser.values()));
        ilib_LogEvent.info('SHARE: idToDistributorAccount: ' + idToDistributorAccount);

        Map<Id, Id> indirectT2IdToDistributorId = buildIndirectTerritoryIdToDistributorId(indirectTerritoryIdToUserIds, idToIndirectUser);
        ilib_LogEvent.info('SHARE: indirectT2IdToDistributorId: ' + indirectT2IdToDistributorId);

        for (SVMXC__Installed_Product__c ip : installedProducts)
        {
            ilib_LogEvent.message('SHARE: ip.Id: ' + ip.Id);

            // confirm we have IP and account details to work with
            Id ucId = ip.SVMXC__Company__c;
            if (ucId == null) continue;
            if (!ucIdToIndirectTerritoryIds.containsKey(ucId)) continue;

            // confirm we have indirect territories associated with this UC
            Set<Id> indirectTerritoryIds = ucIdToIndirectTerritoryIds.get(ucId);
            if (indirectTerritoryIds == null || indirectTerritoryIds.size() == 0) continue;

            Set<Id> userIds = new Set<Id>();  // all users who get shares

            for (Id indirectTerritoryId : indirectTerritoryIds)
            {
                Id distributorId = indirectT2IdToDistributorId.get(indirectTerritoryId);
                ilib_LogEvent.fine('SHARE: distributorId: ' + distributorId);
                if (distributorId == null || idToDistributorAccount.get(distributorId) == null) continue;
                Account distributorDetails = idToDistributorAccount.get(distributorId);

                Product2 productDetails = idToproduct.get(ip.SVMXC__Product__c);
                if (productDetails == null) continue;

                Boolean shareThisOneToIndirect = doesProductMatchDistributor(distributorDetails, productDetails);
                ilib_LogEvent.fine('SHARE: shareThisOneToIndirect: ' + shareThisOneToIndirect);
                if (!shareThisOneToIndirect) continue;

                ilib_LogEvent.fine('SHARE: product attributes match account attributes, will add indirect users');
                userIds.addAll(indirectTerritoryIdToUserIds.get(indirectTerritoryId));
            }

            idToUserIds.put(ip.Id, userIds);
        }
        ilib_LogEvent.info('idToUserIds : '+idToUserIds);
        ilib_LogEvent.pop();
        return idToUserIds;
    }

    private static Boolean doesProductMatchDistributor(Account distributorDetails, Product2 productDetails)
    {
        String strAccountProductGroup = distributorDetails.Product_Group__c;
        String strIpProductGroup = productDetails.Product_Group__c;
        String strAccountRegulatoryType = distributorDetails.Regulatory_Type__c;
        String strIpRegulatoryType = productDetails.Regulatory_Type__c;

        // null safety
        strAccountProductGroup = (String.isBlank(strAccountProductGroup) ? 'Do Not Share Acc Product Group' : strAccountProductGroup);
        strIpProductGroup = (String.isBlank(strIpProductGroup) ? 'Do not share Ip Product Group' : strIpProductGroup);
        strAccountRegulatoryType = (String.isBlank(strAccountRegulatoryType)  ? 'Do Not Share Acc RT' : strAccountRegulatoryType);
        strIpRegulatoryType = (String.isBlank(strIpRegulatoryType) ? 'Do Not Share IP RT' : strIpRegulatoryType);
        ilib_LogEvent.fine('SHARE: ' + strAccountRegulatoryType + ' vs ' + strIpRegulatoryType + ' and ' + strAccountProductGroup + ' vs ' + strIpProductGroup);

        // if this IP can't be seen by this account we are done with this IP
        return ((strAccountRegulatoryType == 'All' || strAccountRegulatoryType.contains(strIpRegulatoryType))
                && (strAccountProductGroup == 'All' || strAccountProductGroup.contains(strIpProductGroup)));
    }

    private static Map<Id, Set<Id>> mapIndirectTerritoryIdToUserIds(Set<Id> indirectLeafTerritoryIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.mapIndirectTerritoryIdToUserIds()');
        ilib_LogEvent.pop();
        return TerritoriesService.getAllUserIdsWhoCanAccessLeaf(indirectLeafTerritoryIds);
        
    }

    private static Map<Id, Product2> queryProductDetails(List<SVMXC__Installed_Product__c> installedProducts)
    {
        ilib_LogEvent.push(LOG_TITLE + '.queryProductDetails()');
        Set<Id> productIds = UtilsCollection.getSetOfIds(installedProducts, 'SVMXC__Product__c');
        ilib_LogEvent.info('productIds : '+productIds);
        ilib_LogEvent.pop();
        return new Map<Id, Product2>([SELECT Id, Product_Group__c, Regulatory_Type__c FROM Product2 WHERE Id IN :productIds]);
    }

    private static List<ObjectTerritory2Association> queryIndirectTerritories(List<SVMXC__Installed_Product__c> installedProducts)
    {
        ilib_LogEvent.push(LOG_TITLE + '.queryIndirectTerritories()');
        Set<Id> ucIds = UtilsCollection.getSetOfIds(installedProducts, 'SVMXC__Company__c');
        ilib_LogEvent.info('ucIds : '+ucIds);
        ilib_LogEvent.pop();
        return new ObjectTerritory2AssociationsSelector().selectIndirectByAccountIds(ucIds);
    }

    private static List<User> queryDistributorUsers(Map<Id, Set<Id>> indirectTerritoryIdToUserIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.queryDistributorUsers()');
        Set<Id> indirectUserIds = UtilsCollection.flattenMapValueSets(indirectTerritoryIdToUserIds);
        ilib_LogEvent.info('indirectUserIds : '+indirectUserIds);
        ilib_LogEvent.pop();
        return [SELECT Id, AccountId FROM User WHERE Id IN :indirectUserIds AND AccountId != null];
    }

    private static List<Account> queryDistributorAccounts(List<User> indirectUsers)
    {
        ilib_LogEvent.push(LOG_TITLE + '.queryDistributorAccounts()');
        Set<Id> distributorAccountIds = UtilsCollection.getSetOfIds(indirectUsers, 'AccountId');
        ilib_LogEvent.info('distributorAccountIds : '+distributorAccountIds);
        ilib_LogEvent.pop();
        return [SELECT Id, Regulatory_Type__c, Product_Group__c FROM Account WHERE Id IN :distributorAccountIds];
    }

    private static Map<Id, Id> buildIndirectTerritoryIdToDistributorId(Map<Id, Set<Id>> indirectTerritoryIdToUserIds, Map<Id, User> idToIndirectUser)
    {
        ilib_LogEvent.push(LOG_TITLE + '.buildIndirectTerritoryIdToDistributorId()');
        // NOTE: assuming there will only be one distributor in a territory
        Map<Id, Id> indirectT2IdToDistributorId = new Map<Id, Id>();
        for (Id t2Id : indirectTerritoryIdToUserIds.keySet())
        {
            // NOTE: can no longer assume all users in indirect territory are indirect
            // now we loop through to find the first indirect user
            for (Id userIdCandidate : indirectTerritoryIdToUserIds.get(t2Id))
            {
                if (idToIndirectUser.containsKey(userIdCandidate) && idToIndirectUser.get(userIdCandidate).AccountId != null)
                {
                    indirectT2IdToDistributorId.put(t2Id, idToIndirectUser.get(userIdCandidate).AccountId);
                    break;
                }
            }
        }
        ilib_LogEvent.info('indirectT2IdToDistributorId : '+indirectT2IdToDistributorId);
        ilib_LogEvent.pop();
        return indirectT2IdToDistributorId;
    }

    // create Apex sharing records from the record IDs to the user IDs
    private static void createSharingRecords(Map<Id, Set<Id>> recordIdToUserIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.createSharingRecords()');
        if (recordIdToUserIds.size() == 0) return;

        List<SObject> shares = new List<SObject>();

        for (Id recordId : recordIdToUserIds.keySet())
        {
            if (recordId == null || recordIdToUserIds.get(recordId) == null || recordIdToUserIds.get(recordId).size() == 0) continue;
            for (Id userId : recordIdToUserIds.get(recordId))
                shares.add(createSharingRecord(recordId, userId));
        }

        List<Database.SaveResult> allResults = Database.insert(shares, false);
        for (Integer i = 0; i < allResults.size(); i++)
        {
            Database.SaveResult res = allResults.get(i);
            if (!res.isSuccess())
                documentDmlError(shares.get(i), res.getErrors());
            else
                    ilib_LogEvent.message('SHARE: share inserted successfully for ' + shares.get(i));
        }
        ilib_LogEvent.pop();
    }

    // creates a share record specific to this implementation
    private static SObject createSharingRecord(Id recordId, Id userId)
    {
        return new SVMXC__Installed_Product__Share(
                ParentId = recordId,
                UserOrGroupId = userId,
                AccessLevel = 'Edit',
                RowCause = Schema.SVMXC__Installed_Product__Share.RowCause.Distributor__c
        );
    }

    // delete Apex sharing records from the record IDs to the user IDs
    private static void removeSharingRecords(Map<Id, Set<Id>> recordIdToUserIds)
    {
        ilib_LogEvent.push(LOG_TITLE + '.removeSharingRecords()');
        if (recordIdToUserIds.size() == 0) {
            ilib_LogEvent.pop();
            return;
        }

        for (Id recordId : recordIdToUserIds.keyset())
            if (recordIdToUserIds.get(recordId).size() == 0)
                recordIdToUserIds.remove(recordId);

        if (recordIdToUserIds.size() == 0) {
            ilib_LogEvent.pop();
            return;
        }

        List<SVMXC__Installed_Product__Share> shares =
        [SELECT Id, ParentId, UserOrGroupId FROM SVMXC__Installed_Product__Share WHERE ParentId IN :recordIdToUserIds.keyset() AND RowCause = :Schema.SVMXC__Installed_Product__Share.RowCause.Distributor__c];

        List<SObject> sharesToRemove = new List<SObject>();
        for (SVMXC__Installed_Product__Share share : shares)
        {
            Set<Id> userIds = recordIdToUserIds.get(share.ParentId);
            ilib_LogEvent.message('userIds : '+userIds);
            if (userIds.contains(share.UserOrGroupId))
                sharesToRemove.add(share);
        }

        List<Database.DeleteResult> allResults = Database.delete(sharesToRemove, false);
        for (Integer i = 0; i < allResults.size(); i++)
        {
            Database.DeleteResult res = allResults.get(i);
            if (!res.isSuccess())
                documentDmlError(shares.get(i), res.getErrors());
            else
                ilib_LogEvent.message('SHARE: share removed successfully for ' + shares.get(i));
        }
        ilib_LogEvent.pop();
    }

    private static void documentDmlError(SObject objShare, List<Database.Error> errors)
    {
        String allErrorsString = '';
        for (Database.Error e : errors)
            allErrorsString += e.getMessage() + '\n\n';

        ilib_LogEvent.message('SHARE: Insert sharing record error for ' + objShare + ' -- ' + allErrorsString);
    }

}
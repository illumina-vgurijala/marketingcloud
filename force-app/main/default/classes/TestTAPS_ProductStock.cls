@isTest
/***************************************************************************************************************************************
* NAME   : TestTAPS_ProductStock 
*    @author Illumina
*    Modification Log:
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
* --------------------------------------------------------------------------------------------------------------------------------------
*/
private class TestTAPS_ProductStock {

    // NOTE: TestTAPS covers scenarios like new user, new territory, territory move
    // this is just to make sure we have coverage of the specific object trigger

    @testSetup static void setupEtmData()
    {
        setupTerritoryData(); 
    }
    static void setupTerritoryData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryDataWithPartners();
        }
    }


    // these methods do most of the object-specific work, modify all of them

    private static TAPS_ComposedBase mshareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mshareClass == null) mshareClass = new TAPS_ProductStock();
        return mshareClass;
    }

    // product stock can't move so some of the implementations aren't covered by functional unit tests
    // add extra coverage here
    @isTest static void extraCoverage()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Product2 prod1 = TestDataFieldService.getNewSerializedProduct();
        SVMXC__Site__c location1 = TestDataFieldService.getNewLocation(accountIds.get(0));

        // add record
        SVMXC__Product_Stock__c rec1 = TestDataFieldService.getNewProductStock(location1.Id, prod1.Id);

        System.assertEquals(SVMXC__Product_Stock__c.sObjectType, getShareClass().getObjectType());

        // also check record id conversion method
        Set<Id> recordIds = getShareClass().getRecordIdsFromAccountIdsCustom(new Set<Id>(accountIds));
        System.assert(recordIds.contains(rec1.Id), 'idsFromAccountIds: Did not successfully convert from account IDs to record IDs');

        // check account id conversion method
        Map<Id, Set<Id>> accountIdsCalculated = getShareClass().mapRecordToAccountsCustom(new Set<Id>{ rec1.Id });
        System.assert(accountIdsCalculated.get(rec1.Id).contains(accountIds.get(0)), 'Did not successfully convert from record IDs to account IDs');

        // check opportunity IDs are not molested
        Set<Id> sameRecordIds = getShareClass().getRecordIdsFromModifiedRecordIdsCustom(new Set<Id>{ rec1.Id });
        System.assert(sameRecordIds.contains(rec1.Id), 'Did not successfully leave record IDs unmolested');

        // check account-FS IDs are converted to opportunity IDs
        Set<Id> sameRecordIds2 = getShareClass().getRecordIdsFromModifiedRecordIdsCustom(new Set<Id>{ location1.Id });
        System.assert(sameRecordIds2.contains(rec1.Id), 'Did not successfully convert from Account-FS IDs to Opportunity IDs');

        getShareClass().getShareObjectType();
        getShareClass().createSharingRecord(rec1.Id, UserInfo.getUserId());
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Product2 prod1 = TestDataFieldService.getNewSerializedProduct();
        SVMXC__Site__c location1 = TestDataFieldService.getNewLocation(accountIds.get(0));

        // add record
        SVMXC__Product_Stock__c rec1;
        Test.startTest();
        {
            rec1 = TestDataFieldService.getNewProductStock(location1.Id, prod1.Id);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, TestTAPS.getAssociatedUserIds()));
        //System.assertEquals(1, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, TestTAPS.getAssociatedPartnerUserIds()));
    }

    // inserting a record with no account
    // should not bomb or create shares
    @isTest static void createOrphanRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Product2 prod1 = TestDataFieldService.getNewSerializedProduct();
        SVMXC__Site__c location1 = TestDataFieldService.getNewLocation(accountIds.get(0));

        // add record
        SVMXC__Product_Stock__c rec1;
        Test.startTest();
        {
            rec1 = TestDataFieldService.initProductStock(location1.Id, prod1.Id);
            rec1.SVMXC__Location__c = null;
            insert rec1;
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));
    }

}
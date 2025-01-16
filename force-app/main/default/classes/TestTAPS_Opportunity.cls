/*
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*			  Joshith						10-Dec-2019			Sonar Qube Changes
*             Satya                         15-Dec-2020         DCP-43261/TASK0548217: changing
*             Akshay Mohan                  22-June-2021        DCP-38968: Account to Field Support extension
*             Ashwin Kumar                  31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    -----------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
private class TestTAPS_Opportunity {

    private static TAPS_ComposedBase implClass;
    
    @testSetup static void setupEtmData()
    {
        setupTerritoryData();
    }
    static void setupTerritoryData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryData();
        }
    }
    private static TAPS_ComposedBase getShareClass()
    {
        if (implClass == null){
            implClass = new TAPS_Opportunity();
        }
        return implClass;
    }


    @isTest static void objectType()
    {
        System.assertEquals(Opportunity.sObjectType, getShareClass().getObjectType(),'Incorrect object type');
    }
    
    @isTest static void createRecordWithFieldUser()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();

        // field users associated with parent account
        User fieldUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, new Set<Id>());
        User fieldUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, new Set<Id>{ fieldUser1.Id });
        SVMXC__Service_Group__c team1 = TestDataFieldService.getNewServiceTeam('Antarctica');
        SVMXC__Service_Group_Members__c fieldService1 = TestDataFieldService.getNewFieldSupport(fieldUser1.Id, fieldUser1.Name, team1.id);
        SVMXC__Service_Group_Members__c fieldService2 = TestDataFieldService.getNewFieldSupport(fieldUser2.Id, fieldUser2.Name, team1.id);

        // this guy has a sharable role, he will be counted
        Account_to_Field_Support__c atfs1 = TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(0), AccountToFieldSupports.FSE_MANAGER, fieldService1.Id);
        // this guy does not have a sharable role, he will not be counted
        TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(0), AccountToFieldSupports.SECONDARY_FSE, fieldService2.Id);

        // add record
        Opportunity rec1;
        Test.startTest();
        {
            rec1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));

            // Added by Satya as part of PRB0042764
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added
        // DCP-38968 2 users from account to field support and 2 users from territory
        System.assertEquals(4, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id),'Share record count not correct (Territory 2+ ATFS 2)');

        // also check record id conversion method
        Set<Id> recordIds = getShareClass().getRecordIdsFromAccountIdsCustom(new Set<Id>(accountIds));
        System.assert(recordIds.contains(rec1.Id), 'idsFromAccountIds: Did not successfully convert from account IDs to record IDs');

        // check account id conversion method
        Map<Id, Set<Id>> accountIdsCalculated = getShareClass().mapRecordToAccountsCustom(new Set<Id>{ rec1.Id });
        System.assert(accountIdsCalculated.get(rec1.Id).contains(accountIds.get(0)), 'Did not successfully convert from record IDs to account IDs');

        // check opportunity IDs are not molested
        Set<Id> sameOpportunityIds = getShareClass().getRecordIdsFromModifiedRecordIdsCustom(new Set<Id>{ rec1.Id });
        System.assert(sameOpportunityIds.contains(rec1.Id), 'Did not successfully leave record IDs unmolested');

        // check account-FS IDs are converted to opportunity IDs
        Set<Id> sameOpportunityIds2 = getShareClass().getRecordIdsFromModifiedRecordIdsCustom(new Set<Id>{
            atfs1.Id
        });
        System.assert(sameOpportunityIds2.contains(rec1.Id), 'Did not successfully convert from Account-FS IDs to Opportunity IDs');
    }

    @isTest static void addFieldUserToRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();

        // field users associated with parent account
        User fieldUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE, new Set<Id>());
        SVMXC__Service_Group__c team1 = TestDataFieldService.getNewServiceTeam('Antarctica');
        SVMXC__Service_Group_Members__c fieldService1 = TestDataFieldService.getNewFieldSupport(fieldUser1.Id, fieldUser1.Name, team1.id);

        // add record
        TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Test.startTest();
        
            // this guy has a sharable role, he will be counted
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            TestDataFieldService.getNewAccountToFieldSupport(accountIds.get(0), AccountToFieldSupports.FSE_MANAGER, fieldService1.Id);            
            Test.getEventBus().deliver();
        
        Test.stopTest();

        List<OpportunityShare> lstOpportunityShare = [SELECT OpportunityId FROM OpportunityShare WHERE UserOrGroupId = :fieldUser1.Id];
        System.assertEquals(1,lstOpportunityShare.size(),'Opportunity not shared with FS user.');
    }

    //Added by Rahul - DCP-25384 Sold To and UC in same Territory    
     @isTest static void checkUCSharesInSameTerritory()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();

        // add record
        Opportunity opp;

        Test.startTest();
        {
            opp = TestDataOpportunity.initOpportunity2(accountIds.get(0));
            opp.Ultimate_Consignee__c = accountIds.get(2);
            //DCP-38968: Add current UC
            opp.Current_Ultimate_Consignee__c = accountIds.get(2);
            insert opp;
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), opp.Id),'Shared not only to territory 1 users');
    }

    //Added by Rahul - DCP-25384 Sold To and UC in Different Territory    
     @isTest static void checkUCSharesInDiffTerritory()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();

        // add record
        Opportunity opp;

        Test.startTest();
        {
            opp = TestDataOpportunity.initOpportunity2(accountIds.get(0));
            opp.Ultimate_Consignee__c = accountIds.get(1);
            insert opp;
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(1, TestTAPS.getShareRecordCount(getShareClass(), opp.Id),'Incorrect shares. Territory 1 has only 1 user');
    }

    //Added by Rahul - DCP-25384 Sold To and UC in Different Region    
     @isTest static void checkUCSharesInDiffRegion()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();

        // add record
        Opportunity opp;

        Test.startTest();
        {
            opp = TestDataOpportunity.initOpportunity2(accountIds.get(0));
            opp.Ultimate_Consignee__c = accountIds.get(3);
            insert opp;
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), opp.Id),'Incorrect shares. Territory 1 has 1 user & Territory 3 has 1 user.');
    }

}
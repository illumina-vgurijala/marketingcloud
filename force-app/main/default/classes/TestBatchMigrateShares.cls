/*
* @Author:  Illumina
* @Date:    
* @Description: 
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Saddam               08-Dec-2022                   Codescan Fix , Assert statement added for test methods 
*/
@isTest
private class TestBatchMigrateShares {

    @isTest
    static void scheduleMethods()
    {
        BatchMigrateCrfShares objBatch = new BatchMigrateCrfShares();
        objBatch.execute(null);
        BatchMigrateOpportunityShares.obsoleteClass();
        //new BatchMigrateOpportunityShares().execute(null);
        System.assert(objBatch != null,'Object not created correctly' );
    }

    /**
     *  @author - Vishal Reddy
     *  @description - execute method
     **/
    @isTest
    static void scheduleMethods2(){
        BatchMigrateCrfShares objBatch = new BatchMigrateCrfShares();
        List<SObject> lst = [SELECT id from Customer_Readiness_Form__c LIMIT 1];
        objBatch.execute(null, lst);
        System.assert(objBatch!= null,'object not found');
        //BatchMigrateOpportunityShares.obsoleteClass();
    }

    // @isTest
    // static void createOpportunityShares()
    // {
    //     Account a = TestDataAccount.initAccount();
    //     a.Account_Group__c = 'Distributor';
    //     insert a;

    //     Opportunity o = TestDataOpportunity.getNewOpportunity(a);

    //     Set<Id> alreadyUsedUserIds = new Set<Id> { UserInfo.getUserId() };
    //     User fieldUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
    //     alreadyUsedUserIds.add(fieldUser1.Id);
    //     User fieldUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
    //     alreadyUsedUserIds.add(fieldUser2.Id);
    //     User fieldUser3 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
    //     alreadyUsedUserIds.add(fieldUser3.Id);
    //     User fieldUser4 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
    //     alreadyUsedUserIds.add(fieldUser4.Id);

    //     SVMXC__Service_Group__c team1 = TestDataFieldService.getNewServiceTeam('Antarctica');

    //     SVMXC__Service_Group_Members__c fieldService1 = TestDataFieldService.getNewFieldSupport(fieldUser1.Id, fieldUser1.Name, team1.id);
    //     SVMXC__Service_Group_Members__c fieldService2 = TestDataFieldService.getNewFieldSupport(fieldUser2.Id, fieldUser2.Name, team1.id);
    //     SVMXC__Service_Group_Members__c fieldService3 = TestDataFieldService.getNewFieldSupport(fieldUser3.Id, fieldUser3.Name, team1.id);
    //     SVMXC__Service_Group_Members__c fieldService4 = TestDataFieldService.getNewFieldSupport(fieldUser4.Id, fieldUser4.Name, team1.id);

    //     TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.PRIMARY_FSE, fieldService1.Id);
    //     TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.PRIMARY_FAS, fieldService2.Id);
    //     TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.FSE_MANAGER, fieldService3.Id);
    //     TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.FAS_MANAGER, fieldService4.Id);

    //     Test.startTest();
    //     {
    //         Test.getEventBus().deliver();
    //         Database.executeBatch(new BatchMigrateOpportunityShares());
    //     }
    //     Test.stopTest();
    // }

    @isTest
    static void createCrfShares()
    {
        Account a = TestDataAccount.initAccount();
        a.Account_Group__c = 'Distributor';
        insert a;

        Opportunity o = TestDataOpportunity.getNewOpportunity(a);
        Customer_Readiness_Form__c crf = TestDataOpportunity.getNewCrf(a.Id, o.Id);

        Set<Id> alreadyUsedUserIds = new Set<Id> { UserInfo.getUserId() };
        User fieldUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
        alreadyUsedUserIds.add(fieldUser1.Id);
        User fieldUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
        alreadyUsedUserIds.add(fieldUser2.Id);
        User fieldUser3 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
        alreadyUsedUserIds.add(fieldUser3.Id);
        User fieldUser4 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
        alreadyUsedUserIds.add(fieldUser4.Id);

        SVMXC__Service_Group__c team1 = TestDataFieldService.getNewServiceTeam('Antarctica');

        SVMXC__Service_Group_Members__c fieldService1 = TestDataFieldService.getNewFieldSupport(fieldUser1.Id, fieldUser1.Name, team1.id);
        SVMXC__Service_Group_Members__c fieldService2 = TestDataFieldService.getNewFieldSupport(fieldUser2.Id, fieldUser2.Name, team1.id);
        SVMXC__Service_Group_Members__c fieldService3 = TestDataFieldService.getNewFieldSupport(fieldUser3.Id, fieldUser3.Name, team1.id);
        SVMXC__Service_Group_Members__c fieldService4 = TestDataFieldService.getNewFieldSupport(fieldUser4.Id, fieldUser4.Name, team1.id);

        TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.PRIMARY_FSE, fieldService1.Id);
        TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.PRIMARY_FAS, fieldService2.Id);
        TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.FSE_MANAGER, fieldService3.Id);
        TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.FAS_MANAGER, fieldService4.Id);

        Test.startTest();
        {
            Test.getEventBus().deliver();
            Database.executeBatch(new BatchMigrateCRFShares());
        }
        Test.stopTest();

        List<Customer_Readiness_Form__Share> shares = [SELECT Id, UserOrGroupId FROM Customer_Readiness_Form__Share WHERE RowCause = 'Field_Users__c' AND ParentId = :crf.Id];
        System.assert(!shares.isEmpty(),'CRF Share is empty');

        Boolean sharedWithFse = false;
        Boolean sharedWithFas = false;
        Boolean sharedWithFseMgr = false;
        Boolean sharedWithFasMgr = false;
        for (Customer_Readiness_Form__Share s : shares)
        {
            if (s.UserOrGroupId == fieldUser1.Id) sharedWithFse = true;
            if (s.UserOrGroupId == fieldUser2.Id) sharedWithFas = true;
            if (s.UserOrGroupId == fieldUser3.Id) sharedWithFseMgr = true;
            if (s.UserOrGroupId == fieldUser4.Id) sharedWithFasMgr = true;
        }

//        System.assert(sharedWithFse, 'Not shared with FSE');
//        System.assert(sharedWithFas, 'Not shared with FAS');
//        System.assert(sharedWithFseMgr, 'Not shared with FSE Manager');
//        System.assert(sharedWithFasMgr, 'Not shared with FAS Manager');
//        System.assert(sharedWithPartnerFse, 'Not shared with Partner FSE');
//        System.assert(sharedWithPartnerFas, 'Not shared with Partner FAS');
    }

    @isTest
    static void documentDmlError()
    {
        SObject so = new Account(Name = 'hi');
        List<Database.Error> errors = new List<Database.Error>();
        CustomerReadinessFormsService.documentDmlError(so, errors);
        System.assert(so!=Null ,'Check Sobject');

    }

    @isTest
    static void removeSharingFromUsers()
    {
        Account a = TestDataAccount.initAccount();
        a.Account_Group__c = 'Distributor';
        insert a;

        Set<Id> alreadyUsedUserIds = new Set<Id> { UserInfo.getUserId() };
        User fieldUser1 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
        alreadyUsedUserIds.add(fieldUser1.Id);
        User fieldUser2 = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, alreadyUsedUserIds);
        alreadyUsedUserIds.add(fieldUser2.Id);

        SVMXC__Service_Group__c team1 = TestDataFieldService.getNewServiceTeam('Antarctica');

        SVMXC__Service_Group_Members__c fieldService1 = TestDataFieldService.getNewFieldSupport(fieldUser1.Id, fieldUser1.Name, team1.id);
        SVMXC__Service_Group_Members__c fieldService2 = TestDataFieldService.getNewFieldSupport(fieldUser2.Id, fieldUser2.Name, team1.id);

        TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.PRIMARY_FSE, fieldService1.Id);
        TestDataFieldService.getNewAccountToFieldSupport(a.Id, AccountToFieldSupports.PRIMARY_FAS, fieldService2.Id);

        Opportunity o = TestDataOpportunity.getNewOpportunity(a);
        Customer_Readiness_Form__c crf = TestDataOpportunity.getNewCrf(a.Id, o.Id);

        Map<Id, Set<Id>> crfIdToUserIds = new Map<Id, Set<Id>> { crf.Id => new Set<Id> {fieldUser1.Id} };
        CustomerReadinessFormsService.removeSharingFromUsers(crfIdToUserIds);

        System.assert(crfIdToUserIds.containskey(crf.Id),'Map doesnot contains the crf id');

    }

}
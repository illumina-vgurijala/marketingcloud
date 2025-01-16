/**  
*    @description  Test class for SharingConsole
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Ashwin Kumar                   28-Mar-2022         DCP-52339: Remove TAPS_Deferred_Object__c & its field's references
*    --------------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest 
public with sharing class TestTAPS_AccountPlans {

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
    @isTest
    static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        System.debug('accountIds: ' + accountIds);
        Id idAccount = accountIds.get(0);

        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test', 'country');
        insert serviceTeam;

        User objUser = TestDataUser.findUserInProfile(Label.Field_Service);

        SVMXC__Service_Group_Members__c technician = TestDataFieldService.createTechnician(objUser.Id, 'Test Technician', serviceTeam.id);
        technician.SVMXC__Email__c = 'b@b.com';
        insert technician;

        Account_to_Field_Support__c accToFieldSupport = TestDataFieldService.createAccountToFieldSupport(idAccount, 'Primary Field Service Engineer', technician.id);
        insert accToFieldSupport;

        // add record
        Account_Plan__c objAccountPlan = TestDataAccountPlan.initAccoutPlan(idAccount);

        Test.startTest();
        insert objAccountPlan;
        Test.getEventBus().deliver();
        Test.stopTest();

        // validate shares were added by batch
        List<Account_Plan__Share> lstShareRecords =
            [SELECT AccessLevel ,UserOrGroupId, UserOrGroup.Name 
             FROM Account_Plan__Share 
             WHERE ParentId = :objAccountPlan.Id
             AND RowCause='Manual'];

        System.debug('lstShareRecords: ' + lstShareRecords);
        System.assertEquals(3, lstShareRecords.size(),'Share records not created as expected');

        Boolean booFoundFieldSupportShare = false;
        for (Account_Plan__Share objshare : lstShareRecords)
        {
            if (objUser.id == objshare.UserOrGroupId && objshare.AccessLevel == 'Read')
                booFoundFieldSupportShare = true;
        }
        System.assert(booFoundFieldSupportShare, 'Read Share record not created for field support user');
    }

    @isTest 
    static void checkAccountToFieldSupportSharing()
    {
        Account objAccount = TestDataAccount.getAccount('ATFS Account Check');
        insert objAccount;

        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test', 'country');
        insert serviceTeam;

        User objUser = TestDataUser.findUserInProfile(Label.Field_Service);

        SVMXC__Service_Group_Members__c technician = TestDataFieldService.createTechnician(objUser.id, 'Test Technician', serviceTeam.id);
        technician.SVMXC__Email__c = 'b@b.com';
        insert technician;

        Account_Plan__c objAccountPlan = TestDataAccountPlan.initAccoutPlan(objAccount.id);
        insert objAccountPlan;

        Account_to_Field_Support__c accToFieldSupport = TestDataFieldService.createAccountToFieldSupport(objAccount.id, 'Primary Field Service Engineer', technician.id);

        Test.startTest();
        insert accToFieldSupport;
        
        List<TAPS_Deferred_Record__c> lstDeferredRecords = [SELECT Id, Record_ID__c FROM TAPS_Deferred_Record__c WHERE Object_Name__c =: TAPS_DeferredRun.ACCOUNT_TO_FIELD_SUPPORT_OBJECT_NAME LIMIT 1];

        System.assertEquals(1, lstDeferredRecords.size(), 'Deferred records not created as expected!');
        System.assert(lstDeferredRecords[0].Record_ID__c.contains(objAccount.id), 'Deferred records not having expected Account Id!');

        new TAPS_DeferredRun().execute(null);
        Test.stopTest();

        lstDeferredRecords = [SELECT Id FROM TAPS_Deferred_Record__c WHERE Object_Name__c =: TAPS_DeferredRun.ACCOUNT_TO_FIELD_SUPPORT_OBJECT_NAME LIMIT 1];

        System.assertEquals(0, lstDeferredRecords.size(), 'Records not processed as expected!');
    }

}
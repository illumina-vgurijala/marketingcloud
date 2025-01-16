/***************************************************************************************************************************************
* NAME   : TestAccountsSelector
* DESCRIPTION  : TestClass for AccountsSelector class
* @AUTHOR : Vignesh S
* @DATE   : 25-Sept-2019
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Vignesh S          25-Sept-2019             Initial Version
* Saddam             05-May-2022              Added AccountsSelector other methods to checkAccQueries() method for code coverage(after code scan fix)
****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  
public with sharing class TestAccountsSelector {
    
    static Case cs;
    static SVMXC__Service_Group__c serviceTeam;
    static Account acc;
    private static final String NAME_FIELD = 'Name';
    private static final String ERP_CUSTOMER_ID = 'ERP_Customer_Id__c';
    private static final Integer QUERY_LIMIT = 2;
    /*
    * @description setupdata method
    */
    @testSetup
    public static void initializeTestData() {

        acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.National_Group_Number__c = acc.ERP_Customer_Id__c;
        acc.Account_Group__c= 'Distributor';
        insert acc;
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname' , AccountId = acc.Id);
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        List<User> lstUsers = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service
                               LIMIT 1];     
        serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c='b@b.com';
        insert technicianFAS;
        
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
        technician.SVMXC__Email__c='b@a.com';
        insert technician;
        
        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Service Engineer',technician.id);
        insert accToFieldSupport;
        
    }
    
    static testMethod void checkAccQueries() {
        Set<String> fieldSet = new Set<String>();
        fieldSet.add(NAME_FIELD);
        fieldSet.add(ERP_CUSTOMER_ID);
        
    Test.startTest();
        Account accnt = [select id,ERP_Customer_Id__c,National_Group_Number__c from account LIMIT 1];

        list<Account> lstAccount1 = new AccountsSelector().selectAccounts(new Set<Id>{accnt.Id});
        system.assert(!lstAccount1.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount3 = new AccountsSelector().selectLoggedInAccountForUser((string)accnt.Id);
        system.assert(!lstAccount3.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount4 = new AccountsSelector().selectLoggedInAccountList(new list<Id>{accnt.Id});
        system.assert(!lstAccount4.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount6 = new AccountsSelector().getAccountsTerritories(new Set<Id>{accnt.Id});
        system.assert(!lstAccount6.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount8 = new AccountsSelector().accountWithFieldSupport(new list<Id>{accnt.Id}, new list<string>
        {'Primary Field Service Engineer'});
        system.assert(!lstAccount8.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount9 = new AccountsSelector().getRqComplianceAccounts(new Set<Id>{accnt.Id});
        system.assert(!lstAccount9.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount10 = new AccountsSelector().accountWithRelatedContacts(new Set<Id>{accnt.Id});
        system.assert(!lstAccount10.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount11 = new AccountsSelector().getParentAccount(new Set<Id>{accnt.Id});
        system.assert(!lstAccount11.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount13 = new AccountsSelector().selectAccountsForERPCustomerIds(new set<string>{accnt.ERP_Customer_Id__c});
        system.assert(!lstAccount13.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount14 = new AccountsSelector().getAccountsforCustomerId(accnt.ERP_Customer_Id__c);
        system.assert(!lstAccount14.isEmpty(),'List has zero Accounts');
        list<Account> lstAccount15 = new AccountsSelector().selectAccountsForNationalGroupNumbers(new Set<String>{accnt.National_Group_Number__c});
        system.assert(!lstAccount15.isEmpty(),'List has matching Accounts');
        //QACM-78
        list<Account> lstAccount16 = new AccountsSelector().selectAccountforLookupController(fieldSet,'Name!=null',QUERY_LIMIT);
        system.assert(!lstAccount16.isEmpty(),'List has zero Accounts');
        //CMCM-12168
        list<Account> lstAccount17 = new AccountsSelector().selectLoggedInOrERPCustomerIdsofAccount(new set<string>{accnt.ERP_Customer_Id__c}, new list<Id>{accnt.Id});
        system.assert(!lstAccount17.isEmpty(),'List has zero Accounts');
        Test.stopTest();
    }
    /**
     * Test for `getAccountwithIds` method.
     * Validates that the method retrieves accounts with the specified IDs and correct fields.
     * The test setup is included as part of the test scenario.
     */
    @isTest
    static void testGetAccountWithIds() { 
        // Test Setup: Create Accounts
        Account acc1 = TestDataAccount.getAccount('Test Acc', 'USD');
        acc1.BillingCity = 'TestCity';
        Account acc2 = TestDataAccount.getAccount('Test Acc1', 'USD');
        acc2.BillingCity = 'TestCity';
        Account acc3 = TestDataAccount.getAccount('Test Acc2', 'USD');
        acc3.BillingCity = 'TestCity';
        insert new List<Account>{acc1, acc2, acc3};
        
        // Prepare the input for the method
        Set<Id> accIds = new Set<Id>{acc1.Id, acc2.Id}; // Specify the IDs to query
        
        // Test Execution
        Test.startTest();
        List<Account> resultAccounts = new accountsselector().getAccountwithIds(accIds);
        Test.stopTest();
        
        // Assertions to validate the method behavior
        // Assert that the number of returned accounts matches the input IDs
        System.assertEquals(2, resultAccounts.size(), 'Two accounts should be returned.');
        
        // Verify the returned accounts contain the expected IDs
        Set<Id> resultIds = new Set<Id>();
        for (Account acc : resultAccounts) {
            resultIds.add(acc.Id);
        }
        System.assert(resultIds.contains(acc1.Id), 'Result should contain Account1');
        System.assert(resultIds.contains(acc2.Id), 'Result should contain Account2');
        
        // Verify the `Territory_Region__c` field is populated
        // for (Account acc : resultAccounts) {
        //     System.assertNotEquals(null, acc.Territory_Region__c, 'Territory Region should be populated');
        // }
    }
}
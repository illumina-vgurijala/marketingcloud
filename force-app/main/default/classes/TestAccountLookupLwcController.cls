@isTest
/**************************************************************************************************************************************
* NAME   : TestAccountLookupLwcController
* DESCRIPTION  : Test class for AccountLookupLwcController to validate the functionality of its methods.
*  
* @AUTHOR : Abhishek Yadav
* @DATE   : 26-Jul-2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav         26-Jul-2024         Initial Version. Added unit tests for account lookup operations.
****************************************************************************************************************************************/
public with sharing class TestAccountLookupLwcController {

    /**
    * Unit test for AccountLookupLwcController methods fetchLookupData and fetchDefaultRecord
    * @description This test method inserts test Account records and validates the fetchLookupData and fetchDefaultRecord methods.
    **/
    @isTest
    public static void testfetchLookupData() {
        // Create test data
        List<Account> acclist = new List<Account>();
        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c = 'Distributor';
        objAccount.Clinical_Type__c = 'Clinical';
        acclist.add(objAccount);
        Insert acclist;

        // Test the methods
        Test.startTest();
        List<sObject> sObjectList = AccountLookupLwcController.fetchLookupData('Test', 'Account');
        sObject singlesObject = AccountLookupLwcController.fetchDefaultRecord(objAccount.id, 'Account');
        Assert.isTrue(sObjectList != null , 'list is empty');
        Assert.isTrue(singlesObject != null , 'record is empty');
        Test.stopTest();
    }

    /**
    * Unit test for AccountLookupLwcController method fetchAccountData
    * @description This test method inserts test Account records and validates the fetchAccountData method.
    **/
    @isTest
    public static void testfetchAccountData() {
        // Create test data
        List<Account> acclist = new List<Account>();
        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c = 'Distributor';
        objAccount.Clinical_Type__c = 'Clinical';
        acclist.add(objAccount);

        Account objAccount1 = TestDataAccount.getAccount('Test Account', 'USD');
        objAccount1.Account_Group__c = 'Distributor';
        objAccount1.Clinical_Type__c = 'Clinical';
        objAccount1.ERP_Customer_Id__c = '12346899';
        acclist.add(objAccount1);
        Insert acclist;

        // Test the methods
        Test.startTest();
        List<sObject> sObjectList = AccountLookupLwcController.fetchAccountData('Test', 'Account');
        List<sObject> sObjectList1 = AccountLookupLwcController.fetchAccountData('12346899', 'Account');
        Assert.isTrue(sObjectList != null , 'list is empty');
        Assert.isTrue(sObjectList1 != null , 'list is empty');
        Test.stopTest();
    }
    /**
    * Unit test for AccountLookupLwcController method fetchLookupData to cover the exception
    * @description This test method sets testCodeCoverage to true to cover the exception handling.
    **/
    @isTest
    public static void testFetchLookupDataException() {
        // Test the exception handling
        Test.startTest();
        AccountLookupLwcController.testCodeCoverage = true;
        Boolean exceptionThrown = false;
        try {
            AccountLookupLwcController.fetchLookupData('Test', 'Account');
        } catch (AccountLookupLwcController.CustomException e) {
            exceptionThrown = e.getMessage().contains('QUERY_EXCEPTION');
        }
        Assert.isTrue(exceptionThrown, 'Custom exception was not thrown as expected');
        Test.stopTest();
    }

    /**
    * Unit test for AccountLookupLwcController method fetchDefaultRecord to cover the exception
    * @description This test method sets testCodeCoverage to true to cover the exception handling.
    **/
    @isTest
    public static void testFetchDefaultRecordException() {
        // Test the exception handling
        Test.startTest();
        AccountLookupLwcController.testCodeCoverage = true;
        Boolean exceptionThrown = false;
        try {
            AccountLookupLwcController.fetchDefaultRecord('001000000000001', 'Account');
        } catch (AccountLookupLwcController.CustomException e) {
            exceptionThrown = e.getMessage().contains('QUERY_EXCEPTION');
        }
        Assert.isTrue(exceptionThrown, 'Custom exception was not thrown as expected');
        Test.stopTest();
    }

    /**
    * Unit test for AccountLookupLwcController method fetchAccountData to cover the exception
    * @description This test method sets testCodeCoverage to true to cover the exception handling.
    **/
    @isTest
    public static void testFetchAccountDataException() {
        // Test the exception handling
        Test.startTest();
        AccountLookupLwcController.testCodeCoverage = true;
        Boolean exceptionThrown = false;
        try {
            AccountLookupLwcController.fetchAccountData('Test', 'Account');
        } catch (AccountLookupLwcController.CustomException e) {
            exceptionThrown = e.getMessage().contains('QUERY_EXCEPTION');
        }
        Assert.isTrue(exceptionThrown, 'Custom exception was not thrown as expected');
        Test.stopTest();
    }
}
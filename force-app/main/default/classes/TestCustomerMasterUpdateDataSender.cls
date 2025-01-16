/**
* @author Rohit Sahu
* @date   2024-05-21
* @description  CMCM-7687  CSA - SFDC Updates to send value to SAP (Parthi/Bruce)
* MODIFICATION LOG:  
* -------------------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                 DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------------------------------
* Gerardo Garcia            2024-05-30          CMCM-7687 Initial tests
*/
@IsTest
private class TestCustomerMasterUpdateDataSender {

    private static final String ACCOUNT_NAME = 'Test Account1';
    private static final String ACCOUNT_WO_ERP = 'Test Account without ERP';

    @TestSetup
    static void makeData(){

        Id prospectRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountProspect).getRecordTypeId();
        Id indirectPartnerRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();

        Account  testAccount1 = TestDataAccount.getAccount(ACCOUNT_NAME);
        testAccount1.Account_Group__c = Accounts.GROUP_SOLD_TO;
        testAccount1.RecordTypeId = indirectPartnerRecordType;

        Account  accountWithoutERP = TestDataAccount.getAccount(ACCOUNT_WO_ERP);// Account_Group__c = Prospect
        accountWithoutERP.ERP_Customer_Id__c = '';
        testAccount1.RecordTypeId = prospectRecordType;

        insert new List<Account> {testAccount1, accountWithoutERP};
    }

    @IsTest
    private static void sendAccountTestMethodDuringUpdateERPCustomerId() {
        Test.setMock(HttpCalloutMock.class, new MockHTTPCallout());

        Account  testAccount = getAccount(ACCOUNT_WO_ERP);

        Test.starttest();
        testAccount.ERP_Customer_Id__c = TestData.getRandomNumeric(10);
        update testAccount;
        Test.Stoptest();

        List<FeedItem> feeds = getFeedItems();
        System.debug('feeds' + JSON.serializePretty(feeds));
        Assert.isTrue(feeds.size() > 0, 'A feed should be created on success');
        Assert.isTrue(feeds[0].Body.contains(ACCOUNT_WO_ERP));
    }

    @IsTest
    private static void sendAccountTestMethodDuringUpdateClinicalType() {
        Test.setMock(HttpCalloutMock.class, new MockHTTPCallout());

        Account testAccount = getAccount(ACCOUNT_NAME);

        Test.starttest();
        testAccount.Clinical_Type__c = 'Healthcare Prime';
        update testAccount;
        Test.Stoptest();

        List<FeedItem> feeds = getFeedItems();
        System.debug('feeds' + JSON.serializePretty(feeds));
        Assert.isTrue(feeds.size() > 0, 'A feed should be created on success');
        Assert.isTrue(feeds[0].Body.contains(ACCOUNT_NAME));
    }

    @IsTest
    private static void sendAccountTestMethodDuringUpdateClinicalTypeEmptyString() {
        Test.setMock(HttpCalloutMock.class, new MockHTTPCallout());

        Account testAccount = getAccount(ACCOUNT_NAME);

        Test.starttest();
        testAccount.Clinical_Type__c = '';
        update testAccount;
        Test.Stoptest();

        List<FeedItem> feeds = getFeedItems();
        System.debug('feeds' + JSON.serializePretty(feeds));
        Assert.isTrue(feeds.size() > 0, 'A feed should be created on success');
        Assert.isTrue(feeds[0].Body.contains(ACCOUNT_NAME));
    }

    //Added sendBulkAccountTestMethod-Karthik Madugula
    @IsTest
    private static void sendBulkAccountTestMethod() {
        List<Account> lstAccounts = new List<Account>();
        for(Integer i=0;i<10;i++)
        	lstAccounts.add(TestDataAccount.getAccount('Testing '+i));
        insert lstAccounts;
        Test.starttest();
        for(Account objAccount:lstAccounts)
            ProspectAccountAddressValidationControl.submitUpdateOutboundRequest(objAccount);
        Test.stopTest();

        Assert.isTrue(MockHTTPCallout.booResponseSuccess, 'It should be marked as success');
    }

    private static List<FeedItem> getFeedItems() {
        return [SELECT id, Body, ParentId FROM FeedItem LIMIT 200];
    }

    private static Account getAccount(String name) {
        return [SELECT id FROM Account WHERE Name = :name LIMIT 1];
    }
}
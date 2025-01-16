/**
 *    @author Prashanth
 *    @date   10-Sep-2020
 *    @description: Test class for ContactsSelector
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Prashanth Kumar              10-Sep-2020          Original version
 *    Deep Diwakar                16-April-2021   Added test for customer community contact selector method
 *    Deep Diwakar                July-19-2021         DCP-45658: Test methods for SOQL instrumentation of ContactsSelector class.
 *    Deep Diwakar                Jun-27-2024          CMCM-6457: Added test method for selectContactsWithWaterfall method
 *    Deep Diwakar                Jul-29-2024          CMCM-7519: Added test method for selectContactFieldsForTask method
 *    Deep Diwakar                Aug-09-2024          CMCM-9421: Added test method for selectContactsForCampMemberFields method
 *    ------------------------------------------------------------------------------------
 *
 */
@istest
public class TestContactsSelector {
    /**
    *  @description Test class for ContactsSelector methods.
    *
    **/
    @istest
    static void testAll(){
        Account account1 = TestDataAccount.getCustomerAccount();
        insert account1;
        System.assert(account1.Id != null);
        //creation of contacts
        Contact con1 =TestDataPerson.initContact(account1.Id);
        insert con1;
        System.assert(con1.Id != null);

        Contact testContact = TestDataMarketing.createContact('TestWin', 'TestMerge1', 'testwinmerge1@testing.com', 'US');
        testContact.Last_Responded_Campaign_Date__c = System.Now();
        update testContact;

        Test.startTest();
        List<Contact> lstContacts = new ContactsSelector().selectContactsFromAccount(new Set<Id>{account1.Id});
        System.assert(lstContacts != null);
        new ContactsSelector().selectContacts(new Set<Id>{con1.Id});
        new ContactsSelector().selectLoggedInAccountContacts(account1.Id,'Inactive');
        new ContactsSelector().selectContactsByEmail(new Set<String>{lstContacts[0].Email});
        new ContactsSelector().contactsByEmailID(new Set<String>{lstContacts[0].Email});
        new ContactsSelector().selectContactsWithSftwDwnldByEmail(new Set<String>{lstContacts[0].Email});
        new ContactsSelector().selectContactIdsforPGUIDId(new Set<String>{'123456'});
        new ContactsSelector().returnContactWithACRDetails(new Set<Id>{con1.Id});
        new ContactsSelector().returnAccountBillingCountry(con1.Id);

        //Customer community contact selector test
        List<Contact>commContList = new ContactsSelector().selectCustomerCommunityContactsByEmail(new Set<String>{con1.Email});
        System.assertEquals(con1.FirstName, commContList.get(0).FirstName);


        List<Contact> lstWaterfallContList = new ContactsSelector().selectContactsWithWaterfall(new Set<Id>{testContact.Id});
        Assert.areEqual('Engaged',lstWaterfallContList.get(0).Waterfall_Stage__c, 'Selector method selectContactsWithWaterfall did not query waterfall field correctly ');
           
        Test.stopTest();
    }

    @isTest
    static void testSelectContactFieldsForTask() {
        Contact testContact = TestDataMarketing.createContactForMarketable('Marketing', 'Testing', 'marketing_task@testing.com', 'US');
        testContact.Form_Type__c = 'Questions';
        testContact.Product_Interest__c = 'Consumables;Services';
        testContact.Questions_For_Rep__c = 'Please refer to the Questions for Rep field for more information about this Contact inquiry';
        testContact.Last_Form_Submission_URL__c = 'www.test.com';

        insert testContact;

        Test.startTest();
        List<Contact> lstContactWithTaskFields = new ContactsSelector().selectContactFieldsForTask(new Set<Id>{testContact.Id});
        Test.stopTest();

        Assert.areEqual('Questions',lstContactWithTaskFields.get(0).Form_Type__c, 'Selector method selectContactFieldsForTask did not query form type field correctly ');
    

    }

    @isTest
    static void testSelectContactsForCampMemberFields() {

        Contact testContact = TestDataMarketing.createContactForMarketable('Marketing', 'Testing', 'marketing_task@testing.com', 'US');
        testContact.Form_Type__c = 'Questions';
        testContact.Media_Code__c = 'Random123';
        testContact.Campaign_Attribution__c = 'Cattr-Random123';
       
        insert testContact;

        Test.startTest();
        List<Contact> lstContactWithCampMemFields = new ContactsSelector().selectContactsForCampMemberFields(new Set<Id>{testContact.Id});
        Test.stopTest();

        Assert.areEqual('Questions',lstContactWithCampMemFields.get(0).Form_Type__c, 'Selector method selectContactsForCampMemberFields did not query form type field correctly ');
        Assert.areEqual('Random123',lstContactWithCampMemFields.get(0).Media_Code__c, 'Selector method selectContactsForCampMemberFields did not query media code field correctly ');
    
    

    }

/**
 * @author:         Deep Diwakar
 * @date:           07-16-2021
 * @description     This method test SOQL instrumentation when feature flag is On
 */
    @isTest
    static void contactsSelectorFFOn() {

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', true);

        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        Account account1 = TestDataAccount.getCustomerAccount();
        insert account1;
        //creation of contacts
        Contact con1 =TestDataPerson.initContact(account1.Id);
        insert con1;

        Test.startTest();
        // instrumented queries from ContactsSelector class
        List<Contact> lstContacts = new ContactsSelector().selectContactsFromAccount(new Set<Id>{account1.Id});
        new ContactsSelector().selectContacts(new Set<Id>{con1.Id});
        new ContactsSelector().selectLoggedInAccountContacts(account1.Id,'Inactive');
        new ContactsSelector().selectContactsByEmail(new Set<String>{lstContacts[0].Email});
        new ContactsSelector().contactsByEmailID(new Set<String>{lstContacts[0].Email});
        new ContactsSelector().selectContactsWithSftwDwnldByEmail(new Set<String>{lstContacts[0].Email});
        new ContactsSelector().selectContactIdsforPGUIDId(new Set<String>{'123456'});
        new ContactsSelector().returnContactWithACRDetails(new Set<Id>{con1.Id});
        new ContactsSelector().returnAccountBillingCountry(con1.Id);
        new ContactsSelector().selectCustomerCommunityContactsByEmail(new Set<String>{con1.Email});

        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'ContactsSelector.selectContactsFromAccount';
        Assert.isTrue([SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle] > 0, 'slow query log did not create');

    }

/**
 * @author:         Deep Diwakar
 * @date:           07-16-2021
 * @description     This method test SOQL instrumentation when feature flag is Off
 */
    @isTest
    static void contactsSelectorFFOff() {

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', false);

        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        Account account1 = TestDataAccount.getCustomerAccount();
        insert account1;
        //creation of contacts
        Contact con1 =TestDataPerson.initContact(account1.Id);
        insert con1;

        Test.startTest();
        // instrumented queries from ContactsSelector class
        List<Contact> lstContacts = new ContactsSelector().selectContactsFromAccount(new Set<Id>{account1.Id});
        new ContactsSelector().selectContacts(new Set<Id>{con1.Id});
        new ContactsSelector().selectLoggedInAccountContacts(account1.Id,'Inactive');
        new ContactsSelector().selectContactsByEmail(new Set<String>{lstContacts[0].Email});
        new ContactsSelector().contactsByEmailID(new Set<String>{lstContacts[0].Email});
        new ContactsSelector().selectContactsWithSftwDwnldByEmail(new Set<String>{lstContacts[0].Email});
        new ContactsSelector().selectContactIdsforPGUIDId(new Set<String>{'123456'});
        new ContactsSelector().returnContactWithACRDetails(new Set<Id>{con1.Id});
        new ContactsSelector().returnAccountBillingCountry(con1.Id);
        new ContactsSelector().selectCustomerCommunityContactsByEmail(new Set<String>{con1.Email});

        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'ContactsSelector.selectLeadsForPGUID';
        System.assertEquals(0, [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle]);

    }

    private static void setThreshholdsToZero()
    {
        PS_Log_Setting__mdt settings = new ilib_LogSettings().query();
        settings.Slow_Query_Threshold__c = 0.0;
        settings.Slow_Transaction_Threshold__c = 0.0;
        settings.Disable_All_Log_Persistence__c = false;
        settings.Disable_Slow_Query_Publish__c = false;
        settings.Disable_Slow_Transaction_Publish__c = false;
        //CMSI-2 Pause_Publishes_Until__c moved to code params metadata

        ilib_LogSettings.unitTestSettingsRecord = settings;
    }
}
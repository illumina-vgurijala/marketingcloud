/*
 * @author:         Sarath Pullanikkatt
 * @date:           12-20-2019
 * @description     Test Class for CommunitySelfRegistrationFormController
 */
@isTest(seeAllData = false)
public class TestCommunitySelfRegistrationForm {
    public static String strExistingContactEmail = 'testemailaddress1@randomdomain.com.test';
    public static String strDupContactEmail = 'testemailaddress2@randomdomain.com.test';
    
    @testSetup
    static void initializeTestData() {
        Account a1 = TestDataAccount.getNewAccount();
        Account a2 = TestDataAccount.getNewAccount();
        
        Contact c1 = TestDataPerson.initContact(a1.Id);
        c1.Email = strExistingContactEmail;
        Contact c2 = TestDataPerson.initContact(a1.Id);
        c2.Email = strDupContactEmail;
        Contact c3 = TestDataPerson.initContact(a2.Id);
        c3.Email = strDupContactEmail;
        
        List<Contact> lstContacts = new List<Contact>();
        lstContacts.add(c1);
        lstContacts.add(c2);
        lstContacts.add(c3);
        
        insert lstContacts;
    }
    
    static testMethod void testGetCountries() {
        
        Test.startTest();
        Map<String, String> strCountries = CommunitySelfRegistrationFormController.getCountries();
        Test.stopTest();
        
        System.assertEquals(true,strCountries.size() > 0);
    }

    static testMethod void testRegisterIlluminaUser() {
        
        String strEmail = TestData.getRandom(10) + '@illumina.com';
        String strFirstName = TestData.getRandom(8);
        String strLastName = TestData.getRandom(8);
        String strTitle = TestData.getRandom(10);
        String strLocation = 'US';
        String strPreferredLanguage = 'en_US';
        String strPassword = '7fD_8728!KDaXBi';
        String strExceptionMsg = '';
        
        Test.startTest();
        try {
            String response = CommunitySelfRegistrationFormController.registerCommunityUser(strEmail, strFirstName, strLastName, strTitle, strLocation, strPreferredLanguage, strPassword);
            System.debug('response -- ' + response);
        }
        catch(Exception e)
        {
            strExceptionMsg = e.getMessage();
            System.debug(e.getMessage());
        }
        Test.stopTest();
        
        System.assert(strExceptionMsg.containsIgnoreCase('Exception'));
    }
    
    static testMethod void testRegisterExternalUser() {
        
        String strEmail = strExistingContactEmail;
        String strFirstName = TestData.getRandom(8);
        String strLastName = TestData.getRandom(8);
        String strTitle = TestData.getRandom(10);
        String strLocation = 'US';
        String strPreferredLanguage = 'en_US';
        String strPassword = '7fD_8728!KDaXBi';
        String strExceptionMsg = '';
        System.debug('strExceptionMsg' + strExceptionMsg);
        
        //Testing the positive scenario. External user creation will succeed
        Test.startTest();
        String response = CommunitySelfRegistrationFormController.registerCommunityUser(strEmail, strFirstName, strLastName, strTitle, strLocation, strPreferredLanguage, strPassword);        
        System.assert(response.containsIgnoreCase('Success'));
        Test.stopTest();
    }
    
    static testMethod void testRegisterExternalUserFailure() {
        
        String strEmail = strDupContactEmail;
        String strFirstName = TestData.getRandom(8);
        String strLastName = TestData.getRandom(8);
        String strTitle = TestData.getRandom(10);
        String strLocation = 'US';
        String strPreferredLanguage = 'en_US';
        String strPassword = '7fD_8728!KDaXBi';
        String strExceptionMsg = '';
        
        Test.startTest();
        try {
        	String response = CommunitySelfRegistrationFormController.registerCommunityUser(strEmail, strFirstName, strLastName, strTitle, strLocation, strPreferredLanguage, strPassword);
            System.debug('response' + response);
        }
        catch(Exception e) {
            strExceptionMsg = e.getMessage();
            System.debug(e.getMessage());
        }
        Test.stopTest();
        
        System.assert(strExceptionMsg.containsIgnoreCase('Exception'));
    }
}
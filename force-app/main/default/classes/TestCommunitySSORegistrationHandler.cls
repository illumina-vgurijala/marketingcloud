/*
 * @author:         Deep Diwakar
 * @date:           03-31-2021
 * @description     Test class for CommunitySSORegistrationHandler.cls
 */


@isTest
private class TestCommunitySSORegistrationHandler {

    private static String authId = 'testId';
    private static String authFirstName = 'testFirst';
    private static String authLastName = 'testLast';
    private static String authUserName = 'testuserlong';
    private static String authEmail = 'testuser@example.org';
    private static String authInternalEmail = 'testuser@illumina.com';
    private static String authCountry = 'US';
    private static String authLanguage = 'en_US';
    private static String authLocale = 'en_US';
    private static String authPlatform = 'platform';
    private static String authTimeZone = 'GMT';
    private static String authEmailEncoding = 'UTF-8';
    private static String sfdcGenericUserEmail = 'rohit_sharma@cricket.com';
    private static String authUserParamLang = 'language';
    private static String authUserParamCountry = 'addr_country';
    private static final Integer EIGHT = 8;
    private static final String DEFAULT_ACCOUNTNAME = Label.Comm_SSO_Default_Account_Name;



    @TestSetup
    static void initializeTestData() {
        Account commDefaultAccount = TestDataAccount.getAccount(DEFAULT_ACCOUNTNAME);
        insert commDefaultAccount;
        System.debug('commDefaultAccount: ' + commDefaultAccount.Id);

        Contact commContact = new Contact(FirstName = 'Rohit', LastName = 'Sharma', Email = sfdcGenericUserEmail, AccountId = commDefaultAccount.Id);
        insert commContact;

        Profile commExtProfile = [SELECT Id FROM Profile WHERE Name = 'Community External User'];

        User commUser = new User();
        commUser.username = 'rohit_sharma@cricket.com';
        commUser.email = sfdcGenericUserEmail;
        commUser.lastName = 'Sharma';
        commUser.firstName = 'Rohit';
        commUser.contactId = commContact.Id;
        commUser.CountryCode = authCountry;
        commUser.LanguageLocaleKey = authLanguage;
        String alias = 'Rohit' + 'Sharma';

        //Alias must be 8 characters or less
        if(alias.length() > EIGHT) {
            alias = alias.substring(0, 8);
        }
        commUser.alias = alias;
        commUser.localesidkey = authLocale;
        commUser.emailEncodingKey = authEmailEncoding;
        commUser.timeZoneSidKey = authTimeZone;
        commUser.profileId = commExtProfile.Id;
        insert commUser;

    }

    @isTest
    static void testCreateUserNew() {

        CommunitySSORegistrationHandler regHandler = new CommunitySSORegistrationHandler();

        // test data for platform
        Auth.UserData testUserData = new Auth.UserData(authId, authFirstName, authLastName,
        authFirstName + authFirstName, authEmail, null, authUserName, authLocale, authPlatform,
        null, new Map<String, String>{authUserParamLang => authLanguage, authUserParamCountry => authCountry});

        Test.startTest();

        User commUser = regHandler.createUser(null, testUserData);

        Test.stopTest();

        System.assertEquals(authFirstName, commUser.firstName);


    }

    @isTest
    static void testCreateUserInternal() {

        CommunitySSORegistrationHandler regHandler = new CommunitySSORegistrationHandler();
        Auth.UserData testUserData = new Auth.UserData(authId, authFirstName, authLastName,
        authFirstName + authLastName, authInternalEmail, null, authUserName, authLocale, authPlatform,
        null, new Map<String, String>{authUserParamLang => authLanguage, authUserParamCountry=> authCountry});

        String exceptionMsg = '';

        Test.startTest();
        try {
            User commUser = regHandler.createUser(null, testUserData);
            System.debug('commUser: ' + commUser);

        } catch(Exception ex) {
            exceptionMsg = ex.getMessage();


        }
        Test.stopTest();


        System.assertEquals('Comm_SSO_Error_Illumina_Employee', exceptionMsg);

    }

    @isTest
    static void testCreateUserExistingUser() {

        User extUser = [SELECT Id, Name, FirstName, LastName, Email FROM User WHERE Email =: sfdcGenericUserEmail LIMIT 1];


        CommunitySSORegistrationHandler regHandler = new CommunitySSORegistrationHandler();
        Auth.UserData testUserData = new Auth.UserData(authId, extUser.FirstName, extUser.LastName,
        extUser.Name, extUser.Email, null, authUserName, authLocale, authPlatform,
        null, new Map<String, String>{authUserParamLang => authLanguage, authUserParamCountry => authCountry});

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();

        User regHandlerUser;

        System.runAs(thisUser) {
            regHandlerUser = regHandler.createUser(null, testUserData);

        }

        Test.stopTest();

        System.assertEquals(extUser.FirstName, regHandlerUser.FirstName);


    }


    @isTest
    static void testCreateUserExistingContact() {


        Contact commContact = [SELECT Id, Name, FirstName, LastName, Email FROM Contact WHERE Email =: sfdcGenericUserEmail LIMIT 1];


        CommunitySSORegistrationHandler regHandler = new CommunitySSORegistrationHandler();
        Auth.UserData testUserData = new Auth.UserData(authId, commContact.FirstName, commContact.LastName,
        commContact.Name, commContact.Email, null, authUserName, authLocale, authPlatform,
        null, new Map<String, String>{authUserParamLang => authLanguage, authUserParamCountry => authCountry});
        Test.startTest();

        User commUser = regHandler.createUser(null, testUserData);

        Test.stopTest();

        System.assertEquals(commContact.FirstName, commUser.firstName);


    }

    @isTest
    static void testCreateUserExistingMultipleUsers() {

        User commUser1 = [SELECT Id, Name, FirstName, LastName, Email FROM User WHERE LastName = 'Sharma' AND FirstName = 'Rohit'
                            AND Email =: sfdcGenericUserEmail LIMIT 1];

        Account commDefaultAccount = [SELECT Id FROM Account WHERE Name =: DEFAULT_ACCOUNTNAME];

        // add second contact and user
        Contact commContact2 = new Contact(FirstName = 'Virat', LastName = 'Kohli', Email = sfdcGenericUserEmail, AccountId = commDefaultAccount.Id);
        insert commContact2;

        Profile commExtProfile = [SELECT Id FROM Profile WHERE Name = 'Community External User'];

        // create user with same email id
        User commUser2 = new User();
        commUser2.username = 'virat_kohli@cricket.com.icpp';
        commUser2.email = sfdcGenericUserEmail;
        commUser2.lastName = 'Kohli';
        commUser2.firstName = 'Virat';
        commUser2.contactId = commContact2.Id;
        commUser2.CountryCode = authCountry;
        commUser2.LanguageLocaleKey = authLanguage;
        String alias2 = 'Virat' + 'Kohli';
        //Alias must be 8 characters or less
        if(alias2.length() > EIGHT) {
            alias2 = alias2.substring(0, 8);
        }
        commUser2.alias = alias2;
        commUser2.localesidkey = authLocale;
        commUser2.emailEncodingKey = authEmailEncoding;
        commUser2.timeZoneSidKey = authTimeZone;
        commUser2.profileId = commExtProfile.Id;

        insert commUser2;


        CommunitySSORegistrationHandler regHandler = new CommunitySSORegistrationHandler();
        Auth.UserData testUserData = new Auth.UserData(authId, commUser1.FirstName, commUser1.LastName,
        commUser1.Name, commUser1.Email, null, authUserName, authLocale, authPlatform,
        null, new Map<String, String>{authUserParamLang => authLanguage, authUserParamCountry => authCountry});

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        User regHandlerUser;

        Test.startTest();

        System.runAs(thisUser) {
            regHandlerUser = regHandler.createUser(null, testUserData);

        }

        Test.stopTest();

        System.debug('regHandlerUser: ' + regHandlerUser);

        System.assertEquals(commUser1.FirstName, regHandlerUser.firstName);


    }

    @isTest
    static void testCreateUserExistingMultipleUsersPGUID() {

        Account commDefaultAccount = [SELECT Id FROM Account WHERE Name =: DEFAULT_ACCOUNTNAME];

        // add second contact and user
        Contact commContact2 = new Contact(FirstName = 'Jaspreet', LastName = 'Bumrah', Email = sfdcGenericUserEmail, PGUID__c = '123-ab', AccountId = commDefaultAccount.Id);
        insert commContact2;

        Profile commExtProfile = [SELECT Id FROM Profile WHERE Name = 'Community External User'];


        User commUser2 = new User();
        commUser2.username = 'jas_bumrah@cricket.com.icpp';
        commUser2.email = sfdcGenericUserEmail;
        commUser2.lastName = 'Bumrah';
        commUser2.firstName = 'Jaspreet';
        commUser2.contactId = commContact2.Id;
        commUser2.CountryCode = authCountry;
        commUser2.LanguageLocaleKey = authLanguage;
        String alias2 = 'Jaspreet' + 'Bumrah';
        //Alias must be 8 characters or less
        if(alias2.length() > EIGHT) {
            alias2 = alias2.substring(0, 8);
        }
        commUser2.alias = alias2;
        commUser2.localesidkey = authLocale;
        commUser2.emailEncodingKey = authEmailEncoding;
        commUser2.timeZoneSidKey = authTimeZone;
        commUser2.profileId = commExtProfile.Id;

        insert commUser2;


        CommunitySSORegistrationHandler regHandler = new CommunitySSORegistrationHandler();
        Auth.UserData testUserData = new Auth.UserData('123-ab', commContact2.FirstName, commContact2.LastName,
        commContact2.Name, commContact2.Email, null, authUserName, authLocale, authPlatform,
        null, new Map<String, String>{authUserParamLang => authLanguage, authUserParamCountry => authCountry});

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        User regHandlerUser;

        Test.startTest();

        System.runAs(thisUser) {
            regHandlerUser = regHandler.createUser(null, testUserData);

        }

        Test.stopTest();

        System.assertEquals(commContact2.FirstName, regHandlerUser.FirstName);


    }

    @isTest
    static void testCreateUserMultipleContacts() {

        Account commDefaultAccount = [SELECT Id FROM Account WHERE Name =: DEFAULT_ACCOUNTNAME];

        // add second contact
        Contact commContact1 = new Contact(FirstName = 'Ajinkya', LastName = 'Rahane', Email = 'cricket@test.com', AccountId = commDefaultAccount.Id);
        Contact commContact2 = new Contact(FirstName = 'Mahendra', LastName = 'Dhoni', Email = 'cricket@test.com', AccountId = commDefaultAccount.Id);

        List<Contact> contactList = new List<Contact>();
        contactList.add(commContact1);
        contactList.add(commContact2);

        insert contactList;


        CommunitySSORegistrationHandler regHandler = new CommunitySSORegistrationHandler();
        Auth.UserData testUserData = new Auth.UserData(authId, commContact1.FirstName, commContact1.LastName,
        commContact1.Name, commContact1.Email, null, authUserName, authLocale, authPlatform,
        null, new Map<String, String>{authUserParamLang => authLanguage, authUserParamCountry => authCountry});
        Test.startTest();

        User commUser = regHandler.createUser(null, testUserData);

        Test.stopTest();

        System.assertEquals(commContact1.FirstName, commUser.FirstName);


    }

    @isTest
    static void testUpdateUser() {

        CommunitySSORegistrationHandler regHandler = new CommunitySSORegistrationHandler();
        Auth.UserData testUserData = new Auth.UserData(authId, authFirstName, authLastName,
        authFirstName + authLastName, authEmail, null, authUserName, authLocale, authPlatform,
        null, new Map<String, String>{authUserParamLang => authLanguage, authUserParamCountry => authCountry});

        User commUser = regHandler.createUser(null, testUserData);
        insert commUser;

        Test.startTest();

        regHandler.updateUser(commUser.Id,null, testUserData);

        Test.stopTest();

        System.debug('today: ' + Date.today());

        System.debug('commUser.LastLoginDate: ' + commUser.LastLoginDate);

        System.assertEquals(authLastName, commUser.lastName);


    }


}
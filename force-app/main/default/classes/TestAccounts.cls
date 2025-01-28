/*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Saddam                22-Feb-2022           PM-33,PM-430,Added update and insert test method for Accounts.updateRQConEligibleAccount() 
 ---------------------------------------------------------------------------------------------------------------------------------------

/****************************************************************************************************************************************
* NAME         : AccountContactRelationships
* DESCRIPTION  : Handler class for AccountContactRelationship Logic 
*                    
* @AUTHOR : Saddam
* @DATE   : 21-Mar-2022 
* 
* MODIFICATION LOG:  
* -------------------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------------------------------
  Saddam                21-Mar-2022           created two methods to cover updateRQConEligibleAccount().PM-33 and PM-430
  Gerardo Garcia        07-Aug-2024           CMCM-9578 Move PB into Trigger code.
  Venkat Gurijala       28-Jan-2025
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
//adding this to commit the changes using devops center
@isTest
public class TestAccounts {

    private static final String ACCOUNTID1 = '0013F00000Mjw8yQAB';
    private static final String ACCOUNTID2 = '0013F00000IYkwkQAD';
    private static final String ACCOUNT_1 = 'testAccount1';
    private static final String ACCOUNT_2 = 'testAccount2';
    private static final String CUSTOMER = 'customer';
    private static final String INDIRECT_CHANNEL = 'indirect';
    private static final String ILLUMINA = 'Illumina';
    private static final String ILLUMINA_PROSPECT = 'testProspectAccount';
    private static final String CHANNEL_PARTNER_PROSPECT = 'chPartnerProspect';
    private static final String ACCOUNT_WO_ERP = 'Test Account without ERP';

    private static final String REST_BODY = '{\n' +
        '   "allOrNone" : false,\n' +
        '   "records" : [    {\n' +
        '      "attributes" : {"type" : "Account"},\n' +
        '      "id" : "0013F00000Mjw8yQAB",\n' +
        '      "Website" : "http://yahoo.com"\n' +
        '   },\n' +
        '    {\n' +
        '      "attributes" : {"type" : "Account"},\n' +
        '      "id" : "0013F00000IYkwkQAD",\n' +
        '      "Website" : "http://yoohoo.com"\n' +
        '   }]\n' +
        '}';

    public static final String RESTSUCCESSRESPONSE = '[\n' +
        '   {\n' +
        '      "id" : "' + ACCOUNTID1 + '",\n' +
        '      "success" : true,\n' +
        '      "errors" : [ ]\n' +
        '   },\n' +
        '   {\n' +
        '      "id" : "' + ACCOUNTID2 + '",\n' +
        '      "success" : true,\n' +
        '      "errors" : [ ]\n' +
        '   }\n' +
        ']';

    public static final String RESTERRORRESPONSE = '[\n' +
        '   {\n' +
        '      "id" : "' + ACCOUNTID1 + '",\n' +
        '      "success" : true,\n' +
        '      "errors" : [ ]\n' +
        '   },\n' +
        '   {\n' +
        '      "id" : "' + ACCOUNTID2 + '",\n' +
        '      "success" : false,\n' +
        '      "errors" : [ "that was bad" ]\n' +
        '   }\n' +
        ']';

    @TestSetup
    static void makeData(){
        Account objAccount = TestDataAccount.getAccount(ACCOUNT_1, 'USD');
        insert objAccount;
        
        Account objAccount2 = TestDataAccount.getAccount(ACCOUNT_2, 'USD');
        objAccount.ParentId = objAccount.id;
        
        Account customerAccount = TestDataAccount.getCustomerAccount();
        customerAccount.Name = CUSTOMER;

        Account indirectChannelPartnerAccount = TestDataAccount.getAccount(INDIRECT_CHANNEL, 'USD');
        indirectChannelPartnerAccount.RecordTypeId = AccountsService.INDIRECT_PARTNER_ID;

        Account illuminaAccount = TestDataAccount.getAccount(ILLUMINA, 'USD');
        illuminaAccount.RecordTypeId = AccountsService.ILLUMINA_INTERNAL_ID;

        Account chPartPros = TestDataAccount.getAccount(CHANNEL_PARTNER_PROSPECT, 'USD');
        chPartPros.RecordTypeId = AccountsService.CHANNEL_PARTNER_PROSPECT_ID;

        insert new List<Account> {objAccount2, customerAccount, indirectChannelPartnerAccount, illuminaAccount, chPartPros};

        //Create Contact
        Contact objContact = TestDataContact.initContact(objAccount);
        objContact.is_active__c = true;
        objContact.Email = 'test123@gmaill.com';
        
        //Create Non related Contact
        Contact objContact2 = TestDataContact.initContact(objAccount);
        objContact2.is_active__c = true;
        objContact.Email = 'test1a23@gmaill.com';

        insert new List<Contact>{objContact, objContact2};
    }

    @isTest
    static void generatedRestBody()
    {
        Map<Id, String> idToWebsite = new Map<Id, String>();
        idToWebsite.put(ACCOUNTID1, 'http://yahoo.com');
        idToWebsite.put(ACCOUNTID2, 'http://yoohoo.com');

        String restBody = Accounts.buildRestBody(idToWebsite);

        Assert.areEqual(REST_BODY, restBody, 'Generated body does not match!');
    }

    @isTest
    static void generatedRestRequest()
    {
        HttpRequest req = Accounts.buildRestRequest(REST_BODY);

        Assert.areEqual(REST_BODY, req.getBody(), 'Expected generated body does not match');
        Assert.areEqual('POST', req.getMethod(), 'It should be a POST!');
        Assert.areEqual('TRUE', req.getHeader('Sforce-Auto-Assign'), 'Sforce-Auto-Assign must be marked as true');
        Assert.isTrue(req.getEndpoint().contains('?_HttpMethod=PATCH'), 'Request missing PATCH call');
        Assert.isTrue(req.getEndpoint().contains('composite/sobjects'), 'Request is not to the path composite/sobjects');
    }

    @isTest
    static void successResponse()
    {
        TestAccountsMockEtmUpdate mockCallout = new TestAccountsMockEtmUpdate();
        HTTPResponse res = mockCallout.respond(null);

        Test.startTest();
        {
            Accounts.processRestResponse(res);
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT count() FROM Exception_Log__c LIMIT 10], 'Exception logs were found!');
    }

    @isTest
    static void errorResponse()
    {
        TestAccountsMockEtmUpdate mockCallout = new TestAccountsMockEtmUpdate();
        TestAccountsMockEtmUpdate.successResponse = false;
        HTTPResponse res = mockCallout.respond(null);

        Test.startTest();
        {
            Accounts.processRestResponse(res);
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // TODO: figure out why this is failing beyond DEVn1
        Assert.areEqual(1, [SELECT count() FROM Exception_Log__c LIMIT 10],'Exception log did not get created correctly');
    }

    @isTest
    static void updateWithoutCheckboxes()
    {
        TestAccountsMockEtmUpdate mockCallout = new TestAccountsMockEtmUpdate();
        mockCallout.respond(null);

        Account a = TestDataAccount.initAmrAccount();
        a.Website = 'http://www.scoobydoo.com';
        insert a;

        Test.startTest();
        {
            // this change will not trigger a callout
            Test.stopTest();
            a.Description = 'I made a change';
            update a;
        }

        // NOTE: can't make a callout so literally nothing to assert
    }

    @isTest
    static void updateWithCheckboxes()
    {
        TestAccountsMockEtmUpdate mockCallout = new TestAccountsMockEtmUpdate();
        mockCallout.respond(null);

        Account a = TestDataAccount.initAmrAccount();
        a.Website = 'http://www.scoobydoo.com';
        a.Exclude_from_rules_Even_Internal__c = true;
        a.Exclude_from_rules_Even_Channel_Partner__c = true;
        a.Exclude_from_rules_Internal__c = true;
        a.Exclude_from_rules_Channel_Partner__c = true;
        insert a;

        Test.startTest();
        {
            // this change will trigger a callout
            a.Description = 'I made a change';
            a.Exclude_from_rules_Even_Internal__c = false;
            a.Exclude_from_rules_Even_Channel_Partner__c = false;
            a.Exclude_from_rules_Internal__c = false;
            a.Exclude_from_rules_Channel_Partner__c = false;
            a.BillingStateCode = 'OH';
            update a;
        }
        Test.stopTest();

        // NOTE: can't make a callout so literally nothing to assert
    }
    
    //pm-33 : Added this method to check the acccount is inserted 
    @isTest
    static void testAccountInsert() {
        Test.startTest();
        List<Account> accList = [SELECT id,name FROM ACCOUNT LIMIT 10];
        Test.stopTest();
        Assert.isTrue(accList.size() > 0, 'Account is not inserted');
    }

    //CMCM-9577: test to check if market segment records are created when Market segment on account is not empty .
    @isTest
    static void testMarketSegmentOnAccountInsert() {
        Account customerAccount = TestDataAccount.getCustomerAccount();
        insert customerAccount;
        List<Market_Segment__c> msList = [SELECT Id FROM Market_Segment__c WHERE Account__c = :customerAccount.Id];
        Assert.areEqual(1, msList.size(), 'Market Segment record did not get created as expected.');
    }

    //CMCM-9577: test to check if market segment records are created when Market segment on account is empty.
    @isTest
    static void testMarketSegmentFromParentOnAccountInsert() {
        Account parentAccount = TestDataAccount.getCustomerAccount();
        insert parentAccount;
        List<Market_Segment__c> msList = [SELECT Id FROM Market_Segment__c WHERE Account__c = :parentAccount.Id];
        Assert.areEqual(1, msList.size(), 'Market Segment record did not get created as expected.');
        Account childAccount = TestDataAccount.getAccount(CHANNEL_PARTNER_PROSPECT, 'USD');
        childAccount.Clinical_Type__c = null;
        childAccount.Customer_Type__c = null;
        childAccount.Customer_Sub_Type__c = null;
        childAccount.Market_Segment__c = null;
        childAccount.ParentId = parentAccount.Id;
        insert childAccount;
        msList = [SELECT Id FROM Market_Segment__c WHERE Account__c = :childAccount.Id];
        Assert.areEqual(1, msList.size(), 'Market Segment record did not get created as expected.');
        List<Account> accts = [SELECT Id, Name, Clinical_Type__c, Population_Genomics__c, Customer_Type__c, Customer_Sub_Type__c, Market_Segment__c, Is_Updated_By_System__c FROM Account WHERE Id = :parentAccount.Id OR Id = :childAccount.Id];
        if (accts[0].Name == CHANNEL_PARTNER_PROSPECT) {
            parentAccount = accts[1];
            childAccount = accts[0];
        } else {
            parentAccount = accts[0];
            childAccount = accts[1];
        }
        Assert.areEqual(1, msList.size(), 'Market Segment record did not get created as expected.');
        Assert.areEqual(parentAccount.Clinical_Type__c, childAccount.Clinical_Type__c, 'Clinical Type did not get populated as expected.');
        Assert.areEqual(parentAccount.Customer_Type__c, childAccount.Customer_Type__c, 'Customer Type did not get populated as expected.');
        Assert.areEqual(parentAccount.Customer_Sub_Type__c, childAccount.Customer_Sub_Type__c, 'Customer Sub Type did not get populated as expected.');
        Assert.areEqual(parentAccount.Market_Segment__c, childAccount.Market_Segment__c, 'Market Segment did not get populated as expected.');   
        Assert.areEqual(parentAccount.Population_Genomics__c, childAccount.Population_Genomics__c, 'Population Genomics did not get populated as expected.');  
    }

    @isTest
    static void onBeforeUpdateERPPopulation() {
        Id prospectRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountProspect).getRecordTypeId();

        Account accountWithoutERP = TestDataAccount.getAccount(ACCOUNT_WO_ERP);
        accountWithoutERP.ERP_Customer_Id__c = '';
        accountWithoutERP.RecordTypeId = prospectRecordType;
        insert accountWithoutERP;

        accountWithoutERP = [SELECT id, name, ERP_Customer_Id__c, Account_Status__c, Address_Status__c FROM ACCOUNT WHERE id =: accountWithoutERP.Id];
        System.debug('accountWithoutERP:' + JSON.serializePretty(accountWithoutERP));

        Test.startTest();

        accountWithoutERP.ERP_Customer_Id__c = TestData.getRandomNumeric(10);
        update accountWithoutERP;

        Test.stopTest();

        Account res = [SELECT id, name, ERP_Customer_Id__c, Account_Status__c, Address_Status__c FROM ACCOUNT WHERE id =: accountWithoutERP.Id];

        Assert.areEqual(Label.Account_Account_Status_Active_Prospect, res.Account_Status__c, 'Account Status not set during ERP set');
        Assert.areEqual(Label.Account_Address_Status_Verified, res.Address_Status__c, 'Adress Status not set during ERP set');
    }

    //pm-33 : Added this method to check the acccount is updated 
     @isTest
    static void testUpdateAccount() {
        List<AccountContactRelation> listAccConRel = [SELECT AccountId, Product_Notifications_Categories__c, 
            Roles, IsActive, Account.R_Q_Contact_Compliant__c 
            FROM AccountContactRelation LIMIT 5
        ];
        List<AccountContactRelation> listAcrObj = new List<AccountContactRelation>();
        for(AccountContactRelation acrObj : listAccConRel) {
            acrObj.Product_Notifications_Categories__c = 'Default (All)';
            acrObj.Roles = 'Bioinformatics';
            listAcrObj.add(acrObj);
        }

        Set<id> accIds = new Set<id>();
        accIds.add(listAcrObj[0].AccountId);

        Test.startTest();
        update listAcrObj;
        Test.stopTest();
        Assert.areEqual('Default (All)', listAcrObj[0].Product_Notifications_Categories__c, 'Acr is not Updated');
    }

    @isTest
    private static void updateTierWhenParentIDIsAvailable() {
        String tier1 = 'Tier 1';
        Account parent = getAccountByName(ACCOUNT_1);
        parent.Tier__c = tier1;
        update parent;

        Account child = getAccountByName(ACCOUNT_2);
        Test.startTest();
        child.ParentId = parent.id;
        child.RecordTypeId = AccountsService.PROSPECT_ID;
        update child;
        Test.stopTest();

        child = getAccountByName(ACCOUNT_2);
        Assert.areEqual(parent.Tier__c, child.Tier__c, 'Child Account Tier value should match with Parent Tier');
    }

    // [Account].Contract_Order_Routing_Sheets__r . Child Relationship Name	Contract_Order_Routing_Sheets
    @IsTest
    private static void updateTAMandDSMvalues() {
        User newOwner = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id>{UserInfo.getUserId()});
        newOwner.ManagerId = UserInfo.getUserId();
        update newOwner;
        System.debug('newOwner:' + JSON.serializePretty(newOwner));

        Account account = getAccountByName(ACCOUNT_1);
        account.OwnerId = newOwner.id;

        Contract_Order_Routing_Sheet__c objCORS = new Contract_Order_Routing_Sheet__c();
        objCORS.Additional_Notes__c = 'test notes';
        objCORS.Rev_Rec_Code__c = 'ACD: Acceptance Upon Delivery';
        objCORS.Account__c = account.Id;
        objCORS.Contract_Review_Status__c = 'Open';
        insert objCORS;

        System.debug('objCORS:' + JSON.serializePretty(objCORS));

        Test.startTest();
        update account;
        System.debug('Account After Update:' + account);
        Test.stopTest();

        Contract_Order_Routing_Sheet__c res = [
            SELECT id, District_Sales_Manager__c, Territory_Account_Manager__c 
            FROM Contract_Order_Routing_Sheet__c 
            WHERE Account__c = :account.id];
        System.debug('CORS:' + JSON.serializePretty(res));
        Assert.areEqual(newOwner.ManagerId, res.District_Sales_Manager__c, 'CORS.District Manager should match with Account Owner Id');
        Assert.areEqual(account.OwnerId, res.Territory_Account_Manager__c, 'CORS.Territory_Account_Manager__c should match with current User Manager');
    }

    @IsTest
    private static void accountUpdateTierForChildProspects() {
        String tier1 = 'Tier 1';
        String child2Name = 'child2';
        String child3Name = 'child3';
        String child4Name = 'child4';
        Account parent = getAccountByName(ACCOUNT_1);

        Account child = getAccountByName(ACCOUNT_2);
        child.ParentId = parent.id;
        child.RecordTypeId = AccountsService.PROSPECT_ID;
        update child;

        Account child2 = TestDataAccount.getAccount(child2Name, 'USD');
        child2.ParentId = parent.id;
        child2.Tier__c = tier1;
        child2.RecordTypeId = AccountsService.PROSPECT_ID;

        Account child3 = TestDataAccount.getAccount(child3Name, 'USD');
        child3.ParentId = parent.id;
        child3.Tier__c = 'Tier 3';
        child3.RecordTypeId = AccountsService.PROSPECT_ID;

        Account child4 = TestDataAccount.getAccount(child4Name, 'USD');
        child4.ParentId = parent.id;
        child4.RecordTypeId = AccountsService.CUSTOMER_ID;

        insert new List<Account> {child2, child3, child4};

        Test.startTest();
        parent.Tier__c = tier1;
        update parent;
        Test.stopTest();

        parent = getAccountByName(ACCOUNT_1);
        child = getAccountByName(ACCOUNT_2);
        child2 = getAccountByName(child2Name);
        child3 = getAccountByName(child3Name);
        child4 = getAccountByName(child4Name);

        System.debug('result:' + JSON.serializePretty(new List<Account>{parent, child, child2, child3, child4}));

        Assert.areEqual(tier1, parent.Tier__c, 'Parent should be Tier1');
        Assert.areEqual(parent.Tier__c, child.Tier__c, 'child Account should have the same tier as parent');
        Assert.areEqual(parent.Tier__c, child2.Tier__c, 'child2 Account should have the same tier as parent');
        Assert.areEqual(parent.Tier__c, child3.Tier__c, 'child3 Account should have the same tier as parent');
        Assert.areNotEqual(parent.Tier__c, child4.Tier__c, 'child4 Account has different record type and should not match with parent\'s tier ');
    }

    @IsTest
    private static void updateSystemFlagToFalse() {
        Account account = getAccountByName(ACCOUNT_1);
        account.Is_Updated_By_System__c = true;

        Test.startTest();
        update account;
        Test.stopTest();

        account = getAccountByName(ACCOUNT_1);
        Assert.isFalse(account.Is_Updated_By_System__c, 'Is_Updated_By_System__c should be turn OFF');
    }

    @IsTest
    private static void updateSuspensionRejectionReason() {
        Account account = getAccountByName(ACCOUNT_1);
        account.Credit_Block__c = 'some reason';
        account.Order_Block__c = 'some reason';
        account.Delivery_Block__c = 'some reason';
        account.Billing_Issue__c = 'reason';
        account.Sales_Block__c = 'some reason';

        Test.startTest();
        update account;
        Test.stopTest();

        account = getAccountByName(ACCOUNT_1);
        System.debug(JSON.serializePretty(account));
        Assert.isTrue(String.isNotEmpty(account.Suspension_Rejection_Reason__c));
        Assert.isTrue(account.Suspension_Rejection_Reason__c.contains('Credit Block'));
        Assert.isTrue(account.Suspension_Rejection_Reason__c.contains('Order Block'));
        Assert.isTrue(account.Suspension_Rejection_Reason__c.contains('Delivery Block'));
        Assert.isTrue(account.Suspension_Rejection_Reason__c.contains('Billing Issue'));
        Assert.isTrue(account.Suspension_Rejection_Reason__c.contains('Sales Block'));
    }

    @IsTest
    private static void setStatusObsolete() {
        Account account = getAccountByName(ACCOUNT_1);
        account.Account_Group__c = Accounts.ACCOUNTGROUP_LEGACY;
        account.RecordTypeId = AccountsService.CUSTOMER_ID;

        Test.startTest();
        update account;
        Test.stopTest();

        account = getAccountByName(ACCOUNT_1);
        Assert.areEqual(Label.AccountStatusObsolete, account.Account_Status__c, 
            'Legacy accounts should be marked as Obsolete Status');
    }

    @IsTest
    private static void setStatusPendingObsolete() {
        Account account = getAccountByName(ACCOUNT_1);
        account.RecordTypeId = AccountsService.INDIRECT_PARTNER_ID;
        account.Mark_For_Deletion__c = true;

        Test.startTest();
        update account;
        Test.stopTest();

        account = getAccountByName(ACCOUNT_1);
        Assert.areEqual(Label.AccountStatusPendingObsolete, account.Account_Status__c, 'Account should be marked as "Pending Obsolete" status');
    }

    @IsTest
    private static void setStatusPendingUpgrade() {
        Account account = getAccountByName(ACCOUNT_1);
        account.Account_Status__c = Label.AccountStatusPendingUpgrade;
        Test.startTest();
        update account;
        Test.stopTest();

        account = getAccountByName(ACCOUNT_1);
        Assert.areEqual(Label.AccountStatusPendingUpgrade, account.Account_Status__c, 'Account should be marked as "Pending Upgrade" status');
    }


    @IsTest
    private static void suspendAccount() {
        Account account = getAccountByName(ACCOUNT_1); 
        Account customerAccount = getAccountByName(CUSTOMER);
        Account indirectChannelPartner = getAccountByName(INDIRECT_CHANNEL);
        Account illuminaAccount = getAccountByName(ILLUMINA);
        
        List<Account> accounts2Update = new List<Account> {account, customerAccount, indirectChannelPartner, illuminaAccount};
        System.debug('accounts before update:' + JSON.serializePretty(accounts2Update));

        Assert.areNotEqual('Suspended', account.Account_Status__c, 'Account should NOT be marked as Suspended'); // defaulted as Prospect Record Type
        Assert.areNotEqual('Suspended', customerAccount.Account_Status__c, 'Customer Account should NOT be marked as Suspended');
        Assert.areNotEqual('Suspended', indirectChannelPartner.Account_Status__c, 'Indirect Channel Account should NOT be marked as Suspended');
        Assert.areNotEqual('Suspended', illuminaAccount.Account_Status__c, 'Illumina Account should NOT be marked as Suspended');

        Test.startTest();
        account.RecordTypeId = AccountsService.INDIRECT_PARTNER_ID;
        account.Suspension_Rejection_Reason__c = 'suspend reason';
        account.Credit_Block__c = 'reason';

        customerAccount.Suspension_Rejection_Reason__c = 'suspend reason';
        customerAccount.Credit_Block__c = 'reason';

        indirectChannelPartner.Suspension_Rejection_Reason__c = 'suspend reason';
        indirectChannelPartner.Credit_Block__c = 'reason';

        illuminaAccount.Suspension_Rejection_Reason__c = 'suspend reason';
        illuminaAccount.Credit_Block__c = 'reason';

        update accounts2Update;
        Test.stopTest();

        account = getAccountByName(ACCOUNT_1);
        customerAccount = getAccountByName(CUSTOMER);
        indirectChannelPartner = getAccountByName(INDIRECT_CHANNEL);
        illuminaAccount = getAccountByName(ILLUMINA);
        System.debug('accounts:' + JSON.serializePretty(new List<Account> {account, customerAccount, indirectChannelPartner, illuminaAccount}));

        Assert.areEqual('Suspended', account.Account_Status__c, 'Account should be marked as Suspended');
        Assert.areEqual('Suspended', customerAccount.Account_Status__c, 'Customer Account should be marked as Suspended');
        Assert.areEqual('Suspended', indirectChannelPartner.Account_Status__c, 'Indirect Channel Account should be marked as Suspended');
        Assert.areEqual('Suspended', illuminaAccount.Account_Status__c, 'Illumina Account record type Account should be marked as Suspended');
    }

    @IsTest
    private static void activateAccount() {
        Account account = getAccountByName(ACCOUNT_1);
        // Accounts below does not have Suspension_Rejection_Reason__c hence are "Active"
        Account customerAccount = getAccountByName(CUSTOMER);
        Account indirectChannelPartnerAccount = getAccountByName(INDIRECT_CHANNEL);
        Account illuminaAccount = getAccountByName(ILLUMINA);
        System.debug('accounts:' + JSON.serializePretty(new List<Account>{account, customerAccount, indirectChannelPartnerAccount, illuminaAccount}));

        // Assert.areEqual('Unverified', account.Account_Status__c, 'Account should be marked as Unverified'); // Record type Prospect. default Account_Status__c "Unverified".
        Assert.areEqual('Active', customerAccount.Account_Status__c, 'Customer Account should be marked as Active');
        Assert.areEqual('Active', indirectChannelPartnerAccount.Account_Status__c, 'Indirect Channel Account should be marked as Active'); 
        Assert.areEqual('Active', illuminaAccount.Account_Status__c, 'Illumina Account record type Account should be marked as Active');
    }

    @IsTest
    private static void cancelProspectOnBlockandMarkForDeletion() {
        Account chPartnelProspectAccount = getAccountByName(CHANNEL_PARTNER_PROSPECT);
        Account prospectAccount = getAccountByName(ACCOUNT_1);

        Test.startTest();
        chPartnelProspectAccount.Mark_For_Deletion__c = true;
        chPartnelProspectAccount.Suspension_Rejection_Reason__c = 'reason';
        prospectAccount.Mark_For_Deletion__c = true;
        prospectAccount.Suspension_Rejection_Reason__c = 'reason';
        update new List<Account> {chPartnelProspectAccount, prospectAccount};
        Test.stopTest();

        chPartnelProspectAccount = getAccountByName(CHANNEL_PARTNER_PROSPECT);
        prospectAccount = getAccountByName(ACCOUNT_1);
        Assert.areEqual('Cancelled', chPartnelProspectAccount.Account_Status__c, 'channel partner prospect Account record type Account should be marked as Cancelled');
        Assert.areEqual('Cancelled', prospectAccount.Account_Status__c, 'prospect Account record type Account should be marked as Cancelled');
    }

    @IsTest
    private static void suspendProspectAccount() {
        Account prospectAccount = getAccountByName(ACCOUNT_1);
        Account chPartnelProspectAccount = getAccountByName(CHANNEL_PARTNER_PROSPECT);

        Test.startTest();
        prospectAccount.Credit_Block__c = 'reason';
        prospectAccount.Delivery_Block__c = 'reason';
        prospectAccount.Order_Block__c = 'reason';
        prospectAccount.Sales_Block__c = 'reason';
        prospectAccount.Billing_Issue__c = 'reason';

        chPartnelProspectAccount.Credit_Block__c = 'reason';
        chPartnelProspectAccount.Delivery_Block__c = 'reason';
        chPartnelProspectAccount.Order_Block__c = 'reason';
        chPartnelProspectAccount.Sales_Block__c = 'reason';
        chPartnelProspectAccount.Billing_Issue__c = 'reason';
        update new List<Account> {prospectAccount, chPartnelProspectAccount};
        Test.stopTest();

        chPartnelProspectAccount = getAccountByName(CHANNEL_PARTNER_PROSPECT);
        prospectAccount = getAccountByName(ACCOUNT_1);
        Assert.areEqual('Suspended', prospectAccount.Account_Status__c, 'prospect Account record type Account should be marked as Suspended');
        Assert.areEqual('Suspended', chPartnelProspectAccount.Account_Status__c, 'channel partner prospect Account record type Account should be marked as Suspended');
    }

    @IsTest
    private static void cancelProspect() {
        Account prospectAccount = getAccountByName(ACCOUNT_1);
        Account chPartnelProspectAccount = getAccountByName(CHANNEL_PARTNER_PROSPECT);

        Test.startTest();
        prospectAccount.Mark_For_Deletion__c = true;
        chPartnelProspectAccount.Mark_For_Deletion__c = true;

        update new List<Account> {prospectAccount, chPartnelProspectAccount};
        Test.stopTest();

        chPartnelProspectAccount = getAccountByName(CHANNEL_PARTNER_PROSPECT);
        prospectAccount = getAccountByName(ACCOUNT_1);
        Assert.areEqual('Cancelled', prospectAccount.Account_Status__c, 'prospect Account record type Account should be marked as Cancelled');
        Assert.areEqual('Cancelled', chPartnelProspectAccount.Account_Status__c, 'channel partner prospect Account record type Account should be marked as Cancelled');
    }

    @IsTest
    private static void updateActiveProspect() {
        Account prospectAccount = getAccountByName(ACCOUNT_1); // Status: Unverified
        Account chPartnelProspectAccount = getAccountByName(CHANNEL_PARTNER_PROSPECT); // Status: Unverified
        System.debug('before update accounts:' + JSON.serializePretty(new List<Account>{prospectAccount, chPartnelProspectAccount}));

        prospectAccount.Credit_Block__c = 'reason';
        prospectAccount.Delivery_Block__c = 'reason';
        prospectAccount.Order_Block__c = 'reason';
        prospectAccount.Sales_Block__c = 'reason';
        prospectAccount.Billing_Issue__c = 'reason';

        chPartnelProspectAccount.Credit_Block__c = 'reason';
        chPartnelProspectAccount.Delivery_Block__c = 'reason';
        chPartnelProspectAccount.Order_Block__c = 'reason';
        chPartnelProspectAccount.Sales_Block__c = 'reason';
        chPartnelProspectAccount.Billing_Issue__c = 'reason';

        update new List<Account> {prospectAccount, chPartnelProspectAccount};

        Test.startTest();
        prospectAccount.Mark_For_Deletion__c = false;
        prospectAccount.Credit_Block__c = '';
        prospectAccount.Delivery_Block__c = '';
        prospectAccount.Order_Block__c = '';
        prospectAccount.Sales_Block__c = '';
        prospectAccount.Billing_Issue__c = '';

        chPartnelProspectAccount.Mark_For_Deletion__c = false;
        chPartnelProspectAccount.Credit_Block__c = '';
        chPartnelProspectAccount.Delivery_Block__c = '';
        chPartnelProspectAccount.Order_Block__c = '';
        chPartnelProspectAccount.Sales_Block__c = '';
        chPartnelProspectAccount.Billing_Issue__c = '';

        update new List<Account> {prospectAccount, chPartnelProspectAccount};
        System.debug('prospectAccount.Credit_Block__c:' + prospectAccount.Credit_Block__c);
        System.debug('chPartnelProspectAccount.Credit_Block__c:' + chPartnelProspectAccount.Credit_Block__c);
        Test.stopTest();

        chPartnelProspectAccount = getAccountByName(CHANNEL_PARTNER_PROSPECT);
        prospectAccount = getAccountByName(ACCOUNT_1);
        System.debug('after update accounts:' + JSON.serializePretty(new List<Account>{prospectAccount, chPartnelProspectAccount}));
        Assert.areEqual('Active Prospect', prospectAccount.Account_Status__c, 'prospect Account record type Account should be marked as "Active Prospect"');
        Assert.areEqual('Active Prospect', chPartnelProspectAccount.Account_Status__c, 'channel partner prospect Account record type Account should be marked as "Active Prospect"');
    }

    //Test method for CMCM-9918
    @isTest
    private static void testStatusChangeonPartnerRequest() {
        User salesUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP, new Set<Id>());
        Profile salesUserProfile = [SELECT Id from PROFILE WHERE NAME = :TestDataUser.PROFILE_SALES_REP LIMIT 1][0];
        User adminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id>());
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'SL_Channel_Development_Manager' LIMIT 1][0].Id;
        System.runAs(adminUser) {
            insert new PermissionSetAssignment (
                AssigneeId = salesUser.Id, PermissionSetId = permissionSetId);
        }

        Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
        cp.SetupOwnerId = salesUserProfile.Id;
        cp.Is_Sales_Rep__c = True;
        insert cp;

        List<Partner_Request__c> lstPartnerRequest = TestDataPartnerPortal.getNewPartnerRequest(1);
        Partner_Request__c partnerRequest = new Partner_Request__c();
        Account prospectAccount = TestDataAccount.getAccount(ILLUMINA_PROSPECT, 'testStreet', 'testCity', '10101', 'CA',
                                        'US', '', '', '','', 'Tier 1', 'USD', 'Prospect');
        prospectAccount.RecordTypeId = AccountsService.PROSPECT_ID; 
        prospectAccount.Email_Channel_Partner__c = 'test@prospect.com';

        System.runAs(salesUser) {            
            insert lstPartnerRequest.get(0);
            partnerRequest = [SELECT Id, Status__c FROM Partner_Request__c LIMIT 1][0];
            prospectAccount.Partner_Request__c = partnerRequest.Id;
            Assert.areEqual('Pending', partnerRequest.Status__c, 'Status is not Pending.');
            insert prospectAccount;
        }

        partnerRequest = [SELECT Id, Status__c FROM Partner_Request__c WHERE Id = :lstPartnerRequest[0].Id LIMIT 1][0];
        Assert.areEqual('Accepted', partnerRequest.Status__c, 'Status is not Accepted.');        
    }

    private static Account getAccountByName(String name) {
        return [SELECT id, Name, Tier__c, RecordType.Name, Is_Updated_By_System__c, 
            Suspension_Rejection_Reason__c, Account_Status__c, Mark_For_Deletion__c,
            Credit_Block__c, Delivery_Block__c, Order_Block__c, Sales_Block__c, Billing_Issue__c
            FROM Account WHERE name = :name LIMIT 1
        ];
    }
    

}
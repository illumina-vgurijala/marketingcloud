/**
 *    @author Arquimidez Mora
 *    @date   30-10-2024
 *    @description Test Class for QuoteCreationAPIErrorHandler and QuoteCreationAPIEmailMessagingService classes
 *    Modification Log:
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *         Arquimidez Mora                 08 Nov 2024          Initial Version
 */
@isTest
public with sharing class TestQuoteCreationAPIErrorHandler {
    @TestSetup
    static void setupData(){
        Account objTestAccount = TestDataAccount.getCustomerAccount();
        objTestAccount.Territory_Region__c = 'AMEA';
        insert objTestAccount;

        Contact objContact = new Contact(FirstName = 'testContactName', LastName = 'testContactLastName' , AccountId = objTestAccount.Id, Email='test@illumi.com');
        insert objContact;

        cs_Apex_Settings__c apexSetting = cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
        apexSetting.EditWebGeneratedQuote__c = true;
        apexSetting.CreateWebGeneratedQuote__c = true;
        upsert apexSetting;
    }

    @isTest
    static void testLogErrors(){
        Account objAccount = [SELECT Id, Name, ERP_Customer_Id__c, Territory_Region__c FROM Account LIMIT 1];

        Map<String, Account> mapCustomerIds= new Map<String, Account>();
        List<QuoteCreationAPIOppCartWrapper> lstOppCreationWrapper= new List<QuoteCreationAPIOppCartWrapper>();
        QuoteCreationAPIOppCartWrapper wrapperTestNoErrors = new QuoteCreationAPIOppCartWrapper();
        QuoteCreationAPIOppCartWrapper wrapperTestNoErrors2 = new QuoteCreationAPIOppCartWrapper();
        QuoteCreationAPIOppCartWrapper wrapperTestErrors1 = new QuoteCreationAPIOppCartWrapper();
        QuoteCreationAPIOppCartWrapper wrapperTestErrors2 = new QuoteCreationAPIOppCartWrapper();
        mapCustomerIds.put(objAccount.ERP_Customer_Id__c, objAccount);

        wrapperTestNoErrors.objErrorHandler = new QuoteCreationAPIErrorHandler();
        lstOppCreationWrapper.add(wrapperTestNoErrors);

        wrapperTestNoErrors2.objErrorHandler = new QuoteCreationAPIErrorHandler();
        lstOppCreationWrapper.add(wrapperTestNoErrors2);

        wrapperTestErrors1.objErrorHandler = new QuoteCreationAPIErrorHandler();
        wrapperTestErrors1.objRequestWrapper = new QuoteCreationAPIRequestWrapper();
        wrapperTestErrors1.objErrorHandler.addError( '02 - ', 'Account is null');
        wrapperTestErrors1.objErrorHandler.addError( '04 - ', 'Contact is null');
        wrapperTestErrors1.objRequestWrapper.soldTo = objAccount.ERP_Customer_Id__c;
        wrapperTestErrors1.strJsonPayload='{"quoteLines" : [ {"EcomLineitemId" : "0","Quantity" : "0","MaterialNumber" : "0"}, {"EcomLineitemId" : "0","Quantity" : "0","MaterialNumber" : "0"} ],"RequestDate" : "","RequestType" : "MYCU","BillTo" : "","ShipTo" : "","EcomId" : "","DistributionChannel" : "01","Divison" : "","SalesOrg" : "US01","PrimaryContact" : "","QuoteCurrency" : "USD","UltimateConsignee" : "","SoldTo" : '+objAccount.ERP_Customer_Id__c+',"SourceSystem" : "MyIllumina"}';
        lstOppCreationWrapper.add(wrapperTestErrors1);

        wrapperTestErrors2.objErrorHandler = new QuoteCreationAPIErrorHandler();
        wrapperTestErrors2.objRequestWrapper = new QuoteCreationAPIRequestWrapper();
        wrapperTestErrors2.objErrorHandler.addError( '05 - ', 'Request Type is null');
        wrapperTestErrors2.objErrorHandler.addError( '04 - ', 'Contact is null');
        wrapperTestErrors2.objRequestWrapper.soldTo = objAccount.ERP_Customer_Id__c;
        wrapperTestErrors2.strJsonPayload='{"quoteLines" : [ {"EcomLineitemId" : "0","Quantity" : "0","MaterialNumber" : "0"}, {"EcomLineitemId" : "0","Quantity" : "0","MaterialNumber" : "0"} ],"RequestDate" : "","RequestType" : "MYCU","BillTo" : "","ShipTo" : "","EcomId" : "","DistributionChannel" : "01","Divison" : "","SalesOrg" : "US01","PrimaryContact" : "","QuoteCurrency" : "USD","UltimateConsignee" : "","SoldTo" : '+objAccount.ERP_Customer_Id__c+',"SourceSystem" : "MyIllumina"}';
        lstOppCreationWrapper.add(wrapperTestErrors2);

        test.startTest();
            List<QuoteCreationAPIOppCartWrapper> lstNumErrors = QuoteCreationAPIErrorHandler.insertInterfaceLog(lstOppCreationWrapper, 'Opportunity Creation');
            QuoteCreationAPIEmailMessagingService.handleErrorEmail(lstNumErrors, mapCustomerIds, 'Opportunity',null);
            Integer emailInvocations = Limits.getEmailInvocations();
        test.stopTest();

        Assert.areEqual(1, emailInvocations, '*** An error has ocurred when email is sending');
        Assert.areEqual(2, lstNumErrors.size(), '*** 2 errors needed to be logged');

    }

    @isTest
    static void testValidateEmailAddress(){
        String strValidEmail = 'test@gmail.com';
        String strInvalidEmail = '12estgmail.-dol';

        test.startTest();
            Boolean boolValidEmailTrue = new QuoteCreationAPIErrorHandler().validateEmailAddress(strValidEmail);
            Boolean boolInvalidtEmailFalse = new QuoteCreationAPIErrorHandler().validateEmailAddress(strInvalidEmail);
        test.stopTest();

        Assert.areEqual(true, boolValidEmailTrue, 'An error has ocurred invalid email');
        Assert.areEqual(false, boolInvalidtEmailFalse, 'An error has ocurred with the email');
    }

    @isTest
    static void testCreateOpportunity(){
        Account objAccount = [SELECT Id, Name, ERP_Customer_Id__c, Territory_Region__c, OwnerId FROM Account LIMIT 1];
        Contact objContact = [SELECT Id, FirstName, AccountId, Email FROM Contact WHERE AccountId = :objAccount.Id LIMIT 1];
        Map<String, Account> mapCustomerIds= new Map<String, Account>();
        Map<String, Contact> mapContacts = new Map<String, Contact>();
        mapCustomerIds.put(objAccount.ERP_Customer_Id__c, objAccount);
        mapContacts.put(objContact.Email, objContact);

        List<QuoteCreationAPIOppCartWrapper> lstOppCreationWrapper= new List<QuoteCreationAPIOppCartWrapper>();
        QuoteCreationAPIOppCartWrapper wrapperTest = new QuoteCreationAPIOppCartWrapper();
        wrapperTest.objErrorHandler = new QuoteCreationAPIErrorHandler();
        wrapperTest.objRequestWrapper = new QuoteCreationAPIRequestWrapper();
        wrapperTest.objRequestWrapper.sourceSystem = 'MyIllumina';
        wrapperTest.objRequestWrapper.soldTo = objAccount.ERP_Customer_Id__c;
        wrapperTest.objRequestWrapper.ultimateConsignee = objAccount.ERP_Customer_Id__c;
        wrapperTest.objRequestWrapper.quoteCurrency = 'EUR';
        wrapperTest.objRequestWrapper.primaryContact = objContact.Email;
        wrapperTest.objRequestWrapper.salesOrg = 'US01';
        wrapperTest.objRequestWrapper.divison = '00';
        wrapperTest.objRequestWrapper.distributionChannel = '01';
        wrapperTest.objRequestWrapper.ecomId = '1729259917';
        wrapperTest.objRequestWrapper.requestType = 'MYCC';
        wrapperTest.objRequestWrapper.requestDate = '20241117';
        wrapperTest.objRequestWrapper.soldTo = objAccount.ERP_Customer_Id__c;
        wrapperTest.strJsonPayload='{"quoteLines" : [ {"EcomLineitemId" : "0","Quantity" : "0","MaterialNumber" : "0"}, ],"RequestDate" : "20241117","RequestType" : "MYCC","BillTo" : "","ShipTo" : "","EcomId" : "1729259917","DistributionChannel" : "01","Divison" : "00","SalesOrg" : "US01","PrimaryContact" : '+ objContact.Email+',"QuoteCurrency" : "EUR","UltimateConsignee" : '+objAccount.ERP_Customer_Id__c+',"SoldTo" : '+objAccount.ERP_Customer_Id__c+',"SourceSystem" : "MyIllumina"}';
        lstOppCreationWrapper.add(wrapperTest);

        test.startTest();
            List<WebGeneratedQuoteOpportunityCreation.ProccesedData> lstOppCreated = QuoteCreationAPIOpportunityService.createOpportunity(lstOppCreationWrapper, mapCustomerIds, mapContacts);
        test.stopTest();

        List<Opportunity> testrecords = [SELECT 
                                        Id, Account.ERP_Customer_Id__c, 
                                        Ultimate_Consignee__r.ERP_Customer_Id__c, Type, 
                                        StageName, Opportunity_Forecast_Category__c, 
                                        CurrencyIsoCode, Primary_Contact__c, 
                                        Sales_Org_Override__c, 
                                        Sold_to_Distribution_Channel__c, 
                                        EcomId__c, Amount, RequestType__c  
                                        FROM Opportunity WHERE Type = 'Web Generated'
        ];

        Assert.areEqual(1, testrecords.size(), 'An error has ocurred opportunity was not created');
        Assert.areEqual(objAccount.ERP_Customer_Id__c, testrecords[0].Account.ERP_Customer_Id__c);
        Assert.areEqual(objAccount.ERP_Customer_Id__c, testrecords[0].Ultimate_Consignee__r.ERP_Customer_Id__c);
        Assert.areEqual('Web Generated', testrecords[0].Type);
        Assert.areEqual('Develop', testrecords[0].StageName);
        Assert.areEqual('Not Forecasted', testrecords[0].Opportunity_Forecast_Category__c);
        Assert.areEqual('EUR', testrecords[0].CurrencyIsoCode);
        Assert.areEqual(objContact.Id, testrecords[0].Primary_Contact__c);
        Assert.areEqual('US01', testrecords[0].Sales_Org_Override__c);
        Assert.areEqual('1729259917', testrecords[0].EcomId__c);
        Assert.areEqual(0, testrecords[0].Amount);
        Assert.areEqual('MYCC', testrecords[0].RequestType__c);
        Assert.areNotEqual(null, lstOppCreated[0].opportunity, 'An error has ocurred opportunity was not created');
    }
}
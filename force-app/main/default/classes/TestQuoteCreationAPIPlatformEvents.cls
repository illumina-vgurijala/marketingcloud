/**
*    @author Arquimidez Mora
*    @date   30-10-2024
*    @description Test QuoteCreationAPIPlatformEvents class
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*         Arquimidez Mora               30th Oct 2024          Initial Version
*/
@isTest
public with sharing class TestQuoteCreationAPIPlatformEvents {
    /**
     *  @author Arquimidez Mora   
     *  @description generate and create an Customer Account. 
     *  @param NA
     *  @return void
     **/
    @TestSetup
    static void setupData(){
        Account objTestAccount = TestDataAccount.getCustomerAccount();
        insert objTestAccount;
        
        Contact objContact = new Contact(FirstName = 'testContactName', LastName = 'testContactLastName' , AccountId = objTestAccount.Id, Email='test@illumi.com');
        insert objContact;

        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            EditWebGeneratedQuote__c = true, CreateWebGeneratedQuote__c = true
        );
        insert apexSettings;
        
        Account soldTo = TestDataAccount.getAccount('WGQACC1', 'USD');
        soldTo.ERP_Customer_Id__c = '4000066230';
        soldTo.BillingCountryCode = 'US';
        soldTo.BillingStateCode = 'AK';
        soldTo.Account_Group__c = 'Sold To';
        insert soldTo;
        
        Account_Sales_Area__c soldToSalesAreaDist1 = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        soldToSalesAreaDist1.Account__c = soldTo.Id;
        soldToSalesAreaDist1.Price_List_Type__c = '01';
        soldToSalesAreaDist1.CurrencyIsoCode = 'USD';
        soldToSalesAreaDist1.Price_List__c = '01-AMR-USD';
        soldToSalesAreaDist1.Contract_Number__c = '4000066230_US010100';
        soldToSalesAreaDist1.Company_Code__c = 'US01';
        insert soldToSalesAreaDist1;
        
        Customer_Master_Data__c cmd1 = new Customer_Master_Data__c(Name='4000066230_dist',ERP_Customer_Id__c = '4000066230', Account_Group__c= 'Distributor');
        insert cmd1;
    }

    /**
     *  @author   Arquimidez Mora
     *  @description Testing that Opportunity is created.
     *  @param NA
     *  @return void 
     **/
    @isTest
    static void testCreateOpportunity() {
        Account objAccount = [SELECT Id, Name, ERP_Customer_Id__c FROM Account WHERE ERP_Customer_Id__c != null LIMIT 1];
        Contact objContact = [SELECT Id, Email FROM Contact LIMIT 1];
        System.debug('***- Customer Id: ' + objAccount.ERP_Customer_Id__c);
        String strJSONPayload = '{"SourceSystem" :"MyIllumina","SoldTo":"4000066230", "UltimateConsignee":"4000066230", "QuoteCurrency" : "USD"'
            +',"PrimaryContact":"'+objContact.email+'","SalesOrg":"US01","Divison":"","DistributionChannel":"01","EcomId":"","ShipTo":"4000066230","BillTo":"4000066230","RequestType":""'
            +',"RequestDate":"","quoteLines":[{"MaterialNumber" : "15033418","Quantity" : 10,"EcomLineitemId":""}]}';    
        Boolean boolResult;
        
        List<RestOpportunityQuoteCreationValidator.MetadataWrapper> lstValidationFields = RestOpportunityQuoteCreationValidator.getValidationFields('MyIllumina');

        if(lstValidationFields == null){
            lstValidationFields = new List<RestOpportunityQuoteCreationValidator.MetadataWrapper>();

            RestOpportunityQuoteCreationValidator.MetadataWrapper objValidationFieldsLvl1 = new RestOpportunityQuoteCreationValidator.MetadataWrapper();
            objValidationFieldsLvl1.isRoot = true;
            objValidationFieldsLvl1.fields = 'SourceSystem,SoldToUltimateConsignee,QuoteCurrency,PrimaryContact,SalesOrg,DivisonDistributionChannel,EcomId,ShipTo,BillTo,RequestType,RequestDate,quoteLines';
            lstValidationFields.add(objValidationFieldsLvl1);
            
            RestOpportunityQuoteCreationValidator.MetadataWrapper objValidationFieldsLvl2 = new RestOpportunityQuoteCreationValidator.MetadataWrapper();
            objValidationFieldsLvl2.key = 'quoteLines';
            objValidationFieldsLvl2.isRoot = false;
            objValidationFieldsLvl2.fields = 'MaterialNumberQuantity,EcomLineitemId';
            lstValidationFields.add(objValidationFieldsLvl2);
        }

        RestOpportunityQuoteCreationValidator.fields2Validate = lstValidationFields;

        test.startTest();
            boolResult = CEQWebResquestPlatformEventService.createPlatformEvent(QuoteCreationAPIPESubscriberService.Step.STEP1_QUOTATION_CREATION, strJSONPayload);
        test.stopTest();

        List<Opportunity> lstOpportunityResult = [SELECT Id FROM Opportunity WHERE Type = 'Web Generated'];
        Assert.areEqual(true, boolResult, '*** The platform event couldn\'t get published');
        Assert.areEqual(1, lstOpportunityResult.size(), '*** The Opportunity was not created');
    }

    /**
     *  @author   Arquimidez Mora
     *  @description Testing that Opportunity is not created because of invalid data.
     *  @param NA   
     *  @return void 
     **/
    @isTest
    static void testOpportunityNotCreated() {
        String strJSONPayload = '{"quoteLines" : [ {"EcomLineitemId" : "0","Quantity" : "0","MaterialNumber" : "0"}, {"EcomLineitemId" : "0","Quantity" : "0","MaterialNumber" : "0"} ],"RequestDate" : "","RequestType" : "MYCU MYCS - Online quotes, customer care impersonation etc","BillTo" : "","ShipTo" : "","EcomId" : "","DistributionChannel" : "01","Divison" : "","SalesOrg" : "US01","PrimaryContact" : "","QuoteCurrency" : "USD","UltimateConsignee" : "","SoldTo" : "1122","SourceSystem" : "MyIllumina"}';    
        Boolean boolResult;

        test.startTest();
            boolResult = CEQWebResquestPlatformEventService.createPlatformEvent(QuoteCreationAPIPESubscriberService.Step.STEP1_QUOTATION_CREATION, strJSONPayload);
        test.stopTest();

        List<Opportunity> lstOpportunityResult = [SELECT Id FROM Opportunity WHERE Type = 'Web Generated'];
        Assert.areEqual(true, boolResult, '*** The platform event couldn\'t get published');
        Assert.areEqual(0, lstOpportunityResult.size(), '*** The Opportunity was created');
    }
}
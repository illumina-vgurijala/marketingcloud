/**
 *    @author Vinay  S Reddy
 *    @date   30-10-2024
 *    @description Test WebGeneratedQuoteOpportunityCreation class
 *    Modification Log:
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *         Vinay  S Reddy               30th Oct 2024          Initial Version
 *         Arquimidez Mora              30th Oct 2024         Added false scenario
 *         Gerardo Garcia               11th Nov 2024         CMCM-9913 add quotation and cart scenario
 *         Arquimidez Mora              25th Nov 2024         CMCM-9914 add cart line items scenario
 */
@isTest
private class TestWebGeneratedQuoteOpportunityCreation {
    
    /**
     *  @author Vinay  S Reddy
     *  @description generate and create an Customer Account.
     *  @param NA
     *  @return void
     **/
    @TestSetup
    static void setupData(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            EditWebGeneratedQuote__c = true, CreateWebGeneratedQuote__c = true
            );
        insert apexSettings;

        User usr = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'testGISUser',
                Email = 'userTestWeb@test.com',
                Username = 'userTestWeb@test.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
            );
        insert usr;
        
        Account soldTo = TestDataAccount.getAccount('WGQACC1', 'USD');
        soldTo.ERP_Customer_Id__c = '4000066230';
        soldTo.BillingCountryCode = 'US';
        soldTo.BillingStateCode = 'AK';
        soldTo.Account_Group__c = 'Sold To';
        
        Account distribuitor = TestDataAccount.getAccount('WGQACC2', 'USD');
        distribuitor.ERP_Customer_Id__c = '6000019679';
        distribuitor.BillingCountryCode = 'US';
        distribuitor.BillingStateCode = 'AK';
        distribuitor.Account_Group__c = 'Distributor';
        
        insert new List<Account> { soldTo, distribuitor };
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('01-AMR-USD');
        insert priceList;

        Contact con = TestDataPerson.initContact(soldTo.Id);
        Contact con2 = TestDataPerson.initContact(distribuitor.Id);
        insert new List<Contact> { con, con2 };
        
        Account_Sales_Area__c soldToSalesAreaDist1 = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        soldToSalesAreaDist1.Account__c = soldTo.Id;
        soldToSalesAreaDist1.Price_List_Type__c = '01';
        soldToSalesAreaDist1.CurrencyIsoCode = 'USD';
        soldToSalesAreaDist1.Price_List__c = '01-AMR-USD';
        soldToSalesAreaDist1.Contract_Number__c = '4000066230_US010100';
        soldToSalesAreaDist1.Company_Code__c = 'US01';

        Account_Sales_Area__c soldToSalesAreaDist2 = TestDataAccountSalesArea.getAccountSalesArea('US01','02','177','00',false);
        soldToSalesAreaDist2.Account__c = soldTo.Id;
        soldToSalesAreaDist2.Price_List_Type__c = '02';
        soldToSalesAreaDist2.CurrencyIsoCode = 'USD';
        soldToSalesAreaDist2.Price_List__c = '01-AMR-USD';
        soldToSalesAreaDist2.Contract_Number__c = '4000066230_US010100';
        soldToSalesAreaDist2.Company_Code__c = 'US01';
        
        Account_Sales_Area__c distSalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','179','00',false);
        distSalesArea.Account__c = distribuitor.Id;
        distSalesArea.Price_List_Type__c = '01';
        distSalesArea.CurrencyIsoCode = 'USD';
        distSalesArea.Price_List__c = '01-AMR-USD';
        distSalesArea.Contract_Number__c ='6000019679_US010100';
        distSalesArea.Company_Code__c = 'US01';
        
        insert new List<Account_Sales_Area__c>{soldToSalesAreaDist1, soldToSalesAreaDist2, distSalesArea};

        Customer_Master_Data__c cmd1 = new Customer_Master_Data__c(Name='4000066230_dist',ERP_Customer_Id__c = '4000066230', Account_Group__c= 'Distributor');
        Customer_Master_Data__c cmd2 = new Customer_Master_Data__c(Name='6000019679_dist',ERP_Customer_Id__c = '6000019679', Account_Group__c = 'Distributor');
        insert new List<Customer_Master_Data__c> {cmd1, cmd2};
    }
    
    /**
     *  @author Vinay  S Reddy 
     *  @descriptionTests Opportunity Creation
     *  @param NA
     *  @return void
     **/
    @isTest
    private static void testMethodWebQuotation(){
        List<String> lstJSONPayloads = new List<String>();
        
        List<Contact>  lstContacts = [SELECT Id, Email FROM Contact WHERE Account.ERP_Customer_Id__c IN ('4000066230', '6000019679')];
        Contact con = lstContacts[0];
        Contact con2 = lstContacts[1];
        
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
        
        Test.startTest();

        String direct = '{"SourceSystem" :"MyIllumina","SoldTo":"4000066230", "UltimateConsignee":"4000066230", "QuoteCurrency" : "USD"'
            +',"PrimaryContact":"'+con.email+'","SalesOrg":"US01","Divison":"","DistributionChannel":"01","EcomId":"","ShipTo":"4000066230","BillTo":"4000066230","RequestType":""'
            +',"RequestDate":"","quoteLines":[{"MaterialNumber" : "15033418","Quantity" : 10,"EcomLineitemId":""}]}';

        String indirect = '{"SourceSystem" :"MyIllumina","SoldTo":"6000019679", "UltimateConsignee":"4000066230", "QuoteCurrency" : "USD"'
        +',"PrimaryContact":"'+con2.email+'","SalesOrg":"US01","Divison":"","DistributionChannel":"02","EcomId":"","ShipTo":"4000066230","BillTo":"4000066230","RequestType":""'
        +',"RequestDate":"","quoteLines":[{"MaterialNumber" : "15033418","Quantity" : 10,"EcomLineitemId":""}]}';

        System.debug(JSON.serializePretty([SELECT Name, ERP_Customer_Id__c, BillingStateCode, BillingCountryCode FROM Account LIMIT 200]));
        System.debug(JSON.serializePretty([SELECT Name, Account__c, Price_List_Type__c, Price_List__c, 
            Contract_Number__c, Sales_Organization__c, Distribution_Channel__c, Division__c, Company_Code__c FROM Account_Sales_Area__c LIMIT 200])
        );

        WebGeneratedQuoteOpportunityCreation.handlePayload(new List<String>{direct, indirect});
        //Test.stopTest();
        
        List<Opportunity> opps = [SELECT Id, Name,
            Sales_Area_Sold_To__c, 
            Sales_Area_Ultimate_Consignee__c, 
            Sales_Area_Distributor__c, 
            Sales_Org_Override__c,
            CurrencyIsoCode,
            Price_List__c 
            FROM Opportunity WHERE Type = 'Web Generated' LIMIT 2];
        System.debug('opp record:' + JSON.serializePretty(opps));
        Assert.areEqual(2, opps.size(), 'Webgenerated Opportunity not created');
        Assert.isNotNull(opps[0].Price_List__c, 'Oppotunity should get a price list');
        Assert.isNotNull(opps[1].Price_List__c, 'Oppotunity should get a price list');
        
        List<String> quotationNames = new List<String> {opps[0].Name, opps[1].Name};
        List<Apttus_Proposal__Proposal__c> quotationRecords = [SELECT Id, 
            name, Apttus_Proposal__Proposal_Name__c, 
            Apttus_QPConfig__PriceListId__c,
            Apttus_QPConfig__ShipToAccountId__c,
            Apttus_QPConfig__BillToAccountId__c,
            Ship_To__c,
            Bill_To__c,
            Payer__c,
            Apttus_Proposal__ExpectedEndDate__c,
            Apttus_Proposal__Proposal_Approval_Date__c,
            Quote_Output_Generated_Valid_From_Date__c,
            Apttus_Proposal__Primary_Contact__c,
            MyIllumina_User_Email__c,
            Ultimate_Consignee__c,
            Prepared_by__c
        FROM Apttus_Proposal__Proposal__c
        WHERE Apttus_Proposal__Proposal_Name__c IN :quotationNames];
        Assert.areEqual(2, quotationRecords.size(), 'Webgenerated Quotations were not created' );

        List<String> quotationIds = new List<String> {quotationRecords[0].Id, quotationRecords[1].Id};
        List<Apttus_Config2__ProductConfiguration__c> carts = [SELECT id,Apttus_QPConfig__Proposald__c FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_QPConfig__Proposald__c IN :quotationIds];
        System.debug('carts:' + JSON.serializePretty(carts));
        
        List<String> listcartPayload = new List<String>();
        
        String directCartValidate = '{"SourceSystem" :"MyIllumina","SoldTo":"4000066230", "UltimateConsignee":"4000066230", "QuoteCurrency" : "USD"'
            +',"PrimaryContact":"'+con.email+'","SalesOrg":"US01","Divison":"","DistributionChannel":"01","EcomId":"","ShipTo":"4000066230","BillTo":"4000066230","RequestType":""'
            +',"RequestDate":"","quoteId":"'+carts[0].Apttus_QPConfig__Proposald__c+'","cartId":"'+carts[0].Id+'","quoteLines":[{"MaterialNumber" : "15033418","Quantity" : 10,"EcomLineitemId":""}]}';
        
        listcartPayload.add(directCartValidate);
        //WebGeneratedQuoteOpportunityCreation.handleCartValidate(listcartPayload);
        System.enqueueJob(new GenerateQueueDocument(listcartPayload,GenerateQueueDocument.QueueStep.STEP1_VALIDATE_CART), 1);
        
        
        //Test coverage of QuoteCreationAPIPlatformEvents
        List<Quote_Creation_API__e> testQuoteCreationAPISubscribeServive = new List<Quote_Creation_API__e>();
        Quote_Creation_API__e test1 = new Quote_Creation_API__e();
        test1.JSON_Payload__c  = direct;
        test1.Process_Type__c  = QuoteCreationAPIPESubscriberService.Step.STEP1_QUOTATION_CREATION.name();
        
        Quote_Creation_API__e test2 = new Quote_Creation_API__e();
        test2.JSON_Payload__c  = directCartValidate;
        test2.Process_Type__c  = QuoteCreationAPIPESubscriberService.Step.STEP3_VALIDATE_CART.name();
        
        testQuoteCreationAPISubscribeServive.add(test1);
        testQuoteCreationAPISubscribeServive.add(test2);
        
        QuoteCreationAPIPESubscriberService.requestHandler(testQuoteCreationAPISubscribeServive);
        
        QuoteCreationAPIRequestWrapper testPayload = new QuoteCreationAPIRequestWrapper();
        testPayload.sourceSystem = 'MyIllumina';
        testPayload.soldTo = '';
        testPayload.ultimateConsignee = '4000066230';
        testPayload.quoteCurrency='USD';
        testPayload.primaryContact=con.email;
        testPayload.salesOrg = 'US01';
        testPayload.divison = '';
        testPayload.distributionChannel ='01';
        testPayload.ecomId='';
        testPayload.shipTo='';
        testPayload.billTo='';
        testPayload.requestType='';
        testPayload.requestDate='';
        testPayload.quoteId=carts[0].Apttus_QPConfig__Proposald__c;
        testPayload.cartId = carts[0].Id;
        
        QuoteCreationAPIOppCartWrapper testingGenDoc = new QuoteCreationAPIOppCartWrapper();
        testingGenDoc.objRequestWrapper = testPayload;
        
        List<QuoteCreationAPIOppCartWrapper> testingGenerateDocument = new List<QuoteCreationAPIOppCartWrapper>();
        testingGenerateDocument.add(testingGenDoc);
        
        
        
        System.enqueueJob(new GenerateQueueDocument( testingGenerateDocument, GenerateQueueDocument.QueueStep.STEP6_GENDOC));
		system.debug('Test Wrapper '+testingGenerateDocument);

        Assert.areEqual(2, carts.size(), 'Webgenerated carts were not created' );
        Test.stopTest();
    }
    
    /**
     *  @author Vinay  S Reddy
     *  @description Test Opportunity not created
     *  @param NA
     *  @return void
     **/
    @isTest
    private static void testMethodOppNoCreated(){
        List<String> lstJSONPayloads = new List<String>();
        
        List<Contact>  lstContacts = [SELECT Id FROM Contact WHERE Account.ERP_Customer_Id__c IN ('4000066230', '6000019679')];
        Contact con = lstContacts[0];
        
        Test.startTest();
        String wgqDistChnl01 = '{"SourceSystem" :"Test_New_Oct_14","SoldTo" : "4000066230","UltimateConsignee":"6000019679","QuoteCurrency" : "USD"'
            +',"PrimaryContact":"'+con.id+'","SalesOrg":"CN03","Divison":"","DistributionChannel":"02","EcomId":"","ShipTo":"","BillTo":"","RequestType":""'
            +',"RequestDate":"","quoteLines":[{"MaterialNumber" : "","Quantity" : 10,"EcomLineitemId":""}]}';
        lstJSONPayloads.add(wgqDistChnl01);
        WebGeneratedQuoteOpportunityCreation.handlePayload(lstJSONPayloads);
        Test.stopTest();
        List<Opportunity> testrecords = [SELECT Id FROM Opportunity WHERE Type = 'Web Generated'];
        Assert.areEqual(0, testrecords.size(), 'Webgenerated Opportunity should not been created due invalid source' );
    }

    /**
     *  @author Arquimidez Mora 
     *  @description test line items are created
     *  @param NA
     *  @return void
     **/
    @isTest
    private static void testLineItemCreated(){
        Product2 objProd = TestDataMaster.getNewProduct('11111111', 'Instrument');

        User objGISUser = [SELECT Id FROM User WHERE LastName = 'testGISUser'];
        List<Contact>  lstContacts = [SELECT Id, Email FROM Contact WHERE Account.ERP_Customer_Id__c IN ('4000066230', '6000019679')];
        Contact con = lstContacts[0];
        Contact con2 = lstContacts[1];
        
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
        
        Test.startTest();
            String direct = '{"SourceSystem" :"MyIllumina","SoldTo":"4000066230", "UltimateConsignee":"4000066230", "QuoteCurrency" : "USD"'
            +',"PrimaryContact":"'+con.email+'","SalesOrg":"US01","Divison":"","DistributionChannel":"01","EcomId":"","ShipTo":"4000066230","BillTo":"4000066230","RequestType":""'
            +',"RequestDate":"","quoteLines":[{"MaterialNumber" : "'+ objProd.Material_Number__c +'","Quantity" : 1,"EcomLineitemId":""}]}';
        
            String indirect = '{"SourceSystem" :"MyIllumina","SoldTo":"6000019679", "UltimateConsignee":"4000066230", "QuoteCurrency" : "USD"'
            +',"PrimaryContact":"'+con2.email+'","SalesOrg":"US01","Divison":"","DistributionChannel":"02","EcomId":"","ShipTo":"4000066230","BillTo":"4000066230","RequestType":""'
            +',"RequestDate":"","quoteLines":[{"MaterialNumber" : "'+ objProd.Material_Number__c +'","Quantity" : 1,"EcomLineitemId":""}]}';

            WebGeneratedQuoteOpportunityCreation.handlePayload(new List<String>{direct, indirect});
        Test.stopTest();
        
        List<Opportunity> opps = [SELECT Id, Name,
        Sales_Area_Sold_To__c, 
        Sales_Area_Ultimate_Consignee__c, 
        Sales_Area_Distributor__c, 
        Sales_Org_Override__c,
        CurrencyIsoCode,
        Price_List__c 
        FROM Opportunity WHERE Type = 'Web Generated' LIMIT 2];
        System.debug('opp record:' + JSON.serializePretty(opps));
        Assert.areEqual(2, opps.size(), 'Webgenerated Opportunity not created');
        Assert.isNotNull(opps[0].Price_List__c, 'Oppotunity should get a price list');
        Assert.isNotNull(opps[1].Price_List__c, 'Oppotunity should get a price list');
        
        List<String> quotationNames = new List<String> {opps[0].Name, opps[1].Name};
        List<Apttus_Proposal__Proposal__c> quotationRecords = [SELECT Id, 
            name, Apttus_Proposal__Proposal_Name__c, 
            Apttus_QPConfig__PriceListId__c,
            Apttus_QPConfig__ShipToAccountId__c,
            Apttus_QPConfig__BillToAccountId__c,
            Ship_To__c,
            Bill_To__c,
            Payer__c,
            Apttus_Proposal__ExpectedEndDate__c,
            Apttus_Proposal__Proposal_Approval_Date__c,
            Quote_Output_Generated_Valid_From_Date__c,
            Apttus_Proposal__Primary_Contact__c,
            MyIllumina_User_Email__c,
            Ultimate_Consignee__c,
            Prepared_by__c
        FROM Apttus_Proposal__Proposal__c
        WHERE Apttus_Proposal__Proposal_Name__c IN :quotationNames];
        Assert.areEqual(2, quotationRecords.size(), 'Webgenerated Quotations were not created' );

        List<String> quotationIds = new List<String> {quotationRecords[0].Id, quotationRecords[1].Id};
        List<Apttus_Config2__ProductConfiguration__c> cartIds = [SELECT id FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_QPConfig__Proposald__c IN :quotationIds];
        List<Apttus_Config2__LineItem__c> lstLineItems = [SELECT Id, Apttus_Config2__ConfigurationId__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c IN: cartIds];
        System.debug('***- Line Items number: ' + lstLineItems.size());
        Assert.areEqual(2, lstLineItems.size(), 'Webgenerated Line Items were not created' );
    }

    /**
     *  @author Arquimidez Mora 
     *  @description test line items are not created
     *  @param NA
     *  @return void
     **/
    @isTest
    private static void testLineItemNotCreated(){

        User objGISUser = [SELECT Id FROM User WHERE LastName = 'testGISUser'];
        List<Contact>  lstContacts = [SELECT Id, Email FROM Contact WHERE Account.ERP_Customer_Id__c IN ('4000066230', '6000019679')];
        Contact con = lstContacts[0];
        Contact con2 = lstContacts[1];
        
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
        
        
        Test.startTest();
            String direct = '{"SourceSystem" :"MyIllumina","SoldTo":"4000066230", "UltimateConsignee":"4000066230", "QuoteCurrency" : "USD"'
                +',"PrimaryContact":"'+con.email+'","SalesOrg":"US01","Divison":"","DistributionChannel":"01","EcomId":"","ShipTo":"4000066230","BillTo":"4000066230","RequestType":""'
                +',"RequestDate":"","quoteLines":[{"MaterialNumber" : "11111111","Quantity" : 1,"EcomLineitemId":""}]}';
    
            String indirect = '{"SourceSystem" :"MyIllumina","SoldTo":"6000019679", "UltimateConsignee":"4000066230", "QuoteCurrency" : "USD"'
                +',"PrimaryContact":"'+con2.email+'","SalesOrg":"US01","Divison":"","DistributionChannel":"02","EcomId":"","ShipTo":"4000066230","BillTo":"4000066230","RequestType":""'
                +',"RequestDate":"","quoteLines":[{"MaterialNumber" : "11111111","Quantity" : 1,"EcomLineitemId":""}]}';
    
            WebGeneratedQuoteOpportunityCreation.handlePayload(new List<String>{direct, indirect});
        Test.stopTest();
        
        List<Opportunity> opps = [SELECT Id, Name,
                Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, 
                Sales_Area_Distributor__c, Sales_Org_Override__c,
                CurrencyIsoCode, Price_List__c 
			FROM Opportunity WHERE Type = 'Web Generated' LIMIT 2
		];
        
        List<String> quotationNames = new List<String> {opps[0].Name, opps[1].Name};
        List<Apttus_Proposal__Proposal__c> quotationRecords = [SELECT Id, 
                name, Apttus_Proposal__Proposal_Name__c, Apttus_QPConfig__PriceListId__c,
                Apttus_QPConfig__ShipToAccountId__c, Apttus_QPConfig__BillToAccountId__c,
                Ship_To__c, Bill_To__c,
                Payer__c, Apttus_Proposal__ExpectedEndDate__c,
                Apttus_Proposal__Proposal_Approval_Date__c,
                Quote_Output_Generated_Valid_From_Date__c,
                Apttus_Proposal__Primary_Contact__c, MyIllumina_User_Email__c, 
				Ultimate_Consignee__c, Prepared_by__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Apttus_Proposal__Proposal_Name__c IN :quotationNames
		];
        Assert.areEqual(2, quotationRecords.size(), 'Webgenerated Quotations were not created' );

        List<String> quotationIds = new List<String> {quotationRecords[0].Id, quotationRecords[1].Id};
        List<Apttus_Config2__ProductConfiguration__c> cartIds = [SELECT id FROM Apttus_Config2__ProductConfiguration__c WHERE Apttus_QPConfig__Proposald__c IN :quotationIds];
        List<Apttus_Config2__LineItem__c> lstLineItems = [SELECT Id, Apttus_Config2__ConfigurationId__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c IN: cartIds];
        Assert.areEqual(0, lstLineItems.size(), 'Webgenerated Line Items were not created' );
    }
}
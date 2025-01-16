/**
*  @author Saswati Prusty
*  @date   2019-06-04
*  @description   Add Product Flows
*  Modification Log:
*  ------------------------------------------------------------------------------------------------------------------------------------------------
*    Developer            Date           Description
*    Saswati Prusty       04-06-2019     DCP-25191: Moving the Flow logic to Controller for Add Products
*    Roopal Verma         19-03-2021     DCP-45967: Added method to cover quick quote controller
*    Rishab Wali          30-06-2021     DCP-45399: Add Products to Opp
*  ------------------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public with sharing class TestApttusAddProduct 
{
    public static final String STRUS01 = 'US01';
    public static final String STRDRAFT = 'draft';
    public static final String STRNONE = 'None';
    public static final String STRAPTTUSADDPRODUCTSPAGE = 'Page.ApttusAddProducts';
    public static final String STRAPTTUSCREATEQUICKQUOTE = 'Page.ApttusCreateQuickQuote';
    public static final String STROPPID = 'oppId';

    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.getAccount('Account 1');
        acc.BillingCountryCode = 'US';
        acc.BillingStateCode = 'AK';
        acc.ERP_Customer_Id__c = '345678';

        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.BillingCountryCode = 'US';
        acc2.BillingStateCode = 'AK';
        acc2.ERP_Customer_Id__c = '123456';
        Account acc3 = TestDataAccount.getAccount('Account 3');
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'AK';
        acc3.ERP_Customer_Id__c = '567890';
        acc3.Account_Group__c = 'Distributor';

        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc);
        lstAcc.add(acc2);
        lstAcc.add(acc3);
        insert lstAcc;

        Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRUS01,'01','177','00',false);
        accSalesArea.Account__c = acc.Id;
        accSalesArea.Price_List_Type__c='01';
        accSalesArea.CurrencyIsoCode = 'USD';
        accSalesArea.Price_List__c = '01-AMR-USD';
        accSalesArea.Contract_Number__c = '345678_US010100';
        accSalesArea.Company_Code__c = STRUS01;

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRUS01,'01','178','00',false);
        acc1SalesArea.Account__c = acc2.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        acc1SalesArea.Company_Code__c = 'GB01';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRUS01,'02','179','00',false);
        acc2SalesArea.Account__c = acc3.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Company_Code__c = STRUS01;
        insert new List<Account_Sales_Area__c>{accSalesArea,acc1SalesArea,acc2SalesArea};

        Contact con = TestDataPerson.getNewContact(acc.Id);
        con.email = 'axs@scs.com';

        System.debug('contss-'+con);

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Consortium__c consortium = TestDataConsortium.initConsortium('Open');
        consortium.Species__c = 'Consortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-Species';
        consortium.name = 'ConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortia';
        consortium.Beadchip_Part_Number__c = 'hdaghf';
        insert consortium;

        List<Opportunity> lstopp = new List<Opportunity>();
        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        System.debug('+++++++ Opp Type: '+opp.Type);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp);

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc,Label.OpportunityRTIndirectStandard);
        opp2.Price_List__c = priceList.Name;
        opp2.Consortium__c = consortium.Id;
        opp2.Type = 'Consortium';
        opp2.Product_Interest__c = 'Consumables';
        opp2.Direct_Sale_to_Ultimate_Consignee__c = true;
        lstopp.add(opp2);

        Opportunity opp3 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTIndirectStandard);
        opp3.Name = 'opp3';
        opp3.Ultimate_Consignee__c = acc2.Id;
        opp3.Distributor__c = acc3.Id;
        opp3.Direct_Sale_to_Ultimate_Consignee__c = true;
        opp3.Are_Products_Added_by_Channel_Partner__c = true;
        lstopp.add(opp3);

        Opportunity opp4 = TestDataOpportunity.initOpportunity(acc);
        opp4.Price_List__c = priceList.Name;
        opp4.Consortium__c = consortium.Id;
        opp4.Type = 'Consortium';
        opp4.Product_Interest__c = 'Consumables';
        opp4.Direct_Sale_to_Ultimate_Consignee__c = false;
        lstopp.add(opp4);

        Opportunity opp5 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTIndirectStandard);
        opp5.Name = 'opp5';
        opp5.Ultimate_Consignee__c = acc2.Id;
        opp5.Distributor__c = acc3.Id;
        opp5.Direct_Sale_to_Ultimate_Consignee__c = false;
        opp5.Are_Products_Added_by_Channel_Partner__c = true;
        lstopp.add(opp5);

        Opportunity opp6 = TestDataOpportunity.initOpportunity(acc,Label.OpportunityRTIndirectStandard);
        opp6.Price_List__c = priceList.Name;
        opp6.Consortium__c = consortium.Id;
        opp6.Type = 'Consortium';
        opp6.Product_Interest__c = 'Consumables';
        opp6.Direct_Sale_to_Ultimate_Consignee__c = false;
        lstopp.add(opp6);

        insert lstopp;

        List<Apttus_Proposal__Proposal__c> lstProp = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, STRDRAFT, STRNONE);
        proposal.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        proposal.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal.Invalid_Quote__c = false;
        // proposal.Promotion_JSON__c='[{"PromoCode":"NEWBEE","PromoChannel":null},{"PromoCode":"ICT-000021","PromoChannel":null},{"PromoCode":"ICT-000022","PromoChannel":null}]';
        System.debug('***1231**'+proposal.Direct_Sale_to_Ultimate_Consignee__c);
        lstProp.add(proposal);

        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test Proposal2', priceList.id, true, STRDRAFT, STRNONE);
        proposal2.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal2.Apttus_Proposal__Proposal_Name__c = 'Test Proposal2';
        proposal2.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal2.Invalid_Quote__c = false;
        // proposal2.Promotion_JSON__c='[{"PromoCode":"NEWBEE","PromoChannel":null},{"PromoCode":"ICT-000021","PromoChannel":null},{"PromoCode":"ICT-000022","PromoChannel":null}]';
        System.debug('***1232**'+proposal2.Direct_Sale_to_Ultimate_Consignee__c);
        lstProp.add(proposal2);

        Apttus_Proposal__Proposal__c proposal3 = TestDataProposal.initProposal(acc2.id, opp3.id, 'Test Proposal3', priceList.id, true, STRDRAFT, STRNONE);
        proposal3.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal3.Apttus_Proposal__Proposal_Name__c = 'Test Proposal3';
        proposal3.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal3.Invalid_Quote__c = false;
        lstProp.add(proposal3);

        Apttus_Proposal__Proposal__c proposal4 = TestDataProposal.initProposal(acc.id, opp4.id, 'Test Proposal4', priceList.id, true, STRDRAFT, STRNONE);
        proposal4.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal4.Apttus_Proposal__Proposal_Name__c = 'Test Proposal4';
        proposal4.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal4.Invalid_Quote__c = false;
        lstProp.add(proposal4);

        Apttus_Proposal__Proposal__c proposal5 = TestDataProposal.initProposal(acc2.id, opp5.id, 'Test Proposal5', priceList.id, true, STRDRAFT, STRNONE);
        proposal5.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal5.Apttus_Proposal__Proposal_Name__c = 'Test Proposal5';
        proposal5.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal5.Invalid_Quote__c = false;
        lstProp.add(proposal5);

        insert lstProp;
    }

    @isTest
    static void testAddProducts()
    {
        Set<Id> userProfileId = Profiles.getCommercialOpsQuotingUserProfileId();
        List<User> lstUsers = [
            SELECT Id, Name, IsActive
            FROM User
            WHERE ProfileId IN :userProfileId
            AND IsActive = true
            
            LIMIT 1
        ];
       
        List<Apttus_Proposal__Proposal__c> lstQuotes = [
            SELECT Id, Name, Apttus_QPConfig__PriceListId__c, Direct_Sale_to_Ultimate_Consignee__c, Invalid_Quote__c, Quote_Sub_Type__c,
                Apttus_Proposal__Proposal_Name__c, Apttus_Proposal__Opportunity__c
            FROM Apttus_Proposal__Proposal__c
            LIMIT 5
        ];

        // transfer all quotes and opportunities to user
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> allOps = new List<Opportunity>();
        for (Apttus_Proposal__Proposal__c objQuote : lstQuotes)
        {
            objQuote.OwnerId = lstUsers[0].Id;
            if (!oppIds.contains(objQuote.Apttus_Proposal__Opportunity__c))
            {
                oppIds.add(objQuote.Apttus_Proposal__Opportunity__c);
                allOps.add(new Opportunity(Id = objQuote.Apttus_Proposal__Opportunity__c, OwnerId = lstUsers[0].Id));
            }
        }
        update lstQuotes;
        update allOps;

        System.debug('-----lstQuotes--->' + lstQuotes);

        Test.setCurrentPageReference(new PageReference(STRAPTTUSADDPRODUCTSPAGE));
        System.currentPageReference().getParameters().put('Id', lstQuotes.get(0).Id);

        String url = '';

        Test.startTest();
          if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0])
            {
                ApttusAddProductsController objAddProducts = new ApttusAddProductsController();
                url += String.valueOf( ApttusAddProductsController.addProducts());
            }
          }

          for (Apttus_Proposal__Proposal__c objQuote : lstQuotes)
          {
              Test.setCurrentPageReference(new PageReference(STRAPTTUSADDPRODUCTSPAGE));
              System.currentPageReference().getParameters().put('Id', objQuote.Id);
              ApttusAddProductsController objAddProducts = new ApttusAddProductsController();
              url += String.valueOf( ApttusAddProductsController.addProducts());
          }

          Test.setCurrentPageReference(new PageReference(STRAPTTUSADDPRODUCTSPAGE));
          System.currentPageReference().getParameters().put('Id', lstQuotes.get(2).Id); 
          ApttusAddProductsController objAddProducts1 = new ApttusAddProductsController();
          if(!lstUsers.isEmpty()){
          	System.runAs (lstUsers[0]) 
        	  {
        	      url += String.valueOf(ApttusAddProductsController.addProducts());
       		  }
       	  }

          Test.setCurrentPageReference(new PageReference(STRAPTTUSADDPRODUCTSPAGE));
          System.currentPageReference().getParameters().put('Id', lstQuotes.get(4).Id); 
          ApttusAddProductsController objAddProducts2 = new ApttusAddProductsController();
          if(!lstUsers.isEmpty()){
            System.runAs (lstUsers[0]) 
            {
                url += String.valueOf( ApttusAddProductsController.addProducts());
            }
          }

          Test.setCurrentPageReference(new PageReference(STRAPTTUSADDPRODUCTSPAGE));
          System.currentPageReference().getParameters().put('Id', lstQuotes.get(1).Id); 
          ApttusAddProductsController objAddProducts3 = new ApttusAddProductsController();
          url += String.valueOf( ApttusAddProductsController.addProducts());

          Test.setCurrentPageReference(new PageReference(STRAPTTUSADDPRODUCTSPAGE));
          System.currentPageReference().getParameters().put('Id', lstQuotes.get(1).Id); 
          ApttusAddProductsController objAddProducts4 = new ApttusAddProductsController();
          if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0])
            {
                url += String.valueOf(ApttusAddProductsController.addProducts());
            }
          }

          System.assert(url.contains('RegionalSalesOpsNGDefault'), 'Flow - RegionalSalesOpsNGDefault did not get fired');
          System.assert(url.contains('NGDefault'),'Flow - NGDefault did not get fired');
          System.assert(url.contains('ConsortiaOppFlow'),'Flow - ConsortiaOppFlow did not get fired');
          System.assert(url.contains('IndirectUCFalseOppFlow'),'Flow - IndirectUCFalseOppFlow did not get fired');
          System.assert(url.contains('RegionalSalesOpsIndirectOppFlow'),'Flow - RegionalSalesOpsIndirectOppFlow did not get fired');
          System.assert(url.contains('RegionalSalesOpsIndirectUCFalseOppFlow'),'Flow - RegionalSalesOpsIndirectUCFalseOppFlow did not get fired');

        Test.stopTest(); 
    }

    /**
     * DCP-45967- Method to cover ApttusCreateQuickQuoteController
     */
    @isTest
    static void testRedirectToCartQuickQuote()
    {
        Set<Id> userProfileId = Profiles.getAdminProfileId();
        List<User> lstUsers = [
            SELECT Id, Name, IsActive
            FROM User
            WHERE ProfileId IN :userProfileId
            AND IsActive = true
            LIMIT 1
        ];

        List<Opportunity> lstOpportunities = [
            SELECT Id, Name, OwnerId, Direct_Sale_to_Ultimate_Consignee__c
            FROM Opportunity
            LIMIT 5
        ];

        for(Opportunity opp : lstOpportunities) {
            opp.OwnerId = lstUsers[0].Id;
        }
        update lstOpportunities;

        Test.setCurrentPageReference(new PageReference(STRAPTTUSCREATEQUICKQUOTE));
        System.currentPageReference().getParameters().put(STROPPID, lstOpportunities.get(0).Id);

        String url = '';

          if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0])
            {
                ApttusCreateQuickQuoteController objQuickQuote = new ApttusCreateQuickQuoteController();
                url += String.valueOf( ApttusCreateQuickQuoteController.redirectToCart());
            }
          }
          Test.startTest();
          Test.setCurrentPageReference(new PageReference(STRAPTTUSCREATEQUICKQUOTE));
          System.currentPageReference().getParameters().put(STROPPID, lstOpportunities.get(1).Id); 
          ApttusCreateQuickQuoteController objQuickQuote2 = new ApttusCreateQuickQuoteController();
          url += String.valueOf(ApttusCreateQuickQuoteController.redirectToCart());

          Test.setCurrentPageReference(new PageReference(STRAPTTUSCREATEQUICKQUOTE));
          System.currentPageReference().getParameters().put(STROPPID, lstOpportunities.get(2).Id); 
          ApttusCreateQuickQuoteController objQuickQuote4 = new ApttusCreateQuickQuoteController();
          url += String.valueOf(ApttusCreateQuickQuoteController.redirectToCart());
          if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0])
            {
                url += String.valueOf(ApttusCreateQuickQuoteController.redirectToCart());
            }
          }

          Test.setCurrentPageReference(new PageReference(STRAPTTUSCREATEQUICKQUOTE));
          System.currentPageReference().getParameters().put(STROPPID, lstOpportunities.get(3).Id);
          ApttusCreateQuickQuoteController objQuickQuote6 = new ApttusCreateQuickQuoteController();
          url += String.valueOf(ApttusCreateQuickQuoteController.redirectToCart());

           System.assert(url.contains('NGDefault'),'Flow - NGDefault did not get fired');
        Test.stopTest(); 
    }

    /*DCP-45399 Opp Line Items already created.*/
    @isTest
    static void testRedirectToCartQuickQuoteWithOLI()
    {
        Set<Id> userProfileId = Profiles.getAdminProfileId();
        List<User> lstUsers = [
            SELECT Id, Name, IsActive
            FROM User
            WHERE ProfileId IN :userProfileId
            AND IsActive = true
            LIMIT 1
        ];

        List<Opportunity> lstOpportunities = [
            SELECT Id, Name, OwnerId, Direct_Sale_to_Ultimate_Consignee__c
            FROM Opportunity
            LIMIT 5
        ];

        for(Opportunity opp : lstOpportunities) {
            opp.OwnerId = lstUsers[0].Id;
        }
        update lstOpportunities;
        Product2 objProduct = TestDataMaster.createProductOfTypeInstrument(true);
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
        Product2 objProduct2 = TestDataMaster.createProduct(true);
        PricebookEntry pbe2 = TestDataMaster.getNewStandardPrice(objProduct2.Id, 200);
        OpportunityLineItem oli1 = TestDataMaster.createOpportunityProduct(lstOpportunities[0].Id, pbe1.Id, false);
        insert oli1;
		Test.startTest();
        Boolean errorHandled = false;
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0])
            {
                String url = '';
                try{
                    Test.setCurrentPageReference(new PageReference(STRAPTTUSCREATEQUICKQUOTE));
                    System.currentPageReference().getParameters().put(STROPPID, lstOpportunities.get(0).Id);
                    ApttusCreateQuickQuoteController objQuickQuote = new ApttusCreateQuickQuoteController();
                    System.debug('Pbe Id + constructor ' + pbe2.Id + objQuickQuote);
                    url += String.valueOf( ApttusCreateQuickQuoteController.redirectToCart());
                }
                Catch(Exception e)
                {
                    errorHandled = true;
                }
            }
        }
        System.assert(!errorHandled,'Error on Quote Creation');
        Test.stopTest(); 
    }
    
    /*DCP-45399 Product Level Indicator check error scenario*/
    @isTest
    static void testRedirectToCartQuickQuoteErrorScenario()
    {
        Set<Id> userProfileId = Profiles.getAdminProfileId();
        List<User> lstUsers = [
            SELECT Id, Name, IsActive
            FROM User
            WHERE ProfileId IN :userProfileId
            AND IsActive = true
            LIMIT 1
        ];

        List<Opportunity> lstOpportunities = [
            SELECT Id, Name, OwnerId, Direct_Sale_to_Ultimate_Consignee__c
            FROM Opportunity
            LIMIT 5
        ];

        for(Opportunity opp : lstOpportunities) {
            opp.OwnerId = lstUsers[0].Id;
        }
        update lstOpportunities;
        Product2 objProduct = TestDataMaster.createProductOfTypeInstrument(true);
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
        Product2 objProduct2 = TestDataMaster.createProduct(true);
        objProduct2.ProductCode = '12341234';
        objProduct2.Product_Level_Indicator__c = 'COM_TEST';
        update objProduct2;
        PricebookEntry pbe2 = TestDataMaster.getNewStandardPrice(objProduct2.Id, 200);
        OpportunityLineItem oli1 = TestDataMaster.createOpportunityProduct(lstOpportunities[0].Id, pbe1.Id, false);
        OpportunityLineItem oli2 = TestDataMaster.createOpportunityProduct(lstOpportunities[0].Id, pbe1.Id, false);
        insert new List<OpportunityLineItem> {oli1,oli2};
		Test.startTest();
        Boolean errorHandled = false;
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0])
            {
                String url = '';
                try{
                    ApttusProposals.boolCheckPLIndicatorOnInsertFromTest = true;
                    Test.setCurrentPageReference(new PageReference(STRAPTTUSCREATEQUICKQUOTE));
                    System.currentPageReference().getParameters().put(STROPPID, lstOpportunities.get(0).Id);
                    ApttusCreateQuickQuoteController objQuickQuote = new ApttusCreateQuickQuoteController();
                    System.debug('Pbe2 Id + constructor ' + pbe2.Id + objQuickQuote);
                    url += String.valueOf( ApttusCreateQuickQuoteController.redirectToCart());
                }
                Catch(Exception e)
                {
                    errorHandled = true;
                }
            }
        }
        System.assert(!errorHandled,'Validation did not fire for Quote Creation');
        Test.stopTest(); 
    }
}
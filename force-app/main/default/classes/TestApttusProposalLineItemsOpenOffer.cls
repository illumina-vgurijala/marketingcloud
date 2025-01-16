/**
*    @author Nesar Mohan
*    @date   2022-06-02
*    @description    DCP-53938: Test class for ApttusProposalLineItemsHelper and ApttusProposalLineItemsQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*        Nesar Mohan                  2022-06-02           Initial Version
*       Akshay Hedaoo                 16-Aug-2024          CMCM-9780 : Quotation Line Item : Update Hide Contract Dates if PriceType is OneTime
*      Sai Pasumarthy                 17-Dec-2024          CMCM-11325 : TI- Quotation Line Item:Check for Product Specific Terms And Material Class
*   ---------------------------------------------------------------------------------------------------------------------------
**/

@isTest(isParallel=false)
public with sharing class TestApttusProposalLineItemsOpenOffer {
    
    public static final String PRICE_LIST = 'AMR-USD-US-01';
    public static final String TEST_PROPOSAL = 'Test Proposal';
    public static final String MATERIAL_GROUP_AIP = 'AIP';
    
    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    This method is used to setup the test data
    *  @PARAM :         none
    *  @RETURN:         void
    */
    @TestSetup
    static void setupData() {
        getSupportedData();      
    }
    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to create cartline items, update, validate and finalize the cart
    *  @PARAM :         none
    *  @RETURN:         void
    */
    @isTest
    static void testOpenOfferLogicQuoteOne() {
        List<Apttus_Proposal__Proposal__c> quote =  [SELECT Id FROM Apttus_Proposal__Proposal__c where Quote_Type__c like 'Direct%' LIMIT 3];
        List<Product2> products = getProducts();
        Id cartId1 = createCartAndLineItems(quote[0].Id,products);

        Test.startTest();

        updateCartLineItems(new set<Id>{cartId1},1);        
        
        validateCart(cartId1);
        finalizeCart(cartId1);

        Test.stopTest();

        Apttus_Proposal__Proposal__c objQuotationAfterUpdate = [SELECT Id, Open_Offer_Discount_Violation_Type__c, Quote_Has_Open_Offer_Product__c FROM Apttus_Proposal__Proposal__c where id=:quote[0].id];

        System.assert(objQuotationAfterUpdate.Quote_Has_Open_Offer_Product__c,'Incorrect data stamped');
        System.assert(objQuotationAfterUpdate.Open_Offer_Discount_Violation_Type__c!='','Violation Type populated');

    }
    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to create cartline items, update, validate and finalize the cart
    *  @PARAM :         none
    *  @RETURN:         void
    */
    @isTest
    static void testOpenOfferLogicQuoteTwo() {
        List<Apttus_Proposal__Proposal__c> quote =  [SELECT Id FROM Apttus_Proposal__Proposal__c where Quote_Type__c like 'Direct%' LIMIT 3];
        List<Product2> products = getProducts();

        Id cartId2 = createCartAndLineItems(quote[1].Id,products);

        Test.startTest();

        updateCartLineItems(new set<Id>{cartId2},2);

        validateCart(cartId2);
        finalizeCart(cartId2);

        Test.stopTest();

        Apttus_Proposal__Proposal__c objQuotationAfterUpdate = [SELECT Id, Open_Offer_Discount_Violation_Type__c, Quote_Has_Open_Offer_Product__c FROM Apttus_Proposal__Proposal__c where id=:quote[1].id];

        System.assert(objQuotationAfterUpdate.Quote_Has_Open_Offer_Product__c,'Incorrect data stamped');
        System.assert(objQuotationAfterUpdate.Open_Offer_Discount_Violation_Type__c!='','Violation Type populated');

    }
    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to create cartline items, update, validate and finalize the cart
    *  @PARAM :         none
    *  @RETURN:         void
    */
    @isTest
    static void testOpenOfferLogicQuoteThree() {
        List<Apttus_Proposal__Proposal__c> quote =  [SELECT Id ,Apttus_Proposal__Account__c, Ultimate_Consignee__c FROM Apttus_Proposal__Proposal__c where Quote_Type__c like 'Direct%' LIMIT 3];
        
        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.BillingCountryCode = 'US';
        objAccount.Territory_Region__c = 'AMR';
        objAccount.CurrencyIsoCode = 'USD';
        objAccount.Country_Local__c = 'USA';
        objAccount.Open_Offer_Comparison_Customer__c = true;
        objAccount.OwnerId = UserInfo.getUserId();
        objAccount.ERP_Customer_Id__c = '60292562728';
        objAccount.National_Group_Number__c = '60292562728';
        insert objAccount;

        quote[2].Ultimate_Consignee__c = objAccount.Id;  
        update quote[2];

        List<Product2> products = getProducts();

        Id cartId3 = createCartAndLineItems(quote[2].Id,products);

        Test.startTest();

        updateCartLineItems(new set<Id>{cartId3},3);

        validateCart(cartId3);
        finalizeCart(cartId3);

        Test.stopTest();

        Apttus_Proposal__Proposal__c objQuotationAfterUpdate = [SELECT Id, Open_Offer_Discount_Violation_Type__c, Quote_Has_Open_Offer_Product__c FROM Apttus_Proposal__Proposal__c where id=:quote[2].id];

        System.assert(objQuotationAfterUpdate.Quote_Has_Open_Offer_Product__c,'Incorrect data stamped');
        System.assert(objQuotationAfterUpdate.Open_Offer_Discount_Violation_Type__c!='','Violation Type populated');

    }

    @isTest
    static void testAsyncExecutionForPlatformEvent() {
        List<Apttus_Proposal__Proposal__c> quote =  [SELECT Id FROM Apttus_Proposal__Proposal__c where Quote_Type__c like 'Direct%' LIMIT 3];
        List<Product2> products = getProducts();

        Id cartId3 = createCartAndLineItems(quote[2].Id,products);

        Test.startTest();
        ApttusProposalLineItems.boolUseLargeCartProcessingMechanism = true;
        updateCartLineItems(new set<Id>{cartId3},3);

        validateCart(cartId3);
        finalizeCart(cartId3);

        Test.stopTest();

        Apttus_Proposal__Proposal__c objQuotationAfterUpdate = [SELECT Id, Open_Offer_Discount_Violation_Type__c, Quote_Has_Open_Offer_Product__c FROM Apttus_Proposal__Proposal__c where id=:quote[0].id];
        
        System.assert(objQuotationAfterUpdate.Open_Offer_Discount_Violation_Type__c!='','Violation Type populated');
        
        ApttusProposalLineItems.boolUseLargeCartProcessingMechanism = false;        

    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to validate cart
    *  @PARAM :         Id
    *  @RETURN:         void
    */

    static void validateCart(Id cartId) {
        Apttus_Config2.CPQWebService.validateCart(cartId);
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to finalize cart
    *  @PARAM :         Id
    *  @RETURN:         void
    */

    static void finalizeCart(Id cartId) {
        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        requestFinalize.CartId = cartId;
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to create cart and line items
    *  @PARAM :         Id, List<Product2>
    *  @RETURN:         Id
    */

    static Id createCartAndLineItems(Id quoteId, List<Product2> products) {
    
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = quoteId;
        Apttus_CPQApi.CPQ.CreateCartResponseDO objProductConfig = Apttus_CPQApi.CPQWebService.createCart(request);

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();

        for(Product2 objProduct : products) {
            Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
            selectProduct.ProductId = objProduct.Id;
            selectProduct.Quantity = 1;
            selectProduct.SellingTerm = 12;
            selectProduct.StartDate = Date.today();
            selectProduct.EndDate = Date.today() + 365;
            selectedProducts.add(selectProduct);
        }

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.CartId;
        addMultiProductRequest.SelectedProducts = selectedProducts;            
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
        
        return objProductConfig.CartId;
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to get supported data
    *  @PARAM :         None
    *  @RETURN:         Void
    */

    static void getSupportedData() {

        TestDataOpportunity.getStandardPriceBook();

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList(PRICE_LIST);
        insert priceList;

        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.BillingCountryCode = 'US';
        objAccount.Territory_Region__c = 'AMR';
        objAccount.CurrencyIsoCode = 'USD';
        objAccount.Country_Local__c = 'USA';
        objAccount.Open_Offer_Comparison_Customer__c = true;
        objAccount.OwnerId = UserInfo.getUserId();
        insert objAccount;

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        objOpportunity.RecordTypeName__c = 'Direct'; 
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = priceList.Name;
        objOpportunity.Type = System.Label.OpportunityTypeConsortium;
        insert objOpportunity;

        List<Apttus_Proposal__Proposal__c> lstInsertQuote = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(objAccount.Id, objOpportunity.Id, TEST_PROPOSAL, priceList.Id, true, Label.QuoteStageDraft, Label.QuoteApprovalStatusNone);
        quote1.Apttus_Proposal__Account__c = objAccount.Id;
        lstInsertQuote.add(quote1);

        Apttus_Proposal__Proposal__c quote2 = TestDataProposal.initProposal(objAccount.Id, objOpportunity.Id, TEST_PROPOSAL, priceList.Id, true, Label.QuoteStageDraft, Label.QuoteApprovalStatusNone);
        quote2.Apttus_Proposal__Account__c = objAccount.Id;
        lstInsertQuote.add(quote2);

        Apttus_Proposal__Proposal__c quote3 = TestDataProposal.initProposal(objAccount.Id, objOpportunity.Id, TEST_PROPOSAL, priceList.Id, true, Label.QuoteStageDraft, Label.QuoteApprovalStatusNone);
        quote3.Apttus_Proposal__Account__c = objAccount.Id;
        lstInsertQuote.add(quote3);

        insert lstInsertQuote;

        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.End_Of_Sale_Date__c = Date.today() + 15;
        objProduct.Product_Specific_Terms__c = 'Test Specific Term';
        objProduct.Material_Group_1_Code__c = MATERIAL_GROUP_AIP;
        objProduct.Open_Offer_Product__c = true;
        insert objProduct;

        TestDataProposal.initPriceListItem(objProduct, priceList);
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to get products
    *  @PARAM :         None
    *  @RETURN:         List<Product2>
    */
    private static List<Product2> getProducts() {
        Product2 objProduct1 = TestDataMaster.createProduct(false);
        objProduct1.Material_Group_1__c = null;
        objProduct1.Open_Offer_Product__c = true;
        objProduct1.Open_Offer_Product_Category__c ='NEXTSEQ 500/550/550DX/1000/2000';
        Product2 objProduct2 = TestDataMaster.createProduct(false);
        objProduct2.Material_Group_1__c = null;     
        objProduct2.Open_Offer_Product__c = false;
        objProduct2.Open_Offer_Product_Category__c ='';
        List<Product2> products = new List<Product2>{objProduct1,objProduct2};

        insert products;
        return products;
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to update the cart line item records
    *  @PARAM :         None
    *  @RETURN:         Id, Integer
    */
    private static void updateCartLineItems(Set<Id> cartId, Integer idx) {

        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id,Shipping_In_Close_Quarter__c,Apttus_Config2__ListPrice__c,Apttus_Config2__StartDate__c,Apttus_Config2__EndDate__c,Apttus_Config2__Quantity__c,Apttus_Config2__PriceType__c,Applied_Discount_Details__c,Applied_Discount_Amount__c,Applied_Discount_Percentage__c,Open_Offer_Max__c FROM Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c IN:cartId LIMIT 1];

        Apttus_Config2__LineItem__c lineitem = lineItemList.get(0);
        lineitem.Shipping_In_Close_Quarter__c = TestDataApprovals.INTEGER_SHIPPING_IN_CLOSE_QUARTER;
        lineitem.Apttus_Config2__ListPrice__c = 3000;
        lineitem.Apttus_Config2__StartDate__c = null;
        lineitem.Apttus_Config2__EndDate__c = null;
        lineitem.Apttus_Config2__Quantity__c = 6;
        lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;

        if (idx == 0) {                 
            lineitem.Applied_Discount_Percentage__c = 50;
            lineitem.Open_Offer_Max__c = 20;
        }            
        if (idx == 1) { 
            lineitem.Applied_Discount_Percentage__c = 50;
            lineitem.Open_Offer_Max__c = 10;
        }
        if (idx == 2) { 
            lineitem.Applied_Discount_Percentage__c = 50;
            lineitem.Open_Offer_Max__c = 60;
        } 

        update lineItemList; 
    }
    
     /* Created By : Akshay Hedaoo
     * Description : CMCM-9780 : Quotation Line Item : Update Hide Contract Dates if PriceType is OneTime
     * @Parameter lstProposalLineItems
     * @return null
     */ 
     @isTest
     static void testQuotationLineitem() {

         Product2 product = [SELECT Id FROM Product2 LIMIT 1];
         Apttus_Config2__PriceList__c priceList = [SELECT Id FROM Apttus_Config2__PriceList__c LIMIT 1];
         Apttus_Config2__PriceListItem__c priceListItem = NEW Apttus_Config2__PriceListItem__c();
             PriceListItem.Apttus_Config2__ProductId__c = Product.Id;
             PriceListItem.Apttus_Config2__ChargeType__c = 'Standard Type';
             PriceListItem.Apttus_Config2__PriceListId__c = PriceList.Id;
             PriceListItem.Apttus_Config2__PriceType__c = 'One Time';        
         insert priceListItem;

         Apttus_Proposal__Proposal__c proposalList = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
         Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 = new Apttus_Proposal__Proposal_Line_Item__c();
             proposalLineItem1.Apttus_Proposal__Proposal__c = proposalList.Id;
             proposalLineItem1.Apttus_QPConfig__PriceListItemId__c = PriceListItem.Id;
             proposalLineItem1.Apttus_QPConfig__PriceType__c = 'One Time';

         Test.startTest();
         INSERT proposalLineItem1;
         Test.stopTest();
         Apttus_Proposal__Proposal_Line_Item__c priceListItem2 = [SELECT Id, Hide_Contract_Dates__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Id =: proposalLineItem1.Id];
         system.assertEquals(true, priceListItem2.Hide_Contract_Dates__c);
     }

     /*
    @Author : Sai Pasumarthy
    @Story : CMCM-11325
    @Description : TI- Quotation Line Item:Check for Product Specific Terms And Material Class
    @Paramters : List of Line Item
    */
    @isTest
    static void testcheckProductSpecificTermsAndMaterialClass() {

        Test.startTest();
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Apttus_Config2__PriceList__c priceList = [SELECT Id FROM Apttus_Config2__PriceList__c LIMIT 1];
        Apttus_Config2__PriceListItem__c priceListItem = NEW Apttus_Config2__PriceListItem__c();
            PriceListItem.Apttus_Config2__ProductId__c = Product.Id;
            PriceListItem.Apttus_Config2__ChargeType__c = 'Standard Type';
            PriceListItem.Apttus_Config2__PriceListId__c = PriceList.Id;
            PriceListItem.Apttus_Config2__PriceType__c = 'One Time';        
        insert priceListItem;

        Apttus_Proposal__Proposal__c proposalList = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 = new Apttus_Proposal__Proposal_Line_Item__c();
            proposalLineItem1.Apttus_Proposal__Proposal__c = proposalList.Id;
            proposalLineItem1.Apttus_QPConfig__PriceListItemId__c = PriceListItem.Id;
            proposalLineItem1.Apttus_Proposal__Product__c = product.Id;
            proposalLineItem1.Apttus_QPConfig__PriceType__c = 'One Time';
            proposalLineItem1.Applied_Discount_Details__c = System.Label.QLIAppliedDiscDetailFixedPrice;        
        insert proposalLineItem1;        
        Apttus_Proposal__Proposal_Line_Item__c priceListItem2 = [SELECT Id, Template_China_Prod1__c,Template_Material_Class_Flag__c,Template_Promotions__c,Template_Applied_Disc_Details__c,Template_Infinium_Product__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Id =: proposalLineItem1.Id];
        Test.stopTest();
        Assert.areEqual(0,priceListItem2.Template_China_Prod1__c, 'Should be equal to 0');
        Assert.areEqual(0,priceListItem2.Template_Material_Class_Flag__c, 'Should be equal to 0');
        Assert.areEqual(0,priceListItem2.Template_Promotions__c, 'Should be equal to 0');
        Assert.areEqual(1,priceListItem2.Template_Applied_Disc_Details__c, 'Should be equal to 1');
        Assert.areEqual(0,priceListItem2.Template_Infinium_Product__c, 'Should be equal to 0');
    }
     /*
    @Author : Sai Pasumarthy
    @Story : CMCM-11325
    @Description : TI- Quotation Line Item:Check for Product Specific Terms And Material Class
    @Paramters : List of Line Item
    */
     @isTest
    static void testcheckProductSpecificTermsAndMaterialClass2() {
        
        Test.startTest();
        Apttus_Config2__Incentive__c incentive = TestDataProposal.initIncentives(TestDataApprovals.PROMOTION_NAME_BOGO, TestDataApprovals.PROMOTION_NAME_BOGO);

        Product2 objProduct = TestDataMaster.initProduct(System.Label.ProductChina1);
        objProduct.Material_Class__c = 'Instrument';
        objProduct.Material_Number__c = System.Label.ProductChina1;
        objProduct.Material_Type__c = System.Label.Material_Type_Infinium;
        objProduct.Material_Class_Type__c = System.Label.Material_Class_Type_Infinium;
        objProduct.Product_Level_Indicator__c = System.Label.Product_Level_Indicator;
        insert objProduct;
        
        Apttus_Config2__PriceList__c priceList = [SELECT Id FROM Apttus_Config2__PriceList__c LIMIT 1];
        Apttus_Config2__PriceListItem__c priceListItem = NEW Apttus_Config2__PriceListItem__c();
            PriceListItem.Apttus_Config2__ProductId__c = objProduct.Id;
            PriceListItem.Apttus_Config2__ChargeType__c = 'Standard Type';
            PriceListItem.Apttus_Config2__PriceListId__c = PriceList.Id;
            PriceListItem.Apttus_Config2__PriceType__c = 'One Time';        
        insert priceListItem;

        Apttus_Proposal__Proposal__c proposalList = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 = new Apttus_Proposal__Proposal_Line_Item__c();
            proposalLineItem1.Apttus_Proposal__Proposal__c = proposalList.Id;
            proposalLineItem1.Apttus_QPConfig__PriceListItemId__c = PriceListItem.Id;
            proposalLineItem1.Apttus_Proposal__Product__c = objProduct.Id;
            proposalLineItem1.Apttus_QPConfig__PriceType__c = 'One Time';
        	proposalLineItem1.Promotion_1__c = incentive.Id;        
        insert proposalLineItem1;        
        Apttus_Proposal__Proposal_Line_Item__c priceListItem2 = [SELECT Id, Template_China_Prod1__c,Template_Material_Class_Flag__c,Template_Promotions__c,Template_Applied_Disc_Details__c,Template_Infinium_Product__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Id =: proposalLineItem1.Id];
        Test.stopTest();
        Assert.areEqual(1,priceListItem2.Template_China_Prod1__c, 'Should be equal to 1');
        Assert.areEqual(1,priceListItem2.Template_Material_Class_Flag__c, 'Should be equal to 1');
        Assert.areEqual(1,priceListItem2.Template_Promotions__c, 'Should be equal to 1');
        Assert.areEqual(0,priceListItem2.Template_Applied_Disc_Details__c, 'Should be equal to 0');
        Assert.areEqual(1,priceListItem2.Template_Infinium_Product__c, 'Should be equal to 1');


    }
    
}
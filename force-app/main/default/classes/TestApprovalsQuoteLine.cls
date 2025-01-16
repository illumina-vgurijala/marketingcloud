/**
*    @author Todd Newman
*    @date   2021-08-19
*    @description    DCP-48131: Test class for overall approvals flow
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-08-19           Initial Version
*         Satya Swain                 2021-10-27           Codescan fixes
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest private class TestApprovalsQuoteLine {

    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;
    public static final String PRICE_LIST = 'AMR-USD-US-01';
    public static final String TEST_PROPOSAL = 'Test Proposal';
    public static final String BOGO_PROMO_SAVINGS = 'BOGO Promo Savings';
    public static final String SALES_DISCRETIONARY = 'Sales Discretionary';
    //public static final String MATERIAL_CLASS = 'Material Class';
    public static final String MATERIAL_GROUP_AIP = 'AIP';
     
    @testSetup
    static void setupData()
    {
        TestDataOpportunity.getStandardPriceBook();

        User accOwner = TestDataFieldService.createUser('Field Service', true);
		
        // TODO: create getNew method
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList(PRICE_LIST);
        insert priceList;

        Account soldTo = TestDataAccount.initAccount();
        soldTo.Territory_Region__c = 'AMR';
        soldTo.CurrencyIsoCode = 'USD';
        soldTo.Country_Local__c = 'USA';
        soldTo.Owner = accOwner;
        insert soldTo;
        System.debug('soldTo &&' + soldTo.Owner.Id);

        TestDataPerson.getNewContact(soldTo.Id);

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(soldTo);
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = priceList.Name;
        objOpportunity.Type = System.Label.OpportunityTypeConsortium;
        insert objOpportunity;

        Apttus_Proposal__Proposal__c quote = TestDataProposal.initProposal(soldTo.Id, objOpportunity.Id, TEST_PROPOSAL, priceList.Id, true, 'Draft', 'None');
        quote.Apttus_Proposal__Account__c = soldTo.Id;
        insert quote;
        System.debug('Apttus_Proposal__Account__c' + quote.Apttus_Proposal__Account__c + ' ' + quote.Apttus_Proposal__Account__r.OwnerId + '_' + quote.Apttus_Proposal__Account__c);

        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.End_Of_Sale_Date__c = Date.today() + 15; // Added for DCP-26583
        objProduct.Product_Specific_Terms__c = 'Test Specific Term'; // Added for 29812
        objProduct.Material_Group_1_Code__c = 'AIM';
        insert objProduct;

        TestDataProposal.initPriceListItem(objProduct, priceList);

        // Cart creation not needed here as cart is created via webservice in test method
        //TestDataProposal.getNewCart(quote);

        List<Approval_Hierarchy__c> lstApprovalHierarchy = new List<Approval_Hierarchy__c>();

        Approval_Hierarchy__c discountApprovalHierarchy = TestDataProposal.initApprovalHierarchy('CPQ_Sales_Hierarchy');
        discountApprovalHierarchy.Approver_Level_1__c = soldTo.Owner.Id;
        lstApprovalHierarchy.add(discountApprovalHierarchy);
        System.debug('discountApprovalHierarchy' + discountApprovalHierarchy);

        Approval_Hierarchy__c customApprovalHierarchy = TestDataProposal.initApprovalHierarchy('CPQ_Custom_Hierarchy');
        lstApprovalHierarchy.add(customApprovalHierarchy);

        lstApprovalHierarchy.add(TestDataProposal.initApprovalHierarchy('Post_Pricing_Message'));

        Approval_Hierarchy__c promotionApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('Promotion');
        lstApprovalHierarchy.add(promotionApprovalHeirarchy);

        insert lstApprovalHierarchy;

        Apttus_Config2__Incentive__c promotion = TestDataProposal.initIncentives('Test Incentive','Test Incentive Code');

        List<Apttus_Config2__ClassificationName__c> lstCategory = new List<Apttus_Config2__ClassificationName__c>();
        Apttus_Config2__ClassificationName__c objCategory = TestDataProposal.initCategory('Test Category');
        lstCategory.add(objCategory);
        insert lstCategory;

        /* Apttus_Config2__ClassificationHierarchy__c level1 = TestDataProposal.initHierarchy(objCategory, 'Level_1', null, null, 0);
        insert level1;
        Apttus_Config2__ClassificationHierarchy__c level2 = TestDataProposal.initHierarchy(objCategory, 'Level_2', level1, level1, 1);
        insert level2;
        Apttus_Config2__ClassificationHierarchy__c level3 = TestDataProposal.initHierarchy(objCategory, 'Level_3', level1, level2, 2);
        insert level3;
        Apttus_Config2__ClassificationHierarchy__c level4 = TestDataProposal.initHierarchy(objCategory, 'Level_4', level1, level3, 3);
        insert level4; */
        

        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();

        Custom_Approval_Matrix__c discountApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Discount', null, 20, 2000, null, '2', null, customApprovalHierarchy);
        discountApprovalMatrix.Distribution_Channel__c = null;
        lstMatrix.add(discountApprovalMatrix);

        Custom_Approval_Matrix__c promoApprovalMatrix = TestDataProposal.initApprovalMatrixForPromotion('Promotion', 'BOGO', '2', promotionApprovalHeirarchy);
        promoApprovalMatrix.Promotion__c = promotion.Id;
        lstMatrix.add(promoApprovalMatrix);

        lstMatrix.add(TestDataProposal.initApprovalPostPricingMatrix('Post Pricing Message', 'services'));
        lstMatrix.add(TestDataProposal.initApprovalPaymentTermMatrix('Payment Term', 'AMRQueue'));
        lstMatrix.add(TestDataProposal.initApprovalIncoTermMatrix('Inco Terms', 'AMR Incoterms Approval Queue', 'AMR')); //Added for DCP-28526
        lstMatrix.add(TestDataProposal.initApprovalIncoTermMatrix('Inco Terms', 'Incoterms Approval Queue', '')); // Added for DCP-28526

        Custom_Approval_Matrix__c matNumApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Material Number', null, 20, 20000, null, '2', null, customApprovalHierarchy);
        matNumApprovalMatrix.Distribution_Channel__c = null;
        lstMatrix.add(matNumApprovalMatrix);

        Custom_Approval_Matrix__c matGrpApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Material Group 1', null, 20, 20000, null, '2', null, customApprovalHierarchy);
        matGrpApprovalMatrix.Distribution_Channel__c = null;
        matGrpApprovalMatrix.Material_Group_1__c = MATERIAL_GROUP_AIP; 
        lstMatrix.add(matGrpApprovalMatrix);

        insert lstMatrix;
		
        // TODO: create getNew method
        //insert TestDataProposal.initProductClassification(level4, objProduct);
    }

    @isTest
    static void quoteLineMaterialNumber()
    {
        ApttusProposalLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesApprovalsPipeline', true);
		
        User objRepUser = TestDataUser.findUserInProfile('Sales User');

        Account acc = [SELECT Id, OwnerId FROM Account LIMIT 1];
        acc.OwnerId = objRepUser.Id;
        update acc;

        
        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();
        Approval_Hierarchy__c customApprovalHierarchy = [SELECT Id FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c = 'CPQ_Custom_Hierarchy'];
        Approval_Hierarchy__c objSalesApprovalHeirarchy = [SELECT Id FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c = 'CPQ_Sales_Hierarchy'];
        objSalesApprovalHeirarchy.Approver_Level_1__c = objRepUser.Id;
        update objSalesApprovalHeirarchy;

        
        Product2 objProduct = [SELECT Id, Name FROM Product2 LIMIT 1];
        objProduct.Material_Number__c = 'MaterialNo2';
        update objProduct;

        
        Product2 objProduct1 = TestDataMaster.createProduct(false);
        objProduct1.Material_Group_1__c = MATERIAL_GROUP_AIP;
        objProduct1.Material_Number__c = 'MaterialNo';
        insert objProduct1;

        //Test.startTest(); // start added early to stay under 100 DML

        Custom_Approval_Matrix__c matNumApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Material Number', null, 20, 20000, null, '2', null, customApprovalHierarchy);
        matNumApprovalMatrix.Distribution_Channel__c = null;
        lstMatrix.add(matNumApprovalMatrix);

        Custom_Approval_Matrix__c matGrpApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Material Group 1', null, 20, 20000, null, '2', null, customApprovalHierarchy);
        matGrpApprovalMatrix.Distribution_Channel__c = null;
        matGrpApprovalMatrix.Material_Group_1__c = MATERIAL_GROUP_AIP; 
        lstMatrix.add(matGrpApprovalMatrix);
        insert lstMatrix;

        List<Custom_Approval_Matrix_Products__c> matrixProducts = new List<Custom_Approval_Matrix_Products__c>();
        matrixProducts.add(new Custom_Approval_Matrix_Products__c(Custom_Approval_Matrix__c = matNumApprovalMatrix.Id, Product__c = objProduct.Id));
        matrixProducts.add(new Custom_Approval_Matrix_Products__c(Custom_Approval_Matrix__c = matNumApprovalMatrix.Id, Product__c = objProduct1.Id));
        
        insert matrixProducts;

        Apttus_Proposal__Proposal__c proposal = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];

        
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQ.CreateCartResponseDO objProductConfig = Apttus_CPQApi.CPQWebService.createCart(request);

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = objProduct.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct1 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct1.ProductId = objProduct1.Id;
        selectProduct1.Quantity = 1;
        selectProduct1.SellingTerm = 12;
        selectProduct1.StartDate = Date.today();
        selectProduct1.EndDate = Date.today() + 364;
        selectedProducts.add(selectProduct1);

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct2 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct2.ProductId = objProduct1.Id;
        selectProduct2.Quantity = 1;
        selectProduct2.SellingTerm = 12;
        selectProduct2.StartDate = Date.today();
        selectProduct2.EndDate = Date.today() + 364;
        selectedProducts.add(selectProduct2);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.CartId;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        //Apttus_CPQApi.CPQ.AddMultiProductResponseDO addMultiProductResponse = Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
       
		
        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c = :objProductConfig.CartId];

        for (Integer idx = 0; idx < lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if (idx == 0)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 3000;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__Quantity__c = 6;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Applied_Discount_Percentage__c = 5;
                lineitem.Applied_Discount_Amount__c = 3600;
                lineitem.Applied_Discount_Details__c = BOGO_PROMO_SAVINGS;
                lineitem.Promotion_Code__c = 'BOGO';
            }

            if (idx == 1)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 3000;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__Quantity__c = 6;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Applied_Discount_Percentage__c = 5;
                lineitem.Applied_Discount_Amount__c = 3600;
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
            }
            if (idx == 2)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 3000;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__Quantity__c = 6;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Applied_Discount_Percentage__c = 5;
                lineitem.Applied_Discount_Amount__c = 100;
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
            }   
        }
        update lineItemList;
        	
		
        System.assertNotEquals(0, lineItemList.size(), 'Line items created');
		
        Apttus_Config2.CPQWebService.validateCart(objProductConfig.CartId);

	       

        Test.startTest();
        // finalize the cart
        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        requestFinalize.CartId = objProductConfig.CartId;
       
        Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);
		
        
        List<Apttus_Proposal__Proposal_Line_Item__c> lstPLI = [SELECT Id, Approval_Category__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c = :proposal.Id];
        Test.stopTest();
        // System.assert(lstPLI.size() > 0, 'PLI not inserted');
        System.assertEquals(3, lstPLI.size(), 'PLI not inserted');
        System.debug('lstPLI &&' + lstPLI);
        
    }
}
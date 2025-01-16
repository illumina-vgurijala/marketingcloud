/**
*    @author Satya Swain
*    @date   2021-08-19
*    @description    DCP-48131: Test class for ApprovalQuoteLineMaterialNumber and ApprovalQuoteLineMaterialNumberCustom
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Satya Swain                 2021-08-19           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestApprovalsQuoteLineMaterialNumber {

    @TestSetup
    static void setupData() {
        TestDataApprovals.getSupportDataForApprovals();  
    }

    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method tests material number approvals for proposal line items
    */
    @isTest
    static void testMaterialNumberApprovals() {
        ApttusProposalLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesApprovalsPipeline', true);
        Account acc = [SELECT ID,Oncology_Lab_Manufacturer_Comparison__c,Clinical_Oncology_Screening_Dx_Testing__c,For_Profit_Company__c,BillingCountry FROM ACCOUNT LIMIT 1];
        acc.Clinical_Oncology_Screening_Dx_Testing__c = 'Yes';
        acc.For_Profit_Company__c = 'Yes';
        acc.BillingCountry = 'USA';
        update acc;
        // create quote and cart
        Apttus_Proposal__Proposal__c quote = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> products = getProducts();
        Id cartId = TestDataApprovals.createCartAndLineItems(quote.Id, products);
        // set one line to level 1 threshhold and one to under level 1
        updateCartLineItems(cartId);

        // add material to matrices to test hierarchy is found
        addMaterialNumbersToMatrices(products);

        Test.startTest();
        TestDataApprovals.validateCart(cartId);
        TestDataApprovals.finalizeCart(cartId);
        Test.stopTest();

        // query results
        Approval_Hierarchy__c salesHierarchy = [SELECT Id, Approver_Level_1__c, Approval_Hierarchy_Type__c FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c = :Approvals.CPQ_SALES LIMIT 1];
        Apttus_Proposal__Proposal__c quoteAfter = [SELECT Id, Sales_Discretionary_Approval_Error__c, Approval_Hierarchy_Record_Owner__c, Approval_Hierarchy_Transborder__c FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.debug('TTN quoteAfter ' + quoteAfter);
        List<Apttus_Proposal__Proposal_Line_Item__c> quoteLinesAfter = [SELECT Id, Approval_Category__c, Apttus_QPApprov__Approval_Status__c, Approval_Hierarchy_Record_Owner__c, Approval_Level_Record_Owner__c, Approval_Hierarchy_UC_Discount__c, Approval_Level_UC_Discount__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c = :quote.Id];
        for (Apttus_Proposal__Proposal_Line_Item__c quoteLine : quoteLinesAfter) { System.debug('TTN quoteLine ' + quoteLine); }

        System.assertEquals(Approvals.Category.CPQ_MATERIAL_NUMBER.name().toUpperCase()+';'+Approvals.Category.CPQ_MATERIAL_NUMBER_CUSTOM.name(), quoteLinesAfter.get(0).Approval_Category__c.toUpperCase(),'Incorrect category stamped');
        System.assertEquals(System.Label.ProposalApprovalStatusApprovalRequired, quoteLinesAfter.get(1).Apttus_QPApprov__Approval_Status__c,'Approval Status not updated to Approval Required');

        // hierarchies
        System.assertEquals(salesHierarchy.Id, quoteAfter.Approval_Hierarchy_Record_Owner__c,'Record Owner Not Stamped on Quotation');
        System.assertEquals(salesHierarchy.Id, quoteAfter.Approval_Hierarchy_Transborder__c,'Tranborder Record Owner Not Stamped on Quotation');
        System.assertEquals(salesHierarchy.Id, quoteLinesAfter.get(0).Approval_Hierarchy_Record_Owner__c,'Record Owner Not Stamped on Quotation Line Item');
        System.assertEquals(salesHierarchy.Id, quoteLinesAfter.get(1).Approval_Hierarchy_UC_Discount__c,'Tranborder Record Owner Not Stamped on Quotation Line Item');
        // levels
        System.assertEquals(1, quoteLinesAfter.get(0).Approval_Level_Record_Owner__c,'Incorrect Level Stamped on Quotation');
        System.assertEquals(1, quoteLinesAfter.get(1).Approval_Level_UC_Discount__c,'Incorrect Transborder level stamped on Quotation');

    }

    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method tests matrix and hierarchy absence for proposal line items
    */
    @isTest
    static void testHierarchyAndMatrixAbsence() {
        ApttusProposalLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesApprovalsPipeline', true);

        // create quote and cart
        Apttus_Proposal__Proposal__c quote = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> products = getProducts();
        Id cartId = TestDataApprovals.createCartAndLineItems(quote.Id, products);
        // set one line to level 1 threshhold and one to under level 1
        updateCartLineItems(cartId);

        // delete Approval Hierarchy and Matrix to test not-found error condition
        deleteMatricesAndHierarchies();

        Test.startTest();
        TestDataApprovals.validateCart(cartId);
        TestDataApprovals.finalizeCart(cartId);
        Test.stopTest();

        // query results
        Apttus_Proposal__Proposal__c quoteAfter = [SELECT Id, Sales_Discretionary_Approval_Error__c FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.debug('TTN quoteAfter ' + quoteAfter);
        List<Apttus_Proposal__Proposal_Line_Item__c> quoteLinesAfter = [SELECT Id, Approval_Category__c, Approval_Hierarchy_Record_Owner__c, Approval_Hierarchy_UC_Discount__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c = :quote.Id];
        for (Apttus_Proposal__Proposal_Line_Item__c quoteLine : quoteLinesAfter) { System.debug('TTN quoteLine ' + quoteLine); }

        //System.assertEquals(2, quoteLinesAfter.size(), 'Quote Lines not inserted');
        //System.assert(quoteAfter.Sales_Discretionary_Approval_Error__c.contains(Label.UI_Error_ApprovalHierarchyNotInPlace), 'Hierarchy error missing on quote header');
        System.assertEquals(null, quoteLinesAfter.get(0).Approval_Hierarchy_Record_Owner__c,'Hierarchy should not be stamped');
        System.assertEquals(null, quoteLinesAfter.get(1).Approval_Hierarchy_UC_Discount__c,'Transborder Hierarchy should not be stamped');
    }
    
    @isTest
    static void testMFN() {
        ApttusProposalLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesApprovalsPipeline', true);
        Account acc = [SELECT ID,Oncology_Lab_Manufacturer_Comparison__c,Clinical_Oncology_Screening_Dx_Testing__c,For_Profit_Company__c,BillingCountry FROM ACCOUNT LIMIT 1];
        acc.Clinical_Oncology_Screening_Dx_Testing__c = 'Yes';
        acc.For_Profit_Company__c = 'Yes';
        acc.BillingCountry = 'USA';
        update acc;
        // create quote and cart
        Apttus_Proposal__Proposal__c quote = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> products = getProducts();
        Id cartId = TestDataApprovals.createCartAndLineItems(quote.Id, products);
        // set one line to level 1 threshhold and one to under level 1
        updateCartLineItemsForMFN(cartId,products);

        // add material to matrices to test hierarchy is found
        addMaterialNumbersToMatrices(products);

        Test.startTest();
        TestDataApprovals.validateCart(cartId);
        TestDataApprovals.finalizeCart(cartId);
        System.assertEquals('USA',acc.BillingCountry,'Not Found!');
        Test.stopTest();
    }
    
    @isTest
    static void testMFNGermany() {
        ApttusProposalLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesApprovalsPipeline', true);
        Account acc = [SELECT ID,Oncology_Lab_Manufacturer_Comparison__c,Clinical_Oncology_Screening_Dx_Testing__c,For_Profit_Company__c,BillingCountry FROM ACCOUNT LIMIT 1];
        acc.Clinical_Oncology_Screening_Dx_Testing__c = 'Yes';
        acc.For_Profit_Company__c = 'Yes';
        acc.BillingCountry = 'Germany';
        update acc;
        // create quote and cart
        Apttus_Proposal__Proposal__c quote = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> products = getProducts();
        Id cartId = TestDataApprovals.createCartAndLineItems(quote.Id, products);
        // set one line to level 1 threshhold and one to under level 1
        updateCartLineItemsForMFN(cartId,products);

        // add material to matrices to test hierarchy is found
        addMaterialNumbersToMatrices(products);

        Test.startTest();
        TestDataApprovals.validateCart(cartId);
        TestDataApprovals.finalizeCart(cartId);
	System.assertEquals('Germany',acc.BillingCountry,'Not Found!');
        Test.stopTest();
    }
    
    private static List<Product2> getProducts()
    {
        Product2 objProduct1 = [SELECT Id FROM Product2 LIMIT 1];

        Product2 objProduct2 = TestDataMaster.createProduct(false);
        objProduct2.Material_Group_1__c = TestDataApprovals.MATERIAL_GROUP_AIP;
        objProduct2.ProductCode = '20028871';  
        insert objProduct2;
        
        Product2 objProduct3 = TestDataMaster.createProduct(false);
        objProduct3.Material_Group_1__c = TestDataApprovals.MATERIAL_GROUP_AIP;
        objProduct3.ProductCode = '20028318';        
        insert objProduct3;
        
        Product2 objProduct4 = TestDataMaster.createProduct(false);
        objProduct4.Material_Group_1__c = TestDataApprovals.MATERIAL_GROUP_AIP; 
        objProduct3.ProductCode = '20024913';       
        insert objProduct4;
        
        return new List<Product2>{objProduct1, objProduct2,objProduct3,objProduct4};
    }

    private static void updateCartLineItems(Id cartId)
    {
        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id FROM Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :cartId LIMIT 2 ];

        for (Integer idx = 0; idx < lineItemList.size(); idx++) {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);

            lineitem.Shipping_In_Close_Quarter__c = TestDataApprovals.INTEGER_SHIPPING_IN_CLOSE_QUARTER;
            lineitem.Apttus_Config2__ListPrice__c = 3000;
            lineitem.Apttus_Config2__StartDate__c = null;
            lineitem.Apttus_Config2__EndDate__c = null;
            lineitem.Apttus_Config2__Quantity__c = 6;
            lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
            lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;

            if (idx == 0) {
                lineitem.Applied_Discount_Percentage__c = 5;
                lineitem.Applied_Discount_Amount__c = 3600;
            }            
            if (idx == 1) {
                lineitem.Applied_Discount_Percentage__c = 1; // to test discount under level 1 concept
                lineitem.Applied_Discount_Amount__c = 50; // to test discount under level 1 concept
                
            }   
        }
        update lineItemList;
        
        
    }
    
    private static void updateCartLineItemsForMFN(Id cartId,List<Product2> products)
    {
        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [SELECT Id FROM Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :cartId LIMIT 10 ];

        for (Integer idx = 0; idx < lineItemList.size(); idx++) {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);

            lineitem.Shipping_In_Close_Quarter__c = TestDataApprovals.INTEGER_SHIPPING_IN_CLOSE_QUARTER;
            lineitem.Apttus_Config2__ListPrice__c = 3000;
            lineitem.Apttus_Config2__StartDate__c = null;
            lineitem.Apttus_Config2__EndDate__c = null;
            lineitem.Apttus_Config2__Quantity__c = 6;
            lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
            lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
            lineitem.Sales_Discretionary_Type__c = '% Discount';
            lineitem.Sales_Discretionary_Discount__c = 70;
            lineitem.Apttus_Config2__ProductId__c = products[1].ID;

            if (idx == 0) {
                lineitem.Applied_Discount_Percentage__c = 5;
                lineitem.Applied_Discount_Amount__c = 3600;
                lineitem.Sales_Discretionary_Type__c = '% Discount';
                lineitem.Sales_Discretionary_Discount__c = 70;
                lineitem.Apttus_Config2__ProductId__c = products[2].ID;
            }            
            if (idx == 1) {
                lineitem.Applied_Discount_Percentage__c = 1; // to test discount under level 1 concept
                lineitem.Applied_Discount_Amount__c = 50; // to test discount under level 1 concept
                lineitem.Sales_Discretionary_Type__c = '% Discount';
                lineitem.Sales_Discretionary_Discount__c = 70;
                lineitem.Apttus_Config2__ProductId__c = products[3].ID;
            }   
        }
        update lineItemList;
        
        
    }

    private static void addMaterialNumbersToMatrices(List<Product2> products)
    {
        Id recordTypeId = TestDataApprovals.getMatrixNameToRecordType().get(TestDataApprovals.RECORD_TYPE_CPQ_MATERIAL_NUMBER).getRecordTypeId();
        List<Custom_Approval_Matrix__c> matNumApprovalMatrices = [SELECT Id FROM Custom_Approval_Matrix__c WHERE RecordTypeId = :recordTypeId];
        List<Custom_Approval_Matrix_Products__c> matrixProducts = new List<Custom_Approval_Matrix_Products__c>();

        for (Custom_Approval_Matrix__c matrix : matNumApprovalMatrices) {
            matrixProducts.add(new Custom_Approval_Matrix_Products__c(Custom_Approval_Matrix__c = matrix.Id, Product__c = products.get(0).Id));
            matrixProducts.add(new Custom_Approval_Matrix_Products__c(Custom_Approval_Matrix__c = matrix.Id, Product__c = products.get(1).Id));
        }

        insert matrixProducts;
    }

    private static void deleteMatricesAndHierarchies()
    {
        List<Approval_Hierarchy__c> allCPQHierarchies = [SELECT Id FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c LIKE '%CPQ%'];
        Id recordTypeId = TestDataApprovals.getMatrixNameToRecordType().get(TestDataApprovals.RECORD_TYPE_CPQ_MATERIAL_NUMBER).getRecordTypeId();
        List<Custom_Approval_Matrix__c> matNumApprovalMatrices = [SELECT Id FROM Custom_Approval_Matrix__c WHERE RecordTypeId = :recordTypeId];

        delete allCPQHierarchies;
        delete matNumApprovalMatrices;
    }
}
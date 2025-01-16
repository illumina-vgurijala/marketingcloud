/**
*    @author Satya Swain
*    @date   2021-08-19
*    @description    DCP-48131: Test class for ApprovalQuoteLineDiscount and TestApprovalQuoteLineDiscountCustom
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Satya Swain                 2021-08-19           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestApprovalsQuoteLineDiscount {
    @TestSetup
    static void setupData() {
        TestDataApprovals.getSupportDataForApprovals();      
    }
    /*
    *  @AUTHOR:         Satya Swain
    *  @DESCRIPTION:    This method tests discount approvals for proposal line items
    *  @PARAM :         none
    *  @RETURN:         void
    */
    @isTest
    static void testDiscountApprovals() {
        ApttusProposalLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesApprovalsPipeline', true);

        Apttus_Proposal__Proposal__c quote =  [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];

        List<Product2> products = getProducts();
 
        Id cartId = TestDataApprovals.createCartAndLineItems(quote.Id, products);

        updateCartLineItems(cartId);      

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

        System.assertEquals(Approvals.Category.CPQ_DISCOUNT.name()+';'+Approvals.Category.CPQ_DISCOUNT_CUSTOM.name(), quoteLinesAfter.get(0).Approval_Category__c.toUpperCase(),'Incorrect category stamped');
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
    *  @PARAM :         none
    *  @RETURN:         void
    */
    @isTest
    static void testHierarchyAndMatrixAbsence() {
        ApttusProposalLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesApprovalsPipeline', true);

        Apttus_Proposal__Proposal__c quote =  [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];

        List<Product2> products = getProducts();

        Id cartId = TestDataApprovals.createCartAndLineItems(quote.Id, products);

        updateCartLineItems(cartId);

        // Delete Approval Hierarchy and Matrix for testing
        deleteMatricesAndHierarchies();

        Test.startTest();

        TestDataApprovals.validateCart(cartId);
        TestDataApprovals.finalizeCart(cartId);
        
        Test.stopTest();

        // query results
        Apttus_Proposal__Proposal__c quoteAfter = [SELECT Id, Sales_Discretionary_Approval_Error__c FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.debug('TTN quoteAfter ' + quoteAfter);
        List<Apttus_Proposal__Proposal_Line_Item__c> quoteLinesAfter = [SELECT Id, Approval_Category__c, Approval_Hierarchy_Record_Owner__c, Approval_Hierarchy_UC_Discount__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c = :quote.Id];

        System.assertEquals(2, quoteLinesAfter.size(), 'Quote Lines not inserted');
        System.assert(quoteAfter.Sales_Discretionary_Approval_Error__c.contains(Label.UI_Error_ApprovalHierarchyNotInPlace), 'Hierarchy error missing on quote header');
        System.assertEquals(null, quoteLinesAfter.get(0).Approval_Hierarchy_Record_Owner__c,'Hierarchy should not be stamped');
        System.assertEquals(null, quoteLinesAfter.get(1).Approval_Hierarchy_UC_Discount__c,'Transborder Hierarchy should not be stamped');
    }

    private static List<Product2> getProducts() {
        Product2 objProduct1 = TestDataMaster.createProduct(false);
        objProduct1.Material_Group_1__c = null;
       
        Product2 objProduct2 = TestDataMaster.createProduct(false);
        objProduct2.Material_Group_1__c = null;       
        
        List<Product2> products = new List<Product2>{objProduct1,objProduct2};

        insert products;
        return products;
    }
    private static void deleteMatricesAndHierarchies() {
        List<Approval_Hierarchy__c> allCPQHierarchies = [SELECT Id FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c LIKE '%CPQ%'];
        Id recordTypeId = TestDataApprovals.getMatrixNameToRecordType().get(TestDataApprovals.RECORD_TYPE_CPQ_DISCOUNT).getRecordTypeId();
        List<Custom_Approval_Matrix__c> discountMatrices = [SELECT Id FROM Custom_Approval_Matrix__c WHERE RecordTypeId = :recordTypeId];
        
        delete allCPQHierarchies;
        delete discountMatrices;
    }
    
    private static void updateCartLineItems(Id cartId) {
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
}
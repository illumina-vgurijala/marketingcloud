/**
*    @author Satya Swain
*    @date   2021-08-30
*    @description    DCP-48131: Test class for ApprovalQuoteLinePromotions
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Satya Swain                 2021-08-30           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestApprovalsQuoteLinePromotions {
    
    @testSetup
    static void setupData() {
        TestDataApprovals.getSupportDataForApprovals();      
    }
    @isTest
    static void testPromotionsApprovals() {
        ApttusProposalLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesApprovalsPipeline', true);

        // create quote and cart
        Apttus_Proposal__Proposal__c quote = [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        
        Apttus_Config2__Incentive__c incentive = TestDataProposal.initIncentives(TestDataApprovals.PROMOTION_NAME_BOGO, TestDataApprovals.PROMOTION_NAME_BOGO);
        
        Id promoRecordTypeId = TestDataApprovals.getMatrixNameToRecordType().get(TestDataApprovals.RECORD_TYPE_PROMOTION).getRecordTypeId();
        Custom_Approval_Matrix__c promotionMatrix = [SELECT Id, Promotion__c FROM Custom_Approval_Matrix__c WHERE RecordTypeId = :promoRecordTypeId LIMIT 1];
        promotionMatrix.Promotion__c = incentive.Id;
        update promotionMatrix;

        List<Product2> products = getProducts();
        
        Id cartId = TestDataApprovals.createCartAndLineItems(quote.Id, products);

        updateCartLineItems(cartId,incentive.Id);

        Test.startTest();
        TestDataApprovals.validateCart(cartId);
        TestDataApprovals.finalizeCart(cartId);
        Test.stopTest();

        // query results
        //Approval_Hierarchy__c salesHierarchy = [SELECT Id, Approver_Level_1__c, Approval_Hierarchy_Type__c FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c = :Approvals.CPQ_SALES LIMIT 1];
        
        Apttus_Proposal__Proposal__c quoteAfter = [SELECT Id, Sales_Discretionary_Approval_Error__c, Approval_Hierarchy_Record_Owner__c, Approval_Hierarchy_Transborder__c FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.debug('TTN quoteAfter ' + quoteAfter);
        List<Apttus_Proposal__Proposal_Line_Item__c> quoteLinesAfter = [SELECT Id, Approval_Category__c, Apttus_QPApprov__Approval_Status__c, Approval_Hierarchy_Record_Owner__c, Approval_Level_Record_Owner__c, Approval_Hierarchy_UC_Discount__c, Approval_Level_UC_Discount__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c = :quote.Id];
        for (Apttus_Proposal__Proposal_Line_Item__c quoteLine : quoteLinesAfter) { System.debug('TTN quoteLine ' + quoteLine); }

        System.assert(quoteLinesAfter.get(0).Approval_Category__c.toUpperCase().contains(Approvals.Category.PROMOTION.name().toUpperCase()),'Incorrect category stamped');
        System.assertEquals(System.Label.ProposalApprovalStatusApprovalRequired, quoteLinesAfter.get(1).Apttus_QPApprov__Approval_Status__c,'Approval Status not updated to Approval Required');    
        
    }

    private static void updateCartLineItems(Id cartId, Id promotionId) {
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
            lineitem.Applied_Discount_Percentage__c = 5;
            lineitem.Applied_Discount_Amount__c = 3600;
            lineitem.Promotion_1__c = promotionId;
            lineitem.Promotion_2__c = promotionId;
            lineitem.Promotion_3__c = promotionId;
            lineitem.Promotion_4__c = promotionId;
            lineitem.Promotion_5__c = promotionId;
        }
        update lineItemList;
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
}
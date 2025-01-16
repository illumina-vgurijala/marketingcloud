/*
 * @Author: Pradeep Landge
 * @Description: DGP-497,DGP-493,DGP-1174,DGP-1176 - Test class for ViewSalesMarginDataController
*/
@isTest
private class TestViewSalesMarginDataController{

    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.getNewAccount();
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        update acc;
        TestDataPerson.getNewContact(acc.Id);
        
        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();
        
        Id pricebookId = standardPricebook.id;
        System.assertNotEquals(null, pricebookId);
        
        List<Opportunity> lstOpty = new List<Opportunity>();
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(acc);
        objOpportunity.Pricebook2Id = pricebookId;
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Name = 'Direct Standard Opty Test';
        lstOpty.add(objOpportunity);

        Opportunity indirectStandardOpp = TestDataOpportunity.initOpportunity(acc,'Create',Date.today() + 30,10000,'Indirect_Standard',10,'Clinical','Description Test','Applied Lab','Forensics','Services','Standard Sale','$10,000 - $25,000','Internal Budget: In Process','Poor Data Quality','0-3 Months',false);
        indirectStandardOpp.Pricebook2Id = pricebookId;
        indirectStandardOpp.RecordTypeName__c = 'Indirect';
        indirectStandardOpp.Sold_to_Distribution_Channel__c = 'Indirect';
        indirectStandardOpp.Transborder_Flag__c = true;
        indirectStandardOpp.Distributor__c = acc.id;
        indirectStandardOpp.Name = 'Indirect Standard Opty Test';
        lstOpty.add(indirectStandardOpp);

        insert lstOpty;
        
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        
        List<Apttus_Proposal__Proposal__c> lstProposal = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, objOpportunity.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        lstProposal.add(proposal);

        insert lstProposal;
        
        Product2 objProduct = TestDataMaster.createProduct(true);
        objProduct.Material_Group_1_Code__c = 'AIM';
        
        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(objProduct, priceList);
        insert priceListItem;

        List<Apttus_Config2__ClassificationName__c> lstCategory = new List<Apttus_Config2__ClassificationName__c>();
        
        Apttus_Config2__ClassificationName__c category = TestDataProposal.initCategory('Test Category');
        lstCategory.add(category);
        insert lstCategory;


        List<Apttus_Config2__ClassificationHierarchy__c> lstHierarchy = new List<Apttus_Config2__ClassificationHierarchy__c>();
        
        Apttus_Config2__ClassificationHierarchy__c level0= TestDataProposal.initHierarchy(category, 'Level0', null, null, 0);
        lstHierarchy.add(level0);
        
        Apttus_Config2__ClassificationHierarchy__c level1= TestDataProposal.initHierarchy(category, 'Level1', level0, level0, 1);
        lstHierarchy.add(level1);
        
        Apttus_Config2__ClassificationHierarchy__c level2= TestDataProposal.initHierarchy(category, 'Level2', level0, level1, 2);
        lstHierarchy.add(level2);
        
        Apttus_Config2__ClassificationHierarchy__c level3= TestDataProposal.initHierarchy(category, 'Level3', level0, level2, 3);
        lstHierarchy.add(level3);
        
        Apttus_Config2__ClassificationHierarchy__c level4= TestDataProposal.initHierarchy(category, 'Level4', level0, level3, 4);
        lstHierarchy.add(level4);

        insert lstHierarchy;

        // Added by Saswati : Incentives
        Apttus_Config2__Incentive__c objIncentive = TestDataProposal.initIncentives('Test Incentive','Test Incentive Code');


        List<Approval_Hierarchy__c> lstApprovalHierarchy = new List<Approval_Hierarchy__c>();
        Approval_Hierarchy__c objDiscountApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('CPQ_Sales_Hierarchy');
        lstApprovalHierarchy.add(objDiscountApprovalHeirarchy);
        Approval_Hierarchy__c objCustomApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('CPQ_Custom_Hierarchy');
        lstApprovalHierarchy.add(objCustomApprovalHeirarchy);
        Approval_Hierarchy__c objPPMApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('Post_Pricing_Message');
        lstApprovalHierarchy.add(objPPMApprovalHeirarchy);
        Approval_Hierarchy__c objPromotionApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('Promotion');
        lstApprovalHierarchy.add(objPromotionApprovalHeirarchy);

        insert lstApprovalHierarchy;

        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();
        
        Custom_Approval_Matrix__c discountApprovalMatrix = TestDataProposal.initApprovalMatrix('CPQ Discount', objProduct , 10 , 10 , 'AMR', '1', 'USD',objCustomApprovalHeirarchy);      
        lstMatrix.add(discountApprovalMatrix);
        
        Custom_Approval_Matrix__c promoApprovalMatrix = TestDataProposal.initApprovalMatrixForPromotion('Promotion', 'BOGO', '2',objPromotionApprovalHeirarchy);
        promoApprovalMatrix.Promotion__c = objIncentive.id;
        lstMatrix.add(promoApprovalMatrix);

        insert lstMatrix;
         
        Apttus_Config2__ProductClassification__c prodClassification = TestDataProposal.initProductClassification(level4, objProduct);
        insert prodClassification;
        
        List<Apttus_Config2__ProductConfiguration__c> lstConfig = new List<Apttus_Config2__ProductConfiguration__c>();
        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.initCart(proposal);
        lstConfig.add(testCart);
        //Apttus_Config2__ProductConfiguration__c testCart3 = testCart.clone(false, false, false, false);
        //lstConfig.add(testCart3);
        insert lstConfig;

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(proposal, objProduct);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = lstConfig[0].id;
        proposalLineItem.Term_Years_helper__c = 1;
        proposalLineItem.Apttus_QPConfig__Quantity2__c = 20;
        proposalLineItem.List_Price__c = 3000;
        proposalLineItem.Distributor_Specific_Discount_Percentage__c = 10;
        proposalLineItem.Customer_Historical_Discount__c = 5;
        proposalLineItem.Total_Discount_Percentage__c = 15; 
        proposalLineItem.Apttus_QPConfig__StartDate__c = Date.newInstance(2024, 9, 17);
        proposalLineItem.Apttus_QPConfig__EndDate__c = Date.newInstance(2025, 9, 16);
        insert proposalLineItem;

        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest= new List<Apttus_Approval__Approval_Request__c>();
       
        Apttus_Approval__Approval_Request__c objApprovalRequest = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameTransregionLeadership; //Trans-Region Leadership
        lstApprovalRequest.add(objApprovalRequest);
       
        Apttus_Approval__Approval_Request__c objApprovalRequest2 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest2.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameUltimateConsignee; //Ultimate Consignee
        lstApprovalRequest.add(objApprovalRequest2);

        

        insert lstApprovalRequest;
        
        List<Id> lstEmailTemplateIds = TestDataEmailTemplate.getEmailTemplates();
        system.assertEquals(5, lstEmailTemplateIds.size(),'All templates not inserted.');
        TestDataApprovalProcess.getApprovalProcess();
        
        ContentVersion objContentVersion = TestDataProposal.initContentVersion();
        insert objContentVersion;
        ContentVersion objContentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        ContentDocumentLink objContentDocumentLink = TestDataProposal.initContentDocumentLink(proposal.Id,objContentVersion2.contentdocumentid);
        insert objContentDocumentLink;

        //Custom Approval Matrx Product Data
        Custom_Approval_Matrix_Products__c campRecord = new Custom_Approval_Matrix_Products__c(
            Custom_Approval_Matrix__c = discountApprovalMatrix.id,
            Product__c = objProduct.id
        );

        insert campRecord;

        

    }

    @isTest
    static void testHasUserPermissionAndAccess() {   
        Test.startTest();
        Apttus_Proposal__Proposal__c quote = [Select id From Apttus_Proposal__Proposal__c lIMIT 1];
        // Run the method to test user access
        Map<String, Boolean> hasAccess = ViewSalesMarginDataController.hasUserPermissionAndAccess(quote.Id);
        Test.stopTest();
        // Assert that access is properly checked
        Assert.areEqual(true, hasAccess.get('hasAccess'), 'User should have access.');
    }

    @isTest static void testCalloutCOGSForQuote() {
        Test.startTest();
        Apttus_Proposal__Proposal__c quote = [Select id,Name,Apttus_Proposal__Opportunity__c From Apttus_Proposal__Proposal__c lIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockCOGSResponse());
        string strRequstQuotJSON ='{"Zzoppid" : "'+quote.Apttus_Proposal__Opportunity__c+'","ZzapQuot" : "'+quote.Name+'","Zstatus" : "GetCOGS","Vbeln" : "4613870","NAVHDRTORET" : [ [ ] ]}';
        ApttusSAPConnector.getCOGS(strRequstQuotJSON);
        HttpRequest requestMock = new HttpRequest();
        HttpResponse res = new MockCOGSResponse().respond(requestMock);
        String actualValue = res.getBody();
        COGS_ResponseWrapper.parse(actualValue);
        Test.stopTest();
        Assert.areEqual(200, res.getStatusCode(), 'Unauthorized API');
        
    }


    @isTest
    static void testGetMarginAnalysis() {
        
        Test.startTest();
        // Create test data
        Apttus_Proposal__Proposal__c quote = [Select id From Apttus_Proposal__Proposal__c LIMIT 1];
		    // Run the method to get margin analysis data
        ViewSalesMarginDataController.MarginAnalysisData analysisData = ViewSalesMarginDataController.getMarginAnalysis(quote.Id);
        Test.stopTest();
        // Assert the analysis data
        Assert.areNotEqual(null, analysisData, 'Margin analysis data should not be null.');
        
    }
}
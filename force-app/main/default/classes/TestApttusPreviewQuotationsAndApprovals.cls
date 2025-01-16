/**
 *    @author Govind Dubey
 *    @date   2018-09-01
 *    @description  Test class of Submit for approval and Preview screen
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *             Developer                      Date                Description
        Saswati Prusty                      05-07-2019          DCP-25340
		Roopal Verma                        14-04-2020          DCP-34075
 *      Nishan Shetty                       17-01-2022          CodeScanFix- [Assert Argument Order]
 *      Himanshu                            22-04-2022          Code Scan Fixes
 *      Adyasha Satapathy                   12-10-2022          Code Scan Fixes(Method Naming Convention)
 *      Satya Swain                         09 Dec 2022         Added Codescan fix for Variable Naming Convention
 *      Priya Mukherjee						25-09-2023			CMCM-2874
 *      Sai Pasumarthy                      09-09-2024          DGP-954
 *      Akash Kumar                         17-09-2024          DGP-499
 *      Gerardo Garcia                      02-12-2024          Test fix of soql 101. Move query inside start/end test block.
 *    ------------------------------------------------------------------------------------
 *
 */
@isTest(isParallel=false)
public with sharing class TestApttusPreviewQuotationsAndApprovals { 
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

        Apttus_Proposal__Proposal__c indirectProposal = TestDataProposal.initProposal(acc.id, indirectStandardOpp.id, 'Test Indirect Proposal', priceList.id, true, 'Draft', 'None');
        lstProposal.add(indirectProposal);
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
        Apttus_Config2__ProductConfiguration__c testCart2 = TestDataProposal.initCart(indirectProposal);
        testCart2.Name = 'Product Config - indirect test';
        lstConfig.add(testCart2);
        //Apttus_Config2__ProductConfiguration__c testCart3 = testCart.clone(false, false, false, false);
        //lstConfig.add(testCart3);
        insert lstConfig;

        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest= new List<Apttus_Approval__Approval_Request__c>();
       
        Apttus_Approval__Approval_Request__c objApprovalRequest = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameTransregionLeadership; //Trans-Region Leadership
        lstApprovalRequest.add(objApprovalRequest);
       
        Apttus_Approval__Approval_Request__c objApprovalRequest2 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest2.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameUltimateConsignee; //Ultimate Consignee
        lstApprovalRequest.add(objApprovalRequest2);

        Apttus_Approval__Approval_Request__c objApprovalRequest3 = TestDataProposal.initApprovalRequest(proposal.Id);
        
        lstApprovalRequest.add(objApprovalRequest3);
        

        Apttus_Approval__Approval_Request__c objApprovalRequest4 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest4.Apttus_Approval__StepSequence__c = 2.1;
        objApprovalRequest4.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameSalesDiscretionary;
        lstApprovalRequest.add(objApprovalRequest4);
        
        Apttus_Approval__Approval_Request__c objApprovalRequest5 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest5.Apttus_Approval__StepSequence__c = 3.1;
        objApprovalRequest5.Apttus_Approval__Sequence__c = '2';
        objApprovalRequest5.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameSalesDiscretionary;
        lstApprovalRequest.add(objApprovalRequest5);

        Apttus_Approval__Approval_Request__c objApprovalRequest6 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest6.Apttus_Approval__StepSequence__c = 4.1;
        lstApprovalRequest.add(objApprovalRequest6);

        Apttus_Approval__Approval_Request__c objApprovalRequest7 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest7.Apttus_Approval__StepSequence__c = 5.1;
        objApprovalRequest7.Apttus_Approval__Sequence__c = '3';
        lstApprovalRequest.add(objApprovalRequest7);

        Apttus_Approval__Approval_Request__c objApprovalRequest8 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest8.Apttus_Approval__StepSequence__c = 6.1;
        objApprovalRequest8.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameTransregionLeadership;
        lstApprovalRequest.add(objApprovalRequest8);

        Apttus_Approval__Approval_Request__c objApprovalRequest9 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest9.Apttus_Approval__StepSequence__c = 7.1;
        objApprovalRequest9.Apttus_Approval__Sequence__c = '4';
        objApprovalRequest9.Apttus_Approval__SubstepSequence__c = 1.0000;
        objApprovalRequest9.Apttus_Approval__Step_Name__c = 'Trans Border';
        lstApprovalRequest.add(objApprovalRequest9);

        Apttus_Approval__Approval_Request__c objApprovalRequest10 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest10.Apttus_Approval__StepSequence__c = 8.1;
        objApprovalRequest10.Apttus_Approval__StepLabel__c = '1';
        objApprovalRequest10.Apttus_Approval__Sequence__c = '5';
        objApprovalRequest10.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameTransregionLeadership;
        lstApprovalRequest.add(objApprovalRequest10);
        
        Apttus_Approval__Approval_Request__c objApprovalRequest11 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest11.Apttus_Approval__StepSequence__c = 8.1;
        objApprovalRequest11.Apttus_Approval__StepLabel__c = '1';
        objApprovalRequest11.Apttus_Approval__Sequence__c = '5';
        objApprovalRequest11.Apttus_Approval__SubstepSequence__c = 1.0000;
        objApprovalRequest11.Apttus_Approval__Step_Name__c ='Trans Border';
        Apttus_Approval__Approval_Request__c objApprovalRequest12 = TestDataProposal.initApprovalRequest(proposal.Id);
        
        objApprovalRequest12.Apttus_Approval__StepSequence__c = 8.1;
        objApprovalRequest12.Apttus_Approval__StepLabel__c = '2';
        objApprovalRequest12.Apttus_Approval__Sequence__c = '6';
        objApprovalRequest12.Apttus_Approval__SubstepSequence__c = 2.0000;
        objApprovalRequest12.Apttus_Approval__Step_Name__c ='Trans Border';
        lstApprovalRequest.add(objApprovalRequest12);

        Apttus_Approval__Approval_Request__c objApprovalRequest13 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest13.Apttus_Approval__StepSequence__c = 9;
        //objApprovalRequest13.Apttus_Approval__StepLabel__c = '9';
        objApprovalRequest13.Apttus_Approval__Sequence__c = '7';
        //objApprovalRequest13.Apttus_Approval__SubstepSequence__c = 2.0000;
        objApprovalRequest13.Apttus_Approval__Step_Name__c ='PROMOTION';
        lstApprovalRequest.add(objApprovalRequest13); 

        Apttus_Approval__Approval_Request__c objApprovalRequestInd = TestDataProposal.initApprovalRequest(indirectProposal.Id);
        objApprovalRequestInd.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameTransregionLeadership;
        lstApprovalRequest.add(objApprovalRequestInd);
       
        Apttus_Approval__Approval_Request__c objApprovalRequestInd2 = TestDataProposal.initApprovalRequest(indirectProposal.Id);
        objApprovalRequestInd2.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameUltimateConsignee;
        lstApprovalRequest.add(objApprovalRequestInd2);

        Apttus_Approval__Approval_Request__c objApprovalRequestInd3 = TestDataProposal.initApprovalRequest(indirectProposal.Id);
        
        lstApprovalRequest.add(objApprovalRequestInd3);
        

        Apttus_Approval__Approval_Request__c objApprovalRequestInd4 = TestDataProposal.initApprovalRequest(indirectProposal.Id);
        objApprovalRequestInd4.Apttus_Approval__StepSequence__c = 2.1;
        objApprovalRequestInd4.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameSalesDiscretionary;
        lstApprovalRequest.add(objApprovalRequestInd4);
        
        Apttus_Approval__Approval_Request__c objApprovalRequestInd5 = TestDataProposal.initApprovalRequest(indirectProposal.Id);
        objApprovalRequestInd5.Apttus_Approval__StepSequence__c = 3.1;
        objApprovalRequestInd5.Apttus_Approval__Sequence__c = '2';
        objApprovalRequestInd5.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameSalesDiscretionary;
        lstApprovalRequest.add(objApprovalRequestInd5);

        Apttus_Approval__Approval_Request__c objApprovalRequestInd6 = TestDataProposal.initApprovalRequest(indirectProposal.Id);
        objApprovalRequestInd6.Apttus_Approval__StepSequence__c = 4.1;
        objApprovalRequestInd6.Apttus_Approval__StepLabel__c = '1';
        objApprovalRequestInd6.Apttus_Approval__Step_Name__c = 'Trans Border';
        objApprovalRequestInd6.Apttus_Approval__SubstepSequence__c = 1.0000;
        lstApprovalRequest.add(objApprovalRequestInd6);

        Apttus_Approval__Approval_Request__c objApprovalRequestInd7 = TestDataProposal.initApprovalRequest(indirectProposal.Id);
        objApprovalRequestInd7.Apttus_Approval__StepSequence__c = 5.1;
        objApprovalRequestInd7.Apttus_Approval__Sequence__c = '3';
        objApprovalRequestInd7.Apttus_Approval__StepLabel__c = '1';
        objApprovalRequestInd7.Apttus_Approval__Step_Name__c = 'Trans Border';
        objApprovalRequestInd7.Apttus_Approval__SubstepSequence__c = 2.0000;
        lstApprovalRequest.add(objApprovalRequestInd7);
        
        Apttus_Approval__Approval_Request__c objApprovalRequestma1 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequestma1.Apttus_Approval__Step_Name__c = 'CPQ Sales Approval Rule';
        objApprovalRequestma1.Apttus_Approval__StepLabel__c = 'Finance Level 2';
        lstApprovalRequest.add(objApprovalRequestma1);
        
        Apttus_Approval__Approval_Request__c objApprovalRequestma2 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequestma2.Apttus_Approval__Step_Name__c = 'CPQ Sales Approval Rule';
        objApprovalRequestma2.Apttus_Approval__StepLabel__c = 'Sales Level 7';
        lstApprovalRequest.add(objApprovalRequestma2);
        
        Apttus_Approval__Approval_Request__c objApprovalRequestma3 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequestma3.Apttus_Approval__Step_Name__c = 'CPQ Sales Transborder Rule';
        objApprovalRequestma3.Apttus_Approval__StepLabel__c = '5';
        lstApprovalRequest.add(objApprovalRequestma3);
        
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
    
    /**
    *  @author Satya Swain
    *  @description Test method for preview Quotation Submitter Experience Screen functionality
    **/    
    @isTest
    static void testDirectPreviewQuotations()
    {   
        Test.startTest();
        Opportunity objOpportunity = null;
        for(Opportunity opp:[Select id,Name From Opportunity]){
            if(opp.Name=='Direct Standard Opty Test')
               objOpportunity = opp; 
        }
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id];
         
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c WHERE Name ='Product Config - test'];  
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;
        
        Product2 product = [Select id From Product2 LIMIT 1];        
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, product);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        proposalLineItem.Term_Years_helper__c = 1; //DGP-954
        insert proposalLineItem;
        Apttus_Approval__Approval_Request__c objApprovalRequest = [Select Id from Apttus_Approval__Approval_Request__c LIMIT 1][0];
        Test.setCurrentPageReference(new PageReference('Page.ApttusSubmitForApprovalPage'));
        System.currentPageReference().getParameters().put('sObjectId', objProposal.Id);
        ApttusSubmitForApprovalController sec = new ApttusSubmitForApprovalController();
		sec.objApprovalRequest = objApprovalRequest;
        sec.previewQuotations();

        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = new ApttusApprovalRequestsSelector().selectByQuoteId(new Set<Id>{objProposal.Id});

        Assert.isNotNull(sec.lstApprovalRequestWrapper , 'Error in PreviewApprovals functionality');
        Assert.areEqual(lstApprovalRequest.get(1).Apttus_Approval__Step_Name__c, sec.lstApprovalRequestWrapper.get(1).strApprovalName, 'Approval name are different.');//CodeScanFix- [Assert Argument Order]
        Assert.areEqual('1',sec.lstApprovalRequestWrapper.get(1).lstApprovalSequence.get(0),'Approver Level not matched.');//CodeScanFix- [Assert Argument Order]
        
        sec.submitForApproval();
        
        //Apttus_Proposal__Proposal__c objProposal3 = [Select id, Apttus_QPApprov__Approval_Status__c, Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id];
        //system.assertEquals('Approval Required', objProposal3.Apttus_Proposal__Approval_Stage__c, 'Quote is not submitted for approval.');
        sec.displayAttachments();
        
        //Apttus_Proposal__Proposal__c objProposal4 = [Select id, Apttus_QPApprov__Approval_Status__c, Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id];
        //system.assertEquals('Approval Required', objProposal4.Apttus_Proposal__Approval_Stage__c, 'Quote is not submitted for approval with attachment.');
        sec.cancel();
        delete lstApprovalRequest;
        sec.previewQuotations();
        Test.stopTest();

        Apttus_Proposal__Proposal__c objProposal2 = [Select id, Apttus_QPApprov__Approval_Status__c, Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id];
        Assert.areEqual('Approved', objProposal2.Apttus_QPApprov__Approval_Status__c, 'Approval Status is different.');
        Assert.areEqual('Approved', objProposal2.Apttus_Proposal__Approval_Stage__c, 'Approval Stage is different.');
    }
    
    /**
    *  @author Satya Swain
    *  @description Test method for preview Quotation Submitter Experience Screen functionality
    **/    
    @isTest
    static void testIndirectPreviewQuotations()
    {   
        Test.startTest();
        Opportunity objOpportunity = [Select id From Opportunity WHERE Name='Indirect Standard Opty Test'];
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id];
         
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c WHERE Name ='Product Config - indirect test'];  
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;
        
        Product2 product = [Select id From Product2 LIMIT 1];
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, product);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        insert proposalLineItem;
        Test.setCurrentPageReference(new PageReference('Page.ApttusSubmitForApprovalPage'));
        System.currentPageReference().getParameters().put('sObjectId', objProposal.Id);
        ApttusSubmitForApprovalController sec = new ApttusSubmitForApprovalController();
        
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_QPApprov__ProposalId__c =: objProposal.Id];
       	sec.objApprovalRequest = lstApprovalRequest[0];
        sec.previewQuotations();
        system.assert(sec.lstApprovalRequestWrapper!=null, 'Error in PreviewApprovals functionality');
        system.assertEquals('Trans-Region Leadership',sec.lstApprovalRequestWrapper.get(0).strApprovalName,'Approval name are different.');//CodeScanFix- [Assert Argument Order]
        system.assertEquals('1',sec.lstApprovalRequestWrapper.get(0).lstApprovalSequence.get(0),'Approver Level not matched.');//CodeScanFix- [Assert Argument Order]
        
        sec.submitForApproval();
       
       
        delete lstApprovalRequest;
        sec.previewQuotations();
        Apttus_Proposal__Proposal__c objProposal2 = [Select id, Apttus_QPApprov__Approval_Status__c, Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Indirect Proposal'];
        system.assertEquals('Approved', objProposal2.Apttus_QPApprov__Approval_Status__c, 'Approval Status is different.');
        system.assertEquals('Approved', objProposal2.Apttus_Proposal__Approval_Stage__c, 'Approval Stage is different.');
        Test.stopTest();
    }
    /**
    *  @author Satya Swain
    *  @description Test method for send email to approver when submit for approval button is clicked functionality
    **/
    @isTest
    static void testSubmitForApproval()
    {
        Opportunity objOpportunity = [SELECT id From Opportunity WHERE Name='Direct Standard Opty Test'];
        Apttus_Proposal__Proposal__c objProposal = [SELECT id, Discount_Reason__c, Discount_Reason_Definition__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id];//and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'
         
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c WHERE Name = 'Product Config - test'];  
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;

        Test.startTest();

        Product2 product = [SELECT id FROM Product2 LIMIT 1];

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, product);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        insert proposalLineItem;
        Test.setCurrentPageReference(new PageReference('Page.ApttusSubmitForApprovalPage'));
        System.currentPageReference().getParameters().put('sObjectId', objProposal.Id);
        ApttusSubmitForApprovalController sec = new ApttusSubmitForApprovalController();
        
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_QPApprov__ProposalId__c =: objProposal.Id  ];
        System.debug('@@@lstApprovalRequest'+lstApprovalRequest);
        
        sec.objApprovalRequest = lstApprovalRequest.get(0);
        sec.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = 'Test Approver';
        sec.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Approved';
        sec.boolSkipPreviewApprovalsAPI = false;
        //CMCM-2874
        
        List<Apttus_Proposal__Proposal__c> lstQuotation = [SELECT id, Discount_Reason__c, Discount_Reason_Definition__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id];
        sec.objQuotation = lstQuotation.get(0);
        sec.objQuotation.Discount_Reason__c = 'Channel Partner Demo Program';
        System.debug('@@@objQuotation Discount_Reason__c:'+sec.objQuotation.Discount_Reason__c);
        update sec.objQuotation;
        System.debug('@@@objApprovalRequest id:'+sec.objApprovalRequest.Id);
        
        sec.updateDiscountReasonDefinition();
        sec.getLoadData();
        sec.previewQuotations();
        sec.submitForApproval();
        sec.cancel();
        sec.displayAttachments();
        
        
        /*sec.objApprovalRequest.id = lstApprovalRequest[12].id;
        sec.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = 'Test Approver';
        sec.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Assigned';
        sec.objApprovalRequest.Apttus_Approval__Step_Name__c = 'PROMOTION';
        update sec.objApprovalRequest;
        System.debug('@@@objApprovalRequest id:'+sec.objApprovalRequest.Id);
        //String str = sec.getLoadData();
        sec.previewQuotations();
        sec.submitForApproval(); */
                
        sec.objApprovalRequest = lstApprovalRequest.get(1);
        sec.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = 'Test Approver';
        sec.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Assigned';
        update sec.objApprovalRequest;
        System.debug('@@@objApprovalRequest id:'+sec.objApprovalRequest.Id);
        sec.boolSkipPreviewApprovalsAPI = false;
        sec.previewQuotations(); 
        //sec.strFileName = 'Unit Test Attachment';
        //sec.blobFile = Blob.valueOf('Unit Test Attachment Body');
        //sec.uploadFile();
        delete lstApprovalRequest;
        sec.previewQuotations();
        
        System.assertEquals(false,sec.boolSkipPreviewApprovalsAPI);
        //CMCM-2874
        Apttus_Proposal__Proposal__c ap = [SELECT Id, Discount_Reason_Definition__c FROM Apttus_Proposal__Proposal__c LIMIT 1];
        system.assertEquals(Label.Discount_Reason_Channel_Partner_Demo_Program, ap.Discount_Reason_Definition__c);
        Test.stopTest();
    }
    
    /**
    *  @author Govind Dubey
    *  @description Test method for preview Approvals functionality
    **/
    @isTest
    static void testDirectPreviewApprovals()
    {   
        Test.startTest();
        Opportunity objOpportunity = [Select id From Opportunity WHERE Name='Direct Standard Opty Test'];
        
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c WHERE Name = 'Product Config - test'];  
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;
        
        Product2 product = [Select id From Product2 LIMIT 1];
        Apttus_Config2__PriceListItem__c objPLI = [SELECT Id,Apttus_Config2__IsQuantityReadOnly__c FROM Apttus_Config2__PriceListItem__c LIMIT 1];

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, product);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        insert proposalLineItem;
        Test.setCurrentPageReference(new PageReference('Page.ApttusPreviewApprovals')); 
        System.currentPageReference().getParameters().put('businessObjectId', objProposal.Id);
        System.currentPageReference().getParameters().put('id', productConfig.Id);

        
        ApttusPreviewApprovalsController pac = new ApttusPreviewApprovalsController();
        
        pac.previewApprovals();
        objPLI.Apttus_Config2__IsQuantityReadOnly__c = false;
        objPLI.Apttus_Config2__PriceType__c = 'One Time';
        update objPLI;
        product.Product_Group__c = Label.ProductGroupProfessionalService;
        product.Material_Class__c = 'Consumables';
        update product;

        product.Product_Group__c = 'AmpliSeq Library Prep';
        product.Material_Class__c = 'Consumables';
        update product;

        Test.stopTest();

        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = new ApttusApprovalRequestsSelector().selectByQuoteId(new Set<Id>{objProposal.Id});

        Assert.isNotNull(pac.lstApprovalRequestWrapper, 'Error in PreviewApprovals functionality');
        Assert.areEqual(lstApprovalRequest.get(1).Apttus_Approval__Step_Name__c, pac.lstApprovalRequestWrapper.get(1).strApprovalName,'Approval name are different.');//CodeScanFix- [Assert Argument Order]
        Assert.areEqual('1',pac.lstApprovalRequestWrapper.get(1).lstApprovalSequence.get(0),'Approver Level not matched.');//CodeScanFix- [Assert Argument Order]
    }
    /**
    *  @author Govind Dubey
    *  @description Test method for preview Approvals functionality
    **/
    @isTest
    static void testIndirectPreviewApprovals()
    {   
        Test.startTest();
        Opportunity objOpportunity = [Select id From Opportunity WHERE Name='Indirect Standard Opty Test'];
        
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c WHERE Name = 'Product Config - indirect test'];  
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;
        
        Product2 product = [Select id From Product2 LIMIT 1];
        Apttus_Config2__PriceListItem__c objPLI = [SELECT Id,Apttus_Config2__IsQuantityReadOnly__c FROM Apttus_Config2__PriceListItem__c LIMIT 1];

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, product);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        insert proposalLineItem;
        Test.setCurrentPageReference(new PageReference('Page.ApttusPreviewApprovals')); 
        System.currentPageReference().getParameters().put('businessObjectId', objProposal.Id);
        System.currentPageReference().getParameters().put('id', productConfig.Id);

        
        ApttusPreviewApprovalsController pac = new ApttusPreviewApprovalsController();
        
        pac.previewApprovals();
        objPLI.Apttus_Config2__IsQuantityReadOnly__c = false;
        objPLI.Apttus_Config2__PriceType__c = 'One Time';
        update objPLI;
        product.Product_Group__c = Label.ProductGroupProfessionalService;
        product.Material_Class__c = 'Consumables';
        update product;

        product.Product_Group__c = 'AmpliSeq Library Prep';
        product.Material_Class__c = 'Consumables';
        update product;

        Test.stopTest();
        system.assert(pac.lstApprovalRequestWrapper!=null, 'Error in PreviewApprovals functionality');
        system.assertEquals('Trans-Region Leadership',pac.lstApprovalRequestWrapper.get(0).strApprovalName,'Approval name are different.');//CodeScanFix- [Assert Argument Order]
        system.assertEquals('1',pac.lstApprovalRequestWrapper.get(0).lstApprovalSequence.get(0),'Approver Level not matched.');//CodeScanFix- [Assert Argument Order]
    }
	
	/**
    *  @author Roopal Verma
    *  @description Test method for send email to approver when submit for approval button is clicked functionality
    **/
    @isTest
    static void addEmailPDFAttachment(){

        Test.startTest();
        Opportunity objOpportunity = [Select id From Opportunity WHERE Name='Direct Standard Opty Test'];
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id ];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c WHERE Name = 'Product Config - test'];   
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;
        
        Product2 product = [Select id From Product2 LIMIT 1];
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, product);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        insert proposalLineItem;
                      
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_QPApprov__ProposalId__c =: objProposal.Id  ];
        System.debug('@@@lstApprovalRequest'+lstApprovalRequest);
        Test.setCurrentPageReference(new PageReference('Page.ApttusSubmitForApprovalPDFPage'));
        System.currentPageReference().getParameters().put('sObjectId', lstApprovalRequest.get(0).Id);
        ApttusSubmitForApprovalController sec = new ApttusSubmitForApprovalController();
        
        System.debug('@@@objApprovalRequest id:'+lstApprovalRequest.get(0).Id);
        sec.boolSkipPreviewApprovalsAPI = false;
        sec.addEmailPDFAttachment();
        
        System.assertEquals(false,sec.boolSkipPreviewApprovalsAPI);
        Test.stopTest();
    }
    /**
    *  @author Akash Kumar
    *  @description Test method to Validate whether the user has access to read the message containing link to marginal analysis data
    **/
    @isTest
    static void testShowMarginAnalysisMessage(){
        
        Boolean boolFinancialApprover = false;
        Boolean boolSalesApprover = false;
        Boolean boolTransborderApprover = false;
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = [SELECT Id,Apttus_Approval__Step_Name__c,Apttus_Approval__StepLabel__c
                                                                         FROM Apttus_Approval__Approval_Request__c 
                                                                         WHERE Apttus_Approval__Step_Name__c =: 'CPQ Sales Approval Rule' 
                                                                         AND Apttus_Approval__StepLabel__c =:'Finance Level 2'LIMIT 1
                                                                        ];
        
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest1 = [SELECT Id,Apttus_Approval__Step_Name__c,Apttus_Approval__StepLabel__c
                                                                         FROM Apttus_Approval__Approval_Request__c 
                                                                         WHERE Apttus_Approval__Step_Name__c =: 'CPQ Sales Approval Rule' 
                                                                         AND Apttus_Approval__StepLabel__c =:'Sales Level 7'LIMIT 1
                                                                        ];
        
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest2 = [SELECT Id,Apttus_Approval__Step_Name__c,Apttus_Approval__StepLabel__c
                                                                         FROM Apttus_Approval__Approval_Request__c 
                                                                         WHERE Apttus_Approval__Step_Name__c =: 'CPQ Sales Transborder Rule' 
                                                                         AND Apttus_Approval__StepLabel__c =:'5'LIMIT 1
                                                                        ];
        
        test.startTest();
        boolFinancialApprover = ApttusSubmitForApprovalController.showMarginalAnalysisMessage(lstApprovalRequest[0]);
        boolSalesApprover = ApttusSubmitForApprovalController.showMarginalAnalysisMessage(lstApprovalRequest1[0]);
        boolTransborderApprover = ApttusSubmitForApprovalController.showMarginalAnalysisMessage(lstApprovalRequest2[0]);
        test.stopTest();
        Assert.isTrue(boolFinancialApprover,'Approver does not have access');
        Assert.isTrue(boolSalesApprover,'Approver does not have access');
        Assert.isTrue(boolTransborderApprover,'Approver does not have access');
        
    }
}
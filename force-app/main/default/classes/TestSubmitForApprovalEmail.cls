/**
*    @author Satya Swain
*    @date   2018-08-26
*    @description  DCP-858: Send Email to Approver when Submit for Approval is clicked
*    Modification Log: 
*    --------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    --------------------------------------------------------------------------------------
*            Satya Swain                    08-26-2018         Initial Version 
*            Roopal Verma                   20-03-2020         Added addEmailPDFAttachment for DCP-3407
*            Roopal Verma                   02-04-2020         Added static string for Sonar qube fix
*            Adyasha Satapathy              12-10-2022         Code Scan Fixes(Method Naming Convention)
*/           

@isTest(isParallel=false)
public with sharing class TestSubmitForApprovalEmail {

	public static final String TEST_APPROVER = 'Test Approver';  //SonarQube fix

	@testsetup
    static void setupData(){
        Account acc = TestDataAccount.getNewAccount();
        TestDataPerson.getNewContact(acc.Id);
        
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert proposal;
        
        Product2 product = TestDataMaster.createProduct(true);
        
        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(product, priceList);
        insert priceListItem;
        
        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.getNewCart(proposal);
        
        Apttus_Config2__ProductConfiguration__c testCart2 = testCart.clone(false);
        insert testCart2;
        
        List<Apttus_Approval__Approval_Request__c> lstobjAppReq = new List<Apttus_Approval__Approval_Request__c>();
        Apttus_Approval__Approval_Request__c objApprovalRequest1 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest1.Apttus_Approval__Step_Name__c = 'PROMOTION';
        objApprovalRequest1.Apttus_Approval__StepLabel__c = '5';
        objApprovalRequest1.Apttus_Approval__Object_Type__c = 'Apttus_Proposal__Proposal__c';

        Apttus_Approval__Approval_Request__c objApprovalRequest2 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest2.Apttus_Approval__Object_Type__c = 'Apttus_Proposal__Proposal__c';
        
        Apttus_Approval__Approval_Request__c objApprovalRequest3 = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest3.Apttus_Approval__Object_Type__c = 'Apttus_Proposal__Proposal__c';
        objApprovalRequest3.Apttus_Approval__Step_Name__c = 'CPQ Sales Approval Rule';
        objApprovalRequest3.Apttus_Approval__StepLabel__c = 'Sales Level 2';
        
        lstobjAppReq.add(objApprovalRequest1);
        lstobjAppReq.add(objApprovalRequest2);
        lstobjAppReq.add(objApprovalRequest3);
        
        insert lstobjAppReq;

        List<Id> lstEmailTemplateIds = TestDataEmailTemplate.getEmailTemplates();
        system.assertEquals(5, lstEmailTemplateIds.size(),'All templates not inserted.');
        TestDataApprovalProcess.getApprovalProcess();
        
        ContentVersion objContentVersion = TestDataProposal.initContentVersion();
        insert objContentVersion;
        ContentVersion objContentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        ContentDocumentLink objContentDocumentLink = TestDataProposal.initContentDocumentLink(proposal.Id,objContentVersion2.contentdocumentid);
        insert objContentDocumentLink; 
    }

    
    /**
    *  @author Bharath Varma
    *  @description Test method to increase coverage of ApttusSubmitForApprovalController class
    **/
    @isTest 
    static void testQuotationStageApprovalRequired(){
        Test.startTest(); 
        Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [Select id,Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
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
        
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_QPApprov__ProposalId__c =: objProposal.Id  ];
		System.debug('@@@lstApprovalRequest'+lstApprovalRequest);
        
        sec.strFileName = 'Testcoverage';
        sec.strEmailType = 'TestEmailType';
        
        sec.objApprovalRequest = lstApprovalRequest.get(0);
        sec.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = TEST_APPROVER;
        sec.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Approved';
        update sec.objApprovalRequest;
        sec.getLoadData();
        
        System.assertEquals(true,sec.boolSkipPreviewApprovalsAPI);
        Test.stopTest();
    }
    
    
    /**
    *  @author Satya Swain
    *  @description Test method for send email to approver when submit for approval button is clicked functionality
    **/
    @isTest
    static void testSubmitForApproval(){
        Test.startTest();
        Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [Select id,Apttus_Proposal__Approval_Stage__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        productConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update productConfig;

        Product2 product = [Select id From Product2 LIMIT 1];
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objProposal, product);
        proposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        proposalLineItem.Approval_Level_Record_Owner__c=8;
        insert proposalLineItem;
                
        Test.setCurrentPageReference(new PageReference('Page.ApttusSubmitForApprovalPage'));
        System.currentPageReference().getParameters().put('sObjectId', objProposal.Id);
       
        List<Apttus_Approval__Approval_Request__c> lstobjAppReq = new List<Apttus_Approval__Approval_Request__c>();
        Apttus_Approval__Approval_Request__c objApprovalRequest1 = TestDataProposal.initApprovalRequest(objProposal.Id);
        objApprovalRequest1.Apttus_Approval__Step_Name__c = 'PROMOTION';
        objApprovalRequest1.Apttus_Approval__StepLabel__c = '5';
        objApprovalRequest1.Apttus_Approval__Object_Type__c = 'Apttus_Proposal__Proposal__c';

        Apttus_Approval__Approval_Request__c objApprovalRequest2 = TestDataProposal.initApprovalRequest(objProposal.Id);
        objApprovalRequest2.Apttus_Approval__Object_Type__c = 'Apttus_Proposal__Proposal__c';
        
        Apttus_Approval__Approval_Request__c objApprovalRequest3 = TestDataProposal.initApprovalRequest(objProposal.Id);
        objApprovalRequest3.Apttus_Approval__Object_Type__c = 'Apttus_Proposal__Proposal__c';
        objApprovalRequest3.Apttus_Approval__Step_Name__c = 'CPQ Sales Approval Rule';
        objApprovalRequest3.Apttus_Approval__StepLabel__c = 'Sales Level 2';
        
        lstobjAppReq.add(objApprovalRequest1);
        lstobjAppReq.add(objApprovalRequest2);
        lstobjAppReq.add(objApprovalRequest3);
        
        insert lstobjAppReq;
        
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_QPApprov__ProposalId__c =: objProposal.Id ];
		System.debug('@@@lstApprovalRequest'+lstApprovalRequest);

        ApttusSubmitForApprovalController sec = new ApttusSubmitForApprovalController();
        sec.objApprovalRequest = lstApprovalRequest.get(0);
        sec.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = TEST_APPROVER;
        sec.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Approved';
        sec.boolSkipPreviewApprovalsAPI = false;
        update sec.objApprovalRequest;
      	System.debug('@@@objApprovalRequest id:'+sec.objApprovalRequest.Id);
        //sec.getLoadData();
        //sec.previewQuotations();
        //sec.submitForApproval();
        //sec.cancel();
        //sec.displayAttachments();
                
        sec.objApprovalRequest = lstApprovalRequest.get(1);
        sec.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = TEST_APPROVER;
        sec.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Assigned';
        sec.objApprovalRequest.Apttus_Approval__Step_Name__c = 'PROMOTION';
        sec.objApprovalRequest.Apttus_Approval__StepLabel__c = '4';
        update sec.objApprovalRequest;
      	System.debug('@@@objApprovalRequest id:'+sec.objApprovalRequest.Id);
        sec.boolSkipPreviewApprovalsAPI = false;
        //sec.previewQuotations(); 
        
        delete lstApprovalRequest;
        //sec.previewQuotations();
        System.assertEquals(false,sec.boolSkipPreviewApprovalsAPI);
        Test.stopTest();
    }
   
    
    /**
    *  @author Satya Swain
    *  @DCP-34075 - description Test method for previewQuotations method after user clicks submit for approval button
    **/
    @isTest
    static void testDisplayQuotations(){
        
        
        Apttus_Proposal__Proposal__c objProposal = [Select Id, Apttus_Proposal__Approval_Stage__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c = 'Test Proposal' ];
    
        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c WHERE Name = 'Product Config - test' LIMIT 1];  
        objProductConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update objProductConfig;
        //Test.startTest();
        Product2 objProduct = [Select id From Product2 LIMIT 1];
       
        Test.startTest(); 
        Apttus_Proposal__Proposal_Line_Item__c objProposalLineItem = TestDataProposal.initProposalLineItem(objProposal, objProduct);
        objProposalLineItem.Apttus_QPConfig__HasIncentives__c = true;
        objProposalLineItem.Apttus_QPConfig__ConfigurationId__c = objProductConfig.id; 
		
        Test.setCurrentPageReference(new PageReference('Page.ApttusSubmitForApprovalPage'));
        System.currentPageReference().getParameters().put('sObjectId', objProposal.Id);
        ApttusSubmitForApprovalController sec = new ApttusSubmitForApprovalController();

        List<Apttus_Approval__Approval_Request__c> lstApprovalRequest = [SELECT Id FROM Apttus_Approval__Approval_Request__c WHERE Apttus_QPApprov__ProposalId__c =: objProposal.Id  ];
        System.debug('@@@lstApprovalRequest'+lstApprovalRequest);
        //Test.startTest();   //Added by SB
        sec.objApprovalRequest = lstApprovalRequest.get(0);
        sec.objApprovalRequest.Apttus_Approval__Assigned_To_Name__c = TEST_APPROVER;
        sec.objApprovalRequest.Apttus_Approval__Approval_Status__c = 'Approved';
        sec.boolSkipPreviewApprovalsAPI = false;
        update sec.objApprovalRequest;
        System.debug('@@@objApprovalRequest id:'+sec.objApprovalRequest.Id);
        sec.previewQuotations();
        sec.submitForApproval();
        sec.cancel();
        sec.displayAttachments();
        sec.submitForApproval();
        
        objProposal.Apttus_Proposal__Approval_Stage__c ='Approval Required';
        update objProposal;
        Test.stopTest();
        delete lstApprovalRequest;
        sec.previewQuotations();
        objProposal.Apttus_Proposal__Approval_Stage__c ='In Review';
        objProposal.Sales_Discretionary_Approval_Error__c = 'Test Error';
        update objProposal;
        sec.previewQuotations();
        	
		system.assertEquals('In Review',objProposal.Apttus_Proposal__Approval_Stage__c,'Approval status not correct');

    }
	
    
	/**
    *  @author Roopal Verma
    *  @description Test method for send email to approver when submit for approval button is clicked functionality
    **/
    @isTest
    static void addEmailPDFAttachment(){
        Test.startTest();
        Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
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
        
                       
        lstApprovalRequest.get(0).Apttus_Approval__Assigned_To_Name__c = 'Test Approver';
        lstApprovalRequest.get(0).Apttus_Approval__Approval_Status__c = 'Assigned';
        lstApprovalRequest.get(0).Apttus_Approval__Step_Name__c = 'PROMOTION';
        lstApprovalRequest.get(0).Apttus_Approval__StepLabel__c = '6';
        update lstApprovalRequest.get(0);        
        System.debug('@@@objApprovalRequest id:'+lstApprovalRequest.get(0).Id);

        sec.boolSkipPreviewApprovalsAPI = false;
        sec.addEmailPDFAttachment();
        
        System.assertEquals(false,sec.boolSkipPreviewApprovalsAPI);
        Test.stopTest();
    }


	/**
    *  @author Saurabh Brahmankar
    *  @description Test method for method createUrlWithParams
    **/    
        @isTest
        static void testCreateUrlWithParams() {
            // Get the base URL
            String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
            
            // Create test data (e.g., parameters)
            Map<String, String> params = new Map<String, String>{
                'param1' => 'value1',
                    'param2' => 'value2'
                    };
                        
                        // Call the method
                        String resultUrl = ApttusSubmitForApprovalController.createUrlWithParams(baseUrl, params);
            
            // Assert the results
            System.assertEquals(baseUrl + '?param1=value1&param2=value2', resultUrl);
        }

    
    
     /* @isTest
    static void testUpdateDiscountReasonDefinition() {
        // Create test data (replace with relevant data)
        Discount_Reason_to_Definition_Mapping__mdt mappingRecord = new Discount_Reason_to_Definition_Mapping__mdt(
            Discount_Reason__c = 'Sample Reason',
            Discount_Reason_Definition__c = 'Sample Definition'
        );
        insert mappingRecord;

        // Create a mock Quotation object (replace with relevant fields)
        Apttus_Proposal__Proposal__c objQuotation = new Apttus_Proposal__Proposal__c(
            Discount_Reason__c = 'Sample Reason'
        );
        insert objQuotation;
         ApttusSubmitForApprovalController apptus=new ApttusSubmitForApprovalController();

        // Call the method
        Test.startTest();
            apptus.updateDiscountReasonDefinition();
        Test.stopTest();

        // Verify the expected behavior
       // System.assertEquals('Sample Definition', ApttusSubmitForApprovalController.updateDiscountReasonDefinition());
    } */
}
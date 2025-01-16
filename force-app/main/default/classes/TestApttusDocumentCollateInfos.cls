/**
*	@author Milan Savaliya
*	@date 2018-10-26
*	@description	
*	Modification Log:
*	------------------------------------------------------------------------------------
*			Developer					Date				Description
*			Milan						2018-10-26
*           Akshay Mohan                2021-05-11          DCP-38809: Add logic to copy file to work order
*	------------------------------------------------------------------------------------
**/

@isTest(SeeAllData=false isParallel=false)
public with sharing class TestApttusDocumentCollateInfos {

    
	/**
	*	@author Milan Savaliya
	*	@description Test Data Setup for Sync  Attachment tO oPP
	**/
	@testSetup
	static voId setupData() {

		Account objAccount = TestDataAccount.getNewAccount();
		objAccount.Account_Group__c = 'Distributor';

		List<Account> lstAccount = new List<Account>();
		lstAccount.add(objAccount);
		update lstAccount;

		//DCP-38809: Start- setup work order data
		Contact con = TestDataPerson.initContact(objAccount.Id);
        insert con;
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Reason_for_Reopen__c = 'Test Reason';
        insert cs;
		cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
		workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        setting.Bypass_All_Validations__c = false;
        update setting;
		//DCP-38809: End- setup work order data
		Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
		insert objPriceList;
		
		Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount, 'Indirect_Standard');
		objOpportunity.Name = 'opp2';
		objOpportunity.Distributor__c = objAccount.Id;
		objOpportunity.Ultimate_Consignee__c = objAccount.Id;
		objOpportunity.Direct_Sale_to_Ultimate_Consignee__c = false;
		objOpportunity.Price_List__c = objPriceList.Name;
		insert objOpportunity;
		
		Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(objAccount.Id
																				, objOpportunity.Id
																				, 'Test Proposal'
																				, objPriceList.Id
																				, true
																				, 'Draft'
																				, 'None');
		proposal.Apttus_Proposal__Primary__c = true;
		insert proposal;

	}


	/**
	*	@author Milan Savaliya
	*	@description Test method for after update
	**/
	static testMethod voId testAfterUpdate() {
		
		List<Apttus_Proposal__Proposal__c> lstProposal = [SELECT Id
																	, Apttus_Proposal__Opportunity__c
																	FROM Apttus_Proposal__Proposal__c 
																	LIMIT 1];

		if(!lstProposal.isEmpty()) {

			Apttus_Proposal__Proposal__c objProposal01 = lstProposal[0];

			Attachment objAttachment01 = getAttachment(objProposal01.Id
															, 'Test_Proposal_Attachment'
															, 'Test Body');

			Attachment objAttachment02 = getAttachment(objProposal01.Id
															, 'Test Proposal.pdf'
															, 'Test Body');

			List<Attachment> listAttachment = new List<Attachment> {objAttachment01
																	, objAttachment02};
			insert listAttachment;

			Apttus_Proposal__DocumentCollateInfo__c objDocumentCollateInfo01 = new Apttus_Proposal__DocumentCollateInfo__c();
			objDocumentCollateInfo01.Name = 'Test';
			objDocumentCollateInfo01.Apttus_Proposal__ProposalId__c = objProposal01.Id;

			Apttus_Proposal__DocumentCollateInfo__c objDocumentCollateInfo02 = new Apttus_Proposal__DocumentCollateInfo__c();
			objDocumentCollateInfo02.Name = 'Test2';
			objDocumentCollateInfo02.Apttus_Proposal__ProposalId__c = objProposal01.Id;
			
			List<Apttus_Proposal__DocumentCollateInfo__c> listDocumentCollateInfo = new List<Apttus_Proposal__DocumentCollateInfo__c> {objDocumentCollateInfo01
				, objDocumentCollateInfo02};

			insert listDocumentCollateInfo;

			List<ContentVersion> lstContentVersion = new List<ContentVersion>();
			ContentVersion contentVersion = new ContentVersion(
		  	Title = 'Penguins',
		  	PathOnClient = 'Penguins.jpg',
		  	VersionData = Blob.valueOf('Test Content'),
		  	IsMajorVersion = true
			);
			lstContentVersion.add(contentVersion);

			ContentVersion contentVersion2 = new ContentVersion(
		  	Title = 'Test_Proposal_Attachment',
		  	PathOnClient = 'Penguins.jpg',
		  	VersionData = Blob.valueOf('Test Content'),
		  	IsMajorVersion = true
			);
			lstContentVersion.add(contentVersion2);

			insert lstContentVersion; 

			List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 2];

			//create ContentDocumentLink  record 
			List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();
			ContentDocumentLink cdl = New ContentDocumentLink();
			cdl.LinkedEntityId = lstProposal[0].id;
			cdl.ContentDocumentId = documents[0].Id;
			cdl.shareType = 'V';
			lstContentDocumentLink.add(cdl);

			ContentDocumentLink cdl2 = New ContentDocumentLink();
			cdl2.LinkedEntityId = lstProposal[0].id;
			cdl2.ContentDocumentId = documents[1].Id;
			cdl2.shareType = 'V';
			lstContentDocumentLink.add(cdl2);

			insert lstContentDocumentLink;
			
			Test.startTest();
			objDocumentCollateInfo01.Apttus_Proposal__RelatedAttachmentId__c = objAttachment01.Id;
			objDocumentCollateInfo02.Apttus_Proposal__RelatedAttachmentId__c = objAttachment02.Id;
			update listDocumentCollateInfo;
			Test.stopTest();
			
			List<Attachment> listAttachmet = [SELECT Id FROM Attachment where ParentId = :objProposal01.Apttus_Proposal__Opportunity__c];
			System.assert(!listAttachmet.isEmpty(), 'Attachment were not synced to Opp');
		}
	}

    
	/**DCP-38809
	*	@author Akshay Mohan
	*	@description Test method for DCP-38809 functionality to copy doc to work order
	**/
	@isTest
	public static void testWorkOrderCopy(){
		SVMXC__Service_Order__c workOrder = [Select Id FROM SVMXC__Service_Order__c LIMIT 1];

		Apttus_Proposal__Proposal__c proposal = [SELECT Id, Apttus_Proposal__Opportunity__c FROM Apttus_Proposal__Proposal__c LIMIT 1];
		proposal.Work_Order__c=workOrder.id;
		update proposal;

		Attachment objAttachment01 = getAttachment(proposal.Id
														, 'Test_Proposal_Attachment WO'
														, 'Test Body WO');

		Attachment objAttachment02 = getAttachment(proposal.Id
														, 'Test Proposal WO.pdf'
														, 'Test Body WO');

		List<Attachment> listAttachment = new List<Attachment> {objAttachment01
																, objAttachment02};
		insert listAttachment;

		Apttus_Proposal__DocumentCollateInfo__c objDocumentCollateInfo01 = new Apttus_Proposal__DocumentCollateInfo__c();
		objDocumentCollateInfo01.Name = 'Test';
		objDocumentCollateInfo01.Apttus_Proposal__ProposalId__c = proposal.Id;

		Apttus_Proposal__DocumentCollateInfo__c objDocumentCollateInfo02 = new Apttus_Proposal__DocumentCollateInfo__c();
		objDocumentCollateInfo02.Name = 'Test2';
		objDocumentCollateInfo02.Apttus_Proposal__ProposalId__c = proposal.Id;
		
		List<Apttus_Proposal__DocumentCollateInfo__c> listDocumentCollateInfo = new List<Apttus_Proposal__DocumentCollateInfo__c> {objDocumentCollateInfo01
			, objDocumentCollateInfo02};

		insert listDocumentCollateInfo;

		List<ContentVersion> lstContentVersion = new List<ContentVersion>();
		ContentVersion contentVersion = new ContentVersion(
		Title = 'Penguins',
		PathOnClient = 'Penguins.jpg',
		VersionData = Blob.valueOf('Test Content'),
		IsMajorVersion = true
		);
		lstContentVersion.add(contentVersion);

		ContentVersion contentVersion2 = new ContentVersion(
		Title = 'Test_Proposal_Attachment',
		PathOnClient = 'Penguins.jpg',
		VersionData = Blob.valueOf('Test Content'),
		IsMajorVersion = true
		);
		lstContentVersion.add(contentVersion2);

		insert lstContentVersion; 

		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 2];

		//create ContentDocumentLink  record 
		List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = proposal.id;
		cdl.ContentDocumentId = documents[0].Id;
		cdl.shareType = 'V';
		lstContentDocumentLink.add(cdl);

		ContentDocumentLink cdl2 = New ContentDocumentLink();
		cdl2.LinkedEntityId = proposal.id;
		cdl2.ContentDocumentId = documents[1].Id;
		cdl2.shareType = 'V';
		lstContentDocumentLink.add(cdl2);

		insert lstContentDocumentLink;
		
		Test.startTest();
		objDocumentCollateInfo01.Apttus_Proposal__RelatedAttachmentId__c = objAttachment01.Id;
		objDocumentCollateInfo02.Apttus_Proposal__RelatedAttachmentId__c = objAttachment02.Id;
		update listDocumentCollateInfo;
		Test.stopTest();

		List<ContentDocumentLink> lstWOCDLs= [SELECT Id,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:workOrder.id];
		System.assertEquals(1,lstWOCDLs.size(),'Incorrect files linked to Work order');
	}



	/**
	*	@author Milan Savaliya
	*	@description getAttachment
	**/
	public static Attachment getAttachment(Id parentId, String name, String body) {
		Attachment objAttachment = new Attachment();
		objAttachment.ParentId  = parentId;
		objAttachment.Name	= name;
		objAttachment.Body	= Blob.valueOf(body);
		return objAttachment;
	}
}
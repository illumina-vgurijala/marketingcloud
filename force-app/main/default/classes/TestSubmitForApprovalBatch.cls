/**
* @author Dushyant Srivastava
* @date   2022-02-22
* @description    DCP-52265: Fixes for Signatures coming in as Attachment.
*/

@isTest(isParallel=false)
public with sharing class TestSubmitForApprovalBatch {
    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.getNewAccount();
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        update acc;
        
        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();
        
        Id pricebookId = standardPricebook.id;

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(acc);
        objOpportunity.Pricebook2Id = pricebookId;
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Name = 'Direct Standard Opty Test';
        
        insert objOpportunity;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, objOpportunity.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert proposal;

        Apttus_Approval__Approval_Process__c objProcess = TestDataApprovalProcess.getApprovalProcess();

        Apttus_Approval__ApprovalProcessInstance__c objApprovalProcessInstance = new Apttus_Approval__ApprovalProcessInstance__c();
        objApprovalProcessInstance.Name = 'Quote Approval Process';
        objApprovalProcessInstance.Apttus_Approval__BusinessObjectType__c = 'Apttus_Proposal__Proposal__c';
        objApprovalProcessInstance.Apttus_Approval__BusinessObjectId__c = proposal.id;
        objApprovalProcessInstance.Apttus_Approval__ApprovalProcessId__c = objProcess.Id;
        objApprovalProcessInstance.Apttus_Approval__AssignmentEmailTemplate__c = 'test';
        objApprovalProcessInstance.Apttus_Approval__ReassignmentEmailTemplate__c = 'test';
        objApprovalProcessInstance.Apttus_Approval__EscalationEmailTemplate__c = 'test';
        objApprovalProcessInstance.Apttus_Approval__NotifyOnlyEmailTemplate__c = 'test';
        objApprovalProcessInstance.Apttus_Approval__CancellationEmailTemplate__c = 'test';
        insert objApprovalProcessInstance;
        
        Apttus_Approval__Approval_Request__c objApprovalRequest = TestDataProposal.initApprovalRequest(proposal.Id);
        objApprovalRequest.Apttus_Approval__Step_Name__c = Label.ApprovalStepNameTransregionLeadership;
        objApprovalRequest.Apttus_Approval__Object_Id__c = proposal.Id;
        objApprovalRequest.Apttus_Approval__ProcessInstanceId__c = objApprovalProcessInstance.Id;
        insert objApprovalRequest;
    }
    /**
    *  @author Dushyant Srivastava
    *  @description Test method for SubmitForApprovalBatch Class
    **/    
    @isTest
    static void testSubmitForApproval()
    {   
        EmailTemplate objEmailTemplate = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId() , TemplateType= 'Text', Name = 'test'); 
        insert objEmailTemplate;
        Test.startTest();
            Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c Limit 1];
            ilib_BatchManager.executeBatch(new SubmitForApprovalBatch(objProposal.Id), 1);
            List<Apttus_Approval__Approval_Request__c> testList = [Select id FROM Apttus_Approval__Approval_Request__c LIMIT 49999];
            system.assertEquals(1, testList.size(), 'Attachment count');
        Test.stopTest();
    }
}
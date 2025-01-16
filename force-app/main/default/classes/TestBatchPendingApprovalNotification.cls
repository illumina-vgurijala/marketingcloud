/**
*    @author Anish pathak
*    @date   30 August 2021
*    @description  DCP-46934: Pending Approval Notifications
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*
*/
@isTest(SeeAllData=false isParallel=false)
public with sharing class TestBatchPendingApprovalNotification {
      /**
     *  @author Anish Pathak
     *  @description Test Data Setup
     **/
    @testSetup
    static void setupData()
    {
        User testUser = TestDataUser.findUserInProfile('System Administrator');
        Account acc = TestDataAccount.initAccount();
        Account acc2 = TestDataAccount.initAccount();
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
       insert new List<Contact> { con, con2 };
      
           
        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Pricebook2Id = standardPricebook.Id;
        opp.Price_List__c = '01-AMR-USD';
        insert opp;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        String strDraft = 'In Review';
        String strNone = 'None';

        Apttus_Proposal__Proposal__c oProposal = TestDataProposal.initProposal(acc.Id, opp.Id, 'Test Proposal', priceList.Id, true, strDraft, strNone);
        insert oProposal;
        Apttus_Approval__Approval_Request__c oApprovalRequest = TestDataProposal.initApprovalRequest(oProposal.Id);
        oApprovalRequest.Apttus_Approval__Approval_Status__c = 'Assigned';
        oApprovalRequest.OwnerId = testUser.id;
        Insert oApprovalRequest;
        




       
        
        
    }

    @istest
    static void recallApproval()
    {
        Apttus_Proposal__Proposal__c objProposal = [SELECT Id,Apttus_Proposal__Proposal_Name__c FROM Apttus_Proposal__Proposal__c Where Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        Apttus_Approval__Approval_Request__c oApprovalReq = [SELECT ID,Apttus_Approval__Approval_Status__c FROM Apttus_Approval__Approval_Request__c Where Apttus_QPApprov__ProposalId__c =: objProposal.id ];

        Test.startTest();
            BatchPendingApprovalNotification oNotificationBatch = new BatchPendingApprovalNotification();
            Database.executeBatch(oNotificationBatch);
            System.AssertEquals('Assigned',oApprovalReq.Apttus_Approval__Approval_Status__c,'No match found');

        Test.stopTest();
    }

}
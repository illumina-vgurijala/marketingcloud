/**
*    @author Illumina
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Nesar Mohan                  20-Jun-2022         DCP-53207 Test Class for ApprovalRequestAfterUpdateQueueable and ApttusApprovalRequestsHelper
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestApttusApprovalAfterInsertQueueable {

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to insert and Update ApttusApprovalRequestRecords
    *  @PARAM :         None
    *  @RETURN:         void
    */

    @isTest static void createApttusRequestRecords() {
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.BillingCountryCode = 'US';
        objAccount.Territory_Region__c = 'AMR';
        objAccount.CurrencyIsoCode = 'USD';
        objAccount.Country_Local__c = 'USA';
        objAccount.OwnerId = UserInfo.getUserId();
        insert objAccount;

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = priceList.Name;
        objOpportunity.Type = System.Label.OpportunityTypeConsortium;
        insert objOpportunity;

        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(objAccount.Id, objOpportunity.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        // add record
        Apttus_Approval__Approval_Request__c rec1 = TestDataProposal.initApprovalRequest(quote1.Id);        
        rec1.Apttus_Approval__Assigned_To_Name__c = 'AMR Legal';
        rec1.Apttus_Approval__Step_Name__c = 'Open Offer Review';
        rec1.Apttus_Approval__Object_Type__c = 'Apttus_Proposal__Proposal__c';
        rec1.Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_USER;
        rec1.Apttus_Approval__Approver_Comments__c='Approved with comments - tester Approver comments - test 2022-03-07 12:08:38-0500';
        rec1.Apttus_Approval__Approval_Status__c = 'Assigned';
        rec1.Apttus_QPApprov__ProposalId__c = quote1.Id;
        insert rec1;
        
        Test.startTest();
             List<Apttus_Approval__Approval_Request__c> rec = [Select Id,Apttus_Approval__Approval_Status__c from Apttus_Approval__Approval_Request__c limit 1 ];
             rec[0].Apttus_Approval__Approval_Status__c = 'Reassigned';
             update rec;
        Test.stopTest();

        List<Apttus_Proposal__Proposal__c> lstQuoteRecords = [Select Id,Open_Offer_Legal_Approver_Comments__c from Apttus_Proposal__Proposal__c LIMIT 1]; // query after update
        System.assertEquals('test', lstQuoteRecords[0].Open_Offer_Legal_Approver_Comments__c,'Failed to Update Comments'); // ensure that correct comment is added.
    }
}

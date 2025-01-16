/**
*    @author Vinay S Reddy
*    @date   2023-12-10
*    @description    CMCM-1036   
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Descriptions
*             Vinay S Reddy                12 Oct 2023           Test class for Quote recall when opportunity stage changes to closed lost or closed abandoned
   ----------------------------------------------------------------------------------- 
*                    
*/
@isTest
public with sharing class TestOpportunityQuoteRecall {

    @isTest
    static void testOppQuote()
    {
       //Opportunity creation
        Account acc = TestDataAccount.getAccount('Test 1');
        String recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
        acc.RecordTypeId = recordtypeid;
        insert acc;

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        insert opp;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        String strDraft = 'Draft';
        String strNone = 'None';
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, strDraft, strNone);
        insert proposal;
        proposal.Apttus_Proposal__Approval_Stage__c='In Review';
        proposal.Apttus_QPApprov__Approval_Status__c='Pending Approval';
        update proposal;


        Test.startTest();
        Opportunity opp1=[Select Id,StageName,Account.Name from  Opportunity where Account.Name='Test 1'];
        opp1.StageName = 'Closed Lost';
        opp1.Competitor_Presence__c = 'No Competitor'; //Added by SB
        update opp1; 
        system.debug('Opportunity record is '+opp1);
        Test.stopTest();

        Apttus_Proposal__Proposal__c prop=[Select ID,Apttus_Proposal__Approval_Stage__c,Apttus_QPApprov__Approval_Status__c From Apttus_Proposal__Proposal__c Where Apttus_Proposal__Opportunity__c = :opp1.Id]; 
	     System.assertEquals('Cancelled',prop.Apttus_QPApprov__Approval_Status__c,'Proposal is not recalled'); 
        System.assertEquals('Draft',prop.Apttus_Proposal__Approval_Stage__c,'Proposal is not recalled');

}
    @isTest static void testOppQuote1(){
        boolean check=PEQuoteOpportunityTriggerHandler.methodToCheckQuotetoRecall('Pending',true);
        system.assertEquals(false,check,'Else block not executed');
}
}
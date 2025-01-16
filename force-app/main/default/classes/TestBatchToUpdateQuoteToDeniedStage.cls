/**
*	@author Adithi Acharya
*	@date	07-October-2022
*	@description	[DCP-56441] Test Class for Batch to update Invalid Quotes to Denied stage
*	Modification Log:
*	------------------------------------------------------------------------------------
*			Developer					Date				Description	
*           Adithi Acharya             07-October-2022      Initial Version
*	------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestBatchToUpdateQuoteToDeniedStage {
   
/**
   *	@author Adithi Acharya
   *	@description Execute method - Test to Update Invalid Quote Stage to Denied
**/
    static testMethod void testUpdateInvalidQuoteToDeniedStage(){
        Id userId = userinfo.getUserId();
        User u1 = [SELECT id from User WHERE id=:userId];
        system.runAs(u1){
            Account objAccount = TestDataAccount.getNewAccount();
            Apttus_Config2__PriceList__c pl = TestDataProposal.initPriceList('AMR-USD-US-01');
            insert pl;
            Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
            objOpportunity.Price_List__c = pl.Name;
            update objOpportunity;
            Apttus_Proposal__Proposal__c objProposal = TestDataProposal.getNewProposal(objAccount.Id, objOpportunity.Id, 'Test Invalid Proposal', pl.Id, true, 'Draft', 'None');
            objProposal.Invalid_Quote__c=true;
            update objProposal;
        
            Test.startTest();
            BatchToUpdateInvalidQuoteToDeniedStage objBatch=new BatchToUpdateInvalidQuoteToDeniedStage();
            Database.executeBatch(objBatch);
            Test.stopTest();
            Apttus_Proposal__Proposal__c objProposal1 =[SELECT id,Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Approval_Stage__c from Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c='Test Invalid Proposal'];
            System.assertEquals('Denied',objProposal1.Apttus_Proposal__Approval_Stage__c,'Quote Stage not moved to Denied');


        }
    }
}

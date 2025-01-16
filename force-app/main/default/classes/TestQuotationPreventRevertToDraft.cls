/**
*    @author Satya Swain
*    @date   20 Nov 2018
*    @description  Test class for QuotationPreventRevertToDraft
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*	  		 Satya Swain            	 20 Nov 2018       		Initial Version
*            
*/
@isTest(isParallel=false)
public class TestQuotationPreventRevertToDraft {

	/**
    * @Author Satya Swain
    * @description Setup method for QuotationPreventRevertToDraft
    **/
	@testSetup
    static void setupData(){
    			
    	Account objAcc = TestDataAccount.getNewAccount();
        
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceList;
        
        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAcc);
        objOpportunity.Ultimate_Consignee__c = objAcc.Id;
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Price_List__c = objPriceList.Name;
        update objOpportunity;
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAcc.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
        
        objOpportunity.StageName = 'Closed Abandoned';
        //objOpportunity.Abandon_Reason__c = 'No Budget';
        objOpportunity.Abandon_Reason__c = 'Other'; // CMCM-12621
        update objOpportunity;
	}
	/**
    * @Author Satya Swain
    * @description Test method for QuotationPreventRevertToDraft
    **/
	@isTest
    static void testCheckRevertToDraftPermissionForUser(){
    	
    	User objCurrentUser = [Select Id FROM User WHERE Id=:UserInfo.getUserId()];
    	new PermissionSetAssignmentsSelector().selectPermissionSetAssigmentByName('Test');
		PermissionSet ps = new PermissionSet();
        ps.Name = 'Testing_SL_Revert_To_Draft';
        ps.Label = 'Testing_SL_Revert_To_Draft';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'SL_Revert_To_Draft'][0].Id;
        insert sea;
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;
		system.runAs(objCurrentUser){  
            
	    	Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
            
	        Apttus_Proposal__Proposal__c objProposal = [Select Id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
	        
	        Test.startTest();	        	
	        QuotationPreventRevertToDraft.checkRevertToDraftPermissionForUser(objProposal.Id);  	         
	        Test.stopTest();
	        
	        System.assertEquals(true,QuotationPreventRevertToDraft.boolPermissionFound,'Custom Permission Assignment Incorrect');
     	}
    }
}

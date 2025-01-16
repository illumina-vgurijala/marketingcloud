/**
*    @author Rohan Chandarana
*    @date   2018-06-06
*    @description    Trigger for Proposal Line Item 
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*        Developer                      Date                Description
*        Rohan Chandarana               06 June 2018        Proposal Approvals Framework
*		 Gopesh Banker (Apttus)			19 Sept, 2018		adding after update, after delete arguments
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger ApttusProposalLineItemTrigger on Apttus_Proposal__Proposal_Line_Item__c (before insert, after insert, before update, after update,before delete,after delete,after undelete) {
    ilib_SObjectDomain.triggerHandler(ApttusProposalLineItems.class);
}
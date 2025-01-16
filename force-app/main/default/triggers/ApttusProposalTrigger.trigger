/**
*    @author Rohan Chandarana
*    @date   2018-05-27
*    @description    DCP-454: Create Quote - Ability to Clone Quote
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Rohan Chandarana               27 May 2018         Ability to Clone Quote
*             Miilan		 	             23 Oct 2018         Added After Insert Event to clone Opp Lines to cart
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger ApttusProposalTrigger on Apttus_Proposal__Proposal__c (before insert, after insert, before update, after update) {
    ilib_SObjectDomain.triggerHandler(ApttusProposals.class);
}
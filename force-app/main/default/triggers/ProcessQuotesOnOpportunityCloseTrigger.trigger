/**
*    @author Vinay S Reddy
*    @date   2023-12-10
*    @description    CMCM-1036 platform event trigger  
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Descriptions
*             Vinay S Reddy                12 Oct 2023           Platform Event Trigger
*  ----------------------------------------------------------------------------------- 
*                    
*/

trigger ProcessQuotesOnOpportunityCloseTrigger on ProcessQuotesOnOpportunityClose__e (after insert){

    ilib_SObjectDomain.triggerHandler(PEQuoteOpportunityTriggerHandler.class);

}

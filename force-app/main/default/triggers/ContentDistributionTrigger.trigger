/**
* @author: Abhishek Yadav
* @date Dec-2024
* @group ContentDistribution
* @description Trigger Handler on ContentDistribution used to handle the functionality when user triggers an event.
* Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*       Abhishek Yadav    13-Dec-2024       Initial Version. CMCM-12619: Prevent Deletion of recall related Files
*    -----------------------------------------------------------------------------------------------------------------------------------
*/
trigger ContentDistributionTrigger on ContentDistribution (before insert) {
    ilib_SObjectDomain.triggerHandler(ContentDistributions.class);
}
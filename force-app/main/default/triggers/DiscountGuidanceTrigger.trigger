/**
 *    @author Lovel Panchal
 *    @date   07-May-2024
 *    @description  Controller class for discountgrid LWC component
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Lovel Panchal             07-May-2024            Trigger for Discount Guidance Object before update and before insert 
 *    ------------------------------------------------------------------------------------ 
 *                       
 */
trigger DiscountGuidanceTrigger on Discount_Guidance__c (before insert, before update) {
        ilib_SObjectDomain.triggerHandler(DiscountGuidanceTriggerHandler.class);
}
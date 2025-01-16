/**
*    @author: Deep Diwakar
*    @date:   March-08-2023
*    @description:  No Charge Marketing Order Product Trigger
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*           Deep Diwakar                  March-08-2023      DCP-59580: Adding after insert and after delete
*    ------------------------------------------------------------------------------------ 
*                    
*/

trigger NoChargeMarketingOrderProductTrigger on No_Charge_Marketing_Order_Product__c (after insert, after delete) {
    ilib_SObjectDomain.triggerHandler(NoChargeMarketingOrderProducts.class);
}
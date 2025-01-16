/**
*    @author: Govind Dubey
*    @date:   20th Aug 2018
*    @description:  Lock Quantity for Professional Services & Service Contracts Products for DCP-1063
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey               20th Aug 2018          Add Price list items for Locking Quantity of Professional Services & Service Contracts Products
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger PriceListItemTrigger on Apttus_Config2__PriceListItem__c (before insert,before update) {
    
        ilib_SObjectDomain.triggerHandler(PriceListItems.class);
    
}
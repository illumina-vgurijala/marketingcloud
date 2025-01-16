/**
*    @author 
*    @date   2018-07-16
*    @description    DCP-905: Trigger for Installed Products
*    Modification Log:
*    ------------------------------------------------------------------------------------
*            Developer                      Date                Description
*            
*    ------------------------------------------------------------------------------------ 
*                    
*/
trigger InstalledProductTrigger on SVMXC__Installed_Product__c (before insert, after insert,before update, after update) {
    
      ilib_SObjectDomain.triggerHandler(InstalledProducts.class);
    
}
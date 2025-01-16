@isTest
/***************************************************************************************************************************************
* NAME   : SVMX_PS_VS_VanStockHookHandler_UT 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
private class SVMX_PS_VS_VanStockHookHandler_UT{
    @isTest
    static void testHookForReturnedIPUpdate(){
        SVMXC__Installed_Product__c returnedIP = new SVMXC__Installed_Product__c();
        SVMX_PS_VS_VanStockHookHandler.hookForReturnedIPUpdate(returnedIP);
    }

    @isTest
    static void testHookForReturnedIPListUpdate(){
        List<SVMXC__Installed_Product__c>  returnedIPList = new List<SVMXC__Installed_Product__c>();
        SVMX_PS_VS_VanStockHookHandler.hookForReturnedIPListUpdate(returnedIPList);
    }
}
/******************************************************************************************************* 
    DESCRIPTION
        On WO closure process the Usage Consumption Lines and adjust the technician inventory. 
*******************************************************************************************************/

trigger SVMX_PS_VS_AfterUpdate_WOTrigger on SVMXC__Service_Order__c (after update) {
    
    if(trigger.isAfter){
        if(trigger.isUpdate){
            SVMX_PS_VS_VanStockUtility vanstockUtility = new SVMX_PS_VS_VanStockUtility();
            if(vanstockUtility.isPartConsumptionActive != null && vanstockUtility.isPartConsumptionActive 
                && vanstockUtility.isPerformStockUsingBatch != null && !vanstockUtility.isPerformStockUsingBatch){
                vanstockUtility.performVanStockManagement(trigger.new, trigger.oldMap);
            }else{
                System.debug('Van Stock is being perfomed using Batch');
            }
        }
    }
}
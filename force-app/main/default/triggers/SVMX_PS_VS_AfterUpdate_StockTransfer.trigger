trigger SVMX_PS_VS_AfterUpdate_StockTransfer on SVMXC__Stock_Transfer__c (after update) {

    if(trigger.isAfter){
        if(trigger.isUpdate){
            SVMX_PS_VS_VanStockTransferUtility vanStockTransferUtility = new SVMX_PS_VS_VanStockTransferUtility();
            if(vanStockTransferUtility.isStockTransferActive != null && 
                vanStockTransferUtility.isStockTransferActive){
                if(vanStockTransferUtility.isPerformStockTransferUsingBatch != null &&
                    !vanStockTransferUtility.isPerformStockTransferUsingBatch){
                    vanStockTransferUtility.performStockTransfer(trigger.new);
                }else{
                    System.debug('Stock Transfer Functionality is performed using batch.');
                }
            }else{
                System.debug('Stock Transfer Functionality is not active.');
            }
        }
    }
}
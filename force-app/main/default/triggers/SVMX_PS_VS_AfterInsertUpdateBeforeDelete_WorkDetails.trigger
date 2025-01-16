trigger SVMX_PS_VS_AfterInsertUpdateBeforeDelete_WorkDetails on SVMXC__Service_Order_Line__c (before delete, after insert, after update) {
    if(Trigger.isAfter){
        System.debug('VanStockAllocatedQtyHandler : Start Allocated Qty Handler');
        SVMX_PS_VS_VanStockAllocateQtyUtility vanStockAllocateQtyHandler = new SVMX_PS_VS_VanStockAllocateQtyUtility();
        if(Trigger.isInsert){
            System.debug('VanStockAllocatedQtyHandler : handle insertion of work details');
            vanStockAllocateQtyHandler.handleAllocatedQtyForWorkDetailsCreation(trigger.new);
            System.debug('VanStockAllocatedQtyHandler : done with insertion of work details');
        }

        if(Trigger.isUpdate){
            System.debug('VanStockAllocatedQtyHandler : handle updation of work details');
            vanStockAllocateQtyHandler.handleAllocatedQtyForWorkDetailsUpdation(trigger.new, trigger.oldMap);
            System.debug('VanStockAllocatedQtyHandler : done with updation of work details');
        }
    }

    if(Trigger.isBefore){
        System.debug('VanStockAllocatedQtyHandler : Start Allocated Qty Handler');
        SVMX_PS_VS_VanStockAllocateQtyUtility vanStockAllocateQtyHandler = new SVMX_PS_VS_VanStockAllocateQtyUtility();
        if(Trigger.isDelete){
            System.debug('VanStockAllocatedQtyHandler : handle deletion of work details');
            vanStockAllocateQtyHandler.handleAllocatedQtyForWorkDetailsDeletion(trigger.old);
            System.debug('VanStockAllocatedQtyHandler : handle deletion of work details');
        }
    }
}
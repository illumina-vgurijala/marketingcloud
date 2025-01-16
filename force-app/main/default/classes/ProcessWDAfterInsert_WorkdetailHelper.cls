/*****************************************************************************************************************
 * Class Name: ProcessWDBeforeInsert_WorkDetailHelper
 * 
 * Description: Helper class for processing work detail on before insert.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for processing work detail on before insert.
 * Dhairya Shah             17 April 2024                      CMCM-6760 - Removed the method -insertRelatedProductOnCase() 
 * 
 ******************************************************************************************************************/
public with sharing class ProcessWDAfterInsert_WorkdetailHelper {
    /**
     * Method:processWorkdetailsAfterInsert
     * Description: Process work detail records for after insert
     */
    public static void processWorkdetailsAfterInsert(List<SVMXC__Service_Order_Line__c> lstWorkDetails){
        Set < Id > setWDPartsIds = new Set < Id > (); // DCP-33467
        for (SVMXC__Service_Order_Line__c objWorkDetail: lstWorkDetails) {
           // DCP-33467 - Spare Parts Reservation 
            if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_PARTS_ORDER_LINE_STATUS) {
                setWDPartsIds.add(objWorkDetail.Id);
            } // DCP-33467
        }
        // DCP-33467    
        if (!setWDPartsIds.isEmpty()){
            createAllocatedStockRecords(setWDPartsIds);
        }
    }
    /*  
     *  @AUTHOR:  Sravan
     *  @DESCRIPTION: 33467 - Parts reservation by creating Allocated Stock records
     *  @PARAM :  Set of Work Details ids with Line type Parts after insert the WD
     *  @RETURN:  void
     */
           
    public static void createAllocatedStockRecords(set < Id > setIdtoSpareWd) {
        List < SVMXC__Allocated_Stock__c > insertAllocatatedStocts = new List < SVMXC__Allocated_Stock__c > ();
        if(!setIdtoSpareWd.isEmpty()){
            for (SVMXC__Service_Order_Line__c wd: new WorkDetailsSelector().selectWDWithLineTypeParts(setIdtoSpareWd)) {
                SVMXC__Allocated_Stock__c allocatedStock = new SVMXC__Allocated_Stock__c();
                allocatedStock.SVMXC__Allocated_Qty__c = wd.SVMXC__Actual_Quantity2__c;
                allocatedStock.Work_Order__c = wd.SVMXC__Service_Order__c;
                allocatedStock.SVMX_PS_VS_Work_Detail__c = wd.id;
                allocatedStock.SVMXC__Product_Stock__c = wd.SVMX_PS_VS_Consumed_Product_Stock__c;
                if (wd.SVMX_PS_VS_Consumed_Stocked_Serial__c != null) {
                    allocatedStock.SVMX_PS_VS_Stocked_Serial__c = wd.SVMX_PS_VS_Consumed_Stocked_Serial__c;
                } else if (wd.Batch_Lookup__c != null) {
                    allocatedStock.SVMX_PS_VS_Stocked_Serial__c = wd.Batch_Lookup__c;
                }
                allocatedStock.Product__c = wd.SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__c;
                allocatedStock.Location__c = wd.SVMXC__Consumed_From_Location__c;
                allocatedStock.Batch_Number__c = wd.Batch_Number__c;
                insertAllocatatedStocts.add(allocatedStock);
            }
            
        }
        if(!insertAllocatatedStocts.isEmpty()){
            insert insertAllocatatedStocts;
        }
        
    }
}
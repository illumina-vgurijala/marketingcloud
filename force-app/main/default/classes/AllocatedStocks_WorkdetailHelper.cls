/*****************************************************************************************************************
 * Class Name: AllocatedStocks_WorkdetailHelper
 * 
 * Description: Helper class for processing allocated stocks.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for processing allocated stocks.
 * 
 ******************************************************************************************************************/
public with sharing class AllocatedStocks_WorkdetailHelper {
    /*
    *  @AUTHOR:  Sravan
    *  @DESCRIPTION: 33467 - Update the related allocated stocks when update the debrief line
    *  @PARAM :  WorkDetail object set, WorkDetail id set
    *  @RETURN:  void
    */
    public static void updateAllocatedStocks(Set <SVMXC__Service_Order_Line__c> setWorkDetailsParts, Set <Id> setWorkDetailsPartsIds){
        System.debug('entered updateAllocatedStocks-->');
        if(!setWorkDetailsParts.isEmpty() && !setWorkDetailsPartsIds.isEmpty()){
            map<Id,SVMXC__Allocated_Stock__c> mapAllocatedStocks = new map<Id,SVMXC__Allocated_Stock__c>();
            for(SVMXC__Allocated_Stock__c als : new AllocatedStocksSelector().selectAllocatedStockWithWd(setWorkDetailsPartsIds)){
                mapAllocatedStocks.put(als.SVMX_PS_VS_Work_Detail__c,als);
            }
            List<SVMXC__Allocated_Stock__c> lstUpdateAllocatedStocks = new List<SVMXC__Allocated_Stock__c>();
            for(SVMXC__Service_Order_Line__c wd : setWorkDetailsParts){
                if(mapAllocatedStocks.containsKey(wd.id)){
                    SVMXC__Allocated_Stock__c als =  mapAllocatedStocks.get(wd.id);
                    als.SVMXC__Allocated_Qty__c = wd.SVMXC__Actual_Quantity2__c;
                    populateFields(wd, als);
                    als.Product__c = wd.SVMXC__Product__c;
                    als.Location__c = wd.SVMXC__Consumed_From_Location__c;
                    als.Batch_Number__c = wd.Batch_Number__c;
                    lstUpdateAllocatedStocks.add(als);
                }
            }
            if(!lstUpdateAllocatedStocks.isEmpty()){
                update lstUpdateAllocatedStocks;
            }
        }
    } // DCP-33467
    /*
    *  @AUTHOR:  Sravan
    *  @DESCRIPTION:DCP-33467 - Delete Allocated Stock if a related work detail got deleted/canceled
    *  @PARAM :  set<Id> setCanceledWdPSId - set of canceled wd Ids. 
    *  @RETURN:  void
    */ 
    public static void deleteAllocatedStockRecords(set<Id> setCanceledOrDeletedWdIds){
        List<SVMXC__Allocated_Stock__c> lstAllocatedStock = new AllocatedStocksSelector().selectAllocatedStockWithWd(setCanceledOrDeletedWdIds);            
        if(!lstAllocatedStock.isEmpty()){
            delete lstAllocatedStock;
        }
    }
    /*
    *  @AUTHOR:  Sravan
    *  @DESCRIPTION:DCP-33467 - populate Allocated Stock from a related work detail
    *  @PARAM :  work detail, allocated stock. 
    *  @RETURN:  void
    */ 
    public static SVMXC__Allocated_Stock__c populateFields(SVMXC__Service_Order_Line__c wd, SVMXC__Allocated_Stock__c als){
        if(wd.SVMX_PS_VS_Consumed_Stocked_Serial__c != null){
            als.SVMX_PS_VS_Stocked_Serial__c = wd.SVMX_PS_VS_Consumed_Stocked_Serial__c;
        }else if(wd.Batch_Lookup__c != null){
            als.SVMX_PS_VS_Stocked_Serial__c = wd.Batch_Lookup__c;
        }
        return als;
    }
}
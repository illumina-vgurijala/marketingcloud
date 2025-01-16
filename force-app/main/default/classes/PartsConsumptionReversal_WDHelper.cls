/*****************************************************************************************************************
 * Class Name: PartsConsumptionReversal_WDHelper
 * Description: helper class to update the work details.
 * Author: Prashanth
 * 
 * Date: 06-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth               06-12-2021        Queueable class to update warning message on the work order.
 ******************************************************************************************************************/
public with sharing class PartsConsumptionReversal_WDHelper implements queueable{
    Map < Id, SVMXC__Service_Order_Line__c > workDetailIdToWorkDetailMap = new Map<Id, SVMXC__Service_Order_Line__c>();
    //DCP-44981
    public static List < SVMXC__Product_Serial__c > listStockedSerialFinalUpdate = new List < SVMXC__Product_Serial__c > ();
    public static List < SVMXC__Service_Order_Line__c > listFinalWorkDetailUpdate = new List < SVMXC__Service_Order_Line__c > ();
    public static List < SVMXC__Product_Stock__c > listProductStockFinalUpdate = new List < SVMXC__Product_Stock__c > ();
    public static List < SVMXC__Product_Stock__c > listFilteredProductStockFinalUpdate = new List < SVMXC__Product_Stock__c > ();
    public static List < SVMXC__Installed_Product__c > listInstalledProductFinalUpdate = new List < SVMXC__Installed_Product__c > ();
    public static Map<Id, SVMXC__Service_Order_Line__c> installedProductIdToWorkDetailFinalMap = new Map<Id, SVMXC__Service_Order_Line__c>();
    public static Map<Id, SVMXC__Site__c> consumedFromLocationIdToLocationMap;
    public static Map < Id, SVMXC__Service_Order_Line__c > serializedWorkDetailIdToWorkDetailMap = new Map < Id, SVMXC__Service_Order_Line__c > ();
    public static Map < Id, SVMXC__Service_Order_Line__c > batchWorkDetailIdToWorkDetailMap = new Map < Id, SVMXC__Service_Order_Line__c > ();
    public static Map < Id, SVMXC__Service_Order_Line__c > nontrackedWorkDetailIdToWorkDetailMap = new Map < Id, SVMXC__Service_Order_Line__c > ();

    public static Map < String, SVMXC__Service_Order_Line__c > partNumberToWorkDetailMap = new Map < String, SVMXC__Service_Order_Line__c > ();
    public static Map < Id, SVMXC__Product_Serial__c > erroredStockedSerialProductStockIdsMap = new Map < Id, SVMXC__Product_Serial__c >();
    public static final String STRING_NON_TRACKED = 'Non-Tracked';
    /**
     * Constructor
     */
    public PartsConsumptionReversal_WDHelper(Map < Id, SVMXC__Service_Order_Line__c > workDetailIdToWorkDetailMap) {
        this.workDetailIdToWorkDetailMap = workDetailIdToWorkDetailMap;
    }
    /*
    *  @AUTHOR:  Vaibhav
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process
    *  @PARAM :  
    *  @RETURN:  void
    */
    public void execute(QueueableContext qc){
        initiatePartConsumptionReversalProcess(workDetailIdToWorkDetailMap);
    }
     /*
    *  @AUTHOR:  Vaibhav
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process
    *  @PARAM :  
    *  @RETURN:  void
    */
    public static void initiatePartConsumptionReversalProcess(Map < Id, SVMXC__Service_Order_Line__c > workDetailIdToWorkDetailMap) {

        Map < Id, SVMXC__Product_Stock__c > finalProductStockIdToProductStockMap;
        Map < Id, SVMXC__Product_Serial__c > finalStockedSerialIdToStockedSerialMap;
        
            
        populateMaps(workDetailIdToWorkDetailMap);
        if (!serializedWorkDetailIdToWorkDetailMap.isEmpty()) {
            AdjustInventory_WorkdetailHelper.adjustSerializedOrNonTrackedInventory(serializedWorkDetailIdToWorkDetailMap, Workdetails.PRODUCT_TRACKING_SERIALIZED);
            AdjustSerializedPart_WorkdetailHelper.adjustInstalledProductForSerializedPart(serializedWorkDetailIdToWorkDetailMap, Workdetails.PRODUCT_TRACKING_SERIALIZED);
        }

        if (!batchWorkDetailIdToWorkDetailMap.isEmpty()) {
            AdjustInventory_WorkdetailHelper.adjustBatchInventory(batchWorkDetailIdToWorkDetailMap);
        }

        if (!nontrackedWorkDetailIdToWorkDetailMap.isEmpty()) {
            AdjustInventory_WorkdetailHelper.adjustSerializedOrNonTrackedInventory(nontrackedWorkDetailIdToWorkDetailMap, 'Non Tracked');
        }

        //reparent stocked serial update
        if (!listStockedSerialFinalUpdate.isEmpty()) {

            set<Id> setStockedSerialIds = new set<Id>();
            //get the ids of stocked 
            for(SVMXC__Product_Serial__c stockedSerial : listStockedSerialFinalUpdate){
                setStockedSerialIds.add(stockedSerial.id);
            }
            
            finalStockedSerialIdToStockedSerialMap = new Map < Id, SVMXC__Product_Serial__c > (new StockedSerialSelector().selectStockedSerialById(setStockedSerialIds));
            updateStockedSerials(workDetailIdToWorkDetailMap,finalStockedSerialIdToStockedSerialMap);

        }

        //update product stock
        if(!listProductStockFinalUpdate.isEmpty()){
            //remove the product stocks for which stocked serial was errored out
            for(SVMXC__Product_Stock__c prodStock : listProductStockFinalUpdate){
                if(!erroredStockedSerialProductStockIdsMap.containskey(prodStock.Id)){
                    listFilteredProductStockFinalUpdate.add(prodStock);
                }
            }
            finalProductStockIdToProductStockMap = new Map < Id, SVMXC__Product_Stock__c > (listFilteredProductStockFinalUpdate);
            updateProductStocks(workDetailIdToWorkDetailMap,finalProductStockIdToProductStockMap);
        }

        //Update IP for serialized part.
        if (!listInstalledProductFinalUpdate.isEmpty()) {
            updateInstalledProduct(workDetailIdToWorkDetailMap);
        }

        updateWorkdetails(listFinalWorkDetailUpdate);

    }
    /*
    *  @AUTHOR:  Vaibhav
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process
    *  @PARAM :  
    *  @RETURN:  void
    */
    public static void updateStockedSerials(Map < Id, SVMXC__Service_Order_Line__c > workDetailIdToWorkDetailMap, Map <Id, SVMXC__Product_Serial__c > finalStockedSerialIdToStockedSerialMap){
        Database.SaveResult[] srList = Database.update(listStockedSerialFinalUpdate, false);
        ApexExceptions.emitSaveErrors(srList, 'Stocked Serial update failed in WorkDetails.initiatePartConsumptionReversalProcess');

        for (Integer i = 0; i < srList.size(); i++) {
            if (srList.get(i).isSuccess()) {
                listFinalWorkDetailUpdate.add(new SVMXC__Service_Order_Line__c(Id = workDetailIdToWorkDetailMap.get(partNumberToWorkDetailMap.get(finalStockedSerialIdToStockedSerialMap.get(srList.get(i).Id).Product_Code__c).Id).Id, Part_Consumption_Reversal_Status__c = Workdetails.STRING_INTEGRATION_SUCCESS, SVMXC__Line_Status__c = 'Canceled'));
                } else if (!srList.get(i).isSuccess()) {
                //store the product stock id as it will not be qualified for update.
                erroredStockedSerialProductStockIdsMap.put(finalStockedSerialIdToStockedSerialMap.get(listStockedSerialFinalUpdate.get(i).Id).SVMXC__Product_Stock__c, finalStockedSerialIdToStockedSerialMap.get(listStockedSerialFinalUpdate.get(i).Id));
                listFinalWorkDetailUpdate.add(new SVMXC__Service_Order_Line__c(Id = workDetailIdToWorkDetailMap.get(partNumberToWorkDetailMap.get(finalStockedSerialIdToStockedSerialMap.get(listStockedSerialFinalUpdate.get(i).Id).Product_Code__c).Id).Id, Part_Consumption_Reversal_Status__c = 'Failed in SFDC: Stocked Serial Update Failed: Please contact your system administrator.',SVMXC__Line_Status__c = 'Closed'));
            }
        }
        
    }
    /*
    *  @AUTHOR:  Vaibhav
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process
    *  @PARAM :  
    *  @RETURN:  void
    */
    public static void populateMaps(Map < Id, SVMXC__Service_Order_Line__c > workDetailIdToWorkDetailMap){
        for (Id workDetailId: workDetailIdToWorkDetailMap.keyset()) {
            if (String.isNotBlank(workDetailIdToWorkDetailMap.get(workDetailId).Consumed_Part_Number__c)) {
                partNumberToWorkDetailMap.put(workDetailIdToWorkDetailMap.get(workDetailId).Consumed_Part_Number__c, workDetailIdToWorkDetailMap.get(workDetailId));
            }
            //filter out serialized, batch tracked, and non tracked work details from the list of WD's received.
            /* Serialized -  If we have a product stock and stock serial is populated */
            if (String.isNotBlank(workDetailIdToWorkDetailMap.get(workDetailId).SVMX_PS_VS_Consumed_Product_Stock__c) && String.isNotBlank(workDetailIdToWorkDetailMap.get(workDetailId).SVMX_PS_VS_Consumed_Stocked_Serial__c) && workDetailIdToWorkDetailMap.get(workDetailId).Product_Tracking__c == Workdetails.PRODUCT_TRACKING_SERIALIZED) {
                serializedWorkDetailIdToWorkDetailMap.put(workDetailId, workDetailIdToWorkDetailMap.get(workDetailId));
            } else if /* Batch tracked - If we have a product stock and batch number/batch lookup is populated. */ (String.isNotBlank(workDetailIdToWorkDetailMap.get(workDetailId).SVMX_PS_VS_Consumed_Product_Stock__c) && String.isNotBlank(workDetailIdToWorkDetailMap.get(workDetailId).Batch_Lookup__c) && workDetailIdToWorkDetailMap.get(workDetailId).Product_Tracking__c == 'Lot/Batch Tracked') {
                batchWorkDetailIdToWorkDetailMap.put(workDetailId, workDetailIdToWorkDetailMap.get(workDetailId));
            } else if(workDetailIdToWorkDetailMap.get(workDetailId).Product_Tracking__c == STRING_NON_TRACKED)/* Non tracked */ {
                nontrackedWorkDetailIdToWorkDetailMap.put(workDetailId, workDetailIdToWorkDetailMap.get(workDetailId));
            }   
        }
    }
    /*
    *  @AUTHOR:  Vaibhav
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process
    *  @PARAM :  
    *  @RETURN:  void
    */
    public static void updateProductStocks(Map < Id, SVMXC__Service_Order_Line__c > workDetailIdToWorkDetailMap ,Map < Id, SVMXC__Product_Stock__c > finalProductStockIdToProductStockMap){
        Database.SaveResult[] result = Database.update(listFilteredProductStockFinalUpdate, false);
        ApexExceptions.emitSaveErrors(result, 'Product stock update failed in WorkDetails.initiatePartConsumptionReversalProcess');
        for (Integer i = 0; i < result.size(); i++) {
            if (result.get(i).isSuccess()) {
                listFinalWorkDetailUpdate.add(new SVMXC__Service_Order_Line__c(Id = workDetailIdToWorkDetailMap.get(partNumberToWorkDetailMap.get(finalProductStockIdToProductStockMap.get(result.get(i).Id).Product_Code__c).Id).Id, Part_Consumption_Reversal_Status__c = Workdetails.STRING_INTEGRATION_SUCCESS, SVMXC__Line_Status__c = 'Canceled'));
            } else if (!result.get(i).isSuccess()) {
                listFinalWorkDetailUpdate.add(new SVMXC__Service_Order_Line__c(Id = workDetailIdToWorkDetailMap.get(partNumberToWorkDetailMap.get(finalProductStockIdToProductStockMap.get(listFilteredProductStockFinalUpdate.get(i).Id).Product_Code__c).Id).Id, Part_Consumption_Reversal_Status__c = 'Failed in SFDC: Product Stock Update Failed: Please contact your system administrator.',SVMXC__Line_Status__c = 'Closed'));
            }
        }
    }
    /*
    *  @AUTHOR:  Vaibhav
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process
    *  @PARAM :  
    *  @RETURN:  void
    */
    public static void updateInstalledProduct(Map < Id, SVMXC__Service_Order_Line__c > workDetailIdToWorkDetailMap){
        if(!listInstalledProductFinalUpdate.isEmpty()){
            Database.SaveResult[] resultIP = Database.update(listInstalledProductFinalUpdate, false);
            ApexExceptions.emitSaveErrors(resultIP, 'Installed Product update failed in WorkDetails.initiatePartConsumptionReversalProcess');
            for (Integer i = 0; i < resultIP.size(); i++) {
                if (resultIP.get(i).isSuccess()) {
                    listFinalWorkDetailUpdate.add(new SVMXC__Service_Order_Line__c(Id = workDetailIdToWorkDetailMap.get(installedProductIdToWorkDetailFinalMap.get(listInstalledProductFinalUpdate.get(i).Id).Id).Id, Part_Consumption_Reversal_Status__c = Workdetails.STRING_INTEGRATION_SUCCESS, SVMXC__Line_Status__c = 'Canceled'));
                    } else if (!resultIP.get(i).isSuccess()) {
                    listFinalWorkDetailUpdate.add(new SVMXC__Service_Order_Line__c(Id = workDetailIdToWorkDetailMap.get(installedProductIdToWorkDetailFinalMap.get(listInstalledProductFinalUpdate.get(i).Id).Id).Id, Part_Consumption_Reversal_Status__c = 'Failed in SFDC: Installed Product Update Failed: Please contact your system administrator.',SVMXC__Line_Status__c = 'Closed'));
                }
            }
        }
    }
    /*
    *  @AUTHOR:  Vaibhav
    *  @DESCRIPTION: DCP-44981 - Parts Consumption Reversal Process
    *  @PARAM :  
    *  @RETURN:  void
    */
    public static void updateWorkdetails(List < SVMXC__Service_Order_Line__c > listFinalWorkDetailUpdate){
        Map < Id, SVMXC__Service_Order_Line__c > uniqueWorkDetailIdToWorkDetailMap = new Map < Id, SVMXC__Service_Order_Line__c >();
        //final update on workDetail with success/error messages
        if (!listFinalWorkDetailUpdate.isEmpty()) {
            for (SVMXC__Service_Order_Line__c wD: listFinalWorkDetailUpdate) {
                uniqueWorkDetailIdToWorkDetailMap.put(wD.Id, wD);
            }
            
            Database.SaveResult[] workDetailUpdate = Database.update(uniqueWorkDetailIdToWorkDetailMap.values(),false);
            ApexExceptions.emitSaveErrors(workDetailUpdate, 'Work Detail update failed in WorkDetails.initiatePartConsumptionReversalProcess');
        }
    }

}
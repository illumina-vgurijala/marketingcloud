/***************************************************************************************************************************************
* NAME   : StockTransfer
* DESCRIPTION  : Domain class for StockTransferTrigger.
*                    
* @AUTHOR : Vaibhav
* @DATE   : 21-Oct-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class StockTransfers extends ilib_SObjectDomain {


		/*
         * Constructor
         */
    public StockTransfers(List < SVMXC__Stock_Transfer__c > sObjectList) {
        super(sObjectList);
    }

    /*
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
	/*Param - sobjectList  */
        public ilib_SObjectDomain construct(List < SObject > sObjectList) {
            return new StockTransfers(sObjectList);
        }
    }

    /**
     *  @author Vaibhav Parashar
     *  @description - To be executed, when the stock transfer is updated. 
     *               
     **/
    public override void onAfterUpdate(Map < Id, SObject > oldRecords) {
        //Stock Transfer SVMX To SAP
        //set of stock transfer ids.
        set < Id > setStockTransferId = new set < Id > ();

        for (Id idStockTransfer: oldRecords.keySet()) {

            //new instance   
            SVMXC__Stock_Transfer__c objNewStockTransfer = (SVMXC__Stock_Transfer__c) Trigger.newMap.get(idStockTransfer);
            //old instance
            SVMXC__Stock_Transfer__c objOldStockTransfer = (SVMXC__Stock_Transfer__c) oldRecords.get(idStockTransfer);

            //conditions to check on stock transfer fields.
            if (objNewStockTransfer.SVMXC__Not_Posted_Item_Count__c != objOldStockTransfer.SVMXC__Not_Posted_Item_Count__c && objNewStockTransfer.SVMXC__Not_Posted_Item_Count__c == 0) {
                setStockTransferId.add(idStockTransfer);
            }


        }

        if (!system.isBatch() && !system.isFuture() && setStockTransferId != null && !setStockTransferId.isEmpty())
            sendStockTransferToSAP(setStockTransferId);

    }


    /**
     *  @AUTHOR Vaibhav Parashar
     *  @DESCRIPTION - Adhoc Inventory Sync using Parts Order Creation Interface.
     *              
     *  @PARAM :       set<Id> setStockTransferId
     *  @RETURN : void
     **/
    @future(callout = true)
    public static void sendStockTransferToSAP(set < Id > setStockTransferId) {

        //this interface creates a JSON.
        system.debug('setStockTransferId ' + setStockTransferId);

        //hold the list of platform events.
        List < Interface_Call__e > lstInterfaceCalls = New List < Interface_Call__e > ();

        //Iterate over the list of work orders.
        //create instance of platform events by iterating over the list of work orders recieved.
        for (Id stockTransRec: setStockTransferId) {

            //create platform event instance.
            Interface_Call__e interCall = new Interface_Call__e(Name__c = 'PartsOrderDataSender',
                Related_Record__c = stockTransRec);

            //add all the events in single list.                        
            lstInterfaceCalls.add(interCall);

        }

        if (lstInterfaceCalls.size() > 0) {
            //publish the events in one single call.
            EventBus.publish(lstInterfaceCalls);
        }



    }


}
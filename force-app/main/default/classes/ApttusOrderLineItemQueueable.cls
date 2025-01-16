/**
* @date 13 Apr 2020
*
* @description Queueable Class getting called from ApttusOrderLineItemsClass
* MODIFICATION LOG:  
* -------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION   
* Shivani                  28-Sep-2021         DCP-47698 - Sync Acceptance Code to Install Work Order 
* Gladis                   22-Jun-2022         DCP-45368 - Added new check for updateInstalledProduct
* Sudarshan                05-Dec-2023         CMCM-1354   EOL WO Changes
*--------------------------------------------------------------------------------------------------------------------------------------
*/
public class ApttusOrderLineItemQueueable implements Queueable {
   //DCP-47698
   public static final string ACTION_CREATE_INSTALL_WO = 'CreateInstallationWorkOrder';
   public static final string ACTION_SYNC_CODE_TO_WO = 'syncAcceptanceCodeInstallWO';
   public static final string ACTION_UPDATE_INSTALLED_PRODUCT = 'updateInstalledProduct';//DCP-45368

   Map<Id,List<Apttus_Config2__OrderLineItem__c>> orderIdToLstOrderLineItems = new Map<Id,List<Apttus_Config2__OrderLineItem__c>>();
   Map<Id,Integer> orderLineItemToQuantityChange = new Map<Id,Integer>();
   Set<Id> setProductIdsSelected = new Set<Id>();
   Map<Id,Boolean> orderEolEligiblity = new Map<Id,Boolean>();
   
	//START DCP-47698
	Map <String, String> oliNumberToMaterialGroup5Map = new Map<String, String>(); 
	String strMethodtoExecute;
	//END DCP-47698

    /*******************************************************************************************************
    * @description Constructor
    * @param strMethodtoExecute the name of the method to execute
    * @param orderIdToLstOrderLineItems Map of Order Ids to List of Line Items
    * @param orderLineItemToQuantityChange Map of Order Line item Id to teh change in quantity
    * @param setProductIdsSelected Set of Product Ids
    * @param orderEolEligiblity Map of 'End of Life' Eligible orders
    * @return 
    * @example
    */
    public ApttusOrderLineItemQueueable(String strMethodtoExecute, Map<Id,List<Apttus_Config2__OrderLineItem__c>> orderIdToLstOrderLineItems, Map<Id,Integer> orderLineItemToQuantityChange,
                                                     Set<Id> setProductIdsSelected,Map<Id,Boolean> orderEolEligiblity) {
      
       this.orderIdToLstOrderLineItems=orderIdToLstOrderLineItems;
       this.orderLineItemToQuantityChange = orderLineItemToQuantityChange;
       this.setProductIdsSelected=setProductIdsSelected;
       this.strMethodtoExecute = strMethodtoExecute; //DCP-47698
       this.orderEolEligiblity = orderEolEligiblity;
   
    }

    /*******************************************************************************************************
     * @description DCP-47698 Sync the acceptance code to the Install Work Order
     * @param strMethodtoExecute Method Name to execute
     * @param oliNumberToMaterialGroup5Map Map of Order Line Item ERP Number to Material Group 5 
     *										from Order Line Item
    */
    public ApttusOrderLineItemQueueable(String strMethodtoExecute, Map <String, String> oliNumberToMaterialGroup5Map) {
       this.strMethodtoExecute = strMethodtoExecute;
       this.oliNumberToMaterialGroup5Map = oliNumberToMaterialGroup5Map;
    }
   
    /*******************************************************************************************************
    * @description Execute method of Queueable Class
    * @param context QueueableContext
    * @return 
    * @example
    */
	public void execute(QueueableContext context) {
		//DCP-47698 adding try catch block
		try {
			if(String.isNotBlank(strMethodtoExecute) && strMethodtoExecute == ACTION_CREATE_INSTALL_WO && !orderIdToLstOrderLineItems.isEmpty()) {//DCP-47698
            ApttusOrderLineItems.createWorkOrders(orderIdToLstOrderLineItems, orderLineItemToQuantityChange, setProductIdsSelected,orderEolEligiblity);
			}
			//START DCP-47698
			if(String.isNotBlank(strMethodtoExecute) && strMethodtoExecute == ACTION_SYNC_CODE_TO_WO && !oliNumberToMaterialGroup5Map.isEmpty()) {
				WorkOrdersService.syncAcceptanceCodeInstallWO(oliNumberToMaterialGroup5Map);
			}  
			//END DCP-47698 
         //DCP-45368 Starts
         if(String.isNotBlank(strMethodtoExecute) && strMethodtoExecute == ACTION_UPDATE_INSTALLED_PRODUCT && !setProductIdsSelected.isEmpty()) {
				ilib_LogEvent.info('45368-setProductIdsSelected passed to ApttusOrderLineItems.mapInstalledProductToCase method from queueable-->'+setProductIdsSelected);
            ApttusOrderLineItems.mapInstalledProductToCase(setProductIdsSelected);
			}
         //DCP-45368 Ends
		} catch(Exception ex) {
			ApexExceptions.emit('ApttusOrderLineItemQueueable.' + strMethodtoExecute, ex);
		}
	}
}
 
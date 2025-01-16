/***************************************************************************************************************************************
 * NAME   : PartsOrderQueueable
 * DESCRIPTION  :Queueable class on  Partsorder object.
 *             :Performance story on work orders.
 *    
 * @AUTHOR : Digvijay
 * @DATE   : 23-12-2020  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Digvijay             23-12-2020           Initial Version
 * Biswajeet            25-06-2022           //CMSI-69 Instrumentation of the class
****************************************************************************************************************************************/
public with sharing class PartsOrderQueueable implements Queueable,Database.AllowsCallouts{
   public static final String LOG_TITLE = 'PartsOrderQueueable'; //CMSI-69
   public Map<Id,String> workOrderIdToPOStatus;
   public String strmethodname;
   public static final String METHOD_UPDATEWORKORDERSTATUS_FROM_PO = 'updateWorkOrderStatus';
   public Set<Id> setPOIds = new Set<Id>();
   
   
   /**  
    *  @author Vaibhav
    *  @description -Update the WO with appropriate part order status
    *  @return : 
    **/

    public PartsOrderQueueable(Map<Id,String> workOrderIdToPOStatus,String strmethodname,Set<Id> setPOIds){
        ilib_LogEvent.info('workOrderIdToPOStatus :'+(workOrderIdToPOStatus != null ? String.valueof(workOrderIdToPOStatus) : 'Map is Empty')); //CMSI-69
        ilib_LogEvent.info('strmethodname'+strmethodname); //CMSI-69
        ilib_LogEvent.info('setPOIds'+setPOIds); //CMSI-69
        this.workOrderIdToPOStatus=workOrderIdToPOStatus;
        this.strmethodname=strmethodname;
		this.setPOIds = setPOIds;
    }

/**  
    *  @author Vaibhav
    *  @description -Update the WO with appropriate part order status
    *  @return : 
    **/  
	
    public void execute(QueueableContext qc){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE+'.execute()');
        try{
            //updateWorkOrderStatus
            if(String.isNotBlank(strmethodname) && strmethodname== METHOD_UPDATEWORKORDERSTATUS_FROM_PO && workOrderIdToPOStatus!= null && !workOrderIdToPOStatus.isEmpty()){
                updateWorkOrderStatus(workOrderIdToPOStatus);     
            }
            //SAP Callout from parts order
            if(String.isNotBlank(strmethodname) && strmethodname== 'sendPartsOrderToSAP' && setPOIds!= null && !setPOIds.isEmpty()){
                PartsOrders.sendPartsOrderToSAP(setPOIds);
                ilib_LogEvent.info('Passing set of Parts Order ID to PartsOrders.sendPartsOrderToSAP :'+setPOIds);   //CMSI-69 
            }
            ilib_LogEvent.pop();
        }catch(Exception ex){
            // class name.method as source
           ApexExceptions.emit('PartsOrderQueueable.'+strmethodname,ex, ilib_LogEvent.SERVICE);
           throw ex;
        } 
        ilib_LogEvent.emit(); 
    }
    
    
     /**  
    *  @author Ritika Maheshwari
    *  @description - Update the Case with appropriate part order status
    *  @parameters : caseIdTOPOStatus : final map of case id against its part order status which is to be upated at case level
    *  @return : 
    **/
    private static void updateWorkOrderStatus(Map<Id,String> workOrderIdToPOStatus){
        ilib_LogEvent.push(LOG_TITLE +'.updateWorkOrderStatus()'); //CMSI-69
        ilib_LogEvent.info('workOrderIdToPOStatus :'+(workOrderIdToPOStatus!=null ? String.valueof(workOrderIdToPOStatus) : 'Map is empty')); //CMSI-69
        List<SVMXC__Service_Order__c> lstWorkOrder = new List<SVMXC__Service_Order__c>();
        for(SVMXC__Service_Order__c objWorkOrder : new WorkOrdersSelector().selectWorkOrders(workOrderIdToPOStatus.keySet()))
        {
            if(objWorkOrder.Parts_Order_Status__c != workOrderIdToPOStatus.get(objWorkOrder.Id)){
                objWorkOrder.Parts_Order_Status__c = workOrderIdToPOStatus.get(objWorkOrder.Id);
                lstWorkOrder.add(objWorkOrder);
            }
        }
        
        if(!lstWorkOrder.isEmpty()){
            update lstWorkOrder;   
            ilib_LogEvent.message('List of Service Order updated'+UtilsCollection.getSetOfIds(lstWorkOrder));  //CMSI-69                         
        }
        ilib_LogEvent.pop(); //CMSI-69
    }

}
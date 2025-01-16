/*****************************************************************************************************************
 * Class Name: InsertPOAndPOL_WorkdetailHelper
 * Description: Queueable class to insert PO and POL for a work detail.
 * Author: Prashanth
 * 
 * Date: 07-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth               07-12-2021        Queueable class to insert PO and POL for a work detail.
 * Pooja                   17-03-2022        modified method:populatePOLFields, Criteria to update Early failure-90day picklist value
 
 ******************************************************************************************************************/
public with sharing class InsertPOAndPOL_WorkdetailHelper implements Queueable{
    public static final String STRING_PART_LINE_STATUS = 'Open';
    public static final String STRING_PARTLINE_RETURN_REASON_NOREASONSELECTED = 'No Return Reason Selected';
    public static final String STRING_PART_TYPE_RETURN = 'Return';
    public static final String STRING_PART_PRIORITY_NORMAL = 'Normal';
    public static final String STRING_ORDER_STATUS = 'Open';
    public static final String RETURN_PARTS_ORDER_CREATION_META_DATA = 'Return_Parts_Order_Creation';
    public static final String STRING_PARTS_ORDER_LINE_CONSUMABLE = 'Consumable';
    public static final String STRING_PARTS_ORDER_LINE_INSTRUMENT = 'Instrument';
    public static final String STRING_PRODUCT_TYPE = 'Spare';
    public static final String STRING_EARLY_FAILURE_90DAYS='Early Failure - 90 Days';//DCP-49921
    Set<Id > setWorkDetailIds = new Set<Id>();
    public static Boolean catchException = false;
    /**
     * constructor
     */
    public InsertPOAndPOL_WorkdetailHelper(Set<Id > setWorkDetailIds) {
        this.setWorkDetailIds = setWorkDetailIds;
    }
    /*
    *  @AUTHOR:  sravan
    *  @DESCRIPTION: insert PO and POL
    *  @PARAM :  
    *  @RETURN:  void
    */
    public void execute(QueueableContext qc){
      try{
        Map<Id, List<SVMXC__Service_Order_Line__c>> workOrderToWorkDetails = new Map<Id, List<SVMXC__Service_Order_Line__c>>();         
        List<SVMXC__RMA_Shipment_Order__c> lstExistingPartsorder = new List<SVMXC__RMA_Shipment_Order__c>();    
        
        if(setWorkDetailIds.size() > 0){
            populateWorkdetailMap(setWorkDetailIds, workOrderToWorkDetails);
        }
        
        if(!workOrderToWorkDetails.isEmpty() ){
            Id loggedInUserId = UserInfo.getUserId();
            String erpSubmittedValue = 'Not Requested'; 
            
            //querying work orders and Not Requested parts orders with the requested by as logged in user 
            for(SVMXC__Service_Order__c objWorkOrder : new WorkOrdersSelector().workOrderWithPartsOrder(workOrderToWorkDetails.keySet(), loggedInUserId, erpSubmittedValue )){
                    
                if(objWorkOrder.SVMXC__RMA_Shipment_Order__r.size() > 0){
                    lstExistingPartsorder.add(objWorkOrder.SVMXC__RMA_Shipment_Order__r[0]);
                }
            }
            
        }
        //if parts order exist then create parts order line only
        if(lstExistingPartsorder.size() > 0){
            insertPartOrdersLinesForPartSwap(lstExistingPartsorder, workOrderToWorkDetails);
        }
        else{
            //creating both parts order and parts order lines
            insertPartOrdersForPartSwap(workOrderToWorkDetails);
        }
        //code coverage for catch block
        if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }
      }catch(Exception e){
        //catch the exception 
        ApexExceptions.emit('InsertPOAndPOL_WorkdetailHelper', e, ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
      }
    }
    /*
    *  @AUTHOR:  sravan
    *  @DESCRIPTION: insert PO and POL
    *  @PARAM :  
    *  @RETURN:  void
    */
    public static void populateWorkdetailMap(Set<Id> setWorkDetailIds, Map<Id, List<SVMXC__Service_Order_Line__c>> workOrderToWorkDetails){
        for(SVMXC__Service_Order_Line__c objWorkDetail : new WorkDetailsSelector().selectWorkDetailFields(setWorkDetailIds)){
            // checking work details for RAM true on retirned installed product or consumed product stock
            if((objWorkDetail.SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__r.RMA_Required__c == true) || (objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c == null && objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__r.RMA_Required__c == true)){
                //adding values to map of work order with newly created work details
                if(!workOrderToWorkDetails.containsKey(objWorkDetail.SVMXC__Service_Order__c)){
                    workOrderToWorkDetails.put(objWorkDetail.SVMXC__Service_Order__c, new List<SVMXC__Service_Order_Line__c>());
                }
                workOrderToWorkDetails.get(objWorkDetail.SVMXC__Service_Order__c).add(objWorkDetail); 
            }               
        }
    }
    /*
   *  @AUTHOR:  Nitin Sood 
   *  @DESCRIPTION: Method to be Create Parts Order Line Record for Work Detail of Type Part
   *  @PARAM :  Set<Id>
   *  @RETURN:  void
   */
    public static void insertPartOrdersLinesForPartSwap(List < SVMXC__RMA_Shipment_Order__c > lstPartOrderIds, Map < Id, List < SVMXC__Service_Order_Line__c >> workOrderToWorkDetails) {

        List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLines = new List<SVMXC__RMA_Shipment_Line__c>();
        
        //creating the parts order lines records for the newly inserted part order records
        for(SVMXC__RMA_Shipment_Order__c objPartsOrder : lstPartOrderIds){
            
            if(objPartsOrder.Id != null  && !workOrderToWorkDetails.isEmpty() && workOrderToWorkDetails.containsKey(objPartsOrder.SVMXC__Service_Order__c ) &&  !workOrderToWorkDetails.get(objPartsOrder.SVMXC__Service_Order__c).isEmpty()){
                
                for(SVMXC__Service_Order_Line__c objWorkDetail : workOrderToWorkDetails.get(objPartsOrder.SVMXC__Service_Order__c)){
                    SVMXC__RMA_Shipment_Line__c objPartsOrderLine = new SVMXC__RMA_Shipment_Line__c();
                    objPartsOrderLine.Work_Detail_Line_Number__c = objWorkDetail.Id  ;
                    objPartsOrderLine.SVMXC__RMA_Shipment_Order__c = objPartsOrder.Id;
                    objPartsOrderLine.SVMXC__Serial_Number__c = objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c;//installed Product from the work Detail 
                    objPartsOrderLine.SVMXC__Actual_Quantity2__c = objWorkDetail.SVMXC__Actual_Quantity2__c ;
                    objPartsOrderLine.Is_Billable__c = false;
                    objPartsOrderLine.SVMXC__Line_Status__c = STRING_PART_LINE_STATUS;
                    objPartsOrderLine.Return_Reason__c = STRING_PARTLINE_RETURN_REASON_NOREASONSELECTED; 
                    objPartsOrderLine.SVMXC__Service_Order__c= objWorkDetail.SVMXC__Service_Order__c;
                    populatePOLFields(objWorkDetail,objPartsOrderLine);
                    
                    lstPartsOrderLines.add(objPartsOrderLine);
                }
            }
        }
        
        if(lstPartsOrderLines != null && lstPartsOrderLines.size() > 0){
            Insert lstPartsOrderLines;
        }
    }
    /*
    *  @AUTHOR:  Nitin Sood 
    *  @DESCRIPTION: Method to be Create Parts Order Record for Parts Type Work Detail
    *  @PARAM :List<SVMXC__Service_Order_Line__c>
    *  @RETURN:  void
    */      

    public static void insertPartOrdersForPartSwap(Map<Id, List<SVMXC__Service_Order_Line__c>> workOrderToWorkDetails){

        Boolean triggerReturnPOEmail = false;
        //getting logged in user Id
        Id loggedInUserId = UserInfo.getUserId();
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders = new List<SVMXC__RMA_Shipment_Order__c>();
        if(!workOrderToWorkDetails.isEmpty() ){
            //creating the parts order records for the newly inserted parts type work detail records
            for(Id objworkOrderId: workOrderToWorkDetails.keySet()){
                SVMXC__Service_Order_Line__c objWorkDetail = workOrderToWorkDetails.get(objworkOrderId)[0];
                SVMXC__RMA_Shipment_Order__c objPartsOrder = new SVMXC__RMA_Shipment_Order__c();
                
                objPartsOrder.SVMXC__Service_Order__c = objWorkDetail.SVMXC__Service_Order__c;
                objPartsOrder.SVMXC__Order_Type__c = STRING_PART_TYPE_RETURN;
                objPartsOrder.Requested_By__c = loggedInUserId;
                objPartsOrder.SVMXC__Priority__c = STRING_PART_PRIORITY_NORMAL   ;
                objPartsOrder.SVMXC__Order_Status__c = STRING_ORDER_STATUS;
                // Update from location as Customer Location for return part orders
                if(String.isNotBlank(objWorkDetail.SVMXC__Service_Order__r.SVMXC__Site__c)){
                    objPartsOrder.SVMXC__Source_Location__c = objWorkDetail.SVMXC__Service_Order__r.SVMXC__Site__c;  
                }
                if(objWorkDetail.SVMXC__Service_Order__c !=  null){
                    objPartsOrder.SVMXC__Contact__c = objWorkDetail.SVMXC__Service_Order__r.SVMXC__Contact__c;  
                    objPartsOrder.SVMXC__Company__c = objWorkDetail.SVMXC__Service_Order__r.SVMXC__Company__c;
                }
                lstPartsOrders.add(objPartsOrder);
                
            }
        }

        if( lstPartsOrders.size() > 0){                
            Insert lstPartsOrders;
                                                                
        }
        //calling method to create part order lines for the inserted part orders
        if(!workOrderToWorkDetails.isEmpty()){
            insertPartOrdersLinesForPartSwap(lstPartsOrders, workOrderToWorkDetails );  
        } else {
            triggerReturnPOEmail = true;   
        }
            //DCP-37399 - Send email notification to RequestedBy for the return parts order created.
        if(triggerReturnPOEmail){
            SendEmailNotification.getSendEmailParamaters(RETURN_PARTS_ORDER_CREATION_META_DATA, lstPartsOrders , null ,'');
        }
        
    } 
    /*
    *  @AUTHOR:  Nitin Sood 
    *  @DESCRIPTION: Method to be Create Parts Order Record for Parts Type Work Detail
    *  @PARAM :List<SVMXC__Service_Order_Line__c>
    *  @RETURN:  void
    */  
    public static void populatePOLFields(SVMXC__Service_Order_Line__c objWorkDetail, SVMXC__RMA_Shipment_Line__c objPartsOrderLine){
        if(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__r != null){
            objPartsOrderLine.SVMXC__Product__c = objWorkDetail.SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__c;//Product populated from work Detail
            objPartsOrderLine.Product_Code1__c = objWorkDetail.SVMX_PS_VS_Return_Installed_Product__r.Product_Code__c;
        if(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__r.Service_Product_Type__c==STRING_PARTS_ORDER_LINE_CONSUMABLE){
            objPartsOrderLine.Controlling_Return_Reason__c = STRING_PARTS_ORDER_LINE_CONSUMABLE;
        }    
        else if(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__r.Service_Product_Type__c== STRING_PARTS_ORDER_LINE_INSTRUMENT){
            objPartsOrderLine.Controlling_Return_Reason__c = STRING_PARTS_ORDER_LINE_INSTRUMENT;
        }
        else if(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Product__r.Service_Product_Type__c== STRING_PRODUCT_TYPE){
            objPartsOrderLine.Controlling_Return_Reason__c = STRING_PRODUCT_TYPE;
             //Modified:Pooja ; DCP-49921 Start
             if(objWorkDetail.Consumption_Confirmed__c && objWorkDetail.SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Date_Installed__c!=null && 
             objWorkDetail.SVMX_PS_VS_Return_Installed_Product__r.SVMXC__Date_Installed__c.daysBetween(system.today())<=90){
                 objPartsOrderLine.Return_Reason__c=STRING_EARLY_FAILURE_90DAYS;
             }
             //Modified:Pooja ; DCP-49921 End
        }

        //Product populated from consumed product stock         
        }else if(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__c != null){
            objPartsOrderLine.SVMXC__Product__c = objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__c;
            objPartsOrderLine.Product_Code1__c = objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__r.Product_Code__c;
            if(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__r.Service_Product_Type__c== STRING_PARTS_ORDER_LINE_CONSUMABLE){
                objPartsOrderLine.Controlling_Return_Reason__c = STRING_PARTS_ORDER_LINE_CONSUMABLE;
            }
            else if(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__r.Service_Product_Type__c== STRING_PARTS_ORDER_LINE_INSTRUMENT){
                objPartsOrderLine.Controlling_Return_Reason__c = STRING_PARTS_ORDER_LINE_INSTRUMENT;
            }
            else if(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__r.SVMXC__Product__r.Service_Product_Type__c== STRING_PRODUCT_TYPE){
                objPartsOrderLine.Controlling_Return_Reason__c = STRING_PRODUCT_TYPE;
            }
        }
    }
    
}

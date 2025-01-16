/***************************************************************************************************************************************
    * NAME   : CreatePartsOrderFromWO
    * DESCRIPTION  : Logic for Creating Parts Order from Work Order when PO Number is added on WO.
    *                    
    * @AUTHOR : Akshay Mohan
    * @DATE   : 28-June-2021  
    * 90% code coverage test classes : TestCompletedWorkOrders_WOHelper, TestCreatePartsOrderFromWO, TestProactiveRunDetailSelector, TestProactiveRunDetails, TestWorkOrderBulkUpdateController 
    * 75% code coverage test classes : TestCompletedWorkOrders_WOHelper, TestCreatePartsOrderFromWO, TestProactiveRunDetailSelector, TestProactiveRunDetails, TestWorkOrderBulkUpdateController
    * MODIFICATION LOG: 
    * -----------------------------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * ------------------------------------------------------------------------------------------------------------------------------------------------------------
    * Akshay Mohan             28-June-2021        DCP-45793: Initial Version. 
    * Adyasha Satapathy        23-July-2021        DCP-49384: UAT Enhancement to create POL only for non blocked products for specific Service Product Types
    * Biswajeet Sahoo          12-Sept-2022        [CMSI-208] Instrumentation of class
******************************************************************************************************************************************************************/
public with sharing class CreatePartsOrderFromWO implements Queueable{
    private final SVMXC__Service_Order__c objWorkOrder;
    private static final String LOG_TITLE = 'CreatePartsOrderFromWO';
    private static final String STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATE ='Estimate';
    private static final String STRING_PARTS_ORDER_PRIORITY_NORMAL = 'Normal';
    private static final Set<String> SET_SERVICE_PRODUCT_TYPES_FOR_POL_CREATION = new Set<String>{Label.ProductTypeSapre, Label.ProductServiceProductTypeConsumable, Label.ProductClassInstrument};

    /**
    *   DCP-45793
	*	@author Akshay Mohan
	*	@param Work Order
	*	@return NA
	**/
    public CreatePartsOrderFromWO(SVMXC__Service_Order__c objWorkOrder) {
        this.objWorkOrder=objWorkOrder;
    }

    /**
    *   DCP-45793
	*	@author Akshay Mohan
	*	@param QueueableContext
	*	@return NA
	**/
    public void execute(QueueableContext context) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE);         //CMSI-208
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            ilib_LogEvent.info('objWorkOrder id: '+objWorkOrder.id);
           List<SVMXC__Service_Order_Line__c> lstEstimateLines=new WorkDetailsSelector().selectWorkDetailsByWOIdWithRecordTypeAndServiceProdType(new Set<Id>{objWorkOrder.id},STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATE,SET_SERVICE_PRODUCT_TYPES_FOR_POL_CREATION);
            if(!lstEstimateLines.isEmpty()){
                SVMXC__RMA_Shipment_Order__c objPO=createPartsOrder();
                List<SVMXC__RMA_Shipment_Line__c> lstPOLines = createPartsOrderLines(objPO,lstEstimateLines);
                ilib_LogEvent.info('Parts Order Lines inserted: '+lstPOLines.size());
                //Update PO Owner after POL creation to avoid sharing issues
                if(objPO != null){
                    objPO.OwnerId=objWorkOrder.OwnerId;
                    update objPO;
                }
            }
        }catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,objWorkOrder.id, e, ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /**
    *   DCP-45793
	*	@author Akshay Mohan
	*	@param NA
	*	@return SVMXC__RMA_Shipment_Order__c
	**/
    private SVMXC__RMA_Shipment_Order__c createPartsOrder() {
        ilib_LogEvent.push(LOG_TITLE + '.createPartsOrder()');
        List<SVMXC__Service_Group_Members__c> lstFieldSupport = new TechniciansSelector().selectTechnicians(new Set<Id>{objWorkOrder.SVMXC__Group_Member__c});
        SVMXC__RMA_Shipment_Order__c objPO = new SVMXC__RMA_Shipment_Order__c();
        objPO.SVMXC__Order_Type__c=Label.PartOrderTypeShipment;
        objPO.SVMXC__Order_Status__c=Label.PartsOrderLineOpen;
        objPO.SVMXC__Company__c=objWorkOrder.SVMXC__Company__c;
        objPO.SVMXC__Service_Order__c=objWorkOrder.id;
        objPO.SVMXC__Priority__c=STRING_PARTS_ORDER_PRIORITY_NORMAL;
        objPO.Shipping_Location__c=objWorkOrder.SVMXC__Site__c;
        objPO.SVMXC__Contact__c=objWorkOrder.SVMXC__Contact__c;
        objPO.Contact_Name__c = objWorkOrder.Contact_Name__c;
        objPO.Contact_Email__c=objWorkOrder.SVMX_PS_Contact_Email__c;
        objPO.Contact_Phone__c=objWorkOrder.SVMX_PS_Contact_Phone__c;
        objPO.Requested_By__c=objWorkOrder.OwnerId;
        if(!lstFieldSupport.isEmpty()){
            objPO.SVMXC__Destination_Location__c = lstFieldSupport.get(0).SVMXC__Inventory_Location__c;
        }
        ilib_LogEvent.info('Parts order for insert: '+objPO);
        insert objPO;
        ilib_LogEvent.info('Parrts order Id: '+objPO.id);
        ilib_LogEvent.pop();
        return objPO;
    }

    /**
    *   DCP-45793
	*	@author Akshay Mohan
	*	@param SVMXC__RMA_Shipment_Order__c objPO,List<SVMXC__Service_Order_Line__c> lstEstimateLines
	*	@return List<SVMXC__RMA_Shipment_Line__c>
	**/
    private List<SVMXC__RMA_Shipment_Line__c> createPartsOrderLines(SVMXC__RMA_Shipment_Order__c objPO,List<SVMXC__Service_Order_Line__c> lstEstimateLines) {
        ilib_LogEvent.push(LOG_TITLE + '.createPartsOrderLines()');
        List<SVMXC__RMA_Shipment_Line__c> lstPOLines = new List<SVMXC__RMA_Shipment_Line__c>();
        for(SVMXC__Service_Order_Line__c objEstimateLine : lstEstimateLines){
            SVMXC__RMA_Shipment_Line__c objPOLine = new SVMXC__RMA_Shipment_Line__c(SVMXC__RMA_Shipment_Order__c=objPO.id);
            objPOLine.SVMXC__Product__c = objEstimateLine.SVMXC__Product__c; 
            objPOLine.SVMXC__Actual_Quantity2__c = objEstimateLine.SVMXC__Estimated_Quantity2__c;            
            objPOLine.Is_Billable__c = true;
            objPOLine.No_Substitute_Parts__c = true;
            objPOLine.PO_Number__c = objEstimateLine.SVMXC__Service_Order__r.PO_Number__c;
            if(String.isNotBlank(objEstimateLine.SVMXC__Product__c) && objEstimateLine.SVMXC__Product__r.Service_Product_Type__c == Label.ProductTypeSpare){
                objPOLine.Field_Replaceable_Unit_Product__c = objEstimateLine.Field_Replaceable_Unit_Product__c;
                objPOLine.Is_Part_Order_Line_for_Spare_Parts__c = true;
            }
            lstPOLines.add(objPOLine);
        }
        ilib_LogEvent.info('Size of PO Lines to insert: '+lstPOLines.size());
        ilib_LogEvent.info('PO Lines to insert: '+lstPOLines);
        Database.SaveResult[] results = Database.insert(lstPOLines,false);
        ApexExceptions.emitUpdateErrorsWithRelatedRecord(results,LOG_TITLE,lstPOLines);
        ilib_LogEvent.pop();
        return lstPOLines;
    }
}
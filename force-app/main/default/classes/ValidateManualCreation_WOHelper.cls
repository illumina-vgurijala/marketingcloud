/**
* @author Shivani Jain
* @date 30th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related the manual creation of work order 
*/ 
public with sharing class ValidateManualCreation_WOHelper {

    /*  @AUTHOR:  Sandeep
    *  @DESCRIPTION: DCP-1026 This method validates the maanual creation of work order 
    *  @PARAM :  List<Sobject> 
    *  return : void
    */
    public static void validateManualCreationOfNewWorkOrder(List<Sobject> records, List<SVMXC__Service_Order__c> lstWOMatchingProductERPOrderNumberAndERPOrderLineNumber) {

        Set<Id> setProductId=new  Set<Id>();
        Set<String> setERPOrderNumber=new Set<String>();
        Set<String> setERPOrderLineNumber=new  Set<String>();
        List<SVMXC__Service_Order__c> lstNewWorkOrder=new List<SVMXC__Service_Order__c>();
        Set<Id> setCaseId=new Set<Id>();

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            if(objWorkOrder.SVMXC__Product__c!= null && String.isNotBlank(objWorkOrder.ERP_Order_Number__c) && String.isNotBlank(objWorkOrder.ERP_Order_Line_Number__c) && 
            (objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_INSTALLATION || objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_PLANNED_MAINTENANCE)) {
                setProductId.add(objWorkOrder.SVMXC__Product__c);
                setERPOrderNumber.add(objWorkOrder.ERP_Order_Number__c.trim());
                setERPOrderLineNumber.add(objWorkOrder.ERP_Order_Line_Number__c.trim());
                lstNewWorkOrder.add(objWorkOrder);
           }
        }

        for(Case objCase: WorkOrders.lstCaserecords){
            setCaseId.add(objCase.Id);
        }
       
        // map to hold unique id (product,erp order number and erp order line number) and list of work order
         Map<String,List<SVMXC__Service_Order__c>>  uniqueIdTolstWo = new Map<String,List<SVMXC__Service_Order__c>>();
        // building the map to hold list of work order based on the unqiue id 
        for(SVMXC__Service_Order__c objWO :lstWOMatchingProductERPOrderNumberAndERPOrderLineNumber) {
                
            if(!uniqueIdTolstWo.containskey(objWO.SVMXC__Product__c+'#'+objWO.ERP_Order_Number__c.trim()+'#'+objWO.ERP_Order_Line_Number__c.trim())){
                uniqueIdTolstWo.put(objWO.SVMXC__Product__c+'#'+objWO.ERP_Order_Number__c.trim()+'#'+objWO.ERP_Order_Line_Number__c.trim(), new List<SVMXC__Service_Order__c>{objWO} );  
            }
            else{
                uniqueIdTolstWo.get(objWO.SVMXC__Product__c+'#'+objWO.ERP_Order_Number__c.trim()+'#'+objWO.ERP_Order_Line_Number__c.trim()).add(objWO);
                }                
        }
    
        // validating the creation of work order
        for(SVMXC__Service_Order__c objWO :lstNewWorkOrder ){
            
            if(uniqueIdTolstWo.containskey(objWO.SVMXC__Product__c+'#'+objWO.ERP_Order_Number__c.trim()+'#'+objWO.ERP_Order_Line_Number__c.trim())){
            
                /* throwing error msg When the ERP Order Line Quantity is Less than the number of work orders in the system (with the same product, ERP Order Number and ERP Order Line Number) */
                    if(objWO.ERP_Order_Line_Quantity__c< =uniqueIdTolstWo.get(objWO.SVMXC__Product__c+'#'+objWO.ERP_Order_Number__c.trim()+'#'+objWO.ERP_Order_Line_Number__c.trim()).size()){
                        objWo.addError(System.Label.WO_Trigger_Installation_Error_Message);
                }
            }
        }   
        workOrderCaseAssociationCheck(setCaseId, records);
    }  

     /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To update Integration status on Completed WorkOrders 
    *  @PARAM : List of Sobjects
    *  @RETURN:  void
    */
    public static void workOrderCaseAssociationCheck(Set<Id> setWorkOrderId, List<sObject> records) {
        Set<Id>  setExistingWORelatedCaseIds = new Set<Id>();
        if(setWorkOrderId!=null && !setWorkOrderId.IsEmpty()){
                setExistingWORelatedCaseIds = new ServiceUtilityCollection.ServiceSystemUtilityCollection().getOtherWorkOrdersForSameCase(setWorkOrderId);
        }
        if(!setExistingWORelatedCaseIds.isEmpty()) {
            for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
                if(setExistingWORelatedCaseIds.contains(objWorkOrder.SVMXC__Case__c)){
                    objWorkOrder.addError(Label.WorkOrderCaseAssociationErrorMsg);
                }
            }           
        }
    }
}

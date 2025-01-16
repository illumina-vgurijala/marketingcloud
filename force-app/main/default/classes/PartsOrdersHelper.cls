/**************************************************************************************************************************************
 * NAME   : PartsOrdersHelper
 * DESCRIPTION  : Helper class for PartsOrders trigger class.                   
 * @AUTHOR : Sravankumar Ch
 * @DATE   : 25-Mar-2021  
 **/

 public with sharing class PartsOrdersHelper { 

    public static final String DML_EXCEPTION='System.DmlException'; 
    public static string priorityValueUrgent = 'Urgent';//CMCM-12520
    public static string stringAMR = 'AMR';//CMCM-12520
    public static string stringAMEA = 'AMEA';//CMCM-12520
    public static string stringChina = 'China';//CMCM-12520
    public static string stringEUR = 'EUR';//CMCM-12520
    public static boolean ifSetPriorityWFR = false;
    public static boolean ifSetPartsOrderStatusUpdate = false;  
    public static final String STRING_PART_ORDER_STATUS_PENDING_APPROVAL='Pending Approval';
/*
* for PartsOrder class
*
*/ 
    public class PartsOrder{
        /*
		*used to do query on PO object by passing POIds
		*/
        public void initPartsOrderMap(set<Id> partsOrderIds){
            if(PartsOrders.mapPartsOrders==null && !partsOrderIds.isEmpty()){
                PartsOrders.mapPartsOrders = new map<id,SVMXC__RMA_Shipment_Order__c> (new PartsOrdersSelector().selectPartsOrders(partsOrderIds));                
            }
        }
        /*
		*used to do DML operation on PO object
		*/
        public void doUpdatePartsOrders(map<Id,SVMXC__RMA_Shipment_Order__c> partsOrdersMap,list<sObject> records){
            if(partsOrdersMap!=null && !partsOrdersMap.isEmpty()){
                try{
                    update partsOrdersMap.values();
                }
                catch(Exception e){
                    Integer numErrors = e.getNumDml();
                    For(SVMXC__RMA_Shipment_Order__c objPO:(List<SVMXC__RMA_Shipment_Order__c>)records){
                        if(partsOrdersMap.keyset().contains(objPO.id)){
                            if(e.getTypeName()==DML_EXCEPTION){
                                for(Integer i=0;i<numErrors;i++) {
                                    objPO.adderror(e.getDmlMessage(i));
                                }
                            }
                            else{
                                objPO.adderror(e.getMessage());                                
                            }
                        }
                    }
                }                
            }
        }        
    }
/*
* for PartsOrderLines class
*
*/ 
    public class PartsOrderLines{
        /*
		*used to do query on POL object by passing POIds
		*/
        public void initPartsOrderLinesMap(set<Id> setPartsOrderIds){               
            if((PartsOrders.mapPartsOrderLines==null || PartsOrders.mapPartsOrderLines.isEmpty()) && !setPartsOrderIds.isEmpty()){
                PartsOrders.mapPartsOrderLines = new Map<Id,SVMXC__RMA_Shipment_Line__c>(new PartsOrderLineSelector().selectPOLsFromPOIds(setPartsOrderIds));
            }
        }
        /*
		*used to do DML Operation on POL object
		*/
        public  void doUpdatePartsOrderLines(map<Id,SVMXC__RMA_Shipment_Line__c> partsOrderLinesMap,list<sObject> records){
            if(partsOrderLinesMap!=null && !partsOrderLinesMap.isEmpty()){
                try{
                    update partsOrderLinesMap.values();
                }
                catch(Exception e){                              
                    Integer numErrors = e.getNumDml();                
                    for(SVMXC__RMA_Shipment_Order__c objPO:(List<SVMXC__RMA_Shipment_Order__c>)records){
                        for(SVMXC__RMA_Shipment_Line__c pol : partsOrderLinesMap.values()){
                            if(pol.SVMXC__RMA_Shipment_Order__c ==objPO.Id){
                                if(e.getTypeName()==DML_EXCEPTION){
                                    for(Integer i=0;i<numErrors;i++) {
                                        objPO.adderror(e.getDmlMessage(i));
                                    }
                                }
                                else{
                                    objPO.adderror(e.getMessage());                            
                                }
                            }
                        }
                    }
                }
            }
        }
    }
/*
* for WorkOrders class
*
*/ 
    public class WorkOrdersLocal{
        /* 
		*used to query on WO object
		*/
        public void initWorkOrderMap(set<Id> setWorkOrderIds){        
            if(PartsOrders.mapWorkOrders==null && !setWorkOrderIds.isEmpty()){
                PartsOrders.mapWorkOrders = new Map<Id,SVMXC__Service_Order__c>(new WorkOrdersSelector().selectWorkOrders(setWorkOrderIds));
            }
        }
        
        /*
		*used to do DML operation on WO object
		*/
        public void doUpdateWorkOrders(map<Id,SVMXC__Service_Order__c> workOrdersMap){
            if(workOrdersMap!=null && !workOrdersMap.isEmpty()){
                WorkOrders.skipWOTrigger = true;
                WorkOrders.isPrimaryAPUpdate = false;
                WorkOrders.isPartsOrderStatusUpdate = true;
                update workOrdersMap.values();
            }
        }
    }
/*
* for Cases class
*
*/ 
    public class Cases{
		/*
		*Method: initCasesMap
		*Author: Sravan
		*/
        public void initCasesMap(set<Id> setCaseIds){        
            if(PartsOrders.mapCases==null && !setCaseIds.isEmpty()){
                PartsOrders.mapCases = new Map<Id,Case>(new CasesSelector().selectCases(setCaseIds));
            }
        }
    }
/*
* for Locations class
*
*/ 
    public class Locations{
		/*
		*Method: initLocationsMap
		*Author: Sravan
		*/
        public void initLocationsMap(set<Id> setLocationIds){               
            if(PartsOrders.mapLocations==null && !setLocationIds.isEmpty()){
                PartsOrders.mapLocations = new Map<Id,SVMXC__Site__c> (new LocationsSelector().selectLocationsFromIds(setLocationIds));
            }
        }
    }
/*
* for ServiceBOMs class
*
*/ 
    public class ServiceBOMs{
		/*
		*Method: initServiceBOMsMap
		*Author: Sravan
		*/
        public void initServiceBOMsMap(set<Id> setProductIdsToServiceBOM){ 
            if(PartsOrders.mapServiceBOMs==null && !setProductIdsToServiceBOM.isEmpty()){
                PartsOrders.mapServiceBOMs = new map<Id,Service_Bill_Of_Materials__c>();
                for(Service_Bill_Of_Materials__c sBOM : new ServiceBOMsSelector().selectDefaultServiceBOMsForProduct(setProductIdsToServiceBOM)){
                    PartsOrders.mapServiceBOMs.put(sBOM.Product__c,sBOM);
                }
            }
        }
    }
/*
* for Profile class
*
*/    
    public class Profiles{
		/*
		*Method: initProfileName
		*Author: Sravan
		*/
        public void initProfileName(set<Id> profileIds){
            if(PartsOrders.mapProfileNames==null && !profileIds.isEmpty()){
                PartsOrders.mapProfileNames = new map<Id,String>();
                for(Profile pf : [SELECT Id, Name FROM Profile WHERE Id IN :profileIds]){
                    PartsOrders.mapProfileNames.put(pf.Id, pf.Name);
                }
            }        
        }
    }
 /*
* for Users class
*
*/ 
    public class Users{
		/*
		*Method: initUsersMap
		*Author: Sravan
		*/
        public void initUsersMap(set<Id> userIds){
            if(PartsOrders.mapUsers==null && !userIds.isEmpty()){
                PartsOrders.mapUsers = new map<Id,User> ([SELECT Profile.Name, Profile.UserLicense.Name, AD_UserName__c, AccountId, CurrencyIsoCode, DelegatedApproverId, Email, EmployeeNumber, Id, IsActive, IsPortalEnabled, LastName, ManagerId, Manager_Email__c, Name, Out_of_Office__c, Phone, ProfileId, Signature, Title, UserType, Username, Contact.AccountId, Manager.DelegatedApproverId, Manager.IsActive, Manager.ManagerId, Manager.Out_of_Office__c, Manager.ProfileId FROM User WHERE Id IN :userIds]);
            }
        }
    }
/*
* for AccountSalesArea class
*
*/ 
    public class AccountSalesArea{
		 /*
		*Method: initAccountSalesAreaMap
		*Author: Sravan
		*/
        public void initAccountSalesAreaMap(set<Id> accIds){
            if(PartsOrders.mapAccountSalesAreas==null && !accIds.isEmpty()){
                PartsOrders.mapAccountSalesAreas = new map<Id,Account_Sales_Area__c>();
                for(Account_Sales_Area__c objAccSalesArea : new AccountSalesAreaSelector().selectAccountSaleaArea(accIds)){
                    PartsOrders.mapAccountSalesAreas.put(objAccSalesArea.Id,objAccSalesArea);
                }
            }
        }
    }
/*
* for FeedItems class
*
*/ 
    public class FeedItems{
        /*
		*used to do DML insert on chatter feed
		*/
        public void doInsertFeedItem(List<ConnectApi.BatchInput> batchInputs){
            if(!batchInputs.isEmpty()){
                PartsOrders.recursionCheckForPostingFeed = true; // CMCM-12429
                ConnectApi.ChatterFeeds.postFeedElementBatch(null, batchInputs);
            }
        } 
    }
    
    /**
     * @author - Gaurav
     * @Description - CMCM-12520 method for Part Order : Set Priority When Instrument Down	 workflow conversion
     */
    public static void partsOrderSetPriorityWhenInstrumentDown(List<SVMXC__RMA_Shipment_Order__c> shipmentOrderList)
    {
        Set <Id> workOrderIds = new Set <Id>();
        Map <Id, SVMXC__Service_Order__c> wOMap = new Map <Id, SVMXC__Service_Order__c>();
        Map <Id,Id> partsOrderidToworkOrderIdSet = new Map <Id,Id>();
        for (SVMXC__RMA_Shipment_Order__c partsOrder : shipmentOrderList)
        {
            if (partsOrder.SVMXC__Service_Order__c != null)
                workOrderIds.add(partsOrder.SVMXC__Service_Order__c);
            partsOrderidToworkOrderIdSet.put(partsOrder.id,partsOrder.SVMXC__Service_Order__c);
        }
        for (SVMXC__Service_Order__c wo: new WorkOrdersSelector().getWorkOrderId(workOrderIds))
        {
            wOMap.put(wo.id,wo);
        } 
        
        if (wOMap != null)
        {
            for (SVMXC__RMA_Shipment_Order__c partsOrder : shipmentOrderList )
            {
                If(partsOrderidToworkOrderIdSet.containsKey(partsOrder.id))
                {
                    if (wOMap.containsKey(partsOrderidToworkOrderIdSet.get(partsOrder.id)))
                    {
                        SVMXC__Service_Order__c workOrder= wOMap.get(partsOrderidToworkOrderIdSet.get(partsOrder.id));
                        if (partsOrder.SVMXC__Service_Order__c != null && partsOrder.SVMXC__Order_Type__c==Label.PartOrderTypeShipment && workOrder.SVMXC__Customer_Down__c == true)
                            partsOrder.SVMXC__Priority__c =  priorityValueUrgent;
                    }
                }
            }
        }
    }
    
    /**
     * @author - Gaurav
     * @Description - CMCM-12520 method for Parts Order :Pending Approval Status time and Parts Order :Pending Approval Status time workflow conversion
     */
    public static void partsOrderPopulateandDepopulateStatusChangedTime(List<SVMXC__RMA_Shipment_Order__c> shipmentOrderList)
    {
        for (SVMXC__RMA_Shipment_Order__c partsOrder : shipmentOrderList)
        {
            if (partsOrder.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_PENDING_APPROVAL)
            {
                partsOrder.Status_Changed_Time__c = system.now();
            }
            else if (partsOrder.SVMXC__Order_Status__c != STRING_PART_ORDER_STATUS_PENDING_APPROVAL)
            {
                partsOrder.Status_Changed_Time__c = null;
            }
        }
    }
     /**
     * @author - Gaurav
     * @Description - CMCM-12520 parent method for all workflow updates method
     */
    public static void partsOrderWorkflowUpdates(List<SVMXC__RMA_Shipment_Order__c> shipmentOrderList,map<id,SVMXC__RMA_Shipment_Order__c> oldMap)
    {
       
       
       for (SVMXC__RMA_Shipment_Order__c partsOrder : shipmentOrderList)
       {
           partsOrderLoopassignment(partsOrder,OldMap);
       }
       if (Trigger.isBefore)
       {
           
           if (Trigger.isInsert || Trigger.isUpdate)
           {
               
               if (ifSetPriorityWFR == true)
               partsOrderSetPriorityWhenInstrumentDown(shipmentOrderList);
               
           }
           if (Trigger.isUpdate)
           {
               if (ifSetPartsOrderStatusUpdate == true)
               partsOrderPopulateandDepopulateStatusChangedTime(shipmentOrderList);
           }
       }  
   }
   /**
    * @author - Gaurav
    * @Description - CMCM-12520 method for Parts Order: Populate Contact Name and Contact Phone workflow conversion 
    */
   public static void partsOrderLoopassignment(SVMXC__RMA_Shipment_Order__c partsOrder,map<id,SVMXC__RMA_Shipment_Order__c> oldMap)
   {
       if(partsOrder.SVMXC__Service_Order__c != null)
       {
           ifSetPriorityWFR = true;
       }
       oldMapManipulation(partsOrder,oldMap);
   }
    /**
    * @author - Gaurav
    * @Description - CMCM-12520 method for Parts Order: Populate Contact Name and Contact Phone workflow conversion
    */
   private static void oldMapManipulation(SVMXC__RMA_Shipment_Order__c partsOrder,map<id,SVMXC__RMA_Shipment_Order__c> oldMap)
   {
       SVMXC__RMA_Shipment_Order__c oldPO = new SVMXC__RMA_Shipment_Order__c();
       if(OldMap != null)
       {
            oldPO = oldMap.get(partsOrder.Id);

       }
           if (partsOrder.SVMXC__Order_Status__c != null && OldMap != null && oldPO.SVMXC__Order_Status__c != partsOrder.SVMXC__Order_Status__c && (partsOrder.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_PENDING_APPROVAL || partsOrder.SVMXC__Order_Status__c != STRING_PART_ORDER_STATUS_PENDING_APPROVAL))
           {
               ifSetPartsOrderStatusUpdate = true;
           }
       
   }
   
}
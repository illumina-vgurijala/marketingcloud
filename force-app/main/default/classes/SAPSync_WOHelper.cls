/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to SAP sync
*/ 
public with sharing class SAPSync_WOHelper {
    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: Initiate Pricing Call to SAP
    *  @PARAM : Map<Id , Sobject> 
    *  @RETURN:  void
    */
    public static void callSAPForPricingData(Map<Id, SObject> oldRecords, List<sObject> records) {
        //DCP-38806
        set<Id> setWOforPricingRequest = new set<Id>();
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            
            //DCP-38806
            if(objWorkOrder.Send_Pricing_Request_to_SAP__c==true) {
                setWOforPricingRequest.add(objWorkOrder.Id);
            }

            objWorkOrder.Send_Pricing_Request_to_SAP__c=false;
        }

        //DCP-38806
        if(!setWOforPricingRequest.IsEmpty()) {
            ilib_Queueablethread queueableThreadforPricingcall = new ilib_Queueablethread('WorkOrdersAfterUpdate');
            queueableThreadforPricingcall.logandQueue(new InitiateSAPRequestQueueable_WOHelper(setWOforPricingRequest), WorkOrders.WORKORDER_QUEUEABLE,'initiateRequesttoSAP');
            if(!queueableThreadforPricingcall.lstQueueableJobs.isEmpty()) {
                ilib_QueueableManager.enqueueJob(queueableThreadforPricingcall);
            }
        }
    }

    /*
     *  
     *  @AUTHOR Digvijay(code refactored)
     *  @DESCRIPTION - process WO for calling SAP
     *  @PARAM :  Old Map of Work Orders.
     *  @RETURN : void
     */
    public static void processWOforCallingSAP(Map<Id, SObject> mapOld, Id idEstimatesRecordTypeId) {

       map<Id,List<SVMXC__Service_Order_Line__c>> mapworkOrderToWD=new map<Id,List<SVMXC__Service_Order_Line__c>>();
       map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToPO=new map<Id,List<SVMXC__RMA_Shipment_Order__c>>();
       //added for INC0271937
       List < SVMXC__Service_Order__c > lstWorkOrderToSAP = new List < SVMXC__Service_Order__c > ();
       //DCP-8444 Work Order Synchronization from ServiceMax to SAP (NEW).
       set<Id> setWorkOrderId = new set<Id>();
       List<SVMXC__Service_Order_Line__c> lstwds=new List<SVMXC__Service_Order_Line__c>();
       //INC0312408
       Map<Id, List<SVMXC__Service_Order_Line__c>> mapWdsToAutoClose = new Map<Id, List<SVMXC__Service_Order_Line__c>>();

       populateWorkDetailsMap(mapWdsToAutoClose, mapworkOrderToWD);

       populatePartsOrderMap(mapworkOrderToPO);


       for(Id idWorkOrder : mapOld.keySet()) {
           SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
           SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);

           populatelstwds(objNewWorkorder, objOldWorkorder, mapWdsToAutoClose, lstwds);

           Boolean hasWorkDetailsOrPartsOrder = checkifHasWDorPO(mapworkOrderToPO, mapworkOrderToWD, objNewWorkorder);

           //DCP-8444 - new changes
           if ((objNewWorkorder.SVMXC__Order_Status__c != objOldWorkorder.SVMXC__Order_Status__c 
                && objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
                && (hasWorkDetailsOrPartsOrder == true || String.isNotBlank(objOldWorkorder.Integration_Message_Details__c)) 
                    || (objOldWorkorder.SVMXC__Order_Status__c == 'Reopen Requested' && objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED  
                && String.isNotBlank(objNewWorkorder.Integration_Message_Details__c))) ||
           (objNewWorkorder.Send_to_ERP__c != objOldWorkorder.Send_to_ERP__c && objNewWorkorder.Send_to_ERP__c == true) ||
           (objNewWorkorder.SVMXC__Order_Status__c != objOldWorkorder.SVMXC__Order_Status__c && objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED))
           {
               populateSAPCollections(objNewWorkorder, setWorkOrderId, lstWorkOrderToSAP, idEstimatesRecordTypeId);
           }
       }

       //DCP-8444 - new changes
       if(!setWorkOrderId.isEmpty() && !system.isBatch() && !system.isFuture() && (!checkIfWorkDetailsAreChannelPartner(setWorkOrderId) || (checkIfSendToERPTrue(lstWorkOrderToSAP) && checkIfWorkDetailsAreChannelPartner(setWorkOrderId))))
           WorkOrders.sendWorkOrderToSAP(setWorkOrderId);

       //INC0244214 - unrelated to DCP-8444
       if(!lstwds.isEmpty()) {
           autoCloseLaborLineItems(lstwds);
       }        
   }

    /*
     *  INC0244214 - Auto Close all labor line items
     *  @AUTHOR Tapas
     *  @DESCRIPTION - Auto Close all labor line items except review activity types 
     *  @PARAM : List of Work Orders which are completed
     *  @RETURN : void
     */
    private static void autoCloseLaborLineItems( List<SVMXC__Service_Order_Line__c> lstWorkDetails) {
        List<SVMXC__Service_Order_Line__c> lstWDs = lstWorkDetails;
        List<String> stringClosedLineStatuses = new List<String>{WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED, WorkOrders.STRING_WORK_DETAIL_LINE_STATUS_CANCELED};
        
        
        for(SVMXC__Service_Order_Line__c objWD : lstWDs) {
            if(objWD.SVMXC__Line_Type__c == WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && objWD.SVMXC__Activity_Type__c != WorkOrders.STRING_WD_ACTIVITY_CUSTOMER_SERVICE_REVIEW && 
               objWD.SVMXC__Activity_Type__c != WorkOrders.STRING_WD_ACTIVITY_FIELD_COMPLIANCE_REVIEW && objWD.SVMXC__Activity_Type__c != WorkOrders.STRING_WD_ACTIVITY_QUALIFICATION_SERVICE_REVIEW &&
               !stringClosedLineStatuses.contains(objWD.SVMXC__Line_Status__c)) {
                if(WorkOrders.mapWDIdtoWDObj.ContainsKey(objWD.Id))
                    objWD= WorkOrders.mapWDIdtoWDObj.get(objWD.Id);

                objWD.SVMXC__Line_Status__c = WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED;
                WorkOrders.mapWDIdtoWDObj.put(objWD.Id,objWD);
            }
        }
            
    }

    /*
     *  @AUTHOR:  Vaibhav - //DCP-8444 - new changes
     *  @DESCRIPTION: Check if the Work Details are channel partner.
     *  @PARAM :  Set<Id> - work order ids.
     *  return : boolean.
     */
    private static  boolean checkIfWorkDetailsAreChannelPartner(set < Id > setWorkOrderId) {

        Boolean isWorkDetailChannelPartner = false;

         //DCP-8444 Work Order Synchronization from ServiceMax to SAP (NEW).
         
         map<Id,List<SVMXC__Service_Order_Line__c>> mapworkOrderToWD=new map<Id,List<SVMXC__Service_Order_Line__c>>();

         if(!WorkOrders.lstworkDetails.IsEmpty()) {
             for(SVMXC__Service_Order_Line__c obj: WorkOrders.lstworkDetails) {
                 
                     if(!mapworkOrderToWD.containsKey(Obj.SVMXC__Service_Order__c)) {
                         mapworkOrderToWD.put(Obj.SVMXC__Service_Order__c,new List<SVMXC__Service_Order_Line__c>());
                     }
                     mapworkOrderToWD.get(Obj.SVMXC__Service_Order__c).add(obj);
                 
             } 
        }
        for(Id varid:setWorkOrderId) {
            if(mapworkOrderToWD.ContainsKey(varid)) {
                for (SVMXC__Service_Order_Line__c workDetailRec: mapworkOrderToWD.get(varid)) {
                    if(String.isNotBlank(workDetailRec.SVMXC__Group_Member__r.SVMXC__Salesforce_User__c) && workDetailRec.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.IsPortalEnabled  == true) {
                        isWorkDetailChannelPartner = true;
                    } else {
                        isWorkDetailChannelPartner = false;
                        //break out of the look even if one work detail is not channel partner.
                        break;
                    }
                }
            }
        }

        return isWorkDetailChannelPartner;
    }

   /*
     *  @DESCRIPTION: Check if the work order has send to erp clicked. added for INC0271937
     *  @PARAM :  List<SVMXC__Service_Order__c> - work orders.
     *  return : boolean.
     */
    private static boolean checkIfSendToERPTrue(List < SVMXC__Service_Order__c > lstWorkOrders) {

        Boolean isSendToERP = true;

        for (SVMXC__Service_Order__c workorder: lstWorkOrders) {
            if (!workorder.Send_to_ERP__c) {
                //break out of the look even if one work order has send to erp as false.
                isSendToERP = false;
                break;
            }
        }

        return isSendToERP;
    }

    /*******************************************************************************************************
     * @description populate mapWdsToAutoClose and mapworkOrderToWD
     * @param mapWdsToAutoClose Map<Id, List<SVMXC__Service_Order_Line__c>>
     * @param mapworkOrderToWD Map<Id, List<SVMXC__Service_Order_Line__c>>
     * @return void
     */
    private static void populateWorkDetailsMap(Map<Id, List<SVMXC__Service_Order_Line__c>> mapWdsToAutoClose,  map<Id,List<SVMXC__Service_Order_Line__c>> mapworkOrderToWD) {
        for(SVMXC__Service_Order_Line__c obj: WorkOrders.lstworkDetails) {
            if(obj.SVMXC__Line_Type__c == 'Parts' || obj.SVMXC__Line_Type__c == WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR) {
                //INC0312408
                if(!mapWdsToAutoClose.containsKey(obj.SVMXC__Service_Order__c)) { 
                    mapWdsToAutoClose.put(obj.SVMXC__Service_Order__c,new List<SVMXC__Service_Order_Line__c>());
                }
                mapWdsToAutoClose.get(obj.SVMXC__Service_Order__c).add(obj);
                if((obj.Labor_Hours__c != '0' && obj.Labor_Hours__c != '00:00' && obj.Labor_Hours__c != '' && obj.Labor_Hours__c != '00') || (obj.Travel_Time_in_hours__c != '0' && obj.Travel_Time_in_hours__c != '' && 
                        obj.Travel_Time_in_hours__c != '00' && obj.Travel_Time_in_hours__c != '00:00')) {
                    if(!mapworkOrderToWD.containsKey(Obj.SVMXC__Service_Order__c)) {
                        mapworkOrderToWD.put(Obj.SVMXC__Service_Order__c,new List<SVMXC__Service_Order_Line__c>());
                    }
                    mapworkOrderToWD.get(Obj.SVMXC__Service_Order__c).add(obj);
                }    
            }
        }
    }

    /*******************************************************************************************************
     * @description populate mapworkOrderToPO
     * @param mapworkOrderToPO Map<Id,List<SVMXC__RMA_Shipment_Order__c>>
     * @return void
     */
    private static void populatePartsOrderMap(Map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToPO) {
        for(SVMXC__RMA_Shipment_Order__c obj:WorkOrders.lstpartsOrders) {
            if(obj.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED && obj.SVMXC__Order_Status__c!= WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED) {
                if(!mapworkOrderToPO.containsKey(Obj.SVMXC__Service_Order__c)) {
                    mapworkOrderToPO.put(Obj.SVMXC__Service_Order__c,new List<SVMXC__RMA_Shipment_Order__c>());
                }
                mapworkOrderToPO.get(Obj.SVMXC__Service_Order__c).add(obj);
            }
        }
    }

    /*******************************************************************************************************
     * @description populate mapworkOrderToPO
     * @param mapworkOrderToPO Map<Id,List<SVMXC__RMA_Shipment_Order__c>>
     * @param mapworkOrderToWD Map<Id,List<SVMXC__Service_Order_Line__c>>
     * @return void
     */
    private static Boolean checkifHasWDorPO(Map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToPO, Map<Id,List<SVMXC__Service_Order_Line__c>> mapworkOrderToWD,
                                            SVMXC__Service_Order__c objNewWorkorder) {
        Boolean hasWorkDetailsOrPartsOrder = false;
        if((mapworkOrderToPO.get(objNewWorkorder.id) != NULL && !mapworkOrderToPO.get(objNewWorkorder.id).isEmpty()) 
                || (mapworkOrderToWD.get(objNewWorkorder.id) != NULL && !mapworkOrderToWD.get(objNewWorkorder.id).isEmpty())) {
            hasWorkDetailsOrPartsOrder = true;
        }
        return hasWorkDetailsOrPartsOrder;
    }

    /*******************************************************************************************************
     * @description populateSAPCollections
     * @param objNewWorkorder SVMXC__Service_Order__c
     * @param setWorkOrderId Set<id>
     * @param lstWorkOrderToSAP List <SVMXC__Service_Order__c>
     * @param idEstimatesRecordTypeId Id
     * @return void
     */
    private static void populateSAPCollections(SVMXC__Service_Order__c objNewWorkorder, set<Id> setWorkOrderId, List <SVMXC__Service_Order__c> lstWorkOrderToSAP, Id idEstimatesRecordTypeId) {
        //For RecordType = Estimates : Json will not be triggered.
        if(objNewWorkorder.RecordTypeId != idEstimatesRecordTypeId && WorkOrders.stopRecurssivefutureCallout == 0) { 
            WorkOrders.stopRecurssivefutureCallout = 1;
            setWorkOrderId.add(objNewWorkorder.Id);
            //added for INC0271937
            lstWorkOrderToSAP.add(objNewWorkorder);
        } 
    }

    /*******************************************************************************************************
     * @description populate lstwds
     * @param lstwds List<SVMXC__Service_Order_Line__c>
     * @param objNewWorkorder SVMXC__Service_Order__c
     * @param mapWdsToAutoClose Map<Id, List<SVMXC__Service_Order_Line__c>>
     * @return void
     */
    private static void populatelstwds(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder, Map<Id, List<SVMXC__Service_Order_Line__c>> mapWdsToAutoClose, List<SVMXC__Service_Order_Line__c> lstwds) {
        //INC0312408
        if(objNewWorkorder.SVMXC__Order_Status__c != objOldWorkorder.SVMXC__Order_Status__c &&  objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED) {
            if(mapWdsToAutoClose.containsKey(objNewWorkorder.Id) && !mapWdsToAutoClose.get(objNewWorkorder.Id).isEmpty()) {
                lstwds.addAll(mapWdsToAutoClose.get(objNewWorkorder.Id));
            }
        }
    }

}

/**
* @author Shivani Jain
* @date 8th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Work Orders getting Completed. 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*         Developer           Date                  Description
*         Nancy Kalach      06-05-2023              CMCM-85: Enforce processing of parts order return before completing the work order
*         Nancy             02-13-2024              CMCM-5307: Work Order Trigger Query Optimization
*/ 
public with sharing class CompletedWorkOrders_WOHelper {

    public static Map<Id,List<SVMXC__RMA_Shipment_Line__c>> mapPartsOrderToNonIstrumentPOL= new Map<Id,List<SVMXC__RMA_Shipment_Line__c>>(); // CMCM-85
    //CMCM-5307 - Start
    public static List<SVMXC__RMA_Shipment_Line__c> partsOrderLinesWithNoInstrumentProd = new List<SVMXC__RMA_Shipment_Line__c>(); // CMCM-85
    public static List<SVMXC__Service_Order_Line__History>  lstGoodwillWDHistories = new List<SVMXC__Service_Order_Line__History>();
    //CMCM-5307 - End
    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To update Integration status on Completed WorkOrders 
    *  @PARAM : List of Sobjects
    *  @RETURN:  void
    */ 
    public static void integrationStatusonCompletedWorkOrders(Map<Id, SObject> oldRecords, List<sObject> records, List<SVMXC__Service_Order_Line__c> lstWDsForCompletionWOs, Id idEstimatesRecordTypeId) {

        map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToPO=new map<Id,List<SVMXC__RMA_Shipment_Order__c>>();
        map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToNOTRequestedPO=new map<Id,List<SVMXC__RMA_Shipment_Order__c>>();
        map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToOnHoldPO=new map<Id,List<SVMXC__RMA_Shipment_Order__c>>();
        map<Id,List<SVMXC__Service_Order_Line__c>> mapworkOrderToWD=new map<Id,List<SVMXC__Service_Order_Line__c>>();
        Boolean isWorkDetailChannelPartner = false;
        Map<Id,List<SVMXC__RMA_Shipment_Line__c>> woIdToObjPOLs = new Map<Id,List<SVMXC__RMA_Shipment_Line__c>>();
        Set<Id> partsOrderIds= new Set<Id>(); // CMCM-85

        // CMCM-85 - Start - Identify the Parts Orders having POL with non-instrument products
            for(SVMXC__RMA_Shipment_Order__c po: WorkOrders.lstpartsOrders) {
                partsOrderIds.add(po.Id);
            }
            //CMCM-5307 - Add empty check for WO trigger Optimization 
            if(partsOrderLinesWithNoInstrumentProd.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                partsOrderLinesWithNoInstrumentProd =  new PartsOrderLineSelector().selectPartsOrderLinesOnPOExcludeProductType(partsOrderIds, 'Instrument', 'Return');
            }
    
            for (SVMXC__RMA_Shipment_Line__c pol: partsOrderLinesWithNoInstrumentProd) {
                if (pol.SVMXC__RMA_Shipment_Order__c != null) {
                    if (!mapPartsOrderToNonIstrumentPOL.containsKey(pol.SVMXC__RMA_Shipment_Order__c)) {
                        mapPartsOrderToNonIstrumentPOL.put(pol.SVMXC__RMA_Shipment_Order__c, new List<SVMXC__RMA_Shipment_Line__c>());
                    }
                    mapPartsOrderToNonIstrumentPOL.get(pol.SVMXC__RMA_Shipment_Order__c).add(pol);
                }
            }     
        // CMCM-85 - End

        fetchOnHoldAndNotRequestedPO(mapworkOrderToPO,mapworkOrderToNOTRequestedPO,mapworkOrderToOnHoldPO);

        for(SVMXC__RMA_Shipment_Line__c objPOL : WorkOrders.lstpartsOrderslines) {
            if(!woIdToObjPOLs.containsKey(objPOL.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c)) {
                woIdToObjPOLs.put(objPOL.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c, new List<SVMXC__RMA_Shipment_Line__c>());
            }
            woIdToObjPOLs.get(objPOL.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c).add(objPOL);
        }

        for(SVMXC__Service_Order_Line__c workDetailRec:WorkOrders.lstworkDetails) { 
            if (String.isNotBlank(workDetailRec.SVMXC__Group_Member__r.SVMXC__Salesforce_User__c) && workDetailRec.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.IsPortalEnabled  == true) {
                    isWorkDetailChannelPartner = true;
            } else {
                isWorkDetailChannelPartner = false;
                //break out of the look even if one work detail is not channel partner.
                break;
            }
        }

        for(SVMXC__Service_Order_Line__c obj:WorkOrders.lstworkDetails) {
                if(!mapworkOrderToWD.containsKey(Obj.SVMXC__Service_Order__c)){
                    mapworkOrderToWD.put(Obj.SVMXC__Service_Order__c,new List<SVMXC__Service_Order_Line__c>());
                }
                mapworkOrderToWD.get(Obj.SVMXC__Service_Order__c).add(obj);
        }
        
        
        validateForCompleteWO(oldRecords,records,mapworkOrderToNOTRequestedPO,mapworkOrderToOnHoldPO,mapworkOrderToPO,mapworkOrderToWD,idEstimatesRecordTypeId,isWorkDetailChannelPartner,lstWDsForCompletionWOs,woIdToObjPOLs);

    }

    /**
    * @description : Map On hold and Not Requested PO related to Work Order
    * @param mapworkOrderToPO 
    * @param mapworkOrderToNOTRequestedPO 
    * @param mapworkOrderToOnHoldPO 
    **/
    public static void fetchOnHoldAndNotRequestedPO(map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToPO,map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToNOTRequestedPO,
    map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToOnHoldPO)
    {
        for(SVMXC__RMA_Shipment_Order__c obj:WorkOrders.lstpartsOrders) {
            if(!mapworkOrderToPO.containsKey(Obj.SVMXC__Service_Order__c)){
                mapworkOrderToPO.put(Obj.SVMXC__Service_Order__c,new List<SVMXC__RMA_Shipment_Order__c>());
            }
            mapworkOrderToPO.get(Obj.SVMXC__Service_Order__c).add(obj);

            // CMCM-85 - Added condition for Return PO to not allow completion of WO
            if(obj.ERP_Submitted__c == WorkOrders.ERP_SUBMITTED_NOT_REQUESTED && (obj.SVMXC__Order_Type__c != WorkOrders.ORDER_TYPE_RETURN || (obj.SVMXC__Order_Type__c == WorkOrders.ORDER_TYPE_RETURN && mapPartsOrderToNonIstrumentPOL.containsKey(obj.Id)) )) {
                if(!mapworkOrderToNOTRequestedPO.containsKey(Obj.SVMXC__Service_Order__c)) {
                    mapworkOrderToNOTRequestedPO.put(Obj.SVMXC__Service_Order__c,new List<SVMXC__RMA_Shipment_Order__c>());
                }
                mapworkOrderToNOTRequestedPO.get(Obj.SVMXC__Service_Order__c).add(obj);
            }

            if(obj.SVMXC__Order_Status__c == WorkOrders.ORDER_STATUS_ON_HOLD) {
                if(!mapworkOrderToOnHoldPO.containsKey(Obj.SVMXC__Service_Order__c)) {
                    mapworkOrderToOnHoldPO.put(Obj.SVMXC__Service_Order__c,new List<SVMXC__RMA_Shipment_Order__c>());
                }
                mapworkOrderToOnHoldPO.get(Obj.SVMXC__Service_Order__c).add(obj);
            }
        }
    }

    /**
    * @description :Throw error message for complete WO, also check for goodwill WD
    * @param oldRecords 
    * @param records 
    * @param mapworkOrderToNOTRequestedPO 
    * @param mapworkOrderToOnHoldPO 
    * @param mapworkOrderToPO 
    * @param mapworkOrderToWD 
    * @param idEstimatesRecordTypeId 
    * @param isWorkDetailChannelPartner 
    **/
    public static void validateForCompleteWO(Map<Id, SObject> oldRecords, List<sObject> records,map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToNOTRequestedPO,map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToOnHoldPO,
    map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToPO,map<Id,List<SVMXC__Service_Order_Line__c>> mapworkOrderToWD, Id idEstimatesRecordTypeId,Boolean isWorkDetailChannelPartner,List<SVMXC__Service_Order_Line__c> lstWDsForCompletionWOs,Map<Id,List<SVMXC__RMA_Shipment_Line__c>> woIdToObjPOLs)
    {
        //DCP-43634 - prevent WO completion if WD is pending approval
        Map<Id,Set<Id>> idWOtoSetWDIds = goodwillWOidToWO(lstWDsForCompletionWOs);

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));

            //DCP-25222 - check parts order associated to work order which are not submitted to SAP.
            //DCP-38815 - bypassing error messages for abandoned WO records
            if( objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c  && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED){
                //DCP-38815 - bypassing error messages for abandoned WO records
                if(mapworkOrderToNOTRequestedPO.ContainsKey(objWorkOrder.Id) && String.isBlank(objWorkOrder.Abandoned_Reason__c))
                    objWorkOrder.addError(System.label.WorkOrderERPSubmittedStatusCheckErrorMessage);
                    //DCP-38815 - bypassing error messages for abandoned WO records
                if(mapworkOrderToOnHoldPO.ContainsKey(objWorkOrder.Id) && String.isBlank(objWorkOrder.Abandoned_Reason__c))
                    objWorkOrder.addError(Label.WorkOrderErrorIfPOisOnHold);
                    //DCP-38815 - bypassing error messages for abandoned WO records
                if(woIdToObjPOLs.ContainsKey(objWorkOrder.Id) && String.isBlank(objWorkOrder.Abandoned_Reason__c))
                    objWorkOrder.addError(Label.WO_Prevent_Completion_For_Open_POL);
                
                if(idWOtoSetWDIds != null && idWOtoSetWDIds.containsKey(objWorkOrder.Id) && String.isBlank(objWorkOrder.Abandoned_Reason__c)  && 
                        (String.isBlank(WorkOrders.loggedInUserProfileName) || !WorkOrders.loggedInUserProfileName.equalsIgnoreCase(WorkOrders.STRING_SYSTEM_ADMINISTRATOR))) //DCP-43634
                    objWorkOrder.addError(System.Label.UI_Error_WO_PendingGoodwillApproval);                        
            }

            updateIntegrationStatusOnWO(objWorkOrder,oldRecords,mapworkOrderToPO,mapworkOrderToWD,idEstimatesRecordTypeId,isWorkDetailChannelPartner);
           
        }
    }

    /**
    * @description :Populate Integration status on WO based on certain conditions
    * @param objWorkOrder 
    * @param oldRecords 
    * @param mapworkOrderToPO 
    * @param mapworkOrderToWD 
    * @param idEstimatesRecordTypeId 
    * @param isWorkDetailChannelPartner 
    **/
    public static void updateIntegrationStatusOnWO(SVMXC__Service_Order__c objWorkOrder,Map<Id, SObject> oldRecords,map<Id,List<SVMXC__RMA_Shipment_Order__c>> mapworkOrderToPO,
    map<Id,List<SVMXC__Service_Order_Line__c>> mapworkOrderToWD, Id idEstimatesRecordTypeId,Boolean isWorkDetailChannelPartner )
    {
         //DCP-8444 - new changes(16 July 2019)
            if( objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
                    && objWorkOrder.SVMXC__Order_Status__c != ((SVMXC__Service_Order__c) oldRecords.get(objWorkOrder.Id)).SVMXC__Order_Status__c) {
                if(String.isNotBlank(((SVMXC__Service_Order__c) oldRecords.get(objWorkOrder.Id)).Integration_Message_Details__c) 
                        || (mapworkOrderToPO.containsKey(objWorkOrder.id) && !mapworkOrderToPO.get(objWorkOrder.id).isEmpty()
                            || (mapworkOrderToWD.containsKey(objWorkOrder.id) && !mapworkOrderToWD.get(objWorkOrder.id).isEmpty()))) {
                    if( objWorkOrder.RecordTypeId != idEstimatesRecordTypeId) {
                            objWorkOrder.Integration_Status__c = WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS;
                    }

                    if(isWorkDetailChannelPartner){
                        //Fixes for INC0237337
                        objWorkOrder.Integration_Status__c = WorkOrders.STRING_WORK_ORDER_INTEGRATION_STATUS_NOT_REQUIRED;
                    }
                
                } else if(objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
                        && objWorkOrder.SVMXC__Order_Status__c != ((SVMXC__Service_Order__c) oldRecords.get(objWorkOrder.Id)).SVMXC__Order_Status__c) {
                    //Added for DCP-28288 [7 Aug 2019]
                    objWorkOrder.Integration_Status__c = WorkOrders.STRING_WORK_ORDER_INTEGRATION_STATUS_NOT_REQUIRED;
                }
            }
    }

    /* @author - Tapas
    *  @description - DCP-43634, return Map of WO id to WO, if goodwill lines are not approved
    */
    public static Map<Id,Set<Id>> goodwillWOidToWO(List<SVMXC__Service_Order_Line__c> lstWDs) {
        Map<Id,Set<Id>> idWOtoSetWDIds = new Map<Id,Set<Id>>();
        List<SVMXC__Service_Order_Line__c> lstGoodwillWDsForCompletionWOs = new List<SVMXC__Service_Order_Line__c>();
        Map<id,List<SVMXC__Service_Order_Line__History>> idToLstWDHistories = new Map<id,List<SVMXC__Service_Order_Line__History>>();

        if(lstWDs.isEmpty()) {
            return null;
        }
        
        for(SVMXC__Service_Order_Line__c objWorkDetail : lstWDs) {
            if(objWorkDetail.Non_Billable_Reason__c == WorkDetails.STRING_WORK_DETAIL_NON_BILLABLE_REASON_GOODWILL) {
                lstGoodwillWDsForCompletionWOs.add(objWorkDetail);
            }
        }

        if(lstGoodwillWDsForCompletionWOs.isEmpty()) {
            return null;
        }
        //CMCM-5307 - Add empty check for WO trigger Optimization 
        if(lstGoodwillWDHistories.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstGoodwillWDHistories = [select parentid,Field, OldValue, NewValue,createdDate from SVMXC__Service_Order_Line__History where Field = 'Non_Billable_Reason__c' AND parentid in: lstGoodwillWDsForCompletionWOs order by createddate desc];
        }

        
        for(SVMXC__Service_Order_Line__History objWDHistory : lstGoodwillWDHistories) {
            if(objWDHistory.NewValue == WorkDetails.STRING_WORK_DETAIL_NON_BILLABLE_REASON_GOODWILL) {
                if(!idToLstWDHistories.containsKey(objWDHistory.parentid)) {
                    idToLstWDHistories.put(objWDHistory.parentid, new List<SVMXC__Service_Order_Line__History>());
                }
                idToLstWDHistories.get(objWDHistory.parentid).add(objWDHistory);
            }
        }
        addWOidToGoodWillWD(lstGoodwillWDsForCompletionWOs,idToLstWDHistories,idWOtoSetWDIds);

        return idWOtoSetWDIds;
    }  
    
    /**
    * @description :map all the good will work detail related to work order
    * @param lstGoodwillWDsForCompletionWOs 
    * @param idToLstWDHistories 
    * @param idWOtoSetWDIds 
    **/
    public static void addWOidToGoodWillWD(List<SVMXC__Service_Order_Line__c> lstGoodwillWDsForCompletionWOs,Map<id,List<SVMXC__Service_Order_Line__History>> idToLstWDHistories,
    Map<Id,Set<Id>> idWOtoSetWDIds)
    {
        for(SVMXC__Service_Order_Line__c objWD : lstGoodwillWDsForCompletionWOs) {
            if(objWD.SVMXC__Line_Status__c != WorkOrders.STRING_WORK_DETAIL_LINE_STATUS_CANCELED && objWD.Approval_Status__c != WorkDetails.WD_APPROVALSTATUS_APPROVED) {
                DateTime dt = DateTime.newInstanceGMT(2021, 5, 23);//for actual prod, will have to change to 22May date(cutover date)
                if(objWD.createdDate > dt || (idToLstWDHistories.containsKey(objWD.Id) && idToLstWDHistories.get(objWD.Id)[0].createdDate > dt)){
                    
                    if (!idWOtoSetWDIds.containsKey(objWD.SVMXC__Service_Order__c)) {
                        idWOtoSetWDIds.put(objWD.SVMXC__Service_Order__c, new Set<Id>());
                    }
                    idWOtoSetWDIds.get(objWD.SVMXC__Service_Order__c).add(objWD.Id);
                }
            }
        }
    }
    
    /*
     *  //DCP-25229
     *  @AUTHOR Digvijay(code refactored)
     *  @DESCRIPTION - Method to deleteAllocatedStockonWOCompletion. 
     *  @PARAM :  Old Map of Work Orders.
     *  @RETURN : void
     */
    public static void deleteAllocatedStockonWOCompletion(Map<Id, SObject> mapOld) {
        map<Id,Set<Id>> mapworkOrderToWD=new map<Id,Set<Id>>();
        //DCP-33467
        Set<Id> setWorkDetailIds = new Set<Id>();

        if(!WorkOrders.lstworkDetails.IsEmpty()){
            for(SVMXC__Service_Order_Line__c obj:WorkOrders.lstworkDetails){
                if(obj.SVMXC__Line_Type__c == WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) {
                    if(!mapworkOrderToWD.containsKey(Obj.SVMXC__Service_Order__c)){
                        mapworkOrderToWD.put(Obj.SVMXC__Service_Order__c,new Set<Id>());
                    }
                    mapworkOrderToWD.get(Obj.SVMXC__Service_Order__c).add(obj.Id);
                }
            }
        }

        for(Id idWorkOrder : mapOld.keySet()){
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
           
            //DCP-33467: Delete Allocated stock records if work order got completed
            if((objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED || objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED) 
                    && objNewWorkorder.Integration_Status__c == WorkOrders.STRING_WORK_ORDER_INTEGRATION_STATUS && objNewWorkorder.SVMX_PS_External_ID__c!=null) {
                if(mapworkOrderToWD.containsKey(objNewWorkorder.id))
                    setWorkDetailIds.addAll(mapworkOrderToWD.get(objNewWorkorder.id));
            }    
        }
        // DCP-33467
        if(!setWorkDetailIds.isEmpty()) {
            AllocatedStocks_WorkdetailHelper.deleteAllocatedStockRecords(setWorkDetailIds);
        }
    }
/*
     *  //CMCM-2640
     *  @AUTHOR- Nidhi
     *  @DESCRIPTION - updatePreviousWOStatus method tracks the status of service orders prior to their completion. 
     *  @RETURN : void
     */
    public static void updatePreviousWOStatus(List<sObject> records , Map<Id, SObject> mapOld) {
 
        for(SVMXC__Service_Order__c objWO : (List<SVMXC__Service_Order__c>)records) { 
            SVMXC__Service_Order__c oldObjWO = (SVMXC__Service_Order__c)mapOld.get(objWO.Id); 
            if(objWO.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED && oldObjWO.SVMXC__Order_Status__c !=objWO.SVMXC__Order_Status__c) { 
                objWO.WO_Precompletion_Status__c = oldObjWO.SVMXC__Order_Status__c; 
            }
        }
    }
}

/**************************************************************************************************************************************
 * NAME   : PartsOrders
 * DESCRIPTION  : Domain class for PartOrderTrigger.
 *    @Test Class for above 90% coverage.
 *    @Test Class for atleast 75% coverage.
 *     TestPartsOrder
 *                    
 * @AUTHOR : Ritika Maheshwari
 * @DATE   : 21-May-2018  
 *  
 * MODIFICATION LOG: 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika               20-May-2018          Initial Version. Added logic for DCP-326 to handle Part Order status change on case.
 * Shashank Singhal     7-July-2018          DCP-6315 set Order Status on Case for reparenting
 * Abhinav              21-Jun-2022          DCP-51199 check for CofD Form when Request All Lines is changed to true
 * Nishan Shetty        25-Aug-2022          DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
 * Shivani              05-Sep-2022          DCP-43629 - Parts Orders Sold To Population Logic
 * Abhishek             15-July-2023         CMCM-195 - refactor the complete code based on codescan result
  ****************************************************************************************************************************************/ 
  public with sharing class PartsOrders extends ilib_SObjectDomain {

    public static Boolean hasRunTaps = false;
    public static final String DML_EXCEPTION='System.DmlException';
    public static final String STRING_PART_ORDER_STATUS_NOTAPPLICABLE = 'Not Applicable';
    public static final String STRING_PART_ORDER_STATUS_INPROGRESS = 'In Progress';
    public static final String STRING_PART_ORDER_STATUS_DELIVERED = 'Delivered';
    public static final String STRING_PART_ORDER_STATUS_CANCELED = 'Canceled';
    public static final String STRING_PART_ORDER_STATUS_CLOSED = 'Closed';
    public static final String STRING_PART_ORDER_TYPE_RETURN = 'Return';
    public static final String STRING_PART_ORDER_TYPE_SHIPMENT = 'Shipment';
    public static final String STRING_ERROR_FOR_NONCSUSERS ='E: CS will review and release the Approved/Requested Instrument Part Order in SAP.';
    public static final String STRING_AUTOMATED_PROCESS = 'Automated Process';//26746
    public static final String STRING_PART_ORDER_STATUS_ON_HOLD = 'On Hold';
    public static Boolean isNotValidPartsOrder = False;
    public static Set<Id> setPartsOrderHavingError = new Set<Id>();
    //DCP-27270
    public static Boolean allowDeletion = false;

     //refactor PB::Parts_Order_Update_Part_Order_Lines_Status
    public static final String STRING_PART_ORDER_LINE_STATUS_REQUESTED = 'Requested';
    public static set<id> setPartsOrderToBeRequested= new Set<id>();
    public static set<id> setPartsOrderToBeCanceled = new Set<id>();

    //public static boolean isPartsOrderLoop1 = false;
    public static boolean triggerSAPIntegration = false;
    // End of PB:: refactor Parts_Order_Update_Part_Order_Lines_Status

    // Refactor PB :: Parts_Order_Update_Line_Item_Requested_Delivery_Date
    public static Map<id,Date> idPartsOrderToReqDelDate= new Map<id,Date>();

    //DCP-30843
    public static final String STRING_PART_ORDER_STATUS_PENDING_REVIEW = 'Pending Review';
    public static final String STRING_PART_ORDER_STATUS_PENDING_APPROVAL='Pending Approval';
	public static final String STRING_PART_ORDER_STATUS_APPROVED='Approved';
	public static final String STRING_PART_ORDER_STATUS_OPEN='Open';
    //DCP-51199 Start
    private static final String LOG_TITLE = 'PartsOrders';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    // public object variables to hold data initially when transaction starts
    public static map<Id,Case> mapCases;
    public static map<Id,SVMXC__Service_Order__c> mapWorkOrders;
    public static map<Id,SVMXC__RMA_Shipment_Line__c> mapPartsOrderLines;
    public static map<Id,SVMXC__Site__c> mapLocations;
    public static map<Id,Service_Bill_Of_Materials__c> mapServiceBOMs;    
    public static map<Id,Account_Sales_Area__c> mapAccountSalesAreas;
    public static map<Id,SVMXC__RMA_Shipment_Order__c> mapPartsOrders;
    public static map<Id,String> mapProfileNames;
    public static map<Id,User> mapUsers;
    public static map<Id,SVMXC__RMA_Shipment_Order__c> mapPartsOrdersToUpdate = new map<Id,SVMXC__RMA_Shipment_Order__c>();
    public static map<Id,SVMXC__RMA_Shipment_Line__c> mapPartsOrderLinesToUpdate = new map<Id,SVMXC__RMA_Shipment_Line__c>();
    public static map<Id,SVMXC__Service_Order__c> mapWorkOrdersToUpdate = new map<Id,SVMXC__Service_Order__c>();
    public static map<Id,List<Id>> poToPolMap = new map<Id,List<Id>>();
    public static List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
    //INC0297731
    //public static final String STRING_PARTS_ORDER_WITH_NO_POL = 'Parts Order should have at least one part order line to submit to SAP';
	public static map<Id,SVMXC__Site__c> mapSites = new Map<Id,SVMXC__Site__c>(); //DCP-52923
    public static List<SVMXC__RMA_Shipment_Order__c> listOtherPOForTheWorkOrder = new List<SVMXC__RMA_Shipment_Order__c>();
	public static Boolean bypassPartsOrderStatusUpdate = false; //DCP-43629
    public static List<SVMXC__RMA_Shipment_Line__c> partsOrdersShippedandDeliveredList = new List<SVMXC__RMA_Shipment_Line__c>();
    public static boolean skipPartsOrderTrigger = false;
	public static boolean recursionCheckForPostingFeed = false; //CMCM-12429
		
    /**
    * @description Call constructor of ilib_SObjectDomain
    * @author 
    * @param sObjectList 
    **/
    public PartsOrders(List<SVMXC__RMA_Shipment_Order__c> sObjectList) {
        super(sObjectList);
    }

    /*
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
	     /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new PartsOrders(sObjectList);
        }
    }

    /*******************************************************************************************************
    * @description  DCP-52923: Method to use for initializing Collections that will be used in before insert and before update events
    * @param records List of Parts Order
    */
    public void queryRecordsforExecutionBeforeEvent(List<Sobject> records) {
        Set<Id> setLocationIds = new Set<Id>();
        Set<Id> setPOIds = new Set<Id>();
        Set<Id> setWOIds = new Set<Id>();

        for(SVMXC__RMA_Shipment_Order__c partsOrderRec : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            setPOIds.add(partsOrderRec.Id);
            if(partsOrderRec.SVMXC__Service_Order__c != null) {
                setWOIds.add(partsOrderRec.SVMXC__Service_Order__c);
            }
            if(partsOrderRec.Shipping_Location__c != NULL) {
                setLocationIds.add(partsOrderRec.Shipping_Location__c);
            }
        }
        if(!setLocationIds.isEmpty()) {
            mapSites = new Map<Id,SVMXC__Site__c>(new LocationsSelector().selectLocations(new List<Id> (setLocationIds)));
        }
        listOtherPOForTheWorkOrder = new PartsOrdersSelector().selectPartsOrdersForAppropriateStatusonWO(setPOIds,setWOIds,new Set<String>{'Canceled'});
    }
    
    /**Overrided method from Super class. Handles Before Insert Trigger  event  */
     public override void onBeforeInsert() {
        queryRecordsforExecutionBeforeEvent(records); //DCP-52923

        //call updateActiveServiceBOMonPOOnBeforeInsert to update Active Service BOM ID on PO 
        updateActiveServiceBOMonPOOnBeforeInsert(records);
        //call getSalesAreaFromAccount to update Account Sales Area on PO 
        getSalesAreaFromAccount((List<SVMXC__RMA_Shipment_Order__c>) records);
        //to update Custom Fields  on PO
        updatePOFieldsOnBeforeInsert((List<SVMXC__RMA_Shipment_Order__c>) records);
        //update POL Statues
        updateRequestedOrCancelledPOLStatus((List<SVMXC__RMA_Shipment_Order__c>) records);
        //update Requester Manager
        updateRequsterMangerOnPartsOrderOnBeforeInsert((List<SVMXC__RMA_Shipment_Order__c>) records);
        //Check if part order requested by and inventory Authority are same.
        checkRequestedByAndInventoryAuthorityOnBeforeInsert((List<SVMXC__RMA_Shipment_Order__c>) records);
        //START - DCP-52923
        for(SVMXC__RMA_Shipment_Order__c partsOrderRec: (List<SVMXC__RMA_Shipment_Order__c>)records) {
                
            ShippingLocationDetails_POHelper.populateShippingLocDetails(partsOrderRec, null);
        }
        PartsOrdersHelper.partsOrderWorkflowUpdates((List<SVMXC__RMA_Shipment_Order__c>)records,null);

        //END - DCP-52923
    }

    /**Overrided method from Super class. Handles After Insert Trigger  event  */
	
	    /*
         * description - onAfterInsert method
		 * return - void
         */
    public override void onAfterInsert() { 
    ilib_Queueablethread queueableThread = new ilib_Queueablethread('PartsOrderAfterInsert');       //DCP-43629 [enqueueJob in handler method]
        // reinitilizing the public map to make sure that the map have latest data for each event
        mapPartsOrderLinesToUpdate = new map<Id,SVMXC__RMA_Shipment_Line__c>();
        // To update parts order line status when all POL are requested/cancelled
        updateRequestedOrCancelledPOLStatus((List<SVMXC__RMA_Shipment_Order__c>) records);
        // To update the related part order lines finally
        PartsOrdersHelper.PartsOrderLines dmlPOL = new PartsOrdersHelper.PartsOrderLines();
        dmlPOL.doUpdatePartsOrderLines(mapPartsOrderLinesToUpdate,records);
        // update work order status of the related Parts order        
        AsyncCalls_POHelper.asyncCallsOnPOAfterInsert((List<SVMXC__RMA_Shipment_Order__c>) records, queueableThread); //DCP-43629 [method moved to helper class]
        
        
        if(!queueableThread.lstQueueableJobs.isEmpty()) {  //DCP-43629 [enqueueJob in handler method]
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        }
        //Taps Logic on After PO Insert
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
    }

    /**Overrided method from Super class. Handles Before Update Trigger  event  */
	
	    /*
         * description - onBeforeUpdate method
		 * return - void
         */	
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords) {
        queryRecordsforExecutionBeforeEvent(records); //DCP-52923

        // reinitilizing the public map to make sure that the map have latest data for each event
        mapWorkOrdersToUpdate = new map<Id,SVMXC__Service_Order__c>();
        
        /** call to validate parts orders */
        validatePartsOrder((List<SVMXC__RMA_Shipment_Order__c>) records,oldRecords);
        //update POL Statues
        updateRequestedOrCancelledPOLStatus((List<SVMXC__RMA_Shipment_Order__c>) records);
        // Call to update parts order fields
        updatePOFieldsOnBeforeUpdate((List<SVMXC__RMA_Shipment_Order__c>) records,oldRecords);
        //call updateActiveServiceBOMonPOOnBeforeUpdate to update Active Service BOM ID on PO 
        updateActiveServiceBOMonPOOnBeforeUpdate((List<SVMXC__RMA_Shipment_Order__c>) records,oldRecords);
        // to update requester's manager and requester's manager's manager        
        updateRequsterMangerOnPartsOrderOnBeforeUpdate((List<SVMXC__RMA_Shipment_Order__c>) records,oldRecords);
        // to get confirmation on requested inventory authority
        checkRequestedByAndInventoryAuthorityOnBeforeUpdate((List<SVMXC__RMA_Shipment_Order__c>) records,oldRecords);

        //START - DCP-52923
        for(SVMXC__RMA_Shipment_Order__c newPartsOrderRec: (List<SVMXC__RMA_Shipment_Order__c>) records) {
            SVMXC__RMA_Shipment_Order__c oldPartsOrderRec = (SVMXC__RMA_Shipment_Order__c)(oldRecords.get(newPartsOrderRec.Id));

            ShippingLocationDetails_POHelper.populateShippingLocDetails(newPartsOrderRec, oldPartsOrderRec);
        }
        //END - DCP-52923

        //PRB0048294 Start
        new PartOrderWithoutSharingInner().unlockPartOrder(records);
        //PRB0048294 End

        // To update the related work orders finally
        PartsOrdersHelper.WorkOrdersLocal dmlWO = new PartsOrdersHelper.WorkOrdersLocal();
        dmlWO.doUpdateWorkOrders(mapWorkOrdersToUpdate);
        PartsOrdersHelper.partsOrderWorkflowUpdates((List<SVMXC__RMA_Shipment_Order__c>)records,(Map<Id, SVMXC__RMA_Shipment_Order__c>) oldRecords);
    }

    /**Overrided method from Super class. Handles Before Update Trigger  event  */

	    /*
         * description - onAfterUpdate method
		 * return - void
         */		
    public override void onAfterUpdate(Map<Id, SObject> oldRecords) {
        // reinitilizing the public maps to make sure that the map have latest data for each event
        mapPartsOrdersToUpdate = new map<Id,SVMXC__RMA_Shipment_Order__c>();
        mapPartsOrderLinesToUpdate = new map<Id,SVMXC__RMA_Shipment_Line__c>();
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('PartsOrderAfterUpdate');    //DCP-43629 - moved enqueueJob to handler method
        
        // To Update Parts Order Lines RequestedDeliveryDate from parts orders
        updatePartsOrderLinesRequestedDeliveryDate();
        // call to update Request_All_Part_Order_Lines__c field when submit to SAP
        updateRequestAllPOLCheckboxWhenSubmitToSAPOnAfterUpdate(records,oldRecords);
        //Call to check, update and submit to SAP if a related POL contains a custom product and user is non CS
        holdPartsOrderNotSubmitToSAPForNonCSUserOnAfterUpdate(oldRecords, queueableThread);        
        //update POL Statues
        updateRequestedOrCancelledPOLStatus(records);
        if (!recursionCheckForPostingFeed) {
            //post chatter comments if PO goodwill is approved/denied
            postCommentsIfGoodwillApprovedOrDenied((List<SVMXC__RMA_Shipment_Order__c>)records,(Map<Id,SVMXC__RMA_Shipment_Order__c>)oldRecords);
            // To insert chatter posts finally
            PartsOrdersHelper.FeedItems dmlFeedItems = new PartsOrdersHelper.FeedItems();
            dmlFeedItems.doInsertFeedItem(batchInputs);
        }
		// To update the part orders finally
        PartsOrdersHelper.PartsOrder dmlPO = new PartsOrdersHelper.PartsOrder();
        dmlPO.doUpdatePartsOrders(mapPartsOrdersToUpdate,records);
        // To update the related part order lines finally
        PartsOrdersHelper.PartsOrderLines dmlPOL = new PartsOrdersHelper.PartsOrderLines();
        dmlPOL.doUpdatePartsOrderLines(mapPartsOrderLinesToUpdate,records);        
        
        AsyncCalls_POHelper.asyncCallsOnPOAfterUpdate((List<SVMXC__RMA_Shipment_Order__c>) records, (Map<Id, SVMXC__RMA_Shipment_Order__c>) oldRecords, queueableThread); //DCP-43629
        //DCP-43629 - moved enqueueJob to handler method
        if(!queueableThread.lstQueueableJobs.isEmpty()) {
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        }
        /** to reclaculate the access of records */
        accessReCalculationOnAfterUpdate(records,oldRecords);
        if(!skipPartsOrderTrigger){
            updateRelatedShipmentLineStatus((List<SVMXC__RMA_Shipment_Order__c>) records, (Map<Id, SVMXC__RMA_Shipment_Order__c>) oldRecords);
        }
    }
    
    //=======================================Starts Functional Methods===============================================

    /** to reclaculate the access of records */
    public void accessReCalculationOnAfterUpdate(List<Sobject> records,Map<Id, SObject> oldRecords) {

        if (!hasRunTaps && !isInsertOperationForObject(getSObjectType())) {
            List<String> fieldsThatTriggerRecalculation = new List<String>{ 'OwnerId'};
            TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, oldRecords, fieldsThatTriggerRecalculation);//DCP-44091
            if (!idsThatNeedRecalculation.isEmpty()) {
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
                hasRunTaps = true;
            }
        }
    }


   
    /** Check, update and submit to SAP if a related POL contains a custom product and user is non CS */
    public static void holdPartsOrderNotSubmitToSAPForNonCSUserOnAfterUpdate(Map<Id, SObject> oldRecords, ilib_Queueablethread queueableThread) {
        //set of part order ids.
        Set<Id> setPartsOrderId = new set<Id>();
        boolean notAllowed=false;
        for(Id idPartsOrder : oldRecords.keySet()) {
            //new instance   
            SVMXC__RMA_Shipment_Order__c objNewPartsOrder = (SVMXC__RMA_Shipment_Order__c)Trigger.newMap.get(idPartsOrder);
            //old instance
            SVMXC__RMA_Shipment_Order__c objOldPartsOrder = (SVMXC__RMA_Shipment_Order__c)oldRecords.get(idPartsOrder);
            //conditions to check on parts order fields.
            setPartsOrderId = checkAndUpdatePartsOrderStatus(objNewPartsOrder, objOldPartsOrder, idPartsOrder);
            
        }
        
        if (!System.isBatch() && !System.isFuture() && setPartsOrderId != null && !setPartsOrderId.isEmpty()) {
            
            Boolean isCustomProduct = false;
            //START DCP-25279
            set<id> shipmentOrderwithInstruments= new set<Id>();
            set<id> shipmentOrderInstrumentsLines= new set<Id>();
            //END DCP-25279
            //Added by Shruti Karn for INC0228681
            //moved out side the for loop for sonarqube fixes
            String profileName = getProfileNameForNonCSUser();
            PartsOrdersHelper.PartsOrderLines pOLInIt = new PartsOrdersHelper.PartsOrderLines();
            pOLInIt.initPartsOrderLinesMap(setPartsOrderId);
            if(mapPartsOrderLines!=null && !mapPartsOrderLines.isEmpty()) {
                for(SVMXC__RMA_Shipment_Line__c partsOrderLine: mapPartsOrderLines.values()) {
                    if(partsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c==Label.PartOrderTypeShipment) {
                        if (partsOrderLine.SVMXC__Product__r.Custom_Product__c) {
                            isCustomProduct = true;
                            break;
                        } else {
                            //Start DCP-25279
                            shipmentOrderInstrumentsLines.add(partsOrderLine.Id);
                            if(partsOrderLine.Service_Product_Type__c=='Instrument' && profileName != System.Label.ProfileName_CustomerService) { //Updated by Shruti Karn for INC0228681
                                shipmentOrderwithInstruments.add(partsOrderLine.SVMXC__RMA_Shipment_Order__c);
                            }//End DCP-25279   
                        }
                    }
                }
            }
            //Start DCP-25279
            notAllowed = handelShipmentOrderwithInstruments(shipmentOrderwithInstruments,shipmentOrderInstrumentsLines, mapPartsOrdersToUpdate, mapPartsOrderLinesToUpdate);
            //End DCP-25279
            
            if(isCustomProduct) { 
                handelMapPartsOrdersToUpdateFroCustomProduct(setPartsOrderId,mapPartsOrdersToUpdate);              
            } else if(notAllowed!=true) { //DCP-26746 this will be true if the current user is a non cs user and parts order contains an instrument line. If notallowed is true then the callout shouldn't happen
                    asyncCallOut(setPartsOrderId, queueableThread);
            }
        }
    }

    private static Boolean handelShipmentOrderwithInstruments(set<Id> shipmentOrderwithInstruments,set<Id> shipmentOrderInstrumentsLines,map<Id,SVMXC__RMA_Shipment_Order__c> mapPartsOrdersToUpdate,map<Id,SVMXC__RMA_Shipment_Line__c> mapPartsOrderLinesToUpdate) {
        Boolean notAllowed =false;
        if(!shipmentOrderwithInstruments.isempty()) {
            notAllowed=true;// this is true when there is a instrumetn line item and current user is not a CS User
            handelMapPartsOrdersToUpdate(shipmentOrderwithInstruments,mapPartsOrdersToUpdate);
            handleMapPartsOrderLinesToUpdate(shipmentOrderInstrumentsLines,mapPartsOrderLinesToUpdate);
                          
        } else {
            notAllowed=false;
        }
        return notAllowed;
        }
        private static void handelMapPartsOrdersToUpdateFroCustomProduct(Set<Id> setPartsOrderId,map<Id,SVMXC__RMA_Shipment_Order__c> mapPartsOrdersToUpdate) {
            for(String partsOrderIds: setPartsOrderId) {      
                if(mapPartsOrdersToUpdate.containsKey(partsOrderIds)) {
                    mapPartsOrdersToUpdate.get(partsOrderIds).SVMXC__Order_Status__c = STRING_PART_ORDER_STATUS_ON_HOLD;
                    mapPartsOrdersToUpdate.get(partsOrderIds).Integration_Error_Message__c = 'Since a Custom Product was entered, the Parts Order has been routed to Customer Service for next steps.';
                } else {
                    SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c(Id = partsOrderIds, SVMXC__Order_Status__c = STRING_PART_ORDER_STATUS_ON_HOLD,Integration_Error_Message__c = 'Since a Custom Product was entered, the Parts Order has been routed to Customer Service for next steps.');
                    mapPartsOrdersToUpdate.put(partsOrder.id,partsOrder);
                }
            }
            }

            private static void handelMapPartsOrdersToUpdate(set<Id> shipmentOrderwithInstruments, map<Id,SVMXC__RMA_Shipment_Order__c> mapPartsOrdersToUpdate) {
                for(String partsOrderId: shipmentOrderwithInstruments) {
                    if(mapPartsOrdersToUpdate.containsKey(partsOrderId)) {
                        mapPartsOrdersToUpdate.get(partsOrderId).SVMXC__Order_Status__c=STRING_PART_ORDER_STATUS_ON_HOLD;
                        mapPartsOrdersToUpdate.get(partsOrderId).Integration_Error_Message__c=STRING_ERROR_FOR_NONCSUSERS;
                        mapPartsOrdersToUpdate.get(partsOrderId).Integration_Status__c = 'E';
                        mapPartsOrdersToUpdate.get(partsOrderId).Request_All_Part_Order_Lines__c = false;
                    } else {
                        SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c(Id = partsOrderId,
                                                                                                   SVMXC__Order_Status__c=STRING_PART_ORDER_STATUS_ON_HOLD,
                                                                                                   Integration_Error_Message__c=STRING_ERROR_FOR_NONCSUSERS,
                                                                                                   Integration_Status__c = 'E');
                        partsOrder.Request_All_Part_Order_Lines__c = false; //DCP-26746
                        mapPartsOrdersToUpdate.put(partsOrder.Id,partsOrder);
                    }
                  }
                }
                
                private static void handleMapPartsOrderLinesToUpdate(set<Id> shipmentOrderInstrumentsLines,map<Id,SVMXC__RMA_Shipment_Line__c> mapPartsOrderLinesToUpdate) {
                for(String partsOrderLineId: shipmentOrderInstrumentsLines) {
                    if(mapPartsOrderLinesToUpdate.containsKey(partsOrderLineId)) {
                        mapPartsOrderLinesToUpdate.get(partsOrderLineId).SVMXC__Line_Status__c=STRING_PART_ORDER_STATUS_ON_HOLD;
                    } else {
                        SVMXC__RMA_Shipment_Line__c partsOrderLine= new SVMXC__RMA_Shipment_Line__c(Id = partsOrderLineId,SVMXC__Line_Status__c=STRING_PART_ORDER_STATUS_ON_HOLD);
                        mapPartsOrderLinesToUpdate.put(partsOrderLine.Id,partsOrderLine);
                    }
                }  
                }
                
                private static String getProfileNameForNonCSUser() {
                    // Logic to retrieve the profile name for non-customer service users
                    // ...
                    String profileName = '';
                    if(UserInfo.getName()!=STRING_AUTOMATED_PROCESS) {
                        set<Id> setProfile = new set<Id>{Userinfo.getProfileId()};
                        PartsOrdersHelper.Profiles profileInIt = new PartsOrdersHelper.Profiles();
                        profileInIt.initProfileName(setProfile);
                        if(mapProfileNames != null && !mapProfileNames.isEmpty()) {
                            profileName = mapProfileNames.get(Userinfo.getProfileId());
                        }
                    }
                    return profileName;
                }

                private static Set<Id> checkAndUpdatePartsOrderStatus(SVMXC__RMA_Shipment_Order__c objNewPartsOrder, SVMXC__RMA_Shipment_Order__c objOldPartsOrder,Id idPartsOrder) {
                    Set<Id> setPartsOrderId = new Set<Id>();
                    if ((objNewPartsOrder.Request_All_Part_Order_Lines__c != objOldPartsOrder.Request_All_Part_Order_Lines__c && objNewPartsOrder.Request_All_Part_Order_Lines__c == true) || triggerSAPIntegration == true) {
                        setPartsOrderId.add(idPartsOrder);
                        triggerSAPIntegration = false;
                    }
                    return setPartsOrderId;
                }
        

//CMCM - 195



    



    /** To update Request_All_Part_Order_Lines__c checkbox when submit to SAP */
    public static void updateRequestAllPOLCheckboxWhenSubmitToSAPOnAfterUpdate(List<Sobject> records,Map<Id, SObject> oldRecords) {
        //DCP-25222
        Map<Id,SVMXC__RMA_Shipment_Order__c> partsOrderIdToSubmitToSAP = new Map<Id,SVMXC__RMA_Shipment_Order__c>();
        for(Id idPartsOrder : oldRecords.keySet()) {
            //new instance   
            SVMXC__RMA_Shipment_Order__c objNewPartsOrder = (SVMXC__RMA_Shipment_Order__c)Trigger.newMap.get(idPartsOrder);
            //old instance
            SVMXC__RMA_Shipment_Order__c objOldPartsOrder = (SVMXC__RMA_Shipment_Order__c)oldRecords.get(idPartsOrder);
            
            //DCP-25222 - Submit to SAP was checked and no parts order line was inserted in edit screen.
            if(objNewPartsOrder.Submit_to_SAP__c != objOldPartsOrder.Submit_to_SAP__c && objNewPartsOrder.Submit_to_SAP__c == true && objNewPartsOrder.Part_Order_Lines_Count__c == objOldPartsOrder.Part_Order_Lines_Count__c && objNewPartsOrder.Request_All_Part_Order_Lines__c != true) {
                partsOrderIdToSubmitToSAP.put(objNewPartsOrder.Id,objNewPartsOrder);
            }
        }

        //DCP-25222 - Submit to SAP will update exisitng request all parts order lines checkbox because of other functionalities built around it.
        if(partsOrderIdToSubmitToSAP != null && !partsOrderIdToSubmitToSAP.isEmpty()) {
            for(Id partsOrderId : partsOrderIdToSubmitToSAP.keyset()) {
				if(mapPartsOrdersToUpdate.containsKey(partsOrderId)) {
                    mapPartsOrdersToUpdate.get(partsOrderId).Request_All_Part_Order_Lines__c = true;
                } else {
                    SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c(Id = partsOrderId, Request_All_Part_Order_Lines__c = true);
                    mapPartsOrdersToUpdate.put(partsOrder.Id,partsOrder);
                }
			}
        }
    }

    /**
     *  @AUTHOR Soumya Ranjan Sahu
     *  @DESCRIPTION - To Update Parts Order Lines RequestedDeliveryDate from parts orders
     *  @RETURN : void
     **/
     
     public void updatePartsOrderLinesRequestedDeliveryDate() {
         //Refactor PB :: Parts_Order_Update_Line_Item_Requested_Delivery_Date
        if(idPartsOrderToReqDelDate!=null && !idPartsOrderToReqDelDate.isEmpty()) {
            PartsOrdersHelper.PartsOrderLines pOLInIt = new PartsOrdersHelper.PartsOrderLines();
            pOLInIt.initPartsOrderLinesMap(idPartsOrderToReqDelDate.keySet());
            if(mapPartsOrderLines!=null && !mapPartsOrderLines.isEmpty()) {
                for(SVMXC__RMA_Shipment_Line__c objPartsOrderLine : mapPartsOrderLines.values()) {
                    if(mapPartsOrderLinesToUpdate.containsKey(objPartsOrderLine.id)) {
                       mapPartsOrderLinesToUpdate.get(objPartsOrderLine.id).Requested_Delivery_Date__c = idPartsOrderToReqDelDate.get(objPartsOrderLine.SVMXC__RMA_Shipment_Order__c);
                    } else {
                        objPartsOrderLine.Requested_Delivery_Date__c = idPartsOrderToReqDelDate.get(objPartsOrderLine.SVMXC__RMA_Shipment_Order__c);
                        mapPartsOrderLinesToUpdate.put(objPartsOrderLine.Id,objPartsOrderLine);
                    }
                }
            }
        }
     }

    /** Used to keep all parts order updates togather */
    public static void updatePOFieldsOnBeforeUpdate(List<Sobject> records,Map<Id, SObject> oldRecords) {
        String profileName = getProfileName();
        // for process builder refactor
        Set<String> setPOClosedStatuses = getPOClosedStatuses();
        Map<Id, Id> woToCase;
        Map<Id,String> workOrderIdToPOStatus = new Map<Id,String>();
        List<SVMXC__RMA_Shipment_Order__c> lstPartOrdersWithUpdatedWOs =  new List<SVMXC__RMA_Shipment_Order__c>();
        //Start CMCM-15
        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            poToPolMap.put(objPartOrder.Id, new List<Id>());
        }
        for(SVMXC__RMA_Shipment_Line__c objPol:new PartsOrderLineSelector().selectPartsOrderLinesOnPartsOrders(poToPolMap.keySet())) {
            poToPolMap.get(objPol.SVMXC__RMA_Shipment_Order__c).add(objPol.Id);
        }
        //End CMCM-15
        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            SVMXC__RMA_Shipment_Order__c objOldPartOrder = (SVMXC__RMA_Shipment_Order__c)(oldRecords.get(objPartOrder.Id));
            //Start - DCP-26746
            processIntegrationError(objPartOrder, profileName);
            //End - DCP-26746

            // for process builder refactor
            updateOrderStatus(objPartOrder, objOldPartOrder, setPOClosedStatuses);
            // CMCM-278
            updateReturnOrderStatus(objPartOrder, objOldPartOrder);
            
            //DCP-25222
            updateCanceledOrderStatus(objPartOrder, objOldPartOrder);

            // update parts order status
            if(objPartOrder.SVMXC__Service_Order__c != null) {
               updatePOStatusOnBeforeUpdate(objPartOrder,objOldPartOrder,workOrderIdToPOStatus); 
            }

            updatePOStatusAndCheckWOChanges(objPartOrder, objOldPartOrder,lstPartOrdersWithUpdatedWOs);
            
            updateRequestedDeliveryDate(objPartOrder, objOldPartOrder ,idPartsOrderToReqDelDate);

            //Refactor PB :: Parts_Order_Update_Line_Item_Requested_Delivery_Date
                        

        }// FOR LOOP END

        //refactor: populate case on Parts Order
        if(!lstPartOrdersWithUpdatedWOs.isEmpty()) {
            woToCase = getCaseFromWorkOrder(lstPartOrdersWithUpdatedWOs);   
        }

        if(woToCase != null && !woToCase.isEmpty()) {
            for(SVMXC__RMA_Shipment_Order__c objpartsOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
                if(woToCase.containsKey(objpartsOrder.SVMXC__Service_Order__c)) {
                    objpartsOrder.SVMXC__Case__c = woToCase.get(objpartsOrder.SVMXC__Service_Order__c);
                }
            }
        }
        
        /** to update the field Parts_order_Status__c on existing work orders */
        if(!bypassPartsOrderStatusUpdate) {    //DCP-43629 [bypassing so that this logic doesnt get called on Sold To field update via Mobile]
            updateWorkOrderStatus(workOrderIdToPOStatus);
        }
    }

    private static String getProfileName() {
        String profileName = '';
        if (UserInfo.getName() != STRING_AUTOMATED_PROCESS) {
            Set<Id> setProfile = new Set<Id>{ Userinfo.getProfileId() };
            PartsOrdersHelper.Profiles profileInIt = new PartsOrdersHelper.Profiles();
            profileInIt.initProfileName(setProfile);
            if (mapProfileNames != null && !mapProfileNames.isEmpty()) {
                profileName = mapProfileNames.get(Userinfo.getProfileId());
            }
        }
        return profileName;
    }
// CMCM-195
    private static Set<String> getPOClosedStatuses() {
        return new Set<String>{ STRING_PART_ORDER_STATUS_CLOSED, STRING_PART_ORDER_STATUS_ON_HOLD, 'Integration Error' };
    }

    private static void processIntegrationError(SVMXC__RMA_Shipment_Order__c objPartOrder, String profileName) {
        if (objPartOrder.Integration_Error_Message__c == STRING_ERROR_FOR_NONCSUSERS && profileName == System.Label.ProfileName_CustomerService) {
            objPartOrder.Integration_Error_Message__c = '';
        }
    }

    private static void updateOrderStatus(SVMXC__RMA_Shipment_Order__c objPartOrder, SVMXC__RMA_Shipment_Order__c objOldPartOrder, Set<String> setPOClosedStatuses) {
        if(objPartOrder.Items_Delivered__c != objOldPartOrder.Items_Delivered__c || objPartOrder.Items_Shipped__c != objOldPartOrder.Items_Shipped__c || objPartOrder.Total_Items__c != objOldPartOrder.Total_Items__c) { 
            if(objPartOrder.Items_Delivered__c  + objPartOrder.Items_Shipped__c == objPartOrder.Total_Items__c && !setPOClosedStatuses.contains(objPartOrder.SVMXC__Order_Status__c)) {
                objPartOrder.SVMXC__Order_Status__c = STRING_PART_ORDER_STATUS_CLOSED;
            }               
        } else if(objPartOrder.Items_Delivered__c != objOldPartOrder.Items_Delivered__c || objPartOrder.Items_Shipped__c != objOldPartOrder.Items_Shipped__c || objPartOrder.Total_Items__c != objOldPartOrder.Total_Items__c ) {
            if(objPartOrder.Items_Delivered__c  + objPartOrder.Items_Shipped__c != objPartOrder.Total_Items__c && objPartOrder.SVMXC__Order_Status__c != STRING_PART_ORDER_STATUS_CLOSED) {
                objPartOrder.SVMXC__Order_Status__c = STRING_PART_ORDER_STATUS_OPEN;
            }               
        }
    }

    private static void updateReturnOrderStatus(SVMXC__RMA_Shipment_Order__c objPartOrder, SVMXC__RMA_Shipment_Order__c objOldPartOrder) {
    if(objPartOrder.SVMXC__Order_Type__c == STRING_PART_ORDER_TYPE_RETURN && objPartOrder.ERP_Sales_Order_Number__c != objOldPartOrder.ERP_Sales_Order_Number__c && String.isNotBlank(objPartOrder.ERP_Sales_Order_Number__c)) {
        if((objOldPartOrder.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_PENDING_REVIEW || objOldPartOrder.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_OPEN) && objPartOrder.SVMXC__Order_Status__c != STRING_PART_ORDER_STATUS_ON_HOLD) {
            objPartOrder.SVMXC__Order_Status__c = STRING_PART_ORDER_STATUS_CLOSED;             
        }
    } 
  }

  private static void updateCanceledOrderStatus(SVMXC__RMA_Shipment_Order__c objPartOrder,SVMXC__RMA_Shipment_Order__c objOldPartOrder) {
    if(objPartOrder.Items_Canceled__c != objOldPartOrder.Items_Canceled__c && objPartOrder.Items_Canceled__c == objPartOrder.Total_Items__c + objPartOrder.Items_Canceled__c) {
        objPartOrder.SVMXC__Order_Status__c = 'Canceled';
        }
  }

  private static void updatePOStatusAndCheckWOChanges(SVMXC__RMA_Shipment_Order__c objPartOrder,SVMXC__RMA_Shipment_Order__c objOldPartOrder,List<SVMXC__RMA_Shipment_Order__c> lstPartOrdersWithUpdatedWOs ) {
    if(objPartOrder.SVMXC__Service_Order__c != null && objPartOrder.SVMXC__Service_Order__c != objOldPartOrder.SVMXC__Service_Order__c) {                
        lstPartOrdersWithUpdatedWOs.add(objPartOrder);
    }
  }

  private static void updateRequestedDeliveryDate(SVMXC__RMA_Shipment_Order__c objPartOrder,SVMXC__RMA_Shipment_Order__c objOldPartOrder,Map<id,Date> idPartsOrderToReqDelDate) {
    if (objPartOrder.Requested_Delivery_Date__c != objOldPartOrder.Requested_Delivery_Date__c && objPartOrder.Requested_Delivery_Date__c != null) {
        idPartsOrderToReqDelDate.put(objPartOrder.id,objPartOrder.Requested_Delivery_Date__c);
        objPartOrder.Requested_Delivery_Date__c = null;
     } 
  }
// CMCM-195
    /** update status of parts order based on below conditions. which will be called in updatePOFieldsOnBeforeUpdate method */
    public static void updatePOStatusOnBeforeUpdate(SVMXC__RMA_Shipment_Order__c objPartOrder,SVMXC__RMA_Shipment_Order__c objOldPartOrder,Map<Id,String> workOrderIdToPOStatus) {
        if(objPartOrder.SVMXC__Service_Order__c != null) {

                if(!workOrderIdToPOStatus.containsKey(objPartOrder.SVMXC__Service_Order__c)) {
                    updatePOStatusForNewWorkOrder(objPartOrder, objOldPartOrder, workOrderIdToPOStatus);
                } else {
                    getPartOrderStatusForWorkOrder(workOrderIdToPOStatus, objPartOrder);
                }
            }
        }

        // Added BY Abhishek Start  CMCM-195
       private static void updatePOStatusForNewWorkOrder(SVMXC__RMA_Shipment_Order__c objPartOrder, SVMXC__RMA_Shipment_Order__c objOldPartOrder, Map<Id, String> workOrderIdToPOStatus) {
        List<SVMXC__RMA_Shipment_Order__c> lstOtherInProgressPO = getOtherInProgressPO();
        List<SVMXC__RMA_Shipment_Order__c> lstOtherClosedPO = getOtherClosedPO();
        String partOrderStatus = calculatePartOrderStatus(objPartOrder, objOldPartOrder, lstOtherInProgressPO, lstOtherClosedPO);
       
        if(partOrderStatus != null && partOrderStatus != '') {
            workOrderIdToPOStatus.put(objPartOrder.SVMXC__Service_Order__c, partOrderStatus);
        }
       }

       private static List<SVMXC__RMA_Shipment_Order__c> getOtherInProgressPO() {
        List<SVMXC__RMA_Shipment_Order__c> lstOtherInProgressPO = new List<SVMXC__RMA_Shipment_Order__c>();
    
        for (SVMXC__RMA_Shipment_Order__c otherPO : listOtherPOForTheWorkOrder) {
            if (otherPO.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_INPROGRESS) {
                lstOtherInProgressPO.add(otherPO);
            }
        }
    
        return lstOtherInProgressPO;
       }

       private static List<SVMXC__RMA_Shipment_Order__c> getOtherClosedPO() {
        List<SVMXC__RMA_Shipment_Order__c> lstOtherClosedPO = new List<SVMXC__RMA_Shipment_Order__c>();
    
        for (SVMXC__RMA_Shipment_Order__c otherPO : listOtherPOForTheWorkOrder) {
            if (otherPO.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_CLOSED) {
                lstOtherClosedPO.add(otherPO);
            }
        }
    
        return lstOtherClosedPO;
    }
       
    private static String calculatePartOrderStatus(SVMXC__RMA_Shipment_Order__c objPartOrder, SVMXC__RMA_Shipment_Order__c objOldPartOrder, List<SVMXC__RMA_Shipment_Order__c> lstOtherInProgressPO, List<SVMXC__RMA_Shipment_Order__c> lstOtherClosedPO) {
        if(objPartOrder.Open_Parts_Orders_Lines__c >0 && objOldPartOrder.Open_Parts_Orders_Lines__c == 0) {
            return STRING_PART_ORDER_STATUS_INPROGRESS;
        } else if((lstOtherInProgressPO.isempty() && objPartOrder.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_CLOSED) &&
        ((objPartOrder.Open_Parts_Orders_Lines__c == 0 && objOldPartOrder.Open_Parts_Orders_Lines__c > 0) 
        || (poToPolMap.get(objPartOrder.Id).isEmpty()))) {
            return STRING_PART_ORDER_STATUS_DELIVERED;
        } else if(objPartOrder.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_CANCELED && lstOtherInProgressPO.isempty()) {
            if(lstOtherClosedPO.isEmpty()) {
                return STRING_PART_ORDER_STATUS_NOTAPPLICABLE;
            } else {
                return STRING_PART_ORDER_STATUS_DELIVERED;
            }
        }
        return null;
       }


       //  Added BY Abhishek End CMCM-195
    
    /**  
    *  @author Ritika Maheshwari
    *  @description - Update the Case with appropriate part order status
    *  @parameters : caseIdTOPOStatus : final map of case id against its part order status which is to be upated at case level
    *  @return : 
    **/
    private static void updateWorkOrderStatus(Map<Id,String> workOrderIdToPOStatus) {
        
        PartsOrdersHelper.WorkOrdersLocal wOInIt = new PartsOrdersHelper.WorkOrdersLocal();
        wOInIt.initWorkOrderMap(workOrderIdToPOStatus.keySet());
        if(mapWorkOrders!=null && !mapWorkOrders.isEmpty()) {
            for(SVMXC__Service_Order__c objWorkOrder : mapWorkOrders.values()) {
                if(objWorkOrder.Parts_Order_Status__c != workOrderIdToPOStatus.get(objWorkOrder.Id)) {
                    if(mapWorkOrdersToUpdate.containsKey(objWorkOrder.Id)) {
                        mapWorkOrdersToUpdate.get(objWorkOrder.Id).Parts_Order_Status__c = workOrderIdToPOStatus.get(objWorkOrder.Id);
                    } else {
                        objWorkOrder.Parts_Order_Status__c = workOrderIdToPOStatus.get(objWorkOrder.Id);
                        mapWorkOrdersToUpdate.put(objWorkOrder.Id,objWorkOrder);
                    }
                }
            }
        }
    }

	/*
    *  @author Ritika Maheshwari
    *  @description - Get the appropriate part order status, by comparing with other part orders for the same case
    *  @parameters : caseIdToPOStatus - case id to the current part order status at case level
    *               objPartOrder : parts order which has been updated, its status is checked against the status at case
    *  @return : void
    **/
    private static void getPartOrderStatusForWorkOrder(Map<Id,String> workOrderIdToPOStatus, SVMXC__RMA_Shipment_Order__c objPartOrder) {
        String strWOStatusFromMap = workOrderIdToPOStatus.get(objPartOrder.SVMXC__Service_Order__c);
        //If the order status is other than delivered, reset the status to In Progress 
        if(strWOStatusFromMap != null) { 
            if(objPartOrder.Open_Parts_Orders_Lines__c >0) {
                workOrderIdToPOStatus.put(objPartOrder.SVMXC__Service_Order__c, STRING_PART_ORDER_STATUS_INPROGRESS);
            } else if(strWOStatusFromMap != STRING_PART_ORDER_STATUS_INPROGRESS) {
                workOrderIdToPOStatus.put(objPartOrder.SVMXC__Service_Order__c, STRING_PART_ORDER_STATUS_DELIVERED);
            }
        }
    }    

    /** update requester manager and requester manager's manager which calls from OnBeforeUpdate */
    public static void updateRequsterMangerOnPartsOrderOnBeforeUpdate(List<Sobject> records,Map<Id, SObject> oldRecords) {
        Map <id,map<id,id>> idOwnerToManager = new Map <id,map<id,id>>();
        set<id> setOwnerIds = new set<id>();
        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            SVMXC__RMA_Shipment_Order__c objOldPartOrder = (SVMXC__RMA_Shipment_Order__c)(oldRecords.get(objPartOrder.Id));
            //Refactor PB :: Parts_Order_Populate_User_Related_Fields
            if((objPartOrder.OwnerId != null && string.valueOf(objPartOrder.OwnerId).startsWith('005') && objOldPartOrder.OwnerId != objPartOrder.OwnerId)
            //DCP-30843
            ||(objPartOrder.Submit_For_Approval__c  && objOldPartOrder.Submit_For_Approval__c != objPartOrder.Submit_For_Approval__c)) {
                system.debug('****OwnerId'+objPartOrder.OwnerId);
                setOwnerIds.add(objPartOrder.OwnerId);
            }
        }

        //Refactor PB :: Parts_Order_Populate_User_Related_Fields
        if(!setOwnerIds.isEmpty()) {
            idOwnerToManager=getOwnerManagerFields(setOwnerIds);
        }

        for (SVMXC__RMA_Shipment_Order__c objPartOrder: (List < SVMXC__RMA_Shipment_Order__c > ) records) {
            //Refactor PB :: Parts_Order_Populate_User_Related_Fields
            if(idOwnerToManager.containsKey(objPartOrder.OwnerId)) {
                system.debug('****Inside if');
                for(id idManager :idOwnerToManager.get(objPartOrder.OwnerId).keyset()) {
                    objPartOrder.Requesters_Manager__c = idManager;
                    objPartOrder.Requester_Managers_Manager__c = idOwnerToManager.get(objPartOrder.OwnerId).get(idManager);
                }
            } else if(idOwnerToManager.containsKey(userinfo.getuserid())) { //End of Refactor PB :: Parts_Order_Populate_User_Related_Fields //DCP-30843
                system.debug('****Inside Else if');
                for(id idManager :idOwnerToManager.get(userinfo.getuserid()).keyset()) {
                    objPartOrder.Requesters_Manager__c = idManager;
                    system.debug('***Requesters_Manager__c='+objPartOrder.Requesters_Manager__c); 
                    objPartOrder.Requester_Managers_Manager__c = idOwnerToManager.get(userinfo.getuserid()).get(idManager);
                    system.debug('***Requester_Managers_Manager__c ='+objPartOrder.Requester_Managers_Manager__c ); 
                }            
            }
        }
    }

    /** to process invetory authoriti in location which calls on before update*/
    public static void checkRequestedByAndInventoryAuthorityOnBeforeUpdate(List<Sobject> records,Map<Id, SObject> oldRecords) {

        //DCP-37305 - Map to hold Loction Id and loction's Inventory Authority.
         Map<Id,String> locationIdToInventoryAuthority = new Map<Id,String> ();
         for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
             SVMXC__RMA_Shipment_Order__c objOldPartOrder = (SVMXC__RMA_Shipment_Order__c)(oldRecords.get(objPartOrder.Id));
            //DCP- 37305, map to hold to location of po.
            if(objPartOrder.SVMXC__Destination_Location__c!=objOldPartOrder.SVMXC__Destination_Location__c && objPartOrder.SVMXC__Destination_Location__c!=null ) {
                locationIdToInventoryAuthority.put(objPartOrder.SVMXC__Destination_Location__c,'');
            } else if(objPartOrder.SVMXC__Destination_Location__c==null && objPartOrder.Is_Requested_By_Not_Inventory_Authority__c==true) {
                objPartOrder.Is_Requested_By_Not_Inventory_Authority__c=false;
            }
         }

         // DCP-37305, get Inventory Authority for the location ids.
        if(!locationIdToInventoryAuthority.isEmpty()) {
            PartsOrdersHelper.Locations locInIt = new PartsOrdersHelper.Locations();
            locInIt.initLocationsMap(locationIdToInventoryAuthority.keyset());
            if(mapLocations!=null && !mapLocations.isEmpty()) {
                for(SVMXC__Site__c objLoc :mapLocations.values()) {
                 locationIdToInventoryAuthority.put(objLoc.id,objLoc.Inventory_Authority__c);
                }
            }
        }
        for (SVMXC__RMA_Shipment_Order__c objPartOrder: (List < SVMXC__RMA_Shipment_Order__c > ) records) {
            // DCP-37305, check if requested by and Inventory Authority are same.
            if(!locationIdToInventoryAuthority.isEmpty()) {
                checkRequestedByAndInventoryAuthority(locationIdToInventoryAuthority,objPartOrder);
            }
        }
    }

    /** To call parts order validation methods */
    public static void validatePartsOrder(List<Sobject> records,Map<Id, SObject> oldRecords) {
        Set<Id> setPOIdCP = new Set<Id>();
        validatePartsOrderError(records,oldRecords);  
        validatePartsOrderPartsHelper(records,oldRecords);
        validatePartsOrderAggrementHelper(records,oldRecords);
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            SVMXC__RMA_Shipment_Order__c objOldPartOrder = (SVMXC__RMA_Shipment_Order__c)(oldRecords.get(objPartOrder.Id));
            if(objPartOrder.SVMXC__Source_Location__c == NULL || objPartOrder.Shipping_Location__c !=NULL || objPartOrder.SVMXC__Destination_Location__c!= NULL || String.isBlank(objPartOrder.SVMXC__Source_Location__c) || String.isNotBlank(objPartOrder.Shipping_Location__c) || String.isNotBlank(objPartOrder.SVMXC__Destination_Location__c)) {
                isNotValidPartsOrder = true;
                setPartsOrderHavingError.add(objPartOrder.Id);
            }
            //DCP-33613
            if (cp.Is_Channel_Partner__c == true && objPartOrder.Submit_for_Approval_CP__c && !objOldPartOrder.Submit_for_Approval_CP__c && objPartOrder.SVMXC__Order_Type__c == STRING_PART_ORDER_TYPE_RETURN) {
                    setPOIdCP.add(objPartOrder.Id);
            }
        }

        //DCP-33613
        if(setPOIdCP != null && !setPOIdCP.isEmpty()) {
            //modified Method signature to resue it for DCP-33613, added the new parameter for error string
             checkPOLRequestingStatus(setPOIdCP,Label.PODCIRCheckErrorCP,records);
        }
    }
    private static void validatePartsOrderError(List<Sobject> records,Map<Id, SObject> oldRecords) {
        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            SVMXC__RMA_Shipment_Order__c objOldPartOrder = (SVMXC__RMA_Shipment_Order__c)(oldRecords.get(objPartOrder.Id));
                //DCP-25283
                if(objPartOrder.Request_All_Part_Order_Lines__c != objOldPartOrder.Request_All_Part_Order_Lines__c 
                && objPartOrder.Request_All_Part_Order_Lines__c
                && (objPartOrder.No_Of_Instruments_POL__c > 0 || objPartOrder.GoodWill_Order_Lines__c > 0)
                && objPartOrder.SVMXC__Order_Type__c != 'return'
                && objPartOrder.SVMXC__Order_Status__c != 'Approved'
                && !(objPartOrder.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_ON_HOLD && String.isNotBlank(objPartOrder.Integration_Status__c) && !objPartOrder.Submit_POL_For_Approval__c)
                && !(objPartOrder.SVMXC__Order_Status__c == 'Open' && String.isNotBlank(objPartOrder.Integration_Status__c) && !objPartOrder.Submit_POL_For_Approval__c)
            ) {
                objPartOrder.addError(Label.POStatusSAPRequestError);
            }
        }
    }

    private static void validatePartsOrderPartsHelper(List<Sobject> records,Map<Id, SObject> oldRecords) {
        Set<Id> setPartsOrderId = new Set<Id>();
        Set<Id> setPartsOrderIdCP = new Set<Id>();

        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            SVMXC__RMA_Shipment_Order__c objOldPartOrder = (SVMXC__RMA_Shipment_Order__c)(oldRecords.get(objPartOrder.Id));
            if(objPartOrder.Request_All_Part_Order_Lines__c != objOldPartOrder.Request_All_Part_Order_Lines__c && objPartOrder.Request_All_Part_Order_Lines__c == true && objPartOrder.SVMXC__Order_Type__c == STRING_PART_ORDER_TYPE_RETURN) {
                setPartsOrderId.add(objPartOrder.Id);
                setPartsOrderIdCP.add(objPartOrder.Id);
            }
        }

        if(!setPartsOrderId.isEmpty()) {
            checkPOLRequestingStatus(setPartsOrderId,Label.POCompleteDCIRError,records);
            checkPOLRequestingStatusWhenDestroyed(setPartsOrderId,records);
        }

        if(!setPartsOrderIdCP.isEmpty()) {
            checkPOLRequestingStatusCP(setPartsOrderIdCP,records);
        }
    }
    private static void validatePartsOrderAggrementHelper(List<Sobject> records,Map<Id, SObject> oldRecords) {
        set<Id> setPOLoanerAgreementId = new set<Id>();      
        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            SVMXC__RMA_Shipment_Order__c objOldPartOrder = (SVMXC__RMA_Shipment_Order__c)(oldRecords.get(objPartOrder.Id));
            //DCP-41581
            if(objPartOrder.SVMXC__Order_Type__c == STRING_PART_ORDER_TYPE_SHIPMENT && ((objPartOrder.Request_All_Part_Order_Lines__c != objOldPartOrder.Request_All_Part_Order_Lines__c && objPartOrder.Request_All_Part_Order_Lines__c == true)||(objPartOrder.Submit_to_SAP__c != objOldPartOrder.Submit_to_SAP__c  && objPartOrder.Submit_to_SAP__c == true))) {
                setPOLoanerAgreementId.add(objPartOrder.Id);
            }
        }

        //DCP-41581
        if(!setPOLoanerAgreementId.isEmpty()) {
            checkPOLRequestingStatusLoaner(setPOLoanerAgreementId,Label.POLoanerAgreementCheckError,records);
        }
    }
    /**  to update Active Service BOM ID on PO*/
    public static void updateActiveServiceBOMonPOOnBeforeUpdate(List<Sobject> records,Map<Id, SObject> oldRecords) {
        //Set of Parts Order Ids for which Service BOM needs to be updated
        Set<Id> setWorkOrderServiceBOMToBeUpdated = new Set<Id>();
        Set<Id> setCaseServiceBOMToBeUpdated = new Set<Id>();
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        List<SVMXC__RMA_Shipment_Order__c> lstPartOrderServiceBOMToBeUpdated = new List<SVMXC__RMA_Shipment_Order__c>();
        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            SVMXC__RMA_Shipment_Order__c objOldPartOrder = (SVMXC__RMA_Shipment_Order__c)(oldRecords.get(objPartOrder.Id));
            //if a new work order is created with a case, then update its Work Order Status
            if(objPartOrder.SVMXC__Service_Order__c != null && objPartOrder.SVMXC__Service_Order__c != objOldPartOrder.SVMXC__Service_Order__c) {
                setWorkOrderServiceBOMToBeUpdated.add(objPartOrder.SVMXC__Service_Order__c);
                lstPartOrderServiceBOMToBeUpdated.add(objPartOrder);
            } else if(objPartOrder.SVMXC__Case__c != null && objPartOrder.SVMXC__Case__c != objOldPartOrder.SVMXC__Case__c) {
                setCaseServiceBOMToBeUpdated.add(objPartOrder.SVMXC__Case__c);
                lstPartOrderServiceBOMToBeUpdated.add(objPartOrder);
            }
            //DCP-30843
            if (cp.Is_Channel_Partner__c == true && objPartOrder.Submit_for_Approval_CP__c && !objOldPartOrder.Submit_for_Approval_CP__c) {
                objPartOrder.SVMXC__Order_Status__c=STRING_PART_ORDER_STATUS_PENDING_REVIEW ;
            }
        }

        // CMCM-195 - START
        if(!setWorkOrderServiceBOMToBeUpdated.isEmpty()) {
            setWorkOrderServiceBOMInit(setWorkOrderServiceBOMToBeUpdated);
        }
        if(!setCaseServiceBOMToBeUpdated.isEmpty()) {
            setCaseServiceBOMInit(setCaseServiceBOMToBeUpdated);
        }
        if(!lstPartOrderServiceBOMToBeUpdated.isEmpty()) {
            getActiveServiceBOMId(lstPartOrderServiceBOMToBeUpdated);
        }
        // CMCM-195 - END
    }

    /**
    *  @author Abhinav Gupta
    *  @description - DCP-51199 Check for Item Destroyed and COFD form checkbox of POL when status is changing to requested
    *  @parameters : setPartsOrderId- Id of part order , POL records
    *  @return : void
    **/
    private static void checkPOLRequestingStatusWhenDestroyed(Set<Id> setPartsOrderId,List<Sobject> records) {
        ilib_LogEvent.push(LOG_TITLE + 'checkPOLRequestingStatusWhenDestroyed');
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.checkPOLRequestingStatusWhenDestroyed');
        }
        try {
            Set<Id> setPartsOrderWithError = new Set<Id>();
            PartsOrdersHelper.PartsOrderLines pOLInIt = new PartsOrdersHelper.PartsOrderLines();
            if(!setPartsOrderId.isEmpty()) {
                pOLInIt.initPartsOrderLinesMap(setPartsOrderId);
                if(mapPartsOrderLines!=null && !mapPartsOrderLines.isEmpty()) {
                    for(SVMXC__RMA_Shipment_Line__c partsOrderLine : mapPartsOrderLines.values()) {
                        if(partsOrderLine.Item_Destroyed__c == True && partsOrderLine.Is_CofD_Filled__c == False) {
                            setPartsOrderWithError.add(partsOrderLine.SVMXC__RMA_Shipment_Order__c);
                        }
                    }
                }

                if(!setPartsOrderWithError.isEmpty()) {
                    for(SVMXC__RMA_Shipment_Order__c partsOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
                        if(setPartsOrderWithError.contains(partsOrder.Id)) {
                            partsOrder.addError(Label.POCompleteCOFDFormError); //CMCM-474
                        }
                    }
                }
            }
        } catch (Exception e) {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop();
        }
        
    }


    /**
    *  @author Prakhar Kumar
    *  @description - Check for Parts Order has the From Location filled in, and both the Shipping Location and To Location are blank. Ensures that the Parts Order Line has an Actual QTY greater than 0 and has a Product 
    *  @parameters : setPartsOrderId- Id of part order 
    *  @return : void
    **/
    private static void checkPOLRequestingStatusCP(Set<Id> setPartsOrderId,List<Sobject> records) {
        
        PartsOrdersHelper.PartsOrderLines pOLInIt = new PartsOrdersHelper.PartsOrderLines();
        pOLInIt.initPartsOrderLinesMap(setPartsOrderId);
        if(mapPartsOrderLines!=null && !mapPartsOrderLines.isEmpty()) {
            for(SVMXC__RMA_Shipment_Line__c partsOrderLine : mapPartsOrderLines.values()) {
                if(partsOrderLine.SVMXC__Product__c == NULL ||partsOrderLine.SVMXC__Actual_Quantity2__c <= 0) {
                    isNotValidPartsOrder = true;
                    setPartsOrderHavingError.add(partsOrderLine.SVMXC__RMA_Shipment_Order__c);          
                }            
            }
        }        
        
        if(!setPartsOrderHavingError.isEmpty()) {
        for(SVMXC__RMA_Shipment_Order__c partsOrder : (List<SVMXC__RMA_Shipment_Order__c>) records) {
                 if(setPartsOrderHavingError.contains(partsOrder.Id)) {
                 partsOrder.addError(Label.POQtyGreaterThanZeroError);
                }
            } 
        }        
    }

    /**
    *  @author Mandeep Singh
    *  @description - Check for Decontamination Required and DCIR form checkbox of POL when status is changing to requested 
    *  @parameters : setPartsOrderId- Id of part order 
    *  @return : void
    **/
    private static void checkPOLRequestingStatus(Set<Id> setPartsOrderId,String errorMessage,List<Sobject> records) {
        Set<Id> setPartsOrderWithError = new Set<Id>();
        PartsOrdersHelper.PartsOrderLines pOLInIt = new PartsOrdersHelper.PartsOrderLines();
        pOLInIt.initPartsOrderLinesMap(setPartsOrderId);
        if(mapPartsOrderLines!=null && !mapPartsOrderLines.isEmpty()) {
            for(SVMXC__RMA_Shipment_Line__c partsOrderLine : mapPartsOrderLines.values()) {
                if(partsOrderLine.Decontamination_Required__c == True &&  partsOrderLine.Is_DCIR_Filled__c == False) {
                    setPartsOrderWithError.add(partsOrderLine.SVMXC__RMA_Shipment_Order__c);
                }
            }
        }        
        
        if(!setPartsOrderWithError.isEmpty()) {
            for(SVMXC__RMA_Shipment_Order__c partsOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
                if(setPartsOrderWithError.contains(partsOrder.Id)) {
                    partsOrder.addError(errorMessage);
                }
            }
        }
    }

   

    /**
    *  @author Harsh Shukla
    *  @description - Check for Product Serial Number Profile Required, Condition Type and Loaner Agreement Signed checkbox of POL when status is changing to requested 
    *  @parameters : setPartsOrderId- Id of part order 
    *  @return : void
    **/
    private static void checkPOLRequestingStatusLoaner(Set<Id> setPOLoanerAgreementId,String errorMessage,List<Sobject> records) {
        Set<Id> setPartsOrderWithError = new Set<Id>();
        PartsOrdersHelper.PartsOrderLines pOLInIt = new PartsOrdersHelper.PartsOrderLines();
        pOLInIt.initPartsOrderLinesMap(setPOLoanerAgreementId);
        if(mapPartsOrderLines!=null && !mapPartsOrderLines.isEmpty()) {
            for(SVMXC__RMA_Shipment_Line__c partsOrderLine : mapPartsOrderLines.values()) {
                if(partsOrderLine.Service_Product_Type__c == 'Instrument' && partsOrderLine.SVMXC__Product__r.Serial_Number_Profile__c == 'IL02' && partsOrderLine.SVMXC__Product__r.Condition_Type__c == 'LOANER' && !partsOrderLine.Loaner_Agreement_Signed__c) {                  
                    setPartsOrderWithError.add(partsOrderLine.SVMXC__RMA_Shipment_Order__c);                  
                }
            }        
        }

        if(!setPartsOrderWithError.isEmpty()) {
            for(SVMXC__RMA_Shipment_Order__c partsOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
                if(setPartsOrderWithError.contains(partsOrder.Id)) {
                    partsOrder.addError(errorMessage);
                }
            }
        }
    }

    /**  to update Custom Fields  on PO*/
    public static void updatePOFieldsOnBeforeInsert(List<Sobject> records) {
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
         //refactor: populate case on Parts Order
         Map<Id, Id> woToCase = getCaseFromWorkOrder((List<SVMXC__RMA_Shipment_Order__c>)records);   
         for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
             //refactor: populate case on Parts Order    
            if(woToCase != null && !woToCase.isEmpty() && woToCase.containsKey(objPartOrder.SVMXC__Service_Order__c)) {
                objPartOrder.SVMXC__Case__c = woToCase.get(objPartOrder.SVMXC__Service_Order__c);
            }

            //DCP-30843
            if (cp.Is_Channel_Partner__c == true && objPartOrder.Submit_for_Approval_CP__c) {
            objPartOrder.SVMXC__Order_Status__c=STRING_PART_ORDER_STATUS_PENDING_REVIEW ;
            }
         }

    }

    /** populate case on Parts Order */        
    public static Map<Id, Id> getCaseFromWorkOrder(List<SVMXC__RMA_Shipment_Order__c> lstPartOrders) {
        
        Set<Id> setWorkOrderIds = new Set<Id>();
        Map<Id, Id> workOrderToCase = new Map<Id, Id>();
        for(SVMXC__RMA_Shipment_Order__c objPartsorder :lstPartOrders ) {
            if(objPartsorder.SVMXC__Service_Order__c != null) {
                setWorkOrderIds.add(objPartsorder.SVMXC__Service_Order__c);
            }
        }

        if(!setWorkOrderIds.isEmpty()) {
            PartsOrdersHelper.WorkOrdersLocal wOInIt = new PartsOrdersHelper.WorkOrdersLocal();
            wOInIt.initWorkOrderMap(setWorkOrderIds);
            if(mapWorkOrders!=null && !mapWorkOrders.isEmpty()) {
                for(SVMXC__Service_Order__c objWorkOrder : mapWorkOrders.values()) {
                    workOrderToCase.put(objWorkOrder.Id, objWorkOrder.SVMXC__Case__c);
                }
            }            
        }

        return workOrderToCase;     
    }


/**  to update Active Service BOM ID on PO*/
    public static void updateActiveServiceBOMonPOOnBeforeInsert(List<Sobject> records) {
        //Set of Parts Order Ids for which Service BOM needs to be updated
        Set<Id> setWorkOrderServiceBOMToBeUpdated = new Set<Id>();
        Set<Id> setCaseServiceBOMToBeUpdated = new Set<Id>();
        List<SVMXC__RMA_Shipment_Order__c> lstPartOrderServiceBOMToBeUpdated = new List<SVMXC__RMA_Shipment_Order__c>();
        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            //if a new work order is created with a case, then update its Work Order Status
            if(objPartOrder.SVMXC__Service_Order__c != null) {
                setWorkOrderServiceBOMToBeUpdated.add(objPartOrder.SVMXC__Service_Order__c);
                lstPartOrderServiceBOMToBeUpdated.add(objPartOrder);
            } else if(objPartOrder.SVMXC__Case__c != null) {
                setCaseServiceBOMToBeUpdated.add(objPartOrder.SVMXC__Case__c);
                lstPartOrderServiceBOMToBeUpdated.add(objPartOrder);
            }
        }

        // CMCM-195 - START
        if(!setWorkOrderServiceBOMToBeUpdated.isEmpty()) {
            setWorkOrderServiceBOMInit(setWorkOrderServiceBOMToBeUpdated);
        }
        if(!setCaseServiceBOMToBeUpdated.isEmpty()) {
            setCaseServiceBOMInit(setCaseServiceBOMToBeUpdated);
        }
        if(!lstPartOrderServiceBOMToBeUpdated.isEmpty()) {
            getActiveServiceBOMId(lstPartOrderServiceBOMToBeUpdated);
        }
       // CMCM-195 - END
    }
    private static void setWorkOrderServiceBOMInit(Set<Id> setWorkOrderServiceBOMToBeUpdated) {
        if(!setWorkOrderServiceBOMToBeUpdated.isEmpty()) {
            PartsOrdersHelper.WorkOrdersLocal wOInIt = new PartsOrdersHelper.WorkOrdersLocal();
            wOInIt.initWorkOrderMap(setWorkOrderServiceBOMToBeUpdated);
        }
    }
    private static void setCaseServiceBOMInit(Set<Id> setCaseServiceBOMToBeUpdated) {
        if(!setCaseServiceBOMToBeUpdated.isEmpty()) {
            PartsOrdersHelper.Cases caseInIt = new PartsOrdersHelper.Cases();
            caseInIt.initCasesMap(setCaseServiceBOMToBeUpdated);
        }
    }
    private static void getActiveServiceBOMId(List<SVMXC__RMA_Shipment_Order__c> lstPartOrderServiceBOMToBeUpdated) {  
        SVMXC__Service_Order__c objPOWorkOrder;
        Case objPOCase;
        Map<Id,List<SVMXC__RMA_Shipment_Order__c>> productIdToPartsOrderListFetchDefaultServiceBOM = new Map<Id,List<SVMXC__RMA_Shipment_Order__c>>();
        for(SVMXC__RMA_Shipment_Order__c partsOrder : lstPartOrderServiceBOMToBeUpdated) {   
            if(mapWorkOrders!=null && !mapWorkOrders.isEmpty()) {
              objPOWorkOrder = mapWorkOrders.get(partsOrder.SVMXC__Service_Order__c);  
            }
            if(mapCases!=null && !mapCases.isEmpty()) {
             objPOCase = mapCases.get(partsOrder.SVMXC__Case__c);     
            }
            if(isWorkOrderWithActiveServiceBOM(objPOWorkOrder)) {
                partsOrder.Service_Bill_Of_Materials__c = objPOWorkOrder.SVMXC__Component__r.Service_Bill_Of_Materials__c;
            } else if(isCaseWithActiveServiceBOM(objPOCase)) {      
                partsOrder.Service_Bill_Of_Materials__c = objPOCase.SVMXC__Component__r.Service_Bill_Of_Materials__c;
            } else if(objPOWorkOrder != null && objPOWorkOrder.SVMXC__Product__c != null) { //If the Work Order does not have an active Service BOM, create a set for which default Service BOM needs to be fetched.
                productIdToPartsOrderListFetchDefaultServiceBOM.putAll(addPartsOrderToDefaultServiceBOM(productIdToPartsOrderListFetchDefaultServiceBOM, objPOWorkOrder.SVMXC__Product__c, partsOrder));
            } else if(objPOCase != null && objPOCase.SVMXC__Product__c != null) { //If the Case does not have an active Service BOM, create a set for which default Service BOM needs to be fetched.
                productIdToPartsOrderListFetchDefaultServiceBOM.putAll(addPartsOrderToDefaultServiceBOM(productIdToPartsOrderListFetchDefaultServiceBOM, objPOCase.SVMXC__Product__c, partsOrder));
            } 
        }
        if(!productIdToPartsOrderListFetchDefaultServiceBOM.isEmpty()) {
            fetchDefaultServiceBOM(productIdToPartsOrderListFetchDefaultServiceBOM);
        }
    }
    private static boolean isWorkOrderWithActiveServiceBOM(SVMXC__Service_Order__c objPOWorkOrder) {
        return objPOWorkOrder != null && objPOWorkOrder.SVMXC__Component__c != null && objPOWorkOrder.SVMXC__Component__r.Service_Bill_Of_Materials__c != null && objPOWorkOrder.SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c;
    }
    private static boolean isCaseWithActiveServiceBOM(Case objPOCase) {
        return objPOCase != null && objPOCase.SVMXC__Component__c != null && objPOCase.SVMXC__Component__r.Service_Bill_Of_Materials__c != null && objPOCase.SVMXC__Component__r.Service_Bill_Of_Materials__r.Active__c;
    }
    private static Map<Id, List<SVMXC__RMA_Shipment_Order__c>> addPartsOrderToDefaultServiceBOM(Map<Id, List<SVMXC__RMA_Shipment_Order__c>> productIdToPartsOrderListFetchDefaultServiceBOM, Id productId, SVMXC__RMA_Shipment_Order__c partsOrder) {
        if (!productIdToPartsOrderListFetchDefaultServiceBOM.containsKey(productId)) {
            productIdToPartsOrderListFetchDefaultServiceBOM.put(productId, new List<SVMXC__RMA_Shipment_Order__c>());
        }
        productIdToPartsOrderListFetchDefaultServiceBOM.get(productId).add(partsOrder);
        return productIdToPartsOrderListFetchDefaultServiceBOM;
    }
    private static void fetchDefaultServiceBOM(Map<Id,List<SVMXC__RMA_Shipment_Order__c>> productIdToPartsOrderListFetchDefaultServiceBOM) {
        //Fetch default service BOM
        PartsOrdersHelper.ServiceBOMs serviceBOMInIt = new PartsOrdersHelper.ServiceBOMs();
        serviceBOMInIt.initServiceBOMsMap(productIdToPartsOrderListFetchDefaultServiceBOM.keySet());
        if(mapServiceBOMs != null && !mapServiceBOMs.isEmpty()) {
            for(Service_Bill_Of_Materials__c objServiceBOM : mapServiceBOMs.values()) {
                for(SVMXC__RMA_Shipment_Order__c objPartOrder : productIdToPartsOrderListFetchDefaultServiceBOM.get(objServiceBOM.Product__c)) {
                    objPartOrder.Service_Bill_Of_Materials__c = objServiceBOM.Id; 
                }
            }
        }             
    }

     /**
    *  @AUTHOR Soumya Ranjan Sahu
    *  @DESCRIPTION - To Populate Sales Area from Account
    *              
    *  @PARAM :       Map<id,SVMXC__RMA_Shipment_Order__c> idToPartsOrderMap
    *  @RETURN : void
    **/
    public static void getSalesAreaFromAccount(List<Sobject> records) {

        //Map of Parts Order for which Sales Area/To Location to be updated
        Map<id,SVMXC__RMA_Shipment_Order__c> idToPartsOrderMap = new Map<id,SVMXC__RMA_Shipment_Order__c>();

        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
             //To Populate Sales Area/To Location while creation of Parts Order
             if(objPartOrder.SVMXC__Order_Type__c == STRING_PART_ORDER_TYPE_SHIPMENT || objPartOrder.SVMXC__Order_Type__c == STRING_PART_ORDER_TYPE_RETURN) {
                idToPartsOrderMap.put(objPartOrder.Id,objPartOrder);
            }
        }
        if(!idToPartsOrderMap.isEmpty()) {
            map<id,id> idAccountToIdPO = getPartsOrders(idToPartsOrderMap);
            setSalesArea(idToPartsOrderMap,idAccountToIdPO);
        }
    }
    private static map<id,id> getPartsOrders(Map<id,SVMXC__RMA_Shipment_Order__c> idToPartsOrderMap) {
        map<id,id> idAccountToIdPO = new map<id,id>();
        if(!idToPartsOrderMap.isEmpty()) {
            //To find the qualifying parts orders
            for(id idPartsOrder:idToPartsOrderMap.keyset()) {
                if(idToPartsOrderMap.get(idPartsOrder).SVMXC__Company__c != null && idToPartsOrderMap.get(idPartsOrder).Sales_Area__c == null) {
                    idAccountToIdPO.put(idToPartsOrderMap.get(idPartsOrder).SVMXC__Company__c,idPartsOrder);
                }
            }
        }
        if(!idAccountToIdPO.isEmpty()) {
            PartsOrdersHelper.AccountSalesArea accSalesAreaInIt = new PartsOrdersHelper.AccountSalesArea();
            accSalesAreaInIt.initAccountSalesAreaMap(idAccountToIdPO.keyset());
        }
        return idAccountToIdPO;
    }
    private static void setSalesArea(Map<id,SVMXC__RMA_Shipment_Order__c> idToPartsOrderMap,map<id,id> idAccountToIdPO) {
        map<id,List<Account_Sales_Area__c>> idAccountToAccountSalesArea = new map<id,List<Account_Sales_Area__c>>();
        //To build a map of Account and Related Sales Area
        if(mapAccountSalesAreas !=null && !mapAccountSalesAreas.isEmpty()) {
            For(Account_Sales_Area__c objAccountSalesArea :mapAccountSalesAreas.values()) {
                if(!idAccountToAccountSalesArea.containsKey(objAccountSalesArea.Account__c)) {
                    idAccountToAccountSalesArea.put(objAccountSalesArea.Account__c, new List<Account_Sales_Area__c>());
                    idAccountToAccountSalesArea.get(objAccountSalesArea.Account__c).add(objAccountSalesArea);
                } else {
                    idAccountToAccountSalesArea.get(objAccountSalesArea.Account__c).add(objAccountSalesArea);
                }
            }
        }
        //To populate the sales area on parts order only if there is one related sales area of the account
        if(!idAccountToAccountSalesArea.isEmpty()) {
            Integer size = 1;
            for(id idAccount:idAccountToAccountSalesArea.keyset()) {
                if(idAccountToAccountSalesArea.get(idAccount).size() == size) {
                    idToPartsOrderMap.get(idAccountToIdPO.get(idAccount)).Sales_Area__c = idAccountToAccountSalesArea.get(idAccount)[0].Id;
                }
            }
        }
    }     

    /**
    * @description To call updatePartsOrderLinesStatus in After insert and After update
    * @author 
    * @param records 
    **/
    public void updateRequestedOrCancelledPOLStatus(List<Sobject> records) {
        if(trigger.operationType == system.TriggerOperation.BEFORE_INSERT || trigger.operationType == system.TriggerOperation.BEFORE_UPDATE) {
            setPartsOrderToBeRequested.clear();
            setPartsOrderToBeCanceled.clear();    
            for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
                //Refactor PB :: Parts_Order_Update_Part_Order_Lines_Status
                if(objPartOrder.Request_All_Part_Order_Lines__c && objPartOrder.Integration_Error_Message__c != System.Label.Parts_Order_Integration_Error_Msg) {
                    objPartOrder.Request_All_Part_Order_Lines__c=false;
                    triggerSAPIntegration = true;
                    objPartOrder.Integration_Status__c = ''; //INC0328485
                    setPartsOrderToBeRequested.add(objPartOrder.Id);
                }
                if(objPartOrder.Cancel_All_Part_Order_Lines__c) {
                    objPartOrder.Cancel_All_Part_Order_Lines__c=false;
                    objPartOrder.SVMXC__Order_Status__c=STRING_PART_ORDER_STATUS_CANCELED;
                    setPartsOrderToBeCanceled.add(objPartOrder.Id);
                }
            }
        }
        
		if(trigger.operationType == system.TriggerOperation.AFTER_INSERT || trigger.operationType == system.TriggerOperation.AFTER_UPDATE) {
            set<Id> requestedOrCanceledPoIds = new set<Id>();  
            requestedOrCanceledPoIds.addAll(setPartsOrderToBeRequested);
            requestedOrCanceledPoIds.addAll(setPartsOrderToBeCanceled);   
            //Refactor Parts_Order_Update_Part_Order_Lines_Status
            if(!setPartsOrderToBeRequested.isEmpty()) {
                updatePartsOrderLinesStatus(requestedOrCanceledPoIds,STRING_PART_ORDER_LINE_STATUS_REQUESTED,setPartsOrderToBeRequested,records);
            }
            if(!setPartsOrderToBeCanceled.isEmpty()) {
                updatePartsOrderLinesStatus(requestedOrCanceledPoIds,STRING_PART_ORDER_STATUS_CANCELED,setPartsOrderToBeCanceled,records);
            }
            //End of Refactor Parts_Order_Update_Part_Order_Lines_Status
        }    
    }

    /**
     *  @AUTHOR Soumya Ranjan Sahu
     *  @DESCRIPTION - To Update Parts Order Lines Status
     *              
     *  @PARAM :     set<id> setPartsOrder, string strPOLStatus
     *  @RETURN : void
     **/
     
    public void updatePartsOrderLinesStatus(set<id> requestedOrCanceledPoIds, string strPOLStatus,set<id> setPartsOrderIds,List<Sobject> records) {
        PartsOrdersHelper.PartsOrderLines pOLInIt = new PartsOrdersHelper.PartsOrderLines();
        pOLInIt.initPartsOrderLinesMap(requestedOrCanceledPoIds);        
        if(strPOLStatus==STRING_PART_ORDER_LINE_STATUS_REQUESTED) {
            if(mapPartsOrderLines!=null && !mapPartsOrderLines.isEmpty()) {
                for(SVMXC__RMA_Shipment_Line__c objPartsOrderLine : mapPartsOrderLines.values()) {
                    if(setPartsOrderIds.contains(objPartsOrderLine.SVMXC__RMA_Shipment_Order__c) && (objPartsOrderLine.SVMXC__Line_Status__c=='Open' || objPartsOrderLine.SVMXC__Line_Status__c==STRING_PART_ORDER_STATUS_ON_HOLD)) {
                        if(mapPartsOrderLinesToUpdate.containsKey(objPartsOrderLine.Id)) {
                            mapPartsOrderLinesToUpdate.get(objPartsOrderLine.Id).SVMXC__Line_Status__c=STRING_PART_ORDER_LINE_STATUS_REQUESTED;
                        } else {
                            objPartsOrderLine.SVMXC__Line_Status__c=STRING_PART_ORDER_LINE_STATUS_REQUESTED;
                            mapPartsOrderLinesToUpdate.put(objPartsOrderLine.Id,objPartsOrderLine);
                        }                            
                    }
                }
            }
        } else if(strPOLStatus==STRING_PART_ORDER_STATUS_CANCELED) {
            if(mapPartsOrderLines!=null && !mapPartsOrderLines.isEmpty()) {
                for(SVMXC__RMA_Shipment_Line__c objPartsOrderLine : mapPartsOrderLines.values()) {
                    if(setPartsOrderIds.contains(objPartsOrderLine.SVMXC__RMA_Shipment_Order__c) && objPartsOrderLine.SVMXC__Line_Status__c!=STRING_PART_ORDER_STATUS_CANCELED) {
                        if(mapPartsOrderLinesToUpdate.containsKey(objPartsOrderLine.Id)) {
                            mapPartsOrderLinesToUpdate.get(objPartsOrderLine.Id).SVMXC__Line_Status__c=STRING_PART_ORDER_STATUS_CANCELED;
                        } else {
                            objPartsOrderLine.SVMXC__Line_Status__c=STRING_PART_ORDER_STATUS_CANCELED;
                            mapPartsOrderLinesToUpdate.put(objPartsOrderLine.Id,objPartsOrderLine);
                        }
                    }
                }
            }
        }
    }

    /** update requester manager and requester manager's manager which calls OnBeforeInsert */
    public static void updateRequsterMangerOnPartsOrderOnBeforeInsert(List<Sobject> records) {

        //Refactor PB :: Parts_Order_Populate_User_Related_Fields
        Map <id,map<id,id>> idOwnerToManager = new Map <id,map<id,id>>();
        set<id> setOwnerIds = new set<id>();

        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {        
        //Refactor PB :: Parts_Order_Populate_User_Related_Fields
            if(objPartOrder.OwnerId != null && string.valueOf(objPartOrder.OwnerId).startsWith('005')) {
                setOwnerIds.add(objPartOrder.OwnerId);
            }        
        }
        //Refactor PB :: Parts_Order_Populate_User_Related_Fields
        if(!setOwnerIds.isEmpty()) {
            idOwnerToManager=getOwnerManagerFields(setOwnerIds);
        }
        for (SVMXC__RMA_Shipment_Order__c objPartOrder: (List < SVMXC__RMA_Shipment_Order__c > ) records) {
            //Refactor PB :: Parts_Order_Populate_User_Related_Fields
            if(idOwnerToManager.containsKey(objPartOrder.OwnerId)) {
                for(id idManager :idOwnerToManager.get(objPartOrder.OwnerId).keyset()) {
                    objPartOrder.Requesters_Manager__c = idManager;
                    objPartOrder.Requester_Managers_Manager__c = idOwnerToManager.get(objPartOrder.OwnerId).get(idManager);
                }
            }
        }

    }
    
    /**
     *  @AUTHOR Soumya Ranjan Sahu
     *  @DESCRIPTION - To get Parts Order Manager and Manager's Manager
     *  @PARAM :     Map<id,Date> idToPOReqDelDate
     *  @RETURN : void
     **/
     
    public static Map<id,map<id,id>> getOwnerManagerFields(set<id> setOwnerIds) {
        Map<id,map<id,id>> idUserToManager = new Map<id,map<id,id>>();
        List<User> lstUser = new List<User>();
        //DCP-30843
        setOwnerIds.add(userinfo.getuserid());
        PartsOrdersHelper.Users userInIt = new PartsOrdersHelper.Users();
        userInIt.initUsersMap(setOwnerIds);
        
        set<id> setFinalOwnerIds = new set<id>();

        for(id userInstance :setOwnerIds) {
            if(mapUsers!=null && !mapUsers.isEmpty()) {
                if(mapUsers.containsKey(userInstance) && mapUsers.get(userInstance).IsActive && string.valueOf(mapUsers.get(userInstance).Profile.Name).contains('Channel Partner')) {
                    setFinalOwnerIds.add(userinfo.getuserid());
                } else {
                    setFinalOwnerIds.add(userInstance);
                }
            }
        }
        system.debug('******setFinalOwnerIds'+setFinalOwnerIds);
        // End of DCP-30843
        
        if(!setFinalOwnerIds.isEmpty()) {
            for(id usrId : setFinalOwnerIds) {
                if(mapUsers.containsKey(usrId) && !string.valueOf(mapUsers.get(usrId).Profile.Name).contains('Channel Partner')) {
                    lstUser.add(mapUsers.get(usrId));
                }  
            }            
        }
        if(!lstUser.isEmpty()) {
            for(User objUser :lstUser) {
                if(!idUserToManager.containsKey(objUser.Id) ) {
                    idUserToManager.put(objUser.Id, new map<id,id>());
                    idUserToManager.get(objUser.Id).put(objUser.ManagerId,objUser.Manager.ManagerId);
                }                
            }            
        }
        return idUserToManager;
     }    

    /** to process invetory authoriti in location which calls on before insert*/
    public static void checkRequestedByAndInventoryAuthorityOnBeforeInsert(List<Sobject> records) {
        //DCP-37305 - Map to hold Loction Id and loction's Inventory Authority.
         Map<Id,String> locationIdToInventoryAuthority = new Map<Id,String> ();
         for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
             //DCP-37305 map to hold to location of po.
            if( objPartOrder.SVMXC__Destination_Location__c!=null ) {
                locationIdToInventoryAuthority.put(objPartOrder.SVMXC__Destination_Location__c,'');
            }
         }
            
        if(!locationIdToInventoryAuthority.isEmpty()) {
            PartsOrdersHelper.Locations locInIt = new PartsOrdersHelper.Locations();
            locInIt.initLocationsMap(locationIdToInventoryAuthority.keyset());
            if(mapLocations!=null && !mapLocations.isEmpty()) {
                for(SVMXC__Site__c objLoc :mapLocations.values()) {
                    locationIdToInventoryAuthority.put(objLoc.id,objLoc.Inventory_Authority__c);
                }
            }           
        }
        for(SVMXC__RMA_Shipment_Order__c objPartOrder : (List<SVMXC__RMA_Shipment_Order__c>)records) {
            // DCP-37305 check if requested by and inventory location are same.
            if(!locationIdToInventoryAuthority.isEmpty()) {
                checkRequestedByAndInventoryAuthority(locationIdToInventoryAuthority,objPartOrder);
            }
        }
    }

    /**
	*  @author Sandeep Ram Chatrathi
	*  @description - DCP-37305
	*               1. Checks if part order requested by and inventory Authority are same.
	**/
    public static void checkRequestedByAndInventoryAuthority(Map<Id,String> locationIdToInventoryAuthority,SVMXC__RMA_Shipment_Order__c  objPartOrder) {
        String strInventoryAuthority = locationIdToInventoryAuthority.containskey(objPartOrder.SVMXC__Destination_Location__c)? locationIdToInventoryAuthority.get(objPartOrder.SVMXC__Destination_Location__c) : '';
        if(!String.isBlank(objPartOrder.Requested_By_Name__c)&& !objPartOrder.Requested_By_Name__c.equalsIgnoreCase(strInventoryAuthority)) {
            objPartOrder.Is_Requested_By_Not_Inventory_Authority__c = true;
        } else {
            objPartOrder.Is_Requested_By_Not_Inventory_Authority__c = false;
        }
    }
    
    /** call a SAP callout in queueable manager */
    public static void asyncCallOut(set<Id> setPartOrderId, ilib_Queueablethread queueableThread) {
        
        if(setPartOrderId!=null && !setPartOrderId.IsEmpty()) {
            queueableThread.logandQueue(new PartsOrderQueueable(null, 'sendPartsOrderToSAP',setPartOrderId),'PartsOrderQueueable','sendPartsOrderToSAP');
        }
        
    }

   /**
    *  @AUTHOR Vaibhav Parashar
    *  @DESCRIPTION - Parts Order creation in SAP (Inbound to SAP from SVMX)
    *              
    *  @PARAM :       set<Id> setPartOrderId
    *  @RETURN : void
    *   //@future(callout = true)
    **/  
    public static void sendPartsOrderToSAP(set<Id> setPartOrderId) {
        PartsOrderDataSender partsOrderSyncSendInterface = new PartsOrderDataSender();
        //INC0297731
        //list of parts orders to update
       
        for(SVMXC__RMA_Shipment_Order__c objPO : new PartsOrdersSelector().selectPartsOrderWithPOL(setPartOrderId)) {
            if(objPO.Request_All_Part_Order_Lines_CS_Override__c || !objPO.SVMXC__RMA_Shipment_Line__r.isEmpty()) {
                if(!Test.isRunningTest()){partsOrderSyncSendInterface.callout(objPO.Id);}
            } else {
                //update the integration error message if that parts order doesn't have any POL.
                if(mapPartsOrdersToUpdate.containsKey(objPO.Id)) {
                    mapPartsOrdersToUpdate.get(objPO.Id).Integration_Error_Message__c = Label.PartsOrderWithNoPOL;
                    mapPartsOrdersToUpdate.get(objPO.Id).Integration_Message_Details_Text__c = Label.PartsOrderWithNoPOL;
                    mapPartsOrdersToUpdate.get(objPO.Id).Submit_to_SAP__c = false;
                } else {
                    objPO.Integration_Error_Message__c = Label.PartsOrderWithNoPOL;
                	objPO.Integration_Message_Details_Text__c = Label.PartsOrderWithNoPOL;
                	objPO.Submit_to_SAP__c = false;
                    mapPartsOrdersToUpdate.put(objPO.Id,objPO);
                }
            }            
        }
    }

/*@author - Tapas
* @Description - DCP-43634, post comments to approval submitter when goodwill approval is approved/denied
*/    	
    public void postCommentsIfGoodwillApprovedOrDenied(List<SVMXC__RMA_Shipment_Order__c> records,Map<Id,SVMXC__RMA_Shipment_Order__c> oldRecords) {
        List<SVMXC__RMA_Shipment_Order__c> lstApprovedRejectedPOs = new List<SVMXC__RMA_Shipment_Order__c>();
        Set<String> setApprovedOrRejectedStatuses = new Set<String>{STRING_PART_ORDER_STATUS_APPROVED,STRING_PART_ORDER_STATUS_OPEN};

        for(SVMXC__RMA_Shipment_Order__c objPO : records) {
            SVMXC__RMA_Shipment_Order__c objOldPO = oldRecords.get(objPO.Id);
            if(objPO.No_Of_Instruments_POL__c == 0 && objPO.GoodWill_Order_Lines__c > 0 && objOldPO.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_PENDING_APPROVAL && setApprovedOrRejectedStatuses.contains(objPO.SVMXC__Order_Status__c)) {
                lstApprovedRejectedPOs.add(objPO);
            }
        }

        if(lstApprovedRejectedPOs.isEmpty()) {
            return;
        }
        Set<Id> setWOIds = UtilsCollection.getSetOfIds(records, 'SVMXC__Service_Order__c');
        /*Map < Id, SVMXC__Service_Order__c > idToworkOrder = new Map < Id, SVMXC__Service_Order__c > (new WorkOrdersSelector().selectWorkOrders(setWOIds));
        */
        PartsOrdersHelper.WorkOrdersLocal wOInIt = new PartsOrdersHelper.WorkOrdersLocal();
        wOInIt.initWorkOrderMap(setWOIds);
        Boolean isApproved = false;
        //List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();

        for(SVMXC__RMA_Shipment_Order__c objPartsOrder : lstApprovedRejectedPOs) {
            SVMXC__Service_Order__c objWO = mapWorkOrders.get(objPartsOrder.SVMXC__Service_Order__c);
            isApproved = (objPartsOrder.SVMXC__Order_Status__c == STRING_PART_ORDER_STATUS_APPROVED) ? true:false;

            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

            mentionSegmentInput.id = objPartsOrder.OwnerId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);

            textSegmentInput.text = '\n Parts Order '+objPartsOrder.Name+' on Work Order '+objWO.Name+' has been '+ (isApproved ? 'Approved':'Denied') +' for use of Goodwill.' + (isApproved ? '':' Please work with your manager on how to proceed further.');
            messageBodyInput.messageSegments.add(textSegmentInput);

            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = objPartsOrder.OwnerId;

            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
            batchInputs.add(batchInput);
        }

        //ConnectApi.ChatterFeeds.postFeedElementBatch(null, batchInputs);
    }

    //PRB0048294 - Start
     public without sharing class PartOrderWithoutSharingInner{

         public void unlockPartOrder(List<SVMXC__RMA_Shipment_Order__c> lstPOs){
            if(!lstPOs.isEmpty()){
                Approval.UnlockResult[] unlockResults = Approval.Unlock(lstPOs);
            }
        }
    }
    //PRB0048294 - End
    /*@author - Gaurav
* @Description - CMCM-9516 update the shipped all parts order line to false
*/  
    @future
    public static void updateShippedAllPartsOrderLineFieldandStatus (Boolean shipmentallPartsOrder, Set<Id> shipmentOrderId){
        List<SVMXC__RMA_Shipment_Order__c> listToUpdate = new List<SVMXC__RMA_Shipment_Order__c>();
        for(id shipmentID : shipmentOrderId){
            SVMXC__RMA_Shipment_Order__c updateShipment = new SVMXC__RMA_Shipment_Order__c(id=shipmentID);
            updateShipment.Shipped_All_Parts_Order_Line__c = shipmentallPartsOrder;
            listToUpdate.add(updateShipment);
        }

        if(listToUpdate!=null && !listToUpdate.isEmpty()){
            skipPartsOrderTrigger = true;
            UPDATE listToUpdate;
        }
    }

    /*@author - Gaurav
    * @Description - CMCM-9516 update the shipped all parts order line to false
    */  
    public static void updateRelatedShipmentLineStatus(list<SVMXC__RMA_Shipment_Order__c> shipmentOrderList,map<id,SVMXC__RMA_Shipment_Order__c> oldMap){	
        set<id> shipmentOrderIdSet = new set<id>();
        boolean shipmentallPartsOrder = false;
        List<SVMXC__RMA_Shipment_Line__c> shipmentLineListToUpdate = new List<SVMXC__RMA_Shipment_Line__c>();
        
        for(SVMXC__RMA_Shipment_Order__c shipOrder: shipmentOrderList){
            SVMXC__RMA_Shipment_Order__c objOldShipOrder = oldMap.get(shipOrder.Id);
            if(shipOrder.Bypass_Validation_Rules_for_Integration__c == objOldShipOrder.Bypass_Validation_Rules_for_Integration__c && shipOrder.SVMXC__Order_Status__c !=objOldShipOrder.SVMXC__Order_Status__c && shipOrder.SVMXC__Order_Status__c==label.PartsOrderLineOnHold){
                shipmentOrderIdSet.add(shipOrder.id);
            }
            
            if(shipOrder.Shipped_All_Parts_Order_Line__c == true){
                shipmentallPartsOrder = true;
                shipmentOrderIdSet.add(shipOrder.id);
            }
        }

        if(!shipmentOrderIdSet.isEmpty()){
            if(partsOrdersShippedandDeliveredList.isEmpty()){
                partsOrdersShippedandDeliveredList = new PartsOrderLineSelector().selectPartsOrderLineforShippedandDelivedStatus(shipmentOrderIdSet);
            }

            if(partsOrdersShippedandDeliveredList!=null && !partsOrdersShippedandDeliveredList.isEmpty()){
                for(SVMXC__RMA_Shipment_Line__c shipline : partsOrdersShippedandDeliveredList){
                    if(shipline.SVMXC__Line_Status__c!= label.PartsOrderLineShipped && shipline.SVMXC__Line_Status__c!= label.PartsOrderLineDelivered){
                        shipline.SVMXC__Line_Status__c = label.PartsOrderLineOnHold;
                    }
                    if(shipmentallPartsOrder == true && (shipline.SVMXC__Line_Status__c == label.PartsOrderLineOnHold || shipline.SVMXC__Line_Status__c == label.PartsOrderLineOpen || shipline.SVMXC__Line_Status__c == label.PartsOrderLineRequested)){
                        shipline.SVMXC__Line_Status__c= label.PartsOrderLineShipped;
                    }
                    shipmentLineListToUpdate.add(shipline);
                }
            }
        }
        if(shipmentLineListToUpdate!=null && !shipmentLineListToUpdate.isEmpty()){
            bypassPartsOrderStatusUpdate = true;
            UPDATE shipmentLineListToUpdate;
            
            //as the current transaction will be read-only so making this false in future transaction
            if(shipmentallPartsOrder == true && shipmentOrderIdSet!=null && !shipmentOrderIdSet.isEmpty()){
                updateShippedAllPartsOrderLineFieldandStatus(false,shipmentOrderIdSet);
            }
        }
    }
    
}
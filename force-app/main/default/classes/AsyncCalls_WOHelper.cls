/**
* @author Shivani Jain
* @date 6th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run queueable 
*                        logic on After Insert event on Work Order 
* Dhairya Shah 17 April 2024 CMCM-6760
*/ 
public with sharing class AsyncCalls_WOHelper {

    private static final String LOG_TITLE = 'AsyncCalls_WOHelper';
    public static Map<Id, Case> caseIdToCase = new Map<Id, Case> (); //Added as part of CMCM-1019
    
    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To prepare List of related records before executing any Bussinsess Logic
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public static void asyncCallsonWOAfterInsert(List<Sobject> records, Id idEstimatesRecordTypeId, Id idFieldServiceRecordType) {
        //DCP-45928
        ilib_LogEvent.push(LOG_TITLE + '.asyncCallsonWOAfterInsert()');
        List<Admin_Operation__e> lstAdminOperation = new List<Admin_Operation__e>();
        //DCP-33872
        ilib_Queueablethread  queueableThread=new ilib_Queueablethread('WorkOrdersAfterInsert');
        //DCP-10944
        List<SVMXC__Service_Order__c> lstInstallWO = new List<SVMXC__Service_Order__c>();

        //DCP-39750
        Map<Id,String> accountIdToAccountGroup = new Map<Id,String>();

        Map<Id,Id> woIdToAccId = new Map<Id,Id> ();
        Map<Id,Id> woIdToSoldAccId = new Map<Id,Id> ();
        set<Id> setWOIDToUpdate = new set<Id>();
        //DCP-17063
        Map<Id, Id> caseIdToWorkOrderIds = new Map<Id, Id>();
        //DCP-46058
        Set<Id> setWorkOrdersToSync = new Set<Id>();
        for(Account objAccount : WorkOrders.lstAccountRecords){
            accountIdToAccountGroup.put(objAccount.id,objAccount.Account_Group__c);
            
        }

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
        addWOWithCaseAndAccountNotNull(objWorkOrder,lstInstallWO,caseIdToWorkOrderIds,accountIdToAccountGroup,woIdToAccId,woIdToSoldAccId,setWOIDToUpdate);
        processAsyncCallsOnRelatedRecord(objWorkOrder,idEstimatesRecordTypeId,lstAdminOperation,queueableThread,idFieldServiceRecordType,setWorkOrdersToSync);
        }

        queueableCallsOnWOInsert(lstInstallWO,queueableThread,caseIdToWorkOrderIds,woIdToAccId,woIdToSoldAccId,setWOIDToUpdate,records);
        //DCP-33872
        if(!queueableThread.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThread);
        }

        //DCP-45928
        if(!lstAdminOperation.isEmpty()){
            EventBus.publish(lstAdminOperation);  
        }
        //DCP-46058
        if(!setWorkOrdersToSync.isEmpty()){
            WorkOrders.sendWorkOrderToSAP(setWorkOrdersToSync);
        }
        ilib_LogEvent.pop();
    }

    /**
    * @description :Add WO id when case and account is not null on work order creation
    * @param objWorkOrder 
    * @param lstInstallWO 
    * @param caseIdToWorkOrderIds 
    * @param accountIdToAccountGroup 
    * @param woIdToAccId 
    * @param woIdToSoldAccId 
    * @param setWOIDToUpdate 
    **/
    public static void addWOWithCaseAndAccountNotNull(SVMXC__Service_Order__c objWorkOrder,List<SVMXC__Service_Order__c> lstInstallWO,Map<Id, Id> caseIdToWorkOrderIds,
    Map<Id,String> accountIdToAccountGroup,Map<Id,Id> woIdToAccId,Map<Id,Id> woIdToSoldAccId,set<Id> setWOIDToUpdate)
    {
             //DCP-10944 Create set of Cases associated with Install WO
             if(objWorkOrder.SVMXC__Case__c != null) {
                lstInstallWO.add(objWorkOrder);
                caseIdToWorkOrderIds.put(objWorkOrder.SVMXC__Case__c, objWorkOrder.Id);   
            }

            if(objWorkOrder.SVMXC__Company__c!=null && !accountIdToAccountGroup.isEmpty() &&  accountIdToAccountGroup.containskey(objWorkOrder.SVMXC__Company__c) && (accountIdToAccountGroup.get(objWorkOrder.SVMXC__Company__c)== WorkOrders.STRING_ACCOUNT_ACCOUNTGROUP_SOLDTO||accountIdToAccountGroup.get(objWorkOrder.SVMXC__Company__c)==WorkOrders.STRING_ACCOUNT_ACCOUNTGROUP_ULTIMATECONSIGNEE ) ){
                woIdToAccId.put(objWorkOrder.id,objWorkOrder.SVMXC__Company__c);
                woIdToSoldAccId.put(objWorkOrder.id,null);
                setWOIDToUpdate.add(objWorkOrder.id);
            }
            
    }
    
    /**
    * @description :Queueable call for creation of Parts order/Billable Create Estimate WD/set workorder Id on certain condition
    * @param objWorkOrder 
    * @param idEstimatesRecordTypeId 
    * @param lstAdminOperation 
    * @param queueableThread 
    * @param idFieldServiceRecordType 
    * @param setWorkOrdersToSync 
    **/
    public static void processAsyncCallsOnRelatedRecord(SVMXC__Service_Order__c objWorkOrder,Id idEstimatesRecordTypeId,List<Admin_Operation__e> lstAdminOperation,ilib_Queueablethread  queueableThread,
    Id idFieldServiceRecordType,Set<Id> setWorkOrdersToSync)
    {
        //DCP-45928
            if(!objWorkorder.Partner_Work_Order__c && objWorkOrder.RecordTypeId == idEstimatesRecordTypeId)
                lstAdminOperation.add(new Admin_Operation__e(Name__c = 'BillableCreateEstimateWD', Related_Record__c = objWorkorder.id));
            //DCP-45793: Start- Add to list of queueables
            if(String.isNotBlank(objWorkorder.PO_Number__c) && !WorkOrders.setWOIdForAutoPOCreation.contains(objWorkorder.id)){
                WorkOrders.setWOIdForAutoPOCreation.add(objWorkorder.id);
                queueableThread.logandQueue(new CreatePartsOrderFromWO(objWorkorder),'CreatePartsOrderFromWO','execute');
                ilib_LogEvent.message('@@45793 CreatePartsOrderFromWO called in after insert for: '+objWorkorder.id);
            }
            //DCP-45793: End- Add to list of queueables
            //DCP-46058
            if(objWorkorder.SVMXC__Order_status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED && objWorkorder.RecordTypeId == idFieldServiceRecordType && objWorkorder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES){
                setWorkOrdersToSync.add(objWorkorder.Id);
            }
    }
    /**
    * @description :queueable calls on WO insert
    * @param lstInstallWO 
    * @param queueableThread 
    * @param caseIdToWorkOrderIds 
    * @param woIdToAccId 
    * @param woIdToSoldAccId 
    * @param setWOIDToUpdate 
    * @param records 
    **/
    public static void queueableCallsOnWOInsert(List<SVMXC__Service_Order__c> lstInstallWO,ilib_Queueablethread  queueableThread,Map<Id, Id> caseIdToWorkOrderIds,
    Map<Id,Id> woIdToAccId,Map<Id,Id> woIdToSoldAccId,set<Id> setWOIDToUpdate,List<Sobject> records)
    {

        //DCP-17063
        if(!caseIdToWorkOrderIds.isEmpty()) {
            queueableThread.logandQueue(new FAIQueueable_WOHelper(caseIdToWorkOrderIds, 'linkFieldActionItemsFromCase'), WorkOrders.WORKORDER_QUEUEABLE, 'linkFieldActionItemsFromCase');
         }


        //DCP-39750-call method updateSoldToOnWO from queuable interface.
        if(!woIdToAccId.isEmpty() && !woIdToSoldAccId.isEmpty() && !setWOIDToUpdate.isEmpty()) {
            //Incident INC0299361 fix
            queueableThread.logandQueue(new UpdateSoldToQueueable_WOHelper(woIdToAccId, woIdToSoldAccId, setWOIDToUpdate), WorkOrders.WORKORDER_QUEUEABLE, WorkOrders.METHOD_UPDATE_SOLD_TO_ON_WO);
        }
        //moving insert wo resource method to queueable for fixing too many queueable jobs error for PM WOs
        queueableThread.logandQueue(new InsertWOResourceQueueable_WOHelper((List<SVMXC__Service_Order__c>) records), WorkOrders.WORKORDER_QUEUEABLE, WorkOrders.INSERT_WO_RESOURCE_RECORD);
        ilib_LogEvent.message('queueableThread -->'+queueableThread );

        //START CMCP-23 [Call Method updatePartnerWOFlagForVADAccount from queueable interface].
        queueableThread.logandQueue(new PartnerFlagVDQueueable_WOHelper((List<SVMXC__Service_Order__c>) records),WorkOrders.WORKORDER_QUEUEABLE, WorkOrders.METHOD_UPDATE_PARTNER_WO_FLAG_FOR_VAD_ACCOUNT);
        //END CMCP-23

    }
    /*
     *  
     *  @AUTHOR Digvijay(code refactored)
     *  @DESCRIPTION - Method to Any Async execution after WO Update goes here. 
     *  @PARAM :  Old Map of Work Orders.
     *  @RETURN : void
     */
    public static void asyncprocessesonAfterWOUpdate(Map<Id, SObject> mapOld, Id idEstimatesRecordTypeId) {
        ilib_LogEvent.push(LOG_TITLE + '.asyncprocessesonAfterWOUpdate()');

        List<Admin_Operation__e> lstAdminOperation = new List<Admin_Operation__e>();
        //DCP-39744
        Map<Id,Id> mapWOIdtoCaseId=new  Map<Id,Id>();
        //DCP-40191
        Set<Id> setWOwithIPChanges = new Set<Id>();
        //added for INC0271937
        set<Id> setWoIdToUpdateWdAsBillable = new set<Id>(); //DCP-38965
        //idToWORecForUpdate - check important note in updateWOfields method
        Map<Id, SVMXC__Service_Order__c> idToWORecForUpdate = new Map<Id, SVMXC__Service_Order__c>(); //DCP-42922
        Set<Id> woIdsWithNewIPOrProduct = new Set<Id>(); //DCP-42922
        ilib_Queueablethread queueableThreadAfterUpdate = new ilib_Queueablethread('WorkOrdersAfterUpdate');     
                
        //DCP-39750
        Map<Id,String> accountIdToAccountGroup = new Map<Id,String>();

        Map<Id,Id> woIdToAccId = new Map<Id,Id> ();
        Map<Id,Id> woIdToSoldAccId = new Map<Id,Id> ();
        set<Id> setWOIDToUpdate = new set<Id>();
        List<Id> lstWorkOrdersWithUpdatedOwners = new List<Id>();
        List<SVMXC__Service_Order__c> lstWorkOrdersAutoClose = new List<SVMXC__Service_Order__c>();
        //DCP-45563
        Boolean isTPSPOwnerChanged = false;

        Set<Id> setAbandonedWOId = new Set<Id>();
        Set<Id> setAbandonedWOOppId = new Set<Id>();

        //START CMCP-23
        List<SVMXC__Service_Order__c> lstWorkOrderWithUpdatedAccount=new List<SVMXC__Service_Order__c>();
        //END CMCP-23 
       
        for(Account objAccount : WorkOrders.lstAccountRecords) { 
            accountIdToAccountGroup.put(objAccount.id,objAccount.Account_Group__c);
            
        }
        
        Set<Id> setWorkOrderIdsToAwaitingParts = new Set<Id>();//CMCP-16
        Set<Id> setWorkOrderIdsFromAwaitingParts = new Set<Id>();//CMCP-16
        
        Set<Id> setNewWorkorderCaseId = new Set<Id>();   
        // CMCM-1019 - Start 
        for(Id idWorkOrder : mapOld.keySet()) {	
        SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);	
            if(objNewWorkorder.SVMXC__Case__c != null){	
                setNewWorkorderCaseId.add(objNewWorkorder.SVMXC__Case__c);	
            }
        }
        //CMCM-5307
        if(caseIdToCase.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            caseIdToCase = new Map<Id, Case>(new CasesSelector().selectCasesFromSetIds(setNewWorkorderCaseId));
        }
        // CMCM-1019 - End 
        for(Id idWorkOrder : mapOld.keySet()) {
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);

            processAwaitingStatusAndCreateOppQuote(objNewWorkorder,objOldWorkorder,setWorkOrderIdsToAwaitingParts,setWorkOrderIdsFromAwaitingParts,queueableThreadAfterUpdate,setWOIDToUpdate);

            processUpdatesOnVariousCondition(objNewWorkorder,objOldWorkorder,idEstimatesRecordTypeId,lstAdminOperation,setWoIdToUpdateWdAsBillable,queueableThreadAfterUpdate,mapWOIdtoCaseId);

            addWOForIPOrLocationChange(objNewWorkorder,objOldWorkorder,setWOwithIPChanges);

            addWOForAccountAndPartsConsumedBySAPUpdate(objNewWorkorder,objOldWorkorder,accountIdToAccountGroup,woIdToAccId,woIdToSoldAccId,setWOIDToUpdate,idToWORecForUpdate);

            addWOForVariousUpdates(objNewWorkorder,objOldWorkorder,idToWORecForUpdate);

            addWOForUpdatedOwnerIPOrProduct(objNewWorkorder,objOldWorkorder,woIdsWithNewIPOrProduct,lstWorkOrdersWithUpdatedOwners);


            isTPSPOwnerChanged=addWOForStatusOwnerOrAbandonedReasonUpdate(objNewWorkorder,objOldWorkorder,lstWorkOrdersAutoClose,setAbandonedWOId,setAbandonedWOOppId);

            //START CMCP-23
            if(objNewWorkorder.SVMXC__Company__c!=null && objNewWorkorder.SVMXC__Company__c !=objOldWorkorder.SVMXC__Company__c){
                lstWorkOrderWithUpdatedAccount.add(objNewWorkorder);
            }
            //END CMCP-23
            //Start - DCP-49744
            if(WorkOrders.SET_WORK_ORDER_COMPLETION_STATUS.contains(objNewWorkorder.SVMXC__Order_Status__c) && objNewWorkorder.SVMXC__Component__c != Null &&
            (objNewWorkorder.Integration_Status__c == WorkOrders.STRING_WORK_ORDER_INTEGRATION_STATUS || objNewWorkorder.Integration_Status__c == WorkOrders.STRING_WORK_ORDER_INTEGRATION_STATUS_NOT_REQUIRED) ){
                lstAdminOperation.add(new Admin_Operation__e(Name__c = 'MaterialConsumedWDManager', Related_Record__c = objNewWorkorder.id));
            }
            //End - DCP-49744
            //START - DCP-49679
            WorkOrders.updatedWOList.clear();
            UpdateElevationDescription_WOHelper.populateWOList(objNewWorkorder, objOldWorkorder);
            //END - DCP-49679
        
        }

        
        asyncProcessOnRelatedObjects(queueableThreadAfterUpdate,setWorkOrderIdsToAwaitingParts,setWorkOrderIdsFromAwaitingParts,setAbandonedWOId,setAbandonedWOOppId,mapWOIdtoCaseId,setWOwithIPChanges);
        asyncProcessToUpdateRecords(queueableThreadAfterUpdate, woIdToAccId, woIdToSoldAccId, setWOIDToUpdate, setWoIdToUpdateWdAsBillable, idToWORecForUpdate, 
                woIdsWithNewIPOrProduct, lstWorkOrdersWithUpdatedOwners, lstWorkOrdersAutoClose, lstAdminOperation);
        asyncUpdatesOnWO(queueableThreadAfterUpdate,isTPSPOwnerChanged,mapOld,lstWorkOrderWithUpdatedAccount);


        if(!queueableThreadAfterUpdate.lstQueueableJobs.isEmpty()) {
            ilib_QueueableManager.enqueueJob(queueableThreadAfterUpdate);
        }
        

        //DCP-45928
        if(!lstAdminOperation.isEmpty())
            EventBus.publish(lstAdminOperation);
        ilib_LogEvent.pop();
    }
     
    /**
    * @description : Initiate automatic process to create Opportunity and quote and form list of work order Ids if status changed to Awaiting Status 
    * @param objNewWorkorder 
    * @param objOldWorkorder 
    * @param setWorkOrderIdsToAwaitingParts 
    * @param setWorkOrderIdsFromAwaitingParts 
    * @param queueableThreadAfterUpdate 
    * @param setWOIDToUpdate 
    **/
    public static void processAwaitingStatusAndCreateOppQuote(SVMXC__Service_Order__c objNewWorkorder,SVMXC__Service_Order__c objOldWorkorder,Set<Id> setWorkOrderIdsToAwaitingParts,Set<Id> setWorkOrderIdsFromAwaitingParts,
    ilib_Queueablethread queueableThreadAfterUpdate,set<Id> setWOIDToUpdate)
    {
         //CMCP-16 Status To Awaiting Parts Status
         if(objNewWorkorder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_AWAITING_PARTS) {
            setWorkOrderIdsToAwaitingParts.add(objNewWorkorder.Id);
        }
        //CMCP-16 Status From Awaiting Parts Status
        if(objNewWorkorder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && objOldWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_AWAITING_PARTS && objNewWorkorder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_AWAITING_PARTS) {
            setWorkOrderIdsFromAwaitingParts.add(objNewWorkorder.Id);
        }

        //DCP-39763, 38809, 39386: Start - Initiate automatic process to create Opportunity and quote
        if(objNewWorkorder.Initiate_Quoting__c != objOldWorkorder.Initiate_Quoting__c && String.isBlank(objOldWorkorder.Initiate_Quoting__c)) {   
            OpportunityQuoteAutomationQueueable objQueueable = new OpportunityQuoteAutomationQueueable(objNewWorkorder.Id);
            queueableThreadAfterUpdate.logandQueue(objQueueable,'OpportunityQuoteAutomationQueueable',objQueueable.lstActionClasses[0]);
        }
        //DCP-39763, 38809, 39386: End - Initiate automatic process to create Opportunity and quote
        //DCP-39882 starts
        if(objNewWorkorder.DCIR_Status__c== WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED) {
            setWOIDToUpdate.add(objOldWorkorder.Id);
            CreateEventToViewDocsInMobile.createEventToViewWODocument(setWOIDToUpdate);
        }
        //DCP-39882 Ends
    }
    
    /**
    * @description :1.Create Billable Work detail for Estimate WO , 2.Add to queueable job for Parts Order creation on PO number being set., 3.Populate setWoIdToUpdateWdAsBillable to call updateIsBillaleOnWdByCS method., 4. Map WO for case update
    * @param objNewWorkorder 
    * @param objOldWorkorder 
    * @param idEstimatesRecordTypeId 
    * @param lstAdminOperation 
    * @param setWoIdToUpdateWdAsBillable 
    * @param queueableThreadAfterUpdate 
    * @param mapWOIdtoCaseId 
    **/
    public static void processUpdatesOnVariousCondition(SVMXC__Service_Order__c objNewWorkorder,SVMXC__Service_Order__c objOldWorkorder,Id idEstimatesRecordTypeId,
    List<Admin_Operation__e> lstAdminOperation,set<Id> setWoIdToUpdateWdAsBillable,ilib_Queueablethread queueableThreadAfterUpdate,Map<Id,Id> mapWOIdtoCaseId)
    {
            //DCP-45928
            if(!objNewWorkorder.Partner_Work_Order__c && objNewWorkorder.RecordTypeId == idEstimatesRecordTypeId && objOldWorkOrder.RecordTypeId != objNewWorkorder.RecordTypeId)
                lstAdminOperation.add(new Admin_Operation__e(Name__c = 'BillableCreateEstimateWD', Related_Record__c = objNewWorkorder.id));
            //DCP-38965 populate setWoIdToUpdateWdAsBillable to call updateIsBillaleOnWdByCS method.
             if(objNewWorkorder.SVMXC__Billing_Type__c!=null && objOldWorkOrder.SVMXC__Billing_Type__c != objNewWorkorder.SVMXC__Billing_Type__c && objNewWorkorder.SVMXC__Billing_Type__c== WorkOrders.STRING_LABEL_BILLABLE&& objNewWorkorder.Billing_Type_Set_Manually__c){
                setWoIdToUpdateWdAsBillable.add(objNewWorkorder.Id);
            }
            //DCP-45793: Start - Add to queueable job for Parts Order creation on PO number being set.
            if(String.isNotBlank(objNewWorkorder.PO_Number__c) && String.isBlank(objOldWorkOrder.PO_Number__c) && !WorkOrders.setWOIdForAutoPOCreation.contains(objNewWorkorder.id)){
                WorkOrders.setWOIdForAutoPOCreation.add(objNewWorkorder.id);
                queueableThreadAfterUpdate.logandQueue(new CreatePartsOrderFromWO(objNewWorkorder),'CreatePartsOrderFromWO','execute');
                ilib_LogEvent.message('@@45793 CreatePartsOrderFromWO called in after update for: '+objNewWorkorder.id);
            }
            //DCP-45793: End - Add to queueable job for Parts Order creation on PO number being set.
            //DCP-39744
            if(objNewWorkorder.SVMXC__Case__c!=objOldWorkOrder.SVMXC__Case__c)
                mapWOIdtoCaseId.put(objNewWorkorder.Id,objNewWorkorder.SVMXC__Case__c); 
            
    }
    /**
    * @description : fetch list of WO when Owner/Installed Product/ Product is updated
    * @param objNewWorkorder 
    * @param objOldWorkorder 
    * @param woIdsWithNewIPOrProduct 
    * @param lstWorkOrdersWithUpdatedOwners 
    **/
    public static void addWOForUpdatedOwnerIPOrProduct(SVMXC__Service_Order__c objNewWorkorder,SVMXC__Service_Order__c objOldWorkorder,Set<Id> woIdsWithNewIPOrProduct,List<Id> lstWorkOrdersWithUpdatedOwners)
    {
         //Work Order : Update Installed product and Product on Associated Case
        if((objNewWorkorder.SVMXC__Component__c != objOldWorkorder.SVMXC__Component__c || objNewWorkorder.SVMXC__Product__c != objOldWorkorder.SVMXC__Product__c) && objNewWorkorder.SVMXC__Case__c != null  ){
            woIdsWithNewIPOrProduct.add(objNewWorkorder.Id);
        }           

        //DCP-43634
        if(objNewWorkorder.OwnerId != objOldWorkOrder.OwnerId && string.valueOf(objNewWorkorder.OwnerId).startsWith(WorkOrders.STRING_005)){
            //INC0401495
            if(lstWorkOrdersWithUpdatedOwners.isEmpty()) {
                lstWorkOrdersWithUpdatedOwners.add(objNewWorkorder.id);
            }//INC0401495
        }
    }

    /**
    * @description :Formulate list of WO when Installed product or location is updated on WO
    * @param objNewWorkorder 
    * @param objOldWorkorder 
    * @param setWOwithIPChanges 
    **/
    public static void addWOForIPOrLocationChange(SVMXC__Service_Order__c objNewWorkorder,SVMXC__Service_Order__c objOldWorkorder,Set<Id> setWOwithIPChanges)
    {
        //DCP-40191
        if (objOldWorkOrder.SVMXC__Component__c != objNewWorkorder.SVMXC__Component__c || objOldWorkOrder.SVMXC__Site__c != objNewWorkorder.SVMXC__Site__c) {
            setWOwithIPChanges.add(objNewWorkorder.Id);
        }
        if (objOldWorkOrder.ownerId != objNewWorkorder.ownerId && objOldWorkOrder.SVMXC__Order_Type__c != null && objNewWorkorder.SVMXC__Order_Type__c != null && objOldWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WO_ORDER_TYPE_PM && objOldWorkOrder.SVMXC__Order_Type__c == objNewWorkorder.SVMXC__Order_Type__c && objOldWorkOrder.SVMXC__Order_Status__c == 'Initiated') {
                setWOwithIPChanges.add(objNewWorkorder.Id);
        }
    }

    
    /**
    * @description :List out WO when account is changed or parts consumed by SAP is true
    * @param objNewWorkorder 
    * @param objOldWorkorder 
    * @param accountIdToAccountGroup 
    * @param woIdToAccId 
    * @param woIdToSoldAccId 
    * @param setWOIDToUpdate 
    * @param idToWORecForUpdate 
    **/
    public static void addWOForAccountAndPartsConsumedBySAPUpdate(SVMXC__Service_Order__c objNewWorkorder,SVMXC__Service_Order__c objOldWorkorder,Map<Id,String> accountIdToAccountGroup,Map<Id,Id> woIdToAccId,
    Map<Id,Id> woIdToSoldAccId,set<Id> setWOIDToUpdate,Map<Id, SVMXC__Service_Order__c> idToWORecForUpdate)
    {
        //DCP-39750-Populate woIdToAccId,woIdToSoldAccId,setWOIDToUpdate to pass them as parameters to method updateSoldToOnWO
        if(objNewWorkorder.SVMXC__Company__c != null && objNewWorkorder.SVMXC__Company__c != objOldWorkOrder.SVMXC__Company__c  && !accountIdToAccountGroup.isEmpty() &&  accountIdToAccountGroup.containskey(objNewWorkorder.SVMXC__Company__c) && (accountIdToAccountGroup.get(objNewWorkorder.SVMXC__Company__c)== WorkOrders.STRING_ACCOUNT_ACCOUNTGROUP_SOLDTO||accountIdToAccountGroup.get(objNewWorkorder.SVMXC__Company__c)==WorkOrders.STRING_ACCOUNT_ACCOUNTGROUP_ULTIMATECONSIGNEE ) && !WorkOrders.stopRecurssiveUpdateSoldToOnWO){
            woIdToAccId.put(objNewWorkorder.id,objNewWorkorder.SVMXC__Company__c);
            woIdToSoldAccId.put(objNewWorkorder.id,null);
            setWOIDToUpdate.add(objNewWorkorder.id);

        }

        //DCP-37399 - Uncheck Parts Consumed By SAP Once Vanstock is completed
        if(objNewWorkorder.Parts_Consumed_By_SAP__c == true ){
            if(!idToWORecForUpdate.isEmpty() && idToWORecForUpdate.containsKey(objNewWorkorder.Id)){
                idToWORecForUpdate.get(objNewWorkorder.Id).Parts_Consumed_By_SAP__c = false;    

            }
            else{
                idToWORecForUpdate.put(objNewWorkorder.Id, new SVMXC__Service_Order__c(Id = objNewWorkorder.Id, Parts_Consumed_By_SAP__c = false));
            }               
        }
    }

    /**
    * @description : list out WO to uncheck service report generation/ Qualtrics Survey: iSeq Installs/ Uncheck Send To ERP
    * @param objNewWorkorder 
    * @param objOldWorkorder 
    * @param idToWORecForUpdate 
    **/
    public static void addWOForVariousUpdates(SVMXC__Service_Order__c objNewWorkorder,SVMXC__Service_Order__c objOldWorkorder,Map<Id, SVMXC__Service_Order__c> idToWORecForUpdate)
    {
         //DCP-42922
            //Service Report Generation 
            if(objNewWorkorder.Service_Report_Generation__c == true ){
                if(!idToWORecForUpdate.isEmpty() && idToWORecForUpdate.containsKey(objNewWorkorder.Id)){
                    idToWORecForUpdate.get(objNewWorkorder.Id).Service_Report_Generation__c = false;    

                }
                else{
                    idToWORecForUpdate.put(objNewWorkorder.Id, new SVMXC__Service_Order__c(Id = objNewWorkorder.Id, Service_Report_Generation__c = false));
                }               
            }
            //WO: Qualtrics Survey: iSeq Installs
            if(objNewWorkorder.SVMXC__Order_Status__c != objOldWorkorder.SVMXC__Order_Status__c  && objNewWorkorder.SVMXC__Order_Status__c == 'Closed'){
                if(objNewWorkorder.SVMXC__Order_Type__c == 'Remote Support'  && objNewWorkorder.Installed_Product_Group__c == 'iSeq System' && objNewWorkorder.Sent_to_Qualtrics__c == false && objNewWorkorder.SVMX_PS_Subject__c.contains('install')){// && SnapSalesIntegrationUserId != null && String.ValueOf(objNewWorkorder.createdById) == SnapSalesIntegrationUserId){
                    
                    if(!idToWORecForUpdate.isEmpty() && idToWORecForUpdate.containsKey(objNewWorkorder.Id)){
                        idToWORecForUpdate.get(objNewWorkorder.Id).Sent_to_Qualtrics__c = true; 

                    }
                    else{
                        idToWORecForUpdate.put(objNewWorkorder.Id, new SVMXC__Service_Order__c(Id = objNewWorkorder.Id, Sent_to_Qualtrics__c = true));
                    }               
                }
            }
            //Work Order : Uncheck Send To ERP
            if(objNewWorkorder.Send_to_ERP__c == true ){
                if(!idToWORecForUpdate.isEmpty() && idToWORecForUpdate.containsKey(objNewWorkorder.Id)){
                    idToWORecForUpdate.get(objNewWorkorder.Id).Send_to_ERP__c = false;  

                }
                else{
                    idToWORecForUpdate.put(objNewWorkorder.Id, new SVMXC__Service_Order__c(Id = objNewWorkorder.Id, Send_to_ERP__c = false));
                }               
            }
    }
    
    /**
    * @description : add WO's for Auto closure WO / when Owner is updated/ list out opportunity when abandoned reason is updated
    * @param objNewWorkorder 
    * @param objOldWorkorder 
    * @param lstWorkOrdersAutoClose 
    * @param setAbandonedWOId 
    * @param setAbandonedWOOppId 
    * @return boolean 
    **/
    public static boolean addWOForStatusOwnerOrAbandonedReasonUpdate(SVMXC__Service_Order__c objNewWorkorder,SVMXC__Service_Order__c objOldWorkorder,List<SVMXC__Service_Order__c> lstWorkOrdersAutoClose,
    Set<Id> setAbandonedWOId,Set<Id> setAbandonedWOOppId)
    {        
        boolean checkTPSPOwnerChanged=false;
         //PB - Work Order : Create Work Details & Auto Closure refactored
         if((objNewWorkorder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c || objNewWorkorder.Parts_Order_Status__c != objOldWorkOrder.Parts_Order_Status__c || objNewWorkorder.Total_Open_Work_Details__c != objOldWorkOrder.Total_Open_Work_Details__c || objNewWorkorder.Integration_Status__c != objOldWorkOrder.Integration_Status__c) && objNewWorkorder.SVMXC__Order_Status__c ==Label.WorkOrderStatusCompleted && objNewWorkorder.Parts_Order_Status__c !=Label.PartsOrderStatusInProgress){
            if(lstWorkOrdersAutoClose.isEmpty()) {
                lstWorkOrdersAutoClose.add(objNewWorkorder);
            } 
        }
    
        if(objNewWorkorder.OwnerId != objOldWorkorder.OwnerId && String.valueof(objNewWorkorder.OwnerId).left(3) == WorkOrders.STRING_005){
            checkTPSPOwnerChanged = true;
        }	
    
        //DCP-38815
        if(objNewWorkorder.Abandoned_Reason__c != objOldWorkorder.Abandoned_Reason__c && String.isNotBlank(objNewWorkorder.Abandoned_Reason__c) && (caseIdToCase.get(objNewWorkorder.SVMXC__Case__c) != null && caseIdToCase.get(objNewWorkorder.SVMXC__Case__c).RecordType != null && caseIdToCase.get(objNewWorkorder.SVMXC__Case__c).RecordType.Name == 'Business Issue')){
            setAbandonedWOId.add(objNewWorkorder.id);
            //DCP-38816
            if(!String.isblank(objNewWorkorder.opportunity__c)){
                setAbandonedWOOppId.add(objNewWorkorder.opportunity__c);
            }
        }
        return checkTPSPOwnerChanged;
    } 

    /**
    * @description : perform queueable call to update the records
    * @param queueableThreadAfterUpdate 
    * @param setWorkOrderIdsToAwaitingParts 
    * @param setWorkOrderIdsFromAwaitingParts 
    * @param setAbandonedWOId 
    * @param setAbandonedWOOppId 
    * @param mapWOIdtoCaseId 
    * @param setWOwithIPChanges 
    **/
    public static void asyncProcessOnRelatedObjects(ilib_Queueablethread queueableThreadAfterUpdate ,Set<Id> setWorkOrderIdsToAwaitingParts,Set<Id> setWorkOrderIdsFromAwaitingParts,
    Set<Id> setAbandonedWOId, Set<Id> setAbandonedWOOppId, Map<Id,Id> mapWOIdtoCaseId,Set<Id> setWOwithIPChanges)
    {
        
        //DCP-38815
        if(!setAbandonedWOId.isEmpty()){
            queueableThreadAfterUpdate.logandQueue(new AbandonedStatusQueueable_WOHelper(setAbandonedWOId), WorkOrders.WORKORDER_QUEUEABLE,'createAssociatedCodeOnAbandonedWO');
        }
        //DCP-38816
        if(!setAbandonedWOOppId.isEmpty()){
            queueableThreadAfterUpdate.logandQueue(new WorkOrderQueueableNonSharing('updateOpportunityAbandoned',setAbandonedWOOppId),WorkOrders.WORKORDER_QUEUEABLE_NON_SHARING,'updateOpportunityAbandoned');	
        }
        //DCP-39744
        if(!mapWOIdtoCaseId.isEmpty() || !setWOwithIPChanges.IsEmpty()) {
            if(!mapWOIdtoCaseId.isEmpty()){
                queueableThreadAfterUpdate.logandQueue(new FAIQueueable_WOHelper(mapWOIdtoCaseId, 'updateFAIrecordsOnWO'),WorkOrders.WORKORDER_QUEUEABLE,'updateFAIrecordsOnWO');
            }
                //DCP-40191
            if(!setWOwithIPChanges.IsEmpty()){
                 queueableThreadAfterUpdate.logandQueue(new UpdateWDQueueable_WOHelper(setWOwithIPChanges, 'updateIsBillabeOnWorkDetails'),WorkOrders.WORKORDER_QUEUEABLE,'updateIsBillabeOnWorkDetails');
                 // DCP-43163
                 queueableThreadAfterUpdate.logandQueue(new UpdatePOLQueueable_WOHelper(setWOwithIPChanges), WorkOrders.WORKORDER_QUEUEABLE,'updateIsBillabeOnPartsOrderLines');
             }
        } 
		
    }
    
    /**
    * @description :perform queueable call to update the records
    * @param queueableThreadAfterUpdate 
    * @param woIdToAccId 
    * @param woIdToSoldAccId 
    * @param setWOIDToUpdate 
    * @param setWoIdToUpdateWdAsBillable 
    * @param idToWORecForUpdate 
    * @param woIdsWithNewIPOrProduct 
    * @param lstWorkOrdersWithUpdatedOwners 
    * @param lstWorkOrdersAutoClose 
    **/
    public static void asyncProcessToUpdateRecords(ilib_Queueablethread queueableThreadAfterUpdate,Map<Id,Id> woIdToAccId,Map<Id,Id> woIdToSoldAccId,set<Id> setWOIDToUpdate,
            set<Id> setWoIdToUpdateWdAsBillable,Map<Id, SVMXC__Service_Order__c> idToWORecForUpdate,Set<Id> woIdsWithNewIPOrProduct,
            List<Id> lstWorkOrdersWithUpdatedOwners,List<SVMXC__Service_Order__c> lstWorkOrdersAutoClose, List<Admin_Operation__e> lstAdminOperation)
    {     
        //DCP-39750-call method updateSoldToOnWO from queuable interface.
        if(!woIdToAccId.isEmpty() && !woIdToSoldAccId.isEmpty() && !setWOIDToUpdate.isEmpty() && !WorkOrders.stopRecurssiveUpdateSoldToOnWO){
            //Incident INC0299361 fix
            queueableThreadAfterUpdate.logandQueue(new UpdateSoldToQueueable_WOHelper(woIdToAccId,woIdToSoldAccId,setWOIDToUpdate), WorkOrders.WORKORDER_QUEUEABLE, WorkOrders.METHOD_UPDATE_SOLD_TO_ON_WO);
        }

        //DCP-38965 call updateIsBillaleOnWdByCS method.
        if(!setWoIdToUpdateWdAsBillable.isEmpty()){
            //Incident INC0299361
            queueableThreadAfterUpdate.logandQueue(new UpdateWDQueueable_WOHelper(setWoIdToUpdateWdAsBillable, WorkOrders.STRING_UPDATE_IS_BILLING_ON_WD_BY_CS), WorkOrders.WORKORDER_QUEUEABLE, WorkOrders.STRING_UPDATE_IS_BILLING_ON_WD_BY_CS);
        }
   
        asyncUpdateFieldsOnCaseAndWO(queueableThreadAfterUpdate,idToWORecForUpdate,woIdsWithNewIPOrProduct);    
        
        //PB - Work Order : Create Work Details & Auto Closure refactored
        if(!lstWorkOrdersAutoClose.isEmpty()) {
            lstAdminOperation.add(new Admin_Operation__e(Name__c = 'AutoCloseWOHelper', Related_Record__c = lstWorkOrdersAutoClose[0].id));
        }
    }

    /**
    * @description :Update work order fields and case with installed product and Product fields
    * @author 
    * @param queueableThreadAfterUpdate 
    * @param idToWORecForUpdate 
    * @param woIdsWithNewIPOrProduct 
    **/
    public static void asyncUpdateFieldsOnCaseAndWO(ilib_Queueablethread queueableThreadAfterUpdate,Map<Id, SVMXC__Service_Order__c> idToWORecForUpdate,Set<Id> woIdsWithNewIPOrProduct)
    {
        //DCP-42922
        if(!idToWORecForUpdate.IsEmpty()){
            queueableThreadAfterUpdate.logandQueue(new UpdateWOQueueable_WOHelper(idToWORecForUpdate.values()), WorkOrders.WORKORDER_QUEUEABLE,'updateWOFields');
        }
        
        //DCP-42922
        if(!woIdsWithNewIPOrProduct.IsEmpty()) {
            queueableThreadAfterUpdate.logandQueue(new UpdateCaseQueueable_WOHelper(woIdsWithNewIPOrProduct), WorkOrders.WORKORDER_QUEUEABLE,'updateIPAndProductOnCase');
        }   
        
    }
    
    /**
    * @description :perform queueable call to update the records
    * @param queueableThreadAfterUpdate 
    * @param isTPSPOwnerChanged 
    * @param mapOld 
    * @param lstWorkOrderWithUpdatedAccount 
    **/
    public static void asyncUpdatesOnWO(ilib_Queueablethread queueableThreadAfterUpdate,Boolean isTPSPOwnerChanged,Map<Id, SObject> mapOld,List<SVMXC__Service_Order__c> lstWorkOrderWithUpdatedAccount)
    {
        
        //DCP-45663
        if(isTPSPOwnerChanged){
            queueableThreadAfterUpdate.logandQueue(new TPSPSharingQueueable_WOHelper(mapOld), WorkOrders.WORKORDER_QUEUEABLE, 'shareRelatedRecordsWithWOOwner');
        }

        //DCP-53745
        if(!WorkOrders.mapIPIdtoIPObj.isempty()){
            queueableThreadAfterUpdate.logandQueue(new UpdateIPQueueable_WOHelper(WorkOrders.mapIPIdtoIPObj), WorkOrders.WORKORDER_QUEUEABLE, 'upsertInstalledProductsOnWO');
        }
        //START CMCP-23
        if(!lstWorkOrderWithUpdatedAccount.isEmpty() && !WorkOrders.stopRecursiveUpdatePartnerWOFlagForVADAccount){
            WorkOrders.stopRecursiveUpdatePartnerWOFlagForVADAccount= true;
            queueableThreadAfterUpdate.logandQueue(new PartnerFlagVDQueueable_WOHelper(lstWorkOrderWithUpdatedAccount),WorkOrders.WORKORDER_QUEUEABLE,WorkOrders.METHOD_UPDATE_PARTNER_WO_FLAG_FOR_VAD_ACCOUNT);
        }
        //END CMCP-23
        
               
        //Start DCP-46273
        if(!WorkOrders.setChildWorkOrderIds.isEmpty()){
            queueableThreadAfterUpdate.logandQueue(new RecalculateOperabilityQueueable_WOHelper(WorkOrders.setChildWorkOrderIds),WorkOrders.WORKORDER_QUEUEABLE, 'reCalculateConfirmOperabilityWO');
        }//End DCP-46273
        //Start DCP-49679
        if(!WorkOrders.updatedWOList.isEmpty()){
            queueableThreadAfterUpdate.logandQueue(new UpdateElevationDescription_WOHelper(WorkOrders.updatedWOList), WorkOrders.WORKORDER_QUEUEABLE, 'updateElevationsDescription');
        }//End DCP-49679
    }
}
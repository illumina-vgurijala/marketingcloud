/***************************************************************************************************************************************
* NAME         : WorkOrderDataReceiver
* DESCRIPTION  : Work Order Synchronization to DCP(ServiceMax)
* @AUTHOR      : 
* @DATE        : 14-Sep-2018  
* 90% code coverage test classes : TestCycleCounts,TestWorkOrderBulkUpdateController,TestWorkOrderDataReceiver,TestWorkOrderDataSender,TestZDSTWorkOrderDataReceiver
* 75% code coverage test classes : TestCycleCounts,TestWorkOrderBulkUpdateController,TestWorkOrderDataReceiver,TestWorkOrderDataSender,TestZDSTWorkOrderDataReceiver
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Adyasha                  25-Jun-2021         DCP-45746 : Creation of CS Review Activity if Invoicing Fails at SAP
* Biswajeet                16-Sept-2022        CMSI-209 Instrumentation of class
* Pooja                    14-Dec-2022         modified upsertIncomingValues, Call UtilRest.cls for interface log update 
****************************************************************************************************************************************/
@RestResource(urlMapping = '/WorkOrderSyncInterface/*')
global with sharing class WorkOrderDataReceiver extends ilib_RestReceiver {
    private static final String LOG_TITLE = 'WorkOrderDataReceiver';

    private static List<WorkOrderDataReceiverWrapper.WorkOrders> wrapWorkOrders;
    //DCP-45746
    private static Map<String, Schema.RecordTypeInfo> nameToRecordType;
    private static final String INTEGRATION_STATUS_C = 'C';
    //end of DCP-45746

    /*******************************************************************************************************
    * @descriptionupsert Incoming Values on Work Order
    * @return void
    */
    @HttpPost	
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        WorkOrderDataReceiver instantiated = new WorkOrderDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SERVICE);           //CMSI-209
        String strRestError = null;
        Id primaryRecordId;
        String erpCustomerId;

        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
        ilib_LogEvent.info('JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            //if there is no body found, throw an error.
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, wrapWorkOrders);

            primaryRecordId = upsertIncomingValuesImpl();
            ilib_LogEvent.info('primaryRecordId :' + primaryRecordId);
            erpCustomerId = getRelatedErpCustomerId('SVMXC__Service_Order__c', 'SVMXC__Company__r', primaryRecordId);
            ilib_LogEvent.info('erpCustomerId :' + erpCustomerId);

        }
        catch (Exception e)
        {
            strRestError = UtilsRest.handleRetryCustomRestError(e);//DCP-51717
            ilib_LogEvent.info('strRestError :' + strRestError);
        }

        Boolean isSuccess = String.isBlank(strRestError);
        ilib_LogEvent.info('isSuccess :' + isSuccess);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }

        String logInterfaceId = ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

        //DCP-51717 & DCP-56196
        UtilsRest.updateHttpResultCodeForRetry(logInterfaceId,LOG_TITLE);

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);            
            ilib_LogEvent.push(LOG_TITLE+'.upsertIncomingValues()');
            ilib_LogEvent.error('Error Description '+strRestError +'----');
            ilib_LogEvent.pop();
        }
   }

    private static void deserializeInputs(String jsonInput)
    {
        ilib_LogEvent.push(LOG_TITLE+'.deserializeInputs()');   //CMSI-209
        wrapWorkOrders = (List < WorkOrderDataReceiverWrapper.WorkOrders > ) System.JSON.deserialize(jsonInput, List<WorkOrderDataReceiverWrapper.WorkOrders>.class);
        ilib_LogEvent.pop();   //CMSI-209
    }

    private static Id upsertIncomingValuesImpl()
    {
        ilib_LogEvent.push(LOG_TITLE + '.upsertIncomingValuesImpl()');
        SVMXC__Service_Order__c oneWorkOrder;

        /* REGISTER HELPERS : GENERIC STATEMENT */
        // Register custom helpers: This is a mandatory step.
        ilib_UpsertHelpers.WorkOrdersUnitofWorkHelper workOrderWork = new ilib_UpsertHelpers.WorkOrdersUnitofWorkHelper();
        ilib_UpsertHelpers.WorkDetailsUnitOfWorkHelper workDetailWork = new ilib_UpsertHelpers.WorkDetailsUnitOfWorkHelper();
        /*  / REGISTER HELPERS : GENERIC STATEMENT */

        /* VARIABLES */
        //Map workOrderExtId to workOrder Object
        Map < String, SVMXC__Service_Order__c > idToWorkOrder = new Map < String, SVMXC__Service_Order__c > (); //   SVMX_PS_External_ID__c

        //Map workDetailExtId to workDetail Object
        Map < String, SVMXC__Service_Order_Line__c > idToWorkDetail = new Map < String, SVMXC__Service_Order_Line__c > ();

        //Map WorkOrderId to List of WorkDetails Id
        Map < String, List < String > > workOrderIdToWorkDetailId = new Map < String, List < String > > ();
        
        //Error Message
        String errorMessage = '';
        //Integration Order Status change check
        Map < String, String > idToWorkOrderStatus = new Map < String, String > ();

        //DCP-45746
        Set<Id> setWorkOrderIdsForCSReview = new Set<Id>();
        List<SVMXC__Service_Order_Line__c> lstQSReviewWDToInsert = new List<SVMXC__Service_Order_Line__c>();
        //end of DCP-45746

        /* UNIT OF WORK : GENERIC STATEMENT */
        //unit of work: This is a mandatory step.
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List < Schema.SObjectType > {
                SVMXC__Service_Order__c.SObjectType,
                SVMXC__Service_Order_Line__c.SObjectType
            });
        /* / UNIT OF WORK : GENERIC STATEMENT */

        /* REGISTER OBJECTS : GENERIC STATEMENT */
        //register your objects: This is a mandatory step.
        uow.registerWork(workOrderWork);
        uow.registerWork(workDetailWork);
        /* / REGISTER OBJECTS : GENERIC STATEMENT */

        if (wrapWorkOrders != null)
        {
            ilib_LogEvent.info('wrapWorkOrders :'+wrapWorkOrders);   //CMSI-209
            //iterate over the work order record (header)
            for (WorkOrderDataReceiverWrapper.WorkOrders wrapperWorkOrders: wrapWorkOrders)
            {
                //get the object details from the method created in WorkOrderDataReceiverWrapper.
                //It has all the fields information which will be updated.
                SVMXC__Service_Order__c workOrderObj = wrapperWorkOrders.getSObject();
                oneWorkOrder = workOrderObj;
                
                
                workOrderIdToWorkDetailId.put(workOrderObj.Id, new List <String>());

                Map < Id, Map < String, String >> errorDetailsforWorkDetailMap = new Map < Id, Map < String, String >> ();
                Map<Id, String> workOrderIdToStatus = new Map<Id, String>();
                
                
                
                if (wrapperWorkOrders.ErrorEntity != null && !wrapperWorkOrders.ErrorEntity.isEmpty())
                {
                    for (WorkOrderDataReceiverWrapper.ErrorEntity err: wrapperWorkOrders.ErrorEntity)
                    {
                        if (string.isNotblank(err.Id))
                        {
                            if (err.Id == workOrderObj.Id)
                            {
                                if (string.isNotBlank(err.status)){
                                    ilib_LogEvent.message('ErrStatus '+err.status);
                                    workOrderObj.Integration_Status__c  = err.status == 'E' ? 'Fail' : err.status;
                                    //DCP-45746
                                    prepareWOSetEligibleForCSReview(setWorkOrderIdsForCSReview, err.status, workOrderObj);
                                    //End of DCP-45746
                                }
                                
                                if (string.isNotBlank(err.Details)) 
                                workOrderObj.Integration_Message_Details__c = err.Details;
                                errorMessage = err.Details + ' \r\n';
                            } else {
                            
                                Map < String, String > eachMap = new Map < string, string > ();
                                if (string.isNotBlank(err.status)) 
                                eachMap.put('status', err.status);
                                workOrderObj.Integration_Status__c  = err.status == 'E' ? 'Fail' : err.status;
                                
                                if (string.isNotBlank(err.Details)) 
                                eachMap.put('Details', err.Details);
                                errorDetailsforWorkDetailMap.put(err.id, eachMap);
                                
                            }
                        }
                        else{
                            if(workOrderIdToStatus.get(workOrderObj.Id)!=null){
                                workOrderIdToStatus.put(workOrderObj.Id,workOrderIdToStatus.get(workOrderObj.Id)+ ' \r\n'+ err.Details);    
                            }
                            else{
                                workOrderIdToStatus.put(workOrderObj.Id, err.Details);
                            }
                            if(errorDetailsforWorkDetailMap.isEmpty() && !workOrderIdToStatus.isEmpty()){
                                workOrderObj.Integration_Status__c  =  'Fail';
                                workOrderObj.Integration_Message_Details__c = workOrderIdToStatus.get(workOrderObj.id);
                            }                            
                        }
                    }

                } else {
                    workOrderObj.Integration_Status__c  = 'Success';
                    workOrderObj.Integration_Message_Details__c = 'Success';
                }

                // Update Previous External ID if it differs CMCM-7849
                if (String.isNotBlank(wrapperWorkOrders.PrevErpServiceOrder) && wrapperWorkOrders.PrevErpServiceOrder != null && wrapperWorkOrders.PrevErpServiceOrder != workOrderObj.SVMX_PS_External_ID__C) {
                    workOrderObj.Previous_External_ID__c = wrapperWorkOrders.PrevErpServiceOrder;
                }
                //CMCM-7849 end
                //populate the map with work order id as key and work order object as values.
                idToWorkOrder.put(workOrderObj.Id, workOrderObj);
                /* ITERATE OVER CHILD RECORDS */
                for (WorkOrderDataReceiverWrapper.WorkDetails wrapperWorkDetails: wrapperWorkOrders.WorkDetails)
                {
                    //instantiate a new work detail object.
                    SVMXC__Service_Order_Line__c workDetailObj = new SVMXC__Service_Order_Line__c();

                    //get the object details from the method created in WorkOrderDataReceiverWrapper.
                    //It has all the fields information which will be updated.
                    workDetailObj = wrapperWorkDetails.getSObject();

                    if (!errorDetailsforWorkDetailMap.isEmpty() && errorDetailsforWorkDetailMap.containskey(wrapperWorkDetails.ConfirmationId))
                    {
                        workDetailObj.Integration_Status__c  = errorDetailsforWorkDetailMap.get(wrapperWorkDetails.ConfirmationId).get('status') == 'E' ? 'Fail' : errorDetailsforWorkDetailMap.get(wrapperWorkDetails.ConfirmationId).get('status');
                        workDetailObj.Integration_Message_Details__c = errorDetailsforWorkDetailMap.get(wrapperWorkDetails.ConfirmationId).get('Details');
                        errorMessage += workDetailObj.Integration_Message_Details__c + ' \r\n';
                        workDetailObj.Consumption_Confirmed__c = false; //CMCM-83
                    } else {
                        workDetailObj.Integration_Status__c  = 'Success';
                        workDetailObj.Integration_Message_Details__c = 'Success';
                    }

                    //populate the map with work detail id as key and work detail object as values.
                    idToWorkDetail.put(workDetailObj.Id, workDetailObj);

                    //add all the child objects.
                    workOrderIdToWorkDetailId.get(workOrderObj.Id).add(workDetailObj.Id);
                }
                ilib_LogEvent.info('IdToWorkDetail :'+IdToWorkDetail.keyset());       //CMSI-209

                /* / ITERATE OVER CHILD RECORDS */
                if(String.isNotBlank(errorMessage))
                workOrderObj.Integration_Message_Details__c = errorMessage;
                //DCP-25284 putting values of Integration_Message_Details__c(long text area)
                //inside  Integration_Message_Details_Text__c(text) field to enable feed tracking
                if(workOrderObj.Integration_Message_Details__c.length()>255)
                    workOrderObj.Integration_Message_Details_text__c = (workOrderObj.Integration_Message_Details__c).substring(0,255);
                else
                    workOrderObj.Integration_Message_Details_text__c = workOrderObj.Integration_Message_Details__c;
            }
        }

        //loop to populate Id column of work order objects based on workOrderIdSet
        for (SVMXC__Service_Order__c workOrderObj: new WorkOrdersSelector().selectWorkOrderLstFromStringIds(idToWorkOrder.keyset()))  {
            idToWorkOrder.get(workOrderObj.Id).Id = workOrderObj.id;
             //Integration Order Status change check
            idToWorkOrderStatus.put(workOrderObj.Id,workOrderObj.SVMXC__Order_Status__c);
            
            ilib_LogEvent.message('@@@@ workOrderObj.SVMXC__Order_Status__c: '+workOrderObj.SVMXC__Order_Status__c);
            ilib_LogEvent.message('@@@@ workOrderObj.SVMXC__Billing_Type__c: '+workOrderObj.SVMXC__Billing_Type__c);
            ilib_LogEvent.message('setWorkOrdersForCSReview '+setWorkOrderIdsForCSReview);
            
            //DCP-45746
            if(workOrderObj.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
                    && workOrderObj.SVMXC__Billing_Type__c ==Label.WorkOrderBillingTypeBillable 
                    && setWorkOrderIdsForCSReview.contains(workOrderObj.Id) 
                    && isWorkOrderEligibleForCSReview(workOrderObj,INTEGRATION_STATUS_C)){

                    lstQSReviewWDToInsert.add(new SVMXC__Service_Order_Line__c(SVMXC__Line_Type__c = WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR, 
                                                                              SVMXC__Activity_Type__c = WorkOrders.STRING_WD_ACTIVITY_CUSTOMER_SERVICE_REVIEW, 
                                                                              SVMXC__Line_Status__c = WorkOrders.STRING_WORK_ORDER_STATUS_OPEN,
                                                                              SVMXC__Is_Billable__c = false,
                                                                              RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WorkOrders.STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId(), 
                                                                              SVMXC__Service_Order__c =workOrderObj.id));
            }
            //end of DCP-45746
        }

        //loop to populate Id of work detail object based on workDetailIdSet
        for (SVMXC__Service_Order_Line__c li: new WorkDetailsSelector().selectWorkDetailsByWorkDetailStringId(idToWorkDetail.keyset())) {
            idToWorkDetail.get(li.Id).Id = li.id;
            
            //DCP-44981 - If External id is different from what is already saved, part consumption reversal was successful in SAP
            if(li.SVMXC__Line_Status__c == 'Reversal Requested'){
            idToWorkDetail.get(li.Id).Part_Consumption_Reversal_External_ID__c = idToWorkDetail.get(li.Id).SVMX_PS_External_ID__c != li.SVMX_PS_External_ID__c ? idToWorkDetail.get(li.Id).SVMX_PS_External_ID__c : '';
            idToWorkDetail.get(li.Id).SVMX_PS_External_ID__c = li.SVMX_PS_External_ID__c;
            
            if(String.isNotBlank(idToWorkDetail.get(li.Id).Part_Consumption_Reversal_External_ID__c) && idToWorkDetail.get(li.Id).Part_Consumption_Reversal_External_ID__c != li.SVMX_PS_External_ID__c && idToWorkDetail.get(li.Id).Integration_Status__c == 'Success'){
            idToWorkDetail.get(li.Id).Part_Consumption_Reversal_Status__c = 'SAP Status: Reversal completed in SAP successfully.' +' \r\n' + 'DCP Status: Reversal initiated SFDC successfully.';    
            }     
            }
            
        }

        

        //Iterate over Parent Object.
        for (String workOrderId: idToWorkOrder.keyset())
        {
            //if the parent object does not exists in SVMX already.
            if (String.IsBlank(idToWorkOrder.get(workOrderId).Id))
            {
                //register parent object.
                uow.registerNew(idToWorkOrder.get(workOrderId));

                //iterate over all the child objects
                for (String workDetailId: workOrderIdToWorkDetailId.get(workOrderId))
                {
                    //get the external id from the child array records.
                    String extId = workDetailId;

                    //register the child object relationship with the parent based on the external id.
                    uow.registerRelationship(idToWorkDetail.get(extId), SVMXC__Service_Order_Line__c.SVMXC__Service_Order__c, idToWorkOrder.get(workOrderId));

                    //register the child record to insert.
                    uow.registerNew(idToWorkDetail.get(extId));
                }

            } else {
                
                //Integration Order Status change check
                if(String.isNotBlank(idToWorkOrderStatus.get(workOrderId)) && (idToWorkOrderStatus.get(workOrderId) == 'Completed' || idToWorkOrderStatus.get(workOrderId) == 'Closed') && idToWorkOrder.get(workOrderId).Integration_Status__c == 'Fail')
                idToWorkOrder.get(workOrderId).SVMXC__Order_Status__c  = 'Assigned'; 

                //register parent object for upsert.
                workOrderWork.registerUpsert(idToWorkOrder.get(workOrderId));

                //iterate over all the child objects
                for (String workDetailId: workOrderIdToWorkDetailId.get(workOrderId))
                {
                    //external Id to make upserts.
                    String extId = workDetailId;

                    //upsert only if there are work details record available.
                    if (!String.IsBlank(extId))
                    {
                        //Get the record id based on the external id.
                        if (String.IsNotBlank(idToWorkDetail.get(extId).Id)) {
                            //register upsert on child object.
                            workDetailWork.registerUpsert(idToWorkDetail.get(extId));

                        } else {
                            uow.registerRelationship(idToWorkDetail.get(extId), SVMXC__Service_Order_Line__c.SVMXC__Service_Order__c, idToWorkOrder.get(workOrderId));
                            uow.registerNew(idToWorkDetail.get(extId));
                        }
                    }
                }
            }
        }

        // any business logic for incoming values goes in here
        businessRules(uow);

        uow.commitWork();

       
         //DCP-45746
         if(!lstQSReviewWDToInsert.isEmpty()){
             insert lstQSReviewWDToInsert;
             ilib_LogEvent.info('@@@@ lstQSReviewWDToInsert: '+UtilsCollection.getSetOfIds(lstQSReviewWDToInsert));
         }
         //end of DCP-45746
        ilib_LogEvent.pop();
        return (oneWorkOrder != null ? oneWorkOrder.Id : null);
    }
    
    /*******************************************************************************************************
    * @description method to run businessRules
    * @param ilib_SObjectUnitOfWork uow
    * @return void
    */
    public static void businessRules(ilib_SObjectUnitOfWork uow) {
    }

    /*
    * Added as part of DCP-45746
    */
    public static Boolean isWorkOrderEligibleForCSReview(SVMXC__Service_Order__c objWorkOrder,String strIndicator)
    {
        
        Boolean boolCriteriaSatisfied = false;
        ilib_LogEvent.message('@@@@ strIndicator: '+strIndicator);

        boolCriteriaSatisfied = (checkOrderTypeRecordTypeCombination(objWorkOrder,Label.WorkOrderRecordTypeServiceSupport,Label.WorkOrderTypeProfessionalServices) 
                                || checkOrderTypeRecordTypeCombination(objWorkOrder,Label.WorkOrderRecordTypeFieldService,Label.WorkOrderTypeServiceActivities)
                                || checkOrderTypeRecordTypeCombination(objWorkOrder,Label.WorkOrderRecordTypeFieldService,Label.WorkOrderTypePreventativeMaintenance))
                                && objWorkOrder.Total_CS_Review_Activity_Open__c == 0;

        ilib_LogEvent.message('@@@@ boolCriteriaSatisfied after first check: '+boolCriteriaSatisfied);

        if(String.isNotBlank(strIndicator)){
            boolCriteriaSatisfied = boolCriteriaSatisfied && strIndicator == 'C';
        }

        ilib_LogEvent.message('@@@@ boolCriteriaSatisfied final: '+boolCriteriaSatisfied);
    
        return boolCriteriaSatisfied;
    }
    /*
    * Added as part of DCP-45746
    */
    public static Boolean checkOrderTypeRecordTypeCombination(SVMXC__Service_Order__c objWorkOrder, String recordTypeName, String strOrderType)
    {
      

        Id recordTypeId = getNameToRecordType().get(recordTypeName).getRecordTypeId();
        if(objWorkOrder.RecordTypeId == recordTypeId && objWorkOrder.SVMXC__Order_Type__c == strOrderType){
            ilib_LogEvent.message('checkOrderTypeRecordTypeCombination - returning true');
            ilib_LogEvent.pop();
            return true;
        }
        ilib_LogEvent.message('checkOrderTypeRecordTypeCombination - returning false');
       
        return false;
    }
    /*
    * Added as part of DCP-45746
    */
    public static Map<String, Schema.RecordTypeInfo> getNameToRecordType()
    {
        ilib_LogEvent.push(LOG_TITLE+'.getNameToRecordType()');   //CMSI-209
        if (nameToRecordType == null){
            nameToRecordType = SVMXC__Service_Order__c.sObjectType.getDescribe().getRecordTypeInfosByName();
            ilib_LogEvent.info('nameToRecordType :'+nameToRecordType.keySet());   //CMSI-209
        }
        ilib_LogEvent.pop();   //CMSI-209
        return nameToRecordType;
    }
     /*
    * Added as part of DCP-45746
    */
    public static void prepareWOSetEligibleForCSReview(Set<Id> setWorkOrderIds, String strStatus, SVMXC__Service_Order__c objWorkOrder)
    {
        if(strStatus == INTEGRATION_STATUS_C){
            objWorkOrder.Integration_Status__c  = WorkOrders.STRING_WORK_ORDER_INTEGRATION_STATUS;
            setWorkOrderIds.add(objWorkOrder.Id);
        }
    }

}

/*
SAMPLE INPUT RECIEVED

[
   {
      "WorkOrderNumber": "a2B2F000000zOYq",
      "ErpServiceOrder": "786876",
      "WorkDetails": [
         {
            "ConfirmationId": "a2A2F000000LXEl",
            "ConfirmationERPId": "ADF546546"
         }
      ],
      "ErrorEntity": [
         {
            "Id": "a2A2F000000LXEl",
            "Status": "E",
            "Details": "Work Order Number WO-00000079 is assigned to ERP Service Order Number 000004000234."
         },
         {
            "Id": "a2B2F000000zOYq",
            "Status": "S",
            "Details": "No Error Received."
         }
      ]
   }
]

*/
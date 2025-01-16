/***************************************************************************************************************************************
* NAME         : WorkOrderDataSender
* DESCRIPTION  : [DCP-8444] Work Order Synchronization from ServiceMax to SAP (NEW).
*                    
* @AUTHOR      : 
* @DATE        : 27-July-2018  
* 90% code coverage test classes : TestBatchAttemptAutoCloseCase,TestWorkOrderBulkUpdateController,TestWorkOrderDataSender,TestWorkOrderWrapper
* 75% code coverage test classes : TestBatchAttemptAutoCloseCase,TestWorkOrderBulkUpdateController,TestWorkOrderDataSender,TestWorkOrderWrapper
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Deepika                  17-May-2021          DCP-38815:Added Abdonded Reason to JSON Mapping 
* Akshay Mohan             01-June-2021         DCP-46834:Billable changes, sending lines to SAP
* Adyasha                  23-Aug-2021          RITM0523587:Send Estimated Quantity for Travel Line to SAP
* Biswajeet                15-Sept-2022         [CMSI-209] Instrumentation of class
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class WorkOrderDataSender extends ilib_RestSender {

    public static string triggeredManuallyOrFromBatch = 'Manually';//DCP-37399
    private static final String LOG_TITLE='WorkOrderDataSender';
    private static Id idEstimateRecordType;
    private static Set<String> setTravelCodes;

    /*
    *  Class to send data to external system
    */	
    private class CalloutData extends ilib_CalloutData
    {
        SVMXC__Service_Order__c workOrdRecs;

		/*******************************************************************************************************
        * @description Constructor
        * @param workOrdRecs SVMXC__Service_Order__c
        */
        public CalloutData(SVMXC__Service_Order__c workOrdRecs)
        {
            this.workOrdRecs = workOrdRecs;
        }
    }

	/*******************************************************************************************************
    * @description Variable for Class CalloutData
    */	
    private CalloutData data {
        get { return (CalloutData) idata; }
    }

    /*this class uses selectors to populate CalloutData*/
    protected override ilib_CalloutData retrieveCalloutData()
    {
        ilib_LogEvent.push(LOG_TITLE+'.retrieveCalloutData()');  //CMSI-209
        SVMXC__Service_Order__c workOrdRecs = new WorkOrdersSelector().selectWorkOrderId(new Set <Id> { recordId })[0];
        CalloutData data = new CalloutData(workOrdRecs);
        ilib_LogEvent.info('data : ' + data);
        ilib_LogEvent.pop();     //CMSI-209
        return data;
    }

    /**
     *  @author Vaibhav Parashar
     *  @description   this method is the last line of defense to make sure we don't send garbage to
     *      the target system.  Some validation will occur before the interface is called
     *      but we may allow retriggers by admins so we need these sanity checks here
     *      it builds a list of errors which are thrown to the caller
     */
    protected override void validateFields() { }

    /**
     *  @author Vaibhav Parashar
     *  @DESCRIPTION - [DCP-8444] Work Order Synchronization from ServiceMax to SAP (NEW).
     *              - This Method will return String body in JSON format which will be used in HTTP request method.
     **/
    protected override String createJSON()
    {
        ilib_LogEvent.push(LOG_TITLE + '.createJSON()');
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SERVICE);      //CMSI-209
        WorkOrderWrapper workOrWrapper = new WorkOrderWrapper();
		 Set<Id> opportunityIdSet = new Set<Id>();
        Map<Id, String> opportunityIdToQuoteNumber = new map<Id, String>();
		Set < Id > ownerIdSet = new Set < Id > ();
		Map < Id, User > userIdToUser; 

        //DCP-46059
        Map<String, List<SVMXC__Service_Order__c>> erpOrderLineNumberToWorkOrderMap = new map<String, List<SVMXC__Service_Order__c>>();
        Set < String > setERPOrderLineNumber = new Set < String > ();
        Map<String, String> erpOrderLineNumberToQualifyForReleaseBilling = new map<String, String>();
        Set < String > setERPOrderNumber = new Set < String > ();

        //holds the final JSON string.
        //DCP-38815 - added Abandoned_Reason__c to the below query
         Map<Id, SVMXC__Service_Order__c> idToWorkOrder = new Map < Id, SVMXC__Service_Order__c > ([Select Id, Name, SVMXC__Site__c,SVMXC__Site__r.SVMX_PS_External_ID__c, SVMXC__Company__c,SVMXC__Company__r.ERP_Customer_Id__c,
            RecordType.Name, Owner.Name,SVMXC__Customer_Down__c,Final_Service_Date__c, Final_Service_Date_Time__c, //CMCM-13
            SVMXC__Order_Type__c, SVMX_PS_External_ID__c, Original_Owner__c,Abandoned_Reason__c,
            SVMXC__Case__c, SVMXC__Scheduled_Date_Time__c,SVMXC__Service_Contract__r.ERP_Contract_Line_Number__c,SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c, SVMXC__Closed_On__c,SVMXC__Service_Contract__r.SVMX_PS_External_ID__c,
            SVMX_PS_Subject__c, SVMXC__Priority__c,SVMXC__Service_Duration__c, Material_Number__c,ERP_Order_Number__c, ERP_Order_Line_Number__c,ERP_Quote_No__c,SVMXC__Case__r.SVMX_PS_External_ID__c,SVMXC__Case__r.CaseNumber,
            Installed_Product_Serial_Number__c, SVMXC__Order_Status__c, PO_Number__c, SVMXC__Component__r.Operation_Status__c,Opportunity__c,
            Cost_Center__c, SVMXC__Service_Contract__c, SVMXC__Billing_Type__c, SVMXC__Component__r.ERP_Equipment_ID__c,/* DCP-46059 */ Acceptance_Status__c,LOA_Signed_and_Attached__c,Acceptance_Forecast_in_Current_Quarter__c,
            (Select Id,Service_Contract__c,Service_Contract__r.ERP_Header_Contract_Number__c,Service_Contract__r.ERP_Contract_Line_Number__c from Applied_Contracts__r Limit 1),
            (Select Id, Name,LastModifiedById,SVMXC__Line_Status__c,SVMXC__Product__r.Material_Number__c,SVMXC__Group_Member__c,SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.Id,SVMX_PS_VS_Consumed_Product_Stock__c,SVMXC__Product__r.ProductCode
            ,SVMX_PS_VS_Consumed_Product_Stock__r.Product_Code__c,SVMX_PS_VS_Consumed_Stocked_Serial__c,SVMX_PS_VS_Consumed_Stocked_Serial__r.Name,SVMXC__Consumed_From_Location__c
            ,SVMXC__Consumed_From_Location__r.SVMX_PS_External_ID__c,Duration_in_hours__c,SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c,Travel_Confirmation_ERP_ID__c,Indirect_Confirmation_ERP_ID__c,Labor_Hours__c,Travel_Time_in_Hours__c,Indirect_in_hours__c
            ,SVMXC__Activity_Type__c,SVMXC__Actual_Quantity2__c,Non_Billable_Reason__c, SVMX_PS_External_ID__c,SVMXC__Start_Date_and_Time__c,SVMXC__End_Date_and_Time__c,Consumption_Confirmed__c/*added for dcp-37399*/
            ,SVMXC__Is_Billable__c, SVMXC__Line_Type__c, Batch_Number__c,SVMXC__Service_Order__c, ERP_Header_Contract_Number__c, ERP_Contract_Line_Number__c,SVMXC__From_Location__r.SVMX_PS_External_ID__c, SVMXC__From_Location__c 
            //DCP-46834: Start- Get line record type Id,product code 
            ,RecordTypeId,Product_Code__c,SVMXC__Estimated_Quantity2__c //RITM0523587
            //DCP-46834: End- Get line record type Id 
            From SVMXC__Service_Order_Line__r where SVMXC__Activity_Type__c != 'Customer Service Review' AND SVMXC__Line_Type__c != null AND Approval_Status__c !=: WorkDetails.WD_APPROVALSTATUS_PENDINGAPPROVAL)
            From SVMXC__Service_Order__c
            Where Id =: data.workOrdRecs.Id
        ]);
        //holds Id and workOrderWrapper data type records.
        Map <Id, WorkOrderWrapper.ServiceOrder> workOrderidToWorkOrderHeader = new Map <Id, WorkOrderWrapper.ServiceOrder>();
		
		  if (idToWorkOrder != null && !idToWorkOrder.isEmpty()) {
            ilib_LogEvent.info('idToWorkOrder :'+idToWorkOrder);   //CMSI-209
            for (Id wrkOrdId: idToWorkOrder.keyset()) {
                if (String.isNotBlank(idToWorkOrder.get(wrkOrdId).Opportunity__c))
                    opportunityIdSet.add(idToWorkOrder.get(wrkOrdId).Opportunity__c);

                if (String.isNotBlank(idToWorkOrder.get(wrkOrdId).OwnerId))
                    ownerIdSet.add(idToWorkOrder.get(wrkOrdId).OwnerId);

                     //CMSI-209
                //DCP-46059
                if(String.isNotBlank(idToWorkOrder.get(wrkOrdId).ERP_Order_Line_Number__c))    
                setERPOrderLineNumber.add(idToWorkOrder.get(wrkOrdId).ERP_Order_Line_Number__c);

                //DCP-46059
                if(String.isNotBlank(idToWorkOrder.get(wrkOrdId).ERP_Order_Number__c))    
                setERPOrderNumber.add(idToWorkOrder.get(wrkOrdId).ERP_Order_Number__c);

                //Iterate over the child records (Work Order Line) and populate the parent wrapper.
                for (SVMXC__Service_Order_Line__c servOrderLine: idToWorkOrder.get(wrkOrdId).SVMXC__Service_Order_Line__r) {

                    if (String.isNotBlank(servOrderLine.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.Id) 
                        //DCP-46834: Start- only add to set if required to send
                        && canSendLine(idToWorkOrder.get(wrkOrdId),servOrderLine)){
                        //DCP-46834: End- only add to set if required to send
                        ownerIdSet.add(servOrderLine.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.Id);
                    }
                    
                }

            }

            ilib_LogEvent.info('opportunityIdSet :'+opportunityIdSet); 
            ilib_LogEvent.info('ownerIdSet :'+ownerIdSet);      //CMSI-209
        }

        //DCP-46059 - check how many work orders are there with same ERP Order Line number
        if (setERPOrderLineNumber != null && !setERPOrderLineNumber.isEmpty() && setERPOrderNumber  != null && !setERPOrderNumber.isEmpty()) {
            for (SVMXC__Service_Order__c workOrderObj: new WorkOrdersSelector().selectWOWithSameERPOrderAndERPOrderLineNum(setERPOrderNumber,setERPOrderLineNumber)) {
                if (erpOrderLineNumberToWorkOrderMap.containskey(workOrderObj.ERP_Order_Line_Number__c)) {
                    erpOrderLineNumberToWorkOrderMap.get(workOrderObj.ERP_Order_Line_Number__c).add(workOrderObj);
                } else {
                    erpOrderLineNumberToWorkOrderMap.put(workOrderObj.ERP_Order_Line_Number__c, new List < SVMXC__Service_Order__c > ());
                    erpOrderLineNumberToWorkOrderMap.get(workOrderObj.ERP_Order_Line_Number__c).add(workOrderObj);
                }
            }
        }

        //DCP-46059 - mark work order to be qualified for billing release
        if (erpOrderLineNumberToWorkOrderMap != null && !erpOrderLineNumberToWorkOrderMap.isEmpty()) {
            ilib_LogEvent.info('erpOrderLineNumberToWorkOrderMap :'+erpOrderLineNumberToWorkOrderMap.keyset());  //CMSI-209
            String releaseForBilling = '';
            for (String erpOrderLineNumber: erpOrderLineNumberToWorkOrderMap.keyset()) {
                releaseForBilling = '';
                for (SVMXC__Service_Order__c workOrder: erpOrderLineNumberToWorkOrderMap.get(erpOrderLineNumber)) {
                    if (workOrder.Acceptance_Status__c == WorkOrderWrapper.STRING_ACCEPTANCE_STATUS_COMPLETED && workOrder.LOA_Signed_and_Attached__c && workOrder.SVMXC__Order_Type__c == WorkOrderWrapper.STRING_ORDER_TYPE_INSTALLATION && workOrder.Acceptance_Forecast_in_Current_Quarter__c == WorkOrderWrapper.STRING_ACCEPTANCE_FORECAST) {
                        releaseForBilling = 'X';
                    } else {
                        releaseForBilling = '';
                        break; 
                    }
                }
                erpOrderLineNumberToQualifyForReleaseBilling.put(erpOrderLineNumber, releaseForBilling);
            }
        }

        
        //create a map to store opportunity Id to SAP Quote Number
         //fetch primary quote related to opportunity
        /* [19 Feb 2020] INC0254955 - Commented as a part of work order prod fix
		if(opportunityIdSet != null && !opportunityIdSet.isEmpty()){ 
        for(Apttus_Proposal__Proposal__c objQuote:new ApttusProposalsSelector().selectPrimary(opportunityIdSet)){
            opportunityIdToQuoteNumber.put(objQuote.Apttus_Proposal__Opportunity__c, objQuote.SAP_Quote__c);
        }
        }*/
		
		  if (ownerIdSet != null && !ownerIdSet.isEmpty())
          userIdToUser = new Map < Id, User > (new UsersSelector().selectUserEmployeeNoById(ownerIdSet));

        //Iterate over the ids recieved from WorkOrdersClass.
        if (idToWorkOrder != null && !idToWorkOrder.isEmpty())
        {
            for (Id wrkOrdId: idToWorkOrder.keyset())
            {
                if (!workOrderIdTOworkOrderHeader.keyset().contains(wrkOrdId))
                {
                    //create a new work order wrapper data type record.
                    WorkOrderWrapper.ServiceOrder objINWListWorkOrder = new WorkOrderWrapper.ServiceOrder(idToWorkOrder.get(wrkOrdId));
                    
                    if (userIdToUser != null && userIdToUser.containsKey(idToWorkOrder.get(wrkOrdId).OwnerId))
                        objINWListWorkOrder.Owner = userIdToUser.get(idToWorkOrder.get(wrkOrdId).OwnerId).IsPortalEnabled == true ? '100' : userIdToUser.get(idToWorkOrder.get(wrkOrdId).OwnerId).EmployeeNumber;

					
					 //Update Quote Number   
                     objINWListWorkOrder.ERP_Quote_No = opportunityIdToQuoteNumber.containsKey(idToWorkOrder.get(wrkOrdId).Opportunity__c) ? opportunityIdToQuoteNumber.get(idToWorkOrder.get(wrkOrdId).Opportunity__c) : null;   
                    
                    //DCP-46059
                    if(erpOrderLineNumberToQualifyForReleaseBilling != null && !erpOrderLineNumberToQualifyForReleaseBilling.isEmpty())
                    objINWListWorkOrder.SVMX_ReleaseForBilling = erpOrderLineNumberToQualifyForReleaseBilling.containskey(idToWorkOrder.get(wrkOrdId).ERP_Order_Line_Number__c) ? erpOrderLineNumberToQualifyForReleaseBilling.get(idToWorkOrder.get(wrkOrdId).ERP_Order_Line_Number__c) : '';
                    
                    //Iterate over the child records (Work Order Line) and populate the parent wrapper.
                    for (SVMXC__Service_Order_Line__c servOrderLine: idToWorkOrder.get(wrkOrdId).SVMXC__Service_Order_Line__r)
                    {
                        //DCP-46834: Start- move to method getLineInfo to avoid existing codescan error
                        setLineInfo(idToWorkOrder.get(wrkOrdId),servOrderLine,userIdToUser,objINWListWorkOrder.lstServiceOrderLines);
                        //DCP-46834: End- move to method getLineInfo to avoid existing codescan error
                    }
                    
                    //Iterate over Applied Contracts
                    for (Applied_Contract__c appliedContract: idToWorkOrder.get(wrkOrdId).Applied_Contracts__r)
                    {
                        WorkOrderWrapper.ServiceContracts objINWListServiceContract = new WorkOrderWrapper.ServiceContracts(appliedContract);    
                        if(String.isNotBlank(idToWorkOrder.get(wrkOrdId).SVMXC__Component__r.ERP_Equipment_ID__c) && String.isNotBlank(idToWorkOrder.get(wrkOrdId).SVMXC__Component__c)){
                            objINWListWorkOrder.lstServiceContracts.add(objINWListServiceContract);
                        }
                    }

                    //put the Id and workOrderWrapper instance.
                    workOrderidToWorkOrderHeader.put(wrkOrdId, objINWListWorkOrder);
                }
            }
        }

        //populate the list with workOrder records.
        workOrWrapper.lstServiceOrders = workOrderidToWorkOrderHeader.values();

        //create the JSON structure of the data present in workOrder wrapper.
        String strJson = JSON.serializePretty(workOrWrapper);
        ilib_LogEvent.info('JSON Output:\n' + strJson);
        ilib_LogEvent.pop();
        return strJson;
    }
	
	/**
	* @description Method for Http Response Execute callout
	* @author 
	* @param strJson 
	* @return HttpResponse 
	**/
	public override HttpResponse executeCallout(String strJson)
    {
        ilib_LogEvent.push(LOG_TITLE+'.executeCallout()'); //CMSI-209
        String strError = null;
        HTTPResponse res;

        try
        {
			String interfaceNameWithougSpaces = interfaceDetails.name.replace(' ', '_');
			System.debug('interfaceNameWithougSpaces ' + interfaceNameWithougSpaces);
			Map<String, String> config = UtilsRest.getIntegrationEndpoint(interfaceNameWithougSpaces);
			System.debug('interface config ' + config);
			HttpRequest req = UtilsRest.createHttpRequest(config.get('Endpoint'), config.get('ApiKey'), config.get('Authorization'));
			req.setBody(strJson);
			//timeout set to 120 Seconds 
            req.setTimeout(2 * 60 * 1000);

            if (Test.isRunningTest())
                res = new MockHTTPCallout().respond(req);
            else
                res = UtilsRest.send(req);
            ilib_LogEvent.info('res ::::'+res );
            ilib_LogEvent.info('res body ::::' + res.getBody());

            if ((null != res) &&
                (!String.isBlank(res.getBody())))
            {
                handleResult(res);
            }
        }
        catch (Exception e)
        {
            ApexExceptions.emit(LOG_TITLE, e, ilib_LogEvent.SERVICE);        //CMSI-209
            strError = e.getMessage() + '\n' + e.getStackTraceString();
            ilib_LogEvent.pop();    //CMSI-209
            throw e;
        }
        
        if(handlesError())
            return res;

        Integer intStatusCode = (res != null ? res.getStatusCode() : null);
        String strStatus = (res != null ? res.getStatus() : null);
        
        Boolean isSuccess = SUCCESS_STATUS_CODES.contains(intStatusCode);
        if (!isSuccess)
            throw new UtilsRest.InterfaceException('Unable to execute callout:\nError message: ' + strError+'\n Status Code: '+intStatusCode+'\n Status: '+strStatus);

        ilib_LogEvent.pop();           //CMSI-209
        return res;
    }
		
    /*******************************************************************************************************
    * @description Overrided method definition for handleResult
    * @param res HTTPResponse
    * @return void
    */
    protected override void handleResult(HTTPResponse res)
    {
        ilib_LogEvent.push(LOG_TITLE+'.handleResult()'); //CMSI-209
        ilib_LogEvent.info('res: ' + res);
        ilib_LogEvent.pop(); //CMSI-209
    }

    /**
     *  @author Akshay Mohan
     *  @DESCRIPTION - [DCP-46834] Set Work Detail line info in the wrapper
     *              - This Method will set wrapper instance of line. 
     *              - It will return without addingif line does not meet criteria to send to SAP.
     **/
    private void setLineInfo(SVMXC__Service_Order__c objWO,SVMXC__Service_Order_Line__c objWDLine,Map < Id, User > userIdToUser,List<WorkOrderWrapper.ServiceOrderLine> lstLines){
        ilib_LogEvent.push(LOG_TITLE + '.setLineInfo()');
        //DCP-46834: Start- only add JSON is qualified to send
        if(!canSendLine(objWO,objWDLine)){
            ilib_LogEvent.pop();
            return;
        }
        //DCP-46834: End- only add JSON is qualified to send
        //create a child record.
        WorkOrderWrapper.ServiceOrderLine objINWListWorkDetail = new WorkOrderWrapper.ServiceOrderLine(objWDLine);
        //DCP-46834: Start- Set estimate line values as per story 
        if(objWDLine.RecordTypeId==getWorkDetailEstimateRecordTypeId()){
            ilib_LogEvent.message('In Estimate line scenario WO Billing Type: '+objWO.SVMXC__Billing_Type__c);
            objINWListWorkDetail.SVMXC_Line_type='Estimate-Travel';
            objINWListWorkDetail.SVMX_PS_VS_Consumed_Product_Stock=objWDLine.Product_Code__c;
            objINWListWorkDetail.SVMXC_Actual_Quantity = String.valueOf(objWDLine.SVMXC__Estimated_Quantity2__c); //RITM0523587
            ilib_LogEvent.message('In Estimate line scenario');
            if(Label.WorkOrderBillingTypeBillable.equals(objWO.SVMXC__Billing_Type__c)){
                ilib_LogEvent.message('WO is billable');
                objINWListWorkDetail.IS_BILLABLE='X';
            }   
        }
        //DCP-46834: End- Set estimate line values as per story 
        if (userIdToUser != null && userIdToUser.containsKey(objWDLine.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.Id)) {
            objINWListWorkDetail.SVMXC_Group_Member = userIdToUser.get(objWDLine.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.Id).EmployeeNumber;
        }

        lstLines.add(objINWListWorkDetail);
        ilib_LogEvent.pop();
    }

    /**
     *  @author Akshay Mohan
     *  @DESCRIPTION - [DCP-46834] Only send work details of estimate record type in certain scenarios
     *              - This Method will return true if record type is not estimate or record type is estimate & work order type = ‘Service Activities’ & Work order status = ‘Completed’ 
     **/
    private Boolean canSendLine(SVMXC__Service_Order__c objWO,SVMXC__Service_Order_Line__c objWD){
        
        if(getWorkDetailEstimateRecordTypeId()!=objWD.RecordTypeId){
            ilib_LogEvent.message('objWD('+objWD+') Not estimate line');
            return true;
        }if(Label.WorkOrderTypeServiceActivities.equals(objWO.SVMXC__Order_Type__c) 
                && Label.WorkOrderStatusCompleted.equals(objWO.SVMXC__Order_Status__c)
                && getWorkDetailEstimateProductCodes().contains(objWD.Product_Code__c)){
            ilib_LogEvent.message('Work detail('+objWD+') meets criteria to send travel lines');
            return true;
        }else{
            ilib_LogEvent.message('Work detail('+objWD+') does not meet criteria to send travel lines');
            return false;
        }
    }

    /**
     *  @author Akshay Mohan
     *  @DESCRIPTION - [DCP-46834] Only get Record type from API if not set already
     *                  - This method will return Record type id of work detail record type Estimate
     *                  - This method will ensure API is called only once to fetch the id
     **/
    private Id getWorkDetailEstimateRecordTypeId(){
        if(idEstimateRecordType==null){
            idEstimateRecordType= SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('Estimate').getRecordTypeId();
            ilib_LogEvent.info('idEstimateRecordType: ' + idEstimateRecordType);
        }
        return idEstimateRecordType;
    }

    /**
     *  @author Akshay Mohan
     *  @DESCRIPTION - [DCP-46834] Only get Record type from API if not set already
     *                  - Only query metadata of product codes if not already queried once in transaction
     **/
    private Set<String> getWorkDetailEstimateProductCodes(){
        if(setTravelCodes==null){
            setTravelCodes= new Set<String>(new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{'Travel_Product_Codes'})[0].Value__c.split(';'));
            ilib_LogEvent.info('setTravelCodes: ' + setTravelCodes);
        }
        return setTravelCodes;
    }

}
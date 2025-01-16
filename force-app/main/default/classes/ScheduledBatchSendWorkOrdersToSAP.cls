/*@ author       : Vaibhav
 * @ date         : 02-17-2020
 * @ Description  : DCP 33466 Accrual of Monthly Labor Hours to SAP
 *
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Description
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Vaibhav        02-17-2020                Initial version
 * Lekhasree      09-14-2023                TASK0941720
 */
global class ScheduledBatchSendWorkOrdersToSAP extends ilib_ScheduleAndBatch implements Database.Stateful, Database.AllowsCallouts {

  global integer intTotalRecords = 0;
  global integer intSuccessfulRecords = 0;
  global List < String > lstErrors = new List < String > ();
  public static List<Database.SaveResult> lstSaveErrors = new List<Database.SaveResult>();
  public static Map<Id, String> mapRecIdToErrors = new Map<Id, String>();
  public static ID batchprocessid;  
  
		/*
         * description - execute method
		 * return - void
         */   
  global Override void execute(SchedulableContext ctx) {
    integer defaultBatchsize = 1;
    Map < String, String > params = UtilsSettings.getCustomMetadataMap('Send_Work_Orders_to_SAP_Batch');
    Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'SAPWorkOrders', defaultBatchSize);

    if (batchSize < 1 || batchSize > 100) {
      batchSize = defaultBatchSize;
    }
    batchprocessid = Database.executeBatch(new ScheduledBatchSendWorkOrdersToSAP(), batchsize);
  }

  /*start method to query for work orders where Qualified for batch processing is true.*/
  global override Database.QueryLocator start(Database.BatchableContext bc) {
     // get the date filter from custom label
    string dateFilter = System.Label.Work_Orders_Qualified_for_Batched_Sync_to_ERP_Date_Filter;
    String strSoql = 'SELECT id,SVMXC__Order_Status__c FROM SVMXC__Service_Order__c Where Qualified_for_Batched_Sync_to_ERP__c = true ';
    if(string.isNotBlank(dateFilter)){
    strSoql += 'AND LastModifiedDate = LAST_N_DAYS:'+dateFilter;   
    }
	return Database.getQueryLocator(strSoql);
  }

  /*execute method to inactivate products of query result*/
  global override void execute(Database.BatchableContext bc, List < sObject > lstScope) {
    WorkOrderDataSender wrkOrdSyncSendInterface = new WorkOrderDataSender();
    WorkOrderDataSender.triggeredManuallyOrFromBatch = 'Batch';//DCP-37399
    list < SVMXC__Service_Order__c > lstSendWorkOrdersToSAP = new list < SVMXC__Service_Order__c > ();
    for (SVMXC__Service_Order__c workOrdersObj: (list < SVMXC__Service_Order__c > ) lstScope) {
		//Added to remove Closed/Completed WOs from resyncing to SAP
		if(workOrdersObj.SVMXC__Order_Status__c != Label.WorkOrderStatusCompleted && workOrdersObj.SVMXC__Order_Status__c != Label.WorkOrderStatusClosed &&
			workOrdersObj.SVMXC__Order_Status__c != Label.WorkOrderStatusReopenRequested && workOrdersObj.SVMXC__Order_Status__c != Label.WorkOrderStatusClosedDuplicate)
			
			wrkOrdSyncSendInterface.callout(workOrdersObj.Id);
		
		workOrdersObj.Qualified_for_Batched_Sync_to_ERP__c = false;
		lstSendWorkOrdersToSAP.add(workOrdersObj);
    }

    if (lstSendWorkOrdersToSAP != null && !lstSendWorkOrdersToSAP.isEmpty()) {
      intTotalRecords = intTotalRecords + lstSendWorkOrdersToSAP.size();
      Integer index = 0;
      List < Database.SaveResult > dsrs = Database.Update(lstSendWorkOrdersToSAP, false);

      for(Integer i=0;i<dsrs.size();i++) {
        if (!dsrs.get(i).isSuccess()) {
          lstErrors.add(dsrs.get(i).getErrors()[0].getMessage() + '.<br/>');
          lstSaveErrors.add(dsrs.get(i)); 
          mapRecIdToErrors.put(lstSendWorkOrdersToSAP.get(i).Id, dsrs.get(i).getErrors()[0].getMessage());
        } else {
          intSuccessfulRecords++;
        }
        index++;
      }

    }

  }

		/*
         * description - finish method
		 * return - void
         */
  global Override void finish(Database.BatchableContext objBatchableContext) {

    integer intFailedRecords = intTotalRecords - intSuccessfulRecords;
    string strError = '';
    for (string strErr: lstErrors) {
      strError = strError + strErr;
    }
    string strBodyText = 'Hi,<br/><br/>' +
      'The batch ScheduledBatchSendWorkOrdersToSAP completed successfully. Below are the statistics:<br/><br/>' +
      'Total Number of Records Processed: ' + string.valueOf(intTotalRecords) + '<br/>' +
      'Total Number of Successful Updates: ' + string.valueOf(intSuccessfulRecords) + '<br/>' +
      'Total Number of Failed Records: ' + string.valueOf(intFailedRecords) + '<br/>' +
      'The Records failed due to following Errors: <br/>' + strError;
    Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
    objEmailMessage.setPlainTextBody(strBodyText);
    objEmailMessage.setHtmlBody(strBodyText);
    objEmailMessage.setSubject('ScheduledBatchSendWorkOrdersToSAP Batch Completion Update');
    objEmailMessage.setTargetObjectId(userInfo.getUserId());
    objEmailMessage.setSaveAsActivity(false);
    Messaging.sendEmail(new List < Messaging.SingleEmailMessage > {
      objEmailMessage
    });

		// code for error logging and sending MS Teams notification
		try{
			if (Feature.isOn('ServiceBatchErrorNotifications')){				
				String source = 'ScheduledBatchSendWorkOrdersToSAP';
					if(!lstSaveErrors.isEmpty()){
						ApexExceptions.emitSaveErrors(lstSaveErrors, source);
					}
					if(!mapRecIdToErrors.isEmpty()){
						ilib_Queueablethread  queueableThread=new ilib_Queueablethread('MSTeamsNotification'); 
						queueableThread.logandQueue(new QueueableMSTeamsNotificationSender(mapRecIdToErrors, source, batchProcessId),'QueueableMSTeamsNotificationSender','getTableEmailBodyAndSendNotification');		

						if(!queueableThread.lstQueueableJobs.isEmpty()){
							ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
						}						
					}
			}
		}
		catch(Exception e){
			System.debug('!!!!!!!!!!!!!'+e.getMessage());			
		}			
        

  }



}
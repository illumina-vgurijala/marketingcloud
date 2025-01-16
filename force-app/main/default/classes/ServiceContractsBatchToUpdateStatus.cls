/***************************************************************************************************************************************
* NAME   : ServiceContractsBatchToUpdateStatus
* DESCRIPTION  : Batch class to update status for Service Contracts based on Start and End date.
*                    
* @AUTHOR : Shashank Singhal
* @DATE   : 13-September-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shashank               13-Sept-2018          Initial Version. 
* Biswajeet              04-July-2022          CMSI-94 Instrumentation of class
****************************************************************************************************************************************/ 
global class ServiceContractsBatchToUpdateStatus extends ilib_ScheduleAndBatch implements database.stateful{
	
    global static final string STRING_BASE_QUERY = 'Select Id, SVMXC__Start_Date__c, SVMXC__End_Date__c, Status__c, Pending_Cancellation__c from SVMXC__Service_Contract__c';
    global static string strFinalQuery = '';
    public static final String LOG_TITLE = 'ServiceContractsBatchToUpdateStatus'; //CMSI-94
    global static final string STRING_SERVICE_CONTRACT_STATUS_CANCELED = 'Canceled';
    global static final string STRING_SERVICE_CONTRACT_STATUS_BLOCKED = 'Blocked';
    global static final string STRING_SERVICE_CONTRACT_STATUS_ACTIVE = 'Active';
    global static final string STRING_SERVICE_CONTRACT_STATUS_PENDING_ACTIVATION = 'Pending Activation';
    global static final string STRING_SERVICE_CONTRACT_STATUS_EXPIRED = 'Expired';
    global static final string STRING_SERVICE_CONTRACT_STATUS_DRAFT = 'Draft';
    global static final Map<String, String> MAP_STRING_TO_STRING_BATCH_SIZE = UtilsSettings.getCustomMetadataMap('Service_Contract_Batch');
    global integer intTotalRecords = 0;
    global integer intSuccessfulRecords = 0;
    global List<String> lstErrors = new List<String>();
    public static List<Database.SaveResult> lstSaveErrors = new List<Database.SaveResult>(); 
	public static Map<Id, String> mapRecIdToErrors = new Map<Id, String>();	
	public static ID batchprocessid;
	
		/*
         * description - execute method
		 * return - void
         */ 	
    global override void execute(SchedulableContext objSchedulableContext)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE); //CMSI-94
        ilib_LogEvent.push(LOG_TITLE+'.execute()-Schedule'); //CMSI-94
		//changed the batch size to avoid getting too many future callouts-51 error while creating PM plans for these contracts
        Integer intBatchSize = 10;
        //get parameter values from custom metadata if present
        if (MAP_STRING_TO_STRING_BATCH_SIZE != null){
            try{
                intBatchSize = Integer.valueOf(MAP_STRING_TO_STRING_BATCH_SIZE.get('ServiceContractBatchSize'));// load batch from custom metadata
                ilib_LogEvent.info('Batch Size :'+intBatchSize);
            }catch (Exception e){
				ApexExceptions.emit(LOG_TITLE ,e, ilib_LogEvent.SERVICE); //CMSI-94
            }
        }
		batchprocessid = Database.executeBatch(new ServiceContractsBatchToUpdateStatus(), intBatchSize);
        ilib_LogEvent.pop();//CMSI-94
        ilib_LogEvent.emit(); //CMSI-94
    }
    
		/*
         * description - start method
         */ 	
    global override Database.QueryLocator start(Database.BatchableContext objBatchableContext){
        //system.debug(Integer.valueOf(MAP_STRING_TO_STRING_BATCH_SIZE.get('StartDateRange')));
        integer intStartDateRange = -1;
        integer intEndDateRange = 1;
        if (MAP_STRING_TO_STRING_BATCH_SIZE != null){
            try{
                intStartDateRange = -1*Integer.valueOf(MAP_STRING_TO_STRING_BATCH_SIZE.get('StartDateRange'));
                intEndDateRange = Integer.valueOf(MAP_STRING_TO_STRING_BATCH_SIZE.get('EndDateRange'));
            }catch (Exception e){
				System.debug('Inside ServiceContractsBatchToUpdateStatus the exception is '+e.getMessage());
				ApexExceptions.emit(LOG_TITLE ,e, ilib_LogEvent.SERVICE); //CMSI-94
            }
        }
        Date dtStartDate = system.today().addDays(intStartDateRange);
        Date dtEndDate = system.today().addDays(intEndDateRange);
        ilib_LogEvent.info('dtStartDate :'+dtStartDate);
        ilib_LogEvent.info('dtEndDate :'+dtEndDate);
        string strWhereClause = ' where (SVMXC__Start_Date__c >= :dtStartDate AND SVMXC__Start_Date__c <= :dtEndDate) OR (SVMXC__End_Date__c >= :dtStartDate AND SVMXC__End_Date__c <= :dtEndDate)';
        strFinalQuery = STRING_BASE_QUERY + strWhereClause;
        return Database.getQueryLocator(strFinalQuery);
    }
    
		/*
         * description - execute method
		 * return - void
         */ 	
    global override void execute(Database.BatchableContext objBatchableContext, List<sObject> lstRecords){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE); //CMSI-94
        ilib_LogEvent.push(LOG_TITLE+'.execute()-Batch'); //CMSI-94
        List<SVMXC__Service_Contract__c> lstServiceContractToUpdate = new List<SVMXC__Service_Contract__c>();
        //Iterate over the service contract records
        for(SVMXC__Service_Contract__c objServiceContract:(List<SVMXC__Service_Contract__c>)lstRecords){
            if(objServiceContract.Status__c != STRING_SERVICE_CONTRACT_STATUS_CANCELED
               && objServiceContract.Status__c != STRING_SERVICE_CONTRACT_STATUS_BLOCKED){
                   //set the status
                   objServiceContract.Status__c = getServiceContractStatus(objServiceContract);
                   //INC0200579
                   if(objServiceContract.Status__c == STRING_SERVICE_CONTRACT_STATUS_EXPIRED && objServiceContract.Pending_Cancellation__c){
                       objServiceContract.Status__c=STRING_SERVICE_CONTRACT_STATUS_CANCELED;
                       objServiceContract.Pending_Cancellation__c=false;
                   }
                   lstServiceContractToUpdate.add(objServiceContract);
               }
        }
        if(!lstServiceContractToUpdate.isEmpty()){
            intTotalRecords = intTotalRecords + lstServiceContractToUpdate.size();
			List<Database.SaveResult> lstSaveResult = Database.update(lstServiceContractToUpdate, false);	
            for(Integer i=0;i<lstSaveResult.size();i++){
				
                if(lstSaveResult.get(i).isSuccess()){
                    intSuccessfulRecords++;
                }else{
                    for(Database.Error objError : lstSaveResult.get(i).getErrors()) {
                        lstErrors.add(objError.getMessage()+'.<br/>');
                    }
					lstSaveErrors.add(lstSaveResult.get(i));
					mapRecIdToErrors.put(lstServiceContractToUpdate.get(i).id, lstSaveResult.get(i).getErrors()[0].getMessage());
                }
            }
            ilib_LogEvent.info('Successful records count :'+intSuccessfulRecords); //CMSI-94
            ilib_LogEvent.info('mapRecIdToErrors :'+(!mapRecIdToErrors.isEmpty() ? String.valueOf(mapRecIdToErrors) : 'map is empty')); //CMSI-94
        }
        ilib_LogEvent.pop(); //CMSI-94
        ilib_LogEvent.emit(); //CMSI-94
    }
    
		/*
         * description - finish method
		 * return - void
         */ 	
    global override void finish(Database.BatchableContext objBatchableContext){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE); //CMSI-94
        ilib_LogEvent.push(LOG_TITLE+'.finish()');
        integer intFailedRecords = intTotalRecords-intSuccessfulRecords;
        string strError = '';
        for(string strErr:lstErrors){
            strError = strError+strErr;
        }
        string strBodyText = 'Hi,<br/><br/>'+
            				'The batch ServiceContractsBatchToUpdateStatus completed successfully. Below are the statistics:<br/><br/>'+
            				'Total Number of Records Processed: '+string.valueOf(intTotalRecords)+'<br/>'+
            				'Total Number of Successful Updates: '+string.valueOf(intSuccessfulRecords)+'<br/>'+
            				'Total Number of Failed Records: '+string.valueOf(intFailedRecords)+'<br/>'+
            				'The Records failed due to following Errors: <br/>'+strError;
        Messaging.SingleEmailMessage objEmailMessage = new Messaging.SingleEmailMessage();
        objEmailMessage.setPlainTextBody(strBodyText);
        objEmailMessage.setHtmlBody(strBodyText);
        objEmailMessage.setSubject('ServiceContractsBatchToUpdateStatus Batch Completion Update');
        objEmailMessage.setTargetObjectId(userInfo.getUserId());
        objEmailMessage.setSaveAsActivity(false);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{objEmailMessage});

		//for exception logging 
		try{
			if(Feature.isOn('ServiceBatchErrorNotifications')){
				String source = LOG_TITLE;
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
                ilib_LogEvent.info('mapRecIdToErrors :'+(!mapRecIdToErrors.isEmpty() ? String.valueOf(mapRecIdToErrors) : 'map is empty')); //CMSI-94
			}
		}
		catch(Exception e){
			ApexExceptions.emit(LOG_TITLE, e, ilib_LogEvent.getWorkstream());	//CMSI-94	
		}
        ilib_LogEvent.pop();//CMSI-94
		ilib_LogEvent.emit(); //CMSI-94
    }
    
	/*
    *  @AUTHOR:  Shashank Singhal 
    *  @DESCRIPTION: get the status for Service contract based on the Start and End dates for DCP-9448
    *  @PARAM :  SVMXC__Service_Contract__c objServiceContract
    *  @RETURN:  string
    */
    global static string getServiceContractStatus(SVMXC__Service_Contract__c objServiceContract){
        ilib_LogEvent.push(LOG_TITLE +'.getServiceContractStatus()'); //CMSI-94
        ilib_LogEvent.info('objServiceContract :'+objServiceContract); //CMSI-94
        string strStatus = STRING_SERVICE_CONTRACT_STATUS_DRAFT;
        if(objServiceContract.SVMXC__Start_Date__c == objServiceContract.SVMXC__End_Date__c){
            strStatus = STRING_SERVICE_CONTRACT_STATUS_EXPIRED;
        }else if(objServiceContract.SVMXC__Start_Date__c <= system.today() && objServiceContract.SVMXC__End_Date__c >= system.today()){
            strStatus = STRING_SERVICE_CONTRACT_STATUS_ACTIVE;
        }else if(objServiceContract.SVMXC__Start_Date__c > system.today()){
            strStatus = STRING_SERVICE_CONTRACT_STATUS_PENDING_ACTIVATION;
        }else if(objServiceContract.SVMXC__End_Date__c < system.today()){
            strStatus = STRING_SERVICE_CONTRACT_STATUS_EXPIRED;   
        }
        ilib_LogEvent.info('status for Service contract :'+strStatus);//CMSI-94
        ilib_LogEvent.pop(); //CMSI-94
        return strStatus;
    }    
}
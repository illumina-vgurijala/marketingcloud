/**
    *    @author : Nitin Sood
    *    @date   : 02-March-2020
    *    @description : Class to attempt to auto-close cases
    *    Modification Log:
    *    ------------------------------------------------------------------------------------ 
    *    Developer                      Date                Description
    *    Nitin Sood                  02-March-2020          Initial Version.
    *    ------------------------------------------------------------------------------------ 
    *                    
    */
    global class BatchAttemptAutoCloseCase extends ilib_ScheduleAndBatch implements Database.Batchable<sObject>, Database.Stateful{
         
        public static final Id BUSINESS_ISSUE_CASE_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get(System.label.CaseRecordTypeBusinessIssue).getRecordTypeId();  
		List<Database.SaveResult> lstSaveErrors = new List<Database.SaveResult>();
		Map<Id, String> mapRecIdToErrors = new Map<Id, String>();
		ID batchprocessid;
        Map<String, List<CaseIdError>> mapEmailToCaseIdError =  new Map<String, List<CaseIdError>>(); // final map to store email and case id and error          
        /*
		*@Description: Excute method of Schedulable Context
		*/
		global Override void execute(SchedulableContext ctx) {
            integer defaultBatchsize = 200;
            Map < String, String > params = UtilsSettings.getCustomMetadataMap('Attempt_auto_case_completion');
            Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'AttempCaseCompletion', defaultBatchSize);

            if (batchSize < 1 || batchSize > 200) {
              batchSize = defaultBatchSize;
            }
            batchprocessid = Database.executeBatch(new BatchAttemptAutoCloseCase(), batchsize);
        }
        
        /*
		*@Description: Start method of Batchable Context
		*/
        global override Database.QueryLocator start(Database.BatchableContext bc){
            
            Set<String> setClosedStatuses = new Set<String>{'Completed', 'Closed'};

            Set<String> setIntegrationStatuses = new Set<String>{'Success', 'Not Required'};
			if(Test.isRunningTest()){
				setIntegrationStatuses.add('In Progress');
			}
			List<AsyncApexJob> lstCompletedJobs = [Select Id, ApexClass.Name, CreatedDate, JobType, Status FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Completed' AND ApexClass.Name = 'BatchAttemptAutoCloseCase' AND NumberOfErrors	= 0 Order By CreatedDate DESC NULLS LAST Limit 1 ];
            
			DateTime lastCompletionDateTime = NULL;
            if(lstCompletedJobs != null && lstCompletedJobs.size() > 0){
				lastCompletionDateTime = lstCompletedJobs[0].CreatedDate;
			}
            System.debug('!!!!!!!!!!!!!lastCompletionDateTime after time set!!!!!!!!!!!!!!!!!!!!'+lastCompletionDateTime);

            String sQuery = 'SELECT id, SVMXC__Case__c, OwnerId, SVMXC__Case__r.Status, SVMXC__Case__r.OwnerId, SVMXC__Case__r.CaseNumber , Owner.Email, Owner.Name, SVMXC__Case__r.Case_Eligible_for_QA_Review__c, SVMXC__Case__r.Case_Eligible_for_Logistics_Review__c, SVMXC__Case__r.RecordTypeId, WO_Completed_by__c  FROM SVMXC__Service_Order__c WHERE SVMXC__Order_Status__c IN: setClosedStatuses AND Attempt_case_completion__c = true AND Integration_Status__c IN: setIntegrationStatuses AND SVMXC__Case__r.Status NOT IN: setClosedStatuses';	
			
			if(lastCompletionDateTime != null ){
				sQuery = sQuery +' AND LastModifiedDate >: lastCompletionDateTime';
			}

            return Database.getQueryLocator(sQuery);
        }
		
        /*
		*@Description: Execute method of Batchable Context
		*/
        
        global override void execute(Database.BatchableContext bc, List<sObject> lstScope){
       
            List<Case> lstCasesToBeUpdated = new List<Case>(); //to store cases whcih needs to be updated
            Map<Id, String> mapCaseIdOwnerEmail =  new Map<Id, String>(); //map for storing case id and email and case number
            Map<Id, String> mapCaseIdError = new Map<Id, String>(); // map to store failed case Ids and their error

            //iterating over completed work orders
            for(SVMXC__Service_Order__c objWorkorder: (list < SVMXC__Service_Order__c > ) lstScope){
                if(objWorkorder.OwnerId == objWorkorder.SVMXC__Case__r.OwnerId){
                    Case objCase = new Case(); 
                    objCase.Id = objWorkorder.SVMXC__Case__c;
					if(objWorkorder.SVMXC__Case__r.Case_Eligible_for_Logistics_Review__c){
						objCase.status = 'Pending Logistics Review';						
					}
					else if(objWorkorder.SVMXC__Case__r.Case_Eligible_for_QA_Review__c && objWorkorder.SVMXC__Case__r.RecordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE ){
						objCase.status = 'Pending QA Review';						
					}
					else{
						objCase.status = 'Completed';
						objCase.Case_Completed_By__c = objWorkorder.WO_Completed_by__c;						
					}
                    objCase.Record_Updated_from_SFM__c = true;//INC0325752
                    lstCasesToBeUpdated.add(objCase);
                    mapCaseIdOwnerEmail.put(objWorkorder.SVMXC__Case__c, objWorkorder.Owner.Email+'~'+ objWorkorder.SVMXC__Case__r.CaseNumber+'~'+ objWorkorder.Owner.Name);
                }               
            }
          
            //iterating over update list and capturing errors for failed cases
            if(lstCasesToBeUpdated.size() > 0){
                List<Database.SaveResult> lstSR = Database.update(lstCasesToBeUpdated, false);

                for(Integer i=0;i<lstSR.size();i++) {

                    if (!lstSR.get(i).isSuccess()){
                        
                        mapCaseIdError.put(lstCasesToBeUpdated.get(i).Id, lstSR.get(i).getErrors()[0].getMessage());
						mapRecIdToErrors.put(lstCasesToBeUpdated.get(i).Id, lstSR.get(i).getErrors()[0].getMessage());
						lstSaveErrors.add(lstSR.get(i)); 
                    }
                }               
            }
            
            //iterating over failed list and preparing map for emial ids with case number and failed error 
            for(Id caseId : mapCaseIdError.keyset()){

                if(mapEmailToCaseIdError.containsKey(mapCaseIdOwnerEmail.get(caseId).split('~')[0])){
                    CaseIdError objCaseIdError = new CaseIdError();
                    objCaseIdError.caseNumber = mapCaseIdOwnerEmail.get(caseId).split('~')[1];
                    objCaseIdError.ownerName = mapCaseIdOwnerEmail.get(caseId).split('~')[2];
                    objCaseIdError.error = mapCaseIdError.get(caseId);
                    mapEmailToCaseIdError.get(mapCaseIdOwnerEmail.get(caseId).split('~')[0]).add(objCaseIdError);
                }
                else{
                    List<CaseIdError> lstCaseIdError =  new List<CaseIdError>();
                    CaseIdError objCaseIdError = new CaseIdError();
                    objCaseIdError.caseNumber = mapCaseIdOwnerEmail.get(caseId).split('~')[1];
                    objCaseIdError.ownerName = mapCaseIdOwnerEmail.get(caseId).split('~')[2];
                    objCaseIdError.error = mapCaseIdError.get(caseId);
                    lstCaseIdError.add(objCaseIdError);
                    mapEmailToCaseIdError.put(mapCaseIdOwnerEmail.get(caseId).split('~')[0],lstCaseIdError);
                    
                }
                
            }
          
        }
        /*
		*@Description: Finish method of Batchable Context
		*/
        global override void finish(Database.BatchableContext bc){
            
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
			if(!mapEmailToCaseIdError.isEmpty()){
				for(String receipientEmail : mapEmailToCaseIdError.keyset()){
					
					String tableBody = getTableEmailBody(mapEmailToCaseIdError.get(receipientEmail));
					String caseOwnerName = mapEmailToCaseIdError.get(receipientEmail)[0].ownerName;        
					Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
					String[] toAddresses = new String[]{receipientEmail};
					String subject = 'ACTION NEEDED: Unsuccessful Completion of Case(s)';
					email.setSubject(subject);
					email.setToAddresses(toAddresses);
					email.setHtmlBody('Dear ' + caseOwnerName+ ',<br>'+'<br>DCP automation processes were NOT able to automatically complete the following Case(s): <br>'+tableBody + '<br> Please note, your action is required to Complete the Case(s) above.  Please log into DCP, make any necessary updates and manually complete the Case(s) as soon as possible.<br>'+'Thank you.');
					mails.add(email);
						
				}
				
				Messaging.sendEmail(mails);
			}
					
			// code for error logging and sending MS Teams notification
			try{
				if(Feature.isOn('ServiceBatchErrorNotifications')){				
					String source = 'BatchAttemptAutoCloseCase';
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
				System.debug('!!!!!!!!!!!!!!!exception!!!!!!!!!!!!'+e.getMessage());
			}						
		}
        /*
		*@method: getTableEmailBody
		*/
        public static string getTableEmailBody(List<CaseIdError> lstCaseIdError){

            String htmlBody = '';

            //open table..
            htmlBody = '<table border="1" style="border-collapse: collapse"><tr><th>Case Number</th><th>Error Message</th></tr>';

            //iterate over list and output columns/data into table rows...
            for(CaseIdError objCaseIdError : lstCaseIdError){

                String caseNumber = objCaseIdError.caseNumber; 
                String error = objCaseIdError.error; 

                htmlBody += '<tr><td>' + caseNumber + '</td><td>' +error + '</td></tr>';

            }

            //close table...
            htmlBody += '</table>';

            system.debug('Email Body: ' + htmlBody);   

            return htmlBody;

        }
        /*
		*@Inner class: CaseIdError
		*/
        public class CaseIdError{
            public string caseNumber;
            public string error;
            public string ownerName;
        }
    }
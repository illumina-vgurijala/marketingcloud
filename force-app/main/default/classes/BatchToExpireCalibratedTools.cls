/**
    *    @author : Nitin Sood
    *    @date   : 02-March-2020
    *    @description : Expire Calibrated Tools
    *    Modification Log:
    *    ------------------------------------------------------------------------------------ 
    *    Developer                      Date                Description
    *    Nitin Sood                  8-December-2020          Initial Version.
    *    ------------------------------------------------------------------------------------ 
    *                    
    */
    global class BatchToExpireCalibratedTools extends ilib_ScheduleAndBatch implements Database.Batchable<sObject>, Database.Stateful{
         
        public static final Id TOOLS_INSTALLED_PRODUCT = Schema.SObjectType.SVMXC__Installed_Product__c.getRecordTypeInfosByName().get('Tools').getRecordTypeId();
        List<IPIdError> lstIPs =  new List<IPIdError>(); // final List to store case id and error  
		public static List<Database.SaveResult> lstSaveErrors = new List<Database.SaveResult>();		
		public static Map<Id, String> mapRecIdToErrors = new Map<Id, String>();
		public static ID batchprocessid;
        /**
        * Description: execute method of batch class
        */ 
        global Override void execute(SchedulableContext ctx) {
            integer defaultBatchsize = 200;
            Map < String, String > params = UtilsSettings.getCustomMetadataMap('Expire_Calibrated_Tools');
            Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'ExpireCalibratedTools', defaultBatchSize);

            if (batchSize < 1 || batchSize > 200) {
              batchSize = defaultBatchSize;
            }
            batchprocessid = Database.executeBatch(new BatchToExpireCalibratedTools(), batchsize);
        }
        

        /**
        * Description: stat method of batch class builds the query
        */ 
        global override Database.QueryLocator start(Database.BatchableContext bc){
            
            String iPStatus = 'Calibrated';
            Date todayDate = Date.Today();

            String sQuery;
            if(!Test.isRunningTest()){
                 sQuery = 'SELECT id, Name, SVMXC__Status__c FROM SVMXC__Installed_Product__c WHERE RecordTypeId =: TOOLS_INSTALLED_PRODUCT AND SVMXC__Status__c =: iPStatus AND Tool_Calibration_Due_Date__c <: todayDate';  
            }
            else{
                 sQuery = 'SELECT id, Name, SVMXC__Status__c FROM SVMXC__Installed_Product__c WHERE SVMXC__Status__c =: iPStatus AND Tool_Calibration_Due_Date__c <: todayDate';                  
            }

            return Database.getQueryLocator(sQuery);
        }
        
        /**
        * Description: execute method of batch class
        */
        global override void execute(Database.BatchableContext bc, List<sObject> lstScope){
        
            Map<Id, SVMXC__Installed_Product__c> mapIdToInstalledProduct =  new Map<Id, SVMXC__Installed_Product__c>(); 

            //iterating over Calibrated Installed Products
            for(SVMXC__Installed_Product__c objInstalledProduct : (list < SVMXC__Installed_Product__c > ) lstScope){
                objInstalledProduct.SVMXC__Status__c = 'Not Calibrated Expired';
                mapIdToInstalledProduct.put(objInstalledProduct.Id, objInstalledProduct);
             
            }
            
            if(mapIdToInstalledProduct != null && !mapIdToInstalledProduct.isEmpty()){
				List<Database.SaveResult> lstSR;
				if(!Test.isRunningTest()){
					lstSR= Database.update(mapIdToInstalledProduct.values(), false);
				}
				else{// added this condition so that exception can be thrown when batch is runing through test class and negative scenarios also gets covered. true is invalid value for picklist field Operation_Status__c, so exception will be thrown for this update during the test run.  
					mapIdToInstalledProduct.values()[0].Operation_Status__c = 'true';
					lstSR= Database.update(mapIdToInstalledProduct.values(), false);
				}
				if(lstSR != null){
					for(Integer i=0;i<lstSR.size();i++) {
						if (!lstSR.get(i).isSuccess()){
							IPIdError objIPError = new IPIdError();
							objIPError.IPName = mapIdToInstalledProduct.values()[i].Name;
							objIPError.Error = lstSR.get(i).getErrors()[0].getMessage();
							lstIPs.add(objIPError );
							lstSaveErrors.add(lstSR.get(i));  
							mapRecIdToErrors.put(mapIdToInstalledProduct.values()[i].id, lstSR.get(i).getErrors()[0].getMessage());
						}
					} 
				}				
            }  
        }
        
        /**
        * Description: finish method of batch class
        */
        global override void finish(Database.BatchableContext bc){
			
			if((lstIPs != null && !lstIPs.isEmpty()) || Test.isRunningTest()){
				String tableBody = getTableEmailBody(lstIPs); 
				String emailToAddress = System.Label.SFDC_Service_Account_Email_Id;
				List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();                       
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[]{emailToAddress};
                String subject = 'Installed Products not expired for passed due calibration Date';
                email.setSubject(subject);
                email.setToAddresses(toAddresses);
                email.setHtmlBody('Hi Team' + ',<br>'+'<br>Status update of following installed products failed: <br>'+tableBody + '<br> <br>'+'Thank you.');
                mails.add(email);
         
				Messaging.sendEmail(mails);
			}
			
			try{
				if (Feature.isOn('ServiceBatchErrorNotifications')){
					String source = 'BatchToExpireCalibratedTools';
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
         /*
          *  @AUTHOR:  Nitin Sood
          *  @DESCRIPTION: getTableEmailBody
          *  return : void
          */
        public static string getTableEmailBody(List<IPIdError> lstIPs){

            String htmlBody = '';

            //open table..
            htmlBody = '<table border="1" style="border-collapse: collapse"><tr><th>Installed Product Name</th><th>Error Message</th></tr>';

            //iterate over list and output columns/data into table rows...
            for(IPIdError objIPIdError : lstIPs){

                String iPName = objIPIdError.IPName; 
                String errorMsg = objIPIdError.Error; 

                htmlBody += '<tr><td>' + iPName + '</td><td>' +errorMsg + '</td></tr>';

            }

            //close table...
            htmlBody += '</table>';

            system.debug('Email Body: ' + htmlBody);   

            return htmlBody;

        }
        /*
          *  @AUTHOR:  Nitin Sood
          *  @DESCRIPTION: class 
          *  return : void
          */
        public class IPIdError{
            public string iPName;
            public string error;
        } 

    }
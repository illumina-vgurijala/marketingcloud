/**************************************************************************************************************************************
 * NAME   : MSTeamsNotificationSender
 * @AUTHOR : Kushagra Desai 
 **/

 public with sharing class MSTeamsNotificationSender extends ilib_RestReceiver{

    private static OrgWideEmailAddress owea = [select Id from OrgWideEmailAddress where Address = 'noreply_salesforce@illumina.com' limit 1];
    /*
	* Method to send Notification for Cases
	*/
    public static MSTeamsNotificationSender.EmailResult  sendTeamsNotificationForCase(String strEndPoint,String strTemplate,String strQueueName,List<String> lstCaseNumber){
        
        String strBody = 'Dear '+strQueueName+'</br>';
        strBody = strBody + strTemplate +'</br> </br> ';
        for(String strCaseNumber : lstCaseNumber)
        strBody = strBody+'<li><b>'+strCaseNumber+'</b></li>';
        
		
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {strEndPoint};
        mail.setToAddresses(toAddresses);
        mail.setSubject(strTemplate);
        mail.setHtmlBody(strBody);
    	mail.setOrgWideEmailAddressId(owea.Id);
		
       
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
                                 new Messaging.SingleEmailMessage[] { mail });
        
       
          return new EmailResult( results[0],strBody); 
    }

    /**
    *  @author Nitin Sood
    *  @description - Method to send MS teams notification when any batch job fails. This method is called from getTableEmailBodyAndSendNotification
    *  @PARAM :  
    *  @RETURN:  void
    */ 
    public static void sendTeamsNotificationForBatchFailure(String endpoint, String htmlBody, String source, AsyncApexJob objAsyncApexJob ){
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        String reqBody = 'Dear Admin'+',<br>'+'<br>Batch class: ' + source + 'failed. Below is the sumarry and errors: <br>';
		if(objAsyncApexJob != null ){
			reqBody = reqBody+ 'Total batches # ' + objAsyncApexJob.TotalJobItems +'<br> Failed records # '+ objAsyncApexJob.NumberOfErrors +'<br> Date/time '+ objAsyncApexJob.CompletedDate+'<br>';
		}
		reqBody = reqBody +htmlBody + '<br> Thankyou';
        req.setBody('{"text" : "'+reqBody+'"}');
        HttpResponse response =  Test.isRunningTest() ? MockHTTPCalloutMSTNotifications.respondMock('Auth') : new Http().send(req);

    }
   
    /**
    *  @author Nitin Sood
    *  @description - Method to create html table for the failed records in batch class and notification sender method
    *  @PARAM :  
    *  @RETURN:  void
    */ 

    public static void getTableEmailBodyAndSendNotification(Map<Id, String>  mapRecIdToErrors, String source, Id batchProcessId){
		
		if(!mapRecIdToErrors.isEmpty()){
			String htmlBody = '';
			//open table..
			htmlBody = '<table><tr><th>Record Id</th><th>Error Message</th></tr>';
			//iterate over list and output columns/data into table rows...
			if(!mapRecIdToErrors.isEmpty()){
				for(Id recId : mapRecIdToErrors.keySet()){
					String recordId = recId; 
					String error = mapRecIdToErrors.get(recId); 

					htmlBody += '<tr><td>' + recordId + '</td><td>' +error + '</td></tr>';
				}
			}

			//close table...
			htmlBody += '</table>';			

			List<Interface_Parameters__mdt> lstInterfaceParameterobj = [SELECT Id, Endpoint__c, MasterLabel, DeveloperName FROM Interface_Parameters__mdt WHERE DeveloperName =: source ];
			if(lstInterfaceParameterobj != null && !lstInterfaceParameterobj.isEmpty() && lstInterfaceParameterobj[0].Endpoint__c != null && lstInterfaceParameterobj[0].Endpoint__c != '' ){

				AsyncApexJob objAsyncApexJob = NULL;
				if(batchprocessid != null){
					objAsyncApexJob = [SELECT CompletedDate,CreatedDate,JobItemsProcessed,NumberOfErrors,Status,TotalJobItems FROM AsyncApexJob WHERE ID =: batchprocessid ];
				}	

				MSTeamsNotificationSender.sendTeamsNotificationForBatchFailure(lstInterfaceParameterobj[0].Endpoint__c, htmlBody, source, objAsyncApexJob );              
			}
			if(Test.isRunningTest()){
				MSTeamsNotificationSender.sendTeamsNotificationForBatchFailure('test.com', htmlBody, source, null ); 				
			}
		}
    }
      /**************************************************************************************************************************************
        * NAME   : EmailResult
        * DESCRIPTION  : Domain class for v.
        * T
        *  
        *                    
        * @AUTHOR : Nitin Z 
        * @DATE   : 13 -Aug -2024   
        *  
        * MODIFICATION LOG: 
        * --------------------------------------------------------------------------------------------------------------------------------------
        * DEVELOPER                DATE                DESCRIPTION 
        * --------------------------------------------------------------------------------------------------------------------------------------
         Nitin Z                  13 -Aug -2024   

        ****************************************************************************************************************************************/ 

    public class EmailResult{
        public Messaging.SendEmailResult sendEmailResultObject;
        public String  sendEmailBody;
        
            /*
            * @author - Nitin Z
            * @Description-  APPRoceessedData constructor 
            */
        public EmailResult(Messaging.SendEmailResult mSendEmailResultObject,String  mSendEmailBody){
            this.sendEmailResultObject=mSendEmailResultObject;
            this.sendEmailBody=mSendEmailBody;
        }
        
    }
    
}
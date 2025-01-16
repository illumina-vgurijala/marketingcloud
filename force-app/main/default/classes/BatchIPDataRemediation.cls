/**************************************************************************************************************************************
* NAME   : BatchIPDataRemediation
* DESCRIPTION  : Domain class for v.
* Test Class- TestBatchIPDataRemediation.cls
*  
*                    
* @AUTHOR : Nitin Z 
* @DATE   : 6 -Dec -2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Nitin Z                 6 -Dec -2024    

****************************************************************************************************************************************/ 


global class BatchIPDataRemediation implements Database.Batchable<sObject>, Database.Stateful {
   
    List< IPDataRemediationHelper.MockHistoryRecord> listData= new List< IPDataRemediationHelper.MockHistoryRecord>();
    List<String> fieldsToFilter= new List<String>();
    List<String> csvLinesSuccess = new List<String>();

	/*
    * @author - Nitin Z
    * @Description-  constructor
    */
    
    public BatchIPDataRemediation(String field){
        fieldsToFilter.add(field);
        csvLinesSuccess.add('Id,'+field+ ', oldValue, isSuccess, Error Message'); 
    }
    
    /*
    * @author - Nitin Z
    * @Description-  start method
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {

         disableAllValidation();
       
		 DateTime createdDateThreshold = DateTime.newInstance(2023, 11, 10, 0, 0, 0);

         String query = 'SELECT Field, OldValue, NewValue, CreatedDate, ParentId ' +
                   'FROM SVMXC__Installed_Product__History ' +
                   'WHERE Field IN :fieldsToFilter ' +
                   'AND CreatedDate >= :createdDateThreshold ' +
                   'ORDER BY CreatedDate DESC';
              
      return Database.getQueryLocator(query);

    }
    
    /*
    * @author - Nitin Z
    * @Description-  execute method
    */
    global void execute(Database.BatchableContext bc, List<SVMXC__Installed_Product__History > scope) {

        
          for(SVMXC__Installed_Product__History iphistory : (List<SVMXC__Installed_Product__History>)scope){
            
            if(iphistory.newValue==null && iphistory.oldValue!=null){
                listData.add(new IPDataRemediationHelper.MockHistoryRecord(iphistory.field,iphistory.oldValue,iphistory.newValue,iphistory.parentId));
            }
          }
          csvLinesSuccess.addAll(IPDataRemediationHelper.processHistoryRecords(listData,fieldsToFilter[0]));
    }

 
    /*
    * @author - Nitin Z
    * @Description-  finishs method
    */
    global void finish(Database.BatchableContext bc) {
      System.debug('BatchADDataRemediation  ' +JSON.serialize(csvLinesSuccess));

        if(Test.isRunningTest()){
            csvLinesSuccess.add('TEst,test');
        }       
       sendEmailWithCsv(String.join(csvLinesSuccess, '\n'));
    }
    
    /*
    * @author - Nitin Z
    * @Description-  method to send email
    */
     private   void sendEmailWithCsv(String csvContentSuccess) {
        // Create the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> toAddresses = System.label.DataRedemiationEmail.split(',');
 

        // Set recipient and subject
        email.setToAddresses(toAddresses ); // Replace with recipient's email
        email.setSubject('Exported CSV File');
        email.setPlainTextBody('Please find the attached CSV file. For data remediation for field '+fieldsToFilter[0]);

        // Create the email attachment
        Messaging.EmailFileAttachment attachmentSuccess = new Messaging.EmailFileAttachment();
        attachmentSuccess.setFileName('success '+ String.valueOf(Date.today()) +' ' +this.fieldsToFilter[0]+ '.csv');
        attachmentSuccess.setBody(Blob.valueOf(csvContentSuccess)); // Attach CSV content
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {attachmentSuccess });
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
     /*
    * @author - Nitin Z
    * @Description-  method to disable all validation
    */
    private void disableAllValidation(){
         
        	cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        	setting.Bypass_All_Validations__c = true;
          setting.Bypass_All_Triggers__c = true;
          setting.Bypass_All_Flows__c = true;
        	upsert setting;
          
    }
}
/***************************************************************************************************************************************
* NAME         : UpdateWorkOrderAdditionalDetailBatch
* DESCRIPTION  :  UpdateWorkOrderAdditionalDetailBatch.
*                    
* @AUTHOR : Abhishek Yadav
* @DATE   : 24-Sept-2024
* @testclasses : UpdateWorkOrderAdditionalDetailBatchTest
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav            24-Sept-2024           Initial Version.
****************************************************************************************************************************************/
global class UpdateWorkOrderAdditionalDetailBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    // Variable to store the count of records processed
    private final String EMAILADDRESS;
    private final Integer NOOFDAYS;
    private Integer totalRecord = 0;
    private final Integer stringCount;
    // List to store failed records using the wrapper
    private List<FailureRecordWrapper> failureRecords = new List<FailureRecordWrapper>();

    /**
    *  @author Abhishek
    *  @description - wrapper class
    *                 
    **/
    public class FailureRecordWrapper {
        public Id recordId { get; set; }
		public String recordName { get; set; }
        public String errorMessage { get; set; }
        
    /**
    *  @author Abhishek
    *  @description - wrapper Constructor class
    *                 
    **/
        public FailureRecordWrapper(Id recordId, String recordName, String errorMessage) {
            this.recordId = recordId;
            this.recordName = recordName;
            this.errorMessage = errorMessage;
        }
    }
    /**
    *  @author Abhishek
    *  @description - Constructor
    *                 
    **/
    public UpdateWorkOrderAdditionalDetailBatch(String emailAddress , Integer numberOfDays) {
        this.EMAILADDRESS = emailAddress;
        this.NOOFDAYS = numberOfDays == 0 || numberOfDays == null ? 730 : numberOfDays;
        getTotalRecord();
        this.stringCount = 180;
    }
    /**
    *  @author Abhishek
    *  @description - get total record count
    *                 
    **/
    public void getTotalRecord() {
        // Ensure NOOFDAYS is an integer
        String query = 'SELECT COUNT(Id) FROM SVMXC__Service_Order__c ' + 
            'WHERE CreatedDate = LAST_N_DAYS:' + String.valueOf(this.NOOFDAYS) + 
            ' AND SVMXC__Order_Status__c IN (\'Closed\', \'Canceled\', \'Completed\')';
        
        // Execute the dynamic query
        List<AggregateResult> result = Database.query(query);
        
        // Check if the result list is not empty before accessing it
        if (!result.isEmpty()) {
            this.totalRecord = (Integer)result[0].get('expr0');
        } else {
            this.totalRecord = 0; // Handle case where there are no records
        }
    }
    /**
    *  @author Abhishek
    *  @description - get Work Order Data
    *                 
    **/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, Additional_Detail__c, SVMXC__Problem_Description__c, Evaluation__c, SVMXC__Work_Performed__c, Verification_Result__c, ' +
            'English_Translation_Additional_Detail__c, English_Translation_Description__c, English_Translation_Evaluation__c, English_Translation_Work_Performed__c, English_Translation_Verification_Result__c ' +
            'FROM SVMXC__Service_Order__c ' +
            'WHERE CreatedDate = LAST_N_DAYS:'+ String.valueOf(this.NOOFDAYS) +
            ' AND SVMXC__Order_Status__c IN (\'Closed\', \'Canceled\', \'Completed\')';
        return Database.getQueryLocator(query);
    }
    /**
    *  @author Abhishek
    *  @description - update Addition Details and English Translation Additional Detail
    *                 
    **/
    global void execute(Database.BatchableContext bc, List<SVMXC__Service_Order__c> ssOlist) {
        try {
            List<SVMXC__Service_Order__c> updateSsoList = new List<SVMXC__Service_Order__c>();
            for (SVMXC__Service_Order__c sso : ssOlist) {
                if (sso.Additional_Detail__c == null) {
                    sso.Additional_Detail__c = getAdditionalDetails(sso);
                }
                if (sso.English_Translation_Additional_Detail__c == null) {
                    sso.English_Translation_Additional_Detail__c = getEnglishAdditionalDetails(sso);
                }
                sso.SVMXC__Problem_Description__c = '';
                sso.Evaluation__c = '';
                sso.SVMXC__Work_Performed__c = '';
                sso.Verification_Result__c = '';
                sso.English_Translation_Description__c = '';
                sso.English_Translation_Evaluation__c = '';
                sso.English_Translation_Work_Performed__c = '';
                sso.English_Translation_Verification_Result__c = '';
                updateSsoList.add(sso);
            }
            if(updateSsoList != null && !updateSsoList.isEmpty()) {
                updateWorkOrderRecord(updateSsoList);
            }
        } catch (Exception e) {
            failureRecords.add(new FailureRecordWrapper('', '', e.getMessage()));
        }
    }
    private static string getAdditionalDetails(SVMXC__Service_Order__c sso) {
        String additionalDetails = '';
        if(sso.SVMXC__Problem_Description__c != null) {
            additionalDetails += 'Description: ' + sso.SVMXC__Problem_Description__c + '\n';
        }
        if(sso.Evaluation__c != null) {
            additionalDetails += 'Evaluation: ' + sso.Evaluation__c + '\n';
        }
        if(sso.SVMXC__Work_Performed__c != null) {
            additionalDetails += 'Work Performed: ' + sso.SVMXC__Work_Performed__c + '\n';
        }
        if(sso.Verification_Result__c != null) {
            additionalDetails += 'Verification Result: ' + sso.Verification_Result__c;

        }
        return additionalDetails;
    }
    private static string getEnglishAdditionalDetails(SVMXC__Service_Order__c sso) {
        String engAdditionalDetails = '';
        if(sso.English_Translation_Description__c != null) {
            engAdditionalDetails += 'English translation Description: ' + sso.English_Translation_Description__c + '\n';
        }
        if(sso.English_Translation_Evaluation__c != null) {
            engAdditionalDetails += 'English translation Evaluation: ' + sso.English_Translation_Evaluation__c + '\n';
        }
        if(sso.English_Translation_Work_Performed__c != null) {
            engAdditionalDetails += 'English translation Work Performed: ' + sso.English_Translation_Work_Performed__c + '\n';
        }
        if(sso.English_Translation_Verification_Result__c != null) {
            engAdditionalDetails += 'English translation Verification: ' + sso.English_Translation_Verification_Result__c;
      }
      return engAdditionalDetails;
    }            

    private void updateWorkOrderRecord(List<SVMXC__Service_Order__c> updateSsoList) {
        cs_Apex_Settings__c apexSetting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        apexSetting.Bypass_All_Validations__c = true;
        apexSetting.Bypass_All_Triggers__c = true;
        apexSetting.Bypass_All_Flows__c = true;
        upsert apexSetting;
        
        // Use Database.update to capture save results
        Database.SaveResult[] saveResults = Database.update(updateSsoList, false);
        // Check for errors in the save results
        for (Integer i = 0; i < saveResults.size(); i++) {
            if (!saveResults[i].isSuccess()) {
                // Get the error message
                String errorMessage = saveResults[i].getErrors()[0].getMessage();
                // Truncate the error message to 180 characters if it exceeds that limit
                if (errorMessage.length() > this.stringCount) {
                    errorMessage = errorMessage.substring(0, this.stringCount);
                }
                // Add the failure record with the truncated error message
                failureRecords.add(new FailureRecordWrapper(updateSsoList[i].Id, updateSsoList[i].Name, errorMessage));
            }
        }
    }
    /**
    *  @author Abhishek
    *  @description - send email for success and failure
    *                 
    **/
    global void finish(Database.BatchableContext bc) {
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        List<String> emailAddressList = new List<String>();
		// Create the CSV content
        String csvContent = 'Record Id, WorkOrder Number, Error Message\n';
        for (FailureRecordWrapper failure : failureRecords) {
            csvContent += failure.recordId + ',' + failure.recordName + ',' + failure.errorMessage + '\n';
        }
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('FailedRecords.csv');
        efa.setBody(Blob.valueOf(csvContent));
        efa.setContentType('text/csv');
        attachments.add(efa);
        // Send an email when the batch process finishes
        String subject = 'Batch Process Completed';
        String body = 'The batch process has completed.\n' +
            'Total records processed: ' + this.totalRecord + '\n' +
            'Please find the Attachment:\n';
        
        // Set the email details
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        emailAddressList = this.EMAILADDRESS.contains(',') ? this.EMAILADDRESS.split(',') : new List<String>{this.EMAILADDRESS};
        email.setToAddresses(emailAddressList);
        email.setSubject(subject);
        email.setPlainTextBody(body);
        email.setFileAttachments(attachments);
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}
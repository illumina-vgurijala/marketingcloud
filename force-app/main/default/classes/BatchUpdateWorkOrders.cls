/**
*    @author: prashanth 
*    @date:   17-Feb-2022
*    @description:  Batch Class to update product family & Repair protocal on open work orders.This will be a one time batch and will be deleted once we complete the data remediation.DCP-51587
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*             Prashanth                   17-Feb-2022           Initial version      
*/
global With Sharing class BatchUpdateWorkOrders extends ilib_ScheduleAndBatch implements Database.Batchable<sObject>, Database.Stateful{
    global static List<String> lstClosedStatuses = new List<String>{'Completed','Closed','Canceled','Closed-Duplicate'};
    global Map<Id, String> errorMap  = new Map<Id, String>();
    
    /**
    * method: start
    * Params: Database.BatchableContext
    * Description: queries for the open work orders.
    * return: Database.QueryLocator
    */
    global override Database.QueryLocator start(Database.BatchableContext objBatchableContext){
        
        String stringFinalQuery = 'SELECT Id,SVMXC__Product__c,SVMXC__Product__r.Family,Repair_protocols__c,Product_Family__c from SVMXC__Service_Order__c where SVMXC__Order_Status__c Not in:lstClosedStatuses AND Product_Family__c = NULL';
        System.debug('stringFinalQuery--:'+stringFinalQuery);
        return Database.getQueryLocator(stringFinalQuery);
    }
    /**
    * method: execute
    * Params: Database.BatchableContext , List<sObject> lstRecords
    * Description: execute method for updating the work orders.
    * return: void
    */
    global override void execute(Database.BatchableContext objBatchableContext, List<sObject> lstRecords){
		List<SVMXC__Service_Order__c> lstWOsToUpdate = new List<SVMXC__Service_Order__c>();
        for(SVMXC__Service_Order__c objWO: (List<SVMXC__Service_Order__c>)lstRecords){
            objWO.Product_Family__c=objWO.SVMXC__Product__r.Family;//Update product family
            if(objWO.Product_Family__c == null || (objWO.Product_Family__c != null && (objWO.Product_Family__c=='NextSeq - NSQ - Dx' || objWO.Product_Family__c=='MiSeq - MSQ - Dx'))){
                objWO.Repair_protocols__c = '';
            } else {
				objWO.Repair_protocols__c = 'Not applicable for this instrument';
			}
			lstWOsToUpdate.add(objWO);
        }
		if(!lstWOsToUpdate.isEmpty()){
			List<Database.SaveResult> lstSR = Database.update(lstWOsToUpdate, false);
            System.debug('lstSR--:'+lstSR);
            Integer index = 0;
            for(Database.SaveResult dsr : lstSR){
                if(!dsr.isSuccess()){
                    String errMsg = dsr.getErrors()[0].getMessage();
                    errorMap.put(lstWOsToUpdate[index].Id, errMsg);
                }
                index++;
            }          
		}
            
    }
    /**
    * Method: finish
    * Params: Database.BatchableContext
    * Description: This is a mandatory method for batchable interface
    * return: void
    */
    global override void finish(Database.BatchableContext objBatchableContext){
        /*This is mandatory method for batchable interface*/
        System.debug('objBatchableContext--:'+objBatchableContext);
        processFailureRecords(errorMap, objBatchableContext.getJobId());
    }
    /**
     * Method: processFailureRecords
     * Description: send email with the failure records info
     * params:Map<Id, String> errorMap
     * return: void
     */
    public void processFailureRecords(Map<Id, String> errorMap, Id jobId){
        //Send an email to the User after your batch completes 
        if (!errorMap.isEmpty()) {
            AsyncApexJob a = [SELECT id, ApexClassId,JobItemsProcessed, TotalJobItems,NumberOfErrors, CreatedBy.Email FROM AsyncApexJob WHERE id =: jobId];
            String body = 'Your batch job ' +'BatchUpdateWorkorders ' +'has finished. \n' +'There were ' +errorMap.size() +' errors. Please find the error list attached to the Case.';

            // Creating the CSV file
            String finalstr = 'Id, Error \n';
            String subject = 'Work Order - Apex Batch Error List';
            String attName = 'Work Order Errors.csv';
            for (Id id: errorMap.keySet()) {
                string err = errorMap.get(id);
                string recordString = '"' + id + '","' + err + '"\n';
                finalstr = finalstr + recordString;
            }

            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            // Create the email attachment    
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstr));

            // Sets the paramaters of the email
            email.setSubject(subject);
            email.setToAddresses(new String[] {a.CreatedBy.Email});
            email.setPlainTextBody(body);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});

            // Sends the email
            if(!Test.isRunningTest()){
                Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }
        }
    }
}
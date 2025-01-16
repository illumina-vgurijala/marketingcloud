/* 
*Description: Batch class to update to send Tool Calibration Due notification to the prefered technician on location
* @author Sravan
*/
public with sharing class BatchSendToolCalibrationDueNotifications extends ilib_ScheduleAndBatch implements Schedulable,Database.Stateful {
    
    private final string regionName;
    private  string ameaRegionName = 'AMEA';
    /*
     * Default constructor
     */ 
    public BatchSendToolCalibrationDueNotifications(){
        this.regionName='';
    }
    /*
     * Constructor with parameter
     */ 
    public BatchSendToolCalibrationDueNotifications(string regionName){
        this.regionName = regionName;
    }
    
    
    /*
*  Description: Execute method to be called when class is scheduled
**/
    public override void execute(SchedulableContext ctx)
    {
        BatchSendToolCalibrationDueNotifications objBatch=new BatchSendToolCalibrationDueNotifications(regionName);
        Database.executebatch(objBatch);
    }
    
    /*
* Description: Fetch required installed products to process
*/
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('<---Started--->');
        string strQuery;
        if(regionName== ameaRegionName ){
            strQuery = 'SELECT Id,Name,SVMXC__Serial_Lot_Number__c,SVMXC__Product__r.Name,SVMXC__Site__c,SVMXC__Site__r.Name,SVMXC__Site__r.SVMX_PS_Preferred_Technician__c,SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Name, SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email, Tool_Calibration_Due_Date__c,No_of_Days_till_Expiry__c FROM SVMXC__Installed_Product__c WHERE Tool_Calibration_Due_Date__c !=null AND SVMXC__Site__c !=null AND SVMXC__Site__r.SVMX_PS_Preferred_Technician__c !=null AND Service_Product_Type__c =\'Approved Tool- Calibrated\' AND SVMXC__Status__c =\'Calibrated\' AND (No_of_Days_till_Expiry__c=1 OR No_of_Days_till_Expiry__c =15) AND SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.Region__c=:regionName';
        }else{
            strQuery = 'SELECT Id,Name,SVMXC__Serial_Lot_Number__c,SVMXC__Product__r.Name,SVMXC__Site__c,SVMXC__Site__r.Name,SVMXC__Site__r.SVMX_PS_Preferred_Technician__c,SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Name, SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email, Tool_Calibration_Due_Date__c,No_of_Days_till_Expiry__c FROM SVMXC__Installed_Product__c WHERE Tool_Calibration_Due_Date__c !=null AND SVMXC__Site__c !=null AND SVMXC__Site__r.SVMX_PS_Preferred_Technician__c !=null AND Service_Product_Type__c =\'Approved Tool- Calibrated\' AND SVMXC__Status__c =\'Calibrated\' AND (No_of_Days_till_Expiry__c='+Label.CalibratedToolDueToday+' OR No_of_Days_till_Expiry__c ='+Label.CalibratedToolDue14Days+') AND SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.Region__c=:regionName';
        }
        return Database.getQueryLocator(strQuery);
    }
    /*
* Process the qualified records as batchs
*/
    public void execute(Database.BatchableContext bc, List<SVMXC__Installed_Product__c> records) { 
        system.debug('<---Executing--->');
        system.debug('IP Records LIST -> '+records.size());
        Map<String, Id> mapWhatId = new Map<String, Id>();
        Map<String, String> mapRecipientNames = new Map<String, String>();
        Map<string,List<SVMXC__Installed_Product__c>> mapTechnicianToIP = new Map<string,List<SVMXC__Installed_Product__c>>();
        Map<string,List<SVMXC__Installed_Product__c>> mapTechnicianToIP14Days = new Map<string,List<SVMXC__Installed_Product__c>>();
        
        for(SVMXC__Installed_Product__c iPRecord : records){
            // Get IPs which are expiring in 14 days also 15 days for AMEA region
            if(iPRecord.No_of_Days_till_Expiry__c== integer.valueOf(Label.CalibratedToolDue14Days) || iPRecord.No_of_Days_till_Expiry__c== integer.valueOf(Label.CalibratedToolDue14Days)+1){
                if(mapTechnicianToIP14Days.containsKey(iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email)){
                    mapTechnicianToIP14Days.get(iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email).add(iPRecord);
                }else{
                    mapTechnicianToIP14Days.put(iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email,new List<SVMXC__Installed_Product__c>{iPRecord});  
                }
            }else{ // Get IPs which are expiring today
                if(mapTechnicianToIP.containsKey(iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email)){
                    mapTechnicianToIP.get(iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email).add(iPRecord);
                }else{
                    mapTechnicianToIP.put(iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email,new List<SVMXC__Installed_Product__c>{iPRecord});  
                }  
            }
            mapRecipientNames.put(iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email,iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Name);
            mapWhatId.put(iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__r.Email,iPRecord.SVMXC__Site__r.SVMX_PS_Preferred_Technician__c);            
        }
        system.debug('IP Records Due is Today--> '+mapTechnicianToIP.keySet() +' ---> '+mapTechnicianToIP.values().size());
        system.debug('IP Records Due is in 14days--> '+mapTechnicianToIP14Days.keySet() +' ---> '+mapTechnicianToIP14Days.values().size());
        system.debug('Prefered Tech Names--> '+mapRecipientNames.keySet() +' ---> '+mapRecipientNames.values().size());
        Messaging.Email[] emailList = new Messaging.Email[0];
        // Build the email for IPs which are expiring Today or in 14 days        
        if(!mapRecipientNames.isEmpty()){            
            //Build email for IPs expiring today
            if(!mapTechnicianToIP.isEmpty()){              
                buildEmailList(mapTechnicianToIP,mapRecipientNames,mapWhatId,Label.SendToolCalibratedEmailNotificationSubjectToday,Label.SendToolCalibratedEmailNotificationBodyTextToday, Label.SendToolCalibratedEmailNotificationEndText,emailList);  
            }
            //Build email for IPs expiring in 14 days            
            if(!mapTechnicianToIP14Days.IsEmpty()){                
                buildEmailList(mapTechnicianToIP14Days,mapRecipientNames,mapWhatId,Label.SendToolCalibratedEmailNotificationSubject14Days,Label.SendToolCalibratedEmailNotificationBodyText14Days, Label.SendToolCalibratedEmailNotificationEndText,emailList);         	   
            }            
        }
        // Send Emails in one go
        if(!emailList.isEmpty()){            
            Messaging.sendEmail(emailList, false);
        }
    }
    /*
     * To build email structure
     */
    private void buildEmailList(Map<string,List<SVMXC__Installed_Product__c>> mapIPtech,Map<String, String> mapRecipientNames,Map<String, Id> mapWhatId,String subject,String bodyText, String bodyEndText,Messaging.Email[] emailList){
        String htmlBody = '';
        String htmlTableHeader = '<table border="1" style="border-collapse: collapse"><tr style="background-color:#dcdcdc;font-family: Arial;"><th><i>Location</i></th><th><i>Installed Product ID</i></th><th><i>Product</i></th><th ><i>Serial/Lot Number</i></th><th><i>Tool Calibration Due date</i></th></tr>';
        // Loop IP records which has due Today
        for(string technician : mapIPtech.keySet()) {
            htmlBody ='<p style="font-family: Arial;"><i>Dear '+mapRecipientNames.get(technician)+'</i></p>';
            htmlBody += '<p style="font-family: Arial;"><i>'+bodyText+'</i></p>'; 
            htmlBody += htmlTableHeader;
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();  
            for(SVMXC__Installed_Product__c ipRecord : mapIPtech.get(technician)){
                htmlBody += '<tr><td><a href="'+URL.getSalesforceBaseUrl().toExternalForm() +'/' + ipRecord.SVMXC__Site__c+'">' + ipRecord.SVMXC__Site__r.Name + '</a></td><td><a href="'+URL.getSalesforceBaseUrl().toExternalForm() +'/' + ipRecord.id+'">' + ipRecord.Name + '</a></td><td>' + ipRecord.SVMXC__Product__r.Name + '</td><td>' + ipRecord.SVMXC__Serial_Lot_Number__c + '</td><td>' + string.valueOf(ipRecord.Tool_Calibration_Due_Date__c) + '</td></tr>';
            }
            htmlBody += '</table>';
            htmlBody += '<p style="font-family: Arial;"><i>'+bodyEndText+'</i></p>';
            message.setSubject(subject);                 
            message.setHtmlBody(htmlBody);
            message.setToAddresses(new String[] {technician});
            message.setWhatId(mapWhatId.get(technician)); 
            message.setSaveAsActivity(true);
            emailList.add(message);
        }
    }   
    
    
    /*
* Finish method to send notification to Illumina Admin user if batch fails
*/
    public override void finish(Database.BatchableContext bc) {
        system.debug('<---Fnished--->');
        AsyncApexJob apxJob = [SELECT Id, Status, NumberOfErrors, ExtendedStatus,CompletedDate FROM AsyncApexJob WHERE Id =:bc.getJobId()];
        if(apxJob!=null && (apxJob.NumberOfErrors>0 || test.isRunningTest())){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setSubject('BatchSendToolCaloibrationDueNotifications Failure');                 
            message.setPlainTextBody('BatchSendToolCaloibrationDueNotifications is failed. No. of batches: '+ apxJob.NumberOfErrors+' Completed on: '+apxJob.CompletedDate);
            message.setToAddresses(new string[] {Label.SFDC_Service_Account_Email_Id});
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {message} , false);   
        }
    }    
}
/*@ author       : Maruthi B
* @ date         : 17-02-2022
* @ Description  : PM-36: Batch to create Task for Non-Complaint Accounts
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
global with sharing class BatchToCreateTaskOnAccount extends ilib_ScheduleAndBatch {

    private static final String LOG_TITLE = 'BatchToCreateTaskOnAccount';
    private final static String STATUS = 'Open';
    private final static String SUBJECT = 'Action Required: Identify contacts to receive Product Notifications';
    private final static String PRIORITY = 'High';
    private final static String DESCRIPTION = 'The referenced Account has been identified as being out of compliance with our Regulatory and Quality requirements and action is needed to ensure contacts are identified in your account to receive important product notifications. As the Account Owner, your responsibility is to review and take the necessary action to meet the minimum number of Contacts identified to receive product notifications. Please navigate to the Contact, assign the Regulatory/Quality Role on the Account Contact Relationship and select a Product Notification Categories value. In most cases, two Contacts need to be identified with the \'Regulatory/Quality\' Role AND \'Default (All)\' Product Notification Categories to ensure that we can effectively communicate with our customers in the event of an urgent product notification.';


    /**
    * @author Maruthi B
    * @date   17-02-2022
    * @description  Overriding execute method for scheduled job
    */
    public override void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchToCreateTaskOnAccount());
    }

    /*
    * @author Maruthi B
    * @date   17-02-2022
    * @description  start method override
    *
    */
    global override Database.QueryLocator start(Database.BatchableContext bc) {                         
        return Database.getQueryLocator('SELECT Id, R_Q_Contact_Compliant__c, OwnerId FROM Account WHERE R_Q_Contact_Compliant__c = \'Non Compliant\'');
    }

    /*
    * @author Maruthi B
    * @date   17-02-2022
    * @description  execute method override
    *
    */
    global override void execute(Database.BatchableContext bc, List<sObject> scope) {     
        ilib_LogEvent.setTitle(LOG_TITLE);   
        ilib_LogEvent.push(LOG_TITLE +'.batchToCreateTask');  
        try { 
            ilib_LogEvent.message('scope-->'+scope);            
            Set<Id> accIdSet = new Set<Id>(UtilsCollection.getSetOfIds(scope));
            List<Task> listTask = new TaskSelector().getAllTaskByWhoIdWithStatus(accIdSet,STATUS);                        
            ilib_LogEvent.message('listTask-->'+listTask); 
            
            Map<Id,Set<Id>> mapAccIdToOwnerId = new Map<Id,Set<Id>>();
			Set<Id> setOwnerIds = new Set<Id>();
            for(Task tskTemp : listTask) {
                if(!(tskTemp.Subject).equals(SUBJECT)) {
                    continue;
                }
				if(mapAccIdToOwnerId.containsKey(tskTemp.WhatId)) {					
					setOwnerIds = mapAccIdToOwnerId.get(tskTemp.WhatId);					          
					setOwnerIds.add(tskTemp.OwnerId);
					mapAccIdToOwnerId.put(tskTemp.WhatId, setOwnerIds);
				} else {
					setOwnerIds.add(tskTemp.OwnerId);
					mapAccIdToOwnerId.put(tskTemp.WhatId, setOwnerIds);
				}                
            }                        
            ilib_LogEvent.message('mapAccIdToOwnerId-->'+mapAccIdToOwnerId);            
            Datetime dueDateTemp = convertToLocalTime(Datetime.now() + 2);
            Date dueDate = date.newinstance(dueDateTemp.year(), dueDateTemp.month(), dueDateTemp.day());
            Datetime remindDateTemp = convertToLocalTime(Datetime.now() + 1);
            Datetime remindDate = Datetime.newinstance(remindDateTemp.year(), remindDateTemp.month(), remindDateTemp.day(), 10, 00, 00);
            List<Account> accList = (List<Account>) scope;
            List<Task> createTaskList = new List<Task>(); 
            for(Account accObj: accList) {   
                ilib_LogEvent.message('condition1-->'+mapAccIdToOwnerId.containsKey(accObj.Id));                         
                ilib_LogEvent.message('condition2-->'+mapAccIdToOwnerId.get(accObj.Id));                         
                if(mapAccIdToOwnerId.containsKey(accObj.Id) && mapAccIdToOwnerId.get(accObj.Id).contains(accObj.OwnerId)) {
                    continue;                    
                }                  
                Task tskObj = new Task();
                tskObj.Subject = SUBJECT;
                tskObj.OwnerId = accObj.OwnerId;                                                            
                tskObj.ActivityDate = dueDate;
                tskObj.Priority = PRIORITY;
                tskObj.Status = STATUS;
                tskObj.IsReminderSet = True;                    
                tskObj.ReminderDateTime = remindDate;                    
                tskObj.Description = DESCRIPTION;
                tskObj.WhatId = accObj.Id;

                createTaskList.add(tskObj);
            }            
            ilib_LogEvent.message('createTaskList-->'+createTaskList);
            if(!createTaskList.isEmpty()) {   
                cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
                cs.Bypass_All_Validations__c = true;
                cs.Bypass_All_Triggers__c=true;
                cs.Bypass_All_Flows__c=true;
                upsert cs cs_Apex_Settings__c.Id;                             
                List<Database.SaveResult> lstSaveErrors = Database.insert(createTaskList, false);
                cs.Bypass_All_Validations__c = false;
                cs.Bypass_All_Triggers__c=false;
                cs.Bypass_All_Flows__c=false;
                upsert cs cs_Apex_Settings__c.Id;
                if(!lstSaveErrors.isEmpty()) { 
                    ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
                }
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }catch(Exception e) {
            ApexExceptions.emit(e, 'BatchToCreateTaskOnAccount', scope);
        }
    }

    /*
    * @author Maruthi B
    * @date   28-02-2022
    * @description  To get the local Time
    *
    */
    private Datetime convertToLocalTime(Datetime gmtTarget) {
        Integer offset = UserInfo.getTimezone().getOffset(gmtTarget);        
        return gmtTarget.addSeconds(offset/1000);
   
   }

   /**
    * @author Maruthi
    * @date   28-Feb-2022
    * @description   Overriding finish method for batch
    */
    global override void finish(Database.BatchableContext bc) {

    }
}
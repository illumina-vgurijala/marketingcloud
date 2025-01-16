/**
* @ author       : Saddam 
* @ date         : 15-Feb-2022
* @ Description  : PM-33 Data correction
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Saddam              23-Mar-2022                 Initial version
*/
public with sharing class BatchForAccountRQCompliant extends ilib_ScheduleAndBatch {
   
    private static final String LOG_TITLE = 'BatchForAccountRQCompliant';
    
    /**
    * @author Saddam
    * @date   23-Mar-2022
    * @description  Overriding execute method for scheduled job
    */
    public override void execute(SchedulableContext sc) {
        String strBatchId; 
        strBatchId=Database.executeBatch(new BatchForAccountRQCompliant());
        ilib_LogEvent.message('strBatchId===> '+strBatchId);    
    }

    /**
    * @author Saddam
    * @date   23-Mar-2022
    * @description  Overriding start method for batch
    */
    public override Database.QueryLocator start(Database.BatchableContext bc) {            
        ilib_LogEvent.push(LOG_TITLE +'Database.QueryLocator');  
        Database.QueryLocator res = Database.getQueryLocator('SELECT Id,R_Q_Contact_Compliant__c FROM Account');
        ilib_LogEvent.message('res===> '+res);
        ilib_LogEvent.pop();
        return res;
    }
    
    /**
    * @author Saddam
    * @date   23-Mar-2022
    * @description  Overriding execute method for batch
    */
    public override void execute(Database.BatchableContext bc, List<sObject> lstRecords)  { 
        ilib_LogEvent.push(LOG_TITLE +'BatchForAccountRQCompliant.execute');  
        ilib_LogEvent.message('lstRecords===> '+lstRecords);
        try{
            ilib_LogEvent.message('lstRecords--'+lstRecords);
            List<Account> acnList = (List<Account>)lstRecords;
            Accounts.updateRQConEligibleAccount(acnList);
            ilib_LogEvent.pop();
        }
        catch(Exception e){
            ApexExceptions.emit('BatchForAccountRQCompliant', e);
            throw e;
        }

    }
    

    /**
    * @author Saddam
    * @date   15-Feb-2022
    * @description   Overriding finish method for batch
    */
    public override void finish(Database.BatchableContext bc){
        ilib_LogEvent.push(LOG_TITLE +'BatchForAccountRQCompliant.finish');  
        ilib_LogEvent.message('NO Logic Required===>');
        ilib_LogEvent.pop();

    }


}

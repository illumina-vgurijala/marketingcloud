/****************************************************************************************************************************************
* NAME         : ilib_Queueablethread
* DESCRIPTION  : Base class used to log the QueueableUtilJob objects to a List for later execution.
*                Also used to update Process statues to DB        
*
* MODIFICATION LOG:  
* -------------------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------------------------------
*  Saddam                 10-oct-22           Codescan Fix Added Comments for methods.
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
 
public without sharing class ilib_Queueablethread implements Queueable {

    //List to hold QueueableUtilJob objects  clubbed for execution on a single thread. 
    public List<ilib_QueueableJobWrapper> lstQueueableJobs = new List<ilib_QueueableJobWrapper>();

    //Map to update the QLI's 
    public static map<Id,Queueable_Log_Item__c> qliMap;

    //To maintain the number of retry count
    Integer retryLimit = 3;
    public string tid;

    //to hold Log Item objects to updated process status to DB.
    List<Queueable_Log_Item__c> lstofQueueableLogItem = null;

    //Indentifier to be logged on DB for identifying the parent Sync process 
    public String logIdentifier;

    //used for Interface Logs 
    public Id interfaceLogId;
    
    /*
    *  @description  : Constructor Method.
    * Param          : String,Id
    */
    public ilib_Queueablethread(String logIdentifier,Id interfaceLogId)
    {
        this.logIdentifier = logIdentifier + '_' + UserInfo.getName() + '_' + DateTime.now();
        this.interfaceLogId = interfaceLogId;
        this.tid = ilib_LogEvent.getTransactionId();
    }

    /*
    *  @description  : Constructor Method.
    * Param          : String 
    */
    public ilib_Queueablethread(String logIdentifier)
    {
        this.logIdentifier = logIdentifier + '_' + UserInfo.getName() + '_' + DateTime.now();
        this.tid = ilib_LogEvent.getTransactionId();
    }
    /*
    *  @description  : method to log/combine one or more Queuable task to lstQueableJobs on Instance of QueueableUtilBase  
    * Param          : Queueable,String,string
    */
    public void logAndQueue(Queueable objJob, String className, String methodname)
    {
        lstQueueableJobs.add(new ilib_QueueableJobWrapper(objJob, className, methodname));
    }

    /*
    *  @description  : method to be executed once the Job is Enqueued using Sysytem.enque from "QueueableUtil"
    * Param          : QueueableContext
    */
    public void execute(QueueableContext context)
    {
        
        set<Id> qliIds = new set<Id>();
        
        if (lstofQueueableLogItem == null)
            lstofQueueableLogItem = new List<Queueable_Log_Item__c>();

        for(ilib_QueueableJobWrapper objJob : lstQueueableJobs){
            qliIds.add(objJob.queueableLogItemId);
            }

         Map<Id,Queueable_Log_Item__c> mapQueueLogItem = new Map<Id,Queueable_Log_Item__c>([SELECT id,Satus__c,Retry_Count__c 
                                                                                    FROM Queueable_Log_Item__c WHERE ID IN:qliIds]);

        for (ilib_QueueableJobWrapper objJob : lstQueueableJobs) {   
            if(mapQueueLogItem.containsKey(objJob.queueableLogItemId) && (mapQueueLogItem.get(objJob.queueableLogItemId).Retry_Count__c>= retryLimit || 
                    mapQueueLogItem.get(objJob.queueableLogItemId).Satus__c =='Success')){    
                continue;
            }
            try
            {
                objJob.queueableJob.execute(context);
                lstofQueueableLogItem.add(ilib_QueueableLogger.updateQueueableLogItems(objJob, context.getJobId(), null,null)); 
            }catch (Exception ex) {
                system.debug('Retry Count**'+mapQueueLogItem.get(objJob.queueableLogItemId).Retry_Count__c);
                lstofQueueableLogItem.add(ilib_QueueableLogger.updateQueueableLogItems(objJob, context.getJobId(), ex,mapQueueLogItem.get(objJob.queueableLogItemId).Retry_Count__c));
                system.debug('lstofQueueableLogItem***'+lstofQueueableLogItem);
                qliMap = prepareMapOfQLI(lstofQueueableLogItem);
                throw ex;
            } 
        }

        //Commiting Process logs to DB
        if (lstofQueueableLogItem != null && !lstofQueueableLogItem.IsEmpty()) {
            system.debug('lstofQueueableLogItem**'+lstofQueueableLogItem);
            qliMap = prepareMapOfQLI(lstofQueueableLogItem);
            handleQueueableLogItemUpsert(qliMap);
        }
       
    }

/*
* @author Raviteja Vakkalagadda
* @date   04-03-2022
* @description  Method to perform the upsert of queueable log items records
* @param List<Queueable_Log_Item__c>
*/
    
public static void handleQueueableLogItemUpsert(map<Id,Queueable_Log_Item__c> logMap) {
        
    system.debug('logMap**'+logMap+'****'+logMap.size());
    if(!logMap.isEmpty()) {
    update logMap.values();}
} 
    		
/*
* @author Raviteja Vakkalagadda
* @date   04-13-2022
* @description  Method to prepare a map of Id with corresponding Queueable Log Item Records
* @param 
*/

    public map<Id,Queueable_Log_Item__c> prepareMapOfQLI(List<Queueable_Log_Item__c> lstofQueueableLogItem) {

         map<Id,Queueable_Log_Item__c> logMap = new map<Id,Queueable_Log_Item__c>();
            for(Queueable_Log_Item__c qp:lstofQueueableLogItem) {
                logMap.put(qp.Id,qp);
            }
        return logMap;
    }
}
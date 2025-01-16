/**
*    @author        Illumina
*    @date          
*    @description   Manager Class to handle stacking of Queueable Jobs to the chain. Also contains Methods to handle insert/update on Queuable Log Objects
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Anshaj                      4/11/2022         CMSI-14 : Support to capture Transaction Id  
*              
*/
 

public without sharing  class ilib_QueueableLogger{

    /**
    *    @author      Illumina  
    *    @date          
    *    @description  log Any new tasks Queued / added as part of current transaction/thread.
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    */
        public static Integer insertQueueableLogItems(List<Queueable> lstQueuedJobs,Integer sequence,String queueableLogRecId){
        
            if(lstQueuedJobs!=null && !lstQueuedJobs.isEmpty()){
            
                Map<Decimal, ilib_QueueableJobWrapper> mapStringtoUtilJob=new Map<Decimal, ilib_QueueableJobWrapper>();
                List<Queueable_Log_Item__c> lstofQueueableLogItem=new List<Queueable_Log_Item__c>();
                Decimal subSequece;
                  
                //Create a List of  Queueable_Log_Item__c from  QueueableUtilJob  instance 
                 for(Queueable jobObj:lstQueuedJobs){
                    ilib_Queueablethread qobj=(ilib_Queueablethread)jobObj; 
                    subSequece=Decimal.Valueof(sequence);
                    for(ilib_QueueableJobWrapper obj:qobj.lstQueueableJobs){
                           
                        Queueable_Log_Item__c qLog=new Queueable_Log_Item__c();
                        qLog.Class_Name__c=!String.IsEmpty(obj.ClassName)? obj.ClassName: ' ';
                        qLog.Method_Name__c=!String.IsEmpty(obj.methodName)?obj.methodName: ' ';
                        subSequece=subSequece+0.1;
                        qLog.Sequence__c=subSequece;
                        
                        qLog.Queueable_Log__c=queueableLogRecId;
                        qLog.Satus__c='Queued';
                        qLog.Apex_JobId__c='.';
                        qLog.Error_Message__c='.';
                        
                        lstofQueueableLogItem.add(qLog);
                        mapStringtoUtilJob.put(qLog.Sequence__c,obj);
                          
                    }
                    sequence=sequence+1;
              
                } 
                
                //Commit to DB
                if(lstofQueueableLogItem!=null && !lstofQueueableLogItem.isEmpty()){
                    insert lstofQueueableLogItem;
                  
                    //set back the record id back to   QueueableUtilJob  instance  in LogId field.This Id will be used later to update the process status or
                    // Exception .This will be used to identify  the correspoding  Queueable_Log_Item__c record  in ilib_Queueablethread.updateQueueableLogItems method.
                    for(Queueable_Log_Item__c obj:lstofQueueableLogItem){
                        mapStringtoUtilJob.get(obj.Sequence__c).queueableLogItemId=obj.id;
                    }
                }
            }
                
            return sequence;    
        }
    
    /*   @author      Illumina  
    *    @date          
    *    @description  Log the Parent Sync Process with Workstream
    *    Modification Log:
    *    ------------------------------------------------------------------------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *            Anshaj                         21-04-2022          CMSI-14 Added support to capture the Transaction Id & Org Id
    *            Anshaj                         02/06/2022          CMSI-37 Added Workstream Field 
    */

    public static id insertQueueableLog(ilib_QueueableManager.queueableLogParameter queueLog){
        
        Queueable_Log__c qlog=new   Queueable_Log__c();
        qlog.logIdentifier__c=!String.IsEmpty(queueLog.queueablethreadObject.logIdentifier)?queueLog.queueablethreadObject.logIdentifier: ' ';
        qlog.Apex_JobId__c=!String.IsEmpty(queueLog.apexJobId)?queueLog.apexJobId: ' ';
        qlog.Interface_Log__c=queueLog.queueablethreadObject.InterfaceLogId;
        //CMSI-14 Added support to capture the Transaction Id & Org Id
        qlog.Transaction_Id__c = ilib_LogEvent.getTransactionId();
        qlog.Org_Id__c = UserInfo.getOrganizationId();
        //CMSI-37 Added workstream field
        if(queueLog.workstream != null){
        qlog.Workstream__c = queueLog.workstream;
        }
        else{
          qlog.Workstream__c = ilib_LogEvent.getWorkstream();

        }
        insert qlog;
        return qlog.id;
    }
        
       /* 
        *    @author      Illumina  
        *    @date          
        *    @description  update the process statuses on to Queueable_Log_Item__c object 
        *    Modification Log:
        *    ------------------------------------------------------------------------------------------------------------------------------------------------
        *             Developer                      Date                Description
        */   
        public static Queueable_Log_Item__c updateQueueableLogItems(ilib_QueueableJobWrapper obj,ID apexJobId,Exception ex,Decimal retryCount){
            system.debug('retryCount***'+retryCount);
            Queueable_Log_Item__c qLog=new Queueable_Log_Item__c();
            qLog.id=obj.queueableLogItemId ;
            qLog.Apex_JobId__c=apexJobId;
            system.debug('Ex1'+ex);
            if(ex!=null){
                qLog.Retry_Count__c = retryCount+1;
                system.debug('Ex'+ex);
                qLog.Satus__c='Failed';
                qLog.Stack_Trace__c=ex.getStackTraceString();
    
                //text length fix
                if(!String.IsEmpty(ex.getMessage()) && ex.getMessage().length() >= 250){
                qLog.Error_Message__c  = ex.getMessage().substring(0, 250);
                } else if(!String.IsEmpty(ex.getMessage()) && ex.getMessage().length() < 250){
                qLog.Error_Message__c  = ex.getMessage();    
                } else {
                    qLog.Error_Message__c = ' ';
                }
    
                
            }else{
                qLog.Satus__c='Success';
            }
            system.debug('qLog**'+qLog);
            return qLog;
        }   
    }
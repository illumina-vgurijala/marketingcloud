/**
*    @author     Illumina   
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Anshaj                      4/11/2022         CMSI-14 : Support to capture Transaction Id and pass it on to ilib_LogEvent Class 
*              
*/
public with sharing class ilib_QueueableManager implements Queueable,Database.AllowsCallouts,Finalizer {

    private static final String LOG_TITLE = 'ilib_QueueableManager';
    public static  Boolean throwException = false;
    private string transcationId;

    //This is passed from thread to update the QLI's in seperate finalizer transaction 
    public map<Id,Queueable_Log_Item__c> mapQLIItems = new map<Id,Queueable_Log_Item__c>();
    
    // List to stores Queueable tasks
    Queueable[] collectiveQueueableJobs;

    //Queueable Job to be executed in current thread
    Queueable queueableJobtobeExecuted;

    //Id of the parent Process which invoked the first Queueable job from a Synchrnous Transcation.
    public String queueableLogRecId;

    //Stores the Job sequence and is incremented each time a new Queueable task in logged to DB. 
    public Integer sequence = 1;

    private static Queueable[] newJobsfromCrntExeThread;

    public static ilib_QueueableManager self;

    private ilib_QueueableManager(Queueable item)
    {
        collectiveQueueableJobs = new Queueable[] { item };
    }
/**
*    @author        Illumina
*    @date          
*    @description   static method to be called to add a new task to the Queuable chain.
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              
*/
    public static Id enqueueJob(ilib_Queueablethread item)
    {
        if (self == null)
        {
            ilib_QueueableManager queueableManagerObject=new ilib_QueueableManager(item);
        
         if (queueableManagerObject.queueableLogRecId == null)
            {
                // called on the first Queable invocation from sync transaction and logs current prtocess on Queueable_Log Object
                queueableLogParameter qLogParameter = new queueableLogParameter(item,'.');
                queueableManagerObject.queueableLogRecId=ilib_QueueableLogger.insertQueueableLog(qLogParameter);


                //logs the taks to Queueable_Log_Item__c that are combined on current payload that going to be executed.
                queueableManagerObject.sequence=ilib_QueueableLogger.insertQueueableLogItems(new List<Queueable>{item},queueableManagerObject.sequence,queueableManagerObject.queueableLogRecId);
            }  

            //invokes the Async process when the First Queuable task in logged from a Sync process. 
            return System.enqueueJob(queueableManagerObject);
        }
        else
        {
            // add the newly added Queuable task in current executing thread/Transaction to List
            if (newJobsfromCrntExeThread == null)
                newJobsfromCrntExeThread = new Queueable[]{item};
            else
                newJobsfromCrntExeThread.add(item);

            //if the current running trnsaction is Async(Queuable ) add any new Queuable task to the 
            //existing (jobs that got added from any previous thread) payload List.
            if (self != null)
                self.collectiveQueueableJobs.add(item);

            return null;
        }
    }

     /**

*    @author        Illumina
*    @date          
*    @description   static method to be called to add a new task to the Queuable chain. This method also takes workstream as an input
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Anshaj                        02/06/2022          CMSI-37 Added this method to capture workstream
*              
*/
public static Id enqueueJob(ilib_Queueablethread item, String strWorkstream)
{
    if (self == null)
    {
        ilib_QueueableManager queueableManagerObject=new ilib_QueueableManager(item);
    
     if (queueableManagerObject.queueableLogRecId == null)
        {
            // called on the first Queable invocation from sync transaction and logs current prtocess on Queueable_Log Object
            //CMSI-37 Added workstream field
            queueableLogParameter qLogParameter = new queueableLogParameter(item,'.',strWorkstream);
            queueableManagerObject.queueableLogRecId=ilib_QueueableLogger.insertQueueableLog(qLogParameter);

            //logs the taks to Queueable_Log_Item__c that are combined on current payload that going to be executed.
            queueableManagerObject.sequence=ilib_QueueableLogger.insertQueueableLogItems(new List<Queueable>{item},queueableManagerObject.sequence,queueableManagerObject.queueableLogRecId);
        }  

        //invokes the Async process when the First Queuable task in logged from a Sync process. 
        return System.enqueueJob(queueableManagerObject);
    }
    else
    {
        // add the newly added Queuable task in current executing thread/Transaction to List
        if (newJobsfromCrntExeThread == null)
            newJobsfromCrntExeThread = new Queueable[]{item};
        else
            newJobsfromCrntExeThread.add(item);

        //if the current running trnsaction is Async(Queuable ) add any new Queuable task to the 
        //existing (jobs that got added from any previous thread) payload List.
        if (self != null)
            self.collectiveQueueableJobs.add(item);

        return null;
    }
}

    /**
*    @author  Anshaj       
*    @date    03/June/2022
*    @description: CMSI-37 creating a wrapper class to pass the parameters in insertQueueableLog method
*/
public class queueableLogParameter {
    public ilib_Queueablethread queueableThreadObject{get; set;}
    public String apexJobId{get; set;}
    public String workstream{get; set;}

  /**
*    @author  Anshaj       
*    @date    03/June/2022

*    @description: CMSI-37 constructor for wrapper class
*/
public queueableLogParameter(ilib_Queueablethread queueableThreadObject, String apexJobId, String workstream){
    this.workstream = workstream;
    this.queueableThreadObject = queueableThreadObject;
    this.apexJobId = apexJobId;
}

 /**
*    @author  Anshaj       
*    @date    03/June/2022
*    @description: CMSI-37 constructor for wrapper class
*    @To-Do : to be removed once all client classes are passing workstream.
*/
public queueableLogParameter(ilib_Queueablethread queueableThreadObject, String apexJobId){
    //to do : to be removed once all client classes are passing workstream.

    this.queueableThreadObject = queueableThreadObject;
    this.apexJobId = apexJobId;
}
}

/**
*    @author        Illumina
*    @date          
*    @description   Execute Method called(in a new thread) each time System.enqueueJob is called.
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Anshaj                        21-04-2022          CMSI-14 : Added a query to pull Header Record and pass on the Transaction_Id__c to ilib_LogEvent.setRequestId() method.
*              
*/
    public void execute(QueueableContext context)
    {
             
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push(LOG_TITLE + '.execute');
        try{
            self = this;
            
            Finalizer objFinalizer = self;
            System.attachFinalizer(objFinalizer);// To attach the Finalizer execute method to the parent Execute method
            ilib_LogEvent.message('collectiveQueueableJobs**'+collectiveQueueableJobs);
            // next payload to be executed from the Payload List  
            queueableJobtobeExecuted = collectiveQueueableJobs.remove(0); 
            ilib_LogEvent.message('queueableJobtobeExecuted**'+queueableJobtobeExecuted);
            //all payloads are instance of  ilib_Queueablethread 
            if (queueableJobtobeExecuted instanceof ilib_Queueablethread)
            {
                ilib_LogEvent.message('queueableJobtobeExecuted&&'+queueableJobtobeExecuted);
                ilib_Queueablethread queueablethreadObj = (ilib_Queueablethread)queueableJobtobeExecuted;       
                ilib_LogEvent.message('testing Payload..' + collectiveQueueableJobs);
               
                if(queueablethreadObj.tId != Null){
                    ilib_LogEvent.setTransactionId(queueablethreadObj.tId);
                    ilib_LogEvent.info('queueableTranscationId : '+queueablethreadObj.tId);
                    transcationId = queueablethreadObj.tId; 
                }
                 
            
                ilib_LogEvent.message('context**'+context);
                //Execute the payload      

            try{ queueablethreadObj.execute(context); }
            catch(Exception e){
                    mapQLIItems = ilib_Queueablethread.qliMap;
                    ilib_LogEvent.error('mapQLIItems***'+mapQLIItems);
                    throw e;
            }
            }

            //Check if payload List conatins tasks to be executed 
            if (!collectiveQueueableJobs.isEmpty() && !Test.isRunningTest())
            {
                ilib_LogEvent.message('collectiveQueueableJobs&&'+collectiveQueueableJobs);
                this.sequence = ilib_QueueableLogger.insertQueueableLogItems(newJobsfromCrntExeThread, this.sequence, this.queueableLogRecId); 

                // pass the current executing refrence of  QueueableUtil (which hold all the chained tasks as Payload) to the New Thread
                System.enqueueJob(this);
            }
            if(throwException){
                 throw new QueueableException('Exception for test coverage');
            }
        }
        catch(Exception ex){
            ApexExceptions.emit(LOG_TITLE,NULL,ex);
            throw ex;
        }
        finally{
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
    }
	
	/*
    * @author Raviteja Vakkalagadda
    * @date   04-03-2022
    * @description  Execute method for Finalizer interface , which invokes retry mechanism when parent job fails
    * @param FinalizerContext
*/
    
    public void execute(FinalizerContext ctx) {
        ilib_LogEvent.setTitle(LOG_TITLE + '.Finalizer');
        ilib_LogEvent.push(LOG_TITLE + '.execute');
        try{
            ilib_LogEvent.setTransactionId(this.transcationId);
            ilib_QueueableManager queueableManagerObject2 =new ilib_QueueableManager(this.queueableJobtobeExecuted);
            //Added below line to fix failing retries with count of 1 or 2
            queueableManagerObject2.queueableLogRecId = this.queueableLogRecId; //DCP-54018
            String queueException = '';
            ilib_LogEvent.message('deserializedd**'+queueableManagerObject2);
            ilib_LogEvent.message('ParentJobResult***'+ctx.getResult());
            ilib_LogEvent.message('mapQLIItems***'+mapQLIItems);

            if(ctx.getResult() != ParentJobResult.SUCCESS || Test.isRunningTest()){
                queueException =    String.valueOf(ctx.getException());
                Set<String> setCodeParamName=new Set<String>{'Retry_Exceptions'};
                    List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(setCodeParamName);
                if(!Test.isRunningTest() && lstCodeParam[0]!= NULL && queueException.contains(lstCodeParam[0].value__c) ){
                    ilib_LogEvent.message('Exception From parent Execute'+ctx.getException());
                    
                    if(!mapQLIItems.isEmpty()){
                        update mapQLIItems.values();
                    }
                    
                    ilib_LogEvent.message('update in finalizer'+mapQLIItems.values());
                    String newJobId = '' + System.enqueueJob(queueableManagerObject2); // This call fails after 5 times when it hits the chaining limit
                    ilib_LogEvent.message('Retry JobId'+newJobId);
                }
            }
            else{
                ilib_LogEvent.message('Parent Job is Success'+ctx.getResult());
            }
            if(throwException){
                throw new QueueableException('Exception for test coverage');
            }
        }

        catch(Exception exc){
            ApexExceptions.emit('LOG_TITLE',NULL,exc);
            throw exc;
        }
        finally{
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
    }

    /*
    * @author Gagan Sindwani
    * @date   08-20-2022
*/
    public class QueueableException extends Exception { }

}
/**
*    @author Ashwin Kumar
*    @date   Apr-04-2022
*    @description DCP-52339
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                     Date(YYYY-MM-DD)        Description         
*         Ashwin Kumar                  Apr-04-2022             DCP-52339
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class TAPS_DeferredRunQueueable implements Queueable {
    String strMethodtoExecute;
	public static Boolean catchException = false;
    List<TAPS_Deferred_Record__c> lstProcessedDeferredRecords;

    public static final String METHOD_NAME_DELETE_DEFERRED_RECORDS = 'deleteDeferredRecords';
    public static final String METHOD_NAME_REVERT_IS_PROCESSING_FLAG = 'revertIsProcessingFlag';
    
    /**
    *   @author Ashwin Kumar
    *   @description Constructor to Initialize Class parameters DCP-52339
    **/
    public TAPS_DeferredRunQueueable(String strMethodtoExecute, List<TAPS_Deferred_Record__c> lstProcessedDeferredRecords) {
        this.strMethodtoExecute = strMethodtoExecute;
        this.lstProcessedDeferredRecords = lstProcessedDeferredRecords;
    }

    /**
    *  @author Ashwin
    *  @description - Holds methods that need to be Run in Queuable context from TAPS_DeferredRun class
    *  @modification CMSI-38 Added try catch mechanism and emitting exception to ApexExceptions with Workstream.
    **/
    public void execute(QueueableContext qc) { 
        try{
        //Call to deleteDeferredRecords method on TAPS_DeferredRun class to delete processed deferred records
        if(METHOD_NAME_DELETE_DEFERRED_RECORDS == strMethodtoExecute && !lstProcessedDeferredRecords.IsEmpty()) {
            TAPS_DeferredRun.deleteDeferredRecords(lstProcessedDeferredRecords);
        }

        //Call to revertIsProcessingFlag method on TAPS_DeferredRun class to set is processing to false for un processed deferred records
        if(METHOD_NAME_REVERT_IS_PROCESSING_FLAG == strMethodtoExecute && !lstProcessedDeferredRecords.IsEmpty()) {
            TAPS_DeferredRun.revertIsProcessingFlag(lstProcessedDeferredRecords);
        }
		if(catchException == true){
				throw new AuraHandledException('Throwing Custom Exception');
			}
        }catch(Exception e){
            //CMSI-38 emitting exception to ApexExceptions with Workstream.
            ApexExceptions.emit('TAPS_DeferredRunQueueable',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
    }
}

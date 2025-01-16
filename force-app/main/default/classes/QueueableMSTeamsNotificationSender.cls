/**
*    @author : Nitin Sood
*    @date   : 15-7-2021
*    @description : Queuable Class for sending ms teams notification.
*    Modification Log:
*    ------------------------------------------------------------------------------------ 

*    ------------------------------------------------------------------------------------ 
*                    
*/
public class QueueableMSTeamsNotificationSender implements Queueable {
    
    Map<Id, String>  mapRecIdToErrors = new Map<Id, String>();
    String source;
    Id batchProcessId;
	public static Boolean catchException = false;
/**
*    @author : Nitin Sood
*    @date   : 15-7-2021
*/
    
    public QueueableMSTeamsNotificationSender(Map<Id, String>  mapRecIdToErrors, String source, Id batchProcessId ){
        this.mapRecIdToErrors = mapRecIdToErrors;
        this.source = source;
        this.batchProcessId = batchProcessId;
    }
/**
*    @author : Nitin Sood
*    @modification : CMSI-38 Added try catch mechanism and emitting exception to ApexExceptions with Workstream.
*    @date   : 15-7-2021
*/
    
    public void execute(QueueableContext qc){
        try{
        if(!mapRecIdToErrors.isEmpty() && source != null){
            MSTeamsNotificationSender.getTableEmailBodyAndSendNotification(mapRecIdToErrors, source, batchProcessId);        
        } 
		if(catchException == true){
			throw new AuraHandledException('Throwing Custom Exception');
		}
    }catch(Exception e){
        // CMSI-38 Emitting exception to ApexExceptions class with Workstream.
        ApexExceptions.emit('QueueableMSTeamsNotificationSender',e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
    }
    }
}

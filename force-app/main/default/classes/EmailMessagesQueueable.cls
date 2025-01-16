/*
* @author : Sravan
* @Description: Queueable class for EmailMessages class
Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Nitin                          7 june 2022         CMSI-36 try catch in execute method 
 *    ------------------------------------------------------------------------------------  
*/ 
public class EmailMessagesQueueable implements Queueable {
    String strMethodtoExecute;
    Map<Id,String> caseIdMap=new Map<Id,String>();
    public static Boolean catchException = false;
    /*
	 * Constructor to initilize the default variables
	 */ 
    public EmailMessagesQueueable(String strMethodtoExecute , Map<Id,String> caseIdMap){
        this.strMethodtoExecute=strMethodtoExecute;
        this.caseIdMap=caseIdMap;
    }
    /*
	 * Execute the main class method from queuable
	 */ 
    public void execute(QueueableContext qc) {
        try{
            //Call to updateCaseOwnerAssignment method on EmailMessages class to make update on cases
            if(strMethodtoExecute=='updateCaseOwnerAssignment' && !caseIdMap.IsEmpty() ){
                EmailMessages.updateCaseOwnerAssignment(caseIdMap);      
            }
            if(catchException == true){
                throw new AuraHandledException('throwing custom exceptions');
            }
        }
        catch(Exception e){
            ApexExceptions.emit('EmailMessagesQueueable.'+strMethodtoExecute,e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
    }    
    
}
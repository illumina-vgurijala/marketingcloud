/**************************************************************************************************************************************** NAME         : CaseUpdateQueueable* DESCRIPTION  : Automatic Case Creation from Order Line Item* @AUTHOR      : Susmitha* @DATE        : 13-09-2022
** MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------*
DEVELOPER                DATE                DESCRIPTION 
Susmitha

**/

public without sharing class CaseUpdateQueueable implements System.Queueable {
    private static final String LOG_TITLE = 'CaseUpdateQueueable';
    String strMethodtoExecute;
    Map<id,Case> mapOfoCaseRecords;

   /*
    * Constructor
    */
    public CaseUpdateQueueable(String strMethodtoExecute,Map<Id,Case> mapOfoCaseRecords){
        this.strMethodtoExecute = strMethodtoExecute;
        this.mapOfoCaseRecords=mapOfoCaseRecords;
    }
    /*
    * Description - execute method of this queueable class
    */
    public void execute(System.QueueableContext qc){
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            if(strMethodtoExecute=='updateCase' && !mapOfoCaseRecords.IsEmpty()){
                 CaseQueueableHelper.updateCase(mapOfoCaseRecords);      
            }
            if(strMethodtoExecute=='updateCodeTitleonRTChange' && !mapOfoCaseRecords.IsEmpty()){
                 CaseQueueableHelper.updateCodeTitleonRTChange(mapOfoCaseRecords);      
            }
            ilib_LogEvent.pop();
       }Catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage());
        }
    }
}
/***************************************************************************************************************************************
 * NAME   : QualityRecordQueueable
 * DESCRIPTION  : Queueable class on QualityRecord object.
 *				      
 * @AUTHOR : Gladis Evangaly
 * @DATE   : 05-Apr-2022  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Gladis             	05-Apr-2022          Initial Version.
  ****************************************************************************************************************************************/ 
public with sharing class QualityRecordQueueable implements Queueable,Database.AllowsCallouts {
    private static final String LOG_TITLE = 'QualityRecordQueueable';
    String strMethodtoExecute;
    Set<Id> setRecordIds = new Set<Id>();

    /*
    * Constructor
    */
    public QualityRecordQueueable(String strMethodtoExecute, Set<Id> setRecordIds) {
        this.strMethodtoExecute = strMethodtoExecute;
        this.setRecordIds = setRecordIds;
    }

    /*
    * Execute queueable
    */
    public void execute(QueueableContext qc){
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try {
            //call sendQICreationToETQ method on QR insert
            if(String.isNotBlank(strMethodtoExecute) && strMethodtoExecute== 'sendQICreationToETQInsert' && setRecordIds!=null && !setRecordIds.isEmpty()){
                QualityRecords.sendQICreationToETQ(setRecordIds);         
            }  

            //call sendQICreationToETQ method on QR update
            if(!setRecordIds.IsEmpty() && strMethodtoExecute == 'sendQICreationToETQUpdate'){
                QualityRecords.sendQICreationToETQ(setRecordIds);         
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit(); 
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }    
    }
}
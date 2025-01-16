/***************************************************************************************************************************************
 * NAME   : QualityRecordJunctionQueueable
 * DESCRIPTION  : Queueable class on QualityRecordJunction object.
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
public with sharing class QualityRecordJunctionQueueable implements Queueable,Database.AllowsCallouts {
    private static final String LOG_TITLE = 'QualityRecordJunctionQueueable';
    String strMethodtoExecute;
    Set<Id> setRecordIds = new Set<Id>();

    /*
    * Constructor
    */
    public QualityRecordJunctionQueueable(String strMethodtoExecute, Set<Id> setRecordIds) {
        this.strMethodtoExecute = strMethodtoExecute;
        this.setRecordIds = setRecordIds;
    }

    /*
    * Execute queueable
    */
    public void execute(QueueableContext qc){
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try {
            //call sendQILinkDelinkToETQ method on QRJ insert
            if(!setRecordIds.IsEmpty() && strMethodtoExecute=='sendQILinkDelinkToETQInsert'){
                QualityRecordJunctions.sendQILinkDelinkToETQ(setRecordIds);         
            }  
            //call sendQILinkDelinkToETQ method on QRJ update
            if(!setRecordIds.IsEmpty() && strMethodtoExecute=='sendQILinkDelinkToETQUpdate'){
                QualityRecordJunctions.sendQILinkDelinkToETQ(setRecordIds);         
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit(); 
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        } 
    }
}
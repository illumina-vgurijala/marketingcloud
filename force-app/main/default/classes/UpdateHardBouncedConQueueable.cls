/*@ author       : Gopi
* @ date         : 05-Jun-2023
* @ Description  : CMCM-704:  R/Q Contact Notifications: Account Engagement Hard Bounced
*/
public with sharing class UpdateHardBouncedConQueueable implements Queueable {
    Set<Id> setContactIds;
    private static final String LOG_TITLE = 'RQContactEligibleQueueable';


    /*@ author       : Gopi
    * @ date         : 05-Jun-2023
    * @ Description  : This is the Constructor for UpdateHardBouncedConQueueable
    */
    public UpdateHardBouncedConQueueable(Set<Id> setContactIds) {
        this.setContactIds = setContactIds;         
    }

    /*
    *  @AUTHOR:  Gopi 
    *  @DESCRIPTION: This Method to invoke  
    */
    public void execute(QueueableContext context) {  
        ilib_LogEvent.push(LOG_TITLE +'.UpdateHardBouncedConQueueable');  
        try {
            ilib_LogEvent.message('setContactIds--'+setContactIds);
            List<AccountContactRelation> lstAccContRelationRecs = new List<AccountContactRelation>();        
            lstAccContRelationRecs = RQContactEligibleHelper.getAccConReltionship(setContactIds); 
            ilib_LogEvent.info('lstAccContRelationRecs--'+lstAccContRelationRecs);
            if(!lstAccContRelationRecs.isEmpty()) {                
                Update lstAccContRelationRecs;
            }
            ilib_LogEvent.pop();
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE+'.UpdateHardBouncedConQueueable',e);
            throw e;
        }  		
    }
}
/*@ author       : Maruthi
* @ date         : 31-Jan-2022
* @ Description  : Email verificaton Queueable
*
*/
public with sharing class EmailVerificationQueueable implements Queueable, Database.AllowsCallouts {

    Contact conWithEmailId;
    public static Boolean testVerificationRequest = false;
    /*@ author       : Maruthi
    * @ date         : 31-Jan-2022
    * @ Description  : This is the Constructor for EmailVerificationQueueable
    *
    */
    public EmailVerificationQueueable(Contact conWithEmailId) {
        this.conWithEmailId = conWithEmailId;
    }

    /*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: This Method to invoke sendVerificationRequest 
    */
    public void execute(QueueableContext context) {
        try{
            String objectApiName = string.valueof(conWithEmailId.getsobjecttype());
            if(!Test.isRunningTest() || testVerificationRequest){
                EmailVerificationController.sendVerificationRequest(conWithEmailId.Email, conWithEmailId.Id, objectApiName, false);
            }
        } catch(Exception e){
            ApexExceptions.emit('EmailVerificationQueueable', e, conWithEmailId.Id, ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
    }
}

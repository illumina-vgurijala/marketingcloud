/***************************************************************************************************************************************
* @Author:  Prem Ranjan
* @Date:   10-March-2022
* @Description: DCP-51955, Ability for system to auto send email notification on account verification and/or upgrade
*
* Modification Log:
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* Prem Ranjan              10-March-2022        Initial Version
******************************************************************************************************************************************************************/
public with sharing class EmailNotificationOnAccUpgrade {
    public static String emailTemplateName = 'Account_Account_Upgrade_Email_Notify';
    public static final String EXCEPTION_LOG_TITLE = 'Account.EmailNotificationOnAccUpgrade';

    /**
    *  @author Prem Ranjan
    *  @description Wrapper class for Flow Inputs
    *  @return void
    **/   
    public class FlowInputs {
        @InvocableVariable(description='Account Id which is getting assigned from flow' required=true)
        public Id strAccountId;
        @InvocableVariable(description='Owner/CreatedBy Id which is getting assigned from flow' required=false)
        public Id strOwnerId;
        //@InvocableVariable public Id strAccountCreatedById;
        @InvocableVariable(description='List of SendTo Email Id as string which is getting assigned from flow' required=false)
        public List<String> sendToEmailIdLst;
        @InvocableVariable(description='List of CC Email Id as string which is getting assigned from flow' required=false)
        public List<String> ccEmailIdLst;
    }

     /*
     * @Author:Prem Ranjan
     * @Description : Invocable method called from Flow to fetch Email Ids
     * @return: NA
     */
    @InvocableMethod(label='Invoke triggerEmailOnAccountVerification' Description='Trigger Email On Account Verification')
    public static void setFlowInputsToSendCustomNotification(List<FlowInputs> requests) {
        List<EmailTemplate> lstEmailTemplate =  new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String> {emailTemplateName});
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>(); 
        ilib_LogEvent.setTitle(EXCEPTION_LOG_TITLE);  
        ilib_LogEvent.push('.setFlowInputsToSendCustomNotification()');
        for (FlowInputs inputRequest: requests) {
                ilib_LogEvent.message('Request1*************'+inputRequest.strAccountId);
                ilib_LogEvent.message('Request2*************'+inputRequest.strOwnerId);
                ilib_LogEvent.message('Request3*************'+inputRequest.sendToEmailIdLst);
                ilib_LogEvent.message('Request4*************'+inputRequest.ccEmailIdLst);
            Messaging.SingleEmailMessage email = new EmailBuilder(
                                                        lstEmailTemplate[0].Id, 
                                                        inputRequest.strOwnerId)
            .addWhatId(inputRequest.strAccountId)
            .addTo(inputRequest.sendToEmailIdLst)
            .addCc(inputRequest.ccEmailIdLst)
            .doNotSendToTargetId()
            .emailMessage();
            allmsg.add(email);
            }
        try{
                Messaging.sendEmail(allmsg,false); 
        }catch (Exception e) {
                ApexExceptions.emit(EXCEPTION_LOG_TITLE, e);
            }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
       }
    }
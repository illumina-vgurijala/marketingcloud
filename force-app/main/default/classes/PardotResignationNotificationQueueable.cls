/**
 *   @author: Deep Diwakar
*    @date:   23-Sept-2022
*    @description: Queueable class call Pardot Resignation Notification Form Handler
*    @Test Class: TestPardotResignationNtfQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*        Deep Diwakar       23-Sept-2022        PM-911: Initial build
*        Deep Diwakar       July-12-2023        DCP-60096: Modified to allow chaining of queueables
*    --------------------------------------------------------------------------------------------------
 */

 public with sharing class PardotResignationNotificationQueueable implements Queueable, Database.AllowsCallouts{
    private String contEmail;
    private List<String> emailList = new List<String>();
    private static final String LOG_TITLE = 'PardotResignationNotificationQueueable';

    // Added for test coverage of catch block. It is getting updated through its test class
    @TestVisible
    private Boolean testCodeCoverage = false;

    private static final string TEST_CUSTOM_EXCEPTION = 'Test exception to cover catch block';

    /**
     * @author: Deep Diwakar
     * @date: 23-Sept-2022
     * @description: Constructor
     * @param: Contact email id that needs to be passed to Pardot form handler
     * @return: NA
     */
    public PardotResignationNotificationQueueable(String emailId) {
        contEmail = emailId;
    }

     /**
     * @author: Deep Diwakar
     * @date: 23-Sept-2022
     * @description: Constructor
     * @param: Contact email id that needs to be passed to Pardot form handler
     * @return: NA
     */
    public PardotResignationNotificationQueueable(List<String> emails) {
        emailList = emails;
    }


    /**
     * @author: Deep Diwakar
     * @date: 23-Sept-2022
     * @description: Queueable execute method
     * @param: Contact email id that needs to be passed to Pardot form handler
     * @return: void
     */
    public void execute(QueueableContext context) {
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.MARKETING);//CMSI-92
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        String currEmail = '';

        try {
            ilib_LogEvent.info('Email Id: ' + contEmail);

            // Added for covering catch block in test class
            if (testCodeCoverage && Test.isRunningTest()) {
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }

            if (!emailList.isEmpty()) {
                currEmail = emailList.get(0);
                // after getting first email, remove it from the list so it doesn't get queued again
                emailList.remove(0);
            } else if (!String.isBlank(contEmail)) {
                currEmail = contEmail;
            }

            // call helper class to make callout
            if (!String.isBlank(currEmail)) {
                PardotResignationNotificationSender.callPardotResignationFormHandler(currEmail);
            }
            
            // chain next queueable
            // not chaining in Test context as this is not permitted by Salesforce currently (April-1-2023)
            if (!emailList.isEmpty() && !Test.isRunningTest()) {
                ilib_LogEvent.info('chaining next queueable');
                System.enqueueJob(new PardotResignationNotificationQueueable(emailList));
            }
            ilib_LogEvent.pop();

        } catch(Exception ex) {
            ApexExceptions.emit(LOG_TITLE+'.execute-email-' + contEmail, ex, ilib_LogEvent.MARKETING);
            throw ex;

        }

        ilib_LogEvent.emit();

    }

     /*
    @Description: To throw custom exception for covering catch block in test class execution
   */
   public class CustomException extends Exception {}
}
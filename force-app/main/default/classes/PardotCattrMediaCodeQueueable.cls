/**
 *   @author: Deep Diwakar
*    @date:   March-23-2023
*    @description: Queueable class for Pardot Campaign Attribution Form Handler
*    @Test Class: TestPardotCampaignAttrSyncQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*        Deep Diwakar       March-23-2023        DCP-59535: Queueable class for Pardot Campaign Attribution Form Handler
*        Deep Diwakar       June-10-2023         CMCM-1164: Updated this class to support platform event changes in caller class
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class PardotCattrMediaCodeQueueable implements Queueable, Database.AllowsCallouts{

    private final Map<String, Map<String, Boolean>> pardotSyncMap; 
    private static final String LOG_TITLE = 'PardotCattrMediaCodeQueueable';

    // Added for test coverage of catch block. It is getting updated through its test class
    @TestVisible
    private Boolean testCodeCoverage = false;

    private static final string TEST_CUSTOM_EXCEPTION = 'Test exception to cover catch block';

    /**
     * @author: Deep Diwakar
     * @date: March-23-2023
     * @description: Constructor
     * @param: Campaign member email id that needs to be passed to Pardot form handler
     * @return: NA
     */
    public PardotCattrMediaCodeQueueable(Map<String, Map<String, Boolean>> currMap) {
        pardotSyncMap = currMap;

    }


    /**
     * @author: Deep Diwakar
     * @date: March-23-2023
     * @description: Queueable execute method
     * @param: Campaign member email id that needs to be passed to Pardot form handler
     * @return: void
     */
    public void execute(QueueableContext context){
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.MARKETING);//CMSI-92
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        String currEmail = '';

        try {
        
            // Added for covering catch block in test class
            if (testCodeCoverage && Test.isRunningTest()) {
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }

            String urlSuffix = '';

            // get first campaign member email
            List<String> lstEmail = new List<String>(pardotSyncMap.keySet());
            currEmail = lstEmail.get(0);

            ilib_LogEvent.info('currEmail: ' + currEmail);

            // get cattr and media code values for current campaign member email
            Map<String, Boolean>syncFieldMap = pardotSyncMap.get(currEmail);
            Boolean isCattrPresent = syncFieldMap.get('Cattr');
            Boolean isMediaCodePresent = syncFieldMap.get('MediaCode');

            // set form handler url parameter based on cattr and media code values from the map
            if (isCattrPresent != null && isCattrPresent && isMediaCodePresent != null && isMediaCodePresent) {
                urlSuffix = '&Cattr=NULL&Mediacode=NULL';
            } else if (isCattrPresent != null && isCattrPresent) {
                urlSuffix = '&Cattr=NULL';
            } else if (isMediaCodePresent != null && isMediaCodePresent) {
                urlSuffix = '&Mediacode=NULL';
            }

            ilib_LogEvent.info('urlSuffix: ' + urlSuffix);
    
            // call helper and pass currEmail and urlSuffix
            if (String.isNotBlank(urlSuffix)) {
                PardotCattrMediaCodeSender.callPardotCattrMediaCodeFormHandler(currEmail, urlSuffix);
            }
            
            // remove this email id from the map
            pardotSyncMap.remove(currEmail);
    
            // chain next queueable
            // not chaining in Test context as this is not permitted by Salesforce currently (April-1-2023)
            if (!pardotSyncMap.isEmpty() && !Test.isRunningTest()) {
                ilib_LogEvent.info('chaining next queueable');
                System.enqueueJob(new PardotCattrMediaCodeQueueable(pardotSyncMap));
            }

        } catch(Exception ex) {
            ApexExceptions.emit(LOG_TITLE+'.execute-email-' + currEmail, ex, ilib_LogEvent.MARKETING);
            throw ex;
        } finally {
            ilib_LogEvent.emit();
        }

    }

    /*
    @Description: To throw custom exception for covering catch block in test class execution
   */
   public class CustomException extends Exception {}
}
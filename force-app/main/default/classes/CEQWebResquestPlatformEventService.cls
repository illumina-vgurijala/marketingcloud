/**
 * @description       : Fires a Platform Event to notify that there is a new CEQ web request.
 * @author            : Arquimidez Mora
 * @group             : 
 * @last modified on  : 11-15-2024
**/
public with sharing class CEQWebResquestPlatformEventService {

    private static final String LOG_TITLE = 'CEQWebResquestPlatformEventService';

    /**
    * @description Create Platform Event
    * @author Arquimidez Mora | 10-22-2024 
    * @param strInterfaceLogId 
    * @param strCustomerId 
    * @return Boolean 
    **/
    public static Boolean createPlatformEvent(QuoteCreationAPIPESubscriberService.Step stepProcessType, String strJSONPayload){
        List<Quote_Creation_API__e> lstCEQWebRequest = new List<Quote_Creation_API__e>();

        Quote_Creation_API__e objCEQWebRequest = new Quote_Creation_API__e();
        objCEQWebRequest.JSON_Payload__c = strJSONPayload;
        objCEQWebRequest.Process_Type__c = stepProcessType.name();

        lstCEQWebRequest.add(objCEQWebRequest);
        
        return publishEvent(lstCEQWebRequest);
    }


    /**
    * @description Method used to publish platform event
    * @author Arquimidez Mora | 10-22-2024 
    * @param lstCEQWebRequest 
    * @return Boolean 
    **/
    private static Boolean publishEvent(List<Quote_Creation_API__e> lstCEQWebRequest){
        RestOpportunityQuoteCreationDataReceiver instantiated = new RestOpportunityQuoteCreationDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(LOG_TITLE);
        List<Database.SaveResult> results = EventBus.publish(lstCEQWebRequest);
        List<String> lstErrors = new List<String>();

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails);
        
        for(Database.SaveResult sr : results){
            if(!sr.isSuccess()){
                for(Database.Error err : sr.getErrors()){
                    lstErrors.add('Exception on Publish Event: '+ err.getMessage() + '\n');
                }
            }
        }

        Boolean isSuccess = lstErrors.isEmpty();

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + lstErrors.toString())
        );

        if (!isSuccess) {
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + lstErrors.toString() +'----');
            ilib_LogEvent.pop();
        }

        ilib_LogEvent.emit();
        
        return isSuccess;
    }
}
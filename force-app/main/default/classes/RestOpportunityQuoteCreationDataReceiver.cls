/***************************************************************************************************************************************
 * NAME   : RestOpportunityQuoteCreationDataReceiver
 * DESCRIPTION  : Receive Opportunity/Quote Payload
 * The schema for this request can be found at QuoteCreationAPIRequestWrapper class
 * @AUTHOR : Vinay S Reddy
 * @DATE   : 14-October-2024
 *
 * MODIFICATION LOG:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                             DATE                DESCRIPTION
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vinay S Reddy                       14-Oct-2024            Initial Version.
 * Arquimidez Mora                     15-Nov-2024            Replace 'RequestWrapper' with QuoteCreationAPIRequestWrapper class
 ****************************************************************************************************************************************/

@RestResource(urlMapping = '/CreateQuote')
global with sharing class RestOpportunityQuoteCreationDataReceiver extends ilib_RestReceiver {

    /**
     * @description Method that handles the Request.
     * @author Vinay S Reddy | 14-Oct-2024
     * @param eventData - Structure to parse the request payload data
     **/
    @HttpPost
    global static void handlePostRequest(){
        RestOpportunityQuoteCreationDataReceiver instantiated = new RestOpportunityQuoteCreationDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);
        
        if(Feature.isOn('WebGeneratedQuote') || Test.isRunningTest()){
            
            RestResponse res = RestContext.response;
            
            String strRestError = null;
            Id primaryRecordId;
            String erpCustomerId;
            
            String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));
            ilib_LogEvent.info('JSON Input:\n' + strJsonInput);
            
            ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);
            
            //Savepoint objSavePoint = Database.setSavepoint();
            try{
                new RestOpportunityQuoteCreationValidator().validateSchema(strJsonInput);
                QuoteCreationAPIRequestWrapper incomingPayloadData = (QuoteCreationAPIRequestWrapper) System.JSON.deserialize(strJsonInput, QuoteCreationAPIRequestWrapper.class);
                ilib_LogEvent.message('Incoming Data  '+ incomingPayloadData);
                
                //Always acknowledge the status as received
                UtilsRest.handleCustomRestSuccess();
                CEQWebResquestPlatformEventService.createPlatformEvent(QuoteCreationAPIPESubscriberService.Step.STEP1_QUOTATION_CREATION, strJsonInput);
            }
            catch(RestOpportunityQuoteCreationValidator.InvalidSchemaException e){
                //acknowledge that JSON Violates agreed Contract
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                gen.writeStringField('HttpCode', '400');
                gen.writeStringField('Status', e.getMessage());
                strRestError = e.getMessage();
                res.statusCode = 400;
                res.addHeader('Content-Type', 'application/json');
                res.responseBody = Blob.valueOf(gen.getAsString());
            }
            catch(Exception ex){
                
                strRestError = UtilsRest.handleCustomRestError(ex);
            }
            
            Boolean isSuccess = String.isBlank(strRestError);
            
            ilib_LogInterface.finalizeLog(
                log,
                (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
                (isSuccess ? null : 'Exception: ' + strRestError),
                primaryRecordId
            );
            
            if (!isSuccess) {
                KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);
                ilib_LogEvent.push('upsertIncomingValues');
                ilib_LogEvent.error('Error Description' + strRestError +'----');
                ilib_LogEvent.pop();
            }
            
        } else {
            ilib_LogEvent.info('Feature WebGeneratedQuote is not enabled');
        }
        
        ilib_LogEvent.emit();
    }
    
}
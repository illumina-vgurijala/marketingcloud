/**
 *    @author Kushagra Desai
 *    @date   10-Jan-2020
 *    @description  Reciever class for Agreement Error Interface
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                   Date                  Description
 *    Kushagra Desai          10-Jan-2020             Initial Version
 *    Nesar Mohan             01-April-2022           CodeScan Fix - Code Comments
 *   ---------------------------------------------------------------------------------------------------------------------------
**/
@RestResource(urlMapping='/AgreementValidateErrorInterface/')
global with sharing class ApttusAgreementValidateErrorReciever extends ilib_RestReceiver {

    private static ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper ValidateErrorWrapper;
    /*
    * @Author      : Kushagra Desai
    * @Description : Method to upsert the incoming values
    * @Return      : Void
    * @Param       : None 
    */
    @Httppost
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        ApttusAgreementValidateErrorReciever instantiated = new ApttusAgreementValidateErrorReciever();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);
        String strRestError = null;
        Id primaryRecordId;
        String erpCustomerId;

        String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, ValidateErrorWrapper);

            primaryRecordId = upsertIncomingValuesImpl();
        }
        
        catch (Exception e){
            strRestError = UtilsRest.handleCustomRestError(e);
        }
        
        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
                log,
                (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
                (isSuccess ? null : 'Exception: ' + strRestError),
                primaryRecordId
        );
 
        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);

            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
        }
        ilib_LogEvent.emit();
    }

    private static void deserializeInputs(String jsonInput)
    {
        ValidateErrorWrapper = (ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper) System.JSON.deserialize(jsonInput, ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper.class);
        System.debug('Error Wrapper::::'+ValidateErrorWrapper);
    }
     private static Id upsertIncomingValuesImpl(){
        return ApttusAgreementErrorHandler.checkErrors(ValidateErrorWrapper,Label.AgreementActionInterface);
     }
}
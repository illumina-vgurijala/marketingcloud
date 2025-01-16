/**
 *   @author: Deep Diwakar
*    @date:   23-Sept-2022
*    @description: Interface class to call Pardot Resignation Notification Form Handler
*    @Test Class: TestPardotResignationNtfQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*        Deep Diwakar       23-Sept-2022        PM-911: Initial build
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class PardotResignationNotificationSender extends ilib_RestReceiver {

    private static final String INTERFACE_NAME = 'Pardot_Resignation_FH';
    private static final Integer HTTP_POST_SUCCESS_CODE = 201;
    private static final Integer HTTP_SUCCESS_CODE = 200;

    /**
     * @author: Deep Diwakar
     * @date: 23-Sept-2022
     * @description: callout method to Pardot form handler
     * @param: Contact email id that needs to be passed to Pardot form handler
     * @return: void
     */
    public static void callPardotResignationFormHandler(String contEmail) {
        ilib_LogEvent.push(INTERFACE_NAME + '.callPardotResignationFormHandler()');
        ilib_LogEvent.info('contact email: ' + contEmail);
        PardotResignationNotificationSender instantiated = new PardotResignationNotificationSender();
        ilib_RestInterface.InterfaceDetails interfaceDetailsInstance = instantiated.interfaceDetails;
        Map<String, String> mapInterfaceDetails = UtilsRest.getIntegrationEndpoint(INTERFACE_NAME);
        String encodedEmail = EncodingUtil.urlEncode(contEmail, 'UTF-8');
        String strEndPoint = mapInterfaceDetails.get('Endpoint') + '?email=' + encodedEmail;    
        ilib_LogEvent.info('Encoded URL Full: ' + strEndPoint);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(strEndPoint);
        req.setMethod('POST');
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetailsInstance,strEndPoint);
        HttpResponse response = new Http().send(req);
        ilib_LogEvent.info('response: ' + response);
        if (response.getStatusCode() != HTTP_POST_SUCCESS_CODE && response.getStatusCode() != HTTP_SUCCESS_CODE ) {
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody() +response.getStatusCode()+ ' Email-' + contEmail);
            return;
        }
        ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,response.getStatusCode() + response.getBody()+ ' Email-' + contEmail);
        ilib_LogEvent.pop();
    }
}

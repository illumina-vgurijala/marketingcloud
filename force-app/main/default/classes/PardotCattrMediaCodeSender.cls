/**
 *   @author: Deep Diwakar
*    @date:   March-23-2022
*    @description: DCP-59535 - Interface class to call Pardot Campaign Attribution Form Handler
*    @Test Class: TestPardotResignationNtfQueueable
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*        Deep Diwakar       March-23-2022        DCP-59535: Initial build
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class PardotCattrMediaCodeSender extends ilib_RestReceiver{

    private static final String INTERFACE_NAME = 'Pardot_Cattr_MediaCode_Sync_FH';
    private static final Integer HTTP_POST_SUCCESS_CODE = 201;
    private static final Integer HTTP_SUCCESS_CODE = 200;

    /**
     * @author: Deep Diwakar
     * @date: March-23-2022
     * @description: callout method to Pardot form handler
     * @param: campaign member email id that needs to be passed to Pardot form handler
     * @return: void
     */
    public static void callPardotCattrMediaCodeFormHandler(String campaignMemberEmail, String urlSuffix) {
        ilib_LogEvent.push(INTERFACE_NAME + '.callPardotCattrMediaCodeFormHandler');
        ilib_LogEvent.info('campaign member email: ' + campaignMemberEmail);
        PardotCattrMediaCodeSender instantiated = new PardotCattrMediaCodeSender();
        ilib_RestInterface.InterfaceDetails interfaceDetailsInstance = instantiated.interfaceDetails;
        Map<String, String> mapInterfaceDetails = UtilsRest.getIntegrationEndpoint(INTERFACE_NAME);
        String encodedEmail = EncodingUtil.urlEncode(campaignMemberEmail, 'UTF-8');
        String strEndPoint = mapInterfaceDetails.get('Endpoint') + '?email=' + encodedEmail + urlSuffix;    
        ilib_LogEvent.info('Encoded URL Full: ' + strEndPoint);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(strEndPoint);
        req.setMethod('POST');
        ilib_LogInterface.LogDetails logDetail = ilib_LogInterface.initiateLog(interfaceDetailsInstance,strEndPoint);
        HttpResponse response = new Http().send(req);
        ilib_LogEvent.info('response: ' + response);
        if (response.getStatusCode() != HTTP_POST_SUCCESS_CODE && response.getStatusCode() != HTTP_SUCCESS_CODE ) {
            ilib_LogInterface.finalizeLog(logDetail,ilib_LogInterface.RESULT_FAIL, response.getBody() +response.getStatusCode()+ ' Email-' + campaignMemberEmail);
            return;
        }
        ilib_LogInterface.finalizeLog(logDetail,ilib_LogInterface.RESULT_SUCCESS,response.getStatusCode() + response.getBody()+ ' Email-' + campaignMemberEmail);
        ilib_LogEvent.pop();
    }
}
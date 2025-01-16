/***************************************************************************************************************************************
* NAME         : ETQGetETQNumber
* DESCRIPTION  : Data Sender class to Fetch ETQ Number
* @AUTHOR      : Gladis
* @DATE        : 04-Apr-2022 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Gladis Evangaly        04-Apr-2022         QACM-14/QACM-15 : Initial Version
* --------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/
public with sharing class EtQGetEtQNumberDataSender extends ilib_RestSender {

    private static final String LOG_TITLE = 'EtQGetEtQNumberDataSender';
    public static final String INTERFACE_NAME_GET = 'EtQ_Inbound'; //http "GET" method endpoint : This is required to GET JSON body.
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public final static String STRING_CONTENT_TYPE = 'application/json';
    public static final String AUTHORIZATION = 'Authorization';
    public static final String APIKEY = 'apikey';
    public final static String HTTP_METHOD = 'GET';
    public static final String CUSTOM_URL = '?url=';

    /**
    * hold http actions.
    **/
    public enum HttpMethod {HEAD,GET} 

    /**
    * hold CalloutData.
    **/
    private class CalloutData extends ilib_CalloutData {

    }


    /**
    * this class uses selectors to populate CalloutData
    **/
    protected override ilib_CalloutData retrieveCalloutData() {
        
        CalloutData dataObj = new CalloutData();
        return dataObj;
    }

    /**
     * // this method is the last line of defense to make sure we don't send garbage to
    // the target system.  Some validation will occur before the interface is called
    // but we may allow retriggers by admins so we need these sanity checks here
    // it builds a list of errors which are thrown to the caller
    // NOTE: a return might be a better choice, will think about that for hardening (or handle in ancestor)
    **/
    protected override void validateFields() {
    }


    /**
     *  @DESCRIPTION - Method will return String body in JSON format which will be used in HTTP request method.
     *  @RETURN : String JSON
     **/
    public override String createJSON() {
        return null;
    }

    /**
    *  @AUTHOR Gladis
    *  @DESCRIPTION - QACM-15 - Method to create resource url and is passed to the callout method.
    *  @PARAM : String
    *  @RETURN : EtQResponseWrapper
    **/
    public static EtQResponseWrapper fetchETQNumber(string strUrl) {
        ilib_LogEvent.push(LOG_TITLE + '.fetchETQNumber()');
        ilib_LogEvent.message('strUrl: ' + strUrl); 
        String strInputParamUrl = null;
        EtQResponseWrapper wrpFinalResponse = new EtQResponseWrapper();
        HttpResponse httpResultResponse = null;
        EtQGetEtQNumberDataSender etqDataSender = new EtQGetEtQNumberDataSender();
        try {
            if(String.isNotBlank(strUrl)) {
                String urlEncode = EncodingUtil.urlEncode(strUrl , 'UTF-8');
                strInputParamUrl = CUSTOM_URL+urlEncode;
                httpResultResponse =  etqDataSender.executeCallout(strInputParamUrl);
                wrpFinalResponse = deserializeInputs(httpResultResponse.getBody());
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return wrpFinalResponse;
        } catch(Exception e) { 
            ApexExceptions.emit(LOG_TITLE,e);
            throw new AuraHandledException(LOG_TITLE +'.fetchETQNumber'+ e.getMessage());
        }
    }

    /**
    *  @AUTHOR Gladis
    *  @DESCRIPTION - QACM-15 Method to fetch ETQ Number.
    *               - This Method will make the callout.
    * @PARAM : String
    * @RETURN : HttpResponse
    **/
    public override HttpResponse executeCallout(String strInputParamUrl){

        ilib_LogEvent.push(LOG_TITLE + '.executeCallout()'); 
        HttpRequest request = new HttpRequest(); 
        HttpResponse response = null;
        String strResourceURL = null;
        String strError = null;
        String strId = null;

        try {
            if(String.isNotBlank(strInputParamUrl)) { 
                Interface_Parameters__mdt connectionParameters = UtilsRest.getConnectionParameters(INTERFACE_NAME_GET);
                String strEndPoint = connectionParameters.Endpoint__c;
                strResourceURL = strEndPoint+strInputParamUrl;
                ilib_LogEvent.message('EtqDataSender--strResourceURL: ' + strResourceURL);

                //create Http request
                request.setEndpoint(strResourceURL);
                request.setMethod(HTTP_METHOD);
                request.setHeader(AUTHORIZATION,'Bearer '+connectionParameters.BearerToken__c);
                request.setHeader(APIKEY, connectionParameters.ApiKey__c);
                request.setHeader('Accept','application/json');
                request.setTimeout(120000);
                ilib_LogEvent.message('Http Request ===>: ' + request); 

                //sending the request and capturing the response.
                response = UtilsRest.send(request);  
            }

            //adding response body to the Interface Log Result Details field.
            if(response.getStatusCode() != HTTP_SUCCESS_CODE) {
                ilib_LogInterface.finalizeLog(getInterfaceLog(strResourceURL),ilib_LogInterface.RESULT_FAIL, response.getBody(), strId, response);
            } else {
                ilib_LogInterface.finalizeLog(getInterfaceLog(strResourceURL),ilib_LogInterface.RESULT_SUCCESS, response.getBody(), strId, response);
            }

            if ((null != response) && (!String.isBlank(response.getBody()))) {
                handleResult(response);
            }
        } catch (Exception e) {
            strError = e.getMessage() + '\n' + e.getStackTraceString();
            ilib_LogEvent.message('Exception--strError:' + strError);
            ApexExceptions.emit(LOG_TITLE,e);
            throw new AuraHandledException(LOG_TITLE +'--executeCallout:'+ e.getMessage());
        }
        return response;  
    }

    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION - Initiate log object record.
    *  @PARAM : String 
    *  @RETURN : ilib_LogInterface.LogDetails
    **/
    private static ilib_LogInterface.LogDetails getInterfaceLog(String strResourceURL) {
            
        String interfaceName;
        ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(LOG_TITLE);
        interfaceName = interfaceDetails.name;

        //Interface Log
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(interfaceName, interfaceDetails.direction, interfaceDetails.objectType);
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(intDetails);
        ilib_LogInterface.addJsonToLog(log,strResourceURL);
        return log;

    }

    /**
    *  @AUTHOR Gladis
    *  @DESCRIPTION - Deserilize the response into wrapper
    *  @PARAM : String 
    *  @RETURN : EtQResponseWrapper
    **/
    private static EtQResponseWrapper deserializeInputs(String jsonInput) {

        ilib_LogEvent.push(LOG_TITLE + '.deserializeInputs()');
        ilib_LogEvent.message('jsonInput: ' + jsonInput);
        EtQResponseWrapper wrapResponse = new EtQResponseWrapper();
        wrapResponse = (EtQResponseWrapper) System.JSON.deserialize(jsonInput, EtQResponseWrapper.class); 
        ilib_LogEvent.message('wrapResponse: ' + wrapResponse);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return wrapResponse;
    }

    /**
     *  @AUTHOR Gladis
     *  @DESCRIPTION -Overriden method from interface
     **/
    protected override void handleResult(HTTPResponse res) {
        ilib_LogEvent.message('res: ' + res);
    }
}
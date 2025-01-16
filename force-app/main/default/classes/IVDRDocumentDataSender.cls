/***************************************************************************************************************************************
* NAME         : IVDRDocumentDataSender
* DESCRIPTION  : CMCP-110 :IVDR Document Search Data Sender Class (Inbound to SAP)
*                    
* @AUTHOR      : Gladis
* @DATE        : 10-Dec-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Gladis Evangaly        10-Dec-2021         CMCP-110: Initial Version
* --------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/
public with sharing class IVDRDocumentDataSender extends ilib_RestSender {
    
    private static final String LOG_TITLE = 'IVDRDocumentDataSender';
    public static final String INTERFACE_NAME_GET = 'Outgoing_IVDRDocument_GET'; //http "GET" method endpoint : This is required to GET JSON body from SAP.
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public final static String STRING_CONTENT_TYPE = 'application/json';
    public final static String HTTP_METHOD = 'GET';
    public final static String IVDR_DOWNLOAD_INTERFACE = 'IVDR Document Download Interface';
    public static final String IVDR_DOC_SET = 'IVDRDocSet';
    

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
     *  @DESCRIPTION - CMCP-110 Method to fetch the Sales Order Details.
     *               - This Method will make the callout to SAP.
     * @PARAM : String
     * @RETURN : HttpResponse
     **/
    public override HttpResponse executeCallout(String strCalloutWrapper) {

        ilib_LogEvent.push(LOG_TITLE + '.executeCallout()');
        HttpResponse response = null; 
        String strResourceURL = null;
        String strError = null;
        String strInputParamUrl = null;
        String strId = null;
        List<IVDRDocumentSearchController.calloutWrapper> calloutWrapperList = new List<IVDRDocumentSearchController.calloutWrapper>();
        Map<String, String> headerKeyToValue = new Map<String, String>{
            'Content-Type' => STRING_CONTENT_TYPE,
            'accept' => STRING_CONTENT_TYPE
        };
        
        try {
            if(String.isNotBlank(strCalloutWrapper)) { 
               
                calloutWrapperList = (List<IVDRDocumentSearchController.calloutWrapper>) System.JSON.deserialize(strCalloutWrapper, List<IVDRDocumentSearchController.calloutWrapper>.class);
                if(!calloutWrapperList.isEmpty()) {
                    strInputParamUrl = calloutWrapperList[0].strInputParamUrl;
                    strId = calloutWrapperList[0].strId;
                }

                Interface_Parameters__mdt connectionParameters = UtilsRest.getConnectionParameters(INTERFACE_NAME_GET);
                String strEndPoint = connectionParameters.Endpoint__c;
                strResourceURL = strEndPoint+strInputParamUrl;
                ilib_LogEvent.message('DataSender--strResourceURL: ' + strResourceURL);
                
                //sending the request and capturing the response.
                HttpRequest request = UtilsRest.createHttpRequest(INTERFACE_NAME_GET, strResourceURL , HTTP_METHOD, headerKeyToValue);
                response = UtilsRest.send(request);
                
                //adding response body to the Interface Log Result Details field.
                if(response.getStatusCode() != HTTP_SUCCESS_CODE) {
                    ilib_LogInterface.finalizeLog(getInterfaceLog(strResourceURL),ilib_LogInterface.RESULT_FAIL, response.getBody(), strId, response);
                } else {
                    ilib_LogInterface.finalizeLog(getInterfaceLog(strResourceURL),ilib_LogInterface.RESULT_SUCCESS, response.getBody(), strId, response);
                }

                if ((null != response) && (!String.isBlank(response.getBody()))) {
                    handleResult(response);
                }
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
        Boolean booIvdrDocSet = strResourceURL.contains(IVDR_DOC_SET);
        ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(LOG_TITLE);
        if(booIvdrDocSet == true) {
            interfaceName = IVDR_DOWNLOAD_INTERFACE;
        } else {
            interfaceName = interfaceDetails.name;
        }

        //Interface Log
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(interfaceName, interfaceDetails.direction, interfaceDetails.objectType);
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(intDetails);
        ilib_LogInterface.addJsonToLog(log,strResourceURL);
        return log;
    
    }

    /**
     *  @AUTHOR Gladis
     *  @DESCRIPTION -Overriden method from interface
     **/
    
    protected override void handleResult(HTTPResponse res) {
        ilib_LogEvent.message('res: ' + res);
    }
}
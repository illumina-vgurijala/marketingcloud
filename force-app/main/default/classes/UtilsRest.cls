/**
*    @Author: Todd Newman
*    @Date:   2018-05-12
*    @Description:  This class is for storing the generic methods related to integration.
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2018-05-12           Initial Version
          Nesar Mohan                 2022-03-31           CodeScan Fix - Add code comments
          Pooja                       2022-12-14           DCP-56196 : Created new Utility method to update interface log record    
*    --------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class UtilsRest {

    public static final String APEX_SOAP_WEBSERVICE_VERSION = '46.0';
    public static final String APEX_WEBSERVICE_VERSION = 'v'+APEX_SOAP_WEBSERVICE_VERSION;
    public static final Integer REST_SUCCESS = 200;
    public static final Integer REST_ERROR = 412;
	public static final Integer REST_ERROR_LOCKROW = 503;
    public static final Integer TOKENEXPIRESINMINUTES = 2;
    public static final Integer TOKENEXPIRESINSECS = (TOKENEXPIRESINMINUTES * 60);
    public static final Integer TOKENEXPIRESINMS = (TOKENEXPIRESINMINUTES * 60 * 1000);
	public static final String RETRYEXCEPTIONS = 'Retry_Exceptions';
	public static final String APPLICATIONJSON = 'application/json';
    public static final String CONTENTTYPE = 'Content-Type';
    public static final Set<String> SET_CLASS_NAME_FOR_LOCK_ROW = new Set<String>{'EquipmentMasterDataReceiver','WorkOrderDataReceiver','InventoryDataReceiver'};//56196
    
    /**
     * Method:getIntegrationEndpoint
     * Description: method is to get the end point based on the interation name.
     * params: Integration Name
     * return: Map<String, String>
     */
    public static Map<String, String> getIntegrationEndpoint(String strIntegrationName)
    {
        Interface_Parameters__mdt connectionParameters = getConnectionParameters(strIntegrationName);
        return new Map<String, String> { 'Endpoint' => connectionParameters.Endpoint__c, 'ApiKey' => connectionParameters.ApiKey__c, 'Authorization' => 'Bearer '+connectionParameters.BearerToken__c,'NamedCredentials' =>connectionParameters.Named_Credential__c,
                                         'Header Token' => connectionParameters.Header_Token__c};
    }
    /**
     * Method:createHttpRequest
     * Description: method is to create the HTTP Request.
     * params: end point, apikey, authorization
     * return: HttpRequest
     */
    public static HttpRequest createHttpRequest(String endpoint, String apikey, String authorization)
    {
       return createHttpRequest(endpoint, apikey, authorization, '', 'POST');
    }
// Vishn to add the parameters being passed
    /**
     * Method:createHttpRequest
     * Description: method is to create the HTTP Request.
     * params: end point, apikey, authorization, Header Token, methodName
     * return: HttpRequest
     */
    public static HttpRequest createHttpRequest(String endpoint, String apikey, String authorization, string headerToken, string methodName)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(methodName);
        if(String.isNotBlank(headerToken)){
            req.setHeader('ORSUS', headerToken);
        }
        else{
            req.setHeader('Authorization', authorization);
        }
        req.setHeader('apikey', apikey);
        req.setHeader('Accept', APPLICATIONJSON);
        req.setHeader(CONTENTTYPE, APPLICATIONJSON);
        System.debug('req:'+ req);
        return req;
    }
    /**
     * Method:createHttpRequest
     * Description: method is to create the HTTP Request.
     * params: strIntegrationName, strMethod, headerKeyToValue
     * return: HttpRequest
     */
    public static HttpRequest createHttpRequest(String strIntegrationName, String strMethod, Map<String, String> headerKeyToValue)
    {
        Interface_Parameters__mdt connectionParameters = getConnectionParameters(strIntegrationName);
        String strNamedCredential = connectionParameters.Named_Credential__c;
        String strResourceURL = connectionParameters.Endpoint__c;
        String strAPIKey = connectionParameters.ApiKey__c;

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:'+strNamedCredential+strResourceURL);
        request.setMethod(strMethod);
        request.setHeader('apikey', strAPIKey);
        for (String headerKey: headerKeyToValue.keySet())
        {
            request.setHeader(headerKey, headerKeyToValue.get(headerKey));
        }

        return request;
    }
    
	/*
    * @author Kushagra Desai
    * @Description Request creation with Bearer token SNAP integration
    * @param Integration Details
    * @return Response
    */
    public static HttpRequest createHttpRequest(String strIntegrationName, String strMethod, Map<String, String> headerKeyToValue,String strJSON)
    {
        Interface_Parameters__mdt connectionParameters = getConnectionParameters(strIntegrationName);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(connectionParameters.Endpoint__c);
        request.setMethod(strMethod);
        request.setHeader('Authorization','Bearer '+connectionParameters.BearerToken__c);
        request.setHeader('apikey',connectionParameters.ApiKey__c);
        for (String headerKey: headerKeyToValue.keySet())
        {
            request.setHeader(headerKey, headerKeyToValue.get(headerKey));
        }
        request.setBody(strJSON);
        request.setTimeout(120000);
        return request;
    }
	
	/*    
    * @Description: To send the request
    * @param: HttpRequest
    * @return: HttpRequest
    */
    public static HttpResponse send(HttpRequest request)
    {
        System.debug('request: ' + request);
        Http httpObj = new Http();
        HTTPResponse res = httpObj.send(request);
        System.debug(LoggingLevel.INFO, '\nHttpResponse======>\n' + res.toString() + '\n');
        return res;
    }
	
	/*
     *  @AUTHOR: Maruthi
     *  @DESCRIPTION: Method to return Sandbox value
     *  @RETURN: Boolean   
    */
    public static Boolean sandboxValue() {
        return [SELECT IsSandbox FROM Organization LIMIT 1][0].IsSandbox;
    }
	
	/*
     *  @DESCRIPTION: getConnectionParameters
     *  @RETURN: String   
    */
    public static Interface_Parameters__mdt getConnectionParameters(String strIntegrationName) {
		//Added as part of PM-22
        Boolean isSandbox = sandboxValue();
        String sandboxPostfix = isSandbox ? '_SANDBOX' : '';
        String developerName = strIntegrationName + sandboxPostfix;

        List<Interface_Parameters__mdt> listParameters =
            [SELECT Id, DeveloperName, ApiKey__c, Endpoint__c, Named_Credential__c, BearerToken__c, Header_Token__c
             FROM Interface_Parameters__mdt
             WHERE DeveloperName = :developerName];

        if (listParameters.isEmpty()){
			throw new InterfaceException('No integration parameter metadata exists for ' + developerName);
		}
            

        return listParameters.get(0);
    }
	
	/*
     *  @DESCRIPTION: handleCustomRestError
     *  @RETURN: Exception   
    */
    public static String handleCustomRestError(Exception e)
    {
        System.debug('ILMN: exception occurred ' + e);
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('Result', 'Error');
        gen.writeStringField('ErrorDetail', e.getMessage());

        RestContext.response.statusCode = REST_ERROR;
        RestContext.response.addHeader(CONTENTTYPE, APPLICATIONJSON);
        RestContext.response.responseBody = Blob.valueOf(gen.getAsString());
        String errMsg = e.getMessage() + '\n' + e.getStackTraceString();
        System.debug('ILMN: exception occurred ' + errMsg);
        return errMsg;
    }
	
	/*
    * @author Raviteja Vakkalagadda
    * @date   10-03-2022
    * @description  Method to handle and return the custom code accordingly
    * @param Exception
    * DCP-51717
*/

    public static String handleRetryCustomRestError(Exception e)
    {
        
        String queueException = '';
        queueException = String.valueOf(e);
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('Result', 'Error');
        gen.writeStringField('ErrorDetail', e.getMessage());

        retryExceptionHandling(queueException);
        RestContext.response.addHeader(CONTENTTYPE, 'application/json');
        RestContext.response.responseBody = Blob.valueOf(gen.getAsString());
        String errMsg = e.getMessage() + '\n' + e.getStackTraceString();
        
        return errMsg;
    }

/*
    * @author Raviteja Vakkalagadda
    * @date   10-03-2022
    * @description  Method to handle the logic for reusability 
    * @param Exception
    * DCP-51717
*/
    public static void retryExceptionHandling(String queueException){

        Set<String> setCodeParamName=new Set<String>{RETRYEXCEPTIONS};
        List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(setCodeParamName);
        if(!Test.isRunningTest() && !lstCodeParam.isEmpty() && queueException.contains(lstCodeParam[0].value__c)){
            RestContext.response.statusCode = REST_ERROR_LOCKROW;
        }
        else{
            RestContext.response.statusCode = REST_ERROR;
        }
    }
	
	/*
     *  @DESCRIPTION: handleCustomRestSuccess
     *  @RETURN: void   
    */
    public static void handleCustomRestSuccess()
    {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('Result', 'Success');
        gen.writeStringField('ErrorDetail', '');

        RestContext.response.statusCode = REST_SUCCESS;
        RestContext.response.addHeader(CONTENTTYPE, APPLICATIONJSON);
        RestContext.response.responseBody = Blob.valueOf(gen.getAsString());
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Custom Exception class
    */

    public class InterfaceException extends Exception { }
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to convert String to DateTime
    *  @Param       : String
    *  @Return      : DateTime
    */
    public  DateTime stringToDateTimeConversion(String dateTimeString)
    {
        //if(dateTimeString!='')
           return datetime.valueOf(dateTimeString+' 00:00:00');
    }
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to convert String to Boolean
    *  @Param       : String
    *  @Return      : Boolean
    */
    public  Boolean stringToBooleanConversion(String booleanString)
    {
        return (booleanString == 'Y' ? true : false);
    }
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to convert String to Decimal
    *  @Param       : String
    *  @Return      : Decimal
    */
    public  Decimal stringToDecimalConversion(String decimalString)
    {
        return Decimal.valueof(String.valueof(decimalString));
    }

    /*
     * @Author: Sravan Panchangam
     * @Description: String to Date format Conversion for DCP-11857 (Conversion from YYYYMMDD to YYYY-MM-DD)
    */
    public DateTime stringTODateTimeFormatConversion(String dateTimeString)
    {
        if (dateTimeString!=null  &&  dateTimeString.length()==8)
        {
            String year=dateTimeString.substring(0, 4);
            String month=dateTimeString.substring(4,6);
            String day=dateTimeString.substring(6);
            String format=year+'-'+month+'-'+day;
            DateTime dateTimeValue=this.stringToDateTimeConversion(format);
            return dateTimeValue;
        }
        return null;
    }
    /*
    * @author Kushagra Desai
    * @Description Request creation with dynamic Resource URL
    * @param Integration Details
    * @return Response
    */
    public static HttpRequest createHttpRequest(String strIntegrationName,String strResourceURL,String strMethod, Map<String, String> headerKeyToValue)
    {
        Interface_Parameters__mdt connectionParameters = getConnectionParameters(strIntegrationName);
        String strNamedCredential = connectionParameters.Named_Credential__c;
        String strAPIKey = connectionParameters.ApiKey__c;

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:'+strNamedCredential+strResourceURL);
        request.setMethod(strMethod);
        request.setHeader('apikey', strAPIKey);
        request.setTimeout(120000);
        for (String headerKey: headerKeyToValue.keySet())
        {
            request.setHeader(headerKey, headerKeyToValue.get(headerKey));
        }

        return request;
    }

    /**
    *  @author Pankaj Sharma
    *  @Convert String to Number having commas
    *  @param String
    *  @return Decimal
    **/
    public static Decimal convertStringToNumber(String strNumber)
    {
        if (strNumber != null)
        {
            String strDecimalNumber;
            if (strNumber.contains(',') || strNumber.contains('-'))
            {
                strDecimalNumber = strNumber.replace(',','');
                strDecimalNumber = strDecimalNumber.replace('-','');
                return (String.isBlank(strDecimalNumber) ? 0 : Decimal.valueOf(strDecimalNumber));
            }
            else
            {
                return (String.isBlank(strNumber) ? 0 : Decimal.valueOf(strNumber));
            }
        }
        else
            return null;
    }
     /**
    * @description : To update "HTTP_Result_Code__c" field on Interface log  for unable to lock row issue DCP-56196/ DCP-51717
    * @author :Pooja
    **/
    public static void updateHttpResultCodeForRetry(String logInterfaceId,string logTitle){

        //DCP-51717
        if (logInterfaceId != '' && SET_CLASS_NAME_FOR_LOCK_ROW.contains(logTitle)) {
           Set<String> setCodeParamName=new Set<String>{'Retry_Exceptions'};
           List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(setCodeParamName);
           Interface_Log__c logRec = [SELECT Id,Result_Details__c,HTTP_Result_Code__c FROM Interface_Log__c WHERE Id =: logInterfaceId][0];
           if (!Test.isRunningTest() && logRec != null && !String.isBlank(logRec.Result_Details__c) && logRec.Result_Details__c.contains(lstCodeParam[0].value__c)) {
                   logRec.HTTP_Result_Code__c = UtilsRest.REST_ERROR_LOCKROW;
                   UPDATE logRec;
               }
       }
   }
    /**
    * @description : Create Http request for sending outbound messages
    * @author : Vishal
    **/
    public static HttpRequest createHttpRequestIP(String strIntegrationName, String strMethod, String strJSON){
		Interface_Parameters__mdt connectionParameters = getConnectionParameters(strIntegrationName);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(connectionParameters.Endpoint__c);
        request.setMethod(strMethod);
		request.setHeader(CONTENTTYPE, 'application/json');
		request.setBody(strJSON);
        request.setTimeout(120000);
        return request;
	 
 }
}
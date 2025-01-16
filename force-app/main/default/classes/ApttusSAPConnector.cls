/*
 * @Author: Kushagra Desai
 * @Date: 
 * @Description :Connector class to create HTTP request
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Kushagra Desai            23-APR-2019                 Implemented org session cache for storing HEAD call header
* Kushagra Desai            10-Dec-2019                 DCP-31676 - Adding Agreement Interface 
* Kushagra Desai            16-Jan-2019                 DCP-32815 - Reverted changes made as part of DCP-31676
* Aman Tyagi                31-Mar-2022                 Codescan Fixes
* Prem Ranjan               20-Feb-2023                 CodeScan Fixes (APEX) Variable Naming Conventions
 */
public with sharing class ApttusSAPConnector {

    /*
    * @Author: Kushagra Desai
    * @Description :enum type Http method
    * @return: enum
    */
    public enum HttpMethod {HEAD, POST}
    public static final String INTEGRATION_NAME = 'Outgoing_Realtime_Pricing';
    public static final String INTEGRATION_NAME_RTP = 'Outgoing_Realtime_PricingCheck';
    public static final String INTEGRATION_NAME_COGS = 'Get_COGS_For_Margin_Data';
    public static final String INTEGRATION_NAME_CATALYST = 'Catalyst_Pricing_Guidance';
    public static final String VALIDATEHEADER = 'ValidateHeader';
    public static final String RTPHEADER = 'RTPHeader';
    public static Map<String, String> mapResponseHeader = new Map<String, String>();
    public static final String CODEPARAMETER = 'API_Token_Expiry';
    public static final Integer HTTP_POST_AUTHORIZE_FAIL = 403;
    public static Boolean bolRetryFlag = true;
    public static Boolean bolTestRetryFlag = false;

    /*
    * @Author: Kushagra Desai
    * @Description :static method for getting price 
    * @param : String strRequestJSON, Boolean bolDirectSalesToUC
    * @return: HttResponse
    */   
    public static HttpResponse getPrice(String strRequestJSON, Boolean bolDirectSalesToUC)
    {
        ilib_LogEvent.push('updateProductConfig');

        HttpResponse authResponse;
        HttpResponse response;

        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.DCPSessionVariables');
        if (bolDirectSalesToUC)
        {
            if (orgPart.contains(RTPHEADER) && bolRetryFlag)
            {
                ilib_LogEvent.message('Inside IF RTPToken');
                mapResponseHeader = (Map<String,String>)orgPart.get(RTPHEADER);
            }
            else
            {
                ilib_LogEvent.message('Inside ELSE RTPHeader');
                authResponse = authenticate(bolDirectSalesToUC);
                setHeaderValues(RTPHEADER, authResponse, orgPart);
            }
        }
        else
        {
            if (orgPart.contains(VALIDATEHEADER) && bolRetryFlag)
            {
                ilib_LogEvent.message('Inside IF ValidateHeader');
                mapResponseHeader = (Map<String,String>)orgPart.get(VALIDATEHEADER);
            }
            else
            {
                ilib_LogEvent.message('Inside ELSE ValidateHeader');
                authResponse = authenticate(bolDirectSalesToUC);
                setHeaderValues(VALIDATEHEADER, authResponse, orgPart);
            }
        }

        Map<String, String> headerKeyToValue = new Map<String, String>{
            'x-csrf-token' => mapResponseHeader.get('csrfToken'),
            'content-type' => 'application/json',
            'cookie' => mapResponseHeader.get('cookie'),
            'accept' => 'application/json'
        };

        if (Test.isRunningTest())
        {
            headerKeyToValue.put('x-csrf-token','XRTSGD');
            headerKeyToValue.put('cookie','SAP_SESSIONID_GPD_100=mO8EaMo-Pau05qhnxumQ1BBwJENk4RHpgOgAUFa3Pfw%3d; path=/;sap-usercontext=sap-client=100; path=/');
        }
        ilib_LogEvent.message('Map of headerkey--> '+headerKeyToValue);

        String body = strRequestJSON;
        ilib_LogEvent.message('***---++ '+HttpMethod.POST.name());

        HttpRequest request = bolDirectSalesToUC ? UtilsRest.createHttpRequest(INTEGRATION_NAME_RTP, HttpMethod.POST.name(), headerKeyToValue) : UtilsRest.createHttpRequest(INTEGRATION_NAME, HttpMethod.POST.name(), headerKeyToValue);
        request.setBody(body);
        request.setTimeout(120000);

        if (Test.isRunningTest())
        {
            if(bolTestRetryFlag)
                response = new MockApttusSAPConnector().respondAuthError(request);
            else if(!bolDirectSalesToUC)
                response =  new MockApttusSAPConnector().respond(request);
            else
                response =  new MockApttusSAPConnector().respondDirectUC(request);
        }
        else
        {
            response = UtilsRest.send(request);
        }
        //ilib_LogEvent.message('Response Body-- '+ response.getBody());

        if (response.getStatusCode() == HTTP_POST_AUTHORIZE_FAIL && bolRetryFlag)
        {
            bolRetryFlag = false;
            getPrice(strRequestJSON, bolDirectSalesToUC);
        }

        ilib_LogEvent.pop();
        return response;
    }

    /*
    * @Author: Pradeep Landge
    * @Description :static method for getting COGS 
    * @param : String strRequestJSON
    * @return: HttResponse
    */   
    public static HttpResponse getCOGS(String strRequestJSON) {
        ilib_LogEvent.push('getCOGS');

        HttpResponse response;
        HttpResponse authResponse;
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.DCPSessionVariables');
        if (orgPart.contains(VALIDATEHEADER) && bolRetryFlag) {
            ilib_LogEvent.message('Inside IF ValidateHeader');
            mapResponseHeader = (Map<String, String>) orgPart.get(VALIDATEHEADER);
        } else {
            ilib_LogEvent.message('Inside ELSE ValidateHeader');
            authResponse = authenticate(false);
            setHeaderValues(VALIDATEHEADER, authResponse, orgPart);
        }

        Map<String, String> headerKeyToValue = new Map<String, String>{
            'x-csrf-token' => mapResponseHeader.get('csrfToken'),
            'content-type' => 'application/json',
            'cookie' => mapResponseHeader.get('cookie'),
            'accept' => 'application/json'
        };

        if (Test.isRunningTest())
        {
            headerKeyToValue.put('x-csrf-token','XRTSGD');
            headerKeyToValue.put('cookie','SAP_SESSIONID_GPD_100=mO8EaMo-Pau05qhnxumQ1BBwJENk4RHpgOgAUFa3Pfw%3d; path=/;sap-usercontext=sap-client=100; path=/');
        } 

        String body = strRequestJSON;

        HttpRequest request = UtilsRest.createHttpRequest(INTEGRATION_NAME_COGS, HttpMethod.POST.name(), headerKeyToValue);
        request.setBody(body);
        request.setTimeout(120000);

        response = !Test.isRunningTest() ? UtilsRest.send(request) : new MockCOGSResponse().respond(request);

        ilib_LogEvent.message('Response Body-- ' + response.getBody());
        if (response.getStatusCode() == HTTP_POST_AUTHORIZE_FAIL && bolRetryFlag) {
            bolRetryFlag = false;
            getCOGS(strRequestJSON);
        }
        ilib_LogEvent.pop();
        return response;
    }

    /**
    *  @author Kushagra Desai
    *  @description Add API call header value to org session cache
    *  @param Boolean Direct sales to UC flag, HTTP response from HEAD call
    *  @return void
    **/
    private static void setHeaderValues(String callType,HttpResponse authResponse,Cache.OrgPartition orgPart)
    {
        List<Code_Parameter__mdt> codeParameter = [SELECT Id, DeveloperName, Value__c FROM Code_Parameter__mdt WHERE DeveloperName =: CODEPARAMETER];
        String cookie = authResponse.getHeader('set-cookie');
        if (cookie !=null && cookie.indexOf(';') > -1)
        {
            mapResponseHeader.put('cookie',cookie.substring(0, cookie.indexOf(';')));
            mapResponseHeader.put('csrfToken',authResponse.getHeader('x-csrf-token'));
        }
        orgPart.put(callType,mapResponseHeader, Integer.valueOf(codeParameter[0].Value__c), Cache.Visibility.ALL, true);
    }

    private static HttpResponse authenticate(Boolean bolDirectSalesToUC)
    {
        Map<String, String> headerKeyToValue = new Map<String, String>{
            'content-type' => 'application/json',
            'X-CSRF-TOKEN' => 'Fetch',
            'accept' => 'application/json'
        };

        HttpRequest request = bolDirectSalesToUC ? UtilsRest.createHttpRequest(INTEGRATION_NAME_RTP, HttpMethod.HEAD.name(), headerKeyToValue) : UtilsRest.createHttpRequest(INTEGRATION_NAME, HttpMethod.HEAD.name(), headerKeyToValue);
        request.setTimeout(120000);
        if (Test.isRunningTest())
        {
            if (!bolDirectSalesToUC)
                return new MockApttusSAPConnector().respond(request);
            else
                return new MockApttusSAPConnector().respondDirectUC(request);
        }
        else
        {
            return UtilsRest.send(request);
        }
    }
    /*
    * @Author: Rahul
    * @date: 09-Apr-2019
    * @Description :static method for apttus catalyst integration 
    * @param : String strRequestJSON
    * @return: HttResponse
    */
    public static HttpResponse getCatalystDiscount(String strRequestJSON)
    {
        ilib_LogEvent.push('getCatalystDiscount');

        Map<String, String> headerKeyToValue = new Map<String, String>{
            'content-type' => 'application/json'
            ,'accept' => 'application/json'
        };
        ilib_LogEvent.message('Map of headerkey--> '+headerKeyToValue);

        String body = strRequestJSON;
        HttpRequest request = UtilsRest.createHttpRequest(INTEGRATION_NAME_CATALYST, HttpMethod.POST.name(), headerKeyToValue);

        String username = '{!$Credential.UserName}';
        String password = '{!$Credential.Password}';
        request.setHeader( 'username',username);
        request.setHeader('password',password);
        request.setBody(body);
        request.setTimeout(30000);

        HttpResponse response;

        if (Test.isRunningTest())
        {
            ilib_LogEvent.message('Entering test mock method');
            response = new ApttusCatalystDiscountMock().respond(request);
        }
        else
        {
            response = UtilsRest.send(request);
        }
        ilib_LogEvent.message('Response Body-- '+ response.getBody());

        ilib_LogEvent.pop();
        return response;
    }     

}
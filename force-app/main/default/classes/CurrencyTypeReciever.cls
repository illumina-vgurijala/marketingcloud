/*
 * @Author: Rishab Wali
 * @Date: 17-MAR-2019
 * @Description :Connector class to create HTTP request for Updating Currency Type Record Update (DCP -32959)
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rishab Wali            17-MAR-2019                   Web Service Development for Currency Conversion Rate Updates and then Callout to 
                                                       Internal Salesforce API for updating the values.
* Nishan Shetty          22-April-2022                 CodeScan Fix-Avoid Literals in If condition               
* Jitesh Lakhwani        6-July-2022                   Code Scan fixes of Comments                               
*************************************************************************************************************************************************
 */


@RestResource(urlMapping='/CurrencySyncInterface/')
global without sharing class CurrencyTypeReciever extends ilib_RestReceiver {

    public static final String CURRENCYTYPE = 'CurrencyType';
    public static final String EXCEPTIONMESSAGE = 'Input JSON is missing';
    public static final STring HTTPMETHODPOST = 'POST';

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_STATUS_CODE_200 = 200;
    //End CodeScan Fix

    /**
    * @description: Method for Currency Conversion Rate Updates
    * @param : String searchKey, String objectName, String searchField
    * @return: List<SObject>
    */
    @HttpPatch
    global static void getCurrencyRecordIdsByCodes() {
        
        RestRequest request = RestContext.request;
        if(String.isBlank(request.requestBody.toString()))
        {
            throw new UtilsRest.InterfaceException(EXCEPTIONMESSAGE);
        }
        List<WrapData> wrapperDataList = (List<WrapData>)JSON.deserialize(request.requestBody.toString(),List<WrapData>.class);      
        
        System.debug('wrapperDataList --- ' + wrapperDataList); 
        
        Map<String,WrapData> currenyCodeToWrapDataMap = new Map<String,WrapData>(); 
        Map<Id,WrapData> currencyIdTowrapDataMap = new Map<Id,WrapData>();
        
        if(wrapperDataList.size() > 0)
        {
            for(WrapData wrp : wrapperDataList)
            {
                currenyCodeToWrapDataMap.put(wrp.IsoCode,wrp);
            }
        }
        
        if(currenyCodeToWrapDataMap.size() > 0)
        {
            CurrencyCodesSelector currncySelector = new CurrencyCodesSelector();
            List<CurrencyType> currencyTypeList = currncySelector.getCurrencyTypeRecordsFromIsoCodes(currenyCodeToWrapDataMap.keySet());
            
            if(currencyTypeList.size() > 0)
            {
                for(CurrencyType currncy : currencyTypeList)
                {
                    if(currenyCodeToWrapDataMap.containsKey(currncy.IsoCode))
                        currencyIdTowrapDataMap.put(currncy.Id,currenyCodeToWrapDataMap.get(currncy.IsoCode));
                }
            } 
        }
        
        JSONGenerator currncyGeneratorJSON = JSON.createGenerator(true);    
        currncyGeneratorJSON.writeStartObject();
        currncyGeneratorJSON.writeFieldName('records');
        
        currncyGeneratorJSON.writeStartArray(); //for loop starts from here
        for(Id str : currencyIdTowrapDataMap.keySet())
        {
            currncyGeneratorJSON.writeStartObject();
            currncyGeneratorJSON.writeFieldName('attributes');
            currncyGeneratorJSON.writeStartObject();
            currncyGeneratorJSON.writeStringField('type', CURRENCYTYPE); 
            currncyGeneratorJSON.writeEndObject();
            if(currencyIdTowrapDataMap.get(str).ConversionRate != '' && currencyIdTowrapDataMap.get(str).ConversionRate != null)
            currncyGeneratorJSON.writeNumberField('ConversionRate',Decimal.valueOf(currencyIdTowrapDataMap.get(str).ConversionRate));
            if(currencyIdTowrapDataMap.get(str).DecimalPlaces != '' && currencyIdTowrapDataMap.get(str).DecimalPlaces != null)
            currncyGeneratorJSON.writeNumberField('DecimalPlaces',Integer.valueOf(currencyIdTowrapDataMap.get(str).DecimalPlaces));
            currncyGeneratorJSON.writeIdField('Id',str);
            currncyGeneratorJSON.writeEndObject();
        }
        currncyGeneratorJSON.writeEndArray();
        currncyGeneratorJSON.writeEndObject();
        
        String JSONString = currncyGeneratorJSON.getAsString();
        System.debug('JSON String ----- ' + JSONString);    

        //Interface Log
        ilib_RestInterface.interfaceDetails interfaceDetails = new CurrencyTypeReciever().interfaceDetails;
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, JSONString);

        ilib_LogInterface.addJsonToLog(log,JSONString);
        
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String restApiUrl = baseUrl + '/services/data/v48.0/composite/sobjects/?_HttpMethod=PATCH';
        Http objHttp = new Http();
        HttpRequest objHttpRequest = new HttpRequest();
        objHttpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        objHttpRequest.setEndpoint(restAPIURL);
        objHttpRequest.setMethod(HTTPMETHODPOST);
        objHttpRequest.setBody(JSONString);
        objHttpRequest.setHeader('content-type','application/json');
        objHttpRequest.setHeader('accept','application/json');
        objHttpRequest.setTimeout(120000);
        if(!test.isRunningTest())
        {
            HttpResponse objHttpResponse = objHttp.send(objHttpRequest);
            
            if(objHttpResponse.getStatusCode() == INTEGER_STATUS_CODE_200)
            {
                //Finalize Interface Log Success
                ilib_LogInterface.finalizeLog(log, InterfaceLog.RESULT_SUCCESS, objHttpResponse.getBody(), null, objHttpResponse);
            }
            else
            {
                //Finalize Interface Log Failure
                ilib_LogInterface.finalizeLog(log, InterfaceLog.RESULT_FAIL, objHttpResponse.getBody(), null, objHttpResponse);
            }
        }
    }
    
    /**
    * @description: Wrappper class used in above method 'getCurrencyRecordIdsByCodes'
    * @param : None
    * @return: None
    */
    public class WrapData
    {
        public string IsoCode;
        public String ConversionRate;
        public String DecimalPlaces;
    }
    
}
/***************************************************************************************************************************************
* NAME         : IVDRDocumentSearchController
* DESCRIPTION  : Sending the Sales order and Date information to fetch the data from SAP
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
public with sharing class IVDRDocumentSearchController {

    private static final String LOG_TITLE = 'IVDRDocumentSearchController';
    public final static String PARTNER_FN = 'AG';
    public final static String START_TIME = 'T00:00:00';
    public final static String END_TIME = 'T11:59:59';
    public static final String ORDER_DETAILS_SET = 'OrderDetailSet?$filter=';
    public static final String IVDR_DOC_SET = 'IVDRDocSet';

    
    /**
    *  @AUTHOR Gladis
    *  @RETURN Boolean
    *  @DESCRIPTION Checks if the current user is Channel Partner
    **/
    @AuraEnabled 
    public static Boolean checkCPProfile() {
        ilib_LogEvent.push(LOG_TITLE + '.checkCPProfile()');
        Boolean res = false;
        try {
            Channel_Partner_Profile_Settings__c cpProfile = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
            if (cpProfile.Is_Channel_Partner__c == true) { 
                res =true;
            }
            ilib_LogEvent.message('res: ' + res); 
            ilib_LogEvent.pop();
            return res;
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            throw new AuraHandledException(LOG_TITLE+'--checkCPProfile'+ e.getMessage());
        } 
    }

    /**
    *  @AUTHOR Gladis
    *  @DESCRIPTION - CMCP-110 - Method to create resource url, which is passed to IVDRDocumentDataSender to make  the callout and return String body in JSON format.
    *  @PARAM : String
    *  @RETURN : String JSON
    **/
    @AuraEnabled
    public static String fetchSalesOrderDetailsFromSAP(string strOrderDetails) {

        ilib_LogEvent.push(LOG_TITLE + '.fetchSalesOrderDetailsFromSAP()');
        ilib_LogEvent.message('orderDetails: ' + strOrderDetails); 
        List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper> salesOrderRecordList = new List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper>();
        String strFinalResponse = null;
        String strId = null;
        String strInputParamUrl = null;

        try {
            if(String.isNotBlank(strOrderDetails)) {  
                salesOrderRecordList = (List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper>) System.JSON.deserialize(strOrderDetails, List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper>.class);
                ilib_LogEvent.message('salesOrderRecordList: ' + salesOrderRecordList);
                if(!salesOrderRecordList.isEmpty()) {
                    String urlEncode = EncodingUtil.urlEncode(createCustomUrl(salesOrderRecordList) , 'UTF-8');
                    ilib_LogEvent.message('createCustomUrl: ' +urlEncode);
                    ilib_LogEvent.message('finalUrl'+ORDER_DETAILS_SET+urlEncode);

                    if(salesOrderRecordList[0].id != null) {
                        strId = salesOrderRecordList[0].id;
                    }
                    strInputParamUrl = ORDER_DETAILS_SET+urlEncode;
                    strFinalResponse = getFinalResponse(strInputParamUrl,strId);
                }
            } 

            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return strFinalResponse;
        } catch(Exception e) { 
            ApexExceptions.emit(LOG_TITLE,e);
            throw new AuraHandledException(LOG_TITLE +'--fetchSalesOrderDetailsFromSAP:'+ e.getMessage());
        }
    }

    /**
     *  @AUTHOR Gladis
     *  @DESCRIPTION - Method to get the final response after making the callout
     *  @PARAM : String, String
     *  @RETURN : String
     **/
    public static String getFinalResponse(String strInputParamUrl,String strId){
        
        List<IVDRDocumentSearchController.calloutWrapper> calloutWrapperList = new List<IVDRDocumentSearchController.calloutWrapper>();
        String strFinalResponse = null;
        HttpResponse httpResultResponse = null;
        IVDRDocumentDataSender ivdrDataSender = new IVDRDocumentDataSender();
        calloutWrapper cWrapper = new calloutWrapper();
            cWrapper.strInputParamUrl = strInputParamUrl;
            cWrapper.strId = strId;
            calloutWrapperList.add(cWrapper);
        ilib_LogEvent.message('calloutWrapperList--'+calloutWrapperList);
        httpResultResponse =  ivdrDataSender.executeCallout(JSON.serialize(calloutWrapperList)); 
        strFinalResponse = deserializeInputs(httpResultResponse.getBody());

        return strFinalResponse;
    }


    /**
     *  @AUTHOR Gladis
     *  @DESCRIPTION - Create custom resource URL
     *  @PARAM : IVDRDocumentSalesOrderWrapper wrapper list
     *  @RETURN : String
     **/
    private static String createCustomUrl(List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper> salesOrderRecordList) {

        String strResourceURL = null;
        String strStartDate = null;
        String strEndDate = null;
        String strSalesOrder = null;
        String strErpCustomer = null;
        ilib_LogEvent.message('salesOrderRecordList in customURL method' + salesOrderRecordList);

        if(String.isNotBlank(salesOrderRecordList[0].salesOrder)) {
            strSalesOrder = salesOrderRecordList[0].salesOrder.leftPad(10,'0');
        }

        if(String.isNotBlank(salesOrderRecordList[0].startDate)) {
            strStartDate = salesOrderRecordList[0].startDate+START_TIME;
        }

        if(String.isNotBlank(salesOrderRecordList[0].endDate)) {
            strEndDate = salesOrderRecordList[0].endDate+END_TIME;
        }

        if(String.isNotBlank(salesOrderRecordList[0].erpCustomer)) {
            strErpCustomer = salesOrderRecordList[0].erpCustomer;
        }

        if(String.isNotBlank(salesOrderRecordList[0].salesOrder) && String.isBlank(salesOrderRecordList[0].startDate)) {
            strResourceURL = '(Customer eq \'' + strErpCustomer+'\' '+'and SalesOrder eq \'' + strSalesOrder+'\' '+'and PartnerFn eq \'' + PARTNER_FN+'\' '+')';
        
        } else if(String.isBlank(salesOrderRecordList[0].salesOrder) && String.isNotBlank(salesOrderRecordList[0].startDate) && String.isNotBlank(salesOrderRecordList[0].endDate)) {                   
            strResourceURL = '(Customer eq \'' + strErpCustomer+'\' '+'and PartnerFn eq \'' + PARTNER_FN+'\' '+'and StartDate eq datetime\'' + strStartDate+'\' '+'and EndDate eq datetime\'' + strEndDate+'\' '+')';
        
        } else if(String.isNotBlank(salesOrderRecordList[0].salesOrder) && String.isNotBlank(salesOrderRecordList[0].startDate) && String.isNotBlank(salesOrderRecordList[0].endDate)) {
            strResourceURL = '(Customer eq \'' + strErpCustomer+'\' '+'and SalesOrder eq \'' + strSalesOrder+'\' '+'and PartnerFn eq \'' + PARTNER_FN+'\' '+'and StartDate eq datetime\'' + strStartDate+'\' '+'and EndDate eq datetime\'' + strEndDate+'\' '+')';
        }

        ilib_LogEvent.message('strResourceURL in customURL method' + strResourceURL);
        return strResourceURL;
    }

    /**
     *  @AUTHOR Gladis
     *  @DESCRIPTION - Deserilize the response into wrapper
     *  @PARAM : String response from SAP.
     *  @RETURN : Json String
     **/
    private static String deserializeInputs(String jsonInput) {

        ilib_LogEvent.push(LOG_TITLE + '.deserializeInputs()');
        ilib_LogEvent.message('jsonInput: ' + jsonInput);
        List<IVDRDocumentSearchResponseWrapper.results> wrapResponseList = new List<IVDRDocumentSearchResponseWrapper.results>();
        IVDRDocumentSearchResponseWrapper wrapResponse = new IVDRDocumentSearchResponseWrapper();   
        wrapResponse = (IVDRDocumentSearchResponseWrapper) System.JSON.deserialize(jsonInput, IVDRDocumentSearchResponseWrapper.class); 
        ilib_LogEvent.message('wrapResponse: ' + wrapResponse);

        //Success Response
        if (wrapResponse.d!= null) {
            if (wrapResponse.d.results != null && wrapResponse.d.results.size()>0) {
                wrapResponseList.addAll(wrapResponse.d.results); 
            }
            if (wrapResponse.d.Stream != null) {
                IVDRDocumentSearchResponseWrapper.results wrapResult = new IVDRDocumentSearchResponseWrapper.results();
                    wrapResult.Stream = wrapResponse.d.Stream;
                    wrapResponseList.add(wrapResult);
            }
        }
        //Error Response
        if (wrapResponse.error!= null) {
            if (wrapResponse.error.message != null) {
                IVDRDocumentSearchResponseWrapper.results wrapResult = new IVDRDocumentSearchResponseWrapper.results();
                wrapResult.value = (String)wrapResponse.error.message.value;
                wrapResult.code = (String)wrapResponse.error.code;
                wrapResponseList.add(wrapResult);
            }
        }

        ilib_LogEvent.message('wrapResponseList: ' + wrapResponseList);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return JSON.serialize(wrapResponseList);

    }

    /**
     *  @AUTHOR Gladis
     *  @DESCRIPTION - Method to make the second callout and download the response into blob64.
     *  @PARAM : String
     *  @RETURN : String
     **/
    @AuraEnabled
    public static string downloadSalesOrderDetails(string strOrderDetails) {

        ilib_LogEvent.push(LOG_TITLE + '.downloadSalesOrderDetails()');
        ilib_LogEvent.message('orderDetails: ' + strOrderDetails);
        List<IVDRDocumentSearchResponseWrapper.results> salesOrderRecordList = new List<IVDRDocumentSearchResponseWrapper.results>();
        String strResourceURL = null;
        String strFinalResponse = null;
        String strId = null;
        String strInputParamUrl = null;

        try {
            if(String.isNotBlank(strOrderDetails)) { 
                salesOrderRecordList = (List<IVDRDocumentSearchResponseWrapper.results>) System.JSON.deserialize(strOrderDetails, List<IVDRDocumentSearchResponseWrapper.results>.class);

                if(!salesOrderRecordList.isEmpty()) {
                    if(String.isNotBlank(salesOrderRecordList[0].Delivery)) {
                        strResourceURL = '(\''+salesOrderRecordList[0].Delivery+'\')';
                    }
                    String urlEncode = EncodingUtil.urlEncode(strResourceURL , 'UTF-8');
                    ilib_LogEvent.message('finalUrl: ' + IVDR_DOC_SET+urlEncode);
                    if(salesOrderRecordList[0].id != null) {
                        strId = salesOrderRecordList[0].id;
                    }
                    strInputParamUrl = IVDR_DOC_SET+urlEncode;
                    strFinalResponse = getFinalResponse(strInputParamUrl,strId);
                }
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return strFinalResponse;
        } catch(Exception e) { 
            ApexExceptions.emit(LOG_TITLE,e);
            throw new AuraHandledException(LOG_TITLE +'downloadSalesOrderDetails:'+ e.getMessage());
        }
        
    }


    /**
    *  @AUTHOR: Gladis
    *  @DESCRIPTION: Wrapper to hold the parameters from UI.
    **/
    public class IVDRDocumentSalesOrderWrapper {

            @AuraEnabled public String id;
            @AuraEnabled public String salesOrder;
            @AuraEnabled public String deliveryNumber;
            @AuraEnabled public String quantity;
            @AuraEnabled public String materialDescription;
            @AuraEnabled public String startDate;
            @AuraEnabled public String endDate;
            @AuraEnabled public String erpCustomer;
            @AuraEnabled public String accountName;
    }

    /**
    *  @AUTHOR: Gladis
    *  @DESCRIPTION: Wrapper to hold the parameters to pass to datasender class.
    **/
    public class calloutWrapper {
        @AuraEnabled public String strInputParamUrl;
        @AuraEnabled public String strId;
    }

}
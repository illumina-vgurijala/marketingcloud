/* @ author      :  Akash Kumar
 * @ date         :  26-SEP-2024
 * @ Description  :  TargetMarginCalculationService is the class for callout to SNAP for getting Margin Target
 *
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer               Date                 Description
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Akash Kumar         26-SEP-2024             Initial version
 */

 public with sharing class TargetMarginCalculationService extends ilib_RestReceiver {
    public static final String INTERFACE_NAME = 'Get_Target_Margins';
    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public static final String ERROR = 'Error-';
    public static final String APPLICATION_JSON = 'application/json';
    private static final String SUCCESS = 'Success';
    /*
	Enum for HttpMethod
	*/
    public enum HttpMethod {
        HEAD,
        POST
    }
    /**
     * Method to get Target Margin From SNAP based on ProductCodes
     **/
    public ViewSalesMarginDataController.responseWrapper getTargetMarginFromSnap(List<Apttus_Proposal__Proposal_Line_Item__c> items) {
        TargetMarginCalculationService instantiated = new TargetMarginCalculationService();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ViewSalesMarginDataController.responseWrapper responseWrapper;
        Map<String, Double> productCodeToTargetMargin = new Map<String, Double>();
        String message;
        ilib_LogEvent.push('Call SNAP for Target Margin');
        ilib_LogEvent.message('QLIs' + JSON.serializePretty(items));

        try {
            String strJSON = createRequestJSON(items);
            Map<String, String> headerKeyToValue = new Map<String, String>{
                'content-type' => APPLICATION_JSON,
                'accept' => APPLICATION_JSON
            };
            ilib_LogEvent.message('@@@ Target Margin Request ' + strJSON);
            HttpRequest request = UtilsRest.createHttpRequest(INTERFACE_NAME, HttpMethod.POST.name(), headerKeyToValue, strJSON);
            ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, strJSON);
            HttpResponse response = !Test.isRunningTest() ? UtilsRest.send(request) : new MockSnowFlakeConnector().respond(request);
            ilib_LogEvent.message('@@@ Target Margin Response ' + response.getBody());
            if ((response.getStatusCode() == HTTP_SUCCESS_CODE || response.getStatusCode() == HTTP_POST_SUCCESS_CODE)) {
                TargetMarginResponseWrapper marginResponse = processResponse(response.getBody());
                ilib_LogEvent.message('@@@ Target Margin Serialize Response ' + JSON.serializePretty(marginResponse));
                if (marginResponse?.Margin != null && !marginResponse.Margin.isEmpty()) {
                    for (Margin margin : marginResponse.Margin) {
                        productCodeToTargetMargin.put(margin.MaterialNumber, margin.TargetMarginPercent);
                    }
                }
                message =
                    '{"StatusCode" : "' +
                    marginResponse.StatusCode +
                    '","Status" : "' +
                    marginResponse.Status +
                    '","Details" : "' +
                    marginResponse.Details +
                    '"}';
                responseWrapper = new ViewSalesMarginDataController.responseWrapper(
                    productCodeToTargetMargin,
                    log,
                    SUCCESS,
                    message,
                    items[0].Apttus_Proposal__Proposal__c
                );
            } else {
                productCodeToTargetMargin.put(ERROR, 0.0);
                responseWrapper = new ViewSalesMarginDataController.responseWrapper(
                    productCodeToTargetMargin,
                    log,
                    ERROR,
                    response.getBody(),
                    items[0].Apttus_Proposal__Proposal__c
                );
            }
        } catch (Exception e) {
            ilib_LogEvent.error('Error at line         					: ' + e.getLineNumber());
            ilib_LogEvent.error('The following exception has occurred   : ' + e.getMessage());
            ilib_LogEvent.error('Exception type caught 					: ' + e.getTypeName());
            ilib_LogEvent.error('Cause                 					: ' + e.getCause());
            ilib_LogEvent.error('Stack trace           					: ' + e.getStackTraceString());
            productCodeToTargetMargin.put(ERROR, 0.0);
            ApexExceptions.emit('TargetMarginCalculationService', items[0].Apttus_Proposal__Proposal__c, e);
        }
        ilib_LogEvent.pop();
        return responseWrapper;
    }

    /**
     * Method to create Request JSON to SNAP
     **/
    public static String createRequestJSON(List<Apttus_Proposal__Proposal_Line_Item__c> items) {
        ilib_LogEvent.push('createTargetMarginJSON');
        TargetMarginRequestWrapper tmw = new TargetMarginRequestWrapper();
        tmw.Sub_Region = items[0].Apttus_Proposal__Proposal__r.Sub_Region_UC__c != null
            ? items[0].Apttus_Proposal__Proposal__r.Sub_Region_UC__c
            : null;
        tmw.Region = items[0].Apttus_Proposal__Proposal__r.Region_Ultimate_Consignee__c != null
            ? items[0].Apttus_Proposal__Proposal__r.Region_Ultimate_Consignee__c
            : null;
        tmw.OppClosedDate = String.valueOf(items[0].Apttus_Proposal__Proposal__r.Apttus_Proposal__Opportunity__r.CloseDate);
        tmw.Product_Code = new Set<String>();
        for (Apttus_Proposal__Proposal_Line_Item__c item : items) {
            tmw.Product_Code.add(item.Apttus_Proposal__Product__r.Material_Number__c);
        }
        ilib_LogEvent.pop();
        return JSON.serializePretty(tmw);
    }

    /**
     * Method to Process Response JSON from SNAP
     **/
    public static TargetMarginResponseWrapper processResponse(String strResponse) {
        ilib_LogEvent.push('processReponseJSON');
        TargetMarginResponseWrapper marginResponse = (TargetMarginResponseWrapper) JSON.deserialize(
            strResponse,
            TargetMarginResponseWrapper.class
        );
        ilib_LogEvent.message('@@@ TM Response ' + marginResponse);
        ilib_LogEvent.pop();
        return marginResponse;
    }

    /**
     * Wrapper Class for Request
     **/
    public class TargetMarginRequestWrapper {
        public String Sub_Region;
        public String Region;
        public String OppClosedDate;
        public Set<String> Product_Code;
    }

    /**
     * Wrapper Class for Response
     **/
    public class TargetMarginResponseWrapper {
        public List<Margin> Margin;
        public String StatusCode;
        public String Status;
        public String Details;
        public TargetMarginRequestWrapper request;
    }

    /**
     * Wrapper Class for Response
     **/
    public class Margin {
        public String GMVersionName;
        public String Region;
        public String FsclQtrID;
        public String FsclQtrStrtDt;
        public String FsclQtrEndDt;
        public String MaterialNumber;
        public String L04_ProductGroupCode;
        public Double TargetMarginPercent;
        public String Publish_Dt;
        public String Publish_Usr;
    }
}

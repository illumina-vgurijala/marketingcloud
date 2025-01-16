/***************************************************************************************************************************************
* NAME         : WOTranslationDataSender
* DESCRIPTION  : DCP-56433 Data Sender class for Lokalise Translation API
* @AUTHOR      : Sagar Madkaikar
* @DATE        : 14-Sep-2022 
* @Testclass   : TestWOTranslationDataSender
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar        14-Sep-2022         DCP-56433 : Initial Version
* --------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/
public with sharing class WOTranslationDataSender extends ilib_RestSender {
    private static final String LOG_TITLE = 'WOTranslationDataSender';
    public static final String INTERFACE_NAME = 'Lokalise_Inbound';
    public static final String API_TOKEN = 'X-Api-Token';
    public final static String STRING_CONTENT_TYPE = 'Content-Type';
    public final static String STRING_APPLICATION_JSON = 'application/json';
    public final static String STRING_ACCEPT = 'Accept';
    public final static String STRING_ERROR_MESSAGE = 'Error in calling Lokalise API:';
    public final static String STRING_SUCCESS_MESSAGE = 'Fields Translated Successfully';
    public final static String STRING_ENGLISH_LANGUAGE_ISO = 'en_US';
    public static final Integer HTTP_SUCCESS_CODE = 200;
    //public final static String STRING_FAILURE_MESSAGE = ' Translation Failed. Check Lokalise Support';
    public final static String CUSTOM_EXCEPTION_TYPE = 'WOTranslationDataSender.CustomException';
    public static final Integer EXPECTED_TRANSLATED_VALUES_SIZE = 2;
    

    public String woId = ''; //store the Work Order Record Id for current Context record
    public SVMXC__Service_Order__c woRecord;//this will store Work Order record instance
    String languageISO;//variable to hold language ISO
    String concatenatedTranslationInput;// this variable will hold 5 WO concatenated fields
    

    /**
    * constructor
    **/
    public WOTranslationDataSender(String languageISO, String woId, String concatenatedTranslationInput)
    {
        this.languageISO = languageISO;
        this.woId = woId;
        this.concatenatedTranslationInput=concatenatedTranslationInput;
        this.woRecord =  new WorkOrdersSelector().selectWorkOrders(new Set < Id > {
            woId
        })[0];
    }

    /**
    * hold http actions.
    **/
    public enum HttpMethod {POST,PUT} 

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
        LokaliseTranslationRequestWrapper requestWrapper = new LokaliseTranslationRequestWrapper();
        requestWrapper.use_automations = true;
        requestWrapper.keys=new  List<LokaliseTranslationRequestWrapper.Keys>();

        //populate Translation Obj
        LokaliseTranslationRequestWrapper.Translations translation = new LokaliseTranslationRequestWrapper.Translations();
		translation.language_iso=languageISO;//'zh_CN'
        translation.translation=concatenatedTranslationInput;

        //Populate Keys obj
        LokaliseTranslationRequestWrapper.Keys key = new LokaliseTranslationRequestWrapper.Keys();
        key.translations = new List<LokaliseTranslationRequestWrapper.Translations>();
        key.translations.add(translation);
        key.key_name = woRecord.Name;//'WO-00706803c'; 
        key.description = 'This is Key for '+woRecord.Name; 
        if(String.isNotBlank(woRecord.Lokalise_Key_ID__c)){
            key.key_id = woRecord.Lokalise_Key_ID__c;
        }
        
        key.platforms = new List<String>();
        key.platforms.add('web');

        requestWrapper.keys.add(key);

        ilib_LogEvent.message(LOG_TITLE+' createJSON() requestWrapper ===>: ' + requestWrapper); 
        return JSON.serializePretty(requestWrapper);
    }

    /**
    *  @AUTHOR Sagar Madkaikar
    *  @DESCRIPTION - DCP-56433 - Method to create resource url and is passed to the callout method.
    *  @PARAM : String
    *  @RETURN : 
    **/
    public WOResponseWrapper fetchWOTranslations() {
        ilib_LogEvent.push(LOG_TITLE + '.fetchWOTranslations()');
        ilib_LogEvent.message('languageISO: ' + languageISO);
        ilib_LogEvent.message('woRecord: ' + woRecord); 

        WOResponseWrapper woWrapperIns = new WOResponseWrapper();
        HttpResponse httpResultResponse = null;

        
        //ilib_LogEvent.message('concatenatedTranslationInput ' + concatenatedTranslationInput);
        try {
                httpResultResponse =  executeCallout(concatenatedTranslationInput);
                //check if the status code is not 400 or a bad request.
                if (String.valueOf(httpResultResponse.getStatuscode()).startsWith('2')) {
                    
                    //get the response body
                    String result = httpResultResponse.getBody();
                    ilib_LogEvent.message('Http Response ===>: ' + result); 
                    //deserialize the response received into a wrapper class
                    woWrapperIns = deserializeInputs(result);
                } else {   
                    ilib_LogEvent.message('Error Body===>: ' + httpResultResponse.getBody());  
                    woWrapperIns.isSuccess = false;
                    woWrapperIns.message = STRING_ERROR_MESSAGE+httpResultResponse.getStatus();
                }
                
                
                
        } catch(Exception e) { 
            woWrapperIns.isSuccess = false;
            woWrapperIns.message = e.getMessage();
            if(e.getTypeName()!=CUSTOM_EXCEPTION_TYPE){
                ApexExceptions.emit(LOG_TITLE,e);
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return woWrapperIns;
    }

    /**
    *  @AUTHOR Sagar
    *  @DESCRIPTION - Method to call Lokalise Interface.
    * @PARAM : String
    * @RETURN : HttpResponse
    **/
    public override HttpResponse executeCallout(String strJson){

        ilib_LogEvent.push(LOG_TITLE + '.executeCallout()'); 
        HttpRequest request = new HttpRequest(); 
        HttpResponse response = null;

        try {

                //populate the body by created JSON.
                String body = createJSON();
                ilib_LogEvent.message('Request Body ' + body);

                Interface_Parameters__mdt connectionParameters = UtilsRest.getConnectionParameters(INTERFACE_NAME);
                String strEndPoint = connectionParameters.Endpoint__c;

                //create Http request
                request.setEndpoint(strEndPoint);
                request.setMethod(String.isBlank(woRecord.Lokalise_Key_ID__c)?HttpMethod.POST.name():HttpMethod.PUT.name());
                request.setHeader(API_TOKEN, connectionParameters.BearerToken__c);
                request.setHeader(STRING_ACCEPT,STRING_APPLICATION_JSON);
                request.setHeader(STRING_CONTENT_TYPE,STRING_APPLICATION_JSON);
                request.setBody(body);
                request.setTimeout(120000);
                ilib_LogEvent.message('Http Request ===>: ' + request); 

                //sending the request and capturing the response.
                response = UtilsRest.send(request);  
            
                ilib_LogEvent.message('Http Response ===>: ' + response.getBody()); 
            //adding response body to the Interface Log Result Details field.
            if(response.getStatusCode() != HTTP_SUCCESS_CODE) {
                ilib_LogInterface.finalizeLog(getInterfaceLog(body),ilib_LogInterface.RESULT_FAIL, response.getBody(), woId, response);
            } else {
                ilib_LogInterface.finalizeLog(getInterfaceLog(body),ilib_LogInterface.RESULT_SUCCESS, response.getBody(), woId, response);
            }

            if (null != response && !String.isBlank(response.getBody())) {
                handleResult(response);
            }
        } catch (Exception e) {
            ilib_LogEvent.message('Exception--strError:' + e.getMessage() + '\n' + e.getStackTraceString());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new CustomException(STRING_ERROR_MESSAGE+ e.getMessage());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return response;  
    }

    /**
    *  @AUTHOR Sagar
    *  @DESCRIPTION - Deserilize the response into wrapper and handle the response
    *  @PARAM : String 
    *  @RETURN : WOResponseWrapper
    **/
    private  WOResponseWrapper deserializeInputs(String  responseJSON) {

        ilib_LogEvent.push(LOG_TITLE + '.deserializeInputs()');
        ilib_LogEvent.message('responseJSON: ' + responseJSON);

        WOResponseWrapper woWrapperIns = new WOResponseWrapper();

        try {
            
       
            LokaliseTranslationResponseWrapper wrapResponse = new LokaliseTranslationResponseWrapper();
            wrapResponse = (LokaliseTranslationResponseWrapper) System.JSON.deserialize(responseJSON, LokaliseTranslationResponseWrapper.class); 
            ilib_LogEvent.message('wrapResponse: ' + wrapResponse);

            //check for errors in response
            if(wrapResponse.errors!=null && !wrapResponse.errors.isEmpty()){
                woWrapperIns.isSuccess=false;
                woWrapperIns.message='';
                //iterate over error list to get the error message.
                for(LokaliseTranslationResponseWrapper.Errors error: wrapResponse.errors) {
                    woWrapperIns.message=woWrapperIns.message+'\n'+error.message;
                }
            }
            else{ //Handle success response
                woWrapperIns.isSuccess=true;
                woWrapperIns.message=STRING_SUCCESS_MESSAGE;
                //get keyInstance
                LokaliseTranslationResponseWrapper.Keys keyInstance = wrapResponse.keys[0];

                ilib_LogEvent.message('keyInstance: ' + keyInstance);

                String englishTranslatedValues = null;
                //iterate over keyInstance.translations list to get the english translated value
                for (LokaliseTranslationResponseWrapper.Translations translationIns : keyInstance.translations) {
                    if (translationIns.language_iso==STRING_ENGLISH_LANGUAGE_ISO) {
                        englishTranslatedValues = translationIns.translation;
                    }
                }
                ilib_LogEvent.message('englishTranslatedValues: ' + englishTranslatedValues);
                //update woRecord for Key ID
                update new SVMXC__Service_Order__c(Id=woRecord.Id,Lokalise_Key_ID__c=String.valueOf(keyInstance.key_id));
                
                //populate the translated value to respective WO English fields
                populateWOTranslatedFields(englishTranslatedValues);
                woWrapperIns.woObj=woRecord;

             }
        } catch (Exception e) {
            ilib_LogEvent.message('Exception--strError:' + e.getMessage() + '\n' + e.getStackTraceString());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new CustomException(e.getMessage());        
        }
        ilib_LogEvent.message('woWrapperIns Returned: ' + woWrapperIns);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return woWrapperIns;
    }

    /**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - Initiate log object record.
    *  @PARAM : String 
    *  @RETURN : ilib_LogInterface.LogDetails
    **/
    private  ilib_LogInterface.LogDetails getInterfaceLog(String strRequestBody) {
        
            
        String interfaceName;
        ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(LOG_TITLE);
        interfaceName = interfaceDetails.name;

        //Interface Log
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(interfaceName, interfaceDetails.direction, interfaceDetails.objectType);
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(intDetails);
        ilib_LogInterface.addJsonToLog(log,strRequestBody);
        return log;

    }

     /**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - This method Split the string into list using delimiter '@&%#' and populate the woRecord fields
    *  @PARAM : String 
    *  @RETURN : void
    **/
    private void populateWOTranslatedFields(String englishTranslatedValues){
        ilib_LogEvent.message('populateWOTranslatedFields:englishTranslatedValues: ' + englishTranslatedValues);

        //split the englishTranslatedValues with delimiter and map the values to WO fields.
        List<String> lstTranslatedValues = englishTranslatedValues.split(WOTranslationService.DELIMITER);
        //added if condition for CMCM 2180 by Dhairya Shah
            if (lstTranslatedValues.size()!=EXPECTED_TRANSLATED_VALUES_SIZE) {
                throw new CustomException(System.Label.WOTranslationErrorMessage);
            }
            woRecord.English_Translation_Subject__c = lstTranslatedValues[0];
            woRecord.English_Translation_Additional_Detail__c = lstTranslatedValues[1];
            ilib_LogEvent.message('populateWOTranslatedFields:woRecord: ' + woRecord);
    }

    
     /**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - This is a wrapper class to return response to the calling class
    **/
    public class WOResponseWrapper{
        public Boolean isSuccess;
        public String message;
        public SVMXC__Service_Order__c woObj;

    }

    
     /**
    *  @AUTHOR Sagar 
    *  @DESCRIPTION - Custom Exception class
    **/
    public class CustomException extends Exception {}

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION -Overriden method from interface
     **/
    protected override void handleResult(HTTPResponse res) {
    }

}
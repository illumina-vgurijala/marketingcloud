/***************************************************************************************************************************************
* NAME         : EtQCreateQIDataSender
* DESCRIPTION  : QACM-14:Create QI from Case/FAN Data Sender Class
*                    
* @AUTHOR      : 
* @DATE        : 30-Mar-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar       30-Mar-2021           QACM-14: Initial Version
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class EtQCreateQIDataSender extends ilib_RestSender{
   
    private static final String LOG_TITLE = 'EtQLinkDelinkQIDataSender';
    public static final String INTERFACE_NAME = 'EtQ_Inbound'; 
    public static final String SOURCE_COMPLAINT = 'Complaint';
    public static final String ETQ_STATUS_QI_CREATION_FAIL = 'QI Creation Failed';
    public static final String AUTHORIZATION = 'Authorization';
    public static final String APIKEY = 'apikey';
    
    public String qrId = ''; //store the Quality Record Id for current QR Context record
    public Quality_Record__c qrRecord;//this will store Quality_Record__c record instance

     /**
    * hold CalloutData.
    *
    private CalloutData data {
        get {
            return (CalloutData) idata;
        }
    }*/

    /**
    * hold http actions.
    **/
    public enum HttpMethod {POST} 

    /**
    * hold CalloutData.
    **/
    private class CalloutData extends ilib_CalloutData {

        Quality_Record__c qrRec;
        /**
        *  CalloutData Constructor.
        **/
        public CalloutData(Quality_Record__c qrRec) {
            this.qrRec = qrRec;
        }
    }
   

    /**
    * this class uses selectors to populate CalloutData
    **/
    protected override ilib_CalloutData retrieveCalloutData() {
        QualityRecordSelector qrSelector = new QualityRecordSelector();
        Quality_Record__c qrRecs = qrSelector.selectQR(new Set < Id > {
            recordId
        })[0];

        CalloutData dataObj = new CalloutData(qrRecs);
        qrId = dataObj.qrRec.Id;
        qrRecord = dataObj.qrRec;
        system.debug('qrId ' +qrId);
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
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - This Method will return String body in JSON format which will be used in HTTP request method.
     *  @DATE - 30-Mar-2022 
     *  @PARAM : 
     *  @RETURN : String JSON
     **/
    public override String createJSON() {
    
        //wrapper object holder.
        EtQRequestWrapper linkQIWrapperInstance = new EtQRequestWrapper();
        linkQIWrapperInstance.Source = qrRecord.Source__c;
        linkQIWrapperInstance.AssignedUser = qrRecord.CreatedBy.Email.substringBefore('@');
        //linkQIWrapperInstance.QINumber = qrRecord.Quality_Record__r.EtQ_Number__c;
        linkQIWrapperInstance.UniqueID = qrId;
        if(qrRecord.Case__c!=null) {
            linkQIWrapperInstance.CaseNumber = qrRecord.Case__r.CaseNumber;
            linkQIWrapperInstance.FANNumber = '';
            linkQIWrapperInstance.Link = System.Label.Portal_URL+qrRecord.Case__c;
        }
        else if(qrRecord.Field_Action_Notification__c!=null) {
            linkQIWrapperInstance.CaseNumber = '';
            linkQIWrapperInstance.FANNumber = qrRecord.Field_Action_Notification__r.Name;
            linkQIWrapperInstance.Link = System.Label.Portal_URL+qrRecord.Field_Action_Notification__c;
        }

        //create the JSON structure of the data present in LinkQI wrapper.
        String strJson = JSON.serializePretty(linkQIWrapperInstance);
        System.debug(LoggingLevel.INFO, 'JSON Output:\n' + strJson);
        return strJson;
    }

     /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - This Method will make the authentication callout and actual callout to EtQ
     *  @DATE - 20-Mar-2022 
     *  @PARAM : String strJson
     *  @RETURN : HttpResponse
     **/
    public override HttpResponse executeCallout(String strJson) {
        ilib_LogEvent.push(LOG_TITLE + '.executeCallout()');

        HttpResponse response=null; 

        //update the Case if we get an error during authentication / connection.
        List < Quality_Record__c > lstQRToUpdate = new List < Quality_Record__c > ();

        try {

            //populate the body by created JSON.
            String body = createJSON();

            //make final request with token in header.
            Interface_Parameters__mdt connectionParameters = UtilsRest.getConnectionParameters(INTERFACE_NAME);
            HttpRequest request = new HttpRequest();
            request.setEndpoint(connectionParameters.Endpoint__c);
            request.setMethod(HttpMethod.POST.name());
            request.setHeader(AUTHORIZATION,'Bearer '+connectionParameters.BearerToken__c);
            request.setHeader(APIKEY, connectionParameters.ApiKey__c);
            request.setHeader('Accept','application/json');
            request.setHeader('Content-Type','application/json');
            request.setBody(body);
            request.setTimeout(120000);
            ilib_LogEvent.message('Http Request ===>: ' + request); 
            
            //send the request and capture the response.
            response = UtilsRest.send(request);

            //Add response body to the Log Result Details field.
            ilib_LogInterface.addMessageToLog(log, 'EtQ Response : '+response.getBody());

            //check if the status code is not 400 or a bad request.
            if (String.valueOf(response.getStatuscode()).startsWith('2')) {
                
                //get the response body
                String result = response.getBody();
                ilib_LogEvent.message('Http Response ===>: ' + result); 
                
            
                //deserialize the response received into a wrapper class and make updates to QRJ Status as required
                //deserializeInputs(result);

            } else {
                 
                ilib_LogEvent.message('Error Body===>: ' + response.getBody());   
                //Its an error of some kind. Update the error on Quality_Record__c
                lstQRToUpdate.add(new Quality_Record__c(Id = qrId,EtQ_Integration_Status__c=ETQ_STATUS_QI_CREATION_FAIL, EtQ_Integration_Messages__c = 'Status Code : ' +response.getStatuscode() + ' \r\n' +'Error Message : '  +response.getBody()));
            }

        } 
        catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
                ilib_LogEvent.message('Exception: ' + e.getMessage()); 
                lstQRToUpdate.add(new Quality_Record__c(Id = qrId,EtQ_Integration_Status__c=ETQ_STATUS_QI_CREATION_FAIL, EtQ_Integration_Messages__c = 'Internal Exception : '+e.getMessage()));
                
        }

        if (lstQRToUpdate != null && !lstQRToUpdate.isEmpty()) {
            update lstQRToUpdate;		
        }
        return response;

    }

     /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - Deserializes the response and check for errors.
     *  @PARAM : Response from SNAP EtQ.
     *  @RETURN : void
     *
    private void deserializeInputs(String jsonInput) {

        //deserialize the json received into a wrapper class.
        ETQResponseWrapper wrapResponse = new ETQResponseWrapper();
        wrapResponse = (ETQResponseWrapper) System.JSON.deserialize(jsonInput, ETQResponseWrapper.class); 

        
        //If QINumber is blank stamp error on QR record
        if(String.isBlank(wrapResponse.QINumber)){
            //Instantiate QR to Update results
            Quality_Record__c qrRecToUpdate = new Quality_Record__c(Id = qrId);
            qrRecToUpdate.EtQ_Integration_Status__c = ETQ_STATUS_QI_CREATION_FAIL;
            qrRecToUpdate.EtQ_Integration_Messages__c = wrapResponse.Messages;
            update qrRecToUpdate;
        }

    } */
    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION -Overriden method from interface
     **/
    protected override void handleResult(HTTPResponse res) {
        System.debug('res: ' + res);
    }

}

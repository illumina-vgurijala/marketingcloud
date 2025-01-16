/***************************************************************************************************************************************
* NAME         : EtQLinkDelinkQIDataSender
* DESCRIPTION  : QACM-14:Link QI to Case/FAN Data Sender Class
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
public with sharing class EtQLinkDelinkQIDataSender extends ilib_RestSender{
   
    private static final String LOG_TITLE = 'EtQLinkDelinkQIDataSender';
    public static final String INTERFACE_NAME = 'EtQ_Inbound';
    public static final String SOURCE_COMPLAINT = 'Complaint';
    public static final String ETQ_STATUS_LINK_INITIATED = 'Link Initiated';
    public static final String ETQ_STATUS_DELINK_INITIATED = 'Delink Initiated';
    public static final String ETQ_STATUS_LINKFAILED = 'Link Failed';
    public static final String ETQ_STATUS_DELINKFAILED = 'Delink Failed';
    public static final String INTERFACE_DETAIL_NAME_LINK = 'EtQ Link QI Inbound';
    public static final String INTERFACE_DETAIL_NAME_DELINK = 'EtQ De-Link QI Outbound';
    public static final String AUTHORIZATION = 'Authorization';
    public static final String APIKEY = 'apikey';
    public static final String HTTP_DELETE = 'DELETE';
    
    public String interfaceMethod = '';
    public String qrjId = ''; //store the Quality Junction Record Id for current QRJ Context record
    public Quality_Record_Junction__c qrjRecord;//this will store Quality_Record_Junction__c record instance
    public String interfaceNameJSON='';//this will store the InterFace name to be passed in the request JSON
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
    public enum HttpMethod {PATCH,DEL} 

    /**
    * hold CalloutData.
    **/
    private class CalloutData extends ilib_CalloutData {

        Quality_Record_Junction__c qrjRec;
        /**
        *  CalloutData Constructor.
        **/
        public CalloutData(Quality_Record_Junction__c qrjRec) {
            this.qrjRec = qrjRec;
        }
    }
   

    /**
    * this class uses selectors to populate CalloutData
    **/
    protected override ilib_CalloutData retrieveCalloutData() {
        QualityRecordJunctionSelector qrSelector = new QualityRecordJunctionSelector();
        Quality_Record_Junction__c qrjRecs = qrSelector.selectQRJ(new Set < Id > {
            recordId
        })[0];

        CalloutData dataObj = new CalloutData(qrjRecs);
        qrjId = dataObj.qrjRec.Id;
        qrjRecord = dataObj.qrjRec;

        //Populate Interface Name based on Link/DeLink operation
        if(qrjRecs.EtQ_Integration_Status__c==ETQ_STATUS_LINK_INITIATED)
        {
            interfaceMethod = HttpMethod.PATCH.name();
            interfaceNameJSON = INTERFACE_DETAIL_NAME_LINK;
        }
        else if(qrjRecs.EtQ_Integration_Status__c==ETQ_STATUS_DELINK_INITIATED)
        {
            interfaceMethod = HTTP_DELETE;//HttpMethod.DEL.name();
            interfaceNameJSON = INTERFACE_DETAIL_NAME_DELINK;
        }
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
        //linkQIWrapperInstance.Source = SOURCE_COMPLAINT;
        linkQIWrapperInstance.AssignedUser = qrjRecord.CreatedBy.Email.substringBefore('@');
        linkQIWrapperInstance.QINumber = qrjRecord.Quality_Record__r.EtQ_Number__c;
        linkQIWrapperInstance.UniqueID = qrjId;
        if(qrjRecord.Case__c!=null)
        {
            linkQIWrapperInstance.CaseNumber = qrjRecord.Case__r.CaseNumber;
            linkQIWrapperInstance.FANNumber = '';
            linkQIWrapperInstance.Link = System.Label.Portal_URL+qrjRecord.Case__c;
        }
        else if(qrjRecord.Field_Action_Notification__c!=null)
        {
            linkQIWrapperInstance.CaseNumber = '';
            linkQIWrapperInstance.FANNumber = qrjRecord.Field_Action_Notification__r.Name;
            linkQIWrapperInstance.Link = System.Label.Portal_URL+qrjRecord.Field_Action_Notification__c;
        }
        linkQIWrapperInstance.InterfaceName=interfaceNameJSON;

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

        //update the Case if we get an error during authentication / connection.
        List < Quality_Record_Junction__c > lstQRJToUpdate = new List < Quality_Record_Junction__c > ();

        HttpResponse response=null; 

        try{

            //populate the body by created JSON.
            String body = createJSON();

            //make final request with token in header.
            Interface_Parameters__mdt connectionParameters = UtilsRest.getConnectionParameters(INTERFACE_NAME);
            HttpRequest request = new HttpRequest();
            request.setEndpoint(connectionParameters.Endpoint__c);
            request.setMethod(interfaceMethod);
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
                //Its an error of some kind. Update the error on Quality_Record_Junction__c
                lstQRJToUpdate.add(new Quality_Record_Junction__c(Id = qrjId,EtQ_Integration_Status__c=getFailureStatus(), EtQ_Integration_Message__c = 'Status Code : ' +response.getStatuscode() + ' \r\n' +'Error Message : '  +response.getBody()));
            }
        }
        catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message('Exception: ' + e.getMessage()); 
            lstQRJToUpdate.add(new Quality_Record_Junction__c(Id = qrjId,EtQ_Integration_Status__c=getFailureStatus(), EtQ_Integration_Message__c = 'Internal Exception : '+e.getMessage()));
        }
        

        if (lstQRJToUpdate != null && !lstQRJToUpdate.isEmpty()) {
            update lstQRJToUpdate;		
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

        
        //If StatusCode != 200 stamp error message and status on QRJ record
        if(!wrapResponse.StatusCode.startsWith('2')){
            //Instantiate QRJ to Update results
            Quality_Record_Junction__c qrjRecToUpdate = new Quality_Record_Junction__c(Id = qrjId);
            qrjRecToUpdate.EtQ_Integration_Status__c = getFailureStatus();
            qrjRecToUpdate.EtQ_Integration_Message__c = wrapResponse.Messages;
            update qrjRecToUpdate;
        }

    }*/

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - This method will provide the Failure status based on the INTERFACE MethodName
     *  @PARAM : 
     *  @RETURN : String : Failure Status
     **/
    private String getFailureStatus() {
            String failureStatus = '';
            if(interfaceMethod==HttpMethod.PATCH.name()){
                failureStatus = ETQ_STATUS_LINKFAILED;
            }
            else if(interfaceMethod==HTTP_DELETE){
                failureStatus = ETQ_STATUS_DELINKFAILED;
            }
            return failureStatus;
        }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION -Overriden method from interface
     **/
    protected override void handleResult(HTTPResponse res) {
        System.debug('res: ' + res);
    }  

}

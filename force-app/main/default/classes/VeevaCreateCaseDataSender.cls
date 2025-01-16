/***************************************************************************************************************************************
* NAME         : VeevaCreateCaseDataSender
* DESCRIPTION  :DCP-51201:Data Sender class for creating Case in Veeva System.
*                    
* @AUTHOR      : Sagar Madkaikar
* @DATE        : 29-Aug-2022  
* @testclasses : TestVeevaCreateCaseDataSender
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar       29-Aug-2022           DCP-51201: Initial Version
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class VeevaCreateCaseDataSender extends ilib_RestSender{

    private static final String LOG_TITLE = 'VeevaCreateCaseDataSender';
    public static final String INTERFACE_NAME = 'Veeva_Inbound'; 
    public static final String AUTHORIZATION = 'Authorization';
    public static final String APIKEY = 'apikey';
    public static final String VEEVA_STATUS_FAILED= 'Case Creation Failed';

    public String caseId = ''; //store the Case Id for current Case record in Context
    public Case caseRecord;//this will store Case record instance

    /**
    * hold http actions.
    **/
    public enum HttpMethod {POST} 

    /**
    * hold CalloutData.
    **/
    private class CalloutData extends ilib_CalloutData {

        Case caseRec;
        /**
        *  CalloutData Constructor.
        **/
        public CalloutData(Case caseRec) {
            this.caseRec = caseRec;
        }
    }
   

    /**
    * this class uses selectors to populate CalloutData
    **/
    protected override ilib_CalloutData retrieveCalloutData() {
        CasesSelector caseSelector = new CasesSelector();
        Case caseRecs = caseSelector.selectCases(new Set < Id > {
            recordId
        })[0];

        CalloutData dataObj = new CalloutData(caseRecs);
        caseId = dataObj.caseRec.Id;
        caseRecord = dataObj.caseRec;
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
     *  @DATE - 29-Aug-2022 
     *  @PARAM : 
     *  @RETURN : String JSON
     **/
    public override String createJSON() {
        VeevaCaseCreationWrapper caseWrapper = new VeevaCaseCreationWrapper();

        caseWrapper.CaseId = caseId;
        caseWrapper.AccountName = caseRecord.Account.Name;
        caseWrapper.Region = caseRecord.Region__c;
        caseWrapper.Subject= caseRecord.Subject;
        caseWrapper.Description= caseRecord.Description;
        caseWrapper.ProductName= caseRecord.Product_Name__c;
        caseWrapper.CaseNumber= caseRecord.CaseNumber;

        //populating VeevaCaseCreationWrapper.ContactDetails()
        caseWrapper.ContactDetail = new VeevaCaseCreationWrapper.ContactDetails();
        if(caseRecord.Contact!=null){
            caseWrapper.ContactDetail.ContactFirstName = caseRecord.Contact.FirstName;
            caseWrapper.ContactDetail.ContactLastName = caseRecord.Contact.LastName;
            caseWrapper.ContactDetail.ContactPhone = caseRecord.Contact.Phone;
            caseWrapper.ContactDetail.ContactEmail = caseRecord.Contact.Email;
        }
        caseWrapper.ContactDetail.Webmail = caseRecord.SuppliedEmail;

        caseWrapper.emails = new List<VeevaCaseCreationWrapper.Email>();
        VeevaCaseCreationWrapper.Email emailObj;

        //Get EmailMessages records to fetch TextBody
        for(EmailMessage email:new EmailMessagesSelector().selectEmailMessageByParentId(new Set<String>{caseId}))
        {
            emailObj = new VeevaCaseCreationWrapper.Email();
            emailObj.EmailBody = email.TextBody;
            caseWrapper.emails.add(emailObj);
            break;//adding break to stop the loop after first iteration as we only need to pass 1 Email Mesage Body which is latest.
        }
        ilib_LogEvent.message(LOG_TITLE+' createJSON() caseWrapper ===>: ' + caseWrapper); 

        //TODO: Add code to populate wrapper
        return JSON.serializePretty(caseWrapper);
    }

     /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - This Method will make the authentication callout and actual callout to Veeva System through SNAP
     *  @DATE - 29-Aug-2022 
     *  @PARAM : String strJson
     *  @RETURN : HttpResponse
     **/
    public override HttpResponse executeCallout(String strJson) {
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE + '.executeCallout()');

        HttpResponse response=null; 

        //update the Case if we get an error during authentication / connection.
        List < Case > lstCaseToUpdate = new List < Case > ();

        try {
            
            //populate the body by created JSON.
            String body = createJSON();

            ilib_LogEvent.message(LOG_TITLE+' body ===>: ' + response); 

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

             ilib_LogEvent.message('Http Response ===>: ' + response); 

             //Add response body to the Log Result Details field.
             ilib_LogInterface.addMessageToLog(log, 'Veeva Response : '+response.getBody());
 
             //check if the status code is not 400 or a bad request.
             if (String.valueOf(response.getStatuscode()).startsWith('2')) {
                 
                 //get the response body
                 String result = response.getBody();
                 ilib_LogEvent.message('Http Response ===>: ' + result); 
                 
             
                 //deserialize the response received into a wrapper class and make updates to QRJ Status as required
                 //deserializeInputs(result);
 
             } else {
                  
                 ilib_LogEvent.message('Error Body===>: ' + response.getBody());   
                 //Its an error of some kind. Update the Veeva_Integration_Status__c to Fail
                 lstCaseToUpdate.add(new Case(Id = caseId,Veeva_Integration_Status__c=VEEVA_STATUS_FAILED));
                }

        } catch (Exception ex) {
            ApexExceptions.emit(LOG_TITLE,ex,ilib_LogEvent.SERVICE );
            ilib_LogEvent.message('Exception: ' + ex.getMessage()); 
            lstCaseToUpdate.add(new Case(Id = caseId,Veeva_Integration_Status__c=VEEVA_STATUS_FAILED));
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }

       

        //Update Case record
        if (lstCaseToUpdate != null && !lstCaseToUpdate.isEmpty()) {
            update lstCaseToUpdate;		
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return response;
    }

     /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION -Overriden method from interface
     **/
    protected override void handleResult(HTTPResponse res) {
        System.debug('res: ' + res);
    }

    
}

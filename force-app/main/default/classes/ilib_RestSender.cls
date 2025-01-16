/**
 * @File Name          : ilib_RestSender.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 8/19/2019, 9:44:08 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    8/19/2019, 9:44:08 PM   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
 * 1.1    06/03/2021              Akshay Mohan                           DCP-46834: Add logging and test class support for JSON
 *        06/24/2024              Gerardo Garcia                         CMCM-8480 Add set of extra information.
**/
public abstract class ilib_RestSender implements ilib_OutboundInterface {

    private final static Integer HTTP_TIMEOUT = 30000;
    public final Set<Integer> SUCCESS_STATUS_CODES = new Set<Integer>{ 200, 201 };
    //DCP-46834:Start-Making class variable for JSON asserts
    public String strJSON;
    //DCP-46834:End-Making class variable for JSON asserts

    protected ilib_RestInterface.InterfaceDetails interfaceDetails;
    private String logTitle;
    public String extraInformation;

    /**
    * 
    *
    * @desc ilib_RestSender Constructor [CodeScan Fix]
    */
    public ilib_RestSender()
    {
        String strClassName = getThisClassName();
        interfaceDetails = ilib_RestInterface.getInterfaceDetails(strClassName);
        //DCP-46834:Start- Add logging framework
        logTitle=strClassName;
        ilib_LogEvent.rootTitle = logTitle;
        ilib_LogEvent.message('interfaceDetails-->'+interfaceDetails);
        //DCP-46834:End- Add logging framework
    }

    /**
    * 
    *
    * @desc getThisClassName [CodeScan Fix]
    */
    public String getThisClassName()
    {
        return String.valueOf(this).split(':')[0];
    }

    @TestVisible protected Id recordId;

    // these hold the data the interface will query for and send in the callout body
    // values will be set in the child via retrieveCalloutData
    /**
    * 
    *
    * @desc ilib_CalloutData Class [CodeScan Fix]
    */
    public abstract class ilib_CalloutData { }
    protected ilib_CalloutData idata;

    protected ilib_LogInterface.LogDetails log;

    private void validateRequiredMetadataFields()
    {
        Boolean metadataValid = true;
        metadataValid = metadataValid && (interfaceDetails != null && !String.isBlank(interfaceDetails.name));
        if (!metadataValid)
            throw new UtilsRest.InterfaceException('Code error, set interface details for ' + getThisClassName());
    }

    /**
     * @description adds extra infomation commonly from Interface_Call__e
     * @param String values from extra information
     */
    public void setExtraInformation(String extraInformation) {
        this.extraInformation = extraInformation;
    }

    // this is the main entry point that the Event trigger will call
    /**
    * 
    * this is the main entry point that the Event trigger will call
    * @desc callout [CodeScan Fix]
    */
    public Boolean callout(Id recordId)
    {
        ilib_LogEvent.push(logTitle + '.callout()');
        validateRequiredMetadataFields();

        this.recordId = recordId;
        log = ilib_LogInterface.initiateLog(interfaceDetails);

        String strErrorMessage = null;
        HttpResponse res;
        try
        {
            validateId();
            res = calloutImpl();
        }
        catch (Exception e)
        {
            strErrorMessage = e.getMessage() + '\n' + e.getStackTraceString();
            ilib_LogEvent.message('ERROR:\n' + e.getMessage());
            ilib_LogEvent.pop();
		    ilib_LogEvent.emit();
            throw e;
        }

        Boolean isSuccess = String.isBlank(strErrorMessage);

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strErrorMessage),
            recordId,
            res
        );

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, recordId, null, ilib_LogInterface.RESULT_FAIL, strErrorMessage);
            ApexExceptions.emit('Interface: ' + interfaceDetails.name, log.logRecordId, strErrorMessage);
        }
        ilib_LogEvent.pop();
		ilib_LogEvent.emit();
        return isSuccess;
    }

    /**
    * 
    *
    * @desc validateId [CodeScan Fix]
    */
    private void validateId()
    {
        try {
            Id.valueOf(recordId);
        } catch (Exception e) {
            throw new UtilsRest.InterfaceException(interfaceDetails.name + ' error: record Id (' + recordId + ') is not valid.');
        }
    }

    /**
    * 
    *
    * @desc CalloutImpl [CodeScan Fix]
    */
    public HttpResponse calloutImpl()
    {
        ilib_LogEvent.push(logTitle + '.calloutImpl()');
        
        idata = retrieveCalloutData();

        validateFields();

        //DCP-46834:Start- Set JSON variable
        strJson = createJSON();
        //DCP-46834:End- Set JSON variable
        ilib_LogInterface.addJsonToLog(log, strJson);
        ilib_LogEvent.pop();
        return executeCallout(strJson);
    }
    /*
    // retrieve all the records needed for the callout
    // ex. for a contact you would likely query both contact and account information
    */
    protected abstract ilib_CalloutData retrieveCalloutData();
    /*
    // is all the required data present? Any other data requirements for integration?
    // those go here
    */
    protected abstract void validateFields();
    /*
    // turn the data from retrieveCalloutData() into the JSON the target system expects
    */
    protected abstract String createJSON();
    /*
    // process the result, update records, etc
    */
    protected abstract void handleResult(HTTPResponse res);

    /**
    * 
    *
    * @desc executeCallout [CodeScan Fix]
    */
    public virtual HTTPResponse executeCallout(String strJson)
    {
        String strError = null;
        HTTPResponse res;

        try
        {
            HTTPRequest req = createHttpRequest(strJson);
            req.setTimeout(HTTP_TIMEOUT);

            if (Test.isRunningTest())
                res = new MockHTTPCallout().respond(req);
            else
                res = UtilsRest.send(req);
            ilib_LogEvent.message('res ::::'+res );
            ilib_LogEvent.message('res body ::::' + res.getBody());

            if ((null != res) &&
                (!String.isBlank(res.getBody())))
            {
                handleResult(res);
            }
        }
        catch (Exception e)
        {
            ilib_LogEvent.message(e.getMessage());
            ilib_LogEvent.message(e.getStackTraceString());
            strError = e.getMessage() + '\n' + e.getStackTraceString();
            throw e;
        }
        
        if(handlesError())
            return res;

        Integer intStatusCode = (res != null ? res.getStatusCode() : null);
        String strStatus = (res != null ? res.getStatus() : null);
        
        Boolean isSuccess = SUCCESS_STATUS_CODES.contains(intStatusCode);
        if (!isSuccess)
            throw new UtilsRest.InterfaceException('Unable to execute callout:\nError message: ' + strError+'\n Status Code: '+intStatusCode+'\n Status: '+strStatus);
        return res;
    }

    /**
     * @author Illumina
     * @description if handling error in derived class then return true from there after overriding
     */
    protected virtual Boolean handlesError()
    {
        return false;
    }

    private HTTPRequest createHttpRequest(String strJson)
    {
        String interfaceNameWithougSpaces = interfaceDetails.name.replace(' ', '_');
        ilib_LogEvent.message('interfaceNameWithougSpaces ' + interfaceNameWithougSpaces);
        Map<String, String> config = UtilsRest.getIntegrationEndpoint(interfaceNameWithougSpaces);
        ilib_LogEvent.message('interface config ' + config);

        HttpRequest req = UtilsRest.createHttpRequest(config.get('Endpoint'), config.get('ApiKey'), config.get('Authorization'));

        req.setBody(strJson);

        return req;
    }

}
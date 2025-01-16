/*@ author       : Kushagra Desai
* @ date         : 22-June-2020
* @ Description  : Lead Email verificaton Apex Controller
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*       Developer               Date            Description
*       Maruthi B           02-Feb-2022         Added getRecordData,getEmailVerificationFields methods and Modified sendVerificationRequest as part of PM-22
*       Sipra               04-Feb-2022         Modified sendVerificationRequest as part of PM-97
*       Abhinav             04-Feb-2022         Modified sendVerificationRequest as part of PM-75
*       Abhinav Gupta       03-Feb-2022         Added check for Is Active and Deactivation reason as a part of PM-75.
*       Sipra Routray       03-Feb-2022         Added check for Is Active and Deactivation reason as a part of PM-97.
*       Ashwin              11-July-2022        INC0403213 - Skip AuraHandledException and log exception when triggered from Async or backend process
*       Ashwin              06-Mar-2023         INC0455686 - Move Bypass Trigger revert DML to finally block in getResult()
*       Arpan Shah          21-Nov-2023         CMCM-4601  - Add instrumentation in Email Verification Functionality To help discover issues with Email Verification tool
*       Gerardo Garcia      03-Mar-2024         CMCM-5889 - Refactor throws exception
*    --------------------------------------------------------------------------------------------------

*/
public with sharing class EmailVerificationController extends ilib_RestReceiver {
    
    public static final String INTERFACENAME = 'Email_Verify';
    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public static final String ERROR = 'Error-';
    public static final String APPLICATION_JSON = 'application/json';    
    public static final String CODEPARAMETEREMAILVERIFICATIONFIELDS = '_Email_Verification_Fields';
    public static final String VERIFICATION_FAILURE = 'Verification Failure';
    public static final String VERIFIED_SUCCESSFULLY = 'Verified Successfully';
    public static final String VERIFIED_WITH_WARNING = 'Verified With Warning';
    public static final String CONTACT = 'Contact';
    public static final String EMAIL_VERIFICATION_FAILED = 'Email Verification Failed';
    public static final String LOG_TITLE = 'EmailVerificationController';       //INC0403213
    
    // Wrapper class for response
    /*
    * @author Maruthi B
    * @Description Wrapper class for response    
    */
    public class LeadVerifyResponseWrapper {
        public VerifyEmailResultObject verifyEmailResult;
    }

    /*
    * @author Maruthi B
    * @Description Wrapper class for response    
    */
    public class VerifyEmailResultObject {
        public ServiceStatusObject serviceStatus;
        public ServiceResultObject serviceResult;
    }

    /*
    * @author Maruthi B
    * @Description Wrapper class for response    
    */
    public class ServiceStatusObject {
        public string statusNbr;
        public string statusDescription;
    }

    /*
    * @author Maruthi B
    * @Description Wrapper class for response    
    */
    public class ServiceResultObject {
        public ReasonObject reason;
    }

    /*
    * @author Maruthi B
    * @Description Wrapper class for response    
    */
    public class ReasonObject {
        public string code;
        public string description;
    } 


    /*
     *  @AUTHOR:  Maruthi
     *  @DESCRIPTION: Wrapper class for EmailVerificationFields     
     */
    public class EmailVerificationFieldsWrapper {
        public String strQueryFields, strVerificationDate, strVerofocationStatus, strIsActive, strDeactivationReason, strDeactivationReasonComment;
        
        /*
        *  @AUTHOR:  Maruthi
        *  @DESCRIPTION: Wrapper class Constroctor for EmailVerificationFieldsWrapper     
        */
        public EmailVerificationFieldsWrapper(List<String> fieldsList, String objectApiName) {
            strQueryFields = fieldsList[0];
            strVerificationDate = fieldsList[1];
            strVerofocationStatus = fieldsList[2];
            if(objectApiName == CONTACT) {
                strIsActive = fieldsList[3];
                strDeactivationReason = fieldsList[4]; 
                strDeactivationReasonComment = fieldsList[5];        
            }        
        }
    }


    /*
    * @author Kushagra Desai
    * @Description Aura method to send validation request to informatica
    * @param String emailId String Lead Id
    * @return String Response
    */ 
    @AuraEnabled
    public static String sendVerificationRequest(String strEmail, Id recordId, String objectApiName, Boolean boolIsFromLwc) {
        try {
            return sendEmailVerificationRequest(strEmail, recordId, objectApiName);
        } catch (Exception e) {

            if(boolIsFromLwc) {
                ApexExceptions.emit(LOG_TITLE, e, recordId, ilib_LogEvent.MARKETING );
                throw new AuraHandledException(e.getMessage());
            }

            throw e;
        }
    }

    /**
     * @description: Request Email Verification and Updates flags Target Object(Lead, Contact)
     * @param String strEmail: Target Email
     * @param Id recordId: Target id
     * @param String ObjectApiName: Lead or Contact
     */
    private static String sendEmailVerificationRequest(String strEmail, Id recordId, String objectApiName) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE+ '.sendEmailVerificationRequest()');

        Map<String, String> mapInterfaceDetails = UtilsRest.getIntegrationEndpoint(INTERFACENAME);
        String endpoint = getEndPoint(strEmail, mapInterfaceDetails);

        EmailVerificationController instantiated = new EmailVerificationController();
        ilib_RestInterface.InterfaceDetails interfaceDetailsInstance = instantiated.interfaceDetails;
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetailsInstance, endpoint);

        HttpResponse response = proccesRequest(endpoint, mapInterfaceDetails);
        String result = getResult(response, log, recordId, objectApiName);

        return result;
    }

    private static String getEndPoint(String strEmail, Map<String, String> mapInterfaceDetails){
        String strEndPoint = mapInterfaceDetails.get('Endpoint') + strEmail + '?sandbox=' + UtilsRest.sandboxValue();
        ilib_LogEvent.info('EndPoint: '+strEndPoint);
        return strEndPoint;
    }

    private static HttpResponse proccesRequest(String strEndPoint, Map<String, String> mapInterfaceDetails) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint(strEndPoint);
        req.setMethod('GET');
        req.setHeader('apikey', mapInterfaceDetails.get('ApiKey'));
        req.setHeader('Accept', APPLICATION_JSON);
        req.setHeader('Content-Type', APPLICATION_JSON);
        req.setTimeout(120000);
        ilib_LogEvent.info('request: '+ req);

        HttpResponse response = new Http().send(req);
        ilib_LogEvent.info('response:' + response);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return response;
    }

     /*
    * @author Maruthi
    * @Description This method to get result string
    * @return String Response
    */ 
    private static String getResult(HttpResponse response, ilib_LogInterface.LogDetails log, Id recordId, String objectApiName) { 
        ilib_LogEvent.push(LOG_TITLE+'.getResult()');

        Map<String,String> mapStatusCodeToVerificationStatus = new Map<String,String>();
        for(Email_Verification_Matrix__mdt levm : new EmailVerificationMatrixSelector().getAllRecords()) {  //INC0403213 - Moved SOQL to selector
            mapStatusCodeToVerificationStatus.put(levm.StatusNbr__c + '-' + levm.ReasonCode__c, levm.Verification_Status__c);
        }

        cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());     //INC0455686

        try {
            if (response.getStatusCode() != HTTP_POST_SUCCESS_CODE && response.getStatusCode() != HTTP_SUCCESS_CODE ) {
                ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), recordId);
                return ERROR + response.getBody();
            }

            //Modified as part of PM-22
            EmailVerificationController.LeadVerifyResponseWrapper objWrap = (EmailVerificationController.LeadVerifyResponseWrapper) System.JSON.deserialize(response.getBody(), EmailVerificationController.LeadVerifyResponseWrapper.class);
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,response.getStatusCode() + response.getBody(), recordId);

            EmailVerificationFieldsWrapper wrap = getEmailVerificationFields(objectApiName);

            String verificationStatusValue = mapStatusCodeToVerificationStatus.get(objWrap.verifyEmailResult.serviceStatus.statusNbr+'-'+objWrap.verifyEmailResult.serviceResult.reason.code);
            ilib_LogEvent.info('verificationStatusValue: ' + verificationStatusValue);

            cs.Bypass_All_Triggers__c = true;
            upsert cs cs_Apex_Settings__c.Id;

            stampRecord(verificationStatusValue, wrap, recordId, objectApiName);

            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return verificationStatusValue;
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE+'.getResult', recordId, e, ilib_LogEvent.MARKETING);
            throw e;
        } finally {     //INC0455686
            cs.Bypass_All_Triggers__c = false;
            upsert cs cs_Apex_Settings__c.Id;
        }
    }

    private static void stampRecord(String verificationStatusValue, EmailVerificationFieldsWrapper wrap, Id recordId, String objectApiName) {
        Sobject objRec = recordId.getSObjectType().newSObject(recordId);
        ilib_LogEvent.info('objRec: '+objRec);

        if(verificationStatusValue == VERIFIED_SUCCESSFULLY
        || verificationStatusValue == VERIFIED_WITH_WARNING) {
            objRec.put(wrap.strVerificationDate, Datetime.now().dateGmt());
        } else {
            objRec.put(wrap.strVerificationDate, null);
        }

        objRec.put(wrap.strVerofocationStatus,verificationStatusValue);

        //PM-97: Email Verification Updates
        if(verificationStatusValue == VERIFICATION_FAILURE && objectApiName == CONTACT) {
            objRec.put(wrap.strIsActive, False);
            objRec.put(wrap.strDeactivationReason, EMAIL_VERIFICATION_FAILED);
        }

        //PM-75 : Email Verification Updates
        if(objectApiName == CONTACT) {
            Contact con = (Contact) getRecordData(recordId, objectApiName, false);
            if(con.Is_Active__c == false 
            && (String.isNotBlank(con.Deactivation_Reason__c)) 
            && con.Deactivation_Reason__c.equals(EMAIL_VERIFICATION_FAILED) 
            && (verificationStatusValue == VERIFIED_SUCCESSFULLY
                || verificationStatusValue == VERIFIED_WITH_WARNING)) {
                objRec.put(wrap.strIsActive, true);
                objRec.put(wrap.strDeactivationReason, null);
                objRec.put(wrap.strDeactivationReasonComment, '');
            }
        }

        update objRec;
    }

    /*
     *  @AUTHOR:  Maruthi
     *  @DESCRIPTION: Callback method Email Verification
     *  @RETURN:  SObject
     *  @Parameters: String, String
    */ 
    @AuraEnabled(cacheable=false)
    public static SObject getRecordData(Id recordId, String objectApiName, Boolean boolIsFromLwc) {
        try {
            EmailVerificationFieldsWrapper wrap = getEmailVerificationFields(objectApiName);
            String dynamicSoql = 'SELECT ' + wrap.strQueryFields + ' FROM '+ objectApiName + ' WHERE ID = :recordId LIMIT 1';
            List<SObject> res = Database.query(dynamicSoql);

            if(res.isEmpty()) {
                throw new EmailVerificationException('Unable to find record with id:' + recordId);
            }

            return res[0];
        } catch (Exception e) {
            if(boolIsFromLwc) {
                ApexExceptions.emit(LOG_TITLE, e, recordId, ilib_LogEvent.MARKETING );
                throw new AuraHandledException(e.getMessage());
            }
            throw e;
        }
    }

    
     /*
     *  @AUTHOR:  Maruthi
     *  @DESCRIPTION: This method to get list fields for query and update
     *  @RETURN:  SObject
     *  @Parameters: String  
    */   
    public static EmailVerificationFieldsWrapper getEmailVerificationFields(String objectApiName) {     
        
        List<Code_Parameter__mdt> codeParameter =new CodeParametersSelector().selectCodeParameterByDeveloperName(new set<String>{objectApiName+CODEPARAMETEREMAILVERIFICATIONFIELDS});        
        return new EmailVerificationFieldsWrapper(codeParameter[0].Value__c.split(';'), objectApiName);               
    }


    /**
     * Custom Exception for the Controller
     */
    public class EmailVerificationException extends Exception { }
}
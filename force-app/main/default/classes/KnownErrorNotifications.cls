/**
*    @author Satya Swain
*    @date   2019-05-28
*    @description   Domain class to check for errors happening in interface or apex class and then store details in a reporting object
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Satya Swain                 28 May 2019            Initial Version
*              Himanshu                    30 Mar 2022            Code Scan Fixes 
              Nitin                       11 July 2022           CMSI-50: Moving KnownErrorNotification to platform event after insert
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class KnownErrorNotifications {
    /**
     * @author  Satya Swain
     * @date   2019-05-28
     * @description wrapperclass for errordetails
    **/
    public with sharing class ErrorDetails
    {
        public String source;
        public Id relatedRecordId;
        public Integer lineNumber;
        public String userErrorMessage;
        public String rawResultMessage;
        public String erpRecordId;
        public Id accountId;
        public String stackTrace;
        public String errorType;
        public String recordTypeName;
        public Id knownErrorId;
        /**
         * @author  Satya Swain
         * @description parameterized constructor called for above wrapper
         * @param String source, Id relatedRecordId, String rawResultMessage
         * @return void
        **/
        public ErrorDetails(String source, Id relatedRecordId, String rawResultMessage)
        {
            this.source = source;
            this.relatedRecordId = relatedRecordId;
            this.rawResultMessage = rawResultMessage;
            this.recordTypeName = 'Interface_Errors';
        }
        /**
         * @author  Satya Swain
         * @description parameterized constructor called for above wrapper
         * @param String source, Id relatedRecordId, String erpRecordId, Id accountId, String rawResultMessage
         * @return void
        **/
        public ErrorDetails(String source, Id relatedRecordId, String erpRecordId, Id accountId, String rawResultMessage)
        {
            this.source = source;
            this.relatedRecordId = relatedRecordId;
            this.rawResultMessage = rawResultMessage;
            this.erpRecordId = erpRecordId;
            this.accountId = accountId;
            this.recordTypeName = 'Interface_Errors';
        }
        /**
         * @author  Satya Swain
         * @description parameterized constructor called for above wrapper
         * @param String source, Exception e, Id relatedRecordId
         * @return void
        **/
        public ErrorDetails(String source, Exception e, Id relatedRecordId)
        {
            this.source = source;
            this.relatedRecordId = relatedRecordId;
            this.lineNumber = e.getLineNumber();
            this.rawResultMessage = e.getMessage();
            this.stackTrace = e.getStackTraceString().abbreviate(4000);
            this.errorType = e.getTypeName().abbreviate(255);
            this.recordTypeName = 'Apex_Exceptions';
        }
        /**
         * @author  Nitin
         * @description CMSI-50 usesing wrapper instead of Exception
         * @param String source, ExceptionWrapper e, Id relatedRecordId
         * @return void
        **/
        public ErrorDetails(String source, ApexExceptions.ExceptionWrapper e, Id relatedRecordId)
        {
            this.source = source;
            this.relatedRecordId = relatedRecordId;
            if(e.lineNumber!=null){
            this.lineNumber = e.lineNumber.intValue();
            }
            this.rawResultMessage = e.message;
            this.stackTrace = e.stackTrace;
            this.errorType = e.type;
            this.recordTypeName = 'Apex_Exceptions';
        }
        /**
         * @author  Satya Swain
         * @description method to match error messages
         * @param Id knownErrorId, String userErrorMessage
         * @return void
        **/
        public void addKnownErrorMatch(Id knownErrorId, String userErrorMessage)
        {
            this.knownErrorId = knownErrorId;
            this.userErrorMessage = userErrorMessage;
        }
    }

    /**
    * @owner Satya Swain
    * @description Checks for Possible Known Errors from Known_Error_Notification__c records using incoming rawResultMessage string from Interface Errors
    */
    public static void checkForKnownErrors (
        ilib_RestInterface.InterfaceDetails interfaceDetails,
        Id interfaceLogId,
        String erpRecordId,
        String erpAccountId,
        String result,
        String rawResultMessage
    ) {
        try
        {
            if (result == ilib_LogInterface.RESULT_SUCCESS)
                return;

            // get related account ID
            Id accountId;
            if (!String.isBlank(erpAccountId))
            {
                List<Account> retrievedAccount = [SELECT Id FROM Account WHERE ERP_Customer_Id__c = :erpAccountId];
                accountId = retrievedAccount.size() > 0 ? retrievedAccount.get(0).Id : null;
            }

            ErrorDetails errorDetails = new ErrorDetails(interfaceDetails.name, interfaceLogId, erpRecordId, accountId, rawResultMessage);
            checkForKnownErrors(errorDetails);
        }
        catch (Exception e)
        {
            // this call should not impact functional code
			System.debug('Inside KnownErrorNotifications the exception is '+e.getMessage());
        }
    }
    /**
     * @author  Satya Swain
     * @description Checks for Possible Known Errors from Known_Error_Notification__c records
     * @param String source, Exception e
     * @return void
    **/
    public static void checkForKnownErrors(String source, Exception e)
    {
        checkForKnownErrors(source, null, e);
    }
    /**
     * @author  Nitin
     * @description CMSI-50 using ExceptionWrapper instead of exception
     * @param String source, ExceptionWrapper e
     * @return void
    **/
    public static void checkForKnownErrors(String source, ApexExceptions.ExceptionWrapper e)
    {
        checkForKnownErrors(source, null, e);
    }
    /**
     * @author  Satya Swain
     * @description Checks for Possible Known Errors from Known_Error_Notification__c records
     * @param String source, Id relatedRecordId, Exception e
     * @return void
    **/
    public static void checkForKnownErrors(String source, Id relatedRecordId, Exception e)
    {
        ErrorDetails errorDetails = new ErrorDetails(source, e, relatedRecordId);
        checkForKnownErrors(errorDetails);
    }
    /**
     * @author  Nitin
     * @description CMSI-50 using ExceptionWrapper instead of exception
     * @param String source, Id relatedRecordId, ExceptionWrapper e
     * @return void
    **/
    public static void checkForKnownErrors(String source, Id relatedRecordId, ApexExceptions.ExceptionWrapper e)
    {
        ErrorDetails errorDetails = new ErrorDetails(source, e, relatedRecordId);
        checkForKnownErrors(errorDetails);
    }
    /**
     * @author  Satya Swain
     * @description Checks for Possible Known Errors from Known_Error_Notification__c records
     * @param String source, Id interfaceLogId, String message
     * @return void
    **/
    public static void checkForKnownErrors(String source, Id interfaceLogId, String message)
    {
        ErrorDetails errorDetails = new ErrorDetails(source, interfaceLogId, message);
        checkForKnownErrors(errorDetails);
    }
    /**
     * @author  Satya Swain
     * @description Checks for Possible Known Errors from Known_Error_Notification__c records
     * @param String source, Exception e, Id interfaceLogId
     * @return void
    **/
    public static void checkForKnownErrors(String source, Exception e, Id interfaceLogId)
    {
        ErrorDetails errorDetails = new ErrorDetails(source, interfaceLogId, e.getMessage());
        checkForKnownErrors(errorDetails);
    }
     /**
     * @author  Nitin
     * @description CMSI-50 using ExceptionWrapper instead of exception
     * @param String source, ExceptionWrapper e, Id interfaceLogId
     * @return void
    **/
    public static void checkForKnownErrors(String source, ApexExceptions.ExceptionWrapper e, Id interfaceLogId)
    {
        ErrorDetails errorDetails = new ErrorDetails(source, interfaceLogId, e.Message);
        checkForKnownErrors(errorDetails);
    }

    /**
    * @owner Satya Swain
    * @description Checks for Possible Known Errors from Known_Error_Notification__c records using incoming rawResultMessage string from Apex Exceptions
    */
    private static void checkForKnownErrors(ErrorDetails errorDetails)
    {
        Id knownErrorId;
        String userErrorMessage;

        try
        {
            // query for potential known errors by source
            List<Known_Error_Notification__c> lstKnownErrorNotification = new KnownErrorNotificationsSelector().selectKnownErrorsBySource(errorDetails.source);
            System.debug('TTN: lstKnownErrorNotification ' + lstKnownErrorNotification);

            // check for match with current error
            Map<Id, String> idtoResult = getMatchResults(lstKnownErrorNotification, errorDetails.rawResultMessage);
            if (idtoResult.isEmpty()) return;

            for (Id idError : idtoResult.keySet())
            {
                knownErrorId = idError;
                userErrorMessage = idtoResult.get(idError);
            }
            System.debug('TTN: knownErrorId ' + knownErrorId);
            System.debug('TTN: userErrorMessage ' + userErrorMessage);

            // add error match details
            errorDetails.addKnownErrorMatch(knownErrorId, userErrorMessage);
            System.debug('TTN: errorDetails ' + errorDetails);

            // log error details for reporting
            Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Error_Notification__c.getRecordTypeInfosByDeveloperName();
            Error_Notification__c objErrorNotification = new Error_Notification__c(
                Source__c = errorDetails.source,
                Interface_Log__c = errorDetails.relatedRecordId,
                ERP_Record_Id__c = errorDetails.erpRecordId,
                Account__c = errorDetails.accountId,
                Result__c = userErrorMessage,
                Full_Error_Text__c = errorDetails.rawResultMessage.abbreviate(32768),
                RecordTypeId = rts.get(errorDetails.recordTypeName).getRecordTypeId(),
                Known_Error_Notification__c = knownErrorId
            );
            insert objErrorNotification;
            System.debug('TTN: objErrorNotification ' + objErrorNotification);

            // publish platform event for notification to user
            Process_Known_Error__e knownErrorEvent = new Process_Known_Error__e(Notification_Id__c = objErrorNotification.Id);
            System.debug('TTN: knownErrorEvent ' + knownErrorEvent);
            System.debug(LoggingLevel.ERROR, knownErrorEvent);

            EventBus.publish(knownErrorEvent);
        }
        catch (Exception e)
        {
            // this call should not impact functional code
			System.debug('Inside KnownErrorNotifications the exception is '+e.getMessage());
        }
    }

    /**
    * @owner Satya Swain
    * @description Returns Map of Id to String of Message based on Pattern Matching on incoming Raw Message value with Known Error Pattern
    */
    private static Map<Id,String> getMatchResults(List<Known_Error_Notification__c> lstKnownErrorNotification, String rawResultMessage)
    {
        Map<Id, String> idtoResult = new Map<Id, String>();

        if (lstKnownErrorNotification.isEmpty()) return idtoResult;

        // get map of known error ID to error notification message
        // based on the raw error message received
        for (Known_Error_Notification__c objKEN : lstKnownErrorNotification)
        {
            Pattern p = Pattern.compile(objKEN.Pattern__c);
            Matcher m = p.matcher(rawResultMessage);
            if (m.find())
            {
                String reportResult = objKEN.Message__c;
                System.debug('@@@ Report Result : '+ reportResult);
                idtoResult.put(objKEN.Id, reportResult);
                break;
            }
        }

        return idtoResult;
    }

}
/**
*    @author Illumina
*    @date   2018
*    @description    Log Apex Exceptions
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                     Date                   Description
*         Ashwin                        2022-01-17             TASK0699567: Include errored Ids in Logs and handle bulk failed records in single log
*         Ashwin                        2022-03-11             DCP-52339: Log specific exceptions from saveResult
*         Himanshu                      2022-03-29             Code Scan Fixes  
          Nitin                         2022-04-14             CMSI-7 linking exception records with ILMN debug with transaction id instead of link key
          Nitin                         2022-07-11             CMSI-50 Moving KnownErrorNotification to platform event after insert 
*         Ashwin                        2022-07-14             INC0407615: Log specific exceptions from upsertResult
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApexExceptions extends ilib_SObjectDomain {
    
    /**
    * @author  Satya Swain
    * @description parameterized constructor
    * @param List<Apex_Exception__e> sObjectList
    * @return sObjectList 
    **/
    public ApexExceptions(List<Apex_Exception__e> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
         * @author  Prabhsimran
         * @description constructor for base class
         * @param List<SObject> sObjectList
         * @return sObjectList 
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApexExceptions(sObjectList);
        }
    }
    /**
      * @author  Prabhsimran
      * @description transfer the event data to log table rows
      * @param List<SObject> sObjectList
      * @return sObjectList 
    **/
    public override void onAfterInsert()
    {
        saveExceptionLogRecords();
	}

    /**
      * @author  Satya Swain
      * @description Public API
      * @param List<SObject> sObjectList
      * @return sObjectList 
    **/
    public static void emit(String source, Exception e)
    {
        emit(source, null, e);
    }
     /**
      * @author  Biswajeet Sahoo
      * CMSI-38
    **/
   public static void emit(String source, Exception e, string workstream) 
    {
       Apex_Exception__e ae = getExceptionInstance(source, null, e.getLineNumber(), e.getMessage(), e.getStackTraceString(), e.getTypeName(), null, workstream);
       ilib_LogEvent.error(e.getMessage());
       Database.SaveResult res = EventBus.publish(ae);
       System.debug(String.valueOf(res));
    }
    /**
      * @author  Satya Swain
      * @description given an exception occurred in Apex, publish its details to the event bus which will be handled in the trigger method above
      * @param String source, Id relatedRecord, Exception e
      * @return void
      *************************************************************
      @ModifiedBy : Biswajeet Sahoo
      *************************************************************
    **/
     
    public static void emit(String source, Id relatedRecord, Exception e)
    {
        Apex_Exception__e ae ;
        ae = getExceptionInstance(source, relatedRecord, e.getLineNumber(), e.getMessage(), e.getStackTraceString(), e.getTypeName(), null, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : '' );
        System.debug(LoggingLevel.ERROR, ae);
        Database.SaveResult res = EventBus.publish(ae);
        System.debug(res);
    }

     /**
      * @author  Biswajeet Sahoo
      * @description given an exception occurred in Apex, publish its details to the event bus which will be handled in the trigger method above
      * @param String source, Id relatedRecord, Exception e, String workstream
      * @return void
     
    **/
     
    public static void emit(String source, Id relatedRecord, Exception e, String workstream)
    {
        Apex_Exception__e ae ;
        ae = getExceptionInstance(source, relatedRecord, e.getLineNumber(), e.getMessage(), e.getStackTraceString(), e.getTypeName(), null, workstream );
        System.debug(LoggingLevel.ERROR, ae);
        Database.SaveResult res = EventBus.publish(ae);
        System.debug(res);
    }
    
    /**
     *  @author Ashwin Kumar
     *  @description - method to log exception based on errorIds or errorInfo
     *  @param String - Exception e, source, List<Sobject>
     *  @return void
    **/
    public static void emit(Exception e, String source, List<SObject> lstSobjects) {
        String relatedRecords = UtilsCollection.concatenateToStringWithDelimiter(lstSobjects, 'Id', ';');
        emit(e, source, relatedRecords);
    }

     /**
     *  @author Biswajeet Sahoo
     *  @description - method to log exception based on errorIds or errorInfo
    **/
    public static void emit(Exception e, String source, List<SObject> lstSobjects, String workstream) {
        String relatedRecords = UtilsCollection.concatenateToStringWithDelimiter(lstSobjects, 'Id', ';');
        emit(e, source, relatedRecords, workstream);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - method to log exception based on errorIds or errorInfo
     *  @param String - Exception e, source, errorInfo
     *  @return void
    **/
    public static void emit(Exception e, String source, String errorInfo) {
        Apex_Exception__e ae;
        String abbreviatedError = String.isNotBlank(errorInfo) ? errorInfo.abbreviate(255) : '';
        ae = getExceptionInstance(source, abbreviatedError, e.getLineNumber(), e.getMessage(), e.getStackTraceString(), e.getTypeName(), null, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : '' );  
        System.debug(LoggingLevel.ERROR, ae);
        Database.SaveResult res = EventBus.publish(ae);
        System.debug(res);
    }

    /**
     *  @author Biswajeet Sahoo
     *  @description - method to log exception based on errorIds or errorInfo
    **/
    public static void emit(Exception e, String source, String errorInfo, String workstream) {
        Apex_Exception__e ae;
        String abbreviatedError = String.isNotBlank(errorInfo) ? errorInfo.abbreviate(255) : '';
        ae = getExceptionInstance(source, abbreviatedError, e.getLineNumber(), e.getMessage(), e.getStackTraceString(), e.getTypeName(), null, workstream);  
        System.debug(LoggingLevel.ERROR, ae);
        Database.SaveResult res = EventBus.publish(ae);
        System.debug(res);
    }

    /**
      * @author Prabhsimran
      * @description given an exception occurred in Apex, publish its details to the event bus which will be handled in the trigger method above
      * @param String source, Id interfaceLog, String message
      * @return void
    **/
    public static void emit(String source, Id interfaceLog, String message)
    {
        Apex_Exception__e ae = getExceptionInstance(source, null, null, message, '', '', interfaceLog, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : '');
        System.debug(LoggingLevel.ERROR, ae);
        Database.SaveResult res = EventBus.publish(ae);
        System.debug(res);
    }

    /**
      * @author Biswajeet
      * @description given an exception occurred in Apex, publish its details to the event bus which will be handled in the trigger method above
      * @param String source, Id interfaceLog, String message, String workstream
      * @return void
    **/
    public static void emit(String source, Id interfaceLog, String message, String workstream)
    {
        Apex_Exception__e ae = getExceptionInstance(source, null, null, message, '', '', interfaceLog, workstream);
        System.debug(LoggingLevel.ERROR, ae);
        Database.SaveResult res = EventBus.publish(ae);
        System.debug(res);
    }
    
     /**
      * @author Biswajeet
      * @param String source, String message, String workstream
      * @return void
    **/
    public static void emit(String source, String message, String workstream)
    {
        Apex_Exception__e ae = getExceptionInstance(source, null, null, message, '', '', null, workstream);
        System.debug(LoggingLevel.ERROR, ae);
        Database.SaveResult res = EventBus.publish(ae);
        System.debug(res);
    }
     /**
      * @author  Satya Swain
      * @description given an exception occurred in Apex, publish its details to the event bus which will be handled in the trigger method above
      * @param String source, Exception e, Id interfaceLog
      * @return void
    **/
    public static void emit(String source, Exception e, Id interfaceLog)
    {
        Apex_Exception__e ae;
        ae = getExceptionInstance(source, null, e.getLineNumber(), e.getMessage(), e.getStackTraceString(), e.getTypeName(), interfaceLog, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : '');
        System.debug(LoggingLevel.ERROR, ae);
        Database.SaveResult res = EventBus.publish(ae);
        System.debug(res);
    }

     /**
      * @author  Biswajeet
      * @description given an exception occurred in Apex, publish its details to the event bus which will be handled in the trigger method above
      * @param String source, Exception e, Id interfaceLog, String workstream
      * @return void
    **/
    public static void emit(String source, Exception e, Id interfaceLog, String workstream)
    {
        Apex_Exception__e ae;
        ae = getExceptionInstance(source, null, e.getLineNumber(), e.getMessage(), e.getStackTraceString(), e.getTypeName(), interfaceLog, workstream);
        System.debug(LoggingLevel.ERROR, ae);
        Database.SaveResult res = EventBus.publish(ae);
        System.debug(res);
    }
    /**
      * @author  Satya Swain
      * @description Added by Satya Swain for PRB0042658
      * @param List<Database.SaveResult> results, String source
      * @return void
    **/
    
    public static void emitSaveErrors(List<Database.SaveResult> results, String source)
    {
        List<Apex_Exception__e> lstApexException = new List<Apex_Exception__e>();
            
        for (Database.SaveResult res : results)
        {
            if (!res.isSuccess())
            {
                for(Database.Error err : res.getErrors())
                {
                    String errorMessage = err.getStatusCode() + ',' + err.getMessage();
                    System.debug('@@@@ Error Occurred while saving, details: '+errorMessage);
                    lstApexException.add(ApexExceptions.getExceptionInstance(source, res.getId(), null, errorMessage, '', '', null, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : ''));   //TASK0699567
                }
            }
        }
        List<Database.SaveResult> lstRes = EventBus.publish(lstApexException);
        System.debug(lstRes);
    }
    /**
      * @author  Satya Swain
      * @description Added by Satya Swain for INC0253701
      * @param List<Database.SaveResult> results, String source
      * @return void
    **/

    public static void emitDeleteErrors(List<Database.DeleteResult> results, String source)
    {
        List<Apex_Exception__e> lstApexException = new List<Apex_Exception__e>();   //TASK0699567
        for(Database.DeleteResult res : results)
        {
            if(!res.isSuccess())
            {
                for(Database.Error err : res.getErrors())
                {
                    String errorMessage = err.getStatusCode() + ': '+ err.getMessage();
                    System.debug('@@@@ Error Occurred while deleting, details: '+errorMessage);
                    lstApexException.add(ApexExceptions.getExceptionInstance(source, res.getId(), null, errorMessage, '', '', null, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : ''));   //TASK0699567
                }
            }
        }
        List<Database.SaveResult> lstRes = EventBus.publish(lstApexException);      //TASK0699567
        System.debug(lstRes);
    }
    /**
      * @author  Satya Swain
      * @description emitting upsert errors
      * @param List<Database.SaveResult> results, String source
      * @return void
    **/
    public static void emitUpsertErrors(List<Database.UpsertResult> results, String source)
    {
        List<Apex_Exception__e> lstApexException = new List<Apex_Exception__e>();   //TASK0699567
        for(Database.UpsertResult res : results)
        {
            if(!res.isSuccess())
            {
                for(Database.Error err : res.getErrors())
                {
                    String errorMessage = err.getStatusCode() + ': '+ err.getMessage();
                    System.debug('@@@@ Error Occurred while upsert, details: '+errorMessage);
                    lstApexException.add(ApexExceptions.getExceptionInstance(source, res.getId(), null, errorMessage, '', '', null, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : ''));   //TASK0699567
                }
            }
        }
        List<Database.SaveResult> lstRes = EventBus.publish(lstApexException);      //TASK0699567
        System.debug(lstRes);
    }

    // ******************************
    // Private methods
    // ******************************

    private static Apex_Exception__e getExceptionInstance(String source, String relatedRecord, Decimal lineNumber, String message, String stackTrace, String type, Id interfaceLog, String workstream)
    {
		Apex_Exception__e ae = new Apex_Exception__e(
            Source__c = string.isNotBlank(source) ? source.abbreviate(255) : '',
            Related_Record__c = relatedRecord,
            Line_Number__c = lineNumber,
            Message__c = string.isNotBlank(message) ? message.abbreviate(4000) : '',
            Stack_Trace__c = string.isNotBlank(stackTrace) ? stackTrace.abbreviate(4000) : '',
            Type__c = string.isNotBlank(type) ? type.abbreviate(255) : '',
            Interface_Log__c = interfaceLog,
            Running_User_Id__c = UserInfo.getUserId(),
            //CMSI-38 populating workstream
            Workstream__c = workstream,
            //CMSI-7 populating Transaction id
            Transaction_Id__c = ilib_LogEvent.getTransactionId()
        );

        // the presence of a link key means there are debug logs
        // which we can link to this error log
        if (String.isNotBlank(ae.Transaction_Id__c))
        {
            ilib_LogEvent.forcePersistLogsAndLinkToError();
        }

        return ae;
    }

    private List<Exception_Log__c> saveExceptionLogRecords()
    {
        // confirm user IDs exist by querying User table
        Map<Id, User> idToUser = confirmUserIdsExist();

        List<Exception_Log__c> exceptions = new List<Exception_Log__c>();
        for (Apex_Exception__e e : (List<Apex_Exception__e>)records)
        {
            Id userId = null;
            if (idToUser.containsKey(e.Running_User_Id__c)) userId = idToUser.get(e.Running_User_Id__c).Id;

            exceptions.add(new Exception_Log__c(
                Interface_Log__c = e.Interface_Log__c,
                Line_Number__c = e.Line_Number__c,
                Message__c = e.Message__c,
                Related_Record__c = e.Related_Record__c,
                Source__c = e.Source__c,
                Stack_Trace__c = e.Stack_Trace__c,
                Type__c = e.Type__c,
                User__c = userId,
                Transaction_Id__c = e.Transaction_Id__c,
                Workstream__c = e.Workstream__c,
               Org_Id__c= UserInfo.getOrganizationId()
            ));
            //CMSI-50
            ExceptionWrapper exceptionWrappers= new ExceptionWrapper(  e.Message__c,  e.Stack_Trace__c,  e.Type__c,  e.Line_Number__c);
            if(e.Related_Record__c!=Null)
            {
                try{
                    Id record= e.Related_Record__c;
                    KnownErrorNotifications.checkForKnownErrors(e.Source__c, e.Related_Record__c, exceptionWrappers);
                }catch(exception ex){
                    KnownErrorNotifications.checkForKnownErrors(e.Source__c, exceptionWrappers);
                }
            }else if(e.Interface_Log__c!=Null){
                if(e.Line_Number__c!=Null)
                    KnownErrorNotifications.checkForKnownErrors(e.Source__c, exceptionWrappers,  e.Interface_Log__c);
                else 
                    KnownErrorNotifications.checkForKnownErrors(e.Source__c, e.Interface_Log__c, e.Message__c);
            }
            else if(e.Related_Record__c==Null & e.Interface_Log__c==Null)
                KnownErrorNotifications.checkForKnownErrors(e.Source__c, null, e.Message__c);        
        }

        System.debug('ApexExceptions received ' + exceptions);
        insert exceptions;
        return exceptions;
    }

   

    private Map<Id, User> confirmUserIdsExist()
    {
        Set<Id> userIds = UtilsCollection.getSetOfIds(records, 'Running_User_Id__c');
        return new Map<Id, User> ([SELECT Id FROM User WHERE Id IN :userIds]);
    }

    /**
    * method:emitUpdateErrorsWithRelatedRecord
    * Description: emit the error incase of database DMLs with Related record populated
    */
    public static void emitUpdateErrorsWithRelatedRecord(List<Database.SaveResult> result, String source, List<sObject> lstsObject) {
        List<Apex_Exception__e> lstApexException = new List<Apex_Exception__e>();   //TASK0699567
        for(Integer i=0; i < result.size(); i++){
            if(!result.get(i).isSuccess()){
                Database.Error error =  result.get(i).getErrors().get(0);
                String failedId = !lstsObject.isEmpty() ? lstsObject.get(i).Id : null;
                lstApexException.add(ApexExceptions.getExceptionInstance(source, failedId, null, error.getMessage(), null, null, null, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : ''));    //TASK0699567
            }
        }
        List<Database.SaveResult> lstRes = EventBus.publish(lstApexException);      //TASK0699567
        System.debug(lstRes);
    }

    /**
    * @author Ashwin
    * @decription log specific exceptions only - SaveResult
    * Story DCP-52339
    * @param String - SaveResults, source, List<Sobject> records, Set<String> errorToExclude, fieldToStore 
    * @return void
    **/
    public static void emitSpecificExceptions(List<Database.SaveResult> results, String source, List<sObject> lstsObjects, Set<String> errorsToExclude, String fieldToStore) {
        List<Apex_Exception__e> lstApexException = new List<Apex_Exception__e>();
        for (Integer i=0; i < results.size(); i++) {

            if (results.get(i).isSuccess()) { continue; }

            Set<String> allErrorMessages = new Set<String>();
            String errorMsg;
            for (Database.Error e : results.get(i).getErrors()) {
                errorMsg  = e.getMessage();
                if(String.isBlank(errorMsg)) { continue; }
                allErrorMessages.addAll(UtilsCollection.addUnknownErrors(errorMsg, errorsToExclude));
            }

            if (allErrorMessages.isEmpty()) { continue; }

            String failedId = lstsObjects.isEmpty() ? null : (String)lstsObjects.get(i).get(fieldToStore);

            lstApexException.add(
                getExceptionInstance(source, failedId, null, allErrorMessages.toString(), '', '', null, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : '' )
            );
        }
        if(!lstApexException.isEmpty()) { EventBus.publish(lstApexException); }
    }

    /**
    * @author Ashwin
    * @decription log specific exceptions only - DeleteResult
    * Story DCP-52339
    * @param String - DeleteResults, source, List<Sobject> records, Set<String> errorToExclude, fieldToStore 
    * @return void
    **/
    public static void emitSpecificExceptions(List<Database.DeleteResult> results, String source, List<sObject> lstsObjects, Set<String> errorsToExclude, String fieldToStore) {
        List<Apex_Exception__e> lstApexException = new List<Apex_Exception__e>();
        for (Integer i=0; i < results.size(); i++) {

            if (results.get(i).isSuccess()) { continue; }

            Set<String> allErrorMessages = new Set<String>();
            String errorMsg;
            for (Database.Error e : results.get(i).getErrors()) {
                errorMsg  = e.getMessage();
                if(String.isBlank(errorMsg)) { continue; }
                allErrorMessages.addAll(UtilsCollection.addUnknownErrors(errorMsg, errorsToExclude));
            }

            if (allErrorMessages.isEmpty()) { continue; }

            String failedId = lstsObjects.isEmpty() ? null : (String)lstsObjects.get(i).get(fieldToStore);

            lstApexException.add(
                getExceptionInstance(source, failedId, null, allErrorMessages.toString(), '', '', null, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : '' )
            );
        }
        if(!lstApexException.isEmpty()) { EventBus.publish(lstApexException); }
    }
    /**
    * @author Nitin
    * @decription wrapper class for exception
    * Story CMSI-50
    **/
    public class ExceptionWrapper{
        public String  message{get; set;}
        public String stackTrace{get; set;}
        public String type{get; set;}
        public decimal lineNumber{get; set;}

        /**
        * @author Nitin
        * @decription 
        * Story CMSI-50
        **/
        public ExceptionWrapper(String message, String stackTrace, String type, decimal lineNumber){
            this.message=message;
            this.stackTrace=stackTrace;
            this.type=type;
            this.lineNumber=lineNumber;
        }
    }
    /**
    * @author Ashwin
    * @decription log specific exceptions only - UpsertResult
    * Story INC0407615
    * @param String - UpsertResults, source, List<Sobject> records, Set<String> errorToExclude, fieldToStore 
    * @return void
    **/
    public static void emitSpecificExceptions(List<Database.UpsertResult> results, String source, List<sObject> lstsObjects, Set<String> errorsToExclude, String fieldToStore) {
        List<Apex_Exception__e> lstApexException = new List<Apex_Exception__e>();
        for (Integer i=0; i < results.size(); i++) {

            if (results.get(i).isSuccess()) { continue; }

            Set<String> allErrorMessages = new Set<String>();
            String errorMsg;
            for (Database.Error e : results.get(i).getErrors()) {
                errorMsg  = e.getMessage();
                if(String.isBlank(errorMsg)) { continue; }
                allErrorMessages.addAll(UtilsCollection.addUnknownErrors(errorMsg, errorsToExclude));
            }

            if (allErrorMessages.isEmpty()) { continue; }

            String failedId = lstsObjects.isEmpty() ? null : (String)lstsObjects.get(i).get(fieldToStore);

            lstApexException.add(
                getExceptionInstance(source, failedId, null, allErrorMessages.toString(), '', '', null, ilib_LogEvent.getWorkstream() != null ? ilib_LogEvent.getWorkstream() : '' )
            );
        }
        if(!lstApexException.isEmpty()) { EventBus.publish(lstApexException); }
    }
    
}
/**
 * @File Name          : ilib_RestReceiver.cls
 * @Description        : 
 * @Author             : Vaibhav.SFDoc
 * @Group              : 
 * @Last Modified On   : 01-04-2023
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0       6/9/2020        Vaibhav.SFDoc          Initial Version
 *           12/14/2022      Pooja                  Modified Receive() method as part of DCP-56196
**/
public abstract class ilib_RestReceiver {

    public ilib_RestInterface.InterfaceDetails interfaceDetails;
    private String logTitle;
    private String logInterfaceId;//DCP-56196
    @testVisible private Boolean testClassCoverage = false;//DCP-56196
    private static final String CUSTOM_EXCEPTION = 'Test coverage for catch block';//DCP-56196

    /**
     * @author Illumina
     * @description 
     */
    public ilib_RestReceiver()
    {
        logTitle = getThisClassName();
        interfaceDetails = ilib_RestInterface.getInterfaceDetails(logTitle);
        ilib_LogEvent.rootTitle = logTitle;
        ilib_LogEvent.message('interfaceDetails-->'+interfaceDetails);
    }

    /**
     * @author Illumina
     * @description 
     */
    public String getThisClassName()
    {
        return String.valueOf(this).split(':')[0];
    }

    /**
     * @author Illumina
     * @description 
     */
    public void addFriendlyJsonToLog(ilib_LogInterface.LogDetails log, Object dataWrapper)
    {
        ilib_RestInterface.addFriendlyJsonToLog(log, dataWrapper);
    }

    /**
     * @param tableName      name of the table this interface represents, e.g. OpportunityLineItem
     * @param pathToAccount  soql path from this table to Account, e.g. Opportunity.Account
     * @param recordId       id of current record
     *
     * @return               ERP Id of the related customer
     **/
    public static String getRelatedErpCustomerId(String tableName, String pathToAccount, Id recordId)
    {
        if (recordId == null) return '';

        String soql = 'SELECT Id, ' + pathToAccount + '.ERP_Customer_Id__c FROM ' + tableName + ' WHERE Id = :recordId';
        try
        {
            List<SObject> results = Database.query(soql);
            if (results.size() == 0) return '';

            return UtilsObject.getDeepStringFromObject(results.get(0), pathToAccount + '.ERP_Customer_Id__c');
        }
        catch (Exception e)
        {
            // no worries
        }

        return '';
    }
    /**
     * @author Illumina
     * @description 
     */
    public virtual void doBusinessLogic() { }

    // NOTE: added to restore build of ApttusOrderDataReceiver
    public Map<Object, Object> mapData = new Map<Object, Object>();

    /**************************************************
     * new code
     **************************************************/

    ///////////////////////////////////////////////////////////
    // methods decsendents must implement
    ///////////////////////////////////////////////////////////
    /**
     * @author Illumina
     * @description these hold the data structures the incoming json data will be deserialized into
     in base class inherit from ilib_ReceivedData and include instance variables of the deserialized types
     */
    public abstract class ilib_ReceivedData { }
    protected ilib_ReceivedData idata;

    // TODO: make these two methods abstract once all descendents are ready
    /**
     * @author Illumina
     * @description convert the string JSON into ilib_ReceivedData
     */
    protected virtual ilib_ReceivedData deserializeJson(String jsonInput)
    {
        return null;
    }

    /**
     * @author Illumina
     * @description using idata, build a UOW instance with all the sobjects and relationships actualized
     */
    protected virtual ilib_SObjectUnitOfWork buildUnitOfWork()
    {
        return null;
    }

    ///////////////////////////////////////////////////////////
    // methods decsendents may optionally implement
    ///////////////////////////////////////////////////////////
    /**
     * @author Illumina
     * @description if the interface updates a single parent record
     parse idata for it and return it here
     this method will be called after data is persisted
     */
    protected virtual Id findSingleRecordId()
    {
        return null;
    }

    /**
     * @author Illumina
     * @description  if any extra logic needs to run just before or just after building the UOW
                     then override these methods
     */
    protected virtual void preUowBusinessLogic() { }
    /**
     * @author Illumina
     * @description  
     */
    protected virtual void postUowBusinessLogic() { }


    //
    // below this is not-extendible base class functionality
    //

    protected ilib_SObjectUnitOfWork objUnitOfWork;
    protected ilib_LogInterface.LogDetails log;

    private String getJson()
    {
        String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));

        ilib_LogEvent.message('JSON Input:\n' + strJsonInput);
        if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

        return strJsonInput;
    }
     
    /**
     * @author Illumina
     * @description  this method is to be called by the static method annotated by Httppost
                     it parses and serializes the input
                     then builds a UOW for data persistance
                     and finally persists the data, the persistence step might be passed to a queueable for scalability
     */
    public void receive()
    {
        ilib_LogEvent.rootTitle = interfaceDetails.name;
        ilib_LogEvent.push(logTitle + '.receive()');

        String strRestError;

        try
        {
            // get input
            String strJsonInput = getJson();
            log = ilib_LogInterface.initiateLog(interfaceDetails, strJsonInput);

            // parse input
            idata = deserializeJson(strJsonInput);
            ilib_LogEvent.message('serialized data\n' + idata);
            addFriendlyJsonToLog(log, idata);

            // construct UOW
            preUowBusinessLogic();
            objUnitOfWork = buildUnitOfWork();
            postUowBusinessLogic();
            //DCP-56196
            if(testClassCoverage && Test.isRunningTest()) {
                throw new CustomException(CUSTOM_EXCEPTION);
            }
        }
        catch (Exception e)
        {
            strRestError = UtilsRest.handleCustomRestError(e);
            printError(strRestError);
        }

        Boolean isSuccess = String.isBlank(strRestError);
        saveInterfaceLogRecord(isSuccess, strRestError, null);  // primaryRecordId not yet available
        if (isSuccess)
        {
            Boolean checkForSuccess = false;
            //Avoid running this block temporarily    
            if (!useQueueable())
            {
                // save the records asynchronously in a queueable
                ilib_RestQueueableHelper queueableClassInstance = new ilib_RestQueueableHelper(this);
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('RestReceiver');
                queueableThread.logAndQueue(queueableClassInstance, 'ilib_RestQueueableHelper', 'execute');

                Id jobId = ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
                ilib_LogEvent.message('data will be persisted in job ' + jobId);
            }
            else
            {
                // save the records now
                checkForSuccess = finishTransaction();
            }
           
            if(!UtilsRest.SET_CLASS_NAME_FOR_LOCK_ROW.contains(logTitle) || checkForSuccess){
                UtilsRest.handleCustomRestSuccess();
            } 
        }
        UtilsRest.updateHttpResultCodeForRetry(logInterfaceId,logTitle);//DCP-56196
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /**
     * @author Illumina
     * @description  this method either runs at the end of retrieve() or is called from a queueable
                     it's primary purpose is to commit the UOW
                     after that it updates the logs and handles any known errors
     */
    public Boolean finishTransaction()
    {
        ilib_LogEvent.push(logTitle + '.finishTransaction()');
        Id primaryRecordId;
        String erpCustomerId;
        String strSaveError;

        try
        {
            objUnitOfWork.commitWork();
            ilib_LogEvent.message('data persisted successfully');

            // any additionl post-commit logic here
            doBusinessLogic();

            // get IDs of persisted records for log and error handling
            // only relevent if a single (parent) record was saved
            // we might handle bulk records in a future implementation
            primaryRecordId = findSingleRecordId();
            if (primaryRecordId != null)
                ilib_LogEvent.message('primaryRecordId = ' + primaryRecordId);

            erpCustomerId = getRelatedErpCustomerId(primaryRecordId);
            if (!String.isBlank(erpCustomerId))
                ilib_LogEvent.message('erpCustomerId = ' + erpCustomerId);
                
            if(testClassCoverage && Test.isRunningTest()) {
                throw new CustomException(CUSTOM_EXCEPTION);
            }
        }
        catch (Exception e)
        {
            strSaveError = UtilsRest.SET_CLASS_NAME_FOR_LOCK_ROW.contains(logTitle) ? UtilsRest.handleRetryCustomRestError(e) :UtilsRest.handleCustomRestError(e);
            printError(strSaveError);
        }

        Boolean isSuccess = String.isBlank(strSaveError);
        saveInterfaceLogRecord(isSuccess, strSaveError, primaryRecordId);
        
        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strSaveError);
        }

        ilib_LogEvent.pop();

        return isSuccess;
    }



    private void saveInterfaceLogRecord(Boolean isSuccess, String errorText, Id primaryRecordId)
    {
        //DCP-56196
        logInterfaceId = ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + errorText),
            primaryRecordId
        );
    }

    /**
     * @param recordId       id of current record
     * @return               ERP Id of the related customer
     **/
    public String getRelatedErpCustomerId(Id recordId)
    {
        // TODO: get these from interfaceDetails record
        String tableName;
        String pathToAccount;

        return getRelatedErpCustomerId(tableName, pathToAccount, recordId);
    }

    // TODO: get this from interfaceDetails record
    private Boolean useQueueable()
    {
        return true;
    }

    private void printError(String errorMessage)
    {
        ilib_LogEvent.push('EXCEPTION');
        ilib_LogEvent.message(errorMessage);
        ilib_LogEvent.pop();
    }

   /*
    @Description: To throw custom exception for covering catch block : DCP-56196
   */
   public class CustomException extends Exception {}
	
	
}
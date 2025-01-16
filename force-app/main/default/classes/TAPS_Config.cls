/**
*    @Author: Todd Newman
*    @Date:   
*    @Description: This class contains the configurations for Territory Apex Sharing parameters	
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Ashwin Kumar                   31-March-2022           DCP-52339 Add max deferred ids to process in a transaction
*    Todd Newman                                            Initial Version
*    Nesar Mohan                    2022-03-30              CodeScan Fix - Add code comments
*    Ashwin Kumar                   14-July-2022            INC0407615 - Bypass known/no impact errors for TAPS process
*    ------------------------------------------------------------------------------------                  
**/
public without sharing class TAPS_Config {

    public static final Integer LIMIT_MAX_SCHEDULED_JOBS = 100;

    private static final Integer MAX_FUTURE_DEFERRED_PROCESSING_JOBS = 5;
    private static final Integer MAX_IDS_IN_SINGLE_EVENT_DEFAULT = 1400;
    private static final Integer MAX_ACCOUNTS_IN_SINGLE_BATCH_DEFAULT = 75;
    private static final Integer MAX_IDS_IN_DEFERRAL_REQUEST_DEFAULT = 750;
    private static final Integer DEFAULT_MAX_SCHEDULED_JOBS = 100;
    private static final Integer DEFAULT_BUFFER_JOBS = 25;
    private static final Integer DEFAULT_BATCH_SIZE = 75;
    private static final Integer DEFAULT_JOB_DELAY = 2;
    private static final Integer MAX_DEFERRED_JOBS_PICKED_UP = 35;
    private static final Integer MAX_TERRITORY2_TO_ORCHESTRATOR = 15;   //INC0316527
    private static final Integer MAX_DEFERRED_IDS_TO_EXECUTE = 4800;    //DCP-52339
    private static final Integer MAX_ACCOUNT_TO_ORCHESTRATOR = 750;     //DCP-52339
    private static final Integer MAX_NEW_JOBS_IN_ONE_TRANSACTION = 50;
    private static final Boolean BYPASS_PLATFORM_EVENT_DEFAULT = false;
    private static final Boolean ALWAYS_DEFER_SHARING_DEFAULT = false;
    private static final Integer MAX_SYNCHRONOUS_RECORDS = 100;
    private static final String OBJECTS_SHARED_FUTURE_RAW = '';
    private static final String OBJECTS_SHARED_SYNCHRONOUSLY_RAW = '';
    private static final String OBJECTS_NEVER_DEFERRED_RAW = 'Opportunity,Apttus_Config2__TempObject__c,Apttus_Config2__ProductConfiguration__c';
    private static final String SKIP_ERRORS_INSERT_DEFERRED_REC = 'duplicate value found: Record_ID__c';    //DCP-52339
    private static final String SKIP_ERRORS_UPDATE_DEFERRED_REC = 'UNABLE_TO_LOCK_ROW';                     //DCP-52339
    private static final String SKIP_ERRORS_DELETE_DEFERRED_REC = 'entity is deleted,unable to obtain exclusive access';    //INC0407615
    private static final String SKIP_ERRORS_UPSERT_DEFERRED_REC = 'UNABLE_TO_LOCK_ROW,duplicate value found: Record_ID__c,unable to obtain exclusive access';   //INC0407615
    public static final String STRING_TRUE = 'true';

    private static Map<String, String> mtapsSettings;

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the TAPS record data from Custom Metadata Code_Parameter__mdt 
    *  @Param       : None
    *  @Return      : Map<String, String>
    */

    public static Map<String, String> getTapsSettings()
    {
        if (mtapsSettings == null)
        {
            mtapsSettings = UtilsSettings.getCustomMetadataMap('TAPS');
        }
        return mtapsSettings;
    }

    private static Map<String, Integer> mtapsBatchSizes;

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the TAPS_Object_Batch_Size record data from Custom Metadata Code_Parameter__mdt 
    *  @Param       : None
    *  @Return      : Map<String, Integer>
    */

    public static Map<String, Integer> getTapsBatchSizes()
    {
        if (mtapsBatchSizes == null)
        {
            mtapsBatchSizes = new Map<String, Integer>();

            Map<String, String> rawSizes = UtilsSettings.getCustomMetadataMap('TAPS_Object_Batch_Size');
            for (String key : rawSizes.keySet())
            {
                Integer val = UtilsSettings.parseIntegerFromSettingsMap(rawSizes, key, -1);
                if (val > 0)
                    mtapsBatchSizes.put(key, val);
            }
        }
        return mtapsBatchSizes;
    }

    // TODO: look at moving all the below Int methods to this map and clients just call getIntValue
    public final static String KEY_DEFERRED_QUERY_BUFFER = 'deferredQueryBuffer';
    public final static String KEY_MAX_PUBLISHED_RECORDS = 'maxPublishedRecordsProcessed';
    public final static String DISABLE_TAPS = 'DisableTAPS';

    private static Map<String, Object> keyToDefaultValue = new Map<String, Object>
    {
        KEY_DEFERRED_QUERY_BUFFER => 10,
        KEY_MAX_PUBLISHED_RECORDS => 2001,
        DISABLE_TAPS => false
    };

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the corresponding Integer value based on the passed parameter configKey 
    *  @Param       : String
    *  @Return      : Integer
    */

    public static Integer getIntValue(String configKey)
    {
        Integer defaultValue = 0;
        if (keyToDefaultValue.containsKey(configKey))
            defaultValue = (Integer)keyToDefaultValue.get(configKey);

        return getIntegerFromConfigSafe(configKey, defaultValue);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the Boolean value from TAPS record based on the passed configKey 
    *  @Param       : String
    *  @Return      : Boolean
    */

    public static Boolean getBooleanValue(String configKey)
    {
        Boolean defaultValue = false;
        if (keyToDefaultValue.containsKey(configKey))
            defaultValue = (Boolean)keyToDefaultValue.get(configKey);

        String raw = getTapsSettings().get(configKey);
        if (!String.isBlank(raw))
        {
            return raw.equalsIgnoreCase(STRING_TRUE);
        }
        return defaultValue;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the Boolean value from deferPartnerUserSharing field on TAPS record.
    *  @Param       : None
    *  @Return      : Boolean
    */

    public static Boolean deferPartnerUserSharing() {
        String raw = getTapsSettings().get('deferPartnerUserSharing');
        if (String.isBlank(raw))
        {
            return raw.equalsIgnoreCase(STRING_TRUE);
        }
        return false;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the maximum number of new jobs allowed in transaction
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getBufferedSimultaneousJobsMax() {
        Integer bufferedMax = getSimultaneousJobsMax() - getSimultaneousJobsBuffer();
        Integer singleTransactionThrottle = getNewJobsInTransactionMax();
        if (bufferedMax > singleTransactionThrottle)
            bufferedMax = singleTransactionThrottle;
        return bufferedMax;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to retrieve the maximum count of Jobs willing to schedule
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getBufferedSimultaneousDeferredJobsMax() {
        Integer bufferedMax = getSimultaneousJobsMax() - getSimultaneousJobsBuffer();
        Integer deferredJobThrottle = getDeferredJobsPickedUpMax();
        if (bufferedMax > deferredJobThrottle)
            bufferedMax = deferredJobThrottle;
        return bufferedMax;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to check whether to bypass the platform event or not based on the 'bypassPlatformEvent'
    *  field present on TAPS record
    *  @Param       : None
    *  @Return      : Boolean
    */

    public static Boolean bypassPlatformEvent() {
        String rawValue = getTapsSettings().get('bypassPlatformEvent');
        if (String.isBlank(rawValue)) return BYPASS_PLATFORM_EVENT_DEFAULT;
        if (rawValue.equalsIgnoreCase(STRING_TRUE)) return true;
        if (rawValue.equalsIgnoreCase('false')) return false;
        return BYPASS_PLATFORM_EVENT_DEFAULT;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return boolean value based on the field 'alwaysDeferSharingInTrigger' present
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Boolean
    */

    public static Boolean alwaysDeferSharingInTrigger() {
        String rawValue = getTapsSettings().get('alwaysDeferSharingInTrigger');
        if (String.isBlank(rawValue)) return ALWAYS_DEFER_SHARING_DEFAULT;
        if (rawValue.equalsIgnoreCase(STRING_TRUE)) return true;
        if (rawValue.equalsIgnoreCase('false')) return false;
        return ALWAYS_DEFER_SHARING_DEFAULT;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return Integer value present in the field 'maxSynchronousRecords' present
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getMaxSynchronousRecords()
    {
        return getIntegerFromConfigSafe('maxSynchronousRecords', MAX_SYNCHRONOUS_RECORDS);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Set of objects present in objectsThatShareInFuture field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Set<String>
    */

    public static Set<String> getObjectsThatShareInFuture()
    {
        String rawValue = getTapsSettings().get('objectsThatShareInFuture');
        if (String.isBlank(rawValue)) rawValue = OBJECTS_SHARED_FUTURE_RAW;
        List<String> lstValues = rawValue.split(',');
        return new Set<String>(lstValues);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Set of objects present in objectsThatShareSynchronously field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Set<String>
    */

    public static Set<String> getObjectsThatShareSynchronously()
    {
        String rawValue = getTapsSettings().get('objectsThatShareSynchronously');
        if (String.isBlank(rawValue)) rawValue = OBJECTS_SHARED_SYNCHRONOUSLY_RAW;
        List<String> lstValues = rawValue.split(',');
        return new Set<String>(lstValues);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Set of objects present in objectsThatNeverDefer field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Set<String>
    */

    public static Set<String> getObjectsThatNeverDefer()
    {
        String rawValue = getTapsSettings().get('objectsThatNeverDefer');
        if (String.isBlank(rawValue)) rawValue = OBJECTS_NEVER_DEFERRED_RAW;
        List<String> lstValues = rawValue.split(',');
        return new Set<String>(lstValues);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in futureDeferredProcessingJobsMax field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getFutureDeferredProcessingJobsMax() {
        return getIntegerFromConfigSafe('futureDeferredProcessingJobsMax', MAX_FUTURE_DEFERRED_PROCESSING_JOBS);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in newJobsInTransactionMax field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getNewJobsInTransactionMax() {
        return getIntegerFromConfigSafe('newJobsInTransactionMax', MAX_NEW_JOBS_IN_ONE_TRANSACTION);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in deferredJobsPickedUpMax field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getDeferredJobsPickedUpMax() {
        return getIntegerFromConfigSafe('deferredJobsPickedUpMax', MAX_DEFERRED_JOBS_PICKED_UP);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in simultaneousJobsMax field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getSimultaneousJobsMax() {
        return getIntegerFromConfigSafe('simultaneousJobsMax', DEFAULT_MAX_SCHEDULED_JOBS);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in simultaneousJobsBuffer field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getSimultaneousJobsBuffer() {
        return getIntegerFromConfigSafe('simultaneousJobsBuffer', DEFAULT_BUFFER_JOBS);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in nextJobDelayMinutes field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getNextJobDelayMinutes() {
        return getIntegerFromConfigSafe('nextJobDelayMinutes', DEFAULT_JOB_DELAY);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in maxAccountsInBatch field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getMaxAccountsInBatch() {
        return getIntegerFromConfigSafe('maxAccountsInBatch', MAX_ACCOUNTS_IN_SINGLE_BATCH_DEFAULT);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in maxIdsInDeferralRequest field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getMaxIdsInDeferralRequest() {
        return getIntegerFromConfigSafe('maxIdsInDeferralRequest', MAX_IDS_IN_DEFERRAL_REQUEST_DEFAULT);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - fetch max deferred records to be processed in a single job - DCP-52339
     *  @param - none
     *  @return - Integer
    **/
    public static Integer getMaxDeferredRecordsToExecute() {
        return getIntegerFromConfigSafe('maxDeferredRecordsToExecute', MAX_DEFERRED_IDS_TO_EXECUTE);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - fetch max Account deferred records to be processed in a single job - DCP-52339
     *  @param - none
     *  @return - Integer
    **/
    public static Integer getMaxAccountToOrchestrator() {
        return getIntegerFromConfigSafe('maxAccountToOrchestrator', MAX_ACCOUNT_TO_ORCHESTRATOR);
    }
    
    /**
     *  @author Ashwin Kumar
     *  @description - fetch errors to exclude when inserting Deferred records - DCP-52339
     *  @param - none
     *  @return - Set<String>
    **/
    public static Set<String> getErrorsToSkipForDeferredRecInsert() {
        String rawValue = getTapsSettings().get('skipErrorsForDeferredRecInsert');
        if (String.isBlank(rawValue)) { rawValue = SKIP_ERRORS_INSERT_DEFERRED_REC; }
        List<String> lstValues = rawValue.split(',');
        return new Set<String>(lstValues);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - fetch errors to exclude when updating Deferred records - DCP-52339
     *  @param - none
     *  @return - Set<String>
    **/
    public static Set<String> getErrorsToSkipForDeferredRecUpdate() {
        String rawValue = getTapsSettings().get('skipErrorsForDeferredRecUpdate');
        if (String.isBlank(rawValue)) { rawValue = SKIP_ERRORS_UPDATE_DEFERRED_REC; }
        List<String> lstValues = rawValue.split(',');
        return new Set<String>(lstValues);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - fetch errors to exclude when deleting Deferred records - DCP-52339
     *  @param - none
     *  @return - Set<String>
    **/
    public static Set<String> getErrorsToSkipForDeferredRecDelete() {
        String rawValue = getTapsSettings().get('skipErrorsForDeferredRecDelete');
        if (String.isBlank(rawValue)) { rawValue = SKIP_ERRORS_DELETE_DEFERRED_REC; }
        List<String> lstValues = rawValue.split(',');
        return new Set<String>(lstValues);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - fetch errors to exclude when upsert Deferred records - INC0407615
     *  @param - none
     *  @return - Set<String>
    **/
    public static Set<String> getErrorsToSkipForDeferredRecUpsert() {
        String rawValue = getTapsSettings().get('skipErrorsForDeferredRecUpsert');
        if (String.isBlank(rawValue)) { rawValue = SKIP_ERRORS_UPSERT_DEFERRED_REC; }
        List<String> lstValues = rawValue.split(',');
        return new Set<String>(lstValues);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in maxIdsInEvent field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */
    public static Integer getMaxIdsInEvent() {
        return getIntegerFromConfigSafe('maxIdsInEvent', MAX_IDS_IN_SINGLE_EVENT_DEFAULT);
    }
    

    //INC0316527
    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value present in maxTerritory2ToOrchestrator field
    *  on TAPS record
    *  @Param       : None
    *  @Return      : Integer
    */

    public static Integer getMaxTerritory2ToOrchestrator() {
        return getIntegerFromConfigSafe('maxTerritory2ToOrchestrator', MAX_TERRITORY2_TO_ORCHESTRATOR);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the Integer value (batch size) if passed SObjectType
    *  parameter is present as a key in TAPS Object Batch Size record, If not returns the batchSize
    *  from TAPS record.
    *  @Param       : SObjectType
    *  @Return      : Integer
    */

    public static Integer getBatchSize(SObjectType objectType) {
        Map<String, Integer> objectNameToSize = getTapsBatchSizes();
        String objectName = objectType.getDescribe().getName();

        if (objectNameToSize.containsKey(objectName))
            return objectNameToSize.get(objectName);
        else
            return getIntegerFromConfigSafe('batchSize', DEFAULT_BATCH_SIZE);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the corresponding Integer value for the passed configKey parameter matching
    *  the key in TAPS record else returns the second paramter defaultValue 
    *  @Param       : String, Integer
    *  @Return      : Integer
    */

    private static Integer getIntegerFromConfigSafe(String configKey, Integer defaultValue)
    {
        return UtilsSettings.parseIntegerFromSettingsMap(getTapsSettings(), configKey, defaultValue);
    }

}
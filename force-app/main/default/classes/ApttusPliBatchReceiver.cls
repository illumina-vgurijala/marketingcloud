@RestResource(urlMapping='/ProcessApttusPrices')
global with sharing class ApttusPliBatchReceiver {

//    //static variable for log
//    public static String INTERFACE_NAME = 'PLI Load Complete';
//
//    private static String jobId; // the ID of the bulk 2.0 job which has completed
//    private static String successCount; // the number of records which were inserted successfully
//    private static String errorCount; // the number of records which failed to insert
//
//    /**
//     * @author       Todd Newman
//     * @description  receive and process the request to process the new PLI Staging records, transforming them into Apttus PLI records
//     */
//    @HttpPut
//    global static void requestBatchProcess()
//    {
//        String strRestError = null;
//        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
//        System.debug(LoggingLevel.ERROR, 'JSON Input:\n' + strJsonInput);
//
//        Interface_Log__c log = InterfaceLog.instantiateLog(INTERFACE_NAME, strJsonInput);
//
//        try
//        {
//            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');
//
//            deserializeInputs(strJsonInput);
//
//            requestBatchProcessImpl();
//        }
//
//        catch (Exception e)
//        {
//            strRestError = UtilsRest.handleCustomRestError(e);
//        }
//
//        Boolean isSuccess = String.isBlank(strRestError);
//        if (isSuccess)
//        {
//            UtilsRest.handleCustomRestSuccess();
//        }
//
//        InterfaceLog.finalizeLog(
//                log,
//                (isSuccess ? InterfaceLog.RESULT_SUCCESS : InterfaceLog.RESULT_FAIL),
//                (isSuccess ? null : 'Exception: ' + strRestError)
//        );
//
//        emitEvent(isSuccess);
//    }
//
//    /**
//     * @author       Todd Newman
//     * @description  parse and store the request inputs
//     */
//    private static void deserializeInputs(String jsonInput)
//    {
//        Map<String, String> inputs = (Map<String, String>)JSON.deserialize(jsonInput, Map<String, String>.class);
//        System.debug('inputs: ' + inputs);
//
//        jobId = inputs.get('jobId');
//        successCount = inputs.get('successCount');
//        errorCount = inputs.get('errorCount');
//    }
//
//    /**
//     * @author       Todd Newman
//     * @description  kick off the batch job, BatchStagedPLItems
//     */
//    private static void requestBatchProcessImpl()
//    {
//        Map<String, String> settings = UtilsSettings.getCustomMetadataMap('Apttus_PLI_Staging');
//
//        Integer defaultBatchSize = 200;
//        Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(settings, 'batchSize', defaultBatchSize);
//        if (batchSize < 1 || batchSize > 200) batchSize = defaultBatchSize;
//
//        Id jobId = Database.executeBatch(new BatchStagedPLItems(), batchSize);
//        System.debug('jobId: ' + jobId);
//    }
//
//    /**
//     * @author       Todd Newman
//     * @description  log results to a platform event
//     */
//    private static void emitEvent(Boolean isSuccess)
//    {
//        ilib_LogEvent.quickEmit('PLI Staging Batch Request', new Map<String, String> {
//                'jobId' => jobId,
//                'processedCount' => successCount,
//                'errorCount' => errorCount,
//                'triggeredJob' => String.valueOf(isSuccess)
//        });
//    }

}
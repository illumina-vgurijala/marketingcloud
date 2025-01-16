/***************************************************************************************************************************************
 * NAME   : ScheduledObjectTruncate
 * DESCRIPTION  : ScheduledObjectTruncate class is used to delete log records.
 *    
 * @AUTHOR : Todd Newman
 * @DATE   : 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Nishan Shetty           16-Mar-22            DCP-52338 Changed the Logic from Queueable to Batch Execution because queueable job was failing when deleting 
 *                                              queueable logs due of too many DML rows error which was caused due to parent-child relationship [Queueable Logs-Queueable Logs Item].
 * Nesar Mohan             31-Mar-22            CodeScan Fix
 * Nishan Shetty           25-May-22            INC0398604 Changes moved batch size to object truncation metadata.
 *--------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/ 
global with sharing class ScheduledObjectTruncate extends ilib_ScheduleAndBatch {
    Object_Truncation__mdt testParameter;
    /*
    * @author      : Todd Newman
    * @description : Wrapper Class
    */
    public class TruncationParameters {
        public String strObjectName;
        public Integer intMaxRecordAge;
        public String strSoqlCriteria;
        public Integer intBatchSize;
        
        /*
         * @author- Todd Newman
         * @description- Constructor to intialize the variables of TruncationParameters object based on
         * the parameters passed
         * @param: 2 Strings and 1 Integer
        */

        public TruncationParameters(String strObjectName, Integer intMaxRecordAge, String strSoqlCriteria,Integer intBatchSize) {
            this.strObjectName = strObjectName;
            this.intMaxRecordAge = intMaxRecordAge;
            this.strSoqlCriteria = strSoqlCriteria;
            this.intBatchSize = intBatchSize;
        }
    }

    

   /*
    * @author       : Todd Newman
    * @description  : No parameter Constructor
    */
    global ScheduledObjectTruncate() { }

    /*
    * @author       : Todd Newman
    * @description  : Parameterized Constructor to initialize the variable testParameter of type Object_Truncation__mdt
    * @param        : Object_Truncation__mdt
    */

    global ScheduledObjectTruncate(Object_Truncation__mdt testParameter) {
        super();
        this.testParameter = testParameter;
    }
    
    /*
     * @author      : Todd Newman
     * @description : Method to execute Schedulable.
     * @param       : SchedulableContext
     * @return      : void
     */
    global override void execute(SchedulableContext sc) {
        List<TruncationParameters> lstTruncations = getConfiguration(testParameter);

        // queue up a delete job for each configured truncation
        for (TruncationParameters t : lstTruncations) {
            createBatchJob(t.strObjectName, t.intMaxRecordAge, t.strSoqlCriteria, t.intBatchSize);
        }
    }
    
    /*
    * @author - Nishan Shetty DCP-52338
    * @description - Method to create Queueable job.
    * @param - 2 Strings and 1 Integer
    * @return - void
    */
    public static void createBatchJob(String strObjectName, Integer intMaxRecordAge, String strSoqlCriteria, Integer intBatchSize) {
        if(!Test.isRunningTest()) {
            ilib_BatchManager.executeBatch(new ScheduledObjectTruncateBatch(strObjectName,intMaxRecordAge,strSoqlCriteria,intBatchSize));
        }
        
    }
     /*
    *  @author      : Todd Newman
    *  @description : Method to return List of TruncationParameters record based on Object_Truncation__mdt if not in test context,
    *  If it is in test context, returns the List of TruncationParameters record based on the Object_Truncation__mdt parameter values
    *  @param       : Object_Truncation__mdt
    *  @return      : List<TruncationParameters>
    */
    @TestVisible private List<TruncationParameters> getConfiguration(Object_Truncation__mdt parameter) {
        List<Object_Truncation__mdt> configs = new List<Object_Truncation__mdt>();

        if (Test.isRunningTest()) {
            configs.add(parameter);
        } else {
            configs = queryMetadata();
        }

        List<TruncationParameters> lstTruncations = new List<TruncationParameters>();
        for (Object_Truncation__mdt config : configs) {
            lstTruncations.add(new TruncationParameters(config.Object_Name__c, Integer.valueOf(config.Max_Record_Age__c), config.SOQL_Criteria__c,Integer.valueOf(config.Batch_Size__c)));
        }
          
        return lstTruncations;
    }
    /*
    *  @Author      : Todd Newman
    *  @Description : Test Method to return List of records from Object_Truncation__mdt custom metadata
    *  @Param       : None
    *  @Return      : List<Object_Truncation__mdt>
    */
    @TestVisible private List<Object_Truncation__mdt> queryMetadata() {
        return [SELECT Object_Name__c, Batch_Size__c, Max_Record_Age__c, SOQL_Criteria__c
                FROM Object_Truncation__mdt
                WHERE IsActive__c = true];
    }

}
/****************************************************************************************************************************************
* NAME         : ScheduledObjectTruncateBatch
* DESCRIPTION  : Batch Class to delete Logs.
* Test class for 90% coverage: TestScheduledObjectTruncate (As of Sep 12, 22 - 100%)
* Test class for 75% coverage: TestScheduledObjectTruncate (As of Sep 12, 22 - 100%)                 
* @AUTHOR : Nishan Shetty
* @DATE   : 15-Mar-2022
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Nishan Shetty           15-Mar-2020         Initial Version.
                                              Batch Class to delete different types of Logs record from the Org based on the record age specified in Object Truncation 
                                              Metadata.
* Nishan Shetty           25-May-22           INC0398604 Changes moved batch size to object truncation metadata.
* Atit Kar                12-Sep-22           INC0419648 - Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
****************************************************************************************************************************************/ 
public with sharing class ScheduledObjectTruncateBatch extends ilib_BatchDeferrable {
    public final static String LOG_TITLE = 'ScheduledObjectTruncateBatch';
    private Inputs inputs;

    /* Parameter wrapper for easy serialization */
    public class Inputs {
        public String strObjectName;
        public Integer intMaxRecordAge;
        public String strSoqlCriteria;
        public Integer intBatchSize;
        /*Constructor*/
        public Inputs(String strObjectName,Integer intMaxRecordAge, String strSoqlCriteria, Integer intBatchSize) {
            this.strObjectName=strObjectName;
            this.intMaxRecordAge=intMaxRecordAge;
            this.strSoqlCriteria=strSoqlCriteria;
            this.intBatchSize=intBatchSize;
        }
    }

    /*
    * @Author : Atit Kar[INC0419648]
    * @Description : Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
    */
    public ScheduledObjectTruncateBatch() {
        super();
    }
    
    /*
     @description: Constructor
    */
    public ScheduledObjectTruncateBatch(String strObjectName, Integer intMaxRecordAge, String strSoqlCriteria, Integer intBatchSize) {
        super();
        ilib_LogEvent.push('ScheduledObjectTruncateBatch.Constructor');
        this.inputs = new Inputs(strObjectName, intMaxRecordAge, strSoqlCriteria, intBatchSize);
        ilib_LogEvent.message('Input Parameters'+this.inputs);        
        ilib_LogEvent.pop();
    }

    /*
     @description: Start Method
    */
    public override Database.QueryLocator start(Database.BatchableContext bc) {   
        ilib_LogEvent.push('ScheduledObjectTruncateBatch.Start');
        Datetime datetimeCutOff = Datetime.now() - inputs.intMaxRecordAge;
        ilib_LogEvent.message('Cut-Off Date'+datetimeCutOff);
        String soql='SELECT Id'
        + ' FROM ' + inputs.strObjectName
        + ' WHERE CreatedDate < :datetimeCutOff';

        if (!String.isBlank(inputs.strSoqlCriteria)) {
            soql = soql + ' AND ' + inputs.strSoqlCriteria;
        }

        ilib_LogEvent.message('Query String '+ soql);
        ilib_LogEvent.pop();
        return Database.getQueryLocator(soql);
    }
    
    /*
     @description: Execute Method
    */
    public override void execute(Database.BatchableContext bc, List<SObject> records) {
        ilib_LogEvent.push('ScheduledObjectTruncateBatch.Execute');
        ilib_LogEvent.message('Object Name'+inputs.strObjectName);
        ilib_LogEvent.message('Record Size'+records.size());
        List<Database.DeleteResult> lstDeletedResults = Database.delete(records,false);
        ApexExceptions.emitDeleteErrors(lstDeletedResults,inputs.strObjectName);
        ilib_LogEvent.pop();
    }

    /*
     @description: Finish Method
    */
    public override void finish(Database.BatchableContext bc) {}



    // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************

    /* simple input serialization */
    public override String serializeInputs() {
        return JSON.serialize(inputs);
    }

    /* simple input deserialization */
    public override void restoreInputs(String serializedInputs) {
        this.inputs = (ScheduledObjectTruncateBatch.Inputs)JSON.deserialize(serializedInputs, ScheduledObjectTruncateBatch.Inputs.class);
    }

    /* default value */
    public override Integer getDefaultBatchSize() {
        return inputs.intBatchSize;
    }
}

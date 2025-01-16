/****************************************************************************************************************************************
* NAME         : BatchUpdateIsUpdatedBySystemFlag
* DESCRIPTION  : Batch Class to Update IsUpdatedBySystem Flag to False.
* @Test Class for above 90% coverage
*  -TestBatchUpdateIsUpdatedBySystemFlag
* @Test Class for atleast 75% coverage
*  -TestBatchUpdateIsUpdatedBySystemFlag                 
* @AUTHOR : Nishan Shetty
* @DATE   : 02-Sept-2022
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Nishan Shetty           06-Sept-2022         Initial Version [DCP-53823].
****************************************************************************************************************************************/ 
public without sharing class BatchUpdateIsUpdatedBySystemFlag extends ilib_BatchDeferrable {
    public final static String LOG_TITLE = 'BatchUpdateIsUpdatedBySystemFlag';
    public final static String STRING_BATCH_SIZE_PARAMETER ='BatchUpdateIsUpdatedBySystemFlagSize';
    public final static String STRING_OPPORTUNITY ='Opportunity';
    private Inputs inputs;
    
    /* Parameter wrapper for easy serialization */
    public class Inputs {
        public String strObjectName;
        public Integer intBatchSize;
        /*Constructor*/
        public Inputs(String strObjectName,Integer intBatchSize) {
            this.strObjectName=strObjectName;
            this.intBatchSize=intBatchSize;
        }
    }
    
    /*
    No Arg Constructor
    */
    public BatchUpdateIsUpdatedBySystemFlag() {
        super();
    }

    /*
     @description: Parameterized Constructor
    */
    public BatchUpdateIsUpdatedBySystemFlag(String strObjectName,Integer intBatchSize) {
        super();
        ilib_LogEvent.push(LOG_TITLE+'.Constructor');
        this.inputs = new Inputs(strObjectName,intBatchSize);
        ilib_LogEvent.message('Input Parameters'+this.inputs);        
        ilib_LogEvent.pop();
    }

    
    /*
     @description: Start Method
    */
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        ilib_LogEvent.push(LOG_TITLE+'Start');
        String query = 'Select Id,Is_Updated_By_System__c from '+inputs.strObjectName+' where Is_Updated_By_System__c=true';
        ilib_LogEvent.message('Query String '+ query);
        ilib_LogEvent.pop();
        return Database.getQueryLocator(query);
    }


    /*
     @description: Execute Method
    */
    public override void execute(Database.BatchableContext bc, List<SObject> records) {
        ilib_LogEvent.setBatchTitle(LOG_TITLE,transactionId);
        ilib_LogEvent.push(LOG_TITLE+'.execute');

        for(Opportunity objOpp:(List<Opportunity>)records) {
            objOpp.Is_Updated_By_System__c=false;
        }
        ilib_LogEvent.info('Updated Records'+records);
        
        List<Database.SaveResult> lstSaveErrors = Database.update(records,false);
        ApexExceptions.emitSaveErrors(lstSaveErrors,LOG_TITLE);
        ilib_LogEvent.pop();
    }

    /*
     @description: Finish Method
    */
    public override void finish(Database.BatchableContext bc) {}

    // ************************************************************************************************
    // Deferrable implementation
    // **********************************************************************************************
    
  /*
   *  @Author      : Nishan Shetty
   *  @Description : Method to simple input serialization
   *  @Param       : None
   *  @Return      : String
   */
   public override String serializeInputs() {
    return JSON.serialize(inputs);
   }

   /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs) {
        this.inputs = (BatchUpdateIsUpdatedBySystemFlag.Inputs)JSON.deserialize(serializedInputs,BatchUpdateIsUpdatedBySystemFlag.Inputs.class);
    } 


    /* default value */
    public override Integer getDefaultBatchSize() {
        return inputs.intBatchSize;
    }
}

/*@ author       : Todd Newman
* @ date         : 
* @ Description  : Base class for batchables that can be deferred to run later.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Saddam                02-02-2021                 Extended this classes to ilib_ScheduleAndBatch US-(PM-41)
* Nitin                 18-05-2021                 CMSI-19: Transaction id 
* Nishan Shetty          13-June-2022          Extended ilib_ScheduleAndBatch class as part of DCP-50962 user story.
*/
global virtual with sharing class ilib_BatchDeferrable extends ilib_ScheduleAndBatch implements Database.Batchable<sObject>, Database.stateful {

    public static final Integer DEFAULT_BATCH_SIZE = 200;
    //CMSI-19
    //public string transactionId;
    protected string transactionId;
    // batchable methods - if overridded no exception will be thrown
    /* batchable start */
    global virtual override  Database.QueryLocator start(Database.BatchableContext bc) { throw new UnsupportedOperationException(); }
    /* batchable execute */
    global virtual override void execute(Database.BatchableContext bc, List<sObject> scope) { throw new UnsupportedOperationException(); }
    /* batchable finish */
    global virtual override void finish(Database.BatchableContext bc) { throw new UnsupportedOperationException(); }

    /* methods required to support deferrable */
    public virtual String serializeInputs()
    {
        throw new UnsupportedOperationException();
    }

    /* methods required to support deferrable */
    public virtual void restoreInputs(String serializedInputs)
    {
        throw new UnsupportedOperationException();
    }

    /* override if different value is required */
    public virtual Integer getDefaultBatchSize()
    {
        return DEFAULT_BATCH_SIZE;
    }

    /*
    name of class needed for reinstantiation
    this will return name of descendent class
    */
    public virtual String getName()
    {
        return String.valueOf(this).split(':')[0];
    }
    /*
    @Author : Nitin
    @Story : CMSI-19
    @Description : Setting the transaction Id
    */
    public void setTransactionId(String tid){
        transactionId=tid;
    }

    /*
    @Author : Nitin
    @Story : CMSI-19
    @Description : getting the transaction Id
    */
    public string getTransactionId(){
        return transactionId;
    }

}
/*
*    @author: Rajbabu Boopalan 
*    @description: Service Class used to trigger batch create
*    Modification Log:
*   -----------------------------------------------------------------------------------------
*    Developer                      Date                    Description
*    Rajbabu Boopalan               2024-Feb-05              Initial Version
*    Gerardo Garcia                 2024-Aug-08              Add updateAsyncRecords method
*    ----------------------------------------------------------------------------------------
*/
public inherited sharing class BatchDMLService {
    public static final integer MAX_BATCH_SIZE = 10000;
    // New sObject records to be created or updated
    private List<SObject> lstSObj;
    private dmlOperation batchDMLAction;
    private Integer batchSize;
    /*
    *   @description:
    *   Enum containing supported DML Operation handled by BatchDMLOperation class 
    *   Any new kind of DML action which is to be developed in future needs to be added here
    */
    public enum dmlOperation { DML_INSERT, DML_UPDATE, DML_UPSERT }

    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : Parameterized constructor to initialize the variables
    *  @Param       : List<SObject>
    */
    public BatchDMLService(List<SObject> lstSObj, dmlOperation dmlAction, Integer batchSize) {
        if(!lstSObj.isEmpty()){
            this.lstSObj = lstSObj;
        }
        this.batchDMLAction = dmlAction;
        this.batchSize = batchSize;
    }
    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : Method to validate batch size and trigger the DML batch
    *  @Param       : none
    *  @return      : void
    */
    public void runBatchDML() {
        if(!lstSObj.isEmpty()) {
            string objTypeName = lstSObj[0].getSObjectType().getDescribe().getName();
            BatchDMLOperation batchDML = new BatchDMLOperation(lstSObj, batchDMLAction);
            if(this.batchSize > 0 && this.batchSize <= MAX_BATCH_SIZE){
                ilib_LogEvent.message('starting batch BatchDMLOperation for ' + lstSObj.size() + ' ' + objTypeName + ' records with batch size ' + batchSize);
                Database.executeBatch(batchDML, batchSize);
            } else {
                ilib_LogEvent.message('starting batch BatchDMLOperation for ' + lstSObj.size() + ' ' + objTypeName + ' records with batch size 200');
                Database.executeBatch(batchDML, 200);
            }
        }
    }

    /**
     * @description: Update giving records by calling a BatchDMLOperation.
     * @param: List<SObject> objects to update.
     */
    public static void updateAsyncRecords(List<SObject> records) {
        if(!records.isEmpty()) {
            Integer batchSize = 2000;
            BatchDMLService batchDMLService = new BatchDMLService(records, dmlOperation.DML_UPDATE, batchSize);
            batchDMLService.runBatchDML();
        }
    } 
}
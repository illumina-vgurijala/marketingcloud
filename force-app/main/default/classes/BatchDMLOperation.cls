/*
*    @author: Rajbabu Boopalan 
*    @description: Batch class to perform DML Operation
*    Modification Log:
*   ----------------------------------------------------------------------------------------
*    Developer                      Date                    Description
*    Rajbabu Boopalan               2024-Feb-28              Initial Version
*    ---------------------------------------------------------------------------------------                  
*/
public without sharing class BatchDMLOperation implements Database.Batchable<SObject> {
    // New records to be created or updated
    private List<SObject> lstSObj;
    private BatchDMLService.dmlOperation dmlAction;
    
    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : Parameterized constructor to initialize the variables
    *  @Param       : List<SObject>, enum BatchDMLService.dmlOperation
    */
    public BatchDMLOperation(List<SObject> lstSObj, BatchDMLService.dmlOperation dmlOperation) {
        this.lstSObj = lstSObj;
        this.dmlAction = dmlOperation;
    }
    
    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : start method to return the sObject records
    *  @Param       : Database.BatchableContext
    *  @Return      : Iterable<SObject> 
    */
    public Iterable<SObject> start(Database.BatchableContext bc) {
        return new List<SObject>(lstSObj);
    }
    
    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : execute method for the business logic
    *  @Param       : Database.BatchableContext, List<Id>
    *  @Return      : Void
    */
    public void execute(Database.BatchableContext bc, List<SObject> newShareRecords)
    {
        string objTypeName = newShareRecords[0].getSObjectType().getDescribe().getName();
        ilib_LogEvent.rootTitle = 'BatchDMLOperation Batch Run (' +objTypeName + ')';
        ilib_LogEvent.push('BatchDMLOperation.execute');
        List<Database.SaveResult> insertUpdateResults = new List<Database.SaveResult>();
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();
        try {
            ilib_LogEvent.message('in batch; newShareRecords ' + newShareRecords);

            if(dmlAction == BatchDMLService.dmlOperation.DML_INSERT) {
                insertUpdateResults = Database.insert(newShareRecords, false);
            }
            else if(dmlAction == BatchDMLService.dmlOperation.DML_UPDATE) {
                insertUpdateResults = Database.update(newShareRecords, false);
            }
            else if(dmlAction == BatchDMLService.dmlOperation.DML_UPSERT) {
                upsertResults = Database.upsert(newShareRecords, false);
            }

            if(!insertUpdateResults.isEmpty()){
                ApexExceptions.emitSaveErrors(insertUpdateResults,'BatchDMLOperation');
            }
            else if(!upsertResults.isEmpty()){
                ApexExceptions.emitUpsertErrors(upsertResults,'BatchDMLOperation');
            }
            ilib_LogEvent.message('BatchDMLOperation batch run complete');
        }
        catch (Exception e) {
            ApexExceptions.emit('BatchDMLOperation ', e);
            ilib_LogEvent.push('EXCEPTION');
            ilib_LogEvent.message(e.getMessage().abbreviate(4000));
            ilib_LogEvent.pop();
        } finally {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
    }
    
    /*
    *  @Author      : Rajbabu Boopalan
    *  @Description : Finish method for post execution logic
    *  @Param       : Database.BatchableContext
    *  @Return      : Void
    */
    public void finish(Database.BatchableContext bc)
    {
        ilib_LogEvent.setTitle('BatchDMLOperation Finished');
        ilib_LogEvent.push('BatchDMLOperation.finish');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}
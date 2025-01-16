/**
 * @author KD 
 * @description  Batch class to share plan
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description   
*   Nishan Shetty          03-Jun-2022        Implementation of Batch Manager Framework[DCP-50962].
*  -----------------------------------------------------------------------------------          
*/
global with sharing class BatchQuarterlyPlanShare extends ilib_BatchDeferrable {

    public final static String SOURCE = 'BatchQuarterlyPlanShare';//DCP-50962
    /**
    *   @author KD
    *   @description Start Method For the Apex JOb
    **/
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        String strQuery = 'SELECT Id,Territory_Code__c,RecordTypeId,Channel_Partner_Territory_Code__c,OwnerId from Plan__c';
        return Database.getQueryLocator(strQuery);
    }
    /**
    *   @author KD
    *   @description : Sharing of plan
    **/
    global override void execute(Database.BatchableContext bc, list<Sobject> scope) {
        ilib_LogEvent.setBatchTitle(SOURCE, transactionId);
        ilib_LogEvent.push(SOURCE+'.execute');
        Set<Id> objRecordIds = new Set<Id>();
        for(Plan__c objPlan : (List<Plan__c>)scope) {
            objRecordIds.add(objPlan.Id);
        }
        List<Plan__share> lstPlanShare =new PlanShareSelector().getShareRecordsWithParentId(objRecordIds,Schema.Plan__Share.RowCause.Manual);
        PlanShareService.deleteExistingSharing(lstPlanShare);
        PlanShareService.sharePlanRecords((List<Plan__c>)scope);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *   @author KD
    *   @description  Finish method
    **/
    global override void finish(Database.BatchableContext bc) {

    }


    // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************
    
    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String  no inputs, serialize dummy values 
    */
    public override String serializeInputs()
    {
        return JSON.serialize('No input for this class');
    }

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : no inputs
    */
    public override void restoreInputs(String serializedInputs) { }
    
}
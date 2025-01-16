/**
*    @author: Monika Parihar
*    @date:   29-Sept-2020
*    @description:  Batch class to update IsAutoConvertInProgress &IsAutoMergeInProgress field  //DCP-41191
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Monika                        29-Sept-2020        Batch class to update IsAutoConvertInProgress &IsAutoMergeInProgress field //DCP-41191
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class BatchUpdateAutoConvertMergeCheckbox extends ilib_ScheduleAndBatch implements Database.Batchable<sObject> {
    /**
     *  @author  Monika Parihar
     *  @description execute method to be called when class is scheduled
     *  @paramter- schedule context
     **/
    public override void execute(SchedulableContext ctx){
      BatchUpdateAutoConvertMergeCheckbox objBatch=new BatchUpdateAutoConvertMergeCheckbox();
      Database.executebatch(objBatch);
    }

    /**
     *  @author  Monika Parihar
     *  @description start method for the batch job
     *  @paramter- schedule context
     **/
    public override Database.QueryLocator start(Database.BatchableContext bc){
        /*Fetch the list of all Lead records for update*/
        return Database.getQueryLocator('SELECT Id,Is_AutoMerge_In_Progress__c,Is_AutoConversion_In_Progress__c FROM Lead where (IsConverted = false and Is_AutoConversion_In_Progress__c=true) or (Is_AutoMerge_In_Progress__c=true) order by createddate desc');
    }
    
    /**
     *  @author  Monika Parihar
     *  @description execute  method for the batch job
     *  @paramter- schedule context, list of 
     **/
    public override void execute(Database.BatchableContext bc, List<sObject> lstLead){
        for (Lead objLead: (List<Lead>)lstLead){
            objLead.Is_AutoConversion_In_Progress__c=false;
            objLead.Is_AutoMerge_In_Progress__c=false;
        }
        Database.update(lstLead, false);
    }
	/**
     *  @author  Monika Parihar
     *  @description finish  method for the batch job
     *  @paramter- schedule context
     **/
    public override void finish(Database.BatchableContext bc){
        System.Debug(BC);
    }

}
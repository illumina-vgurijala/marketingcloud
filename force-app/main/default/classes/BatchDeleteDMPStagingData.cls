/**
*    @author: Pankaj Singla
*    @date:   13-Feb-2020
*    @description:  Batch class to delete DMP Staging Data which is processed and crossed threshold date
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla              13 Feb 2020           Initial Build
              
               BatchDeleteDMPStagingData objBatch=new BatchDeleteDMPStagingData();
               String sch='0 0 1 * * ? *';               
               System.schedule('DMP: Delete Staging Data', sch , objBatch);
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class BatchDeleteDMPStagingData extends ilib_ScheduleAndBatch{
    /*Integer which number of days old data to be retained. Delete all records which are processed before 
    the number of days specified*/
    public Integer intNumberDaysForDeletion = -(Integer.ValueOf(Label.DMP_Staging_Rentention_Days));
    public Datetime dtCutoffTime = Datetime.now().addDays(intNumberDaysForDeletion);
    
    /*Start method of Batch Class*/
    public override Database.QueryLocator start(Database.BatchableContext bc){
        /*Fetch all the processed DMP Staging records*/
        return Database.getQueryLocator('select id,Hem__c,segments__c,Record_Processed__c,Record_Processed_Date__c from DMP_Staging__c'+ 
                                        ' where Record_Processed__c=true and Record_Processed_Date__c!= null '+
                                          'and Record_Processed_Date__c<:dtCutoffTime');
        
    }
    
    /*Execute method for Schedulable Context*/
    public override void execute(SchedulableContext sc){
          Database.executeBatch(new BatchDeleteDMPStagingData());
    }
    
    /*Execute method of Batch Class*/
    public override void execute (Database.BatchableContext bc, List<SObject> scope){
        List<DMP_Staging__c> lstDMPStagingDelete=new List<DMP_Staging__c>();
         for (DMP_Staging__c objDMPStaging : (List<DMP_Staging__c>)scope){
             lstDMPStagingDelete.add(objDMPStaging);
         }
         
         if(lstDMPStagingDelete.size()>0){
             Database.Delete(lstDMPStagingDelete,false);
         }
    }
    
    /*Finish method of Batch Class*/
    public override void finish(Database.BatchableContext bc) { System.debug('Batch Class Logic Finished'); }

}
/**
*    @author: Rishab Wali 
*    @date:   26-Sept-2022
*    @description:  Waterfall Enagaged Date clear if not updated in more than 365 days
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Rishab Wali                   26 Sep 2022         [DCP-57145] Clear Waterfall Enagaged Date
*    -----------------------------------------------------------------------------------------------------
*                    
*/
public with sharing class BatchClearWaterfallStageLeads extends ilib_BatchDeferrable {

    /* Batch Start Method to query records */
    public override Database.QueryLocator start(Database.BatchableContext bc) {        
        Datetime dtYearAgo = System.now() - 365 ;   
        ilib_LogEvent.message('Date 1 Year ago - ' + dtYearAgo);
        String query = 'SELECT Id,Waterfall_Stage__c FROM Lead WHERE Waterfall_Stage__c = \'Engaged\' AND (Status = \'New\' OR Status = \'Recycled\') AND Waterfall_Engaged_Date__c <: dtYearAgo AND Last_Responded_Campaign_Date__c <: dtYearAgo';
        return Database.getQueryLocator(query);
    }
    
    /* Batch Execute Method to process records */
    public override void execute(Database.BatchableContext bc, List<sobject> lstLeads) {  
        ilib_LogEvent.push('BatchClearWaterfallStageLeads.execute()');
        for(Lead ld : (List<Lead>)lstLeads)
        {
            ld.Waterfall_Stage__c = '';
        }
        ilib_LogEvent.info('List size ' + lstLeads.size());
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        cs.Bypass_All_Validations__c = true;
        cs.Bypass_All_Triggers__c = true;
        cs.Bypass_All_Flows__c = true;
        upsert cs cs_Apex_Settings__c.Id;
        Database.update(lstLeads,false);
        cs.Bypass_All_Validations__c = false;
        cs.Bypass_All_Triggers__c = false;
        cs.Bypass_All_Flows__c = false;
        upsert cs cs_Apex_Settings__c.Id;
        ilib_LogEvent.pop();        
    }
    
    /* Schedulable Execute Method to schedule Batch */    
    public override void execute(SchedulableContext sc) {
         ilib_BatchManager.executeBatch(new BatchClearWaterfallStageLeads());
    }
    /* Batch Finish Method for post execute logic */    
    public override void finish(Database.BatchableContext bc) {
       //No Logic needed.
    }
    
}
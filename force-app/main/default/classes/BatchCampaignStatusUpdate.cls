/**
*    @author: Pankaj 
*    @date:   15-May-2019
*    @description:  Batch Class to update Campaign Status based on Start and End date
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        15-May-2019        Initial Development
*            Deep Diwakar                   Aug-12-2024        CMCM-9647: Updated to remove process builder dependency, added instrumentation

        BatchCampaignStatusUpdate objBatch=new BatchCampaignStatusUpdate();
        String sch='0 0 1 * * ? *';
        System.schedule('BatchCampaignStatusUpdate', sch , objBatch);
*    ------------------------------------------------------------------------------------ 
*                    
*/
global class BatchCampaignStatusUpdate extends ilib_ScheduleAndBatch {
    global static final String STRING_CAMPAIGN_STATUS_COMPLETED = 'Completed';
    global static final String STRING_CAMPAIGN_STATUS_IN_PROGRESS = 'In Progress';
    global static final Integer INT_CAMPAIGN_END_DAYS = -30;

    private static final String LOG_TITLE = 'BatchCampaignStatusUpdate';

    @TestVisible
    private Boolean testExceptionBlock = false;

    private static final string TEST_CUSTOM_EXCEPTION = 'Test exception to test catch block';

    /*Start method of Batch Class*/
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.start()');

        String strSOQL;
        if(!Test.isRunningTest()) {
            strSOQL='SELECT id,EndDate,IsActive,StartDate,Status FROM Campaign where (StartDate<=today or  EndDate<LAST_N_DAYS:30)';
            strSOQL=String.escapeSingleQuotes(strSOQL);
                       
        } else {
            String strEsc = String.escapeSingleQuotes('TestCampaignBatch%');            
            strSOQL='SELECT id,EndDate,IsActive,StartDate,Status FROM Campaign where name like \''+strEsc +'\'and  (StartDate<=today or  EndDate<LAST_N_DAYS:30)';
        }

        ilib_LogEvent.info('strSOQL: ' + strSOQL);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return Database.getQueryLocator(strSOQL);
    }

    /*Execute method for Schedulable Context*/
    global override void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchCampaignStatusUpdate());
    }
    
    /*Execute method of Batch Class*/
    global override void execute (Database.BatchableContext bc, List<SObject> scope) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        try {

            ilib_LogEvent.info('testExceptionBlock: ' + testExceptionBlock);
            // Added for testing catch block
            if (testExceptionBlock && Test.isRunningTest()) {
                ilib_LogEvent.info('test context - throwing exception');
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }

            Date dtToday=Date.today();
            Date dtPreviousDate = dtToday.addDays(INT_CAMPAIGN_END_DAYS);
            List<Campaign> lstCampaign=new List<Campaign>();
            
            for (Campaign objCampaign : (List<Campaign>)scope) {
                if (objCampaign.EndDate<dtPreviousDate) {
                    Campaign objCampaignUpd=new Campaign(id=objCampaign.id);
                    objCampaignUpd.IsActive=false;
                    objCampaignUpd.Status=STRING_CAMPAIGN_STATUS_COMPLETED;
                    lstCampaign.add(objCampaignUpd);
                } else if (objCampaign.StartDate<=dtToday && objCampaign.EndDate>dtToday) {
                    Campaign objCampaignUpd=new Campaign(id=objCampaign.id);
                    objCampaignUpd.Status=STRING_CAMPAIGN_STATUS_IN_PROGRESS;
                    lstCampaign.add(objCampaignUpd);
                }
            }

            ilib_LogEvent.info('lstCampaign size: ' + lstCampaign.size());

            // list is empty
            if (!lstCampaign.isEmpty()) {
                // bypassing validaiton as this is a backend batch update, not user context. Restoring it back after update
                cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();
                objApexSettings.Bypass_All_Validations__c=true;
                upsert objApexSettings cs_Apex_Settings__c.Id;
                List<Database.SaveResult> results = Database.update(lstCampaign, false);
                ApexExceptions.emitSaveErrors(results, LOG_TITLE + '.execute');
                objApexSettings.Bypass_All_Validations__c=false;
                upsert objApexSettings cs_Apex_Settings__c.Id;
            }


        } catch(Exception ex) {
            ilib_LogEvent.error(LOG_TITLE + ' - Exception occurred - ' + ex.getMessage());
            // logging it to surface on Splunk
            ApexExceptions.emit(LOG_TITLE, ex, ilib_LogEvent.MARKETING);
            throw ex;

        } finally {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }

    }

    /*Finish method of Batch Class*/   
    global override void finish(Database.BatchableContext bc) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.finish()');

        ilib_LogEvent.info('No work for finish method');

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    @Description: To throw custom exception for covering catch block in test class execution
   */
   public class CustomException extends Exception {}
}
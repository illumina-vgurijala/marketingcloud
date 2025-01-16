/**
*    @author  Pankaj Singla
*    @date    01-August-2018
*    @description  This Batch job updates the campaign member status from Registered to No Show 
                    if the Campaign Date is passed the current date(2 days time period) if the Campaign Type is
                    Webinar
                    Runs once a day

*        Modification Log:
*       
------------------------------------------------------------------------------------
*       Developer                       Date                Description
*       
------------------------------------------------------------------------------------
*       Pankaj Singla                03/10/2018            Original  Version
*/
public class BatchToUpdateCampaignMemberStatus extends ilib_ScheduleAndBatch {

    public static final String STRING_CAMPAIGN_TYPE_WEBINAR = 'Webinar'; //Considers only campign type as Webinar
    public static final String STRING_CAMPAIGN_STATUS_NO_SHOW = 'No Show';  // Final status of the campaign member to be updated
    public static final String STRING_CAMPAIGN_STATUS_REGISTERED = 'Registered'; // Initial status of campaign member
    public static final Integer INTEGER_NUMBER_OF_ELAPSED_DAYS_MIN = 2;  // Minimum Number of Elapsed days after Campaign End Date
    public static final Integer INTEGER_NUMBER_OF_ELAPSED_DAYS_MAX = 5;  // Maximum Number of Elapsed days after Campaign End Date

    /*Execute method of Schedulable Context */
    public override void execute(SchedulableContext ctx)
    {
        Database.executeBatch(new BatchToUpdateCampaignMemberStatus());
    }

    /* The batch job considers the campaigns whose end date has elapsed between the min and max day criteria*/
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        String strSoql;
        if(!Test.isRunningTest()){
            // Get list of all campaign member which are Registered and Campaign End Date is passed the required number of days
        strSoql = 'SELECT Id, Campaignid, LeadOrContactId, Campaign.Name, Status, Campaign.EndDate, Campaign.Type FROM CampaignMember ' +
            ' WHERE Campaign.EndDate != null AND Campaign.Type = :STRING_CAMPAIGN_TYPE_WEBINAR AND Status = :STRING_CAMPAIGN_STATUS_REGISTERED';
        }
        else {
            // Get list of all campaign member which are Registered and Campaign End Date is passed the required number of days
        strSoql = 'SELECT Id, Campaignid, LeadOrContactId, Campaign.Name, Status, Campaign.EndDate, Campaign.Type FROM CampaignMember ' +
            ' WHERE Campaign.EndDate != null AND Campaign.Type = :STRING_CAMPAIGN_TYPE_WEBINAR AND Status = :STRING_CAMPAIGN_STATUS_REGISTERED order by createddate desc limit 1';
        }
        

      return Database.getQueryLocator(strSoql);
    }

    /*Execute method of Batch Class */
    public override void execute(Database.BatchableContext objBatchableContext, List<SObject> lstScope)
    {
         Date dtToday = Date.today();
         List<CampaignMember> lstCampaignMember = new List<CampaignMember>();

         for (CampaignMember objCampaignMember : (List<CampaignMember>)lstScope)
         {
             if (objCampaignMember.Campaign.EndDate.daysBetween(dtToday) >= INTEGER_NUMBER_OF_ELAPSED_DAYS_MIN
                 && objCampaignMember.Campaign.EndDate.daysBetween(dtToday) <= INTEGER_NUMBER_OF_ELAPSED_DAYS_MAX)
             {
                 objCampaignMember.Status = STRING_CAMPAIGN_STATUS_NO_SHOW;
                 lstCampaignMember.add(objCampaignMember);
             }
         }

         if (lstCampaignMember.size() > 0)
         {
             update lstCampaignMember;
         }
    }
    /*Finish method of Batch Class */
    public override void finish(Database.BatchableContext objBatchableContext) { }

}
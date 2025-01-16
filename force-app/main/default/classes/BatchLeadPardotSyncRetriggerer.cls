/**
*    @author: Pankaj 
*    @date:   16-Jan-2019
*    @description:  Batch Class to perform a dummy update on Lead records to re-trigger Pardot Sync
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        16-Jan-2019        Initial Development

        BatchLeadPardotSyncRetriggerer objBatch=new BatchLeadPardotSyncRetriggerer();
        String sch='0 0 * * * ? *';
        String sch2='0 30 * * * ? *';
        System.schedule('BatchLeadPardotSyncRetriggerer', sch , objBatch);
        System.schedule('BatchLeadPardotSyncRetriggerer', sch2, objBatch);

*    ------------------------------------------------------------------------------------ 
*                    
*/
global class BatchLeadPardotSyncRetriggerer extends ilib_ScheduleAndBatch {

    global Datetime dtCutoffTime = Datetime.now().addminutes(-30);

    /*Start method of Batch Class*/
    global override Database.QueryLocator start(Database.BatchableContext bc)
    {
         String strSoql='SELECT Id, Marketable_Date__c, Pardot_Re_Trigger_Date__c FROM Lead WHERE Marketable_Date__c != NULL AND Marketable_Date__c > :dtCutoffTime AND isconverted = false';
         strSOQL=String.escapeSingleQuotes(strSOQL);
        return Database.getQueryLocator(strSOQL);
    }

    /*Execute method for Schedulable Context*/
    global override void execute(SchedulableContext sc)
    {
        BatchLeadPardotSyncRetriggerer b = new BatchLeadPardotSyncRetriggerer();
        Database.executebatch(b);
    }

    /*Execute method of Batch Class*/
    global override void execute (Database.BatchableContext bc, List<SObject> scope)
    {
        system.debug('scope is---'+scope);
        List<Lead> lstLead = new List<Lead>();
        Long lgNowValue = Datetime.now().getTime();
        Long lgReTriggerDateValue;
        Long lgDiffInMinutes;

        for (Lead objLead : (List<Lead>)scope)
        {
            if(objLead.Pardot_Re_Trigger_Date__c!=null)
            {
                lgReTriggerDateValue=objLead.Pardot_Re_Trigger_Date__c.getTime();
                lgDiffInMinutes=(lgNowValue-lgReTriggerDateValue)/(1000*60);

                // Check if the ReTriggerDate is past 30 minutes and is earlier than Marketable date
                if(objLead.Pardot_Re_Trigger_Date__c < objLead.Marketable_Date__c && lgDiffInMinutes > 30)
                {
                     objLead.Pardot_Re_Trigger_Date__c = Datetime.now();
                     lstLead.add(objLead);
                }
            }
            else if (objLead.Pardot_Re_Trigger_Date__c == null)
            {
                objLead.Pardot_Re_Trigger_Date__c=Datetime.now();
                lstLead.add(objLead);
            }
        }

        if (lstLead.size() > 0)
        {
            Database.update(lstLead, false);
        }
    }

    /*Finish method of Batch Class*/
    global override void finish(Database.BatchableContext bc) { }

}
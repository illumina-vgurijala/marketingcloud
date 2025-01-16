/**
*    @author: Pankaj 
*    @date:   16-Jan-2019
*    @description:  Batch Class to perform a dummy update on Contact records to re-trigger Pardot Sync
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        16-Jan-2019        Initial Development

        BatchContactPardotSyncRetriggerer objBatch=new BatchContactPardotSyncRetriggerer();
        String sch='0 0 * * * ? *';
        String sch2='0 30 * * * ? *';
        System.schedule('BatchContactPardotSyncRetriggerer', sch , objBatch);
        System.schedule('BatchContactPardotSyncRetriggerer2', sch , objBatch);
*    ------------------------------------------------------------------------------------ 
*                    
*/
global class BatchContactPardotSyncRetriggerer extends ilib_ScheduleAndBatch {

    global Datetime dtCutoffTime = Datetime.now().addminutes(-30);

    /*Execute method for Schedulable Context*/
    global override void execute(SchedulableContext sc)
    {
        Database.executebatch(new BatchContactPardotSyncRetriggerer());
    }

    /*Start method of Batch Class*/
    global override Database.QueryLocator start(Database.BatchableContext bc)
    {
        String strSoql ='SELECT id, Marketable_Date__c, Pardot_Re_Trigger_Date__c FROM Contact WHERE Marketable_Date__c != NULL AND Marketable_Date__c > :dtCutoffTime';
        strSOQL=String.escapeSingleQuotes(strSOQL);
        return Database.getQueryLocator(strSOQL);
    }

    /*Execute method of Batch Class*/
    global override void execute (Database.BatchableContext bc, List<SObject> scope)
    {
        List<Contact> lstContact = new List<Contact>();
        Long lgNowValue = Datetime.now().getTime();
        Long lgReTriggerDateValue;
        Long lgDiffInMinutes;

        for (Contact objContact : (List<Contact>)scope)
        {
            if (objContact.Pardot_Re_Trigger_Date__c!=null)
            {
                lgReTriggerDateValue = objContact.Pardot_Re_Trigger_Date__c.getTime();
                lgDiffInMinutes = (lgNowValue - lgReTriggerDateValue) / (1000*60);

                // Check if the ReTriggerDate is past 30 minutes and is earlier than Marketable date
                if(objContact.Pardot_Re_Trigger_Date__c < objContact.Marketable_Date__c && lgDiffInMinutes > 30)
                {
                     objContact.Pardot_Re_Trigger_Date__c = Datetime.now();
                     lstContact.add(objContact);
                }
            }
            else if (objContact.Pardot_Re_Trigger_Date__c == null)
            {
                objContact.Pardot_Re_Trigger_Date__c = Datetime.now();
                lstContact.add(objContact);
            }
        }

        if (lstContact.size() > 0)
            Database.update(lstContact, false);
    }
    /*Finish method of Batch Class*/
    global override void finish(Database.BatchableContext bc) { System.debug('Batch Class Logic Finished'); }

}
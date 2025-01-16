/**
*    @author: Deep Diwakar
*    @date:   Feb-09-2024
*    @description: One time batch class to update existing contacts with new Area of Work field
*    @Test Class: TestBatchContactAOWUpdates
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Feb-09-2024        CMCM-4508: Batch class to update existing contacts with new AOW field
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class BatchContactAOWUpdates implements Database.Batchable<sObject> {

    private static final String LOG_TITLE = 'BatchContactAOWUpdates';

    /**
     * @author: Deep Diwakar
     * @date: Feb-09-2024 
     * @description: Start method for batch class to collect records
     * @param: bc - batch context
     * @return: Database.QueryLocator to return contact records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.start()');

        String strSOQL = 'SELECT Id, AccountId, Area_Of_Work__c FROM Contact';
        strSOQL=String.escapeSingleQuotes(strSOQL);

        ilib_LogEvent.info('strSOQL: ' + strSOQL);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return Database.getQueryLocator(strSOQL);
    }
    
    /**
     * @author: Deep Diwakar
     * @date: Feb-09-2024 
     * @description: Execute method to run logic for AOW field
     * @param: bc - batch conext
     * @param: scope - contact records for this batch
     * @return: void
     */
    public void execute (Database.BatchableContext bc, List<Contact> scope) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        List<Contact> lstContactUpdate = new List<Contact>();
        List<Contact> lstContactUpdateFinal = new List<Contact>();

        // filter contacts based on existing AOW value and empty account id
        for (Contact cont : scope) {
            if (String.isBlank(cont.Area_Of_Work__c) && !String.isBlank(cont.AccountId)) {
                ilib_LogEvent.message('contact id: ' + cont.Id);
                lstContactUpdate.add(cont);
            }
        }

        ilib_LogEvent.info('lstContactUpdate size pre decorator: ' + lstContactUpdate.size());

        if (lstContactUpdate.isEmpty()) {
            ilib_LogEvent.info('nothing to update, returning');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return;
        }

        ilib_SObjectDecorator aowDecorator = new AreaOfWorkContactDecorator(lstContactUpdate);
        aowDecorator.decorate();

        ilib_LogEvent.info('lstContactUpdate size after decorator: ' + lstContactUpdate.size());

        // create list of records that are updated by decorator
        for (Contact cont : lstContactUpdate) {
            if (!String.isBlank(cont.Area_Of_Work__c)) {
                lstContactUpdateFinal.add(cont);
            }
        }

        ilib_LogEvent.info('lstContactUpdateFinal size: ' + lstContactUpdateFinal.size());

        if (lstContactUpdateFinal.isEmpty()) {
            ilib_LogEvent.info('nothing to update, returning');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return;
        }

        // Bypassing trigger run, validation and flows because this is one time mass update of existing records
        if (Schema.sObjectType.cs_Apex_Settings__c.isUpdateable() && Schema.sObjectType.cs_Apex_Settings__c.isCreateable()) {
          cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();

          // adding bypass for running user
          objApexSettings.Bypass_All_Validations__c=true;
          objApexSettings.Bypass_All_Triggers__c=true;
          objApexSettings.Bypass_All_Flows__c=true;
          upsert objApexSettings cs_Apex_Settings__c.Id;
          List<Database.SaveResult> results = Database.update(lstContactUpdateFinal, false);
          // log errors, if any
          ApexExceptions.emitSaveErrors(results, LOG_TITLE);

          // revert bypass
          objApexSettings.Bypass_All_Validations__c=false;
          objApexSettings.Bypass_All_Triggers__c=false;
          objApexSettings.Bypass_All_Flows__c=false;
          upsert objApexSettings cs_Apex_Settings__c.Id;
        } else {
          ilib_LogEvent.info('User does not have create and update permission on custom setting - Apex Settings');
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();


    }

    /**
     * @author: Deep Diwakar
     * @date: Feb-09-2024 
     * @description: Required final method for batch
     * @param: bc - batch context
     * @return: void
     */
    public void finish(Database.BatchableContext bc) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.finish()');

        ilib_LogEvent.info('No work for finish method');

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}
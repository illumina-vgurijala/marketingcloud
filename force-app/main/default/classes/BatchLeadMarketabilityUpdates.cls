/**
*    @author: Deep Diwakar
*    @date:   Mar-19-2024
*    @description: One time batch class to update existing leads marketability based on new marketability logic
*    @Test Class: TestBatchLeadMarketabilityUpdates
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Mar-19-2024        CMCM-5552: Batch class to update existing leads marketability
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class BatchLeadMarketabilityUpdates implements Database.Batchable<sObject> {

    private static final String LOG_TITLE = 'BatchLeadMarketabilityUpdates';

    /**
     * @author: Deep Diwakar
     * @date: Mar-19-2024 
     * @description: Start method for batch class to collect records
     * @param: bc - batch context
     * @return: Database.QueryLocator to return lead records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.start()');

        String strSOQL = 'SELECT Id, Country, CountryCode, Opt_in_Rule__c, Explicit_Opt_In__c, Double_Opt_In_Email_Sent_Date__c, '
                         + 'Implicit_Opt_In__c, Double_Opt_In__c, Explicit_Opt_In_Date__c, Marketable__c, Marketable_Date__c, '
                         + 'Implicit_Opt_In_Date__c, Double_Opt_In_Date__c, Pardot_Opted_Out__c, HasOptedOutOfEmail '
                         + 'FROM Lead WHERE IsConverted = false';

        strSOQL=String.escapeSingleQuotes(strSOQL);

        ilib_LogEvent.info('strSOQL: ' + strSOQL);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return Database.getQueryLocator(strSOQL);
    }
    
    /**
     * @author: Deep Diwakar
     * @date: Mar-19-2024 
     * @description: Execute method to run logic new Marketability logic
     * @param: bc - batch conext
     * @param: scope - lead records for this batch
     * @return: void
     */
    public void execute (Database.BatchableContext bc, List<Lead> scope) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        List<Lead> lstLeadUpdates = new List<Lead>();

        MarketabilityServiceFacade facade = new MarketabilityServiceFacade();
        lstLeadUpdates = facade.determineMarketability(scope, 'global-v1');

        ilib_LogEvent.info('lstLeadUpdates size: ' + lstLeadUpdates.size());

        // Bypassing trigger run, validation and flows because this is one time mass update of existing records
        if (Schema.sObjectType.cs_Apex_Settings__c.isUpdateable() && Schema.sObjectType.cs_Apex_Settings__c.isCreateable()) {
          cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();
          
          // adding bypass for running user
          objApexSettings.Bypass_All_Validations__c=true;
          objApexSettings.Bypass_All_Triggers__c=true;
          objApexSettings.Bypass_All_Flows__c=true;
          upsert objApexSettings cs_Apex_Settings__c.Id;
          List<Database.SaveResult> results = Database.update(lstLeadUpdates, false);
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
     * @date: Mar-19-2024 
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
/**
 *  @author Pradeep Landge  
 *  @date  24-June-2024
 *  @description  [DCP-522] | [CPQ]: Data remediation - For In Progress Quotes
 *  Modification Log:
 *  ------------------------------------------------------------------------------------
 *       Developer           Date            Description  
 *       Pradeep Landge      24-June-2024    Initial Version
 *  ------------------------------------------------------------------------------------
 **/
public with sharing class BatchUpdateApprovalReqQuoteToDraftStage implements Database.Batchable < sObject > , Database.Stateful {
    public static String strQuoteStageDraft = 'Draft';
    set < Id > processedQuotes = new set < Id > ();
    private static final String LOG_TITLE = 'BatchUpdateApprovalReqQuoteToDraftStage';
    cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(userInfo.getUserId());


    /**
     *  @author Pradeep Landge
     *  @description Batch start method
     **/
    public Database.QueryLocator start(Database.BatchableContext bc) {

        cs.Bypass_All_Validations__c = true;
        upsert cs cs_Apex_Settings__c.Id;

        String strSoql = 'select id, Apttus_Proposal__Approval_Stage__c from  Apttus_Proposal__Proposal__c where Apttus_Proposal__Approval_Stage__c = \'Approval Required\'';
        return Database.getQueryLocator(strSOQL);
    }

    /**
     *  @author Pradeep Landge
     *  @description Execute method - Update Quote Stage
     **/
    public void execute(Database.BatchableContext bc, list < SObject > scope) {
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        List < Apttus_Proposal__Proposal__c > lstProposal = new List < Apttus_Proposal__Proposal__c > ();

        for (Apttus_Proposal__Proposal__c objProposal: (List < Apttus_Proposal__Proposal__c > ) scope) {

            objProposal.Apttus_Proposal__Approval_Stage__c = strQuoteStageDraft;
            lstProposal.add(objProposal);
            ilib_LogEvent.info('lstProposal > '+lstProposal);
        }
        if (!lstProposal.isEmpty()) {
            List < Database.SaveResult > srList = Database.update(lstProposal, false);
            ApexExceptions.emitSaveErrors(srList, LOG_TITLE + ' updateQuoteStageDraft ');
            // Iterate through each returned result
            for (Database.SaveResult sr: srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    processedQuotes.add(sr.getId());
                }
            }
        }

        ilib_LogEvent.pop();
    }


    /**
     *  @author Pradeep Landge
     *  @description Batch Finish method
     **/
    public void finish(Database.BatchableContext bc) {
        ilib_LogEvent.push(LOG_TITLE + '.finish()');
        cs.Bypass_All_Validations__c = false;
        upsert cs cs_Apex_Settings__c.Id;
        // Call line batch and pass processedQuotes;        
        ilib_LogEvent.info('processedQuotes > '+processedQuotes);
        BatchUpdateToRecalculate updateLines = new BatchUpdateToRecalculate(processedQuotes);
        Database.executeBatch(updateLines, 1);
        ilib_LogEvent.pop();
    }

}
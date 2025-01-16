/**
*	@author Adithi Acharya
*	@date	06-October-2022
*	@description	[DCP-56441] Batch to update Invalid Quotes to Denied stage
*	Modification Log:
*	------------------------------------------------------------------------------------
*			Developer					Date				Description	
*           Adithi Acharya             06-October-2022      Initial Version
*	------------------------------------------------------------------------------------
**/
public with sharing class BatchToUpdateInvalidQuoteToDeniedStage implements Database.Batchable<sObject>{
    public static String strQuoteStageDenied = 'Denied';
    private static final String LOG_TITLE='BatchToUpdateInvalidQuoteToDeniedStage';
    

    /**
    *	@author Adithi Acharya
    *	@description Batch start method
    **/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String strSoql='select id, Apttus_Proposal__Approval_Stage__c, Invalid_Quote__c from  Apttus_Proposal__Proposal__c where Invalid_Quote__c = true';    
        return Database.getQueryLocator(strSOQL);
    }    

    /**
    *	@author Adithi Acharya
    *	@description Execute method - Update Quote Stage
    **/
    public void execute(Database.BatchableContext bc, list<SObject> scope){

        List<Apttus_Proposal__Proposal__c> lstProposal = new List<Apttus_Proposal__Proposal__c>();

        for(Apttus_Proposal__Proposal__c objProposal : (List<Apttus_Proposal__Proposal__c>)scope) {
           
                objProposal.Apttus_Proposal__Approval_Stage__c= strQuoteStageDenied;
				lstProposal.add(objProposal);
            
        }   
            cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(userInfo.getUserId());
            try{
                if (!lstProposal.isEmpty())
                {
                    cs.Bypass_All_Validations__c = true;
                    upsert cs cs_Apex_Settings__c.Id;
                    Database.update(lstProposal, false);
                    List<Database.SaveResult> lstSaveErrorsQuo = Database.update(lstProposal, false);
                    ApexExceptions.emitSaveErrors(lstSaveErrorsQuo, LOG_TITLE +' updateQuoteStage ');
                }
            }
            catch(Exception e){
                //catch the exception 
                ApexExceptions.emit(LOG_TITLE,e);
            } 
            finally{
                cs.Bypass_All_Validations__c = false;
                upsert cs cs_Apex_Settings__c.Id;
            }
    }
    
    
    /**
    *	@author Adithi Acharya
    *	@description Batch Finish method
    **/
    public void finish(Database.BatchableContext bc) {
        /**No logic required */
    }
    
}
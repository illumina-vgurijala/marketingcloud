/**
*    @author: Pankaj 
*    @date:   09-Jun-2020
*    @description:  Batch Class to Migrate Prospect score from Pardot Score to Marketing Score
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        09-Jun-2019        Initial Development

       Database.executeBatch(new BatchMigratePardotScore('Lead'));
       Database.executeBatch(new BatchMigratePardotScore('Contact'));
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class BatchMigratePardotScore extends ilib_ScheduleAndBatch{
	public static final String STRING_LEAD = 'Lead';
    public static final String STRING_ACTION_NAME='Transition From Pardot Score to Marketing Score';
    public String objectName;
    /* Parameterized Constructor */
    public BatchMigratePardotScore(String objectName){
        this.objectName=objectName;
    }
    /*Start method of Batch Class*/   
    public override Database.QueryLocator start(Database.BatchableContext bc){
        String strSoql='Select id,Marketing_Score__c,pi__score__c from '+ objectName+' where pi__score__c!=null and pi__score__c>0 and Marketing_Score__c=null';
        /*If the object name is lead, update only the non converted records*/   
         if(ObjectName.equals(STRING_LEAD)){
            strSoql=strSoql+' and isconverted=false';
         }
        strSOQL=String.escapeSingleQuotes(strSOQL);     
        return Database.getQueryLocator(strSOQL);
    }
    /*Execute method of Batch Class*/
    public override void execute (Database.BatchableContext bc, List<SObject> scope){
        List<sObject> lstObject=New List<sObject>();
        List<Prospect_Scoring_Log__c> lstProspectScoreLog=new List<Prospect_Scoring_Log__c>();
        for(sObject obj:scope){
            if(obj.get('pi__score__c')!=null){
                Integer intPiScore=Integer.ValueOf(obj.get('pi__score__c'));
                obj.put('Marketing_Score__c',intPiScore);
                lstObject.add(obj);                
                Prospect_Scoring_Log__c objProspectScoringLog=ProspectScoringUtils.createProspectScoringLogRecords(STRING_ACTION_NAME,'',obj.Id,UserInfo.getUserId(),'',0,intPiScore);
                lstProspectScoreLog.add(objProspectScoringLog);	
            }
        }
        
        
        if(lstObject.size()>0){
			Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(p.Id);
            cs.Bypass_All_Validations__c = true;
            upsert cs cs_Apex_Settings__c.Id;
            Database.update(lstObject, false);
			cs.Bypass_All_Validations__c = false;
            upsert cs cs_Apex_Settings__c.Id;
        }
        if(lstProspectScoreLog.size()>0){
            insert lstProspectScoreLog;
        }
    }
    
    /*Finish method of Batch Class*/
    public override void finish(Database.BatchableContext bc) { 
      system.debug(' Batch Job Completed');
    }
}
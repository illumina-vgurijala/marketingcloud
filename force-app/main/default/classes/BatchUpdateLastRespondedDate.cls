/**
*    @author: Pankaj
*    @date:   05-Oct-2020
*    @description:  Batch class to update Last Responded Date on Campaign
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 05 Oct 2020          Initial build
              
*    ------------------------------------------------------------------------------------
*
*/
public with sharing class BatchUpdateLastRespondedDate extends ilib_ScheduleAndBatch{
    public static final Integer INT_PST_TIME_LAG_HOURS=Integer.ValueOf(Label.PST_Time_Lag);
    /*
    * @author Pankaj Singla
    * @date   05-Oct-2020
    * @description: The start method of batch job. It fetches all campaign mambers records
    */
    public override Database.QueryLocator start(Database.BatchableContext objBatchable){
        String strSoql;
        if(Test.isRunningTest()){
            set<String> setCampaignName=new Set<String>{'testing1dddd','testing1eee'};
            strSoql='select id,leadId,Lead.Last_Responded_Campaign__c,Lead.Last_Responded_Campaign_Date__c,contactId,Contact.Last_Responded_Campaign__c,Contact.Last_Responded_Campaign_Date__c,campaignId,createddate,lastmodifieddate,FirstRespondedDate from campaignMember where hasresponded=true and campaign.Name in:setCampaignName order by createddate';
        }
        else {
            strSoql='select id,leadId,Lead.Last_Responded_Campaign__c,Lead.Last_Responded_Campaign_Date__c,contactId,Contact.Last_Responded_Campaign__c,Contact.Last_Responded_Campaign_Date__c,campaignId,FirstRespondedDate,createddate,lastmodifieddate from campaignMember where hasresponded=true and Lead.isConverted=false order by createddate';
        }
        
        strSOQL=String.escapeSingleQuotes(strSOQL);     
        return Database.getQueryLocator(strSOQL);
        
    }
    /*
    * @author Pankaj Singla
    * @date   05-Oct-2020
    * @description: The execute method of batch job.
    */
    public override void execute (Database.BatchableContext objBatchable, List<SObject> scope){
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Map<Id,Lead> mapLeadIdToLead =new Map<Id,Lead>();
        Map<Id,Contact> mapContactIdToContact=new Map<Id,Contact>();
        List<Lead> lstLead=new List<Lead>();
        List<contact> lstContact=new List<Contact>();
        for(campaignMember objCampaignMember:(List<campaignMember>)scope){
            if(objCampaignMember.LeadId!=null ){
                Date dtFirstRespondedDate;
				Date dtLeadLastRespondedDateValue;
                Lead objLead;
                if(mapLeadIdToLead.containsKey(objCampaignMember.LeadId)){
                    objLead=mapLeadIdToLead.get(objCampaignMember.LeadId);
                    dtLeadLastRespondedDateValue=Date.ValueOf(objLead.Last_Responded_Campaign_Date__c);
                    dtFirstRespondedDate=objCampaignMember.FirstRespondedDate;
                }
                else {
                    objLead=new Lead(Id=objCampaignMember.LeadId);
                    dtLeadLastRespondedDateValue=Date.ValueOf(objCampaignMember.Lead.Last_Responded_Campaign_Date__c);
                    dtFirstRespondedDate=objCampaignMember.FirstRespondedDate;
                }               
                system.debug('dtLeadLastRespondedDate for lead--'+dtLeadLastRespondedDateValue);
                if(dtLeadLastRespondedDateValue==null || (dtLeadLastRespondedDateValue<=dtFirstRespondedDate)){
                    objLead.Last_Responded_Campaign_Date__c=computeDate(dtFirstRespondedDate);
                    objLead.Last_Responded_Campaign__c=objCampaignMember.CampaignId;
                    mapLeadIdToLead.put(objLead.Id,objLead);
                }   
                
                
            }
            
            if(objCampaignMember.ContactId!=null ){
                Date dtContactLastRespondedDateValue;
                Contact objcontact;
                Date dtFirstRespondedDate;
                if(mapContactIdToContact.containsKey(objCampaignMember.ContactId)){
                    objcontact=mapContactIdToContact.get(objCampaignMember.ContactId);
                    dtContactLastRespondedDateValue=Date.ValueOf(objcontact.Last_Responded_Campaign_Date__c);
                    dtFirstRespondedDate=objCampaignMember.FirstRespondedDate;
                }
                else {
                    objcontact=new Contact(Id=objCampaignMember.ContactId);
                    dtContactLastRespondedDateValue=Date.ValueOf(objCampaignMember.Contact.Last_Responded_Campaign_Date__c);
                    dtFirstRespondedDate=objCampaignMember.FirstRespondedDate;
                }               
                system.debug('dtContactLastRespondedDate for contact--'+dtContactLastRespondedDateValue);
                if(dtContactLastRespondedDateValue==null || (dtContactLastRespondedDateValue<=dtFirstRespondedDate)){
                    objcontact.Last_Responded_Campaign_Date__c=computeDate(dtFirstRespondedDate);
                    objcontact.Last_Responded_Campaign__c=objCampaignMember.CampaignId;
                    mapContactIdToContact.put(objcontact.Id,objcontact);
                }   
                
                
            }
        }
        
		if(mapLeadIdToLead.size()>0){
			lstLead.addAll(mapLeadIdToLead.values());
		}
        		
		if(mapContactIdToContact.size()>0){
			lstContact.addAll(mapContactIdToContact.values());
		}
		
        
        if(lstLead.size()>0){
            cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(objProfile.Id);
            cs.Bypass_All_Validations__c = true;
            upsert cs cs_Apex_Settings__c.Id;
            update lstLead;
            cs.Bypass_All_Validations__c = false;
            upsert cs cs_Apex_Settings__c.Id;
        }
        
        if(lstContact.size()>0){
            cs_Apex_Settings__c cs = cs_Apex_Settings__c.getInstance(objProfile.Id);
            cs.Bypass_All_Validations__c = true;
            upsert cs cs_Apex_Settings__c.Id;
            update lstContact;
            cs.Bypass_All_Validations__c = false;
            upsert cs cs_Apex_Settings__c.Id;
        }
    }
    /*
    * @author Pankaj Singla
    * @date   05-Oct-2020
    * @description: The finish method of batch job.
    */
    public override void finish(Database.BatchableContext objBatchable){
       system.debug('I am Finished'); 
    } 
    
    /*
    * @author Pankaj Singla
    * @date   05-Oct-2020
    * @description: Method to add offset to UTC time based on PST lag
    */
	private static Datetime computeDate(Date dtDateValue){
		Time myTime = Time.newInstance(INT_PST_TIME_LAG_HOURS, 0, 0, 0);
		Datetime dt = DateTime.newInstance(dtDateValue,myTime);
		return dt;
	}

}
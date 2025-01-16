/**
*    @author: Pankaj Singla
*    @date:   16-Apr-2021
*    @description: Batch Class to Update Hive 9 waterfall stage for Contacts {Test Class - TestBatchHiveNineWaterfallUpdates}
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date            Description
*        Pankaj Singla       16-Apr-2021         Initial build
*        Rishab Wali         23-Mar-2022       DCP-52296 Waterfall Opp Adjustments
*        Rishab Wali         22-Aug-2022       DCP-55949 Waterfall Changes for Open Opps
*        Rishab Wali         27-Sep-2022       DCP-57910 - Adding check for waterfall changes 
*        Deep Diwakar        03-Oct-2022       DCP-57910 - Correcting empty/null checks
*        Deep Diwakar       April-14-2023      DCP-59777 - Updated batch job query to run based on lastmodifieddate  
*        Deep Diwakar       Aug-14-2023        DCP-60131: Setting up contact status to open opportunity, not waiting for other batch job
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class BatchHiveNineWaterfallUpdate extends ilib_ScheduleAndBatch implements Schedulable{
    public static final String STRING_FUNNEL_MARKETING='Funnel Marketing';
    public static final String STRING_RENEWAL_SERVICE_CONTRACT='Renewal - Service Contract No Upsell';
    public static final String STRING_NO_SELL='Renewal - Software No Upsell';
    public static final String STRING_BILLABLE_SERVICES='Billable Services';
    public static final String STRING_OPPORTUNITY_CLOSED_WON='Closed Won';
    public static final String STRING_OPEN_OPPORTUNITY='Open Opportunity';
    public static final String STR_OPPORTUNITY = 'Opportunity';

     /*Execute method for Schedulable Context*/
    public override void execute(SchedulableContext ctx){
       Database.executeBatch(new BatchHiveNineWaterfallUpdate());
    }
    /*
    * @author Pankaj Singla
    * @date   02-May-2021 
    * @description: start method   
    * @parameters:Batchable context
    * @return : Database.QueryLocator
    */
    public override Database.QueryLocator start(Database.BatchableContext bC){
        Date dtToday=Date.today().adddays(-2);
        Set<string> setStagename=new Set<String>{STR_OPPORTUNITY,'Closed Won'};
        set<String> setOpenOpp=new Set<String> {'Create','Qualify','Develop','Prove','Negotiate & Resolve','Finalize'};

        // DCP-59777: Updated this query to run based on lastmodifieddate instead of createddate. This is done to account for user action
        //             where they edit existing contact role by removing current contact and adding new contact
        String strSoql = 'SELECT ContactId,contact.Marketing_Contact_Status__c,OpportunityId,opportunity.StageName,Contact.Waterfall_Stage__c, ' 
                        + ' Contact.Waterfall_Closed_Won_Date__c, Contact.Waterfall_Engaged_Date__c,Contact.Waterfall_Opportunity_Date__c,Contact.Waterfall_Qualified_Date__c, '+
                        ' Contact.Waterfall_Sales_Accepted_Date__c,Contact.Last_Responded_Campaign_Date__c,Opportunity.Type,Opportunity.LeadSource ' +
                         ' FROM OpportunityContactRole ' +
                        ' where Opportunity.StageName  in:setOpenOpp  and Contact.waterfall_stage__c not in:setStagename and lastmodifieddate>=:dttoday '; 
                        
        return Database.getQueryLocator(strSoql);
    }
    /*
    * @author Pankaj Singla
    * @date   02-May-2021 
    * @description: execute method   
    * @parameters:Batchable context
    * @param: list of records
    * @return : Database.QueryLocator
    */
    public override void execute(Database.BatchableContext bC, List<sObject> lstOppContactRole){
        //Datetime dtYearAgo=Datetime.now().addYears(-1);
        Set<String> setWaterfallStages=new Set<String>{'Closed Won',STR_OPPORTUNITY};
        set<String> setRenewalOpportunityTypes=new set<String>{STRING_RENEWAL_SERVICE_CONTRACT,STRING_NO_SELL,STRING_BILLABLE_SERVICES};
        //Set<Id> setContactIds=new Set<Id>();
        List<Contact> lstContacts=new List<Contact>();
        Map<Id,Contact> mapIdContact=new Map<Id,Contact>();
        for(OpportunityContactRole objOpportunityContactRole:(List<OpportunityContactRole>)lstOppContactRole){
            Boolean boolFunnelOpp = objOpportunityContactRole.Opportunity.LeadSource=='Funnel Marketing'?true:false;
			if(!setRenewalOpportunityTypes.contains(objOpportunityContactRole.Opportunity.Type) && (boolFunnelOpp || (objOpportunityContactRole.Contact.Last_Responded_Campaign_Date__c != null && objOpportunityContactRole.Contact.Last_Responded_Campaign_Date__c > System.now()-365) 
            || (String.isNotBlank(objOpportunityContactRole.Contact.waterfall_stage__c) && !STR_OPPORTUNITY.equalsIgnoreCase(objOpportunityContactRole.Contact.waterfall_stage__c)))) {  //DCP-57910
                ilib_LogEvent.message('Run Waterfall Logic'); 
            }
            else { continue; }
            Boolean boolClearWaterFallDates=false;
            Id idContact=objOpportunityContactRole.ContactId;
            Contact objContact=mapIdContact.containsKey(idContact)?mapIdContact.get(idContact):(new Contact(id=idContact));
             if(!setWaterfallStages.contains(objOpportunityContactRole.Contact.Waterfall_Stage__c) && objOpportunityContactRole.Contact.Marketing_Contact_Status__c.equals(STRING_OPEN_OPPORTUNITY)){
				if(String.isBlank(objOpportunityContactRole.Contact.Waterfall_Stage__c)){
                     objContact.Waterfall_Closed_Won_Date__c=null;
                     objContact.Waterfall_Opportunity_Date__c=null;
                     objContact.Waterfall_Sales_Accepted_Date__c=null;
                     objContact.Waterfall_Qualified_Date__c=null;
                     objContact.Waterfall_Engaged_Date__c=null;
                     boolClearWaterFallDates=true;
                 } 
                ObjContact.Waterfall_Stage__c=STR_OPPORTUNITY;
                
				objContact.Waterfall_Opportunity_Date__c=(objOpportunityContactRole.Contact.Waterfall_Opportunity_Date__c==null||boolClearWaterFallDates)?Datetime.now():objOpportunityContactRole.Contact.Waterfall_Opportunity_Date__c;
                
				objContact.Waterfall_Sales_Accepted_Date__c=(objOpportunityContactRole.Contact.Waterfall_Sales_Accepted_Date__c==null||boolClearWaterFallDates)?Datetime.now():objOpportunityContactRole.Contact.Waterfall_Sales_Accepted_Date__c;
                
				objContact.Waterfall_Qualified_Date__c=(objOpportunityContactRole.Contact.Waterfall_Qualified_Date__c==null||boolClearWaterFallDates)?Datetime.now():objOpportunityContactRole.Contact.Waterfall_Qualified_Date__c;
                
				objContact.Waterfall_Engaged_Date__c=(objOpportunityContactRole.Contact.Waterfall_Engaged_Date__c==null||boolClearWaterFallDates)?Datetime.now():objOpportunityContactRole.Contact.Waterfall_Engaged_Date__c;
                
                // DCP-60131: Setting up contact status right here, not waiting for other batch job
                if (!STRING_OPEN_OPPORTUNITY.equals(objOpportunityContactRole.Contact.Marketing_Contact_Status__c)) {
                    objContact.Marketing_Contact_Status__c = STRING_OPEN_OPPORTUNITY;
                    objContact.Is_Recycled__c=false;
                }

				mapIdContact.put(idContact,objContact);
            }
        }
        
        if(!mapIdContact.isEmpty()){
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            lstContacts.addAll(mapIdContact.values());
            cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(p.Id);
            cs.Bypass_All_Validations__c = true;
            cs.Bypass_All_Triggers__c = true;
            upsert cs cs_Apex_Settings__c.Id;
            Database.update(lstContacts,false);
            cs.Bypass_All_Validations__c = false;
            cs.Bypass_All_Triggers__c = false;
            upsert cs cs_Apex_Settings__c.Id;
        }
    }
    /*
    * @author Pankaj Singla
    * @date   02-May-2021 
    * @description: finish method   
    * @parameters:None
    * @return : None
    */
    public override void finish(Database.BatchableContext bC){
        ilib_LogEvent.message('Finish Method');
    }
}
/**
*    @author: Pankaj 
*    @date:   10-Sept-2018
*    @description:  atch Class to update Contact Marketing status for Open Opportunitiy
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        23-Oct-2018        Initial Development
*             Himanshu                      29-Mar-2022        Code Scan Fixes
*             Rishab Wali                   22-July-2022       Using partial Update instead of allornone 
*             Saddam                        08-Dec-2022        Codescan Fix , Varaible naming convention. 
*             Deep Diwakar                  Sept-01-2023       CMCM-1201: Updated batch job bypass from profile to user and added instrumentation
*    ------------------------------------------------------------------------------------ 
*                    
*/

public class BatchUpdateContactStatusForOpenOpp extends ilib_ScheduleAndBatch implements Schedulable {
    
    public static final string STRING_OPPORTUNITY_STAGE_CLOSED_LOST='Closed Lost';
    public static final string STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED='Closed Abandoned';
    public static final string STRING_OPEN_OPPORTUNITY='Open Opportunity';
    public static final string STRING_OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    public static final string STRING_CONTACT_OPEN_OPPORTUNITY='Open Opportunity';
    public static final string STRING_CONTACT_STATUS_RECYCLED='Recycled';
    public static final string STRING_CONTACT_STATUS_NEW='New';
    public static final string STRING_CONTACT_STATUS_INQUIRY='Inquiry';
    public static final string STRING_CONTACT_STATUS_AQ='Automation Qualified';
    public static final string STRING_CONTACT_STATUS_MQ='Marketing Qualified';
    public static final string STRING_CONTACT_STATUS_DATA_CHECK='Data Check';
    public static final string STRING_CONTACT_STATUS_VALIDATED='Validated';
    public static final string STRING_CONTACT_STATUS_ACCEPTED='Accepted';
    public static final string STRING_CONTACT_STATUS_NO_OPP='Lead Converted No Opp';
    private static final String LOG_TITLE = 'BatchUpdateContactStatusForOpenOpp';
    
    /**
     *  @author  Pankaj Singla
     *  @description execute method to be called when class is scheduled
     *  @paramter- schedule context
     **/
     
    public override void execute(SchedulableContext ctx) {
        BatchUpdateContactStatusForOpenOpp objBatch=new BatchUpdateContactStatusForOpenOpp();
        Database.executebatch(objBatch);
    
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description start method for the batch job
     *  @paramter- schedule context
     **/
     
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        /*Fetch the list of all contact records which are associated to Opportunities which are not closed*/
        Set<String> setClosedOpportunityStatusString=new Set<String>{STRING_OPPORTUNITY_STAGE_CLOSED_LOST,STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED,
            STRING_OPPORTUNITY_STAGE_CLOSED_WON};
        Set<String> setContactMarketingStatus=new Set<String>{STRING_CONTACT_STATUS_RECYCLED,STRING_CONTACT_STATUS_NEW,STRING_CONTACT_STATUS_INQUIRY,STRING_CONTACT_STATUS_AQ,STRING_CONTACT_STATUS_MQ,STRING_CONTACT_STATUS_DATA_CHECK,STRING_CONTACT_STATUS_VALIDATED,STRING_CONTACT_STATUS_ACCEPTED,STRING_CONTACT_STATUS_NO_OPP};
        
        String strSoql = 'SELECT ContactId,contact.Marketing_Contact_Status__c,OpportunityId,opportunity.StageName FROM OpportunityContactRole ' +
                        ' where  contact.Marketing_Contact_Status__c!=:STRING_CONTACT_OPEN_OPPORTUNITY ' +
                        ' and opportunity.StageName not in :setClosedOpportunityStatusString '+
                        'and contact.Marketing_Contact_Status__c in :setContactMarketingStatus';
        
             
        return Database.getQueryLocator(strSoql);
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description execute  method for the batch job
     *  @paramter- schedule context, list of 
     **/
    public override void execute(Database.BatchableContext bc, List<sObject> lstOppContactRole) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        Set<Id> setContactIDs=new Set<Id>();
        List<Contact> lstContact=new List<Contact>();
        Contact objContact;
        for (OpportunityContactRole objOpportunityContactRole:(List<OpportunityContactRole>)lstOppContactRole) {
            if (!setContactIDs.contains(objOpportunityContactRole.ContactId)) {
                objContact=new Contact(id=objOpportunityContactRole.ContactId);
                objContact.Marketing_Contact_Status__c=STRING_CONTACT_OPEN_OPPORTUNITY;
                objContact.Is_Recycled__c=false;
                lstContact.add(objContact);
                setContactIDs.add(objOpportunityContactRole.ContactId);
            }  
        }

        ilib_LogEvent.info('lstContact size: ' + lstContact.size());
        if (!lstContact.isEmpty() && Schema.sObjectType.cs_Apex_Settings__c.isUpdateable() && Schema.sObjectType.cs_Apex_Settings__c.isCreateable()) {
          cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();
          objApexSettings.Bypass_All_Validations__c=true;
          upsert objApexSettings cs_Apex_Settings__c.Id;
          List<Database.SaveResult> results = Database.update(lstContact, false);
          // log errors, if any
          ApexExceptions.emitSaveErrors(results, LOG_TITLE);
          objApexSettings.Bypass_All_Validations__c=false;
          upsert objApexSettings cs_Apex_Settings__c.Id;
        } else {
          ilib_LogEvent.info('User does not have create and update permission on custom setting - Apex Settings');
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
         
    }
    
    /**
    * @author Pankaj
    * @date   23-Oct-2018   
    * @description   Overriding finish method for batch
    * @params Database.BatchableContext bc
    * @return void
    */
     public override void finish(Database.BatchableContext bc){
     
     
     }

}
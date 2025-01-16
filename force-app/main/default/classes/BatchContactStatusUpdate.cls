/**
*    @author: Pankaj 
*    @date:   16-Jan-2019
*    @description:  Batch Class to update Contact Status Based on Contact Score
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        16-Jan-2019        Initial Development
*             Pankaj                        24-Jan-2020        DCP-31617 Changes  
*            Deep Diwakar                   Sept-01-2023       CMCM-1201: Updated batch job bypass from profile to user and added instrumentation
*            Deep Diwakar                   Nov-28-2024        CMCM-12570: Updated batch job to include Hand Raise status

        BatchContactStatusUpdate objBatch=new BatchContactStatusUpdate();
        String sch='0 0 * * * ? *';
        String sch2='0 30 * * * ? *';
        System.schedule('BatchContactStatusUpdate', sch , objBatch);
        System.schedule('BatchContactStatusUpdate2', sch2 , objBatch);
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class BatchContactStatusUpdate extends ilib_ScheduleAndBatch {

    public static final Integer INT_MIN_CONTACT_SCORE_INQUIRY = 19;
    public static final Integer INT_MAX_CONTACT_SCORE_INQUIRY = 50;
    public static final Integer INT_MIN_CONTACT_SCORE_AQ = 49;

    public static final String STRING_CONTACT_STATUS_NEW = 'New';
    public static final String STRING_CONTACT_STATUS_RECYCLED = 'Recycled';
    public static final String STRING_CONTACT_STATUS_INQUIRY = 'Inquiry';
    public static final String STRING_CONTACT_STATUS_AQ = 'Automation Qualified';
    public static final String STRING_CONTACT_STATUS_MQ = 'Marketing Qualified';   
    public static final String STRING_DISPOSITION_CODE='Auto-Recycle Marketing Suppression';
    public static final String STRING_OPEN_OPPORTUNITY='Open Opportunity';
    public static final String STRING_LEAD_NO_OPP='Lead Converted No Opp';
    public Datetime dtCutoffTime = Datetime.now().addminutes(-60);
    public Datetime dtToday = System.Today();

    private static final String LOG_TITLE = 'BatchContactStatusUpdate';  

    private static final String STRING_CONTACT_STATUS_HAND_RAISE = 'Hand Raise';

    /*Start method of Batch Class*/
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch all the Contacts such that either Contact Me Requested Date or Date of Last Score Change is updated in the last 60 minutes
        /*Updating the query to include Contacts whose status has been updated as MQ/AQ/Inquiry and Marketing Suppression is true 
        Adding is_Recycled check*/
        String strSoql='SELECT Id, Marketing_Contact_Status__c, pi__score__c, Contact_Me_Requested_Date__c, Date_Of_Last_Score_Change__c, LastModifiedDate,Contact_Me_Date_Elapsed_Days__c,Marketing_Suppression__c,Contact_Me__c,Disposition_Code__c,Is_Recycled__c,Marketing_Score__c,Job_Function__c FROM Contact WHERE (Contact_Me__c=true OR Date_Of_Last_Score_Change__c >= :dtCutoffTime OR Marketing_Suppression__c=true)';
        strSOQL=String.escapeSingleQuotes(strSOQL);     
        return Database.getQueryLocator(strSOQL);
    }
    
    /*Execute method for Schedulable Context*/
    public override void execute(SchedulableContext sc) {
        BatchContactStatusUpdate b = new BatchContactStatusUpdate();
        Database.executebatch(b);
    }
    
    /*Execute method of Batch Class*/
    public override void execute (Database.BatchableContext bc, List<SObject> scope) {

        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        List<Contact> lstContact=new List<Contact>();
        Set <String> setContactStatusNewRecycled = new Set<String>{STRING_CONTACT_STATUS_NEW, STRING_CONTACT_STATUS_RECYCLED};
        Set <String> setContactStatusNewRecycledInquiry = new Set<String>{STRING_CONTACT_STATUS_NEW, STRING_CONTACT_STATUS_RECYCLED, STRING_CONTACT_STATUS_INQUIRY};
        Set <String> setContactStatusNewRecycledInquiryAQ = new Set<String>{STRING_CONTACT_STATUS_NEW, STRING_CONTACT_STATUS_RECYCLED,STRING_CONTACT_STATUS_INQUIRY, STRING_CONTACT_STATUS_AQ};
        
        for (Contact objContact : (List<Contact>)scope) {
            if(objContact.Marketing_Suppression__c==true && objContact.Marketing_Contact_Status__c!=STRING_CONTACT_STATUS_RECYCLED && objContact.Marketing_Contact_Status__c!=STRING_OPEN_OPPORTUNITY){
                objContact.Marketing_Contact_Status__c=STRING_CONTACT_STATUS_RECYCLED;
                objContact.Disposition_Code__c=STRING_DISPOSITION_CODE;
                objContact.Is_Recycled__c=true;
                lstContact.add(objContact);
            }
            
            if(objContact.Marketing_Suppression__c!=true && objContact.Is_Recycled__c!=true){
                    //Set Status as MQ if Contact me is true
                    if(objContact.Contact_Me__c==true && setContactStatusNewRecycledInquiryAQ.contains(objContact.Marketing_Contact_Status__c)){
                        // CMCM-12363: Setting status to Hand Raise instead of MQ
                        objContact.Marketing_Contact_Status__c = STRING_CONTACT_STATUS_HAND_RAISE;
                        lstContact.add(objContact);
                    }
                    // Set status as Inquiry if score is above threshold limit for Inquiry
                    else if(objContact.Date_Of_Last_Score_Change__c >= dtCutoffTime && objContact.Marketing_Score__c > INT_MIN_CONTACT_SCORE_INQUIRY && objContact.Marketing_Score__c < INT_MAX_CONTACT_SCORE_INQUIRY && setContactStatusNewRecycled.contains(objContact.Marketing_Contact_Status__c)){
                         objContact.Marketing_Contact_Status__c = STRING_CONTACT_STATUS_INQUIRY;
                         lstContact.add(objContact);
                    }
                    // Set Status as AQ if score is above threshold limit for AQ
                    else if(objContact.Date_Of_Last_Score_Change__c >= dtCutoffTime && objContact.Marketing_Score__c > INT_MIN_CONTACT_SCORE_AQ && setContactStatusNewRecycledInquiry.contains(objContact.Marketing_Contact_Status__c)){
                        objContact.Marketing_Contact_Status__c = STRING_CONTACT_STATUS_AQ;
                        lstContact.add(objContact);
                    }
            }
        }

        ilib_LogEvent.info('lstContact size: ' + lstContact.size());

        // Allow Partial update so not to block the entire batch job for Validation Errors on Contact
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

    /*Finish method of Batch Class*/
    public override void finish(Database.BatchableContext bc) {
        /*This is mandatory method for batchable interface*/
    }

}
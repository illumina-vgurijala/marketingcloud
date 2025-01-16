/**
*    @author: Pankaj 
*    @date:   16-Jan-2019
*    @description:  Batch Class to update Lead status Based on Lead Score
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        16-Jan-2019        Initial Development
*             Pankaj                        30-Mar-2020        Updated Default Dispostion Code-DCP-36530  
*            Deep Diwakar                   Sept-01-2023       CMCM-1201: Updated batch job bypass from profile to user and added instrumentation 
*            Deep Diwakar                   Nov-27-2024        CMCM-12570: Updated batch job to include Hand Raise status

        BatchLeadStatusUpdate objBatch=new BatchLeadStatusUpdate();
        String sch='0 0 * * * ? *';
        String sch2='0 30 * * * ? *';
        System.schedule('BatchLeadStatusUpdate', sch , objBatch);
        System.schedule('BatchLeadStatusUpdate2', sch2 , objBatch);
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class BatchLeadStatusUpdate extends ilib_ScheduleAndBatch {

    public static final Integer INT_MIN_LEAD_SCORE_INQUIRY = 19;
    public static final Integer INT_MAX_LEAD_SCORE_INQUIRY = 50;
    public static final Integer INT_MIN_LEAD_SCORE_AQ = 49;

    public static final String STRING_LEAD_STATUS_NEW = 'New';
    public static final String STRING_LEAD_STATUS_RECYCLED = 'Recycled';
    public static final String STRING_LEAD_STATUS_INQUIRY = 'Inquiry';
    public static final String STRING_LEAD_STATUS_AQ = 'Automation Qualified';
    public static final String STRING_LEAD_STATUS_MQ = 'Marketing Qualified';
    public static final String STRING_DISPOSITION_CODE='Auto-Recycle Marketing Suppression';
    private static final String LOG_TITLE = 'BatchLeadStatusUpdate';  

    private static final String STRING_LEAD_STATUS_HAND_RAISE = 'Hand Raise';

    public Datetime dtCutoffTime = Datetime.now().addminutes(-60);
    public Datetime dtToday = System.Today();

    /*Start method of Batch Class*/
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        // Fetch all the Leads such that either Contact Me Requested Date or Date of Last Score Change is updated in the last 30 minutes
        /*Updating the query to fetch leads whose status has been updated as MQ/AQ/Inquiry and Marketing Suppression is true*/
        String strSoql='SELECT Id, Status, pi__score__c, Contact_Me_Requested_Date__c, Date_Of_Last_Score_Change__c,Job_Function__c, LastModifiedDate,Contact_Me_Date_Elapsed_Days__c,Marketing_Suppression__c,Contact_Me__c,Disposition_Code__c,Is_Recycled__c,Marketing_Score__c FROM Lead WHERE (Contact_Me__c=true or Date_Of_Last_Score_Change__c >= :dtCutoffTime OR Marketing_Suppression__c=true) AND IsConverted = false';
        strSOQL=String.escapeSingleQuotes(strSOQL);
        return Database.getQueryLocator(strSOQL);
    }

    /*Execute method for Schedulable Context*/
    public override void execute(SchedulableContext sc)
    {
        Database.executeBatch(new BatchLeadStatusUpdate());
    }
    
    /*Execute method of Batch Class*/
    public override void execute (Database.BatchableContext bc, List<SObject> scope) {

        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        List<Lead> lstLead = new List<Lead>();
        Set <String> setLeadStatusNewRecycled = new Set<String>{STRING_LEAD_STATUS_NEW, STRING_LEAD_STATUS_RECYCLED};
        Set <String> setLeadStatusNewRecycledInquiry = new Set<String>{STRING_LEAD_STATUS_NEW, STRING_LEAD_STATUS_RECYCLED, STRING_LEAD_STATUS_INQUIRY};
        Set <String> setLeadStatusNewRecycledInquiryAQ = new Set<String>{STRING_LEAD_STATUS_NEW, STRING_LEAD_STATUS_RECYCLED, STRING_LEAD_STATUS_INQUIRY, STRING_LEAD_STATUS_AQ};

        for (Lead objLead : (List<Lead>)scope)
        {
            system.debug('Processing-'+objLead.Marketing_Score__c);
            // Recycle the lead if the Marketing Suppression is set to true
            if(objLead.Marketing_Suppression__c!=null && objLead.Marketing_Suppression__c==true && objLead.status!=STRING_LEAD_STATUS_RECYCLED){
                objLead.status=STRING_LEAD_STATUS_RECYCLED;
                objLead.Disposition_Code__c=STRING_DISPOSITION_CODE;
                objLead.Is_Recycled__c=true;
                lstLead.add(objLead);
            }
            
            if(objLead.Marketing_Suppression__c!=true && objLead.Is_Recycled__c!=true){
                //Set Status as MQ if Contact me is true
              	if(objLead.Contact_Me__c==true && setLeadStatusNewRecycledInquiryAQ.contains(objLead.status)){
                    // CMCM-12363: Setting status to Hand Raise instead of MQ
                    objLead.status = STRING_LEAD_STATUS_HAND_RAISE;
                    lstLead.add(objLead);
                }
                else if(objLead.Date_Of_Last_Score_Change__c >= dtCutoffTime && objLead.Marketing_Score__c > INT_MIN_LEAD_SCORE_INQUIRY && objLead.Marketing_Score__c < INT_MAX_LEAD_SCORE_INQUIRY && setLeadStatusNewRecycled.contains(objLead.status)){
                    // Set status as Inquiry if score is above threshold limit for Inquiry
                    objLead.status=STRING_LEAD_STATUS_INQUIRY;
                    lstLead.add(objLead);
                }
                else if(objLead.Date_Of_Last_Score_Change__c >= dtCutoffTime && objLead.Marketing_Score__c > INT_MIN_LEAD_SCORE_AQ && setLeadStatusNewRecycledInquiry.contains(objLead.status)){
                    // Set Status as AQ if score is above threshold limit for AQ
                    objLead.status=STRING_LEAD_STATUS_AQ;
                    lstLead.add(objLead);
                }
            }
        }

        ilib_LogEvent.info('lstLead size: ' + lstLead.size());

        // Allow Partial update so not to block the entire batch job for Validation Errors on Lead
        if (!lstLead.isEmpty() && Schema.sObjectType.cs_Apex_Settings__c.isUpdateable() && Schema.sObjectType.cs_Apex_Settings__c.isCreateable()) {
          cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();
          objApexSettings.Bypass_All_Validations__c=true;
          upsert objApexSettings cs_Apex_Settings__c.Id;
          List<Database.SaveResult> results = Database.update(lstLead, false);
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
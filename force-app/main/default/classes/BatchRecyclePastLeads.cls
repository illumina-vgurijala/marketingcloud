/**
*    @author: Pankaj 
*    @date:   04-March-2020
*    @description:  BatchRecyclePastLeads-DCP-34980 Batch Class to Auto Recycle Leads if status is not
                                        updated in last 45(configurable) days 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Pankaj Singla                 04-March-2020        Initial Build
*            Deep Diwakar                  Sept-01-2023         CMCM-1201: Updated batch job bypass from profile to user and added instrumentation
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class BatchRecyclePastLeads extends ilib_ScheduleAndBatch {

    
    public static final String STRING_LEAD_STATUS_NEW = 'New';
    public static final String STRING_LEAD_STATUS_RECYCLED = 'Recycled';
    public static final String STRING_LEAD_STATUS_INQUIRY = 'Inquiry';
    public static final String STRING_LEAD_STATUS_AQ = 'Automation Qualified';
    public static final String STRING_DISPOSITION_CODE='Auto-Recycle Stale Status';
    public Integer intRecycleDays=Integer.ValueOf(Label.ProspectRecycleDays);
    public Date dtDueDate=Date.Today().AddDays(-intRecycleDays);    
    private static final String LOG_TITLE = 'BatchRecyclePastLeads'; 

    /*Start method of Batch Class */
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        /*Since test class would create data, it is not possible to created date in past
        So using due date as future date */
        if(Test.isRunningTest()) {
              dtDueDate=Date.Today().AddDays(2);
        }
        Set<String> setStatuses=new Set<String>{STRING_LEAD_STATUS_NEW,STRING_LEAD_STATUS_INQUIRY,STRING_LEAD_STATUS_AQ};
        
        String strSoql='Select id,Status,Date_Status_Set_As_Inquiry__c,Date_Status_Set_As_Marketing_Qualified__c,Date_Status_Set_As_Automation_Qualified__c,Date_Of_Last_Status_Change__c,CreatedDate,lastmodifiedDate,pi__score__c,Marketing_Score__c,Date_Of_Last_Score_Change__c from lead where (Date_Status_Set_As_Inquiry__c<:dtDueDate or Date_Status_Set_As_Automation_Qualified__c<:dtDueDate or Date_Of_Last_Score_Change__c<:dtDueDate) and status in :setStatuses and isconverted=false'; 
        
         return Database.getQueryLocator(strSOQL); 
     
     }
     
      /*Execute method of Schedulable Context */
      public override void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchRecyclePastLeads());
      }
      
      /*Execute method of Batch Class */
      public override void execute (Database.BatchableContext bc, List<SObject> scope) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

          /*Since test class would create data, it is not possible to created date in past
            So using due date as future date */
          if(Test.isRunningTest()) {
              dtDueDate=Date.Today().AddDays(2);
          }
           List<Lead> lstLead=new List<Lead>();
           for (Lead objLead : (List<Lead>)scope) {
               /*If status is new check for created date.*/
              if(objLead.status.equals(STRING_LEAD_STATUS_NEW) &&  objLead.Date_Of_Last_Score_Change__c <dtDueDate && objLead.Marketing_Score__c>0) {
                objLead.Status=STRING_LEAD_STATUS_RECYCLED;
                objLead.Disposition_Code__c=STRING_DISPOSITION_CODE;
                lstLead.add(objLead);  
              }
              else if (objLead.status.equals(STRING_LEAD_STATUS_INQUIRY) &&  objLead.Date_Status_Set_As_Inquiry__c<dtDueDate) {
                  objLead.Status=STRING_LEAD_STATUS_RECYCLED;
                  objLead.Disposition_Code__c=STRING_DISPOSITION_CODE;
                  lstLead.add(objLead);  
              }
              else if (objLead.status.equals(STRING_LEAD_STATUS_AQ) &&  objLead.Date_Status_Set_As_Automation_Qualified__c<dtDueDate){
                 objLead.Status=STRING_LEAD_STATUS_RECYCLED;
                 objLead.Disposition_Code__c=STRING_DISPOSITION_CODE;
                 lstLead.add(objLead);   
              }
           }

          ilib_LogEvent.info('lstLead size: ' + lstLead.size());
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
      
       /*Finish method of Batch Class */ 
       public override void finish(Database.BatchableContext bc) {
           system.debug('The job is finished----');
       }
     

}
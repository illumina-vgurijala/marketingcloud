/**
*    @author: Pankaj 
*    @date:   24-Jan-2019
*    @description:  Batch Class to update Contact Marketing status to Recycled if the contact is no longer associated to Open Opp
     BatchUpdateContactStatusOppDissociation objBatch=new BatchUpdateContactStatusOppDissociation();
        String sch='0 0 1 * * ? *';
       
        System.schedule('BatchUpdateContactStatusOppDissociation', sch , objBatch);
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        24-Jan-2019        Initial Development
*			        Rishab Wali                   22-July-2022       Updating partial update instead of allornone
*             Deep Diwakar                  Sept-01-2023       CMCM-1201: Updated batch job bypass from profile to user and added instrumentation
*             Deep Diwakar                  Dec-18-2024        CMCM-12362: Updated class to add new disposition code value
*    ------------------------------------------------------------------------------------ 
*                    
*/
global class BatchUpdateContactStatusOppDissociation extends ilib_ScheduleAndBatch{
    global static final string STRING_OPEN_OPPORTUNITY='Open Opportunity';
    public static final string STRING_OPPORTUNITY_STAGE_CLOSED_LOST='Closed Lost';
    public static final string STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED='Closed Abandoned';
    public static final string STRING_OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    public static final string STRING_RECYCLED='Recycled';
    public static final string STRING_DISPOSITION_CODE='No need';
    private static final String LOG_TITLE = 'BatchUpdateContactStatusForOpenOpp';
     
    /**Start method of Batch Class */
    global override Database.QueryLocator start(Database.BatchableContext bc) {
         return Database.getQueryLocator('Select id,Marketing_Contact_Status__c,pi__score__c,Is_Recycled__c From Contact where Marketing_Contact_Status__c=:STRING_OPEN_OPPORTUNITY');
    }
      /**Execute method of Schedulable Context */
    global override void execute(SchedulableContext sc) {
          BatchUpdateContactStatusOppDissociation objBatch=new BatchUpdateContactStatusOppDissociation();
          Database.executebatch(objBatch);
    }

    /**Execute method of Batch Class */
    global override void execute (Database.BatchableContext bc, List<SObject> scope) {
      ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
      ilib_LogEvent.push(LOG_TITLE + '.execute()'); 

      Set<Id> setContactIds=new Set<Id>();
      list<Contact> lstUpdateContactRecords=new list<contact>();
      set<string> setClosedOpportunityStatusString=new set<string>{STRING_OPPORTUNITY_STAGE_CLOSED_LOST,STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED,
      STRING_OPPORTUNITY_STAGE_CLOSED_WON};
      for(Contact objContact:(List<Contact>)scope) {
        setContactIds.add(objContact.id);
      }
      
      for(OpportunityContactRole objOpportunityContactRole: new OpportunityContactRoleSelector().selectValidContactOppAssociations(setContactIds,setClosedOpportunityStatusString)) {
        setContactIds.remove(objOpportunityContactRole.ContactId);       
      }
      
      for(id idContactid:setContactIds){
        Contact objCon=new Contact(id=idContactid);
        objCon.Marketing_Contact_Status__c=STRING_RECYCLED;
        objCon.Disposition_Code__c=STRING_DISPOSITION_CODE;
        objCon.Is_Recycled__c=true;
        lstUpdateContactRecords.add(objCon);
      }
      
      ilib_LogEvent.info('lstUpdateContactRecords size: ' + lstUpdateContactRecords.size());
      if (!lstUpdateContactRecords.isEmpty() && Schema.sObjectType.cs_Apex_Settings__c.isUpdateable() && Schema.sObjectType.cs_Apex_Settings__c.isCreateable()) {
        cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();
        objApexSettings.Bypass_All_Validations__c=true;
        upsert objApexSettings cs_Apex_Settings__c.Id;
        List<Database.SaveResult> results = Database.update(lstUpdateContactRecords, false);
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
      /**Finish method of Batch class */
      global override void finish(Database.BatchableContext bc){
      system.debug('Finish method completed');
    }
}
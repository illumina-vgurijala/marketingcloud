/**
 *    @author Gautam Arya
 *    @date   2021-03-30
 *    @description    
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *             Developer                      Date                Description
*              
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class NotificationDetailsSelector extends ilib_SObjectSelector
{
    public static final String SETUP_NOTIFICATION_DETAIL = CaseChangeEvents.SETUP_NOTIFICATION_DETAIL;
    /**
     *  @author  Gautam Arya 
     *  @description Retrieve list of fields for Notification Detail sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
        Notification_Detail__c.id,
        Notification_Detail__c.Is_Instant_Notification__c, 
        Notification_Detail__c.MS_Teams_Recipient__c,
        Notification_Detail__c.Trigger_Notification_After_in_HRS__c,
        Notification_Detail__c.Notification_Template__c,
        Notification_Detail__c.Region__c,
        Notification_Detail__c.Send_Only_During_Office_Hours__c,
        Notification_Detail__c.Rule_Syntax__c,
        Notification_Detail__c.User_Group__c,
        Notification_Detail__c.Is_Active__c,
        Notification_Detail__c.Recipient_Name__c,
        Notification_Detail__c.Send_Only_After_Hours__c,
        Notification_Detail__c.Impacted_Fields__c
           
       };
    }
	
	/**
    *  @author Gautam Arya 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Notification Detail
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Notification_Detail__c.sObjectType;
   }
    
    
    /**
     *  @author Gautam Arya
     *  @description Select the records without any condition
	 *  Returns return specific Notification Detail Record
     **/
     
    public List<Notification_Detail__c> selectAllActiveRecords()
    {
        return (List<Notification_Detail__c>) Database.query(
                newQueryFactory()
                .setCondition('Is_Active__c = TRUE')
                .toSOQL());
    }

    /**
     *  @author Gautam Arya
     *  @description Select the records based on name
	 *  Returns specific Notification Detail Record
     **/
     
    public Notification_Detail__c getSetUpNotificationDetail()
    {
        return (Notification_Detail__c) Database.query(
                newQueryFactory().setCondition('Name =: SETUP_NOTIFICATION_DETAIL').toSOQL());
    }

    
}
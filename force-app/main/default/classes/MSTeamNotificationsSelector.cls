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
public with sharing class MSTeamNotificationsSelector extends ilib_SObjectSelector
{
    
    /**
     *  @author  Gautam Arya 
     *  @description Retrieve list of fields for MS Team Notification sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           MS_Team_Notification__c.id,
           MS_Team_Notification__c.Case__c, 
           MS_Team_Notification__c.Notification_Detail__c,
           MS_Team_Notification__c.Notification_Eligible__c,
           MS_Team_Notification__c.IsActive__c

       };
    }
	
	/**
    *  @author Gautam Arya 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the MS Team Notification
    **/
   public Schema.SObjectType getSObjectType()
   {
        return MS_Team_Notification__c.sObjectType;
   }
    
    
    /**
     *  @author Gautam Arya
     *  @description Select by caseid and IsActive
	 *  Returns return specific MS Team Notification Record
     **/
     
    public List<MS_Team_Notification__c> selectByCaseAndActive(Set<String> idCaseids)
    {
        return (List<MS_Team_Notification__c>) Database.query(
                newQueryFactory().setCondition('IsActive__c = TRUE and Case__c IN: idCaseids').toSOQL());
    }

    
}
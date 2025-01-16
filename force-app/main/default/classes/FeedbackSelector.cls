/**
 *    @author Anisha Bharti
 *    @date   19-Nov-2020
 *    @description : Feedback Selector class
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *  
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class FeedbackSelector extends ilib_SObjectSelector{
    /**
    *  @author Anisha
    *  @description Method to fetch Feedback fields
    *  @param none
    *  @return List
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {   
        return new List<Schema.SObjectField> {
            
            Feedback__c.id,
            Feedback__c.Name,
            Feedback__c.ownerid,
            Feedback__c.Feedback_Owner__c,
            Feedback__c.createdById
        };
    }

     /**
    *  @author Anisha
    *  @description Method to fetch sobjecttyhpe of feedback
    *  @param none
    *  @return SObjectType The Schema.SObjectType of Feedback
    **/
    public Schema.SObjectType getSObjectType()
    { 
        return Feedback__c.sObjectType;
    }
    
    /**
    *  @author Anisha
    *  @param Set<Id>
    *  @return List
    **/
    public List<Feedback__c> getFeedbackByIds(Set<ID> setIds)
    {
        return (List<Feedback__c>)Database.query(newQueryFactory().setCondition('ID IN :setIds').toSOQL());
    }
}
/**
*    @author Satya Swain
*    @date   2018-07-22
*    @description    DCP-2433: OpportunityLineItems Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Satya Swain                   22 July 2018        KnownErrorNotifications Selector Class
*             Aman Tyagi                    31 March 2022       CodeScan Fixes
*    ------------------------------------------------------------------------------------
*/
public with sharing class KnownErrorNotificationsSelector extends ilib_SObjectSelector{

    /*
    * @Author: Satya Swain
    * @Description : method for getting the sObject type
    * @param :null
    * @return: Schema.SObjectType
    */ 
    public Schema.SObjectType getSObjectType(){
        return Known_Error_Notification__c.sObjectType;
    }

    /*
    * @Author: Satya Swain
    * @Description : method for getting the sObject field list
    * @param :null
    * @return: List<Schema.SObjectField> 
    */ 
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Known_Error_Notification__c.Id,
            Known_Error_Notification__c.Name,
            Known_Error_Notification__c.LastModifiedById,
            Known_Error_Notification__c.Message__c,
            Known_Error_Notification__c.Notification_Type__c,
            Known_Error_Notification__c.Pattern__c,
            Known_Error_Notification__c.Recipients__c,
            Known_Error_Notification__c.Source__c
        };
    }

    /*
    * @Author: Satya Swain
    * @Description : method for selecting the known errors based on source
    * @param :String source
    * @return: List<Known_Error_Notification__c> 
    */
    public List<Known_Error_Notification__c> selectKnownErrorsBySource(String source)
    {
        String strQuery = newQueryFactory().setCondition('Source__c = :source').toSOQL();
        System.debug('@@@@ Inside selectKnownErrorsBySource query: ' + strQuery);
        return (List<Known_Error_Notification__c>) Database.query(strQuery);
    }

    // public List<Known_Error_Notification__c> selectKnownErrorsById(Set<Id> recordIds)
    // {
    //     String strQuery =  newQueryFactory().setCondition('Id IN :recordIds').toSOQL(); 
    //     System.debug('@@@@ Inside selectKnownErrorsById query: ' + strQuery);
    //     return (List<Known_Error_Notification__c>) Database.query(strQuery);
    // }

}
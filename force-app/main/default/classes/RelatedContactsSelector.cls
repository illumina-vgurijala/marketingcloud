/**
*    @author Digvijay SIngh
*    @date   2020-02-14
*    @description    DCP-33450: RelatedContactSelector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Digvijay                   14/02/2020          Initial Version
*             Rohan Rathod               17/01/2022            Added selector using WO ID
*             Aman Tyagi                 31 March 2022       Codescan Fixes
*             Rohan Rathod               08/06/2022          Elevation Members By Category
*             Gladis                     22-Sep-2022         Added Query Instrumentation
*     ------------------------------------------------------------------------------------ 
*                    
*/


public with sharing class RelatedContactsSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'RelatedContactsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';


    /*
    * @Author: Digvijay 
    * @Description : method to get the sObject type
    * @param :null
    */
    public Schema.SObjectType getSObjectType()
    {
        return Related_Contacts__c.sObjectType;
    }
    
    /**
    *  @author  Digvijay
    *  @description Retrieve list of fields for Related_Contacts__cObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Related_Contacts__c.id,
            Related_Contacts__c.Contact__c,
            Related_Contacts__c.OwnerId
            

        }; 
            
    }
    
    /*
    * @Author: Digvijay 
    * @Description : method for selecting list of related contacts
    * @param :Set<Id> setd
    * @return: List<Related_Contacts__c>
    */
    public List<Related_Contacts__c> selectRelatedContact(Set<Id> setd) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectRelatedContact', UtilsCollection.serializeIds(setd));
        }
        List<Related_Contacts__c> lstRelatedContact = (List<Related_Contacts__c>) Database.query(
                                    newQueryFactory().setCondition('Related_Contacts__c.Id IN :setd').toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(lstRelatedContact.size());
        }
        return lstRelatedContact;
    }   

 
 /**
    * @description Retrieve Related contacts based on WO Id
    * @author Rohan Rathod 
    * @param setWOId 
    * @return List<Related_Contacts__c> 
    **/
    public List<Related_Contacts__c> selectRelatedContactByWOId(Set<Id> setWOId){
        ilib_LogQuery logger=null;
       
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectRelatedContactByWOId', UtilsCollection.serializeIds(setWOId));
        }
        String strQuery = newQueryFactory()
            .selectField('Name')
            .selectField('Contact_Name__c')
            .selectField('User_Name__c')
            .selectField('Contact__c')
            .selectField('User__c')
            .selectField('Elevated_Work_Order__c')
            .selectField('Type__c')
            .selectField('Title__c')
            .selectField('Email__c')
            .selectField('Representative__c')
            .setCondition('Elevated_Work_Order__c =: setWOId') 
            .toSOQL();
            
        List<Related_Contacts__c> lstRelatedContact = (List<Related_Contacts__c>) Database.query(strQuery);
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(lstRelatedContact.size());
        }
        return lstRelatedContact;
    }
/**
    * @description Retrieve Related contacts based on WO Id
    * @author Prerna 
    * @param setWOId 
    * @return List<Related_Contacts__c> 
    **/
    public List<Related_Contacts__c> selectAddElevationMembersByWOId(Set<Id> setWOId, String watcherType){
        ilib_LogQuery logger=null;
       
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAddElevationMembersByWOId', UtilsCollection.serializeIds(setWOId));
        }
        String strQuery = newQueryFactory()
            .selectField('Name')
            .selectField('Contact_Name__c')
            .selectField('User_Name__c')
            .selectField('Contact__c')
            .selectField('User__c')
            .selectField('Elevated_Work_Order__c')
            .selectField('Type__c')
            .selectField('Title__c')
            .selectField('Email__c')
            .selectField('Representative__c')
            .setCondition('Elevated_Work_Order__c =: setWOId AND Type__c includes ' + watcherType)
            .toSOQL();
        
        List<Related_Contacts__c> lstRelatedContact = (List<Related_Contacts__c>) Database.query(strQuery);
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(lstRelatedContact.size());
        }
        return lstRelatedContact;
    }

     /**
    * @description Retrieve Related contacts based on WO Id for Elevation Validation
    * @author Rohan 
    * @param setWOId 
    * @return List<Related_Contacts__c> 
    **/
    public List<Related_Contacts__c> selectElevationMembersByCategory(Set<Id> setWOId){
        ilib_LogQuery logger=null;
       
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAddElevationMembersByWOId', UtilsCollection.serializeIds(setWOId));
        }
        String strQuery = newQueryFactory()
            .selectField('Name')
            .selectField('Elevated_Work_Order__c')
            .selectField('Type__c')
            .selectField('Elevated_Work_Order__r.Account_Elevation__c')  
            .setCondition('Elevated_Work_Order__c =: setWOId AND Elevated_Work_Order__c != null AND Elevated_Work_Order__r.Account_Elevation__c != null') //DCP-52224
            .toSOQL();
        
        List<Related_Contacts__c> lstRelatedContact = (List<Related_Contacts__c>) Database.query(strQuery);
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(lstRelatedContact.size());
        }
        return lstRelatedContact;
    }
 }
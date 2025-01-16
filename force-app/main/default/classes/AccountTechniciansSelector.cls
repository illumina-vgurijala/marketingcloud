/**
 *    @author Ritika Maheshwari
 *    @date   11-06-2018
 *    @description    Class to get the Account to technician records based on different conditions
 *    @TestClasses:  TestAccountTechniciansSelector
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *      Developer                      Date                Description
 *      Ritika                        11-June-2018               Initial Version
 *      Sandeep Ram Ch.                4-July-2018         Added selectRelatedAccountTechnicians method
 *      Chaarvi Sardana               11-Dec-2018          Added new field query in selectRelatedAccountTechnicians method
 *      Gladis                        22-Sep-2022          Added Query Instrumentation   
 * ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class AccountTechniciansSelector extends ilib_SObjectSelector
{   
    private static final string  LOG_TITLE = 'AccountTechniciansSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

   /**
    *  @author Ritika Maheshwari 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Account_to_Field_Support__c.sObjectType;
   }
    
    /**
     *  @author  Ritika Maheshwari 
     *  @description Retrieve list of fields for Account_Technician_Role__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {  
       return new List<Schema.SObjectField> {
           Account_to_Field_Support__c.Id, 
           Account_to_Field_Support__c.Name, 
           Account_to_Field_Support__c.Account__c, 
           Account_to_Field_Support__c.User_Role__c, 
           Account_to_Field_Support__c.User__c
		   
       };
    }
    
    /**
     *  @author Ritika Maheshwari
     *  @description Fetch Account_to_Field_Support__c records associated with the account 
     *  @param Parts order ids
     *  @param case ids
     *  @return pasrt orders which are not delivered
     **/
    /*public List<Case> selectRelatedAccountTechnicianRole(Set<String> setAccountId, Set<String> setRoleNames) 
    {
        return (List<Case>) Database.query(
            newQueryFactory().setCondition(' Account__c IN:setAccountId AND User_Role__c IN:setRoleNames').toSOQL()
        );
    }*/
    
    
     public List<Account_to_Field_Support__c> selectRelatedAccountTechnicians(Set<Id> setAccountId) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectRelatedAccountTechnicians', UtilsCollection.serializeIds(setAccountId));
        }

        List<Account_to_Field_Support__c> res = (List<Account_to_Field_Support__c>) Database.query(
            newQueryFactory().selectField('User__r.SVMXC__Email__c')
            .selectField('User__r.SVMXC__Salesforce_User__c')
            .selectField('User__r.SVMXC__Active__c')
            .selectField('Account__r.Account_Group__c')
            .setCondition('Account__c IN:setAccountId').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
	
    /*
    * @Description- Fetch Account_to_Field_Support__c records associated with the User
    * @param - Account_to_Field_Support__c Id
    * @return - Account_to_Field_Support__c
    */
	public List<Account_to_Field_Support__c> selectAccountTechnicians(Set<Id> setToTechnicianId)
    {
        //Set<String> setSelectedRoles = new Set<String>{Label.Field_Support_User_Role_Primary_FSE,Label.Field_Support_User_Role_Primary_FAS,Label.Field_Support_User_Role_FSM,Label.Field_Support_User_Role_FAM};
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAccountTechnicians', UtilsCollection.serializeIds(setToTechnicianId));
        }
        
        List<Account_to_Field_Support__c> res = (List<Account_to_Field_Support__c>) Database.query(
            newQueryFactory().selectField('User__r.SVMXC__Salesforce_User__c')
            .selectField('User__r.SVMXC__Active__c')
            .setCondition('User__c IN:setToTechnicianId').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    } 
}
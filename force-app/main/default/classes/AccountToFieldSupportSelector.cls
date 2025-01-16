/**
*    @author Akash Kumar
*    @date   2018-05-25
*    @description    DCP-758: AccountToFieldSupportSelector Class
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------
*     Developer                      Date                        Description
*     Akash Kumar                 25 September 2018            Account To FieldSupport Selector Class
*     KD                          2-June-2021                  DCP-38933 Added new method selectAccountToFieldSupportByAccountERPAndRole
*     Sagar Madkaikar             13-Sep-2021                  CMCP-22:Added Field Support User fields in SOQL of selectAccountToFieldSupportByAccountAndRole() method. 
*                                                              Added Query Instrumentation
*     Pooja Shalwadi              22-Sep-2022                  Added Query Instrumentation
*    ---------------------------------------------------------------------------------------------------- 
*                    
*/
public with sharing class AccountToFieldSupportSelector extends ilib_SObjectSelector {

    private static final String LOG_TITLE = 'AccountToFieldSupportSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';//CMCP-22

    /**
     *  @author 
     *  @description : Initialization of the Account_to_Field_Support__c object
     *  @return SObjectType The Schema.SObjectType of the proposal
     */
    public Schema.SObjectType getSObjectType()
    {
        return Account_to_Field_Support__c.sObjectType;
    }

     /**
     *  @author
     *  @description Retrieve list of fields for Account_to_Field_Support__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField>
       {
           Account_to_Field_Support__c.Id,
           Account_to_Field_Support__c.Account__c,
           Account_to_Field_Support__c.User_Role__c,
           Account_to_Field_Support__c.User__c
       };
    }

    /**
    * @description To return a List of Account_to_Field_Support__c based on Id set
    * @author 
    * @param idSet 
    * @return List<Account_to_Field_Support__c> 
    **/
    public List<Account_to_Field_Support__c> selectByIds(Set<Id> idSet)
    {
        return (List<Account_to_Field_Support__c>) selectSObjectsById(idSet);
    }
    
	/**
     *  @author Debanka Chakraborty
     *  @description Fetch federation id of the user
     **/
    public List<Account_to_Field_Support__c> selectAccountToFieldSupport(Set<Id> AccountIds) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.selectAccountToFieldSupport', UtilsCollection.serializeIds(AccountIds));
        }    
        List<Account_to_Field_Support__c> res = (List<Account_to_Field_Support__c>) Database.query(
                                     newQueryFactory().selectField('User_Role__c')
                                    .selectField('User__r.SVMXC__Active__c')
                                    .selectField('User__r.SVMXC__Salesforce_User__c')
                                    .selectField('Account__c')
                                    .selectField('User__r.SVMXC__Salesforce_User__r.FederationIdentifier')
                                    .selectField('User__r.SVMXC__Salesforce_User__r.Alias')
                                    .setCondition('Account__c IN :AccountIds').toSOQL());

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;    
        
    }
	
	/**
	*  @author Sravan
	*  @description DCP-40120: To fetch Account To Field Support records based on AccountId and Role Name
	**/
    public List<Account_to_Field_Support__c> selectAccountToFieldSupportByAccountAndRole(Set<Id> accountIds,Set<String> rolesNames) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAccountToFieldSupportByAccountAndRole', UtilsCollection.serializeIds(accountIds)+'|'+UtilsCollection.serializeIds(rolesNames));
        }
            List<Account_to_Field_Support__c> res = (List<Account_to_Field_Support__c>) Database.query(
            newQueryFactory().selectField('User_Role__c')
            .selectField('Salesforce_User_ID__c')
            .selectField('User__c')//CMCP-22
            .selectField('Account__c')
            .setCondition('Salesforce_User_ID__c!=null AND Salesforce_User_ID__c!=\'\' AND Account__c IN : accountIds AND User_Role__c IN : rolesNames').toSOQL());  
        
            if(Feature.isOn(SERVICE_QUERY_LOGS)) {
                logger.stop(res.size());
            }
           
        return res;     
    }
    /**
	*  @author KD
	*  @description : To fetch Account To Field Support records based on Account ERP and Role Name
	**/
    public List<Account_to_Field_Support__c> selectAccountToFieldSupportByAccountERPAndRole(Set<String> setAccountERP,Set<String> setRolesNames) 
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn('ServiceQueryLogs')) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectAccountToFieldSupportByAccountERPAndRole',
            UtilsCollection.serializeIds(setAccountERP)
        );
        String strQuery = newQueryFactory().selectField('User_Role__c')
            .selectField('Salesforce_User_ID__c')
            .selectField('Account__c')
            .setCondition('Salesforce_User_ID__c!=null AND Salesforce_User_ID__c!=\'\' AND Account__r.ERP_Customer_Id__c IN : setAccountERP AND User_Role__c IN : setRolesNames').toSOQL();       
        List<Account_to_Field_Support__c> res = (List<Account_to_Field_Support__c>) Database.query(strQuery);
        if (Feature.isOn('ServiceQueryLogs')) {
            logger.stop(res.size());
        }
        return res;
    }

}
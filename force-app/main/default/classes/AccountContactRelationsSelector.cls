/**
 *    @author Vaibhav Sirohi
 *    @date   20-Aug-2019
 *    @description   
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Vaibhav Sirohi              28-Aug-2019          Added getAcountContactRelationOfAccount().
 *    Saddam                      22-feb-22            Added Product_Notifications_Categories__c field,
 *    Saddam                      09-mar-22            Created new method getAcrWithContactByAccount(),PM-33 and PM-430
 *    Saddam                      21-Mar-22            Modified getAcrCountByAccount()
 *    Nesar Mohan                 2022-03-30           CodeScan Fix - Add code comments
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public class AccountContactRelationsSelector  extends ilib_SObjectSelector {

    private static final String LOG_TITLE = 'AccountContactRelationSelector';

    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /*
    *  @Author: Vaibhav Sirohi
    *  @Description: Method to retrieve the SObjectType of AccountContactRelation
    *  @Param: None
    *  @Return: Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType()
    {
        return AccountContactRelation.sObjectType;
    }

    /*
    *  @author  Vaibhav Sirohi
    *  @description Retrieve list of fields for AccountContactRelation Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    */

    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Key_Stakeholder_Analysis__c.id,
                AccountContactRelation.Roles,
                AccountContactRelation.AccountId,
                AccountContactRelation.ContactId,
                AccountContactRelation.IsActive,
                AccountContactRelation.Product_Notifications_Categories__c //pm-33
                }; 
                    }
    /*
    *  @author Vaibhav Sirohi
    *  @description Retrieve contact relation of the account
    *  @param three parameters of type String, set<Id> and Integer
    *  @return List<AccountContactRelation>
    */

    public List<AccountContactRelation> getAcountContactRelationOfAccount(String ultimateParentId, String ultimateParentName, String currentContactName, set<Id> contactId, Integer offset)
    {
        system.debug('currentContactName-->'+currentContactName);
        system.debug('ultimateParentId-->'+ultimateParentId);
        if(currentContactName != null &&  ultimateParentId == null){
            ilib_QueryFactory query = newQueryFactory();
            query.selectField('Contact.Name');
            query.selectField('Contact.FirstName');
            query.selectField('Account.Name');
            query.selectField('Contact.LastName');
            query.selectField('Contact.Region__c');
            query.selectField('Contact.Title');
            query.selectField('Contact.Email');
            query.setCondition('Contact.Name Like : currentContactName AND ContactId NOT IN :contactId');
            query.setLimit(15);
            query.setOffSet(offset);
            system.debug('query-->'+query);
            system.debug('result-->'+Database.query(query.toSOQL()));
            return (List<AccountContactRelation>) Database.query(
                query.toSOQL());
        }else if(ultimateParentId != null  &&  currentContactName != null){
            ilib_QueryFactory query = newQueryFactory();
            query.selectField('Contact.FirstName');
            query.selectField('Contact.Name');
            query.selectField('Account.Name');
            query.selectField('Contact.LastName');
            query.selectField('Contact.Region__c');
            query.selectField('Contact.Title');
            query.selectField('Contact.Email');
            query.setCondition('Account.Ultimate_Parent_Id__c =: ultimateParentId  AND Account.Ultimate_Parent__c =: ultimateParentName AND Contact.Name Like : currentContactName AND ContactId NOT IN :contactId');
            query.setLimit(15);
            query.setOffSet(offset);
            system.debug('query-->'+query);
            system.debug('result-->'+Database.query(query.toSOQL()));
            return (List<AccountContactRelation>) Database.query(
                query.toSOQL());
        }else{
            return null;
        }
    }
	
	/*
    *  @author  Soumya Sahu
    *  @description Retrieve list of fields for AccountContactRelation Object based on Account
    *  @param set<id>
    *  @return sObjectFieldList list of Schema.SObjectField
    */

     public List<AccountContactRelation> getAccountContactRelationByAccount(set<id> setAccountIds){
            
            return (List<AccountContactRelation>) Database.query(
            newQueryFactory().setCondition('AccountId  IN : setAccountIds').toSOQL()
        );
        }
    /*
    *  @author  Gopi
    *  @description Retrieve list of fields for AccountContactRelation Object based on Account
    *  @param set<id>
    *  @return sObjectFieldList list of Schema.SObjectField
    */

     public List<AccountContactRelation> getAccountContactRelationByContact(set<id> setContactIds){
            
            return (List<AccountContactRelation>) Database.query(
            newQueryFactory().selectField('Roles').selectField('Product_Notifications_Categories__c').setCondition('ContactId  IN : setContactIds').toSOQL()
        );
    }

	/*
    *  @author Vaibhav Sirohi
    *  @params: set of contact Ids
    *  @description DCP-39969 Retrieve list of fields for direct AccountContactRelations based on contact
    *  @return list of account contact relations
    *  @method:getDirectAccConRelationByContact
    */

    public List<AccountContactRelation> getDirectAccConRelationByContact(Set<Id> setContactIds){
        return (List<AccountContactRelation>) Database.query(
            newQueryFactory().selectField('IsActive').selectField('IsDirect')
            .setCondition('ContactId  IN : setContactIds AND IsDirect = true AND IsActive = false').toSOQL());
    }
	
    /*
    *  @author Vaibhav Sirohi
    *  params: set of contact Ids
    *  @description DCP-40723 Retrieve list of AccountContactRelations based on contacts
    *  @return list of account contact relations
    *  method:getAccConRelationByContact
    */
    
    public List<AccountContactRelation> getAccConRelationByContact(Set<Id> setContactIds){
        return (List<AccountContactRelation>) Database.query(
            newQueryFactory().selectField('IsDirect')
            .setCondition('ContactId  IN : setContactIds AND IsDirect = true').toSOQL()
        );
    }
    /*
    * @author Saddam
    * @date   28-feb-2022
    * @description Aggregate roll up of all data,pm-33, PM-430
    * @param accountIds Set of Account Ids and Group field
    *
    */
    public List<AggregateResult> getAcrCountByAccount(Set<Id> accountIds) {
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) 
        logger = new ilib_LogQuery(LOG_TITLE + '.getContactCountByAccount',UtilsCollection.serializeIds(accountIds));

        String query = 'Select AccountId,count(id) NumberOfRecord,Contact.Is_Active__c contactIsActive,IsActive from AccountContactRelation where AccountId IN: accountIds group by AccountId,Contact.Is_Active__c,IsActive';
        System.debug('---query--- '+query);

        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS))
        logger.stop(Database.query(query).size());

        return Database.query(query);
    }
    /*
    * @author Saddam
    * @date   09-MAR-2022
    * @description Aggregate roll up of all data,pm-33 AND PM-430
    * @param accountIds Set of Account Ids and Group field
    *
    */
    public List<AccountContactRelation> getAcrWithContactByAccount(Set<Id> setAccIds) {
      
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) 
        logger = new ilib_LogQuery(LOG_TITLE + '.getAcrWithContactByAccount',UtilsCollection.serializeIds(setAccIds));

        String acrQuery = newQueryFactory(false).selectField('Product_Notifications_Categories__c')
        .selectField('Roles')
        .selectField('AccountId')
        .selectField('IsActive')
        .selectField('Contact.Is_Active__c')
        .setCondition('AccountId IN :setAccIds').toSOQL();
        List<AccountContactRelation> acr = (List<AccountContactRelation>) Database.query(acrQuery);
        
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS))
            logger.stop(acr.size());

        return acr;
    }

    /*
    * @author abhishek
    * @date   03-05-2024
    * @description CMCM-6731
    * @param set of contact Ids
    *
    */

    public List<AccountContactRelation> getAccountContactRelationByContactId(Set<Id> setConIds) {
      
        ilib_LogQuery logger = new ilib_LogQuery();
        if (Feature.isOn(FEATURE_SALES_QUERY_LOGS)) 
        logger = new ilib_LogQuery(LOG_TITLE + '.getAccountContactRelationByContactId',UtilsCollection.serializeIds(setConIds));

        String acrQuery = newQueryFactory(false).selectField('Id')
        .selectField('ContactId')
        .selectField('AccountId')
        .setCondition('ContactId IN :setConIds').toSOQL();
        List<AccountContactRelation> acr = (List<AccountContactRelation>) Database.query(acrQuery);
        
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS))
            logger.stop(acr.size());

        return acr;
    }

    /**
     * @author Venkatesh Prabhu
     * @description : Method to get Account Contact Relations by Account Ids and Contact Ids
     * @param accountIds 
     * @param contactIds 
     * @return  `List<AccountContactRelation>`
     */
    public List<AccountContactRelation> getAccountContactRelactionByAccountIdAndContactId(Set<Id> accountIds, List<Id> contactIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getAccountContactRelactionByAccountIdAndContactId', UtilsCollection.serializeIds(accountIds));
        }
        
        List<AccountContactRelation> accountContacts = (List<AccountContactRelation>) Database.query(
            newQueryFactory(false)
            .selectField('Id')
            .selectField('IsActive')
            .selectField('AccountId')
            .selectField('ContactId')
            .setCondition('AccountId in :accountIds and ContactId in :contactIds')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(accountContacts.size());
        }
        return accountContacts;
    }

}
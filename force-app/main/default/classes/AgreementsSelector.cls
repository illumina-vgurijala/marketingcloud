/**
 *    @author Soumya Ranjan Sahu
 *    @date   09-09-2018
 *    @description    Class to get the Agreements records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                         Date                     Description
 *    Soumya Ranjan Sahu               09-Sept-2018             Initial Version
 *    Gautam Arya                      19-July-2021             DCP-39882 Fetch Agreements form for a Work Order
 *    ------------------------------------------------------------------------------------                     
 */
public with sharing class AgreementsSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'AgreementsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
	/**
    *  @author Soumya Ranjan Sahu
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Agreement
    **/
   public Schema.SObjectType getSObjectType()
   {
        return echosign_dev1__SIGN_Agreement__c.sObjectType;
   }
    
    /**
     *  @author  Soumya Ranjan Sahu 
     *  @description Retrieve list of fields for Agreement(echo sign) sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           echosign_dev1__SIGN_Agreement__c.id,
           echosign_dev1__SIGN_Agreement__c.echosign_dev1__Status__c,
           echosign_dev1__SIGN_Agreement__c.Work_Order__c
          
       };
    }
        /**
     *  @author Soumya Ranjan Sahu
     *  @description Fetch Agreements from Agreement Id set where work order is not null
     *  @param Agreements ids
     *  @return Agreements
     **/
    public List<echosign_dev1__SIGN_Agreement__c> selectAgreements(Set<Id> setAgreementIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAgreements', UtilsCollection.serializeIds(setAgreementIds));
		
		List<echosign_dev1__SIGN_Agreement__c> res = (List<echosign_dev1__SIGN_Agreement__c>) Database.query(
						newQueryFactory().selectField('id')
						.selectField('Name')
            			.selectField('echosign_dev1__Status__c')
            			.selectField('Work_Order__c')
            			.setCondition('ID IN : setAgreementIds AND Work_Order__c != NULL').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	
	 /**
     *  @author Digvijay
     *  @description Fetch Agreements from for an Parts order Line's
     *  @param POL ids
     *  @return Agreements
     **/
    public List<echosign_dev1__SIGN_Agreement__c> selectPOLAgreements(Set<Id> setPOLIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectPOLAgreements', UtilsCollection.serializeIds(setPOLIds));
		
		List<echosign_dev1__SIGN_Agreement__c> res = (List<echosign_dev1__SIGN_Agreement__c>) Database.query(
            newQueryFactory().selectField('id')
							 .selectField('Name')
            				 .selectField('echosign_dev1__Status__c')
            				 .selectField('Parts_Order_Line__c')
            				 .setCondition('Parts_Order_Line__c IN : setPOLIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
     /**
     *  @author Gautam Arya
     *  @description Fetch Agreements form for a Work Order
     *  @param WO ids
     *  @return Agreements
     **/
    public List<echosign_dev1__SIGN_Agreement__c> selectWOAgreements(Set<Id> setWOId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWOAgreements', UtilsCollection.serializeIds(setWOId));
		
		List<echosign_dev1__SIGN_Agreement__c> res = (List<echosign_dev1__SIGN_Agreement__c>) Database.query(
            newQueryFactory().selectField('id')
                      .selectField('Name')
            				 .selectField('echosign_dev1__Status__c')
            				 .selectField('Work_Order__c')
            				 .setCondition('Work_Order__c IN : setWOId').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}
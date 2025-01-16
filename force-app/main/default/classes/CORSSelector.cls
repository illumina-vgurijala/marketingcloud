/**
 *    @author Shashank Singhal
 *    @date   2018-08-24
 *    @description  DCP-844: CORS Selector 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Shashank                        2018-08-24         Initial Version
 *    Gerardo Garcia                  2024-08-07         CMCM-9578 Added selectCORSFromAccountsAndStatus
 *    ------------------------------------------------------------------------------------ 
 *
 */
public with sharing class CORSSelector extends ilib_SObjectSelector{
	
    private static final String LOG_TITLE = 'CORSSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
	/**
    *  @author Shashank Singhal 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the CORS
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Contract_Order_Routing_Sheet__c.sObjectType;
   }
    
    /**
     *  @author  Shashank Singhal
     *  @description Retrieve list of fields for CORS sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList(){
    	return new List<Schema.SObjectField> {
        	Contract_Order_Routing_Sheet__c.id, 
                Contract_Order_Routing_Sheet__c.Letter_Of_Acceptance_Notes__c, 
                Contract_Order_Routing_Sheet__c.Rev_Rec_Code__c,
                Contract_Order_Routing_Sheet__c.Opportunity__c,
                Contract_Order_Routing_Sheet__c.Order__c
        };
    }
    
    /**
     *  @author Shashank Singhal 
     *  @description Fetch CORS for related opportunities
     *  @param setOpportunityIds Set of Opportunity Ids
     *  @return CORS List
     **/
    /*public List<Contract_Order_Routing_Sheet__c> selectCORSForOpportunities(Set<Id> setOpportunityIds) 
    {
        return (List<Contract_Order_Routing_Sheet__c>) Database.query(
            newQueryFactory().setCondition('Opportunity__c IN :setOpportunityIds')
                              .addOrdering('CreatedDate', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );
    }*/

    /**
     *  @author Ritka M
     *  @description Fetch CORS for related orders
     *  @param setOpportunityIds Set of Apptus Order Ids
     *  @return CORS List
     **/
    public List<Contract_Order_Routing_Sheet__c> selectCORSForOrders(Set<Id> setOrderIdsIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCORSForOrders', UtilsCollection.serializeIds(setOrderIdsIds));
		
        List<Contract_Order_Routing_Sheet__c> res = (List<Contract_Order_Routing_Sheet__c>) Database.query(
            newQueryFactory().setCondition('Order__c IN :setOrderIdsIds')
                              .addOrdering('CreatedDate', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Ritka M
     *  @description Fetch CORS for related orders
     *  @param setOpportunityIds Set of Apptus Order Ids
     *  @return CORS List
     **/
    public List<Contract_Order_Routing_Sheet__c> selectCORSForOrders(List<Id> setOrderIdsIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCORSForOrders', UtilsCollection.serializeIds(new Set<Id>(setOrderIdsIds)));
		
        List<Contract_Order_Routing_Sheet__c> res = (List<Contract_Order_Routing_Sheet__c>) Database.query(
            newQueryFactory().setCondition('Order__c IN :setOrderIdsIds')
                              .addOrdering('CreatedDate', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     * @description: Gets CORS by accounts rel and by status
     * @param: Set<Id> accounts ids
     * @param: Set<String> Contract_Review_Status__c of CORS. Open, In Review, Completed.
     */
    public List<Contract_Order_Routing_Sheet__c> selectCORSFromAccountsAndStatus(Set<Id> accountIds, Set<String> status)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCORSFromAccountsAndStatus', 
                'accountIds:' + UtilsCollection.serializeIds(accountIds) + ' status:' + status);
        }

        List<Contract_Order_Routing_Sheet__c> res = (List<Contract_Order_Routing_Sheet__c>) Database.query(
            newQueryFactory(false, false, false)
            .selectField('Account__c')
            .setCondition('Contract_Review_Status__c IN :status')
            .setCondition('Account__c IN :accountIds')
            .addOrdering('CreatedDate', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}
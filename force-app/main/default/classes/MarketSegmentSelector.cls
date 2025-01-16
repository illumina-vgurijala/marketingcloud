/**
 * @author Akshay Mohan 
 * @date   12-Oct-2018
 * @description  Selector class for Market_Segment__c
 * Modification Log:
*  --------------------------------------------------------------------------------------------------------- 
*   Developer                Date                Description                                                 
*   Akshay Mohan             12-Oct-2018         Original
*   Adyasha                  30-May-2022         Added new method - selectByAccountIdExcludingGivenRecords
*   Deep Diwakar             Dec-03-2023        CMCM-4856: Added new method - getMarketSegmentByAccountIds
*  ---------------------------------------------------------------------------------------------------------          
*/
public with sharing class MarketSegmentSelector extends ilib_SObjectSelector{

    private static final String QUERY_LOGS_SALES = 'SalesQueryLogs';
    private static final String LOG_TITLE = 'MarketSegmentSelector';
	/*
    * 	@author Akshay Mohan
    *   @date   12-Oct-2018
    *   @description  Describe the object
    *
    */
	public Schema.SObjectType getSObjectType(){
      return Market_Segment__c.sObjectType;
   }

    /*
    * 	@author Akshay Mohan
    *   @date   12-Oct-2018
    *   @description  Set Select fields
    *
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
       return new List<Schema.SObjectField> {
          Market_Segment__c.Id,
          Market_Segment__c.Name,
          Market_Segment__c.Account__c,
          Market_Segment__c.Market_Segment__c,
          Market_Segment__c.Market_Sub_Segment__c,
		  Market_Segment__c.Percent_Allocation__c
       };
    }

	/**
     *  @author Akshay Mohan
     *  @date   30-Aug-2018
     *  @description Fetch the Market Segements for an account
     *  @param Id idAccount
     *  @return Market_Segment__c List with related Accounts
     * 
    **/
    public List<Market_Segment__c> selectByAccountId(Id idAccount){
		    
        ilib_QueryFactory query = newQueryFactory();
        
        query.setCondition(' Account__c = :idAccount ');
        
        //get relationship fields on Account
        AccountsSelector selectorAccount = new AccountsSelector();
        selectorAccount.configureQueryFactoryFields(query,'Account__r');
        
        //select records
        return (List<Market_Segment__c>) Database.query( query.toSOQL() );
	}
  /**
     *  @author Kushagra Desai
     *  @date   21-Nov-2019
     *  @description Fetch the Market Segements for list of account
     *  @param List of account Id
     *  @return Market_Segment__c List with related Accounts
     * 
    **/
    public List<Market_Segment__c> selectByAccountId(List<String> idAccount){
        
        ilib_QueryFactory query = newQueryFactory();
        
        query.setCondition(' Account__c IN :idAccount ');
        
        //get relationship fields on Account
        AccountsSelector selectorAccount = new AccountsSelector();
        selectorAccount.configureQueryFactoryFields(query,'Account__r');
        
        //select records
        return (List<Market_Segment__c>) Database.query( query.toSOQL() );
  }

  /**
     *  @author Adyasha Satapathy
     *  @date   27-May-2022
     *  @description Fetch the Market Segements for a set of accountIds excluding market segment Ids provided
     *  @param Set<Id> setAccountIds, Set<Id> setMarketSegmentIdsToExclude
     *  @return Market_Segment__c List with related Accounts
     * 
    **/
    public List<AggregateResult> selectByAccountIdExcludingGivenRecords(Set<Id> setAccountIds, Set<Id> setMarketSegmentIdsToExclude) {
        ilib_LogQuery logger = null;
        if (Feature.isOn(QUERY_LOGS_SALES)) { logger = new ilib_LogQuery(LOG_TITLE + '.selectByAccountIdExcludingGivenRecords',UtilsCollection.serializeIds(setAccountIds) +'~'+UtilsCollection.serializeIds(setMarketSegmentIdsToExclude)); }
   
        String strQuery = 'SELECT Account__c, SUM(Percent_Allocation__c) TotalAllocation FROM Market_Segment__c WHERE Account__c IN :setAccountIds';

        if(setMarketSegmentIdsToExclude != null && !setMarketSegmentIdsToExclude.isEmpty()) { strQuery += ' AND Id NOT IN :setMarketSegmentIdsToExclude'; } 

        strQuery += ' GROUP BY Account__c';

        List<AggregateResult> result = (List<AggregateResult>) Database.query(strQuery);

        if (Feature.isOn(QUERY_LOGS_SALES)) { logger.stop(result.size()); }
        return result;
    }

    /**
     *  @author: Deep Diwakar
     *  @date:  Dec-04-2023
     *  @description:  Fetch the Market Segements for given set of accountIds
     *  @param: set of account ids
     *  @return List of market segments tied to these account ids
     * 
    **/
    public List<Market_Segment__c> getMarketSegmentByAccountIds(Set<Id> setAccountIds) {
        ilib_LogQuery logger = new ilib_LogQuery();

        if (Feature.isOn(QUERY_LOGS_SALES)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getMarketSegmentByAccountIds',UtilsCollection.serializeIds(setAccountIds));
        }

        List<Market_Segment__c> res = (List<Market_Segment__c>) Database.query(
                    newQueryFactory(false)
                    .selectField('Id')
                    .selectField('Account__c')
                    .selectField('Market_Segment__c')
                    .selectField('Percent_Allocation__c')
                    .setCondition('Account__c IN : setAccountIds').toSOQL()
        );

        if (Feature.isOn(QUERY_LOGS_SALES)) {
            logger.stop(res.size());
        }

        return res;

    }
}
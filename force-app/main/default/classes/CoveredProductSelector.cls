/**
 *    @author Veerendra
 *    @date   09-June-2018
 *    @description    Class to get the Covered Product records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Veerendra                   09-Jun-2018            Initial Version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class CoveredProductSelector extends ilib_SObjectSelector
{
	
    private static final String LOG_TITLE = 'CoveredProductSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String CONTRACTTYPEZWS = 'Software (ZWS)';
    private static final String CONTRACTTYPEZCQ = 'Quantity Contract (ZCQ)';
    private static final String CONTRACTTYPESOFTWARE = 'Software Contract';
   /**
   /**
    *  @author Veerendra
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Service_Contract_Products__c.sObjectType;
   }
    
   /**
     *  @author  Veerendra 
     *  @description Retrieve list of fields for Covered Product sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           SVMXC__Service_Contract_Products__c.id,
           SVMXC__Service_Contract_Products__c.SVMXC__Installed_Product__c,
           SVMXC__Service_Contract_Products__c.SVMXC__Service_Contract__c,
		   SVMXC__Service_Contract_Products__c.SVMXC__End_Date__c
       };
    }
    /*  
    * @description  Related select field
    */
    private ilib_QueryFactory getRelatedFieldsQuery(){
        return newQueryFactory()
            .selectField('SVMXC__Installed_Product__r.SVMXC__Product__r.Condition_Type__c')
            .selectField('SVMXC__Installed_Product__r.SVMXC__Product__r.Serial_Number_Profile__c');
    }
	public string stringSortOrder = 'Name ASC';
	 /*  
      * @description - return the string order
      */
	public override String getOrderBy(){
        return stringSortOrder;
    }
    /**
     *  @author Veerendra
     *  @description Fetch Covered Products associated with Installed Product
     *  @param Installed Product Ids
     *  @return List of Covered Products that are entitled
     **/
    public List<SVMXC__Service_Contract_Products__c> selectActiveCoveredProducts(Set<Id> setInstalledProductIds) 
    {
        Date dateToday = system.today();
		stringSortOrder = 'SVMXC__Service_Contract__r.SVMXC__End_Date__c ASC';
		
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectActiveCoveredProducts', UtilsCollection.serializeIds(setInstalledProductIds));
		
        List<SVMXC__Service_Contract_Products__c> res = (List<SVMXC__Service_Contract_Products__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Service_Contract__r.Name')
			.selectField('SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c')
            .selectField('SVMXC__Service_Contract__r.SVMXC__Service_Level__c')
            .selectField('SVMXC__Service_Contract__r.SVMXC__End_Date__c')
			.selectField('External_Id__c')
			.selectField('SVMXC__Service_Contract__r.SVMXC__Service_Plan__c')
			.selectField('SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c')
            .setCondition('SVMXC__Installed_Product__c IN : setInstalledProductIds ' +
                                          ' AND Contract_Status__c = \'Active\'' +
                                          ' AND SVMXC__Start_Date__c <= :dateToday' +
                                          ' AND SVMXC__End_Date__c >=:dateToday ' ).toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
    /**
     *  @author Shashank Singhal
     *  @description Fetch Covered Products associated with Installed Product
     *  @param Set<Id> setInstalledProductIds
     *  @return List of Covered Products ordered by End Date
     **/
    public List<SVMXC__Service_Contract_Products__c> selectOrderedCoveredProductsForInstalledProduct(Set<Id> setInstalledProductIds) 
    {
        stringSortOrder = 'SVMXC__End_Date__c DESC';
		
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOrderedCoveredProductsForInstalledProduct', UtilsCollection.serializeIds(setInstalledProductIds));
		
        List<SVMXC__Service_Contract_Products__c> res = (List<SVMXC__Service_Contract_Products__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Service_Contract__c')
                             .selectField('SVMXC__Installed_Product__c')
                             .setCondition('SVMXC__Installed_Product__c IN :setInstalledProductIds')
                             .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	/**
     *  @author Nitin Sood
     *  @description Fetch Covered Products associated with External Id
     *  @param External Ids
     *  @return List of Covered Products that are entitled
     **/
    public List<SVMXC__Service_Contract_Products__c> selectCoveredProductsForExternalIds(Set<String> setExternalIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCoveredProductsForExternalIds', UtilsCollection.serializeIds(setExternalIds));
		
        List<SVMXC__Service_Contract_Products__c> res =  (List<SVMXC__Service_Contract_Products__c>) Database.query(
            newQueryFactory().selectField('External_Id__c')
                            .setCondition('External_Id__c IN : setExternalIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	 
	
	/**
     *  @author Shashank Singhal
     *  @description Fetch Covered Products associated with Service Contract
     *  @param Service Contract Ids
     *  @return List of Covered Products 
     **/
    public List<SVMXC__Service_Contract_Products__c> selectCoveredProductsForServiceContracts(Set<Id> setServiceContractIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCoveredProductsForServiceContracts', UtilsCollection.serializeIds(setServiceContractIds));
		
        List<SVMXC__Service_Contract_Products__c> res = (List<SVMXC__Service_Contract_Products__c>) Database.query(
            getRelatedFieldsQuery().setCondition('SVMXC__Service_Contract__c IN : setServiceContractIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /**
     *  @author Shashank Singhal
     *  @description Fetch Active Covered Products associated with Installed product
     *  @param Installed Product Ids
     *  @return List of Covered Products 
     **/
    public List<SVMXC__Service_Contract_Products__c> selectActiveCoveredProductsForIP(Set<Id> setInstalledProductIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectActiveCoveredProductsForIP', UtilsCollection.serializeIds(setInstalledProductIds));
		
        List<SVMXC__Service_Contract_Products__c> res = (List<SVMXC__Service_Contract_Products__c>) Database.query(
            newQueryFactory().selectField('SVMXC__Service_Contract__r.SVMXC__Service_Plan__c')
                            .selectField('SVMXC__Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c')
                            .setCondition('SVMXC__Service_Contract__r.Status__c = \'Active\' AND SVMXC__Installed_Product__c IN :setInstalledProductIds AND SVMXC__Service_Contract__r.ERP_Contract_Type__c !=: CONTRACTTYPEZWS AND SVMXC__Service_Contract__r.ERP_Contract_Type__c !=: CONTRACTTYPEZCQ AND SVMXC__Service_Contract__r.ERP_Contract_Type__c !=: CONTRACTTYPESOFTWARE').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Shashank Singhal
     *  @description Fetch Covered Products associated with Installed Product ordered by Contract End Date
     *  @param Set<Id> setInstalledProductIds
     *  @return List of Covered Products ordered by Contract End Date
     **/
    public List<SVMXC__Service_Contract_Products__c> selectOrderedCoveredProductsByContractEndDate(Set<Id> setInstalledProductIds) 
    {
        stringSortOrder = 'SVMXC__Service_Contract__r.SVMXC__End_Date__c DESC';
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOrderedCoveredProductsByContractEndDate', UtilsCollection.serializeIds(setInstalledProductIds));
		
        List<SVMXC__Service_Contract_Products__c> res = (List<SVMXC__Service_Contract_Products__c>) Database.query(
            newQueryFactory().setCondition('SVMXC__Installed_Product__c IN :setInstalledProductIds AND SVMXC__Service_Contract__r.Status__c != \'Canceled\' AND SVMXC__Service_Contract__r.Status__c != \'Blocked\' AND SVMXC__Service_Contract__r.ERP_Contract_Type__c !=: CONTRACTTYPEZWS AND SVMXC__Service_Contract__r.ERP_Contract_Type__c !=: CONTRACTTYPEZCQ AND SVMXC__Service_Contract__r.ERP_Contract_Type__c !=: CONTRACTTYPESOFTWARE')
                             .toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}

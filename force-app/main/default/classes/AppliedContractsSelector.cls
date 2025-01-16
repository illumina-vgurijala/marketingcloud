/**
 *    @author Veerendra
 *    @date   09-June-2018
 *    @description    Class to get the Entitlement records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Veerendra                   09-Jun-2018            Initial Version
 *  Abhishek Yadav                04-March 2024          CMCM-273 product on cases Functionality
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class AppliedContractsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'AppliedContractsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String CONTRACTTYPEZWS = 'Software (ZWS)';
    private static final String CONTRACTTYPEZCQ = 'Quantity Contract (ZCQ)';
    private static final String CONTRACTTYPESOFTWARE = 'Software Contract';
    public static final String CONSUMABLE_CONTRACT = 'Consumable Contract';
    /**
    *  @author Veerendra
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Applied_Contract__c.sObjectType;
   }
  ////Added by Shruti Karn for INC0227445
  public string stringSortOrder = 'Service_Contract__r.SVMXC__Service_Level__r.Least_SLA__c ASC';
    /**
    *  @author Veerendra
    *  @description - returns Service_Contract__r.SVMXC__Service_Level__r.Least_SLA__c ASC
    **/
  public override String getOrderBy(){
        return stringSortOrder;
    }
   
   /**
     *  @author  Veerendra 
     *  @description Retrieve list of fields for Entitlement sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           Applied_Contract__c.id,
           Applied_Contract__c.Case_Number__c,
           Applied_Contract__c.Work_order__c,
           Applied_Contract__c.Service_Contract__c,
           Applied_Contract__c.Contract_Start_Date__c,
           Applied_Contract__c.Contract_End_Date__c,
           Applied_Contract__c.Applied_Contract_Source__c
       };
    }
    //Commented by Shruti Karn for INC0227445
    /**
     *  @author  Mandeep
     *  @description Define ordering of records
     *  @return String 
     *
    public override String getOrderBy(){
      return 'Service_Contract__r.SVMXC__Service_Level__r.Least_SLA__c ASC';
   }*/

    /**
     *  @author Veerendra
     *  @description Fetch Entitlement associated with Service Contract which are entitled to Cases
     *  @param Case Ids
     *  @return List of Service Contracts that are entitled
     **/
    public List<Applied_Contract__c> selectCaseEntitlements(Set<Id> setCaseIds) 
    {
		
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseEntitlements', UtilsCollection.serializeIds(setCaseIds));
		
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().setCondition('Case_Number__c IN : setCaseIds ').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;
    }

    /**
     *  @author Veerendra
     *  @description Fetch Entitlement associated with Service Contract which are entitled to Work Orders
     *  @param Work Order Ids
     *  @return List of Service Contracts that are entitled
     **/
    public List<Applied_Contract__c> selectWorkOrderEntitlements(Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectWorkOrderEntitlements', UtilsCollection.serializeIds(setWorkOrderIds));
		
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().setCondition('Work_order__c IN : setWorkOrderIds ').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;
    }

    /*
     *  @author Veerendra
     *  @description Fetch Entitlement associated with Service Contract which are entitled to Work Orders
     *  @param Work Order Ids
     *  @return List of Service Contracts that are entitled
    */ 
    public List<Applied_Contract__c> selectEntitlements(Set<Id> setCaseIds, Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectEntitlements', UtilsCollection.serializeIds(setCaseIds)  + '|' + UtilsCollection.serializeIds(setWorkOrderIds));
		
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().setCondition('Associated_Product__c = null AND (Case_Number__c IN : setCaseIds OR Work_order__c IN : setWorkOrderIds)').toSOQL()
         );
		 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;
    } 
    
         /*
    * @author Mandeep Singh
    * @date   08-13-2018
x`x    * @description  Fetch Entitlements fields on basis of record Id and sort based on SLA term.
    * @param IN:setEntitlementIds - Set of Entitlement IDs
    *
    */
   public List<Applied_Contract__c> selectEntitlementsFromIds(Set<Id> setEntitlementIds) 
    {
    

	ilib_LogQuery logger=null;
	if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
		logger = new ilib_LogQuery(LOG_TITLE + '.selectEntitlementsFromIds', UtilsCollection.serializeIds(setEntitlementIds));
	
    stringSortOrder = 'Contract_End_Date__c ASC';
    system.debug('test query'+newQueryFactory().selectField('Service_Contract__r.SVMXC__Service_Level__c').selectField('Service_Contract__r.SVMXC__Service_Level__r.Least_SLA__c').setCondition('Id IN : setEntitlementIds').toSOQL());
	
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().selectField('Service_Contract__r.SVMXC__Service_Level__c')
			.selectField('Service_Contract__r.Name')
            .selectField('Work_order__r.Applied_Service_Contract__c')
            .selectField('Service_Contract__r.Consumables_Included__c')
            .selectField('Service_Contract__r.SVMXC__Service_Plan__r.Name')
            .selectField('Service_Contract__r.Parts_Included__c')
			.selectField('Service_Contract__r.Labor_Included__c')
            .selectField('Service_Contract__r.ERP_Header_Contract_Number__c')
            .selectField('Service_Contract__r.ERP_Contract_Line_Number__c')
			.setCondition('Id IN : setEntitlementIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;

    }
	
	 /**
     *  @author Shruti Karn
     *  @description Fetch Entitlement associated with Service Contract which are entitled to Work Orders
     *  @param Set of Work Order Ids
     *  @return List of Service Contracts that are entitled
     **/
    public List<Applied_Contract__c> selectWOEntitlements(Set<Id> setWorkOrderIds) 
    {
        stringSortOrder = 'Contract_End_Date__c ASC';
		ilib_LogQuery logger=null;
		if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
			logger = new ilib_LogQuery(LOG_TITLE + '.selectEntitlementsFromSMCIds', UtilsCollection.serializeIds(setWorkOrderIds));
	
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
             newQueryFactory()
            .selectField('Service_Contract__r.Consumables_Included__c')
            .selectField('Service_Contract__r.SVMXC__Service_Plan__r.Name')
            .selectField('Service_Contract__r.Parts_Included__c')
			.selectField('Service_Contract__r.Labor_Included__c')
            .selectField('Service_Contract__r.ERP_Header_Contract_Number__c')
            .selectField('Service_Contract__r.ERP_Contract_Line_Number__c')
            .setCondition('Work_order__c IN : setWorkOrderIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;
    }
	 /*
     *  @author Digvijay
     *  @description Fetch Entitlement associated with Service Contract which are entitled to Work Orders
     *  @param Service Contracts Id's
     *  @return List of Applied Contracts that are entitled
    */
	
	 public List<Applied_Contract__c> selectEntitlementsFromSMCIds(Set<Id> setSMCIds){
		ilib_LogQuery logger=null;
		if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
			logger = new ilib_LogQuery(LOG_TITLE + '.selectEntitlementsFromSMCIds', UtilsCollection.serializeIds(setSMCIds));
	
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().selectField('Work_order__c').selectField('Work_order__r.SVMXC__Order_Type__c').selectField('Work_order__r.SVMXC__Order_Status__c').selectField('Associated_Product__c') 
                             .setCondition('Service_Contract__c IN : setSMCIds').toSOQL()
        );
		
       if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;
    }

    /*
     *  @author Ritika M
     *  @description Fetch Active Entitlement associated to Work Orders, excluding a few contracts
     *  @param Service Contracts Id's to be excluded, work order Id's
     *  @return List of Applied Contracts that are entitled
    */
	
	public List<Applied_Contract__c> selectActiveEntitlementsFromWO(Set<Id> setSMCIds, Set<Id> setWorkOrderIds){
		ilib_LogQuery logger=null;
		if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
			logger = new ilib_LogQuery(LOG_TITLE + '.selectActiveEntitlementsFromWO', UtilsCollection.serializeIds(setSMCIds));
	
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().selectField('Work_order__c').selectField('Work_order__r.SVMXC__Order_Type__c')
                            .setCondition('Service_Contract__c NOT IN : setSMCIds AND Work_order__c IN : setWorkOrderIds AND Contract_Status__c = \'Active\'')
                            .toSOQL()
        );
		
       if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;
    }
    /*
     *  @author Abhishek Yadav
     *  @description Fetch Active Applied Contracts associated to Work Orders
     *  @param work order Id's
     *  @return List of Applied Contracts that are Active
    */
    public List<Applied_Contract__c> selectActiveAppliedContractFromWO(Set<Id> setWorkOrderIds) {
		ilib_LogQuery logger = null;
		if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
			logger = new ilib_LogQuery(LOG_TITLE + '.selectActiveAppliedContractFromWO', UtilsCollection.serializeIds(setWorkOrderIds));
	
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().selectField('Work_order__c').selectField('Work_order__r.SVMXC__Order_Type__c')
                            .setCondition('Work_order__c IN : setWorkOrderIds AND Contract_Status__c = \'Active\'')
                            .toSOQL()
        );
		
       if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;
    }
    /*
     *  @author Abhishek
     *  @description Fetch Entitlement associated with Associated Product
     *  @param AssociatedProduct Ids
     *  @return List of Service Contracts that are entitled
    */ 
    public List<Applied_Contract__c> selectAssociatedProductEntitlements(Set<Id> associatedProductIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedProductEntitlements', UtilsCollection.serializeIds(associatedProductIds));
        }
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().setCondition('Associated_Product__c IN : associatedProductIds').toSOQL()
         );
		 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    /*
     *  @author Yash Jain
     *  @description Fetch Entitlement associated with Associated Product, excluding Consumable Contracts
     *  @param AssociatedProduct Ids
     *  @return List of Service Contracts that are entitled
    */ 
    public List<Applied_Contract__c> selectAssociatedProductEntitlementsExcludingConsumables(Set<Id> associatedProductIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedProductEntitlementsExcludingConsumables', UtilsCollection.serializeIds(associatedProductIds));
        }
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory()
            // Added SVMX_PS_External_ID__c filter for cmcm-9024
            .setCondition('Associated_Product__c IN : associatedProductIds AND (NOT Service_Contract__r.SVMX_PS_External_ID__c Like \'%'+CONSUMABLE_CONTRACT+'%\')').toSOQL()
         );
		 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    /*
     *  @author Abhishek Yadav (CMCM-295) 
     *  @description Fetch Applied Contract associated with Associated Product
     *  @param AssociatedProduct Ids
     *  @return List of Applied Contracts
    */ 
    public List<Applied_Contract__c> selectActiveAppliedContractForWO(Set<Id> associatedProductIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectActiveAppliedContractForWO', UtilsCollection.serializeIds(associatedProductIds));
        }
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().selectField('Service_Contract__r.SVMXC__Service_Plan__c')
                            .selectField('Associated_Product__c')
                            .selectField('Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c')
                            .setCondition('Service_Contract__r.Status__c = \'Active\' AND Associated_Product__c IN : associatedProductIds AND Service_Contract__r.ERP_Contract_Type__c !=: CONTRACTTYPEZWS AND Service_Contract__r.ERP_Contract_Type__c !=: CONTRACTTYPEZCQ AND Service_Contract__r.ERP_Contract_Type__c !=: CONTRACTTYPESOFTWARE').toSOQL()
         );
		 
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    /**
     *  @author Abhishek Yadav
     *  @description Fetch Entitlement associated with Service Contract which are entitled to Cases and Work Orders
     *  @param Case Ids, WorkOrder Ids
     *  @return List of Service Contracts that are entitled
    **/
    public List<Applied_Contract__c> selectCaseAndWorkOrderEntitlements(Set<Id> setCaseIds, Set<Id> setWoIds) {
		
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseAndWorkOrderEntitlements', UtilsCollection.serializeIds(setCaseIds)  + '|' + UtilsCollection.serializeIds(setWoIds));
        }		
        List<Applied_Contract__c> res = (List<Applied_Contract__c>) Database.query(
            newQueryFactory().setCondition('Case_Number__c IN : setCaseIds OR work_order__c IN : setWoIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;
    }
}
/*
*    @author: Pankaj Singla
*    @date:   12-Aug-2020
*    @description:  Selector class for Contract Object
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla		        12-Aug-2020		       Initial Build
*             Rishab Wali               07-June-2022           [DCP-53883] Adding Query Instrumentation		
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ContractSelector extends ilib_SObjectSelector{

    public static final string LOG_TITLE = 'ContractSelector';
    public static final String MARKETING_QUERY_LOGS = 'MarketingQueryLogs';
    string stringSortOrder = 'LastModifiedDate desc';

	/**Method - get sObjectType */
    public Schema.SObjectType getSObjectType()
    {
        return Contracts__c.sObjectType;
    }
  	
	/*
    *  @author  Pankaj singla
    *  @description return the orderby field 
    *  @String Sort Order
    */
	
	public override String getOrderBy(){
        return stringSortOrder;
    }
    
	/*
    *  @author  Pankaj singla
    *  @description Retrieve list of fields for Contract Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    */
	
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            Contracts__c.Id,
            Contracts__c.Name,
            Contracts__c.Status__c,
            Contracts__c.Expiration_Date__c,
			Contracts__c.LastModifiedDate,
			Contracts__c.Contact__c                
         };
    }
    
	/*
    *  @author Pankaj singla
    *  @description Fetch the Attendee
    *  @param lst of Contract
    *  @return List of Contract  
    */
	
    public List<Contracts__c> selectContractsByContactIds(Set<Id> setContactId){
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContractsByContactIds',UtilsCollection.serializeIds(setContactId));
        }

        stringSortOrder = 'LastModifiedDate desc';
        List<Contracts__c> res = (List<Contracts__c>) Database.query(
                                                        newQueryFactory()                  
                                                        .setCondition('status__c=\'Active\' and Contact__c in:setContactId').toSOQL()    
                                                        );        
        if (Feature.isOn(MARKETING_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    
}
/**
 *    @author Debanka Chakraborty
 *    @date   08-09-2018
 *    @description    Class to get the Field Action Item records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Debanka                08-Sept-2018             Initial Version
 *    ------------------------------------------------------------------------------------                     
 */
public with sharing class FieldActionItemsSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'FieldActionItemsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    string strOrderByClause;
    /*
    * @Auther : Abhishek Yadav
    * @Description : method for returning order
    * @param : null
    * @return : String
    */
    public override String getOrderBy() {   
        if(String.isNotBlank(strOrderByClause))
            return strOrderByClause;  
        else 
            return super.getOrderBy(); 
    }
	/**
    *  @author Debanka Chakraborty
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Field Action Items
    **/
   public Schema.SObjectType getSObjectType()
   {
        return Field_Action_Item__c.sObjectType;
   }
    
    /**
     *  @author  Debanka Chakraborty 
     *  @description Retrieve list of fields for Field Action Item sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> {
            Field_Action_Item__c.id,
            Field_Action_Item__c.Field_Action_Notification_Record_Type__c,
            Field_Action_Item__c.Case__c
          
       };
    }
    /**
     *  @Debanka Chakraborty
     *  @description Fetch Field Action Items from Field Action Items Id set
     *  @param Field Action Items Ids
     *  @return Field Action Items
     **/
    public List<Field_Action_Item__c> selectFieldActionItemsByFANRecType(Set<Id> setFieldActiionItemIds,string fanRecordtype) 
    { 
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectFieldActionItemsByFANRecType', UtilsCollection.serializeIds(setFieldActiionItemIds)+'|'+FANRecordtype);

        List<Field_Action_Item__c> res = (List<Field_Action_Item__c>) Database.query(
            newQueryFactory().selectField('id')
            				 .selectField('Field_Action_Notification_Record_Type__c')
            				 .selectField('Case__c')
            				 .setCondition('Case__c IN : setFieldActiionItemIds'+' AND Field_Action_Notification_Record_Type__c =:FANRecordtype').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
    /**
     *  @Nitin Sood
     *  @description Fetch Field Action Items from CaseId
     *  @param CaseIds
     *  @return Field Action Items
     **/
    public List<Field_Action_Item__c> selectFieldActionItemsByCaseId(Set<Id> setFieldActiionItemIds) 
    { 
        strOrderByClause = 'CreatedDate DESC';
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectFieldActionItemsByCaseId', UtilsCollection.serializeIds(setFieldActiionItemIds));

        List<Field_Action_Item__c> res = (List<Field_Action_Item__c>) Database.query(
            newQueryFactory().selectField('id')
                     .selectField('Name')
                     .selectField('Case__c')
                     .selectField('Work_Order__c')
                     .setCondition('Case__c IN : setFieldActiionItemIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @Digvijay Singh
     *  @description Fetch Field Action Items from CaseId
     *  @param CaseIds
     *  @return Field Action Items
     **/
    public List<Field_Action_Item__c> selectFieldActionItemsByCaseORWOId(Set<Id> setIds,set<id> setcaseIds) 
    { 
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectFieldActionItemsByCaseORWOId', UtilsCollection.serializeIds(setIds)+'|'+ UtilsCollection.serializeIds(setcaseIds));

        List<Field_Action_Item__c> res = (List<Field_Action_Item__c>) Database.query(
            newQueryFactory().selectField('id')
                     .selectField('Work_Order__c')
                      .selectField('Case__c')
                      .selectField('Field_Action_Notification__c')
                     .setCondition('Work_Order__c IN : setIds'+' OR Case__c IN :setcaseIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}
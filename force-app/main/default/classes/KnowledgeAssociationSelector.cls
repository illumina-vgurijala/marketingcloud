/**
 *    @author KD
 *    @date   24-Nov-2020
 *    @description : Selector class for Plan__c object.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *    Pooja Shalwadi                 22-Sep-2022         Added Query Instrumentation                   
 */
public with sharing class KnowledgeAssociationSelector extends ilib_SObjectSelector{
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String LOG_TITLE = 'KnowledgeAssociationSelector';
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType(){
        return Knowledge_Association__c.sObjectType;
    }
    /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Knowledge_Association__c.id,
            Knowledge_Association__c.Parent_Knowledge__c,
            Knowledge_Association__c.Related_Knowledge__c
        }; 
    }
    /*  
    * @description  Related select field
    */
    private ilib_QueryFactory getRelatedFieldsQuery(){
        return newQueryFactory()
            .selectField('Related_Knowledge__r.RecordType.Name')
            .selectField('Related_Knowledge__r.Title')
            .selectField('Related_Knowledge__r.Knowledge_Source__c')
            .selectField('Related_Knowledge__r.LastModifiedDate');

    }
    /**
     * @author 
     * @date  
     * @description  get Association based on parent Id
     * @param 
     */
    public List<Knowledge_Association__c> getAssociationByParentId(String strParentId) {

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
        logger = new ilib_LogQuery(LOG_TITLE + '.getAssociationByParentId',strParentId);

        List<Knowledge_Association__c> res =  (List<Knowledge_Association__c>) Database.query(
             getRelatedFieldsQuery()
            .setCondition('Parent_Knowledge__c =: strParentId')
            .toSOQL());
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
}
/**
*    @author vishnu Kurra
*    @date   10 march 2020
*    @description  DCP-5311: To fetch DocumentVersion for the attached files
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    vishnu Kurra                  10 march 2020         Initial Version
*    
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class DocumentVersionSelector extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'DocumentVersionSelector';
    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';

    /**
    *  @author vishnu kurra
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Apttus__DocumentVersion__c.sObjectType;
    }
    
    /**
    *  @author  vishnu kurra
    *  @description Retrieve list of fields for DocumentVersion sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus__DocumentVersion__c.id,
            Apttus__DocumentVersion__c.Apttus__AgreementId__c
    	};
    }
    /**
    *  @author vishnu kurra
    *  @description fetch Document details via  Id
    *  @param  setIds of Parent Object ids
    *  @return list of Attachment records
    **/
    public List<Apttus__DocumentVersion__c> getLatestDocumentById(Set<Id> setIds,String strKey) 
    {
        return (List<Apttus__DocumentVersion__c>) Database.query(
            newQueryFactory()
            .selectField('Name')
            .selectField('Apttus__Title__c')
            .selectField('createddate')
            .selectField('Apttus__LatestVersionId__r.Apttus__ContentId__c')
            .setCondition('Apttus__AgreementId__c IN :setIds  AND Apttus__LatestVersionId__c != NULL AND Apttus__Title__c LIKE \'%'+String.escapeSingleQuotes(strKey)+'%\'')
                            .addOrdering('LastModifiedDate', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );
    }

    /*
    * @author Rishi Sharma
    * @date   09-Dec-2021
    * @description Fetch Document Version record
    * @param Set of Document Version id
    *
    */
    public List<Apttus__DocumentVersion__c> selectDocVersion(Set<Id> docIds) {

        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
           logger = new ilib_LogQuery(LOG_TITLE + '.selectDocVersion', UtilsCollection.serializeIds(docIds));
        }
        Integer numberOfQueries = Limits.getQueries();
        System.debug('Number of SOQL queries executed: ' + numberOfQueries);    
        List<Apttus__DocumentVersion__c> res= (List<Apttus__DocumentVersion__c>) Database.query(
            newQueryFactory()
            .selectField('Agreement_Record_Type__c')
            .setCondition('Id IN :docIds').toSOQL()
            );
            
            if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
                logger.stop(res == null ? 0 : 1);
            }
    
            return res;
    }


}
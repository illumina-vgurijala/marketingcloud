/**
*    @author Govind Dubey
*    @date   03 Aug 2018
*    @description  DCP-5311: To fetch ContentDocument for the attached files
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Govind Dubey                   03 Aug 2018         Initial Version
*	 Pankaj Singla					10 Apr 2019			Added selectByContentDocument for ContentDocument	
*    Raja Siva Krishna              11 Nov 2020         Added new method getContentVersionIdsForDocUploadComp
*    Pooja Shalwadi                 22-Sep-2022         Added Query Instrumentation 
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ContentVersionsSelector extends ilib_SObjectSelector{
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String LOG_TITLE = 'ContentVersionsSelector';
    /**
*  @author Govind Dubey 
*  @description  
*  @return SObjectType The Schema.SObjectType of the proposal
**/
    public Schema.SObjectType getSObjectType()
    {
        return ContentVersion.sObjectType;
    }
    
    /**
    *  @author  Govind Dubey
    *  @description Retrieve list of fields for ContentDocument sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            ContentVersion.id,
            ContentVersion.ContentDocumentId,
            ContentVersion.PathOnClient,
            ContentVersion.Title,
            ContentVersion.FileType,
            ContentVersion.IsRecallRelated__c,
            ContentVersion.FileExtension
            
        };
    }
    /**
    *  @author Govind Dubey
    *  @description fetch ContentVersion details via ContentDocumentId
    *  @param setContentDocumentIds set of Content Document ids
    *  @return list of ContentDocument records
    **/
    public List<ContentVersion> selectByContentDocumentId(Set<ID> setContentDocumentIds) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.selectByContentDocumentId', UtilsCollection.serializeIds(setContentDocumentIds));
        }    
        List<ContentVersion> res =(List<ContentVersion>) Database.query(
            newQueryFactory().selectField('VersionData')
			.addOrdering('ContentModifiedDate', ilib_QueryFactory.SortOrder.DESCENDING)
            .setCondition('ContentDocumentId IN :setContentDocumentIds').toSOQL()
        );
        
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    
    /**
    *  @author Govind Dubey
    *  @description fetch ContentVersion details via Content Version Id
    *  @param setContentVersionIds set of Content Version ids
    *  @return list of ContentDocument records
    **/
    public List<ContentVersion> selectByContentVersionId(Set<ID> setContentVersionIds) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.selectByContentVersionId', UtilsCollection.serializeIds(setContentVersionIds));
        }    
        List<ContentVersion> res =(List<ContentVersion>) Database.query(
            newQueryFactory().selectField('VersionData')
			.addOrdering('ContentModifiedDate', ilib_QueryFactory.SortOrder.DESCENDING)
            .setCondition('Id IN :setContentVersionIds').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    
    /**
    *  @author Pankaj Singla
    *  @description fetch ContentVersion details via List ContentDocument IDs
    *  @param List ContendDocumentIds List of Content Document ids
    *  @return list of ContentDocument records
    **/
    public List<ContentVersion> selectByContentDocument(List<id> lstContentDocumentids) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.selectByContentDocument');
        }    
        List<ContentVersion> res = (List<ContentVersion>) Database.query(
            newQueryFactory().selectField('ContentDocument.Title')
            .selectField('Document_Type_fileupload__c')
            .selectField('ContentDocumentId')
            .selectField('VersionData')
            .setCondition('ContentDocumentId IN :lstContentDocumentids').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }

    /**
     *  @author Raja Siva Krishna
     *  @description Fetch List of Uploaded document names
     *  @param  List<Id>  
     *  @return List<ContentVersion>
     **/
    public List<ContentVersion> getContentVersionIdsForDocUploadComp(List<Id> contentDocIds) {

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.getContentVersionIdsForDocUploadComp');
        }    
        List<ContentVersion> res = (List<ContentVersion>) Database.query(
            newQueryFactory()
            .selectField('Document_Type_fileupload__c')
            .selectField('ContentDocumentId')
            .setCondition('Document_Type_fileupload__c!=\'\' AND ContentDocumentId in :contentDocIds').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
	/**
     *  @description Fetch List of ContentVersion records for particular list of ContentDocumentIds
     *  @param  List<Id>  
     *  @return List<ContentVersion>
     **/
    public List<ContentVersion> selectByContentDocumentWithoutVersionData(List<id> lstContentDocumentids) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.selectByContentDocumentWithoutVersionData', UtilsCollection.serializeIds(new Set<Id>(lstContentDocumentids)));
        }    
        List<ContentVersion> res = (List<ContentVersion>) Database.query(
            newQueryFactory().selectField('ContentDocument.Title')
            .selectField('Document_Type_fileupload__c')
            .selectField('ContentDocumentId')
            .setCondition('ContentDocumentId IN :lstContentDocumentids').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
    /*	@author Pooja Shalwadi
     *  @description Fetch List of ContentVersion 
     *  @param  Set<Id>  , String
     *  @return List<ContentVersion>
     *  DCP-49741
     */ 
    public List<ContentVersion> selectByContentDocumentForManualLOA(Set<id> lstContentDocumentids, String documentTypeLOA) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
         logger = new ilib_LogQuery(LOG_TITLE + '.selectByContentDocumentForManualLOA', UtilsCollection.serializeIds(lstContentDocumentids));
        }    
        List<ContentVersion> res = (List<ContentVersion>) Database.query(
            newQueryFactory().selectField('ContentDocument.Title')
            .selectField('Document_Type_fileupload__c')
            .selectField('ContentDocumentId')
            .setCondition('ContentDocumentId IN :lstContentDocumentids AND Document_Type_fileupload__c=:documentTypeLOA').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
}
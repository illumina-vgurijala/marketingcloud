/**
*    @author: Pankaj Singla
*    @date:   10-April-2019
*    @description:  Selector class for ContentDocument Object
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla             10 April 2019            Initial Build
*			  Shivani Jain              29 Nov 2021              DCP-42926 Parts Order Lines Optimization
*             Gladis                    26-Sep-2022              Added Query Instrumentation
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ContentDocumentSelector extends ilib_SObjectSelector{
	
	private static final string  LOG_TITLE = 'ContentDocumentSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
	/**
	*  @author Pankaj Singla
	*  @description  
	*  @return SObjectType The Schema.SObjectType of the Master_Data_Request__c
	**/
	public Schema.SObjectType getSObjectType()
    {
        return ContentDocument.sObjectType;
    }
    
	/* 
    * @description: To get fields of sObject
    * @return: List<Schema.SObjectField>
    */
	public List<Schema.SObjectField> getSObjectFieldList()
		{
			return new List<Schema.SObjectField> {
			ContentDocument.id,
			ContentDocument.Title,
			ContentDocument.OwnerId,
			ContentDocument.CreatedDate //DCP-42926
			};
		}
		
	/**
    *  @author Pankaj Singla
    *  @description To Fetch all the Documents uploaded
    *  @param strDocID
    *  @return List<ContentDocument>- Documents
    **/
		public List<ContentDocument> selectById(String strDocID) 
		{

			ilib_LogQuery logger = null;
			if(Feature.isOn(SERVICE_QUERY_LOGS)) {
				logger = new ilib_LogQuery(LOG_TITLE + '.selectById', strDocID);
			}
			List<ContentDocument> res = (List<ContentDocument>) Database.query(
				newQueryFactory().setCondition('Id =:strDocID').toSOQL()
			);

			if(Feature.isOn(SERVICE_QUERY_LOGS)) {
				logger.stop(res.size());
			}
	
			return res;
		}

	/**
    *  @author KD
    *  @description To Fetch all the Documents uploaded
    *  @param Lists of ID
    *  @return List<ContentDocument>- Documents
    **/
	public List<ContentDocument> selectById(List<Id> idDocId) 
	{
		ilib_LogQuery logger = null;
		if(Feature.isOn(SERVICE_QUERY_LOGS)) {
			logger = new ilib_LogQuery(LOG_TITLE + '.selectById');
		}
		List<ContentDocument> res = (List<ContentDocument>) Database.query(
			newQueryFactory().setCondition('Id =: idDocId').toSOQL()
		);

		if(Feature.isOn(SERVICE_QUERY_LOGS)) {
			logger.stop(res.size());
		}

		return res;
	}
}
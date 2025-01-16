/*   @author Adyasha Satapathy
*    @date   11-Dec-2020
*    @description   Selector Class for Knowledge Sync Mapping
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------
*    Developer              Date                    Description
*    Adyasha Satapathy      20-Nov-2020             DCP-43401: Selector Class
*    Gladis                 22-Sep-2022         Added Query Instrumentation
*    ------------------------------------------------------------------------------------------------------------- 
*                    
*/
public with sharing class KnowledgeSyncMappingSelector extends ilib_SObjectSelector{
  
    private static final string  LOG_TITLE = 'KnowledgeSyncMappingSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
  /**
   *  @author  Adyasha Satapathy
   *  @description getSObjectType
   *  @return sObjectFieldList list of Schema
   **/
    public Schema.SObjectType getSObjectType()
    {
         return Knowledge_Sync_Mapping__mdt.sObjectType;
    }

    /**
   *  @author  Adyasha Satapathy
   *  @description Retrieve list of fields for Knowledge Sync Mapping Metadata type 
   *  @return sObjectFieldList list of Schema.SObjectField
   **/
  public List<Schema.SObjectField> getSObjectFieldList()
  {
     return new List<Schema.SObjectField> {
        Knowledge_Sync_Mapping__mdt.Type__c,
    Knowledge_Sync_Mapping__mdt.Value__c,
    Knowledge_Sync_Mapping__mdt.DeveloperName,
    Knowledge_Sync_Mapping__mdt.MasterLabel
     };
  }

  /**
   *  @author Adyasha Satapathy
   *  @description Fetch Knowledge Knowledge Sync Mapping Metadata Records 
   *  @param void
   *  @return list of Knowledge Sync mapping metadata records
   **/
  public List<Knowledge_Sync_Mapping__mdt> selectKnowledgeSyncMapping() 
  {
    String strQuery = newQueryFactory().toSOQL();
    System.debug('@@@@AD ' +strQuery);
    ilib_LogQuery logger = null;
    if(Feature.isOn(SERVICE_QUERY_LOGS)) {
      logger = new ilib_LogQuery(LOG_TITLE + '.selectKnowledgeSyncMapping');
    }

    List<Knowledge_Sync_Mapping__mdt> res = (List<Knowledge_Sync_Mapping__mdt>) Database.query(strQuery);
    
    if(Feature.isOn(SERVICE_QUERY_LOGS)) {
      logger.stop(res.size());
    }
    return res;
  }
}
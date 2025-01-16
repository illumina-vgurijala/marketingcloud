/**
*    @author Nesar Mohan
*    @date   29th June 2022
*    @description    Class to get the User record access object records 
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                        Description
*    Nesar Mohan               29th June 2022                 Initial Version
*    Gladis                    27-Jan-2023                 DCP-52696 Added method selectUserRecordAccessByUserAndSetRecordId
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class UserRecordAccessSelector extends ilib_SObjectSelector {
    private static final String LOG_TITLE = 'UserRecordAccessSelector';
    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
    /**
    *  @author Nesar Mohan
    *  @description To get sobjectList
    *  @return SObjectType The Schema.SObjectType of the Line Items
    **/
    public Schema.SObjectType getSObjectType() {
        return UserRecordAccess.sObjectType;
    }

    /**
    *  @author  Nesar Mohan
    *  @description Retrieve list of fields for UserRecordAccess object
    *  @return sObjectFieldList list of Schema.SObjectField
    **/

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            UserRecordAccess.RecordId,
            UserRecordAccess.HasEditAccess,
            UserRecordAccess.HasDeleteAccess,
            UserRecordAccess.HasTransferAccess,
            UserRecordAccess.HasAllAccess,
            UserRecordAccess.MaxAccessLevel
        };
    }

// To retrigger the deployment of this file.

    /**
    *  @author  Nesar Mohan
    *  @description Fetch UserRecordAccess records based on UserId and RecordId
    *  @return userId, RecordId
    **/
    public List<UserRecordAccess> selectUserRecordAccessByUserAndRecordId(Id userId,Id recordId) {

        ilib_LogQuery logger = null;
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectUserRecordAccessByUserAndRecordId', userId+'~'+recordId);
        }
        String strQuery = 'SELECT RecordId,HasEditAccess,HasDeleteAccess,HasTransferAccess,HasAllAccess,MaxAccessLevel FROM UserRecordAccess WHERE UserId = \''+userId+'\' AND RecordId = \''+recordId+'\'';        
        List<UserRecordAccess> res = (List<UserRecordAccess>) Database.query(strQuery);        
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }

    /**
    *  @author  Gladis
    *  @description DCP-52696 Fetch UserRecordAccess records based on UserId and set of RecordIds
    *  @return userId, Set of RecordIds
    **/
    public List<UserRecordAccess> selectUserRecordAccessByUserAndSetRecordId(Id userId,Set<Id> setIds) {

        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectUserRecordAccessByUserAndSetRecordId', UtilsCollection.serializeIds(setIds));
        }

        String strQuery = 'SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = \''+userId+'\' AND RecordId IN:setIds';
        List<UserRecordAccess> res = (List<UserRecordAccess>) Database.query(strQuery); 

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
}

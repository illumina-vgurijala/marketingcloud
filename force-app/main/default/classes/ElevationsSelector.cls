/**
* @author Prerna Agrawal
* @date 03 Jan 2022
*
* @description DCP-49679 Selector Class for Elevations Object	
*/
public with sharing class ElevationsSelector extends ilib_SObjectSelector {  
    private static final String LOG_TITLE = 'ElevationsSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /**
    * @description Constructor
    * @author  | 04-14-2022 
    * @return Schema.SObjectType 
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Elevations__c.sObjectType;
    }

    /**
    * @description Get Fields list
    * @author  | 04-14-2022 
    * @return List<Schema.SObjectField> 
    **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>
        {
            Elevations__c.Elevation_Status__c,
            Elevations__c.Elevation_Owner__c,
            Elevations__c.Elevation_Manager__c,
            Elevations__c.OwnerId,
            Elevations__c.Elevation_Status__c

        };
    }
    /**
    * @description Get elevation fields
    * @author | 04-14-2022 
    * @param setElevationIds 
    * @return List<Elevations__c> 
    **/
    public List<Elevations__c> selectElevations(Set<Id> setElevationIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectElevations', UtilsCollection.serializeIds(setElevationIds));

        List<Elevations__c> res = (List<Elevations__c>) Database.query(
            newQueryFactory()
            .selectField('Case__r.OwnerId')
            .selectField('Work_Order__r.OwnerId')
            .selectField('Work_Order__r.SVMXC__Company__r.OwnerId')
            .selectField('Case__r.Case_Owner_s_Manager_Email__c')
            .selectField('Account_Owner_Email__c')
            .selectField('Case__r.Region__c')
            .setCondition('ID IN : setElevationIds ')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
                logger.stop(res.size());
    
        return res;
    }
    
    /**
    * @description DCP: 49669:  Query to access elevation record Ids whose elevation status is open
    * @author Vatsal | 04-05-2022 
    * @param setElevationIds 
    * @param strElevationStatus 
    * @return List<Elevations__c> 
    **/
    public List<Elevations__c> selectElevationByElevationStatus(Set<Id> setElevationIds, String strElevationStatus) {
        ilib_LogQuery logger=null;
       
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectElevationByElevationStatus', UtilsCollection.serializeIds(setElevationIds));
        }
        String strQuery = newQueryFactory()
            .selectField('Id')
            .selectField('Elevation_Status__c')
            .setCondition('(ID IN : setElevationIds) AND (Elevation_Status__c = : strElevationStatus)') 
            .toSOQL();
            
        List<Elevations__c> res = (List<Elevations__c>) Database.query(strQuery);
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

      /**
    * @description DCP: 52224:  Query to access elevation record Ids whose elevation category is Hot Site
    * @author Rohan | 30-05-2022 
    * @param setElevationIds 
    * @param strElevationStatus 
    * @return List<Elevations__c> 
    **/
    public List<Elevations__c> selectElevationByCategory(Set<Id> setElevationIds, String strElevationCategory) {
        ilib_LogQuery logger=null;
       
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectElevationByCategory', UtilsCollection.serializeIds(setElevationIds));
        }
        String strQuery = newQueryFactory()
            .selectField('Id')
            .selectField('Elevation_Status__c')
            .selectField('Elevation_Category__c')
            .selectField('Work_Order__c')     
            .setCondition('(ID IN : setElevationIds) AND (Elevation_Category__c = : strElevationCategory)') 
            .toSOQL();
            
        List<Elevations__c> res = (List<Elevations__c>) Database.query(strQuery);
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }
}
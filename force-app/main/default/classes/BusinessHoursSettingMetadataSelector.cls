/**
 * @author Venkatesh Prabhu
 * @date 2024-11-28
 * @description This class is used to get the Business Hours Setting metadata records
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *             Venkatesh Prabhu            28 Nov 2024           Initial Build	
 *    ------------------------------------------------------------------------------------------- 
 */
public with sharing class BusinessHoursSettingMetadataSelector extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'BusinessHoursSettingMetadataSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
    /**
     * @author Venkatesh Prabhu
     * @Description : method to get the sObject type
     * @return  `Schema.SObjectType`
     */
    public Schema.SObjectType getSObjectType()
    {
        return Business_Hours_Setting__mdt.sObjectType;
    }
    
    /**
     * @author Venkatesh Prabhu
     * @description : method to get the list of fields for Business_Hours_Setting__mdt sObject
     * @return  `List<Schema.SObjectField>`
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
        Business_Hours_Setting__mdt.Id,
        Business_Hours_Setting__mdt.DeveloperName,
        Business_Hours_Setting__mdt.StartTimeOfTheDay__c,
        Business_Hours_Setting__mdt.EndHourOfTheDay__c,
        Business_Hours_Setting__mdt.Rejection_Hour_For_SLA_Post_Next_Day__c,
        Business_Hours_Setting__mdt.Rejection_Hour_For_SLA_Next_Day__c          
       };
    }
    
    /**
     * @author Venkatesh Prabhu
     * @description : Get Default Business Hour Setting  metadata records.
     * @param  `String defaultBusinessHourSetting`
     * @return  `List<Business_Hours_Setting__mdt>`
     */
    public List<Business_Hours_Setting__mdt> selectDefaultBusinessHourSetting(String defaultBusinessHourSetting){
       
        ilib_LogQuery logger = null;

        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectDefaultBusinessHourSetting');
        }

        List<Business_Hours_Setting__mdt> res = (List<Business_Hours_Setting__mdt>) Database.query(
            newQueryFactory()
            .setCondition('DeveloperName =: defaultBusinessHourSetting')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
}
/**
 *    @author Dushyant Srivastava
 *    @date   2021-10-08
 *    @description    Class to get the TimeZone records based on different conditions 
 *    Modification Log:
 *   ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Dushyant Srivastava            2021-10-08          Initial Version
 *    ------------------------------------------------------------------------------------                  
 */

public with sharing class TimeZoneSelector extends ilib_SObjectSelector {
    /**
     *  @author Dushyant Srivastava
     *  @description
     *  @return SObjectType The Schema.SObjectType of the Time Zones
     **/
    public Schema.SObjectType getSObjectType(){
        return Time_Zones__mdt.sObjectType;
    }

    /**
    *  @author  Dushyant Srivastava
    *  @description Retrieve list of fields for Time Zone Metadata type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Time_Zones__mdt.Id,
            Time_Zones__mdt.Hour__c,
            Time_Zones__mdt.Time_Zones__c
        };
    }

    /**
     *  @author Dushyant Srivastava
     *  @description fetch TimeZone
     *  @param Integer Hour
     *  @return list of Time Zones
     **/
    public List<Time_Zones__mdt> selectByHour(Integer hour) { 
        return (List<Time_Zones__mdt>) Database.query(
                      newQueryFactory()
                      .setCondition('Hour__c =: hour')
                      .toSOQL());
                     
    }
}
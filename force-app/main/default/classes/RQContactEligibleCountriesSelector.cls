/**
*    @author Govind Dubey
*    @date   12th November 2018
*    @description    Class to get the Custom Metadata records for Code Parameter 
*    Modification Log:
*   ----------------------------------------------------------------------------------------- 
*    Developer                      Date                		Description
*	 Balakrishna					22-August-2023
*    ---------------------------------------------------------------------------------------                
*/

public with sharing class RQContactEligibleCountriesSelector extends ilib_SObjectSelector{
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String LOG_TITLE = 'RQContactEligibleCountriesSelector';
    
    
    /*Param - sobjectList  */
    public Schema.SObjectType getSObjectType()
    {
        return R_Q_Contact_Eligible_Countries__mdt.sObjectType;
    }
    
    /**
    *  @author  
    *  @description Retrieve list of fields for Code Parameter Metadata type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            R_Q_Contact_Eligible_Countries__mdt.DeveloperName,
                R_Q_Contact_Eligible_Countries__mdt.CountryCode__c,
                R_Q_Contact_Eligible_Countries__mdt.CountryName__c,
                R_Q_Contact_Eligible_Countries__mdt.Countries__c,
                R_Q_Contact_Eligible_Countries__mdt.Description__c
                };
      }
    
    /**
    *  @author Govind Dubey
    *  @description Fetch Code Parameter records based on Developer name of metadata
    *  @return list of Code Parameter records
    **/
    public List<R_Q_Contact_Eligible_Countries__mdt> selectRQContactEligibleByDeveloperName(set<String> setRQContactEligibleDeveloperName){
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.setRQContactEligibleDeveloperName', UtilsCollection.serializeIds(setRQContactEligibleDeveloperName));
        List<R_Q_Contact_Eligible_Countries__mdt> res = (List<R_Q_Contact_Eligible_Countries__mdt>) Database.query(
            newQueryFactory()
            .selectField('Countries__c')  //added here so that all methods does not add to SOQL limit
            .setCondition('DeveloperName IN :setRQContactEligibleDeveloperName').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
    return res;
    }
}
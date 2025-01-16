/**
*    @author Govind Dubey
*    @date   12th November 2018
*    @description    Class to get the Custom Metadata records for Code Parameter 
*    Modification Log:
*   ----------------------------------------------------------------------------------------- 
*    Developer                      Date                		Description
*    Govind Dubey                  12th November 2018          Initial Version
*    Pooja Shalwadi                22-Sep-2022                 Added Query Instrumentation 
*    Shivani                       24-Nov-2022                 DCP-57074: Added new method 
*                                                              selectCodeParameterByDeveloperNameLike
*    ---------------------------------------------------------------------------------------                
*/
public with sharing class CodeParametersSelector extends ilib_SObjectSelector{
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String LOG_TITLE = 'CodeParametersSelector';
    
    /*Param - sobjectList  */
    public Schema.SObjectType getSObjectType()
    {
        return Code_Parameter__mdt.sObjectType;
    }    
    
    /**
    *  @author  Govind Dubey
    *  @description Retrieve list of fields for Code Parameter Metadata type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Code_Parameter__mdt.DeveloperName,
                Code_Parameter__mdt.PicklistValue__c,
                Code_Parameter__mdt.Values_Text__c
                };
                    }
    /**
    *  @author Govind Dubey
    *  @description Fetch Code Parameter records based on Developer name of metadata
    *  @return list of Code Parameter records
    **/
    public List<Code_Parameter__mdt> selectCodeParameterByDeveloperName(set<String> setCodeParameterDeveloperName){
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeParameterByDeveloperName', UtilsCollection.serializeIds(setCodeParameterDeveloperName));
        List<Code_Parameter__mdt> res = (List<Code_Parameter__mdt>) Database.query(
            newQueryFactory()
            .selectField('Value__c')  //added here so that all methods does not add to SOQL limit
            .setCondition('DeveloperName IN :setCodeParameterDeveloperName').toSOQL()
        );
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
    return res;
    }

    /*******************************************************************************************************
    * @description  DCP-57074 Method to query Code Parameters starting with specific Developer Name
    * @param startsWithKey String
    * @return List<Code_Parameter__mdt>
    */
    public List<Code_Parameter__mdt> selectCodeParameterByDeveloperNameLike(String startsWithKey){
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeParameterByDeveloperNameLike', startsWithKey);
        }

        String startsWithKeyParam = startsWithKey + '%';
        List<Code_Parameter__mdt> res = (List<Code_Parameter__mdt>) Database.query(
            newQueryFactory().setCondition('DeveloperName like : startsWithKeyParam').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
    
}
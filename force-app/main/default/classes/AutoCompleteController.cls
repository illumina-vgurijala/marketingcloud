/***************************************************************************************************************************************
* NAME   : AutoCompleteController 
* DESCRIPTION  : Controller class
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------------------
*      Developer                       Date                Description
*                                                          Initial Version
*     -------------------------------------------------------------------------------------------------------------------------------------------------
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class AutoCompleteController {

    @AuraEnabled(cacheable = true)
	
	/*
    * @Description- Fetch sObject records
    * @return - SOQL result
    */
    public static List < SObject > getRecords(String searchString, String objectApiName, String idFieldApiName, String valueFieldApiName, String extendedWhereClause, Integer maxRecords) {
        
        //variables passed from lightning component.
        searchString = String.escapeSingleQuotes(searchString);
        objectApiName = String.escapeSingleQuotes(objectApiName);
        idFieldApiName = String.escapeSingleQuotes(idFieldApiName);
        valueFieldApiName = String.escapeSingleQuotes(valueFieldApiName);
		
        //used so that dynamic soql does not give error.
        if (extendedWhereClause == null) {
            extendedWhereClause = '';
        }

        if(objectApiName == 'Case'){
            //remove Elevation record type  
            Id elevationRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Elevation').getRecordTypeId();  
            extendedWhereClause = ' AND RecordTypeId !=\'' + String.escapeSingleQuotes(elevationRecordTypeId) + '\'  ';   
        }
        
        //dynamic soql.
        String query = 'SELECT ' + String.escapeSingleQuotes(idFieldApiName) + ', ' + String.escapeSingleQuotes(valueFieldApiName) + ' FROM ' + String.escapeSingleQuotes(objectApiName) + ' WHERE ' + String.escapeSingleQuotes(valueFieldApiName) + ' LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\' ' + extendedWhereClause + ' LIMIT ' + maxRecords;
        system.debug('query = ' + query);
        
        return Database.query(query);
    }
}
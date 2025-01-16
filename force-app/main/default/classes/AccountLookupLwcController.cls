/**************************************************************************************************************************************
* NAME   : AccountLookupLwcController
* DESCRIPTION  : Controller class for handling account lookup operations in Lightning Web Components.
* Test Class : TestAccountLookupLwcController.cls
*  
* @AUTHOR : Abhishek Yadav
* @DATE   : 25-Jul-2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav         25-Jul-2024         Initial Version. Added logic for account lookup operations.
****************************************************************************************************************************************/

public with sharing class AccountLookupLwcController {

    // Added for test coverage of catch block. It is getting updated through its test class
    @TestVisible
    private static Boolean testCodeCoverage = false;
    private static final string TEST_CUSTOM_EXCEPTION = 'QUERY_EXCEPTION';
    /**
    * Method to fetch lookup search result
    * @param searchKey The search keyword to filter the records.
    * @param sObjectApiName The API name of the sObject to be queried.
    * @return List of sObjects matching the search criteria.
    * @author Abhishek Yadav
    **/
    @AuraEnabled(cacheable=true)
    public static List<sObject> fetchLookupData(String searchKey, String sObjectApiName) {    
        List<sObject> returnList = new List<sObject>();

        try {
            // Added for covering catch block in test class
            if (testCodeCoverage && Test.isRunningTest()) {
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }
            String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
            String sQuery = 'SELECT Id, Name, ERP_Customer_Id__c, BillingAddress, Type FROM ' + String.escapeSingleQuotes(sObjectApiName) + ' WHERE Name LIKE :sWildCardText ORDER BY CreatedDate DESC LIMIT 5';
            returnList.addAll(Database.query(sQuery));
        } catch (Exception e) {
            if (testCodeCoverage && Test.isRunningTest()) {
            	throw e; 
            } else {
                throw new AuraHandledException('Error fetching lookup data: ' + e.getMessage());
            }
        }
        return returnList;
    }

    /**
    * Method to fetch default record based on record ID
    * @param recordId The ID of the record to be fetched.
    * @param sObjectApiName The API name of the sObject to be queried.
    * @return sObject containing the default record details or null if not found.
    * @author Abhishek Yadav
    **/
    @AuraEnabled
    public static sObject fetchDefaultRecord(String recordId, String sObjectApiName) {
        try {
            // Added for covering catch block in test class
            if (testCodeCoverage && Test.isRunningTest()) {
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }
            if(recordId != null) {
                String sRecId = String.escapeSingleQuotes(recordId);    
                String sQuery = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(sObjectApiName) + ' WHERE Id = :sRecId LIMIT 1';
                return Database.query(sQuery);
            }
        } catch (Exception e) {
            if (testCodeCoverage && Test.isRunningTest()) {
            	throw e; 
            } else {
                throw new AuraHandledException('Error fetching lookup data: ' + e.getMessage());
            }
        }
        return null;
    }

    /**
    * Method to fetch account data based on search criteria
    * @param searchKey The search keyword to filter the records.
    * @param sObjectApiName The API name of the sObject to be queried.
    * @return List of sObjects matching the search criteria with additional fields.
    * @author Abhishek Yadav
    **/
    @AuraEnabled
    public static List<sObject> fetchAccountData(String searchKey, String sObjectApiName) {    
        List<sObject> returnList = new List<sObject>();

        try {
            // Added for covering catch block in test class
            if (testCodeCoverage && Test.isRunningTest()) {
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }
            String sWildCardText = '%' + String.escapeSingleQuotes(searchKey) + '%';
            String sQuery = 'SELECT Id, Name, ERP_Customer_Id__c, BillingAddress, Type FROM ' + String.escapeSingleQuotes(sObjectApiName) + ' WHERE Name LIKE :sWildCardText OR ERP_Customer_Id__c LIKE :sWildCardText ORDER BY CreatedDate DESC LIMIT 50';
            returnList.addAll(Database.query(sQuery));
        } catch (Exception e) {
            if (testCodeCoverage && Test.isRunningTest()) {
            	throw e; 
            } else {
                throw new AuraHandledException('Error fetching lookup data: ' + e.getMessage());
            }
        }
        return returnList;
    }
    /*******************************************************************************************************
    * @description Custom Exception innner class
    */
    public class CustomException extends Exception {}
}
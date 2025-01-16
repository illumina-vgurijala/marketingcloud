/**  @author Illumina
*    @date   Not available
*    @description    Class to get upto 5 records of any SObjects
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Jitesh Lakhwani                6-July-2022             Code Scan fixes of Comments
*    ------------------------------------------------------------------------------------                  
*/

public with sharing class CustomLookupController {

    /**
    * @description: Custom method to search records from any SObjects.
    * @param : String searchKey, String objectName, String searchField
    * @return: List<SObject>
    */
    @AuraEnabled(cacheable = true)
    public static List<SObject> findRecords(String searchKey, String objectName, String searchField){
        String key = '%' + searchKey + '%';
        String query = 'Select Id, '+searchField+' From '+objectName +' Where '+searchField +' LIKE '+'\''+key+'\' LIMIT 5';
        System.debug(System.LoggingLevel.DEBUG, query);
        List<SObject> sObjectList = Database.query(query);
        return sObjectList;
    }
}
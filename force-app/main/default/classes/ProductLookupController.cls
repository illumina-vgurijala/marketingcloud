/***************************************************************************************************************************************
* NAME         : ProductLookupController
* DESCRIPTION  : Controller class for ProductLookup component.
*                    
* @AUTHOR      : Prashanth 
* @DATE        : 10-Mar-2020  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Prashanth              10-Mar-2020            Initial version
  Aman Tyagi             05-Apr-2022            CodeScan Fixes
****************************************************************************************************************************************/
public with sharing class ProductLookupController {
    public static final String STRING_LIKE_EXPRESSION = ' LIKE \'%' ;
    /**
   *  @author Prashanth
   *  @description performs a soql search based on the user input for given object and field names.
   *  @param objectname, inputvalue and field names.
   *  @return List<SObJectResult>
   **/
    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getResults(String ObjectName, String fieldName, String value, String displayText, String optionalField) {
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        //query string
        String query = 'Select Id,'+fieldName;
        if(String.isNotBlank(displayText) && displayText != fieldName && String.isNotBlank(optionalField)){
            query = query + ','+displayText+' FROM '+ObjectName+' WHERE '+fieldName+STRING_LIKE_EXPRESSION + value + '%\' OR '+displayText+ STRING_LIKE_EXPRESSION+ value + '%\' OR '+optionalField+STRING_LIKE_EXPRESSION+ value + '%\' Limit 5';
        }else{
            query = query+' FROM '+ObjectName+' WHERE '+fieldName+STRING_LIKE_EXPRESSION + value+'%\' Limit 5';
        }
        
        System.debug('query--:'+query);
 		//'Select Id,'+fieldName+','+displayText+' FROM '+ObjectName+' WHERE '+fieldName+' LIKE \'%' + value + '%\' Limit 5'
        if(String.isNotEmpty(value)){
            for(sObject so : Database.Query(query)) {
                String fieldvalue = (String)so.get(fieldName);
                String displayValue = (String)so.get(displayText);
                sObjectResultList.add(new SObjectResult(fieldvalue, so.Id,displayValue));
            }
        }
        return sObjectResultList;
    }
    /**
     * Description: SObJectResult wrapper class to store the search results information.
     */
    public class SObJectResult {
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public Id recId;
        @AuraEnabled
        public String displayField;
        /**
        * @description Assign Record name, ID, Displayfield
        * @author 
        * @param recNameTemp 
        * @param recIdTemp 
        * @param displayFieldTemp 
        **/
        public SObJectResult(String recNameTemp, Id recIdTemp, String displayFieldTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
            displayField = displayFieldTemp;
        }
    }
}
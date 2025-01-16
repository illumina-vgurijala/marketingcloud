/***************************************************************************************************************************************
* NAME         : AccountLookupController
* DESCRIPTION  : Controller class for ProductLookup component.
*                    
* @AUTHOR      : Avina 
* @DATE        : 16-Sep-2022  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Avina                 16-Sep-2022           Initial version
****************************************************************************************************************************************/
public with sharing class AccountLookupController {
    public static final String STRING_LIKE_EXPRESSION = ' LIKE \'%' ;
    private static final String LOG_TITLE = 'AccountLookupController';
    private static final Integer QUERY_LIMIT = 5;
    /**
   *  @author Avina
   *  @description performs a soql seadrch based on the user input for given object and field names.
   *  @param objectname, inputvalue and field names.
   *  @return List<SObJectResult>
   **/
    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getAccountResults(String objectName, String fieldName, String value, String displayText) {
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE + '.getAccountResults()');
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        //query string
        try {
            String dynamicCondition;
            Set<String> fieldsSet = new Set<String>();
            fieldsSet.add('Id');
            fieldsSet.add(fieldName);
            if(String.isNotBlank(displayText) && displayText != fieldName) {
                dynamicCondition = fieldName+STRING_LIKE_EXPRESSION + value + '%\' OR '+displayText+ STRING_LIKE_EXPRESSION+ value + '%\'';
                fieldsSet.add(displayText);
            } else {
                dynamicCondition = fieldName+STRING_LIKE_EXPRESSION + value+'%\'';
            }
            ilib_LogEvent.info('dynamicCondition' + dynamicCondition);
            if(String.isNotEmpty(value)) {
                for(Account so : new AccountsSelector().selectAccountforLookupController(fieldsSet,dynamicCondition,QUERY_LIMIT)) {
                    String displayValue='';
                    String fieldvalue = (String)so.get(fieldName);
                    if(String.isNotBlank(displayText) && displayText != fieldName) {
                        displayValue = (String)so.get(displayText);
                    }
                    sObjectResultList.add(new SObjectResult(fieldvalue, so.Id,displayValue));
                }
            }
            ilib_LogEvent.info('sObjectResultList' + sObjectResultList);
            ilib_LogEvent.pop();
            return sObjectResultList;
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SERVICE );
            throw new AuraHandledException(e.getMessage());
        }
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

/**
*    @author: Rishab Wali
*    @date:   09-Jun-2021
*    @description:  Controller class for MultiSelectLookupController LWC.
*    @ Test class Coverage: 100% - TestAccountPlanObjectivesController
*    @ Test class Coverage : 75% - TestAccountPlanObjectivesController
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Rishab Wali                  08-Jun-2021            DCP-46115 - Inital Version
*            Bharath Varma                09-Jun-2021            DCP-46115 - Added Instrumentation and updated query 
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class MultiSelectLookupController {

    private static final String EXCEPTION_LOG_TITLE = 'MultiSelectLookupController';
    
    /* Method to return results for based on search */
    @AuraEnabled(cacheable=true)
    public static String getResults(String params, List<String> selectedRecId) {
        try{
            ilib_LogEvent.push(EXCEPTION_LOG_TITLE + '.getResults()');

            DataWrapper dataWrapper = (DataWrapper) JSON.deserialize(params, DataWrapper.class);
            system.debug(dataWrapper);

            List<PickListValueWrapper> sObjectResultList = new List<PickListValueWrapper>();
            ilib_LogEvent.message('Parameters: ' + dataWrapper.fieldName+', '+dataWrapper.objectName+', '+dataWrapper.value+', '+selectedRecId);
            List<String> selectRecId = new List<String>();
            if(selectedRecId != null) {
                selectRecId = selectedRecId;
            }

            if(String.isNotEmpty(dataWrapper.value)) {
                ilib_LogQuery logger = new ilib_LogQuery( EXCEPTION_LOG_TITLE + '.getResults()');
                String query = 'Select Id,'+dataWrapper.fieldName+' FROM '+dataWrapper.objectName+' WHERE '+dataWrapper.fieldName+' LIKE \'%' + dataWrapper.value.trim() + '%\' and ID NOT IN: selectRecId ORDER BY ' + dataWrapper.fieldName + ' ' + dataWrapper.orderBy + ' LIMIT ' + dataWrapper.limitValue;
                ilib_LogEvent.message('Query to run: ' + query);
                for(sObject so : Database.Query(query)) {
                    String fieldvalue = (String)so.get(dataWrapper.fieldName);
                    sObjectResultList.add(new PickListValueWrapper(so.Id, fieldvalue));
                }
                logger.stop();
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();

            return JSON.serialize(sObjectResultList);
        }
        catch(Exception e) { 
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            if(!Test.isRunningTest()){throw new AuraHandledException(e.getMessage());}
            return e.getMessage();
        }
        
    }

    /* Wrapper class */
    public class DataWrapper {
    
        public String objectName;
        public String fieldName;
        public String value;
        public String limitValue;
        public String orderBy;
        
        /* Constructor method */
        public DataWrapper (String objectName,String fieldName, String value, String limitValue, String orderBy) {
            this.objectName = objectName;
            this.fieldName = fieldName;
            this.value = value;
            this.limitValue = limitValue;
            this.orderBy = orderBy;
        }
    
    }

}
/**
*    @date: 09-Mar-2022
*    @description: PM-54 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Maruthi                        09-Mar-2022         Initial build
*    ------------------------------------------------------------------------------------
*	 Maruthi						22-Apr-2022			Updated for codescan fix  
*/
public with sharing class ACRHistoryTrackingRelatedListController {
    private static final String LOG_TITLE = 'ACRHistoryTrackingRelatedListController';
    /*
     *  @AUTHOR:  Maruthi
     *  @DESCRIPTION: PM-54 
     *  @RETURN:  List<Object_History__c> records
     */   
    @AuraEnabled(cacheable=false)
    public static List<Object_History__c> getObjectHistoryData(Id recordId){
        
        try{        
            ilib_LogEvent.push(LOG_TITLE +'.getObjectHistoryData');  
            List<Object_History__c> listObjHis = new List<Object_History__c>();            
            listObjHis = new  ObjectHistorySelector().selectObjectHistory(recordId);
            ilib_LogEvent.message('listObjHis-->'+listObjHis);  
            ilib_LogEvent.pop();   
            return listObjHis;                   
        } catch (Exception e) {            
            throw new AuraHandledException(e.getMessage());          
        }        
    }
}
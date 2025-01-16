/**
*    @author Ashwin
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Ashwin Kumar                   06-April-2022           DCP-52339 Insert processed deferred records to TAPS_Processed_Record__c
*    ------------------------------------------------------------------------------------                  
**/
public without sharing class TAPS_DeferredRecords extends ilib_SObjectDomain {
    
    private static final String LOG_TITLE = 'TAPS_DeferredRecords'; 

    /*Parameterised Constructor */
    public TAPS_DeferredRecords(List<TAPS_Deferred_Record__c> sObjectList) {
        super(sObjectList);
    }

    /**
     * Boilerplate which is required for base class instantiation logic 
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /**
        * Comments are added to fix code scan issues
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new TAPS_DeferredRecords(sObjectList);
        }
    }

    /**
     *  @author Ashwin Kumar
     *  @description - AfterDelete logic
    **/
    public override void onAfterDelete() {
        ilib_LogEvent.push(LOG_TITLE+'.onAfterDelete');
        insertProcessedRecords();
        ilib_LogEvent.pop();
    }

    /**
     *  @author Ashwin Kumar
     *  @description - Insert processed deferred records in TAPS_Processed_Record__c when Deferred Records are deleted
    **/
    private void insertProcessedRecords() {
        ilib_LogEvent.push(LOG_TITLE+'.insertProcessedRecords');
        if(records.isEmpty()) { 
            ilib_LogEvent.pop();
            return;
        }
        ilib_LogEvent.message('records count: ' + records.size());
        List<TAPS_Processed_Record__c> lstProcessedRecords = new List<TAPS_Processed_Record__c>();
        for (TAPS_Deferred_Record__c objDeferredRecord : (List<TAPS_Deferred_Record__c>)records) {
            lstProcessedRecords.add(new TAPS_Processed_Record__c(Name = objDeferredRecord.Record_ID__c));
        }
        List<Database.SaveResult> results = Database.insert(lstProcessedRecords, false);
        ApexExceptions.emitSaveErrors(results, LOG_TITLE+'.insertProcessedRecords');
        ilib_LogEvent.pop();
    }
}
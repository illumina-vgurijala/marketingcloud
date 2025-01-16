/**
*    @author Ashwin
*    @date   2021
*    @description  TAPS Deferred Record Selector
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                     Date                   Description
*         Ashwin                        30-Mar-2022            DCP-52339
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class TAPSDeferredRecordSelector extends ilib_SObjectSelector {
    
    private static final String LOG_TITLE = 'TAPSDeferredRecordSelector';
    private static final String SALES_QUERY_LOGS = 'SalesQueryLogs';

    /**
     *  @author Ashwin Kumar
     *  @description
     *  @return SObjectType The Schema.SObjectType of the TAPS Deferred Record
    **/
    public Schema.SObjectType getSObjectType() {
        return TAPS_Deferred_Record__c.sObjectType;
    }

    /**
    *  @author  Ashwin Kumar
    *  @description Retrieve list of fields for TAPS_Deferred_Record__c
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            TAPS_Deferred_Record__c.Id,
            TAPS_Deferred_Record__c.Record_ID__c,
            TAPS_Deferred_Record__c.Object_Name__c,
            TAPS_Deferred_Record__c.Is_Processing__c,
            TAPS_Deferred_Record__c.CreatedDate
        };
    }

    /**
     *  @author Ashwin
     *  @description Get Deferred Records by Object Names
     *  @param setObjectName, maxDeferredRecordsToExecute
     *  @return List of TAPS_Deferred_Record__c 
     **/
    public List<TAPS_Deferred_Record__c> getUnprocessedDeferredRecsByObjectNames(Set<String> setObjectName, Integer maxDeferredRecordsToExecute) {
        
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERY_LOGS)) { 
            logger = new ilib_LogQuery(LOG_TITLE + '.getUnprocessedDeferredRecsByObjectNames', setObjectName.toString());
        }

        List<TAPS_Deferred_Record__c> lstDeferredRecords = (List<TAPS_Deferred_Record__c>) Database.query(
            newQueryFactory()
            .setCondition('Object_Name__c IN :setObjectName AND Is_Processing__c = false')
            .addOrdering('Object_Name__c', ilib_QueryFactory.SortOrder.DESCENDING)
            .addOrdering('CreatedDate', ilib_QueryFactory.SortOrder.ASCENDING)
            .setLimit(maxDeferredRecordsToExecute)
            .toSOQL()
        );

        if (Feature.isOn(SALES_QUERY_LOGS)) { logger.stop(lstDeferredRecords.size()); }
        return lstDeferredRecords;
    }

    /**
     *  @author Ashwin
     *  @description Get Aggregate results of unprocessed Deferred Records by Object Names having recordId count > 0
     *  @return List of AggregateResult 
     **/
    public List<AggregateResult> getAggregateOfUnprocessedDeferredRecords() {
        
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERY_LOGS)) { 
            logger = new ilib_LogQuery(LOG_TITLE + '.getAggregateOfUnprocessedDeferredRecords');
        }
        
        String query = 'SELECT Object_Name__c, count(id) '+
                        'FROM TAPS_Deferred_Record__c WHERE Object_Name__c != null AND Is_Processing__c = false '+
                        'GROUP BY Object_Name__c HAVING count(id) > 0 ORDER BY Object_Name__c DESC';
        List<AggregateResult> lstAggregateResults = (List<AggregateResult>) Database.query(String.escapeSingleQuotes(query));

        if (Feature.isOn(SALES_QUERY_LOGS)) { logger.stop(lstAggregateResults.size()); }
        return lstAggregateResults;
    }

}
/**
*    @author Ashwin
*    @date   2021
*    @description  TAPS Deferred Record Selector
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                     Date                   Description
*         Ashwin                        31-Mar-2022            DCP-52339
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class CustomerReadinessFormSelector extends ilib_SObjectSelector {
    private static final String LOG_TITLE = 'CustomerReadinessFormSelector';
    private static final String SALES_QUERY_LOGS = 'SalesQueryLogs';

    /**
     *  @author Ashwin Kumar
     *  @description
     *  @return SObjectType The Schema.SObjectType of Customer_Readiness_Form__c
    **/
    public Schema.SObjectType getSObjectType() {
        return Customer_Readiness_Form__c.sObjectType;
    }

    /**
    *  @author  Ashwin Kumar
    *  @description Retrieve list of fields for Customer_Readiness_Form__c
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Customer_Readiness_Form__c.Id,
            Customer_Readiness_Form__c.Opportunity_Name__c
        };
    }

    /**
     *  @author Ashwin
     *  @description Get Jobs by JobType
     *  @return List of Customer_Readiness_Form__c 
     **/
    public List<Customer_Readiness_Form__c> getCRFsByIds(Set<Id> recordIds) {
        
        ilib_LogQuery logger;
        if (Feature.isOn(SALES_QUERY_LOGS)) { 
            logger = new ilib_LogQuery(LOG_TITLE + '.getCRFsByIds', UtilsCollection.serializeIds(recordIds));
        }

        List<Customer_Readiness_Form__c> lstCRFs = (List<Customer_Readiness_Form__c>) Database.query(
            newQueryFactory()
            .setCondition('Id IN: recordIds')
            .toSOQL()
        );

        if (Feature.isOn(SALES_QUERY_LOGS)) { logger.stop(lstCRFs.size()); }
        return lstCRFs;
    }
}
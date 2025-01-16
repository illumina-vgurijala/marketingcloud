/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger
*              DCP-45743 To check validation on Before Update. 

*/ 
public with sharing class CheckDataIntegrity_WOHelper {

    /**
    *  @author Gladis 
    *  @description - DCP-45743 To check validation on Before Update. 
    *                
    **/
    public static void checkDataIntegrity(Map<Id, SObject> oldRecords, List<sObject> records, Id idRemoteSupportRecordType, Id idFieldServiceRecordType, Id idEstimatesRecordTypeId) {

        ilib_LogEvent.push(WorkOrders.LOG_TITLE + '.checkDataIntegrity()');
        
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
        
            Boolean boolWasSupport =objOldWorkOrder.recordtypeId == idRemoteSupportRecordType && objOldWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WORK_ORDER_RTYPE_REMOTE_SUPPORT;
            ilib_LogEvent.message('boolWasSupport: '+boolWasSupport);
            Boolean boolWasServiceActivity = objOldWorkOrder.recordtypeId == idFieldServiceRecordType && objOldWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES;
            ilib_LogEvent.message('boolWasServiceActivity: '+boolWasServiceActivity);
            if(objWorkOrder.Recordtypeid != objOldWorkOrder.Recordtypeid 
                && objWorkOrder.recordtypeId == idEstimatesRecordTypeId
                && !boolWasSupport
                && !boolWasServiceActivity) {
                ilib_LogEvent.message('Adding error for '+objWorkOrder.id);
                objWorkOrder.addError(Label.WOCheckRecordTypeBeforeChangingToEstimates);
            }
        }
        ilib_LogEvent.pop();
    }
}

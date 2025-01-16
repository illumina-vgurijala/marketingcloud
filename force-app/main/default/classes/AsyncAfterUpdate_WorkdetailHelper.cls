/*****************************************************************************************************************
 * Class Name: AsyncAfterUpdate_WorkdetailHelper
 * Description: Helper class for async processing of after update of Work details.
 * Author: Prashanth
 * 
 * Date: 06-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth               06-12-2021        Helper class for async processing of after update of Work details.
 * 
 ******************************************************************************************************************/
public with sharing class AsyncAfterUpdate_WorkdetailHelper {
    public static Map < Id, SVMXC__Service_Order_Line__c > workDetailIdToWorkDetailMap = new Map < Id, SVMXC__Service_Order_Line__c > (); //DCP-44981
    //DCP-37747
    public static List < SVMXC__Service_Order_Line__c > lstWarningMessageUpdateWorkDetails = new List < SVMXC__Service_Order_Line__c > ();
    public static Set < Id > setNoBatchQualifiedWorkOrderIds = new Set < Id > ();
    public static Set < Id > setInsertedPartWorkDetailsIds = new Set < Id > ();
    /**
     * Method:asyncCallsAfterUpdate
     * Description: Method to process the async calls.
     * params: new records, old records.
     * return: void
     */
    public static void asyncCallsAfterUpdate(Map < Id, SObject > mapOld){
        ilib_Queueablethread  queueableThread=new ilib_Queueablethread('WorkDetailsAfterUpdate');
        Map<Id, SObject> mapNew = Trigger.newMap;
        processAfterUpdateRecords(mapOld, mapNew);
        processRecordsInQueueable(queueableThread);
        if (!setInsertedPartWorkDetailsIds.isEmpty() && !PartsOrderLines.stopPartOrderLineInsertion) {
            //DCP-33873
            queueableThread.logandQueue(new InsertPOAndPOL_WorkdetailHelper(setInsertedPartWorkDetailsIds), 'InsertPOAndPOL_WorkdetailHelper', 'insertPOAndPOLForPartSwap');
        }
        //DCP-46273 moving After update call to async
        if(!Workdetails.lstLabourWorkDetails.isEmpty()){
            queueableThread.logandQueue(new UpdateConfirmOperability_WDHelper(Workdetails.lstLabourWorkDetails, mapOld, mapNew),'UpdateConfirmOperability_WDHelper','updateConfirmOperabilityForRelocationWO');
        }
        //Added by shruti Karn to populate Product group on work order for ICE integration
        if(!AfterUpdate_WorkDetailHelper.setWOIdforICEPrdGrp.isEmpty()){
            queueableThread.logandQueue(new UpdateProductGroup_WorkdetailHelper(AfterUpdate_WorkDetailHelper.setWOIdforICEPrdGrp),'UpdateProductGroup_WorkdetailHelper','updateProductGrponWorkOrder');
        }
         
        //DCP-33466
        if(!AfterUpdate_WorkDetailHelper.setBatchQualifiedWorkOrderIds.isEmpty()){
            queueableThread.logandQueue(new WOBatchQualification_WorkdetailHelper(AfterUpdate_WorkDetailHelper.setBatchQualifiedWorkOrderIds),'WOBatchQualification_WorkdetailHelper','updateWorkOrdersForBatchQualification');
        }
        if(!setNoBatchQualifiedWorkOrderIds.isEmpty()){
             queueableThread.logandQueue(new WOBatchQualification_WorkdetailHelper( setNoBatchQualifiedWorkOrderIds),'WOBatchQualification_WorkdetailHelper','updateWorkOrdersForBatchQualification');
        }
        //DCP-37399
        if(!AfterUpdate_WorkDetailHelper.setPartConsumptionWorkOrderIds.isEmpty()){
            queueableThread.logandQueue(new QualifyWOsForConsumption_WDHelper(AfterUpdate_WorkDetailHelper.setPartConsumptionWorkOrderIds),'QualifyWOsForConsumption_WDHelper','qualifyWorkOrdersForConsumptionThroughVanstock');
        }

        if(!queueableThread.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        } 
    }
    /**
     * Method:processAfterUpdateRecords
     * Description: Method to process the after update records.
     * params:  old records.
     * return: void
     */
    public static void processAfterUpdateRecords(Map < Id, SObject > mapOld,Map<Id, SObject> mapNew){
        for(SVMXC__Service_Order_Line__c objOldWorkDetail: (List < SVMXC__Service_Order_Line__c > ) mapOld.values()){
            SVMXC__Service_Order_Line__c objNewWorkDetail = (SVMXC__Service_Order_Line__c) mapNew.get(objOldWorkDetail.id);
            //DCP-37747
            if (objOldWorkDetail.SVMXC__Line_Status__c != objNewWorkDetail.SVMXC__Line_Status__c && objNewWorkDetail.SVMXC__Line_Status__c == 'Canceled') {
                lstWarningMessageUpdateWorkDetails.add(objNewWorkDetail);
                setNoBatchQualifiedWorkOrderIds.add(objNewWorkDetail.SVMXC__Service_Order__c);
            }
            
            setInsertedPartWorkDetailsIds = AutoRMA_WorkdetailHelper.throwAutoRMAValidation(objOldWorkDetail, objNewWorkDetail,setInsertedPartWorkDetailsIds);
            workDetailIdToWorkDetailMap=AfterUpdate_WorkDetailHelper.populateWorkdetailMap(objOldWorkDetail, objNewWorkDetail);
        }
    }
    /**
     * Method:processRecordsInQueueable
     * Description: Method to process the after update records.
     * params:  old records.
     * return: void
     */
    public static ilib_Queueablethread processRecordsInQueueable(ilib_Queueablethread queueableThread){
        //DCP-37747
        if (!lstWarningMessageUpdateWorkDetails.isEmpty()) {
            //DCP-50636 [call method in queueable]
            queueableThread.logandQueue(new UpdateWarningMsg_WorkdetailHelper( lstWarningMessageUpdateWorkDetails), 'UpdateWarningMsg_WorkdetailHelper', 'updateWarningMessageOnWorkOrder');
        }
        
        if (!workDetailIdToWorkDetailMap.isEmpty()) {
            // start reversal in sfdc.  
            queueableThread.logandQueue(new PartsConsumptionReversal_WDHelper(workDetailIdToWorkDetailMap), 'PartsConsumptionReversal_WDHelper', 'initiatePartConsumptionReversalProcess');
        }
        return queueableThread;
    }
}
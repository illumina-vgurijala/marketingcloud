/***************************************************************************************************************************************
* NAME         : Work Details
* DESCRIPTION  : Domain class for Work Detail Trigger.
*                    
* @AUTHOR : Veerendra
* @DATE   : 06-Jun-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Veerendra            06-Jun-2018          Initial Version. Update Is-Billable flag for every line type created in Work Details
* Ritika               15-Jun-2018          Added logic in afterupdate method to send email notificaiton for non-billable work order
* Debanka              14-Jul-2018          Added logic in afterupdate and afterinsert method to update Parts Not Used field on wok order
* Sravankumar          02-Aug-2018          Added 90days service warranty condition to make isBillable false without checking the contract
* Soumya               08-Aug-2018          Added logic in before insert and before update to check for Tool's product listed in FRU List
* KD                   15-May-2021          DCP-45873 : Update line type for estimate work details
* KD                   19-May-2021          DCP-45928 : Error if Estiamte Labor qnty less than 2.
* Rucha Dalvi          26-Aug-2021          DCP-46273 : Added method updateConfirmOperabilityForRelocationWO, calculateConfirmOperabilityWO to update Confirm Operability on WO for relocation work order type 
* Vignesh              25-Sep-2021          DCP-49744 - Logic to populate Serial Lot Number
* Shivani              13-Oct-2021          DCP-50636 : Making Warning Message updates on Work Order asyn
* Biswajeet            25-June-2022         CMSI-69 : Instrumentation of class
* Dhairya Shah         17 April 2024        CMCM-6760 - Removed the method -dmlOnAfterInsert() 
* Nancy                26-Sep-2024          CMCM-10494 - Work Order Trigger Long Term Optimization - Part 2
****************************************************************************************************************************************/
public with sharing class WorkDetails extends ilib_SObjectDomain {

    // public static final String BILLABLE_WORK_DETAIL_META_DATA = 'Billable_Work_Detail';
    // public static final String WORK_ORDER_ACCOUNT = 'SVMXC__Service_Order__r.SVMXC__Company__c';
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS = 'Tools';
    public static final Set < String > SET_FSE_ROLES = new Set < String > {
        'Field Service Manager'
    };
    public static final String STRING_SERVICE_CONTRACT_STATUS_ACTIVE = 'Active';
    public static final String STRING_WORK_DETAIL_NON_BILLABLE_REASON_GOODWILL = 'Goodwill';
    public static final String WD_APPROVALSTATUS_APPROVED = 'Approved';
    public static final String WD_APPROVALSTATUS_PENDINGAPPROVAL = 'Pending Approval';
    public static final String STRING_WORK_ORDER_STATUS_COMPLETED = 'Completed'; //CMCM-10494
    
    public static final String STRING_PARTS_ORDER_LINE_STATUS = 'Canceled';
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS = 'Parts';
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR = System.Label.Labor;
    
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED = 'Material Consumed';
    
    public static final String STRING_WORK_DETAIL_LINE_STATUS_OPEN = System.Label.WorkDetailLineStatusOpen; //DCP-37747
    public static final String STRING_WORK_ORDER_BILLING_TYPE_IS_BILLABLE = 'Billable';
    public static final String STRING_WORKORDER_API_NAME = 'Work_Order__c';
    public static final String STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION = System.Label.Work_Detail_Record_Type_Usage_Consumption;
    public static final String STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATES = System.Label.Work_Detail_Record_Type_Estimate;
    public static final String STRING_WORK_DETAIL_RECORD_TYPE_RELATED_PRODUCT = 'Related Products';

    public static final string STRING_WOD_ACTIVITY_TYPE_IQ_OQ = 'IQ/OQ';
    public static final string STRING_WOD_ACTIVITY_TYPE_PQ = 'PQ';
    public static final String STRING_WORK_DETAIL_ACTIVITY_TYPE_FIELD_COMPLIANCE_REVIEW = System.Label.WorkDetailActivityFieldComplianceReview;
    public static final String STRING_WORK_DETAIL_ACTIVITY_TYPE_CUSTOMER_SERVICE_REVIEW = System.Label.WorkDetailActivityCustomerServiceReview;
    public static final String STRING_WORK_DETAIL_ACTIVITY_TYPE_QS_REVIEW = 'Qualification Service Review';
    public static final String STRING_WORK_ORDER_RECORD_TYPE_REMOTE_SUPPORT = 'Remote Support';
    public static final String CP_USER_TYPE = 'PowerPartner';
    public static boolean boolVanStockTestInProgress = false;
    public static Boolean boolIsCaseLineCreated = false;
    public static Boolean boolRunBillableFlagCheck = true;
    public static Boolean hasupdaterun = false;
    public static final String STRING_CRO_USER = 'Commercial and Revenue Operations'; // DCP-45568
    public static final String STRING_WORK_ORDER_RECORD_TYPE_FIELD_SERVICE = 'Field Service';
    public static final String STRING_WORK_ORDER_ORDER_TYPE_INSTALLATION = 'Installation';
    
    //public static final String STRING_WORK_DETAIL_NON_BILLABLE_REASON_CONSUMABLE_WARRANTY = 'Consumable Warranty';
    public static final String PRODUCT_TRACKING_SERIALIZED = 'Serialized';
    public static final String PRODUCT_TRACKING_LOT_BATCH_TRACKED = 'Lot/Batch Tracked';
    public static final String STRING_WORK_DETAIL_OBJECT_API_NAME = 'SVMXC__Service_Order_Line__c';
    //public static final String STRING_METHOD_COMPARE_WORK_DETAIL_LINE_ITEM = 'compareWorkDetailLineItems';
    public static final String STRING_REVERSAL_REQUESTED = 'Reversal Requested';
    
    
    //public static final String STRING_UPDATE_WO_FOR_CONSUMPTION_QUALIFICATION = 'qualifyWorkOrdersForConsumptionThroughVanstock'; //DCP-37399
    //DCP-38877
    public static final String STRING_WORK_DETAIL_NON_BILLABLE_REASON_SPARE_PART_WARRANTY = 'Spare Part Warranty';
    public static final String STRING_WORK_ORDER_ORDER_TYPE_RELOCATION = 'Relocation';
    public static final String STRING_WORK_ORDER_IP_ASSET_TYPE_CUSTOMER_OWNED = 'Customer Owned';
    public static final Set < String > SET_WD_ACTIVITY_TYPES = new Set < String > {
        'Repair/Troubleshooting',
        'Training',
        'Upgrade',
        'Remote Support',
        'Depot Service',
        'Install',
        'Preventative Maintenance',
        'Dedicated Onsite Activities',
        'Account Maintenance',
        'Customer Readiness',
        'Sales Support Activity',
        'Consulting',
        'IT Consult',
        'Workflow Config',
        'Coding'
    };
    public static final Set < String > SET_ACTIVITY_TYPES_OPEN = new Set < String > {
        'IQ/OQ',
        'OQ',
        'PQ',
        STRING_WORK_DETAIL_ACTIVITY_TYPE_FIELD_COMPLIANCE_REVIEW,
        'Letter of Acceptance accepted'
    };
    
    public static Id idWorkDetailRelProdRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(STRING_WORK_DETAIL_RECORD_TYPE_RELATED_PRODUCT).getRecordTypeId();
    //DCP-46273
    public static final Set < String > SET_WORKDETAIL_ACTIVITY_TYPES = new Set < String > {
        'IQ/OQ',
        'OQ',
        'PQ',
        'System Health Check',
        'Installation',
        'Preventative Maintenance'
    };
    public static final Set < String > SET_WORK_ORDER_STATUS = new Set < String > {
        'Completed',
        'Closed',
        'Closed-Duplicate',
        'Canceled'
    };
    // DCP-33467
    public static final String PRODUCT_CODE = 'Product Code:';
    public static final String SERIAL = ', Serial:';
    public static final String BATCH = ', Batch:';
    public static Set < string > setWorkOrderNumber = new Set < string > ();
    // DCP-33467
    public static boolean appliedContractsTriggerRanOnce = false;
    public static Set<string> setWDErrors = new Set<string>();
    //DCP-37399
    
    public static final String STRING_WORK_DETAIL_LINE_STATUS_CANCELED = 'Canceled';
    //DCP-46273
    public static Map < Id, SObject > mapNew = new Map < Id, SObject > ();

    //DCP-43634 start
    public static Map < Id, SVMXC__Service_Order__c > idParentWOToWO;
    
    public static user currentUser {
        get {
            if (currentUser == null && !Trigger.isInsert){
                currentUser = [select id, profile.name, ManagerId from user where id =: UserInfo.getUserId() limit 1];
            }    
            return currentUser;
        }
        set;
    }
    public static final String STRING_INTEGRATION_SUCCESS = 'Success';
    public static List < SVMXC__Service_Order_Line__c > lstLabourWorkDetails = new List < SVMXC__Service_Order_Line__c > (); //DCP-46273
    public static List < SVMXC__Service_Order_Line__c > lstRejectedWDs = new List < SVMXC__Service_Order_Line__c > ();
    
    //DCP-43634 end
    public static List < SVMXC__Product_Stock__c > listFilteredProductStockFinalUpdate = new List < SVMXC__Product_Stock__c > ();
    public static Map < Id, SVMXC__Site__c > consumedFromLocationIdToLocationMap;

    //DCP-37747
    // public static final Set < String > SET_BYPASS_LINE_STATUS_FROM_ADDERROR = new Set < String > {
    //     'Canceled'
    // };
    //May2021 Sonarqubes fixes
    public static final String STRING_WORKDETAILQUEUEABLE = 'WorkDetailQueueable';

    // DCP-45873
    public static final String CODE_PARAMETER_LABOUR_CODE = 'Labour_Product_Codes';
    public static final String CODE_PARAMETER_TRAVEL_CODE = 'Travel_Product_Codes';
    public static final String ERROR_LABOR_QNTY_2_NEEDED = 'Billable on-site support requires 2 hours of labor at minimum';
    //DCP-49744
    public static Map < Id, SVMXC__Installed_Product__c > mapRelatedIP = new Map < Id, SVMXC__Installed_Product__c > ();
    public static Id idWorkDetailUsageRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId();
    public static Id idWorkDetailEstimatesRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATES).getRecordTypeId();
    public static Map < Id, Id > iPtoProduct = new Map<Id, Id>();
    public static final Integer INTEGER_ONE = 1;
    public static Map < Id, SVMXC__Product_Serial__c > consumedStockedSerialIdToConsumedStockedSerailMap = new Map<Id, SVMXC__Product_Serial__c>();
    
    public static Map < Id, Id > idUserToManager = new Map<Id, Id>();
    public static Map<Id, Id> idWOtoWOOwnerId = new Map<Id, Id>();
    public static Map < Id, SVMXC__Installed_Product__c > mapIdToIP = new Map < Id, SVMXC__Installed_Product__c > ();
    //public static List < SVMXC__Allocated_Stock__c > insertAllocatatedStocts = new List < SVMXC__Allocated_Stock__c > ();
    public static Map<Id, SVMXC__Service_Order__c> mapFinalWOToBeUpdated = new Map<Id, SVMXC__Service_Order__c>();
    public static Set < Id > setDeletedWDIds = new Set < Id > (); // DCP-33467
    //public static List<SVMXC__Allocated_Stock__c> lstUpdateAllocatedStocks = new List<SVMXC__Allocated_Stock__c>();
    //DCP-46273:
    public static Set < Id > setWOWorkDetails = new Set < Id > ();
    public static List < SVMXC__Service_Order_Line__c > lstWorkDetailWithUpdatedIPs = new List < SVMXC__Service_Order_Line__c > ();
    //Set < Id > setInsertedPartWorkDetailsIds = new Set < Id > ();
    /**
    * constructor
    **/
    public WorkDetails(List < SVMXC__Service_Order_Line__c > sObjectList) {
        super(sObjectList);
    }
    /*
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /**
        * constructor
        **/
        public ilib_SObjectDomain construct(List < SObject > sObjectList) {
            return new WorkDetails(sObjectList);
        }
    }

     /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }

    /**
     * Method Name:queryRecordsforExecutionBeforeInsert
     */
    public void queryRecordsforExecutionBeforeInsert(List<SVMXC__Service_Order_Line__c> lstWorkDetails) {
        ilib_LogEvent.push('WorkDetails.queryRecordsforExecutionBeforeInsert');
        Set < Id > setInstaledProductIds = new Set < Id > ();
        for (SVMXC__Service_Order_Line__c objWorkDetail: lstWorkDetails) {
            if (objWorkDetail.SVMXC__Serial_Number__c != null) {
                setInstaledProductIds.add(objWorkDetail.SVMXC__Serial_Number__c);
            }
            ilib_LogEvent.message('Service Order Line details'+objWorkDetail); //CMSI-69
        }
        if (!setInstaledProductIds.isEmpty()) {
            for (SVMXC__Installed_Product__c objInstalledProduct: new InstalledProductsSelector().selectInstalledProductsFromIds(setInstaledProductIds)) {
                iPtoProduct.put(objInstalledProduct.Id, objInstalledProduct.SVMXC__Product__c);
                mapRelatedIP.put(objInstalledProduct.Id, objInstalledProduct);
                ilib_LogEvent.message('Installed Product details'+objInstalledProduct); //CMSI-69
            }
        }
        ilib_LogEvent.info('setInstaledProductIds'+setInstaledProductIds); //CMSI-69
        ilib_LogEvent.pop(); //CMSI-69
    }
    /**
     * Method Name:queryRecordsforExecutionBeforeInsert
     */
    public void queryRecordsForExecution(List<Sobject> records){
        ilib_LogEvent.push('WorkDetails.queryRecordsForExecution');
        Set <Id> setParentWOIds = new Set<Id>();
        for (SVMXC__Service_Order_Line__c objWorkDetail: (List<SVMXC__Service_Order_Line__c>)records) {
            if (objWorkDetail.SVMXC__Service_Order__c != null) {
                setParentWOIds.add(objWorkDetail.SVMXC__Service_Order__c);
            }
            ilib_LogEvent.message('Service Order Line details'+objWorkDetail); //CMSI-69
        }
        if (!setParentWOIds.isEmpty() && idParentWOToWO == null){
            idParentWOToWO = new Map < Id, SVMXC__Service_Order__c > (new WorkOrdersSelector().selectWorkOrders(setParentWOIds));
        }
        ilib_LogEvent.pop(); //CMSI-69
    }
    /*
    *  method: queryRecordsForExecutionBeforeUpdate
    *  @author - Prashanth
    *  @Description : query the records for execution in before update of work details.
    * 
    */
    public void queryRecordsForExecutionBeforeUpdate(Map<Id, SObject> oldRecords, List<sObject> records){
        ilib_LogEvent.push('WorkDetails.queryRecordsForExecutionBeforeUpdate');
        set < Id > setInstalledProdId = new set < Id > ();
        for (SVMXC__Service_Order_Line__c objWorkDetail: (List < SVMXC__Service_Order_Line__c > ) records) {
            SVMXC__Service_Order_Line__c objOldWorkOrderLine = (SVMXC__Service_Order_Line__c)(oldRecords.get(objWorkDetail.Id));
            //DCP-46273 Hold the set of ids in before update context to fetch list of old
            if (objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR) {
                setWOWorkDetails.add(objOldWorkOrderLine.Id);
            }
            //DCP-33873(Refractor WF :- Work Detail : Return Installed Product Is Not Blank)
            if (!String.IsBlank(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c)) {
                setInstalledProdId.add(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c);
            }
            if (objOldWorkOrderLine.SVMXC__Serial_Number__c != objWorkDetail.SVMXC__Serial_Number__c && objWorkDetail.SVMXC__Serial_Number__c != null) {
                lstWorkDetailWithUpdatedIPs.add(objWorkDetail);
            }
            ilib_LogEvent.message('Service Order Line details'+objWorkDetail); //CMSI-69
        }
        //DCP-46273
        if (!setWOWorkDetails.isEmpty()) {
            lstLabourWorkDetails = new WorkDetailsSelector().selectWorkDetailsByWorkDetailId(setWOWorkDetails);
        }
        //DCP-33873(Refractor WF :- Work Detail : Return Installed Product Is Not Blank)
        if (!setInstalledProdId.IsEmpty()) {
            for (SVMXC__Installed_Product__c obj: new InstalledProductsSelector().selectRelatedInstalledProducts(setInstalledProdId)) {
                mapIdToIP.put(obj.Id, obj);
            }
        }
        if (lstWorkDetailWithUpdatedIPs.size() > 0) {
            iPtoProduct = BeforeInsert_WorkDetailHelper.getProductFromInstallProduct(lstWorkDetailWithUpdatedIPs);
        }
        ilib_LogEvent.pop(); //CMSI-69
    }
    /**
     *  @author Veerendra
     *  @description - To be executed, when the Work Detail is inserted. 
     *                 1. Checks if Work Detail is created, updates Is-Billable flag for Parts and Labor lines
     **/
    public override void onBeforeInsert(){
        //Map of Work order Id versus its estimate and debrief quantity
        Map < Id, AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper > workOrderIdToQuantityWrapper = new Map < Id, AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper > ();
        List<SVMXC__Service_Order_Line__c> lstWorkDetails = (List<SVMXC__Service_Order_Line__c>) records;
        //before insert started
        queryRecordsforExecutionBeforeInsert(lstWorkDetails);
        queryRecordsForExecution(records);
        idUserToManager = BeforeInsert_WorkDetailHelper.getUsersManager();
        //to update Custom Fields  on work detail
        BeforeInsert_WorkDetailHelper.updateFieldsOnBeforeInsert(lstWorkDetails);
        PartsReservation_WorkDetailHelper.checkPartsReservation(lstWorkDetails);
        AggregateLineItems_WorkDetailHelper.aggregateLineItems(lstWorkDetails, workOrderIdToQuantityWrapper);
        ProcessWDBeforeInsert_WorkDetailHelper.processWorkDetailsBeforeInsert(lstWorkDetails);
        if (WorkDetails.boolRunBillableFlagCheck) {
            BillableRules_WorkdetailsHelper.executeIsBillableRules(records);
            UpdateContract_WorkDetailHelper.updateContractOnWD((List < SVMXC__Service_Order_Line__c > ) records, true, false, new List < Applied_Contract__c > ()); //Tapas INC0230587              
        }
        
        BeforeInsert_WorkDetailHelper.populateSerialNumber(lstWorkDetails);
        asyncCallOnBeforeInsert(lstWorkDetails, workOrderIdToQuantityWrapper);
    }
    /**
     *  @author Nancy
     *  @description - To skip some WO trigger methods when WO is Completed and WD are upserted - Added as part of CMCM-10494
    **/
    public static void skipWOTrigger(List < SVMXC__Service_Order_Line__c > lstWorkDetails){
        Set<Id> setWDId = new Set<Id>();
        for(SVMXC__Service_Order_Line__c workDetail: lstWorkDetails) {
            setWDId.add(workDetail.Id);
        }
        List<SVMXC__Service_Order_Line__c> lstWD = new WorkDetailsSelector().selectWorkDetailsByWorkDetailId(setWDId);
        
        for(SVMXC__Service_Order_Line__c workDetail: lstWD) {
            if(workDetail.SVMXC__Service_Order__r.SVMXC__Order_Status__c == STRING_WORK_ORDER_STATUS_COMPLETED){
                WorkOrders.skipWOTrigger = true;
                WorkOrders.isWDUpserted = true;
            }
        }
    }
    /**
     * Method:asyncCallOnBeforeInsert
     * Description: async calls for before insert
     */
    public static void asyncCallOnBeforeInsert(List < SVMXC__Service_Order_Line__c > lstWorkDetails, Map<Id, AggregateLineItems_WorkDetailHelper.WorkDetailLineQuantityWrapper> workOrderIdToQuantityWrapper){
        ilib_LogEvent.push('WorkDetails.asyncCallOnBeforeInsert');
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('WorkDetailsBeforeInsert');

        if (!workOrderIdToQuantityWrapper.isEmpty()) {
            List<SVMXC__Service_Order_Line__c> lstWD = new WorkDetailsSelector().selectWorkDetailsByWorkOrderId(workOrderIdToQuantityWrapper.keySet());
            //Fetch the existing work detail lines for the work order and aggregate them
            for(SVMXC__Service_Order_Line__c objWorkDetail: lstWD) {
                if (objWorkDetail.RecordTypeId == idWorkDetailEstimatesRecordTypeId) {
                    AggregateLineItems_WorkDetailHelper.aggregateEstimateLineItems(workOrderIdToQuantityWrapper, objWorkDetail);
                }

                if (objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId && (objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED || objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS || (objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && (objWorkDetail.SVMXC__Activity_Type__c != STRING_WORK_DETAIL_ACTIVITY_TYPE_FIELD_COMPLIANCE_REVIEW && objWorkDetail.SVMXC__Activity_Type__c != STRING_WORK_DETAIL_ACTIVITY_TYPE_CUSTOMER_SERVICE_REVIEW && objWorkDetail.SVMXC__Activity_Type__c != STRING_WORK_DETAIL_ACTIVITY_TYPE_QS_REVIEW)))) {
                    //DCP-25289 condition updated  
                    AggregateLineItems_WorkDetailHelper.aggregateDebriefLineItems(workOrderIdToQuantityWrapper, objWorkDetail);
                }
                ilib_LogEvent.message('objWorkDetail'+objWorkDetail); //CMSI-69
            }
            //DCP-33873
            queueableThread.logandQueue(new CompareWorkdetails_WorkdetailHelper(workOrderIdToQuantityWrapper), 'CompareWorkdetails_WorkdetailHelper', 'compareWorkDetailLineItems');
        }

        if (!queueableThread.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        }
        ilib_LogEvent.pop(); //CMSI-69
    }
    /**
     *  @author Veerendra
     *  @description - To be executed, when the Work Detail is inserted.
     **/
    public override void onAfterInsert() {
        System.debug('Inside WD After Insert');
        List<SVMXC__Service_Order_Line__c> lstWorkDetails = (List<SVMXC__Service_Order_Line__c>) records;
        skipWOTrigger(lstWorkDetails);
        //before update started
        ProcessWDAfterInsert_WorkdetailHelper.processWorkdetailsAfterInsert(lstWorkDetails);
        GoodWillApprovals_WorkdetailHelper.submitGoodwillApproval((List < SVMXC__Service_Order_Line__c > ) records, null);
        AsyncAfterInsert_WorkdetailHelper.asynCallsOnAfterInsert(lstWorkDetails);
    }
    /*
     *  @AUTHOR:  Ritika 
     *  @DESCRIPTION: Method to be called after insert of the work details
     *  @PARAM :  Map<Id, SObject> mapOld
     *  @RETURN:  void
     */
    public override void onBeforeDelete() {
        //Added for DCP-37747
        ProcessWDBeforeDelete_WorkdetailHelper.restrictWorkDetailsDeletion((List < SVMXC__Service_Order_Line__c > ) records);
        ProcessWDBeforeDelete_WorkdetailHelper.updateWarningMessageOnWorkOrder((List < SVMXC__Service_Order_Line__c > ) records);
        setDeletedWDIds = ProcessWDBeforeDelete_WorkdetailHelper.processWorkdetailsBeforeDelete((List < SVMXC__Service_Order_Line__c > ) records); 
        dmlOnBeforeDelete();  
        ilib_LogEvent.info('setDeletedWDIds :'+setDeletedWDIds);   //CMSI-69
    }
    /*
     *  @AUTHOR:  Prashanth 
     *  @DESCRIPTION: Method to be called before delete of the work details.
     *  @RETURN:  void
     */
    public static void dmlOnBeforeDelete(){
        if(!mapFinalWOToBeUpdated.isEmpty()){
            update mapFinalWOToBeUpdated.values();
        }
        if(!setDeletedWDIds.isEmpty()){
            List < SVMXC__Allocated_Stock__c > lstAllocatedStock = new AllocatedStocksSelector().selectAllocatedStockWithWd(setDeletedWDIds);
            if (!lstAllocatedStock.isEmpty()){
                ilib_LogEvent.info('lstAllocatedStock :'+UtilsCollection.getSetOfIds(lstAllocatedStock)); //CMSI-69
                delete lstAllocatedStock;
            }
        }
    }
    /*
     *  @AUTHOR:  Ritika 
     *  @DESCRIPTION: Method to be called before update of the work details
     *  @PARAM :  Map<Id, SObject> mapOld
     *  @RETURN:  void
     */
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords){
        ilib_LogEvent.info('Work Detail old records before update:'+oldRecords); //CMSI-69
        queryRecordsForExecutionBeforeUpdate(oldRecords,records);
        queryRecordsForExecution(records);
        ApprovalsBeforeUpdate_WorkdetailHelper.revertNonBillableReasonOnRejection((List < SVMXC__Service_Order_Line__c > ) records, (Map < Id, SVMXC__Service_Order_Line__c > ) oldRecords); //DCP-43634 
        BeforeUpdate_WorkdetailHelper.processBeforeUpdate(oldRecords, records);
        BeforeUpdate_WorkdetailHelper.updateWDOwnerManager(records);
        CheckWDsInFRUs_WorkdetailHelper.checkIfSelectedInFRU(oldRecords, records);
        BeforeUpdate_WorkdetailHelper.asyncCallsOnBeforeUpdate();
        ApprovalsBeforeUpdate_WorkdetailHelper.preventEditWhenPendingApproval((List < SVMXC__Service_Order_Line__c > ) records, (Map < Id, SVMXC__Service_Order_Line__c > ) oldRecords); //DCP-43634
    } 
    /*
     *  @AUTHOR:  Ritika 
     *  @DESCRIPTION: Method to be called after update of the work details
     *  @PARAM :  Map<Id, SObject> mapOld
     *  @RETURN:  void
     */
    public override void onAfterUpdate(Map < Id, SObject > mapOld) {
        ilib_LogEvent.info('Work Detail old records after update:'+mapOld); //CMSI-69
        System.debug('Inside WD After Update');
        skipWOTrigger((List < SVMXC__Service_Order_Line__c >) records);
        //queryRecordsForExecution(records);
        AfterUpdate_WorkDetailHelper.processWorkdetailsAfterUpdate(mapOld);
        GoodWillApprovals_WorkdetailHelper.submitGoodwillApproval((List < SVMXC__Service_Order_Line__c > ) records, (Map < Id, SVMXC__Service_Order_Line__c > ) mapOld);
        GoodWillApprovals_WorkdetailHelper.postCommentsIfGoodwillApprovedOrDenied((List < SVMXC__Service_Order_Line__c > ) records, (Map < Id, SVMXC__Service_Order_Line__c > ) mapOld, idParentWOToWO); //DCP-43634
        AsyncAfterUpdate_WorkdetailHelper.asyncCallsAfterUpdate(mapOld);
    }
}
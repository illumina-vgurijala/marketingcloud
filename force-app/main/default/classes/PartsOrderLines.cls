/***************************************************************************************************************************************
 * NAME         : PartsOrderLines
 * DESCRIPTION  : Apex class for Parts Order Lines
 *                    
 * @AUTHOR : Veerendra
 * @DATE   : 15-Jun-2018  
 * TestClasses for 75%: TestAgreementValidation_POLHelper, TestBatchUpdateCaseStatus, TestCheckDCIR_POLHelper, TestCheckLinkedrecord_POLHelper, TestCompletedWorkOrders_WOHelper,
 *              TestPartsOrderDataSender, TestPartsOrderLineSelector, TestPartsOrderLines,TestSwapProcessOnLineItems_POLHelper, TestTPSPWorkOrderShareService,TestUpdatePendingReview_POLHelper
 * TestClasses for 90%: TestAgreementValidation_POLHelper, TestBatchUpdateCaseStatus, TestCheckDCIR_POLHelper, TestCheckLinkedrecord_POLHelper, TestCompletedWorkOrders_WOHelper,
 *              TestPartsOrderDataSender, TestPartsOrderLineSelector, TestPartsOrderLines,TestSwapProcessOnLineItems_POLHelper, TestTPSPWorkOrderShareService,TestUpdatePendingReview_POLHelper
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Veerendra            15-Jun-2018             Apex Class for populating the Is Billable flag when the Parts Order line is created.
 * Sravankumar          02-Aug-2018             Added 90days service warranty condition to make isBillable false without checking the contract
 * Veerendra            16-Aug-2018             Added Part if "Return" condition to make isBillable false without checking the contract
 * Soumya               21-Aug-2018              Added Logic inside updateIsBillable method to check for installation work orders.
 * Mandeep              29-Aug-2018             Added logic to restrict linking return part order line to more that part order line.
 * Prashanth Kumar      03-Jun-2019             Added logic to send Parts order for re-approval on changing parts order lines quanity/product(DCP-25283).
 * KD                   03-March-2021           DCP-43163 : Updated executeIsBillableRules method parameter for reusablity
 * Adyasha Satapathy    08-Mar-2021             Added logic to auto create Return Parts order from Shipment Parts Order and copy the Parts Order Line(DCP-41580)
 * Vignesh S            08-Jun-2021             Added logic for NONFRU product submission: DCP-47228
 * Vignesh S            25-Aug-2021             Removed logic for NONFRU product ordering against DX for DCP-49742
 * Shivani Jain         29-Nov-2021             DCP-42926 : Parts Order Line Optimization
 * Sagar Madkaikar      06-Jun-2022             DCP-51199 : Added field change check for Is_CofD_Filled__c for validating CofD uploaded Document.
 * Nitin                25-Aug-2022             CMSI-221: Instrumentation 
 ****************************************************************************************************************************************/
public with sharing class PartsOrderLines extends ilib_SObjectDomain {
  
    public static final String DML_EXCEPTION='System.DmlException';
  
    public static final String BILLABLE_PARTS_ORDER_LINE_META_DATA = 'Billable_Parts_Order_Line';//DCP-38817
    public static final String STRING_SERVICE_CONTRACT_STATUS_ACTIVE = 'Active';
    public static final String STRING_PARTS_ORDER_LINE_CONSUMABLE = 'Consumable';
    public static final String STRING_PARTS_ORDER_LINE_NONFRU = 'NONFRU'; //DCP-47227
    public static final String STRING_CASENO_API_NAME = 'Case_Number__c';
    public static final String STRING_WORKORDER_API_NAME = 'Work_Order__c';
    public static final String STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    public static final String STRING_PRODUCT_TYPE = 'Spare'; // Product Type on Product
    public static final String STRING_WORK_ORDER_TYPE_INSTALLATION = 'Installation';
    public static final String STRING_PART_ORDER_TYPE_ADVANCEEXCHANGE = 'Advance Exchange';
    public static final String STRING_PART_ORDER_LINE_STATUS_SHIPPED = 'Shipped';
    public static final String STRING_SAP_INTEGRATION_USER = 'SAP Service Integration';
    public static final String STRING_SNAP_INTEGRATION_USER = 'SNAP Service Integration';
    public static boolean stopPartOrderLineInsertion = false;
    public static final String STRING_WORK_ORDER_RECORD_TYPE_FIELD_SERVICE='Field Service';
    public static final String STRING_WORK_ORDER_ORDER_TYPE_INSTALLATION='Installation';
    public static final String STRING_WORK_DETAIL_NON_BILLABLE_REASON_GOODWILL='Goodwill';
    public static final String STRING_PARTSORDERLINE_NON_BILLABLE_REASON_GOODWILL='Goodwill';
    public static final String STRING_WORK_DETAIL_NON_BILLABLE_REASON_CONSUMABLE_WARRANTY='Consumable Warranty'; 
    public static final String STRING_WORK_ORDER_ORDER_TYPE_RELOCATION='Relocation';
    public static final String STRING_WORK_ORDER_IP_ASSET_TYPE_CUSTOMER_OWNED='Customer Owned';
    public static final String STRING_INTEGRATION_SAP_SERVICE_PROFILE_NAME='Integration SAP Service';
    public static final String STRING_PARTS_ORDER_STOCK_TRANSFER = 'Stock Transfer';
    public static final String STRING_SERIALIZED = 'Serialized';
    public static final String STRING_LOT_BATCH_TRACKED = 'Lot/Batch Tracked';
    public static boolean boolStopPartOrderLineInsert = false;
    public static Boolean hasUpdateRun = false;//DCP-38817
    public static Boolean hasInsertRun = false;//DCP-38817
    //[DCP-3245]
    public static final String STRING_MISSING_PRODUCT_IN_FRULIST = 'Selected Product is not listed in FRU List.';
    
    //DCP-25645
    public static final String STRING_PRODUCT_TYPE_INSTRUMENT = 'Instrument';
    //DCP-33467
    public static final String PRODUCT_CODE = 'Product Code:';
    public static final String SERIAL = ', Serial:';
    public static final String BATCH = ', Batch:';
    public static Set<string> setWorkOrderNumber = new Set<string>();
    public static Set<string> setPolErrors = new Set<string>();
    //DCP-33467
    public static boolean appliedContractsTriggerRanOnce = false;
    public static final String STRING_PART_ORDER_STATUS_PENDING_REVIEW = 'Pending Review';
    
    public static final List<String> CLOSED_WO_STATUS_LIST = new List<String>{'Canceled','Reopen Requested','Closed-Duplicate'};
  
    //DCP-41580
    public static final String STRING_PARTS_ORDER_TYPE_SHIPMENT = 'Shipment';
    public static final String STRING_CONDITION_TYPE_LOANER = 'LOANER';
    public static final String STRING_SERIAL_NUMBER_PROFILE_IL02 = 'IL02';
    public static final string STRING_RETURN_REASON = 'Company Owned Asset';
    public static final string STRING_PARTSORDERLINEQUEUEABLE = 'PartsOrderLineQueueable';
    public static final string STRING_RETURNPOCREATION = 'returnPOCreation';
    public static final String STRING_PARTS_ORDER_LINE_STATUS_CANCELED = 'Canceled'; //DCP-42763
    public static final String STRING_PART_ORDER_LINE_STATUS_REQUESTED = 'Requested'; //DCP-42763

    public static final String STRING_NONFRU_REQUISITION_ERROR = 'NONFRU products cannot be ordered for IVD products. Please remove any NONFRU products to request this parts order';
    public static final String STRING_SERVICE_PRODUCT_TYPE_NONFRU = 'NONFRU'; 
    //DCP-47694
    public static final String PARTIAL_SHIPMENT = 'Partial_Shipment';
    public static final String STRING_ALL = 'All';
    public static final String STRING_STATUS_OPEN = 'Open';

    public static Map<Id, SVMXC__RMA_Shipment_Line__c> mapCurrentPartsOrderLines = new Map<Id, SVMXC__RMA_Shipment_Line__c>();
    public static Map<Id, SVMXC__RMA_Shipment_Order__c> partsOrderIdToPartsOrder = new Map < Id, SVMXC__RMA_Shipment_Order__c>();
    public static Map<Id, SVMXC__RMA_Shipment_Order__c> mapPartsOrderToUpdate = new Map <Id, SVMXC__RMA_Shipment_Order__c> ();
    public static Map<Id, SVMXC__RMA_Shipment_Order__c> mapPartsOrderToUpdateAfterInsert = new Map <Id, SVMXC__RMA_Shipment_Order__c> ();
    public static Map<Id, Id> mapPOLIdToInstalledProductId = new Map<Id, Id>();
    public static Map<Id, SVMXC__RMA_Shipment_Line__c> nonReturnPartsOrderLineIdVSPOL = new Map<Id, SVMXC__RMA_Shipment_Line__c > ();
    public static Set<Id> setPartsOrderLineId = new Set<Id> ();
    public static Set<Id> setBillablePartsOrderLinesIds = new Set<Id>();//DCP-38817
    public static Map<Id, Product2> mapProduct = new Map<Id, Product2>();
    //DCP-42760
    public static Set<Id> setReturnPOLProducts = new Set<Id>();
    public static Set<Id> setReturnPOLIP = new Set<Id>();
    //DCP-31049
    public static set<id> setEligiblePOsForRestrictionCheck = new set<id>();
    public static List<SVMXC__RMA_Shipment_Line__c> lstPOLForCompatibleProductCheck = new List<SVMXC__RMA_Shipment_Line__c> (); 
    public static Map <SVMXC__RMA_Shipment_Line__c, Id> partsOrderLinesToPartsOrder = new Map < SVMXC__RMA_Shipment_Line__c, Id > ();
    public static set<id> setPartOrderIdForLocation = new set<id>();
    public static String strLoggedInProfile;
    public static Id shipmentRecordTypeId;
    public static Set <Id> setProductIdsSelected = new Set <Id> (); 
    public static Set <Id> setPartOrderIds = new Set <Id> (); 
    public static Set <SVMXC__RMA_Shipment_Line__c> setPartsOrderLinesRecords = new Set<SVMXC__RMA_Shipment_Line__c>(); 
    public static Set <Id> setFromLocationId = new Set <Id> (); 
    public static Set <String> setBatchNumber = new Set <String> (); 
    public static Set <Id> setStockSerialId = new Set <Id> (); 
    public static Set <Id> setProductStockId = new Set <Id> (); 
    public static Map<Id, SVMXC__Product_Serial__c> stockSerialRecordsMap = new Map<Id, SVMXC__Product_Serial__c>();
    public static Map <id,Product2> mapidtoReturnProduct = new Map <id,Product2>();
    public static Map <id,SVMXC__Installed_Product__c> mapidtoReturnIP = new Map <id,SVMXC__Installed_Product__c>();
    public static list<SVMXC__RMA_Shipment_Line__c> lstPOLContracttoupdate = new list<SVMXC__RMA_Shipment_Line__c>();
    public static Set<Id> setPOLIdsDCIRCheck = new Set<Id>();
    public static Set<Id> setPOLIdsLoanerAgreementCheck = new set<Id>();
    public static Map<Id, SVMXC__RMA_Shipment_Line__c> mapPOLWithBillableChange = new Map<Id, SVMXC__RMA_Shipment_Line__c>();
    public static set<Id> setRelatedWorkOrderId = new set<Id>();

    //DCP-51199
    public static Set<Id> setPOLIdsCofDCheck = new Set<Id>();
    public static final String DOC_NAME_DCIR = 'DCIR';
    public static final String DOC_NAME_COFD = 'COFD';

    private static final String LOG_TITLE = 'PartsOrderLines';
    public static final String NULLSTR = 'Null';
    public static final String STRING_RETURN_REASON_POL = 'Complaint Investigation'; //CMCM-8243
    /*******************************************************************************************************
    * @description Constructor
    * @param sObjectList List of Parts Order Lines records
    */
    public PartsOrderLines(List <SVMXC__RMA_Shipment_Line__c> sObjectList) {
        super(sObjectList);
    }
  
    /*******************************************************************************************************
    * @description  Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /****************************************************************************************************
        * @description  construct method
        */
        public ilib_SObjectDomain construct(List < SObject > sObjectList) {
            return new PartsOrderLines(sObjectList);
        }
    }
  
    /*******************************************************************************************************
    * @description  Method to clear out static collections for Before Event
    */
    private void clearCollectionsBeforeEvent() {
        ilib_LogEvent.push(LOG_TITLE + '.clearCollectionsBeforeEvent()');
        setReturnPOLProducts.clear();
        setReturnPOLIP.clear();
        setEligiblePOsForRestrictionCheck.clear();
        lstPOLForCompatibleProductCheck.clear();
        partsOrderLinesToPartsOrder.clear();
        setProductIdsSelected.clear();
        setPartOrderIds.clear();
        setPartsOrderLinesRecords.clear();
        setFromLocationId.clear();
        setBatchNumber.clear();
        setStockSerialId.clear();
        setProductStockId.clear();
        mapidtoReturnProduct.clear();
        mapidtoReturnIP.clear();
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  Method to clear out static collections for Before insert
    */
    private void clearCollectionsBeforeInsert() {
        ilib_LogEvent.push(LOG_TITLE + '.clearCollectionsBeforeInsert()');
        setPartOrderIdForLocation.clear();
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  Method to clear out static collections for Before Update
    */
    private void clearCollectionsBeforeUpdate() {
        ilib_LogEvent.push(LOG_TITLE + '.clearCollectionsBeforeUpdate()');
        lstPOLContracttoupdate.clear();
        setPOLIdsDCIRCheck.clear();
        setPOLIdsLoanerAgreementCheck.clear();
        mapPOLWithBillableChange.clear();
        setRelatedWorkOrderId.clear();
        setPOLIdsCofDCheck.clear();//DCP-51199
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  Method to clear out static collections for After Insert 
    */
    private void clearCollectionsAfterInsert() {
        ilib_LogEvent.push(LOG_TITLE + '.clearCollectionsAfterInsert()');
        mapPartsOrderToUpdateAfterInsert.clear();
        nonReturnPartsOrderLineIdVSPOL.clear();
        ilib_LogEvent.pop();        
    }

    /*******************************************************************************************************
    * @description  Method to clear out static collections for After Event 
    */
    private void clearCollectionsAfterEvent() {
        ilib_LogEvent.push(LOG_TITLE + '.clearCollectionsAfterInsert()');
        mapPOLIdToInstalledProductId.clear();
        setPartsOrderLineId.clear();
        setBillablePartsOrderLinesIds.clear();
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  Method to clear out static collections for After Update 
    */
    private void clearCollectionsAfterUpdate() {
        ilib_LogEvent.push(LOG_TITLE + '.clearCollectionsAfterInsert()');
        mapPartsOrderToUpdate.clear();
        nonReturnPartsOrderLineIdVSPOL.clear();
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  Method to use for initializing Collections that will be used in all events
    * @param records List of Parts Order Lines
    */
    public void queryRecordsforExecution(List<Sobject> records) {
        ilib_LogEvent.push(LOG_TITLE + '.queryRecordsforExecution()');
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  Method to use for initializing Collections that will be used in Before Insert Event
    * @param records List of Parts Order Lines
    */
    public void queryRecordsforExecutionOnBeforeInsert(List<Sobject> records) {
        ilib_LogEvent.push(LOG_TITLE + '.queryRecordsforExecutionOnBeforeInsert()');
        Set<Id> setPartsOrderId = new Set <Id>();
        Id idLoggedInUserProfile;
        Set<id> setStockedSerialIds = new Set<Id>();
        Set<Id> setProductId = new Set<Id>();

        for(SVMXC__RMA_Shipment_Line__c objPartOrderLine: (List<SVMXC__RMA_Shipment_Line__c>) records) {
            setPartsOrderId.add(objPartOrderLine.SVMXC__RMA_Shipment_Order__c);
            if(objPartOrderLine.SVMXC__Product__c != Null) {
                setProductId.add(objPartOrderLine.SVMXC__Product__c);
            }
            if (objPartOrderLine.SVMXC__RMA_Shipment_Order__c != null) {
                if (objPartOrderLine.Stocked_Serial__c != null) {
                    setStockedSerialIds.add(objPartOrderLine.Stocked_Serial__c);
                }
            }
        }
        ilib_LogEvent.info('setPartsOrderId : '+setPartsOrderId);
        ilib_LogEvent.info('setStockedSerialIds : '+setStockedSerialIds);
        ilib_LogEvent.info('setProductId : '+setProductId);
        mapProduct = new Map<Id,Product2>(new ProductsSelector().selectProducts(setProductId));
        partsOrderIdToPartsOrder = new Map <Id, SVMXC__RMA_Shipment_Order__c> (new PartsOrdersSelector().selectPartsOrders(setPartsOrderId));
        idLoggedInUserProfile = UserInfo.getProfileId();
        strLoggedInProfile = [Select Name from Profile where Id = :idLoggedInUserProfile limit 1][0].Name;
        shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get(STRING_PARTS_ORDER_TYPE_SHIPMENT).getRecordTypeId();
        stockSerialRecordsMap = new Map<Id, SVMXC__Product_Serial__c>(new StockedSerialSelector().selectStockedSerialById(setStockedSerialIds));
        ilib_LogEvent.info('mapProduct : ' + (mapProduct != Null ? String.valueof(mapProduct.keySet()):NULLSTR));
        ilib_LogEvent.info('partsOrderIdToPartsOrder : ' + (partsOrderIdToPartsOrder != Null ? String.valueof(partsOrderIdToPartsOrder.keySet()):NULLSTR));
        ilib_LogEvent.info('idLoggedInUserProfile : '+idLoggedInUserProfile);
        ilib_LogEvent.info('strLoggedInProfile : '+strLoggedInProfile);
        ilib_LogEvent.info('shipmentRecordTypeId : '+shipmentRecordTypeId);
        ilib_LogEvent.info('stockSerialRecordsMap : ' + (stockSerialRecordsMap != Null ? String.valueof(stockSerialRecordsMap.keySet()):NULLSTR));
        ilib_LogEvent.pop();
    }
      
    /*******************************************************************************************************
    * @description  Method to use for initializing Collections that will be used in Before Update Event
    * @param records List of Parts Order Lines
    */
    public void queryRecordsforExecutionOnBeforeUpdate(List<Sobject> records) {
        ilib_LogEvent.push(LOG_TITLE + '.queryRecordsforExecutionOnBeforeUpdate()');
        Set<Id> polIds = UtilsCollection.getSetOfIds((List <SVMXC__RMA_Shipment_Line__c>) records);
        Set<Id> setPartsOrderId = new Set <Id>();
        Set<id> setStockedSerialIds = new Set<Id>();
        Set<Id> setProductId = new Set<Id>();
        
        mapCurrentPartsOrderLines = new Map<Id, SVMXC__RMA_Shipment_Line__c>(new PartsOrderLineSelector().selectPartsOrderLineRecords(polIds));
        
        for(SVMXC__RMA_Shipment_Line__c objPartOrderLine: (List <SVMXC__RMA_Shipment_Line__c>) records) {
            setPartsOrderId.add(objPartOrderLine.SVMXC__RMA_Shipment_Order__c);
            if(objPartOrderLine.SVMXC__Product__c != Null) {
        setProductId.add(objPartOrderLine.SVMXC__Product__c);
    }
            if (objPartOrderLine.SVMXC__RMA_Shipment_Order__c != null) {
                if (objPartOrderLine.Stocked_Serial__c != null) {
                    setStockedSerialIds.add(objPartOrderLine.Stocked_Serial__c);
                }
            }
            if(objPartOrderLine.Work_Order__c != NULL) {
                setRelatedWorkOrderId.add(objPartOrderLine.Work_Order__c);
            }
            
        }
        ilib_LogEvent.info('setPartsOrderId : '+setPartsOrderId);
        ilib_LogEvent.info('setProductId : '+setProductId);
        ilib_LogEvent.info('setStockedSerialIds : '+setStockedSerialIds);
        ilib_LogEvent.info('setRelatedWorkOrderId : '+setRelatedWorkOrderId);
        mapProduct = new Map<Id,Product2>(new ProductsSelector().selectProducts(setProductId));
        partsOrderIdToPartsOrder = new Map <Id, SVMXC__RMA_Shipment_Order__c> (new PartsOrdersSelector().selectPartsOrders(setPartsOrderId));
        shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get(STRING_PARTS_ORDER_TYPE_SHIPMENT).getRecordTypeId();
        stockSerialRecordsMap = new Map<Id, SVMXC__Product_Serial__c>(new StockedSerialSelector().selectStockedSerialById(setStockedSerialIds));
        ilib_LogEvent.info('shipmentRecordTypeId : '+shipmentRecordTypeId);
        ilib_LogEvent.info('mapProduct : ' + (mapProduct != Null ? String.valueof(mapProduct.keySet()):NULLSTR));
        ilib_LogEvent.info('partsOrderIdToPartsOrder : ' + (partsOrderIdToPartsOrder != Null ? String.valueof(partsOrderIdToPartsOrder.keySet()):NULLSTR));
        ilib_LogEvent.info('stockSerialRecordsMap : ' + (stockSerialRecordsMap != Null ? String.valueof(stockSerialRecordsMap.keySet()):NULLSTR));
        ilib_LogEvent.pop();
    }
  
    /*******************************************************************************************************
    * @description  Method to use for initializing Collections that will be used in After Insert Event
    * @param records List of Parts Order Lines
    */
    public void queryRecordsforExecutionOnAfterInsert(List<Sobject> records) {
        ilib_LogEvent.push(LOG_TITLE + '.queryRecordsforExecutionOnAfterInsert()');
        Set<Id> polIds = UtilsCollection.getSetOfIds((List <SVMXC__RMA_Shipment_Line__c>) records);
        Set<Id> setPartsOrderId = new Set <Id>();
        
        mapCurrentPartsOrderLines = new Map<Id, SVMXC__RMA_Shipment_Line__c>(new PartsOrderLineSelector().selectPartsOrderLineRecords(polIds));
        
        for(SVMXC__RMA_Shipment_Line__c objPartOrderLine: (List <SVMXC__RMA_Shipment_Line__c>) records) {
            setPartsOrderId.add(objPartOrderLine.SVMXC__RMA_Shipment_Order__c);
        }
        ilib_LogEvent.info('setPartsOrderId : '+setPartsOrderId);
        partsOrderIdToPartsOrder = new Map <Id, SVMXC__RMA_Shipment_Order__c> (new PartsOrdersSelector().selectPartsOrders(setPartsOrderId));
        ilib_LogEvent.info('partsOrderIdToPartsOrder : ' + (partsOrderIdToPartsOrder != Null ? String.valueof(partsOrderIdToPartsOrder.keySet()):NULLSTR));
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  Method to use for initializing Collections that will be used in After Update Event
    * @param records List of Parts Order Lines
    */
    public void queryRecordsforExecutionOnAfterUpdate(List<Sobject> records) {
        ilib_LogEvent.push(LOG_TITLE + '.queryRecordsforExecutionOnAfterUpdate()');
        Set<Id> polIds = UtilsCollection.getSetOfIds((List <SVMXC__RMA_Shipment_Line__c>) records);
        
        mapCurrentPartsOrderLines = new Map<Id, SVMXC__RMA_Shipment_Line__c>(new PartsOrderLineSelector().selectPartsOrderLineRecords(polIds));
       
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  Before Insert Logic for Parts Order Line Trigger
    * @param
    * @return void
    */
    public override void onBeforeInsert() {
        Set<Id> setWoId = new Set <Id>();
        List<SVMXC__RMA_Shipment_Line__c> lstPOL = new List<SVMXC__RMA_Shipment_Line__c>();
        clearCollectionsBeforeEvent();
        clearCollectionsBeforeInsert();
        queryRecordsforExecutionOnBeforeInsert(records);
  
        CheckLinkedrecord_POLHelper.checkLinkedPOL(records, null);
        UpdateContract_POLHelper.updateContractOnPOL((List<SVMXC__RMA_Shipment_Line__c>) records, false, new List<Applied_Contract__c>());
  
        for (SVMXC__RMA_Shipment_Line__c partOrderLine: (List<SVMXC__RMA_Shipment_Line__c>) records) {
            PopulateFields_POLHelper.populateSets(partOrderLine);
            POLRestrictions_POLHelper.populateEligiblePOs(partOrderLine, NULL);
            FRUProducts_POLHelper.generateCollections(partOrderLine, NULL);
            ValidateExistingWO_POLHelper.populateCollections(partOrderLine);
            Location_POLHelper.generatePartsOrderMap(partOrderLine, null);
            BatchNumber_POLHelper.makeBatchNumberNull(partOrderLine);
            PopulateFields_POLHelper.populateSerialNumber(partOrderLine);
            //CMCM-8243 start
            PopulateFields_POLHelper.populateWOForCP(partOrderLine);
            String wOId = partOrderLine.SVMXC__Service_Order__c;
            if(partOrderLine.Return_Reason__c == STRING_RETURN_REASON_POL && wOId != null){
                setWoId.add(wOId);
                lstPOL.add(partOrderLine);
            }
        }
        if(setWoId != null && !setWoId.isEmpty()){
            ValidateExistingWO_POLHelper.validateFANOnWorkOrder(setWoId,lstPOL);
        }
         //CMCM-8243 end
        PopulateFields_POLHelper.populateReturnProdAndIPMap();
        Location_POLHelper.validateFromLocation(partsOrderLinesToPartsOrder);
      
        if(!setPartsOrderLinesRecords.IsEmpty()) {
            ValidateExistingWO_POLHelper.validateBatchOrStockSerial(setPartsOrderLinesRecords,setBatchNumber,setFromLocationId,setStockSerialId,setProductStockId);
        }
  
        if(!setPartOrderIds.IsEmpty()) {
            FRUProducts_POLHelper.checkProductsOnFruList(setPartOrderIds, lstPOLForCompatibleProductCheck, null, setProductIdsSelected, 'Part');
        }
  
        if(!setEligiblePOsForRestrictionCheck.IsEmpty()) {
            POLRestrictions_POLHelper.checkPOLRestriction(setEligiblePOsForRestrictionCheck, records);
        }
  
        for(SVMXC__RMA_Shipment_Line__c objPartOrderLine: (List<SVMXC__RMA_Shipment_Line__c>) records) {
            PopulateFields_POLHelper.populateValues(objPartOrderLine, setPartOrderIdForLocation);
            PopulateFields_POLHelper.updateInstrumentComponentSNumber(objPartOrderLine, NULL);
            PopulateFields_POLHelper.updateInstrumentComponentModelType(objPartOrderLine);
            PopulateFields_POLHelper.updatePOLFieldsForInstrumentType(objPartOrderLine, NULL);
            DangerousGoods_POLHelper.populateDangerousGoods(objPartOrderLine, NULL);//DCP-42724
        }
  
        BillableRules_POLHelper.executeIsBillableRules(records);
          
    }
  
    /*******************************************************************************************************
    * @description  Before Update Logic for Parts Order Line Trigger
    * @param oldRecords Map of old Parts Order Line records
    * @return void
    */
    public override void onBeforeUpdate(Map < Id, SObject > oldRecords) {
        Set<Id> setWoId = new Set <Id>();
        List<SVMXC__RMA_Shipment_Line__c> lstPOL = new List<SVMXC__RMA_Shipment_Line__c>();

        clearCollectionsBeforeEvent();
        clearCollectionsBeforeUpdate();
        queryRecordsforExecutionOnBeforeUpdate(records);
          
        CheckLinkedrecord_POLHelper.checkLinkedPOL(records, oldRecords);

        for(SVMXC__RMA_Shipment_Line__c partOrderLine: (List < SVMXC__RMA_Shipment_Line__c > ) records) {
            SVMXC__RMA_Shipment_Line__c objOldPartOrderLine = (SVMXC__RMA_Shipment_Line__c)(oldRecords.get(partOrderLine.Id));
  
            POLRestrictions_POLHelper.populateEligiblePOs(partOrderLine, objOldPartOrderLine);
            PopulateFields_POLHelper.populateSetsBeforeUpdate(partOrderLine, objOldPartOrderLine);
            FRUProducts_POLHelper.generateCollections(partOrderLine, objOldPartOrderLine);
            AgreementValidation_POLHelper.populateSets(partOrderLine, objOldPartOrderLine);
            Location_POLHelper.generatePartsOrderMap(partOrderLine, objOldPartOrderLine);
            PopulateFields_POLHelper.populateSerialNumber(partOrderLine);
            BatchNumber_POLHelper.makeBatchNumberNullBeforeUpdate(partOrderLine, objOldPartOrderLine);
            BatchNumber_POLHelper.makeBatchNumberNull(partOrderLine);
            ValidateExistingWO_POLHelper.populateCollectionsBeforeUpdate(partOrderLine);
            BillableRules_POLHelper.populateIsBillableChangeSets(partOrderLine, objOldPartOrderLine);
            //CMCM-8243 start
            string wOId = partOrderLine.SVMXC__Service_Order__c;
            if(partOrderLine.Return_Reason__c == STRING_RETURN_REASON_POL && wOId != null){
                setWoId.add(wOId);
                lstPOL.add(partOrderLine);
            }
        }
        
        if(setWoId != null && !setWoId.isEmpty()){
            ValidateExistingWO_POLHelper.validateFANOnWorkOrder(setWoId,lstPOL);
        }
         //CMCM-8243 end
        if(!setPOLIdsDCIRCheck.isEmpty()) {
            AgreementValidation_POLHelper.validateIfDCIRAgreementIsGenerated(setPOLIdsDCIRCheck, (List<SVMXC__RMA_Shipment_Line__c>) records,DOC_NAME_DCIR);
        }
        //DCP-51199:call AgreementValidation_POLHelper for CofD
        if(!setPOLIdsCofDCheck.isEmpty()) {
            AgreementValidation_POLHelper.validateIfDCIRAgreementIsGenerated(setPOLIdsCofDCheck, (List<SVMXC__RMA_Shipment_Line__c>) records,DOC_NAME_COFD);
        }
        
        if(!setPOLIdsLoanerAgreementCheck.isEmpty()) {
            AgreementValidation_POLHelper.validateIfLoanergreementIsGenerated(setPOLIdsLoanerAgreementCheck, (List<SVMXC__RMA_Shipment_Line__c>) records);  
        }
      
        Location_POLHelper.validateFromLocation(partsOrderLinesToPartsOrder);
  
        if(!setPartsOrderLinesRecords.isEmpty()) {
            ValidateExistingWO_POLHelper.validateBatchOrStockSerial(setPartsOrderLinesRecords,setBatchNumber,setFromLocationId,setStockSerialId,setProductStockId);
        }
  
        if(!setEligiblePOsForRestrictionCheck.isEmpty()) {
            POLRestrictions_POLHelper.checkPOLRestriction(setEligiblePOsForRestrictionCheck, records);
        }
  
        if (!setPartOrderIds.IsEmpty()) {
            FRUProducts_POLHelper.checkProductsOnFruList(setPartOrderIds, lstPOLForCompatibleProductCheck, oldRecords, setProductIdsSelected, 'Part');
        }
  
        PopulateFields_POLHelper.populateReturnProdAndIPMap();
  
        for (SVMXC__RMA_Shipment_Line__c objPartOrderLine: (List < SVMXC__RMA_Shipment_Line__c > ) records) {
            SVMXC__RMA_Shipment_Line__c objOldPartOrderLine = (SVMXC__RMA_Shipment_Line__c)(oldRecords.get(objPartOrderLine.Id));

            PopulateFields_POLHelper.updateInstrumentComponentSNumber(objPartOrderLine, objOldPartOrderLine);
            PopulateFields_POLHelper.updateInstrumentComponentModelType(objPartOrderLine);
            DangerousGoods_POLHelper.populateDangerousGoods(objPartOrderLine, objOldPartOrderLine);
            PopulateFields_POLHelper.updatePOLFieldsForInstrumentType(objPartOrderLine, objOldPartOrderLine);
              
        }
  
        if(!mapPOLWithBillableChange.isEmpty()) {
              BillableRules_POLHelper.executeBillableBeforeUpdate();
          }
  
        if(!lstPOLContracttoupdate.isEmpty()) {
            UpdateContract_POLHelper.updateContractOnPOL(lstPOLContracttoupdate, false, new List<Applied_Contract__c>());
        }
    }
  
    /*******************************************************************************************************
    * @description  After Insert Logic for Parts Order Line Trigger
    * @param 
    * @return void
    */
    public override void onAfterInsert() {
        clearCollectionsAfterEvent();
        clearCollectionsAfterInsert();
        queryRecordsforExecutionOnAfterInsert(records);
  
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('PartsOrderLineAfterInsert');
        List<SVMXC__RMA_Shipment_Line__c> lstReturnPOEligible = new List<SVMXC__RMA_Shipment_Line__c>(); //DCP-41580
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        ilib_LogEvent.info('cp : '+cp);
        lstReturnPOEligible = GenAutoCreateReturnPOList_POLHelper.autoCreateReturnPartsOrder(null);
        CheckDCIR_POLHelper.checkDCIR(cp.Is_Channel_Partner__c, records);

        for(SVMXC__RMA_Shipment_Line__c objPartOrderLine: (List <SVMXC__RMA_Shipment_Line__c>) records) {
            PopulateCollectionsAfterEvent_POLHelper.populateSetAndMaps(objPartOrderLine, null, true, hasInsertRun);
        }
  
        if (!setPartsOrderLineId.isEmpty()) {
            ProductStockHandler.partsOrderShippedMechanism(setPartsOrderLineId);
            if(!mapPOLIdToInstalledProductId.isEmpty()) {
                queueableThread.logandQueue(new CreateCoveredProduct_POLHelper(mapPOLIdToInstalledProductId), STRING_PARTSORDERLINEQUEUEABLE, 'LoanerInstalledProductModification');
            }
            if(!nonReturnPartsOrderLineIdVSPOL.isEmpty()) {
                queueableThread.logandQueue(new AutoDebrief_POLHelper(nonReturnPartsOrderLineIdVSPOL.keyset()), 'AutoDebrief_POLHelper', 'autoDebrief');
            }
        }
        UpdatePOStatusPendingReview_POLHelper.updatePartsOrderStatus(cp.Is_Channel_Partner__c);
        dmlonAfterInsert();
  
        if(setBillablePartsOrderLinesIds != null && !setBillablePartsOrderLinesIds.isEmpty() && !isLoggedInUserChannelPartner()) {
            SendEmailNonBillableContacts_POLHelper.sendEmail(setBillablePartsOrderLinesIds);
        }

        if(!lstReturnPOEligible.isEmpty()) {
            queueableThread.logandQueue(new CreateReturnPOWithLines_POLHelper(lstReturnPOEligible), 'CreateReturnPOWithLines_POLHelper', STRING_RETURNPOCREATION);
        }
        
        if(queueableThread != null) {
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        } 

    }
    
    /*******************************************************************************************************
    * @description  After Update Logic for Parts Order Line Trigger
    * @param onAfterUpdate Map of old Parts Order Line records
    * @return void
    */
    public override void onAfterUpdate(Map < Id, sObject > oldRecords) {
        clearCollectionsAfterEvent();
        clearCollectionsAfterUpdate();
        queryRecordsforExecutionOnAfterUpdate(records);

        ilib_Queueablethread queueableThread=new ilib_Queueablethread('PartsOrderLineAfterUpdate');
        List<SVMXC__RMA_Shipment_Line__c> lstReturnPOEligible = new List<SVMXC__RMA_Shipment_Line__c>();//DCP-41580

        lstReturnPOEligible = GenAutoCreateReturnPOList_POLHelper.autoCreateReturnPartsOrder(oldRecords);

        for(SVMXC__RMA_Shipment_Line__c objPartOrderLine: (List <SVMXC__RMA_Shipment_Line__c>) records) {
            SVMXC__RMA_Shipment_Line__c objOldPartsOrderLine = (SVMXC__RMA_Shipment_Line__c)(oldRecords.get(objPartOrderLine.Id));
            //Class to populate collections to be used for further processing(After Insert and After Update)
            PopulateCollectionsAfterEvent_POLHelper.populateSetAndMaps(objPartOrderLine, objOldPartsOrderLine, false, hasUpdateRun);
            ReOpenPartsOrderLine_POLHelper.reOpenPOL(objPartOrderLine, objOldPartsOrderLine);
        }          
        
        if (!setPartsOrderLineId.isEmpty()) {
            ProductStockHandler.partsOrderShippedMechanism(setPartsOrderLineId);
            if(!mapPOLIdToInstalledProductId.isEmpty()) {
                queueableThread.logandQueue(new CreateCoveredProduct_POLHelper(mapPOLIdToInstalledProductId), STRING_PARTSORDERLINEQUEUEABLE, 'LoanerInstalledProductModification');
            }
            if (!nonReturnPartsOrderLineIdVSPOL.isEmpty()) {
                queueableThread.logandQueue(new AutoDebrief_POLHelper(nonReturnPartsOrderLineIdVSPOL.keyset()), 'AutoDebrief_POLHelper', 'autoDebrief');

            }
            queueableThread.logandQueue(new ProcessServiceLoanerInstrument_POLHelper(setPartsOrderLineId), 'ProcessServiceLoanerInstrument_POLHelper', 'updateIPInsertCDL');

        }
      
        if(setBillablePartsOrderLinesIds != null && !setBillablePartsOrderLinesIds.isEmpty() && !isLoggedInUserChannelPartner()) {
            SendEmailNonBillableContacts_POLHelper.sendEmail(setBillablePartsOrderLinesIds);
        }

        queueableThread.logandQueue(new SwapProcessOnLineItems_POLHelper((List<SVMXC__RMA_Shipment_Line__c>) records, oldRecords), 'SwapProcessOnLineItems_POLHelper', 'swapProcessOnLineItems');
        
        if(!lstReturnPOEligible.isEmpty()) {
            queueableThread.logandQueue(new CreateReturnPOWithLines_POLHelper(lstReturnPOEligible), 'CreateReturnPOWithLines_POLHelper', STRING_RETURNPOCREATION);
        }         
        if(queueableThread!=null) {
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE); 
        }

        dmlonAfterUpdate();
    
    }
      
    /*******************************************************************************************************
    * @description  After Delete Logic for Parts Order Line Trigger
    * @param
    * @return void
    */
    public override void onAfterDelete() { }

    /*******************************************************************************************************
    * @description  After UnDelete Logic for Parts Order Line Trigger
    * @param
    * @return void
    */
    public override void onAfterUndelete() { }
  
    /*******************************************************************************************************
    * @description  Before Delete Logic for Parts Order Line Trigger
    * @param
    * @return void
    */
    public override void onBeforeDelete() {
        ProcessItemsBeforeDelete_POLHelper.processLineItemsBeforeDelete((List<SVMXC__RMA_Shipment_Line__c>) records);
    }
    
    /*******************************************************************************************************
    * @description  DCP-38817 - To check if the logged in user is channel partner.
    * @param
    * @return Boolean - True if logged in user is Channel partner
    */
    public static Boolean isLoggedInUserChannelPartner(){
        ilib_LogEvent.push(LOG_TITLE + '.isLoggedInUserChannelPartner()');
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        ilib_LogEvent.info('cp.Is_Channel_Partner__c : '+cp.Is_Channel_Partner__c);
        ilib_LogEvent.pop();
        return cp.Is_Channel_Partner__c;
    }
  
    /*******************************************************************************************************
    * @description  method to fire DMLs for After Update event
    * @param
    * @return void
    */
    public void dmlonAfterUpdate() {
        ilib_LogEvent.push(LOG_TITLE + '.dmlonAfterUpdate()');
        if(!mapPartsOrderToUpdate.IsEmpty()) {
            update mapPartsOrderToUpdate.values();
        } 
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description  method to fire DMLs for After Insert event
    * @param
    * @return void
    */
    public void dmlonAfterInsert() {
        try {
            ilib_LogEvent.push(LOG_TITLE + '.dmlonAfterInsert()');
            update mapPartsOrderToUpdateAfterInsert.values();
        } catch(Exception e) {
            Integer numErrors = e.getNumDml();
            ilib_LogEvent.info('numErrors : '+numErrors);
            for(SVMXC__RMA_Shipment_Line__c objPOL:(List<SVMXC__RMA_Shipment_Line__c>)records) {
                if(mapPartsOrderToUpdateAfterInsert.keyset().contains(objPOL.SVMXC__RMA_Shipment_Order__c)) {
                    if(e.getTypeName()==DML_EXCEPTION) {
                        for(Integer i=0;i<numErrors;i++) {
                            objPOL.adderror(e.getDmlMessage(i));
                        }
                    } else {
                        objPOL.adderror(e.getMessage());
                    }
                }
            }
        }
        ilib_LogEvent.pop();
    }

       /**
    *  @author Nitin
    *  @description  CMSI-221,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }
}
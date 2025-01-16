/***************************************************************************************************************************************
* NAME         : InventoryDataReceiver
* DESCRIPTION  : Inventory Synchronization to DCP(ServiceMax)
* @AUTHOR      : 
* @DATE        : 14-Oct-2018
*  
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* KD                    25-June-2021           DCP-46257 : Refactored code to include incremental sync
* Anshaj				29-June-2022		   CMSI-95 : Instrumented class for ilib_LogEvent Framework
* Saikiran              10-June-2023           CMCM-138 : Unable to lock row (SAP/SFDC) Location Outbound
* Vineeta Verma         9-Jan-2025             PRB0047876: To add logic for Serialized+Batched Products
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
@RestResource(urlMapping = '/InventorySyncInterface/*')
global with sharing class InventoryDataReceiver extends ilib_RestReceiver {

    private static List < InventoryDataReceiverWrapper.Location > wrapLocations;
	public static Map < String, String > locationExtIdToLocationId = new Map < String, String > ();
	public static Map < String, String > productMaterialIdToPrdId = new Map < String, String > ();
    private static final string STRING_PRODUCTSTOCK_AVAILABLE = 'Available';
    private static final string STRING_PRODUCTSTOCK_SERIALIZED = 'Serialized';
    private static Set<String> setUniqueProductStock = new Set<String>();
    private static Set<String> setUniqueStockedSerial = new Set<String>();
    // Register custom helpers: This is a mandatory step.
    public static ilib_UpsertHelpers.LocationUnitofWorkHelper locationWork = new ilib_UpsertHelpers.LocationUnitofWorkHelper();
    public static ilib_UpsertHelpers.ProductStockUnitOfWorkHelper productStockWork = new ilib_UpsertHelpers.ProductStockUnitOfWorkHelper();
    public static ilib_UpsertHelpers.StockedSerialUnitOfWorkHelper stockedSerialWork = new ilib_UpsertHelpers.StockedSerialUnitOfWorkHelper();

    private static SVMXC__Site__c oneLocation;
	private static final String LOG_TITLE = 'InventoryDataReceiver.';
    
    // Added for test coverage of catch block. It is getting updated through its test class
    @TestVisible
    private static Boolean testCodeCoverage = false;

    private static final string TEST_CUSTOM_EXCEPTION = 'UNABLE_TO_LOCK_ROW';

    /* Map: ExternalId to Parent Object */
    private static Map < String, InventoryDataReceiverWrapper.Location > extIdToLocation = new Map < String, InventoryDataReceiverWrapper.Location > ();

    /* Map: ExternalId to Location JSON fields */
    private static Map < String, InventoryDataReceiverWrapper.Location > extIdToLocationJSONFields = new Map < String, InventoryDataReceiverWrapper.Location > ();
    /*==========Processing Serials Start=============*/
    private static List<SVMXC__Product_Stock__c> productStockProcessObj = new List<SVMXC__Product_Stock__c>();
    private static Set<Id> productStockIds = new Set<Id>();
    private static List<SVMXC__Product_Serial__c> stockedSerialProcessObj = new List<SVMXC__Product_Serial__c>();
    private static List<SVMXC__Product_Serial__c> batchProcessObj = new List<SVMXC__Product_Serial__c>();
    
    private static Map<String,InventoryDataReceiverWrapper.ProductStock> productStocksInJson = new Map<String,InventoryDataReceiverWrapper.ProductStock>();  
    private static Map<String,InventoryDataReceiverWrapper.StockedSerial> stockSerialsInJson = new Map<String,InventoryDataReceiverWrapper.StockedSerial>();
    private static Map<String,InventoryDataReceiverWrapper.StockedBatch> batchNumbersInJson = new Map<String,InventoryDataReceiverWrapper.StockedBatch>();
    private static List<SVMXC__Product_Stock__c> productStocksInSFDC = new List<SVMXC__Product_Stock__c>();  
    private static List<SVMXC__Product_Serial__c> stockSerialsInSFDC = new List<SVMXC__Product_Serial__c>();
    private static Map<Id,List<SVMXC__Product_Serial__c>> consumedBatchProdStockVsBatchRec = new Map<Id,List<SVMXC__Product_Serial__c>>();
    /*==========Processing Serials END=============*/
    /* STORE ALL LOOKUP VARIABLES HERE */

    //Product lookup based on Material Number of Product.
    private static Set < String > productExtIdSet = new Set < String > ();
    
    //prashanth-INC0214764 start
    //IP Product lookup based on equipment Number
    private static Set<String> equipmentNumberExtIdSet = new Set<String>();
    //Map Installed Product equipment Number to Installed Product Id
    private static Map < String, String > installedProductEquipmentToIPId = new Map < String, String > ();
    //prashanth-INC0214764 end

    //Added for DCP-22362
    
    private static Map < String, SVMXC__Product_Serial__c > stockSerialExtIdToStockSerial = new Map < String, SVMXC__Product_Serial__c > ();
    private static Map < String, String > stockSerialExtIdToLocId = new Map < String, String > ();
    private static Map < String, String > stockSerialExtIdToIPERPID = new Map < String, String > ();//INC0214764							   
    
        //[DCP-31054]
    //Map < String, PartsOrderLinesQualificationWrapper > batchNumberToPOLQualificationFields = new Map < String, PartsOrderLinesQualificationWrapper > ();
    
    //prashanth INC0214764
    //map of product id to product code
    //used to populate installed product name correctly in the format of serialnumber - product code.
    private static Map<String, String> mapProductIdCode = new Map<String, String>();
    
    private static List<SVMXC__Stock_History__c> lstStocKHistory = new List<SVMXC__Stock_History__c>();


    private static Map<String,SVMXC__Product_Stock__c> mapExternalIdToProductStock;
    private static Map<String,SVMXC__Product_Serial__c> mapExternalIdToStockedSerial;
    private static Boolean boolIsIncremental;

    /* UNIT OF WORK : GENERIC STATEMENT */
        //unit of work: This is a mandatory step.
    private static ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List < Schema.SObjectType > {
                SVMXC__Site__c.SObjectType,
                SVMXC__Product_Stock__c.SObjectType,
                SVMXC__Product_Serial__c.SObjectType
            });
        /* / UNIT OF WORK : GENERIC STATEMENT */

    @HttpPost
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        InventoryDataReceiver instantiated = new InventoryDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name, ilib_LogEvent.SERVICE);
		ilib_LogEvent.push(LOG_TITLE+'upsertIncomingValues()');
        String strRestError = null;
        Id primaryRecordId;
        String erpCustomerId;

        //fetch the Json input from the request body and store it in a variable.
        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try {
            // Added for covering catch block in test class
            if (testCodeCoverage && Test.isRunningTest()) {
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }
            //if there is no body found, throw an error.
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');
            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, wrapLocations);

            primaryRecordId = upsertIncomingValuesImpl();
            erpCustomerId = getRelatedErpCustomerId('SVMXC__Site__c', 'SVMXC__Account__r', primaryRecordId);
        }
        catch (Exception e)
        {
            strRestError = UtilsRest.handleRetryCustomRestError(e);//CMCM-138
            if (testCodeCoverage && Test.isRunningTest()) {
            	throw e; 
            }
        }

        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }
        
        //Updated below line
        String logInterfaceId = ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

        //Updating Interface log record to capture "UNABLE_TO_LOCK_ROW" error message
        if(String.isNotBlank(logInterfaceId)){
            UtilsRest.updateHttpResultCodeForRetry(logInterfaceId, LOG_TITLE);
        } 

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
        }
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();  
    }

    private static void deserializeInputs(String jsonInput) {
        ilib_LogEvent.push(LOG_TITLE+'deserializeInputs()');
        ilib_LogEvent.info('jsonInput : '+jsonInput);
        ilib_LogEvent.pop();
        wrapLocations = (List < InventoryDataReceiverWrapper.Location > ) System.JSON.deserialize(jsonInput, List < InventoryDataReceiverWrapper.Location > .class);
    }

    private static Id upsertIncomingValuesImpl() {
        ilib_LogEvent.push(LOG_TITLE+'upsertIncomingValuesImpl()');
        boolIsIncremental = wrapLocations[0].Action == 'IncrementStock';
        ilib_LogEvent.info('boolIsIncremental : '+boolIsIncremental);

        /* REGISTER OBJECTS : GENERIC STATEMENT */
        //register your objects: This is a mandatory step.
        uow.registerWork(locationWork);
        uow.registerWork(productStockWork);
        uow.registerWork(stockedSerialWork);
        /* / REGISTER OBJECTS : GENERIC STATEMENT */
        //if the recieved JSON body is not null, process it.
        if (wrapLocations != null) {
            /** POPULATE LOOKUP VARIABLES **/
            //iterate over parent records.
            processIncomingJSON();
            populateLookupVariables();
            //DCP-46257
            if(boolIsIncremental){
                fetchProductStockAndSerials();
            }
            fetchExistingProductStockDetails();
            initializeSobjectFields();
            if(!boolIsIncremental){
                processProductSerials();
            }
			
        }

        // any business logic for incoming values goes in here
        businessRules(uow);
        uow.commitWork();

        if (stockSerialExtIdToStockSerial != null && !stockSerialExtIdToStockSerial.isEmpty()){
            createInstalledProduct(stockSerialExtIdToStockSerial, stockSerialExtIdToLocId, stockSerialExtIdToIPERPID,mapProductIdCode);//INC0214764
        }
        if(!lstStocKHistory.isEmpty()){
            insert lstStocKHistory;
        }
        ilib_LogEvent.pop();
        return (oneLocation != null ? oneLocation.Id : null);
    }
	    /*
         * description - businessRules method
		 * return - void
         */ 
	public static void businessRules(ilib_SObjectUnitOfWork uow) {}
    /**
     *  @author 
     *  @description process incoming JSON
     **/
    private static void processIncomingJSON(){
        ilib_LogEvent.push(LOG_TITLE+'processIncomingJSON()');
        for (InventoryDataReceiverWrapper.Location wrapperLocations: wrapLocations) {
            ilib_LogEvent.message('wrapperLocations : '+wrapperLocations);
            extIdToLocationJSONFields.put(wrapperLocations.Location, wrapperLocations);
            extIdToLocation.put(wrapperLocations.Location, wrapperLocations);
            //setLocationWithNoInventory.add(wrapperLocations.Location);
            /* ITERATE OVER CHILD RECORDS */
            SVMXC__Site__c locationObj = wrapperLocations.getSObject();
            oneLocation = locationObj;
            for (InventoryDataReceiverWrapper.ProductStock wrapperProductStocks: wrapperLocations.ProductStock) {
                ilib_LogEvent.fine('wrapperProductStocks : '+wrapperProductStocks);
                //setLocationWithNoInventory.remove(wrapperLocations.Location);
                if (String.isNotBlank(wrapperProductStocks.SVMXC_Product)){
                    productExtIdSet.add(wrapperProductStocks.SVMXC_Product);
                    // Incremental stock DCP-46257
                    setUniqueProductStock.add(wrapperLocations.Location+wrapperProductStocks.SVMXC_Product);
                }
                /* ITERATE OVER STOCKED SERIAL AND STORE NAME : DCP-22362*/
                for (InventoryDataReceiverWrapper.StockedSerial wrapperStockedSerial: wrapperProductStocks.StockedSerial) {
                    //prashanth-INC0214764 start
                    //Adding equipmentIds to a set
                    if(String.isNotBlank(wrapperStockedSerial.Equipment_Id)){
                        equipmentNumberExtIdSet.add(wrapperStockedSerial.Equipment_Id);
                    }
                    //prashanth - INC0214764 end  
                    // Incremental stock  DCP-46257
                    setUniqueStockedSerial.add(wrapperLocations.Location+wrapperStockedSerial.Name); 
                }
                // Incremental stock  DCP-46257
                for(InventoryDataReceiverWrapper.StockedBatch wrapperStockedBatch: wrapperProductStocks.StockedBatch){
                    setUniqueStockedSerial.add(wrapperLocations.Location+wrapperProductStocks.SVMXC_Product+wrapperStockedBatch.Batch_Number);
                }

            }
        }
		ilib_LogEvent.info('extIdToLocationJSONFields : '+extIdToLocationJSONFields);
		ilib_LogEvent.info('extIdToLocation : '+extIdToLocation);
        ilib_LogEvent.info('productExtIdSet : '+productExtIdSet);
        ilib_LogEvent.info('setUniqueProductStock : '+setUniqueProductStock);
        ilib_LogEvent.info('setUniqueStockedSerial : '+setUniqueStockedSerial);
        ilib_LogEvent.pop();
    }
    /**
     *  @author 
     *  @description populate related look ups
     **/
    private static void populateLookupVariables(){
        /********************************************************** Getting Salesforce Id of lookup variables ****************************/
        ilib_LogEvent.push(LOG_TITLE+'populateLookupVariables()');
        for (Product2 prdM: new ProductsSelector().selectProductsForMaterialNumber(productExtIdSet)) {
			ilib_LogEvent.message('prdM : '+prdM);
            productMaterialIdToPrdId.put(prdM.Material_Number__c, prdM.id);
            //prashanth - INC0214764
            mapProductIdCode.put(prdM.id,prdM.Material_Number__c);
        }
		ilib_LogEvent.info('productMaterialIdToPrdId : '+productMaterialIdToPrdId);
        ilib_LogEvent.info('mapProductIdCode : '+mapProductIdCode);
        //Added for DCP-22362
        for (SVMXC__Site__c siteLoc: new LocationsSelector().selectLocationsForExternalId(extIdToLocation.keyset())) {
            locationExtIdToLocationId.put(siteLoc.SVMX_PS_External_ID__c, siteLoc.id);
        }
        ilib_LogEvent.info('locationExtIdToLocatoinId : '+locationExtIdToLocationId);
        //prashanth- INC0214764 start
        for (SVMXC__Installed_Product__c instProd: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(equipmentNumberExtIdSet)) {
            installedProductEquipmentToIPId.put(instProd.ERP_Equipment_ID__c, instProd.id);
        }
        //prashanth - INC0214764 end
        ilib_LogEvent.info('installedProductEquipmentToIPId : '+installedProductEquipmentToIPId);
        ilib_LogEvent.pop();
    }
    /**
     *  @author 
     *  @description DCP-46257 : fetch all product stock and serial for processing
     **/
    private static void fetchProductStockAndSerials(){
        ilib_LogEvent.push(LOG_TITLE+'fetchProductStockAndSerials()');
        mapExternalIdToProductStock = (Map<String,SVMXC__Product_Stock__c>)UtilsCollection.getMapOfStringToSObject(new ProductStockSelector().selectProductStocksByExternalId(setUniqueProductStock),'SVMX_PS_External_ID__c',Map<String,SVMXC__Product_Stock__c>.class);
        mapExternalIdToStockedSerial = (Map<String,SVMXC__Product_Serial__c>)UtilsCollection.getMapOfStringToSObject(new StockedSerialSelector().selectStockedSerialByExternalId(setUniqueStockedSerial),'SVMX_PS_External_ID__c',Map<String,SVMXC__Product_Serial__c>.class);
        ilib_LogEvent.pop();
    }
    /**
     *  @author 
     *  @description fetching existing detail for quantity update
     **/
    private static void fetchExistingProductStockDetails(){
        /*==========Processing Serials Start=============*/
            // Get stocks from SFDC for location passed from SAP/JSon
            ilib_LogEvent.push(LOG_TITLE+'fetchExistingProductStockDetails');
            for (SVMXC__Product_Stock__c prodStockRecs: new ProductStockSelector().selectProductStockByLocationExtId(extIdToLocation.keyset())) {
				ilib_LogEvent.message('prodStockRecs : '+prodStockRecs);
                productStockIds.add(prodStockRecs.Id);
                productStocksInSFDC.add(prodStockRecs);
            }
            // Get stock serials from SFDC for stocks related the location passed from SAP/JSon
            for (SVMXC__Product_Serial__c stockedSerialRecs: new StockedSerialSelector().selectStockedSerialByProductStockExtId(productStockIds)) {
				ilib_LogEvent.message('stockedSerialRecs : '+stockedSerialRecs);
                if(stockedSerialRecs.SVMXC__Product_Stock__r.SVMXC__Status__c == STRING_PRODUCTSTOCK_AVAILABLE){
                	stockSerialsInSFDC.add(stockedSerialRecs);
                }
                if(stockedSerialRecs.Batch_Number__c != null && stockedSerialRecs.SVMX_PS_VS_Product_Tracking__c=='Lot/Batch Tracked' && stockedSerialRecs.SVMXC__Product_Stock__r.SVMXC__Status__c == 'Consumed'){
                    if(!consumedBatchProdStockVsBatchRec.containskey(stockedSerialRecs.SVMXC__Product_Stock__c)){
                        consumedBatchProdStockVsBatchRec.put(stockedSerialRecs.SVMXC__Product_Stock__c, new List<SVMXC__Product_Serial__c>());
                    }
                    consumedBatchProdStockVsBatchRec.get(stockedSerialRecs.SVMXC__Product_Stock__c).add(stockedSerialRecs);
                }
            } 
            /*==========Processing Serials END=============*/
			ilib_LogEvent.info('consumedBatchProdStockVsBatchRec Ids : '+(consumedBatchProdStockVsBatchRec != NULL ? String.valueOf(consumedBatchProdStockVsBatchRec.keySet()) : 'NULL'));
            ilib_LogEvent.info('productStockIds : '+productStockIds);
            ilib_LogEvent.pop();
    }
    /**
     *  @author 
     *  @description Initialize Object and fields for upsert
     **/
    private static void initializeSobjectFields(){
        /********************************************************** INSTANTIATE SOBEJCTS AND ITS FIELDS ****************************/
        ilib_LogEvent.push(LOG_TITLE+'intializeSobjectFields()');
        //Iterate over Parent Object
        for (InventoryDataReceiverWrapper.Location wrapperLocations: wrapLocations) {
            //get the object details from the method created in InventoryDataReceiverWrapper.
            //It has all the fields information which will be updated.
            SVMXC__Site__c locationObj = wrapperLocations.getSObject();
            oneLocation = locationObj;
            ilib_LogEvent.message('oneLocation : '+oneLocation);

            locationWork.registerUpsert(locationObj);

            /* ITERATE OVER CHILD RECORDS */
            //Iterate over the child records.
            for (InventoryDataReceiverWrapper.ProductStock wrapperProductStocks: wrapperLocations.ProductStock) {
                //Process only the records where status != Blocked.
                if (wrapperProductStocks.SVMXC_Status.equalsIgnoreCase(STRING_PRODUCTSTOCK_AVAILABLE)) {
                    //get the object details from the method created in InventoryDataReceiverWrapper.
                    //It has all the fields information which will be updated.
                    SVMXC__Product_Stock__c productStockObj = wrapperProductStocks.getSObject();
                    ilib_LogEvent.fine('productStockObj : '+productStockObj);
                    //External Id = Location + Product.
                    productStockObj.SVMX_PS_External_ID__c = wrapperLocations.Location + wrapperProductStocks.SVMXC_Product;
                    ilib_LogEvent.fine('productStockObj.SVMX_PS_External_ID__c : '+productStockObj.SVMX_PS_External_ID__c);
                    

                    //populate product
                    productStockObj.SVMXC__Product__c = productMaterialIdToPrdId.containsKey(wrapperProductStocks.SVMXC_Product) ? productMaterialIdToPrdId.get(wrapperProductStocks.SVMXC_Product) : null;
                    // DCP-46257
                    if(boolIsIncremental && mapExternalIdToProductStock.containsKey(productStockObj.SVMX_PS_External_ID__c)){
                        productStockObj.SVMXC__Quantity2__c = mapExternalIdToProductStock.get(productStockObj.SVMX_PS_External_ID__c).SVMXC__Quantity2__c + Decimal.valueOf(wrapperProductStocks.SVMXC_Quantity2);
                        wrapperProductStocks.SVMXC_Quantity2 = String.ValueOf(productStockObj.SVMXC__Quantity2__c);
                    }
                    productStockObj.Sales_Order_Number__c = wrapperLocations.SalesOrderNumber;
                    // Prepare product stocks map passed from JSon
                    productStocksInJson.put(wrapperLocations.Location + wrapperProductStocks.SVMXC_Product,wrapperProductStocks);
                    uow.registerRelationship(productStockObj, SVMXC__Product_Stock__c.SVMXC__Location__c, locationObj);
                    productStockWork.registerUpsert(productStockObj);

                    /* ITERATE OVER SUB-CHILD RECORDS */
                    for (InventoryDataReceiverWrapper.StockedSerial wrapperStockedSerial: wrapperProductStocks.StockedSerial) {
                        //get the object details from the method created in InventoryDataReceiverWrapper.
                        SVMXC__Product_Serial__c stockedSerialObj = wrapperStockedSerial.getSObject();
                        ilib_LogEvent.fine('stockedSerialObj : '+stockedSerialObj);
                        //External Id = Location + Name.
                        stockedSerialObj.SVMX_PS_External_ID__c = wrapperLocations.Location + wrapperStockedSerial.Name;
                        ilib_LogEvent.fine('stockedSerialObj.SVMX_PS_External_ID__c : '+stockedSerialObj.SVMX_PS_External_ID__c);
                        // Prepare serials map passed from JSon
                        stockSerialsInJson.put(wrapperLocations.Location + wrapperStockedSerial.Name,wrapperStockedSerial);
                        
                        //populate product
                        stockedSerialObj.SVMXC__Product__c = productMaterialIdToPrdId.containsKey(wrapperProductStocks.SVMXC_Product) ? productMaterialIdToPrdId.get(wrapperProductStocks.SVMXC_Product) : null;

                        //prashanth- INC0214764 start 
                        if (installedProductEquipmentToIPId.containsKey(wrapperStockedSerial.Equipment_Id)) {
                            stockedSerialObj.SVMX_PS_VS_Linked_Installed_Product__c = installedProductEquipmentToIPId.get(wrapperStockedSerial.Equipment_Id);
                            //prashanth - INC0214764 end
                        }else {
                            //An installed product will be created for all of them.
                            stockSerialExtIdToStockSerial.put(stockedSerialObj.SVMX_PS_External_ID__c, stockedSerialObj);
                            stockSerialExtIdToLocId.put(stockedSerialObj.SVMX_PS_External_ID__c, locationExtIdToLocationId.get(wrapperLocations.Location));
                            stockSerialExtIdToIPERPID.put(stockedSerialObj.SVMX_PS_External_ID__c, wrapperStockedSerial.Equipment_Id);//INC0214764
                        }

                        uow.registerRelationship(stockedSerialObj, SVMXC__Product_Serial__c.SVMXC__Product_Stock__c, productStockObj);
                        stockedSerialWork.registerUpsert(stockedSerialObj);

                    }
                    
                    if (wrapperProductStocks.StockedBatch != null && !wrapperProductStocks.StockedBatch.isEmpty()){
                        for (InventoryDataReceiverWrapper.StockedBatch wrapperStockedBatch: wrapperProductStocks.StockedBatch) {
                            SVMXC__Product_Serial__c stockedSerialObj = wrapperStockedBatch.getSObject();
                            ilib_LogEvent.fine('stockedSerialObj : '+stockedSerialObj);
                                //External Id = Location + Product Code + Batch Number.
                            stockedSerialObj.SVMX_PS_External_ID__c = wrapperLocations.Location + wrapperProductStocks.SVMXC_Product + wrapperStockedBatch.Batch_Number;
                            ilib_LogEvent.fine('stockedSerialObj.SVMX_PS_External_ID__c : '+stockedSerialObj.SVMX_PS_External_ID__c);
                            //populate product
                            stockedSerialObj.SVMXC__Product__c = productMaterialIdToPrdId.containsKey(wrapperProductStocks.SVMXC_Product) ? productMaterialIdToPrdId.get(wrapperProductStocks.SVMXC_Product) : null;
                            //DCP-46257
                            if(boolIsIncremental && mapExternalIdToStockedSerial.containsKey(stockedSerialObj.SVMX_PS_External_ID__c)){
                                stockedSerialObj.Quantity__c = mapExternalIdToStockedSerial.get(stockedSerialObj.SVMX_PS_External_ID__c).Quantity__c + wrapperStockedBatch.Quantity;
                                wrapperStockedBatch.Quantity = stockedSerialObj.Quantity__c;
                            }
                            // Prepare serials map passed from JSon
                            batchNumbersInJson.put(stockedSerialObj.SVMX_PS_External_ID__c,wrapperStockedBatch);
                            uow.registerRelationship(stockedSerialObj, SVMXC__Product_Serial__c.SVMXC__Product_Stock__c, productStockObj);
                            stockedSerialWork.registerUpsert(stockedSerialObj);
                        }
                    }
                }
            }
        }
		ilib_LogEvent.info('stockSerialExtIdToLocId : '+stockSerialExtIdToLocId);
		ilib_LogEvent.info('stockSerialExtIdToIPERPID : '+stockSerialExtIdToIPERPID);
        ilib_LogEvent.pop();
    }
    /**
     *  @author 
     *  @description Process product serial for transaction history
     **/
    private static void processProductSerials(){
        /*==========Processing Serials Start=============*/
        ilib_LogEvent.push(LOG_TITLE+'processProductSerials()');
        for(SVMXC__Product_Stock__c prodStock : productStocksInSFDC){
			ilib_LogEvent.message('prodStock : '+prodStock);
            if(!productStocksInJson.containsKey(prodStock.SVMX_PS_External_ID__c)){
                productStockProcessObj.add(prodStock);
                if(prodStock.SVMXC__Status__c == STRING_PRODUCTSTOCK_AVAILABLE && prodStock.SVMXC__Quantity2__c > 0){
                    lstStocKHistory.add(ServiceUtilityCollection.createTransationHistoryRecord('Decrease', prodStock, null, 'Consumed', 'Stock Adjustment',prodStock.SVMXC__Quantity2__c));
                }
            }else{
                InventoryDataReceiverWrapper.ProductStock wrapperProductStocks = productStocksInJson.get(prodStock.SVMX_PS_External_ID__c);
                if(prodStock.SVMXC__Status__c == STRING_PRODUCTSTOCK_AVAILABLE && prodStock.SVMXC__Quantity2__c > 0){
                    Decimal qtyInJSON = Decimal.valueof(wrapperProductStocks.SVMXC_Quantity2);
                    if(qtyInJSON < prodStock.SVMXC__Quantity2__c){
                        lstStocKHistory.add(ServiceUtilityCollection.createTransationHistoryRecord('Decrease', prodStock, null, 'Consumed', 'Stock Adjustment',qtyInJSON - prodStock.SVMXC__Quantity2__c));
                    }else if(qtyInJSON > prodStock.SVMXC__Quantity2__c){
                        lstStocKHistory.add(ServiceUtilityCollection.createTransationHistoryRecord('Increase', prodStock, null, STRING_PRODUCTSTOCK_AVAILABLE, 'Stock Adjustment',prodStock.SVMXC__Quantity2__c - qtyInJSON));
                    }
                }
            }
        }
        for(SVMXC__Product_Serial__c stockSerial : stockSerialsInSFDC){        
			ilib_LogEvent.message('stockSerial : '+stockSerial);
            //PRB0047876: stockedSerialProcessObj should contain Serialized, Serialized+Batched records
            //for Serialized, Batched+Serialized Stock Serial records, SVMX_PS_External_ID__c = Location+Name 
            if(!stockSerialsInJson.containsKey(stockSerial.SVMX_PS_External_ID__c) && !stockSerial.SVMX_PS_External_ID__c.contains(stockSerial.Product_Code__c )  ){              
                stockedSerialProcessObj.add(stockSerial);  
            }
            else if(stockSerial.Batch_Number__c != null){ //To identify batched Stocked serial/batch records
                //for Batched Stock Serial records, SVMX_PS_External_ID__c = Location+ProductCode+Batch Number
                if(!batchNumbersInJson.containsKey(stockSerial.SVMX_PS_External_ID__c)){
                    batchProcessObj.add(stockSerial);
                }else if(batchNumbersInJson.containsKey(stockSerial.SVMX_PS_External_ID__c) && batchNumbersInJson.get(stockSerial.SVMX_PS_External_ID__c).Quantity < stockSerial.Quantity__c){
                    stockSerial.Quantity__c = stockSerial.Quantity__c - batchNumbersInJson.get(stockSerial.SVMX_PS_External_ID__c).Quantity;
                    batchProcessObj.add(stockSerial);                     
                }
            }
        }       
        // Process stocks and stock serials to maintain sync and historical data
        processStockAndStockSerials(productStockProcessObj,stockedSerialProcessObj,batchProcessObj,batchNumbersInJson,consumedBatchProdStockVsBatchRec);
      
        /*==========Processing Serials END=============*/
        ilib_LogEvent.pop();
    }
    /**
     *  @author 
     *  @description Process product stock and serial for sync
     **/
    /*==========Processing Serials START=============*/
    private static void processStockAndStockSerials(List<SVMXC__Product_Stock__c>productStockProcessObj,List<SVMXC__Product_Serial__c>stockedSerialProcessObj, List<SVMXC__Product_Serial__c> batchProcessObj,Map<String,InventoryDataReceiverWrapper.StockedBatch> batchNumbersInJson,Map<Id,List<SVMXC__Product_Serial__c>> consumedBatchProdStockVsBatchRec){
        ilib_LogEvent.push(LOG_TITLE+'processStockAndStockSerials()');
        Map<String,SVMXC__Product_Stock__c> productStockSFDCAvailable = new Map<String,SVMXC__Product_Stock__c>();
        Map<String,SVMXC__Product_Stock__c> serialProductStockSFDCConsumed = new Map<String,SVMXC__Product_Stock__c>();
        Map<String,SVMXC__Product_Stock__c> batchedStockSFDCConsumed = new Map<String,SVMXC__Product_Stock__c>();
        Map<Id,SVMXC__Product_Stock__c> availableProductStocksToUpdate = new Map<Id,SVMXC__Product_Stock__c>();
        Map<String,SVMXC__Product_Serial__c> finalStockSerials = new Map<String,SVMXC__Product_Serial__c>();
        Map<String,SVMXC__Product_Stock__c> consumedProdStockForSerial = new Map<String,SVMXC__Product_Stock__c>();
        Map<String,SVMXC__Product_Stock__c> consumedProdStockForBatch = new Map<String,SVMXC__Product_Stock__c>();
        Map<String,SVMXC__Product_Stock__c> consumedProdStocksToUpdate = new Map<String,SVMXC__Product_Stock__c>();
        Map<Id,SVMXC__Product_Stock__c> updateConsumedProdStockForSerial = new Map<Id,SVMXC__Product_Stock__c>();
        Map<String,SVMXC__Product_Stock__c> nonSerialConsumedStocksInSFDC = new Map<String,SVMXC__Product_Stock__c>();
        Map<Id,SVMXC__Product_Stock__c> updateNonSerialConsumedStocks = new Map<Id,SVMXC__Product_Stock__c>();
        Map<String,SVMXC__Product_Stock__c> insertNonSerialConsumedStocks = new Map<string,SVMXC__Product_Stock__c>();
        Map<String,SVMXC__Product_Stock__c> productStocks = new Map<String,SVMXC__Product_Stock__c>();

        for (SVMXC__Product_Stock__c prodStock : productStockProcessObj){
			ilib_LogEvent.message('prodStock : '+prodStock);
            String prodStockKey = prodStock.SVMXC__Location__c+''+prodStock.SVMXC__Product__c;
			ilib_LogEvent.message('prodStockKey : '+prodStockKey);
            if(prodStock.SVMXC__Status__c == STRING_PRODUCTSTOCK_AVAILABLE){
                productStockSFDCAvailable.put(prodStockKey,prodStock);
            }
            else if(prodStock.SVMXC__Status__c == 'Consumed'){
                if(prodStock.SVMX_PS_VS_Product_Tracking__c=='Non-Tracked'){
                    nonSerialConsumedStocksInSFDC.put(prodStockKey,prodStock);
                }else if(prodStock.SVMX_PS_VS_Product_Tracking__c==STRING_PRODUCTSTOCK_SERIALIZED){ // Serial consumed stock records
                    serialProductStockSFDCConsumed.put(prodStockKey,prodStock);  
                } else{
                    batchedStockSFDCConsumed.put(prodStockKey,prodStock);
                }               
            }                        
        }
                
        // Process available stock records left in SFDC and update the quantity field
        for(SVMXC__Product_Stock__c prodStock :productStockSFDCAvailable.values()){
            if(prodStock.SVMX_PS_VS_Product_Tracking__c=='Non-Tracked'){
                if(nonSerialConsumedStocksInSFDC.containskey(prodStock.SVMXC__Location__c+''+prodStock.SVMXC__Product__c)){  
                    nonSerialConsumedStocksInSFDC.get(prodStock.SVMXC__Location__c+''+prodStock.SVMXC__Product__c).SVMXC__Quantity2__c +=prodStock.SVMXC__Quantity2__c;
                    updateNonSerialConsumedStocks.put(nonSerialConsumedStocksInSFDC.get(prodStock.SVMXC__Location__c+''+prodStock.SVMXC__Product__c).id,nonSerialConsumedStocksInSFDC.get(prodStock.SVMXC__Location__c+''+prodStock.SVMXC__Product__c));                
                }else{
                    //Create consumed product stock for the non serial stock if not exists                
                    SVMXC__Product_Stock__c consumedProductStock = new SVMXC__Product_Stock__c();
                    consumedProductStock.SVMXC__Product__c = prodStock.SVMXC__Product__c;
                    consumedProductStock.SVMXC__Location__c = prodStock.SVMXC__Location__c;
                    consumedProductStock.SVMXC__Status__c = 'Consumed';
                    consumedProductStock.SVMXC__Quantity2__c = prodStock.SVMXC__Quantity2__c;
                    insertNonSerialConsumedStocks.put(prodStock.SVMXC__Location__c+''+prodStock.SVMXC__Product__c,consumedProductStock);                
                } 
            }
            // Update QTY as 0 in available stock existing in system
            prodStock.SVMXC__Quantity2__c = 0;
            // Add available stocks to update
            availableProductStocksToUpdate.put(prodStock.id,prodStock);
        } 
        ilib_LogEvent.info('updateNonSerialConsumedStocks Ids : '+(updateNonSerialConsumedStocks != NULL ? String.valueOf(updateNonSerialConsumedStocks.keySet()) : 'NULL'));
        // Process stock serial records and create serial consumed stocks with QTY 0 if not exists in the system
        for(SVMXC__Product_Serial__c stockSerial :stockedSerialProcessObj){
            if(!serialProductStockSFDCConsumed.containskey(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c)){                
                SVMXC__Product_Stock__c consumedProductStock = new SVMXC__Product_Stock__c();
                consumedProductStock.SVMXC__Product__c = stockSerial.SVMXC__Product__c;
                consumedProductStock.SVMXC__Location__c = stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c;
                consumedProductStock.SVMXC__Status__c = 'Consumed';
                consumedProductStock.SVMXC__Quantity2__c = 0;
                consumedProdStockForSerial.put(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c,consumedProductStock);
            }
        }
        
        // Process stock serial records and create serial consumed stocks with QTY 0 if not exists in the system
        for(SVMXC__Product_Serial__c stockSerial :batchProcessObj){
            if(!batchedStockSFDCConsumed.containskey(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c)){                
                SVMXC__Product_Stock__c consumedProductStock = new SVMXC__Product_Stock__c();
                consumedProductStock.SVMXC__Product__c = stockSerial.SVMXC__Product__c;
                consumedProductStock.SVMXC__Location__c = stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c;
                consumedProductStock.SVMXC__Status__c = 'Consumed';
                consumedProductStock.SVMXC__Quantity2__c = 0;
				consumedProdStockForBatch.put(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c,consumedProductStock);
            }
        }

        if(!insertNonSerialConsumedStocks.isEmpty() && insertNonSerialConsumedStocks.values()[0]!=null){
            productStocks.putAll(insertNonSerialConsumedStocks);   
        }        
        if(!consumedProdStockForSerial.isEmpty() && consumedProdStockForSerial.values()[0]!=null){
            productStocks.putAll(consumedProdStockForSerial); 
        }
        if(!consumedProdStockForBatch.isEmpty() && consumedProdStockForBatch.values()[0]!=null){
            productStocks.putAll(consumedProdStockForBatch); 
        }
        
        //Insert consumed stocks
        if(!productStocks.isEmpty() && productStocks.values()[0]!=null){
            insert productStocks.values();
            if(!consumedProdStockForSerial.isEmpty() && consumedProdStockForSerial.values()[0]!=null){
                consumedProdStocksToUpdate.putAll(consumedProdStockForSerial);  
            }
            
            if(!consumedProdStockForBatch.isEmpty() && consumedProdStockForBatch.values()[0]!=null){
                consumedProdStocksToUpdate.putAll(consumedProdStockForBatch);  
            }
        }
        // Combine inserted Stock records with existing
        if(!serialProductStockSFDCConsumed.isEmpty() && serialProductStockSFDCConsumed.values()[0]!=null){
            consumedProdStocksToUpdate.putAll(serialProductStockSFDCConsumed);   
        } 
        if(!batchedStockSFDCConsumed.isEmpty() && batchedStockSFDCConsumed.values()[0]!=null){
            consumedProdStocksToUpdate.putAll(batchedStockSFDCConsumed);   
        }        
        
        for(SVMXC__Product_Serial__c stockSerial : stockedSerialProcessObj){
            if(consumedProdStocksToUpdate.containsKey(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c)){
                if(stockSerial.SVMXC__Product_Stock__c != consumedProdStocksToUpdate.get(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c).Id){
                    stockSerial.SVMXC__Product_Stock__c = consumedProdStocksToUpdate.get(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c).Id;  
                    consumedProdStocksToUpdate.get(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c).SVMXC__Quantity2__c +=1;
                    updateConsumedProdStockForSerial.put(consumedProdStocksToUpdate.get(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c).id,consumedProdStocksToUpdate.get(stockSerial.SVMXC__Product_Stock__r.SVMXC__Location__c+''+stockSerial.SVMXC__Product__c)); 
                    finalStockSerials.put(stockSerial.Id,stockSerial) ;  
                }
            }
        }
		system.debug('## batchProcessObj : ' + batchProcessObj);
        for(SVMXC__Product_Serial__c batchNumberSFDC : batchProcessObj){
            ilib_LogEvent.message('batchNumberSFDC : '+batchNumberSFDC);
            String productStockKey = batchNumberSFDC.SVMXC__Product_Stock__r.SVMXC__Location__c+''+batchNumberSFDC.SVMXC__Product__c;
            SVMXC__Product_Stock__c consumedProductStock = consumedProdStocksToUpdate.get(productStockKey);
            InventoryDataReceiverWrapper.StockedBatch batchNumberJSON = batchNumbersInJson.get(batchNumberSFDC.SVMX_PS_External_ID__c);
            Boolean consumedBatchRecFound = false;
            
            Decimal quantityToBeUpdated = 0;
            // if(batchNumberJSON == null){
            //     quantityToBeUpdated = batchNumberSFDC.Quantity__c;
            // }else{
            //     quantityToBeUpdated = batchNumberSFDC.Quantity__c - batchNumberJSON.Quantity;
            // }
            quantityToBeUpdated = batchNumberSFDC.Quantity__c;
            
            //if(consumedProductStock != null && consumedBatchProdStockVsBatchRec.containsKey(consumedProductStock.Id)){
            if(consumedProductStock != null){    
                if(consumedBatchProdStockVsBatchRec.containsKey(consumedProductStock.Id)){
                for(SVMXC__Product_Serial__c consumedBatchNumberSFDC : consumedBatchProdStockVsBatchRec.get(consumedProductStock.Id))
                { 
                    if(consumedBatchNumberSFDC.SVMXC__Product__c == batchNumberSFDC.SVMXC__Product__c && 
                       consumedBatchNumberSFDC.Batch_Number__c == batchNumberSFDC.Batch_Number__c)
                    {
                        consumedBatchNumberSFDC.Quantity__c += quantityToBeUpdated;
                    	consumedBatchRecFound = true;
                    	finalStockSerials.put(consumedBatchNumberSFDC.Id,consumedBatchNumberSFDC) ;  
                        break; 
                    }
                }
                }
                if(!consumedBatchRecFound){
                    SVMXC__Product_Serial__c consumedBatchNumberSFDC = batchNumberSFDC.clone();
                    consumedBatchNumberSFDC.Quantity__c = quantityToBeUpdated;
                    consumedBatchNumberSFDC.SVMXC__Product_Stock__c = consumedProductStock.Id;
                    consumedBatchNumberSFDC.SVMX_PS_External_ID__c = consumedBatchNumberSFDC.SVMX_PS_External_ID__c + 'Consumed';
					//Added for PRB0045098
					consumedBatchNumberSFDC.SVMXC__Active__c = true;
                    finalStockSerials.put(consumedBatchNumberSFDC.SVMX_PS_External_ID__c,consumedBatchNumberSFDC) ;  
                }

                consumedProductStock.SVMXC__Quantity2__c += quantityToBeUpdated;	
                updateConsumedProdStockForSerial.put(consumedProdStocksToUpdate.get(batchNumberSFDC.SVMXC__Product_Stock__r.SVMXC__Location__c+''+batchNumberSFDC.SVMXC__Product__c).id,consumedProdStocksToUpdate.get(batchNumberSFDC.SVMXC__Product_Stock__r.SVMXC__Location__c+''+batchNumberSFDC.SVMXC__Product__c)); 

            }

            
            if(batchNumberSFDC != null && batchNumberJSON == null){
                batchNumberSFDC.Quantity__c = 0;
                finalStockSerials.put(batchNumberSFDC.SVMX_PS_External_ID__c,batchNumberSFDC) ;  
            }
        }
        // update stock serial records
        if(!finalStockSerials.isEmpty()){
            system.debug('Stocked Serials KEY SET --> '+finalStockSerials.keySet());
			ilib_LogEvent.info('finalStockSerials KEY SET : '+(finalStockSerials != NULL ? String.valueOf(finalStockSerials.keySet()) : 'NULL'));
            upsert finalStockSerials.values();         
        }
        
        // Combine all stock records update in single map to avoid multiple DML 
        if(!updateNonSerialConsumedStocks.isEmpty() && updateNonSerialConsumedStocks.values()[0]!=null){
            updateConsumedProdStockForSerial.putAll(updateNonSerialConsumedStocks); 
        }       
        if(!availableProductStocksToUpdate.isEmpty() && availableProductStocksToUpdate.values()[0]!=null){
            updateConsumedProdStockForSerial.putAll(availableProductStocksToUpdate);    
        }  
        
        if(!updateConsumedProdStockForSerial.isEmpty()){ 
            system.debug('Product Stocks KEY SET --> '+updateConsumedProdStockForSerial.keySet());
            update updateConsumedProdStockForSerial.values();
        }
        ilib_LogEvent.info('updateConsumedProdStockForSerial Ids : '+(updateConsumedProdStockForSerial != NULL ? String.valueOf(updateConsumedProdStockForSerial.keySet()):'NULL'));
        ilib_LogEvent.pop();
    } // Method END
    /*==========Processing Serials END=============*/
    /**
     *  @author 
     *  @description Added for DCP-22362. Created Installed Products for Stocked serials for which the serial number is not available and attach back the lookup.
     *  @param 
     *  @return 
     **/
    private static void createInstalledProduct(Map < String, SVMXC__Product_Serial__c > stockSerialExtIdToStockSerial, Map < String, String > stockSerialExtIdToLocId, Map < String, String > stockSerialExtIdToIPERPID, Map<String, String> mapProductIdCode) {//INC0214764
        ilib_LogEvent.push(LOG_TITLE+'createInstalledProduct()');
		ilib_LogEvent.info('stockSerialExtIdToStockSerial Ids : '+(stockSerialExtIdToStockSerial != NULL ? String.valueOf(stockSerialExtIdToStockSerial.keySet()) : 'NULL'));
        List < SVMXC__Installed_Product__c > lstInstalledProducts = new List < SVMXC__Installed_Product__c > (); //to insert new installed products
        List < SVMXC__Product_Serial__c > lstStockedSerialToUpdate = new List < SVMXC__Product_Serial__c > (); // existing stocked serials to updated with IP lookup.
        Map < String, String > installedProdNameToId = new Map < String, String > (); // Installed prod name to Installed prod Id.
		
        //get the id of newly created stockedSerial records based on external Id.
		
        for (SVMXC__Product_Serial__c stockedSerialRecs: [Select Id,SVMX_PS_External_ID__c from SVMXC__Product_Serial__c where SVMX_PS_External_ID__c IN: stockSerialExtIdToStockSerial.keyset()]) {
            stockSerialExtIdToStockSerial.get(stockedSerialRecs.SVMX_PS_External_ID__c).id = stockedSerialRecs.Id;
        }

        //Iterate over stocked serials which have no lookup to installed products.
        for (String stockedSerialIds: stockSerialExtIdToStockSerial.keyset()) {
			String productId = stockSerialExtIdToStockSerial.get(stockedSerialIds).SVMXC__Product__c;
            SVMXC__Installed_Product__c installedProducts = new SVMXC__Installed_Product__c();
			//prashanth INC0214764
			//changed istalled product name format to be uniform in all interfaces as serialnumber & product code.
            installedProducts.Name = mapProductIdCode.containsKey(productId) ? stockSerialExtIdToStockSerial.get(stockedSerialIds).Name+'-'+mapProductIdCode.get(productId) : stockSerialExtIdToStockSerial.get(stockedSerialIds).Name;
            installedProducts.SVMXC__Serial_Lot_Number__c = stockSerialExtIdToStockSerial.get(stockedSerialIds).Name;
            installedProducts.SVMXC__Status__c = 'Shipped';
            installedProducts.SVMXC__Product__c = stockSerialExtIdToStockSerial.get(stockedSerialIds).SVMXC__Product__c;
            installedProducts.SVMXC__Site__c = stockSerialExtIdToLocId.get(stockedSerialIds);
			installedProducts.ERP_Equipment_ID__c = stockSerialExtIdToIPERPID.get(stockedSerialIds);//INC0214764				
            lstInstalledProducts.add(installedProducts);
        }

        //create new IP records
        if (lstInstalledProducts != null && !lstInstalledProducts.isEmpty())
            insert lstInstalledProducts;
            ilib_LogEvent.info('lstInstalledProducts Ids : '+UtilsCollection.getsetOfIds(lstInstalledProducts));

        //attach the inserted installed products to respective stocked serials.
        for (SVMXC__Installed_Product__c instProdIds: lstInstalledProducts) {
            //prashanth INC0214764
            //as name will be in formmat of serail number- product code , changing the key from name to serial number
            installedProdNameToId.put(instProdIds.SVMXC__Serial_Lot_Number__c, instProdIds.Id);
        }
        ilib_LogEvent.info('installedProdNameToId : '+installedProdNameToId);
        //attach existing stocked serials with IP
        for (String stockedSerialIds: stockSerialExtIdToStockSerial.keyset()) {
            SVMXC__Product_Serial__c stockedSerialRec = new SVMXC__Product_Serial__c(Id = stockSerialExtIdToStockSerial.get(stockedSerialIds).Id, SVMX_PS_VS_Linked_Installed_Product__c = installedProdNameToId.get(stockSerialExtIdToStockSerial.get(stockedSerialIds).Name));
            lstStockedSerialToUpdate.add(stockedSerialRec);
        }

        if (lstStockedSerialToUpdate != null && !lstStockedSerialToUpdate.isEmpty())
            update lstStockedSerialToUpdate;
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description Custom Exception innner class
    */
    public class CustomException extends Exception {}

}

/*
SAMPLE INPUT RECEIVED

[{
    "Action": "",
    "Indicator": "",
    "Location": "10021",
    "ProductStock": [{
        "SVMXC_Product": "20002063",
        "SVMXC_Quantity2": "10",
        "SVMXC_Status": "Available",
        "StockedSerial": [{
            "Name": "1",
            "Batch_Number": "1",
            "Batch_Expiration": "2019-11-20",
			"Equipment_ID":"1234567" 
        }, {
            "Name": "2",
            "Batch_Number": "2",
            "Batch_Expiration": "2019-11-20",
			"Equipment_ID":"1234567" 
        }],
        "StockedBatch": [{
            "Batch_Number": "B-1",
            "Quantity": "1",
            "Batch_Expiration": "2019-11-20",
			"Equipment_ID":"1234567" 
        }, {
            "Batch_Number": "B-2",
            "Quantity": "1",
            "Batch_Expiration": "2019-11-20",
			"Equipment_ID":"1234567" 
        }]
    }]
}]
*/
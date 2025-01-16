/***************************************************************************************************************************************
* NAME         : PartsOrderDataReceiver
* DESCRIPTION  : Parts Order Synchronization to DCP(ServiceMax)
* @AUTHOR      : 
* @DATE        : 12-Oct-2018  
* Test Class for 75%: TestPartsOrderDataReceiver
* Test Class for 90%: TestParstOrderDataReceiver
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Nitin                    22-sept-2022        CMSI-223 Instrumentation 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shivani Jain           30-08-2022            DCP-50068 - Updated the Feature Flag for Missing Products Functionality
* Rucha Dalvi            22-12-2022            INC0426603 - Added createInstalledProduct method to link IP details in case of PGI
* Vineeta Verma          20-12-2023            PRB0047806 - To restrict change of Location for Intrument IPs when PO is synced
* Nidhi Hegde             12-02-2024            [CMCM-4585] Resolve Quality Notification integration: tracking num & return reason
* Lekhasree              10-06-2024            INC0509276 - Populating Account Name after PO processing on IP to enable visiblity to CP users
****************************************************************************************************************************************/
@RestResource(urlMapping = '/PartsOrderSyncInterface/*')
global with sharing class PartsOrderDataReceiver extends ilib_RestReceiver {

    private static List <PartsOrderDataReceiverWrapper.PartsOrder> wrapPartsOrders;
    private static final String LOG_TITLE = 'PartsOrderDataReceiver';
    //DCP-47694
    public static final String STRING_PART_ORDER_LINE_STATUS_PARTIALLY_SHIPPED = 'Partially Shipped';
    public static final String STRING_PART_ORDER_LINE_STATUS_REQUESTED = 'Requested';
    public static final String STRING_COMPLETE = 'Complete';
    public static final String STRING_COMPLETED = 'Completed';
    public static final String STRING_SHIPPED = 'Shipped';
    public static final String STRING_OPEN = 'Open';
    public static final String STRING_FEATURE_FLAG_MISSING_PRODUCT = 'UpdatePOLsIPsWithMissingProds';  //DCP-50068
    public static final String STRING_INSTRUMENT = 'Instrument';
    public static final String NULLSTR = 'Null';
    public static Map < String, Map < String, String >> objectToPicklistValueMap = UtilsSettings.getCustomMetadataPicklistMap('SVMXC__RMA_Shipment_Line__c', 'ERP', false); //Picklist mapping - Parts Order Line (Return Reason)
    public static List < String > SERVICE_PRODUCT_TYPE = new List < String > {'Spare' , 'Instrument' , 'Consumable'}; 
    @HttpPost
    /*
    * @description: This method is used to upsert Incoming JSON Inputs
    * @return: void
    */	
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        PartsOrderDataReceiver instantiated = new PartsOrderDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name,ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE+'.upsertIncomingValues()');
        String strRestError = null;
        Id primaryRecordId;
        String erpCustomerId;

        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
        ilib_LogEvent.info('JSON Input:\n' + strJsonInput);
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            //if there is no body found, throw an error.
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, wrapPartsOrders);

            primaryRecordId = upsertIncomingValuesImpl();
            ilib_LogEvent.info('primaryRecordId : '+primaryRecordId);
            erpCustomerId = getRelatedErpCustomerId('SVMXC__RMA_Shipment_Order__c', 'SVMXC__Service_Order__r.SVMXC__Company__r', primaryRecordId);
            ilib_LogEvent.info('erpCustomerId : '+erpCustomerId);
        }
        catch (Exception e)
        {
            strRestError = UtilsRest.handleCustomRestError(e);
            ilib_LogEvent.info('strRestError : '+strRestError);
        }

        Boolean isSuccess = String.isBlank(strRestError);
        ilib_LogEvent.info('isSuccess : '+isSuccess);
        if (isSuccess) {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

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

    private static void deserializeInputs(String jsonInput)
    {
        ilib_LogEvent.push(LOG_TITLE+'.deserializeInputs()');
        wrapPartsOrders = (List < PartsOrderDataReceiverWrapper.PartsOrder > ) System.JSON.deserialize(jsonInput, List < PartsOrderDataReceiverWrapper.PartsOrder > .class);
        ilib_LogEvent.pop();
    }

    private static Id upsertIncomingValuesImpl()
    {
        ilib_LogEvent.push(LOG_TITLE+'.upsertIncomingValuesImpl()');
        SVMXC__RMA_Shipment_Order__c oneOrder;

        /* REGISTER HELPERS : MANDATORY STEP */
        // Register custom helpers: This is a mandatory step.
        ilib_UpsertHelpers.PartsOrderUnitofWorkHelper partsOrderWork = new ilib_UpsertHelpers.PartsOrderUnitofWorkHelper();
        ilib_UpsertHelpers.PartsOrderLineUnitOfWorkHelper partsOrderLineWork = new ilib_UpsertHelpers.PartsOrderLineUnitOfWorkHelper();
        /* END */

        /* STORE ALL LOOKUP VARIABLES HERE */

        //Product lookup based on Material Number of Product.
        Set < String > productExtIdSet = new Set < String > ();
        //ProductExtIdSet to check for missing Product
        Set < String > productExtIdSetForMissingProds = new Set < String > ();
        //Map ProductMaterialId to PrdId
        Map < String, String > productMaterialIdToPrdId = new Map < String, String > ();
		//DCP-23809
        Map < String, String > productMaterialToPrdServiceType = new Map < String, String > ();

        //From Location lookup based on External Id.
        Set < String > fromLocationExtIdSet = new Set < String > ();
        //Map ExternalId to Location Id
        Map < String, String > fromLocationExtIdToLocationId = new Map < String, String > ();

        //From Location lookup based on External Id.
        Set < String > toLocationExtIdSet = new Set < String > ();
        //Map ExternalId to Location Id
        Map < String, String > toLocationExtIdToLocationId = new Map < String, String > ();
        
		//prashanth-INC0214764 start
		//set of equipment Id
        Set<String> equipmentIdSet = new Set<String>();
        //Map Equipment Id to Installed product Id in sfdc
		Map<String, String> equipmentIdToInstalledProductId = new Map<String, String>();
		//prashanth-INC0214764 end
		
        //Delete existing parts order line
        Set < String > partsOrderExtIdSet = new Set < String > ();
        List < SVMXC__RMA_Shipment_Line__c > oldLstPartsOrderLine = new List < SVMXC__RMA_Shipment_Line__c > ();
		
        //Ritika : Added for INC0276378
        Map < String, SVMXC__RMA_Shipment_Order__c > erpSalesOrderNumberToPartsOrder = new Map < String, SVMXC__RMA_Shipment_Order__c > ();
        //Nidhi : Added for CMCM-91
        Map < String, String > erpSalesOrderNumberToPartsOrderType = new Map < String, String > ();
        //Added for DCP-23607
        Map < String, SVMXC__RMA_Shipment_Line__c > erpSalesOrderItemNumberToPartsOrderLine = new Map < String, SVMXC__RMA_Shipment_Line__c > ();

        /*UPSERT DONE USING THIS VARIABLE*/
        //Map parent object with the list of child objects.
        Map < String, List < String > > partsOrderextIdToPartsOrderLineId = new Map < String, List < String > > ();
		
		 //prashanth-INC0214764 start
		// set to hold new equipment Number from the JSON
        //Set<String> newEquipmentIdSet = new Set<String>();
		//prashanth-INC0214764 end
		//DCP-44455
        Map<String, SVMXC__RMA_Shipment_Line__c> mapNewPartOrderLines = new Map<String, SVMXC__RMA_Shipment_Line__c>();
        /*END*/
        //DCP-47694
        Map<String, SVMXC__RMA_Shipment_Line__c> mapOldPO = new Map<String,SVMXC__RMA_Shipment_Line__c>();
        Set<String> setPartiallyShippedLineItems = new Set<String>();
        Set<String> setOpenLineItems = new Set<String>();
        /* UNIT OF WORK : GENERIC STATEMENT */
        //unit of work: This is a mandatory step.
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List < Schema.SObjectType > {
                SVMXC__RMA_Shipment_Order__c.SObjectType,
                SVMXC__RMA_Shipment_Line__c.SObjectType
            });
        /* / UNIT OF WORK : GENERIC STATEMENT */

        /* REGISTER OBJECTS : GENERIC STATEMENT */
        //register your objects: This is a mandatory step.
        uow.registerWork(partsOrderWork);
        uow.registerWork(partsOrderLineWork);
        /* / REGISTER OBJECTS : GENERIC STATEMENT */

        //if the recieved JSON body is not null, process it.
        if (wrapPartsOrders != null) {

            /** POPULATE LOOKUP VARIABLES **/
            //iterate over parent records.
            for (PartsOrderDataReceiverWrapper.PartsOrder wrapperPartsOrders: wrapPartsOrders) {
                
                if (String.isNotBlank(wrapperPartsOrders.SVMXC_Sales_Order_Number))
                        partsOrderExtIdSet.add(wrapperPartsOrders.SVMXC_Sales_Order_Number);

                /* ITERATE OVER CHILD RECORDS */
                //Iterate over the child records. 
                for (PartsOrderDataReceiverWrapper.PartsOrderLine wrapperPartsOrderLines: wrapperPartsOrders.PartsOrderLine) {

                    if (String.isNotBlank(wrapperPartsOrderLines.SVMXC_Product)){
                        productExtIdSet.add(wrapperPartsOrderLines.SVMXC_Product);
                        //RITM0503667
                        productExtIdSetForMissingProds.add(wrapperPartsOrderLines.SVMXC_Product);
                    }

                    if (String.isNotBlank(wrapperPartsOrderLines.From_Location))
                        fromLocationExtIdSet.add(wrapperPartsOrderLines.From_Location);

                    if (String.isNotBlank(wrapperPartsOrderLines.To_Location))
                        toLocationExtIdSet.add(wrapperPartsOrderLines.To_Location);
                    
					//Add equipment Id to a set : prashanth-INC0214764     
                    if (String.isNotBlank(wrapperPartsOrderLines.SVMXC_Equipment_Number)){         
                        equipmentIdSet.add(wrapperPartsOrderLines.SVMXC_Equipment_Number);
                    } 
                            

                }

            }

            /********************************************************** Getting Salesforce Id of lookup variables ****************************/
            //Map ProductMaterialId to PrdId  r.Material_Number__c productExtIdSet
            for (Product2 prdM: new ProductsSelector().selectProductsForMaterialNumber(productExtIdSet)) {
                productMaterialIdToPrdId.put(prdM.Material_Number__c, prdM.id);
				//DCP-23809
                productMaterialToPrdServiceType.put(prdM.Material_Number__c, prdM.Service_Product_Type__c);
                productExtIdSetForMissingProds.remove(prdM.Material_Number__c);
            }

            //Map fromLocationExtIdToLocationId
            for (SVMXC__Site__c location: new LocationsSelector().selectLocationsForExternalId(fromLocationExtIdSet)) {
                fromLocationExtIdToLocationId.put(location.SVMX_PS_External_ID__c, location.id);
            }

            //Map fromLocationExtIdToLocationId
            for (SVMXC__Site__c location: new LocationsSelector().selectLocationsForExternalId(toLocationExtIdSet)) {
                toLocationExtIdToLocationId.put(location.SVMX_PS_External_ID__c, location.id);
            }
			
            //prashanth-INC0214764 start
            ilib_LogEvent.info('equipmentIdSet : '+equipmentIdSet);
            //Map equipmentIdToInstalledProductId
            
            for (SVMXC__Installed_Product__c installedProds: new InstalledProductsSelector().selectInstallProductsForEquipmentIds(equipmentIdSet)) {
                equipmentIdToInstalledProductId.put(installedProds.ERP_Equipment_ID__c, installedProds.id);
            }
            ilib_LogEvent.info('equipmentIdToInstalledProductId : '+equipmentIdToInstalledProductId);
            
			//check for new equipment number in the Json
			/*for(String equipmentId : equipmentIdSet){
                if(equipmentIdToInstalledProductId!=null && (!equipmentIdToInstalledProductId.containsKey(equipmentId))){
                    newEquipmentIdSet.add(equipmentId);
                }
            }
            system.debug('newEquipmentIdSet ==>'+newEquipmentIdSet);*/
			//prashanth-INC0214764 End
			
            //Ritika : Added for INC0276378
            for(SVMXC__RMA_Shipment_Order__c partsOrder : new PartsOrdersSelector().selectPartsOrdersWithName(partsOrderExtIdSet)){
                erpSalesOrderNumberToPartsOrder.put(partsOrder.ERP_Sales_Order_Number__c, partsOrder);
                erpSalesOrderNumberToPartsOrderType.put('partsOrderAccount',partsOrder.SVMXC__Company__c);
                // CMCM-91
                erpSalesOrderNumberToPartsOrderType.put(partsOrder.ERP_Sales_Order_Number__c,partsOrder.SVMXC__Order_Type__c);
            }
            for (SVMXC__RMA_Shipment_Line__c partsOrderLines: new PartsOrderLineSelector().selectPartsOrderLineByPartsOrderExtId(partsOrderExtIdSet)) { 
			//added for DCP-23607
             erpSalesOrderItemNumberToPartsOrderLine.put(partsOrderLines.ERP_Sales_Order_Item__c,partsOrderLines);	
             oldLstPartsOrderLine.add(partsOrderLines);
             //DCP-47694
             if(partsOrderLines.External_ID__c == null){
                mapOldPO.put(partsOrderLines.ERP_Sales_Order_Item__c, partsOrderLines);
             }  
            }
            
            /********************************************************** INSTANTIATE SOBEJCTS AND ITS FIELDS ****************************/
			Map<String,SVMXC__Installed_Product__c> partOrderLineExtIDToIP = new Map<String,SVMXC__Installed_Product__c>();
			Map<String,SVMXC__RMA_Shipment_Line__c> partOrderLineObjMap = new Map<String,SVMXC__RMA_Shipment_Line__c>();
            //Iterate over Parent Object
            for (PartsOrderDataReceiverWrapper.PartsOrder wrapperPartsOrders: wrapPartsOrders)
            {
                Boolean polMissingProduct = false;
                ilib_LogEvent.message('polMissingProduct : '+polMissingProduct);
                //get the object details from the method created in PartsOrderDataReceiverWrapper.
                //It has all the fields information which will be updated.
                SVMXC__RMA_Shipment_Order__c partsOrderObj = wrapperPartsOrders.getSObject();
                oneOrder = partsOrderObj;
                ilib_LogEvent.message('oneOrder : '+oneOrder);
                partsOrderWork.registerUpsert(partsOrderObj);

                /* ITERATE OVER CHILD RECORDS */
                //Iterate over the child records. 
                for (PartsOrderDataReceiverWrapper.PartsOrderLine wrapperPartsOrderLines: wrapperPartsOrders.PartsOrderLine)
                {
                    //get the object details from the method created in PartsOrderDataReceiverWrapper.
                    //It has all the fields information which will be updated.
                    SVMXC__RMA_Shipment_Line__c partsOrderLineObj = wrapperPartsOrderLines.getSObject();
                    String partsOrderType = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c : erpSalesOrderNumberToPartsOrderType.containsKey(wrapperPartsOrders.SVMXC_Sales_Order_Number) ? erpSalesOrderNumberToPartsOrderType.get(wrapperPartsOrders.SVMXC_Sales_Order_Number) : '';
                    ilib_LogEvent.fine('partsOrderType : '+partsOrderType);
                    if(partsOrderType == 'Return'){
                        partsOrderLineObj.External_ID__c = wrapperPartsOrders.SVMXC_Sales_Order_Number + wrapperPartsOrderLines.ERP_Sales_Order_Item;
                        partsOrderLineObj.SVMXC__Actual_Quantity2__c =(String.IsNotBlank(wrapperPartsOrderLines.Shipped_Qty) ? Decimal.valueOf(wrapperPartsOrderLines.Shipped_Qty.trim()) : 0);
                        partsOrderLineObj.SVMXC__Line_Status__c = wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_COMPLETE) || wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_COMPLETED) ? STRING_SHIPPED : wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_OPEN) ? STRING_PART_ORDER_LINE_STATUS_REQUESTED : wrapperPartsOrderLines.SVMXC_Line_Status;
                    }else{
                        //DCP-47694
                        populateExternalId(wrapperPartsOrderLines, wrapperPartsOrders, partsOrderLineObj);
                        //populate the line status of parts order line.
                        if(Feature.isOn(PartsOrderLines.PARTIAL_SHIPMENT)){
                            partsOrderLineObj.SVMXC__Line_Status__c = wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_COMPLETE) || wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_COMPLETED) || wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_PART_ORDER_LINE_STATUS_PARTIALLY_SHIPPED) ? STRING_SHIPPED : wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_OPEN) ? STRING_PART_ORDER_LINE_STATUS_REQUESTED : wrapperPartsOrderLines.SVMXC_Line_Status;
                            //populate original POL: DCP-47694.
                            partsOrderLineObj.Original_Parts_Order_Line__c = mapOldPO.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? mapOldPO.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).Id : null;
                            partsOrderLineObj.Shipped_Qty__c =(String.IsNotBlank(wrapperPartsOrderLines.Shipped_Qty) ? Decimal.valueOf(wrapperPartsOrderLines.Shipped_Qty.trim()) : 0); 
                        }else{
                            partsOrderLineObj.SVMXC__Line_Status__c = wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_COMPLETE) || wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_COMPLETED) ? STRING_SHIPPED : wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_OPEN) ? STRING_PART_ORDER_LINE_STATUS_REQUESTED : wrapperPartsOrderLines.SVMXC_Line_Status;
                        }
                        partsOrderLineObj.SVMXC__Actual_Quantity2__c = mapOldPO.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? mapOldPO.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).SVMXC__Actual_Quantity2__c : null;
                    }
                    
                    
                    //populate product
                    partsOrderLineObj.SVMXC__Product__c = productMaterialIdToPrdId.containsKey(wrapperPartsOrderLines.SVMXC_Product) ? productMaterialIdToPrdId.get(wrapperPartsOrderLines.SVMXC_Product) : null;
                    partsOrderLineObj.Product_Code1__c = wrapperPartsOrderLines.SVMXC_Product;//RITM0503667
                    if(partsOrderLineObj.SVMXC__Product__c == null)
                        polMissingProduct = true;
                    //populate from location
                    partsOrderLineObj.From_Location__c = fromLocationExtIdToLocationId.containsKey(wrapperPartsOrderLines.From_Location) ? fromLocationExtIdToLocationId.get(wrapperPartsOrderLines.From_Location) : null;

                    //populate to location
                    partsOrderLineObj.To_Location__c = toLocationExtIdToLocationId.containsKey(wrapperPartsOrderLines.To_Location) ? toLocationExtIdToLocationId.get(wrapperPartsOrderLines.To_Location) : null;
                    
                    //populate Installed Product
					//prashanth-INC0214764 start
					//partsOrderLineObj.SVMXC__Serial_Number__c = equipmentIdToInstalledProductId.containsKey(wrapperPartsOrderLines.SVMXC_Equipment_Number) ? equipmentIdToInstalledProductId.get(wrapperPartsOrderLines.SVMXC_Equipment_Number) : null;
					if(equipmentIdToInstalledProductId.containsKey(wrapperPartsOrderLines.SVMXC_Equipment_Number)){
                        partsOrderLineObj.SVMXC__Serial_Number__c = equipmentIdToInstalledProductId.get(wrapperPartsOrderLines.SVMXC_Equipment_Number);
                        //Added as part of INC0426603
                        //PRB0047806:added prduct type as parameter to createInstalledProduct
                        InstalledProductObj ipfieldsOBJ = new InstalledProductObj(wrapperPartsOrderLines.SVMXC_Serial_Number_List, wrapperPartsOrderLines.SVMXC_Equipment_Number, wrapperPartsOrderLines.SVMXC_Product, productMaterialToPrdServiceType.get(wrapperPartsOrderLines.SVMXC_Product),erpSalesOrderNumberToPartsOrderType.get('partsOrderAccount'), wrapperPartsOrderLines.MAC_Address); //CMCM-9541
                        partOrderLineExtIDToIP.put(partsOrderLineObj.External_ID__c,createInstalledProduct(partsOrderLineObj, ipfieldsOBJ));
                    }
                    else{ 
                        //47694 - added check for bypassing the open lines(will create wuth svmxc__line_status__c = requested)
                        if(productMaterialToPrdServiceType.get(wrapperPartsOrderLines.SVMXC_Product) != 'Consumable' && String.isNotBlank(wrapperPartsOrderLines.SVMXC_Serial_Number_List) && partsOrderLineObj.SVMXC__Line_Status__c != STRING_PART_ORDER_LINE_STATUS_REQUESTED){
                            //Ritika - Fix added for INC0247392
                            partOrderLineObjMap.put(partsOrderLineObj.External_ID__c, partsOrderLineObj);
                            //Prashanth-Added equipment number, product code for INC0214764
                            //PRB0047806:added prduct type as parameter to createInstalledProduct
                            InstalledProductObj ipfieldsOBJ = new InstalledProductObj(wrapperPartsOrderLines.SVMXC_Serial_Number_List, wrapperPartsOrderLines.SVMXC_Equipment_Number, wrapperPartsOrderLines.SVMXC_Product, productMaterialToPrdServiceType.get(wrapperPartsOrderLines.SVMXC_Product),erpSalesOrderNumberToPartsOrderType.get('partsOrderAccount'), wrapperPartsOrderLines.MAC_Address); //CMCM-9541
                            partOrderLineExtIDToIP.put(partsOrderLineObj.External_ID__c, createInstalledProduct(partsOrderLineObj,ipfieldsOBJ));
                        }
                    }
                    //prashanth-INC0214764 end
					
                    //update the Sales Order number on line object as well.
                    partsOrderLineObj.ERP_Sales_Order__c = wrapperPartsOrders.SVMXC_Sales_Order_Number;
                    
					 //Added for DCP-23607
                    //Copy the original line item information to the new ones.
                    partsOrderLineObj.PO_Number__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).PO_Number__c : '';
                    partsOrderLineObj.COD_Uploaded__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).COD_Uploaded__c : '';
                    partsOrderLineObj.RMA__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).RMA__c : '';
                    partsOrderLineObj.Return_Reason__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).Return_Reason__c : '';
                    partsOrderLineObj.No_Substitute_Parts__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).No_Substitute_Parts__c : Boolean.valueOf('');
                    partsOrderLineObj.Is_Billable__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).Is_Billable__c : Boolean.valueOf('');
                    partsOrderLineObj.Linked_Line_Item__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).Linked_Line_Item__c : '';
                    partsOrderLineObj.Reason__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).Reason__c : '';
                    partsOrderLineObj.Tracking_Number__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).Tracking_Number__c : '';
					//DCP-44455
                    partsOrderLineObj.Loaner_Agreement_Signed__c = erpSalesOrderItemNumberToPartsOrderLine.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item) ? erpSalesOrderItemNumberToPartsOrderLine.get(wrapperPartsOrderLines.ERP_Sales_Order_Item).Loaner_Agreement_Signed__c : false;
                    ilib_LogEvent.message('Tracking_Number : '+wrapperPartsOrderLines.Tracking_Number);
                    ilib_LogEvent.message('Return_Reason_Code : '+wrapperPartsOrderLines.Return_Reason_Code);
                    ilib_LogEvent.message('objectToPicklistValueMap : '+objectToPicklistValueMap);
                    
					// CMCM-4585 - START
					if (String.isNotBlank(wrapperPartsOrderLines.Tracking_Number)) {
                        partsOrderLineObj.Tracking_Number__c = String.valueOf(wrapperPartsOrderLines.Tracking_Number);
                    }
                    if (String.isNotBlank(wrapperPartsOrderLines.Return_Reason_Code)) {
                        partsOrderLineObj.Controlling_Return_Reason__c = SERVICE_PRODUCT_TYPE.contains(productMaterialToPrdServiceType.get(wrapperPartsOrderLines.SVMXC_Product)) ? productMaterialToPrdServiceType.get(wrapperPartsOrderLines.SVMXC_Product) : SERVICE_PRODUCT_TYPE.get(0);
                        partsOrderLineObj.Return_Reason__c  = objectToPicklistValueMap.get('Return_Reason__c').get(wrapperPartsOrderLines.Return_Reason_Code);
                    }
                    ilib_LogEvent.message('Tracking Number : '+partsOrderLineObj.Tracking_Number__c);
                    ilib_LogEvent.message('Controlling Return Reason : '+partsOrderLineObj.Controlling_Return_Reason__c);
                    ilib_LogEvent.message('Return Reason : '+partsOrderLineObj.Return_Reason__c);
                   // CMCM-4585 - END
					//prashanth-INC0214764 start				
                    //Create an Installed Product record if the equipment number recieved from SAP is not available in SVMX.                     
					/* if((equipmentIdToInstalledProductId.keyset() == null || equipmentIdToInstalledProductId.keyset().isEmpty()||(!newequipmentIdSet.isEmpty())) && !newequipmentIdSet.isEmpty() && productMaterialToPrdServiceType.get(wrapperPartsOrderLines.SVMXC_Product) != 'Consumable' ){
                        if(String.isNotBlank(wrapperPartsOrderLines.SVMXC_Serial_Number_List)){
                            //Ritika - Fix added for INC0247392
                            partOrderLineObjMap.put(partsOrderLineObj.External_ID__c, partsOrderLineObj);
                            //Prashanth-Added equipment number, product code for INC0214764
                            partOrderLineExtIDToIP.put(partsOrderLineObj.External_ID__c, createInstalledProduct(partsOrderLineObj,wrapperPartsOrderLines.SVMXC_Serial_Number_List, wrapperPartsOrderLines.SVMXC_Equipment_Number,wrapperPartsOrderLines.SVMXC_Product));
                            //partsOrderLineObj.SVMXC__Serial_Number__c = createInstalledProduct(partsOrderLineObj,wrapperPartsOrderLines.SVMXC_Serial_Number_List);
                        }
                    }*/
					//prashanth-INC0214764 end

                    //Ritika : Added for INC0276378
                    if(!erpSalesOrderNumberToPartsOrder.containskey(partsOrderObj.ERP_Sales_Order_Number__c) && !partsOrderObj.ERP_Sales_Order_Number__c.startsWith('8')){
                        partsOrderObj.SVMXC__Order_Type__c = 'Shipment';
                        partsOrderObj.SVMXC__Destination_Location__c =partsOrderLineObj.To_Location__c;
                        partsOrderObj.SVMXC__Source_Location__c =partsOrderLineObj.From_Location__c;
                        erpSalesOrderNumberToPartsOrder.put(partsOrderObj.ERP_Sales_Order_Number__c,partsOrderObj);
                    }
                    //47694 - added check for bypassing the open lines(will create wuth svmxc__line_status__c = requested)
                    if(partsOrderLineObj.SVMXC__Line_Status__c != STRING_PART_ORDER_LINE_STATUS_REQUESTED){
                        uow.registerRelationship(partsOrderLineObj, SVMXC__RMA_Shipment_Line__c.SVMXC__RMA_Shipment_Order__c, partsOrderObj);
                        partsOrderLineWork.registerUpsert(partsOrderLineObj);
                        
                        //DCP-44455
                        mapNewPartOrderLines.put(partsOrderLineObj.ERP_Sales_Order_Item__c,partsOrderLineObj);
                    }
                    //DCP-50941 defect fix (multiple same orderlineitems in the same payload)
                    if(Feature.isOn(PartsOrderLines.PARTIAL_SHIPMENT) && mapOldPO.containsKey(wrapperPartsOrderLines.ERP_Sales_Order_Item)){
                        if(wrapperPartsOrderLines.SVMXC_Line_Status.equalsIgnoreCase(STRING_PART_ORDER_LINE_STATUS_PARTIALLY_SHIPPED)){
                            setPartiallyShippedLineItems.add(wrapperPartsOrderLines.ERP_Sales_Order_Item);
                        }else if(partsOrderLineObj.SVMXC__Line_Status__c == STRING_PART_ORDER_LINE_STATUS_REQUESTED){
                            //ignore open lines while cancelling the original pol.
                            setOpenLineItems.add(wrapperPartsOrderLines.ERP_Sales_Order_Item);
                        }
                    }
                    ilib_LogEvent.fine('partsOrderLineObj : '+partsOrderLineObj);
                }
                
                //DCP-47694 - update old parts order line to partially shipped if the status is coming as partially shipped from SAP.
                //assigning line_status as 'Requested' if it is not partially shipment because we have cancellation logic of Original POL in ilib_UpsertHelpers class. In that class, before cancelling a POL we have a condition for checking "line_status != canceled".
                //If we ssign line_status as canceled here, it would bypass that particular POL while cancelling. To include this original POL, doing a dummy assignment to 'requested' and cancelling the line in ilib__UpsertHepers class.
                //DCP-50941 defect fix (mulitple same orderlineitems in the same payload)
                if(Feature.isOn(PartsOrderLines.PARTIAL_SHIPMENT)){
                    for(String erpOrderLineItem : mapOldPO.keySet()){
                        if(setPartiallyShippedLineItems.contains(erpOrderLineItem)){
                            mapOldPO.get(erpOrderLineItem).SVMXC__Line_Status__c = STRING_PART_ORDER_LINE_STATUS_PARTIALLY_SHIPPED;
                        }
                        else if(setOpenLineItems.contains(erpOrderLineItem) && !setPartiallyShippedLineItems.contains(erpOrderLineItem)){
                            mapOldPO.remove(erpOrderLineItem);
                        }else{
                            mapOldPO.get(erpOrderLineItem).SVMXC__Line_Status__c = STRING_PART_ORDER_LINE_STATUS_REQUESTED;
                        }
                    }
                }
                //delete existing parts order line
                //DCP-47694 to accommadate partially shipped value update changes, changed the param from list to map.values().
                partsOrderLineWork.registerDelete(mapOldPO.values());
                if(polMissingProduct){
                    String warningMsg = erpSalesOrderNumberToPartsOrder.get(partsOrderObj.ERP_Sales_Order_Number__c).Warning_Message__c;
                    partsOrderObj.Warning_Message__c = 'One or more shipped line items of this Parts Order are missing Products. GFSL is working on it. Please be informed till that time inventory sync or auto-debrief won\'t happen. \n' + (warningMsg == null? '':warningMsg);
                    ilib_LogEvent.message('warningMsg : '+warningMsg);
                    ilib_LogEvent.message('partsOrderObj.Warning_Message__c : '+partsOrderObj.Warning_Message__c);
                }
                
            }
			
			//Ritika - Fix added for INC0247392
                if(!partOrderLineExtIDToIP.isempty()){
                    //insert partOrderLineExtIDToIP.values();
                    upsert partOrderLineExtIDToIP.values() ERP_Equipment_ID__c;
                    for(String partOrderLineExtId : partOrderLineObjMap.keySet()){
                        SVMXC__RMA_Shipment_Line__c partsOrderLineObj = partOrderLineObjMap.get(partOrderLineExtId);
                        partsOrderLineObj.SVMXC__Serial_Number__c = partOrderLineExtIDToIP.get(partOrderLineExtId).Id;
                    }
                }
            
            ilib_LogEvent.info('partOrderLineExtIDToIP : '+(partOrderLineExtIDToIP != Null ? String.valueof(partOrderLineExtIDToIP):NULLSTR));
            ilib_LogEvent.info('partOrderLineObjMap : '+(partOrderLineObjMap!= Null ? String.valueof(partOrderLineObjMap.keySet()):NULLSTR));
        }
        ilib_LogEvent.info('productExtIdSet : '+productExtIdSet);
        ilib_LogEvent.info('productExtIdSetForMissingProds : '+productExtIdSetForMissingProds);
        ilib_LogEvent.info('productMaterialIdToPrdId : ' + productMaterialIdToPrdId);
        ilib_LogEvent.info('productMaterialToPrdServiceType : '+productMaterialToPrdServiceType);
        ilib_LogEvent.info('fromLocationExtIdSet : ' + fromLocationExtIdSet);
        ilib_LogEvent.info('fromLocationExtIdToLocationId : ' + fromLocationExtIdToLocationId);
        ilib_LogEvent.info('toLocationExtIdSet : ' + toLocationExtIdSet);
        ilib_LogEvent.info('toLocationExtIdToLocationId : '+ toLocationExtIdToLocationId);
        ilib_LogEvent.info('partsOrderExtIdSet : ' + partsOrderExtIdSet);
        ilib_LogEvent.info('erpSalesOrderNumberToPartsOrder : '+(erpSalesOrderNumberToPartsOrder != Null ? String.valueof(erpSalesOrderNumberToPartsOrder):NULLSTR));
        ilib_LogEvent.info('erpSalesOrderItemNumberToPartsOrderLine : '+(erpSalesOrderItemNumberToPartsOrderLine != Null ? String.valueof(erpSalesOrderItemNumberToPartsOrderLine.keySet()):NULLSTR));
        ilib_LogEvent.info('partsOrderextIdToPartsOrderLineId : '+ partsOrderextIdToPartsOrderLineId);
        ilib_LogEvent.info('mapNewPartOrderLines : '+(mapNewPartOrderLines != Null ? String.valueof(mapNewPartOrderLines):NULLSTR));
        ilib_LogEvent.info('mapOldPO : '+(mapOldPO != Null ? String.valueof(mapOldPO.keySet()):NULLSTR));
        ilib_LogEvent.info('setPartiallyShippedLineItems : '+ setPartiallyShippedLineItems);
        ilib_LogEvent.info('setOpenLineItems : '+ setOpenLineItems);
        // any business logic for incoming values goes in here
        businessRules(uow);

        uow.commitWork();
		//DCP-44455
        transferFiles(erpSalesOrderItemNumberToPartsOrderLine, mapNewPartOrderLines);
        if(!productExtIdSetForMissingProds.isEmpty()){ //RITM0503667
            if(Feature.isOn(STRING_FEATURE_FLAG_MISSING_PRODUCT)) {		 //DCP-50068 Changed Feature Flag name		
                ServiceUtilityCollection.sendEmailToGFSLAndStoreProdExtId(productExtIdSetForMissingProds);
            }
        }
        ilib_LogEvent.pop();
        return (oneOrder != null ? oneOrder.Id : null);
    }

		/*
         * description - businessRules method
		 * return - void
         */ 
    public static void businessRules(ilib_SObjectUnitOfWork uow) {
        ilib_LogEvent.push(LOG_TITLE+'.businessRules()');
        ilib_LogEvent.info('uow : '+uow);
        ilib_LogEvent.pop();
    }
    
    
    private static SVMXC__Installed_Product__c createInstalledProduct(SVMXC__RMA_Shipment_Line__c partsOrderLineObj, InstalledProductObj ipFieldsOBJ ){
        SVMXC__Installed_Product__c installedProducts = new SVMXC__Installed_Product__c();
        installedProducts.SVMXC__Serial_Lot_Number__c = ipFieldsOBJ.sVMXCSerialNumberList;
		//prashanth-INC0214764
		installedProducts.Name = ipFieldsOBJ.sVMXCSerialNumberList+'-'+ipFieldsOBJ.productCode;
        installedProducts.SVMXC__Status__c = STRING_SHIPPED;
        //PRB0047806
        if(partsOrderLineObj.SVMXC__Product__r.Service_Product_Type__c != 'Instrument'){
            installedProducts.SVMXC__Site__c = partsOrderLineObj.To_Location__c;
        }
        installedProducts.SVMXC__Site__c = partsOrderLineObj.To_Location__c;
        installedProducts.SVMXC__Product__c = partsOrderLineObj.SVMXC__Product__c;
        installedProducts.Product_Code1__c = partsOrderLineObj.Product_Code1__c;//RITM0503667
        installedProducts.SVMXC__Sales_Order_Number__c = partsOrderLineObj.ERP_Sales_Order__c;
        installedProducts.SVMXC__Date_Shipped__c = partsOrderLineObj.SVMXC__Actual_Ship_Date__c;
        installedProducts.SVMXC__Company__c = ipFieldsOBJ.Account  ;			
        //Equipment number added INC0214764
        installedProducts.ERP_Equipment_ID__c = ipFieldsOBJ.sVMXCEquipmentNumber;
        installedProducts.Mac_Address__c = ipFieldsOBJ.MAC_Address; //CMCM-9541
        ilib_LogEvent.message('installedProducts : '+installedProducts);
        return installedProducts;
    }
	/**
	* Method: transferFiles 
	* Description: This method is to copy the files from old pol to new pol
	* params: erpSalesOrderItemNumberToPartsOrderLine, mapNewPartOrderLines
	* return: void
	**/
	public static void transferFiles(Map<String, SVMXC__RMA_Shipment_Line__c> erpSalesOrderItemNumberToPartsOrderLine, Map<String, SVMXC__RMA_Shipment_Line__c> mapNewPartOrderLines){
        ilib_LogEvent.push(LOG_TITLE+'.transferFiles()');
        List<echosign_dev1__SIGN_Agreement__c> lstAgreementsToUpdate = new List<echosign_dev1__SIGN_Agreement__c>();
        List<contentDocumentLink> lstContentDocumentLinks = new List<contentDocumentLink>();
        Set<Id> setPOLHasFiles = new Set<Id>();
        //get the new POL ids
        Set<Id> setPOLIds = new Set<Id>();
        for(SVMXC__RMA_Shipment_Line__c pol : mapNewPartOrderLines.values()){
            if(pol.Id != null){
                setPOLIds.add(pol.Id);
            }
        }
        ilib_LogEvent.info('setPOLIds : '+setPOLIds);
        //populate setPOLHasFiles to restrict inserting the files again if the SAP send multiple requests with same POL.
        if(!setPOLIds.isEmpty()){
            for(ContentDocumentLink cdl : new ContentDocumentLinksSelector().selectByEmailMessagesRecordIds(setPOLIds)){
                setPOLHasFiles.add(cdl.LinkedEntityId);
            }
        }
        ilib_LogEvent.info('setPOLHasFiles : '+setPOLHasFiles);
        for(String erpOrderNum : erpSalesOrderItemNumberToPartsOrderLine.keySet()){
            SVMXC__RMA_Shipment_Line__c oldObjPOL = erpSalesOrderItemNumberToPartsOrderLine.get(erpOrderNum);
            SVMXC__RMA_Shipment_Line__c newobjPOL = mapNewPartOrderLines.containsKey(erpOrderNum) ? mapNewPartOrderLines.get(erpOrderNum) : null;
            ilib_LogEvent.message('oldObjPOL : '+oldObjPOL);
            ilib_LogEvent.message('newobjPOL : '+newobjPOL);
            if(newobjPOL != null && newobjPOL.Id != null && !setPOLHasFiles.contains(newobjPOL.Id)){
                for(echosign_dev1__SIGN_Agreement__c agreement : oldObjPOL.Agreements__r){
                    agreement.Parts_Order_Line__c = newobjPOL.Id;
                    lstAgreementsToUpdate.add(agreement);
                }
                for(contentDocumentLink link : oldObjPOL.contentDocumentLinks){
                    contentDocumentLink cDocLink = link.clone();
                    cDocLink.LinkedEntityId = newobjPOL.Id;
                    cDocLink.ShareType = 'V';
                    cDocLink.Visibility = 'InternalUsers';
                    //Insert cDocLink;
                    lstContentDocumentLinks.add(cDocLink);
                }
            }
            
        }   
        ilib_LogEvent.info('lstAgreementsToUpdate : '+UtilsCollection.getSetOfIds(lstAgreementsToUpdate));
        if(!lstAgreementsToUpdate.isEmpty()){
            update lstAgreementsToUpdate;
        }
        ilib_LogEvent.info('lstContentDocumentLinks : '+UtilsCollection.getSetOfIds(lstContentDocumentLinks));
        if(!lstContentDocumentLinks.isEmpty()){
            insert lstContentDocumentLinks;
        }
        ilib_LogEvent.pop();
    }
    /**
     * Method: populateExternalId
     * Description: populate the external id field on POL: DCP-47694
     * params: wrapperPartsOrderLines, wrapperPartsOrders, partsOrderLineObj
     * return: SVMXC__RMA_Shipment_Line__c
     */
    public static SVMXC__RMA_Shipment_Line__c populateExternalId(PartsOrderDataReceiverWrapper.PartsOrderLine wrapperPartsOrderLines,PartsOrderDataReceiverWrapper.PartsOrder wrapperPartsOrders,SVMXC__RMA_Shipment_Line__c partsOrderLineObj){
        if (String.isNotBlank(wrapperPartsOrderLines.SVMXC_Serial_Number_List)) {
            partsOrderLineObj.External_ID__c = wrapperPartsOrders.SVMXC_Sales_Order_Number + wrapperPartsOrderLines.ERP_Sales_Order_Item + wrapperPartsOrderLines.SVMXC_Serial_Number_List;
        } else if (String.isNotBlank(wrapperPartsOrderLines.Batch_Number)) {
            partsOrderLineObj.External_ID__c = wrapperPartsOrders.SVMXC_Sales_Order_Number + wrapperPartsOrderLines.ERP_Sales_Order_Item + wrapperPartsOrderLines.Batch_Number;
        } else {
            partsOrderLineObj.External_ID__c = wrapperPartsOrderLines.ERP_Sales_Order_Item + wrapperPartsOrders.SVMXC_Sales_Order_Number;
        }
        //partial shipment feature flag is on.
        if(Feature.isOn(PartsOrderLines.PARTIAL_SHIPMENT) && String.isNotblank(wrapperPartsOrderLines.Delivery)){ 
            partsOrderLineObj.External_ID__c += wrapperPartsOrderLines.Delivery;    
        }
        ilib_LogEvent.message('partsOrderLineObj : '+partsOrderLineObj);
        return partsOrderLineObj;
    }
    /*
    * description - To send parameters into createInstalledProduct method
    */ 
    private class InstalledProductObj{
        String sVMXCSerialNumberList;
        String sVMXCEquipmentNumber;
        String productCode;
        String sVMXCProductType;
        String account;
        String MAC_Address; //CMCM-9541
        /*
        * description - constructor
        */ 
     public InstalledProductObj(String serialNumList, String eqNumber, String pdCode, String productType,String accountName, String macAddress){
        	sVMXCSerialNumberList = serialNumList;
        	sVMXCEquipmentNumber = eqNumber;
        	productCode = pdCode;
        	sVMXCProductType = productType;
            account = accountName;
            MAC_Address = macAddress; //CMCM-9541
        }
    }

}

/*
SAMPLE INPUT RECIEVED

[{
    "SVMXC_Order_Status": "Complete",
    "Integration_Error_Message": "Completed",
    "SVMXC_Sales_Order_Number": "0001601389",
    "PartsOrderLine": [{
        "ERP_Sales_Order_Item": "000010",
        "SVMXC_Product": "20004162",
        "Shipped_qty":"1.000",
        "Delivery":"12345_6789",
        "SVMXC_Expected_Ship_Date": "2018-12-11",
        "Expected_Delivery_Date": "2018-12-12",
        "SVMXC_Actual_Ship_Date": "2018-12-11",
        "Actual_Delivery_Date": "2018-12-12",
        "SVMXC_Line_Status": "Complete",
        "SVMXC_Serial_Number_List": "",
        "From_Location": "TS100171",
        "Batch_Number": "20257504",
        "Name": "LN-00242961",
        "Requested_Delivery_Date": "2018-12-11"
    }]
}]
*/
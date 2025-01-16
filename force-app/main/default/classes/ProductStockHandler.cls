/**************************************************************************************************************************************
 * NAME   : ProductStockHandler
 * DESCRIPTION  : Class to handle inventory update on Parts Order shipment / reuturn / stock transfer
 *                    
 * @AUTHOR : Ritika Maheshwari
 * @DATE   :   
 *  
 * MODIFICATION LOG: 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika               20-Nov-2020          Changes made for batch management
  ****************************************************************************************************************************************/ 

public without sharing class ProductStockHandler{

    public static final String STRING_PRODUCT_STOCK_STATUS_AVAILABLE = 'Available';
    public static final String STRING_PRODUCT_STOCK_STATUS_RETURN = 'Return';
	public static final String STRING_PRODUCT_STOCK_TRANSFER = 'Stock Transfer';
    //DCP-47694
    public static final String PARTIAL_SHIPMENT = 'Partial_Shipment';
    // To store the ERP Customer Id with respective To Location
    static Map<Id,String> idToLocationErp = new Map <Id,String>();  
    // To store the ERP Customer Id with respective To Location
    static Map<Id,String> idFromLocationErp = new Map <Id,String>();
    //Map of btach stocked serials
    static Map<String, SVMXC__Product_Serial__c> batchKeyToBatchStockMap = new Map<String, SVMXC__Product_Serial__c>();
    
    static Map<String,SVMXC__Product_Serial__c> lstStockSerialToBeUpserted = new Map<String,SVMXC__Product_Serial__c>();
	
    //Map of parts order line ID versus product associated with it
    static Map<Id,Id> polIdToProductId = new Map<Id,Id>();
        
    //Map of Available Product Stock for the the From location and product selected on Parts Order Line
    static Map<String,SVMXC__Product_Stock__c> fromLocationProductStockMap = new Map<String,SVMXC__Product_Stock__c>();
    //Set of Ids for From Location Product Stock
    static Set<Id> setLocationProductStockIds = new Set<Id>();
    //Map of Available Product Stock for the the To location and product selected on Parts Order Line
    static Map<String,SVMXC__Product_Stock__c> toLocationProductStockMap = new Map<String,SVMXC__Product_Stock__c>();
    //Map of Return Product Stock
    static Map<String,SVMXC__Product_Stock__c> returnedProductStockMap = new Map<String,SVMXC__Product_Stock__c>();
    //Map of Stock serial number vs stocked serial
    static Map<String,SVMXC__Product_Serial__c> stockedSerialNumberToRecordMap = new Map<String,SVMXC__Product_Serial__c>(); //Will there be only one stock serrial per stock for a product?
    //Return or stock transfer product stock versus its stock serial map 
    static Map<String, List<SVMXC__Product_Serial__c>> returnProdStockToStockSerialMap = new Map<String, List<SVMXC__Product_Serial__c>>();
    
    static Map<Id,SVMXC__Product_Stock__c> polToLstProductStockToBeUpdated = new Map<Id,SVMXC__Product_Stock__c>();
    static Map<Id,SVMXC__Product_Stock__c> polToLstProductStockToBeInserted = new Map<Id,SVMXC__Product_Stock__c>();
    static Map<String, SVMXC__Product_Stock__c> uniqueStringToProductStockToBeInserted = new Map<String,SVMXC__Product_Stock__c>();
    static Map<String, List<SVMXC__Product_Serial__c>> newProdStockKeyToStockSerialToBeReparented = new  Map<String, List<SVMXC__Product_Serial__c>>();
    static List<SVMXC__Product_Serial__c> lstStockSerialToBeReparented = new  List<SVMXC__Product_Serial__c>();
    
    static List<SVMXC__Stock_History__c> lstStocKHistory = new List<SVMXC__Stock_History__c>();
    static Set<String> setPartsOrderTypes = new Set<String>{'Shipment', 'Replenishment'};
    
/* @Story number - DCP - 47694
 * @Author - Prashanth
 */ 
    public static void partsOrderShippedMechanism(Set<Id> setPOLIds){
        //Map of Parts Order Line Id versus Part Order Line record
        Map<Id,SVMXC__RMA_Shipment_Line__c> polIdToPOLRecord = new Map<Id,SVMXC__RMA_Shipment_Line__c>();  
        
        
        //query fields related to POL being updated.
        for(SVMXC__RMA_Shipment_Line__c pol : new PartsOrderLineSelector().selectPartsOrderLineForProductType(setPOLIds, 'Spare')){
            polIdToProductId.put(pol.Id, pol.SVMXC__Product__c);
            polIdToPOLRecord.put(pol.Id, pol);
            if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c != null && pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__r.SVMXC__Stocking_Location__c){
                idFromLocationErp.put(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c,null);
            }
            if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c != null && pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__r.SVMXC__Stocking_Location__c){
                idToLocationErp.put(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c,null);
            }
        }
        fetchLocationDetails();
        fetchProductStockDetails();
        fetchStockSerials();
        
        //Iterate on the POL and update inventory
        for(SVMXC__RMA_Shipment_Line__c pol : polIdToPOLRecord.values()){
            processToLocationInventory(pol);
            processFromLocationInventory(pol);
        }
        //DML Statements to update the inventory
        if(!polToLstProductStockToBeUpdated.isEmpty()){
            update polToLstProductStockToBeUpdated.values();
        }
        system.debug('## polToLstProductStockToBeInserted : ' + polToLstProductStockToBeInserted);
        system.debug('## uniqueStringToProductStockToBeInserted : ' + uniqueStringToProductStockToBeInserted);
        if(!polToLstProductStockToBeInserted.isEmpty()){
            insert uniqueStringToProductStockToBeInserted.values();
            for(Id polId : polToLstProductStockToBeInserted.keySet()){
                SVMXC__RMA_Shipment_Line__c pol = polIdToPOLRecord.get(polId);
                String strToLocationKey = getProductStockKey(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c, pol.SVMXC__Product__c);
                String returnProdStockKey = getProductStockKeyForReturns(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c, pol.SVMXC__Product__c,pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c);
                //Create Stock Serials and Batch Serials for the new Product Stocks created at To Location
                if(uniqueStringToProductStockToBeInserted.containskey(strToLocationKey) && (pol.SVMXC__Serial_Number__c != null || pol.Batch_Number__c != null)){
					//If new product stock is created for 'Stock Transfer' then just reparent to Stocked serial
                    if(newProdStockKeyToStockSerialToBeReparented.containsKey(strToLocationKey)){
                        for(SVMXC__Product_Serial__c stockSerial : newProdStockKeyToStockSerialToBeReparented.get(strToLocationKey))
                        {
                            if(stockSerial != null && stockSerial.SVMX_PS_VS_Linked_Installed_Product__c == pol.SVMXC__Serial_Number__c ){
                                stockSerial.SVMXC__Product_Stock__c = polToLstProductStockToBeInserted.get(pol.Id).Id;
                                stockSerial.SVMX_PS_External_ID__c = idToLocationErp.get(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c) + pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c;
                                lstStockSerialToBeReparented.add(stockSerial);
                                system.debug('## stockSerial : ' + stockSerial); 
                            }
                        }
                    }
                    //For Shipment of all type of products and Stock Transfer for batch products create new stock / batch serials
                    else{
                        createStockedBatchOrSerialRecord(pol,polToLstProductStockToBeInserted.get(pol.Id),true);
                    }
                }
                //For Return PO, reparent the Stocked Serial to Return Product Stock created
                else if(returnProdStockToStockSerialMap.containsKey(returnProdStockKey)){ 
                    for(SVMXC__Product_Serial__c stockSerial : returnProdStockToStockSerialMap.get(returnProdStockKey)){
                        stockSerial.SVMXC__Product_Stock__c = polToLstProductStockToBeInserted.get(pol.Id).Id;
                        lstStockSerialToBeUpserted.put(stockSerial.SVMX_PS_External_ID__c,stockSerial);
                        system.debug('## lstStockSerialToBeUpserted 5 : ' + lstStockSerialToBeUpserted);
                    }
                }
                //For return PO, if it is not serialized part, then create a new stocked serial for batched part
                else if(uniqueStringToProductStockToBeInserted.containskey(returnProdStockKey)){
                    createStockedBatchOrSerialRecord(pol,polToLstProductStockToBeInserted.get(pol.Id),false);
                }
            }
        }
        
        if(!lstStockSerialToBeUpserted.isEmpty()){
            upsert lstStockSerialToBeUpserted.values() SVMX_PS_External_ID__c;
        }  
		if(!lstStockSerialToBeReparented.isEmpty()){
			update lstStockSerialToBeReparented;
		}
        if(!lstStocKHistory.isEmpty()){
            insert lstStocKHistory;
        }

        clearDMLLists();
    }

    private static void fetchLocationDetails(){
        // Itrate the ToLocation records and fetch the ERP Customer Id and store in a map IdToLocationErp      
        for(SVMXC__Site__c objLoc : new LocationsSelector().selectToLocations(idToLocationErp.keySet())){
            IdToLocationErp.put(objLoc.id, objLoc.ERP_Customer_ID__c);
        }
		// Itrate the FromLocation records and fetch the ERP Customer Id and store in a map idToLocationErp      
        for(SVMXC__Site__c objLoc : new LocationsSelector().selectToLocations(idFromLocationErp.keyset())){
            idFromLocationErp.put(objLoc.id, objLoc.ERP_Customer_ID__c);
        }
    }

    private static void fetchProductStockDetails(){
        //Query Available or Returned or Stock Transfer Product Stock records which are present at To Location and From Location
        for(SVMXC__Product_Stock__c productStock : new ProductStockSelector().selectProductStockByToFromLocationAndProduct(idFromLocationErp.keySet(),idToLocationErp.keySet(),polIdToProductId.values(), new Set<String>{STRING_PRODUCT_STOCK_STATUS_AVAILABLE,STRING_PRODUCT_STOCK_STATUS_RETURN,'Stock Transfer'})){
            setLocationProductStockIds.add(productStock.Id);
            //Map of from location product stock for Available status
            if(idFromLocationErp.containskey(productStock.SVMXC__Location__c) && productStock.SVMXC__Status__c == STRING_PRODUCT_STOCK_STATUS_AVAILABLE){
                fromLocationProductStockMap.put(productStock.SVMXC__Location__c + '-' + productStock.SVMXC__Product__c, productStock);
            }
            //Map of To location product stock for Available status
            if(idToLocationErp.containskey(productStock.SVMXC__Location__c) && productStock.SVMXC__Status__c == STRING_PRODUCT_STOCK_STATUS_AVAILABLE){
                toLocationProductStockMap.put(productStock.SVMXC__Location__c + '-' + productStock.SVMXC__Product__c, productStock);
            }
            //Map of From and To location product stock for Return / Stock Transfer status
            if(productStock.SVMXC__Status__c == STRING_PRODUCT_STOCK_STATUS_RETURN ){
                returnedProductStockMap.put(productStock.SVMX_PS_External_ID__c,productStock);
            }
        }
    }

    private static void fetchStockSerials(){
        //Select Serial Numbers at a particular Product Stock
        for(SVMXC__Product_Serial__c stockSerial : new StockedSerialSelector().selectStockedSerialByProductStockAndProduct(setLocationProductStockIds,polIdToProductId.values() )){ 
            //Create a map of linked IP vs stock serial record
            if(stockSerial.SVMX_PS_VS_Linked_Installed_Product__c != null && stockSerial.SVMX_PS_VS_Linked_Installed_Product__r != null && stockSerial.SVMXC__Product_Stock__r.SVMXC__Status__c == STRING_PRODUCT_STOCK_STATUS_AVAILABLE){
            	stockedSerialNumberToRecordMap.put(stockSerial.SVMX_PS_VS_Linked_Installed_Product__r.SVMXC__Serial_Lot_Number__c, stockSerial);
            } //Create a map of stock with batch number vs record
            else if(stockSerial.Batch_Number__c != null){
            	batchKeyToBatchStockMap.put(stockSerial.SVMX_PS_External_ID__c,stockSerial);
            }
        }
    }

    private static void processFromLocationInventory(SVMXC__RMA_Shipment_Line__c pol){
        //Check if the From Location is not null
        //If Product Stock exists, decrement the Quantity at Product Stock
        //If the installed Product exists, then move the stock serials to Returned / Stock Transfer Product Stock
        if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c != null &&
        idFromLocationErp.containskey(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c)){
            String strFromLocationKey = getProductStockKey(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c, pol.SVMXC__Product__c);
            Decimal actualQty = pol.SVMXC__Actual_Quantity2__c == null ? 0 : pol.SVMXC__Actual_Quantity2__c;
            //Check if the From Location Product Stock exists, fetch the product stock
            if(fromLocationProductStockMap.containsKey(strFromLocationKey)){
                SVMXC__Product_Stock__c fromProductStock = fromLocationProductStockMap.get(strFromLocationKey);
                //Update the from location product stock for Serialized, Non-Serialized, Batched Products
                //DCP-47694- replacing actual qty with shipped qty
                if(Feature.isOn(PARTIAL_SHIPMENT) && setPartsOrderTypes.contains(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c)){
                    fromProductStock.SVMXC__Quantity2__c = fromProductStock.SVMXC__Quantity2__c == null ? pol.Shipped_Qty__c : fromProductStock.SVMXC__Quantity2__c - pol.Shipped_Qty__c;
                }else{
                    fromProductStock.SVMXC__Quantity2__c = fromProductStock.SVMXC__Quantity2__c == null ? actualQty : fromProductStock.SVMXC__Quantity2__c - actualQty;
                }
                polToLstProductStockToBeUpdated.put(fromProductStock.Id, fromProductStock);
                
                //For Serialized and Batched products, fetch the records and move them to "Return" Product Stock
                SVMXC__Product_Serial__c stockSerial = null;
                SVMXC__Product_Serial__c batchedStockSerial = null;
                //Update product stock for serialized parts
                if(stockedSerialNumberToRecordMap.containsKey(pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c)){
                    stockSerial = stockedSerialNumberToRecordMap.get(pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c);
                }
                String batchExternalIdKey = idFromLocationErp.get(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c) + pol.Product_Code__c + pol.Batch_Lookup__r.Name;
                if(batchKeyToBatchStockMap.containsKey(batchExternalIdKey)){
                    batchedStockSerial = batchKeyToBatchStockMap.get(batchExternalIdKey);
                }
                
                //Decrement the quantity in Available Product Stock,
                if(batchedStockSerial != null){
                    //DCP-47694- replacing actual qty with shipped qty
                    if(Feature.isOn(PARTIAL_SHIPMENT) && setPartsOrderTypes.contains(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c)){
                        batchedStockSerial.Quantity__c = batchedStockSerial.Quantity__c == null ? pol.Shipped_Qty__c : batchedStockSerial.Quantity__c - pol.Shipped_Qty__c;
                    }else{
                        batchedStockSerial.Quantity__c = batchedStockSerial.Quantity__c == null ? actualQty : batchedStockSerial.Quantity__c - actualQty;
                    }
                    lstStockSerialToBeUpserted.put(batchedStockSerial.SVMX_PS_External_ID__c,batchedStockSerial);
                    system.debug('## lstStockSerialToBeUpserted 1 : ' + lstStockSerialToBeUpserted);
                }

                if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c == STRING_PRODUCT_STOCK_STATUS_RETURN && (stockSerial != null || batchedStockSerial != null)){
                    //Fetch the Product Stock For "Return" status
                    SVMXC__Product_Stock__c returnProductStock = new SVMXC__Product_Stock__c();
                    String returnProdStockKey = getProductStockKeyForReturns(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c,pol.SVMXC__Product__c,pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c);
                    //If the "Return" Product stock exists
                    //1. Increment the quantity of the Product Stock
                    //2. For Serialzied part : Reparent the 'Serialized' stocked serial  
                    //3. For Batched part : Increment the quantity in Return Product Stock
                    if(returnedProductStockMap.containsKey(returnProdStockKey)){
                        returnProductStock = returnedProductStockMap.get(returnProdStockKey);
                        //1. Incrementing the Return Product Stock quantity
                        returnProductStock.SVMXC__Quantity2__c += actualQty; 
                        polToLstProductStockToBeUpdated.put(returnProductStock.Id, returnProductStock);
                        //2. For Serialized part
                        if(stockSerial != null){
                            stockSerial.SVMXC__Product_Stock__c = returnProductStock.Id;
                            lstStockSerialToBeUpserted.put(stockSerial.SVMX_PS_External_ID__c, stockSerial);
                            system.debug('## lstStockSerialToBeUpserted 2 : ' + lstStockSerialToBeUpserted);
                        }
                        //3. For Batched part, Increment the quantity of batched serial in Return Product Stock if it exists else create new
                        else if(batchedStockSerial != null){
                            SVMXC__Product_Serial__c returnedBatchedStockSerial = batchKeyToBatchStockMap.get(batchExternalIdKey + 'Return');
                            if(returnedBatchedStockSerial != null){
                                returnedBatchedStockSerial.Quantity__c = returnedBatchedStockSerial.Quantity__c == null ? actualQty : returnedBatchedStockSerial.Quantity__c + actualQty;
                                lstStockSerialToBeUpserted.put(returnedBatchedStockSerial.SVMX_PS_External_ID__c,returnedBatchedStockSerial);
                                system.debug('## lstStockSerialToBeUpserted 3 : ' + lstStockSerialToBeUpserted);
                            }else{
                                createStockedBatchOrSerialRecord(pol,returnProductStock,false);
                            }
                        }
                    }
                    //If the "Return" Product stock does not exists
                    //1. Create Product Return Product Stock
                    //2. Serialized part : Update the Stocked serial once the return Product Stock is created
                    //3. Batched part : Create batched serial, once the return product stock is created
                    else{
                        //1. Create "Return Product Stock
                        if(uniqueStringToProductStockToBeInserted.containsKey(returnProdStockKey)){
                            returnProductStock = uniqueStringToProductStockToBeInserted.get(returnProdStockKey);
                        }
                        returnProductStock = createProductStock(returnProductStock, pol, pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c, pol.SVMXC__Actual_Quantity2__c,returnProdStockKey,'Source');
                        polToLstProductStockToBeInserted.put(pol.Id,returnProductStock);
                        uniqueStringToProductStockToBeInserted.put(returnProdStockKey,returnProductStock);
                        //2. map of return product stock to be inserted vs the stock serial to be updated
                        if(stockSerial != null){
                            if(!returnProdStockToStockSerialMap.containsKey(returnProdStockKey)){
                                returnProdStockToStockSerialMap.put(returnProdStockKey,new List<SVMXC__Product_Serial__c>());
                            } 
                            returnProdStockToStockSerialMap.get(returnProdStockKey).add(stockSerial);
                        }
                    }
                }
                //DCP-47694
                Decimal quantity = pol.Shipped_Qty__c != null ? pol.Shipped_Qty__c : actualQty;
                lstStocKHistory.add(ServiceUtilityCollection.createTransationHistoryRecord('Decrease', fromProductStock, stockSerial != null ? stockSerial : (batchedStockSerial != null ? batchedStockSerial : null), STRING_PRODUCT_STOCK_STATUS_RETURN, 'RMA Receipt', quantity));
            }
        }
    }

    private static void processToLocationInventory(SVMXC__RMA_Shipment_Line__c pol){
        //Check if the To Location is not null
        //If Product Stock exists, increment the Quantity at Product Stock, else create new product stock
        //If the installed Product exists, then create stock serials.
        //If the batch number exists, update the quantity on existing stocked serial else create new one 
        if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c != null && 
        idToLocationErp.containskey(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c)){
            String strToLocationKey = getProductStockKey(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c, pol.SVMXC__Product__c);
            SVMXC__Product_Stock__c toProductStock;
            system.debug('strToLocationKey=='+ strToLocationKey);
            //Available Product Stock exists 
            //1. If Shipment, then create new Stock serials for Serialized and Batched products
            //2. If Stock Transfer, then 
            //2.a Serialized part - reparent the product stock
            //2. b Batched part - Increment the quantity if batched stock serial present, else create new one
            if(toLocationProductStockMap.containsKey(strToLocationKey)){
                toProductStock = toLocationProductStockMap.get(strToLocationKey);
                //DCP-47694- replacing actual qty with shipped qty
                if(Feature.isOn(PARTIAL_SHIPMENT) && setPartsOrderTypes.contains(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c)){
                    toProductStock.SVMXC__Quantity2__c = (toProductStock.SVMXC__Quantity2__c != null && pol.Shipped_Qty__c != null) ? 
                                            toProductStock.SVMXC__Quantity2__c + pol.Shipped_Qty__c :
                                            (pol.Shipped_Qty__c != null ? pol.Shipped_Qty__c : toProductStock.SVMXC__Quantity2__c);
                }else{
                    toProductStock.SVMXC__Quantity2__c = toProductStock.SVMXC__Quantity2__c != null ? toProductStock.SVMXC__Quantity2__c + pol.SVMXC__Actual_Quantity2__c : pol.SVMXC__Actual_Quantity2__c;
                }
                polToLstProductStockToBeUpdated.put(toProductStock.Id, toProductStock);
                //1. Create new stocked serials for Shipment
                if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c != STRING_PRODUCT_STOCK_TRANSFER && (pol.SVMXC__Serial_Number__c != null || pol.Batch_Number__c != null)){
                    createStockedBatchOrSerialRecord(pol,toProductStock,true);
                } 
                //2. For Stock transfer
                else if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c == STRING_PRODUCT_STOCK_TRANSFER){
					system.debug('## stocked serial :  ' + stockedSerialNumberToRecordMap.get(pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c));
                    //2.a Serialized product
                    if(pol.Stocked_Serial__c != null && stockedSerialNumberToRecordMap.containsKey(pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c)){
						SVMXC__Product_Serial__c stockSerial = stockedSerialNumberToRecordMap.get(pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c);
						system.debug('## stockSerial : ' + stockSerial); 
                        stockSerial.SVMXC__Product_Stock__c = toProductStock.Id;
                        stockSerial.SVMX_PS_External_ID__c = idToLocationErp.get(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c) + pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c;
						lstStockSerialToBeReparented.add(stockSerial);
                    }
                    //2.b Batched product
                    else if(pol.Batch_Lookup__c != null){
                        createStockedBatchOrSerialRecord(pol,toProductStock,true);
                    }
                }
            }
            //Available Product Stock does not exists 
            else{
                toProductStock = new SVMXC__Product_Stock__c();
                if(uniqueStringToProductStockToBeInserted.containsKey(strToLocationKey)){
                    toProductStock = uniqueStringToProductStockToBeInserted.get(strToLocationKey);
                }
                //DCP-47694- replacing actual qty with shipped qty
                Decimal quantity = null;
                if(Feature.isOn(PARTIAL_SHIPMENT) && setPartsOrderTypes.contains(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c)){
                    quantity = toProductStock.SVMXC__Quantity2__c != null ? 
                                        (toProductStock.SVMXC__Quantity2__c + pol.Shipped_Qty__c) :
                                        pol.Shipped_Qty__c;
                }else{
                    quantity = toProductStock.SVMXC__Quantity2__c != null ? 
                                        (toProductStock.SVMXC__Quantity2__c + pol.SVMXC__Actual_Quantity2__c) :
                                        pol.SVMXC__Actual_Quantity2__c;
                }
                String prodStockExternalId = idToLocationErp.get(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c)+pol.Product_Code__c;
                toProductStock = createProductStock(toProductStock, pol, STRING_PRODUCT_STOCK_STATUS_AVAILABLE, quantity, prodStockExternalId,'Destination');
                polToLstProductStockToBeInserted.put(pol.Id,toProductStock);
                uniqueStringToProductStockToBeInserted.put(strToLocationKey,toProductStock);
                if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c == STRING_PRODUCT_STOCK_TRANSFER && pol.Stocked_Serial__c != null){
                    if(stockedSerialNumberToRecordMap.containsKey(pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c)){
                        if(!newProdStockKeyToStockSerialToBeReparented.containsKey(strToLocationKey)){
                            newProdStockKeyToStockSerialToBeReparented.put(strToLocationKey, new List<SVMXC__Product_Serial__c>());
                        }
                        newProdStockKeyToStockSerialToBeReparented.get(strToLocationKey).add(stockedSerialNumberToRecordMap.get(pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c));
                    }
                }
            }
        }
    }

    private static Map<String,SVMXC__Product_Serial__c> createStockedBatchOrSerialRecord(SVMXC__RMA_Shipment_Line__c pol, SVMXC__Product_Stock__c toProductStock, Boolean isShipped){
        //If it is a serialized product
        SVMXC__Product_Serial__c newStockSerial = new SVMXC__Product_Serial__c();
        newStockSerial.SVMXC__Product_Stock__c = toProductStock.Id;
        newStockSerial.SVMXC__Product__c = pol.SVMXC__Product__c;
        newStockSerial.SVMXC__Active__c = true;
            
        String externalIdKey = '';
        if(pol.SVMXC__Serial_Number__c != null){
            externalIdKey = idToLocationErp.get(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c) + pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c;
            newStockSerial.Name = pol.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c;
            newStockSerial.SVMX_PS_VS_Linked_Installed_Product__c = pol.SVMXC__Serial_Number__c;                        
            newStockSerial.SVMX_PS_External_ID__c = externalIdKey;
        }
        //If it is a batched product
        else if(pol.Batch_Number__c != null){
            if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c != null && isShipped){
                externalIdKey = idToLocationErp.get(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c) + pol.Product_Code__c + pol.Batch_Number__c;
            }else if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c != null && !isShipped){
                externalIdKey = idFromLocationErp.get(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c) + pol.Product_Code__c + pol.Batch_Number__c;
            }
            if(!isShipped){ 
                externalIdKey += STRING_PRODUCT_STOCK_STATUS_RETURN;
            }
            if(batchKeyToBatchStockMap.containsKey(externalIdKey)){
                newStockSerial = batchKeyToBatchStockMap.get(externalIdKey);
            }else{
                newStockSerial.Name = pol.Batch_Number__c;
                newStockSerial.Batch_Number__c = pol.Batch_Number__c;
            }
            //DCP-47694 use Shipped_qty for non-return Product stocks & Actual QTy for Return product stocks.
            if(isShipped && Feature.isOn(PARTIAL_SHIPMENT) && setPartsOrderTypes.contains(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c)){
                newStockSerial.Quantity__c = newStockSerial.Quantity__c == null ? pol.Shipped_Qty__c : newStockSerial.Quantity__c + pol.Shipped_Qty__c;
            }else{
                newStockSerial.Quantity__c = newStockSerial.Quantity__c == null ? pol.SVMXC__Actual_Quantity2__c : newStockSerial.Quantity__c + pol.SVMXC__Actual_Quantity2__c;
            }
            newStockSerial.SVMX_PS_External_ID__c = externalIdKey;
            newStockSerial.Batch_Expiration__c = pol.Batch_Expiration__c;
            batchKeyToBatchStockMap.put(newStockSerial.SVMX_PS_External_ID__c,newStockSerial);
        }
        lstStockSerialToBeUpserted.put(newStockSerial.SVMX_PS_External_ID__c,newStockSerial);
        system.debug('## lstStockSerialToBeUpserted 4 : ' + lstStockSerialToBeUpserted);
        //DCP-47694: replace Actual Qty with Shipped qty
        if(isShipped){
            if(Feature.isOn(PARTIAL_SHIPMENT) && setPartsOrderTypes.contains(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Order_Type__c)){
                lstStocKHistory.add(ServiceUtilityCollection.createTransationHistoryRecord('Increase', toProductStock, newStockSerial, 'Available', 'Shipment',pol.Shipped_Qty__c));
            }else{
                lstStocKHistory.add(ServiceUtilityCollection.createTransationHistoryRecord('Increase', toProductStock, newStockSerial, 'Available', 'Shipment',pol.SVMXC__Actual_Quantity2__c));
            }
        }
        return lstStockSerialToBeUpserted;
    }

    private static SVMXC__Product_Stock__c createProductStock(SVMXC__Product_Stock__c newProductStock, SVMXC__RMA_Shipment_Line__c pol, String status, Decimal quantity, String externalId, String location){
        if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c != null && location == 'Source'){
            newProductStock.SVMXC__Location__c =  pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Source_Location__c;
        }else if(pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c != null && location == 'Destination'){
        	newProductStock.SVMXC__Location__c =  pol.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c;
        }
        newProductStock.SVMXC__Status__c = status;
        newProductStock.SVMXC__Quantity2__c = quantity;
        newProductStock.SVMXC__Product__c = pol.SVMXC__Product__c;
        // Update External Id field with To Location + Product Code
        newProductStock.SVMX_PS_External_ID__c= externalId;
        return newProductStock;
    }
    
    private static void clearDMLLists(){
        polToLstProductStockToBeUpdated.clear();
        polToLstProductStockToBeInserted.clear();
        uniqueStringToProductStockToBeInserted.clear();
        lstStockSerialToBeUpserted.clear();
        lstStocKHistory.clear();
    }

    private static String getProductStockKey(String locationId, String productCode){
        return locationId + '-' + productCode;
    }
    
    private static String getProductStockKeyForReturns(String locationId, String productCode, String status){
        return locationId + '-' + productCode + '-' + status; 
    }
}
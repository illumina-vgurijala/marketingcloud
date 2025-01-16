/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to run DCIR logic 
*/ 
public with sharing class ValidateExistingWO_POLHelper {

    /*******************************************************************************************************
    * @description populateCollections
    * @param partOrderLine new record
    * @return void
    */
    public static void populateCollections(SVMXC__RMA_Shipment_Line__c partOrderLine) {
        //DCP-33467
        if ((partOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_TYPE_RETURN 
                    || partOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_STOCK_TRANSFER)
                && PartsOrderLines.partsOrderIdToPartsOrder.containsKey(partOrderLine.SVMXC__RMA_Shipment_Order__c)
                && PartsOrderLines.partsOrderIdToPartsOrder.get(partOrderLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Service_Order__c == NULL) {
            if(partOrderLine.Batch_Lookup__c !=null && partOrderLine.From_Location__c!=null && partOrderLine.SVMXC__Actual_Quantity2__c > 0) {
                PartsOrderLines.setBatchNumber.add(partOrderLine.Batch_Number__c);
                PartsOrderLines.setStockSerialId.add(partOrderLine.Batch_Lookup__c);
                PartsOrderLines.setFromLocationId.add(partOrderLine.From_Location__c);
                PartsOrderLines.setPartsOrderLinesRecords.add(partOrderLine);
            }
            if(partOrderLine.Stocked_Serial__c!=null){           
                PartsOrderLines.setStockSerialId.add(partOrderLine.Stocked_Serial__c);
                PartsOrderLines.setPartsOrderLinesRecords.add(partOrderLine);
            }
            if(partOrderLine.Stocked_Serial__c==null && partOrderLine.Batch_Number__c==null){
                PartsOrderLines.setProductStockId.add(partOrderLine.Product_Stock__c);
                PartsOrderLines.setPartsOrderLinesRecords.add(partOrderLine);
            }  
        } // DCP-33467
    }

    /*******************************************************************************************************
    * @description populateCollectionsBeforeUpdate
    * @param partOrderLine new record
    * @return void
    */
    public static void populateCollectionsBeforeUpdate(SVMXC__RMA_Shipment_Line__c partOrderLine) {
        if(partOrderLine.Work_Order__c==null && (partOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_TYPE_RETURN 
                    || partOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_STOCK_TRANSFER) 
                && (partOrderLine.SVMXC__Line_Status__c!=PartsOrderLines.STRING_PARTS_ORDER_LINE_STATUS_CANCELED 
                    || partOrderLine.SVMXC__Line_Status__c != PartsOrderLines.STRING_PART_ORDER_LINE_STATUS_SHIPPED)) {
            PartsOrderLines.setPartsOrderLinesRecords.add(partOrderLine);
            if(String.isNotBlank(partOrderLine.Batch_Number__c)){
                PartsOrderLines.setBatchNumber.add(partOrderLine.Batch_Number__c);
            }
            if(String.isNotBlank(partOrderLine.From_Location__c)){
                PartsOrderLines.setFromLocationId.add(partOrderLine.From_Location__c);
            }
            if(String.isNotBlank(partOrderLine.Stocked_Serial__c)){
                PartsOrderLines.setStockSerialId.add(partOrderLine.Stocked_Serial__c);
            }
            if(String.isNotBlank(partOrderLine.Product_Stock__c)){
                PartsOrderLines.setProductStockId.add(partOrderLine.Product_Stock__c);  
            }        
        } // DCP-42763
    }
    
    /*
    *  @AUTHOR:  Sravan
    *  @DESCRIPTION: 33467 - Validate the batched or serilized part while creating POL for Retun/Stock Transfer which are created from location
    *  @PARAM :  Parts order line Id set, BatchNumber set, Location Id set and StockSerial Id set
    *  @RETURN:  void
    */
    public static void validateBatchOrStockSerial(set<SVMXC__RMA_Shipment_Line__c> setPartsOrderLinesRecords, Set<String> setBatchNumber, 
                                                        Set<Id> setFromLocationId, Set<Id> setStockSerialId, Set<Id> setProductStockId) {
        Map<String,List<SVMXC__Allocated_Stock__c>> mapAllocaatedStockList = new Map<String,List<SVMXC__Allocated_Stock__c>>();        
        Set<SVMXC__RMA_Shipment_Line__c> setErrorPols = new Set<SVMXC__RMA_Shipment_Line__c>();
        Set<Id> setStockedSerialIds = new Set<Id>();
        Map<Id,String> mapStockSerialNumbers = new Map<Id,String>();
        Map<Id,SVMXC__Product_Serial__c> mapBatchSerialRecords = new Map<Id,SVMXC__Product_Serial__c>();


        // Prepare Srocked Serial id set
        setStockedSerialIds = prepareSetStockedSerialIds(setPartsOrderLinesRecords); 

        // Prepare a map with Stock Serial number by passing stock serial set
        if(setStockedSerialIds != NULL && !setStockedSerialIds.isEmpty()) {
            for(SVMXC__Product_Serial__c stockedSerial:new StockedSerialSelector().selectStockedSerialById(setStockedSerialIds)){
                if(stockedSerial.SVMX_PS_VS_Product_Tracking__c == PartsOrderLines.STRING_SERIALIZED) {
                    mapStockSerialNumbers.put(stockedSerial.id,stockedSerial.Name);
                } else if(stockedSerial.SVMX_PS_VS_Product_Tracking__c == PartsOrderLines.STRING_LOT_BATCH_TRACKED){
                    mapBatchSerialRecords.put(stockedSerial.id,stockedSerial);
                }
            }
        }
        
        // Prepare POL map and Allocated Stock Map to get the batch QTY(Available and Allocated) per batch
        mapAllocaatedStockList = prepareMapAllocaatedStockList(setBatchNumber, setFromLocationId);
    
        //Batched Parts
        if(!mapAllocaatedStockList.isEmpty()) {
            setErrorPols.addAll(verifyBatchedParts(setPartsOrderLinesRecords,mapStockSerialNumbers,mapBatchSerialRecords,mapAllocaatedStockList));
        }

        //Serialized Parts
        if(!setStockSerialId.isEmpty()) {
            setErrorPols.addAll(verifySerializedParts(setPartsOrderLinesRecords,setStockSerialId,mapStockSerialNumbers));
        }
    
        //Non Serialized Parts

        if(!setProductStockId.isEmpty()) {
            setErrorPols.addAll(verifyNonSerializedParts(setPartsOrderLinesRecords,mapStockSerialNumbers,setProductStockId));
        }    

        throwsetPOLErrors(setErrorPols);
             
    } 

    /*******************************************************************************************************
    * @description Throw POL Errors
    * @param setErrorPols Set<SVMXC__RMA_Shipment_Line__c>
    * @return void
    */
    private static void throwsetPOLErrors(Set<SVMXC__RMA_Shipment_Line__c> setErrorPols) {
        List<string> lstPolErrors = new list<string>();
        List<string> lstWoNumber = new list<string>();
        
        if(!PartsOrderLines.setPolErrors.isEmpty() && !PartsOrderLines.setWorkOrderNumber.isEmpty() && !setErrorPols.isEmpty()) {
            //add bypass validation using custom setting check.
            cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
            if(!setting.Bypass_All_Validations__c) {
                for(SVMXC__RMA_Shipment_Line__c pol:setErrorPols) {
                    lstWoNumber.addAll(PartsOrderLines.setWorkOrderNumber);
                    lstPolErrors.addAll(PartsOrderLines.setPolErrors);
                    pol.addError(Label.StockTransferOrReturnPartsReservationError+String.join(lstWoNumber, '#')+Label.StockTransferOrReturnPartsReservationErrorPart2+'\n'+'[*'+String.join(lstPolErrors, '*')+']',false);
                }
            }
        }   
    }
    
    /*******************************************************************************************************
    * @description prepare mapAllocaatedStockList
    * @param setBatchNumber Set<String>
    * @param setFromLocationId Set<Id>
    * @return Map<String,List<SVMXC__Allocated_Stock__c>>
    */
    private static Map<String,List<SVMXC__Allocated_Stock__c>> prepareMapAllocaatedStockList(Set<String> setBatchNumber, Set<Id> setFromLocationId) {
        Map<String,List<SVMXC__Allocated_Stock__c>> mapAllocaatedStockList = new Map<String,List<SVMXC__Allocated_Stock__c>>();        
        
        if(!setBatchNumber.isEmpty() && !setFromLocationId.isEmpty()) {        
            for(SVMXC__Allocated_Stock__c allocatedStock : new AllocatedStocksSelector().selectAllocatedStocksByBatchAndLocation(setFromLocationId, setBatchNumber)){          
                String batchUniqueKey = allocatedStock.Location__r.ERP_Customer_ID__c + allocatedStock.Product_Code__c + allocatedStock.Batch_Number__c;
                if(!mapAllocaatedStockList.containsKey(batchUniqueKey)) {
                    mapAllocaatedStockList.put(batchUniqueKey , new List<SVMXC__Allocated_Stock__c>());
                }
                mapAllocaatedStockList.get(batchUniqueKey).add(allocatedStock);
            }
        }
        return mapAllocaatedStockList;
    }

    /*******************************************************************************************************
    * @description prepare setStockedSerialIds
    * @param setPartsOrderLinesRecords Set<SVMXC__RMA_Shipment_Line__c>
    * @return Set<id>
    */
    private static Set<Id> prepareSetStockedSerialIds(Set<SVMXC__RMA_Shipment_Line__c> setPartsOrderLinesRecords) {
        Set<Id> setStockedSerialIds = new Set<Id>();

        if(!setPartsOrderLinesRecords.isEmpty()) {            
            for(SVMXC__RMA_Shipment_Line__c pol: setPartsOrderLinesRecords){
                if(pol.Stocked_Serial__c!=null){
                    setStockedSerialIds.add(pol.Stocked_Serial__c);
                }else if(pol.Batch_Lookup__c != null){
                    setStockedSerialIds.add(pol.Batch_Lookup__c);
                }
            }
        }
        return setStockedSerialIds;
    }

    /*
    *  @AUTHOR:  Sravan
    *  @DESCRIPTION: 33467 - Verify the batched parts whether it has error
    */
    public static set<SVMXC__RMA_Shipment_Line__c> verifyBatchedParts(set <SVMXC__RMA_Shipment_Line__c> setPartsOrderLinesRecords,Map<Id,String> mapStockSerialNumbers,Map<Id,SVMXC__Product_Serial__c> mapBatchSerialRecords,Map<String,List<SVMXC__Allocated_Stock__c>> mapAllocaatedStockList){
        Set<SVMXC__RMA_Shipment_Line__c> setPols = new Set<SVMXC__RMA_Shipment_Line__c>();
        Map<String,Integer> mapAllocatedStockQTY = new Map<String,Integer>();
        String batchNumberDisplay = '';
        String serialNumberDisplay = '';
        
        // Get allocated/Reserved Qty for each batch number and prepare the WOs list it was used
        If(!mapAllocaatedStockList.isEmpty()){      
            for(string alsKey : mapAllocaatedStockList.keySet()){
                Integer allocatedQty = 0;
                for(SVMXC__Allocated_Stock__c allocatedStock : mapAllocaatedStockList.get(alsKey)) {          
                    allocatedQty = allocatedQty + integer.valueOf(allocatedStock.SVMXC__Allocated_Qty__c);
                    PartsOrderLines.setWorkOrderNumber.add(allocatedStock.Work_Order__r.Name);
                }
                mapAllocatedStockQTY.put(alsKey,allocatedQty);
            }      
        } 
        
        // Compare the Available - Reserved/Allocated QTY for bacth and through error
        if(!setPartsOrderLinesRecords.isEmpty() && !mapBatchSerialRecords.isEmpty() && !mapAllocatedStockQTY.isEmpty()) {
            for(SVMXC__RMA_Shipment_Line__c pol : setPartsOrderLinesRecords){

                SVMXC__Product_Serial__c batchSerialRec = mapBatchSerialRecords.get(pol.Batch_Lookup__c);

                if(batchSerialRec != null && mapAllocatedStockQTY.containsKey(batchSerialRec.SVMX_PS_External_ID__c) && pol.SVMXC__Actual_Quantity2__c > (batchSerialRec.Quantity__c - mapAllocatedStockQTY.get(batchSerialRec.SVMX_PS_External_ID__c))){
                    setPols.add(Pol);
                    batchNumberDisplay = Pol.Batch_Number__c!=null ? Pol.Batch_Number__c :'';
                    serialNumberDisplay = mapStockSerialNumbers.get(Pol.Stocked_Serial__c)!=null ?mapStockSerialNumbers.get(Pol.Stocked_Serial__c) :'';
                    PartsOrderLines.setPolErrors.add(PartsOrderLines.PRODUCT_CODE+Pol.Product_Code__c+PartsOrderLines.SERIAL+serialNumberDisplay+PartsOrderLines.BATCH+batchNumberDisplay+'\n');

                }
            }
        }
        
        return setPols;
    } 

    /*
    *  @AUTHOR:  Sravan
    *  @DESCRIPTION: 33467 - Verify serialized parts whether it has error
    */
    public static set<SVMXC__RMA_Shipment_Line__c> verifySerializedParts(set <SVMXC__RMA_Shipment_Line__c> setPartsOrderLinesRecords,Set<Id> setStockSerialId,Map<Id,String> mapStockSerialNumbers){
        Set<SVMXC__RMA_Shipment_Line__c> setPols = new Set<SVMXC__RMA_Shipment_Line__c>();
        Map<Id,set<string>> mapAlsWorkOrderNumber = new Map<Id,set<string>>();
        String batchNumberDisplay = '';
        String serialNumberDisplay = '';

        // Prepare Allocated Stock Map for each Serial and get WOs list it was used
        if(setPartsOrderLinesRecords.size()>0 && setStockSerialId.size()>0){
            for(SVMXC__Allocated_Stock__c als : new AllocatedStocksSelector().selectAllocatedStocksByStockSerialIds(setStockSerialId)){
                if(mapAlsWorkOrderNumber.containsKey(als.SVMX_PS_VS_Stocked_Serial__c)){
                mapAlsWorkOrderNumber.get(als.SVMX_PS_VS_Stocked_Serial__c).add(als.Work_Order__r.Name);   
                }else{
                    mapAlsWorkOrderNumber.put(als.SVMX_PS_VS_Stocked_Serial__c,new set<string>{als.Work_Order__r.Name});  
                }                
            }
            // Find if the given serial was already used then through error
            if(!mapAlsWorkOrderNumber.isEmpty()){
                for(SVMXC__RMA_Shipment_Line__c pol : setPartsOrderLinesRecords){
                    if(mapAlsWorkOrderNumber.containsKey(pol.Stocked_Serial__c)){
                        PartsOrderLines.setWorkOrderNumber.addAll(MapAlsWorkOrderNumber.get(pol.Stocked_Serial__c));
                        setPols.add(pol);
                        batchNumberDisplay = pol.Batch_Number__c!=null ? pol.Batch_Number__c :'';
                        serialNumberDisplay = mapStockSerialNumbers.get(pol.Stocked_Serial__c)!=null ?mapStockSerialNumbers.get(pol.Stocked_Serial__c) :'';
                        PartsOrderLines.setPolErrors.add(PartsOrderLines.PRODUCT_CODE+pol.Product_Code__c+PartsOrderLines.SERIAL+serialNumberDisplay+PartsOrderLines.BATCH+batchNumberDisplay+'\n');
                    }
                }
            }       
        }
        
        return setPols;
    } //DCP-33467

    /*
    *  @AUTHOR:  Sravan
    *  @DESCRIPTION: 33467 - Verify non-serialized parts whether it has error
    */
    public static set<SVMXC__RMA_Shipment_Line__c> verifyNonSerializedParts(set <SVMXC__RMA_Shipment_Line__c> setPartsOrderLinesRecords,Map<Id,String> mapStockSerialNumbers, set<Id> setProductStockId){
        Set<SVMXC__RMA_Shipment_Line__c> setPols = new Set<SVMXC__RMA_Shipment_Line__c>();
        Map<Id,List<SVMXC__Allocated_Stock__c>> mapProductStockAllocatedList = new Map<Id,List<SVMXC__Allocated_Stock__c>>();
        Map<Id,Integer> mapProductStockAllocatedQTY = new Map<Id,Integer>();
        Map<Id,Integer> mapProductStockAvailableQTY = new Map<Id,Integer>();
        Integer allocatedQty;
        
        mapProductStockAllocatedList = generateMapProductStockAllocatedList(setProductStockId); // Non Tracked product stocks
        
        for(SVMXC__Product_Stock__c ps: new ProductStockSelector().selectProductStocksByIds(setProductStockId)) {
            mapProductStockAvailableQTY.put(ps.id,integer.valueOf(ps.SVMXC__Quantity2__c !=null ? ps.SVMXC__Quantity2__c : 0));
        }
        
        // Get allocated/Reserved Qty for each product stock and prepare the WO Number list
        If(!mapProductStockAllocatedList.isEmpty()){      
            for(Id alsKey : mapProductStockAllocatedList.keySet()){
                allocatedQty = 0;
                for(SVMXC__Allocated_Stock__c allocatedStock : mapProductStockAllocatedList.get(alsKey)){          
                    allocatedQty = allocatedQty + integer.valueOf(allocatedStock.SVMXC__Allocated_Qty__c);
                    PartsOrderLines.setWorkOrderNumber.add(allocatedStock.Work_Order__r.Name);
                }
                mapProductStockAllocatedQTY.put(alsKey, allocatedQty);
            }      
        }
        
        setPols = setPOLErrors(setPartsOrderLinesRecords, mapProductStockAllocatedQTY, mapProductStockAvailableQTY, mapStockSerialNumbers);
        return setPols;
    } 

    /*******************************************************************************************************
    * @description populate setPols
    * @param setPartsOrderLinesRecords Set<SVMXC__RMA_Shipment_Line__c>
    * @param mapProductStockAllocatedQTY Map<Id,Integer>
    * @param mapProductStockAvailableQTY Map<Id,Integer>
    * @param mapStockSerialNumbers Map<Id, String>
    * @return Set<SVMXC__RMA_Shipment_Line__c>
    */
    private static Set<SVMXC__RMA_Shipment_Line__c> setPOLErrors(Set<SVMXC__RMA_Shipment_Line__c> setPartsOrderLinesRecords,
                    Map<Id,Integer> mapProductStockAllocatedQTY, Map<Id,Integer> mapProductStockAvailableQTY, Map<Id, String> mapStockSerialNumbers) {
        Set<SVMXC__RMA_Shipment_Line__c> setPols = new Set<SVMXC__RMA_Shipment_Line__c>();
        String batchNumberDisplay = '';
        String serialNumberDisplay = '';

        for(SVMXC__RMA_Shipment_Line__c pol : setPartsOrderLinesRecords) {
            if(mapProductStockAllocatedQTY.containsKey(pol.Product_Stock__c) && mapProductStockAvailableQTY.containsKey(pol.Product_Stock__c) 
                    && pol.SVMXC__Actual_Quantity2__c > (mapProductStockAvailableQTY.get(pol.Product_Stock__c) - mapProductStockAllocatedQTY.get(pol.Product_Stock__c))){
                setPols.add(pol);
                batchNumberDisplay = pol.Batch_Number__c!=null ? pol.Batch_Number__c :'';
                serialNumberDisplay = mapStockSerialNumbers.get(pol.Stocked_Serial__c)!=null ?mapStockSerialNumbers.get(pol.Stocked_Serial__c) :'';
                PartsOrderLines.setPolErrors.add(PartsOrderLines.PRODUCT_CODE+pol.Product_Code__c+PartsOrderLines.SERIAL+serialNumberDisplay+PartsOrderLines.BATCH+batchNumberDisplay+'\n');
            }
        }
        return setPols;
    }

    /*******************************************************************************************************
    * @description populate mapProductStockAllocatedList
    * @param setProductStockId Set<Id>
    * @return Map<Id, List<SVMXC__Allocated_Stock__c>>
    */
    private static Map<Id, List<SVMXC__Allocated_Stock__c>> generateMapProductStockAllocatedList(Set<Id> setProductStockId) {
        Map<Id,List<SVMXC__Allocated_Stock__c>> mapProductStockAllocatedList = new Map<Id,List<SVMXC__Allocated_Stock__c>>();

        if(!setProductStockId.isEmpty()) {
            for(SVMXC__Allocated_Stock__c als : new AllocatedStocksSelector().selectAllocatedStocksByProductStockIds(setProductStockId)){                
                if(mapProductStockAllocatedList.containsKey(als.SVMXC__Product_Stock__c)){
                    mapProductStockAllocatedList.get(als.SVMXC__Product_Stock__c).add(als);
                }else{
                    mapProductStockAllocatedList.put(als.SVMXC__Product_Stock__c,new List<SVMXC__Allocated_Stock__c>{als}); 
                }
            }
        }
        return mapProductStockAllocatedList;
    }

    //CMCM-8243 start
    /*
    *  @AUTHOR:  Nitin
    *  @DESCRIPTION: CMCM-8243 - Validate if WO on POL has FAN attached 
    */
    public static void validateFANOnWorkOrder(Set<Id> setWoIdPOL, List<SVMXC__RMA_Shipment_Line__c> partOrderLine) {
        Set<Id> lstwoIdPO = new Set<Id>();
        if(setWoIdPOL != null && !setWoIdPOL.isEmpty()){
        	lstwoIdPO.addAll(setWoIdPOL);
        }
        
        List<Field_Action_Item__c> lstFans = new List<Field_Action_Item__c>();
        if (lstFans.isEmpty() && (lstwoIdPO != null && !lstwoIdPO.isEmpty())) { 
            lstFans = new FieldActionItemsSelector().selectFieldActionItemsByCaseORWOId(lstwoIdPO, new Set<Id>());
        }
        
        // Iterate through the fetched Field Action Items and remove the WOs from set that have FAN, remaining WOs in setWoIdPOL will throw error
        for(Field_Action_Item__c objFieldActItem : lstFans) {
            // Added the condition for CMCM-11603 to include the scenario if FAI.FAN lookup is null
            if(objFieldActItem.Field_Action_Notification__c != null) {
                setWoIdPOL.remove(objFieldActItem.Work_Order__c);
            }
        }
    
        for(SVMXC__RMA_Shipment_Line__c partOrderLineObj : partOrderLine) {
            if(setWoIdPOL.contains(partOrderLineObj.SVMXC__Service_Order__c)) {
                partOrderLineObj.addError(Label.Parts_Order_Return_Reason_CI);
            }
        }
    }
    //CMCM-8243 end
}
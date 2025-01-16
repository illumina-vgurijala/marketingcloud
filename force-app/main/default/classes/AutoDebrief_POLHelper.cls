/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Queueable Class for Parts Order Line Trigger to run logic 
*                        for creating Work Details
*Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Nitin                          7 june 2022         CMSI-36 try catch in execute method 
*    ------------------------------------------------------------------------------------ 
*                     
*/
public class AutoDebrief_POLHelper implements Queueable {

    Set<Id> nonReturnPartsOrderLineIds = new Set<Id>();
    public static final Integer SIZE_255 = 255;
    public static final String STRING_COMPANY_OWNED = 'Company Owned';
    public static Boolean catchException = false;

    /*******************************************************************************************************
    * @description Constructor
    * @param nonReturnPartsOrderLineIds Set of Part Order Line Ids
    */
    public AutoDebrief_POLHelper(Set<Id> nonReturnPartsOrderLineIds) {
        this.nonReturnPartsOrderLineIds = nonReturnPartsOrderLineIds;
    }

    /*******************************************************************************************************
    * @description execute Method
    * @param qc QueueableContext
    * @return void
    */
    public void execute(QueueableContext qc) {
        try{
        PartsOrderLines.stopPartOrderLineInsertion = true;
        Set<Id> setFromLocations = new Set<Id> ();
        Set<Id> setProducts = new Set<Id> ();
      
        List<SVMXC__Product_Stock__c> lstProductStock = new List<SVMXC__Product_Stock__c> ();
        String  strPOLId='';

        Map<Id, SVMXC__RMA_Shipment_Line__c> polMap = new Map<Id, SVMXC__RMA_Shipment_Line__c>(new PartsOrderLineSelector().selectPartsOrderLineRecords(nonReturnPartsOrderLineIds));
    
        for (SVMXC__RMA_Shipment_Line__c objPartsOrderLine: polMap.values()) {
            if (objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c != null 
                    && objPartsOrderLine.SVMXC__Product__c != null) {
                setFromLocations.add(objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c);
                setProducts.add(objPartsOrderLine.SVMXC__Product__c);
            }
            strPOLId = strPOLId +','+ objPartsOrderLine.Id;
        }
        strPOLId = strPOLId.trim(); // removes extra space from left and right //
        strPOLId = strPOLId.substring(1, strPOLId.length());  //removes First ','//
        
        if(strPOLId.length() > SIZE_255){
            strPOLId = strPOLId.substring(0, SIZE_255);
        }

        if (!setFromLocations.isEmpty() && !setProducts.isEmpty()) {
            lstProductStock = new ProductStockSelector().selectProductStockByLocationAndProduct(setFromLocations, setProducts);
        }
        processPOLrecords(strPOLId, polMap, lstProductStock);
        
        PartsOrderLines.stopPartOrderLineInsertion = false;
        
        if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }
    }
    catch(exception e){
        ApexExceptions.emit('AutoDebrief_POLHelper',e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
    }
    }

    /*******************************************************************************************************
    * @description process Parts Order Line records
    * @param strPOLId String
    * @param polMap Map<id, SVMXC__RMA_Shipment_Line__c>
    * @param lstProductStock List<SVMXC__Product_Stock__c>
    * @return void
    */
    private void processPOLrecords(String strPOLId, Map<Id, SVMXC__RMA_Shipment_Line__c> polMap, List<SVMXC__Product_Stock__c> lstProductStock) {
        Set<Id> setConsumedProduct = new Set<Id>();
        Map<Id,String> mapProductsToTracking = new Map<Id, String>();
        List<SVMXC__Service_Order_Line__c> lstWorkDetailsToInsert = new List<SVMXC__Service_Order_Line__c>();
        List<SVMXC__Service_Order_Line__c> lstWorkDetailsToCheck = new List<SVMXC__Service_Order_Line__c > ();
        List <SVMXC__Product_Serial__c> lstStockedSerial = new List<SVMXC__Product_Serial__c> ();
        
        for (SVMXC__RMA_Shipment_Line__c objPartsOrderLine: polMap.values()) {
            if(!PartsOrderLines.CLOSED_WO_STATUS_LIST.contains(objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__r.SVMXC__Order_Status__c)) {
                if (objPartsOrderLine.SVMXC__Product__r.Service_Product_Type__c == 'Spare' 
                        && objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c != null) {
                    for (SVMXC__Product_Stock__c objProductStock: lstProductStock) {
                        if (objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c == objProductStock.SVMXC__Location__c 
                                && objPartsOrderLine.SVMXC__Product__c == objProductStock.SVMXC__Product__c) {
                            setConsumedProduct.add(objProductStock.Id);
                            mapProductsToTracking.put(objPartsOrderLine.SVMXC__Product__c, objPartsOrderLine.SVMXC__Product__r.SVMXC__Tracking__c);
                            SVMXC__Service_Order_Line__c objWorkDetail = genWorkDetailFromProductStock(objPartsOrderLine, objProductStock);
                            lstWorkDetailsToCheck.add(objWorkDetail);
                        }
                    }
                } else if (objPartsOrderLine.SVMXC__Product__r.Service_Product_Type__c ==  'Consumable'
                            ||objPartsOrderLine.SVMXC__Product__r.Service_Product_Type__c == PartsOrderLines.STRING_PARTS_ORDER_LINE_NONFRU) {
                    SVMXC__Service_Order_Line__c objWorkDetail = genWorkDetailConsumableNonFRUProduct(objPartsOrderLine);
                    lstWorkDetailsToInsert.add(objWorkDetail);
                }
            }
        }
        
        insertIlluminaLogRec(lstWorkDetailsToCheck, strPOLId, 'objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c===>');

        if (!setConsumedProduct.isEmpty() && mapProductsToTracking != null && !mapProductsToTracking.isEmpty()) {
            lstStockedSerial = new StockedSerialSelector().selectStockedSerialByConProductAndProduct(setConsumedProduct, mapProductsToTracking.keyset());
        }

        lstWorkDetailsToInsert = createListWorkDetails(lstWorkDetailsToCheck, mapProductsToTracking, lstWorkDetailsToInsert, lstStockedSerial);

        insertIlluminaLogRec(lstWorkDetailsToInsert, strPOLId, 'objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c===>');

        if (!lstWorkDetailsToInsert.isEmpty()) {
            WorkDetails.boolRunBillableFlagCheck = false;
            insert lstWorkDetailsToInsert;
        }
    }
    
    /*******************************************************************************************************
    * @description create Work Details Records List
    * @param lstWorkDetailsToCheck List<SVMXC__Service_Order_Line__c>
    * @param mapProductsToTracking Map<Id, String>
    * @param lstWorkDetailsToInsert List<SVMXC__Service_Order_Line__c>
    * @param lstStockedSerial List<SVMXC__Product_Serial__c>
    * @return List<SVMXC__Service_Order_Line__c>
    */
    private static List<SVMXC__Service_Order_Line__c> createListWorkDetails(List<SVMXC__Service_Order_Line__c> lstWorkDetailsToCheck, Map<Id,String> mapProductsToTracking,
                            List<SVMXC__Service_Order_Line__c> lstWorkDetailsToInsert, List<SVMXC__Product_Serial__c> lstStockedSerial) {
        for (SVMXC__Service_Order_Line__c objWorkDetail: lstWorkDetailsToCheck) {
            if(mapProductsToTracking.containsKey(objWorkDetail.SVMXC__Product__c) && mapProductsToTracking.get(objWorkDetail.SVMXC__Product__c) == 'Non-Tracked') {
                lstWorkDetailsToInsert.add(objWorkDetail);
            }
            else if (objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c != null && !lstStockedSerial.isEmpty()
                    && mapProductsToTracking.containsKey(objWorkDetail.SVMXC__Product__c)) {
                for (SVMXC__Product_Serial__c objStockSerial: lstStockedSerial) {
                    SVMXC__Service_Order_Line__c objWorkDetailTemp = objWorkDetail.clone();
                    objWorkDetailTemp = defaultValuesFromStockedSerial(mapProductsToTracking, objWorkDetail, objStockSerial);
                    if(objWorkDetailTemp != NULL) {
                        lstWorkDetailsToInsert.add(objWorkDetailTemp);
                    }
                }
            } 
        }
        return lstWorkDetailsToInsert;
    }

    /*******************************************************************************************************
    * @description Insert Illumina Log Record
    * @param lstWorkDetails QueueableContext
    * @param strPOLId QueueableContext
    * @param message QueueableContext
    * @return void
    */
    public void insertIlluminaLogRec(List<SVMXC__Service_Order_Line__c> lstWorkDetails, String strPOLId, String message) {
        ILMN_Debug_Log__c al = new ILMN_Debug_Log__c();
        al.Data__c = message + lstWorkDetails ;
        al.Title__c = strPOLId ;
        insert(al);
    }

    /*******************************************************************************************************
    * @description Generate Work Detail from Product Serial
    * @param mapProductsToTracking Map<Id,String>
    * @param objWorkDetail SVMXC__Service_Order_Line__c
    * @param objStockSerial SVMXC__Product_Serial__c
    * @return SVMXC__Service_Order_Line__c
    */
    public static SVMXC__Service_Order_Line__c defaultValuesFromStockedSerial(Map<Id,String> mapProductsToTracking, SVMXC__Service_Order_Line__c objWorkDetail,
                                                                            SVMXC__Product_Serial__c objStockSerial) {
        if (mapProductsToTracking != NULL && mapProductsToTracking.get(objWorkDetail.SVMXC__Product__c) == PartsOrderLines.STRING_SERIALIZED 
                && objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c == objStockSerial.SVMXC__Product_Stock__c 
                && objWorkDetail.SVMXC__Product__c == objStockSerial.SVMXC__Product__c 
                && objWorkDetail.SVMXC__Serial_Number__c == objStockSerial.SVMX_PS_VS_Linked_Installed_Product__c) {
            objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c = objStockSerial.Id;
            objWorkDetail.SVMXC__Serial_Number__c = null;
            return objWorkDetail;
        } else if (mapProductsToTracking.get(objWorkDetail.SVMXC__Product__c) == PartsOrderLines.STRING_LOT_BATCH_TRACKED 
                && objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c == objStockSerial.SVMXC__Product_Stock__c 
                && objWorkDetail.SVMXC__Product__c == objStockSerial.SVMXC__Product__c && objWorkDetail.Batch_Number__c == objStockSerial.Batch_Number__c) {
            objWorkDetail.Batch_Lookup__c = objStockSerial.Id;
            return objWorkDetail;
        }
        return null;
    }

    /*******************************************************************************************************
    * @description  Generate Work Detail from Product Stock
    * @param objProductStock SVMXC__Product_Stock__c
    * @param objPartsOrderLine SVMXC__RMA_Shipment_Line__c
    * @return SVMXC__Service_Order_Line__c
    */
    public SVMXC__Service_Order_Line__c genWorkDetailFromProductStock(SVMXC__RMA_Shipment_Line__c objPartsOrderLine, SVMXC__Product_Stock__c objProductStock) {
        SVMXC__Service_Order_Line__c objWorkDetail = new SVMXC__Service_Order_Line__c();
        objWorkDetail.SVMXC__Service_Order__c = objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c;
        objWorkDetail.SVMXC__Line_Type__c = 'Parts';
        objWorkDetail.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        objWorkDetail.SVMXC__Consumed_From_Location__c = objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Destination_Location__c;
        //DCP-47694- replacing actual qty with shipped qty
        if(Feature.isOn(PartsOrderLines.PARTIAL_SHIPMENT)) {
            objWorkDetail.SVMXC__Actual_Quantity2__c = objPartsOrderLine.Shipped_Qty__c;
        } else {
            objWorkDetail.SVMXC__Actual_Quantity2__c = objPartsOrderLine.SVMXC__Actual_Quantity2__c;
        }
        objWorkDetail.Include_in_Service_Report__c = true;
        objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c = objProductStock.Id;
        objWorkDetail.SVMXC__Product__c = objPartsOrderLine.SVMXC__Product__c;
        objWorkDetail.Product_Code1__c = objPartsOrderLine.Product_Code__c;
        objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c = NULL;
        objWorkDetail.SVMXC__Is_Billable__c = objPartsOrderLine.Is_Billable__c;
        if (objPartsOrderLine.Reason__c != STRING_COMPANY_OWNED) {
            objWorkDetail.Non_Billable_Reason__c = objPartsOrderLine.Reason__c;
            if(objPartsOrderLine.Reason__c == PartsOrderLines.STRING_PARTSORDERLINE_NON_BILLABLE_REASON_GOODWILL)  {//DCP-43634
                objWorkDetail.Approval_Status__c = WorkDetails.WD_APPROVALSTATUS_APPROVED;
            }
        }
        objWorkDetail.SVMXC__Serial_Number__c = objPartsOrderLine.SVMXC__Serial_Number__c;
        objWorkDetail.SVMX_PS_VS_Is_Create_Install_Product__c = true;
        objWorkDetail.SVMX_PS_VS_Is_Part_Out__c = true;
        if(objPartsOrderLine.Batch_Number__c!=null){                            
            objWorkDetail.Batch_Number__c = objPartsOrderLine.Batch_Number__c;
        }
        objWorkDetail.ERP_Header_Contract_Number__c = objPartsOrderLine.ERP_Contract_Number__c;
        objWorkDetail.ERP_Contract_Line_Number__c = objPartsOrderLine.ERP_Contract_Line_Number__c;
        objWorkDetail.Is_Auto_Created__c = true;//DCP-43634
        return objWorkDetail;
    }

    /*******************************************************************************************************
    * @description  Generate Work Detail for Consumable or Non FRU Product
    * @param objPartsOrderLine SVMXC__RMA_Shipment_Line__c
    * @return SVMXC__Service_Order_Line__c
    */
    public SVMXC__Service_Order_Line__c genWorkDetailConsumableNonFRUProduct(SVMXC__RMA_Shipment_Line__c objPartsOrderLine) {
        SVMXC__Service_Order_Line__c objWorkDetail = new SVMXC__Service_Order_Line__c();
        objWorkDetail.SVMXC__Service_Order__c = objPartsOrderLine.SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c;
        objWorkDetail.SVMXC__Line_Type__c = 'Material Consumed';
        objWorkDetail.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        objWorkDetail.SVMXC__Product__c = objPartsOrderLine.SVMXC__Product__c;
        objWorkDetail.Product_Code1__c = objPartsOrderLine.Product_Code__c;
        //DCP-47694- replacing actual qty with shipped qty
        if(Feature.isOn(PartsOrderLines.PARTIAL_SHIPMENT)){
            objWorkDetail.SVMXC__Actual_Quantity2__c = objPartsOrderLine.Shipped_Qty__c;
        }else{
            objWorkDetail.SVMXC__Actual_Quantity2__c = objPartsOrderLine.SVMXC__Actual_Quantity2__c;
        }
        objWorkDetail.Include_in_Service_Report__c = true;
        objWorkDetail.SVMXC__Is_Billable__c = objPartsOrderLine.Is_Billable__c;
        objWorkDetail.Batch_Number__c = objPartsOrderLine.Batch_Number__c;
        objWorkDetail.ERP_Header_Contract_Number__c = objPartsOrderLine.ERP_Contract_Number__c;
        objWorkDetail.ERP_Contract_Line_Number__c = objPartsOrderLine.ERP_Contract_Line_Number__c;
        if (objPartsOrderLine.Reason__c != STRING_COMPANY_OWNED) {
            objWorkDetail.Non_Billable_Reason__c = objPartsOrderLine.Reason__c;
            if(objPartsOrderLine.Reason__c == PartsOrderLines.STRING_PARTSORDERLINE_NON_BILLABLE_REASON_GOODWILL) { //DCP-43634
                objWorkDetail.Approval_Status__c = WorkDetails.WD_APPROVALSTATUS_APPROVED;
            }
        }
        if(objPartsOrderLine.SVMXC__Serial_Number__c != Null){
            objWorkDetail.SVMXC__Serial_Number__c = objPartsOrderLine.SVMXC__Serial_Number__c;
            objWorkDetail.SVMXC__Serial_Number_List__c = objPartsOrderLine.SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c;
        }
        objWorkDetail.Is_Auto_Created__c = true;//DCP-43634
        return objWorkDetail;
    }
    
}

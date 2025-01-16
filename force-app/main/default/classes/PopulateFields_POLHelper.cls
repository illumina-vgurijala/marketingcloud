/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to populate 
*                default values on record creation/updation
 ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*      Pooja                    30/3/2022               DCP-51210: Modified updateServiceProductTypeInstrument
*/ 
public class PopulateFields_POLHelper {

    /*******************************************************************************************************
    * @description populateReturnProdAndIPMap
    * @return void
    */
    public static void populateReturnProdAndIPMap() {
        if(!PartsOrderLines.setReturnPOLProducts.isEmpty()){
            PartsOrderLines.mapidtoReturnProduct.putall(new ProductsSelector().selectProducts(PartsOrderLines.setReturnPOLProducts));  
        }
        if(!PartsOrderLines.setReturnPOLIP.isEmpty()) {
            PartsOrderLines.mapidtoReturnIP.putall(new InstalledProductsSelector().selectRelatedInstalledProducts(PartsOrderLines.setReturnPOLIP));  
       }
    }

    /*******************************************************************************************************
    * @description populate Sets Before Update
    * @param partOrderLine new record
    * @param objOldPartOrderLine old record
    * @return void
    */
    public static void populateSetsBeforeUpdate(SVMXC__RMA_Shipment_Line__c partOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
        //Added by Shruti Karn for INC0227445
        if(objOldPartOrderLine.SVMXC__Product__c != partOrderLine.SVMXC__Product__c && partOrderLine.SVMXC__Product__c != null){
            PartsOrderLines.lstPOLContracttoupdate.add(partOrderLine);
            PartsOrderLines.setReturnPOLProducts.add(partOrderLine.SVMXC__Product__c);
        }
        
        if (objOldPartOrderLine.SVMXC__Serial_Number__c != partOrderLine.SVMXC__Serial_Number__c) {
            PartsOrderLines.setReturnPOLIP.add(partOrderLine.SVMXC__Serial_Number__c);
        }
    }

    /*******************************************************************************************************
    * @description populate Sets
    * @param partOrderLine new record
    * @return void
    */
    public static void populateSets(SVMXC__RMA_Shipment_Line__c partOrderLine) {
        if(partOrderLine.SVMXC__Product__c != null && partOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_TYPE_RETURN){
            PartsOrderLines.setReturnPOLProducts.add(partOrderLine.SVMXC__Product__c);
        }
        if(partOrderLine.SVMXC__Serial_Number__c != null && partOrderLine.Parts_Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_TYPE_RETURN){
            PartsOrderLines.setReturnPOLIP.add(partOrderLine.SVMXC__Serial_Number__c);
        }
        if (partOrderLine.SVMXC__RMA_Shipment_Order__c != null && PartsOrderLines.strLoggedInProfile != PartsOrderLines.STRING_INTEGRATION_SAP_SERVICE_PROFILE_NAME){
            PartsOrderLines.setPartOrderIdForLocation.add(partOrderLine.SVMXC__RMA_Shipment_Order__c);
        }
    }

    /*******************************************************************************************************
    * @description populate Serial Number
    * @param partOrderLine new record
    * @return void
    */
    public static void populateSerialNumber(SVMXC__RMA_Shipment_Line__c partOrderLine) {
        if(partOrderLine.Stocked_Serial__c != NULL && PartsOrderLines.stockSerialRecordsMap.containsKey(partOrderLine.Stocked_Serial__c)
                && PartsOrderLines.partsOrderIdToPartsOrder.containsKey(partOrderLine.SVMXC__RMA_Shipment_Order__c)
                && PartsOrderLines.partsOrderIdToPartsOrder.get(partOrderLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_STOCK_TRANSFER) {
            partOrderLine.SVMXC__Serial_Number__c = PartsOrderLines.stockSerialRecordsMap.get(partOrderLine.Stocked_Serial__c).SVMX_PS_VS_Linked_Installed_Product__c;
        }
    }

    /*******************************************************************************************************
    * @description populate field values
    * @param partOrderLine new record
    * @param objOldPartOrderLine old record
    * @return void
    */
    public static void populateValues(SVMXC__RMA_Shipment_Line__c objPartOrderLine, Set<Id> setPartOrderIdForLocation) {
        if (PartsOrderLines.partsOrderIdToPartsOrder != null && objPartOrderLine.SVMXC__RMA_Shipment_Order__c != null && PartsOrderLines.partsOrderIdToPartsOrder.containsKey(objPartOrderLine.SVMXC__RMA_Shipment_Order__c)) {
            if (PartsOrderLines.partsOrderIdToPartsOrder.get(objPartOrderLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Service_Order__c != null 
                    && PartsOrderLines.partsOrderIdToPartsOrder.get(objPartOrderLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Service_Order__r.SVMXC__Contact__c != null) {
                objPartOrderLine.WO_Contact__c = PartsOrderLines.partsOrderIdToPartsOrder.get(objPartOrderLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Service_Order__r.SVMXC__Contact__c;
            }
        }
        if(objPartOrderLine.SVMXC__RMA_Shipment_Order__c != null && setPartOrderIdForLocation.contains(objPartOrderLine.SVMXC__RMA_Shipment_Order__c)) {
            if(PartsOrderLines.partsOrderIdToPartsOrder.get(objPartOrderLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Destination_Location__c != null) {
                objPartOrderLine.To_Location__c = PartsOrderLines.partsOrderIdToPartsOrder.get(objPartOrderLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Destination_Location__c;
            }
            if(PartsOrderLines.partsOrderIdToPartsOrder.get(objPartOrderLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Source_Location__c != null) {
                objPartOrderLine.From_Location__c = PartsOrderLines.partsOrderIdToPartsOrder.get(objPartOrderLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Source_Location__c;
            }
        }
    }

    /*******************************************************************************************************
    * @description for CP users, populate WO from PartOrder, if POL value is blank
    * @param partOrderLine new record
    * @return void
    */
    public static void populateWOForCP(SVMXC__RMA_Shipment_Line__c partOrderLine) {
        if (PartsOrderLines.isLoggedInUserChannelPartner() && partOrderLine.SVMXC__Service_Order__c == null && PartsOrderLines.partsOrderIdToPartsOrder != null
                && partOrderLine.SVMXC__RMA_Shipment_Order__c != null && PartsOrderLines.partsOrderIdToPartsOrder.containsKey(partOrderLine.SVMXC__RMA_Shipment_Order__c)) {
            partOrderLine.SVMXC__Service_Order__c = PartsOrderLines.partsOrderIdToPartsOrder.get(partOrderLine.SVMXC__RMA_Shipment_Order__c)?.SVMXC__Service_Order__c;
        }
    }

    /*******************************************************************************************************
    * @description populate Service_Product_Type_Instrument__c
    * @param partOrderLine new record
    * @param objOldPartOrderLine old record
    * @return void
    */
    public static void updatePOLFieldsForInstrumentType(SVMXC__RMA_Shipment_Line__c objPartOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
        if(objOldPartOrderLine == NULL || objPartOrderLine.SVMXC__Product__c != objOldPartOrderLine.SVMXC__Product__c) {
            objPartOrderLine.Is_Loaner_Instrument__c = false;//DCP-51210
            if(objPartOrderLine.SVMXC__Product__c != null && objPartOrderLine.Service_Product_Type__c == PartsOrderLines.STRING_PRODUCT_TYPE_INSTRUMENT) 
            {
                objPartOrderLine.Service_Product_Type_Instrument__c = true;
                 //DCP-51210 : Start
                 if(PartsOrderLines.mapProduct.get(objPartOrderLine.SVMXC__Product__c).Serial_Number_Profile__c == PartsOrderLines.STRING_SERIAL_NUMBER_PROFILE_IL02
                 && PartsOrderLines.mapProduct.get(objPartOrderLine.SVMXC__Product__c).Condition_Type__c ==PartsOrderLines.STRING_CONDITION_TYPE_LOANER)
                 {
                     objPartOrderLine.Is_Loaner_Instrument__c = true;
                 }
                 //DCP-51210 END
            } else {
                objPartOrderLine.Service_Product_Type_Instrument__c = false;
            }  
        }
    }

    /*******************************************************************************************************
    * @description populate Instrument_or_Component_Serial_Number__c
    * @param partOrderLine new record
    * @param objOldPartOrderLine old record
    * @return void
    */
    public static void updateInstrumentComponentSNumber(SVMXC__RMA_Shipment_Line__c objPartOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
        if (PartsOrderLines.mapidtoReturnIP.containsKey(objPartOrderLine.SVMXC__Serial_Number__c)) {
            objPartOrderLine.Instrument_or_Component_Serial_Number__c = PartsOrderLines.mapidtoReturnIP.get(objPartOrderLine.SVMXC__Serial_Number__c).Name;
        } else if(objOldPartOrderLine == NULL || (objPartOrderLine.SVMXC__Serial_Number__c!=objOldPartOrderLine.SVMXC__Serial_Number__c)) {
            objPartOrderLine.Instrument_or_Component_Serial_Number__c= 'N/A';
        }
    }

    /*******************************************************************************************************
    * @description populate Instrument_or_Component_Model_Type__c
    * @param partOrderLine new record
    * @return void
    */
    public static void updateInstrumentComponentModelType(SVMXC__RMA_Shipment_Line__c objPartOrderLine) {
        if(PartsOrderLines.mapidtoReturnProduct.containsKey(objPartOrderLine.SVMXC__Product__c)) {
            objPartOrderLine.Instrument_or_Component_Model_Type__c = PartsOrderLines.mapidtoReturnProduct.get(objPartOrderLine.SVMXC__Product__c).Name;
        }
    }
}

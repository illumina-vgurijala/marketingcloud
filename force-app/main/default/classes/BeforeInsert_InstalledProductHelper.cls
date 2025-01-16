/*****************************************************************************************************************
* Class Name: BeforeInsert_InstalledProductHelper
* 
* Description: Helper class for Stamping the fields on before insert.
* 
* Author: Raviteja
* 
* Date: 27-03-2022
* 
* Notification Log:
* -------------------------------------------------------------------------------------------------------------
* Developer                  Date                              Description
* -------------------------------------------------------------------------------------------------------------
* Raviteja Vakkalagadda      27-03-2022                       Helper class for stamping the fields on before insert.
* Shivani Jain               17-08-2022                       DCP-50068 Remove setProducts from InstalledProducts class
* 
******************************************************************************************************************/
public with sharing class BeforeInsert_InstalledProductHelper {
    
    public static final String INSTRUMENT_OPERATION_STATUS_OFF = 'Off';
    public static final String SERVICE_PRODUCT_TYPE_INSTRUMENT = System.Label.IPServiceProductTypeInstrument;
    
/*
* @description: Method to form a map of sales order number to partsorder
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: void
*/
    public static void fetchOrderNumbersProductIds(List<SVMXC__Installed_Product__c> lstInstalledProducts) {
        for (SVMXC__Installed_Product__c obj : lstInstalledProducts) {
            
            if (obj.SVMXC__Sales_Order_Number__c != null && !String.isEmpty(obj.SVMXC__Sales_Order_Number__c)) {
                InstalledProducts.setSalesOrderId.add(obj.SVMXC__Sales_Order_Number__c);
            }
            
        }
        
    }

/*
* @description: Method to set the operation status of an Instrument as OFF (Down)
* @author: Sarath Pullanikkatt
* @date: 10/24/2019
* @returns: void
*/
    public static void setDefaultOperationStatusForInstruments(List<SVMXC__Installed_Product__c> lstInstalledProducts) {
        Set<Id> setProductIds = new Set<Id>();
        List<SVMXC__Installed_Product__c> lstInstruments = new List<SVMXC__Installed_Product__c>();
        
        for(SVMXC__Installed_Product__c ip : lstInstalledProducts) {
            if(ip.SVMXC__Product__c != null) {
                setProductIds.add(ip.SVMXC__Product__c);
                lstInstruments.add(ip);
            }
        }
        
        if(!setProductIds.isEmpty() && !lstInstruments.isEmpty()) {
            Map<Id, Product2> mapInstrumentProducts = new Map<Id, Product2>(new ProductsSelector().selectProductsWithServiceProductType(setProductIds, SERVICE_PRODUCT_TYPE_INSTRUMENT));
            system.debug('mapInstrumentProducts'+mapInstrumentProducts);
            for(SVMXC__Installed_Product__c ip : lstInstruments) {
                if(mapInstrumentProducts.containsKey(ip.SVMXC__Product__c)) {
                    system.debug('inside if');
                    ip.Operation_Status__c = INSTRUMENT_OPERATION_STATUS_OFF;
                }
            }
        }
    }
    
/*
* @description: Method to Stamp values on the New Installed Product
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: void
*/
    public static void stampValuesOnNewIPs(List<SVMXC__Installed_Product__c> lstInstalledProducts,Map<Id, Product2> mapProducts,Map<String, SVMXC__RMA_Shipment_Order__c> orderNumberToPartOrder) {
        for (SVMXC__Installed_Product__c obj : lstInstalledProducts) {
            if (orderNumberToPartOrder.Containskey(obj.SVMXC__Sales_Order_Number__c)) {
                obj.SVMXC__Company__c = orderNumberToPartOrder.get(obj.SVMXC__Sales_Order_Number__c).SVMXC__Company__c;
            }
            //DCP-45663
            if(obj.SVMXC__Product__c != null && mapProducts.containsKey(obj.SVMXC__Product__c) && mapProducts.get(obj.SVMXC__Product__c) != null && mapProducts.get(obj.SVMXC__Product__c).Service_Product_Type__c == SERVICE_PRODUCT_TYPE_INSTRUMENT) {
                obj.Is_Instrument__c = true;
            }
            
            if( obj.SVMXC__Serial_Lot_Number__c != Null) {
                obj.External_Id__c = obj.SVMXC__Serial_Lot_Number__c; 
            }
            
        }
    }
    
/*
* @description: Method to form a map of sales order number to partsorder
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: Map<String, SVMXC__RMA_Shipment_Order__c>
*/
    public static Map<String, SVMXC__RMA_Shipment_Order__c> buildMapOfOrderNumberToPartsOrder(Set<String> setSalesOrderId,Map<String, SVMXC__RMA_Shipment_Order__c> orderNumberToPartOrder) {
        PartsOrdersSelector pobj = new PartsOrdersSelector();
        
        for (SVMXC__RMA_Shipment_Order__c objpr : pobj.selectPartsOrdersWithName(setSalesOrderId)) {
            if (String.isNotBlank(objpr.SVMXC__Destination_Location__r.ERP_Customer_ID__c) && 
                objpr.SVMXC__Destination_Location__r.ERP_Customer_ID__c.startswith('TS3')) {
                    orderNumberToPartOrder.put(objpr.ERP_Sales_Order_Number__c,objpr);
                }
        }
        return orderNumberToPartOrder;
    }
}

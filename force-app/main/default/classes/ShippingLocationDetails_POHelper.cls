/**
*    @author Romi Taskar
*    @date 30 August 2022
*
*    @description DCP-52923 Helper Class for Parts Order Handler for populating Shipping Location Details
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Romi Taskar                1-Sep-2022              DCP-52923: Helper Class for Parts Order Handler for populating Shipping Location Details
*    ------------------------------------------------------------------------------------------------------
*/ 
public with sharing class ShippingLocationDetails_POHelper {

    private static final String LOG_TITLE = 'ShippingLocationDetails_POHelper';
    
   /*******************************************************************************************************
    * @description : DCP - 52923 -Parts Order Management: Display Shipping Location Address
    * @param newRecord : new Parts Order
    * @param oldRecord : old Parts Order
    * @return : void
    */

    public static void populateShippingLocDetails(SVMXC__RMA_Shipment_Order__c newRecord, SVMXC__RMA_Shipment_Order__c oldRecord) {

        ilib_LogEvent.push(LOG_TITLE + '.populateShippingLocDetails()');
        ilib_LogEvent.info('New Record-->: '+newRecord.id);
        if(oldRecord == NULL || (oldRecord != NULL && oldRecord.Shipping_Location__c != newRecord.Shipping_Location__c)) {

            if(newRecord.Shipping_Location__c != NULL && PartsOrders.mapSites.containsKey(newRecord.Shipping_Location__c)) {
                newRecord.Shipping_Location_Details__c = PartsOrders.mapSites.get(newRecord.Shipping_Location__c).Shipping_Location_Address__c;

            } else {
                newRecord.Shipping_Location_Details__c = '';
            }
        }

        ilib_LogEvent.pop();
    }
}

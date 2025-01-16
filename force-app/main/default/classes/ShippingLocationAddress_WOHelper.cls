/**
* @author Romi Taskar
* @date 30 August 2022
*
* @description DCP-52923 Helper Class for Work Order Handler for populating Shipping Location Address while creating Parts Order
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Developer                      Date                Description
* Romi Taskar                1-Sep-2022              DCP-52923: Helper Class for Work Order Handler for populating Shipping Location Address while creating Parts Order
* --------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/ 
public with sharing class ShippingLocationAddress_WOHelper {

    private static final String LOG_TITLE = 'ShippingLocationAddress_WOHelper';

    /*******************************************************************************************************
    * @description : DCP - 52923 -Parts Order Management: Display Shipping Location Address
    * @param newRecord : new Parts Order
    * @param oldRecord : old Parts Order
    * @return : void
    */

    public static void populatingLocationAddress(SVMXC__Service_Order__c newRecord, SVMXC__Service_Order__c oldRecord) {

        ilib_LogEvent.push(LOG_TITLE + '.populatingLocationAddress()');
        ilib_LogEvent.info('New Record-->: '+newRecord.id);
        
        if(oldRecord == NULL || (oldRecord != NULL && oldRecord.SVMXC__Site__c != newRecord.SVMXC__Site__c)) {

            if (newRecord.SVMXC__Site__c != NULL && WorkOrders.mapLocationrecords.containsKey(newRecord.SVMXC__Site__c)) {
                newRecord.Shipping_Location_Address__c = WorkOrders.mapLocationrecords.get(newRecord.SVMXC__Site__c).Shipping_Location_Address__c;   

            } else {
                newRecord.Shipping_Location_Address__c = '';
                
            }
        }
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description : DCP - 52923 -Parts Order Management: Display Shipping Location Address
    * @param newRecord : new Parts Order
    * @param oldRecord : old Parts Order
    * @return : void
    */
    public static void queryLocationRecords(List<sObject> records) {
        Set<Id> setSiteIds = new Set<Id>();
        Boolean runLocationQuery = false; //INC0438621

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) { 
            if (objWorkOrder.SVMXC__Site__c != NULL) {
                setSiteIds.add(objWorkOrder.SVMXC__Site__c);
                //INC0438621
                if(!WorkOrders.mapLocationrecords.containsKey(objWorkOrder.SVMXC__Site__c )) {
                    runLocationQuery = true;
                }
            }
        }
        
        if(runLocationQuery && !setSiteIds.isEmpty()) {
            WorkOrders.mapLocationrecords = new Map<Id,SVMXC__Site__c>(new LocationsSelector().selectLocations(new List<Id>(setSiteIds)));
        }
    }
}
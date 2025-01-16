/**
* @author Shivani Jain
* @date 27th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Agreements 
*
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Romi Taskar          31-Aug-2022          DCP-52923 - Changing the List of Location to Map of Location for simpler approach
* Nancy                26-Sep-2024          CMCM-10494 - Work Order Trigger Long Term Optimization - Part 2
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class IlluminaAddress_WOHelper {
    private static final Integer INTEGER_1 = 1;
    public static List<SVMXC__Service_Order__c> lstWorkOrderLocations = new List<SVMXC__Service_Order__c>(); //CMCM-10494
    public static List<Id> lstSiteIds=new List<Id>(); //CMCM-10494
    /**
    *  @author Naomi Thammadi
    *  @description - Get the Illumina address when the location is set on a work order
    *  @parameters : lstSiteIds: List<Id> - List of Locations ids
    *         lstWorkOrderLocations : List<SVMXC__Service_Order__c> - List of work orders
    *  @return : void
    **/
    public static void setIlluminaAddressOnWO(List<Sobject> records, Map<Id, SObject> oldRecords, List<SVMXC__Site__c> lstLocationrecordsbyCountries, Map<Id,SVMXC__Site__c> mapLocationrecords) {
        populateSites(records, oldRecords);
        //DCP-610
        Map<String, List<SVMXC__Site__c>> countryNameToLocationSites=new Map<String, List<SVMXC__Site__c>>();
        Map<Id,String> workOrderSiteToCountryNames=new Map<Id,String>();
        
        //DCP-610: get illumina addresses
        //Added null check for lstLocationrecordsbyCountries for INC0313186 as CP users do not have access to Location and hence this list is not getting initialized - Shruti Karn
        if(!lstSiteIds.isEmpty() && lstLocationrecordsbyCountries != null ) {
            for(SVMXC__Site__c objLoc: mapLocationrecords.values()) {
                workOrderSiteToCountryNames.put(objLoc.id,objLoc.SVMXC__Country__c);
            }

            for(SVMXC__Site__c objLocation: lstLocationrecordsbyCountries) {
                if(!countryNameToLocationSites.containsKey(objLocation.SVMXC__Country__c)) {
                    countryNameToLocationSites.put(objLocation.SVMXC__Country__c,new List<SVMXC__Site__c>());
                }
                countryNameToLocationSites.get(objLocation.SVMXC__Country__c).add(objLocation);
            }
            
            for(SVMXC__Service_Order__c objWO : lstWorkOrderLocations) {
                if(workOrderSiteToCountryNames.containsKey(objWO.SVMXC__Site__c) && countryNameToLocationSites.containsKey(workOrderSiteToCountryNames.get(objWO.SVMXC__Site__c))&& !countryNameToLocationSites.get(workOrderSiteToCountryNames.get(objWO.SVMXC__Site__c)).isEmpty()){
                    if(countryNameToLocationSites.get(workOrderSiteToCountryNames.get(objWO.SVMXC__Site__c)).size()== INTEGER_1) {
                        objWO.Illumina_Address__c=countryNameToLocationSites.get(workOrderSiteToCountryNames.get(objWO.SVMXC__Site__c))[0].id;
                    }
                    //assign the primary location if there are multiple illumina addresses defined for a country
                    else {
                        for(SVMXC__Site__c objLocations: countryNameToLocationSites.get(workOrderSiteToCountryNames.get(objWO.SVMXC__Site__c))) {
                            if(objLocations.Is_Primary_Illumina_Address__c) {
                                objWO.Illumina_Address__c=objLocations.id;
                                break;
                            }
                        }
                    }
                } else {
                    ilib_LogEvent.message('Illumina address not defined for the Country - '+workOrderSiteToCountryNames.get(objWO.SVMXC__Site__c));
                }
            } 
            
        } 
    }
    /**
    *  @author Nancy
    *  @description - populate WOs and WO Sites - added as part of CMCM-10494
    *  @parameters: List<Sobject> records, Map<Id, SObject> oldRecords
    *  @return : void
    **/
    public static void populateSites(List<Sobject> records, Map<Id, SObject> oldRecords) {
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = oldRecords != null && !oldRecords.isEmpty() ? (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)) : null;
            if((Trigger.isInsert && objWorkOrder.SVMXC__Site__c!=null) || (Trigger.isUpdate && objOldWorkOrder!= null && objWorkOrder.SVMXC__Site__c!=null && objOldWorkOrder.SVMXC__Site__c != objWorkOrder.SVMXC__Site__c )) {
                lstWorkOrderLocations.add(objWorkOrder);
                lstSiteIds.add(objWorkOrder.SVMXC__Site__c);
            }
        }  
    }

}
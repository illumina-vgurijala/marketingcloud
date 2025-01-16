/**
 * Class Name: UpdateContract_WorkDetailHelper
 * 
 * Description: Helper class for updating the contract info on work details.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for updating the contract info on work details.
 */
public with sharing class UpdateContract_WorkDetailHelper {
    public static final String STRING_WORK_DETAIL_LINE_STATUS_LABOR = 'Labor';
    /*
     *  @AUTHOR:  Tapas C
     *  @DESCRIPTION: INC0230587 - Update contract on work details 
     *   Added other 2 params  as part of incident INC0250483
     *  @PARAM :  list<SVMXC__service_order_Line__c> lstWD - list of WDs inserted/updated 
     *  @RETURN:  void
     */
    public static void updateContractOnWD(list < SVMXC__service_order_Line__c > lstWD, Boolean isInsert, Boolean isEntitlementInsertTrigger, List < Applied_Contract__c > lstWoEntitlement) {

        set < id > setWOIds = new set < Id > ();
        map < Id, list < SVMXC__service_order_Line__c >> mapWOIdSpareWD = new map < Id, list < SVMXC__service_order_Line__c >> ();
        map < Id, list < SVMXC__service_order_Line__c >> mapWOIdConsumableWD = new map < Id, list < SVMXC__service_order_Line__c >> ();
        map < Id, list < SVMXC__service_order_Line__c >> mapWOIdLaborWD = new map < Id, list < SVMXC__service_order_Line__c >> ();
        map < Id, Applied_Contract__c > mapWOIdConsContract = new map < Id, Applied_Contract__c > ();
        map < Id, Applied_Contract__c > mapWOIdSpareContract = new map < Id, Applied_Contract__c > ();
        map < Id, Applied_Contract__c > mapWOIdPartsOnlyContract = new map < Id, Applied_Contract__c > ();
        map < Id, Applied_Contract__c > mapWOIdLaborContract = new map < Id, Applied_Contract__c > ();
        Map < Id, SVMXC__Service_Order_Line__c > mapWDtoBeUpdated = new Map < Id, SVMXC__Service_Order_Line__c > ();
        List<Applied_Contract__c> lstAppliedContracts = new List<Applied_Contract__c>();
        populateWorkOrderMaps(lstWD, setWOIds, mapWOIdSpareWD, mapWOIdConsumableWD, mapWOIdLaborWD);
        lstAppliedContracts = fetchEntitlements(setWOIds, isEntitlementInsertTrigger);
        lstWoEntitlement.addAll(lstAppliedContracts);
        if (!lstWoEntitlement.isEmpty()) {
            Map < String, Map < Id, Applied_Contract__c >> mapLineTypeToContractsMap = new Map < String, Map < Id, Applied_Contract__c >> ();
            mapLineTypeToContractsMap = ServiceUtilityCollection.classifyEntitlementsByLineTypesIncluded(lstWoEntitlement);
            mapWOIdPartsOnlyContract = mapLineTypeToContractsMap.get('Parts Only');
            mapWOIdConsContract = mapLineTypeToContractsMap.get('Consumable');
            mapWOIdSpareContract = mapLineTypeToContractsMap.get('Spare');
            mapWOIdLaborContract = mapLineTypeToContractsMap.get('Labor');
        }
        for (Id woId: setWOIds) {
            if (mapWOIdSpareWD.containsKey(WOId) && mapWOIdPartsOnlyContract.containsKey(WOId)) {
                updateContractInfo(woId,mapWOIdSpareWD,mapWOIdPartsOnlyContract,mapWDtoBeUpdated);

            } else if (mapWOIdSpareWD.containsKey(WOId) && mapWOIdSpareContract.containsKey(WOId)) {
                updateContractInfo(woId,mapWOIdSpareWD,mapWOIdSpareContract,mapWDtoBeUpdated);
            }
            if (mapWOIdConsumableWD.containsKey(WOId) && mapWOIdConsContract.containsKey(WOId)) {
                updateContractInfo(woId,mapWOIdConsumableWD,mapWOIdConsContract,mapWDtoBeUpdated);
            }
            if (mapWOIdLaborWD.containsKey(WOId) && mapWOIdLaborContract.containsKey(WOId)) {
                updateContractInfo(woId,mapWOIdLaborWD,mapWOIdLaborContract,mapWDtoBeUpdated);
            }
        }
        updateWorkdetails(isInsert, isEntitlementInsertTrigger, lstWD, mapWDtoBeUpdated);
        
    }
    /**
     * Method: fetchEntitlements
     * Description: Method to fetch entitlements
     */
    public static List<Applied_Contract__c> fetchEntitlements(Set<Id> setWOIds, Boolean isEntitlementInsertTrigger){
        List<Applied_Contract__c> lstWoEntitlement = new List<Applied_Contract__c>();
        if (!setWOIds.isEmpty() && !isEntitlementInsertTrigger) {    
            lstWoEntitlement = new AppliedContractsSelector().selectWOEntitlements(setWOIds);    
        }
        return lstWoEntitlement;
    }
    /**
     * Method:updateWorkdetails
     * Description: Method to update wd.
     * return: void
     */
    public static void updateWorkdetails(Boolean isInsert, Boolean isEntitlementInsertTrigger, List < SVMXC__Service_Order_Line__c > lstWD, Map < Id, SVMXC__Service_Order_Line__c > mapWDtoBeUpdated){
        //-----------
        if (!isInsert && !isEntitlementInsertTrigger) {
            for (SVMXC__Service_Order_Line__c objWD: lstWD) {
                SVMXC__Service_Order_Line__c objWorkDetail = mapWDtoBeUpdated.get(objWD.Id);
                if (objWorkDetail != null) {
                    objWD.ERP_Header_Contract_Number__c = objWorkDetail.ERP_Header_Contract_Number__c;
                    objWD.ERP_Contract_Line_Number__c = objWorkDetail.ERP_Contract_Line_Number__c;
                }
            }
        }
        if (isEntitlementInsertTrigger && !mapWDtoBeUpdated.isEmpty()) {
            Workdetails.appliedContractsTriggerRanOnce = true;
            update mapWDtoBeUpdated.values();
        }
    }
    /**
     * Method:updateContractInfo
     * Description: Method to update contract info on wd.
     * return: void
     */
    public static void updateContractInfo(Id woId, map < Id, list < SVMXC__service_order_Line__c >> mapWOIdWD, map < Id, Applied_Contract__c > mapWOIdContract, Map < Id, SVMXC__Service_Order_Line__c > mapWDtoBeUpdated){
        for (SVMXC__Service_Order_Line__c objWD: mapWOIdWD.get(WOId)) {
            objWD.ERP_Header_Contract_Number__c = mapWOIdContract.get(WOId).Service_Contract__r.ERP_Header_Contract_Number__c;
            objWD.ERP_Contract_Line_Number__c = mapWOIdContract.get(WOId).Service_Contract__r.ERP_Contract_Line_Number__c;
            mapWDtoBeUpdated.put(objWD.Id, objWD);
        }
    }
    /**
     * Method: populateWorkOrderMaps
     * Description: Method to populate the maps
     */
    public static void populateWorkOrderMaps(List < SVMXC__service_order_Line__c > lstWD, Set<Id> setWOIds, map < Id, list < SVMXC__service_order_Line__c >> mapWOIdSpareWD, map < Id, list < SVMXC__service_order_Line__c >> mapWOIdConsumableWD, map < Id, list < SVMXC__service_order_Line__c >> mapWOIdLaborWD){
        for (SVMXC__service_order_Line__c objWD: lstWD) {
            if (objWD.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS || objWD.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED || objWD.SVMXC__Line_Type__c == 'labor') {
                setWOIds.add(objWD.SVMXC__Service_Order__c);
                if (objWD.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) {
                    populateRequiredMaps(mapWOIdSpareWD, objWD);
                } else if (objWD.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED) {
                    populateRequiredMaps(mapWOIdConsumableWD, objWD);
                } else if (objWD.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_STATUS_LABOR) {
                    populateRequiredMaps(mapWOIdLaborWD, objWD);
                }
            }
        }
    }
    /**
     * Method: populateRequiredMaps
     * Description: Method to populate the map of work order to work details.
     * return: void
     */
    public static void populateRequiredMaps(map < Id, list < SVMXC__service_order_Line__c >> mapWoIdWds, SVMXC__service_order_Line__c objWD){
        if (!mapWoIdWds.containsKey(objWD.SVMXC__Service_Order__c)){
            mapWoIdWds.put(objWD.SVMXC__Service_Order__c, new list < SVMXC__service_order_Line__c > ());
        }   
        mapWoIdWds.get(objWD.SVMXC__Service_Order__c).add(objWD);
    }
    
}

/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to update Contract 
*/ 
public with sharing class UpdateContract_POLHelper {
    
    /*
     *  @AUTHOR:  Shruti Karn 
     *  @DESCRIPTION: INC0227445 - Update contract on Parts order line based on the Product type 
     *  @PARAM :  List<SVMXC__RMA_Shipment_Line__c> lstCurrentPartsOrderLines
     *  @RETURN:  void
     */  
    public static void updateContractOnPOL(list<SVMXC__RMA_Shipment_Line__c> lstPOL, Boolean isEntitlementInsertTrigger, List<Applied_Contract__c> lstAppliedContracts) {
         
        set<Id> setShipmentWorkId = new set<Id>();
        set<id> setPOId = new set<Id>();
        map<String,SVMXC__RMA_Shipment_Line__c> mapUpdatedPOLs = new map<String,SVMXC__RMA_Shipment_Line__c>(); //to update the original records
        list <Applied_Contract__c> lstWoEntitlement = new list<Applied_Contract__c>();
        map<Id,list<SVMXC__RMA_Shipment_Line__c>> mapWOIdSparePOL = new map<Id,list<SVMXC__RMA_Shipment_Line__c>>();
        map<Id,list<SVMXC__RMA_Shipment_Line__c>> mapWOIdConsumablePOL = new map<Id,list<SVMXC__RMA_Shipment_Line__c>>();
        map<Id,Applied_Contract__c> mapWOIdConsContract = new map<Id,Applied_Contract__c>();
        map<Id,Applied_Contract__c> mapWOIdSpareContract = new map<Id,Applied_Contract__c>();
        map<Id,Applied_Contract__c> mapWOIdPartsOnlyContract = new map<Id,Applied_Contract__c>();
        map<Id,SVMXC__RMA_Shipment_Order__c > mapPOIdtoPO = new map<Id, SVMXC__RMA_Shipment_Order__c >();
        
        setPOId = populateSetPOLids(lstPOL);
        
        //To get the value of Work Order and type of Parts Order
        if(!setPOId.isEmpty()) {
            mapPOIdtoPO = new Map<Id,SVMXC__RMA_Shipment_Order__c>(new PartsOrdersSelector().selectPartsOrders(setPOId));
        }
        
        for (SVMXC__RMA_Shipment_Line__c rmaLine: lstPOL) {
            if(setPOId.contains(rmaLine.SVMXC__RMA_Shipment_Order__c) && mapPOIdtoPO.get(rmaLine.SVMXC__RMA_Shipment_Order__c) != null
                    && mapPOIdtoPO.get(rmaLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Order_Type__c == PartsOrderLines.STRING_PARTS_ORDER_TYPE_SHIPMENT  
                    && mapPOIdtoPO.get(rmaLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Service_Order__c != null) {
                setShipmentWorkId.add(mapPOIdtoPO.get(rmaLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Service_Order__c);
                mapWOIdSparePOL = populatePOLMap(rmaLine, PartsOrderLines.STRING_PRODUCT_TYPE, mapWOIdSparePOL, mapPOIdtoPO);
                mapWOIdConsumablePOL = populatePOLMap(rmaLine, PartsOrderLines.STRING_PARTS_ORDER_LINE_CONSUMABLE, mapWOIdConsumablePOL, mapPOIdtoPO);
            }
        }    
        
                    
        if(!setShipmentWorkId.isEmpty()) {
            lstWoEntitlement = populateLstEntitlements(isEntitlementInsertTrigger, setShipmentWorkId, lstAppliedContracts);
            
            if(!lstWoEntitlement.isEmpty()) {
                Map<String, Map<Id,Applied_Contract__c>> mapLineTypeToContractsMap = new Map<String, Map<Id,Applied_Contract__c>>();
                mapLineTypeToContractsMap = ServiceUtilityCollection.classifyEntitlementsByLineTypesIncluded(lstWoEntitlement);
                mapWOIdPartsOnlyContract = mapLineTypeToContractsMap.get('Parts Only');
                mapWOIdConsContract = mapLineTypeToContractsMap.get(PartsOrderLines.STRING_PARTS_ORDER_LINE_CONSUMABLE);
                mapWOIdSpareContract = mapLineTypeToContractsMap.get(PartsOrderLines.STRING_PRODUCT_TYPE);
            }
                            
            for(Id woId: setShipmentWorkId) {
                mapUpdatedPOLs = populateContractValuesPOL(woId, mapWOIdSparePOL, mapWOIdPartsOnlyContract, mapUpdatedPOLs);
                mapUpdatedPOLs = populateContractValuesPOL(woId, mapWOIdSparePOL, mapWOIdSpareContract, mapUpdatedPOLs);
                mapUpdatedPOLs = populateContractValuesPOL(woId, mapWOIdConsumablePOL, mapWOIdConsContract, mapUpdatedPOLs);
            }
            
        }
        
        updatePOLRecords(isEntitlementInsertTrigger, lstPOL, mapUpdatedPOLs);
    }
 
    /*******************************************************************************************************
    * @description populate mapWOIdSparePOL and mapWOIdConsumablePOL
    * @param rmaLine SVMXC__RMA_Shipment_Line__c
    * @param pType Product Type
    * @param mapWOIdPOL Map<Id,list<SVMXC__RMA_Shipment_Line__c>>
    * @param mapPOIdtoPOmap<Id,SVMXC__RMA_Shipment_Order__c >
    * @return map<Id,list<SVMXC__RMA_Shipment_Line__c>>
    */
    private static map<Id,list<SVMXC__RMA_Shipment_Line__c>> populatePOLMap(SVMXC__RMA_Shipment_Line__c rmaLine, String pType,
                        Map<Id,list<SVMXC__RMA_Shipment_Line__c>> mapWOIdPOL, map<Id,SVMXC__RMA_Shipment_Order__c > mapPOIdtoPO) {
        if(rmaLine.Service_Product_Type__c == pType) {
            if(!mapWOIdPOL.containsKey(mapPOIdtoPO.get(rmaLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Service_Order__c)) {
                mapWOIdPOL.put(mapPOIdtoPO.get(rmaLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Service_Order__c , new list<SVMXC__RMA_Shipment_Line__c>());
            }
            mapWOIdPOL.get(mapPOIdtoPO.get(rmaLine.SVMXC__RMA_Shipment_Order__c).SVMXC__Service_Order__c).add(rmaLine);
        }
        return mapWOIdPOL;
    }

    /*******************************************************************************************************
    * @description populate setPOLids
    * @param lstPOL List<SVMXC__RMA_Shipment_Line__c>
    * @return Set<Id>
    */
    private static Set<Id> populateSetPOLids(List<SVMXC__RMA_Shipment_Line__c> lstPOL) {
        set<id> setPOId = new set<Id>();
        
        for (SVMXC__RMA_Shipment_Line__c rmaLine: lstPOL) {
            if(rmaLine.Service_Product_Type__c != null && (rmaLine.Service_Product_Type__c == PartsOrderLines.STRING_PRODUCT_TYPE 
                    || rmaLine.Service_Product_Type__c == PartsOrderLines.STRING_PARTS_ORDER_LINE_CONSUMABLE)) {
                setPOId.add(rmaLine.SVMXC__RMA_Shipment_Order__c);
            } 
        }
        return setPOId;
    }

    /*******************************************************************************************************
    * @description update Parts Order Line records
    * @param isEntitlementInsertTrigger Boolean
    * @param lstPOL List<SVMXC__RMA_Shipment_Line__c>
    * @param mapUpdatedPOLs Map<String, SVMXC__RMA_Shipment_Line__c>
    * @return void
    */
    private static void updatePOLRecords(Boolean isEntitlementInsertTrigger, List<SVMXC__RMA_Shipment_Line__c> lstPOL, 
                                                                        Map<String,SVMXC__RMA_Shipment_Line__c> mapUpdatedPOLs) {
        if(!isEntitlementInsertTrigger) {
            for (SVMXC__RMA_Shipment_Line__c rmaLine: (List<SVMXC__RMA_Shipment_Line__c>) lstPOL) {
                if(mapUpdatedPOLs.containsKey(rmaLine.SVMXC__RMA_Shipment_Order__c+rmaLine.Service_Product_Type__c)) { 
                    rmaLine.ERP_Contract_Number__c = mapUpdatedPOLs.get(rmaLine.SVMXC__RMA_Shipment_Order__c+rmaLine.Service_Product_Type__c).ERP_Contract_Number__c;
                    rmaLine.ERP_Contract_Line_Number__c = mapUpdatedPOLs.get(rmaLine.SVMXC__RMA_Shipment_Order__c+rmaLine.Service_Product_Type__c).ERP_Contract_Line_Number__c;
                }
            }
        } else {
            if(!mapUpdatedPOLs.IsEmpty()){
                PartsOrderLines.appliedContractsTriggerRanOnce = true;
                update mapUpdatedPOLs.values();
            }
        }
    }

    /*******************************************************************************************************
    * @description populate ERP Contract Number and Line Number on POL
    * @param woId id
    * @param mapWOIdPOL Map<Id,list<SVMXC__RMA_Shipment_Line__c>>
    * @param mapWOIdContract Map<Id, Applied_Contract__c>
    * @param mapUpdatedPOLs Map<String,SVMXC__RMA_Shipment_Line__c> 
    * @return Map<String, SVMXC__RMA_Shipment_Line__c>
    */
    private static Map<String,SVMXC__RMA_Shipment_Line__c> populateContractValuesPOL(Id woId, Map<Id,list<SVMXC__RMA_Shipment_Line__c>> mapWOIdPOL, 
                Map<Id,Applied_Contract__c> mapWOIdContract,  Map<String,SVMXC__RMA_Shipment_Line__c> mapUpdatedPOLs) {
        if(mapWOIdPOL.containsKey(woId) && mapWOIdContract.containsKey(woId) ) {
            for(SVMXC__RMA_Shipment_Line__c pol : mapWOIdPOL.get(woId)) {
                pol.ERP_Contract_Number__c = mapWOIdContract.get(woId).Service_Contract__r.ERP_Header_Contract_Number__c;
                pol.ERP_Contract_Line_Number__c = mapWOIdContract.get(woId).Service_Contract__r.ERP_Contract_Line_Number__c;
                if(!mapUpdatedPOLs.containsKey(pol.SVMXC__RMA_Shipment_Order__c+pol.Service_Product_Type__c )) {
                    mapUpdatedPOLs.put((pol.SVMXC__RMA_Shipment_Order__c+pol.Service_Product_Type__c), pol);
                }
            }
        }
        return  mapUpdatedPOLs;
    }

    /*******************************************************************************************************
    * @description populate setPOLids
    * @param isEntitlementInsertTrigger Boolean
    * @param setShipmentWorkId Set<Id>
    * @param lstAppliedContracts List<Applied_Contract__c>
    * @return List<Applied_Contract__c>
    */
    private static List<Applied_Contract__c> populateLstEntitlements(Boolean isEntitlementInsertTrigger, Set<Id> setShipmentWorkId, 
                                                                    List<Applied_Contract__c> lstAppliedContracts) {
        List<Applied_Contract__c> lstWoEntitlement = new List<Applied_Contract__c>();

        if(!isEntitlementInsertTrigger){
            lstWoEntitlement = new AppliedContractsSelector().selectWOEntitlements(setShipmentWorkId);
        } else {
            //get the applied contracts which are related to WOs with shipment type partsorder. 
            for(Applied_Contract__c contract : lstAppliedContracts){
                if(setShipmentWorkId.contains(contract.Work_Order__c)){
                    lstWoEntitlement.add(contract);
                }
            }
        }
        return lstWoEntitlement;
    }
 
}
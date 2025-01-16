/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Helper Class for Parts Order Line Trigger to run logic Billable logic 
*/ 
public with sharing class BillableRules_POLHelper {
    
    /*******************************************************************************************************
    * @description Update of Isbillable Logic to Metadata // DCP-43163 
    * @param records List<sObject>
    * @return List<sObject>
    */
    public static List<Sobject> executeIsBillableRules(List<Sobject> records) {
       
        Set<Id> setWorkOrderIds = new Set<Id>();
        Set<Id> setServiceContractIds = new Set<Id>();
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders = new List < SVMXC__RMA_Shipment_Order__c >();
        Map<Id, SVMXC__RMA_Shipment_Order__c> idToPartsOrders = new Map<id,SVMXC__RMA_Shipment_Order__c>();
        Map<Id,SVMXC__Service_Order__c> idToworkOrder = new Map<Id,SVMXC__Service_Order__c>();
        Map<Id,SVMXC__Service_Order__c> idPOToworkOrder = new Map<Id,SVMXC__Service_Order__c>();
        Map<Id, List<SVMXC__Service_Contract__c>> idPOToServiceContract = new Map <Id, List<SVMXC__Service_Contract__c>>();
        Map<Id, Id> mapCaseIdPOID = new Map<Id, Id>();
        Map<Id, Id> mapWOIdPOID = new Map<Id, Id>();
        

        lstPartsOrders = queryPartsOrder();
        
        for(SVMXC__RMA_Shipment_Order__c objPartsOrder: lstPartsOrders) {
            if (objPartsOrder.SVMXC__Case__c != null) {
                mapCaseIdPOID.put(objPartsOrder.SVMXC__Case__c, objPartsOrder.Id);
                if(objPartsOrder.SVMXC__Service_Order__c != null){
                    setWorkOrderIds.add(objPartsOrder.SVMXC__Service_Order__c);
                    //INC0375826
                    mapWOIdPOID.put(objPartsOrder.SVMXC__Service_Order__c,objPartsOrder.Id);
                }
                idToPartsOrders.put(objPartsOrder.Id, objPartsOrder);
            } else if (objPartsOrder.SVMXC__Service_Order__c != null) {
                idToPartsOrders.put(objPartsOrder.Id, objPartsOrder);
                setWorkOrderIds.add(objPartsOrder.SVMXC__Service_Order__c);
                mapWOIdPOID.put(objPartsOrder.SVMXC__Service_Order__c, objPartsOrder.Id);
            }
        
        }
        //Populating PartsOrderId to WorkOrder Map
        if(!setWorkOrderIds.isEmpty()) {
            idToworkOrder = new Map<Id,SVMXC__Service_Order__c>(new WorkOrdersSelector().selectWorkOrders(setWorkOrderIds));
            for(id idPO: idToPartsOrders.keyset()){
                idPOToworkOrder.put(idPO, idToworkOrder.get(idToPartsOrders.get(idPO).SVMXC__Service_Order__c));
            }
        }

        // Create Map of Case/Work Order IDs and Entitlements
        list<Applied_Contract__c> lstCaseEntitlement = new AppliedContractsSelector().selectCaseEntitlements(mapCaseIdPOID.keySet());
        list<Applied_Contract__c> lstWoEntitlement = new AppliedContractsSelector().selectWorkOrderEntitlements(mapWOIdPOID.keySet());
        Map<Id, List <Applied_Contract__c>> idToCaseEntitlement = UtilsCollection.getMapOfIdToSObjects(lstCaseEntitlement, 
                                                                                PartsOrderLines.STRING_CASENO_API_NAME);
        Map<Id, List<Applied_Contract__c>> idToWorkOrderEntitlement = UtilsCollection.getMapOfIdToSObjects(lstWoEntitlement, 
                                                                                PartsOrderLines.STRING_WORKORDER_API_NAME);

        // Collect Service Contract IDs into a Set For Case or Work Order
        if (!idToCaseEntitlement.isEmpty()) {
            for(Applied_Contract__c entitlement : lstCaseEntitlement) {
                if (entitlement.Service_Contract__c != null) {
                    setServiceContractIds.add(entitlement.Service_Contract__c);
                }
            }
        } 
        //Added if check for WO Entitlement - INC0421820
        if(!idToWorkOrderEntitlement.isEmpty()){
            for(Applied_Contract__c entitlement : lstWoEntitlement) {
                if (entitlement.Service_Contract__c != null) {
                    setServiceContractIds.add(entitlement.Service_Contract__c);
                }
            }
        }
        
        // Create Map of Service Contracts
        Map <Id, SVMXC__Service_Contract__c> idToServiceContract = new Map <Id, SVMXC__Service_Contract__c> 
                    (new ServiceContractSelector().selectServiceContracts(setServiceContractIds));
    
        idPOToServiceContract = populateIdPOToServiceContract(mapCaseIdPOID, mapWOIdPOID, idToServiceContract, idToCaseEntitlement, idToWorkOrderEntitlement);
        if(!idToPartsOrders.IsEmpty()){
            Map<String, Map<Id,Object>> mapofNeededSobjects=new Map<String , Map<Id,Object>>();
            mapofNeededSobjects.put('POLtoServiceContractMap', idPOToServiceContract);
            mapofNeededSobjects.put('POLToWorkOrderMap', idPOToworkOrder);
            mapofNeededSobjects.put('POLToProductMap', PartsOrderLines.mapProduct);

            return RuleEngineLogic.runtheBussinessRules('SVMXC__RMA_Shipment_Line__c','Billable', records, mapofNeededSobjects, null);
        }
        return null;
    }

    /*******************************************************************************************************
    * @description populate idPOToServiceContract
    * @param mapCaseIdPOID Map<Id, Id>
    * @param mapWOIdPOID Map<Id, Id>
    * @param idToServiceContract Map<Id, SVMXC__Service_Contract__c>
    * @param idToCaseEntitlement Map<Id, List <Applied_Contract__c>>
    * @param idToWorkOrderEntitlement Map<Id, List <Applied_Contract__c>>
    * @return Map<Id, List<SVMXC__Service_Contract__c>>
    */
    private static Map<Id, List<SVMXC__Service_Contract__c>> populateIdPOToServiceContract(Map<Id, Id> mapCaseIdPOID, Map<Id, Id> mapWOIdPOID, 
            Map<Id, SVMXC__Service_Contract__c> idToServiceContract, Map<Id, List <Applied_Contract__c>> idToCaseEntitlement, 
            Map<Id, List<Applied_Contract__c>> idToWorkOrderEntitlement) {
        Map<Id, List<SVMXC__Service_Contract__c>> idPOToServiceContract = new Map <Id, List<SVMXC__Service_Contract__c>>();
        
        for(id idCase:idToCaseEntitlement.keyset()){
            if(!idPOToServiceContract.containskey(idCase)){
                idPOToServiceContract.put(mapCaseIdPOID.get(idCase), new List<SVMXC__Service_Contract__c>());
            }
            for (Applied_Contract__c entitlement: idToCaseEntitlement.get(idCase)) {
                idPOToServiceContract.get(mapCaseIdPOID.get(idCase)).add(idToServiceContract.get(entitlement.Service_Contract__c));
            }
            
        }
        for(id idWorkOrder:idToWorkOrderEntitlement.keyset()){
            if(!idPOToServiceContract.containskey(idWorkOrder)){
                idPOToServiceContract.put(mapWOIdPOID.get(idWorkOrder), new List<SVMXC__Service_Contract__c>());
            }
            for (Applied_Contract__c entitlement: idToWorkOrderEntitlement.get(idWorkOrder)) {
                idPOToServiceContract.get(mapWOIdPOID.get(idWorkOrder)).add(idToServiceContract.get(entitlement.Service_Contract__c));
            }
            
        }
        return idPOToServiceContract;
    }

    /*******************************************************************************************************
    * @description query Parts Order
    * @param isChannelPartner True if logged in user is CP
    * @param records List <SVMXC__RMA_Shipment_Line__c>
    * @return
    */
    private static List<SVMXC__RMA_Shipment_Order__c> queryPartsOrder() {
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrders = new List < SVMXC__RMA_Shipment_Order__c >();
        
        //Create Wo and Case Map    
        if(PartsOrderLines.partsOrderIdToPartsOrder != null && !PartsOrderLines.partsOrderIdToPartsOrder.isEmpty()){
            lstPartsOrders = new PartsOrdersSelector().selectPartsOrdersExcludingOrderType(PartsOrderLines.partsOrderIdToPartsOrder.keyset(), 
                                                        PartsOrderLines.STRING_PARTS_ORDER_TYPE_RETURN);
            //querying parts order whose status is not return to bypass return type parts orders from entitlement check
        }
        return lstPartsOrders;
    }

    /*******************************************************************************************************
    * @description method to execute Billable logic on Before Update event
    */
    public static void executeBillableBeforeUpdate() {
        Map<Id, set<Id>> idwoToSetAppContractId = new  Map<Id, set<Id>>();
        Map<Id,Id> idPOLToIdWo = new Map<Id,Id>();
        Set<Id> setWorkOrderIds = new Set<Id>();
        Map<Id,SVMXC__Service_Order__c> idPOToWo = new Map<Id,SVMXC__Service_Order__c>();
        Map<Id,SVMXC__Service_Order__c> mapRelatedWO = new Map<Id,SVMXC__Service_Order__c>(
            new WorkOrdersSelector().selectWorkOrders(PartsOrderLines.setRelatedWorkOrderId) );
        
            
        for (Id polId: PartsOrderLines.mapPOLWithBillableChange.keyset()) {
            idPOLToIdWo.put(polId, PartsOrderLines.mapCurrentPartsOrderLines.get(polId).SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c);
            if (PartsOrderLines.mapCurrentPartsOrderLines.get(polId).SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c != null) {
                setWorkOrderIds.add(PartsOrderLines.mapCurrentPartsOrderLines.get(polId).SVMXC__RMA_Shipment_Order__r.SVMXC__Service_Order__c);
            }
        }
            //DCP-33876
        
        idwoToSetAppContractId = generateIdwoToSetAppContractId(setWorkOrderIds);

        //DCP-40191
        for(SVMXC__RMA_Shipment_Line__c partOrderLine: PartsOrderLines.mapPOLWithBillableChange.values()) {
                //DCP-40191
            if(mapRelatedWO!=null && idPOLToIdWo.containsKey(partOrderLine.id) && mapRelatedWO.containsKey(idPOLToIdWo.get(partOrderLine.id))) {
                idPOToWo.put(partOrderLine.SVMXC__RMA_Shipment_Order__c, mapRelatedWO.get(idPOLToIdWo.get(partOrderLine.id)));
            }
        }
        //DCP-40191
        if(!PartsOrderLines.mapPOLWithBillableChange.IsEmpty()) {
            List<String> lstruleIds=new List<String>();
            if(!String.IsEmpty(Label.POLBillableRulesonUpdate)) {
                lstruleIds=new List<String>(Label.POLBillableRulesonUpdate.split(',')); 
            }
            Map<String , Map<Id,Object>> mapofNeededSobjects=new Map<String , Map<Id,Object>>();
            mapofNeededSobjects.put('POLToWorkOrderMap',idPOToWo);
            RuleEngineLogic.runtheBussinessRules('SVMXC__RMA_Shipment_Line__c','Billable',(List<Sobject>)PartsOrderLines.mapPOLWithBillableChange.values(),mapofNeededSobjects,lstruleIds);
        }        

        throwRelocationBillableError(idwoToSetAppContractId, mapRelatedWO, idPOLToIdWo);
    }

    /*******************************************************************************************************
    * @description Throw Relocation Billable Error 
    * @param idwoToSetAppContractId Map<Id, set<Id>>
    * @param mapRelatedWO Map<Id, SVMXC__Service_Order__c>
    * @param idPOLToIdWo Map<id, Id>
    * @return void
    */
    private static void throwRelocationBillableError(Map<Id, set<Id>> idwoToSetAppContractId, Map<Id,SVMXC__Service_Order__c> mapRelatedWO, 
                                                                            Map<Id, Id> idPOLToIdWo) {
        for(SVMXC__RMA_Shipment_Line__c partOrderLine: PartsOrderLines.mapPOLWithBillableChange.values()) {
                
            if((!partOrderLine.Is_Billable__c || partOrderLine.Reason__c!=null) && idwoToSetAppContractId!= null 
                    && idwoToSetAppContractId.containsKey(idPOLToIdWo.get(partOrderLine.id))
                    && !idwoToSetAppContractId.get(idPOLToIdWo.get(partOrderLine.id)).isEmpty()
                    && mapRelatedWO != null && mapRelatedWO.containsKey(idPOLToIdWo.get(partOrderLine.id)) 
                    && mapRelatedWO.get(idPOLToIdWo.get(partOrderLine.id)).SVMXC__Order_Type__c==PartsOrderLines.STRING_WORK_ORDER_ORDER_TYPE_RELOCATION 
                    && mapRelatedWO.get(idPOLToIdWo.get(partOrderLine.id)).IP_Asset_Type__c==PartsOrderLines.STRING_WORK_ORDER_IP_ASSET_TYPE_CUSTOMER_OWNED){
                partOrderLine.addError(Label.Relocation_Billable_Error);
            }
            
        }
    }
    
    /*******************************************************************************************************
    * @description populate idwoToSetAppContractId
    * @param setWorkOrderIds Set<Id>
    * @return Map<Id, set<Id>>
    */
    private static Map<Id, set<Id>> generateIdwoToSetAppContractId(Set<Id> setWorkOrderIds) {
        Map<Id, set<Id>> idwoToSetAppContractId = new  Map<Id, set<Id>>();

        if(!setWorkOrderIds.isEmpty()) {
            for (Applied_Contract__c objAppContract: new AppliedContractsSelector().selectWorkOrderEntitlements(setWorkOrderIds)) {
                if (!idwoToSetAppContractId.containskey(objAppContract.Work_Order__c)) {
                    idwoToSetAppContractId.put(objAppContract.Work_Order__c, new Set <Id> ());
                }
                idwoToSetAppContractId.get(objAppContract.Work_Order__c).add(objAppContract.Id);
            }
        }
        return idwoToSetAppContractId;
    }

    /*******************************************************************************************************
    * @description method to populate records for runnning Before Update event
    * @param partsOrderLine New record
    * @param objOldPartOrderLine Old record
    * @return
    */
    public static void populateIsBillableChangeSets(SVMXC__RMA_Shipment_Line__c partOrderLine, SVMXC__RMA_Shipment_Line__c objOldPartOrderLine) {
        if(partOrderLine.Reason__c != objOldPartOrderLine.Reason__c || partOrderLine.Is_Billable__c != objOldPartOrderLine.Is_Billable__c) {   
            PartsOrderLines.mapPOLWithBillableChange.put(partOrderLine.Id, partOrderLine);

            //INC0401821
            if(partOrderLine.Is_Billable__c && partOrderLine.Reason__c == PartsOrderLines.STRING_PARTSORDERLINE_NON_BILLABLE_REASON_GOODWILL && partOrderLine.Reason__c != objOldPartOrderLine.Reason__c) {
                partOrderLine.Is_Billable__c=false;
            }
        }
    }
}

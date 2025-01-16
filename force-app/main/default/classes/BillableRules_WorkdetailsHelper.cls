/*****************************************************************************************************************
 * Class Name: BillableRules_WorkdetailsHelper
 * 
 * Description: Helper class for updating the billing rules on work details.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for updating the billing rules on work details.
 * 
 ******************************************************************************************************************/
public with sharing class BillableRules_WorkdetailsHelper {
    /* @DESCRIPTION:DCP-40191 - to update the Is billable field on wd .
     *  @Author :Digvijay
     *  @RETURN:  void
     */
    public static List < Sobject > executeIsBillableRules(List < Sobject > records) {

        Set < Id > setWorkOrderIds = new Set < Id > ();
        Set < Id > setProductIds = new Set < Id > ();
        Set < Id > setServiceContractIds = new Set < Id > ();
        Map < id, Id > mapWOtoServiceCId = new Map < id, Id > ();
        Map < Id, Sobject > userMap = new Map < Id, Sobject > ();
        Map < id, List < SVMXC__Service_Contract__c >> workDetailtoServiceContractMap = new Map < id, List < SVMXC__Service_Contract__c >> ();
        Map < Id, SVMXC__Service_Order__c > idToWorkOrder = new Map < Id, SVMXC__Service_Order__c >();
        
        for (SVMXC__Service_Order_Line__c wd: (List < SVMXC__Service_Order_Line__c > ) records) {
            //37747 by pass billable logic for canceled lines
            if (wd.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {

                UserMap.put(wd.SVMXC__Service_Order__c, new user(Username = UserInfo.getName()));
                setProductIds.add(wd.SVMXC__Product__c);
                setWorkOrderIds.add(wd.SVMXC__Service_Order__c);

            }

            if (wd.Is_Under_Service_Contract__c && wd.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) {
                wd.Non_Billable_Reason__c = Workdetails.STRING_WORK_DETAIL_NON_BILLABLE_REASON_SPARE_PART_WARRANTY;

            }
        }



        // Exit if no records are qualified
        if (setWorkOrderIds.isEmpty()){
            return new List<sObject>();
        }
        Map < Id, Product2 > mapIdToProduct = populateProductMap(setProductIds);
        idToWorkOrder = populatePONumber(records, setWorkOrderIds);

        createEntitlementsForWorkOrder(setWorkOrderIds, setServiceContractIds, mapWOtoServiceCId);
        createServiceContractsMap(setServiceContractIds, mapWOtoServiceCId, workDetailtoServiceContractMap);
        System.debug('idToWorkOrder--:'+idToWorkOrder);
        if (!idToWorkOrder.IsEmpty()) {
            Map < String, Map < Id, Object >> mapofNeededSobjects = new Map < String, Map < Id, Object >> ();
            mapofNeededSobjects.put('WorkDetailtoServiceContractMap', WorkDetailtoServiceContractMap);
            mapofNeededSobjects.put('WorkDetailtoWorkOrderMap', idToWorkOrder);
            mapofNeededSobjects.put('WorkDetailtoProductMap', mapIdToProduct);

            mapofNeededSobjects.put('UserMap', UserMap);
            System.debug('here..' + mapofNeededSobjects);
            return RuleEngineLogic.runtheBussinessRules(WOrkdetails.STRING_WORK_DETAIL_OBJECT_API_NAME, workdetails.STRING_WORK_ORDER_BILLING_TYPE_IS_BILLABLE, records, mapofNeededSobjects, null);
        }

        return new List<sObject>();
    }
    /**
     * Method: populateProductMap
     * Description: populate the product map.
     */
    public static Map < Id, Product2 > populateProductMap(Set<Id> setProductIds){
        Map < Id, Product2 > mapIdToProduct = new Map<Id, Product2>();
        // Create Product Map
        List < Product2 > lstProduct = new List<Product2>();
        if (!setProductIds.isEmpty()) {
            lstProduct = new ProductsSelector().selectProducts(setProductIds);
        }
        if (!lstProduct.isEmpty()) {
            
            mapIdToProduct = new Map < Id, Product2 > (lstProduct);
        }
        return mapIdToProduct;
    }
    /**
     * Method: populatePONumber
     * Description: populate the PO number.
     */
    public static Map < Id, SVMXC__Service_Order__c > populatePONumber(List <Sobject> records, Set<Id> setWorkOrderIds){
        Map < Id, SVMXC__Service_Order__c > idToWorkOrder = new Map < Id, SVMXC__Service_Order__c > (new WorkOrdersSelector().selectWorkOrders(setWorkOrderIds));

        for (SVMXC__Service_Order_Line__c wd: (List < SVMXC__Service_Order_Line__c > ) records) {
            if (idToworkOrder.containskey(wd.SVMXC__Service_Order__c)) {
                wd.PO_Number__c = idToworkOrder.get(wd.SVMXC__Service_Order__c).PO_Number__c;
                //DCP-41937
                if (idToworkOrder.containsKey(wd.SVMXC__Service_Order__c) && idToworkOrder.get(wd.SVMXC__Service_Order__c).SVMXC__Order_Type__c == Workdetails.STRING_WORK_ORDER_ORDER_TYPE_RELOCATION && idToworkOrder.get(wd.SVMXC__Service_Order__c).IP_Asset_Type__c == Workdetails.STRING_WORK_ORDER_IP_ASSET_TYPE_CUSTOMER_OWNED && wd.Non_Billable_Reason__c != null) {
                    wd.Non_Billable_Reason__c = '';
                }
            }
        }
        return idToWorkOrder;
    }
    /**
     * Method:createEntitlementsForWorkOrder
     * Description: create entitlements for work order.
     */
    public static void createEntitlementsForWorkOrder(Set<Id> setWorkOrderIds, Set<Id> setServiceContractIds, Map < id, Id > mapWOtoServiceCId){
        // Create map of all Entitlements for each Work Order
        List < Applied_Contract__c > lstEntitlement = new AppliedContractsSelector().selectWorkOrderEntitlements(setWorkOrderIds);
        if (!lstEntitlement.isEmpty()) {
            Map < id, list < Applied_Contract__c >> idToEntitlement = UtilsCollection.getMapOfIdToSObjects(lstEntitlement, Workdetails.STRING_WORKORDER_API_NAME);

            // Create Contract Ids
            //if (!idToEntitlement.isEmpty()) {
                for (Id wo: idToEntitlement.keySet()) {
                    for (Applied_Contract__c entitlement: idToEntitlement.get(wo)) {
                        if (entitlement.Service_Contract__c != null) {
                            setServiceContractIds.add(entitlement.Service_Contract__c);
                            mapWOtoServiceCId.put(entitlement.Service_Contract__c, wo);
                        }
                    }
                }
            //}
        }
    }
    /**
     * Method:createServiceContractsMap
     * Description: create service contracts map
     */
    public static void createServiceContractsMap(Set<Id> setServiceContractIds,Map < id, Id > mapWOtoServiceCId, Map < id, List < SVMXC__Service_Contract__c >> workDetailtoServiceContractMap){
        List < SVMXC__Service_Contract__c > lstServiceContract = new List<SVMXC__Service_Contract__c>();
        if (!setServiceContractIds.isEmpty()) {
            // Create Map of Contracts which will be used to fetch the fields
            lstServiceContract = new ServiceContractSelector().selectServiceContracts(setServiceContractIds);
        }
        //testing code : to be removed later
        for (SVMXC__Service_Contract__c obj: lstServiceContract) {
            if (mapWOtoServiceCId.containsKey(obj.id)) {

                if (!WorkDetailtoServiceContractMap.ContainsKey(mapWOtoServiceCId.get(obj.id))){
                    WorkDetailtoServiceContractMap.put(mapWOtoServiceCId.get(obj.id), new List < SVMXC__Service_Contract__c > ());
                }
                WorkDetailtoServiceContractMap.get(mapWOtoServiceCId.get(obj.id)).add(obj);
            }
        }
        
    }
   
}

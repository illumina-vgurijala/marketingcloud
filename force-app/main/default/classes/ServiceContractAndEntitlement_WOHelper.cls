/**
* @author Shivani Jain
* @date 6th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Service Contract and Entitlement 
* Dhairya Shah 29-Feb-2024 - CMCM-9
*/ 
public with sharing class ServiceContractAndEntitlement_WOHelper {

    private static final String STATUS_ACTIVE = 'Active';
    //CMCM-5307 - Start
    public static List<SVMXC__Service_Order__c> lstWOWithSubscription = new List<SVMXC__Service_Order__c>();
    public static List < SVMXC__Service_Contract__c > lstServiceContract = new List < SVMXC__Service_Contract__c > ();
    public static List<Applied_Contract__c> lstAppliedContractsSortByEndDate = new List<Applied_Contract__c>();
    //CMCM-5307 - End
    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To prepare List of related records before executing any Bussinsess Logic
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public static void insertEntitlementsonWOAfterInsert(List<Sobject> records) {

        Map<Id,SVMXC__Service_Order__c> mapWorkOrdersToBeEntitled = new Map<Id,SVMXC__Service_Order__c>();
        Set<Id> setInstalledProductIds = new Set<Id>();
        Set<Id> setlocationIds = new Set<Id>();
        Set<Id> setServiceContractIds = new Set<Id>();
        List<String> lstFieldAPINames = new List<String>();
        lstFieldAPINames.add(WorkOrders.STRING_INSTALLED_PRODUCT_FIELD_API_NAME);
        lstFieldAPINames.add(WorkOrders.STRING_LOCATION_FIELD_API_NAME);
        List<Applied_Contract__c> lstEntitlement = new List<Applied_Contract__c>();
        Set<Id> woIdSet = new Set<Id>();
        Set<Id> setSubscriptionIds = new Set<Id>();
        Map<Id,SVMXC__Service_Order__c> woIdBYWODetails = new Map<Id,SVMXC__Service_Order__c>();

        for(SVMXC__Service_Order__c woObj : (List<SVMXC__Service_Order__c>)records){
            if(woObj.Subscription__c != null){
                woIdSet.add(woObj.Id);
            }
            
        }
        system.debug('DATA:'+woIdSet+'@@@'+records);
       
        //lstEntitlement = ServiceUtilityCollection.insertEntitlement(mapWorkOrdersToBeEntitled.values(), setInstalledProductIds, setlocationIds, lstFieldAPINames);// point 2 replace setInstalledProductIds with empty set
        
    
        Map < Id, SVMXC__Service_Contract__c > idToServiceContract = new Map < Id, SVMXC__Service_Contract__c > ();

        populateIPsAndLocationIds(records, setInstalledProductIds, setlocationIds, mapWorkOrdersToBeEntitled);// setInstalledProductIds is null in this line for CMCM 7287
        
        //added empty check DCP-33872
        if(!lstEntitlement.isEmpty()) {
            setServiceContractIds = UtilsCollection.getSetOfIds(lstEntitlement, WorkOrders.STRING_SERVICE_CONTRACT_FIELD_API_NAME);
        }
        
        //added empty checks DCP-33872
        // Create Map of Id to Service Contracts which will be used to fetch the fields
        //CMCM-5307 - Add empty check for WO trigger Optimization
        if (!setServiceContractIds.isEmpty() && (lstServiceContract.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization))) {
            lstServiceContract = new ServiceContractSelector().selectServiceContractsByStatus(setServiceContractIds, WorkOrders.STRING_SERVICE_CONTRACT_STATUS_ACTIVE);
        }
        if (!lstServiceContract.isEmpty()) {
            idToServiceContract = new Map < Id, SVMXC__Service_Contract__c > (lstServiceContract);
        }

        if (mapWorkOrdersToBeEntitled!=null && !mapWorkOrdersToBeEntitled.isEmpty()) {
            insertEntitlements(mapWorkOrdersToBeEntitled.values(), false);
        }

        
    }

    /**
    * Description: Inserting the Entitlements when Installed Product is changed on Work Order
    **/
    public static List<Applied_Contract__c> insertEntitlements(List<SVMXC__Service_Order__c> lstWorkOrdersToBeEntitled,boolean isInstallProducChanged) {
     //   Set<Id> setInstalledProductIds = new Set<Id>();
        Set<Id> setlocationIds = new Set<Id>();
     //   Set<Id> setSubscriptionIds = new Set<Id>();
        Map<Id,SVMXC__Service_Order__c> woIdBYWODetails = new Map<Id,SVMXC__Service_Order__c>();
        Map<id,SVMXC__Service_Order__c> idToWorkOrderIPChanged = new Map<id,SVMXC__Service_Order__c>();        
        List<SVMXC__Service_Order__c> lstWorkOrdersToBeEntitledSubset = new List<SVMXC__Service_Order__c>();
        Map<Id,Id> mapOfCaseNWO = new Map<Id,Id>(); // CMCM-8527
        for(SVMXC__Service_Order__c objWorkOrder : lstWorkOrdersToBeEntitled) {
            // INC0538739(CMCM-9 related) Added top level if() condition to skip WO creation for Rapid Account Maintenance(SFM) WOs
            if (objWorkOrder.SVMXC__Order_Type__c != 'Account Maintenance' && objWorkOrder.SVMXC__Order_Type__c != 'Presales') {
                lstWorkOrdersToBeEntitledSubset.add(objWorkOrder);
                if(objWorkOrder.SVMXC__Case__c != null) {
                    mapOfCaseNWO.put(objWorkOrder.SVMXC__Case__c , objWorkOrder.Id);    
                }
            // INC0538739(CMCM-9 related) change end

                if(objWorkOrder.SVMXC__Component__c != null) {
                    //setInstalledProductIds.add(objWorkOrder.SVMXC__Component__c); // Commented by Dhairya shah for CMCM 7287
                    //To find the work orders where installed product is changed
                    idToWorkOrderIPChanged.put(objWorkOrder.id,objWorkOrder);
                }
                if(objWorkOrder.SVMXC__Site__c != null){
                    setlocationIds.add(objWorkOrder.SVMXC__Site__c);
                }
                // Commented by Dhairya shah for CMCM 7287
                /*if(WorkOrders.mapOfSubscription.containsKey(objWorkOrder.Subscription__c) && WorkOrders.mapOfSubscription.get(objWorkOrder.Subscription__c).Status__c == STATUS_ACTIVE) {
                        setSubscriptionIds.add(objWorkOrder.Subscription__c);
                }*/
                woIdBYWODetails.put(objWorkOrder.Id, objWorkOrder);            
            }
        }
        List<String> lstFieldAPINames = new List<String>();
        lstFieldAPINames.add(WorkOrders.STRING_INSTALLED_PRODUCT_FIELD_API_NAME);
        lstFieldAPINames.add(WorkOrders.STRING_LOCATION_FIELD_API_NAME);
        List<Applied_Contract__c> lstEntitlement = new List<Applied_Contract__c>();
        lstEntitlement = ServiceUtilityCollection.insertEntitlement(lstWorkOrdersToBeEntitledSubset, new Set<Id>(), setlocationIds, lstFieldAPINames); // setInstalledProductIds is null in this line for CMCM 7287

        AppliedContracts.isSLATermBlank = false;
        lstEntitlement = getAppliedContractRelatedCase(mapOfCaseNWO , lstEntitlement);
        return lstEntitlement;
    }
    /*
    *  @AUTHOR: Abhishek Yadav
    *  @DESCRIPTION: Link Case Applied Contract with Work Order
    *  @PARAM : Map<Id , Sobject> 
    *  @RETURN:  void
    */
    public static List<Applied_Contract__c> getAppliedContractRelatedCase(Map<Id,Id> mapOfCaseNWO , List<Applied_Contract__c> lstEntitlement) {
        list<Applied_Contract__c> lstCaseEntitlement = new list<Applied_Contract__c>();
        Map<Id,Applied_Contract__c> serviceContractACMap = new Map<Id,Applied_Contract__c>();
        lstCaseEntitlement = new AppliedContractsSelector().selectCaseEntitlements(mapOfCaseNWO.keySet());
        list<Applied_Contract__c> listOfACtobeInserted = new list<Applied_Contract__c>();
        if(lstEntitlement != null && !lstEntitlement.isEmpty()) {
            lstCaseEntitlement.addAll(lstEntitlement);
            for(Applied_Contract__c ac : lstCaseEntitlement) {
                if(!serviceContractACMap.containsKey(ac.Service_Contract__c)) {
                    serviceContractACMap.put(ac.Service_Contract__c , ac);
                }
            }
            if(serviceContractACMap != null) {
                for(Id ap : serviceContractACMap.keySet()) {
                    Applied_Contract__c ac = serviceContractACMap.get(ap);
                    if(ac.Case_Number__c != null && ac.Work_order__c == null) {
                        ac.Work_order__c = mapOfCaseNWO.get(ac.Case_Number__c);
                    }
                    listOfACtobeInserted.add(ac);
                }
            }
        } else {
            for(Applied_Contract__c ap :  lstCaseEntitlement) {
                ap.Work_order__c = mapOfCaseNWO.get(ap.Case_Number__c);
                listOfACtobeInserted.add(ap);
            }
        }
        if(listOfACtobeInserted != null && !listOfACtobeInserted.isEmpty()) {
            upsert listOfACtobeInserted;
        }
        return listOfACtobeInserted;
    }
    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: Work Order Entitlement
    *  @PARAM : Map<Id , Sobject> 
    *  @RETURN:  void
    */
    public static void workOrderEntitlement(Map<Id, SObject> oldRecords, List<Sobject> records) {
        List<SVMXC__Service_Order__c> lstWOToBeEntitled = new List<SVMXC__Service_Order__c>();
        List<Applied_Contract__c> lstEntitlements = new List<Applied_Contract__c>();
            
            for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
                SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)); 

                //CMCM-9 added extra condition in if block (objOldWorkOrder.SVMXC__Company__c != objWorkOrder.SVMXC__Company__c)
                // Commented objOldWorkOrder.Subscription__c checks by Dhairya shah for CMCM 7287
                if (objOldWorkOrder.SVMXC__Site__c != objWorkOrder.SVMXC__Site__c ||  objOldWorkOrder.SVMXC__Company__c != objWorkOrder.SVMXC__Company__c) {
                    lstWOToBeEntitled.add(objWorkOrder);
                }
                if (objOldWorkOrder.ownerId != objWorkOrder.ownerId && objOldWorkOrder.SVMXC__Order_Type__c != null && objWorkOrder.SVMXC__Order_Type__c != null && objOldWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WO_ORDER_TYPE_PM && objOldWorkOrder.SVMXC__Order_Type__c == objWorkOrder.SVMXC__Order_Type__c && objOldWorkOrder.SVMXC__Order_Status__c == 'Initiated') {
                    lstWOToBeEntitled.add(objWorkOrder);
                }
            }

            if (lstWOToBeEntitled!=null && !lstWOToBeEntitled.isEmpty()) {
                try{
                    lstEntitlements = insertEntitlements(lstWOToBeEntitled, true);
                    //update applied contracts && SLA terms fields on work order if the insertion is successful
                    updateWorkOrderFields(lstEntitlements, (List < SVMXC__Service_Order__c > ) records);
                    
                } catch(Exception e) {
                    //catch the exception 
                    ApexExceptions.emit('WorkOrders', e);
                }
            }    
    }

    /**
    *  @description - to be executed in before context of work order class for updateing sla terms and applied contracts fields on work orders. 
    *  @Params: List<Applied_Contract__c> lstAppliedContracts, List<SVMXC__Service_Order__c> newWorkOrders
    *   INC0255552 - changing the return type from void to List<SVMXC__Service_Order__c> to use this method in covered products.
    *  @return : List<SVMXC__Service_Order__c>           
    **/
    public static List<SVMXC__Service_Order__c>  updateWorkOrderFields(List<Applied_Contract__c> lstAppliedContracts, List<SVMXC__Service_Order__c> newWorkOrders) {
        Integer maxLength = 255;
        //map of workorder vs Set of service contract names.
        Map<Id,Set<String>> workOrderIdToServiceContractsNames = new Map<Id,Set<String>>();
        
        Set<Id> setEntitlementIds = new Set<Id>();
        for(Applied_Contract__c ent : lstAppliedContracts){
            setEntitlementIds.add(ent.Id);
        }
        //CMCM-5307 - Add empty check for WO trigger Optimization
        if(!setEntitlementIds.isEmpty() && (lstAppliedContractsSortByEndDate.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization))) {
            //need to put a Query here as records are inserted in the calling method 
            lstAppliedContractsSortByEndDate = new AppliedContractsSelector().selectEntitlementsFromIds(setEntitlementIds);            
        }
        for(Applied_Contract__c contract : lstAppliedContractsSortByEndDate) {
            if(String.isNotBlank(contract.Work_Order__c)){
                
                //populate the map of workorder vs service contracts
                if(!workOrderIdToServiceContractsNames.containsKey(contract.Work_Order__c)) {
                    workOrderIdToServiceContractsNames.put(contract.Work_Order__c, new Set<String>());
                }
                workOrderIdToServiceContractsNames.get(contract.Work_Order__c).add(contract.Service_Contract__r.Name);
            }
                                           
        }
        if(!workOrderIdToServiceContractsNames.isEmpty()) {
            for(SVMXC__Service_Order__c workOrder : newWorkOrders) {
            List<String> lstServiceContractNames = new List<String>(workOrderIdToServiceContractsNames.get(workOrder.Id));
                if(workOrderIdToServiceContractsNames.containsKey(workOrder.Id) && !workOrderIdToServiceContractsNames.get(workOrder.Id).isEmpty()) {
                    updateAppliedContractOnWorkOrder(workOrder,  lstServiceContractNames, maxLength);     
                }    
            }
        }
        return newWorkOrders;

    }

    /*
    *  @AUTHOR: Nancy
    *  @DESCRIPTION: Update Applied Contract Field on WO
    *  @PARAM : SVMXC__Service_Order__c, Set<String>, Integer
    *  @RETURN:  void
    */
    public static void updateAppliedContractOnWorkOrder(SVMXC__Service_Order__c workOrder, List<String> serviceContracts, Integer maxLength) {
        String concatenatedContracts = !serviceContracts.isEmpty() ? String.join(serviceContracts, ',') : null;
        if (concatenatedContracts != null && concatenatedContracts.length() > maxLength) {
            concatenatedContracts = concatenatedContracts.substring(0, maxLength - 11); // 11 is the length of " and more."
            Integer lastCommaIndex = concatenatedContracts.lastIndexOf(',');
            if (lastCommaIndex > 0) {
                concatenatedContracts = concatenatedContracts.substring(0, lastCommaIndex);
            }
            concatenatedContracts += ' and more.';
        }
        // Update the service contract names on the work order                       
        workOrder.Applied_Service_Contract__c = concatenatedContracts;  
    }

    private static void populateIPsAndLocationIds(List<SVMXC__Service_Order__c> records, Set<Id> setInstalledProductIds, Set<Id> setlocationIds, Map<Id,SVMXC__Service_Order__c> mapWorkOrdersToBeEntitled) {
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            //To be executed, when the work order is inserted. Creates Entitlement records
            if( objWorkOrder.SVMXC__Site__c != null || objWorkOrder.SVMXC__Company__c != null) { 
                mapWorkOrdersToBeEntitled.put(objWorkOrder.Id,objWorkOrder);
                
                // Commented by Dhairya shah for CMCM 7287
                /*if(objWorkOrder.SVMXC__Component__c != null) {
                    setInstalledProductIds.add(objWorkOrder.SVMXC__Component__c); // point 3 remove WO IP and Subscription logic 
                }*/
                if(objWorkOrder.SVMXC__Site__c != null) {
                    setlocationIds.add(objWorkOrder.SVMXC__Site__c);
                }
            }
        }
    }
}
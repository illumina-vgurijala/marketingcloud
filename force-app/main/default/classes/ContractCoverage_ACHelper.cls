/**
 *    @author Abhishek Yadav
 *    @date   28-May-2024
 *    @description    Class to get the Entitlement records and update Contract Coverage on Case Object
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Abhishek Yadav             28-May-2024            Initial Version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class ContractCoverage_ACHelper {
    public static final String LOG_TITLE = 'ContractCoverage_ACHelper';
    public static Map<Id,Case> lstCasesToUpdate = new Map<Id,Case>();
    public static String consumableContractId;

    /**
    *  @author Abhishek
    *  @description - Handle Insert/Update Applied contract for Service Covered checkbox
    *  @PARAM :  List<Applied_Contract__c> lstNewCases
    *  @RETURN:  void
    */ 
    public static void handleInsertUpdateServiceCovered(List<sObject> records) {
        ilib_LogEvent.push(LOG_TITLE + '.handleInsertUpdateServiceCovered');
        Set<Id> caseIds = new Set<Id>();
        Set<Id> worOrderIds = new Set<Id>();
        List<Applied_Contract__c> lstCaseEntitlement = new List<Applied_Contract__c>();
        for(Applied_Contract__c objAppliedContract : (List<Applied_Contract__c>)records) {
            if (objAppliedContract.Case_Number__c != null) {
                caseIds.add(objAppliedContract.Case_Number__c);
            }
            if(objAppliedContract.work_order__c != null) {
                worOrderIds.add(objAppliedContract.work_order__c);
            }
        }
        if((caseIds != null && !caseIds.isEmpty()) || (worOrderIds != null && !worOrderIds.isEmpty())) {
            lstCaseEntitlement = new AppliedContractsSelector().selectCaseAndWorkOrderEntitlements(caseIds, worOrderIds); 
        }
        if(lstCaseEntitlement != null && !lstCaseEntitlement.isEmpty()) {
            handleInsertUpdateDeleteServiceCoveredHelper(lstCaseEntitlement);
        }
        ilib_LogEvent.message('caseIds--' + caseIds);
        ilib_LogEvent.message('worOrderIds--' + worOrderIds);
        ilib_LogEvent.message('lstCaseEntitlement--' + lstCaseEntitlement);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *  @author Abhishek
    *  @description - Handle Delete Applied contract for Service Covered checkbox
    *  @PARAM :  List<Applied_Contract__c> lstNewCases
    *  @RETURN:  void
    */
    public static void handleDeleteServiceCovered(List<sObject> records) {
        ilib_LogEvent.push(LOG_TITLE + '.handleDeleteServiceCovered');
        Set<Id> caseIds = new Set<Id>();
        Set<Id> woIds = new Set<Id>();
        List<Applied_Contract__c> lstCaseEntitlement = new List<Applied_Contract__c>();
        for(Applied_Contract__c objAppliedContract : (List<Applied_Contract__c>)records) {
            if (objAppliedContract.Case_Number__c != null) { 
                caseIds.add(objAppliedContract.Case_Number__c);
            }
            if(objAppliedContract.work_order__c != null) {
                woIds.add(objAppliedContract.work_order__c);
            }
        }
        if((caseIds != null && !caseIds.isEmpty()) || (woIds != null && !woIds.isEmpty())) {
            lstCaseEntitlement = new AppliedContractsSelector().selectCaseAndWorkOrderEntitlements(caseIds, woIds); 
        }
        handleDeleteServiceCoveredHelper(lstCaseEntitlement , caseIds , woIds);
        
        ilib_LogEvent.message('lstCaseEntitlement--' + lstCaseEntitlement);
        ilib_LogEvent.message('caseIds--' + caseIds);
        ilib_LogEvent.message('woIds--' + woIds);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    private static void handleDeleteServiceCoveredHelper(List<Applied_Contract__c> lstCaseEntitlement , Set<Id> caseIds , Set<Id> woIds) {
        Set<Id> singleAPCaseIds = new Set<Id>();
        Set<Id> singleAPWOIds = new Set<Id>();
        if(lstCaseEntitlement != null && !lstCaseEntitlement.isEmpty()) {
            for (Applied_Contract__c objcseAC : lstCaseEntitlement) {
                    if(objcseAC.Case_Number__c != null && !caseIds.contains(objcseAC.Case_Number__c)) {
                        singleAPCaseIds.add(objcseAC.Case_Number__c);
                    }
                    if(objcseAC.work_order__c != null && !woIds.contains(objcseAC.work_order__c)) {
                        singleAPWOIds.add(objcseAC.work_order__c);
                    }
            }
            updateSingleAppliedContract(singleAPCaseIds , singleAPWOIds); // update single Applied contract
            handleInsertUpdateDeleteServiceCoveredHelper(lstCaseEntitlement);
        } else {
            updateSingleAppliedContract(caseIds , woIds); // update single Applied contract 
        }
        ilib_LogEvent.message('singleAPCaseIds--' + singleAPCaseIds);
        ilib_LogEvent.message('singleAPWOIds--' + singleAPWOIds);
    }
    /**
    *  @author Abhishek
    *  @description - helper method of handleInsertUpdateDeleteServiceCovered
    *  @PARAM :  List<Applied_Contract__c> lstNewCases
    *  @RETURN:  void
    */ 
    public static void handleInsertUpdateDeleteServiceCoveredHelper(List<Applied_Contract__c> lstCaseEntitlement) {
        Map<Id,Integer> caseNWoEntitlementCount = new Map<Id,Integer>();
        Map<Id,Integer> woEntitlementCount = new Map<Id,Integer>();
        Map<Id,Id> woNCaseIds = new Map<Id,Id>();
        set<Id> woIds = new set<Id>();
        if(consumableContractId == null) {
            consumableContractId = new ServiceUtilityCollection.ServiceSystemUtilityCollection().getConsumbleContract(); 
        }    
        if(lstCaseEntitlement != null && !lstCaseEntitlement.isEmpty()) {
            for (Applied_Contract__c objcseAC : lstCaseEntitlement) {
                // create Map of Install Product , Subscription and Lication Based Applied Contrcat
                if(objcseAC.Service_Contract__c != consumableContractId && objcseAC.Case_Number__c != null) {
                    if(caseNWoEntitlementCount.containsKey(objcseAC.Case_Number__c)) {
                        caseNWoEntitlementCount.put(objcseAC.Case_Number__c , caseNWoEntitlementCount.get(objcseAC.Case_Number__c) + 1);
                    } else if(objcseAC.Service_Contract__c != consumableContractId) {
                        caseNWoEntitlementCount.put(objcseAC.Case_Number__c ,1);
                    }
                }
                if (objcseAC.Service_Contract__c != consumableContractId && objcseAC.work_order__c != null && objcseAC.Applied_Contract_Source__c == 'WO Location/Account') {
                    woIds.add(objcseAC.work_order__c);
                    if(woEntitlementCount.containsKey(objcseAC.work_order__c)) {
                        woEntitlementCount.put(objcseAC.work_order__c , woEntitlementCount.get(objcseAC.work_order__c) + 1);
                    } else if(objcseAC.Service_Contract__c != consumableContractId) {
                        woEntitlementCount.put(objcseAC.work_order__c ,1);
                    }
                }
            }
            woNCaseIds = preparedCaseMap(woIds);
            
        }
        ilib_LogEvent.message('consumableContractId--' + consumableContractId);
        ilib_LogEvent.message('caseNWoEntitlementCount--' + caseNWoEntitlementCount);
        updateCaseRecord(lstCaseEntitlement , caseNWoEntitlementCount , woEntitlementCount , woNCaseIds);
    }
    private static Map<Id,Id> preparedCaseMap(set<Id> woIds) {
        Map<Id,Id> woNCaseIds = new Map<Id,Id>();
        List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
        if (woIds != null && woList.isEmpty()) {
            woList = new WorkOrdersSelector().selectWorkOrderAndCaseInfo(woIds);
        }
        for (SVMXC__Service_Order__c wo : woList) {
            if (wo.SVMXC__Case__c != null) {
                woNCaseIds.put(wo.Id , wo.SVMXC__Case__c);
            }
        }
        return woNCaseIds;
    }
    /**
    *  @author Abhishek
    *  @description - add Case Record data
    *  @PARAM :  Set<Id> singleAppliedContracts
    *  @RETURN:  void
    */
    public static void updateSingleAppliedContract(Set<Id> singleAPCaseIds , Set<Id> singleAPWOIds) {
        List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
        if (singleAPWOIds != null && woList.isEmpty()) {
            woList = new WorkOrdersSelector().selectWorkOrderAndCaseInfo(singleAPWOIds);
        }
        if(singleAPCaseIds != null && !singleAPCaseIds.isEmpty()) {
            for(Id csId : singleAPCaseIds) {
                Case objcs = new Case();
                objcs.Id = csId;
                objcs.SVMXC__Is_Service_Covered__c = false;
                lstCasesToUpdate.put(csId,objcs);
            }
        }
        if(singleAPWOIds != null && !singleAPWOIds.isEmpty()) {
            for (SVMXC__Service_Order__c wo : woList) {
                if(wo.SVMXC__Case__c != null) {
                    Case objcs = new Case();
                    objcs.Id = wo.SVMXC__Case__c;
                    objcs.SVMXC__Is_Service_Covered__c = false;
                    lstCasesToUpdate.put(wo.SVMXC__Case__c,objcs);
                }
            }
        }
        updateCases();
    }
    /**
    *  @author Abhishek
    *  @description - update Case Record
    *  @PARAM :  List<Applied_Contract__c> lstNewCases Map<Id,Integer> caseNEntitlementCount
    *  @RETURN:  void
    */ 
    public static void updateCaseRecord(List<Applied_Contract__c> lstCaseEntitlement , Map<Id,Integer> caseEntitlementCount , Map<Id,Integer> workOrderEntitlementCount , Map<Id,Id> woNCaseIds) {
        if(lstCaseEntitlement != null && !lstCaseEntitlement.isEmpty()) {
            for(Applied_Contract__c objcseAC : lstCaseEntitlement) {
                if(caseEntitlementCount.containsKey(objcseAC.Case_Number__c) && caseEntitlementCount.get(objcseAC.Case_Number__c) > 0) {
                    Case objcs = new Case();
                    objcs.Id = objcseAC.Case_Number__c;
                    objcs.SVMXC__Is_Service_Covered__c = true;
                    lstCasesToUpdate.put(objcs.Id,objcs);
                } else if(woNCaseIds.containskey(objcseAC.work_order__c) && workOrderEntitlementCount.containsKey(objcseAC.work_order__c) && workOrderEntitlementCount.get(objcseAC.work_order__c) > 0) {
                    Case objcs = new Case();
                    objcs.Id = woNCaseIds.get(objcseAC.work_order__c);
                    objcs.SVMXC__Is_Service_Covered__c = true;
                    lstCasesToUpdate.put(objcs.Id,objcs);
                } else if(objcseAC.Case_Number__c != null) {
                    Case objcs = new Case();
                    objcs.Id = objcseAC.Case_Number__c;
                    objcs.SVMXC__Is_Service_Covered__c = false;
                    lstCasesToUpdate.put(objcs.Id,objcs);
                }
            }
        }
        updateCases();
    }
    private static void updateCases() {
        ilib_LogEvent.message('lstCasesToUpdate--' + lstCasesToUpdate);
        if(lstCasesToUpdate != null && !lstCasesToUpdate.isEmpty()) {
            Cases.skipCaseTrigger = True; // Added for CMCM -8242
            update lstCasesToUpdate.values();
        }
    }
    /**
    *  @author Abhishek
    *  @description - update Contract Coverage on case from WO
    *  @PARAM :  List<Applied_Contract__c> lstNewCases Map<Id,Integer> caseNEntitlementCount
    *  @RETURN:  void
    */ 
    public static void handleWOChange(List<sObject> records , Map<Id, SVMXC__Service_Order__c> mapOldCaseRecs) {
        ilib_LogEvent.push(LOG_TITLE + '.handleWOChange');
        Set<Id> caseIds = new Set<Id>();
        Set<Id> worOrderIds = new Set<Id>();
        List<Applied_Contract__c> lstCaseEntitlement = new List<Applied_Contract__c>();
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c oldWO = mapOldCaseRecs.get(objWorkOrder.Id);
            // Case is Linked To Work Order
            if (objWorkOrder.SVMXC__Case__c != null && objWorkOrder.SVMXC__Case__c != oldWO.SVMXC__Case__c) {
                caseIds.add(objWorkOrder.SVMXC__Case__c);
                worOrderIds.add(objWorkOrder.Id);
            }
             // Case is unLink To Work Order
            if (String.isEmpty(objWorkOrder.SVMXC__Case__c) && objWorkOrder.SVMXC__Case__c != oldWO.SVMXC__Case__c) {
                caseIds.add(oldWO.SVMXC__Case__c);
            }
        }
        ilib_LogEvent.message('caseIds--' + caseIds);
        ilib_LogEvent.message('worOrderIds--' + worOrderIds);
        if((caseIds != null && !caseIds.isEmpty()) || (worOrderIds != null && !worOrderIds.isEmpty())) {
            lstCaseEntitlement = new AppliedContractsSelector().selectCaseAndWorkOrderEntitlements(caseIds, worOrderIds); 
        }
        if(lstCaseEntitlement != null || caseIds != null) {
            handleWOChangeHelper(lstCaseEntitlement , caseIds);
        }
    }
    private static void handleWOChangeHelper(List<Applied_Contract__c> lstCaseEntitlement , Set<Id> caseIds) {
        Map<Id,Case> casesToUpdate = new Map<Id,Case>();
        if(lstCaseEntitlement != null && !lstCaseEntitlement.isEmpty()) {
            handleInsertUpdateDeleteServiceCoveredHelper(lstCaseEntitlement);
        } else {
            for(Id cs : caseIds) {
                Case objCase = new Case();
                objCase.Id = cs;
                objCase.SVMXC__Is_Service_Covered__c = false;
                casesToUpdate.put(cs , objCase);
            }
        }
        if(casesToUpdate != null && !casesToUpdate.isEmpty()) {
            Cases.skipCaseTrigger = true;
            update casesToUpdate.values();
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}
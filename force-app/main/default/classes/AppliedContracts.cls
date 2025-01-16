/***************************************************************************************************************************************
* NAME   : AppliedContracts
* DESCRIPTION  : Domain class for EntitlementTrigger.
*                    
* @AUTHOR : Mandeep Singh
* @DATE   : 13-Sep-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Mandeep               13-Sep-2018          Initial Version. Added logic to populate SLA term on work orders.
* Shivani Jain          29 Nov 2021          DCP-42926 Parts Order Lines Optimization
* Biswajeet Sahoo       04 July 2022         CMSI-94 Instrumnentation of class
* Abhishek Yadav        29 May 2024          Implemented CMCM-7411 & Refector Code
***************************************************************************************************************************************/ 
public with sharing class AppliedContracts extends ilib_SObjectDomain
{
	public static final string FLDWORKORDER = 'work_order__c';
	public static Boolean isSLATermBlank = true;
    public static final String LOG_TITLE = 'AppliedContracts';
    //List of Parts Order Lines
    public static List<SVMXC__RMA_Shipment_Line__c> lstPOL = new List<SVMXC__RMA_Shipment_Line__c>();
    public static  Boolean isTestRunning = false;
	
    // AfterInsert variables
	public static List<SVMXC__Service_Order__c> listWOToUpdate = new List<SVMXC__Service_Order__c>();
    public static Map<Id,Id> mapWorkOrderToSLATerm = new Map<Id,Id>();
    public static Map<Id,SVMXC__Service_Order__c> mapIdToWorkOrder = new Map<Id,SVMXC__Service_Order__c>();
    public static Set <Id> setServiceContractId = new Set<Id>();
    public static Set<Id> setWOIds = new Set<Id>();
    // Map of service Contract TO List of Service Covered Product
    public static Map<Id,List<SVMXC__Service_Contract_Products__c>> mapsrvcContrctIdToLstCovrdProduct = new Map<Id,List<SVMXC__Service_Contract_Products__c>>();
    public static List<Applied_Contract__c> lstAppliedContracts = new List<Applied_Contract__c>();
	/*
    * Constructor
    */
    public AppliedContracts(List<Applied_Contract__c> sObjectList) {
        super(sObjectList);
        //Added by Dhairya Shah for CMCM - 9205
        Configuration.disableTriggerCRUDSecurity();
        ilib_SecurityUtils.bypassInternalFlsAndCrud = true;    
    }

    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new AppliedContracts(sObjectList);
        }
    }

    
    /**
    *  @author Mandeep Singh
    *  @description - To be executed, when the entitlement is inserted. 
    *               1. Checks if work order is created, update the Work Order status on Case.
    *               2. Creates Entitlement records
    **/
    public override void onAfterInsert() {
        Set<Id> setEntitlementIds = new Set<Id>();

        for(Applied_Contract__c ent : (List<Applied_Contract__c>)records){
            setEntitlementIds.add(ent.Id);
        }
        ilib_LogEvent.info('setEntitlementIds :'+setEntitlementIds);  //CMSI-94    
		
       if(!setEntitlementIds.isEmpty()){ 
            lstAppliedContracts =  new AppliedContractsSelector().selectEntitlementsFromIds(setEntitlementIds);
        }
		
        if(lstAppliedContracts != null && !lstAppliedContracts.isEmpty()) {
            ilib_LogEvent.info('lstAppliedContracts :'+UtilsCollection.getSetOfIds(lstAppliedContracts)); //CMSI-94
            updateWorkdetails(lstAppliedContracts);
            updatePOL(lstAppliedContracts);
        }
        ContractCoverage_ACHelper.handleInsertUpdateServiceCovered(records);   
    }
    /*
     * Description - onAfterUpdate method
	 * return - void
     */
    public override void onAfterUpdate(Map<Id, SObject> mapOld) {  
        ContractCoverage_ACHelper.handleInsertUpdateServiceCovered(records);
    }
    /*
     * Description - onAfterDelete method
	 * return - void
     */
    public override void onAfterDelete() {
        ContractCoverage_ACHelper.handleDeleteServiceCovered(records);
    }
    
    /**
    *  @description - To be executed, when the entitlement is inserted and updates the ERP header and line number on work detail. 
    *  @Params: List<Applied_Contract__c> lstAppliedContracts
    *  @return : void          
    **/
    public void updateWorkdetails(List<Applied_Contract__c> lstAppliedContracts){
        ilib_LogEvent.push(LOG_TITLE +'.updateWorkdetails'); //CMSI-94
        ilib_LogEvent.info('lstAppliedContracts :'+UtilsCollection.getSetOfIds(lstAppliedContracts)); //CMSI-94
        //set work order Ids
        Set<Id> setWOId = UtilsCollection.getSetOfIds(lstAppliedContracts, FLDWORKORDER);
		
        if(!setWOId.isEmpty()){
            //List of work details with blank contracts header & contract line number for the given work orders.
            List<SVMXC__Service_Order_Line__c> lstWorkDetails = new WorkDetailsSelector().selectBlankContractWorkDetailsByWorkOrderId(setWOId);
            if(!lstWorkDetails.isEmpty()){
                UpdateContract_WorkDetailHelper.updateContractOnWD(lstWorkDetails, false, true,lstAppliedContracts);
            }                
        }
        ilib_LogEvent.pop(); //CMSI-94
        
    }
    /**
    *  @description - To be executed when the entitlement is inserted. It updates the ERP header and line number on partsorder line. 
    *  @Params: List<Applied_Contract__c> lstAppliedContracts
    *  @return : void          
    **/
    public void updatePOL(List<Applied_Contract__c> lstAppliedContracts){
        ilib_LogEvent.push(LOG_TITLE +'.updatePOL'); //CMSI-94
        ilib_LogEvent.info('lstAppliedContracts :'+UtilsCollection.getSetOfIds(lstAppliedContracts)); //CMSI-94
        //set of work orders
        Set<Id> setWOId = UtilsCollection.getSetOfIds(lstAppliedContracts, FLDWORKORDER);      
        
        //populate the parts order lines list.
        if(!setWOId.isEmpty()){
            ilib_LogEvent.info('Set of WO Ids :'+setWOId);  
            Set<String> setStatuses = new Set<String>{'Open', 'On Hold'};
            //CMCM - 7787 Added an empty check for lstPOL
            if(lstPOL == null || lstPOL.isEmpty() || isTestRunning) {
                lstPOL = new PartsOrderLineSelector().selectBlankContractPOLsByWorkOrderId(setWOId,setStatuses);
            }
			if(!lstPOL.isEmpty()){
				//START - DCP-42926
                //new PartsOrderLines(lstPOL).updateContractOnPOL(lstPOL, true, lstAppliedContracts);
                UpdateContract_POLHelper.updateContractOnPOL(lstPOL, true, lstAppliedContracts);
                //END - DCP-42926
			}
        }
        ilib_LogEvent.pop(); //CMSI-94
    }

     /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }
}
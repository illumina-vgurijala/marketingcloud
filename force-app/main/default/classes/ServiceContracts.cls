/***************************************************************************************************************************************
* NAME   : ServiceContracts
* DESCRIPTION  : Domain class for ServiceContractTrigger.
*                    
* @AUTHOR : Shashank Singhal
* @DATE   : 13-September-2018  
* Test class for 75%: TestAgreementValidation_POLHelper,TestBatchUpdateCaseStatus, TestCheckDCIR_POLHelper, TestCheckLinkedrecord_POLHelper, TestCoveredProductsQueueable,
                      TestPartsOrderLineSelector, TestPopulateLastPMDateOnIP, TestServiceContracts, TestSwapProcessOnLineItems_POLHelper, TestUpdatePendingReview_POLHelper
* Test class for 90%: TestAgreementValidation_POLHelper,TestBatchUpdateCaseStatus, TestCheckDCIR_POLHelper, TestCheckLinkedrecord_POLHelper, TestCoveredProductsQueueable,
                      TestPartsOrderLineSelector, TestPopulateLastPMDateOnIP, TestServiceContracts, TestSwapProcessOnLineItems_POLHelper, TestUpdatePendingReview_POLHelper
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shashank               13-Sept-2018          Initial Version. 
* Naomi                  16-Oct-2019           Added logic to make PM Plans Suspended for blocked contracts
* Nitin                  31-Aug-2022           CMSI-222 Instrumentation 
* Dhairya Shah       11-Oct-2024             CMCM-5165      
****************************************************************************************************************************************/ 

public with sharing class ServiceContracts extends ilib_SObjectDomain {
	
    public static final string STRING_SERVICE_CONTRACT_STATUS_CANCELED = 'Canceled';
    public static final string STRING_SERVICE_CONTRACT_STATUS_BLOCKED = 'Blocked';
    public static final string STRING_SERVICE_CONTRACT_STATUS_ACTIVE = 'Active';
    public static final string STRING_SERVICE_CONTRACT_STATUS_PENDING_ACTIVATION = 'Pending Activation';
    public static final string STRING_SERVICE_CONTRACT_STATUS_EXPIRED = 'Expired';
    public static final string STRING_SERVICE_CONTRACT_STATUS_DRAFT = 'Draft';
    public static final string STRING_PM_PLAN_STATUS_CANCELED ='Canceled';
    public static final string STRING_PM_PLAN_STATUS_ACTIVE ='Active';
	//DCP-42827
	public static final string STRING_PM_WO_CANCELLATION_MESSAGE = 'Work order cancelled by system due to service contract cancellation.';
    private static final String LOG_TITLE = 'ServiceContracts';
    public static final String NULLSTR = 'Null';
    public static Map<id,SVMXC__Service_Plan__c> servicePlanMap = new Map<id,SVMXC__Service_Plan__c>();
	
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public ServiceContracts(List<SVMXC__Service_Contract__c> sObjectList)
    {
        super(sObjectList);
    }
    
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * Boilerplate which is required for base class instantiation logic
        */    
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ServiceContracts(sObjectList);
        }
    }
    /**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Service Contract is inserted. 
    **/
    public override void onBeforeInsert(){
        //INC0312950
        Set<Id> setAccountIds = new Set<Id>();
        //Iterate over the service contract records
        for(SVMXC__Service_Contract__c objServiceContract:(List<SVMXC__Service_Contract__c>)records){
            if((objServiceContract.Status__c != STRING_SERVICE_CONTRACT_STATUS_CANCELED || objServiceContract.Pending_Cancellation__c) 
               && objServiceContract.Status__c != STRING_SERVICE_CONTRACT_STATUS_BLOCKED){
                   //set the status
                   objServiceContract.Status__c = getServiceContractStatus(objServiceContract);
               }
            //INC0312950
            if(objServiceContract.SVMXC__Company__c != null){
                setAccountIds.add(objServiceContract.SVMXC__Company__c);
            }
        }
        ilib_LogEvent.info('setAccountIds : '+setAccountIds);
        //INC0312950
        if(!setAccountIds.isEmpty()){
            updateAccountRegion(setAccountIds, records);
        }
        boolean isInsert = true;
        updateServiceContractfields(records,null,isInsert);
    }
    /**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Service Contract is updated. 
    **/
    public override void onBeforeUpdate(Map<Id, sObject> oldRecords){
        //Iterate over the service contract records
        for(SVMXC__Service_Contract__c objServiceContract:(List<SVMXC__Service_Contract__c>)records){
            SVMXC__Service_Contract__c objOldServiceContract = (SVMXC__Service_Contract__c)oldRecords.get(objServiceContract.Id);
            if((objServiceContract.Status__c != STRING_SERVICE_CONTRACT_STATUS_CANCELED || objServiceContract.Pending_Cancellation__c) 
               && objServiceContract.Status__c != STRING_SERVICE_CONTRACT_STATUS_BLOCKED
               && (objServiceContract.SVMXC__Start_Date__c != objOldServiceContract.SVMXC__Start_Date__c
                   || objServiceContract.SVMXC__End_Date__c != objOldServiceContract.SVMXC__End_Date__c)){
                   //set the status
                       objServiceContract.Status__c = getServiceContractStatus(objServiceContract);
               }
        }
        boolean isInsert = false;
        updateServiceContractfields(records,oldRecords,isInsert);
    }
    /**
    * Method:updateAccountRegion
    * Description: POpulates Region from Account-INC0312950
    * params: Set<Id>, List<sObject>
    * return: void
    */
    public static void updateAccountRegion(Set<Id> setAccountIds, List<sObject> records){
        ilib_LogEvent.push(LOG_TITLE+'.updateAccountRegion()');
        Map<Id, Account> mapAccounts = new Map<Id, Account>(new AccountsSelector().getAccountsTerritories(setAccountIds));
        for(SVMXC__Service_Contract__c contract : (List<SVMXC__Service_Contract__c>)records){
            if(contract.SVMXC__Company__c != null && mapAccounts.containsKey(contract.SVMXC__Company__c) && mapAccounts.get(contract.SVMXC__Company__c) != null){
                contract.Region__c = mapAccounts.get(contract.SVMXC__Company__c).Territory_Region__c;
                ilib_LogEvent.message('contract.Region__c : '+contract.Region__c);
            }
        }
        ilib_LogEvent.pop();
    }
    /**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Service Contract is updated. 
    **/
    public override void onAfterUpdate(Map<Id, sObject> oldRecords){
        set<Id> setServiceContractIds = new set<Id>();
        set<Id> setInstalledProductIds = new set<Id>();
		Set<Id> setServicePlanId = new Set<Id>();
        Set<SVMXC__Service_Contract__c> setSMC = new Set<SVMXC__Service_Contract__c>();
		//DCP-28624
		List<SVMXC__Service_Contract__c> lstServiceContracts=new List<SVMXC__Service_Contract__c>();
        Set<Id> setSMCId = new Set<Id>();
        		
        //Iterate over the service contract records
        for(SVMXC__Service_Contract__c objServiceContract:(List<SVMXC__Service_Contract__c>)records){
            SVMXC__Service_Contract__c objOldServiceContract = (SVMXC__Service_Contract__c)oldRecords.get(objServiceContract.Id);
			//DCP-28624
			if(objServiceContract.Status__c!=objOldServiceContract.Status__c && objServiceContract.Status__c==STRING_SERVICE_CONTRACT_STATUS_CANCELED){
                lstServiceContracts.add(objServiceContract);
               
            }
            if(objServiceContract.Status__c != objOldServiceContract.Status__c
               || objServiceContract.SVMXC__Start_Date__c != objOldServiceContract.SVMXC__Start_Date__c
               || objServiceContract.SVMXC__End_Date__c != objOldServiceContract.SVMXC__End_Date__c){
                   setServiceContractIds.add(objServiceContract.Id);
               }
			   if(objServiceContract.SVMXC__Service_Plan__c!=null&&objServiceContract.SVMXC__Service_Plan__c!=objOldServiceContract.SVMXC__Service_Plan__c){
				setServicePlanId.add(objServiceContract.SVMXC__Service_Plan__c);
				setSMC.add(objServiceContract);
				setSMCId.add(objServiceContract.Id);
			}
	       
        }
        ilib_LogEvent.info('setServiceContractIds : '+setServiceContractIds);
        ilib_LogEvent.info('setInstalledProductIds : '+setInstalledProductIds);
        ilib_LogEvent.info('setServicePlanId : '+setServicePlanId);
        ilib_LogEvent.info('setSMC : '+setSMC);
        ilib_LogEvent.info('setSMCId : '+setSMCId);
        
        if(!setServiceContractIds.isEmpty()){
            for(SVMXC__Service_Contract_Products__c objCoveredProduct:new CoveredProductSelector().selectCoveredProductsForServiceContracts(setServiceContractIds)){
                if(objCoveredProduct.SVMXC__Installed_Product__c != null)
                	setInstalledProductIds.add(objCoveredProduct.SVMXC__Installed_Product__c);
            }
        }
		
        if(!setInstalledProductIds.isEmpty()){
            ServiceUtilityCollection.updateCurrentActiveContractOnIP(setInstalledProductIds);
            ServiceUtilityCollection.updateLatestExpiringContractOnIP(setInstalledProductIds);
        }
		// calling create pm offering method
		if(!(setServicePlanId.isEmpty()&& setSMC.isEmpty()&& setSMCId.isEmpty())){
		    createPMOffering(setServicePlanId,setSMC,setSMCId,false);
	    }
		 //DCP-28624
		 if(lstServiceContracts!=null && !lstServiceContracts.isEmpty()){
           updaterelatedPMWorkOrder(lstServiceContracts);
         }
    }
     /**
    *  @author Sandeep Ram Ch.
    *  @description :- be executed, when the SMC is inserted. 
    **/
    public override void onAfterInsert(){
	    Set<Id> setServicePlanId = new Set<Id>();
        Set<SVMXC__Service_Contract__c> setServiceContract = new Set<SVMXC__Service_Contract__c>();
		Set<Id> setServiceContractId = new Set<Id>();
		//Map<Id,SVMXC__PM_Offering__c> IdToObjPMOfferings = new Map<Id,SVMXC__PM_Offering__c>();
		

		for(SVMXC__Service_Contract__c objServiceContract:(List<SVMXC__Service_Contract__c>)records){
			if(objServiceContract.SVMXC__Service_Plan__c!=null){
				setServicePlanId.add(objServiceContract.SVMXC__Service_Plan__c);
				setServiceContract.add(objServiceContract);
				setServiceContractId.add(objServiceContract.Id);
			}
			
 
		}
        ilib_LogEvent.info('setServicePlanId : '+setServicePlanId);
        ilib_LogEvent.info('setServiceContract : '+setServiceContract);
        ilib_LogEvent.info('setServiceContractId : '+setServiceContractId);
          // calling create pm offering method
	if(!(setServicePlanId.isEmpty()&& setServiceContract.isEmpty()&& setServiceContractId.isEmpty())){
		createPMOffering(setServicePlanId,setServiceContract,setServiceContractId,true);
	    
	}
    
    }
    /*
    *  @AUTHOR:  Shashank Singhal 
    *  @DESCRIPTION: get the status for Service contract based on the Start and End dates for DCP-9448
    *  @PARAM :  SVMXC__Service_Contract__c objServiceContract
    *  @RETURN:  string
    */
    private static string getServiceContractStatus(SVMXC__Service_Contract__c objServiceContract){
        string strStatus = STRING_SERVICE_CONTRACT_STATUS_DRAFT;
        if(objServiceContract.SVMXC__Start_Date__c == objServiceContract.SVMXC__End_Date__c){
            strStatus = STRING_SERVICE_CONTRACT_STATUS_EXPIRED;
        }else if(objServiceContract.SVMXC__Start_Date__c <= system.today() && objServiceContract.SVMXC__End_Date__c >= system.today()){
            strStatus = STRING_SERVICE_CONTRACT_STATUS_ACTIVE;
        }else if(objServiceContract.SVMXC__Start_Date__c > system.today()){
            strStatus = STRING_SERVICE_CONTRACT_STATUS_PENDING_ACTIVATION;
        }else if(objServiceContract.SVMXC__End_Date__c < system.today()){
            strStatus = STRING_SERVICE_CONTRACT_STATUS_EXPIRED;   
        }
        ilib_LogEvent.message('strStatus : '+strStatus);
        return strStatus;
    }
    
     /*
    *  @AUTHOR: Sandeep Ram Ch.
    *  @DESCRIPTION: to create pm offerings 
    *  @PARAM :  Set<Id> setServicePlanId,Set<SVMXC__Service_Contract__c> setServiceContract,Set<Id> setServiceContractId,Boolean newRecord
    *  @RETURN:  void
    */
private static void createPMOffering(Set<Id> setServicePlanId,Set<SVMXC__Service_Contract__c> setServiceContract,Set<Id> setServiceContractId,Boolean newRecord){
    ilib_LogEvent.push(LOG_TITLE+'.createPMOffering()');
    // List to hold insert and delete pm offering and pm plan records
    List<SVMXC__PM_Offering__c> lstPMOfferingsInsert= new List<SVMXC__PM_Offering__c>();
	//List<SVMXC__PM_Plan__c> lstPMPlanDelete= new List<SVMXC__PM_Plan__c>();
	List<SVMXC__PM_Plan__c> lstPMPlanUpdate= new List<SVMXC__PM_Plan__c>();
	List<SVMXC__PM_Offering__c> lstPMOfferingsDelete= new List<SVMXC__PM_Offering__c>();
    //Map with smc id and list of pm offering assoicated to it
    Map<Id,List<SVMXC__PM_Offering__c>> idObjSMCToLstObjPMOfferings =new  Map<Id,List<SVMXC__PM_Offering__c>>();
    //Map with service plan id and list of pm offering assoicated to it
    Map<Id,List<SVMXC__PM_Offering__c>> idToLstObjPMOfferings =new  Map<Id,List<SVMXC__PM_Offering__c>>();
    //Map with smc id and list of pm plans
	Map<Id,List<SVMXC__PM_Plan__c>> idToLstObjPMPlan = new Map<Id,List<SVMXC__PM_Plan__c>>();
	    // building map service plan id and list of pm offering assoicated to it
        for(SVMXC__PM_Offering__c objPMOfferings : new PMOfferingsSelector().selectPMOfferingsForServicePlan(setServicePlanId)){
		 if(!idToLstObjPMOfferings.isEmpty() &&idToLstObjPMOfferings.containsKey(objPMOfferings.SVMXC__Service_Plan__c)){
		    List<SVMXC__PM_Offering__c> lstObjPMOfferings = idToLstObjPMOfferings.get(objPMOfferings.SVMXC__Service_Plan__c);
             lstObjPMOfferings.add(objPMOfferings);
             idToLstObjPMOfferings.put(objPMOfferings.SVMXC__Service_Plan__c,lstObjPMOfferings);
		 }
		 else{ 
		  idToLstObjPMOfferings.put(objPMOfferings.SVMXC__Service_Plan__c,new List<SVMXC__PM_Offering__c>{objPMOfferings});
		 }
	}
    ilib_LogEvent.info('idToLstObjPMOfferings : '+(idToLstObjPMOfferings != Null ? String.valueof(idToLstObjPMOfferings.keySet()):NULLSTR));
    // builiding smc id and list of pm offering assoicated to it
	for(SVMXC__PM_Offering__c objPMOfferings: new PMOfferingsSelector().selectPMOfferingsForSMC(setServiceContractId)){
		if(!idObjSMCToLstObjPMOfferings.isEmpty() &&idObjSMCToLstObjPMOfferings.containsKey(objPMOfferings.SVMXC__Service_Contract__c)){
			 List<SVMXC__PM_Offering__c> lstObjPMOfferings = idObjSMCToLstObjPMOfferings.get(objPMOfferings.SVMXC__Service_Contract__c);
             lstObjPMOfferings.add(objPMOfferings);
             idObjSMCToLstObjPMOfferings.put(objPMOfferings.SVMXC__Service_Contract__c,lstObjPMOfferings); 
        }
		 else{ 
		  idObjSMCToLstObjPMOfferings.put(objPMOfferings.SVMXC__Service_Contract__c,new List<SVMXC__PM_Offering__c>{objPMOfferings});
		 }
	}
    ilib_LogEvent.info('idObjSMCToLstObjPMOfferings : '+(idObjSMCToLstObjPMOfferings != Null ? String.valueof(idObjSMCToLstObjPMOfferings.keySet()):NULLSTR));
	//builiding smc id and list of pm plans
	for(SVMXC__PM_Plan__c objPMPlan : new PreventiveMaintenancePlansSelector().selectPMPlanForSMC(setServiceContractId)){
		
		if(idToLstObjPMPlan!=null&&!idToLstObjPMPlan.isEmpty() &&idToLstObjPMPlan.containsKey(objPMPlan.SVMXC__Service_Contract__c)){
			List<SVMXC__PM_Plan__c> lstObjPMPlan = idToLstObjPMPlan.get(objPMPlan.SVMXC__Service_Contract__c);
             lstObjPMPlan.add(objPMPlan);
		     idToLstObjPMPlan.put(objPMPlan.SVMXC__Service_Contract__c,lstObjPMPlan);
		}
		else{
			
			idToLstObjPMPlan.put(objPMPlan.SVMXC__Service_Contract__c,new List<SVMXC__PM_Plan__c>{objPMPlan});
		}
	}
    ilib_LogEvent.info('idToLstObjPMPlan : '+(idToLstObjPMPlan != Null ? String.valueof(idToLstObjPMPlan.keySet()):NULLSTR));
	for(SVMXC__Service_Contract__c objServiceContract: setServiceContract){
          // inserting pm offering to smc from sp
	    if(idToLstObjPMOfferings!=null&&!idToLstObjPMOfferings.isEmpty()&&newRecord&&idToLstObjPMOfferings.containsKey(objServiceContract.SVMXC__Service_Plan__c)){
		   for(SVMXC__PM_Offering__c objPMOfferings : idToLstObjPMOfferings.get(objServiceContract.SVMXC__Service_Plan__c)){
			   SVMXC__PM_Offering__c objPMOffering = new SVMXC__PM_Offering__c();
			objPMOffering.SVMXC__Service_Contract__c = objServiceContract.Id;
			objPMOffering.SVMXC__PM_Plan_Template__c= objPMOfferings.SVMXC__PM_Plan_Template__c;
			lstPMOfferingsInsert.add(objPMOffering);
			}
        }
        // execute when sp is update on smc
		if(idToLstObjPMOfferings!=null&&!idToLstObjPMOfferings.isEmpty()&&idObjSMCToLstObjPMOfferings!=null&&!newRecord&&idToLstObjPMOfferings.containsKey(objServiceContract.SVMXC__Service_Plan__c)){
			for(SVMXC__PM_Offering__c objPMOfferings : idToLstObjPMOfferings.get(objServiceContract.SVMXC__Service_Plan__c)){
			    SVMXC__PM_Offering__c objPMOffering = new SVMXC__PM_Offering__c();
				objPMOffering.SVMXC__Service_Contract__c = objServiceContract.Id;
				objPMOffering.SVMXC__PM_Plan_Template__c= objPMOfferings.SVMXC__PM_Plan_Template__c;
				// inserting new pm offerings to smc
                lstPMOfferingsInsert.add(objPMOffering);
			 }
            // removing pm offering of the old sp
			if(!idObjSMCToLstObjPMOfferings.isEmpty()&&idObjSMCToLstObjPMOfferings.containsKey(objServiceContract.Id)){
			for(SVMXC__PM_Offering__c objPMofferings :idObjSMCToLstObjPMOfferings.get(objServiceContract.Id)){
				lstPMOfferingsDelete.add(objPMOfferings);
            }
			}
            // Updating pm plans for the given smc
			if(idToLstObjPMPlan!=null&&!idToLstObjPMPlan.isEmpty()&&idToLstObjPMPlan.containsKey(objServiceContract.Id)){
			for(SVMXC__PM_Plan__c objPMPlan:idToLstObjPMPlan.get(objServiceContract.Id)){
				//lstPMPlanDelete.add(objPMPlan);
				objPMPlan.SVMXC__Status__c=STRING_PM_PLAN_STATUS_CANCELED;
                lstPMPlanUpdate.add(objPMPlan);
			}
			
            }
		}
		
		
		
	}
	 // inserting of pm offerings
	 if(!lstPMOfferingsInsert.isEmpty()){
	insert lstPMOfferingsInsert;
    ilib_LogEvent.info('lstPMOfferingsInsert : '+UtilsCollection.getSetOfIds(lstPMOfferingsInsert));
	 }
    // deleting of pm offerings
	 if(!lstPMOfferingsDelete.isEmpty()){
	 Delete lstPMOfferingsDelete;
	 }
    // deleting of pm plans
	 /*if(!lstPMPlanDelete.isEmpty()){
	 Delete lstPMPlanDelete; 
	 } */
	 // updating of pm plans
	 if(!lstPMPlanUpdate.isEmpty()){
	 Update lstPMPlanUpdate; 
	 }
     ilib_LogEvent.pop();
	}

	
	  /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: to cancel Work Orders if the Contract is Cancelled 
    *  @PARAM :  List<SVMXC__Service_Contract__c> lstServiceContracts
    *  @RETURN:  void
    */
  
  public void updaterelatedPMWorkOrder( List<SVMXC__Service_Contract__c> lstServiceContracts){
       ilib_LogEvent.push(LOG_TITLE+'.updaterelatedPMWorkOrder()');
       set<id> setServiceContractIds = new set<Id>();
       List<SVMXC__Service_Order__c> lstWOtoBeUpdated=new List<SVMXC__Service_Order__c>();
       Map<id, SVMXC__Service_Order__c> mapWorkOrder=new Map<id,SVMXC__Service_Order__c>();
       Map<id ,List<SVMXC__Service_Order_Line__c>> mapWorkOrdertoWorkdetails=new Map<id ,List<SVMXC__Service_Order_Line__c>>();
       Map<id ,List<SVMXC__RMA_Shipment_Order__c>> mapWorkOrdertoPartOrders=new Map<id ,List<SVMXC__RMA_Shipment_Order__c>>();
       set<Id> setWoIds=new set<Id>();
   
       for(SVMXC__Service_Contract__c obj : lstServiceContracts){
            setServiceContractIds.add(obj.id);
       }
       
       ilib_LogEvent.info('setServiceContractIds : '+setServiceContractIds);
       //Fetch related Applied Contracts 
         if(setServiceContractIds!=null && !setServiceContractIds.IsEmpty()){
            for(Applied_Contract__c obj: new AppliedContractsSelector().selectEntitlementsFromSMCIds(setServiceContractIds)){
               if(obj.Work_order__r.SVMXC__Order_Type__c==Label.WorkOrderTypePreventativeMaintenance && obj.Work_order__r.SVMXC__Order_Status__c != Label.WorkOrderStatusCanceled)
                   setWOIds.add(obj.Work_order__c);
            }
         }
         ilib_LogEvent.info('setWOIds : '+setWOIds);
         for(SVMXC__Service_Order__c obj: new WorkOrdersSelector().selectWorkOrdersWithoutCasesFromIds(setWOIds)){ //INC0370929
            if(obj.SVMXC__Billing_Type__c != WorkOrders.STRING_LABEL_BILLABLE){
                mapWorkOrder.put(obj.id,obj);
            }
        }

        for(Applied_Contract__c obj: new AppliedContractsSelector().selectActiveEntitlementsFromWO(setServiceContractIds,setWOIds)){
            if(mapWorkOrder.containskey(obj.Work_order__c)){
                mapWorkOrder.remove(obj.Work_order__c);
            }
        }
        ilib_LogEvent.info('mapWorkOrder : '+(mapWorkOrder != Null ? String.valueof(mapWorkOrder.keySet()):NULLSTR));
         //Fetch Associated Parts Orders    
         for(SVMXC__RMA_Shipment_Order__c obj : new PartsOrdersSelector().selectPartsOrdersOnWorkOrders(mapWorkOrder.keySet())){
         if(obj!=null){
            if(mapWorkOrdertoPartOrders.get(obj.SVMXC__Service_Order__c)==null)
                mapWorkOrdertoPartOrders.put(obj.SVMXC__Service_Order__c,new List<SVMXC__RMA_Shipment_Order__c>());
                
              mapWorkOrdertoPartOrders.get(obj.SVMXC__Service_Order__c).add(obj);
            }
         }
         ilib_LogEvent.info('mapWorkOrdertoPartOrders : '+(mapWorkOrdertoPartOrders != Null ? String.valueof(mapWorkOrdertoPartOrders.keySet()):NULLSTR));
         //Fetch Associated Work Details 
         for(SVMXC__Service_Order_Line__c obj : new WorkDetailsSelector().selectWorkDetailsForWorkOrderId(mapWorkOrder.keySet())){
         if(obj!=null){
            if(mapWorkOrdertoWorkdetails.get(obj.SVMXC__Service_Order__c)==null)
                mapWorkOrdertoWorkdetails.put(obj.SVMXC__Service_Order__c,new List<SVMXC__Service_Order_Line__c>());
                
            mapWorkOrdertoWorkdetails.get(obj.SVMXC__Service_Order__c).add(obj);
            }
         }
         ilib_LogEvent.info('mapWorkOrdertoWorkdetails : '+(mapWorkOrdertoWorkdetails != Null ? String.valueof(mapWorkOrdertoWorkdetails.keySet()):NULLSTR));
         // Set Work Order status to Canceled if no PO and WO are associated
         for(id objId :mapWorkOrder.keySet()){
           
            if(mapWorkOrder.get(objId).SVMXC__Order_Status__c!=Label.WorkOrderStatusClosed && mapWorkOrder.get(objId).SVMXC__Order_Status__c!=Label.WorkOrderStatusCompleted && mapWorkOrder.get(objId).SVMXC__Order_Status__c!=Label.WorkOrderStatusTechnicianOnsite ){
            if(mapWorkOrdertoWorkdetails.get(objId)==null && mapWorkOrdertoPartOrders.get(objId)==null ){
                  //DCP-42827
                	SVMXC__Service_Order__c objWO = mapWorkOrder.get(objId);
                   	objWO.SVMXC__Order_Status__c=Label.WorkOrderStatusCanceled ;
                    // Added field by Dhairya for CMCM - 5165
                    objWO.Notes__c = objWO.Notes__c != null ? objWO.Notes__c+' : '+STRING_PM_WO_CANCELLATION_MESSAGE : STRING_PM_WO_CANCELLATION_MESSAGE;
                	ilib_LogEvent.message('objWO : '+objWO);
                  lstWOtoBeUpdated.add(objWO);
               }
           }
           
         }
     
         if(lstWOtoBeUpdated!=null && !lstWOtoBeUpdated.IsEmpty()) {
            //PRB0050214 Added for Contract Sync issue fix
            WorkOrders.skipWOTrigger = true;
            WorkOrders.isPMWOCancelled = true;
            update lstWOtoBeUpdated;
        }
         ilib_LogEvent.pop();
     }

     /**
    *  @author Nitin
    *  @description  CMSI-222,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }
     /**
    *  @author Kumar Gaurav
    *  @description CMCM-9428 field update for process builder conversion of Service Contract populate fields from Service Plan
    *  @return none
    **/
    public static void updateServiceContractfields( list <SObject> serviceContractList, map <id,sobject> oldserviceContractMap, Boolean isNew){
        set<id> servicePlanIds = new set<id>();
        if (isNew == true){
			if(!serviceContractList.isEmpty()){
                for(SVMXC__Service_Contract__c servContract : (List<SVMXC__Service_Contract__c>)serviceContractList){
                    if(servContract.SVMXC__Service_Plan__c !=null){
                        servicePlanIds.add(servContract.SVMXC__Service_Plan__c);
                    }
                }
			}
        }
        else {
            for(SVMXC__Service_Contract__c servContract : (List<SVMXC__Service_Contract__c>)serviceContractList){
                SVMXC__Service_Contract__c oldservContract=(SVMXC__Service_Contract__c)oldserviceContractMap.get(servContract.Id);
                if(servContract.SVMXC__Service_Plan__c !=null && servContract.SVMXC__Service_Plan__c != oldservContract.SVMXC__Service_Plan__c){
                    servicePlanIds.add(servContract.SVMXC__Service_Plan__c);
                }
            }
        }
		if(!servicePlanIds.IsEmpty()){
			updateServiceContract(servicePlanIds,serviceContractList);
		}
    }

    private static void updateServiceContract(Set<id> servicePlanIds,List <Sobject> serviceContractList){   
        
        if(servicePlanMap.isEmpty()){
            servicePlanMap = new map<id,SVMXC__Service_Plan__c>(new ServicePlanSelector().getServicePlan(servicePlanIds));
        }
        
        for(SVMXC__Service_Contract__c serviceContract :  (List<SVMXC__Service_Contract__c>)serviceContractList){
            updateServiceContract2(serviceContract,servicePlanMap);
        }
    }

    //RESOLVING N PATH COMPLEXITY
    private static void updateServiceContract2(SVMXC__Service_Contract__c serviceContract, Map<id,SVMXC__Service_Plan__c> servicePlanMap){
        if(servicePlanMap!=null && servicePlanMap.containsKey(serviceContract.SVMXC__Service_Plan__c)){
            SVMXC__Service_Plan__c servicePlan = servicePlanMap.get(serviceContract.SVMXC__Service_Plan__c);
            serviceContract.Consumables_Included__c = servicePlan.Consumables_Included__c!=null ? servicePlan.Consumables_Included__c : serviceContract.Consumables_Included__c;
            serviceContract.Labor_Included__c = servicePlan.Labor_Included__c!=null ? servicePlan.Labor_Included__c : serviceContract.Labor_Included__c;
            serviceContract.Loaner_Included__c = servicePlan.Loaner_Included__c!=null ? servicePlan.Loaner_Included__c : serviceContract.Loaner_Included__c;
            serviceContract.Parts_Included__c = servicePlan.Parts_Included__c!=null ? servicePlan.Parts_Included__c : serviceContract.Parts_Included__c;
            serviceContract.Remote_Support_Included__c = servicePlan.Remote_Support_Included__c!=null ? servicePlan.Remote_Support_Included__c : serviceContract.Remote_Support_Included__c;
            serviceContract.SVMXC__Service_Level__c = servicePlan.SVMXC__SLA_Terms__c !=null ? servicePlan.SVMXC__SLA_Terms__c : serviceContract.SVMXC__Service_Level__c;
            serviceContract.Travel_Included__c = servicePlan.Travel_Included__c!=null ? servicePlan.Travel_Included__c : serviceContract.Travel_Included__c;
        }
    }
}
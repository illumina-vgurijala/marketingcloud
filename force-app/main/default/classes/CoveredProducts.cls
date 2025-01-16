/***************************************************************************************************************************************
* NAME   : CoveredProducts
* DESCRIPTION  : Domain class for CoveredProducTrigger.
*                    
* @AUTHOR : Shashank Singhal
* @DATE   : 10-Oct-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shashank               10-Oct-2018          Initial Version. 
* Shivani                15-Jun-2022          DCP-54018 Work Order optimization
****************************************************************************************************************************************/ 

public with sharing class CoveredProducts extends ilib_SObjectDomain{
	
	//added constants - INC0255552
    public static final String STRING_INSTALLED_PRODUCT_FIELD_API_NAME = 'SVMXC__Component__c';
    public static final String STRING_LOCATION_FIELD_API_NAME = 'SVMXC__Site__c';
    public static final String STRING_METHOD_UPDATE_CURRENT_ACTIVE_CONTRACT = 'updateCurrentActiveContractOnIP';
    public static final String STRING_METHOD_UPDATE_LATEST_EXPIRING_CONTRACT = 'updateLatestExpiringContractOnIP';
    
	/*
     * Constructor
     */
    public CoveredProducts(List<SVMXC__Service_Contract_Products__c> sObjectList)
    {
        super(sObjectList);
    }
    
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList  */

        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new CoveredProducts(sObjectList);
        }
    }
    
    /**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Covered product is inserted. 
    **/
    public override void onAfterInsert(){
        //Queueable Thread
        ilib_Queueablethread  queueableThread = new ilib_Queueablethread('AfterInsertCoveredProducts');
        set<Id> setInstalledProductIds = new set<Id>();
        for(SVMXC__Service_Contract_Products__c objCoveredProduct:(List<SVMXC__Service_Contract_Products__c>)records){
            if(objCoveredProduct.SVMXC__Installed_Product__c != null)
                setInstalledProductIds.add(objCoveredProduct.SVMXC__Installed_Product__c);
        }
        //Commented for INC0199251
        //processCoveredProductsOnIP((List<SVMXC__Service_Contract_Products__c>)records, null);
        if(!setInstalledProductIds.isEmpty()){
            //INC0307942
            queueableThread.logandQueue(new CoveredProductsQueueable(STRING_METHOD_UPDATE_CURRENT_ACTIVE_CONTRACT, setInstalledProductIds),'CoveredProducts',STRING_METHOD_UPDATE_CURRENT_ACTIVE_CONTRACT);
            queueableThread.logandQueue(new CoveredProductsQueueable(STRING_METHOD_UPDATE_LATEST_EXPIRING_CONTRACT, setInstalledProductIds),'CoveredProducts',STRING_METHOD_UPDATE_LATEST_EXPIRING_CONTRACT);
			//INC0255552
            insertEntitlements(setInstalledProductIds);
        }
        //INC0307942
        System.debug('queueableThread.lstQueueableJobs--:'+queueableThread.lstQueueableJobs);
        if(queueableThread != null && !queueableThread.lstQueueableJobs.isEmpty()){
            //CMSI-36 passed workstream
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE); 
        }
        
    }
    
    /**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Covered product is updated. 
    **/
    public override void onAfterUpdate(Map<Id, sObject> oldRecords){
        //Queueable Thread
        ilib_Queueablethread  queueableThread = new ilib_Queueablethread('AfterUpdateCoveredProducts');
        set<Id> setInstalledProductIds = new set<Id>();
		//INC0255552
        Set<Id> setNewInstalledProductIds = new Set<Id>();
		//DCP-28624 
		Set<SVMXC__Service_Contract_Products__c> setIntrumentModifiesCoveredProducts=new set<SVMXC__Service_Contract_Products__c>();
        for(SVMXC__Service_Contract_Products__c objCoveredProduct:(List<SVMXC__Service_Contract_Products__c>)records){
            SVMXC__Service_Contract_Products__c objOldCoveredProduct = (SVMXC__Service_Contract_Products__c)oldRecords.get(objCoveredProduct.Id);
            if(objCoveredProduct.SVMXC__Installed_Product__c != objOldCoveredProduct.SVMXC__Installed_Product__c){
                if(objCoveredProduct.SVMXC__Installed_Product__c != null){
                   setInstalledProductIds.add(objCoveredProduct.SVMXC__Installed_Product__c);
				   //INC0255552
                   setNewInstalledProductIds.add(objCoveredProduct.SVMXC__Installed_Product__c);
                }
				//DCP-28624 
				setIntrumentModifiesCoveredProducts.add(objCoveredProduct);
                if(objOldCoveredProduct.SVMXC__Installed_Product__c != null){
                   setInstalledProductIds.add(objOldCoveredProduct.SVMXC__Installed_Product__c);
                }
            }
        }
        //Commented for INC0199251
        //processCoveredProductsOnIP((List<SVMXC__Service_Contract_Products__c>)records, oldRecords);
        if(!setInstalledProductIds.isEmpty()){
             //INC0307942
            queueableThread.logandQueue(new CoveredProductsQueueable(STRING_METHOD_UPDATE_CURRENT_ACTIVE_CONTRACT, setInstalledProductIds),'CoveredProducts',STRING_METHOD_UPDATE_CURRENT_ACTIVE_CONTRACT);
            queueableThread.logandQueue(new CoveredProductsQueueable(STRING_METHOD_UPDATE_LATEST_EXPIRING_CONTRACT, setInstalledProductIds),'CoveredProducts',STRING_METHOD_UPDATE_LATEST_EXPIRING_CONTRACT);
        }
		
		//DCP-28624 
		if(setIntrumentModifiesCoveredProducts!=null && !setIntrumentModifiesCoveredProducts.isEmpty()){
           updateInstrumentonPMWorkOrders(setIntrumentModifiesCoveredProducts);
        }
		//INC0255552
        if(!setNewInstalledProductIds.isEmpty()){
            insertEntitlements(setNewInstalledProductIds);
        }
         //INC0307942
        if(queueableThread != null && !queueableThread.lstQueueableJobs.isEmpty()){
            //CMSI-36 passed workstream
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE); 
        }
    }
    
    /**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Covered product is deleted. 
    **/
    public override void onAfterDelete(){
        //Queueable Thread
        ilib_Queueablethread  queueableThread = new ilib_Queueablethread('AfterDeleteCoveredProducts');
        set<Id> setInstalledProductIds = new set<Id>();
        for(SVMXC__Service_Contract_Products__c objCoveredProduct:(List<SVMXC__Service_Contract_Products__c>)records){
            if(objCoveredProduct.SVMXC__Installed_Product__c != null)
                setInstalledProductIds.add(objCoveredProduct.SVMXC__Installed_Product__c);
        }
        //Commented for INC0199251
        //processCoveredProductsOnIP((List<SVMXC__Service_Contract_Products__c>)records, null);
        if(!setInstalledProductIds.isEmpty()){
            //INC0307942
            queueableThread.logandQueue(new CoveredProductsQueueable(STRING_METHOD_UPDATE_CURRENT_ACTIVE_CONTRACT, setInstalledProductIds),'CoveredProducts',STRING_METHOD_UPDATE_CURRENT_ACTIVE_CONTRACT);
            queueableThread.logandQueue(new CoveredProductsQueueable(STRING_METHOD_UPDATE_LATEST_EXPIRING_CONTRACT, setInstalledProductIds),'CoveredProducts',STRING_METHOD_UPDATE_LATEST_EXPIRING_CONTRACT);
        }
         //INC0307942
        if(queueableThread != null && !queueableThread.lstQueueableJobs.isEmpty()){
            //CMSI-36 passed workstream
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE); 
        }
    }
    
    /**
    *  @author Shashank Singhal
    *  @description - To be executed, when the Covered product is undeleted. 
    **/
    public override void onAfterUndelete(){
        //Commented for INC0199251
        //processCoveredProductsOnIP((List<SVMXC__Service_Contract_Products__c>)records, null);
    }
	
	
	/** 
    * DCP-28624
    * @author Digvijay Singh
    *  Description :- Update Instrument on PM work Order , if the Instrument got updated in related Covered Product in Service Contract
    **/
    
    public void updateInstrumentonPMWorkOrders(set<SVMXC__Service_Contract_Products__c>setIntrumentModifiesCoveredProducts){
       
        List<SVMXC__Service_Order__c> lstWorkOrderstobeUpdated=new List<SVMXC__Service_Order__c>();
        Map<id,id> mapWOtoIP=new Map<id, id>();
        Map<id,id> mapSMCtoIP=new Map<id, id>();
        System.debug('obj:setIntrumentModifiesCoveredProducts '+setIntrumentModifiesCoveredProducts );
         //Create a Map between Service Contrat id and Installed Product Id
         for(SVMXC__Service_Contract_Products__c obj:setIntrumentModifiesCoveredProducts )
         {
            if(obj!=null && obj.SVMXC__Service_Contract__c!=null){
            mapSMCtoIP.put(obj.SVMXC__Service_Contract__c , obj.SVMXC__Installed_Product__c);
            }   
         }

         //Fetch related Applied Contracts 
         if(mapSMCtoIP!=null && !mapSMCtoIP.keySet().IsEmpty()){
            for(Applied_Contract__c obj: new AppliedContractsSelector().selectEntitlementsFromSMCIds(mapSMCtoIP.keySet())){
               if(obj.Work_order__r.SVMXC__Order_Type__c==Label.WorkOrderTypePreventativeMaintenance )
               mapWOtoIP.put(obj.Work_order__c,mapSMCtoIP.get(obj.Service_Contract__c));
               
            }
         }
           
         //Fetch the WorkOrders and Identify the WO in Open status to updated the installed Product
         if(mapWOtoIP!=null && !mapWOtoIP.keyset().IsEmpty()){
            
            for(SVMXC__Service_Order__c obj: new WorkOrdersSelector().selectWorkOrdersFromIds(mapWOtoIP.keySet())){
                if(obj.SVMXC__Order_Status__c==Label.WorkOrderStatusInitiated || obj.SVMXC__Order_Status__c==Label.WorkOrderStatusAssigned || obj.SVMXC__Order_Status__c==Label.WorkOrderStatusAssignmentAccepted ||obj.SVMXC__Order_Status__c==Label.WorkOrderStatusScheduled ||
                obj.SVMXC__Order_Status__c==Label.WorkOrderStatusAwaitingCustomer){
                obj.SVMXC__Component__c=mapWOtoIP.get(obj.Id);
                lstWorkOrderstobeUpdated.add(obj);
                }
            }
         }
       
        if(lstWorkOrderstobeUpdated!=null && !lstWorkOrderstobeUpdated.isEmpty()){
           update lstWorkOrderstobeUpdated;
        }
    }
	/** 
    * INC0255552
    * Method: insertEntitlements
    *  Description : insert applied contracts on insert/update of covered products and update Applied_contracts__c && SLA_terms__c fields in work order.
    **/
    public void insertEntitlements(Set<Id> setInstalledProductIds){
        //get all the install wo's related to that installed product with no applied contracts attached. 
        List<String> lstFieldAPINames = new List<String>{STRING_INSTALLED_PRODUCT_FIELD_API_NAME,STRING_LOCATION_FIELD_API_NAME};    
        List<SVMXC__Service_Order__c> lstWorkOrders = new WorkOrdersSelector().selectWorkOrdersForIP(setInstalledProductIds);
        if(lstWorkOrders != null && !lstWorkOrders.isEmpty()){
            List<Applied_Contract__c>lstAppliedContracts = ServiceUtilityCollection.insertEntitlement(lstWorkOrders, setInstalledProductIds, new Set<Id>(), lstFieldAPINames);
            if(!lstAppliedContracts.isEmpty()){
                try{
                    insert lstAppliedContracts;
                    List<SVMXC__Service_Order__c> lstWorkOrdersToUpdate = ServiceContractAndEntitlement_WOHelper.updateWorkOrderFields(lstAppliedContracts, lstWorkOrders); //DCP-54018
                    if(!lstWorkOrdersToUpdate.isEmpty())
                        update lstWorkOrdersToUpdate;
                }catch(Exception e){
                    ApexExceptions.emit('Applied contracts insert', e);
                }
                
            }

        }
    }
        //Commented for INC0199251
    /*
    *  @AUTHOR:  Shashank Singhal 
    *  @DESCRIPTION: If the Covered product is inserted, updated, deleted or undeleted, the Installed Product Warranty Expiration Date is updated updated based 
    *               on the End Date
    *  @PARAM :  List<SVMXC__Service_Contract_Products__c> lstCurrentCoveredProducts, map<Id, sObject> mapCoveredProductIdToOldCoveredProduct
    *  @RETURN:  void
    */

    /*private void processCoveredProductsOnIP(List<SVMXC__Service_Contract_Products__c> lstCurrentCoveredProducts, map<Id, sObject> mapCoveredProductIdToOldCoveredProduct){
        set<Id> setInstalledProductIds = new set<Id>();
        Map<Id, SVMXC__Service_Contract_Products__c> mapInstalledProductIdToLatestCoveredProduct = new Map<Id, SVMXC__Service_Contract_Products__c>();
        List<SVMXC__Installed_Product__c> lstInstalledProductsToUpdate = new List<SVMXC__Installed_Product__c>();
        for(SVMXC__Service_Contract_Products__c objCoveredProduct: lstCurrentCoveredProducts){
            if(objCoveredProduct.SVMXC__Installed_Product__c != null){
                setInstalledProductIds.add(objCoveredProduct.SVMXC__Installed_Product__c);
            }
            if(mapCoveredProductIdToOldCoveredProduct != null){
                SVMXC__Service_Contract_Products__c objOldCoveredProduct = (SVMXC__Service_Contract_Products__c)mapCoveredProductIdToOldCoveredProduct.get(objCoveredProduct.Id);
                if(objCoveredProduct.SVMXC__Installed_Product__c != objOldCoveredProduct.SVMXC__Installed_Product__c 
                  && objOldCoveredProduct.SVMXC__Installed_Product__c != null){
                    setInstalledProductIds.add(objOldCoveredProduct.SVMXC__Installed_Product__c);
                }
            }
        }
        if(!setInstalledProductIds.isEmpty()){
            for(SVMXC__Service_Contract_Products__c objCoveredProduct:new CoveredProductSelector().selectOrderedCoveredProductsForInstalledProduct(setInstalledProductIds)){
                if(!mapInstalledProductIdToLatestCoveredProduct.containsKey(objCoveredProduct.SVMXC__Installed_Product__c)){
                    mapInstalledProductIdToLatestCoveredProduct.put(objCoveredProduct.SVMXC__Installed_Product__c, objCoveredProduct);
                }
            }
            if(!mapInstalledProductIdToLatestCoveredProduct.isEmpty()){
                for(Id idInstalledProduct:mapInstalledProductIdToLatestCoveredProduct.keyset()){
                    SVMXC__Installed_Product__c objInstalledProduct = new SVMXC__Installed_Product__c(Id = idInstalledProduct);
                    objInstalledProduct.SVMXC__Warranty_End_Date__c = null;
                    if(mapInstalledProductIdToLatestCoveredProduct.get(idInstalledProduct) != null){
                        objInstalledProduct.SVMXC__Warranty_End_Date__c = mapInstalledProductIdToLatestCoveredProduct.get(idInstalledProduct).SVMXC__End_Date__c;
                    }
                    lstInstalledProductsToUpdate.add(objInstalledProduct);
                }
            }
            if(!lstInstalledProductsToUpdate.isEmpty()){
                update lstInstalledProductsToUpdate;
            }
        }
    }*/
	
}
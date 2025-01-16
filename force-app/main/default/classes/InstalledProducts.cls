/**
*    @date   2018-07-12
*    @description    Domain class for InstalledProducts
*    @Test Class for above 90% coverage.
*    @Test Class for atleast 75% coverage.
      -TestInstalledProducts
      -TestTAPS
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------------------------------
*    Developer               Date                Description
*    Vignesh S               11/15/2019          Adding Logic to populate Account on Before Insert for partner installed products.
*    KD                      3-March-2021        DCP-43163 : [Service Loaners] No Requirement of Entitlement for Company Owned Instruments
*    Sagar Madkaikar         2-Nov-2021          CMCP-14 : Regression Bug Fix: Added SVMXC__Company__c to check field changes.
*    Shivani Jain            29-Nov-2021         DCP-42926 Parts Order Lines Optimization
*    Rohan Rathod            23-Mar-2022         DCP-49682 Elevation 1.0 Code removal       
*    Biswajeet Sahoo         04-July-2022        CMSI-94 Instrumentation of class  
*    Sagar Madkaikar         21-Jul-2022         DCP-54367 Added extra arguments while calling AsyncAfterUpdate_InstalledProductHelper.sendIPToSAP() method from onAfterUpdate()       
*    Shivani Jain            17-08-2022          DCP-50068 Keep material number in sync in Installed Product during SAP refurbishment
*    Nishan Shetty           24-August-2022      DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.      
*    -----------------------------------------------------------------------------------------------------------------------------------------------------------
*
*/
public without sharing class InstalledProducts extends ilib_SObjectDomain {
    
    public static Boolean hasRunTaps = false;
    public static Boolean hasRunPartnerSharing = false;
    public static final String INSTRUMENT_OPERATION_STATUS_OFF = 'Off';
    public static final Id TOOLS_INSTALLED_PRODUCT = Schema.SObjectType.SVMXC__Installed_Product__c.getRecordTypeInfosByName().get('Tools').getRecordTypeId();
    public static final Id LIMS_INSTALLED_PRODUCT = Schema.SObjectType.SVMXC__Installed_Product__c.getRecordTypeInfosByName().get('LIMS Software').getRecordTypeId(); //DCP-50068
    public static List<SVMXC__Installed_Product__c> parentInstallProductList = new List<SVMXC__Installed_Product__c>();
    public static List<Time_In_State__c> timeStateListToUpdate = new List<Time_In_State__c>();
    public static List<Profile> currentProfile = new List<Profile>();
    public static boolean skipTrigger = false;
    
    //DCP-45663
    public static final String LOG_TITLE = 'InstalledProducts';
    
    public static Set<String> setSalesOrderId = new Set<String>();
    
    
    public static List < SVMXC__Installed_Product__c > lstInstalledProductsForCPLocationSharing = new List < SVMXC__Installed_Product__c >();  // IPs where location has no account, type= Partner Stock
    
    public static Map<String, String> mapIBFieldLabelVsAPIName = new Map<String, String>();
    public static Map<Id, SVMXC__Installed_Product__c> idToRecordWithAttributesUpdated = new Map<Id, SVMXC__Installed_Product__c>();
    
    public static Set<Id> setInstalledProductIds = new Set<Id>();
    public static Set<Id> setAssetUpdatedInstalledProductIds = new Set<Id>();
    
    public static Map<Id, Product2> mapProducts = new Map<Id, Product2>(); //DCP-50068
    
/*
*Description : Constructor method
*/
    public InstalledProducts(List<SVMXC__Installed_Product__c> sObjectList) {
        super(sObjectList);
        ilib_LogEvent.rootTitle = LOG_TITLE;
    }
    /*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*
* Boilerplate which is required for base class instantiation logic
*/
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new InstalledProducts(sObjectList);
        }
    }

    /*******************************************************************************************************
    * @description  DCP-50068 Method to use for initializing Collections that will be used in before insert and before update events
    * @param records List of Installed Products
    */
    public void queryRecordsforExecutionBeforeEvent(List<Sobject> records) {
        Set<Id> setProductIds = new Set<Id>();

        for(SVMXC__Installed_Product__c installedProd : (List<SVMXC__Installed_Product__c>)records) {
            if(installedProd.SVMXC__Product__c != NULL) {
                setProductIds.add(installedProd.SVMXC__Product__c);
            }
        }

        mapProducts = new Map<Id, Product2>(new ProductsSelector().selectProductsFromMaterialId(setProductIds));
    }

    /* 
    * @description: Before Insert Trigger
    * @date: 03/28/2022
    * @returns: void
    * DCP-28892
    */
    public override void onBeforeInsert() {
        queryRecordsforExecutionBeforeEvent(records);  //DCP-50068

        Map<String, SVMXC__RMA_Shipment_Order__c> orderNumberToPartOrder = new Map<String, SVMXC__RMA_Shipment_Order__c>();
        List<SVMXC__Installed_Product__c> lstInstalledProducts = (List<SVMXC__Installed_Product__c>) records;
        try {
            BeforeInsert_InstalledProductHelper.setDefaultOperationStatusForInstruments(lstInstalledProducts);
            BeforeInsert_InstalledProductHelper.fetchOrderNumbersProductIds(lstInstalledProducts);
            orderNumberToPartOrder = BeforeInsert_InstalledProductHelper.buildMapOfOrderNumberToPartsOrder(setSalesOrderId,orderNumberToPartOrder);
            BeforeInsert_InstalledProductHelper.stampValuesOnNewIPs(lstInstalledProducts,mapProducts,orderNumberToPartOrder);

            //START - DCP-50068
            for(SVMXC__Installed_Product__c installedProd: lstInstalledProducts) {
                
                SyncNameAndCode1_InstalledProductHelper.populateFields(installedProd, null);
            }
            //END - DCP-50068
        } catch (Exception ex) {
            ApexExceptions.emit('InstalledProducts', ex, ilib_LogEvent.SERVICE); //CMSI-94
        }
        if(!skipTrigger){
            updateInstalledProductFields(records, null);
        }
    }

/* 
* @description: After Insert Trigger
* @date: 03/28/2022
* @returns: void
* DCP-28892
*/
    public override void onAfterInsert() {	
        List<SVMXC__Installed_Product__c> lstInstalledProducts = (List<SVMXC__Installed_Product__c>) records;   
        ilib_LogEvent.info('lstInstalledProducts :'+UtilsCollection.getSetOfIds(lstInstalledProducts)); //CMSI-94
        AfterInsert_InstalledProductHelper.processNewIpsToSendEmailNotification(lstInstalledProducts);
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
        hasRunTaps = true;
        // NOTE: should filter records that have non-null values in SVMXC__Product__c & SVMXC__Company__c, then pass that filtered list to shareWithDistributorUsers
        InstalledProductsService.shareWithDistributorUsers(records);
        hasRunPartnerSharing = true;
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(lstInstalledProductsForCPLocationSharing, 'Id'), SVMXC__Site__c.sObjectType);//DCP-44091
        AsyncAfterInsert_InstalledProductHelper.asynCallsOnAfterInsert(lstInstalledProducts);
        
    }

     /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }
    
/* 
* @description: Method to update the installed Product Record type to Tools
* @date: 03/28/2022
* @returns: void
* DCP-28892
*/
    public static void updateInstalledProductRecordType(Set<Id> setInstalledProductIds ) {
        ilib_LogEvent.push(LOG_TITLE + '.updateInstalledProductRecordType()'); //CMSI-94
        ilib_LogEvent.info('setInstalledProductIds :'+setInstalledProductIds); //CMSI-94
        
        Map<Id, SVMXC__Installed_Product__c> idToInstalledProduct = new Map<Id, SVMXC__Installed_Product__c>();
        List<User> lstIntegrationUser = [SELECT Id FROM User Where Name =: 'SAP Service Integration'] ;
        for(SVMXC__Installed_Product__c objInstalledProduct :new InstalledProductsSelector().selectRelatedInstalledProducts(setInstalledProductIds)) {
            if(objInstalledProduct.Service_Product_Type__c == 'Standard Tool' && objInstalledProduct.CreatedById == lstIntegrationUser[0].Id ) {
                objInstalledProduct.RecordTypeId = TOOLS_INSTALLED_PRODUCT;
                idToInstalledProduct.put(objInstalledProduct.id, objInstalledProduct );
            }
        }
        ilib_LogEvent.info('idToInstalledProduct :'+(!idToInstalledProduct.isEmpty() ? String.valueOf(idToInstalledProduct.keySet()) : 'map is empty')); //CMSI-94
        
        if(idToInstalledProduct != null && !idToInstalledProduct.isEmpty()) {
            update idToInstalledProduct.Values();
        }
        ilib_LogEvent.pop(); //CMSI-94
    }
    
/* 
* @description: before update trigger
* @date: 03/28/2022
* @returns: void
* DCP-28892
*/
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords) {
        queryRecordsforExecutionBeforeEvent(records); //DCP-50068

        BeforeUpdate_InstalledProductHelper.prepareIPFieldLabelToApiName();
        BeforeUpdate_InstalledProductHelper.checkFieldSetValuesChangedOnIP(oldRecords, records);
        //CMCM-1355
        BeforeUpdate_InstalledProductHelper.updateFieldsonInstalledProduct(oldRecords, records);

        //START - DCP-50068
        for(SVMXC__Installed_Product__c installedProd: (List<SVMXC__Installed_Product__c>)records) {
            SVMXC__Installed_Product__c oldRec = oldRecords != NULL && oldRecords.get(installedProd.Id) != NULL ? (SVMXC__Installed_Product__c) oldRecords.get(installedProd.Id) : NULL;

            SyncNameAndCode1_InstalledProductHelper.populateFields(installedProd, oldRec);
        }
        //END - DCP-50068

        // Call method to create / update technical attributes
        AsyncBeforeUpdate_InstalledProductHelper.checkFieldSetValuesChangedOnIP(idToRecordWithAttributesUpdated);
        if(!skipTrigger){
            updateInstalledProductFields((List<SVMXC__Installed_Product__c>)records,(map<id,SVMXC__Installed_Product__c>)oldRecords);
        }
    }

/* 
* @description: after update trigger
* @date: 03/28/2022
* @returns: void
* DCP-28892
*/
    public override void onAfterUpdate(Map<Id, sObject> existingRecords) {  
        AfterUpdate_InstalledProductHelper.prepareRequiredSets(records,existingRecords);
        AsyncAfterUpdate_InstalledProductHelper.sendIPToSAP(setInstalledProductIds,setAssetUpdatedInstalledProductIds,(List<SVMXC__Installed_Product__c>)records,(Map<Id,SVMXC__Installed_Product__c>)existingRecords);//DCP-54367 sent typecasted new records and oldmap
        setAssetUpdatedInstalledProductIds.clear();
        setInstalledProductIds.clear();
        AfterUpdate_InstalledProductHelper.iterateToUpdateIVDAndRemoveCoveredProduct(existingRecords,records);
        
        if (!hasRunTaps) {
            Set<Id> changesRequireSharingRecalc = new Set<Id>();
            for (SVMXC__Installed_Product__c rec : (List<SVMXC__Installed_Product__c>)records) {
                SVMXC__Installed_Product__c oldRec = (SVMXC__Installed_Product__c)existingRecords.get(rec.Id);
                
                // NOTE: Family is a Product2 attribute and can't change
                // NOTE: wrote this custom instead of using updateRequiresRecalculation() because Regulatory_Type__c is a string rather than an ID
                if (oldRec.Regulatory_Type__c != rec.Regulatory_Type__c
                    || oldRec.SVMXC__Company__c != rec.SVMXC__Company__c
                    || oldRec.OwnerId != rec.OwnerId
                   ) {
                       changesRequireSharingRecalc.add(rec.Id);
                   }
            }
            
            if (!changesRequireSharingRecalc.isEmpty()) {
                ilib_LogEvent.info('changesRequireSharingRecalc :'+ changesRequireSharingRecalc); //CMSI-94
                TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
                tapsOrchestratorInst.recalculateRecordChanges(changesRequireSharingRecalc, getSObjectType());//DCP-44091
                hasRunTaps = true;
            }
        }
        
        AfterUpdate_InstalledProductHelper.ipSharingWithDistributionUsers(hasRunPartnerSharing,records,existingRecords);
        if(!skipTrigger){
            updateParentInstalledProductfields((List<SVMXC__Installed_Product__c>)records,(map<id,SVMXC__Installed_Product__c>)existingRecords);
        }
        if(currentProfile.isEmpty()){
            currentProfile = new ProfilesSelector().getProfilesById(new Set<Id>{UserInfo.getProfileId()});
        }
        if(currentProfile!=null && !currentProfile.isEmpty() && currentProfile[0].name != Label.Field_Service_Third_Party){
            createOrUpdateTimeInStateRecord((List<SVMXC__Installed_Product__c>)records,(map<id,SVMXC__Installed_Product__c>)existingRecords);
        }
    }
    
/*
* @description: Method for executing sendInstalledProductToSAP if calling from Batch
* @author Harsh Shukla
* @date: 03/28/2022
* @returns: void
* DCP-28892
*/
    
    public static void batchsendInstalledProductToSAP(set<Id> setInstalledProductIds) {
        ilib_LogEvent.push(LOG_TITLE +'.batchsendInstalledProductToSAP()'); //CMSI-94
        ilib_LogEvent.info('setInstalledProductIds :'+setInstalledProductIds); //CMSI-94
        if (setInstalledProductIds.isEmpty()) { return;}
        for (SVMXC__Installed_Product__c instProd : new InstalledProductsSelector().selectInstalledProductsFromIds(setInstalledProductIds)) {
            if (instProd.ERP_Equipment_Id__c == null || instProd.SVMXC__Company__r.ERP_Customer_Id__c == null){
                setInstalledProductIds.remove(instProd.Id);
            }
        }  
        
        EquipmentMasterDataSender equipmentMasterSyncSendInterface = new EquipmentMasterDataSender();
        for (Id strInstProdId : setInstalledProductIds) {
            equipmentMasterSyncSendInterface.callout(strInstProdId); 
        }
        ilib_LogEvent.pop(); //CMSI-94
    }
    
    /**
*  @author       : Kushagra Desai
*  @description  : run billable rule engine on WD and POL
*  @return       : void
*/
    public static void executeIsBillableRules(Set<Id> setIPIds) {
        ilib_LogEvent.push(LOG_TITLE +'.executeIsBillableRules()'); //CMSI-94
        ilib_LogEvent.info('setIPIds :'+setIPIds); //CMSI-94
        List<SVMXC__Service_Order_Line__c> lstWorkDetailstoupdate = new List<SVMXC__Service_Order_Line__c>();
        List<SVMXC__RMA_Shipment_Line__c> lstPOLlstoupdate = new List<SVMXC__RMA_Shipment_Line__c>();
        List<SVMXC__Service_Order__c> lstWO = new WorkOrdersSelector().selectOpenWorkOrdersFromIP(setIPIds);
        Set<Id> setWOId = UtilsCollection.getSetOfIds(lstWO);
        ilib_LogEvent.info('Set of WO ids :'+setWOId);
        List<Sobject> lstWD = new WorkDetailsSelector().selectWorkDetailsForWorkOrderId(setWOId);
        if(!lstWD.isEmpty()) {
            List<Sobject> lstwdUp=BillableRules_WorkdetailsHelper.executeIsBillableRules(lstWD);
            if(!lstwdUp.IsEmpty()) {
                lstWorkDetailstoupdate.addAll((List<SVMXC__Service_Order_Line__c>)lstwdUp);
                ilib_LogEvent.info('lstWorkDetailstoupdate :'+UtilsCollection.getSetOfIds(lstWorkDetailstoupdate)); //CMSI-94
                update lstWorkDetailstoupdate;
            }
        }
        List<sObject> lstPOL = new PartsOrderLineSelector().selectPartsOrderLinesByWONotInStatues(setWOId,null,null,null);
        if(!lstPOL.isEmpty()) {
            //START - DCP-42926
            List<Sobject> lstpolUp = BillableRules_POLHelper.executeIsBillableRules(lstPOL);
            //END - DCP-42926
            if(lstpolUp != null && !lstpolUp.IsEmpty()) {
                lstPOLlstoupdate.addAll((List<SVMXC__RMA_Shipment_Line__c>)lstpolUp);
                ilib_LogEvent.info('lstPOLlstoupdate :'+UtilsCollection.getSetOfIds(lstPOLlstoupdate)); //CMSI-94
                update lstPOLlstoupdate;
            }
        }
        ilib_LogEvent.pop(); //CMSI-94
    }
    
     /**
    *  @author       : Kumar Gaurav
    *  @description  : Called from after Update
    *  @return       : void
    */
    public static void updateInstalledProductFields(List<SVMXC__Installed_Product__c> installProductList, Map<Id, SVMXC__Installed_Product__c> oldInstallProductMap) {
        for (SVMXC__Installed_Product__c installProduct : installProductList) {
            // Handling before insert scenario (oldInstallProductMap is null)
            if (oldInstallProductMap == null) {
                if (installProduct.SVMXC__Status__c == System.label.InstalledProductStatusInstalled && installProduct.Service_Product_Type__c == System.label.ProductTypeSpare) {
                    installProduct.SVMXC__Date_Installed__c = System.today();
                    skipTrigger = true; //avoiding recurssion.
                    WorkOrders.skipWOTrigger = true;
                }
            }
            // Handling before update scenario (oldInstallProductMap is populated)
            else {
                SVMXC__Installed_Product__c oldInstalledProduct = oldInstallProductMap.get(installProduct.Id);
                if (oldInstalledProduct != null && oldInstalledProduct.SVMXC__Status__c == System.label.PartsOrderLineShipped && installProduct.SVMXC__Status__c == System.label.InstalledProductStatusInstalled && installProduct.Service_Product_Type__c == System.label.ProductTypeSpare) {
                    installProduct.SVMXC__Date_Installed__c = System.today();
                    skipTrigger = true; //avoiding recurssion.
                    WorkOrders.skipWOTrigger = true;
                }
            }
        }
    }    
	
 /**
*  @author       : Kumar Gaurav
*  @description  : Called from after Update
*  @return       : void
*/
	public static void updateParentInstalledProductfields(list<SVMXC__Installed_Product__c> installProductList,map<id,SVMXC__Installed_Product__c> installProductMap){
		set<id>parentInstallProductIds = new set<id>();
		//set<id>installProductIds = new set<id>();
		//list<Time_In_State__c> timeStateList = new list<Time_In_State__c>();
		for(SVMXC__Installed_Product__c installProduct :installProductList){
			SVMXC__Installed_Product__c oldInstalledProduct=installProductMap.get(installProduct.id);
				if(installProduct.SVMX_PS_VS_Cloned_From_IP__c!=null &&((oldInstalledProduct.SVMXC__Top_Level__c!=installProduct.SVMXC__Top_Level__c)||(oldInstalledProduct.SVMXC__Parent__c !=installProduct.SVMXC__Parent__c))){
					parentInstallProductIds.add(installProduct.SVMX_PS_VS_Cloned_From_IP__c);
				}
			}
		list<SVMXC__Installed_Product__c> installProductUpdateList = new list<SVMXC__Installed_Product__c>();
		if(parentInstallProductList.isEmpty()){
            parentInstallProductList = new list<SVMXC__Installed_Product__c>(new InstalledProductsSelector().getInstallProduct(parentInstallProductIds));
        }
		
        if(parentInstallProductList!=null && !parentInstallProductList.isEmpty()){
            for(SVMXC__Installed_Product__c insproduct : parentInstallProductList){
                if(insproduct.SVMXC__Status__c==system.label.InstallProductStatusDeInstalled){
                    insproduct.Deinstall_Date__c=system.Today();
                }
                insproduct.SVMXC__Parent__c=null;
                insproduct.SVMXC__Top_Level__c=null;
                installProductUpdateList.add(insproduct);
            }
        }
		
		if(installProductUpdateList!=null && !installProductUpdateList.IsEmpty()){
			skipTrigger = true; //avoiding recurssion.
            WorkOrders.skipWOTrigger = true;
            UPDATE installProductUpdateList;
		}
	}	
	
		
 /**
*  @author       : Kumar Gaurav
*  @description  : Called from after Update
*  @return       : void
*/
	
	public static void createOrUpdateTimeInStateRecord(list<SVMXC__Installed_Product__c> installProductList,map<id,SVMXC__Installed_Product__c> installProductMap){
		set<id>installProductIds = new set<id>();
		List<Time_In_State__c> timeStateList = new List<Time_In_State__c>();
		for(SVMXC__Installed_Product__c installProduct :installProductList){
            SVMXC__Installed_Product__c oldInstalledProduct=installProductMap.get(installProduct.id);
            if(oldInstalledProduct.Operation_Status__c !=installProduct.Operation_Status__c && installProduct.Operation_Status__c=='off'){
                Time_In_State__c timestate = new Time_In_State__c();
                timestate.Field__c='Instrument Down';
                timestate.Installed_Product__c=installProduct.id;
                timestate.Start_Date_Time__c=system.now();
                timeStateList.add(timestate);
            }

            if(oldInstalledProduct.Operation_Status__c !=installProduct.Operation_Status__c && installProduct.Operation_Status__c=='ON'){
                installProductIds.add(installProduct.id);
            }
		}
        if(!timeStateList.IsEmpty()){
            INSERT timeStateList;
        }
		
        if(timeStateListToUpdate.isEmpty()){
            timeStateListToUpdate = new list<Time_In_State__c>(new TimeInStateSelector().getTimeInState(installProductIds));
        }
		
        if(timeStateListToUpdate!=null && !timeStateListToUpdate.isEmpty()){
            for(Time_In_State__c newtimestate : timeStateListToUpdate){
                newtimestate.End_Date_Time__c=system.now();
            }
        }
		
		if(!timeStateListToUpdate.isEmpty()){
			UPDATE timeStateListToUpdate;
		}
	}
}
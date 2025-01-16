/***************************************************************************************************************************************
* NAME   : ApttusOrderLineItems 
* DESCRIPTION  : Domain class for ApptusOrderLineItemTrigger.
*                    
* @AUTHOR : Ritika Maheshwari
* @DATE   : 20-May-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Shivani                  08-Sep-2021         DCP-47686 : OQ PQ IQ/OQ required: Checkbox instead of Labor Line addition  
* Shivani                  16-Sep-2021         DCP-47698 - Sync Acceptance Code to Install Work Order 
* Romi                     17-Nov-2021         DCP-47704 - Email when Work Order fails on creation
* Shivani                  08-Feb-2022         DCP-51266 - Relocation Order should not trigger Install WO Creation
* Shivani                  15-Mar-2022         DCP-51484 : No CP WOs should have Associated SR case
* Prem Ranjan              25-April-2022       CodeScan Fix:Avoid Literals in If condition
* Prem Ranjan              04 May 2022         CodeScan Fix:(APEX) Unused Local Variable
* Aman Tyagi               31-Mar-2022         CodeScan Fixes
* Gladis                   22-Jun-2022         DCP-45368 : Added new methods checkForOLIEquipmentIDChange, mapInstalledProductToCase, fetchIPFromOLI
* Aman Tyagi               12-Dec-2022         CodeScan Fixes
* Prem Ranjan              20-Feb-2023         CodeScan Fixes (APEX) Variable Naming Conventions 
* Sudarshan                05-Dec-2023         CMCM-1354  EOL WO Changes
* LekhaSree                24-May-2024         Enhancement TASK0873335 to add Next Steps &  TASK1011455 to temporarily disable populating nextsteps value on case.
* Vineeta Verma            12-Jul-2024         TASK1037157-Remove creation and deletion of dummy contact and query it
* Arquimidez Mora          09-Aug-2024         CCM-9644 - Delete Order Line Item rejected and update Asset Line Item related 
* Dhairya Shah             11-Oct-2024         CMCM-5165
* Sandeep Singh            15-Nov-2024         CMCM-10562 Ensure only 1 installation work order is created
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ApttusOrderLineItems extends ilib_SObjectDomain{
    
    public static final string STRING_WORK_ORDER_TYPE_INSTALLATION = 'Installation';
    public static final string STRING_WORK_ORDER_STATUS_CANCELED = 'Canceled';
    public static final string STRING_PRODUCT_REGULATORY_TYPE_DX = 'DX';
	public static final String STRING_CHANNEL_PARTNER_TYPE_VAD = 'Value Added Distributor';
    public static final String STRING_CHANNEL_PARTNER_TYPE_SP = 'Service Partner';
    public static final String STRING_LABEL_CHANNEL_PARTNER_REC_TYPE = 'Indirect Partner';
	public static final String STRING_LABEL_PARTNER_PRIMARY_FSE = 'Partner Primary Field Service Engineer';
    public static final String STRING_LABEL_PRIMARY_FSE = 'Primary Field Service Engineer'; // Added by Vishal for CMCM-9451
	public static final String STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED = 'Assignment Accepted';
    public static final String STRING_CS_AMR_QUEUE='CS_AMR_Customer_Service';
    // POL-18 AC9 keywords replaced from APJ to AMEA 
	public static final String STRING_CS_AMEA_QUEUE='CS_AMEA_Customer_Service'; 
    // POL-18 AC9 keywords replaced from EMEA to EUR
	public static final String STRING_CS_EUR_QUEUE='CS_EUR_Customer_Service';
	public static final String STRING_CS_GC_QUEUE='CS_GC_Customer_Service';
    public static final Id SERVICE_REQUEST_ISSUE_CASE_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
    public static final Id WORKORDER_FIELDSERVICE_RECORDTYPE = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId();
    public static final String STRING_PROBLEM_DESCRIPTION = 'has been processed in SAP for a new Instrument that includes a Trade-In and is ready for onsite coordination or support from an Illumina FSE.If the Trade-In is for an instrument that will be scrapped or decommissioned, any onsite time to decommission or decontaminate the Instrument should be recorded and the assigned Work Order completed.';  
    public static final String STRING_CASE_INITIATED_STATUS='Initiated';
	public static final String STRING_CASE_ORIGIN_AUTO_GENERATED='Auto Generated';
    public static final String STRING_CASE_SUB_TYPE_SERVICE_SUPPORT='Service Support';
    public static final String STRING_SER_REQUEST_CODE='SER Request for Install';
    //DCP-47686
    public static final string STRING_QUAL_REQ_IQ_OQ = 'IQ/OQ Required';
    public static final string STRING_QUAL_REQ_PQ = 'PQ Required';
    public static final string SEMICOLON = ';';
    public static final string STRING_PRODUCT_REGULATORY_TYPE_EUA = 'EUA';
    //DCP-47704
    public static final string EMAIL_TEMPLATE_NAME_INSTALLATION = 'Work_Order_Work_Order_Failure_on_installation';   
    public static final string EMAIL_TEMPLATE_NAME_EOL = 'Work_Order_Work_Order_Failure_on_eol';
    //Dummy contact name-TASK1037157
    private static final String CONTACT_NAME = 'Master Data Request Dummy Contact';
    public static final String STRING_TEST_EMAIL = 'test@test.com';
    public static final String PROD_INTEREST_RELOCATION = 'Relocation'; //DCP-51266
    public static final String AMR = 'AMR';
    // POL-18 AC9 keywords replaced from APJ to AMEA 
    public static final String AMEA = 'AMEA';
    // POL-18 AC9 keywords replaced from EMEA to EUR
    public static final String EUR = 'EUR';
    public static final String CHINA = 'China';
    private static final String LOG_TITLE = 'ApptusOrderLineItems';
    public static final string STRING_UPDATE_INSTALLED_PRODUCT = 'updateInstalledProduct';//DCP-45368
    public static final Integer COMMENT_MAX_SIZE = 255; 
	public static Map<String, List<Id>> contactEmailToIDs = new Map<String, List<Id>>();
    public static Map<Id,Account> idToAccount = new Map<Id,Account>();
    public static Map<String,Id> queueToId = new Map<String,Id>();
    public static Map<Id,Product2> productIdToRecord = new Map<Id,Product2>();
    public static final String AUTO_CREATE_INSTALL_WO = 'Auto Create Install Work Order Only'; //CMCM-1662
    public static final String AUTO_CREATE_INSTALL_WO_SR_CASE = 'Auto Create Install Work Order and Service Request Case';
    public static final String AUTO_CREATE_SR_CASE = 'Auto Create Service Request Case Only';  
    
    /*
    * @Author: Shivani
    * @Description :parameterized constructor of class ApttusOrderLineItems
    * @param: List<Apttus_Config2__OrderLineItem__c> sObjectList
    */
    public ApttusOrderLineItems (List<Apttus_Config2__OrderLineItem__c> sObjectList)
    {
        super(sObjectList);
    }
    
     /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {

        /*
        * @Author: Shivani
        * @Description :parameterized constructor of base class
        * @param: List<SObject> sObjectList
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusOrderLineItems (sObjectList);
        }
    }
    
    /**
    *  @author Ritika Maheshwari
    *  @description - To be executed, when the order line item is inserted. 
    **/
    public override void onAfterInsert()
    {
        //Map of Apptus Order to its Order Line Items
        Map<Id,List<Apttus_Config2__OrderLineItem__c>> orderIdToLstOrderLineItems = new Map<Id,List<Apttus_Config2__OrderLineItem__c>>();
        //Map of Apptus Order Line Items to the Quantity that has been set for it.
        Map<Id,Integer> orderLineItemToQuantityChange = new Map<Id,Integer>();
        //Set of product ids selected
        Set<Id> setProductIdsSelected = new Set<Id>();
		//DCP-40254:contains Apttus OLI which has hamilton products
        Map<Id,Boolean> orderEolEligiblity = new Map<Id,Boolean>();

        Map<Id, Apttus_Config2__Order__c> orderMap = populateOrderMap((List<Apttus_Config2__OrderLineItem__c>)records); //DCP-51266
        for(Apttus_Config2__OrderLineItem__c objOrderLineItem : (List<Apttus_Config2__OrderLineItem__c>)records){
            //If the quantity and product is not null, then create work orders for the same.
            //DCP-51266 [added Product Interest filter]
            Boolean hasProduct = objOrderLineItem.Apttus_Config2__ProductId__c != null && objOrderLineItem.Apttus_Config2__Quantity__c != null;
            Boolean hasRelatedOpportunity = orderMap?.get(objOrderLineItem.Apttus_Config2__OrderId__c)?.Apttus_Config2__RelatedOpportunityId__c != null;
            //INC0405959
            String prodInterest = orderMap?.get(objOrderLineItem.Apttus_Config2__OrderId__c).Apttus_Config2__RelatedOpportunityId__r.Product_Interest__c;
            if(hasProduct && (!hasRelatedOpportunity || prodInterest == null || !prodInterest?.contains(PROD_INTEREST_RELOCATION))) {
                if(!orderIdToLstOrderLineItems.containsKey(objOrderLineItem.Apttus_Config2__OrderId__c)){
                    orderIdToLstOrderLineItems.put(objOrderLineItem.Apttus_Config2__OrderId__c , new List<Apttus_Config2__OrderLineItem__c>());
                }
                orderIdToLstOrderLineItems.get(objOrderLineItem.Apttus_Config2__OrderId__c).add(objOrderLineItem);
                orderLineItemToQuantityChange.put(objOrderLineItem.Id, Integer.valueOf(objOrderLineItem.Apttus_Config2__Quantity__c));
                setProductIdsSelected.add(objOrderLineItem.Apttus_Config2__ProductId__c);
            }

        }//END
		OLIWrapper objOLIWrap = ApttusOrderLineItems.filterHamiltonProductCodeInOLI(records);
        ilib_Queueablethread  queueableThread = new ilib_Queueablethread('createWFMInstalledProduct');
		if(objOLIWrap.mapOLIObjToProdCode.size()>0){
            queueableThread.logandQueue(new InstalledProductQueueable('createWFMInstalledProduct',objOLIWrap.mapOLIObjToProdCode.keySet(),objOLIWrap.setHamiltonProdCode,objOLIWrap.mapHamilton, null),'InstalledProductQueueable','createWFMInstalledProduct'); 
            if(queueableThread!=null)
            ilib_QueueableManager.enqueueJob(queueableThread, ilib_LogEvent.SERVICE); 
        }
         
        
        //Call the method to create automated installation Work Orders
        if(!orderIdToLstOrderLineItems.isEmpty()){
			//DCP-47698 
            orderEolEligiblity = prepareEOLConditions(orderIdToLstOrderLineItems);
		 	ApttusOrderLineItemQueueable apttusOrderLineQueuable= new ApttusOrderLineItemQueueable(ApttusOrderLineItemQueueable.ACTION_CREATE_INSTALL_WO, orderIdToLstOrderLineItems, orderLineItemToQuantityChange, setProductIdsSelected,orderEolEligiblity);
            ilib_Queueablethread QBase=new ilib_Queueablethread(LOG_TITLE);
            QBase.logandQueue(apttusOrderLineQueuable,LOG_TITLE,ApttusOrderLineItemQueueable.ACTION_CREATE_INSTALL_WO);
            ilib_QueueableManager.enqueueJob(QBase,ilib_LogEvent.SERVICE); 
            //createInstallationWorkOrders(orderIdToLstOrderLineItems, orderLineItemToQuantityChange, setProductIdsSelected);
        }
    }

    /**
    *  @author Sudarshan Kataria
    *  @description - 
    **/
    public static Map<Id,Boolean> prepareEOLConditions(Map<Id,List<Apttus_Config2__OrderLineItem__c>> orderIdToLstOrderLineItems){ 
        Map<Id,Boolean> orderEolEligiblity = new Map<Id,Boolean>();  
        List<Apttus_Config2__OrderLineItem__c> tradeInOrderLines = new List<Apttus_Config2__OrderLineItem__c>();
        tradeInOrderLines = new ApttusOrderLineItemsSelector().selectTradeInOrderLines(orderIdToLstOrderLineItems.keySet()); 
        for(Apttus_Config2__OrderLineItem__c tradeInOL:tradeInOrderLines){ 
            orderEolEligiblity.put(tradeInOL.Apttus_Config2__OrderId__c,TRUE); 
        }  
        return orderEolEligiblity;
    }

	
	/**
    *  @author Prakhar Kumar
    *  @description - 
    **/
    public static OLIWrapper filterHamiltonProductCodeInOLI(List<Apttus_Config2__OrderLineItem__c> records){  
        Map< String , Installed_Product_Creation_Config__mdt > mapHamilton = new Map< String , Installed_Product_Creation_Config__mdt >();  
        
        //stores the WFM Product code which is present in Metadata.  
        Set<String> setHamiltonProdCode = new Set<String>();  
        
        //stores the OLI with its corresponding ProdCode having Hamilton Products  
        Map<Apttus_Config2__OrderLineItem__c,String>  mapOLIObjToProdCode = new Map<Apttus_Config2__OrderLineItem__c,String> ();  
        
            for(Installed_Product_Creation_Config__mdt mdt:[SELECT label,Installed_Product_Code_Created__c,Order_Line_Item_Code_Searched__c,Prefix__c FROM Installed_Product_Creation_Config__mdt]){ 
                mapHamilton.put(mdt.Order_Line_Item_Code_Searched__c, mdt); 
            }
        
            //Filter Hamilton Prod Codes from all ProdCodes present in setProdCode 
            
            for(Apttus_Config2__OrderLineItem__c objOrderLineItem : (List<Apttus_Config2__OrderLineItem__c>)records){ 
                if(objOrderLineItem.Product_Code__c != NULL && objOrderLineItem.Contract_Number__c !=NULL && mapHamilton.containsKey(objOrderLineItem.Product_Code__c)){ 
                      setHamiltonProdCode.add(mapHamilton.get(objOrderLineItem.Product_Code__c).Installed_Product_Code_Created__c); 
                      mapOLIObjToProdCode.put(objOrderLineItem,objOrderLineItem.Product_Code__c); 
                } 
            }  
            
        OLIWrapper oliWrapperObj = new OLIWrapper(mapOLIObjToProdCode,setHamiltonProdCode,mapHamilton); 
        return oliWrapperObj;
    }
    
    
    /**
    *  @author Ritika Maheshwari
    *  @description - To be executed, when the order line item is updated. 
    **/
    public override void onAfterUpdate(Map<Id, SObject> existingRecords)
    {
        //DCP-45368 Check for EquipmentId change
        ilib_LogEvent.info('45368-After update-->'+existingRecords);
        Set<Id> setOrderLineItemIds = checkForOLIEquipmentIDChange(existingRecords);
        //Map of Apptus Order to its Order Line Items
        Map<Id,List<Apttus_Config2__OrderLineItem__c>> orderIdToLstOrderLineItems = new Map<Id,List<Apttus_Config2__OrderLineItem__c>>();
        //Map of Apptus Order Line Items to the Quantity that has been set for it.
        Map<Id,Integer> orderLineItemToQuantityChange = new Map<Id,Integer>();
        //Set of product ids selected
        Set<Id> setProductIdsSelected = new Set<Id>();
        Map<Id,Boolean> orderEolEligiblity = new Map<Id,Boolean>();
		
		//DCP-40254: contains Apttus OLI which has hamilton products
        List<Apttus_Config2__OrderLineItem__c> lstOLI = new List<Apttus_Config2__OrderLineItem__c>();
        
        Map<String, String> oliERPNumberToMaterialGroup5 = new Map<String, String>(); //DCP-47698
 
        Map<Id, Apttus_Config2__Order__c> orderMap = populateOrderMap((List<Apttus_Config2__OrderLineItem__c>)records); //DCP-51266
        
        for(Apttus_Config2__OrderLineItem__c objOrderLineItem : (List<Apttus_Config2__OrderLineItem__c>)records){
            Apttus_Config2__OrderLineItem__c objOldOrderLineItem = (Apttus_Config2__OrderLineItem__c)existingRecords.get(objOrderLineItem.Id);
            //If the quantity is not null, and the quantity is increased then create work orders for the same.
            //DCP-51266 [added Product Interest filter]
            Boolean hasProduct = objOrderLineItem.Apttus_Config2__ProductId__c != null && objOrderLineItem.Apttus_Config2__Quantity__c != null;
            Boolean hasRelatedOpportunity = orderMap?.get(objOrderLineItem.Apttus_Config2__OrderId__c)?.Apttus_Config2__RelatedOpportunityId__c != null;
            
            if(hasProduct && 
                    (objOrderLineItem.Apttus_Config2__Quantity__c > objOldOrderLineItem.Apttus_Config2__Quantity__c || 
                        objOldOrderLineItem.Apttus_Config2__Quantity__c == null)
                    && (!hasRelatedOpportunity
                        || !(orderMap.get(objOrderLineItem.Apttus_Config2__OrderId__c).Apttus_Config2__RelatedOpportunityId__r.Product_Interest__c?.contains(PROD_INTEREST_RELOCATION)))) {
                if(!orderIdToLstOrderLineItems.containsKey(objOrderLineItem.Apttus_Config2__OrderId__c)){
                    orderIdToLstOrderLineItems.put(objOrderLineItem.Apttus_Config2__OrderId__c , new List<Apttus_Config2__OrderLineItem__c>());
                }
                orderIdToLstOrderLineItems.get(objOrderLineItem.Apttus_Config2__OrderId__c).add(objOrderLineItem);
                orderLineItemToQuantityChange.put(objOrderLineItem.Id, 
                                Integer.valueOf(objOrderLineItem.Apttus_Config2__Quantity__c) - 
                                (objOldOrderLineItem.Apttus_Config2__Quantity__c != null ? Integer.valueOf(objOldOrderLineItem.Apttus_Config2__Quantity__c) : 0));
            	setProductIdsSelected.add(objOrderLineItem.Apttus_Config2__ProductId__c);
            }
			if((objOldOrderLineItem.ERP_Line_Number_Id__c == NULL && objOrderLineItem.ERP_Line_Number_Id__c!=NULL)||(objOldOrderLineItem.Apttus_Config2__ProductId__c != objOrderLineItem.Apttus_Config2__ProductId__c && objOrderLineItem.Apttus_Config2__ProductId__c != NULL)){
                lstOLI.add(objOrderLineItem);
            }
            //START DCP-47698
            if(objOrderLineItem.Material_Group_5__c != objOldOrderLineItem.Material_Group_5__c) {
                oliERPNumberToMaterialGroup5.put(objOrderLineItem.ERP_Line_Number_Id__c, objOrderLineItem.Material_Group_5__c);
            }
            //END DCP-47698
			 
        }//END
		
		    OLIWrapper objOLIWrap = ApttusOrderLineItems.filterHamiltonProductCodeInOLI(lstOLI);

            if(lstOLI.size()>0){
                ilib_Queueablethread  queueableThread = new ilib_Queueablethread('createWFMInstalledProduct');
                queueableThread.logandQueue(new InstalledProductQueueable('createWFMInstalledProduct',objOLIWrap.mapOLIObjToProdCode.keySet(),objOLIWrap.setHamiltonProdCode,objOLIWrap.mapHamilton, null),'InstalledProductQueueable','createWFMInstalledProduct'); 
                
                if(queueableThread!=null){
                    ilib_QueueableManager.enqueueJob(queueableThread, ilib_LogEvent.SERVICE); 
                } 
            } 
        
        ilib_Queueablethread qBase=new ilib_Queueablethread(LOG_TITLE); //DCP-47698
        //Call the method to create automated installation Work Orders
        if(!orderIdToLstOrderLineItems.isEmpty()){
            orderEolEligiblity = prepareEOLConditions(orderIdToLstOrderLineItems);
            //Modified for DCP-47698 
			ApttusOrderLineItemQueueable apttusOrderLineQueuable= new ApttusOrderLineItemQueueable(ApttusOrderLineItemQueueable.ACTION_CREATE_INSTALL_WO, orderIdToLstOrderLineItems, orderLineItemToQuantityChange, setProductIdsSelected,orderEolEligiblity);
            //ilib_Queueablethread QBase=new ilib_Queueablethread(LOG_TITLE);
            qBase.logandQueue(apttusOrderLineQueuable,LOG_TITLE,ApttusOrderLineItemQueueable.ACTION_CREATE_INSTALL_WO);
            //ilib_QueueableManager.enqueueJob(qBase); 
            //createInstallationWorkOrders(orderIdToLstOrderLineItems, orderLineItemToQuantityChange, setProductIdsSelected);
        }
        //DCP-45368 Starts
        if(!setOrderLineItemIds.isEmpty()) {
            qBase.logandQueue(new ApttusOrderLineItemQueueable(STRING_UPDATE_INSTALLED_PRODUCT,null,null,setOrderLineItemIds,orderEolEligiblity),'ApttusOrderLineItemQueueable',STRING_UPDATE_INSTALLED_PRODUCT); 
        }
        //DCP-45368 Ends
        //START DCP-47698
        if(!oliERPNumberToMaterialGroup5.isEmpty()) {
            qBase.logandQueue(new ApttusOrderLineItemQueueable(ApttusOrderLineItemQueueable.ACTION_SYNC_CODE_TO_WO, oliERPNumberToMaterialGroup5),'ApttusOrderLineItemQueueable', ApttusOrderLineItemQueueable.ACTION_SYNC_CODE_TO_WO); 
        }
        if(qBase != null && !qBase.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(qBase, ilib_LogEvent.SERVICE);
        }
        //END DCP-47698
        // START CMCM-9644
        OrderLineItemService.updateStatusToRejectedAndDeleteRejectedRecords((List<Apttus_Config2__OrderLineItem__c>)records, existingRecords);
        OrderLineItemService.updateStatusAndAssetLineItemLineStatus((List<Apttus_Config2__OrderLineItem__c>)records, existingRecords);
        //END CMCM-9644
    }
    
    /**
    *  @author Ritika Maheshwari
    *  @description - To be executed, when the order line item is deleted. 
    **/
    public override void onBeforeDelete()
    {
        //Set of order line items which have been deleted
        Set<String> setOrderLineNumberCanceled = new Set<String>();
        
        //If an order line item is deleted, then cancel its related work orders.
        for(Apttus_Config2__OrderLineItem__c objOrderLineItem : (List<Apttus_Config2__OrderLineItem__c>)records){
            setOrderLineNumberCanceled.add(objOrderLineItem.ERP_Line_Number_Id__c);
        }
        
        //Call to method, to cancel the work orders for an order line item
        if(!setOrderLineNumberCanceled.isEmpty()){
            cancelWorkOrders(setOrderLineNumberCanceled);
        }
    }
    
    /**
    *  @author Sudarshan Kataria
    *  @description - CMCM-1354: Create Installation and/or EOL (End of life) work orders
    **/
    public static void createWorkOrders(Map<Id,List<Apttus_Config2__OrderLineItem__c>> orderIdToLstOrderLineItems, Map<Id,Integer> orderLineItemToQuantityChange,Set<Id> setProductIdsSelected,Map<Id,Boolean> orderEolEligiblity)
    {
        Map<Id,List<Apttus_Config2__OrderLineItem__c>> eolOrderIdToLstOrderLineItems = new Map<Id,List<Apttus_Config2__OrderLineItem__c>>();
        for(Id orderId:orderIdToLstOrderLineItems.keySet()){ 
            if(orderEolEligiblity.containsKey(orderId)){
                eolOrderIdToLstOrderLineItems.put(orderId,orderIdToLstOrderLineItems.get(orderId)); 
            }
        } 
        if(!eolOrderIdToLstOrderLineItems.isEmpty()){
            createEolWorkOrders(eolOrderIdToLstOrderLineItems,orderLineItemToQuantityChange,setProductIdsSelected);
        }
        if(!orderIdToLstOrderLineItems.isEmpty()){
            createInstallationWorkOrders(orderIdToLstOrderLineItems, orderLineItemToQuantityChange, setProductIdsSelected);
        } 
    }
    
    /**
    *  @author Sandeep Singh
    *  @description - CMCM-10562 Method to ensure only 1 installation work order is created
    **/
    public static Map<Id,Boolean> checkBillableService(Map<Id,List<Apttus_Config2__OrderLineItem__c>> orderIdToLstOrderLineItems) {
        Map<String, String> mapMaterialToProdCodeMetadata = new Map<String, String>();
        Map<String, Billable_Install_Product__mdt> mapProdCodeMetadata = new Map<String, Billable_Install_Product__mdt>();
        Set<Id> orderIdSet = new Set<Id>();
        Map<String, Decimal> mapOrderProdToQnty = new Map<String,Decimal>();
        Map<Id,Boolean> mapOLIToSkipInstallationWOFlag = new Map<Id,Boolean>();     
        
        //Query to get metadata records list
        List<Billable_Install_Product__mdt> billableInstallOrders = [Select Id,Billable_Service_Product_Code__c,Sales_Instrument_Product_Code__c from Billable_Install_Product__mdt limit 50];
        
        if(!billableInstallOrders.isEmpty()) {
            for(Billable_Install_Product__mdt billableInstallOrder : billableInstallOrders) {
                mapProdCodeMetadata.put(billableInstallOrder.Sales_Instrument_Product_Code__c,billableInstallOrder);
                mapMaterialToProdCodeMetadata.put(billableInstallOrder.Billable_Service_Product_Code__c,billableInstallOrder.Sales_Instrument_Product_Code__c);
            }           
        } 
        
        List<Apttus_Config2__OrderLineItem__c> orderLineItemList = new ApttusOrderLineItemsSelector().fetchOrderLineItemsByOrder(orderIdToLstOrderLineItems.keySet());
        
        for(Apttus_Config2__OrderLineItem__c orderLineItemRec : orderLineItemList) {            
            Decimal orderLineQuantity = 0;
            mapOLIToSkipInstallationWOFlag.put(orderLineItemRec.Id,false);
            if(orderLineItemRec.Product_Code__c != null && mapProdCodeMetadata.containsKey(orderLineItemRec.Product_Code__c)) {
                if(!mapOrderProdToQnty.containsKey(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c)) {
                    mapOrderProdToQnty.put(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c,0);
                } 
                orderLineQuantity = orderLineItemRec.Apttus_Config2__Quantity__c;
                orderIdSet.add(orderLineItemRec.Apttus_Config2__OrderId__c);
                mapOrderProdToQnty.put(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c,mapOrderProdToQnty.get(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c)+orderLineQuantity);
            }
        }       
        
        if(mapOrderProdToQnty.isEmpty()) {
            return mapOLIToSkipInstallationWOFlag;
        }
        mapOLIToSkipInstallationWOFlag = compareOLIProdQLIMaterialQnty(orderIdSet,mapMaterialToProdCodeMetadata,mapOrderProdToQnty,orderLineItemList);
                                              
        return mapOLIToSkipInstallationWOFlag; 
    }
    
    /**
    *  @author Sandeep Singh
    *  @description - CMCM-10562 method to compare oli quantity and qli martial quantity related to an order/quotation
    **/
    public static Map<Id,Boolean> compareOLIProdQLIMaterialQnty(Set<Id> orderIdSet,Map<String, String> mapMaterialToProdCodeMetadata, 
                                                        Map<String, Decimal> mapOrderProdToQnty,  
                                                        List<Apttus_Config2__OrderLineItem__c> orderLineItemList) {
        Set<Id> emailForOrderIdSet = new Set<Id>(); 
        Map<String,Decimal> mapMatCodeToQLIQnty = new Map<String,Decimal>();
        Map<Id,Boolean> mapOLIToSkipInstallationWOFlag = new Map<Id,Boolean>();
        Set<Id> quotationIdSet = new Set<Id>();
        Map<Id,Id> mapQuotationToOrder= new Map<Id,Id>();
        Map<Id,Apttus_Config2__Order__c> mapOrderIdToOrderRecord = new Map<Id,Apttus_Config2__Order__c>();

        List<Apttus_Config2__Order__c> orderList = new ApttusOrdersSelector().selectOrdersByIds(orderIdSet); 
        for(Apttus_Config2__Order__c  orderRecord : orderList) {
            mapOrderIdToOrderRecord.put(orderRecord.Id,orderRecord);
            if(orderRecord.Apttus_QPConfig__ProposalId__c != null) {
                quotationIdSet.add(orderRecord.Apttus_QPConfig__ProposalId__c);
                mapQuotationToOrder.put(orderRecord.Apttus_QPConfig__ProposalId__c,orderRecord.Id);
            }
        }
        mapMatCodeToQLIQnty = processMaterialQnty(quotationIdSet, mapQuotationToOrder, mapMaterialToProdCodeMetadata);
        for(Apttus_Config2__OrderLineItem__c orderLineItemRec : orderLineItemList) {
            mapOLIToSkipInstallationWOFlag.put(orderLineItemRec.Id,false);
            if(mapOrderProdToQnty.get(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c) != null && mapMatCodeToQLIQnty.get(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c) != null && mapOrderProdToQnty.get(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c) == mapMatCodeToQLIQnty.get(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c)) {
                mapOLIToSkipInstallationWOFlag.put(orderLineItemRec.Id,true);
            } else if(mapOrderProdToQnty.get(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c) != null && mapMatCodeToQLIQnty.get(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c) != null && mapOrderProdToQnty.get(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c) != mapMatCodeToQLIQnty.get(orderLineItemRec.Apttus_Config2__OrderId__c+orderLineItemRec.Product_Code__c)) {
                emailForOrderIdSet.add(orderLineItemRec.Apttus_Config2__OrderId__c);
            }
        }
        
        if(emailForOrderIdSet != null && !emailForOrderIdSet.isEmpty()) {
            sendEmailForTraningMismatch(emailForOrderIdSet,mapOrderIdToOrderRecord);
        } 
        return mapOLIToSkipInstallationWOFlag;
    }

    /**
    *  @author Sandeep Singh
    *  @description - CMCM-10562 method to calculate martial quantity related to an order/quotation
    **/
    public static Map<String,Decimal> processMaterialQnty(Set<Id> quotationIdSet,Map<Id,Id> mapQuotationToOrder,Map<String, String> mapMaterialToProdCodeMetadata) {
        Map<String,Decimal> mapMaterialCodeToQLIQnty = new Map<String,Decimal>();
        List<Apttus_Proposal__Proposal_Line_Item__c> quotationLineList = new ApttusProposalLineItemsSelector().selectByQuoteId(quotationIdSet);
        for(Apttus_Proposal__Proposal_Line_Item__c quotationLineRecord : quotationLineList) {
            Decimal quotationLineQuantity = 0;
            if(quotationLineRecord.Material_Number__c != null && mapMaterialToProdCodeMetadata.containsKey(quotationLineRecord.Material_Number__c)) {
                if(!mapMaterialCodeToQLIQnty.containsKey(mapQuotationToOrder.get(quotationLineRecord.Apttus_Proposal__Proposal__c)+mapMaterialToProdCodeMetadata.get(quotationLineRecord.Material_Number__c))) {
                    mapMaterialCodeToQLIQnty.put(mapQuotationToOrder.get(quotationLineRecord.Apttus_Proposal__Proposal__c)+mapMaterialToProdCodeMetadata.get(quotationLineRecord.Material_Number__c),0);
                }
                quotationLineQuantity = quotationLineRecord.Apttus_QPConfig__Quantity2__c;
                mapMaterialCodeToQLIQnty.put(mapQuotationToOrder.get(quotationLineRecord.Apttus_Proposal__Proposal__c)+mapMaterialToProdCodeMetadata.get(quotationLineRecord.Material_Number__c),mapMaterialCodeToQLIQnty.get(mapQuotationToOrder.get(quotationLineRecord.Apttus_Proposal__Proposal__c)+mapMaterialToProdCodeMetadata.get(quotationLineRecord.Material_Number__c))+quotationLineQuantity); 
            }  
        }
        return mapMaterialCodeToQLIQnty;
    }
    /**
    *  @author Sandeep Singh
    *  @description - CMCM-10562 method to send email to customer care for traning mismatch
    **/
   
    public static void sendEmailForTraningMismatch(Set<Id> emailForOrderIdSet,  Map<Id,Apttus_Config2__Order__c> mapOrderIdToOrderRecord){
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        String[] toAddress = new String[]{System.Label.Email2CaseCustomerCareId};
            for(Id orderRecId : emailForOrderIdSet) {
                Apttus_Config2__Order__c orderRec = mapOrderIdToOrderRecord.get(orderRecId);
                Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
                emailToSend.setSubject('Order '+orderRec.Name+': Potential Work Order Creation Issues');
                emailToSend.setHtmlBody('For order '+orderRec.Name+' there were an uneven number of instruments and related billable trainings. Some Installation work orders will need to be cancelled to have the number of Installation and Billable Install work orders to match the number of instruments on this order.</br></br>'+
                                        +'NOTE '+orderRec.Name+' means to substitute the ERP number for the order into the text.'); 
                emailToSend.setToAddresses(toAddress);
                emailList.add(emailToSend);
            }
        Messaging.sendEmail(emailList);
    }

    /**
    *  @author Sudarshan Kataria
    *  @description - CMCM-1354: Create EOL (End of life) work orders
    **/
    public static void createEolWorkOrders(Map<Id,List<Apttus_Config2__OrderLineItem__c>> eolOrderIdToLstOrderLineItems, Map<Id,Integer> orderLineItemToQuantityChange,Set<Id> setProductIdsSelected)
    {  
        Set<Id> ipIdSet = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        Set<String> setAccIds = new Set<String> ();
        Map<Id,List<Id>> quoteIdInstalledProductIdMap = new Map<Id,List<Id>>();
        Map<Id,Trade_In_Product__c> ipIdTradeInProductMap = new Map<Id,Trade_In_Product__c>();
        Map<Id,Apttus_Config2__Order__c> orderIdOrderMap = new Map<Id,Apttus_Config2__Order__c>(); 
        List<SVMXC__Service_Order__c> woListToInsert = new List<SVMXC__Service_Order__c>();
        Apttus_Config2__Order__c objApptusOrder;
        Savepoint sp = Database.setSavepoint();
        try{
            for(Apttus_Config2__Order__c ordObj:new ApttusOrdersSelector().selectOrdersByIds(eolOrderIdToLstOrderLineItems.keySet())){
                orderIdOrderMap.put(ordObj.Id,ordObj);
                quoteIds.add(ordObj.Apttus_QPConfig__ProposalId__c);
                setAccIds.add(ordObj.Apttus_Config2__SoldToAccountId__c);
            } 
            for(Trade_In_Product__c tradeInP:new TradeInProductsSelector().selectTradeInProductsForQuotes(quoteIds)){
                if(!quoteIdInstalledProductIdMap.containsKey(tradeInP.Quote_Proposal__c)){
                    quoteIdInstalledProductIdMap.put(tradeInP.Quote_Proposal__c,new List<Id>());
                }
                quoteIdInstalledProductIdMap.get(tradeInP.Quote_Proposal__c).add(tradeInP.Installed_Product__c);
                ipIdTradeInProductMap.put(tradeInP.Installed_Product__c,tradeInP);
                ipIdSet.add(tradeInP.Installed_Product__c);
            }  
            for(SVMXC__Service_Order__c wo: new WorkOrdersSelector().selectEOLWorkOrders(ipIdSet)){
                ipIdSet.remove(wo.SVMXC__Component__c);   //Final List of IPs to create WOs
            } 
            if(!ipIdSet.isEmpty()){
                Map<Id,Map<String,Account_to_Field_Support__c>> mapAccFieldSupport = ServiceUtilityCollection.fetchAccountRoles(setAccIds, new Set<String>{STRING_LABEL_PARTNER_PRIMARY_FSE});
                for(Id idApptusOrder: eolOrderIdToLstOrderLineItems.keySet()){  
                    objApptusOrder = orderIdOrderMap.get(idApptusOrder); 
                    for(Id ipId: quoteIdInstalledProductIdMap.get(objApptusOrder.Apttus_QPConfig__ProposalId__c)){
                        if(ipIdSet.contains(ipId)){
                            SVMXC__Service_Order__c woObj = createWoObj(objApptusOrder,ipIdTradeInProductMap.get(ipId),mapAccFieldSupport); 
                            woListToInsert.add(woObj);  
                        } 
                    }
                }  
            } 
            if(!woListToInsert.isEmpty()){ 
                insert woListToInsert;
            } 
        }catch(Exception ex){
            ilib_LogEvent.info('## Exception : ' + ex.getStackTraceString());
            ilib_LogEvent.info('## Exception Message : ' + ex.getMessage());
			Database.rollback(sp);
            
           ApttusOrderLineItems.sendEmailWhenWOFails(objApptusOrder, ex,EMAIL_TEMPLATE_NAME_EOL);  
        
        }
    }

    /**
    *  @author Sudarshan Kataria
    *  @description - 
    **/
    public static SVMXC__Service_Order__c createWoObj(Apttus_Config2__Order__c objApptusOrder, Trade_In_Product__c tradeInObj,Map<Id,Map<String,Account_to_Field_Support__c>> mapAccFieldSupport)
    { 
        SVMXC__Service_Order__c objWO = new SVMXC__Service_Order__c(); 
        objWO.Opportunity__c = objApptusOrder.Apttus_Config2__RelatedOpportunityId__c; 
        objWO.SVMXC__Component__c = tradeInObj.Installed_Product__c;
        objWO.SVMXC__Product__c = tradeInObj.Installed_Product__r.SVMXC__Product__c;
        objWO.SVMXC__Company__c = tradeInObj.Installed_Product__r.SVMXC__Company__c;
        objWO.SVMXC__Contact__c = tradeInObj.Installed_Product__r.SVMXC__Contact__c;
        objWO.SVMXC__Site__c = tradeInObj.Installed_Product__r.SVMXC__Site__c; 
        objWO.RecordTypeId = WORKORDER_FIELDSERVICE_RECORDTYPE;    
        objWO.SVMXC__Order_Type__c = System.Label.WorkOrderTypeTradeinEOL; 
        objWO.SVMX_PS_Subject__c = '[Trade-In]' + ' ' + tradeInObj.Installed_Product__r.SVMXC__Serial_Lot_Number__c + ' ' + tradeInObj.Installed_Product__r.SVMXC__Product__r.Name +  ' ' + objApptusOrder.Apttus_Config2__OrderReferenceNumber__c;
        if(objWO.SVMX_PS_Subject__c.length() > COMMENT_MAX_SIZE) objWO.SVMX_PS_Subject__c = objWO.SVMX_PS_Subject__c.substring(0, COMMENT_MAX_SIZE); 
        objWO.Notes__c = 'Order ' + objApptusOrder.Apttus_Config2__OrderReferenceNumber__c + ' ' + STRING_PROBLEM_DESCRIPTION; // Added field by Dhairya for CMCM - 5165
        objWO.Standalone_Work_Order_Origin__c = STRING_CASE_ORIGIN_AUTO_GENERATED; 
        objWO.SVMXC__Order_Status__c = WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED;
        return objWO;
    } 

    /**
    *  @author Ritika M
    *  @description - Create Installation Work Orders
    *  @parameters : orderIdToLstOrderLineItems: Map of apptus orders to the list of order line items which have been created / updated.
    *                orderLineItemToQuantityChange : map of order line items created/updated to the corresponding quantity created/updated
    *                orderLineItemToQuantityChange : set of product ids selected in order line items
    *                boolOrderLineItemCreated : Check whether order line item is created or updated.
    *  @return : void
    **/
    public static void createInstallationWorkOrders(Map<Id,List<Apttus_Config2__OrderLineItem__c>> orderIdToLstOrderLineItems, Map<Id,Integer> orderLineItemToQuantityChange,
                                                    Set<Id> setProductIdsSelected) {
        Savepoint sp = Database.setSavepoint();
        //added for INC0220064
		Apttus_Config2__Order__c objApptusOrder;
		try {
            Map<Id,Apttus_Config2__Order__c> orderIdToOrderObj = new Map<Id,Apttus_Config2__Order__c>();
            Map<Id,Id> orderIdToASOPOrderId = new Map<Id,Id>();
            Map<Id,Contract_Order_Routing_Sheet__c> orderIDToCORSObj = new Map<Id, Contract_Order_Routing_Sheet__c>();
            //List<SVMXC__Service_Order__c> lstInstallWOToBeInserted = new List<SVMXC__Service_Order__c>();
            Map<Id,Boolean> mapOLIToSkipInstallationWOFlag = new Map<Id,Boolean>();
            Set<String> setAccIds = new Set<String> ();
			
			//case creation logic -DCP-34287
            Set<Id> setUCAccIds = new Set<Id>();
            Map<String,case> orderItemIdToCase = new Map<String,case>();
			Map<String,SVMXC__Service_Order__c> orderItemIdToWo = new Map<String,SVMXC__Service_Order__c>();
            Map<Id,Case> caseIdToCaseRecord = new Map<Id,Case>(); 
            
            mapOLIToSkipInstallationWOFlag = checkBillableService(orderIdToLstOrderLineItems);
                 
            if(setProductIdsSelected != null) {
                productIdToRecord = new Map<Id,Product2>(new ProductsSelector().selectInstrumentProductsForAutoWOCreation(setProductIdsSelected));
            }
                                   
            for(Apttus_Config2__Order__c objOrder : new ApttusOrdersSelector().selectOrdersByIds(orderIdToLstOrderLineItems.keySet())) { 
                orderIdToOrderObj.put(objOrder.Id, objOrder);
				setAccIds.add(objOrder.Apttus_Config2__SoldToAccountId__c);
				setUCAccIds.add(objOrder.Ultimate_Consignee__c);
                if(objOrder.ASOP_Number_Link__c != null) {
                	orderIdToASOPOrderId.put(objOrder.Id, objOrder.ASOP_Number_Link__c);
                }
                if(objOrder.Contact_Email__c != null) {
                    contactEmailToIDs.put(objOrder.Contact_Email__c, new List<Id>());
                }
            } 
            
            for(Contract_Order_Routing_Sheet__c objCORS : new CORSSelector().selectCORSForOrders(orderIdToASOPOrderId.values()))
            {
                orderIDToCORSObj.put(objCORS.Order__c, objCORS);
            }
            //for(Account objAccount : new AccountsSelector().selectAccounts(setUCAccIds)){
			// Added for INC0317567 . The query is moved directly as 'FOR UPDATE' keyword.
			for(Account objAccount : [select id,name,Territory_Region__c,District__c from account where id in:setUCAccIds FOR UPDATE]) {		
				idToAccount.put(objAccount.Id,objAccount);
				
			}
            for(Contact objCon : new ContactsSelector().selectContactsByEmail(contactEmailToIDs.keySet())) {
                contactEmailToIDs.get(objCon.Email).add(objCon.Id);
            } 
			queueToId.put(STRING_CS_AMR_QUEUE,System.Label.CSAMRCustomerServiceQueueId);
            // POL-18 AC9 keywords replaced from APJ to AMEA 
			queueToId.put(STRING_CS_AMEA_QUEUE,System.Label.CSAMEACustomerServiceQueueId); 
            // POL-18 AC9 keywords replaced from EMEA to EUR
			queueToId.put(STRING_CS_EUR_QUEUE,System.Label.CSEURCustomerServiceQueueId);
			queueToId.put(STRING_CS_GC_QUEUE,System.Label.CSGCCustomerServiceQueueId);
			
			
			Map<Id,Map<String,Account_to_Field_Support__c>> mapAccFieldSupport = ServiceUtilityCollection.fetchAccountRoles(setAccIds, new Set<String>{STRING_LABEL_PARTNER_PRIMARY_FSE, STRING_LABEL_PRIMARY_FSE});
            String subject='';
         
    		for(Id idApptusOrder: orderIdToLstOrderLineItems.keySet()) {                
                objApptusOrder = orderIdToOrderObj.get(idApptusOrder);
                
                Contract_Order_Routing_Sheet__c objCORS = orderIDToCORSObj.get(orderIdToASOPOrderId.get(idApptusOrder));
                for(Apttus_Config2__OrderLineItem__c objOrderLineItem : orderIdToLstOrderLineItems.get(idApptusOrder)) {
                    if(productIdToRecord.containsKey(objOrderLineItem.Apttus_Config2__ProductId__c) && objOrderLineItem.Trade_In_Indicator__c != 'A' && objOrderLineItem.Trade_In_Indicator__c != 'C'){
                        //case creation logic -DCP-34287
						if(!idToAccount.isEmpty()&&idToAccount.containsKey(objApptusOrder.Ultimate_Consignee__c)) {
							subject+=idToAccount.get(objApptusOrder.Ultimate_Consignee__c).Name+' ';
						}
						if(!productIdToRecord.isEmpty()&&productIdToRecord.containsKey(objOrderLineItem.Apttus_Config2__ProductId__c)) {
							subject+=productIdToRecord.get(objOrderLineItem.Apttus_Config2__ProductId__c).Name+' ';
						}
						if(!String.isblank(objApptusOrder.Apttus_Config2__OrderReferenceNumber__c)) {
							subject+=('Install Order '+objApptusOrder.Apttus_Config2__OrderReferenceNumber__c);
						}
						for(Integer i = 0 ;i < orderLineItemToQuantityChange.get(objOrderLineItem.Id) ; i++) {
                            //case creation logic for internal wo.
                            //DCP-51484 [No CP WOs should have an associated SR case]
                            ilib_LogEvent.info('objOrderLineItem.Apttus_Config2__ProductId__r  '+objOrderLineItem.Apttus_Config2__ProductId__r);
                            if (objApptusOrder.Ultimate_Consignee__c != NULL && (productIdToRecord.get(objOrderLineItem.Apttus_Config2__ProductId__c).Auto_Create_Installation_Workflow__c == AUTO_CREATE_SR_CASE || productIdToRecord.get(objOrderLineItem.Apttus_Config2__ProductId__c).Auto_Create_Installation_Workflow__c == AUTO_CREATE_INSTALL_WO_SR_CASE)) { //CMCM-1662
                                Case objCase = createInstallationWorkOrdersCaseInstance(objOrderLineItem , objApptusOrder , subject, mapAccFieldSupport);
                                orderItemIdToCase.put(objOrderLineItem.id+'-'+i,objCase);
                            }
                            if ((productIdToRecord.get(objOrderLineItem.Apttus_Config2__ProductId__c).Auto_Create_Installation_Workflow__c == AUTO_CREATE_INSTALL_WO || productIdToRecord.get(objOrderLineItem.Apttus_Config2__ProductId__c).Auto_Create_Installation_Workflow__c == AUTO_CREATE_INSTALL_WO_SR_CASE) && mapOLIToSkipInstallationWOFlag.get(objOrderLineItem.Id)== false) {
                                SVMXC__Service_Order__c objWO = createInstallationWorkOrdersWOInstance(objOrderLineItem , objApptusOrder , subject , objCORS , mapAccFieldSupport);
                                orderItemIdToWo.put(objOrderLineItem.id+'-'+i,objWO);
                            }
                        }
						subject='';
                    }
                }
            }
			//case creation logic -DCP-34287
            if(!orderItemIdToCase.isEmpty()){
                Cases.createInstallServiceRequestCode = true;
				insert orderItemIdToCase.values();
                for(case caseRecord: orderItemIdToCase.values()){
					caseIdToCaseRecord.put(caseRecord.Id, caseRecord);
					//caseIdToAssociatedTitle.put(caseRecord.id,STRING_SER_REQUEST_CODE);
				}
			}
			// if(!caseIdToCaseRecord.isEmpty()){
			// 	Cases casesClass = new Cases(orderItemIdToCase.values());
            //     casesClass.createAssociatedCode(null, caseIdToCaseRecord);
            // }
			if(!orderItemIdToWo.isEmpty()){
                
                for(string orderId : orderItemIdToCase.keySet()){
                    if(orderItemIdToCase.containskey(orderId) && orderItemIdToWo.containskey(orderId)){
                         SVMXC__Service_Order__c wo =orderItemIdToWo.get(orderId);
                        wo.Svmxc__case__c = orderItemIdToCase.get(orderId).id;
                   }
                }
				insert orderItemIdToWo.values();
            }
			
        }catch(Exception ex){
            ilib_LogEvent.info('## Exception : ' + ex.getStackTraceString());
			Database.rollback(sp);
            
           ApttusOrderLineItems.sendEmailWhenWOFails(objApptusOrder, ex,EMAIL_TEMPLATE_NAME_INSTALLATION); // DCP-47704
        
        }
    }    
    /**
    *  @author Nidhi
    *  @description - Create Case Instance
    *  @parameters : objOrderLineItem , objApptusOrder , subject
    *  @return : case
    **/
    public static case createInstallationWorkOrdersCaseInstance(Apttus_Config2__OrderLineItem__c objOrderLineItem , Apttus_Config2__Order__c objApptusOrder , String subject, Map<Id,Map<String,Account_to_Field_Support__c>> mapAccFieldSupport) {
    
        case objCase = new case();
        objCase.status = STRING_CASE_INITIATED_STATUS;
        objCase.Origin = STRING_CASE_ORIGIN_AUTO_GENERATED;
        objCase.Sub_Type__c = STRING_CASE_SUB_TYPE_SERVICE_SUPPORT;
        objCase.RecordTypeId = SERVICE_REQUEST_ISSUE_CASE_RECORDTYPE;
        objCase.SVMXC__Product__c = objOrderLineItem.Apttus_Config2__ProductId__c;
        objCase.subject = subject;
        objCase.Description = subject;
        objCase.Next_Steps__c = Label.Case_Next_Steps_Description.equalsIgnoreCase('None') ? '' : Label.Case_Next_Steps_Description ;
        if(objApptusOrder.Ultimate_Consignee__c != null) {
            objCase.AccountId = objApptusOrder.Ultimate_Consignee__c;
        }
        if(contactEmailToIDs != null && contactEmailToIDs.containsKey(objApptusOrder.Contact_Email__c) && contactEmailToIDs.get(objApptusOrder.Contact_Email__c).size() == 1) {
            objCase.ContactId = contactEmailToIDs.get(objApptusOrder.Contact_Email__c)[0];
        }
        if(!idToAccount.isEmpty()&&idToAccount.containsKey(objApptusOrder.Ultimate_Consignee__c)) {
            objCase.Region__c = idToAccount.get(objApptusOrder.Ultimate_Consignee__c).Territory_Region__c;
            objCase.District__c = idToAccount.get(objApptusOrder.Ultimate_Consignee__c).District__c;
            if(String.IsBlank(objApptusOrder.Ultimate_Consignee__r.VAD_Channel_Partner_Territory__c) ){ //Added by Vishal for CMCM-9451
                if(idToAccount.get(objApptusOrder.Ultimate_Consignee__c).Territory_Region__c == AMR) {
                    objCase.ownerid = queueToId.get(STRING_CS_AMR_QUEUE);
                }
                else if(idToAccount.get(objApptusOrder.Ultimate_Consignee__c).Territory_Region__c == AMEA) {
                    objCase.ownerid = queueToId.get(STRING_CS_AMEA_QUEUE);
                    
                }
                else if(idToAccount.get(objApptusOrder.Ultimate_Consignee__c).Territory_Region__c == EUR) {
                    objCase.ownerid = queueToId.get(STRING_CS_EUR_QUEUE);
                }
                else if(idToAccount.get(objApptusOrder.Ultimate_Consignee__c).Territory_Region__c == CHINA) {
                    objCase.ownerid = queueToId.get(STRING_CS_GC_QUEUE);
                }
            }else { //Added by Vishal for CMCM-9451
                if (mapAccFieldSupport != null && mapAccFieldSupport.containsKey(objApptusOrder.Apttus_Config2__SoldToAccountId__c)){
                    if(mapAccFieldSupport.get(objApptusOrder.Apttus_Config2__SoldToAccountId__c).containsKey(STRING_LABEL_PARTNER_PRIMARY_FSE)){
                        objCase.ownerId = mapAccFieldSupport.get(objApptusOrder.Apttus_Config2__SoldToAccountId__c).get(STRING_LABEL_PARTNER_PRIMARY_FSE).User__r.SVMXC__Salesforce_User__c;
                    }else if(mapAccFieldSupport.get(objApptusOrder.Apttus_Config2__SoldToAccountId__c).containsKey(STRING_LABEL_PRIMARY_FSE)){
                        objCase.ownerId = mapAccFieldSupport.get(objApptusOrder.Apttus_Config2__SoldToAccountId__c).get(STRING_LABEL_PRIMARY_FSE).User__r.SVMXC__Salesforce_User__c;
                    }
                }
            }
    }
        return objCase;        
    }
    /**
    *  @author Nidhi
    *  @description - Create work Order Instance
    *  @parameters : objOrderLineItem , objApptusOrder , subject
    *  @return : case
    **/
    public static SVMXC__Service_Order__c createInstallationWorkOrdersWOInstance(Apttus_Config2__OrderLineItem__c objOrderLineItem, Apttus_Config2__Order__c objApptusOrder, String subject, Contract_Order_Routing_Sheet__c objCORS, Map<Id,Map<String,Account_to_Field_Support__c>> mapAccFieldSupport) {
        SVMXC__Service_Order__c objWO = new SVMXC__Service_Order__c();
        assignBasicWorkOrderDetails(objWO, objOrderLineItem, objApptusOrder, subject, objCORS);
    
        if (shouldSetPartnerInstallation(objApptusOrder)) {
            setPartnerInstallationDetails(objWO, objApptusOrder, mapAccFieldSupport);
        }
    
        if (isQualificationRequired(objOrderLineItem)) {
            setQualificationRequirements(objWO);
        }
    
        // Non-conditional assignments
        objWO.ERP_Order_Number__c = objApptusOrder.Apttus_Config2__OrderReferenceNumber__c;
        objWO.ERP_Order_Line_Number__c = objOrderLineItem.ERP_Line_Number_Id__c;
        objWO.ERP_Order_Line_Quantity__c = objOrderLineItem.Apttus_Config2__Quantity__c;
        objWO.Is_Auto_Dispatch__c = false; // Simplified as per original logic
        objWO.Is_Auto_Created__c = true; // To bypass validation for preventing manual creation of Work Order - DCP-14702
    
        return objWO;
    }
    /**
    *  @author Nidhi
    *  @description - Create work Order Instance(helper method to fix n path complexity)
    *  @parameters : objWO , objOrderLineItem ,objApptusOrder, subject,objCORS
    *  @return : case
    **/
    private static void assignBasicWorkOrderDetails(SVMXC__Service_Order__c objWO, Apttus_Config2__OrderLineItem__c objOrderLineItem, Apttus_Config2__Order__c objApptusOrder, String subject, Contract_Order_Routing_Sheet__c objCORS) {
        objWO.SVMXC__Order_Type__c = STRING_WORK_ORDER_TYPE_INSTALLATION;
        objWO.Opportunity__c = objApptusOrder.Apttus_Config2__RelatedOpportunityId__c;
        objWO.Apttus_Sales_Order__c = objApptusOrder.Id;
        objWO.ERP_Ship_Date__c = objOrderLineItem.Actual_Ship_Date__c;
        objWO.ERP_Delivery_Date__c = objOrderLineItem.Estimated_Delivery_Date__c;
        objWO.SVMXC__Order_Status__c = System.Label.WorkOrderStatusAssigned;
        objWo.SVMX_PS_Subject__c = subject;
        objWO.Acceptance_Code__c = objOrderLineItem.Material_Group_5__c; // DCP-47698
        if (objCORS != null) {
            objWO.Acceptance_Criteria__c = objCORS.Letter_Of_Acceptance_Notes__c;
        }
        objWO.SVMXC__Company__c = objApptusOrder.Ultimate_Consignee__c;
        if (contactEmailToIDs != null && contactEmailToIDs.containsKey(objApptusOrder.Contact_Email__c) && contactEmailToIDs.get(objApptusOrder.Contact_Email__c).size() == 1) {
            objWO.SVMXC__Contact__c = contactEmailToIDs.get(objApptusOrder.Contact_Email__c)[0];
        }
        objWO.SVMXC__Product__c = objOrderLineItem.Apttus_Config2__ProductId__c;
    }
     /**
    *  @author Nidhi
    *  @description - Create work Order Instance(helper method to fix n path complexity)
    *  @parameters : objApptusOrder
    *  @return : case
    **/
    private static boolean shouldSetPartnerInstallation(Apttus_Config2__Order__c objApptusOrder) {
        return objApptusOrder.Ultimate_Consignee__c != null && String.IsNotBlank(objApptusOrder.Ultimate_Consignee__r.VAD_Channel_Partner_Territory__c);
    }
    /**
    *  @author Nidhi
    *  @description - Create work Order Instance(helper method to fix n path complexity)
    *  @parameters : objWO, objApptusOrder, mapAccFieldSupport
    *  @return : case
    **/
    private static void setPartnerInstallationDetails(SVMXC__Service_Order__c objWO, Apttus_Config2__Order__c objApptusOrder, Map<Id,Map<String,Account_to_Field_Support__c>> mapAccFieldSupport) {
        objWO.Partner_Installation_WO__c = true;
        objWO.SVMXC__Order_Status__c = STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED;
        if (mapAccFieldSupport.containsKey(objApptusOrder.Apttus_Config2__SoldToAccountId__c) && mapAccFieldSupport.get(objApptusOrder.Apttus_Config2__SoldToAccountId__c).containsKey(STRING_LABEL_PARTNER_PRIMARY_FSE)) {
            objWO.SVMXC__Group_Member__c = mapAccFieldSupport.get(objApptusOrder.Apttus_Config2__SoldToAccountId__c).get(STRING_LABEL_PARTNER_PRIMARY_FSE).User__c;
            objWO.ownerId = mapAccFieldSupport.get(objApptusOrder.Apttus_Config2__SoldToAccountId__c).get(STRING_LABEL_PARTNER_PRIMARY_FSE).User__r.SVMXC__Salesforce_User__c;
        }
    }
    /**
    *  @author Nidhi
    *  @description - Create work Order Instance(helper method to fix n path complexity)
    *  @parameters : objOrderLineItem
    *  @return : case
    **/
    private static boolean isQualificationRequired(Apttus_Config2__OrderLineItem__c objOrderLineItem) {
        return productIdToRecord.get(objOrderLineItem.Apttus_Config2__ProductId__c).Regulatory_Type__c != null && 
               (productIdToRecord.get(objOrderLineItem.Apttus_Config2__ProductId__c).Regulatory_Type__c.contains(STRING_PRODUCT_REGULATORY_TYPE_DX) || 
                STRING_PRODUCT_REGULATORY_TYPE_EUA.equals(productIdToRecord.get(objOrderLineItem.Apttus_Config2__ProductId__c).Regulatory_Type__c));
    }
    /**
    *  @author Nidhi
    *  @description - Create work Order Instance(helper method to fix n path complexity)
    *  @parameters : objWO, objOrderLineItem
    *  @return : case
    **/
    private static void setQualificationRequirements(SVMXC__Service_Order__c objWO) {
        String qrValue = STRING_QUAL_REQ_IQ_OQ + SEMICOLON + STRING_QUAL_REQ_PQ;
        objWO.Qualification_Requirements__c = String.isBlank(objWO.Qualification_Requirements__c) ? qrValue : objWO.Qualification_Requirements__c + SEMICOLON + qrValue;
    }
    
    /*
    * @Description- An email notification is sent when Work Order fails to be created for new instrument orders.
    * @param - Apttus_Config2__Order__cobject
    * @return - Messaging.SingleEmailMessage
    * @User Story - DCP-47704
    */
    public static void  sendEmailWhenWOFails(Apttus_Config2__Order__c objApptusOrder,Exception ex, String emailTemplate){
            String woType = '';
            if(emailTemplate == EMAIL_TEMPLATE_NAME_INSTALLATION){
                woType = 'Install WO';
            }else{
                woType = 'EOL WO';
            }
            //added for INC0220064
			//added null check for INC0325829
            if(objApptusOrder != null){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddress = new String[]{System.Label.WorkOrderFailureEmail};
                EmailTemplatesSelector emailTemplateSlctr = new EmailTemplatesSelector();
                List<EmailTemplate> lstEmailTemplate = emailTemplateSlctr.selectByNameOrDeveloperName(new List<String> {emailTemplate});

                //TASK1037157:query Contact- Dummy Contact
                Contact objDummyContact = null;
                try{
                    objDummyContact = [select Id from Contact where Name = :CONTACT_NAME and Is_Active__c = true limit 1];
                    ilib_LogEvent.info('objDummyContact found : '+objDummyContact);
                } 
                catch(QueryException queryException) {
                    ilib_LogEvent.info('Dummy contact not found, using random contact instead');
                    ApexExceptions.emit(LOG_TITLE, 'Dummy contact not found, using random contact instead',ilib_LogEvent.SERVICE);
                    objDummyContact = [select Id from Contact where Is_Active__c = true limit 1];
                }

                ApexExceptions.emit(woType+' failed to Create!!',objApptusOrder.Id,ex);
                mail.setTemplateId(lstEmailTemplate[0].Id);
                mail.setToAddresses(toAddress);
                mail.setTargetObjectId(objDummyContact.id);
                mail.setWhatId(objApptusOrder.id);
                mail.setSaveAsActivity(false);

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
 
            }
            else{	
                ApexExceptions.emit(woType+' failed to Create without OrderId!!',ex);
            }
    }   

    
    
    /**
    *  @author Ritika M
    *  @description - Cancel Work Orders
    *  @parameters : setOrderLineNumberCanceled: set of order line items which have been deleted.
    *  @return : void
    **/
    private static void cancelWorkOrders(Set<String> setOrderLineNumberCanceled){
        List<SVMXC__Service_Order__c> lstInstallWOToBeCanceled = new List<SVMXC__Service_Order__c>();
        
        for(SVMXC__Service_Order__c objWO : new WorkOrdersSelector().selectWorkOrdersForOrderLineNumber(setOrderLineNumberCanceled))
        {
			objWo.svmxc__case__C=null;
            objWO.SVMXC__Order_Status__c = STRING_WORK_ORDER_STATUS_CANCELED;
            lstInstallWOToBeCanceled.add(objWO);
        }
        
        if(!lstInstallWOToBeCanceled.isEmpty()){
            update lstInstallWOToBeCanceled;
        }
    }

    /*
    * @Author: 
    * @Description : wrapper class
    */   
	public class OLIWrapper{
        public Map<Apttus_Config2__OrderLineItem__c,String> mapOLIObjToProdCode;
        public Set<String> setHamiltonProdCode;
        public Map< String , Installed_Product_Creation_Config__mdt > mapHamilton;
        
        OLIWrapper(Map<Apttus_Config2__OrderLineItem__c,String> mapOLIObjToProdCode, Set<String> setHamiltonProdCode, Map< String , Installed_Product_Creation_Config__mdt > mapHamilton){
            this.mapOLIObjToProdCode = mapOLIObjToProdCode;
            this.setHamiltonProdCode = setHamiltonProdCode;
            this.mapHamilton = mapHamilton;      
        }
    }

    /*******************************************************************************************************
    * @description DCP-51266 Relocation Orders should not generate Install Work Orders
    * @param newList new List of OLI records
    * @param oldMap old records Map (if Insert event then null)
    * @return Map<Id, Apttus_Config2__Order__c> orderMap
    * @example
    */
    private Map<Id, Apttus_Config2__Order__c> populateOrderMap(List<Apttus_Config2__OrderLineItem__c> newList) {
        Set<Id> orderIds = new Set<Id> ();
        Map<Id, Apttus_Config2__Order__c> orderMap = new Map<Id, Apttus_Config2__Order__c>();

        for(Apttus_Config2__OrderLineItem__c oliRec : newList) {
            orderIds.add(oliRec.Apttus_Config2__OrderId__c);
        }
        orderMap = new Map<Id, Apttus_Config2__Order__c> (new ApttusOrdersSelector().selectOrdersByIds(orderIds));
        return orderMap;
    }

    /**
     *  @author Gladis
     *  @description    Added as a sepearate method to avoid Npath codescan issues
     *                  DCP-45368 Method to check updation of Equipment Id and Enqueue Job.
     *  @return Set<Id>
    **/
    private Set<Id> checkForOLIEquipmentIDChange(Map<Id, SObject> existingRecords) {
        ilib_LogEvent.push(LOG_TITLE + '.checkForOLIEquipmentIDChange()');
        ilib_LogEvent.info('45368-existingRecords in checkForOLIEquipmentIDChange method-->'+existingRecords);
        Set<Id> setOrderLineItemIds = new Set<Id>();
        
        try {
            for(Apttus_Config2__OrderLineItem__c objOrderLineItem : (List<Apttus_Config2__OrderLineItem__c>)records) {
                Apttus_Config2__OrderLineItem__c objOldOrderLineItem = (Apttus_Config2__OrderLineItem__c)existingRecords.get(objOrderLineItem.Id); 
                if(!string.isBlank(objOrderLineItem.Equipment_Id__c) && objOrderLineItem.Equipment_Id__c!=objOldOrderLineItem.Equipment_Id__c) {
                    setOrderLineItemIds.add(objOrderLineItem.Id);
                }
            }
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        ilib_LogEvent.info('45368-setOrderLineItemIds-->'+setOrderLineItemIds);
        return setOrderLineItemIds;    
    }
    /**
     *  @author Gladis
     *  @description DCP-45368 Called from ApttusOrderLineItemQueueable.
     *               Method to get Equipment Id on OrderLineItem and map Installed Prodcut to Case.
     *  @return void
    **/
    public static void mapInstalledProductToCase(Set<Id> setOrderLineItemIds) {
        ilib_LogEvent.push(LOG_TITLE + '.mapInstalledProductToCase()');
        ilib_LogEvent.info('45368-setOrderLineItemIds in mapInstalledProductToCase method-->'+setOrderLineItemIds);
        Set<String> setEquipmentIds = new Set<String>();
        List<Case> lstCasesWithIP = new List<Case>();
        Set<Id> setCaseIds = new Set<Id>();
        Map<String,String> mapOLIInstalledProduct = new Map<String,String>();
        Map<String,String> mapOLICase = new Map<String,String>();

        try {
            for(Apttus_Config2__OrderLineItem__c objOrderLineItemRecord: new ApttusOrderLineItemsSelector().fetchCasebyOrderLineItemId(setOrderLineItemIds)) {
                if(String.isnotblank(objOrderLineItemRecord.Equipment_Id__c)) {
                    setEquipmentIds.add(objOrderLineItemRecord.Equipment_Id__c); 
                }
                if(!string.isBlank(objOrderLineItemRecord.Case_Id__c)) {
                    setCaseIds.add(objOrderLineItemRecord.Case_Id__c);
                    mapOLICase.put(objOrderLineItemRecord.Case_Id__c, objOrderLineItemRecord.Equipment_Id__c);
                }
            }
            mapOLIInstalledProduct = fetchIPFromOLI(setEquipmentIds);
            for(Case objCaseRecord: new CasesSelector().fetchCaseWithNullIPIds(setCaseIds)) {
                ilib_LogEvent.info('45368-objCaseRecord -->'+objCaseRecord);
                if(objCaseRecord.SVMXC__Component__c == null && mapOLICase.containsKey(objCaseRecord.Id)) {
                    objCaseRecord.SVMXC__Component__c = mapIPToCase(mapOLIInstalledProduct, mapOLICase.get(objCaseRecord.Id));
                    lstCasesWithIP.add(objCaseRecord);
                }
            }
            ilib_LogEvent.info('45368-lstCasesWithIP -->'+lstCasesWithIP);
            if(!lstCasesWithIP.isEmpty()){
                update lstCasesWithIP;
                ilib_LogEvent.info('45368-updated lstCasesWithIP -->'+lstCasesWithIP);
            }
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
     *  @author Gladis
     *  @description    Added as a sepearate method to avoid Npath codescan issues
     *                  DCP-45368 Method to fetch Installed Product Id from Order Line Item
     *  @return String
    **/
    private static Map<String,String> fetchIPFromOLI(Set<String> setEquipmentIds) {
        ilib_LogEvent.push(LOG_TITLE + '.fetchIPFromOLI()');
        ilib_LogEvent.info('45368-setEquipmentIds in fetchIPFromOLI method-->'+setEquipmentIds);
        Map<String,String> mapOLIInstalledProduct = new Map<String,String>();
        try {
            List<SVMXC__Installed_Product__c> lstInstalledProduct =  new InstalledProductsSelector().selectInstalledProductsFromEquipmentId(setEquipmentIds);
            for(SVMXC__Installed_Product__c objIP: lstInstalledProduct) {
                ilib_LogEvent.info('45368-lstInstalledProduct-->'+lstInstalledProduct);
                if(setEquipmentIds.contains(objIP.ERP_Equipment_ID__c)) {
                    mapOLIInstalledProduct.put(objIP.ERP_Equipment_ID__c, objIP.Id);
                }
            }
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        ilib_LogEvent.info('45368-mapOLIInstalledProduct-->'+mapOLIInstalledProduct);
        return mapOLIInstalledProduct;
    }

    /*  @AUTHOR - Gladis
    *  @RETURN - String
    *  @DESCRIPTION - DCP-45368 method to get Installed Product Id from given Equipment Id and to map to Case's IP.
    **/
    private static String mapIPToCase(Map<String, String> mapOLIInstalledProduct, String equipmentId) {
        ilib_LogEvent.push(LOG_TITLE + '.mapIPToCase()');
        ilib_LogEvent.info('45368-mapOLIInstalledProduct in mapIPToCase method-->'+mapOLIInstalledProduct);
        ilib_LogEvent.info('45368-equipmentId in mapIPToCase method-->'+equipmentId);
        String strInstalledProductId = null;
        if(mapOLIInstalledProduct.containsKey(equipmentId)) {
            strInstalledProductId = mapOLIInstalledProduct.get(equipmentId);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        ilib_LogEvent.info('45368-strInstalledProductId -->'+strInstalledProductId);
        return strInstalledProductId;
    }
}
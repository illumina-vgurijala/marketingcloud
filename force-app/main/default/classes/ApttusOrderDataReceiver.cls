/*
* @Author: Sravan Panchangam
* @Date :10/08/2018
* @Description : DCP-13048 SalesOrderSyncInterface : This Inteface will accept the order and orderlineitems  from external systems and save those records in sfdc
* --------------------------------------------------------------------------------------------------------------------------------------
 * Developer             Date                Description
 * Rahul Bishnoi         07-Jan-2020         DCP-32561 : Asset line item sync: Informatics
 * Rahul Bishnoi         16-Jan-2020         DCP-31268 : Lookup Fields of Order Line item updated: Informatics
 * Kushagra Desai        29-Nov-2019         DCP-31270 : Asset line item sync: Informatics 
 * Rahul Bishnoi         07-Jan-2020         DCP-32561 : Asset line item sync: Informatics
 * Rahul Bishnoi         16-Jan-2020         DCP-31268 : Lookup Fields of Order Line item updated: Informatics
 * Gopinath Reddy        12-Feb-2020         DCP-32166 : Case Creation Queueble 
 * Joshith K             07-May-2020         PRB0043542- throw exception if JSON invalid
 * Todd                  19-Jun-2020         INC0275048: removing quote line check since quote line is sometimes blank
 * Ashwin Kumar          18-Oct-2021         INC0351626: Added missing null check from the previous Incident change 
 * Koustubh M            24-Feb-2022         INC0378142: Created new instance to update order line item. Update the order line item only if a change was made.
 * Anand Palla           26-Apr-2022         CodeScan Fix-Avoid Literals in If condition
 * Sagar Madkaikar       22-Jun-2022         DCP-45368 :  Added Queuable Manager THread to Enqueue Jobs
 * Iram Malik			 04-Jul-2022		 CodeScan Fix-Avoid Literals in If condition
 * Koustubh M            2022-03-28          TASK0730598: Used header level asset activation 
 * JItesh Lakhwani       21-Feb-2023         Codescan resolution - Avoid unused variable
 * ---------------------------------------------------------------------------------------------------------------------------------------
 */
@RestResource(urlMapping='/SalesOrderSyncInterface/')
global with Sharing class ApttusOrderDataReceiver extends ilib_RestReceiver {
    
    public static ApttusOrderWrapper.Order objOrderWrapper;
    //START CodeScan Fix [Avoid Literals in If condition]
    public static final String EXECUTE = 'execute';
    //END CodeScan Fix

    private static final String CASE_CREATION_QUEUEABLE = 'CaseCreationQueueable';//DCP-45368
    private static final String LEAD_CONTACT_QUEUEABLE = 'PopulateLeadContactPguidQueueable';
    private static ilib_LogInterface.LogDetails logInt;
    private static final String LOG_TITLE = 'ApttusOrderDataReceiver';
    private static Id primaryRecordId;
    private static String erpCustomerId;
    private static Boolean boolOrderDoesNotExist;

    /**
	* @description   method to deserialize json coming from external system so that it can be stored in sfdc
	* @params NA
	* @return void
	**/
    @Httppost
    global static void upsertIncomingValues()
    {        
        // instantiate this class so that base class logic is available
        ApttusOrderDataReceiver instantiated = new ApttusOrderDataReceiver();
        // get the (non-static context) details
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push('upsertIncomingValues');
        String strRestError = null;

        String strJsonInput = (String.isNotBlank(RestContext.request.requestBody.toString()) ? RestContext.request.requestBody.toString() : null);
        ilib_LogEvent.message('JSON Input:\n'+strJsonInput);

        logInt = ilib_LogInterface.initiateLog(interfaceDetails, strJsonInput);
        
        try
        {
            processIncomingValues(strJsonInput,instantiated);
        }
        catch (Exception e){
            strRestError = UtilsRest.handleCustomRestError(e);
        }
        
        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
            logInt,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, logInt.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
        }
        ilib_LogEvent.pop();
        ilib_logEvent.emit();
    }

    /**
     * @Author: Sravan Panchangam
     * @Description : Deserializes the incoming jsonInput from the external source and wraps the values accordingly to their Objects
     */
    private static void deserializeInputs(String jsonInput)
    {
        ilib_LogEvent.push('deserializeInputs');
        objOrderWrapper=(ApttusOrderWrapper.Order)System.JSON.deserialize(jsonInput, ApttusOrderWrapper.Order.class);
        ilib_LogEvent.message('ApttusOrderWrapper Updated::::'+objOrderWrapper);
        ilib_LogEvent.pop();
    }

    /**
     * For Order Lookups that part will be handled in the ApttusOrdersTrigger during before insert and update
     * For Order line items the lookups are populated below
     */
    public static Id upsertIncomingValuesImpl()
    {
        ilib_LogEvent.push('upsertIncomingValuesImpl');
        
        //Following maps are used for populating the lookup for the order line items
        Map<String,List<Apttus_Config2__OrderLineItem__c>> quoteToOLItems=new Map<String,List<Apttus_Config2__OrderLineItem__c>>();

        //Following map is used fot setting some fields for orderline items that donot have quote reference
        Map<String,List<Apttus_Config2__OrderLineItem__c>> quoteToOLItemsFieldUpdate=new Map<String,List<Apttus_Config2__OrderLineItem__c>>();
        ilib_SObjectUnitOfWork objUnitOfWork=new ilib_SObjectUnitOfWork(new List<Schema.SObjectType> { Apttus_Config2__Order__c.SObjectType, Apttus_Config2__OrderLineItem__c.SObjectType});
        
        Map<String, Apttus_Config2__Order__c> asopToOrder =new Map<String, Apttus_Config2__Order__c>();
        Map<String, Apttus_Config2__Order__c> salesOrderUniqueToOrder =new Map<String, Apttus_Config2__Order__c>();
        Map<String,List<Apttus_Config2__OrderLineItem__c>> serviceProductToOLItems=new Map<String,List<Apttus_Config2__OrderLineItem__c>>();
        Map<String,List<Apttus_Config2__OrderLineItem__c>> contactPguidToOrderLineItems = new Map<String,List<Apttus_Config2__OrderLineItem__c>>();
        Map<String,List<Apttus_Config2__OrderLineItem__c>> leadPguidToOrderLineItems = new Map<String,List<Apttus_Config2__OrderLineItem__c>>();
        Set<String>  pguidSet = new Set<String>();
        //Map<String,List<Apttus_Config2__OrderLineItem__c>> asopToOrderLineItems =new  Map<String,List<Apttus_Config2__OrderLineItem__c>>();
        Map<String,List<Apttus_Config2__OrderLineItem__c>> salesOrderToOrderLineItems =new  Map<String,List<Apttus_Config2__OrderLineItem__c>>();
        Set<String> setERPLineNumber = new Set<String>();
        //DCP-45368: Adding Queuable thread
        ilib_Queueablethread  queueableThread=new ilib_Queueablethread('CaseCreationQueueable');
        ilib_Queueablethread queueableThreadPguid = new ilib_Queueablethread(LEAD_CONTACT_QUEUEABLE);
            Apttus_Config2__Order__c apttusOrderSObject=objOrderWrapper.getSObject();
            if(String.isNotBlank(objOrderWrapper.ASOP_Number)){
                asopToOrder.put(objOrderWrapper.ASOP_Number,apttusOrderSObject);
            }
            
        Map<String,Apttus_Config2__OrderLineItem__c> oliMap = new Map<String,Apttus_Config2__OrderLineItem__c>();
        boolOrderDoesNotExist = true; //indicates whether the operation is insert or update

        //populate ASOP number lookup
        if(String.isNotBlank(objOrderWrapper.ASOP_Number)){
            asopToOrder.put(objOrderWrapper.ASOP_Number,apttusOrderSObject);
        }
        
        //Query OLI based on Sales order number of order and populate map
        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItem =new Map<Id, Apttus_Config2__OrderLineItem__c>(new ApttusOrderLineItemsSelector().fetchLinesBySalesOrderNumber(new set<String>{apttusOrderSObject.Sales_Order_Number_Unique__c}));

        //Register order for DML 
        salesOrderUniqueToOrder.put(apttusOrderSObject.Sales_Order_Number_Unique__c, apttusOrderSObject);
        registerOrderForDml(idToOrderLineItem,objUnitOfWork,apttusOrderSObject);

        oliMap = (Map<String, Apttus_Config2__OrderLineItem__c>)UtilsCollection.getMapOfStringToSObject(idToOrderLineItem.values(),'ERP_Line_Number_Id__c',Map<String, Apttus_Config2__OrderLineItem__c>.class);

        registerOrderLineitemForDml(objUnitOfWork,apttusOrderSObject,oliMap,setERPLineNumber,salesOrderToOrderLineItems,quoteToOLItems,quoteToOLItemsFieldUpdate,contactPguidToOrderLineItems,leadPguidToOrderLineItems,serviceProductToOLItems,pguidSet);
        
        populateAsopLink(asopToOrder);
        populateServiceProductLink(serviceProductToOLItems);

        //Fetching the quotelineitem from the ApttusProposalLineItemsSelector to populate the ProposalLineitem for all the orderlineitems in the quoteToOLItems map
        set<String> setQuoteLineItem=quoteToOLItems.keySet();
        list<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems=setQuoteLineItem.isEmpty()?new list<Apttus_Proposal__Proposal_Line_Item__c>():new ApttusProposalLineItemsSelector().fetchQuoteLineItemId(setQuoteLineItem);
        //For updating the fields in order line items that do not have quote line reference
        set<String> setUpdateNewOLItems=new set<String>();
        set<String> oliWithoutReference=quoteToOLItemsFieldUpdate.keySet();
        List<Apttus_Config2__OrderLineItem__c> listOliWithoutRef= oliWithoutReference.isEmpty()?new list<Apttus_Config2__OrderLineItem__c>():quoteToOLItemsFieldUpdate.get(null);
        populateSetToUpdateNewOli(setUpdateNewOLItems,listOliWithoutRef,setQuoteLineItem,lstProposalLineItems,oliWithoutReference);
        populateProposalLineitemFields(lstProposalLineItems,quoteToOLItems);
        updateOliWithoutQuoteReference(setUpdateNewOLItems, quoteToOLItems, quoteToOLItemsFieldUpdate);

        Map<String,Id> erpLineNumberToAssetLineItemId = new Map<String,Id> ();
        Map<Id,String> assetLineItemIdToErpLineNumber = new Map<Id,String> ();
        Map<String, Apttus_Config2__OrderLineItem__c> erpLineNumberToOli = new Map<String, Apttus_Config2__OrderLineItem__c>();
        Map<String, Apttus_Config2__OrderLineItem__c> erpLineNumberToNewOliValues = new Map<String, Apttus_Config2__OrderLineItem__c>();
        
        Set<String> setSalesOrderToActivate = new Set<String>();

        populateSoAndAssetMaps(salesOrderToOrderLineItems, idToOrderLineItem, erpLineNumberToOli, setERPLineNumber, salesOrderUniqueToOrder, setSalesOrderToActivate, erpLineNumberToAssetLineItemId, assetLineItemIdToErpLineNumber, erpLineNumberToNewOliValues);

        businessRules(objUnitOfWork);
        ilib_LogEvent.message('ApttusOrderWrapper Updated::::'+objOrderWrapper);

        //Commit the registered work (order and OLI)
        objUnitOfWork.commitWork();

        if(!contactPguidToOrderLineItems.isEmpty() || !pguidSet.isEmpty()){
            PopulateLeadContactPguidQueueable queueableClassInstance = new PopulateLeadContactPguidQueueable(contactPguidToOrderLineItems, leadPguidToOrderLineItems, pguidSet);
            queueableThreadPguid.logAndQueue(queueableClassInstance, LEAD_CONTACT_QUEUEABLE, EXECUTE);
            ilib_QueueableManager.enqueueJob(queueableThreadPguid); 
        }

        //Do header level activation of asset in case (new order is inserted) or (order is not activated). 
        if(boolOrderDoesNotExist){//Can add conditions of checking 'no of order lines = no of activated lines'
            //The below function does header level activation (one order at a time). Suseel from conga confirmed this behaviour. He will have product team confirm the behaviour after capturing subscriber logs
            headerLevelActivationOfAssets(new Apttus_Config2__Order__c(Id=apttusOrderSObject.Id));
        }

        populateAliFields(assetLineItemIdToErpLineNumber, erpLineNumberToNewOliValues, erpLineNumberToOli, erpLineNumberToAssetLineItemId);

        //DCP-32166 - Calling queueable job to create case
        ilib_LogEvent.message('mysetofERPValues-->'+setERPLineNumber);
        if(!setERPLineNumber.isEmpty()){
            //DCP-45368 : Added Queuable Manager
            ilib_LogEvent.info('45368-setERPLineNumber -->'+setERPLineNumber);
            queueableThread.logandQueue(new CaseCreationQueueable(setERPLineNumber,0),CASE_CREATION_QUEUEABLE,CASE_CREATION_QUEUEABLE);
        }

        //DCP-45368 : Calling Queuable Manager Enqueue Jobs
        if(!queueableThread.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(queueableThread);
        }
        
        ilib_LogEvent.pop();
        return (apttusOrderSObject == null ? null:apttusOrderSObject.Id );
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation (works for only one order at a time.)
     * @Param Set<String> (setSalesOrderToActivate)
     * @return void
     */
    public static void headerLevelActivationOfAssets(Apttus_Config2__Order__c orderToActivate)
    {
        ilib_LogEvent.push('headerLevelActivation');    
        orderToActivate.Apttus_Config2__Status__c=Label.OpportunityDealRegStatusPending; 
        String todayDate=Datetime.now().format('yyyy-MM-dd 00:00:00');
        DateTime dtToday = Datetime.valueOf(todayDate); //timezone correction
        orderToActivate.Apttus_Config2__ActivatedDate__c = dtToday;
        update orderToActivate;
        ilib_LogEvent.message('orderToActivate:'+orderToActivate);
        ilib_LogEvent.pop();
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation. Populate list and map required for further use 
     * @return void
     */
    public static void populateSalesOrderToOliMap(Apttus_Config2__OrderLineItem__c oliSObject,Apttus_Config2__Order__c apttusOrderSObject, Set<String> setERPLineNumber,Map<String,List<Apttus_Config2__OrderLineItem__c>> salesOrderToOrderLineItems)
    {
        ilib_LogEvent.push('populateSalesOrderToOliMap');    
        //DCP-32166
        if(String.isNotBlank(oliSObject.ERP_Line_Number_Id__c)){
            setERPLineNumber.add(oliSObject.ERP_Line_Number_Id__c);
        }
        if(salesOrderToOrderLineItems.containsKey(apttusOrderSObject.Sales_Order_Number_Unique__c)){
            salesOrderToOrderLineItems.get(apttusOrderSObject.Sales_Order_Number_Unique__c).add(oliSObject);
        }else{
            salesOrderToOrderLineItems.put(apttusOrderSObject.Sales_Order_Number_Unique__c,new List<Apttus_Config2__OrderLineItem__c>{oliSObject});
        }

        ilib_LogEvent.message('salesOrderToOrderLineItems:'+salesOrderToOrderLineItems);
        ilib_LogEvent.pop();
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation. Populate set that collets Oli to update.
     * @return void
     */
    public static void populateSetToUpdateNewOli(set<String> setUpdateNewOLItems, List<Apttus_Config2__OrderLineItem__c> listOliWithoutRef, set<String> setQuoteLineItem, list<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems, set<String> oliWithoutReference){
        if(!listOliWithoutRef.isEmpty()){
            setUpdateNewOLItems.addAll(oliWithoutReference);
        }
        if(!setQuoteLineItem.isEmpty() && !lstProposalLineItems.isEmpty()){
            for(String quoteRefCheck:setQuoteLineItem){
                for(Apttus_Proposal__Proposal_Line_Item__c proposalLICheck : lstProposalLineItems){
                    String check=proposalLICheck.Name;
                    if(!check.equals(quoteRefCheck)){
                        setUpdateNewOLItems.add(quoteRefCheck);
                    }
                }
            }
        }
        else if(lstProposalLineItems.isEmpty()){
            setUpdateNewOLItems.addAll(setQuoteLineItem);
        }
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation. Populate fields of quote lineitems.
     * @return void
     */
    public static void populateProposalLineitemFields(list<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> quoteToOLItems){
        //Populate quote related fields
        if(lstProposalLineItems.isEmpty()){
            return;
        }
        for(Apttus_Proposal__Proposal_Line_Item__c objProposalLineItem:lstProposalLineItems){
            List<Apttus_Config2__OrderLineItem__c> lstOLIProposalUpdate=quoteToOLItems.get(objProposalLineItem.Name);
            Integer value=1;
            for(Apttus_Config2__OrderLineItem__c oliUpdate:lstOLIProposalUpdate){
                oliUpdate.Apttus_QPConfig__ProposalLineItemId__c=objProposalLineItem.Id;
                oliUpdate.Apttus_Config2__LineNumber__c=value;
                oliUpdate.Apttus_Config2__ItemSequence__c=1;
                oliUpdate.Apttus_Config2__LineType__c='Product/Service';
                oliUpdate.Apttus_Config2__PrimaryLineNumber__c=value;
                oliUpdate.Apttus_Config2__IsPrimaryLine__c=true;
                oliUpdate.Apttus_QPConfig__ProposalId__c=objProposalLineItem.Apttus_Proposal__Proposal__c;
                oliUpdate.Apttus_Config2__LineStatus__c=objProposalLineItem.Apttus_QPConfig__LineStatus__c;
                oliUpdate.Apttus_Config2__PriceType__c=Label.OrderLineItemPriceTypeRecurring;
                oliUpdate.Apttus_Config2__SellingFrequency__c=objProposalLineItem.Apttus_QPConfig__SellingFrequency__c;
                oliUpdate.Apttus_Config2__ChargeType__c=objProposalLineItem.Apttus_QPConfig__ChargeType__c;
                oliUpdate.Apttus_Config2__ParentBundleNumber__c=objProposalLineItem.Apttus_QPConfig__ParentBundleNumber__c;
                oliUpdate.Billing_Type__c=objProposalLineItem.Billing_Type__c;
                oliUpdate.Apttus_Config2__SellingTerm__c=objProposalLineItem.Apttus_QPConfig__SellingTerm__c;
                oliUpdate.Apttus_Config2__Quantity__c=objProposalLineItem.Apttus_QPConfig__Quantity2__c;
                value++;
            }
        }
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation. Update order lineitems that dont have reference to Quote.
     * @return void
     */
    public static void updateOliWithoutQuoteReference(set<String> setUpdateNewOLItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> quoteToOLItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> quoteToOLItemsFieldUpdate){
        //Updating the Order Line items that do not have Quote Reference available
        if(setUpdateNewOLItems.isEmpty()){
            return;
        } 
        List<Apttus_Config2__OrderLineItem__c> lstNewOLIProposalUpdate;
        for(String updateNewOLItems:setUpdateNewOLItems){
            lstNewOLIProposalUpdate = quoteToOLItems.containsKey(updateNewOLItems) ? quoteToOLItems.get(updateNewOLItems) : quoteToOLItemsFieldUpdate.get(updateNewOLItems);
            Integer assignedValue=1;
            if(lstNewOLIProposalUpdate==null){
                continue;
            }
            for(Apttus_Config2__OrderLineItem__c updateOLI:lstNewOLIProposalUpdate){
                updateOLI.Apttus_Config2__LineNumber__c=assignedValue;
                updateOLI.Apttus_Config2__ItemSequence__c=1;
                updateOLI.Apttus_Config2__LineType__c='Product/Service';
                updateOLI.Apttus_Config2__PrimaryLineNumber__c=assignedValue;
                updateOLI.Apttus_Config2__IsPrimaryLine__c=true;
                updateOLI.Apttus_Config2__LineStatus__c=Label.LineItemLineStatusNew;
                updateOLI.Apttus_Config2__PriceType__c=Label.OrderLineItemPriceTypeRecurring;
                assignedValue++;
            }
            
        }
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation. Populate maps required for further use.
     * @return void
     */
    public static void populateSoAndAssetMaps(Map<String,List<Apttus_Config2__OrderLineItem__c>> salesOrderToOrderLineItems,Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItem,Map<String, Apttus_Config2__OrderLineItem__c> erpLineNumberToOli,Set<String> setERPLineNumber,Map<String, Apttus_Config2__Order__c> salesOrderUniqueToOrder,Set<String> setSalesOrderToActivate,Map<String,Id> erpLineNumberToAssetLineItemId,Map<Id,String> assetLineItemIdToErpLineNumber,Map<String, Apttus_Config2__OrderLineItem__c> erpLineNumberToNewOliValues){
        ilib_LogEvent.push('populateSoAndAssetMaps');   
        if(salesOrderToOrderLineItems.isEmpty()){
            return;
        }
        ilib_LogEvent.message('salesOrderToOrderLineItems.keySet():'+salesOrderToOrderLineItems.keySet()+'Values'+salesOrderToOrderLineItems.Values());
        ilib_LogEvent.message('idToOrderLineItem::::'+idToOrderLineItem);
        for(Apttus_Config2__OrderLineItem__c oli : idToOrderLineItem.values()){
            if(oli.ERP_Line_Number_Id__c == null){
                continue;
            }
            erpLineNumberToOli.put(oli.ERP_Line_Number_Id__c,oli);
            //DCP-32166
            if(String.isBlank(oli.Case_Id__c)){
                continue;
            }
            ilib_LogEvent.message('My Case Id on OLI-->'+oli.Case_Id__c);
            setERPLineNumber.remove(oli.ERP_Line_Number_Id__c);
        }
        ilib_LogEvent.message('erpLineNumberToOli::::'+erpLineNumberToOli);
        for(String salesOrderValue: salesOrderUniqueToOrder.keySet()){
            Apttus_Config2__Order__c order = salesOrderUniqueToOrder.get(salesOrderValue);
            if(order.Apttus_Config2__Status__c == Label.OrderStatusCancelled){
                continue;
            }
            ilib_LogEvent.message('salesOrderToOrderLineItems.get(salesOrderValue)'+salesOrderValue+salesOrderToOrderLineItems);
            setSalesOrderToActivate.add(salesOrderValue);
            for(Apttus_Config2__OrderLineItem__c oliStatusUpdate: salesOrderToOrderLineItems.get(salesOrderValue)){
                if(erpLineNumberToOli.containsKey(oliStatusUpdate.ERP_Line_Number_Id__c) 
                    && erpLineNumberToOli.get(oliStatusUpdate.ERP_Line_Number_Id__c).Apttus_Config2__Status__c == Label.OrderLineItemStatusActivated)   {  
                    erpLineNumberToAssetLineItemId.put(oliStatusUpdate.ERP_Line_Number_Id__c, erpLineNumberToOli.get(oliStatusUpdate.ERP_Line_Number_Id__c).Apttus_Config2__AssetLineItemId__c);        
                    assetLineItemIdToErpLineNumber.put(erpLineNumberToOli.get(oliStatusUpdate.ERP_Line_Number_Id__c).Apttus_Config2__AssetLineItemId__c,oliStatusUpdate.ERP_Line_Number_Id__c);
                    erpLineNumberToNewOliValues.put(oliStatusUpdate.ERP_Line_Number_Id__c,oliStatusUpdate);
                }
            }
            ilib_LogEvent.message('setSalesOrderToActivate:'+setSalesOrderToActivate);
        }
        ilib_LogEvent.pop();
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation - Populate all the asset lineitem fields.
     * @return void
     */
    public static void populateAliFields(Map<Id,String> assetLineItemIdToErpLineNumber,Map<String, Apttus_Config2__OrderLineItem__c> erpLineNumberToNewOliValues,Map<String, Apttus_Config2__OrderLineItem__c> erpLineNumberToOli,Map<String,Id> erpLineNumberToAssetLineItemId){
        if(assetLineItemIdToErpLineNumber.IsEmpty() || erpLineNumberToNewOliValues.IsEmpty()){
            return;
        }
        ilib_LogEvent.push('populateAliFields');   
        //Populate asset fields
        List<Apttus_Config2__AssetLineItem__c> assetLineItems = new  List<Apttus_Config2__AssetLineItem__c> (new ApttusAssetLineItemsSelector().selectByAssetId(assetLineItemIdToErpLineNumber.keyset()));
        List<Apttus_Config2__AssetLineItem__c> updateAssetLineItems = new List<Apttus_Config2__AssetLineItem__c>();


        for(Apttus_Config2__AssetLineItem__c objAli : assetLineItems){
            Apttus_Config2__OrderLineItem__c objOrderLine = erpLineNumberToNewOliValues.get(assetLineItemIdToErpLineNumber.get(objAli.id));
            ilib_LogEvent.message('objOrderLine for asset copy: '+ objOrderLine);
            objAli.Apttus_Config2__StartDate__c = objOrderLine.Apttus_Config2__StartDate__c;
            objAli.Apttus_Config2__EndDate__c = objOrderLine.Apttus_Config2__EndDate__c;
            objAli.Billing_Type__c = objOrderLine.Billing_Type__c;
            objAli.Apttus_Config2__BillingFrequency__c = objOrderLine.Apttus_Config2__BillingFrequency__c;
            objAli.Equipment_Id__c = objOrderLine.Equipment_Id__c;
            objAli.Serial_Number__c = objOrderLine.Serial_Number__c;
            //Informatics : DCP-32561
            objAli.Dragen_Connectivity__c = objOrderLine.Dragen_Connectivity__c;
            objAli.Registrant_Contact__c = objOrderLine.Registrant_Contact__c;
            objAli.Registrant_Lead__c = objOrderLine.Registrant_Lead__c;
            objAli.Work_Group_Name__c = objOrderLine.Work_Group_Name__c;
            objAli.Instance_Region__c = objOrderLine.Instance_Region__c;
            objAli.Zuora_Subscription_ID__c = objOrderLine.Zuora_Subscription_ID__c;
            objAli.Domain_URL__c = objOrderLine.Domain_URL__c;
            objAli.Object_Status__c = objOrderLine.Object_Status__c;
            objAli.Custom_License_Flag__c = objOrderLine.Custom_License_Flag__c;
            updateAssetLineItems.add(objAli);
        }
        if(!updateAssetLineItems.isEmpty()) {
            update updateAssetLineItems;
        }
        ilib_LogEvent.message('erpLineNumberToAssetLineItemId: ' + erpLineNumberToAssetLineItemId);
        ilib_LogEvent.message('erpLineNumberToNewOliValues: ' + erpLineNumberToNewOliValues);

        List<Apttus_Config2__OrderLineItem__c> updateOrderLineItems = new List<Apttus_Config2__OrderLineItem__c>();


        //The below loop assignes the correct ALI to OLI in case of incorrect assignment
        for(Apttus_Config2__OrderLineItem__c oli : erpLineNumberToOli.values()) {
            Apttus_Config2__OrderLineItem__c orderLineItemUpdate = new Apttus_Config2__OrderLineItem__c(Id=oli.Id); //INC0378142 - Created an object for making the update 
            if(oli.Apttus_Config2__AssetLineItemId__c != erpLineNumberToAssetLineItemId.get(oli.ERP_Line_Number_Id__c)){    //check if the field value is changed.
                orderLineItemUpdate.Apttus_Config2__AssetLineItemId__c = erpLineNumberToAssetLineItemId.get(oli.ERP_Line_Number_Id__c);
                updateOrderLineItems.add(orderLineItemUpdate);
            }
        }
        ilib_LogEvent.message('updateOrderLineItems :::'+updateOrderLineItems);
        if(!updateOrderLineItems.isEmpty()) {
            update updateOrderLineItems;
        }
        ilib_LogEvent.pop();
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation  - Below function populates the lookups using external ids.
     * @return Apttus_Config2__OrderLineItem__c
     */
    public static Apttus_Config2__OrderLineItem__c populateLookupsUsingExtId(ApttusOrderWrapper.OrderLineItem objOLIWrapper, Apttus_Config2__OrderLineItem__c oliSObject){
        if(String.isNotBlank(objOLIWrapper.Apttus_Config2_ProductId) && String.isBlank(objOLIWrapper.SVMXC_Service_Plan)){
            oliSObject.Apttus_Config2__ProductId__r = new Product2(Material_Number__c = objOLIWrapper.Apttus_Config2_ProductId);
        }
        return oliSObject;
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation - Populates map of quote lineitems to order lineitems. 
     * @return void
     */
    public static void populateMapOfQliToOli(ApttusOrderWrapper.OrderLineItem objOLIWrapper,Map<String,List<Apttus_Config2__OrderLineItem__c>> quoteToOLItems,Apttus_Config2__OrderLineItem__c oliSObject,Map<String,List<Apttus_Config2__OrderLineItem__c>> quoteToOLItemsFieldUpdate, Map<String,List<Apttus_Config2__OrderLineItem__c>> contactPguidToOrderLineItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> leadPguidToOrderLineItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> serviceProductToOLItems, Set<String>  pguidSet){
        //creating the map with Contact PGUID to orderlineitem - DCP-31268
        if(String.isNotBlank(objOLIWrapper.Registrant_Contact)){
            if(contactPguidToOrderLineItems.containsKey(objOLIWrapper.Registrant_Contact)){
                contactPguidToOrderLineItems.get(objOLIWrapper.Registrant_Contact).add(oliSObject);
            }else{
                contactPguidToOrderLineItems.put(objOLIWrapper.Registrant_Contact,new List<Apttus_Config2__OrderLineItem__c>{oliSObject});
            }
            pguidSet.add(objOLIWrapper.Registrant_Contact);
        }
        //creating the map with Lead PGUID to orderlineitem - DCP-31268
        if(String.isNotBlank(objOLIWrapper.Registrant_Lead)){
            if(leadPguidToOrderLineItems.containsKey(objOLIWrapper.Registrant_Lead)){
                leadPguidToOrderLineItems.get(objOLIWrapper.Registrant_Lead).add(oliSObject);
            }else{
                leadPguidToOrderLineItems.put(objOLIWrapper.Registrant_Lead,new List<Apttus_Config2__OrderLineItem__c>{oliSObject});
            }
            pguidSet.add(objOLIWrapper.Registrant_Lead);
        }
        //Added by KD
        //creating the map with Service plan product to orderlineitem 
        if(String.isNotBlank(objOLIWrapper.SVMXC_Service_Plan)){
            if(serviceProductToOLItems.containsKey(objOLIWrapper.SVMXC_Service_Plan)){
                serviceProductToOLItems.get(objOLIWrapper.SVMXC_Service_Plan).add(oliSObject);
            }else{
                serviceProductToOLItems.put(objOLIWrapper.SVMXC_Service_Plan,new List<Apttus_Config2__OrderLineItem__c>{oliSObject});
            }
        }

        //populating map of QLI to orderlineitem
        if(String.isNotBlank(objOLIWrapper.Apttus_QPConfig_ProposalLineItemId)){
            if(quoteToOLItems.containsKey(objOLIWrapper.Apttus_QPConfig_ProposalLineItemId)){
                quoteToOLItems.get(objOLIWrapper.Apttus_QPConfig_ProposalLineItemId).add(oliSObject);
            }else{
                quoteToOLItems.put(objOLIWrapper.Apttus_QPConfig_ProposalLineItemId,new List<Apttus_Config2__OrderLineItem__c>{oliSObject});
            }
        }
        else{
            //creating the map  for orderlineitems that donot have quote line reference to set the values 
            objOLIWrapper.Apttus_QPConfig_ProposalLineItemId=null;
            if(quoteToOLItemsFieldUpdate.containsKey(objOLIWrapper.Apttus_QPConfig_ProposalLineItemId)){
                quoteToOLItemsFieldUpdate.get(objOLIWrapper.Apttus_QPConfig_ProposalLineItemId).add(oliSObject);
            }else{
                quoteToOLItemsFieldUpdate.put(objOLIWrapper.Apttus_QPConfig_ProposalLineItemId,new List<Apttus_Config2__OrderLineItem__c>{oliSObject});
            }
        }
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation  - Below function populates the ASOP lookup
     * @return void
     */
    public static void populateAsopLink(Map<String, Apttus_Config2__Order__c> asopToOrder){
        if(asopToOrder.isEmpty()){
            return;
        }
        List<Apttus_Config2__Order__c> lstASOP=new ApttusOrdersSelector().fetchRecordForASOPLink(asopToOrder.keySet());
        if(lstASOP.isEmpty()){
            return;
        }
        Apttus_Config2__Order__c asopLink=asopToOrder.values();
        asopLink.ASOP_Number_Link__c=lstASOP[0].Id;
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation  - Below function populates the service product lookup
     * @return void
     */
    public static void populateServiceProductLink(Map<String,List<Apttus_Config2__OrderLineItem__c>> serviceProductToOLItems){
        // Added By KD
        // Fetching the productid  from the productsselector to populate the productId for all the orderlineitems for Service contract
        list<Product2> lstProductsForService = serviceProductToOLItems.keyset().isEmpty()?new list<Product2>():new ProductsSelector().fetchProductId(serviceProductToOLItems.keyset());
        if(lstProductsForService.isEmpty()){
            return;
        }
        for(Product2 objProduct: lstProductsForService){
            List<Apttus_Config2__OrderLineItem__c> lstOLIUpdate=serviceProductToOLItems.get(objProduct.ProductCode);
            for(Apttus_Config2__OrderLineItem__c productIdUpdate:lstOLIUpdate){
                productIdUpdate.Apttus_Config2__ProductId__c = objProduct.Id;
            }
        }
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation  - Below function processes the incoming values from SAP
     * @return void
     */
    public static void processIncomingValues(String strJsonInput, ApttusOrderDataReceiver instantiated){
        if (String.isBlank(strJsonInput)) {
            throw new UtilsRest.InterfaceException('Input JSON is missing');
        }
        deserializeInputs(strJsonInput);
        instantiated.addFriendlyJsonToLog(logInt, objOrderWrapper);

        // PRB0043542
        Boolean oppIDNotNull = true;
        Boolean quoteIDNotNull = true;
        // INC0275048: removing quote line check since quote line is sometimes blank
        // could restore it if we understand when blank line names are appropriate and check appropriately
        // Boolean quoteLineNotNull = true;
        if (objOrderWrapper != null)
        {
            oppIDNotNull = String.isNotBlank(objOrderWrapper.Apttus_Config2_RelatedOpportunityId);
            quoteIDNotNull = String.isNotBlank(objOrderWrapper.Apttus_QPConfig_ProposalId);

            // INC0275048: removing quote line check since quote line is sometimes blank
            // for (ApttusOrderWrapper.OrderLineItem objLine :objOrderWrapper.orderLineItem)
            // {
            //     if (String.isBlank(objLine.Apttus_QPConfig_ProposalLineItemId))
            //     {
            //         quoteLineNotNull = false;
            //         break;
            //     }
            // }
        }

        if (oppIDNotNull != quoteIDNotNull) // || oppIDNotNull != quoteLineNotNull)
        {
            throw new UtilsRest.InterfaceException('Missing opportunity or quote ID in Request JSON'); 
        }

        primaryRecordId = upsertIncomingValuesImpl();
        erpCustomerId = getRelatedErpCustomerId('Apttus_Config2__Order__c', 'Apttus_QPConfig__ProposalId__r.Apttus_Proposal__Opportunity__r.Account', primaryRecordId);
    }

    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation  - Below function Register order for DML operation.
     * @return void
     */
    public static void registerOrderForDml(Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItem, ilib_SObjectUnitOfWork objUnitOfWork, Apttus_Config2__Order__c apttusOrderSObject){
        if(idToOrderLineItem.isEmpty()){
            objUnitOfWork.registerNew(apttusOrderSObject); //insert - TASK0730598
        }else{
            boolOrderDoesNotExist=false; //update operation
            apttusOrderSObject.id=idToOrderLineItem.values()[0].Apttus_Config2__OrderId__c;
            objUnitOfWork.registerDirty(apttusOrderSObject);//update - TASK0730598
        }
    }
    
    /*
     * @Author : Koustubh M
     * @Decription : TASK0730598 - header level asset activation  - Below function Register order lineitem for DML operation.
     * @return void
     */
    public static void registerOrderLineitemForDml(ilib_SObjectUnitOfWork objUnitOfWork, Apttus_Config2__Order__c apttusOrderSObject, Map<String,Apttus_Config2__OrderLineItem__c> oliMap, Set<String> setERPLineNumber,Map<String,List<Apttus_Config2__OrderLineItem__c>> salesOrderToOrderLineItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> quoteToOLItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> quoteToOLItemsFieldUpdate, Map<String,List<Apttus_Config2__OrderLineItem__c>> contactPguidToOrderLineItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> leadPguidToOrderLineItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> serviceProductToOLItems, Set<String>  pguidSet){
        //This loop populates lookups, registers oli for DML and populates maps
        for(ApttusOrderWrapper.OrderLineItem objOLIWrapper:objOrderWrapper.orderLineItem){
            Apttus_Config2__OrderLineItem__c oliSObject = populateLookupsUsingExtId(objOLIWrapper, objOLIWrapper.getSObject());
            //Populate setERPLineNumber and salesOrderToOrderLineItems for further use
            populateSalesOrderToOliMap(oliSObject,apttusOrderSObject,setERPLineNumber,salesOrderToOrderLineItems);
            populateMapOfQliToOli(objOLIWrapper, quoteToOLItems,oliSObject,quoteToOLItemsFieldUpdate,contactPguidToOrderLineItems,leadPguidToOrderLineItems,serviceProductToOLItems,pguidSet);
            //TASK0730598 - Below code registers OLI for DML 
            if(boolOrderDoesNotExist){
                //Register OLI for insert when new order is created
                objUnitOfWork.registerNew(oliSObject,Apttus_Config2__OrderLineItem__c.Apttus_Config2__OrderId__c , apttusOrderSObject); //insert
            }else{
                if(oliMap.containsKey(oliSObject.ERP_Line_Number_Id__c)){
                    //Register OLI for update when OLI of an order are updated
                    oliSObject.id=oliMap.get(oliSObject.ERP_Line_Number_Id__c).id;
                    objUnitOfWork.registerRelationship(oliSObject,Apttus_Config2__OrderLineItem__c.Apttus_Config2__OrderId__c , apttusOrderSObject);
                    objUnitOfWork.registerDirty(oliSObject);
                }else{
                    //Register OLI for insert when new OLI are added to an already activated order. In this case the lineitem is not activated and asset does not get created for it.
                    objUnitOfWork.registerNew(oliSObject,Apttus_Config2__OrderLineItem__c.Apttus_Config2__OrderId__c , apttusOrderSObject); //insert
                }
            }
        }
    }

    /*
        Empty method possibly for future use
    */
    public static void businessRules(ilib_SObjectUnitOfWork uow)
    {
        
        // ...
    }
    
}
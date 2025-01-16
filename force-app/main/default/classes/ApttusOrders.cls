/*
* @Author : Sravan Panchangam
* @Description:DCP-9865 ASOP Integration
*    @Test Class for above 90% coverage.
*    -TestApttusOrders
     -TestTAPS_ApttusOrder
*    @Test Class for atleast 75% coverage.
      -TestApttusOrders
      -TestTAPS_ApttusOrder
* @Date :2018-09-27
Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date            Description
*          Maruthi           16-Feb-2022     PM-122: Added logic in AfterInsert and in AfterUpdate method and created invokeRQContactEligibleQueueable method.
*          Jitesh Lakhwani   8-July-2022     Code Scan fixes of Comments
*          Nishan Shetty     24-August-2022  DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*          Arquimidez Mora   13-August-2024  CMCM-9645 - Populate Contact and Opportunity Fields And update PO Data from related Opportunity.
*    --------------------------------------------------------------------------------------------------
*/
public with sharing class ApttusOrders extends ilib_SObjectDomain {

    public static Boolean hasRunTaps = false;

    /**
    * @description Parameterized Constructor called
    * @params List<Apttus_Config2__Order__c> sObjectList
    * @return void
    **/
    public ApttusOrders(List<Apttus_Config2__Order__c> sObjectList)
    {
        super(sObjectList);
    }
    /**
     *  Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @description  Constructor of base class
        * @params List<SObjects> sObjectList
        * @return sObjectList
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusOrders(sObjectList);
        }
    }

    /**
     * For DCP-14870(Asop Integration): Used for Populating SoldTO ,Ultimate consigneee,OpportunityId and Proposal Id before inserting the order in Apttus_Config2__Order__c
     * For DCP-13048(Sales Orde Sync): Used for populating distributor,ship to,bill to ,payer before inserting the order in Apttus_Config2__Order__c
     */
    public override void onBeforeInsert()
    {
        List<Apttus_Config2__Order__c> lstTempOrders=(List<Apttus_Config2__Order__c>)records;
        populateOrdersLookUps(lstTempOrders,null);
    }

    /**
     * For DCP-14870(Asop Integration): Used for Populating SoldTO ,Ultimate consigneee,OpportunityId and Proposal Id before Updating the order in Apttus_Config2__Order__c
     * For DCP-13048(Sales Orde Sync): Used for populating distributor,ship to,bill to ,payer before updating the order in Apttus_Config2__Order__c
	 */
    public override void onBeforeUpdate(Map<Id, sObject> existingRecords)
    {
        List<Apttus_Config2__Order__c> lstTempOrders=(List<Apttus_Config2__Order__c>)records;
        setStatusCompleted(lstTempOrders); //INC0383655- retired workflow 'Order: Update Activation Date On Orders'
        populateOrdersLookUps(lstTempOrders,existingRecords);
    }

    /**
    * @description Overriding the onAfterInsert base class method
    * @params NA
    * @return void
    **/ 
    public override void onAfterInsert()
    {
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
		//PM-122 Update Contact Eligible
        invokeRQContactEligibleQueueable(Trigger.newMap.keySet());
        //CMCM-9645
        ApttusOrderService.populateDefaultFieldsAndPONumberAndPODate((List<Apttus_Config2__Order__c>)records, null);
        //END CMCM-9645
    }

    /**
    * @description Overriding the onAfterUpdate base class method
    * @params NA
    * @return void
    **/
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        if (!hasRunTaps && !isInsertOperationForObject(getSObjectType()))
        {
            List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId' };
            TAPS_OrchestratorInterface tapsOrchestratorInst= (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);//DCP-44091
            if (idsThatNeedRecalculation.size() > 0)
            {
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
                hasRunTaps = true;
            }
        }
        //PM-122 Update Contact Eligible  	
        invokeRQContactEligibleQueueable(Trigger.newMap.keySet());
        //CMCM-9645
        ApttusOrderService.populateDefaultFieldsAndPONumberAndPODate((List<Apttus_Config2__Order__c>)records, (Map<Id, Apttus_Config2__Order__c>)existingRecords);
        //END CMCM-9645
    }

    /**
     * INC0383655- retired workflow 'Order: Update Activation Date On Orders'
     */
    public static void setStatusCompleted(List<Apttus_Config2__Order__c> lstOrders)
    {
        for(Apttus_Config2__Order__c orderItem: lstOrders){
            if( orderItem.No_Of_Order_Lines__c != 0 && orderItem.Order_Line_Not_Activated__c == 0 && orderItem.Order_Status__c!=System.Label.Completed && orderItem.No_Of_Order_Lines__c == orderItem.Processed_Order_Lines__c ){
                orderItem.Order_Status__c=System.Label.Completed; 
            }
        }
    }

    /**
     * This method is used for both the  insert and update for populating the SoldTO ,Ultimate consigneee,OpportunityId, Proposal Id ,distributor,ship to,bill to ,payer
     */
    public static void populateOrdersLookUps(List<Apttus_Config2__Order__c> lstOrders,Map<Id, sObject> existingOrders)
    {
        //Following maps are used in populating the SoldTo , Ultimate Consignee, Distributor lookups(Account)
        Map<String,list<Apttus_Config2__Order__c>> soldTOERPIdsToOrder=new Map<String,list<Apttus_Config2__Order__c>>();
        Map<String,list<Apttus_Config2__Order__c>> ucERPIdsToOrder=new Map<String,list<Apttus_Config2__Order__c>>();
        Map<String,list<Apttus_Config2__Order__c>> distributorERPIdsToOrder=new Map<String,list<Apttus_Config2__Order__c>>();

        //Following maps are used in populating the ShipTo , BillTo, Payer lookups(Customer Master Data)
        Map<String,list<Apttus_Config2__Order__c>> shipToERPIdsToOrder=new Map<String,list<Apttus_Config2__Order__c>>();
        Map<String,list<Apttus_Config2__Order__c>> billToERPIdsToOrder=new Map<String,list<Apttus_Config2__Order__c>>();
        Map<String,list<Apttus_Config2__Order__c>> payerERPIdsToOrder=new Map<String,list<Apttus_Config2__Order__c>>();
        
        //Following map is used in populating the  ProposalId , OpportunityId lookups
        Map<String,list<Apttus_Config2__Order__c>> apttusQuoteNumberToOrder=new Map<String,list<Apttus_Config2__Order__c>>();
        //Following map is used for updating the source field in the orders as part of Order and Orderline item bundle creation
        Map<String,list<Apttus_Config2__Order__c>> apttusQuoteNumberToOrderFieldUpdate=new Map<String,list<Apttus_Config2__Order__c>>();
		
        Map<String, Map<String,String>> objectToPicklistValueMap=UtilsSettings.getCustomMetadataPicklistMap('Apttus_Config2__Order__c','ERP',false);
        //iterating over list of orders to get create a Map which contains key as SoldTOERPID , UltimateConsigneeERPID ,ERP Quote Number,BillToERPID,ShipToErpID,PayerERPID,DistributorErpId and value as Corresponding Orders
        for(Apttus_Config2__Order__c orders:lstOrders)
        {
            Apttus_Config2__Order__c objOrder = (existingOrders!=null ? (Apttus_Config2__Order__c)existingOrders.get(orders.Id) : null);
            System.debug('Inco Term Value:'+orders.Inco_Term_1_SAP__c);
            if((objOrder== null || objOrder.Inco_Term_1_SAP__c!=orders.Inco_Term_1_SAP__c) 
                    && String.isNotBlank(orders.Inco_Term_1_SAP__c)){
                String incoTerm=objectToPicklistValueMap.get('Inco_Term_1__c').get(orders.Inco_Term_1_SAP__c);
                System.debug('Inco Term Value Latest:'+incoTerm);
                orders.Inco_Term_1__c=incoTerm;
            }
            if(String.isBlank(orders.ASOP_Number__c) && String.isNotBlank(orders.Sales_Order_Number_Unique__c)){
                orders.ASOP_Number__c=orders.Sales_Order_Number_Unique__c;
            }
            
            if(objOrder!= null && objOrder.Apttus_Config2_SoldToAccountId_ERP_Id__c!=null && orders.Apttus_Config2__SoldToAccountId__c == null){
                orders.Apttus_Config2_SoldToAccountId_ERP_Id__c = null; //IF Sold To is blanked out, then blank out UC ERP Id as well.
            }
            Boolean isSoldToAcc= objOrder!= null && objOrder.Apttus_Config2_SoldToAccountId_ERP_Id__c!=null && objOrder.Apttus_Config2_SoldToAccountId_ERP_Id__c.equals(orders.Apttus_Config2_SoldToAccountId_ERP_Id__c)?true:false;
            if(orders.Apttus_Config2_SoldToAccountId_ERP_Id__c!=null && !isSoldToAcc){
                if(soldTOERPIdsToOrder.containsKey(orders.Apttus_Config2_SoldToAccountId_ERP_Id__c)){
                    soldTOERPIdsToOrder.get(orders.Apttus_Config2_SoldToAccountId_ERP_Id__c).add(orders);
                }
                else{
                    soldTOERPIdsToOrder.put(orders.Apttus_Config2_SoldToAccountId_ERP_Id__c,new List<Apttus_Config2__Order__c>{orders});
                }
            }
            if(objOrder!= null && objOrder.Ultimate_Consignee_ERP_Id__c!=null && orders.Ultimate_Consignee__c == null){
                orders.Ultimate_Consignee_ERP_Id__c = null; //IF Ultimate Consignee is blanked out, then blank out UC ERP Id as well.
            }
            Boolean ultimateConsignee= objOrder!= null && objOrder.Ultimate_Consignee_ERP_Id__c!=null && objOrder.Ultimate_Consignee_ERP_Id__c.equals(orders.Ultimate_Consignee_ERP_Id__c);
            if(orders.Ultimate_Consignee_ERP_Id__c!=null && !ultimateConsignee){
                if(ucERPIdsToOrder.containsKey(orders.Ultimate_Consignee_ERP_Id__c)){
                    ucERPIdsToOrder.get(orders.Ultimate_Consignee_ERP_Id__c).add(orders);
                }
                else{
                    ucERPIdsToOrder.put(orders.Ultimate_Consignee_ERP_Id__c,new List<Apttus_Config2__Order__c>{orders});
                }
            }

            if(objOrder!= null && objOrder.Distributor_ERP_Id__c!=null && orders.Distributor__c == null){
                orders.Distributor_ERP_Id__c = null; //IF Distributor is blanked out, then blank out UC ERP Id as well.
            }
            Boolean distributor=objOrder!= null && objOrder.Distributor_ERP_Id__c!=null && objOrder.Distributor_ERP_Id__c.equals(orders.Distributor_ERP_Id__c)?true:false ;
            if(orders.Distributor_ERP_Id__c!=null && !distributor){
                if(distributorERPIdsToOrder.containsKey(orders.Distributor_ERP_Id__c)){
                    distributorERPIdsToOrder.get(orders.Distributor_ERP_Id__c).add(orders);
                }
                else{
                    distributorERPIdsToOrder.put(orders.Distributor_ERP_Id__c,new List<Apttus_Config2__Order__c>{orders});
                }
            }

            Boolean shipTo=objOrder!= null && objOrder.Ship_To_ERP_Id__c!=null && objOrder.Ship_To_ERP_Id__c.equals(orders.Ship_To_ERP_Id__c)?true:false ; 
            if(orders.Ship_To_ERP_Id__c!=null && !shipTo){
                if(shipToERPIdsToOrder.containsKey(orders.Ship_To_ERP_Id__c)){
                    shipToERPIdsToOrder.get(orders.Ship_To_ERP_Id__c).add(orders);
                }
                else{
                    shipToERPIdsToOrder.put(orders.Ship_To_ERP_Id__c,new List<Apttus_Config2__Order__c>{orders});
                }
            }

            Boolean billTo=objOrder!= null && objOrder.Bill_To_ERP_Id__c!=null && objOrder.Bill_To_ERP_Id__c.equals(orders.Bill_To_ERP_Id__c)?true:false ; 
            if(orders.Bill_To_ERP_Id__c!=null && !billTo){
                if(billToERPIdsToOrder.containsKey(orders.Bill_To_ERP_Id__c)){
                    billToERPIdsToOrder.get(orders.Bill_To_ERP_Id__c).add(orders);
                }
                else{
                    billToERPIdsToOrder.put(orders.Bill_To_ERP_Id__c,new List<Apttus_Config2__Order__c>{orders});
                }
            }

            Boolean payer=objOrder!= null && objOrder.Payer_ERP_Id__c!=null && objOrder.Payer_ERP_Id__c.equals(orders.Payer_ERP_Id__c)?true:false ; 
            if(orders.Payer_ERP_Id__c!=null && !payer){
                if(payerERPIdsToOrder.containsKey(orders.Payer_ERP_Id__c)){
                    payerERPIdsToOrder.get(orders.Payer_ERP_Id__c).add(orders);
                }
                else{
                    payerERPIdsToOrder.put(orders.Payer_ERP_Id__c,new List<Apttus_Config2__Order__c>{orders});
                }
            }

            Boolean apttusQuoteNumber= objOrder!= null && objOrder.APTTUS_Quote_Number__c!=null && objOrder.APTTUS_Quote_Number__c.equals(orders.APTTUS_Quote_Number__c)?true:false ; 
            if(orders.APTTUS_Quote_Number__c!=null && !apttusQuoteNumber){
                if(apttusQuoteNumberToOrder.containsKey(orders.APTTUS_Quote_Number__c)){
                    apttusQuoteNumberToOrder.get(orders.APTTUS_Quote_Number__c).add(orders);
                }
                else{
                    apttusQuoteNumberToOrder.put(orders.APTTUS_Quote_Number__c,new List<Apttus_Config2__Order__c>{orders});
                }
            }
            else{
                //This logic is for updating the source field of orders that do not have quote reference
                if(orders.APTTUS_Quote_Number__c==null){
                    if(apttusQuoteNumberToOrderFieldUpdate.containsKey(orders.APTTUS_Quote_Number__c)){
                        apttusQuoteNumberToOrderFieldUpdate.get(orders.APTTUS_Quote_Number__c).add(orders);
                    }
                    else{
                        apttusQuoteNumberToOrderFieldUpdate.put(orders.APTTUS_Quote_Number__c,new List<Apttus_Config2__Order__c>{orders});
                    }
                }
            }
        }
        System.debug('From ApttusOrder Maps:   Erp QuoteNumber :'+apttusQuoteNumberToOrder+'soldTOERPIdsToOrder :'+soldTOERPIdsToOrder+'ucERPIdsToOrder :'+ucERPIdsToOrder);

        set<String> setofERPIds=new set<String>();
        setofERPIds.addAll(soldTOERPIdsToOrder.keySet());
        setofERPIds.addAll(ucERPIdsToOrder.keySet());
        setofERPIds.addAll(distributorERPIdsToOrder.keySet());

        if(!setofERPIds.isEmpty()) {
            //fetching the list of Accounts with the Id and  ERP_Customer_Id__c from Accountsselector for SoldTO ,distributor and Ultimate Consignee lookup Update
            for(Account acc:new AccountsSelector().selectAccountsForERPCustomerIds(setofERPIds)){
                if(soldTOERPIdsToOrder.containsKey(acc.ERP_Customer_Id__c)){
                    List<Apttus_Config2__Order__c>  lstSoldToorders=soldTOERPIdsToOrder.get(acc.ERP_Customer_Id__c);
                    for(Apttus_Config2__Order__c soldToUpdate:lstSoldToorders){
                        //updating the order by setting Account Id to the SoldToAccountId
                        soldToUpdate.Apttus_Config2__SoldToAccountId__c=acc.Id;
                        soldTOERPIdsToOrder.remove(acc.ERP_Customer_Id__c);
                    }
                }
                if(ucERPIdsToOrder.containsKey(acc.ERP_Customer_Id__c)){
                    List<Apttus_Config2__Order__c>  lstUCorders=ucERPIdsToOrder.get(acc.ERP_Customer_Id__c);
                    for(Apttus_Config2__Order__c ucUpdate:lstUCorders){
                        //updating the order by setting Account Id to the Ultimate_Consignee__c
                        ucUpdate.Ultimate_Consignee__c=acc.Id;
                        ucERPIdsToOrder.remove(acc.ERP_Customer_Id__c);
                    }
                }

                if(distributorERPIdsToOrder.containsKey(acc.ERP_Customer_Id__c)){
                    List<Apttus_Config2__Order__c>  lstDistributororders=distributorERPIdsToOrder.get(acc.ERP_Customer_Id__c);
                    for(Apttus_Config2__Order__c distributorUpdate:lstDistributororders){
                        //updating the order by setting Account Id to the Distributor__c
                        distributorUpdate.Distributor__c=acc.Id;
                        distributorERPIdsToOrder.remove(acc.ERP_Customer_Id__c);
                    }
                }
            }
            //If UC is not found then for those orders blank out ERP Id
            for(List<Apttus_Config2__Order__c> ucUpdateList:ucERPIdsToOrder.values()){
                    for(Apttus_Config2__Order__c ucUpdate:ucUpdateList){
                        ucUpdate.Ultimate_Consignee_ERP_Id__c=null;
                        ucUpdate.Ultimate_Consignee__c=null;
                    }
            }
            //If Distributor is not found then for those orders blank out ERP Id
            for(List<Apttus_Config2__Order__c> distUpdateList:distributorERPIdsToOrder.values()){
                    for(Apttus_Config2__Order__c distUpdate:distUpdateList){
                        distUpdate.Distributor__c=null;
                        distUpdate.Distributor_ERP_Id__c=null;
                    }
            }
            //If Sold To is not found then for those orders blank out ERP Id
            for(List<Apttus_Config2__Order__c> stUpdateList:soldTOERPIdsToOrder.values()){
                for(Apttus_Config2__Order__c stUpdate:stUpdateList){
                    stUpdate.Apttus_Config2_SoldToAccountId_ERP_Id__c=null;
                    stUpdate.Apttus_Config2__SoldToAccountId__c=null;
                }
            }
        }
        
        set<String> setErpCustomerIds=new set<String>();
        setErpCustomerIds.addAll(shipToERPIdsToOrder.keySet());
        setErpCustomerIds.addAll(billToERPIdsToOrder.keySet());
        setErpCustomerIds.addAll(payerERPIdsToOrder.keySet());

        if(!setErpCustomerIds.isEmpty())
        {
            //fetching the list of Customer_Master_Data with the Id and  ERP_Customer_Id__c from CustomerMasterDataSelector for ShipTo ,BillTo and Payer lookup Update
            for(Customer_Master_Data__c cmd:new CustomerMasterDataSelector().selectByAccountERPId(setErpCustomerIds)){
                if(shipToERPIdsToOrder.containsKey(cmd.ERP_Customer_Id__c)){
                    List<Apttus_Config2__Order__c>  lstShipTo=shipToERPIdsToOrder.get(cmd.ERP_Customer_Id__c);
                    for(Apttus_Config2__Order__c shipToUpdate:lstShipTo){
                        shipToUpdate.Ship_To__c=cmd.Id;
                    }
                }
                if(billToERPIdsToOrder.containsKey(cmd.ERP_Customer_Id__c)){
                    List<Apttus_Config2__Order__c>  lstBillTo=billToERPIdsToOrder.get(cmd.ERP_Customer_Id__c);
                    for(Apttus_Config2__Order__c billToUpdate:lstBillTo){
                        billToUpdate.Bill_To__c=cmd.Id;
                    }
                }
                if(payerERPIdsToOrder.containsKey(cmd.ERP_Customer_Id__c)){
                    List<Apttus_Config2__Order__c>  lstPayer=payerERPIdsToOrder.get(cmd.ERP_Customer_Id__c);
                    for(Apttus_Config2__Order__c payerUpdate:lstPayer){
                        payerUpdate.Payer__c=cmd.Id;
                    }
                }
            }
        }

        //fetching the list of Apttusproposal with Proposal Id and Opportunity Id from ApttusProposalsSelector for ProposalId and RelatedOpportunityId lookup update
        set<String> setApttusQuoteNumber=apttusQuoteNumberToOrder.keySet();
        list<Apttus_Proposal__Proposal__c> lstApttusproposal=!setApttusQuoteNumber.isEmpty()?new ApttusProposalsSelector().fetchQuotation(setApttusQuoteNumber):new list<Apttus_Proposal__Proposal__c>();
        set<String> setUpdateSource=new set<String>();
        set<String> ordersWithoutReference=apttusQuoteNumberToOrderFieldUpdate.keySet();
        list<Apttus_Config2__Order__c> listSize=!ordersWithoutReference.isEmpty()?apttusQuoteNumberToOrderFieldUpdate.get(null):new list<Apttus_Config2__Order__c>();
        if(!listSize.isEmpty()){
            setUpdateSource.addAll(apttusQuoteNumberToOrderFieldUpdate.keySet());
        }

        //Checking for the orders that donot have quote references
        if(!setApttusQuoteNumber.isEmpty()){
            if(!lstApttusproposal.isEmpty()){
                for(String quoteRefCheck:setApttusQuoteNumber){
                    for(Apttus_Proposal__Proposal__c proposalCheck:lstApttusproposal){
                        String check=proposalCheck.Name;
                        if(!check.equals(quoteRefCheck)){
                            setUpdateSource.add(quoteRefCheck);
                        }
                    }
                }
            }
            else{
                setUpdateSource.addAll(setApttusQuoteNumber);
            }
        }

        if(!lstApttusproposal.isEmpty()){
            for(Apttus_Proposal__Proposal__c proposal:lstApttusproposal){
                if(apttusQuoteNumberToOrder.containsKey(proposal.Name)){
                    List<Apttus_Config2__Order__c>  lstProposalAndOppOrders=apttusQuoteNumberToOrder.get(proposal.Name);
                    for(Apttus_Config2__Order__c proposalAndOppupdate:lstProposalAndOppOrders){
                        //updating the Order by setting the ProposalId and RelatedOpportunityId to the orders
                        proposalAndOppupdate.Apttus_QPConfig__ProposalId__c=proposal.Id;
                        proposalAndOppupdate.Apttus_Config2__RelatedOpportunityId__c=proposal.Apttus_Proposal__Opportunity__c;
                        proposalAndOppupdate.Apttus_Config2__PrimaryContactId__c=proposal.Apttus_Proposal__Primary_Contact__c;
                        //For Orders if the quote reference is available then we are setting the source to quote else Account
                        proposalAndOppupdate.Apttus_Config2__Source__c='Quote';
                    }
                }
            }
        }

        //Updating the source field with Account for those that do not have quote reference
        if(!setUpdateSource.isEmpty())
        {
            List<Apttus_Config2__Order__c>  lstSourceUpdate;
            for(String updateSource:setUpdateSource){
                if(apttusQuoteNumberToOrderFieldUpdate.containsKey(updateSource)){
                    lstSourceUpdate=apttusQuoteNumberToOrderFieldUpdate.get(updateSource);
                }
                else{
                    lstSourceUpdate=apttusQuoteNumberToOrder.get(updateSource);
                }
                for(Apttus_Config2__Order__c sourceUpdate:lstSourceUpdate){
                    sourceUpdate.Apttus_Config2__Source__c='Account';
                }
            }
        }
    }  

    /*	
    *  @AUTHOR:  Maruthi B	
    *  @DESCRIPTION: PM-122: This Method to invoke RQContactEligibleQueueable	
    */	
    public static void invokeRQContactEligibleQueueable(Set<Id> setOrderIds) {        	
        //PM-122 invoke RQContactEligibleQueueable to mark R_Q_Contact_Eligible__c         	
        // chain queueables fix start 	
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('OrderAfterInsert');           	
        RQContactEligibleQueueable objRQContactEligibleQueueable = new RQContactEligibleQueueable(setOrderIds);       	
        if(!System.isBatch()) {            	
            queueableThread.logAndQueue(objRQContactEligibleQueueable,'RQContactEligibleQueueable','execute');            	
            ilib_QueueableManager.enqueueJob(queueableThread);      	
        }	
        // chain queueables fix end	
    }
}
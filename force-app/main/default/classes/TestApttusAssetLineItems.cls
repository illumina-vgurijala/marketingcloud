/**
*    @author Gopesh Banker
*    @date   2018-10-03
*    @description  initial version of class
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Himanshu                     20/04/2022            Code Scan Fixes
*    -----------------------------------------------------------------------------------------------------------------------------------
*/ 
@isTest(isParallel=false)
private class TestApttusAssetLineItems {
	
    private static final String AMR = 'AMR';
    private static final String USD = 'USD';
    private static final String USA = 'USA';
    private static final String OPPORTUNITYRTDIRECT = 'Direct';
    private static final String PRICELIST = 'AMR-USD-US-01';
    private static final String ASSETSTATUSPENDINGRENEWAL = 'Pending Renewal';
    private static final String ASSETSTATUSNEW = 'New';
    private static final String ASSETSTATUSPENDINGACTIVATION = 'Pending Activation';

	@testSetup
    static void setupData()
    {
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICELIST);
        insert objPriceList;

        Account objAccount = TestDataAccount.getNewAccount();
        TestDataPerson.getNewContact(objAccount.Id);
        objAccount.Territory_Region__c = AMR;
        objAccount.CurrencyIsoCode = USD;
        objAccount.Country_Local__c = USA;
        objAccount.Territory_Name__c = AMR;
        objAccount.ERP_Customer_Id__c = 'abcd1234';
        update objAccount;
        
        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
      
        objOpportunity.RecordTypeName__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Sold_to_Distribution_Channel__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = objPriceList.Name;
        update objOpportunity;
        
        
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
        
        Product2 objProduct = TestDataMaster.createProduct(true);
        objProduct.Material_Class__c = 'Instrument';
        update objProduct;

        TestDataProposal.initPriceListItem(objProduct, objPriceList);
        
        
        TestDataProposal.getNewCart(objProposal);
        
        List<Apttus_Config2__ClassificationName__c> lstCategory = new List<Apttus_Config2__ClassificationName__c>();
        
        Apttus_Config2__ClassificationName__c objCategory = TestDataProposal.initCategory('Test Category');
        lstCategory.add(objCategory);
        insert lstCategory;
    }

    @isTest
    static void testRenewalAssetLineItemStatusFromProposalOnInsert()
    {
        Account acc = [Select Id from Account limit 1];     
        Product2 thisProduct = [Select Id From Product2 limit 1];
        Apttus_Proposal__Proposal__c proposal = [Select id From Apttus_Proposal__Proposal__c LIMIT 1];

        

        Apttus_Config2__AssetLineItem__c objAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem.Apttus_Config2__AccountId__c = acc.Id;
        objAssetLineItem.Apttus_Config2__ProductId__c = thisProduct.Id;
        objAssetLineItem.Serial_Number__c = '123123';
        objAssetLineItem.Contract_Number__c = '453523413';
        objAssetLineItem.Contract_Type__c = 'test Contract Type';
        objAssetLineItem.Apttus_QPConfig__ProposalId__c = proposal.Id;
        objAssetLineItem.Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Status__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Apttus_Config2__EndDate__c = Date.valueOf('2017-12-31');
        objAssetLineItem.Apttus_Config2__StartDate__c = Date.valueOf('2017-10-01');
        objAssetLineItem.Apttus_Config2__OriginalStartDate__c = Date.valueOf('2017-10-01');
        insert objAssetLineItem;

        Apttus_Config2__AssetLineItem__c objAssetLineItem2 = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem2.Apttus_Config2__AccountId__c = acc.Id;
        objAssetLineItem2.Apttus_Config2__ProductId__c = thisProduct.Id;
        objAssetLineItem.Serial_Number__c = '1223123';
        objAssetLineItem.Contract_Number__c = '45352213413';
        objAssetLineItem.Contract_Type__c = 'test2 Contract Type';
        objAssetLineItem2.Apttus_QPConfig__ProposalId__c = proposal.Id;
        objAssetLineItem2.Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem2.Status__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem2.Apttus_Config2__EndDate__c = system.today()+360;
        objAssetLineItem2.Apttus_Config2__StartDate__c = Date.valueOf('2017-10-01');
        objAssetLineItem2.Apttus_Config2__OriginalStartDate__c = Date.valueOf('2017-10-01');
        insert objAssetLineItem2;

        Apttus_CPQApi.CPQ.CreateCartRequestDO createCartRequest = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        createCartRequest.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQ.CreateCartResponseDO createCartResponse = Apttus_CPQApi.CPQWebService.createCart(createCartRequest);
        
        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addProductRequest.CartId = createCartResponse.CartId;
        
        Apttus_CPQApi.CPQ.SelectedProductDO selectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectedProduct.ProductId = thisProduct.Id;
        selectedProduct.Quantity = 1;
        selectedProduct.SellingTerm = 12;
        addProductRequest.SelectedProducts.add(selectedProduct);

        Apttus_CPQApi.CPQ.selectedProductDO selectedProduct2 = new Apttus_CPQApi.CPQ.selectedProductDO();
        selectedProduct2.ProductId = thisProduct.Id;
        selectedProduct2.Quantity = 1;
        selectedProduct2.SellingTerm = 12;
        addProductRequest.selectedProducts.add(selectedProduct2);

        Apttus_CPQApi.CPQWebService.addMultiProducts(addProductRequest);
        
        List<Apttus_Config2__LineItem__c> lstLi = [Select Id, Apttus_Config2__LineStatus__c, Apttus_Config2__AssetLineItemId__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :createCartResponse.CartId];
        
        lstLi.get(0).Apttus_Config2__LineStatus__c = 'Renewed';
        lstLi.get(0).Apttus_Config2__AssetLineItemId__c = objAssetLineItem.Id;
        lstLi.get(1).Apttus_Config2__LineStatus__c = 'Renewed';
        lstLi.get(1).Apttus_Config2__AssetLineItemId__c = objAssetLineItem2.Id;
        update lstLi;

        Apttus_Config2.CPQStruct.RenewAssetsRequestDO  changeAssetRequest = new Apttus_Config2.CPQStruct.RenewAssetsRequestDO();
        List<ID> listAssetId = new List<ID>();
        listAssetId.add(objAssetLineItem.id);
        listAssetId.add(objAssetLineItem2.id);
        changeAssetRequest.AssetIds = listAssetId;
        changeAssetRequest.CartId = createCartResponse.cartID;
        changeAssetRequest.FarthestAssetEndDate=false;
        changeAssetRequest.RenewEndDate = System.today().addDays(365);
        changeAssetRequest.RenewTerm = 12; 
        Apttus_Config2.AssetService.renewAssets(changeAssetRequest); 
        

        Apttus_CpqApi.CPQ.FinalizeCartRequestDO requestFinalize = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
        requestFinalize.CartId = createCartResponse.CartId;
        

        Test.startTest();
            Apttus_CpqApi.CPQWebService.finalizeCart(requestFinalize);
            
            List<Apttus_Proposal__Proposal_Line_Item__c> lstPli = [Select Id From Apttus_Proposal__Proposal_Line_Item__c Where Apttus_QPConfig__ConfigurationId__c = :createCartResponse.CartId];
            Set<Id> setAssetId = new Set<Id>();
            setAssetId.add(objAssetLineItem.id);
            setAssetId.add(objAssetLineItem2.id);
            List<Apttus_Config2__AssetLineItem__c> lstAli = [Select Id, Apttus_Config2__AssetStatus__c, Status__c FROM Apttus_Config2__AssetLineItem__c Where Id in :setAssetId order by createddate desc];
            System.debug('lstAli = '+lstAli);
            for(Apttus_Config2__AssetLineItem__c objAsset : lstAli)
            {
                if(objAsset.id == objAssetLineItem.id)
                {
                    System.assertEquals(System.Label.AssetLineItemStatusExpiredPendingRenewal,objAsset.Status__c);        
                }
                else if(objAsset.id == objAssetLineItem2.id)
                {
                    System.assertEquals(ASSETSTATUSPENDINGRENEWAL,objAsset.Status__c);
                }
            }
			set<id> lnItemIds = new Set <Id>();
            for(Apttus_Proposal__Proposal_Line_Item__c ln: lstPli){
                lnItemIds.add(ln.id);
            }

            delete lstPli;
	        lstPli = [SELECT id FROM Apttus_Proposal__Proposal_Line_Item__c where id in :lnItemIds];
           system.assertEquals(0,lstPli.size());      

            lstAli = [Select Id, Apttus_Config2__AssetStatus__c, Status__c FROM Apttus_Config2__AssetLineItem__c Where Id in :setAssetId order by createddate desc];
            for(Apttus_Config2__AssetLineItem__c objAsset : lstAli)
            {
                if(objAsset.id == objAssetLineItem.id)
                {
                    System.assertEquals(System.Label.AssetLineItemStatusExpired,objAsset.Status__c);        
                }
                else if(objAsset.id == objAssetLineItem2.id)
                {
                    System.assertEquals(System.Label.AssetLineItemStatusActivated,objAsset.Status__c);
                }
            }  
        List<Apttus_Proposal__Proposal_Line_Item__c> lstUndeletedPli = [SELECT id FROM Apttus_Proposal__Proposal_Line_Item__c where id in :lnItemIds ALL Rows];
        undelete lstUndeletedPli; 
        lstUndeletedPli = [SELECT id FROM Apttus_Proposal__Proposal_Line_Item__c where id in :lnItemIds];
        System.debug('<--lstUndeletedPli-->' +lstUndeletedPli.size());
        system.assertEquals(2,lstUndeletedPli.size()); 			
        Test.stopTest();
    }

       

    @isTest
    static void testRenewalAssetLineItemHistoryStatus()
    {
    	Account acc = [Select Id from Account limit 1];
    	
    	Product2 thisProduct = [Select Id From Product2 limit 1];
Apttus_Proposal__Proposal__c proposal = [Select id From Apttus_Proposal__Proposal__c LIMIT 1];
    	

    	Apttus_Config2__Order__c objOrder = new Apttus_Config2__Order__c();
    	objOrder.Apttus_QPConfig__ProposalId__c = proposal.Id;
    	insert objOrder;

    	Apttus_Config2__AssetLineItem__c objAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem.Apttus_Config2__AssetStatus__c = ASSETSTATUSPENDINGRENEWAL;
        objAssetLineItem.Status__c = ASSETSTATUSPENDINGRENEWAL;
        objAssetLineItem.Apttus_Config2__AccountId__c = acc.Id;
        objAssetLineItem.Apttus_Config2__ProductId__c = thisProduct.Id;
        objAssetLineItem.Serial_Number__c = '123123';
        objAssetLineItem.Contract_Number__c = '453523413';
        objAssetLineItem.Contract_Type__c = 'test Contract Type';
        objAssetLineItem.Apttus_QPConfig__ProposalId__c = proposal.Id;
        objAssetLineItem.Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Status__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Apttus_Config2__EndDate__c = Date.valueOf('2017-12-31');
        objAssetLineItem.Apttus_Config2__StartDate__c = Date.valueOf('2017-10-01');
        objAssetLineItem.Apttus_Config2__OriginalStartDate__c = Date.valueOf('2017-10-01');
        insert objAssetLineItem;

    	Apttus_Config2__AssetLineItemHistory__c objAssetLineItemHistory = new Apttus_Config2__AssetLineItemHistory__c();
    	objAssetLineItemHistory.Apttus_Config2__AssetStatus__c = ASSETSTATUSNEW;
    	objAssetLineItemHistory.Apttus_Config2__AssetLineItemId__c = objAssetLineItem.Id;
    	insert objAssetLineItemHistory;

    	Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
    	objOrderLineItem.Apttus_Config2__AssetLineItemId__c = objAssetLineItem.Id;
    	objOrderLineItem.Apttus_Config2__LineStatus__c = System.Label.LineItemLineStatusRenewed;
    	objOrderLineItem.Apttus_Config2__OrderId__c = objOrder.Id;
    	insert objOrderLineItem;

    	Test.startTest();
    	
    	objAssetLineItemHistory.Apttus_Config2__AssetStatus__c = ASSETSTATUSPENDINGRENEWAL;
    	update objAssetLineItemHistory;

    	Test.stopTest();
    	Apttus_Config2__AssetLineItemHistory__c thisAssetLineItemHistory = [Select Id, Apttus_Config2__AssetStatus__c From Apttus_Config2__AssetLineItemHistory__c Where Apttus_Config2__AssetLineItemId__c = :objAssetLineItem.Id order by createddate desc limit 1];
    	
    	System.assertEquals(System.Label.LineItemLineStatusRenewed, thisAssetLineItemHistory.Apttus_Config2__AssetStatus__c);

    }

    @isTest
    static void testNewAssetLineItemStatus()
    {

    	Account acc = [Select Id from Account limit 1];
    	Apttus_Proposal__Proposal__c proposal = [Select id From Apttus_Proposal__Proposal__c LIMIT 1];
    	Product2 thisProduct = [Select Id From Product2 limit 1];
    	
    	Apttus_Config2__AssetLineItem__c objAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem.Apttus_Config2__AssetStatus__c = ASSETSTATUSNEW;
        objAssetLineItem.Status__c = ASSETSTATUSPENDINGACTIVATION;
        objAssetLineItem.Apttus_Config2__AccountId__c = acc.Id;
        objAssetLineItem.Apttus_Config2__ProductId__c = thisProduct.Id;
        objAssetLineItem.Serial_Number__c = '123123';
        objAssetLineItem.Contract_Number__c = '453523413';
        objAssetLineItem.Contract_Type__c = 'test Contract Type';
        objAssetLineItem.Apttus_QPConfig__ProposalId__c = proposal.Id;
        objAssetLineItem.Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Status__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Apttus_Config2__EndDate__c = Date.valueOf('2017-12-31');
        objAssetLineItem.Apttus_Config2__StartDate__c = Date.valueOf('2017-10-01');
        objAssetLineItem.Apttus_Config2__OriginalStartDate__c = Date.valueOf('2017-10-01');
        insert objAssetLineItem;

    	Test.startTest();
    	
    	objAssetLineItem.Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated;
    	update objAssetLineItem;

    	Test.stopTest();

    	Apttus_Config2__AssetLineItem__c thisAssetLineItem = [Select Id, Apttus_Config2__AssetStatus__c, Status__c from Apttus_Config2__AssetLineItem__c Where id = :objAssetLineItem.id];
    	System.assertEquals(System.Label.AssetLineItemStatusActivated, thisAssetLineItem.Status__c);
    }
}
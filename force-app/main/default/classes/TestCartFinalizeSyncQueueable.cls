/**
*    @author Akshay Mohan
*    @date   2021-05-10 
*    @description    DCP-38809: Test class for Auto Finalize cart
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-10          Initial Version
*         Adithi Acharya          29-Sept-2022        86% Class Coverage: CartSyncQueueable.cls
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestCartFinalizeSyncQueueable {
    private static final String PRICELIST = 'AMR-USD-US-01';
    private static final String AMR = 'AMR';
    private static final String USD = 'USD';
    private static final String USA = 'USA';
    private static final String OPPORTUNITYRTDIRECT = 'Direct';

    /**DCP-38809
	*	@author Akshay Mohan
	*	
	**/
    @testSetup
    static void setupData(){
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICELIST);
        insert objPriceList;

        Account objAccount = TestDataAccount.getNewAccount();
        TestDataPerson.getNewContact(objAccount.Id);
        objAccount.Territory_Region__c =AMR;
        objAccount.CurrencyIsoCode=USD;
        objAccount.Country_Local__c = USA;
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
        
        TestDataProposal.initPriceListItem(objProduct, objPriceList);
        
        
        TestDataProposal.getNewCart(objProposal);
        
        List<Apttus_Config2__ClassificationName__c> lstCategory = new List<Apttus_Config2__ClassificationName__c>();
        
        Apttus_Config2__ClassificationName__c objCategory = TestDataProposal.initCategory('Test Category');
        lstCategory.add(objCategory);
        insert lstCategory;

        Apttus_CPQApi.CPQ.CreateCartRequestDO createCartRequest = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        createCartRequest.QuoteId = objProposal.Id;
        Apttus_CPQApi.CPQ.CreateCartResponseDO createCartResponse = Apttus_CPQApi.CPQWebService.createCart(createCartRequest);

        

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addProductRequest.CartId = createCartResponse.CartId;
        
        Apttus_CPQApi.CPQ.SelectedProductDO selectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectedProduct.ProductId = objProduct.Id;
        selectedProduct.Quantity = 1;
        selectedProduct.SellingTerm = 12;
        addProductRequest.SelectedProducts.add(selectedProduct);

        Apttus_CPQApi.CPQWebService.addMultiProducts(addProductRequest);


        List<Apttus_Config2__LineItem__c> lstLi = [Select Id, Global_Trade_Block__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :createCartResponse.CartId];

        lstLi.get(0).Global_Trade_Block__c = false;
        update lstLi;

    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	
	**/
    @isTest
    static void testFinalize(){
        Apttus_Config2__ProductConfiguration__c prodConfig = [Select Id From Apttus_Config2__ProductConfiguration__c LIMIT 1];
        CartFinalizeQueueable queueable = new CartFinalizeQueueable();
        queueable.setRecordId(prodConfig.Id);
        Test.startTest();
        queueable.execute(null);
        queueable.getErrorDetails();
        Test.stopTest();
        System.assert(String.isBlank(queueable.getRecordId()),'No Error while finalizing');
    }

    
    /**DCP-38809
	*	@author Akshay Mohan
	*	
	**/
    @isTest
    static void testSync(){
        Apttus_Config2__ProductConfiguration__c prodConfig = [Select Id From Apttus_Config2__ProductConfiguration__c LIMIT 1];
        CartSyncQueueable queueable = new CartSyncQueueable();
        queueable.setRecordId(prodConfig.Id);
        Test.startTest();
        queueable.execute(null);
        queueable.getErrorDetails();
        Test.stopTest();
        System.assert(String.isBlank(queueable.getRecordId()),'No Error while syncing');
    }
     /**
	*	@author Adithi Acharya
    *   @description 86% Class Coverage: CartSyncQueueable.cls
	**/
    @isTest
    static void testRunTestCartFinalizeSyncQueueable(){
        CartSyncQueueable.boolRunTestCartFinalizeSyncQueueable=true;
        Apttus_Config2__ProductConfiguration__c prodConfig = [Select Id From Apttus_Config2__ProductConfiguration__c LIMIT 1];
        CartSyncQueueable queueable = new CartSyncQueueable();
        queueable.setRecordId(prodConfig.Id);
        Test.startTest();
        queueable.execute(null);
        queueable.getErrorDetails();
        Test.stopTest();
        System.assert(String.isBlank(queueable.getRecordId()),'No Error while syncing');
    }
    
    
    
}
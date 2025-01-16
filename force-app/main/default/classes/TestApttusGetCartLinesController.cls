/**
 * @author Rahul Sharma
 * @date   12-Apr-2019
 * @description  Test class of ApttusGetCartLinesController
 * Modification Log:
 *  --------------------------------------------------------------------------------------------------
 *   Developer                Date                Description                                                  
 *   Rahul Sharma           12-Apr-2019        Original Version
 *   Satya Swain            09 Dec 2022        Added Codescan fix for Variable Naming Convention
 * ---------------------------------------------------------------------------------------------------
**/

@isTest(isParallel=true) 
public class TestApttusGetCartLinesController {

	public static final Integer INTEGER_QUANTITY = 2;
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 1;

    @testSetup
    static void setupData(){
        Account objAcc = TestDataAccount.getNewAccount();
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('01-AMR-USD');
        insert objPriceList;
        
        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAcc);
        objOpportunity.Ultimate_Consignee__c = objAcc.Id;
        objOpportunity.Price_List__c = objPriceList.Name;
        update objOpportunity; 
        
        Apttus_Proposal__Proposal__c objProposal1 = TestDataProposal.initProposal(objAcc.id, objOpportunity.id, 'Test Proposal 1', objPriceList.id, true, 'Draft', 'None');
        Apttus_Proposal__Proposal__c objProposal2 = TestDataProposal.initProposal(objAcc.id, objOpportunity.id, 'Test Proposal 2', objPriceList.id, true, 'Draft', 'None');
        insert new List<Apttus_Proposal__Proposal__c>{objProposal1,objProposal2};
        
		Product2 objProduct1 = TestDataMaster.createProduct(false); 
        Product2 objProduct2 = TestDataMaster.createProduct(false); 
        insert new List<Product2>{objProduct1,objProduct2};
        objProduct1.Name = 'Test Product 1';
        objProduct2.Name = 'Test Product 2';
        update new List<Product2>{objProduct1,objProduct2};

        Apttus_Config2__PriceListItem__c priceListItem1 = TestDataProposal.initPriceListItem(objProduct1, objPriceList);
        priceListItem1.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;

        Apttus_Config2__PriceListItem__c priceListItem2 = TestDataProposal.initPriceListItem(objProduct2, objPriceList);
        priceListItem2.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        insert new List<Apttus_Config2__PriceListItem__c>{priceListItem1,priceListItem2};

    }

    /**
    *  @author      : Rahul Sharma
    *  @description : Apply Suggested sales discount to cart lines
    */
    @isTest
    static void applyCartLines(){
    	 Map<Id, Apttus_Config2__LineItem__c> mapSelectedProducts = new Map<Id, Apttus_Config2__LineItem__c>();
    	 List<Apttus_Config2__LineItem__c> lstSelectedProducts = new List<Apttus_Config2__LineItem__c>();
    	 Boolean hasPrevious;
    	 Boolean hasNext;
    	 Integer pageNumber;


    	Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal 1'];
        
        Product2 objProduct1 = [SELECT Id FROM Product2 WHERE Name like '%Test Product 1'];

        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = objProposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference('Page.ApttusGetCartLines'));
        System.currentPageReference().getParameters().put('businessObjectId', objProposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id );

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = objProduct1.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);
        
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct2 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct2.ProductId = objProduct1.Id;
        selectProduct2.Quantity = 1;
        selectProduct2.SellingTerm = 12;
        selectProduct2.StartDate = Date.today();
        selectProduct2.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct2);
        
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct3 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct3.ProductId = objProduct1.Id;
        selectProduct3.Quantity = 1;
        selectProduct3.SellingTerm = 12;
        selectProduct3.StartDate = Date.today();
        selectProduct3.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct3);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        List<Apttus_Config2__LineItem__c> lstInsertedProducts = [SELECT Id,Apttus_Config2__LineNumber__c,Suggested_Sales_Discount_Percentage__c,Sales_Discretionary_Type__c,Suggested_Sales_Discount_Amount__c from Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        System.debug('Apply lstInsertedProducts:'+lstInsertedProducts);

        Apttus_Config2__PriceListItem__c priceListItem1 = [SELECT Id FROM Apttus_Config2__PriceListItem__c WHERE Apttus_Config2__ProductId__c=:objProduct1.Id];

        for(Integer idx=0; idx<lstInsertedProducts.size(); idx++){
            Apttus_Config2__LineItem__c lineitem = lstInsertedProducts.get(idx);
            if(idx == 0){
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=priceListItem1.id;
                lineitem.Apttus_Config2__Quantity__c=1;    
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Suggested_Sales_Discount_Percentage__c = 'NA';
                lineitem.Apttus_Config2__PriceListItemId__c = priceListItem1.Id;
                lineitem.Apttus_Config2__LineNumber__c = 1;
            }
            if(idx == 1){
               lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=priceListItem1.id;
                lineitem.Apttus_Config2__Quantity__c=1;    
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Suggested_Sales_Discount_Percentage__c = 'NA';
                lineitem.Apttus_Config2__PriceListItemId__c = priceListItem1.Id;
                lineitem.Suggested_Sales_Discount_Percentage__c = '17.17';
                lineitem.Sales_Discretionary_Type__c = null;
                lineitem.Apttus_Config2__LineNumber__c = 2;
            }   
            if(idx == 2){
               lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=priceListItem1.id;
                lineitem.Apttus_Config2__Quantity__c=1;    
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Suggested_Sales_Discount_Percentage__c = 'NA';
                lineitem.Apttus_Config2__PriceListItemId__c = priceListItem1.Id;
                lineitem.Suggested_Sales_Discount_Percentage__c = '17.17';
                lineitem.Sales_Discretionary_Type__c = null;
                lineitem.Apttus_Config2__PriceListItemId__c = priceListItem1.Id;
                lineitem.Apttus_Config2__LineNumber__c = 3;
                lineitem.Suggested_Sales_Discount_Amount__c = 177.17;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypeDiscountAmount;
                lineitem.Apttus_Config2__PriceListItemId__c = priceListItem1.Id;  
            }   
            
        }
        update lstInsertedProducts;

        for(Apttus_Config2__LineItem__c lineItem : lstInsertedProducts){
        	mapSelectedProducts.put(lineItem.id, lineItem);
        	lstSelectedProducts.add(lineItem);
        }

        Test.startTest();
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstSelectedProducts);
        stdSetController.setSelected(lstSelectedProducts);
        ApttusGetCartLinesController cartController = new ApttusGetCartLinesController();
        cartController.getProducts();
        hasPrevious = cartController.hasPrevious;
        hasNext = cartController.hasNext;
        pageNumber = cartController.pageNumber;
        cartController.apply();
        cartController.redirectToCart();
        Test.stopTest();

        List<Apttus_Config2__LineItem__c> lstApplyProducts = [SELECT Id,Apttus_Config2__LineNumber__c,Suggested_Sales_Discount_Percentage__c,Sales_Discretionary_Type__c,Suggested_Sales_Discount_Amount__c,Sales_Discretionary_Discount__c,Global_Trade_Block__c from Apttus_Config2__LineItem__c WHERE Apttus_Config2__LineNumber__c IN (1,2,3)];
        System.debug('lstApplyProducts:'+lstApplyProducts);
        for(Apttus_Config2__LineItem__c lineItem : lstApplyProducts){
            if(lineItem.Apttus_Config2__LineNumber__c == 1){
                System.assert(String.isBlank(String.valueOf(lineItem.Sales_Discretionary_Discount__c)),'Suggested Sales discount is applied incorrectly.');
            }
            if(lineItem.Apttus_Config2__LineNumber__c == 2){
                System.assertEquals(Decimal.valueOf(lineItem.Suggested_Sales_Discount_Percentage__c),lineItem.Sales_Discretionary_Discount__c,'Suggested Sales discount percentage is applied incorrectly.');
                System.assertEquals(Label.LineItemSalesDiscretionaryTypePercentageDiscount,lineItem.Sales_Discretionary_Type__c,'Sales Discretionary Type is applied incorrectly.');
            }
            if(lineItem.Apttus_Config2__LineNumber__c == 3){
                System.assertEquals(lineItem.Suggested_Sales_Discount_Amount__c,lineItem.Sales_Discretionary_Discount__c,'Suggested Sales discount amount is applied incorrectly.');
            }
        }

    }

    /**
    *  @author      : Rahul Sharma
    *  @description : Remove suggested sales discount to Cart Lines
    */
    @isTest
    static void removeCartLines(){
         Map<Id, Apttus_Config2__LineItem__c> mapSelectedProducts = new Map<Id, Apttus_Config2__LineItem__c>();
         List<Apttus_Config2__LineItem__c> lstSelectedProducts = new List<Apttus_Config2__LineItem__c>();
         Boolean hasPrevious;
         Boolean hasNext;
         Integer pageNumber;


        Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal 2'];
        
        Product2 objProduct2 = [SELECT Id FROM Product2 WHERE Name like '%Test Product 2'];

        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = objProposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference('Page.ApttusGetCartLines'));
        System.currentPageReference().getParameters().put('businessObjectId', objProposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id );

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = objProduct2.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        List<Apttus_Config2__LineItem__c> lstInsertedProducts = [SELECT Id,Sales_Discretionary_Discount__c from Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        System.debug('Remove lstInsertedProducts:'+lstInsertedProducts);

        Apttus_Config2__PriceListItem__c priceListItem2 = [SELECT Id FROM Apttus_Config2__PriceListItem__c WHERE Apttus_Config2__ProductId__c=:objProduct2.Id];
        for(Integer idx=0; idx<lstInsertedProducts.size(); idx++){
            Apttus_Config2__LineItem__c lineitem = lstInsertedProducts.get(idx);
            if(idx == 0){
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__Quantity__c=1;    
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Sales_Discretionary_Discount__c = 170.00;
                lineitem.Apttus_Config2__PriceListItemId__c = priceListItem2.Id;
            }
        }
        update lstInsertedProducts;

        for(Apttus_Config2__LineItem__c lineItem : lstInsertedProducts){
            mapSelectedProducts.put(lineItem.id, lineItem);
            lstSelectedProducts.add(lineItem);
        }

        Test.startTest();
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstSelectedProducts);
        stdSetController.setSelected(lstSelectedProducts);
        ApttusGetCartLinesController cartController = new ApttusGetCartLinesController();
        cartController.getProducts();
        hasPrevious = cartController.hasPrevious;
        hasNext = cartController.hasNext;
        pageNumber = cartController.pageNumber;
        cartController.remove();
        cartController.redirectToCart();
        Test.stopTest();

    List<Apttus_Config2__LineItem__c> lstRemoveProducts = [SELECT Id,Sales_Discretionary_Discount__c,Global_Trade_Block__c from Apttus_Config2__LineItem__c WHERE Apttus_Config2__ProductId__c =:objProduct2.Id LIMIT 1];
    System.debug('lstRemoveProducts:'+lstRemoveProducts);
    System.assert(String.isBlank(String.valueOf(lstRemoveProducts[0].Sales_Discretionary_Discount__c)),'Suggested Sales Discount is removed incorrectly.');
    System.assertEquals(false,lstRemoveProducts[0].Global_Trade_Block__c,'GT Check value is incorrect.');
}

}
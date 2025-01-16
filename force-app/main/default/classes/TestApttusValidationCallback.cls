/* @ author       : Satya Swain
* @ date         : 07-04-2018
* @ Description  : TestApttusValidationCallback is the test class for ApttusValidationCallback
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Satya Swain          07-04-2018                  DCP-1061            Initial version
* Satya Swain          09-24-2018                  DCP-449             Modification as part of DCP-449
* Satya Swain          10-06-2018                  DCP-2774            Modification as part of DCP-2774
* Kristiyan Petkov     10-18-2018                  DCP-14179           Modification as part of DCP-14179
* Kristiyan Petkov     10-26-2018                  DCP-11002           Modification as part of DCP-11002
* Saswati Prusty       04-09-2019                  DCP-10444           Modification as part of DCP-10444
* Kushagra Desai       24-June-2019                 DCP-26680
* Anish Pathak         25-Sept-2019                DCP-29915           Modifications as part of DCP-29915
*/

@isTest(isParallel = true)
public with sharing class TestApttusValidationCallback {   
    
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;
    public static final Integer INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER = NULL;
    public static final Integer INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER = 10;
    public static final Integer INTEGER_BLANK_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER = NULL;
    public static final Integer INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER = 15;
    public static final Integer INTEGER_BLANK_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER = NULL;
    public static final String STRING_BLANK_COST_CENTER = NULL;
    public static final String STRING_BLANK_SOFTWARE_TYPE = NULL;
    public static final String BLOCKED_FOR_SALES = 'Blocked for Sales';
    public static final String BLOCKED_FOR_SHIPMENT = 'Blocked for Shipment';
    public static final String SAP_CROSS_PLANT_STATUS_INACTIVE = 'Inactive';

    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.getNewAccount();
        TestDataAccount.getNewAccount();

        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        opp.Type = 'Upsell with Service Contract Renewal';
        opp.Sold_to_Sales_Organization__c = 'Test Sales Organization';
        opp.Sold_to_Distribution_Channel__c = 'Test Distribution Channel';
        opp.Direct_Sale_to_Ultimate_Consignee__c = true;
        update opp;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        List<Product2> lstProduct = new List<Product2>();
        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProduct.End_Of_Sale_Date__c = Date.today()-1;
        objProduct.End_Of_Service_Date__c = Date.today();
        lstProduct.add(objProduct);

        Product2 objProductTwo = TestDataMaster.createProduct(false);
        objProductTwo.Cross_Distribution_Chain_Status__c = BLOCKED_FOR_SALES;
        objProductTwo.SFDC_Block__c = 'SFDC_SALES_BLOCK';
        objProductTwo.Cross_Plant_Material_Status__c = SAP_CROSS_PLANT_STATUS_INACTIVE;
        objProductTwo.End_Of_Sale_Date__c = Date.today();
        objProductTwo.End_Of_Service_Date__c = Date.today()-1;
        objProductTwo.Material_Class__c = Label.ProductMaterialClassServices;
        objProductTwo.Custom_Product__c = true;
        objProductTwo.Line_Of_Business_Code__c = 'MA';      
        lstProduct.add(objProductTwo);

        Product2 objProductThree = TestDataMaster.createProduct(false);
        objProductTwo.End_Of_Sale_Date__c = Date.today()-1;
        objProductTwo.End_Of_Service_Date__c = Date.today()-1;
        objProductThree.Custom_Product__c = true;
        objProductThree.Line_Of_Business_Code__c = 'SQ';
        lstProduct.add(objProductThree);
        
        Product2 objProductFour = TestDataMaster.createProduct(false);
        objProductFour.Material_Class__c = Label.ProductMaterialClassInformaticsSoftware;
        objProductFour.End_Of_Sale_Date__c = Date.today()-1;
        objProductFour.End_Of_Service_Date__c = Date.today();
        lstProduct.add(objProductFour);
        
        Product2 objProductFive = TestDataMaster.createProduct(false);
        objProductFive.Material_Class__c = Label.ProductMaterialClassInformaticsSoftware;
        objProductFive.End_Of_Sale_Date__c = Date.today();
        objProductFive.End_Of_Service_Date__c = Date.today();
        lstProduct.add(objProductFive);
		
		/*Uncommented objProductSix for DCP-29915*/
        Product2 objProductSix = TestDataMaster.createProduct(false);
        objProductSix.Cross_Distribution_Chain_Status__c = BLOCKED_FOR_SALES;
        objProductSix.SFDC_Block__c = 'SFDC_SALES_BLOCK';
        objProductSix.Cross_Plant_Material_Status__c = SAP_CROSS_PLANT_STATUS_INACTIVE;
        objProductSix.End_Of_Sale_Date__c = Date.today() - 1;
        objProductSix.End_Of_Service_Date__c = Date.today() - 1;
        objProductSix.Material_Class__c = Label.ProductMaterialClassServices;
        objProductSix.Custom_Product__c = true;
        objProductSix.Line_Of_Business_Code__c = 'MA';      
        lstProduct.add(objProductSix);

        insert lstProduct;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries()); 

        TestDataApttusAsset.getNewAssetLineItem(acc.Id, acc.Id, lstProduct.get(0).Id);

        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert proposal;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        List<Product_Sales_Area__c> listProductSalesArea = new List<Product_Sales_Area__c>();

        Product_Sales_Area__c productSalesArea = new Product_Sales_Area__c();
        productSalesArea.Product__c = objProduct.id;
        productSalesArea.Sales_Organization__c = 'Test Sales Organization';
        productSalesArea.Distribution_Channel__c = 'Test Distribution Channel';
        productSalesArea.Distribution_Chain_Specific_Status__c = BLOCKED_FOR_SHIPMENT;
        listProductSalesArea.add(productSalesArea);

        Product_Sales_Area__c productSalesArea2 = new Product_Sales_Area__c();
        productSalesArea2.Product__c = objProductTwo.id;
        productSalesArea2.Sales_Organization__c = 'Test Sales Organization';
        productSalesArea2.Distribution_Channel__c = 'Test Distribution Channel';
        productSalesArea2.Distribution_Chain_Specific_Status__c = BLOCKED_FOR_SHIPMENT;
        listProductSalesArea.add(productSalesArea2);

        Product_Sales_Area__c productSalesArea3 = new Product_Sales_Area__c();
        productSalesArea2.Product__c = objProductThree.id;
        productSalesArea2.Sales_Organization__c = 'Test Sales Organization';
        productSalesArea2.Distribution_Channel__c = 'Test Distribution Channel';
        productSalesArea2.Distribution_Chain_Specific_Status__c = BLOCKED_FOR_SHIPMENT;
        listProductSalesArea.add(productSalesArea3);
        insert listProductSalesArea;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

		/*Uncommented productSalesArea5 for DCP-29915*/
        Product_Sales_Area__c productSalesArea5 = new Product_Sales_Area__c();
        productSalesArea2.Product__c = objProductSix.id;
        productSalesArea2.Sales_Organization__c = 'Test Sales Organization';
        productSalesArea2.Distribution_Channel__c = 'Test Distribution Channel';
        productSalesArea2.Distribution_Chain_Specific_Status__c = BLOCKED_FOR_SHIPMENT;
        listProductSalesArea.add(productSalesArea5);

        TestDataProposal.getNewCart(proposal);

        //Restricted_Product__c objRestrictedProduct = TestDataProposal.initRestrictedProduct(acc2, lstProduct.get(2));
        //insert objRestrictedProduct;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
        List<Apttus_Config2__PriceListItem__c> lstPriceList = new List<Apttus_Config2__PriceListItem__c>();
        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(objProduct, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItem);
        Apttus_Config2__PriceListItem__c priceListItemTwo = TestDataProposal.initPriceListItem(objProductTwo, priceList);
        priceListItemTwo.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        
        lstPriceList.add(priceListItemTwo);
        
        Apttus_Config2__PriceListItem__c priceListItemThree = TestDataProposal.initPriceListItem(objProductThree, priceList);
        lstPriceList.add(priceListItemThree);

		/*Uncommented priceListItemFive for DCP-29915*/
        Apttus_Config2__PriceListItem__c priceListItemFive = TestDataProposal.initPriceListItem(objProductSix, priceList);
        lstPriceList.add(priceListItemFive); 

        insert lstPriceList;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        Apttus_Config2__ConfigCustomClasses__c configCustomClass = TestDataProposal.getNewConfigCustomClass();
        configCustomClass.Apttus_Config2__PricingCallbackClass__c = 'ApttusPricingCallback';
        configCustomClass.Name = 'System Properties';
        update configCustomClass;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
        TestDataProposal.getNewConfigLineItemCustomField();
        TestDataProposal.getNewConfigLineItemCustomField1();
    }

    @isTest
    static void testCartValidation()
    {        
        Apttus_Proposal__Proposal__c proposal = [Select id From Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> lstProduct = [Select id From Product2 LIMIT 10];
        lstProduct.get(0).Material_Class__c = Label.ProductMaterialClassInformaticsSoftware;
        update lstProduct.get(0);
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        Apttus_Config2__AssetLineItem__c objAssetLineItem = [SELECT Id FROM Apttus_Config2__AssetLineItem__c];
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries()); 

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        update objProductConfig;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        Test.setCurrentPageReference(new PageReference('Page.ApttusCheckPrice'));
        System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id );

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = lstProduct.get(0).Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);
        
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct2 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct2.ProductId = lstProduct.get(1).Id;
        selectProduct2.Quantity = 1;
        selectProduct2.SellingTerm = 12;
        selectProduct2.StartDate = Date.today();
        selectProduct2.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct2);
        
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct3 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct3.ProductId = lstProduct.get(2).Id;
        selectProduct3.Quantity = 1;
        selectProduct3.SellingTerm = 12;
        selectProduct3.StartDate = Date.today();
        selectProduct3.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct3);

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct4 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct4.ProductId = lstProduct.get(3).Id;
        selectProduct4.Quantity = 1;
        selectProduct4.SellingTerm = 12;
        selectProduct4.StartDate = Date.today();
        selectProduct4.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct4);  

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct5 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct5.ProductId = lstProduct.get(1).Id;
        selectProduct5.Quantity = 1;
        selectProduct5.SellingTerm = 12;
        selectProduct5.StartDate = Date.today();
        selectProduct5.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct5); 

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct6 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct6.ProductId = lstProduct.get(2).Id;
        selectProduct6.Quantity = 1;
        selectProduct6.SellingTerm = 12;
        selectProduct6.StartDate = Date.today();
        selectProduct6.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct6);

		/*Uncommented selectProduct7 for DCP-29915*/
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct7 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct6.ProductId = lstProduct.get(5).Id;
        selectProduct6.Quantity = 1;
        selectProduct6.SellingTerm = 12;
        selectProduct6.StartDate = Date.today();
        selectProduct6.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct6); 
		Test.startTest();
        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = [select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c ];
        lstPriceListItemId[0].Apttus_Config2__PriceType__c = 'One Time';

        //DCP-26680 : Added new field for data setup
        for(Integer idx=0; idx<lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if(idx == 0)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = Date.today() + 300;
                lineitem.Apttus_Config2__EndDate__c = Date.today() + 380;
                lineitem.Sales_Discretionary_Discount__c = 100;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Sales_Discretionary_Type__c = NULL;
                lineitem.Cost_Center__c = STRING_BLANK_COST_CENTER;
                lineitem.Software_Type__c = STRING_BLANK_SOFTWARE_TYPE;
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c =  Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__AssetLineItemId__c = objAssetLineItem.id;
                lineitem.Apttus_Config2__LineStatus__c = Label.LineItemLineStatusRenewed;
                lineitem.Price_Override__c = 900;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Trade_In_Type__c='Marketing External';
                lineitem.Line_Item_Old_Values__c = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}';
            }
            else if(idx == 1)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Applied_Discount_Amount__c = 30000;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Sales_Discretionary_Discount__c = 150;
                lineitem.Sales_Discretionary_Type__c = 'Discount Amount';
                lineitem.Volume_Discount__c = 30;
                lineitem.Promotion_Discount__c= 50;
                lineitem.Apttus_Config2__BasePriceOverride__c=200;
                lineitem.Price_Override__c = 900;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Apttus_Config2__PriceType__c =  Label.PriceListItemPriceTypeRecurring;
                lineitem.Trade_In_Type__c='Marketing External';
                lineitem.Apttus_Config2__PriceListItemId__c = lstPriceListItemId.get(0).id;
            }
            else if(idx == 2)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__PriceType__c =  Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__LineStatus__c= Label.LineItemLineStatusRenewed;
                lineitem.Price_Override__c = 900;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Trade_In_Type__c='Marketing External';
                lineitem.Line_Item_Validate_Old__c = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}';
            }
            else if(idx ==3)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Applied_Discount_Percentage__c = 102;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;  
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Price_Override__c = 900;
                lineitem.Customer_Net_Price__c= 300;
                lineitem.Apttus_Config2__NetPrice__c = 500;
                lineitem.Apttus_Config2__OptionId__c = selectedProducts[3].ProductId;
                lineitem.Trade_In_Type__c='Marketing External';
                lineitem.Line_Item_Validate_Old__c = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}';
            }
            else if(idx ==4)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Applied_Discount_Percentage__c = 102;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;  
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
                lineitem.Price_Override__c = 900;
                lineitem.Customer_Net_Price__c= 300;
                lineitem.Apttus_Config2__NetPrice__c = 500;
                lineitem.Trade_In_Type__c='Marketing External';
                lineitem.Apttus_Config2__OptionId__c = selectedProducts[4].ProductId;
                lineitem.Line_Item_Validate_Old__c = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}';
            }
            else if(idx ==5)
            {
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Applied_Discount_Percentage__c = 102;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;  
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
                lineitem.Price_Override__c = 900;
                lineitem.Customer_Net_Price__c= 300;
                lineitem.Apttus_Config2__NetPrice__c = 500;
                lineitem.Trade_In_Type__c='Marketing External';
                lineitem.Apttus_Config2__OptionId__c = selectedProducts[5].ProductId;
                lineitem.Line_Item_Validate_Old__c = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}';
                lineitem.Line_Item_Old_Values__c = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}';
            }
            else if(idx ==6)
            {
                 //Uncommented this else if block for DCP-29915
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Applied_Discount_Percentage__c = 102;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;  
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
                lineitem.Price_Override__c = 900;
                lineitem.Customer_Net_Price__c= 300;
                lineitem.Trade_In_Type__c='Marketing External';
                lineitem.Apttus_Config2__NetPrice__c = 3000; // INC0330527
                lineitem.Apttus_Config2__OptionId__c = selectedProducts[6].ProductId;
                lineitem.Hide_Contract_Dates__c = false;
                lineitem.Customer_Premium_Amount_Per_Unit__c = 2000; // INC0330527
            }
        }

        update lineItemList;
    	System.debug('Number of line items: ' + lineItemList.size());
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        //Test.startTest();
        Apttus_Config2.CustomClass.ValidationResult result = Apttus_Config2.CPQWebService.validateCart(objProductConfig.Id);
        
        Test.stopTest();

        // error messages this method validates
        Map <String, Boolean> errorMessageToFoundInResult = new Map<String, Boolean> {
            Label.UI_ErrorMessage_Custom_Beadchip_Missing => false,
            Label.UI_ErrorMessage_Custom_Project_Id_Missing => false,
            //Label.UI_ErrorMessage_BlankShippingInCloseQuarter => false,
            Label.UI_ErrorMessage_ShippingInCloseQuarterGreaterThanQuantity => false,
            Label.UI_ErrorMessage_Renewal_Product_Blank_StartDate_EndDate => false,
            Label.UI_ErrorMessage_Renewal_Product_Blank_StartDate_EndDate => false,
            Label.UI_ErrorMessage_CostCenterBlank => false,
            Label.UI_ErrorMessage_SoftwareTypeBlank => false, 
            Label.UI_ErrorMessage_DiscountGreaterThanHundredPercent => false,
            Label.UI_ErrorMessage_BlankSalesDiscretionaryType => false,
            Label.UI_ErrorMessage_RenewalStartDate => false,
            Label.UI_ErrorMessage_Product_Under_Sales_Block => false,
            Label.UI_ErrorMessage_Product_Material_Cannot_Be_Quoted => false,
            Label.UI_ErrorMessage_Product_Within_End_Of_Sale_Date => false,
            Label.UI_AddErrorForEndOfSaleDateOrServiceDate => false,
            Label.UI_ErrorMessage_Inactive_Product => false,
            Label.UI_Text_Reason_For_Price_Override_Error => false,
            Label.UI_ErrorMessage_CustomerPrice_Higher_Than_Distributor_Net_Price => false
        };

        // validate messages
        for (ApexPages.Message msg : result.Messages)
        {
            String errorText = msg.getSummary();
            if (errorMessageToFoundInResult.containsKey(errorText))
                errorMessageToFoundInResult.put(errorText, true);
            if (errorText.contains(Label.UI_AddErrorForEndOfSaleDateOrServiceDate))
            {
                errorMessageToFoundInResult.put(Label.UI_AddErrorForEndOfSaleDateOrServiceDate, true);
            }
            if (errorText.contains(Label.UI_ErrorMessage_Product_Material_Cannot_Be_Quoted))
            {
                //Added label for DCP-29915
                errorMessageToFoundInResult.put(Label.UI_ErrorMessage_Product_Material_Cannot_Be_Quoted, true);
            }
        }      

        for (String errorMessage : errorMessageToFoundInResult.keySet())
        {
            System.assert(errorMessageToFoundInResult.get(errorMessage), 'Not fired :: ' + errorMessage);
        }
    }

}
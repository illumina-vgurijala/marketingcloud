/**
*    @author  Khushbu Vasani 
*    @date   2018-09-17
*    @description  Test class for ApttusPricingCallBack for DCP-53200
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Khushbu Vasani                   28-06-2022              Original method 
**/
@isTest(isParallel=false)
public class TestApttusPricingCallBack {

    
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;   
    public static final Integer INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER = 10;
    public static final Integer INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER = 15;
    public static final String STRING_BLANK_COST_CENTER = 'Cost_Center';


    @testSetup
     static void setupData()
     {
        Account acc = TestDataAccount.getNewAccount();
        acc.Open_Offer_Comparison_Customer__c = true;
        acc.National_Group_Number__c = acc.ERP_Customer_ID__c;
        update acc;
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        List<Opportunity> lstopp = new List<Opportunity>();
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        System.debug('+++++++ Opp Type: '+opp.Type);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp);
        
        update lstopp;

        List<Apttus_Proposal__Proposal__c> lstProp = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        //proposal.Apttus_QPConfig__PricingDate__c = Datetime.now()+1;
        proposal.Apttus_QPConfig__PricingDate__c =  Datetime.newInstance(2022, 6, 1, 00, 00,00);
        proposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        //proposal.Promotion_JSON__c='[{"PromoCode":"NEWBEE","PromoChannel":null},{"PromoCode":"ICT-000021","PromoChannel":null},{"PromoCode":"ICT-000022","PromoChannel":null}] ';
        lstProp.add(proposal);
       
        insert lstProp;

        MockApttusSAPConnector.strQuoteNumber = lstProp[0].name;
        List<Product2> lstProduct = new List<Product2>();
        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Material_Class__c = Label.ProductMaterialClassInstrument;
        objProduct.End_Of_Sale_Date__c = Date.today() + 15; // Added for DCP-26583
        objProduct.Open_Offer_Product__c = true;
        objProduct.Open_Offer_Product_Category__c = 'NEXTSEQ 550';
        lstProduct.add(objProduct);

        Product2 objProductTwo = TestDataMaster.createProduct(false);
        objProductTwo.Material_Class__c = Label.ProductMaterialClassServices;
        objProductTwo.End_Of_Sale_Date__c = Date.today() + 15; // Added for DCP-26583
        objProductTwo.Open_Offer_Product__c = true;
        objProduct.Open_Offer_Product_Category__c = 'NEXTSEQ 550';
        lstProduct.add(objProductTwo);

        Product2 objProductThree = TestDataMaster.createProduct(false);
        objProductThree.Material_Class__c = Label.ProductMaterialClassConsumables;
        objProductThree.End_Of_Sale_Date__c = Date.today() + 15; // Added for DCP-26583
        objProductThree.Open_Offer_Product__c = true;
        objProductThree.Open_Offer_Product_Category__c = 'NEXTSEQ 550';
        lstProduct.add(objProductThree);

        insert lstProduct;


        List<Apttus_Config2__PriceListItem__c> lstPriceList = new List<Apttus_Config2__PriceListItem__c>();
        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(objProduct, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItem);
        Apttus_Config2__PriceListItem__c priceListItemTwo = TestDataProposal.initPriceListItem(objProductTwo, priceList);
        priceListItemTwo.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;

        lstPriceList.add(priceListItemTwo);
       
        insert lstPriceList;

        Apttus_Config2__ConfigCustomClasses__c configCustomClass = TestDataProposal.getNewConfigCustomClass();
        configCustomClass.Apttus_Config2__PricingCallbackClass__c = 'ApttusPricingCallback';
        configCustomClass.Name = 'System Properties';
        update configCustomClass;

        TestDataProposal.getNewConfigLineItemCustomField();
        TestDataProposal.getNewConfigLineItemCustomField1();
        Apttus_Config2__Incentive__c objIncentive=new Apttus_Config2__Incentive__c();
        objIncentive.Apttus_Config2__IncentiveCode__c='NEWBEE';
        objIncentive.Apttus_Config2__Sequence__c=1;

        insert objIncentive;

        List<Account_Discount_Tier__c> listAccountDiscountTier = new List<Account_Discount_Tier__c>();
        Account_Discount_Tier__c accTier = new Account_Discount_Tier__c();
        accTier.ERP_Customer_ID__c = acc.National_Group_Number__c;
        accTier.Pricing_Tier__c = 1;
        accTier.Discount_Type__c = 'Consumables';
        listAccountDiscountTier.add(accTier);

        accTier = new Account_Discount_Tier__c();
        accTier.ERP_Customer_ID__c = acc.National_Group_Number__c;
        accTier.Pricing_Tier__c = 1;
        accTier.Discount_Type__c = 'Instrument';
        listAccountDiscountTier.add(accTier);

        accTier = new Account_Discount_Tier__c();
        accTier.ERP_Customer_ID__c = acc.National_Group_Number__c;
        accTier.Pricing_Tier__c = 1;
        accTier.Discount_Type__c = 'Services';
        listAccountDiscountTier.add(accTier);

        insert listAccountDiscountTier;

        List<Pricing_Discount_Tier__c> listPricingTier = new List<Pricing_Discount_Tier__c>();
        Pricing_Discount_Tier__c pricingDis = new Pricing_Discount_Tier__c();
        pricingDis.UG_Discount_Type__c = 'Consumables';
        pricingDis.Discount_Tier__c = 1;
        pricingDis.Open_Offer_Product_Category__c = 'NEXTSEQ 550';
        pricingDis.Valid_From__c =  Datetime.newInstance(2022, 5, 1, 00, 00,00);
        pricingDis.Valid_To__c =  datetime.now().addDays(10);
        pricingDis.IsActive__c = true;
        pricingDis.Discount_Value__c = 10;
        listPricingTier.add(pricingDis);

        pricingDis = new Pricing_Discount_Tier__c();
        pricingDis.UG_Discount_Type__c = 'Instrument';
        pricingDis.Discount_Tier__c = 1;
        pricingDis.Open_Offer_Product_Category__c = 'NEXTSEQ 550';
        pricingDis.Valid_From__c =  Datetime.newInstance(2022, 5, 1, 00, 00,00);
        pricingDis.Valid_To__c =  datetime.now().addDays(10);
        pricingDis.Discount_Value__c = 11;
        pricingDis.IsActive__c = true;
        listPricingTier.add(pricingDis);

        pricingDis = new Pricing_Discount_Tier__c();
        pricingDis.UG_Discount_Type__c = 'Services';
        pricingDis.Discount_Tier__c = 1;
        pricingDis.Open_Offer_Product_Category__c = 'NEXTSEQ 550';
        pricingDis.Valid_From__c =  Datetime.newInstance(2022, 5, 1, 00, 00,00);
        pricingDis.Valid_To__c =  datetime.now().addDays(10);
        pricingDis.Discount_Value__c = 12;
        pricingDis.IsActive__c = true;
        listPricingTier.add(pricingDis);

       
        cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance(UserInfo.getprofileID());
            objApexSettings.Bypass_All_Validations__c=true;
            upsert objApexSettings cs_Apex_Settings__c.Id;
       
        insert listPricingTier;

        objApexSettings.Bypass_All_Validations__c=false;
        upsert objApexSettings cs_Apex_Settings__c.Id;
    } 

    /**
     *  @author Khushbu Vasani
     *  @description Test method for validate cart and check pricing functionality
     **/
     @isTest
     static void testCartValidationAndCheckPricings()
     {
        Feature.setMockFeatureFlag('OpenOfferDiscountPricingCallback', true);
        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c,Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal' LIMIT 1];
        System.debug('Proposal Type'+proposal.Quote_Sub_Type__c);
        List<Product2> lstProduct = [Select id From Product2 LIMIT 10];
        MockApttusSAPConnector.strQuoteNumber = proposal.Name;

        system.debug('KKK '+ lstProduct);
        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Test.startTest();
        Apttus_CPQApi.CPQWebService.createCart(request);
        
        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];
        objProductConfig.Apttus_Config2__IsPricePending__c = true;

        update objProductConfig;

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

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        
        // Line Item Creation and Modification to test ValidateCart()
        
        List<Apttus_Config2__LineItem__c> lineItemList = [select Id,Open_Offer_Max__c,Apttus_Config2__ProductId__c,name,Price_Override__c,Reason_For_Price_Override__c,Apttus_Config2__PriceType__c,Registrant_Contact__c,Registrant_Contact__r.AccountId,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c, Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;
        for(Integer idx=0; idx<lineItemList.size(); idx++){
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if(idx == 0){
                
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
              
          }
            else if(idx == 1){           
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
              
            }else if(idx == 2){
            
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
            
               // lineitem.Reason_For_Price_Override__c = 'test';
            }
        }
        update lineItemList;

        ApttusCheckPriceController objCheckPriceController = new ApttusCheckPriceController();
        

        Apttus_CpqApi.CPQ.UpdatePriceRequestDO updatePriceRequestDOSO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
        updatePriceRequestDOSO.CartId = objProductConfig.Id;
        Apttus_CpqApi.CPQWebService.updatePriceForCart(updatePriceRequestDOSO);
        objCheckPriceController.callSAP();
        Test.stopTest();

        lineItemList = [select Id,Open_Offer_Max__c,Apttus_Config2__ProductId__r.Open_Offer_Product_Category__c,Apttus_Config2__ProductId__c,name,Price_Override__c,Reason_For_Price_Override__c,Apttus_Config2__PriceType__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;
        for(Integer idx=0; idx<lineItemList.size(); idx++){
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            system.debug('KKK '+lineitem.Apttus_Config2__ProductId__c);
            system.debug('KKK '+lineitem.Apttus_Config2__ProductId__r.Open_Offer_Product_Category__c);
                system.debug('KKK '+ lineitem.Open_Offer_Max__c );
               
            }        
        system.assertEquals(11, lineItemList[0].Open_Offer_Max__c, 'Discount does not match');   
    }
}
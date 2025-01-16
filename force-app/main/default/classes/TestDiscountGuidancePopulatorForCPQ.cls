/* @ author      : Sushil Bolwar
* @ date         : 10-JUN-2024
* @ Description  : TestDiscountGuidancePopulatorForCPQ is the test class for DiscountGuidancePopulatorForCPQ & DiscountGuidanceSelector
*
* Modification Log :
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                 Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Sushil Bolwar          10-JUN-2024           Initial version
* 
*/
@isTest
public class TestDiscountGuidancePopulatorForCPQ {

    public static final String BLOCKED_FOR_SALES = 'Blocked for Sales';
    public static final String DISCOUNT_TYPE_PERCENT = '% Discount';
    public static final String DISCOUNT_TYPE_AMOUNT ='Discount Amount';
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 5;
    public static final Integer INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER = NULL;
    public static final Integer INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER = 10;
    public static final Integer INTEGER_BLANK_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER = NULL;
    public static final Integer INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER = 15;
    public static final Integer INTEGER_BLANK_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER = NULL;
    public static final String STRING_BLANK_COST_CENTER = NULL;
    //DCP-46872
    public static final String STRING_QUOTE_VALIDATE_INTERFACE = 'Quote RT Price Inbound';
    public static final String STRING_QUOTE_GENERATE_INTERFACE = 'Quote Price Validate Inbound';

    //SonarCube 
    public static final String FAPIAO_COND_NOT_SATISFIED = 'Fapiao Condition not Satisfied';
    public static final String TEST_CART_NAME = 'Test Cart 1';
    public static final String LINE_ITEM_OLD_VALUES_JSON = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}';
    public static final String SALES_DISCRETIONARY = 'Sales Discretionary';
    public static final String TEST_LINE_DESCRIPTION = 'test Description';
    public static final String PAGE_APTTUS_CHECK_PRICE = 'Page.ApttusCheckPrice';
    public static final String PROMOTION_JSON = '[{"PromoCode":"NEWBEE","PromoChannel":null},{"PromoCode":"ICT-000021","PromoChannel":null},{"PromoCode":"ICT-000022","PromoChannel":null}]';
    
    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.getNewAccount();
        acc.ERP_Customer_Id__c = '123457';
        acc.Territory_Region__c = 'AMR';
        update acc;
        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.BillingCountryCode = 'US';
        acc2.BillingStateCode = 'AK';
        acc2.ERP_Customer_Id__c = '123456';
        Account acc3 = TestDataAccount.getAccount('Account 3');
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'AK';
        acc3.ERP_Customer_Id__c = '567890';
        acc3.Account_Group__c = 'Distributor';
        Account acc4 = TestDataAccount.getAccount('Account 4');
        acc4.BillingCountryCode = 'US';
        acc4.BillingStateCode = 'AK';
        acc4.ERP_Customer_Id__c = '567891';
        acc4.Account_Group__c = 'Sold To';
        
        Account acc5 = TestDataAccount.getAccount('Account 5');
        acc5.BillingCountryCode = 'US';
        acc5.BillingStateCode = 'AK';
        acc5.ERP_Customer_Id__c = '6000022795';
        acc5.Account_Group__c = 'Sold To';

        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc2);
        lstAcc.add(acc3);
        lstAcc.add(acc4);
        lstAcc.add(acc5);
        insert lstAcc;

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc2.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        acc1SalesArea.Company_Code__c = 'GB01';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','179','00',false);
        acc2SalesArea.Account__c = acc3.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Company_Code__c = 'US01';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea};
        
        Account_Relationship__c objSoldToPayer = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Gryffy',
                                                                            Relationship__c=Label.AccountGroupPayer,
                                                                            Account_Sales_Area__c=acc2SalesArea.Id);
        insert objSoldToPayer;
        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='GCMD',ERP_Customer_Id__c = 'Gryffy',Account_Group__c=Label.AccountRelationshipBillTo),
                                objCMDSoldTo = new Customer_Master_Data__c(Name='HCMD',ERP_Customer_Id__c = 'Hogy',Account_Group__c=Label.AccountRelationshipShipTo),
                                objCMDDist = new Customer_Master_Data__c(Name='SCMD',ERP_Customer_Id__c = 'Slimy',Account_Group__c=Label.AccountGroupDistributor);

        List<Customer_Master_Data__c> lstCMD = new List<Customer_Master_Data__c>();
        lstCMD.add(objCMDUC);
        lstCMD.add(objCMDSoldTo);
        lstCMD.add(objCMDDist);
        insert lstCMD;
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc2.Id);
        con2.FirstName = 'test contact';
        List<Contact> lstContact = new List<Contact>{con,con2};
        insert lstContact;
        
		Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Consortium__c consortium = TestDataConsortium.initConsortium('Open');
        consortium.Species__c = 'Consortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-Species';
        consortium.name = 'ConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortia';
        consortium.Beadchip_Part_Number__c = 'hdaghf';
        insert consortium;

        List<Opportunity> lstopp = new List<Opportunity>();
        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp);

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
        opp2.Price_List__c = priceList.Name;
        opp2.Consortium__c = consortium.Id;
        opp2.Type = 'Consortium';
        opp2.Product_Interest__c = 'Consumables';
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
        lstopp.add(opp2);

        Opportunity opp3 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTIndirectStandard);
        opp3.Name = 'opp3';
        opp3.Ultimate_Consignee__c = acc2.Id;
        opp3.Distributor__c = acc3.Id;
        opp3.Direct_Sale_to_Ultimate_Consignee__c = true;
        opp3.Are_Products_Added_by_Channel_Partner__c = true;
        lstopp.add(opp3);

        Opportunity opp5 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp5);
        insert lstopp;

		subSetUp(priceList, con, acc, acc2, acc5, opp, opp2, opp3, opp5, objCMDUC);
	}
    
    @isTest
    static void testConsortiaCartValidationAndPricings(){
        Apttus_Proposal__Proposal__c proposal = null;
        Apttus_Proposal__Proposal__c proposal1 = null;
        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal2' OR Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        for(Apttus_Proposal__Proposal__c objProposal : lstProposal){
            if(objProposal.Apttus_Proposal__Proposal_Name__c == 'Test Proposal'){
                proposal = objProposal;
            }
            else{
                    proposal1 = objProposal;
                }
        }
        List<Product2> lstProduct = [Select id From Product2 LIMIT 10];
        MockApttusSAPConnector.strQuoteNumber = proposal.name;

        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id, Promo_Name_1__c, Promo_Name_2__c, Promo_Name_3__c, Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c, Apttus_QPConfig__Proposald__r.Quote_Type__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference(PAGE_APTTUS_CHECK_PRICE));
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

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId = [select Id from Apttus_Config2__PriceListItem__c LIMIT 1];
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

        updateLineItems(lineItemList, lstPriceListItemId);
        
        proposal.Promotion_JSON__c = PROMOTION_JSON;
        objProductConfig.Promotion_JSON__c = PROMOTION_JSON;
        update proposal;
        update objProductConfig;
        ApttusCheckPriceController objCheckPriceController = new ApttusCheckPriceController();
        ApttusCheckPriceBaseClass objCheckPriceBaseClass = new ApttusCheckPriceBaseClass();//Added by Arnab - DCP-34013
        Test.startTest();
        Apttus_Config2__ProductConfiguration__c objApttusProductConfig1=TestDataProposal.getNewCart(proposal1);
        //Calling validateCart from ApttusCheckPriceBaseClass
        objCheckPriceBaseClass.validateCart(objApttusProductConfig1, lineItemList,false);
        objCheckPriceBaseClass.validateCart(objProductConfig, lineItemList,false);
        objCheckPriceBaseClass.callSAP(true);
        objCheckPriceController.redirectToCart();
        objCheckPriceController.callSAP();
        objCheckPriceController.repriceCart();
        Cache.Org.getPartition('local.DCPSessionVariables');
        objCheckPriceController.callSAP();
        ApttusCheckPriceController objCheckPriceController1 = new ApttusCheckPriceController();
        objCheckPriceController1.strConfigId = objProductConfig.Id;
        objCheckPriceController1.callSAP();
        objCheckPriceController.redirectToQuote();
        UtilsRest.convertStringToNumber(null);
        Test.stopTest();

        system.assert(objProductConfig.Apttus_Config2__IsPricePending__c,true);
        System.assertEquals(Label.UI_ErrorMessage_Registrant_Contract, ApttusCheckPriceBaseClass.strErrorMsg);
	}
    
    @isTest
    static void testPopulator(){
        Discount_Guidance__c dg = new Discount_Guidance__c();
        dg.Start_Date__c = System.today() + 2;
        dg.End_Date__c = System.today() + 10;
        dg.Discount_Guidance_Level__c = 'Country';
        dg.Country__c = 'HK';
        dg.Channel__c = 'Direct';
        dg.Customer_Discount_Tier__c = '1';
        dg.Tier_Min__c = 1;
        dg.Tier_Max__c = 999999;
        dg.Median_Discount__c = 30;
        dg.Max_Discount__c = 42;
        dg.Discount_Grid_Group__c = 'iSeq Cons';
        dg.Primary_Customer_Type__c = 'Government';
        dg.Tier_Type__c = 'Spend';
        insert dg;
        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal' LIMIT 1];
        proposal.Sold_To_Distribution_Channel__c = Label.DirectDistributionChannelCode;
        update proposal;
        
        Apttus_Config2__ProductConfiguration__c objApttusProductConfig=TestDataProposal.getNewCart(proposal);
        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByDeveloperName().get('CPQ_Discount').getRecordTypeId();
        Custom_Approval_Matrix__c recordCAM = New Custom_Approval_Matrix__c();
        recordCAM.Name = 'AMR';
        recordCAM.Approval_Hierarchy_Type__c = 'Record Owner';
        recordCAM.Discount_Level_1__c = 1;
        recordCAM.Discount_Amount_Level_1__c = 500;
        recordCAM.Active__c = True;
        recordCAM.RecordTypeId = recTypeId;
        recordCAM.Region__c = 'AMR';
        Insert recordCAM;
        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = 'VC0013519-OPA';
        product.ProductCode = 'ADCS';
        product.Discount_Grid_Group__c = 'iSeq Cons';
        insert product;
        //Custom Approval Matrx Product Data
        Custom_Approval_Matrix_Products__c campRecord = new Custom_Approval_Matrix_Products__c(
            Custom_Approval_Matrix__c = recordCAM.id,
            Product__c = product.id
        );
		insert campRecord;
        
        List<Apttus_Config2__LineItem__c> objLineItemList = new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__LineItem__c objLineItem=new Apttus_Config2__LineItem__c();
        objLineItem.Apttus_Config2__ConfigurationId__c=objApttusProductConfig.id;
        objLineItem.Apttus_Config2__ItemSequence__c=2;
        objLineItem.Apttus_Config2__LineNumber__c=10;
        objLineItem.Beadchip_Part_Number__c = 'BeadChip1';
        objLineItem.Project_Id__c = 'Project1';
        objLineItem.Discount_Guidance__c = dg.Id;
        objLineItem.Apttus_Config2__LineType__c = 'Product/Service';
        objLineItem.Apttus_Config2__ProductId__c =product.Id;
        objLineItem.Line_Item_Validate_Old__c = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Apttus_Config2__Quantity__c" : 1,"Price_Override__c" : null}';
        objLineItemList.add(objLineItem);
        insert objLineItemList;
        
        Test.startTest();
        DiscountGuidancePopulatorForCPQ dpCpq = new DiscountGuidancePopulatorForCPQ();
        dpCpq.deriveFieldValuesForDiscountGuidance(objLineItemList);
        Test.stopTest();
        List<Apttus_Config2__LineItem__c> objLineItemListUpdated = [Select Id, Project_Id__c From Apttus_Config2__LineItem__c Where Id =:objLineItemList[0].Id ];
        System.AssertNotEquals(0, objLineItemListUpdated.size());
    }

    static List<Apttus_Config2__LineItem__c> fetchLineItems(Id idProductConfig){
        return [select Id,
                name,
                Promo_Name_1__c,
                Promo_Name_2__c,
                Promo_Name_3__c,
                Sales_Discretionary_Discount__c,
                Sales_Discretionary_Type__c,
                Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
                Apttus_Config2__ProductId__r.Material_Class_Type__c,
                Price_Override__c,
                Reason_For_Price_Override__c,
                Beadchip_Part_Number__c,
                Line_Item_Old_Values__c,
                Program_Type__c,
                Serial_Number__c,
                Apttus_Config2__ProductId__r.ProductCode,
                Distributor_Total_Discount__c,
                Cost_Center__c,
                Distributor_Specific_Discount__c,
                Manual_Rebate__c,
                Manual_Rebate_Per_Unit__c,
                LastModifiedById,
                Apttus_Config2__PriceListItemId__c,
                Apttus_Config2__LineType__c,
                Customer_Premium_Amount_Per_Unit__c,
                Registrant_Contact__c,
                Registrant_Contact__r.AccountId,
                Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c,
                Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__c
                from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :idProductConfig];
    }
    
    static void updateLineItems(List<Apttus_Config2__LineItem__c> lineItemList, List<Apttus_Config2__PriceListItem__c> lstPriceListItemId){
        contact con = [Select id from contact where firstName = 'test contact' limit 1];
        Custom_Approval_Matrix__c recordCAM = New Custom_Approval_Matrix__c();
        recordCAM.Name = 'AMR Owner';
        recordCAM.Approval_Hierarchy_Type__c = 'Record Owner';
        recordCAM.Discount_Level_1__c = 1;
        recordCAM.Discount_Amount_Level_1__c = 500;
                
        Insert recordCAM;

        for (Integer idx = 0; idx < lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if (idx == 0)
            {
                system.debug('Line items --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;
                lineitem.Cost_Center__c = STRING_BLANK_COST_CENTER;
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Line_Description__c = TEST_LINE_DESCRIPTION;
                lineitem.Price_Override__c = 900;
                lineitem.Beadchip_Part_Number__c = 'BeadchipConsortia';
                lineitem.Project_Id__c = 'ProjectIDConsortia';
                lineitem.Max_Samples_Allowed_Per_kit__c = 8;
                lineitem.Price_per_sample__c = 123;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Cost_Center__c = '67';
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Distributor_Total_Discount__c = 50;
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = recordCAM.Id;

            }
            else if (idx == 1)
            {
                system.debug('Line items1 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_BLANK_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Applied_Discount_Amount__c = 30000;
                lineitem.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Sales_Discretionary_Discount__c = 150;
                lineitem.Sales_Discretionary_Type__c = 'Discount Amount';
                lineitem.Volume_Discount__c = 30;
                lineitem.Promotion_Discount__c= 50;
                lineitem.Apttus_Config2__BasePriceOverride__c=200;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Price_Override__c = 900;
                lineitem.Max_Samples_Allowed_Per_kit__c = 8;
                lineitem.Price_per_sample__c = 123;
                lineitem.Registrant_Contact__c = con.id;
                lineitem.Beadchip_Part_Number__c = 'BeadchipConsortia';
                lineitem.Project_Id__c = 'ProjectIDConsortia';
                lineitem.Customer_Premium_Amount_Per_Unit__c = 98;
                lineitem.Distributor_Specific_Price__c = 78;
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Cost_Center__c = '67';
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Distributor_Total_Discount__c = 50;
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = recordCAM.Id;

            }
            else if(idx==2 || idx==3){
                lineItemTwoAndThree(idx, lineitem, lstPriceListItemId, recordCAM);
            }
        }

        update lineItemList;
    }
    
    static void lineItemTwoAndThree(Integer idx, Apttus_Config2__LineItem__c lineitem, List<Apttus_Config2__PriceListItem__c> lstPriceListItemId, Custom_Approval_Matrix__c recordCAM){
        if (idx == 2)
            {
                system.debug('Line items2 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Apttus_Config2__EndDate__c = null;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__LineStatus__c= Label.LineItemLineStatusRenewed;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Price_Override__c = 900;
                lineitem.Max_Samples_Allowed_Per_kit__c = 8;
                lineitem.Price_per_sample__c = 123;
                lineitem.Beadchip_Part_Number__c = 'BeadchipConsortia';
                lineitem.Project_Id__c = 'ProjectIDConsortia';
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Cost_Center__c = '67';
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Distributor_Total_Discount__c = 50;
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = recordCAM.Id;

            }
            else if (idx == 3)
            {
                system.debug('Line items3 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
                lineitem.Sales_Discretionary_Discount__c = 15;
                lineitem.Sales_Discretionary_Type__c = DISCOUNT_TYPE_PERCENT;
                lineitem.Volume_Discount__c = 30;
                lineitem.Promotion_Discount__c= 50;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Applied_Discount_Percentage__c = 15;
                lineitem.Apttus_Config2__BasePriceOverride__c=200;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Price_Override__c = 900;
                lineitem.Max_Samples_Allowed_Per_kit__c = 8;
                lineitem.Price_per_sample__c = 123;
                lineitem.Beadchip_Part_Number__c = 'BeadchipConsortia';
                lineitem.Project_Id__c = 'ProjectIDConsortia';
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Cost_Center__c = '67';
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Distributor_Total_Discount__c = 50;
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = recordCAM.Id;
            }
    }
    
    static void subSetUp(Apttus_Config2__PriceList__c priceList, Contact con, Account acc, Account acc2, Account acc5, 
                         Opportunity opp, Opportunity opp2, Opportunity opp3, Opportunity opp5, Customer_Master_Data__c objCMDUC){
        subSetUp2(con, acc, acc2, acc5, opp, opp2, opp3, opp5, objCMDUC, priceList);                    
        List<Product2> lstProduct = new List<Product2>();
        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProduct.End_Of_Sale_Date__c =Date.today()-1;
        objProduct.End_Of_Service_Date__c =Date.today();
        lstProduct.add(objProduct);

        Product2 objProductTwo = TestDataMaster.createProduct(false);
        objProductTwo.Material_Class__c = Label.ProductMaterialClassServices;
        lstProduct.add(objProductTwo);

        Product2 objProductThree = TestDataMaster.createProduct(false);
        lstProduct.add(objProductThree);

        Product2 objProductFour = TestDataMaster.createProduct(false);
        objProductFour.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProductFour.End_Of_Sale_Date__c =Date.today();
        objProductFour.End_Of_Service_Date__c =Date.today()-1;
        lstProduct.add(objProductFour);

        Product2 objProductFive = TestDataMaster.createProduct(false);
        objProductFive.Material_Class__c = 'Informatics Software';
        objProductFive.End_Of_Sale_Date__c =Date.today()-1;
        objProductFive.End_Of_Service_Date__c =Date.today()-1;
        lstProduct.add(objProductFive);

        Product2 objFixedBundleProduct = TestDataMaster.initProduct('Pizza','Services');
        objFixedBundleProduct.Apttus_Config2__ConfigurationType__c = 'Bundle';
        objFixedBundleProduct.Material_Class_Type__c = Label.FixedBundleMatClassType;
        lstProduct.add(objFixedBundleProduct);

        Product2 objCompProduct = TestDataMaster.initProduct('Toppings','Services');
        lstProduct.add(objCompProduct);
		insert lstProduct;

        List<Apttus_Config2__PriceListItem__c> lstPriceList = new List<Apttus_Config2__PriceListItem__c>();

        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(objProduct, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItem);

        Apttus_Config2__PriceListItem__c priceListItemTwo = TestDataProposal.initPriceListItem(objProductTwo, priceList);
        priceListItemTwo.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        lstPriceList.add(priceListItemTwo);

        Apttus_Config2__PriceListItem__c priceListItemThree = TestDataProposal.initPriceListItem(objProductThree, priceList);
        priceListItemThree.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        lstPriceList.add(priceListItemThree);

        Apttus_Config2__PriceListItem__c priceListItemFour = TestDataProposal.initPriceListItem(objProductFour, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemFour);

        Apttus_Config2__PriceListItem__c priceListItemFive = TestDataProposal.initPriceListItem(objProductFive, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemFive);

        Apttus_Config2__PriceListItem__c priceListItemFixBundleSKU = TestDataProposal.initPriceListItem(objFixedBundleProduct, priceList);
        priceListItemFixBundleSKU.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemFixBundleSKU);

        Apttus_Config2__PriceListItem__c priceListItemFixBundleComp = TestDataProposal.initPriceListItem(objCompProduct, priceList);
        priceListItemFixBundleComp.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        lstPriceList.add(priceListItemFixBundleComp);

      	insert lstPriceList;

        Apttus_Config2__ConfigCustomClasses__c configCustomClass = TestDataProposal.getNewConfigCustomClass();
        configCustomClass.Apttus_Config2__PricingCallbackClass__c = 'ApttusPricingCallback';
        configCustomClass.Apttus_Config2__ValidationCallbackClass__c = 'ApttusValidationCallback';
        configCustomClass.Name = 'System Properties';
        update configCustomClass;

        TestDataProposal.getNewConfigLineItemCustomField();
        TestDataProposal.getNewConfigLineItemCustomField1();
        Apttus_Config2__Incentive__c objIncentive=new Apttus_Config2__Incentive__c();
        objIncentive.Apttus_Config2__IncentiveCode__c='NEWBEE';
        objIncentive.Apttus_Config2__Sequence__c=1;

        insert objIncentive;
	}
    
    static void subSetUp2(Contact con, Account acc, Account acc2, Account acc5, 
                         Opportunity opp, Opportunity opp2, Opportunity opp3, Opportunity opp5, Customer_Master_Data__c objCMDUC, Apttus_Config2__PriceList__c priceList){
        List<Apttus_Proposal__Proposal__c> lstProp = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        proposal.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        proposal.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal.Promotion_JSON__c=PROMOTION_JSON;
        Proposal.Bill_To__c = objCMDUC.id;
        lstProp.add(proposal);

        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test Proposal2', priceList.id, true, 'Draft', 'None');
        proposal2.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal2.Apttus_Proposal__Proposal_Name__c = 'Test Proposal2';
        proposal2.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal2.Promotion_JSON__c=PROMOTION_JSON;
        Proposal2.Bill_To__c = objCMDUC.id;
        lstProp.add(proposal2);

        Apttus_Proposal__Proposal__c proposal3 = TestDataProposal.initProposal(acc2.id, opp3.id, 'Test Proposal3', priceList.id, true, 'Draft', 'None');
        proposal3.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal3.Apttus_Proposal__Proposal_Name__c = 'Test Proposal3';
        proposal3.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal3.Bill_To__c = objCMDUC.id;
        proposal3.Ultimate_Consignee__c = acc.id;
        lstProp.add(proposal3);

        Apttus_Proposal__Proposal__c proposal4 = TestDataProposal.initProposal(acc5.id, opp5.id, 'Test Proposal4', priceList.id, true, 'Draft', 'None');
        proposal4.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal4.Apttus_Proposal__Proposal_Name__c = 'Test Proposal4';
        proposal4.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal4.Bill_To__c = objCMDUC.id;
        lstProp.add(proposal4);

        Apttus_Proposal__Proposal__c proposal5 = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal 3', priceList.id, true, 'Draft', 'None');
        proposal5.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal5.Apttus_Proposal__Primary_Contact__c = con.id;
        Proposal5.Bill_To__c = objCMDUC.id;
        Proposal5.Invalid_Quote__c = true;
        Proposal5.Generate_In_Progress__c = true;
        Proposal5.Async_Generation_Complete__c = false;
         
        lstProp.add(proposal5);

        insert lstProp;
        
        MockApttusSAPConnector.strQuoteNumber = lstProp[0].name; 
        ContentVersion objContentVersion = TestDataProposal.initContentVersion();
        insert objContentVersion;

        ContentVersion objContentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        ContentDocumentLink objContentDocumentLink = TestDataProposal.initContentDocumentLink(lstProp.get(2).Id,objContentVersion2.contentdocumentid);
        insert objContentDocumentLink;

        cs_Apex_Settings__c cs1 = cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
        cs1.Bypass_All_Validations__c = true;
        upsert cs1 cs_Apex_Settings__c.Id;

        Customer_Historical_Spend__c ch = new Customer_Historical_Spend__c();
        ch.Primary_Customer_Type__c = 'Government';
        ch.Customer_Historic_Spend__c = 120000;
        ch.Total_Instrument_Credits__c = 11;
        ch.Valid_From_Date__c = System.today() - 5;
        ch.Frequency__c = 'Last Fiscal Year';
        ch.ERP_ID__c = '123457';
        insert ch;

        cs1.Bypass_All_Validations__c = false;
        upsert cs1 cs_Apex_Settings__c.Id;
    }
}
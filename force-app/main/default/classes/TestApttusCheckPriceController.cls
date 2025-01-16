/* @ author       : Pankaj Sharma
* @ date         :
* @ Description  : TestApttusCheckPriceController is the test class for ApttusCheckPriceController
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                 Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Kushagra Desai          6-FEB-2019           Initial version
* Roopal Verma            3-Jun-2019           DCP-25322, Manual rebate change
* Saswati                 6-JUN-2019           DCP-25191
* Kushagra Desai          12-June-2019         DCP-25908 : Update payment term
* Kushagra Desai          24-June-2019         DCP-26680 : Code optimization updated defination of Validate cart
* Kushagra Desai          7-July-2018          Added Assert : testCheckPriceDirectUC()
* Satya Swain             25-Sep-2019          DCP-30062 : SonarQube Fixes
* Saswati                 29-Sep-2019          DCP-28565 : Test Coverage for Fapiao Functionality
* Kushagra Desai          7-July-2018          Added Assert : testCheckPriceDirectUC()
* Arnab Modak             10-Sep-2019          DCP-28284 : Test Coverage for changes in request and response classes
//SonarQube Fixes 10-12-2019
* Joshith K               03-Dec-2019                                      INC0238317- changed Validate cart method signature to pass Line items as separate variable
* Rahul Bishnoi           13-Jan-2020                                       DCP-32794 Removed Software Id
* Rahul Bishnoi           03-Mar-2020          INC0255210 - Do not allow discount more than 100%.
* Arnab Modak             23-Mar-2020          DCP-34013 - Called validateCart() using instance of ApttusCheckPriceBaseClass.
* Arnab Modak             01-Apr-2020          SonarCube fixes
* Rishab Wali             01-June-2020         Validate Cart Update DCP-34910 
* Prabhsimran Singh       11-June-2020         Generate Update DCP-37888
* Rishab Wali             12-Dec-2020          Add logic for ZCNP instead of ZPNP
* Rishab Wali             08-Dec-2020          DCP-31081 Add logic for beadchip soft warning
* Roopal Verma            03-Mar-2021          DCP-42729: Added value for Distributor_Total_Discount__c
* Adyasha Satapathy       18-May-2021          DCP-46872: Test method for sending Product Interest and WO Name to SAP
* KD                      24-May-2021          DCP-46276 : new method testRelocationValidationAndPricings
* Ashwin Kumar            25-May-2021          INC0321438 - ApttusLineItemsSelector.selectLineItemsByConfigId param updated from Id to Set<Id>
* KD                      8-June-2021          DCP-45926 : Mandatory field 
* Akshay Mohan            25-June-2021         DCP-46277: Add coverage for bypass
* Nishan Shetty           17-Jan-2022          CodeScanFix- [Assert Argument Order]
* Prem Ranjan             04 May 2022          CodeScan Fix (APEX) Unused Local Variable
* Jitesh Lakhwani         21-Sept-2022         @100% Class : 'RealtimePricingResponse' Test Coverage 
* Parthasarathy D         10-Oct-2022          Codescan fix - Added method level comments.
* Satya Swain             09 Dec 2022          Added Codescan fix for Variable Naming Convention
* Vinay S Reddy           27 Oct 2023          CMCM1482 Update
*/

@isTest
public class TestApttusCheckPriceController {
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

    
       /**
     *  @author Kushagra Desai
     *  @description Test Data Setup
     **/
     @testSetup
     static void setupData()
     {
        //Test.setMock(HttpCalloutMock.class, new MockApttusSAPConnector());

        Account acc = TestDataAccount.getNewAccount();
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
        //Fapiao
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
        // DCP-25908 : Payment term
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
        System.debug('contss-'+con);

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Consortium__c consortium = TestDataConsortium.initConsortium('Open');
        consortium.Species__c = 'Consortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-SpeciesConsortia-Species';
        consortium.name = 'ConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortiaConsortia';
        consortium.Beadchip_Part_Number__c = 'hdaghf';
        insert consortium;

        List<Opportunity> lstopp = new List<Opportunity>();
        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        System.debug('+++++++ Opp Type: '+opp.Type);
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
        System.debug('+++++++ Opp Type: '+opp.Type);
        opp.Price_List__c = priceList.Name;
        lstopp.add(opp5);
        insert lstopp;

        List<Apttus_Proposal__Proposal__c> lstProp = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        proposal.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        proposal.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal.Promotion_JSON__c=PROMOTION_JSON;
        //Proposal.Apttus_QPConfig__BillToAccountId__c = objCMDUC.id;
        Proposal.Bill_To__c = objCMDUC.id;
        System.debug('***1231**'+proposal.Direct_Sale_to_Ultimate_Consignee__c);
        lstProp.add(proposal);

        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test Proposal2', priceList.id, true, 'Draft', 'None');
        proposal2.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal2.Apttus_Proposal__Proposal_Name__c = 'Test Proposal2';
        proposal2.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal2.Promotion_JSON__c=PROMOTION_JSON;
        Proposal2.Bill_To__c = objCMDUC.id;
        System.debug('***1232**'+proposal2.Direct_Sale_to_Ultimate_Consignee__c);
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

        //Creating Fixed Bundle SKU - DCP-28284
        Product2 objFixedBundleProduct = TestDataMaster.initProduct('Pizza','Services');
        objFixedBundleProduct.Apttus_Config2__ConfigurationType__c = 'Bundle';
        objFixedBundleProduct.Material_Class_Type__c = Label.FixedBundleMatClassType;
        lstProduct.add(objFixedBundleProduct);

        //FixedBundle Component Product - DCP-28284
        Product2 objCompProduct = TestDataMaster.initProduct('Toppings','Services');
        lstProduct.add(objCompProduct);

       /* Product2 objProductSix = TestDataMaster.createProduct(false);
        objProductSix.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProductSix.End_Of_Sale_Date__c =Date.today()-1;
        objProductSix.End_Of_Service_Date__c =Date.today()+1;
        lstProduct.add(objProductSix);

        Product2 objProductSeven = TestDataMaster.createProduct(false);
        objProductSeven.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProductSeven.End_Of_Sale_Date__c =Date.today()+1;
        objProductSeven.End_Of_Service_Date__c =Date.today()-1;
        lstProduct.add(objProductSeven);

        Product2 objProductEight = TestDataMaster.createProduct(false);
        objProductEight.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProductEight.End_Of_Sale_Date__c =Date.today()-1;
        objProductEight.End_Of_Service_Date__c =Date.today()-1;
        lstProduct.add(objProductEight); */


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

        //Adding PLI for Fixed Bundle SKU - DCP-28284
        Apttus_Config2__PriceListItem__c priceListItemFixBundleSKU = TestDataProposal.initPriceListItem(objFixedBundleProduct, priceList);
        priceListItemFixBundleSKU.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemFixBundleSKU);

        //Adding PLI for Fixed Bundle Component - DCP-28284
        Apttus_Config2__PriceListItem__c priceListItemFixBundleComp = TestDataProposal.initPriceListItem(objCompProduct, priceList);
        priceListItemFixBundleComp.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
        lstPriceList.add(priceListItemFixBundleComp);

      /*  Apttus_Config2__PriceListItem__c priceListItemSix = TestDataProposal.initPriceListItem(objProductSix, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemSix);

        Apttus_Config2__PriceListItem__c priceListItemSeven = TestDataProposal.initPriceListItem(objProductSeven, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemSeven);

        Apttus_Config2__PriceListItem__c priceListItemEight = TestDataProposal.initPriceListItem(objProductEight, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItemEight); */

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

        ContentVersion objContentVersion = TestDataProposal.initContentVersion();
        insert objContentVersion;

        ContentVersion objContentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objContentVersion.Id LIMIT 1];
        ContentDocumentLink objContentDocumentLink = TestDataProposal.initContentDocumentLink(lstProp.get(2).Id,objContentVersion2.contentdocumentid);
        insert objContentDocumentLink;
    }

    @isTest
    static void testConsortiaCartValidationAndPricings()
    {
        System.debug('TTN queries so far ' + Limits.getQueries());
        //Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal2' LIMIT 1];
        //Apttus_Proposal__Proposal__c proposal1 = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal' LIMIT 1];
        //SB,Apttus_Proposal__Opportunity__c,Apttus_Proposal__Opportunity__r.AccountId
        Apttus_Proposal__Proposal__c proposal,proposal1;
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
        contact con = [Select id from contact where firstName = 'test contact' limit 1];
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
        // Line Item Creation and Modification to test ValidateCart(), modified for DCP34013
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

        //Added by SB - DGP-385
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
            else if (idx == 2)
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

        update lineItemList;

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
		system.debug('Consortia Cart Validation And Pricings'+objProductConfig.Apttus_Config2__IsPricePending__c);
    }

    @isTest
    static void testException()
    {
        System.debug('TTN queries so far ' + Limits.getQueries());
        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal2' LIMIT 1];
        Apttus_Proposal__Proposal__c proposal1 = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal' LIMIT 1];
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
        // Line Item Creation and Modification to test ValidateCart(), modified for DCP34013
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

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
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = null;

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
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = null;

            }
            else if (idx == 2)
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
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = null;

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
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = null;
            }
        }

        update lineItemList;

        proposal.Promotion_JSON__c = PROMOTION_JSON;
        objProductConfig.Promotion_JSON__c = PROMOTION_JSON;
        update proposal;
        update objProductConfig;
        ApttusCheckPriceBaseClass objCheckPriceBaseClass = new ApttusCheckPriceBaseClass();//Added by Arnab - DCP-34013
        Test.startTest();
        Apttus_Config2__ProductConfiguration__c objApttusProductConfig1=TestDataProposal.getNewCart(proposal1);
        //Calling validateCart from ApttusCheckPriceBaseClass
        objCheckPriceBaseClass.validateCart(objApttusProductConfig1, lineItemList,false);
        objCheckPriceBaseClass.validateCart(objProductConfig, lineItemList,false);
        objCheckPriceBaseClass.callSAP(true);
        ApttusCheckPriceBaseClass.strConfigId = 'abcd1234asdasd';
        objCheckPriceBaseClass.callSAP(false);
        Test.stopTest();

        system.assert(objProductConfig.Apttus_Config2__IsPricePending__c,true);
    }

    @isTest
    static void testApttusGenerateQuoteController()
    {
        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c,Generate_In_Progress__c,Async_Generation_Complete__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal2' LIMIT 1];
        proposal.Total_Net__c = 1;
        proposal.Sub_Total__c = 1;
        // DCP-25908 : Payment term
        proposal.Apttus_Proposal__Payment_Term__c = '';
        update proposal;
        List<product2> product=[Select id ,name from product2 LIMIT 5];
        product[0].End_Of_Sale_Date__c = Date.today()-1;
        product[0].End_Of_Service_Date__c = Date.today();
        product[3].End_Of_Sale_Date__c = Date.today();
        product[3].End_Of_Service_Date__c = Date.today()-1;
        product[4].End_Of_Sale_Date__c = Date.today()-1;
        product[4].End_Of_Service_Date__c = Date.today()-1;
        update product;

        Apttus_Config2__ProductConfiguration__c objApttusProductConfig=TestDataProposal.getNewCart(proposal);

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c LIMIT 1];
        lstPriceListItemId[0].Apttus_Config2__PriceType__c = 'One Time';

        Test.startTest();

        List<Apttus_Proposal__Proposal_Line_Item__c> listProposalLineItem = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 = TestDataProposal.initProposalLineItem(proposal, product[0]);
        proposalLineItem1.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem1.Hide_Contract_Dates__c = true;
        proposalLineItem1.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem1.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem1.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem1.Project_Id__c = 'Project1';
        proposalLineItem1.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem1.Price_per_sample__c = 32;
        proposalLineItem1.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem1);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem2 = TestDataProposal.initProposalLineItem(proposal, product[3]);
        proposalLineItem2.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem2.Hide_Contract_Dates__c = true;
        proposalLineItem2.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem2.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem2.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem2.Project_Id__c = 'Project1';
        proposalLineItem2.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem2.Price_per_sample__c = 32;
        proposalLineItem2.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem2);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem3 = TestDataProposal.initProposalLineItem(proposal, product[4]);
        proposalLineItem3.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem3.Hide_Contract_Dates__c = true;
        proposalLineItem3.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem3.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem3.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem3.Project_Id__c = 'Project1';
        proposalLineItem3.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem3.Price_per_sample__c = 32;
        proposalLineItem3.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem3);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem4 = TestDataProposal.initProposalLineItem(proposal, product[0]);
        proposalLineItem4.Apttus_QPConfig__OptionId__c = product[0].Id;
        proposalLineItem4.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem4.Hide_Contract_Dates__c = true;
        proposalLineItem4.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem4.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem4.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem4.Project_Id__c = 'Project1';
        proposalLineItem4.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem4.Price_per_sample__c = 32;
        proposalLineItem4.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem4);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem5 = TestDataProposal.initProposalLineItem(proposal, product[3]);
        proposalLineItem5.Apttus_QPConfig__OptionId__c = product[3].Id;
        proposalLineItem5.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem5.Hide_Contract_Dates__c = true;
        proposalLineItem5.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem5.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem5.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem5.Project_Id__c = 'Project1';
        proposalLineItem5.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem5.Price_per_sample__c = 32;
        proposalLineItem5.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem5);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem6 = TestDataProposal.initProposalLineItem(proposal, product[4]);
        proposalLineItem6.Apttus_QPConfig__OptionId__c = product[4].Id;
        proposalLineItem6.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem6.Hide_Contract_Dates__c = true;
        proposalLineItem6.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem6.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem6.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem6.Project_Id__c = 'Project1';
        proposalLineItem6.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem6.Price_per_sample__c = 32;
        proposalLineItem6.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem6);
        insert listProposalLineItem;

        System.currentPageReference().getParameters().put('Id',proposal.Id );
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0001',listProposalLineItem[0]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0002',listProposalLineItem[1]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0003',listProposalLineItem[2]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0004',listProposalLineItem[3]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0005',listProposalLineItem[4]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0006',listProposalLineItem[5]);
        ApttusGenerateQuoteController objApptusGenQuote=new ApttusGenerateQuoteController();
        ApttusGenerateQuoteController.strQuoteID=proposal.id;
        ApttusGenerateQuoteController.reCheckPricing();

        objApptusGenQuote.redirectToGenerate();
        objApptusGenQuote.redirectToQuote();
        // to cover the else part if input sting is null
        String s;
        UtilsRest.convertStringToNumber(s);
        s='1';
        UtilsRest.convertStringToNumber(s);
        System.currentPageReference().getParameters().put('Id',objApttusProductConfig.Id);
        ApttusGenerateQuoteController objApptusGenQuote1 = new ApttusGenerateQuoteController();
        ApttusGenerateQuoteController.reCheckPricing();
        ApttusSAPConnector.bolTestRetryFlag = true;
        ApttusGenerateQuoteController.reCheckPricing();
        try{
            RealtimePricingRequest.createJSONForGenerateQuote(proposal.id,false); 
        }
        Catch(Exception e){System.debug('Exception -- ' + e.getMessage());}
        Test.stopTest();

        System.assertEquals(true, ApttusGenerateQuoteController.boolHasError);
    }

    @isTest
    static void testApttusGenerateQuoteControllerErrorResponse()
    {
        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c,Generate_In_Progress__c,Async_Generation_Complete__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal2' LIMIT 1];
        proposal.Total_Net__c = 1;
        proposal.Sub_Total__c = 1;
        // DCP-25908 : Payment term
        proposal.Apttus_Proposal__Payment_Term__c = '';
        update proposal;
        List<product2> product=[Select id ,name from product2 LIMIT 5];
        product[0].End_Of_Sale_Date__c = Date.today()-1;
        product[0].End_Of_Service_Date__c = Date.today();
        product[3].End_Of_Sale_Date__c = Date.today();
        product[3].End_Of_Service_Date__c = Date.today()-1;
        product[4].End_Of_Sale_Date__c = Date.today()-1;
        product[4].End_Of_Service_Date__c = Date.today()-1;
        update product;

        Apttus_Config2__ProductConfiguration__c objApttusProductConfig=TestDataProposal.getNewCart(proposal);

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c LIMIT 1];
        lstPriceListItemId[0].Apttus_Config2__PriceType__c = 'One Time';

        Test.startTest();

        List<Apttus_Proposal__Proposal_Line_Item__c> listProposalLineItem = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 = TestDataProposal.initProposalLineItem(proposal, product[0]);
        proposalLineItem1.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem1.Hide_Contract_Dates__c = true;
        proposalLineItem1.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem1.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem1.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem1.Project_Id__c = 'Project1';
        proposalLineItem1.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem1.Price_per_sample__c = 32;
        proposalLineItem1.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem1);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem2 = TestDataProposal.initProposalLineItem(proposal, product[3]);
        proposalLineItem2.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem2.Hide_Contract_Dates__c = true;
        proposalLineItem2.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem2.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem2.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem2.Project_Id__c = 'Project1';
        proposalLineItem2.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem2.Price_per_sample__c = 32;
        proposalLineItem2.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem2);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem3 = TestDataProposal.initProposalLineItem(proposal, product[4]);
        proposalLineItem3.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem3.Hide_Contract_Dates__c = true;
        proposalLineItem3.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem3.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem3.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem3.Project_Id__c = 'Project1';
        proposalLineItem3.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem3.Price_per_sample__c = 32;
        proposalLineItem3.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem3);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem4 = TestDataProposal.initProposalLineItem(proposal, product[0]);
        proposalLineItem4.Apttus_QPConfig__OptionId__c = product[0].Id;
        proposalLineItem4.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem4.Hide_Contract_Dates__c = true;
        proposalLineItem4.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem4.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem4.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem4.Project_Id__c = 'Project1';
        proposalLineItem4.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem4.Price_per_sample__c = 32;
        proposalLineItem4.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem4);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem5 = TestDataProposal.initProposalLineItem(proposal, product[3]);
        proposalLineItem5.Apttus_QPConfig__OptionId__c = product[3].Id;
        proposalLineItem5.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem5.Hide_Contract_Dates__c = true;
        proposalLineItem5.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem5.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem5.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem5.Project_Id__c = 'Project1';
        proposalLineItem5.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem5.Price_per_sample__c = 32;
        proposalLineItem5.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem5);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem6 = TestDataProposal.initProposalLineItem(proposal, product[4]);
        proposalLineItem6.Apttus_QPConfig__OptionId__c = product[4].Id;
        proposalLineItem6.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem6.Hide_Contract_Dates__c = true;
        proposalLineItem6.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem6.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem6.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem6.Project_Id__c = 'Project1';
        proposalLineItem6.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem6.Price_per_sample__c = 32;
        proposalLineItem6.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem6);
        insert listProposalLineItem;

        System.currentPageReference().getParameters().put('Id',proposal.Id );
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0001',listProposalLineItem[0]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0002',listProposalLineItem[1]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0003',listProposalLineItem[2]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0004',listProposalLineItem[3]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0005',listProposalLineItem[4]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0006',listProposalLineItem[5]);
        ApttusGenerateQuoteController objApptusGenQuote=new ApttusGenerateQuoteController();
        ApttusGenerateQuoteController.strQuoteID=proposal.id;
        ApttusSAPConnector.bolTestRetryFlag = true;
        ApttusGenerateQuoteController.reCheckPricing();

        objApptusGenQuote.redirectToGenerate();
        objApptusGenQuote.redirectToQuote();
        proposal.Generate_In_Progress__c = false;
        proposal.Async_Generation_Complete__c = true;
        update proposal;
        //DCP-37888 For large cart generate.
        PostToChatterAfterGenerate.postToChatter(new List<Id>{proposal.Id});
        Test.stopTest();
        
        System.assertEquals(true, ApttusSAPConnector.bolTestRetryFlag);
    }

    /*
    *@author: Satya Swain
    *@Desc: Test method to cover validateCart method
    */

    @isTest
    static void testCartValidations(){
        Opportunity objOpportunity = [Select Id, Name, Direct_Sale_to_Ultimate_Consignee__c  from Opportunity where Name='opp3'];
        objOpportunity.Direct_Sale_to_Ultimate_Consignee__c = true;
        update objOpportunity;

        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal3' LIMIT 1];

        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Product_Group_Code__c ='SQ0BS00B110BS3';
        insert objProduct;

        MockApttusSAPConnector.strQuoteNumber = proposal.name;

        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.initCart(proposal);
        testCart.Name =TEST_CART_NAME;
        insert testCart;

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id,Apttus_Config2__IsPricePending__c,Is_SAP_Pricing_Completed__c,GT_Check_Pending_Count__c,Number_of_Line_Items_During_Check_Price__c,Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c, Apttus_QPConfig__Proposald__r.Quote_Type__c from Apttus_Config2__ProductConfiguration__c where Name =: TEST_CART_NAME LIMIT 1];
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        objProductConfig.Is_SAP_Pricing_Completed__c = true;
        update objProductConfig;

        System.debug('@@@@ Is_SAP_Pricing_Completed__c after 1st Update: '+ objProductConfig.Is_SAP_Pricing_Completed__c);
        System.debug('@@@@ GT_Check_Pending_Count__c after 1st update '+ objProductConfig.GT_Check_Pending_Count__c );

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = objProduct.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct2 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct2.ProductId = objProduct.Id;
        selectProduct2.Quantity = 1;
        selectProduct2.SellingTerm = 12;
        selectProduct2.StartDate = Date.today();
        selectProduct2.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct2);
        Test.startTest();
        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

        for (Integer idx = 0; idx < lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if (idx == 0)
            {
                system.debug('Line items IDX 0 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = 1;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = 1;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = 1;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=null;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Applied_Discount_Percentage__c = 80;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;
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
                lineitem.Price_per_sample__c = null;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Cost_Center__c = '67';
                lineitem.Global_Trade_Block__c = true;
                lineitem.Apttus_Config2__Quantity__c = 1;
                lineitem.Sales_Discretionary_Discount__c = 10;
                lineitem.Sales_Discretionary_Type__c = DISCOUNT_TYPE_PERCENT;
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = null;
            }
            else if(idx == 1){
                system.debug('Line items IDX 1--'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = 1;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = 1;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = 1;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c = null;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Applied_Discount_Percentage__c = 80;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Line_Description__c = 'test Description 2';
               // lineitem.Price_Override__c = 900;
               lineitem.Beadchip_Part_Number__c = 'BeadchipConsortia';
               lineitem.Project_Id__c = 'ProjectIDConsortia';
               lineitem.Max_Samples_Allowed_Per_kit__c = 8;
               lineitem.Price_per_sample__c = null;
               lineitem.Reason_For_Price_Override__c = 'test';
               lineitem.Apttus_Config2__StartDate__c = Date.today();
               lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
               lineitem.Reason_For_Price_Override__c = 'test';
               lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
               lineitem.Applied_Discount_Percentage__c = 100;
               lineitem.Cost_Center__c = '67';
               lineitem.Global_Trade_Block__c = true;
               lineitem.Apttus_Config2__Quantity__c = 3;
               lineitem.Line_Item_Old_Values__c = NULL;
               //lineitem.Software_Id__c = NULL;
               lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
                lineitem.Approval_Matrix_Record_Owner__c = null;

           }

       }
        
       update lineItemList;

       proposal.Promotion_JSON__c = PROMOTION_JSON;
       objProductConfig.Promotion_JSON__c = PROMOTION_JSON;
       objProductConfig.Is_SAP_Pricing_Completed__c = true;
       objProductConfig.Apttus_Config2__IsPricePending__c = true;
       objProductConfig.Number_of_Line_Items_During_Check_Price__c = 3;
       update proposal;
       update objProductConfig;

       System.debug('@@@ line items:'+ lineItemList);

       ApttusCheckPriceController objCheckPriceController = new ApttusCheckPriceController();
       ApttusCheckPriceBaseClass objCheckPriceBaseClass = new ApttusCheckPriceBaseClass();//Added by Arnab - DCP-34013

       Test.setCurrentPageReference(new PageReference(PAGE_APTTUS_CHECK_PRICE));
       System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
       System.currentPageReference().getParameters().put('flow', 'NGDefault');
       System.currentPageReference().getParameters().put('Id',objProductConfig.Id);

       //Test.startTest();

        // test: change in Quantity
        lineItemList.get(0).Apttus_Config2__Quantity__c = 5;
        lineItemList.get(0).Line_Item_Old_Values__c = '{"Sales_Discretionary_Type__c" : null,"Sales_Discretionary_Discount__c" : null,"Quantity" : 1,"PriceOverride" : null,"LineNumber" : 1}';
        lineItemList.get(0).Program_Type__c = 'Demo Program';
        update lineItemList;

        Apttus_Config2__ProductConfiguration__c objProductConfig2 = new ApttusProductConfigurationsSelector().selectConfigWithLines(new Set<Id>{objProductConfig.Id})[0];


        System.debug('@@@ Direct Sale to Ultimate Consignee: '+objProductConfig2.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c);
        objCheckPriceBaseClass.validateCart(objProductConfig2, lineItemList,false);//DCP-34013
        System.assertEquals(false,objCheckPriceController.boolDemoPromoAdded);//DCP-34013 //CodeScanFix [Assert Argument Order]
        //System.assertEquals(objCheckPriceController.boolHasError,true);

        System.debug('@@@@ Is_SAP_Pricing_Completed__c post calling validate Cart ' + objProductConfig2.Is_SAP_Pricing_Completed__c);

        //DCP-25322, Added condition for manual rebate
        lineItemList.get(0).Manual_Rebate__c = 50;
        lineItemList.get(0).Line_Item_Validate_Old__c = '{"Manual_Rebate__c" : 50,"LineNumber" : 1}';
        lineItemList.get(0).Line_Item_Old_Values__c = null;

        update lineItemList;

        Apttus_Config2__ProductConfiguration__c objProductConfig3 = new ApttusProductConfigurationsSelector().selectConfigWithLines(new Set<Id>{objProductConfig.Id})[0];
        objCheckPriceBaseClass.validateCart(objProductConfig3, lineItemList,false);//DCP-34013

        // test: deletion of lineitem
        delete lineItemList.get(1);
        lineItemList.remove(1);


        Apttus_Config2__ProductConfiguration__c objProductConfig4 = new ApttusProductConfigurationsSelector().selectConfigWithLines(new Set<Id>{objProductConfig.Id})[0];
        objCheckPriceBaseClass.validateCart(objProductConfig4, lineItemList,false);//DCP-34013
        objCheckPriceController.redirectToCart();

        System.debug('############'+lineItemList);

        objProduct.Apttus_Config2__ConfigurationType__c=Label.ProductConfigTypeBundle;
        objProduct.Material_Class_Type__c=Label.FixedBundleMatClassType;
        update objProduct;

        lineItemList.get(0).Apttus_Config2__LineType__c='Product/Service';
        lineItemList.get(0).Customer_Premium_Amount_Per_Unit__c=100;
        lineItemList.get(0).Price_Override__c=10;
        lineItemList.get(0).Apttus_Config2__ProductId__c=objProduct.id;
        update lineItemList;

        lineItemList = new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id> {objProductConfig.id});    //INC0321438
        objCheckPriceBaseClass.validateCart(objProductConfig4,lineItemList,false);//DCP-34013
        Test.setCurrentPageReference(new PageReference(PAGE_APTTUS_CHECK_PRICE));
        System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
        System.currentPageReference().getParameters().put('flow', 'DirectSaleToUCConsortia');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id);
        ApttusCheckPriceDirectUCController objCheckPriceController2 = new ApttusCheckPriceDirectUCController();
        objCheckPriceController2.strConfigId=objProductConfig.id;
        objCheckPriceController2.callSAP();
        objCheckPriceBaseClass.validateCart(objProductConfig, lineItemList,true);//DCP-34013

        lineItemList.get(0).Sales_Discretionary_Discount__c = 115;
        lineItemList.get(0).Sales_Discretionary_Type__c = DISCOUNT_TYPE_PERCENT;
        lineItemList.get(0).Customer_Premium_Type__c='% Premium';
                lineItemList.get(0).Customer_Premium_Per_Unit__c= -90;
                lineItemList.get(0).List_Price__c=18000;
        update lineItemList;

        lineItemList = new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id> {objProductConfig.id});    //INC0321438
        //DCP-34013
        objCheckPriceBaseClass.validateCart(objProductConfig,lineItemList,true);
        objCheckPriceBaseClass.validateCart(objProductConfig4,lineItemList,false);
        //Test.stopTest();

        Apttus_Config2__ProductConfiguration__c cart = [Select Id,Name,GT_Check_Pending_Count__c,Is_SAP_Pricing_Completed__c, Apttus_QPConfig__Proposald__r.Quote_Type__c From Apttus_Config2__ProductConfiguration__c where Name =: TEST_CART_NAME];
        
                lineItemList.get(0).Customer_Premium_Type__c='% Premium';
                lineItemList.get(0).Customer_Premium_Per_Unit__c= 190;
                lineItemList.get(0).List_Price__c=18000;
        update lineItemList;

        lineItemList = new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id> {objProductConfig.id});    //INC0321438
        //DCP-34013
        objCheckPriceBaseClass.validateCart(objProductConfig,lineItemList,true);
        objCheckPriceBaseClass.validateCart(objProductConfig4,lineItemList,false);

        
        Test.stopTest();
        System.debug('@@@@ GT_Check_Pending_Count__c after stopTest'+cart.GT_Check_Pending_Count__c );
        System.debug('@@@@ Is_SAP_Pricing_Completed__c after stopTest'+ cart.Is_SAP_Pricing_Completed__c);
        system.assert(objProductConfig.Apttus_Config2__IsPricePending__c,true);
        system.assertEquals(0,Integer.valueOf(cart.GT_Check_Pending_Count__c));//CodeScanFix [Assert Argument Order]
        system.assert(cart.Is_SAP_Pricing_Completed__c,true);


    }
    /*
    *  @author      : 
    *  @description : Method to test Price End dates.
    *  @param       : 
    *  @return      : Void.
    */
    @isTest
    public static void testApttusCheckPriceEndDates()
    {
        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal2' LIMIT 1];
       // Apttus_Proposal__Proposal__c proposal1 = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal' LIMIT 1];
       List<Product2> lstProduct = [Select id From Product2 LIMIT 3];

        //lstProduct.get(0).End_Of_Sale_Date__c =Date.today()-1;
        //lstProduct.get(0).End_Of_Service_Date__c =Date.today();
        //lstProduct.get(1).End_Of_Sale_Date__c =Date.today();
        //lstProduct.get(1).End_Of_Service_Date__c =Date.today()-1;
        //lstProduct.get(2).End_Of_Sale_Date__c =Date.today()-1;
        //lstProduct.get(2).End_Of_Service_Date__c =Date.today()-1;

        //update lstProduct;

        MockApttusSAPConnector.strQuoteNumber = proposal.name;

        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id, Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c, Apttus_QPConfig__Proposald__r.Quote_Type__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];
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
        // Line Item Creation and Modification to test ValidateCart(), modified for DCP-34013
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

        //Added by SB - DGP-385
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
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Cost_Center__c = '67-80';  
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
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
				lineitem.Approval_Matrix_Record_Owner__c = recordCAM.Id;

            }
            else if (idx == 2)
            {
                system.debug('Line items2 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
                lineitem.Apttus_Config2__StartDate__c = null;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
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
               // lineitem.Sales_Discretionary_Discount__c = 15;
               // lineitem.Sales_Discretionary_Type__c = DISCOUNT_TYPE_PERCENT;
               lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
				lineitem.Approval_Matrix_Record_Owner__c = recordCAM.Id;

           }

       }
       update lineItemList;

       proposal.Promotion_JSON__c = PROMOTION_JSON;
       objProductConfig.Promotion_JSON__c = PROMOTION_JSON;
       objProductConfig.Promo_Name_1__c = 'TEST_DEMO';
       update proposal;
       update objProductConfig;

       ApttusCheckPriceBaseClass objCheckPriceBaseClass = new ApttusCheckPriceBaseClass();//Added by Arnab - DCP-34013

       Test.startTest();

       objCheckPriceBaseClass.validateCart(objProductConfig, lineItemList,false);
       System.assertEquals(Label.UI_ErrorMessage_CostCenterNonNumeric, ApttusCheckPriceBaseClass.strErrorMsg);//TASK0555443 - give error if cost center in cart contains non-numeric values
       objCheckPriceBaseClass.boolValidationStatus = false;
       objCheckPriceBaseClass.validateCart(objProductConfig, lineItemList,false);

       Test.stopTest();

       System.assertEquals(true,objCheckPriceBaseClass.boolHasError);//CodeScanFix [Assert Argument Order]


   }
   @isTest
   static void testMockSAP(){
    test.startTest();
    HttpResponse res;
    HttpRequest req = new HttpRequest();
    res = new MockApttusSAPConnector().respond(req);
    res = new MockApttusSAPConnector().respondDirectUC(req);
    res = new MockApttusSAPConnector().respondAuthError(req);
    system.assertEquals(403,res.getStatusCode());//CodeScanFix [Assert Argument Order]

}
    /*
    *@author: Saswati. DCP -25191
    *@Desc: Test method to cover validateCart method
    */

    @isTest
    static void testCheckPriceDirectUC(){
        Opportunity objOpportunity = [Select Id, Name, Direct_Sale_to_Ultimate_Consignee__c  from Opportunity where Name='opp3'];
        objOpportunity.Direct_Sale_to_Ultimate_Consignee__c = true;
        update objOpportunity;

        Apttus_Proposal__Proposal__c proposal = [Select id,Sub_Total__c,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal3' LIMIT 1];

        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Product_Group_Code__c ='SQ0BS00B110BS3';
        insert objProduct;
        Test.startTest();
        MockApttusSAPConnector.strQuoteNumber = proposal.name;

        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.initCart(proposal);
        testCart.Name =TEST_CART_NAME;
        insert testCart;

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id,Apttus_Config2__IsPricePending__c,Is_SAP_Pricing_Completed__c,GT_Check_Pending_Count__c,Number_of_Line_Items_During_Check_Price__c,Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c,Apttus_QPConfig__Proposald__r.Quote_Type__c from Apttus_Config2__ProductConfiguration__c where Name =: TEST_CART_NAME LIMIT 1];
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        objProductConfig.Is_SAP_Pricing_Completed__c = true;
        update objProductConfig;

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = objProduct.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);

        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct2 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct2.ProductId = objProduct.Id;
        selectProduct2.Quantity = 1;
        selectProduct2.SellingTerm = 12;
        selectProduct2.StartDate = Date.today();
        selectProduct2.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct2);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        // Line Item Creation and Modification to test ValidateCart(), Modified for DCP-34013
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;
        lineItemList = new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id> {objProductConfig.id});    //INC0321438
        for (Integer idx = 0; idx < lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if (idx == 0)
            {
                system.debug('Line items IDX 0 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = 1;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = 1;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = 1;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=null;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Applied_Discount_Percentage__c = 80;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Line_Description__c = TEST_LINE_DESCRIPTION;
                lineitem.Price_Override__c = 900;
                lineitem.Beadchip_Part_Number__c = null;
                lineitem.Project_Id__c = 'ProjectIDConsortia';
                lineitem.Max_Samples_Allowed_Per_kit__c = 8;
                lineitem.Price_per_sample__c = null;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Cost_Center__c = '67';
                lineitem.Global_Trade_Block__c = true;
                lineitem.Apttus_Config2__Quantity__c = 1;
                lineitem.Sales_Discretionary_Discount__c = 10;
                lineitem.Sales_Discretionary_Type__c = DISCOUNT_TYPE_PERCENT;
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
            }
            else if(idx == 1){
                system.debug('Line items IDX 1--'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = 1;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = 1;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = 1;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c = null;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Applied_Discount_Percentage__c = 80;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Line_Description__c = 'test Description 2';
               // lineitem.Price_Override__c = 900;
               lineitem.Beadchip_Part_Number__c = null;
               lineitem.Project_Id__c = 'ProjectIDConsortia';
               lineitem.Max_Samples_Allowed_Per_kit__c = 8;
               lineitem.Price_per_sample__c = null;
               lineitem.Reason_For_Price_Override__c = 'test';
               lineitem.Apttus_Config2__StartDate__c = Date.today();
               lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
               lineitem.Reason_For_Price_Override__c = 'test';
               lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
               lineitem.Applied_Discount_Percentage__c = 100;
               lineitem.Cost_Center__c = '67';
               lineitem.Global_Trade_Block__c = true;
               lineitem.Apttus_Config2__Quantity__c = 3;
               lineitem.Line_Item_Old_Values__c = NULL;
               //lineitem.Software_Id__c = NULL;
               lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;

           }

       }
       update lineItemList;

       proposal.Promotion_JSON__c = PROMOTION_JSON;
       objProductConfig.Promotion_JSON__c = PROMOTION_JSON;
       objProductConfig.Is_SAP_Pricing_Completed__c = true;
       objProductConfig.Apttus_Config2__IsPricePending__c = true;
       objProductConfig.Number_of_Line_Items_During_Check_Price__c = 3;
       objProductConfig.SAP_Warnings__c = 'Beadchip Warning Error'; //DCP-31081 Add warning message
       objProductConfig.SAP_Errors__c = 'SAP Errors'; 
       proposal.Fapiao_Type_Code__c = null;
       proposal.Sold_To_Sales_Organization__c = 'CNO3';
       update proposal;
       update objProductConfig;

       System.debug('@@@ line items:'+ lineItemList);
       ApttusCheckPriceBaseClass objCheckPriceBaseClass = new ApttusCheckPriceBaseClass();//DCP-34013

       Test.setCurrentPageReference(new PageReference(PAGE_APTTUS_CHECK_PRICE));
       System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
       System.currentPageReference().getParameters().put('flow', 'NGDefault');
       System.currentPageReference().getParameters().put('Id',objProductConfig.Id);

       //Test.startTest();

        // test: change in Quantity
        lineItemList.get(0).Apttus_Config2__Quantity__c = 5;
        lineItemList.get(0).Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
        lineItemList.get(0).Program_Type__c = 'Demo Program';
        update lineItemList;

        Apttus_Config2__ProductConfiguration__c objProductConfig2 = new ApttusProductConfigurationsSelector().selectConfigWithLines(new Set<Id>{objProductConfig.Id})[0];
        //DCP-34910 Validate Cart Update
        ApttusCheckPriceBaseClass baseClass = new ApttusCheckPriceBaseClass();
        baseClass.updateProductConfig(objProductConfig2,'Saved');
        baseClass.updateQuotation(String.valueOf(proposal.Id),false,0);
        
        ApttusProposalsSelector apttusProposalsSelector = new ApttusProposalsSelector();
        Apttus_Proposal__Proposal__c objQuotation = apttusProposalsSelector.selectProposalById(String.valueOf(proposal.Id));
        objQuotation.Validation_In_Progress__c = false;
        objQuotation.Async_Validation_Complete__c = true;
        Database.update(objQuotation,false);
        PostToChatterAfterValidation.postToChatter(new List<Id>{proposal.Id});

        System.debug('@@@ Direct Sale to Ultimate Consignee: '+objProductConfig2.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c);
        //DCP-34013
        ApttusCheckPriceBaseClass.boolConsortia = false;
        objCheckPriceBaseClass.validateCart(objProductConfig2, lineItemList,true);

        System.debug('@@@@ Is_SAP_Pricing_Completed__c post calling validate Cart ' + objProductConfig2.Is_SAP_Pricing_Completed__c);

        //DCP-25322, Added condition for manual rebate
        lineItemList.get(0).Manual_Rebate__c = 50;
        lineItemList.get(0).Line_Item_Validate_Old__c = '{"Manual_Rebate__c" : 50,"LineNumber" : 1}';
        lineItemList.get(0).Distributor_Total_Discount__c = 50;
        update lineItemList;

        Apttus_Config2__ProductConfiguration__c objProductConfig3 = new ApttusProductConfigurationsSelector().selectConfigWithLines(new Set<Id>{objProductConfig.Id})[0];
        objCheckPriceBaseClass.validateCart(objProductConfig3, lineItemList,true);//DCP-34013
        objCheckPriceBaseClass.validateCart(objProductConfig, lineItemList,true);//DCP-34013
        objCheckPriceBaseClass.boolValidationStatus = false;
        objCheckPriceBaseClass.validateCart(objProductConfig, lineItemList,true);//DCP-34013
        RealTimePricingRequestGenerator.createJSON(objProductConfig2,lineItemList); //DCP-23566
        
        Test.stopTest();
        system.assert(objProductConfig.Apttus_Config2__IsPricePending__c,true);
    }

    @isTest
    static void testGenerate()
    {
        Opportunity objOpportunity = [Select Id, Name, Direct_Sale_to_Ultimate_Consignee__c  from Opportunity where Name='opp3'];
        objOpportunity.Direct_Sale_to_Ultimate_Consignee__c = true;
        update objOpportunity;

        Apttus_Proposal__Proposal__c proposal = [Select id,name,Sub_Total__c,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Primary_Contact__c, Apttus_Proposal__Proposal_Name__c,Ultimate_Consignee__c,Apttus_Proposal__ExpectedStartDate__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal3' LIMIT 1];
        proposal.Apttus_Proposal__ExpectedStartDate__c = null;
        update proposal; 

        List<product2> product=[Select id ,name from product2 LIMIT 5];
        product[0].End_Of_Sale_Date__c = Date.today()-1;
        product[0].End_Of_Service_Date__c = Date.today();
        product[3].End_Of_Sale_Date__c = Date.today();
        product[3].End_Of_Service_Date__c = Date.today()-1;
        product[4].End_Of_Sale_Date__c = Date.today()-1;
        product[4].End_Of_Service_Date__c = Date.today()-1;


        Apttus_Config2__ProductConfiguration__c objApttusProductConfig=TestDataProposal.getNewCart(proposal);

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c LIMIT 1];
        lstPriceListItemId[0].Apttus_Config2__PriceType__c = 'One Time';


        List<Apttus_Proposal__Proposal_Line_Item__c> listProposalLineItem = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 = TestDataProposal.initProposalLineItem(proposal, product[0]);
        proposalLineItem1.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem1.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem1.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem1.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem1.Project_Id__c = 'Project1';
        proposalLineItem1.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem1.Price_per_sample__c = 32;
        proposalLineItem1.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem1.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem1);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem2 = TestDataProposal.initProposalLineItem(proposal, product[3]);
        proposalLineItem2.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem2.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem2.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem2.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem2.Project_Id__c = 'Project1';
        proposalLineItem2.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem2.Price_per_sample__c = 32;
        proposalLineItem2.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem2.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem2);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem3 = TestDataProposal.initProposalLineItem(proposal, product[4]);
        proposalLineItem3.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem3.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem3.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem3.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem3.Project_Id__c = 'Project1';
        proposalLineItem3.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem3.Price_per_sample__c = 32;
        proposalLineItem3.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem3.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem3);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem4 = TestDataProposal.initProposalLineItem(proposal, product[0]);
        proposalLineItem4.Apttus_QPConfig__OptionId__c = product[0].Id;
        proposalLineItem4.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem4.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem4.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem4.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem4.Project_Id__c = 'Project1';
        proposalLineItem4.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem4.Price_per_sample__c = 32;
        proposalLineItem4.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem4.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem4);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem5 = TestDataProposal.initProposalLineItem(proposal, product[3]);
        proposalLineItem4.Apttus_QPConfig__OptionId__c = product[3].Id;
        proposalLineItem5.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem5.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem5.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem5.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem5.Project_Id__c = 'Project1';
        proposalLineItem5.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem5.Price_per_sample__c = 32;
        proposalLineItem5.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem5.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem5);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem6 = TestDataProposal.initProposalLineItem(proposal, product[4]);
        proposalLineItem4.Apttus_QPConfig__OptionId__c = product[4].Id;
        proposalLineItem6.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem6.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem6.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem6.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem6.Project_Id__c = 'Project1';
        proposalLineItem6.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem6.Price_per_sample__c = 32;
        proposalLineItem6.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem6.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem6);

        Test.startTest();
        insert listProposalLineItem; 
         
        
        RealtimePricingRequest.createJSONForGenerateQuote(proposal.id,true); 
//
        System.currentPageReference().getParameters().put('Id',proposal.Id );
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0001',listProposalLineItem[0]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0002',listProposalLineItem[1]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0003',listProposalLineItem[2]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0004',listProposalLineItem[3]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0005',listProposalLineItem[4]);
        ApttusGenerateQuoteController.lineNameToLineItem.put('LI-0006',listProposalLineItem[5]);
        ApttusGenerateQuoteController objApptusGenQuote=new ApttusGenerateQuoteController();
        ApttusGenerateQuoteController.strQuoteID=proposal.id;
        ApttusGenerateQuoteController.reCheckPricing();

        objApptusGenQuote.redirectToGenerate();
        objApptusGenQuote.redirectToQuote();

        ApttusProposalsSelector apttusProposalsSelector = new ApttusProposalsSelector();
        Apttus_Proposal__Proposal__c objQuotation = apttusProposalsSelector.selectProposalById(String.valueOf(proposal.Id));
        objQuotation.Validation_In_Progress__c = true;                          
        //DCP-37888 For large cart generate.        
        objQuotation.Generate_In_Progress__c = true;        
        Database.update(objQuotation,false); 
        PostToChatterAfterValidation.postToChatter(new List<Id>{proposal.Id});
        //DCP-37888 For large cart generate.        
        PostToChatterAfterGenerate.postToChatter(new List<Id>{objQuotation.Id});
        ApttusGenerateQuoteController apttusGnrtQuoteCtrl = new ApttusGenerateQuoteController(proposal.Id);
        apttusGnrtQuoteCtrl.redirectToError();
        Test.stopTest();
        System.assertEquals(false, ApttusGenerateQuoteController.boolHasError);
    }

    /*
    Added By Saswati
    DCP-28565 : Coverage for Fapiao functionality
    */

     @isTest
    static void testFapiao(){

        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c,Quote_Type__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal4' LIMIT 1];
        proposal.Fapiao_Type_Code__c ='';
        proposal.Fapiao_Type_Description__c ='';
        proposal.Sold_To_Sales_Organization__c = 'CN03';
        update proposal;
        Test.startTest();

        Product2 objProduct = TestDataMaster.createProduct(false);
        insert objProduct;

        MockApttusSAPConnector.strQuoteNumber = proposal.name;

        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.initCart(proposal);
        testCart.Name =TEST_CART_NAME;
        insert testCart;

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id,Apttus_Config2__IsPricePending__c,Is_SAP_Pricing_Completed__c,GT_Check_Pending_Count__c,Number_of_Line_Items_During_Check_Price__c,Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c, Apttus_QPConfig__Proposald__r.Quote_Type__c from Apttus_Config2__ProductConfiguration__c where Name =: TEST_CART_NAME LIMIT 1];
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        objProductConfig.Is_SAP_Pricing_Completed__c = true;
        update objProductConfig;

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = objProduct.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);


        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

        for (Integer idx = 0; idx < lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if (idx == 0)
            {
                system.debug('Line items IDX 0 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = 1;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = 1;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = 1;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=null;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Applied_Discount_Percentage__c = 80;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Line_Description__c = TEST_LINE_DESCRIPTION;
                lineitem.Price_Override__c = 900;
                lineitem.Beadchip_Part_Number__c = null;
                lineitem.Project_Id__c = 'ProjectIDConsortia';
                lineitem.Max_Samples_Allowed_Per_kit__c = 8;
                lineitem.Price_per_sample__c = null;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Cost_Center__c = '67';
                lineitem.Global_Trade_Block__c = true;
                lineitem.Apttus_Config2__Quantity__c = 1;
                lineitem.Sales_Discretionary_Discount__c = 10;
                lineitem.Sales_Discretionary_Type__c = DISCOUNT_TYPE_PERCENT;
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
            }

       }
       update lineItemList;

       proposal.Promotion_JSON__c = PROMOTION_JSON;
       objProductConfig.Promotion_JSON__c = PROMOTION_JSON;
       objProductConfig.Is_SAP_Pricing_Completed__c = true;
       objProductConfig.Apttus_Config2__IsPricePending__c = true;
       objProductConfig.Number_of_Line_Items_During_Check_Price__c = 3;
       update proposal;
       update objProductConfig;
        
       System.debug('@@@ line items:'+ lineItemList);
        ApttusCheckPriceController objCheckPriceController = new ApttusCheckPriceController();

       Test.setCurrentPageReference(new PageReference(PAGE_APTTUS_CHECK_PRICE));
       System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
       System.currentPageReference().getParameters().put('flow', 'NGDefault');
       System.currentPageReference().getParameters().put('Id',objProductConfig.Id);

       objCheckPriceController.boolValidationError =false;

      // Test.startTest();

        objCheckPriceController.callSAP();
        //objCheckPriceController.validateCart(objProductConfig);
        //objCheckPriceController.redirectToCart();
       // objCheckPriceController.callSAP();
       // objCheckPriceController.repriceCart();

        System.debug('@@@@ Is_SAP_Pricing_Completed__c post calling validate Cart ' + objProductConfig.Is_SAP_Pricing_Completed__c);



        system.assert(proposal.Fapiao_Type_Code__c!=null ,FAPIAO_COND_NOT_SATISFIED);

        proposal.Fapiao_Type_Code__c =null;
        update proposal;

        objCheckPriceController.callSAP();
        //objCheckPriceController.validateCart(objProductConfig);
        //objCheckPriceController.redirectToCart();
        objCheckPriceController.callSAP();
        //objCheckPriceController.repriceCart();


        ApttusGenerateQuoteController objGenerateQuoteController = new ApttusGenerateQuoteController();
        ApttusGenerateQuoteController.strQuoteID=proposal.id;
        ApttusGenerateQuoteController.reCheckPricing();

        objGenerateQuoteController.redirectToGenerate();
        objGenerateQuoteController.redirectToQuote();
         system.assert(proposal.Fapiao_Type_Description__c!=null ,FAPIAO_COND_NOT_SATISFIED);
        Test.stopTest();



    }

     @isTest
    static void testFapiaoCheckPrice(){

        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Type__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal3' LIMIT 1];
        proposal.Fapiao_Type_Code__c ='';
        proposal.Fapiao_Type_Description__c ='';
        proposal.Sold_To_Sales_Organization__c = 'CN03';
        update proposal;
        Test.startTest();
        Product2 objProduct = TestDataMaster.createProduct(false);
        insert objProduct;

        MockApttusSAPConnector.strQuoteNumber = proposal.name;

        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.initCart(proposal);
        testCart.Name =TEST_CART_NAME;
        insert testCart;

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id,Apttus_Config2__IsPricePending__c,Is_SAP_Pricing_Completed__c,GT_Check_Pending_Count__c,Number_of_Line_Items_During_Check_Price__c,Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c, Apttus_QPConfig__Proposald__r.Quote_Type__c from Apttus_Config2__ProductConfiguration__c where Name =: TEST_CART_NAME LIMIT 1];
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        objProductConfig.Is_SAP_Pricing_Completed__c = true;
        update objProductConfig;

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = objProduct.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);


        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        // Line Item Creation and Modification to test ValidateCart()
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

        for (Integer idx = 0; idx < lineItemList.size(); idx++)
        {
            Apttus_Config2__LineItem__c lineitem = lineItemList.get(idx);
            if (idx == 0)
            {
                system.debug('Line items IDX 0 --'+lineitem);
                lineitem.Shipping_In_Close_Quarter__c = 1;
                lineitem.Shipping_In_1Q_After_Close_Quarter__c = 1;
                lineitem.Shipping_In_2Q_After_Close_Quarter__c = 1;
                lineitem.Apttus_Config2__ListPrice__c = 300;
                lineitem.Apttus_Config2__PriceListItemId__c=null;
                lineitem.Apttus_Config2__Quantity__c=400;
                lineitem.Applied_Discount_Percentage__c = 80;
                lineitem.Sales_Discretionary_Type__c = Label.LineItemSalesDiscretionaryTypePercentageDiscount;
                lineitem.Applied_Discount_Details__c = Label.ApprovalStepNameSalesDiscretionary;
                lineitem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
                lineitem.Apttus_Config2__PricingStatus__c='Pending';
                lineitem.Apttus_Config2__LineStatus__c = 'New';
                lineitem.Is_New__c = true;
                lineitem.Line_Description__c = TEST_LINE_DESCRIPTION;
                lineitem.Price_Override__c = 900;
                lineitem.Beadchip_Part_Number__c = null;
                lineitem.Project_Id__c = 'ProjectIDConsortia';
                lineitem.Max_Samples_Allowed_Per_kit__c = 8;
                lineitem.Price_per_sample__c = null;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Apttus_Config2__StartDate__c = Date.today();
                lineitem.Apttus_Config2__EndDate__c = Date.today() +1;
                lineitem.Reason_For_Price_Override__c = 'test';
                lineitem.Applied_Discount_Details__c = SALES_DISCRETIONARY;
                lineitem.Applied_Discount_Percentage__c = 100;
                lineitem.Cost_Center__c = '67';
                lineitem.Global_Trade_Block__c = true;
                lineitem.Apttus_Config2__Quantity__c = 1;
                lineitem.Sales_Discretionary_Discount__c = 10;
                lineitem.Sales_Discretionary_Type__c = DISCOUNT_TYPE_PERCENT;
                lineitem.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
                lineitem.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
            }

       }
       
       update lineItemList;

       proposal.Promotion_JSON__c = PROMOTION_JSON;

       objProductConfig.Promotion_JSON__c = PROMOTION_JSON;
       objProductConfig.Is_SAP_Pricing_Completed__c = true;
       objProductConfig.Apttus_Config2__IsPricePending__c = true;
       objProductConfig.Number_of_Line_Items_During_Check_Price__c = 3;
       update proposal;
       update objProductConfig;

       System.debug('@@@ line items:'+ lineItemList);
        ApttusCheckPriceController objCheckPriceController = new ApttusCheckPriceController();
         objCheckPriceController.boolValidationError =false;
       Test.setCurrentPageReference(new PageReference(PAGE_APTTUS_CHECK_PRICE));
       System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
       System.currentPageReference().getParameters().put('flow', 'NGDefault');
       System.currentPageReference().getParameters().put('Id',objProductConfig.Id);


        objCheckPriceController.callSAP();
        //objCheckPriceController.validateCart(objProductConfig);
        objCheckPriceController.redirectToCart();
        objCheckPriceController.callSAP();
       // objCheckPriceController.repriceCart();

        System.debug('@@@@ Is_SAP_Pricing_Completed__c post calling validate Cart ' + objProductConfig.Is_SAP_Pricing_Completed__c);



        system.assert(proposal.Fapiao_Type_Code__c!=null ,FAPIAO_COND_NOT_SATISFIED);

        proposal.Fapiao_Type_Code__c =null;
        update proposal;

        objCheckPriceController.callSAP();
        //objCheckPriceController.validateCart(objProductConfig);
        objCheckPriceController.redirectToCart();
        objCheckPriceController.callSAP();
       // objCheckPriceController.repriceCart();

        ApttusGenerateQuoteController objGenerateQuoteController = new ApttusGenerateQuoteController();
        ApttusGenerateQuoteController.strQuoteID=proposal.id;
        ApttusGenerateQuoteController.reCheckPricing();

        objGenerateQuoteController.redirectToGenerate();
        objGenerateQuoteController.redirectToQuote();
         system.assert(proposal.Fapiao_Type_Description__c!=null ,FAPIAO_COND_NOT_SATISFIED);
        Test.stopTest();
    }

    /*Method - To cover exception for Post To Chatter After Generate Class */
    @isTest
    public static void testCatchPostToChatterGenerate()
    {
        Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal 3' LIMIT 1];
        PostToChatterAfterGenerate.postToChatter(new List<Id>{proposal.Id});
        System.assertEquals(true,String.isNotBlank(proposal.Apttus_Proposal__Proposal_Name__c)); //Covers catch portion
    }
    /*
    *  @author      : 
    *  @description : Method to test existing subscriptions.
    *  @param       : 
    *  @return      : Void.
    */
    @isTest
    public static void testExistingSubscriptions()
    {
        Opportunity objOpportunity = [Select Id, Name, Direct_Sale_to_Ultimate_Consignee__c  from Opportunity where Name='opp3'];
        objOpportunity.Direct_Sale_to_Ultimate_Consignee__c = true;
        update objOpportunity;

        Apttus_Proposal__Proposal__c proposal = [Select id,name,Sub_Total__c,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Primary_Contact__c, Apttus_Proposal__Proposal_Name__c,Ultimate_Consignee__c,Apttus_Proposal__ExpectedStartDate__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal3' LIMIT 1];
        proposal.Apttus_Proposal__ExpectedStartDate__c = null;
        update proposal; 

        List<product2> product=[Select id ,name from product2 LIMIT 5];
        product2 informaticsProduct = [SELECT id FROM product2 WHERE Material_Class__c='Informatics Software' LIMIT 1];

        Test.startTest();
        Apttus_Config2__ProductConfiguration__c objApttusProductConfig=TestDataProposal.getNewCart(proposal);

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId =[select Id,Apttus_Config2__PriceType__c from Apttus_Config2__PriceListItem__c LIMIT 1];
        lstPriceListItemId[0].Apttus_Config2__PriceType__c = 'One Time';


        List<Apttus_Proposal__Proposal_Line_Item__c> listProposalLineItem = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem1 = TestDataProposal.initProposalLineItem(proposal, product[0]);
        proposalLineItem1.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem1.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem1.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem1.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem1.Project_Id__c = 'Project1';
        proposalLineItem1.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem1.Price_per_sample__c = 32;
        proposalLineItem1.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem1.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem1);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem2 = TestDataProposal.initProposalLineItem(proposal, product[3]);
        proposalLineItem2.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem2.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem2.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem2.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem2.Project_Id__c = 'Project1';
        proposalLineItem2.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem2.Price_per_sample__c = 32;
        proposalLineItem2.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem2.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem2);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem3 = TestDataProposal.initProposalLineItem(proposal, product[4]);
        proposalLineItem3.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem3.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem3.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem3.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem3.Project_Id__c = 'Project1';
        proposalLineItem3.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem3.Price_per_sample__c = 32;
        proposalLineItem3.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem3.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem3);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem4 = TestDataProposal.initProposalLineItem(proposal, product[0]);
        proposalLineItem4.Apttus_QPConfig__OptionId__c = product[0].Id;
        proposalLineItem4.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem4.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem4.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem4.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem4.Project_Id__c = 'Project1';
        proposalLineItem4.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem4.Price_per_sample__c = 32;
        proposalLineItem4.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem4.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem4);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem5 = TestDataProposal.initProposalLineItem(proposal, product[3]);
        proposalLineItem4.Apttus_QPConfig__OptionId__c = product[3].Id;
        proposalLineItem5.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem5.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem5.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem5.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem5.Project_Id__c = 'Project1';
        proposalLineItem5.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem5.Price_per_sample__c = 32;
        proposalLineItem5.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem5.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem5);

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem6 = TestDataProposal.initProposalLineItem(proposal, product[4]);
        proposalLineItem4.Apttus_QPConfig__OptionId__c = product[4].Id;
        proposalLineItem6.Apttus_QPConfig__HasIncentives__c = false;
        proposalLineItem6.Apttus_QPConfig__ConfigurationId__c = objApttusProductConfig.id;
        proposalLineItem6.Apttus_QPConfig__NetPrice__c=20;
        proposalLineItem6.Beadchip_Part_Number__c = 'BeadChip1';
        proposalLineItem6.Project_Id__c = 'Project1';
        proposalLineItem6.Max_Samples_Allowed_Per_kit__c = 1;
        proposalLineItem6.Price_per_sample__c = 32;
        proposalLineItem6.Apttus_QPConfig__DerivedFromId__c = null;
        proposalLineItem6.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.get(0).id;
        listProposalLineItem.add(proposalLineItem6);

        insert listProposalLineItem;

        Apttus_Config2__Order__c aptusOrder = new Apttus_Config2__Order__c(Apttus_QPConfig__ProposalId__c=proposal.id,
                                                                           Apttus_Config2__PrimaryContactId__c = proposal.Apttus_Proposal__Primary_Contact__c,
                                                                           Apttus_Config2__RelatedOpportunityId__c = objOpportunity.id,
                                                                           Ultimate_Consignee__c = proposal.Ultimate_Consignee__c
                                                                          );
        insert aptusOrder;
        Apttus_Config2__OrderLineItem__c orderLine = new Apttus_Config2__OrderLineItem__c(Apttus_Config2__OrderId__c=aptusOrder.id,
                                                                                        Apttus_Config2__LineNumber__c=0,
                                                                                        Apttus_Config2__ItemSequence__c=0,
                                                                                        Apttus_Config2__ProductId__c=informaticsProduct.id,
                                                                                        Apttus_QPConfig__ProposalLineItemId__c = listProposalLineItem.get(1).id,
                                                                                        Apttus_Config2__EndDate__c = System.today(),
                                                                                        Apttus_Config2__Quantity__c=1);
        insert orderLine;
        Apttus_Proposal__Proposal_Line_Item__c qli = listProposalLineItem.get(1);
        qli.Existing_Subscription__c = orderLine.id;
        update qli;
        
        RealtimePricingRequest.createJSONForGenerateQuote(proposal.id,false);
        

        Apttus_Proposal__Proposal_Line_Item__c qli1 = [Select Id, Existing_Subscription__c from Apttus_Proposal__Proposal_Line_Item__c WHERE Id=: qli.id];
        
        Test.stopTest();
        System.assertEquals(orderLine.id, qli1.Existing_Subscription__c);
    
    
    }
    /**
    * DCP-46872
    * @author Adyasha Satapathy
    **/
    @isTest
    public static void testSendProductInteresttoSAP()
    {   
        Opportunity objOpportunity = [SELECT Id,Name,Work_Order__c,AccountId,Type,Product_Interest__c FROM Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [SELECT Id,Name,Apttus_Proposal__Account__c,Apttus_Proposal__Primary_Contact__c, Work_Order__c from Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c = :objOpportunity.Id LIMIT 1];
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;
        
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(TestPartsOrderLines.STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT, null, TestPartsOrderLines.STRING_WORK_ORDER_STATUS_INITIATED);
        objWorkOrder.SVMXC__Order_Type__c = Label.Presales;
        objWorkOrder.SVMXC__Company__c = objProposal.Apttus_Proposal__Account__c;
        objWorkOrder.SVMXC__Contact__c = objProposal.Apttus_Proposal__Primary_Contact__c;
        objWorkOrder.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(TestPartsOrderLines.STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT).getRecordTypeId();
        objWorkOrder.OwnerId = UserInfo.getUserId();
        objWorkOrder.Cost_Center__c = 123456;
        insert objWorkOrder;
        
        setting.Bypass_All_Validations__c = false;
        update setting;
        
        String strRecordTypeId = Opportunities.RECORD_TYPE_MAP.get(Label.FieldServices).getRecordTypeId();
        objOpportunity.Work_Order__c = objWorkOrder.Id;
        objOpportunity.Type = Label.OpportunityTypeBillableService;
        objOpportunity.Product_Interest__c = Label.OpportunityProductInterestBreakFix;
        objOpportunity.RecordTypeId = strRecordTypeId;
        update objOpportunity;
        
        Test.startTest();

        objProposal.Work_Order__c = objWorkOrder.Id;
        update objProposal;

        Product2 objProduct = [Select id From Product2 LIMIT 1];
        MockApttusSAPConnector.strQuoteNumber = objProposal.name;
                
        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = objProposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id, Promo_Name_1__c, Promo_Name_2__c, Promo_Name_3__c, Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c, Apttus_QPConfig__Proposald__r.Quote_Type__c,Work_Order__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        objProductConfig.Work_Order__c = objWorkOrder.Id;
        update objProductConfig;

        Test.setCurrentPageReference(new PageReference(PAGE_APTTUS_CHECK_PRICE));
        System.currentPageReference().getParameters().put('businessObjectId', objProposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id );

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = objProduct.Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
        
        Apttus_Config2__PriceListItem__c objPriceListItem = [select Id from Apttus_Config2__PriceListItem__c LIMIT 1];

        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

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
                lineitem.Apttus_Config2__PriceListItemId__c = objPriceListItem.id;
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

            }
        }
        update lineItemList;

        ApttusCheckPriceController objCheckPriceController = new ApttusCheckPriceController();
        objCheckPriceController.callSAP();
        update new Apttus_Proposal__Proposal__c(id=objProposal.Id,Sub_Total__c = 0);
        Apttus_Proposal__Proposal_Line_Item__c objProposalLineItem = TestDataProposal.initProposalLineItem(objProposal, objProduct);
        objProposalLineItem.Apttus_QPConfig__HasIncentives__c = false;
        objProposalLineItem.Apttus_QPConfig__ConfigurationId__c = objProductConfig.id;
        objProposalLineItem.Apttus_QPConfig__NetPrice__c=20;
        objProposalLineItem.Beadchip_Part_Number__c = 'BeadChip1';
        objProposalLineItem.Project_Id__c = 'Project1';
        objProposalLineItem.Max_Samples_Allowed_Per_kit__c = 1;
        objProposalLineItem.Price_per_sample__c = 32;
        objProposalLineItem.Apttus_QPConfig__DerivedFromId__c = null;
        objProposalLineItem.Apttus_QPConfig__PriceListItemId__c = objPriceListItem.Id;
        insert new List<Apttus_Proposal__Proposal_Line_Item__c>{objProposalLineItem};
        
        ApttusGenerateQuoteController.strQuoteID = objProposal.id;
        ApttusGenerateQuoteController.reCheckPricing();

        Test.stopTest();

        Apttus_Proposal__Proposal__c objProposalPostUpdate = [Select Id,SAP_Quote__c,Work_Order__r.Name, SAP_Errors__c from Apttus_Proposal__Proposal__c where Id = :objProposal.Id];

        for(Interface_Log__c objLog : [SELECT Id, Json_Message__c, Interface_Name__c FROM Interface_Log__c LIMIT 2])
        {
            if(objLog.Interface_Name__c == STRING_QUOTE_VALIDATE_INTERFACE)
            {
                System.assert(objLog.Json_Message__c.contains(RealtimePricingRequestGenerator.mapProductInterestToSAPValue.get(objOpportunity.Product_Interest__c)), 'Product Interest not sent to SAP');
                System.assert(objLog.Json_Message__c.contains(objProposalPostUpdate.Work_Order__r.Name), 'Work Order not sent to SAP');
            }
            else if(objLog.Interface_Name__c == STRING_QUOTE_GENERATE_INTERFACE)
            {
                System.assert(objLog.Json_Message__c.contains(RealtimePricingRequestGenerator.mapProductInterestToSAPValue.get(objOpportunity.Product_Interest__c)), 'Product Interest not sent to SAP');
                System.assert(objLog.Json_Message__c.contains(objProposalPostUpdate.Work_Order__r.Name), 'Work Order not sent to SAP');
            }
        }
    }
    /**
    * DCP-46276 : Test class to test relocation errors 
    * @author KD
    **/
    @isTest
    public static void testRelocationValidationAndPricings()
    {
        System.debug('TTN queries so far ' + Limits.getQueries());
        id idRecordTypeId = Opportunities.RECORD_TYPE_MAP.get(Label.OpportunityRTDirectFieldServices).getRecordTypeId();
        //Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Opportunity__c,Apttus_Proposal__Opportunity__r.AccountId From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c IN ('Test Proposal2','Test Proposal') LIMIT 2];
        //Apttus_Proposal__Proposal__c proposal1 = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Opportunity__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'  LIMIT 1];
        Apttus_Proposal__Proposal__c proposal,proposal1;
        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Opportunity__c,Apttus_Proposal__Opportunity__r.AccountId From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal2' OR Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        for(Apttus_Proposal__Proposal__c objProposal : lstProposal){
            if(objProposal.Apttus_Proposal__Proposal_Name__c == 'Test Proposal'){
                proposal = objProposal;
            }
            else{
                proposal1 = objProposal;
            }
        }
        update new Opportunity(Id = proposal.Apttus_Proposal__Opportunity__c,Product_Interest__c = Label.OpportunityProductInterestRelocation,Type = Label.OpportunityTypeBillableService,recordTypeId =idRecordTypeId ,Current_Ultimate_Consignee__c=proposal.Apttus_Proposal__Opportunity__r.AccountId);
        Test.startTest();
        List<Product2> lstProduct = [Select id From Product2 LIMIT 2];
        lstProduct[0].ProductCode = Label.Labor_SQ_Product_Code;
        lstProduct[1].ProductCode = 'IL-SER-TRAVEL-Z1';
        //{"PromoCode":"NEWBEE","PromoChannel":null,"Marketing_Trade_In__c":"External"},{"PromoCode":"ICT-000021","PromoChannel":null,"Marketing_Trade_In__c":"Internal"},{"PromoCode":"ICT-000022","PromoChannel":null,"Marketing_Trade_In__c":"External"
       List<Promotions__c> tempNew= new List<Promotions__c>();
         Promotions__c temp1=new Promotions__c();
        temp1.Promotion_Code__c='NEWBEE';
        temp1.Promotion_Channel__c=null;
        temp1.Marketing_Trade_In__c='External';
        tempNew.add(temp1);
        Promotions__c temp2=new Promotions__c();
        temp2.Promotion_Code__c='ICT-000021';
        temp2.Promotion_Channel__c=null;
        temp2.Marketing_Trade_In__c='Internal';
        tempNew.add(temp2);
        Promotions__c temp3=new Promotions__c();
        temp3.Promotion_Code__c='ICT-000022';
        temp3.Promotion_Channel__c=null;
        temp3.Marketing_Trade_In__c='External';
        tempNew.add(temp3);
        Insert tempNew;
        
        //Added by SB - DGP-385
        Custom_Approval_Matrix__c recordCAM = New Custom_Approval_Matrix__c();
        recordCAM.Name = 'AMR Owner';
        recordCAM.Approval_Hierarchy_Type__c = 'Record Owner';
        recordCAM.Discount_Level_1__c = 1;
        recordCAM.Discount_Amount_Level_1__c = 500;
                        
        Insert recordCAM;
        
        
        update lstProduct;
        MockApttusSAPConnector.strQuoteNumber = proposal.name;
        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id, Promo_Name_1__c, Promo_Name_2__c, Promo_Name_3__c, Apttus_QPConfig__Proposald__c, Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c, Apttus_QPConfig__Proposald__r.Quote_Type__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];
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
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct1 = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct1.ProductId = lstProduct.get(1).Id;
        selectProduct1.Quantity = 1;
        selectProduct1.SellingTerm = 12;
        selectProduct1.StartDate = Date.today();
        selectProduct1.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct1);

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId = [select Id from Apttus_Config2__PriceListItem__c LIMIT 1];
        // Line Item Creation and Modification to test ValidateCart(), modified for DCP34013
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

        Apttus_Config2__LineItem__c lineitem = lineItemList.get(0);
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
        lineItem.Trade_In_Type__c='Marketing Internal';
        lineitem.Serial_Number__c = 'SERIAL2';
        lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
        lineitem.Approval_Matrix_Record_Owner__c = recordCAM.Id;
        
        Apttus_Config2__LineItem__c lineitem1 = lineItemList.get(1);
        lineitem1.Shipping_In_Close_Quarter__c = INTEGER_SHIPPING_IN_CLOSE_QUARTER;
        lineitem1.Shipping_In_1Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_1Q_AFTER_CLOSE_QUARTER;
        lineitem1.Shipping_In_2Q_After_Close_Quarter__c = INTEGER_SHIPPING_IN_2Q_AFTER_CLOSE_QUARTER;
        lineitem1.Line_Item_Old_Values__c = LINE_ITEM_OLD_VALUES_JSON;
        lineitem1.Line_Item_Validate_Old__c = LINE_ITEM_OLD_VALUES_JSON;
        lineitem1.Apttus_Config2__PricingStatus__c='Pending';
        lineitem1.Apttus_Config2__LineStatus__c = 'New';
        lineitem1.Is_New__c = true;
        lineitem1.Serial_Number__c = 'SERIAL2';
        lineitem1.Apttus_Config2__Quantity__c=400;
        lineitem1.Apttus_Config2__PriceListItemId__c=lstPriceListItemId.get(0).id;
        lineItem1.Trade_In_Type__c='Marketing Internal';
        lineitem1.Customer_Premium_Type__c='% Premium';
                lineitem1.Customer_Premium_Per_Unit__c= 90;
                lineitem1.List_Price__c=18000;
        lineitem1.Approval_Matrix_Record_Owner__c = recordCAM.Id;
        update lineItemList;
        ApttusCheckPriceController objCheckPriceController = new ApttusCheckPriceController();
        ApttusCheckPriceBaseClass objCheckPriceBaseClass = new ApttusCheckPriceBaseClass();//Added by Arnab - DCP-34013
        Apttus_Config2__ProductConfiguration__c objApttusProductConfig1=TestDataProposal.getNewCart(proposal1);
        //Calling validateCart from ApttusCheckPriceBaseClass
        objCheckPriceBaseClass.validateCart(objApttusProductConfig1, lineItemList,false);
        objCheckPriceBaseClass.validateCart(objProductConfig, lineItemList,false);
        objCheckPriceBaseClass.callSAP(true);
        objCheckPriceController.redirectToCart();
        objCheckPriceController.callSAP();
        objCheckPriceController.repriceCart();
        objCheckPriceController.callSAP();
        ApttusCheckPriceController objCheckPriceController1 = new ApttusCheckPriceController();
        objCheckPriceController1.strConfigId = objProductConfig.Id;
        //objCheckPriceController1.callSAP();
        objCheckPriceController1.strBusinessObjectId = objProductConfig.Apttus_QPConfig__Proposald__c; //Added by SB
        objCheckPriceController.redirectToQuote();
        UtilsRest.convertStringToNumber(null);
        Test.stopTest();

        system.assert(objProductConfig.Apttus_Config2__IsPricePending__c,'Princing not pending');
        system.assert(ApttusCheckPriceBaseClass.strErrorMsg.contains(Label.UI_Instrument_Compliance_Relocation),'Insturment Complaince not catched');
        system.assert(ApttusCheckPriceBaseClass.strErrorMsg.contains(Label.UI_Regulatory_Device_Relocation),'Regulatory Complaince not catched');
    }
    /**
    * DCP-45926 : Mandatory field
    * @author KD
    **/
    @isTest
    public static void testRelocationMandatoryLines()
    {
        System.debug('TTN queries so far ' + Limits.getQueries());
        id idRecordTypeId = Opportunities.RECORD_TYPE_MAP.get(Label.OpportunityRTDirectFieldServices).getRecordTypeId();
        Apttus_Proposal__Proposal__c proposal,proposal1;
        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id,name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__Opportunity__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal2' OR Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        for(Apttus_Proposal__Proposal__c objProposal : lstProposal){
            if(objProposal.Apttus_Proposal__Proposal_Name__c == 'Test Proposal'){
                proposal = objProposal;
            }
            else{
                proposal1 = objProposal;
            }
        }
        update new Opportunity(Id = proposal.Apttus_Proposal__Opportunity__c,Product_Interest__c = Label.OpportunityProductInterestRelocation,Type = Label.OpportunityTypeBillableService,recordTypeId =idRecordTypeId );
        List<Product2> lstProduct = [Select id From Product2 LIMIT 1];
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

        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);

        List<Apttus_Config2__PriceListItem__c> lstPriceListItemId = [select Id from Apttus_Config2__PriceListItem__c LIMIT 1];
        // Line Item Creation and Modification to test ValidateCart(), modified for DCP34013
        List<Apttus_Config2__LineItem__c> lineItemList = fetchLineItems(objProductConfig.Id);
        MockApttusSAPConnector.strLineItemNumber = lineItemList[0].name;

        Apttus_Config2__LineItem__c lineitem = lineItemList.get(0);
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
        lineitem.Serial_Number__c = 'SERIAL2';
        lineitem.Customer_Premium_Type__c='% Premium';
                lineitem.Customer_Premium_Per_Unit__c=90;
                lineitem.List_Price__c=18000;
        lineitem.Approval_Matrix_Record_Owner__c = null;
        ApttusCheckPriceController objCheckPriceController = new ApttusCheckPriceController();
        ApttusCheckPriceBaseClass objCheckPriceBaseClass = new ApttusCheckPriceBaseClass();//Added by Arnab - DCP-34013
        //DCP-46277: Start- Get Blanket PO product code
        List<Code_Parameter__mdt> lstCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CreateQuoteAutomation.CODE_PARAMETER_BLANKET_QUOTE_PRODUCTS});
        Test.startTest();
        Apttus_Config2__ProductConfiguration__c objApttusProductConfig1=TestDataProposal.getNewCart(proposal1);
        //Calling validateCart from ApttusCheckPriceBaseClass
        objCheckPriceBaseClass.validateCart(objApttusProductConfig1, lineItemList,false);
        objCheckPriceBaseClass.validateCart(objProductConfig, lineItemList,false);
        objCheckPriceBaseClass.callSAP(false);
        objCheckPriceController.redirectToCart();
        objCheckPriceController.callSAP();
        objCheckPriceController.repriceCart();
        objCheckPriceController.callSAP();
        ApttusCheckPriceController objCheckPriceController1 = new ApttusCheckPriceController();
        objCheckPriceController1.strConfigId = objProductConfig.Id;
        objCheckPriceController1.callSAP();
        objCheckPriceController.redirectToQuote();
        UtilsRest.convertStringToNumber(null);
        //DCP-46277: Start- Move ASserts and add for bypass scenario
        System.assert(objProductConfig.Apttus_Config2__IsPricePending__c,true);
        system.assert(ApttusCheckPriceBaseClass.strWarningMsgs.contains(Label.UI_Message_Travel_Zone_Missing),'Travel Zone missing error not thrown');
        system.assert(ApttusCheckPriceBaseClass.strWarningMsgs.contains(Label.UI_Message_Labour_Line_Missing),'Labour Line error not thrown');
        lstProduct[0].ProductCode=lstCodeParam[0].Value__c;
        update lstProduct;
        objCheckPriceController1.callSAP();
        System.assert(!ApttusCheckPriceBaseClass.strErrorMsg.contains(Label.UI_Message_Travel_Zone_Missing),'Travel Zone missing error thrown');
        System.assert(!ApttusCheckPriceBaseClass.strErrorMsg.contains(Label.UI_Message_Labour_Line_Missing),'Labour Line error thrown');
        //DCP-46277: End- Move ASserts and add for bypass scenario
        Test.stopTest();

    }
    /**
    * DCP-45926 : Common method
    * @author KD
    **/
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

    /** @author Jitesh Lakhwani
     * @description This is a test method to cover 'RealtimePricingResponse'
    */
    @isTest
    public static void testRealtimePricingResponse()
    {
        RealtimePricingResponse objRealtimePricingResponse = new RealtimePricingResponse();

        System.assertEquals('ZQT', objRealtimePricingResponse.DocType, 'Value is ZQT');
    }
}
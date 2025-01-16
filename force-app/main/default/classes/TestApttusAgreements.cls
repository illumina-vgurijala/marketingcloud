/**
*    @author Saswati Prusty
*    @date   05 Dec 2019
*    @description  DCP-454: Create Quote - Ability to Clone Quote
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Saswati Prusty       06 Dec 2019     DCP-31654 : Update Price group on insert and update.
*       B Kamini             13 Jan 2020     DCP-31209 : Validation method for Start & End dates
*       Adhithyan            23 Jan 2020     DCP-33550 : Updated test class to include product material number and agreeent material number match
*                                            Populated sales Org field for the trigger class to be covered
*       B Kamini             09 Feb 2020     DCP-33783 : Updated Price_Group__c on Agreements and Account Sales Area
*       Pankaj Sharma        10 Feb 2020     DCP-33708 : Added Price Group Description
*       B Kamini             11 Feb 2020     DCP-33783 : Added Custom setting Profile validation data setup
*       Umesh                11 Feb 2020     DCP-33757 : Added SalesOrg related validation changes
*       B Kamini             11 Feb 2020     DCP-33783 : Added Custom setting Profile validation data setup
*       Vignesh              21 Feb 2020     DCP-34091 : Added Validation logic for agreements.
*       Joshith K            04 Mar 2020     DCP-34982 : Added billing country code for account  in Setup method.
*       Saswati              12 Mar 2020     DCP-32046 : Increase coverage
*       Todd                 24 Mar 2020     DCP-33808 : validate changes on active agreements
*       B Kamini                        4  April 2020   SonarQube Issue fix: Added Constant APJ_USD_01 instead of literal '01-APJ-USD', Test_TXDR instead of literal 'Test TXDR', VC0013519_OPA instead of literal 'VC0013519-OPA'
*       Roopal               12 June 2020    DCP-37652: Approval email
*       Roopal               16 June 2020    DCP-37705: Channel Partner One Time Approval
*       Karthik Rayani       25-Sep-2020     DCP-40107 - Updated method testsetApprovalOnUpdate for new logic.
*       Rishab Wali          24-Nov-2020     DCP-43224 Account update on Agreement
*       Roopal Verma         03-Dev-2020     DCP-37652 Edit field on active agreement
*       Rishab Wali          24-Feb-2021     DCP-37232 - Default Preferred Language
*       Bharath Varma        29-Jun-2021     DCP-47006 - Count Number of UC Dicsount Line Items
*       Vivek R              03-Oct-2022     Added test method to cover serializeInputs() and restoreInputs() in the AgreementLineStatusBatchUpdate class
*       Arif,Dalali          28-Nov-2022      POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*       Amogh Ghodke         27-Nov-2023     CMCM-2709 - Added nonCompliantVar logic
*       Gerardo Garcia       08-Aug-2024     CMCM-9576 : Move PB into code. Set Clinical_Type__c with Account's, during beforeInsert.
*       Vijay Masne          23-Oct-2024     TI-10949  - TI- Agreement: Status & Status Category as Request.
*       Vijay Masne          11-Nov-2024     TI-10601  - TI- Agreement : Update Other Party Signed Date when fully signed
*/
@isTest
private with sharing class TestApttusAgreements
{
    //SonarQube Fix
    private static final String AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    private static final String TEST_TXDR = 'Test TXDR';
    private static final String VC0013519_OPA = 'VC0013519-OPA';
    private static final String DISTRIBUTOR = 'Distributor';
    private static final String TXDR = 'TXDR';
    private static final String ERP_123456 = '123456';
    private static final String ERP_234567 = '234567';
    private static final String USD = 'USD';
    private static final String HK01 = 'HK01';
    private static final String AU01 = 'AU01';
    private static final String AGRMNT_NAME_PRI_GRP = 'Test Agreement - Price Group';
    private static final String PRIMARY_ACCOUNT = 'PrimaryAccount';
    private static final String AGREEMENT_NO_PRICE_GROUP = 'Test Agreement -  No Price Group';
    private static final String AGREEMENT_ONE_TIME = 'Test Agreement - One Time';
    private static final String AGREEMENT_NO_SALES = 'Test Agreement -  No Sales Org';
    private static final String AGREEMENT_TENDER = 'Test Agreement - Tender';
    private static final String AGREEMENT_UC_DISCOUNT = 'Test Agreement - UC Discounts';
    private static final String ACCOUNT_CHANNEL_PARTNER_TYPE_VAD = 'Value Added Distributor';

    private static final Id REC_TYPE_CHANNEL_PARTNER = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
    private static final Id REC_TYPE_MASTER_AGREEMENT = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Service Agreement').getRecordTypeId();
    private static final Id REC_TYPE_TENDER = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Tender').getRecordTypeId();

    /**
     *  @author Saswati Prusty
     *  @description Test Data Setup
     **/
    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = ERP_123456;
        acc.Clinical_Type__c = 'Clinical';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = ERP_123456;
        acc.BIllingCountryCode='HK';
        acc.Channel_Partner_Type__c = ACCOUNT_CHANNEL_PARTNER_TYPE_VAD;

        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = ERP_234567;
        acc2.Clinical_Type__c = 'Clinical';
        acc2.BIllingCountryCode='HK' ;
        acc2.Name = ERP_234567;

        /*Start DCP-54438 Open Offer Agreements Account Setup*/
        Account primaryAcct = TestDataAccount.getCustomerAccount();
        primaryAcct.Clinical_Type__c = 'Clinical';
        primaryAcct.BIllingCountryCode='HK' ;
        primaryAcct.Name = PRIMARY_ACCOUNT;

        insert new List<Account> { acc, acc2, primaryAcct };

        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };

        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = ERP_123456;
        objCMD2.ERP_Customer_Id__c = ERP_234567;
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        TestDataAgreement.addHierarchyPermission();

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = USD;
        acc1SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = TXDR;
        acc1SalesArea.Sales_Organization__c=HK01;
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = USD;
        acc2SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Price_Group__c = TXDR;
        acc2SalesArea.Sales_Organization__c=AU01;
        acc2SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc2SalesArea.Distribution_Channel__c='01';

        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '02', '179', '00', false);
        acc3SalesArea.Account__c = acc2.Id;
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = USD;
        acc3SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc3SalesArea.Contract_Number__c ='67890_HK010100';
        acc3SalesArea.Price_Group__c = TXDR;
        acc3SalesArea.Sales_Organization__c=HK01;
        acc3SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc3SalesArea.Distribution_Channel__c='01';
        acc3SalesArea.ERP_Account_Sales_Area_Id__c='67890_HK010100';

        Account_Sales_Area__c acc4SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '02', '178', '00', false);
        acc4SalesArea.Account__c = acc.Id;
        acc4SalesArea.Price_List_Type__c = '06';
        acc4SalesArea.CurrencyIsoCode = USD;
        acc4SalesArea.Price_List__c = '06-SGD-USD';
        acc4SalesArea.Contract_Number__c = '123456_HK010200';
        acc4SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010200';
        acc4SalesArea.Price_Group__c = TXDR;
        acc4SalesArea.Sales_Organization__c=HK01;
        acc4SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc4SalesArea.Distribution_Channel__c='02';

        Account_Sales_Area__c acc5SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '01', '180', '00', false);
        acc5SalesArea.Account__c = primaryAcct.Id;
        acc5SalesArea.Price_List_Type__c = '06';
        acc5SalesArea.CurrencyIsoCode = USD;
        acc5SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc5SalesArea.Contract_Number__c = '123456_HK010100';
        acc5SalesArea.Price_Group__c = TXDR;
        acc5SalesArea.Sales_Organization__c=HK01;
        acc5SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc5SalesArea.Distribution_Channel__c='01';

        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea,acc3SalesArea,acc4SalesArea,acc5SalesArea };

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = VC0013519_OPA;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        insert new List<Product2> { product, productTwo, productThree };
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(AMEA_USD_01);  //POL-57
        Apttus_Config2__PriceList__c objPriceList2 = TestDataAgreement.initPriceList('06-SGD-USD');
        insert new List<Apttus_Config2__PriceList__c>{objPriceList, objPriceList2};
        
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(product, objPriceList);
        Apttus_Config2__PriceListItem__c objPriceListItem2 = TestDataAgreement.initPriceListItem(product, objPriceList2);
        Apttus_Config2__PriceListItem__c objPriceListItem3 = TestDataAgreement.initPriceListItem(productTwo, objPriceList2);
        Apttus_Config2__PriceListItem__c objPriceListItem4 = TestDataAgreement.initPriceListItem(productThree, objPriceList2);
        insert new List<Apttus_Config2__PriceListItem__c>{objPriceListItem, objPriceListItem2,objPriceListItem3,objPriceListItem4};

        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements(AGRMNT_NAME_PRI_GRP, acc.id);
        //oAgreement1.Customer_Discount_Level__c = 'Price Group';
        oAgreement1.Sales_Org__c =HK01;//adding reference sales org
        oAgreement1.RecordTypeId = REC_TYPE_CHANNEL_PARTNER;
        oAgreement1.Apttus__Auto_Renewal__c=True;

        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements(AGREEMENT_NO_PRICE_GROUP, acc2.id);
        oAgreement2.RecordTypeId = REC_TYPE_MASTER_AGREEMENT;
        oAgreement2.Apttus__Contract_Start_Date__c = system.today();
        oAgreement2.Apttus__Contract_End_Date__c = system.today() + 750;
        oAgreement2.Sales_Org__c = AU01; //DCP-33757//adding reference sales org

        Apttus__APTS_Agreement__c oAgreement3 = TestDataAgreement.initAgreements('Test Agreement - Date Validation', acc.id);
        oAgreement3.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement3.Sales_Org__c = HK01;//adding reference sales org
        oAgreement3.RecordTypeId = REC_TYPE_CHANNEL_PARTNER;
        //oAgreement3.Customer_Discount_Level__c = 'Price Group';

        Apttus__APTS_Agreement__c oAgreement4 = TestDataAgreement.initAgreements('Test Agreement - Activated', acc.id);
        oAgreement4.Apttus__Contract_Start_Date__c = system.today()+20;
        oAgreement4.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement4.Sales_Org__c = HK01;//adding reference sales org
        oAgreement4.RecordTypeId = REC_TYPE_CHANNEL_PARTNER;
        oAgreement4.Apttus__Status__c = 'Activated';
        oAgreement4.Apttus__Status_Category__c = 'In Effect';
        oAgreement4.Preferred_Language__c = 'English';


        Apttus__APTS_Agreement__c oAgreement5 = TestDataAgreement.initAgreements(AGREEMENT_ONE_TIME, acc.id); //DCP-37705
        oAgreement5.Sales_Org__c =HK01;//adding reference sales org
        oAgreement5.RecordTypeId = REC_TYPE_CHANNEL_PARTNER;
        oAgreement5.Apttus__Subtype__c = 'One Time';
        oAgreement5.One_Time_Agreement_Products__c = 'test';
        oAgreement5.Ultimate_Consignee__c = acc.id;

        Apttus__APTS_Agreement__c oAgreement6 = TestDataAgreement.initAgreements(AGREEMENT_NO_SALES, acc2.id);
        oAgreement6.RecordTypeId = REC_TYPE_MASTER_AGREEMENT;
        oAgreement6.Apttus__Contract_Start_Date__c = system.today();
        oAgreement6.Apttus__Contract_End_Date__c = system.today() + 750;
        oAgreement6.Sales_Org__c = ''; 

        Apttus__APTS_Agreement__c oAgreement7 = TestDataAgreement.initAgreements(AGREEMENT_TENDER, acc2.id);
        oAgreement7.Sales_Org__c = AU01;
        oAgreement7.RecordTypeId = REC_TYPE_TENDER;

        Apttus__APTS_Agreement__c oAgreement8 = TestDataAgreement.initAgreements(AGREEMENT_UC_DISCOUNT, acc.id);
        oAgreement8.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement8.Sales_Org__c = HK01;//adding reference sales org
        oAgreement8.RecordTypeId = REC_TYPE_CHANNEL_PARTNER;

        insert new List<Apttus__APTS_Agreement__c> {oAgreement1, oAgreement2, oAgreement3, oAgreement4, oAgreement5, oAgreement6, oAgreement7, oAgreement8};

        List<Approval_Hierarchy__c> lstApprovalHierarchy = new List<Approval_Hierarchy__c>();
        Approval_Hierarchy__c objDiscountApprovalHeirarchy = TestDataAgreement.initApprovalHierarchyStandingDiscount('CLM_Sales_Hierarchy', acc.OwnerId);
        lstApprovalHierarchy.add(objDiscountApprovalHeirarchy);

        Approval_Hierarchy__c objCustomApprovalHeirarchy = TestDataAgreement.initApprovalHierarchyStandingDiscount('CLM_Custom_Hierarchy', acc.OwnerId);
        lstApprovalHierarchy.add(objCustomApprovalHeirarchy);
        insert lstApprovalHierarchy;

        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();
        Custom_Approval_Matrix__c standingDiscountApprovalMatrix = TestDataAgreement.initApprovalMatrixForAgreement('CLM Discount', 10 , null, null,objCustomApprovalHeirarchy.id);

        standingDiscountApprovalMatrix.Distribution_Channel__c = '';
        standingDiscountApprovalMatrix.Currency__c = ''; 
        standingDiscountApprovalMatrix.region__c = ''; 
        standingDiscountApprovalMatrix.Sales_Organization__c = '';
        lstMatrix.add(standingDiscountApprovalMatrix);
        insert lstMatrix; 

        List<Apttus__AgreementLineItem__c> lstALI = new list<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c oAgreementLI1 = TestDataAgreement.initAgreementsLineItem(oAgreement3.id);
        oAgreementLI1.Material_Number__c = VC0013519_OPA;
        oAgreementLI1.Material_Group_1__c = 'BGS';
        oAgreementLI1.Line_Type__c = 'Material';
        oAgreementLI1.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI1.Discount_Type__c = '% Discount';
        oAgreementLI1.Discount__c = 15;
        oAgreementLI1.Customer_ERP_Number__c = ERP_123456;
        oAgreementLI1.Sales_Org__c = HK01;
        oAgreementLI1.Distribution_Channel__c = '02';
        oAgreementLI1.CurrencyIsoCode= USD;
        oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today()+1;
        oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+2;
        lstALI.add(oAgreementLI1);

        Apttus__AgreementLineItem__c oAgreementLI2 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLI2.Material_Number__c = VC0013519_OPA;
        oAgreementLI2.Material_Group_1__c = 'BGS';
        oAgreementLI2.Line_Type__c = 'Material';
        oAgreementLI2.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI2.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI2.Discount_Type__c = '% Discount';
        oAgreementLI2.Discount__c = 15;
        oAgreementLI2.Customer_ERP_Number__c = ERP_123456;
        oAgreementLI2.Sales_Org__c = HK01;
        oAgreementLI2.Distribution_Channel__c = '02';
        oAgreementLI2.CurrencyIsoCode= USD;
        oAgreementLI2.Apttus_CMConfig__StartDate__c = system.today()+1;
        oAgreementLI2.Apttus_CMConfig__EndDate__c = system.today()+2;
        
        lstALI.add(oAgreementLI2);
        Apttus__AgreementLineItem__c oAgreementLI3 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLI3.Material_Number__c = VC0013519_OPA;
        oAgreementLI3.Material_Group_1__c = 'BGS';
        oAgreementLI3.Line_Type__c = 'Material';
        oAgreementLI3.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI3.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI3.Discount_Type__c = '% Discount';
        oAgreementLI3.Discount__c = 15;
        oAgreementLI3.Customer_ERP_Number__c = ERP_123456;
        oAgreementLI3.Sales_Org__c = HK01;
        oAgreementLI3.Distribution_Channel__c = '02';
        oAgreementLI3.CurrencyIsoCode= USD;
        oAgreementLI3.Apttus_CMConfig__StartDate__c = system.today()+1;
        oAgreementLI3.Apttus_CMConfig__EndDate__c = system.today()+2;
        oAgreementLI3.Apttus_Approval__Approval_Status__c = ApttusAgreements.APPROVAL_STATUS_APPROVAL_REQUIRED;
        lstALI.add(oAgreementLI3);

        insert lstALI;
    }

    private static Account getAccountByName(String name){
        Account acc = [SELECT Id, Clinical_Type__c FROM Account WHERE Name = :name LIMIT 1];
        return acc;
    }

    private static Apttus__APTS_Agreement__c getAgreementByName(String name) {
        return [SELECT Id, Name, Price_Group__c, Apttus_Approval__Approval_Status__c, Clinical_Type__c,
            Approval_Request_Present__c,Submitted_by__c, Apttus__Account__c, Apttus__Contract_Start_Date__c,
            Apttus__Contract_End_Date__c, Sales_Org__c, RecordTypeId, Apttus__Status__c, Apttus__Status_Category__c,
            ALIs_with_UC_Material_Group__c
            FROM Apttus__APTS_Agreement__c
            WHERE Name = :name LIMIT 1];
    }

    @isTest
    static void testPriceGroupOnInsert()
    {
        List<Account> acc = [SELECT Id,Account_Group__c FROM Account LIMIT 2];

        List<Account_Sales_Area__c> acntSalesArea = [Select Id, Price_Group__c from Account_Sales_Area__c LIMIT 2];

        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();

        Test.starttest();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement 1 - Insert', acc.get(0).id);
        //oAgreement1.Customer_Discount_Level__c = 'Price Group';
        if(acc.get(0).Account_Group__c == DISTRIBUTOR){
            oAgreement1.recordtypeId = recTypeId;
        }
        insert oAgreement1;

        Apttus__APTS_Agreement__c agreement1 = [Select Id, Price_Group__c from Apttus__APTS_Agreement__c where Name='Test Agreement 1 - Insert'];

        Assert.areEqual(acntSalesArea.get(0).Price_Group__c,agreement1.Price_group__c,'insert failed');
        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement 2 - Insert', acc.get(1).id);
        oAgreement2.Justification_for_No_Agreement_Value__c = 'Tender';
        if(acc.get(1).Account_Group__c == DISTRIBUTOR){
            oAgreement2.recordtypeId = recTypeId;
        }
        insert oAgreement2;
        Apttus__APTS_Agreement__c agreement2 = [Select Id, Price_Group__c,Name from Apttus__APTS_Agreement__c where Name='Test Agreement 2 - Insert'];
        Assert.areEqual('Test Agreement 2 - Insert',agreement2.Name);
        Assert.areEqual(acntSalesArea.get(1).Price_Group__c,agreement2.Price_group__c,'insert failed');
        Test.stoptest();
    }

    @isTest
    static void testPriceGroupOnUpdate()
    {
        Apttus__APTS_Agreement__c oAgreement = getAgreementByName(AGREEMENT_NO_PRICE_GROUP);
        //oAgreement.Customer_Discount_Level__c = 'Price Group';
        oAgreement.Sales_org__c=AU01; //DCP-33757// adding reference sale org

        Update oAgreement;

        List<Account_Sales_Area__c> acntSalesArea = [Select Id, Price_Group__c from Account_Sales_Area__c LIMIT 2];

        Assert.areEqual(acntSalesArea.get(1).Price_Group__c,oAgreement.Price_group__c,'update failed');
    }

    /*
    Added By Saswati
    */
    @isTest
    static void testsetApprovalOnUpdate()
    {
        Apttus__APTS_Agreement__c oAgreement = getAgreementByName(AGRMNT_NAME_PRI_GRP);

        List<Apttus__AgreementLineItem__c> linesBefore = [SELECT Id, Apttus_Approval__Approval_Status__c 
            FROM Apttus__AgreementLineItem__c 
            WHERE Apttus__AgreementId__c = :oAgreement.Id
        ];

        for (Apttus__AgreementLineItem__c l : linesBefore) {
            Assert.areEqual(ApttusAgreements.APPROVAL_STATUS_APPROVAL_REQUIRED, l.Apttus_Approval__Approval_Status__c);
        }

        Test.startTest();
        {
            oAgreement.Apttus__Auto_Renewal__c = false;
            oAgreement.Value_Added_Distributor__c = true;
            oAgreement.Apttus_Approval__Approval_Status__c = ApttusAgreements.APPROVAL_STATUS_APPROVED;
            update oAgreement;
            
            Apttus__APTS_Agreement__c oAgreement2 = getAgreementByName(AGREEMENT_NO_PRICE_GROUP);
            oAgreement2.Apttus__Contract_End_Date__c = System.today() + 800;
            update oAgreement2;

                 
            Apttus__APTS_Agreement__c oAgreement3 = getAgreementByName(AGREEMENT_NO_SALES);
            oAgreement3.Sales_Org__c = '';
            update oAgreement3;

            ApttusAgreements.getCurrencyPrecision('JPY');
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        List<Apttus__AgreementLineItem__c> linesAfter = [SELECT Id, Apttus_Approval__Approval_Status__c FROM Apttus__AgreementLineItem__c WHERE Name = :AGRMNT_NAME_PRI_GRP];
        for (Apttus__AgreementLineItem__c l : linesAfter) {
            Assert.areEqual(ApttusAgreements.APPROVAL_STATUS_APPROVED, l.Apttus_Approval__Approval_Status__c);
        }
    }

    /*
    Added By Roopal
    */
    @isTest
    static void testSendEmailSetupOnUpdate(){
        Apttus__APTS_Agreement__c oAgreement = getAgreementByName(AGRMNT_NAME_PRI_GRP);
        oAgreement.Apttus_Approval__Approval_Status__c = 'Pending Approval';
        update oAgreement;
        System.debug('oAgreement ==>' + oAgreement);

        Apttus_Approval__Approval_Request__c objAppReq = new Apttus_Approval__Approval_Request__c(
            Apttus_Approval__Related_Agreement__c = oAgreement.id
        );
        insert objAppReq;
        System.debug('objAppReq ==>'+ objAppReq.Apttus_Approval__Related_Agreement__c);

        Test.startTest();
        oAgreement.Apttus_Approval__Approval_Status__c = 'Approved';
        update oAgreement;
        Test.stopTest();

        Assert.areEqual('Approved',oAgreement.Apttus_Approval__Approval_Status__c);
    }

/*
    @author: Tapas
    @Story : INC0293002  
*/
    private static testmethod void testresetStatusOfClonedAgreements(){
        Apttus__APTS_Agreement__c oAgreement = [SELECT Id, Name, Apttus__Account__c, 
            Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, Sales_Org__c,
            RecordTypeId,Apttus__Status__c, Apttus__Status_Category__c 
            FROM Apttus__APTS_Agreement__c 
            WHERE Apttus__Status__c = 'Activated' AND Apttus__Status_Category__c = 'In Effect'
        ];

        Test.startTest();
        Apttus__APTS_Agreement__c objAgmtClone = oAgreement.clone();
        System.debug('objAgmtClone is '+objAgmtClone); 
        insert objAgmtClone;
        Test.stopTest();
        Apttus__APTS_Agreement__c res = [SELECT id,Apttus__Status__c,Apttus__Status_Category__c,Validation_Status__c 
            FROM Apttus__APTS_Agreement__c 
            WHERE id = :objAgmtClone.Id
        ];
        System.debug('testresetStatusOfClonedAgreements :' + JSON.serializePretty(res));
        Assert.areEqual(Label.AgreementStatusRequest, res.Apttus__Status__c);
    }
    
    /* @author - Rishab Wali
       @Description - DCP-43224 Account update on Agreement.
    */
    private static testmethod void testAfterUpdateAccountUpdate()
    {
        Apttus__APTS_Agreement__c oAgreement = getAgreementByName(AGREEMENT_ONE_TIME);
        Account accNew = getAccountByName(ERP_234567);
        oAgreement.Apttus__Account__c = accNew.Id;
        update oAgreement;
        Assert.areEqual(accNew.Id,oAgreement.Apttus__Account__c);
    }

    /* @author - Roopal Verma
       @Description - DCP-37652 
    */
    @isTest
    static void testEditableFieldsOnActiveAgreement()
    {
        List<PermissionSetAssignment> lstAgrManager = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'SL_Apttus_Agreement_Manager'];
        Set<Id> setUserId = UtilsCollection.getSetOfIds(lstAgrManager,'AssigneeId');
        List<User> lstUser = [Select Id From User where Id =: setUserId AND IsActive = true AND Profile.Name = 'Sales User'];
        User agrManager = lstUser[0];
        
        Apttus__APTS_Agreement__c oAgreement4 = [SELECT Id,Apttus__Status_Category__c,Apttus__Status__c,Name From Apttus__APTS_Agreement__c where Apttus__Status__c = 'Activated' and Apttus__Status_Category__c = 'In Effect' ];
        oAgreement4.Apttus__Status__c = 'Request';
        oAgreement4.ownerId = agrManager.Id;
        update oAgreement4;
        System.runAs(agrManager){
        TestDataAgreement.addHierarchyPermission();
        oAgreement4.Apttus__Status_Category__c = 'In Effect';
        update oAgreement4;
        oAgreement4.Name = 'New Name';
        Test.startTest();
        update oAgreement4;
        Test.stopTest();
        }
        Apttus__APTS_Agreement__c oAgreementUpd = [Select Id,Name
                                                       FROM Apttus__APTS_Agreement__c
                                                       Where Id= :oAgreement4.id];
        Assert.areEqual(oAgreementUpd.Name,oAgreement4.Name);
    }

    /*
    @Author : Bharath Varma
    @Description : DCP-47006
    */
    @isTest
    static void testUCMaterialRollUp() {
        Apttus__APTS_Agreement__c oAgreement8 = getAgreementByName(AGREEMENT_UC_DISCOUNT);
        Test.startTest();

        List<Apttus__AgreementLineItem__c> lstAgreementLineItems = new List<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c oAgreementLI1 = TestDataAgreement.initAgreementsLineItem(oAgreement8.id);
        oAgreementLI1.Material_Group_1__c = 'BGS';
        oAgreementLI1.Line_Type__c = 'UC - Material Group 1';
        oAgreementLI1.Apttus_CMConfig__LineNumber__c = 0;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c = 0;
        oAgreementLI1.Discount_Type__c = '% Discount';
        oAgreementLI1.Discount__c = 1;
        oAgreementLI1.Customer_ERP_Number__c = ERP_123456;
        oAgreementLI1.Ultimate_Consignee_ERP_Number__c = ERP_123456;
        oAgreementLI1.Partner_Role__c = 'Z3';
        oAgreementLI1.Sales_Org__c = HK01;
        oAgreementLI1.Distribution_Channel__c = '02';
        oAgreementLI1.CurrencyIsoCode= USD;
        oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today()+1;
        oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+2;
        lstAgreementLineItems.add(oAgreementLI1);

        Apttus__AgreementLineItem__c oAgreementLI2 = TestDataAgreement.initAgreementsLineItem(oAgreement8.id);
        oAgreementLI2.Material_Number__c = VC0013519_OPA;
        oAgreementLI2.Material_Group_1__c = 'BGS';
        oAgreementLI2.Line_Type__c = 'UC - Material';
        oAgreementLI2.Apttus_CMConfig__LineNumber__c = 0;
        oAgreementLI2.Apttus_CMConfig__ItemSequence__c = 0;
        oAgreementLI2.Discount_Type__c = '% Discount';
        oAgreementLI2.Discount__c = 1;
        oAgreementLI2.Customer_ERP_Number__c = ERP_123456;
        oAgreementLI2.Ultimate_Consignee_ERP_Number__c = ERP_123456;
        oAgreementLI2.Partner_Role__c = 'Z3';
        oAgreementLI2.Sales_Org__c = HK01;
        oAgreementLI2.Distribution_Channel__c = '02';
        oAgreementLI2.CurrencyIsoCode= USD;
        oAgreementLI2.Apttus_CMConfig__StartDate__c = system.today()+1;
        oAgreementLI2.Apttus_CMConfig__EndDate__c = system.today()+2;
        lstAgreementLineItems.add(oAgreementLI2);
        ApttusAgreementLineItems.isDiscountLinesFutureCalled = true;
        
        insert lstAgreementLineItems;
        Test.stopTest();

        Apttus__APTS_Agreement__c oAgreement = getAgreementByName(AGREEMENT_UC_DISCOUNT);
        Assert.isTrue(oAgreement.ALIs_with_UC_Material_Group__c > 0, 'UC - Material Group Line item is not counted');
    }
    
    @isTest
    static void testNonComplianceConditions()
    {
        Apttus__APTS_Agreement__c oAgreement7 = getAgreementByName(AGREEMENT_TENDER);

        Test.startTest();
        oAgreement7.Submission_Response_Deadline__c = System.today() - 1;
        update oAgreement7;

        oAgreement7.Tender_submitted_date__c = System.today();
        oAgreement7.Reason_for_Missing_24hr_Before_Deadline__c = 'Waiting for quote approvals';
        update oAgreement7;

        oAgreement7.Tenders_Status__c = 'Submitted';
        update oAgreement7;

        oAgreement7.TAMs_Deadline_to_Respond__c = System.today() - 5;
        update oAgreement7;
        Test.stopTest();

        List<Apttus__APTS_Agreement__c> oAgreementList = [SELECT Id, Name, Tender_submitted_date__c, Tenders_Status__c, TAMs_Deadline_to_Respond__c, Sales_Org__c, Total_contract_length_with_extension__c, Apttus__Subtype__c, Reason_for_Non_Compliance__c, Reason_for_Missing_24hr_Before_Deadline__c, Submission_Response_Deadline__c FROM Apttus__APTS_Agreement__c WHERE Record_Type__c = 'Tender'];

        for(Apttus__APTS_Agreement__c nonCompliantVar : oAgreementList) {
            if(nonCompliantVar.Name == AGREEMENT_TENDER)
                Assert.isTrue(String.isNotBlank(nonCompliantVar.Reason_for_Non_Compliance__c), 'Compliance errors are not returned');
            else if(nonCompliantVar.Name == 'Test Agreement - Non Compliant' && nonCompliantVar.Total_contract_length_with_extension__c == null)
                Assert.isTrue(String.isNotBlank(nonCompliantVar.Reason_for_Non_Compliance__c), 'Total contract length blank');
            else if(nonCompliantVar.Name == 'Test Agreement - Non Compliant' && nonCompliantVar.Date_awarded__c == null && nonCompliantVar.Tenders_Status__c == 'In Effect/Won')
                Assert.isTrue(String.isNotBlank(nonCompliantVar.Reason_for_Non_Compliance__c), 'Award date not specified');
       }

    }

    @isTest
    static void testStartDateInPast(){
        Account acc = getAccountByName(ERP_123456);
        Apttus__APTS_Agreement__c oAgreement = TestDataAgreement.initAgreements('Test Agreement - Start Date Validation', acc.id);
        oAgreement.Apttus__Contract_Start_Date__c = system.today()-5;
        oAgreement.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement.Sales_Org__c = HK01;//adding reference sales org
        oAgreement.RecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();

        Test.startTest();
        insert oAgreement;
        Test.stopTest();

        Apttus__APTS_Agreement__c oAgreementUpdated = [Select Id, Name, Apttus__Contract_Start_Date__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Start Date Validation' LIMIT 1];
        //Assert.areEqual(Date.today(), oAgreementUpdated.Apttus__Contract_Start_Date__c, 'StartDate did not get updated to today\'s date');
    }

    /*
    * Added by Rucha Dalvi
    */
    @isTest
    static void testCreateOOAgreementAffiliates() {
        Account primaryAcct = getAccountByName(PRIMARY_ACCOUNT);
        primaryAcct.National_Group_Number__c='6000022795';
        update primaryAcct;
        Account childAcct = TestDataAccount.getCustomerAccount();
        childAcct.ParentId = primaryAcct.Id;
        childAcct.National_Group_Number__c='6000022795';
        insert childAcct;

        Id recTypeOO = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Open Offer Agreement').getRecordTypeId();
        
        Test.startTest();
        Apttus__APTS_Agreement__c openOfferAgreement = new Apttus__APTS_Agreement__c();
        openOfferAgreement.Name = 'Test Agreement - Open Offer';
        openOfferAgreement.Apttus__Account__c  = primaryAcct.Id;
        openOfferAgreement.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreement.RecordTypeId = recTypeOO;
        openOfferAgreement.Apttus__Subtype__c ='Standard';
        openOfferAgreement.Discount_Justification__c = 'None';
        openOfferAgreement.Sales_Org__c = HK01;
        insert openOfferAgreement;
        Test.stopTest();
        
        List<Agreement_Account_Relationship__c> lstAgrAccRel = [Select Id from Agreement_Account_Relationship__c where Agreement__c =:openOfferAgreement.Id];
        Assert.isTrue(!lstAgrAccRel.isEmpty(),'Junction records = has Not Created');
    }    

    /**
     *  @author      : Nitin
     *  @description : method to cover catch block in ApttusPublishToContentRepository
     **/
    @isTest
    public static void coverCatchBlockApttusPublishToContentRepository(){
        try{
            ApttusPublishToContentRepository.catchException = true;
            ApttusPublishToContentRepository pd = new ApttusPublishToContentRepository(null, null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            Assert.isTrue(e!=null,'e is not empty');
        }
    }

    /**
     *  @author      : Vivek R
     *  @description : method to cover serializeInputs and restoreInputs in the AgreementLineStatusBatchUpdate class
     **/
    @isTest
    static void testJsonMthodsForLineStatusUpd(){
        
        Apttus__APTS_Agreement__c oAgreement = [SELECT Id,Apttus_Approval__Approval_Status__c From Apttus__APTS_Agreement__c WHERE Name =: AGRMNT_NAME_PRI_GRP];
        AgreementLineStatusBatchUpdate btch = new AgreementLineStatusBatchUpdate();
        btch = new AgreementLineStatusBatchUpdate(oAgreement.id, oAgreement.Apttus_Approval__Approval_Status__c);
        
        Test.startTest();
        String serializedInput = btch.serializeInputs();
        btch.restoreInputs(serializedInput);
        
        Test.stopTest();
        
        Assert.areEqual(100, btch.getDefaultBatchSize(), 'Default batch size matched');
        Assert.areEqual(btch.inputs.agreementId, oAgreement.id, 'Agreement ID matched after restoring inputs');
        Assert.areEqual(btch.inputs.agreementStatus, oAgreement.Apttus_Approval__Approval_Status__c, 'Agreement approval status matched after restoring inputs');
    }

    @isTest
    private static void updateClinicalTypeFromAccountDuringInsertAgreement() {
        Account distribuitorAccount = getAccountByName(ERP_123456);
        Account partnerAccount = getAccountByName(ERP_234567);

        Apttus__APTS_Agreement__c agreementRes1 = getAgreementByName(AGREEMENT_ONE_TIME);
        Apttus__APTS_Agreement__c agreementRes2 = getAgreementByName(AGREEMENT_NO_SALES);

        Assert.areEqual(distribuitorAccount.Clinical_Type__c, agreementRes1.Clinical_Type__c, 'Agreement.Name:'+ AGREEMENT_ONE_TIME + ' Clinical_Type__c should match with Account.Name:' + ERP_123456);
        Assert.areEqual(partnerAccount.Clinical_Type__c, agreementRes2.Clinical_Type__c, 'Agreement.Name:'+ AGREEMENT_NO_SALES + ' Clinical_Type__c should match with Account.Name:' + ERP_234567);

        Test.startTest();
        String agreementTestTitle = 'Agreement which overrides default';
        Apttus__APTS_Agreement__c agreementWithClinicalType = TestDataAgreement.initAgreements(agreementTestTitle, distribuitorAccount.id); //DCP-37705
        agreementWithClinicalType.Sales_Org__c = HK01;
        agreementWithClinicalType.RecordTypeId = REC_TYPE_CHANNEL_PARTNER;
        agreementWithClinicalType.Apttus__Subtype__c = 'One Time';
        agreementWithClinicalType.One_Time_Agreement_Products__c = 'test';
        agreementWithClinicalType.Ultimate_Consignee__c = distribuitorAccount.id;
        agreementWithClinicalType.Clinical_Type__c = 'Non Clinical';

        insert agreementWithClinicalType;
        Test.stopTest();

        Apttus__APTS_Agreement__c res = getAgreementByName(agreementTestTitle);

        Assert.areNotEqual(distribuitorAccount.Clinical_Type__c, res.Clinical_Type__c, 'Agreement.Name:'+ res.name + ' Clinical_Type__c should NOT match with Account.Name:' + ERP_234567);
    }

    /* @author - Vijay Masne
    @Story : TI-10949 & TI-10601
    @Description : TI- Agreement: Status & Status Category as Request.
                    TI- Agreement : Update Other Party Signed Date when fully signed.
    @Paramters : List of Agreements
    */
    @isTest
    private static void testUpdateAgreementStatus() {       
        List<Apttus__APTS_Agreement__c> agreements = new List<Apttus__APTS_Agreement__c>();
        Map<Id,Apttus__APTS_Agreement__c> mapObApttus=new Map <Id,Apttus__APTS_Agreement__c>();
          

        Account primaryAcct = getAccountByName(PRIMARY_ACCOUNT);
        agreements.add(new Apttus__APTS_Agreement__c(
            Apttus__Account__c = primaryAcct.Id,
            Name = 'Agreement 1',
            Apttus__Status_Category__c = 'Request',
            Apttus__Subtype__c = 'Standard',
            ApplicableTermsandConditions__c = 'RUO',
            Products__c ='Instruments',
            Applicable_Region_s__c = 'AMEA',
            Freight_Charge__c = 'Standard',
            Payment_Terms__c = '30',
            Apttus__Status__c = 'Request' // Should be updated to 'Request'
        ));
        
        agreements.add(new Apttus__APTS_Agreement__c(
            Apttus__Account__c = primaryAcct.Id,
            Name = 'Agreement 2',
            Apttus__Status_Category__c = 'Request',
            Apttus__Subtype__c = 'Standard',
            ApplicableTermsandConditions__c = 'RUO',
            Products__c ='Instruments',
            Applicable_Region_s__c = 'AMEA',
            Freight_Charge__c = 'Standard',
            Payment_Terms__c = '30',
            Apttus__Status__c = 'In Amendment' // Should not be updated
        ));
        
        agreements.add(new Apttus__APTS_Agreement__c(
            Apttus__Account__c = primaryAcct.Id,
            Name = 'Agreement 3',
            Apttus__Status_Category__c = 'Request',
            Apttus__Subtype__c = 'Standard',
            ApplicableTermsandConditions__c = 'RUO',
            Products__c ='Instruments',
            Applicable_Region_s__c = 'AMEA',
            Freight_Charge__c = 'Standard',
            Payment_Terms__c = '30',
            Apttus__Status__c = 'In Renewal' // Should not be updated
        ));

        agreements.add(new Apttus__APTS_Agreement__c(
            Apttus__Account__c = primaryAcct.Id,
            Name = 'Agreement 4',
            Apttus__Status_Category__c = 'In Signatures',
            Apttus__Subtype__c = 'Standard',
            ApplicableTermsandConditions__c = 'RUO',
            Products__c ='Instruments',
            Applicable_Region_s__c = 'AMEA',
            Freight_Charge__c = 'Standard',
            Payment_Terms__c = '30',
            Apttus__Status__c = 'Fully Signed',
            Apttus__Other_Party_Signed_Date__c = Date.today()
        ));
        
        insert agreements; // Insert test agreements
        for(Apttus__APTS_Agreement__c obj:agreements){
            mapObApttus.put(obj.id, obj);
        }

        // Retrieve inserted agreements
        List<Apttus__APTS_Agreement__c> lstAgreements = [
            SELECT Id, Apttus__Account__c ,Name , Apttus__Status_Category__c , Apttus__Subtype__c ,
            ApplicableTermsandConditions__c , Products__c ,Applicable_Region_s__c ,Freight_Charge__c ,
            Payment_Terms__c , Apttus__Status__c ,Apttus__Other_Party_Signed_Date__c
            FROM Apttus__APTS_Agreement__c
        ];
       Test.startTest();
       ApttusAgreements.updateAgreementStatus(lstAgreements, mapObApttus); // Call the method
       ApttusAgreements.updateOtherPartySignedDate(lstAgreements, mapObApttus); // Call the method
       Test.stopTest();
        
        // Query the updated agreements to validate the changes
        List<Apttus__APTS_Agreement__c> updatedAgreements = [
            SELECT Id, Apttus__Account__c ,Name , Apttus__Status_Category__c , Apttus__Subtype__c ,
            ApplicableTermsandConditions__c , Products__c ,Applicable_Region_s__c ,Freight_Charge__c ,
            Payment_Terms__c , Apttus__Status__c , Apttus__Other_Party_Signed_Date__c FROM Apttus__APTS_Agreement__c
        ];
        // Assert the expected outcomes
        for (Apttus__APTS_Agreement__c agreement : updatedAgreements) {
            if (agreement.Name == 'Agreement 1') {
                Assert.areEqual('Request', agreement.Apttus__Status__c, 'Agreement 1 status should be updated to Request');
                
            } else if (agreement.Name == 'Agreement 2') {
                Assert.areEqual('In Amendment', agreement.Apttus__Status__c, 'Agreement 2 status should remain unchanged');
            
            } else if (agreement.Name == 'Agreement 3') {
                Assert.areEqual('In Renewal', agreement.Apttus__Status__c, 'Agreement 3 status should remain unchanged');
                
            } else if (agreement.Name == 'Agreement 4') {
             Assert.areEqual('Fully Signed', agreement.Apttus__Status__c, 'Agreement 4 status should remain as Fully Signed');
             Assert.areEqual(Date.today(), agreement.Apttus__Other_Party_Signed_Date__c, 'Agreement 4 Other_Party_Signed_Date__c should be set to today');
          }
        }
    }
    /* @author - Rajbabu Boopalan
    @Story : CMCM-12243
    @Description : [CLM] [Channel Partner] Automation of VAD Designation
    @Paramters : none
    */
    @isTest
    private static void setVADFlagBasedOnAccountOnInsertAgreement() {
        Apttus__APTS_Agreement__c cpAgreement = [SELECT Id,Value_Added_Distributor__c From Apttus__APTS_Agreement__c WHERE Name =: AGRMNT_NAME_PRI_GRP];
        Assert.areEqual(true, cpAgreement.Value_Added_Distributor__c, 'cpAgreement Value_Added_Distributor__c should be checked when Account channel partner type is VAD');
    }
}
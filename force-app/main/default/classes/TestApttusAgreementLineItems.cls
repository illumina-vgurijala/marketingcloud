/**
*    @author Satya Swain
*    @date   2019-10-20
*    @description    DCP-31673 ApttusAgreementLineItems test class
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------
*      Developer                      Date                Description
*     Satya Swain                  20 Dec 2019            Initial Version
*     B Kamini                     14 Jan 2020            Modified the setup data
*     Kushagra Desai               15-Jan-2020            DCP-33377 : Condition type/Table update; before update
*     Saswati                      20th Jan 2020          DCP-31789
*     B Kamini                     20th Jan 2020          Added Product data setup and made changes as part of DCP-31442
*     Roopal Verma                 21st Jan 2020          DCP-32801 Added test method testSetAARRel
*     B Kamini                     8 Feb 2020             DCP-33776 Modified test method testSetAARRel1
*     B Kamini                     11 Feb 2020            DCP-33783: Added Custom setting Profile validation data setup
*     Saswati                      12 Feb 2020            DCP-32563 : Added Approval MAtrix Hierarchy
*     Satya Swain                  09 March 2020          DCP-34983 : Added Asserts in testSetAARRel1 and testSetAARRel2
*     Prabhsimran Singh            18 March 2020          DCP-32572 : Added test method testConditionAgreementLineItem
*     Satya Swain                  24-March-2020          DCP-36047: Added testDeletionUponAmendRenew for Renew/Amend functionality
*     Joshith K                    27-May-2020            INC0270711-Added new method testCalculateDiscount
*     Rahul Bishnoi                17-June-2020           TASK0486150- Delete Agreement Account relationships after Line is items is discontinued.
*     Rishab Wali                  18-June-2020           DCP-38285 - Updated method testCalculateDiscount for new logic.
*     Karthik Rayani               25-Sep-2020            DCP-40107 - Updated method testsetApprovals for new logic.
*     Joshith k                    26-Nov-2020            TASK0537090--testLineStatusUpdate
*     Rishab Wali                  25-Nov-2020            Code Coverage errors.
*     Nishan Shetty                17-Jan-2022            CodeScanFix- [Assert Argument Order]
*     Aman Tyagi                   12-Apr-2022            CodeScan Fixes
*     Arif,Dalali                  28-Nov-2022            POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    --------------------------------------------------------------------------------------------------------------------------
**/
@isTest(SeeAllData=false isParallel=false)
public with sharing class TestApttusAgreementLineItems{

    public static FINAL string VC0013519_OPA = 'VC0013519-OPA';
    public static FINAL string SV_111_3001 = 'SV-111-3001';
    public static FINAL string AMEA_USD = '01-AMEA-USD'; //POL-57
    public static FINAL string PERDISCOUNT = '% Discount';
    public static FINAL string MATERIALGROUP = 'Material Group 1';
    public static FINAL string PRICEGROUP = 'Price Group - Material';
    public static FINAL string FIXEDDISCOUNT = 'Fixed Price';
    public static FINAL string DEBUG_SOQLCHECK = 'Total Number of SOQL Queries allowed in this apex code context: ';
    public static FINAL string DEBUG_SOQLIMIT = 'Number of Queries used in this apex code so far:';
    public static FINAL string DISCAMT = 'Discount Amount';
    public static FINAL string MATGRPAIP = 'AIP';
    //Code scan fixes
    public static FINAL string SGD_USD = '06-SGD-USD';
    public static FINAL string TXDR = 'TXDR';
    public static final String TEST_AGREEMENT_CUSTOMER = 'Test Agreement - Customer';
    public static final String TEST_AGREEMENT_CUSTOMER_HEIRARCHY = 'Test Agreement - Customer Hierarchy';

    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.initAccount();
         acc.Country_Local__c ='Japan';
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };


        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = VC0013519_OPA ;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        Product2 productFour = TestDataMaster.createProduct(false);
        productFour.Old_Material_Number__c = SV_111_3001;

        insert new List<Product2> { product, productTwo, productThree, productFour };

        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = SGD_USD;
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = TXDR;
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = AMEA_USD; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        
		Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '178', '00', false);
        acc3SalesArea.Account__c = acc.Id;
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = SGD_USD;
        acc3SalesArea.Contract_Number__c = '123456_HK010200';
        acc3SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010200';
        acc3SalesArea.Price_Group__c = TXDR;

        Account_Sales_Area__c acc4SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '178', '00', false);
        acc4SalesArea.Account__c = acc2.Id;
        acc4SalesArea.Price_List_Type__c = '06';
        acc4SalesArea.CurrencyIsoCode = 'USD';
        acc4SalesArea.Price_List__c = SGD_USD;
        acc4SalesArea.Contract_Number__c = '234567_HK010200';
        acc4SalesArea.ERP_Account_Sales_Area_Id__c = '234567_HK010200';
        acc4SalesArea.Price_Group__c = TXDR;
        
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea, acc3SalesArea, acc4SalesArea };

        System.debug(DEBUG_SOQLCHECK +' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());


        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements(TEST_AGREEMENT_CUSTOMER, acc.id);
        //oAgreement1.Customer_Discount_Level__c = 'Customer';
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Apttus__Subtype__c = 'Non-Standard';
        oAgreement1.Additional_Output_Language__c = 'Japanese';
        oAgreement1.Incoterm__c = 'EXW: Ex Works';
        oAgreement1.Exclusivity__c  = true;

        Id recTypeId2 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Customer Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc2.id);
        oAgreement2.RecordTypeId = recTypeId2;
        //oAgreement2.Customer_Discount_Level__c = 'Price Group';


        Apttus__APTS_Agreement__c oAgreement3 = TestDataAgreement.initAgreements(TEST_AGREEMENT_CUSTOMER_HEIRARCHY, acc.id);
        //oAgreement3.Customer_Discount_Level__c = 'Customer';
        oAgreement3.RecordTypeId = recTypeId;

        Apttus__APTS_Agreement__c oAgreement4 = TestDataAgreement.initAgreements('Test Agreement - Approvals', acc.id);
        oAgreement4.RecordTypeId = recTypeId;
        //oAgreement4.Customer_Discount_Level__c = 'Customer';

        insert new List<Apttus__APTS_Agreement__c>{oAgreement1,oAgreement2,oAgreement3,oAgreement4};

        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());



         List<Approval_Hierarchy__c> lstApprovalHierarchy = new List<Approval_Hierarchy__c>();  // 40115
         Approval_Hierarchy__c objRecordOwnerApprovalHierarchy = TestDataAgreement.initApprovalHierarchyStandingDiscount('CLM_Sales_Hierarchy', acc.OwnerId);
         lstApprovalHierarchy.add(objRecordOwnerApprovalHierarchy);
         Approval_Hierarchy__c objCustomApprovalHierarchy = TestDataAgreement.initApprovalHierarchy('CLM_Custom_Hierarchy');
         lstApprovalHierarchy.add(objCustomApprovalHierarchy);
         insert lstApprovalHierarchy;


        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());


        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(AMEA_USD); //POL-57
        Apttus_Config2__PriceList__c objPriceList2 = TestDataAgreement.initPriceList(SGD_USD);
        insert new List<Apttus_Config2__PriceList__c>{objPriceList, objPriceList2};
        
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(product, objPriceList);
        Apttus_Config2__PriceListItem__c objPriceListItem2 = TestDataAgreement.initPriceListItem(product, objPriceList2);
        Apttus_Config2__PriceListItem__c objPriceListItem3 = TestDataAgreement.initPriceListItem(productTwo, objPriceList2);
        Apttus_Config2__PriceListItem__c objPriceListItem4 = TestDataAgreement.initPriceListItem(productThree, objPriceList2);
        insert new List<Apttus_Config2__PriceListItem__c>{objPriceListItem, objPriceListItem2,objPriceListItem3,objPriceListItem4};

        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());


        //Custom Approval Matrix Data
        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();  // 40115
        Custom_Approval_Matrix__c standingDiscountApprovalMatrix = TestDataAgreement.initApprovalMatrixForAgreement('CLM Discount', 10 , null, null,objCustomApprovalHierarchy.id);
        lstMatrix.add(standingDiscountApprovalMatrix);
        Custom_Approval_Matrix__c standingDiscountApprovalMatrix1 = TestDataAgreement.initApprovalMatrixForAgreement('CLM Discount', 10 , null, null,objCustomApprovalHierarchy.id);
        lstMatrix.add(standingDiscountApprovalMatrix1);

        Custom_Approval_Matrix__c standingMaterialGroupApprovalMatrix = TestDataAgreement.initApprovalMatrixForAgreement('CLM Material Group 1', 10 , MATGRPAIP, null, objCustomApprovalHierarchy.id);
        lstMatrix.add(standingMaterialGroupApprovalMatrix);
        Custom_Approval_Matrix__c standingMaterialGroupApprovalMatrix2 = TestDataAgreement.initApprovalMatrixForAgreement('CLM Material Group 1', 10 , MATGRPAIP, null, objCustomApprovalHierarchy.id);
        lstMatrix.add(standingMaterialGroupApprovalMatrix2);

        Custom_Approval_Matrix__c standingMaterialNumberApprovalMatrix = TestDataAgreement.initApprovalMatrixForAgreement('CLM Material Number', 10 , null, product.id,objCustomApprovalHierarchy.id);
        lstMatrix.add(standingMaterialNumberApprovalMatrix);
        Custom_Approval_Matrix__c standingMaterialNumberApprovalMatrix3 = TestDataAgreement.initApprovalMatrixForAgreement('CLM Material Number', 20 , null, product.id,objCustomApprovalHierarchy.id);
        lstMatrix.add(standingMaterialNumberApprovalMatrix3);
        insert lstMatrix;

        //Custom Approval Matrx Product Data
        Custom_Approval_Matrix_Products__c campRecord = new Custom_Approval_Matrix_Products__c(
            Custom_Approval_Matrix__c = standingMaterialNumberApprovalMatrix.id,
            Product__c = product.id
        );

        insert campRecord;

        Custom_Approval_Matrix_Products__c campRecord1 = new Custom_Approval_Matrix_Products__c(
            Custom_Approval_Matrix__c = standingMaterialNumberApprovalMatrix.id,
            Product__c = productFour.id
        );
        insert campRecord1;
        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());
        Test.startTest();
        insertUserPermissionset();//future method to create user and assogn permission set.
        Test.stopTest();


    }
    @isTest
     static void testCheckConditionTypeAndTableOnInsertForCP(){
        Apttus__APTS_Agreement__c objAgreement1, objAgreement2;
        List<Apttus__APTS_Agreement__c> lstAgreement = [Select Id,Name from Apttus__APTS_Agreement__c];
        for(Apttus__APTS_Agreement__c objAgreement : lstAgreement ){
           if(objAgreement.Name.equals(TEST_AGREEMENT_CUSTOMER)){
                objAgreement1 = objAgreement;
            }else if(objAgreement.Name.equals(TEST_AGREEMENT_CUSTOMER_HEIRARCHY)){
                objAgreement2 = objAgreement;
            }
        }

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement1.Id);
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount__c = 5;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c='123456';
        objAgreementLineItem1.Sales_Org__c='HK01';
        objAgreementLineItem1.Distribution_Channel__c='02';
        objAgreementLineItem1.Discount__c = 15;
		objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Apttus__AgreementLineItem__c objAgreementLineItem3 = TestDataAgreement.initAgreementsLineItem(objAgreement1.Id);
        objAgreementLineItem3.Material_Number__c = '11234187';
        //cv objAgreementLineItem3.Material_Group_1__c = 'AIP';
        objAgreementLineItem3.Line_Type__c = 'Material';
        objAgreementLineItem3.Apttus_CMConfig__LineNumber__c = 3;
        objAgreementLineItem3.Apttus_CMConfig__ItemSequence__c = 3;
        objAgreementLineItem3.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem3.Customer_ERP_Number__c = '123456';
        objAgreementLineItem3.Sales_Org__c = 'HK01';
        objAgreementLineItem3.Distribution_Channel__c = '02';
        objAgreementLineItem3.CurrencyIsoCode= 'USD';
        objAgreementLineItem3.Discount__c = 15;
		objAgreementLineItem3.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem3.Apttus_CMConfig__EndDate__c=system.today()+2;

        Apttus__AgreementLineItem__c objAgreementLineItem4 = TestDataAgreement.initAgreementsLineItem(objAgreement2.Id);
        objAgreementLineItem4.Material_Number__c = '11234187';
        //cv objAgreementLineItem4.Material_Group_1__c = 'BGS';
        objAgreementLineItem4.Line_Type__c = 'Material';
        objAgreementLineItem4.Apttus_CMConfig__LineNumber__c = 4;
        objAgreementLineItem4.Apttus_CMConfig__ItemSequence__c = 4;
        objAgreementLineItem4.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem4.Customer_ERP_Number__c = '123456';
        objAgreementLineItem4.Sales_Org__c = 'HK01';
        objAgreementLineItem4.Distribution_Channel__c = '02';
        objAgreementLineItem4.CurrencyIsoCode= 'USD';
        objAgreementLineItem4.Discount__c = 15;
		objAgreementLineItem4.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem4.Apttus_CMConfig__EndDate__c=system.today()+2;

        Apttus__AgreementLineItem__c objAgreementLineItem5 = TestDataAgreement.initAgreementsLineItem(objAgreement2.Id);
        objAgreementLineItem5.Material_Number__c = '11234187';
        objAgreementLineItem5.Line_Type__c = 'Material';
        objAgreementLineItem5.Apttus_CMConfig__LineNumber__c = 5;
        objAgreementLineItem5.Apttus_CMConfig__ItemSequence__c = 5;
        objAgreementLineItem5.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem5.Customer_ERP_Number__c = '123456';
        objAgreementLineItem5.Sales_Org__c = 'HK01';
        objAgreementLineItem5.Distribution_Channel__c = '02';
        objAgreementLineItem5.CurrencyIsoCode= 'USD';
        objAgreementLineItem5.Discount__c = 15;
		objAgreementLineItem5.Discontinued__c = 'No';
        objAgreementLineItem5.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem5.Apttus_CMConfig__EndDate__c=system.today()+2;

        Test.startTest();
        insert new List<Apttus__AgreementLineItem__c >{objAgreementLineItem1,objAgreementLineItem3,objAgreementLineItem4,objAgreementLineItem5};

        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());

        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = [Select Id,Material_Number__c,Condition_Table__c,Condition_Type__c from Apttus__AgreementLineItem__c];
        for(Apttus__AgreementLineItem__c objAgreementLineItem : lstAgreementLineItem){
            if(objAgreementLineItem.Material_Number__c == '12345'){
                System.assertEquals('A305',objAgreementLineItem.Condition_Table__c);
                System.assertEquals('ZD01',objAgreementLineItem.Condition_Type__c);
            }
            else if(objAgreementLineItem.Material_Number__c == '123457'){
                System.assertEquals('A305',objAgreementLineItem.Condition_Table__c);
                System.assertEquals('ZD10',objAgreementLineItem.Condition_Type__c);
            }

        }
        Test.stopTest();



        }

    @isTest
    static void testCheckConditionTypeAndTableOnInsertForNonCP(){
        product2 product=[select id from product2 where Material_Number__c='11234187'];
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(SGD_USD);
        insert objPriceList;
        //06-SGD-USD
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(product, objPriceList);
        insert objPriceListItem ;
		Apttus__APTS_Agreement__c objAgreement = [Select Id from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group' LIMIT 1];

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '01';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
		objAgreementLineItem1.Discontinued__c = 'No';
        objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Test.startTest();
        insert objAgreementLineItem1;

        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());

        Test.stopTest();

        Apttus__AgreementLineItem__c objAgreementLineItem2 = [Select Id,Condition_Table__c,Condition_Type__c from Apttus__AgreementLineItem__c where Material_Number__c = '11234187' LIMIT 1];
        System.assertEquals('A305', objAgreementLineItem2.Condition_Table__c);
        System.assertEquals('ZD01', objAgreementLineItem2.Condition_Type__c);

    }

    @isTest
    static void testSetAARRel1()
    {
        Apttus__APTS_Agreement__c objAgreement = [Select Id FROM Apttus__APTS_Agreement__c WHERE Name = :TEST_AGREEMENT_CUSTOMER ];

        String[] accERP = new String[]{'123456', '23456'};

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '02';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
		objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c = VC0013519_OPA ;
        objAgreementLineItem2.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 2;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 2;
        objAgreementLineItem2.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem2.Customer_ERP_Number__c = '234567';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '02';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
		objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;

        Apttus__AgreementLineItem__c objAgreementLineItem3 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        //objAgreementLineItem3.Material_Number__c = VC0013519_OPA;
        objAgreementLineItem3.Material_Group_1__c = MATGRPAIP;
		objAgreementLineItem3.Line_Type__c = MATERIALGROUP;
        objAgreementLineItem3.Customer_ERP_Number__c = '234567';
        objAgreementLineItem3.Apttus_CMConfig__LineNumber__c = 2;
        objAgreementLineItem3.Apttus_CMConfig__ItemSequence__c = 2;
        objAgreementLineItem3.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem3.Sales_Org__c = 'HK01';
        objAgreementLineItem3.Price_Group__c = TXDR;
        objAgreementLineItem3.Distribution_Channel__c = '02';
        objAgreementLineItem3.CurrencyIsoCode= 'USD';
        objAgreementLineItem3.Discount__c = 15;
		objAgreementLineItem3.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem3.Apttus_CMConfig__EndDate__c=system.today()+2;


        insert new List<Apttus__AgreementLineItem__c >{objAgreementLineItem1,objAgreementLineItem2,objAgreementLineItem3};
        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = [Select Id, Account__c,Customer_ERP_Number__c from Apttus__AgreementLineItem__c];

        System.debug(DEBUG_SOQLCHECK +' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());

        //Added by Satya for DCP-34983
        Map<String,String> erpIdToAccountId = new Map<String,String>();
        for(Account acc : [Select Id,ERP_Customer_Id__c from Account])
        {
            if(!erpIdToAccountId.containsKey(acc.ERP_Customer_Id__c))
                erpIdToAccountId.put(acc.ERP_Customer_Id__c, acc.Id);
        }
        for(Apttus__AgreementLineItem__c objAgrLineItem : lstAgreementLineItem)
        {
            if(erpIdToAccountId.containsKey(objAgrLineItem.Customer_ERP_Number__c)){
                System.assertEquals(erpIdToAccountId.get(objAgrLineItem.Customer_ERP_Number__c),objAgrLineItem.Account__c);
            }
        }
        Test.startTest();
        List<Agreement_Account_Relationship__c> lstAARInserted = [SELECT Id, Account__c, Agreement__c FROM Agreement_Account_Relationship__c];
        system.debug('lstAARInserted--'+lstAARInserted);
        //system.assertEquals(2,lstAARInserted.size(),'Agreement Account Relationship records not created');


        Apttus__AgreementLineItem__c objUpdAgreementLineItem = [Select Id,Customer_ERP_Number__c from Apttus__AgreementLineItem__c where Material_Number__c = '11234187' LIMIT 1];
        objUpdAgreementLineItem.Customer_ERP_Number__c = '234567';
        update objUpdAgreementLineItem;

        Apttus__AgreementLineItem__c objUpdAgreementLineItem1 = [Select Id,Customer_ERP_Number__c,Price_Group__c,Sales_Org__c from Apttus__AgreementLineItem__c where Price_Group__c = 'TXDR' AND Sales_Org__c = 'HK01'  LIMIT 1];
        objUpdAgreementLineItem1.Sales_Org__c = 'US01';
		objUpdAgreementLineItem1.Material_Number__c = ''; 
        update objUpdAgreementLineItem1;

        System.debug(DEBUG_SOQLCHECK+'  ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());


        Test.stopTest();
    }

     @isTest
    static void testSetAARRel2(){

        Apttus__APTS_Agreement__c objAgreement = [Select Id FROM Apttus__APTS_Agreement__c WHERE Name = :TEST_AGREEMENT_CUSTOMER ];

        String[] accERP = new String[]{'123456', '23456'};

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '02';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
		objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c = VC0013519_OPA ;
        objAgreementLineItem2.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 2;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 2;
        objAgreementLineItem2.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem2.Customer_ERP_Number__c = '234567';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '02';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
		objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;

        insert new List<Apttus__AgreementLineItem__c >{objAgreementLineItem1,objAgreementLineItem2};

        System.debug(DEBUG_SOQLCHECK+'  ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());

        Test.startTest();

        List<Agreement_Account_Relationship__c> lstAARInserted = [SELECT Id, Account__c, Agreement__c,Account_Default_Sales_Org__c,Company_Name__c FROM Agreement_Account_Relationship__c];
        system.debug('lstAARInserted--'+lstAARInserted);
        //system.assertEquals(2,lstAARInserted.size(),'Agreement Account Relationship records not created');

        //Asserts below added by Satya as part of DCP-34983
        System.assertEquals('HK01',lstAARInserted.get(0).Account_Default_Sales_Org__c);
        System.assertEquals('HK01', lstAARInserted.get(1).Account_Default_Sales_Org__c);
        System.assertEquals('Illumina Hong Kong Limited', lstAARInserted.get(0).Company_Name__c);
        System.assertEquals('Illumina Hong Kong Limited', lstAARInserted.get(1).Company_Name__c);

        Apttus__AgreementLineItem__c objUpdAgreementLineItem2 = [Select Id,Customer_ERP_Number__c from Apttus__AgreementLineItem__c where Material_Number__c = '11234187' LIMIT 1];
        objUpdAgreementLineItem2.Customer_ERP_Number__c = '123456';
        update objUpdAgreementLineItem2;
        delete objUpdAgreementLineItem2;

        List<Agreement_Account_Relationship__c> lstAARUpdated2 = [SELECT Id, Account__c, Agreement__c FROM Agreement_Account_Relationship__c];

        //system.assertEquals(1,lstAARUpdated2.size(),'Agreement Account Relationship records not deleted');
        //Added by Satya for DCP-34983
        lstAARUpdated2.get(0).Account_Default_Sales_Org__c = null;
        update lstAARUpdated2;
        List<Agreement_Account_Relationship__c> lstAARUpdated3 = [Select Id,Account_Default_Sales_Org__c from Agreement_Account_Relationship__c ];
        System.assertEquals('HK01', lstAARUpdated3.get(0).Account_Default_Sales_Org__c);

        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());



        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());


        Test.stopTest();
    }


     @isTest
    static void testsetApprovals(){
        Apttus__APTS_Agreement__c objAgreement = [Select Id FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Approvals' ];
        System.debug('### Agreement Created? ' + objAgreement );
        List<Apttus__AgreementLineItem__c> lstALI = new List<Apttus__AgreementLineItem__c>();

       Apttus__AgreementLineItem__c objAgreementLineItem = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem.Material_Number__c = VC0013519_OPA;
        objAgreementLineItem.Line_Type__c = MATERIALGROUP;
        objAgreementLineItem.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem.Discount__c = 15;
        objAgreementLineItem.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem.Customer_ERP_Number__c = '123456';
        objAgreementLineItem.Sales_Org__c = 'HK01';
        objAgreementLineItem.Distribution_Channel__c = '02';
        objAgreementLineItem.CurrencyIsoCode = 'USD';
        objAgreementLineItem.Apttus_CMConfig__StartDate__c = System.today()+1;
		objAgreementLineItem.Apttus_CMConfig__EndDate__c=system.today()+2;
        lstALI.add(objAgreementLineItem);

         Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c = VC0013519_OPA;
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem2.Discount__c = 30;
        objAgreementLineItem2.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem2.Customer_ERP_Number__c = '123456';
        objAgreementLineItem2.Distribution_Channel__c = '02';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.CurrencyIsoCode = 'USD';
        objAgreementLineItem2.Apttus_CMConfig__StartDate__c = System.today()+1;
		objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;
        lstALI.add(objAgreementLineItem2);

         Apttus__AgreementLineItem__c objAgreementLineItem3 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem3.Material_Number__c = VC0013519_OPA;
        objAgreementLineItem3.Line_Type__c = 'Material';
        objAgreementLineItem3.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem3.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem3.Discount__c = 30;
        objAgreementLineItem3.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem3.Customer_ERP_Number__c = '123456';
        objAgreementLineItem3.Distribution_Channel__c = '02';
        objAgreementLineItem3.Sales_Org__c = 'HK01';
        objAgreementLineItem3.CurrencyIsoCode = 'USD';
        objAgreementLineItem3.Apttus_CMConfig__StartDate__c = System.today()+1;
		objAgreementLineItem3.Apttus_CMConfig__EndDate__c=system.today()+2;
        lstALI.add(objAgreementLineItem3);

        /*Apttus__AgreementLineItem__c objAgreementLineItem4 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem4.Material_Number__c = VC0013519_OPA;
        objAgreementLineItem4.Line_Type__c = MATERIALGROUP;
        //cv objAgreementLineItem4.Material_Group_1__c = 'AIR';
        objAgreementLineItem4.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem4.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem4.Discount__c = 15;
        objAgreementLineItem4.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem4.Customer_ERP_Number__c = '123456';
        objAgreementLineItem4.Sales_Org__c = 'HK01';
        objAgreementLineItem4.Distribution_Channel__c = '01';
        objAgreementLineItem4.CurrencyIsoCode = 'USD';
        objAgreementLineItem4.Apttus_CMConfig__StartDate__c = System.today()+1;
        lstALI.add(objAgreementLineItem4); */
    
        Apttus__AgreementLineItem__c objAgreementLineItem5 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem5.Material_Number__c = VC0013519_OPA;
        objAgreementLineItem5.Line_Type__c = 'Material';
        objAgreementLineItem5.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem5.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem5.Discount__c = 30;
        objAgreementLineItem5.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem5.Customer_ERP_Number__c = '123456';
        objAgreementLineItem5.Distribution_Channel__c = '02';
        objAgreementLineItem5.Sales_Org__c = 'HK01';
        objAgreementLineItem5.CurrencyIsoCode = 'USD';
        objAgreementLineItem5.Apttus_CMConfig__StartDate__c = System.today()+1;
		objAgreementLineItem5.Apttus_CMConfig__EndDate__c=system.today()+2;
        lstALI.add(objAgreementLineItem5);
        
        Test.startTest();
        insert lstALI;
    
        List<Apttus__AgreementLineItem__c> lstUpdALI = [Select Id, Approval_Category__c, Approval_Level_Discount__c,Approval_Level_Material_Group__c,Approval_Level_Material_Number__c,Approval_Hierarchy_Discount__c,Approval_Hierarchy_Material_Group__c,Approval_Hierarchy_Material_Number__c,Approval_Hierarchy_Record_Owner__c,Approval_Level_RO_Discount__c,Apttus_Approval__Approval_Status__c From Apttus__AgreementLineItem__c where  Apttus__AgreementId__c = :objAgreement.id];
        System.debug('$$ lstUpdALI'+ lstUpdALI);
        System.debug(DEBUG_SOQLCHECK+' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());
        
        objAgreementLineItem5.Line_Type_1__c ='Material';  
        update objAgreementLineItem5;
      
        if(lstALI.get(0).Approval_Category__c != null){
             system.assert(lstALI.get(0).Approval_Category__c.contains('Discount'),'Standing discount approvals did not fire.');
             system.assert(lstALI.get(1).Approval_Category__c.contains('Material_Group'),' Standing Material Group approvals did not fire.');
        }
        if(lstALI.get(2).Approval_Category__c != null){

             system.assert(lstALI.get(2).Approval_Category__c.contains('Material_Number'),'Standing Material Number approvals did not fire.');
        }

        Test.stopTest();



    }
    /**
    *  @author Rahul Bishnoi
    *  @description TASK0486150- Delete Agreement Account relationships after Line is items is discontinued.
    *  @return void
    **/
    @isTest
    static void testdeleteAgreementAccountRelationship(){
        Apttus__APTS_Agreement__c objAgreement = [Select Id FROM Apttus__APTS_Agreement__c WHERE Name = :TEST_AGREEMENT_CUSTOMER ];

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem1.Line_Type__c = MATERIALGROUP;
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '02';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
		objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c = '11234187';
        objAgreementLineItem2.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem2.Line_Type__c = MATERIALGROUP;
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem2.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem2.Customer_ERP_Number__c = '123456';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '02';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
		objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;

        insert new List<Apttus__AgreementLineItem__c >{objAgreementLineItem1,objAgreementLineItem2};

        test.startTest();
        List<Agreement_Account_Relationship__c> lstAAR = [SELECT id FROM Agreement_Account_Relationship__c where Agreement__c = :objAgreement.id];
        System.assertEquals(1, lstAAR.size());
        objAgreementLineItem1.Discontinued__c = 'Yes';
        Update objAgreementLineItem1;

        lstAAR = [SELECT id FROM Agreement_Account_Relationship__c where Agreement__c = :objAgreement.id];
        System.assertEquals(1, lstAAR.size());
        test.stopTest();
    }

     @isTest
    static void testConditionAgreementLineItem(){

        Apttus__APTS_Agreement__c objAgreement = [Select Id FROM Apttus__APTS_Agreement__c WHERE Name = :TEST_AGREEMENT_CUSTOMER ];

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem1.Line_Type__c = MATERIALGROUP;
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '02';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
		objAgreementLineItem1.Discontinued__c = 'No';
        objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;
        
        insert new List<Apttus__AgreementLineItem__c >{objAgreementLineItem1};
		
		
		Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c = '11234187';
        objAgreementLineItem2.Material_Group_1__c = 'AIM';
        objAgreementLineItem2.Line_Type__c = MATERIALGROUP;
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem2.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem2.Customer_ERP_Number__c = '123456';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '02';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
		objAgreementLineItem2.Discontinued__c = 'No';
        objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;
		objAgreementLineItem2.Apttus_CMConfig__LineStatus__c = 'New';
		objAgreementLineItem2.Apttus_Approval__Approval_Status__c = 'Approval Required';
        objAgreementLineItem2.Priority__c = 25;
		
        Apttus__AgreementLineItem__c objAgreementLineItem3 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem3.Material_Number__c = '11234187';
        objAgreementLineItem3.Material_Group_1__c = 'AIM';
        objAgreementLineItem3.Line_Type__c = MATERIALGROUP;
        objAgreementLineItem3.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem3.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem3.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem3.Customer_ERP_Number__c = '123456';
        objAgreementLineItem3.Sales_Org__c = 'HK01';
        objAgreementLineItem3.Distribution_Channel__c = '02';
        objAgreementLineItem3.CurrencyIsoCode= 'USD';
        objAgreementLineItem3.Discount__c = 15;
		objAgreementLineItem3.Discontinued__c = 'No';
        objAgreementLineItem3.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem3.Apttus_CMConfig__EndDate__c=system.today()+2;
		objAgreementLineItem3.Apttus_CMConfig__LineStatus__c = 'New';
		objAgreementLineItem3.Apttus_Approval__Approval_Status__c = 'Rejected';
        objAgreementLineItem3.Priority__c = 25;
        
        Apttus__AgreementLineItem__c objAgreementLineItem4 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem4.Material_Number__c = '11234187';
        objAgreementLineItem4.Material_Group_1__c = 'AIM';
        objAgreementLineItem4.Line_Type__c = MATERIALGROUP;
        objAgreementLineItem4.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem4.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem4.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem4.Customer_ERP_Number__c = '123456';
        objAgreementLineItem4.Sales_Org__c = 'HK01';
        objAgreementLineItem4.Distribution_Channel__c = '02';
        objAgreementLineItem4.CurrencyIsoCode= 'USD';
        objAgreementLineItem4.Discount__c = 15;
		objAgreementLineItem4.Discontinued__c = 'No';
        objAgreementLineItem4.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem4.Apttus_CMConfig__EndDate__c=system.today()+2;
		objAgreementLineItem4.Apttus_CMConfig__LineStatus__c = 'New';
		objAgreementLineItem4.Apttus_Approval__Approval_Status__c = 'Cancelled';
        objAgreementLineItem4.Priority__c = 25;
		

        
        Test.startTest();

		insert new List<Apttus__AgreementLineItem__c >{objAgreementLineItem2,objAgreementLineItem3,objAgreementLineItem4};
        Apttus__AgreementLineItem__c objUpdAgreementLineItem2 = [Select Id,Material_Number__c,Customer_ERP_Number__c from Apttus__AgreementLineItem__c where Material_Number__c = '11234187' LIMIT 1];
        objUpdAgreementLineItem2.Material_Number__c = '';
		update objUpdAgreementLineItem2;
        
        System.assertEquals('123456', objUpdAgreementLineItem2.Customer_ERP_Number__c);
        
        Test.stopTest();
    }
    @isTest
    static void testDeletionUponAmendRenew()
    {
        Apttus__APTS_Agreement__c objAgreement = [Select Id FROM Apttus__APTS_Agreement__c WHERE Name =  :TEST_AGREEMENT_CUSTOMER ];

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem1.Line_Type__c = 'Material Group 1';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '02';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
        objAgreementLineItem1.Apttus_CMConfig__LineStatus__c = 'Existing';
        objAgreementLineItem1.Discontinued__c = 'No';

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c = VC0013519_OPA;
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 2;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 2;
        objAgreementLineItem2.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem2.Customer_ERP_Number__c = '234567';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '02';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
        objAgreementLineItem2.Apttus_CMConfig__LineStatus__c = 'Existing';
        objAgreementLineItem2.Discontinued__c = 'Yes';


        Test.startTest();
        insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem1,objAgreementLineItem2};
        Test.stopTest();

        List<Apttus__AgreementLineItem__c> lstALI = [Select Id,Discontinued__c from Apttus__AgreementLineItem__c];
        System.assertEquals(1, lstALI.size()); //indicating that one line item didn't get copied post renewal/amendment
        System.assertEquals('No', lstALI.get(0).Discontinued__c); // indicating that only 1 line item got copied where Discontinued = No
    }


    @isTest
    static void testCalculateDiscount()
    {
        product2 product=[select id from product2 where Material_Number__c='11234187'];
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(SGD_USD);
        insert objPriceList;
        //06-SGD-USD
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(product, objPriceList);
        insert objPriceListItem ;
        Apttus__APTS_Agreement__c objAgreement = [Select Id FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' ];

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c ='11234187';
        objAgreementLineItem1.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = FIXEDDISCOUNT ;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '01';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
        objAgreementLineItem1.Discontinued__c = 'No';
        objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        

        Apttus__AgreementLineItem__c objAgreementLineItem3 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem3.Material_Number__c ='11234187';
        objAgreementLineItem3.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem3.Line_Type__c = 'Material';
        objAgreementLineItem3.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem3.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem3.Discount_Type__c = PERDISCOUNT ;
        objAgreementLineItem3.Customer_ERP_Number__c = '123456';
        objAgreementLineItem3.Sales_Org__c = 'HK01';
        objAgreementLineItem3.Distribution_Channel__c = '01';
        objAgreementLineItem3.CurrencyIsoCode= 'USD';
        objAgreementLineItem3.Discount__c = 2;
        objAgreementLineItem3.Discontinued__c = 'No';
        objAgreementLineItem3.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem3.Apttus_CMConfig__EndDate__c=system.today()+2;

        

        Apttus__AgreementLineItem__c objAgreementLineItem5 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem5.Material_Number__c ='11234187';
        objAgreementLineItem5.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem5.Line_Type__c = 'Material';
        objAgreementLineItem5.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem5.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem5.Discount_Type__c = DISCAMT;
        objAgreementLineItem5.Customer_ERP_Number__c = '123456';
        objAgreementLineItem5.Sales_Org__c = 'HK01';
        objAgreementLineItem5.Distribution_Channel__c = '01';
        objAgreementLineItem5.CurrencyIsoCode= 'USD';
        objAgreementLineItem5.Discount__c = 2;
        objAgreementLineItem5.Discontinued__c = 'No';
        objAgreementLineItem5.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem5.Apttus_CMConfig__EndDate__c=system.today()+2;

        Test.startTest();
        insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem1,objAgreementLineItem3,objAgreementLineItem5};
        Test.stopTest();

        List<Apttus__AgreementLineItem__c> lstALI = [Select Id,Discount_In_Percent__c from Apttus__AgreementLineItem__c where Material_Number__c='11234187'  ];
        boolean discountPercentFound=(lstALI[0].Discount_In_Percent__c!=null)?true:false;
        System.assertEquals(true, discountPercentFound); //indicating that one line item have discount in percent populated
        
    }   

    @isTest
    static void testNoCAM()
    {  
        List<Custom_Approval_Matrix__c> lstCAM = [SELECT Id From Custom_Approval_Matrix__c];
        delete lstCAM;

        List<Approval_Hierarchy__c> lstAppHierarchy = [SELECT id from Approval_Hierarchy__c];
        delete lstAppHierarchy;

        product2 product=[select id from product2 where Material_Number__c='11234187'];
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(SGD_USD);
        insert objPriceList;
        //06-SGD-USD
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(product, objPriceList);
        insert objPriceListItem ;
        Apttus__APTS_Agreement__c objAgreement = [Select Id,Submit_For_Approval__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' ];

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c ='11234187';
        objAgreementLineItem1.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = FIXEDDISCOUNT ;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '01';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
        objAgreementLineItem1.Discontinued__c = 'No';
        objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Test.startTest();
        insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem1};
        
        Test.stopTest();
        Apttus__APTS_Agreement__c objAgreementupd = [Select Id FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' ];
        system.debug('objAgreementupd'+objAgreementupd);
        Apttus__AgreementLineItem__c objAgrUpd = [Select Id, Approval_Category__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :objAgreement.Id];
        system.assertEquals(null, objAgrUpd.Approval_Category__c);
    }

    @isTest
    static void testMaterialNumber()
    { 
        Product2 prod = [Select Id From Product2 Where Material_Number__c = '11234187'];
        Custom_Approval_Matrix__c standingMaterialNumberApprovalMatrix = [Select Id from Custom_Approval_Matrix__c where Name = 'CLM Material Number Approval Matrix' LIMIT 1];
        Custom_Approval_Matrix_Products__c campRecord1 = new Custom_Approval_Matrix_Products__c(
            Custom_Approval_Matrix__c = standingMaterialNumberApprovalMatrix.id,
            Product__c = prod.id
        );
        insert campRecord1;
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(SGD_USD);
        insert objPriceList;
        //06-SGD-USD
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(prod, objPriceList);
        insert objPriceListItem ;
        Apttus__APTS_Agreement__c objAgreement = [Select Id,Submit_For_Approval__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' ];

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c ='11234187';
        objAgreementLineItem2.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem2.Discount_Type__c = FIXEDDISCOUNT ;
        objAgreementLineItem2.Customer_ERP_Number__c = '123456';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '01';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
        objAgreementLineItem2.Discontinued__c = 'No';
        objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;
        Test.startTest();
        insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem2};
        
        Test.stopTest();
        Apttus__AgreementLineItem__c objAgrUpd = [Select Id, Approval_Category__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :objAgreement.Id];
        system.assert(objAgrUpd.Approval_Category__c != null, 'Approvals did not fire');
    }

    @isTest
    static void testROApprovalsMaterialNumber()
    { 
        User objRepUser = TestDataUser.findUserInProfile('Sales User');

        Account acc = [Select Id,OwnerId From Account Where ERP_Customer_Id__c = '234567'];
        acc.OwnerId = objRepUser.Id;
        update acc;
        system.debug('%& acc'+acc); 

        Product2 prod = [Select Id From Product2 Where Material_Number__c = '11234187'];
        Approval_Hierarchy__c appHierarchy = [SELECT id from Approval_Hierarchy__c where Approval_Hierarchy_Type__c = 'CLM_Sales_Hierarchy'];
        appHierarchy.Approver_Level_1__c = objRepUser.id;
        update appHierarchy;
        system.debug('%$ appHierarchy'+appHierarchy);

        Custom_Approval_Matrix__c standingMaterialNumberApprovalMatrix = [Select Id from Custom_Approval_Matrix__c where Name = 'CLM Material Number Approval Matrix' LIMIT 1];
        Custom_Approval_Matrix_Products__c campRecord1 = new Custom_Approval_Matrix_Products__c(
            Custom_Approval_Matrix__c = standingMaterialNumberApprovalMatrix.id,
            Product__c = prod.id
        );
        insert campRecord1;
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(SGD_USD);
        insert objPriceList;
        //06-SGD-USD
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(prod, objPriceList);
        insert objPriceListItem ;
        Apttus__APTS_Agreement__c objAgreement = [Select Id,Submit_For_Approval__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' ];

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c ='11234187';
        objAgreementLineItem2.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem2.Discount_Type__c = FIXEDDISCOUNT ;
        objAgreementLineItem2.Customer_ERP_Number__c = '123456';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '01';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
        objAgreementLineItem2.Discontinued__c = 'No';
        objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;
        Test.startTest();
        insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem2};
        
        Test.stopTest();
        Apttus__AgreementLineItem__c objAgrUpd = [Select Id, Approval_Category__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :objAgreement.Id];
        system.assert(objAgrUpd.Approval_Category__c != null, 'Approvals did not fire');
    }

    @isTest
    static void testROApprovalsDiscount(){
        User objRepUser = TestDataUser.findUserInProfile('Sales User');

        Account acc = [Select Id,OwnerId From Account Where ERP_Customer_Id__c = '234567'];
        acc.OwnerId = objRepUser.Id;
        update acc;
        system.debug('%& acc'+acc);

        Product2 prod = [Select Id From Product2 Where Material_Number__c = '11234187'];
		Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(SGD_USD);
        insert objPriceList;
        //06-SGD-USD
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(prod, objPriceList);
        insert objPriceListItem ;
        Approval_Hierarchy__c appHierarchy = [SELECT id from Approval_Hierarchy__c where Approval_Hierarchy_Type__c = 'CLM_Sales_Hierarchy'];
        appHierarchy.Approver_Level_1__c = objRepUser.id;
        update appHierarchy;
        system.debug('%$ appHierarchy'+appHierarchy);

        Apttus__APTS_Agreement__c objAgreement = [Select Id,Submit_For_Approval__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' ];

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c ='11234187';
        objAgreementLineItem2.Material_Group_1__c = 'FTS';
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem2.Discount_Type__c = FIXEDDISCOUNT ;
        objAgreementLineItem2.Customer_ERP_Number__c = '123456';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '01';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
        objAgreementLineItem2.Discontinued__c = 'No';
        objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;
        Test.startTest();
        insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem2};
        
        Test.stopTest();
        Apttus__AgreementLineItem__c objAgrUpd = [Select Id, Approval_Category__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :objAgreement.Id];
        system.assert(objAgrUpd.Approval_Category__c != null, 'Approvals did not fire');
    }
/*
    @author: Joshith K
    @Story : TASK0537090
    @Description : .
*/ 
    @isTest
    static void testLineStatusUpdate(){
        //User objRepUser = TestDataUser.findUserInProfile('Sales User');
        Test.startTest();
        //PermissionSet objpermissionSet =[select id,name from PermissionSet where Name ='SL_Apttus_Agreement_Manager' limit 1];
        //insertUserPermissionset();
        //PermissionSetAssignment objPermiAssign=[select id,AssigneeId  from PermissionSetAssignment where PermissionSetId =:objpermissionSet.Id  and AssigneeId!=:UserInfo.getuserid() limit 1 ];
        User objUser=[Select id from user where UserName= 'testsalesUser@testorg.com' limit 1];
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=objUser.Id,Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        Product2 prod = [Select Id From Product2 Where Material_Number__c = '11234187'];
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(SGD_USD);
        insert objPriceList;
        //06-SGD-USD
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(prod, objPriceList);
        insert objPriceListItem ;
        Approval_Hierarchy__c appHierarchy = [SELECT id from Approval_Hierarchy__c where Approval_Hierarchy_Type__c = 'CLM_Sales_Hierarchy'];
        appHierarchy.Approver_Level_1__c = objUser.id;
        update appHierarchy;
        system.debug('%$ appHierarchy'+appHierarchy);

        System.runAs(objUser){
            Account acc2=[select id from Account where ERP_Customer_Id__c='234567' limit 1];
            Id recTypeId2 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Customer Agreement').getRecordTypeId();
            Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc2.id);
            oAgreement2.RecordTypeId = recTypeId2;
            insert oAgreement2;
            //Apttus__APTS_Agreement__c objAgreement = [Select Id,Submit_For_Approval__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' ];

            Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(oAgreement2.Id);
            objAgreementLineItem2.Material_Number__c ='11234187';
            objAgreementLineItem2.Material_Group_1__c = 'FTS';
            objAgreementLineItem2.Line_Type__c = 'Material';
            objAgreementLineItem2.Apttus_CMConfig__LineStatus__c = Label.AgreementLineItemLineStatusExisting;
            objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
            objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
            objAgreementLineItem2.Discount_Type__c = FIXEDDISCOUNT ;
            objAgreementLineItem2.Customer_ERP_Number__c = '123456';
            objAgreementLineItem2.Sales_Org__c = 'HK01';
            objAgreementLineItem2.Distribution_Channel__c = '01';
            objAgreementLineItem2.CurrencyIsoCode= 'USD';
            objAgreementLineItem2.Discount__c = 15;
            objAgreementLineItem2.Discontinued__c = 'No';
            objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
            objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;
           
            insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem2};
            objAgreementLineItem2.Discount__c = 16;
            update objAgreementLineItem2;
            Test.stopTest();
        
        Apttus__AgreementLineItem__c objAgrUpd = [Select Id, Apttus_CMConfig__LineStatus__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :oAgreement2.Id limit 1];
        system.assertEquals(objAgrUpd.Apttus_CMConfig__LineStatus__c,Label.AgreementLineItemLineStatusUpdated, 'Line status not Updated');
        }
    }
/*
    @author: Joshith K
    @Story : TASK0537090
    @Description : To create user and assign permissionset
*/ 
    @future
    public static void insertUserPermissionset() {
        Profile prof = [SELECT Id FROM Profile WHERE Name='Sales User'];
        User objUser = new User(Alias = 'standt', Email='salesuser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='TestingMerge', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = prof.Id,
                          TimeZoneSidKey='America/Los_Angeles',UserName='testsalesUser@testorg.com');
        insert objUser;
        //User objRepUser = TestDataUser.findUserInProfile('Sales User');
        List <PermissionSet> objpermissionSet =[select id,name from PermissionSet where Name ='SL_Apttus_Agreement_Manager' or Name = 'SL_Apttus_Quoting_User' limit 2];
        PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = objpermissionSet[0].Id, AssigneeId = objUser.Id);
        PermissionSetAssignment psa2 = new PermissionSetAssignment(PermissionSetId = objpermissionSet[1].Id, AssigneeId = objUser.Id);
        insert new List<PermissionSetAssignment> { psa, psa2 };
    }
    
     /* 
     * Author - Rishab
     * Description - After Update Logic
     */
    @isTest
    static void checkWithSalesProfile()
    {
        User objComOpQuotingUser = TestDataUser.findUserInProfile('Commercial Ops Quoting User');

        List<Custom_Approval_Matrix__c> lstCAM = [SELECT Id From Custom_Approval_Matrix__c];
        delete lstCAM;

        List<Approval_Hierarchy__c> lstAppHierarchy = [SELECT id from Approval_Hierarchy__c];
        delete lstAppHierarchy;

        product2 product=[select id from product2 where Material_Number__c='11234187'];
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList('06-SGD-USD');
        insert objPriceList;
        //06-SGD-USD
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(product, objPriceList);
        insert objPriceListItem ;
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        if (setting.Bypass_All_Triggers__c == false || setting.Bypass_All_Validations__c == false) 
        {
            setting.Bypass_All_Triggers__c = true;
            setting.Bypass_All_Validations__c = true;
            upsert setting;
        }

        setting.Bypass_All_Triggers__c = false;
        update setting;
        
        CLM_ProfileValidation__c setting2 = CLM_ProfileValidation__c.getInstance(objComOpQuotingUser.Id);
        if(setting2.Master_Customer_Agreement__c == false)
        {
            setting2.Master_Customer_Agreement__c = true;
        }
        upsert setting2;

        PermissionSet ps = [SELECT id,Name from Permissionset WHERE Name = 'SL_Apttus_Agreement_Manager'];

        List<PermissionSetAssignment> lstpsa = new List<PermissionSetAssignment>();
        lstpsa = [SELECT Id From PermissionSetAssignment WHERE PermissionSetId =: ps.Id AND AssigneeId =: objComOpQuotingUser.Id];

        if(lstpsa.isEmpty())
        {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id , AssigneeId = objComOpQuotingUser.Id);

            UsersSelector usrsSlctr = new UsersSelector();
            User currentUser = usrsSlctr.selectByUserId(new Set<Id> {UserInfo.getUserId()})[0];
    
            System.runAs(currentUser)
            {
                upsert psa;
            }
        }

        Apttus__APTS_Agreement__c objAgreement = [Select Id,Submit_For_Approval__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group'];
        objAgreement.OwnerId = objComOpQuotingUser.Id;
        objAgreement.Is_Auto_Approved__c = true;
        objAgreement.Legacy_Agreement_Number__c='';
        objAgreement.Apttus__Contract_Start_Date__c = system.today()+1;
        update objAgreement;
        
        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c ='11234187';
        objAgreementLineItem1.Material_Group_1__c = 'AIP';
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = FIXEDDISCOUNT ;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '01';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
        objAgreementLineItem1.Discontinued__c = 'No';
        objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Test.startTest();
        insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem1};
        
        System.runAs(objComOpQuotingUser)
        {
            objAgreementLineItem1.Apttus_CMConfig__EndDate__c = system.today()+4;
            update objAgreementLineItem1;
        }   
        Test.stopTest();
        Apttus__AgreementLineItem__c objAgrUpd = [Select Id, Discount__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :objAgreement.Id];
        system.assertEquals(15,objAgrUpd.Discount__c);//CodeScanFix [Assert Argument Order]
    }

    @isTest
    static void testBlankValidationStatusOnDelete(){

        Apttus__APTS_Agreement__c objAgreement = [Select Id, Validation_Status__c FROM Apttus__APTS_Agreement__c WHERE Name = :TEST_AGREEMENT_CUSTOMER ];

        String[] accERP = new String[]{'123456', '23456'};

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = 'HK01';
        objAgreementLineItem1.Distribution_Channel__c = '02';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
        objAgreementLineItem1.Discount__c = 15;
		objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c = VC0013519_OPA ;
        objAgreementLineItem2.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 2;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 2;
        objAgreementLineItem2.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem2.Customer_ERP_Number__c = '234567';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '02';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
		objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;
        
        insert new List<Apttus__AgreementLineItem__c >{objAgreementLineItem1,objAgreementLineItem2};

        System.debug(DEBUG_SOQLCHECK+'  ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());

        objAgreement.Validation_Status__c = 'Validate Completed';
        update objAgreement;

        Test.startTest();

        Apttus__AgreementLineItem__c objUpdAgreementLineItem2 = [Select Id,Customer_ERP_Number__c from Apttus__AgreementLineItem__c where Material_Number__c = '11234187' LIMIT 1];
        
        delete objUpdAgreementLineItem2;

        Apttus__APTS_Agreement__c objAgreementAfterDelete = [Select Id, Validation_Status__c FROM Apttus__APTS_Agreement__c WHERE Name = :TEST_AGREEMENT_CUSTOMER LIMIT 1];

        System.assert(String.isBlank(objAgreementAfterDelete.Validation_Status__c), 'Validation Status didnot get updated to blank');
        Test.stopTest();
    }

    // DCP-56501 Introduced to test Material number validation.
    @isTest
    static void testMaterialNumCustomerElecValidation()
    {
        
        User objUser=[Select id from user where UserName= 'testsalesUser@testorg.com' limit 1];
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=objUser.Id,Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(SGD_USD);
        insert objPriceList;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234186';
        productTwo.Open_Offer_Product__c= true;
        insert productTwo;
        //06-SGD-USD
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(productTwo, objPriceList);
        insert objPriceListItem ;
        Approval_Hierarchy__c appHierarchy = [SELECT id from Approval_Hierarchy__c where Approval_Hierarchy_Type__c = 'CLM_Sales_Hierarchy'];
        appHierarchy.Approver_Level_1__c = objUser.id;
        update appHierarchy;
        Apttus__APTS_Agreement__c objAgreement = [Select Id,Submit_For_Approval__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group'];
        objAgreement.OwnerId = objUser.Id;
        objAgreement.Is_Auto_Approved__c = true;
        update objAgreement;

        

        Id recTypeId = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Open Offer Agreement Line Items').getRecordTypeId();
        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c ='11234186';
        objAgreementLineItem1.Material_Group_1__c = 'AIP';
        objAgreementLineItem1.Open_Offer_Line_Type__c = 'Material';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = FIXEDDISCOUNT ;
        objAgreementLineItem1.Discount__c = 15;
        objAgreementLineItem1.Discontinued__c = 'No';
        objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;
        objAgreementLineItem1.Customer_Election__c = 'PSP';
        objAgreementLineItem1.PSP_Discount__c = 25;
        objAgreementLineItem1.RecordTypeId = recTypeId;

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c ='11234186';
        objAgreementLineItem2.Material_Group_1__c = 'AIP';
        objAgreementLineItem2.Open_Offer_Line_Type__c  = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem2.Discount_Type__c = FIXEDDISCOUNT ;
        objAgreementLineItem2.Discount__c = 15;
        objAgreementLineItem2.Discontinued__c = 'No';
        objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;
        objAgreementLineItem2.Customer_Election__c = 'PSP';
        objAgreementLineItem2.PSP_Discount__c = 26;
        objAgreementLineItem2.RecordTypeId = recTypeId;

        Test.startTest();
                
        System.runAs(objUser)
        {
            try {
                insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem1,objAgreementLineItem2};
            }
            catch(Exception e){
                System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'Exception not found');
            }            
           
        }   
        Test.stopTest();        
    }
}
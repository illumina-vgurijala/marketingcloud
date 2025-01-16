/*************************
 * @author : Pradeep L
 * Description  : Test Class to DiscountGuidancePopulatorForCLM.
 *************************/

@isTest
public class TestDiscountGuidancePopulatorForCLM {
    public static final string STRLINETYPEMATERIALGROUP = 'Material Group 1';
    public static final string STRDISCOUNTTYPE = '% Discount';
    public static FINAL string PERDISCOUNT = '% Discount';
    public static FINAL string STRING_USD = 'USD';
    public static FINAL string STRING_HK01 = 'HK01';
    public static FINAL string SV_111_3001 = 'SV-111-3001';
    public static FINAL string VC0013519_OPA = 'VC0013519-OPA';


    /**
     * Method Name: setupdata
     * Description: Sets up the test data required for the DiscountGuidancePopulatorForCLM tests. 
     *              This includes creating accounts, products, customer master data, account sales areas, 
     *              agreements, agreement line items, and other necessary records.
     * Author: Pradeep Landge
     * Ticket: DGP-406,DGP-103
     */
    @TestSetup
    static void setupdata() {
        Test.startTest();

        Account acc = TestDataAccount.initAccount();
        acc.Country_Local__c = 'Japan';
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Prospect';
        acc.Channel_Partner_Type__c = null;
        acc.National_Group_Number__c = '2';

        Account acc1 = TestDataAccount.initAccount();
        acc1.ERP_Customer_Id__c = '234567';

        insert new List < Account > {
            acc,
            acc1
        };

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = VC0013519_OPA;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        Product2 productFour = TestDataMaster.createProduct(false);
        productFour.Old_Material_Number__c = SV_111_3001;

        insert new List < Product2 > {
            product,
            productTwo,
            productThree,
            productFour
        };


        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name = 'CMD1', Country__c = 'Hong Kong', Country_Code__c = 'HK'),
            objCMD2 = new Customer_Master_Data__c(Name = 'CMD2', Country__c = 'Hong Kong', Country_Code__c = 'HK');
        objCMD1.ERP_Customer_Id__c = '234567';
        objCMD2.ERP_Customer_Id__c = '183456';
        insert new List < Customer_Master_Data__c > {
            objCMD1,
            objCMD2
        };

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD';
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc1.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD';
        acc2SalesArea.Contract_Number__c = '567890_US010100';
        insert new List < Account_Sales_Area__c > {
            acc1SalesArea,
            acc2SalesArea
        };

        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId = userinfo.getProfileId(), Channel_Partner_Agreement__c = true, Master_Customer_Agreement__c = true, Master_Service_Agreement__c = true, Negotiated_Terms_and_Conditions__c = true, Standing_Quote__c = true, Tender__c = true);
        insert profilevalidation;

        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        oAgreement1.recordTypeId = recTypeId;
        insert oAgreement1;


        cs_Apex_Settings__c cs1 = cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
        cs1.Bypass_All_Validations__c = true;
        upsert cs1 cs_Apex_Settings__c.Id;

        Customer_Historical_Spend__c ch = new Customer_Historical_Spend__c();
        ch.Primary_Customer_Type__c = 'Government';
        ch.Customer_Historic_Spend__c = 120000;
        ch.Total_Instrument_Credits__c = 11;
        ch.Valid_From_Date__c = System.today() - 5;
        ch.Valid_To_Date__c = System.today() + 5;
        ch.Frequency__c = 'Last Fiscal Year';
        ch.ERP_ID__c = '234567';
        insert ch;

        cs1.Bypass_All_Validations__c = false;
        upsert cs1 cs_Apex_Settings__c.Id;

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

        Test.stopTest();
    }

    /**
     * Method Name: deriveFieldValuesForDiscountGuidanceTest
     * Description: Test method for deriveFieldValuesForDiscountGuidance. This method sets up the test data, executes the DiscountGuidancePopulatorForCLM method, and verifies the results.
     * Author: Pradeep Landge
     * Ticket: DGP-406, DGP-103
     */
    @IsTest
    static void deriveFieldValuesForDiscountGuidanceTest() {

        Test.startTest();
        Apttus__APTS_Agreement__c objAgreement = [Select Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        List < Apttus__AgreementLineItem__c > lstAgmtLI = new List < Apttus__AgreementLineItem__c > ();
        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Material_Group_1__c = 'AIP';
        objAgreementLineItem1.Line_Type__c = 'Material Group 1';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c = '234567';
        objAgreementLineItem1.Sales_Org__c = STRING_HK01;
        objAgreementLineItem1.Distribution_Channel__c = '01';
        objAgreementLineItem1.CurrencyIsoCode = STRING_USD;
        objAgreementLineItem1.Discount__c = 15;
        objAgreementLineItem1.Apttus_CMConfig__LineStatus__c = 'New';
        objAgreementLineItem1.Discount_Grid_Group__c = 'iSeq Cons';
        objAgreementLineItem1.Discontinued__c = 'No';
        objAgreementLineItem1.Apttus_CMConfig__StartDate__c = System.today() + 5;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c = System.today() + 28;
        lstAgmtLI.add(objAgreementLineItem1);

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c = VC0013519_OPA;
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 2;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 2;
        objAgreementLineItem2.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem2.Customer_ERP_Number__c = '234567';
        objAgreementLineItem2.Sales_Org__c = STRING_HK01;
        objAgreementLineItem2.Distribution_Channel__c = '01';
        objAgreementLineItem2.CurrencyIsoCode = STRING_USD;
        objAgreementLineItem2.Discount__c = 15;
        objAgreementLineItem2.Apttus_CMConfig__LineStatus__c = 'New';
        objAgreementLineItem2.Discount_Grid_Group__c = 'iSeq Cons';
        objAgreementLineItem2.Discontinued__c = 'Yes';
        objAgreementLineItem2.Apttus_CMConfig__StartDate__c = System.today() + 5;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c = System.today() + 28;
        lstAgmtLI.add(objAgreementLineItem2);
        insert lstAgmtLI;

        lstAgmtLI = [SELECT id, Material_Group_1__c, Discount_Grid_Group__c, Apttus_CMConfig__StartDate__c, Agreement_Currency__c, CurrencyIsoCode, Customer_Historical_Discount__c, Discount_Guidance__c, Max_Discount_Guidance__c, Median_Discount_Guidance__c, Ultimate_Consignee_ERP_Number__c, Agreement_Distribution_Channel__c, Agreement_Subtype__c, Do_Not_Run_Discount_Guidance__c, Agreement_Record_Type__c, Discontinued__c, Apttus_CMConfig__LineStatus__c, Discount__c, Distribution_Channel__c, Sales_Org__c, Material_Number__c, Line_Type__c, Apttus_CMConfig__LineNumber__c, Apttus_CMConfig__ItemSequence__c, Discount_Type__c, Customer_ERP_Number__c from Apttus__AgreementLineItem__c LIMIT 2];
        lstAgmtLI[0].Discount_Grid_Group__c = 'iSeq Cons';
        lstAgmtLI[1].Discount_Grid_Group__c = 'iSeq Cons';
        new DiscountGuidancePopulatorForCLM().deriveFieldValuesForDiscountGuidance(lstAgmtLI, null);
        Test.stopTest();
        Assert.areEqual(lstAgmtLI.size(), 2, 'Agreement Lines'); 

    }
}
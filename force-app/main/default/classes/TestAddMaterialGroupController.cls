/**
*    @author        Tapas Chakraborty
*    @date          Sep-18-2020
*    @description   DCP-40571 add material groups to  Standing Quote Opportunities
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Tapas Chakraborty              18 Sep 2020         Initial Version: DCP-40571 Test Class for AddMaterialGroupController
*             Arif,Dalali                    28-Nov-2022          POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*------------------------------------------------------------- ------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestAddMaterialGroupController{
    
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
    public static FINAL string STRING_HK01 = 'HK01' ;
    public static FINAL string STRING_USD = 'USD';
    
/**  
*  @author Tapas Chakraborty
*  @description -setup method to create test data
**/
    @testSetup
    public static void createData(){
        Account acc = TestDataAccount.initAccount();
        acc.Country_Local__c ='Japan';
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        //acc.Account_Group__c = 'Distributor';
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
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRING_HK01, '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = STRING_USD;
        acc1SalesArea.Price_List__c = AMEA_USD; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea(STRING_HK01, '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = STRING_USD;
        acc2SalesArea.Price_List__c = AMEA_USD; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };
            
            System.debug(DEBUG_SOQLCHECK +' ' + Limits.getLimitQueries());
        System.debug(DEBUG_SOQLIMIT+' ' + Limits.getQueries());
        
        
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standing Quote').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Customer', acc.id);
        //oAgreement1.Customer_Discount_Level__c = 'Customer';
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Apttus__Subtype__c = 'Non-Standard';
        oAgreement1.Additional_Output_Language__c = 'Japanese';
        oAgreement1.Incoterm__c = 'EXW: Ex Works';
        oAgreement1.Exclusivity__c  = true;
        oAgreement1.Justification_for_No_Agreement_Value__c = 'Comparison Customer';
        oAgreement1.Freight_Charge__c = 'Standard';
        insert oAgreement1;   
        
    }
    
    static testmethod void testgetMaterialGroups(){
        Apttus__APTS_Agreement__c objAgreement = [Select Id FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Customer' ];
        Account objAcc = [select id from account limit 1];
        Id oppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standing Quote').getRecordTypeId();
        
        List<Apttus__AgreementLineItem__c> lstAgmtLI = new List<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Material_Number__c = '11234187';
        objAgreementLineItem1.Material_Group_1__c = 'AIP';
        objAgreementLineItem1.Line_Type__c = 'Material Group 1';
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount_Type__c = PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c = '123456';
        objAgreementLineItem1.Sales_Org__c = STRING_HK01;
        objAgreementLineItem1.Distribution_Channel__c = '01';
        objAgreementLineItem1.CurrencyIsoCode= STRING_USD;
        objAgreementLineItem1.Discount__c = 15;
        objAgreementLineItem1.Apttus_CMConfig__LineStatus__c = 'Existing';
        objAgreementLineItem1.Discontinued__c = 'No';
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
        objAgreementLineItem2.CurrencyIsoCode= STRING_USD;
        objAgreementLineItem2.Discount__c = 15;
        objAgreementLineItem2.Apttus_CMConfig__LineStatus__c = 'Existing';
        objAgreementLineItem2.Discontinued__c = 'Yes';
        lstAgmtLI.add(objAgreementLineItem2);
        insert lstAgmtLI;

        Test.startTest();
        
        Opportunity objOpp1 = new Opportunity();
        objOpp1.Related_Agreement__c = objAgreement.Id;
        objOpp1.Fiscal_Quarter__c = 'Current Quarter';
        objOpp1.CloseDate = Date.newinstance(Date.Today().Year() + 1, 3, 31);
        objOpp1.Name = 'Test Data 8 Amended 12_4d Molecular Therapeutics_Sep302020 2';
        objOpp1.AccountId = objAcc.Id;
        objOpp1.StageName = 'Finalize';
        objOpp1.recordTypeId = oppRecTypeId;
        
        insert objOpp1;
        
        String str = AddMaterialGroupController.getMaterialGroups(objAgreement.Id, objOpp1.Id);
        List<AddMaterialGroupController.WrapperClass> lstWrapper = (List<AddMaterialGroupController.WrapperClass>)JSON.deserialize(str, List<AddMaterialGroupController.WrapperClass>.class);
        System.debug('str is '+str);
        System.assertEquals('AIP', lstWrapper[0].MaterialGroup);
        lstWrapper[0].ForecastAmount = 100;
        lstWrapper[0].isChecked = true;
        String str2 = AddMaterialGroupController.insertMaterialGroupsOnOpp(lstWrapper, objOpp1.Id);
        System.debug('sqop is '+str2 + [select id,name,Forecast_Amount__c from Standing_Quote_Opportunity_Product__c limit 2]);
        System.assertEquals(1, [select id from Standing_Quote_Opportunity_Product__c limit 2].size());
        String str22 = AddMaterialGroupController.getMaterialGroups(objAgreement.Id, objOpp1.Id);
        List<AddMaterialGroupController.WrapperClass> lstWrapper2 = new List<AddMaterialGroupController.WrapperClass>();
        String str3 = AddMaterialGroupController.insertMaterialGroupsOnOpp(lstWrapper2, objOpp1.Id);
        System.debug('sqop2 is '+str22 + str3 + [select id,name,Forecast_Amount__c from Standing_Quote_Opportunity_Product__c limit 2]);
        System.assertEquals(0, [select id from Standing_Quote_Opportunity_Product__c limit 2].size());
        Test.stopTest();
    }
}
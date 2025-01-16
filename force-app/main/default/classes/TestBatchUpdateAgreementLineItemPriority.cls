/**
*    @author Nishan Shetty
*    @date   2022-07-01
*    @description    DCP-52703 Test Class for BatchUpdateAgreementLineItemPriority class.
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------
*       Developer                      Date                Description
*     Nishan Shetty                 01 July 2022          Initial Version
*     Gerardo Garcia                26 June 2024          DGP-107 Fix test on UAT.
*    --------------------------------------------------------------------------------------------------------------------------
**/
@isTest(SeeAllData=false isParallel=false)
public without sharing class TestBatchUpdateAgreementLineItemPriority {
    public static final string SGD_USD = '06-SGD-USD';
    public static final string TXDR = 'TXDR';
    private static final String MG_AIM = 'AIM';

    @testSetup
    static void setupData() {
      //Creating Account
      Account acc = TestDataAccount.initAccount();
      acc.Country_Local__c ='Japan';
      acc.ERP_Customer_Id__c = '123458';
      acc.Territory_Region__c = 'AMR';
      acc.Account_Group__c = 'Sold To';
      insert acc;
      //Creating Contact
      Contact con = TestDataPerson.initContact(acc.Id);
      insert con;

      //Creating Account Sales Area
      Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
      acc1SalesArea.Account__c = acc.Id;
      acc1SalesArea.Price_List_Type__c = '06';
      acc1SalesArea.CurrencyIsoCode = 'USD';
      acc1SalesArea.Price_List__c = SGD_USD;
      acc1SalesArea.Contract_Number__c = '123458_HK010100';
      acc1SalesArea.ERP_Account_Sales_Area_Id__c = '123458_HK010100';
      acc1SalesArea.Price_Group__c = TXDR;
      insert acc1SalesArea;

      //Creating Product
      Product2 product = TestDataMaster.createProduct(false);
      product.Material_Number__c = '11293048' ;
      product.Material_Group_1_Code__c = MG_AIM;
      insert product;

      //Creating Profile Validation.
      CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
      insert profilevalidation;

      //Customer Master Data
      Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK');
      objCMD1.ERP_Customer_Id__c = '123458';
      insert new List<Customer_Master_Data__c> {objCMD1};

      //Creating Agreement
      Apttus__APTS_Agreement__c objAgreement=TestDataAgreement.initAgreements('TestBatchUpdateAgreementLineItemPriority',acc.Id);
      objAgreement.Apttus_Approval__Approval_Status__c='Approval Required';
      objAgreement.Apttus__Contract_End_Date__c=System.today()+3;
      objAgreement.Discount_Justification__c = 'Test';
      objAgreement.Justification_for_No_Agreement_Value__c = 'Comparison Customer';
      //objAgreement.Reason_for_Non_Standard_Freight__c = 'Testing';
      insert objAgreement;

      //Creating AgreementLineItem
      Apttus__AgreementLineItem__c objAgreementLineItem = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
      objAgreementLineItem.Material_Group_1__c = MG_AIM;
      objAgreementLineItem.Apttus_Approval__Approval_Status__c='Approval Required';
      objAgreementLineItem.Line_Type__c='Material Group 1';
      objAgreementLineItem.Customer_ERP_Number__c='123458';
      objAgreementLineItem.Sales_Org__c='HK01';
      objAgreementLineItem.Distribution_Channel__c='01';
      objAgreementLineItem.CurrencyIsoCode= 'USD';
      objAgreementLineItem.Apttus_CMConfig__StartDate__c=system.today()+1;
      objAgreementLineItem.Apttus_CMConfig__EndDate__c=system.today()+2;
      objAgreementLineItem.Discount__c = 15;
      objAgreementLineItem.Discount_Type__c = '% Discount';
      objAgreementLineItem.Discontinued__c = 'No';
      insert objAgreementLineItem;
    }

    @isTest
    static void testBatchUpdate() {
        Apttus__APTS_Agreement__c objAgreement = [SELECT Id, Name FROM Apttus__APTS_Agreement__c WHERE Name = 'TestBatchUpdateAgreementLineItemPriority' LIMIT 1];
        Test.startTest();
        BatchUpdateAgreementLineItemPriority batchUpdateAgreementLinePriority=new BatchUpdateAgreementLineItemPriority();
        batchUpdateAgreementLinePriority.getDefaultBatchSize();
        String strInput=batchUpdateAgreementLinePriority.serializeInputs();
        batchUpdateAgreementLinePriority.restoreInputs(strInput);
        
        Database.executeBatch(batchUpdateAgreementLinePriority,1);
        Test.stopTest();

        Map<String,Material_Group__mdt> mapMaterialGroupMetaData = Material_Group__mdt.getAll();

        Apttus__AgreementLineItem__c objAgreementLineItem = [SELECT Id,Priority__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c=:objAgreement.Id LIMIT 1];
        Assert.areEqual(mapMaterialGroupMetaData.get(MG_AIM).Priority__c, objAgreementLineItem.Priority__c, 'Agreement Line Item Priority Not Set');

    }


    
}
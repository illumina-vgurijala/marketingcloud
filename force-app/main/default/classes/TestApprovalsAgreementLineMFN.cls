/**
*    @author Bharath Varma
*    @date   2021-12-07
*    @description    DCP-50961: Test class for ApprovalsAgreementLineMFN
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Bharath Varma                2021-12-07           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestApprovalsAgreementLineMFN {

    public static FINAL string PERDISCOUNT = '% Discount';
    public static FINAL string MATGRPAIP = 'AIP';

    @testSetup
    static void setupData() {
        TestDataApprovals.getSupportDataForAgreementApprovals();
    }


    private static List<Product2> getProducts()
    {
        Product2 objProduct2 = TestDataMaster.createProduct(false);
        objProduct2.Material_Group_1__c = TestDataApprovals.MATERIAL_GROUP_AIP;
        objProduct2.Material_Number__c = '20028871'; 

        Product2 objProduct3 = TestDataMaster.createProduct(false);
        objProduct3.Material_Group_1__c = TestDataApprovals.MATERIAL_GROUP_AIP;
        objProduct3.Material_Number__c = '20028318'; 
        
        Product2 objProduct4 = TestDataMaster.createProduct(false);
        objProduct4.Material_Group_1__c = TestDataApprovals.MATERIAL_GROUP_AIP; 
        objProduct4.Material_Number__c = '20024913'; 

        return new List<Product2>{objProduct2,objProduct3,objProduct4};
    }

     @isTest
    static void testMFNApprovals()
    { 
        ApttusAgreementLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesCLMApprovalsPipeline', true);

        Account acc = [Select Id, Clinical_Oncology_Screening_Dx_Testing__c, For_Profit_Company__c, BillingCountry, BillingState From Account Where ERP_Customer_Id__c = '234567'];
        acc.Clinical_Oncology_Screening_Dx_Testing__c = 'Yes';
        acc.For_Profit_Company__c = 'Yes';
        acc.BillingCountry = 'USA';
        acc.BillingState = 'Texas';

        update acc;
        system.debug('%& acc'+acc); 

        List<Product2> products = getProducts();
        insert products;

        Apttus__APTS_Agreement__c objAgreement = [Select Id,Submit_For_Approval__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' ];

        List<Apttus__AgreementLineItem__c> agreementLines = new List<Apttus__AgreementLineItem__c>();

        for(Product2 product : products)
        {
            Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
            objAgreementLineItem2.Material_Number__c = product.Material_Number__c;
            objAgreementLineItem2.Material_Group_1__c = MATGRPAIP;
            objAgreementLineItem2.Line_Type__c = 'Material';
            objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
            objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
            objAgreementLineItem2.Discount_Type__c = PERDISCOUNT ;
            objAgreementLineItem2.Customer_ERP_Number__c = '123456';
            objAgreementLineItem2.Sales_Org__c = 'HK01';
            objAgreementLineItem2.Distribution_Channel__c = '01';
            objAgreementLineItem2.CurrencyIsoCode= 'USD';
            objAgreementLineItem2.Discount__c = 45;
            objAgreementLineItem2.Discontinued__c = 'No';
            objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
            objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;

            agreementLines.add(objAgreementLineItem2);
        }

        Test.startTest();
        insert agreementLines;

        acc.BillingCountry = 'Germany';
        update acc;

        for(Apttus__AgreementLineItem__c agreementLine : agreementLines)
        {
            agreementLine.Discount__c = 47;
        }

        update agreementLines;
        
        Test.stopTest();
        Apttus__AgreementLineItem__c objAgrUpd = [Select Id, Approval_Category__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :objAgreement.Id LIMIT 1];
        system.assert(objAgrUpd.Approval_Category__c != null, 'Approvals did not fire');
    }

   
}
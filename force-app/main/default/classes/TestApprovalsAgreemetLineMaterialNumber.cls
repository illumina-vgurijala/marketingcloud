/**
*    @author Bharath Varma
*    @date   2021-12-07
*    @description    DCP-50961: Test class for ApprovalAgreementLineMaterialNumber and ApprovalAgreementLineMatNumCustom
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Bharath Varma               2021-08-19           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestApprovalsAgreemetLineMaterialNumber {

    public static FINAL string PERDISCOUNT = '% Discount';
    public static FINAL string MATGRPAIP = 'AIP';
    public static FINAL string SGD_USD = '06-SGD-USD';

    @testSetup
    static void setupData() {
        TestDataApprovals.getSupportDataForAgreementApprovals();
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
    }

    @isTest
    static void testROApprovalsMaterialNumber()
    { 
        ApttusAgreementLineItems.useOldFrameworkWhileTesting = false;
        Feature.setMockFeatureFlag('SalesCLMApprovalsPipeline', true);

        Apttus__APTS_Agreement__c objAgreement = [Select Id,Submit_For_Approval__c FROM Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group' ];

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem2.Material_Number__c ='11234187';
        objAgreementLineItem2.Material_Group_1__c = MATGRPAIP;
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem2.Discount_Type__c = PERDISCOUNT ;
        objAgreementLineItem2.Customer_ERP_Number__c = '123456';
        objAgreementLineItem2.Sales_Org__c = 'HK01';
        objAgreementLineItem2.Distribution_Channel__c = '01';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
        objAgreementLineItem2.Discount__c = 15;
        objAgreementLineItem2.Discontinued__c = 'No';
        objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;

        Account acc = [Select Id,OwnerId From Account Where ERP_Customer_Id__c = '123456'];
        system.debug('%& acc'+acc); 

        Test.startTest();
        insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem2};

        Approval_Hierarchy__c appHierarchy = [SELECT id from Approval_Hierarchy__c where Approval_Hierarchy_Type__c = 'CLM_Sales_Hierarchy'];
        appHierarchy.Approver_Level_1__c = acc.OwnerId;
        update appHierarchy;
        system.debug('%$ appHierarchy'+appHierarchy);

        objAgreementLineItem2.Discount__c = 2;

        update objAgreementLineItem2;

        objAgreementLineItem2.Discount__c = 16;

        update objAgreementLineItem2;
        
        Test.stopTest();
        Apttus__AgreementLineItem__c objAgrUpd = [Select Id, Approval_Category__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c = :objAgreement.Id];
        system.assert(objAgrUpd.Approval_Category__c != null, 'Approvals did not fire');
    }

   
}
/**
*    @author Adyasha Satapathy
*    @date   2021-09-24
*    @description  DCP- : Test class for AgreementLinesFindDuplicatesController
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adyasha Satapathy            2021-09-24           Initial Version
 *        Arif,Dalali                  28-Nov-2022          POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestAgrLinesFindDuplicatesController 
{
    @TestSetup
    static void setupData()
    {
        Account acc = TestDataAccount.getCustomerAccount();
        acc.Country_Local__c ='Japan';
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';

        Account acc2 = TestDataAccount.getCustomerAccount();
        acc2.ERP_Customer_Id__c = '234567';
        insert new List<Account> { acc, acc2 };
        
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};
        
        TestDataMaster.createProduct(true);
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = TestApttusAgreementLineItems.SGD_USD;
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010100';
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group__c = TestApttusAgreementLineItems.TXDR;
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Sales_Organization__c='HK01';
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = TestApttusAgreementLineItems.AMEA_USD; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea};

        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=UserInfo.getUserId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Id recTypeId1 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Customer Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Agreement SQ 1', acc.id);
        oAgreement1.RecordTypeId = recTypeId1;
        oAgreement1.Sales_Org__c = 'HK01';

        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Agreement SQ 2', acc.id);
        oAgreement2.RecordTypeId = recTypeId1;
        oAgreement2.Sales_Org__c = 'HK01';

        Apttus__APTS_Agreement__c oAgreement3 = TestDataAgreement.initAgreements('Agreement SQ 3', acc.id);
        oAgreement3.RecordTypeId = recTypeId1;
        oAgreement3.Sales_Org__c = 'HK01';

        insert new List<Apttus__APTS_Agreement__c>{oAgreement1,oAgreement2, oAgreement3};
    }

    /*
    *  @author:         Adyasha
    *  @description:    Mthod to Detect Duplicate Agreement Line Items among other agreements
    */
    @isTest
    static void testGetDuplicateAgreementLines()
    {
        List<Apttus__APTS_Agreement__c> lstAgreement = [SELECT Id,Apttus__Status_Category__c,Apttus__Status__c,Validation_Status__c FROM Apttus__APTS_Agreement__c LIMIT 3];
        Product2 product = [Select Id, Material_Number__c from Product2 LIMIT 1];
        Apttus__APTS_Agreement__c objAgreement1 = lstAgreement.get(0);
        Apttus__APTS_Agreement__c objAgreement2 = lstAgreement.get(1);
        Apttus__APTS_Agreement__c objAgreement3 = lstAgreement.get(2);

        objAgreement2.Apttus__Status_Category__c ='In Effect';
        objAgreement2.Apttus__Status__c = 'Activated';
        objAgreement2.Validation_Status__c = 'Activate Completed';
        update objAgreement2;

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement1.Id);
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Material_Number__c = product.Material_Number__c;
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount__c = 5;
        objAgreementLineItem1.Discount_Type__c = TestApttusAgreementLineItems.PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c='123456';
        objAgreementLineItem1.Sales_Org__c='HK01';
        objAgreementLineItem1.Distribution_Channel__c='01';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
		objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Apttus__AgreementLineItem__c objAgreementLineItem2 = TestDataAgreement.initAgreementsLineItem(objAgreement2.Id);
        objAgreementLineItem2.Line_Type__c = 'Material';
        objAgreementLineItem2.Material_Number__c = product.Material_Number__c;
        objAgreementLineItem2.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem2.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem2.Discount__c = 5;
        objAgreementLineItem2.Discount_Type__c = TestApttusAgreementLineItems.PERDISCOUNT;
        objAgreementLineItem2.Customer_ERP_Number__c='123456';
        objAgreementLineItem2.Sales_Org__c='HK01';
        objAgreementLineItem2.Distribution_Channel__c='01';
        objAgreementLineItem2.CurrencyIsoCode= 'USD';
		objAgreementLineItem2.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem2.Apttus_CMConfig__EndDate__c=system.today()+2;
        
        Test.startTest();

        insert new List<Apttus__AgreementLineItem__c>{objAgreementLineItem1,objAgreementLineItem2};
        
        Apttus__APTS_Related_Agreement__c relAgreement = new Apttus__APTS_Related_Agreement__c();
        relAgreement.Apttus__APTS_Contract_From__c = objAgreement3.Id;
        relAgreement.Apttus__APTS_Contract_To__c = objAgreement1.Id;
        relAgreement.Apttus__Relationship_From_Type__c = 'Is Amended By';
        insert relAgreement;
        
        String strResult = AgreementLinesFindDuplicatesController.getDuplicateAgreementLines(objAgreement1.Id);

        Test.stopTest();

        AgreementLinesFindDuplicatesController.AgreementLineDuplicateWrapper agreementLineDuplicateWrapper = (AgreementLinesFindDuplicatesController.AgreementLineDuplicateWrapper) JSON.deserialize(strResult, AgreementLinesFindDuplicatesController.AgreementLineDuplicateWrapper.class);
        
        System.assertEquals(agreementLineDuplicateWrapper.duplicates.get(0).agreementLineID.replace('/',''),objAgreementLineItem2.Id,'Duplicate logic did not fire');
    }

     /*
    *  @author:         Adyasha
    *  @description:    Mthod to show Error if no Agreement Lines present
    */
    @isTest
    static void testGetDuplicateLinesWithoutLineItemsPresent()
    {
        Apttus__APTS_Agreement__c objAgreement = [SELECT Id,Apttus__Status_Category__c,Apttus__Status__c,Validation_Status__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        Product2 product = [Select Id, Material_Number__c from Product2 LIMIT 1];

        Apttus__AgreementLineItem__c objAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(objAgreement.Id);
        objAgreementLineItem1.Line_Type__c = 'Material';
        objAgreementLineItem1.Material_Number__c = product.Material_Number__c;
        objAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem1.Discount__c = 5;
        objAgreementLineItem1.Discount_Type__c = TestApttusAgreementLineItems.PERDISCOUNT;
        objAgreementLineItem1.Customer_ERP_Number__c='123456';
        objAgreementLineItem1.Sales_Org__c='HK01';
        objAgreementLineItem1.Distribution_Channel__c='01';
        objAgreementLineItem1.CurrencyIsoCode= 'USD';
		objAgreementLineItem1.Apttus_CMConfig__StartDate__c=system.today()+1;
        objAgreementLineItem1.Apttus_CMConfig__EndDate__c=system.today()+2;

        Test.startTest();

        String strResult1 = AgreementLinesFindDuplicatesController.getDuplicateAgreementLines(objAgreement.Id);
        
        insert objAgreementLineItem1;

        String strResult2 = AgreementLinesFindDuplicatesController.getDuplicateAgreementLines(objAgreement.Id);

        Test.stopTest();

        AgreementLinesFindDuplicatesController.AgreementLineDuplicateWrapper agreementLineDuplicateWrapper = (AgreementLinesFindDuplicatesController.AgreementLineDuplicateWrapper) JSON.deserialize(strResult1, AgreementLinesFindDuplicatesController.AgreementLineDuplicateWrapper.class);

        AgreementLinesFindDuplicatesController.AgreementLineDuplicateWrapper agreementLineDuplicateWrapper2 = (AgreementLinesFindDuplicatesController.AgreementLineDuplicateWrapper) JSON.deserialize(strResult2, AgreementLinesFindDuplicatesController.AgreementLineDuplicateWrapper.class);

        System.assert(agreementLineDuplicateWrapper.strMessage.contains(Label.No_Agreement_Lines_For_Duplicates_Validation),'Agreement Lines should not be present for current agreement for this test');

        System.assert(agreementLineDuplicateWrapper2.strMessage.contains(Label.No_Agreement_Lines_For_Duplicates_Validation),'Agreement Lines should not be present for any other agreement for this test');
    }
}
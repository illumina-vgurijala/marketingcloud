/**
 *    @author Satya Swain
 *    @date   12-March-2020
 *    @description    Test class for ApttusAgreementImportDocumentController created as part of DCP-35033
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                   Date                  Description
 *    Satya                   12-March-2020           Initial Version
 *    Arif,Dalali             28-Nov-2022             POL-57: Update APJ and EMEA References to AMEA and Europe respectively
 *   ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest(isParallel=false)
public with sharing class TestApttusAgreementImportDocController
{
    @TestSetup
    static void setupData()
    {
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Name = 'Test Account';
        acc.Account_Group__c = 'Distributor';
        acc.BillingCountryCode='HK';
        insert acc;
        
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK');
        insert objCMD1;

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';        
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c='Test TXDR';
        acc1SalesArea.Distribution_Channel__c='01';

        insert acc1SalesArea;

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = 'VC0013519-OPA';
        insert product;

        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        //Changed record type to satisfy condition in metadata
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Negotiated Terms and Conditions').getRecordTypeId();

        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        //oAgreement1.Customer_Discount_Level__c = 'Price Group';
        oAgreement1.Sales_Org__c ='HK01';//adding reference sales org
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Apttus__Auto_Renewal__c=True;
        insert oAgreement1;
    }
    @isTest
    static void testUpdateAgreementOnOfflineImport()
    {

        Apttus__APTS_Agreement__c objAgreement = [Select Id from Apttus__APTS_Agreement__c Limit 1];
        objAgreement.Apttus__Subtype__c = Label.AgreementSubTypeStandard;
        update objAgreement;
        Test.setCurrentPageReference(new PageReference('Page.ApttusAgreementImportOfflineDocument'));
        System.currentPageReference().getParameters().put('id', objAgreement.Id);
        
        ApttusAgreementImportDocumentController importDocController = new ApttusAgreementImportDocumentController();
        importDocController.updateAgreement();
        Apttus__APTS_Agreement__c objAgreement2 = [Select Id, Apttus__Status_Category__c, Apttus__Status__c from Apttus__APTS_Agreement__c Limit 1];
        System.assertEquals('In Authoring', objAgreement2.Apttus__Status_Category__c);
        System.assertEquals('Author Contract', objAgreement2.Apttus__Status__c);

        System.currentPageReference().getParameters().put('id', null);
        ApttusAgreementImportDocumentController importDocController2 = new ApttusAgreementImportDocumentController();
        importDocController2.updateAgreement();

    }

}
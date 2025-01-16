/**
*    @author Rishab Wali
*    @date   2020-05-23
*    @description DCP-37233 Test Class for Agreement Recall Controller
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                 Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Parthasarathy D         10-Oct-2022          Codescan Fix - Added method level comments.
* Arif,Dalali             28-Nov-2022          POL-57: Update APJ and EMEA References to AMEA and Europe respectively             
*/
@isTest
public class TestAgreementRecallController {

    Public static FINAL String PRICELIST_01_AMEA_USD = '01-AMEA-USD'; //POL-57
    Public static FINAL String TEST_TXDR = 'Test TXDR';
    Public static FINAL String AUTHOR_CONTRACT = 'Author Contract';
    Public static FINAL String APPROVAL_REQUIRED = 'Approval Required';
    /*
    *  @author      : 
    *  @description : Method to test recall agreement scenario.
    *  @param       : 
    *  @return      : Void.
    */
    @isTest
    public static void recallAgreementTest()
    {
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BIllingCountryCode='HK';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';  
        acc2.BIllingCountryCode='HK' ;     
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
        
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        insert new List<Customer_Master_Data__c> {objCMD1};
        
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = PRICELIST_01_AMEA_USD; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';        
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';

        insert new List<Account_Sales_Area__c>{ acc1SalesArea };

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = 'VC0013519-OPA';
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        insert new List<Product2> { product, productTwo, productThree };
       

        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();

        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - One', acc.id);
        oAgreement1.Sales_Org__c ='HK01';
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Apttus__Auto_Renewal__c=True;
        oAgreement1.Apttus__Status_Category__c ='In Authoring';
        oAgreement1.Apttus__Status__c = AUTHOR_CONTRACT;
        oAgreement1.Apttus_Approval__Approval_Status__c =APPROVAL_REQUIRED;
        oAgreement1.Validation_Status__c ='None';
        insert oAgreement1;
        test.startTest();
        AgreementRecallController.recallAgreement(oAgreement1.Id);//Success Case
        AgreementRecallController.recallAgreement('Invalid');//Catch Coverage
        test.stopTest();
        List<Apttus__APTS_Agreement__c > lstAgrment = [Select Id,Apttus_Approval__Approval_Status__c from Apttus__APTS_Agreement__c where Name='Test Agreement - One'];
        System.assertEquals('Cancelled',lstAgrment[0].Apttus_Approval__Approval_Status__c);
        
    }
    
}
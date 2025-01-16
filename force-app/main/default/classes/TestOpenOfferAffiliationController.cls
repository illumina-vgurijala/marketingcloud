/**
 * @author Satya Swain
 * @date   01-Sept-2022
 * @description    DCP-54439 : Test class for OpenOfferAffiliationController
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                 Date                    Description                                                 
*   Satya Swain             29-Aug-2022         DCP-54439: Initial Version
*   Arif,Dalali             28-Nov-2022         POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*  -----------------------------------------------------------------------------------          
*/
@isTest(isParallel=false)
public with sharing class TestOpenOfferAffiliationController {
    
    public static final string AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    public static final string TEST_TXDR = 'Test TXDR';
    public static final string TXDR = 'TXDR';
    public static final string USD = 'USD';
    public static final string HK01 = 'HK01';

    /**
     *  @author Satya Swain
     *  @description Test Data Setup
     **/
    @testSetup
    static void setupData() {
        Account objPrimaryAccount = TestDataAccount.getCustomerAccount();
        objPrimaryAccount.BillingCountryCode ='HK';
        objPrimaryAccount.ERP_Customer_ID__c = '7816_1234';
        objPrimaryAccount.National_Group_Number__c = objPrimaryAccount.ERP_Customer_ID__c;

        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.BillingCountryCode ='HK';
        objAccount.ERP_Customer_ID__c = '7816_1235';
        objAccount.National_Group_Number__c = objAccount.ERP_Customer_ID__c;
        
        insert new List<Account>{ objPrimaryAccount, objAccount };
        
        Contact con = TestDataPerson.initContact(objPrimaryAccount.Id);
        insert con;

        TestDataAgreement.addHierarchyPermission();

        Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '01', '180', '00', false);
        accSalesArea.Account__c = objPrimaryAccount.Id;
        accSalesArea.Price_List_Type__c = '06';
        accSalesArea.CurrencyIsoCode = USD;
        accSalesArea.Price_List__c = AMEA_USD_01; //POL-57
        accSalesArea.Contract_Number__c = '7816_1234_HK010100';
        accSalesArea.Price_Group__c = TXDR;
        accSalesArea.Sales_Organization__c=HK01;
        accSalesArea.Price_Group_Description__c=TEST_TXDR;
        accSalesArea.Distribution_Channel__c='01';
        insert accSalesArea;
        
        Id recTypeOO = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Open Offer Agreement').getRecordTypeId();

        Apttus__APTS_Agreement__c openOfferAgreement1 = new Apttus__APTS_Agreement__c();
        openOfferAgreement1.Name = 'Test Agreement - Open Offer2';
        openOfferAgreement1.Apttus__Account__c  = objPrimaryAccount.Id;
        openOfferAgreement1.Apttus__Contract_Start_Date__c = system.today();
        openOfferAgreement1.RecordTypeId = recTypeOO;
        openOfferAgreement1.Apttus__Subtype__c ='Standard';
        openOfferAgreement1.Discount_Justification__c = 'None';
        openOfferAgreement1.Sales_Org__c = HK01;
        openOfferAgreement1.Open_Offer_Status__c='Request';
        insert openOfferAgreement1;
    }

    @isTest
    static void testOpenOfferViewAffiliates() {
        Apttus__APTS_Agreement__c objAgreement = [SELECT Id from Apttus__APTS_Agreement__c LIMIT 1];
        
        Test.startTest();       
        
        String strResult = OpenOfferAffiliationController.loadPage(objAgreement.Id);
        
        Test.stopTest();
        Map<String, Object> mapResponse = (Map<String, Object>) JSON.deserializeUntyped(strResult);
        Boolean boolComponentReadOnly = (Boolean) mapResponse.get('boolComponentReadOnly');
        List<Object> lstOpenOfferAffiliatesWrapper = (List<Object>) mapResponse.get('lstOpenOfferAffiliatesWrapper');

        System.assert(!boolComponentReadOnly, 'Component should not be read only');
        System.assert(!lstOpenOfferAffiliatesWrapper.isEmpty(), 'Affiliates data not returned');
    }

    @isTest
    static void testUpsertAffiliates() {
        Apttus__APTS_Agreement__c objAgreement = [SELECT Id from Apttus__APTS_Agreement__c LIMIT 1];
        List<Agreement_Account_Relationship__c> lstAgreementAccountRelationship = [SELECT Id, Account__c,Include_In_Annual_Consumable_Spend__c, Opt_In_Receiving_Open_Offer_Discount__c, Consider_for_GF_Discount_Calculation__c FROM Agreement_Account_Relationship__c WHERE Agreement__c = :objAgreement.Id];
        System.assert(!lstAgreementAccountRelationship.isEmpty(),'No Agreement Account Relationships found.');
        
        List<Object> lstAgreementAccountRelationshipForUpdate = new List<Object>();
        List<Object> lstAgreementAccountRelationshipForDelete = new List<Object>();
        
        Test.startTest();
        lstAgreementAccountRelationshipForUpdate.add(new Agreement_Account_Relationship__c(Id = lstAgreementAccountRelationship.get(0).Id, Include_In_Annual_Consumable_Spend__c = false ));
        lstAgreementAccountRelationshipForDelete.add(new Agreement_Account_Relationship__c(Id = lstAgreementAccountRelationship.get(0).Id));

        OpenOfferAffiliationController.upsertAffiliates(JSON.serialize(lstAgreementAccountRelationshipForUpdate), JSON.serialize(lstAgreementAccountRelationshipForDelete));
        
        Test.stopTest();
        List<Agreement_Account_Relationship__c> lstAgreementAccountRelationshipAfterUpdate = [SELECT Id, Account__c,Include_In_Annual_Consumable_Spend__c, Opt_In_Receiving_Open_Offer_Discount__c, Consider_for_GF_Discount_Calculation__c FROM Agreement_Account_Relationship__c WHERE Agreement__c = :objAgreement.Id];        
        System.assertEquals(0,lstAgreementAccountRelationshipAfterUpdate.size(), 'Update and Delete operation failed.');

    }
}
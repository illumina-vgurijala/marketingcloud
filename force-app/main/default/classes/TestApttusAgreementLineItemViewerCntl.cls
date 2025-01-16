/**
 *    @author Rahul Bishnoi
 *    @date   10-July-2020
 *    @description  Test class for ApttusAgreementLineItemViewerController
 *    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Rahul Bishnoi                 10-July-2020         Initial Version
*    Prem Ranjan                   04 May 2022          CodeScan Fix (APEX) Unused Local Variable 
*	 Maruthi						27-June-2022		Updated testgetRecords
*    Vishal Reddy                  30-Sep-2022          Created testExceptions to increase code coverage
*    Arif,Dalali                   28-Nov-2022          POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    ------------------------------------------------------------------------------------------------------------------------------------------------

 *
 */
@isTest
public with sharing class TestApttusAgreementLineItemViewerCntl {
    public static final string STRLINETYPEMATERIALGROUP = 'Material Group 1';
    public static final string STRDISCOUNTTYPE = '% Discount';
    public static final string STRPAGEREFERENCE = 'Page.PreviewSubmitApprovals';
    public static final string STRAPPROVER = 'Test Approver';

    @testSetup
    static void setupData() {
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '234567';
        acc.Account_Group__c = 'Distributor';
        
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '183456';
        insert new List<Account> { acc, acc2 };

        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '234567';
        objCMD2.ERP_Customer_Id__c = '183456';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };
        
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };

        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        //oAgreement1.Customer_Discount_Level__c = 'Price Group';
        oAgreement1.recordTypeId=recTypeId;
        insert oAgreement1;
        
        
        Apttus__AgreementLineItem__c oAgreementLI1 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLI1.Line_Type__c = STRLINETYPEMATERIALGROUP;
        oAgreementLI1.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI1.Discount_Type__c = STRDISCOUNTTYPE;
        oAgreementLI1.Discount__c=12.23;
        oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today()+5;
        oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+28;
        oAgreementLI1.Material_Group_1__c='AIM';
        oAgreementLI1.CurrencyIsoCode = 'USD';
        oAgreementLI1.Distribution_Channel__c = '02';
        oAgreementLI1.Customer_ERP_Number__c = '234567';
        oAgreementLI1.Sales_Org__c = 'US01';
        insert oAgreementLI1;
            
        
    }
    /*
    *@author: Rahul Bishnoi
    *@Desc: Test method to check getRecords
    */
    @isTest
    static void testgetRecords() {
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Test.starttest();        
        try{
            ApttusAgreementLineItemViewerController.getFilterRecords(objAgreement.id,'test',Integer.valueof(Label.LabelViewLinesLimit));
            String jsonObj = ApttusAgreementLineItemViewerController.getRecords(objAgreement.id,Integer.valueof(Label.LabelViewLinesLimit));
            AgreementLineWrapper listTemp = new AgreementLineWrapper();
            listTemp = (AgreementLineWrapper) System.JSON.deserialize(jsonObj, AgreementLineWrapper.class);		
            System.assert(!(listTemp.listAgreementLineItems.isEmpty()),'Agreement Lines Are Fetched');
        }catch(Exception e){
            System.debug('error message is : '+e.getMessage());
        }
        Test.stoptest();
    }

    /*
    *@author: Maruthi B
    *@Desc: Wrapper calss to get records for getRecords method for assert.
    */
    public class AgreementLineWrapper
    {
        public List<ApttusAgreementLineItemViewerController.agreementLineWrapper> listAgreementLineItems;
        String hasMoreLines;
    }
    /*
    *@author: Rahul Bishnoi
    *@Desc: Test method to check getAgreement
    */

    @isTest
    static void testgetAgreement() {
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Test.starttest();
        ApttusAgreementLineItemViewerController.checkSessionCache(objAgreement.id);
        Apttus__APTS_Agreement__c agrmt = ApttusAgreementLineItemViewerController.getAgreement();
        System.assertEquals(agrmt.id, objAgreement.id);
        Test.stoptest();
    }
    /*
    *@author: Rahul Bishnoi
    *@Desc: Test method to check getAgreementAura
    */

    @isTest
    static void testgetAgreementAura() {
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Test.starttest();
        Apttus__APTS_Agreement__c agrmt = ApttusAgreementLineItemViewerController.getAgreementAura(objAgreement.id);
        System.assertEquals(agrmt.id, objAgreement.id);
        Test.stoptest();
    }
    /*
    *@author: Vishal Reddy
    *@Desc: Test method to create exceptions
    */

    @isTest
    static void testExceptions() {
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Test.starttest();
        try{
            ApttusAgreementLineItemViewerController.catchExceptionGetFilterRecords = true;
            ApttusAgreementLineItemViewerController.getFilterRecords(objAgreement.id,'test',Integer.valueof(Label.LabelViewLinesLimit));		
            System.assert(!ApttusAgreementLineItemViewerController.catchExceptionGetFilterRecords, 'catchExceptionFilterRecords is still true');
        }
        catch(Exception e){
            System.debug('error message is : '+e.getMessage());
        }

        try{
            ApttusAgreementLineItemViewerController.catchExceptionFilterLogic = true;      
            ApttusAgreementLineItemViewerController.getFilterRecords(objAgreement.id,'test',Integer.valueof(Label.LabelViewLinesLimit));		
            //System.assert(!(listTemp.listAgreementLineItems.isEmpty()),'Agreement Lines Are Fetched'); no need for system.assert as this method raises exceptions
        }
        catch(Exception e){
            System.debug('error message is : '+e.getMessage());
        }
        
        try{
            ApttusAgreementLineItemViewerController.catchExceptiongetRecords = true;
            ApttusAgreementLineItemViewerController.getRecords(objAgreement.id,Integer.valueof(Label.LabelViewLinesLimit));
        }
        catch(Exception e){
            System.debug('error message is : '+e.getMessage());
        }

        try{
            ApttusAgreementLineItemViewerController.catchExceptionCheckSessionCache = true;
            ApttusAgreementLineItemViewerController.checkSessionCache(objAgreement.id);
        }
        catch(Exception e){
            System.debug('error message is : '+e.getMessage());
        }

        try{
            ApttusAgreementLineItemViewerController.catchExceptionGetAgreement = true;
            ApttusAgreementLineItemViewerController.getAgreement();
        }
        catch(Exception e){
            System.debug('error message is : '+e.getMessage());
        }
        
        try{
            ApttusAgreementLineItemViewerController.catchExceptionGetAgreementAura = true;
            ApttusAgreementLineItemViewerController.getAgreementAura(objAgreement.id);
        }
        catch(Exception e){
            System.debug('error message is : '+e.getMessage());
        }

        Test.stoptest();
    }

}
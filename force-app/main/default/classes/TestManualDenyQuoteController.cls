/**
*    @author      :Prem Ranjan
*    @date        :2022-09-23
*    @description :Test class for Manual Deny Quote
*    Modification Log:
*     ---------------------------------------------------------------------------------------------------------------------------
*         Developer                       Date                    Description         
*       Prem Ranjan                   14-Sep-2022               Initial Version
*       Pravallika, Gundreddy         28-nov-2022               POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*       Balakrishna                    27-July-2023             CMCM-803
*    ---------------------------------------------------------------------------------------------------------------------------
*
***/
@isTest(isParallel=false)
public with sharing class TestManualDenyQuoteController {

    /**
     *  @author Prem Ranjan
     *  @description Test Data Setup
     **/
    @testSetup
    static void setupData() {
        Account acc = TestDataAccount.initAccount();
        Account acc2 = TestDataAccount.initAccount();
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };

        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Pricebook2Id = standardPricebook.Id;
        opp.Price_List__c = '01-AMR-USD';
        insert opp;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        String strNone = 'None';
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, Label.QuoteStageDraft, strNone);
        Apttus_Proposal__Proposal__c proposal1 = TestDataProposal.initProposal(acc.id, opp.id, 'Proposal 1', priceList.id, true, Label.QuoteStageDraft, strNone);
        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp.id, 'Test New Proposal2', priceList.id, true, Label.QuoteStageDraft, strNone);
        insert new List<Apttus_Proposal__Proposal__c> { proposal, proposal1, proposal2 };
    }
    /**
     *  @author Prem Ranjan
     *  @description Test Positive sceniaro of ManualDenyQuoteController
     **/
    @isTest
    static void testManualDenyPositive() {
        List<Apttus_Proposal__Proposal__c> lstProposal =new List<Apttus_Proposal__Proposal__c>();
    	Apttus_Proposal__Proposal__c objProPosal = [Select id,Apttus_Proposal__Approval_Stage__c,SAP_Quote__c,Apttus_Proposal__Opportunity__c from Apttus_Proposal__Proposal__c limit 1];
        objProPosal.SAP_Quote__c ='123456';
        test.startTest();
                lstProposal.add(objProPosal);
                update lstProposal;
                system.assert(ManualDenyQuoteController.updateQuotationToDenied(lstProposal[0].id),'Return False');
        test.stopTest();
        List<Apttus_Proposal__Proposal__c> lstQuotation = [Select id,Apttus_Proposal__Approval_Stage__c from Apttus_Proposal__Proposal__c where id =:lstProposal[0].id];
        system.assertEquals(lstQuotation[0].Apttus_Proposal__Approval_Stage__c, Label.QuoteStageDenied, 'Stage not denied');
    }  
    /**
     *  @author Prem Ranjan
     *  @description Test Negative sceniaro of ManualDenyQuoteController
     **/
    @isTest
    static void testManualDenyNegative() {
    List<Apttus_Proposal__Proposal__c> lstProposal = [Select id,Apttus_Proposal__Approval_Stage__c from Apttus_Proposal__Proposal__c limit 1];
        test.startTest();
                User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FAST_TRACK_SERVICES);
                System.runAs(objUser) {
                    try {
                        ManualDenyQuoteController.updateQuotationToDenied(lstProposal[0].id);
                    } catch(Exception e) {
                        system.debug(e.getMessage());
                    }
                }
        test.stopTest();
        List<Apttus_Proposal__Proposal__c> lstQuotation = [Select id,Apttus_Proposal__Approval_Stage__c from Apttus_Proposal__Proposal__c where id =:lstProposal[0].id];
        system.assertEquals(lstQuotation[0].Apttus_Proposal__Approval_Stage__c, Label.QuoteStageDraft, 'Stage not Draft');
    }  
}
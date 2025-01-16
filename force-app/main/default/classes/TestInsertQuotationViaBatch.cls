/**
*    @author Satya Swain
*    @date   2020-01-28
*    @description  Test class for InsertQuotationViaBatch,Organizations
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Satya Swain                     2020-01-28         Initial Version
*            Pravallika, Gundreddy          28-nov-2022         POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*/
@isTest(SeeAllData=false isParallel=false)
public with sharing class TestInsertQuotationViaBatch {

    @testSetup
    static void setupData()
    {
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
    }

    /**
     *  @author Satya Swain
     *  @description Test method for Creating Quotes via Batch Class
     **/
    @istest
    static void createQuoteViaBatch()
    {
        Profile profile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(profile.Id);
        cs.Bypass_All_Validations__c = true;
        cs.Bypass_All_Triggers__c = true;
        upsert cs cs_Apex_Settings__c.Id;

        // call batch class
        Test.startTest();
        InsertQuotationViaBatch objBatch=new InsertQuotationViaBatch();
        Database.executeBatch(objBatch,10);
        // To increase coverage of Organizations class
        Organizations.isProductionUsingConstant();
        List<Organization> lstOrg=[select id from Organization];
        Organizations.Constructor obj=new Organizations.Constructor();
        obj.construct(lstOrg);
        Organizations objOrg=new Organizations(lstOrg);
        Test.stopTest();
        list<Apttus_Proposal__Proposal__c> lstQuotes=[select id from Apttus_Proposal__Proposal__c ];
        system.AssertEquals(10,lstQuotes.size());

    }

}
/**
*    @author Anand Palla
*    @date   15 Jun 2021
*    @description  DCP-46168: Send Email Alert
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*
*/
@isTest
public without sharing class TestEmailAlertforClosedWonOppty {
    
    private static final String CURRENT_QUARTER = 'Current Quarter';
    private static final String STRING_FINALIZE = 'finalize';

    @testSetup
    static void setupData()
    {
        Id recTypeTender = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Tender').getRecordTypeId();
        
        Account acc1 = TestDataAccount.getAccount('Account 1');
        acc1.BillingCountryCode = 'US';
        acc1.BillingStateCode = 'AK';
        acc1.Territory_Region__c = 'AMR';
        acc1.ERP_Customer_Id__c = '123456';
        insert acc1;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc1.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        insert acc1SalesArea;
        
        TestDataAgreement.addHierarchyPermission(UserInfo.getUserId());
        
        User testUser = [SELECT Id,Email from User Where Id =: UserInfo.getUserId() LIMIT 1];
        testUser.Email = 'invalid@illumina.com';
        update testUser;
        
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement 1', acc1.id);
        oAgreement1.Sales_Org__c = 'US01';
        oAgreement1.RecordTypeId = recTypeTender;
        oAgreement1.Freight_Charge__c = 'Standard';
        insert oAgreement1;
        
        
        Opportunity objOpp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        objOpp1.Related_Agreement__c = oAgreement1.Id;
        objOpp1.Fiscal_Quarter__c = CURRENT_QUARTER;
        objOpp1.CloseDate = Date.newinstance(Date.Today().Year() + 1, 3, 31);
        objOpp1.Name = 'Test Oppty';
        objOpp1.StageName = STRING_FINALIZE;
        objOpp1.Tender_Status__c = 'Future Tender';
        objOpp1.Sold_to_Sales_Organization__c = 'US01';
        insert objOpp1;
        
    }
    
    /* @author Anand Palla
     * @date   10-Jun-2021
     * @description DCP-46168
    **/
    public static testMethod void testEmailAlert(){
        Opportunity opp = [SELECT Id,StageName FROM Opportunity WHERE Name = 'Test Oppty' LIMIT 1];
        opp.StageName = 'Closed Won';
        update opp;

        system.assertEquals('Closed Won',opp.StageName,'Opportunity is not updated to Closed Won');
    }
}
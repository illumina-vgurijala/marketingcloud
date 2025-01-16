/**
 * @author Gopinath Reddy 
 * @date   14-Nov-2018
 * @description   Test class Mobile Create Quote
 * Modification Log:
 *  --------------------------------------------------------------------------------------------------
 *   Developer                Date                Description                                                  
 *   Gopinath Reddy          14-Nov-2018         Original Version
 * ---------------------------------------------------------------------------------------------------
 **/
@isTest(isParallel=true)
public class TestApttusMobileCreateQuote {
     @isTest
    static void mobileQuoteCreate(){
     
     Account acc1 = TestDataAccount.getAccount('Account 1');
     Account acc2 = TestDataAccount.getAccount('Account 2');
     acc2.Account_Group__c = 'Distributor';
        
     List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc1);
        lstAcc.add(acc2);
        insert lstAcc;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc1.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        acc1SalesArea.Company_Code__c = 'SE01';
        
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','179','00',false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Company_Code__c = 'US01';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea};
        System.debug('acc1SalesArea: '+acc1SalesArea);
        System.debug('acc2SalesArea: '+acc2SalesArea);
        
        
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Ultimate_Consignee__c = acc1.Id;
        opp2.Distributor__c = acc2.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = true;
        opp2.Are_Products_Added_by_Channel_Partner__c = true;
        lstOpportunity.add(opp1);
        lstOpportunity.add(opp2);
        insert lstOpportunity;
        
        Test.startTest();
        List<Opportunity> lstOpp =[select id from Opportunity ];
        
        System.debug('lstOpp : '+lstOpp);

        ApexPages.StandardController stdSetController = new ApexPages.StandardController(lstOpp.get(0));
        ApttusMobileCreateQuoteController quoteCOntroller = new ApttusMobileCreateQuoteController(stdSetController);
        System.assertNotEquals(null, lstOpp.size());
        test.stopTest();
        
    }

}
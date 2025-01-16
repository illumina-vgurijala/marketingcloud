/*@ author       : Sudarshan
* @ date         : 12-04-2023
* @ Description  : Test class for TradeInProductsSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer          Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Sudarshan          12-04-2023              CMCM-1354           Initial version 
*/
@IsTest(SeeAllData=false)
public class TestTradeInProductsSelector{
    private static final String TEST_NAME = 'test';
    private static final String TEST_NAME_2 = 'test2'; 

    @TestSetup
    static void makeData(){
        Account acc = TestDataAccount.initAccount();
        acc.Name = TEST_NAME;
        insert acc;

        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct(TEST_NAME, 'USD', 'New');
        SVMXC__Installed_Product__c ip2 = TestDataFieldService.createInstalledProduct(TEST_NAME_2, 'USD', 'New');
        insert new List<SVMXC__Installed_Product__c> {ip, ip2};

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Name = TEST_NAME;
        opp.RecordTypeName__c = 'Direct';
        opp.Sold_to_Distribution_Channel__c = 'Direct';
        opp.Transborder_Flag__c = true;
        opp.Price_List__c = priceList.Name;
        opp.Type = System.Label.OpportunityTypeConsortium;
        insert opp;

        Apttus_Proposal__Proposal__c quote = TestDataProposal.initProposal(acc.id, opp.id, TEST_NAME, priceList.id, true, 'Draft', 'None');
        insert quote;

        Trade_In_Product__c tip = new Trade_In_Product__c(
            Account__c = acc.id,
            Installed_Product__c = ip2.id,
            Quote_Proposal__c = quote.id
        );
        insert tip;
    }
    /**
     * @description: Test method for selectTradeInProductsForQuotes()
     */
    static testmethod void testSelectTradeInProductsForQuotes() { 
        Id quoteId = [SELECT id from Apttus_Proposal__Proposal__c limit 1].Id;
        Set<Id> quoteIds = new Set<Id>();
        quoteIds.add(quoteId);
        test.startTest();  
        List<Trade_In_Product__c> tiList = new TradeInProductsSelector().selectTradeInProductsForQuotes(quoteIds); 
        System.assertEquals(1, tiList.size(),'testSelectTradeInProductsForQuotes');  
        test.stopTest();
    }
    
}
/* @ author      :  Akash Kumar
* @ date         :  26-SEP-2024
* @ Description  :  Test Class For SalesMarginDataCalculationService, DGP-1176
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                 Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akash Kumar         26-SEP-2024             Initial version
* Akash Kumar         26-SEP-2024              DGP-942
*/
@isTest
private class TestSalesMarginDataCalculationService {
    
    //Setup Test Data
    @TestSetup
    static void setupData(){
        Account acc = TestDataAccount.getAccount('Account 4');
        acc.BillingCountryCode = 'US';
        acc.BillingStateCode = 'AK';
        acc.ERP_Customer_Id__c = '567891';
        acc.Account_Group__c = 'Sold To';
        
        insert new List<Account>{acc};

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert new List<Apttus_Config2__PriceList__c> {priceList};

        Opportunity objOpp = TestDataOpportunity.initOpportunity(acc);
        objOpp.Price_List__c = priceList.Name;
        insert new List<Opportunity> {objOpp};

        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, objOpp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert new List<Apttus_Proposal__Proposal__c> {proposal};

        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.initCart(proposal);
        insert new List<Apttus_Config2__ProductConfiguration__c> {testCart};

        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProduct.End_Of_Sale_Date__c =Date.today();
        objProduct.End_Of_Service_Date__c =Date.today().addDays(90);
        
        Product2 objProductTwo = TestDataMaster.createProduct(false);
        objProductTwo.Material_Class__c = Label.ProductMaterialClassServices;

        Product2 objProductThree = TestDataMaster.createProduct(false);
        objProductThree.Material_Class__c = Label.OpportunityProductTypeInformaticsSoftware;
        objProductThree.End_Of_Sale_Date__c =Date.today()-1;
        objProductThree.End_Of_Service_Date__c =Date.today()-1;
        
        insert new List<Product2> {objProduct, objProductTwo, objProductThree};
    }

    //Test method to test margin analysis for Direct Scenarios
    @isTest
    static void testMarginAnalysisForDirect(){

        Double marginAtListPriceForDirect = 0;
        Double marginAtHistoricPriceForDirect = 0;
        Double marginAtQuoteProposedPriceForDirect = 0;
        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> lstProduct = [Select id FROM Product2 LIMIT 3];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c WHERE Name ='Product Config - test'];  
        productConfig.Apttus_Config2__Status__c = Label.ConfigurationStatusFinalized;
        update productConfig;

        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(lstProposal[0], lstProduct[0]);
        proposalLineItem.Apttus_QPConfig__Quantity2__c = 10;
        proposalLineItem.Customer_Historical_Discount__c = 10;
        proposalLineItem.Total_Discount_Percentage__c = 20; 
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        proposalLineItem.Apttus_QPConfig__StartDate__c = Date.newInstance(2024, 9, 17);
        proposalLineItem.Apttus_QPConfig__EndDate__c = Date.newInstance(2025, 9, 16);
        
        insert new List<Apttus_Proposal__Proposal_Line_Item__c> {proposalLineItem};

        Test.startTest();
        Apttus_Proposal__Proposal_Line_Item__c objLineItem = [SELECT 
                                                              Id,
                                                              Name,
                                                              Apttus_QPConfig__Quantity2__c,
                                                              Customer_Historical_Discount__c,
                                                              Total_Discount_Percentage__c,
                                                              Apttus_QPConfig__ConfigurationId__c,
                                                              Apttus_QPConfig__StartDate__c,
                                                              Apttus_QPConfig__EndDate__c,
                                                              Term_Months__c
                                                              FROM Apttus_Proposal__Proposal_Line_Item__c
                                                              WHERE Apttus_Proposal__Proposal__c =:lstProposal[0].Id AND
                                                              Apttus_Proposal__Product__c =:lstProduct[0].Id];
        
        marginAtListPriceForDirect = SalesMarginDataCalculationService.calculateStandardMarginAtListPricePercentage(objLineItem,
                                                                                            double.valueOf(1000.00),
                                                                                            True,
                                                                                            False,
                                                                                            Label.Direct_Quote,
                                                                                            15);
        	
        marginAtListPriceForDirect = SalesMarginDataCalculationService.calculateStandardMarginAtListPricePercentage(objLineItem,
                                                                                            double.valueOf(2000.00),
                                                                                            False,
                                                                                            True,
                                                                                            Label.Direct_Quote,
                                                                                            20);
        
        marginAtHistoricPriceForDirect = SalesMarginDataCalculationService.calculateStandardMarginAtHistoricDiscountPercent(objLineItem,
                                                                                            double.valueOf(1000.00),
                                                                                               False,
                                                                                               True,
                                                                                               Label.Direct_Quote,
                                                                                               25);

        SalesMarginDataCalculationService.calculateStandardMarginAtHistoricDiscountPercent(objLineItem,
                                                                                               double.valueOf(1000.00),
                                                                                               True,
                                                                                               False,
                                                                                               Label.Direct_Quote,
                                                                                               30);
        
        
        marginAtQuoteProposedPriceForDirect = SalesMarginDataCalculationService.calculateStandardMarginAtQuoteProposedPricePercent(objLineItem,
                                                                                                   double.valueOf(1000.00),
                                                                                                   False,
                                                                                                   True,
                                                                                                   Label.Direct_Quote,
                                                                                                   35);

        SalesMarginDataCalculationService.calculateStandardMarginAtQuoteProposedPricePercent(objLineItem,
                                                                                                   double.valueOf(1000.00),
                                                                                                   True,
                                                                                                   False,
                                                                                                   Label.Direct_Quote,
                                                                                                   40);
        
        Test.stopTest();
        Assert.isNotNull(marginAtListPriceForDirect, 'Çalculation Error');
        Assert.isNotNull(marginAtHistoricPriceForDirect, 'Çalculation Error');
        Assert.isNotNull(marginAtQuoteProposedPriceForDirect, 'Çalculation Error');
        
    }
    
    //Test method to test margin analysis for InDirect Scenarios
    @isTest
    static void testMarginAnalysisForInDirect(){
        Double marginAtListPriceForInDirect = 0;
        Double marginAtHistoricPriceForInDirect = 0;
        Double marginAtQuoteProposedPriceForInDirect = 0;
        List<Apttus_Proposal__Proposal__c> lstProposal = [Select id FROM Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> lstProduct = [Select id FROM Product2 LIMIT 3];
        Apttus_Config2__ProductConfiguration__c productConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c WHERE Name ='Product Config - test'];  
        productConfig.Apttus_Config2__Status__c = Label.ConfigurationStatusFinalized;
        update productConfig;
        
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(lstProposal[0], lstProduct[1]);
        proposalLineItem.Apttus_QPConfig__Quantity2__c = 20;
        proposalLineItem.Distributor_Specific_Discount_Percentage__c = 10;
        proposalLineItem.Customer_Historical_Discount__c = 5;
        proposalLineItem.Total_Discount_Percentage__c = 15; 
        proposalLineItem.Apttus_QPConfig__ConfigurationId__c = productConfig.id;
        proposalLineItem.Apttus_QPConfig__StartDate__c = Date.newInstance(2024, 9, 17);
        proposalLineItem.Apttus_QPConfig__EndDate__c = Date.newInstance(2025, 9, 16);

        insert new List<Apttus_Proposal__Proposal_Line_Item__c> {proposalLineItem};

        Test.startTest();
        Apttus_Proposal__Proposal_Line_Item__c objLineItem = [SELECT 
                                                              Id,
                                                              Name,
                                                              Apttus_QPConfig__Quantity2__c,
                                                              Customer_Historical_Discount__c,
                                                              Distributor_Specific_Discount_Percentage__c,
                                                              Total_Discount_Percentage__c,
                                                              Apttus_QPConfig__ConfigurationId__c,
                                                              Apttus_QPConfig__StartDate__c,
                                                              Apttus_QPConfig__EndDate__c,
                                                              Term_Months__c
                                                              FROM Apttus_Proposal__Proposal_Line_Item__c
                                                              WHERE Apttus_Proposal__Proposal__c =:lstProposal[0].Id AND
                                                              Apttus_Proposal__Product__c =:lstProduct[1].Id];
        
            
        marginAtListPriceForInDirect = SalesMarginDataCalculationService.calculateStandardMarginAtListPricePercentage(objLineItem,
                                                                                            double.valueOf(1000.00),
                                                                                            True,
                                                                                            False,
                                                                                            Label.Indirect_Quote,
                                                                                            15);
        	
        marginAtListPriceForInDirect = SalesMarginDataCalculationService.calculateStandardMarginAtListPricePercentage(objLineItem,
                                                                                            double.valueOf(2000.00),
                                                                                            False,
                                                                                            True,
                                                                                            Label.Indirect_Quote,
                                                                                            20);
        
        marginAtHistoricPriceForInDirect = SalesMarginDataCalculationService.calculateStandardMarginAtHistoricDiscountPercent(objLineItem,
                                                                                               double.valueOf(1000.00),
                                                                                               False,
                                                                                               True,
                                                                                               Label.Indirect_Quote,
                                                                                               25);

        SalesMarginDataCalculationService.calculateStandardMarginAtHistoricDiscountPercent(objLineItem,
                                                                                               double.valueOf(1000.00),
                                                                                               True,
                                                                                               False,
                                                                                               Label.Indirect_Quote,
                                                                                               30);
        
        marginAtQuoteProposedPriceForInDirect = SalesMarginDataCalculationService.calculateStandardMarginAtQuoteProposedPricePercent(objLineItem,
                                                                                               double.valueOf(1000.00),
                                                                                               False,
                                                                                               True,
                                                                                               Label.Indirect_Quote,
                                                                                               35);

        SalesMarginDataCalculationService.calculateStandardMarginAtQuoteProposedPricePercent(objLineItem,
                                                                                               double.valueOf(1000.00),
                                                                                               True,
                                                                                               False,
                                                                                               Label.Indirect_Quote,
                                                                                               40);
        
        Test.stopTest();
        Assert.isNotNull(marginAtListPriceForInDirect, 'Çalculation Error');
        Assert.isNotNull(marginAtHistoricPriceForInDirect, 'Çalculation Error');
        Assert.isNotNull(marginAtQuoteProposedPriceForInDirect, 'Çalculation Error');

	}
}
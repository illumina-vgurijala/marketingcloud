/*
 * Test class for ApttusProductConfiguration Class
      Developer                  Date              Description
*        
*    ------------------------------------------------------------------------------------
*      Arqimidez Mora           23-Aug-2024        CMCM-9986 Added new methods migrated from process builder
 */
@isTest
public with sharing class TestApttusProductConfiguration {
    
    @testSetup
    static void setupData()
    {
        Account a = TestDataAccount.getNewAccount();
        Account a1 = TestDataAccount.getCustomerAccount(); 
        insert a1;

        TestDataPerson.getNewContact(a1.Id);

        Apttus_Config2__PriceList__c objPriceLis1 = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceLis1;

        Apttus_Config2__PriceList__c objPriceLis2 = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceLis2;

        Opportunity objOpportunity1 = TestDataOpportunity.initOpportunity(a);
        objOpportunity1.Ultimate_Consignee__c = a.Id;
        objOpportunity1.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity1.Price_List__c = objPriceLis1.Name;
        insert objOpportunity1;

        Opportunity objOpportunity2 = TestDataOpportunity.initOpportunity(a);
        objOpportunity2.Ultimate_Consignee__c = a.Id;
        objOpportunity2.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity2.Price_List__c = objPriceLis2.Name;
        insert objOpportunity2;

        TestDataProposal.getNewProposal(a1.Id, objOpportunity1.Id, 'Test Proposal 1', objPriceLis1.Id, true, 'Draft', 'None');
        TestDataProposal.getNewProposal(a1.Id, objOpportunity2.Id, 'Test Proposal 2', objPriceLis2.Id, true, 'Draft', 'None');
    }

    static testMethod void testIsClone(){
        Datetime dateTimeNow = datetime.now();
        List<Apttus_Proposal__Proposal__c> lstQuotation = [SELECT Id, Cloned_From__c, Apttus_QPConfig__PricingDate__c FROM Apttus_Proposal__Proposal__c ORDER BY Name DESC LIMIT 2];
        Apttus_Proposal__Proposal__c objQuote1 = lstQuotation[0];
        Apttus_Proposal__Proposal__c objQuote2 = lstQuotation[1];

        Apttus_Config2__ProductConfiguration__c objProductConfig1 = TestDataProposal.initCart(objQuote2);
        insert objProductConfig1;

        Apttus_Config2__ProductConfiguration__c objProductConfig2 = TestDataProposal.initCart(objQuote1);
        Test.startTest();

        objQuote1.Cloned_From__c = objQuote2.Id;
        objQuote1.Apttus_QPConfig__PricingDate__c = dateTimeNow;
        update objQuote1;

        objProductConfig2.Apttus_QPConfig__Proposald__c = objQuote1.Id;
        objProductConfig2.Apttus_Config2__AncestorId__c = objProductConfig1.Id;
        objProductConfig2.Apttus_Config2__VersionNumber__c = 1;
        insert objProductConfig2;

        Test.stopTest();

        Apttus_Config2__ProductConfiguration__c objProductConfigResult = [SELECT Id, Apttus_Config2__EffectiveDate__c, Apttus_Config2__ExpectedStartDate__c FROM Apttus_Config2__ProductConfiguration__c WHERE Id = :objProductConfig2.Id];
        System.assertEquals(objProductConfigResult.Apttus_Config2__EffectiveDate__c, dateTimeNow, '*** Error updating Product Configuration');
        System.assertEquals(objProductConfigResult.Apttus_Config2__ExpectedStartDate__c, dateTimeNow.date(), '*** Error updating Product Configuration');
    }

    static testMethod void testByPassSynToOpportunity(){
        Apttus_Proposal__Proposal__c objQuotation = [SELECT Id, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Primary__c FROM Apttus_Proposal__Proposal__c LIMIT 1];

        Apttus_Config2__ProductConfiguration__c objProductConfig = TestDataProposal.initCart(objQuotation);
        Product2 objProduct = TestDataMaster.initProduct('Cookie');
        insert objProduct;
        PricebookEntry objProceBookEntry = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
        OpportunityLineItem objOpportunityLineItem = TestDataMaster.createOpportunityProduct(objQuotation.Apttus_Proposal__Opportunity__c, objProceBookEntry.Id, true);

        Test.startTest();

        objQuotation.Apttus_Proposal__Primary__c = true;
        update objQuotation;
        
        objProductConfig.Apttus_QPConfig__Proposald__c = objQuotation.Id;
        objProductConfig.Estimated_Freight__c = 1100;
        objProductConfig.Estimated_Tax__c = 1200;
        objProductConfig.Promotion_JSON__c = 'Test Promotion JSON';
        objProductConfig.SAP_Errors__c = 'Test SAP Errors';
        objProductConfig.SAP_Promotion__c = 'Test SAP Promotion';
        objProductConfig.Sub_Total__c = 1300;
        objProductConfig.Total_Discount__c = 900;
        objProductConfig.Total_Net__c = 400;
        insert objProductConfig;

        objProductConfig.Apttus_Config2__Status__c = 'Finalized';
        update objProductConfig;

        Test.stopTest();

        Apttus_Proposal__Proposal__c objQuotationResult = [SELECT Id, SAP_Errors__c, Total_Discount__c, Estimated_Freight__c FROM Apttus_Proposal__Proposal__c WHERE Id = :objQuotation.Id];
        OpportunityLineItem objOpportunityLineResult = [SELECT Id, By_Pass_Sync_To_Opportunity__c FROM OpportunityLineItem WHERE Id = :objOpportunityLineItem.Id];
        System.assertEquals('Test SAP Errors', objQuotationResult.SAP_Errors__c, '*** Error updating Proposal');
        System.assertEquals(900, objQuotationResult.Total_Discount__c, '*** Error updating Proposal');
        System.assertEquals(1100, objQuotationResult.Estimated_Freight__c, '*** Error updating Proposal');
        System.assert(true, objOpportunityLineResult.By_Pass_Sync_To_Opportunity__c);
    }
}
/**
*    @author Gopinath Reddy
*    @date   2018-09-17
*    @description  Test class for ApttusAssetLineItemCallBack
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Gopinath Reddy                   17-09-2018              Original method 
*/
@isTest(SeeAllData=false isParallel=false)
public class TestApttusAssetLineItemCallBack {

    @testSetup
    static void setupData()
    {
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccountUC = TestDataAccount.getUCAccount();
        insert objAccountUC;
        TestDataPerson.getNewContact(objAccount.Id);

        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceList;

        Product2 objProduct = TestDataMaster.initProduct('Cookie');
        objProduct.Material_Class__c = 'Instrument';
        insert objProduct;

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        objOpportunity.Ultimate_Consignee__c = objAccountUC.Id;
        objOpportunity.RecordTypeName__c = 'Direct';
        objOpportunity.Type = 'Upsell with Service Contract Renewal';
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Price_List__c = objPriceList.Name;
        insert objOpportunity;

        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataProposal.initPriceListItem(objProduct, objPriceList);
        insert objPriceListItem;

        TestDataApttusAsset.getNewExpiredAssetLineItem(objAccount.Id, objAccountUC.Id, objProduct.Id);

        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        objProposal.Ultimate_Consignee__c = objAccountUC.Id;
        insert objProposal;

        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = objProposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);
    }

    @isTest
    static void startAssetLineItemCallback()
    {
        Account thisAcc = [SELECT Id FROM Account Limit 1];

        Apttus_Config2__AssetLineItem__c thisAssetLineItem = [SELECT Id, Ultimate_Consignee__c FROM Apttus_Config2__AssetLineItem__c Limit 1];

        Apttus_Config2__ProductConfiguration__c newCart = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c Limit 1];
        Test.startTest();
        {
            ApttusAssetLineItemCallBack newAssetCallBack = new ApttusAssetLineItemCallBack();
            String assetSearchFilter = null;
            List<String> assetSearchScope = null;

            Apttus_Config2.CustomClass.ActionParams params = new Apttus_Config2.CustomClass.ActionParams();
            params.AccountId = thisAcc.Id;

            Apttus_Config2.CallbackTester.testAssetLineItemCallback(newCart.Id, assetSearchFilter, assetSearchScope, newAssetCallBack, params);
        }
        Test.stopTest();

        System.assertNotEquals(null, thisAssetLineItem.Ultimate_Consignee__c);
    }

}
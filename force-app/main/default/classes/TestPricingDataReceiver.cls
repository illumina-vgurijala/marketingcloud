/**
 * @author Akshay Mohan
 * @date   2018-06-26
 * @description    US-1101:  List Price Synchronization to DCP (INT_O-020-002)
 *
 * Modification Log:
 * -----------------
 * Akshay Mohan        27/06/2018   : Comments Updated    Original Version
 * Jitesh Lakhwani     09-Nov-2022  : Added test coverage for Price Book Entry
 * -----------------
 */
@isTest()
public class TestPricingDataReceiver {

    @testSetup
    static void setData()
    {
        Product2 pr = new Product2();
        pr.Name = 'DummyProduct';
        pr.ProductCode = '15045005';
        pr.IsActive = true;
        insert pr;

        //New Product added to cover price book entry scenario
        Product2 pr1 = new Product2();
        pr1.Name = 'Product PEB';
        pr1.ProductCode = '45379806';
        pr1.IsActive = true;
        insert pr1;

        //Update standard price book for price book entries
        Pricebook2 priceBookObj = new Pricebook2(

            Id = Test.getStandardPricebookId(),
            IsActive = true
        );

        update priceBookObj;

        //created existing price book entries to cover scenario
        List<PricebookEntry> pebList = new List<PricebookEntry>();
        PricebookEntry newPriceBookEntryObj1 = new PricebookEntry(
            UnitPrice = 0, 
            CurrencyIsoCode = 'EUR', 
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = pr.Id,
            IsActive = true
        );
        pebList.add(newPriceBookEntryObj1);

    PricebookEntry newPriceBookEntryObj2 = new PricebookEntry(
            UnitPrice = 0, 
            CurrencyIsoCode = 'AUD', 
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = pr.Id,
            IsActive = true
        );
        pebList.add(newPriceBookEntryObj2);
        insert pebList;
    }

    static testMethod void testPricingInsertHTTPPost()
    {
        List<PricingWrapper.priceList> plRecordsWithPliRecords = new List<PricingWrapper.priceList>();

        List<PricingWrapper.PriceListItems> pliList1= new List<PricingWrapper.PriceListItems>();
        List<PricingWrapper.PriceListItems> pliList2= new List<PricingWrapper.PriceListItems>();

        PricingWrapper.PriceListItems pliRecord1 = new PricingWrapper.PriceListItems();
        pliRecord1.ProductId = '15045005';
        pliRecord1.EffectiveDate = '2018-06-23';
        pliRecord1.ExpirationDate = '2018-10-23';
        pliRecord1.IsActive = 'Y';
        pliRecord1.PriceUom = 'Each';
        pliRecord1.ListPrice = '9.0';
        pliRecord1.PriceType = 'Recurring';
        pliRecord1.PriceListItemExternalId = 'pliunique1';
        pliRecord1.CurrencyIsoCode = 'USD'; // updated for Price Book Entries
        pliList1.add(pliRecord1);

        PricingWrapper.PriceListItems plirecord2 = new PricingWrapper.PriceListItems ();
        pliRecord2.ProductId = '15045005';
        pliRecord2.EffectiveDate = '2018-06-24';
        pliRecord2.ExpirationDate = '2018-10-24';
        pliRecord2.IsActive = 'Y';
        pliRecord2.PriceUom = 'Each';
        pliRecord2.ListPrice = '10.0';
        pliRecord2.PriceType = 'Recurring';
        pliRecord2.PriceListItemExternalId = 'pliunique2';
        pliRecord2.CurrencyIsoCode = 'USD'; // updated for Price Book Entries
        pliList1.add(pliRecord2);

        //Price List Item for Price Book Entry
        PricingWrapper.PriceListItems plirecordPEB = new PricingWrapper.PriceListItems ();
        plirecordPEB.ProductId = '45379806';
        plirecordPEB.EffectiveDate = '2018-06-24';
        plirecordPEB.ExpirationDate = '2018-10-24';
        plirecordPEB.IsActive = 'Y';
        plirecordPEB.PriceUom = 'Each';
        plirecordPEB.ListPrice = '10.0';
        plirecordPEB.PriceType = 'Recurring';
        plirecordPEB.PriceListItemExternalId = 'pliuniquePEB';
        plirecordPEB.CurrencyIsoCode = 'USD'; 
        pliList1.add(plirecordPEB);

        PricingWrapper.PriceListItems pliRecord3 = new PricingWrapper.PriceListItems();
        pliRecord3.ProductId = '15045005';
        pliRecord3.EffectiveDate = '2018-6-25';
        pliRecord3.ExpirationDate = '2018-10-25';
        pliRecord3.IsActive = 'Y';
        pliRecord3.PriceUom = 'Each';
        pliRecord3.ListPrice = '11.0';
        pliRecord3.PriceType = 'Recurring';
        pliRecord3.CurrencyIsoCode = 'USD'; // updated for Price Book Entries
        pliRecord3.PriceListItemExternalId = 'pliunique3';
        pliList2.add(pliRecord3);

        PricingWrapper.PriceListItems pliRecord4 = new PricingWrapper.PriceListItems ();
        pliRecord4.ProductId = '15045005';
        pliRecord4.EffectiveDate = '2018-06-26';
        pliRecord4.ExpirationDate = '2018-10-26';
        pliRecord4.IsActive = 'Y';
        pliRecord4.PriceUom = 'Each';
        pliRecord4.ListPrice = '12.0';
        pliRecord4.PriceType = 'Recurring';
        pliRecord4.CurrencyIsoCode = 'USD'; // updated for Price Book Entries
        pliRecord4.PriceListItemExternalId = 'pliunique4';
        pliList2.add(pliRecord4);


        PricingWrapper.PriceList plRecords1 = new PricingWrapper.PriceList();
        plRecords1.Name = 'TestPriceList1';
        plRecords1.PriceListExternalId = 'plunique1';
        plRecords1.priceListItems = new List<PricingWrapper.PriceListItems>();
        plRecords1.priceListItems.addAll(pliList1);
        plRecordsWithPliRecords.add(plRecords1);

        PricingWrapper.PriceList plRecords2 = new PricingWrapper.PriceList ();
        plRecords2.Name = 'TestPriceList1';
        plRecords2.PriceListExternalId = 'plunique2';
        plRecords2.priceListItems = new List<PricingWrapper.PriceListItems>();
        plRecords2.priceListItems.addAll(pliList2);
        plRecordsWithPliRecords.add(plRecords2);

        PricingWrapper pw = new PricingWrapper();
        pw.priceList = new List<PricingWrapper.PriceList>();
        pw.priceList.addAll(plRecordsWithPliRecords);

        String pricingJSON = JSON.serialize(pw);

        RestResponse res;
        Test.startTest();
        {
            RestRequest req = new RestRequest();
            res = new RestResponse();
            req.requestURI = '/services/apexrest/PricingSyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(pricingJSON);
            RestContext.request = req;
            RestContext.response = res;
            PricingDataReceiver.upsertIncomingValues();
        }
        Test.stopTest();

        System.assertEquals(200, res.StatusCode);

        List<Apttus_Config2__PriceListItem__c> pliRecords = [SELECT Id, Apttus_Config2__ProductId__r.ProductCode FROM Apttus_Config2__PriceListItem__c];
        System.assertEquals(5, pliRecords.size());
        System.assertEquals('15045005', pliRecords[0].Apttus_Config2__ProductId__r.ProductCode);

        System.assertEquals(2, [SELECT count() FROM Apttus_Config2__PriceList__c]);

        List<PricebookEntry> pebList = [SELECT id, CurrencyIsoCode, Pricebook2Id, ProductCode FROM priceBookEntry]; 

        System.assertEquals(4, pebList.size(), 'Price Book Entries inserted');
    }

    static testMethod void testPricingUpdateHTTPPost()
    {
        Apttus_Config2__PriceList__c pl = new Apttus_Config2__PriceList__c();
        pl.Name = 'priceListUpdated';
        pl.External_Id__c = 'plunique1';
        insert pl;

        //New product added to cover price book entry test class DCP58381
        Product2 prdTemp = new Product2();
        prdTemp.Name = 'Product PEB';
        prdTemp.ProductCode = '45379844';
        prdTemp.IsActive = true;
        insert prdTemp;

        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__ProductId__c = prdTemp.Id; // updated for DCP58381 Price Book Entry Coverage
        pli.External_Id__c = 'pliunique1';
        pli.Apttus_Config2__Active__c = false;
        pli.Apttus_Config2__PriceListId__c = pl.id; 
        insert pli;

        List<PricingWrapper.priceList> plRecordsWithPliRecords= new List<PricingWrapper.priceList>();
        List<PricingWrapper.PriceListItems> pliList1= new List<PricingWrapper.PriceListItems>();
        List<PricingWrapper.PriceListItems> pliList2= new List<PricingWrapper.PriceListItems>();

        PricingWrapper.PriceListItems pliRecord1 = new PricingWrapper.PriceListItems();
        pliRecord1.ProductId = '15045005';
        pliRecord1.EffectiveDate = '2018-06-23';
        pliRecord1.ExpirationDate = '2018-10-23';
        pliRecord1.IsActive = 'Y';
        pliRecord1.PriceUom = 'Each';
        pliRecord1.ListPrice = '9.0';
        pliRecord1.PriceType = 'Recurring';
        pliRecord1.CurrencyIsoCode = 'USD'; // updated for Price Book Entries
        pliRecord1.PriceListItemExternalId = 'pliunique1';
        pliList1.add(pliRecord1);

        PricingWrapper.PriceListItems plirecord2 = new PricingWrapper.PriceListItems ();
        pliRecord2.ProductId = '15045005';
        pliRecord2.EffectiveDate = '2018-06-24';
        pliRecord2.ExpirationDate = '2018-10-24';
        pliRecord2.IsActive = 'Y';
        pliRecord2.PriceUom = 'Each';
        pliRecord2.ListPrice = '10.0';
        pliRecord2.PriceType = 'Recurring';
        pliRecord2.CurrencyIsoCode = 'USD'; // updated for Price Book Entries
        pliRecord2.PriceListItemExternalId = 'pliunique2';
        pliList1.add(pliRecord2);

        PricingWrapper.PriceListItems pliRecord3 = new PricingWrapper.PriceListItems();
        pliRecord3.ProductId = '15045005';
        pliRecord3.EffectiveDate = '2018-6-25';
        pliRecord3.ExpirationDate = '2018-10-25';
        pliRecord3.IsActive = 'Y';
        pliRecord3.PriceUom = 'Each';
        pliRecord3.ListPrice = '11.0';
        pliRecord3.PriceType = 'Recurring';
        pliRecord3.CurrencyIsoCode = 'USD'; // updated for Price Book Entries
        pliRecord3.PriceListItemExternalId = 'pliunique3';
        pliList2.add(pliRecord3);

        PricingWrapper.PriceListItems pliRecord4 = new PricingWrapper.PriceListItems ();
        pliRecord4.ProductId = '15045005';
        pliRecord4.EffectiveDate = '2018-06-26';
        pliRecord4.ExpirationDate = '2018-10-26';
        pliRecord4.IsActive = 'Y';
        pliRecord4.PriceUom = 'Each';
        pliRecord4.ListPrice = '12.0';
        pliRecord4.PriceType = 'Recurring';
        pliRecord4.CurrencyIsoCode = 'USD'; // updated for Price Book Entries
        pliRecord4.PriceListItemExternalId = 'pliunique4';
        pliList2.add(pliRecord4);

        PricingWrapper.PriceList plRecords1 = new PricingWrapper.PriceList();
        plRecords1.Name = 'TestPriceList1';
        plRecords1.PriceListExternalId = 'plunique1';
        plRecords1.priceListItems = new List<PricingWrapper.PriceListItems>();
        plRecords1.priceListItems.addAll(pliList1);
        plRecordsWithPliRecords.add(plRecords1);

        PricingWrapper.PriceList plRecords2 = new PricingWrapper.PriceList ();
        plRecords2.Name = 'TestPriceList1';
        plRecords2.PriceListExternalId = 'plunique2';
        plRecords2.priceListItems = new List<PricingWrapper.PriceListItems>();
        plRecords2.priceListItems.addAll(pliList2);
        plRecordsWithPliRecords.add(plRecords2);

        PricingWrapper pw = new PricingWrapper();
        pw.priceList = new List<PricingWrapper.PriceList>();
        pw.priceList.addAll(plRecordsWithPliRecords);

        String pricingJSON = JSON.serialize(pw);
        System.debug('pricingJSON :::::'+pricingJSON );

        RestResponse res;
        Test.startTest();
        {
            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest();
            res = new RestResponse();

            req.requestURI = '/services/apexrest/PricingSyncInterface';
            req.httpMethod = 'POST';

            req.requestBody = Blob.valueof(pricingJSON);
            RestContext.request = req;
            RestContext.response = res;
            PricingDataReceiver.upsertIncomingValues();
        }
        Test.stopTest();

        System.assertEquals(200, res.StatusCode);

        Apttus_Config2__PriceListItem__c pliRecord = [SELECT id,Apttus_Config2__Active__c, Apttus_Config2__ProductId__r.ProductCode
            FROM Apttus_Config2__PriceListItem__c
            WHERE External_Id__c = 'pliunique1'];
        System.assertEquals(true, pliRecord.Apttus_Config2__Active__c);
        System.assertEquals('15045005', pliRecord.Apttus_Config2__ProductId__r.ProductCode);

        Apttus_Config2__PriceList__c plRecord = [SELECT Id, Name FROM Apttus_Config2__PriceList__c WHERE External_Id__c = 'plunique1'];
        System.assertEquals('TestPriceList1', plRecord.Name);
    }

}
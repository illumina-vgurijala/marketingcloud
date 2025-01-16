@isTest
private class TestBatchStagedPLItems {

//    private static Date pastDate = Date.today() - 10;
//    private static Date futureDate = Date.today() + 10;
//
//    @isTest static void renewableField()
//    {
//        // product setup
//        Product2 p1 = TestDataMaster.getNewProduct('Cookie');
//        Product2 p2 = TestDataMaster.getNewProduct('Cookie_Service');
//        Product_Sales_Area__c psa1 = TestDataMaster.initProductSalesArea(p1.Id);
//        Product_Sales_Area__c psa2 = TestDataMaster.initProductSalesArea(p2.Id);
//        Product_Sales_Area__c psa3 = TestDataMaster.initProductSalesArea(p2.Id);
//        psa2.Category_Group__c = Products.CATEGORY_GROUP_SAP_RENEWABLE_CODE;
//        psa3.Category_Group__c = Products.CATEGORY_GROUP_SAP_RENEWABLE_CODE;
//        insert new List<Product_Sales_Area__c> {psa1, psa2, psa3};
//
//        // account setup
//        Account a = TestDataAccount.getNewAccount();
//        Account_Sales_Area__c asa = TestDataAccountSalesArea.getNewAccountSalesArea(a.ERP_Customer_Id__c);
//        String expectedContract = a.ERP_Customer_Id__c + '_' + asa.Sales_Organization__c + asa.Distribution_Channel__c + asa.Division__c;
//
//        // staging data setup
//        TestDataMaster.getNewPliStaging(a, asa, p1, pastDate, futureDate);
//        TestDataMaster.getNewPliStaging(a, asa, p2, pastDate, futureDate);
//
//        Test.startTest();
//        Database.executeBatch(new BatchStagedPLItems());
//        Test.stopTest();
//
//        // assert PL data
//        List<Apttus_Config2__PriceList__c> pls = [SELECT Id, Apttus_Config2__ContractNumber__c FROM Apttus_Config2__PriceList__c];
//        System.assertEquals(1, pls.size());
//        Apttus_Config2__PriceList__c pl = pls.get(0);
//        System.assertEquals(expectedContract, pl.Apttus_Config2__ContractNumber__c);
//
//        // assert PLI data inserted
//        List<Apttus_Config2__PriceListItem__c> plis =
//            [SELECT Id, Apttus_Config2__ProductId__c, Apttus_Config2__PriceType__c
//             FROM Apttus_Config2__PriceListItem__c];
//        System.assertEquals(2, plis.size());
//
//        // assert price types are correct
//        Apttus_Config2__PriceListItem__c pli1;
//        Apttus_Config2__PriceListItem__c pli2;
//        if (plis.get(0).Apttus_Config2__ProductId__c == p1.Id)
//        {
//            pli1 = plis.get(0);
//            pli2 = plis.get(1);
//        }
//        else
//        {
//            pli2 = plis.get(0);
//            pli1 = plis.get(1);
//        }
//        System.assertEquals(PriceListItems.PRICE_TYPE_ONE_TIME, pli1.Apttus_Config2__PriceType__c);
//        System.assertEquals(PriceListItems.PRICE_TYPE_RECURRING, pli2.Apttus_Config2__PriceType__c);
//
//        // assert processing is complete
//        List<Apttus_PLI_Staging__c> stagingAfter = [SELECT Id, Processed_Date__c FROM Apttus_PLI_Staging__c];
//        System.assertEquals(2, stagingAfter.size());
//        System.assertEquals(Date.today(), stagingAfter.get(0).Processed_Date__c);
//    }
//
//    @isTest static void oneStagingRecordToOnePLI()
//    {
//        Account a = TestDataAccount.getNewAccount();
//        Product2 p = TestDataMaster.getNewProduct('Cookie');
//        Account_Sales_Area__c asa = TestDataAccountSalesArea.getNewAccountSalesArea(a.ERP_Customer_Id__c);
//        Apttus_PLI_Staging__c staging = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        // NOTE: could be a domain function
//        String expectedContract = a.ERP_Customer_Id__c + '_' + asa.Sales_Organization__c + asa.Distribution_Channel__c + asa.Division__c;
//
//        Test.startTest();
//        {
//            Database.executeBatch(new BatchStagedPLItems());
//        }
//        Test.stopTest();
//
//        // assert PL data
//        List<Apttus_Config2__PriceList__c> pls = [SELECT Id, Apttus_Config2__ContractNumber__c FROM Apttus_Config2__PriceList__c];
//        System.assertEquals(1, pls.size());
//        Apttus_Config2__PriceList__c pl = pls.get(0);
//        System.assertEquals(expectedContract, pl.Apttus_Config2__ContractNumber__c);
//
//        // assert PLI data
//        List<Apttus_Config2__PriceListItem__c> plis =
//            [SELECT Id, Apttus_Config2__ProductId__c, Apttus_Config2__ListPrice__c, Customer_Specific_Price__c, Apttus_Config2__EffectiveDate__c, Apttus_Config2__ExpirationDate__c
//             FROM Apttus_Config2__PriceListItem__c];
//        System.assertEquals(1, plis.size());
//        Apttus_Config2__PriceListItem__c pli = plis.get(0);
//        System.assertEquals(p.Id, pli.Apttus_Config2__ProductId__c);
//        System.assertEquals(staging.ListPrice__c, pli.Apttus_Config2__ListPrice__c);
//        System.assertEquals(staging.CustomerPrice__c, pli.Customer_Specific_Price__c);
//        System.assertEquals(pastDate, pli.Apttus_Config2__EffectiveDate__c.date());
//        System.assertEquals(futureDate, pli.Apttus_Config2__ExpirationDate__c.date());
//
//        // assert processing is complete
//        List<Apttus_PLI_Staging__c> stagingAfter = [SELECT Id, Processed_Date__c FROM Apttus_PLI_Staging__c];
//        System.assertEquals(1, stagingAfter.size());
//        System.assertEquals(Date.today(), stagingAfter.get(0).Processed_Date__c);
//    }
//
//    @isTest static void oneStagingRecordToOnePLIExtantPL()
//    {
//        Account a = TestDataAccount.getNewAccount();
//        Product2 p = TestDataMaster.getNewProduct('Cookie');
//        Account_Sales_Area__c asa = TestDataAccountSalesArea.getNewAccountSalesArea(a.ERP_Customer_Id__c);
//        Apttus_PLI_Staging__c staging = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        String contractNumber = a.ERP_Customer_Id__c + '_' + asa.Sales_Organization__c + asa.Distribution_Channel__c + asa.Division__c;
//        Apttus_Config2__PriceList__c priceList = TestDataMaster.getNewPriceList(contractNumber);
//
//        Test.startTest();
//        {
//            Database.executeBatch(new BatchStagedPLItems());
//        }
//        Test.stopTest();
//
//        // assert no new PL data
//        List<Apttus_Config2__PriceList__c> pls = [SELECT Id FROM Apttus_Config2__PriceList__c];
//        System.assertEquals(1, pls.size());
//
//        // assert PLI data
//        List<Apttus_Config2__PriceListItem__c> plis =
//            [SELECT Id, Apttus_Config2__ProductId__c, Apttus_Config2__ListPrice__c, Customer_Specific_Price__c, Apttus_Config2__EffectiveDate__c, Apttus_Config2__ExpirationDate__c
//             FROM Apttus_Config2__PriceListItem__c];
//        System.assertEquals(1, plis.size());
//        Apttus_Config2__PriceListItem__c pli = plis.get(0);
//        System.assertEquals(p.Id, pli.Apttus_Config2__ProductId__c);
//        System.assertEquals(staging.ListPrice__c, pli.Apttus_Config2__ListPrice__c);
//        System.assertEquals(staging.CustomerPrice__c, pli.Customer_Specific_Price__c);
//        System.assertEquals(pastDate, pli.Apttus_Config2__EffectiveDate__c.date());
//        System.assertEquals(futureDate, pli.Apttus_Config2__ExpirationDate__c.date());
//
//        // assert processing is complete
//        List<Apttus_PLI_Staging__c> stagingAfter = [SELECT Id, Processed_Date__c FROM Apttus_PLI_Staging__c];
//        System.assertEquals(1, stagingAfter.size());
//        System.assertEquals(Date.today(), stagingAfter.get(0).Processed_Date__c);
//    }
//
//    @isTest static void oneStagingToMatchingPlis()
//    {
//        Account a = TestDataAccount.getNewAccount();
//        Product2 p = TestDataMaster.getNewProduct('Cookie');
//        Account_Sales_Area__c asa = TestDataAccountSalesArea.getNewAccountSalesArea(a.ERP_Customer_Id__c);
//        Apttus_PLI_Staging__c staging = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        String contractNumber = a.ERP_Customer_Id__c + '_' + asa.Sales_Organization__c + asa.Distribution_Channel__c + asa.Division__c;
//        Apttus_Config2__PriceList__c priceList = TestDataMaster.getNewPriceList(contractNumber);
//        Apttus_Config2__PriceListItem__c pliOverlapped = TestDataMaster.getNewPriceListItem(priceList.Id, p.Id, pastDate + 2, futureDate - 2, 'USD');
//        Apttus_Config2__PriceListItem__c pliFuture = TestDataMaster.getNewPriceListItem(priceList.Id, p.Id, futureDate + 20, futureDate + 50, 'USD');
//
//        Test.startTest();
//        {
//            Database.executeBatch(new BatchStagedPLItems());
//        }
//        Test.stopTest();
//
//        // assert PLI data
//        List<Apttus_Config2__PriceListItem__c> plis =
//            [SELECT Id, Apttus_Config2__Active__c, Apttus_Config2__ProductId__c, Apttus_Config2__ListPrice__c, Customer_Specific_Price__c, Apttus_Config2__EffectiveDate__c, Apttus_Config2__ExpirationDate__c
//             FROM Apttus_Config2__PriceListItem__c];
//        System.assertEquals(3, plis.size());
//        for (Apttus_Config2__PriceListItem__c pli : plis)
//        {
//            if (pli.Id == pliOverlapped.Id)
//            {
//                System.assert(pli.Apttus_Config2__Active__c == false);
//            }
//            else if (pli.Id == pliFuture.Id)
//            {
//                System.assert(pli.Apttus_Config2__Active__c == true);
//            }
//            else // newly-created row
//            {
//                System.assertEquals(p.Id, pli.Apttus_Config2__ProductId__c);
//                System.assertEquals(staging.ListPrice__c, pli.Apttus_Config2__ListPrice__c);
//                System.assertEquals(staging.CustomerPrice__c, pli.Customer_Specific_Price__c);
//                System.assertEquals(pastDate, pli.Apttus_Config2__EffectiveDate__c.date());
//                System.assertEquals(futureDate, pli.Apttus_Config2__ExpirationDate__c.date());
//            }
//        }
//    }
//
//    @isTest static void batchGetsFirstFindsMany()
//    {
//        Account a = TestDataAccount.getNewAccount();
//        Product2 p = TestDataMaster.getNewProduct('Cookie');
//        Account_Sales_Area__c asa = TestDataAccountSalesArea.getNewAccountSalesArea(a.ERP_Customer_Id__c);
//        Apttus_PLI_Staging__c staging1 = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        Apttus_PLI_Staging__c staging2 = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        Apttus_PLI_Staging__c staging3 = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        Test.setCreatedDate(staging1.Id, DateTime.now() - .3);
//        Test.setCreatedDate(staging2.Id, DateTime.now() - .2);
//        Test.setCreatedDate(staging3.Id, DateTime.now() - .1);
//        String contractNumber = a.ERP_Customer_Id__c + '_' + asa.Sales_Organization__c + asa.Distribution_Channel__c + asa.Division__c;
//        Apttus_Config2__PriceList__c priceList = TestDataMaster.getNewPriceList(contractNumber);
//        Apttus_Config2__PriceListItem__c pliExtant = TestDataMaster.getNewPriceListItem(priceList.Id, p.Id, pastDate, futureDate, 'USD');
//
//        Test.startTest();
//        {
//            // requery to get formula and system values
//            List<Apttus_PLI_Staging__c> batchRows =
//                [SELECT Id, CreatedDate, Contract_Number__c, CurrencyIsoCode, PLI_Key__c, CustomerId__c, SalesOrganization__c, DistributionChannel__c, Division__c, MaterialId__c, PriceListType__c, ListPrice__c, CustomerPrice__c, Quantity__c, UOM__c, ValidFrom__c, ValidTo__c, Processed_Date__c
//                 FROM Apttus_PLI_Staging__c
//                 WHERE Id = :staging1.Id];
//
//            BatchStagedPLItems batch = new BatchStagedPLItems();
//            batch.initCounts();
//            batch.execute(null, batchRows);
//        }
//        Test.stopTest();
//
//        // assert PLI data
//        List<Apttus_Config2__PriceListItem__c> plis =
//            [SELECT Id, Apttus_Config2__Active__c, Apttus_Config2__ProductId__c, Apttus_Config2__ListPrice__c, Customer_Specific_Price__c, Apttus_Config2__EffectiveDate__c, Apttus_Config2__ExpirationDate__c
//             FROM Apttus_Config2__PriceListItem__c];
//        System.assertEquals(2, plis.size());
//        Apttus_Config2__PriceListItem__c activePli;
//        for (Apttus_Config2__PriceListItem__c pli : plis)
//        {
//            if (pli.Apttus_Config2__Active__c) activePli = pli;
//        }
//        // staging 3 is the most recent
//        System.assertEquals(p.Id, activePli.Apttus_Config2__ProductId__c);
//
//        System.assertEquals(staging3.ListPrice__c, activePli.Apttus_Config2__ListPrice__c);
//        System.assertEquals(staging3.CustomerPrice__c, activePli.Customer_Specific_Price__c);
//        System.assertEquals(pastDate, activePli.Apttus_Config2__EffectiveDate__c.date());
//        System.assertEquals(futureDate, activePli.Apttus_Config2__ExpirationDate__c.date());
//
//        // assert processing is complete
//        List<Apttus_PLI_Staging__c> stagingAfter = [SELECT Id FROM Apttus_PLI_Staging__c WHERE Processed_Date__c != null];
//        System.assertEquals(3, stagingAfter.size());
//    }
//
//    @isTest static void batchGetsSecondFindsMany()
//    {
//        Account a = TestDataAccount.getNewAccount();
//        Product2 p = TestDataMaster.getNewProduct('Cookie');
//        Account_Sales_Area__c asa = TestDataAccountSalesArea.getNewAccountSalesArea(a.ERP_Customer_Id__c);
//        Apttus_PLI_Staging__c staging1 = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        Apttus_PLI_Staging__c staging2 = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        Apttus_PLI_Staging__c staging3 = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        Test.setCreatedDate(staging1.Id, DateTime.now() - .3);
//        Test.setCreatedDate(staging2.Id, DateTime.now() - .2);
//        Test.setCreatedDate(staging3.Id, DateTime.now() - .1);
//        String contractNumber = a.ERP_Customer_Id__c + '_' + asa.Sales_Organization__c + asa.Distribution_Channel__c + asa.Division__c;
//        Apttus_Config2__PriceList__c priceList = TestDataMaster.getNewPriceList(contractNumber);
//        Apttus_Config2__PriceListItem__c pliExtant = TestDataMaster.getNewPriceListItem(priceList.Id, p.Id, pastDate, futureDate, 'USD');
//
//        Test.startTest();
//        {
//            // requery to get formula and system values
//            List<Apttus_PLI_Staging__c> batchRows =
//            [SELECT Id, CreatedDate, Contract_Number__c, CurrencyIsoCode, PLI_Key__c, CustomerId__c, SalesOrganization__c, DistributionChannel__c, Division__c, MaterialId__c, PriceListType__c, ListPrice__c, CustomerPrice__c, Quantity__c, UOM__c, ValidFrom__c, ValidTo__c, Processed_Date__c
//            FROM Apttus_PLI_Staging__c
//            WHERE Id = :staging2.Id];
//
//            BatchStagedPLItems batch = new BatchStagedPLItems();
//            batch.initCounts();
//            batch.execute(null, batchRows);
//        }
//        Test.stopTest();
//
//        // assert PLI data
//        List<Apttus_Config2__PriceListItem__c> plis =
//            [SELECT Id, Apttus_Config2__Active__c, Apttus_Config2__ProductId__c, Apttus_Config2__ListPrice__c, Customer_Specific_Price__c, Apttus_Config2__EffectiveDate__c, Apttus_Config2__ExpirationDate__c
//             FROM Apttus_Config2__PriceListItem__c];
//        System.assertEquals(2, plis.size());
//        Apttus_Config2__PriceListItem__c activePli;
//        for (Apttus_Config2__PriceListItem__c pli : plis)
//        {
//            if (pli.Apttus_Config2__Active__c) activePli = pli;
//        }
//        // staging 3 is the most recent
//        System.assertEquals(p.Id, activePli.Apttus_Config2__ProductId__c);
//
//        System.assertEquals(staging3.ListPrice__c, activePli.Apttus_Config2__ListPrice__c);
//        System.assertEquals(staging3.CustomerPrice__c, activePli.Customer_Specific_Price__c);
//        System.assertEquals(pastDate, activePli.Apttus_Config2__EffectiveDate__c.date());
//        System.assertEquals(futureDate, activePli.Apttus_Config2__ExpirationDate__c.date());
//
//        // assert processing is complete
//        List<Apttus_PLI_Staging__c> stagingAfter = [SELECT Id FROM Apttus_PLI_Staging__c WHERE Processed_Date__c != null];
//        System.assertEquals(3, stagingAfter.size());
//    }
//
//    @isTest static void batchGetsThirdFindsMany()
//    {
//        Account a = TestDataAccount.getNewAccount();
//        Product2 p = TestDataMaster.getNewProduct('Cookie');
//        Account_Sales_Area__c asa = TestDataAccountSalesArea.getNewAccountSalesArea(a.ERP_Customer_Id__c);
//        Apttus_PLI_Staging__c staging1 = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        Apttus_PLI_Staging__c staging2 = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        Apttus_PLI_Staging__c staging3 = TestDataMaster.getNewPliStaging(a, asa, p, pastDate, futureDate);
//        Test.setCreatedDate(staging1.Id, DateTime.now() - .3);
//        Test.setCreatedDate(staging2.Id, DateTime.now() - .2);
//        Test.setCreatedDate(staging3.Id, DateTime.now() - .1);
//        String contractNumber = a.ERP_Customer_Id__c + '_' + asa.Sales_Organization__c + asa.Distribution_Channel__c + asa.Division__c;
//        Apttus_Config2__PriceList__c priceList = TestDataMaster.getNewPriceList(contractNumber);
//        Apttus_Config2__PriceListItem__c pliExtant = TestDataMaster.getNewPriceListItem(priceList.Id, p.Id, pastDate, futureDate, 'USD');
//
//        Test.startTest();
//        {
//            // requery to get formula and system values
//            List<Apttus_PLI_Staging__c> batchRows =
//            [SELECT Id, CreatedDate, Contract_Number__c, CurrencyIsoCode, PLI_Key__c, CustomerId__c, SalesOrganization__c, DistributionChannel__c, Division__c, MaterialId__c, PriceListType__c, ListPrice__c, CustomerPrice__c, Quantity__c, UOM__c, ValidFrom__c, ValidTo__c, Processed_Date__c
//            FROM Apttus_PLI_Staging__c
//            WHERE Id = :staging3.Id];
//
//            BatchStagedPLItems batch = new BatchStagedPLItems();
//            batch.initCounts();
//            batch.execute(null, batchRows);
//        }
//        Test.stopTest();
//
//        // assert PLI data
//        List<Apttus_Config2__PriceListItem__c> plis =
//            [SELECT Id, Apttus_Config2__Active__c, Apttus_Config2__ProductId__c, Apttus_Config2__ListPrice__c, Customer_Specific_Price__c, Apttus_Config2__EffectiveDate__c, Apttus_Config2__ExpirationDate__c
//             FROM Apttus_Config2__PriceListItem__c];
//        System.assertEquals(2, plis.size());
//        Apttus_Config2__PriceListItem__c activePli;
//        for (Apttus_Config2__PriceListItem__c pli : plis)
//        {
//            if (pli.Apttus_Config2__Active__c) activePli = pli;
//        }
//        // staging 3 is the most recent
//        System.assertEquals(p.Id, activePli.Apttus_Config2__ProductId__c);
//
//        System.assertEquals(staging3.ListPrice__c, activePli.Apttus_Config2__ListPrice__c);
//        System.assertEquals(staging3.CustomerPrice__c, activePli.Customer_Specific_Price__c);
//        System.assertEquals(pastDate, activePli.Apttus_Config2__EffectiveDate__c.date());
//        System.assertEquals(futureDate, activePli.Apttus_Config2__ExpirationDate__c.date());
//
//        // assert processing is complete
//        List<Apttus_PLI_Staging__c> stagingAfter = [SELECT Id FROM Apttus_PLI_Staging__c WHERE Processed_Date__c != null];
//        System.assertEquals(3, stagingAfter.size());
//    }
//
//    @isTest static void batchGetsOneFindsSome()
//    {
//        Account a = TestDataAccount.getNewAccount();
//        Product2 p1 = TestDataMaster.getNewProduct('Cookie');
//        Product2 p2 = TestDataMaster.getNewProduct('Brownie');
//        Account_Sales_Area__c asa = TestDataAccountSalesArea.getNewAccountSalesArea(a.ERP_Customer_Id__c);
//        Apttus_PLI_Staging__c staging1 = TestDataMaster.getNewPliStaging(a, asa, p1, pastDate, futureDate);
//        Apttus_PLI_Staging__c staging2 = TestDataMaster.getNewPliStaging(a, asa, p1, pastDate, futureDate);
//        Apttus_PLI_Staging__c staging3 = TestDataMaster.getNewPliStaging(a, asa, p2, pastDate, futureDate);
//        Apttus_PLI_Staging__c staging4 = TestDataMaster.getNewPliStaging(a, asa, p2, pastDate, futureDate);
//        Test.setCreatedDate(staging1.Id, DateTime.now() - .3);
//        Test.setCreatedDate(staging2.Id, DateTime.now() - .2);
//        Test.setCreatedDate(staging3.Id, DateTime.now() - .3);
//        Test.setCreatedDate(staging4.Id, DateTime.now() - .2);
//        String contractNumber = a.ERP_Customer_Id__c + '_' + asa.Sales_Organization__c + asa.Distribution_Channel__c + asa.Division__c;
//        Apttus_Config2__PriceList__c priceList = TestDataMaster.getNewPriceList(contractNumber);
//        Apttus_Config2__PriceListItem__c pliExtant1 = TestDataMaster.getNewPriceListItem(priceList.Id, p1.Id, pastDate, futureDate, 'USD');
//        Apttus_Config2__PriceListItem__c pliExtant2 = TestDataMaster.getNewPriceListItem(priceList.Id, p2.Id, pastDate, futureDate, 'USD');
//
//        Test.startTest();
//        {
//            // requery to get formula and system values
//            List<Apttus_PLI_Staging__c> batchRows =
//            [SELECT Id, CreatedDate, Contract_Number__c, CurrencyIsoCode, PLI_Key__c, CustomerId__c, SalesOrganization__c, DistributionChannel__c, Division__c, MaterialId__c, PriceListType__c, ListPrice__c, CustomerPrice__c, Quantity__c, UOM__c, ValidFrom__c, ValidTo__c, Processed_Date__c
//            FROM Apttus_PLI_Staging__c
//            WHERE Id = :staging2.Id];
//
//            BatchStagedPLItems batch = new BatchStagedPLItems();
//            batch.initCounts();
//            batch.execute(null, batchRows);
//        }
//        Test.stopTest();
//
//        // assert PLI data
//        List<Apttus_Config2__PriceListItem__c> plis =
//            [SELECT Id, Apttus_Config2__Active__c, Apttus_Config2__ProductId__c, Apttus_Config2__ListPrice__c, Customer_Specific_Price__c, Apttus_Config2__EffectiveDate__c, Apttus_Config2__ExpirationDate__c
//             FROM Apttus_Config2__PriceListItem__c];
//        System.assertEquals(3, plis.size());
//
//        // assert processing is complete for product p1
//        List<Apttus_PLI_Staging__c> stagingAfter = [SELECT Id FROM Apttus_PLI_Staging__c WHERE Processed_Date__c = null];
//        System.assertEquals(2, stagingAfter.size());
//    }

}
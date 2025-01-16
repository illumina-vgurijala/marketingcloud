/**
* Master data records (products & prices)
*
* Author 
* @date   
* @description    
* Modification Log:
* ------------------------------------------------------------------------------------
*   Parthasarathy D        10-Oct-2022            Codescan Fixes
*   Aman Tyagi             12-Dec-2022            Codescan Fixes
*------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestDataMaster {
    /*
    * @Description : To get the Pricebook ID.
    */ 
    public static Id getStandardPricebookId()
    {
        return Test.getStandardPricebookId();
    }
    /*
    * @Description : To get the instance of Pricebook record.
    */
    public static Pricebook2 initNewCustomPricebook()
    {
        Pricebook2 customPb = new Pricebook2(
            Name = 'Custom Pricebook ' + TestData.getRandom(),
            IsActive = true
            //ERP_Price_List_Type_Id__c = '01'
        );
        return customPb;
    }
    /*
    * @Description : To create the new instance of Pricebook record.
    */
    public static Pricebook2 getNewCustomPricebook()
    {
        Pricebook2 customPb = initNewCustomPricebook();
        insert customPb;
        return customPb;
    }
    /*
    * @Description : To get the new instance of Product record.
    */
    public static Product2 getNewProduct(String productCode)
    {
        return getNewProduct(productCode, '');
    }
    /*
    * @Description : To get the new instance of Product record.
    */
    public static Product2 initProduct(String productCode)
    {
        return initProduct(productCode, '');
    }
    /*
    * @Description : To get the new instance of Product record.
    */
    public static Product2 getNewProduct(String productCode, String materialClass)
    {
        Product2 p = initProduct(productCode, materialClass);
        insert p;
        return p;
    }
    /*
    * @Description : To create the new instance of Product record.
    */
    public static Product2 initProduct(String productCode, String materialClass)
    {
        Product2 p = new Product2(
            ProductCode = productCode,
            Name = productCode,
            Material_Number__c = TestData.getRandom(),
            Material_Class__c = materialClass,
            Number_Of_Samples__c = 1,
            Informatics_Family__c = 'BASESPACE_COHORT_ANALYZER',
            Informatics_SKU_Type__c ='SUBSCRIPTION',
            Subscription_Tier__c='Enterprise',
            Number_Of_BeadChips_Per_Sample__c='1',
            IsActive = true
        );
        return p;
    }
    /*
    * @Description : To insert and return Product SalesArea object record.
    */
    public static Product_Sales_Area__c getNewProductSalesArea(Id productId)
    {
        Product_Sales_Area__c rec = initProductSalesArea(productId);
        insert rec;
        return rec;
    }
    /*
    * @Description : To get the instance of Product SalesArea object record.
    */
    public static Product_Sales_Area__c initProductSalesArea(Id productId)
    {
        Product_Sales_Area__c rec = new Product_Sales_Area__c(
            Product__c = productId,
            Category_Group__c = TestData.getRandom(),
            Sales_Organization__c = TestData.getRandom(),
            Distribution_Channel__c = TestData.getRandom(),
            Distribution_Chain_Specific_Status__c = TestData.getRandom(),
            ERP_Product_Sales_Area_Id__c = TestData.getRandom()
        );
        return rec;
    }
    /*
    * @Description : To get PricebookEntry record.
    */
    public static PricebookEntry getNewStandardPrice(Id productId, Double price)
    {
        return getNewStandardPrice(productId, price, UserInfo.getDefaultCurrency());
    }
    /*
    * @Description : To insert and return PricebookEntry record.
    */
    public static PricebookEntry getNewStandardPrice(Id productId, Double price, String currencyCode)
    {
        PricebookEntry standardPrice = initStandardPrice(productId, price, currencyCode);
        insert standardPrice;
        return standardPrice;
    }
    /*
    * @Description : To create an instance of PricebookEntry record.
    */
    public static PricebookEntry initStandardPrice(Id productId, Double price, String currencyCode)
    {
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = price,
            UseStandardPrice = false,
            IsActive = true
        );
        return standardPrice;
    }
    /*
    * @Description : To get PricebookEntry record.
    */
    public static PricebookEntry getNewCustomPrice(Id pricebookId, Id productId, Double price)
    {
        return getNewCustomPrice(pricebookId, productId, price, UserInfo.getDefaultCurrency());
    }
    /*
    * @Description : To insert and return PricebookEntry record.
    */
    public static PricebookEntry getNewCustomPrice(Id pricebookId, Id productId, Double price, String currencyCode)
    {
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = price,
            IsActive = true
        );
        insert customPrice;
        return customPrice;
    }

    // TODO: some overlap with TestDataProposal. Reconcile to here at some point
    /*
    * @Description : To insert and return PriceList record.
    */
    public static Apttus_Config2__PriceList__c getNewPriceList(String contractNumber)
    {
        Apttus_Config2__PriceList__c rec = initPriceList(contractNumber);
        insert rec;
        return rec;
    }
    /*
    * @Description : To create an instance of PriceList record.
    */
    public static Apttus_Config2__PriceList__c initPriceList(String contractNumber)
    {
        Apttus_Config2__PriceList__c rec = new Apttus_Config2__PriceList__c(
                Name = contractNumber,
                Apttus_Config2__ContractNumber__c = contractNumber,
                Apttus_Config2__Active__c = true
        );
        return rec;
    }
    /*
    * @Description : To insert and return PriceList record.
    */
    public static Apttus_Config2__PriceListItem__c getNewPriceListItem(Id priceListId, Id productId, Datetime startDate, Datetime endDate, String currencyCode)
    {
        Apttus_Config2__PriceListItem__c rec = initPriceListItem(priceListId, productId, startDate, endDate, currencyCode);
        insert rec;
        return rec;
    }
    /*
    * @Description : To create an instance of PriceList record.
    */
    public static Apttus_Config2__PriceListItem__c initPriceListItem(Id priceListId, Id productId, Datetime startDate, Datetime endDate, String currencyCode)
    {
        Apttus_Config2__PriceListItem__c rec = new Apttus_Config2__PriceListItem__c(
                Apttus_Config2__PriceListId__c = priceListId,
                Apttus_Config2__ProductId__c = productId,
                Apttus_Config2__ChargeType__c = 'Standard Price',
                Apttus_Config2__ListPrice__c = Decimal.valueOf(TestData.getRandomNumeric(6)),
                Customer_Specific_Price__c = Decimal.valueOf(TestData.getRandomNumeric(5)),
                CurrencyIsoCode = currencyCode,
                Apttus_Config2__EffectiveDate__c = startDate,
                Apttus_Config2__ExpirationDate__c = endDate,
                Apttus_Config2__PriceUom__c = 'Each',
                Apttus_Config2__DefaultQuantity__c = 1,
                Apttus_Config2__Active__c = true
        );
        return rec;
    }
    /*
    * @Description : To get Pricelist record.
    */
    public static Apttus_Config2__PriceListItem__c getNewPriceListItem(Id priceListId, Id productId, Datetime startDate, Datetime endDate)
    {
        return getNewPriceListItem(priceListId, productId, startDate, endDate, 'USD');
    }
    /*
    * @Description : To get Pricelist record.
    */
    public static Apttus_Config2__PriceListItem__c initPriceListItem(Id priceListId, Id productId, Datetime startDate, Datetime endDate)
    {
        return initPriceListItem(priceListId, productId, startDate, endDate, 'USD');
    }
    /*
    * @Description : To insert and return PLI Staging record.
    */
    public static Apttus_PLI_Staging__c getNewPliStaging(Account a, Account_Sales_Area__c asa, Product2 p, Date fromDate, Date toDate)
    {
        Apttus_PLI_Staging__c rec = initPliStaging(a, asa, p, fromDate, toDate);
        insert rec;
        return rec;
    }
    /*
    * @Description : To create an instance of PLI Staging record.
    */
    public static Apttus_PLI_Staging__c initPliStaging(Account a, Account_Sales_Area__c asa, Product2 p, Date fromDate, Date toDate)
    {
        Apttus_PLI_Staging__c rec = new Apttus_PLI_Staging__c(
                CurrencyIsoCode = asa.CurrencyIsoCode,
                CustomerId__c = a.ERP_Customer_Id__c,
                SalesOrganization__c = asa.Sales_Organization__c,
                DistributionChannel__c = asa.Distribution_Channel__c,
                Division__c = asa.Division__c,
                MaterialId__c = p.Material_Number__c,
                ListPrice__c = Decimal.valueOf(TestData.getRandomNumeric(5)),
                CustomerPrice__c = Decimal.valueOf(TestData.getRandomNumeric(4)),
                PriceListType__c = '01',  // TODO: any logic around this?
                Quantity__c = 1,
                UOM__c = 'EA',
                ValidFrom__c = formatFlatFileDate(fromDate),
                ValidTo__c = formatFlatFileDate(toDate)
        );
        return rec;
    }

    private static String formatFlatFileDate(Date raw)
    {
        // convert to format used in CSP flat file
        // ex: 20180820
        String year = String.valueOf(raw.year());
        String month = String.valueOf(raw.month());
        if (raw.month() < 10) month = '0' + month;
        String day = String.valueOf(raw.day());
        if (raw.day() < 10) day = '0' + day;
        return year + month + day;
    }


    /*
    *
    *
    *
    *
    *
    *     STOP HERE
    *
    * The methods below shouldn't be used.
    * If you need a product2, pricebook2 or pricebookentry test data generator
    * that isn't already covered, create one above this.
    *
    * Data of other types belongs in a different TestData class
    *
    *
    *
    */
    
    
    
    
    
    
    
    // ++++++ DO NOT USE
    // TODO: replace calls to this with initOpportunityLineItem() or getNewOpportunityLineItem()
    /*
    * @Description : To create Opportunity Product records.
    */
    public static OpportunityLineItem createOpportunityProduct(Id opportunityId, Id priceId, Boolean doInsert)
    {
        if (doInsert)
            return TestDataOpportunity.getNewOpportunityLineItem(opportunityId, priceId, 10, 11);
        else
            return TestDataOpportunity.initOpportunityLineItem(opportunityId, priceId, 10, 11);
    }
    
    // ++++++ DO NOT USE
    // TODO: replace calls to this with initStandardPrice() or getNewStandardPrice()
    /*
    * @Description : To create Pricebook entry records.
    */
    public static PricebookEntry createPricebookEntry(Id prodId, Boolean doInsert)
    {
        if (doInsert)
            return getNewStandardPrice(prodId, 20, 'USD');
        else
            return initStandardPrice(prodId, 20, 'USD');
    }
    
    // ++++++ DO NOT USE
    // TODO: replace calls to this with initProduct() or getNewProduct()
    /*
    * @Description : To create Product records with type as "Instrument".
    */
    public static Product2 createProductOfTypeInstrument(Boolean doInsert)
    {
        if (doInsert)
            return getNewProduct(TestData.getRandom(), 'Instrument');
        else
            return initProduct(TestData.getRandom(), 'Instrument');
    }
    
    // ++++++ DO NOT USE
    // TODO: replace calls to this with initProduct() or getNewProduct()
    /*
    * @Description : To create Product records with type as "Services".
    */
    public static Product2 createProduct(Boolean doInsert)
    {
        if (doInsert)
            return getNewProduct(TestData.getRandom(), 'Services');
        else
            return initProduct(TestData.getRandom(), 'Services');
    }
    
    // ++++++ DO NOT USE
    // TODO: replace calls to this with initNewCustomPricebook() or getNewCustomPricebook()
    /*
    * @Description : To create Pricebook records.
    */
    public static PriceBook2 createPriceBook(Boolean doInsert)
    {
        if (doInsert)
            return getNewCustomPricebook();
        else
            return initNewCustomPricebook();
    }
    
    /*
    * @Description : Linking Bundle and Component Product - Fixed Bundle SKU
    */
    public static void linkBundleComponent(Id fixBundleId, Id fixBundleComp){
        
        //Creating Category of type Option Group
        Apttus_Config2__ClassificationName__c fixBundleCategory = new Apttus_Config2__ClassificationName__c();
        fixBundleCategory.Name = 'Pizza';
        fixBundleCategory.Apttus_Config2__Active__c = true;
        fixBundleCategory.Apttus_Config2__Type__c = 'Option Group';
        fixBundleCategory.Apttus_Config2__HierarchyLabel__c = 'Pizza';
        insert fixBundleCategory;

        //Category Hierarchy corresponding record
        Apttus_Config2__ClassificationHierarchy__c fixBundleCatHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        fixBundleCatHierarchy.Name = 'Pizza';
        fixBundleCatHierarchy.Apttus_Config2__Label__c = 'Pizza';
        fixBundleCatHierarchy.Apttus_Config2__HierarchyId__c = fixBundleCategory.Id;
        insert fixBundleCatHierarchy;        

        //Product Option Group
        Apttus_Config2__ProductOptionGroup__c fixBundleProdOpGroup = new Apttus_Config2__ProductOptionGroup__c();
        fixBundleProdOpGroup.Apttus_Config2__Sequence__c = 0;
        fixBundleProdOpGroup.Apttus_Config2__ModifiableType__c = 'Fixed';
        fixBundleProdOpGroup.Apttus_Config2__RootOptionGroupId__c = fixBundleCatHierarchy.Id;
        fixBundleProdOpGroup.Apttus_Config2__OptionGroupId__c = fixBundleCatHierarchy.Id;
        fixBundleProdOpGroup.Apttus_Config2__ProductId__c = fixBundleId;
        fixBundleProdOpGroup.Apttus_Config2__MinOptions__c = 1;
        fixBundleProdOpGroup.Apttus_Config2__MaxOptions__c = 1;
        insert fixBundleProdOpGroup;

        //ProductOptionComponent
        Apttus_Config2__ProductOptionComponent__c fixBundleProdOpComp = new Apttus_Config2__ProductOptionComponent__c();
        fixBundleProdOpComp.Apttus_Config2__ComponentProductId__c = fixBundleComp;
        fixBundleProdOpComp.Apttus_Config2__ProductOptionGroupId__c = fixBundleProdOpGroup.Id;
        fixBundleProdOpComp.Apttus_Config2__ParentProductId__c = fixBundleId;
        fixBundleProdOpComp.Apttus_Config2__Sequence__c = 1;
        fixBundleProdOpComp.Apttus_Config2__RelationshipType__c = 'Option';
        fixBundleProdOpComp.Apttus_Config2__DefaultQuantity__c = 1;
        insert fixBundleProdOpComp;
    }
    
}
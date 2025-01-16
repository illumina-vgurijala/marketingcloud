/**
*    @Name :   TestBundleCustomersTests
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Saddam                         10-oct-22           COdescan Fix,Comments Added.
*    ------------------------------------------------------------------------------------
*
*/
@isTest(isParallel=true)
private class TestBundleCustomersTests {

    /*
    *  @description  : Test Method simpleProspect()
    */
    @isTest
    public static void simpleProspect()
    {
        String currencyCode = 'EUR';
        String countryCode = 'FR';

        List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions = new List<TestBundleCustomersStructure.CustomerDefinition> {
            new TestBundleCustomersStructure.CustomerDefinition(Accounts.GROUP_PROSPECT, currencyCode, countryCode)
        };

        TestBundleCustomers bundleMaker = new TestBundleCustomers(customerDefinitions);
        Map<String, List<SObject>> customerBundle = bundleMaker.getBundle();

        Test.startTest();
        bundleMaker.insertBundle(customerBundle);
        Test.stopTest();

        System.assertEquals(1, customerBundle.get('Account').size());
        System.assertEquals(0, customerBundle.get('Customer_Master_Data__c').size());
    }

    /*
    *  @description  : Test Method simpleHierarchy()
    */
    @isTest
    public static void simpleHierarchy()
    {
        String currencyCode = 'JPY';
        String countryCode = 'JP';
        String salesOrg = 'JP01';

        List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions = new List<TestBundleCustomersStructure.CustomerDefinition> {
            new TestBundleCustomersStructure.CustomerDefinition(Accounts.GROUP_DISTRIBUTOR, currencyCode, countryCode),
            new TestBundleCustomersStructure.CustomerDefinition(CustomerMasterDatas.GROUP_SHIP_TO, currencyCode, countryCode)
        };

        List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs = new List<TestBundleCustomersStructure.SalesAreaDefinition> {
            new TestBundleCustomersStructure.SalesAreaDefinition(salesOrg, '01', '00')
        };

        TestBundleCustomers bundleMaker = new TestBundleCustomers(customerDefinitions, salesAreaDefs);
        Map<String, List<SObject>> customerBundle = bundleMaker.getBundle();

        Test.startTest();
        bundleMaker.insertBundle(customerBundle);
        Test.stopTest();

        System.assertEquals(1, customerBundle.get('Account').size());
        System.assertEquals(2, customerBundle.get('Customer_Master_Data__c').size());
        System.assertEquals(2, customerBundle.get('Account_Sales_Area__c').size());
        System.assertEquals(6, customerBundle.get('Account_Relationship__c').size());
    }

    /*
    *  @description  : Test Method hierarchyWithExtraRelations()
    */
    @isTest
    public static void hierarchyWithExtraRelations()
    {
        String currencyCode = 'EUR';
        String countryCode = 'FR';
        String salesOrg = 'FR01';

        List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions = new List<TestBundleCustomersStructure.CustomerDefinition> {
            new TestBundleCustomersStructure.CustomerDefinition(Accounts.GROUP_SOLD_TO, currencyCode, countryCode),
            new TestBundleCustomersStructure.CustomerDefinition(CustomerMasterDatas.GROUP_BILL_TO, currencyCode, countryCode),
            new TestBundleCustomersStructure.CustomerDefinition(Accounts.GROUP_ULTIMATE_CONSIGNEE, currencyCode, countryCode)
        };

        List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs = new List<TestBundleCustomersStructure.SalesAreaDefinition> {
            new TestBundleCustomersStructure.SalesAreaDefinition(salesOrg, '01', '00')
        };

        List<TestBundleCustomersStructure.ExtraRelationshipDefinition> extraRels = new List<TestBundleCustomersStructure.ExtraRelationshipDefinition> {
            new TestBundleCustomersStructure.ExtraRelationshipDefinition(2, 1, new Set<String> {salesOrg}, CustomerMasterDatas.GROUP_BILL_TO, true),
            new TestBundleCustomersStructure.ExtraRelationshipDefinition(2, 1, new Set<String> {salesOrg}, CustomerMasterDatas.GROUP_PAYER, true),
            new TestBundleCustomersStructure.ExtraRelationshipDefinition(3, 1, new Set<String> {salesOrg}, Accounts.GROUP_ULTIMATE_CONSIGNEE, false)
        };

        TestBundleCustomers bundleMaker = new TestBundleCustomers(customerDefinitions, salesAreaDefs, extraRels);
        Map<String, List<SObject>> customerBundle = bundleMaker.getBundle();

        Test.startTest();
        bundleMaker.insertBundle(customerBundle);
        Test.stopTest();

        System.assertEquals(2, customerBundle.get('Account').size());
        System.assertEquals(3, customerBundle.get('Customer_Master_Data__c').size());
        System.assertEquals(3, customerBundle.get('Account_Sales_Area__c').size());
        System.assertEquals(11, customerBundle.get('Account_Relationship__c').size());
    }

}
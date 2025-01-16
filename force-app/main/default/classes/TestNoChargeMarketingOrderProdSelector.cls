/**
*    @author: Deep Diwakar
*    @date:   March-08-2023
*    @description:  Test class for NoChargeMarketingOrderProductsSelector class
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                                     Description
*            Deep Diwakar                March-15-2023       DCP-59580: Test class for NoChargeMarketingOrderProductsSelector class
*    ------------------------------------------------------------------------------------ 
*                    
*/

@isTest
private class TestNoChargeMarketingOrderProdSelector {

    @testSetup
    static void testSetup() {
        Account testAcct = TestDataMarketing.getAccount('Test NCMO Changes');
        No_Charge_Marketing_Order__c testNcmo = new No_Charge_Marketing_Order__c();
        testNcmo.Acknowledgement_of_NCMO_Type_Usage__c = true;
        testNcmo.Account__c = testAcct.Id;
        testNcmo.Contact_Name__c = 'Ncmo Testing';
        testNcmo.Contact_Email__c = 'ncmo_trigger@testing.com';
        testNcmo.Customer_Address__c = 'Testing Avenue';
        testNcmo.NCMO_Justification__c = 'Test data';
        testNcmo.NCMO_Reason__c = 'Marketing Data';

        insert testNcmo;

        Product2 openOfferProduct = TestDataMaster.initProduct('123999');
        openOfferProduct.Open_Offer_Product__c = true;
        insert openOfferProduct;

        No_Charge_Marketing_Order_Product__c testNcmoProduct = new No_Charge_Marketing_Order_Product__c();
        testNcmoProduct.Product__c = openOfferProduct.Id;
        testNcmoProduct.NCMO__c = testNcmo.Id;
        insert testNcmoProduct;

    }

    @isTest
    static void testselectNcmoProductsById(){
        No_Charge_Marketing_Order_Product__c testNcmoProduct = [SELECT Id FROM No_Charge_Marketing_Order_Product__c LIMIT 1];

        Set<Id> testSetNcmoProductId = new Set<Id>();
        testSetNcmoProductId.add(testNcmoProduct.Id);

        Test.startTest();
        List<No_Charge_Marketing_Order_Product__c> result = new NoChargeMarketingOrderProductsSelector().selectNcmoProductsById(testSetNcmoProductId);
        Test.stopTest();

        System.assert(result.get(0).Product__r.Open_Offer_Product__c, 'NCMO Product selector querying correct fields');


    }

    @isTest
    static void testSelectorMethodsFFOn() {

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', true);

        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        No_Charge_Marketing_Order_Product__c testNcmoProduct = [SELECT Id FROM No_Charge_Marketing_Order_Product__c LIMIT 1];

        Set<Id> testSetNcmoProductId = new Set<Id>();
        testSetNcmoProductId.add(testNcmoProduct.Id);

        Test.startTest();
        new NoChargeMarketingOrderProductsSelector().selectNcmoProductsById(testSetNcmoProductId);
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'NoChargeMarketingOrderProductsSelector.selectNcmoProductsById';
        

        // querying ilmn_debug_log__c to check if query is logged when feature flag is on
        System.assertEquals(1, [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle],
         'Selector method did not log slow query when Feature Flag was On');

    }

    @isTest
    static void testSelectorMethodsFFOff() {

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', false);

        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        No_Charge_Marketing_Order_Product__c testNcmoProduct = [SELECT Id FROM No_Charge_Marketing_Order_Product__c LIMIT 1];

        Set<Id> testSetNcmoProductId = new Set<Id>();
        testSetNcmoProductId.add(testNcmoProduct.Id);

        Test.startTest();
        new NoChargeMarketingOrderProductsSelector().selectNcmoProductsById(testSetNcmoProductId);
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'NoChargeMarketingOrderProductsSelector.selectNcmoProductsById';
        
        // querying ilmn_debug_log__c to check if query is logged when feature flag is off
        System.assertEquals(0, [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle],
         'Selector method logged slow query even when Feature Flag was off');

    }

    private static void setThreshholdsToZero()
    {
        PS_Log_Setting__mdt settings = new ilib_LogSettings().query();
        settings.Slow_Query_Threshold__c = 0.0;
        settings.Slow_Transaction_Threshold__c = 0.0;
        settings.Disable_All_Log_Persistence__c = false;
        settings.Disable_Slow_Query_Publish__c = false;
        settings.Disable_Slow_Transaction_Publish__c = false;
        //settings.Pause_Publishes_Until__c = null;

        ilib_LogSettings.unitTestSettingsRecord = settings;
    }

}
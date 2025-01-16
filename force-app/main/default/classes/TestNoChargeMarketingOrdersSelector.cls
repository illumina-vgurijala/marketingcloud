/**
*    @author: Deep Diwakar
*    @date:   March-08-2023
*    @description:  Test class for NoChargeMarketingOrdersSelector class
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                                     Description
*            Deep Diwakar                March-15-2023       DCP-59580: Test class for NoChargeMarketingOrdersSelector class
*    ------------------------------------------------------------------------------------ 
*                    
*/

@isTest
private class TestNoChargeMarketingOrdersSelector {

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
    static void testSelectNcmoById() {

        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
                                                    WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];
        Set<Id> testSetNcmo = new Set<Id>();
        testSetNcmo.add(testNcmo.Id);
        Test.startTest();
        List<No_Charge_Marketing_Order__c> result = new NoChargeMarketingOrdersSelector().selectNcmoById(testSetNcmo);
        Test.stopTest();

        // Since the test NCMO has open offer product then the query result should return true for this field
        System.assert(result.get(0).Open_Offer_Product__c, 'NCMO Open offer field not queried correctly');

    }

    @isTest
    static void testselectNcmoWithProductsById() {

        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
                                                    WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];
        Set<Id> testSetNcmo = new Set<Id>();
        testSetNcmo.add(testNcmo.Id);
        Test.startTest();
        List<No_Charge_Marketing_Order__c> result = new NoChargeMarketingOrdersSelector().selectNcmoWithProductsById(testSetNcmo);
        Test.stopTest();
        List<No_Charge_Marketing_Order_Product__c> lstNcmoProduct = result.get(0).No_Charge_Marketing_Order_Products__r;

        System.assertEquals(1, lstNcmoProduct.size(), 'NCMO product not returned as subquery result');

    }

    @isTest
    static void testSelectorMethodsFFOn() {

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', true);

        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
        WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];
        Set<Id> testSetNcmo = new Set<Id>();
        testSetNcmo.add(testNcmo.Id);
        Test.startTest();
        new NoChargeMarketingOrdersSelector().selectNcmoById(testSetNcmo);
        new NoChargeMarketingOrdersSelector().selectNcmoWithProductsById(testSetNcmo);
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'NoChargeMarketingOrdersSelector.selectNcmoById';

        // querying ilmn_debug_log__c to check if query is logged when feature flag is on
        System.assertEquals(1, [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle],
         'Selector method did not log slow query');

    }

    @isTest
    static void testSelectorMethodsFFOff() {

        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', false);

        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
        WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];
        Set<Id> testSetNcmo = new Set<Id>();
        testSetNcmo.add(testNcmo.Id);
        Test.startTest();
        new NoChargeMarketingOrdersSelector().selectNcmoById(testSetNcmo);
        new NoChargeMarketingOrdersSelector().selectNcmoWithProductsById(testSetNcmo);
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'NoChargeMarketingOrdersSelector.selectNcmoById';

        // querying ilmn_debug_log__c to check if query is logged when feature flag is off
        System.assertEquals(0, [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle],
         'Selector method logged slow query even when Feature Flag is off');

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
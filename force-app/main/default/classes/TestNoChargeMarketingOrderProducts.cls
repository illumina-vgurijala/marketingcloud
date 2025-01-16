/**
*    @author: Deep Diwakar
*    @date:   March-08-2023
*    @description:  Test class for No Charge Marketing Order Product Trigger Handler class
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                                     Description
*            Deep Diwakar                March-15-2023       DCP-59580: Test class for No Charge Marketing Order Product Trigger Handler class
*    ------------------------------------------------------------------------------------ 
*                    
*/

@isTest
private class TestNoChargeMarketingOrderProducts {

    @testSetup
    static void testSetup() {
        Account testAcct = TestDataMarketing.getAccount('Test NCMO Changes');
        No_Charge_Marketing_Order__c testNcmo = new No_Charge_Marketing_Order__c();
        testNcmo.Acknowledgement_of_NCMO_Type_Usage__c = true;
        testNcmo.Account__c = testAcct.Id;
        testNcmo.Contact_Name__c = 'Ncmo Testing';
        testNcmo.Contact_Email__c = 'ncmo_trigger@testing.com';
        //testNcmo.Contact_Phone_Number__c = TestData.getRandomNumeric(10);
        testNcmo.Customer_Address__c = 'Testing Avenue';
        testNcmo.NCMO_Justification__c = 'Test data';
        testNcmo.NCMO_Reason__c = 'Marketing Data';

        insert testNcmo;

    }

    @isTest
    static void testNcmoProductOpenOffer() {

        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
                                                 WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];

        Product2 openOfferProduct = TestDataMaster.initProduct('123999');
        openOfferProduct.Open_Offer_Product__c = true;
        insert openOfferProduct;

        No_Charge_Marketing_Order_Product__c testNcmoProduct = new No_Charge_Marketing_Order_Product__c();
        testNcmoProduct.Product__c = openOfferProduct.Id;
        testNcmoProduct.NCMO__c = testNcmo.Id;

        Test.startTest();
        insert testNcmoProduct;
        Test.stopTest();
        
        No_Charge_Marketing_Order__c result = [Select Id, Open_Offer_Product__c From No_Charge_Marketing_Order__c
                                               where Id =: testNcmo.Id ];

        System.assert(result.Open_Offer_Product__c, 'NCMO order field not updated after adding open offer product');

    }
    
    @isTest
    static void testNcmoProductNonOpenOffer() {

        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
                                                 WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];

        Product2 nonOpenOfferProduct = TestDataMaster.initProduct('123999');
        insert nonOpenOfferProduct;

        No_Charge_Marketing_Order_Product__c testNcmoProduct = new No_Charge_Marketing_Order_Product__c();
        testNcmoProduct.Product__c = nonOpenOfferProduct.Id;
        testNcmoProduct.NCMO__c = testNcmo.Id;

        Test.startTest();
        insert testNcmoProduct;
        Test.stopTest();
        No_Charge_Marketing_Order__c result = [Select Id, Open_Offer_Product__c From No_Charge_Marketing_Order__c
                                               where Id =: testNcmo.Id ];

        System.assert(!result.Open_Offer_Product__c, 'NCMO order field updated after adding non open offer product');

    }
    
    @isTest
    static void testNcmoMultipleProducts() {

        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
                                                 WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];

        List<Product2> lstProducts = new List<Product2>();
        Product2 nonOpenOfferProduct = TestDataMaster.initProduct('123999');
        lstProducts.add(nonOpenOfferProduct);
        
        Product2 openOfferProduct = TestDataMaster.initProduct('123990');
        openOfferProduct.Open_Offer_Product__c = true;
        lstProducts.add(openOfferProduct);
        
        insert lstProducts;

        List<No_Charge_Marketing_Order_Product__c> lstNcmoProducts = new List<No_Charge_Marketing_Order_Product__c>();
        
        No_Charge_Marketing_Order_Product__c ncmoNonOpenOfferProduct = new No_Charge_Marketing_Order_Product__c();
        ncmoNonOpenOfferProduct.Product__c = nonOpenOfferProduct.Id;
        ncmoNonOpenOfferProduct.NCMO__c = testNcmo.Id;
        lstNcmoProducts.add(ncmoNonOpenOfferProduct);
        
        No_Charge_Marketing_Order_Product__c ncmoOpenOfferProduct = new No_Charge_Marketing_Order_Product__c();
        ncmoOpenOfferProduct.Product__c = openOfferProduct.Id;
        ncmoOpenOfferProduct.NCMO__c = testNcmo.Id;
        lstNcmoProducts.add(ncmoOpenOfferProduct);

        Test.startTest();
        insert lstNcmoProducts;
        Test.stopTest();
        No_Charge_Marketing_Order__c result = [Select Id, Open_Offer_Product__c From No_Charge_Marketing_Order__c
                                               where Id =: testNcmo.Id ];

        System.assert(result.Open_Offer_Product__c, 'NCMO order field not updated after adding open offer product');

    }


    @isTest
    static void testNcmoOpenOfferProductDelete() {
        
        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
                                                 WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];

        List<Product2> lstProducts = new List<Product2>();
        Product2 nonOpenOfferProduct = TestDataMaster.initProduct('123999');
        lstProducts.add(nonOpenOfferProduct);
        
        Product2 openOfferProduct = TestDataMaster.initProduct('123990');
        openOfferProduct.Open_Offer_Product__c = true;
        lstProducts.add(openOfferProduct);
        
        insert lstProducts;

        List<No_Charge_Marketing_Order_Product__c> lstNcmoProducts = new List<No_Charge_Marketing_Order_Product__c>();
        
        No_Charge_Marketing_Order_Product__c ncmoNonOpenOfferProduct = new No_Charge_Marketing_Order_Product__c();
        ncmoNonOpenOfferProduct.Product__c = nonOpenOfferProduct.Id;
        ncmoNonOpenOfferProduct.NCMO__c = testNcmo.Id;
        lstNcmoProducts.add(ncmoNonOpenOfferProduct);
        
        No_Charge_Marketing_Order_Product__c ncmoOpenOfferProduct = new No_Charge_Marketing_Order_Product__c();
        ncmoOpenOfferProduct.Product__c = openOfferProduct.Id;
        ncmoOpenOfferProduct.NCMO__c = testNcmo.Id;
        lstNcmoProducts.add(ncmoOpenOfferProduct);

     
        insert lstNcmoProducts;
        
        Test.startTest();
        delete ncmoOpenOfferProduct;
        Test.stopTest();
        
        No_Charge_Marketing_Order__c result = [Select Id, Open_Offer_Product__c From No_Charge_Marketing_Order__c
                                               where Id =: testNcmo.Id ];

        System.assert(!result.Open_Offer_Product__c, 'NCMO order field not updated after deletion of open offer product');
        
    }
    
    @isTest
    static void testNcmoNonOpenOfferProductDelete() {
        
        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
                                                 WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];

        List<Product2> lstProducts = new List<Product2>();
        Product2 nonOpenOfferProduct = TestDataMaster.initProduct('123999');
        lstProducts.add(nonOpenOfferProduct);
        
        Product2 openOfferProduct = TestDataMaster.initProduct('123990');
        openOfferProduct.Open_Offer_Product__c = true;
        lstProducts.add(openOfferProduct);
        
        insert lstProducts;

        List<No_Charge_Marketing_Order_Product__c> lstNcmoProducts = new List<No_Charge_Marketing_Order_Product__c>();
        
        No_Charge_Marketing_Order_Product__c ncmoNonOpenOfferProduct = new No_Charge_Marketing_Order_Product__c();
        ncmoNonOpenOfferProduct.Product__c = nonOpenOfferProduct.Id;
        ncmoNonOpenOfferProduct.NCMO__c = testNcmo.Id;
        lstNcmoProducts.add(ncmoNonOpenOfferProduct);
        
        No_Charge_Marketing_Order_Product__c ncmoOpenOfferProduct = new No_Charge_Marketing_Order_Product__c();
        ncmoOpenOfferProduct.Product__c = openOfferProduct.Id;
        ncmoOpenOfferProduct.NCMO__c = testNcmo.Id;
        lstNcmoProducts.add(ncmoOpenOfferProduct);

     
        insert lstNcmoProducts;
        
        Test.startTest();
        delete ncmoNonOpenOfferProduct;
        Test.stopTest();
        
        No_Charge_Marketing_Order__c result = [Select Id, Open_Offer_Product__c From No_Charge_Marketing_Order__c
                                               where Id =: testNcmo.Id ];

        System.assert(result.Open_Offer_Product__c, 'NCMO order field updated after deletion of non open offer product');
        
    }
    
    @isTest
    static void testNcmoNoOpenOfferDelete() {
        
        No_Charge_Marketing_Order__c testNcmo = [SELECT Id, Account__c FROM No_Charge_Marketing_Order__c
                                                 WHERE Contact_Email__c = 'ncmo_trigger@testing.com'];

        List<Product2> lstProducts = new List<Product2>();
        Product2 nonOpenOfferProduct1 = TestDataMaster.initProduct('123999');
        lstProducts.add(nonOpenOfferProduct1);
        
        Product2 nonOpenOfferProduct2 = TestDataMaster.initProduct('123990');
        lstProducts.add(nonOpenOfferProduct2);
        
        insert lstProducts;

        List<No_Charge_Marketing_Order_Product__c> lstNcmoProducts = new List<No_Charge_Marketing_Order_Product__c>();
        
        No_Charge_Marketing_Order_Product__c ncmoNonOpenOfferProduct1 = new No_Charge_Marketing_Order_Product__c();
        ncmoNonOpenOfferProduct1.Product__c = nonOpenOfferProduct1.Id;
        ncmoNonOpenOfferProduct1.NCMO__c = testNcmo.Id;
        lstNcmoProducts.add(ncmoNonOpenOfferProduct1);
        
        No_Charge_Marketing_Order_Product__c ncmoNonOpenOfferProduct2 = new No_Charge_Marketing_Order_Product__c();
        ncmoNonOpenOfferProduct2.Product__c = nonOpenOfferProduct2.Id;
        ncmoNonOpenOfferProduct2.NCMO__c = testNcmo.Id;
        lstNcmoProducts.add(ncmoNonOpenOfferProduct2);

     
        insert lstNcmoProducts;
        
        Test.startTest();
        delete ncmoNonOpenOfferProduct2;
        Test.stopTest();
        
        No_Charge_Marketing_Order__c result = [Select Id, Open_Offer_Product__c From No_Charge_Marketing_Order__c
                                               where Id =: testNcmo.Id ];

        System.assert(!result.Open_Offer_Product__c, 'NCMO order field updated after deletion of non open offer product');
        
    }


}
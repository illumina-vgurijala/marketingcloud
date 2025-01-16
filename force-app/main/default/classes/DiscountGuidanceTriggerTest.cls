/**
 *    @author Lovel Panchal
 *    @date   07-May-2024
 *    @description  Test class for DiscountGuidanceTriggerhandler
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Lovel Panchal             07-May-2024            Test class for DiscountGuidanceTriggerhandler class 
 *    ------------------------------------------------------------------------------------ 
 *                       
 */
@isTest
public class DiscountGuidanceTriggerTest {
    @TestSetup
    static void setupTestData() {
        // Create test data for Country Discount Guidance
        List<Discount_Guidance__c> countryDiscounts = new List<Discount_Guidance__c>();
        for(Integer i = 0; i < 1; i++) {
            Discount_Guidance__c countryDiscount = new Discount_Guidance__c(
                Channel__c = 'Direct',
                Discount_Grid_Group__c = 'DNA LP',
                Median_Discount__c = 29, 
                Max_Discount__c = 41, 
                Customer_Discount_Tier__c = '10', 
                Tier_Min__c = 1, 
                Tier_Max__c = 10, 
                Primary_Customer_Type__c = 'Healthcare',
                Discount_Guidance_Level__c = 'Country',
                Country__c = 'BE', 
                CurrencyIsoCode = 'USD',
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addDays(20),
                Tier_Type__c = 'Spend'
            );
            countryDiscounts.add(countryDiscount);
        }
        insert countryDiscounts;
        
        // Create test data for Price List Type Discount Guidance
        List<Discount_Guidance__c> priceListDiscounts = new List<Discount_Guidance__c>();
        for(Integer i = 0; i < 1; i++) {
            Discount_Guidance__c priceListDiscount = new Discount_Guidance__c(
                Channel__c = 'Direct',
                Discount_Grid_Group__c = 'DNA LP',
                Median_Discount__c = 29, 
                Max_Discount__c = 41, 
                Customer_Discount_Tier__c = '10', 
                Tier_Min__c = 1, 
                Tier_Max__c = 10, 
                Primary_Customer_Type__c = 'Healthcare',
                Discount_Guidance_Level__c = 'Price List Type',
                Price_List_Type__c = '11', 
                CurrencyIsoCode = 'USD',
                Start_Date__c = Date.today().addDays(1),
                End_Date__c = Date.today().addDays(30),
                Tier_Type__c = 'Spend'
            );
            priceListDiscounts.add(priceListDiscount);
        }
        insert priceListDiscounts;
    }

    @isTest
    static void testCountryDiscountGuidance() {
        List<Discount_Guidance__c> discounts = [SELECT Id, Text_CountryCurrencyDate__c FROM Discount_Guidance__c WHERE Discount_Guidance_Level__c = 'Country'];
        
        for (Discount_Guidance__c discount : discounts) {
            String expected = 'BE USD ' + Date.today().format() + ' ' + Date.today().addDays(20).format();
            System.assertEquals(expected, discount.Text_CountryCurrencyDate__c, 'Incorrect Text_CountryCurrencyDate__c');
        }
    }  

    @isTest
    static void testPriceListTypeDiscountGuidance() {
        List<Discount_Guidance__c> discounts = [SELECT Id, Text_PriceListTypeCurrencyDate__c FROM Discount_Guidance__c WHERE Discount_Guidance_Level__c = 'Price List Type'];
        
        for (Discount_Guidance__c discount : discounts) {
            String expected = '11 USD ' + Date.today().addDays(1).format() + ' ' + Date.today().addDays(30).format();
            System.assertEquals(expected, discount.Text_PriceListTypeCurrencyDate__c, 'Incorrect Text_PriceListTypeCurrencyDate__c');
        }
    } 

    @isTest
    static void testOverlappingRecords() {
        String strErrorMessage;
        Discount_Guidance__c priceListDiscount = new Discount_Guidance__c(
            Channel__c = 'Direct',
            Discount_Grid_Group__c = 'DNA LP',
            Median_Discount__c = 29, 
            Max_Discount__c = 41, 
            Customer_Discount_Tier__c = '10', 
            Tier_Min__c = 1, 
            Tier_Max__c = 10,
            Tier_Type__c = 'Spend',
            Primary_Customer_Type__c = 'Healthcare',
            Discount_Guidance_Level__c = 'Price List Type',
            Price_List_Type__c = '11', 
            CurrencyIsoCode = 'USD',
            Start_Date__c = Date.today().addDays(7),
            End_Date__c = Date.today().addDays(35)
        );   
        Discount_Guidance__c countryDiscount = new Discount_Guidance__c(
            Channel__c = 'Direct',
            Discount_Grid_Group__c = 'DNA LP',
            Median_Discount__c = 29, 
            Max_Discount__c = 41, 
            Customer_Discount_Tier__c = '10', 
            Tier_Min__c = 1, 
            Tier_Max__c = 10,
            Tier_Type__c = 'Spend',
            Primary_Customer_Type__c = 'Healthcare',
            Discount_Guidance_Level__c = 'Country',
            Country__c = 'BE', 
            CurrencyIsoCode = 'USD',
            Start_Date__c = Date.today().addDays(5),
            End_Date__c = Date.today().addDays(20)
        );
        
        Test.StartTest();
        try {
            insert new List<Discount_Guidance__c> {priceListDiscount, countryDiscount}; 
        } catch(Exception e) {
            strErrorMessage = e.getMessage();
        }
        Test.stopTest();
        Assert.areEqual(true, !String.isBlank(strErrorMessage), 'There are overlapping records, overlap check failed!');
        Assert.areEqual(true, strErrorMessage.contains('Duplicate Record. New record is in between period'), 'Overlapping Period validation failed.');
    } 

    @isTest
    static void testNoOverlappingRecordsAndUpdate() {
        Discount_Guidance__c priceListDiscount = new Discount_Guidance__c(
            Channel__c = 'Direct',
            Discount_Grid_Group__c = 'DNA LP',
            Median_Discount__c = 29, 
            Max_Discount__c = 41, 
            Customer_Discount_Tier__c = '10', 
            Tier_Min__c = 1, 
            Tier_Max__c = 10, 
            Primary_Customer_Type__c = 'Healthcare',
            Discount_Guidance_Level__c = 'Price List Type',
            Price_List_Type__c = '11', 
            CurrencyIsoCode = 'USD',
            Start_Date__c = Date.today().addDays(50),
            End_Date__c = Date.today().addDays(70),
            Tier_Type__c = 'Spend'
        );   
        Discount_Guidance__c countryDiscount = new Discount_Guidance__c(
            Channel__c = 'Direct',
            Discount_Grid_Group__c = 'DNA LP',
            Median_Discount__c = 29, 
            Max_Discount__c = 41, 
            Customer_Discount_Tier__c = '10', 
            Tier_Min__c = 1, 
            Tier_Max__c = 10, 
            Primary_Customer_Type__c = 'Healthcare',
            Discount_Guidance_Level__c = 'Country',
            Country__c = 'BE', 
            CurrencyIsoCode = 'USD',
            Start_Date__c = Date.today().addDays(50),
            End_Date__c = Date.today().addDays(70),
            Tier_Type__c = 'Spend'
        );
        
        Test.StartTest();
        String strErrorMessage;
        try {
            insert new List<Discount_Guidance__c> {priceListDiscount, countryDiscount}; 
        } catch(Exception e) {
            strErrorMessage = e.getMessage();
        }
        Assert.areEqual(true, String.isBlank(strErrorMessage), 'There are overlapping records, overlap check failed!');
        try {
            priceListDiscount.Start_Date__c = Date.today().addDays(10);
            update priceListDiscount;
        } catch(Exception e) {
            strErrorMessage = e.getMessage();
        }
        Test.stopTest();
        Assert.areEqual(true, !String.isBlank(strErrorMessage), 'There are overlapping records, overlap check failed!');
        Assert.areEqual(true, strErrorMessage.contains('Duplicate Record. New record is in between period'), 'Overlapping Period validation failed.');
    } 

    @isTest
    static void testPriceListTypeOverlap() {
        Discount_Guidance__c uniquePriceListTypeDiscount1 = new Discount_Guidance__c(
            Channel__c = 'Direct',
            Discount_Guidance_Level__c = 'Price List Type',
            Country__c = '',
            Price_List_Type__c = '01',
            CurrencyIsoCode = 'USD',
            Customer_Discount_Tier__c = '1',
            Tier_Type__c = 'Credit',
            Tier_Min__c = 0, 
            Tier_Max__c = 9,
            Primary_Customer_Type__c = 'Academic',
            Discount_Grid_Group__c = 'MiSeq i100 Plus System',
            Median_Discount__c = 5,
            Max_Discount__c = 7,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(5)
        );
        Discount_Guidance__c uniquePriceListTypeDiscount2 = new Discount_Guidance__c(
            Channel__c = 'Direct',
            Discount_Guidance_Level__c = 'Price List Type',
            Country__c = '',
            Price_List_Type__c = '02',
            CurrencyIsoCode = 'USD',
            Customer_Discount_Tier__c = '1',
            Tier_Type__c = 'Credit',
            Tier_Min__c = 0, 
            Tier_Max__c = 9,
            Primary_Customer_Type__c = 'Academic',
            Discount_Grid_Group__c = 'MiSeq i100 Plus System',
            Median_Discount__c = 5,
            Max_Discount__c = 7,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(5)
        );
        Discount_Guidance__c duplicatePriceListTypeDiscount1 = new Discount_Guidance__c(
            Channel__c = 'Direct',
            Discount_Guidance_Level__c = 'Price List Type',
            Country__c = '',
            Price_List_Type__c = '01',
            CurrencyIsoCode = 'USD',
            Customer_Discount_Tier__c = '1',
            Tier_Type__c = 'Credit',
            Tier_Min__c = 0, 
            Tier_Max__c = 9,
            Primary_Customer_Type__c = 'Academic',
            Discount_Grid_Group__c = 'MiSeq i100 Plus System',
            Median_Discount__c = 5,
            Max_Discount__c = 7,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(5)
        );
        Discount_Guidance__c duplicatePriceListTypeDiscount2 = new Discount_Guidance__c(
            Channel__c = 'Direct',
            Discount_Guidance_Level__c = 'Price List Type',
            Country__c = '',
            Price_List_Type__c = '02',
            CurrencyIsoCode = 'USD',
            Customer_Discount_Tier__c = '1',
            Tier_Type__c = 'Credit',
            Tier_Min__c = 0, 
            Tier_Max__c = 9,
            Primary_Customer_Type__c = 'Academic',
            Discount_Grid_Group__c = 'MiSeq i100 Plus System',
            Median_Discount__c = 5,
            Max_Discount__c = 7,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(5)
        );
        
        Test.StartTest();
        Integer recordsCreated = 0;
        Integer recordsWithError = 0;
        String strErrorMessage;
        Database.SaveResult[] saveResults = Database.insert(new List<Discount_Guidance__c> {uniquePriceListTypeDiscount1, uniquePriceListTypeDiscount2, duplicatePriceListTypeDiscount1, duplicatePriceListTypeDiscount2}, false);
        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult.isSuccess()) {
                recordsCreated++;
            } else {
                recordsWithError++;
                for (Database.Error error : saveResult.getErrors()) {
                    strErrorMessage = error.message;
                }
            }
        }
        Test.stopTest();
        Assert.areEqual(2, recordsCreated, '2 Records should have been inserted');
        Assert.areEqual(2, recordsWithError, '2 Recors should have not been inserted');
        Assert.areEqual(true, strErrorMessage.contains('Duplicate Record. New record is in between period'), 'Overlapping Period validation failed.');
    }

    @isTest
    static void testCountryOverlap() {
        Discount_Guidance__c uniqueCountryDiscount1 = new Discount_Guidance__c(
            Channel__c = 'Indirect',
            Discount_Guidance_Level__c = 'Country',
            Country__c = 'SZ;SY',
            Price_List_Type__c = '',
            CurrencyIsoCode = 'USD',
            Customer_Discount_Tier__c = '1',
            Tier_Type__c = 'Credit',
            Tier_Min__c = 0, 
            Tier_Max__c = 9,
            Primary_Customer_Type__c = 'Academic',
            Discount_Grid_Group__c = 'MiSeq i100 Plus System',
            Median_Discount__c = 5,
            Max_Discount__c = 7,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(5)
        );
        Discount_Guidance__c uniqueCountryDiscount2 = new Discount_Guidance__c(
            Channel__c = 'Indirect',
            Discount_Guidance_Level__c = 'Country',
            Country__c = 'CN',
            Price_List_Type__c = '',
            CurrencyIsoCode = 'USD',
            Customer_Discount_Tier__c = '1',
            Tier_Type__c = 'Credit',
            Tier_Min__c = 0, 
            Tier_Max__c = 9,
            Primary_Customer_Type__c = 'Academic',
            Discount_Grid_Group__c = 'MiSeq i100 Plus System',
            Median_Discount__c = 5,
            Max_Discount__c = 7,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(5)
        );
        Discount_Guidance__c duplicateCountryDiscount1 = new Discount_Guidance__c(
            Channel__c = 'Indirect',
            Discount_Guidance_Level__c = 'Country',
            Country__c = 'SZ',
            Price_List_Type__c = '',
            CurrencyIsoCode = 'USD',
            Customer_Discount_Tier__c = '1',
            Tier_Type__c = 'Credit',
            Tier_Min__c = 0, 
            Tier_Max__c = 9,
            Primary_Customer_Type__c = 'Academic',
            Discount_Grid_Group__c = 'MiSeq i100 Plus System',
            Median_Discount__c = 5,
            Max_Discount__c = 7,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(5)
        );
        Discount_Guidance__c duplicateCountryDiscount2 = new Discount_Guidance__c(
            Channel__c = 'Indirect',
            Discount_Guidance_Level__c = 'Country',
            Country__c = 'CN',
            Price_List_Type__c = '',
            CurrencyIsoCode = 'USD',
            Customer_Discount_Tier__c = '1',
            Tier_Type__c = 'Credit',
            Tier_Min__c = 0, 
            Tier_Max__c = 9,
            Primary_Customer_Type__c = 'Academic',
            Discount_Grid_Group__c = 'MiSeq i100 Plus System',
            Median_Discount__c = 5,
            Max_Discount__c = 7,
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(5)
        );
        
        Test.StartTest();
        Integer recordsCreated = 0;
        Integer recordsWithError = 0;
        String strErrorMessage;
        Database.SaveResult[] saveResults = Database.insert(new List<Discount_Guidance__c> {uniqueCountryDiscount1, uniqueCountryDiscount2, duplicateCountryDiscount1, duplicateCountryDiscount2}, false);
        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult.isSuccess()) {
                recordsCreated++;
            } else {
                recordsWithError++;
                for (Database.Error error : saveResult.getErrors()) {
                    strErrorMessage = error.message;
                }
            }
        }
        Test.stopTest();
        Assert.areEqual(2, recordsCreated, '2 Records should have been inserted');
        Assert.areEqual(2, recordsWithError, '2 Recors should have not been inserted');
        Assert.areEqual(true, strErrorMessage.contains('Duplicate Record. New record is in between period'), 'Overlapping Period validation failed.');
    }
}
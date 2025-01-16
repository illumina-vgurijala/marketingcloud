/**
*    @author: Vinay 
*    @date:   05-Sep-2024
*    @description:  Test class for BatchtoUpdatePromotypeAndPrimaryLine 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Vinay                        05-Sep-2024        Initial Development
*    ------------------------------------------------------------------------------------ 
*                    
*/

@isTest
public with sharing class TestBatchtoUpdatePromotypeAndPrimaryLine {
    

    
/**
* @authorVinay S Reddy
* @description setup test data for plan records
**/
@testSetup
public static void setupData()
    { 

        Promotions__c testPromotion = new Promotions__c();
        testPromotion.Name = 'Test Record';
        testPromotion.Promotion_Code__c = '1234';
        testPromotion.Primary_Product_Line__c = 'Test Line (Test Promo Type)';
        testPromotion.Active__c = true;
        insert testPromotion;

    }

    @isTest
    /**
* @author Vinay S Reddy
* @description execute the test data
**/
public static void method1(){
 
 
        Test.startTest();
             Database.executeBatch(new BatchtoUpdatePromotypeAndPrimaryLine());
        Test.stopTest();
        List<Promotions__c> promoAfterDataUpdate = new List<Promotions__c>();
        promoAfterDataUpdate = [Select Id ,Name,Primary_Product_Line__c,Promo_Type__c,Active__c From Promotions__c Where Active__c=true Limit 1];
        Assert.areEqual('Test Promo Type',promoAfterDataUpdate[0].Promo_Type__c,'Promo Type is not Matching');
    }

}
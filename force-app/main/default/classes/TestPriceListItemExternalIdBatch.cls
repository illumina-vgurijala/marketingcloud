/*
 * @Author: Rishab Wali
 * @Date: 03-APR-2020
 * @Description : Test Class for Batch to Update External Id on Price List Item Records
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rishab Wali            03-APR-2020                   Test Class For PriceListItemExternalIdBatch Class(DCP 33826)
 */
@isTest
public class TestPriceListItemExternalIdBatch {
    /*
 * @Author: Rishab Wali
 * @Date: 03-APR-2020
 * @Description : Test method for Batch to Update External Id on Price List Item Records
 */
    @isTest
    public static void testMethod1()
    {
        Account acc = TestDataAccount.getUCAccount();
        insert acc;
        DateTime dt = system.now();
        Datetime newDateTime = dt.addDays(2);
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c(Apttus_Config2__Type__c='Standard',External_Id__c='12345566776',
                                                                                  Apttus_Config2__AccountId__c=acc.Id,Apttus_Config2__Active__c=true,
                                                                                  Apttus_Config2__EffectiveDate__c=dt);
        insert priceList;
        
        Product2 product = new Product2(Name='Test Product',ProductCode='121212',IsActive=true);
        insert product;
    
        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c(Apttus_Config2__PriceListId__c=priceList.Id,
                                                                                   Apttus_Config2__ProductId__c=product.Id,
                                                                                   Apttus_Config2__ChargeType__c='Standard Price',
                                                                                   Apttus_Config2__Active__c=true,
                                                                                   Apttus_Config2__EffectiveDate__c=dt,
                                                                                   Apttus_Config2__ExpirationDate__c =newDateTime);
        insert pli;
        
        test.startTest();
        PriceListItemExternalIdBatch pliBatch = new PriceListItemExternalIdBatch();
        Database.executeBatch(pliBatch);
        test.stopTest();
        Apttus_Config2__PriceListItem__c pliData = [SELECT Id,External_Id__c FROM Apttus_Config2__PriceListItem__c WHERE Id=: pli.Id];
        System.assertEquals(false,String.isBlank(pliData.External_Id__c));
    }
    
}
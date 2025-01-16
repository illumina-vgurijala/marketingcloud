/**
*    @author: Sravan 
*    @date:   20-Jan-2021
*    @description:  Test Class for  BatchToExpireCalibratedTools batch class.
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*             Sravan                   20-Jan-2021           Initial Development            
*/
@isTest
public class TestBatchToExpireCalibratedTools {
    @isTest
    static void createUpdateInstalledProduct()
    { 

        Id installedProductsRecortTypeTools = Schema.SObjectType.SVMXC__Installed_Product__c.getRecordTypeInfosByName().get('Tools').getRecordTypeId();  	
        // parent records
        Product2 objProduct = TestDataMaster.initProduct('Test 1234');
        objProduct.Service_Product_Type__c = 'Consumable';
        insert objProduct;

        // add record
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test Product', 'USD', 'New');
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
		objInstalledProduct.RecordTypeId = installedProductsRecortTypeTools;
        insert objInstalledProduct;
		System.assert(objInstalledProduct != null);
        
        objInstalledProduct.SVMXC__Status__c = 'Calibrated';
        objInstalledProduct.Tool_Calibration_Due_Date__c = Date.Today() -1;
        update objInstalledProduct;
		System.assertEquals('Calibrated',objInstalledProduct.SVMXC__Status__c);
        SchedulableContext ctx;
        BatchToExpireCalibratedTools objBatchClass = new BatchToExpireCalibratedTools();
        objBatchClass.execute(ctx);
        Database.executeBatch(objBatchClass);
         
    }
}
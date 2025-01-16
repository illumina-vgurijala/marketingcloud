/*@ author       : Tapas C
* @ date         : 25-Jun-2019
* @ Description  : Test class for WorkOrderSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Digvijay              25-Jun-2019                                   Initial version 
* 
*/
@isTest
public class TestStockedSerialSelector 
{
    /* @author - Tapas
     * @description - to test StockedSerialSelector class
     */
    @isTest
    public static void testStockedSerialSelectorMethod()
    {
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc;
            
        Account objAccount =TestDataAccount.initAccount();
        insert objAccount;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataInstalledProduct.initInstalledProduct(objAccount.Id);
        objInstalledProduct.SVMXC__Serial_Lot_Number__c = TestData.getRandomNumeric(4);
        insert objInstalledProduct;
            
        Product2 objProduct = TestDataMaster.initProduct('1241527');
        objProduct.Service_Product_Type__c = 'Core';
        objProduct.SVMXC__Tracking__c = 'Serialized';
        insert objProduct;
        
        SVMXC__Product_Stock__c objProductStock = new SVMXC__Product_Stock__c();
        objProductStock.SVMXC__Product__c = objProduct.Id;
        objProductStock.SVMXC__Location__c = objLoc.Id;
        objProductStock.SVMXC__Status__c = 'Available';
        insert objProductStock;
        
        SVMXC__Product_Serial__c objStockedSerial = new SVMXC__Product_Serial__c();
        objStockedSerial.SVMXC__Product__c = objProduct.Id;
        objStockedSerial.SVMXC__Product_Stock__c = objProductStock.Id;
        objStockedSerial.SVMX_PS_VS_Linked_Installed_Product__c = objInstalledProduct.Id;
        objStockedSerial.Quantity__c = 3;
        objStockedSerial.SVMX_PS_External_ID__c = '000';
        objStockedSerial.Batch_Number__c = '3';
        insert objStockedSerial;
        
        Set<Id> setselectStockedSerialById = new Set<Id>{objStockedSerial.Id};
        Set<Id> setProductStockId = new Set<Id>{objProductStock.Id};
  		Set<Id> setProductId = new Set<Id>{objProduct.Id};
  		List<Id> lstProductId = new List<Id>{objProduct.Id};
        Set<String> strExternalId = new Set<String>{objStockedSerial.SVMX_PS_External_ID__c};
        
        Test.startTest();
        StockedSerialSelector selector = new StockedSerialSelector();
        selector.selectStockedSerialByExternalId(strExternalId);
        selector.selectStockedSerialById(setselectStockedSerialById);
       // List<SVMXC__Product_Serial__c> lstProductSerial =  new StockedSerialSelector().selectStockedSerialByExternalId(strExternalId);
        //System.assert(lstProductSerial.size()>0);
        Test.stopTest();
         
        System.assertEquals(objStockedSerial.Id, (new StockedSerialSelector().selectStockedSerialByProductStockExtId(setProductStockId))[0].Id);
        System.assertEquals(objStockedSerial.Id, (new StockedSerialSelector().selectStockedSerialByConProductAndProduct(setProductStockId, setProductId))[0].Id);
        System.assertEquals(objStockedSerial.Id, (new StockedSerialSelector().selectStockedSerialByProductStockAndProduct(setProductStockId, lstProductId))[0].Id);       
    }
}
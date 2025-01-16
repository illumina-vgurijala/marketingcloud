/*@ author       : Tapas
* @ date         : 21-Jun-2019
* @ Description  : Test class for WorkOrderResourceSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Tapas                   21-Jun-2019                                  Initial version
* Rohan                   23-Mar-2022                                  DCP-49682   Elevation 1.0 Code Removal
* Shivani                 16-Sep-2022                                  DCP-52682   Added coverage for selectIPsWithAttributeHistory method
*/
@isTest
global with sharing class TestInstalledProductsSelector 
{
    testMethod static void methodToIncreaseCoverage()
    {
        List<SVMXC__Installed_Product__c> lstInstalledProducts = new List<SVMXC__Installed_Product__c>();
        
        Account objAccount =TestDataAccount.initAccount();
        insert objAccount;
        
        Product2 productObj = new Product2();
        productObj.Name = 'Test';
        productObj.Condition_Type__c = 'LOANER';
        productObj.Serial_Number_Profile__c = 'IL02';
        productObj.ProductCode = '0124';
        insert productObj;
        
        SVMXC__Site__c loc = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
        insert loc;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataInstalledProduct.initInstalledProduct(objAccount.Id);
        objInstalledProduct.SVMXC__Serial_Lot_Number__c = TestData.getRandomNumeric(4);
        objInstalledProduct.SVMXC__Product__c = productObj.id;
        objInstalledProduct.SVMXC__Site__c = loc.id;
		objInstalledProduct.Name = 'Test';
        insert objInstalledProduct;
        
         
        
        lstInstalledProducts.add(objInstalledProduct);
        
        Set<Id> setInstallProdIds = new Set<Id>{objInstalledProduct.Id};
        Set<Id> accountIds = new Set<Id>{objAccount.Id};
        Set<String> setEquipmentIds = new Set<String>{objInstalledProduct.ERP_Equipment_ID__c};
        Set<String> setSerialLotNumbers = new Set<String>{objInstalledProduct.SVMXC__Serial_Lot_Number__c};
        List<Id> lstInstallProdIds = new List<Id>{objInstalledProduct.Id};
        List<String> lstSerialLotNumbers = new List<String>{objInstalledProduct.SVMXC__Serial_Lot_Number__c};
        Set<Id> setRecordIDsWithNoAccount = new Set<Id>{loc.Id};
        
        
        InstalledProductsSelector ipselectorClass = new InstalledProductsSelector();
        Test.startTest(); 
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selectInstallProductsForEquipmentIds(setEquipmentIds))[0].Id);
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selectByAccountIds(accountIds))[0].Id);
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selectRelatedInstalledProducts(setInstallProdIds))[0].Id);       
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selectInstallProductsForSerialLotNumber(setSerialLotNumbers))[0].Id);
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selectInstalledProductsFromIds(setInstallProdIds))[0].Id);
        System.assert(ipselectorClass.selectLatestIP()!=null, 'List should not be empty');
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selectLoanerInstalledProductById(lstInstallProdIds))[0].Id);
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selectInstalledProductByAccountAndSerialNumber(accountIds,lstSerialLotNumbers,true))[0].Id);                                               
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selecInstalledProductsFromLocation(setRecordIDsWithNoAccount))[0].Id);
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selectInstalledProductByIds(setInstallProdIds))[0].Id);
        System.assertEquals(lstInstalledProducts[0].Id, (ipselectorClass.selectInstalledProductsFromEquipmentId(setEquipmentIds))[0].Id);// added by dhairya for code coverage
        ipselectorClass.selectIPsFromProductExtIds(new Set<String>{'12345678'});
		ipselectorClass.selectIPForSerialNumber(objInstalledProduct.Name);//Added as per of DCP-44003
        ipselectorClass.selectIPsWithId(new List<Id>{objInstalledProduct.Id});//Added as per of CMCM-263
        ipselectorClass.selectIPsWithAccountIdandSearch(objAccount.Id,productObj.ProductCode);
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = objInstalledProduct.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<SVMXC__Installed_Product__c> installProductResult = ipselectorClass.selectIPsWithSearchWithSOSL(productObj.ProductCode);
        Assert.areEqual(1, installProductResult.size(),'did not returned Install Product');
        ipselectorClass.selectInstalledProductsByName(objInstalledProduct.Name); // added by dhairya for code coverage
		Test.stopTest();
    }

    /*******************************************************************************************************
    * @description DCP-52682 test method for selectIPsWithAttributeHistory
    */
    testMethod static void testSelectIPsWithAttributeHistory() {
        
        Account objAccount =TestDataAccount.initAccount();
        insert objAccount;
        System.assert(objAccount.Id != NULL, 'Account insertion failed');
        
        Product2 productObj = new Product2();
        productObj.Name = 'Test Prod';
        productObj.Condition_Type__c = 'LOANER';
        productObj.Serial_Number_Profile__c = 'IL02';
        insert productObj;
        System.assert(productObj.Id != NULL, 'Product insertion failed');
        
        SVMXC__Site__c loc = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
        insert loc;
        System.assert(loc.Id != NULL, 'Location insertion failed');
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataInstalledProduct.initInstalledProduct(objAccount.Id);
        objInstalledProduct.SVMXC__Serial_Lot_Number__c = TestData.getRandomNumeric(4);
        objInstalledProduct.SVMXC__Product__c = productObj.id;
        objInstalledProduct.SVMXC__Site__c = loc.id;
		objInstalledProduct.Name = 'Test';
        insert objInstalledProduct;
        System.assert(objInstalledProduct.Id != NULL, 'IP Record insertion failed');
        
        List<SVMXC__Installed_Product__c> listIP = new InstalledProductsSelector().selectIPsWithAttributeHistory(new Set<Id>{objInstalledProduct.Id});
        System.assert(!listIP.isEmpty(), 'selectIPsWithAttributeHistory method failed ');
    }
    
}
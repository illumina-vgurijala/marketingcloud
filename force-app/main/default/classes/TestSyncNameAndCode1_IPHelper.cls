/**
* @author Shivani Jain
* @date 23 Aug 2022
*
* @description DCP-50068 Test class for SyncNameAndCode1_InstalledProductHelper
*/ 
@IsTest
private class TestSyncNameAndCode1_IPHelper {

    /*******************************************************************************************************
    * @description DCP-50068 - Test Method for populateFields & generateName
    */
    static testmethod void testpopulateFields() {
        Account testAccount = TestDataAccount.initAccount();
        insert testAccount;
        system.assertNotEquals(null, testAccount.Id, 'Account insertion failed');

        //insert product
        Product2 objProd = TestDataMaster.getNewProduct('Test Prod', 'Instrument');
        System.assertNotEquals(null, objProd.Id, 'Product insertion failed');

        Test.startTest();
        //insert instprod
        SVMXC__Installed_Product__c instProd = TestDataInstalledProduct.initInstalledProduct(testAccount.Id); 
        instProd.SVMXC__Serial_Lot_Number__c = '12456';
        insert instProd;
        System.assertNotEquals(null, instProd.Id, 'Installed Product insertion failed');
        
        instProd.SVMXC__Product__c = objProd.Id;
        update instProd;

        instProd.SVMXC__Serial_Lot_Number__c = '12312';
        update instProd;
        
        instProd.SVMXC__Product__c = null;
        instProd.Product_Code1__c = '1234534';
        update instProd;
        

        Test.stopTest();
        
        SVMXC__Installed_Product__c updatedIpRec = [SELECT id, Name FROM SVMXC__Installed_Product__c where Id =: instProd.id];
        System.assertEquals(updatedIpRec.Name, instProd.SVMXC__Serial_Lot_Number__c + '-' + instProd.Product_Code1__c, 'Installed Product Id population logic failed');
       
    }
}

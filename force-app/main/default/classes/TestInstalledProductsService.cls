/***************************************************************************************************************************************
 * NAME   : TestInstalledProductsService
 * DESCRIPTION  : TestClass for InstalledProductsService
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 09-July-2019 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                    DATE                    DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth                10-July-2019                Initial Version
 * Ashwin                   2022-03-31                  DCP-52339 Remove TestTAPS.setupDeferredObjectData
 * Gerardo Garcia           2023-12-07                  CMCM-4772 Fix Assert of installedProductServiceTest
  ****************************************************************************************************************************************/ 

@isTest
private class TestInstalledProductsService {
    /**
    * method : setupEtmData
    * Description: method is to create test data.
    * params: NA
    * return: void
    * author: prashanth
    **/
    @testSetup 
    static void setupEtmData(){
        TestTAPS.setupTerritoryDataWithPartners();
    }

    /**
    * method : installedProductServiceTest
    * Description: method is to test installedProductService.
    * params: NA
    * return: void
    * author: prashanth
    **/
	@isTest 
	static void installedProductServiceTest(){
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Assert.isTrue(accountIds.size() > 0);
        List<Account> accList = [Select Id,name,Product_Group__c,Regulatory_Type__c from Account];
        accountIds.add(accList[0].Id);
    
        Account acc = new Account(Id = accList[0].Id);
        acc.Product_Group__c = 'All';
        acc.Regulatory_Type__c = 'All';
        update acc;
        Assert.isNotNull(acc?.Id);
        //insert product
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Service_Level__c = 'BASIC';
        insert product1;
        Assert.isNotNull(product1?.Id);
        
        SVMXC__Installed_Product__c ip1 = TestDataInstalledProduct.getNewInstalledProduct(accList[0].Id);
        ip1.SVMXC__Product__c = product1.Id;
        update ip1;
        Assert.areEqual(product1.Id, ip1.SVMXC__Product__c, 'Product Id should match with the Installed product\'s SVMXC__Product__c');
        
        SVMXC__Installed_Product__c ip2 = TestDataInstalledProduct.getNewInstalledProduct(accountIds.get(0));
        ip2.SVMXC__Product__c = product1.Id;
        update ip2;
        Assert.isNotNull(ip2?.Id);
        
        SVMXC__Installed_Product__Share share1 = new SVMXC__Installed_Product__Share();
        share1.ParentId = ip2.Id;
        share1.UserOrGroupId = UserInfo.getUserId();
        share1.RowCause = Schema.SVMXC__Installed_Product__Share.RowCause.Distributor__c;
        share1.AccessLevel = 'Read';
        insert share1;
        Assert.isNotNull(share1?.Id);

        Test.startTest();
        InstalledProductsService.shareWithDistibutorUsersByUC(new Set<Id>(accountIds));
        Test.stopTest();

        Assert.areEqual(2, TestTAPS.getShareRecordCount(new TAPS_InstalledProducts(), ip2.Id, new List<String>{Schema.SVMXC__Installed_Product__Share.RowCause.Distributor__c}));
    }
    /**
    * method : testUpdaterelatedInstalledProducts
    * Description: method added as part of DCP-43261/TASK0548217
    * params: NA
    * return: void
    * author: Satya Swain
    **/
    @isTest
    static void testUpdateIPUpgradeTypes()
    {
        List<Id> accountIds = TestTAPS.createParentAccounts();
        SVMXC__Installed_Product__c ip1 = TestDataInstalledProduct.getNewInstalledProduct(accountIds.get(0));

        // add record
        SVMXC__SM_IB_Technical_Attributes__c rec1;
        rec1 = TestDataInstalledProduct.initTechnicalAttributes(ip1.Id);
        rec1.SVMXC__SM_Attr_Name__c = 'NIPT Enablement Server Upgrade Type';
        rec1.SVMXC__SM_IsActive__c = true;
        rec1.SVMXC__SM_Attr_Value__c = 'IVD Upgrade';

        insert rec1;

        SVMXC__Installed_Product__c objInstalledProduct = [Select  Id,Installed_Product_Upgrade_Type__c from SVMXC__Installed_Product__c LIMIT 1];
        Assert.areEqual('IVD', objInstalledProduct.Installed_Product_Upgrade_Type__c);
    }

}
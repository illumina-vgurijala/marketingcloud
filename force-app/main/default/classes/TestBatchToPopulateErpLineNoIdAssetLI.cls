@isTest(SeeAllData=false isParallel=false)

public with sharing class TestBatchToPopulateErpLineNoIdAssetLI {
    static testMethod voId testBatch() {

        Account acc = TestDataAccount.getNewAccount();
        //insert acc;
        Product2 objProduct = TestDataMaster.createProduct(true);
        String todayDate=Datetime.now().format('yyyy-MM-dd');
        Date dtToday = Date.valueOf(todayDate);
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c='0002';
        orders.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        orders.Ultimate_Consignee_ERP_Id__c='123456';
        orders.Apttus_Config2__PODate__c=Date.valueOf('2018-10-30');
        orders.Apttus_Config2__PONumber__c='76543';
        orders.Order_Status__c = 'Open';
        orders.Sales_Order_Number_Unique__c ='TEST123';
		orders.Apttus_Config2__SoldToAccountId__c=acc.Id;
        insert orders;

        Apttus_Config2__AssetLineItem__c objAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem.Apttus_Config2__AccountId__c = acc.Id;
        objAssetLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objAssetLineItem.Serial_Number__c = '123123';
        objAssetLineItem.Contract_Number__c = '453523413';
        objAssetLineItem.Contract_Type__c = 'test Contract Type';
        objAssetLineItem.Apttus_Config2__EndDate__c = dtToday+6;
        objAssetLineItem.Apttus_Config2__StartDate__c = dtToday;
        insert objAssetLineItem;

        Apttus_Config2__OrderLineItem__c soli = new Apttus_Config2__OrderLineItem__c();
        soli.Apttus_Config2__StartDate__c = dtToday - 6;
        soli.Apttus_Config2__OrderId__c = orders.id;
        soli.ERP_Line_Number_Id__c = 'TEST123_00100';
        soli.Apttus_Config2__AssetLineItemId__c = objAssetLineItem.Id;
        insert soli;

        Apttus_Config2__AssetLineItem__c lstasi1 = [SELECT id, ERP_Line_Number_Id__c FROM Apttus_Config2__AssetLineItem__c];
        System.debug('lstasi1 -->' + lstasi1);

        test.startTest();
        BatchToPopulateErpLineNoIdAssetLI obj = new BatchToPopulateErpLineNoIdAssetLI();				
		Id idBatchId = Database.executeBatch(obj, 1);
        system.debug('Batch IDD -->:' + idBatchId);
        test.stopTest();
        
        Apttus_Config2__AssetLineItem__c lstasi = [SELECT id, ERP_Line_Number_Id__c FROM Apttus_Config2__AssetLineItem__c];
        System.debug('lstasi -->' + lstasi);

        System.assertEquals(soli.ERP_Line_Number_Id__c, lstasi.ERP_Line_Number_Id__c);

    }



}
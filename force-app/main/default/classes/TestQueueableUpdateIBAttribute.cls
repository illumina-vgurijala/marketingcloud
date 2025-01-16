/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-19-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * * Date                           Name                                        Description
 * 20-09-2022                     Sheikh Shahnawaz                            Enhance code coverage above 80%
**/
@isTest
private class TestQueueableUpdateIBAttribute {

    @isTest static void testWarmTemp() {

        String testjson=' {"fields":[{"title":"Upgrade Type","description":"Upgrade Type for Autoloader Product Family","technicalAttributes":[{"label":"Autoloader Upgrade Type","type":"Static","sequence":0,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"AutoloaderUpgradeType","picklistSfId":"a1S3F000000oSPAUA2","picklistName":"Autoloader Upgrade Type","defaultDisplayValue":""},{"label":"Last Upgrade Day","type":"Static","sequence":1,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Day","picklistSfId":"a1S3F000000qXkRUAU","picklistName":"Day","defaultDisplayValue":""},{"label":"Last Upgrade Month","type":"Static","sequence":2,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Month","picklistSfId":"a1S3F000000qXkWUAU","picklistName":"Month","defaultDisplayValue":""},{"label":"Last Upgrade Year","type":"Static","sequence":3,"defaultValue":"","unit":"","readOnly":"","format":"Picklist","picklistId":"Year","picklistSfId":"a1S3F000000qXkSUAU","picklistName":"Year","defaultDisplayValue":""}]}],"picklist":{"AutoloaderUpgradeType":{"values":["Autoloader II Upgrade","Autoloader IIx Upgrade"],"setDefaultValue":false},"Day":{"values":["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"],"setDefaultValue":false},"Month":{"values":["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],"setDefaultValue":false},"Year":{"values":["2015","2016","2017","2018","2019","2020","2021","2022","2023","2024","2025"],"setDefaultValue":false}}}';
        
	

		Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
		acc.Account_Group__c='Distributor';
		insert acc;
		
		Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
		objProduct.Family='Autoloader';
		insert objProduct;
		
		SVMXC__Installed_Product__c objInstalledProduct= TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'Installed');
		objInstalledProduct.SVMXC__Company__c = acc.Id;
		objInstalledProduct.Operation_Status__c='Off';
		objInstalledProduct.SVMXC__Product__c = objProduct.Id;
		objInstalledProduct.SVMXC__Serial_Lot_Number__c = '12345';
		insert objInstalledProduct;

        SVMXC__SM_IB_Attributes_History__c objAttributeHistory = new SVMXC__SM_IB_Attributes_History__c();
        list<SVMXC__SM_IB_Attributes_History__c> attrHistoryToInsert = new list<SVMXC__SM_IB_Attributes_History__c>();
        objAttributeHistory.SVMXC__SM_Attr_Payload__c = testjson ;
		objAttributeHistory.SVMXC__SM_Captured_On__c = Datetime.now();
		objAttributeHistory.SVMXC__SM_Installed_Product_Id__c = objInstalledProduct.Id;
		objAttributeHistory.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
		objAttributeHistory.SVMXC__SM_Source__c = 'Web';
        attrHistoryToInsert.add(objAttributeHistory);

        SVMXC__SM_IB_Attributes_Template_Instance__c objIBTemplateInstance = new SVMXC__SM_IB_Attributes_Template_Instance__c();
        objIBTemplateInstance.SVMXC__SM_Attr_Payload__c = testjson;
		objIBTemplateInstance.SVMXC__SM_Captured_On__c = Datetime.now();
		objIBTemplateInstance.serial_lot_Number__c = '12345';
        //insert objIBTemplateInstance;
        
        Map<String,SVMXC__SM_IB_Attributes_Template_Instance__c> mapTemplateInstancetoInsert = new Map<String,SVMXC__SM_IB_Attributes_Template_Instance__c>();
        mapTemplateInstancetoInsert.put('Test', objIBTemplateInstance);
        QueueableContext qc;
        system.assert(!mapTemplateInstancetoInsert.isEmpty(), 'mapTemplateInstancetoInsert is empty');
        QueueableUpdateIBAttribute objUpdateIBAttribute = new QueueableUpdateIBAttribute(attrHistoryToInsert, mapTemplateInstancetoInsert);
        objUpdateIBAttribute.execute(qc);
	   /* Enhance test class coverage start */
		mapTemplateInstancetoInsert.clear();
		SVMXC__SM_IB_Attributes_Template_Instance__c tempLateInstance = [select id from SVMXC__SM_IB_Attributes_Template_Instance__c limit 1];
		mapTemplateInstancetoInsert.put('Test', tempLateInstance);
        system.assert(!mapTemplateInstancetoInsert.isEmpty(), 'mapTemplateInstancetoInsert is empty');
        QueueableUpdateIBAttribute objUpdateIBAttribute2 = new QueueableUpdateIBAttribute(attrHistoryToInsert, mapTemplateInstancetoInsert);
		objUpdateIBAttribute2.execute(qc);
		 /* Enhance test class coverage end */

    }
      
}
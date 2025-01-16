/*********************************************************************************************************************
* @description : Test classfor EquipmentMasterDataReceiver
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Pooja                    23-09-2022          CodeScan Fixes
* Pooja                    14-12-2022          To test functionality of DCP-56196
****************************************************************************************************************************************/ 

@isTest
public class TestEquipmentMasterDataReceiver {


/*
* @author : KD
* @description : create installed products JSON
*/
  public static EquipmentMasterDataReceiverWrapper.InstalledProducts getinstallProductJson(String serialNumber, String erpEquimntId, String assetType, String salesOrderNumber, String company, String product, String topLevel, String parent, String costCenter, String originPlant, String prevEquipNumber, String nextEquipNumber) {

    //create a child array record.
    EquipmentMasterDataReceiverWrapper.InstallBase childInstPrdRecords = new EquipmentMasterDataReceiverWrapper.InstallBase();
    childInstPrdRecords.ERP_Equipment_Id = erpEquimntId;
    childInstPrdRecords.SVMXC_Serial_Lot_Number = serialNumber;
    childInstPrdRecords.SVMXC_Product = product;
    childInstPrdRecords.SVMXC_Top_Level = topLevel;
    childInstPrdRecords.SVMXC_Parent = Parent;

    EquipmentMasterDataReceiverWrapper.InstalledProducts instPrdRecords = new EquipmentMasterDataReceiverWrapper.InstalledProducts();
    instPrdRecords.SVMXC_Serial_Lot_Number = serialNumber;
    instPrdRecords.ERP_Equipment_Id = erpEquimntId;
    instPrdRecords.Asset_Type = assetType;
    instPrdRecords.SVMXC_Sales_Order_Number = salesOrderNumber;
    instPrdRecords.SVMXC_Company = company;
    instPrdRecords.SVMXC_Product = product;
    instPrdRecords.SVMXC_Top_Level = topLevel;
    instPrdRecords.SVMXC_Parent = Parent;
    instPrdRecords.SVMXC_Date_Ordered = '2018-10-18';
    instPrdRecords.SVMXC_Date_Shipped = '2018-10-18';
    instPrdRecords.Cost_Center = costCenter;
    instPrdRecords.Country_of_Origin = 'IN';
    instPrdRecords.Plant_of_Origin = originPlant;
    instPrdRecords.Previous_Equipment_Number = prevEquipNumber;
    instPrdRecords.Next_Equipment_Number = nextEquipNumber;
    instPrdRecords.InstallBase.add(childInstPrdRecords);

    return instPrdRecords;
  }

  static testMethod void testProductInsertHTTPPost() {

    List < EquipmentMasterDataReceiverWrapper.InstalledProducts > lstInstProductRecords = new List < EquipmentMasterDataReceiverWrapper.InstalledProducts > ();
    // Product Data
    Product2 pr = new Product2();
    pr.Name = 'DummyProduct';
    pr.ProductCode = '15045005';
    pr.Material_Number__c = '12345';
    pr.IsActive = true;
    insert pr;
    // Account Data
    Account testAccount1 = TestDataAccount.getNewAccount();
    //testAccount1.ERP_Customer_Id__c='897';

    // Top level Data
    SVMXC__Installed_Product__c tprd = new SVMXC__Installed_Product__c();
    tprd.ERP_Equipment_Id__c = '1234';
    tprd.SVMXC__Company__C = testAccount1.Id;
    tprd.Acceptance_Date__c = Date.valueOf('2018-10-18');
    tprd.SVMXC__Date_Installed__c = Date.valueOf('2018-10-18');
    insert tprd;

    // Parent Data
    SVMXC__Installed_Product__c pprd = new SVMXC__Installed_Product__c();
    pprd.ERP_Equipment_Id__c = '5678';
    pprd.SVMXC__Company__C = testAccount1.Id;
    pprd.Acceptance_Date__c = Date.valueOf('2018-10-18');
    pprd.SVMXC__Date_Installed__c = Date.valueOf('2018-10-18');
    insert pprd;

    // For Upsert
    SVMXC__Installed_Product__c uiprd = new SVMXC__Installed_Product__c();
    uiprd.ERP_Equipment_Id__c = '333';
    uiprd.SVMXC__Company__C = testAccount1.Id;
    uiprd.Acceptance_Date__c = Date.valueOf('2018-10-18');
    uiprd.SVMXC__Date_Installed__c = Date.valueOf('2018-10-18');
    insert uiprd;

    EquipmentMasterDataReceiverWrapper.InstalledProducts instPrdRecords = getinstallProductJson('200131', '333', 'COLLABRN', '9', '897', '12345', '1234', '5678', '3044100', '3310', '12344', '1233445');

    lstInstProductRecords.add(instPrdRecords);

    EquipmentMasterDataReceiverWrapper.InstalledProducts instPrdRecords1 = getinstallProductJson('200131', '9999', 'COLLABRN', '9', '897', '12345', '1234', '5678', '3044100', '3310', '12344', '1233445');

    lstInstProductRecords.add(instPrdRecords1);

    EquipmentMasterDataReceiverWrapper.InstalledProducts instPrdRecords2 = getinstallProductJson('200131', '666', 'COLLABRN', '9', '897', '12345', '1234', '5678', '3044100', '3310', '12344', '1233445');

    lstInstProductRecords.add(instPrdRecords2);

    String prdJSON = JSON.serialize(lstInstProductRecords);


    Test.startTest();

    //As Per Best Practice it is important to instantiate the Rest Context 
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/EquipmentMasterSyncInterface';
    req.httpMethod = 'POST';
    req.requestBody = Blob.valueof(prdJSON);
    RestContext.request = req;
    RestContext.response = res;
    EquipmentMasterDataReceiver.upsertIncomingValues();

    Test.stopTest();

    System.assertequals(200, res.statuscode);


    List < SVMXC__Installed_Product__c > instPrdRecds = new List < SVMXC__Installed_Product__c > ();
    instPrdRecds = [Select id from SVMXC__Installed_Product__c where SVMXC__Serial_Lot_Number__c = '200131'];
    System.assertequals(3, instPrdRecds.size());


  }

  /**
  * @description : Cover catch block of ilib_resrReceiver. receiver method
  * @return testMethod 
  **/
  static testMethod void testIPInsterHTTPPostForCatch() {
    try{
      List < EquipmentMasterDataReceiverWrapper.InstalledProducts > lstInstProductRecords = new List < EquipmentMasterDataReceiverWrapper.InstalledProducts > ();
      // Product Data
      Product2 pr = new Product2();
      pr.Name = 'DummyProduct';
      pr.ProductCode = '15045005';
      pr.Material_Number__c = '12345';
      pr.IsActive = true;
      insert pr;
      // Account Data
      Account testAccount1 = TestDataAccount.getNewAccount();
  
      // Top level Data
      SVMXC__Installed_Product__c tprd = new SVMXC__Installed_Product__c();
      tprd.ERP_Equipment_Id__c = '1234';
      tprd.SVMXC__Company__C = testAccount1.Id;
      tprd.Acceptance_Date__c = Date.valueOf('2018-10-18');
      tprd.SVMXC__Date_Installed__c = Date.valueOf('2018-10-18');
      insert tprd;
  
      // Parent Data
      SVMXC__Installed_Product__c pprd = new SVMXC__Installed_Product__c();
      pprd.ERP_Equipment_Id__c = '5678';
      pprd.SVMXC__Company__C = testAccount1.Id;
      pprd.Acceptance_Date__c = Date.valueOf('2018-10-18');
      pprd.SVMXC__Date_Installed__c = Date.valueOf('2018-10-18');
      insert pprd;
  
      // For Upsert
      SVMXC__Installed_Product__c uiprd = new SVMXC__Installed_Product__c();
      uiprd.ERP_Equipment_Id__c = '333';
      uiprd.SVMXC__Company__C = testAccount1.Id;
      uiprd.Acceptance_Date__c = Date.valueOf('2018-10-18');
      uiprd.SVMXC__Date_Installed__c = Date.valueOf('2018-10-18');
      insert uiprd;
  
      EquipmentMasterDataReceiverWrapper.InstalledProducts instPrdRecords1 = getinstallProductJson('200131', '9999', 'COLLABRN', '9', '897', '12345', '1234', '5678', '3044100', '3310', '12344', '1233445');
  
      lstInstProductRecords.add(instPrdRecords1);
  
      EquipmentMasterDataReceiverWrapper.InstalledProducts instPrdRecords2 = getinstallProductJson('', '666', 'COLLABRN', '9', '897', '12345', '1234', '5678', '3044100', '3310', '12344', '1233445');
  
      lstInstProductRecords.add(instPrdRecords2);
  
      String prdJSON = JSON.serialize(lstInstProductRecords);
  
  
      Test.startTest();
      
      //As Per Best Practice it is important to instantiate the Rest Context 
      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();
      req.requestURI = '/services/apexrest/EquipmentMasterSyncInterface';
      req.httpMethod = 'POST';
      req.requestBody = Blob.valueof(prdJSON);
      RestContext.request = req;
      RestContext.response = res;
      // EquipmentMasterDataReceiver.upsertIncomingValues();
  
      ilib_RestReceiver instantiated = new EquipmentMasterDataReceiver();
      instantiated.testClassCoverage=true;
      instantiated.receive();
  
      Test.stopTest();
   
      System.assertequals(412, res.statuscode,'Installed Product creation denied');
  
    }
    catch (Exception e){
      boolean exceptionCheck= e.getMessage().contains('Test coverage for catch block');
      System.assert(exceptionCheck,'Catch block not covered');
    }
  
    }

}
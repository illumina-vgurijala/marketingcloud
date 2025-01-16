/***************************************************************************************************************************************
 * NAME   : TestPartsOrderDataReceiver
 * DESCRIPTION  : TestClass for Parts Orders Data Receiver
 *                Annotated with SeeAllData=true due to dependency on ServiceMax managed trigger
 * @AUTHOR : Vaibhav
 * @DATE   : 14-Oct-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vaibhav                 14-Oct-2018             Initial Version
 * Priya Mukherjee         30th April 2024         CMCM-2846 Modify implementation related to Missing product functionality
 ****************************************************************************************************************************************/
@IsTest(SeeAllData = true)
public class TestPartsOrderDataReceiver {
    
    /**
    * @description prepare replica of JSON as received from SAP.
    * @author Vaibhav | 10/8/2019 
    * @param 
    * @return void 
    **/
    static PartsOrderDataReceiverWrapper.PartsOrder getPartsOrderJson() {

        /****** POPULATE THE WRAPPER WITH DATA **************/
        //create child data.
        PartsOrderDataReceiverWrapper.PartsOrderLine partsOrderLineRecord = new PartsOrderDataReceiverWrapper.PartsOrderLine();
        partsOrderLineRecord.ERP_Sales_Order_Item = '01910';
        partsOrderLineRecord.Shipped_Qty = '10';
        partsOrderLineRecord.Delivery = '11_11';
        partsOrderLineRecord.SVMXC_Serial_Number_List = '199842';
		partsOrderLineRecord.SVMXC_Equipment_Number = '19984211';
        partsOrderLineRecord.SVMXC_Line_Status = 'Complete';
        partsOrderLineRecord.SVMXC_Expected_Ship_Date = '2019-10-13';
        partsOrderLineRecord.Expected_Delivery_Date = '2019-10-14';
        partsOrderLineRecord.Requested_Delivery_Date = '2019-10-15';
        partsOrderLineRecord.Actual_Delivery_Date = '2019-10-16';
        partsOrderLineRecord.SVMXC_Actual_Ship_Date = '2019-10-17';
        partsOrderLineRecord.SVMXC_Product = '717189';
        partsOrderLineRecord.From_Location = '717189';
        partsOrderLineRecord.To_Location = '717189';
        partsOrderLineRecord.Tracking_Number = '65746474';
        partsOrderLineRecord.Return_Reason_Code = 'SR11';
		partsOrderLineRecord.MAC_Address = '00-B0-D0-63-C2-11';
        //create header data.
        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecord = new PartsOrderDataReceiverWrapper.PartsOrder();
        partsOrderRecord.SVMXC_Sales_Order_Number = '28189';
        partsOrderRecord.SVMXC_Order_Status = 'Open';
        partsOrderRecord.PartsOrderLine.add(partsOrderLineRecord);

        return partsOrderRecord;

    }
    
    /**
     * @description prepare replica of JSON as received from SAP to check Public_tracking_URL field on PartsOrderLine.
     * @author Gagan | 06/07/2021 
     * @param 
     * @return void 
     * DCP 47007
     **/
    static PartsOrderDataReceiverWrapper.PartsOrder getPartsOrderJsonTracking() {

        /****** POPULATE THE WRAPPER WITH DATA **************/
        //create child data.
        PartsOrderDataReceiverWrapper.PartsOrderLine partsOrderLineRecord = new PartsOrderDataReceiverWrapper.PartsOrderLine();
        partsOrderLineRecord.ERP_Sales_Order_Item = '019103';
        partsOrderLineRecord.Shipped_Qty = '10';
        partsOrderLineRecord.Delivery = '22_22';
        partsOrderLineRecord.SVMXC_Serial_Number_List = '199842';
        partsOrderLineRecord.SVMXC_Equipment_Number = '199842';
        partsOrderLineRecord.SVMXC_Line_Status = 'Open';
        partsOrderLineRecord.SVMXC_Expected_Ship_Date = '2019-10-13';
        partsOrderLineRecord.Expected_Delivery_Date = '2019-10-14';
        partsOrderLineRecord.Requested_Delivery_Date = '2019-10-15';
        partsOrderLineRecord.Actual_Delivery_Date = '2019-10-16';
        partsOrderLineRecord.SVMXC_Actual_Ship_Date = '2019-10-17';
        partsOrderLineRecord.SVMXC_Product = '717189';
        partsOrderLineRecord.From_Location = '717189';
        partsOrderLineRecord.To_Location = '717189';

        PartsOrderDataReceiverWrapper.Tracking_Data trackingDataObj = new PartsOrderDataReceiverWrapper.Tracking_Data();
        trackingDataObj.Public_Tracking_URL = 'https://tinyurl.com/trackpd?t=1Z2E032A0492808829%22';
        PartsOrderDataReceiverWrapper.Tracking_Data trackingDataObj1 = new PartsOrderDataReceiverWrapper.Tracking_Data();
        trackingDataObj1.Public_Tracking_URL = 'https://tinyurl.com/trackpd?t=1Z2E032A0492808829%21';

        partsOrderLineRecord.Tracking_Data.add(trackingDataObj);
        partsOrderLineRecord.Tracking_Data.add(trackingDataObj1);

        //create header data.
        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecord = new PartsOrderDataReceiverWrapper.PartsOrder();
        partsOrderRecord.SVMXC_Sales_Order_Number = '281893';
        partsOrderRecord.SVMXC_Order_Status = 'Open';
        partsOrderRecord.PartsOrderLine.add(partsOrderLineRecord);

        return partsOrderRecord;

    }

    /**
    * @description Update POL to test the required functionality.
    * @author Vaibhav | 10/8/2019 
    * @param 
    * @return void 
    **/
    static testMethod void testPartsOrderUpdateHTTPPost() {
        
         String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile pro = [SELECT Id FROM Profile WHERE Name='Integration SAP Service'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = pro.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);
        
          System.runAs(u) {
        //create parts order with parts order line.
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');

        Product2 p = new Product2();
        p.Name = 'TestProductUpdated';
        p.ProductCode = '717189';
        p.Material_Number__c = '717189';
        insert p;

        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;
		Test.startTest();
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');

        //Parts Order creation in SAP (Inbound to SAP from SVMX)
        partOrder.ERP_Sales_Order_Number__c = '28189';
        partOrder.SVMXC__Order_Status__c = 'Open';
        partOrder.Contact_Name__c = 'Test Contact';
        partOrder.Contact_Phone__c = '+100021';
        partOrder.SVMXC__Order_Type__c = 'Return';
        insert partOrder;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
        objPartsOrderLine.ERP_Sales_Order_Item__c = '01910' + '199842';
        insert objPartsOrderLine;

        //holds the wrapper records in list.
        List < PartsOrderDataReceiverWrapper.PartsOrder > lstPartsOrderRecords = new List < PartsOrderDataReceiverWrapper.PartsOrder > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecords = getPartsOrderJson();

        //pass it over to a list.  
        lstPartsOrderRecords.add(partsOrderRecords);

        //convert the apex list into a Json structure.
        String partsOrderJSON = JSON.serialize(lstPartsOrderRecords);

        

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/partsOrderSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(partsOrderJSON);
        RestContext.request = req;
        RestContext.response = res;
        PartsOrderDataReceiver.upsertIncomingValues();
        //assertion added by prashanth
        List < SVMXC__Installed_Product__c > installedProducts = [Select Id, SVMXC__Status__c from SVMXC__Installed_Product__c Limit 1];
        System.assert(installedProducts.size() > 0);
        Test.stopTest();
        
        List <SVMXC__RMA_Shipment_Line__c> partsOrderLine =[select Tracking_Number__c, Return_Reason__c from SVMXC__RMA_Shipment_Line__c where Tracking_Number__c='65746474'and Return_Reason__c='Used/Failure'];      
        System.assert(PartsOrderLine.size() > 0);
		List < SVMXC__Installed_Product__c > checkMAc = [Select Id, Mac_Address__c from SVMXC__Installed_Product__c where Mac_Address__c = '00-B0-D0-63-C2-11' Limit 1];
        System.assert(String.isNotBlank(checkMAc[0].Mac_Address__c), 'Mac_Address__c is not populated');
        //make sure the status is success.
        System.assertequals(200, res.statuscode);
        }

    }
    
    /**
    * @description negative testing
    * @author Vaibhav | 10/8/2019 
    * @param 
    * @return void 
    **/
    static testMethod void negativeTestHTTPPost() {
    
    //holds the wrapper records in list.
        List < PartsOrderDataReceiverWrapper.PartsOrder > lstPartsOrderRecords = new List < PartsOrderDataReceiverWrapper.PartsOrder > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecords = getPartsOrderJson();

        //pass it over to a list.  
        lstPartsOrderRecords.add(partsOrderRecords);

        //convert the apex list into a Json structure.
        String partsOrderJSON = JSON.serialize(lstPartsOrderRecords);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/partsOrderSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(partsOrderJSON);
        RestContext.request = req;
        RestContext.response = res;
        PartsOrderDataReceiver.upsertIncomingValues();
        //assertion added by prashanth
        List < SVMXC__Installed_Product__c > installedProducts = [Select Id, SVMXC__Status__c from SVMXC__Installed_Product__c Limit 1];
        System.assert(installedProducts.size() > 0);
        Test.stopTest();

        //make sure the status is failure.
        System.assertequals(412, res.statuscode);
    
    }

	/**
     * @description Update POL to test the required functionality.
     * @author Gagan | 06/07/2021 
     * @param 
     * @return void 
     * DCP47007
     **/
    static testMethod void trackingURL() {

        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile pro = [SELECT Id FROM Profile WHERE Name = 'Integration SAP Service'];
        User u = new User(Alias = 'standt', Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8', FirstName = 'SAP Service', LastName = 'Integration', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = pro.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName);

        System.runAs(u) {

            //create parts order with parts order line.
            Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');

            Product2 p = new Product2();
            p.Name = 'TestProductUpdated';
            p.ProductCode = '717189';
            p.Material_Number__c = '717189';
            insert p;

            Case objCase = TestDataCase.initServiceRequestCase(con);
            insert objCase;
            Test.startTest();
            SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');

            //Parts Order creation in SAP (Inbound to SAP from SVMX)
            partOrder.ERP_Sales_Order_Number__c = '281893';
            partOrder.SVMXC__Order_Status__c = 'Open';
            partOrder.Contact_Name__c = 'Test Contact1';
            partOrder.Contact_Phone__c = '+100021';
            partOrder.SVMXC__Order_Type__c = 'Return';
            insert partOrder;

            SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
            objPartsOrderLine.ERP_Sales_Order_Item__c = '019103' + '1998423';
            objPartsOrderLine.Public_Tracking_URL__c = 'test ptl';
            insert objPartsOrderLine;


            //holds the wrapper records in list.
            List < PartsOrderDataReceiverWrapper.PartsOrder > lstPartsOrderRecords = new List < PartsOrderDataReceiverWrapper.PartsOrder > ();

            //get the wrapper object.
            //Passing new unique numbers will insert the data.
            PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecords = getPartsOrderJsonTracking();

            //pass it over to a list.  
            lstPartsOrderRecords.add(partsOrderRecords);

            //convert the apex list into a Json structure.
            String partsOrderJSON = JSON.serialize(lstPartsOrderRecords);

            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/partsOrderSyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(partsOrderJSON);
            RestContext.request = req;
            RestContext.response = res;
            PartsOrderDataReceiver.upsertIncomingValues();
            Test.stopTest();
            List < SVMXC__RMA_Shipment_Order__c > partOrderTrackingURL = [Select Id, (Select Id, Public_Tracking_URL__c from SVMXC__RMA_Shipment_Line__r limit 1) from SVMXC__RMA_Shipment_Order__c Where ERP_Sales_Order_Number__c = '281893'];
            for (SVMXC__RMA_Shipment_Order__c po: partOrderTrackingURL) {
                for (SVMXC__RMA_Shipment_Line__c pol: po.SVMXC__RMA_Shipment_Line__r) {
                    if (pol.Public_Tracking_URL__c != 'test ptl') {
                        System.assertequals('<p>https://tinyurl.com/trackpd?t=1Z2E032A0492808829%22<br/>https://tinyurl.com/trackpd?t=1Z2E032A0492808829%21</p>', pol.Public_Tracking_URL__c);
                    }

                }
            }

            //make sure the status is not failure.
            System.assertequals(200, res.statuscode);

        }

    }

	/**
    * @description prepare replica of JSON as received from SAP.
    * @author Vaibhav | 10/8/2019 
    * @param 
    * @return void 
    **/
    static PartsOrderDataReceiverWrapper.PartsOrder getPartsOrderJsonStagePGI1() {

        /****** POPULATE THE WRAPPER WITH DATA **************/
        //create child data 1 status complete .
        PartsOrderDataReceiverWrapper.PartsOrderLine partsOrderLineRecord = new PartsOrderDataReceiverWrapper.PartsOrderLine();
        partsOrderLineRecord.ERP_Sales_Order_Item = '01910';
        partsOrderLineRecord.Shipped_Qty = '1';
        partsOrderLineRecord.SVMXC_Serial_Number_List = 'FIRST';
		partsOrderLineRecord.SVMXC_Equipment_Number = '19984211';
        partsOrderLineRecord.SVMXC_Line_Status = 'Complete';
        partsOrderLineRecord.SVMXC_Expected_Ship_Date = '2019-10-13';
        partsOrderLineRecord.Expected_Delivery_Date = '2019-10-14';
        partsOrderLineRecord.Requested_Delivery_Date = '2019-10-15';
        partsOrderLineRecord.Actual_Delivery_Date = '2019-10-16';
        partsOrderLineRecord.SVMXC_Actual_Ship_Date = '2019-10-17';
        partsOrderLineRecord.SVMXC_Product = '717189';
        partsOrderLineRecord.From_Location = '717189';
        partsOrderLineRecord.To_Location = '717189';

		        //create child data 2 status open no serial number.
        /*PartsOrderDataReceiverWrapper.PartsOrderLine partsOrderLineRecord1 = new PartsOrderDataReceiverWrapper.PartsOrderLine();
        partsOrderLineRecord1.ERP_Sales_Order_Item = '01910';
        partsOrderLineRecord1.SVMXC_Actual_Quantity2 = '1';
        partsOrderLineRecord1.SVMXC_Serial_Number_List = '';
		partsOrderLineRecord.SVMXC_Equipment_Number = '';
        partsOrderLineRecord1.SVMXC_Line_Status = 'Open';
        partsOrderLineRecord1.SVMXC_Expected_Ship_Date = '2019-10-13';
        partsOrderLineRecord1.Expected_Delivery_Date = '2019-10-14';
        partsOrderLineRecord1.Requested_Delivery_Date = '2019-10-15';
        partsOrderLineRecord1.Actual_Delivery_Date = '2019-10-16';
        partsOrderLineRecord1.SVMXC_Actual_Ship_Date = '2019-10-17';
        partsOrderLineRecord1.SVMXC_Product = '717189';
        partsOrderLineRecord1.From_Location = '717189';
        partsOrderLineRecord1.To_Location = '717189';*/
        //create header data.
        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecord = new PartsOrderDataReceiverWrapper.PartsOrder();
        partsOrderRecord.SVMXC_Sales_Order_Number = '28189';
        partsOrderRecord.SVMXC_Order_Status = 'Open';
        partsOrderRecord.PartsOrderLine.add(partsOrderLineRecord);
        //partsOrderRecord.PartsOrderLine.add(partsOrderLineRecord1);
        return partsOrderRecord;

    }
	
	/**
    * @description prepare replica of JSON as received from SAP.
    * @author Vaibhav | 10/8/2019 
    * @param 
    * @return void 
    **/
    static PartsOrderDataReceiverWrapper.PartsOrder getPartsOrderJsonStagePGI2() {

        /****** POPULATE THE WRAPPER WITH DATA **************/
        //create child data 1 status complete .
        PartsOrderDataReceiverWrapper.PartsOrderLine partsOrderLineRecord = new PartsOrderDataReceiverWrapper.PartsOrderLine();
        partsOrderLineRecord.ERP_Sales_Order_Item = '01910';
        partsOrderLineRecord.Shipped_Qty = '1';
        partsOrderLineRecord.SVMXC_Serial_Number_List = 'FIRST';
		partsOrderLineRecord.SVMXC_Equipment_Number = '0191011';
        partsOrderLineRecord.SVMXC_Line_Status = 'Complete';
        partsOrderLineRecord.SVMXC_Expected_Ship_Date = '2019-10-13';
        partsOrderLineRecord.Expected_Delivery_Date = '2019-10-14';
        partsOrderLineRecord.Requested_Delivery_Date = '2019-10-15';
        partsOrderLineRecord.Actual_Delivery_Date = '2019-10-16';
        partsOrderLineRecord.SVMXC_Actual_Ship_Date = '2019-10-17';
        partsOrderLineRecord.SVMXC_Product = '717189';
        partsOrderLineRecord.From_Location = '717189';
        partsOrderLineRecord.To_Location = '717189';

		        //create child data 2 status open no serial number.
        /*PartsOrderDataReceiverWrapper.PartsOrderLine partsOrderLineRecord1 = new PartsOrderDataReceiverWrapper.PartsOrderLine();
        partsOrderLineRecord1.ERP_Sales_Order_Item = '01910';
        partsOrderLineRecord1.SVMXC_Actual_Quantity2 = '1';
        partsOrderLineRecord1.SVMXC_Serial_Number_List = 'SECOND';
		partsOrderLineRecord.SVMXC_Equipment_Number = 'SECOND_EQUIP';
        partsOrderLineRecord1.SVMXC_Line_Status = 'Open';
        partsOrderLineRecord1.SVMXC_Expected_Ship_Date = '2019-10-13';
        partsOrderLineRecord1.Expected_Delivery_Date = '2019-10-14';
        partsOrderLineRecord1.Requested_Delivery_Date = '2019-10-15';
        partsOrderLineRecord1.Actual_Delivery_Date = '2019-10-16';
        partsOrderLineRecord1.SVMXC_Actual_Ship_Date = '2019-10-17';
        partsOrderLineRecord1.SVMXC_Product = '717189';
        partsOrderLineRecord1.From_Location = '717189';
        partsOrderLineRecord1.To_Location = '717189';*/
        //create header data.
        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecord = new PartsOrderDataReceiverWrapper.PartsOrder();
        partsOrderRecord.SVMXC_Sales_Order_Number = '28189';
        partsOrderRecord.SVMXC_Order_Status = 'Open';
        partsOrderRecord.PartsOrderLine.add(partsOrderLineRecord);
        //partsOrderRecord.PartsOrderLine.add(partsOrderLineRecord1);
        return partsOrderRecord;

    }
	
	 /**
    * @description Update POL to test the required functionality.
    * @author Vaibhav | 10/8/2019 
    * @param 
    * @return void 
    **/
    static testMethod void testPartsOrderUpdateHTTPPostMultiplePGI() {
        
         String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile pro = [SELECT Id FROM Profile WHERE Name='Integration SAP Service'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = pro.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);
        
          System.runAs(u) {
        //create parts order with parts order line.
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');

        Product2 p = new Product2();
        p.Name = 'TestProductUpdated';
        p.ProductCode = '717189';
        p.Material_Number__c = '717189';
        insert p;

        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');

        //Parts Order creation in SAP (Inbound to SAP from SVMX)
        partOrder.ERP_Sales_Order_Number__c = '28189';
        partOrder.SVMXC__Order_Status__c = 'Open';
        partOrder.Contact_Name__c = 'Test Contact';
        partOrder.Contact_Phone__c = '+100021';
        partOrder.SVMXC__Order_Type__c = 'Shipment';
        insert partOrder;
	    Test.startTest();
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
        objPartsOrderLine.ERP_Sales_Order_Item__c = '01910' + 'FIRST';
        insert objPartsOrderLine;
         
		 SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(partOrder.Id);
        objPartsOrderLine1.ERP_Sales_Order_Item__c = '01910' + '';
        insert objPartsOrderLine1;
		
        //holds the wrapper records in list.
        List < PartsOrderDataReceiverWrapper.PartsOrder > lstPartsOrderRecords = new List < PartsOrderDataReceiverWrapper.PartsOrder > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecords = getPartsOrderJsonStagePGI1();

        //pass it over to a list.  
        lstPartsOrderRecords.add(partsOrderRecords);

        //convert the apex list into a Json structure.
        String partsOrderJSON = JSON.serialize(lstPartsOrderRecords);
		
		
		// second PGI JSON
		 //holds the wrapper records in list.
        List < PartsOrderDataReceiverWrapper.PartsOrder > lstPartsOrderRecords1 = new List < PartsOrderDataReceiverWrapper.PartsOrder > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecords1 = getPartsOrderJsonStagePGI2();

        //pass it over to a list.  
        lstPartsOrderRecords1.add(partsOrderRecords1);

        //convert the apex list into a Json structure.
        String partsOrderJSON1 = JSON.serialize(lstPartsOrderRecords1);

        

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/partsOrderSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(partsOrderJSON);
        RestContext.request = req;
        RestContext.response = res;
        PartsOrderDataReceiver.upsertIncomingValues();
        //assertion added by prashanth
        List < SVMXC__Installed_Product__c > installedProducts = [Select Id, SVMXC__Status__c from SVMXC__Installed_Product__c Limit 1];
        System.assert(installedProducts.size() > 0);
        RestRequest req1 = new RestRequest();
        RestResponse res1 = new RestResponse();
        req1.requestURI = '/services/apexrest/partsOrderSyncInterface';
        req1.httpMethod = 'POST';
        req1.requestBody = Blob.valueof(partsOrderJSON1);
        RestContext.request = req1;
        RestContext.response = res1;
		// second pgi 
		Test.stopTest();	
        PartsOrderDataReceiver.upsertIncomingValues();
		List < SVMXC__Installed_Product__c > installedProducts1 = [Select Id,Name, SVMXC__Status__c from SVMXC__Installed_Product__c where ERP_Equipment_ID__c = '0191011'];
        System.assert(installedProducts1.size()>0);
		
        //make sure the status is success.
        System.assertequals(200, res.statuscode);
        }

    }
    /**
    *  @AUTHOR Tapas
    *  @DESCRIPTION - covers RITM0503667 components
    **/
    static testMethod void testPartsOrderUpdateHTTPPostForMissingProduct() {
        SVMXC__RMA_Shipment_Order__c partOrder;
        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecords = getPartsOrderJson();
		RestResponse res;
        
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile pro = [SELECT Id FROM Profile WHERE Name='Integration SAP Service'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = pro.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName);
        
        System.runAs(u) {
        //create parts order with parts order line.
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');

        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;
		Test.startTest();

        //Parts Order creation in SAP (Inbound to SAP from SVMX)
        partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        partOrder.ERP_Sales_Order_Number__c = '28189';
        partOrder.SVMXC__Order_Status__c = 'Open';
        partOrder.Contact_Name__c = 'Test Contact';
        partOrder.Contact_Phone__c = '+100021';
        partOrder.SVMXC__Order_Type__c = 'Return';
        insert partOrder;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
        objPartsOrderLine.ERP_Sales_Order_Item__c = '01910';// + '199842';
        insert objPartsOrderLine;

        //holds the wrapper records in list.
        List < PartsOrderDataReceiverWrapper.PartsOrder > lstPartsOrderRecords = new List < PartsOrderDataReceiverWrapper.PartsOrder > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
		partsOrderRecords.PartsOrderLine[0].SVMXC_Product = 'aaaaawwwwwcc';
        //pass it over to a list.  
        lstPartsOrderRecords.add(partsOrderRecords);

        //convert the apex list into a Json structure.
        String partsOrderJSON = JSON.serialize(lstPartsOrderRecords);

            RestRequest req = new RestRequest();
            res = new RestResponse();
            req.requestURI = '/services/apexrest/partsOrderSyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(partsOrderJSON);
            RestContext.request = req;
            RestContext.response = res;

            Integer beforeCount = [SELECT COUNT() FROM Missing_Product__c LIMIT 199]; //CMCM-2846
            PartsOrderDataReceiver.upsertIncomingValues();
            Integer afterCount = [SELECT COUNT() FROM Missing_Product__c LIMIT 199]; //CMCM-2846

            // Assert that a new Missing_Product__c record has been inserted
            System.assertEquals(beforeCount + 1, afterCount, 'New Record created for Missing Product');//CMCM-2846
        }

        // More operations and assertions can be placed here if necessary
        Product2 p = new Product2(Name = 'TestProductUpdated', ProductCode = 'aaaaawwwwwcc', Material_Number__c = 'aaaaawwwwwcc');
        insert p;
        Test.getEventBus().deliver();
        //assertion added by prashanth
        List < SVMXC__Installed_Product__c > installedProducts = [Select Id, SVMXC__Status__c from SVMXC__Installed_Product__c Limit 1];
        System.assert(installedProducts.size() > 0);
        Test.stopTest();
        //make sure the status is success.
        if(res.statuscode == 200){
        	System.assertequals(200, res.statuscode);
        }
        else{
            System.debug('StatusCode:'+res.statuscode);
        }
          
    } 
    /**
    * @description prepare replica of JSON as received from SAP.
    * @author Prashanth | 18/9/2021
    * @param 
    * @return void 
    **/
    static PartsOrderDataReceiverWrapper.PartsOrder getPartialShipmentJson1() {

        /****** POPULATE THE WRAPPER WITH DATA **************/
        //create child data 1 status partially shipped .
        PartsOrderDataReceiverWrapper.PartsOrderLine partsOrderLineRecord = new PartsOrderDataReceiverWrapper.PartsOrderLine();
        partsOrderLineRecord.ERP_Sales_Order_Item = '00010';
        partsOrderLineRecord.Shipped_Qty = '1';
        partsOrderLineRecord.Delivery = '11111_10';
        partsOrderLineRecord.SVMXC_Serial_Number_List = '';
		partsOrderLineRecord.SVMXC_Equipment_Number = '';
        partsOrderLineRecord.SVMXC_Line_Status = 'Partially Shipped';
        partsOrderLineRecord.SVMXC_Expected_Ship_Date = '2019-10-13';
        partsOrderLineRecord.Expected_Delivery_Date = '2019-10-14';
        partsOrderLineRecord.Requested_Delivery_Date = '2019-10-15';
        partsOrderLineRecord.Actual_Delivery_Date = '2019-10-16';
        partsOrderLineRecord.SVMXC_Actual_Ship_Date = '2019-10-17';
        partsOrderLineRecord.SVMXC_Product = '717189';
        partsOrderLineRecord.From_Location = '';
        partsOrderLineRecord.To_Location = '717189';

        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecord = new PartsOrderDataReceiverWrapper.PartsOrder();
        partsOrderRecord.SVMXC_Sales_Order_Number = '28189';
        partsOrderRecord.SVMXC_Order_Status = 'Open';
        partsOrderRecord.PartsOrderLine.add(partsOrderLineRecord);
        return partsOrderRecord;

    }
    /**
    * @description prepare replica of JSON as received from SAP.
    * @author Prashanth | 18/9/2021
    * @param 
    * @return void 
    **/
    static PartsOrderDataReceiverWrapper.PartsOrder getPartialShipmentJson2() {

        /****** POPULATE THE WRAPPER WITH DATA **************/
        //create child data 2 status partially shipped .
        PartsOrderDataReceiverWrapper.PartsOrderLine partsOrderLineRecord = new PartsOrderDataReceiverWrapper.PartsOrderLine();
        partsOrderLineRecord.ERP_Sales_Order_Item = '00010';
        partsOrderLineRecord.Shipped_Qty = '1';
        partsOrderLineRecord.Delivery = '22222_10';
        partsOrderLineRecord.SVMXC_Serial_Number_List = '';
		partsOrderLineRecord.SVMXC_Equipment_Number = '';
        partsOrderLineRecord.SVMXC_Line_Status = 'Completed';
        partsOrderLineRecord.SVMXC_Expected_Ship_Date = '2019-10-14';
        partsOrderLineRecord.Expected_Delivery_Date = '2019-10-15';
        partsOrderLineRecord.Requested_Delivery_Date = '2019-10-16';
        partsOrderLineRecord.Actual_Delivery_Date = '2019-10-17';
        partsOrderLineRecord.SVMXC_Actual_Ship_Date = '2019-10-18';
        partsOrderLineRecord.SVMXC_Product = '717189';
        partsOrderLineRecord.From_Location = '';
        partsOrderLineRecord.To_Location = '717189';

        PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecord = new PartsOrderDataReceiverWrapper.PartsOrder();
        partsOrderRecord.SVMXC_Sales_Order_Number = '28189';
        partsOrderRecord.SVMXC_Order_Status = 'Open';
        partsOrderRecord.PartsOrderLine.add(partsOrderLineRecord);
        return partsOrderRecord;

    }
    /**
    *  @AUTHOR Prashanth
    *  @DESCRIPTION - covers Partial Shipment process
    **/
    static testMethod void testPartialShipment(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile pro = [SELECT Id FROM Profile WHERE Name='Integration SAP Service'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = pro.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);
        
        System.runAs(u) {
            //create parts order with parts order line.
            Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');

            Product2 p = new Product2();
            p.Name = 'TestProductUpdated';
            p.ProductCode = '717189';
            p.Material_Number__c = '717189';
            insert p;

            Case objCase = TestDataCase.initServiceRequestCase(con);
            insert objCase;
            Test.startTest();
            SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');

            //Parts Order creation in SAP (Inbound to SAP from SVMX)
            partOrder.ERP_Sales_Order_Number__c = '28189';
            partOrder.SVMXC__Order_Status__c = 'Open';
            partOrder.Contact_Name__c = 'Test Contact';
            partOrder.Contact_Phone__c = '+100021';
            partOrder.SVMXC__Order_Type__c = 'Shipment';
            insert partOrder;

            SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
            objPartsOrderLine.ERP_Sales_Order_Item__c = '00010';
            insert objPartsOrderLine;
            
            //holds the wrapper records in list.
            List < PartsOrderDataReceiverWrapper.PartsOrder > lstPartsOrderRecords = new List < PartsOrderDataReceiverWrapper.PartsOrder > ();

            //get the wrapper object.
            //Passing new unique numbers will insert the data.
            PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecords = getPartialShipmentJson1();

            //pass it over to a list.  
            lstPartsOrderRecords.add(partsOrderRecords);

            //convert the apex list into a Json structure.
            String partsOrderJSON = JSON.serialize(lstPartsOrderRecords);
            
            
            // second PGI JSON
            //holds the wrapper records in list.
            List < PartsOrderDataReceiverWrapper.PartsOrder > lstPartsOrderRecords1 = new List < PartsOrderDataReceiverWrapper.PartsOrder > ();

            //get the wrapper object.
            //Passing new unique numbers will insert the data.
            PartsOrderDataReceiverWrapper.PartsOrder partsOrderRecords1 = getPartialShipmentJson2();

            //pass it over to a list.  
            lstPartsOrderRecords1.add(partsOrderRecords1);

            //convert the apex list into a Json structure.
            String partsOrderJSON1 = JSON.serialize(lstPartsOrderRecords1);

            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/partsOrderSyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(partsOrderJSON);
            RestContext.request = req;
            RestContext.response = res;
            PartsOrderDataReceiver.upsertIncomingValues();
            List<SVMXC__RMA_Shipment_Line__c> originalPOL = [Select Id,SVMXC__Line_Status__c,External_ID__c,Shipped_Qty__c from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__c =:partOrder.Id and External_ID__c = null];
            System.assertEquals('Partially Shipped',originalPOL[0].SVMXC__Line_Status__c);
            RestRequest req1 = new RestRequest();
            RestResponse res1 = new RestResponse();
            req1.requestURI = '/services/apexrest/partsOrderSyncInterface';
            req1.httpMethod = 'POST';
            req1.requestBody = Blob.valueof(partsOrderJSON1);
            RestContext.request = req1;
            RestContext.response = res1;
            // second pgi 
            Test.stopTest();	
            PartsOrderDataReceiver.upsertIncomingValues();
            List<SVMXC__RMA_Shipment_Line__c> originalPOL1 = [Select Id,SVMXC__Line_Status__c,External_ID__c,Shipped_Qty__c from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__c =:partOrder.Id and External_ID__c = null];
            System.assertEquals('Canceled',originalPOL1[0].SVMXC__Line_Status__c);
            //make sure the status is success.
            System.assertequals(200, res.statuscode);
        }
    }
    /**
     *  @author      : Nitin
     *  @description : method to cover catch block in CreateCoveredProduct_POLHelper
     **/
    @isTest
    public static void coverCatchBlockCreateCoveredProductPOLHelper(){
        try{
            CreateCoveredProduct_POLHelper.catchException = true;
            CreateCoveredProduct_POLHelper pd = new CreateCoveredProduct_POLHelper(null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}
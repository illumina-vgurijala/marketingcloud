//TestPartsOrderLineSelector 
/*
* @ author       : Romi
* @ date         : 03-Sep-2021
* @ Description  : Test class for PartsOrderLineSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Romi                  27-Aug-2021                        Initial version
* Nancy                 06-06-2023                         CMCM-85: Enforce processing of parts order return before completing the work order
*/
@IsTest(seeAllData = true)
public class TestPartsOrderLineSelector {
      /**
     * @method:PartsOrderLineSelector
     * @description: test the PartsOrderLineSelector method.
     */
    static testMethod void testPartsOrderLineMethod(){
        User u = new User( 
         ProfileId = [SELECT Id FROM Profile WHERE Name like '%System Admin%'].Id,
         LastName = 'last_1',
         Email = 'puser000@test.com',
         Username = 'puser000@test.com' + System.currentTimeMillis(),
         CompanyName = 'TEST',
         Title = 'title',
         Alias = 'alias',
         TimeZoneSidKey = 'America/Los_Angeles',
         EmailEncodingKey = 'UTF-8',
         LanguageLocaleKey = 'en_US',
         LocaleSidKey = 'en_US'
    );
    insert u;
    System.runAs(u) {
        Test.startTest();
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            SetupOwnerId = u.Id,
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__RMA_Shipment_Order__c',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__RMA_Shipment_Line__c'
        );
        insert apexSettings;
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        //insert case
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != null);
        
        //insert Work Order
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        insert workOrder2;
        
        //insert Product
        Product2 objProduct1 = TestDataMaster.initProduct('12419677','Instrument');
        objProduct1.Serial_Number_Profile__c='IL02';
        objProduct1.Service_Product_Type__c = 'Instrument';
        objProduct1.CurrencyIsoCode= 'USD';
        objProduct1.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        insert objProduct1;
        
         //insert location
         SVMXC__Site__c loc = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
         loc.SVMXC__Stocking_Location__c=true;
         loc.Type__c='Service Center';
         loc.Is_Illumina_Address__c=true;
         loc.SVMX_PS_External_ID__c ='THUGLIFE123';
        // insert loc;
        //Pooja
        SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
            Name = 'testLocation',
            CurrencyIsoCode = 'USD',
            SVMXC__Stocking_Location__c = true,
            SVMX_PS_Active__c = true,
            Type__c = 'Trunk');
        list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
        locList.add(loc);
        locList.add(shippingLocation);
        insert locList;
        //Pooja

        
        //insert Parts Order
        SVMXC__RMA_Shipment_Order__c objPartsOrder =TestDataFieldService.createPartOrder('RMA', cs.Id, 'Open');
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='1234567890';
        objPartsOrder.SVMXC__Order_Type__c='Advance Exchange';
        objPartsOrder.ERP_Sales_Order_Number__c='0000';
        objPartsOrder.SVMXC__Service_Order__c = workOrder2.Id;
        objPartsOrder.Shipping_Location__c = locList[1].Id;//Pooja
        objPartsOrder.SVMXC__Destination_Location__c = locList[0].Id;//Pooja
        
        //objPartsOrder.SVMXC__Destination_Location__c = loc.Id;
        insert objPartsOrder;
             
        //insert Parts Order Line
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine1.SVMXC__Product__c = objProduct1.Id;
        objPartsOrderLine1.To_Location__c = loc.Id;
        objPartsOrderLine1.SVMXC__Line_Status__c ='Open';
        objPartsOrderLine1.Tracking_Number__c = '1234';
        objPartsOrderLine1.ERP_Contract_Line_Number__c = '23456';
        objPartsOrderLine1.ERP_Contract_Number__c = '1234567';
        objPartsOrderLine1.Batch_Number__c = '123';
        objPartsOrderLine1.Product_Code1__c = '45678';
        insert objPartsOrderLine1;
        
        //Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
                
        Set<Id> setPartsOrderLineIds = new Set<Id>{objPartsOrderLine1.Id};
        Set<Id> setPartsOrderIds = new Set<Id>{objPartsOrder.Id};
        Set<Id> setWorkOrder = new Set<Id>{workOrder2.Id};
        Set<String> setPartsOrderOrderNo = new Set<String>{objPartsOrder.ERP_Sales_Order_Number__c};
        Set<String> setPartsOrderStatus = new Set<String>{objPartsOrderLine1.SVMXC__Line_Status__c};
        Set<String> setLocationIds = new Set<String>{loc.Id};
        Set<Id> setLocationIds1 = new Set<Id>{loc.Id};
        Set<String> setPOLBatchNumber = new Set<String>{objPartsOrderLine1.Batch_Number__c};
        Set<String> setPOLProductCode = new Set<String>{objPartsOrderLine1.Product_Code1__c};
        Set<String> setNotPOLStatus = new Set<String>();
        Set<String> setNotPOStatus = new Set<String>();
        Set<String> setPOType = new Set<String>{objPartsOrder.SVMXC__Order_Type__c};
        
        
        PartsOrderLineSelector selector = new PartsOrderLineSelector();
        List<SVMXC__RMA_Shipment_Line__c> lstPOL1 = selector.selectPartsOrderLineById(setPartsOrderLineIds);
        System.assert(lstPOL1.size()>0);
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL2 = selector.selectShipmentPartsOrderLinesOnPartsOrders(setPartsOrderIds,objPartsOrder.SVMXC__Order_Type__c); 
        System.assert(lstPOL2.size()>0);
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL3 = selector.selectPartsOrderLinesOnPartsOrders(setPartsOrderIds);
        System.assert(lstPOL3.size()>0);
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL4 = selector.selectPartsOrderLineByPartsOrderExtId(setPartsOrderOrderNo);
        System.assert(lstPOL4.size()>0);
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL5 = selector.selectPartsOrderLineForProductType(setPartsOrderLineIds, objProduct1.Service_Product_Type__c);
        System.assert(lstPOL5.size()>0);
        
         List<SVMXC__RMA_Shipment_Line__c> lstPOL6 = selector.selectPartsOrdersLinesOnIds(setPartsOrderLineIds);
         System.assert(lstPOL6.size()>0);
        
         List<SVMXC__RMA_Shipment_Line__c> lstPOL7 = selector.selectPartsOrdersLinesByStatus(setPartsOrderIds, setPartsOrderStatus );
         System.assert(lstPOL7.size()>0);
        
         List<SVMXC__RMA_Shipment_Line__c> lstPOL8 = selector.selectPartsOrdersLinesByLocation(setLocationIds);
         System.assertNotEquals(null, lstPOL8.size());
        
         List<SVMXC__RMA_Shipment_Line__c> lstPOL9 = selector.selectAllPartsOrdersLinesForLocation(setLocationIds1, setPartsOrderLineIds );
         System.assertNotEquals(null, lstPOL9.size());
        
         List<SVMXC__RMA_Shipment_Line__c> lstPOL10 = selector.selectBlankContractPOLsByWorkOrderId(setWorkOrder, setPartsOrderStatus);
         System.assertNotEquals(null, lstPOL10.size());
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL11 = selector.selectPartsOrdersLinesByLocationAndBatchNumber(setLocationIds1, setPOLBatchNumber );
        System.assertNotEquals(null, lstPOL11.size());
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL12 = selector.selectNonBillablePartsOrderLinesById(setPartsOrderLineIds);
         System.assert(lstPOL12.size()>0);
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL13 = selector.selectPartsOrderLinesWithReasonOnPartsOrders(setPartsOrderIds);
         System.assertNotEquals(null, lstPOL13.size());
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL14 = selector.selectPOLsFromPOIds(setPartsOrderIds);
         System.assert(lstPOL14.size()>0);
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL15 = selector.selectPOLsFromProductExtIds(setPOLProductCode);
         System.assert(lstPOL15.size()>0);
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL16 = selector.selectPartsOrderLinesByWONotInStatues(setWorkOrder, setNotPOLStatus, setNotPOStatus, setPOType);
         System.assert(lstPOL16.size()>0);
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL17 = selector.selectPartsOrdersLinesNotInStatus(setPartsOrderIds, setNotPOLStatus);
         System.assert(lstPOL17.size()>0);
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL18 = selector.selectPartsOrdersLinesOfProductTypeByStatus(setWorkOrder, objPartsOrder.SVMXC__Order_Type__c, null, setPartsOrderStatus, objPartsOrderLine1.Service_Product_Type__c);
         System.assertNotEquals(null, lstPOL18.size());
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL19 = selector.selectLinkedPartsOrderLine(setPartsOrderLineIds);
		System.assertEquals(0, lstPOL19.size());

        List<SVMXC__RMA_Shipment_Line__c> lstPOL20 = selector.selectPartsOrderLinesOnPOExcludeProductType(setPartsOrderIds, 'Instrument', 'Return');
		System.assertEquals(0, lstPOL20.size());

        List<SVMXC__RMA_Shipment_Line__c> lstPOL21 = selector.selectPartsOrderLinesOnPOExcludeProductType(setPartsOrderIds, 'Core', 'Advance Exchange');
		System.assertEquals(1, lstPOL21.size());

        List<SVMXC__RMA_Shipment_Line__c> lstPOL22 = selector.selectPartsOrderLineforShippedandDelivedStatus(setPartsOrderIds);
		System.assertEquals(1, lstPOL22.size());

        Test.stopTest();
    }

 }
}
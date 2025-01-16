@isTest(SeeAllData=true) 
// here parts order is created automatically when a work detail of type parts gets inserted. SeeAllData=true is done as otherwise a serviceMax trigger is thrown
// EXCEPTION_THROWN [774]|System.DmlException: Insert failed. First exception on row 0; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, 
/*SVMXC.PORD_Trigger1: execution of BeforeInsert*/

public class TestPartsOrderSelector
{
    public static final string STRING_WORK_DETAIL_TYPE = 'Parts';
    public static final String STRING_PART_TYPE_RETURN = 'Return'; 
    public static final String STRING_ORDER_STATUS = 'Open';
    
    @isTest
    static void testPartsOrdersSelector()
    {
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = 'Distributor';
        update objAccount;
        System.assertNotEquals(null, objAccount.Id);
        Contact objContact = TestDataContact.getNewContact(objAccount);        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;
        System.assertNotEquals(null, objCase.Id);
        Set<Id> setCaseId = new Set<Id>{objCase.Id};
        
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Service_Product_Type__c  = 'Spare';
        serializedProd.Material_Group__c = '41';
        serializedProd.RMA_Required__c = true;
        insert serializedProd;
        System.assertNotEquals(null, serializedProd.Id);
        
        SVMXC__Product_Stock__c objProductStock = new SVMXC__Product_Stock__c();
        objProductStock.SVMXC__Product__c = serializedProd.Id;
        insert objProductStock;
        System.assertNotEquals(null, objProductStock.Id);
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;   
        System.assertNotEquals(null, workOrder.Id);
        Set<Id> setWorkOrderId = new Set<Id>{workOrder.Id};

        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Line_Type__c = STRING_WORK_DETAIL_TYPE;
        objOrderDetail.SVMX_PS_VS_Consumed_Product_Stock__c = objProductStock.Id;
        objOrderDetail.Consumption_Confirmed__c = true;
        Test.startTest();
        insert objOrderDetail;
        System.assertNotEquals(null, objOrderDetail.Id);
        Test.stoptest();
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrder = [select id,SVMXC__Service_Order__c from SVMXC__RMA_Shipment_Order__c where SVMXC__Service_Order__c =: workOrder.id];
        Set<Id> setPartOrderId = new Set<Id>{lstPartsOrder[0].Id};
        List<Id> lstPartOrderId = new List<Id>{lstPartsOrder[0].Id};
            
        PartsOrdersSelector objPartsOrdersSelector = new PartsOrdersSelector();
        objPartsOrdersSelector.selectPartsOrdersWithName(new set<String>{''});
        objPartsOrdersSelector.selectERPSubmittedPartsOrdersOnWorkOrders(setWorkOrderId);
                    
        System.assertEquals(0, (objPartsOrdersSelector.selectPartsOrdersForAppropriateStatusonCase(setPartOrderId,setCaseId,'Closed')).size());
        System.assertEquals(0, (objPartsOrdersSelector.selectPartsOrdersForAppropriateStatusonWO(setPartOrderId,setWorkOrderId,new Set<String>{'Closed'})).size());
        System.assertEquals(1, (objPartsOrdersSelector.selectPartsOrders(setPartOrderId)).size());
        System.assertEquals(1, (objPartsOrdersSelector.selectPartsOrdersExcludingOrderType(setPartOrderId,'Non-Return')).size());
        System.assertEquals(0, (objPartsOrdersSelector.selectPartsOrdersAndFieldService(lstPartOrderId)).size());
        System.assertEquals(1, (objPartsOrdersSelector.selectPartsOrdersOnWorkOrders(setWorkOrderId)).size());
        System.assertEquals(1, (objPartsOrdersSelector.selectPartsOrdersofWOForAppropriateStatus(setWorkOrderId,'Open')).size());
        objPartsOrdersSelector.selectERPSubmittedNonReturnPartsOrders(setWorkOrderId);
        objPartsOrdersSelector.selectReturnOrStockTransferPOsByIds(setPartOrderId);
        objPartsOrdersSelector.selectNonCancelledPartsOrdersOnWorkOrders(setWorkOrderId);
        objPartsOrdersSelector.selectPartsOrderWithPOL(setPartOrderId);
        new AgreementsSelector().selectAgreements(new Set<Id>());
        new AgreementsSelector().selectWOAgreements(setWorkOrderId);
        //System.assertEquals(1, (objPartsOrdersSelector.selectNonCancelledPartsOrdersOnWorkOrders(setWorkOrderId)).size());
        
    }
	
	//Added by Shruti for calling PartsOrderLineSelector.selectShipmentPartsOrderLinesOnPartsOrders()
	 @isTest
    static void testPartsOrderLineSelector()
    {
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
            Account objAccount = TestDataAccount.getNewAccount();
            objAccount.Account_Group__c = 'Distributor';
            update objAccount;
            System.assertNotEquals(null, objAccount.Id);
            Contact objContact = TestDataContact.getNewContact(objAccount);
            cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
                SetupOwnerId = u.Id,
                Bypass_Triggers_By_Object_1__c = 'Case',
                Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
                Bypass_Triggers_By_Object_3__c = 'SVMXC__RMA_Shipment_Order__c',
                Bypass_Triggers_By_Object_4__c = 'SVMXC__RMA_Shipment_Line__c'
            );
            insert apexSettings;        
            Case objCase = TestDataCase.initServiceRequestCase(objContact);
            insert objCase;
            System.assertNotEquals(null, objCase.Id);
            
            Product2 serializedProd = new Product2();
            serializedProd.Name = 'Test Serialized Product';
            serializedProd.IsActive = true;
            serializedProd.SVMXC__Tracking__c = 'Serialized';
            serializedProd.SVMXC__Stockable__c = true;
            serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
            serializedProd.Service_Product_Type__c  = 'Spare';
            serializedProd.Material_Group__c = '41';
            serializedProd.RMA_Required__c = true;
            insert serializedProd;
            System.assertNotEquals(null, serializedProd.Id);
            
            SVMXC__Product_Stock__c objProductStock = new SVMXC__Product_Stock__c();
            objProductStock.SVMXC__Product__c = serializedProd.Id;
            insert objProductStock;
            System.assertNotEquals(null, objProductStock.Id);
            
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
            workOrder.SVMXC__Company__c = objAccount.id;
            workOrder.SVMXC__Order_Type__c='Installation';
            workOrder.Is_Auto_Created__c = true;
            insert workOrder;   
            System.assertNotEquals(null, workOrder.Id);
            
            SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
            objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
            objOrderDetail.SVMXC__Line_Type__c = STRING_WORK_DETAIL_TYPE;
            objOrderDetail.SVMX_PS_VS_Consumed_Product_Stock__c = objProductStock.Id;
            
            objOrderDetail.Consumption_Confirmed__c = true;
            
            insert objOrderDetail;
            System.assertNotEquals(null, objOrderDetail.Id);
            
            SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
            insert objLocationRec;
            
            SVMXC__Site__c destinationLocation = new SVMXC__Site__c();
            destinationLocation.Name = 'destination Location';
            destinationLocation.Type__c = 'Locker';
            //sourceLocation.SVMXC__Account__c = testAccount.Id;
            destinationLocation.SVMXC__Stocking_Location__c = true;
            insert destinationLocation;
            
            SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
            partOrder.SVMXC__Service_Order__c=workOrder.id;
            //partOrder.SVMXC__Order_Type__c = 'Stock Transfer';
            partOrder.SVMXC__Order_Type__c = 'Shipment';
            partOrder.Contact_Name__c = 'Test Contact';
            partOrder.Contact_Phone__c = '+100021';
            partOrder.Shipping_Location__c = objLocationRec.Id;
            partOrder.SVMXC__Destination_Location__c = destinationLocation.Id;
            insert partOrder;
            
            
            List<SVMXC__RMA_Shipment_Order__c> lstPartsOrder = [select id,SVMXC__Service_Order__c from SVMXC__RMA_Shipment_Order__c where SVMXC__Service_Order__c =: workOrder.id];
            Set<Id> setPartOrderId = new Set<Id>{lstPartsOrder[0].Id};
                list < SVMXC__RMA_Shipment_Line__c > poLineList = new list < SVMXC__RMA_Shipment_Line__c > ();
            SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(lstPartsOrder[0].Id);
            objPartsOrderLine1.SVMXC__Product__c = serializedProd.Id;
            objPartsOrderLine1.Requested_Delivery_Date__c = date.today() + 2;
            objPartsOrderLine1.Return_Reason__c ='Test';
            poLineList.add(objPartsOrderLine1);
            
            insert poLineList;
            Test.stoptest();
            
            poLineList =[select id from SVMXC__RMA_Shipment_Line__c limit 1];
            Set<Id> setPartOrderLineId = new Set<Id>{poLineList[0].Id};
                PartsOrderLineSelector objPartsOrderLineSelector = new PartsOrderLineSelector();
            set<String> setStr = new set<string>{'Test'};
                
                objPartsOrderLineSelector.selectShipmentPartsOrderLinesOnPartsOrders(setPartOrderId ,'Return');
            objPartsOrderLineSelector.selectLinkedPartsOrderLine(setPartOrderLineId );
            objPartsOrderLineSelector.selectPartsOrderLineById(setPartOrderLineId );
            objPartsOrderLineSelector.selectPartsOrderLineRecords(setPartOrderLineId );
            objPartsOrderLineSelector.selectPartsOrdersLinesNotInStatus(setPartOrderLineId , setStr );
            objPartsOrderLineSelector.selectPartsOrdersLinesOnIds(setPartOrderLineId );
            objPartsOrderLineSelector.selectPartsOrdersLinesByStatus(setPartOrderLineId , setStr );
            objPartsOrderLineSelector.selectPartsOrderLineForProductType(setPartOrderLineId , 'Tool');
            objPartsOrderLineSelector.selectPartsOrderLineByPartsOrderExtId(setStr);
            objPartsOrderLineSelector.selectPartsOrderLinesOnPartsOrders(setPartOrderId);
            objPartsOrderLineSelector.selectAllPartsOrdersLinesForLocation(new Set<Id>(),setPartOrderLineId);
            objPartsOrderLineSelector.selectPartsOrdersLinesByLocation(new Set<String>());
            objPartsOrderLineSelector.selectBlankContractPOLsByWorkOrderId(new Set<Id>(), new Set<String>{'In Progress'});
            objPartsOrderLineSelector.selectNonBillablePartsOrderLinesById(setPartOrderLineId);
            new AgreementsSelector().selectPOLAgreements(setPartOrderLineId);
        }
    }
}
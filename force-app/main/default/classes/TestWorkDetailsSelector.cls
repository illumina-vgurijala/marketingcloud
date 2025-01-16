/**
 * @Class Name: TestWorkDetailsSelector
 * @author: Prashanth
 * @ Description: Test class for WorkDetailsSelector
 * CreatedDate : 6/21/2019
 * Modification Log :
 * --------------------------------------------------------------------
 * Developer                  Date                      Description
 * Prashanth                6/21/2019                  original version
 * --------------------------------------------------------------------
 * */
@isTest
Public class TestWorkDetailsSelector {

    /** 
    * @author: prashanth
    * Description: method to create test data
    **/
    @Testsetup
    static void createData(){
        Test.startTest();
        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assert(acc.Id != null);

        //insert contact
        Contact objContact = TestDataContact.getNewContact(acc);
        System.assert(objContact != null);

        //insert installed product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        //objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        System.assert(objInstalledProduct.Id != null);

        //insert case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        System.assert(objCase.Id != null);

        //insert workorder
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');       
        workOrder.SVMXC__Company__c = acc.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        workOrder.Partner_Installation_WO__c = true;
        insert workorder;
        System.assert(workOrder.Id != null);

        //insert product
        Product2 objProduct1 = TestDataMaster.createProduct(true);
		SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc; //Insert DCP-33467

        //Insert Product Stock DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = objProduct1.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;


        //insert workdetails
        Id recId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.RecordTypeId = recId;
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Product__c = objProduct1.Id;
        objOrderDetail.SVMXC__Line_Type__c = 'Parts';
		objOrderDetail.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467								 
        objOrderDetail.SVMXC__Is_Billable__c = true;
        objOrderDetail.SVMXC__Line_Status__c = 'Open';
        insert objOrderDetail;
        System.assert(objOrderDetail.Id != null);
        Test.stopTest();
    }
    /**
    * @author: Prashanth
    * method:workDetailsSelectorTest
    * Description: test workDetailsSelector
     */
    static testmethod void workDetailsSelectorTest(){
        
        Set<String> setStatus = new Set<String>();
        setStatus.add('test');
        
        SVMXC__Service_Order__c workOrder = [Select Id,SVMXC__Component__c from SVMXC__Service_Order__c];
        Test.startTest();
        WorkDetailsSelector selector = new WorkDetailsSelector();
        //test selectWorkDetailsMatchingWorkOrderId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails =  selector.selectWorkDetailsMatchingWorkOrderId(new Set<Id>{workOrder.Id},'Usage/Consumption','Parts');
		System.assertEquals(0,lstWorkDetails.size());

        //test selectWorkDetailsByWorkOrderIdWithRecordTypeAndShowOnCase
        List<SVMXC__Service_Order_Line__c> lstWorkDetails1 =  selector.selectWorkDetailsByWorkOrderIdWithRecordTypeAndShowOnCase(new Set<Id>{workOrder.Id},'Usage/Consumption',false);
		System.assertEquals(0,lstWorkDetails.size());
        //System.assert(lstWorkDetails1.size() == 1);

        //test selectWorkDetailsByWorkOrderIdWithRecordType
        List<SVMXC__Service_Order_Line__c> lstWorkDetails2 = selector.selectWorkDetailsByWorkOrderIdWithRecordType(new Set<Id>{workOrder.Id},'Usage/Consumption');
        System.assertEquals(1,lstWorkDetails2.size());
        
        //test selectWorkDetailsByWorkDetailId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails3 = selector.selectWorkDetailsByWorkDetailId(new Set<Id>{lstWorkDetails2[0].Id});
        System.assertEquals(1,lstWorkDetails3.size());

        //test selectWorkDetailsByWorkDetailStringId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails4 = selector.selectWorkDetailsByWorkDetailStringId(new Set<String>{lstWorkDetails2[0].Id});
        System.assertEquals(1,lstWorkDetails4.size());

        //test selectWorkDetailsByWorkOrderIdAndActivityTypeAndStatus
        List<SVMXC__Service_Order_Line__c> lstWorkDetails5 = selector.selectWorkDetailsByWorkOrderIdAndActivityTypeAndStatus(new Set<Id>{workOrder.Id},null,null);
        System.assertEquals(0,lstWorkDetails5.size());

        //test selectBillableWorkDetailsByWorkOrderIdExcludingFew
        List<SVMXC__Service_Order_Line__c> lstWorkDetails6 =  selector.selectBillableWorkDetailsByWorkOrderIdExcludingFew(new Set<Id>{workOrder.Id},new Set<Id>());
        System.assertEquals(0,lstWorkDetails6.size());
        System.debug('Work Details List6: ' + lstWorkDetails6);

        //test selectWorkDetailsByWorkOrderId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails7 = selector.selectWorkDetailsByWorkOrderId(new Set<Id>{workOrder.Id});
        System.assertEquals(0,lstWorkDetails7.size());
        
        //test selectLaborWorkDetailsByWorkOrderIdExcludingFew
        List<SVMXC__Service_Order_Line__c> lstWorkDetails10 = selector.selectLaborWorkDetailsByWorkOrderIdExcludingFew(new List<Id>{workOrder.Id}, new Set<Id>());
        System.assertEquals(0,lstWorkDetails10.size());
        
        //test selectWorkDetailFields
        List<SVMXC__Service_Order_Line__c> lstWorkDetails8 = selector.selectWorkDetailFields(new Set<Id>{lstWorkDetails1[0].Id});
        System.assertEquals(0,lstWorkDetails8.size());
        
        //test selectWorkDetailRecords
        List<SVMXC__Service_Order_Line__c> lstWorkDetails9 = selector.selectWorkDetailRecords(workOrder.Id);
        System.assertEquals(1,lstWorkDetails9.size());
        
        //test selectWorkDetailsForWorkOrderId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails11 = selector.selectWorkDetailsForWorkOrderId(new Set<Id>{workOrder.Id});
        System.assertEquals(1,lstWorkDetails11.size());
        
		//test selectWDWithLineTypeParts
        List<SVMXC__Service_Order_Line__c> lstWorkDetails12 = selector.selectWDWithLineTypeParts(new Set<Id>{lstWorkDetails1[0].Id});
        System.assertEquals(1,lstWorkDetails12.size());
        
        //test selectWDWTypePartsByWorkOrderId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails13 = selector.selectWDWTypePartsByWorkOrderId(new Set<Id>{workOrder.Id});
        System.assertEquals(1,lstWorkDetails13.size());
        
        //test selectPartsWorkDetailsByWorkOrderId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails14 = selector.selectPartsWorkDetailsByWorkOrderId(new Set<Id>{workOrder.Id});
        System.assertEquals(1,lstWorkDetails14.size());
        
        //test selectBlankContractWorkDetailsByWorkOrderId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails15 = selector.selectBlankContractWorkDetailsByWorkOrderId(new Set<Id>{workOrder.Id});
        System.assertEquals(1,lstWorkDetails15.size());
        
        //test selectOpenLaborWorkDetailsByWorkOrderId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails16 = selector.selectOpenLaborWorkDetailsByWorkOrderId(new Set<Id>{workOrder.Id},setStatus);
        System.assertEquals(0,lstWorkDetails16.size());
        
        //test selectNonCanceledWorkDetailsForWorkOrderId
        List<SVMXC__Service_Order_Line__c> lstWorkDetails17 = selector.selectNonCanceledWorkDetailsForWorkOrderId(new Set<Id>{workOrder.Id});
        System.assertEquals(1,lstWorkDetails17.size());
       
        //test selectWDLinkedWithBillableWO
        List<SVMXC__Service_Order_Line__c> lstWorkDetails18 = selector.selectWDLinkedWithBillableWO(new Set<Id>{workOrder.Id});
        System.assertEquals(1,lstWorkDetails18.size()); 
        
        //test selectNonBillableWorkDetailsById
        List<SVMXC__Service_Order_Line__c> lstWorkDetails19 = selector.selectNonBillableWorkDetailsById(new Set<Id>{workOrder.Id});
        System.assertEquals(0,lstWorkDetails19.size());
        
        //test selectWorkDetailRecordsWithNonBillableReason
        List<SVMXC__Service_Order_Line__c> lstWorkDetails20 = selector.selectWorkDetailRecordsWithNonBillableReason(workOrder.Id);
        System.assertEquals(0,lstWorkDetails20.size());
        Test.stopTest();
        
    }    
}
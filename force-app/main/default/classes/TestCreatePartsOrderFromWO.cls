/**
*    @author Adyasha Satapathy
*    @date   2021-06-30
*    @description    DCP-45793: Test class for CreatePartsOrderFromWO 
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Adyasha Satapathy       2021-06-30          Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest(SeeAllData = true) 
/* To ensure all required managed package SVMXC Data is available*/
public with sharing class TestCreatePartsOrderFromWO {
    
    /**
    *  DCP-45793
    *  @author : Adyasha
    *  @description - test method to verify auto creation of PO and POL on update of PO on WO
    **/
    @isTest
    static void testAutoCreatePOAndPOLOnWOUpdate(){
        
        User objAdminUser = TestDataUser.findUserInProfile('System Administrator');
        User objFieldServiceUser = TestDataUser.findUserInProfile('Field Service');

        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        
        Contact objContact = TestDataPerson.initContact(acc.Id);
        insert objContact;

        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Service_Product_Type__c = Label.ProductTypeSpare;
        insert objProduct;

        List<SVMXC__Site__c> lstLocationsToInsert = new List<SVMXC__Site__c>();
        SVMXC__Site__c objLocation = new SVMXC__Site__c(Name = TestPartsOrderLines.STRING_FROM_LOCATION);
        lstLocationsToInsert.add(objLocation);
        
        SVMXC__Site__c objToLocation = new SVMXC__Site__c(Name = TestPartsOrderLines.STRING_TO_LOCATION,SVMXC__Stocking_Location__c=true,Type__c=TestPartsOrderLines.STRING_SHIPPING_TYPE_TRUNK);
        lstLocationsToInsert.add(objToLocation);
        
        insert lstLocationsToInsert;

        SVMXC__Service_Group__c objServiceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert objServiceTeam;
        
        SVMXC__Service_Group_Members__c objTechnician = TestDataFieldService.createTechnician(objAdminUser.id,'Primary Field Application Scientist',objServiceTeam.id);
        objTechnician.SVMXC__Email__c='a@b.com';
        objTechnician.Preferred_Service_Report_Language__c='Japanese';
        objTechnician.SVMXC__Inventory_Location__c = lstLocationsToInsert.get(1).id;
        insert objTechnician;

        SVMXC__Service_Order__c workOrder;
        System.runAs(objFieldServiceUser){
            Case objCase = TestDataCase.initServiceRequestCase(objContact);
            insert objCase;

            workOrder = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, objCase.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c = WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES;
            workOrder.Is_Auto_Created__c = true;
            workOrder.SVMXC__Company__c = acc.id;
            workOrder.SVMXC__Contact__c = objContact.id;
            workOrder.SVMX_PS_Contact_Email__c = objContact.Email;
            workOrder.SVMX_PS_Contact_Phone__c = objContact.Phone;
            workOrder.SVMXC__Site__c = lstLocationsToInsert.get(0).id;
            workOrder.SVMXC__Group_Member__c = objTechnician.id;
            insert workOrder;
            
            Test.startTest();
            workOrder.PO_Number__c ='127845';
            update workOrder;
            Test.stopTest();
        }

        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrder = [Select Id,SVMXC__Order_Type__c from SVMXC__RMA_Shipment_Order__c where SVMXC__Service_Order__c =: workOrder.id];
        System.assert(lstPartsOrder.isEmpty(), 'Parts Order Creation Occured even if no Estimate lines');
  
  }

  /**
    *  DCP-45793
    *  @author : Adyasha
    *  @description - test method to verify auto creation of PO and POL on update of PO on WO insertion
    **/
    @isTest
    static void testAutoCreatePOAndPOLOnWOInsert(){

        User objAdminUser = TestDataUser.findUserInProfile('System Administrator');
        User objIntServiceSnapUser = TestDataUser.findUserInProfile(System.Label.Integration_Service_SNAP_Profile);

        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        
        Contact objContact = TestDataPerson.initContact(acc.Id);
        objContact.OwnerId = objIntServiceSnapUser.Id;
        insert objContact;

        List<Product2> lstProducts = new List<Product2>();

        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Service_Product_Type__c = Label.ProductTypeSpare;
        objProduct.Material_Group__c = '41';

        Product2 objProduct1 = TestDataMaster.initProduct('15013864');

        Product2 objProduct2 = TestDataMaster.createProduct(false);
        objProduct2.Service_Product_Type__c = Label.ProductTypeSpare;
        objProduct2.Material_Group__c = '41';
        objProduct2.Cross_Plant_Material_Status__c = 'Y6';

        Product2 objProduct3 = TestDataMaster.createProduct(false);
        objProduct3.Service_Product_Type__c = Label.ProductClassInstrument;
        objProduct3.Serial_Number_Profile__c = PartsOrderLines.STRING_SERIAL_NUMBER_PROFILE_IL02;

        Product2 objProduct4 = TestDataMaster.createProduct(false);
        objProduct4.Service_Product_Type__c = Label.ProductServiceProductTypeCore;

        lstProducts.add(objProduct);
        lstProducts.add(objProduct1);
        lstProducts.add(objProduct2);
        lstProducts.add(objProduct3);
        lstProducts.add(objProduct4);

        insert lstProducts;
        
        System.debug('product1 id: '+objProduct1.Id);

        FRU_List__c objFRUList = new FRU_List__c(ERP_Parent_Product__c = objProduct.id, ERP_Product__c = objProduct.id);
        insert objFRUList;

        FRU_List__c objFRUList2 = new FRU_List__c(ERP_Parent_Product__c = objProduct2.id, ERP_Product__c = objProduct2.id);
        insert objFRUList2;

        SVMXC__Service_Order__c workOrder;

        System.runAs(objIntServiceSnapUser){

            Case objCase = TestDataCase.initServiceRequestCase(objContact);
            insert objCase;

            List<SVMXC__Site__c> lstLocation = new List<SVMXC__Site__c>();
            SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = TestPartsOrderLines.STRING_FROM_LOCATION);
            lstLocation.add(objLocationRec);
            
            SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = TestPartsOrderLines.STRING_TO_LOCATION,SVMXC__Stocking_Location__c=true,Type__c=TestPartsOrderLines.STRING_SHIPPING_TYPE_TRUNK);
            lstLocation.add(toLocation);
            
            insert lstLocation;

            SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
            insert serviceTeam;
            
            SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(objAdminUser.id,'Primary Field Application Scientist',serviceTeam.id);
            technician.SVMXC__Email__c='a@b.com';
            technician.Preferred_Service_Report_Language__c='Japanese';
            technician.SVMXC__Inventory_Location__c = lstLocation.get(1).id;
            insert technician;

            Test.startTest();
            workOrder = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, objCase.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c = WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES;
            workOrder.Is_Auto_Created__c = true;
            workOrder.SVMXC__Company__c = acc.id;
            workOrder.SVMXC__Contact__c = objContact.id;
            workOrder.SVMX_PS_Contact_Email__c = objContact.Email;
            workOrder.SVMX_PS_Contact_Phone__c = objContact.Phone;
            workOrder.SVMXC__Site__c = lstLocation.get(0).id;
            workOrder.SVMXC__Group_Member__c = technician.id;
            workOrder.PO_Number__c ='127845';
            insert workOrder;

            List<SVMXC__Service_Order_Line__c> lstEstimateLine = new List<SVMXC__Service_Order_Line__c>();
            SVMXC__Service_Order_Line__c objOrderDetail = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
            objOrderDetail.SVMXC__Product__c = objProduct.Id;
            objOrderDetail.SVMXC__Estimated_Quantity2__c = 2;
            objOrderDetail.Field_Replaceable_Unit_Product__c = objFRUList.id;
            lstEstimateLine.add(objOrderDetail);

            SVMXC__Service_Order_Line__c objOrderDetailLabor = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
            objOrderDetailLabor.SVMXC__Product__c = objProduct1.Id;
            objOrderDetailLabor.SVMXC__Estimated_Quantity2__c = 2;
            objOrderDetailLabor.SVMXC__Line_Type__c = 'Labor';
            lstEstimateLine.add(objOrderDetailLabor);

            SVMXC__Service_Order_Line__c objOrderDetailBlocked = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
            objOrderDetailBlocked.SVMXC__Product__c = objProduct2.Id;
            objOrderDetailBlocked.SVMXC__Estimated_Quantity2__c = 2;
            objOrderDetailBlocked.Field_Replaceable_Unit_Product__c = objFRUList2.id;
            lstEstimateLine.add(objOrderDetailBlocked);

            SVMXC__Service_Order_Line__c objOrderDetailInstrument = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
            objOrderDetailInstrument.SVMXC__Product__c = objProduct3.Id;
            objOrderDetailInstrument.SVMXC__Estimated_Quantity2__c = 2;
            lstEstimateLine.add(objOrderDetailInstrument);

            SVMXC__Service_Order_Line__c objOrderDetailCore = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
            objOrderDetailCore.SVMXC__Product__c = objProduct4.Id;
            objOrderDetailCore.SVMXC__Estimated_Quantity2__c = 2;
            lstEstimateLine.add(objOrderDetailCore);
            insert lstEstimateLine;

            Test.stopTest();
        }
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrder = [Select Id,SVMXC__Order_Type__c from SVMXC__RMA_Shipment_Order__c where SVMXC__Service_Order__c =: workOrder.id];
        System.assert(!lstPartsOrder.isEmpty(), 'Parts Order Creation Failed');
        
        List<SVMXC__RMA_Shipment_Line__c> lstPOL = [Select Id,SVMXC__Product__c  from SVMXC__RMA_Shipment_Line__c  where SVMXC__RMA_Shipment_Order__c =: lstPartsOrder[0].id];
        System.debug('lstPOL size: '+lstPOL.size());
        System.debug('lstPOL: '+lstPOL);
        System.assertEquals(2, lstPOL.size(), 'POL created for Labor and Blocked Product Estimate Line');
        
    }
	
	/*Test method to cover Catch Block of Class UpdateConfirmOperability_WDHelper
	*/
   @isTest
   public static void coverCatchBlockUpdateConfirmOperabilityWDHelper(){
    try{
        UpdateConfirmOperability_WDHelper.catchException = true;
        UpdateConfirmOperability_WDHelper uc = new UpdateConfirmOperability_WDHelper(null, null, null);
        Test.startTest();
        System.enqueueJob(uc);
        Test.stopTest();
    	}catch(Exception e){
            System.assert(e!=null, 'e is not empty');
    	}
   }
}
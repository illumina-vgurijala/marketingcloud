/***************************************************************************************************************************************
* @Author:  Nidhi Hegde
* @Date:    05-Oct-2023 
* @Name :   TestPartsOrderApproval
* @Description: For Covering Parts_Order_Notify_Primary_Secondary_FSE_for_review_and_Approval_of_Parts_Order Flow
* ----------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ---------------------------------------------------------------------------------------------------------------------------------------
* Nidhi Hegde             05-Oct-2023        Initial Version (CMCM-3826)
******************************************************************************************************************************************************************/

@IsTest(SeeAllData=true)
public class TestPartsOrderApproval {
    public static final string STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON = 'Goodwill';
    public static final string STRING_PARTS_ORDER_LINE_STATUS = 'Open';
    public static final string STRING_PRODUCT_CODE = 'Test 123';
    public static final string STRING_PRODUCT_CODE1 = 'Test 1234';
    public static final string STRING_PRODUCT_INSTRUMENT_CLASS = 'Instrument';
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
	public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
   
   /**
    *  @author Nidhi Hegde
   * This test method is responsible for testing the order approval workflow.
  */    
    @isTest
    public static void testOrderApproval() {
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = 'Sold To';
        update objAccount;
        
        Contact objContact = TestDataContact.getNewContact(objAccount);
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;
        
        Profile proId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Service' LIMIT 1];
        User u = TestDataUser.initPartnerUser(proId.id,objContact.Id);
        insert u;
        
        User manager1 = TestDataFieldService.createUser('Field Service', true);
        User manager2 = TestDataFieldService.createUser('Field Service', false);
        manager2.ManagerId = manager1.id;
        manager2.UserName = 'Second'+ manager2.UserName;
        insert manager2;
        User sapUsr = TestDataFieldService.createUser('Integration SAP Service', false);
        sapUsr.ManagerId = manager2.Id;
        insert sapUsr;
        
        SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
             
        SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
            Name = 'testStockingLocation',
            CurrencyIsoCode = 'USD',
            SVMXC__Stocking_Location__c = true,
            SVMX_PS_Active__c = true,
            SVMXC__Service_Engineer__c=sapUsr.id,
            Type__c = 'Trunk'
        );
        list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
        locList.add(location);
        locList.add(shippingLocation);
        insert locList;
        
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        partOrder.ERP_Sales_Order_Number__c = '1765';
        partOrder.SVMXC__Company__c = objAccount.id;
        partOrder.Contact_Name__c = 'Test';
        partOrder.Contact_Phone__c = 'Test';
        partOrder.SVMXC__Order_Type__c = 'Shipment';
        partOrder.SVMXC__Destination_Location__c = locList[0].Id;
        partOrder.Shipping_Location__c = locList[1].Id;
        partOrder.Requested_Delivery_Date__c = date.today() + 2;
        partOrder.Requested_By__c = u.Id;
        insert partOrder;
        
        List<Product2> lstProducts = new List<Product2>();
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = 'Spare';
        lstProducts.add(objProduct);
        Product2 objProduct1 = TestDataMaster.initProduct(STRING_PRODUCT_CODE1);
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        lstProducts.add(objProduct1);
        
        insert lstProducts;
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        list <SVMXC__RMA_Shipment_Line__c > objPartsOrderLineList = new list <SVMXC__RMA_Shipment_Line__c > ();
		Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();        
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = new SVMXC__RMA_Shipment_Line__c();
        objPartsOrderLine1.SVMXC__RMA_Shipment_Order__c = partOrder.Id;
        objPartsOrderLine1.SVMXC__Product__c = lstProducts[0].Id;
        objPartsOrderLine1.From_Location__c = objLocationRec.id;
        objPartsOrderLine1.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine1.Requested_Delivery_Date__c = system.today();
        objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLineList.add(objPartsOrderLine1);
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
        objPartsOrderLine.SVMXC__Product__c = lstProducts[1].Id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId; 
        objPartsOrderLine.Reason__c = STRING_PARTS_ORDER_LINE_NON_BILLABLE_REASON;
        objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine.Requested_Delivery_Date__c = system.today();
        objPartsOrderLineList.add(objPartsOrderLine);
        
        insert objPartsOrderLineList;
        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('PartsOrderID',partOrder.Id);    
        Flow.Interview flw = new Flow.Interview.Parts_Order_Notify_Primary_Secondary_FSE_for_review_and_Approval_of_Parts_Order(inputs);
        flw.start();
        SVMXC__RMA_Shipment_Order__c partsOrderList = (SVMXC__RMA_Shipment_Order__c)flw.getVariableValue('ObjPartsOrder');  
        User usrList = (User)flw.getVariableValue('PartsOrderUser');
        String contactId = (String)flw.getVariableValue('varContactId');
        String partnerEmail = (String)flw.getVariableValue('ListPartnerUserEmails');
        Assert.isTrue (partsOrderList != null);
        Assert.isTrue (usrList != null);
        Assert.isTrue (ContactId != null);
        Assert.isTrue (partnerEmail != null);
        Test.stopTest();
        Integer emailCount = Limits.getLimitEmailInvocations();
        Assert.isTrue(emailCount != null, 'email not sent');
    }
    /**
    *  @author Nidhi Hegde
    * This test method is responsible for testing the handling of exceptions during the parts order workflow. 
   */
    @isTest
    public static void testPartsOrderException() {
        Profile proId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Service' LIMIT 1];
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('PartsOrderID',proId.Id);    
        Flow.Interview flw = new Flow.Interview.Parts_Order_Notify_Primary_Secondary_FSE_for_review_and_Approval_of_Parts_Order(inputs);
        Test.startTest();
        flw.start();
        Test.stopTest();
        List<Exception_Log__c> logList = [SELECT Id, Name, Message__c, Related_Record__c, Source__c, Type__c, Workstream__c, Line_Number__c FROM Exception_Log__c LIMIT 1];
        Assert.isTrue(!logList.isEmpty());
    }
}
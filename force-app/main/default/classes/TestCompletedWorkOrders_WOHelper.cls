/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for CompletedWorkOrders_WOHelper
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Nancy             06-06-2023            CMCM-85: Enforce processing of parts order return before completing the work order
 *               Annotated with SeeAllData=true due to dependency on ServiceMax managed trigger
*/
@IsTest(SeeAllData=true)
private class TestCompletedWorkOrders_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final String WORKDETAIL_RECORDTYPE = 'Usage/Consumption';
    private static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    static SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c();
    static SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c();
    static  Account acc;
    static Contact con;
    static Case cs;

    /**
    *  @description - initialize test data
    **/
    public static void initializeTestData() {
        serviceTeam.Name = STRING_SERVICE_TEAM_NAME;
        serviceTeam.SVMXC__Country__c = 'India';
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
            grpMembers.Name = 'Test Name';
            grpMembers.SVMXC__Active__c = True;
            grpMembers.SVMXC__Email__c = 'testmail@testing.com';
            grpMembers.SVMXC__Country__c = 'India';
            grpMembers.SVMXC__Street__c = 'Test';
            grpMembers.SVMXC__Salesforce_User__c = lstUsers[0].Id;
            grpMembers.SVMXC__Service_Group__c = serviceTeam.Id;
        insert grpMembers;
        acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Clinical_Type__c = 'Clinical';
        acc.Account_Group__c='Distributor';
        insert acc;

        //insert contact
        con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case        
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

      
    /**
    *  @author Ritika Maheshwari
    *  @description - test the work order status on case when a new work order is inserted 
    **/
    static testMethod void workOrderStatusUpdatedToCompletedWithNoOtherWO() {
        User u = TestDataFieldService.createUser('Professional Services',false);
        Insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'View_All_Modify_All'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = ps.Id);
        PermissionSet duplicateAcc = [SELECT Id FROM PermissionSet WHERE Name = 'Bypass_Duplicate_Account_Rules_Permission'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = duplicateAcc.Id);
        System.runAs(u) {
        cs_Apex_Settings__c settings = cs_Apex_Settings__c.getInstance(UserInfo.getprofileID());
        settings.Bypass_All_Validations__c = true;
        upsert settings;

        initializeTestData(); 
        List<SVMXC__Service_Order__c> lstWorkOrderInserted = new List<SVMXC__Service_Order__c>();
        for(integer i=0; i<1; i++) {  // Changing it to fix the cpu error
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
            workOrder.Is_Service_Report_Generated__c=true;
            workOrder.Record_Created_from_SFM__c=true;
            workOrder.Evaluation__c='Test';
            workOrder.SVMXC__Work_Performed__c='Test';
            workOrder.Verification_Result__c='Test'; 
            workOrder.PO_Number__c = '12345';   
            workOrder.Cost_Center__c = 123456;
            lstWorkOrderInserted.add(workOrder);
        }
        Test.startTest();
        WorkOrders.skipWOTrigger = true;
        insert lstWorkOrderInserted;
        
        SVMXC__Service_Order_Line__c objWorkDetail =TestDataFieldService.createWorkDetailWithSpecifiedRecordType(lstWorkOrderInserted[0].Id,WORKDETAIL_RECORDTYPE);
        objWorkDetail.SVMXC__Activity_Type__c = 'Repair/Troubleshooting';
        objWorkDetail.Duration_in_hours__c = '1';
        objWorkDetail.SVMXC__Line_Type__c = WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR;
        objWorkDetail.Non_Billable_Reason__c = 'Goodwill';
        insert objWorkDetail;

        SVMXC__RMA_Shipment_Order__c partOrder1 = TestDataFieldService.createPartOrder('RMA', cs.id, 'Open');
        partOrder1.SVMXC__Service_Order__c = lstWorkOrderInserted[0].id;
        partOrder1.Contact_Name__c = 'Test';
        partOrder1.Contact_Phone__c = 'Test';
        partOrder1.SVMXC__Order_Type__c = 'Return';
        insert partOrder1;

        
        partOrder1.SVMXC__Order_Status__c  = 'On Hold';
        //partOrder1.Bypass_Validation_Rules_for_Integration__c = true;
        WorkOrders.skipWOTrigger = false;
        update partOrder1;
        Test.stopTest();
                lstWorkOrderInserted[0].SVMXC__Order_Status__c = 'Completed';
                lstWorkOrderInserted[0].No_Calibrated_Tools_Used__c = true;
                lstWorkOrderInserted[0].Signature_Type__c='Manual Sign';
                lstWorkOrderInserted[0].Manual_Sign_Captured__c=true;
                lstWorkOrderInserted[0].Is_Customer_Sign_Captured__c=true;
                lstWorkOrderInserted[0].Cost_Center__c=876765;
            try {
                    update lstWorkOrderInserted[0];
                } catch(DmlException e) {
                    system.assert(e.getMessage().contains(system.label.UI_Error_WO_PendingGoodwillApproval), 'Exception');
            }
        }
    }
	/*******************************************************************************************************
    * @description test method to cover CompletedWorkOrders_WOHelper
    */ 
    static testmethod void testCompleteWO() {

        cs_Apex_Settings__c custApexSetting  = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
    custApexSetting.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
        upsert custApexSetting;

        initializeTestData(); 

        //Creating Work Order
         list <SVMXC__Service_Order__c> woList = new list <SVMXC__Service_Order__c>();
         SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
         workOrder1.SVMXC__Order_Status__c='Assigned';
         workOrder1.Is_Auto_Created__c = true;
         woList.add(workOrder1);
         Id woRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(STRING_WO_RECORDTYPE_REMOTE_SUPPORT).getRecordTypeId();
         SVMXC__Service_Order__c workOrder2 = new SVMXC__Service_Order__c(
             RecordTypeId = woRecordTypeId,
             SVMXC__Case__c = cs.Id,
             SVMXC__Order_Type__c = STRING_WO_RECORDTYPE_REMOTE_SUPPORT,
             SVMXC__Order_Status__c='In Progress',
             Is_Auto_Created__c = true
         );
         woList.add(workOrder2);

         insert woList;
         Test.startTest();

         // CMCM-85 non-instrument Product
         Product2 product2 = TestDataMaster.createProduct(false);
         product2.Material_Group__c  = '41';
         product2.Service_Product_Type__c = 'Core';
         insert product2;

         SVMXC__Site__c objLocationRec12 = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
         insert objLocationRec12;

        // CMCM-85 - Create Return PO
        SVMXC__RMA_Shipment_Order__c partOrder2 = new SVMXC__RMA_Shipment_Order__c();
        partOrder2.SVMXC__Service_Order__c = workOrder2.id;
        partOrder2.Contact_Name__c = 'Test';
        partOrder2.Contact_Phone__c = '123';
        partOrder2.SVMXC__Order_Type__c = 'Return';
        partOrder2.SVMXC__Order_Status__c  = 'Open';
        partOrder2.SVMXC__Priority__c = 'Normal';
        insert partOrder2;
         
         //Insert Location
         SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
         SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
                 Name = 'testStockingLocation',
                 CurrencyIsoCode = 'USD',
                 SVMXC__Stocking_Location__c = true,
                 SVMX_PS_Active__c = true,
                 Type__c = 'Trunk');
         list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
             locList.add(location);
             locList.add(shippingLocation);
         insert locList;

        // CMCM-85 Create POL with non-instrument Product
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine12 = new SVMXC__RMA_Shipment_Line__c();  
        objPartsOrderLine12.SVMXC__RMA_Shipment_Order__c = partOrder2.Id;
        objPartsOrderLine12.SVMXC__Line_Status__c = 'Open';
        objPartsOrderLine12.SVMXC__Product__c = product2.id;
        objPartsOrderLine12.Return_Reason__c = 'Return for Scrap';
        objPartsOrderLine12.SVMXC__Actual_Quantity2__c = 1;
        objPartsOrderLine12.To_Location__c = objLocationRec12.id;
        insert objPartsOrderLine12;

         // Creating Part Order
         SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', cs.Id, 'Open');
         partOrder.ERP_Sales_Order_Number__c = '0000';
         partOrder.SVMXC__Service_Order__c = workOrder1.id;
         partOrder.Contact_Name__c = 'Test';
         partOrder.Contact_Phone__c = 'Test';
         partOrder.SVMXC__Order_Type__c = 'Shipment';
         partOrder.SVMXC__Destination_Location__c = locList[0].Id;
         partOrder.Shipping_Location__c = locList[1].Id;
         insert partOrder;
         Test.stopTest();
        
        workOrder1.SVMXC__Order_Status__c='Awaiting Parts';
        try{
            update workOrder1;
        } catch(Exception e) {
            System.debug('Exception' + e);
        }

        // CMCM-85 - Try to complete WO
        workOrder2.Evaluation__c = 'evaluation';
        workOrder2.SVMXC__Work_Performed__c= 'work performed';
        workOrder2.Verification_Result__c = 'verification result';
        workOrder2.SVMXC__Order_Status__c='Completed';
        Boolean isException = false;
        try{
            WorkOrders.skipWOTrigger = false;
            update workOrder2;
        } catch(Exception e) {
            if(e.getMessage().contains('Request or Cancel all associated Parts Orders'))
            isException = true;
            System.assert(isException, 'Exception should get thrown while completing WO');
        }
        List<SVMXC__Service_Order__c> lstWorkOrder = [Select Id, SVMXC__Order_Status__c from SVMXC__Service_Order__c where id=:workOrder2.Id];
        System.assertNotEquals('Completed', lstWorkOrder[0].SVMXC__Order_Status__c);

        List<SVMXC__RMA_Shipment_Order__c> lstPartOrder = [Select Id, ERP_Sales_Order_Number__c from SVMXC__RMA_Shipment_Order__c where id=:partOrder.Id];
        System.assertEquals('0000', lstPartOrder[0].ERP_Sales_Order_Number__c, 'Diff Sales order number');
       }

}
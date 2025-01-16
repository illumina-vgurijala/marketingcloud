/**
* @author Shivani Jain
* @date 13th June 2022
*
* @description DCP-54018 Test class for AsyncCalls_WOHelper
* Date                           Name                                        Description
 * 19-09-2022                    Sheikh Shahnawaz                            Enhance code coverage above 80%
 * 06-26-2023                    Saikiran Surapaneni                         Updated autoCloseQueueableTest method for CMCM1019
*/
@IsTest
public with sharing class TestAsyncCalls_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    private static final String FIELD_STOCK_MANAGEMENT = 'Field Stock Management';
    private static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    private static final String STRING_WO_STATUS_IN_PROGRESS = 'In Progress';
    private static final String WORKDETAIL_RECORDTYPE = 'Usage/Consumption';
    private static final String STRING_TIMEZONE = 'America/Los_Angeles';
    private static final String STRING_USER_EMAIL = 'puser000@amamama.com';
    /**
    *  @description - initialize test data
    **/
    @testSetup
    public static void initializeTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    /**
    *  @author Naomi Thammadi
    *  @description - test the refactoring process of work flows
    **/
    static testMethod void testInsertWOResource() {
        Case cs = [SELECT id FROM Case LIMIT 1];
        Boolean exceptionThrown = false;
                  
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        try {
            Test.startTest();
            InsertWOResourceQueueable_WOHelper.testClassCoverage = true;
           
            insert workOrder;
            System.assert(workOrder.Id != null,'workorder id is null');

            workOrder.SVMXC__Order_Status__c = System.Label.WorkOrderStatusTechnicianOnsite;
            workOrder.SVMXC__Order_Type__c = System.Label.WorkOrderTypeServiceActivities;
            workOrder.First_Time_Fix_Count__c=null;
            workOrder.SVMXC__Billing_Type__c = 'Billable';
            update workOrder;
            Test.stopTest();
        } catch(Exception ex) {
            exceptionThrown = ex.getMessage().contains('Throwing Exception from Test Class');
        }

        System.assert(exceptionThrown, 'Exception not thrown from queueable class');
        
    }

    /**
    *  @author Shivani Jain
    *  @description - test UpdateWOQueueable_WOHelper
    **/
    static testMethod void testUpdateWOQueueable() {
        Case cs = [SELECT id FROM Case LIMIT 1];
        Boolean exceptionThrown = false;
                  
       
        try {
            
            Test.startTest();
            UpdateWOQueueable_WOHelper.testClassCoverage = true;
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
            workOrder.Record_Created_from_SFM__c=true;
            insert workOrder;
            System.assert(workOrder.Id != null,'workorder id is null');

            workOrder.Parts_Consumed_By_SAP__c = true;
            update workOrder;
            Test.stopTest();
        } catch(Exception ex) {
            exceptionThrown = ex.getMessage().contains('Throwing Exception from Test Class');
        }

        System.assert(exceptionThrown, 'Exception not thrown from queueable class');
        
    }

    /**
     * Method: testUpdateBillableTypeOnWO
     * DCP-38965
     * @author : sandeep 
     * */
    public static testMethod void testUpdateBillableTypeOnWO() {
        //Dhairya Shah- Added apex settings for code coverage
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Account',
            Bypass_Triggers_By_Object_2__c = 'Case',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Group_Members__c',
            //Bypass_Triggers_By_Object_4__c = 'SVMXC__Site__c',
             Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Order_Line__c'
        );
        insert apexSettings;

        Account objAccount = TestDataAccount.initAccount();//TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;
        List<SVMXC__Installed_Product__c> lstIp = new List<SVMXC__Installed_Product__c>();
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c=objAccount.Id;
        lstIp.add(objInstalledProduct);
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct1.SVMXC__Company__c=objAccount.Id;
        lstIp.add(objInstalledProduct1);
        insert lstIp;
        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;
        SVMXC__Service_Contract__c objServiceContract= TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        objServiceContract.Parts_Included__c=true;
        insert objServiceContract;
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(lstIp[0].Id );
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc; 
         Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2; 

        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;
         
        Contact objContact = TestDataPerson.getNewContact(objAccount.Id);
        
        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', objContact.Id);
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        objWorkOrder.SVMXC__Component__c = lstIp[1].Id;
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        objWorkOrder.SVMXC__Case__c = objCase.Id;
        objWorkOrder.Record_Created_from_SFM__c=true;
        objWorkOrder.Cost_Center__c = 10;
        test.startTest(); 
        insert objWorkOrder;
        
        SVMXC__Service_Order__c wo =[select id,SVMXC__Billing_Type__c,SVMXC__Component__c from SVMXC__Service_Order__c where id= : objWorkOrder.id];
        System.assertEquals(null,wo.SVMXC__Billing_Type__c,'wo.SVMXC__Billing_Type__c is null'); 
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = objWorkOrder.id;
        workDetail1.SVMXC__Line_Type__c='Parts';
        workDetail1.SVMXC__Product__c = toolProduct2.Id;
        workDetail1.SVMXC__Is_Billable__c = true;
        workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467          
        insert workDetail1;   
        /* Enhance test class coverage start */
        workDetail1.SVMXC__Line_Type__c = WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS;
        workDetail1.SVMXC__Is_Billable__c = false;
        workDetail1.Non_Billable_Reason__c = '';
        workDetail1.Billable_AutoUpdated__c = true;
        Update workDetail1;
        test.stoptest();
        set<Id> setWoId = new set<Id>();
        setWoId.add(objWorkOrder.Id);
        UpdateWDQueueable_WOHelper.updateIsBillaleOnWdByCS(setWoId); 
        SVMXC__Service_Order__c wo1 =[select id,SVMXC__Billing_Type__c from SVMXC__Service_Order__c where id= : wo.id];
        System.assertEquals('Billable',wo1.SVMXC__Billing_Type__c,'wo1.SVMXC__Billing_Type__c is Billable'); 
         /* Enhance test class coverage end */
         
     }

         /**
      * Method:populateFieldSupportAndOwnerFromLocationTest
      * Description: Test populateFieldSupportAndOwnerFromLocation method in workorder
      * return:NA
      * params:NA
      * */
      static testMethod void testUpdateWDQueueable() {
        //insert acc

        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Account',
            Bypass_Triggers_By_Object_2__c = 'User',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Group_Members__c',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Order_Line__c',
            //Dhairya Shah- Added apex settings for test coverage
            //Bypass_Triggers_By_Object_4__c = 'SVMXC__Site__c',
            Bypass_Triggers_By_Object_5__c = 'SVMXC__Service_Order__c'
        );

        insert apexSettings;
       
       Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
       acc.Account_Group__c='Distributor';
       acc.ERP_Customer_Id__c = 'Test1';
       insert acc;
       System.assert(acc.Id != null, 'Account insertion failed'); 
       
       //insert contact
       Contact con = TestDataPerson.getNewContact(acc.Id);
       System.assert(con.id != null, 'Contact Insertion failed');
       
       Case cs = [SELECT id FROM Case LIMIT 1];
       
       User serviceEngineer = TestDataFieldService.createUser('Field Service Logistics',false);
       
       User sapUsr = TestDataFieldService.createUser('Integration SAP Service', false);
       sapUsr.LastName = 'Integration';
       sapUsr.UserName = sapUsr.UserName+'1';
       List<User> lstUser = new List<User>{serviceEngineer, sapUsr};
       insert lstUser;

       SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam('TestTeam','US');
       insert serviceTeam;
       SVMXC__Service_Group_Members__c fieldSupport = TestDataFieldService.getNewFieldSupport(ServiceEngineer.Id,'PreferedTechnician',serviceTeam.Id);
       
       SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
       objLocation.SVMXC__Service_Engineer__c = serviceEngineer.Id;

       SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
       objLocation1.SVMX_PS_Preferred_Technician__c=fieldSupport.Id;
       List<SVMXC__Site__c> lstSites = new List<SVMXC__Site__c>{objLocation, objLocation1};
       insert lstSites;
       
       List<SVMXC__Service_Order__c> lstWorkOrder = new List<SVMXC__Service_Order__c>();
       SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(FIELD_STOCK_MANAGEMENT, cs.Id, 'Initiated');
       workOrder.SVMXC__Order_Type__c='Installation';
       workOrder.SVMXC__Company__c=acc.id;
       workOrder.Is_Auto_Created__c = true;
       workOrder.ProActive_Account_ERP_Customer_Id__c = 'Test1';
       workOrder.SVMXC__SM_SLA_Initial_Response__c = 2880;
       workOrder.SVMXC__Site__c = objLocation.Id;
       lstWorkOrder.add(workOrder);
       
       SVMXC__Service_Order__c workOrder1= TestDataFieldService.createWorkOrder(FIELD_STOCK_MANAGEMENT, cs.Id, 'Initiated');
       workOrder1.SVMXC__Order_Type__c='Installation';
       workOrder1.SVMXC__Company__c=acc.id;
       workOrder1.Is_Auto_Created__c = true;
       workOrder1.ProActive_Account_ERP_Customer_Id__c = 'Test2';
       workOrder1.SVMXC__Site__c = objLocation1.Id;
       workOrder1.SVMXC__Customer_Down__c = true;
       workOrder1.Reason__c = 'test';
       lstWorkOrder.add(workOrder1);
       
       SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
       workOrder2.SVMXC__Company__c=acc.id;
       workOrder2.Is_Auto_Created__c = true;
       workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
       workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
       workOrder2.SVMXC__Site__c = objLocation1.Id;
       lstWorkOrder.add(workOrder2);
       
       SVMXC__Service_Order__c workOrder3 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Assigned');
       workOrder3.SVMXC__Company__c=acc.id;
       workOrder3.Is_Auto_Created__c = true;
       workOrder3.ProActive_Account_ERP_Customer_Id__c = 'Test2';
       workOrder3.SVMXC__Site__c = objLocation1.Id;
       lstWorkOrder.add(workOrder3);
       
       System.runAs(sapUsr) {
            insert lstWorkOrder;

            Test.startTest();

            SVMXC__Service_Order_Line__c objWorkDetail =TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder2.Id,WORKDETAIL_RECORDTYPE);
            objWorkDetail.SVMXC__Activity_Type__c = 'Repair/Troubleshooting';
            objWorkDetail.Duration_in_hours__c = '1';
            objWorkDetail.SVMXC__Line_Type__c = WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR;
            insert objWorkDetail;
            
            lstWorkOrder[2].SVMXC__Order_Status__c = 'Initiated';
            lstWorkOrder[2].Is_Auto_Dispatch__c = true;
            lstWorkOrder[2].SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
            lstWorkOrder[2].Reason__c = 'Testing';
            lstWorkOrder[2].SVMXC__SM_SLA_Initial_Response__c = 7200;
            lstWorkOrder[2].Send_to_ERP__c = True;
            
            lstWorkOrder[3].SVMXC__Order_Status__c = 'Canceled';
            lstWorkOrder[3].Reason__c = 'Test';
            lstWorkOrder[3].SVMXC__Customer_Down__c = true;
            lstWorkOrder[3].SVMXC__SM_SLA_Initial_Response__c = 4320;
            
            lstWorkOrder[0].SVMXC__Order_Status__c = 'Scheduled';
            lstWorkOrder[0].Send_Notification_To_Customer__c = true;
            lstWorkOrder[0].SVMXC__SM_SLA_Initial_Response__c = 2880;
            
            update lstWorkOrder;
            Test.StopTest();
            FieldStockFSOwner_WOHelper.populateFieldSupportAndOwnerFromLocation(lstWorkOrder);
            List<SVMXC__Service_Order__c> lstWO = [Select Id,OwnerId from SVMXC__Service_Order__c where Id =: lstWorkOrder[0].Id];
            System.assertEquals(lstWO[0].OwnerId, sapUsr.Id, 'Owner not updated');
        }
        
 }

    /**
    *  @author Ritika Maheshwari
    *  @description - test the work order status on case when a new work order is inserted 
    **/
    static testMethod void autoCloseQueueableTest() {
        //Dhairya Shah - Added Apexsettings for code coverage
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case'
       );
       insert apexSettings;

        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
      acc.Account_Group__c='Distributor';
      acc.ERP_Customer_Id__c = 'Test1';
      insert acc;
       
       Case cs = [SELECT id FROM Case LIMIT 1];
       List<SVMXC__Service_Order__c> lstWorkOrderInserted = new List<SVMXC__Service_Order__c>();
       for(integer i=0; i<10; i++){
           SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
           workOrder.SVMXC__Order_Type__c='Connected';
           workOrder.Is_Service_Report_Generated__c=true;
           workOrder.Record_Created_from_SFM__c=true;
           workOrder.Evaluation__c='Test';
           workOrder.SVMXC__Work_Performed__c='Test';
           workOrder.Verification_Result__c='Test'; 
           workOrder.PO_Number__c = '12345';      
           workOrder.Additional_Detail__c = 'Test';         
           lstWorkOrderInserted.add(workOrder);
       }
       insert lstWorkOrderInserted;
       SVMXC__Service_Order_Line__c objWorkDetail =TestDataFieldService.createWorkDetailWithSpecifiedRecordType(lstWorkOrderInserted[0].Id,WORKDETAIL_RECORDTYPE);
       objWorkDetail.SVMXC__Activity_Type__c = 'Repair/Troubleshooting';
       objWorkDetail.Duration_in_hours__c = '1';
       objWorkDetail.SVMXC__Line_Type__c = WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR;
       //objOrderDetailPart3.Labor_Hours__c  = '1';
       
       Opportunity opp1 = TestDataOpportunity.initOpportunity(acc,Label.OpportunityRTIndirectStandard);
       opp1.Name = 'opp1';
       opp1.Ultimate_Consignee__c = acc.Id;
       opp1.Direct_Sale_to_Ultimate_Consignee__c = true;
       insert opp1;
       
          Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId(); 
       
       cs.RecordTypeId = idCaseRecordTypeId;
       update cs;   
       
       Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
       objProduct.Product_Group__c = 'AmpliSeq Library Prep';
       insert objProduct;
       
       SVMXC__Service_Order__c objNewWorkorder = new SVMXC__Service_Order__c();
       SVMXC__Service_Order__c objOldWorkorder = new SVMXC__Service_Order__c();
       Set<Id> setAbandonedWOId = new Set<Id>();
       Set<Id> setAbandonedWOOppId = new Set<Id>();
       objNewWorkorder.Abandoned_Reason__c = 'No Customer Response';
       objNewWorkorder.SVMXC__Case__c = cs.Id;
       Case caseRecord = new Case();
       caseRecord.RecordType = new RecordType(Name = 'Business Issue');
       Map<Id, Case> caseIdToCase = new Map<Id, Case>();
       caseIdToCase.put(objNewWorkorder.SVMXC__Case__c, caseRecord);  
       objNewWorkorder.opportunity__c = opp1.Id; 
     
       
       Test.startTest();
       insert objWorkDetail;
       
       
       objOldWorkorder.Abandoned_Reason__c = 'Customer Declined Service';
       update objWorkDetail;
    
       //Test.startTest();
       lstWorkOrderInserted[0].SVMXC__Order_Status__c = 'Completed';
       lstWorkOrderInserted[0].No_Calibrated_Tools_Used__c = true;
       lstWorkOrderInserted[0].Signature_Type__c='Manual Sign';
       lstWorkOrderInserted[0].Manual_Sign_Captured__c=true;
       lstWorkOrderInserted[0].Is_Customer_Sign_Captured__c=true;
       lstWorkOrderInserted[0].Abandoned_Reason__c = 'Customer Declined Service';
       lstWorkOrderInserted[0].SVMXC__Case__c = cs.Id;
       lstWorkOrderInserted[0].Cost_Center__c=876765;
       lstWorkOrderInserted[0].SVMXC__Product__c = objProduct.Id;
       update lstWorkOrderInserted[0];
        
       AsyncCalls_WOHelper.addWOForStatusOwnerOrAbandonedReasonUpdate(objNewWorkorder, objOldWorkorder, null, setAbandonedWOId, setAbandonedWOOppId);

       Case updatedCase = [Select Work_Order_Status__c from Case where Id =: cs.Id];
       System.assertEquals(updatedCase.Work_Order_Status__c, STRING_WO_STATUS_IN_PROGRESS, 'Work Order Status failed to change to In Progress');
       System.assertEquals('Closed', [select id, SVMXC__Line_Status__c from SVMXC__Service_Order_Line__c where id =: objWorkDetail.Id][0].SVMXC__Line_Status__c, 'Work Detail not Closed');
       Test.stopTest();
   }

    static testMethod void testUpdateCaseQueueable() {   

        Boolean exceptionThrown = false;     
             
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assertNotEquals(null, acc.Id);  
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        insert objInstalledProduct;
        System.assertNotEquals(null, objInstalledProduct.Id);
        
        Contact con  = TestDataPerson.getNewContact(acc.Id);
        Contact con1  = TestDataPerson.getNewContact(acc.Id);
        con1.Email = 'pqr@xyz.com';
        update con1;
        Case cs1= new Case();
        Cs1=TestDataCase.initServiceRequestCase(con1);
        try {
            UpdateCaseQueueable_WOHelper.testClassCoverage = true;
            insert cs1;     
            System.assertNotEquals(null, cs1.Id);
            Test.startTest(); 
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs1.Id, 'Initiated');
            workOrder.SVMXC__Component__c = objInstalledProduct.Id;
            workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
            workOrder.SVMXC__Company__c = acc.Id;
            workOrder.Is_Auto_Created__c = true;
            workOrder.SVMXC__Contact__c= con.id;
            insert workOrder;
            System.assertNotEquals(null, workOrder.Id);        
            
                workOrder.SVMXC__Contact__c= con1.id;   
     
                update workOrder;
            Test.stopTest();
            System.assertEquals('pqr@xyz.com', 
                            [select id,SVMX_PS_Contact_Email__c from SVMXC__Service_Order__c where id =: workOrder.Id][0].SVMX_PS_Contact_Email__c, 'Contact Email not updated');
        } catch(Exception ex) {
            exceptionThrown = ex.getMessage().contains('Throwing Exception from Test Class');
        }
        System.assert(exceptionThrown, 'Exception not thrown from queueable class');
    }

    /**
     *  @author Digvijay
    *  @description - test the TPSP Sharing logic
    **/
    static testMethod void tpspSharingTest() {

        Case cs = [SELECT id FROM Case LIMIT 1];
        Boolean exThrown = false;

        User serviceEngineer = TestDataFieldService.createUser('Field Service Logistics', true);
        
        //changded from field support to Remote support by prashanth
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        try {
            Test.startTest();
            TPSPSharingQueueable_WOHelper.testClassCoverage = true;
            insert workOrder;
            
            workOrder.Ownerid = serviceEngineer.Id;
            update workOrder;
            
            Test.stopTest();
        } catch(Exception ex) {
            exThrown = ex.getMessage().contains('Throwing Exception from Test Class');
        }

        System.assert(exThrown, 'Exception not thrown from queueable class');

    }
   
}
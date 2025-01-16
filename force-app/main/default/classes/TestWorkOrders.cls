/***************************************************************************************************************************************
 * NAME   : TestWorkOrders
 * DESCRIPTION  : TestClass for Work Orders Trigger
 *           DCP-326  :Validation the open work orders on Case
 *    
 * @AUTHOR : Debalina
 * @DATE   : 22-May-2018  
 *
 * MODIFICATION LOG:   
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika             22-May-2018             Initial Version
 * Debalina           15-June-2018            803/802 Code Review comment removed TestDataFieldService.createUser()
 * Akshay             19-June-2018            Changed account creation to TestDataAccount
 * Naomi              13-July-2018            Added workOrderScheduledToCreateEvents() method as part of DCP-5623
 * Raja Siva Krishna  10-Nov-2020             Added testUpdateCostCenterOnWO() method as part of DCP-42762
 * KD                 4-June-2021             DCP-39952 : Send WO to SAP on Schedule date Time update
 * Adyasha            07-Jun-2021             DCP-46317: Added testUpdatedScheduledDate method
 * KD                 7-June-2021             DCP-45874 : Removed logic to update Owner as Estimate Queue for Estimate record type.
 * Gladis             26-June-2021           DCP-45743  Method to check data validation while changing record types to Estimates
 * Gautam Arya        14-Jun-2021            DCP-39881: Added testValidateIfDCIRAgreementIsGenerated method
 * Gautam Arya        22-June-2021           DCP-39881: Added testValidateIfDCIRStatusIsCompleted method
 * KD                 21-June-2021           DCP-45490 : CP Relocation WO should not be billable.
 * Adyasha            25-Jun-2021            DCP-45746 : Added method to check CS Review Activity Creation
 * Gladis             26-June-2021           DCP-38816  Method to check updated Abandoned Opportnity
 * Nishan Shetty      13-Aug-2021            Added checkChannelPartnerWorkOrderCreate() checkChannelPartnerWorkOrderUpdate() and updated testPopulateWDOwnerManager() method as part of CMCP-23
 * Gladis             07-Sep-2021            CMCP-16 Added testcheckPartsOrderStatusChange method, to test method to validate  if no shipment PartsOrders found.
 * Shivani            08-Sep-2021            DCP-47686 : OQ PQ IQ/OQ required: Checkbox instead of Labor Line addition
 * Nishan Shetty      22-Sept-2021           CMCP-64  Method to check Request Ownership Status. 
 * Pooja Shalwadi     17-Sept-2021           DCP-49916: Method to check Training reqired and Reason for no Training field update
 * Rohan Rathod       23-Mar-2022            DCP-49682 : Removal of Elevation 1.0 Code
 * Dhairya            24-July-2024           CMCM-6756 No changes in the test class only using for deployment
  ***************************************************************************************************************************************
*/ 
@isTest(SeeAllData = false isParallel = false)
public with sharing class TestWorkOrders {
  
    public static final String STRING_WO_STATUS_IN_PROGRESS = 'In Progress';
    public static final String STRING_LANGUAGE = 'en_US';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    public static final String STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST = 'Primary Field Application Scientists';
    public static final String STRING_EMAIL = 'a@b.com';
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_USER_EMAIL = 'puser000@amamama.com';
    public static final String STRING_TIMEZONE = 'America/Los_Angeles';
    public static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    public static final String SECONDARY_FIELD_SERVICE_ENGINEER = 'Secondary Field Service Engineer';
    public static final String BUSINESS_ISSUE = 'Business Issue';
    public static final String FIELD_STOCK_MANAGEMENT = 'Field Stock Management';
    public static final String PRODUCT_GROUP_AMPLISEQ = 'AmpliSeq Library Prep';
    public static final String WORKDETAIL_RECORDTYPE = 'Usage/Consumption';
    public static final String STRING_WO_ORDER_TYPE_RELOCATION = 'Relocation';
    public static final String STRING_WO_ORDER_TYPE_BILLABLE_INSTALL = 'Billable Install';
    //DCP-47686
    public static final String CURRENCY_USD = 'USD';
    public static final String STRING_ERROR_QR = 'OQ or type IQ/OQ';
    //DCP-49916 start
    public static final String NON_INSTALL_WO = 'Non-Install WO, not required';
    public static final string STRING_INSTALLED_PRODUCT_IP_NAME = 'A01195-15019046'; // created by Dhairya Shah for CMCM-7910
    public static final string STRING_INSTALLED_PRODUCT_SERIAL_LOT_NUMBER = 'A01195'; // created by Dhairya Shah for CMCM-7910
  
    /**
    *  @author Ritika Maheshwari
    *  @description - initialize test data
    **/
    @testSetup
        /*Test Data*/
    public static void initializeTestData()
    {
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
    *  @author Ritika Maheshwari
    *  @description - test the work order status on case when a new work order is inserted 
    **/
    static testMethod void newWorkOrderCreation(){
        //initializeTestData();
        // To create a FAN record of record type "Notification"
        Field_Action_Notification__c fAN =TestDataFieldService.createFAN('Notification');
        insert fAN;
        Case cs = [Select Id from Case limit 1];
        // To create a second FAI record with FAN record type "Notification"
        Field_Action_Item__c fAI1 =TestDataFieldService.createFAI(CS.Id,FAN.Id);
        try{
            insert fAI1;
       }
       catch(DmlException e) {
           system.assert(e.getMessage().contains(system.label.FANTriggerErrorMessage));
       }
    //changded from field support to Remote support by prashanth
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true; 
        Test.startTest();
        insert workOrder;
        Case updatedCase = [Select Work_Order_Status__c from Case where Id =: cs.Id];
        System.assertEquals(updatedCase.Work_Order_Status__c, STRING_WO_STATUS_IN_PROGRESS);
        Test.stopTest();
    }
    
    /**
    *  @author Shashank Singhal
    *  @description - test the work order status on case when a work order is deleted 
    **/
      static testMethod void workOrderDeletion(){
        //initializeTestData();
        Case cs = [Select Id from Case limit 1];
        List<SVMXC__Service_Order__c> lstWorkOrderInserted = new List<SVMXC__Service_Order__c>();
        for(integer i=0; i<10; i++){
          SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
          workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
            workOrder.Is_Service_Report_Generated__c=true;
            workOrder.Record_Created_from_SFM__c=true;
            lstWorkOrderInserted.add(workOrder);
        }
        Test.startTest();
        insert lstWorkOrderInserted;
        System.assertNotEquals(null, lstWorkOrderInserted[0].Id);
        //Test.startTest();
        delete lstWorkOrderInserted[0];
        Test.stopTest();
        System.assertEquals(STRING_WO_STATUS_IN_PROGRESS, [select id, Work_Order_Status__c from case where id =: cs.Id][0].Work_Order_Status__c);
    }
    /**
    *  @author Sandeep
    *  @description - test the work order contact pre language.
    **/
    static testMethod void woPreferredServiceReportLanguage(){
         contact c = TestDataPerson.initContact(null);
        c.Preferred_Language__c='French';
        insert c;
    List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        
        
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Primary Field Application Scientists',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        technician.Preferred_Service_Report_Language__c='Japanese';
        insert technician;
          SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
          workOrder.SVMXC__Order_Type__c='Installation';
          workOrder.Is_Service_Report_Generated__c=true;
          workOrder.Record_Created_from_SFM__c=true;
          workOrder.SVMXC__Contact__c=c.id;
          workOrder.SVMXC__Group_Member__c=technician.id;
            workOrder.Is_Auto_Created__c=true;
        insert workOrder;
        
        Test.startTest();
        SVMXC__Service_Order__c wo=[select id,Contact_Preferred_Language__c from SVMXC__Service_Order__c where id =:workOrder.id];
        System.assertEquals('French',wo.Contact_Preferred_Language__c);
        wo.SVMXC__Contact__c=null;
        wo.Contact_Preferred_Language__c=null;
        update wo;
        SVMXC__Service_Order__c wo1=[select id,Contact_Preferred_Language__c from SVMXC__Service_Order__c where id =:workOrder.id];
        
        System.assertEquals('Japanese',wo1.Contact_Preferred_Language__c);
    }
    
    /**
    *  @author Ritika Maheshwari
    *  @description - test the work order status on case when a new work order is inserted 
    **/
        static testMethod void workOrderStatusUpdatedToCompletedWithInProgressWO(){
          
        Test.startTest();
        //initializeTestData();
        Case cs = [Select Id from Case limit 1];
        cs.Has_Resolution_Code__c = true;
        update cs;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
       workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
       workOrder.Record_Created_from_SFM__c=true;
     workOrder.SVMXC__Billing_Type__c = 'Billable';
        insert workOrder;
        System.assertNotEquals(null, workOrder.Id);
            workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test'; 
        workOrder.SVMXC__Order_Status__c = 'Completed';
        workOrder.No_Calibrated_Tools_Used__c = true;
         workOrder.Is_Service_Report_Generated__c=true;
         workOrder.Signature_Type__c='Manual Sign';
        workOrder.Manual_Sign_Captured__c=true;
        workOrder.Is_Customer_Sign_Captured__c=true;
         workOrder.PO_Number__c='12';
         workOrder.Cost_Center__c=8765;
         
        Test.stopTest();
        update workOrder;
        
        Case updatedCase = [Select Work_Order_Status__c from Case where Id =: cs.Id];
        //DCP-29159
        System.assertEquals('Completed' , updatedCase.Work_Order_Status__c);
         
    }
    
    /**
    *  @author Naomi Thammadi
    *  @description - test method for DCP-5623; creation/update of events based on change in schedule
    **/
     static testMethod void workOrderScheduledToCreateEvents(){
        //initializeTestData();
        List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                LIMIT 1];
        Test.startTest();
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        insert acc;

        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        System.assert(serviceTeam.Id != null);
        
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST,serviceTeam.id);
        technician.SVMXC__Email__c=STRING_EMAIL;
        insert technician;
        System.assert(technician.Id != null);
        Case cs = [Select Id from Case limit 1];
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;  
        workOrder.Record_Created_from_SFM__c=true;  
        insert workOrder;
        System.assert(workOrder.Id != null);
        System.assert([Select Id,Work_Order_Status__c from Case where Id =: cs.Id].Work_Order_Status__c != null);          
        Test.stopTest();
    }
    
    /**
    *  @author Ritika Maheshwari
    *  @description - test the work order status on case when a new work order is inserted 
    **/
    static testMethod void workOrderStatusUpdatedToClosedWithInProgressWO(){
        //initializeTestData();
        Case cs = [Select Id from Case limit 1];
        List<SVMXC__Service_Order__c> lstWorkOrderInserted = new List<SVMXC__Service_Order__c>();
        for(integer i=0; i<10; i++){
          SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
          workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
          workOrder.Record_Created_from_SFM__c=true;
            lstWorkOrderInserted.add(workOrder);
        }
        insert lstWorkOrderInserted;
        
        Test.startTest();
        lstWorkOrderInserted[0].SVMXC__Order_Status__c = 'Closed';
        //update lstWorkOrderInserted[0];
        
        Case updatedCase = [Select Work_Order_Status__c from Case where Id =: cs.Id];
        System.assertEquals(updatedCase.Work_Order_Status__c, STRING_WO_STATUS_IN_PROGRESS);
        Test.stopTest();
    }
    
    /**
    *  @author Ritika Maheshwari
    *  @description - test the work order status on case when a new work order is inserted 
    **/
    static testMethod void workOrderStatusUpdatedToClosedWithCompletedWO(){
        //initializeTestData();
        Case cs = [Select Id from Case limit 1];
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        
        Test.startTest();
        workOrder.SVMXC__Order_Status__c = 'Closed';
        //update workOrder;
        
        Case updatedCase = [Select Work_Order_Status__c from Case where Id =: cs.Id];
        System.assertEquals(updatedCase.Work_Order_Status__c, STRING_WO_STATUS_IN_PROGRESS);
        Test.stopTest();
    }
    
    /**
    * DCP-1047, DCP-1053
    *  @author 
    *  @description - test the work order status on case when a new work order is inserted 
    */
    static testMethod void workOrderStatusUpdatedToScheduled() {
     Account acc = [SELECT id FROM Account WHERE Account_Group__c = 'Distributor' AND Name=: STRING_ACCOUNT LIMIT 1];
      Case cs = [SELECT id FROM Case LIMIT 1];
      Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
      objProduct.Product_Group__c = 'AmpliSeq Library Prep';
      insert objProduct;

      SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
      objInstalledProduct.SVMXC__Company__c = acc.Id;
      objInstalledProduct.Operation_Status__c='Off';
      objInstalledProduct.SVMXC__Product__c = objProduct.Id;
      insert objInstalledProduct;

      SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
      workOrder.SVMXC__Component__c = objInstalledProduct.Id;
      workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
      workOrder.SVMXC__Company__c = acc.Id;
      workOrder.Is_Auto_Created__c = true;

      insert workOrder;
      Test.startTest();
      workOrder.SVMXC__Scheduled_Date_Time__c=system.now();
      workOrder.SVMXC__SM_Scheduled_Duration__c=1.2;
      workOrder.SVMXC__Order_Status__c = 'Scheduled'; 
      update workOrder;
      System.assert(workOrder.Id != null);
      Test.stopTest();
    }

    /**
      *  @author Dhairya Shah
      *  @description - CMCM-7910: Method to check product serial number
      **/
    static testMethod void populateSerialNumberWO() {
        Account acc = [SELECT id FROM Account WHERE Account_Group__c = 'Distributor' AND Name=: STRING_ACCOUNT LIMIT 1];
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Product_Group__c = 'AmpliSeq Library Prep';
        insert objProduct;

        SVMXC__Installed_Product__c objInstalledProductLotNumber = TestDataFieldService.createInstalledProductforLotNumber(STRING_INSTALLED_PRODUCT_IP_NAME, 'New',STRING_INSTALLED_PRODUCT_SERIAL_LOT_NUMBER);
        objInstalledProductLotNumber.SVMXC__Company__c = acc.Id;
        objInstalledProductLotNumber.Operation_Status__c='Off';
        objInstalledProductLotNumber.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProductLotNumber;

        Test.startTest();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Component__c = objInstalledProductLotNumber.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;

        SVMXC__Service_Order__c fetchedWO = [SELECT SVMXC__Component__c, Product_Serial_Number__c FROM SVMXC__Service_Order__c WHERE Id = :workOrder.Id];
        
        Test.stopTest();
        System.assertEquals('A01195', fetchedWO.Product_Serial_Number__c, 'The Product Serial Number should be set correctly.');
    }

    static testMethod void workOrderContactUpdate(){        
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
        Bypass_Triggers_By_Object_1__c = 'Case',
        Bypass_Triggers_By_Object_2__c = 'Account',
        Bypass_Triggers_By_Object_3__c = 'Contact',
        Bypass_Triggers_By_Object_4__c = 'SVMXC__Installed_Product__c'
        );
        insert apexSettings;    
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
        Test.startTest(); 
        insert cs1;     
        System.assertNotEquals(null, cs1.Id);
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs1.Id, 'Initiated');
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Contact__c= con.id;
        insert workOrder;
    System.assertNotEquals(null, workOrder.Id);        
        
        try{
            workOrder.SVMXC__Contact__c= con1.id;       
            update workOrder;
        }
        Catch(Exception e){
            system.debug('exception:'+e.getMessage());
            //ApexExceptions.emit('exception',e);
        }
        Test.stopTest();
    System.assertEquals('pqr@xyz.com', 
                            [select id,SVMX_PS_Contact_Email__c from SVMXC__Service_Order__c where id =: workOrder.Id][0].SVMX_PS_Contact_Email__c);
    }
    
    static testmethod void testAutoDispatchPFSE(){
         User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = STRING_USER_EMAIL,
             Username = STRING_USER_EMAIL + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = STRING_TIMEZONE,
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        System.assertNotEquals(null, u.Id);
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail2@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        System.assertNotEquals(null, grpMembers.Id);
             
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assertNotEquals(null, acc.Id);

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
    System.assertNotEquals(null, objProduct.Id);        
        
        List<Account_to_Field_Support__c> lstAccountRoles = new List<Account_to_Field_Support__c>();
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Service Engineer'
        );
        lstAccountRoles.add(accTechRole1);
        Account_to_Field_Support__c accTechRole2 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = SECONDARY_FIELD_SERVICE_ENGINEER
        );
        lstAccountRoles.add(accTechRole2);
        Account_to_Field_Support__c accTechRole3 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Field Service Manager'
        );
        lstAccountRoles.add(accTechRole3);
        insert lstAccountRoles;
        System.assertNotEquals(null, lstAccountRoles[0].Id);

        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = grpMembers.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;
        System.assertNotEquals(null, objExpertise.Id);

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        Test.startTest();
        insert workOrder;
        System.assertNotEquals(null, workOrder.Id);
        //Test.startTest();
        /* */workOrder.Is_Auto_Dispatch__c = true;
        update workOrder;
        Test.stopTest();
        System.assertEquals(userinfo.getUserId(), [select id,Original_Owner__c from SVMXC__Service_Order__c where id =: workOrder.Id][0].Original_Owner__c);
    }

    static testmethod void testAutoDispatchSFSE(){
         User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = STRING_USER_EMAIL,
             Username = STRING_USER_EMAIL + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = STRING_TIMEZONE,
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        System.assertNotEquals(null, u.Id);
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail3@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        System.assertNotEquals(null, grpMembers.Id);
             
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assertNotEquals(null, acc.Id);

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        System.assertNotEquals(null, objProduct.Id);
        
        List<Account_to_Field_Support__c> lstAccountRoles = new List<Account_to_Field_Support__c>();
        Account_to_Field_Support__c accTechRole2 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = SECONDARY_FIELD_SERVICE_ENGINEER
        );
        lstAccountRoles.add(accTechRole2);
        Account_to_Field_Support__c accTechRole3 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Field Service Manager'
        );
        lstAccountRoles.add(accTechRole3);
        insert lstAccountRoles;

        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                        SVMXC__Group_Member__c = grpMembers.Id,
                                                                                        SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;
        System.assertNotEquals(null, objExpertise.id);

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        Test.startTest();
        insert workOrder;
        System.assertNotEquals(null, workOrder.Id);
        //Test.startTest();
        workOrder.Is_Auto_Dispatch__c = true;
        update workOrder;
    Test.stopTest();
        System.assertEquals(userinfo.getUserId(), [select id,Original_Owner__c from SVMXC__Service_Order__c where id =: workOrder.Id][0].Original_Owner__c);
    }

    static testmethod void testAutoDispatchFSM(){
        //CMCM-9 Bug Deployment 101 Error
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
           Bypass_Triggers_By_Object_1__c = 'Case',
           Bypass_Triggers_By_Object_2__c = 'Account',
           Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Order_Line__c',
           Bypass_Triggers_By_Object_4__c = 'SVMXC__Installed_Product__c'
       );
       insert apexSettings;

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
            LastName = 'last',
            Email = STRING_USER_EMAIL,
            Username = STRING_USER_EMAIL + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = STRING_TIMEZONE,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
       );
       insert u;
       System.assertNotEquals(null, u.Id);

       User integrationUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
            LastName = 'Integration',
            Email = STRING_USER_EMAIL,
            Username = STRING_USER_EMAIL + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = STRING_TIMEZONE,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
       );
       insert integrationUser;
       System.assertNotEquals(null, integrationUser.Id);
       SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
           Name = STRING_SERVICE_TEAM_NAME,
           SVMXC__Country__c = 'India'
       );
       insert serviceTeam;
       System.assertNotEquals(null, serviceTeam.Id);
       
       SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
           Name = 'Test Name',
           SVMXC__Active__c = True,
           SVMXC__Email__c = 'testmail1@testing.com',
           SVMXC__Country__c = 'India',
           SVMXC__Street__c = 'Test',
           SVMXC__Salesforce_User__c = u.Id,
           SVMXC__Service_Group__c = serviceTeam.Id
       );
       insert grpMembers;
       System.assertNotEquals(null, grpMembers.Id);
            
       Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
       acc.Account_Group__c='Distributor';
       insert acc;
       System.assertNotEquals(null, acc.Id);

       Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
       insert objProduct;
       System.assertNotEquals(null, objProduct.Id);
       
       List<Account_to_Field_Support__c> lstAccountRoles = new List<Account_to_Field_Support__c>();
       Account_to_Field_Support__c accTechRole3 = new Account_to_Field_Support__c(
           Account__c = acc.Id,
           User__c = grpMembers.Id,
           User_Role__c = 'Field Service Manager'
       );
       lstAccountRoles.add(accTechRole3);
       insert lstAccountRoles;

       Opportunity opp1 = TestDataOpportunity.initOpportunity(acc);
       opp1.Name = 'Test Opp 1';
       opp1.Ultimate_Consignee__c = acc.Id;
       opp1.Current_Ultimate_Consignee__c = acc.Id;
       opp1.OwnerId = u.Id; 
       insert opp1;

       Contact con = TestDataPerson.getNewContact(acc.Id);
       Case cs = TestDataCase.initServiceRequestCase(con);
       insert cs;

       SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                       SVMXC__Group_Member__c = grpMembers.Id,
                                                                                       SVMXC__Service_Group__c = serviceTeam.Id);
       insert objExpertise;
       System.assertNotEquals(null, objExpertise.Id);
        
       List<SVMXC__Service_Order__c> lstWorkOrders = new List<SVMXC__Service_Order__c>();
       SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
       workOrder.SVMXC__Product__c = objProduct.Id;
       workOrder.SVMXC__Case__c = cs.Id;
       workOrder.SVMXC__Order_Type__c = 'Installation';
       workOrder.SVMXC__Company__c = acc.Id;
       workOrder.Is_Auto_Created__c = true;
       workOrder.Is_Auto_Dispatch__c = true;
       workorder.opportunity__c = opp1.Id;
       workorder.Partner_Installation_WO__c = true;
       lstWorkOrders.add(workOrder);

       SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
       wo.SVMXC__Product__c = objProduct.Id;
       wo.SVMXC__Case__c = cs.Id;
       wo.SVMXC__Order_Type__c = 'Installation';
       wo.SVMXC__Company__c = acc.Id;
       wo.Is_Auto_Created__c = true;
       wo.Is_Auto_Dispatch__c = true;
       wo.opportunity__c = opp1.Id;
       wo.Partner_Installation_WO__c = false;

       lstWorkOrders.add(wo);

       SVMXC__Service_Order__c nonDispatchwo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
       nonDispatchwo.SVMXC__Product__c = objProduct.Id;
       nonDispatchwo.SVMXC__Case__c = cs.Id;
       nonDispatchwo.SVMXC__Order_Type__c = 'Installation';
       nonDispatchwo.SVMXC__Company__c = acc.Id;
       nonDispatchwo.Is_Auto_Created__c = true;
       nonDispatchwo.Is_Auto_Dispatch__c = true;
       nonDispatchwo.opportunity__c = opp1.Id;
       nonDispatchwo.Partner_Installation_WO__c = false;

       lstWorkOrders.add(nonDispatchwo);

       SVMXC__Service_Order__c woAutoRejected = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
       woAutoRejected.SVMXC__Product__c = objProduct.Id;
       woAutoRejected.SVMXC__Case__c = cs.Id;
       woAutoRejected.SVMXC__Order_Type__c = 'Installation';
       woAutoRejected.SVMXC__Order_Status__c = 'Initiated';
       woAutoRejected.Reason__c = 'test';
       woAutoRejected.SVMXC__Company__c = acc.Id;
       woAutoRejected.Is_Auto_Created__c = true;
       woAutoRejected.Is_Auto_Dispatch__c = true;
       woAutoRejected.Partner_Installation_WO__c = false;

       lstWorkOrders.add(woAutoRejected);

       SVMXC__Service_Order__c fsWO = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
       fsWO.SVMXC__Product__c = objProduct.Id;
       fsWO.SVMXC__Case__c = cs.Id;
       fsWO.SVMXC__Order_Type__c = 'Service Activities';
       fsWO.SVMXC__Order_Status__c = 'Initiated';
       fsWO.Reason__c = 'test';
       fsWO.SVMXC__Company__c = acc.Id;
       fsWO.Is_Auto_Created__c = true;
       fsWO.Is_Auto_Dispatch__c = false;
       fsWO.Partner_Installation_WO__c = false;

       lstWorkOrders.add(fsWO);
       Test.startTest();
       insert lstWorkOrders;
       System.assertNotEquals(null, workOrder.Id);
       
       //Test.startTest();
       workOrder.Is_Auto_Dispatch__c = true;
       fsWO.Is_Auto_Dispatch__c = true;
       update workOrder;
       update fsWO;
   Test.stopTest();
       System.assertEquals(userinfo.getUserId(), [select id,Original_Owner__c from SVMXC__Service_Order__c where id =: workOrder.Id][0].Original_Owner__c);
  
   }
    
    static testmethod void testAutoDispatchCP(){
         User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = STRING_USER_EMAIL,
             Username = STRING_USER_EMAIL + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = STRING_TIMEZONE,
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        System.assertNotEquals(null, u.Id);
        
        //CP Profile
        Id profileId = [select id from profile where name='Channel Partner Service'].id;

        //CP Account
        Account objAccountCP = TestDataAccount.getAccount('Test Acc23', 'USD');
        objAccountCP.Account_Group__c='Distributor';
        Insert objAccountCP;

        //CP Contact
        Contact objContactCP = TestDataContact.getNewContact(objAccountCP);

        //CP User
        User objCPUser = TestDataUser.initPartnerUser(profileId,objContactCP.id);
        insert objCPUser;
            
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail2@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        System.assertNotEquals(null, grpMembers.Id);
             
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c= 'Distributor';
        insert acc;
        System.assertNotEquals(null, acc.Id);

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
    	System.assertNotEquals(null, objProduct.Id);        
        
        SVMXC__Installed_Product__c installedProduct = new SVMXC__Installed_Product__c();
        installedProduct.SVMXC__Company__c = acc.Id;
        installedProduct.SVMXC__Product__c = objproduct.Id;
        insert installedProduct;
        
        SVMXC__Installed_Product__Share shareIP = new SVMXC__Installed_Product__Share();
        shareIP.ParentId = installedProduct.Id;
        shareIP.UserOrGroupId = objCPUser.Id;
        shareIP.RowCause = Schema.SVMXC__Installed_Product__Share.RowCause.Distributor__c;
        shareIP.AccessLevel = 'Read';
        insert shareIP;
        System.assert(shareIP.Id != null);
        
        List<Account_to_Field_Support__c> lstAccountRoles = new List<Account_to_Field_Support__c>();
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Service Engineer'
        );
        lstAccountRoles.add(accTechRole1);
        Account_to_Field_Support__c accTechRole2 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = SECONDARY_FIELD_SERVICE_ENGINEER
        );
        lstAccountRoles.add(accTechRole2);
        Account_to_Field_Support__c accTechRole3 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Field Service Manager'
        );
        lstAccountRoles.add(accTechRole3);
        insert lstAccountRoles;
        System.assertNotEquals(null, lstAccountRoles[0].Id);

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Component__c = installedProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Preventative Maintenance';
        Test.startTest();
        Database.SaveResult woResult;
        if(objCPUser != null){
            System.runAs(objCPUser){
                woResult = Database.insert(workOrder, false);
        	} 
        }
        Test.stopTest();
        System.assertEquals(false, woResult.isSuccess(), 'Inserting PM WO without Account by CP user should not be successful.');
		System.assertEquals(1, woResult.getErrors().size());
	}
    
     /**
    * DCP-1026
    *  @author : Sandeep Ram Ch.
    *  @description -test method to validate work order creation
    **/
    static testMethod void validateManualCreationOfNewWorkOrder(){
                //initializeTestData();

                SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
                objInstalledProduct.Operation_Status__c='Off';
                insert objInstalledProduct;
                Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
                insert objProduct;
                Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
                insert objAccount;
                Contact con = TestDataPerson.getNewContact(null);
                SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
                insert objLocation;
                Case cs = TestDataCase.initServiceRequestCase(con);
                cs.SVMXC__Site__c = objLocation.id;
                //insert cs;
                Contact con1 = TestDataPerson.getNewContact(null);
                Case cs1 = TestDataCase.initServiceRequestCase(con1);
                cs1.SVMXC__Site__c = objLocation.id;
                //insert cs1;
                List<Case> lstCase = new List<Case>{cs,cs1};
        insert lstCase;
                List<SVMXC__Service_Order__c> lstWo= new List<SVMXC__Service_Order__c>();
                SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
                objWorkOrder.SVMXC__Product__c=objProduct.id;
                objWorkOrder.Is_Auto_Dispatch__c = True;
                objWorkOrder.SVMXC__Company__c = objAccount.Id;
                objWorkOrder.Partner_Installation_WO__c = False;
                objWorkOrder.ProActive_Account_ERP_Customer_Id__c = 'Test1';
                objWorkOrder.SVMXC__Order_Type__c='Installation';
                objWorkOrder.ERP_Order_Number__c='1234567';
                objWorkOrder.ERP_Order_Line_Number__c='1234567_001';
                objWorkOrder.ERP_Order_Line_Quantity__c=1;
                objWorkOrder.Is_Auto_Created__c = true;
                objWorkOrder.Record_Created_from_SFM__c = false;
                objWorkOrder.SVMXC__Case__c = cs.Id;
                //insert objWorkOrder;
                lstWo.add(objWorkOrder);
               
               SVMXC__Service_Order__c objWorkOrderTwo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
                objWorkOrderTwo.SVMXC__Product__c=objProduct.id;
                objWorkOrderTwo.SVMXC__Company__c = objAccount.Id;
                objWorkOrderTwo.Is_Auto_Dispatch__c = True;
                objWorkOrderTwo.Partner_Installation_WO__c = true;
                objWorkOrderTwo.SVMXC__Order_Type__c='Installation';
                objWorkOrderTwo.SVMXC__Component__c = objInstalledProduct.Id;
                objWorkOrderTwo.ERP_Order_Number__c='2345678';
                objWorkOrderTwo.ERP_Order_Line_Number__c='2345678_001';
                objWorkOrderTwo.ERP_Order_Line_Quantity__c=1;
                objWorkOrderTwo.Is_Auto_Created__c = true;
        
                Test.startTest();
               lstWo.add(objWorkOrderTwo);
               try{
                   insert lstWo;
                   System.assert(lstWo[0].Id != null);
                   objWorkOrder.SVMXC__Case__c = cs1.Id;
                   update lstWo;
                   System.assert([Select Id,Work_Order_Status__c from Case where Id = : cs1.Id].Work_Order_Status__c != null);
               }
               catch(Exception e){
                   Boolean expectedExceptionThrown =  e.getMessage().contains('Work order cannot be created as there already exists an install work order for selected product, ERP Order Number and ERP Order Line Number.') ? true : false;
                  // System.AssertEquals(expectedExceptionThrown, true);
               }                   
        Test.stopTest();
    }
    
    
    
     /**
    * DCP-1050
    *  @author : Sandeep Ram Ch.
    *  @description - test the work order Field Support field on when a work order is Updated 
    **/
    static testMethod void workOrderFieldSupportUpdateToLoggedInUser(){
        //initializeTestData();
        TestDataFieldService.createUser('System Administrator',true);
        List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name = 'System Administrator'
                                AND IsActive = TRUE
                                LIMIT 1]; 
        Test.startTest();
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0]){
                SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
                insert serviceTeam;
                
                SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
                insert technician;
                Case cs = [Select Id from Case limit 1];
                SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
                workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
                workOrder.Record_Created_from_SFM__c=true;
                insert workOrder;
                workOrder.SVMXC__Order_Status__c = 'Assignment Accepted' ;
                update workOrder;
                SVMXC__Service_Order__c wo =[select id,SVMXC__Group_Member__c,ownerid from SVMXC__Service_Order__c where id= : workOrder.id];
                System.assertEquals(wo.ownerid,UserInfo.getUserId());
            }
        }                      
        Test.stopTest();
    }
    
    static testmethod void newWorkOrderCreationForEntitlement() {
        
        Test.startTest();

        // Insert Account
        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;

        //insert objInstalledProduct;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
        SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
        System.assertEquals('New',insertedInstalledProduct.SVMXC__Status__c);

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;
        
        SVMXC__Service_Contract__c objServiceContract= TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;
         
        // Insert Covered Product
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id );
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;        
        SVMXC__Service_Contract_Products__c insertedCoveredProduct = [Select SVMXC__Installed_Product__c from SVMXC__Service_Contract_Products__c where SVMXC__Installed_Product__c =: objInstalledProduct.Id];
        System.assertEquals(insertedCoveredProduct.SVMXC__Installed_Product__c, objInstalledProduct.Id);
        
        //insert covered location
        SVMXC__Service_Contract_Sites__c objCoveredLocation = TestDataFieldService.createCoveredLocation(null);
        objCoveredLocation.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredLocation;
        
        //insert Contact
        Contact objContact = TestDataPerson.getNewContact(objAccount.Id);            
        Contact insertedContact = [Select AccountId from Contact where Id =: objContact.Id];
        System.assertEquals(insertedContact.AccountId , objAccount.Id);

        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', objContact.Id);
        // Insert Work Order
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        objWorkOrder.SVMXC__Company__c=objAccount.Id;
        objWorkOrder.SVMXC__Component__c = objInstalledProduct.Id;
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        objWorkOrder.SVMXC__Case__c = objCase.Id;
        objWorkOrder.Record_Created_from_SFM__c=true;
        insert objWorkOrder;
        SVMXC__Service_Order__c insertedWorkOrder = [Select SVMXC__Order_Status__c from SVMXC__Service_Order__c where Id =: objWorkOrder.Id];
        System.assertEquals('Initiated',insertedWorkOrder.SVMXC__Order_Status__c);
         Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.CurrencyIsoCode='USD';
        objEntitlement.Work_Order__c =objWorkOrder.id;
        //insert objEntitlement;         
        List<SVMXC__Service_Contract_Products__c> lstCP = [Select Id,SVMXC__Service_Contract__c,SVMXC__Service_Contract__r.Name,SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c,SVMXC__Service_Contract__r.SVMXC__Service_Level__c,SVMXC__Service_Contract__r.SVMXC__End_Date__c,SVMXC__Installed_Product__c from SVMXC__Service_Contract_Products__c limit 10];
        List<SVMXC__Service_Contract_Sites__c> lstCL = [Select Id,SVMXC__Service_Contract__c,SVMXC__Service_Contract__r.Name,SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c,SVMXC__Service_Contract__r.SVMXC__Service_Level__c,SVMXC__Service_Contract__r.SVMXC__End_Date__c,SVMXC__Site__c from SVMXC__Service_Contract_Sites__c limit 10];
        AutoPopulateWOField_WOHelper.getEntitlementsForWO(lstCP, lstCL);
        AutoPopulateWOField_WOHelper.getEntitlementsForERPWO(lstCP, lstCL);
        Test.stopTest();
    }
    /**
    * DCP-8174
    *  @author : Shashank Singhal
    *  @description - test the creation of related products 
    **/
    static testMethod void checkShowOnCase()
    {
        Contact con = TestDataPerson.getNewContact(null);
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        Test.startTest();
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        wo.SVMXC__Order_Type__c='Relocation';
        wo.Customer_Requested_Not_To_Re_Install__c=true;
        wo.Record_Created_from_SFM__c=true;
        insert wo;
         System.assert(wo!=null,'wo is null');
        Case cs1 = [Select Id, AP_Installed_Product__c from Case where Id = :cs.Id limit 1];
        //system.assertEquals(ip.Id, cs1.AP_Installed_Product__c);
        Test.stopTest();
    }
     /**
    * DCP-843
    *  @author : Shashank Singhal
    *  @description - test the Document signed when status is completed 
    **/
    
    static testMethod void checkLOADocumentSigned()
    {
        Contact con = TestDataPerson.getNewContact(null);
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != null);
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        wo.SVMXC__Order_Type__c='Installation';
        wo.Acceptance_Code__c = 'ACD: Acceptance Upon Delivery';
        wo.Is_Auto_Created__c = true;
        insert wo;
        System.assert(wo.Id != null);
        wo.SVMXC__Order_Status__c = 'Completed';
        wo.No_Calibrated_Tools_Used__c = true;
        try{
            update wo;
            System.assert([Select Id,Work_Order_Status__c from Case where Id =: cs.Id].Work_Order_Status__c != null);
        }catch(exception ex){
            system.debug(ex.getMessage());
        }
        
        
    }
     /**
    * DCP-11867
    *  @author : Soumya Ranjan Sahu
    *  @description - test the Document signed when status is completed 
    **/
    static testMethod void checkLOASignedandSent()
    {
        Contact con = TestDataPerson.getNewContact(null);
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != null);
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        wo.SVMXC__Order_Type__c='Installation';
        wo.Is_Auto_Created__c = true;
        wo.LOA_Signed_and_Attached__c=false;
        wo.Signature_Type__c='Mobile Sign';
        wo.Customer_Representative__c = con.id;
        insert wo;
        Attachment objAttachment = TestDataFieldService.createAttachment(wo.id,'Letter_of_Acceptance');
        insert objAttachment;
        wo.LOA_Signed_and_Attached__c=true;
        update wo;
        System.assert([select Id,Work_Order_Status__c from case where Id=: cs.Id].Work_Order_Status__c != null);
    }

    
    /**
    * DCP-17424
    *  @author : Mandeep Singh
    *  @description - Test Onsite Respose Due Date Value
    **/
    static testMethod void testOnsiteResponseDueDate()
    {
        User testUser = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=TRUE LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(testUser.id,STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST,serviceTeam.id);
        technician.SVMXC__Email__c=STRING_EMAIL;
        insert technician;
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c();
        System.runAs(testUser) {
        //Contact con = TestDataPerson.getNewContact(null);
        Case cs = TestDataCase.initNewCase(BUSINESS_ISSUE, 'Initiated', 'Email-TS');
        insert cs;  
        Test.startTest();
        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        List<SVMXC__Service_Level__c> objServiceLevels = new List<SVMXC__Service_Level__c> ();
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        objServiceLevel.Least_SLA__c = 2880;
        objServiceLevels.add(objServiceLevel);
        SVMXC__Service_Level__c objServiceLevel2 = TestDataFieldService.createServiceLevel();
        objServiceLevel2.SVMXC__Business_Hours__c = objBuinessHours.id;
        objServiceLevel2.Least_SLA__c = 4320;
        objServiceLevels.add(objServiceLevel2);
        insert objServiceLevels;
        workOrder = [select id,Onsite_Response_Due_Date__c, SVMXC__SM_SLA_Onsite_Response__c,
                                             SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                             SVMXC__Order_Status__c from 
                                             SVMXC__Service_Order__c where SVMXC__Case__c =: cs.Id Limit 1];
        System.debug('The order type is '+workOrder);
        workOrder.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(STRING_WO_RECORDTYPE).getRecordTypeId(); 
        workOrder.SVMXC__Order_Type__c = STRING_WO_ORDER_TYPE;
        // workOrder.Onsite_Response_Due_Date__c = NULL;
        workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test';        
        workOrder.Record_Created_from_SFM__c = true;
        workOrder.SVMXC__Group_Member__c = technician.Id;
        workOrder.SVMXC__Order_Status__c = 'Assigned';
        workOrder.SVMXC__SLA_Terms__c = objServiceLevel.id;
        workOrder.OwnerId = testUser.id;
        update workOrder;
        }

        
        Profile fsProfile = [SELECT Id FROM Profile WHERE Name =: System.label.Field_Service Limit 1];
        User u = new User(
         ProfileId = fsProfile.Id,
         LastName = 'Last Name',
         Email = STRING_USER_EMAIL,
         Username = STRING_USER_EMAIL + System.currentTimeMillis(),
         CompanyName = 'TEST',
         Title = 'title',
         Alias = 'alias',
         TimeZoneSidKey = STRING_TIMEZONE,
         EmailEncodingKey = 'UTF-8',
         LanguageLocaleKey = 'en_US',
         LocaleSidKey = 'en_US'
         );
         insert u;
         User testUser2 = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND LastName = 'Last Name' AND IsActive=TRUE LIMIT 1];
         SVMXC__Service_Level__c objSrvcLevel2 = [Select Id, Least_SLA__c From SVMXC__Service_Level__c Where Least_SLA__c = 4320 Limit 1];
         SVMXC__Service_Order__c workOrderToUpdate2 = [select id, Onsite_Response_Due_Date__c, SVMXC__SLA_Terms__c, OwnerId, SVMXC__Order_Status__c from SVMXC__Service_Order__c where Id = :workOrder.Id Limit 1];
         workOrderToUpdate2.OwnerId = testUser2.id;
         update workOrderToUpdate2;
         workOrderToUpdate2.SVMXC__Order_Status__c = 'Technician Onsite';
         workOrderToUpdate2.SVMXC__SLA_Terms__c = objSrvcLevel2.id;
         update workOrderToUpdate2;
         system.assert(workOrderToUpdate2.Id != null);
         Test.stopTest(); 
    }
            
     Static testMethod void testCPWOCreation(){
    
          Id profileId = [select id from profile where name='Channel Partner Sales and Service'].id;
       
        Account ac =TestDataAccount.initAccount();
        ac.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
         insert ac;
        Contact con =TestDataContact.getNewContact(ac);
       // insert con;  
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;          
        User user = new User(alias = uniqueName.substring(18, 23), email=uniqueName + '@test' + orgId + '.org',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profileId , country='USA',IsActive =true,PortalRole = 'Manager',
                ContactId = con.Id,
                timezonesidkey=STRING_TIMEZONE, username=uniqueName + '@test' + orgId + '.org');
       
        insert user;
        
          Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
        
        Case objCase  = new Case(
            
            Status = 'Initiated',
            Subject = dateString ,
            Description= dateString,
            Origin = 'Phone-CP',
            Date_of_Issue_Awareness__c=System.today() -2,
            Awareness_Date_Difference_Reason__c = 'Logistical delay',
            ContactId = con.Id,
            RecordTypeId = idCaseRecordTypeId
        );
        //System.runAs(user){
        Test.startTest();
        insert objCase  ;
        System.assert(objCase.id != null);
        // Insert Work Order
        SVMXC__Service_Order__c objWorkOrder  = [Select id,OwnerID from SVMXC__Service_Order__c where SVMXC__Case__c=: objCase.Id];
        System.assert(objWorkOrder.Id !=null);
        objWorkOrder.ownerID=user.id;
        update objWorkOrder;
        Test.stopTest();
        //}
        
      }
    
    /**
    * DCP-24619
    *  @author : Nitin Sood
    *  @description - Test contact/account validations and auto assingments
    **/    
    static testMethod void testContactAccountValidations(){
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = STRING_USER_EMAIL,
             Username = STRING_USER_EMAIL + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = STRING_TIMEZONE,
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;

        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
    
        Account acc1 = TestDataAccount.getAccount('Test Acc1', 'USD');
        acc1.Account_Group__c='Distributor';
        insert acc1;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        insert objInstalledProduct;

        Contact con  = TestDataPerson.getNewContact(acc.Id);
    
        Contact con1  = TestDataPerson.getNewContact(acc1.Id);

      Test.startTest();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrderWithoutCase('Estimates', 'Initiated', STRING_WO_RECORDTYPE);
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Contact__c= con1.id;
        workOrder.SVMXC__Contact__c= con.id;    
    //insert workOrder;

        workOrder.SVMXC__Component__c = null;  
        workOrder.SVMXC__Contact__c= con1.id;
    System.runAs(u){
      try{
          
        update workOrder;  
      }
      Catch(Exception e){  
         system.debug('exception:'+e.getMessage());
         ApexExceptions.emit('exception',e);
      }
    }
        workOrder.SVMXC__Contact__c= con.id;    
        update workOrder;

        workOrder.SVMXC__Component__c = null;  
        workOrder.SVMXC__Company__c = null;  
    update workOrder;
    Test.stopTest();
    SVMXC__Service_Order__c objWorkorder = [SELECT SVMXC__Company__c FROM SVMXC__Service_Order__c where Id =: workOrder.Id];
    System.assertEquals(objWorkorder.SVMXC__Company__c, acc.id);
  }
  
  
    /**
    *  @author Naomi Thammadi
    *  @description - test the refactoring process of work flows
    **/
    static testMethod void testWorkFlows(){
        //initializeTestData();
        Case cs = [Select Id from Case limit 1];          
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        System.assert(workOrder.Id != null,'workorder id is null');
        Test.startTest();
        workOrder.SVMXC__Order_Status__c = System.Label.WorkOrderStatusTechnicianOnsite;
        workOrder.SVMXC__Order_Type__c = System.Label.WorkOrderTypeServiceActivities;
        workOrder.First_Time_Fix_Count__c=null;
        workOrder.SVMXC__Billing_Type__c = 'Billable';
        update workOrder;
        
    }
  
  
  //start of DCP-25289 - new test method
    static testMethod void testWorkOrderCompletionWithIQWD(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
           Bypass_Triggers_By_Object_1__c = 'Case',
           Bypass_Triggers_By_Object_2__c = 'Associated_Product__c',
           Bypass_Triggers_By_Object_3__c = 'SVMXC__Service_Order_Line__c',
           Bypass_Triggers_By_Object_4__c = 'SVMXC__Installed_Product__c'
       );
       insert apexSettings;
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        
        Product2 objProduct = new Product2(
            Name = 'Test Product VM', 
            Service_Product_Type__c = 'Consumable',
            Material_Class__c = 'Consumables');
        insert objProduct;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.Acceptance_Date__c= Date.Today();
        objInstalledProduct.SVMXC__Date_Installed__c= Date.Today();
        objInstalledProduct.Operation_Status__c = 'On';
        objInstalledProduct.SVMXC__Status__c = 'Awaiting Installation';
        insert objInstalledProduct;
        Test.startTest();
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        objCase.Has_Resolution_Code__c = true;
        insert objCase;
        System.assert(objCase.Id != null);

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        insert workOrder;
        //Test.startTest();
        List<SVMXC__Service_Order_Line__c> lstWorkDetails = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Activity_Type__c ='IQ/OQ';
        //objOrderDetail.SVMXC__Line_Status__c='Open';
        lstWorkDetails.add(objOrderDetail);     

        //DCP-33657 to Bypass validation rule :CheckTraineeWorkDetails
        SVMXC__Service_Order_Line__c objOrderDetail1 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail1.SVMXC__Activity_Type__c ='Training';
        lstWorkDetails.add(objOrderDetail1);
        insert lstWorkDetails;
        Test.stopTest();
        workOrder.SVMXC__Order_Status__c = 'Assigned';
        workOrder.No_Calibrated_Tools_Used__c = true;
        workOrder.Is_Service_Report_Generated__c =true;
        workOrder.Evaluation__c ='test';
        workOrder.SVMXC__Work_Performed__c ='test';
        workOrder.Verification_Result__c ='test';
        workOrder.Has_Verification_Code__c =true;
        workOrder.PO_Number__c ='127845';
        workOrder.Signature_Type__c='Manual Sign';
        workOrder.Manual_Sign_Captured__c=true;
        workOrder.Is_Customer_Sign_Captured__c=true;
        workOrder.Cost_Center__c=6776;
        update workOrder;
        List<SVMXC__Service_Order_Line__c> lstWDs=new List<SVMXC__Service_Order_Line__c>();
        lstWDs=[select id, SVMXC__Service_Order__c from SVMXC__Service_Order_Line__c where SVMXC__Activity_Type__c='Qualification Service Review' AND SVMXC__Service_Order__c=:workOrder.id];
        //System.assertNotEquals(lstWDs.size(), 0);
  
  }

    /**
     * Method Name: updateIsBillabeOnWorkDetailsTest
     * Description: To test updateIsBillabeOnWorkDetails functionality
     * Params: NA
     * Return: NA
     * */
     static testmethod void updateIsBillabeOnWorkDetailsTest(){
        //insert account
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
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
        
        //insert work order
        List<SVMXC__Service_Order__c> lstWOrkOrder = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        lstWOrkOrder.add(workOrder);
        
        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder1.SVMXC__Order_Type__c='Installation';
        workOrder1.Is_Auto_Created__c = true;
        lstWOrkOrder.add(workOrder1);

        SVMXC__Service_Order__c workOrder2 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder2.SVMXC__Order_Type__c='Installation';
        workOrder2.Is_Auto_Created__c = true;
        lstWOrkOrder.add(workOrder2);
        
        insert lstWOrkOrder;
        
        System.assert(lstWOrkOrder[0].Id != null);
        
        //insert product
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        Test.startTest();
        insert toolProduct2;
        System.assert(toolProduct2.Id != null);
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc; //Insert DCP-33467

        //Insert Product Stock DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;
        //insert work details
        List<SVMXC__Service_Order_Line__c> lstWorkDetails = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c workDetail = new SVMXC__Service_Order_Line__c();
        workDetail.SVMXC__Service_Order__c = workOrder.id;
        workDetail.SVMXC__Activity_Type__c = 'PQ';
        workDetail.SVMXC__Line_Type__c='Tools';
        workDetail.SVMXC__Product__c = toolProduct2.Id;
        workDetail.SVMXC__Is_Billable__c = false;
        lstWorkDetails.add(workDetail);

        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = workOrder1.id;
        workDetail1.SVMXC__Line_Type__c='Parts';
        workDetail1.SVMXC__Product__c = toolProduct2.Id;
        workDetail1.SVMXC__Is_Billable__c = false;
        workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467                        
        lstWorkDetails.add(workDetail1);
        
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c();
        workDetail2.SVMXC__Service_Order__c = workOrder2.id;
        workDetail2.SVMXC__Line_Type__c='Labour';
        workDetail2.SVMXC__Product__c = toolProduct2.Id;
        workDetail2.SVMXC__Is_Billable__c = false;
        lstWorkDetails.add(workDetail2);
        
        SVMXC__Service_Order_Line__c workDetail3 = new SVMXC__Service_Order_Line__c();
        workDetail3.SVMXC__Service_Order__c = workOrder2.id;
        workDetail3.SVMXC__Product__c = toolProduct2.Id;
        lstWorkDetails.add(workDetail3);
        
        insert lstWorkDetails;
        System.assert(lstWorkDetails[0].Id != null);
        
        //Test.startTest();
        
        lstWorkDetails[0].SVMXC__Is_Billable__c = false;
        lstWorkDetails[1].SVMXC__Is_Billable__c = false;
        lstWorkDetails[2].SVMXC__Is_Billable__c = false;
        lstWorkDetails[3].SVMXC__Is_Billable__c = false;
        update lstWorkDetails;
        
        //insert service contract
        List<SVMXC__Service_Contract__c> lstServiceContracts = new List<SVMXC__Service_Contract__c>();
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = 'Active';
        objServiceContract.Parts_Included__c = True;
        lstServiceContracts.add(objServiceContract);

        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract1.Consumables_Included__c=false;
        objServiceContract1.Status__c = 'Active';
        objServiceContract1.Labor_Included__c = True;
        lstServiceContracts.add(objServiceContract1);
        insert lstServiceContracts;
        System.assert(lstServiceContracts[0].Id != null);
        
        //insert applied contracts
        List<Applied_Contract__c> lstEntitlements = new List<Applied_Contract__c>();
        Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.CurrencyIsoCode='USD';
        objEntitlement.Work_Order__c = workOrder1.id;
        objEntitlement.Service_Contract__c = objServiceContract.Id;
        lstEntitlements.add(objEntitlement);
        
        Applied_Contract__c objEntitlement1 = new Applied_Contract__c();
        objEntitlement1.CurrencyIsoCode='USD';
        objEntitlement1.Work_Order__c = workOrder2.id;
        objEntitlement1.Service_Contract__c = objServiceContract1.Id;
        lstEntitlements.add(objEntitlement1);
        insert lstEntitlements;
        System.assert(lstEntitlements[0].Id != null);
        
        Map<Id,SVMXC__Service_Order__c> mapIdToWorkOrder = new Map<Id,SVMXC__Service_Order__c> {workOrder.Id => workOrder,workOrder1.Id => workOrder1,workOrder2.Id => workOrder2};
        UpdateWDQueueable_WOHelper.updateIsBillabeOnWorkDetails(mapIdToWorkOrder.Keyset());
        SVMXC__Service_Order_Line__c wd = [Select Id,SVMXC__Is_Billable__c from SVMXC__Service_Order_Line__c where Id =:workDetail.Id];
        System.assert(!wd.SVMXC__Is_Billable__c , 'Is Billable made true for work order');
        Test.stopTest();
     }

     /**
      * Method:populateFieldSupportAndOwnerFromLocationTest
      * Description: Test populateFieldSupportAndOwnerFromLocation method in workorder
      * return:NA
      * params:NA
      * */
      static testMethod void populateFieldSupportAndOwnerFromLocationTest(){
            cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'Account',
            Bypass_Triggers_By_Object_3__c = 'Contact'
            );
            insert apexSettings; 
             //insert acc
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
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
            workOrder2.SVMXC__Order_Type__c='Installation';
            workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
            workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
            workOrder2.Partner_Installation_WO__c = true;
            workOrder2.SVMXC__Site__c = objLocation1.Id;
            lstWorkOrder.add(workOrder2);
            
            SVMXC__Service_Order__c workOrder3 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Assigned');
            workOrder3.SVMXC__Company__c=acc.id;
            workOrder3.Is_Auto_Created__c = true;
            workOrder3.ProActive_Account_ERP_Customer_Id__c = 'Test2';
            workOrder3.SVMXC__Site__c = objLocation1.Id;
            lstWorkOrder.add(workOrder3);
            
            System.runAs(sapUsr){
                //Test.startTest();
                insert lstWorkOrder;
                Test.startTest();
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
                //WorkOrders controller = new WorkOrders(lstWorkOrder);
                //controller.populateFieldSupportAndOwnerFromLocation(new Set<Id>{objLocation.Id,objLocation1.Id}, new Map<Id,Id> {workOrder.Id => objLocation.id, workOrder1.Id => objLocation1.id});
                FieldStockFSOwner_WOHelper.populateFieldSupportAndOwnerFromLocation(lstWorkOrder);
                //controller.populateOnsiteResponseTime(new List<SVMXC__Service_Order__c> {lstWorkOrder[0],lstWorkOrder[2],lstWorkOrder[3]});
                List<SVMXC__Service_Order__c> lstWO = [Select Id,OwnerId from SVMXC__Service_Order__c where Id =: lstWorkOrder[0].Id];
                System.assert(lstWO[0].OwnerId == sapUsr.Id);
                //Test.stoptest();
            }
      }
    


    //for 25229
    Static testMethod void testcloseduplicateWO(){
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        Account objAccount =TestDataAccount.initAccount();
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;
        Contact con =TestDataContact.getNewContact(objAccount);
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
        
        Case objCaseRecord  = new Case(
            Subject = 'Test subject' ,
            Description= 'Test description',
            Origin = 'Phone-CP',
            Status = 'Initiated',
            Date_of_Issue_Awareness__c=System.today() -2,
            Awareness_Date_Difference_Reason__c = 'Logistical delay',
            ContactId = con.Id,
            RecordTypeId = idCaseRecordTypeId,
            Has_Closed_Duplicate_WO__c = false
        );
        Test.StartTest();
        Cases.skipCaseTrigger = true;
        insert objCaseRecord;
        
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        WorkOrders.skipWOTrigger = true;
        INSERT wo;
        
        SVMXC__Service_Order_Line__c wd = new SVMXC__Service_Order_Line__c();
        wd.SVMXC__Service_Order__c = wo.id;
        wd.SVMXC__Activity_Type__c = 'Repair/Troubleshooting';
        wd.Duration_in_hours__c = '1';
        wd.SVMXC__Line_Type__c = WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR;
        insert wd;

        wo.SVMXC__Order_Status__c = 'Closed-Duplicate';
        try{
           update wo; 
           System.assert(wo.Id != null, 'Work Order insertion failed');
           System.assert([Select Id,Work_Order_Status__c from Case where Id = : objCaseRecord.Id].Work_Order_Status__c != null, 'Work Order Status not updated');
        }catch(exception e){
            system.debug('exception:'+e.getMessage());
            ApexExceptions.emit('exception',e);
        }

        Test.StopTest();
    }



        
  
 /**
    *  @author Ritika Maheshwari
    *  @description - test the work order completed date population
    **/
    static testMethod void workOrderCompleteDatePopulation(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case'
        );
        INSERT apexSettings;
    
        Case cs = [SELECT id FROM Case LIMIT 1];
        cs.Has_Resolution_Code__c = true;
        UPDATE cs;
    
        Id woRecordTypeId = ServiceUtilityCollection.getRecordTypeId(WorkOrders.STRING_WORK_ORDER_API_NAME, WorkOrders.STRING_WORK_ORDER_RTYPE_REMOTE_SUPPORT);
    
        // Insert test work orders
        List<SVMXC__Service_Order__c> lstWorkOrderInserted = new List<SVMXC__Service_Order__c>();
        for (integer i = 0; i < 10; i++) {
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(WorkOrders.STRING_WORK_ORDER_RTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c = STRING_WO_ORDER_TYPE;
            workOrder.Is_Service_Report_Generated__c = true;
            workOrder.Record_Created_from_SFM__c = true;
            workOrder.Evaluation__c = 'Test';
            workOrder.SVMXC__Work_Performed__c = 'Test';
            workOrder.Verification_Result__c = 'Test';
            workOrder.RecordTypeId = woRecordTypeId; // Ensure the correct record type
            lstWorkOrderInserted.add(workOrder);
        }
        INSERT lstWorkOrderInserted;
    
        Test.startTest();
        
        // Update the work order status to Completed and set completed date/time
        lstWorkOrderInserted[0].PO_Number__c = '12';
        lstWorkOrderInserted[0].SVMXC__Order_Status__c = 'Completed';
        lstWorkOrderInserted[0].No_Calibrated_Tools_Used__c = true;
        lstWorkOrderInserted[0].SVMXC__Completed_Date_Time__c = DateTime.now();
        UPDATE lstWorkOrderInserted[0];
    
        // Change the status to Assigned and ensure the conditions in your logic are met
        lstWorkOrderInserted[0].SVMXC__Order_Status__c = 'Assigned';
        lstWorkOrderInserted[0].Service_Report_Generation__c = true;
        lstWorkOrderInserted[0].PO_Number__c = '12';
        
        Test.stopTest();
        WorkOrders.skipWOTrigger = false;
        UPDATE lstWorkOrderInserted[0];
        
        SVMXC__Service_Order__c workOrderUpdatedLatest = [SELECT id, SVMXC__Completed_Date_Time__c FROM SVMXC__Service_Order__c WHERE id = :lstWorkOrderInserted[0].Id];
        System.assertEquals(null, workOrderUpdatedLatest.SVMXC__Completed_Date_Time__c, 'Completed Date/Time should be cleared after status change to Assigned');
    }    
    /*Test Data*/
    public static testmethod void testRemoteSupportEntitlements(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c');
        insert apexSettings; 
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert objInstalledProduct;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        insert objInstalledProduct;
        SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
        System.assertEquals('New',insertedInstalledProduct.SVMXC__Status__c);
        
        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel(); 
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;
        
        SVMXC__Service_Contract__c objServiceContract= TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;
        
        // Insert Covered Product
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id );
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;        
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.SVMXC__Component__c = objInstalledProduct.Id;
        Test.startTest();
        insert cs;
        System.assert(cs.Id != null);
        
        //insert work order
        List<SVMXC__Service_Order__c> lstWOrkOrder = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.Record_Created_from_SFM__c = true;
        lstWOrkOrder.add(workOrder);
        
        try{
        insert lstWOrkOrder;
        }
        catch(Exception ee){
            System.assert(ee.getMessage().contains('Remote Support Work Order cannot be created as no Service Contract exists for the Installed Product or Location with Remote Support Coverage'));
        }      
        Test.stopTest();    
        
        
    }
    /*Test Data*/
    public static testmethod void testSendEmailNotifications1(){
        Account acc = [select id from account where name =: STRING_ACCOUNT];
        SVMXC__Service_Group_Members__c grpMembers = [select id from SVMXC__Service_Group_Members__c where name =: 'Test Name' limit 1];
        //Case cs = [select id from case where AccountId =: acc.Id limit 1];
        
        List<Account_to_Field_Support__c> lstAccountRoles = new List<Account_to_Field_Support__c>();
        
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Service Engineer');
        lstAccountRoles.add(accTechRole1);
        
        Account_to_Field_Support__c accTechRole2 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = SECONDARY_FIELD_SERVICE_ENGINEER
        );
        lstAccountRoles.add(accTechRole2);
        
        Account_to_Field_Support__c accTechRole3 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Field Service Manager'
        );
        lstAccountRoles.add(accTechRole3);
        Test.startTest();
        insert lstAccountRoles;
        System.assertNotEquals(null, lstAccountRoles[0].Id);
        Test.stopTest();
     }
         /*Test Data*/
    public static testmethod void testSendEmailNotifications2(){
        Account acc = [select id from account where name =: STRING_ACCOUNT];
        //SVMXC__Service_Group_Members__c grpMembers = [select id from SVMXC__Service_Group_Members__c where name =: 'Test Name' limit 1];
        Case cs = [select id from case where AccountId =: acc.Id limit 1];
        List<SVMXC__Service_Order__c> lstWorkOrder = new List<SVMXC__Service_Order__c>();       
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(FIELD_STOCK_MANAGEMENT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c = 'Installation';
        workOrder.SVMXC__Company__c=acc.id;
        workOrder.Is_Auto_Created__c = true;
        workOrder.ProActive_Account_ERP_Customer_Id__c = 'Test1';
        workOrder.SVMXC__SM_SLA_Initial_Response__c = 2880;
        lstWorkOrder.add(workOrder);
        
        SVMXC__Service_Order__c workOrder1= TestDataFieldService.createWorkOrder(FIELD_STOCK_MANAGEMENT, cs.Id, 'Initiated');
        workOrder1.SVMXC__Order_Type__c='Installation';
        workOrder1.SVMXC__Company__c=acc.id;
        workOrder1.Is_Auto_Created__c = true;
        workOrder1.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        //workOrder1.SVMXC__Site__c = objLocation.Id;
        lstWorkOrder.add(workOrder1);
        
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
        //workOrder2.SVMXC__Site__c = objLocation.Id;
        workOrder2.Field_Support_User_Role__c = 'Primary Field Service Engineer';
        lstWorkOrder.add(workOrder2);
        
        SVMXC__Service_Order__c workOrder3 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Assigned');
        workOrder3.SVMXC__Company__c=acc.id;
        workOrder3.Is_Auto_Created__c = true;
        workOrder3.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        //workOrder3.SVMXC__Site__c = objLocation.Id;
        lstWorkOrder.add(workOrder3);
        
        SVMXC__Service_Order__c workOrder4= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
        workOrder4.SVMXC__Company__c=acc.id;
        workOrder4.Is_Auto_Created__c = true;
        workOrder4.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder4.SVMXC__SM_SLA_Initial_Response__c = 7200;
        //workOrder4.SVMXC__Site__c = objLocation.Id;
        workOrder4.Field_Support_User_Role__c = SECONDARY_FIELD_SERVICE_ENGINEER;
        lstWorkOrder.add(workOrder4);
        
        SVMXC__Service_Order__c workOrder5= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Assigned');
        workOrder5.SVMXC__Company__c=acc.id;
        workOrder5.Is_Auto_Created__c = true;
        workOrder5.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder5.SVMXC__SM_SLA_Initial_Response__c = 7200;
        //workOrder5.SVMXC__Site__c = objLocation.Id;
        workOrder5.Field_Support_User_Role__c = 'Field Service Manager';
        lstWorkOrder.add(workOrder5);
        
        insert lstWorkOrder;
        Test.startTest();
        lstWorkOrder[2].SVMXC__Order_Status__c = 'Initiated';
        lstWorkOrder[2].Is_Auto_Dispatch__c = true;
        lstWorkOrder[2].SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        lstWorkOrder[2].Reason__c = 'Testing';
        lstWorkOrder[2].SVMXC__SM_SLA_Initial_Response__c = 7200;
        lstWorkOrder[2].Send_to_ERP__c = True;
        
        lstWorkOrder[4].SVMXC__Order_Status__c = 'Initiated';
        lstWorkOrder[4].Is_Auto_Dispatch__c = true;
        lstWorkOrder[4].SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        lstWorkOrder[4].Reason__c = 'Testing';
        lstWorkOrder[4].SVMXC__SM_SLA_Initial_Response__c = 7200;
        lstWorkOrder[4].Send_to_ERP__c = True;
        
        lstWorkOrder[5].SVMXC__Order_Status__c = 'Initiated';
        lstWorkOrder[5].Is_Auto_Dispatch__c = true;
        lstWorkOrder[5].SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        lstWorkOrder[5].Reason__c = 'Testing';
        lstWorkOrder[5].SVMXC__SM_SLA_Initial_Response__c = 7200;
        lstWorkOrder[5].Send_to_ERP__c = True;
        
        lstWorkOrder[1].SVMXC__Customer_Down__c = true;
        lstWorkOrder[1].Reason__c = 'test';
        
        lstWorkOrder[3].SVMXC__Order_Status__c = 'Canceled';
        lstWorkOrder[3].Reason__c = 'Test';
        lstWorkOrder[3].SVMXC__Customer_Down__c = true;
        lstWorkOrder[3].SVMXC__SM_SLA_Initial_Response__c = 4320;
        
        lstWorkOrder[0].SVMXC__Order_Status__c = 'Scheduled';
        lstWorkOrder[0].Send_Notification_To_Customer__c = true;
        lstWorkOrder[0].SVMXC__SM_SLA_Initial_Response__c = 2880;
        
        try{
        update lstWorkOrder;
        }
        catch(Exception ee){
            System.assert(ee.getMessage().contains('Auto assignment is not possible at this time. Please manually assign'));
        }
        
        
        Test.stopTest();
    }
/*method : populateSoldToAccount  
    * description: update sold to on wo
    * @author : Sandeep Ram
    */
    public static testmethod void  populateSoldToAccount(){
        //initializeTestData();
         Account objAccLevel2 = TestDataAccount.getAccount('TestAccount Level2','USD');
        objAccLevel2.Account_Group__c='Sold To';
        objAccLevel2.ERP_Customer_Id__c = '4000026704';
        insert objAccLevel2;   
        Account objAccLevel1 = TestDataAccount.getAccount('TestAccount Level1','USD');
        objAccLevel1.Account_Group__c='Distributor';
        objAccLevel1.Parentid =objAccLevel2.id;
        Test.startTest();
        insert objAccLevel1;  
        Account objAcc = TestDataAccount.getAccount('TestAccount','USD');
        objAcc.Parentid =objAccLevel1.id;
        objAcc.Account_Group__c='Ultimate Consignee';
        insert objAcc;    
        Contact con  = TestDataPerson.getNewContact(objAcc.Id);     
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Preventative Maintenance';
        workOrder.SVMXC__Company__c = objAcc.Id;
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Contact__c= con.id;
        //Test.startTest();
        insert workOrder;
         Test.stopTest(); 
        SVMXC__Service_Order__c workOrder1 = [select id, Sold_To_Account__c,SVMXC__Company__c from SVMXC__Service_Order__c where id = : workOrder.id];
        system.assertequals(workOrder1.Sold_To_Account__c,objAccLevel2.id,'sold is not found/equal in the account hirechary');

    }
    
  /*method : updateSoldToOnWO 
    * description: update sold to on wo
    * @author : Sandeep Ram
    */
       public static testmethod void  updatePopulateSoldToAccount(){
      //initializeTestData();
        Account objAccLevel3 = TestDataAccount.getAccount('TestAccount Level3','USD');
        objAccLevel3.Account_Group__c='Sold To';
        insert objAccLevel3;
        Account objAccLevel2 = TestDataAccount.getAccount('TestAccount Level2','USD');
        objAccLevel2.Account_Group__c='Distributor';
        objAccLevel2.Parentid =objAccLevel3.id;
        insert objAccLevel2; 
        Account objAccLevel1 = TestDataAccount.getAccount('TestAccount Level1','USD');
        objAccLevel1.Account_Group__c='Distributor';
        objAccLevel1.Parentid =objAccLevel2.id;
        insert objAccLevel1;  
        Account objAcc = TestDataAccount.getAccount('TestAccount','USD');
        objAcc.Parentid =objAccLevel1.id;
        objAcc.Account_Group__c='Ultimate Consignee';
        insert objAcc;  
        System.assert(objAcc.Id != null,'objAcc id is null');
        Contact con  = TestDataPerson.getNewContact(objAcc.Id);    
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Preventative Maintenance';
        workOrder.SVMXC__Company__c = objAccLevel2.Id;
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Contact__c= con.id;
        Test.startTest();
        insert workOrder;
        SVMXC__Service_Order__c workOrder1 = [select id, Sold_To_Account__c,SVMXC__Company__c,Sold_To_Account__r.Name,SVMXC__Company__r.Name from SVMXC__Service_Order__c where id = : workOrder.Id];
        //Test.startTest();
        workOrder1.SVMXC__Company__c = objAcc.id;
        update workOrder1;
        Test.stopTest();
        //SVMXC__Service_Order__c workOrder2 = [select id, Sold_To_Account__c,SVMXC__Company__c,Sold_To_Account__r.Name,SVMXC__Company__r.Name from SVMXC__Service_Order__c where id = : workOrder1.Id];
        //System.assertequals(workOrder2.Sold_To_Account__c,objAccLevel3.id,'sold is not found/equal in the account hirechary');
    }
    /**
     * Method: testBillingTypeUpdatedByCS
     * DCP-38965
     * @author : sandeep 
     * */
    public static testMethod void testBillingTypeUpdatedByCS(){
   List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.ProfileCustomerService and IsActive =true LIMIT 1];
      
         Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
          objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        insert objInstalledProduct;
        Contact objContact = TestDataPerson.getNewContact(objAccount.Id);
          System.runAs(lstUsers[0]){
        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', objContact.Id);
         SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        objWorkOrder.SVMXC__Component__c = objInstalledProduct.Id;
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        objWorkOrder.SVMXC__Case__c = objCase.Id;
        objWorkOrder.Record_Created_from_SFM__c=true;
        objWorkOrder.SVMXC__Billing_Type__c ='Billable';
        Test.startTest();
        insert objWorkOrder;
        SVMXC__Service_Order__c wo =[select id,SVMXC__Billing_Type__c,Billing_Type_Set_Manually__c from SVMXC__Service_Order__c where id= : objWorkOrder.id];
        system.debug('@@@wo'+wo.SVMXC__Billing_Type__c+' '+wo.Billing_Type_Set_Manually__c);
        Test.stopTest();
         System.assert(wo.Billing_Type_Set_Manually__c,'wo.Billing_Type_Set_Manually__c is not true');
        }
    
    }
    /**
     * Method: testUpdateIsBillaleOnWdByCS
     * DCP-38965
     * @author : sandeep 
     * */
     public static testMethod void testUpdateIsBillaleOnWdByCS(){
   List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.ProfileCustomerService and IsActive =true LIMIT 1];
       Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c='Distributor';
        insert objAccount;
    SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        insert objInstalledProduct;
    BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;
    SVMXC__Service_Contract__c objServiceContract= TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
         objServiceContract.Parts_Included__c=true;
        insert objServiceContract;
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id );
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
        Test.startTest(); 
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        objWorkOrder.SVMXC__Component__c = objInstalledProduct.Id;
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE_BILLABLE_INSTALL;
        objWorkOrder.SVMXC__Case__c = objCase.Id;
        objWorkOrder.Record_Created_from_SFM__c=true;
        insert objWorkOrder;
        
        List<SVMXC__Service_Order_Line__c> lstWorkDetails = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = objWorkOrder.id;
        workDetail1.SVMXC__Line_Type__c='Parts';
        workDetail1.SVMXC__Product__c = toolProduct2.Id;
        workDetail1.SVMXC__Is_Billable__c = false;
        workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467              
        lstWorkDetails.add(workDetail1);
        
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c();
        workDetail2.SVMXC__Service_Order__c = objWorkOrder.id;
        workDetail2.SVMXC__Line_Type__c='Labour';
        workDetail2.SVMXC__Product__c = toolProduct2.Id;
        workDetail2.SVMXC__Activity_Type__c = 'IQ/OQ';
        workDetail2.SVMXC__Line_Status__c = 'Open';
        workDetail2.Labor_Hours__c = '4';
        lstWorkDetails.add(workDetail2);
        insert lstWorkDetails;

        SVMXC__Service_Order__c wo =[select id,SVMXC__Billing_Type__c,Billing_Type_Set_Manually__c from SVMXC__Service_Order__c where id= : objWorkOrder.id];
        system.debug('@@@objWorkOrder.SVMXC__Billing_Type__c'+wo.SVMXC__Billing_Type__c);
        
        System.runAs(lstUsers[0]){
            wo.SVMXC__Billing_Type__c='Billable';
            update wo;
        
            SVMXC__Service_Order_Line__c workDetail = [select id,SVMXC__Is_Billable__c from SVMXC__Service_Order_Line__c where SVMXC__Service_Order__c =:objWorkOrder.id and SVMXC__Line_Type__c='Labour'];
            System.assert(workDetail.SVMXC__Is_Billable__c,'workDetail.SVMXC__Is_Billable__c is not true'); 
         
        }
        Test.stopTest();
    
    }
    /**
     * Method: testUpdateBillableTypeOnWO
     * DCP-38965
     * @author : sandeep 
     * */
     public static testMethod void testUpdateBillableTypeOnWO(){
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
        //System.runAs(lstUsers[0]){
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
        test.startTest(); 
        insert objWorkOrder;
        //test.startTest(); 
        SVMXC__Service_Order__c wo =[select id,SVMXC__Billing_Type__c,SVMXC__Component__c from SVMXC__Service_Order__c where id= : objWorkOrder.id];
        System.assertEquals(null,wo.SVMXC__Billing_Type__c,'wo.SVMXC__Billing_Type__c is null'); 
          SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = objWorkOrder.id;
        workDetail1.SVMXC__Line_Type__c='Parts';
        workDetail1.SVMXC__Product__c = toolProduct2.Id;
        workDetail1.SVMXC__Is_Billable__c = true;
        workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467          
        insert workDetail1;   
         test.stoptest();
        system.debug('@W@'+[select id,SVMXC__Is_Billable__c from SVMXC__Service_Order_Line__c where id=:workDetail1.Id and SVMXC__Line_Type__c='Parts'][0].SVMXC__Is_Billable__c);
         SVMXC__Service_Order__c wo1 =[select id,SVMXC__Billing_Type__c from SVMXC__Service_Order__c where id= : wo.id];
        System.assertEquals('Billable',wo1.SVMXC__Billing_Type__c,'wo1.SVMXC__Billing_Type__c is not Billable'); 
        //}
        
    }



  /**
     * Method: CheckRelocationOnInstalledProducts
     * Description: Testmethod to test relocation sunctionality on completion of Relocation Work Order
     * CreatedDate: 18-08-2020
     * DCP-39877
     * */
    static testMethod void checkRelocationOnInstalledProducts() {
        Boolean exceptionThrown = false;

        Account acc1 = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc1.Account_Group__c='Distributor';
        acc1.ERP_Customer_Id__c = 'Test1';
        insert acc1;
        System.assert(acc1.Id != null);

        Account acc2 = TestDataAccount.getAccount(STRING_ACCOUNT+'2', 'USD');
        acc2.Account_Group__c='Distributor';
        acc2.ERP_Customer_Id__c = 'Test12';
        insert acc2;
        System.assert(acc2.Id != null);

        Contact con = TestDataPerson.getNewContact(acc1.Id);
        System.assert(con.id != null);
        contact con2 = TestDataPerson.getNewContact(acc2.Id);
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con2);
        insert cs;

        SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation('testlocation1','teststreet','testcountry','53434343','USD');
        insert objLocation1;

        SVMXC__Site__c objLocation2 = TestDataFieldService.createLocation('testlocation1','teststreet','testcountry','53434343','USD');
        insert objLocation2;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc1.Id;
        objInstalledProduct.SVMXC__Site__c = objLocation1.Id;
        objInstalledProduct.SVMXC__Contact__c = con2.id;
        try {
            UpdateIPQueueable_WOHelper.testClassCoverage = true;
            insert objInstalledProduct;

            Test.StartTest();
            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
            workOrder.SVMXC__Order_Type__c='Relocation';
            workOrder.Customer_Requested_Not_To_Re_Install__c=true;
            workOrder.Record_Created_from_SFM__c=true;
            workOrder.SVMXC__Component__c=objInstalledProduct.id;
            insert workOrder;

            workOrder.Relocated_Account__c=acc2.id;
            workOrder.Relocated_Location__c=objLocation2.id;
            workOrder.Is_Service_Report_Generated__c=true;
            workOrder.No_Calibrated_Tools_Used__c=true;
            workOrder.SVMXC__Order_Status__c='Completed';
            workOrder.No_Calibrated_Tools_Used__c = true;
            workOrder.Evaluation__c='Test';
            workOrder.SVMXC__Work_Performed__c='Test';
            workOrder.Verification_Result__c='Test'; 
            workOrder.Has_Verification_Code__c =true;
            workOrder.PO_Number__c='12';
            workorder.SVMXC__Contact__c=con2.id;
            WorkOrders.skipWOTrigger = true;
            Cases.skipCaseTrigger = true;
            update workOrder;
            Test.StopTest();
        } catch(Exception ex) {
            exceptionThrown = ex.getMessage().contains('Throwing Exception from Test Class');
        }
        System.assert(!exceptionThrown, 'Exception not thrown from queueable class');
        
    }

  
     /**
     * Method: woDistributorAccount
     * DCP-39824
     * @author : sandeep 
     * */
     public static testMethod void woDistributorAccount(){
            List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.ERP_Customer_Id__c='ERPCustomer';
        insert acc;
         SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
         objLocation.SVMXC__Account__c = acc.Id;
        insert objLocation;
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Primary Field Application Scientists',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        technician.SVMXC__Inventory_Location__c=objLocation.Id;
        insert technician;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Is_Auto_Created__c=true;
        workOrder.Partner_Work_Order__c =true;
        insert workOrder;
        test.startTest();
         workOrder.SVMXC__Group_Member__c=technician.id;
        update workOrder;
        test.stopTest();
        system.assertEquals('ERPCustomer',[select id,Distributor_Account__c from SVMXC__Service_Order__c where id=:workOrder.Id][0].Distributor_Account__c,'value is not erp customer');
    }

     /* Method: testUpdatePONumberUpdate
     * @author : Digvijay 
     * */
     public static testMethod void testUpdatePONumberUpdate(){
     List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name ='Field Service' and IsActive =true LIMIT 1];
     
        //Account objAccount = TestDataAccount.initAccount();//TestDataAccount.getAccount('Test Account', 'USD');
    Account objAccount = [SELECT id FROM Account LIMIT 1];
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        //insert objAccount;
    update objAccount;
        
         SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
            
    List<SVMXC__Service_Group_Members__c> techlist = new List<SVMXC__Service_Group_Members__c>();
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST,serviceTeam.id);
        technician.SVMXC__Email__c=STRING_EMAIL;
        //insert technician;
    techlist.add(technician);
        SVMXC__Service_Group_Members__c technician1 =TestDataFieldService.createTechnician(lstUsers[0].id,STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST,serviceTeam.id);
        technician.SVMXC__Email__c=STRING_EMAIL;
        //insert technician1;
     techlist.add(technician1);
     insert techlist;
        
        List<Account_to_Field_Support__c> lstAFS=new List<Account_to_Field_Support__c>();
         Account_to_Field_Support__c accTechRole = new Account_to_Field_Support__c(
            Account__c = objAccount.Id,
            User__c = technician.Id,
            User_Role__c = 'Primary Field Service Engineer'
        );
        lstAFS.add(accTechRole);
         Account_to_Field_Support__c accTechRole2 = new Account_to_Field_Support__c(
            Account__c = objAccount.Id,
            User__c = technician1.Id,
            User_Role__c = 'Partner Primary Field Service Engineer'
        );
        
        lstAFS.add(accTechRole2);
        
        insert lstAFS;
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
        
        Case objCase = [SELECT id, AccountId FROM Case WHERE RecordType.Name = 'Service Request' LIMIT 1];
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        objWorkOrder.SVMXC__Component__c = lstIp[1].Id;
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        objWorkOrder.SVMXC__Case__c = objCase.Id;
        objWorkOrder.Record_Created_from_SFM__c=true;
        objWorkOrder.PO_Number__c='6789';
        objWorkOrder.SVMXC__Company__c=objAccount.id;
        objWorkOrder.SVMXC__Billing_Type__c='Billable';
        WorkOrders.skipWOTrigger = true; 
        Cases.skipCaseTrigger = true; 
        test.startTest(); 
        insert objWorkOrder;
        SVMXC__Service_Order__c wo =[select id,SVMXC__Billing_Type__c,SVMXC__Component__c from SVMXC__Service_Order__c where id= : objWorkOrder.id];
         
        /*SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = objWorkOrder.id;
        workDetail1.SVMXC__Line_Type__c='Parts';
        workDetail1.SVMXC__Product__c = toolProduct2.Id;
        workDetail1.SVMXC__Is_Billable__c = true;
        
        workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467          
        insert workDetail1; */
        objWorkOrder.PO_Number__c='8976';
        objWorkOrder.Send_Pricing_Request_to_SAP__c=true;
        
        
        update  objWorkOrder;
        test.stoptest();
        
         SVMXC__Service_Order__c wo1 =[select id,SVMXC__Billing_Type__c ,PO_Number__c from SVMXC__Service_Order__c where id= : wo.id];
        System.assertEquals('8976',wo1.PO_Number__c);
      
        
    }
    /**
     * Method: testUpdateCostCenterOnWO
     * Description: DCP-42762-Test method to test send to ERP auto check on update of cost center on WO
     * @author : Raja Siva Krishna
     * */
    public static testMethod void testUpdateCostCenterOnWO(){
        //initializeTestData();
        Case cs = [Select Id from Case limit 1];
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        
        Test.startTest();
        workOrder.Cost_Center__c = 123456;
        //update workOrder;
        update workOrder;
        Test.stopTest();
        SVMXC__Service_Order__c updatedWo = [Select Send_to_ERP__c from SVMXC__Service_Order__c where Id =: workOrder.Id];
        
        System.assert(!updatedWo.Send_to_ERP__c,'Send to ERP auto updated and not reverted back after the update on cost center.');

    }
     
     //DCP-45000
    static testMethod void updateWOStatus(){
      //initializeTestData();

      Group testGroup = new Group(Name='test group', Type='Queue');
      insert testGroup;
      
      System.runAs(new User(Id=UserInfo.getUserId()))
      {
          QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
          insert testQueue;
      }
      Case cs = [Select Id from Case limit 1];
      SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
      workOrder.SVMXC__Order_Type__c='Installation';
      workOrder.Is_Auto_Created__c = true;
      
      insert workOrder;
      cs.Status='Initiated';
      cs.Work_Order_Status__c='Initiated';
      cs.OwnerId = testGroup.id;
      
       Test.startTest();  
      update cs;
      
      
      workOrder.SVMXC__Scheduled_Date_Time__c=system.now();
      workOrder.SVMXC__SM_Scheduled_Duration__c=1.2;
      // workOrder.SVMXC__Group_Member__c = grpMembers.Id;
      workOrder.SVMXC__Order_Status__c = 'In Progress'; 
      update workOrder;
        //Test.stopTest();
      List<SVMXC__Service_Order__c> worlOrderLst=[SELECT id FROM SVMXC__Service_Order__c where ID =:workOrder.id];
      System.assert(worlOrderLst.size() != null);
      
      System.assertEquals('In Progress' , [Select Id,Status from Case where Id =: cs.Id].Status, 'Status not updated to In progress.');

    Test.stopTest();
    }


    /**
    * DCP-39952
    *  @author : KD
    *  @description - test method to send Updated Scheduled Date To ERP
    **/
    @isTest
    static void testUpdatedScheduledDateToERP(){
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c='Installation';
        objWorkOrder.Is_Auto_Created__c = true;
        objWorkOrder.SVMX_PS_Subject__c = 'Test WO PO Update';
        objWorkOrder.Billing_Type_Set_Manually__c = true;
        objWorkOrder.SVMXC__Billing_Type__c = Label.WorkOrderBillingTypeBillable;
        objWorkOrder.SVMXC__Scheduled_Date_Time__c = DateTime.Now()-5;
        insert objWorkOrder;

        setting.Bypass_All_Validations__c = false;
        update setting;
        Test.startTest();
        ilib_LogEvent.message('Test.startTest();');
        objWorkOrder.SVMXC__Scheduled_Date_Time__c = DateTime.Now();
        update objWorkOrder;
        List<SVMXC__Service_Order__c> lstWO = [Select id,Send_to_ERP__c,SVMXC__Billing_Type__c from SVMXC__Service_Order__c LIMIT 1];
        System.assert(lstWO[0].Send_to_ERP__c,'SAP flag not updated');
        System.assertEquals('Billable',lstWO[0].SVMXC__Billing_Type__c,'Workorder Not billable');
        ilib_LogEvent.message('Test.stopTest();');
        Test.stopTest();
    }
    /**
    * DCP-46317
    *  @author : Adyasha
    *  @description - test method to update WO status to Technician onsite and verify Scheduled Date Time
    **/
    @isTest
    static void testUpdatedScheduledDate(){
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c='Installation';
        objWorkOrder.Is_Auto_Created__c = true;
        objWorkOrder.SVMX_PS_Subject__c = 'Test WO Update';
        objWorkOrder.Billing_Type_Set_Manually__c = true;
        objWorkOrder.SVMXC__Billing_Type__c = Label.WorkOrderBillingTypeBillable;
        objWorkOrder.SVMXC__Scheduled_Date_Time__c = System.Now()-10;
        insert objWorkOrder;

        setting.Bypass_All_Validations__c = false;
        update setting;
        Test.startTest();
        objWorkOrder.SVMXC__Order_Status__c = 'Technician Onsite';
        update objWorkOrder;
        Test.stopTest();
        List<SVMXC__Service_Order__c> lstWO = [Select id,SVMXC__Scheduled_Date_Time__c from SVMXC__Service_Order__c LIMIT 1];
        System.assertNotEquals(objWorkOrder.SVMXC__Scheduled_Date_Time__c,lstWO[0].SVMXC__Scheduled_Date_Time__c, 'Scheduled Date Time Not Updated');
    
    }
      
    /**
    * DCP-39881
    *  @author : Gautam Arya
    *  @description - test method to validate DCIR Error if work order status is completed
    **/

    static testMethod void testValidateIfDCIRAgreementIsGenerated() {
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        Boolean expectedExceptionThrown = false;

        //START - DCP-47686 
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount.Account_Group__c='Distributor';
        insert objAccount;

        Contact objContact = TestDataContact.getNewContact(objAccount);

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;    
        List<User> lstUser = new List<User> {TestDataUser.initPartnerUser(profileId, objContact.id)};
        insert lstUser;
        
        //END - DCP-47686 
        Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
        cp.SetupOwnerId= lstUser[0].profile.id;
        cp.Is_Channel_Partner__c= True;
        insert cp;

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation1','teststreet','testcountry','53434343','USD');
        insert objLocation;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.SVMXC__Site__c = objLocation.Id;
        objInstalledProduct.SVMXC__Contact__c = objContact.id;
        Cases.skipCaseTrigger = true;
        WorkOrders.skipWOTrigger = true;
        insert objInstalledProduct;

        //START - DCP-47686
        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', lstUser[0].ContactId);
        objCase.GTS_Status__c = 'Request Initiated';
        objCase.Has_Analysis_Code__c = true;
        objCase.Has_Resolution_Code__c = true;
        objCase.HasHazardCode__c = true;
        Cases.skipCaseTrigger = true;
        update objCase;
        //END - DCP-47686

        //Test.startTest();
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
        objWorkOrder.Customer_Requested_Not_To_Re_Install__c=true;
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE_RELOCATION;
        objWorkOrder.Record_Created_from_SFM__c=true;
        objWorkOrder.DCIR_Status__c='Open';
        objWorkOrder.SVMXC__Component__c=objInstalledProduct.id;
        objWorkOrder.Relocated_Location__c = objLocation.id;
        Test.startTest();
        WorkOrders.skipWOTrigger = false;
        INSERT objWorkOrder;

        System.assertNotEquals(null, objWorkOrder.Id);
        if(!lstUser.isEmpty()){
            objWorkOrder.ownerId=lstUser[0].id;
            WorkOrders.skipWOTrigger = true;
            UPDATE objWorkOrder;
        }

        if(!lstUser.isEmpty()){
            System.runas(lstUser[0]){
                try{
                    objWorkOrder.SVMXC__Problem_Description__c='Test';
                    objWorkOrder.SVMX_PS_Subject__c= 'Test';
                    objWorkOrder.Evaluation__c= 'Test';
                    objWorkOrder.Verification_Result__c= 'Test';
                    objWorkOrder.SVMXC__Work_Performed__c='Test';
                    objWorkOrder.No_Calibrated_Tools_Used__c = true;
                    objWorkOrder.Is_Service_Report_Generated__c=true;
                    objWorkOrder.Signature_Type__c='Manual Sign';
                    objWorkOrder.Manual_Sign_Captured__c=true;
                    objWorkOrder.Is_Customer_Sign_Captured__c=true;
                    objWorkOrder.PO_Number__c='12';
                    objWorkOrder.Cost_Center__c=8765;
                    objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE_RELOCATION;
                    objWorkOrder.SVMXC__Order_Status__c = 'Completed';
                    //objWorkOrder.DCIR_Status__c='Completed';
                    objWorkOrder.Relocated_Account__c = objAccount.id;
                    WorkOrders.skipWOTrigger = false;
                    UPDATE objWorkOrder;
                } Catch(Exception ex){
                    expectedExceptionThrown =  ex.getMessage().contains(Label.WODCIRCheckErrorCP) ? true : false;
                    System.assert(expectedExceptionThrown, 'Expected Validation from Confirm Assignee Functionality not thrown'+ex.getMessage());
                }
            }
        }
        Test.stopTest();
    }

    /**
    * DCP-39881
    *  @author : Gautam Arya
    *  @description - test method to validate DCIR Error if DCIR status is set to completed
    **/
    static testMethod void testValidateIfDCIRStatusIsCompleted(){
        //initializeTestData();
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount.Account_Group__c='Distributor';
        insert objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;    
        List<User> lstUser = new List<User> {TestDataUser.initPartnerUser(profileId, objContact.id)};
        insert lstUser;
        Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
        cp.SetupOwnerId= lstUser[0].profile.id;
        cp.Is_Channel_Partner__c= True;
        insert cp;
        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', lstUser[0].ContactId);
        objCase.GTS_Status__c = 'Request Initiated';
        update objCase;
        Case cs = [Select Id from Case limit 1];
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE_RELOCATION;
        objWorkOrder.Customer_Requested_Not_To_Re_Install__c=true;
        objWorkOrder.Record_Created_from_SFM__c=true;
        objWorkOrder.DCIR_Status__c='Open';
        objWorkOrder.SVMXC__Case__c = objCase.Id;
        Test.startTest();
        insert objWorkOrder;
        System.assertNotEquals(null, objWorkOrder.Id);
        if(!lstUser.isEmpty()){
        objWorkOrder.ownerId=lstUser[0].id;
        Update objWorkOrder;
        }

        if(!lstUser.isEmpty()){
          System.runas(lstUser[0]){

          try{
              objWorkOrder.DCIR_Status__c='Completed';
              update objWorkOrder;
           }Catch(Exception ex){
              system.assert(ex.getMessage() != Null , 'No Error');
           } 
        }
        }
        //START - DCP-47686
        ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
        insert objCV;
        system.assertNotEquals(null, objCV.id);
        objCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, objWorkOrder.Id,'V','AllUsers');
        insert objCDL;
        Attachment objAttachment = TestDataFieldService.createAttachment(objWorkOrder.id,'Letter_of_Acceptance');
        insert objAttachment;
      try{
        objWorkOrder.DCIR_Status__c='Completed';
        update objWorkOrder;
      } Catch(Exception ex){
          system.assert(ex.getMessage() != Null , 'No Error');
      }
      //END - DCP-47686
      Test.stopTest();
  }
    /**
    *  @author : KD
    *  @description - DCP-45490 : CP Relocation WO should not be billable.
    **/
    public static testMethod void testCPRelocationWOCreation(){
      Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id; 
      Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
      objAccount1.Account_Group__c='Distributor';
      insert objAccount1;
      
      Contact objContact = TestDataContact.getNewContact(objAccount1);
      
      //Creating User
      User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      User objUser;
      User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{thisUser.Id});
      TestDataUser.allowUserCreation(objUser1.Id); 

      System.runAs(objUser1) {
      
          //Querying Territory Type
          List<Territory2Type> territoryType   = [SELECT id, DeveloperName from Territory2Type where  DeveloperName = 'Territory_Value_Added_Distributor_Channel_Partner' LIMIT 1];
          
          //Querying Active Territory Model
          Territory2Model terrModel = [SELECT Id, Name, (SELECT Id, Name FROM Territory2s) FROM Territory2Model WHERE State = 'Active' Limit 1];
          
          //Creating Territory 
          Territory2 objTerritory = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId=terrModel.Id, Name='TestTerritory', Territory2TypeId=territoryType[0].Id);
          insert objTerritory;
          
          //Associating Territory with Account 1
          ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,objAccount1.id);
          insert objTerritoryAssociation;

          //Created User
          objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
          insert objUser;
          
      }

      
      SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
      objInstalledProduct.Asset_Type__c =  WorkOrders.STRING_WORK_ORDER_IP_ASSET_TYPE_CUSTOMER_OWNED;
      insert objInstalledProduct;

      Test.startTest();
      System.runAs(objUser){
          Case objCase = TestDataCase.createCase('Service Request', 'Initiated', objContact.Id);
          SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
          objWorkOrder.SVMXC__Component__c = objInstalledProduct.Id;
          objWorkOrder.Customer_Requested_Not_To_Re_Install__c=true;
          objWorkOrder.SVMXC__Order_Type__c=WorkOrders.STRING_WORK_ORDER_ORDER_TYPE_RELOCATION;
          objWorkOrder.SVMXC__Case__c = objCase.Id;
          objWorkOrder.Record_Created_from_SFM__c=true;
          insert objWorkOrder;
          SVMXC__Service_Order__c wo =[select id,SVMXC__Billing_Type__c,Billing_Type_Set_Manually__c from SVMXC__Service_Order__c where id= : objWorkOrder.id];
          system.debug('@@@wo'+wo.SVMXC__Billing_Type__c+' '+wo.Billing_Type_Set_Manually__c);
          System.assertEquals(null,wo.SVMXC__Billing_Type__c,'Billing Type set to true');
      }
      Test.stopTest();
    }

  /**
     * @author Gladis
     * @date   26-June-2021
     * @description   DCP-38816 : test method to test Update Opportunity Abandoned
    **/
    static testMethod void testupdateOpportunityAbandoned(){
        //initializeTestData();

        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name ='Field Service' and IsActive =true LIMIT 1];
        //User objUser = TestDataUser.findUserInProfile('Sales User');
        Test.startTest();
        
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc);
        opp1.Name = 'Test Opp 1';
        opp1.Ultimate_Consignee__c = acc.Id;
        opp1.Current_Ultimate_Consignee__c = acc.Id;
        opp1.OwnerId = lstUsers[0].Id; 
        insert opp1;
        
        System.runAs(lstUsers[0]){
            
        Case cs = TestDataCase.createCase('Service Request', 'Initiated', con.Id);

        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrder.Opportunity__c = opp1.id; 
        workOrder.Abandoned_Reason__c = 'Customer Declined Service';
        workOrder.Is_Auto_Created__c=true;
        insert workOrder;
        setting.Bypass_All_Validations__c = false;
        update setting;

        
        //updating work order
        SVMXC__Service_Order__c wo = [select id,SVMX_PS_Subject__c,Abandoned_Reason__c from SVMXC__Service_Order__c where id =:workOrder.id];
        wo.Abandoned_Reason__c='No Customer Response';
        wo.SVMX_PS_Subject__c='test';
        update wo;
        Test.getEventBus().deliver();
        SVMXC__Service_Order__c updatedwo = [select Id,SVMX_PS_Subject__c,Abandoned_Reason__c,Opportunity__c from SVMXC__Service_Order__c where id =:wo.id];
        System.assertEquals('No Customer Response',updatedwo.Abandoned_Reason__c,'reason not updated'); 
        
        }
        Test.stopTest();

    }



  /**
  *  @author Nishan Shetty
  *  @description - CMCP-23 method to check Partner Work Order flag while updating.
  **/
  static testmethod void checkChannelPartnerWorkOrderUpdate() {
   
      //Created Account 1
      Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
      objAccount1.Account_Group__c='Distributor';
      insert objAccount1;

      //Created Account 2
      Account objAccount2 = TestDataAccount.getAccount('Test Acc2', 'USD');
      objAccount2.Account_Group__c='Distributor';
      insert objAccount2;

      //Created Contact1
       Contact objContact = TestDataContact.getNewContact(objAccount1);

      //Creating User
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       User objUser;
       User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{thisUser.Id});
       TestDataUser.allowUserCreation(objUser1.Id); 

       System.runAs(objUser1) {

      Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;    
      //Querying Territory Type
      List<Territory2Type> territoryType   = [SELECT id, DeveloperName from Territory2Type where  DeveloperName = 'Territory_Value_Added_Distributor_Channel_Partner' LIMIT 1];
      
      //Querying Active Territory Model
      Territory2Model terrModel = [SELECT Id, Name, (SELECT Id, Name FROM Territory2s) FROM Territory2Model WHERE State = 'Active' Limit 1];
       
     
      //Creating Territory 
      Territory2 objTerritory = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId=terrModel.Id, Name='TestTerritory', Territory2TypeId=territoryType[0].Id);
      insert objTerritory;
      
      //Associating Territory with Account 1
      ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,objAccount1.id);
      insert objTerritoryAssociation;

      //Associating Territory with Account 2
      ObjectTerritory2Association objTerritoryAssociation2 = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,objAccount2.id);
      insert objTerritoryAssociation2;
      
      
      //Created User
      objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
      insert objUser;

      Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
      cp.SetupOwnerId= profileId;
      cp.Is_Channel_Partner__c= True;
      insert cp;
       }

      test.startTest();

      //Created Case
      Case objCase = TestDataCase.initServiceRequestCase(objContact);
      insert objCase;	
      //Create Work Order     
      SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, objCase.Id, 'Initiated');
      objWorkOrder.SVMXC__Company__c = objAccount1.id;
      objWorkOrder.SVMXC__Order_Type__c = 'Installation';
      objWorkOrder.Is_Auto_Created__c=true;
      insert objWorkOrder;
      objWorkOrder.OwnerId=objUser.Id;
      objWorkOrder.SVMXC__Company__c=objAccount2.id;
      update objWorkOrder;
  
      test.stopTest();   
       
      SVMXC__Service_Order__c objNewWO=[Select Id,Partner_Work_Order__c from SVMXC__Service_Order__c where SVMXC__Company__c=:objAccount2.Id];
      System.assert(true, objNewWO.Partner_Work_Order__c);
  }  

  /**
  *  @author Rishi Sharma
  *  @description - DCP-47271 - Test Work Order Field update on case after insert.
  **/    
  static testMethod void testPopulateWorkOrderOnCaseInsert(){
      //initializeTestData();
      
      System.runAs(new User(Id=UserInfo.getUserId())){
      Test.startTest();
      Case cs = [Select Id from Case limit 1];
      SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
      workOrder.SVMXC__Order_Type__c='Installation';
      workOrder.Is_Auto_Created__c = true;

      insert workOrder;
      
      List<SVMXC__Service_Order__c> worlOrderLst=[SELECT id FROM SVMXC__Service_Order__c where ID =:workOrder.id];
      System.assert(worlOrderLst.size() != null);
      Case caseRec=[SELECT id, Work_Order__c  FROM Case where ID =:cs.id];
      System.assert(worlOrderLst.size() != null, 'List Should not be Empty');
      Test.stopTest();
      }
  }

  /**
  *  @author Rishi Sharma
  *  @description - DCP-47271 - Test Work Order Field update on case after update.
  **/ 
  static testMethod void testPopulateWorkOrderOnCaseUpdate(){
      //initializeTestData();

      System.runAs(new User(Id=UserInfo.getUserId())){
      Test.startTest();  
      Case cs = [Select Id from Case limit 1];
      SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, null, 'Initiated');
      workOrder1.SVMXC__Order_Type__c='Installation';
      workOrder1.Is_Auto_Created__c = true;

      insert workOrder1;
      workOrder1.SVMXC__Case__c = cs.Id;
      update workOrder1;
      Case caseRec=[SELECT id, Work_Order__c  FROM Case where ID =:cs.id];
      System.assertEquals(caseRec.Work_Order__c, workOrder1.Id);
      Test.stopTest();
      }
  }


/*
@Author : Pooja Shalwadi
@Description: This method is used to create Installed WO and handle Training required, reason for No training requirement
DCP-49916
*/
public static testMethod void testUpdateOrderTypeInstallation() {
    User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = STRING_USER_EMAIL,
             Username = STRING_USER_EMAIL + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = STRING_TIMEZONE,
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
      System.assert(u.Id!=null);
      Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
       objAccount.Account_Group__c='Distributor';
       insert objAccount;    
       Contact objContact = TestDataPerson.getNewContact(objAccount.Id);
       System.runAs(u){
       Case objCase = TestDataCase.createCase('Service Request', 'Initiated', objContact.Id);

       Test.startTest();   
      
       List<SVMXC__Service_Order__c> lstWO= new List<SVMXC__Service_Order__c>();
       SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
                 objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
                 objWorkOrder.SVMXC__Case__c = objCase.Id;
                 objWorkOrder.Record_Created_from_SFM__c=true;
                 lstWO.add(objWorkOrder);
       SVMXC__Service_Order__c objWorkOrder1 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
                 objWorkOrder1.SVMXC__Order_Type__c='Installation';
                 objWorkOrder1.Training_Required__c=true;
                 objWorkOrder1.Is_Auto_Created__c = true;
                 objWorkOrder1.SVMXC__Case__c = objCase.Id;
                 objWorkOrder1.Record_Created_from_SFM__c=true;
                 lstWO.add(objWorkOrder1);
       SVMXC__Service_Order__c objWorkOrder2 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
                 objWorkOrder2.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
                 objWorkOrder2.SVMXC__Case__c = objCase.Id;
                 objWorkOrder2.Record_Created_from_SFM__c=true;
       lstWO.add(objWorkOrder2);
   
          insert lstWO;
          System.assert(lstWO.size()>0);
          List<SVMXC__Service_Order__c> wo =[SELECT id,SVMXC__Order_Type__c,Reason_for_No_Training__c,Training_Required__c FROM SVMXC__Service_Order__c LIMIT 3];
          wo[0].SVMXC__Order_Type__c='Installation';
          wo[0].Training_Required__c=true;
          wo[1].SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;

          wo[2].Reason_for_No_Training__c='Customer Declined - Lab already trained';
          update wo;
       }
      Test.stopTest();  
      List<SVMXC__Service_Order__c> wolst =[SELECT id,SVMXC__Order_Type__c,Reason_for_No_Training__c,Training_Required__c 
                                          FROM SVMXC__Service_Order__c LIMIT 3];
      System.debug('wolst--->'+wolst);
      System.assertEquals(true,wolst[0].Training_Required__c);
      System.assertEquals(null,wolst[0].Reason_for_No_Training__c);

      System.assertEquals(false,wolst[1].Training_Required__c);
      System.assertEquals(NON_INSTALL_WO,wolst[1].Reason_for_No_Training__c);
      System.debug('wo 2--->'+wolst[2].Reason_for_No_Training__c);
   }

    /**
    *  @author Arquimidez Mora
    *  @description - delete Order Line Items related when status changes 
    **/
    static testMethod void deleteOrderLineItemRelatedWhenStatusChange(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
        Bypass_Triggers_By_Object_1__c = 'Case',
        Bypass_Triggers_By_Object_2__c = 'Account',
        Bypass_Triggers_By_Object_3__c = 'Contact'
        );
        insert apexSettings;  
        //initializeTestData();
        Account objAccount =TestDataAccount.getAccount('TestAccountApttusOrderUpdate');
        objAccount.ERP_Customer_Id__c='654321';
        insert objAccount;

        Contact objContact = TestDataContact.getNewContact(objAccount);
        objContact.Email = 'test123@illumina.com';
        update objContact;

        Pricebook2 objPricebook = TestDataOpportunity.getStandardPriceBook();
        
        Opportunity objOpp = TestDataOpportunity.getNewOpportunity(objAccount);
        objOpp.Pricebook2Id = objPricebook.Id;
        update objOpp;
        
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceList;
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpp.id, 'Test Proposal Update', objPriceList.id, true, 'Draft', 'None');
        insert objProposal;
        
        Apttus_Config2__Order__c objOrder =new Apttus_Config2__Order__c();
        objOrder.Sales_Order_Number_Unique__c='001';
        objOrder.Apttus_Config2_SoldToAccountId_ERP_Id__c='123456';
        objOrder.Ultimate_Consignee_ERP_Id__c='123456';
        objOrder.Distributor_ERP_Id__c='123456';
        objOrder.Bill_To_ERP_Id__c='1981';
        objOrder.Ship_To_ERP_Id__c='1981';
        objOrder.Payer_ERP_Id__c='1981';
        objOrder.Apttus_Config2__PODate__c=Date.valueOf('2018-10-20');
        objOrder.APTTUS_Quote_Number__c=objProposal.Name;
        objOrder.Apttus_Config2__RelatedOpportunityId__c = objOpp.Id;
        insert objOrder;

        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
        Case objCase  = new Case();  
        objCase.Status = 'Initiated';
        objCase.Subject = 'test' ;
        objCase.Description= 'test';
        objCase.Origin = 'Phone-CP';
        objCase.Date_of_Issue_Awareness__c=System.today() -2;
        objCase.ContactId = objContact.Id;
        objCase.AccountId = objAccount.Id;
        objCase.RecordTypeId = idCaseRecordTypeId;
        objCase.SVMXC__Component__c = null;
        objCase.Next_Steps__c='Case AutoGenerated by Install WO Process.';
        insert objCase;

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        objProduct.Serial_Number_Profile__c = 'IL02';
        objProduct.Regulatory_Type__c  = ApttusOrderLineItems.STRING_PRODUCT_REGULATORY_TYPE_EUA; 
        insert objProduct;

        Apttus_Config2__AssetLineItem__c objAssetLineItem = new Apttus_Config2__AssetLineItem__c();
        objAssetLineItem.Apttus_Config2__AccountId__c = objAccount.Id;
        objAssetLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objAssetLineItem.Serial_Number__c = '123123';
        objAssetLineItem.Contract_Number__c = '453523413';
        objAssetLineItem.Contract_Type__c = 'test Contract Type';
        objAssetLineItem.Apttus_QPConfig__ProposalId__c = objProposal.Id;
        objAssetLineItem.Apttus_Config2__AssetStatus__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Status__c = System.Label.AssetLineItemStatusActivated;
        objAssetLineItem.Apttus_Config2__EndDate__c = System.today();
        objAssetLineItem.Apttus_Config2__StartDate__c = Date.valueOf('2017-10-01');
        objAssetLineItem.Apttus_Config2__OriginalStartDate__c = Date.valueOf('2017-10-01');
        insert objAssetLineItem;

        Test.startTest();
        Apttus_Config2__OrderLineItem__c objOrderLineItem = new Apttus_Config2__OrderLineItem__c();
        objOrderLineItem.Apttus_Config2__OrderId__c = objOrder.Id;
        objOrderLineItem.Apttus_Config2__ProductId__c = objProduct.Id;
        objOrderLineItem.Apttus_Config2__Quantity__c = 2;
        objOrderLineItem.ERP_Line_Number_Id__c = '12345_122';
        objOrderLineItem.Equipment_Id__c = '123';
        insert objOrderLineItem;
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, null, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c='Installation';
        objWorkOrder.Is_Auto_Created__c = true;
        objWorkOrder.Record_Created_from_SFM__c = true;
        insert objWorkOrder;
        objOpp.Work_Order__c = objWorkOrder.Id;
        update objOpp;
        objWorkOrder.SVMXC__Order_Status__c = 'In Progress';
        update objWorkOrder;
        Test.stopTest();

        system.assertEquals(0, [SELECT COUNT() FROM Apttus_Config2__OrderLineItem__c WHERE Id = :objOrderLineItem.Id] ,'Order line items should be deleted' );
    }
}
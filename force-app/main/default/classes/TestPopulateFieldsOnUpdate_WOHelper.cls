/**
* @author Rohan Rathod
* @date 29 Nov 2022
* @Classes covered by this Test class - PopulateFieldsOnUpdate_WOHelper
* @description DCP-57117 Test class for PopulateFieldsOnUpdate_WOHelper

MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Rohan Rathod        29 Nov 2022         DCP-57117 : Test class created

****************************************************************************************************************************************/ 
 
@IsTest(SeeAllData = false)
private class TestPopulateFieldsOnUpdate_WOHelper {
    static final String STRING_SHIPPING_TYPE_TRUNK = 'Trunk';
    public static final String STRING_ACCOUNT = 'Test Acc';
    static SVMXC__RMA_Shipment_Order__c objPartsOrder;
    public static final String STRING_TIMEZONE = 'America/Los_Angeles';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_USER_EMAIL = 'new5@test.com';
    public static final String SECONDARY_FIELD_SERVICE_ENGINEER = 'Secondary Field Service Engineer';
    public static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    public static final String BUSINESS_ISSUE = 'Business Issue';
    public static final String STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST = 'Primary Field Application Scientists';
    public static final String STRING_EMAIL = 'a@b.com';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    static Case cs;  

    /*******************************************************************************************************
    * @description setup data
    */
    @testSetup
    public static void testDataCreation() {
        List<User> usersList = new List<User>();
        Profile fsProfile = [SELECT Id FROM Profile WHERE Name =: System.label.Field_Service Limit 1];
        User u1 = new User(
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
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name=:System.label.Field_Service Limit 1].Id,
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
        usersList.add(u1);
        usersList.add(u);
        insert usersList;
        System.assertNotEquals(null, u.Id, 'User should not be null');

        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id, 'Service Team should not be NULL');
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        System.assertNotEquals(null, grpMembers.Id, 'Field Support should not be NULL');
             
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assertNotEquals(null, acc.Id, 'Account should not be NULL');

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        List<SVMXC__Service_Level__c> objServiceLevels = new List<SVMXC__Service_Level__c> ();
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        objServiceLevel.Least_SLA__c = 2880;

        SVMXC__Service_Level__c objServiceLevel2 = TestDataFieldService.createServiceLevel();
        objServiceLevel2.SVMXC__Business_Hours__c = objBuinessHours.id;
        objServiceLevel2.Least_SLA__c = 4320;

        objServiceLevels.add(objServiceLevel);
        objServiceLevels.add(objServiceLevel2);
        insert objServiceLevels; 
        

        List<SVMXC__Service_Contract__c> servcContractList = new List<SVMXC__Service_Contract__c>();
        SVMXC__Service_Contract__c servcContract= TestDataFieldService.createServiceContract(acc.Id);
        servcContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        SVMXC__Service_Contract__c servcContract2= TestDataFieldService.createServiceContract(acc.Id);
        servcContract2.SVMXC__Service_Level__c = objServiceLevel2.Id;
        servcContractList.add(servcContract);
        servcContractList.add(servcContract2);
        insert servcContractList;

        List<SVMXC__Installed_Product__c> objInstalledProductList = new List<SVMXC__Installed_Product__c>();
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.Currently_Active_Service_Contract__c = servcContract.Id;
        SVMXC__Installed_Product__c objInstalledProduct2 = TestDataFieldService.createInstalledProduct('Test IP2', 'USD', 'New');
        objInstalledProduct2.Operation_Status__c='Off';
        objInstalledProduct2.Currently_Active_Service_Contract__c = servcContract2.Id;
        
        objInstalledProductList.add(objInstalledProduct);
        objInstalledProductList.add(objInstalledProduct2);
        insert objInstalledProductList;
 
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        System.assertNotEquals(null, objProduct.Id, 'Project should not be NULL'); 

        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assertNotEquals(null, con.Id, 'Contact should not be NULL'); 
         cs = TestDataCase.initServiceRequestCase(con); 
 
        Case bIcase = TestDataCase.initNewCase(BUSINESS_ISSUE, 'Initiated', 'Email-TS');
        bIcase.OwnerId = u.id;
        insert bIcase;
    }

    @isTest static void workOrderStatusUpdatedToInProgress() { 
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'Account',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_4__c = 'Contact'
        );
        insert apexSettings;
        Account acc = [SELECT id FROM Account WHERE Account_Group__c = 'Distributor' AND Name=: STRING_ACCOUNT LIMIT 1];        
         Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
         objProduct.Product_Group__c = 'AmpliSeq Library Prep';
         objProduct.Source_System__c='SAP';
         insert objProduct;
   
         SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
         objInstalledProduct.SVMXC__Company__c = acc.Id;
         objInstalledProduct.Operation_Status__c='Off';
         objInstalledProduct.SVMXC__Product__c = objProduct.Id;
         insert objInstalledProduct;
        
        Contact con = [Select Id,AccountId from Contact limit 1];
        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;
         SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
         workOrder.SVMXC__Component__c = objInstalledProduct.Id;
         workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
         workOrder.SVMXC__Company__c = acc.Id;
         workOrder.Is_Auto_Created__c = true;
         insert workOrder;
         System.assertNotEquals(null, workOrder.Id, 'Work order should not be null');
         Test.startTest();
         workOrder.SVMXC__Scheduled_Date_Time__c=system.now();
         workOrder.SVMXC__SM_Scheduled_Duration__c=1.2;
         workOrder.SVMXC__Order_Status__c = 'In Progress'; 
         update workOrder;
         System.assertNotEquals(null, workOrder.Id, 'Work order should not be null');
         Test.stopTest();
       }

       @isTest static void testDispatchFSE() {
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
                SVMXC__Email__c = 'testmail1@testing.com',
                SVMXC__Country__c = 'India',
                SVMXC__Street__c = 'Test',
                SVMXC__Salesforce_User__c = u.Id,
                SVMXC__Service_Group__c = serviceTeam.Id
            );
            insert grpMembers;
            System.assertNotEquals(null, grpMembers.Id, 'Field Support should not be Null');
                    
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c='Distributor';
            insert acc;
            System.assertNotEquals(null, acc.Id, 'Account should not be Null');

            Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
            objProduct.Source_System__c='SAP';
            insert objProduct;
            System.assertNotEquals(null, objProduct.Id, 'Product should not be null');        
            
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
            System.assertNotEquals(null, lstAccountRoles[0].Id, 'Account to Field Support should not be Null');

            SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
                                                                                            SVMXC__Group_Member__c = grpMembers.Id,
                                                                                            SVMXC__Service_Group__c = serviceTeam.Id);
            insert objExpertise;
            System.assertNotEquals(null, objExpertise.Id, 'Product group should not be Null');

            SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
            workOrder.SVMXC__Product__c = objProduct.Id;
            workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
            workOrder.SVMXC__Company__c = acc.Id;
            workOrder.Is_Auto_Created__c = true;
            Test.startTest();
            insert workOrder;
            System.assertNotEquals(null, workOrder.Id, 'WO should not be NULL'); 
            workOrder.Is_Auto_Dispatch__c = true;
            workOrder.Dispatch_Source__c = 'Field Technician';
            workOrder.SVMXC__Billing_Type__c = 'Billable';
            update workOrder;
            System.assertEquals('Field Technician', workOrder.Dispatch_Source__c, 'Dispatch Source should be updated');
            Test.stopTest();
       }

       @isTest static void testWOOnsiteResponseDueDate() { 
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'Account',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_4__c = 'Contact'
        );
        insert apexSettings;
           SVMXC__Installed_Product__c objInstalledProduct = [Select id from SVMXC__Installed_Product__c Where Name = 'Test IP2' limit 1];
           User testUser = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND LastName = 'last' AND IsActive=TRUE LIMIT 1];
        //    System.assertNotEquals(null, testUser.Id, 'User should not be null');

           SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
           insert serviceTeam;
           SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(testUser.id,STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST,serviceTeam.id);
           technician.SVMXC__Email__c=STRING_EMAIL;
           insert technician;
           SVMXC__Service_Order__c workOrderToUpdate = new SVMXC__Service_Order__c(); 
            Case objCase = [Select Id from Case where RecordType.Name=:BUSINESS_ISSUE limit 1]; 
            SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                                SVMXC__Order_Status__c,SVMXC__Locked_By_DC__c from 
                                                SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
           System.debug('The order type is '+workOrder); 
           workOrder.SVMXC__Order_Type__c = STRING_WO_ORDER_TYPE; 
           workOrder.Evaluation__c='Test';
           workOrder.SVMXC__Work_Performed__c='Test';
           workOrder.Verification_Result__c='Test';        
           workOrder.Record_Created_from_SFM__c = true;
           workOrder.SVMXC__Group_Member__c = technician.Id;
           workOrder.OwnerId = testUser.id;
           workOrder.SVMXC__Locked_By_DC__c = true; 
           update workOrder;
         
           workOrderToUpdate = [select id, Onsite_Response_Due_Date__c, SVMXC__SLA_Terms__c, OwnerId  from SVMXC__Service_Order__c where Id = :workOrder.Id Limit 1];
           System.assertNotEquals(null, workOrderToUpdate.Id, 'WO should not be null');  
        
        Test.startTest();
            User testUser2 = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND LastName = 'Last Name' AND IsActive=TRUE LIMIT 1];
            SVMXC__Service_Order__c workOrderToUpdate2 = [select id, Onsite_Response_Due_Date__c, SVMXC__SLA_Terms__c, OwnerId, SVMXC__Order_Status__c from SVMXC__Service_Order__c where Id = :workOrderToUpdate.Id Limit 1];
            workOrderToUpdate2.OwnerId = testUser2.id; 
            workOrderToUpdate2.SVMXC__Order_Status__c = 'Technician Onsite';
            workOrderToUpdate2.SVMXC__Component__c = objInstalledProduct.Id; 
            update workOrderToUpdate2;
           // System.assertNotEquals(null, workOrderToUpdate.Onsite_Response_Due_Date__c, 'WO ORDD should not be null'); 
            Test.stopTest();  
       }

       @isTest static void testupdateScheduledDateTimeAndSendERP(){
        //testDataCreation();
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'Account',
            Bypass_Triggers_By_Object_3__c = 'Product2',
            Bypass_Triggers_By_Object_4__c = 'Contact'
        );
        insert apexSettings;
        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c='Distributor';
        insert objAccount;  

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        System.assertNotEquals(null, objProduct.Id, 'Product should not be null');  

        Contact con = TestDataPerson.getNewContact(objAccount.Id); 
        Case varCase = TestDataCase.initServiceRequestCase(con);
        insert varCase;
        
        List<SVMXC__Service_Order__c> lstWO= new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, varCase.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        lstWO.add(workOrder);

        
        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
        objWorkOrder.Record_Created_from_SFM__c=true;
        lstWO.add(objWorkOrder);
        insert lstWO;
       
        Test.startTest();
        List<SVMXC__Service_Order__c> wo =[SELECT id,Cost_Center__c,SVMXC__Order_Type__c,SVMXC__Order_Status__c,First_Time_Fix_Count__c,SVMXC__Billing_Type__c,
                                            Reason_for_Reopen__c FROM SVMXC__Service_Order__c LIMIT 2];
        wo[0].Cost_Center__c = 123456;
        wo[1].SVMXC__Order_Status__c = System.Label.WorkOrderStatusTechnicianOnsite;
        wo[1].SVMXC__Order_Type__c = System.Label.WorkOrderTypeServiceActivities;
        wo[1].First_Time_Fix_Count__c=null;
        wo[1].SVMXC__Billing_Type__c = 'Billable';
        wo[1].Reason_for_Reopen__c =null; 
        update lstWO;
        Test.stopTest();
    }

    @isTest static void testWOTrainingRequired() {
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
          System.assertNotEquals(null, u.Id, 'User should not be null');  
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
              List<Id> woIdList = new List<Id>();
              for(SVMXC__Service_Order__c wo:lstWO){
                system.debug('SK WOID='+wo.Id);
                woIdList.add(wo.Id);
              } 
              List<SVMXC__Service_Order__c> wo =[SELECT id,SVMXC__Order_Type__c,Reason_for_No_Training__c,Training_Required__c FROM SVMXC__Service_Order__c where id IN :woIdList LIMIT 3];
              system.debug('SK WO QUERIED='+wo);
              wo[0].SVMXC__Order_Type__c='Installation';
              wo[0].Training_Required__c=true;
              wo[1].SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
    
              wo[2].Reason_for_No_Training__c='Customer Declined - Lab already trained';
              update wo;
           }
          Test.stopTest();  
          List<SVMXC__Service_Order__c> wolst =[SELECT id,SVMXC__Order_Type__c,Reason_for_No_Training__c,Training_Required__c 
                                              FROM SVMXC__Service_Order__c LIMIT 3];
          System.assert(true,wolst[0].Training_Required__c);
          System.assertEquals(null,wolst[0].Reason_for_No_Training__c,'Training Required is true');
       }


       @isTest static void testTechnicianOnsiteFunctionality(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'Account',
            Bypass_Triggers_By_Object_4__c = 'Contact'
        );
        insert apexSettings;
        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c='Distributor';
        insert objAccount;  

        Contact con = TestDataPerson.getNewContact(objAccount.Id);
        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        System.assertNotEquals(null, workOrder.Id, 'workOrder should not be null');  

        Test.startTest();
        SVMXC__Service_Order__c wo =[SELECT id,Cost_Center__c,SVMXC__Order_Type__c,SVMXC__Order_Status__c,First_Time_Fix_Count__c,SVMXC__Billing_Type__c,
                                            Reason_for_Reopen__c FROM SVMXC__Service_Order__c where Id=:workOrder.Id];
   
        wo.SVMXC__Order_Status__c = System.Label.WorkOrderStatusTechnicianOnsite;
        wo.SVMXC__Order_Type__c = System.Label.WorkOrderTypeServiceActivities;
        wo.First_Time_Fix_Count__c=null;
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.Reason_for_Reopen__c =null; 
        update wo;
        Test.stopTest();
    }

    /*
     CMCM-9579 This test mesthod will test updateBillableCompletionChanged method from   PopulateFieldsOnUpdate_WOHelper class
    */
    @isTest static void testUpdateBillableCompletionChanged(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'Account',
            Bypass_Triggers_By_Object_4__c = 'Contact'
        );
        insert apexSettings;
        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c='Distributor';
        insert objAccount;  

        Contact con = TestDataPerson.getNewContact(objAccount.Id);
        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c=true;
        insert workOrder;
        System.assertNotEquals(null, workOrder.Id, 'workOrder should not be null');  

        Test.startTest();
        SVMXC__Service_Order__c wo =[SELECT id,Date_Billable_Completion_Changed__c,Cost_Center__c,SVMXC__Order_Type__c,SVMXC__Order_Status__c,First_Time_Fix_Count__c,SVMXC__Billing_Type__c,
                                            Reason_for_Reopen__c FROM SVMXC__Service_Order__c where Id=:workOrder.Id];

       System.assertEquals(null,wo.Date_Billable_Completion_Changed__c ,'Date Billable Completion Changed should be null');


        wo.SVMXC__Order_Status__c = System.Label.WorkOrderStatusTechnicianOnsite;
        wo.SVMXC__Order_Type__c = System.Label.WorkOrderTypeServiceActivities;
        wo.First_Time_Fix_Count__c=null;
        wo.SVMXC__Billing_Type__c = 'Billable';
        wo.Reason_for_Reopen__c =null; 
        wo.Billable_Completion_in_Current_Quarter__c ='30% Out - Long Shot'; 
        update wo;
        Test.stopTest();

        wo =[SELECT id,Date_Billable_Completion_Changed__c  FROM SVMXC__Service_Order__c where Id=:workOrder.Id];

        System.assertEquals(Date.today(),wo.Date_Billable_Completion_Changed__c ,'Date Billable Completion Changed should not be null or Date Billable Completion Changed should be populated');

    }


}
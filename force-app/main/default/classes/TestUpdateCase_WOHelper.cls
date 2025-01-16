/***************************************************************************************************************************************
* @author Shivani Jain
* @date 12-Jan-2023
*
* @description DCP-52364 Test class for UpdateCase_WOHelper 
* MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dhairya                 24 Sept 24            No change
*
****************************************************************************************************************************************/ 
@isTest
public with sharing class TestUpdateCase_WOHelper {

    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    /*******************************************************************************************************
    * @description setup data
    */
    @testSetup
    public static void initializeTestData() {
        
        Account acc = TestDataAccount.getAccount('Test Account', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assertNotEquals(null, acc.Id, 'Account Insertion failed');

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact Insertion failed');
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    /*******************************************************************************************************
    * @description Test Method for UpdateCases method
    */
    static testmethod void testUpdateCases() {

        Account acc = [SELECT id FROM Account LIMIT 1];
        Case cs = [SELECT id FROM Case LIMIT 1];

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;

        SVMXC__Service_Contract__c objServiceContract= TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;

        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract1.SVMXC__Service_Level__c = objServiceLevel.Id;
        objServiceContract1.ERP_Contract_Type__c = 'Software (ZWS)';
        objServiceContract1.Registration_Contact_Email__c = 'test@test.com';
        objServiceContract1.Domain_ID__c = 'Test';
        objServiceContract1.Domain_URL_Pattern__c='Test';
        objServiceContract1.Workgroup_Name__c = 'Test';
        insert objServiceContract1;
        Test.startTest();
        //insert objInstalledProduct;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        insert objInstalledProduct;
         
        // Insert Covered Product
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;   
        

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Family='NextSeq - NSQ - Dx';
        insert objProduct;
        System.assertNotEquals(null, objProduct.Id, 'Product Insertion failed');        

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Case__c = cs.Id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.Subscription__c = objServiceContract1.Id;
        WorkOrders.skipWOTrigger = true;
        insert workOrder;
        Test.stopTest();
        workOrder.Subscription__c = null;
        workOrder.Product_Serial_Number__c = 'Test1';
        WorkOrders.skipWOTrigger = false;
        update workOrder;
       
        
    }

    /*******************************************************************************************************
    * @description Test Method for UpdateCaseifWOisClosedasDuplicate method
    */
    static testMethod void testUpdateCaseifWOisClosedasDuplicate() {  
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        Account objAccount =TestDataAccount.initAccount();
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;

        Contact conRec =TestDataContact.getNewContact(objAccount);
        
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
        Case objCaseRecord  = new Case(
            Subject = 'Test subject' ,
            Description= 'Test description',
            Origin = 'Phone-CP',
            Status = 'Initiated',
            Date_of_Issue_Awareness__c=System.today() -2,
            ContactId = conRec.Id,
            RecordTypeId = idCaseRecordTypeId,
            Awareness_Date_Difference_Reason__c ='Logistical delay',
            Has_Closed_Duplicate_WO__c = false
        );
        
        Cases.skipCaseTrigger = true;
        insert objCaseRecord ;
		System.assert(objCaseRecord.Id != NULL, 'Case insertion failed');

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, objCaseRecord.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true; 
        WorkOrders.skipWOTrigger = true;
        insert workOrder;

        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        cs.Bypass_All_Validations__c = true;
        upsert cs cs_Apex_Settings__c.Id;
        
        Test.startTest();
        SVMXC__Service_Order__c objWorkOrder = [SELECT id, OwnerID 
                                                FROM SVMXC__Service_Order__c 
                                                WHERE SVMXC__Case__c = :objCaseRecord.Id 
                                                AND SVMXC__Order_Status__c NOT IN ('Closed', 'Completed') 
                                                LIMIT 1];

        Test.stopTest();
        objWorkOrder.SVMXC__Order_Status__c = 'Closed-Duplicate';
        WorkOrders.skipWOTrigger = false;
        UPDATE objWorkOrder;
    }

    /*******************************************************************************************************
    * @description Test Method for Dispatch Console functionality
    */
    @isTest static void testDispatchFSE() {
        Account acc = [SELECT id FROM Account LIMIT 1];

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
            LastName = 'last',
            Email = 'test@testuser.com',
            Username = 'test@testuser.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        insert u;
        System.assertNotEquals(null, u.Id);
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
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
        System.assertNotEquals(null, grpMembers.Id, 'Field Support should not be Null');

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
            User_Role__c = 'Secondary Field Service Engineer'
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

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        Test.startTest();
        insert workOrder;
        System.assertNotEquals(null, workOrder.Id, 'WO should not be NULL');
        workOrder.Dispatch_Source__c = 'Coordinator';
        workOrder.OwnerId = [SELECT id FROM Group WHERE DeveloperName = 'Field_Service_Coordination_EUR_North'][0].Id;
        update workOrder;

        Integer invocations = Limits.getEmailInvocations();
        //system.assert(invocations > 0, 'An email should be sent');
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Test Method for updateCaseToAcceptOrReject method
    */
    static testMethod void testupdateCaseToAcceptOrReject() {  
        
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        cs.Bypass_All_Validations__c = true;
        upsert cs cs_Apex_Settings__c.Id;

        Account objAccount =TestDataAccount.initAccount();
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;

        Contact conRec =TestDataContact.getNewContact(objAccount);
        
        WorkOrders.skipWOTrigger = false;
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
        Case objCaseRecord  = new Case(
            Subject = 'Test subject' ,
            Description= 'Test description',
            Origin = 'Phone-CP',
            Status = 'Initiated',
            Date_of_Issue_Awareness__c=System.today() -2,
            ContactId = conRec.Id,
            RecordTypeId = idCaseRecordTypeId,
            Awareness_Date_Difference_Reason__c ='Logistical delay',
            Has_Closed_Duplicate_WO__c = false
        );
        
        Test.StartTest();
        INSERT objCaseRecord ;
		System.assert(objCaseRecord.Id != NULL, 'Case insertion failed'); 
        SVMXC__Service_Order__c objWorkOrder  = [SELECT id,Product_Serial_Number__c , Reopen_Request_Initiated_From_WO__c 
                                                FROM SVMXC__Service_Order__c 
                                                WHERE SVMXC__Case__c=: objCaseRecord.Id];

        SVMXC__Service_Order__c updateWO = new SVMXC__Service_Order__c(id=objWorkOrder.id);
        updateWO.Product_Serial_Number__c = 'Test1';
        updateWO.Reopen_Request_Initiated_From_WO__c = true;
        UPDATE updateWO;
        
        SVMXC__Service_Order__c objWorkOrder1  = [SELECT id,Reopen_Request_Initiated_From_WO__c
                                                FROM SVMXC__Service_Order__c 
                                                WHERE SVMXC__Case__c=: objCaseRecord.Id];

        Assert.areEqual(false, objWorkOrder1.Reopen_Request_Initiated_From_WO__c);
        Test.StopTest();
    }

    /*******************************************************************************************************
    * @description Test Method for updateCaseToAcceptOrReject method
    */
    static testMethod void testWorkOrderReopenApproval(){

        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        cs.Bypass_All_Validations__c = true;
        upsert cs cs_Apex_Settings__c.Id;

        Account objAccount =TestDataAccount.initAccount();
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;

        Contact conRec =TestDataContact.getNewContact(objAccount);
        
        WorkOrders.skipWOTrigger = true;
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
        Case objCaseRecord  = new Case(
            Subject = 'Test subject' ,
            Description= 'Test description',
            Origin = 'Phone-CP',
            Status = 'Initiated',
            Date_of_Issue_Awareness__c=System.today() -2,
            ContactId = conRec.Id,
            RecordTypeId = idCaseRecordTypeId,
            Awareness_Date_Difference_Reason__c ='Logistical delay',
            Has_Closed_Duplicate_WO__c = false
        );
        
        INSERT objCaseRecord ;
		System.assert(objCaseRecord.Id != NULL, 'Case insertion failed'); 

        // Retrieve the created work order from the setup method
        SVMXC__Service_Order__c workOrder = [SELECT Id, SVMXC__Order_Status__c 
                                            FROM SVMXC__Service_Order__c 
                                            WHERE SVMXC__Case__c=: objCaseRecord.Id];
        
        // Update the Work Order to trigger the flow
        workOrder.SVMXC__Order_Status__c = 'Reopen Requested';
        workOrder.Reason_for_Reopen__c = 'Reason';
        update workOrder;
        
        Map<String, Object> flowInputs = new Map<String, Object>{
            'WorkOrderId' => workOrder.Id,
            'ActionType' => 'Reopen'  // Assuming there is a branch for denial in the flow
        };
        
        Test.startTest();
        
        // Invoke the Flow using Flow.Interview
        Flow.Interview.Email_Alert_for_Reopen_Request flow = new Flow.Interview.Email_Alert_for_Reopen_Request(flowInputs);
        flow.start();
        //List<EmailMessage> emails = [SELECT Id from EmailMessage LIMIT 1];
        //system.assertEquals(true,emails.size()>0); 
        Test.stopTest();
    }
}
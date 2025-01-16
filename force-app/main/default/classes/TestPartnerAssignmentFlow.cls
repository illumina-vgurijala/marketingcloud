/***************************************************************************************************************************************
* NAME   : TestPartnerAssignmentFlow
* DESCRIPTION  : For Covering the "Work Order Partner Assignment Flow"
*    
* @AUTHOR : Abhishek
* @DATE   : 5-Oct-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek             5-Oct-2023              Initial Version (CMCM-3823)
****************************************************************************************************************************************/ 
@isTest
public class TestPartnerAssignmentFlow {
    public static final String STRING_WO_ORDER_TYPE_RELOCATION = 'Relocation';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
     
    /**
    *  @author Abhishek
    *  @description - Inserted test data 
    **/
    @testSetup
    public static void initializeTestData() {
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount.Account_Group__c = 'Distributor';
        insert objAccount;
        
        Contact objContact = TestDataContact.getNewContact(objAccount);
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Service' LIMIT 1].id;    
        User lstUser = TestDataUser.initPartnerUser(profileId, objContact.id);
        insert lstUser;
        Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
        cp.SetupOwnerId = lstUser.profile.id;
        cp.Is_Channel_Partner__c = True;
        insert cp;
        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', lstUser.ContactId);
        objCase.GTS_Status__c = 'Request Initiated';
        update objCase;
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        SVMXC__Service_Group_Members__c technicianFAS = TestDataFieldService.createTechnician(lstUser.id,'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c = 'b@b.com';
        technicianFAS.SVMXC__Salesforce_User__c = lstUser.Id;
        technicianFAS.SVMXC__Active__c = true;
        insert technicianFAS;
         Account_to_Field_Support__c afs = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                          Account__c = objAccount.Id,User_Role__c = 'Primary Field Service Engineer');
        insert afs;
         SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c = STRING_WO_ORDER_TYPE_RELOCATION;
        objWorkOrder.Customer_Requested_Not_To_Re_Install__c = true;
        objWorkOrder.Record_Created_from_SFM__c = true;
        objWorkOrder.DCIR_Status__c = 'Open';
        objWorkOrder.SVMXC__Case__c = objCase.Id;
        objWorkOrder.OwnerId = lstUser.Id;
        objWorkOrder.SVMXC__Contact__c = objContact.Id;
        objWorkOrder.Field_Support_User_Role__c = 'Field Service Manager';
        objWorkOrder.SVMXC__Group_Member__c = technicianFAS.Id;
        insert objWorkOrder;
    }
    
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testAssignmnent() {

        Test.startTest();
        SVMXC__Service_Order__c objWorkOrder = [Select Id,SVMXC__Order_Type__c,Customer_Requested_Not_To_Re_Install__c,Record_Created_from_SFM__c,DCIR_Status__c,
                                               SVMXC__Case__c,OwnerId,Field_Support_User_Role__c,SVMXC__Group_Member__c  
                                                From SVMXC__Service_Order__c LIMIT 1];

        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('WorkOrderId' , objWorkOrder.id);
        
        Flow.Interview flw = new Flow.Interview.Work_Order_Partner_Assignment_Flow (inputs);
        flw.start();
        Test.stopTest();
        sObject objWorkOrders = (SVMXC__Service_Order__c)flw.getVariableValue('ObjWorkOrder');
        Assert.isTrue(objWorkOrders != null); 
        sObject objUser = (User)flw.getVariableValue('ObjUser');
        Assert.isTrue(objUser != null); 
        sObject objContact2 = (Contact)flw.getVariableValue('ObjContact');
        Assert.isTrue(objContact2 != null);
        sObject objAccountToFieldSupport = (Account_to_Field_Support__c)flw.getVariableValue('ObjAccountToFieldSupport');
        Assert.isTrue(objAccountToFieldSupport != null);
        sObject objFieldSupport = (SVMXC__Service_Group_Members__c)flw.getVariableValue('ObjFieldSupport');
        Assert.isTrue(objFieldSupport != null);
    }
    
    /**
    *  @author Abhishek
    *  @description - Negative Testing 
    **/
    @isTest
    public static void testAssignmnentException() {
        Test.startTest();
        Account objAccount = [Select Id From Account Limit 1];
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('WorkOrderId' , objAccount.Id);
        
        Flow.Interview flw = new Flow.Interview.Work_Order_Partner_Assignment_Flow (inputs);
        flw.start();
        Test.stopTest();
        List<Exception_Log__c> logList = [SELECT Id FROM Exception_Log__c LIMIT 1];
        Assert.isTrue(!logList.isEmpty()); 
    }
}
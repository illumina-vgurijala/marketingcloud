/**
*    @author Gladis
*    @date   2021-08-20
*    @description  CMCP-11:Test Class for FetchUserEmailIds
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Gladis                       20-Aug-2021         InitialVersion
*         Gladis                       06-Sep-2021        CMCP-10 : updated method testFetchEmails to test custom notifications for the users
*         Nishan Shetty                15-Sep-2021        CMCP-158: Send Notifications.
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
public class TestFetchUserEmailIds {

    /**
    *  @author Gladis
    *  @description - Setup Method
    **/
    @testSetup
    static void initiallizeData() { 

        //Fetch CP User
        Id profileId = [select id from profile where name='Channel Partner Service'].id;
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{thisUser.Id});
        objUser1.Email = 'gladg@deloitte.com';
        Update objUser1;
        TestDataUser.allowUserCreation(objUser1.Id);
        User objUser;

        //Create Account
        Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
        objAccount.Account_Group__c='Distributor';
        Insert objAccount;
        
        //Create Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);

        System.runAs(objUser1) {
            //Created User
            objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
           // objUser.UserRoleId=ur.Id;
            insert objUser;
           
                
            Product2 product1 = TestDataMaster.createProduct(true);
            product1.Source_System__c = 'SAP';
            update product1;

            Case objCase = TestDataCase.initServiceRequestCase(objContact);
            objCase.SVMXC__Product__c = product1.Id;
            insert objCase;

            SVMXC__Service_Group__c objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
            insert objGrp;
                
            //Insert Field Support
            SVMXC__Service_Group_Members__c objGrpMember = new SVMXC__Service_Group_Members__c();
            objGrpMember.SVMXC__Active__c = true;
            objGrpMember.Name = 'Test Technician';
            objGrpMember.SVMXC__Service_Group__c = objGrp.Id;
            objGrpMember.SVMXC__Salesforce_User__c = objUser1.Id;
            objGrpMember.SVMXC__Inventory_Location__c = null;
            insert objGrpMember;

            //Insert AccountToFieldSupport
            List<Account_to_Field_Support__c> lstA2fs = new List<Account_to_Field_Support__c>();
            Account_to_Field_Support__c a2fs = new Account_to_Field_Support__c();
            a2fs.Account__c = objAccount.Id;
            a2fs.User__c = objGrpMember.Id;
            a2fs.User_Role__c = 'Primary Field Service Engineer';
            lstA2fs.add(a2fs);

            Account_to_Field_Support__c a2fs2 = new Account_to_Field_Support__c();
            a2fs2.Account__c = objAccount.Id;
            a2fs2.User__c = objGrpMember.Id;
            a2fs2.User_Role__c = 'Customer Care Specialist';
            a2fs2.Enable_Notifications_For__c = 'Parts Order Notification';
            lstA2fs.add(a2fs2);

            Insert lstA2fs;
        }
       
        
    }

    /**
    *  @author Gladis
    *  @description - test method for FetchEmails
    **/
    static testMethod void testFetchEmails() {
        Account objAccount=[Select id,name from Account where name='Test Acc2354' Limit 1];
        list<string>  lstEnabledNotifications = new list<string>{'Parts Order Notification'}; 
        list<string> lstUserroles = new list<string>();

        FetchUserEmailIds.FlowInputs fInputs = new FetchUserEmailIds.FlowInputs();
        fInputs.strAccountId = objAccount.Id;
        fInputs.lstUserRoles = lstUserroles;
        fInputs.lstEnabledNotifications = lstEnabledNotifications;
        fInputs.strRecordId = objAccount.Id;
        fInputs.strRecordName = 'Test';
        fInputs.strRequestor = 'Test Requestor';
        fInputs.boolPartnerUser=false;
        fInputs.boolGTSBlock=false;
        
        test.startTest();
        list<string> lstUsers = FetchUserEmailIds.setFlowInputs(new list<FetchUserEmailIds.FlowInputs>{fInputs});
        system.assertEquals('gladg@deloitte.com', lstUsers[0], 'Email Users');
        test.stopTest();

    }

   
    
    /**
    *  @author Gladis
    *  @description - CMCP-11 Test Class for FetchUserEmailIds Exception.
    **/
    static testmethod void testException() { 

        FetchUserEmailIds.FlowInputs fInputs = new FetchUserEmailIds.FlowInputs();
        fInputs.strAccountId = null;
        fInputs.lstUserRoles = null;
        fInputs.lstEnabledNotifications = null;
        fInputs.strRecordId = null;
        fInputs.strRecordName = null;
        fInputs.strRequestor = null;
        fInputs.boolPartnerUser=false;
        fInputs.boolGTSBlock=false;
        
        Test.startTest();
        list<string> lstUsers = FetchUserEmailIds.setFlowInputs(new list<FetchUserEmailIds.FlowInputs>{fInputs});
        system.assertEquals(new List<String>(), lstUsers, 'Catch Block ');
        Test.stopTest();
    }

     /**
    *  @author Nishan Shetty CMCP-158
    *  @description - test method for FetchEmails for GTS Work Order Relocation CMCP-158
    **/
    static testMethod void testFetchEmailsForRelocationGTSBlock() {
        Account objAccount=[Select id,name from Account where name='Test Acc2354' Limit 1];
        Case objCase=[Select id from Case Limit 1];
        list<string>  lstEnabledNotifications = new list<string>{'Relocation Work Order Notification'}; 
        list<string> lstUserroles = new list<string>();
        lstUserroles.add('Partner Primary Field Service Engineer');
        lstUserroles.add('Primary Field Service Engineer');

        FetchUserEmailIds.FlowInputs fInputs = new FetchUserEmailIds.FlowInputs();
        fInputs.strAccountId = objAccount.Id;
        fInputs.lstUserRoles = lstUserroles;
        fInputs.lstEnabledNotifications = lstEnabledNotifications;
        fInputs.strRecordId = objCase.Id;
        fInputs.strRecordName = 'Test';
        fInputs.strRequestor = '234567';
        fInputs.boolPartnerUser=false;
        fInputs.boolGTSBlock=true;
        fInputs.boolGTSRequestFailed=false;
        
        test.startTest();
        list<string> lstUsers = FetchUserEmailIds.setFlowInputs(new list<FetchUserEmailIds.FlowInputs>{fInputs});
        system.assertEquals('gladg@deloitte.com', lstUsers[0], 'Email Users');
        test.stopTest();

    }


     /**
    *  @author Nishan Shetty CMCP-158
    *  @description - test method for FetchEmails for GTS Work Order Relocation CMCP-158
    **/
    static testMethod void testFetchEmailsForRelocationGTSApproved() {
        Account objAccount=[Select id,name from Account where name='Test Acc2354' Limit 1];
        Case objCase=[Select id from Case Limit 1];
        list<string>  lstEnabledNotifications = new list<string>{'Relocation Work Order Notification'}; 
        list<string> lstUserroles = new list<string>();
        lstUserroles.add('Partner Primary Field Service Engineer');
        lstUserroles.add('Primary Field Service Engineer');

        FetchUserEmailIds.FlowInputs fInputs = new FetchUserEmailIds.FlowInputs ();
        fInputs.strAccountId = objAccount.Id;
        fInputs.lstUserRoles = lstUserroles;
        fInputs.lstEnabledNotifications = lstEnabledNotifications;
        fInputs.strRecordId = objCase.Id;
        fInputs.strRecordName = 'Test';
        fInputs.strRequestor = '123456';
        fInputs.boolPartnerUser=false;
        fInputs.boolGTSBlock=false;
        fInputs.boolGTSRequestFailed=false;
        
        test.startTest();
        list<string> lstUsers = FetchUserEmailIds.setFlowInputs(new list<FetchUserEmailIds.FlowInputs>{fInputs});
        system.assertEquals('gladg@deloitte.com', lstUsers[0], 'Email Users');
        test.stopTest();

    }


     /**
    *  @author Nishan Shetty CMCP-158
    *  @description - test method for FetchEmails for GTS Work Order Relocation CMCP-158
    **/
    static testMethod void testFetchEmailsForRelocationGTSRequestFailed() {
        Account objAccount=[Select id,name from Account where name='Test Acc2354' Limit 1];
        Case objCase=[Select id from Case Limit 1];
        list<string>  lstEnabledNotifications = new list<string>{'Relocation Work Order Notification'}; 
        list<string> lstUserroles = new list<string>();
        lstUserroles.add('Partner Primary Field Service Engineer');
        lstUserroles.add('Primary Field Service Engineer');

        FetchUserEmailIds.FlowInputs fInputs = new FetchUserEmailIds.FlowInputs ();
        fInputs.strAccountId = objAccount.Id;
        fInputs.lstUserRoles = lstUserroles;
        fInputs.lstEnabledNotifications = lstEnabledNotifications;
        fInputs.strRecordId = objCase.Id;
        fInputs.strRecordName = 'Test';
        fInputs.strRequestor = '123456';
        fInputs.boolPartnerUser=false;
        fInputs.boolGTSBlock=false;
        fInputs.boolGTSRequestFailed=true;
        
        test.startTest();
        list<string> lstUsers = FetchUserEmailIds.setFlowInputs(new list<FetchUserEmailIds.FlowInputs>{fInputs});
        system.assertEquals('gladg@deloitte.com', lstUsers[0], 'Email Users');
        test.stopTest();

    }
}
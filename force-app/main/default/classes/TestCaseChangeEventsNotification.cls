/* @ author      : Adyasha Satapathy
* @ date         : 01-04-2021
* @ Description  : TestCaseChangeEventsNotification is the test class for the CaseChangeEvents,CaseChangeEventsService,MSNotificationRuleEngine
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Adyasha Satapathy        01-04-2021                  DCP-43907         Initial version
*/
@isTest
public with sharing class TestCaseChangeEventsNotification {

    public static final String STRING_NOTIFICATION_NAME1 = 'Notification Instant';
    public static final String STRING_NOTIFICATION_NAME2 = 'Notification Details Setupsss';
    public static final String STRING_NOTIFICATION_NAME3 = 'Notification Instant2';
    public static final String STRING_CASE_ORIGIN_PHONE_TS = 'Phone - TS';
    public static final String STRING_CASE_REGION_AMR = 'AMR';
    public static final String STRING_DATE_FORMAT = 'MM/dd/yyyy';
     /**
     *  @author      :Adyasha Satapathy
     *  @description :Setup method
     **/
    @TestSetup
    static void setupData()
    {
        Notification_Detail__c objNotification1 = initNotificationDetail();
        objNotification1.Name = STRING_NOTIFICATION_NAME1;
        // POL-18 AC9 keywords replaced from APJ to AMEA
        objNotification1.Rule_Syntax__c = 'Owned By Queue && Subject Contains {Hello} && Account.ERP_Customer_Id__c IN {123456} && Region__c NotEquals AMEA && Description NotEquals {IVD}';
        objNotification1.Is_Instant_Notification__c	= true;
        objNotification1.Trigger_Notification_After_in_HRS__c = NULL;
        objNotification1.Send_Only_During_Office_Hours__c = true;
        
        Notification_Detail__c objNotification2 = initNotificationDetail();
        objNotification2.Name = STRING_NOTIFICATION_NAME2;
        objNotification2.Rule_Syntax__c = 'Owned By Queue && Subject Contains {High,Pri} || Priority Equals Medium';
        objNotification2.Is_Instant_Notification__c	= false;
        objNotification2.Trigger_Notification_After_in_HRS__c = 0;
        objNotification2.Send_Only_During_Office_Hours__c = true;

        Notification_Detail__c objNotification3 = initNotificationDetail();
        objNotification3.Name = STRING_NOTIFICATION_NAME3;
         // POL-18 AC9 keywords replaced from APJ to AMEA
        objNotification3.Rule_Syntax__c = 'Subject Contains {Hello,Subject}';
        objNotification3.Is_Instant_Notification__c	= true;
        objNotification3.Trigger_Notification_After_in_HRS__c = NULL;
        objNotification3.Send_Only_During_Office_Hours__c = false;
        Notification_Detail__c objNotification4 = initNotificationDetail();
        objNotification4.Name = CaseChangeEvents.SETUP_NOTIFICATION_DETAIL;
        objNotification4.Rule_Syntax__c = 'Owner.Name|Owner.type|Subject|Description|OwnerId|Region__c|Origin|AccountId|ContactEmail|Unread_Emails__c|Account.Name|Account.ERP_Customer_Id__c';
        objNotification4.Is_Instant_Notification__c = true;
        objNotification4.Trigger_Notification_After_in_HRS__c = NULL;
        objNotification4.Send_Only_During_Office_Hours__c = false;
        objNotification4.Is_Active__c = false;

        insert new List<Notification_Detail__c>{objNotification1, objNotification2, objNotification3,objNotification4};
        
    }

    /**
     *  @author      :Adyasha Satapathy
     *  @description :test method to test sending of MS Teams notification on creation and updation of cases
     **/
    @isTest
    static void testCaseCreateUpdate()
    {
        Test.enableChangeDataCapture();
        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.ERP_Customer_Id__c = '123456';
        insert objAccount;
        
        Group testGroup = new Group(Name='Customer Service', Type='Queue');
        insert testGroup;
        
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }
        
        List<Case> lstCases = new List<Case>();
        Case objCase1 = TestDataCase.initNewCase(TestCases.STRING_CASE_RECORDTYPENAME, TestCases.STRING_CASE_STATUS, STRING_CASE_ORIGIN_PHONE_TS); 
        objCase1.Subject = 'Test Case Subject World';
        objCase1.Description = 'product identifier Case';
        objCase1.Region__c = STRING_CASE_REGION_AMR;
        objCase1.AccountId = objAccount.Id;

        Case objCase2 = TestDataCase.initNewCase(TestCases.STRING_CASE_RECORDTYPENAME, TestCases.STRING_CASE_STATUS, STRING_CASE_ORIGIN_PHONE_TS); 
        objCase2.Subject = 'Test Subject High Priority';
        objCase2.Priority = 'Medium';
        objCase2.Region__c = STRING_CASE_REGION_AMR;
        objCase2.AccountId = objAccount.Id;
        Test.startTest();
        lstCases.add(objCase1);
        lstCases.add(objCase2);
        insert lstCases;
        Test.getEventBus().deliver();
        
        objCase1.OwnerId = testGroup.Id;
        objCase1.Subject = 'Test Case Subject Hello World';
        update objCase1;

        Case objCase3 = [Select Id,Owner.Name from Case where Id =: objCase1.Id];
        CaseChangeEventsService.getCaseUserGroup(objCase3.Owner.Name);
        Test.getEventBus().deliver();
        Test.stopTest();

        MS_Team_Notification__c objMSNotification = [Select Id, Case__c from MS_Team_Notification__c LIMIT 1];
        System.assertEquals(objCase1.Id, objMSNotification.Case__c,'MS Notification not inserted with right case');
    }

     /**
     *  @author      :Adyasha Satapathy
     *  @description :test method to test scheduled batch functionality for sending scheduled MS Teams notifications
     **/
    @isTest
    static void testScheduledCaseNotifications()
    {
        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.ERP_Customer_Id__c = '123456';
        insert objAccount;

        Case objCase1 = TestDataCase.initNewCase(TestCases.STRING_CASE_RECORDTYPENAME, TestCases.STRING_CASE_STATUS, STRING_CASE_ORIGIN_PHONE_TS); 
        objCase1.Subject = 'Test Case Subject World';
        objCase1.Description = 'product identifier Case';
        objCase1.Region__c = STRING_CASE_REGION_AMR;
        objCase1.AccountId = objAccount.Id;

        insert objCase1;

        Notification_Detail__c objNotificationDetail = [Select Id,Is_Active__c,Recipient_Name__c from Notification_Detail__c where Is_Instant_Notification__c = false LIMIT 1];
        
        MS_Team_Notification__c objMSNotification = new MS_Team_Notification__c();
        objMSNotification.IsActive__c = true;
        objMSNotification.Notification_Detail__c = objNotificationDetail.Id;
        objMSNotification.Case__c = objCase1.Id;
        
        insert objMSNotification;
        
        Test.startTest();
        
        ScheduleBatchSendCaseTeamsNotification schedule =  new ScheduleBatchSendCaseTeamsNotification();
        schedule.execute(null);
        
        Test.stopTest();

        MS_Team_Notification__c objMSNotification2 = [Select Id, Last_NotificationTime__c from MS_Team_Notification__c where Id =: objMSNotification.Id];
        System.assertEquals(System.now().format(STRING_DATE_FORMAT),objMSNotification2.Last_NotificationTime__c.format(STRING_DATE_FORMAT),'Notification not sent');
        Notification_Detail__c objNotification = initNotificationDetail();
        objNotification.Name = 'ND1';
         // POL-18 AC9 keywords replaced from APJ to AMEA
        objNotification.Rule_Syntax__c = 'Owned By Queue && Subject Contains {Hello} && Account.ERP_Customer_Id__c IN {123456} && Region__c NotEquals AMEA && Description NotEquals {IVD}';
        objNotification.Is_Instant_Notification__c = true;
        objNotification.Trigger_Notification_After_in_HRS__c = NULL;
        objNotification.Send_Only_During_Office_Hours__c = true;
        insert objNotification;
         // POL-18 AC9 keywords replaced from APJ to AMEA
        objNotification.Rule_Syntax__c = 'Owned By Queue && Subject Contains {Hello} && Account.ERP_Customer_Id__c IN {123456} && Region__c NotEquals AMEA && Description NotEquals {IVD12}';
        update objNotification;

    }
	 /**
     *  @author      :Adyasha Satapathy
     *  @description : test method for Notification Details.
     **/
    public static Notification_Detail__c initNotificationDetail()
    {
        Notification_Detail__c objNotification = new Notification_Detail__c();
        objNotification.Is_Active__c = true;
        objNotification.Description__c = 'Testing Description';
        objNotification.Notification_Template__c = 'Few cases are not assigned please take a look.';
        objNotification.MS_Teams_Recipient__c = '123@illumina.com';
        objNotification.Region__c = STRING_CASE_REGION_AMR;
        objNotification.User_Group__c = 'TS';
        objNotification.Recipient_Name__c = 'User';
        return objNotification;
    }

}
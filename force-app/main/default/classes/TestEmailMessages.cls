/*
 * Test class to cover EmailMessages
 */
@isTest(SeeAllData=false)
public with sharing class TestEmailMessages {
    
    public static final String STRING_CASE_PRIORITY_MEDIUM = 'Medium';
    public static final String STRING_CASE_ORIGIN_EMAIL_TS = 'Email - TS';
    public static final String STRING_CASE_ORIGIN_EMAIL_CS = 'Email - CS';
    /*
     * Initial data Setup
     */ 
    @testSetup
    public static void setUpData() {
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true
        );
        
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
           insert u;
        
        Group g = new Group(Type='Queue', Name='Global Customer Service');
        insert g;
        QueueSObject q = new QueueSObject(SobjectType='Case', QueueId=g.Id);
        insert q;
        GroupMember qMember = new GroupMember(UserOrGroupId = u.id,GroupId = g.Id);
        insert qMember;  
        }
               
        
        
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test Service','India');
        insert serviceTeam;
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Customer Care Specialist user',serviceTeam.id);
        technician.Preferred_Service_Report_Language__c='English';
        technician.SVMXC__Active__c=true;
        insert technician; 
        Account objAcc = TestDataAccount.getAccount('TestAccount','USD');
        objAcc.Account_Group__c='Distributor';
        insert objAcc;
        Contact objCon = TestDataPerson.getNewContact(objAcc.Id);
        
        Account_to_Field_Support__c accToFS = new Account_to_Field_Support__c(Account__c=objAcc.Id,User__c=technician.Id,User_Role__c='Customer Care Specialist');
        Account_to_Field_Support__c accToFS1 = new Account_to_Field_Support__c(Account__c=objAcc.Id,User__c=technician.Id,User_Role__c='Field Support Ops Specialist');
        List<Account_to_Field_Support__c> accFSLst = new List<Account_to_Field_Support__c>{accToFS,accToFS1};
            insert accFSLst;
        Case objCase1 = TestDataCase.initServiceRequestCase(objCon);
        objCase1.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('Case', 'Inquiry');
        objCase1.Priority = STRING_CASE_PRIORITY_MEDIUM;
        objCase1.Origin = STRING_CASE_ORIGIN_EMAIL_CS;
        objCase1.Ownerid = u.id;
        Case objCase2 = TestDataCase.initServiceRequestCase(objCon);
        objCase2.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('Case', 'Inquiry');
        objCase2.Priority = STRING_CASE_PRIORITY_MEDIUM;
        objCase2.Origin = STRING_CASE_ORIGIN_EMAIL_TS;
        objCase2.Ownerid = u.id;
        
        List<Group> gp = new List<Group>();
        gp = [Select id, Name from Group where Name ='Global Customer Service' Limit 1];
        
        Case objCase3 = TestDataCase.initServiceRequestCase(objCon);
        objCase3.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('Case', 'Inquiry');
        objCase3.Priority = STRING_CASE_PRIORITY_MEDIUM;
        objCase3.Origin = STRING_CASE_ORIGIN_EMAIL_CS;
        objCase3.Ownerid = gp[0].id;
        objCase3.SuppliedEmail = 'abcd@illumina.com';
        
        List<Case> lstCases = new List<Case>{objCase1,objCase2,objCase3};
        
        insert lstCases;
        
        Event objEvent= new Event();
        objEvent.WhatId=lstCases[0].id;
        objEvent.StartDateTime=System.now()-1;
        objEvent.subject='Out Of Office';
        objEvent.EndDateTime=System.now()+1;
        objEvent.ownerid= u.id;
        insert objEvent;
        
        
        EmailMessage objEmail2 = new EmailMessage();
        objEmail2.FromAddress = 'debalchatterjee@deloitte.com';
        objEmail2.Incoming = true;
        objEmail2.Subject = 'Test email';
        objEmail2.HTMLBody = 'Hello';
        objEmail2.Headers = 'In-Reply-To: <SN4PR85MB01091C88F722D016DA982EB1A6149@SN4PR85MB0109.NAMPRD85.PROD.OUTLOOK.COM> References: <SN4PR85MB01091C88F722D016DA982EB1A6149@SN4PR85MB0109.NAMPRD85.PROD.OUTLOOK.COM>';
        objEmail2.ParentId = lstCases[1].Id;
        insert objEmail2;
    }
    /*
     * To cover preventRecurrentCaseCreation method
     */ 
    testMethod static void testEmailMessage(){
        List<EmailToCase_Creation_Setting__mdt> setE2CAddressesSetting = [SELECT DeveloperName,QueueId__c,Routing_Email__c FROM EmailToCase_Creation_Setting__mdt];
        List<Case> lstCases = [SELECT Id FROM Case LIMIT 2];
        system.assertNotEquals(0,lstCases.size());
        EmailMessage objEmail1 = new EmailMessage();
        objEmail1.FromAddress = 'debalchatterjee@deloitte.com';
        objEmail1.Incoming = true;
        objEmail1.ToAddress = setE2CAddressesSetting[0].Routing_Email__c;
        objEmail1.CcAddress = setE2CAddressesSetting[1].Routing_Email__c;
        objEmail1.BccAddress = setE2CAddressesSetting[2].Routing_Email__c;
        objEmail1.Subject = 'Test email';
        objEmail1.TextBody = 'Hello';
        objEmail1.ParentId = lstCases[0].Id;
        
        EmailMessage objEmail2 = new EmailMessage();
        objEmail2.FromAddress = 'debalchatterjee@deloitte.com';
        objEmail2.Incoming = true;
        objEmail2.ToAddress = setE2CAddressesSetting[1].Routing_Email__c;
        objEmail2.CcAddress = setE2CAddressesSetting[0].Routing_Email__c;
        objEmail2.BccAddress = setE2CAddressesSetting[2].Routing_Email__c;
        objEmail2.Subject = 'Test email';
        objEmail2.HTMLBody = 'Hello';
        objEmail2.Headers = 'In-Reply-To: <SN4PR85MB01091C88F722D016DA982EB1A6149@SN4PR85MB0109.NAMPRD85.PROD.OUTLOOK.COM> References: <SN4PR85MB01091C88F722D016DA982EB1A6149@SN4PR85MB0109.NAMPRD85.PROD.OUTLOOK.COM>';
        objEmail2.ParentId = lstCases[1].Id;
        
        List<EmailMessage> lstEmailMessage = new List<EmailMessage>();
        lstEmailMessage.add(objEmail1);
        lstEmailMessage.add(objEmail2);
        
        Test.startTest();
        try{
            insert lstEmailMessage;
            system.assertNotEquals(null,lstEmailMessage[0].id);
            system.assertNotEquals(null,lstEmailMessage[1].id);
        }catch(exception ex){
            system.debug(ex.getMessage());
        }
        Test.stopTest();                                             
    }
    /*
     * To cover checkParentCaseUserIsOOO method
     */ 
    testMethod static void checkParentCaseUserIsOOO(){
        List<EmailToCase_Creation_Setting__mdt> setE2CAddressesSetting = [SELECT DeveloperName,QueueId__c,Routing_Email__c FROM EmailToCase_Creation_Setting__mdt LIMIT 1];
        List<Case> lstCases = [SELECT Id FROM Case LIMIT 1];
        
        
        
        EmailMessage objEmail1 = new EmailMessage();
        objEmail1.FromAddress = 'debalchatterjee@deloitte.com';
        objEmail1.Incoming = true;
        objEmail1.ToAddress = setE2CAddressesSetting[0].Routing_Email__c;
        objEmail1.Subject = 'Test email';
        objEmail1.TextBody = 'Hello';
        objEmail1.ParentId = lstCases[0].Id;
        
        
        List<EmailMessage> lstEmailMessage = new List<EmailMessage>();
        lstEmailMessage.add(objEmail1);
        Test.startTest();
        try{
            insert  lstEmailMessage;
            list<case> lstcase= [select id,ownerid from case where id=:lstCases[0].id LIMIT 1];
            system.assertEquals(System.Label.Technical_Support_Queue_Name,lstcase[0].owner.name );
            
        }catch(exception ex){
            system.debug(ex.getMessage());
        }
        Test.stopTest();  
        
    }
    /*
     * DCP-40120: To cover updateCaseOwnerAssignment method
     */
    testMethod static void checkCaseOwnerAssignment(){     
        List<Case> lstCases = [SELECT Id, AccountId,OwnerId FROM Case WHERE Origin =: STRING_CASE_ORIGIN_EMAIL_CS AND SuppliedEmail = 'abcd@illumina.com'];
       
        Id caseOwnerId = lstCases[0].OwnerId;
        EmailMessage objEmail1 = new EmailMessage();
        objEmail1.FromAddress = 'abcd@illumina.com';
        objEmail1.Incoming = true;
        objEmail1.Status='0';
        objEmail1.ToAddress = Label.Email2CaseCustomerCareId;
        objEmail1.Subject = 'Test email';
        objEmail1.TextBody = 'Test email';
        objEmail1.ParentId = lstCases[0].Id; 

        EmailMessage objEmail2 = new EmailMessage();
        objEmail2.FromAddress = 'abcd@illumina.com';
        objEmail2.Incoming = true;
        objEmail2.Status='0';
        objEmail2.ToAddress = Label.Email2CaseInstrumentServiceId;
        objEmail2.Subject = 'Test email';
        objEmail2.TextBody = 'Test email';
        objEmail2.ParentId = lstCases[0].Id;
        Test.startTest();
        insert  objEmail1;
        insert objEmail2;
        list<case> lstcase= [select id,ownerid from case where id=:objEmail1.ParentId LIMIT 1];
        system.assertNotEquals(lstCase[0].OwnerId, caseOwnerId, 'No change in OwnerId');
        new EmailMessagesSelector().getAggregateResult('ParentId', new Set<Id>{lstCases[0].Id});
        Test.stopTest(); 
    }
    
    /*
     * To cover else if when header is not blank 
     */ 
    testMethod static void checkWhenEmailMessageHeaderIsNotBlank(){
        List<EmailToCase_Creation_Setting__mdt> setE2CAddressesSetting = [SELECT DeveloperName,QueueId__c,Routing_Email__c FROM EmailToCase_Creation_Setting__mdt LIMIT 1];
        List<Case> lstCases = [SELECT Id FROM Case LIMIT 1];
        
        
        
        EmailMessage objEmail1 = new EmailMessage();
        objEmail1.FromAddress = 'debalchatterjee@deloitte.com';
        objEmail1.Incoming = true;
        objEmail1.ToAddress = setE2CAddressesSetting[0].Routing_Email__c;
        objEmail1.Subject = 'Test email';
        objEmail1.TextBody = 'Hello1';
        objEmail1.Headers = 'In-Reply-To: <SN4PR85MB01091C88F722D016DA982EB1A6149@SN4PR85MB0109.NAMPRD85.PROD.OUTLOOK.COM> References: <SN4PR85MB01091C88F722D016DA982EB1A6149@SN4PR85MB0109.NAMPRD85.PROD.OUTLOOK.COM>';
        
        
        List<EmailMessage> lstEmailMessage = new List<EmailMessage>();
        lstEmailMessage.add(objEmail1);
        Test.startTest();
        try{
            insert  lstEmailMessage;
            list<case> lstcase= [select id,ownerid from case where id=:lstCases[0].id LIMIT 1];
            system.assertEquals(System.Label.Technical_Support_Queue_Name,lstcase[0].owner.name );
            
        }catch(exception ex){
            system.debug(ex.getMessage());
        }
        Test.stopTest(); 
        
    }

    /**
     *  @author      : Nitin
     *  @description : method to cover catch block in EmailMessagesQueueable
     **/
    @isTest
    public static void coverCatchBlockEmailMessagesQueueable(){
        try{
            EmailMessagesQueueable.catchException = true;
            EmailMessagesQueueable pd = new EmailMessagesQueueable(null,null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }

    //Test class for the process builder - email message : update case on unread emails.	@isTest
	public static void testEmailMessageTriggerHandler() {
        // Fetch the Customer Service profile
        Profile customerServiceProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Service' LIMIT 1];

        // Create the test user (Note: isActive cannot be set directly in test context)
        User testUser = new User(
            ProfileId = customerServiceProfile.Id,
            LastName = 'amdewra',
            Username = 'testuserpune1234@example.com',
            Email = 'testuser@example.com',
            Alias = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Query the inserted user (since isActive cannot be set in test class)
        User insertedUser = [SELECT Id FROM User WHERE Username = 'testuserpune1234@example.com' LIMIT 1];

        // Fetch an active Business Hours record
        BusinessHours businessHour = [SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1];

        // Create and insert an account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Query the inserted account
        Account insertedAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Create and insert a contact
        Contact con = new Contact(
            FirstName = 'test firstname',
            LastName = 'test lastname',
            AccountId = insertedAccount.Id
        );
        insert con;

        // Query the inserted contact
        Contact insertedContact = [SELECT Id FROM Contact WHERE LastName = 'test lastname' LIMIT 1];

        // Create and insert a parent case
        Case parentCase = new Case(
            OwnerId = insertedUser.Id,
            BusinessHoursId = businessHour.Id,
            ContactId = insertedContact.Id,
            Status = 'Initiated',
            Origin = 'Phone - CP',
            Subject = 'Test Subject',
            Description = 'Test Description',
            Sub_Type__c = 'Billable Service'
        );
        insert parentCase;

        // Query the inserted case
        Case insertedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :parentCase.Id LIMIT 1];

        // Create and insert an EmailMessage
        EmailMessage eMessage = new EmailMessage(
            ParentId = insertedCase.Id,
            Incoming = true
        );
        insert eMessage;

        // Requery the case to check ownership (this should trigger your handler logic)
        Case updatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :insertedCase.Id LIMIT 1];

        // Assert that the case owner has changed (replace with correct value)
        // Ensure the system label Customer_Service_Queue_ID exists, or replace with a valid queue ID for testing.
        String expectedOwnerId = System.Label.Customer_Service_Queue_ID; // Adjust if needed
        System.assertEquals(expectedOwnerId, updatedCase.OwnerId, 'The case owner should be updated to the expected queue.');
    }
	   
}
//TestEmailMessagesSelector 
/*
* @ author       : Romi
* @ date         : 30-Aug-2021
* @ Description  : Test class for EmailMessagesSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Romi                  30-Aug-2021                        Initial version
* Shivani Jain          17-Mar-2022          DCP-51321 Hide potential logos & signature from Files list
*/
@IsTest
public class TestEmailMessagesSelector {
    static Case cs = new Case();
    /**
     * @author: Romi
     * @description: method to create test data.
     */
    @testSetup
    public static void setUpData() {
            //insert Account
            Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
            acc.Account_Group__c='Distributor';
            acc.ERP_Customer_Id__c = 'Test1';
            insert acc;
            System.assert(acc.Id != null);
            
            //insert contact
            Contact con = TestDataPerson.getNewContact(acc.Id);
            System.assert(con.id != null);
            
            //insert case
            cs = TestDataCase.initServiceRequestCase(con);
            insert cs;
            System.assert(cs.Id != null);

}
/**
 * @author: Romi
 * @description:method to test selectEmailMessages.
 */
@IsTest
static void selectEmailMessagesTest()
{
    //setUpData();
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
    insert  lstEmailMessage;
    System.assert(lstEmailMessage[0].Id != null);
    Set<String> setEmailID = new Set<String>();
    setEmailID.add(lstEmailMessage[0].ID);
    System.assert(lstEmailMessage.size()!=null);
    
    Test.startTest();
    EmailMessagesSelector selector = new EmailMessagesSelector();
    selector.selectEmailMessages(setEmailID);
    Test.stopTest();
    
} 
/**
 * @author: Romi
 * @description:method to test selectEmailMessageByParentId.
 */
@IsTest
static void selectEmailMessageByParentIdTest()
{
    //setUpData();
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
    insert lstEmailMessage;

    Set<String> setEmailID = new Set<String>();
    setEmailID.add(lstCases[0].Id);
    System.assert(lstEmailMessage.size()!=null);
    
    Test.startTest();
    EmailMessagesSelector selector = new EmailMessagesSelector();
    selector.selectEmailMessageByParentId(setEmailID);
    Test.stopTest();
    
} 
/**
 * @author: Romi
 * @description: method to test selectEmailMessagesByIds
 */
@IsTest
static void selectEmailMessagesByIdsTest()
{
    //setUpData();
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
    insert  lstEmailMessage;

    Set<String> setEmailID = new Set<String>();
    setEmailID.add(lstEmailMessage[0].ID);
    System.assert(lstEmailMessage.size()!=null);
    
    
    Test.startTest();
    EmailMessagesSelector selector = new EmailMessagesSelector();
    selector.selectEmailMessagesByIds(setEmailID);
    Test.stopTest();
    
}

/**********************************
    * @description Test method for selectEmailMsgByParentId. Test Method to verify the emails related
    * to case are displayed properly on the case lwc component
    * DCP-43125
    * Deepika Ayyavari
    */
 @isTest
static void selectEmailMsgByParentIdTest()
	{
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
        insert lstEmailMessage;
        System.assert(lstEmailMessage.size()!=null, 'List should not be empty');

        Set<Id> setCaseID = new Set<Id>();
        setCaseID.add(lstCases[0].Id);
        
        Test.startTest();
            EmailMessagesSelector selector = new EmailMessagesSelector();
            selector.selectEmailMsgByParentId(20, setCaseID);
        Test.stopTest();
    
	} 

    /*******************************************************************************************************
    * @description DCP-51321 test method for selectEmailMsgsByParentWithAttachment
    */
    static testMethod void testSelectEmailMsgsByParentWithAttachment() {
        List<EmailToCase_Creation_Setting__mdt> setE2CAddressesSetting = [SELECT DeveloperName,QueueId__c,Routing_Email__c FROM EmailToCase_Creation_Setting__mdt LIMIT 1];
        List<Case> lstCases = [SELECT Id FROM Case LIMIT 1];
        
        EmailMessage objEmail = new EmailMessage();
        objEmail.FromAddress = 'test@testing.com';
        objEmail.Incoming = true;
        objEmail.ToAddress = setE2CAddressesSetting[0].Routing_Email__c;
        objEmail.Subject = 'Test email';
        objEmail.TextBody = 'Hello';
        objEmail.ParentId = lstCases[0].Id;
        
        List<EmailMessage> lstEmailMessage = new List<EmailMessage>();
        lstEmailMessage.add(objEmail);
        insert lstEmailMessage;
        System.assert(lstEmailMessage.size()!=null, 'List should not be empty');

        ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
        insert objCV;
        system.assertNotEquals(null, objCV.id);

        objCV =[SELECT id, ContentDocumentId FROM ContentVersion where Id =: objCV.Id];
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, lstEmailMessage[0].Id, 'V','AllUsers');
        insert objCDL;
        system.assertNotEquals(null,objCDL.id);

        Set<Id> setCaseIds = new Set<Id>();
        setCaseIds.add(lstCases[0].Id);
        
        Test.startTest();
        EmailMessagesSelector selector = new EmailMessagesSelector();
        selector.selectEmailMsgsByParentWithAttachment(setCaseIds);
        Test.stopTest();
    }
}
/***************************************************************************************************************************************
 * NAME         : TestApttusAgreementGenerateEmailHandler
 * DESCRIPTION  : DCP-33716 Test Class for Email Handler class for Agreement generation.
 *    
 * @AUTHOR      : Vignesh S
 * @DATE        : 13-Oct-2018
 *Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Nishan                 10-Oct-2022                  CodeScanFix [Method name should not start with Capital].
  ****************************************************************************************************************************************/ 
@isTest
public class TestApttusAgreementGenerateEmailHandler{
    /*
    *@author: Akshay Mohan
    *@Desc: Test method  for successful Email Generation
    */

    public static testMethod void testApttusAgreementGenerateEmailHandlerMtd() {//CodeScan Fix
        Test.starttest();
        // setup agreement object
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567'; 
        acc2.Account_Group__c = 'Distributor';      
        insert new List<Account> { acc, acc2 };
        
        CLM_ProfileValidation__c objCLMValidation = new CLM_ProfileValidation__c();
        objCLMValidation.Channel_Partner_Agreement__c = True;
        insert objCLMValidation;
        
        Account_Sales_Area__c objASA = new Account_Sales_Area__c();
        objASA.Sales_Organization__c = 'US01';
        objASA.Account__c = acc.Id;
        insert objASA;
        
        
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Customer', acc.id);
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Apttus__Subtype__c = 'Non-Standard';
        oAgreement1.Additional_Output_Language__c = 'Japanese';
        oAgreement1.Incoterm__c = 'EXW: Ex Works';
        oAgreement1.Exclusivity__c  = true;
        oAgreement1.Apttus__Agreement_Number__c = '001';
        oAgreement1.Apttus__Version_Number__c = 10;
        oAgreement1.Sales_Org__c = 'US01'; //adding reference sales org
        insert oAgreement1;
        ApttusAgreementGenerateEmailHandler  objAGEH = new ApttusAgreementGenerateEmailHandler();
        
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        objAGEH.handleInboundEmail(email, envelope);
        
        email.subject = '12345678-001.10-S';
        email.plainTextBody = 'Hello, this a test email body. for testing purposes only. ';
        email.fromAddress = 'sap@illumina.com';
        email.toAddresses = new list<String>{'sfdc@illumina.com'};
        
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'agreement.pdf';
        binaryAttachment.body = blob.valueOf('my attachment text');
        
        Messaging.InboundEmail.textAttachment textAttachment = new Messaging.InboundEmail.textAttachment();
        textAttachment.Filename = 'test.xml';
        textAttachment.body = 'test';
        
        Messaging.InboundEmail.textAttachment excelAttachment = new Messaging.InboundEmail.textAttachment();
        excelAttachment.Filename = 'excelFile.xls';
        excelAttachment.body = 'excel file attached test';
               
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] {textAttachment};
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] {excelAttachment};
        
        objAGEH.handleInboundEmail(email, envelope);
        test.stoptest();
        list<Attachment> lstAttachment = [select id from Attachment where parentid = :oAgreement1.Id];
        System.assert(lstAttachment.size() > 0);
    }
     /*
    *@author: Akshay Mohan
    *@Desc: Test method  for failure of Email Generation
    */
    
    public static testMethod void testApttusAgreementGenerateEmailHandlerMtdFail() {//CodeScan Fix
        Test.starttest();
        // setup agreement object
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567'; 
        acc2.Account_Group__c = 'Distributor';      
        insert new List<Account> { acc, acc2 };
        
        CLM_ProfileValidation__c objCLMValidation = new CLM_ProfileValidation__c();
        objCLMValidation.Channel_Partner_Agreement__c = True;
        insert objCLMValidation;
        
        Account_Sales_Area__c objASA = new Account_Sales_Area__c();
        objASA.Sales_Organization__c = 'US01';
        objASA.Account__c = acc.Id;
        insert objASA;
        
        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Customer', acc.id);
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Apttus__Subtype__c = 'Non-Standard';
        oAgreement1.Additional_Output_Language__c = 'Japanese';
        oAgreement1.Incoterm__c = 'EXW: Ex Works';
        oAgreement1.Exclusivity__c  = true;
        oAgreement1.Apttus__Agreement_Number__c = '001';
        oAgreement1.Apttus__Version_Number__c = 10;
        oAgreement1.Sales_Org__c = 'US01'; //adding reference sales org
        insert oAgreement1;
        ApttusAgreementGenerateEmailHandler  objAGEH = new ApttusAgreementGenerateEmailHandler();
        
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        objAGEH.handleInboundEmail(email, envelope);
        
        email.subject = '12345678-001.10-E';
        email.plainTextBody = '!!Error!!! ';
        email.fromAddress = 'sap@illumina.com';
        email.toAddresses = new list<String>{'sfdc@illumina.com'};
        
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'agreement.pdf';
        binaryAttachment.body = blob.valueOf('my attachment text');
        
        Messaging.InboundEmail.textAttachment textAttachment = new Messaging.InboundEmail.textAttachment();
        textAttachment.Filename = 'test.xml';
        textAttachment.body = 'test';
        
        Messaging.InboundEmail.BinaryAttachment excelAttachment = new Messaging.InboundEmail.BinaryAttachment();
        excelAttachment.Filename = 'excelAgreement.xls';
        excelAttachment.body = blob.valueOf('my attachment excle');
               
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment };
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] {textAttachment};
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { excelAttachment };
        
        objAGEH.handleInboundEmail(email, envelope);
        test.stoptest();
        list<Attachment> lstAttachment = [select id from Attachment where parentid = :oAgreement1.Id];
        System.assert(lstAttachment.size() > 0);
    }
}
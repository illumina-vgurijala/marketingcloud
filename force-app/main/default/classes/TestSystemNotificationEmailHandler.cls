/***************************************************************************************************************************************
 * NAME   : TestSystemNotificationEmailHandler
 * DESCRIPTION  : DCP-11785 Test Class for creation of System notification record.
 *    
 * @AUTHOR : Dipika
 * @DATE   : 17-Oct-2018  
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData=false)
public class TestSystemNotificationEmailHandler{
    /*Test Data*/
    public static testMethod void systemNotificationEmailHandler(){
        
        // setup controller object
        SystemNotificationEmailHandler objconfirm = new SystemNotificationEmailHandler();
        
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        objconfirm.handleInboundEmail(email, envelope);
        
        email.subject = 'Test Subject';
        email.plainTextBody = 'Hello, this a test email body. for testing purposes only. Bye';
        email.fromAddress = 'maf@cloudsocius.com';
        email.toAddresses = new list<String>{'maf@cloudsocius.com','maf@cloudsocius1.com'};
        email.ccAddresses = new list<String>{'maf@cloudsocius.com','maf@cloudsocius1.com'};
        
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'test.pdf';
        binaryAttachment.body = blob.valueOf('my attachment text');
        
        Messaging.InboundEmail.BinaryAttachment binaryAttachment1 = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment1.Filename = 'test.xml';
        binaryAttachment1.body = blob.valueOf('my attachment text');
         
        Messaging.InboundEmail.textAttachment textAttachment = new Messaging.InboundEmail.textAttachment();
        textAttachment.Filename = 'test.xml';
        textAttachment.body = 'test';
        
        Messaging.InboundEmail.textAttachment textAttachment1 = new Messaging.InboundEmail.textAttachment();
        textAttachment1.Filename = 'test.xml';
        textAttachment1.body = 'test';
        
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binaryattachment,binaryAttachment1 };
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] { textAttachment,textAttachment1 };
        
        Messaging.InboundEmailResult result = objconfirm.handleInboundEmail(email, envelope);
        System.assertEquals(true,result.success);
        
    
    }
}
/* Test Class for InboundAttachmentCallback
*/

@istest
public class InboundAttachmentCallbackTest {
    
    /*
    Author - Kush Shah
    */
    static testMethod void testInBoundEmail()   
    {
      TestDataApprovals.getSupportDataForApprovals();  
      Apttus_Proposal__Proposal__c quote =  [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1]; 
      
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      email.subject = 'Create Contact';
      email.fromAddress = 'someaddress@email.com';
      email.plainTextBody = 'email body';
      Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
      attachment.body = blob.valueOf('my attachment text');
      attachment.fileName = 'textfileone.txt';
      attachment.mimeTypeSubType = 'text/plain';
      email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
      
      Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
      attachmenttext.body = 'my attachment text';
      attachmenttext.fileName = 'textfiletwo3.txt';
      attachmenttext.mimeTypeSubType = 'texttwo/plain';
      email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };
      
      Test.StartTest();
      InboundAttachmentCallback oIB = new InboundAttachmentCallback();
      oIB.handleActionAttachment(quote.ID,'APPROVE',email);
      System.assertEquals('Create Contact',email.subject,'Not Found!');
      Test.StopTest();
   }
   
   static testMethod void testInBoundEmailWithPropLineItem()   
   {
     TestDataApprovals.getSupportDataForApprovals();  
     Apttus_Proposal__Proposal__c quote =  [SELECT Id FROM Apttus_Proposal__Proposal__c LIMIT 1]; 
     Product2 objPro = [SELECT id FROM Product2 LIMIT 1];

     Apttus_Proposal__Proposal_Line_Item__c objPropLineItem = TestDataProposal.initProposalLineItem(quote,objPro);
     insert objPropLineItem;

     Messaging.InboundEmail email = new Messaging.InboundEmail() ;
     email.subject = 'Create Contact';
     email.fromAddress = 'someaddress@email.com';
     email.plainTextBody = 'email body';
     Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
     attachment.body = blob.valueOf('my attachment text');
     attachment.fileName = 'textfileone.txt';
     attachment.mimeTypeSubType = 'text/plain';
     email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
     
     Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
     attachmenttext.body = 'my attachment text';
     attachmenttext.fileName = 'textfiletwo3.txt';
     attachmenttext.mimeTypeSubType = 'texttwo/plain';
     email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };
     
     Test.StartTest();
     InboundAttachmentCallback oIB = new InboundAttachmentCallback();
     oIB.handleActionAttachment(objPropLineItem.ID,'APPROVE',email);
     System.assertEquals('Create Contact',email.subject,'Not Found!');
     Test.StopTest();
  }
}
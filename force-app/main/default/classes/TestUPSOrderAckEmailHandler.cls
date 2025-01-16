/***************************************************************************************************************************************
* NAME   : TestUPSOrderAckEmailHandler
* @AUTHOR : Shruti Karn
* @DATE   : 27-May-2019
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Pooja                    23-09-2022          CodeScan Fixes
****************************************************************************************************************************************/ 
@isTest(SeeAllData=true)
public class TestUPSOrderAckEmailHandler {
    
    /*
    * Test method for systemNotificationEmailHandler
    */		
    public static testMethod void systemNotificationEmailHandlerTest() {
        
        // setup controller object
        UPSOrderAckEmailHandler objconfirm = new UPSOrderAckEmailHandler();
        
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        newPartOrderCreation();
        
        Test.startTest();
        
        //Creating plain text attachments on PO
        email.subject = 'Service Number: 267545TEST1 Order Number: 267545345 Louisville to Eindhoven Confirmation';
        email.plainTextBody = 'Hello, this a test email body. for testing purposes only. Bye';
                
        Messaging.InboundEmailResult result = objconfirm.handleInboundEmail(email, envelope);               
        //Added by Sarath to increase test coverage
        //Creating HTML attachments on PO
        email.htmlBody = '<html><body>Hello, this a test email body.<br/>for testing purposes only.<br/>Bye</body></html>';
        
        result = objconfirm.handleInboundEmail(email, envelope);     
        Test.stopTest();
		system.assert(result!=null, 'result is null');
    }
    
    /*
    * Test method for new Parts Order Creation
    */		
    public static testMethod void newPartOrderCreation(){
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        
        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        
        //Parts Order creation in SAP (Inbound to SAP from SVMX)
        partOrder.ERP_Sales_Order_Number__c = '267545';
        partOrder.Contact_Name__c='Test';
        partOrder.Contact_Phone__c='Test';
        partOrder.SVMXC__Order_Type__c='Return';
        
        insert partOrder;
        Case updatedCase = [Select Parts_Order_Status__c from Case where Id =: objCase.Id];
        System.assert(updatedCase.Parts_Order_Status__c!=null, 'Parts order status is blank');
    }
    
    /*
     * Author: Sarath Pullanikkatt
     * Description: Test method to cover the negative sceanarios on the UPSOrderAckEmailHandler class
    */
    public static testMethod void orderAckNegativeTestingInvalidSubject() {
        //Setup Email Service Controller
        UPSOrderAckEmailHandler upsOrderAck = new UPSOrderAckEmailHandler();
        
        //Create a new email and envelope
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        newPartOrderCreation();
        
        Test.startTest();
        
        //Setting up invalid Email Subject
        email.subject = 'Louisville to Eindhoven Order Confirmation';
        email.htmlBody = '<html><body>We do not expect this to work! Its a negative testing.</body><html>';
        
        Messaging.InboundEmailResult result = upsOrderAck.handleInboundEmail(email, env);
        System.assertEquals(false,result.success);
        
        Test.stopTest();
    }
    
    /*
     * Author: Sarath Pullanikkatt
     * Description: Test method to cover the negative sceanarios on the UPSOrderAckEmailHandler class
    */
    public static testMethod void orderAckNegativeTestingIncorrectPONumber() {
        //Setup Email Service Controller
        UPSOrderAckEmailHandler upsOrderAck = new UPSOrderAckEmailHandler();
        
        //Create a new email and envelope
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        newPartOrderCreation();
        
        Test.startTest();
        
        //Setting up Email Subject with incorrect PO number
        email.subject = 'Service Number: 12345 - Test Order Number: 12345 Louisville to Eindhoven Confirmation';
        email.htmlBody = '<html><body>We do not expect this to work! Its a negative testing.</body><html>';
        
        Messaging.InboundEmailResult result = upsOrderAck.handleInboundEmail(email, env);
        System.assertEquals(false,result.success);
        
        Test.stopTest();
    }
    /*
    * Description: This method is to cover the catch block
    */
    public static testMethod void orderAckNegativeTestingCoverCatchBlock() {
        //Setup Email Service Controller
        UPSOrderAckEmailHandler upsOrderAck = new UPSOrderAckEmailHandler();
        
        //Create a new email and envelope
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        newPartOrderCreation();
        
        Test.startTest();
        
        //Setting up Email Subject with incorrect PO number
        email.subject = 'Service Number: 267545 - Test Order Number: 12345 Louisville to Eindhoven Confirmation';
        try{
            Messaging.InboundEmailResult result = upsOrderAck.handleInboundEmail(email, env);
            System.assert(result.success == false);
        }catch(Exception ex){
            System.debug('ex--:'+ex.getMessage());
        }
        
        Test.stopTest();
    }
	
	/*
     * Author: Vaibhav
     * Description: //Added for [DCP-28140] - This method is to cover the main catch block.
     */
    public static testMethod void orderAckNegativeTestingInvalidEmail() {
        //Setup Email Service Controller
        UPSOrderAckEmailHandler upsOrderAck = new UPSOrderAckEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = upsOrderAck.handleInboundEmail(null, null);
        System.assert(result.success == false);
        Test.stopTest();
    }
    
    /*
    * Author: Vaibhav
    * Description: //Added for [DCP-28140] - This method is to cover the catch block by sending InvalidServiceNumber
    */
    public static testMethod void orderAckNegativeTestingBlankServiceNumber() {
        //Setup Email Service Controller
        UPSOrderAckEmailHandler upsOrderAck = new UPSOrderAckEmailHandler();
        
        //Create a new email and envelope
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        newPartOrderCreation();
        
        //Setting up Email Subject with incorrect PO number
        email.subject = 'Service Number:';
        
        Test.startTest();
        
        Messaging.InboundEmailResult result = upsOrderAck.handleInboundEmail(email, env);
        System.assert(result.success == false);
        
        Test.stopTest();
    }
    
}
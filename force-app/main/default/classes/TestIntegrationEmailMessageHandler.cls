/**
*    @author Todd Newman
*    @date   2020-06-09
*    @description    DCP-34910 Email Service Handler Test Class for TestIntegrationEmailMessageHandler
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Todd Newman                 2020-06-09           Initial Version
*    ------------------------------------------------------------------------------------                  
*/
@isTest
private class TestIntegrationEmailMessageHandler {

    public static final string TESTSUBJECT = 'Nada';
    public static final string TESTBODY = 'No service even mentioned';
    public static final string TESTSENDER = 'sender1@sender.com';
    public static final string TESTRECEIVER = 'receiver@receiver.com';
    public static final string TESTSUBJECTINVALIDSERVICE = 'NoService-Nada';
    public static final string TESTBODYMETHODINVALIDSERVICE = 'Service that does not exist';
    public static final string TESTSENDERMETHODINVALIDSERVICE = 'sender2@sender.com';
    public static final string TESTRECEIVERMETHODINVALIDSERVICE = 'receiver2@receiver.com';
    public static final string TESTVALUE = '-SomeValue';
    public static final string EXISTINGSERVICE = 'Service that exists';
    public static final string TESTSENDEREMAIL = 'sender3@sender.com';
    public static final string TESTRECEIVEREMAIL = 'receiver3@receiver.com';
    
    /*
    *@author: Todd Newman
    *@Desc: Test method for detecting no services specified
    */
    @isTest
    public static void detectNoServiceSpecified()
    {
        IntegrationEmailMessageHandler genericHandler = new IntegrationEmailMessageHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = TESTSUBJECT;
        email.plainTextBody = TESTBODY;
        email.fromAddress = TESTSENDER;
        email.toAddresses = new list<String> {TESTRECEIVER};

        Test.startTest();
        Messaging.InboundEmailResult result = genericHandler.handleInboundEmail(email, new Messaging.InboundEnvelope());
        Test.stopTest();

        System.assert(!result.success);
    }
    
    /*
    *@author: Todd Newman
    *@Desc: Test method for detecting invalid service
    */
    @isTest
    public static void detectInvalidService()
    {
        IntegrationEmailMessageHandler genericHandler = new IntegrationEmailMessageHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = TESTSUBJECTINVALIDSERVICE;
        email.plainTextBody = TESTBODYMETHODINVALIDSERVICE;
        email.fromAddress = TESTSENDERMETHODINVALIDSERVICE;
        email.toAddresses = new list<String> {TESTRECEIVERMETHODINVALIDSERVICE};

        Test.startTest();
        Messaging.InboundEmailResult result = genericHandler.handleInboundEmail(email, new Messaging.InboundEnvelope());
        Test.stopTest();

        System.assert(!result.success);
    }
    
    /*
    *@author: Todd Newman
    *@Desc: Test method for basic test service
    */
    @isTest
    public static void basicTestService()
    {
        IntegrationEmailMessageHandler genericHandler = new IntegrationEmailMessageHandler();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = IntegrationEmailMessageHandler.TEST_HANDLER + TESTVALUE;
        email.plainTextBody = EXISTINGSERVICE;
        email.fromAddress = TESTSENDEREMAIL;
        email.toAddresses = new list<String> {TESTRECEIVEREMAIL};

        Test.startTest();
        Messaging.InboundEmailResult result = genericHandler.handleInboundEmail(email, new Messaging.InboundEnvelope());
        Test.stopTest();

        System.assert(result.success);
    }

}
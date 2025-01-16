/**
 *    @author Vishal
 *    @date   19-Nov-2024
 *    @description  Test class for InstalledProductOutboundMessageHandler 
 * */
@isTest
public class TestIPOutboundMessageHandler {

    /**
    *    @author Vishal
    *    @date   19-Nov-2024
    *    @description Test method for sending outbound message
    */ 
    @isTest
    static void testSendMessage() {
        // Create test data
        Account testAccount = TestDataAccount.initAccount();
        SVMXC__Installed_Product__c instProd = TestDataInstalledProduct.getNewInstalledProduct(testAccount.Id);
        List<string> instProdList = new List<string>();
        instProdList.add(instProd.Id);

        // Create the input for the invocable method
        InstalledProductOutboundMessageHandler.CheckPartner checkPartner = new InstalledProductOutboundMessageHandler.CheckPartner();
        checkPartner.recordId = instProdList[0];
        checkPartner.isCP = false;

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new InstalledProductOutboundMessageHandlerMock());

        // Invoke the method
        Test.startTest();
        InstalledProductOutboundMessageHandler.sendMessage(new List<InstalledProductOutboundMessageHandler.CheckPartner>{checkPartner});
        Test.stopTest();

        // Assert the record was updated
        SVMXC__Installed_Product__c updatedProduct = [
            SELECT Sent_to_Qualtrics__c FROM SVMXC__Installed_Product__c WHERE Id = :instProdList[0]
        ];
        System.assertEquals(true, updatedProduct.Sent_to_Qualtrics__c, 'The Sent_to_Qualtrics__c field should be updated to true.');
    }

    /**
    *    @author Vishal
    *    @date   19-Nov-2024
    *    @description Mock class for HTTP callouts
    */ 
    public class InstalledProductOutboundMessageHandlerMock implements HttpCalloutMock {
        /**
    *    @author Vishal
    *    @date   19-Nov-2024
    *    @description method for sending mock HTTP callouts
    */ 
        public HttpResponse respond(HttpRequest req) {
            // Create a mock HTTP response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"message":"Success"}');
            return res;
        }
    }
}
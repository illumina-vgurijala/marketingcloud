/* @ author       : Akshay Mohan
* @ date         : 07-11-2018
* @ Description  : TestCustomerMasterSyncSendInterface is the test class for CustomerMasterSyncSendInterface
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-11-2018                  US-358            Initial version
*/
@IsTest
private class TestCustomerMasterDataSender {

    @IsTest
    static void sendAccountTestMethod() {
        Account  testAccount1=TestDataAccount.getAccount('Test Account1');
        insert testAccount1;
        Test.starttest();
             Test.setMock(HttpCalloutMock.class, new MockHTTPCallout());
             ProspectAccountAddressValidationControl.submitOutboundRequest(testAccount1.id);
        Test.Stoptest();
        System.assertEquals(true, MockHTTPCallout.booResponseSuccess);
    }
    //Added sendBulkAccountTestMethod-Karthik Madugula
    @IsTest
    static void sendBulkAccountTestMethod() {
    	List<Account> lstAccounts = new List<Account>();
        for(Integer i=0;i<10;i++)
        	lstAccounts.add(TestDataAccount.getAccount('Testing '+i));
        insert lstAccounts;
        Test.starttest();
        for(Account objAccount:lstAccounts)
            ProspectAccountAddressValidationControl.submitOutboundRequest(objAccount.id);
        Test.stopTest();
        System.assertEquals(true,MockHTTPCallout.booResponseSuccess);
    }
}
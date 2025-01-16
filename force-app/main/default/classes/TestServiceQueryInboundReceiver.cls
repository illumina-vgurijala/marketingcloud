/*
* @Author: Prabhsimran Singh
* @Date: 05-02-2021
* @Description : Test Class for Web Service Class for ServiceQueryInboundReceiver.
* --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                        Description
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * 
*/
@isTest
public class TestServiceQueryInboundReceiver {
    
    public static final String POSTURL = '/services/apexrest/ServiceQueryReceiver';
    public static final String HTTPPOST = 'Post';
    
    @testSetup
    static void setupData(){
        TestDataAccount.getNewAccount();
        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.BillingCountryCode = 'US';
        acc2.BillingStateCode = 'AK';
        acc2.ERP_Customer_Id__c = '123456';
        Account acc3 = TestDataAccount.getAccount('Account 3');
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'AK';
        acc3.ERP_Customer_Id__c = '567890';
        acc3.Account_Group__c = 'Distributor';
        Account acc4 = TestDataAccount.getAccount('Account 4');
        acc4.BillingCountryCode = 'US';
        acc4.BillingStateCode = 'AK';
        acc4.ERP_Customer_Id__c = '567891';
        acc4.Account_Group__c = 'Sold To';
        
        Account acc5 = TestDataAccount.getAccount('Account 5');
        acc5.BillingCountryCode = 'US';
        acc5.BillingStateCode = 'AK';
        acc5.ERP_Customer_Id__c = '6000022795';
        acc5.Account_Group__c = 'Sold To';

        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc2);
        lstAcc.add(acc3);
        lstAcc.add(acc4);
        lstAcc.add(acc5);
        insert lstAcc;

        TestDataContact.getNewContact(lstAcc[0]);        

    }
    /* Test method for success*/
    @isTest
    public static void testResponseReceiverSuccess()
    {
        ServiceQueryInboundReceiver.queryWrapper qw = new ServiceQueryInboundReceiver.queryWrapper();
        qw.query = 'select id,name,account.name from contact';        
        Test.startTest();        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = HTTPPOST;
        req.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + POSTURL;
        req.requestBody = Blob.valueOf(JSON.serialize(qw));
        
        RestContext.request = req;
        RestContext.response= res;
        ServiceQueryInboundReceiver.getSobjectRecords();
        test.stopTest();
        System.assertEquals(false,String.isBlank(RestContext.request.requestBody.toString()));
		System.assertEquals(200,res.statusCode);
    }

    /* Test method for Failure*/
    @isTest
    public static void testResponseReceiverFailure()
    {
        ServiceQueryInboundReceiver.queryWrapper qw = new ServiceQueryInboundReceiver.queryWrapper();
        qw.query = 'select id,name,email from account';        
        Test.startTest();        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = HTTPPOST;
        req.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + POSTURL;
        req.requestBody = Blob.valueOf(JSON.serialize(qw));
        
        RestContext.request = req;
        RestContext.response= res;
        ServiceQueryInboundReceiver.getSobjectRecords();
        test.stopTest();
        System.assertEquals(false,String.isBlank(RestContext.request.requestBody.toString()));
		System.assertEquals(200,res.statusCode);
    }

    /* Test method for no records*/
    @isTest
    public static void testResponseReceiverNoRecords()
    {
        ServiceQueryInboundReceiver.queryWrapper qw = new ServiceQueryInboundReceiver.queryWrapper();
        qw.query = 'select id,name from opportunity';        
        Test.startTest();        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = HTTPPOST;
        req.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + POSTURL;
        req.requestBody = Blob.valueOf(JSON.serialize(qw));
        
        RestContext.request = req;
        RestContext.response= res;
        ServiceQueryInboundReceiver.getSobjectRecords();
        test.stopTest();
        System.assertEquals(false,String.isBlank(RestContext.request.requestBody.toString()));
		System.assertEquals(200,res.statusCode);
    }
}
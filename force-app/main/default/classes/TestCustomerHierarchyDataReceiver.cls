/**
* 
*
* @desc TestCustomerHeirarchyDataReceiver [CodeScan Fix]
*/
@isTest
public  class TestCustomerHierarchyDataReceiver {

    @testSetup
    static void addAccounts()
    {
        Account testAccount1=TestDataAccount.getAccount('Test Account1');
        testAccount1.ERP_Customer_Id__c = '897';

        Account testAccount2=TestDataAccount.getAccount('Test Account2');
        testAccount2.ERP_Customer_Id__c = '88997';

        insert new List<Account> { testAccount1, testAccount2 };
    }

    static testMethod void parentInsert()
    {
        List<CustomerMasterWrapper.accountheader> accountList = new List<CustomerMasterWrapper.accountheader>();

        CustomerMasterWrapper.accountheader accountobj1 = new CustomerMasterWrapper.accountheader();
        accountobj1.AccountNumber = '897';
        accountobj1.ParentAccount = '88997';
        accountobj1.Indicator = 'I';
        accountList.add(accountobj1);

        String accountJSON = JSON.serialize(accountList);
        System.debug('accountJSON ==' + accountJSON );

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CustomerHierarchySyncInterface';  //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(accountJSON);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CustomerHierarchyDataReceiver.upsertIncomingValues();
        Test.stopTest();

        System.assertequals(200, RestContext.response.statuscode);

        Account testAccount1 = [SELECT Id,Parent.ERP_Customer_Id__c FROM Account WHERE ERP_Customer_Id__c = '897'];
        System.assertEquals('88997', testAccount1.Parent.ERP_Customer_Id__c, 'Parent not set properly');
    }

    static testMethod void parentDelete()
    {
        Account testAccount1 = [SELECT Id FROM Account WHERE ERP_Customer_Id__c = '897'];
        Account testAccount2 = [SELECT Id FROM Account WHERE ERP_Customer_Id__c = '88997'];
        testAccount1.ParentId = testAccount2.id;
        testAccount1.Is_Updated_By_System__c = true;
        update testAccount1;

        List<CustomerMasterWrapper.accountheader>  accountList = new List<CustomerMasterWrapper.accountheader>();

        CustomerMasterWrapper.accountheader accountobj1 = new CustomerMasterWrapper.accountheader();
        accountobj1.AccountNumber = '897';
        accountobj1.ParentAccount = '88997';
        accountobj1.Indicator = 'D';
        accountList.add(accountobj1);
        
        String accountJSON = JSON.serialize(accountList);
        System.debug('accountJSON ==' + accountJSON );

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CustomerHierarchySyncInterface';  //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(accountJSON);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        CustomerHierarchyDataReceiver.upsertIncomingValues(); 
        Test.stopTest();

        System.assertequals(200, RestContext.response.statuscode);

        testAccount1 = [SELECT Id,ParentId FROM Account WHERE ERP_Customer_Id__c = '897'];
        System.assert(String.isBlank(testAccount1.ParentId), 'Parent Id not blanking out');
    }

    static testMethod void parentDeleteMismatch()
    {
        Account testAccount1 = [SELECT Id FROM Account WHERE ERP_Customer_Id__c = '897'];
        Account testAccount2 = [SELECT Id FROM Account WHERE ERP_Customer_Id__c = '88997'];
        testAccount1.ParentId = testAccount2.id;
        testAccount1.Is_Updated_By_System__c = true;
        update testAccount1;

        List<CustomerMasterWrapper.accountheader>  accountList = new List<CustomerMasterWrapper.accountheader>();

        CustomerMasterWrapper.accountheader accountobj1 = new CustomerMasterWrapper.accountheader();
        accountobj1.AccountNumber = '897';
        accountobj1.ParentAccount = '12345'; // mismatch, no action will be taken
        accountobj1.Indicator = 'D';
        accountList.add(accountobj1);
        
        String accountJSON = JSON.serialize(accountList);
        System.debug('accountJSON ==' + accountJSON );

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CustomerHierarchySyncInterface';  //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.requestBody = Blob.valueof(accountJSON);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        CustomerHierarchyDataReceiver.upsertIncomingValues(); 
        Test.stopTest();

        System.assertequals(200, RestContext.response.statuscode);

        testAccount1 = [SELECT Id,ParentId FROM Account WHERE ERP_Customer_Id__c = '897'];
        System.assert(String.isNotBlank(testAccount1.ParentId), 'Parent Id blanked when it should not');
    }

}
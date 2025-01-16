/**
* @author Vishnu Priya Duggineni
* @date   2018-10-28
* @description    Test class for AccountServiceSalesEmail
* Modification Log:
* ----------------------------------------------------------------------------------------------------------------------------------------
* Developer                   Date                       Description
* Vishnu Priya Duggineni      28 October 2018            AccountServiceSalesEmail test class
* ----------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
private class TestAccountsServiceSalesEmails {   

    static testMethod void knownUserFound()
    {
        // query territory information
        List<Territory2Model> activeModels = [SELECT Id FROM Territory2Model WHERE State = 'Active'];
        if (activeModels.size() == 0) return;

        Territory2 territoryRecord = [SELECT Id, Name, Territory_Code__c, District__c FROM Territory2 WHERE Territory2ModelId = :activeModels.get(0).Id LIMIT 1];
        Account acc = TestDataAccount.getNewAccount();

        TestDataTerritory.getNewAccountTerritoryLink(acc, territoryRecord);

        User testUser = TestDataUser.findUserInProfile('System Administrator');
        System.debug('testUser:'+testUser);

        System.runAs(testUser)
        {
            TestDataTerritory.getNewUserTerritoryLink(testUser.Id, territoryRecord.Id);
        }

        System.debug('testuser terrritory' + UserTerritory2Association.Territory2Id);
        System.debug('Customer Id' + acc.ERP_Customer_ID__c);

        RestResponse res = new RestResponse();
        RestRequest req = new RestRequest();
        req.requestURI = '/AccountSalesUsers/*';
        req.params.put('customerId', acc.ERP_Customer_ID__c);
        req.params.put('roles', 'Territory Account Manager');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        System.runAs(testUser)
        {
            AccountsServiceSalesEmails.getSalesUsers();
        }
        Test.stopTest();

        System.debug('res.responseBody:' + res.responseBody.toString());
        System.assertEquals(200, res.statusCode);
        System.assert(res.responseBody.toString().contains(testUser.Email), 'Response should contain user email ' + testUser.Email);
    }

    static testMethod void noCustomerPassedError()
    {
        RestResponse res = new RestResponse();
        RestRequest req = new RestRequest();
        req.requestURI = '/AccountSalesUsers/*';
        req.params.put('customerId', '');
        req.params.put('roles', 'Territory Account Manager, TAM');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        {
            AccountsServiceSalesEmails.getSalesUsers();
        }
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains(AccountsServiceSalesEmails.ERROR_NO_CUSTOMER));
    }

    static testMethod void noRolesPassedError()
    {
        RestResponse res = new RestResponse();
        RestRequest req = new RestRequest();
        req.requestURI = '/AccountSalesUsers/*';
        req.params.put('customerId', '00000');
        req.params.put('roles', '');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
            
        Test.startTest();
        {
            AccountsServiceSalesEmails.getSalesUsers();
        }
        Test.stopTest();
        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains(AccountsServiceSalesEmails.ERROR_NO_ROLES));
    }

    static testMethod void noCustomerFoundError()
    {
        RestResponse res = new RestResponse();
        RestRequest req = new RestRequest();
        req.requestURI = '/AccountSalesUsers/*';
        req.params.put('customerId', '00000');
        req.params.put('roles', 'TAM');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
            
        Test.startTest();
        {
            AccountsServiceSalesEmails.getSalesUsers();
        }
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains(AccountsServiceSalesEmails.ERROR_CUSTOMER_NOT_FOUND));
    }

}
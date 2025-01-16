/**
 *   @author: Deep Diwakar
*    @date:   Feb-06-2024
*    @description: Test class for TSContactDataReceiver and TSContactDataWrapper class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Feb-06-2024        Test class for TSContactDataReceiver and TSContactDataWrapper class
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestTSContactDataReceiver {

    @TestSetup
    static void dataSetup() {
        Contact testCont1 = TestDataMarketing.createContactForMarketable('Tascan1', 'Test1', 'test_tascan1@testing.com', 'US');
        testCont1.openq__TaScanID__c = '22222';

        insert testCont1;
    }

    @IsTest
    static void testContactInsert() {

        List<TSContactDataWrapper> dataWrapperList = new List<TSContactDataWrapper>();
        TSContactDataWrapper dataWrapper = new TSContactDataWrapper();
        dataWrapper.per_id = 11111;
        dataWrapper.person_name_list = 'Tascan Test';
        dataWrapper.private_address_nice_name= '123 Test Lane Street';
        dataWrapper.location_name = 'Torino';
        dataWrapper.private_address_region = null;
        dataWrapper.postcode = '10123';
        dataWrapper.private_address_country = 'Italy';
        dataWrapper.telephone = '+39 232323 ext 121';
        dataWrapper.email = 'tascan_test@testing.com';
        dataWrapper.person_name = 'Test';
        dataWrapper.person_first_name = 'Tascan';
        dataWrapper.person_title = 'md';
        dataWrapper.person_speciality = null;
        dataWrapper.person_npi = 'test123';

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSContactSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSContactDataReceiver.upsertIncomingValues();
        Test.stopTest();

        Contact resultCont = [Select Id, Name, openq__TaScanID__c, openq__OPENQ_NPI_Number__c From Contact
                                WHERE openq__TaScanID__c =: String.valueOf(dataWrapper.per_id)
                                LIMIT 1];


        Assert.areEqual(dataWrapper.person_npi, resultCont.openq__OPENQ_NPI_Number__c, 'Tascan contact NPI number did not set correctly');

    }

    @IsTest
    static void testContactUpdate() {
        // existing contact 
        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSContactDataWrapper> dataWrapperList = new List<TSContactDataWrapper>();
        TSContactDataWrapper dataWrapper = new TSContactDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan1 Test1';
        dataWrapper.private_address_nice_name= '123 Test Lane Street';
        dataWrapper.location_name = 'Torino';
        dataWrapper.private_address_region = null;
        dataWrapper.postcode = '10123';
        dataWrapper.private_address_country = 'Italy';
        dataWrapper.telephone = '+39 232323 ext 121';
        dataWrapper.email = 'tascan_test@testing.com';
        dataWrapper.person_name = 'Test';
        dataWrapper.person_first_name = 'Tascan';
        dataWrapper.person_title = 'md';
        dataWrapper.person_speciality = null;
        dataWrapper.person_npi = 'test123';

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSContactSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSContactDataReceiver.upsertIncomingValues();
        Test.stopTest();

        Contact resultCont = [Select Id, Name, openq__TaScanID__c, openq__OPENQ_NPI_Number__c From Contact
                                WHERE Id =: testCont.Id];


        Assert.areEqual(dataWrapper.person_npi, resultCont.openq__OPENQ_NPI_Number__c, 'Tascan contact NPI number did not set correctly');
        
    }

    @IsTest
    static void testInvalidInput() {

        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        TSContactDataWrapper dataWrapper = new TSContactDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan1 Test1';
        dataWrapper.private_address_nice_name= '123 Test Lane Street';
        dataWrapper.location_name = 'Torino';
        dataWrapper.private_address_region = null;
        dataWrapper.postcode = '10123';
        dataWrapper.private_address_country = 'Italy';
        dataWrapper.telephone = '+39 232323 ext 121';
        dataWrapper.email = 'tascan_test@testing.com';
        dataWrapper.person_name = 'Test';
        dataWrapper.person_first_name = 'Tascan';
        dataWrapper.person_title = 'md';
        dataWrapper.person_speciality = null;
        dataWrapper.person_npi = 'test123';

        // passing invalid input - passing only object, not list of objects
        String requestBody = JSON.serialize(dataWrapper);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSContactSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSContactDataReceiver.upsertIncomingValues();
        // publish platform event to create exception record
        Test.getEventBus().deliver();
        Test.stopTest();

        Contact resultCont = [Select Id, Name, openq__TaScanID__c, openq__OPENQ_NPI_Number__c From Contact
                                WHERE Id =: testCont.Id];

        Assert.areNotEqual(dataWrapper.person_npi, resultCont.openq__OPENQ_NPI_Number__c, 'Tascan contact invalid input did not parse correctly');
        
        
        Interface_Log__c log = [Select Id, Result__c From Interface_Log__c 
                                WHERE Interface_Name__c = 'TSContactSyncInterface'];

        Assert.areEqual('Fail', log.Result__c, 'Interface transaction did not fail');
        
    }

}
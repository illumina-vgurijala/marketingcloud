/**
 *   @author: Deep Diwakar
*    @date:   Jan-25-2024
*    @description: Test class for TSPublicationDataReceiver and TSPublicationDataWrapper class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-25-2024        Test class for TSPublicationDataReceiver and TSPublicationDataWrapper class
*         Deep Diwakar       Feb-06-2024        Adjusted for API response field name change 
*    --------------------------------------------------------------------------------------------------
*/

@IsTest
private class TestTSPublicationDataReceiver {
    @TestSetup
    static void dataSetup() {
        Contact testCont1 = TestDataMarketing.createContactForMarketable('Tascan1', 'Publication1', 'test_tascan1@testing.com', 'US');
        testCont1.openq__TaScanID__c = '11111';

        Contact testCont2 = TestDataMarketing.createContactForMarketable('Tascan2', 'Publication2', 'test_tascan2@testing.com', 'US');
        testCont2.openq__TaScanID__c = '11112';

        insert new List<Contact> {testCont1, testCont2};
    }

    @IsTest
    static void testPublicationInsert() {

        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSPublicationDataWrapper> dataWrapperList = new List<TSPublicationDataWrapper>();
        TSPublicationDataWrapper dataWrapper = new TSPublicationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Publication';
        dataWrapper.publication_id = 22222;
        dataWrapper.journal_name = 'Test Publication Journal';
        dataWrapper.publication_title = 'Test Publication';
        dataWrapper.author_order = '1';
        dataWrapper.medline_id = 33333;
        dataWrapper.publication_date = '2024-07-01T00:00:00.000Z';
        dataWrapper.publication_url = 'http://testinglibrary.testing.com';
        dataWrapper.authors = 'Tascan1 Publication1, Tascan2 Publication2, Tascan3 Publication3';
        dataWrapper.publication_about_trial_tag = null;

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSPublicationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSPublicationDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Publication__c> publicationList = [SELECT Id, Name, openq__Publication_Tascan_ID__c
                                                                FROM  openq__OPENQ_Publication__c LIMIT 100];

        Assert.areEqual(1, publicationList.size(), 'Publication list size did not match total publications');

        openq__OPENQ_Publication__c resultPublication = publicationList.get(0);

        Assert.areEqual('22222', resultPublication.openq__Publication_Tascan_ID__c, 'Publication Tascan Id did not match');

    }

    @IsTest
    static void testExistingPublication() {

        Contact testCont1 = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSPublicationDataWrapper> dataWrapperList = new List<TSPublicationDataWrapper>();

        // create publication first
        openq__OPENQ_Publication__c pubNew = new openq__OPENQ_Publication__c();
        pubNew.openq__Author__c = 'Tascan1 Publication1';
        pubNew.openq__Publication_URL__c = 'http://testinglibrary.testing.com';
        pubNew.openq__Journal__c = 'Test Publication Journal';
        pubNew.openq__Publication_Tascan_ID__c = String.valueOf(22222);
        pubNew.openq__Publication_Title__c = 'Test Publication';
        pubNew.openq__Author_Position__c = '1';
        String pubDate = '2024-07-01T00:00:00.000Z';
        pubNew.openq__Publication_Date__c = pubDate?.substring(0,4);
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(testCont1.openq__TaScanID__c));
        pubNew.openq__Contact_Name__r = parentContact;

        insert pubNew;

        TSPublicationDataWrapper dataWrapper = new TSPublicationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont1.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan1 Publication1';
        dataWrapper.publication_id = 22222;
        dataWrapper.journal_name = 'Test Publication Journal';
        dataWrapper.publication_title = 'Test Publication';
        dataWrapper.author_order = '1';
        dataWrapper.medline_id = 33333;
        dataWrapper.publication_date = '2024-07-01T00:00:00.000Z';
        dataWrapper.publication_url = 'http://testinglibrary.testing.com';
        dataWrapper.authors = 'Tascan1 Publication1, Tascan2 Publication2, Tascan3 Publication3';
        dataWrapper.publication_about_trial_tag = null;

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSPublicationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSPublicationDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Publication__c> publicationList = [SELECT Id, Name, openq__Publication_Tascan_ID__c, openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Publication__c LIMIT 100];

        Assert.areEqual(1, publicationList.size(), 'Publication list size did not match total publications');

        // validating both contact have same publication records
        Assert.areEqual('22222', publicationList.get(0).openq__Publication_Tascan_ID__c, 'Publication Tascan Id did not match');

    }


    @IsTest
    static void testSamePubAnotherContact() {

        Contact testCont1 = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        // create publication first
        openq__OPENQ_Publication__c pubNew = new openq__OPENQ_Publication__c();
        pubNew.openq__Author__c = 'Tascan1 Publication1';
        pubNew.openq__Publication_URL__c = 'http://testinglibrary.testing.com';
        pubNew.openq__Journal__c = 'Test Publication Journal';
        pubNew.openq__Publication_Tascan_ID__c = String.valueOf(22222);
        pubNew.openq__Publication_Title__c = 'Test Publication';
        pubNew.openq__Author_Position__c = '1';
        String pubDate = '2024-07-01T00:00:00.000Z';
        pubNew.openq__Publication_Date__c = pubDate?.substring(0,4);
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(testCont1.openq__TaScanID__c));
        pubNew.openq__Contact_Name__r = parentContact;

        insert pubNew;

        List<TSPublicationDataWrapper> dataWrapperList = new List<TSPublicationDataWrapper>();

        Contact testCont2 = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan2@testing.com'];

        TSPublicationDataWrapper dataWrapper = new TSPublicationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont2.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan1 Publication1';
        dataWrapper.publication_id = 22222;
        dataWrapper.journal_name = 'Test Publication Journal';
        dataWrapper.publication_title = 'Test Publication';
        dataWrapper.author_order = '1';
        dataWrapper.medline_id = 33333;
        dataWrapper.publication_date = '2024-07-01T00:00:00.000Z';
        dataWrapper.publication_url = 'http://testinglibrary.testing.com';
        dataWrapper.authors = 'Tascan1 Publication1, Tascan2 Publication2, Tascan3 Publication3';
        dataWrapper.publication_about_trial_tag = null;

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSPublicationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSPublicationDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Publication__c> publicationList = [SELECT Id, Name, openq__Publication_Tascan_ID__c,  
                                                                openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Publication__c LIMIT 100];

        Assert.areEqual(2, publicationList.size(), 'Publication list size did not match total publications');

        openq__OPENQ_Publication__c testPublicationCont1 = new openq__OPENQ_Publication__c();
        openq__OPENQ_Publication__c testPublicationCont2 = new openq__OPENQ_Publication__c();
        for (openq__OPENQ_Publication__c testPublication : publicationList) {
            if ('11111'.equals(testPublication.openq__Contact_Name__r.openq__TaScanID__c)) {
                testPublicationCont1 = testPublication;
            } else {
                testPublicationCont2 = testPublication;
            }

        }

        // validating both contact have same publication records
        Assert.areEqual('22222', testPublicationCont1.openq__Publication_Tascan_ID__c, 'Publication Tascan Id did not match');
        Assert.areEqual('22222', testPublicationCont2.openq__Publication_Tascan_ID__c, 'Publication Tascan Id did not match');

    }

    @isTest
    static void testPublicationInvalidInput() {
        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        TSPublicationDataWrapper dataWrapper = new TSPublicationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan1 Publication1';
        dataWrapper.publication_id = 22222;
        dataWrapper.journal_name = 'Test Publication Journal';
        dataWrapper.publication_title = 'Test Publication';
        dataWrapper.author_order = '1';
        dataWrapper.medline_id = 33333;
        dataWrapper.publication_date = '2024-07-01T00:00:00.000Z';
        dataWrapper.publication_url = 'http://testinglibrary.testing.com';
        dataWrapper.authors = 'Tascan1 Publication1, Tascan2 Publication2, Tascan3 Publication3';
        dataWrapper.publication_about_trial_tag = null;

        // passing invalid input - passing only object, not list of objects
        String requestBody = JSON.serialize(dataWrapper);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSPublicationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSPublicationDataReceiver.upsertIncomingValues();
        // publish platform event to create exception record
        Test.getEventBus().deliver();
        Test.stopTest();

        List<openq__OPENQ_Publication__c> publicationList = [SELECT Id, Name, openq__Publication_Tascan_ID__c,
                                                                openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Publication__c LIMIT 100];

        Assert.areEqual(0, publicationList.size(), 'Invalid input did not parse correctly');
        
        Interface_Log__c log = [Select Id, Result__c From Interface_Log__c 
                                WHERE Interface_Name__c = 'TSPublicationSyncInterface'];

        Assert.areEqual('Fail', log.Result__c, 'Interface transaction did not fail');
       
    }

}
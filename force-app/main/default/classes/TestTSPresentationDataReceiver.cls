/**
 *   @author: Deep Diwakar
*    @date:   Jan-17-2024
*    @description: Test class for TSPresentationDataReceiver and TSPresentationDataWrapper class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-17-2024        Test class for TSPresentationDataReceiver and TSPresentationDataWrapper class
*         Deep Diwakar       Feb-06-2024        Adjusted for API response field name change 
*    --------------------------------------------------------------------------------------------------
*/

@IsTest
private class TestTSPresentationDataReceiver {

    @TestSetup
    static void dataSetup() {
        Contact testCont1 = TestDataMarketing.createContactForMarketable('Tascan1', 'Present1', 'test_tascan1@testing.com', 'US');
        testCont1.openq__TaScanID__c = '11111';

        Contact testCont2 = TestDataMarketing.createContactForMarketable('Tascan2', 'Present2', 'test_tascan2@testing.com', 'US');
        testCont2.openq__TaScanID__c = '11112';

        insert new List<Contact> {testCont1, testCont2};
    }

    @IsTest
    static void testPresentationInsert() {

        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSPresentationDataWrapper> dataWrapperList = new List<TSPresentationDataWrapper>();
        TSPresentationDataWrapper dataWrapper = new TSPresentationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Present';
        dataWrapper.presentation_type = 'Poster Discussion Session, Lung Cancer';
        dataWrapper.presentation_id = 22222;
        dataWrapper.conference_name = 'Test Conference';
        dataWrapper.presentation_title = 'Test Presentation';
        dataWrapper.presentation_author_order = '1';
        dataWrapper.conference_start = '2024-07-01T00:00:00.000Z';
        dataWrapper.conference_url = 'http://testinglibrary.testing.com';
        dataWrapper.presenters = 'Tascan1 Present1, Tascan2 Present2, Tascan3 Present3';

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSPresentationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSPresentationDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Presentation__c> presentationList = [SELECT Id, Name, openq__Presentation_Tascan_ID__c
                                                                FROM  openq__OPENQ_Presentation__c LIMIT 100];

        Assert.areEqual(1, presentationList.size(), 'Presentation list size did not match total presentations');

        openq__OPENQ_Presentation__c resultPresent = presentationList.get(0);

        Assert.areEqual('22222', resultPresent.openq__Presentation_Tascan_ID__c, 'Presentation Tascan Id did not match');

    }

    @IsTest
    static void testExistingPresentation() {

        Contact testCont1 = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSPresentationDataWrapper> dataWrapperList = new List<TSPresentationDataWrapper>();

        // create presentation first
        openq__OPENQ_Presentation__c prstNew = new openq__OPENQ_Presentation__c();
        prstNew.openq__Presenters__c = 'Tascan1 Present1';
        prstNew.openq__Meeting_URL__c = 'http://testinglibrary.testing.com';
        prstNew.openq__Meeting_Name__c = 'Test Conference';
        prstNew.openq__Presentation_Type__c = 'Poster Discussion Session, Lung Cancer';
        prstNew.openq__Presentation_Tascan_ID__c = String.valueOf(22222);
        prstNew.openq__Presentation_Title__c = 'Test Presentation';
        prstNew.openq__Position__c = '1';
        String confDate = '2024-07-01T00:00:00.000Z';
        prstNew.openq__Date__c = confDate.substringBefore('T');
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(testCont1.openq__TaScanID__c));
        prstNew.openq__Contact_Name__r = parentContact;

        insert prstNew;

        TSPresentationDataWrapper dataWrapper2 = new TSPresentationDataWrapper();
        dataWrapper2.per_id = Integer.valueOf(testCont1.openq__TaScanID__c);
        dataWrapper2.person_name_list = 'Tascan1 Present1';
        dataWrapper2.presentation_type = 'Poster Discussion Session, Lung Cancer';
        dataWrapper2.presentation_id = 22222;
        dataWrapper2.conference_name = 'Test Conference';
        dataWrapper2.presentation_title = 'Test Presentation';
        dataWrapper2.presentation_author_order = '1';
        dataWrapper2.conference_start = '2024-07-01T00:00:00.000Z';
        dataWrapper2.conference_url = 'http://testinglibrary.testing.com';
        dataWrapper2.presenters = 'Tascan2 Present2, Tascan1 Present1, Tascan3 Present3';

        dataWrapperList.add(dataWrapper2);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSPresentationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSPresentationDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Presentation__c> presentationList = [SELECT Id, Name, openq__Presentation_Tascan_ID__c, openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Presentation__c LIMIT 100];

        Assert.areEqual(1, presentationList.size(), 'Presentation list size did not match total presentations');

        // validating both contact have same presentation records
        Assert.areEqual('22222', presentationList.get(0).openq__Presentation_Tascan_ID__c, 'Presentation Tascan Id did not match');

    }


    @IsTest
    static void testSamePrstAnotherContact() {

        Contact testCont1 = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        // create presentation first
        openq__OPENQ_Presentation__c prstNew = new openq__OPENQ_Presentation__c();
        prstNew.openq__Presenters__c = 'Tascan1 Present1';
        prstNew.openq__Meeting_URL__c = 'http://testinglibrary.testing.com';
        prstNew.openq__Meeting_Name__c = 'Test Conference';
        prstNew.openq__Presentation_Type__c = 'Poster Discussion Session, Lung Cancer';
        prstNew.openq__Presentation_Tascan_ID__c = String.valueOf(22222);
        prstNew.openq__Presentation_Title__c = 'Test Presentation';
        prstNew.openq__Position__c = '1';
        String confDate = '2024-07-01T00:00:00.000Z';
        prstNew.openq__Date__c = confDate.substringBefore('T');
        
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(testCont1.openq__TaScanID__c));
        prstNew.openq__Contact_Name__r = parentContact;

        insert prstNew;

        List<TSPresentationDataWrapper> dataWrapperList = new List<TSPresentationDataWrapper>();

        Contact testCont2 = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan2@testing.com'];

        TSPresentationDataWrapper dataWrapper2 = new TSPresentationDataWrapper();
        dataWrapper2.per_id = Integer.valueOf(testCont2.openq__TaScanID__c);
        dataWrapper2.person_name_list = 'Tascan2 Present2';
        dataWrapper2.presentation_type = 'Poster Discussion Session, Lung Cancer';
        dataWrapper2.presentation_id = 22222;
        dataWrapper2.conference_name = 'Test Conference';
        dataWrapper2.presentation_title = 'Test Presentation';
        dataWrapper2.presentation_author_order = '2';
        dataWrapper2.conference_start = '2024-07-01T00:00:00.000Z';
        dataWrapper2.conference_url = 'http://testinglibrary.testing.com';
        dataWrapper2.presenters = 'Tascan2 Present2, Tascan1 Present1, Tascan3 Present3';

        dataWrapperList.add(dataWrapper2);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSPresentationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSPresentationDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Presentation__c> presentationList = [SELECT Id, Name, openq__Presentation_Tascan_ID__c,  
                                                                openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Presentation__c LIMIT 100];

        Assert.areEqual(2, presentationList.size(), 'Presentation list size did not match total presentations');

        openq__OPENQ_Presentation__c testPresentCont1 = new openq__OPENQ_Presentation__c();
        openq__OPENQ_Presentation__c testPresentCont2 = new openq__OPENQ_Presentation__c();
        for (openq__OPENQ_Presentation__c testPresent : presentationList) {
            if ('11111'.equals(testPresent.openq__Contact_Name__r.openq__TaScanID__c)) {
                testPresentCont1 = testPresent;
            } else {
                testPresentCont2 = testPresent;
            }

        }

        // validating both contact have same presentation records
        Assert.areEqual('22222', testPresentCont1.openq__Presentation_Tascan_ID__c, 'Presentation Tascan Id did not match');
        Assert.areEqual('22222', testPresentCont2.openq__Presentation_Tascan_ID__c, 'Presentation Tascan Id did not match');

    }

    @isTest
    static void testPresentationInvalidInput() {
        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        TSPresentationDataWrapper dataWrapper = new TSPresentationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan1 Present1';
        dataWrapper.presentation_type = 'Poster Discussion Session, Lung Cancer';
        dataWrapper.presentation_id = 22222;
        dataWrapper.conference_name = 'Test Conference';
        dataWrapper.presentation_title = 'Test Presentation';
        dataWrapper.presentation_author_order = '1';
        dataWrapper.conference_start = '2024-07-01T00:00:00.000Z';
        dataWrapper.conference_url = 'http://testinglibrary.testing.com';
        dataWrapper.presenters = 'Tascan1 Present1, Tascan2 Present2, Tascan3 Present3';

        // passing invalid input - passing only object, not list of objects
        String requestBody = JSON.serialize(dataWrapper);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSPresentationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSPresentationDataReceiver.upsertIncomingValues();
        // publish platform event to create exception record
        Test.getEventBus().deliver();
        Test.stopTest();

        List<openq__OPENQ_Presentation__c> presentationList = [SELECT Id, Name, openq__Presentation_Tascan_ID__c,
                                                                openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Presentation__c LIMIT 100];

        Assert.areEqual(0, presentationList.size(), 'Invalid input did not parse correctly');
        
        Interface_Log__c log = [Select Id, Result__c From Interface_Log__c 
                                WHERE Interface_Name__c = 'TSPresentationSyncInterface'];

        Assert.areEqual('Fail', log.Result__c, 'Interface transaction did not fail');
       
    }


}
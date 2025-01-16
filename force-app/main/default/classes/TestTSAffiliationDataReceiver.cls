/**
 *   @author: Deep Diwakar
*    @date:   Jan-17-2024
*    @description: Test class for TSAffiliationDataReceiver and TSAffiliationDataWrapper class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-17-2024        Test class for TSAffiliationDataReceiver and TSAffiliationDataWrapper class
*         Deep Diwakar       Feb-06-2024        Adjusted for API response field name change 
*    --------------------------------------------------------------------------------------------------
*/

@IsTest
private class TestTSAffiliationDataReceiver {

    @TestSetup
    static void dataSetup() {
        Contact testCont1 = TestDataMarketing.createContactForMarketable('Tascan1', 'Present1', 'test_tascan1@testing.com', 'US');
        testCont1.openq__TaScanID__c = '11111';

        Contact testCont2 = TestDataMarketing.createContactForMarketable('Tascan2', 'Present2', 'test_tascan2@testing.com', 'US');
        testCont2.openq__TaScanID__c = '11112';

        insert new List<Contact> {testCont1, testCont2};
    }

    @IsTest
    static void testAffiliationInsert() {

        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSAffiliationDataWrapper> dataWrapperList = new List<TSAffiliationDataWrapper>();
        TSAffiliationDataWrapper dataWrapper = new TSAffiliationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Affiliation';
        dataWrapper.known_associated_organization_name = 'Affiliation Institute';
        dataWrapper.organisation_id = 22222;
        dataWrapper.first_year_at_known_associated_organization = 2016;
        dataWrapper.last_year_at_known_associated_organization = 2020;
        dataWrapper.organization_url = 'http://testinglibrary.testing.com';

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSAffiliationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSAffiliationDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Affiliation__c> affiliationList = [SELECT Id, Name, openq__Affiliation_Tascan_ID__c
                                                                FROM  openq__OPENQ_Affiliation__c LIMIT 100];

        Assert.areEqual(1, affiliationList.size(), 'Affiliation list size did not match total affiliations');

        openq__OPENQ_Affiliation__c resultAffiliation = affiliationList.get(0);

        Assert.areEqual('22222', resultAffiliation.openq__Affiliation_Tascan_ID__c, 'Affiliation Tascan Id did not match');

    }

    @IsTest
    static void testExistingAffiliation() {

        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSAffiliationDataWrapper> dataWrapperList = new List<TSAffiliationDataWrapper>();

        // create affiliation first
        openq__OPENQ_Affiliation__c aflnNew = new openq__OPENQ_Affiliation__c();
        aflnNew.openq__Website__c = 'http://testinglibrary.testing.com';
        aflnNew.Name = 'Affiliation Institute';
        aflnNew.openq__First_Year__c = '2016';
        aflnNew.openq__Affiliation_Tascan_ID__c = '22222';
        aflnNew.openq__Last_Year__c = '2020';

        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(testCont.openq__TaScanID__c));
        aflnNew.openq__Contact_Name__r = parentContact;

        insert aflnNew;

        TSAffiliationDataWrapper dataWrapper = new TSAffiliationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Affiliation';
        dataWrapper.known_associated_organization_name = 'Affiliation Institute';
        dataWrapper.organisation_id = 22222;
        dataWrapper.first_year_at_known_associated_organization = 2016;
        dataWrapper.last_year_at_known_associated_organization = 2020;
        dataWrapper.organization_url = 'http://testinglibrary.testing.com';

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSAffiliationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSAffiliationDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Affiliation__c> affiliationList = [SELECT Id, Name, openq__Affiliation_Tascan_ID__c, openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Affiliation__c LIMIT 100];

        Assert.areEqual(1, affiliationList.size(), 'Affiliation list size did not match total affiliations');

        // validating both contact have same presentation records
        Assert.areEqual('22222', affiliationList.get(0).openq__Affiliation_Tascan_ID__c, 'Affiliation Tascan Id did not match');

    }


    @IsTest
    static void testMultipleAffiliation() {

        Contact testCont1 = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        // create affiliation first
        openq__OPENQ_Affiliation__c aflnNew = new openq__OPENQ_Affiliation__c();
        aflnNew.openq__Website__c = 'http://testinglibrary.testing.com';
        aflnNew.Name = 'Affiliation Institute';
        aflnNew.openq__First_Year__c = '2016';
        aflnNew.openq__Affiliation_Tascan_ID__c = '22222';
        aflnNew.openq__Last_Year__c = '2020';

        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(testCont1.openq__TaScanID__c));
        aflnNew.openq__Contact_Name__r = parentContact;

        insert aflnNew;

        List<TSAffiliationDataWrapper> dataWrapperList = new List<TSAffiliationDataWrapper>();

        TSAffiliationDataWrapper dataWrapper = new TSAffiliationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont1.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Affiliation 2';
        dataWrapper.known_associated_organization_name = 'Affiliation Institute 2';
        dataWrapper.organisation_id = 22223;
        dataWrapper.first_year_at_known_associated_organization = 2018;
        dataWrapper.last_year_at_known_associated_organization = 2022;
        dataWrapper.organization_url = 'http://testinglibrary2.testing.com';


        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSAffiliationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSAffiliationDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Affiliation__c> affiliationList = [SELECT Id, Name, openq__Affiliation_Tascan_ID__c,  
                                                                openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Affiliation__c LIMIT 100];

        Assert.areEqual(2, affiliationList.size(), 'Affiliation list size did not match total affiliations');


    }

    @isTest
    static void testAffiliationInvalidInput() {
        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        TSAffiliationDataWrapper dataWrapper = new TSAffiliationDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Affiliation';
        dataWrapper.known_associated_organization_name = 'Affiliation Institute';
        dataWrapper.organisation_id = 22222;
        dataWrapper.first_year_at_known_associated_organization = 2016;
        dataWrapper.last_year_at_known_associated_organization = 2020;
        dataWrapper.organization_url = 'http://testinglibrary.testing.com';

        // passing invalid input - passing only object, not list of objects
        String requestBody = JSON.serialize(dataWrapper);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSAffiliationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSAffiliationDataReceiver.upsertIncomingValues();
        // publish platform event to create exception record
        Test.getEventBus().deliver();
        Test.stopTest();

        List<openq__OPENQ_Affiliation__c> affiliationList = [SELECT Id, Name, openq__Affiliation_Tascan_ID__c,
                                                                openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Affiliation__c LIMIT 100];

        Assert.areEqual(0, affiliationList.size(), 'Invalid input did not parse correctly');
        
        Interface_Log__c log = [Select Id, Result__c From Interface_Log__c 
                                WHERE Interface_Name__c = 'TSAffiliationSyncInterface'];

        Assert.areEqual('Fail', log.Result__c, 'Interface transaction did not fail');
       
    }

}
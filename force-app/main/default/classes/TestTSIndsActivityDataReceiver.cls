/**
 *   @author: Deep Diwakar
*    @date:   Feb-19-2024
*    @description: Test class for TSIndsActivityDataReceiver and TSIndsActivityDataWrapper class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Feb-19-2024        Test class for TSIndsActivityDataReceiver and TSIndsActivityDataWrapper class
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestTSIndsActivityDataReceiver {

    @TestSetup
    static void dataSetup() {
        Contact testCont1 = TestDataMarketing.createContactForMarketable('Tascan1', 'Present1', 'test_tascan1@testing.com', 'US');
        testCont1.openq__TaScanID__c = '11111';

        Contact testCont2 = TestDataMarketing.createContactForMarketable('Tascan2', 'Present2', 'test_tascan2@testing.com', 'US');
        testCont2.openq__TaScanID__c = '11112';

        insert new List<Contact> {testCont1, testCont2};
    }

    @IsTest
    static void testIndustryActivityInsert() {

        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSIndsActivityDataWrapper> dataWrapperList = new List<TSIndsActivityDataWrapper>();
        TSIndsActivityDataWrapper dataWrapper = new TSIndsActivityDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Industry Activity';
        dataWrapper.organization_name = 'Industry Activity Institute';
        dataWrapper.organisation_id = 22222;
        dataWrapper.fee_disclosure_purpose = 'Research';
        dataWrapper.fee_disclosure_period = '30 Jun 2022 to 30 Jun 2022';
        dataWrapper.fee_disclosure_amount_in_dollars = 550;

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSIndustryActivitySyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSIndsActivityDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Industry_Activity__c> lstIndsActivities = [SELECT Id, Name, openq__IndustryActivity_Tascan_ID__c
                                                                FROM  openq__OPENQ_Industry_Activity__c LIMIT 100];

        Assert.areEqual(1, lstIndsActivities.size(), 'Industry Activity list size did not match total industry activities');

        openq__OPENQ_Industry_Activity__c resultIndustryActivity = lstIndsActivities.get(0);

        Assert.areEqual('22222', resultIndustryActivity.openq__IndustryActivity_Tascan_ID__c, 'Industry Activity Tascan Id did not match');

    }

    @IsTest
    static void testMultipleIndustryActivity() {

        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSIndsActivityDataWrapper> dataWrapperList = new List<TSIndsActivityDataWrapper>();

        // create one industry activity first
        openq__OPENQ_Industry_Activity__c indsActNew = new openq__OPENQ_Industry_Activity__c();
        indsActNew.openq__Exp_Date__c = '30 Jun 2022 to 30 Jun 2022';
        indsActNew.openq__Amount__c = '550';
        indsActNew.openq__IndustryActivity_Tascan_ID__c = '22222';
        indsActNew.openq__Description__c = 'Industry Activity Institute';
        indsActNew.openq__Experience_Type__c = 'Research';

        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(testCont.openq__TaScanID__c));
        indsActNew.openq__Contact_Name__r = parentContact;

        insert indsActNew;

        // same record info coming again
        TSIndsActivityDataWrapper dataWrapper = new TSIndsActivityDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Industry Activity';
        dataWrapper.organization_name = 'Industry Activity Institute';
        dataWrapper.organisation_id = 22222;
        dataWrapper.fee_disclosure_purpose = 'Research';
        dataWrapper.fee_disclosure_period = '30 Jun 2022 to 30 Jun 2022';
        dataWrapper.fee_disclosure_amount_in_dollars = 550;

        dataWrapperList.add(dataWrapper);

        // new record info
        TSIndsActivityDataWrapper dataWrapper2 = new TSIndsActivityDataWrapper();
        dataWrapper2.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper2.person_name_list = 'Tascan Industry Activity';
        dataWrapper2.organization_name = 'Industry Activity Institute';
        dataWrapper2.organisation_id = 22222;
        dataWrapper2.fee_disclosure_purpose = 'Travel and Lodging';
        dataWrapper2.fee_disclosure_period = '07 Feb 2023 to 07 Feb 2023';
        dataWrapper2.fee_disclosure_amount_in_dollars = 250;

        dataWrapperList.add(dataWrapper2);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSIndustryActivitySyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSIndsActivityDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Industry_Activity__c> lstIndsActivities = [SELECT Id, Name, openq__IndustryActivity_Tascan_ID__c, openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Industry_Activity__c LIMIT 100];

        Assert.areEqual(2, lstIndsActivities.size(), 'Industry Activity list size did not match total industry activities');

    }


    @isTest
    static void testIndustryActivityInvalidInput() {
        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        TSIndsActivityDataWrapper dataWrapper = new TSIndsActivityDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Industry Activity';
        dataWrapper.organization_name = 'Industry Activity Institute';
        dataWrapper.organisation_id = 22222;
        dataWrapper.fee_disclosure_purpose = 'Research';
        dataWrapper.fee_disclosure_period = '30 Jun 2022 to 30 Jun 2022';
        dataWrapper.fee_disclosure_amount_in_dollars = 550;

        // passing invalid input - passing only object, not list of objects
        String requestBody = JSON.serialize(dataWrapper);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSIndustryActivitySyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSIndsActivityDataReceiver.upsertIncomingValues();
        // publish platform event to create exception record
        Test.getEventBus().deliver();
        Test.stopTest();

        List<openq__OPENQ_Industry_Activity__c> lstIndsActivities = [SELECT Id, Name, openq__IndustryActivity_Tascan_ID__c,
                                                                openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Industry_Activity__c LIMIT 100];

        Assert.areEqual(0, lstIndsActivities.size(), 'Invalid input did not parse correctly');
        
        Interface_Log__c log = [Select Id, Result__c From Interface_Log__c 
                                WHERE Interface_Name__c = 'TSIndustryActivitySyncInterface'];

        Assert.areEqual('Fail', log.Result__c, 'Interface transaction did not fail');
       
    }

}
/**
 *   @author: Deep Diwakar
*    @date:   Jan-31-2024
*    @description: Test class for TSTrialDataReceiver and TSTrialDataWrapper class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Jan-31-2024        Test class for TSTrialDataReceiver and TSTrialDataWrapper class
*         Deep Diwakar       Feb-12-2024        Adjusted for defect fixes
*    --------------------------------------------------------------------------------------------------
*/

@isTest
private class TestTSTrialDataReceiver {

    @TestSetup
    static void dataSetup() {
        Contact testCont1 = TestDataMarketing.createContactForMarketable('Tascan1', 'Trial1', 'test_tascan1@testing.com', 'US');
        testCont1.openq__TaScanID__c = '11111';

        Contact testCont2 = TestDataMarketing.createContactForMarketable('Tascan2', 'Trial2', 'test_tascan2@testing.com', 'US');
        testCont2.openq__TaScanID__c = '11112';

        insert new List<Contact> {testCont1, testCont2};
    }

    @IsTest
    static void testTrialInsert() {

        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSTrialDataWrapper> dataWrapperList = new List<TSTrialDataWrapper>();
        TSTrialDataWrapper dataWrapper = new TSTrialDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Trial';
        dataWrapper.trial_id = 22222;
        dataWrapper.study_type = 'Test interventional trial';
        dataWrapper.trial_registry_id = 'Test-NCT01966';
        dataWrapper.trial_name = 'Test Trial';
        dataWrapper.state = 'completed trials';
        dataWrapper.trial_purpose = 'Test purpose';
        dataWrapper.primary_outcomes = 'Test result achieved';
        dataWrapper.trial_participant_gender_restriction = 'Both';
        dataWrapper.phase = 'phase 2 trials';
        dataWrapper.enrollment = 40.0;
        dataWrapper.minimum_age = 18.0;
        dataWrapper.maximum_age = 80.0;
        dataWrapper.therapy_treatment = 'Test Treatment';
        dataWrapper.study_start = '2023-07-01T00:00:00.000Z';
        dataWrapper.study_end = '2024-01-01T00:00:00.000Z';
        dataWrapper.trial_url = 'http://testinglibrary.testing.com';
        dataWrapper.sponsors = 'Test Company1, Test Company2';
        dataWrapper.number_of_sites = 3;

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSTrialSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSTrialDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Trial__c> trialList = [SELECT Id, Name, openq__Trial_Tascan_ID__c
                                                                FROM  openq__OPENQ_Trial__c LIMIT 100];

        Assert.areEqual(1, trialList.size(), 'Trial list size did not match total trials');

        openq__OPENQ_Trial__c resultTrial = trialList.get(0);

        Assert.areEqual('22222', resultTrial.openq__Trial_Tascan_ID__c, 'Trial Tascan Id did not match');

    }

    @IsTest
    static void testExistingTrialUpdate() {

        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        List<TSTrialDataWrapper> dataWrapperList = new List<TSTrialDataWrapper>();

        // create trial first
        openq__OPENQ_Trial__c trialNew = new openq__OPENQ_Trial__c();
        trialNew.openq__Trial_Sponsors__c = 'Test Company1, Test Company2';
        trialNew.openq__Trial_URL__c = 'http://testinglibrary.testing.com';
        trialNew.openq__TrialID_Number__c = 'Test-NCT01966';
        trialNew.openq__Trial_Tascan_ID__c = String.valueOf(22222);
        trialNew.openq__Full_Trial_Name__c = 'Test Trial';
        trialNew.openq__Trial_Sites__c = 10;
        trialNew.openq__Trial_Type__c = 'Test interventional trial';
        trialNew.openq__Therapy__c = 'Test Treatment';
        trialNew.openq__Trial_Description__c = 'Test purpose';
        trialNew.openq__Status__c = 'completed trials';
        trialNew.openq__Primary_Outcome__c =  'Test result achieved';
        trialNew.openq__Phase__c = 'phase 2 trials';
        trialNew.openq__Enrollment__c = 40.0;
        trialNew.openq__Gender__c = 'Both';
        trialNew.openq__Start_Date__c = '2023-07-01';
        //trialNew.openq__End_Date__c
        trialNew.openq__Maximum_Age__c = 80.0;
        trialNew.openq__Minimum_Age__c = 18.0;
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(testCont.openq__TaScanID__c));
        trialNew.openq__Contact_Name__r = parentContact;

        insert trialNew;

        TSTrialDataWrapper dataWrapper = new TSTrialDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Trial';
        dataWrapper.trial_id = 22222;
        dataWrapper.study_type = 'Test interventional trial';
        dataWrapper.trial_registry_id = 'Test-NCT01966';
        dataWrapper.trial_name = 'Test Trial';
        dataWrapper.state = 'completed trials';
        dataWrapper.trial_purpose = 'Test purpose';
        dataWrapper.primary_outcomes = 'Test result achieved';
        dataWrapper.trial_participant_gender_restriction = 'Both';
        dataWrapper.phase = 'phase 2 trials';
        dataWrapper.enrollment = 40.0;
        dataWrapper.minimum_age = 18.0;
        dataWrapper.maximum_age = 80.0;
        dataWrapper.therapy_treatment = 'Test Treatment';
        dataWrapper.study_start = '2023-07-01T00:00:00.000Z';
        dataWrapper.study_end = '2024-01-01T00:00:00.000Z';
        dataWrapper.trial_url = 'http://testinglibrary.testing.com';
        dataWrapper.sponsors = 'Test Company1, Test Company2';
        dataWrapper.number_of_sites = 15;

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSTrialSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSTrialDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Trial__c> trialList = [SELECT Id, openq__Trial_Tascan_ID__c, openq__End_Date__c, openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Trial__c LIMIT 100];

        Assert.areEqual(1, trialList.size(), 'Trial list size did not match total trials');
        Assert.isNotNull(trialList.get(0).openq__End_Date__c, 'Trial end date did not update correctly');

    }


    @IsTest
    static void testSameTrialAnotherContact() {

        Contact testCont1 = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        // create trial first
        openq__OPENQ_Trial__c trialNew = new openq__OPENQ_Trial__c();
        trialNew.openq__Trial_Sponsors__c = 'Test Company1, Test Company2';
        trialNew.openq__Trial_URL__c = 'http://testinglibrary.testing.com';
        trialNew.openq__TrialID_Number__c = 'Test-NCT01966';
        trialNew.openq__Trial_Tascan_ID__c = String.valueOf(22222);
        trialNew.openq__Full_Trial_Name__c = 'Test Trial';
        trialNew.openq__Trial_Sites__c = 15;
        trialNew.openq__Trial_Type__c = 'Test interventional trial';
        trialNew.openq__Therapy__c = 'Test Treatment';
        trialNew.openq__Trial_Description__c = 'Test purpose';
        trialNew.openq__Status__c = 'completed trials';
        trialNew.openq__Primary_Outcome__c =  'Test result achieved';
        trialNew.openq__Phase__c = 'phase 2 trials';
        trialNew.openq__Enrollment__c = 40.0;
        trialNew.openq__Gender__c = 'Both';
        trialNew.openq__Start_Date__c = '2023-07-01';
        trialNew.openq__End_Date__c = '2024-01-01';
        trialNew.openq__Maximum_Age__c = 80.0;
        trialNew.openq__Minimum_Age__c = 18.0;
        Contact parentContact = new Contact(openq__TaScanID__c = String.valueOf(testCont1.openq__TaScanID__c));
        trialNew.openq__Contact_Name__r = parentContact;

        insert trialNew;

        List<TSTrialDataWrapper> dataWrapperList = new List<TSTrialDataWrapper>();

        Contact testCont2 = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan2@testing.com'];

        TSTrialDataWrapper dataWrapper = new TSTrialDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont2.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Trial';
        dataWrapper.trial_id = 22222;
        dataWrapper.study_type = 'Test interventional trial';
        dataWrapper.trial_registry_id = 'Test-NCT01966';
        dataWrapper.trial_name = 'Test Trial';
        dataWrapper.state = 'completed trials';
        dataWrapper.trial_purpose = 'Test purpose';
        dataWrapper.primary_outcomes = 'Test result achieved';
        dataWrapper.trial_participant_gender_restriction = 'Both';
        dataWrapper.phase = 'phase 2 trials';
        dataWrapper.enrollment = 40.0;
        dataWrapper.minimum_age = 18.0;
        dataWrapper.maximum_age = 80.0;
        dataWrapper.therapy_treatment = 'Test Treatment';
        dataWrapper.study_start = '2023-07-01T00:00:00.000Z';
        dataWrapper.study_end = '2024-01-01T00:00:00.000Z';
        dataWrapper.trial_url = 'http://testinglibrary.testing.com';
        dataWrapper.sponsors = 'Test Company1, Test Company2';
        dataWrapper.number_of_sites = 15;

        dataWrapperList.add(dataWrapper);

        String requestBody = JSON.serialize(dataWrapperList);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSTrialSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSTrialDataReceiver.upsertIncomingValues();
        Test.stopTest();

        List<openq__OPENQ_Trial__c> trialList = [SELECT Id, Name, openq__Trial_Tascan_ID__c,  
                                                                openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Trial__c LIMIT 100];

        Assert.areEqual(2, trialList.size(), 'Trial list size did not match total trials');

        openq__OPENQ_Trial__c testTrialCont1 = new openq__OPENQ_Trial__c();
        openq__OPENQ_Trial__c testTrialCont2 = new openq__OPENQ_Trial__c();
        for (openq__OPENQ_Trial__c testTrial : trialList) {
            if ('11111'.equals(testTrial.openq__Contact_Name__r.openq__TaScanID__c)) {
                testTrialCont1 = testTrial;
            } else {
                testTrialCont2 = testTrial;
            }

        }

        // validating both contact have same trial records
        Assert.areEqual('22222', testTrialCont1.openq__Trial_Tascan_ID__c, 'Trial Tascan Id did not match');
        Assert.areEqual('22222', testTrialCont2.openq__Trial_Tascan_ID__c, 'Trial Tascan Id did not match');

    }

    @isTest
    static void testTrialInvalidInput() {
        Contact testCont = [Select Id, openq__TaScanID__c FROM Contact WHERE Email = 'test_tascan1@testing.com'];

        TSTrialDataWrapper dataWrapper = new TSTrialDataWrapper();
        dataWrapper.per_id = Integer.valueOf(testCont.openq__TaScanID__c);
        dataWrapper.person_name_list = 'Tascan Trial';
        dataWrapper.trial_id = 22222;
        dataWrapper.study_type = 'Test interventional trial';
        dataWrapper.trial_registry_id = 'Test-NCT01966';
        dataWrapper.trial_name = 'Test Trial';
        dataWrapper.state = 'completed trials';
        dataWrapper.trial_purpose = 'Test purpose';
        dataWrapper.primary_outcomes = 'Test result achieved';
        dataWrapper.trial_participant_gender_restriction = 'Both';
        dataWrapper.phase = 'phase 2 trials';
        dataWrapper.enrollment = 40.0;
        dataWrapper.minimum_age = 18.0;
        dataWrapper.maximum_age = 80.0;
        dataWrapper.therapy_treatment = 'Test Treatment';
        dataWrapper.study_start = '2024-07-01T00:00:00.000Z';
        dataWrapper.study_end = '2024-07-01T00:00:00.000Z';
        dataWrapper.trial_url = 'http://testinglibrary.testing.com';
        dataWrapper.sponsors = 'Test Company1, Test Company2';
        dataWrapper.number_of_sites = 3;

        // passing invalid input - passing only object, not list of objects
        String requestBody = JSON.serialize(dataWrapper);

        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/TSTrialSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestBody);
        RestContext.request = req;
        RestContext.response= res;
        TSTrialDataReceiver.upsertIncomingValues();
        // publish platform event to create exception record
        Test.getEventBus().deliver();
        Test.stopTest();

        List<openq__OPENQ_Trial__c> trialList = [SELECT Id, Name, openq__Trial_Tascan_ID__c,
                                                                openq__Contact_Name__r.openq__TaScanID__c
                                                                FROM  openq__OPENQ_Trial__c LIMIT 100];

        Assert.areEqual(0, trialList.size(), 'Invalid input did not parse correctly');
        
        Interface_Log__c log = [Select Id, Result__c From Interface_Log__c 
                                WHERE Interface_Name__c = 'TSTrialSyncInterface'];

        Assert.areEqual('Fail', log.Result__c, 'Interface transaction did not fail');
       
    }

}
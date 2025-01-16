/**
*    @author Vishnu Priya Duggineni
*    @date   
*    @description  Test Class for ScheduledBatchSailPointUserSync
*    Modification Log:
*   ---------------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Vishnu Priya Duggineni                             Initial Version
*    Nishan Shetty                 25-Jan-2023          POL-862-Truncate title greater than 80 characters.
*    --------------------------------------------------------------------------------------------                
*/
@isTest(SeeAllData=false)
public with sharing class TestScheduledBatchSailPointUserSync {
    /*
    *@author: Vishnu Priya Duggineni
    *@Desc: Test method for Scheduled Job
    */
    @isTest
    public static void scheduleJob()
    {
        ScheduledBatchSailPointUserSync schedule = new ScheduledBatchSailPointUserSync();
        String cronExp = '0 0 18 ? * WED';
        Test.StartTest();
            String jobId = System.schedule('ScheduledBatchSailPointUserSync',  cronExp, schedule);
        Test.StopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        System.assertEquals(cronExp, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
    }
    /*
    *@author: Vishnu Priya Duggineni
    *@Desc: Test method for batch run
    */
    @isTest
    public static void batchRun()
    {      
        Id profileId = [SELECT Id FROM Profile WHERE Name = :TestDataUser.PROFILE_COMMERCIAL_OPS_QUOTING_USER].Id;
        User standardUser1 = TestDataUser.initStandardUser(profileId);
        standardUser1.Unique_Id__c='1234567';// TASK0573387 to check if Unique ID gets null if null returned in response.
        Insert standardUser1;
        set <Id> setUsers = new Set<Id>();
        setUsers.add(standardUser1.id);  
        Test.StartTest();
            Database.executeBatch(new ScheduledBatchSailPointUserSync(setUsers));
        Test.StopTest();

        User objUser=[select FirstName,LastName,Division,Department,Title,Unique_Id__c from User where id = :standardUser1.id];
        system.assertEquals('Test', objUser.FirstName);
        system.assertEquals('Batch', objUser.LastName);
        system.assertEquals('Strategy Test', objUser.Division);
        system.assertEquals('Strategy, Test', objUser.Department);
        system.assertEquals('Associate Director, Medical Affairs, Head of GDT/RH - Europe, Middle East & Afri', objUser.Title);//Code Coverage for POL-862
        system.assertEquals(null, objUser.Unique_Id__c);// TASK0573387 value will be null as response send null
    }
    /*
    *@author: Vishnu Priya Duggineni
    *@Desc: Test method for  MockSailPointConnector
    */
    @isTest
    static void testMockSailpoint(){
        test.startTest();
        HttpResponse res;
        HttpRequest req = new HttpRequest();
        res = new MockSailPointConnector().respondAuthError(req);
        system.assertEquals(403, res.getStatusCode());
    }
}
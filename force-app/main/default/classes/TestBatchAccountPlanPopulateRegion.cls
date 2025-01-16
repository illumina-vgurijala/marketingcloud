/*@ author       : Akshay Mohan
* @ date         : 10-09-2019
* @ Description  : Test class for TestBatchAccountPlanPopulateRegion
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan           10-09-2019                 Initial version
 */
@isTest
public with sharing class TestBatchAccountPlanPopulateRegion {

    @isTest 
    static void checkBatch(){
        Account objAccount = TestDataAccount.getAccount('Region Check');
        insert objAccount;
        Account_Plan__c objAccountPlan = TestDataAccountPlan.initAccoutPlan(objAccount.Id);
        insert objAccountPlan;
        objAccount.Territory_Region__c='AMR';
        update objAccount;

        Test.startTest();
        Database.executeBatch(new BatchAccountPlanPopulateRegion(new Set<Id>{objAccount.Id}), 10);
        Test.stopTest();

        objAccountPlan= [SELECT Account_Region__c FROM Account_Plan__c WHERE Id=:objAccountPlan.Id];
        System.debug('objAccountPlan: ' + objAccountPlan);
        System.assertEquals('AMR', objAccountPlan.Account_Region__c,'Region not set');
    }
}
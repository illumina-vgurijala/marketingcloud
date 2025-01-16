/*Class - Test Class for BatchClearWaterfallStageLeads 
* Author - Rishab Wali
* Date - 26th Sep 2022
*/
@isTest
public with sharing class TestBatchClearWaterfallStageLeads {

static testMethod void  testBatch()
{
    Lead ld=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
    Ld.Waterfall_Stage__c = 'Engaged';
    Ld.Status = 'New';
    Ld.Waterfall_Engaged_Date__c = System.now() - 400;
    Ld.Last_Responded_Campaign_Date__c = System.now() - 380;
    update Ld;
    test.startTest();
    BatchClearWaterfallStageLeads btch = new BatchClearWaterfallStageLeads();
    Database.executeBatch(btch);
    test.stopTest();
    Lead objLead = [SELECT Id,Waterfall_Stage__c from Lead where Id =: ld.Id];
    System.assert(String.isBlank(objLead.Waterfall_Stage__c),'Waterfall_Stage__c not set correctly');
}

}

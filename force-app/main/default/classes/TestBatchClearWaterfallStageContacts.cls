/*Class - Test Class for BatchClearWaterfallStageContacts 
* Author - Rishab Wali
* Date - 26th Sep 2022
*/
@isTest
public with sharing class TestBatchClearWaterfallStageContacts {

static testMethod void  testBatch()
{
    Contact con=TestDataMarketing.createContact('testfirstnameing','testlastnameing','test@gmail.com');
    con.Waterfall_Stage__c = 'Engaged';
    con.Marketing_Contact_Status__c = 'New';
    con.Waterfall_Engaged_Date__c = System.now() - 400;
    con.Last_Responded_Campaign_Date__c = System.now() - 370;
    update con;
    Test.StartTest();
    BatchClearWaterfallStageContacts btch = new BatchClearWaterfallStageContacts();
    Database.executeBatch(btch);
    Test.StopTest();
    Contact objCon = [SELECT Id,Waterfall_Stage__c from Contact where id =: con.Id];
    System.assert(String.isBlank(objCon.Waterfall_Stage__c),'Waterfall Stage not correctly set');
}

}

/**
*    @author: Rishab Wali
*    @date:   06-Jan-2022
*    @description:  Test class for Events Class
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestEvents {

    @isTest
    static void testEventsCheck()
    {
        lead objLead = TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname2','test2@gmail.com','Germany','test2Company');
        insert objLead;

        Event objEvt = new Event();
        objEvt.whoId = objLead.id;
        objEvt.subject='Email';
        objEvt.StartDateTime = System.now()+10;
        objEvt.EndDateTime = System.now()+15;
        insert objEvt;

        objEvt.StartDateTime = System.now()+20;
        objEvt.EndDateTime = System.now()+25;
        update objEvt;

        Lead objLd = [SELECT Id,Most_Recent_Activity_Date__c FROM Lead WHERE Id =: objLead.Id];
        System.assertEquals(objLd.Most_Recent_Activity_Date__c,objEvt.StartDateTime,'Dates not matching');
    }

}

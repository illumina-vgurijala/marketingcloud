/**
*    @author Ashwin Kumar
*    @date   
*    @description  Test class for TAPS_DeferredRecords
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Ashwin Kumar                   28-Mar-2022         Initial Version DCP-52339
*    --------------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestTAPS_DeferredRecords {

    @isTest static void deleteRecord() {

        Lead objLead1 = TestDataPerson.getNewLead();

        TAPS_Deferred_Record__c objDeferredRec = new TAPS_Deferred_Record__c(Object_Name__c = 'Lead', Record_ID__c = objLead1.Id);
        insert objDeferredRec;

        Test.startTest();
        delete objDeferredRec;
        Test.stopTest();

        List<TAPS_Processed_Record__c> lstProcessedRec = [SELECT Id FROM TAPS_Processed_Record__c WHERE Name = :objLead1.Id];
        System.assertEquals(1, lstProcessedRec.size(), 'Processed record is not inserted in TAPS_Processed_Record__c as expected');
    }
}
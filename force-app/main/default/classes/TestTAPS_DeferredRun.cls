/**
*    @author Todd Newman
*    @date   
*    @description  Test class for TAPS_DeferredRun
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Todd Newman                                        Initial Version
*           Satya Swain                    17-Dec-2020         DCP-43261/TASK0548217: Added logic for new design of TAPS_DeferredRun
*           Ashwin Kumar                   26-Apr-2021         INC0316527 - Added scheduleTerritoryJobs() to TAPS_DeferredRun.cover returnSpecificList()
*           Ashwin Kumar                   28-Mar-2022         DCP-52339: Update method name and remove TAPS_Deferred_Object__c & its field's references
*    --------------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestTAPS_DeferredRun {
    
    @isTest static void createRecord()
    {
        Account a = TestDataAccount.getNewAmrAccount();
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(a.Id);
        Comment__c comment = TestDataFieldService.getNewComment(wo.Id);

        List<TAPS_Deferred_Record__c> runs = TAPS_DeferredRun.getDeferredList('Comment__c', new Set<Id> { comment.Id });
        insert runs;
        TAPS_Deferred_Record__c run = runs.get(0);

        Test.startTest();
        {
            TAPS_DeferredRun scheduledClass = new TAPS_DeferredRun();
            scheduledClass.execute(null);
        }
        Test.stopTest();

        List<TAPS_Deferred_Record__c> lstDeferredRec = [SELECT Id FROM TAPS_Deferred_Record__c WHERE Id = :run.Id];
        List<TAPS_Processed_Record__c> lstProcessedRec = [SELECT Id FROM TAPS_Processed_Record__c WHERE Name = :comment.Id];
        System.assertEquals(0, lstDeferredRec.size(), 'Processed deferred record not deleted as expected');
        System.assertEquals(1, lstProcessedRec.size(), 'Processed record is not inserted in TAPS_Processed_Record__c as expected');
    }

    @isTest static void deferSharing()
    {
        Lead objLead1 = TestDataPerson.getNewLead();
        Lead objLead2 = TestDataPerson.getNewLead();

        TAPS_DeferredRun.deferSharing('Lead', new Set<Id> { objLead1.Id, objLead2.id });
        // for merging new lead ids with the existing TAPS_Deferred_Run__c record.-PRB0043528
        //TAPS_DeferredRun.deferSharing('Lead', new Set<Id> { objLead2.Id });

        List<TAPS_Deferred_Record__c> runs = [SELECT Object_Name__c, Record_ID__c, Is_Processing__c FROM TAPS_Deferred_Record__c LIMIT 100];
        System.assertEquals(2, runs.size(), 'Deferred records not created as expected');
        System.assertEquals('Lead', runs.get(0).Object_Name__c, 'Deferred record not created with Lead object type as expected');
    }

    @isTest static void runJobAgain()
    {
        TAPS_DeferredRun dr = new TAPS_DeferredRun();
        Id jobId = dr.runJobAgain(3);

        List<CronTrigger> ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, ct.size(), 'Given job not scheduled as expected');

    }

    @isTest static void scheduleNoJobs()
    {
        TAPS_DeferredRun deferred = new TAPS_DeferredRun();
        deferred.executeDeferredJobs(new Map<String, Map<Id, TAPS_Deferred_Record__c>>());     //DCP-52339

        List<TAPS_Deferred_Record__c> runs = [SELECT Object_Name__c, Record_ID__c, Is_Processing__c FROM TAPS_Deferred_Record__c LIMIT 100];
        System.assertEquals(0, runs.size(), 'No Deferred records created as expected');
    }

    @isTest static void scheduleAccountJobs()
    {
        Account a = TestDataAccount.getNewAmrAccount();
        List<TAPS_Deferred_Record__c> runs = TAPS_DeferredRun.getDeferredList('Account', new Set<Id> { a.Id });
        insert runs;
        
        TAPS_Deferred_Record__c run = [Select Id, Object_Name__c, Record_ID__c, Is_Processing__c FROM TAPS_Deferred_Record__c WHERE Object_Name__c = 'Account' LIMIT 1];

        Test.startTest();
        {
            TAPS_DeferredRun deferred = new TAPS_DeferredRun();
            deferred.execute(null);  //DCP-52339
        }
        Test.stopTest();

        List<TAPS_Deferred_Record__c> lstDeferredRec = [SELECT Id FROM TAPS_Deferred_Record__c WHERE Id = :run.Id];
        List<TAPS_Processed_Record__c> lstProcessedRec = [SELECT Id FROM TAPS_Processed_Record__c WHERE Name = :a.Id];
        System.assertEquals(0, lstDeferredRec.size(), 'Processed deferred record not deleted as expected');
        System.assertEquals(1, lstProcessedRec.size(), 'Processed record is not inserted in TAPS_Processed_Record__c as expected');
    }
    
    @isTest
    static void testOrchestrationImpl()
    {        
        Account a = TestDataAccount.getNewAmrAccount();
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(a.Id);
        Comment__c comment = TestDataFieldService.getNewComment(wo.Id);
        
        Test.startTest();
        
        Set<Id> commentIds = new Set<Id>{comment.id};
        DeferExecution deferExecInstance = new DeferExecution();
        deferExecInstance.processChunk('Comment__c',commentIds);
        deferExecInstance.execute();
        List<TAPS_Deferred_Record__c> deferredRecords = [Select Id, Object_Name__c, Record_ID__c, Is_Processing__c FROM TAPS_Deferred_Record__c WHERE Object_Name__c = 'Comment__c'];
        System.assert(!deferredRecords.isEmpty(), 'Deferred record not created as expected');
        
        RunOrDeferExecution runDeferInstance = new RunOrDeferExecution();
        runDeferInstance.processChunk('Comment__c',commentIds);
        runDeferInstance.execute();
        List<TAPS_Deferred_Record__c> deferredRecords2 = [Select Id, Object_Name__c, Record_ID__c, Is_Processing__c FROM TAPS_Deferred_Record__c WHERE Object_Name__c = 'Comment__c'];
        System.assertEquals(1, deferredRecords2.size(), 'Deferred record not created as expected'); //  no deferring

        Test.stopTest();
    }

    //INC0316527
    @isTest static void scheduleTerritoryobs()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryData();
        }
        
        Id territoryId = [SELECT Id FROM Territory2 LIMIT 1]?.Id;
        List<TAPS_Deferred_Record__c> runs = TAPS_DeferredRun.getDeferredList('Territory2', new Set<Id> { territoryId });
        insert runs;

        TAPS_Deferred_Record__c run = [Select Id, Object_Name__c, Record_ID__c, Is_Processing__c FROM TAPS_Deferred_Record__c WHERE Object_Name__c = 'Territory2' LIMIT 1];

        Test.startTest();
        {
            TAPS_DeferredRun deferred = new TAPS_DeferredRun();
            deferred.execute(null);  //DCP-52339
        }
        Test.stopTest();

        List<TAPS_Deferred_Record__c> lstDeferredRec = [SELECT Id FROM TAPS_Deferred_Record__c WHERE Id = :run.Id];
        List<TAPS_Processed_Record__c> lstProcessedRec = [SELECT Id FROM TAPS_Processed_Record__c WHERE Name = :territoryId];
        System.assertEquals(0, lstDeferredRec.size(), 'Processed deferred record not deleted as expected');
        System.assertEquals(1, lstProcessedRec.size(), 'Processed record is not inserted in TAPS_Processed_Record__c as expected');
    }

    @isTest static void testRevertProcessingFlagFromList()
    {
        Lead objLead1 = TestDataPerson.getNewLead();
        List<TAPS_Deferred_Record__c> lstDeferredRec = TAPS_DeferredRun.getDeferredList('Lead', new Set<Id> { objLead1.Id });
        lstDeferredRec[0].Is_Processing__c = true;
        insert lstDeferredRec;

        Test.startTest();
        TAPS_DeferredRun.revertIsProcessingFlag(lstDeferredRec);
        Test.stopTest();

        TAPS_Deferred_Record__c objDeferredRec = [SELECT Is_Processing__c FROM TAPS_Deferred_Record__c WHERE Id = :lstDeferredRec[0].Id];
        System.assert(!objDeferredRec.Is_Processing__c, 'Is processing flag not reverted to false as expected');
    }

    @isTest static void testRevertProcessingFlagFromSet()
    {
        Lead objLead1 = TestDataPerson.getNewLead();
        List<TAPS_Deferred_Record__c> lstDeferredRec = TAPS_DeferredRun.getDeferredList('Lead', new Set<Id> { objLead1.Id });
        lstDeferredRec[0].Is_Processing__c = true;
        insert lstDeferredRec;

        Test.startTest();
        TAPS_DeferredRun.revertIsProcessingFlag(new Set<Id> { objLead1.Id });
        Test.stopTest();

        TAPS_Deferred_Record__c objDeferredRec = [SELECT Is_Processing__c FROM TAPS_Deferred_Record__c WHERE Id = :lstDeferredRec[0].Id];
        System.assert(!objDeferredRec.Is_Processing__c, 'Is processing flag not reverted to false as expected');
    }
	
	/*Test method to cover Catch Block of Class TAPS_DeferredRunQueueable
	*/
   @isTest
   public static void coverCatchBlockTAPSDeferredRunQueueable(){
    try{
        TAPS_DeferredRunQueueable.catchException = true;
        TAPS_DeferredRunQueueable td = new TAPS_DeferredRunQueueable(null, null);
        Test.startTest();
        System.enqueueJob(td);
        Test.stopTest();
    	}catch(Exception e){
            System.assert(e!=null, 'e is not empty');
    	}
   }
}
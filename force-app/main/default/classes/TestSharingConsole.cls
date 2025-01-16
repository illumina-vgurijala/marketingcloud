/**  
*    @description  Test class for SharingConsole
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Ashwin Kumar                   28-Mar-2022         DCP-52339: Remove TAPS_Deferred_Object__c & its field's references
*    --------------------------------------------------------------------------------------------------------------------------------------------
*
**/
@isTest
public with sharing class TestSharingConsole {
    
    @testSetup static void setupEtmData()
    {
        setupTerritoryData();
    }
    static void setupTerritoryData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryData();
        }
    }
    @isTest static void testRetreiveSharing() {
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        Apttus_Approval__Approval_Request__c rec1;
        rec1 = TestDataProposal.getNewApprovalRequest(quote1.Id);
        Test.getEventBus().deliver();
        List<id> recordIds = new List<Id>();
        recordIds.add(rec1.Id);
    
        Test.startTest();
        {
            SharingConsole.retriveShareRecords(recordIds);
        }
        Test.stopTest();
        List<Apttus_Approval__Approval_Request__Share> shareRecords = [SELECT Id FROM Apttus_Approval__Approval_Request__Share WHERE ParentId = :rec1.Id AND RowCause = :Schema.Apttus_Approval__Approval_Request__Share.RowCause.Manual];
        System.assertEquals(2, shareRecords.size());
    }

    @isTest static void testDeferredRun(){
        Account a = TestDataAccount.getNewAmrAccount();
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(a.Id);
        Comment__c comment = new Comment__c();
        try{
            comment = TestDataFieldService.getNewComment(wo.Id);
        }
        catch(exception e)
        {
            system.debug(e);
        }

        List<TAPS_Deferred_Record__c> runs = TAPS_DeferredRun.getDeferredList('Comment__c', new Set<Id> { comment.Id });
        insert runs;
        TAPS_Deferred_Record__c run = runs.get(0);

        Test.startTest();
        {
            sharingconsole.retriveDeferredRun();
        }
        Test.stopTest();

        List<TAPS_Deferred_Record__c> deferredRuns = [SELECT Id FROM TAPS_Deferred_Record__c WHERE Id = :run.Id];
        System.assertEquals(1, deferredRuns.size());

    }
    @isTest static void testRerunSharingRecordApprovalRequests() {
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        Apttus_Approval__Approval_Request__c rec1;
        rec1 = TestDataProposal.getNewApprovalRequest(quote1.Id);
        List<id> recordIds = new List<Id>();
        recordIds.add(rec1.Id);

        Test.startTest();
        {
            SharingConsole.reRunSharingRecords(recordIds);
        }
        Test.stopTest();

        List<TAPS_Processed_Record__c> lstProcessedRec = [SELECT Id FROM TAPS_Processed_Record__c WHERE Name = :rec1.Id];
        System.assertEquals(1, lstProcessedRec.size(), 'Processed record is not inserted in TAPS_Processed_Record__c as expected');
    }
    @isTest static void testRerunSharingRecordInstalledProducts() {
        List<Id> accountIds = TestTAPS.createParentAccounts();
        SVMXC__Installed_Product__c rec1;
        rec1 = TestDataInstalledProduct.getNewInstalledProduct(accountIds.get(0));

        List<id> recordIds = new List<Id>();
        recordIds.add(rec1.Id);

        Test.startTest();
        {
            SharingConsole.reRunSharingRecords(recordIds);
        }
        Test.stopTest();

        List<TAPS_Processed_Record__c> lstProcessedRec = [SELECT Id FROM TAPS_Processed_Record__c WHERE Name = :rec1.Id];
        System.assertEquals(1, lstProcessedRec.size(), 'Processed record is not inserted in TAPS_Processed_Record__c as expected');
    }
    @isTest static void testRerunSharingRecordCustomerReadinessForm() {
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Customer_Readiness_Form__c rec1;
        rec1 = TestDataOpportunity.getNewCrf(accountIds.get(0), o1.Id);

        List<id> recordIds = new List<Id>();
        recordIds.add(rec1.Id);

        Test.startTest();
        {
            SharingConsole.reRunSharingRecords(recordIds);
        }
        Test.stopTest();

        List<TAPS_Processed_Record__c> lstProcessedRec = [SELECT Id FROM TAPS_Processed_Record__c WHERE Name = :rec1.Id];
        System.assertEquals(1, lstProcessedRec.size(), 'Processed record is not inserted in TAPS_Processed_Record__c as expected');
    }
    @isTest static void testRerunSharingRecordOpportunties() {
        // List<Id> accountIds = TestTAPS.createParentAccounts();
        // Opportunity rec1;
        
        // rec1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Account a = TestDataAccount.getNewAmrAccount();
        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(a.Id);
        Comment__c comment = new Comment__c();
        try {
            comment = TestDataFieldService.getNewComment(wo.Id);
           } catch (Exception e) {
               system.debug(e);
           }

        List<id> recordIds = new List<Id>();
        recordIds.add(comment.Id);

        Test.startTest();
        {
            try {
                SharingConsole.reRunSharingRecords(recordIds);
               } catch (Exception e) {
                system.debug('e '+e);
               }//DGP-31
        }
        
        Test.stopTest();

        try {
            List<TAPS_Processed_Record__c> lstProcessedRec = [SELECT Id FROM TAPS_Processed_Record__c WHERE Name = :comment.Id];
        System.assertEquals(1, lstProcessedRec.size(), 'Processed record is not inserted in TAPS_Processed_Record__c as expected');
        } catch (Exception e) {
            system.debug(e);
        }
    }

}
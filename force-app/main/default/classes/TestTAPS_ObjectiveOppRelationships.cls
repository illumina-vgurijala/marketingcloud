/**
 *    @author Adyasha Satapathy
 *    @date   06-December-2021
 *    @description : DCP-50392 : Test class for TAPS_ObjectiveOpportunityRelationships
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer             Date                      Description
 *    Adyasha           06-December-2021            Initial Version
 *    Ashwin Kumar      31-Mar-2021                 DCP-52339 Remove TestTAPS.setupDeferredObjectData
 *    -----------------------------------------------------------------------------------------------        
 */
@isTest
public with sharing class TestTAPS_ObjectiveOppRelationships
{
    private static TAPS_ComposedBase shareClass;
    @testSetup 
    static void setupEtmData()
    {
        setupTerritoryData();
    }

    static void setupTerritoryData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser)
        {
            TestTAPS.setupTerritoryData();
        }
    }

    private static TAPS_ComposedBase getShareClass()
    {
        if (shareClass == null) { shareClass = new TAPS_ObjectiveOpportunityRelationships(); }
        return shareClass;
    }

    @isTest
    static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        System.debug('accountIds: ' + accountIds);
        Id idAccount = accountIds.get(0);

        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test', 'country');
        insert serviceTeam;

        User objUser = TestDataUser.findUserInProfile(Label.Field_Service);

        SVMXC__Service_Group_Members__c technician = TestDataFieldService.createTechnician(objUser.Id, 'Test Technician', serviceTeam.id);
        technician.SVMXC__Email__c = 'b@b.com';
        insert technician;

        Account_to_Field_Support__c accToFieldSupport = TestDataFieldService.createAccountToFieldSupport(idAccount, 'Primary Field Service Engineer', technician.id);
        insert accToFieldSupport;

        // add record
        Account_Plan__c objAccountPlan = TestDataAccountPlan.initAccoutPlan(idAccount);
        insert objAccountPlan;
        
        Objective__c objObjective = TestDataObjectives.initObjective(objAccountPlan.Id);
        insert objObjective;

        Objective_Opportunity_Relationship__c objRelationship = new Objective_Opportunity_Relationship__c();
        objRelationship.Account_Plan__c = objAccountPlan.Id;
        objRelationship.Account_Plan_Objective__c = objObjective.Id;

        Test.startTest();
                
        insert objRelationship;
        Test.getEventBus().deliver();
        
        Test.stopTest();

        // validate shares were added by batch
        List<Objective_Opportunity_Relationship__Share> lstShareRecords = [
            SELECT AccessLevel ,UserOrGroupId, UserOrGroup.Name 
            FROM Objective_Opportunity_Relationship__Share 
            WHERE ParentId = :objRelationship.Id
            AND RowCause='Manual'
        ];

        System.debug('lstShareRecords: ' + lstShareRecords);
        System.assertEquals(3, lstShareRecords.size(),'Share records not created as expected');
        
        Set<Id> recordIds = getShareClass().getRecordIdsFromAccountIdsCustom(new Set<Id>(accountIds));
        System.assert(recordIds.contains(objRelationship.Id), 'idsFromAccountIds: Did not successfully convert from account IDs to record IDs');
        getShareClass().getRecordIdsFromModifiedRecordIdsCustom(new Set<Id> {objObjective.Id});

        Boolean booFoundFieldSupportShare = false;
        for (Objective_Opportunity_Relationship__Share objshare : lstShareRecords)
        {
            if (objUser.id == objshare.UserOrGroupId && objshare.AccessLevel == 'Read')
            {
                booFoundFieldSupportShare = true;
            }
        }
        System.assert(booFoundFieldSupportShare, 'Read Share record not created for field support user');
    }
}
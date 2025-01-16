/**
 *      @author Gerardo Garcia
 *      Created Date 2023-10-02
 *      Modification Log
 *    ------------------------------------------------------------------------------------------------------------------------
 *          Developer                       Date(YY-MM-DD)                  Description
 *          Gerardo Garcia                  2023-10-02                      CMCM-2893 Initial CCT sharing implementation
 *    ------------------------------------------------------------------------------------------------------------------------
 */

@IsTest
private class TestTAPS_CompetitiveComplementaryTech {

    // these methods do most of the object-specific work, modify all of them
    private static TAPS_ComposedBase mshareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mshareClass == null) mshareClass = new TAPS_CompetitiveComplementaryTech();
        return mshareClass;
    }

    @TestSetup
    static void makeData(){
        Feature.setMockFeatureFlag(Feature.TAPS_CCT, true);

        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryData();
        }
    }

    private static List<Competitive_Complementary_Technology__Share> getShareRecords(Id parentId, Set<Id> userIds)
    {
        return [SELECT Id
        FROM Competitive_Complementary_Technology__Share
        WHERE ParentId = :parentId
        AND RowCause = :Schema.Competitive_Complementary_Technology__Share.RowCause.Manual
        AND UserOrGroupId IN :userIds];
    }

    @IsTest
    private static void triggerInsertShareUsersFromSameHerarchyAccount(){
        // Creates accounts and assign them territories(ObjectTerritory2Association) ac1->TERRITORY1, ac2->TERRITORY2, u1->TERRITORY1, u2->TERRITORY3 
        List<Id> accountIds = TestTAPS.createParentAccounts();

        Competitive_Complementary_Technology__c ct;
        Test.startTest();
        {
            ct = TestDataCompetitiveCompTech.initCompetitiveCompTech(accountIds[0]); // CCT to Territory1 ac1
            insert ct;
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        Assert.areEqual(2, TestTAPS.getShareRecordCount(getShareClass(), ct.Id), 'Number of share records do not match');
    }

    @IsTest
    private static void triggerUpdateShareUsersFromSameHerarchyAccount(){
        // Creates accounts and assign them territories(ObjectTerritory2Association) ac1->TERRITORY1, ac2->TERRITORY2, u1->TERRITORY1, u2->TERRITORY3 
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Competitive_Complementary_Technology__c ct;
        Account uc2 = [SELECT id FROM Account WHERE Name = :TestTAPS.UC2_NAME];
        Test.startTest();
        {
            ct = TestDataCompetitiveCompTech.initCompetitiveCompTech(accountIds[0]); // CCT to Territory1 ac1
            insert ct;
            
            // update account assignment to uc2(account)->territory3 with territoryUser2
            ct.Account__c = uc2.id;
            update ct;

            Test.getEventBus().deliver();
        }
        Test.stopTest();

        UserTerritory2Association territoryUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2.Name = :TestTAPS.TERRITORY1 LIMIT 1];
        Assert.areEqual(0, getShareRecords(ct.id, new Set<Id> {territoryUser1.UserId}).size(), 'territoryUser1 should not have sharing record!');

        UserTerritory2Association territoryUser2 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2.Name = :TestTAPS.TERRITORY3 LIMIT 1];
        Assert.areEqual(1, getShareRecords(ct.id, new Set<Id> {territoryUser2.UserId}).size(), 'territoryUser2 should have sharing record!');
    }

    @IsTest
    private static void triggerInsertShareUsersCP() {

        Territory2Model activeModel = [SELECT Id FROM Territory2Model WHERE State = 'Active' LIMIT 1];
        Territory2 district1 = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.DISTRICT1 LIMIT 1];
        Territory2 district2 = [SELECT Id FROM Territory2 WHERE Name = :TestTAPS.DISTRICT2 LIMIT 1];
        
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            // creates distribuitor account with contacts and creates a CP users from dist account and generates territories from given districts
            TestTAPS.setupIndirectTerritoryData(activeModel.id, district1, district2);
        }

        // Assign ObjectTerritory2Association for ac1 and ac2(herarchy Territory and cp territory) uc1, uc2(give herarchy territory) 
        List<Id> accountIds = TestTAPS.createParentAccounts();

        Competitive_Complementary_Technology__c ct;
        Test.startTest();
        {
            ct = TestDataCompetitiveCompTech.initCompetitiveCompTech(accountIds[0]); // CCT to Territory1 ac1
            insert ct;
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        UserTerritory2Association associatedUser1 = [SELECT UserId FROM UserTerritory2Association WHERE Territory2.Name = :TestTAPS.TERRITORY1_CP LIMIT 1];
        System.debug('associatedUser1:' +  associatedUser1);
        Assert.areEqual(1, getShareRecords(ct.id, new Set<Id> {associatedUser1.UserId}).size(), 'CP user should have sharing record');
    }

    @IsTest
    private static void vefifyFeatureOff(){
        Feature.setMockFeatureFlag(Feature.TAPS_CCT, false);

        List<Id> accountIds = TestTAPS.createParentAccounts();

        Competitive_Complementary_Technology__c ct;
        Test.startTest();
        {
            ct = TestDataCompetitiveCompTech.initCompetitiveCompTech(accountIds[0]);
            insert ct;
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        Assert.areEqual(0, TestTAPS.getShareRecordCount(getShareClass(), ct.Id), 'No share records should be created, The feature flag is Off!');
    }
}
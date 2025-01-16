/**
 * @actor illumina
 * @description :-
 */
@isTest(SeeAllData = true)
// NOTE: SeeAllData required or ServiceMax managed triggers will bomb
/***************************************************************************************************************************************
* NAME   : TestTAPS_SmaxPartsOrders 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
private class TestTAPS_SmaxPartsOrders {

    // NOTE: TestTAPS covers scenarios like new user, new territory, territory move
    // this is just to make sure we have coverage of the specific object trigger

    // these methods do most of the object-specific work, modify all of them

    private static TAPS_ComposedBase mshareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mshareClass == null) mshareClass = new TAPS_SmaxPartsOrders();
        return mshareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId)
    {
        update new SVMXC__Service_Order__c(Id = recordId, SVMXC__Company__c = newParentId);
    }

    private static List<ObjectTerritory2Association> getSomeAssociations(Set<Id> soldToIds)
    {
        List<ObjectTerritory2Association> associations =
        [SELECT Id, ObjectId, Territory2Id
        FROM ObjectTerritory2Association
        WHERE Territory2.Territory2Type.DeveloperName = :TerritoryTypesService.TYPE_TERRITORY
        AND Territory2.Territory2Model.State = 'Active'
        AND ObjectId IN :soldToIds
        LIMIT 10];

        return associations;
    }

    private static Integer userCountForTerritory(Id territoryId)
    {
        Map<Id, Set<Id>> leafIdToParentIds = new TerritoriesSelector().selectTerritoriesInHierarchy(new Set<Id> { territoryId });
        Set<Id> setAllTerritoryIds = new Set<Id>();
        for (Id leafId : leafIdToParentIds.keySet())
        {
            setAllTerritoryIds.add(leafId);
            setAllTerritoryIds.addAll(leafIdToParentIds.get(leafId));
        }

        List<UserTerritory2Association> userAlignments = new UserTerritory2AssociationSelector().selectByTerritoryId(setAllTerritoryIds);

        Set<Id> uniqueUsers = UtilsCollection.getSetOfIds(userAlignments, 'UserId');
        return uniqueUsers.size();
    }

    @isTest static void objectType()
    {
        System.assertEquals(SVMXC__RMA_Shipment_Order__c.sObjectType, getShareClass().getObjectType());
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        Account accountWithTerritories = [
            SELECT Id
            FROM Account
            WHERE Account_Group__c = 'Sold To'
            AND Territory_Region__c != null
            AND Territory_Name__c != null
            LIMIT 1
        ];
        Set<Id> soldToIds = new Set<Id> {accountWithTerritories.Id};

        List<ObjectTerritory2Association> associations = getSomeAssociations(soldToIds);
        if (associations.size() < 1) return;

        ObjectTerritory2Association assoc1 = associations.get(0);
        Id accountId = assoc1.ObjectId;
        Integer userCount = userCountForTerritory(assoc1.Territory2Id);

        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(accountId);
        SVMXC__Site__c location1 = TestDataFieldService.getNewLocation(accountId);
        SVMXC__RMA_Shipment_Order__c rec1;

        Test.startTest();
        {
            rec1 = TestDataFieldService.getNewPartsOrder(wo.Id, location1.Id);
            // Added by Satya as part of PRB0042764
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        //System.assertEquals(userCount, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));

        // also check record id conversion method
        Set<Id> recordIds = getShareClass().getRecordIdsFromAccountIdsCustom(soldToIds);
        getShareClass().getRecordIdsFromModifiedRecordIdsCustom(new Set<Id> {wo.Id});
        System.assert(recordIds.contains(rec1.Id), 'idsFromAccountIds: Did not successfully convert from account IDs to record IDs');
    }

    // move a record from one account to another (and therefore from one territory to another)
    // the old shares should go away and new shares created
    @isTest static void customReparent()
    {
        Account accountWithTerritories1 = [
            SELECT Id, Territory_Name__c
            FROM Account
            WHERE Account_Group__c = 'Sold To'
            AND Territory_Region__c != null
            AND Territory_Name__c != null
            LIMIT 1
        ];
        Account accountWithTerritories2 = [
            SELECT Id
            FROM Account
            WHERE Account_Group__c = 'Sold To'
            AND Territory_Region__c != null
            AND Territory_Name__c != null
            AND Territory_Name__c != :accountWithTerritories1.Territory_Name__c
            LIMIT 1
        ];
        Set<Id> soldToIds = new Set<Id> {accountWithTerritories1.Id, accountWithTerritories2.Id};

        List<ObjectTerritory2Association> associations = getSomeAssociations(soldToIds);
        if (associations.size() < 1) return;

        Id territory1Id;
        Id territory2Id;
        for (ObjectTerritory2Association assoc : associations)
        {
            if (accountWithTerritories1.Id == assoc.ObjectId)
                territory1Id = assoc.Territory2Id;
            if (accountWithTerritories2.Id == assoc.ObjectId)
                territory2Id = assoc.Territory2Id;

            if (territory1Id != null && territory2Id != null)
                break;
        }

        //Integer userCountBefore = userCountForTerritory(territory1Id);
        Integer userCountAfter = userCountForTerritory(territory2Id);

        SVMXC__Service_Order__c wo = TestDataFieldService.getNewWorkOrder(accountWithTerritories1.Id);
        SVMXC__Site__c location1 = TestDataFieldService.getNewLocation(accountWithTerritories1.Id);
        SVMXC__RMA_Shipment_Order__c rec1 = TestDataFieldService.getNewPartsOrder(wo.Id, location1.Id);

        Test.startTest();
        {
            reparentRecord(wo.Id, accountWithTerritories2.Id);
            // Added by Satya as part of PRB0042764
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        //System.assertEquals(userCountAfter, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));
    }

}
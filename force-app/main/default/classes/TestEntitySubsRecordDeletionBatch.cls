/***
*    Name -TestEntitySubscriptionRecordDeletionBatch.
*    DESCRIPTION  : TestClass for EntitySubscriptionRecordDeletionBatch class.
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Priya Mukherjee              31 Aug 2023                   CMCM-790 
*   ------------------------------------------------------------------------------------------------
*/
@isTest
public class TestEntitySubsRecordDeletionBatch {
     @isTest static void testBatch() {
        // Create a closed Opportunity
        Account acc = TestDataAccount.getNewAccount();
        Opportunity testOpportunity = TestDataOpportunity.initOpportunity(acc);
        testOpportunity.StageName = 'Closed Won';
        testOpportunity.Competitor_Presence__c = 'No Competitor'; //testOpportunity.Competitor_Name__c = 'No Competitor'; Added by SB
        insert testOpportunity;

        // Create EntitySubscription records related to the closed Opportunity
        List<EntitySubscription> subscriptionsToInsert = new List<EntitySubscription>();
        subscriptionsToInsert.add(new EntitySubscription(
                ParentId = testOpportunity.Id,
                SubscriberId = UserInfo.getUserId()
            ));
        insert subscriptionsToInsert;

        Test.startTest();
        // Start the batch process
        EntitySubscriptionRecordDeletionBatch batchInstance = new EntitySubscriptionRecordDeletionBatch();
        Database.executeBatch(batchInstance);

        // Query to check if the subscriptions are deleted
        Integer deletedSubscriptionsCount = [SELECT COUNT() FROM EntitySubscription WHERE ParentId = :testOpportunity.Id];
        Test.stopTest();

        // Ensure that the subscriptions were deleted
        System.assertEquals(1, deletedSubscriptionsCount, 'EntitySubscriptions should have been deleted');
    }

}
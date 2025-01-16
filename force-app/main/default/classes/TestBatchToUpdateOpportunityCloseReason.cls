/**
*    @author Sai Pasumarthy
*    @date   2024-09-26
*    @description   CMCM-6757 : C&CT: [OPP] Create 'Close Reason - Other' field
*    Test classes for 75%: BatchToUpdateOpportunityCloseReason
* 
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Sai Pasumarthy              2024-09-26            Initial Version
*    -----------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
public class TestBatchToUpdateOpportunityCloseReason {
   
    private static final String OPPORTUNITY_CLOSE_REASON_OTHER = 'Pre-CCT';    
    @testSetup
    static void setupData() {
        Account soldToAccount = TestDataAccount.getAccount('Sold To Account');
        Account ultimateConsigneeAccount1 = TestDataAccount.getAccount('Ultimate Consignee Account 1');
        Account ultimateConsigneeAccount2 = TestDataAccount.getAccount('Ultimate Consignee Account 2');
        insert new List<Account>{soldToAccount, ultimateConsigneeAccount1, ultimateConsigneeAccount2};

        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        for(Integer i = 0; i<5; i++){
            Opportunity newOpportunity = TestDataOpportunity.initOpportunity(soldToAccount,Label.OpportunityRTIndirectStandard);
            newOpportunity.Name = 'Ultimate Consignee 1 - Opportunity '+ i;
            newOpportunity.Ultimate_Consignee__c = ultimateConsigneeAccount1.Id;
            newOpportunity.StageName = 'Closed Abandoned';
            newOpportunity.Abandon_Reason__c = 'Other';
            opportunitiesToInsert.add(newOpportunity);
        }
        Database.insert(opportunitiesToInsert, false);
    }

    @IsTest
    static void testUpdateOpportunityCloseReason() {
        Test.startTest();
        BatchToUpdateOpportunityCloseReason batchJob = new BatchToUpdateOpportunityCloseReason();
        Database.executeBatch(batchJob);
        Test.stopTest();

        List<Opportunity> updatedOpportunities = [
            SELECT Id, Close_Reason_Other__c
            FROM Opportunity
            WHERE Abandon_Reason__c = 'Other'
        ];

        System.assertEquals(5, updatedOpportunities.size(), 'Expected opportunities to be updated');
        for(Opportunity opportunity : updatedOpportunities) {
            System.assertEquals(OPPORTUNITY_CLOSE_REASON_OTHER, opportunity.Close_Reason_Other__c, 'Close Reason Other should be updated');
        }
    }
}
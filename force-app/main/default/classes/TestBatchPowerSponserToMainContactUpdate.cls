/***
*    Name -testBatchUpdatePowerSponserToMainContact.
*    DESCRIPTION  : TestClass for BatchUpdatePowerSponserToMainContact class.
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Priya Mukherjee              13 Sept 2023                   CMCM-2875 
*   ------------------------------------------------------------------------------------------------
*/
@isTest
public class TestBatchPowerSponserToMainContactUpdate {
 @isTest
    static void testBatchWithRecordsToUpdate() {
        // Create Account, Contact, and Opportunity records 
        Account acc1 = TestDataAccount.getAccount('Territory Account');
        acc1.Territory_Region__c = 'China';
        acc1.ERP_Customer_Id__c = '123456';
        insert acc1;  
        
        Contact con1 = TestDataPerson.initContact(acc1.Id);
        insert con1;
        
        List<Opportunity> lstOpp = new List<Opportunity>();
        set<Id> setOppIds = new set<Id>();
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id; 
        lstOpp.add(opp1);
        setOppIds.add(opp1.id);
        insert lstOpp;    

        // Create OpportunityContactRole with 'Power Sponsor' role
        OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('', con1.Id, lstOpp[0].Id);
        ocr1.Role = 'Power Sponsor';
        insert ocr1;
        
        OpportunityContactRole ocr2 = TestDataOpportunity.getNewOpportunityContactRole('', con1.Id, lstOpp[0].Id);
        ocr2.Role = 'Power Sponsor';
        insert ocr2;

        Test.startTest();
        BatchUpdatePowerSponserToMainContact batchInstance = new BatchUpdatePowerSponserToMainContact();
        Database.executeBatch(batchInstance);
        Test.stopTest();

        // Verify that all OpportunityContactRole records with 'Power Sponsor' role are updated
        List<OpportunityContactRole> updatedRoles = [SELECT Role FROM OpportunityContactRole WHERE Id IN :new Set<Id>{ocr1.Id, ocr2.Id}];
        for (OpportunityContactRole updatedRole : updatedRoles) {
            System.assertEquals('Main Contact', updatedRole.Role, 'Role updated');
        }
    }

   
}
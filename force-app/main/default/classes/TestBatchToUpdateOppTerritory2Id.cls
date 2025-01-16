/**
*    @author: Enrique Reyes 
*    @date:   27-Nov-2023
*    @description:  Test class for BatchToUpdateOppTerritory2Id 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*       Developer                      Date               Description
*       Enrique Reyes                  27-Nov-2023        Initial Development
*    ------------------------------------------------------------------------------------ 
*/
@isTest(isparallel=false)
public class TestBatchToUpdateOppTerritory2Id {	
	@testSetup
    public static void setupData() {
        Account soldToAccount = TestDataAccount.getAccount('Sold To Account');
        Account ultimateConsigneeAccount1 = TestDataAccount.getAccount('Ultimate Consignee Account 1');
        Account ultimateConsigneeAccount2 = TestDataAccount.getAccount('Ultimate Consignee Account 2');
        insert new List<Account>{soldToAccount, ultimateConsigneeAccount1, ultimateConsigneeAccount2};

        List<Territory2Model> lstModels =
            [SELECT Id, Name, (SELECT Id, Name FROM Territory2s WHERE Territory2Type.DeveloperName = 'Territory')
             FROM Territory2Model
             WHERE State = 'Active'];

        Territory2Model objTerritoryModel = lstModels.get(0);

        Territory2 objTerritory1 = objTerritoryModel.Territory2s.get(0);
        Territory2 objTerritory2 = objTerritoryModel.Territory2s.get(1);

        //Insert Object2TerritoryAssociation
        ObjectTerritory2Association objTerritoryAssociation1 = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory1.Id,ultimateConsigneeAccount1.Id);
        ObjectTerritory2Association objTerritoryAssociation2 = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory2.Id,ultimateConsigneeAccount2.Id);
        insert new List<ObjectTerritory2Association>{objTerritoryAssociation1, objTerritoryAssociation2};

        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        for(Integer i = 0; i<25; i++){
            Opportunity newOpportunity = TestDataOpportunity.initOpportunity(soldToAccount,Label.OpportunityRTIndirectStandard);
            newOpportunity.Name = 'Ultimate Consignee 1 - Opportunity '+ i;
            newOpportunity.Ultimate_Consignee__c = ultimateConsigneeAccount1.Id;
            opportunitiesToInsert.add(newOpportunity);
        }
        for(Integer i = 0; i<25; i++){
            Opportunity newOpportunity = TestDataOpportunity.initOpportunity(soldToAccount,Label.OpportunityRTIndirectStandard);
            newOpportunity.Name = 'Ultimate Consignee 2 - Opportunity '+ i;
            newOpportunity.Ultimate_Consignee__c = ultimateConsigneeAccount1.Id;
            opportunitiesToInsert.add(newOpportunity);
        }

        Database.SaveResult[] insertResults = Database.insert(opportunitiesToInsert, false);
        Boolean insertError = false;
        for (Database.SaveResult result : insertResults) {
            if (!result.isSuccess()) {
                insertError = true;
            }
        }

        Assert.isFalse(insertError, 'All Opportunities should have been inserted successfully');
    }

    @isTest
    static void testBatch() {
        //Change Ultimate consignee from TerritoryId1 to TerritoryId3 and from TerritoryId2 to TerritoryId4
        List<Territory2Model> lstModels =
            [SELECT Id, Name, (SELECT Id, Name FROM Territory2s WHERE Territory2Type.DeveloperName = 'Territory')
             FROM Territory2Model
             WHERE State = 'Active'];

        Territory2Model objTerritoryModel = lstModels.get(0);

        //Territory we will be moving the Ultimate Consignee into
        Territory2 objTerritory3 = objTerritoryModel.Territory2s.get(2);
        Territory2 objTerritory4 = objTerritoryModel.Territory2s.get(3);

        //Actual Territory of the Ultimate Consignee
        Account ultimateConsigneeAccount1 = [SELECT Id, Territory_Name__c from Account WHERE Name = 'Ultimate Consignee Account 1'];
        Account ultimateConsigneeAccount2 = [SELECT Id, Territory_Name__c from Account WHERE Name = 'Ultimate Consignee Account 2'];

        //Delete old Object2TerritoryAssociation
        ObjectTerritory2Association objTerritoryAssociation1 = [SELECT Id from ObjectTerritory2Association WHERE AssociationCause = 'Territory2Manual' AND ObjectId = :ultimateConsigneeAccount1.Id];
        ObjectTerritory2Association objTerritoryAssociation2 = [SELECT Id from ObjectTerritory2Association WHERE AssociationCause = 'Territory2Manual' AND ObjectId = :ultimateConsigneeAccount2.Id];
        delete new List<ObjectTerritory2Association>{objTerritoryAssociation1, objTerritoryAssociation2};

        //Insert new Object2TerritoryAssociation
        ObjectTerritory2Association objTerritoryAssociation3 = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory3.Id,ultimateConsigneeAccount1.Id);
        ObjectTerritory2Association objTerritoryAssociation4 = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory4.Id,ultimateConsigneeAccount2.Id);
        insert new List<ObjectTerritory2Association>{objTerritoryAssociation3, objTerritoryAssociation4};

        //Update TerritoryName on Ultimate Consignee (run ScheduledBatchAccountTerritorySync)
        ultimateConsigneeAccount1.Territory_Name__c = objTerritory3.Name;
        ultimateConsigneeAccount2.Territory_Name__c = objTerritory4.Name;
        update new List<Account>{ultimateConsigneeAccount1, ultimateConsigneeAccount2};

        Set<Id> ultimateConsigneeIds = new Set<Id>();
        ultimateConsigneeIds.add(ultimateConsigneeAccount1.Id);
        ultimateConsigneeIds.add(ultimateConsigneeAccount2.Id);

        //Check that all 50 Opportunities should have Is_In_Wrong_Territory__c = true
        List<Opportunity> opportunitiesToUpdate = 
            [SELECT Id, Ultimate_Consignee__c, Territory2Id
            FROM Opportunity
            WHERE Ultimate_Consignee__c = :ultimateConsigneeIds and Is_In_Wrong_Territory__c = true];

        //Create mapAccountIdTerritory2Id
        Map<Id, String> mapAccountIdTerritory2Id = new Map<Id, String>();
        for(Opportunity opportunity : opportunitiesToUpdate) {
            if(!mapAccountIdTerritory2Id.containsKey(opportunity.Ultimate_Consignee__c)) {
                mapAccountIdTerritory2Id.put(opportunity.Ultimate_Consignee__c, null);
            }
        }
        List<Id> listTargetAccountIds = new List<Id>(mapAccountIdTerritory2Id.keySet());

        List<String> listTerritoryIds = RetrieveAccountTerritoryId.GetAccountTerritoryId(listTargetAccountIds);
        for (Integer i = 0; i < listTargetAccountIds.size(); i++) {
            mapAccountIdTerritory2Id.put(listTargetAccountIds[i], listTerritoryIds[i]);
        }

        Test.startTest();        
        BatchToUpdateOppTerritory2Id job = new BatchToUpdateOppTerritory2Id();
        Database.executeBatch(job);
        Test.stopTest();

        //Check TerritoryId was updated correctly for all Opportunities
        List<Opportunity> updatedOpportunities = 
            [SELECT Id, Ultimate_Consignee__c, Territory2Id
            FROM Opportunity
            WHERE Ultimate_Consignee__c IN :ultimateConsigneeIds];

        Boolean updateError = false;
        for (Opportunity opportunity : updatedOpportunities) {
            String newTerritory2Id = mapAccountIdTerritory2Id.get(opportunity.Ultimate_Consignee__c);
            if(opportunity.Territory2Id != newTerritory2Id) {
                updateError = true;
            }
        }

        Assert.isFalse(updateError, 'All Opportunities should have been updated with the new Territory2Id of their Ultimate Consignee');
    }
}
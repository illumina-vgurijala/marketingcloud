/**
*    @author Enrique Reyes
*    @date   09-25-2023
*    @description    CMCM-721: RetrieveAccountTerritoryId test class
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Enrique Reyes                  25 Sept 2023        RetrieveAccountTerritoryId test class
*    ----------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestRetrieveAccountTerritoryId {
    private final static String TERRITORY = 'Territory';
	private final static String MODEL_STATE_ACTIVE = Territories2.MODEL_STATE_ACTIVE;

	/**
    *    @author Enrique Reyes
    *    @date   25-09-2023
    *    @description Test Opportunity: Populate Territory Id Flow   
    */
    @isTest
    static void testGetAccountTerritoryId()
    {
        Account ultimateConsigneeAccount = TestDataAccount.getAccount('Flow Account: Ultimate Consignee');
        insert new List<Account>{ultimateConsigneeAccount};

        List<Territory2Model> lstModels =
            [SELECT Id, Name, (SELECT Id, Name FROM Territory2s WHERE Territory2Type.DeveloperName = 'Territory')
             FROM Territory2Model
             WHERE State = 'Active'];

        Territory2Model objTerritoryModel = lstModels.get(0);

        Territory2 objTerritory = objTerritoryModel.Territory2s.get(0);

        //Insert Object2TerritoryAssociation
        ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,ultimateConsigneeAccount.Id);
        insert objTerritoryAssociation;

        Set<Id> accountIds = new Set<Id>{ultimateConsigneeAccount.Id};
        List<ObjectTerritory2Association> insertedObjectTerritoryAssociation = [select Id, ObjectId, Territory2Id from ObjectTerritory2Association where ObjectId IN :accountIds AND Territory2.Territory2Model.State = :MODEL_STATE_ACTIVE AND Territory2.Territory2Type.DeveloperName = :TERRITORY];

        List<Id> requests = new List<Id>();
        requests.add(ultimateConsigneeAccount.Id);
        List<String> results = RetrieveAccountTerritoryId.GetAccountTerritoryId(requests);
        Assert.areEqual(insertedObjectTerritoryAssociation[0].Territory2Id, results[0], 'Should be the same Territory');
    }
}
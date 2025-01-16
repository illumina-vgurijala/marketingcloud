public class RetrieveAccountTerritoryId {
    private final static String TERRITORY = 'Territory';
	private final static String MODEL_STATE_ACTIVE = Territories2.MODEL_STATE_ACTIVE;

    @InvocableMethod(label='Get TerritoryIds' description='Returns the list of TerritoryIds corresponding to the specified account Ids.' category='Account')
	public static List<String> GetAccountTerritoryId (List<Id> accountIds) {
        List<String> results = new List<String>();
        Set<Id> accountIdSet = new Set<Id>();
        
		for (Id accountId : accountIds){
            accountIdSet.add(accountId);
		}
        
        Map<Id, String> accountIdToTerritoryId = new Map<Id, String>();
        for(ObjectTerritory2Association soqlResult : [select Id, ObjectId, Territory2Id from ObjectTerritory2Association where ObjectId IN :accountIds AND Territory2.Territory2Model.State = :MODEL_STATE_ACTIVE AND Territory2.Territory2Type.DeveloperName = :TERRITORY]){
            accountIdToTerritoryId.put(soqlResult.ObjectId, soqlResult.Territory2Id);
        }
        
        //Put each territortId in the output at the same position as the id in the input
        for (String accountId : accountIds) {
            results.add(accountIdToTerritoryId.get(accountId));
        }
           
    	return results;
    }
}
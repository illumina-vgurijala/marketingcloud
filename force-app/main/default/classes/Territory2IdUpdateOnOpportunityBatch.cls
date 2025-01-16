/**
*    Description - Batch Class to update the Opprtunity object for Territory2Id field.
*    Test Class Coverage For 100% coverage: testTerritory2IdUpdateOnOpportunityBatch
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Balakrishna                    3rd Julay 2023              CMCM-721  
*    -----------------------------------------------------------------------------------------------
**/

global class Territory2IdUpdateOnOpportunityBatch implements Database.Batchable<sObject>{
	
	global Database.QueryLocator start(Database.BatchableContext bc){        
        return Database.getQueryLocator('SELECT Id,name,CreatedDate,AccountId, Account.Territory_Name__c,Territory2Id,Ultimate_Consignee__c FROM Opportunity WHERE CreatedDate > 2020-01-01T00:00:00.000+0000');
    }
	
	global void execute(Database.BatchableContext bc, List<SObject> scope){
		Map<Id,Id> mapAccId=new Map<Id,Id>();
		List<Opportunity> updateOppList=new List<Opportunity>();
		Map<Id,ObjectTerritory2Association> mapTerritory =new Map<Id, ObjectTerritory2Association>();
		if(!scope.isEmpty()){
			for(Opportunity opp: (List<Opportunity>)scope){	
				if(opp.Ultimate_Consignee__c != null){
					mapAccId.put(opp.Id,opp.Ultimate_Consignee__c);
				}
			}
        }
		Map<Id, Id> mapAccIdToTerritory2Ids = getTerritory2Ids(mapAccId);		
		 ilib_LogEvent.info('Batch mapAccIdToTerritory2Ids: '+ mapAccIdToTerritory2Ids);
		 for(Opportunity opt:(List<Opportunity>)scope){			 
			 if(mapAccIdToTerritory2Ids.containskey(opt.Ultimate_Consignee__c)){
				 opt.Territory2Id = mapAccIdToTerritory2Ids.get(opt.Ultimate_Consignee__c);
				updateOppList.add(opt);
				ilib_LogEvent.info('updateOppList: '+ updateOppList);
			 }
		 }
		 
		 if(!updateOppList.isEmpty()){
			 Database.update(updateOppList,false);
		 }		
		
	}
	global void finish(Database.BatchableContext bc){
        
    }
	
	public Map<Id, Id> getTerritory2Ids(Map<Id, Id> mapOppToAccId) {
        Map<Id, Id> mapAccIdToTerritory2Id = new Map<Id, Id>();
        List<ObjectTerritory2Association> lstObjectTerritory2Association = new ObjectTerritory2AssociationsSelector().selectOnlyDirectByAccountId(mapOppToAccId.values());
        for(ObjectTerritory2Association eachObjTerritory2Assoc : lstObjectTerritory2Association) {
            mapAccIdToTerritory2Id.put(eachObjTerritory2Assoc.ObjectId, eachObjTerritory2Assoc.Territory2Id);   // 1 Account will have only 1 Direct Territory
        }
        return mapAccIdToTerritory2Id;
    }
}
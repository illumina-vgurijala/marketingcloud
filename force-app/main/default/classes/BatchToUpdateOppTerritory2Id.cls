/**
*    @author: Enrique Reyes 
*    @date:   27-Nov-2023
*    @description:  Batchable Opportunity Territory2Id update
*    Modification Log:
*    ------------------------------------------------------------------------------------
*       Developer                      Date               Description
*       Enrique Reyes                  27-Nov-2023        Initial Development
*    ------------------------------------------------------------------------------------ 
*/

public class BatchToUpdateOppTerritory2Id implements Database.Batchable<sObject>, Database.Stateful {
    private final static String SOURCE = 'BatchToUpdateOppTerritory2Id';

    /*
    * @author: Enrique Reyes 
    * @description : empty constructor
    * @param : N/A
    */
    public BatchToUpdateOppTerritory2Id() {

    }

    /*
    * @author Enrique Reyes
    * @date   16-11-2023
    * @description  Schedule method override
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Ultimate_Consignee__c, Territory2Id FROM Opportunity WHERE Is_In_Wrong_Territory__c = true';
        return Database.getQueryLocator(query);
    }

    /*
    * @author Enrique Reyes
    * @date   16-11-2023
    * @description    Batch method override
    * Excute Logic to populate Territory region Information on Opportunity
    */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        ilib_LogEvent.push(SOURCE+'.execute');

        Map<Id, String> mapAccountIdTerritory2Id = new Map<Id, String>();
        for(Opportunity opportunity : (List<Opportunity>)scope) {
            if(!mapAccountIdTerritory2Id.containsKey(opportunity.Ultimate_Consignee__c)) {
                mapAccountIdTerritory2Id.put(opportunity.Ultimate_Consignee__c, null);
            }
        }
        List<Id> listTargetAccountIds = new List<Id>(mapAccountIdTerritory2Id.keySet());

        List<String> listTerritoryIds = RetrieveAccountTerritoryId.GetAccountTerritoryId(listTargetAccountIds);
        for (Integer i = 0; i < listTargetAccountIds.size(); i++) {
            mapAccountIdTerritory2Id.put(listTargetAccountIds[i], listTerritoryIds[i]);
        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for(Opportunity opportunity : (List<Opportunity>)scope) {
            String newTerritory2Id = mapAccountIdTerritory2Id.get(opportunity.Ultimate_Consignee__c);
            if(opportunity.Territory2Id != newTerritory2Id) {
                opportunity.Territory2Id = newTerritory2Id;
                opportunitiesToUpdate.add(opportunity);
            }
        }

        if(!opportunitiesToUpdate.isEmpty()){
            List<Database.SaveResult> lstSaveErrors = Database.update(opportunitiesToUpdate, false);
            if(!lstSaveErrors.isEmpty()){
                ApexExceptions.emitSaveErrors(lstSaveErrors, SOURCE);
            }
        }
  
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
  
    /*
    * @author Enrique Reyes
    * @param Database.BatchableContext BC
    * @return  void
    */
    public void finish(Database.BatchableContext bc) {
        
    }
}
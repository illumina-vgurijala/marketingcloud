/**
*    @author: Enrique Reyes 
*    @date:   27-Nov-2023
*    @description: To Schedule BatchToUpdateOppTerritory2Id class
*    Modification Log:
*    ------------------------------------------------------------------------------------
*       Developer                      Date               Description
*       Enrique Reyes                  27-Nov-2023        Initial Development
*    ------------------------------------------------------------------------------------ 
*/
public with sharing class ScheduleBatchToUpdateOppTerritory2Id implements Schedulable {
    public void execute(SchedulableContext sc) {
        //Database.executeBatch takes in the class, and then the size of batches.
        Id batchId = Database.executeBatch(new BatchToUpdateOppTerritory2Id(), 50);
    }
}
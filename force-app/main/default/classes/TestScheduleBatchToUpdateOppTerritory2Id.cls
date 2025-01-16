/**
*    @author: Enrique Reyes 
*    @date:   27-Nov-2023
*    @description:  Test class for ScheduleBatchToUpdateOppTerritory2Id 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*       Developer                      Date               Description
*       Enrique Reyes                  27-Nov-2023        Initial Development
*    ------------------------------------------------------------------------------------              
*/
@isTest
public class TestScheduleBatchToUpdateOppTerritory2Id {
    @isTest
    public static void testScheduledBatch(){
        Test.startTest();
		    string cronexp = '0 30 21 2W 1,4,7,10 ?';
            String jobId = system.schedule('ScheduleBatchToUpdateOppTerritory2Id',cronexp,new ScheduleBatchToUpdateOppTerritory2Id());
        Test.stopTest();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        Assert.areEqual(ct.CronExpression,cronexp,'Batch not scheduled!');
    }
}
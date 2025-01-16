/**
*    @author: Gopi 
*    @date:   01-Aug-2023
*    @description:  Test class for ScheduleBatchToUpdateCompliance 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Gopi                        01-Aug-2023        Initial Development
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public class TestScheduleBatchToUpdateCompliance {
    public testmethod static void TestScheduledbatch(){
    Test.startTest();
		string cronexp = '0 0 2 * * ?';
        String jobId = system.schedule('ScheduleBatchToUpdateCompliance',cronexp,new ScheduleBatchToUpdateCompliance());
    Test.stopTest();
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];
    Assert.areEqual(ct.CronExpression,cronexp,'Batch not scheduled!');
    }
}
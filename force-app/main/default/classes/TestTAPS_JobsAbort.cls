/**
*   @author Gerardo Garcia
*   @description  Test class for TAPS_JobsAbort
*   Modification Log:
*---------------------------------------------------------------------------------------------------------------------------
*   Developer                       Date                    Description
*   Gerardo Garcia                  01-Aug-2023             CMCM-3106
*---------------------------------------------------------------------------------------------------------------------------
*/
@IsTest
private class TestTAPS_JobsAbort {

    public static final String CRON_EXP = '0 0 0 3 9 ? 2042';
    private static final Integer JOBS_TO_DEL = 150;

    static testmethod void deleteObsoleteJobs() {

        // System.abortJob could only take 150 DML. So in this test will have 151 jobs schedule(plus the already jobs in environment). 
        for(Integer i = 0; i < 151; i++) {
            System.schedule('TAPS_testToDel' + i,
            CRON_EXP, 
            new TAPS_Test());
        }

        // Jobs that their name are starting with "TAPS" on Waiting state. These means 151 jobs from test plus the current jobs from Environment.
        Integer numCurrentJobs = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name LIKE 'TAPS%' AND State = 'WAITING'];
        System.debug('NumCurrentJobs:' + numCurrentJobs);

        Test.startTest();
        // deleteObsoleteJobs will only delete 150 jobs with starting name "TAPS" and Waiting state
        TAPS_JobsAbort.deleteObsoleteJobs(CronTriggerSelector.STATE_WAITING);
        Test.stopTest();

        List<CronTrigger> res = [SELECT Id, State, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name LIKE 'TAPS%' AND State = 'WAITING'];
        System.debug('===res:' + JSON.serializePretty(res));
        System.debug('===numJobs that are remeaning:' + res.size());
        Assert.areEqual(numCurrentJobs - JOBS_TO_DEL, res.size(), '150 jobs should be removed');
    }

    static testmethod void scheduleJobsAbort() {
        String jobId = System.schedule('TAPS_JobsAbort', CRON_EXP, new TAPS_JobsAbort());
        Integer numJobs = [SELECT Count() FROM CronTrigger WHERE id = :jobId];
        Assert.areEqual(1, numJobs, 'Only 1 job should be schedule');
    }

    /**
     * @description: Dummy Class for quick testing schedule
     */
    public class TAPS_Test implements Schedulable {

        /**
         * @description: implementation execute.
         */
        public void execute(SchedulableContext sc) {
            System.debug('===done' + sc.getTriggerId());
        }
    } 
}
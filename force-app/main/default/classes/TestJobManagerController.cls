 /**    
    *    @description test class for JobManagerController
    */
@isTest
private class TestJobManagerController {

    // TODO: add asserts after signature are decided upon

    @IsTest
    private static void markScheduledJobs()
    {
        List<JobManagerController.JobDetails> allJobs = JobManagerController.getJobDetails();
        JobManagerController.findJobsAlreadyScheduled(allJobs);
        System.assert(!allJobs.isEmpty(), 'list of Jobs are empty');
    }

    @IsTest
    private static void runOneJob()
    {
        List<JobManagerController.JobDetails> allJobs = JobManagerController.getJobDetails();
        System.assert(!allJobs.isEmpty(), 'list of Jobs are empty');
        Test.startTest();
        JobManagerController.executeBatchNow(JSON.serialize(allJobs[2]));
        Test.stopTest();
    }

    @IsTest
    private static void scheduleOneJob()
    {
        List<JobManagerController.JobDetails> allJobs = JobManagerController.getJobDetails();
        JobManagerController.findJobsAlreadyScheduled(allJobs);

        JobManagerController.JobDetails unscheduled;
        for (JobManagerController.JobDetails j : allJobs)
            if (!j.currentlyScheduled)
                unscheduled = j;
        //if (unscheduled == null) return;
        System.assert(!allJobs.isEmpty(), 'list of Jobs are empty');
        Test.startTest();
        JobManagerController.unscheduleJob('undefined' + JSON.serialize(unscheduled));
        Test.stopTest();
    }

    @IsTest
    private static void unscheduleOneJob()
    {
        List<JobManagerController.JobDetails> allJobs = JobManagerController.getJobDetails();
        JobManagerController.findJobsAlreadyScheduled(allJobs);

        JobManagerController.JobDetails scheduled;
        for (JobManagerController.JobDetails j : allJobs)
            if (j.currentlyScheduled)
                scheduled = j;
        //if (scheduled == null) return;
        System.assert(!allJobs.isEmpty(), 'list of Jobs are empty');
        Test.startTest();
        JobManagerController.scheduleJob(JSON.serialize(scheduled));
        Test.stopTest();
    }

}
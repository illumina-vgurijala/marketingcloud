/**
*   @author Gerardo Garcia
*   @date   2023
*   @description  TAPS_JobsAbort
*   Modification Log:
*---------------------------------------------------------------------------------------------------------------------------
*   Developer                       Date                    Description
*   Gerardo Garcia                  01-Aug-2023             CMCM-3106
*---------------------------------------------------------------------------------------------------------------------------
*/

global class TAPS_JobsAbort implements Schedulable {

    private static final String LOG_TITLE = 'TAPS_JobsAbort';

    /**
     * @description execute implementation
     */
    global void execute(SchedulableContext sc) {
        deleteObsoleteJobs(CronTriggerSelector.STATE_DELETED);
    }

    @TestVisible
    private static void deleteObsoleteJobs(String state) {

        try {
            ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE);
            ilib_LogEvent.push(LOG_TITLE + '.deleteObsoleteJobs()');
            List<CronTrigger> cronsToAbort = new CronTriggerSelector().getJobsByNameAndState('TAPS%', state);
            ilib_LogEvent.info('cronsToAbort:' + cronsToAbort.size());
            for (CronTrigger t : cronsToAbort) {
                System.abortJob(t.ID);
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE, e, ilib_LogEvent.SALES);
        } 

    }
}
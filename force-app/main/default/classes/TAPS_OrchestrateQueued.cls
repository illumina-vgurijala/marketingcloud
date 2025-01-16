/**
*    @author: Todd Newman
*    @date:  
*    @description: Queueable class for calculating share records based on account level changes
*    @Test Class for above 90% coverage.
*    @Test Class for atleast 75% coverage.
*     -TestTAPS_AccountPlans
*     -TestTAPS_DeferredRun
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description  
*          Todd Newman                                        Initial Version
*          Aman Tyagi                    30th March 2022      CodeScan Fixes
*          Nishan Shetty                 24-Aug-2022          DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*          Jitesh Lakhwani               21-Feb-2023          Codescan - Avoid unused Variable
*    ------------------------------------------------------------------------------------ 
*                    
*/
global without sharing class TAPS_OrchestrateQueued implements Queueable {

    private Set<Id> accountIds;
    private List<SObjectType> sharedObjectTypes;

    /*
    * @Author: Todd
    * @Description : parameterized constructor of the class TAPS_OrchestrateQueued
    * @param: Set<Id> accountIds
    * @return: NA
    */
    global TAPS_OrchestrateQueued(Set<Id> accountIds)
    {
        this.accountIds = accountIds;
        // default to all supported object types
        this.sharedObjectTypes = TAPS_ObjectSupport.allSharedObjectTypes;
    }

    /*
    * @Author: Todd
    * @Description : parameterized constructor of the class TAPS_OrchestrateQueued
    * @param: Set<Id> accountIds , List<Schema.SObjectType> sharedObjectTypes
    * @return: NA
    */
    global TAPS_OrchestrateQueued(Set<Id> accountIds, List<Schema.SObjectType> sharedObjectTypes)
    {
        this.accountIds = accountIds;
        this.sharedObjectTypes = sharedObjectTypes;
    }

    /*
    * @Author: Todd
    * @Description : execute method for Queueable and for apex sharing for Accounts and child objects
    * @param: QueueableContext qc
    * @return: void
    */
    global void execute(QueueableContext qc)
    {
        if (sharedObjectTypes == null || sharedObjectTypes.size() == 0) return;
        if (accountIds == null || accountIds.size() == 0) return;

        // pick the first object
        SObjectType thisSObjectType = sharedObjectTypes.get(0);

        ilib_LogEvent.rootTitle = 'TAPS Queued Recalc - ' + thisSObjectType.getDescribe().getName();
        ilib_LogEvent.push('TAPS_OrchestrateQueued.execute');
        ilib_LogEvent.message('Object count including this run ' + sharedObjectTypes.size());

        try
        {
            // run sharing calculations for a single object
            TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            tapsOrchestrator.recalculateAccountChangesForObject(thisSObjectType, accountIds);//DCP-44091
            ilib_LogEvent.message('Scheduling batch for ' + accountIds.size() + ' account rows');

        }
        catch (Exception e)
        {
            ilib_LogEvent.logError(e);
            ApexExceptions.emit('TAPS_OrchestrateQueued', null ,e);
        }

        finally
        {
            scheduleNextJob();
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
    }

    /*
    * @Author: Todd
    * @Description : method for queuing the objects
    * @param: none
    * @return: void
    */
    public void scheduleNextJob(){
        try
        {
            // queue up the remaining objects
            sharedObjectTypes.remove(0);
            if (sharedObjectTypes.size() > 0)
            {
                TAPS_OrchestrateQueued queueableClassInstance = new TAPS_OrchestrateQueued(accountIds, sharedObjectTypes);
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('TAPS_OrchestrateQueued');
                queueableThread.logAndQueue(queueableClassInstance, 'TAPS_OrchestrateQueued', 'execute');

                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
                ilib_LogEvent.message(sharedObjectTypes.size() + ' objects to go, scheduled another one');
            }
        }catch (Exception e){
            ilib_LogEvent.logError(e);
        }

    }

}
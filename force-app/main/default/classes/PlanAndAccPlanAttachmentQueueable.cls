/* **************************************************************************************
* CLASS NAME     : PlanAndAccPlanAttachmentQueueable
* DEVELOPER      : Prem Ranjan
* USER STORY     : TASK0720146-Updated future to Queueable
* DESCRIPTION    : Moved Future to Queueable (Populate Fields on Plan/Account Plan if it has Files Attached/Deattached)
  Modification Log:
*       ------------------------------------------------------------------------------------
*       Prem Ranjan         04/03/2022            Initial Version
*       ------------------------------------------------------------------------------------
*******************************************************************************************/
public class PlanAndAccPlanAttachmentQueueable implements Queueable {

    private final Set<Id> accPlanIdSet;
    private final Set<Id> planIdSet;
    private final String action;
    public static Boolean catchException = false;

/*Constructor*/
public PlanAndAccPlanAttachmentQueueable(Set<Id> accPlanIdSet, Set<Id> planIdSet, String action) {
    this.accPlanIdSet = accPlanIdSet;
    this.planIdSet = planIdSet;
    this.action=action;
}

/* METHOD NAME   : excute
* DEVELOPER      : Prem Ranjan
* RETURN TYPE    : NA
* PARAMETER      : QueueableContext
*/
public void execute(QueueableContext context) {
   try{
    if((!accPlanIdSet.isEmpty() || !planIdSet.isEmpty()) && action == PlanAndAccPlanAttachmentHandler.INSERT_ACTION){
        PlanAndAccPlanAttachmentHandler.updateIsFileAttachedTrue(accPlanIdSet,planIdSet);
    }
    if(!accPlanIdSet.isEmpty()  && planIdSet.isEmpty() && action == PlanAndAccPlanAttachmentHandler.DELETE_ACTION){
        PlanAndAccPlanAttachmentHandler.updateAccPlanIsFileAttachedFalse(accPlanIdSet);
    } 
    if(!planIdSet.isEmpty() && accPlanIdSet.isEmpty() && action == PlanAndAccPlanAttachmentHandler.DELETE_ACTION){
        PlanAndAccPlanAttachmentHandler.updatePlanIsFileAttachedFalse(planIdSet);
    }
     //code coverage for catch block
     if(catchException == true){
        throw new AuraHandledException('throwing custom exceptions');
    }
   
   }catch(Exception e){
     //catch the exception 
     ApexExceptions.emit('PlanAndAccPlanAttachmentQueueable', e,ilib_LogEvent.getWorkstream());
     ilib_LogEvent.pop();
     ilib_LogEvent.emit();
     throw e;
   }
}
}

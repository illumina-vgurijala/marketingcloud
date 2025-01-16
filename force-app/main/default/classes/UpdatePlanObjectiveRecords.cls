/**
* @author Kushagra Desai 
* @date   20-Nov-2019
* @description    Service call to update Plan Objective
* Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description       
*  -----------------------------------------------------------------------------------          
*/
public with sharing class UpdatePlanObjectiveRecords implements ilib_AdminOperationLogicInterface{
    /**
     *  @author       : Kushagra Desai
     *  @description  : update total task count and total closed task count in plan objective un admin context
     *  @return       : void
     */
    public static void doBusinessLogic(List<Id> lstPlanObjectiveIds){
        Set<Id> setPlanObjectiveId = new Set<Id>(lstPlanObjectiveIds);
        Tasks.updatePlanObjectiveRecords(setPlanObjectiveId);
    }
}
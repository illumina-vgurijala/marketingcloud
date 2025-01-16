/**
*   @author KD
*   @date  1-Sept-2020
*   @description  : Create new objective on account plan from Territory plan 
*   Modification Log:
*   ------------------------------------------------------------------------------------
*           Developer                   Date                Description
*        Nishan Shetty                 03-Jun-2022         Batch Manager Implementation.
*   ------------------------------------------------------------------------------------
**/
global with sharing class BatchClonePlanObjectiveToObjective extends ilib_BatchDeferrable {
    TerritoryPlanStrategyController.PlanObjectiveWrapper objPlanObjective;
    List<String> setAccountIds = new List<String>();
    private Inputs inputs;
    public final static String LOG_TITLE = 'BatchClonePlanObjectiveToObjective';
    
    /*
    *  @Author      : Nishan Shetty DCP-50962
    *  @Description : Parameter wrapper for easy serialization
    */
    public class Inputs {
        public List<String> lstAccountId;
        public String strObjectiveJSON;
        /**
        * @author illumina
        * @description 
        */
        public Inputs(List<String> lstAccountId, String strObjectiveJSON) {
            this.lstAccountId = lstAccountId;
            this.strObjectiveJSON = strObjectiveJSON;
        }
    }
    
    /**
    *   @author KD
    *   @description Constructor method
    **/
    public BatchClonePlanObjectiveToObjective(){
        super();
    }
    
    /**
    *   @author KD
    *   @description Constructor method
    **/
    public BatchClonePlanObjectiveToObjective(List<String> setAccountIds,String strObjectiveJSON) {
        super();
        ilib_LogEvent.setTitle(LOG_TITLE);
        this.inputs = new Inputs(setAccountIds,strObjectiveJSON);
        this.setAccountIds = inputs.lstAccountId;
        this.objPlanObjective = (TerritoryPlanStrategyController.PlanObjectiveWrapper)JSON.deserialize(strObjectiveJSON,TerritoryPlanStrategyController.PlanObjectiveWrapper.class);
    }
    /**
    *   @author KD
    *   @description Start Method For the Apex JOb
    **/
    global override Database.QueryLocator start(Database.BatchableContext bc){
        Set<String> setStatus = new Set<String>{Label.AccountPlanStatusDraft,Label.AccountPlanStatusActive};
        String strQuery = 'SELECT Id from Account_Plan__c where Account_Name__c IN :setAccountIds AND Plan_Status__c IN :setStatus';
        return Database.getQueryLocator(strQuery);
    }
    /**
    *   @author KD
    *   @description 
    **/
    global override void execute(Database.BatchableContext bc, list<Sobject> scope){
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.push(LOG_TITLE+'.execute');
        List<Objective__c> lstObjective = new List<Objective__c>();
        for(Account_Plan__c objAccPlan : (List<Account_Plan__c>)scope){
            Objective__c objObjective = new Objective__c();
            objObjective.Account_Plan__c = objAccPlan.Id;
            objObjective.Name = objPlanObjective.name.removeStart('Plan Objective: ');
            objObjective.Priority__c = objPlanObjective.priority;
            objObjective.Objective_Status__c = objPlanObjective.objectiveStatus;
            objObjective.Due_Date__c = Date.valueOf(objPlanObjective.dueDate);
            objObjective.Plan_Objective__c = objPlanObjective.strObjectId;
            objObjective.Closed_Status__c = objPlanObjective.closedStatus;
            lstObjective.add(objObjective);
        }
        ilib_LogEvent.message('lstObjective++'+lstObjective);
        if(!lstObjective.isEmpty()){
            Database.SaveResult[] result = Database.insert(lstObjective, false);
            ApexExceptions.emitSaveErrors(result,'BatchUpdateAccountPlan');
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *   @author KD
    *   @description 
    **/
    global override void finish(Database.BatchableContext bc){

    }
    
    //DCP-50962 - implementation of batch manager
    
     // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************
    
    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs() {
        return JSON.serialize(inputs);
    }

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs) {
        this.inputs = (BatchClonePlanObjectiveToObjective.Inputs)JSON.deserialize(serializedInputs, BatchClonePlanObjectiveToObjective.Inputs.class);
    }
}
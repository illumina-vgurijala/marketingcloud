/**
*    @author Nishan Shetty
*    @date   04 October 2021
*    @description  CMCP-5- Expose DCP Published Knowledge Article to Channel Partners.
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*    Nishan Shetty         04-Oct-2021        Initial
*    -----------------------------------------------------------------------------------------------------------------------------------
*
*/
public without sharing class BatchUpdateObjectives extends ilib_ScheduleAndBatch {

    public String objectName;
    public String query;
    public final static String STRING_PLAN = 'Plan';
    public final static String STRING_ACCOUNT_PLAN = 'AccountPlan';
    public final static String STRING_CLOSED='Closed';
    /**
    *	@author Nishan Shetty
    *	@description Constructor
    **/
    public BatchUpdateObjectives(String objectName) {
        super();
        this.objectName=objectName;
        if(objectName==STRING_PLAN) {
            this.query='Select Id,Objective_Status__c,Plan_Strategy__r.Plan__r.Status__c,Closed_Status__c from Plan_Objective__c where Objective_Status__c!=\'Closed\'';
        } else {
            this.query='Select Id,Objective_Status__c,Closed_Status__c,Account_Plan__r.Plan_Status__c from Objective__c where Objective_Status__c!=\'Closed\'';
        }
    }
    
   
    /*Batch Start Method to query records*/
    public override Database.QueryLocator start(Database.BatchableContext bc) {        
    return Database.getQueryLocator(query);
    }


    /*Batch Execute Method to process records*/
    public override void execute(Database.BatchableContext bc, List<sobject> lstObjectives) {
       List<Plan_Objective__c> lstPlanObjectives=new List<Plan_Objective__c>();
       List<Objective__c> lstAccountPlanObjectives=new List<Objective__c>();
       if(objectName==STRING_PLAN) {
           for(Plan_Objective__c objPlanObjective:(List<Plan_Objective__c>)lstObjectives) {
               if(objPlanObjective.Plan_Strategy__r.Plan__r.Status__c ==STRING_CLOSED && objPlanObjective.Closed_Status__c!=null) {
                   objPlanObjective.Objective_Status__c=STRING_CLOSED;
                   lstPlanObjectives.add(objPlanObjective);
               }
           }
       }

       if(objectName==STRING_ACCOUNT_PLAN) {
           for(Objective__c objAcctPlanObjective:(List<Objective__c>)lstObjectives) {
                if(objAcctPlanObjective.Account_Plan__r.Plan_Status__c ==STRING_CLOSED && objAcctPlanObjective.Closed_Status__c!=null) {
                    objAcctPlanObjective.Objective_Status__c=STRING_CLOSED;
                    lstAccountPlanObjectives.add(objAcctPlanObjective);
                }
           }
        }
        
        try {
            if(!lstPlanObjectives.isEmpty()) {
                update lstPlanObjectives;
            }
    
            if(!lstAccountPlanObjectives.isEmpty()) {
                update lstAccountPlanObjectives;
            }
        } catch (Exception e) {
            ApexExceptions.emit('Objective Update Failed',e);
        }
        
    }

    

    /*Batch Finish Method for post execute logic*/  
    public override void finish(Database.BatchableContext bc) {
    //No Logic needed.
    }
  
}
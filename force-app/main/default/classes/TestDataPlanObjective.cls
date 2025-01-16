/*@ author       : KD
* @ date         : 28-July-2020
* @ Description  : CreatePlan Objective
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------

* 
*/
public with sharing class TestDataPlanObjective {
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates Plan Objective
    *  @PARAM :  String Strategy ID
    *  @RETURN:  
    */
    
    public static Plan_Objective__c getPlanObjective(String strPlanStrategyId){
        return new Plan_Objective__c(Name = 'Test_Plan_Objective',
                            Plan_Strategy__c = strPlanStrategyId,
                            Due_Date__c = Date.Today()
                            );
    }
}
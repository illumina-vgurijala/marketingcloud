/*@ author       : KD
* @ date         : 28-July-2020
* @ Description  : CreatePlan Stratey
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------

* 
*/
public with sharing class TestDataPlanStrategy {
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates Plan Strategy
    *  @PARAM :  String TerritoryId
    *  @RETURN:  
    */
    
    public static Plan_Strategy__c getPlanStrategy(String strPlanId){
        return new Plan_Strategy__c(Name = 'Test_Plan_Strategy', 
                            Plan__c = strPlanId,
                            Due_Date__c = Date.Today()
                            );
    }
}
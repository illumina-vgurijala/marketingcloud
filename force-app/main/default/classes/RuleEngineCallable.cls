/***************************************************************************************************************************************
* NAME   :  RuleEngineCallable

* DESCRIPTION  :DCP-40191, Apex Class to call a apex  method from rule engine
*           
*    
* @AUTHOR : Digvijay
* @DATE   : 18-09-2020  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Digvijay             18-09-2020            Initial Version

****************************************************************************************************************************************/ 
public with sharing class RuleEngineCallable implements Callable {
 


/**
*  @AUTHOR Digvijay
*  @DESCRIPTION - Callable method called from the RuleEngineLogic class, need to  a particular apex Rule 
*  @PARAM : String , Map<String, Object>
*  @RETURN : Object
**/
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'SVMXC__Service_Order_Line__c_Billable' {
                System.debug('RuleEngineCallable');
                return AutoRMA_WorkdetailHelper.workdetailsComplexBillableRules(args);
            }
            when else {
                return null;
            }
        }
    }
}
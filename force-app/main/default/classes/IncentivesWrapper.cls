/**
 * @author Prakhar Kumar
 * @date   20-Sep-2019
 * @description  Wrapper class of ApttusGetPromotionsController class . User story : DCP-26235
 * Modification Log:
 *  --------------------------------------------------------------------------------------------------
 *   Developer                Date                Description                                                  
 *   Prakhar Kumar         20-Sep-2019         Original Version
 *   Himanshu              30-Mar-2022         Code Scan Fixes  
 * ---------------------------------------------------------------------------------------------------
 **/
public class IncentivesWrapper {
        public Apttus_Config2__Incentive__c incentive {get; set;}
        public Boolean bool {get; set;}
        /**
        * @author  Akash Kumar
        * @description Parameterizes Constructor called of above wrapper class
        * @params Apttus_Config2__Incentive__c incentive, Boolean bool
        * @return void
        **/
        public IncentivesWrapper(Apttus_Config2__Incentive__c incentive, Boolean bool) {
            this.incentive = incentive;
            this.bool = bool;
        }
    }
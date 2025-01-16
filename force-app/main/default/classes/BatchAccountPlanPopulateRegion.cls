/*@ author       : Akshay Mohan
* @ date         : 10-09-2019
* @ Description  : Batch update to sync the account region from Account
*
* 90% Code Coverage: TestBatchAccountPlanPopulateRegion,TestScheduledBatchAccountTerritorySync
* 75% Code Coverage: TestBatchAccountPlanPopulateRegion,TestScheduledBatchAccountTerritorySync
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan           10-09-2019                 Initial version
*
* Koustubh M             09-Dec-2021                TASK0679416 Added code for error logging
* Aman Tyagi             31-Mar-2022                Codescan Fixes
* Rucha Dalvi            31-May-2022                DCP-52588 : Violation Reduction Sales(Q3) Codescan Fix
* Nishan Shetty          03-Jun-2022                Implementing Batch Manager Framework DCP-50962
* Nishan Shetty          22-Aug-2022                [TASK0802266] Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
* Sibin P Kuriakose      12-Sep-2022                [CMSI-212] Instrumentation of the Class.
* Adyasha Satapathy      13-Dec-2022                POL- 190: Update the batch to exclude plans with closed status for region update
*/
global with sharing class BatchAccountPlanPopulateRegion extends ilib_BatchDeferrable {

    private static final String LOG_TITLE = 'BatchAccountPlanPopulateRegion'; //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
    public static final String STRING_STATUS_CLOSED = System.Label.Closed; //POL-190

    //public String query;
    //DCP-52588 made final since the value is set within constructor. This resolves codescan issue.
    Set<Id> setAccountIds;
    private Inputs inputs;


    /*
    *  @Author      : Nishan Shetty
    *  @Description : Parameter wrapper for easy serialization[DCP-50962]
    */
    public class Inputs {
        public Set<Id> setAccountId;

        /*Constructor*/
        public Inputs(Set<Id> setAccountId) {
            this.setAccountId = setAccountId;
        }
    }

   /*
    * @Author : Nishan Shetty[TASK0802266]
    * @Description : Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
    */
    public BatchAccountPlanPopulateRegion() {
      super();
    }

    /*
    * @Author: Akshay Mohan
    * @Description : parameterized constructor of class BatchAccountPlanPopulateRegion and instantiating Id
    * @param :Set<Id> setAccountIds
    */ 
    public BatchAccountPlanPopulateRegion(Set<Id> setAccountIds) {
        super();
        this.inputs = new Inputs(setAccountIds);
        this.setAccountIds = inputs.setAccountId;
    }

    /*
    * @author Akshay Mohan
    * @date   10-09-2019
    * @description  start method override
    *
    */
    global override Database.QueryLocator start(Database.BatchableContext bc) {
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId); //CMSI-212
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES); //CMSI-212
        ilib_LogEvent.push(LOG_TITLE + '.start'); //CMSI-212
        String query = 'SELECT Id, Name, Account_Region__c,Account_Name__c, Plan_Status__c FROM Account_Plan__c WHERE (Plan_Status__c != :STRING_STATUS_CLOSED  AND Account_Name__c IN :setAccountIds)';
        ilib_LogEvent.info('Query' + query); //CMSI-212
        ilib_LogEvent.pop(); //CMSI-212
        ilib_LogEvent.emit(); //CMSI-212
        return Database.getQueryLocator(query);
    }

    /*
    * @author Akshay Mohan
    * @date   10-09-2019
    * @description  execute method override
    *
    */
   global override void execute(Database.BatchableContext bc, List<sObject> scope){
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId); //CMSI-212
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES); //CMSI-212
        ilib_LogEvent.push(LOG_TITLE + '.execute'); //CMSI-212
        List<Account_Plan__c> lstAccountPlans = (List<Account_Plan__c>)scope;
        ilib_LogEvent.info('lstAccountPlans: '+lstAccountPlans);
        Set<Id> accounIds = UtilsCollection.getSetOfIds(lstAccountPlans, 'Account_Name__c');
        ilib_LogEvent.info('accounIds: '+accounIds);
        Map<String,String> accountIdToRegion = new Map<String,String>();
        for(Account objAccount : [Select Id,Territory_Region__c FROM Account where Id IN :accounIds]) {
          accountIdToRegion.put(objAccount.Id,objAccount.Territory_Region__c);
        }
        List<Account_Plan__c> lstUpdatedAccountPlans= new List<Account_Plan__c>();
        for(Account_Plan__c objAP : lstAccountPlans) {
            if(objAP.Account_Region__c!=accountIdToRegion.get(objAP.Account_Name__c)){
                objAP.Account_Region__c= accountIdToRegion.get(objAP.Account_Name__c);
                lstUpdatedAccountPlans.add(objAP);
            }
        }
        Set<Id> updatedaccIds = UtilsCollection.getSetOfIds(lstUpdatedAccountPlans, 'Account_Name__c'); //CMSI-212
        ilib_LogEvent.info('UpdatedaccountIds: '+updatedaccIds); //CMSI-212
        if(!lstUpdatedAccountPlans.isEmpty())
        {
            List<Database.SaveResult> lstSaveErrors = Database.update(lstUpdatedAccountPlans, false);
            if(!lstSaveErrors.isEmpty()){ //Koustubh - TASK0679416, 9th Dec 2021 - Added error logging
                ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE); //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    * @Author: Akshay Mohan
    * @Description : overriding the finish method
    * @param :Database.BatchableContext bc
    * @return : void
    */
    global override void finish(Database.BatchableContext bc){
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId); //CMSI-212
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES); //CMSI-212
        ilib_LogEvent.push(LOG_TITLE + '.finish'); //CMSI-212
        ilib_LogEvent.pop(); //CMSI-212
        ilib_LogEvent.emit(); //CMSI-212
    }


    // ************************************************************************************************
    // Deferrable implementation DCP-50962
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
        this.inputs = (BatchAccountPlanPopulateRegion.Inputs)JSON.deserialize(serializedInputs,BatchAccountPlanPopulateRegion.Inputs.class);
    }
}
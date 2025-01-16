    /*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description: Batch class to share Customer_Readiness_Form__c records
    *  @Test class for 90% coverage: TestBatchMigrateShares
    *  @Test class for 75% coverage: TestBatchMigrateShares
    *  Modification Log:
    *  ---------------------------------------------------------------------------------------------------------------------------
    *       Developer                      Date                Description         
    *       Todd Newman                                      Initial Version
    *       Nesar Mohan                 2022-03-30           CodeScan Fix 
    *    ---------------------------------------------------------------------------------------------------------------------------
    **/

global class BatchMigrateCRFShares extends ilib_ScheduleAndBatch {

    /*
    *  @Author      : Todd Newman
    *  @Description : Execute method for the batch class
    *  @Param       : SchedulableContext
    *  @Return      : Void
    */

    global override void execute(SchedulableContext sc)
    {
        Database.executeBatch(new BatchMigrateCRFShares());
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Start method for the batch class to collect Customer_Readiness_Form__c records
    *  @Param       : Database.BatchableContext
    *  @Return      : Database.QueryLocator
    */

    global override Database.QueryLocator start(Database.BatchableContext bc)
    {
        String soql = 'SELECT Id, Opportunity_Name__c ' +
            'FROM Customer_Readiness_Form__c ' +
            'WHERE Opportunity_Name__r.Primary_Field_Service_Engineer__c != null ' +
            'OR Opportunity_Name__r.Primary_Field_Application_Scientist__c != null ' +
            'OR Opportunity_Name__r.Field_Application_Manager__c != null ' +
            'OR Opportunity_Name__r.Field_Service_Manager__c != null ' +
            'OR Opportunity_Name__r.Partner_Primary_Field_App_Scientist__c != null ' +
            'OR Opportunity_Name__r.Partner_Primary_Field_Service_Engineer__c != null';

        return Database.getQueryLocator(soql);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Execute method for the batch class to execute the business logic
    *  @Param       : Database.BatchableContext, List<SObject>
    *  @Return      : Void
    */

    global override void execute(Database.BatchableContext bc, List<SObject> records)
    {
        CustomerReadinessFormsService.shareWithFieldUsers((List<Customer_Readiness_Form__c>)records, null);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Finish method for the batch class
    *  @Param       : Database.BatchableContext
    *  @Return      : Void
    */   
    
    global override void finish(Database.BatchableContext bc) { }

}
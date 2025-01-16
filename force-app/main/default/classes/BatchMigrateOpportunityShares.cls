global class BatchMigrateOpportunityShares { //extends ilib_ScheduleAndBatch {

    global static void obsoleteClass()
    {
        System.debug('no longer needed');
    }
/*
    global override void execute(SchedulableContext sc)
    {
        Database.executeBatch(new BatchMigrateOpportunityShares());
    }

    global override Database.QueryLocator start(Database.BatchableContext BC)
    {
        String soql = 'SELECT Id, Primary_Field_Service_Engineer__c, Primary_Field_Application_Scientist__c, ' +
            'Field_Application_Manager__c, Field_Service_Manager__c, ' +
            'Partner_Primary_Field_App_Scientist__c, Partner_Primary_Field_Service_Engineer__c ' +
            'FROM Opportunity ' +
            'WHERE Primary_Field_Service_Engineer__c != null ' +
            'OR Primary_Field_Application_Scientist__c != null ' +
            'OR Field_Application_Manager__c != null ' +
            'OR Field_Service_Manager__c != null ' +
            'OR Partner_Primary_Field_App_Scientist__c != null ' +
            'OR Partner_Primary_Field_Service_Engineer__c != null';

        return Database.getQueryLocator(soql);
    }

    global override void execute(Database.BatchableContext BC, List<SObject> records)
    {
        OpportunitiesService.shareOpportunites(UtilsCollection.getSetOfIds(records, 'Id'));
    }

    global override void finish(Database.BatchableContext BC) { }
*/

}
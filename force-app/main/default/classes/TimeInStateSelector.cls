/**
 *    @author Gladis
 *    @date   07-Sep-2021
 *    @description    Class to get the Time In State records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Gladis                         07-Sep-2021           Initial Version  
 *    ------------------------------------------------------------------------------------ 
 */

 public with sharing class TimeInStateSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'TimeInStateSelector';
    private static final String SERVICE_QUERY_LOGS = 'servicequerylogs';
    private static final String INSTRUMENTDOWNSTRING  = 'Instrument Down';
    /*
    * @description  describe the object
    */
    public Schema.SObjectType getSObjectType(){
        return Time_In_State__c.sObjectType;
    }
    /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Time_In_State__c.id,
            Time_In_State__c.Case__c,
            Time_In_State__c.Down_Time__c,
            Time_In_State__c.End_Date_Time__c,
            Time_In_State__c.Field__c,
            Time_In_State__c.Installed_Product__c,
            Time_In_State__c.Start_Date_Time__c,
            Time_In_State__c.Time_in_Status__c,
            Time_In_State__c.Name,
            Time_In_State__c.Value__c,
            Time_In_State__c.Work_Order__c,
            Time_In_State__c.Ownerid
        };

    }
    /**
     * @author Gladis
     * @date  07-Sep-2021 
     * @description  get  records using  WorkOrder Id and null EndDateTime
     * @param Id
     */
    public List<Time_In_State__c> getRecordbyWorkOrder(set<Id> setWorkOrderIds) {

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.getRecordbyWorkOrder', UtilsCollection.serializeIds(setWorkOrderIds));

            List<Time_In_State__c> res = (List<Time_In_State__c>) Database.query(
                newQueryFactory()
                .selectField('End_Date_Time__c')
                .setCondition('Work_Order__c IN : setWorkOrderIds ' + ' AND End_Date_Time__c = null')
                .toSOQL()
            );
    
            if(Feature.isOn(SERVICE_QUERY_LOGS))
                logger.stop(res.size());
    
            return res;
        }

	 /**
     *  @author Gaurav
     *  @description Retrieve list of fields for time in state object
     *  @return list of time in state
     **/

    public List<Time_In_State__c> getTimeInState(Set<Id> installProductIds) {
    System.debug(INSTRUMENTDOWNSTRING);
    
    // Check if the Time_In_State__c object is accessible
    Schema.DescribeSObjectResult describeResult = Time_In_State__c.SObjectType.getDescribe();
    
    if (!describeResult.isAccessible()) {
        System.debug('Time_In_State__c object is not accessible for the current user.');
        return new List<Time_In_State__c>(); // Return an empty list if the object is not accessible
    }
    else{
    // Now check field accessibility
    Schema.DescribeFieldResult endDateField = Time_In_State__c.End_Date_Time__c.getDescribe();
    Schema.DescribeFieldResult fieldField = Time_In_State__c.Field__c.getDescribe();
    Schema.DescribeFieldResult installedProductField = Time_In_State__c.Installed_Product__c.getDescribe();

    // Check if fields are accessible
    if (!endDateField.isAccessible() || !fieldField.isAccessible() || !installedProductField.isAccessible()) {
        System.debug('One or more fields are not accessible for the current user.');
        return new List<Time_In_State__c>(); // Return an empty list if fields are not accessible by user
    }
    else{
        List<Time_In_State__c> res = (List<Time_In_State__c>) Database.query(
            newQueryFactory()
                .selectField('Id')
                .selectField('End_Date_Time__c')
                .selectField('Field__c')
                .selectField('Installed_Product__c')
                .setCondition('Installed_Product__c IN :installProductIds AND End_Date_Time__c = null AND Field__c = :INSTRUMENTDOWNSTRING')
                .toSOQL()
        );

        return res;
    }
    }

}


}
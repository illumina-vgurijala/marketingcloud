/*@ author       : KD
* @ date         : 28-July-2020
* @ Description  : CreatePlan in system
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                  Date                       Description
*    KD                      12-Aug-2020                  Added getOverlayPlan method
   Anisha Bharti             07-Sept-2020                DCP-40497 : updated plan recordtype API name
* ---------------------------------------------------------------------------------------------------------------------------------------

* 
*/
@isTest
public with sharing class TestDataPlan {
    public static Id idOverlayRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.PlanOverlay).getRecordTypeId();
    public static Id idDirectRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Direct).getRecordTypeId();
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates Plan
    *  @PARAM :  String TerritoryId
    *  @RETURN:  
    */
    
    public static Plan__c getPlan(String strTerritoryId){
        return new Plan__c(Name = 'Test_Plan', 
                            Territory_Id__c = strTerritoryId,
                            Start_Date__c = Date.Today(),
                            End_Date__c = Date.Today()+120,
                            Status__c = 'Draft',
                            recordTypeId =idDirectRecordType);
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates Plan
    *  @PARAM :  String TerritoryId
    *  @RETURN:  
    */
    
    public static Plan__c getOverlayPlan(String strTerritoryId){
        return new Plan__c(Name = 'Test_Plan', 
                            Territory_Id__c = strTerritoryId,
                            Start_Date__c = Date.Today(),
                            End_Date__c = Date.Today()+120,
                            Status__c = 'Draft',
                            recordTypeId =idOverlayRecordType);
    }

}
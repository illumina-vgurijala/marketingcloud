/**
 *    @author KD
 *    @date   21-Aug-2020
 *    @description  Test class for ViewRelatedActiveTerritoryPlanCtrl Controller
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                        Description
 *   Anisha Bharti                07-Sept-2020                  DCP-40497 : updated plan recordtype API name
*    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestViewRelatedActiveTerritoryPlanCtrl {
    public static Id idInDirectRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';    
        Account acc2 = TestDataAccount.initAccount();
        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc);
        lstAcc.add(acc2);
        insert lstAcc;
        Territory2 objTr = TestTerritoryPlanStrategyController.getTerritory();
        Plan__c objPlan = TestDataPlan.getPlan(objTr.id);
        objPlan.recordTypeId = idInDirectRecordType;
        objPlan.Channel_Partner__c = lstAcc[0].id;
        objPlan.Status__c = 'Active';
        Plan__c objPlan1 = TestDataPlan.getPlan(objTr.id);
        objPlan1.recordTypeId = idInDirectRecordType;
        objPlan1.Channel_Partner__c = lstAcc[1].id;
        objPlan1.Status__c = 'Active';
        Plan__c objPlan2 = TestDataPlan.getPlan(objTr.id);
        objPlan2.Status__c = 'Active';
        insert new List<Plan__c>{objPlan,objPlan1,objPlan2};
    }
    @isTest
    static void testActivePlan(){
        Plan__c objPlan = [select id from Plan__c LIMIT 1];
        Test.starttest();
        String strReturn = ViewRelatedActiveTerritoryPlanCtrl.initRecords(objPlan.id);
        system.debug('-->'+strReturn);
        List<ViewRelatedActiveTerritoryPlanCtrl.PlanWrapper> lstPlan = (List<ViewRelatedActiveTerritoryPlanCtrl.PlanWrapper>)
            		JSON.deserialize(UtilsObject.getJSONPart(strReturn,'{"wrapPlanList": ', ', "mapLabels":'), List<ViewRelatedActiveTerritoryPlanCtrl.PlanWrapper>.class);
        System.assertEquals(2, lstPlan.size(),'Incorrect number of Account Plan');    
        Test.stoptest();
    }
}
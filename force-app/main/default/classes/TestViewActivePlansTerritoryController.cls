/**
 *    @author Anisha
 *    @date   28-July-2020
 *    @description  Test class for ViewActivePlansTerritory Controller
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
 *   
*    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestViewActivePlansTerritoryController {
    @testSetup
    static void setupData(){
        Territory2 objTr = getTerritory();
        Plan__c objPlan = TestDataPlan.getPlan(objTr.id);
        insert objPlan;
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        Account_Plan__c ap = TestDataAccountPlan.getNewAccountPlan(acc);
        ap.Plan_Status__c = 'Active';
        update ap;
        ObjectTerritory2Association objOTA = TestDataObjectTerritory2Association.getObjectAssociation(objTr.id,acc.id);
        insert objOTA;
    }
    @isTest
    static void testFetchActtivePlan(){
        Plan__c objPlan = [select id from Plan__c where Name= 'Test_Plan'];
        Test.starttest();
        String strReturn = ViewActivePlansTerritoryController.initRecords(objPlan.id);
        system.debug('-->'+strReturn);
        List<ViewActivePlansTerritoryController.AccountPlanWrapper> lstAccountPlan = (List<ViewActivePlansTerritoryController.AccountPlanWrapper>)
            		JSON.deserialize(UtilsObject.getJSONPart(strReturn,'{"wrapAccountList": ', ', "mapLabels":'), List<ViewActivePlansTerritoryController.AccountPlanWrapper>.class);
        System.assertEquals(1, lstAccountPlan.size(),'Incorrect number of Account Plan');
        
        Test.stoptest();
    }
     /**
    *    @author KD
    *    @date   28-Jult-2020
    *    @description Method for retrieving Territory
    */
    public static Territory2 getTerritory(){
        List<Territory2Model> lstModels = [SELECT ID,Name,(SELECT ID,Name,Territory2Type.DeveloperName FROM Territory2s where Territory2Type.DeveloperName = 'Territory') 
                                           FROM Territory2Model WHERE State='Active'];
        System.debug('lstModels: ' + lstModels);
        System.assert(!lstModels.isEmpty(),'Territory Model needs to be set up first and activated!');
        Territory2Model objTerritoryModel = lstModels.get(0);
        System.assert(!objTerritoryModel.Territory2s.isEmpty(),'Territory needs to be set up first!');
        Territory2 objTerritory = objTerritoryModel.Territory2s.get(0);
        System.debug('objTerritory: ' + objTerritory);
        return objTerritory;
    }
}
/**
 *    @author Anisha Bharti
 *    @date   10-Aug-2020
 *    @description  Test class for Plans
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *   Anisha Bharti					25-Aug-2020			Added test method testafterupdate
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestPlans {
	/*
    *@author: Anisha Bharti
    *@Desc: Test method 
    */
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
        Territory2 objTr = getTerritory();
        TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,lstAcc[0].id);
        TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,lstAcc[1].id);
        TestDataAccountPlan.getNewAccountPlan(acc);
        
        Plan__c objPlan = TestDataPlan.getPlan(objTr.id);
        List<Plan__c> lstDirectPlans = new List<Plan__c>();
        objPlan.Name = 'Sample Plan1';
        objPlan.Territory_Name__c = objTr.Name;
        objPlan.Territory_Code__c = objTr.Territory_Code__c;
        objPlan.Status__c = Label.PlanStatusActive;
        lstDirectPlans.add(objPlan);
        Plan__c objPlan1 = TestDataPlan.getPlan(objTr.id);
        objPlan1.Name = 'Sample plan2';
        objPlan1.Territory_Name__c = objTr.Name;
        objPlan1.Territory_Code__c = objTr.Territory_Code__c;
        lstDirectPlans.add(objPlan1);
        insert lstDirectPlans;
        
        List<Plan__c> lstIndirectPlans = new List<Plan__c>();
        Plan__c objPlan2 = TestDataPlan.getPlan(objTr.id);
        objPlan2.Name = 'Sample Plan3';
        objPlan2.Territory_Name__c = objTr.Name;
        objPlan2.Territory_Code__c = objTr.Territory_Code__c;
        objPlan2.Channel_Partner__c = acc.id;
        objPlan2.Status__c = Label.PlanStatusActive;
        objPlan2.RecordTypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
        lstIndirectPlans.add(objPlan2);
        Plan__c objPlan3 = TestDataPlan.getPlan(objTr.id);
        objPlan3.Name = 'Sample plan4';
        objPlan3.Territory_Name__c = objTr.Name;
        objPlan3.Territory_Code__c = objTr.Territory_Code__c;
        objPlan3.Channel_Partner__c = acc.id;
        objPlan3.RecordTypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
        lstIndirectPlans.add(objPlan3);
        insert lstIndirectPlans;
    }
    
    @isTest
    static void testdirect(){
        Plan__c objIndirectPlan = [Select id,Territory_Id__c,Status__c from Plan__c where name='Sample Plan4'];
        objIndirectPlan.Status__c = Label.PlanStatusActive;
        try{ 
        	update objIndirectPlan;
        }
        catch(Exception e) {
            System.debug(e.getMessage());
            System.Assert(e.getMessage().contains(Label.Plan_Indirect_Restrict_Active_Error),'Plan update restriction failed');
        }
    }
    @isTest
    static void testIndirect(){
        Plan__c objDirectPlan = [Select id,Territory_Id__c,Status__c from Plan__c where name='Sample Plan2'];
        objDirectPlan.Status__c = Label.PlanStatusActive;
        try{ 
        	update objDirectPlan;
        }
        catch(Exception e) {
             System.debug(e.getMessage());
			System.Assert(e.getMessage().contains(Label.Plan_Direct_Restrict_Active_Error),'Plan update restriction failed');
        }
    }
    /**
    *    @author Anisha Bharti
    *    @date   25-Aug-2020
    *    @test Method onafterupdate of plan
    */
    @isTest
    static void testafterupdate(){
        Account acc = [select id, name,Territory_Region__c from Account where Territory_Region__c ='AMR'];
        Plan__c objDirectPlan = [Select id,Territory_Id__c,Territory_Code__c,Status__c from Plan__c where name='Sample Plan1'];
        Map<String, SObject> mapTerritorycodePlan = new Map<String, SObject>();
        mapTerritorycodePlan.put(objDirectPlan.Territory_Code__c, objDirectPlan);
    	Map<Id, String> mapAccountTerritoryCode = new Map<Id, String>();
        mapAccountTerritoryCode.put(acc.id, objDirectPlan.Territory_Code__c);
        Plan__c objDirectPlan1 = [Select id,Territory_Id__c,Status__c from Plan__c where name='Sample Plan1'];
        objDirectPlan1.Status__c = Label.PlanStatusDraft;
        update objDirectPlan1;
        Plan__c objDirectPlan2 = [Select id,Territory_Id__c,Status__c from Plan__c where name='Sample Plan1'];
        test.startTest();
        objDirectPlan2.Status__c = Label.PlanStatusActive;
        update objDirectPlan2;
        test.stopTest();
        Account_Plan__c objAccPlan = [select id, name, Territory_Plan__c from Account_Plan__c];
        System.assert(BatchUpdateAccountPlanWithActiveTP.lstSaveErrors.isEmpty(),'Error found were not expected');
        System.assertEquals(objAccPlan.Territory_Plan__c , objDirectPlan2.id);
    }
  
    /**
    *    @author Anisha Bharti
    *    @date   10-Aug-2020
    *    @description Method for retrieving Territory
    */
    public static Territory2 getTerritory(){
        List<Territory2Model> lstModels = [SELECT ID,Name,(SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName FROM Territory2s where Territory2Type.DeveloperName = 'Territory') 
                                           FROM Territory2Model WHERE State='Active'];
        System.assert(!lstModels.isEmpty(),'Territory Model needs to be set up first and activated!');
        Territory2Model objTerritoryModel = lstModels.get(0);
        System.assert(!objTerritoryModel.Territory2s.isEmpty(),'Territory needs to be set up first!');
        Territory2 objTerritory = objTerritoryModel.Territory2s.get(0);
        return objTerritory;
    }
    
}
/**
 *    @author Kushagra Desai
 *    @date   28-July-2020
 *    @description  Test class for Strategy UI Controller
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
 *    KD                            31-Aug-2020          DCP-40334 : Automation of Objective creation from associated account  
 *    KD                            21-Sept-2020         DCP-41752 : Account visibility for Channel partner
 *    Ashwin Kumar                  31-Mar-2021          DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestTerritoryPlanStrategyController {
    public static final String JSON_PART_1 = ',"lstAccountWrap": ';
    public static final String ASSERT_MESSAGE_1 = 'Incorrect number of Account Returned';
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    @testSetup 
    static void setupData(){
        setupAllData();
        
    }
    static void setupAllData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            Territory2 objIndirect = getIndirectTerritory();
            Account acc = TestDataAccount.initAccount();
            acc.ERP_Customer_Id__c = '123456';
            acc.Territory_Region__c = 'AMR';    
            Account acc2 = TestDataAccount.initAccount();
            // DCP-41752
            Account acc3 = TestDataAccount.initAccount();
            acc3.ERP_Customer_Id__c = '121212';
            acc3.Territory_Region__c = 'AMR';
            acc3.Account_Group__c = 'Distributor';
            acc3.Territory_Name__c = objIndirect.Id;
            acc3.Territory_Code__c = objIndirect.Territory_Code__c;
            List<Account> lstAcc = new List<Account>();
            lstAcc.add(acc);
            lstAcc.add(acc2);
            lstAcc.add(acc3);
            insert lstAcc;
            Account_Plan__c accPlan = TestDataAccountPlan.initAccoutPlan(lstAcc[0].id);
            accPlan.Plan_Status__c = Label.AccountPlanStatusActive;
            Account_Plan__c accPlan1 = TestDataAccountPlan.initAccoutPlan(lstAcc[0].id);
            accPlan.Plan_Status__c = Label.AccountPlanStatusDraft;
            insert new List<Account_Plan__c>{accPlan,accPlan1};
            Territory2 objTr = getTerritory();
            TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,lstAcc[0].id);
            TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,lstAcc[1].id);
            TestDataObjectTerritory2Association.getObjectAssociationFuture(objIndirect.id,lstAcc[2].id);
            Id idInDirectRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
            Plan__c objTPlanIndirect = TestDataPlan.getPlan(objTr.id);
            objTPlanIndirect.Name='Territory Indirect Plan';
            objTPlanIndirect.Territory_Code__c = objTr.Territory_Code__c;
            objTPlanIndirect.Channel_Partner_Territory_Code__c = objIndirect.Territory_Code__c;
            objTPlanIndirect.recordTypeId = idInDirectRecordType;
            Plan__c objPlan = TestDataPlan.getPlan(objTr.id);
            objPlan.Name = 'Direct Plan';
            objPlan.Territory_Name__c = objTr.Name;
            //DCP-41752
            objPlan.Territory_Code__c = objTr.Territory_Code__c;
            insert new List<Plan__c>{objPlan,objTPlanIndirect};
            Plan_Strategy__c objPlanStrategy = TestDataPlanStrategy.getPlanStrategy(objPlan.id);
            Plan_Strategy__c objInPlanStrategy = TestDataPlanStrategy.getPlanStrategy(objTPlanIndirect.id);
            insert new List<Plan_Strategy__c>{objInPlanStrategy,objPlanStrategy};
            Plan_Objective__c objPlanObjective = TestDataPlanObjective.getPlanObjective(objPlanStrategy.id);
            Plan_Objective__c objInPlanObjective = TestDataPlanObjective.getPlanObjective(objInPlanStrategy.id);
            objInPlanObjective.Name = 'Indirect Objective';
            insert new List<Plan_Objective__c>{objInPlanObjective,objPlanObjective};
            List<Task> lstTsk = new List<Task>();
            Task objtsk = new Task();
            objtsk.WhatId = objPlanObjective.id;
            lstTsk.add(objtsk);
            Task objtsk1 = new Task();
            objtsk1.WhatId = objPlanObjective.id;
            lstTsk.add(objtsk1);
            Task objtsk2 = new Task();
            objtsk2.WhatId = objPlanObjective.id;
            lstTsk.add(objtsk2);
            insert lstTsk;
        }
    }
    @isTest
    static void testPlanMetrics(){
        Test.startTest();
        Plan_Objective__c objPlanObjective = [Select id from Plan_Objective__c where Name != 'Indirect Objective'];
        Tasks.boolIsTestRunning = true;
        Task objtsk4 = new Task();
        objtsk4.WhatId = objPlanObjective.id;
        insert objtsk4;
        Test.getEventBus().deliver();
        String strReturn = TerritoryPlanStrategyController.fetchTaskList(objPlanObjective.id);
        List<TerritoryPlanStrategyController.ActionWrapper> lstTask = (List<TerritoryPlanStrategyController.ActionWrapper>)
                    JSON.deserialize(UtilsObject.getJSONPart(strReturn,'{"lstActionWrapper": ', '}'), List<TerritoryPlanStrategyController.ActionWrapper>.class);
        System.assertEquals(4,lstTask.size(),'Incorrect number of Task Returned');
        Test.stopTest();
    }
    @isTest
    static void testLoad(){
        User objAdminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        User objUsr = TestDataUser.findUserInProfile('Sales User');
        Plan__c objPlan = [Select id,Territory_Id__c from Plan__c where Name = 'Direct Plan'];
        Plan__c objInDirectPlan = [Select id,Territory_Id__c,Channel_Partner_Territory_Code__c from Plan__c where Name != 'Direct Plan'];
        System.runAs(objAdminUser){
            List<UserTerritory2Association> lstOTA = [Select id from UserTerritory2Association where UserId =:objUsr.id and Territory2Id =: objPlan.Territory_Id__c];
            if(lstOTA.isEmpty()){
                UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(objPlan.Territory_Id__c,objUsr.id);
                insert objUTA;
            }
        }
        Test.startTest();
        String strReturn;
        strReturn = TerritoryPlanStrategyController.initRecord(objPlan.id);
        List<TerritoryPlanStrategyController.PlanStrategyWrapper> lstPlanStrategy = (List<TerritoryPlanStrategyController.PlanStrategyWrapper>)
                    JSON.deserialize(UtilsObject.getJSONPart(strReturn,'{"lstStrategyWrap": ', ', "mapLabels":'), List<TerritoryPlanStrategyController.PlanStrategyWrapper>.class);
        System.assertEquals(1,lstPlanStrategy.size(),'Incorrect number of Strategy Returned');
        Plan_Strategy__c objPlanStrategy = [Select id from Plan_Strategy__c LIMIT 1];
        strReturn = TerritoryPlanStrategyController.fetchStrategy(objPlanStrategy.id);
        List<TerritoryPlanStrategyController.PlanObjectiveWrapper> lstPlanObjective = (List<TerritoryPlanStrategyController.PlanObjectiveWrapper>)
                    JSON.deserialize(UtilsObject.getJSONPart(strReturn,'"objPlanObjectiveWrapper": ', '}'), List<TerritoryPlanStrategyController.PlanObjectiveWrapper>.class);
        System.assertEquals(1,lstPlanObjective.size(),'Incorrect number of Objective Returned');
        Plan_Objective__c objPlanObjective = [Select id from Plan_Objective__c where Name != 'Indirect Objective'];
        strReturn = TerritoryPlanStrategyController.fetchObjective(objPlanObjective.id);
        strReturn = TerritoryPlanStrategyController.fetchTaskList(objPlanObjective.id);
        List<TerritoryPlanStrategyController.ActionWrapper> lstTask = (List<TerritoryPlanStrategyController.ActionWrapper>)
                    JSON.deserialize(UtilsObject.getJSONPart(strReturn,'{"lstActionWrapper": ', '}'), List<TerritoryPlanStrategyController.ActionWrapper>.class);
        System.assertEquals(3,lstTask.size(),'Incorrect number of Task Returned');
        // DCP-41752
        strReturn = TerritoryPlanStrategyController.fetchAssociatedAccount(objPlanObjective.id);
        List<TerritoryPlanStrategyController.AccountWrapper> lstAccount = (List<TerritoryPlanStrategyController.AccountWrapper>)
                    JSON.deserialize(UtilsObject.getJSONPart(strReturn,JSON_PART_1, '}'), List<TerritoryPlanStrategyController.AccountWrapper>.class);
        System.assertEquals(2,lstAccount.size(),ASSERT_MESSAGE_1);
        Plan_Objective__c objInPlanObjective = [Select id from Plan_Objective__c where Name = 'Indirect Objective'];
        String strReturn1;
        strReturn1 = TerritoryPlanStrategyController.getAssociatedAccountsForObjectives(objInPlanObjective.id);
        List<TerritoryPlanStrategyController.AccountWrapper> lstAllAccount = (List<TerritoryPlanStrategyController.AccountWrapper>)
                    JSON.deserialize(UtilsObject.getJSONPart(strReturn1,JSON_PART_1, '}'), List<TerritoryPlanStrategyController.AccountWrapper>.class);
        System.assertEquals(3,lstAllAccount.size(),ASSERT_MESSAGE_1);
        User objUsrIndirect = new User();
        objUsrIndirect =  TestDataUser.findUserInProfile(Label.Profile_Channel_Partner_Sales);
        if(objUsrIndirect == null)  
            objUsrIndirect =  TestDataUser.findUserInProfile(Label.Profile_Channel_Partner_Sales_Login);
        Territory2 objTrIn = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
        FROM Territory2 WHERE Territory_Code__c =: objInDirectPlan.Channel_Partner_Territory_Code__c and Territory2Model.State='Active'];
        System.runAs(objAdminUser){
            List<UserTerritory2Association> lstOTA1 = [Select id from UserTerritory2Association where UserId =:objUsrIndirect.id and Territory2Id =: objTrIn.id];
            if(lstOTA1.isEmpty()){
                UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(objTrIn.id,objUsrIndirect.id);
                insert objUTA;
            }
            PermissionSet objPS = [select id,name from PermissionSet where name = 'CP_Plan' LIMIT 1];
            List<PermissionSetAssignment> lstPSA= [select id from PermissionSetAssignment where AssigneeId =:objUsrIndirect.id and PermissionSetId=:objPS.id];
            if(lstPSA.isEmpty()){
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = objUsrIndirect.id;
                psa.PermissionSetId = objPS.Id;
                insert psa;
            }
        }
        System.runAs(objUsrIndirect){   
            String strReturn2 = TerritoryPlanStrategyController.fetchAssociatedAccount(objInPlanObjective.id);
            List<TerritoryPlanStrategyController.AccountWrapper> lstAllAccount1 = (List<TerritoryPlanStrategyController.AccountWrapper>)
            JSON.deserialize(UtilsObject.getJSONPart(strReturn2,JSON_PART_1, '}'), List<TerritoryPlanStrategyController.AccountWrapper>.class);
                System.assertEquals(1,lstAllAccount1.size(),ASSERT_MESSAGE_1);
        }
        Test.stopTest();
    }
    @isTest
    static void testAddDeleteAssociatedAccount(){
        Test.startTest();
        Plan_Objective__c objPlanObj = [Select id from Plan_Objective__c LIMIT 1];
        Plan_Objective__c objPlanObjective = new PlanObjectiveSelector().getPlanObjectiveById(objPlanObj.Id)[0];
        List<Account> lstAcc = [Select id from Account];
        List<Id> lstAccId = new List<Id>();
        for(Account a: lstAcc)
            lstAccId.add(a.id);
        System.assert(TerritoryPlanStrategyController.addAssociatedAccount(lstAccId,objPlanObjective.id,JSON.serialize(new TerritoryPlanStrategyController.PlanObjectiveWrapper(objPlanObjective))).contains('account(s) is/are associated with the objective'),'ATO insertion failed');
        String strReturn = TerritoryPlanStrategyController.fetchAssociatedAccount(objPlanObjective.id);
        List<TerritoryPlanStrategyController.AccountWrapper> lstAccount = (List<TerritoryPlanStrategyController.AccountWrapper>)
                    JSON.deserialize(UtilsObject.getJSONPart(strReturn,JSON_PART_1, '}'), List<TerritoryPlanStrategyController.AccountWrapper>.class);
        System.assertEquals(0,lstAccount.size(),ASSERT_MESSAGE_1);
        List<Plan_Objective_Account__c> lstAccPlanObj = [Select id from Plan_Objective_Account__c];
        List<Id> lstAPOId = new List<Id>();
        for(Plan_Objective_Account__c objAPO : lstAccPlanObj)
            lstAPOId.add(objAPO.id);
        System.assert(TerritoryPlanStrategyController.deleteAssociatedAccount(lstAPOId).contains('account(s) is/are de-associated with the objective'),'ATO deletion failed');
        Test.stopTest();
    }
    // DCP-40334 
    @isTest
    static void testObjectiveCreation(){
        Test.startTest();
        Plan_Objective__c objPlanObj = [Select id from Plan_Objective__c LIMIT 1];
        Plan_Objective__c objPlanObjective = new PlanObjectiveSelector().getPlanObjectiveById(objPlanObj.Id)[0];
        List<Account> lstAcc = [Select id from Account];
        List<Id> lstAccId = new List<Id>();
        for(Account a: lstAcc)
            lstAccId.add(a.id);
        System.assert(TerritoryPlanStrategyController.addAssociatedAccount(lstAccId,objPlanObjective.id,JSON.serialize(new TerritoryPlanStrategyController.PlanObjectiveWrapper(objPlanObjective))).contains('account(s) is/are associated with the objective'),'ATO insertion failed');
        Test.stopTest();
        List<Objective__c> lstAccountObjective = [Select id from Objective__c];
        System.assertEquals(2,lstAccountObjective.size(),'Objective not inserted');
    }
    /**
    *    @author KD
    *    @date   28-Jult-2020
    *    @description Method for retrieving Territory
    */
    public static Territory2 getTerritory(){
        List<Territory2Model> lstModels = [SELECT ID,Name,(SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c,District__c,Territory_Region__c FROM Territory2s where Territory2Type.DeveloperName = 'Territory') 
                                           FROM Territory2Model WHERE State='Active'];
        System.debug('lstModels: ' + lstModels);
        System.assert(!lstModels.isEmpty(),'Territory Model needs to be set up first and activated!');
        Territory2Model objTerritoryModel = lstModels.get(0);
        System.assert(!objTerritoryModel.Territory2s.isEmpty(),'Territory needs to be set up first!');
        Territory2 objTerritory = objTerritoryModel.Territory2s.get(0);
        System.debug('objTerritory: ' + objTerritory);
        return objTerritory;
    }
    /**
    *    @author KD
    *    @date   28-July-2020
    *    @description Method for retrieving Indirect Territory
    // DCP-41752
    */
    static Territory2 getIndirectTerritory(){
        List<Territory2> lstTerritories = [SELECT ID,Name,Territory_Code__c
                                                FROM Territory2 
                                                WHERE Territory2Type.DeveloperName = 'District_Channel_Partner' 
                                                        AND Territory2Model.State='Active'
                                                        AND ParentTerritory2Id<>null
                                                LIMIT 1];
        System.assertEquals(1,lstTerritories.size(),'No Territories found');
        Territory2 objT = lstTerritories[0];
        return objT;
    }
}
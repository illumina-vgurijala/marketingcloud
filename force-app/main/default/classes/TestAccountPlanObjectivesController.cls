/**
*    @author: Kushagra Desai
*    @date:   19-Sept-2019
*    @description:  Test class for Controller class of  Component AccountPlanObjectives
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*               KD                          7-Aug-2020           DCP-39561 : Add data setup method and test method for objective cloning 
*              Adithi Acharya               11-Oct-2022          Test Coverage for MultiSelectLookupController.cls
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public class TestAccountPlanObjectivesController {
     /*
    *@author: Kushagra Desai
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
        Territory2 objTr = TestTerritoryPlanStrategyController.getTerritory();
        TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,lstAcc[0].id);
        Plan__c objPlan = TestDataPlan.getPlan(objTr.id);
        objPlan.Territory_Name__c = objTr.Name;
        objPlan.Territory_Code__c = objTr.Territory_Code__c;
        insert objPlan;
        Plan_Strategy__c objPlanStrategy = TestDataPlanStrategy.getPlanStrategy(objPlan.id);
        insert objPlanStrategy;
        Plan_Objective__c objPlanObjective = TestDataPlanObjective.getPlanObjective(objPlanStrategy.id);
        insert objPlanObjective;
        Plan_Objective_Account__c objAPO = new Plan_Objective_Account__c(Account__c = lstAcc[0].id,Plan_Objective__c = objPlanObjective.id);
        insert objAPO;
        Account_Plan__c ap = TestDataAccountPlan.getNewAccountPlan(lstAcc[0]);
        Account_Plan__c ap1 = TestDataAccountPlan.getNewAccountPlan(lstAcc[1]);
        ap1.Name = 'No Territory';
        update ap1;
        
        TestDataObjectives.getNewObjective(ap);
        TestDataObjectives.getNewObjective(ap);
        TestDataObjectives.getNewObjective(ap);
    }
    @isTest
    static void testinitRecords(){
        Account_Plan__c ap = [Select id from Account_Plan__c where Name != 'No Territory' LIMIT 1];
        String jsonReturn = AccountPlanObjectivesController.initRecord(ap.id);
        AccountPlanObjectivesController.InitDataWrapper initwrap = (AccountPlanObjectivesController.InitDataWrapper)JSON.deserialize(jsonReturn, AccountPlanObjectivesController.InitDataWrapper.class);
        System.assert(!initwrap.lstobjectiveWrap.isEmpty(),'No objective record found');
        List<Objective__c> lstObjective = [Select id from Objective__c where Account_Plan__c=: ap.id]; 
        List<Task> lstTsk = new List<Task>();
        Task objtsk = new Task();
        objtsk.WhatId = lstObjective[0].id;
        lstTsk.add(objtsk);
        Task objtsk1 = new Task();
        objtsk1.WhatId = lstObjective[0].id;
        lstTsk.add(objtsk1);
        Task objtsk2 = new Task();
        objtsk2.WhatId = lstObjective[0].id;
        lstTsk.add(objtsk2);
        insert lstTsk;
        Set<Id> userProfileId = Profiles.getAdminProfileId();
        List<User> lstUsers = [
            SELECT Id, Name, IsActive
            FROM User
            WHERE ProfileId IN :userProfileId
            AND IsActive = true
            LIMIT 1
        ];
        List<Id> lstUserIds = new List<Id>();
        for (User user : lstUsers) {
            lstUserIds.add(user.Id);
        }
        System.assert(AccountPlanObjectivesController.deleteTask(objtsk1.id),'Task not deleted');
        String taskData = '{"Subject":"Test Data","DueDate":"2019-09-19","Descrition":"Test comment","Status":"Open","Priority":"Normal"}';
        System.assert(AccountPlanObjectivesController.createTask(taskData,lstObjective[0].id, JSON.serialize(lstUserIds)),'Task not created');
        String taskDataUpdate = '{"Subject":"Test Data Update","DueDate":"2019-09-19","Descrition":"Test comment","Status":"Completed","Priority":"Normal","TaskId":"'+objtsk2.id+'"}';
        System.assert(AccountPlanObjectivesController.createTask(taskDataUpdate,lstObjective[0].id, '[]'),'Task not Updated');
    }
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: Method to test fetching and adding of objectives.
    *  @PARAM :  
    *  @RETURN:  
    */
    @isTest
    static void testAssociatedObjectiveFetch(){
        Account_Plan__c objAccountPlan = [Select id,Account_Name__c from Account_Plan__c where Name != 'No Territory' LIMIT 1];
        String strJSON = AccountPlanObjectivesController.getAssociatedObjective(objAccountPlan.Account_Name__c,objAccountPlan.id);
        List<TerritoryPlanStrategyController.AccountPlanObjectiveWrapper> lstAccountPlanWrapper = (List<TerritoryPlanStrategyController.AccountPlanObjectiveWrapper>)JSON.deserialize(strJSON,List<TerritoryPlanStrategyController.AccountPlanObjectiveWrapper>.class);
        System.assert(!lstAccountPlanWrapper.isEmpty(),'No Objective fetched');
        String strReturn = AccountPlanObjectivesController.createAccountObjective(strJSON,objAccountPlan.id);
        System.assert(strReturn.contains('Objectives added to account plan'),'Objective not created');
        Account_Plan__c ap = [Select id,Account_Name__c from Account_Plan__c where Name = 'No Territory' LIMIT 1];
        try{
            AccountPlanObjectivesController.getAssociatedObjective(ap.Account_Name__c,ap.id);
        }
        catch(Exception e){
            System.assertEquals('Script-thrown exception',e.getMessage(),'Wrong Exception Caught');
        }
    }
     /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION: DCP-40334  : Method to test fetching and adding of objectives.
    *  @PARAM :  
    *  @RETURN:  
    */
    @isTest
    static void testAssociatedObjectiveFetch1(){
        Account_Plan__c objAccountPlan = [Select id,Account_Name__c from Account_Plan__c where Name != 'No Territory' LIMIT 1];
        Plan__c objPlan1 = [Select id,Territory_Name__c,Territory_Code__c,Territory_Id__c from Plan__c LIMIT 1];
        Plan__c objPlan = TestDataPlan.getPlan(objPlan1.Territory_Id__c);
        objPlan.Territory_Name__c = objPlan1.Territory_Name__c;
        objPlan.Territory_Code__c = objPlan1.Territory_Code__c;
        objPlan.Status__c = 'Active';
        insert objPlan;
        String strJSON = AccountPlanObjectivesController.getAssociatedObjective(objAccountPlan.Account_Name__c,objAccountPlan.id);
        List<TerritoryPlanStrategyController.AccountPlanObjectiveWrapper> lstAccountPlanWrapper = (List<TerritoryPlanStrategyController.AccountPlanObjectiveWrapper>)JSON.deserialize(strJSON,List<TerritoryPlanStrategyController.AccountPlanObjectiveWrapper>.class);
        System.assert(lstAccountPlanWrapper.isEmpty(),'Objective fetched Incorrect');
    }

    /**
    * @description 
    * @author Rohan Rathod | 09-28-2022 
    **/
    @isTest
    static void testMultiSelectLookupController(){
        User u = TestDataFieldService.createUser(System.label.Field_Service,false);
        Insert u;
        List<string> lstUserIds = new List<string>();
        lstUserIds.add(u.Id);
        Set<Id> userProfileId = Profiles.getAdminProfileId();
        List<User> lstUsers = [
            SELECT Id, Name, IsActive
            FROM User
            WHERE ProfileId IN :userProfileId
            AND IsActive = true
            LIMIT 1
        ];
        List<String> lstUserNames = new List<String>();
        for (User user : lstUsers) {
            lstUserNames.add(user.Name);
        }
        String params = '{"objectName":"User","fieldName":"Name","value":"' + lstUserNames[0] + '","limitValue":"20","orderBy":"asc"}';
        String sObjResult = MultiSelectLookupController.getResults(params, null);
        new MultiSelectLookupController.DataWrapper('test1','test2','test3','test4','test5'); //Test Coverage 
        MultiSelectLookupController.getResults(null, null);
        System.assert(sObjResult!=null, 'No values returned');

    }
    
}
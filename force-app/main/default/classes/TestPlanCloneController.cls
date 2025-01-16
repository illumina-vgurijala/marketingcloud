/**
 *    @author Kushagra Desai
 *    @date   17-Sep-2020
 *    @description  Test class for Plan Clone Controller
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
*     Developer               Date                 Description
*     Ashwin Kumar            31-Mar-2021          DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    Adyasha Satapathy       30-Aug-2022          DCP-54419: Added Coverage for cloning of related Opportunities while cloning Territory plan
    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestPlanCloneController {
    static Territory2 getTerritory(){
        List<Territory2> lstTerritories = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,
                                                ParentTerritory2Id,ParentTerritory2.Territory_Code__c,ParentTerritory2.ParentTerritory2Id
                                                FROM Territory2 
                                                WHERE Territory2Type.DeveloperName = 'Territory' 
                                                        AND Territory2Model.State='Active'
                                                        AND ParentTerritory2Id<>null
                                                LIMIT 1];
        System.assertEquals(1,lstTerritories.size(),'No Territories found');
        Territory2 objT = lstTerritories[0];
        objT.Name='Testing Territory';
        update objT;
        return objT;
    }
    /**
    *    @author KD
    *    @date   17-Sep-2020
    *    @description Method get admin user having NO territory association.
    */
    public static User getAdminUser(){
        Set<String> setDirectTerritoryType = new Set<String>{
            TerritoryTypesService.TYPE_BU,
            TerritoryTypesService.TYPE_REGION,
            TerritoryTypesService.TYPE_SUBREGION,
            TerritoryTypesService.TYPE_STREAM,
            TerritoryTypesService.TYPE_DISTRICT,
            TerritoryTypesService.TYPE_TERRITORY
        };
        Set<Id> setUsers = new Set<Id>();
        for(UserTerritory2Association objUTA : [SELECT UserId FROM UserTerritory2Association where Territory2.Territory2Model.State = 'Active' AND Territory2.Territory2Type.MasterLabel IN :setDirectTerritoryType])
            setUsers.add(objUTA.UserId);
        return TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,setUsers);
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    @testSetup 
    static void setupData(){
        createETMData();
        
    }
    /*
    *@author: Satya Swain
    *@Desc: created to avoid mixed DML exception for DCP-43261/TASK0548217
    */
    static void createETMData(){
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            Territory2 objTr = getTerritory();
            Id idUser = getAdminUser().Id;
            List<UserTerritory2Association> lstUTAInsert = new List<UserTerritory2Association>();
            List<UserTerritory2Association> lstUTA = new List<UserTerritory2Association>();
            lstUTA = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.Id and UserId =:idUser];
            if(lstUTA.isEmpty()){
                lstUTAInsert.add(TestDataUserTerritory2Association.getUserAssociation(objTr.Id,idUser));
            }
            lstUTA = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.ParentTerritory2Id and UserId =:idUser];
            if(lstUTA.isEmpty()){
                lstUTAInsert.add(TestDataUserTerritory2Association.getUserAssociation(objTr.ParentTerritory2Id,idUser));
            }
            lstUTA = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.ParentTerritory2.ParentTerritory2Id and UserId =:idUser];
            if(lstUTA.isEmpty()){
                lstUTAInsert.add(TestDataUserTerritory2Association.getUserAssociation(objTr.ParentTerritory2.ParentTerritory2Id,idUser));
            }
            insert lstUTAInsert;
        } 
    }
    @isTest
    static void testCloneDirectPlan(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';  

        insert acc;
        Test.startTest();
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Territory' ]; 
        Plan__c objTPlan = TestDataPlan.getPlan(objTr.id);
        objTPlan.Name='Territory Plan';
        objTPlan.Territory_Code__c = objTr.Territory_Code__c;
        objTPlan.Gap_Analysis__c = 'Gap Plan Analysis';
        insert objTPlan;
        Plan_Strategy__c objPlanStrategy = TestDataPlanStrategy.getPlanStrategy(objTPlan.id);
        insert objPlanStrategy;
        Plan_Objective__c objPlanObjective = TestDataPlanObjective.getPlanObjective(objPlanStrategy.id);
        insert objPlanObjective;
        Plan_Objective_Account__c objAPO = new Plan_Objective_Account__c(Account__c =acc.id,Plan_Objective__c = objPlanObjective.id);
        insert objAPO;

        //DCP-54419
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc);
        opp1.Name = TestPlanAssociatedOppsController.OPPORTUNITY_NAME; 
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
        insert new List<Opportunity>{opp1, opp2};

        Objective_Opportunity_Relationship__c oor1 = new Objective_Opportunity_Relationship__c(Opportunity__c = opp1.Id, Plan_Objective__c = objPlanObjective.Id, Plan__c = objTPlan.Id);
        insert oor1;
        //End of 54419

        List<Task> lstTsk = new List<Task>();
        Task objtsk = new Task();
        objtsk.WhatId = objPlanObjective.id;
        lstTsk.add(objtsk);

        insert lstTsk;
        ContentNote contentNote = new ContentNote();
        contentNote.Title = 'Test Note';
        insert contentNote;
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(contentNote.Id, objTPlan.Id,'V','AllUsers');
        insert objCDL;

        String lstCloneStrategiesWrapper = PlanCloneController.getStrategies(objTPlan.Id);

        String strJSON = '{"Territory_Name":"AB Sask","Territory_Code":"AMR13101","Territory_Id":"0MI3l000000Xqy5GAC","Territory_Region":"AMR","Channel_Partner":"","Start_Date":"2021-01-01T00:00:00.000Z","End_Date":"2021-12-31T00:00:00.000Z"}';
        String strClonedId = PlanCloneController.deepClone(strJSON,objTPlan.id,lstCloneStrategiesWrapper);
        Test.stopTest();
        List<Plan__c> territoryPlan = new PlanSelector().getTerritoryPlanbyId(strClonedId);
        System.assertEquals('AB Sask',territoryPlan[0].Territory_Name__c,'Territory Stamped incorrect');
        List<Plan_Strategy__c> lstClonedPlanStrategy = new PlanStrategySelector().getPlanStrategyWithObjectiveByPlan(strClonedId);
        System.assertEquals(1,lstClonedPlanStrategy.size(),'Strategy not Cloned');
        System.assertEquals(1,lstClonedPlanStrategy[0].Plan_Objectives__r.size(),'Objective not Cloned');

        //DCP-54419
        if(lstClonedPlanStrategy != null && !lstClonedPlanStrategy.isEmpty()) {

            Set<Id> setPlanStrategyId = new Set<Id>();
            setPlanStrategyId.add(lstClonedPlanStrategy[0].id);

            List<Plan_Objective__c> lstPlanObjective = [Select Id from Plan_Objective__c where Plan_Strategy__c = :setPlanStrategyId];
            List<Objective_Opportunity_Relationship__c> lstClonedOOR = [Select Id from Objective_Opportunity_Relationship__c where Plan_Objective__c = :lstPlanObjective[0].id];
            System.assertEquals(1,lstClonedOOR.size(),'Associated opportunities are not Cloned');
            
        }
        //DCP-54419

        try{
            String strJSON1 = '{"Territory_Name":"AB Sask","Territory_Code":"AMR13101","Territory_Id":"0MI3l000000Xqy5GAC","Territory_Region":"AMR","Channel_Partner":"","Start_Date":"Hello","End_Date":"Hello"}';
            PlanCloneController.deepClone(strJSON1,objTPlan.id,lstCloneStrategiesWrapper);
        }
        catch(exception e){
            System.assertEquals('Script-thrown exception',e.getMessage(),'Wrong Exception Caught');
        }
    }
    /*******************************************************
    *Method Name : coverCatchBlock_PlanAndAccPlanAttachmentQueueable()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest
    public static void coverCatchBlockPlanAndAccPlanAttachmentQueueable(){
        try{
            PlanAndAccPlanAttachmentQueueable.catchException = true;
            PlanAndAccPlanAttachmentQueueable pd = new PlanAndAccPlanAttachmentQueueable(null, null,null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}
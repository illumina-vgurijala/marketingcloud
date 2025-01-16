/**
 *    @author Adyasha Satapathy
 *    @date   06-December-2021
 *    @description : DCP-50392 : Test class for PlanAssociatedOpportunitiesController
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer             Date                      Description
 *    Adyasha           06-December-2021            Initial Version
 *    Ashwin Kumar      31-Mar-2021                 DCP-52339 Remove TestTAPS.setupDeferredObjectData
 *    -----------------------------------------------------------------------------------------------        
 */
@istest
public with sharing class TestPlanAssociatedOppsController 
{
    public static final String INDIRECT_PLAN_OBJECTIVE = 'Indirect Plan Objective';
    public static final String OVERLAY_PLAN_OBJECTIVE = 'Overlay plan Objective';
    public static final String OPPORTUNITY_NAME = 'Opportunity Test';

    /*
    *@author: Adyasha
    *@Desc: Test method 
    */
    @testSetup 
    static void setupData()
    {
        setupAllData();  
    }
    
    static void setupAllData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser)
        {
            Territory2 objIndirect = getIndirectTerritory();
            Account acc = TestDataAccount.initAccount();
            acc.ERP_Customer_Id__c = '123456';
            acc.Territory_Region__c = 'AMR';    
            Account acc2 = TestDataAccount.initAccount();
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
            
            Objective__c objObjective1 = TestDataObjectives.initObjective(accPlan.Id);
            insert new List<Objective__c>{objObjective1};

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
            objPlan.Territory_Code__c = objTr.Territory_Code__c;
            Plan__c objOverlayPlan = TestDataPlan.getOverlayPlan(objTr.id);
            insert new List<Plan__c>{objPlan,objTPlanIndirect, objOverlayPlan};

            Plan_Strategy__c objPlanStrategy = TestDataPlanStrategy.getPlanStrategy(objPlan.id);
            Plan_Strategy__c objInPlanStrategy = TestDataPlanStrategy.getPlanStrategy(objTPlanIndirect.id);
            Plan_Strategy__c objOverlayPlanStrategy = TestDataPlanStrategy.getPlanStrategy(objOverlayPlan.id);
            insert new List<Plan_Strategy__c>{objInPlanStrategy,objPlanStrategy,objOverlayPlanStrategy};

            Plan_Objective__c objPlanObjective = TestDataPlanObjective.getPlanObjective(objPlanStrategy.id);
            Plan_Objective__c objInPlanObjective = TestDataPlanObjective.getPlanObjective(objInPlanStrategy.id);
            objInPlanObjective.Name = INDIRECT_PLAN_OBJECTIVE;
            Plan_Objective__c objOverlayPlanObjective = TestDataPlanObjective.getPlanObjective(objOverlayPlanStrategy.id);
            objOverlayPlanObjective.Name = OVERLAY_PLAN_OBJECTIVE;
            insert new List<Plan_Objective__c>{objInPlanObjective,objPlanObjective, objOverlayPlanObjective};
           
            Opportunity opp1 = TestDataOpportunity.initOpportunity(acc);
            opp1.Name = OPPORTUNITY_NAME;
            Opportunity opp2 = TestDataOpportunity.initOpportunity(acc2);
            Opportunity opp3 = TestDataOpportunity.initOpportunity(acc3);

            insert new List<Opportunity>{opp1, opp2, opp3};

            Objective_Opportunity_Relationship__c oor1 = new Objective_Opportunity_Relationship__c(Opportunity__c = opp1.Id, Account_Plan_Objective__c = objObjective1.Id,Account_Plan__c = accPlan.Id);
            Objective_Opportunity_Relationship__c oor2 = new Objective_Opportunity_Relationship__c(Opportunity__c = opp1.Id, Plan_Objective__c = objPlanObjective.Id, Plan__c = objPlan.Id);

            insert new List<Objective_Opportunity_Relationship__c>{oor1, oor2};
        }
    }

    /*
    *@author: Adyasha
    *@Desc: Method to test fetching list of opportunities for Objectives
    */
    @isTest
    static void testFetchAssociatedOpportunities()
    {
        Set<String> setPlanObjectiveName = new Set<String>{INDIRECT_PLAN_OBJECTIVE,OVERLAY_PLAN_OBJECTIVE};
        List<Plan_Objective__c> lstPlanObjective = [SELECT Id,Plan_Strategy__r.Plan__c FROM Plan_Objective__c WHERE Name IN: setPlanObjectiveName];
        Objective__c  objObjective = [SELECT Id,Account_Plan__c from Objective__c LIMIT 1];
        Opportunity objOpportunity = [SELECT Id FROM Opportunity WHERE Name =: OPPORTUNITY_NAME];
        Account objAccount = [SELECT Id from Account LIMIT 1];
        
        Test.startTest();

        String strReturnValue1 = PlanAssociatedOpportunitiesController.fetchAssociatedOpportunities(lstPlanObjective[0].Plan_Strategy__r.Plan__c,lstPlanObjective[0].Id, Label.UI_Label_Objective_API);
        String strReturnValue2 = PlanAssociatedOpportunitiesController.fetchAssociatedOpportunities(objObjective.Account_Plan__c,objObjective.Id, 'Objective__c');
        PlanAssociatedOpportunitiesController.fetchOpportunitiesToDisplay(lstPlanObjective[1].Plan_Strategy__r.Plan__c,Label.UI_Label_Objective_API,new List<Id>{objAccount.Id});

        Test.stopTest();
        System.assert(strReturnValue1.contains(objOpportunity.Id),'');
        System.assert(strReturnValue2.contains(objOpportunity.Id),'');
    }
    
    /*
    *@author: Adyasha
    *@Desc: Method to test deleting assosciated opportunities with Objectives
    */
    @isTest
    static void testDeleteAssociatedOpportunities()
    {
        Objective_Opportunity_Relationship__c  oor = [SELECT Id FROM Objective_Opportunity_Relationship__c LIMIT 1];
        Test.startTest();
        String strReturnValue = PlanAssociatedOpportunitiesController.deleteAssociatedOpportunities(new List<String>{oor.Id});
        Test.stopTest();
        System.assert(strReturnValue.contains(Label.UI_Message_OOR_Delete.replace('{0}','1')),'Error in deleting Junction object record');
    }

    /*
    *@author: Adyasha
    *@Desc: Method to test assosciating opportunities with Objectives
    */
    @isTest
    static void testAddAssociatedOpportunities()
    {
        Objective__c  objObjective = [SELECT Id, Account_Plan__c from Objective__c LIMIT 1];
        Opportunity objOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Objective_Opportunity_Relationship__c oor = [SELECT Id FROM Objective_Opportunity_Relationship__c WHERE Account_Plan__c = null LIMIT 1];
        ObjectiveOpportunityRelationshipSelector selector = new ObjectiveOpportunityRelationshipSelector();
        Test.startTest();

        String strPayload = '[{"Opportunity__c":'+'"'+objOpportunity.Id+'",'
                            +'"Account_Plan_Objective__c":'+'"'+objObjective.Id+'",'
                            +'"Account_Plan__c":'+'"'+objObjective.Account_Plan__c+'"}]';
        String strReturnValue = PlanAssociatedOpportunitiesController.addAssociatedOpportunities(strPayload);

        selector.getSObjectType();
        selector.getSObjectFieldList();

        Test.stopTest();

        System.assert(strReturnValue.contains(Label.UI_Message_OOR_Create.replace('{0}','1')),'Error in creating Junction object record');

        
        List<Objective_Opportunity_Relationship__Share> lstShareRecords = [
            SELECT AccessLevel ,UserOrGroupId, UserOrGroup.Name 
            FROM Objective_Opportunity_Relationship__Share 
            WHERE ParentId = :oor.Id
            AND RowCause='Manual'
        ];
        
        System.assert(!lstShareRecords.isEmpty(),'Share records not created via Plan Sharing Model');
        System.assertEquals(5,lstShareRecords.size(),'Incorrect number Share records created');

    }

    /**
    *    @author Adyasha
    *    @date   2021-12-06
    *    @description Method for retrieving Territory
    */
    public static Territory2 getTerritory()
    {
        List<Territory2Model> lstModels = [SELECT ID,Name,(SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c FROM Territory2s where Territory2Type.DeveloperName = 'Territory') 
                                           FROM Territory2Model WHERE State='Active'];
        
        System.assert(!lstModels.isEmpty(),'Territory Model needs to be set up first and activated!');
        
        Territory2Model objTerritoryModel = lstModels.get(0);
        
        System.assert(!objTerritoryModel.Territory2s.isEmpty(),'Territory needs to be set up first!');
        
        return objTerritoryModel.Territory2s.get(0);        
    }

    static Territory2 getIndirectTerritory()
    {
        List<Territory2> lstTerritories = [
            SELECT ID,Name,Territory_Code__c
            FROM Territory2 
            WHERE Territory2Type.DeveloperName = 'District_Channel_Partner' 
            AND Territory2Model.State='Active'                                                        
            LIMIT 1
        ];
        System.assertEquals(1,lstTerritories.size(),'No Territories found');
        return lstTerritories[0];
    }
}
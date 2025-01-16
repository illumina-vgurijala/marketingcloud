/**
 *    @author KD
 *    @date   26-Aug-2020
 *    @description  Test class for ViewTerritoryPlansController Controller
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
 *   
*    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestViewTerritoryPlansController {
    static Territory2 getTerritory(){
        List<Territory2> lstTerritories = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
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
    @testSetup
    static void setupData(){
        Territory2 objTr = getTerritory();
        Set<Id> setOverlayUsers = new Set<Id>();
        for(UserTerritory2Association objUTA : [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.ParentTerritory2Id])
            setOverlayUsers.add(objUTA.UserId);
        if(setOverlayUsers.isEmpty()){
            insert TestDataUserTerritory2Association.getUserAssociation(objTr.ParentTerritory2Id,getAdminUser().Id);
        }
    }
    @isTest
    static void testDetailsFetch(){
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Territory' ];
        List<UserTerritory2Association> lstOverLayUsers = [SELECT UserId,Territory2Id,Territory2.Name FROM UserTerritory2Association WHERE Territory2Id = :objTr.ParentTerritory2Id];
        Plan__c objOverlayPlan = TestDataPlan.getOverlayPlan('');
        objOverlayPlan.Name='Parent Territory';
        objOverlayPlan.OwnerId=lstOverLayUsers[0].UserId;
        Plan__c objTPlan = TestDataPlan.getPlan(objTr.id);
        objTPlan.Name='Territory Plan 1';
        objTPlan.Status__c = 'Active';
        objTPlan.Territory_Code__c = objTr.Territory_Code__c;
        Plan__c objTPlan1 = TestDataPlan.getPlan(objTr.id);
        objTPlan1.Name='Territory Plan 1';
        objTPlan1.Status__c = 'Active';
        objTPlan1.Territory_Code__c = objTr.Territory_Code__c;
        System.Debug('COde in test -->'+objTr.Territory_Code__c);
        insert new List<Plan__c>{objOverlayPlan,objTPlan1,objTPlan};
        String strRetJSON = ViewTerritoryPlansController.initRecords(objOverlayPlan.Id);
        List<ViewTerritoryPlansController.PlanWrapper> lstPlanWrap = (List<ViewTerritoryPlansController.PlanWrapper>)JSON.deserialize(strRetJSON,List<ViewTerritoryPlansController.PlanWrapper>.class);
        System.assertEquals(2,lstPlanWrap.size(),'Incorrect number of Plan found : '+lstPlanWrap.size());

    }
    @isTest
    static void testException(){
        Plan__c objOverlayPlan = TestDataPlan.getOverlayPlan('');
        objOverlayPlan.Name='Parent Territory';
        objOverlayPlan.OwnerId=getAdminUser().Id;
        insert objOverlayPlan;
        try{
            ViewTerritoryPlansController.initRecords(objOverlayPlan.Id);
        }
        catch(Exception e){
            System.assertEquals('No Association Found',e.getMessage(),'Exception not fired');
        }
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
}
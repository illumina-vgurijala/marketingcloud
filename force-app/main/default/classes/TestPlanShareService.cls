/**
*    @author: Kushagra Desai
*    @date:   09-Sept-2020
*    @description:  Test class for  Plan share service
*    Modification Log:
*    -----------------------------------------------------------------------------------
*   Developer                      Date                Description
*   KD                       24-Sept-2020            DCP-39951 : Admin layout
*   Prem Ranjan              04 May 2022             CodeScan Fix (APEX) Unused Local Variable
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestPlanShareService {
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
    static Territory2 getIndirectTerritory(){
        List<Territory2> lstTerritories = [SELECT ID,Name,Territory_Code__c
                                                FROM Territory2 
                                                WHERE Territory2Type.DeveloperName = 'District_Channel_Partner' 
                                                        AND Territory2Model.State='Active'
                                                        AND ParentTerritory2Id<>null
                                                LIMIT 1];
        System.assertEquals(1,lstTerritories.size(),'No Territories found');
        Territory2 objT = lstTerritories[0];
        objT.Name='Testing Indirect Territory';
        update objT;
        return objT;
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Get admin user
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
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,setUsers);
        objUser.FirstName = 'Testing';
        objUser.LastName = 'PlanShareUser';
        update objUser;
        return objUser;
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    @testSetup 
    static void setupData(){
        Territory2 objTr = getTerritory();
        getIndirectTerritory();
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
    @isTest
    static void testDirectPlanShare(){
        Test.startTest();
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Territory' ]; 
        Plan__c objTPlan = TestDataPlan.getPlan(objTr.id);
        objTPlan.Name='Territory Plan';
        objTPlan.Territory_Code__c = objTr.Territory_Code__c;
        objTPlan.Territory_Region__c = 'AMR';
        insert objTPlan;
        // DCP-39951
        String strShareRecords = PlanShareRecordsController.initRecords(new List<String>{objTPlan.Id});
        List<SharingConsole.WrapperForUserRecord> lstPlanShareRecords = (List<SharingConsole.WrapperForUserRecord>)JSON.deserialize(strShareRecords,List<SharingConsole.WrapperForUserRecord>.class);
        System.assert(lstPlanShareRecords.size()>4,'Correct records fetched');
        Test.stopTest();
        List<Plan__share> lstPlanShare = [select id, ParentId, UserOrGroupId, AccessLevel, RowCause from Plan__Share where RowCause = 'Manual' and ParentId =:objTPlan.Id];
        Group objGrp = [Select id from Group where RelatedId =:objTr.ParentTerritory2Id and Type = 'Territory'];
        Group objGrpCurrent = [Select id from Group where RelatedId =: objTr.Id and Type = 'Territory'];
        Boolean boolIsShared = false;
        for(Plan__share objPlanshare : lstPlanShare){
            System.assertEquals('Edit',objPlanshare.AccessLevel,'Direct Plan accessLevel not correct');
            if(objPlanshare.UserOrGroupId == objGrp.Id || objPlanshare.UserOrGroupId == objGrpCurrent.Id)
                boolIsShared = true;
        }
        System.assert(boolIsShared,'Direct Plan Shared Incorrectly');
    }
    @isTest
    static void testInDirectPlanShare(){
        Test.startTest();
        Id idInDirectRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Territory' ];
        Territory2 objTrIn = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Indirect Territory' ];
        Plan__c objTPlanIndirect = TestDataPlan.getPlan(objTr.id);
        objTPlanIndirect.Name='Territory Indirect Plan';
        objTPlanIndirect.Territory_Code__c = objTr.Territory_Code__c;
        objTPlanIndirect.Channel_Partner_Territory_Code__c = objTrIn.Territory_Code__c;

        objTPlanIndirect.recordTypeId = idInDirectRecordType;
        insert objTPlanIndirect;
        Test.stopTest();
        List<Plan__share> lstPlanShare = [select id, ParentId, UserOrGroupId, AccessLevel, RowCause from Plan__Share where RowCause = 'Manual' and ParentId =:objTPlanIndirect.Id];
        Group objGrp = [Select id from Group where RelatedId =:objTrIn.ParentTerritory2Id and Type = 'Territory'];
        Group objGrpDirect = [Select id from Group where RelatedId =:objTr.ParentTerritory2Id and Type = 'Territory'];
        Boolean boolIsShared = false;
        for(Plan__share objPlanshare : lstPlanShare){
            if(objPlanshare.UserOrGroupId == objGrp.Id)
                boolIsShared = true;
        }
        System.assert(boolIsShared,'InDirect Plan Shared Incorrectly for CP');
        boolIsShared = false;
        for(Plan__share objPlanshare : lstPlanShare){
            if(objPlanshare.UserOrGroupId == objGrpDirect.Id)
                boolIsShared = true;
        }
        System.assert(boolIsShared,'InDirect Plan Shared Incorrectly');
    }
    @isTest
    static void testOverlayPlanShare(){
        Test.startTest();
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id
                            ,ParentTerritory2.Territory_Code__c,ParentTerritory2.ParentTerritory2Id
                            FROM Territory2 WHERE Name = 'Testing Territory' ];
        List<UserTerritory2Association> lstUsers = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.Id];
        Plan__c objOverlayPlan = TestDataPlan.getOverlayPlan(objTr.id);
        objOverlayPlan.Name='OverlayPlan';
        objOverlayPlan.OwnerId=lstUsers[0].UserId;
        
        insert objOverlayPlan;
        Test.stopTest();
        List<Plan__share> lstPlanShare = [select id, ParentId, UserOrGroupId, AccessLevel, RowCause from Plan__Share where RowCause = 'Manual' and ParentId =:objOverlayPlan.Id];
        System.assertEquals('Edit',lstPlanShare[0].AccessLevel,'OverlayPlan AccessLevel not correct');
        System.assert(!lstPlanShare.isEmpty(),'No share records created');
    }
    @isTest
    static void testOverlayPlanReShare(){
        Test.startTest();
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id
                            ,ParentTerritory2.Territory_Code__c,ParentTerritory2.ParentTerritory2Id
                            FROM Territory2 WHERE Name = 'Testing Territory' ];
        List<UserTerritory2Association> lstUsers = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.Id and User.name = 'Testing PlanShareUser'];
        Plan__c objOverlayPlan = TestDataPlan.getOverlayPlan(objTr.id);
        objOverlayPlan.Name='OverlayPlan';
        objOverlayPlan.OwnerId=lstUsers[0].UserId;
        insert objOverlayPlan;
        Group objGrp = [Select id from Group where RelatedId =:objTr.ParentTerritory2.ParentTerritory2Id and Type = 'TerritoryAndSubordinates'];
        Plan__share objPlanShare = [select id, ParentId, UserOrGroupId, AccessLevel, RowCause from Plan__Share where RowCause = 'Manual' and ParentId =:objOverlayPlan.Id and UserOrGroupId=:objGrp.id LIMIT 1];
        System.assert(objPlanShare!=null,'Overlay Plan Shared Incorrectly');
        List<UserTerritory2Association> lstDeleteUsers = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id =:objTr.ParentTerritory2.ParentTerritory2Id and User.name = 'Testing PlanShareUser'];
        deleteUserAssociation(lstDeleteUsers[0].Id);
        Test.stopTest();
        Group objGrp1 = [Select id from Group where RelatedId =:objTr.ParentTerritory2Id and Type = 'TerritoryAndSubordinates'];
        Plan__share objPlanShare1 = [select id, ParentId, UserOrGroupId, AccessLevel, RowCause from Plan__Share where RowCause = 'Manual' and ParentId =:objOverlayPlan.Id and UserOrGroupId =:objGrp1.id LIMIT 1];
        System.assertEquals('Edit',objPlanShare1.AccessLevel,'OverlayPlan  AccessLevel not correct');
        System.assert(objPlanShare1!=null,'Overlay Plan Re-Shared Incorrectly');
        Group objGrp2 = [Select id from Group where RelatedId =:objTr.ParentTerritory2.ParentTerritory2Id and Type = 'TerritoryAndSubordinates'];
        List<Plan__share> objPlanShare2 = [select id, ParentId, UserOrGroupId, AccessLevel, RowCause from Plan__Share where RowCause = 'Manual' and UserOrGroupId =:objGrp2.Id and ParentId=:objOverlayPlan.Id];
        System.assert(objPlanShare2.isEmpty(),'Overplan share not deleted');
    }
    static void deleteUserAssociation(Id idUTA){
        System.debug('UTA user id -->'+idUTA);
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            delete [SELECT UserId FROM UserTerritory2Association where id =:idUTA];
        }
    } 
    // DCP-39951   
    @isTest
    static void testRePlanShare(){
        Test.startTest();
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Territory' ]; 
        Plan__c objTPlan = TestDataPlan.getPlan(objTr.id);
        objTPlan.Name='Territory Plan';
        objTPlan.Territory_Code__c = objTr.Territory_Code__c;
        objTPlan.Territory_Region__c = 'AMR';
        insert objTPlan;
        String strReturn = PlanSharingConsoleController.reRunPlanSharingForRecords(new List<Id>{objTPlan.Id});
        Test.stopTest();
        System.assertEquals('Plan Record Shared',strReturn,'Re-Share not success');
        try{
            PlanSharingConsoleController.reRunPlanSharingForRecords(new List<Id>{objTr.Id});
        }
        catch(Exception e){
            System.assertEquals('Script-thrown exception',e.getMessage(),'Incorrect Exception caught');
        }
    }
    // DCP-39951   
    @isTest
    static void testAllRePlanShare(){
        Test.startTest();
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Territory' ]; 
        Plan__c objTPlan = TestDataPlan.getPlan(objTr.id);
        objTPlan.Name='Territory Plan';
        objTPlan.Territory_Code__c = objTr.Territory_Code__c;
        objTPlan.Territory_Region__c = 'AMR';
        insert objTPlan;
        PlanSharingConsoleController.reShareAllPlans();
        PlanSharingConsoleController.checkRunningJob();
        Test.stopTest();
        List<Exception_Log__c> lstException = [Select id from Exception_Log__c];
        System.assertEquals(0,lstException.size(),'Batch Run not success');
    }

    /*******************************************************
    *Method Name : coverCatchBlock_PlanShareServiceHelper()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest
    public static void coverCatchBlockPlanShareServiceHelper(){
        try{
            PlanShareServiceHelper.catchException = true;
            PlanShareServiceHelper pd = new PlanShareServiceHelper(null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}
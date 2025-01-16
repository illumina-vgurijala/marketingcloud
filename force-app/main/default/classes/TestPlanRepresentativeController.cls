/**
 *    @author Kushagra Desai
 *    @date   11-Aug-2020
 *    @description  Test class for PlanRepresentativeController.
 *
 * 
 * 
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
*    Akshay Mohan                   12-Aug-2020         Changes for DCP-39673: Manage Users
*    Akshay Mohan                   18-Aug-2020         Changes for DCP-39966: Cascade Hierarchy for Add Users
*    KD                             14-Sept             DCP-40041 : Notify Overlay user for Plan creation
*    Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    Nishan Shetty                  13-Sept-2022        DCP-56402 CodeScan Issue Fix.
*    Vishal Reddy                   3-Oct-2022          Added code coverage for getAllUsers method
*    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestPlanRepresentativeController {
    public static final String ROLE_CODE_PARAMETER = 'Plan_DefaultUserRole';
    public static final String CPROLE_CODE_PARAMETER = 'Plan_CPUsers';
    public static final String ROLE_DELIMITER = ';';

    static Territory2 getTerritory() {//DCP-56402
        List<Territory2> lstTerritories = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                                                FROM Territory2 
                                                WHERE Territory2Type.DeveloperName = 'Territory' 
                                                        AND Territory2Model.State='Active'
                                                        AND ParentTerritory2Id<>null
                                                LIMIT 1];
        System.assertEquals(1,lstTerritories.size(),'No Territories found');
        System.debug('lstTerritories: ' +lstTerritories);
        //Territory Record
        Territory2 objT = lstTerritories[0];
        objT.Name='Testing Territory';
        update objT;
        return objT;
    }
    /*
    *
    *@author: Kushagra Desai
    *@Desc: Test setup method
    *[DCP-56402-CodeScan Fixes]
    *
    */
    @testSetup 
    static void setupData() {//DCP-56402
        createETMData();     
    }
    /*
    *
    *@author: Satya Swain
    *@Desc: created to avoid mixed DML for DCP-43261/TASK0548217
    *[DCP-56402-CodeScan Fixes]
    */
    static void createETMData() {//DCP-56402
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser) {//DCP-56402
            Territory2 objTr = getTerritory();
            Set<Id> setFoundUsers = new Set<Id>();
            for(UserTerritory2Association objUTA : [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.Id]) {//DCP-56402
                setFoundUsers.add(objUTA.Id);
            }
            if(setFoundUsers.size()<3) {//DCP-56402
                List<UserTerritory2Association> lstUTA = new List<UserTerritory2Association>();
                //User Creation
                User objUsr = setFoundUsers.isEmpty()?TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP):TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP,setFoundUsers); 
                setFoundUsers.add(objUsr.Id);
                //UserTerritoryAssociation Creation.
                lstUTA.add(TestDataUserTerritory2Association.getUserAssociation(objTr.Id,objUsr.Id));
                objUsr = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP,setFoundUsers); 
                setFoundUsers.add(objUsr.Id);
                lstUTA.add(TestDataUserTerritory2Association.getUserAssociation(objTr.Id,objUsr.Id));
                objUsr = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP,setFoundUsers); 
                setFoundUsers.add(objUsr.Id);
                lstUTA.add(TestDataUserTerritory2Association.getUserAssociation(objTr.Id,objUsr.Id));
                insert lstUTA;
            }
            List<String> lstDefaultRole = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{PlanRepresentativeController.ROLE_CODE_PARAMETER})[0].value__c.split(PlanRepresentativeController.ROLE_DELIMITER);
            if([SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.ParentTerritory2Id AND RoleInTerritory2 IN :lstDefaultRole].size()<2) {//DCP-56402
                for(UserTerritory2Association objUTA : [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.ParentTerritory2Id]) {//DCP-56402
                    setFoundUsers.add(objUTA.Id);
                }
                List<UserTerritory2Association> lstUTA = new List<UserTerritory2Association>();
                //User Creation
                User objUsr = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP,setFoundUsers);
                setFoundUsers.add(objUsr.Id); 
                //User Territory Association Creation.
                lstUTA.add(TestDataUserTerritory2Association.getUserAssociationwithRole(objTr.ParentTerritory2Id,objUsr.Id,lstDefaultRole[0]));
                
                //DCP-39966 add test data
                objUsr = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP,setFoundUsers);
                setFoundUsers.add(objUsr.Id);
                lstUTA.add(TestDataUserTerritory2Association.getUserAssociation(objTr.ParentTerritory2Id,objUsr.Id));
                insert lstUTA;
            }
        }
    }

     /*
    *
    *@author: 
    *@Desc: Test Fetch Details.
    *[DCP-56402-CodeScan Fixes]
    */
    @isTest
    static void testDetailsFetch() {//DCP-56402
        List<String> lstDefaultRole = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{PlanRepresentativeController.ROLE_CODE_PARAMETER})[0].value__c.split(PlanRepresentativeController.ROLE_DELIMITER);
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Territory' ];
        List<UserTerritory2Association> lstUsers = [SELECT UserId FROM UserTerritory2Association WHERE Territory2Id = :objTr.Id];
        List<UserTerritory2Association> lstParentUsers = [SELECT UserId FROM UserTerritory2Association 
                                                            WHERE Territory2Id = :objTr.ParentTerritory2Id
                                                                AND RoleInTerritory2 NOT IN :lstDefaultRole];
       //Plan Creation.
        Plan__c objOverlayPlan = TestDataPlan.getOverlayPlan(objTr.id);
        objOverlayPlan.Name='Same Territory';
        objOverlayPlan.Territory_Code__c = objTr.Territory_Code__c;
        objOverlayPlan.OwnerId=lstUsers[0].UserId;
        
        Plan__c objParentOverlayPlan = TestDataPlan.getOverlayPlan(objTr.ParentTerritory2Id);
        objParentOverlayPlan.Name = 'Parent Plan';
        objParentOverlayPlan.OwnerId = lstParentUsers[0].UserId;
        objParentOverlayPlan.Territory_Code__c = objTr.ParentTerritory2.Territory_Code__c;

        Plan__c objTPlan = TestDataPlan.getPlan(objTr.id);
        objTPlan.Name='Territory Plan';
        objTPlan.Territory_Code__c = objTr.Territory_Code__c;
        
        insert new List<Plan__c>{objOverlayPlan,objParentOverlayPlan,objTPlan};
        
        Test.startTest();
        String strJSON = PlanRepresentativeController.initRecords(objTPlan.Id);
        // DCP-40041
        PlanRepresentativeController.notifyOverlayUser(objTPlan.Id,lstUsers[0].UserId);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, invocations, 'An email has not been sent');
        List<PlanRepresentativeController.UserPlanAssociation> lstPlanReps = (List<PlanRepresentativeController.UserPlanAssociation>)JSON.deserialize(UtilsObject.getJSONPart(strJSON,'{"lstUserTerritory2AssociationWrap": ', ', "mapLabels":'),List<PlanRepresentativeController.UserPlanAssociation>.class);
        //DCP-39966 change assert
        System.assert(lstPlanReps.size()>=3,'Incorrect Reps fetched: '+lstPlanReps.size());
    }


     /*
    *
    *@author: 
    *@Desc: Test Manage User Flow.
    *[DCP-56402-CodeScan Fixes]
    */
    @isTest
    static void testManageUserFlow() {//DCP-56402

        List<String> lstDefaultRole = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{PlanRepresentativeController.ROLE_CODE_PARAMETER})[0].value__c.split(PlanRepresentativeController.ROLE_DELIMITER);
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Territory' ];
        List<UserTerritory2Association> lstUsers = [SELECT UserId,RoleInTerritory2,User.Name FROM UserTerritory2Association WHERE Territory2Id = :objTr.Id];//DCP-56402
        System.debug('lstUsers: '+ lstUsers);
        List<UserTerritory2Association> lstDefaultParentUsers = [SELECT UserId FROM UserTerritory2Association 
                                                            WHERE Territory2Id = :objTr.ParentTerritory2Id
                                                                AND RoleInTerritory2 IN :lstDefaultRole];
        System.debug('lstDefaultParentUsers: '+ lstDefaultParentUsers);
        //Plan Record Creation
        Plan__c objOverlayPlan = TestDataPlan.getOverlayPlan(objTr.id);
        objOverlayPlan.Name='Same Territory';
        objOverlayPlan.Territory_Code__c = objTr.Territory_Code__c;
        objOverlayPlan.OwnerId=lstUsers[0].UserId;
        
        Plan__c objParentOverlayPlan = TestDataPlan.getOverlayPlan(objTr.ParentTerritory2Id);
        objParentOverlayPlan.Name = 'Parent Plan';
        objParentOverlayPlan.OwnerId = lstDefaultParentUsers[0].UserId;
        objParentOverlayPlan.Territory_Code__c = objTr.ParentTerritory2.Territory_Code__c;

        Plan__c objTPlan = TestDataPlan.getPlan(objTr.id);
        objTPlan.Name='Territory Plan';
        objTPlan.Territory_Code__c = objTr.Territory_Code__c;

        Account channelPartner = TestDataAccount.getNewPartnerAccount('test');
        objTPlan.Channel_Partner__c = channelPartner.id;
        
        
        insert new List<Plan__c>{objOverlayPlan,objParentOverlayPlan,objTPlan};
        //Plan Representative Creation
        Plan_Representative_Association__c objPRA = new Plan_Representative_Association__c(User__c=lstUsers[0].UserId,Territory_Plan__c=objTPlan.Id,Is_Removed__c=true);
        Plan_Representative_Association__c objPRARem = new Plan_Representative_Association__c(User__c=lstDefaultParentUsers[0].UserId,Territory_Plan__c=objTPlan.Id,Is_Removed__c=true);
        insert new List<Plan_Representative_Association__c>{objPRA,objPRARem};

        Test.startTest();
        String strJSON = PlanRepresentativeController.getAddUsers(objTPlan.id);
        List<PlanRepresentativeController.UserAssociation> lstUsersWrap = (List<PlanRepresentativeController.UserAssociation>)JSON.deserialize(strJSON,List<PlanRepresentativeController.UserAssociation>.class);
        //DCP-39966 change assert count
        System.assert(lstUsersWrap.size()>=4,'Incorrect number of users found for addition: '+lstUsersWrap.size());
        List<PlanRepresentativeController.UserAssociation> lstUsersWrap2 = new List<PlanRepresentativeController.UserAssociation>();
        for(PlanRepresentativeController.UserAssociation wrapUA : lstUsersWrap) {//DCP-56402
            if(wrapUA.strUserId!=lstDefaultParentUsers[0].UserId) {//DCP-56402
               lstUsersWrap2.add(wrapUA);
            }
        }
        //Check add
        System.debug('lstUsersWrap2: ' +lstUsersWrap2);
        PlanRepresentativeController.addUsers(JSON.serialize(lstUsersWrap2),objTPlan.id);
        System.assertEquals(0,[Select Id FROM Plan_Representative_Association__c WHERE ID=:objPRA.Id].size(),'Add scenario: Association Record not deleted');
        System.assert([Select Id FROM Plan_Representative_Association__c WHERE Territory_Plan__c=:objTPlan.Id AND Is_Removed__c=false].size()>=2,'Add scenario: Association Record not created properly');
        System.assertEquals(1,[Select Id FROM Plan_Representative_Association__c WHERE Territory_Plan__c=:objTPlan.Id AND Is_Removed__c=true].size(),'Add scenario: Association Record deleted incorrectly');
        
        //Check remove
        lstUsersWrap = new List<PlanRepresentativeController.UserAssociation>();
        PlanRepresentativeController.UserAssociation wrapUser = new PlanRepresentativeController.UserAssociation(lstUsers.get(0));//DCP-56402
        lstUsersWrap.add(wrapUser);
        wrapUser = new PlanRepresentativeController.UserAssociation(lstUsers.get(1));//DCP-56402
        lstUsersWrap.add(wrapUser);
        System.debug('Removal Users: ' + lstUsersWrap);
        PlanRepresentativeController.removeUsers(JSON.serialize(lstUsersWrap),objTPlan.id);
        Test.stopTest();
        System.assert([Select Id FROM Plan_Representative_Association__c WHERE Territory_Plan__c=:objTPlan.Id AND Is_Removed__c=false].size()>=1,'Remove scenario: Association Record not deleted properly');
        System.assertEquals(2,[Select Id FROM Plan_Representative_Association__c WHERE Territory_Plan__c=:objTPlan.Id AND Is_Removed__c=true].size(),'Remove scenario: Association Record not created properly');
    }

    /*
    *@author: Vishal Reddy
    *@Desc: Test method for getAllUsers()
    */

    @isTest
    static void testGetAllUsers(){
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
        FROM Territory2 WHERE Name = 'Testing Territory' ];
        Plan__c objTPlan = TestDataPlan.getPlan(objTr.id);
        objTPlan.Name='Territory Plan';
        objTPlan.Territory_Code__c = objTr.Territory_Code__c;
        Account channelPartner = TestDataAccount.getNewPartnerAccount('test');
        objTPlan.Channel_Partner__c = channelPartner.id;
        insert new List<Plan__c>{objTPlan};
        Test.startTest();
        PlanRepresentativeController.getAllUsers(objTPlan.Channel_Partner__c);
        System.assert(objTPlan.Channel_Partner__c != null, 'channel partner is not null');
        Test.stopTest();

    }

    /*
    *@author: Vishal Reddy
    *@Desc: Test method for exceptions
    */

    @isTest
    static void testExceptions(){
        Territory2 objTr = [SELECT ID,Name,Territory_Code__c,Territory2Type.DeveloperName,ParentTerritory2Id,ParentTerritory2.Territory_Code__c 
                            FROM Territory2 WHERE Name = 'Testing Territory' ];
        Plan__c objTPlan = TestDataPlan.getPlan(objTr.id);
        objTPlan.Name='Territory Plan';
        objTPlan.Territory_Code__c = objTr.Territory_Code__c;

        insert new List<Plan__c>{objTPlan};
        
        Test.startTest();
        try{
            PlanRepresentativeController.catchException = true;
            PlanRepresentativeController.initRecords(objTPlan.Id);
            System.assert(!PlanRepresentativeController.catchException, 'catchException is now false');
        }
        catch(Exception e){
            System.debug('Error : '+ e.getMessage());
        }

        try{
            PlanRepresentativeController.catchException = true;
            PlanRepresentativeController.getAddUsers(objTPlan.id);
            System.assert(!PlanRepresentativeController.catchException, 'catchException is now false');
        }
        catch(Exception e){
            System.debug('Error : '+ e.getMessage());
        }

        try{
            PlanRepresentativeController.catchException = true;
            PlanRepresentativeController.addUsers('testException',objTPlan.id);
        }
        catch(Exception e){
            System.debug('Error : '+ e.getMessage());
        }

        try{
            PlanRepresentativeController.catchException = true;
            PlanRepresentativeController.removeUsers('TestException',objTPlan.id);
        }
        catch(Exception e){
            System.debug('Error : '+ e.getMessage());
        }

        try{
            PlanRepresentativeController.catchException = true;
            PlanRepresentativeController.notifyOverlayUser('TestException', 'testuserid');
        }
        catch(Exception e){
            System.debug('Error : '+ e.getMessage());
        }

        try{
            PlanRepresentativeController.catchException = true;
            PlanRepresentativeController.getAllUsers('testchannelpartner');
        }
        catch(Exception e){
            System.debug('Error : '+ e.getMessage());
        }

        Test.stopTest();
        
    }

}

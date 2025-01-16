/**
 *    @author Kushagra Desai
 *    @date   28-July-2020
 *    @description  Test class for Plan Creation Controller
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *   Developer                      Date                         Description
 *   KD                           3-Sept-2020                   DCP-39735 : Automation of channel partner  
 *   Anisha Bharti                07-Sept-2020                  DCP-40497 : updated plan recordtype API name
 *   KD                           17-Sept                                      DCP-39967 : Plan CLone
 *   Satya                        04 Jan 2020                   DCP-43261/TASK0548217 : TAPS enhancements  
 *   Ashwin Kumar                 31-Mar-2021                   DCP-52339 Remove TestTAPS.setupDeferredObjectData
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestPlanCreationController {
    public static Territory2 objTr1 = new Territory2();
    public static final string STRING_LITERAL_1 = '{"lstUserTerritory2Association": ';
    public static final string STRING_LITERAL_2 = ', "mapLabels":';
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    //  DCP-39735 : Automation of channel partner
    @testSetup 
    static void setupData(){
        setupAllData();    
    }
    static void setupAllData(){
        User objAdminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objAdminUser){
            objTr1 = getTerritory();
            Account acc = TestDataAccount.initAccount();
            acc.ERP_Customer_Id__c = '123456';
            acc.Territory_Region__c = 'AMR';
            acc.Account_Group__c = 'Distributor';
            acc.Territory_Name__c = objTr1.Id;
            acc.Territory_Code__c = objTr1.Territory_Code__c;   
            Account acc2 = TestDataAccount.initAccount();
            List<Account> lstAcc = new List<Account>();
            lstAcc.add(acc);
            lstAcc.add(acc2);
            insert lstAcc;
            Contact con1 = TestDataPerson.initContact(acc.Id);
            insert con1;
            // DCP-40497
            List<Channel_Partner_Quota__c> lstQuota = new List<Channel_Partner_Quota__c>();
            Channel_Partner_Quota__c q1 = TestDataChannelPartnerQuota.getCPQuota(acc.id,'2020');
            q1.Quarter_1__c = 10;
            lstQuota.add(Q1);
            Channel_Partner_Quota__c q2 = TestDataChannelPartnerQuota.getCPQuota(acc.id,'2021');
            q2.Quarter_1__c = 10;
            lstQuota.add(q2);
            Channel_Partner_Quota__c q3 = TestDataChannelPartnerQuota.getCPQuota(acc.id,'2021');
            q3.Quarter_1__c = 20;
            lstQuota.add(q3);
            Channel_Partner_Quota__c q4 = TestDataChannelPartnerQuota.getCPQuota(acc.id,'2022');
            lstQuota.add(q4);
            Channel_Partner_Quota__c q5 = TestDataChannelPartnerQuota.getCPQuota(acc.id,'2023');
            q5.Quarter_1__c = 10;
            lstQuota.add(q5);
            insert lstQuota;
            TestDataUser.updateUserDetailsFuture(con1.Id,'TestPortalUserTP');
            TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr1.id,lstAcc[0].id);
        }
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    @isTest
    static void testFetchTerritoryAssigned(){
        User objAdminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        User objUsr = TestDataUser.findUserInProfile('Sales User');
        Territory2 objTr = getTerritory();
        String idOverlayRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.PlanOverlay).getRecordTypeId();
        String idDirectRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Direct).getRecordTypeId();
        List<UserTerritory2Association> lstOTA = [Select id from UserTerritory2Association where UserId =:objUsr.id and Territory2Id =: objTr.id];
        System.runAs(objAdminUser){
            if(lstOTA.isEmpty()){
                UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(objTr.id,objUsr.id);
                insert objUTA;
            }
        }
        Test.starttest();
        String strReturn = PlanCreationController.initRecords(objUsr.id, idOverlayRecordType,'' );
        system.debug('return-->'+strReturn);
        List<PlanCreationController.TerritoryWrapper> lstTerritory = (List<PlanCreationController.TerritoryWrapper>)
                    JSON.deserialize(UtilsObject.getJSONPart(strReturn,STRING_LITERAL_1, STRING_LITERAL_2), List<PlanCreationController.TerritoryWrapper>.class);
        System.debug('lstTerritory: '+ lstTerritory);
        System.assertEquals(0,lstTerritory.size(),'Territory size incorrect');
        
        String strReturn1 = PlanCreationController.initRecords(objUsr.id, idDirectRecordType,'');
        system.debug('return-->'+strReturn1);
        List<PlanCreationController.TerritoryWrapper> lstTerritory1 = (List<PlanCreationController.TerritoryWrapper>)
                    JSON.deserialize(UtilsObject.getJSONPart(strReturn1,STRING_LITERAL_1, STRING_LITERAL_2), List<PlanCreationController.TerritoryWrapper>.class);
        System.debug('lstTerritory1: '+ lstTerritory1);
        System.assert(lstTerritory1.size() > 0,'Incorrect number of Territory Returned');
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    //  DCP-39735 : Automation of channel partner
    @isTest
    static void testFetchTerritoryAssignedIndirect(){
        User objAdminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        User objUsr = TestDataUser.findUserInProfile('Sales User');
        Account acc = [Select id,Territory_Name__c from Account where ERP_Customer_Id__c = '123456' LIMIT 1];
         String idInDirectRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
        System.runAs(objAdminUser){
            List<UserTerritory2Association> lstOTA = [Select id from UserTerritory2Association where UserId =:objUsr.id and Territory2Id =: acc.Territory_Name__c];
            if(lstOTA.isEmpty()){
                UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(acc.Territory_Name__c,objUsr.id);
                insert objUTA;
            }
        }
        Test.starttest();
        String strReturn = PlanCreationController.initRecords(objUsr.id, idInDirectRecordType,'' );
        system.debug('return-->'+strReturn);
        List<PlanCreationController.TerritoryWrapper> lstTerritory = (List<PlanCreationController.TerritoryWrapper>)
                     JSON.deserialize(UtilsObject.getJSONPart(strReturn,STRING_LITERAL_1, STRING_LITERAL_2), List<PlanCreationController.TerritoryWrapper>.class);
        System.debug('lstTerritory: '+ lstTerritory);
        System.assert(lstTerritory.size() > 0,'No Territory Fetched');
        Map<String,List<PlanCreationController.AccountWrapper>> mapCodeToAccount = (Map<String,List<PlanCreationController.AccountWrapper>>)
                     JSON.deserialize(UtilsObject.getJSONPart(strReturn,'"mapAccountWrapper": ', ', "recordTypeID": "'), Map<String,List<PlanCreationController.AccountWrapper>>.class);
        System.assertEquals(1,mapCodeToAccount.keySet().size(),'No Account Fetched');
        Test.stoptest();
    }
    @isTest
    static void testFetchPageLayout(){
        RecordType objRecordType = [select id,SobjectType from RecordType where SobjectType='Plan__c' LIMIT 1];
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMockHTTP());
        String strReturn = PlanCreationController.loadPage(objRecordType.id);
        System.assert(strReturn.length() > 0,'Page Layout not fetched');
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    //  DCP-39735 : Automation of channel partner
    @isTest
    static void testCommunityTerritoryAssigned(){
        User objAdminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        User objUsr = [Select ContactId,Contact.AccountId,Contact.Account.Territory_Code__c from user where Name like 'TestPortalUserTP%'];
        Territory2 objTr = getTerritory();
        System.runAs(objAdminUser){
            List<UserTerritory2Association> lstOTA = [Select id from UserTerritory2Association where UserId =:objUsr.id and Territory2Id =: objTr.id];
            if(lstOTA.isEmpty()){
                UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(objTr.id,objUsr.id);
                insert objUTA;
            }
            List<PermissionSet> lstobjPS =  [select id,name from PermissionSet where name = 'CP_Plan'];
            if(lstobjPS.isEmpty()){
                PlanCreationController.boolIsTestRunning = true;
                String strReturn = PlanCreationController.initRecords(objUsr.id,'Community','Community');
                system.debug('Portal Prtal ->'+strReturn);
                List<PlanCreationController.TerritoryWrapper> lstTerritory = (List<PlanCreationController.TerritoryWrapper>)
                        JSON.deserialize(UtilsObject.getJSONPart(strReturn,STRING_LITERAL_1, STRING_LITERAL_2), List<PlanCreationController.TerritoryWrapper>.class);
                System.assertEquals(1,lstTerritory.size());
            }
            else{
                PermissionSet objPS = [select id,name from PermissionSet where name = 'CP_Plan' LIMIT 1];
                List<PermissionSetAssignment> lstPSA= [select id from PermissionSetAssignment where AssigneeId =:objUsr.id and PermissionSetId=:objPS.id];
                if(lstPSA.isEmpty()){
                    PermissionSetAssignment psa = new PermissionSetAssignment();
                    psa.AssigneeId = objUsr.id;
                    psa.PermissionSetId = objPS.Id;
                    insert psa;
                }
            }
            System.runAs(objUsr){
                String strReturn = PlanCreationController.initRecords(objUsr.id,'Community','Community');
                system.debug('Portal Prtal ->'+strReturn);                
                System.assert(!String.isEmpty(strReturn), 'result is written');
            }
        }
    }
    /*
    *@author: Kushagra Desai
    *@Desc: DCP-40495 : Automation of Plan Targer
    */
    @isTest
    static void testPlanTargetAutomation(){
        User objAdminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        User objUsr = TestDataUser.findUserInProfile('Sales User');
        Account acc = [Select id,Territory_Name__c,Territory_Code__c from Account where ERP_Customer_Id__c = '123456' LIMIT 1];
        String idInDirectRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
        System.runAs(objAdminUser){
            List<UserTerritory2Association> lstOTA = [Select id from UserTerritory2Association where UserId =:objUsr.id and Territory2Id =: acc.Territory_Name__c];
            if(lstOTA.isEmpty()){
                UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(acc.Territory_Name__c,objUsr.id);
                insert objUTA;
            }
        }
        Test.starttest();
        String strReturn = PlanCreationController.initRecords(objUsr.id, idInDirectRecordType, '');
        system.debug('testPlanTargetAutomation return-->'+strReturn);
        Map<String,List<PlanCreationController.AccountWrapper>> mapCodeToAccount = (Map<String,List<PlanCreationController.AccountWrapper>>)
                     JSON.deserialize(UtilsObject.getJSONPart(strReturn,'"mapAccountWrapper": ', ', "recordTypeID": "'), Map<String,List<PlanCreationController.AccountWrapper>>.class);
        Map<String,Decimal> mapYearToQuota = new Map<String,Decimal>();
        for(PlanCreationController.AccountWrapper objAccWrap : mapCodeToAccount.get(acc.Territory_Code__c)){
            if(objAccWrap.strAccountId == acc.id)
                mapYearToQuota = objAccWrap.mapAccountIdToFYQuota;
        }
        System.assertEquals(1,mapCodeToAccount.keySet().size(),'Incorrect Quota fetched');
        System.assert(!mapYearToQuota.containsKey('2022'),'Incorrect Quota year fetched');
        System.assertEquals(10,mapYearToQuota.get('2021'),'Incorrect Quota Value fetched');
    }
    /**
    *    @author KD
    *    @date   28-Jult-2020
    *    @description Method for retrieving Territory
    */
    public static Territory2 getTerritory(){
        List<Territory2Model> lstModels = [SELECT ID,Name,(SELECT ID,Name,Territory2Type.DeveloperName,Territory_Code__c FROM Territory2s where Territory2Type.DeveloperName = 'Territory') 
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
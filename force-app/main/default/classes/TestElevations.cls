/***************************************************************************************************************************************
* NAME   : TestElevations
* DESCRIPTION  : TestClass for Elevation Trigger
*     
* @AUTHOR : Deepika Ayyavari
* @DATE   : Dec-2021 
* Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Deepika Ayyavari              15-Dec-2021         Initial Version
*    Rohan Rathod                   30-May-2022        testElevationMemberForCategory added
*/

@isTest(SeeAllData = false)
public with sharing class TestElevations {
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String BUSINESS_ISSUE = 'Business Issue';
    
    /**
*  @author Deepika Ayyavari
*  @description - initialize test data
**/
    static testMethod void checkNotification(){
 
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test';
        ps.Label = 'Test';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'RPS_FSM_FAM'][0].Id;
        insert sea;
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;
            
        system.runas(new user(Id = userinfo.getUserid())){
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
            insert acc;
            
            //insert contact
            Contact con = TestDataPerson.getNewContact(acc.Id);
            System.assert(con.id != null, 'Contact should not be null');
            
            Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
            
            Case objCase  = new Case(    
                Status = 'Initiated',
                Subject = 'test' ,
                Description= 'test',
                Origin = 'Phone-CP',
                Date_of_Issue_Awareness__c=System.today() -2,
                ContactId = con.Id,
                Awareness_Date_Difference_Reason__c ='Logistical delay',
                RecordTypeId = idCaseRecordTypeId
            );
            insert objCase;
            Test.startTest();
            List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
            
            Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
            Id accountElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Account Elevation').getRecordTypeId();  
            
            SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                 SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                                 SVMXC__Order_Status__c from 
                                                 SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
            
            Elevations__c techElev = new Elevations__c();
            techElev.RecordTypeId = technicalElevationRecordType;
            techElev.Elevation_Category__c = 'Standard Technical';
            techElev.Elevation_Status__c = 'Open';
            techElev.Elevation_Owner__c = lstUsers[0].Id;
            techElev.Elevation_Manager__c = lstUsers[0].Id;
            techElev.Plan_of_Action__c = 'test';
            techElev.Work_Order__c = workOrder.Id;
            insert techElev;
            
            Elevations__c accElev = new Elevations__c();
            accElev.RecordTypeId = accountElevationRecordType;
            accElev.Elevation_Status__c = 'Open';
            accElev.Elevation_Owner__c = lstUsers[0].Id;
            accElev.Plan_of_Action__c = 'test';
            accElev.Work_Order__c = workOrder.id;
            insert accElev;
                      
            workOrder.Technical_Elevation__c = techElev.Id;
            workOrder.Account_Elevation__c = accElev.Id;
            update workOrder;
            
            techElev.Elevation_Owner__c = userinfo.getUserId();
            techElev.Elevation_Status__c = 'Closed - Actions Complete';
            Update techElev;
            
            techElev.Elevation_Status__c = 'Open';
            Update techElev;
            Test.stopTest();
        }
    }
    
/**
*  @author Rohan
*  @description - initialize test data
**/
    @IsTest(SeeAllData = false)
    static void testElevationMemberForCategory(){
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test';
        ps.Label = 'Test';
        insert ps;
        System.assertNotEquals(null, ps.id,'PermissionSet should not be null');
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'RPS_FSM_FAM'][0].Id;
        insert sea;
        System.assertNotEquals(null, sea.id,'SetupEntityAccess should not be null');
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;
        System.assertNotEquals(null, psa.id,'PermissionSetAssignment should not be null');
        User u = TestDataFieldService.createUser('System Administrator',false);
        Insert u;
        PermissionSet newPS = [SELECT Id FROM PermissionSet WHERE Name = 'SS_Product_Support'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = newPS.Id);

        System.runAs(u){
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
            insert acc;
            System.assertNotEquals(null, acc.id,'Account should not be null');
            //insert contact
            Contact con = TestDataPerson.getNewContact(acc.Id);
            System.assertNotEquals(null, con.id,'Contact should not be null');
            
            Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
            
            Case objCase  = new Case(    
                Status = 'Initiated',
                Subject = 'test' ,
                Description= 'test',
                Origin = 'Phone-CP',
                Date_of_Issue_Awareness__c=System.today() -2,
                ContactId = con.Id,
                Awareness_Date_Difference_Reason__c ='Logistical delay',
                RecordTypeId = idCaseRecordTypeId
            );
            insert objCase;
            System.assertNotEquals(null, objCase.Id, 'Case Object should not be empty');
            
            List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
                        
            Id accountElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Account Elevation').getRecordTypeId();  
            
            SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                 SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                                 SVMXC__Order_Status__c from 
                                                 SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];        
            
            Elevations__c accElev = new Elevations__c();
            accElev.RecordTypeId = accountElevationRecordType;
            accElev.Elevation_Category__c = 'Account Maintenance';
            accElev.Elevation_Status__c = 'Open';
            accElev.Elevation_Owner__c = lstUsers[0].Id;
            accElev.Elevation_Manager__c = lstUsers[0].Id;
            accElev.Plan_of_Action__c = 'test';
            accElev.Success_Criteria__c = 'TEST';
            accElev.Work_Order__c = workOrder.id;
            insert accElev;
            System.assertNotEquals(null, accElev.Id, 'Elevation Object should not be empty');   

            workOrder.Account_Elevation__c = accElev.Id;
            workOrder.Business_Impact_to_Customer__c = 'System Down';
            workOrder.Business_impact_to_Illumina__c = 'Instrument replacement';
            update workOrder;
            System.assertNotEquals(null, workOrder.Id, 'workOrder Object should not be empty');

            Related_Contacts__c rc = new Related_Contacts__c();
            rc.Elevated_Work_Order__c = workOrder.id;            
            rc.User__c=u.id;
            rc.Type__c = 'Watcher (Account)';
            rc.recordtypeid = Schema.SObjectType.Related_Contacts__c.getRecordTypeInfosByName().get('Elevation Member').getRecordTypeId();
            rc.Source__c = 'Flow';
            Insert rc;
            System.assertNotEquals(null, rc.Id, 'RC Object should not be empty');

            try{
                Test.startTest();
                accElev.Elevation_Category__c = 'Hot Site';
                update accElev;
                System.assertNotEquals(null, accElev.Id, 'Elevation should not be empty');
                Test.stopTest();
            }            
            catch(Exception e)
            {
                System.assert(e.getMessage().contains(system.label.Elevation_Category_Validaton_Message));
            }
        }                
    }
}
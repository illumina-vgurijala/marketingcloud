/***************************************************************************************************************************************
* NAME   : TestAccountToFieldSupports
* DESCRIPTION  : TestClass for AccountToFieldSupport Trigger
*          
*    
* @AUTHOR : Sandeep Ram Ch.
* @DATE   : 06-July-2018  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Sandeep Ram Ch.           06-July-2018             Initial Version
* Akash Kumar               01-Oct-2018              Added method for Insert Scenarios for Populate field service fields on Opportunity
* Akash Kumar               01-Oct-2018              Added method for Delete Scenarios for Populate field service fields on Opportunity
* Akash Kumar               01-Oct-2018              Added method for Update Scenarios for Populate field service fields on Opportunity
* Himanshu                  20-April-2022            Code Scan Fixes
* Parthasarathy D           10-Oct-2022              Codescan Fix - Added method level comments.
****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  
public with sharing class TestAccountToFieldSupports {
    
    static Case cs;
    static SVMXC__Service_Group__c serviceTeam;
    static Account acc;
    /*
    *  @author      : 
    *  @description : Method to create test data.
    *  @param       : 
    *  @return      : Void.
    */
    @testSetup
    public static void initializeTestData() {
        acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c= 'Distributor';
        insert acc;
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname' , AccountId = acc.Id);
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        List<User> lstUsers = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service
                               LIMIT 1];     
        serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c='b@b.com';
        insert technicianFAS;
    }
    
    /**
*    @author Akash Kumar
*    @date   2018-09-28
*    @description Insert Scenarios for Populate field service fields
*/ 
    static testMethod void updateFieldServicesFieldOnOpportunityOnInsert(){  
        
        SVMXC__Service_Group__c serviceTeam = [Select id from SVMXC__Service_Group__c];
        System.debug('serviceTeam' +serviceTeam);       
        SVMXC__Service_Group_Members__c technicianFAS = [Select id from SVMXC__Service_Group_Members__c];
        technicianFAS.SVMXC__Active__c = true;
        update technicianFAS; 
        
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        
        Account acc1 = TestDataAccount.getNewAccount();
        acc1.Account_Group__c = 'Distributor';
        
        Account acc2 = TestDataAccount.getNewAccount();
        acc2.Account_Group__c = 'Distributor';
        
        List<Account> lstAccount = new List<Account>();
        lstAccount.add(acc1);
        lstAccount.add(acc2);
        
        update lstAccount;
        
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Distributor__c = acc1.Id;
        opp2.Ultimate_Consignee__c = acc1.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
        lstOpportunity.add(opp1);
        lstOpportunity.add(opp2);
        
        insert lstOpportunity;
        
        test.startTest();
        
        Account_to_Field_Support__c afs1 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Primary Field Application Scientist');
        
        Account_to_Field_Support__c afs2 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Field Application Manager');
        
        Account_to_Field_Support__c afs3 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Primary Field Service Engineer');
        
        Account_to_Field_Support__c afs4 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Field Service Manager');
        
        list<Account_to_Field_Support__c> lstAccFS = new list<Account_to_Field_Support__c>();
        lstAccFS.add(afs1);
        lstAccFS.add(afs2);
        lstAccFS.add(afs3);
        lstAccFS.add(afs4);
        insert lstAccFS;
        
        
        test.stopTest(); 
        Opportunity objOpp = [Select id,Primary_Field_Service_Engineer__c from Opportunity where Name =:'opp1'];
        System.assertequals(null,objOpp.Primary_Field_Service_Engineer__c,'Id not matching');
        
    }
    
    /**
*    @author Akash Kumar
*    @date   2018-09-28
*    @description Delete Scenarios for Populate field service fields
*/ 
    static testMethod void updateFieldServicesFieldOnOpportunityOnDelete(){  
        
        SVMXC__Service_Group__c serviceTeam = [Select id from SVMXC__Service_Group__c];
        System.debug('serviceTeam' +serviceTeam);
        SVMXC__Service_Group_Members__c technicianFAS = [Select id from SVMXC__Service_Group_Members__c];
        technicianFAS.SVMXC__Active__c = true;
        update technicianFAS; 
        
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        
        Account acc1 = TestDataAccount.getNewAccount();
        acc1.Account_Group__c = 'Distributor';
        
        Account acc2 = TestDataAccount.getNewAccount();
        acc2.Account_Group__c = 'Distributor';
        
        List<Account> lstAccount = new List<Account>();
        lstAccount.add(acc1);
        lstAccount.add(acc2);
        
        update lstAccount;
        
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Distributor__c = acc1.Id;
        opp2.Ultimate_Consignee__c = acc1.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
        lstOpportunity.add(opp1);
        lstOpportunity.add(opp2);
        
        insert lstOpportunity;
        
        Account_to_Field_Support__c afs1 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Primary Field Application Scientist');
        
        Account_to_Field_Support__c afs2 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Field Application Manager');
        
        Account_to_Field_Support__c afs3 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c='Primary Field Service Engineer');
        
        Account_to_Field_Support__c afs4 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c='Field Service Manager');
        
        list<Account_to_Field_Support__c> lstAccFS = new list<Account_to_Field_Support__c>();
        lstAccFS.add(afs1);
        lstAccFS.add(afs2);
        lstAccFS.add(afs3);
        lstAccFS.add(afs4);
        insert lstAccFS;       
        
        test.startTest();
        
        delete lstAccFS;
        
        test.stopTest(); 
        
        Opportunity objOpp = [Select id,Primary_Field_Service_Engineer__c from Opportunity where Name =: 'opp1'];
        System.assertequals(null,objOpp.Primary_Field_Service_Engineer__c,'Id is not null');
        
        
    }
    
    /**
*    @author Akash Kumar
*    @date   2018-09-28
*    @description Delete Scenarios for Populate field service fields
*/ 
    static testMethod void updateFieldServicesFieldOnOpportunityOnUpdate(){  
        
        SVMXC__Service_Group__c serviceTeam = [Select id from SVMXC__Service_Group__c];
        System.debug('serviceTeam' +serviceTeam);
        SVMXC__Service_Group_Members__c technicianFAS = [Select id from SVMXC__Service_Group_Members__c];
        technicianFAS.SVMXC__Active__c = true;
        update technicianFAS; 
        
        List<Opportunity> lstOpportunity = new List<Opportunity>();
        
        Account acc1 = TestDataAccount.getNewAccount();
        acc1.Account_Group__c = 'Distributor';
        
        Account acc2 = TestDataAccount.getNewAccount();
        acc2.Account_Group__c = 'Distributor';
        
        List<Account> lstAccount = new List<Account>();
        lstAccount.add(acc1);
        lstAccount.add(acc2);
        
        update lstAccount;
        
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
        opp2.Name ='opp2';
        opp2.Distributor__c = acc2.Id;
        opp2.Ultimate_Consignee__c = acc1.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
        Opportunity opp3 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        opp3.Name = 'opp3';
        opp3.Ultimate_Consignee__c = acc1.Id;
        Opportunity opp4 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
        opp4.Name ='opp4';
        opp4.Distributor__c = acc2.Id;
        opp4.Ultimate_Consignee__c = acc1.Id;
        opp4.Direct_Sale_to_Ultimate_Consignee__c = false;
        lstOpportunity.add(opp1);
        lstOpportunity.add(opp2);
        lstOpportunity.add(opp3);
        lstOpportunity.add(opp4);
        
        insert lstOpportunity;
        
        Account_to_Field_Support__c afs1 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Primary Field Application Scientist');
        
        Account_to_Field_Support__c afs2 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Field Application Manager');
        
        Account_to_Field_Support__c afs3 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc2.Id,User_Role__c = 'Primary Field Service Engineer');
        
        Account_to_Field_Support__c afs4 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc2.Id,User_Role__c = 'Field Service Manager');
        
        list<Account_to_Field_Support__c> lstAccFS = new list<Account_to_Field_Support__c>();
        lstAccFS.add(afs1);
        lstAccFS.add(afs2);
        lstAccFS.add(afs3);
        lstAccFS.add(afs4);
        insert lstAccFS;    
        
        List<Account_to_Field_Support__c> lstUpdatedAccFS = new list<Account_to_Field_Support__c>();
        
        test.startTest();
        
        afs1.User_Role__c = 'Additional Service Resource';
        afs2.User_Role__c = 'Secondary Field Application Scientist';
        afs3.User_Role__c = 'Secondary Field Service Engineer';
        
        lstUpdatedAccFS.add(afs1);
        lstUpdatedAccFS.add(afs2);
        lstUpdatedAccFS.add(afs3);
       
        update lstUpdatedAccFS;
        
        test.stopTest(); 
        
        Opportunity objOpp = [Select id,Primary_Field_Service_Engineer__c from Opportunity where Name =: 'opp1'];
        System.assertequals(null,objOpp.Primary_Field_Service_Engineer__c,'Id is not null');
        
    }    
	 /**
        * DCP-17253
        *  @author : Dipika Gupta
        *  @description - test updates field support ids on Account
    **/
    static testMethod void testUpdateFieldSupportIdsOnAccount(){
        User usr;
        User usr1;
        System.runAs(new User(Id = UserInfo.getUserId())){
            usr = TestDataFieldService.createUser(System.label.Field_Service,false);
            usr.FederationIdentifier = 'Test123';
            
            
            //Create User
            usr1 = TestDataFieldService.createUser(System.label.Field_Service,false);
            usr1.userName = System.now().format('yyyyMMddhhmmss') + '@testorg1.com';
            usr1.FederationIdentifier = 'Test234';
            insert new list<User> {usr,usr1};
        }
        
        acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c= 'Distributor';
        
        Account acc1 = TestDataAccount.getAccount('Test Acc', 'USD');
        acc1.Account_Group__c= 'Distributor';
        insert new list<Account>{acc,acc1};
          
        serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(usr.id,'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c='b@b1.com';
        
        SVMXC__Service_Group_Members__c technicianFAS1 =TestDataFieldService.createTechnician(usr1.id,'Test Technician',serviceTeam.id);
        technicianFAS1.SVMXC__Email__c='b@b2.com';
        insert new list<SVMXC__Service_Group_Members__c> {technicianFAS,technicianFAS1};
        
                            
        Test.startTest();
        
        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Service Engineer',technicianFAS.id);
        Account_to_Field_Support__c accToFieldSupport1 =TestDataFieldService.createAccountToFieldSupport(acc1.id,'Primary Field Service Engineer',technicianFAS1.id);
        insert new list<Account_to_Field_Support__c> {accToFieldSupport,accToFieldSupport1};
        
        acc = [SELECT Field_Support_IDs__c From Account WHERE Id = : acc.Id];
        system.assertEquals('Test123test1', acc.Field_Support_IDs__c, 'The Field support Ids do not match');
        
        acc = [SELECT Field_Support_IDs__c From Account WHERE Id = : acc1.Id];
        system.assertEquals('Test234test1', acc.Field_Support_IDs__c, 'The Field support Ids do not match');
        
        Test.stopTest();
        
        
    }
    /**
    *    @author Vishal
    *    @date   2024-12-09
    *    @description Test method for AccountToFieldSupport : Duplicate Check flow
    */ 
    static testMethod void testDuplicateCheck(){ 
        //Create User
        User usr = TestDataFieldService.createUser(System.label.Field_Service,false);
        usr.FederationIdentifier = 'Test123';
        
        acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c= 'Distributor';
        insert acc;
        
        serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(usr.id,'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c='b@b1.com';
        insert technicianFAS;
        
        Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Additional Service Resource',technicianFAS.id);
        insert accToFieldSupport;
        List<Account_to_Field_Support__c> afsList = [select id,Duplicate_Record__c from Account_to_Field_Support__c where Id =: accToFieldSupport.Id];
        System.assert(afsList[0].Duplicate_Record__c != null, 'Duplicate Record field should not be null');
    }

    
    
}
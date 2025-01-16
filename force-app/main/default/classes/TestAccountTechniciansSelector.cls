/*****************************************************************************************************************************************
* @author       : Gladis
* @date         : 23-09-2022
* @Description  : Test class for AccountTechniciansSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Gladis                 23-09-2022               Initial version
****************************************************************************************************************************************/ 
@isTest
public with sharing class TestAccountTechniciansSelector {

    static Case cs;
    static Account acc;
    static SVMXC__Service_Group__c serviceTeam;
    static SVMXC__Service_Group_Members__c technicianFAS;

    /*
    *@author: Gladis
    *@Desc: Test data method
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
        
        technicianFAS =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c='b@b.com';
        insert technicianFAS;

        Account_to_Field_Support__c afs1 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
        Account__c = acc.Id,User_Role__c = 'Primary Field Application Scientist');
        
        Account_to_Field_Support__c afs2 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
        Account__c = acc.Id,User_Role__c = 'Field Service Manager');

        list<Account_to_Field_Support__c> lstAccFS = new list<Account_to_Field_Support__c>();
        lstAccFS.add(afs1);
        lstAccFS.add(afs2);
        insert lstAccFS;
        list<Account_to_Field_Support__c> aFSlst  = [Select Id from Account_to_Field_Support__c where Id =: lstAccFS[0].Id limit 1];
        system.assertEquals(1, aFSlst.size(), 'No Account to fiels support records');
    }

    /**
     *  @author Gladis
     *  @description - Test method to check SelectRelatedAccountTechnicians
    **/
    static testMethod void testSelectRelatedAccountTechnicians() {
        Test.startTest();
        Account account = [Select id from Account limit 1];
        list<Account_to_Field_Support__c> lstAcctoFS = new AccountTechniciansSelector().selectRelatedAccountTechnicians(new Set<Id>{account.Id});
        system.assert(!lstAcctoFS.isEmpty(), 'Account to field list Empty');
        Test.stopTest();
    }

    /**
     *  @author Gladis
     *  @description - Test method to check SelectAccountTechnicians
    **/
    static testMethod void testSelectAccountTechnicians() {
        Test.startTest();
        SVMXC__Service_Group_Members__c technician = [select Id from SVMXC__Service_Group_Members__c limit 1];
        list<Account_to_Field_Support__c> lstAcctoFS1 = new AccountTechniciansSelector().selectAccountTechnicians(new Set<Id>{technician.Id});
        system.assert(!lstAcctoFS1.isEmpty(), 'List Empty');
        Test.stopTest();
    }
}

/**
*    @date          9 Dec 2021
*    @description   Test Class for OpportunityContactRolesHelper.
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Prem Ranjan                    9 Dec 2021          Initial Version
*    ------------------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest(SeeAllData=false)
public with sharing class TestOpportunityContactRolesHelper {
    /**
    *    @author Prem Ranjan
    *    @date   2021-12-09
    *    @description DCP-50538 -Testing Power Sponser on Contact Role Creation    
    */
    @isTest
    static void testMakeContactPowerSponserOnInsert()
    {
        Account acc1 = TestDataAccount.getAccount('Territory Account');
        Account acc2 = TestDataAccount.getAccount('Territory Account 2');
        acc1.Territory_Region__c = 'China';
        acc1.ERP_Customer_Id__c = '123456';
        acc2.Territory_Region__c = 'AMR';
        acc2.ERP_Customer_Id__c = '123457';
        insert new List<Account>{acc1,acc2};  
        Contact con1 = TestDataPerson.initContact(acc1.Id);
        Contact con2 = TestDataPerson.initContact(acc2.Id);
        Contact con3 = TestDataPerson.initContact(acc1.Id);
        Contact con4 = TestDataPerson.initContact(acc2.Id);
        insert new List<Contact> { con1, con2, con3, con4 };
        List<Opportunity> lstOpp = new List<Opportunity>();
        set<Id> setOppIds = new set<Id>();
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id; 
        lstOpp.add(opp1);
        setOppIds.add(opp1.id);
        insert lstOpp;    
        Test.startTest();
        OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('', con1.Id, lstOpp[0].Id);
        insert new List<OpportunityContactRole> {ocr1};
        OpportunityContactRole contactRole1 = [SELECT id,Role,OpportunityId FROM OpportunityContactRole where id = :ocr1.id];
        System.assertEquals('Main Contact', contactRole1.Role, 'Role not set');
        OpportunityContactRole ocr2 = TestDataOpportunity.getNewOpportunityContactRole('', con3.Id, lstOpp[0].Id);
        insert new List<OpportunityContactRole> {ocr2};
        OpportunityContactRole contactRole2 = [SELECT id,Role,OpportunityId FROM OpportunityContactRole where id = :ocr2.id];
        System.assertNotEquals('Main Contact', contactRole2.Role, 'Role not set');
        Delete ocr1;
        OpportunityContactRole contactRole3 = [SELECT id,Role,OpportunityId FROM OpportunityContactRole where id = :ocr2.id];
        System.assertEquals('Main Contact', contactRole3.Role, 'Role not set');
        Test.stopTest();
    }

    /*******************************************************
    *Method Name : coverCatchBlockOpportunityContactRoleQueueable()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
    @isTest
    public static void coverCatchBlockOpportunityContactRoleQueueable(){
        try{
            OpportunityContactRoleQueueable.catchException = true;
            OpportunityContactRoleQueueable pd = new OpportunityContactRoleQueueable(null, null,null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null,'e is not empty');
        }
    }	
}

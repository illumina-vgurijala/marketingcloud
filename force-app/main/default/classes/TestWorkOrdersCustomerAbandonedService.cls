/**
 *    @author Gladis
 *    @date   05/05/2021  
 *    @description: Test class for WorkOrdersCustomerAbandonedService   
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Gladis                      05/05/2021            Initial Version.
 *    Shivani                     01/07/2022            DCP-54018 Increase coverage for AbandonedStatusQueueable_WOHelper
 *    ------------------------------------------------------------------------------------ 
 *                    
 */

@istest
public with sharing class TestWorkOrdersCustomerAbandonedService {
    
    static Case cs;
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_ACCOUNT_GROUP = 'Distributor';
    public static final String STRING_WO_ABANDONED_REASON_NO_CUST_RESPONSE = 'No Customer Response';
    
    /** 
        Name : initializeTestData
        Description : Method to create setup data. 
    **/
	@testSetup
    public static void initializeTestData() {
        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c=STRING_ACCOUNT_GROUP;
        insert acc;
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case		 
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs; 
        insert new Code_Library__c(
            Code_Type__c = 'Resolution',
            Case_Type__c = 'Business Issue',
            Name = WorkOrdersCustomerAbandonedService.STRING_ABANDONED_CODE,
            Code_Description__c = 'Test Code'
        );
        
    }
     
    /**
     *  @author       : Gladis
     *  @description  : Updating WorkOrder record with Abadoned Reason
     *  @return       : void
     */
    static testMethod void updateWorkOrder() {
        Boolean exceptionThrown = false;

        // creating/Inserting the WorkOrder 
        initializeTestData();
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Field Service'].Id,
            LastName = 'last',
            Email = 'test@g.com',
            Username = 'test@g.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        insert u;
        Account acc2 = TestDataAccount.getAccount('Test Acc2', 'USD');
        acc2.Account_Group__c='Distributor';
        acc2.ERP_Customer_Id__c = 'Test2';
        insert acc2;
        System.assert(acc2.Id != null, 'Account should not be null');
        
        Contact con2 = TestDataPerson.getNewContact(acc2.Id);
        System.assert(con2.id != null);
        
        Case cs2 = TestDataCase.createCase('Business Issue','Initiated',con2.Id);
        cs2.Sub_Type__c = 'Complaint';
        update cs2;
        SVMXC__Service_Order__c workOrder = [Select Id,OwnerId, Abandoned_Reason__c,SVMX_PS_Subject__c From SVMXC__Service_Order__c Where SVMXC__Case__c = :cs2.Id Limit 1];

        Test.startTest();
        try {
            AbandonedStatusQueueable_WOHelper.testClassCoverage = true;
            // Updating the WorkOrder's Abandoned Reason
            workOrder.OwnerId=u.Id;
            workOrder.Abandoned_Reason__c='No Customer Response';
            workOrder.SVMX_PS_Subject__c='test';
            update workOrder;
            SVMXC__Service_Order__c updatedwo=[select id,SVMX_PS_Subject__c,Abandoned_Reason__c from SVMXC__Service_Order__c where id =:workOrder.id];
            System.assertEquals('ABANDONED - test',updatedwo.SVMX_PS_Subject__c,'Subject not updated'); 
            Test.stopTest();
        } catch(Exception ex) {
            exceptionThrown = ex.getMessage().contains('Throwing Exception from Test Class');
        }

        System.assert(exceptionThrown, 'Exception not thrown from queueable class');
        List<Associated_Codes__c> lstAssociatedCOde = new AssociatedCodeSelector().selectParticularAssociatedCodesOnWorkOrders(new Set<Id>{workOrder.id},WorkOrdersCustomerAbandonedService.STRING_ABANDONED_CODE);
        System.assertEquals(1,lstAssociatedCOde.size(),'Associated Code not created'); 
    }

}
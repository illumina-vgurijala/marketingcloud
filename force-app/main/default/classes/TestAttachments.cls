/**
 *    @author         :
 *    @date           :
 *    @description    : Test class for Attachments
 *    Modification Log:
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date                Description
 *    Vivek R                       06-Oct-22           Codescan fixes: added comments
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest (SeeAllData=False)
public class TestAttachments {
    public static final String STRING_ATTACHMENT_NAME = 'Letter of Acceptance - signed';
    public static final String STRING_WORK_ORDER_ACCEPTANCE_STATUS = 'Completed';
    public static final String STRING_AGREEMENT_NAME = 'Letter of Acceptance';
    public static final String STRING_AGREEMENT_STATUS_SIGNED = 'Signed';
    public static final String STRING_WORK_ORDER_ACCEPATNCE_FORECAST = '100% Completed - LOA Signed';
    static SVMXC__Service_Order__c workOrder= new SVMXC__Service_Order__c();
    static echosign_dev1__SIGN_Agreement__c objAgreement= new echosign_dev1__SIGN_Agreement__c();
    static SVMXC__Site__c objLocation = new SVMXC__Site__c();
    static Account objAccount = new Account();
    static Opportunity opportunity = new Opportunity();
    static Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();

    /**
     *  @description : Method for test data setup
    */
    @testSetup
    public static void initializeTestData() {
        objLocation = TestDataFieldService.createLocation('Test Location','Test','Test','Test','USD');
        insert objLocation;

        workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Site__c=objLocation.id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Generate_Inventory_Snapshot__c = true;
        workOrder.Is_Auto_Created__c = true;
        WorkOrders.skipWOTrigger = true;
        insert workOrder;

        objAccount = TestDataAccount.initAccount();
        insert objAccount;
        try {
            Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();

        

        priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        opportunity = TestDataOpportunity.initOpportunity(objAccount);
        opportunity.Pricebook2Id = standardPricebook.Id;
        opportunity.Price_List__c = '01-AMR-USD';
        opportunity.Sold_to_Sales_Organization__c = 'CN03';
        insert opportunity;       
     } catch (Exception e) {
            system.debug(e);
        }
    }

    /**
    *  @author : Soumya Ranjan
    *  @description - test validate Attachment Parent is changed.
    **/
    static testMethod void validateAttachmentParentIsChanged() {
        initializeTestData();
        
        system.debug('objLocation='+objLocation.id);
        Attachment objAttachment=TestDataFieldService.createAttachment(objLocation.Id,'Test');
        insert objAttachment;
        
        Test.startTest();
        
        Attachment objAttachment1=new Attachment();
        objAttachment1=[Select Name,ParentId from Attachment where id=:objAttachment.id][0];
        system.assertEquals(objAttachment1.ParentId,workOrder.id);
        
        Test.stopTest();
    }

    /**
    *  @author : Soumya Ranjan
    *  @description - test validate Letter of Acceptance is generated and E-Signed.
    **/
    static testMethod void validateLOAEmail() {
        initializeTestData();
        objAgreement = TestDataFieldService.createAgreement(STRING_AGREEMENT_NAME,STRING_AGREEMENT_STATUS_SIGNED,workOrder.id);
        insert objAgreement;
        Test.startTest();
        Attachment objAttachment=TestDataFieldService.createAttachment(objAgreement.Id,STRING_ATTACHMENT_NAME);
        insert objAttachment;
        Attachment objAttachment1=new Attachment();
        objAttachment1=[Select Name,ParentId from Attachment where id=:objAttachment.id][0];
        SVMXC__Service_Order__c objWorkOrder1= new SVMXC__Service_Order__c();
        objWorkOrder1=[Select Name,LOA_Signed_and_Attached__c from SVMXC__Service_Order__c where id=:workOrder.id][0];
        system.assert(objWorkOrder1.LOA_Signed_and_Attached__c);
        Test.stopTest();
    }

    /**
    *  @author : Roopal Verma
    *  @description - DCP-45303: tests task creation when sales contract is attached to a quote
    **/
    static testMethod void validateTaskCreation() {
        initializeTestData();

        Set<Id> userProfileId = Profiles.getAdminProfileId();
        List<User> lstUsers = [
            SELECT Id, Name, IsActive
            FROM User
            WHERE ProfileId IN :userProfileId
            AND IsActive = true
            LIMIT 1
        ];

         Apttus_Proposal__Proposal__c objQuotation = TestDataProposal.initProposal(objAccount.id, opportunity.id, 'Test Proposal', priceList.id, true, 'Presented', 'None'); 
         objQuotation.Ultimate_Consignee__c = objAccount.id;
         objQuotation.Sold_To_Sales_Organization__c = 'CN03';
         insert objQuotation;

         System.runAs(lstUsers[0])
         {
             Apttus_Proposal__Proposal__c objUpdQuote = [Select Id,Name,View_Contract__c from Apttus_Proposal__Proposal__c LIMIT 1];

             Attachment objAttachment=TestDataFieldService.createAttachment(objUpdQuote.Id,'Test');
             insert objAttachment;

             test.startTest();
             List<Task> lstTask = [SELECT Id,Subject FROM Task WHERE WhatId =: objUpdQuote.id];
             system.assertEquals(1, lstTask.size(), 'Task did not get created ');
             test.stopTest();
        }
     }
}
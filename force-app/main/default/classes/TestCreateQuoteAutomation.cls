/**
*    @author Adyasha Satapathy
*    @date   2021-05-10 
*    @description    DCP-38809: Test class for Auto Create Quote and Cart
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                 Date                Description
*         Adyasha Satapathy         2021-05-10          Initial Version
*         Akshay                    2021-05-17          DCP-46579 changes
*         Adithi Acharya            2022-09-27          Test coverage 
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestCreateQuoteAutomation
{
    /**
    *   DCP-38809
	*	@author Adyasha Satapathy	
	**/
    @TestSetup
    static void setupData()
    {
        TestDataBillableFlowQueueable.getWorkOrder();
    }

    /**
    *   DCP-38809
	*	@author Adyasha Satapathy
	**/
    @isTest
    static void testQuotationCreate()
    {
        
        
        SVMXC__Service_Order_Line__c objWorkDetail = [SELECT Id,SVMXC__Product__c,SVMXC__Service_Order__c,Discount_Reason__c,SVMXC__Service_Order__r.Initiate_Quoting__c FROM SVMXC__Service_Order_Line__c LIMIT 1];
        objWorkDetail.SVMXC__Service_Order__r.Initiate_Quoting__c = CreateQuoteAutomation.INITIATE_QUOTING_BLANKET;
        update objWorkDetail.SVMXC__Service_Order__r;
        Test.startTest();
        Opportunity objOpportunity = TestDataBillableFlowQueueable.createOpportunityFromWorkOrder(objWorkDetail.SVMXC__Service_Order__c, objWorkDetail.SVMXC__Product__c);
        
        CreateQuoteAutomation objQueueable = new CreateQuoteAutomation();
        objqueueable.setRecordId(objOpportunity.Id);
        objqueueable.execute(null);
        
        Test.stopTest();

        System.assert(String.isNotBlank(objQueueable.getRecordId()),'Id not being returned as expected');
        Apttus_Proposal__Proposal__c objProposal = [Select Id, Work_Order__c,Work_Order_Discount_Request__c from Apttus_Proposal__Proposal__c LIMIT 1];
        System.assertEquals(objWorkDetail.SVMXC__Service_Order__c,objProposal.Work_Order__c, 'WorkOrder not stamped on Quotation');
        System.assertEquals(null,objProposal.Work_Order_Discount_Request__c,'Discount Reason not null');
        
    }
    
    /**
    *   Test Coverage for ApttusUpdatePriceForCart class
	*	@author Adithi Acharya	
	**/
    
    @isTest
    static void testBoolIsPricePendingCheck()
    {
        ApttusUpdatePriceForCart.runTestBoolIsPricePending = true;
        SVMXC__Service_Order_Line__c objWorkDetail = [SELECT Id,SVMXC__Product__c,SVMXC__Service_Order__c,Discount_Reason__c,SVMXC__Service_Order__r.Initiate_Quoting__c FROM SVMXC__Service_Order_Line__c LIMIT 1];
        objWorkDetail.SVMXC__Service_Order__r.Initiate_Quoting__c = CreateQuoteAutomation.INITIATE_QUOTING_BLANKET;
        update objWorkDetail.SVMXC__Service_Order__r;
        Test.startTest();
        Opportunity objOpportunity = TestDataBillableFlowQueueable.createOpportunityFromWorkOrder(objWorkDetail.SVMXC__Service_Order__c, objWorkDetail.SVMXC__Product__c);
        CreateQuoteAutomation objQueueable = new CreateQuoteAutomation();
        objqueueable.setRecordId(objOpportunity.Id);
        objqueueable.execute(null);
        Test.stopTest();
        System.assert(String.isNotBlank(objQueueable.getRecordId()),'Id not being returned as expected');
        
    }

    /**
    *   DCP-46579
	*	@author Akshay Mohan
	**/
    @isTest
    static void testQuotationWithDiscountReason(){
        Test.startTest();
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        setting.Bypass_All_Triggers__c=true;
        upsert setting;
        
        SVMXC__Service_Order_Line__c objWorkDetail = [SELECT Id,SVMXC__Product__c,SVMXC__Service_Order__c,Discount_Reason__c,SVMXC__Service_Order__r.Initiate_Quoting__c 
                                                        FROM SVMXC__Service_Order_Line__c LIMIT 1];
        objWorkDetail.Discount_Reason__c='Inflation kills.';
        update objWorkDetail;
        objWorkDetail.SVMXC__Service_Order__r.Initiate_Quoting__c = CreateQuoteAutomation.INITIATE_QUOTING_BLANKET;
        update objWorkDetail.SVMXC__Service_Order__r;
        setting.Bypass_All_Validations__c = false;
        setting.Bypass_All_Triggers__c=false;
        upsert setting;
        Opportunity objOpportunity = TestDataBillableFlowQueueable.createOpportunityFromWorkOrder(objWorkDetail.SVMXC__Service_Order__c, objWorkDetail.SVMXC__Product__c);
        
        CreateQuoteAutomation objQueueable = new CreateQuoteAutomation();
        objqueueable.setRecordId(objOpportunity.Id);
        objqueueable.execute(null);
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails = objqueueable.getErrorDetails();
        Test.stopTest();
        System.debug('wrapDetails: '+wrapDetails);
        Apttus_Proposal__Proposal__c objProposal = [Select Id, Work_Order__c,Work_Order_Discount_Request__c from Apttus_Proposal__Proposal__c LIMIT 1];
        System.assert(objProposal.Work_Order_Discount_Request__c.contains(objWorkDetail.Discount_Reason__c), 'Discount reason not stamped on Quotation');
        System.assertEquals(null,objqueueable.getRecordId(),'Process not stopping in case of error');
        System.assertEquals(Label.OpportunityQuoteAutomation_QUOTE_DISCOUNT_NEEDED,wrapDetails.strFailureReason,'Wrong failure message');
    }
}
/***************************************************************************************************************************************
    * NAME   : TestUpdateQuoteAmountOnWO
    * DESCRIPTION  : Test class for UpdateQuoteAmountOnWO
    *                    
    * @AUTHOR : Akshay Mohan
    * @DATE   : 04-May-2021  
    * 
    * MODIFICATION LOG: 
    * -----------------------------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * ------------------------------------------------------------------------------------------------------------------------------------------------------------
    * Akshay Mohan             04-May-2021          Initial Version. 
    * Adyasha Satapathy        28-Nov-2022          POL-54: Update region references to AMEA and EUR

******************************************************************************************************************************************************************/
@isTest(SeeAllData=false)
public with sharing class TestUpdateQuoteAmountOnWO {
   
    /**
     *  @author Akshay Mohan
     *  @description Test setup
     **/
    @testSetup
    public static void initializeTestData() {
        Account acc = TestDataAccount.initAccount();
        insert acc;
        Contact con = TestDataPerson.initContact(acc.Id);
        insert con;
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Reason_for_Reopen__c = 'Test Reason';
        insert cs;

        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
		workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        setting.Bypass_All_Validations__c = false;
        update setting;

        Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        accSalesArea.Account__c = acc.Id;
        accSalesArea.Price_List_Type__c = '06';
        accSalesArea.CurrencyIsoCode = 'USD';
        accSalesArea.Price_List__c = '01-AMEA-USD'; //POL-54
        accSalesArea.Contract_Number__c = '123456_HK010100';
        insert accSalesArea;

        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Pricebook2Id = standardPricebook.Id;
        opp.Price_List__c = '01-AMR-USD';
        insert opp;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Apttus_Proposal__Proposal__c proposal1 = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, Label.QuoteStageDraft, Label.QuoteApprovalStatusNone);
        proposal1.Work_Order__c=workOrder.id;
        proposal1.Total_Net__c=0;
        proposal1.Apttus_Proposal__Primary__c=false;
        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal 2', priceList.id, true, Label.QuoteStageDraft, Label.QuoteApprovalStatusNone);
        proposal2.Work_Order__c=workOrder.id;
        proposal2.Total_Net__c=50;
        proposal2.Apttus_Proposal__Primary__c=true;
        insert new List<Apttus_Proposal__Proposal__c>{proposal1,proposal2};
        
    }

    /**
     *  @author Akshay Mohan
     *  @description Test method for setting primary
     **/
    @istest
    static void setPrimary(){
        Apttus_Proposal__Proposal__c proposal = [SELECT Id,Work_Order__c,Total_Net__c, Apttus_Proposal__Primary__c
                                                    FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c='Test Proposal'];
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP,new Set<Id>{UserInfo.getUserId()});
        proposal.ownerId=objUser.Id;
        update proposal;
        Test.startTest();
        System.runAs(objUser){
            proposal.Apttus_Proposal__Primary__c=true;
            proposal.Total_Net__c=1000;
            update proposal;
        }
        Test.getEventBus().deliver();
        Test.stopTest();

        SVMXC__Service_Order__c workOrder = [SELECT Id,Quote_Amount__c 
                                                FROM SVMXC__Service_Order__c LIMIT 1];
        System.assertEquals(proposal.Total_Net__c,workOrder.Quote_Amount__c,'Quote amount not updated');
    }

    /**
     *  @author Akshay Mohan
     *  @description Test method for changing amount
     **/
    @istest
    static void changeAmount(){
        Apttus_Proposal__Proposal__c proposal = [SELECT Id,Work_Order__c,Total_Net__c, Apttus_Proposal__Primary__c
                                                    FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c='Test Proposal 2'];
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP,new Set<Id>{UserInfo.getUserId()});
        proposal.ownerId=objUser.Id;
        update proposal;
        Test.startTest();
        System.runAs(objUser){
            proposal.Total_Net__c=500;
            update proposal;
        }
        Test.getEventBus().deliver();
        Test.stopTest();

        SVMXC__Service_Order__c workOrder = [SELECT Id,Quote_Amount__c 
                                                FROM SVMXC__Service_Order__c LIMIT 1];
        System.assertEquals(proposal.Total_Net__c,workOrder.Quote_Amount__c,'Quote amount not updated');
    }

    /**
     *  @author Adyasha Satapathy
     *  @description Test method for event creation to view WO Document
     **/
    @isTest 
    static void testCreateEventToViewWODocument()
    {
        SVMXC__Service_Order__c workOrder = [SELECT Id,OwnerId FROM SVMXC__Service_Order__c LIMIT 1];
        
        Apttus_Proposal__Proposal__c proposal = [SELECT Id,Work_Order__c,Total_Net__c, Apttus_Proposal__Primary__c
                                                    FROM Apttus_Proposal__Proposal__c 
                                                    WHERE Apttus_Proposal__Proposal_Name__c='Test Proposal'];
        

        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_FIELD_SERVICE,new Set<Id>{UserInfo.getUserId()});
        Test.startTest();
        System.runAs(objUser)
        {
            workOrder.OwnerId = objUser.Id;
            workOrder.SVMXC__Order_Type__c = Label.Presales;
            workOrder.RecordTypeId = ServiceUtilityCollection.getRecordTypeId(ServiceUtilityCollection.STRING_WORKORDER_API_NAME,Label.Service_Support);
            WorkOrders.skipWOTrigger = true;
            update workOrder;
        }
        Event objEvent = new Event();
        objEvent.subject = 'Testing';
        objEvent.StartDateTime = System.now().addDays(-1);
        objEvent.EndDateTime = System.now().addDays(1);
        objEvent.WhatId = workOrder.Id;
        objEvent.OwnerId = workOrder.OwnerId;
        insert objEvent;
        
        proposal.Apttus_Proposal__Primary__c=true;
        proposal.Total_Net__c=1000;
        update proposal;

        Test.getEventBus().deliver();
        Test.stopTest();
        
        Event autoInsertedEvent = [SELECT Id,WhatId,Subject,OwnerId FROM Event WHERE OwnerId = : objUser.Id];
        System.assertNotEquals('Quote Created',autoInsertedEvent.Subject,'Subject did not match for new event');
        System.assertEquals(workOrder.Id,autoInsertedEvent.WhatId,'What Id did not match for new event');
    }
}
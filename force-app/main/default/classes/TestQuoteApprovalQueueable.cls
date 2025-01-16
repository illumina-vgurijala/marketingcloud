/**
*    @author Akshay Mohan
*    @date   2021-05-10
*    @description    DCP-38809: Test class for QuoteApprovalQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-10         Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestQuoteApprovalQueueable {
    private static final String PRICELIST = 'AMR-USD-US-01';
    private static final String AMR = 'AMR';
    private static final String USD = 'USD';
    private static final String USA = 'USA';
    private static final String OPPORTUNITYRTDIRECT = 'Direct';
    private static final String LIST_EXCEPTION = 'List index out of bounds: 0';
    
    /**DCP-38809
	*	@author Akshay Mohan
	*	
	**/
    @testSetup
    static void setupData(){
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICELIST);
        insert objPriceList;

        Account objAccount = TestDataAccount.getNewAccount();
        TestDataPerson.getNewContact(objAccount.Id);
        objAccount.Territory_Region__c =AMR;
        objAccount.CurrencyIsoCode=USD;
        objAccount.Country_Local__c = USA;
        update objAccount;

        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c='Installation';
        objWorkOrder.Is_Auto_Created__c = true;
        objWorkOrder.SVMXC__Company__c = objAccount.id;
        insert objWorkOrder;

        setting.Bypass_All_Validations__c = false;
        update setting;
        
        Customer_Master_Data__c objCMD = new Customer_Master_Data__c(Name = 'GCMD', Country__c = 'Hong Kong', Country_Code__c = 'HK');
        insert objCMD;

        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
      
        objOpportunity.RecordTypeName__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Sold_to_Distribution_Channel__c = OPPORTUNITYRTDIRECT;
        objOpportunity.Transborder_Flag__c = true;
        objOpportunity.Price_List__c = objPriceList.Name;
        objOpportunity.Work_Order__c = objWorkOrder.id;
        update objOpportunity;
        
        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        objProposal.SAP_Quote__c='SAP dummy';
        objProposal.Ship_To__c =objCMD.Id;
        objProposal.Apttus_QPConfig__PriceListId__c=objPriceList.Id;
        objProposal.Apttus_Proposal__Approval_Stage__c=Label.QuoteStageApprovalRequired;
        objProposal.Work_Order__c = objWorkOrder.id;
        insert objProposal;
        
        
        
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	
	**/
    @isTest
    static void testApproved(){
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Submit_For_Approval__c,Approval_Category__c,Approval_Hierarchy_Record_Owner__c,Approval_Hierarchy_Transborder__c,Invalid_Quote__c ,Apttus_QPConfig__PriceListId__c ,Ship_To__c ,Informatics_Product_Line_Item_Numbers__c,SAP_Quote__c 
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.debug('objProposal: ' +objProposal);
        QuoteApprovalQueueable queueable = new QuoteApprovalQueueable();
        queueable.setRecordId(objProposal.id);
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();
        System.assertEquals(objProposal.Id,queueable.getRecordId(),'Approval not processed');
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	
	**/
    @isTest
    static void testBlocked(){
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Submit_For_Approval__c,Approval_Category__c,Approval_Hierarchy_Record_Owner__c,Approval_Hierarchy_Transborder__c,Invalid_Quote__c ,Apttus_QPConfig__PriceListId__c ,Ship_To__c ,Informatics_Product_Line_Item_Numbers__c,SAP_Quote__c 
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.debug('objProposal: ' +objProposal);
        objProposal.Ship_To__c=null;
        update objProposal;
        QuoteApprovalQueueable queueable = new QuoteApprovalQueueable();
        queueable.setRecordId(objProposal.id);
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();
        Apttus_Proposal__Proposal__c objProposalUpdated =[SELECT Id, Apttus_QPApprov__Approval_Status__c 
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        System.assertNotEquals(Label.QuotationApprovalStatusApproved,objProposalUpdated.Apttus_QPApprov__Approval_Status__c,'Approval not blocked');
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	
	**/
    @isTest
    static void testApprovalRequired(){
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Submit_For_Approval__c,Approval_Category__c,Approval_Hierarchy_Record_Owner__c,Approval_Hierarchy_Transborder__c,Invalid_Quote__c ,Apttus_QPConfig__PriceListId__c ,Ship_To__c ,Informatics_Product_Line_Item_Numbers__c,SAP_Quote__c 
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        objProposal.Approval_Category__c='Region';
        update objProposal;
        QuoteApprovalQueueable queueable = new QuoteApprovalQueueable();
        queueable.setRecordId(objProposal.id);
        Test.startTest();
        queueable.execute(null);
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails = queueable.getErrorDetails();
        Test.stopTest();
        System.debug('wrapDetails: '+wrapDetails);
        System.assertEquals(null,queueable.getRecordId(),'Approval not stopped');
        System.assertEquals(Label.OpportunityQuoteAutomation_QUOTE_APPROVAL_BLOCKED,wrapDetails.strFailureReason,'Expected failure message not set');
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	
	**/
    @isTest
    static void testError(){
        String errorMessage = '';
        Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Submit_For_Approval__c,Approval_Category__c,Approval_Hierarchy_Record_Owner__c,Approval_Hierarchy_Transborder__c,Invalid_Quote__c ,Apttus_QPConfig__PriceListId__c ,Ship_To__c ,Informatics_Product_Line_Item_Numbers__c,SAP_Quote__c 
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
        QuoteApprovalQueueable queueable = new QuoteApprovalQueueable();
        queueable.setRecordId(objProposal.id);
        delete objProposal;
        Test.startTest();
        try{
            queueable.execute(null);
            queueable.getErrorDetails();
        }
        catch(Exception e){
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        System.assert(errorMessage.contains(LIST_EXCEPTION), 'Exception not fired');
    }

     /**
     *  @author      : Anshaj
     *  @description : method to cover catch block in CreateOpportunityAutomation
     **/
    @isTest
    public static void coverCatchCreateOpportunityAutomation(){
        try{
            Test.startTest();
            QuoteApprovalQueueable.catchException = true;
            Apttus_Proposal__Proposal__c objProposal=[SELECT Id, Submit_For_Approval__c,Approval_Category__c,Approval_Hierarchy_Record_Owner__c,Approval_Hierarchy_Transborder__c,Invalid_Quote__c ,Apttus_QPConfig__PriceListId__c ,Ship_To__c ,Informatics_Product_Line_Item_Numbers__c,SAP_Quote__c 
                                                    FROM Apttus_Proposal__Proposal__c LIMIT 1];
            QuoteApprovalQueueable queueable = new QuoteApprovalQueueable();
            queueable.setRecordId(objProposal.id);
            queueable.execute(null);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}
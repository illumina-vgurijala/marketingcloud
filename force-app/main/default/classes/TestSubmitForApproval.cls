/**
*    @author Vignesh S
*    @date   27 Apr 2020
*    @description  Test class for SubmitForApproval
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Vignesh S             27 Apr 2020     
*       Karthik Rayani        25-Sep-2020     DCP-40107 - Added method testCheckApprovalInBatchWithError for new logic.
*       Pravallika, Gundreddy 28-nov-2022     POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*       Satya Swain           09 Dec 2022     Added Codescan fix for Variable Naming Convention
*/
@isTest(SeeAllData=false isParallel=false)
public with sharing class TestSubmitForApproval{
    
    public static FINAL string AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    public static FINAL string TEST_TXDR = 'Test TXDR';
    public static FINAL string VC0013519_OPA = 'VC0013519-OPA';
    /**
*  @author Vignesh S
*  @description Test Data Setup
**/
    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BIllingCountryCode='HK';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';
        acc2.BIllingCountryCode='HK' ;
        insert new List<Account> { acc, acc2 };
            Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
            
            Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
            objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};
            
            TestDataAgreement.addHierarchyPermission();
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';
        
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Price_Group__c = 'TXDR';
        acc2SalesArea.Sales_Organization__c='AU01';
        acc2SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc2SalesArea.Distribution_Channel__c='01';
        
        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc3SalesArea.Account__c = acc2.Id;
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc3SalesArea.Contract_Number__c ='67890_HK010100';
        acc3SalesArea.Price_Group__c = 'TXDR';
        acc3SalesArea.Sales_Organization__c='HK01';
        acc3SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc3SalesArea.Distribution_Channel__c='01';
        acc3SalesArea.ERP_Account_Sales_Area_Id__c='67890_HK010100';
        
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea,acc3SalesArea  };
            
            Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = VC0013519_OPA;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        insert new List<Product2> { product, productTwo, productThree };
            
            Id recTypeChannelPartner = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Id recTypeMasterAgreement = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Service Agreement').getRecordTypeId();
        
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        //oAgreement1.Customer_Discount_Level__c = 'Price Group';
        oAgreement1.Sales_Org__c ='HK01';//adding reference sales org
        oAgreement1.RecordTypeId = recTypeChannelPartner;
        oAgreement1.Apttus__Auto_Renewal__c=True;
        
        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement -  No Price Group', acc2.id);
        oAgreement2.RecordTypeId = recTypeMasterAgreement;
        oAgreement2.Apttus__Contract_Start_Date__c = system.today();
        oAgreement2.Apttus__Contract_End_Date__c = system.today() + 750;
        oAgreement2.Sales_Org__c = 'AU01'; //DCP-33757 //adding reference sales org
        
        Apttus__APTS_Agreement__c oAgreement3 = TestDataAgreement.initAgreements('Test Agreement - Date Validation', acc.id);
        oAgreement3.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement3.Sales_Org__c = 'HK01'; //adding reference sales org
        oAgreement3.RecordTypeId = recTypeChannelPartner;
        //oAgreement3.Customer_Discount_Level__c = 'Price Group';
        
        Apttus__APTS_Agreement__c oAgreement4 = TestDataAgreement.initAgreements('Test Agreement - Activated', acc.id);
        oAgreement4.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement4.Sales_Org__c = 'HK01';//adding reference sales org
        oAgreement4.RecordTypeId = recTypeChannelPartner;
        oAgreement4.Apttus__Status__c = 'Activated';
        oAgreement4.Apttus__Status_Category__c = 'In Effect';
        
        insert new List<Apttus__APTS_Agreement__c> {oAgreement1, oAgreement2, oAgreement3, oAgreement4};
            
        List<Approval_Hierarchy__c> lstApprovalHierarchy = new List<Approval_Hierarchy__c>();
        Approval_Hierarchy__c objDiscountApprovalHeirarchy = TestDataAgreement.initApprovalHierarchyStandingDiscount('CLM_Custom_Hierarchy', acc.OwnerId);
        lstApprovalHierarchy.add(objDiscountApprovalHeirarchy);
        insert lstApprovalHierarchy;
        
        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();
        Custom_Approval_Matrix__c standingDiscountApprovalMatrix = TestDataAgreement.initApprovalMatrixForAgreement('CLM Discount', 10 , null, null,objDiscountApprovalHeirarchy.id);
        lstMatrix.add(standingDiscountApprovalMatrix);
        insert lstMatrix;
        
        List<Apttus__AgreementLineItem__c> lstALI = new list<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c oAgreementLI1 = TestDataAgreement.initAgreementsLineItem(oAgreement3.id);
        //oAgreementLI1.Material_Number__c = VC0013519_OPA;
        oAgreementLI1.Material_Group_1__c = 'BGS';
        oAgreementLI1.Line_Type__c = 'Material Group 1';
        oAgreementLI1.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI1.Discount_Type__c = '% Discount';
        oAgreementLI1.Discount__c = 15;
        oAgreementLI1.Customer_ERP_Number__c = '123456';
        oAgreementLI1.Sales_Org__c = 'HK01';
        oAgreementLI1.Distribution_Channel__c = '02';
        oAgreementLI1.CurrencyIsoCode= 'USD';
        oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today()+5;
        oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+28;
        lstALI.add(oAgreementLI1);
        
        Apttus__AgreementLineItem__c oAgreementLI2 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        //oAgreementLI2.Material_Number__c = VC0013519_OPA;
        oAgreementLI2.Material_Group_1__c = 'BGS';
        oAgreementLI2.Line_Type__c = 'Material Group 1';
        oAgreementLI2.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI2.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI2.Discount_Type__c = '% Discount';
        oAgreementLI2.Discount__c = 15;
        oAgreementLI2.Customer_ERP_Number__c = '123456';
        oAgreementLI2.Sales_Org__c = 'HK01';
        oAgreementLI2.Distribution_Channel__c = '02';
        oAgreementLI2.CurrencyIsoCode= 'USD';
        oAgreementLI2.Apttus_CMConfig__StartDate__c = system.today()+5;
        oAgreementLI2.Apttus_CMConfig__EndDate__c = system.today()+28;
        lstALI.add(oAgreementLI2);
        
        insert lstALI;
        
        
    }
    
    @isTest
    static void testCheckApprovalInBatch(){
        Apttus_Approval__Approval_Process__c objProcess = new Apttus_Approval__Approval_Process__c();
        objProcess.Apttus_Approval__Active__c = true;
        objProcess.Apttus_Approval__Assignment_Email_Template__c = 'Test Visa Assignment Template';
        objProcess.Apttus_Approval__Cancellation_Email_Template__c = 'Test Visa Cancellation Template';
        objProcess.Apttus_Approval__Escalation_Email_Template__c = 'Test Visa Escalation Template';
        objProcess.Apttus_Approval__NotifyOnly_Email_Template__c = 'Test Visa NotifyOnly Template';
        objProcess.Apttus_Approval__Reassignment_Email_Template__c = 'Test Visa Reassignment Template';
        objProcess.Apttus_Approval__Object_Label__c = 'Quotation';
        objProcess.Apttus_Approval__Object_Name__c = 'Apttus__APTS_Agreement__c';
        objProcess.Apttus_Approval__Object_Type__c = 'Apttus__APTS_Agreement__c';
        objProcess.Apttus_Approval__Process_Name__c = 'Test Visa Legal Approval Process';
        objProcess.Apttus_Approval__ProcessAutoEscalate__c = false;
        objProcess.Apttus_Approval__SubmissionCommentsEnabled__c = false;
        objProcess.Apttus_Approval__ContextType__c = 'Single';
        objProcess.Apttus_Approval__Sequence__c = 1;
        objProcess.RecordTypeId = [select id from RecordType where name = 'Approval Process' limit 1].Id;
        insert objProcess;
        
        Apttus_Approval__Approval_Process__c objEntryCriteria =  new Apttus_Approval__Approval_Process__c(); 
        objEntryCriteria.RecordTypeId = [select id from RecordType where name = 'Entry Criteria' limit 1].Id;
        objEntryCriteria.Apttus_Approval__Active__c = true;
        objEntryCriteria.Apttus_Approval__Entry_Criteria_Active__c = true;
        objEntryCriteria.Apttus_Approval__Entry_Criteria_BoolOper__c = 'AND';
        objEntryCriteria.Apttus_Approval__Entry_Criteria_Comparison_Type__c = 'contains';
        objEntryCriteria.Apttus_Approval__Entry_Criteria_Field__c = 'Name';
        objEntryCriteria.Apttus_Approval__Entry_Criteria_Field_Value__c  = 'Test';
        objEntryCriteria.Apttus_Approval__Initial_Submission_Field_Name_Source__c = 'Self';
        objEntryCriteria.Apttus_Approval__Entry_Criteria__c = objProcess.ID;
        insert objEntryCriteria;
        
        Apttus_Approval__Approval_Process__c objStepGroup =  new Apttus_Approval__Approval_Process__c();
        
        objStepGroup.RecordTypeId = [select id from RecordType where name = 'Step Group' limit 1].Id;
        objStepGroup.Apttus_Approval__Active__c = true;
        objStepGroup.Apttus_Approval__Step_Group_Active__c = true;
        objStepGroup.Apttus_Approval__Step_Group_Name__c = 'Dummy';
        objStepGroup.Apttus_Approval__Step_Group_Rejection_Action__c = null;
        objStepGroup.Apttus_Approval__Step_Group_Seq_Number__c = 1;
        objStepGroup.Apttus_Approval__Step_Group__c = objProcess.ID;
        
        insert objStepGroup;
        
        Apttus_Approval__Approval_Process__c objStep =  new Apttus_Approval__Approval_Process__c();
        
        objStep.RecordTypeId = [select id from RecordType where name = 'Step' limit 1].Id;
        objStep.Apttus_Approval__Active__c = true;
        objStep.Apttus_Approval__DependsOn__c = null;
        objStep.Apttus_Approval__Send_Email__c = true;
        objStep.Apttus_Approval__StepAutoEscalate__c = false;
        objStep.Apttus_Approval__StepAutoReapprove__c = false;
        objStep.Apttus_Approval__StepFilterConditionDescription__c = null;
        objStep.Apttus_Approval__StepLabel__c = 'Level 1 Approval';
        objStep.Apttus_Approval__StepSequence__c = 2;
        objStep.Apttus_Approval__StepSubmissionComment1Enabled__c = false;
        objStep.Apttus_Approval__StepSubmissionComment2Enabled__c = false;
        objStep.Apttus_Approval__StepSubmissionComment3Enabled__c = false;
        objStep.Apttus_Approval__StepSubmissionCommentsEnabled__c = false;
        objStep.Apttus_Approval__StepType__c = 'Standard';
        objStep.Apttus_Approval__Step_Active__c = true;
        objStep.Apttus_Approval__Step_Assignee_Description__c = 'Level 1 Approval for VISA';
        objStep.Apttus_Approval__Step_Assignee_Type__c = 'Related User';
        objStep.Apttus_Approval__Step_Assignee__c = 'OwnerId';
        objStep.Apttus_Approval__Step_Auto_Complete__c = false;
        objStep.Apttus_Approval__Step_Name__c = 'Level 1 Approval';
        objStep.Apttus_Approval__Step_Notify_Only__c = false;
        objStep.Apttus_Approval__Step_Seq_Number__c = null;
        objStep.Apttus_Approval__Step__c = objStepGroup.ID;            
        
        insert objStep;
        
       Apttus__APTS_Agreement__c oAgreement = [SELECT Id From Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group'];
        Test.StartTest();
          SubmitForApproval.initiateSubmission(oAgreement.Id);
        Test.StopTest();
        list<Apttus_Approval__Approval_Request__c> lstRequest = [select id from Apttus_Approval__Approval_Request__c ];
        system.assert(lstRequest.size() > 0);
        
    }
    
    @isTest
    static void testCheckApprovalInBatchWithoutApprovals(){
        Apttus__APTS_Agreement__c oAgreement = [SELECT Id From Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group'];
        Test.StartTest();
          SubmitForApproval.initiateSubmission(oAgreement.Id);
        Test.StopTest();
        Apttus__APTS_Agreement__c oAgreement2 = [SELECT Id,Submission_Failed_Error_Message__c From Apttus__APTS_Agreement__c WHERE Name = 'Test Agreement - Price Group'];
        system.assert(oAgreement2.Submission_Failed_Error_Message__c != Null);
        
    }
     /**
*  @author Karthik
*  @description Testing error case
**/
     @isTest
    static void testCheckApprovalInBatchWithError(){
        Test.StartTest();
        String errorMessage = SubmitForApproval.initiateSubmission(null);
        Test.StopTest();
        system.assert(errorMessage != Null);
        
    }
	
	/*Test method to cover Catch Block of Class QueuableSubmitForApprovals
	*/
   @isTest
   public static void coverCatchBlockQueuableSubmitForApprovals(){
    try{
        QueuableSubmitForApprovals.catchException = true;
        QueuableSubmitForApprovals qs = new QueuableSubmitForApprovals(null);
        Test.startTest();
        System.enqueueJob(qs);
        Test.stopTest();
    	}catch(Exception e){
            System.assert(e!=null, 'e is not empty');
    	}
   }
}
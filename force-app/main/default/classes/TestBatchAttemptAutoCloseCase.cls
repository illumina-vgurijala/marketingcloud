/***************************************************************************************************************************************
* NAME         : TestBatchAttemptAutoCloseCase
* DESCRIPTION  : Test class for BatchAttemptAutoCloseCase
* @AUTHOR      : 
* @DATE        : 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Pooja                 23-Sep-2022            CodeScan Fixes
****************************************************************************************************************************************/
 
@isTest
public class TestBatchAttemptAutoCloseCase {
    @IsTest
    static void testBatchAutoCloseCase(){
        Contact con = TestDataPerson.getNewContact(null);
        
        Profile prof = [select id from profile where name = 'Customer Service'];
        User user = new User();
        user.firstName = 'test1';
        user.lastName = 'test2';
        user.profileId = prof.id;
        user.username =  'test9732@testing.com';
        user.email = 'test9732@testing.com';
        user.CompanyName = 'TEST';
        user.Title = 'title';
        user.Alias = 'alias';
        user.TimeZoneSidKey = 'America/Los_Angeles';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.LocaleSidKey = 'en_US';
        insert user;
        
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.OwnerId = user.Id;
        insert cs;
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        wo.SVMXC__Order_Type__c='Service Activities';
        wo.Acceptance_Code__c = 'ACD: Acceptance Upon Delivery';
        wo.Is_Auto_Created__c = true;
        wo.OwnerId = user.Id;
        insert wo;
        System.assert(wo.Id != null);

        //insert product
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2;
        System.assert(toolProduct2.Id != null);
        //Insert Product Stock DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;  

        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = wo.id;
        workDetail1.SVMXC__Line_Type__c='Parts';
        workDetail1.SVMXC__Product__c = toolProduct2.Id;
        workDetail1.SVMXC__Is_Billable__c = false;
        workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        insert workDetail1;

        wo.SVMXC__Order_Status__c = 'Completed';
        wo.PO_Number__c ='67887'; 
        wo.WO_Completed_by__c = user.Id;
        wo.Attempt_case_completion__c = true;
        wo.Integration_Status__c = 'Not Required';
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c='Test';
        wo.Verification_Result__c='Test';
        wo.Has_Verification_Code__c = true;
        wo.Is_Service_Report_Generated__c = true;
		wo.Is_Customer_Sign_Captured__c = true;
		
        update wo; 
        Test.startTest();
           //String sch = '0 0 23 * * ?';
            BatchAttemptAutoCloseCase b = new BatchAttemptAutoCloseCase();
            //system.schedule('Test1121'+system.now(),sch,b); 
            String sch = '0 0 2 * * ?'; 
           system.schedule('Auto close Case', sch, b);
            Database.executebatch(b);
        Test.stopTest();
        
    }
    @IsTest
    static void testBatchAutoCloseCase1(){
        Contact con = TestDataPerson.getNewContact(null);
        
        Profile prof = [select id from profile where name = 'Customer Service'];
        User user = new User();
        user.firstName = 'test1';
        user.lastName = 'test2';
        user.profileId = prof.id;
        user.username =  'test9732@testing.com';
        user.email = 'test9732@testing.com';
        user.CompanyName = 'TEST';
        user.Title = 'title';
        user.Alias = 'alias';
        user.TimeZoneSidKey = 'America/Los_Angeles';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.LocaleSidKey = 'en_US';
        insert user;
		
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
        Case cs =  new Case();
		cs.RecordTypeId =  idCaseRecordTypeId;
		cs.AccountId = con.AccountId;
		cs.ContactId = con.Id;
		cs.Status = 'New';
		cs.Subject = 'test';
        cs.Origin = 'Phone';
		cs.Description = 'test';
		cs.Sub_Type__c = 'General Issue';
		cs.Category__c = 'Other';
		cs.Date_of_Issue_Awareness__c =  Date.Today();
		cs.Has_Analysis_Code__c = true;
		cs.Has_Resolution_Code__c = true;
        cs.OwnerId = user.Id;
		insert cs;

		SVMXC__Service_Order__c wo = [Select Id, SVMXC__Order_Type__c, Acceptance_Code__c, Is_Auto_Created__c, OwnerId, Owner.Email, SVMXC__Case__c, SVMXC__Case__r.RecordTypeId, SVMXC__Case__r.Case_Eligible_for_QA_Review__c, SVMXC__Case__r.CaseNumber From SVMXC__Service_Order__c WHERE SVMXC__Case__c =: cs.id ];

        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2;
        System.assert(toolProduct2.Id != null);
        //Insert Product Stock DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;  

        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = wo.id;
        workDetail1.SVMXC__Line_Type__c='Parts';
        workDetail1.SVMXC__Product__c = toolProduct2.Id;
        workDetail1.SVMXC__Is_Billable__c = false;
        workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        insert workDetail1;
		wo.OwnerId = user.Id;
        wo.SVMXC__Order_Status__c = 'Completed';
        wo.PO_Number__c ='67887'; 
		wo.SVMXC__Product__c = toolProduct2.Id;
        wo.WO_Completed_by__c = user.Id;
        wo.Attempt_case_completion__c = true;
        wo.Integration_Status__c = 'Not Required';
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c='Test';
        wo.Verification_Result__c='Test';
        wo.Has_Verification_Code__c = true;
        wo.Is_Service_Report_Generated__c = true;
		wo.Case_Follow_up_Needed__c = true;
		wo.Case_Next_Steps__c  ='test';
        //update wo; 
        Test.startTest();
           //String sch = '0 0 23 * * ?';
            BatchAttemptAutoCloseCase b = new BatchAttemptAutoCloseCase();
            //system.schedule('Test1121'+system.now(),sch,b); 
            String sch = '0 0 2 * * ?'; 
           system.schedule('Auto close Case', sch, b);
            Database.executebatch(b);
        Test.stopTest();
        
    }
}
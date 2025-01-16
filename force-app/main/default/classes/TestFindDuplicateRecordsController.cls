/**
 * NAME   : TestFindDuplicateRecordsController
 * DESCRIPTION  : TestClass for FindDuplicateRecordsController Apex Class
 *                 
 *    
 * @AUTHOR : Monika Parihar
 * @DATE   : 24-Aug-2020
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             9/21/2020             Modified version
 * Prem Ranjan           07-02-2022            CodeScan Fix - System.assertEquals instead of System.assert
 **/
@isTest(SeeAllData = false)
public class TestFindDuplicateRecordsController{
    public static final String STRING_CONTACT_OBJECT = 'Contact';
     /**
     * method:testUpdateAccount
     * descritpion: Test method for update account contact relations in contacts class.
     **/
    static testmethod void testfetchDuplicates(){
        //create duplicate scenario
        CRMfusionDBR101__Scenario__c scenario1 = new CRMfusionDBR101__Scenario__c();
        scenario1.Name='Scenario1';
        scenario1.CRMfusionDBR101__Match_on_Insert_Action__c='Do Nothing';
        scenario1.CRMfusionDBR101__Match_on_Update_Action__c='Do Nothing';
        scenario1.CRMfusionDBR101__Scenario_Type__c=STRING_CONTACT_OBJECT;
        //scenario1.CRMfusionDBR101__Deployed__c = true;
        scenario1.CRMfusionDBR101__Error_Message__c = 'Duplicates Found!!';
        scenario1.CRMfusionDBR101__Create_Task__c = 'No';
        insert scenario1;
        //create duplicate scenario rule
        CRMfusionDBR101__Scenario_Rule__c scenariorule1 = new CRMfusionDBR101__Scenario_Rule__c(CRMfusionDBR101__Scenario_Type__c=STRING_CONTACT_OBJECT,CRMfusionDBR101__Match_Field__c='LastName',CRMfusionDBR101__Mapping_Type__c='Exact',CRMfusionDBR101__Scenario__c=scenario1.id);
        insert scenariorule1;

        //dcp-41006

        Lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
        objLead.CountryCode='DE';
        objLead.Area_Of_Interest__c='Plant Testing';
        objLead.pi__score__c=2;
        objLead.Email_Verification_Date__c = Date.today();
        objLead.Email_Verification_Status__c = 'Verified Successfully';
        objLead.Is_AutoMerge_In_Progress__c = true;
        insert objLead;
        System.assert(objLead.Id != null);
        
        Test.StartTest();
        //create contacts
        Contact con1 = TestDataPerson.initContact(null);
        con1.LastName = 'LCon1';
        Contact con2 = TestDataPerson.initContact(null);
        con2.LastName = 'LCon1';
        insert con1;
        insert con2;
        Map<String,Object> mapDuplicates = new Map<String,Object>();
        mapDuplicates.put(con2.id,scenario1.id);
        //dcp-41006
        Map<String,Object> mapLeadDuplicates = new Map<String,Object>();
        mapLeadDuplicates.put(objLead.id,scenario1.id);

        FindDuplicateRecordsController.fetchDuplicates(con2.id);
        
        Id warningId = FindDuplicateRecordsController.createDuplicateWarnings(con2.id,mapDuplicates,STRING_CONTACT_OBJECT);
        System.assert(warningId != null);
        ////dcp-41006
        FindDuplicateRecordsController.createDuplicateWarnings(objLead.id,mapLeadDuplicates,'Lead');
        try{
            FindDuplicateRecordsController.fetchDuplicates(null);
        }catch(Exception e){
            System.assert(e.getMessage() != null);
        }
        try{
            FindDuplicateRecordsController.createDuplicateWarnings(con2.id,null,STRING_CONTACT_OBJECT);
        }catch(Exception e){
            System.assert(e.getMessage() != null);
        }
        //test coverage
        FindDuplicateRecordsController.getAutoActionMessageDetails(objLead.Id);
        Test.StopTest();

    }
	/*
	* Description: This methos is a test method for testing the merge request functionality.
	*/
    @isTest
    static void testSendMergeRequest(){
        Account account1 = TestDataAccount.getCustomerAccount();
        account1.BillingCountryCode = 'US';
        account1.BillingCountry = 'USA';
        insert account1;
        System.assert(account1.Id != null);
        //creation of contacts
        Contact con1 =TestDataPerson.initContact(account1.Id);
        insert con1;
        System.assert(con1.Id != null);

        //DCP-42099
        lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test2@gmail.com','USA','test1Company');
        objLead.CountryCode='US';
        objLead.Area_Of_Interest__c='Plant Testing';
        objLead.Is_AutoConversion_In_Progress__c = true;
        insert objLead;

        Test.startTest();
        Boolean success = FindDuplicateRecordsController.sendEmailMergeRequest(con1.Id, 'test commments');
        System.debug('success--:'+success);
        system.assertEquals(true,success,'Assert Failed');

        //DCP-42009
        FindDuplicateRecordsController.sendEmailMergeRequest(objLead.Id, 'test commments');
        //test coverage
        FindDuplicateRecordsController.getAutoActionMessageDetails(objLead.Id);
        Test.stopTest();
    }
    /*
	* Description: This methos is a test method for testing the lead merge & convert functionality.
	*/
    @isTest
    static void testLeadMerge(){
        Account objAcc =TestDataAccount.getAccount('TestSftware');
        objAcc.ERP_Customer_Id__c='8976';
        objAcc.Account_Group__c='Ultimate Consignee';
        insert objAcc;
        System.assert(objAcc.Id != null);

        Lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
        objLead.CountryCode='DE';
        objLead.Area_Of_Interest__c='Plant Testing';
        objLead.pi__score__c=2;
        objLead.Email_Verification_Date__c = Date.today();
        objLead.Email_Verification_Status__c = 'Verified Successfully';
        insert objLead;
        System.assert(objLead.Id != null);

        Contact objCon1=TestDataMarketing.createContactForMarketable('testfirstname','testlastname','test@gmail.com','USA');
        objCon1.mailingcountrycode='US';
        objCon1.AccountId = objAcc.Id;
        insert objCon1;
        System.assert(objCon1.Id != null);
        Test.startTest();
        FindDuplicateRecordsController.isMergeAccessGranted('Lead_Merge');
        try{
            FindDuplicateRecordsController.convertLead(objLead.Id, objCon1.Id);
        }catch(Exception e){
            system.assert(e.getMessage() != null);
        }
        Map<Id, String> mapLeads = new Map<Id, String>{objLead.Id => objLead.Id};
        Map<Id, String> mapContacts = new Map<Id, String>{objCon1.Id => objCon1.Id};
        FindDuplicateRecordsController.Response response = new FindDuplicateRecordsController.Response();
        FindDuplicateRecordsController.populateResponse(mapLeads, response);
        FindDuplicateRecordsController.populateResponse(mapContacts, response);
        FindDuplicateRecordsController.getAutoActionMessageDetails(objLead.Id);
        Test.stopTest();
    }
    /*
	* Description: This methos is a test method for testing permission set access related functionality.
	*/
    @isTest
    static void checkPermissionSet(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email='leadMerge@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='TestingMerge', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',UserName='testLeadMergeUser@testorg.com');
        insert u;
        System.assert(u.Id != null);
        // Create PermissionSet with Custom Permission and assign to test user
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test_Merge';
        ps.Label = 'Test Merge';
        insert ps;
        System.assert(ps.Id != null);
        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;

        Test.startTest();
        // Run your code with inserted user.
        System.runAs(u)
        {
            FindDuplicateRecordsController.isMergeAccessGranted('Test_Merge');
        }
        Test.stopTest();
    }
}
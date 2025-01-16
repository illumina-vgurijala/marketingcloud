/***************************************************************************************************************************************
 * NAME   : TestLeads
 * DESCRIPTION  : TestClass for Lead Trigger
 *                  Testing Pardot Resubscribe Functionality
 *
 * @AUTHOR : Pankaj Singla
 * @DATE   : 17-Sept-2018
 *
 * MODIFICATION LOG:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION
 * Rishab Wali			    17-Nov-2021         [DCP-50851] Clear Disposition Code if not recycled
 * Deep Diwakar             Nov-01-2023        CMCM-1521: SFDC-ULC integration retirement, removing test method related to this integration
 * Deep Diwakar             Nov-29-2023        CMCM-4510: Added test method for area of work field calculation
 * Deep Diwakar             Mar-07-2024        CMCM-5551: Removed old marketability test method
 * Deep Diwakar             May-22-2024        CMCM-7994: Removed Cvent opt in test method as logic is moved to different class 
 * Deep Diwakar             Jun-14-2024        CMCM-6457: Added test method for waterfall merge logic
 * Deep Diwakar             Jun-27-2024        CMCM-6457: Added test method for waterfall lead conversion logic
 * Deep Diwakar             Dec-10-2024        CMCM-12466: Adjusted test method to work with new Hand Raise Lead status
 * Deep Diwakar             Dec-17-2024        CMCM-12469: Added test method to test waterfall feature with new Hand Raise status
 * Deep Diwakar             Dec-18-2024        CMCM-12362: Updated test method to adjust for new disposition code values
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/


@isTest(SeeAllData = false)
public class TestLeads{

     static testMethod void testLeadAssignmentRules(){
         //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

         Lead ld=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
         System.assertEquals('testfirstname',ld.FirstName,'First name not set correctly');
         Test.StartTest();
         //Ld.Resubscribe_Request__c='Yes';
         Ld.HasOptedOutOfEmail=true;
         update Ld;
         Test.StopTest();

         cs_Apex_Settings__c cs=cs_Apex_Settings__c.getOrgDefaults();
         cs.Bypass_All_Validations__c=true;
         upsert cs cs_Apex_Settings__c.id;
                 Ld.Country='USA';
                Ld.LeadSource='CS Generated';
                Ld.Status='Marketing Qualified';
                update ld;

         Lead objLead=[select id,ownerid,owner.name from Lead where id=:Ld.id];
         system.debug('Lead is--'+objLead);
     }

     static testmethod void testSetLeadStatusAndLeadSource(){
        User objServiceUser = TestDataUser.findUserInProfile('Customer Service'),
            objOpsUser = TestDataUser.findUserInProfile('Commercial Ops Quoting User');
            User objSupportUser = TestDataUser.findUserInProfile('Technical Support');
            Lead objServiceLead = new Lead();
            Lead objSalesLead = new Lead();
            Lead objSupportLead = new Lead();
            Test.startTest();
            String strHashString,strHexDigest1,strHexDigest2,strHexDigest3;
            system.runAs(objServiceUser){
            strHashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
            Blob bbHash = Crypto.generateDigest('MD5', Blob.valueOf(strHashString));
            strHexDigest1 = EncodingUtil.convertToHex(bbHash);
            system.debug('##########' + strHexDigest1 );
             objServiceLead = TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1',strHexDigest1+'@test.com','Germany','test1Company');
              insert objServiceLead;
            }
            system.runAs(objOpsUser){
            strHashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
            Blob bbHash = Crypto.generateDigest('MD5', Blob.valueOf(strHashString));
            strHexDigest2 = EncodingUtil.convertToHex(bbHash);
            system.debug('##########' + strHexDigest2 );
             objSalesLead = TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname2',strHexDigest2+'@test.com','Germany','test1Company');
              insert objSalesLead;
            }

            system.runAs(objSupportUser){
            strHashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
            Blob bbHash = Crypto.generateDigest('MD5', Blob.valueOf(strHashString));
            strHexDigest3 = EncodingUtil.convertToHex(bbHash);
            system.debug('##########' + strHexDigest3 );
             objSupportLead = TestDataMarketing.createLeadForMarketable('testfirstname3','testlastname3',strHexDigest3+'@test.com','Germany','test1Company');
              insert objSupportLead;
            }
            String emailService=strHexDigest1+'@test.com';
            String emailSales=strHexDigest2+'@test.com';
            String emailSupport=strHexDigest3+'@test.com';
            objServiceLead = [SELECT Id,LeadSource FROM Lead WHERE Email = :emailService LIMIT 1];
            objSalesLead = [SELECT Id,LeadSource FROM Lead WHERE Email = :emailSales LIMIT 1];
            objSupportLead = [SELECT Id,LeadSource FROM Lead WHERE Email = :emailSupport LIMIT 1];

            Test.stopTest();
             system.assertEquals(Label.LeadSourceSalesGenerated,objSalesLead.LeadSource,'Lead Source not set correctly');
             system.assertEquals(Label.LeadSourceCSGenerated,objServiceLead.LeadSource,'Lead Source not set correctly');
             system.assertEquals(Label.LeadSourceCSGenerated,objSupportLead.LeadSource,'Lead Source not set correctly');
     }

     /*Method - To check if Status gets updated to Attended. */
     static testmethod void testCampaignAttendedStatus(){
            lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
            objLead.Webinar_Attended__c=true;
            objLead.Webinar_AttendedOnDemand__c=true;
            objLead.Seminar_Attended__c=true;
            objLead.Tradeshow_Attended__c=true;
            lead objLead2=TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname2','test2@gmail.com','Germany','test1Company');
            insert (new list<Lead>{objLead,objLead2});
            objLead2.Webinar_Attended__c=true;
            objLead2.Webinar_AttendedOnDemand__c=true;
            objLead2.Seminar_Attended__c=true;
            objLead2.Tradeshow_Attended__c=true;
            update objLead2;
     }


      static testmethod void testAOIFunctionality(){
         lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
         objLead.CountryCode='DE';
         objLead.Area_Of_Interest__c='Plant Testing';
         insert objLead;

         Lead ojLd=[select id,AOI_PLant_Testing__c,AOI_Agriculture_Research__c from lead where id=:objLead.id];
         system.assert(ojLd.AOI_PLant_Testing__c,'AOI Plant Testing field not set as true');
         system.assert(!ojLd.AOI_Agriculture_Research__c,'AOI Agriculture Field not set as false');
         objLead.Area_Of_Interest__c='Plant Testing;Agriculture Research';
         update objLead;
          ojLd=[select id,AOI_PLant_Testing__c,AOI_Agriculture_Research__c from lead where id=:objLead.id];
         system.assert(ojLd.AOI_PLant_Testing__c,'AOI Plant Testing field not set as true');
         system.assert(ojLd.AOI_Agriculture_Research__c,'AOI Agriculture Field not set as true');
     }

     static testmethod void testCharketFunctionality(){
      Leads.booTestRunning=true;
              Contact con=TestDataMarketing.createContact('testfirstname','testlastname','test1@gmail.com');
               system.assertEquals('test1@gmail.com',con.email,'Email not set correctly');
              lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
                 Test.StartTest();
                objLead.CountryCode='DE';
                objLead.Area_Of_Interest__c='Plant Testing';
                insert objLead;
                lead objLead2=TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname2','test1@gmail.com','Germany','test1Company');
                insert objLead2;
				Con.Email='abc@test2222.com';
				update con;
                objLead.Email='abc@test2222.com';
                update objLead;
                objLead2.Email='abc@test2222.com';
                update objLead2;

                lead objLead12=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','testxyz@gmail.com','Germany','test1Company');
                insert objLead12;

                lead objLead13=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','testxyz@gmail.com','Germany','test1Company');
                insert objLead13;
				Test.StopTest();
     }
    static testmethod void testRecycledScoring(){
        lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
        Test.StartTest();
        objLead.CountryCode='DE';
        objLead.Area_Of_Interest__c='Plant Testing';
        insert objLead;
        objLead.status='Recycled';
        objLead.Disposition_Code__c='No Response';
        update objLead;
        objLead=[select id,Marketing_Score__c from lead where id=:objLead.id];
        system.assertEquals(0, objLead.Marketing_Score__c,'Marketing Score not set correctly');
    }


    static testmethod void testLeadHighValueScoringCounter(){
         lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
         objLead.CountryCode='DE';
         objLead.Area_Of_Interest__c='Plant Testing';
         insert objLead;
         objLead.pi__score__c=2;
         update objLead;
         Lead objL=[select id,Marketing_Score__c,pi__score__c from lead where id=:objLead.id];
         system.debug('objLead is--'+objL);
         Integer intExpectedScore=2*Integer.valueOf(Label.High_Value_Scoring_factor);
        system.assertEquals(intExpectedScore,objL.Marketing_Score__c,'Marketing Score not set correctly');
    }
	 static testmethod void testLeadConvert(){
        account objAcc =TestDataAccount.getAccount('TestSftware');
        objAcc.ERP_Customer_Id__c='8976';
        objAcc.Account_Group__c='Ultimate Consignee';
        insert objAcc;

        lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
        objLead.CountryCode='DE';
        objLead.Area_Of_Interest__c='Plant Testing';
        objLead.pi__score__c=2;
        objLead.Email_Verification_Date__c = Date.today();
        objLead.Email_Verification_Status__c = 'Verified Successfully';
        insert objLead;
        Prospect_Scoring_Log__c obj=new Prospect_Scoring_Log__c();
        obj.lead__c=objLead.id;
        insert obj;
        Contact objCon1=TestDataMarketing.createContactForMarketable('testfirstname','testlastname','test@gmail.com','USA');
        objCon1.mailingcountrycode='US';
        insert objCon1;
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(objLead.id);
		lc.setAccountId(objAcc.id);
        lc.setContactId(objCon1.id);
		lc.setOwnerId(userinfo.getUserId());
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Lead Converted No Opp'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);
		Database.convertLead(lc);
        Map<Id,Id> mapLeadIdToContactId = new Map<Id,Id>{objLead.Id=>objCon1.Id}; 
        Leads.processConvertedRecordsForScoring(mapLeadIdToContactId);
		list<Prospect_Scoring_Log__c> lstLogRec=[select id from Prospect_Scoring_Log__c where contact__c=:objCon1.id];
        system.assertEquals(2, lstLogRec.size(),'Logs not created correctly');


    }
	static testmethod void testsendEmailAfterLeadAutoConvertandAutoMerge(){
        account objAcc =TestDataAccount.getAccount('TestSftware');
        objAcc.ERP_Customer_Id__c='8976';
        objAcc.Account_Group__c='Ultimate Consignee';
        insert objAcc;
        System.assert(objAcc.Id != null,'Account not created.');

        Contact objCon1=TestDataMarketing.createContactForMarketable('testfirstname','testlastname','test@gmail.com','USA');
        objCon1.mailingcountrycode='US';
        insert objCon1;
        System.assert(objCon1.Id != null,'Contact not created.');

        lead objLead=TestDataMarketing.createLeadForMarketable('testfirstname1','testlastname1','test1@gmail.com','Germany','test1Company');
        objLead.CountryCode='DE';
        objLead.Email_Verification_Date__c = Date.today();
        objLead.Email_Verification_Status__c = 'Verified Successfully';
        insert objLead;
        System.assert(objLead.Id != null,'Lead not created');

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(objLead.id);
        lc.setAccountId(objAcc.id);
        lc.setContactId(objCon1.id);
        lc.setOwnerId(userinfo.getUserId());

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Lead Converted No Opp'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);
        Database.convertLead(lc);

        lead objLead1=TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname2','test2@gmail.com','Germany','test2Company');
        objLead1.CountryCode='DE';
        objLead1.Email_Verification_Date__c = Date.today();
        objLead1.Email_Verification_Status__c = 'Verified Successfully';
        insert objLead1;
        System.assert(objLead1.Id != null,'Lead not created');

        Test.StartTest();
            Leads.sendEmailAfterLeadAutoConvertandAutoMerge(new List<Id>{objLead.id});
            Leads.sendEmailAfterLeadAutoConvertandAutoMerge(new List<Id>{objLead1.id});
        Test.StopTest();
    }

	static testmethod void testLeadForAutoTagging(){
		List<Charket__WeChatTag__c> lstTags=new List<Charket__WeChatTag__c>();
		Charket__WeChatTag__c objTag1=new Charket__WeChatTag__c();
		objTag1.name='Tag 1';
		objTag1.Charket__IsActive__c=true;
		objTag1.Area_of_Interest__c='Animal Testing';
		objTag1.Job_Function__c='Lab Staff';
		lstTags.add(objTag1);
		Charket__WeChatTag__c objTag2=new Charket__WeChatTag__c();
		objTag2.name='Tag 2';
		objTag2.Charket__IsActive__c=true;
		objTag2.Area_of_Interest__c='Agriculture Research';
		objTag2.Job_Function__c='Partner';
		lstTags.add(objTag2);

		Charket__WeChatTag__c objTag3=new Charket__WeChatTag__c();
		objTag3.name='Tag 3';
		objTag3.Charket__IsActive__c=true;
		objTag3.Area_of_Interest__c='Genetic Health';
		objTag3.Job_Function__c='Student';
		lstTags.add(objTag3);

		Insert lstTags;
		//system.runAs(u){
		Lead objLead1=TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname1','test2@gmail.com','Germany','test2Company');
         objLead1.CountryCode='DE';
         objLead1.Area_of_Interest__c='Animal Testing;Agriculture Research';
		 objLead1.Job_Function__c='Lab Staff';
         insert objLead1;
		 objLead1.Area_of_Interest__c='Genetic Health';
		 update objLead1;
		//}
		List<Charket__WeChatTagAssignment__c> lstTagsNew=[select id from Charket__WeChatTagAssignment__c LIMIT 1];
        system.assertEquals(0,lstTagsNew.size(),'List size not equal to expected.');


	}
	
	static testmethod void testUpdateMostRecentDate(){

        lead objLead = TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname2','test2@gmail.com','Germany','test2Company');
        insert objLead;
        objLead.Last_Responded_Campaign_Date__c = system.now()+5;
        objLead.pi__last_activity__c = system.now()+7;
        objLead.Date_Of_Last_Score_Change__c = system.now()+8;
        update objLead;
        Lead ld = [SELECT id,Most_Recent_Activity_Date__c FROM Lead WHERE Id =: objLead.Id];
        system.assert(String.isNotBlank(String.valueOf(ld.Most_Recent_Activity_Date__c)),'Most Recent Activity not set.');

    }

	/*Method - [DCP-50851] To check if disposition code gets cleared when updated and not in recycled status*/
	static testmethod void testClearDispositionCode()
	{
        lead objLead = TestDataMarketing.createLeadForMarketable('testfirstname2','testlastname2','test2@gmail.com','Germany','test2Company');
        insert objLead;
        objLead.Disposition_Code__c = 'Competitor';
        update objLead;
        Lead ld = [SELECT id,Disposition_Code__c FROM Lead WHERE Id =: objLead.Id];
        system.assert(String.isBlank(ld.Disposition_Code__c),'Disposition Code not cleared.');

    }

    @IsTest
    static void testAreaOfWork() {
        Lead leadInsert = TestDataMarketing.createLeadForMarketable('Aow', 'Testaow', 'aow_test@testing.com', 'USA', 'Aow Test Inc');
        leadInsert.Area_Of_Interest__c = 'Animal Testing';

        Lead leadUpdate = TestDataMarketing.createLead('Aow2', 'Testaow2', 'aow_test2@testing.com', 'USA', 'Aow Test 2 Inc');
        leadUpdate.Area_Of_Interest__c = 'Genetic Health';

        Test.startTest();
        insert leadInsert;
        update leadUpdate;
        Test.stopTest();

        Lead resultLeadInsert = [SELECT Id, Area_Of_Work__c, Area_Of_Interest__c FROM Lead WHERE Id =: leadInsert.Id];
        Lead resultLeadUpdate = [SELECT Id, Area_Of_Work__c, Area_Of_Interest__c FROM Lead WHERE Id =: leadUpdate.Id];

        Assert.areEqual('Agrigenomics', resultLeadInsert.Area_Of_Work__c, 'Area of work field did not set correctly');
        Assert.areEqual('Genetic Disease Testing', resultLeadUpdate.Area_Of_Work__c, 'Area of work field did not set correctly');

    }

    @isTest
    static void testWaterfallMerge() {
        Lead testWinnerLead = TestDataMarketing.createLead('Win1', 'Merge1', 'win_merge1@testing.com', 'USA', 'Win Merge 1 Inc');
        Lead testLooserLead = TestDataMarketing.createLead('Loose2', 'Merge2', 'loose_merge2@testing.com', 'USA', 'Loose Merge 2 Inc');

        testWinnerLead.Last_Responded_Campaign_Date__c = System.Now();

        testLooserLead.Status = 'Marketing Qualified';

        update new List<Lead> {testWinnerLead, testLooserLead};

        Test.startTest();

        merge testWinnerLead testLooserLead;
        Test.stopTest();

        Lead resultWinLead = [SELECT Id, Waterfall_Stage__c, Waterfall_Qualified_Date__c FROM Lead WHERE Id =: testWinnerLead.Id];

        Assert.areEqual('Qualified', resultWinLead.Waterfall_Stage__c, 'Waterfall stage did not set correctly after merging leads');
        Assert.isNotNull(resultWinLead.Waterfall_Qualified_Date__c, 'Waterfall data did not set correctly after merging leads');

    }

    @isTest
    static void testWaterfallForLeadConversion() {

        account objAcc =TestDataAccount.getAccount('TestSftware');
        objAcc.ERP_Customer_Id__c='8976';
        objAcc.Account_Group__c='Ultimate Consignee';
        insert objAcc;

        Lead testLead = TestDataMarketing.createLead('Win1', 'Merge1', 'win_merge1@testing.com', 'USA', 'Win Merge 1 Inc');
        Contact testContact = TestDataMarketing.createContact('TestWin', 'TestMerge1', 'testwinmerge1@testing.com', 'US');
        testContact.AccountId = objAcc.Id;

        testContact.Last_Responded_Campaign_Date__c = System.Now();

        testLead.Status = 'Marketing Qualified';
        testLead.Email_Verification_Date__c = Date.today();
        testLead.Email_Verification_Status__c = 'Verified Successfully';

        update testLead;

        // Bypass recursion check because test method runs in single transaction and skips waterfall logic
        Leads.boolCheckRecursionForLeadStatus = false;
        update testContact;

        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.id);
		lc.setAccountId(objAcc.id);
        lc.setContactId(testContact.Id);
		lc.setOwnerId(userinfo.getUserId());
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true and MasterLabel='Lead Converted No Opp'];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);
		Database.convertLead(lc);

        Test.stopTest();
        
        Contact resultCont = [Select Id, AccountId, waterfall_stage__c From Contact where Id =: testContact.Id];

        Assert.areEqual('Qualified', resultCont.waterfall_stage__c, 'Lead conversion for waterfall did not work' );

    }

    @isTest
    static void testWaterfallHandRaiseStatus() {
        Lead testLeadHR = TestDataMarketing.createLeadForMarketable('Hand', 'Raise', 'hand_raise@testing.com', 'USA', 'Hand Raise Test Inc');
        testLeadHR.Contact_Me__c = true;

        insert testLeadHR;

        BatchLeadStatusUpdate batchJob = new BatchLeadStatusUpdate();

        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();

        Lead resultLead = [Select Id, Status, Date_Status_Set_As_Hand_Raise__c, Waterfall_Stage__c From Lead WHERE Id =: testLeadHR.Id];

        Assert.areEqual('Hand Raise', resultLead.Status, 'Lead status did not set correctly');
        Assert.areEqual(Date.today(), resultLead.Date_Status_Set_As_Hand_Raise__c, 'Lead field Date_Status_Set_As_Hand_Raise__c did not set correctly');
        Assert.areEqual('Engaged', resultLead.Waterfall_Stage__c, 'Lead waterfall stage did not set correctly for hand raise status');

    }

}
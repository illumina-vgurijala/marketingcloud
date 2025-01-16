/***************************************************************************************************************************************
 * NAME   : TestContacts
 * DESCRIPTION  : TestClass for Contact Trigger
 *                  Testing Pardot Resubscribe Functionality
 *
 * @AUTHOR : Pankaj Singla
 * @DATE   : 17-Sept-2018
 *
 * MODIFICATION LOG:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION
 * Rishab Wali			    17-Nov-2021         [DCP-50851] Clear Disposition Code if not recycled
 * Deep Diwakar             17-Dec-2021         DCP-37684: Added test method for OpenQ Lead Source setup story
 * saddam                   08-FEB              PM-57 : Added test method for iscontactisactive() method
 * Deep Diwakar             25-Sept-2022        PM-911: Added test method to test contact resignation change and corresponding callout
 * Deep Diwakar             July-12-2023        DCP-60096: Updated test method - testResignedNotification for this story 
 * Deep Diwakar             Aug-08-2023         DCP-60130: Added test method for Charket user bypass check
 * Deep Diwakar             Nov-01-2023         CMCM-1521: SFDC-ULC integration retirement, removing test method related to this integration
 * Deep Diwakar             Dec-04-2023         CMCM-4856: Added test method for area of work field calculation
 * Deep Diwakar             Mar-07-2024         CMCM-5551: Removed old marketability test methods
 * Deep Diwakar             May-22-2024         CMCM-7994: Removed Cvent opt in test method as logic is moved to different class 
 * Deep Diwakar             Jun-14-2024         CMCM-6457: Added test method for waterfall merge logic
 * Deep Diwakar             Dec-06-2024         CMCM-12466: Added and updated test methods for new Hand Raise status
 * Deep Diwakar             Dec-17-2024         CMCM-12469: Updated test method to test waterfall feature with new Hand Raise status
 * Deep Diwakar             Dec-18-2024         CMCM-12362: Updated test method to adjust for new disposition code values
 * --------------------------------------------------------------------------------------------------------------------------------------
 ****************************************************************************************************************************************/
@isTest(SeeAllData = false)
public class TestContacts{
    static testMethod void testBeforeInsert(){
        Contact con=TestDataMarketing.createContact('testfirstnameing','testlastnameing','test@gmail.com');
        System.assertEquals('testfirstnameing',con.FirstName,'First name not correct');
        Test.StartTest();
        //con.Resubscribe_Request__c='Yes';
        con.HasOptedOutOfEmail=true;
        update con;
        Test.StopTest();
    }
    static testmethod void testCampaignAttendedStatus(){
        Contact objCon1=TestDataMarketing.createContactForMarketable('testfirstname','testlastname','test@gmail.com','USA');
        objCon1.mailingcountrycode='US';
        objCon1.Webinar_Attended__c=true;
        objCon1.Webinar_AttendedOnDemand__c=true;
        objCon1.Seminar_Attended__c=true;
        objCon1.Tradeshow_Attended__c=true;
        Contact objCon2=TestDataMarketing.createContactForMarketable('testfirstname2','testlastname2','test2@gmail.com','USA');
        objCon2.mailingcountrycode='US';
        insert (new list<Contact>{objCon1,objCon2});
        objCon2.Webinar_Attended__c=true;
        objCon2.Webinar_AttendedOnDemand__c=true;
        objCon2.Seminar_Attended__c=true;
        objCon2.Tradeshow_Attended__c=true;
        update objCon2;
        System.assertEquals('testlastname',objCon1.LastName,'Last name set incorrectly');
    }
    static testmethod void testAOIFunctionality(){
        Contact objCon1=TestDataMarketing.createContactForMarketable('testfirstname','testlastname','test@gmail.com','USA');
        objCon1.mailingcountrycode='US';
        objCon1.Area_Of_Interest__c='Plant Testing';
        insert objCon1;
        Contact ojCon=[select id,AOI_PLant_Testing__c,AOI_Agriculture_Research__c from Contact where id=:objCon1.id];
        system.assert(ojCon.AOI_PLant_Testing__c,'AOI Plant Testing not checked');
        system.assert(!ojCon.AOI_Agriculture_Research__c,'AOI Agriculture Research not checked');
        ojCon.Area_Of_Interest__c='Plant Testing;Agriculture Research';
        update ojCon;
        ojCon=[select id,AOI_PLant_Testing__c,AOI_Agriculture_Research__c from Contact where id=:objCon1.id];
        system.assert(ojCon.AOI_PLant_Testing__c,'AOI Plant Testing not checked');
        system.assert(ojCon.AOI_Agriculture_Research__c,'AOI Agriculture Research not checked');
    }

    static testmethod void testCharketFunctionality() {
            Test.startTest();
            Contacts.booTestRunning=true;
            Contact testcontact=TestDataMarketing.createContact('supportfirstname','supportlastname','test1@gmail.com');
            Contact testcontact2=TestDataMarketing.createContact('testfirstname2','testlastname2','test1@gmail.com');
            set<id> conIds = new set<Id>();
            conIds.add(testcontact.id);
            conIds.add(testcontact2.id);
            List<Contact> lstCon=[select id from Contact where Id IN:conIds limit 3];  //codescanfix
            system.assertNotEquals(Null,lstCon.size(),'contacts not created');
            Test.stopTest();
    }

    static testmethod void testRecycledScoring(){
        List<RecordType> obj=[select id,name,developerName from recordType where sobjecttype='Contact' and developerName='Standard_Contact'];
         Id recordTypeId;
         if(!obj.isEmpty()){
            recordTypeId=obj[0].id;
         }
        Contact con=TestDataMarketing.createContact('testfirstname','testlastname','test1@gmail.com');
        Con.Marketing_Contact_Status__c='Recycled';
        Con.Disposition_Code__c='No Response';
        Con.recordTypeId=recordTypeId;
        update con;
        con=[select id,Marketing_score__c from Contact where Id=:con.id];
        system.assertEquals(0, Con.Marketing_Score__c,'Marketing Score is not 0.');
    }
    static testmethod void testHighValueScoring(){
        Contact con=TestDataMarketing.createContact('testfirstname','testlastname','test1@gmail.com');
        Con.pi__score__c=2;
        update con;
        Integer intExpectedScore=2*Integer.valueOf(Label.High_Value_Scoring_factor);
        Contact objC=[select id,Marketing_Score__c,pi__score__c from Contact where id=:Con.id];
        system.assertEquals(intExpectedScore,objC.Marketing_Score__c,'Marketing Score not equal to expected.');
    }
    /**
     * method:testMergeContacts
     * descritpion: Test method for onAfterDelete in contacts class.
     **/
    static testmethod void testMergeContacts(){
        //creation of accounts
        Account account1 = TestDataAccount.getCustomerAccount();
        Account account2 = TestDataAccount.getCustomerAccount();
        insert new List<Account> {account1, account2};
        System.assert(account1.Id != null,'Account not created.');
        //creation of contacts
        Contact con1 =TestDataPerson.initContact(account1.Id);
        Contact con2 = TestDataPerson.initContact(account2.Id);
        Contact con3 = TestDataPerson.initContact(account2.Id);
        insert new List<Contact> {con1, con2,con3};
        System.assert(con1.Id != null,'Contact not created.');
        AccountContactRelation  acr = [Select Id from AccountContactRelation where contactId =: con2.Id];
        acr.Roles = 'BioInformatics';
        update acr;

        //start test
        Test.startTest();
        merge con1 con2;
        merge con1 con3;

        List<AccountContactRelation> lstACR = [Select Id,Roles from AccountContactRelation where contactId =:con1.Id];
        System.assertEquals(2,lstACR.size(),'Account Contact Relation List size is not as expected');
        Map<Id, String> mapContactRoles = new Map<Id, String>();
        Map<Id, String> mapContactPNC = new Map<Id, String>();
        mapContactRoles.put(con1.Id, 'BioInformatics');
        mapContactPNC.put(con1.Id, 'Arrays');
        Contacts.handleExistingACRRelns(con1, mapContactRoles, mapContactPNC, lstACR[0]);
        Test.stopTest();
    }
     /**
     * method:testUpdateAccount
     * descritpion: Test method for update account contact relations in contacts class.
     **/
    static testmethod void testUpdateAccountContactRelns(){
        //creation of accounts
        Account account1 = TestDataAccount.getCustomerAccount();
        Account account2 = TestDataAccount.getCustomerAccount();
        insert new List<Account> {account1, account2};
        System.assert(account1.Id != null,'Account not created');
        //creation of contacts
        Contact con1 =TestDataPerson.initContact(account1.Id);
        insert new List<Contact> {con1};
        System.assert(con1.Id != null,'Contact not created');
        //start test
        Test.startTest();
        con1.AccountId = account2.Id;
        update con1;
        List<AccountContactRelation> lstACR = [Select Id,AccountId,ContactId from AccountContactRelation where contactId =:con1.Id];
        System.assertEquals(2,lstACR.size(),'Account Contact Relation List size is not as expected');
        Test.stopTest();
    }

    static testmethod void testContactForAutoTagging(){
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

        Contact objCon1=TestDataMarketing.createContactForMarketable('testfirstname','testlastname','test@gmail.com','USA');
        objCon1.mailingcountrycode='US';
        objCon1.Area_of_Interest__c='Animal Testing;Agriculture Research';
        objCon1.Job_Function__c='Lab Staff';
        insert objCon1;
        objCon1.Area_of_Interest__c='Genetic Health';
        update objCon1;
		 list<contact> lst1=new List<Contact>();
		lst1.add(objCon1);
		CharketUtils.processContactsForWeChatTagging(lst1);
		List<Charket__WeChatTagAssignment__c> lstTagsNew=[select id from Charket__WeChatTagAssignment__c LIMIT 1];
        system.assertEquals(0,lstTagsNew.size(),'List size not equal to 0');

    }

	 /*
   PM-57 : Added test method for  checkContactIsActive()
 */
    @istest
    static void testcheckcontactiactive() {

        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        //Create Account
        Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
        Insert objAccount;

        //Create Contact
        Contact objContactold = TestDataContact.getNewContact(objAccount);
        objContactold.is_active__c=true;
        objContactold.Email = 'test1@gmail.com';

        Contact objContactnew =TestDataContact.getNewContact(objAccount);
        objContactnew.is_active__c=false;
        objContactnew.id =objContactold.id;
        objContactnew.Email ='test2@gmail.com';
        update objcontactnew;

        List<contact> listOfNewContacts = [SELECT id, is_active__c,Email FROM Contact WHERE id =: objContactnew.id];
        //Creating User
        User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{Id.valueOf(UserInfo.getUserId())});
        TestDataUser.allowUserCreation(objUser1.Id);
        Id kolRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('KOL').getRecordTypeId();
        ilib_LogEvent.message('kolRecordTypeId-->: '+kolRecordTypeId);
        test.startTest();
        contacts.checkContactIsActive(objcontactnew,objContactold,kolRecordTypeId);
        system.assert(!listOfNewContacts.isEmpty(),'Contact is not updated');
        test.stopTest();
    }

    /*Method - [DCP-50851] To check if disposition code gets cleared when updated and not in recycled status*/
	static testMethod void testClearDispositionCode()
    {
        Contact objContact = TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
        objContact.Disposition_Code__c = 'Competitor' ;
        objContact.Marketing_Contact_Status__c = 'Marketing Qualified';
        update objContact;

        Contact con = [SELECT id,Disposition_Code__c FROM Contact WHERE Id =: objContact.Id];
        system.assert(String.isBlank(con.Disposition_Code__c),'Disposition code not cleared.');

    }

   /**
   * DCP-37684: Adding test method for OpenQ Lead Source setup story.
   */
  @isTest
  static void testOpenQLeadSource() {

      // get KOL record type Id for contact
      Id kolRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('KOL').getRecordTypeId();
      Contact openqcont = new Contact(FirstName = 'OpenQ', LastName = 'LeadSource', Email = 'openq_leadsource@test.com', RecordTypeId = kolRecordTypeId);
      Test.startTest();
      insert openqcont;
      Contact resultCont = [Select Id, LeadSource From Contact where Id =: openqcont.Id];
      Test.stopTest();
      System.assertEquals('Key Opinion Leader', resultCont.LeadSource, 'Lead Source not correctly set for OpenQ - KOL contact');

  }

  /**
   * @author: Deep Diwakar
   * @date: 23-Sept-2022
   * @description: Test method for PM-911 changes
   * @param: NA
   * @return: NA
   */
    @isTest
    static void testResignedNotification() {
      Contact testCont = TestDataMarketing.createContact('Pardot', 'Resignation', 'pardot_resig@test.com');

      // Setting up mock response for Resignation Form Handler.
      // Reusing Sync Attribution Form Handler response as Pardot Form Hanlder response remains exactly same
      StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
      mock.setStaticResource('PardotSynCampaignAttributionMoc');
      mock.setStatusCode(200);
      mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
      // Associate the callout with a mock response
      Test.setMock(HttpCalloutMock.class, mock);

      Test.startTest();
      testCont.Resigned_R_Q__c = true;
      update testCont;
      // publish platform event
      Test.getEventBus().deliver();
      Test.stopTest();

      Contact contUpdated = [Select Id, Resigned_R_Q__c From Contact where Id =: testCont.Id];
      System.assert(contUpdated.Resigned_R_Q__c, 'Contact did not update resigned r q field');

      // query interface log to check result
      Interface_Log__c log = [Select Id, Interface_Name__c, Result__c From Interface_Log__c where Interface_Name__c = 'PardotResignationNotificationSender'];
      System.assertEquals('Success', log.Result__c, 'PardotResignationNotificationSender queueable did not work correctly!');

  }

  @isTest
  static void testCharketContactCreation() {
    User charketUser = [SELECT Id, Name FROM User WHERE Name = 'Charket User' LIMIT 1];

    Contact testCharketContact;

    System.runAs(charketUser) {
        Test.startTest();
        testCharketContact = TestDataMarketing.createContact('Testcharcontfirst', 'Testcharcontfirst', 'testcharcont@testchar.com', 'CN');
        Test.stopTest();
    }

    Contact resultCont = [SELECT Id, FirstName, FirstNameLocal, LastNameLocal FROM Contact WHERE Id =: testCharketContact.Id];
    Assert.areEqual('Testcharcontfirst', resultCont.FirstName, 'Charket user did not create contact correctly');

  }

   /**
     * @author: Deep Diwakar
     * @date: Dec-04-2023 
     * @description: Test method for contact area of work field. More test methods for this functionality are in
     *               TestAreaOfWorkContactDecorator class
     * @param: none
     * @return: void
     */
    @IsTest
    static void testAreaOfWork() {

        //Create Account
        Account testAcct = TestDataAccount.getCustomerAccount();
        testAcct.Market_Segment__c = null;
        insert testAcct;

        Market_Segment__c objMarketSegment1 = new Market_Segment__c(Market_Segment__c = 'Agrigenomics',Account__c=testAcct.Id,
                                                    Market_Sub_Segment__c='Plant Testing',Percent_Allocation__c = 20);
        Market_Segment__c objMarketSegment2 = new Market_Segment__c(Market_Segment__c = 'Financial Services',Account__c=testAcct.Id,
                                                        Percent_Allocation__c = 50);
        Market_Segment__c objMarketSegment3 = new Market_Segment__c(Market_Segment__c = 'Oncology Testing',Account__c=testAcct.Id,
                                                        Percent_Allocation__c = 30);

        insert new List<Market_Segment__c> {objMarketSegment1, objMarketSegment2, objMarketSegment3};

        Contact testContInsert = TestDataPerson.initContact(testAcct.Id);

        Contact testContUpdate = TestDataPerson.getNewContact(testAcct.Id);

        testContUpdate.Area_Of_Work__c = 'Agrigenomics';

        Test.startTest();
        insert testContInsert;
        update testContUpdate;
        Test.stopTest();

        // validate results
        Contact resultInsert = [Select Id, Area_Of_Work__c From Contact where Id =: testContInsert.Id LIMIT 1];
        Contact resultUpdate = [Select Id, Area_Of_Work__c From Contact where Id =: testContUpdate.Id LIMIT 1];


        Assert.areEqual('Oncology Testing', resultInsert.Area_Of_Work__c, 'Contact market segment did not set correctly for insert');
        Assert.areEqual('Agrigenomics', resultUpdate.Area_Of_Work__c, 'Contact market segment did not set correctly for update');

    }

    @isTest
    static void testWaterfallMerge() {
        Contact testWinnerContact = TestDataMarketing.createContact('TestWin', 'TestMerge1', 'testwinmerge1@testing.com', 'US');
        Contact testLooserContact = TestDataMarketing.createContact('TestLoose', 'TestMerge2', 'testwinmerge2@testchar.com', 'US');

        testWinnerContact.Last_Responded_Campaign_Date__c = System.Now() - 3;

        testLooserContact.Marketing_Contact_Status__c = 'Marketing Qualified';
        testLooserContact.Last_Responded_Campaign_Date__c = System.Now();

        update new List<Contact> {testWinnerContact, testLooserContact};

        Test.startTest();

        merge testWinnerContact testLooserContact;
        Test.stopTest();

        Contact resultWinContact = [SELECT Id, Waterfall_Stage__c, Waterfall_Qualified_Date__c FROM Contact WHERE Id =: testWinnerContact.Id];

        Assert.areEqual('Qualified', resultWinContact.Waterfall_Stage__c, 'Waterfall stage did not set correctly after merging Contacts');
        Assert.isNotNull(resultWinContact.Waterfall_Qualified_Date__c, 'Waterfall data did not set correctly after merging Contacts');

    }

    @isTest
    static void testHandRaiseFieldSetup() {

        //Contact testHrContact = TestDataMarketing.createContact('Hand', 'Raise', 'handraise@testing.com', 'US');
        // createContactForMarketable
        Contact testHrContact = TestDataMarketing.createContactForMarketable('Hand', 'Raise', 'handraise@testing.com', 'US');

        testHrContact.Contact_Me__c = true;
        insert testHrContact;

        BatchContactStatusUpdate batchJob = new BatchContactStatusUpdate();

        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();

        Contact resultCont = [Select Id, Marketing_Contact_Status__c, Date_Status_Set_As_Hand_Raise__c, Waterfall_Stage__c From Contact WHERE Id =: testHrContact.Id];

        Assert.areEqual('Hand Raise', resultCont.Marketing_Contact_Status__c, 'Contact status did not set correctly');
        Assert.areEqual(Date.today(), resultCont.Date_Status_Set_As_Hand_Raise__c, 'Contact field Date_Status_Set_As_Hand_Raise__c did not set correctly');
        Assert.areEqual('Engaged', resultCont.Waterfall_Stage__c, 'Contact waterfall stage did not set correctly for hand raise status');

    }

}
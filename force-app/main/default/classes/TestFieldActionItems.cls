/***************************************************************************************************************************************
 * NAME   : TestFieldActionItems
 * DESCRIPTION  : TestClass for FieldActionItems Trigger
 *         
 *    
 * @AUTHOR : Debanka
 * @DATE   : 09-Sept-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Debanka            09-Sept-2018             Initial Version
  ****************************************************************************************************************************************/ 
  @isTest(SeeAllData = false) 
  public class TestFieldActionItems {
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';

      static Case cs;
      static Field_Action_Notification__c recFAN;
      @testSetup
  
      /*
       * description - initializeTestData method
       * return - void
       */     
      public static void initializeTestData() {
          cs = TestDataCase.initNewCase('Business Issue', 'Initiated', 'Phone - Field');
          cs.Date_of_Issue_Awareness__c = Date.Today();
          insert cs;
          // To create a FAN record of record type "Notification"
          recFAN = TestDataFieldService.createFAN('Notification');
          insert recFAN;
      }
      
      /*
       * description - newFieldActionItem method
       * return - void
       */     
      public static testMethod void newFieldActionItem(){
          initializeTestData();
          // To create a new FAI record With FAN record type "Notification"
          Field_Action_Item__c recFAI = TestDataFieldService.createFAI(cs.Id, recFAN.Id);
          Test.StartTest();
          insert recFAI;
          // To create a second FAI record with FAN record type "Notification"
          Field_Action_Item__c recFAI1 = TestDataFieldService.createFAI(cs.Id, recFAN.Id);
          try{
              insert recFAI1;
          }
          catch(DmlException e) {
              system.assert(e.getMessage().contains(system.label.FANTriggerErrorMessage));
          }
          Test.StopTest();
      }
      
      /*
       * description - testUpdateFieldActionItemTriggerHandler method 
       * return - void
       */
      @isTest
        public static void testUpdateFieldActionItemTriggerHandler(){
            // Set up the test user with the appropriate profile
            Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Integration SAP Service' LIMIT 1];
            User testUser = new User(
                Username = 'testuser1234@examillu.com',
                Email = 'testuser@example.com',
                LastName = 'TestIllu',
                Alias = 'test',
                ProfileId = testProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                IsActive = true
            );
            insert testUser;

            // Set the context user to the test user
            System.runAs(testUser) {
                // Create an installed product
                SVMXC__Installed_Product__c insproduct = new SVMXC__Installed_Product__c();
                insproduct.Name = 'Test install product';
                insproduct.SVMXC__Status__c = 'Installed';
                insert insproduct;
                
                // Create a product
                Product2 prod = new Product2();
                prod.Name = 'Test Product';
                insert prod;
                
                Case cs = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
                cs.SVMXC__Component__c = insproduct.Id;
                cs.SVMXC__Product__c = prod.Id;
                cs.Status = 'New'; // Set to a status that won't trigger the validation
                cs.Date_of_Issue_Awareness__c = Date.Today();  
                Cases.skipCaseTrigger = true;
                insert cs;
                
                // Create a Field Action Item related to the case
                Field_Action_Item__c fieldAction = new Field_Action_Item__c();
                fieldAction.Case__c = cs.Id;
                insert fieldAction;

                // Assert the Installed Product and Product are correctly set
                Field_Action_Item__c fieldActionRetrieved = [SELECT Installed_Product__c, Product__c FROM Field_Action_Item__c WHERE Id = :fieldAction.Id];
                System.assertEquals(insproduct.Id, fieldActionRetrieved.Installed_Product__c);
                System.assertEquals(prod.Id, fieldActionRetrieved.Product__c);
            }
        }
  }
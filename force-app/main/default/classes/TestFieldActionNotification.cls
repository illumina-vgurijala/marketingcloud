/**
* @File Name : TestFieldActionNotification.cls
* @Description : TestClass for Field_Action_Notification__c : After Insert and Update Flow
* @Author : Dhairya Shah
* @Last Modified By : Dhairya Shah
* @Last Modified On : December 2, 2024
**/
@isTest(seeAllData = false)
public class TestFieldActionNotification {
	public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    public static final string STRING_FAN_RECORDTYPENAME = 'Tracking Escalation';
    public static final string STRING_FAN_SUBJECT = 'Testing Tracking Escalation';
    public static final string STRING_FAN_STATUS = 'Closed';
    public static final string STRING_IP_STATUS = 'Installed';
    
    static Field_Action_Notification__c recFAN;

	static testMethod void testFieldActionNotificationMethod(){
	
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
            insproduct.SVMXC__Status__c = STRING_IP_STATUS;
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

            // To create a FAN record of record type "Notification"
            recFAN = TestDataFieldService.createFANForTE(STRING_FAN_RECORDTYPENAME, STRING_FAN_SUBJECT,STRING_FAN_STATUS);
            recFAN.Original_Case__c = cs.Id;
            recFAN.Severity__c = 'Low';
            recFAN.Escalation_Type__c = 'Array Consumables';
            recFAN.Symptom__c = 'Test';
            recFAN.Customer_Messaging__c = 'Test';
            recFAN.Requested_Information__c = 'Test';
            recFAN.Mitigations__c = 'Test';
            recFAN.Affected_Product__c = 'Test';
            recFAN.Suspected_Causes_Experiments_Done__c = 'Test';

            Test.StartTest();
            insert recFAN;
            Test.StopTest();
            
            Field_Action_Notification__c fieldActionRetrieved = [SELECT Resolution_Date__c, Status__c FROM Field_Action_Notification__c WHERE Id = :recFAN.Id];
            if(System.today() < fieldActionRetrieved.Resolution_Date__c){
                System.assertEquals(System.today().addDays(1), fieldActionRetrieved.Resolution_Date__c,'Resolution date should be today');
            } else {
                System.assertEquals(System.today(), fieldActionRetrieved.Resolution_Date__c,'Resolution date should be today');
            }
           
        }
	}
}
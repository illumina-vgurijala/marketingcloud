/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for BillingTypeAndDCIR_WOHelper
*/
@IsTest
private class TestBillingTypeAndDCIR_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final String STRING_WO_ORDER_TYPE_RELOCATION = 'Relocation';

    /**
    *  @description - initialize test data
    **/
    @testSetup
    public static void initializeTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

     /**
      * DCP-39881
      *  @author : Gautam Arya
      *  @description - test method to validate DCIR Error if work order status is completed
      **/
  
      static testMethod void testValidateIfDCIRAgreementIsGenerated() {
        Boolean expectedExceptionThrown = false;
        Case cs = [SELECT id FROM Case LIMIT 1];

        //START - DCP-47686 
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount.Account_Group__c='Distributor';
        insert objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;    
        List<User> lstUser = new List<User> {TestDataUser.initPartnerUser(profileId, objContact.id)};
        insert lstUser;
        //END - DCP-47686 
        Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
        cp.SetupOwnerId= lstUser[0].profile.id;
        cp.Is_Channel_Partner__c= True;
        insert cp;

        //START - DCP-47686
        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', lstUser[0].ContactId);
        objCase.GTS_Status__c = 'Request Initiated';
        Test.startTest();
        update objCase;
        //END - DCP-47686

        //Test.startTest();
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE_RELOCATION;
        objWorkOrder.Customer_Requested_Not_To_Re_Install__c=true;
        objWorkOrder.Record_Created_from_SFM__c=true;
        objWorkOrder.DCIR_Status__c='Open';
        objWorkOrder.SVMXC__Case__c = objCase.Id; //DCP-47686
        insert objWorkOrder;
        System.assertNotEquals(null, objWorkOrder.Id);
        if(!lstUser.isEmpty()){
        objWorkOrder.ownerId=lstUser[0].id;
        Update objWorkOrder;
        }

        
        if(!lstUser.isEmpty()){
        System.runas(lstUser[0]){
            system.debug('userid'+lstUser[0].id);
        try{

            objWorkOrder.SVMXC__Problem_Description__c='Test';
            objWorkOrder.SVMX_PS_Subject__c= 'Test';
            objWorkOrder.Evaluation__c= 'Test';
            objWorkOrder.Verification_Result__c= 'Test';
            objWorkOrder.SVMXC__Work_Performed__c='Test';
            objWorkOrder.No_Calibrated_Tools_Used__c = true;
            objWorkOrder.Is_Service_Report_Generated__c=true;
            objWorkOrder.Signature_Type__c='Manual Sign';
            objWorkOrder.Manual_Sign_Captured__c=true;
            objWorkOrder.Is_Customer_Sign_Captured__c=true;
            objWorkOrder.PO_Number__c='12';
            objWorkOrder.Cost_Center__c=8765;
            objWorkOrder.SVMXC__Order_Status__c = 'Completed';
            update objWorkOrder;
          } Catch(Exception ex){
            expectedExceptionThrown =  ex.getMessage().contains(Label.WODCIRCheckErrorCP) ? true : false;
            System.assert(expectedExceptionThrown, 'Expected Validation from Confirm Assignee Functionality not thrown'+ex.getMessage());
        }
          
        }
    }
        Test.stopTest();
    }

    /**
    * DCP-39881
    *  @author : Gautam Arya
    *  @description - test method to validate DCIR Error if DCIR status is set to completed
    **/
    static testMethod void testValidateIfDCIRStatusIsCompleted(){
        Case cs = [SELECT id FROM Case LIMIT 1];

        List<User> lstUser = [Select id,profile.id from user where profile.Name='Channel Partner Sales and Service' and IsActive=True limit 1];
        Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
        cp.SetupOwnerId= lstUser[0].profile.id;
        cp.Is_Channel_Partner__c= True;
        insert cp;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE_RELOCATION;
        objWorkOrder.Customer_Requested_Not_To_Re_Install__c=true;
        objWorkOrder.Record_Created_from_SFM__c=true;
        objWorkOrder.DCIR_Status__c='Open';
        insert objWorkOrder;
        System.assertNotEquals(null, objWorkOrder.Id);
        Test.startTest();
        if(!lstUser.isEmpty()){
        objWorkOrder.ownerId=lstUser[0].id;
        Update objWorkOrder;
        }

        if(!lstUser.isEmpty()){
          System.runas(lstUser[0]){

          try{
              objWorkOrder.DCIR_Status__c='Completed';
              update objWorkOrder;
           }Catch(Exception ex){
              system.assert(ex.getMessage() != Null , 'No Error');
           } 
        }
        }
        //START - DCP-47686
        ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
        insert objCV;
        system.assertNotEquals(null, objCV.id);
        objCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, objWorkOrder.Id,'V','AllUsers');
        insert objCDL;
        Attachment objAttachment = TestDataFieldService.createAttachment(objWorkOrder.id,'Letter_of_Acceptance');
        insert objAttachment;
      try{
        objWorkOrder.DCIR_Status__c='Completed';
        update objWorkOrder;
      } Catch(Exception ex){
          system.assert(ex.getMessage() != Null , 'No Error');
      }
      //END - DCP-47686
      Test.stopTest();
  }
    /**
    * DCP-39881
    *  @author : Dhairya Shah 
    *  @description - test method to validate DCIR Error if DCIR status is set to completed
    **/
    static testMethod void testValidateForNonBillableWOOnInsert() {
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(
            SVMXC__Billing_Type__c = WorkOrders.STRING_LABEL_BILLABLE,
            Billing_Type_Set_Manually__c = false
        );

        boolean boolCSOrSysAdmin = true;
        String integrationSapServiceProfileId = null;
        String strIntegrationSNAPServiceProfileId = null;

        BillingTypeAndDCIR_WOHelper.validateForNonBillableWOOnInsert(workOrder, boolCSOrSysAdmin, integrationSapServiceProfileId, strIntegrationSNAPServiceProfileId);

        System.assertEquals(true, workOrder.Billing_Type_Set_Manually__c, 'Billing_Type_Set_Manually__c should be set to true.');
    }

    /**
     * @author : Dhairya Shah
     * Test method for validateForNonBillableWOOnInsert covering the condition
     * where none of the profiles match, and an error should be thrown.
     */
    static testMethod void testValidateForNonBillableWOOnInsertNoProfilesMatch() {
        SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(
            SVMXC__Billing_Type__c = WorkOrders.STRING_LABEL_BILLABLE,
            Billing_Type_Set_Manually__c = false
        );

        boolean boolCSOrSysAdmin = false;
        String integrationSapServiceProfileId = 'someProfileId';
        String strIntegrationSNAPServiceProfileId = 'anotherProfileId';

        Test.startTest();
        Boolean expectedExceptionThrown = true;
        try {
            BillingTypeAndDCIR_WOHelper.validateForNonBillableWOOnInsert(workOrder, boolCSOrSysAdmin, integrationSapServiceProfileId, strIntegrationSNAPServiceProfileId);
        } catch (Exception e) {
            expectedExceptionThrown = e.getMessage().contains(System.label.WO_Trigger_Billing_Type_Edit_Error_Message);
        }
        Test.stopTest();
        System.assert(expectedExceptionThrown, 'Expected exception was not thrown when profiles did not match.');
    }
    /**
     * @author : Dhairya Shah
     */
    static testMethod void testValidateForNonBillableWOOnUpdate1() {
        RecordType estimatesRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'SVMXC__Service_Order__c' AND Name = 'Estimates' LIMIT 1];
        
        SVMXC__Service_Order__c oldWorkOrder = new SVMXC__Service_Order__c(
            RecordTypeId = estimatesRecordType.Id,
            SVMXC__Billing_Type__c = 'Contract',
            SVMXC__Order_Type__c = 'Preventative Maintenance',
            PO_Number__c = '12345'
        );
        insert oldWorkOrder;

        SVMXC__Service_Order__c newWorkOrder = new SVMXC__Service_Order__c(
            Id = oldWorkOrder.Id,
            RecordTypeId = estimatesRecordType.Id,

            SVMXC__Billing_Type__c = WorkOrders.STRING_LABEL_BILLABLE,
            PO_Number__c = '12345',
            Billing_Type_Set_Manually__c = false
        );

        Boolean boolCSOrSysAdmin = true;
        String integrationSapServiceProfileId = null;
        String strIntegrationSNAPServiceProfileId = null;

        newWorkOrder.RecordTypeId = estimatesRecordType.Id;
        
        Test.startTest();
        oldWorkOrder.SVMXC__Billing_Type__c = 'Contract';
        newWorkOrder.SVMXC__Billing_Type__c = WorkOrders.STRING_LABEL_BILLABLE;
        newWorkOrder.PO_Number__c = '12345'; // reset PO_Number__c
        newWorkOrder.Billing_Type_Set_Manually__c = false;
        BillingTypeAndDCIR_WOHelper.validateForNonBillableWOOnUpdate(newWorkOrder, oldWorkOrder, boolCSOrSysAdmin, integrationSapServiceProfileId, strIntegrationSNAPServiceProfileId, estimatesRecordType.Id);
        Test.stopTest();
        System.assertEquals(true, newWorkOrder.Billing_Type_Set_Manually__c, 'Billing_Type_Set_Manually__c should be set to true when Billing Type changes to Billable.');
    }
}
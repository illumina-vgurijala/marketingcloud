/**
*  @author Siddartha Reddy Kalam 
*  @description : test Class for WorkOrderBulkUpdateController Class.
*  
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Pooja                    23-09-2022          CodeScan Fixes
* --------------------------------------------------------------------------------------------------------------------------------------
    **/

@isTest(SeeAllData = false)
public class TestWorkOrderBulkUpdateController {
    static Case cs;
    public static final String STRING_WO_STATUS_IN_PROGRESS = 'In Progress';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
	public static final String STRING_WO_ORDER_STATUS_INITIATED = 'Initiated';
    public static final String STRIN_PRIMARY_FIELD_APPLICATION_SCIENTIST = 'Primary Field Application Scientists';
    public static final String STRING_EMAIL = 'a@b.com';
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_USER_EMAIL = 'puser000@amamama.com';
    public static final String STRING_TIMEZONE = 'America/Los_Angeles';
    public static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    public static final String SECONDARY_FIELD_SERVICE_ENGINEER = 'Secondary Field Service Engineer';
    public static final String BUSINESS_ISSUE = 'Business Issue';
    public static final String FIELD_STOCK_MANAGEMENT = 'Field Stock Management';
    public static final String PRODUCT_GROUP_AMPLISEQ = 'AmpliSeq Library Prep';
    public static final String WORKDETAIL_RECORDTYPE = 'Usage/Consumption';
	public static final String STRING_COUNTRY_INDIA = 'India';
	public static final String STRING_TEST = 'Test';
	public static final String STRING_LOCALE_KEY_EN_US = 'en_US';
    
    /*
	* test Data initialization.
	*/
    @testSetup
    public static void initializeTestData()
    {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = STRING_COUNTRY_INDIA
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = STRING_COUNTRY_INDIA,
            SVMXC__Street__c = STRING_TEST,
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
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }
    
    static testMethod void newWorkOrderCreation(){
        Test.startTest();
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'last',
            Email = STRING_USER_EMAIL,
            Username = STRING_USER_EMAIL + System.currentTimeMillis(),
            CompanyName = STRING_TEST,
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = STRING_TIMEZONE,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = STRING_LOCALE_KEY_EN_US,
            LocaleSidKey = STRING_LOCALE_KEY_EN_US
            
        );
        insert u;
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = STRING_COUNTRY_INDIA
        );
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail1@testing.com',
            SVMXC__Country__c = STRING_COUNTRY_INDIA,
            SVMXC__Street__c = STRING_TEST,
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        //insert grpMembers;
        
        SVMXC__Service_Group_Members__c grpMembers2 = new SVMXC__Service_Group_Members__c(
            Name = 'Test LastName',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testlastnamemail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Teststreet',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert new List<SVMXC__Service_Group_Members__c>{grpMembers, grpMembers2};
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Remote Support', null, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true; 
        workOrder.SVMX_PS_Subject__c = 'Test';
        workOrder.SVMXC__Order_Status__c = 'Initiated'; 
        workOrder.SVMXC__Group_Member__c = grpMembers.Id;
        insert workOrder;
        Account_to_Field_Support__c accTechRole = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Application Scientist'
        );
        insert accTechRole;
        //Fetch all workorders using Account to field Support/Field Support Id
        WorkOrderBulkUpdateController.getRelatedWorkOrders(accTechRole.Id);
        WorkOrderBulkUpdateController.getRelatedWorkOrders(grpMembers.Id);
        SVMXC__Service_Order__c returnedWos = [Select SVMXC__Group_Member__c,SVMXC__Order_Status__c,SVMXC__Order_Type__c from SVMXC__Service_Order__c where id=: workOrder.Id];
        system.assertEquals(grpMembers.Id, returnedWos.SVMXC__Group_Member__c );
        system.assertEquals('Initiated', returnedWos.SVMXC__Order_Status__c );
        system.assertEquals('Installation', returnedWos.SVMXC__Order_Type__c );
        
       //Updating Field Support on Work order
        workOrder.SVMXC__Group_Member__c = grpMembers2.Id; 
        WorkOrderBulkUpdateController.updateRelatedWO(new List<SVMXC__Service_Order__c>{workOrder});
        SVMXC__Service_Order__c objWOResult = [Select SVMXC__Group_Member__c from SVMXC__Service_Order__c where id=: workOrder.Id];
        system.assertEquals(grpMembers2.Id, objWOResult.SVMXC__Group_Member__c );
        
        //Updating Field Support on Work order after work order is completed
        workOrder.Evaluation__c='Test';
        workOrder.SVMXC__Work_Performed__c='Test';
        workOrder.Verification_Result__c='Test'; 
        workOrder.SVMXC__Order_Status__c = 'Completed';
        workOrder.No_Calibrated_Tools_Used__c = true;
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Training_Required__c = false;
        workOrder.Reason_for_No_Training__c='Customer Did Not Respond';
		workOrder.Signature_Type__c='Manual Sign';
        workOrder.Manual_Sign_Captured__c=true;
		workOrder.Is_Customer_Sign_Captured__c=true;
		workOrder.PO_Number__c='12';
        workOrder.Cost_Center__c=8765;
        Test.stopTest();
        update workOrder;
        workOrder.SVMXC__Group_Member__c = grpMembers.Id;            
        try{
            WorkOrderBulkUpdateController.updateRelatedWO(new List<SVMXC__Service_Order__c>{workOrder});            
        }
        catch(Exception ex){
             system.debug(ex.getMessage());
            System.assertEquals(true,ex.getMessage().contains('Work Order cannot be edited when status is Completed/Closed'));
        }
        
    }
   
}
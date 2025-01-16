/*
*@Description: Test class for ServiceReportEmailController
*/
@isTest (SeeAllData=False)
public class TestServiceReportEmailController {
    public static final String STRING_ATTACHMENT_NAME = 'Service_Report';
    static SVMXC__Service_Order__c workOrder= new SVMXC__Service_Order__c();
    static Attachment objAttachment= new Attachment();
    static Account acc;
    static Account_to_Field_Support__c afs1;
    static SVMXC__Service_Group__c serviceTeam;
    static user userInstance;
    static Contact con;
    static Case cs;
    
/*
*@Method : initializeTestData
*/
    @testSetup
    public static void initializeTestData() {
        userInstance = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service AND isActive=true
                               LIMIT 1]; 
        User userAdmin = [SELECT Id FROM User 
                               WHERE Profile.Name =:System.label.ProfileSystemAdmin AND isActive=true
                               LIMIT 1]; 
        System.runAs(userAdmin){  
        PermissionSet ps = new PermissionSet(Name='TestContactPermission',Label='TestContactPermission');
        insert ps;
        List<ObjectPermissions> op = new List<ObjectPermissions>();
        op.add(new ObjectPermissions(ParentId=ps.Id,
                                     SobjectType='Contact',
                                     PermissionsRead=true,
                                     PermissionsViewAllRecords=true));
        insert op;
        insert new PermissionSetAssignment(PermissionSetId=ps.Id ,AssigneeId=userInstance.Id); 
        
        }
        acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c= 'Distributor';
        insert acc;
        con = new Contact(FirstName = 'test', LastName = 'test1' , AccountId = acc.Id);
        con.Email='testcontact@testillm.com';
        con.Phone='9876543210';
        insert con;

        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
                             
        serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(userInstance.id,'Test Technician',serviceTeam.id);
        technicianFAS.SVMXC__Email__c='b@b.com';
        insert technicianFAS;
        
        afs1 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc.Id,User_Role__c = 'Primary Field Application Scientist');
        insert afs1;
        workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Service_Report_Generated__c = true;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
		System.assert(workOrder.Id != null);
        objAttachment=TestDataFieldService.createAttachment(workOrder.Id,STRING_ATTACHMENT_NAME);
        insert objAttachment;
        
       
  }

/**
* 
*  @author : Soumya Ranjan
*  @description - test validate Email is loaded
**/
static testMethod void testServiceReportLoad(){
    boolean isLoggedInUser = null;
    List<ServiceReportEmailController.SObjectResult> lstSObjectResult= new List<ServiceReportEmailController.SObjectResult>();
    Attachment testAttachment=  new Attachment();
    List<id> lstAllRelatedContacts = new List<id>();
    Map<String, String> templateData = new Map<String, String>();
    Test.Starttest();
    acc=[Select id,Name from Account LIMIT 1][0];
    workOrder=[Select id from SVMXC__Service_Order__c LIMIT 1][0];
    con=[select id from Contact LIMIT 1][0];
    objAttachment=[Select id from Attachment LIMIT 1][0];
    userInstance = [SELECT Id  FROM User 
                               WHERE Profile.Name =: System.label.Field_Service AND isActive=true
                               LIMIT 1];
    System.runAs(userInstance){
    lstSObjectResult=ServiceReportEmailController.getCCAddresses(acc.id);
    
    For(ServiceReportEmailController.SObjectResult objInst:lstSObjectResult){
        if(objInst.recId==userInstance.id)
            isLoggedInUser=true;
    }
    
    lstAllRelatedContacts = ServiceReportEmailController.getRelatedContacts(acc.id);
    testAttachment = ServiceReportEmailController.getLatestServiceReportfromWorkOrder(workOrder.id);
    templateData = ServiceReportEmailController.getTemplateData(workOrder.id);
    }
    Test.stoptest();
    //to check if logged in user is added to CC List
    system.assert(isLoggedInUser);
    //to check if returned list conatins inserted contact
    system.assert(lstAllRelatedContacts.contains(con.id));
    //to check if retuned attachment is the inserted ones
    system.assertequals(testAttachment.id,objAttachment.id);

    //to check if proper template is called
    system.assert(templateData.get('subject').contains('Customer Service Report:'));
  }

      /**
* 
*  @author : Soumya Ranjan
*  @description - test validate Email is sent
**/
static testMethod void testgetResults(){
    acc=[Select id,Name from Account LIMIT 1][0];
    workOrder=[Select id from SVMXC__Service_Order__c LIMIT 1][0];
    con=[select id,Name from Contact LIMIT 1][0];
    objAttachment=[Select id from Attachment LIMIT 1][0];
    userInstance = [SELECT Id  FROM User 
                               WHERE Profile.Name =: System.label.Field_Service AND isActive=true
                               LIMIT 1];
    list<id> lstContactIds = new list<id>();
    list<id> lstRelatedContactIds = new list<id>{con.id};
    list<id> lstUserIds = new list<id>();
    List<ServiceReportEmailController.SObjectResult> lstSObjectResult= new List<ServiceReportEmailController.SObjectResult>();
    Test.Starttest();
    System.runAs(userInstance){
    Id [] fixedSearchResults= new Id[1];
    fixedSearchResults[0] = Con.Id;
    Test.setFixedSearchResults(fixedSearchResults);
    lstSObjectResult=ServiceReportEmailController.getResults('test',lstContactIds,lstUserIds,lstRelatedContactIds);
    }
    Test.stoptest();
    system.assert(lstSObjectResult.size()>0);
    
}
  
       /**
* 
*  @author : Soumya Ranjan
*  @description - test validate Email is sent
**/
static testMethod void testSendEmail(){
    List<String> lstToAddresses= new List<String>{'Test@Test.com'};
    List<String> lstCCAddresses= new List<String>{'TestCC@Test.com'};
    string subject='Test';
    string body ='Test';
    Test.Starttest();
    acc=[Select id,Name from Account LIMIT 1][0];
    workOrder=[Select id from SVMXC__Service_Order__c LIMIT 1][0];
    con=[select id from Contact LIMIT 1][0];
    cs = [select id from Case LIMIT 1][0];
    objAttachment=[Select id from Attachment LIMIT 1][0];
    userInstance = [SELECT Id  FROM User 
                               WHERE Profile.Name =: System.label.Field_Service AND isActive=true
                               LIMIT 1];
    System.runAs(userInstance){
        ServiceReportEmailController.sendServiceReportEmail(lstToAddresses,lstCCAddresses,subject,body,null,new List<id>{objAttachment.id},workOrder.Id, cs.Id);
        }
        Integer invocations = Limits.getEmailInvocations();
    Test.stoptest();
    system.assertEquals(1, invocations, 'An email should be sent');
    }
}
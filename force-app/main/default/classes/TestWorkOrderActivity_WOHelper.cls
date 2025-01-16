/**
* @author Shivani Jain
* @date 13th June 2022
*
* @description DCP-54018 Test class for WorkOrderActivity_WOHelper
*/
@IsTest
public with sharing class TestWorkOrderActivity_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String WORKDETAIL_RECORDTYPE = 'Usage/Consumption';
    private static final String PRODUCT_GROUP_AMPLISEQ = 'AmpliSeq Library Prep';

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
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
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

               //insert account
               Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
               acc.Account_Group__c='Distributor';
               insert acc;
               //insert contact
               Contact objContact = TestDataContact.getNewContact(acc);
               //insert product
               Product2 objProduct1=TestDataFieldService.createProduct('Test Product','Instrument');
               objProduct1.product_Group__c=PRODUCT_GROUP_AMPLISEQ;
               insert objProduct1;
               Work_Order_Activity_Rules__c objWoActivityRule = new Work_Order_Activity_Rules__c();
               objWoActivityRule.Document_Name__c = 'TestLWC1';
               objWoActivityRule.Document_Number__c = '123456';
               objWoActivityRule.Name = 'TestClass1234';
               objWoActivityRule.Activity_Type__c = 'Installation';
               objWoActivityRule.Product_Code__c = objProduct1.Id;
               objWoActivityRule.Product_Group__c = PRODUCT_GROUP_AMPLISEQ;
               objWoActivityRule.Generic_Document__c = true;
               objWoActivityRule.Required__c = true;
               insert objWoActivityRule;
               //Approving the Record
               Set<Id> pIds = new Map<Id, ProcessInstance>([SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId = :objWoActivityRule.Id]).keySet();
               Set<Id> pInstanceWorkitems = new Map<Id, ProcessInstanceWorkitem>([SELECT Id,ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId in :pIds]).keySet();
               //List<Approval.ProcessWorkitemRequest> allReq = new List<Approval.ProcessWorkitemRequest>(); 
               for (Id pInstanceWorkitemsId:pInstanceWorkitems){
                   Approval.ProcessWorkitemRequest req2 =  new Approval.ProcessWorkitemRequest();
                   req2.setComments('Approving request.');
                   req2.setAction('Approve');
                   req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
                 req2.setWorkitemId(pInstanceWorkitemsId);
                   Approval.ProcessResult result = Approval.process(req2);
                   System.debug('result ' +result);
               }
              
               //insert installed product
               SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
               objInstalledProduct.SVMXC__Company__c = acc.Id;
               objInstalledProduct.Acceptance_Date__c= Date.Today();
               objInstalledProduct.SVMXC__Date_Installed__c= Date.Today();
               objInstalledProduct.SVMXC__Product__c = objProduct1.Id;
               objInstalledProduct.Operation_Status__c = 'On';
               insert objInstalledProduct;
               Case objCase = TestDataCase.initServiceRequestCase(objContact);
               objCase.SVMXC__Component__c = objInstalledProduct.Id;
               insert objCase;
               SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
               insert objLoc;

    }

    /**
     * Method: testVerifyWOForMissingDocumentation
     * Description: DCP-43185-Test method to validate missing documents on complete work order
     * @author : Raja Siva Krishna
     * */
    @IsTest
    public static void testVerifyWOForMissingDocumentation(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;
        Test.startTest();
        SVMXC__Installed_Product__c objInstalledProduct = [Select Id, Name From SVMXC__Installed_Product__c Where Name = 'Test IP VM' ];
        Product2 objProduct1=[Select Id, Name From Product2 Where Name = 'Test Product'];
        Case objCase = [Select Id, SVMXC__Component__c From Case Where SVMXC__Component__c =  :objInstalledProduct.Id];
        Account acc=[Select Id, Name From Account Where Name = :STRING_ACCOUNT];
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');       
        workOrder.SVMXC__Company__c = acc.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Product__c = objProduct1.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        workOrder.Partner_Installation_WO__c = true;
        workOrder.Evaluation__c ='test';
        workOrder.Is_Service_Report_Generated__c = true;
        workOrder.Is_Customer_Sign_Captured__c = true;
        workOrder.Training_Required__c = false;  
        workOrder.SVMXC__Work_Performed__c ='test';
        workOrder.Verification_Result__c ='test';
        workOrder.Has_Verification_Code__c =true;
        workOrder.No_Calibrated_Tools_Used__c=true; 
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Reason_for_No_Training__c = 'Customer Did Not Respond';
        insert workOrder;
        Id recId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WORKDETAIL_RECORDTYPE).getRecordTypeId();
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.RecordTypeId = recId;
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Activity_Type__c = 'Installation';
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Product__c = objProduct1.Id;
        objOrderDetail.SVMXC__Line_Type__c = WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR;         
        objOrderDetail.SVMXC__Is_Billable__c = true;
        objOrderDetail.Consumption_Confirmed__c=true;
        insert objOrderDetail;
        Test.stopTest();
        
        workOrder.SVMXC__Order_Status__c = 'Completed';
        try{
            WorkOrders.hasactivityRuleran = false;
            update workOrder;
        }
        catch(Exception e){
            system.debug('DCP-43185-Test Error:'+e.getMessage());
            system.assert(e.getMessage().contains(System.Label.WO_Trigger_Documents_Upload_Error_Message),  'Wo trigger documents upload error message');
        }
        
    }

    /**
     * Method: testVerifyWOForMissingDocumentationWithFile
     * Description: DCP-43185-Test method to validate missing documents on complete work order
     * @author : Raja Siva Krishna
     * */
    @IsTest
    public static void testVerifyWOForMissingDocumentationWithFile(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;
        Test.startTest();
        SVMXC__Installed_Product__c objInstalledProduct = [Select Id, Name From SVMXC__Installed_Product__c Where Name = 'Test IP VM' ];
        objInstalledProduct.Operation_Status__c = 'On';
        objInstalledProduct.SVMXC__Status__c = 'Awaiting Installation';
        update objInstalledProduct;
        Product2 objProduct1=[Select Id, Name From Product2 Where Name = 'Test Product'];
        Case objCase = [Select Id, SVMXC__Component__c From Case Where SVMXC__Component__c =  :objInstalledProduct.Id];
        Account acc=[Select Id, Name From Account Where Name = :STRING_ACCOUNT];

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');       
        workOrder.SVMXC__Company__c = acc.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Product__c = objProduct1.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        workOrder.Partner_Installation_WO__c = true;
        workOrder.Evaluation__c ='test';
        workOrder.Is_Service_Report_Generated__c = true;
        workOrder.Is_Customer_Sign_Captured__c = true;
        workOrder.Training_Required__c = false;  
        workOrder.SVMXC__Work_Performed__c ='test';
        workOrder.Verification_Result__c ='test';
        workOrder.Has_Verification_Code__c =true;
        workOrder.No_Calibrated_Tools_Used__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.Reason_for_No_Training__c='Customer Declined - Lab already trained';
        insert workOrder;
        Id recId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WORKDETAIL_RECORDTYPE).getRecordTypeId();
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.RecordTypeId = recId;
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Activity_Type__c = 'Installation';
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Product__c = objProduct1.Id;
        objOrderDetail.SVMXC__Line_Type__c = WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR;             
        objOrderDetail.SVMXC__Is_Billable__c = true;
        insert objOrderDetail;
        Test.stopTest();

        // Updating the Case to make sure Associated Code error doesn't come
        objCase.GTS_Status__c = 'Request Initiated';
        objCase.Has_Analysis_Code__c = true;
        objCase.Has_Resolution_Code__c = true;
        objCase.HasHazardCode__c = true;
        Cases.skipCaseTrigger = true;
        update objCase;

        workOrder.SVMXC__Order_Status__c = 'Completed';
        ContentVersion objCV;
        objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
        insert objCV;
        objCV.Document_Type_fileupload__c = 'TestLWC1';
        update objCV;
        system.assertNotEquals(null,objCV.id);
        objCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, workOrder.Id,'V','AllUsers');
        insert objCDL;
        WorkOrders.hasactivityRuleran = false;
        update workOrder;
        try{
            DocumentUploadController.WorkDetailsFieldsWrapper wrapperDetails1 = DocumentUploadController.getWrapperFieldDetails(null);
            System.debug('wrapperDetails1 ' +wrapperDetails1);
        }
        catch(Exception e){
            system.assert(e.getMessage().contains('Script-thrown exception'), 'exception');
        }
    
    }
    

}
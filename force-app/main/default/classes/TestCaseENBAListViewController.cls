/***************************************************************************************************************************************
 * NAME   : TestCaseENBAListViewController
 * DESCRIPTION  : TestClass for TestCaseENBAListViewController
 *         
 *    
 * @AUTHOR : Shahnawaz
 * @DATE   : 06-08-2022 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shahnawaz            06-08-2022           Initial Version
 * Gladis               14-June-2022         DCP-54039 Added test method for Billable suggest and customer follow up Recommendations
 * Rohan               14-June-2022         DCP-54039 Added test method for Review Comments and Loop Team
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)  
public with sharing class TestCaseENBAListViewController {
    private static final String LOG_TITLE = 'TestCaseENBAListViewController';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String BUSINESS_ISSUE = 'Business Issue';
    public static final string STRING_LOCATION = 'Test Location';
    public static final string STRING_STREET = 'Test Street';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static Case cs;
    public static Field_Action_Notification__c fan;
    static testMethod void getWorkOrderListMethod() {
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
            insert acc;
        
            Contact con = TestDataPerson.getNewContact(acc.Id);
            Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
            
            Case objCase  = new Case(    
                Status = 'Initiated',
                Subject = 'test' ,
                Description= 'test',
                Origin = 'Phone-CP',
                Date_of_Issue_Awareness__c=System.today() -2,
                Awareness_Date_Difference_Reason__c = 'Logistical delay',
                ContactId = con.Id,
                AccountId = acc.Id,
                RecordTypeId = idCaseRecordTypeId
            );
            insert objCase;
            List<User> lstUsers = [SELECT Id 
            FROM User 
            WHERE Profile.Name =: System.label.Field_Service
            LIMIT 1];     
            SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
            insert serviceTeam;

            SVMXC__Service_Group_Members__c technicianFAS =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technicianFAS.SVMXC__Email__c='b@b.com';
            insert technicianFAS;

            SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Test Technician',serviceTeam.id);
            technician.SVMXC__Email__c='b@b1.com';
            insert technician;

            Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(acc.id,'Primary Field Service Engineer',technician.id);
            insert accToFieldSupport;
            List<Id> lstAccountId = new List<Id>();
            lstAccountId.add(acc.id);
            CaseENBAListViewController.getToAddresses(lstAccountId);
            Test.startTest();
            Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId(); 
            SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                 SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                                 SVMXC__Order_Status__c from 
                                                 SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
            System.assertNotEquals(null,workOrder,'work order is null');
            
            Elevations__c techElev = new Elevations__c();
            techElev.RecordTypeId = technicalElevationRecordType;
            techElev.Elevation_Category__c = 'Standard Technical';
            techElev.Elevation_Status__c = 'Open';
            techElev.Elevation_Owner__c = lstUsers[0].Id;
            techElev.Elevation_Manager__c = lstUsers[0].Id;
            techElev.Plan_of_Action__c = 'test';
            techElev.Work_Order__c = workOrder.Id;
            insert techElev;            
            
            test.StopTest();
            Recommendation recom = new Recommendation();
            recom.name = 'This account is a hot site with at least one open elevation';
            recom.description = 'This account is a hot site with at least one open elevation';
            recom.acceptancelabel ='Accept';
            recom.rejectionlabel = 'Reject';
            List<Recommendation> lstRecomm = new List<Recommendation>();
            lstRecomm.add(recom);

            CaseENBAListViewController.getWorkOrderList(acc.Id);

            List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
            CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
            inputRequest.recordId=objCase.Id;
            inputRequest.recommendations = lstRecomm;
            inputRequests.add(inputRequest);
            List<List<Recommendation>> listOfrecomm = CaseRecommendationController.generateRecommendation(inputRequests);
            System.assertNotEquals(null,listOfrecomm,' listOfrecomm returned not null');
    }
    static testmethod void filterRecommendations() {
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert acc;
    
        Contact con = TestDataPerson.getNewContact(acc.Id);
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(acc.Id);
          insert objServiceContract;
          SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
          insert objLocation;
  
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          insert objInstalledProduct;
  
        Test.startTest();
        Case objCase  = new Case(    
            Status = 'Initiated',
            Subject = 'test' ,
            Description= 'test',
            Origin = 'Phone-CP',
            Date_of_Issue_Awareness__c=System.today() -2,
            Awareness_Date_Difference_Reason__c = 'Logistical delay',
            ContactId = con.Id,
            AccountId = acc.Id,
            RecordTypeId = idCaseRecordTypeId
        );
        insert objCase;
        Case objCase2  = new Case(    
            Status = 'Initiated',
            Subject = 'test' ,
            Description= 'test',
            Origin = 'Phone-CP',
            Date_of_Issue_Awareness__c=System.today() -2,
            Awareness_Date_Difference_Reason__c = 'Logistical delay',
            ContactId = con.Id,
            AccountId = acc.Id,
            RecordTypeId = idCaseRecordTypeId
        );
        insert objCase2;
        Test.stopTest();   
            Recommendation recom = new Recommendation();
            recom.name = 'This Contact and/or Installed Product has another Open Case';
            recom.description = 'This Contact and/or Installed Product has another Open Case';
            recom.acceptancelabel ='Accept';
            recom.rejectionlabel = 'Reject';

            CaseENBAListViewController.getCaseList(objCase.Id,con.Id, recom.name);

            Recommendation recom2 = new Recommendation();
            recom2.name = 'Potential Duplicate: This Account has another Opened Case within the last 8 hour';
            recom2.description = 'This Contact and/or Installed Product has another Open Case';
            recom2.acceptancelabel ='Accept';
            recom2.rejectionlabel = 'Reject';

            CaseENBAListViewController.getCaseList(objCase.Id,con.Id, recom2.name);

            Recommendation recom3 = new Recommendation();
            recom3.name = 'This Installed Product does not have an Active Service Contract Associated with';
            recom3.description = 'This Contact and/or Installed Product has another Open Case';
            recom3.acceptancelabel ='Accept';
            recom3.rejectionlabel = 'Reject';

            CaseENBAListViewController.getCaseList(objCase.Id,con.Id, recom3.name);

            Recommendation recom4 = new Recommendation();
            recom4.name = 'This Case has a Product that may be related to a FAN';
            recom4.description = 'This Case has a Product that may be related to a FAN';
            recom4.acceptancelabel ='Accept';
            recom4.rejectionlabel = 'Reject';
            List<Recommendation> lstRecomm = new List<Recommendation>();
            lstRecomm.add(recom);
            lstRecomm.add(recom2);
            lstRecomm.add(recom3);
            lstRecomm.add(recom4);

            List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
            CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
            inputRequest.recordId=objCase.Id;
            inputRequest.recommendations = lstRecomm;
            inputRequests.add(inputRequest);
            List<List<Recommendation>> lstRecommendations = CaseRecommendationController.generateRecommendation(inputRequests);
            System.assertNotEquals(null,lstRecommendations,' lstRecommendations returned not null');
      
    }
    
/* testSetup method */
    @testSetup
    public static void initializeTestData() {
        // To create a FAN record of record type "Notification"
        FAN =TestDataFieldService.createFAN('Notification');
        insert FAN;
    }

/* test method */
    public static testMethod void newFieldActionItem() {
        initializeTestData();

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.ProductCode='TestProduct0006';
        objProduct.Source_System__c = 'SAP';
        insert objProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.Product_Serial_Number__c='Test11';
        
        insert objCase;
            
        List<Impacted_Products_Serials_Lots__c> lstimpprod=new List<Impacted_Products_Serials_Lots__c>();
        lstimpprod.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN.Id,Serial_Number__c='Test11'));
        lstimpprod.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN.Id,Lot_Number__c='Test12'));
        lstimpprod.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN.Id,Product__c=objProduct.Id));
        insert lstimpprod;

        Recommendation recom = new Recommendation();
        recom.name = 'This Case has a Product that may be related to a FAN';
        recom.description = 'This Case has a Product that may be related to a FAN';
        recom.acceptancelabel ='Accept';
        recom.rejectionlabel = 'Reject';
        List<Recommendation> lstRecomm = new List<Recommendation>();
        lstRecomm.add(recom);
        System.debug(' >>>>>>>>>>>>>>>>>>   '+objCase.SVMXC__Product__c);
        objCase.SVMXC__Product__c = objProduct.Id;
        Update objCase ;
        List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
        CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
        inputRequest.recordId=objCase.Id;
        inputRequest.recommendations = lstRecomm;
        inputRequests.add(inputRequest);
        CaseRecommendationController.generateRecommendation(inputRequests);
        try {
        Test.StartTest();            
            List<FANRecordListController.DataWrapper> lstdatawrapper=FANRecordListController.getwrapperList(objCase.Id);
            system.assertNotEquals(null,lstdatawrapper);
        Test.StopTest();
        }
    	catch(Exception e) {
            System.debug(e);
        }
    }

    /* @Author Gladis
    *  @Description DCP-54039 method to cover getPublishedKnwArticles
    */
    public static testMethod void testFetchKnowledgeArticlesAndEmails() {
        ilib_LogEvent.push(LOG_TITLE + 'testFetchKnowledgeArticlesAndEmails()');
        initializeTestData();

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.ProductCode='TestProduct0006';
        objProduct.Source_System__c = 'SAP';
        insert objProduct;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.Product_Serial_Number__c='Test11';
        
        insert objCase;

        EmailMessage objEmail2 = new EmailMessage();
        objEmail2.FromAddress = 'debalchatterjee@deloitte.com';
        objEmail2.Incoming = true;
        objEmail2.Subject = 'Test email';
        objEmail2.HTMLBody = 'Hello';
        objEmail2.Headers = 'In-Reply-To: <SN4PR85MB01091C88F722D016DA982EB1A6149@SN4PR85MB0109.NAMPRD85.PROD.OUTLOOK.COM> References: <SN4PR85MB01091C88F722D016DA982EB1A6149@SN4PR85MB0109.NAMPRD85.PROD.OUTLOOK.COM>';
        objEmail2.ParentId = objCase.Id;
        insert objEmail2;

        List<Recommendation> lstRecomms = new List<Recommendation>();
        Recommendation recom5 = new Recommendation();
        recom5.name = 'This Installed Product does not have an Active Service Contract Associated with';
        recom5.description = 'This Installed Product does not have an Active Service Contract Associated with it. If service is required, please follow the Billable Workflow for your region';
        recom5.acceptancelabel ='Accept';
        recom5.rejectionlabel = 'Reject';
        
        Recommendation recom6 = new Recommendation();
        recom6.name = 'This Case has not been updated in two days';
        recom6.description = 'This Case has not been updated in two days';
        recom6.acceptancelabel ='Accept';
        recom6.rejectionlabel = 'Reject';

        lstRecomms.add(recom5);
        lstRecomms.add(recom6);
        
        Test.StartTest(); 
        List<Knowledge__Kav> lstKnw = CaseENBAListViewController.getPublishedKnwArticles(objCase.Id);
        system.assertEquals(0, lstKnw.size(), 'No Articles found');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        Test.StopTest(); 
    }

    /**
    *  @AUTHOR Rohan 
    *  @DESCRIPTION : DCP-54039 Test method for Review Comments Logic
    **/
    static testMethod void testReviewComment() {
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
        acc.Field_Comments__c = 'TS do not process replacements';
        insert acc;
    
        Contact con = TestDataPerson.getNewContact(acc.Id);
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
        
        Case objCase  = new Case(    
            Status = 'Initiated',
            Subject = 'test' ,
            Description= 'test',
            Origin = 'Phone-CP',
            Date_of_Issue_Awareness__c=System.today() -2,
            Awareness_Date_Difference_Reason__c = 'Logistical delay',
            ContactId = con.Id,
            AccountId = acc.Id,
            RecordTypeId = idCaseRecordTypeId
        );
        insert objCase;

        Recommendation recom = new Recommendation();
        recom.name = 'This Account has a specialized Replacement Process per the Field Comments';
        recom.description = 'This Account has a specialized Replacement Process per the Field Comments';
        recom.acceptancelabel ='Accept';
        recom.rejectionlabel = 'Reject';
        List<Recommendation> lstRecomm = new List<Recommendation>();
        lstRecomm.add(recom);

        List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
        CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
        inputRequest.recordId=objCase.Id;
        inputRequest.recommendations = lstRecomm;
        inputRequests.add(inputRequest);
        Test.startTest();
        List<List<Recommendation>> listOfrecomm = CaseRecommendationController.generateRecommendation(inputRequests);
        System.assertNotEquals(null,listOfrecomm,' listOfrecomm returned not null');
        List<Account> lstAccounts = CaseENBAListViewController.getAccountFieldDetails(acc.Id);
        system.assertNotEquals(null, lstAccounts, 'No Account details found');
        Test.stopTest();
    }
}
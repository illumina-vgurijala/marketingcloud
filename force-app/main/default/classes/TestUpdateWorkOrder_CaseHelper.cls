/**
 * @description       : To test to functionality of work order update
 * @author            : Pooja Shalwadi
 * @group             : 
 * @last modified on  : 06-13-2022
 * 
 * Date                           Name                                        Description
 * 18-09-2022                     Sheikh Shahnawaz                            Enhance code coverage above 80%
**/
@isTest
public class TestUpdateWorkOrder_CaseHelper {
    public static final string STRING_LOCATION = 'Test Location';
    public static final string STRING_STREET = 'Test Street';
    public static final string STRING_CASE_STATUS_IN_PROGRESS = 'In Progress';
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';     
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    public static final string STRING_EVALUATION_ANSWER_NO = 'No';
    public static final string STRING_CASE_STATUS_CLOSED = 'Closed';
    public static final string STRING_INSTALLED_PRODUCT_IP_NAME = 'A01195-15019046'; 
    public static final string STRING_INSTALLED_PRODUCT_SERIAL_LOT_NUMBER = 'A01195';
 
    static testmethod void testUpdateWorkOrderForVariousConditions() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount1.Account_Group__c='Distributor';
        objAccount1.Territory_Region__c='AMR';
        insert objAccount1;

        Contact con = TestDataContact.getNewContact(objAccount1);

        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = '23456';
        insert sp;

        List<SVMXC__Service_Contract__c> listSub = new List<SVMXC__Service_Contract__c>();
        SVMXC__Service_Contract__c sub = TestDataFieldService.createServiceContract(objAccount1.Id);
        sub.ERP_Contract_Type__c = 'Software (ZWS)';
        sub.SVMXC__Service_Plan__c = sp.id;
        listSub.add(sub);
 
        SVMXC__Service_Contract__c sub1 = TestDataFieldService.createServiceContract(objAccount1.Id);
        sub1.SVMXC__Service_Plan__c = sp.Id;
        sub1.Status__c = 'Active';
        sub1.SVMXC__Start_Date__c = System.today();
        sub1.SVMXC__End_Date__c = System.today().addDays(20);
        sub1.ERP_Contract_Type__c = 'Software (ZWS)';
        listSub.add(sub1);
 
        INSERT listSub;

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProductforLotNumber(STRING_INSTALLED_PRODUCT_IP_NAME, STRING_INSTALLED_PRODUCT_STATUS,STRING_INSTALLED_PRODUCT_SERIAL_LOT_NUMBER);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        objInstalledProduct.SVMXC__Company__c = objAccount1.id;
        objInstalledProduct.SVMXC__Contact__c = con.id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase1.Date_of_Issue_Awareness__c = Date.Today();
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.SVMXC__Site__c=objLocation.id;
        objCase1.AccountId=objAccount1.id;
        objCase1.Region__c='AMR';
        objCase1.Subscription__c=listSub[0].id;
        objCase1.ContactId = con.id;
        insert objCase1;
        Map<Id, Case> mapOldCases = new Map<Id, Case>();
        mapOldCases.put(objCase1.id,objCase1);
        system.debug('objCase1>>'+objCase1.RecordTypeId);
        
        SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'USA','123456990','USD');
        insert objLocation1;

        SVMXC__Service_Order__c objWorkOrder = [Select Id, Integration_Status__c from  SVMXC__Service_Order__c where SVMXC__Case__c =: objCase1.id limit 1];
        objWorkOrder.Integration_Status__c = 'Not Required';
        
        Test.startTest();
        update objWorkOrder;
        Cases.mapWOIdToWorkOrders = null;
        objCase1.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
        objCase1.Verification_Result__c = 'Test';
        objCase1.Record_Updated_from_SFM__c = true;
        objCase1.Status = STRING_CASE_STATUS_CLOSED;
        objCase1.Record_Updated_from_SFM__c = True;
        objCase1.Subject='Testing12345';
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.Product_Serial_Number__c='Test11';
        objCase1.Subscription_License_Status__c = 'Active';
        objCase1.Registrant_Email_Address__c = 'test@example.com';
        objCase1.Domain_Name__c = 'example.com';
        objCase1.Workgroup_Name__c = 'Workgroup1';
        objCase1.SVMXC__Site__c=objLocation1.id;
        objCase1.Subscription__c=listSub[1].id;
        update objCase1;

        List<Case> lstNewCases = [SELECT Id, Status, Product_Serial_Number__c, Product_Lot_Number__c,RecordTypeId, Subject,Description,Next_Steps__c,
                                         Follow_up_Needed__c,Evaluation__c,Verification_Result__c,Work_Performed__c,
                                         Subscription__c, Subscription_License_Status__c,SVMXC__Site__c,Previous_Status__c,
                                         Registrant_Email_Address__c, Domain_Name__c, Workgroup_Name__c,Work_Order__r.Id
                                  FROM Case];

        // Modify case status to simulate changes
        for (Case c : lstNewCases) {
            System.debug('c.Status--->>'+c.Status);
            if (c.Status == 'Closed') {
                c.Status = 'Open';
            }
            if(c.SVMXC__Site__c == objLocation1.id){
                c.SVMXC__Site__c = objLocation.id;
            } else {
                c.SVMXC__Site__c = objLocation1.id;
            }
            if(c.Subscription__c == sub1.id){
                c.Subscription__c = sub.id;
            } else {
                c.Subscription__c = sub1.id;
            }
        }


        UpdateWorkOrder_CaseHelper.updateWorkOrderForVariousConditions(lstNewCases, mapOldCases);
        Test.stopTest();
    }
    /**
    * @description : update case reopen/subject functionality check
    * @return testmethod 
    **/
    static testmethod void checkCaseReOpenedStatusFromSFM() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;
        Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount1.Account_Group__c='Distributor';
        objAccount1.Territory_Region__c='AMR';
        insert objAccount1;

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase1.Date_of_Issue_Awareness__c = Date.Today();
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.SVMXC__Site__c=objLocation.id;
        objCase1.AccountId=objAccount1.id;
        objCase1.Region__c='AMR';
        insert objCase1;
        
        SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'USA','123456990','USD');
        insert objLocation1;
        Test.startTest();
        SVMXC__Service_Order__c objWorkOrder = [Select Id, Integration_Status__c from  SVMXC__Service_Order__c where SVMXC__Case__c =: objCase1.id limit 1];
        objWorkOrder.Integration_Status__c = 'Not Required';
        update objWorkOrder;
        Cases.mapWOIdToWorkOrders = null;
        objCase1.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
        objCase1.Verification_Result__c = 'Test';
        objCase1.Record_Updated_from_SFM__c = true;
        objCase1.Status = STRING_CASE_STATUS_CLOSED;
        objCase1.Record_Updated_from_SFM__c = True;
        objCase1.Subject='Testing12345';
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.Product_Serial_Number__c='Test11';
        objCase1.SVMXC__Site__c=objLocation1.id;
        update objCase1;
        objCase1.Record_Updated_from_SFM__c = true;
        objCase1.Status = 'Reopened';
        objCase1.Reason_for_Reopen__c = 'Adding Reason for reopen field on case record to cover more than 255 character, This is just to check the functionality that updates work order " Reason for reopen " field from the case and increase the test class code coverage.';
        objCase1.SVMXC__Site__c=objLocation.id;
        update objCase1;
        Test.stopTest();
        List<SVMXC__Service_Order__c> updateWOSubject = [select Id,Case_Subject__c,SVMX_PS_Subject__c,SVMXC__Case__c,Reason_for_Reopen__c,WO_Reopen_Status__c,Reopen_Requester__c FROM SVMXC__Service_Order__c LIMIT 1];
        /* Code coverage enhancement start */
        Map<Id, Case> mapIdToCase = new Map<Id, Case>();
        Map<Id, SVMXC__Service_Order__c> mapIdToWorkOrder = new Map<Id, SVMXC__Service_Order__c>();
        mapIdToWorkOrder.put(updateWOSubject[0].Id, updateWOSubject[0]);
        updateWOSubject[0].Order_Previous_Status__c =  Label.WorkOrderStatusAssigned;
        updateWOSubject[0].SVMXC__Order_Status__c =  Label.WorkOrderStatusAssignmentAccepted;
        mapIdToCase.put(objCase1.Id,objCase1);
        Map<Id, String> mapCasaeIdToChange = new  Map<Id, String>();
        
        mapCasaeIdToChange.put(objCase1.Id,Cases.CASE_OF_REOPENED_DENIED);
        UpdateWorkOrder_CaseHelper.addWORelatedToReopenCases(updateWOSubject[0],null,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);
        
        mapCasaeIdToChange.put(objCase1.Id,Cases.SUBJECT_DESC_OTHERS_CHANGE);
        UpdateWorkOrder_CaseHelper.addWORelatedToUpdatedCase(updateWOSubject[0],null,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);
        /* Code coverage enhancement end */
        system.assertEquals('Testing12345',updateWOSubject[0].Case_Subject__c,'Work order subject ');
    }

    static testmethod void checkCaseReOpenedStatusFromSFM1() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;
        Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount1.Account_Group__c='Distributor';
        objAccount1.Territory_Region__c='AMR';
        insert objAccount1;

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase1.Date_of_Issue_Awareness__c = Date.Today();
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.SVMXC__Site__c=objLocation.id;
        objCase1.AccountId=objAccount1.id;
        objCase1.Region__c='AMR';
        insert objCase1;
        
        SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'USA','123456990','USD');
        insert objLocation1;
        Test.startTest();
        SVMXC__Service_Order__c objWorkOrder = [Select Id, Integration_Status__c from  SVMXC__Service_Order__c where SVMXC__Case__c =: objCase1.id limit 1];
        objWorkOrder.Integration_Status__c = 'Not Required';
        
        update objWorkOrder;
        Cases.mapWOIdToWorkOrders = null;
        objCase1.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
        objCase1.Verification_Result__c = 'Test';
        objCase1.Record_Updated_from_SFM__c = true;
        objCase1.Status = STRING_CASE_STATUS_CLOSED;
        objCase1.Record_Updated_from_SFM__c = True;
        objCase1.Subject='Testing12345';
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.Product_Serial_Number__c='Test11';
        objCase1.SVMXC__Site__c=objLocation1.id;
        update objCase1;
        
        objCase1.Record_Updated_from_SFM__c = true;
        objCase1.Status = 'Reopened';
        objCase1.Reason_for_Reopen__c = 'Adding Reason for reopen field on case record to cover more than 255 character, This is just to check the functionality that updates work order " Reason for reopen " field from the case and increase the test class code coverage.';
        objCase1.SVMXC__Site__c=objLocation.id;
        update objCase1;
        
        Test.stopTest();
        
        List<SVMXC__Service_Order__c> updateWOSubject = [select Id,Case_Subject__c,SVMX_PS_Subject__c,SVMXC__Case__c,Reason_for_Reopen__c,WO_Reopen_Status__c,Reopen_Requester__c FROM SVMXC__Service_Order__c LIMIT 1];
        /* Code coverage enhancement start */
        Map<Id, Case> mapIdToCase = new Map<Id, Case>();
        Map<Id, SVMXC__Service_Order__c> mapIdToWorkOrder = new Map<Id, SVMXC__Service_Order__c>();
        mapIdToWorkOrder.put(updateWOSubject[0].Id, updateWOSubject[0]);
        updateWOSubject[0].Order_Previous_Status__c =  Label.WorkOrderStatusAssigned;
        updateWOSubject[0].SVMXC__Order_Status__c =  Label.WorkOrderStatusAssignmentAccepted;
        mapIdToCase.put(objCase1.Id,objCase1);
        Map<Id, String> mapCasaeIdToChange = new  Map<Id, String>();
        
        mapCasaeIdToChange.put(objCase1.Id,Cases.CASE_OF_REOPEN_STATUS);
        UpdateWorkOrder_CaseHelper.addWORelatedToReopenCases(updateWOSubject[0],null,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);
        
        mapCasaeIdToChange.put(objCase1.Id,Cases.SUBJECT_DESC_OTHERS_CHANGE);
        UpdateWorkOrder_CaseHelper.addWORelatedToUpdatedCase(updateWOSubject[0],null,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);
        /* Code coverage enhancement end */
        system.assertEquals('Testing12345',updateWOSubject[0].Case_Subject__c,'Work order subject ');
    }

    static testmethod void checkCaseReOpenedStatusFromSFM2() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;
        Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount1.Account_Group__c='Distributor';
        objAccount1.Territory_Region__c='AMR';
        insert objAccount1;

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase1.Date_of_Issue_Awareness__c = Date.Today();
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.SVMXC__Site__c=objLocation.id;
        objCase1.AccountId=objAccount1.id;
        objCase1.Region__c='AMR';
        insert objCase1;
        
        SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'USA','123456990','USD');
        insert objLocation1;
        Test.startTest();
        SVMXC__Service_Order__c objWorkOrder = [Select Id, Integration_Status__c from  SVMXC__Service_Order__c where SVMXC__Case__c =: objCase1.id limit 1];
        objWorkOrder.Integration_Status__c = 'Not Required';
        
        update objWorkOrder;
        Cases.mapWOIdToWorkOrders = null;
        objCase1.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
        objCase1.Verification_Result__c = 'Test';
        objCase1.Record_Updated_from_SFM__c = true;
        objCase1.Status = STRING_CASE_STATUS_CLOSED;
        objCase1.Record_Updated_from_SFM__c = True;
        objCase1.Subject='Testing12345';
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.Product_Serial_Number__c='Test11';
        objCase1.SVMXC__Site__c=objLocation1.id;
        update objCase1;
        
        objCase1.Record_Updated_from_SFM__c = true;
        objCase1.Status = 'Reopened';
        objCase1.Reason_for_Reopen__c = 'Adding Reason for reopen field on case record to cover more than 255 character, This is just to check the functionality that updates work order " Reason for reopen " field from the case and increase the test class code coverage.';
        objCase1.SVMXC__Site__c=objLocation.id;
        update objCase1;
        
        Test.stopTest();
        
        List<SVMXC__Service_Order__c> updateWOSubject = [select Id,Case_Subject__c,SVMX_PS_Subject__c,SVMXC__Case__c,Reason_for_Reopen__c,WO_Reopen_Status__c,Reopen_Requester__c FROM SVMXC__Service_Order__c LIMIT 1];
        /* Code coverage enhancement start */
        Map<Id, Case> mapIdToCase = new Map<Id, Case>();
        Map<Id, SVMXC__Service_Order__c> mapIdToWorkOrder = new Map<Id, SVMXC__Service_Order__c>();
        updateWOSubject[0].Order_Previous_Status__c =  Label.WorkOrderStatusAssigned;
        updateWOSubject[0].SVMXC__Order_Status__c =  Label.WorkOrderStatusAssignmentAccepted;
        mapIdToCase.put(objCase1.Id,objCase1);
        Map<Id, String> mapCasaeIdToChange = new  Map<Id, String>();
        
        mapCasaeIdToChange.put(objCase1.Id,Cases.CASE_OF_REOPEN_STATUS);
        UpdateWorkOrder_CaseHelper.addWORelatedToReopenCases(updateWOSubject[0],null,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);
        
        mapCasaeIdToChange.put(objCase1.Id,Cases.SUBJECT_DESC_OTHERS_CHANGE);
        UpdateWorkOrder_CaseHelper.addWORelatedToUpdatedCase(updateWOSubject[0],null,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);
        /* Code coverage enhancement end */
        system.assertEquals('Testing12345',updateWOSubject[0].Case_Subject__c,'Work order subject ');
    }

    /**
    * @description : to check field updates for reopen request status updates functionality
    * @return testmethod 
    **/
    static testmethod void checkCaseReOpenedRequestedStatusFromSFM() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;

        Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount1.Account_Group__c='Distributor';
        objAccount1.Territory_Region__c='AMR';
        insert objAccount1;

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase1.Date_of_Issue_Awareness__c = Date.Today();
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        insert objCase1;
        Test.startTest();
        SVMXC__Service_Order__c objWorkOrder = [Select Id, Integration_Status__c from  SVMXC__Service_Order__c limit 1];
        objWorkOrder.Integration_Status__c = 'Not Required';
        update objWorkOrder;
        Cases.mapWOIdToWorkOrders = null;
        objCase1.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
        objCase1.Verification_Result__c = 'Test';
        objCase1.Record_Updated_from_SFM__c = true;
        objCase1.Status = STRING_CASE_STATUS_CLOSED;
        objCase1.Record_Updated_from_SFM__c = True;
        objCase1.AccountId=objAccount1.id;
        objCase1.Region__c='AMR';
        objCase1.Subject = 'test';
        update objCase1;
        objCase1.Record_Updated_from_SFM__c = true;
        objCase1.Reopen_Requester__c=UserInfo.getUserId();
        objCase1.Reason_for_Approval_Denial_of_Reopen__c='Testing';
        objCase1.Status = 'Reopen Requested';
        objCase1.Reason_for_Reopen__c = 'test';
        update objCase1; 
        objCase1.Status = 'In Progress';
        update objCase1;
        Test.stopTest();
        Map<Id, Case> mapIdToCase = new Map<Id, Case>();
        Map<Id, SVMXC__Service_Order__c> mapIdToWorkOrder = new Map<Id, SVMXC__Service_Order__c>();
        Map<Id, String> mapCasaeIdToChange = new  Map<Id, String>();

        List<SVMXC__Service_Order__c> updateWOSubject = [select Id, SVMXC__Case__c, Reason_for_Approval_Denial_of_Reopen__c, WO_Precompletion_Status__c FROM SVMXC__Service_Order__c LIMIT 1];
       
        mapIdToCase.put(objCase1.id, objCase1);
        mapIdToWorkOrder.put(updateWOSubject[0].id, updateWOSubject[0]);
        mapCasaeIdToChange.put(objCase1.Id,Cases.CASE_OF_REOPENED_DENIED);

        UpdateWorkOrder_CaseHelper.addWORelatedToReopenCases(updateWOSubject[0],null,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);

        system.assertEquals('Testing',updateWOSubject[0].Reason_for_Approval_Denial_of_Reopen__c,'Work order reason for Approval or denial ');
        
    }

    /**
    * @description :To validate functionality of  location update on WO based on case location change
    **/
    static testmethod void checkCaseReOpenedStatusFromSFMtest() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.Date_of_Issue_Awareness__c = Date.Today();
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        insert objCase1;
        
        SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'USA','123456990','USD');
        insert objLocation1;
        SVMXC__Service_Order__c objWorkOrder = [Select Id, Integration_Status__c from  SVMXC__Service_Order__c where SVMXC__Case__c =: objCase1.id limit 1];
        objWorkOrder.Integration_Status__c = 'Not Required';
        update objWorkOrder;
        Test.startTest();
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.SVMXC__Site__c=objLocation1.id;
        update objCase1;
        Test.stopTest();
    
        List<SVMXC__Service_Order__c> updateWOSubject = [select Id,SVMXC__Site__c, SVMXC__Case__c FROM SVMXC__Service_Order__c where SVMXC__Case__c=:objCase1.id LIMIT 1];
        Map<Id, Case> mapIdToCase = new Map<Id, Case>();
        Map<Id, SVMXC__Service_Order__c> mapIdToWorkOrder = new Map<Id, SVMXC__Service_Order__c>();
        Map<Id, String> mapCasaeIdToChange = new  Map<Id, String>();
       
        mapIdToCase.put(objCase1.id, objCase1);
        mapIdToWorkOrder.put(updateWOSubject[0].id, updateWOSubject[0]);
        mapCasaeIdToChange.put(objCase1.Id,Cases.CASE_OF_LOCATION_CHANGE);
        
        UpdateWorkOrder_CaseHelper.addWORelatedToUpdatedCase(updateWOSubject[0],null,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);

        system.assertEquals(objCase1.SVMXC__Site__c,updateWOSubject[0].SVMXC__Site__c,'Location update ');
        
    }

    static testmethod void checkCaseReOpenedStatusFromSFMtest2() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Source_System__c = 'SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.Date_of_Issue_Awareness__c = Date.Today();
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        insert objCase1;
        
        SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'USA','123456990','USD');
        insert objLocation1;
        SVMXC__Service_Order__c objWorkOrder = [Select Id, Integration_Status__c from  SVMXC__Service_Order__c where SVMXC__Case__c =: objCase1.id limit 1];
        objWorkOrder.Integration_Status__c = 'Not Required';
        update objWorkOrder;
        Test.startTest();
        objCase1.Evaluation__c='Test1';
        objCase1.Verification_Result__c='Test1';
        objCase1.Work_Performed__c='Test1';
        objCase1.SVMXC__Site__c=objLocation1.id;
        update objCase1;
        Test.stopTest();
    
        List<SVMXC__Service_Order__c> updateWOSubject = [select Id,SVMXC__Site__c, SVMXC__Case__c FROM SVMXC__Service_Order__c where SVMXC__Case__c=:objCase1.id LIMIT 1];
        Map<Id, Case> mapIdToCase = new Map<Id, Case>();
        Map<Id, SVMXC__Service_Order__c> mapIdToWorkOrder = new Map<Id, SVMXC__Service_Order__c>();
        Map<Id, String> mapCasaeIdToChange = new  Map<Id, String>();
       
        mapIdToCase.put(objCase1.id, objCase1);
        mapCasaeIdToChange.put(objCase1.Id,Cases.CASE_OF_LOCATION_CHANGE);
        
        UpdateWorkOrder_CaseHelper.addWORelatedToUpdatedCase(updateWOSubject[0],null,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);

        system.assertEquals(objCase1.SVMXC__Site__c,updateWOSubject[0].SVMXC__Site__c,'Location update ');
        
    }

}
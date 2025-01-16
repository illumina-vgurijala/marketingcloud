/*@ author       : Raja Siva Krishna
* @ date         : 26-11-2020
* @ Description  : Test class for TestDocumentUploadController class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Raja Siva Krishna       26-11-2020                 DCP-43185            Initial version
* 
*/
@IsTest(SeeAllData=false)
public with sharing class TestDocumentUploadController {
    /*Initial data setup*/
    @testSetup
    static void initializeTestData() {
    Work_Order_Activity_Rules__c objWoActivityRule = new Work_Order_Activity_Rules__c();
    Id recId = Schema.SObjectType.Work_Order_Activity_Rules__c.getRecordTypeInfosByName().get('Document Compliance').getRecordTypeId();
    objWoActivityRule.RecordTypeId = recId;
    objWoActivityRule.Document_Name__c = 'TestClass1234';
    objWoActivityRule.Document_Number__c = '123456';
    objWoActivityRule.Name = 'TestClass1234';
    objWoActivityRule.Activity_Type__c = 'Installation';
    objWoActivityRule.Product_Group__c = 'AmpliSeq Library Prep';
    objWoActivityRule.Generic_Document__c = true;
    objWoActivityRule.Required__c = false;
    objWoActivityRule.Active__c=true;
        insert objWoActivityRule;
        //Approving the Record
         Set<Id> pIds = (new Map<Id, ProcessInstance>([SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId = :objWoActivityRule.Id])).keySet();
        Set<Id> pInstanceWorkitems = (new Map<Id, ProcessInstanceWorkitem>([SELECT Id,ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstanceId in :pIds])).keySet();
        
        for (Id pInstanceWorkitemsId:pInstanceWorkitems){
            Approval.ProcessWorkitemRequest req2 =  new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
          req2.setWorkitemId(pInstanceWorkitemsId);
            Approval.process(req2);
        }
    }
    /*
    Description: testGetWrapperDetails for testing wrapper details
    */
    @IsTest
    public static void testGetWrapperDetails(){ 
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Account',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Contact',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Installed_Product__c'
        );
        insert apexSettings;
        initializeTestData();    
        //insert account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact objContact = TestDataContact.getNewContact(acc);
                //insert product
                Product2 objProduct1=TestDataFieldService.createProduct('Test Product','Instrument');
                objProduct1.product_Group__c='AmpliSeq Library Prep';
                objProduct1.Source_System__c='SAP';
                insert objProduct1;
                system.debug('DCP-43185-objProduct1:'+objProduct1);
        //insert installed product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.SVMXC__Product__c = objProduct1.Id;
        insert objInstalledProduct;
        //insert case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;

        
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc;
        //insert workorder
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');       
        workOrder.SVMXC__Company__c = acc.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Product__c = objProduct1.Id;
       // workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        workOrder.Partner_Installation_WO__c = true;
        insert workorder;
        Test.startTest();
        //Insert Product Stock
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = objProduct1.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;
        //insert workdetails
        Id recId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get('Usage/Consumption').getRecordTypeId();
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.RecordTypeId = recId;
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Activity_Type__c = 'Installation';
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Product__c = objProduct1.Id;
        objOrderDetail.SVMXC__Line_Type__c = 'Labor';
        objOrderDetail.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;                             
        objOrderDetail.SVMXC__Is_Billable__c = true;
        insert objOrderDetail;
        ContentVersion objCV;
        objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
        insert objCV;
        objCV.Document_Type_fileupload__c = 'LWC1';
        update objCV;
        system.assertNotEquals(null,objCV.id);
        Test.stopTest();
        objCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, workOrder.Id,'V','AllUsers');
        insert objCDL;    
        //SVMXC__Service_Order__c sampleWo = [select id,name,SVMXC__Product__c,SVMXC__Order_Type__c from SVMXC__Service_Order__c where SVMXC__Order_Type__c= 'Field Service'];
        DocumentUploadController.WorkDetailsFieldsWrapper wrapperDetails = DocumentUploadController.getWrapperFieldDetails(workorder.Id);
        WorkOrderDocumentUploadController.initRecord(workorder.Id);
        WorkOrderDocumentUploadController.getInstalledProductId(workorder.Id);
        //WorkOrderDocumentUploadController.DataWrapper newDataWrapper = WorkOrderDocumentUploadController.DataWrapper();
        system.assert(wrapperDetails.mapContentDocIdtoDocName.size()>0);
        try{
             DocumentUploadController.getWrapperFieldDetails(null);
        }
        catch(Exception e){
            system.assert(e.getMessage().contains('Script-thrown exception'));
        }
    }
}
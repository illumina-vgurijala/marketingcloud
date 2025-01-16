/***************************************************************************************************************************************
 * NAME   :  TestContentDocumentLinks 
 * DESCRIPTION  : Test class for ContentDocumentLinks.
 *          Added logic for DCP-804  
 * @AUTHOR : Debalina
 * @DATE   : 08-Jun-2018  
 *  
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Debalina              08-Jun-2018             Initial Version. 
 * Prashanth             28-Jun-2019             Modified to increase the coverage (DCP-26892)
 * Prem Ranjan           23-11-2021              Modification to cover logic for DCP-50569 Territory Planning: Reporting ability T/F "Is file attached?"
 * Prem Ranjan           04/03/2022              TASK0720146- Updated to cover PlanAndAccPlanAttachmentQueueable (future to Queueable modification)
 * Shivani Jain          04/04/2022              DCP-49914 Optimize WeChat case and follower management in SFDC
 *   Nidhi               04-March-2024           [CMCM-3329] [CP] - Enable Access to Attachments on FAN's 
****************************************************************************************************************************************/ 
@isTest(SeeAllData = true)
public class TestContentDocumentLinks {
    static final String COMMENT_TYPE_WECHAT = 'WeChat Comment'; //DCP-49914
    public static final String STRING_TIMEZONE = 'America/Los_Angeles';

    static Case cs;
    static SVMXC__Installed_Product__c svm;  
    static SVMXC__Site__c siteNew;
    static Contact objCon;
    //added by prashanth
    static Account acc;
	
	/*
    * Method to Setup data for test class
    */	    
    public static void initializeTestData() {
        TestDataFieldService.createSettings();
        //added by prashanth
        acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        
        //changed by prashanth
        svm = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        svm.SVMXC__Company__c = acc.Id;
        svm.Operation_Status__c='Off';
        svm.name = 'Test';
        svm.SVMXC__Status__c = 'Shipped';
        insert svm;
        
        siteNew = new SVMXC__Site__c();
        siteNew.name = 'Test';
        insert siteNew;
        
        //added by prashanth
        objCon  = TestDataPerson.getNewContact(acc.Id);
        
        cs = TestDataCase.initServiceRequestCase(objCon);
        cs.SVMXC__Component__c = svm.id;
        cs.SVMXC__Site__c = siteNew.id;
        insert cs;
        
    }

    static testMethod void validateWorkOrderAttachment(){
        initializeTestData();
        

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        objWorkOrder.SVMXC__Component__c = svm.id;
        objWorkOrder.SVMXC__Site__c = siteNew.id;
		objWorkOrder.Record_Created_from_SFM__c=true;
		//added by prashanth
		objWorkOrder.SVMXC__Company__c = acc.Id;
        Test.startTest();
        insert objWorkOrder;
         
        string stringBlobValue = 'Testing base 64 encode';            
        Blob blobDummyContent = Blob.valueOf(stringBlobValue);
        ContentVersion objContentVersion=new ContentVersion(ContentLocation='S', Origin='H', PathOnClient='to render as PDF.txt', Title='to render as PDF', VersionData=blobDummyContent, FirstPublishLocationId=objWorkOrder.id);
        insert objContentVersion;
        
        //file attachment should be allowed since status is not "Closed"
        system.assertNotEquals(null,objContentVersion.id);
        
        List<ContentDocument> listDocuments = [SELECT Id, Title, LatestPublishedVersionId, ParentId FROM ContentDocument where LatestPublishedVersionId=:objContentVersion.id];
        system.assert(listDocuments.size()>0);
        Test.stopTest();
        
        //close the work order
        objWorkOrder.SVMXC__Order_Status__c='Closed';
		objWorkOrder.PO_Number__c = '123456';
        update objWorkOrder;
        
        
        //this insert should fail
        try{
            objContentVersion=new ContentVersion(ContentLocation='S', Origin='H', PathOnClient='to render as PDF2.txt', Title='to render as PDF2', VersionData=blobDummyContent, FirstPublishLocationId=objWorkOrder.id);
            insert objContentVersion;
        }
        catch(exception ex){
            system.assertNotEquals('',ex.getmessage());
            system.debug('Exception: '+ex.getMessage());
        }
        
    }
    testMethod static void testContentLinkInsertPositiveUseCase(){
        initializeTestData();
        List<User> lstUsers = [SELECT Id 
                              FROM User 
                                WHERE Profile.Name =: System.label.Field_Service
                                AND IsActive = true
                                LIMIT 1];
        Test.startTest();
        ContentVersion objCV;
        if(!lstUsers.isEmpty()){
            Case objCase = TestDataCase.initServiceRequestCase(objCon);
            SVMXC__Service_Order__c objWO = 
            TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
            insert objWO;
            system.assertNotEquals(null,objWO.id);
            //Create Installed Product and Account
            //Account objAcc = TestDataAccount.getAccount('TestAccount','USD');
            Account objAcc = TestDataAccount.getCustomerAccount();
            
            insert objAcc;
            system.assertNotEquals(null,objAcc.id);
            SVMXC__Installed_Product__c objIP = TestDataFieldService.createInstalledProduct('TestClassProd', 
                                                    'USD',
                                                    'Installed');  
            insert objIP;
            system.assertNotEquals(null,objIP.id);
            objWO.SVMXC__Company__c = objAcc.Id;
            objWO.SVMXC__Component__c = objIP.Id;
            update objWO;
            objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
            insert objCV;
            system.assertNotEquals(null,objCV.id);
            objCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];
            ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, objWO.Id,'V','AllUsers');
            insert objCDL;
            system.assertNotEquals(null,objCDL.id);
            delete objCDL;
            List<ContentDocumentLink> lstCDL=new List<ContentDocumentLink>();
            lstCDL=[select id,ContentDocumentId from ContentDocumentLink where LinkedEntityId=:objAcc.id];
            system.assertEquals(0,lstCDL.size());
        }
        Test.stopTest();
        
    }  
/* METHOD NAME   : testUpdateIsFileAttached
* DEVELOPER      : Prem Ranjan
* USER STORY     : DCP-50569 Territory Planning: Reporting ability T/F "Is file attached?"
* DESCRIPTION    : TestMethod for pdateIsFileAttachedTrue
* RETURN TYPE    : NA
* PARAMETER      : NA
*/
static testMethod void testUpdateIsFileAttached(){
    ContentVersion objCV;
    Account acc1 = TestDataAccount.initAccount();
    acc1.ERP_Customer_Id__c = '123456';
    acc1.Territory_Region__c = 'AMR';    
    Account acc2 = TestDataAccount.initAccount();
    List<Account> lstAcc = new List<Account>();
    lstAcc.add(acc1);
    lstAcc.add(acc2);
    insert lstAcc;
    Territory2 objTr = TestPlans.getTerritory();
    TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,lstAcc[0].id);
    TestDataObjectTerritory2Association.getObjectAssociationFuture(objTr.id,lstAcc[1].id);
    TestDataAccountPlan.getNewAccountPlan(acc1);
    
    Plan__c objPlan = TestDataPlan.getPlan(objTr.id);
    
    objPlan.Name = 'Sample Plan1';
    objPlan.Is_file_attached__c = false;
    objPlan.Territory_Name__c = objTr.Name;
    objPlan.Territory_Code__c = objTr.Territory_Code__c;
    objPlan.Status__c = Label.PlanStatusActive;
    Account_Plan__c ap = TestDataAccountPlan.getNewAccountPlan(lstAcc[0]);
    ap.Name = 'Test Account Plan';
    ap.Is_file_attached__c = false;
    update ap;
    
    insert objPlan;
    set<Id> planId =new set<Id>();
    set<Id> accPlanId =new set<Id>();
    planId.add(objPlan.Id);
    accPlanId.add(ap.Id);
    
    Test.startTest();
    objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
    insert objCV;
    system.assertNotEquals(null,objCV.id,'Assert Failed objCV.id is null');
    objCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];
    ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, objPlan.Id,'V','AllUsers');
    insert objCDL;
    ContentDocumentLink objCDL1 = TestDataFieldService.createDocLink(objCV.ContentDocumentId, ap.Id,'V','AllUsers');
    insert objCDL1;
    PlanAndAccPlanAttachmentHandler.updateIsFileAttachedTrue(accPlanId,planId);
    //system.assertEquals(objPlan.Is_file_attached__c,True);
    system.debug('objPlan.Is_file_attached__c' + objPlan.Is_file_attached__c);
    system.assertNotEquals(null,objCDL.id,'Assert Failed objCV.id is null');
    delete objCDL;
    delete objCDL1;
    List<ContentDocumentLink> lstCDL=new List<ContentDocumentLink>();
    lstCDL=[select id,ContentDocumentId from ContentDocumentLink where LinkedEntityId=:objPlan.id];
    system.assertEquals(0,lstCDL.size(),'Assert Failed lstCDL.size() is not equals 0');
    PlanAndAccPlanAttachmentHandler.updatePlanIsFileAttachedFalse(planId);
    PlanAndAccPlanAttachmentHandler.updateAccPlanIsFileAttachedFalse(accPlanId);
    system.assertEquals(False,objPlan.Is_file_attached__c,'Assert Failed because objPlan.Is_file_attached__c is True');
    Test.stopTest(); 
    }

    /*******************************************************************************************************
    * @description DCP-49914 test method for insertFromCommentToCase
    */
    static testmethod void insertFromCommentToCaseTest() {
        Account objAcc = TestDataAccount.getNewAccount();
        System.assert(objAcc.Id != NULL, 'Account insertion failed');

        Contact con = new Contact(FirstName = 'firstname', LastName = 'lastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='testid@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        System.assert(con.Id != NULL, 'Contact insertion failed');

        Case caseRec = TestDataCase.initServiceRequestCase(con);
        insert caseRec;
        System.assert(caseRec.Id != NULL, 'Case insertion failed');

        Comment__c commentRec = new Comment__c();
        commentRec.Name = 'Sent by Test User';
        commentRec.recordTypeId = Schema.SObjectType.Comment__c.getRecordTypeInfosByName().get('Case - WeChat').getRecordTypeId();
        commentRec.Case__c = caseRec.Id;
        commentRec.Comment__c = 'Test Comment';
        commentRec.Type__c = COMMENT_TYPE_WECHAT;
        insert commentRec;

        System.assert(commentRec.Id != NULL, 'Comment insertion failed');

        ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'TestDoc.txt', 'Test Content', true);
        insert objCV;
        system.assert(objCV.id != NULL, 'Assert Failed objCV.id is null');
        objCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];

        Test.startTest();
        ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, commentRec.Id, 'V', 'AllUsers');
        insert objCDL;
        System.assert(objCDL.id != NULL, 'Creation of Content Document link failed');
        Test.stopTest();

        List<ContentDocumentLink> objCDLForCaseList = [SELECT id FROM ContentDocumentLink WHERE LinkedEntityId =: caseRec.Id];
        System.assert(objCDLForCaseList != NULL && objCDLForCaseList.size() == 1, 'Content Document inserted on comment didnt attach to case');
    }
    /* METHOD NAME   : testFANVisibility
* DEVELOPER      : Nidhi
* USER STORY     :[CMCM-3329] [CP] - Enable Access to Attachments on FAN's
* DESCRIPTION    : TestMethod for FAN Visibility
*/
    static testmethod void testFANVisibility() {
            SVMXC__Site__c objLocationRecTest = new SVMXC__Site__c(Name = 'test');
            insert objLocationRecTest;
            SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderRecord('Return', 'Open','188', 'Test', 'Test', null);
            objPartsOrder.SVMXC__Source_Location__c = objLocationRecTest.id;
            insert objPartsOrder;
            SVMXC__Installed_Product__c objIP = TestDataFieldService.createInstalledProduct('TestClassProd','USD','Installed');  
            insert objIP;
            Product2 objProduct = TestDataFieldService.createProduct('Test Product','Instrument');
            objProduct.Service_Product_Type__c = 'Instrument';
        	objProduct.Condition_Type__c = 'LOANER';
            objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
            objProduct.Serial_Number_Profile__c = 'IL02';
            insert objProduct;
            system.assertNotEquals(null,objIP.id);
            Test.startTest();
            List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
            SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
            objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
        	objPartsOrderLine.SVMXC__Serial_Number__c = objIP.id;
        	objPartsOrderLine.Tracking_Number__c = '747474';
        	objPartsOrderLine.SVMXC__Product__c = objProduct.id;
            insert objPartsOrderLine;
        	objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
        	update objPartsOrderLine;
            Field_Action_Notification__c fan =TestDataFieldService.createFAN('Notification');
            insert fan;
            Test.stopTest();
            ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'TestDoc.txt', 'Test Content', true);
            insert objCV;
            ContentVersion objCV1 = TestDataFieldService.createDocVersion('TestDoc', 'TestDoc.txt', 'Test Content', true);
            insert objCV1;
            objCV = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];
            objCV1 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV1.Id];
            ContentDocumentLink objCDL = TestDataFieldService.createDocLink(objCV.ContentDocumentId, objPartsOrderLine.Id, 'V', 'AllUsers');
            cdList.add(objCDL);
            ContentDocumentLink objCDL1 = TestDataFieldService.createDocLink(objCV.ContentDocumentId, fan.Id, 'V', 'InternalUsers');
            cdList.add(objCDL1);
            insert cdList;
            List<ContentDocumentLink> ipcontentDocList = [SELECT Visibility  FROM ContentDocumentLink WHERE LinkedEntityId = :objIP.id];
			Assert.areEqual(ipcontentDocList[0].Visibility , 'AllUsers');
            List<ContentDocumentLink> contentDocList = [SELECT Visibility  FROM ContentDocumentLink WHERE LinkedEntityId = :fan.id];
            Assert.areEqual(contentDocList[0].Visibility , 'AllUsers');
    }
}
/*@ author       : Raja Siva Krishna
* @ date         : 26-11-2020
* @ Description  : Test class for TestUploadAttachmentController class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Raja Siva Krishna       26-11-2020                 DCP-43185            Initial version
* 
*/
@IsTest(SeeAllData=false)
public with sharing class TestUploadAttachmentController {
    
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';//DCP-49741
    public static final String STRING_ACCOUNT = 'Test Acc';//DCP-49741
    static Case cs;//DCP-49741
    /**
    *  @author Pooja Shalwadi
    *  @description: This test method is used to setup the data for Account,contact and case object
    *	User Story: DCP-49741
    **/
    @testSetup
    public static void initializeTestData()
    {
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        //insert case        
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.id != null);
    }   
    
    /**
    *  @author Raja Siva Krishna
    *  @description to test created content document link records for given objbect and file Id
    **/
    @IsTest
    public static void testCreateFileRecInIP(){
        Test.startTest();
        ContentVersion objCV;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert objInstalledProduct;
        objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
        insert objCV;
        system.assertNotEquals(null,objCV.id,'Content version not found');
        ContentVersion objCV1 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :objCV.Id];
        system.assertNotEquals(null,objCV1.ContentDocumentId,'Content Document Id is not found');
        UploadAttachmentController.createFileRecInIP(objInstalledProduct.Id,objCV1.ContentDocumentId);
        List<ContentDocumentLink> lstCDL = [select id,ContentDocumentId from ContentDocumentLink where LinkedEntityId=:objInstalledProduct.Id];
        system.assertEquals(1,lstCDL.size(),'Document content link record not created.');
        try{
            UploadAttachmentController.createFileRecInIP(objInstalledProduct.Id,'1234');
        }
        catch(Exception e){
            system.assert(e.getMessage().contains('Script-thrown exception'),'Error in Script.');
        }
        Test.stopTest();
    }

    /**
*  @author Pooja Shalwadi
*  @description: This test method is used to test the functionality of creating contentversion and updating the Installation Type work order
*	User Story: DCP-49741
**/
@isTest
    public static void testSaveFiles(){
        initializeTestData();  
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');	
        workOrder.SVMXC__Order_Type__c='Installation';	
        workOrder.Is_Auto_Created__c = true; 	
        insert workOrder;
        System.assert(workOrder.id != null);
        
        Test.startTest(); 
        UploadAttachmentController.saveFiles(workOrder.id);
        Test.stopTest();
        
        List<SVMXC__Service_Order__c> lstWO=[SELECT id,Acceptance_Status__c,Acceptance_Forecast_in_Current_Quarter__c 
                                       FROM SVMXC__Service_Order__c 
                                       WHERE SVMXC__Order_Type__c='Installation' LIMIT 1];
        
        system.assertEquals('Completed',lstWO[0].Acceptance_Status__c);
        system.assertEquals('100% Completed - LOA Signed',lstWO[0].Acceptance_Forecast_in_Current_Quarter__c);
       
    }
}
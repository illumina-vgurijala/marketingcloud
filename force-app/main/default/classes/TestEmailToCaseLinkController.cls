/***************************************************************************************************************************************
 * NAME   : TestAutoCompleteController
 * DESCRIPTION  : TestClass for AutoCompleteController Class
 * @AUTHOR : Vaibhav
 * @DATE   : 15-May-2019  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pooja                    23-Sep-2022         CodeScan Fixes
 * --------------------------------------------------------------------------------------------------------------------------------------
 ****************************************************************************************************************************************/
@isTest
public with sharing class TestEmailToCaseLinkController {

    public static final boolean BOOLEAN_CONSUMABLES_INCLUDED = false;
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';

    @TestSetup
    static void setupData() {

        //create a case and associate it with an emailMessage record.
        Account objAccount = TestDataAccount.getNewAccount();

        Test.startTest();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        insert objServiceContract;
        SVMXC__Service_Contract__c insertedServiceContract = [Select Consumables_Included__c from SVMXC__Service_Contract__c where Id =: objServiceContract.Id];
        System.assertEquals(insertedServiceContract.Consumables_Included__c, BOOLEAN_CONSUMABLES_INCLUDED);

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location', 'Test Street', 'Ireland', '123456', 'USD');
        insert objLocation;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
        System.assertEquals(insertedInstalledProduct.SVMXC__Status__c, STRING_INSTALLED_PRODUCT_STATUS);

        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        SVMXC__Service_Contract_Products__c insertedCoveredProduct = [Select SVMXC__Installed_Product__c from SVMXC__Service_Contract_Products__c where SVMXC__Installed_Product__c =: objInstalledProduct.Id];
        System.assertEquals(insertedCoveredProduct.SVMXC__Installed_Product__c, objInstalledProduct.Id);

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        objCase.SVMXC__Site__c = objLocation.Id;
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        insert objCase;
        Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
        System.assertEquals(InsertedCase.SVMXC__Component__c, objInstalledProduct.Id);

        Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.CurrencyIsoCode = 'USD';
        objEntitlement.Case_Number__c = objCase.id;
        insert objEntitlement;
        List<Applied_Contract__c> insertedEntitlement = [Select Case_Number__c from Applied_Contract__c where Case_Number__c =: objCase.Id];
        System.assertEquals(insertedEntitlement[0].Case_Number__c, objCase.Id);

        Test.stopTest();

        //create an email message record and associate it with a case.
        EmailMessage objEmail1 = new EmailMessage();
        objEmail1.FromAddress = '';
        objEmail1.ToAddress = '';
        objEmail1.CcAddress = '';
        objEmail1.BccAddress = '';
        objEmail1.Subject = 'Test email';
        objEmail1.TextBody = 'Test Text Body';
        objEmail1.htmlBody = 'Test HTML Body thread::OElU-Ec7dhKBGLNk6uw2UEA::';
        objEmail1.ParentId = objCase.Id;

        insert objEmail1;
		
		//Create Document - //DCP-34276
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
         
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
         
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objEmail1.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;

    }

    /*
     *  @author Vaibhav Parashar
     *  @description - To test the code which creates a new email message and associate it with the selected case.
     */
    testMethod static void testCopyToExistingCase() {

        Map < String, String > caseIdToEmailMessageId = new Map < String, String > ();

        //pass the caseIdToEmailMessageId to move to existing case.
        EmailMessage eMsg = [Select Id from EmailMessage Limit 1];
        Case caseRec = [Select Id from Case Limit 1];
        caseIdToEmailMessageId.put(caseRec.Id, eMsg.Id);

        //execute main method
        String processingStatus = EmailToCaseLinkController.moveToExisitingCase(caseIdToEmailMessageId);
        Map < Id, EmailMessage > emailMessageIdToEmailMessage = New Map < Id, EmailMessage >([Select Id from EmailMessage]);
        List<EmailMessage> clonedEmailMsg = [Select Id,htmlBody from EmailMessage where ParentId =: caseRec.Id LIMIT 2];
        system.assertNotEquals(clonedEmailMsg[0].htmlBody, clonedEmailMsg[1].htmlBody, 'The HTML Body should not be same');
        //assert if the new email record got created.
        System.assertEquals(2, emailMessageIdToEmailMessage.values().size());
        System.assertEquals('Operation Successfull', processingStatus);
        
        //DCP-34276 - there should be 2 attachments in total.
        List<ContentDocumentLink> lstAttachments =  [Select ContentDocument.title,ContentDocumentId,LinkedEntityId from ContentDocumentLink where LinkedEntityId IN: emailMessageIdToEmailMessage.keyset()];
        System.assertEquals(2, lstAttachments.size());
		
		//DCP-34276 - Assert if an attachment went to Case as well.
        List<ContentDocumentLink> lstAttachmentsCase =  [Select ContentDocument.title,ContentDocumentId,LinkedEntityId from ContentDocumentLink where LinkedEntityId =: caseRec.Id];
        System.assertEquals(1, lstAttachmentsCase.size());
        
    }

    /*
     *  @author Vaibhav Parashar
     *  @description - To test exceptions like null pointer.
     */
    testMethod static void testCopyToExistingCaseExceptions() {

        Map < String, String > caseIdToEmailMessageId = new Map < String, String > ();

        //pass the caseIdToEmailMessageId to move to existing case.
        EmailMessage eMsg = [Select Id from EmailMessage Limit 1];
        caseIdToEmailMessageId.put(null, eMsg.Id);

        //pass null to the controller method.
        String processingStatus = EmailToCaseLinkController.moveToExisitingCase(caseIdToEmailMessageId);

        //assert if the code went into catch block
        System.assertNotEquals('Operation Successfull', processingStatus);

    }

    /*
     *  @author Vaibhav Parashar
     *  @description - To get the relatedTo Sobject name by passing the email message id.
     */
    testMethod static void testcheckRelatedToSObject() {
        //get the email message id.
        EmailMessage eMsg = [Select Id from EmailMessage Limit 1];

        //get the sObject relatedToId
        String sobjectName = EmailToCaseLinkController.getRelatedToSobject(eMsg.Id);

        //assert if the returned SobjectName was Case.
        System.assertEquals('Case', sobjectName);

    }

}
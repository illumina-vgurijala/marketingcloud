/***************************************************************************************************************************************
 * NAME   : TestSendEmailToASOPFromCase
 * DESCRIPTION  : TestClass for SendEmailToASOPFromCase Class
 * @AUTHOR : Vaibhav
 * @DATE   : 3-Sep-2020  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 ****************************************************************************************************************************************/
@isTest
public with sharing class TestSendEmailToASOPFromCase {

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
        objEmail1.htmlBody = 'Test HTML Body';
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
     *  @description - testSendingEmailWithAttachmentFromCaseScreen.
     */
    testMethod static void testSendingEmailWithAttachmentFromCaseScreen() {
    
        Case caseRec = [Select Id from Case Limit 1];
        
        Test.StartTest();
        //execute main method
        SendEmailToASOPFromCase.EmailMessageWrapper emailMessageWrapper = SendEmailToASOPFromCase.runASOPEmailBusinessLogic(caseRec.Id,'Case','OnLoad','',null);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, invocations, 'An email has been sent');
        System.assertEquals('Success: Email Sent to ASOP successfully.', emailMessageWrapper.uiDisplayMessage, 'Email Sent Successfully');
        
    }
    
    /*
     *  @author Vaibhav Parashar
     *  @description - testSendingEmailWithAttachmentFromEmailScreen.
     */
    testMethod static void testSendingEmailWithAttachmentFromEmailScreen() {

        EmailMessage emailMessageObj = [Select Id from EmailMessage Limit 1];
        
        Test.StartTest();
        //execute main method
        SendEmailToASOPFromCase.EmailMessageWrapper emailMessageWrapper = SendEmailToASOPFromCase.runASOPEmailBusinessLogic(emailMessageObj.Id,'EmailMessage','OnLoad','',null);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(0, invocations, 'An email has not been sent');
        System.assertEquals('', emailMessageWrapper.uiDisplayMessage, 'Stopped at UI for email Message screen');
        
        
    }
    
    
    /*
     *  @author Vaibhav Parashar
     *  @description - method to test upload of files from lwc ui.
     */
    testMethod static void testSendingEmailFromEmailScreenUploadFiles() {
    
        List < Map < String, Object >> files = new List < Map < String, Object >>();
    
        files.add(new Map < String, Object >{
        'pathOnClient' => 'Salesforce Report Filters.PNG',
        'title' => 'Salesforce Report Filters',
        'versionData' => 'iVBORw0KGgoAAAANSUhEUgAAAjQAAADXCAYAAAANxMsGAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAFiUAABYlAUlSJPAAAEDrSURBVHhe7Z3Pa11Jm981f8XNUuBFHLxoZWXtrKEXVsaLPoMXUeiFR+mFxRBeNGZolB6II96FufTCqAcajQlvkBdvRiZ0Rg3Tg0ziIBMaZJoGmdBBXjREGS/uogl3oDN49aTq/Kh6quqpOnV/6N57pG/Dh/atUz+eeqrO83x1zrn3LJH678OHDwAAAAAAnQWCBgAAAACdB4IGAAAAAJ0HggYAAAAAnQeCBgAAAACdB4IGAAAAAJ0HggYAAAAAnQeCBgAAAACdpxQ0P/zwAwAAAABAZ4Gg'
        });
 
        EmailMessage emailMessageObj = [Select Id from EmailMessage Limit 1];
        
        Test.StartTest();
        //execute main method
        SendEmailToASOPFromCase.EmailMessageWrapper emailMessageWrapper = SendEmailToASOPFromCase.runASOPEmailBusinessLogic(emailMessageObj.Id,'EmailMessage','sendEmailClicked','searchterm',files);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, invocations, 'An email has been sent');
        System.assertEquals('Success: Email Sent to ASOP successfully.', emailMessageWrapper.uiDisplayMessage, 'Email Sent Successfully');
        
     }
    

}
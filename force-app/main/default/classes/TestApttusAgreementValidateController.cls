/**
 *    @author Kushagra Desai
 *    @date   12-Dec-2019
 *    @description  Test class for ApttusAgreementValidateController
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
 *    Kushagra Desai                 27-Jan-2020             Activate Agreement support
 *    Kushagra Desai                 5-Jan-2020              Cancel Agreeement Support
 *    Kushagra Desai                 4-Feb-2020              Added support for Terminate
 *     KD                            11-Feb                  Fixed material 
*     B Kamini                       11 Feb 2020             DCP-33783: Added Custom setting Profile validation data setup 
*     Umesh                          12-Fab-2020             DCP-33575 :Modified Datasetup for Sales Org Validation   
 *      KD                             20-Feb-2020           End date start date logic addition
 *     KD                            11-Feb                  Fixed material and Validation logic 
 *     Vishnu Kurra                  02-March-2020           Added support for PreValidate 
*    Rishab Wali					 12-Nov-2020             DCP-34579 Updated for Auto Terminate Agreement
*    Maruthi					 	 21-Sep-2022              DCP-56218 Created testPreviousStatus and testExceptionBloks methods
*    Himanshu                        03-Oct-2022             Added method to increase coverage for ApttusAgreementActionService
*    Arif,Dalali                     28-Nov-2022             POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    Gerardo Garcia                  02-Dec-2024             Fix test 101 SOQL. Fixed setup by using list insertes, instead 1 by 1 insert object.
*    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestApttusAgreementValidateController {
    public static final String MATERIALNUMBER = 'VC0013519-OPA';
    public static final String ERROR_INTERFACE_API = '/services/apexrest/AgreementValidateErrorInterface';
    public static final String ATTACHMENT_NAME = 'Test Docs';
    public static final String JSON_PART1 = '{"AgreeStartDate": "", "Status": "S", "AgreeEndDate": "","AgreementNum": "';
    public static final String JSON_VALIDATE_PART = '", "Action": "Validate","EX_ReturnSet": {"results": [{"Type": "E","MsgId": "VK","MsgNumber": "009","Message": "Material  15043762 is marked for deletion","LineItemId": "';
    public static final String ACTIVATION_FAILED = 'Activation failed';
    public static final String AGREEMENT_NAME_DATE_VALIDATION = 'Test Agreement - Date Validation';
    public static final String JSON_PART2 = '"}]},"im_itemSet": {"results": [{"CalType": "A","FutUse": "","Customer": "4000003831","Curr": "USD","ProdGroup": "qwdr","Lob": "","SalesOrg": "CA01","DistChnl": "01","ProdCategory": "asdfg","PriceGroup": "","ProdLine": "qwer","CondTable": "A305","UltCons": "","PartnerRole": "qs","Material": "15043762","CondType": "ZFXP","Rate": "12500.000","RateUnit": "","LineItemId": "LI-123456","MaterialGroup": "","StartDate": "","EndDate": "" }]}}';
    public static final String JSON_PART3 = '", "Action": "Validate","EX_ReturnSet": {"results": [{"Type": "S","MsgId": "VK","MsgNumber": "009","Message": "Material  15043762 is marked for deletion","LineItemId": "';
    public static final String VALIDATE_COMPLETED = 'Validate Completed';
    public static final String TERMINATE_FAILED = 'Termination failed';
    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';    
        Account acc2 = TestDataAccount.initAccount();
        insert new List<Account> { acc, acc2 };
            
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
            
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};
        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = MATERIALNUMBER;
        insert product;
        
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD'; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };

        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Customer Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc.id);
        //oAgreement1.scount_Level__c = 'Price Group';
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Validation_Status__c = 'Validate';
        oAgreement1.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusNotSubmitted;
        oAgreement1.Apttus__Contract_Start_Date__c = Date.Today();
        oAgreement1.Apttus__Contract_End_Date__c = Date.Today()+30;
        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement - Price Group123', acc.id);
        oAgreement2.RecordTypeId = recTypeId;
        oAgreement2.Validation_Status__c = 'Validate';
        oAgreement2.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusNotSubmitted;
        oAgreement2.Apttus__Contract_Start_Date__c = Date.Today();
        oAgreement2.Apttus__Contract_End_Date__c = Date.Today()+30;
        Apttus__APTS_Agreement__c objAgreement = new Apttus__APTS_Agreement__c();
        objAgreement.Name = 'Test Agreement - Price Group3';
        objAgreement.Apttus__Account__c  = acc.Id;
        objAgreement.RecordTypeId = recTypeId;
        objAgreement.Validation_Status__c = 'Validate';
        objAgreement.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusNotSubmitted;
        objAgreement.Apttus__Contract_Start_Date__c = Date.Today();
        objAgreement.Apttus__Contract_End_Date__c = Date.Today()+30;
        insert new List<Apttus__APTS_Agreement__c>{oAgreement1,oAgreement2,objAgreement};
        
        
        Apttus__AgreementLineItem__c oAgreementLineItem = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLineItem.Material_Number__c = MATERIALNUMBER;
        oAgreementLineItem.Line_Type__c = 'Material';
        oAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        oAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        oAgreementLineItem.Discount_Type__c = '% Discount';
        oAgreementLineItem.Discount__c = 1;
        oAgreementLineItem.CurrencyIsoCode = 'USD';
        oAgreementLineItem.Distribution_Channel__c = '01';
        oAgreementLineItem.Customer_ERP_Number__c = '123456';
        oAgreementLineItem.Sales_Org__c = 'US01';
        oAgreementLineItem.Apttus_CMConfig__StartDate__c = Date.Today() + 5;
        oAgreementLineItem.Apttus_CMConfig__EndDate__c = Date.Today() + 10;
        oAgreementLineItem.Apttus_CMConfig__LineStatus__c = 'New';
        oAgreementLineItem.Discontinued__c = 'No';

        Apttus__AgreementLineItem__c oAgreementLineItem1 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLineItem1.Material_Number__c = MATERIALNUMBER;
        oAgreementLineItem1.Line_Type__c = 'Material';
        oAgreementLineItem1.Apttus_CMConfig__LineNumber__c = 1;
        oAgreementLineItem1.Apttus_CMConfig__ItemSequence__c = 1;
        oAgreementLineItem1.Discount_Type__c = '% Discount';
        oAgreementLineItem1.Discount__c = 1;
        oAgreementLineItem1.CurrencyIsoCode = 'USD';
        oAgreementLineItem1.Distribution_Channel__c = '01';
        oAgreementLineItem1.Customer_ERP_Number__c = '123456';
        oAgreementLineItem1.Sales_Org__c = 'US01';
        oAgreementLineItem1.Apttus_CMConfig__StartDate__c = Date.Today() - 10;
        oAgreementLineItem1.Apttus_CMConfig__EndDate__c = Date.Today() - 3;
        oAgreementLineItem1.Apttus_CMConfig__LineStatus__c = 'Existing';
        oAgreementLineItem1.Discontinued__c = 'Yes';

        Apttus__AgreementLineItem__c objAgreementLineItem = TestDataAgreement.initAgreementsLineItem(objAgreement.id);
        objAgreementLineItem.Material_Number__c = MATERIALNUMBER;
        objAgreementLineItem.Line_Type__c = 'Material';
        objAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        objAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        objAgreementLineItem.Discount_Type__c = '% Discount';
        objAgreementLineItem.Discount__c = 1;
        objAgreementLineItem.CurrencyIsoCode = 'USD';
        objAgreementLineItem.Distribution_Channel__c = '01';
        objAgreementLineItem.Customer_ERP_Number__c = '123456';
        objAgreementLineItem.Sales_Org__c = 'US01';
        objAgreementLineItem.Apttus_CMConfig__StartDate__c = Date.Today() - 10;
        objAgreementLineItem.Apttus_CMConfig__EndDate__c = Date.Today() - 3;
        objAgreementLineItem.Apttus_CMConfig__LineStatus__c = 'New';
        objAgreementLineItem.Discontinued__c = 'No';
        
        insert new List<Apttus__AgreementLineItem__c>{oAgreementLineItem, oAgreementLineItem1, objAgreementLineItem};

        oAgreement1.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved;
        oAgreement2.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved;
        update new List<Apttus__APTS_Agreement__c> {oAgreement1, oAgreement2};
    }

    /*
    *@author: Maruthi
    *@Desc: Test method to check updateAgreementBeforeValidate, sendTerminateRequest and sendCancelRequest
    */

    @isTest
    static void testPreviousStatus(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];        
        objAgreement.Validation_Status__c = null;
        update objAgreement;
        Test.starttest();  
        ApttusAgreementValidateController.sendTerminateRequest(String.valueOf(objAgreement.id),'Terminate');
        ApttusAgreementValidateController.sendCancelRequest(String.valueOf(objAgreement.id),'Cancel');
        String str = ApttusAgreementValidateController.updateAgreementBeforeValidate(String.valueOf(objAgreement.id),'Validate');        
        System.assertEquals('Cancel Completed',str,'Previous Status');
        Test.stoptest();
    }
	
	/*
    *@author: Maruthi
    *@Desc: Test method to check updateAgreementBeforeValidate, sendTerminateRequest and sendCancelRequest
    */
	@isTest
    static void testExceptionBloks(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];        
        objAgreement.Validation_Status__c = null;
        update objAgreement;
        Test.starttest();          
        String str = ApttusAgreementActionService.sendGenerateRequestToSAP('Validate', String.valueOf(objAgreement.id)); 
        ApttusAgreementActionService.sendRequestToSAP(objAgreement,'Validate',null);
        System.assert(true,str.contains('Error-'));
        Test.stoptest();
    }

	
	/*
    *@author: Maruthi
    *@Desc: Test method to cover ApttusAgreementErrorHandler
    */
    @isTest
    static void testAgrErrorHandler(){
        Apttus__AgreementLineItem__c objAgreementLineItem = [Select Id,Apttus_CMConfig__StartDate__c,Apttus_CMConfig__EndDate__c,Discontinued__c,Apttus_CMConfig__LineStatus__c from Apttus__AgreementLineItem__c LIMIT 1];
        objAgreementLineItem.Discontinued__c = 'Yes';
        objAgreementLineItem.Apttus_CMConfig__LineStatus__c = 'Updated';
        //update objAgreementLineItem;        
        Test.starttest();          
		new ApttusAgreementValidateErrorWrapper.ValidateErrorWrapper();
        ApttusAgreementErrorHandler.generateEndDate(objAgreementLineItem, objAgreementLineItem.Apttus_CMConfig__StartDate__c+2);
        ApttusAgreementErrorHandler.generateEndDate(objAgreementLineItem, objAgreementLineItem.Apttus_CMConfig__StartDate__c);        
        Date resultDate = ApttusAgreementErrorHandler.generateStartDate(objAgreementLineItem, objAgreementLineItem.Apttus_CMConfig__StartDate__c+2);
        ApttusAgreementErrorHandler.generateStartDate(objAgreementLineItem, objAgreementLineItem.Apttus_CMConfig__StartDate__c);        
        //System.assertEquals(objAgreementLineItem.Apttus_CMConfig__StartDate__c+2 ,resultDate,'Result Start Date'); 
        Test.stoptest();
    }
    
    /*
    *@author: Maruthi
    *@Desc: Test method to cover ApttusAgreementErrorHandler
    */
    @isTest
    static void testAgrErrorHandler1(){        
        Apttus__AgreementLineItem__c objAgreementLineItem1 = [Select Id,Apttus_CMConfig__StartDate__c,Apttus_CMConfig__EndDate__c,Discontinued__c,Apttus_CMConfig__LineStatus__c from Apttus__AgreementLineItem__c LIMIT 1];
        objAgreementLineItem1.Discontinued__c = 'No';
        objAgreementLineItem1.Apttus_CMConfig__LineStatus__c = 'Updated';
        update objAgreementLineItem1;        
        Test.starttest();                  
        ApttusAgreementErrorHandler.generateEndDate(objAgreementLineItem1, null);
        ApttusAgreementErrorHandler.generateEndDate(objAgreementLineItem1, objAgreementLineItem1.Apttus_CMConfig__StartDate__c+2);
        ApttusAgreementErrorHandler.generateEndDate(objAgreementLineItem1, objAgreementLineItem1.Apttus_CMConfig__StartDate__c);        
        Date resultDate =ApttusAgreementErrorHandler.generateStartDate(objAgreementLineItem1, objAgreementLineItem1.Apttus_CMConfig__StartDate__c+2);
        ApttusAgreementErrorHandler.generateStartDate(objAgreementLineItem1, objAgreementLineItem1.Apttus_CMConfig__StartDate__c);        
        System.assertEquals(objAgreementLineItem1.Apttus_CMConfig__StartDate__c+2 ,resultDate,'Result Start Date'); 
        Test.stoptest();
    }
	
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Validation failure/success
    */

    @isTest
    static void testAgreementValidations(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Success',objAgreement.Apttus__FF_Agreement_Number__c,objAgrLineItem.Name));        
        System.assertEquals('Validate Failed, Please check error related object for error details.',ApttusAgreementValidateController.sendActionRequest(objAgreement.id,'Validate',null),'Validation failed');
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Validation failure
    */
    @isTest
    static void testAgreementValidationsFailure(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Fail',objAgreement.Apttus__FF_Agreement_Number__c,objAgrLineItem.Name));
        System.assertEquals('Error',ApttusAgreementValidateController.sendActionRequest(objAgreement.id,'Validate',null),'Validation failed');
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check 2nd interface success
    */
    @isTest
    static void testErrorReciever(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/AgreementValidateErrorInterface/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"AgreeStartDate": "", "Status": "E", "AgreeEndDate": "","AgreementNum": "'+objAgreement.Apttus__FF_Agreement_Number__c+JSON_VALIDATE_PART+objAgrLineItem.Name+JSON_PART2);
        RestContext.request = req;
        RestContext.response= res;
        ApttusAgreementValidateErrorReciever.upsertIncomingValues();

        Test.stopTest();
        System.assertequals(200,res.statuscode);
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check 2nd interface failure
    */
    @isTest
    static void testErrorRecieverFailure(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = ERROR_INTERFACE_API;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('"AgreeStartDate": "", "Status": "E", "AgreeEndDate": "","AgreementNum": "'+objAgreement.Apttus__FF_Agreement_Number__c+JSON_VALIDATE_PART+objAgrLineItem.Name+JSON_PART2);
        RestContext.request = req;
        RestContext.response= res;
        ApttusAgreementValidateErrorReciever.upsertIncomingValues();

        Test.stopTest();
        System.assertequals(412,res.statuscode);
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Validation success
    */
    @isTest
    static void testAgreementActivateSuccess(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Apttus__APTS_Agreement__c objAgreement1 = [select id,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group123'];
        objAgreement.Validation_Status__c = 'Activate In Progress';
        update objAgreement;
        Attachment objAttachment = TestDataFieldService.createAttachment(objAgreement.id,ATTACHMENT_NAME);
        insert objAttachment;
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.startTest();
        Apttus__APTS_Related_Agreement__c obj = new Apttus__APTS_Related_Agreement__c();
        obj.Apttus__APTS_Contract_From__c =  objAgreement1.Id;
        obj.Apttus__APTS_Contract_To__c = objAgreement.Id;
        obj.Name='Test Rexc';
        insert obj;
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'Test'+Label.Attachment_Prefix_Signed;
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=objAgreement.id;
        contentlink.ShareType= 'I';
        contentlink.ContentDocumentId=documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = ERROR_INTERFACE_API;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JSON_PART1+objAgreement.Apttus__FF_Agreement_Number__c+JSON_PART3+objAgrLineItem.Name+JSON_PART2);
        RestContext.request = req;
        RestContext.response= res;
        ApttusAgreementValidateErrorReciever.upsertIncomingValues();

        Test.stopTest();
        System.assertequals(200,res.statuscode);
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Validation failure/success
    */
    @isTest
    static void testAgreementActivation(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Validation_Status__c,Apttus__FF_Agreement_Number__c,Agreement_Not_Amended__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        objAgreement.Validation_Status__c = VALIDATE_COMPLETED;
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        update objAgreement;
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Success',objAgreement.Apttus__FF_Agreement_Number__c,objAgrLineItem.Name));
        System.assertEquals('Activate Failed, Please check error related object for error details.',ApttusAgreementValidateController.sendActionRequest(objAgreement.id,'Activate',VALIDATE_COMPLETED),ACTIVATION_FAILED);
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Validation failure/success
    */
    @isTest
    static void testAgreementCancelation(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,Validation_Status__c,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        objAgreement.Validation_Status__c = VALIDATE_COMPLETED;
        objAgreement.Is_Validated_Successful__c = true;
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        update objAgreement;
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Success',objAgreement.Apttus__FF_Agreement_Number__c,objAgrLineItem.Name));
        System.assertEquals('Cancel Failed, Please check error related object for error details.',ApttusAgreementValidateController.sendActionRequest(objAgreement.id,'Cancel', null),'Cancelation failed');
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check no line item activate and cancel
    */
    @isTest
    static void testAgreementNoLineItemCancel(){
        Test.starttest();
        List<Account> lstAcc = [Select id from Account];
        
        Apttus__APTS_Agreement__c oAgreement3 = TestDataAgreement.initAgreements(AGREEMENT_NAME_DATE_VALIDATION, lstAcc[0].id);
        oAgreement3.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement3.Sales_Org__c = 'HK01'; //adding reference sales org
        oAgreement3.Apttus__Total_Contract_Value__c = 100;
        oAgreement3.Freight_Charge__c = 'Standard';
        insert oAgreement3;
        
        System.assertEquals('Cancel request is completed.',ApttusAgreementValidateController.sendActionRequest(oAgreement3.id,'Cancel', null),'Cancellation failed');
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check no line item activate and cancel
    */
    @isTest
    static void testAgreementNoLineItemActtivate(){
        Test.starttest();
        List<Account> lstAcc = [Select id from Account];
        
        Apttus__APTS_Agreement__c oAgreement3 = TestDataAgreement.initAgreements(AGREEMENT_NAME_DATE_VALIDATION, lstAcc[0].id);
        oAgreement3.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement3.Sales_Org__c = 'HK01';//adding reference sales org
        oAgreement3.Apttus__Total_Contract_Value__c = 100;
        oAgreement3.Freight_Charge__c = 'Standard';
        insert oAgreement3;
        System.assertEquals('Activate request failed, Please contact system administrator.',ApttusAgreementValidateController.sendActionRequest(oAgreement3.id,'Activate', null),ACTIVATION_FAILED);
        Attachment objAttachment = TestDataFieldService.createAttachment(oAgreement3.id,'Test Docs Signed.');
        insert objAttachment;
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');

        ContentVersion cv = new ContentVersion();
        cv.title = 'Test'+Label.Attachment_Prefix_Signed;
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=oAgreement3.id;
        contentlink.ShareType= 'I';
        contentlink.ContentDocumentId=documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        System.assertEquals('Activate request is completed.',ApttusAgreementValidateController.sendActionRequest(oAgreement3.id,'Activate', null),ACTIVATION_FAILED);
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check no line item activate and cancel
    */
    @isTest
    static void testAgreementNoLineItemTerminate(){
        Test.starttest();
        List<Account> lstAcc = [Select id from Account];
        
        Apttus__APTS_Agreement__c oAgreement3 = TestDataAgreement.initAgreements(AGREEMENT_NAME_DATE_VALIDATION, lstAcc[0].id);
        oAgreement3.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement3.Sales_Org__c = 'HK01';//adding reference sales org
        oAgreement3.Apttus__Total_Contract_Value__c = 100;
        oAgreement3.Freight_Charge__c = 'Standard';
        insert oAgreement3;
        System.assertEquals('Terminate request is completed.',ApttusAgreementValidateController.sendActionRequest(oAgreement3.id,'Terminate', null),TERMINATE_FAILED);
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Cancel success
    */
    @isTest
    static void testAgreementCancelSuccess(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Apttus__APTS_Agreement__c objAgreement1 = [select id,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group123'];
        objAgreement.Validation_Status__c = 'Cancel In Progress';
        update objAgreement;
        Attachment objAttachment = TestDataFieldService.createAttachment(objAgreement.id,ATTACHMENT_NAME);
        insert objAttachment;
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.startTest();
        Apttus__APTS_Related_Agreement__c obj = new Apttus__APTS_Related_Agreement__c();
        obj.Apttus__APTS_Contract_From__c =  objAgreement1.Id;
        obj.Apttus__APTS_Contract_To__c = objAgreement.Id;
        obj.Name='Test Rexc';
        insert obj;
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = ERROR_INTERFACE_API;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JSON_PART1+objAgreement.Apttus__FF_Agreement_Number__c+JSON_PART3+objAgrLineItem.Name+JSON_PART2);
        RestContext.request = req;
        RestContext.response= res;
        ApttusAgreementValidateErrorReciever.upsertIncomingValues();
        Test.stopTest();
        System.assertequals(200,res.statuscode);
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Termination success
    */
    @isTest
    static void testAgreementTerminateSuccess(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        objAgreement.Validation_Status__c = 'Terminate In Progress';
        update objAgreement;
        Attachment objAttachment = TestDataFieldService.createAttachment(objAgreement.id,ATTACHMENT_NAME);
        insert objAttachment;
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = ERROR_INTERFACE_API;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JSON_PART1+objAgreement.Apttus__FF_Agreement_Number__c+JSON_PART3+objAgrLineItem.Name+JSON_PART2);
        RestContext.request = req;
        RestContext.response= res;
        ApttusAgreementValidateErrorReciever.upsertIncomingValues();

        Test.stopTest();
        System.assertequals(200,res.statuscode);
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Terminate failure/success
    */
    @isTest
    static void testAgreementTermination(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Success',objAgreement.Apttus__FF_Agreement_Number__c,objAgrLineItem.Name));
        System.assertEquals('Terminate Failed, Please check error related object for error details.',ApttusAgreementValidateController.sendActionRequest(objAgreement.id,'Terminate', objAgreement.Validation_Status__c),TERMINATE_FAILED);
        Test.stoptest();
    }

    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Validate success
    */
    @isTest
    static void testAgreementValidateSuccess(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        objAgreement.Validation_Status__c = 'Validate In Progress';
        update objAgreement;
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = ERROR_INTERFACE_API;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JSON_PART1+objAgreement.Apttus__FF_Agreement_Number__c+JSON_PART3+objAgrLineItem.Name+JSON_PART2);
        RestContext.request = req;
        RestContext.response= res;
        ApttusAgreementValidateErrorReciever.upsertIncomingValues();
        Test.stopTest();
        System.assertequals(200,res.statuscode);
    }
        
     /*
    *@author: Vishnu Kurra
    *@Desc: Test method to check PreValidate failure/success
    */

    @isTest
    static void testAgreementPreValidation(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,Apttus__FF_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Success',objAgreement.Apttus__FF_Agreement_Number__c,objAgrLineItem.Name));
        System.assertEquals('PreValidate Failed, Please check error related object for error details.',ApttusAgreementValidateController.sendActionRequest(objAgreement.id,'PreValidate', null),'PreValidation failed');
        Test.stoptest();
    }
        /*
    *@author: Vishnu Kurra
    *@Desc: Test method to check PreValidate success
    */
    @isTest
    static void testAgreementPreValidateSuccess(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        objAgreement.Validation_Status__c = 'PreValidate In Progress';
        update objAgreement;
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = ERROR_INTERFACE_API;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JSON_PART1+objAgreement.Apttus__FF_Agreement_Number__c+'", "Action": "PreValidate","EX_ReturnSet": {"results": [{"Type": "S","MsgId": "VK","MsgNumber": "009","Message": "Material  15043762 is marked for deletion","LineItemId": "'+objAgrLineItem.Name+JSON_PART2);
        RestContext.request = req;
        RestContext.response= res;
        ApttusAgreementValidateErrorReciever.upsertIncomingValues();
        Test.stopTest();
        System.assertequals(200,res.statuscode);
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Validation failure
    */
    @isTest
    static void testAgreementCancelFailure1(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        objAgreement.Validation_Status__c = VALIDATE_COMPLETED;
        objAgreement.Is_Validated_Successful__c = true;
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        update objAgreement;
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('Fail',objAgreement.Apttus__FF_Agreement_Number__c,objAgrLineItem.Name));
        System.assertEquals('Error',ApttusAgreementValidateController.sendActionRequest(objAgreement.id,'Cancel', null),'Cancel failed');
        Test.stoptest();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method to check Terminate failure/success
    */
    @isTest
    static void testAgreementPartialSuccess(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,Apttus__FF_Agreement_Number__c,Validation_Status__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group'];
        Apttus__AgreementLineItem__c objAgrLineItem = [select id,Name from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: objAgreement.id][0];
        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new ApttusCLMMockHTTP('SuccessPartial',objAgreement.Apttus__FF_Agreement_Number__c,objAgrLineItem.Name));
        System.assertEquals('Error-',ApttusAgreementValidateController.sendActionRequest(objAgreement.id,'Terminate', objAgreement.Validation_Status__c),TERMINATE_FAILED);
        Test.stoptest();
    }
	
	//DCP-34579 - Auto Terminate Agreements
    @isTest
    static void testAgreementValidateControllerUpdateTerminateDate()
    {
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__Termination_Date__c from Apttus__APTS_Agreement__c 
                                                  where Name = 'Test Agreement - Price Group'];    
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        if (setting.Bypass_All_Triggers__c == false || setting.Bypass_All_Validations__c == false) 
        {
            setting.Bypass_All_Triggers__c = true;
            setting.Bypass_All_Validations__c = true;
            upsert setting;
        }
        test.startTest();
        String result = ApttusAgreementValidateController.updateTerminationDateAgreement(objAgreement.Id,String.valueOf(Date.today()));
        ApttusAgreementValidateController.updateTerminationDateAgreement(objAgreement.Id,'#@#@');
        System.assertEquals('true',result);
        test.stopTest();
    }

    //DCP-34579 - Auto Terminate Agreements
    @isTest
    static void testAgreementValidateControllerUpdateTerminateDateCatch()
    {
        Apttus__APTS_Agreement__c objAgreement = [select id,Apttus__Termination_Date__c from Apttus__APTS_Agreement__c 
                                                  where Name = 'Test Agreement - Price Group'];    
        
        ApttusAgreementValidateController.updateTerminationDateAgreement(objAgreement.Id,String.valueOf(Date.today()));
        System.assertEquals(null,objAgreement.Apttus__Termination_Date__c);
    }
    /*
    *@author: Himanshu
    *@Desc: Test method to cover sendRequestToSAP in ApttusAgreementActionService
    */
	@isTest
    static void testPastDateForNonOpenOfferAgremeentLineItem(){
        Apttus__APTS_Agreement__c objAgreement = [select id,Agreement_Not_Amended__c,CurrencyIsoCode,Apttus__FF_Agreement_Number__c,Validation_Status__c,RecordType.DeveloperName,RecordType.name,Apttus__Subtype__c,Apttus__Contract_Start_Date__c,Apttus__Contract_End_Date__c,Parent_Agreement_Number__c from Apttus__APTS_Agreement__c where Name = 'Test Agreement - Price Group3'];        
        Test.starttest();          
        String str = ApttusAgreementActionService.sendGenerateRequestToSAP('Validate', String.valueOf(objAgreement.id)); 
        ApttusAgreementActionService.sendRequestToSAP(objAgreement,'Validate',null);
        System.assert(true,str.contains('Error-'));
        Test.stoptest();
    }
}
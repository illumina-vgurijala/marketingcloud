/***************************************************************************************************************************************
* NAME         : TestIVDRDocumentSearchController
* DESCRIPTION  : Test class for IVDRDocumentSearchController class
*                    
* @AUTHOR      : Gladis
* @DATE        : 04-Jan-2022  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Gladis Evangaly        04-Jan-2022         CMCP-110: Initial Version
****************************************************************************************************************************************/
@isTest
public with sharing class TestIVDRDocumentSearchController {
    
    public static final String ORDER_DETAILS_SET = 'OrderDetailSet';
    public static final String IVDR_DOC_SET = 'IVDRDocSet';
    public static final String HTTP_SUCCESS_CODE = '200';
    public static final String HTTP_FAILURE_CODE = '400';
    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION : Test method to check Cp Profiles
    **/    
    @isTest
    static void testCPProfile() {

        //Create Account
        Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
        objAccount.Account_Group__c='Distributor';
        Insert objAccount;
        
        //Create Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);

        //Creating User
        User objUser;
        User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{Id.valueOf(UserInfo.getUserId())});
        TestDataUser.allowUserCreation(objUser1.Id); 

        System.runAs(objUser1) {
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;    
            //Created User
            objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
            insert objUser;
    
            Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
                cp.SetupOwnerId= profileId;
                cp.Is_Channel_Partner__c= True;
                insert cp;
        }
        Boolean checkCPAccess = false ;
        test.startTest();
        System.runAs(objUser) { 
            checkCPAccess=IVDRDocumentSearchController.checkCPProfile();
        }
        test.stopTest();
        system.assertEquals(true, checkCPAccess,'Access not granted');
    }

    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION : Test method to test fetchSalesOrderDetails with all inputs
    **/    
    @isTest
    static void testfetchSalesOrderDetailsFromSAP() {

        List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper> wrapperList = new List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper>();
        IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper inputWrap = new IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper();
        //{"sobjectType":"IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper","salesOrder":"0002093190","startDate":"2022-01-03","endDate":"2022-1-4","erpCustomer":"4000003563"}
            inputWrap.salesOrder = '0002093190';
            inputWrap.startDate = '2022-01-03';
            inputWrap.endDate = '2022-1-4';
            inputWrap.erpCustomer = '4000003563';
            wrapperList.add(inputWrap);

            Test.startTest();
        TestIVDRDocumentMockClass mockCallout = new TestIVDRDocumentMockClass(HTTP_SUCCESS_CODE,'Ok',ORDER_DETAILS_SET);     
        Test.setMock(HttpCalloutMock.class, mockCallout);
        String response = IVDRDocumentSearchController.fetchSalesOrderDetailsFromSAP(JSON.serialize(wrapperList));
        System.assert(response!= NULL,'Response is null');
        System.assert(mockCallout!= NULL,'first mockCallout is not initiated');
        System.assertEquals(0, [SELECT count() FROM Exception_Log__c LIMIT 1], 'Exception Count is greater than 0');
        Test.stopTest();
    }

    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION : Test method to test fetchSalesOrderDetails with only SalesOrder input
    **/    
    @isTest
    static void testfetchSalesOrderDetailsOnlySalesOrder() {

        List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper> wrapperList = new List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper>();
        IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper inputWrap = new IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper();
            inputWrap.salesOrder = '0002093190';
            inputWrap.erpCustomer = '4000003563';
            wrapperList.add(inputWrap);

            Test.startTest();
        TestIVDRDocumentMockClass mockCallout = new TestIVDRDocumentMockClass(HTTP_SUCCESS_CODE,'Ok',ORDER_DETAILS_SET);     
        Test.setMock(HttpCalloutMock.class, mockCallout);
        IVDRDocumentSearchController.fetchSalesOrderDetailsFromSAP(JSON.serialize(wrapperList));
        System.assert(mockCallout!= NULL,'first mockCallout is not initiated');
        System.assertEquals(0, [SELECT count() FROM Exception_Log__c LIMIT 1]);
        Test.stopTest();
    }

    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION : Test method to test fetchSalesOrderDetails with strat and end dates as input
    **/    
    @isTest
    static void testfetchSalesOrderDetailsWithDates() {

        List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper> wrapperList = new List<IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper>();
        IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper inputWrap = new IVDRDocumentSearchController.IVDRDocumentSalesOrderWrapper();
            inputWrap.startDate = '2022-01-03';
            inputWrap.endDate = '2022-1-4';
            inputWrap.erpCustomer = '4000003563';
            wrapperList.add(inputWrap);

            Test.startTest();
        TestIVDRDocumentMockClass mockCallout = new TestIVDRDocumentMockClass(HTTP_SUCCESS_CODE,'Ok',ORDER_DETAILS_SET);     
        Test.setMock(HttpCalloutMock.class, mockCallout);
        IVDRDocumentSearchController.fetchSalesOrderDetailsFromSAP(JSON.serialize(wrapperList));
        System.assert(mockCallout!= NULL,'first mockCallout is not initiated');
        System.assertEquals(0, [SELECT count() FROM Exception_Log__c LIMIT 1]);
        Test.stopTest();
    }

    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION : Test method to test downloadSalesOrderDetails success scenario
    **/    
    @isTest
    static void testdownloadSalesOrderDetails() {

        List<IVDRDocumentSearchResponseWrapper.results> wrapperList = new List<IVDRDocumentSearchResponseWrapper.results>();
        IVDRDocumentSearchResponseWrapper.results inputWrap = new IVDRDocumentSearchResponseWrapper.results();
            inputWrap.SalesOrder = '0002093190';
            inputWrap.Customer = '6000022300';
            inputWrap.Delivery = '1001122414';
            wrapperList.add(inputWrap);

        Test.startTest();
        TestIVDRDocumentMockClass mockCallout = new TestIVDRDocumentMockClass(HTTP_SUCCESS_CODE,'Ok', IVDR_DOC_SET);     
        Test.setMock(HttpCalloutMock.class, mockCallout);
        IVDRDocumentSearchController.downloadSalesOrderDetails(JSON.serialize(wrapperList));
        System.assert(mockCallout!= NULL,'second mockCallout is not initiated');
        System.assertEquals(0, [SELECT count() FROM Exception_Log__c LIMIT 1]);
        Test.stopTest();
    }

    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION : Test method to test downloadSalesOrderDetails error scenario
    **/    
    @isTest
    static void testErrordownloadSalesOrderDetails() {

        List<IVDRDocumentSearchResponseWrapper.results> wrapperList = new List<IVDRDocumentSearchResponseWrapper.results>();
        IVDRDocumentSearchResponseWrapper.results inputWrap = new IVDRDocumentSearchResponseWrapper.results();
            inputWrap.SalesOrder = '0002093190';
            inputWrap.Customer = '6000022300';
            inputWrap.Delivery = '1001122414';
            wrapperList.add(inputWrap);

        Test.startTest();
        TestIVDRDocumentMockClass mockCallout = new TestIVDRDocumentMockClass(HTTP_FAILURE_CODE,'Bad request', IVDR_DOC_SET);     
        Test.setMock(HttpCalloutMock.class, mockCallout);
        IVDRDocumentSearchController.downloadSalesOrderDetails(JSON.serialize(wrapperList));
        System.assert(mockCallout!= NULL,'second error mockCallout is not initiated');
        System.assertEquals(0, [SELECT count() FROM Exception_Log__c LIMIT 1]);
        Test.stopTest();
    }

    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION : Test method to handle downloadSalesOrderDetails exception method
    **/    
    @isTest
    static void testdownloadSalesOrderDetailsException() {

        Test.startTest();
        try {
            IVDRDocumentSearchController.downloadSalesOrderDetails('0');
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error');
        }
        Test.stopTest();
    }

    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION : Test method to handle IVDRDataSender.executeCallout exception method
    **/    
    @isTest
    static void testexecuteCalloutException() {
        
        Test.startTest();
        try {
            IVDRDocumentDataSender ds = new IVDRDocumentDataSender();
            ds.executeCallout('0');
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error');
        }
        Test.stopTest();
    }

    /**
    *  @AUTHOR Gladis 
    *  @DESCRIPTION : Test method to handle fetchSalesOrderDetailsFromSAP exception method
    **/    
    @isTest
    static void testfetchSalesOrderDetailsException() {

        Test.startTest();
        try {
            IVDRDocumentSearchController.fetchSalesOrderDetailsFromSAP('0');
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error');
        }
        Test.stopTest();
    }
    
            
}
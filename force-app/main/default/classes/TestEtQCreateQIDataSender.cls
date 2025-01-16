/***************************************************************************************************************************************
 * NAME   : TestEtQCreateQIDataSender
 * DESCRIPTION  : TestClass for EtQCreateQIDataSender
 *                Annotated with SeeAllData=true due to dependency on ServiceMax managed trigger
 *    
 * @AUTHOR : Sagar Madkaikar
 * @DATE   : 06-Apr-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Sagar Madkaikar       06-Apr-2022         QACM-14: Initial Version
 * --------------------------------------------------------------------------------------------------------------------------------------
 
  ****************************************************************************************************************************************/
  @IsTest(SeeAllData = true)
public with sharing class TestEtQCreateQIDataSender {

    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_EVALUATION_ANSWER_PENDING='Pending';

    static testMethod void testCreateQIAPISuccess() {

        // START : Create Case Test Record
        Account objAcc = TestDataAccount.getNewAccount();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        objProduct.Source_System__c = 'SAP';
        insert objProduct;

        cs_Apex_Settings__c c=cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
        c.Bypass_All_Validations__c = true;
        c.Bypass_All_Triggers__c = true;
        upsert c cs_Apex_Settings__c.Id;
        
        Case objCase = TestDataCase.initServiceRequestCase(con);
        objCase.Status = 'Initiated';
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.Description = 'testDescription';
        insert objCase;
        // END : Create Case Test Record

        //Create QR Record
        Quality_Record__c testQR = new Quality_Record__c();
        testQR.EtQ_Number__c = 'QI-12345';
        testQR.External_URL__c='https://www.test.com';
        testQR.EtQ_Integration_Status__c='QI Creation Initiated';
        testQR.Case__c=objCase.id;
        insert testQR;

        //Create QRJ Record
        Quality_Record_Junction__c testQRJ = new Quality_Record_Junction__c();
        testQRJ.Quality_Record__c = testQR.Id;
        testQRJ.Case__c=objCase.id;
        insert testQRJ;

        c.Bypass_All_Validations__c = false;
        c.Bypass_All_Triggers__c = false;
        upsert c cs_Apex_Settings__c.Id;

        Test.starttest();

        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok','{\"StatusCode\":\"200\",\"Messages\":\"Success\",\"ETQNumber\":\"QI-12345\"}',headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Boolean isexecuted = new EtQCreateQIDataSender().callout(testQR.id);
        Test.Stoptest();
        System.assertEquals(true,isexecuted,'Error in calling API');

        
    }
    static testMethod void testCreateQIAPIFailure() {

        // START : Create Case Test Record
        Account objAcc = TestDataAccount.getNewAccount();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        objProduct.Source_System__c = 'SAP';
        insert objProduct;

        cs_Apex_Settings__c c=cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());
        c.Bypass_All_Validations__c = true;
        c.Bypass_All_Triggers__c = true;
        upsert c cs_Apex_Settings__c.Id;
        
        Case objCase = TestDataCase.initServiceRequestCase(con);
        objCase.Status = 'Initiated';
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.Description = 'testDescription';
        insert objCase;
        // END : Create Case Test Record

        //Create QR Record
        Quality_Record__c testQR = new Quality_Record__c();
        testQR.EtQ_Number__c = 'QI-12345';
        testQR.External_URL__c='https://www.test.com';
        testQR.EtQ_Integration_Status__c='QI Creation Initiated';
        testQR.Case__c=objCase.id;
        insert testQR;

        //Create QRJ Record
        Quality_Record_Junction__c testQRJ = new Quality_Record_Junction__c();
        testQRJ.Quality_Record__c = testQR.Id;
        testQRJ.Case__c=objCase.id;
        insert testQRJ;

        c.Bypass_All_Validations__c = false;
        c.Bypass_All_Triggers__c = false;
        upsert c cs_Apex_Settings__c.Id;

        Test.starttest();

        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok','{\"StatusCode\":\"500\",\"Messages\":\"Failed\",\"ETQNumber\":\"\"}',headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Boolean isexecuted = new EtQCreateQIDataSender().callout(testQR.id);
        Test.Stoptest();
        System.assertEquals(true,isexecuted,'Error in calling API');

        
    }
    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION -Mock response
     **/
    public class SingleRequestMock implements HttpCalloutMock {
        protected Integer code;
        protected String status;
        protected String bodyAsString;
        protected Blob bodyAsBlob;
        protected Map < String, String > responseHeaders;

        /**
         *  @DESCRIPTION -Mock response
         **/
        public SingleRequestMock(Integer code, String status, String body, Map < String, String > responseHeaders) {
            this.code = code;
            this.status = status;
            this.bodyAsString = body;
            this.bodyAsBlob = null;
            this.responseHeaders = responseHeaders;
        }

        /**
         *  @DESCRIPTION -Mock response
         **/
        public SingleRequestMock(Integer code, String status, Blob body,
            Map < String, String > responseHeaders) {
            this.code = code;
            this.status = status;
            this.bodyAsBlob = body;
            this.bodyAsString = null;
            this.responseHeaders = responseHeaders;
        }

        /**
         *  @DESCRIPTION -Mock response
         **/
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse resp = new HttpResponse();
            resp.setStatusCode(code);
            resp.setStatus(status);
            if (bodyAsBlob != null) {
                resp.setBodyAsBlob(bodyAsBlob);
            } else {
                resp.setBody(bodyAsString);
            }

            if (responseHeaders != null) {
                for (String key: responseHeaders.keySet()) {
                    resp.setHeader(key, responseHeaders.get(key));
                }
            }
            return resp;
        }
    }
    
}


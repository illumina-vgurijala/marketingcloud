/***************************************************************************************************************************************
 * NAME   : TestVeevaCreateCaseDataSender
 * DESCRIPTION  : TestClass for VeevaCreateCaseDataSender
 *                Annotated with SeeAllData=true due to dependency on ServiceMax managed trigger
 *    
 * @AUTHOR : Sagar Madkaikar
 * @DATE   : 02-Sep-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Sagar Madkaikar       02-Sep-2022         DCP-51201: Initial Version
 * --------------------------------------------------------------------------------------------------------------------------------------
 
  ****************************************************************************************************************************************/
  @IsTest(SeeAllData = true)
public with sharing class TestVeevaCreateCaseDataSender {

    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';    

    static testMethod void testUpdataVeevaStatusSuccess() {

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
		objCase.Veeva_Integration_Status__c='Case Creation Initiated';
		Update objCase;

        //Create EmailMessage Record
        EmailMessage objEmail1 = new EmailMessage();
        objEmail1.FromAddress = 'test@gmail.com';
        objEmail1.Incoming = true;
        objEmail1.ToAddress = 'test@gmail.com';
        objEmail1.Subject = 'Test email';
        objEmail1.TextBody = 'Hello';
        objEmail1.ParentId =objCase.Id;
        insert objEmail1;
        
        Test.starttest();
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };
            
        SingleRequestMock resp = new SingleRequestMock(200,'ok','{\"status\":\"200\",\"messages\":\"Received Case Information Successfully\"}',headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, resp);

        Boolean isexecuted = new VeevaCreateCaseDataSender().callout(objCase.id);
        Test.Stoptest();
        System.assertEquals(true,isexecuted,'Error in calling API');

        
    }
    static testMethod void testUpdataVeevaStatusFailure() {

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

        c.Bypass_All_Validations__c = false;
        c.Bypass_All_Triggers__c = false;
        upsert c cs_Apex_Settings__c.Id;

		objCase.Veeva_Integration_Status__c='Case Creation Failed';
		Update objCase;
        Test.starttest();

        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        SingleRequestMock mockResp = new SingleRequestMock(400,'ok','{\"status\":\"501\",\"messages\":\"Request Failed\"}',headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, mockResp);

        Boolean isexecuted = new VeevaCreateCaseDataSender().callout(objCase.id);
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


/***************************************************************************************************************************************
 * NAME   : TestWOTranslationDataSender
 * DESCRIPTION  : TestClass for WOTranslationDataSender
 *                Annotated with SeeAllData=true due to dependency on ServiceMax managed trigger
 *    
 * @AUTHOR : Sagar Madkaikar
 * @DATE   : 20-Sep-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Sagar Madkaikar       20-Sep-2022        DCP-56433: Initial Version
 * Dhairya               21/8/2024 CMCM-2180 
 * --------------------------------------------------------------------------------------------------------------------------------------
 
  ****************************************************************************************************************************************/
@IsTest(SeeAllData = false)
public with sharing class TestWOTranslationDataSender {

    /**
    *  @AUTHOR Sagar
    *  @DESCRIPTION - test method to check WO Translation Success
    **/
    static testMethod void testCreateKeyAPISuccess(){
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;


        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder2.SVMXC__Is_PM_Work_Order__c = true;
        //workorder2.SVMXC__PM_Plan__c = pmPlan.Id;
        workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
        //workOrder2.SVMXC__Site__c = objLocation.Id;
        workOrder2.SVMX_PS_Subject__c='Test Subject';
        workOrder2.SVMXC__Problem_Description__c='Test Description';
        workOrder2.Evaluation__c='Test Evaluation';
        workOrder2.Verification_Result__c='Test Verification Result';
        workOrder2.SVMXC__Work_Performed__c='Test Work Performed';
        insert workOrder2;

        Test.starttest();
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        String jsonResponse = '{   \"project_id\": \"5857770162ba154068f7a6.35574900\",   \"keys\": [     {       \"key_id\": 215085875,       \"created_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"created_at_timestamp\": 1663138927,       \"key_name\": {         \"ios\": \"Test14Sep22\",         \"android\": \"Test14Sep22\",         \"web\": \"Test14Sep22\",         \"other\": \"Test14Sep22\"       },       \"filenames\": {         \"ios\": \"\",         \"android\": \"\",         \"web\": \"\",         \"other\": \"\"       },       \"description\": \"Chinese to English Translation for Test14Sep22\",       \"platforms\": [         \"web\"       ],       \"tags\": [               ],       \"comments\": [               ],       \"screenshots\": [               ],       \"translations\": [         {           \"translation_id\": 1714045740,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"zh_TW\",           \"translation\": \"\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": true,           \"is_fuzzy\": true,           \"words\": 0,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045741,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"zh_CN\",           \"translation\": \"这是工单主题的中英翻译#$#\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": false,           \"is_fuzzy\": false,           \"words\": 11,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045739,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"ja\",           \"translation\": \"\",           \"modified_by\": 203380,           \"modified_by_email\": \"sdineshmadkaikar@deloitte.com\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": true,           \"is_fuzzy\": true,           \"words\": 0,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         },         {           \"translation_id\": 1714045742,           \"segment_number\": 1,           \"key_id\": 215085875,           \"language_iso\": \"en_US\",           \"translation\": \"This is the @&%#Chinese-English translation\",           \"modified_by\": 1,           \"modified_by_email\": \"support@lokalise.co\",           \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",           \"modified_at_timestamp\": 1663138927,           \"is_reviewed\": false,           \"reviewed_by\": 0,           \"is_unverified\": false,           \"is_fuzzy\": false,           \"words\": 9,           \"custom_translation_statuses\": [                       ],           \"task_id\": null         }       ],       \"is_plural\": false,       \"plural_name\": \"\",       \"is_hidden\": false,       \"is_archived\": false,       \"context\": \"\",       \"base_words\": 11,       \"char_limit\": 0,       \"custom_attributes\": \"\",       \"modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"modified_at_timestamp\": 1663138927,       \"translations_modified_at\": \"2022-09-14 07:02:07 (Etc/UTC)\",       \"translations_modified_at_timestamp\": 1663138927     }   ],   \"errors\": [] }';
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok',jsonResponse,headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        WOTranslationDataSender.WOResponseWrapper responseWrap = new WOTranslationDataSender('zh_CN',workOrder2.Id,null).fetchWOTranslations();
        Test.Stoptest();
        System.assertEquals(true,responseWrap.isSuccess,'Integration Failed');
    }
    
    /**
    *  @AUTHOR Sagar
    *  @DESCRIPTION - test method to check WO Translation Error
    **/
    static testMethod void testCreateKeyAPIError(){
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;

        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder2.SVMXC__Is_PM_Work_Order__c = true;
        //workorder2.SVMXC__PM_Plan__c = pmPlan.Id;
        workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
        //workOrder2.SVMXC__Site__c = objLocation.Id;
        workOrder2.SVMX_PS_Subject__c='Test Subject';
        workOrder2.SVMXC__Problem_Description__c='Test Description';
        workOrder2.Evaluation__c='Test Evaluation';
        workOrder2.Verification_Result__c='Test Verification Result';
        workOrder2.SVMXC__Work_Performed__c='Test Work Performed';
        insert workOrder2;

        Test.starttest();
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        String jsonResponse = '{     \"project_id\": \"5857770162ba154068f7a6.35574900\",     \"keys\": [],     \"errors\": [         {             \"message\": \"This key name is already taken\",             \"code\": 400,             \"key_name\": {                 \"ios\": \"Test14Sep22v2\",                 \"android\": \"Test14Sep22v2\",                 \"web\": \"Test14Sep22v2\",                 \"other\": \"Test14Sep22v2\"             }         }     ] }';
        SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok',jsonResponse,headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        WOTranslationDataSender.WOResponseWrapper responseWrap = new WOTranslationDataSender('zh_CN',workOrder2.Id,null).fetchWOTranslations();
        Test.Stoptest();
        System.assertEquals(false,responseWrap.isSuccess,'Integration Failed');    


    }

    /**
    *  @AUTHOR Sagar
    *  @DESCRIPTION - test method to check WO Translation Failure
    **/
    static testMethod void testCreateKeyAPIFailure(){
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;

        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder2.SVMXC__Is_PM_Work_Order__c = true;
        //workorder2.SVMXC__PM_Plan__c = pmPlan.Id;
        workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
        //workOrder2.SVMXC__Site__c = objLocation.Id;
        workOrder2.SVMX_PS_Subject__c='Test Subject';
        workOrder2.SVMXC__Problem_Description__c='Test Description';
        workOrder2.Evaluation__c='Test Evaluation';
        workOrder2.Verification_Result__c='Test Verification Result';
        workOrder2.SVMXC__Work_Performed__c='Test Work Performed';
        insert workOrder2;

        Test.starttest();
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        String jsonResponse = '{     \"project_id\": \"5857770162ba154068f7a6.35574900\",     \"keys\": [],     \"errors\": [         {             \"message\": \"This key name is already taken\",             \"code\": 400,             \"key_name\": {                 \"ios\": \"Test14Sep22v2\",                 \"android\": \"Test14Sep22v2\",                 \"web\": \"Test14Sep22v2\",                 \"other\": \"Test14Sep22v2\"             }         }     ] }';
        SingleRequestMock fakeResponse = new SingleRequestMock(400,'ok',jsonResponse,headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        WOTranslationDataSender.WOResponseWrapper responseWrap = new WOTranslationDataSender('zh_CN',workOrder2.Id,null).fetchWOTranslations();
        Test.Stoptest();
        System.assertEquals(false,responseWrap.isSuccess,'Integration Failed');    


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
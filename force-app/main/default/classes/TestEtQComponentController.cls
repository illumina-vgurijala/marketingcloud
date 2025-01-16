/**
* @ author       : Abhinav Gupta
* @ date         : 31-Mar-2022
* @ Description  : QACM-14,15 Test class for LWC Controller for EtQ stories
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Abhinav             31-Mar-2022                 Initial version
*/
@IsTest
public with sharing class TestEtQComponentController {


    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_CASE_STATUS = 'Initiated';
      public static final string STRING_PRODUCT_CODE = 'Test 1234';
      public static final boolean BOOLEAN_CONSUMABLES_INCLUDED = false;
      public static final string STRING_CASE_ORIGIN = 'Phone - CS';
      public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
      public static final string STRING_CASE_SUB_TYPE = 'Complaint';
      public static final string STRING_CASE_CATEGORY = 'Install';
      public static final string LINK_INITIATED = 'Link Initiated';
      public static final String CASE_OBJ = 'Case';
    public static final String FIELD_ACTION_NOTIFICATION_OBJ = 'Field_Action_Notification__c';
    public static final String QI_TYPE = 'QI';
    public static final String ETQ_NUMBER = 'ETQ-0001';
    public static final String SOURCE = 'Complaint';
    public static final String DELINK_INITIATED = 'Delink Initiated';
    public static final String ETQ_URL = 'TestVal';
    public static final String NOTIFICATION = 'Notification';
    public static final String QI_CREATION_INITIATED = 'QI Creation Initiated';
    public static final String MANUAL_LINK = 'Manual Link';
    

    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description  Test method for searchQiRecords of EtQComponentController class
    */
    static testmethod void testSearchQiRecords(){
        
        Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='Test',EtQ_Created_Date__c=Datetime.now());
            insert qr1;
        Quality_Record__c qr2 = new Quality_Record__c(EtQ_Number__c = 'ETQTest2',Problem_Title__c='Test2',Quality_Record_Type__c='QI',Sites_Impacted__c='Test',EtQ_Created_Date__c=Datetime.now());
            insert qr2;
        
        String iso8601 = Datetime.now().format('yyyy-MM-dd');
        Test.startTest();
        List<Quality_Record__c> qrList = EtQComponentController.searchQiRecords('Test','Test','ETQTest',iso8601);
        Test.stopTest();
        system.assertEquals(2,qrList.size(),'QI Records are searched as per criteria.');
    }
    
    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for checkIfAlreadyLinked of EtQComponentController class
    */
    static testmethod void testCheckIfAlreadyLinked(){
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
            insert objCase;

            Field_Action_Notification__c fan =TestDataFieldService.createFAN(NOTIFICATION);
            insert fan;

            Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
            insert qr1;
        
        	Quality_Record__c qr2 = new Quality_Record__c(EtQ_Number__c = 'ETQTest2',Problem_Title__c='Test2',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite2');
            insert qr2;

            Quality_Record_Junction__c qrj1 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Case__c=objCase.Id);
            insert qrj1;

            Quality_Record_Junction__c qrj2 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Field_Action_Notification__c=fan.Id);
            insert qrj2;
        
        QualityRecordJunctionSelector qrs = new QualityRecordJunctionSelector();
        List<Quality_Record_Junction__c> fanList = qrs.selectQRJForFANLinked(qr1.Id);
        List<Quality_Record_Junction__c> caseLst = qrs.selectQRJForCaseLinked(qr1.Id);
        List<Quality_Record__c> qrList = [Select Id from Quality_Record__c where EtQ_Number__c like 'ETQTest%' order by EtQ_Number__c asc];
        
        Test.startTest();
        Boolean test1 = EtQComponentController.checkIfAlreadyLinked(qrList[0].Id,objCase.Id,CASE_OBJ);
        Boolean test2 = EtQComponentController.checkIfAlreadyLinked(qrList[0].Id,fan.Id,FIELD_ACTION_NOTIFICATION_OBJ);
        Boolean test3 = EtQComponentController.checkIfAlreadyLinked(qrList[1].Id,objCase.Id,CASE_OBJ);
        Test.stopTest();
        System.assert(test1,'QR is Linked to Case');
        System.assert(test2,'QR is Linked to FAN');
        System.assert(!test3,'QR is not Linked to Case');
    }

    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for createQualityRecordJuntions of EtQComponentController class
    */
    static testmethod void testCreateQualityRecordJuntions(){
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
            insert objCase;

            Field_Action_Notification__c fan =TestDataFieldService.createFAN(NOTIFICATION);
            insert fan;

            Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
            insert qr1;
        
        	Quality_Record__c qr2 = new Quality_Record__c(EtQ_Number__c = 'Test2',Problem_Title__c='Test2',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite2');
            insert qr2;

            Quality_Record_Junction__c qrj1 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Case__c=objCase.Id);
            insert qrj1;

            Quality_Record_Junction__c qrj2 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Field_Action_Notification__c=fan.Id);
            insert qrj2;
        
      List<Quality_Record__c> qrList = [Select Id from Quality_Record__c where EtQ_Number__c = 'ETQTest' order by EtQ_Number__c asc];
      Test.startTest();
      Quality_Record_Junction__c test1 = EtQComponentController.createQualityRecordJuntions(qrList[0].Id,objCase.Id,CASE_OBJ,LINK_INITIATED);
      Quality_Record_Junction__c test2 = EtQComponentController.createQualityRecordJuntions(qrList[0].Id,fan.Id,FIELD_ACTION_NOTIFICATION_OBJ,LINK_INITIATED);
      Test.stopTest();
      system.assertEquals(objCase.Id,test1.Case__c,'QRJ is created for the CASE');
      system.assertEquals(fan.Id,test2.Field_Action_Notification__c,'QRJ is created for the FAN');
    }

    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for getLinkedQualityRecords of EtQComponentController class
    */
    static testmethod void testGetLinkedQualityRecords(){
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
            insert objCase;

            Field_Action_Notification__c fan =TestDataFieldService.createFAN(NOTIFICATION);
            insert fan;

            Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
            insert qr1;
        
        	Quality_Record__c qr2 = new Quality_Record__c(EtQ_Number__c = 'ETQTest2',Problem_Title__c='Test2',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite2');
            insert qr2;

            Quality_Record_Junction__c qrj1 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Case__c=objCase.Id);
            insert qrj1;

            Quality_Record_Junction__c qrj2 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Field_Action_Notification__c=fan.Id);
            insert qrj2;
        
      List<Quality_Record_Junction__c> qrList = [Select Id,Case__c,Field_Action_Notification__c,Quality_Record__c from Quality_Record_Junction__c where Case__c =: objCase.Id];
      Test.startTest();
      List<Quality_Record_Junction__c> test1 = EtQComponentController.getLinkedQualityRecords(objCase.Id,CASE_OBJ,'');
      Test.stopTest();
      system.assertEquals(qrList[0].Id,test1[0].Id,'Method returned expected linked QI Records');
    }

    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for delinkQRJ of EtQComponentController class
    */
    static testmethod void testDelinkQRJ(){
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
            insert objCase;

            Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
            insert qr1;
        
        	Quality_Record_Junction__c qrj1 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Case__c=objCase.Id);
            insert qrj1;
        
      List<Quality_Record_Junction__c> qrList = [Select Id,Case__c,Field_Action_Notification__c,Quality_Record__c,EtQ_Integration_Status__c from Quality_Record_Junction__c where Case__c =: objCase.Id];
      qrList[0].EtQ_Integration_Status__c = DELINK_INITIATED;
            update qrList[0];
      Test.startTest();
      EtQComponentController.delinkQRJ(qrList[0].id);
      Test.stopTest();
      Quality_Record_Junction__c qrj = [Select Id,EtQ_Integration_Status__c from Quality_Record_Junction__c where Id =: qrList[0].id];
      system.assertEquals(qrList[0].EtQ_Integration_Status__c,qrj.EtQ_Integration_Status__c,'Method delinked the linked QI Record');
    }

    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for createQR of EtQComponentController class
    */
    static testmethod void testCreateQR(){
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
            insert objCase;

            Field_Action_Notification__c fan =TestDataFieldService.createFAN(NOTIFICATION);
            insert fan;
        
      
      Test.startTest();
      Quality_Record__c test1 = EtQComponentController.createQR(ETQ_NUMBER,objCase.Id,CASE_OBJ,SOURCE,ETQ_URL,QI_CREATION_INITIATED,'','');
      Quality_Record__c test2 = EtQComponentController.createQR(ETQ_NUMBER,fan.id,FIELD_ACTION_NOTIFICATION_OBJ,SOURCE,ETQ_URL,QI_CREATION_INITIATED,'','');
      Test.stopTest();
      system.assertEquals(objCase.id,test1.Case__c,'Method created expected QR');
      system.assertEquals(fan.id,test2.Field_Action_Notification__c,'Method created expected QR');

    }

    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for checkIfManuallyLinked of EtQComponentController class
    */
    static testmethod void testCheckIfManuallyLinked(){
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
            insert objCase;

            Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
            insert qr1;
        
        	Quality_Record_Junction__c qrj1 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Case__c=objCase.Id,EtQ_Integration_Status__c=MANUAL_LINK);
            insert qrj1;
              
      Test.startTest();
      Boolean test1 = EtQComponentController.checkIfManuallyLinked(qrj1.Id);
      Test.stopTest();
      system.assert(test1,'Method returned the Manually Linked QI Record');

    }

        /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for deleteManualQrj of EtQComponentController class
    */
    static testmethod void testDeleteManualQrj(){
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
            insert objCase;

            Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
            insert qr1;
        
        	Quality_Record_Junction__c qrj1 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Case__c=objCase.Id,EtQ_Integration_Status__c=MANUAL_LINK);
            insert qrj1;
        
      Test.startTest();
      Boolean test1 = EtQComponentController.deleteManualQrj(qrj1.Id);
      Test.stopTest();
      system.assert(test1,'Method deleted Manually Linked QRJ.');

    }
    
    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for createQRCallout of EtQComponentController class
    */
    static testmethod void testCreateQRCallout(){
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
            insert objCase;

            Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
            insert qr1;


      Test.startTest();
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok','{\"StatusCode\":\"200\",\"Messages\":\"Success\",\"ETQNumber\":\"QI-12345\",\"ProblemTitle\":\"test title\"}',headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        EtQComponentController.EtQCompWrapper etqComp = EtQComponentController.createQrjCallout(ETQ_URL,CASE_OBJ,objCase.Id);
      	//EtQComponentController.EtQCompWrapper etqComp1 = EtQComponentController.createQrjCallout(ETQ_URL,CASE_OBJ,objCase.Id);
        Test.stopTest();
      system.assertEquals(0,etqComp.status,'Method returned and linked QI Record');
    }

        /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for createQRCallout of EtQComponentController class
    */
    static testmethod void testCreateQRCallout2(){
        
      Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          insert objCase;

          Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
          insert qr1;


      
    Test.startTest();
      Map < String, String > headerKeyToValue = new Map < String, String > {
          'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
          'Accept' => 'application/json'
      };

      SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok','{\"StatusCode\":\"200\",\"Messages\":\"Success\",\"ETQNumber\":\"QI-1345\",\"ProblemTitle\":\"test title\"}',headerKeyToValue);
      Test.setMock(HttpCalloutMock.class, fakeResponse);
      EtQComponentController.EtQCompWrapper etqComp = EtQComponentController.createQrjCallout(ETQ_URL,CASE_OBJ,objCase.Id);
    Test.stopTest();
    system.assertEquals(0,etqComp.status,'Method returned the Manually Linked QI Record');
  }

          /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for createQRCallout of EtQComponentController class
    */
    static testmethod void testCreateQRCallout3(){
        
      Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          insert objCase;

          Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
          insert qr1;


      
    Test.startTest();
      Map < String, String > headerKeyToValue = new Map < String, String > {
          'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
          'Accept' => 'application/json'
      };

      SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok','{\"StatusCode\":\"200\",\"Messages\":\"Success\",\"ETQNumber\":\"\",\"ProblemTitle\":\"test title\"}',headerKeyToValue);
      Test.setMock(HttpCalloutMock.class, fakeResponse);
      EtQComponentController.EtQCompWrapper etqComp = EtQComponentController.createQrjCallout(ETQ_URL,CASE_OBJ,objCase.Id);
    Test.stopTest();
    system.assertEquals(1,etqComp.status,'Method returned bad status as expected');
  }
    
    
    /**
    * @author abhinav
    * @date   31-Mar-2022
    * @description   Test method for createQRCallout of EtQComponentController class
    */
    static testmethod void testCreateQRCallout4(){
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
            insert objCase;

            Quality_Record__c qr1 = new Quality_Record__c(EtQ_Number__c = 'ETQTest',Problem_Title__c='Test',Quality_Record_Type__c='QI',Sites_Impacted__c='TestSite');
            insert qr1;
        
        Quality_Record_Junction__c qrj1 = new Quality_Record_Junction__c(Quality_Record__c=qr1.Id,Case__c=objCase.Id,EtQ_Integration_Status__c=MANUAL_LINK);
            insert qrj1;


        
      Test.startTest();
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok','{\"StatusCode\":\"200\",\"Messages\":\"Success\",\"ETQNumber\":\"ETQTest\",\"ProblemTitle\":\"test title\"}',headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        EtQComponentController.EtQCompWrapper etqComp = EtQComponentController.createQrjCallout(ETQ_URL,CASE_OBJ,objCase.Id);
        Test.stopTest();
      system.assertEquals(1,etqComp.status,'Method returned bad status as expected');
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
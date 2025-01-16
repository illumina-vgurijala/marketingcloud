/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-18-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

/***************************************************************************************************************************************
 * NAME   : TestEtQGetEtQNumberDataSender
 * DESCRIPTION  : TestClass for EtQGetEtQNumberDataSender
 *                Annotated with SeeAllData=true due to dependency on ServiceMax managed trigger
 *    
 * @AUTHOR : Gladis Evangaly
 * @DATE   : 06-Apr-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Gladis Evangaly       06-Apr-2022         QACM-14: Initial Version
 * --------------------------------------------------------------------------------------------------------------------------------------
 
  ****************************************************************************************************************************************/
  @IsTest(SeeAllData = true)
public with sharing class TestEtQGetEtQNumberDataSender {
    
    static testMethod void testGetEtQNumberSuccess() {

        Test.starttest();

        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok','{\"StatusCode\":\"200\",\"Messages\":\"Success\",\"ETQNumber\":\"QI-12345\"}',headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        EtQResponseWrapper responseWrap = EtQGetEtQNumberDataSender.fetchETQNumber('http://www.etq.com');
        Test.Stoptest();
        System.assertEquals('QI-12345',responseWrap.ETQNumber,'EtQ Number not found');    
        
    }
    static testMethod void testGetEtQNumberFailure() {

        Test.starttest();

        Map < String, String > headerKeyToValue = new Map < String, String > {
            'Authorization' => 'Bearer gQtXZ1oTB4QzFfSSmg6ZCppUICIy1Cvo',
            'Accept' => 'application/json'
        };

        SingleRequestMock fakeResponse = new SingleRequestMock(200,'ok','{\"StatusCode\":\"200\",\"Messages\":\"Invalid URL\",\"ETQNumber\":\"\"}',headerKeyToValue);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        EtQResponseWrapper responseWrap = EtQGetEtQNumberDataSender.fetchETQNumber('http://www.etq.com');
        Test.Stoptest();
        System.assertEquals('Invalid URL',responseWrap.Messages,'Assertion Failed : Messages:Invalid URL');    
        
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

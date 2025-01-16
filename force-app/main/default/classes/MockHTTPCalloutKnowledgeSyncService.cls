/* @ author      : Adyasha Satapathy
* @ date         : 10-12-2020
* @ Description  : MockHTTPCalloutKnowledgeSyncService is the class to send mock response for Knowledge Sync Service class
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Adyasha Satapathy       10-12-2020                 DCP-43401         Initial version
*/
@isTest
public class MockHTTPCalloutKnowledgeSyncService implements HttpCalloutMock{
    public static String strStatusType = 'Success';
    /**
     *  @author      :Adyasha Satapathy
     *  @description :respond method
     **/
    public static HTTPResponse respond(HTTPRequest req){
        return new HTTPResponse();
    }
    /**
     *  @author      :Adyasha Satapathy
     *  @description :method for mock responses for Knowledge Article Sync
     **/
    public static HTTPResponse respondMock(String strMethod){
        String strFetchMethod = '[ { "id": "841d1e83-3efe-4048-b697-5f7e8ce22c53", "hasDomainOfValues": false, "isRequired": false, "listOrder": 34, "name": "AEM Tags", "teamsiteId": "1", "type": "string", "isDeleted": false, "isPublished": true } ]';
         // POL-18 AC9 keywords replaced from EMEA to EUR And APJ with AMEA
        String strFetchFile = '{"assignedToProfiles":[{"id":"2c5e01d0-eb04-4cb2-8d92-258ae8a44865","name":"Knowledge Management","type":"ContentProfile"}],"id":"841d1e83-3efe-4048-b697-5f7e8ce22c53","properties":[{"id":"39b5aa40-3404-41cc-93cf-582e57c5eb37","name":"Allowed Distribution","values":["Illumina Internal","Channel Partner"]},{"id":"8fa84a26-4ba9-4bcc-a661-3ced69269263","name":"Audience","values":["Support"]},{"id":"4ad84e72-cbd2-41b2-b302-66bf25b8da2b","name":"Content Asset Type","values":["FSB"]},{"id":"ac87dbf1-a08b-489a-b363-5eab80eeb56c","name":"Regional Distribution","values":["For AMR","For AMEA","For Greater China","For EUR"]},{"id":"fde1442a-02ab-4aca-99f3-9e718fc65b84","name":"Regulatory Type","values":["IVD"]},{"id":"4789a251-b32c-43cf-92e3-230b841d42f7","name":"Instrument","values":["MiSeqDx"]},{"id":"01b5f172-ce08-43fb-a7fd-79c4df1486c1","name":"Products and Services","values":["MiSeqDx"]}],"name":"'+String.valueof(System.now())+'"}';
        String strAuth = '{"access_token": "abc"}';
        String strFetchDetails ='[{"contentProfileId":"2c5e01d0-eb04-4cb2-8d92-258ae8a44865","libraryContentId":"61ffb592-303c-49b2-a98c-14e34d31722c","libraryContentVersionId":"50490aa6-078e-447f-a29f-08ca01bca67b"},{"contentProfileId":"2c5e01d0-eb04-4cb2-8d92-258ae8a44865","libraryContentId":"61ffb592-303c-49b2-a98c-14e34d31722c","libraryContentVersionId":"50490aa6-078e-447f-a29f-08ca01bca67b"}]';
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token','XRTSGD');
        res.setBody(strMethod == 'Auth' ? strAuth : strMethod == 'FetchMethod' ? strFetchMethod : strMethod == 'FetchContentDetail' ? strFetchDetails : strFetchFile);
        
        Integer intStatusCode = strMethod == 'Auth' ? 200 : (strStatusType == 'Success' && strMethod !='Auth') ? 200 : 401;
        res.setStatusCode(intStatusCode);
        return res;
    }
}
/* @ author      : Vaibhav
* @ date         : 01-04-2021
* @ Description  : MockHTTPCalloutQualtricsAPI  is the class to send mock response for QualtricsAPISurveyLinkReader class
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Vaibhav       01-04-2021                  DCP-46141       Initial version
*/

public with sharing class MockHTTPCalloutQualtricsAPI {
    /**
     *  @author      :Vaibhav
     *  @description :respond method
     **/
    public static HTTPResponse respond(HTTPRequest req){
        return new HTTPResponse();
    }
    /**
     *  @author      :Vaibhav
     *  @description :method for mock responses for QualtricsAPISurveyLinkReader
     **/
    public static HTTPResponse respondMock(String strMethod)
    {
        String strResponseBody = '{"result": {"id": "CID_eR6JOlUMzxLqRsl"},"meta": { "httpStatus": "200 - OK","requestId": "5751a6ca-377e-48e0-909c-c7e60f12a612"}}';
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token','XRTSGD');
        res.setBody(strMethod == 'Auth' ?  strResponseBody : NULL);
        res.setStatusCode(200);
        return res;
    }
}
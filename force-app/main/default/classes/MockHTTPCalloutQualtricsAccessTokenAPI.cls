/* @ author      : Vaibhav
* @ date         : 01-04-2021
* @ Description  : MockHTTPCalloutQualtricsAPI  is the class to send mock response for QualtricsAPISurveyLinkReader class
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Vaibhav       01-04-2021                  DCP-46141       Initial version
*/
public with sharing class MockHTTPCalloutQualtricsAccessTokenAPI {
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
        String strResponseBody = '{"access_token": "jhjw7q81997781","token_type": "access","expires_in": "36617","scope": "manage:all"}';
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token','XRTSGD');
        res.setBody(strMethod == 'Auth' ?  strResponseBody : NULL);
        res.setStatusCode(200);
        return res;
    }
}
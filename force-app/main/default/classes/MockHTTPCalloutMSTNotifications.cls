/* @ author      : Adyasha Satapathy
* @ date         : 01-04-2021
* @ Description  : MockHTTPCalloutMSTNotifications is the class to send mock response for CaseChangeEventsService class
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Adyasha Satapathy       01-04-2021                  DCP-43907       Initial version
*/
@isTest
public with sharing class MockHTTPCalloutMSTNotifications {
    /**
     *  @author      :Adyasha Satapathy
     *  @description :respond method
     **/
    public static HTTPResponse respond(HTTPRequest req){
        return new HTTPResponse();
    }
    /**
     *  @author      :Adyasha Satapathy
     *  @description :method for mock responses for CaseChangeEventsService
     **/
    public static HTTPResponse respondMock(String strMethod)
    {
        String strResponseBody = '{"text" : "Dear TEST QUEUE</br>Few cases are not assigned please take a look.</br><li>01889730</li>"}';
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token','XRTSGD');
        res.setBody(strMethod == 'Auth' ?  strResponseBody : NULL);
        res.setStatusCode(200);
        return res;
    }
}
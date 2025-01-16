  /*
    * @Author: Rishab
    * @Description : test class for Http callout
    * -------------------------------------------------------------------------------------------------------
    *        Developer               Date                Description
    *        Rishab                                     Initial Version
    *        Aman Tyagi             2022-03-30          CodeScan Fixes
    * -------------------------------------------------------------------------------------------------------
    */
@isTest
public class MockHTTPCallout implements HttpCalloutMock {

    public static Boolean booResponseSuccess = false;

		/*
         * description - respond method
         */
    public String responseBody = '{"Status" : "Ok"}';

     /*
     * @Description : methhod for returning Http Response code
     * @param :  HTTPRequest req
     * @return :HTTPResponse
     */
    public HTTPResponse respond(HTTPRequest req)
    {
        booResponseSuccess = true;

        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(responseBody);
        res.setStatusCode(200);
        return res;
    } 

}
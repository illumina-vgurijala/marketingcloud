/**
 *    @author         :
 *    @date           :
 *    @description    : To create mock HTTP response for TestAccounts
 *    Test class for 90% coverage:
 *    Test class for 75% coverage:
 *    Modification Log:
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date                Description
 *    Vivek R                       06-Oct-22           Codescan fixes: added comments
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
global class TestAccountsMockEtmUpdate implements HttpCalloutMock{
    public static Boolean successResponse = true;

    /**
     *  @description : Method to create the HTTP response
     *  @param       : HTTP request
     *  @return      : HTTP response
    */
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        if (successResponse)
            res.setBody(TestAccounts.RESTSUCCESSRESPONSE);
        else
            res.setBody(TestAccounts.RESTERRORRESPONSE);

        res.setStatusCode(200);
        return res;
    }

}
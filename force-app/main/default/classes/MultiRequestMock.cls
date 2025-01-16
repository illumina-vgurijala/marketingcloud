/* @ author      : Vineeta Verma
* @ date         : 5 Dec 2023
* @ Description  : To be used for creating multiple mock responses for testing callouts
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Vineeta Verma            5 Dec 2023                 INC0500807       Initial version
*/
@isTest
public class MultiRequestMock implements HttpCalloutMock {
    Map<String, HttpCalloutMock> requests;
    /**
     *  @author      :Vineeta
     *  @description :To create Mock endpoint to request map
     **/
    public MultiRequestMock(Map<String, HttpCalloutMock> requests) {
        this.requests = requests;
    }
    /**
     *  @author      :Vineeta
     *  @description :To return mock response
     **/
    public HTTPResponse respond(HTTPRequest req) {
        HttpCalloutMock mock = requests.get(req.getEndpoint());
        if (mock != null) {
            return mock.respond(req);
        } else {
            return null;
        }
    }
    
}
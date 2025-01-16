/* @ author      : Vaibhav
* @ date         : 01-04-2021
* @ Description  : MockHTTPCalloutQualtricsSurveyLinkAPI  is the class to send mock response for QualtricsAPISurveyLinkReader class
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Vaibhav       01-04-2021                  DCP-46141       Initial version
*/
public with sharing class MockHTTPCalloutQualtricsSurveyLinkAPI {
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
        String strResponseBody = '{"result": {"elements": [ {                "contactId": "CID_6EyU52VM7NU9WkZ",                "transactionId": null,                "link": "https://feedback.illumina.com/jfe/form/SV_1F9zm1TyVG0A1wx?Q_CHL=gl&Q_DL=BXUuTPU7WKXF2JT_1F9zm1TyVG0A1wx_CGC_v9yEKop2Yim53H3",                "exceededContactFrequency": false,                "linkExpiration": "2021-07-23T03:26:00Z",                "status": "Email not sent",                "lastName": null,                "firstName": "Aaron",                "externalDataReference": null,                "email": "aschlum@carisls.com.invalid",                "unsubscribed": false            }        ],        "nextPage": null    },    "meta": {        "httpStatus": "200 - OK",        "requestId": "a5f474de-392a-4092-8578-2fc082a54825"    }}';
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token','XRTSGD');
        res.setBody(strMethod == 'Auth' ?  strResponseBody : NULL);
        res.setStatusCode(200);
        return res;
    }
}
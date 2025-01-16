/*
 * @Author: Rishab Wali
 * @Date: 17-MAR-2019
 * @Description :Mock Callout For Customer Specific Pricing Interface
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rishab Wali            12-MAR-2019                   Mock Callout For Customer Specific Pricing Interface. DCP 34078
* Aman Tyagi             31-Mar-2022                   CodeScan Fixes
 */
@isTest
global class MockHTTPCalloutCustomerSpecificPricing implements HttpCalloutMock{

    /*
    * @Author: Rishab Wali
    * @Description : method has logic for HTTResponse based on HttpRequest
    * @param  :  HTTPRequest req
    * @return :  HTTPResponse
    */
    global HTTPResponse respond(HTTPRequest req) {
        
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{\"ex_prices\":[{\"kunnr\":\"13212123\",\"matnr\":\"13131\",\"bismt\":\"12131\",\"matxt\":\"test\",\"unitp\":\"123\",\"custp\":\"542\",\"konwa\":\"kg\",\"mvgr1\":\"01\"}]}');
        res.setStatusCode(201);
        return res;
    } 
}
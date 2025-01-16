/*@ author       : Akshay Mohan
* @ date         : 07-02-2018
* @ Description  : ProspectAccountAddressValidationComponent Apex Controller Outbound mock for address doctor
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan        	10-05-2018                  DCP-6494             Initial version
* Aman Tyagi            31 Mar 2022                                       CodeScan Fixes
* 
*/
public class AddressDoctorHttpMock implements HttpCalloutMock {
	public static Boolean booResponseSuccess = false;
    /*
    * @Author: Akshay Mohan
    * @Description : method for returning HttpResponse based on Http request
    * @param : HTTPRequest req
    * @return :HTTPResponse
    */
	public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"data":{"addresses":[{"mailingName":null,"address1":"ASDKL","address2":null,"street":"ASDKL","street2":null,"houseNumber":null,"houseNumber2":null,"city":"SML","state":null,"postalCode":"12345","poBox":null,"countryCode":"US","iso2":"US","iso3":"USA","isoNumber":840,"countryName":"UNITED STATES","longitude":0,"latitude":0,"addressComplete":"ASDKL;SML 12345;UNITED STATES","confidenceScore":"0.00","mailabilityScore":"0","formattedAddress":["ASDKL","SML 12345","UNITED STATES"]}],"status":"100","statusCode":"I2"},"error":{"errorCode":0,"errorDescription":"None"}}');
        res.setStatusCode(200);
        booResponseSuccess = true;
        return res;
    }
}
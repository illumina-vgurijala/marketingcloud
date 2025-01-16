/*
* @Description : Class for Mock SAP response/request for real time test classes
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date             Description
* Vishnu Priya Duggineni                Inital Version
* Himanshu            31-Mar-2022       Code Scan Fixes
* Nishan Shetty       25-Jan-2023       POL-862-Truncate Title greater than 80 characters.
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class MockSailPointConnector implements HttpCalloutMock{
    public static Boolean booResponseSuccess = false;
    /**
    *@description method with mock respose data when there is no auth error
    *@params HTTPRequest req
    *@return HTTPResponse 
    **/
    public HTTPResponse respond(HTTPRequest req) {
        
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('set-cookie', 'setvalue;test');
        res.setBody('{"Table":[{"PREFERRED_FIRST_NAME":"Test","PREFERRED_LAST_NAME":"Batch","EMAIL":"tBatch@illumina.com","JOB_TITLE":"Associate Director, Medical Affairs, Head of GDT/RH - Europe, Middle East & Africa","DEPARTMENT_NAME":"Strategy, Test","COSTCENTER_NAME":"Strategy Test","EMP_ID":"0000000","MANAGER_OID":"","MANAGER_EMAIL":"testManager@illumina.com","EMPLOYEEIDORIGINAL":"0000000","COUNTRY":"United States","REGION":"AMR","SUB_REGION":"AMR","MANAGER":"Test manager","DESK_COUNTRY_CODE":"1","DESK_AREA_CODE":"619","DESK_PHONE_ONLY":"0000000","WD_USER_NAME":"tBatch","COSTCENTER_NUMBER":"100","FUNCTIONAL_AREA":"Sales"}]}');//POL-862
        res.setStatusCode(200);
        res.setStatus('OK');
        booResponseSuccess = true;
        return res;
    }
    /**
    *@description method with mock respose data when there is an auth error
    *@params HTTPRequest req
    *@return HTTPResponse 
    **/
    public HTTPResponse respondAuthError(HTTPRequest req) {
        
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('set-cookie', 'setvalue;test');
        res.setBody('Bad request');
        res.setStatusCode(403);
        booResponseSuccess = true;
        return res;
    }
}
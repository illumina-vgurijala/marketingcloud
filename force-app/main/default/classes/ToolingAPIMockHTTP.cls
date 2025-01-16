/**
 *    @author Kushagra Desai
 *    @date   11-Dec-2019
 *    @description    Mock class for Territory Planning
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *       
 *    --------------------------------------------------------------------------------------------------------------------------
 */
@isTest
global with sharing class ToolingAPIMockHTTP implements HttpCalloutMock{
    /**
    *   @author KD
    *   @description Mock respond method for test class
    **/
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('x-csrf-token','XRTSGD');
        res.setBody('{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ProfileLayout","records":[{"attributes":{"type":"ProfileLayout","url":"/services/data/v43.0/tooling/sobjects/ProfileLayout/01G2i000004Fp6DEAS"},"Layout":{"attributes":{"type":"Layout","url":"/services/data/v43.0/tooling/sobjects/Layout/00h2i000000RIh0AAG"},"Name":"Direct Territory Plan"}}]}');
        res.setStatusCode(200);
        return res;
    }
}
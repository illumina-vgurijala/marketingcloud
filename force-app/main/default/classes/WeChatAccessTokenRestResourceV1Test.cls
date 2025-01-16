/**
*    @author Pankaj Singla
*    @date   2020-05-28
*    @description   Test Class for WeChatAccessTokenRestResourceV1
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 28 May 2020          Initial Version
*             Sheikh Shahnawaz              28 sep 2022         Code Coverage Enhancement
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class WeChatAccessTokenRestResourceV1Test
{
    @isTest
    static void testGetToken()
    {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/wechat/v1.0/tokens/12312321';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        WeChatAccessTokenRestResourceV1.doGet();
        System.assertEquals('{"access_token":""}', res.responseBody.toString()); 
    }
    @isTest
    static void testGetTokenException()
    {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/wechat/v1.0/tokens/12312321';
        req.httpMethod = 'GET';
        RestContext.response = res;
        WeChatAccessTokenRestResourceV1.doGet();
        System.assertNotEquals('{"access_token":""}', res.responseBody.toString()); 
    }
}
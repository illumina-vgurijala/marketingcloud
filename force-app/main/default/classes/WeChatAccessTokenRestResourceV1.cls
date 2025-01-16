/**
*    @author Pankaj Singla
*    @date   2020-05-28
*    @description   webservice class for sharing WeChat access token between Salesforce and third party Vendor
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 28 May 2020          Initial Version
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
@RestResource(urlMapping='/wechat/v1.0/tokens/*')
global with sharing class WeChatAccessTokenRestResourceV1
{
    /**
    * @owner Pankaj Singla
    * @description Reads the custom settings and provide access token stored in Charket Settings
    */
    @HttpGet
    global static void doGet()
    {
        String response = '';
        
        try
        {
            String token = '';
            
            Pattern tokenPattern = Pattern.compile('/wechat/v1.0/tokens/(.*)');
            Matcher tokenMatch = tokenPattern.matcher(RestContext.request.requestURI);
           
            if(tokenMatch.matches() && !Test.isRunningTest())
            {
                token = Charket.WeChatAccessToken.getAccessToken(tokenMatch.group(1));
            }
                       
            response = JSON.serialize(new Map<String, String> {
                'access_token' => token
            });
        }
        catch(Exception ex)
        {
            response = ex.getMessage();
        }
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(response);
    }
}
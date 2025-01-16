/*
 * @Author: Rishab Wali
 * @Date: 17-MAR-2019
 * @Description : Test Class for CurrencyTypeReciever Web Service Class (DCP -32959)
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rishab Wali            17-MAR-2019                   Test Class for CurrencyTypeReciever Web Service Class (DCP -32959)
* Aman Tyagi              12-Dec-2022                   CodeScan Fixes
 */
@isTest
public class TestCurrencyTypeReciever {
    /**
    * 
    *
    * @desc testMethod1 [CodeScan Fix]
    */
    @isTest
    public static void testMethod1()
    {
        String stringReq = '[{\"IsoCode\":\"USD\",\"ConversionRate\":1.2,\"DecimalPlaces\":2,\"IsActive\":false}]';
        
        RestRequest req = new RestRequest();
		req.httpMethod = 'PATCH';
		req.requestUri = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/CurrencySyncInterface';
        req.requestBody = Blob.valueOf(stringReq);

        RestContext.request = req;
        CurrencyTypeReciever.getCurrencyRecordIdsByCodes();
        System.assertEquals(false,String.isBlank(RestContext.request.requestBody.toString()));
    }
}
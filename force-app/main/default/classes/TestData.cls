/**
*    @Name :   TestBundleCustomersTests
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Saddam                         10-oct-22           COdescan Fix,Comments Added.
*    ------------------------------------------------------------------------------------
* 
*/
@isTest 
public with sharing class TestData {

    /*
    *  @description  : Method to Return RandomString.
    */
    public static String getRandom()
    {
        return getRandom(6);
    }

    /*
    *  @description  :  Method to Return Random String by Passsing lenght
    * @param         :  Integer
    * Return         :  String
    */
    public static String getRandom(Integer len)
    {
         String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        return getRandom(len, chars);
    }

    /*
    *  @description  : Method to Return RandomNumber
    */
    public static String getRandomNumeric()
    {
        return getRandomNumeric(6);
    }

    /*
    *  @description  :  Method to Return Random String by Passsing lenght
    * @param         :  Integer
    * Return         :  String
    */
    public static String getRandomNumeric(Integer len)
    {
        String chars = '123456789'; // NOTE: removed 0 so numbers never start with 0
        return getRandom(len, chars);
    }

    /*
    *  @description  :  Method to Return Random String by Passsing lenght and string of characters.
    * @param         :  Integer
    * Return         :  String
    */
    private static String getRandom(Integer len, String chars)
    {
        String randStr = '';
        while (randStr.length() < len)
        {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    } 
}
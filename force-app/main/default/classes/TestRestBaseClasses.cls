/**
 * @author 
 * @date   
 * @description  private test class TestRestBaseClasses
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Aman Tyagi               07-Oct-2022         Codescan Fixes
*  -----------------------------------------------------------------------------------          
*/
@isTest private class TestRestBaseClasses {
    /**
    * @author 
    * @description static method bogusClassName
    * @param NA
    * @return NA
    **/ 
    @isTest public static void bogusClassName()
    {
        Boolean exceptionCaught = false;

        try
        {
            ilib_RestInterface.getInterfaceDetails('Not an interface class');
        }
        catch (Exception e)
        {
            exceptionCaught = true;
        }

        System.assert(exceptionCaught, 'Bogus interface class should throw exception');
    }

    /**
    * @author 
    * @description static method addFriendlyJson
    * @param NA
    * @return NA
    **/
    @isTest public static void addFriendlyJson()
    {
        String someJson = '{ "key" : "val" }';
        String escapedJson = '"' + someJson.replace('"', '\\"') + '"';

        ilib_RestInterface.InterfaceDetails interfaceDetails = new ilib_RestInterface.InterfaceDetails('Some Interface', 'Inbound', 'Account');
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, '{ }');
        ilib_RestInterface.addFriendlyJsonToLog(log, someJson);

        System.assertEquals(escapedJson, log.jsonMessage);
    }

    /**
    * @author 
    * @description static method badCustomerQuery
    * @param NA
    * @return NA
    **/
    @isTest public static void badCustomerQuery()
    {
        Account a = TestDataAccount.getNewAccount();
        Opportunity o = TestDataOpportunity.getNewOpportunity(a);

        String erpId = ReceiverImpl.getRelatedErpCustomerId('Opportunity', 'WrongPath', o.Id);

        System.assertEquals('', erpId);
    }

    /**
    * @author 
    * @description static method goodCustomerQuery
    * @param NA
    * @return NA
    **/
    @isTest public static void goodCustomerQuery()
    {
        Account a = TestDataAccount.getNewAccount();
        Opportunity o = TestDataOpportunity.getNewOpportunity(a);

        String erpId = ReceiverImpl.getRelatedErpCustomerId('Opportunity', 'Account', o.Id);

        System.assertEquals(a.ERP_Customer_Id__c, erpId);
    }
    /**
    * @author 
    * @description sharing class extending ilib_RestReceiver
    **/
    public with sharing class ReceiverImpl extends ilib_RestReceiver { }

}
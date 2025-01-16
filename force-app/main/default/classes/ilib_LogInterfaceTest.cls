/**
*    @author Illumina       
*    @date          
*    @description 
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
@isTest
private with sharing class ilib_LogInterfaceTest {

    private static ilib_RestInterface.InterfaceDetails details = new ilib_RestInterface.InterfaceDetails('Test Interface', 'Outbound', 'Account');
    private static String someJson = '{\n  "CompanyName" : "Illumina"\n}';
    private static String someKongId = 'ae7973ff8-cb676c4-aaff';
    private static String resultDetails = 'Stunning success';
    private static String processingMessage1 = 'Just getting started';
    private static String processingMessage2 = 'On our way now';

    @isTest static void runThroughLogBeforePersist()
    {
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(details);

        System.assertEquals(details.name, log.interfaceName);
        System.assertEquals(details.direction, log.direction);
        System.assertEquals(details.objectType, log.objectType);

        ilib_LogInterface.addJsonToLog(log, someJson);
        System.assertEquals(someJson, log.jsonMessage);

        ilib_LogInterface.addMessageToLog(log, processingMessage1);
        System.assert(log.runningDetails.contains(processingMessage1));

        ilib_LogInterface.addMessageToLog(log, processingMessage2);
        System.assert(log.runningDetails.contains(processingMessage1));
        System.assert(log.runningDetails.contains(processingMessage2));
    }

    @isTest static void initiateLog()
    {
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(details);

        System.assertEquals(details.name, log.interfaceName);
        System.assertEquals(details.direction, log.direction);
        System.assertEquals(details.objectType, log.objectType);
    }

    @isTest static void initiateLogWithJson()
    {
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(details, someJson);

        System.assertEquals(someJson, log.jsonMessage);
        System.assertEquals(details.name, log.interfaceName);
        System.assertEquals(details.direction, log.direction);
        System.assertEquals(details.objectType, log.objectType);
    }

    @isTest static void initiateLogWithMockContext()
    {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/CustomerHierarchySyncInterface';  //Request URL
        req.httpMethod = 'POST'; //HTTP Request Type
        req.headers.put(ilib_LogInterface.KONG_CORRELATION_HEADER, someKongId);
        req.requestBody = Blob.valueof(someJson);
        RestContext.request = req;
        RestContext.response = res;

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(details, req);

        System.assertEquals(someJson, log.jsonMessage);
        System.assertEquals(details.name, log.interfaceName);
        System.assertEquals(details.direction, log.direction);
        System.assertEquals(details.objectType, log.objectType);
        System.assertEquals(someKongId, log.kongCorrelationId);
    }

    @isTest static void finalizeLog()
    {
        ilib_LogInterface.LogDetails logDetails = ilib_LogInterface.initiateLog(details, someJson);

        ilib_LogInterface.finalizeLog(logDetails, ilib_LogInterface.RESULT_SUCCESS, resultDetails);

        Interface_Log__c savedLog = [SELECT Result__c, Result_Details__c FROM Interface_Log__c WHERE Id = :logDetails.logRecordId];
        System.assertEquals(ilib_LogInterface.RESULT_SUCCESS, savedLog.Result__c);
        System.assertEquals(resultDetails, savedLog.Result_Details__c);
    }

}
/**
*    @author Todd Newman
*    @date  2018-05-12 
*    @description  Test Class for Utils Rest
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Todd Newman                   2018-05-12           Initial Version
*    Pooja                         2022-12-14           DCP-56196 : Method to test functionality of update interface log
*    ------------------------------------------------------------------------------------                  
*/
@isTest(SeeAllData = false)  
public class TestUtilsRest {
    /*
    *@author: Todd Newman
    *@Desc: Test method for conversion methods
    */
    public static testMethod void conversionMethods()
    {
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        insert acc;

        UtilsRest objUtilsRest = new UtilsRest();

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Price_List__c = '01-AMR-USD';
        opp.CRF_Creation_Date__c = objUtilsRest.stringTODateTimeFormatConversion('20190521');
        opp.IsPrivate = objUtilsRest.stringToBooleanConversion('N');
        opp.TotalOpportunityQuantity = objUtilsRest.stringToDecimalConversion('9');
        insert opp;

        System.assertEquals(9, opp.TotalOpportunityQuantity, 'Opportunity Quantity Value not assigned');
    }
    /*
    *@author: Todd Newman
    *@Desc: Test method for rest response methods
    */
    public static testMethod void restResponseMethods()
    {
        String errorText = 'Some test error';

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        Map<String, String> headerKeyToValue = new Map<String, String>();
        headerKeyToValue.put('Accept', 'application/json');

        UtilsRest.handleCustomRestError(new UtilsRest.InterfaceException(errorText));
        String handledError = UtilsRest.handleRetryCustomRestError(new UtilsRest.InterfaceException(errorText));//DCP-51717
        System.assertEquals(UtilsRest.REST_ERROR, RestContext.response.statusCode);
        System.assert(handledError.contains(errorText));

        UtilsRest.handleCustomRestSuccess();
        UtilsRest.createHttpRequest('Email_Verify', 'GET', headerKeyToValue, '');
        UtilsRest.createHttpRequest('Email_Verify', 'GET', headerKeyToValue);
        UtilsRest.createHttpRequest('Email_Verify', '' ,'GET', headerKeyToValue);
        UtilsRest.getIntegrationEndpoint('Email_Verify');
        UtilsRest.createHttpRequest('','','','','Get');
        UtilsRest.createHttpRequest('','','');
        Interface_Log__c interfaceAccLog = new Interface_Log__c(Result__c = 'Fail',Result_Details__c='UNABLE_TO_LOCK_ROW');
        insert interfaceAccLog;
        UtilsRest.updateHttpResultCodeForRetry(interfaceAccLog.id, 'EquipmentMasterDataReceiver');
        System.assertEquals(UtilsRest.REST_SUCCESS, RestContext.response.statusCode);
    }

}
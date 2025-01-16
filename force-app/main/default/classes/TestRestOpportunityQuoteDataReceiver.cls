/***************************************************************************************************************************************
 * NAME   : TestRestOpportunityQuoteDataReceiver
 * DESCRIPTION  : Test Class for Apex:RestOpportunityQuoteCreationDataReceiver
 * Code Coverage:97%
 * @AUTHOR : Vinay S Reddy
 * @DATE   : 17-October-2024
 *
 * MODIFICATION LOG:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                             DATE                DESCRIPTION
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vinay S Reddy                       17-Oct-2024            Initial Version.
 ****************************************************************************************************************************************/

@isTest
public class TestRestOpportunityQuoteDataReceiver {
    /* Method to test whether data received successfully
     */
    @isTest
    public static void datareceiveMethod(){
        Feature.setMockFeatureFlag('WebGeneratedQuote', true);
        Account objAccount = TestDataAccount.getCustomerAccount();
        insert objAccount;
        
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            EditWebGeneratedQuote__c = true, CreateWebGeneratedQuote__c = true
            );
        insert apexSettings;
        
        List<RestOpportunityQuoteCreationValidator.MetadataWrapper> lstValidationFields = RestOpportunityQuoteCreationValidator.getValidationFields('MyIllumina');
        
        if(lstValidationFields == null){
            lstValidationFields = new List<RestOpportunityQuoteCreationValidator.MetadataWrapper>();
            
            RestOpportunityQuoteCreationValidator.MetadataWrapper objValidationFieldsLvl1 = new RestOpportunityQuoteCreationValidator.MetadataWrapper();
            objValidationFieldsLvl1.isRoot = true;
            objValidationFieldsLvl1.fields = 'SourceSystem,SoldToUltimateConsignee,QuoteCurrency,PrimaryContact,SalesOrg,DivisonDistributionChannel,EcomId,ShipTo,BillTo,RequestType,RequestDate,quoteLines';
            lstValidationFields.add(objValidationFieldsLvl1);
            
            RestOpportunityQuoteCreationValidator.MetadataWrapper objValidationFieldsLvl2 = new RestOpportunityQuoteCreationValidator.MetadataWrapper();
            objValidationFieldsLvl2.key = 'quoteLines';
            objValidationFieldsLvl2.isRoot = false;
            objValidationFieldsLvl2.fields = 'MaterialNumberQuantity,EcomLineitemId';
            lstValidationFields.add(objValidationFieldsLvl2);
        }
        
        RestOpportunityQuoteCreationValidator.fields2Validate = lstValidationFields;
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CreateQuote';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"quoteLines" : [ {"EcomLineitemId" : "0","Quantity" : "0","MaterialNumber" : "0"}, {"EcomLineitemId" : "0","Quantity" : "0","MaterialNumber" : "0"} ],"RequestDate" : "","RequestType" : "MYCU","BillTo" : "","ShipTo" : "","EcomId" : "","DistributionChannel" : "01","Divison" : "","SalesOrg" : "US01","PrimaryContact" : "","QuoteCurrency" : "USD","UltimateConsignee" : "","SoldTo" : '+objAccount.ERP_Customer_Id__c+',"SourceSystem" : "MyIllumina"}');
        RestContext.request = req;
        RestContext.response= res;
        RestOpportunityQuoteCreationDataReceiver.handlePostRequest();
        Test.stopTest();
        system.debug('response body  '+res.responseBody);
        Assert.areEqual(200,res.statuscode);
    }
    
    /* Method to test whether data received successfully
     */
    @isTest
    public static void datareceiveMethodNegative(){
        Feature.setMockFeatureFlag('WebGeneratedQuote', true);
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            EditWebGeneratedQuote__c = true, CreateWebGeneratedQuote__c = true
            );
        insert apexSettings;
        
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/CreateQuote';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"SourceSystem" :"MyIllumina","SoldTo" : "4000066230","UltimateConsignee":"4000066230","QuoteCurrency" : "USD","PrimaryContact":"","SalesOrg":"","Divison":"","DistributionChannel":"","EcomId":"","ShipTo":"","BillTo":"","RequestType":"","RequestDate":"", "extraField" : "","quoteLines":[{"MaterialNumber" : "","Quantity" : 10,"EcomLineitemId":"", "innerExtraField": ""}]}');
        RestContext.request = req;
        RestContext.response= res;
        RestOpportunityQuoteCreationDataReceiver.handlePostRequest();
        Test.stopTest();
        system.debug('response body  '+res.responseBody);
        Assert.areEqual(400,res.statuscode);
    }
}
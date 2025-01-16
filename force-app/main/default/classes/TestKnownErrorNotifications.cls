/**
*    @author Satya Swain
*    @date   2019-05-28
*    @description   Test Class for KnownErrorNotifications class
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Satya Swain                 23 June 2019          Initial Version
*             Prem Ranjan                    21-Feb-2023         Codescan fix (APEX) Unit Test Method should include System.Assert
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestKnownErrorNotifications {

    private static final String INTERFACE_NAME = 'Product Outbound';
    private static final String APEX_CLASS_NAME = 'TestKnownErrorNotifications';

    private static final String INTERFACE_ERROR = 'A known interface error occurred';
    private static final String APEX_CLASS_ERROR = 'A known apex error occurred';

    @testSetup
    static void setupData()
    { 
        Id userid1 = TestDataUser.findUserInProfile('System Administrator').Id;
        Id userid2 = TestDataUser.findUserInProfile('Sales User').Id;

        Known_Error_Notification__c objKEN = new Known_Error_Notification__c(
            Source__c = INTERFACE_NAME,
            Pattern__c = 'bad value for restricted picklist field',
            Message__c = INTERFACE_ERROR,
            Notification_Type__c = 'Chatter;Email',
            Recipients__c = userid1 + ';' + userid2
        );

        Known_Error_Notification__c objKEN2 = new Known_Error_Notification__c(
            Source__c = APEX_CLASS_NAME,
            Pattern__c = 'bad value for restricted picklist field',
            Message__c = APEX_CLASS_ERROR,
            Notification_Type__c = 'Chatter;Email',
            Recipients__c = userid1 + ';' + userid2
        );

        insert new List<Known_Error_Notification__c> { objKEN, objKEN2 };
    }
 
    /**
    *    @author Satya Swain      
    *    @description test method for testing known error notification functionality for Interface Errors
    */
    @isTest
    static void testKnownErrorNotificationsFromInterfaceErrors()
    {
        List<ProductWrapper.Product> productWithProductSalesArea = new List<ProductWrapper.Product>();
        List<ProductWrapper.ProductSalesArea> psa1 = new List<ProductWrapper.ProductSalesArea>();

        ProductWrapper.ProductSalesArea psaRecord1 = new ProductWrapper.ProductSalesArea();
        psaRecord1.Category_Group = 'TestCategory1';
        psaRecord1.Distribution_Chain_Specific_Status = 'TestDistributionChainStatus1';
        psaRecord1.Distribution_Channel = 'TestDistributionChannel1';
        psaRecord1.Sales_Organization = 'TestSalesOrganization1';
        psaRecord1.ERP_Product_Sales_Area_ID = 'extId1';
        psa1.add(psaRecord1);

        ProductWrapper.Product productRecord1 = new ProductWrapper.Product();
        productRecord1.Name = 'TestProduct';
        productRecord1.ProductCode = '123456';
        productRecord1.Commercial_Launch_Date = '20180906';
        productRecord1.Number_Of_Samples = '22';
        productRecord1.End_of_Sale_Date = '20180920';
        productRecord1.End_of_Ship_Date = '20180925';
        productRecord1.End_of_Service_Date = '20180930';
        productRecord1.Cross_Plant_Material_Status = 'Z5';
        productRecord1.Product_Manager = '100031';
        productRecord1.Material_Class = 'Test Value';
        productRecord1.Custom_Product = true;
        productRecord1.Replenishment_Eligible = null;
        productRecord1.productSalesArea = new List<ProductWrapper.ProductSalesArea>();
        productRecord1.productSalesArea.addAll(psa1);
        productWithProductSalesArea.add(productRecord1);

        String productJSON = JSON.serialize(productWithProductSalesArea);

        Test.startTest();

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProductMaterialSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(productJSON);
        RestContext.request = req;
        RestContext.response = res;
        ProductDataReceiver.upsertIncomingValues(); 
        Test.getEventBus().deliver();

        Test.stopTest();

        Error_Notification__c objEN = [SELECT Id, Name, Source__c, Result__c FROM Error_Notification__c LIMIT 1];
        System.assertEquals(INTERFACE_NAME, objEN.Source__c);
        System.assertEquals(INTERFACE_ERROR, objEN.Result__c);
    }

    /**
    *    @author Satya Swain      
    *    @description test method for testing known error notification functionality for Exceptions
    */
    @isTest
    static void testKnownErrorNotificationsFromExceptions()
    {

        Test.startTest();
        try
        {
            Product2 objProduct = new Product2();
            objProduct.Name = 'Test Product';
            objProduct.Material_Class__c = 'Test Value';
            insert objProduct;
        }
        catch (Exception e)
        {
            KnownErrorNotifications.checkForKnownErrors(APEX_CLASS_NAME, e);
            KnownErrorNotifications.checkForKnownErrors(APEX_CLASS_NAME, null, e);
            KnownErrorNotifications.checkForKnownErrors(APEX_CLASS_NAME, null, e.getMessage());
            KnownErrorNotifications.checkForKnownErrors(APEX_CLASS_NAME, e, null);
        }
        Test.getEventBus().deliver();
        Test.stopTest();

        Error_Notification__c objEN = [SELECT Id, Name, Source__c, Result__c FROM Error_Notification__c LIMIT 1];
        System.assertEquals(APEX_CLASS_NAME, objEN.Source__c);
        System.assertEquals(APEX_CLASS_ERROR, objEN.Result__c);
    }
    
    /**
    *    @author Nitin      
    *    @description 
    */
    @isTest
    static void testKnownErrorNotificationsFromExceptionswithExceptionWrapper()
    {

        Test.startTest();
        try
        {
            Product2 objProduct = new Product2();
            objProduct.Name = 'Test Product';
            objProduct.Material_Class__c = 'Test Value';
            insert objProduct;
        }
        catch (Exception e)
        {
            ApexExceptions.ExceptionWrapper exceptionWrappers= new ApexExceptions.ExceptionWrapper( e.getMessage(),  e.getStackTraceString(),  e.getTypeName(),  e.getLineNumber());
            KnownErrorNotifications.checkForKnownErrors(APEX_CLASS_NAME, exceptionWrappers);
            KnownErrorNotifications.checkForKnownErrors(APEX_CLASS_NAME, null, exceptionWrappers);
            KnownErrorNotifications.checkForKnownErrors(APEX_CLASS_NAME, null, exceptionWrappers.Message);
            KnownErrorNotifications.checkForKnownErrors(APEX_CLASS_NAME, exceptionWrappers, null);
        }
        Test.getEventBus().deliver();
        Test.stopTest();

        Error_Notification__c objEN = [SELECT Id, Name, Source__c, Result__c FROM Error_Notification__c LIMIT 1];
        System.assertEquals(APEX_CLASS_NAME, objEN.Source__c,'source should be '+APEX_CLASS_NAME +' but it is '+objEN.Source__c);
        System.assertEquals(APEX_CLASS_ERROR, objEN.Result__c,'result should be '+APEX_CLASS_ERROR +' but it is '+objEN.Result__c);
    }

    /**
    *    @author Satya Swain      
    *    @description test method for testing known error notification functionality for Exceptions
    */
    @isTest
    static void coverWithoutWorkingEvent()
    {
        Known_Error_Notification__c objKEN = [SELECT Id, Source__c, Pattern__c, Message__c, Notification_Type__c, Recipients__c FROM Known_Error_Notification__c WHERE Source__c = :APEX_CLASS_NAME LIMIT 1];

        Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Error_Notification__c.getRecordTypeInfosByDeveloperName();

        Error_Notification__c objErrorNotification = new Error_Notification__c(
            Source__c = objKEN.Source__c,
            Interface_Log__c = null,
            ERP_Record_Id__c = null,
            Account__c = null,
            Result__c = objKEN.Message__c,
            Full_Error_Text__c = 'Error Badness',
            RecordTypeId = rts.get('Interface_Errors').getRecordTypeId(),
            Known_Error_Notification__c = objKEN.Id
        );
        insert objErrorNotification;
        system.assert(objErrorNotification != null , 'objErrorNotification is null');
        Test.startTest();
        ProcessKnownErrors.handleKnownErrors(new List<Id> {objErrorNotification.Id} );
        Test.stopTest();
    }

}
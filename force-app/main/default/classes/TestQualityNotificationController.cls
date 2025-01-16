/***************************************************************************************************************************************
 * NAME   : TestQualityNotificationController
 * DESCRIPTION  : TestQualityNotificationController for QualityNotificationController LWC Controller class
 *    
 * @AUTHOR : Preetha
 * @DATE   : 17-Sep-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Preetha                  17 SEP 22           Initial Version
 */
@IsTest(SeeAllData=false)
public with sharing class TestQualityNotificationController {
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_PARTS_ORDER_TYPE_RETURN = 'Return';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    /*******************************************************************************************************
    * @description test data setup
    */
    
    //removed extra code for test data setup rest all other methods are getting covered in TestPartsOrder
    static testmethod void checkQNControllerTreeStructure() {
        //testDataCreation();
        Test.startTest();
        AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition LIMIT 1];       

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name like '%System Admin%'].Id,
            LastName = 'last_1',
            Email = 'puser000@test.com',
            Username = 'puser000@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
       );
       insert u;
       UserAppInfo app = new UserAppInfo();
       app.AppDefinitionId = appDefinition.DurableId;
       app.UserId = u.Id;
       app.formfactor = 'Small';
       insert app;

        
        System.runAs(u){
            QualityNotificationController.getCurrentApp();
            System.assertEquals(appDefinition.DurableId,app.AppDefinitionId,'App check');
        }
        Test.stopTest();
    }
    /*******************************************************************************************************
    * @description test method validateProductUtilizationMode Exception in the catch block
    * 
    */
    @isTest
    static void getPartsOrderWithQNException() {
        Test.StartTest();
        try {
            QualityNotificationController.getPartsOrderWithQN('1234');
        } catch (Exception e) {
            System.assertEquals('Invalid id: 1234',e.getMessage(),'Unhandled Error');
        }
        Test.stopTest();
    }
}
/***************************************************************************************************************************************
 * NAME   : TestMaterialConsumedWDManager
 * DESCRIPTION  : TestClass for MaterialConsumedWDManager
 *    
 * @AUTHOR : Vignesh
 * @DATE   : 28-Sept-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vignesh               28-Sept-2021              Initial Version
 ****************************************************************************************************************************************/
@isTest(SeeAllData = false isParallel = false)
public with sharing class TestMaterialConsumedWDManager {
    public static Case cs;
    public static Account acc;
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';  
    public static final String WORKDETAIL_RECORDTYPE = 'Usage/Consumption';
    
    /*******************************************************************************************************
    * @description : Method to create setupd data.
    * @param None
    * @return void
    * @example
    ********************************************************************************************************/
    @testSetup
    public static void initializeTestData(){
        //Insert Service Team
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        //Insert Service Group Member.
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        //Insert Account
        acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        //Insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //Insert case        
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }
      
      
    static testMethod void newWorkOrderCreation(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'Product2',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Installed_Product__c'
        );
        insert apexSettings;
        
        list<Product2> lstProduct = new list<Product2>();
        Product2 objP1 = TestDataFieldService.createProduct('Test Product','Instrument');
        Product2 objP2 = TestDataFieldService.createProduct('NONFRU Product','Instrument');
        objP2.Material_Class__c = '';
        objP2.GFSL_FC_Hierarchy__c = 'Non-FRU Service Part';
        lstProduct.add(objP1);
        lstProduct.add(objP2);
        insert lstProduct;

        Account account = [Select id from Account limit 1];

        list<SVMXC__Installed_Product__c> lstInstalledProduct = new list<SVMXC__Installed_Product__c>(); 
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP1', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = account.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objP1.Id;
        lstInstalledProduct.add(objInstalledProduct);

        SVMXC__Installed_Product__c objInstalledProduct2 = TestDataFieldService.createInstalledProduct('Test IP2', 'USD', 'New');
        objInstalledProduct2.SVMXC__Company__c = account.Id;
        objInstalledProduct2.Operation_Status__c='Off';
        objInstalledProduct2.SVMXC__Product__c = objP2.Id;
        lstInstalledProduct.add(objInstalledProduct2);

        SVMXC__Installed_Product__c objInstalledProduct3 = TestDataFieldService.createInstalledProduct('Test IP2', 'USD', 'New');
        objInstalledProduct3.SVMXC__Company__c = account.Id;
        objInstalledProduct3.Operation_Status__c='Off';
        objInstalledProduct3.SVMXC__Product__c = objP2.Id;
        objInstalledProduct3.SVMXC__Parent__c = objInstalledProduct.Id;
        lstInstalledProduct.add(objInstalledProduct3);

        insert lstInstalledProduct;

        SVMXC__Installed_Product__c o1 = [select id,Service_Product_Type__c from SVMXC__Installed_Product__c where id = :objInstalledProduct3.Id];
        system.debug('Service_Product_Type__c=='+o1.Service_Product_Type__c);
		
        Test.startTest();
        Case caseRec = [Select id from Case limit 1];
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, caseRec.Id, 'Initiated');
        ObjworkOrder.SVMXC__Order_Type__c='Installation';
        ObjworkOrder.Is_Auto_Created__c = true; 
        ObjworkOrder.SVMXC__Component__c = objInstalledProduct.Id;
        insert ObjworkOrder;
        
        SVMXC__Service_Order_Line__c objWorkDetail = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(ObjworkOrder.Id,WORKDETAIL_RECORDTYPE);
        objWorkDetail.SVMXC__Line_Type__c = 'Material Consumed';
        objWorkDetail.SVMXC__Serial_Number__c = objInstalledProduct2.Id;
        objWorkDetail.SVMXC__Actual_Quantity2__c = 1;
        //insert objWorkDetail;
        
        
        SVMXC__Service_Order_Line__c objWorkDetail2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(ObjworkOrder.Id,WORKDETAIL_RECORDTYPE);
        objWorkDetail2.SVMXC__Line_Type__c = 'Material Consumed';
        objWorkDetail2.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct3.Id;
        objWorkDetail2.SVMXC__Actual_Quantity2__c = 1;
        insert new List<SVMXC__Service_Order_Line__c> { objWorkDetail, objWorkDetail2 };


        MaterialConsumedWDManager.doBusinessLogic(new list<Id>{ObjworkOrder.Id});
        Test.stopTest();
        SVMXC__Installed_Product__c objIP = [select id,SVMXC__Parent__c from SVMXC__Installed_Product__c WHERE ID = :objInstalledProduct2.Id];
		system.assertEquals(null, objIP.SVMXC__Parent__c);
    }
}
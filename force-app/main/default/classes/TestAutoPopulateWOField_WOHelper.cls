/***************************************************************************************************************************************
 * NAME   : TestAutoPopulateWOField_WOHelper 
 * DESCRIPTION  : TestClass for BeforeEvtAutoPopulateWOField_WOHelper Apex class
 *           DCP-49644  :To autopopulate Product Family and Repair Protocol field values on workOrder object
 *    
 * @AUTHOR : Pooja Shalwadi
 * @DATE   : 06-Jan-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Pooja                 06-Jan-2022             Initial Version
* Shivani                15-Dec-2022             DCP-52634 - Populate Ssubscription fields
* Dhairya                24-Sept-24              No changes
  ***************************************************************************************************************************************
*/
@isTest
public class TestAutoPopulateWOField_WOHelper {
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    static Case cs;
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_TIMEZONE = 'America/Los_Angeles';
    /**
*  @author Pooja
*  @description - initialize test data
**/ //dummy commit
    @testSetup
    public static void initializeTestData() {
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact Insertion failed');
        
        //insert case        
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    static testmethod void testPopulateProductFamilyAndRepairs() {
       
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assertNotEquals(null, acc.Id, 'Account Insertion failed');
        
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Family='NextSeq - NSQ - Dx';
        insert objProduct;
        System.assertNotEquals(null, objProduct.Id, 'Product Insertion failed');        
        
        Product2 objProduct1=TestDataFieldService.createProduct('Test Product1','Instrument');
        objProduct.Family='NextSeq - NSQ - Dx';
        insert objProduct1;
        System.assertNotEquals(null, objProduct1.Id, 'Product Insertion failed');        
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        System.assertNotEquals(null, workOrder.Id, 'Work Order Insertion failed');
        Test.startTest();
        workOrder.SVMXC__Product__c =null;
        update workOrder;
        Test.stopTest();
        System.assertEquals(userinfo.getUserId(), [select id,Repair_protocols__c, Original_Owner__c from SVMXC__Service_Order__c where id =: workOrder.Id][0].Original_Owner__c, 'Logic failed');
        
    }
    static testmethod void testAutoDispatchPFSE(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Associated_Product__c'
        );
        insert apexSettings;
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        System.assertNotEquals(null, acc.Id, 'Account Insertion failed');

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;

        SVMXC__Service_Contract__c objServiceContract= TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        insert objServiceContract;

        SVMXC__Service_Contract__c objServiceContract1 = TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract1.SVMXC__Service_Level__c = objServiceLevel.Id;
        objServiceContract1.ERP_Contract_Type__c = 'Software (ZWS)';
        objServiceContract1.Registration_Contact_Email__c = 'test@test.com';
        objServiceContract1.Domain_ID__c = 'Test';
        objServiceContract1.Domain_URL_Pattern__c='Test';
        objServiceContract1.Workgroup_Name__c = 'Test';
        insert objServiceContract1;

        //insert objInstalledProduct;
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        insert objInstalledProduct;
         
        // Insert Covered Product
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;   
        
        Contact objContact = TestDataContact.getNewContact(acc);

        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Family='NextSeq - NSQ - Dx';
        insert objProduct;
        System.assertNotEquals(null, objProduct.Id, 'Product Insertion failed');        
        
        Product2 objProduct1=TestDataFieldService.createProduct('Test Product1','Instrument');
        objProduct.Family='NextSeq - NSQ - Dx';
        insert objProduct1;
        System.assertNotEquals(null, objProduct1.Id, 'Product Insertion failed');        
        
        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', objContact.Id);
        Test.startTest();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Case__c = objCase.Id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.Subscription__c = objServiceContract1.Id;
        insert workOrder;
        Test.stopTest();
        System.assertNotEquals(null, workOrder.Id, 'Work Order Insertion failed');
       // workOrder.SVMXC__Product__c =null;
       // update workOrder;
    }

    static testmethod void testSubcriptionFields() {
        // Preparing data
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'Associated_Product__c',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c'
        );
        insert apexSettings;
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c = 'Distributor';
        insert acc;

        BusinessHours objBusinessHours = [SELECT Id FROM BusinessHours WHERE Name = 'Default' LIMIT 1];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBusinessHours.Id;
        insert objServiceLevel;

        List<SVMXC__Service_Contract__c> contractsLst = new List<SVMXC__Service_Contract__c>();
        for (Integer i = 0; i < 2; i++) {
            SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(acc.Id);
            objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
            objServiceContract.ERP_Contract_Type__c = 'Software (ZWS)';
            objServiceContract.Registration_Contact_Email__c = 'test' + i + '@test.com';
            objServiceContract.Domain_ID__c = 'Test' + i;
            objServiceContract.Domain_URL_Pattern__c = 'Test' + i;
            objServiceContract.Workgroup_Name__c = 'Test' + i;
            contractsLst.add(objServiceContract);
        }
        insert contractsLst;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        insert objInstalledProduct;

        Contact objContact = TestDataContact.getNewContact(acc);

        Product2 objProduct = TestDataFieldService.createProduct('Test Product', 'Instrument');
        objProduct.Family = 'NextSeq - NSQ - Dx';
        insert objProduct;

        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', objContact.Id);
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.SVMXC__Product__c = objProduct.Id;
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Case__c = objCase.Id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.Subscription__c = contractsLst[0].Id;
        insert workOrder;

        Test.startTest();
        
        workOrder.Subscription__c = contractsLst[1].Id;
        update workOrder;

        SVMXC__Service_Order__c updatedWorkOrder = [SELECT Id, Subscription__c, Workgroup_Name__c FROM SVMXC__Service_Order__c WHERE Id =: workOrder.Id LIMIT 1];
        System.assertEquals(contractsLst[1].Workgroup_Name__c, updatedWorkOrder.Workgroup_Name__c, 'Subscription fields not populated correctly');

        Test.stopTest();
    }
    /**
    *  @author Priya
    *  @description - CMCM-3104
    **/
    @IsTest
    static void testBlankOutSLATerms() {
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        objServiceLevel.SVMXC__Active__c = true;
        objServiceLevel.SVMXC__Onsite_Response_Tracked_On__c = 'WorkOrder';
        objServiceLevel.SVMXC__Resolution_Tracked_On__c = 'WorkOrder';
        objServiceLevel.SVMXC__Restoration_Tracked_On__c = 'WorkOrder';
        insert objServiceLevel;

        SVMXC__Service_Contract__c objServiceContract= TestDataFieldService.createServiceContract(acc.Id);
        objServiceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        objServiceContract.Name ='Test Contract';
        objServiceContract.SVMXC__Company__c = acc.id;
        objServiceContract.SVMXC__Start_Date__c = System.today();
        objServiceContract.SVMXC__End_Date__c = Date.today().addDays(90);
        insert objServiceContract;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        SVMXC__Installed_Product__c installedProductWithSLA = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        installedProductWithSLA.SVMXC__Company__c = acc.Id;
        installedProductWithSLA.Currently_Active_Service_Contract__c = objServiceContract.id;
        insert installedProductWithSLA;

        SVMXC__Installed_Product__c installedProductWithoutSLA = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        installedProductWithoutSLA.SVMXC__Company__c = acc.Id;
        insert installedProductWithoutSLA;

        Test.startTest();
        workOrder.SVMXC__Component__c = installedProductWithoutSLA.id;
        insert workOrder;
        System.assertEquals(null, workOrder.SVMXC__SLA_Terms__c, 'SLA terms should be blanked out on removal of Installed Product');
        workOrder.SVMXC__Component__c = null;
        update workOrder;
        Test.stopTest();
        System.assertEquals(null, workOrder.SVMXC__SLA_Terms__c, 'SLA terms should be blanked out on update to Installed Product without SLA terms');
    }
    
}
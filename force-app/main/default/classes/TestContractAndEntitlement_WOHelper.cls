/**
* @author Shivani Jain
* @date 8th June 2022
*
* @description DCP-54018 Test class for ServiceContractAndEntitlement_WOHelper
*/
@IsTest
private class TestContractAndEntitlement_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';

    /**
    *  @description - initialize test data
    **/
    @testSetup
    public static void initializeTestData() {
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = STRING_SERVICE_TEAM_NAME,
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive=true LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail1@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = lstUsers[0].Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);        
       
    }
   /*
    *  @description - Test Method to cover ServiceContractAndEntitlement_WOHelper Class
    */
   static testMethod void workOrderStatusUpdatedToScheduled(){
        //initializeTestData();
         
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
         
         //Creating Contact
         Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
   
         //Creating Case      
         Case cs = TestDataCase.initServiceRequestCase(con);
         insert cs;
       
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;

        insert workOrder;

        Test.startTest();   
        workOrder.SVMXC__Scheduled_Date_Time__c=system.now();
        workOrder.SVMXC__SM_Scheduled_Duration__c=1.2;
        workOrder.SVMXC__Order_Status__c = 'Scheduled'; 
        update workOrder;
        System.assert(workOrder.Id != null, 'null workOrder Id');
        Test.stopTest();
      }
    
    /*
    *  @description - Test Method to cover ServiceContractAndEntitlement_WOHelper Class
    */
    static testMethod void workOrderStatusUpdatedToScheduled1(){
        //initializeTestData();
        Test.startTest();   
         
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
    
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
       
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        //Insert Location
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
        insert objLocation;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct;

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.SVMXC__Site__c = objLocation.Id;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        List<SVMXC__Service_Order__c> lstServiceOrder = [Select Id, SVMXC__Order_Type__c from SVMXC__Service_Order__c where id=:workOrder.Id];
        System.assertEquals('Planned Maintenance', lstServiceOrder[0].SVMXC__Order_Type__c, 'Diff Order Type');
        Test.stopTest();
      }
   /*
    *  @description - test the ServiceUtilityCollection
    */
    static testmethod void serviceUtilityCollectionTest(){
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'Product2',
            Bypass_Triggers_By_Object_3__c = 'Service_Bill_Of_Materials__c',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_5__c = 'Associated_Product__c'
        );
        insert apexSettings;
        //insert account
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
                objAccount.Account_Group__c='Distributor';
                insert objAccount;       
        System.assert(objAccount.Id != null, 'null objAccount Id');
        
        //insert product
        Product2 product1 = TestDataMaster.initProduct('Test Product','Tools');
        product1.GFSL_FC_Hierarchy__c = 'Tools';
        product1.Service_Product_Type__c = 'Spare';
        product1.Source_System__c = 'SAP';
        insert product1;
        System.assert(product1.Id != null, 'null product1 Id');
        
        //insert serviceBOM
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
        serviceBOM.Default__c = true;
        update serviceBOM;
        System.assert(serviceBOM.Id != null, 'null serviceBOM Id');
        
        //insert objInstalledProduct
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert objInstalledProduct;
        System.assert(objInstalledProduct.Id != null, 'null objInstalledProduct Id');
        
        //insert contact
        Contact objContact = TestDataContact.getNewContact(objAccount);
        System.assert(objContact.Id != null, 'null objContact Id');
        Test.startTest();
        //insert case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        objCase.SVMXC__Product__c = product1.Id;
        insert objCase;
        System.assert(objCase.Id != null, 'null objCase Id');
        
        //insert objLocation
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location', 'Test Street', 'Ireland', '123456', 'USD');
            insert objLocation;
        System.assert(objLocation.Id != null, 'null objLocation Id');
        
        //insert workOrder
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.SVMXC__Site__c = objLocation.Id;
        workOrder.Is_Auto_Created__c=true;
        workorder.SVMXC__Product__c = product1.Id;
        insert workorder;
        System.assert(workOrder.Id != null, 'null workOrder Id');
        //insert objOrderDetail
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Product__c = product1.Id;
        insert objOrderDetail;
        System.assert(objOrderDetail.Id != null, 'null objOrderDetail Id');
        
        //insert ObjServiceContract
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        insert ObjServiceContract;
        system.assert(ObjServiceContract.Id != null, 'null ObjServiceContract');
        Test.stopTest();
        //insert ObjCoveredProduct
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        ObjCoveredProduct.SVMXC__Service_Contract__c = ObjServiceContract.Id;
        insert ObjCoveredProduct;
        system.assert(ObjCoveredProduct.Id != null, 'null covered product');
        
        //insert coveredLocation
        SVMXC__Service_Contract_Sites__c coveredLocation = new SVMXC__Service_Contract_Sites__c(
            SVMXC__Site__c = objLocation.Id,SVMXC__Service_Contract__c = ObjServiceContract.Id
        );
        insert coveredLocation;
        system.assert(ObjCoveredProduct.Id != null, 'null covered location');
        
        //creating FRU List
        FRU_List__c objFRUList = TestDataFieldService.createToolFRU(serviceBOM.Id,product1.Id);
        system.assert(objFRUList.Id != null, 'null FRU List');
        
       
        //set of products
        Set<Id> setProductsIdsSelected = new Set<Id>{objOrderDetail.SVMXC__Product__c};
        Map < Id, SVMXC__Service_Order__c > idToWorkOrderMap = new Map < Id, SVMXC__Service_Order__c > ();
        idToWorkOrderMap.put(workOrder.id,workOrder);
        //test checkCompatibleProductsInFRUList
        ServiceUtilityCollection.checkCompatibleProductsInFRUList(new List<SVMXC__Service_Order_Line__c>{objOrderDetail}, idToWorkOrderMap, null, 'SVMXC__Service_Order__c', setProductsIdsSelected, new set<String>{'Tool'});
        //test insertEntitlement
        ServiceUtilityCollection.insertEntitlement(new List<sObject> {workOrder}, new Set<Id>{objInstalledProduct.Id}, new Set<Id>{objLocation.Id}, new List<String>{'SVMXC__Component__c','SVMXC__Site__c'});
        //test updateLatestExpiringContractOnIP
        ServiceUtilityCollection.updateLatestExpiringContractOnIP(new Set<Id>{objInstalledProduct.Id});
        
    }
   
}
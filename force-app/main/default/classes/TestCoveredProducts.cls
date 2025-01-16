/***************************************************************************************************************************************
 * NAME   : TestCoveredProducts
 * DESCRIPTION  : TestClass for CoveredProductTrigger
 * @AUTHOR : Shashank Singhal
 * @DATE   : 12-Oct-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shashank             12-Oct-2018            Initial Vesrion
 *****************************************************************************************************************************************/ 
@isTest(seeAllData = false)
private class TestCoveredProducts{
    
    /**
    *  @author Shashank Singhal
    *  @description - test the update on IP when a new covered product is inserted/Updated/Deleted/Undeleted 
    **/
    static testMethod void testCoveredProduct(){
        Account objAccount = TestDataAccount.getAccount('Test');
        insert objAccount;
        system.assertNotEquals(null,objAccount.id);
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        system.assertNotEquals(null,ip.id);
        SVMXC__Installed_Product__c ip1 = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip1;
        system.assertNotEquals(null,ip1.id);
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = '1111';
        insert sp;
        system.assertNotEquals(null,sp.id);
        Product2 prod = new Product2(Name='TestProd',
                                     //Auto_Create_Install_Work_Order__c=true,
                                     Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case',
                                     Service_Product_Type__c='Instrument',
                                     Regulatory_Type__c='DX',
                                     IsActive=true,
                                     ProductCode='43535',
                                     Material_Number__c = '1111',
                                     Service_Level__c = 'GOLD'
                                    );        
        insert prod;
        system.assertNotEquals(null,prod.id);
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
        insert objServiceContract;
        system.assertNotEquals(null,objServiceContract.id);
        Test.startTest();
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert cp;
        List<SVMXC__Installed_Product__c> lstIP=new List<SVMXC__Installed_Product__c>();
        system.assertNotEquals(null,cp.id);
        lstIP=[select id, Currently_Active_Service_Contract__c from SVMXC__Installed_Product__c where id=:ip.id];
        cp.SVMXC__Installed_Product__c = ip1.Id;
        update cp;
        Test.stopTest();
        lstIP=[select id, Currently_Active_Service_Contract__c from SVMXC__Installed_Product__c where id=:ip1.id];
        system.assertEquals(lstIP[0].Currently_Active_Service_Contract__c, objServiceContract.id);
    }
    /**
    *  @description - test the update on IP when a covered product is inserted/Deleted 
    **/
    static testMethod void testCoveredProductDelete(){
        Account objAccount = TestDataAccount.getAccount('Test');
        insert objAccount;
        system.assertNotEquals(null,objAccount.id);
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        system.assertNotEquals(null,ip.id);
        SVMXC__Installed_Product__c ip1 = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip1;
        system.assertNotEquals(null,ip1.id);
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = '1111';
        insert sp;
        system.assertNotEquals(null,sp.id);
        Product2 prod = new Product2(Name='TestProd',
                                     Auto_Create_Install_Work_Order__c=true,
                                     Service_Product_Type__c='Instrument',
                                     Regulatory_Type__c='DX',
                                     IsActive=true,
                                     ProductCode='43535',
                                     Material_Number__c = '1111',
                                     Service_Level__c = 'GOLD'
                                    );        
        insert prod;
        system.assertNotEquals(null,prod.id);
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
        insert objServiceContract;
        system.assertNotEquals(null,objServiceContract.id);
        Test.startTest();
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert cp;
        List<SVMXC__Installed_Product__c> lstIP=new List<SVMXC__Installed_Product__c>();
        system.assertNotEquals(null,cp.id);
        delete cp;
        Test.stopTest();
        lstIP=[select id, Currently_Active_Service_Contract__c from SVMXC__Installed_Product__c where id=:ip.id OR id=:ip1.id];
        system.assertEquals(null,lstIP[0].Currently_Active_Service_Contract__c);
        system.assertEquals(null,lstIP[1].Currently_Active_Service_Contract__c);
    }

	  /**
    *  @author Digvijay Singh
    *  @description - Covers the "updateInstrumentonPMWorkOrders" method in CoveredProducts Class.
    **/  
  static testmethod void testInstrumetUpdateonCoveredProduct(){
     
     Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        
        Contact con = TestDataPerson.getNewContact(null);
       Case  cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
 
 
    SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
    insert ip;
    system.assertNotEquals(null,ip.id);
    SVMXC__Installed_Product__c ip1 = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
    insert ip1;
        
    //pm template
    SVMXC__PM_Plan_Template__c pmTemplate = new SVMXC__PM_Plan_Template__c();
    pmTemplate.Name='Test PM Template';
    pmTemplate.CurrencyIsoCode='USD';
    insert pmTemplate;
        
    //Service Plan
    SVMXC__Service_Plan__c testServicePlan = new SVMXC__Service_Plan__c();
    testServicePlan.Name = 'Test Service Plan';
    testServicePlan.SVMXC__Active__c = true;
    testServicePlan.OQ_Required__c = true;
    insert testServicePlan;
    
    //service contract
    SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(acc.Id);
    testServCont.SVMXC__Service_Plan__c = testServicePlan.id;
    testServCont.SVMXC__Start_Date__c = system.today();
    testServCont.SVMXC__End_Date__c = system.today().addYears(1);
    insert testServCont;
    
    //SVMXC__PM_Plan__c
    SVMXC__PM_Plan__c pmPlan = new SVMXC__PM_Plan__c();
    pmPlan.Name='BYANNUAL Plan';
    pmPlan.CurrencyIsoCode='USD';
    pmPlan.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
    pmPlan.SVMXC__Service_Contract__c= testServCont.Id;
    insert pmPlan;
    
    SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
    cp.SVMXC__Service_Contract__c = testServCont.Id;
    insert cp;
    
    SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
    workOrder2.SVMXC__Company__c=acc.id;
    workOrder2.SVMXC__Component__c=ip.id;
    workOrder2.Is_Auto_Created__c = true;
    workOrder2.SVMXC__Order_Type__c='Preventative Maintenance';
    workorder2.SVMXC__Is_PM_Work_Order__c = true;
    workorder2.SVMXC__PM_Plan__c = pmPlan.Id;
    workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
    workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
    
    insert workOrder2;
	
	Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.CurrencyIsoCode='USD';
        objEntitlement.Work_Order__c =workOrder2.id;
        objEntitlement.Service_Contract__c=testServCont.id;
        insert objEntitlement;
    Test.StartTest();
    cp.SVMXC__Installed_Product__c =ip1.id;
    update cp;
    
    List<SVMXC__Service_Order__c> lstWO=[Select id , SVMXC__Component__c from SVMXC__Service_Order__c  where id=:workOrder2.id];
     System.assertEquals(lstWO[0].SVMXC__Component__c, ip1.id);
    Test.StopTest();
    
    
        
        
 }

	
}
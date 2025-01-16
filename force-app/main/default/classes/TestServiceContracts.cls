/***************************************************************************************************************************************
 * NAME   : TestServiceContracts
 * DESCRIPTION  : TestClass for Service Contract Trigger and Service Contract Batch
 * @AUTHOR : Shashank Singhal
 * @DATE   : 13-Sept-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shashank             13-Sept-2018            Initial Vesrion
 * Pooja                23-Sep-2022             CodeScan Fixes
 * Dhairya                   11-Oct-2024           CMCM-5165 No changes in the test class only using for deployment

 *****************************************************************************************************************************************/ 
@isTest(seeAllData = false)
private class TestServiceContracts {

    static testMethod void insertServiceContract(){
        List<SVMXC__Service_Contract__c> lstServCont = new List<SVMXC__Service_Contract__c>();
        Account objAccount = TestDataAccount.getNewAccount();
        system.assertNotEquals(null,objAccount.id);
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont = setContractDates(testServCont, system.today(), system.today());
        lstServCont.add(testServCont);
        SVMXC__Service_Contract__c testServCont1 = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont1 = setContractDates(testServCont1, system.today().adddays(-1), system.today().addDays(1));
        lstServCont.add(testServCont1);
        SVMXC__Service_Contract__c testServCont2 = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont2 = setContractDates(testServCont2, system.today().adddays(1), system.today().addDays(2));
        lstServCont.add(testServCont2);
        SVMXC__Service_Contract__c testServCont3 = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont3 = setContractDates(testServCont3, system.today().adddays(-2), system.today().addDays(-1));
        lstServCont.add(testServCont3);
        test.starttest();
        insert lstServCont;
        testServCont=lstServCont[0];
        testServCont1=lstServCont[1];
        testServCont2=lstServCont[2];
        testServCont3=lstServCont[3];
        system.assertNotEquals(null,testServCont.id);
        system.assertNotEquals(null,testServCont1.id);
        system.assertNotEquals(null,testServCont2.id);
        system.assertNotEquals(null,testServCont3.id);
        Set<Id> serviceContractIds=new Set<id>();
        serviceContractIds.add(testServCont.id);
        serviceContractIds.add(testServCont1.id);
        serviceContractIds.add(testServCont2.id);
        serviceContractIds.add(testServCont3.id);
        for(SVMXC__Service_Contract__c objServ: [select id, Status__c from SVMXC__Service_Contract__c where id IN: serviceContractIds]){
            if(objServ.id==testServCont.id){
                system.assertEquals('Expired',objServ.Status__c);
            }
            else if(objServ.id==testServCont1.id){
                system.assertEquals('Active',objServ.Status__c);
            }else if(objServ.id==testServCont2.id){
                system.assertEquals('Pending Activation',objServ.Status__c);
            }else if(objServ.id==testServCont3.id){
                system.assertEquals('Expired',objServ.Status__c);
            }
        }
        test.stoptest();
    }
    
    static testMethod void updateServiceContract(){
        Account objAccount = TestDataAccount.getNewAccount();
        system.assertNotEquals(null,objAccount.id);
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        system.assertNotEquals(null,ip.id);
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
                                     Service_Level__c = 'INVALID'
                                    );        
        insert prod;
        system.assertNotEquals(null,prod.id);
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont.SVMXC__Service_Plan__c = sp.id;
        testServCont = setContractDates(testServCont, system.today(), system.today());
        insert testServCont;
        system.assertNotEquals(null,testServCont.id);
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = testServCont.Id;
        insert cp;
        system.assertNotEquals(null,cp.id);
        testServCont.SVMXC__Start_Date__c = system.today().adddays(-1);
        test.starttest();
        update testServCont;
        SVMXC__Service_Contract__c objServ=[select id, Status__c from SVMXC__Service_Contract__c where id =: testServCont.id LIMIT 1];
        system.assertEquals('Active',objServ.Status__c);
        test.stoptest();
    }
    
    static testMethod void batchServiceContract(){
        List<SVMXC__Service_Contract__c> lstServCont = new List<SVMXC__Service_Contract__c>();
        Account objAccount = TestDataAccount.getNewAccount();
        system.assertNotEquals(null,objAccount.id);
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont = setContractDates(testServCont, system.today(), system.today());
        lstServCont.add(testServCont);
        SVMXC__Service_Contract__c testServCont1 = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont1 = setContractDates(testServCont1, system.today().adddays(-1), system.today().addDays(1));
        lstServCont.add(testServCont1);
        SVMXC__Service_Contract__c testServCont2 = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont2 = setContractDates(testServCont2, system.today().adddays(1), system.today().addDays(2));
        lstServCont.add(testServCont2);
        SVMXC__Service_Contract__c testServCont3 = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont3 = setContractDates(testServCont3, system.today().adddays(-2), system.today().addDays(-1));
        lstServCont.add(testServCont3);
        test.starttest();
        insert lstServCont;
        testServCont=lstServCont[0];
        testServCont1=lstServCont[1];
        testServCont2=lstServCont[2];
        testServCont3=lstServCont[3];
        system.assertNotEquals(null,testServCont.id);
        system.assertNotEquals(null,testServCont1.id);
        system.assertNotEquals(null,testServCont2.id);
        system.assertNotEquals(null,testServCont3.id);
        Set<Id> serviceContractIds=new Set<id>();
        serviceContractIds.add(testServCont.id);
        serviceContractIds.add(testServCont1.id);
        serviceContractIds.add(testServCont2.id);
        serviceContractIds.add(testServCont3.id);
        for(SVMXC__Service_Contract__c objServ: [select id, Status__c from SVMXC__Service_Contract__c where id IN: serviceContractIds]){
            if(objServ.id==testServCont.id){
                system.assertEquals('Expired',objServ.Status__c);
            }
            else if(objServ.id==testServCont1.id){
                system.assertEquals('Active',objServ.Status__c);
            }else if(objServ.id==testServCont2.id){
                system.assertEquals('Pending Activation',objServ.Status__c);
            }else if(objServ.id==testServCont3.id){
                system.assertEquals('Expired',objServ.Status__c);
            }
        }
        database.executebatch(new ServiceContractsBatchToUpdateStatus());
        test.stoptest();
    }
    
    static testMethod void scheduleBatchServiceContract(){
        List<SVMXC__Service_Contract__c> lstServCont = new List<SVMXC__Service_Contract__c>();
        Account objAccount = TestDataAccount.getNewAccount();
        system.assertNotEquals(null,objAccount.id);
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont = setContractDates(testServCont, system.today(), system.today());
		testServCont.Pending_Cancellation__c = true;
        lstServCont.add(testServCont);
        SVMXC__Service_Contract__c testServCont1 = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont1 = setContractDates(testServCont1, system.today().adddays(-1), system.today().addDays(1));
        lstServCont.add(testServCont1);
        SVMXC__Service_Contract__c testServCont2 = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont2 = setContractDates(testServCont2, system.today().adddays(1), system.today().addDays(2));
        lstServCont.add(testServCont2);
        SVMXC__Service_Contract__c testServCont3 = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont3 = setContractDates(testServCont3, system.today().adddays(-2), system.today().addDays(-1));
        lstServCont.add(testServCont3);
        insert lstServCont;
        Test.starttest();
        ServiceContractsBatchToUpdateStatus testObj = new ServiceContractsBatchToUpdateStatus();      
        String strCron = '0 0 23 * * ?';
        system.schedule('Test Schedule Batch', strCron, testObj);
        testServCont=lstServCont[0];
        testServCont1=lstServCont[1];
        testServCont2=lstServCont[2];
        testServCont3=lstServCont[3];
        system.assertNotEquals(null,testServCont.id);
        system.assertNotEquals(null,testServCont1.id);
        system.assertNotEquals(null,testServCont2.id);
        system.assertNotEquals(null,testServCont3.id);
        Set<Id> serviceContractIds=new Set<id>();
        serviceContractIds.add(testServCont.id);
        serviceContractIds.add(testServCont1.id);
        serviceContractIds.add(testServCont2.id);
        serviceContractIds.add(testServCont3.id);
        for(SVMXC__Service_Contract__c objServ: [select id, Status__c from SVMXC__Service_Contract__c where id IN: serviceContractIds]){
            if(objServ.id==testServCont.id){
                system.assertEquals('Expired',objServ.Status__c);
            }
            else if(objServ.id==testServCont1.id){
                system.assertEquals('Active',objServ.Status__c);
            }else if(objServ.id==testServCont2.id){
                system.assertEquals('Pending Activation',objServ.Status__c);
            }else if(objServ.id==testServCont3.id){
                system.assertEquals('Expired',objServ.Status__c);
            }
        }
        test.stoptest();
    }
    
    private static SVMXC__Service_Contract__c setContractDates(SVMXC__Service_Contract__c objServCont, date dtStartDate, date dtEndDate){
        objServCont.SVMXC__Start_Date__c = dtStartDate;
        objServCont.SVMXC__End_Date__c = dtEndDate;
        return objServCont;
    }
	static testMethod void createPMOffering(){
        Account objAccount = TestDataAccount.getNewAccount();
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        List<SVMXC__Service_Plan__c> lstSP = new List<SVMXC__Service_Plan__c>();
        SVMXC__Service_Plan__c sp1 = new SVMXC__Service_Plan__c();
        sp1.Name = 'Test1';
        sp1.Item_Number__c = '1111';
        lstSP.add(sp1);
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = '1111';
        lstSP.add(sp);
        insert lstSP;
		SVMXC__PM_Plan_Template__c pmTemplate = new SVMXC__PM_Plan_Template__c();
		pmTemplate.Name='Test PM Template';
		pmTemplate.CurrencyIsoCode='USD';
		insert pmTemplate;
        List<SVMXC__PM_Offering__c> lstPMOfferingsInsert = new List<SVMXC__PM_Offering__c>();
		SVMXC__PM_Offering__c pm = new SVMXC__PM_Offering__c();
		pm.SVMXC__Service_Plan__c=lstSP[1].id;
		pm.SVMXC__PM_Plan_Template__c=pmTemplate.id;
        lstPMOfferingsInsert.add(pm);
        SVMXC__PM_Offering__c pm1 = new SVMXC__PM_Offering__c();
		pm1.SVMXC__Service_Plan__c=lstSP[1].id;
		pm1.SVMXC__PM_Plan_Template__c=pmTemplate.id;
		 lstPMOfferingsInsert.add(pm1);
        SVMXC__PM_Offering__c pm2 = new SVMXC__PM_Offering__c();
		pm2.SVMXC__Service_Plan__c=lstSP[0].id;
		pm2.SVMXC__PM_Plan_Template__c=pmTemplate.id;
        lstPMOfferingsInsert.add(pm2);
        SVMXC__PM_Offering__c pm3 = new SVMXC__PM_Offering__c();
		pm3.SVMXC__Service_Plan__c=lstSP[0].id;
		pm3.SVMXC__PM_Plan_Template__c=pmTemplate.id;
		 lstPMOfferingsInsert.add(pm3);
        insert lstPMOfferingsInsert;
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(objAccount.Id);
        testServCont.SVMXC__Service_Plan__c = lstSP[1].id;
        testServCont = setContractDates(testServCont, system.today(), system.today().addYears(1));
        insert testServCont;
        List<SVMXC__PM_Plan__c> lstPMPlan = new List<SVMXC__PM_Plan__c>();
        SVMXC__PM_Plan__c pmPlan = new SVMXC__PM_Plan__c();
        pmPlan.Name='Test PM';
        pmPlan.CurrencyIsoCode='USD';
        pmPlan.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan.SVMXC__Service_Contract__c= testServCont.Id;
        lstPMPlan.add(pmPlan);
         SVMXC__PM_Plan__c pmPlan1 = new SVMXC__PM_Plan__c();
        pmPlan1.Name='Test PM1';
        pmPlan1.CurrencyIsoCode='USD';
        pmPlan1.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan1.SVMXC__Service_Contract__c= testServCont.Id;
        lstPMPlan.add(pmPlan1);
        insert lstPMPlan;
       
         test.starttest();
		List<SVMXC__PM_Offering__c> lstPMOfferings =[select id from SVMXC__PM_Offering__c where SVMXC__Service_Contract__c= :testServCont.id];
		System.assertEquals(2,lstPMOfferings.size());
         SVMXC__Service_Contract__c testServContUpdate = new SVMXC__Service_Contract__c(Id=testServCont.Id);
       testServContUpdate.SVMXC__Active__c= true;
        testServContUpdate.SVMXC__Service_Plan__c=sp1.Id;
        update testServContUpdate;
        
        test.stoptest();
    }	
	    
     /**
    *  @author Digvijay Singh
    *  @description - Covers the "updateInstrumentonPMWorkOrders" method in CoveredProducts Class.
    **/  
  static testmethod void testupdaterelatedPMWorkOrder(){
  
    Product2 workOrderProduct = TestDataMaster.initProduct('Test');
     insert workOrderProduct;
     
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
    testServicePlan.OQ_Required__c = false;
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
    
    SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', null, 'In Progress');
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
    
     /*SVMXC__Service_Order_Line__c objOrderDetailPart2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder2.Id,'Usage/Consumption');
    objOrderDetailPart2.SVMXC__Product__c = workOrderProduct.Id;
    objOrderDetailPart2.SVMXC__Actual_Quantity2__c = 1;
    objOrderDetailPart2.SVMXC__Line_Type__c = 'Material Consumed';
    insert objOrderDetailPart2;*/
    Test.StartTest();
    /*testServCont.Status__c ='Canceled';
    update testServCont; */
    
    List<SVMXC__Service_Order__c> lstWO=[Select id ,SVMXC__Order_Status__c, SVMXC__Component__c from SVMXC__Service_Order__c  where id=:workOrder2.id];
    /* System.assertEquals(lstWO[0].SVMXC__Order_Status__c, Label.WorkOrderStatusCanceled); */
    Test.StopTest();
    
    
        
        
 }
     /**
    *  @author Naomi Thammadi
    *  @description tests change of status of Blocked and Active Contracts
    **/  
    static testmethod void testBlockedandActiveContracts(){
        
        Product2 workOrderProduct = TestDataMaster.initProduct('Test');
        insert workOrderProduct;
        
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
        testServicePlan.OQ_Required__c = false;
        insert testServicePlan;
        
        //service contract
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(acc.Id);
        testServCont.SVMXC__Service_Plan__c = testServicePlan.id;
        testServCont.SVMXC__Start_Date__c = system.today().addDays(-2);
        testServCont.SVMXC__End_Date__c = system.today().addYears(1);
        insert testServCont;
        
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = testServCont.Id;
        insert cp;
        
        testServCont.SVMXC__Active__c = true;
        update testServCont;
        
        //SVMXC__PM_Plan__c
        SVMXC__PM_Plan__c pmPlan = new SVMXC__PM_Plan__c();
        pmPlan.Name='BYANNUAL Plan';
        pmPlan.CurrencyIsoCode='USD';
        pmPlan.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan.SVMXC__Service_Contract__c= testServCont.Id;
        pmPlan.SVMXC__Status__c= 'Incomplete';
        insert pmPlan;
        
        Test.StartTest();
        testServCont.Status__c ='Blocked';
        update testServCont;
        List<SVMXC__PM_Plan__c> pmPlans = new List<SVMXC__PM_Plan__c>();
        pmPlans=new PreventiveMaintenancePlansSelector().selectPMPlanForSMC(new Set<Id>{testServCont.id});
        system.assertEquals(1,pmPlans.size());
        testServCont.Status__c ='Active';
        update testServCont;
        Test.StopTest();
        pmPlans = new List<SVMXC__PM_Plan__c>();
        pmPlans=new PreventiveMaintenancePlansSelector().selectPMPlanForSMC(new Set<Id>{testServCont.id});
        system.assert(pmPlans.size()>0);
    }
}
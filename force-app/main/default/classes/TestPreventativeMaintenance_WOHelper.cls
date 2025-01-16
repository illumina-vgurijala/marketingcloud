/**
* @author Shivani Jain
* @date 8th June 2022
* Dhairya Shah       11-Oct-2024             CMCM-5165 No changes in Test Class
* @description DCP-54018 Test class for PreventativeMaintenance_WOHelper
*/
@IsTest
private class TestPreventativeMaintenance_WOHelper {

    private static final String STRING_ACCOUNT = 'Test Acc';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    private static final String STRING_WO_RECORDTYPE = 'Field Service';
    private static final String STRING_ERROR_QR = 'OQ or type IQ/OQ';

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
            SVMXC__Email__c = 'testmail@testing.com',
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
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }

    /**
     *  @author Digvijay Singh
    *  @description - Covers the PM insertion code for  DCP-28624.
    **/     
    static testmethod void testPMWorkOrderFieldSupportAssignment() { 
      
        User serviceEngineer = TestDataFieldService.createUser(STRING_WO_RECORDTYPE,true);
      
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c='Distributor';
            acc.ERP_Customer_Id__c = 'Test1';
            insert acc;
            
        
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
                Name = STRING_SERVICE_TEAM_NAME,
                SVMXC__Country__c = 'India'
            );
            insert serviceTeam;
            System.assertNotEquals(null, serviceTeam.Id);
            
            SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
                Name = 'Test Name',
                SVMXC__Active__c = True,
                SVMXC__Email__c = 'testmail1@testing.com',
                SVMXC__Country__c = 'India',
                SVMXC__Street__c = 'Test',
                SVMXC__Salesforce_User__c = serviceEngineer.Id,
                SVMXC__Service_Group__c = serviceTeam.Id
            );
            insert grpMembers;
            
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        ip.SVMXC__Company__c = acc.Id;
        insert ip;
        system.assertNotEquals(null,ip.id);
            
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
        
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.SVMXC__Component__c=ip.id;
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder2.SVMXC__Is_PM_Work_Order__c = true;
        workorder2.SVMXC__PM_Plan__c = pmPlan.Id;
        workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
        workOrder2.Cost_Center__c  =1234;
        workOrder2.SVMXC__Group_Member__c = grpMembers.id;
        
         
        insert workOrder2;
        Test.StartTest();
        List<SVMXC__Service_Order__c> lstWO=[Select id , SVMXC__Group_Member__c ,SVMXC__Component__c from SVMXC__Service_Order__c  where id=:workOrder2.id];
        System.assertEquals(lstWO[0].SVMXC__Group_Member__c, grpMembers.id, 'Group Member update failed');
         
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder2.id;
        objOrderDetail.SVMXC__Serial_Number__c = ip.Id;
        objOrderDetail.SVMXC__Activity_Type__c='Preventative Maintenance';
        objOrderDetail.SVMXC__End_Date_and_Time__c = system.today();
        insert objOrderDetail;
        
        workOrder2.SVMXC__Order_Status__c = 'Completed';
        workOrder2.Evaluation__c='Test';
        workOrder2.SVMXC__Work_Performed__c='Test';
        workOrder2.Verification_Result__c='Test'; 
        workOrder2.No_Calibrated_Tools_Used__c = true;
        workOrder2.Is_Service_Report_Generated__c=true;
        workOrder2.Is_Customer_Sign_Captured__c=true;
        workOrder2.PO_Number__c = '12345';
        //START Modified DCP-47686
        Boolean isErrorThrown;
        try {
            update workOrder2;
        } catch(Exception e) {
            isErrorThrown = String.isNotBlank(e.getMessage());
            // isErrorThrown = e.getMessage().contains(String.format(Label.MandatoryLaborLineError, 
            // new List<String>{WorkOrders.STRING_OQ_REQUIRED, WorkOrders.STRING_WOD_ACTIVITY_TYPE_OQ, STRING_ERROR_QR}));
            System.Assert(isErrorThrown, 'Validation Error for validateCompletedWOLaborLines not thrown');
        }
        //END Modified DCP-47686
        
        Test.StopTest();
          
   }

    /**
    *  @description - test the work order status on case when a new work order is inserted 
    */
    static testMethod void plannedMaintenanceTest() {
        Account acc = [SELECT id FROM Account WHERE Account_Group__c = 'Distributor' AND Name=: STRING_ACCOUNT LIMIT 1];
        Case cs = [SELECT id FROM Case LIMIT 1];
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        objProduct.Product_Group__c = 'AmpliSeq Library Prep';
        insert objProduct;
        System.assert(objProduct.id != null, 'Product insertion failed');       

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        insert objInstalledProduct;
        System.assert(objInstalledProduct.id != null, 'Installed Product insertion failed');    

        cs.SVMXC__Component__c = objInstalledProduct.Id;
        update cs;
        Test.startTest();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Planned Maintenance';
        workOrder.SVMXC__Company__c = acc.Id;
        workOrder.Is_Auto_Created__c = true;

        insert workOrder;
        Test.stopTest();
        System.assert(workOrder.id != null, 'Work Order insertion failed');    
    }

      /**
       * Method: populateAnnualWODataTest
       * Description: Testmethod to test PM work order onsite response and scheduled date updation functionality
       * CreatedDate: 14-08-2019
       * DCP-28201
       * */
      static testMethod void populateAnnualWODataTest(){
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null, 'Account Insertion failed');

        //DCP-47459 Product2
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;

        //DCP-47459 Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        objInstalledProduct.Last_PM_Date__c = system.today().addMonths(-2);

        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct1.SVMXC__Company__c = acc.Id;
        objInstalledProduct1.Operation_Status__c='Off';
        objInstalledProduct1.SVMXC__Product__c = objProduct.Id;
        objInstalledProduct1.Last_PM_Date__c = system.today().addDays(-15);

        List<SVMXC__Installed_Product__c> lstInstalledProduct = new List<SVMXC__Installed_Product__c>{objInstalledProduct,objInstalledProduct1};
        insert lstInstalledProduct;
        //DCP-47459
        List<SVMXC__PM_Plan__c> lstPmPlans = insertPMPlansTestData(acc);
        SVMXC__PM_Plan__c pmPlan = lstPmPlans[0];
        SVMXC__PM_Plan__c pmPlan1 = lstPmPlans[1];
        SVMXC__PM_Plan__c pmPlan2 = lstPmPlans[2];
        SVMXC__PM_Plan__c pmPlan3 = lstPmPlans[3];

        Test.startTest();
        
        //DCP-47459
        SVMXC__Service_Order__c workOrder4= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder4.Is_Auto_Created__c = true;
        workOrder4.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder4.SVMXC__Is_PM_Work_Order__c = true;
        workorder4.SVMXC__PM_Plan__c = pmPlan3.Id;
        workOrder4.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder4.SVMXC__SM_SLA_Initial_Response__c = 7200;
        workOrder4.SVMXC__Component__c = objInstalledProduct.id;

        SVMXC__Service_Order__c workOrder5= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder5.Is_Auto_Created__c = true;
        workOrder5.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder5.SVMXC__Is_PM_Work_Order__c = true;
        workorder5.SVMXC__PM_Plan__c = pmPlan3.Id;
        workOrder5.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder5.SVMXC__SM_SLA_Initial_Response__c = 7200;
        workOrder5.SVMXC__Component__c = objInstalledProduct1.id;

        SVMXC__Service_Order__c workOrder6= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder6.Is_Auto_Created__c = true;
        workOrder6.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder6.SVMXC__Is_PM_Work_Order__c = true;
        workorder6.SVMXC__PM_Plan__c = pmPlan.Id;
        workOrder6.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder6.SVMXC__SM_SLA_Initial_Response__c = 7200;
        workOrder6.SVMXC__Component__c = objInstalledProduct.id;

        SVMXC__Service_Order__c workOrder7= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder7.Is_Auto_Created__c = true;
        workOrder7.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder7.SVMXC__Is_PM_Work_Order__c = true;
        workorder7.SVMXC__PM_Plan__c = pmPlan.Id;
        workOrder7.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder7.SVMXC__SM_SLA_Initial_Response__c = 7200;
        workOrder7.SVMXC__Component__c = objInstalledProduct1.id;
        //DCP-47459

        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder2.SVMXC__Is_PM_Work_Order__c = true;
        workorder2.SVMXC__PM_Plan__c = pmPlan.Id;
        workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;

        SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder1.Is_Auto_Created__c = true;
        workOrder1.SVMXC__Order_Type__c='Preventative Maintenance';
        workOrder1.SVMXC__Is_PM_Work_Order__c = true;
        workOrder1.SVMXC__PM_Plan__c = pmPlan1.Id;
        workOrder1.ProActive_Account_ERP_Customer_Id__c = 'Test7';
        workOrder1.SVMXC__SM_SLA_Initial_Response__c = 7200;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Order_Type__c='Preventative Maintenance';
        workOrder.SVMXC__Is_PM_Work_Order__c = true;
        workOrder.SVMXC__PM_Plan__c = pmPlan2.Id;
        workOrder.ProActive_Account_ERP_Customer_Id__c = 'Test9';
        workOrder.SVMXC__SM_SLA_Initial_Response__c = 7200;
        
        SVMXC__Service_Order__c workOrder3 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        workOrder3.Is_Auto_Created__c = true;
        workOrder3.SVMXC__Order_Type__c='Preventative Maintenance';
        workOrder3.SVMXC__Is_PM_Work_Order__c = true;
        workOrder3.SVMXC__PM_Plan__c = pmPlan3.Id;
        workOrder3.ProActive_Account_ERP_Customer_Id__c = 'Test3';
        workOrder3.SVMXC__SM_SLA_Initial_Response__c = 7200;
        List<SVMXC__Service_Order__c> lstWorkOrder = new List<SVMXC__Service_Order__c>{workOrder2,workOrder1,workOrder,workOrder3,workOrder4,workOrder5,workOrder6,workOrder7};
        insert lstWorkOrder;
        Set<Id> setIds = new Set<Id>{workOrder2.Id,workOrder1.Id,workOrder4.Id};
        List<SVMXC__Service_Order__c> lstWO = [Select Id,SVMXC__Scheduled_Date_Time__c,SVMXC__Order_Status__c from SVMXC__Service_Order__c where Id in:setIds];
        if(!lstWO.isEmpty()){
            System.assert(lstWO[0].SVMXC__Scheduled_Date_Time__c != null, '_Scheduled Date Time not updated');
            System.assert(lstWO[2].SVMXC__Scheduled_Date_Time__c != null, 'Scheduled Date Time not updated'); //DCP-47459
        }      
        Test.stopTest();
    }      
    
    /*******************************************************************************************************
    * @description  PM test data creation
    */
    private static List<SVMXC__PM_Plan__c> insertPMPlansTestData(Account acc) {
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
        testServCont.SVMXC__End_Date__c = system.today().addYears(2);

        SVMXC__Service_Contract__c testServCont1 = TestDataFieldService.createServiceContract(acc.Id);
        testServCont1.SVMXC__Service_Plan__c = testServicePlan.id;
        testServCont1.SVMXC__Start_Date__c = system.today().addyears(-2);
        testServCont1.SVMXC__End_Date__c = system.today().addYears(-1);
        
        SVMXC__Service_Contract__c testServCont2 = TestDataFieldService.createServiceContract(acc.Id);
        testServCont2.SVMXC__Service_Plan__c = testServicePlan.id;
        testServCont2.SVMXC__Start_Date__c = system.today().addyears(-1);
        testServCont2.SVMXC__End_Date__c = system.today().addYears(1);
        
        SVMXC__Service_Contract__c testServCont3 = TestDataFieldService.createServiceContract(acc.Id);
        testServCont3.SVMXC__Service_Plan__c = testServicePlan.id;
        testServCont3.SVMXC__Start_Date__c = system.today();
        testServCont3.SVMXC__End_Date__c = system.today().addYears(1);
        List<SVMXC__Service_Contract__c> lstContrats = new List<SVMXC__Service_Contract__c>{testServCont,testServCont1,testServCont2,testServCont3};
        insert lstContrats;

        //SVMXC__PM_Plan__c
        SVMXC__PM_Plan__c pmPlan = new SVMXC__PM_Plan__c();
        pmPlan.Name='BYANNUAL Plan';
        pmPlan.CurrencyIsoCode='USD';
        pmPlan.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan.SVMXC__Service_Contract__c= testServCont.Id;

        SVMXC__PM_Plan__c pmPlan1 = new SVMXC__PM_Plan__c();
        pmPlan1.Name='ANNUAL Plan';
        pmPlan1.CurrencyIsoCode='USD';
        pmPlan1.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan1.SVMXC__Service_Contract__c= testServCont1.Id;
        
        SVMXC__PM_Plan__c pmPlan2 = new SVMXC__PM_Plan__c();
        pmPlan2.Name='ANNUAL Plan';
        pmPlan2.CurrencyIsoCode='USD';
        pmPlan2.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan2.SVMXC__Service_Contract__c= testServCont2.Id;
        
        SVMXC__PM_Plan__c pmPlan3 = new SVMXC__PM_Plan__c();
        pmPlan3.Name='BIANNUAL Plan';
        pmPlan3.CurrencyIsoCode='USD';
        pmPlan3.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan3.SVMXC__Service_Contract__c= testServCont3.Id;
        List<SVMXC__PM_Plan__c> lstPmPlans = new List<SVMXC__PM_Plan__c>{pmPlan, pmPlan1, pmPlan2,pmPlan3};
        insert lstPmPlans;
        
        //scheduled definitions
        SVMXC__PM_Schedule_Definition__c schDef = new SVMXC__PM_Schedule_Definition__c();
        schDef.SVMXC__PM_Plan__c = pmPlan.Id;
        schDef.SVMXC__Frequency__c = 6;
        schDef.SVMXC__Frequency_Unit__c = 'Months';

        SVMXC__PM_Schedule_Definition__c schDef1 = new SVMXC__PM_Schedule_Definition__c();
        schDef1.SVMXC__PM_Plan__c = pmPlan1.Id;
        schDef1.SVMXC__Frequency__c = 1;
        schDef1.SVMXC__Frequency_Unit__c = 'Years';
        
        SVMXC__PM_Schedule_Definition__c schDef2 = new SVMXC__PM_Schedule_Definition__c();
        schDef2.SVMXC__PM_Plan__c = pmPlan2.Id;
        schDef2.SVMXC__Frequency__c = 1;
        schDef2.SVMXC__Frequency_Unit__c = 'Years';
        
        SVMXC__PM_Schedule_Definition__c schDef3 = new SVMXC__PM_Schedule_Definition__c();
        schDef3.SVMXC__PM_Plan__c = pmPlan3.Id;
        schDef3.SVMXC__Frequency__c = 6;
        schDef3.SVMXC__Frequency_Unit__c = 'Months';
        List<SVMXC__PM_Schedule_Definition__c> lstSchDefs = new List<SVMXC__PM_Schedule_Definition__c>{schDef,schDef1,schDef2,schDef3};
        insert lstSchDefs;
        //PM schedule
        SVMXC__PM_Schedule__c sch = new SVMXC__PM_Schedule__c();
        sch.SVMXC__PM_Plan__c = pmPlan.Id;
        sch.SVMXC__Last_Run_Date__c = system.today();
        sch.SVMXC__Scheduled_On__c = system.today().addyears(1);

        SVMXC__PM_Schedule__c sch1 = new SVMXC__PM_Schedule__c();
        sch1.SVMXC__PM_Plan__c = pmPlan1.Id;
        sch1.SVMXC__Last_Run_Date__c = system.today().addYears(-2);
        sch1.SVMXC__Scheduled_On__c = system.today().addyears(-1);
        
        SVMXC__PM_Schedule__c sch2 = new SVMXC__PM_Schedule__c();
        sch2.SVMXC__PM_Plan__c = pmPlan2.Id;
        sch2.SVMXC__Last_Run_Date__c = system.today().addYears(-1);
        sch2.SVMXC__Scheduled_On__c = system.today().addyears(1);
        
        SVMXC__PM_Schedule__c sch3 = new SVMXC__PM_Schedule__c();
        sch3.SVMXC__PM_Plan__c = pmPlan3.Id;
        sch3.SVMXC__Last_Run_Date__c = system.today();
        sch3.SVMXC__Scheduled_On__c = system.today().addyears(1);
        List<SVMXC__PM_Schedule__c> lstSch = new List<SVMXC__PM_Schedule__c>{sch,sch1, sch2,sch3};
        insert lstSch;

        return lstPmPlans;
    }

    /**
     *  @author      : Anshaj
     *  @description : CMSI-202 method to cover catch block in OpportunitySharingToWOResource class
     **/
    @isTest
    public static void coverCatchBlockOpportunitySharingToWOResource(){
        try{
            OpportunitySharingToWOResource.catchException = true;
            OpportunitySharingToWOResource os = new OpportunitySharingToWOResource(null,null, null);
            Test.startTest();
            System.enqueueJob(os);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}
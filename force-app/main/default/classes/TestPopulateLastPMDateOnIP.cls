/*@ author       : Ritika M
* @ date         : 11-MAR-2022
* @ Description  : Test class for PopulateLastPMDateOnIP class
*****************************************************************************************************************************************************
*/
@isTest
public with sharing class TestPopulateLastPMDateOnIP {
   
    public static final String STRING_WO_RECORDTYPE = 'Field Service';     
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_SERVICE_TEAM_NAME = 'Test Team';
    public static final String STRING_ERROR_QR = 'OQ or type IQ/OQ';


    /*
     * @param      : 
     * @return     : void 
     * @Description: Method to test PopulateLastPMDateOnIP
     **/
    static testmethod void testPopulateLastPMDateOnIPMethod() {
        User serviceEngineer = TestDataFieldService.createUser(STRING_WO_RECORDTYPE,true);
    
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c='Distributor';
            acc.ERP_Customer_Id__c = 'Test1';
            acc.Clinical_Type__c = 'Clinical';
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
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = serviceEngineer.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = grpMembers.Id,
            User_Role__c = 'Primary Field Service Engineer'
        );
        
        insert accTechRole1 ;
    
        Contact con = TestDataPerson.getNewContact(null);
        Case  cs = TestDataCase.initServiceRequestCase(con);
        insert cs;


        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        ip.SVMXC__Company__c = acc.Id;
        ip.Last_PM_Date__c = system.today().addMonths(-5);
        insert ip;
        system.assertNotEquals(ip.id,null);
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


        Test.StartTest();    
        insert workOrder2;
        
        List<SVMXC__Service_Order__c> lstWO=[Select id , SVMXC__Group_Member__c ,SVMXC__Component__c from SVMXC__Service_Order__c  where id=:workOrder2.id];
        System.assertEquals(lstWO[0].SVMXC__Group_Member__c, grpMembers.id);
        
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder2.id;
        objOrderDetail.SVMXC__Serial_Number__c = ip.Id;
        objOrderDetail.SVMXC__Activity_Type__c='Preventative Maintenance';
        objOrderDetail.SVMXC__Start_Date_and_Time__c = system.today();
        objOrderDetail.Labor_Hours__c = '02:00';
        
        
        insert objOrderDetail;
    

        List<id> idVar = new List<id>();
        idVar.add(workOrder2.id);
        populateLastPMDateOnIP.doBusinessLogic(idVar);
        Test.getEventBus().deliver();
        ip = [Select id,Last_PM_Date__c from SVMXC__Installed_Product__c where id = :ip.Id];
        system.assertNotEquals(null,ip.Last_PM_Date__c);
        
        Test.StopTest();
    }

}
/***************************************************************************************************************************************
 * NAME   : TestValidateCompletedWO_WOHelper
 * DESCRIPTION  : TestClass to Validate Completed Work Order
 *           DCP-49669 : Validate Elevation Status before closing Work Order
 *    
 * @AUTHOR : Vatsal Shah
 * @DATE   : 28-February-2022  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vatsal Shah            28-February-2022             Initial Version
 */
@isTest
public with sharing class TestValidateCompletedWO_WOHelper {
    
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    public static final String WORKDETAIL_RECORDTYPE = 'Usage/Consumption';
    public static final String STRING_WO_STATUS_IN_PROGRESS = 'In Progress';
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String BUSINESS_ISSUE = 'Business Issue';
    public static final String CURRENCY_USD = 'USD';
    public static final String STRING_ERROR_QR = 'OQ or type IQ/OQ';
    private static final String STRING_SERVICE_TEAM_NAME = 'Test Team';

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
        acc.Clinical_Type__c = 'Clinical';
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
     * Logic to validate the Completion of a WO with Elevation status as Open
     */
    
    static testMethod void verifyWorkOrderStatusTest(){
        try {
            PermissionSet ps = new PermissionSet();
            ps.Name = 'Test';
            ps.Label = 'Test';
            insert ps;
            SetupEntityAccess sea = new SetupEntityAccess();
            sea.ParentId = ps.Id;
            sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'RPS_FSM_FAM'][0].Id;
            insert sea;
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = UserInfo.getUserId();
            psa.PermissionSetId = ps.Id;
            insert psa;
            
            system.runas(new user(Id = userinfo.getUserid())) {
                Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
                acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
                acc.Clinical_Type__c = 'Clinical'; //Dhairya Shah - Changes on -19th April
                insert acc;
                
                //insert contact
                Contact con = TestDataPerson.getNewContact(acc.Id);
                System.assert(con.id != null, 'Contact should not be null');
                
                Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
                
                Case objCase  = new Case(    
                    Status = 'Initiated',
                    Subject = 'test' ,
                    Description= 'test',
                    Origin = 'Phone-CP',
                    Date_of_Issue_Awareness__c=System.today() -2,
                    Awareness_Date_Difference_Reason__c = 'Logistical delay',
                    ContactId = con.Id,
                    RecordTypeId = idCaseRecordTypeId
                );
                insert objCase;
                
                List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
                
                Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
                Id accountElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Account Elevation').getRecordTypeId();  
                
                SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                    SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                                    SVMXC__Order_Status__c from 
                                                    SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
                
                Test.startTest();
                
                Elevations__c techElev = new Elevations__c();
                techElev.RecordTypeId = technicalElevationRecordType;
                techElev.Elevation_Category__c = 'Standard Technical';
                techElev.Elevation_Status__c = 'Open';
                techElev.Elevation_Owner__c = lstUsers[0].Id;
                techElev.Elevation_Manager__c = lstUsers[0].Id;
                techElev.Plan_of_Action__c = 'test';
                techElev.Work_Order__c = workOrder.Id;
                insert techElev;
                
                Elevations__c accElev = new Elevations__c();
                accElev.RecordTypeId = accountElevationRecordType;
                accElev.Elevation_Status__c = 'Open';
                accElev.Elevation_Owner__c = lstUsers[0].Id;
                accElev.Plan_of_Action__c = 'test';
                accElev.Work_Order__c = workOrder.id;
                insert accElev;
                

                workOrder.Technical_Elevation__c = techElev.Id;
                workOrder.Account_Elevation__c = accElev.Id;
                workOrder.No_Calibrated_Tools_Used__c = true;
                workOrder.Signature_Type__c='Manual Sign';
                workOrder.Manual_Sign_Captured__c=true;
                workOrder.Is_Customer_Sign_Captured__c=true;
                workOrder.Cost_Center__c=876765;
                workOrder.SVMXC__Order_Status__c = 'Completed';

                update workOrder;
                        
                Test.stopTest();
            
            }
        }
        catch(Exception e) {
            System.assert(e.getMessage().contains(system.label.Elevation_Work_Order_Validation_Message), 'Word Order should not be associated to Account or Technical Elevation');
        }
    }

    /*******************************************************************************************************
    * @description DCP-47686 : OQ PQ IQ/OQ required: Checkbox instead of Labor Line addition 
    */ 
    static testmethod void testValidateCompletedWOLaborLines() { 
      
        Account acc = [SELECT id from Account where Account_Group__c =: Label.AccountGroupDistributor LIMIT 1];
        SVMXC__Service_Group_Members__c grpMembers = [SELECT id from SVMXC__Service_Group_Members__c LIMIT 1];
        Account_to_Field_Support__c accTechRole1 = new Account_to_Field_Support__c(
              Account__c = acc.Id,
              User__c = grpMembers.Id,
              User_Role__c = Label.Field_Support_User_Role_Primary_FSE
        );
        insert accTechRole1 ;
      
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 
                                            CURRENCY_USD, Label.InstalledProductStatusInstalled);
        ip.SVMXC__Company__c = acc.Id;
        insert ip;
        system.assertNotEquals(null, ip.id);
          
        //pm template
        SVMXC__PM_Plan_Template__c pmTemplate = new SVMXC__PM_Plan_Template__c();
        pmTemplate.Name='Test PM Template';
        pmTemplate.CurrencyIsoCode=CURRENCY_USD;
        insert pmTemplate;
        system.assertNotEquals(null, pmTemplate.id);
          
        //Service Plan
        SVMXC__Service_Plan__c testServicePlan = new SVMXC__Service_Plan__c();
        testServicePlan.Name = 'Test Service Plan';
        testServicePlan.SVMXC__Active__c = true;
        testServicePlan.OQ_Required__c = true;
        insert testServicePlan;
        system.assertNotEquals(null, testServicePlan.id);
        Test.startTest();
        //service contract
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(acc.Id);
        testServCont.SVMXC__Service_Plan__c = testServicePlan.id;
        testServCont.SVMXC__Start_Date__c = system.today();
        testServCont.SVMXC__End_Date__c = system.today().addYears(1);
        insert testServCont;
        system.assertNotEquals(null, testServCont.id);

        //SVMXC__PM_Plan__c
        SVMXC__PM_Plan__c pmPlan = new SVMXC__PM_Plan__c();
        pmPlan.Name='BYANNUAL Plan';
        pmPlan.CurrencyIsoCode='USD';
        pmPlan.SVMXC__PM_Plan_Template__c=pmTemplate.Id;
        pmPlan.SVMXC__Service_Contract__c= testServCont.Id;
        insert pmPlan;
        system.assertNotEquals(null, pmPlan.id);
      
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = testServCont.Id;
        insert cp;
        system.assertNotEquals(null, cp.id);

        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, Label.WorkOrderStatusInitiated);
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.SVMXC__Component__c=ip.id;
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.SVMXC__Order_Type__c=Label.WorkOrderTypePreventativeMaintenance;
        workorder2.SVMXC__Is_PM_Work_Order__c = true;
        workorder2.SVMXC__PM_Plan__c = pmPlan.Id;
        workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
        workOrder2.Cost_Center__c  =1234;
        insert workOrder2;
        system.assertNotEquals(null, workOrder2.id);

        //Test.startTest();
        List<SVMXC__Service_Order__c> lstWO=[Select id , SVMXC__Group_Member__c ,SVMXC__Component__c, Qualification_Requirements__c from SVMXC__Service_Order__c  where id=:workOrder2.id];
        System.assertEquals(lstWO[0].Qualification_Requirements__c , WorkOrders.STRING_OQ_REQUIRED, 'Qualification Requirements field not populated');

        List<SVMXC__Service_Order_Line__c> laborLines = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c oqLaborLine = new SVMXC__Service_Order_Line__c();
        oqLaborLine.SVMXC__Service_Order__c = workOrder2.id;
        oqLaborLine.SVMXC__Activity_Type__c = WorkOrders.STRING_WOD_ACTIVITY_TYPE_OQ;
        oqLaborLine.SVMXC__Line_Status__c = Label.WorkDetailLineStatusOpen;
        oqLaborLine.SVMXC__Line_Type__c = Label.Labor;
        oqLaborLine.Labor_Hours__c = '1';
        oqLaborLine.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WORKDETAIL_RECORDTYPE).getRecordTypeId();
        oqLaborLine.Include_in_Service_Report__c = true;
        oqLaborLine.Work_Order_Type__c = Label.WorkOrderTypePreventativeMaintenance;
        laborLines.add(oqLaborLine);

        SVMXC__Service_Order_Line__c iqoqLaborLine = new SVMXC__Service_Order_Line__c();
        iqoqLaborLine.SVMXC__Service_Order__c = workOrder2.id;
        iqoqLaborLine.SVMXC__Activity_Type__c = WorkOrders.STRING_WOD_ACTIVITY_TYPE_IQ_OQ;
        iqoqLaborLine.SVMXC__Line_Status__c = Label.WorkDetailLineStatusOpen;
        iqoqLaborLine.SVMXC__Line_Type__c = Label.Labor;
        iqoqLaborLine.Labor_Hours__c = '1';
        iqoqLaborLine.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WORKDETAIL_RECORDTYPE).getRecordTypeId();
        iqoqLaborLine.Include_in_Service_Report__c = true;
        iqoqLaborLine.Work_Order_Type__c = Label.WorkOrderTypePreventativeMaintenance;
        laborLines.add(iqoqLaborLine);

        SVMXC__Service_Order_Line__c pmLaborLine = new SVMXC__Service_Order_Line__c();
        pmLaborLine.SVMXC__Service_Order__c = workOrder2.id;
        pmLaborLine.SVMXC__Activity_Type__c = Label.WorkOrderTypePreventativeMaintenance;
        pmLaborLine.SVMXC__Serial_Number__c = ip.Id;
        pmLaborLine.SVMXC__End_Date_and_Time__c = system.today();
        laborLines.add(pmLaborLine);

        
 
        insert laborLines;
        system.assertNotEquals(null, oqLaborLine.id);
        Test.StopTest();
        workOrder2.SVMXC__Order_Status__c = Label.WorkOrderStatusCompleted;
        workOrder2.Evaluation__c='Test';
        workOrder2.Has_Resolution_Code__c = true;
        workOrder2.SVMXC__Work_Performed__c='Test';
        workOrder2.Verification_Result__c='Test'; 
        workOrder2.No_Calibrated_Tools_Used__c = true;
        workOrder2.Is_Service_Report_Generated__c=true;
        workOrder2.Is_Customer_Sign_Captured__c=true;
        workOrder2.PO_Number__c = '12345';

        update workOrder2;
          
    }

    /**
     *  @author Digvijay Singh
    *  @description - Covers the PM insertion code for  DCP-28624.
    **/    
      
    static testmethod void testPMWorkOrderFieldSupportAssignment(){
      
        User serviceEngineer = TestDataFieldService.createUser(STRING_WO_RECORDTYPE,true);
      
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Clinical_Type__c = 'Clinical';
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
                SVMXC__Email__c = 'testmail01@testing.com',
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
        TestServicePlan.Name = 'Test Service Plan';
        TestServicePlan.SVMXC__Active__c = true;
        TestServicePlan.OQ_Required__c = true;
        insert TestServicePlan;
        
        //service contract
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(acc.Id);
        testServCont.SVMXC__Service_Plan__c = TestServicePlan.id;
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
        System.assertEquals(lstWO[0].SVMXC__Group_Member__c, grpMembers.id, 'Diff Id');
         
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder2.id;
        objOrderDetail.SVMXC__Serial_Number__c = ip.Id;
        objOrderDetail.SVMXC__Activity_Type__c='Preventative Maintenance';
        objOrderDetail.SVMXC__End_Date_and_Time__c = system.today();
        insert objOrderDetail;
        
        //workOrder2.SVMXC__Order_Status__c = 'Completed';
        workOrder2.SVMXC__Order_Status__c = 'Initiated';  //Dhairya Shah - Changes on -24th April
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
            // System.Assert(e.getMessage().contains(String.format(Label.MandatoryLaborLineError, 
            // new List<String>{WorkOrders.STRING_OQ_REQUIRED, WorkOrders.STRING_WOD_ACTIVITY_TYPE_OQ, STRING_ERROR_QR})), 'Validation Error for validateCompletedWOLaborLines not thrown');
        }
        if(isErrorThrown!=null){
            System.Assert(isErrorThrown, 'Validation Error for validateCompletedWOLaborLines not thrown');
        }
        //END Modified DCP-47686        
        Test.StopTest();
          
   }
    
/*******************************************************************************************************
    * @description CMCM-1355 : Test Method for validateInstalledProductStatus  
    */ 
    static testmethod void testvalidateInstalledProductStatus(){
        
        User usr = [SELECT Id, IsActive FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Customer Service') AND IsActive = True LIMIT 1];
       
        Account acc1 = [SELECT id from Account where Account_Group__c =: Label.AccountGroupDistributor LIMIT 1];
        
        SVMXC__Installed_Product__c ip = New SVMXC__Installed_Product__c();
        ip.Name = 'Test Installed Product 1';
        ip.SVMXC__Status__c = 'Awaiting Installation';
        Insert ip;
        
        system.runas(usr) {
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'In Progress');
           if(workOrder2.SVMXC__Company__c == null){
        workOrder2.SVMXC__Company__c=acc1.id;
        workOrder2.SVMXC__Component__c=ip.id;
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.SVMXC__Order_Type__c=System.Label.WorkOrderTypeTradeinEOL;
        
           }
        insert workOrder2;
        
        workOrder2.SVMXC__Order_Status__c = 'Completed';
        workOrder2.Evaluation__c='Test';
        workOrder2.SVMXC__Work_Performed__c='Test';
        workOrder2.Verification_Result__c='Test'; 
        workOrder2.No_Calibrated_Tools_Used__c = true;
        workOrder2.Is_Service_Report_Generated__c=true;
        workOrder2.Is_Customer_Sign_Captured__c=true;
        workOrder2.PO_Number__c = '12345';
        
        Test.StartTest();
            try{
        update workOrder2;
         Test.StopTest();
            }
                    
            catch (Exception e) {
            System.assert(e.getMessage().contains(system.label.WorkOrderIPStatusValidation), 'Work Order cannot be completed without updating Installed Product Page status. Update the related Installed Product Page Status to Scrapped, Returned, or Decommissioned.');
        
            }
        }
    } 
}
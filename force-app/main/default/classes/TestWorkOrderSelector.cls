/*@ author       : Digvijay
* @ date         : 12-04-2019
* @ Description  : Test class for WorkOrderSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Digvijay          12-04-2019                        US-24628            Initial version
* Shivani           16-Sep-2021                       DCP-47698           Sync Acceptance Code to Install Work Order 
* Rohan             23-Mar-2022                      DCP-49682           Remove elevation 1.0 methods
* Dhairya           21/8/24    CMCM-2180
*/

@IsTest(SeeAllData=false)
global with sharing class TestWorkOrderSelector{

   
    Static testMethod void testmethodWorkOrderSelector(){   
            Account ac =TestDataAccount.initAccount();
            ac.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
            insert ac;
            Contact con =TestDataContact.getNewContact(ac); 
            // String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
           
            /*Case objCase  = new Case(
                
                Status = 'Initiated',
                Subject = dateString ,
                Description= dateString,
                Origin = 'Phone-CP',
                Date_of_Issue_Awareness__c=System.today() -2,
                ContactId = con.Id,
                RecordTypeId = idCaseRecordTypeId
            );
            
            insert objCase  ;*/
            /*Case objCase = TestDataCase.initServiceRequestCase(con);
            objCase.Subject = 'test123';
             objCase.Description='test123';
                 objCase.Origin = 'Phone-CP';
                objCase.Date_of_Issue_Awareness__c=System.today() -3;
                objCase.RecordTypeId = idCaseRecordTypeId;
            insert objCase;*/
            SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
            insert objLocationRec;
            List<Product2> lstProducts1 = new List<Product2>();
            Product2 objProduct = TestDataMaster.initProduct('1241527');
            objProduct.Service_Product_Type__c = 'Core';
            objProduct.Source_System__c='SAP';
            lstProducts1.add(objProduct);
            insert lstProducts1;

            cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId()); 
            setting.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
            upsert setting; 

            //Added by dhairya shah for CMCM 2180 code coverage
            User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
            );
            insert u;

            Opportunity opp1 = TestDataOpportunity.initOpportunity(ac);
            opp1.Name = 'Test Opp 1';
            opp1.OwnerId = u.Id; 
            insert opp1;

            SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'Active');
            objInstalledProduct.SVMXC__Company__c= ac.Id;
            objInstalledProduct.SVMXC__Product__c=lstProducts1[0].Id;
            insert objInstalledProduct;
            Case objCase = new Case(
            ContactId = con.Id,
            Sub_Type__c = 'Complaint',
            AccountId = ac.Id,
            Status = 'In Progress',
            Origin = 'Phone - CP',
            Subject = 'test',
            Priority = 'Medium',
            Description = 'test',
            CurrencyIsoCode = 'USD',
            SVMXC__Component__c = objInstalledProduct.id,
            Category__c = 'Clinical',
            RecordTypeId = idCaseRecordTypeId,
            Date_of_Issue_Awareness__c = Date.newInstance(2019,05,24),
            Awareness_Date_Difference_Reason__c = 'Logistical delay'
            );
            insert objCase;
            objCase.ETQ_Integration_Status__c='Success';
            update objCase;
            //objCase.Status ='Completed';
            objCase.Record_Updated_from_SFM__c=true;
            objCase.PAE_PFA_Evaluation_Required__c='Yes';
            objCase.pAE_pFA_Awareness_Date__c=Date.newInstance(2019,06,21);
            objCase.Question_1__c = 'Did the issue involve a death or serious injury to either the patient or the operator?';
            objCase.Answer_1__c= 'No';
            objCase.Question_2__c = 'Could the issue cause a death or serious injury if it were to recur?';
            objCase.Answer_2__c= 'Yes';
            objCase.Question_3__c = 'Has the customer submitted a Medical Device Report to the FDA or has the customer reported the issue to other regulatory agencies for Illumina’s regulated products?';
            objCase.Answer_3__c= 'Yes';
            objCase.Question_4__c = 'Did the device fail to perform as intended? For example, did the device failure result in a discrepant result or a mix up of patient data?';
            objCase.Answer_4__c= 'Yes';
            objCase.Question_5__c = 'Did the reported issue suggest a potential nonconforming product? For example is the product mislabeled, incorrectly packaged, or no longer meeting package insert specifications?';
            objCase.Answer_5__c= 'No';
            objCase.pAE_pFA_Awareness_Date_Difference_Reason__c = 'Updated information presented by customer';
            update objCase;
            /* DCP-51725 Start */
            Set<Id> setAccountIds = new  Set<Id>();
            setAccountIds.add(ac.Id);
            new WorkOrdersSelector().selectElevatedWorkOrdersOnAccount(setAccountIds);
              /* DCP-51725 End  */
            // Insert Work Order
            SVMXC__Service_Order__c objWorkOrder  = [Select id,OwnerID ,SVMXC__Order_Type__c,SVMXC__Site__c,Name from SVMXC__Service_Order__c where SVMXC__Case__c=: objCase.Id];
            objWorkOrder.SVMXC__Site__c=objLocationRec.id;
            objWorkOrder.LOA_Signed_and_Attached__c = true;
            objWorkOrder.Acceptance_Status__c = 'Completed';
            objWorkOrder.ERP_Order_Number__c = '123456';
            objWorkOrder.SVMXC__Order_Type__c = 'Depot Repair';
            objWorkOrder.Acceptance_Forecast_in_Current_Quarter__c = '0% - Instrument DOA';
            objWorkOrder.Abandoned_Reason__c = 'No Customer Response';
            objWorkOrder.Applied_Service_Contract__c = '12345678';
            objWorkOrder.ERP_Order_Line_Number__c = '1111';
            objWorkOrder.Additional_Detail__c = 'test details';//added by Dhairya Shah for CMCM 2180 for code coverage
            Test.StartTest();
            update objWorkOrder;
            Set<Id> locationIdSet= new Set<Id>();
            locationIdSet.add(objWorkOrder.SVMXC__Site__c);

            Set<String> setCaseId=new Set<String>();
            setCaseId.add(objCase.id);
            Set<Id> setCaseIds=new Set<Id>();
            setCaseIds.add(objCase.id);
            Set<Id> setWOId=new Set<Id>();
            setWOId.add(objWorkOrder.id);
            Set<String> setWOIdString=new Set<String>();
            setWOId.add(objWorkOrder.id);
            
            
            
            WorkOrdersSelector woSelectorObj=new WorkOrdersSelector();
            SVMXC__Service_Order__c wo =woSelectorObj.selectNumberOfPartsAndToolsForWorkOrder(objWorkOrder.id);
			system.assertEquals(objWorkOrder.id,wo.Id,'Work Order Id does not match');
            List<SVMXC__Service_Order__c> lstwo = woSelectorObj.selectWorkOrderIdOnCaseNumber(setCaseId);
			System.assertEquals(0,lstwo.size());
            List<SVMXC__Service_Order__c> lstwo1 = woSelectorObj.selectWorkOrdersForAppropriateStatus(setWOId,'Initiated');
			system.assertEquals(0,lstwo1.size());
            List<SVMXC__Service_Order__c> lstwo2 =  woSelectorObj.selectWOIntegrationStatusNotSuccess(new Set<String> {'Success'}, setCaseIds);
            system.assertEquals(1,lstwo2.size());
			woSelectorObj.selectRelatedWorkOrderWithFieldSupport(setWOId);
            woSelectorObj.workOrdersWithShipmentPartsOrder(setWOId);
            woSelectorObj.selectWorkOrderWithRelatedWorkOrder(setWOId);
            woSelectorObj.selectWorkOrderLstFromStringIds(setWOIdString);            
            woSelectorObj.selectReopenRequestedWOForCases(setCaseIds);
            woSelectorObj.selectOpenWorkOrders(setCaseIds);
            woSelectorObj.selectWorkOrdersNotClosedDuplicateOnCase(setCaseIds);
            woSelectorObj.selectWorkOrderAndCaseInfo(new set<id>{objWorkOrder.id});
            woSelectorObj.selectWorkOrderLstFromIds(new set<id>{objWorkOrder.id},setCaseIds);
            woSelectorObj.selectOpenWorkOrdersFromIP(new set<id>{objInstalledProduct.id});
            woSelectorObj.selectWorkOrdersForOrderLineNumber(setWOIdString);
            woSelectorObj.selectWorkOrdersForOrderLineNumberWithBlankIP(setWOIdString);
            woSelectorObj.workOrderWithPartsOrder(new set<id>{objWorkOrder.id},userInfo.getUserId(),'123');
            woSelectorObj.selectWorkOrdersServiceReportGenerationStatus(new set<id>{objWorkOrder.id});
            woSelectorObj.selectWorkOrderWithWorkDetails(new set<id>{objWorkOrder.id});
            List<SVMXC__Service_Order__c> lstwo3 = woSelectorObj.selectWorkOrders(setWOId);
            system.assertEquals(1,lstwo3.size());
			woSelectorObj.selectWorkOrdersForAppropriateTypeAndIP(new set<id>{objInstalledProduct.id},objWorkOrder.SVMXC__Order_Type__c);
            woSelectorObj.selectWorkOrdersMatchingAccount(new set<id>{ac.id});
            List<SVMXC__Service_Order__c> lstwo4 = woSelectorObj.selectWorkOrdersFromIds(setWOId);
            system.assertEquals(1,lstwo4.size());
			woSelectorObj.selectWorkOrderLstFromIds(setWOId);
			woSelectorObj.selectWorkOrderLstFromIds(objWorkOrder.Id);// Added as part of DCP-44003
			woSelectorObj.selectWorkOrderByIDAndStatus(setWOId);//Added as part of DCP-44003
            List<SVMXC__Service_Order__c> lstWo5 = woSelectorObj.selectCycleCountWorkOrderforSpanshot(locationIdSet);
            system.assertEquals(0,lstwo5.size());
            List<SVMXC__Service_Order__c> lstWo7 = woSelectorObj.selectWorkOrders(setWOId, setCaseIds, 'Awaiting Customer');
            system.assertEquals(0,lstWo7.size());
            List<SVMXC__Service_Order__c> lstWo8 = woSelectorObj.selectOpenWorkOrdersFromIds(setWOId);
            system.assertEquals(1,lstWo8.size());
            List<SVMXC__Service_Order__c> lstWo9 = woSelectorObj.selectWOWithSameERPOrderAndERPOrderLineNum(new Set<String>{'123456'}, new Set<String>{'1111'});
            system.assertEquals(0,lstWo9.size());
            //added by Dhairya Shah for CMCM 2180 for code coverage
            List<SVMXC__Service_Order__c> lstWo10 = woSelectorObj.selectWOMatchingProductERPOrderNumberAndERPOrderLineNumber(new set<id>{lstProducts1[0].Id},new Set<String>{'123456'}, new Set<String>{'1111'},new Set<String>{'Depot Repair'});
            system.assertEquals(1,lstWo10.size());
            //added by Dhairya Shah for CMCM 2180 for code coverage
            List<SVMXC__Service_Order__c> lstWo12 = woSelectorObj.selectWorkOrdersFromOpportunities(new set<id>{opp1.id});
            system.assertEquals(0,lstWo12.size());
            Test.StopTest();
            List<SVMXC__Service_Order__c> lstWo6 = woSelectorObj.selectWOByName(objWorkOrder.Name);
            system.assertEquals(1,lstwo6.size());
            
            woSelectorObj.getAccountToFieldSupportWorkOrders(objWorkOrder.Id);
            
            woSelectorObj.selectWorkOrdertoKnowCompletionDate(objWorkOrder.Id);

            woSelectorObj.selectWorkOrderWithRecordType(setWOId);

            //woSelectorObj.selectWorkOrdersWithNoSLA(setWOId);

            woSelectorObj.selectWorkOrdersWithoutCasesFromIds(setWOId);

            woSelectorObj.getFieldSupportWorkOrders(objWorkOrder.Id);

            
    }
    
    /**
     * DCP-28201
     * Description: method to test retrieving work orders based on PM Plans
     **/
    static testMethod void testPopulateAnnualWOData(){
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != null);
        User serviceEngineer = TestDataFieldService.createUser('Field Service Logistics',false);

        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
        objLocation.SVMXC__Service_Engineer__c = serviceEngineer.Id;
        insert objLocation;
        //pm template
        SVMXC__PM_Plan_Template__c pmTemplate = new SVMXC__PM_Plan_Template__c();
        pmTemplate.Name='Test PM Template';
        pmTemplate.CurrencyIsoCode='USD';
        insert pmTemplate;
        //service contract
        SVMXC__Service_Contract__c testServCont = TestDataFieldService.createServiceContract(acc.Id);
        //testServCont.SVMXC__Service_Plan__c = lstSP[1].id;
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

        //scheduled definitions
        SVMXC__PM_Schedule_Definition__c schDef = new SVMXC__PM_Schedule_Definition__c();
        schDef.SVMXC__PM_Plan__c = pmPlan.Id;
        schDef.SVMXC__Frequency__c = 26;
        schDef.SVMXC__Frequency_Unit__c = 'Weeks';
        insert schDef;
        Test.startTest();
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.SVMXC__Order_Type__c='Preventative Maintenance';
        workorder2.SVMXC__Is_PM_Work_Order__c = true;
        workorder2.SVMXC__PM_Plan__c = pmPlan.Id;
        workOrder2.ProActive_Account_ERP_Customer_Id__c = 'Test2';
        workOrder2.SVMXC__SM_SLA_Initial_Response__c = 7200;
        workOrder2.SVMXC__Site__c = objLocation.Id;
        insert workOrder2;
        List<SVMXC__Service_Order__c> lstWO = new WorkOrdersSelector().selectWorkOrderForPMPlans(new Set<Id>{pmPlan.Id});
        System.assertEquals(1,lstWO.size());

        List<SVMXC__Service_Order__c> lstWO1 = new WorkOrdersSelector().selectAssociatedWorkOrderForPMPlans(new Set<Id>{pmPlan.Id});    
        System.assert(lstWO1.size() > 0);     
        Test.stopTest();
    }
/**
      * Prashanth
     * Description: method to test retriving of work order of type Installation
     **/
    static testMethod void testSelectWorkOrdersForIP(){

        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId()); 
        setting.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
        upsert setting; 
       
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        List<Product2> lstProducts1 = new List<Product2>();
        Product2 objProduct = TestDataMaster.initProduct('1241527');
        objProduct.Service_Product_Type__c = 'Core';
        objProduct.Source_System__c='SAP';
        lstProducts1.add(objProduct);
        insert lstProducts1;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'Active');
        objInstalledProduct.SVMXC__Company__c= acc.Id;
        objInstalledProduct.SVMXC__Product__c=lstProducts1[0].Id;
        insert objInstalledProduct;
        Set<Id> setInstalledProduct= new Set<Id>();
        setInstalledProduct.add(objInstalledProduct.id);
        
         //insert case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.SVMXC__Component__c = objInstalledProduct.id;
        insert cs;
        System.assert(cs.Id != null);
        
        Test.startTest();
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Applied_Service_Contract__c=null;
        workOrder2.Is_Auto_Created__c = true;
        workOrder2.SVMXC__Order_Type__c='Installation';
        workOrder2.Acceptance_Status__c='Completed';
        workOrder2.LOA_Signed_and_Attached__c=true;
        workOrder2.Acceptance_Forecast_in_Current_Quarter__c='100% Completed - LOA Signed';
        insert workOrder2;
        
        Set<Id> setworkOrder2 = new Set<Id>{workOrder2.Id};
        //Set<Id> setCS = new Set<Id>{cs.Id};
            
        List<SVMXC__Service_Order__c> lstWO = new WorkOrdersSelector().selectWorkOrdersForIP(setInstalledProduct);
        System.assert(lstWO.size() > 0); 
        
        List<SVMXC__Service_Order__c> lstWO1 = new WorkOrdersSelector().selectWorkOrderId(setworkOrder2);
        System.assert(lstWO1.size() > 0);
        List<SVMXC__Service_Order__c> getAccount = new WorkOrdersSelector().getAccountonWorkOrder(workOrder2.Id);
        System.assert(getAccount.size() > 0);
        List<SVMXC__Service_Order__c> lstWO2 = new WorkOrdersSelector().selectEOLWorkOrders(setInstalledProduct);
    }
    /*******************************************************************************************************
    * @description DCP-47698 Method to test the retrieval of Work Orders from specific Order 
    *                        Type & Sales Order Ids
    */
    static testMethod void testSelectWorkOrderSpecificOrderTypeOLI() {
        contact c = TestDataPerson.initContact(null);
        c.Preferred_Language__c='French';
        insert c;
        List<User> lstUsers = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service
                               LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
        Test.startTest();
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(lstUsers[0].id,'Primary Field Application Scientists',serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        technician.Preferred_Service_Report_Language__c='Japanese';
        insert technician;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Service_Report_Generated__c=true;
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.SVMXC__Contact__c=c.id;
        workOrder.SVMXC__Group_Member__c=technician.id;
        workOrder.Is_Auto_Created__c=true;
        workOrder.ERP_Order_Number__c='8798675435';
        workOrder.ERP_Order_Line_Number__c = '1234567_001';
        insert workOrder;
        Test.stopTest();
        Set < String > setERPNumbers = new Set< String >{workOrder.ERP_Order_Line_Number__c};
        Set < String > setERPOrderNumber = new Set < String> {workOrder.ERP_Order_Number__c};
        Set < String > setERPOrderLineNumber = new Set <String> {workOrder.ERP_Order_Line_Number__c};
        List<SVMXC__Service_Order__c> lstWO = new WorkOrdersSelector().selectWorkOrderSpecificOrderTypeOLI(setERPNumbers, 'Installation');
        System.assert(!lstWO.isEmpty(), 'Work Orders of Installation Type not created');
        List<SVMXC__Service_Order__c> wo = new WorkOrdersSelector().selectWOWithSameERPOrderAndERPOrderLineNum(setERPOrderNumber , setERPOrderLineNumber);
        System.assert(!wo.isEmpty(), 'Work Orders of Installation Type not created');
    }
    
     /**
     * @description: Test method for selectElevatedWorkOrders()
     */
    static testmethod void testSelectElevatedWorkOrders() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc; 
        System.assert(acc.Id != null,'testSelectElevatedWorkOrders');
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id); 
        
        //insert case 
        Case cs = TestDataCase.initServiceRequestCase(con); 
        insert cs; 
        
        //insert Work Order
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.SVMXC__Contact__c=con.id;
        workOrder2.Is_Auto_Created__c = true;
        insert workOrder2;

        test.startTest();  
        new WorkOrdersSelector().selectElevatedWorkOrders(new Set<ID>{cs.Id});  
        new WorkOrdersSelector().selectWorkOrdersWithNonNullContact(new Set<ID>{workOrder2.Id});  
        test.stopTest();
    }
    
     /**
     * @description: Test method for selectWorkOrderWithSubscription()
     */
    static testmethod void testSelectWorkOrderWithSubscription() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc; 
        System.assert(acc.Id != null,'testSelectWorkOrderWithSubscription');

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id); 
        
        //insert case 
        Case cs = TestDataCase.initServiceRequestCase(con); 
        insert cs; 
        
        //insert Work Order
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        insert workOrder2;

        test.startTest();  
        new WorkOrdersSelector().selectWorkOrderWithSubscription(new Set<ID>{workOrder2.Id});  
        test.stopTest();
    }

    /**
     * @description: Test method for getWorkOrdersOnCase()
     */
    static testmethod void testGetWorkOrdersOnCase() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc; 
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id); 
        
        //insert case 
        Case cs = TestDataCase.initServiceRequestCase(con); 
        insert cs; 
        
        //insert Work Order
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        insert workOrder2;

        test.startTest();  
        List<SVMXC__Service_Order__c> wol = new WorkOrdersSelector().getWorkOrdersOnCase(workOrder2.Id); 
        System.assertEquals(1, wol.size(),'testGetWorkOrdersOnCase');  
        test.stopTest();
    }
    /**
     * Test for `selectWOwithWOID` method.
     * Verifies that the method correctly fetches work orders by ID with the required fields.
     */
    @isTest
    static void getWorkOrderIdTest() {
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        
       //insert contact
       Contact con = TestDataPerson.getNewContact(acc.Id);
        
       //insert case
       Case cs = TestDataCase.initServiceRequestCase(con);
       insert cs;
        
       SVMXC__Service_Order__c workOrder1= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
           // SVMXC__Contact__c = con.id, // Example Contact ID
           workOrder1.SVMXC__Customer_Down__c = true;
           workOrder1.Is_Auto_Created__c=true;

        SVMXC__Service_Order__c workOrder2 = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
            //SVMXC__Contact__c = con.id, // Example Contact ID
            workOrder2.SVMXC__Customer_Down__c = false;
            workOrder2.Is_Auto_Created__c=true;
            
        SVMXC__Service_Order__c workOrder3 = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder3.Is_Auto_Created__c=true;
        insert new List<SVMXC__Service_Order__c>{workOrder1, workOrder2, workOrder3};
        
        // Create a set of Work Order IDs for querying
        Set<Id> workOrderSet = new Set<Id>{workOrder1.Id, workOrder2.Id};
        
        // Test Execution
        Test.startTest();
        List<SVMXC__Service_Order__c> resultWorkOrders = new WorkOrdersSelector().getWorkOrderId(workOrderSet);
        Test.stopTest();
        
        // Assertions to validate the method behavior
        // Assert that the number of returned work orders matches the input IDs
        System.assertEquals(2, resultWorkOrders.size(), 'Two work orders should be returned.');
        
        // Verify that the returned work orders match the queried IDs
        Set<Id> resultIds = new Set<Id>();
        for (SVMXC__Service_Order__c wo : resultWorkOrders) {
            resultIds.add(wo.Id);
        }
        System.assert(resultIds.contains(workOrder1.Id), 'Result should contain Work Order 1');
        System.assert(resultIds.contains(workOrder2.Id), 'Result should contain Work Order 2');
        
        // Verify that the selected fields are populated
        for (SVMXC__Service_Order__c wo : resultWorkOrders) {
            if (wo.Id == workOrder1.Id) {
                System.assertNotEquals(null, wo.SVMXC__Contact__r.Phone, 'Contact phone should be populated for Work Order 1');
                System.assertEquals(true, wo.SVMXC__Customer_Down__c, 'Customer Down flag should be true for Work Order 1');
            } else if (wo.Id == workOrder2.Id) {
                System.assertEquals(false, wo.SVMXC__Customer_Down__c, 'Customer Down flag should be false for Work Order 2');
            }
        }
    }
    
}
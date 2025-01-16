/***************************************************************************************************************************************
* NAME         : TestWorkOrderDataSender
* DESCRIPTION  : Test class for WorkOrderDataSender.
*                    
* @AUTHOR      : 
* @DATE        : 13-Aug-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan             03-June-2021        Add coverage for scenarios in DCP-46834
* Pooja Shalwadi           09-Sep-2022         CodeScan Fixes
****************************************************************************************************************************************/
@IsTest
private class TestWorkOrderDataSender {
    
    public static final boolean BOOLEAN_CONSUMABLES_INCLUDED = false;
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CONTRACT_STATUS = 'Active';
    public static final string STRING_WORK_DETAIL_TYPE = 'Parts';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    
    static Case cs;
    static Account objAcc;
    static SVMXC__Service_Order__c workOrder;
    static SVMXC__Service_Group__c objGrp;
    static Opportunity opp;
    static SVMXC__Service_Group_Members__c objGrpMember;
    static Account objAccount;
    static Contact objContact;
    static SVMXC__Installed_Product__c objInstalledProduct;
    static SVMXC__Service_Contract__c objServiceContract;
    
    @TestSetup static void setup() {
        
        
        objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        objContact = TestDataContact.getNewContact(objAccount);
        opp = TestDataOpportunity.initOpportunity(objAccount);
        
        Product2 objProduct = new Product2(
            Name = STRING_PRODUCT_NAME, 
            Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS);
        insert objProduct;
        
        
        objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        /*SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
        System.assertEquals(insertedInstalledProduct.SVMXC__Status__c, STRING_INSTALLED_PRODUCT_STATUS);*/
        
        objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        /*SVMXC__Service_Contract__c insertedServiceContract = [Select Consumables_Included__c from SVMXC__Service_Contract__c where Id =: objServiceContract.Id];
        System.assertEquals(insertedServiceContract.Consumables_Included__c, BOOLEAN_CONSUMABLES_INCLUDED);*/
        
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        /*SVMXC__Service_Contract_Products__c insertedCoveredProduct = [Select SVMXC__Installed_Product__c from SVMXC__Service_Contract_Products__c where SVMXC__Installed_Product__c =: objInstalledProduct.Id];
        System.assertEquals(insertedCoveredProduct.SVMXC__Installed_Product__c, objInstalledProduct.Id);*/
    }
    
    
    @IsTest
    static void updateWorkOrderTestMethod() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case'
        );
        insert apexSettings;
        
        setup();
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
        
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = u.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        SVMX_PS_VS_Part_Consumption_Settings__c consumptionSetting= new  SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'Use Allocated Qty',SVMX_PS_VS_Field_Type__c ='Boolean');
        insert consumptionSetting;
        
         SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        insert objLocation;
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Site__c = objLocation.Id;  
        objCase.Date_of_Issue_Awareness__c = Date.Today();      
        insert objCase;
        /*Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
        System.assertEquals(InsertedCase.SVMXC__Component__c, objInstalledProduct.Id);*/
        
        Test.starttest();
        workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.SVMXC__Group_Member__c =grpMembers.id;
        workOrder.Is_Auto_Created__c = true;
        workOrder.Opportunity__c=opp.id;
        workOrder.ERP_Order_Number__c = '282891'; // Dummy Commit
        workOrder.ERP_Order_Line_Number__c = '20'; //Dummy Commit
        insert workOrder;
       SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Group_Member__c =grpMembers.id;
        objOrderDetail.SVMXC__Line_Type__c='Labor';
        insert objOrderDetail;
		workOrder.Send_to_ERP__c = true;
        update workOrder;
        
        /*Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
        Applied_Contract__c insertedEntitlement = [Select Work_Order__c from Applied_Contract__c where Id =: objEntitlement.Id];
        System.assertEquals(insertedEntitlement.Work_Order__c, workOrder.Id);*/
        
        Test.setMock(HttpCalloutMock.class, new MockHTTPCallout());
        Test.Stoptest();
        //System.assert(MockHTTPCallout.booResponseSuccess,'Callout failed');
        // Assert.areEqual(false,MockHTTPCallout.booResponseSuccess);
        Assert.areEqual(true,MockHTTPCallout.booResponseSuccess);
    }

    /**DCP-46834
	*	@author Akshay Mohan
	*	sendBillableEstimate
	**/
    @IsTest
    static void sendBillableEstimate() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order_Line__c',
            Bypass_Triggers_By_Object_3__c = 'Case'
        );
        insert apexSettings;

        SVMXC__Service_Order__c objWO = getWorkOrder();
		Test.startTest(); //Codescan fix Feb 2022
        Test.setMock(HttpCalloutMock.class, new MockHTTPCallout());
        objWO.SVMXC__Order_Status__c=Label.WorkOrderStatusCompleted;
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        setting.Bypass_All_Triggers__c=true;
        upsert setting;
        update objWO;
        //Remove bypass for callout
        setting.Bypass_All_Validations__c = false;
        setting.Bypass_All_Triggers__c=false;
        upsert setting;
        //Test.startTest(); //Codescan fix Feb 2022
        WorkOrderDataSender objSender = new WorkOrderDataSender();
        objSender.callout(objWO.Id);
        System.debug('result: '+objSender.strJson);
        //set final bypass for methods which will run on stop test
        setting.Bypass_All_Validations__c = true;
        setting.Bypass_All_Triggers__c=true;
        upsert setting;
        Test.stopTest();
        
        WorkOrderWrapper workOrWrapper = (WorkOrderWrapper)JSON.deserialize(objSender.strJson,WorkOrderWrapper.class);
        System.debug('workOrWrapper: '+workOrWrapper);
        System.assertEquals(1,workOrWrapper.lstServiceOrders.size(),'Incorrect WO sent');
        System.assertEquals(2,workOrWrapper.lstServiceOrders[0].lstServiceOrderLines.size(),'Incorrect lines sent');
    }

    /**DCP-46834
	*	@author Akshay Mohan
	*	sendBillableEstimateWihtoutCompletion
	**/
    @IsTest
    static void sendBillableEstimateWihtoutCompletion() {
        Test.startTest();
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order_Line__c',
            Bypass_Triggers_By_Object_3__c = 'Case'
        );
        insert apexSettings;
        SVMXC__Service_Order__c objWO = getWorkOrder();
        Test.stopTest();
        Test.setMock(HttpCalloutMock.class, new MockHTTPCallout());
        WorkOrderDataSender objSender = new WorkOrderDataSender();
        objSender.callout(objWO.Id);
        System.debug('result: '+objSender.strJson);
        
        WorkOrderWrapper workOrWrapper = (WorkOrderWrapper)JSON.deserialize(objSender.strJson,WorkOrderWrapper.class);
        System.debug('workOrWrapper: '+workOrWrapper);
        System.assertEquals(1,workOrWrapper.lstServiceOrders.size(),'Incorrect WO sent');
        System.assertEquals(0,workOrWrapper.lstServiceOrders[0].lstServiceOrderLines.size(),'Estimate lines sent');
    }
	/**
	* Method: getWorkOrder
	* Description: method to insert the work order and related object info.
	**/
	public static SVMXC__Service_Order__c getWorkOrder()
    {
        
        SVMXC__Service_Order__c objWorkOrder;
        
        Territory2 objTerritory = TestTerritoryPlanStrategyController.getTerritory();
        User objAdminUser = TestDataUser.findUserInProfile('System Administrator');
        //Create Account
        Account objAccount = TestDataAccount.getCustomerAccount();
        objAccount.BillingCountryCode = 'US';
        objAccount.Territory_Region__c = 'AMR';
        insert objAccount;
        
        System.runAs(objAdminUser)
        {
            TestDataObjectTerritory2Association.getObjectAssociationFuture(objTerritory.Id,objAccount.Id); 
            UserTerritory2Association objUTA = TestDataUserTerritory2Association.getUserAssociation(objTerritory.Id,objAdminUser.id);
            insert objUTA;
        }
        //Create contact
        Contact objContact = TestDataContact.getNewContact(objAccount);

        Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea(TestDataBillableFlowQueueable.COMPANY_CODE,'01','177','00',false);
        accSalesArea.Account__c = objAccount.Id;
        accSalesArea.Price_List_Type__c=TestDataBillableFlowQueueable.PRICE_LIST_TYPE;
        accSalesArea.CurrencyIsoCode = TestDataBillableFlowQueueable.PRICE_LIST_CURRENCY;
        accSalesArea.Price_List__c = TestDataBillableFlowQueueable.PRICE_LIST;
        accSalesArea.Contract_Number__c = '345678_US010100';
        accSalesArea.Company_Code__c = TestDataBillableFlowQueueable.COMPANY_CODE;

        insert accSalesArea;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList(TestDataBillableFlowQueueable.PRICE_LIST);
        insert priceList;

        Product2 toolProduct = TestDataMaster.initProduct('IL-SER-TRAVEL-Z1','Tools');//DCP-46834: Changes on product setup
        toolProduct.IsActive = true;
        toolProduct.SVMXC__Tracking__c = TestDataBillableFlowQueueable.TRACKING_SERIALIZED;
        toolProduct.SVMXC__Stockable__c = true;
        toolProduct.SVMXC__Enable_Serialized_Tracking__c = true;
        toolProduct.Service_Product_Type__c  = TestDataBillableFlowQueueable.SERVICE_PRODUCT_TYPE_SPARE;
        toolProduct.Material_Group__c = '41';
        toolProduct.Material_Number__c = '20029031';
        toolProduct.RMA_Required__c = true;

        insert new List<Product2>{toolProduct};

        PricebookEntry pbe1 = TestDataBillableFlowQueueable.initPriceBookEntry(toolProduct.Id, 200,TestDataBillableFlowQueueable.PRICE_LIST_CURRENCY);
        insert new List<PricebookEntry>{pbe1};

        System.runAs(objAdminUser)
        {
            SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(toolProduct.Id);
            insert workOrderIP;

            cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
            setting.Bypass_All_Validations__c = true;
            upsert setting;

            SVMXC__Site__c location = new SVMXC__Site__c();
            location.Name = 'Test Location 1';
            location.SVMXC__Account__c = objAccount.Id;
            location.SVMXC__Stocking_Location__c = true;
            insert location;

            //Insert Product Stock
            SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
            serializedProdStock.SVMXC__Location__c = location.Id;
            serializedProdStock.SVMXC__Product__c = toolProduct.Id;
            serializedProdStock.SVMXC__Status__c = TestDataBillableFlowQueueable.SERVICE_PRODUCT_STATUS_AVAILABLE;
            serializedProdStock.SVMXC__Quantity2__c = 6;
            insert serializedProdStock;

            Profile profile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
            cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(profile.Id);
            cs.Bypass_All_Validations__c = true;
            cs.Bypass_All_Triggers__c = true;
            upsert cs cs_Apex_Settings__c.Id;

            //Create Case
            Case objCaseTest = TestDataCase.initServiceRequestCase(objContact);
            insert objCaseTest;

            SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
            insert serviceTeam;
            
            SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(objAdminUser.id,'Primary Field Application Scientist',serviceTeam.id);
            technician.SVMXC__Email__c='a@b.com';
            technician.Preferred_Service_Report_Language__c='Japanese';
            insert technician;

            Account_to_Field_Support__c accToFieldSupport =TestDataFieldService.createAccountToFieldSupport(objAccount.id,'Field Service Manager',technician.id);
            insert accToFieldSupport;

            //Create WorkOrder
            objWorkOrder = TestDataFieldService.createWorkOrder(TestDataBillableFlowQueueable.STRING_WORK_ORDER_RECORD_TYPE_ESTIMATES, objCaseTest.Id, TestPartsOrderLines.STRING_WORK_ORDER_STATUS_INITIATED);
            objWorkOrder.SVMXC__Order_Type__c = Label.WorkOrderTypeServiceActivities;//DCP-46834: Changes on WO setup
            objWorkOrder.SVMXC__Company__c = objAccount.Id;
            objWorkOrder.SVMXC__Contact__c = objContact.Id;
            objWorkOrder.OwnerId = UserInfo.getUserId();
            objworkOrder.SVMXC__Group_Member__c = technician.id;
            objworkOrder.SVMXC__Billing_Type__c = Label.WorkOrderBillingTypeBillable;//DCP-46834: Changes on WO setup
            insert objWorkOrder;

            cs.Bypass_All_Validations__c = false;
            cs.Bypass_All_Triggers__c = false;
            upsert cs cs_Apex_Settings__c.Id;
            //Create WorkDetail
            Id idEstimateRT = SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByDeveloperName().get('Estimate').getRecordTypeId();
            SVMXC__Service_Order_Line__c objWorkDetail1= TestDataFieldService.createWorkDetail(objworkOrder.Id,workOrderIP.Id);
            objWorkDetail1.SVMXC__Estimated_Quantity2__c = 3;
            objWorkDetail1.SVMX_PS_VS_Consumed_Product_Stock__c= serializedProdStock.Id;
            objWorkDetail1.SVMXC__Line_Type__c = 'Labor';
            objWorkDetail1.SVMXC__Product__c=toolProduct.id;
            objWorkDetail1.RecordTypeId=idEstimateRT;//DCP-46834: set record type
            
            SVMXC__Service_Order_Line__c objWorkDetail2= TestDataFieldService.createWorkDetail(objworkOrder.Id,workOrderIP.Id);
            objWorkDetail2.SVMXC__Estimated_Quantity2__c = 3;
            objWorkDetail2.SVMX_PS_VS_Consumed_Product_Stock__c= serializedProdStock.Id;
            objWorkDetail2.SVMXC__Line_Type__c = 'Travel';
            objWorkDetail2.SVMXC__Product__c=toolProduct.id;
            objWorkDetail2.RecordTypeId=idEstimateRT;//DCP-46834: set record type
            
            insert new List<SVMXC__Service_Order_Line__c>{objWorkDetail1,objWorkDetail2};
            System.assert(String.isNotBlank(objWorkDetail1.Id),'work order not inserted');//for codescan
            setting.Bypass_All_Validations__c = false;
            update setting;
	    
        }
        return objWorkOrder;
        
     
	}
}
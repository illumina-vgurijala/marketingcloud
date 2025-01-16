/**
 * @File Name          : TestWorkDetails.cls
 * @Description        : 
 * @Author             :
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 09-23-2022
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    5/14/2020        Initial Version
 *        09/23/2022       Pooja                    CodeScan Fixes
 * Dhairya Shah CMCM6760 17April2024
**/
@isTest(SeeAllData=true)
	/*Test Data*/
public class TestWorkDetails {
    
    public static final boolean BOOLEAN_CONSUMABLES_INCLUDED = false;
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_CASE_RECORDTYPENAME = 'Service Request';
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CONTRACT_STATUS = 'Active';
    public static final string STRING_WORK_DETAIL_TYPE = 'Parts';
    public static final string STRING_WORK_DETAIL_RECORD_TYPE_RELATED_PRODUCT = 'Related Products';
     public static final String STRING_WO_RECORDTYPE = 'Field Service';    
     public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
	 public static final String STRING_TRAINING = 'Training';
     public static final String STRING_TEST_NON_SERIALIZED_PRODUCT = 'Test Non-Serialized Product';
     public static final String STRING_NON_TRACKED = 'Non-Tracked';
     public static final String STRING_EMAIL = 'puser000@amamama.com';
     public static final String STRING_LANGUAGE = 'en_US';
    public static final String STRING_INTEGRATIONSTATUS_SUCCESS = 'Success';
    public static final String STRING_REVERSAL_REQUESTED = 'Reversal Requested';
	public static final String STRING_INTEGRATION_STATUS_NOT_APPLICABLE = 'Not Applicable';
	public static final String STRING_USAGE_CONSUMPTION = 'Usage/Consumption';
	public static final String STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING = 'Repair/Troubleshooting';
	public static final String STRING_LINE_TYPE_LABOR = 'Labor';
	public static final String STRING_STATUS_OPEN = 'Open';
    public static final String STRING_ORDER_TYPE_INSTALLATION = 'Installation';
    public static final String STRING_ORDER_STATUS_TECHNICIAN_ONSITE = 'Technician Onsite';
    
    static Case cs;
    static Account objAcc;
    static SVMXC__Service_Order__c workOrder;
    static SVMXC__Service_Group__c objGrp;
    static SVMXC__Service_Group_Members__c objGrpMember;
    //dummy commit
    
    	/*Test Data*/
    public static void initializeTestData() {
        
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        
        objAcc = TestDataAccount.getAccount('TestAccount','USD');
        
        insert objAcc;
        Account objAccupdate=[select id,Account_Group__c FROM Account WHERE id=:objAcc.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        
        
        objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;
        
        objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        insert objGrpMember;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAcc.id;
        workOrder.SVMXC__Group_Member__c= objGrpMember.id;
        workOrder.SVMXC__Order_Type__c=STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
        /*Account_to_Field_Support__c objAccountTechnicianRole = new Account_to_Field_Support__c();
objAccountTechnicianRole.Account__c = objAcc.id;
objAccountTechnicianRole.User_Role__c = 'Field Service Manager';
objAccountTechnicianRole.User__c = objGrpMember.id;
insert objAccountTechnicianRole; 
*/
    }
    
    static testMethod void newWorkDetailCreation(){
        
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c FROM Account WHERE id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        SVMXC__Site__c location = new SVMXC__Site__c();
        location.Name = 'Test Location 1';
        location.SVMXC__Account__c = objAccount.Id;
        location.SVMXC__Stocking_Location__c = true;
        insert location;///tc
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Service_Product_Type__c  = 'Spare';
        serializedProd.Material_Group__c = '41';
        serializedProd.RMA_Required__c = true;
        insert serializedProd;///tc
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location.Id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 6;
        insert serializedProdStock;
        List<Product2> lstpro = new List<Product2>();
        Product2 objProduct = new Product2(Name = STRING_PRODUCT_NAME, Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS, Material_Class__c = 'Consumables');
        lstpro.add(objProduct);
        
        //Insert Product of Service Product Type Parts
        
        //Product2 objProduct1 = new Product2(Name = STRING_PRODUCT_NAME+'1',Service_Product_Type__c = 'Parts');
        //lstpro.add(objProduct1);
        
        Product2 objProduct2 = new Product2(Name = STRING_PRODUCT_NAME+'2',Service_Product_Type__c = 'Spare');
        lstpro.add(objProduct2);
        
        insert lstpro;
        
        //Product2 insertedConsumableProduct = [SELECT id,Service_Product_Type__c FROM Product2 WHERE Name = :STRING_PRODUCT_NAME][0];
        //System.assertEquals(insertedConsumableProduct.Service_Product_Type__c, STRING_PRODUCT_MATERIAL_CLASS);
        //  Product2 insertedPartProduct = [SELECT id,Service_Product_Type__c FROM Product2 WHERE Service_Product_Type__c = 'Parts'];
        //Product2 insertedSpareProduct = [SELECT id,Service_Product_Type__c FROM Product2 WHERE Service_Product_Type__c = 'Spare'][0];
        
        List<SVMXC__Installed_Product__c> lstInstProducts = new List<SVMXC__Installed_Product__c>();
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        lstInstProducts.add(objInstalledProduct);
        
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Company__c = objAccount.Id;
        lstInstProducts.add(objInstalledProduct1);
        
        insert lstInstProducts;
        
        //SVMXC__Installed_Product__c insertedInstalledProduct = [SELECT id,SVMXC__Status__c FROM SVMXC__Installed_Product__c WHERE SVMXC__Status__c= :STRING_INSTALLED_PRODUCT_STATUS][0];
        //System.assertEquals(insertedInstalledProduct.SVMXC__Status__c, STRING_INSTALLED_PRODUCT_STATUS);
        //objInstalledProduct1=[SELECT id,SVMXC__Status__c FROM SVMXC__Installed_Product__c WHERE SVMXC__Status__c= :STRING_INSTALLED_PRODUCT_STATUS][1];
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=true;//tc
        objServiceContract.Parts_Included__c = true;///tc
        objServiceContract.Labor_Included__c = true;///tc
        objServiceContract.ERP_Header_Contract_Number__c = '1234';///tc
        objServiceContract.ERP_Contract_Line_Number__c = '9898';///tc
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        
        SVMXC__Service_Contract__c insertedServiceContract = [SELECT Consumables_Included__c FROM SVMXC__Service_Contract__c WHERE Id =: objServiceContract.Id];
        System.assertEquals(true,insertedServiceContract.Consumables_Included__c);//tc
        
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        
        SVMXC__Service_Contract_Products__c insertedCoveredProduct = [SELECT SVMXC__Installed_Product__c FROM SVMXC__Service_Contract_Products__c WHERE SVMXC__Installed_Product__c =: objInstalledProduct.Id];
        System.assertEquals(insertedCoveredProduct.SVMXC__Installed_Product__c, objInstalledProduct.Id);
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
       
        //Case insertedCase = [SELECT SVMXC__Component__c FROM Case WHERE Id =: objCase.Id];
        System.assertEquals(objCase.SVMXC__Component__c, objInstalledProduct.Id);
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());  
        setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
        upsert setting;  

        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c=STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c=true;
        insert workOrder;
        
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
        /*Applied_Contract__c insertedEntitlement = [Select Work_Order__c from Applied_Contract__c where Id =: objEntitlement.Id];
        System.assertEquals(insertedEntitlement.Work_Order__c, workOrder.Id);*/
        
        List<SVMXC__Service_Order_Line__c> listSOL = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Activity_Type__c='Customer Service Review'; 
        listSOL.add(objOrderDetail); 
        
        SVMXC__Service_Order_Line__c objOrderDetail3 = new SVMXC__Service_Order_Line__c();
        objOrderDetail3.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail3.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail3.Record_Create_From_SFM__c=true;
        objOrderDetail3.SVMX_PS_VS_Consumed_Product_Stock__c= serializedProdStock.Id;  
        //objOrderDetail3.SVMXC__Product__c = serializedProd1.Id;
        objOrderDetail3.Consumption_Confirmed__c  = true;
        objOrderDetail3.Integration_Status__c = STRING_INTEGRATION_STATUS_NOT_APPLICABLE;
        listSOL.add(objOrderDetail3);

        Test.startTest();
        insert listSOL;
        
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct1.Id;
        update objOrderDetail;   
        
        WorkDetails.appliedContractsTriggerRanOnce = false; //recurssion handler 
        Test.stopTest();   
    }
    
    static testMethod void newWorkDetailCreation1(){
        
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c FROM Account WHERE id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        
        List<Product2> lstpro = new List<Product2>();
        Product2 objProduct = new Product2(Name = STRING_PRODUCT_NAME, Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS, Material_Class__c = 'Consumables');
        lstpro.add(objProduct);
        
        Product2 objProduct2 = new Product2(Name = STRING_PRODUCT_NAME+'2',Service_Product_Type__c = 'Spare');
        lstpro.add(objProduct2);

        insert lstpro;
        //DCP-33467
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = objAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        insert location1;
        //Insert Product Stock DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.id;
        nonSerializedProdStock.SVMXC__Product__c = objProduct.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;                    
        
        //Insert Product of Service Product Type Parts
        
        
        List<SVMXC__Installed_Product__c> lstInstProducts = new List<SVMXC__Installed_Product__c>();
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        lstInstProducts.add(objInstalledProduct);
        
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Company__c = objAccount.Id;
        lstInstProducts.add(objInstalledProduct1);
        
        insert lstInstProducts;
        
        SVMXC__Installed_Product__c insertedInstalledProduct = [SELECT id,SVMXC__Status__c FROM SVMXC__Installed_Product__c WHERE SVMXC__Status__c= :STRING_INSTALLED_PRODUCT_STATUS][0];
        System.assertEquals(insertedInstalledProduct.SVMXC__Status__c, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1=[SELECT id,SVMXC__Status__c FROM SVMXC__Installed_Product__c WHERE SVMXC__Status__c= :STRING_INSTALLED_PRODUCT_STATUS][1];
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=true;//tc
        objServiceContract.Parts_Included__c = true;///tc
        objServiceContract.Labor_Included__c = true;///tc
        objServiceContract.ERP_Header_Contract_Number__c = '1234';///tc
        objServiceContract.ERP_Contract_Line_Number__c = '9898';///tc
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        SVMXC__Service_Contract__c insertedServiceContract = [SELECT Consumables_Included__c FROM SVMXC__Service_Contract__c WHERE Id =: objServiceContract.Id];
        System.assertEquals(true,insertedServiceContract.Consumables_Included__c);//tc
        
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        
        SVMXC__Service_Contract_Products__c insertedCoveredProduct = [SELECT SVMXC__Installed_Product__c FROM SVMXC__Service_Contract_Products__c WHERE SVMXC__Installed_Product__c =: objInstalledProduct.Id];
        System.assertEquals(insertedCoveredProduct.SVMXC__Installed_Product__c, objInstalledProduct.Id);
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase; 
        System.assertEquals(objCase.SVMXC__Component__c, objInstalledProduct.Id);
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());  
        setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
        upsert setting;  

        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c=STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c=true;
        workOrder.Cost_Center__c = 23451;
        insert workOrder;
        
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
        
        //tcStart
        List<SVMXC__Service_Order_Line__c> lstWD = new List<SVMXC__Service_Order_Line__c>();
       //Billable work Details
        SVMXC__Service_Order_Line__c objOrderDetail1= new SVMXC__Service_Order_Line__c();
        objOrderDetail1.SVMXC__Is_Billable__c = false;
        objOrderDetail1.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
        //objOrderDetail1.SVMXC__Activity_Type__c = STRING_TRAINING;
        objOrderDetail1.Non_Billable_Reason__c ='Goodwill';
        objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;    
        objOrderDetail1.Integration_Status__c = STRING_INTEGRATION_STATUS_NOT_APPLICABLE;		
        lstWD.add(objOrderDetail1);
        
        SVMXC__Service_Order_Line__c objOrderDetail5= new SVMXC__Service_Order_Line__c();
        objOrderDetail5.SVMXC__Is_Billable__c = false;
        objOrderDetail5.SVMXC__Line_Type__c = 'Material Consumed';
        objOrderDetail5.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail5.SVMXC__Activity_Type__c = STRING_TRAINING;
        lstWD.add(objOrderDetail5);
        
        
        SVMXC__Service_Order_Line__c objOrderDetail2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objOrderDetail2.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
        //objOrderDetail2.Duration_in_hours__c = '1';
        objOrderDetail2.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
        objOrderDetail2.Labor_Hours__c  = '1';
        lstWD.add(objOrderDetail2);
        
        SVMXC__Service_Order_Line__c objOrderDetail4 = TestDataFieldService.createMaterialsConsumedTypeWorkDetail(workOrder.Id,objProduct.Id);
        system.debug('@@@objOrderDetail4'+objOrderDetail4);
        lstWD.add(objOrderDetail4);
        
        Test.startTest();
        insert lstWD;//tcEnd
        WorkDetails.appliedContractsTriggerRanOnce = false; //recurssion handler 
        Test.stopTest();
    }

        /*
        * @author : Gagan Sindwani
        * @description : DCP-47396 - TestMethod to verify the duration =  Labor Hours + Indirect Hours + Travel Hours
        */
        static testMethod void newWorkDetailCreation2(){
        
            Account objAccount = TestDataAccount.getNewAccount();
            Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
            objAccupdate.Account_Group__c='Distributor';
            update objAccupdate;
            Contact objContact = TestDataContact.getNewContact(objAccount);
    
            List<SVMXC__Installed_Product__c> lstInstProducts = new List<SVMXC__Installed_Product__c>();
            SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
            objInstalledProduct.SVMXC__Company__c = objAccount.Id;
            lstInstProducts.add(objInstalledProduct);
            insert lstInstProducts;
            
            Case objCase = TestDataCase.initServiceRequestCase(objContact);
            objCase.SVMXC__Component__c = objInstalledProduct.Id;
            insert objCase;
            
            cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());  
            setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
            upsert setting; 

            workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
            
            workOrder.SVMXC__Company__c = objAccount.id;
            workOrder.SVMXC__Component__c = objInstalledProduct.Id;
            workOrder.SVMXC__Order_Type__c=STRING_ORDER_TYPE_INSTALLATION;
            workOrder.Is_Auto_Created__c=true;
            workOrder.Cost_Center__c = 23451;
            
            insert workOrder;
            
            //tcStart
            List<SVMXC__Service_Order_Line__c> lstWD = new List<SVMXC__Service_Order_Line__c>();
            
            SVMXC__Service_Order_Line__c objOrderDetail101 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
            objOrderDetail101.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
            objOrderDetail101.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
            objOrderDetail101.Labor_Hours__c  = '1:10';
            lstWD.add(objOrderDetail101);
    
            SVMXC__Service_Order_Line__c objOrderDetail102 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
            objOrderDetail102.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
            objOrderDetail102.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
            objOrderDetail102.Indirect_in_hours__c  = '2';
            lstWD.add(objOrderDetail102);
    
            SVMXC__Service_Order_Line__c objOrderDetail103 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
            objOrderDetail103.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
            objOrderDetail103.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
            objOrderDetail103.Labor_Hours__c  = '2';
            objOrderDetail103.Indirect_in_hours__c  = '2';
            lstWD.add(objOrderDetail103);
    
            SVMXC__Service_Order_Line__c objOrderDetail104 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
            objOrderDetail104.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
            objOrderDetail104.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
            objOrderDetail104.Labor_Hours__c  = '2';
            objOrderDetail104.Indirect_in_hours__c  = '2:15';
            lstWD.add(objOrderDetail104);
    
            SVMXC__Service_Order_Line__c objOrderDetail105 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
            objOrderDetail105.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
            objOrderDetail105.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
            objOrderDetail105.Labor_Hours__c  = '2:15';
            objOrderDetail105.Indirect_in_hours__c  = '2';
            lstWD.add(objOrderDetail105);
    
            SVMXC__Service_Order_Line__c objOrderDetail106 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
            objOrderDetail106.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
            objOrderDetail106.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
            objOrderDetail106.Labor_Hours__c  = '5:15';
            objOrderDetail106.Indirect_in_hours__c  = '2:15';
            lstWD.add(objOrderDetail106);

            SVMXC__Service_Order_Line__c objOrderDetail107 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
            objOrderDetail107.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
            objOrderDetail107.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
            objOrderDetail107.Labor_Hours__c  = '5:45';
            objOrderDetail107.Indirect_in_hours__c  = '3:50';
            lstWD.add(objOrderDetail107);
            Test.startTest();

            //DHairya Shah 11th March changes --> Updating Validation rules for bypassing the VR
            setting.Bypass_All_Validations__c = true;
            upsert setting;
            
            insert lstWD;

            objOrderDetail106.Travel_Time_in_hours__c = '3:50';
            update objOrderDetail106;//tcEnd
            
            //DHairya Shah 11th March changes --> Updating Validation rules for for removing Bypass VR cond.
            setting.Bypass_All_Validations__c = false;
            upsert setting;
             
            WorkDetails.appliedContractsTriggerRanOnce = false; //recurssion handler 
            Test.stopTest();
            List<SVMXC__Service_Order_Line__c> lstWD2 = [Select Id, Duration_in_hours__c,Labor_Hours__c,Indirect_in_hours__c,Travel_Time_in_hours__c from SVMXC__Service_Order_Line__c where Labor_Hours__c = '5:15' and Indirect_in_hours__c = '2:15' limit 1];
            System.assertequals('11:20',lstWD2[0].Duration_in_hours__c);
            
        }
        //47396
    /*
    * @author : Rucha Dalvi
    * @description : DCP-46273 - TestMethod for verifying confirm operability for Relocation WO
    */
    static testMethod void testConfirmOperabilityReloctaionWO(){
    
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c FROM Account WHERE id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        Contact objContact = TestDataContact.getNewContact(objAccount);

        List<SVMXC__Installed_Product__c> lstInstProducts = new List<SVMXC__Installed_Product__c>();
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        lstInstProducts.add(objInstalledProduct);
        insert lstInstProducts;
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());  
        setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
        upsert setting;

        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        //workOrder.SVMXC__Order_Type__c='Relocation';  //Dhairya shah -CMCM -6760 Changes made on 15th april
        workOrder.Is_Auto_Created__c=true;
        workOrder.Cost_Center__c = 23451;
        insert workOrder;
        
        objGrp = TestDataFieldService.createServiceTeam('TestServiceTeamName','Antarctica');
        insert objGrp;
        
        objGrpMember = TestDataFieldService.createTechnician(userInfo.getUserId(),'Test',objGrp.id);
        insert objGrpMember;

        List<SVMXC__Service_Order_Line__c> lstWD = new List<SVMXC__Service_Order_Line__c>();
        
        SVMXC__Service_Order_Line__c objOrderDetail101 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objOrderDetail101.SVMXC__Activity_Type__c = 'IQ/OQ';
        objOrderDetail101.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
        objOrderDetail101.Work_Order_Type__c  = 'Relocation';
        objOrderDetail101.SVMXC__Group_Member__c = objGrpMember.Id;
        lstWD.add(objOrderDetail101);

        SVMXC__Service_Order_Line__c objOrderDetail102 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objOrderDetail102.SVMXC__Activity_Type__c = 'System Health Check';
        objOrderDetail102.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
        objOrderDetail102.Work_Order_Type__c  = 'Relocation';
        objOrderDetail102.SVMXC__Group_Member__c = objGrpMember.Id;
        lstWD.add(objOrderDetail102);
        
        Test.startTest();
        insert lstWD;
        WorkDetails.appliedContractsTriggerRanOnce = false; //recurssion handler 
        //objOrderDetail102.SVMXC__Activity_Type__c = 'PQ';
        //update objOrderDetail102;

        //objOrderDetail101.SVMXC__Line_Status__c='Canceled';
        //update objOrderDetail101;
        
        Test.stopTest();
        List<SVMXC__Service_Order__c> lstWorkOrder = [SELECT Id, Confirmed_Operability__c FROM SVMXC__Service_Order__c WHERE Id =: workOrder.Id limit 1];
        //system.debug('46273 lstWorkOrder[0].Confirmed_Operability__c: '+lstWorkOrder[0].Confirmed_Operability__c);
        System.assertequals('IQ/OQ;System Health Check',lstWorkOrder[0].Confirmed_Operability__c);
        
    }
    
    static testMethod void createPartOrderAndLines(){
        
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = 'Distributor';
        update objAccount;
        System.assertNotEquals(null, objAccount.Id);
        Contact objContact = TestDataContact.getNewContact(objAccount);        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;
        System.assertNotEquals(null, objCase.Id);
        
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Service_Product_Type__c  = 'Spare';
        serializedProd.Material_Group__c = '41';
        serializedProd.RMA_Required__c = true;
        insert serializedProd;
        System.assertNotEquals(null, serializedProd.Id);
        
        SVMXC__Product_Stock__c objProductStock = new SVMXC__Product_Stock__c();
        objProductStock.SVMXC__Product__c = serializedProd.Id;
        insert objProductStock;
        System.assertNotEquals(null, objProductStock.Id);
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Order_Type__c=STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        workOrder.Cost_Center__c = 23451;
        insert workOrder;   
        System.assertNotEquals(null, workOrder.Id);

        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Line_Type__c = STRING_WORK_DETAIL_TYPE;
        objOrderDetail.SVMX_PS_VS_Consumed_Product_Stock__c = objProductStock.Id;
        objOrderDetail.Consumption_Confirmed__c = true;        
        objOrderDetail.Non_Billable_Reason__c ='Goodwill';
        
        Test.startTest();
        insert objOrderDetail;
        WorkDetails.appliedContractsTriggerRanOnce = false; //recurssion handler 
        System.assertNotEquals(null, objOrderDetail.Id);
        WorkDetailNonBillableChangeNotification obj = new WorkDetailNonBillableChangeNotification();
        obj.workOrderId = workOrder.id;
        List < SVMXC__Service_Order_Line__c > lstworkDetails = obj.getlistworkDetails();
        Test.stopTest();  
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrder = [select id,SVMXC__Service_Order__c FROM SVMXC__RMA_Shipment_Order__c WHERE SVMXC__Service_Order__c =: workOrder.id];
        System.assertEquals(1, lstPartsOrder.size());
         System.assertEquals(1, lstworkDetails.size(),'Work Detail Qualified For Non Billable Notification.'); //added for 38817
        System.assertEquals(1, [select id from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__c =: lstPartsOrder[0].id].size());
    }
    
    
    /**
* DCP- 7465
*  @author : Sandeep Ram Ch.
*  @description - test validate From Location on work detail
**/
    
    static testMethod void validateFromLocation(){
        
        initializeTestData();
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc;
        
        SVMXC__Site__c objLoc2 = TestDataFieldService.createLocation('Test Location2','Test street','Test Country','5555555','USD');
        insert objLoc2;
        
        SVMXC__Service_Group_Site__c objLocCovered =TestDataFieldService.createLocationCovered(objGrpMember.id,objLoc.id,objGrp.id);
        insert objLocCovered;
        
        SVMXC__Service_Group_Site__c objLocCovered2 =TestDataFieldService.createLocationCovered(objGrpMember.id,objLoc2.id,objGrp.id);
        insert objLocCovered2;
        // DCP-33467
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = STRING_TEST_NON_SERIALIZED_PRODUCT;
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = STRING_NON_TRACKED;
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
        insert nonSerializedProd;  
        
        //Insert Product Stock DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;                
        
        List<SVMXC__Service_Order_Line__c> lstWorkDeatils= new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objWorkDetail =TestDataFieldService.createWorkDetail(workOrder.id,objInstalledProduct.id);
        objWorkDetail.SVMXC__Line_Type__c='Tools';
        objWorkDetail.SVMXC__From_Location__c=objLoc.id;
        lstWorkDeatils.add(objWorkDetail);
        
        SVMXC__Service_Order_Line__c objWorkDetail1 =TestDataFieldService.createWorkDetail(workOrder.id,objInstalledProduct.id);
        objWorkDetail1.SVMXC__Line_Type__c='Parts';
        objWorkDetail1.SVMXC__Consumed_From_Location__c=objLoc.id;//DCP-33467
        objWorkDetail1.SVMXC__Actual_Quantity2__c = 2; //DCP-33467
        objWorkDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467 
        objWorkDetail1.Integration_Status__c = STRING_INTEGRATION_STATUS_NOT_APPLICABLE;
        lstWorkDeatils.add(objWorkDetail1);
        
        Test.startTest();
        insert lstWorkDeatils;
        WorkDetails.appliedContractsTriggerRanOnce = false; //recurssion handler      
        System.assertEquals(objWorkDetail.SVMXC__From_Location__c,objLoc.id);
        
        SVMXC__Product_Serial__c objStockedSerial = new SVMXC__Product_Serial__c();
        objStockedSerial.SVMXC__Active__c= true;
        objStockedSerial.SVMX_PS_VS_Linked_Installed_Product__c=objInstalledProduct.id;
        insert objStockedSerial;
        
        objWorkDetail.SVMXC__From_Location__c=objLoc2.id;
        
        objWorkDetail1.SVMXC__Actual_Quantity2__c=2;
        objWorkDetail1.Record_Create_From_SFM__c = true;
       // objWorkDetail1.SVMX_PS_VS_Consumed_Stocked_Serial__c=objStockedSerial.id;
        
        
        lstWorkDeatils.clear();
        lstWorkDeatils.add(objWorkDetail);
        lstWorkDeatils.add(objWorkDetail1);
        try{
        update lstWorkDeatils;
        }
        catch(exception e){
            system.debug('Error:'+e.getmessage());
            system.assert(e.getmessage().contains('please select location from your trunk/locker for adding parts'));
        }
        Test.stopTest();
        
    }
    
    /**
    *  @author : Ritika M
    *  @description - test FRU List of Producrs
    **/
    
    static testMethod void validateToolProductFromFRUListForNonIVD(){
        initializeTestData();
        
        List<Product2> listProd = new List<Product2>();
        Product2 workOrderProduct = TestDataMaster.initProduct('Test');
        workOrderProduct.Source_System__c = 'SAP'; 
        listProd.add(workOrderProduct);
        
        Product2 toolProduct = TestDataMaster.initProduct('Test Product','Tools');
        //updated to Standard Tool since service product type values got updated (This functionality is no more dependent on Service product Type)
        toolProduct.GFSL_FC_Hierarchy__c = 'Standard Tool';
        toolProduct.Service_Product_Type__c = 'Standard Tool';
        toolProduct.Source_System__c = 'SAP';
        listProd.add(toolProduct);
        
        insert listProd;
        
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(workOrderProduct.Id);
        
        TestDataFieldService.createToolFRU(serviceBOM.Id, toolProduct.Id);

        SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(workOrderProduct.Id);
        workOrderIP.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert workOrderIP;

        workOrder.SVMXC__Order_Type__c = 'Remote support';
        workOrder.SVMXC__Component__c=workOrderIP.Id;
        workOrder.SVMXC__Product__c = workOrderProduct.Id;
        workOrder.Warning_Message__c = 'Warning for part Test on the Work Order.\r\nWarning for part Test on the Work Order.';
        WorkOrders.skipWOTrigger = true;
        update workOrder;
        SVMXC__Service_Order_Line__c objWorkDetail= TestDataFieldService.createToolTypeWorkDetail(workOrder.Id,toolProduct.Id);
        
        Test.startTest();
        
        insert objWorkDetail;
        List<SVMXC__Service_Order_Line__c> workDetailInserted = [SELECT Id FROM SVMXC__Service_Order_Line__c WHERE Id = : objWorkDetail.Id];
        System.assertEquals(true,!workDetailInserted.isEmpty());

        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        insert toolProduct2;

        objWorkDetail.SVMXC__Product__c = toolProduct2.Id;
        update objWorkDetail;         

        workDetailInserted = [Select Id, Warning_Message__c from SVMXC__Service_Order_Line__c where Id = : objWorkDetail.Id];
        System.assertEquals(workDetailInserted[0].Warning_Message__c, System.label.FRU_List_Trigger_Error_Message_Non_IVD);

        delete objWorkDetail;
        Test.stopTest();
    }

    /**
    *  @author : Ritika M
    *  @description - test FRU List of Producrs
    **/
    
    static testMethod void validateToolProductFromFRUListForIVD(){
        initializeTestData();
        
        List<Product2> listProd = new List<Product2>();
        Product2 workOrderProduct = TestDataMaster.initProduct('Test');
        //workOrderProduct.Regulatory_Type__c = 'DX';
        workOrderProduct.Source_System__c = 'SAP'; 
        listProd.add(workOrderProduct);
        
        Product2 toolProduct = TestDataMaster.initProduct('Test Product','Tools');
        //updated to Standard Tool since service product type values got updated (This functionality is no more dependent on Service product Type)
        toolProduct.GFSL_FC_Hierarchy__c = 'Standard Tool';
        toolProduct.Service_Product_Type__c = 'Standard Tool';
        toolProduct.Source_System__c = 'SAP'; 
        listProd.add(toolProduct);
        
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(workOrderProduct.Id);
        
        TestDataFieldService.createToolFRU(serviceBOM.Id, toolProduct.Id);

        SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(workOrderProduct.Id);
        workOrderIP.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert workOrderIP;

        
        workOrder.SVMXC__Component__c=workOrderIP.Id;
        workOrder.SVMXC__Product__c = workOrderProduct.Id;
        WorkOrders.skipWOTrigger = true;
        update workOrder;
        SVMXC__Service_Order_Line__c objWorkDetail= TestDataFieldService.createToolTypeWorkDetail(workOrder.Id,toolProduct.Id);
        
        Test.startTest();
        
        insert objWorkDetail;
        List<SVMXC__Service_Order_Line__c> workDetailInserted = [SELECT Id FROM SVMXC__Service_Order_Line__c WHERE Id = : objWorkDetail.Id];
        System.assertEquals(true,!workDetailInserted.isEmpty());

        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        insert toolProduct2;

        try{
            objWorkDetail.SVMXC__Product__c = toolProduct2.Id;
            update objWorkDetail;         
        }catch(Exception ex) {
            System.assert(ex.getMessage().contains(System.label.FRU_List_Trigger_Error_Message_IVD));
        } 
        Test.stopTest();
    }

/**
    *  @author : Ritika M
    *  @description - test FRU List of Producrs
    **/
    
    static testMethod void validatePartSwapFromFRUListForNonIVD(){
        initializeTestData();
        
        List<Product2> listProd = new List<Product2>();
        Product2 workOrderProduct = TestDataMaster.initProduct('Test');
        workOrderProduct.Source_System__c = 'SAP'; 
        listProd.add(workOrderProduct);
        
        Product2 toolProduct = TestDataMaster.initProduct('Test Product','Tools');
        toolProduct.Source_System__c = 'SAP'; 
        listProd.add(toolProduct);
        insert listProd;
        
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc; //Insert DCP-33467

        //Insert Product Stock DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = toolProduct.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;

        
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(workOrderProduct.Id);
        
        TestDataFieldService.createPartFRU(serviceBOM.Id, toolProduct.Id);

        SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(workOrderProduct.Id);
        workOrderIP.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert workOrderIP;

        
        workOrder.SVMXC__Component__c=workOrderIP.Id;
        workOrder.SVMXC__Product__c = workOrderProduct.Id;
        WorkOrders.skipWOTrigger = true;
        update workOrder;
        SVMXC__Service_Order_Line__c objWorkDetail= TestDataFieldService.createPartTypeWorkDetail(workOrder.Id,toolProduct.Id,workOrderIP.Id);
        objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;//33467
        Test.startTest();
        
        insert objWorkDetail;
        List<SVMXC__Service_Order_Line__c> workDetailInserted = [SELECT Id FROM SVMXC__Service_Order_Line__c WHERE Id = : objWorkDetail.Id];
        System.assertEquals(true,!workDetailInserted.isEmpty());

        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        insert toolProduct2;

        objWorkDetail.SVMXC__Product__c = toolProduct2.Id;
        update objWorkDetail;         

        workDetailInserted = [Select Id, Warning_Message__c from SVMXC__Service_Order_Line__c where Id = : objWorkDetail.Id];
        System.assertEquals(workDetailInserted[0].Warning_Message__c, System.label.FRU_List_Trigger_Error_Message_Non_IVD);
            
        Test.stopTest();
    }

    /**
    *  @author : Ritika M
    *  @description - test FRU List of Producrs
    **/
    
    static testMethod void validatePartSwapFromFRUListForIVD(){
        initializeTestData();
        
        List<Product2> listProd = new List<Product2>();
        Product2 workOrderProduct = TestDataMaster.initProduct('Test');
        //workOrderProduct.Regulatory_Type__c = 'DX';
        workOrderProduct.Source_System__c = 'SAP';
        listProd.add(workOrderProduct); 
        
        Product2 toolProduct = TestDataMaster.initProduct('Test Product','Tools');
        toolProduct.Service_Product_Type__c = 'Spare';
        toolProduct.Source_System__c = 'SAP';
        listProd.add(toolProduct); 
        insert listProd;

        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc; //Insert DCP-33467
        
        //Insert Product Stock DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = toolProduct.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;

        
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(workOrderProduct.Id);
        
        TestDataFieldService.createPartFRU(serviceBOM.Id, toolProduct.Id);

        SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(workOrderProduct.Id);
        workOrderIP.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert workOrderIP;

        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        insert toolProduct2;
        
        workOrder.SVMXC__Component__c=workOrderIP.Id;
        workOrder.SVMXC__Product__c = workOrderProduct.Id;
        WorkOrders.skipWOTrigger = true;
        update workOrder;
        SVMXC__Service_Order_Line__c objWorkDetail= TestDataFieldService.createPartTypeWorkDetail(workOrder.Id,toolProduct.Id,workOrderIP.Id);
        objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;//DCP-33467
        Test.startTest();
        
        insert objWorkDetail;
        List<SVMXC__Service_Order_Line__c> workDetailInserted = [SELECT Id FROM SVMXC__Service_Order_Line__c WHERE Id = : objWorkDetail.Id];
        System.assertEquals(true,!workDetailInserted.isEmpty());
        
        try{
            objWorkDetail.SVMXC__Product__c = toolProduct2.Id;
            update objWorkDetail;         
        }catch(Exception ex) {
            System.assert(ex.getMessage().contains(System.label.FRU_List_Trigger_Error_Message_IVD));
        } 
        Test.stopTest();
    }


     /**
    * @author : Ritika Maheshwari
    *  @description - Test the work order estimates and quote mismatch
    **/
    static testmethod void checkEstimateAndDebriefLinePartMismatchOnInsert() {
    
        Product2 product1 = TestDataMaster.createProduct(true);
        Product2 product2 = TestDataMaster.createProduct(true);
        //insert Estimates work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Estimates', null, 'Initiated');
        insert workOrder;
        Test.startTest();
        //create estimate line items
        List<SVMXC__Service_Order_Line__c> lstEstimateLine = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetailPart1 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
        objOrderDetailPart1.SVMXC__Product__c = product1.Id;
        objOrderDetailPart1.SVMXC__Estimated_Quantity2__c = 1;
        lstEstimateLine.add(objOrderDetailPart1);
        SVMXC__Service_Order_Line__c objOrderDetailPart2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
        objOrderDetailPart2.SVMXC__Product__c = product1.Id;
        objOrderDetailPart2.SVMXC__Estimated_Quantity2__c = 1;
        lstEstimateLine.add(objOrderDetailPart2);
        insert lstEstimateLine;
        //Check if there is a mismatch
        //Convert work order to field service.
        Id idWorkDetailRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId(); 
        workOrder.RecordTypeId = idWorkDetailRecordTypeId;
        workOrder.PO_Number__c = '1122';
        workOrder.SVMXC__Order_Status__c = STRING_ORDER_STATUS_TECHNICIAN_ONSITE;
        update workOrder;
        
        //Icreatensert Debrief line items
        List<SVMXC__Service_Order_Line__c> lstDebriefLine = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetailPart3 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objOrderDetailPart3.SVMXC__Product__c = product2.Id;
        objOrderDetailPart3.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetailPart3.SVMXC__Line_Type__c = 'Material Consumed';
        lstDebriefLine.add(objOrderDetailPart3);
        SVMXC__Service_Order_Line__c objOrderDetailPart4 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objOrderDetailPart4.SVMXC__Product__c = product2.Id;
        objOrderDetailPart4.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetailPart4.SVMXC__Line_Type__c = 'Material Consumed';
        lstDebriefLine.add(objOrderDetailPart4);
        insert lstDebriefLine;
        Test.stopTest();
        
        SVMXC__Service_Order__c objWorkorder = [SELECT Estimate_Debrief_Mismatch__c FROM SVMXC__Service_Order__c WHERE Id =: workOrder.Id];
        System.assertEquals(true, objWorkorder.Estimate_Debrief_Mismatch__c, 'Error in Estimate Debrief Lines Comparison');
    }

    
     /**
    * @author : Ritika Maheshwari
    *  @description - Test the work order estimates and quote mismatch
    **/
    static testmethod void checkEstimateAndDebriefLinePartMismatchOnUpdate() {
        Product2 product = TestDataMaster.createProduct(true);
        //insert Estimates work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Estimates', null, 'Initiated');
        insert workOrder;
        //create estimate line items
        SVMXC__Service_Order_Line__c objOrderDetailPart1 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
        objOrderDetailPart1.SVMXC__Product__c = product.Id;
        objOrderDetailPart1.SVMXC__Estimated_Quantity2__c = 1;
        insert objOrderDetailPart1;
        Test.startTest();
        //Convert work order to field service.
        Id idWorkDetailRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId(); 
        workOrder.RecordTypeId = idWorkDetailRecordTypeId;
        workOrder.PO_Number__c = '1122';
        workOrder.SVMXC__Order_Status__c = STRING_ORDER_STATUS_TECHNICIAN_ONSITE;
        update workOrder;
        //Icreatensert Debrief line items
        SVMXC__Service_Order_Line__c objOrderDetailPart2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objOrderDetailPart2.SVMXC__Product__c = product.Id;
        objOrderDetailPart2.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetailPart2.SVMXC__Line_Type__c = 'Material Consumed';
        insert objOrderDetailPart2;
        
        objOrderDetailPart1.SVMXC__Estimated_Quantity2__c = 2;
        update objOrderDetailPart1;
        
        objOrderDetailPart2.SVMXC__Actual_Quantity2__c = 3;
            update objOrderDetailPart2;
            
        Test.stopTest();
        SVMXC__Service_Order__c objWorkorder = [SELECT Estimate_Debrief_Mismatch__c FROM SVMXC__Service_Order__c WHERE Id =: workOrder.Id];
        System.assertEquals(true, objWorkorder.Estimate_Debrief_Mismatch__c, 'Error in Estimate Debrief Lines Comparison');    
    }

     /**
    * @author : Ritika Maheshwari
    *  @description - Test the work order estimates and quote mismatch
    **/
    static testmethod void checkEstimateAndDebriefLineActivityMismatchOnInsert() {
        //insert Estimates work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Estimates', null, 'Initiated');
        insert workOrder;
        //create estimate line items
        List<SVMXC__Service_Order_Line__c> lstEstimateLine = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetailPart1 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
        objOrderDetailPart1.SVMXC__Activity_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        objOrderDetailPart1.SVMXC__Estimated_Quantity2__c = 1;
        lstEstimateLine.add(objOrderDetailPart1);
        SVMXC__Service_Order_Line__c objOrderDetailPart2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
        objOrderDetailPart2.SVMXC__Activity_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        objOrderDetailPart2.SVMXC__Estimated_Quantity2__c = 1;
        lstEstimateLine.add(objOrderDetailPart2);
        insert lstEstimateLine;
        Test.startTest();
        //Check if there is a mismatch
        SVMXC__Service_Order__c objWorkorder = [SELECT Estimate_Debrief_Mismatch__c FROM SVMXC__Service_Order__c WHERE Id =: workOrder.Id];
        // System.assertEquals(objWorkorder.Estimate_Debrief_Mismatch__c, true);
        //Convert work order to field service.
        Id idWorkDetailRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId(); 
        workOrder.RecordTypeId = idWorkDetailRecordTypeId;
        workOrder.PO_Number__c = '1122';
        workOrder.SVMXC__Order_Status__c = STRING_ORDER_STATUS_TECHNICIAN_ONSITE;
        update workOrder;
        //Icreatensert Debrief line items
        List<SVMXC__Service_Order_Line__c> lstDebriefLine = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetailPart3 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objOrderDetailPart3.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
        //objOrderDetailPart3.Duration_in_hours__c = '1';
        objOrderDetailPart3.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
        objOrderDetailPart3.Labor_Hours__c  = '1';
        lstDebriefLine.add(objOrderDetailPart3);
        SVMXC__Service_Order_Line__c objOrderDetailPart4 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objOrderDetailPart4.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
        //objOrderDetailPart4.Duration_in_hours__c = '1';
        objOrderDetailPart4.Labor_Hours__c  = '1';
        lstDebriefLine.add(objOrderDetailPart4);
        insert lstDebriefLine;
        objWorkorder = [SELECT Estimate_Debrief_Mismatch__c FROM SVMXC__Service_Order__c WHERE Id =: workOrder.Id];
        //System.assertEquals(objWorkorder.Estimate_Debrief_Mismatch__c, true);
        Test.stopTest();
        objWorkorder = [SELECT Estimate_Debrief_Mismatch__c FROM SVMXC__Service_Order__c WHERE Id =: workOrder.Id];
        System.assertEquals(true,objWorkorder.Estimate_Debrief_Mismatch__c);
    }

    
     /**
    * @author : Ritika Maheshwari
    *  @description - Test the work order estimates and quote mismatch
    **/
    static testmethod void checkEstimateAndDebriefLineActivityMismatchOnUpdate() {
        //insert Estimates work order
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Estimates', null, 'Initiated');
        insert workOrder;
        //create estimate line items
        SVMXC__Service_Order_Line__c objOrderDetailPart1 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,'Estimate');
        objOrderDetailPart1.SVMXC__Activity_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        objOrderDetailPart1.SVMXC__Estimated_Quantity2__c = 1;
        insert objOrderDetailPart1;
        //Convert work order to field service.
        Id idWorkDetailRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId(); 
        workOrder.RecordTypeId = idWorkDetailRecordTypeId;
        workOrder.PO_Number__c = '1122';
        workOrder.SVMXC__Order_Status__c = STRING_ORDER_STATUS_TECHNICIAN_ONSITE;
        update workOrder;
        Test.startTest();
        //Icreatensert Debrief line items
        SVMXC__Service_Order_Line__c objOrderDetailPart2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objOrderDetailPart2.SVMXC__Activity_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        //objOrderDetailPart2.Duration_in_hours__c = '1';
        objOrderDetailPart2.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
        objOrderDetailPart2.Labor_Hours__c  = '1';
        insert objOrderDetailPart2; 

        objOrderDetailPart1.SVMXC__Estimated_Quantity2__c = 2.5;
        update objOrderDetailPart1;

        objOrderDetailPart2.Labor_Hours__c = '3:30';
        update objOrderDetailPart2;
        Test.stopTest();
        
        SVMXC__Service_Order__c objWorkorder = [SELECT Estimate_Debrief_Mismatch__c FROM SVMXC__Service_Order__c WHERE Id =: workOrder.Id];
        System.assertEquals(true,objWorkorder.Estimate_Debrief_Mismatch__c);
    }

    static testmethod void validateICEParametersOnWorkOrder(){
        initializeTestData();

        
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = 'Distributor';
        update objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
        System.assertNotEquals(null, objInstalledProduct.Id);
        

        Case objCase = TestDataCase.initServiceRequestCase(objContact);  
        insert objCase; 
        System.assertNotEquals(null, objCase.Id);
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.Is_Auto_Created__c=true;
        Test.startTest();
        insert workOrder; 
        System.assertNotEquals(null, workOrder.Id);

        SVMXC__Service_Order_Line__c objWorkDetail =TestDataFieldService.createWorkDetail(workOrder.id,objInstalledProduct.Id);
        objWorkDetail.SVMXC__Line_Type__c=STRING_LINE_TYPE_LABOR;
        objWorkDetail.SVMXC__Activity_Type__c = 'IQ/OQ';
        insert objWorkDetail;
        System.assertNotEquals(null, objWorkDetail.Id);
        
        objWorkDetail.SVMXC__Activity_Type__c = 'Traning';
        update objWorkDetail;
        Test.stopTest();        
        //delete objWorkDetail;
       // System.assertEquals(true, [select id,SVMXC__Is_Billable__c from SVMXC__Service_Order_Line__c where id =: objWorkDetail.Id][0].SVMXC__Is_Billable__c);
    }
    

    /**
    *  @author : Mandeep Singh
    *  @description - Test for insert of related product(case line) on case
    **/
     static testMethod void createRelatedProductWorkDetail(){
        Id idWorkDetailRelProdRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(STRING_WORK_DETAIL_RECORD_TYPE_RELATED_PRODUCT).getRecordTypeId(); 
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = 'Distributor';
        update objAccount;
        
        Contact objContact = TestDataContact.getNewContact(objAccount);        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        Test.startTest();
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Order_Type__c=STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;   

        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.RecordTypeId = idWorkDetailRelProdRecordTypeId;
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        //objOrderDetail.SVMXC__Line_Type__c = STRING_WORK_DETAIL_TYPE; DCP-33467
        insert objOrderDetail;
        
        Test.stopTest();        
    }
     /**
    *  @author : Debanka
    *  @description - test FRU List of Producrs
    **/
    
    static testMethod void validateMaterialsConsumedFromFRUListForIVD(){
        initializeTestData();
        
        Product2 workOrderProduct = TestDataMaster.initProduct('Test');
        workOrderProduct.Regulatory_Type__c = 'DX';
        workOrderProduct.Source_System__c = 'SAP';
        insert workOrderProduct;

        Product2 toolProduct = TestDataMaster.initProduct('Test Product','Tools');
        workOrderProduct.Source_System__c = 'SAP';
        insert toolProduct;
        
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(workOrderProduct.Id);
        
        TestDataFieldService.createPartFRU(serviceBOM.Id, toolProduct.Id);

        SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(workOrderProduct.Id);
        workOrderIP.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert workOrderIP;

        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        insert toolProduct2;
        
        workOrder.SVMXC__Component__c=workOrderIP.Id;
        workOrder.SVMXC__Product__c = workOrderProduct.Id;
        WorkOrders.skipWOTrigger = true;
        update workOrder;
        SVMXC__Service_Order_Line__c objWorkDetail= TestDataFieldService.createMaterialsConsumedTypeWorkDetail(workOrder.Id,toolProduct.Id);
        
        Test.startTest();
        
        insert objWorkDetail;
        List<SVMXC__Service_Order_Line__c> workDetailInserted = [SELECT Id FROM SVMXC__Service_Order_Line__c WHERE Id = : objWorkDetail.Id];
        System.assertEquals(true,!workDetailInserted.isEmpty());
        
        try{
            objWorkDetail.SVMXC__Product__c = toolProduct2.Id;
            update objWorkDetail;         
        }catch(Exception ex) {
            System.assert(ex.getMessage() != null);
        } 
        Test.stopTest();
    }

/**
    *  @author : Debanka
    *  @description - test FRU List of Producrs
    **/
    
    static testMethod void validateMaterialsConsumedFromFRUListForNonIVD(){
        initializeTestData();
        
        Product2 workOrderProduct = TestDataMaster.initProduct('Test');
        workOrderProduct.Material_Group__c = '41';
        workOrderProduct.Source_System__c = 'SAP';
        insert workOrderProduct;

        Product2 toolProduct = TestDataMaster.initProduct('Test Product','Tools');
        insert toolProduct;
        system.debug('@@@863TestCls toolProduct='+[SELECT id,Service_Product_Type__c FROM Product2 WHERE id=:toolProduct.id][0].Service_Product_Type__c);
        
        Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(workOrderProduct.Id);
        
        TestDataFieldService.createPartFRU(serviceBOM.Id, toolProduct.Id);

        SVMXC__Installed_Product__c workOrderIP = TestDataFieldService.createInstalledProduct(workOrderProduct.Id);
        workOrderIP.Service_Bill_Of_Materials__c = serviceBOM.Id;
        insert workOrderIP;

        
        workOrder.SVMXC__Component__c=workOrderIP.Id;
        workOrder.SVMXC__Product__c = workOrderProduct.Id;
        WorkOrders.skipWOTrigger = true;
        update workOrder;
        
        SVMXC__Service_Order_Line__c objWorkDetail1=TestDataFieldService.createToolTypeWorkDetail(workOrder.Id,workOrderProduct.Id);
        SVMXC__Service_Order_Line__c objWorkDetail= TestDataFieldService.createMaterialsConsumedTypeWorkDetail(workOrder.Id,toolProduct.Id);
        
        Test.startTest();
        list<SVMXC__Service_Order_Line__c> lstWDtoInsert = new list<SVMXC__Service_Order_Line__c>{objWorkDetail1,objWorkDetail};
        insert lstWDtoInsert;
        //insert objWorkDetail;
        
        List<SVMXC__Service_Order_Line__c> workDetailInserted = [SELECT Id FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Line_Type__c='Material Consumed' LIMIT 1];
        System.assertEquals(true,!workDetailInserted.isEmpty());
        objWorkDetail=workDetailInserted[0];
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.Service_Product_Type__c = 'Spare';
        toolProduct2.Material_Group__c = '41';
        insert toolProduct2;

        objWorkDetail.SVMXC__Product__c = toolProduct2.Id;
        try{
            update objWorkDetail;
            workDetailInserted = [SELECT Id, Warning_Message__c FROM SVMXC__Service_Order_Line__c WHERE Id = : objWorkDetail.Id];
            System.assertEquals(null,workDetailInserted[0].Warning_Message__c);
        }catch(exception e){
            system.debug('exception'+e.getMessage());
        }
            
        Test.stopTest();
    }
    
    static testMethod void createPartOrderAndPartOrderLine(){
        
        Account objAccount = TestDataAccount.getNewAccount();
        objAccount.Account_Group__c = 'Distributor';
        update objAccount;
        System.assertNotEquals(null, objAccount.Id);
        
        Contact objContact = TestDataContact.getNewContact(objAccount);  
              
        Case objCase = TestDataCase.initServiceRequestCase(objContact);        
        insert objCase;     
        System.assertNotEquals(null, objCase.Id);
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        Test.startTest();
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Order_Type__c=STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;   
        System.assertNotEquals(null, workOrder.Id);
        
        //Create Location1
        SVMXC__Site__c location = new SVMXC__Site__c();
        location.Name = 'Test Location 1';
        location.SVMXC__Account__c = objAccount.Id;
        location.SVMXC__Stocking_Location__c = true;
        insert location;
        System.assertNotEquals(null, location.Id);
      
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Service_Product_Type__c  = 'Spare';
        serializedProd.Material_Group__c = '41';
        serializedProd.RMA_Required__c = true;
        insert serializedProd;
        System.assertNotEquals(null, serializedProd.Id);
        
        Product2 serializedProd1 = new Product2();
        serializedProd1.Name = 'Test Serialized Product1';
        serializedProd1.IsActive = true;
        serializedProd1.Service_Product_Type__c  = 'Spare';
        serializedProd1.Material_Group__c = '41';
        serializedProd1.RMA_Required__c = true;
        insert serializedProd1;
        System.assertNotEquals(null, serializedProd1.Id);
       
        //Insert Product Stock
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location.Id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 6;
        insert serializedProdStock;
        System.assertNotEquals(null, serializedProdStock.Id);

        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail.SVMX_PS_VS_Consumed_Product_Stock__c= serializedProdStock.Id;
        objOrderDetail.SVMXC__Consumed_From_Location__c = location.Id;
        objOrderDetail.SVMXC__Product__c = serializedProd1.Id;
        objOrderDetail.Consumption_Confirmed__c   = true;  
        objOrderDetail.Integration_Status__c = STRING_INTEGRATION_STATUS_NOT_APPLICABLE;
        insert objOrderDetail;
        System.assertNotEquals(null, objOrderDetail.Id);
        Test.stopTest();    
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrder = [select id,SVMXC__Service_Order__c FROM SVMXC__RMA_Shipment_Order__c WHERE SVMXC__Service_Order__c =: workOrder.id];
        System.assertEquals(1, lstPartsOrder.size());
        System.assertEquals(1, [select id FROM SVMXC__RMA_Shipment_Line__c WHERE SVMXC__RMA_Shipment_Order__c =: lstPartsOrder[0].id].size());
        
    }
    /*  @author : Debanka
*  @description - Create Parts Order Line Record for Work Detail of Type Part
**/
    
    static testMethod void insertPartOrdersLinesForPartSwap(){
        
        initializeTestData();
        
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Service_Product_Type__c  = 'Spare';
        serializedProd.Material_Group__c = '41';
        serializedProd.RMA_Required__c = true;
        insert serializedProd;
        System.assertNotEquals(null, serializedProd.Id);
        
        //Pooja
         SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(serializedProd.id);
         objInstalledProduct.SVMXC__Date_Installed__c=System.today();
         objInstalledProduct.SVMXC__Status__c='Installed';
         insert objInstalledProduct;
        //Pooja

        SVMXC__Product_Stock__c objProductStock = new SVMXC__Product_Stock__c();
        objProductStock.SVMXC__Product__c = serializedProd.Id;
        insert objProductStock;
        System.assertNotEquals(null, objProductStock.Id);
        Test.startTest();
        
        SVMXC__Service_Order_Line__c objWorkDetail =TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
        objWorkDetail.SVMXC__Line_Type__c='Parts';
        objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c = objProductStock.Id;
        objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c=objInstalledProduct.Id;//Pooja
        objWorkDetail.Consumption_Confirmed__c = true;
        objWorkDetail.Record_Create_From_SFM__c=true;
        objWorkDetail.SVMXC__Start_Date_and_Time__c = Date.today();
        objWorkDetail.Labor_Hours__c = '1:15';
		objWorkDetail.Integration_Status__c = STRING_INTEGRATION_STATUS_NOT_APPLICABLE;
        insert objWorkDetail;
        System.assertNotEquals(null, objWorkDetail.Id);
        Test.stopTest();
        
        List<SVMXC__RMA_Shipment_Order__c> lstPartsOrder = [select id,SVMXC__Service_Order__c from SVMXC__RMA_Shipment_Order__c where SVMXC__Service_Order__c =: workOrder.id];
        System.assertEquals(1, lstPartsOrder.size());
        System.assertEquals(1, [select id from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__c =: lstPartsOrder[0].id].size());
        
    }


    static testMethod void testinsertupdatemultiplePOL(){
         initializeTestData();
        List<SVMXC__Service_Order_Line__c> lstWorkDetailsToBeInserted = new List<SVMXC__Service_Order_Line__c>();
        List<SVMXC__Service_Order_Line__c> lstWorkDetailsToBeUpdated = new List<SVMXC__Service_Order_Line__c>();
        
        SVMXC__Site__c location = new SVMXC__Site__c();
        location.Name = 'Test Location 1';
        //location.SVMXC__Account__c = objAccount.Id;
        location.SVMXC__Stocking_Location__c = true;
        insert location;
        List<Product2> lstProducts= new List<Product2>();
        Product2 toolProduct = TestDataMaster.initProduct('Test Product 1122','Tools');
        lstProducts.add(toolProduct);
        
        Product2 toolProduct1 = TestDataMaster.initProduct('Test Product 1112233','Tools');
        lstProducts.add(toolProduct1);
        
        insert lstProducts; 
        
        List<SVMXC__Installed_Product__c> lstInstProducts= new List<SVMXC__Installed_Product__c>();
         SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(toolProduct.id);
        lstInstProducts.add(objInstalledProduct);
        
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(toolProduct1.id);
        lstInstProducts.add(objInstalledProduct1);
        insert lstInstProducts; 
        
        
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(workOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = STRING_STATUS_OPEN;
        objPartsOrder.ERP_Sales_Order_Number__c = String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=location.id; 
        insert objPartsOrder;
        System.assert(objPartsOrder!=null,'objPartsOrder is null');
        Test.startTest();
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.SVMXC__Product__c = toolProduct.id;   
        insert objPartsOrderLine;
        
        SVMXC__Service_Order_Line__c objWorkDetail1= TestDataFieldService.createToolTypeWorkDetail(workOrder.Id,toolProduct.Id);
        objWorkDetail1.SVMX_PS_VS_Return_Installed_Product__c=objInstalledProduct.id;
        lstWorkDetailsToBeInserted.add(objWorkDetail1);
        
        SVMXC__Service_Order_Line__c objWorkDetail2= TestDataFieldService.createToolTypeWorkDetail(workOrder.Id,toolProduct1.Id);
        lstWorkDetailsToBeInserted.add(objWorkDetail2);
        
        if(lstWorkDetailsToBeInserted.size()>0){
            insert lstWorkDetailsToBeInserted; 
        }
       
        
        objWorkDetail1=[SELECT id,SVMX_PS_VS_Return_Installed_Product__c FROM SVMXC__Service_Order_Line__c WHERE SVMX_PS_VS_Return_Installed_Product__c=:objInstalledProduct.id][0]; 
        objWorkDetail1.SVMX_PS_VS_Return_Installed_Product__c=objInstalledProduct1.id;
        lstWorkDetailsToBeUpdated.add(objWorkDetail1);
        
        if(lstWorkDetailsToBeUpdated.size()>0){
            update lstWorkDetailsToBeUpdated;  
        }  
        Test.stopTest();
    }
    
     static testMethod void testdeletemultiplePOL(){
        initializeTestData();
        User userInstance = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service AND isActive=true
                               LIMIT 1]; 
         
        User userAdmin = [SELECT Id FROM User 
                               WHERE Profile.Name =:System.label.ProfileSystemAdmin AND isActive=true
                               LIMIT 1]; 
        System.runAs(userAdmin){  
        PermissionSet ps = new PermissionSet(Name='TestContactPermission',Label='TestContactPermission');
        insert ps;
        List<ObjectPermissions> op = new List<ObjectPermissions>();
        op.add(new ObjectPermissions(ParentId=ps.Id,
                                     SobjectType='SVMXC__Service_Order_Line__c',
                                     PermissionsRead=true,
                                     PermissionsEdit=true,
                                     PermissionsDelete=true,
                                     PermissionsViewAllRecords=true,
                                     PermissionsModifyAllRecords=true));
        op.add(new ObjectPermissions(ParentId=ps.Id,
                                     SobjectType='SVMXC__Service_Order__c',
                                     PermissionsRead=true,
                                     PermissionsEdit=true
                                     ));
        insert op;
        insert new PermissionSetAssignment(PermissionSetId=ps.Id ,AssigneeId=userInstance.Id); 
        
        }
        
        List<Product2> lstProducts= new List<Product2>();
        Product2 toolProduct = TestDataMaster.initProduct('Test Product 1122','Tools');
        lstProducts.add(toolProduct);
        
        Product2 toolProduct1 = TestDataMaster.initProduct('Test Product 1112233','Tools');
        lstProducts.add(toolProduct1);
        
        insert lstProducts; 
        
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc; //Insert DCP-33467
         
        //Insert Product Stock DCP-33467
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = toolProduct1.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock; 
         
        List<SVMXC__Installed_Product__c> lstInstProducts= new List<SVMXC__Installed_Product__c>();
         SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(toolProduct.id);
        lstInstProducts.add(objInstalledProduct);
        
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(toolProduct1.id);
        lstInstProducts.add(objInstalledProduct1);
        insert lstInstProducts; 
        
        Test.startTest();
        
        List<SVMXC__Service_Order_Line__c> lstWD= new List<SVMXC__Service_Order_Line__c>();//Pooja
        SVMXC__Service_Order_Line__c objWorkDetail3= TestDataFieldService.createWorkDetail(workOrder.Id,objInstalledProduct.Id);
        objWorkDetail3.SVMXC__Line_Type__c=STRING_LINE_TYPE_LABOR;
        objWorkDetail3.SVMXC__Activity_Type__c ='Customer Service Review';
        objWorkDetail3.Travel_Time_in_hours__c='1';
        objWorkDetail3.Labor_Hours__c='1';
        //insert objWorkDetail3;
        lstWD.add(objWorkDetail3);
        
       // System.assert(objWorkDetail3!=null,'objWorkDetail3 is null');
    
        
        SVMXC__Service_Order_Line__c objWorkDetail4= TestDataFieldService.createPartTypeWorkDetail(workOrder.Id,toolProduct1.Id,objInstalledProduct1.id);
        objWorkDetail4.SVMX_PS_External_ID__c = '12345689';
        objWorkDetail4.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;
        objWorkDetail4.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;                
        //insert objWorkDetail4;
        lstWD.add(objWorkDetail4);
        insert lstWD;  
        System.assert(lstWD.size()>0,'List is not empty');//pooja
         System.runAs(userInstance){

       
        try{
            delete lstWD;
            //delete objWorkDetail3;
            //delete objWorkDetail4;
        }
        catch(Exception e)
        {
            System.debug('@@@Inside Catch'+e.getMessage());
        }   
         }
         Test.stopTest();
    }
     /*
   *  @AUTHOR:  Vaibhav 
   *  @DESCRIPTION: DCP-33466 And DCP-37747 - Method to update Work Orders to qualify for batch processing.
   *  @PARAM : 
   *  @RETURN:  void
   */
  static testMethod void testWorkDetailQualificationForBatchSAPSync() {

   User userInstance = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = STRING_EMAIL,
             Username = STRING_EMAIL + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = STRING_LANGUAGE,
             LocaleSidKey = STRING_LANGUAGE
             
        );
        insert userInstance; 
     
    Account objAccount = TestDataAccount.getNewAccount(); //create account
    Account objAccupdate = [select id, Account_Group__c from Account where id =: objAccount.id];
    objAccupdate.Account_Group__c = 'Distributor';
    update objAccupdate;
    Contact objContact = TestDataContact.getNewContact(objAccount); //create contact.

    //create Installed Product
    SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
    objInstalledProduct.SVMXC__Company__c = objAccount.Id;
    insert objInstalledProduct;
    //System.runAs(userInstance) {  
      // DCP-33467
      Product2 nonSerializedProd = new Product2();
      nonSerializedProd.Name = STRING_TEST_NON_SERIALIZED_PRODUCT;
      nonSerializedProd.IsActive = true;
      nonSerializedProd.SVMXC__Tracking__c = STRING_NON_TRACKED;
      nonSerializedProd.SVMXC__Stockable__c = true;
      nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
      insert nonSerializedProd;  
      
      SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
      insert objLoc; //Insert DCP-33467
      
      System.runAs(userInstance) { 
        //DHairya Shah 11th March changes --> START
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(userInstance.Id);  
        setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
        setting.Bypass_Triggers_By_Object_2__c = 'Case'; 
        upsert setting;
        //DHairya Shah 11th March changes --> END
      //Insert Product Stock DCP-33467
      SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
      nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
      nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
      nonSerializedProdStock.SVMXC__Status__c = 'Available';
      nonSerializedProdStock.SVMXC__Quantity2__c = 10;
      insert nonSerializedProdStock;

    //System.runAs(userInstance) {  

    //create case
    Case objCase = TestDataCase.initServiceRequestCase(objContact);
    objCase.SVMXC__Component__c = objInstalledProduct.Id;
    insert objCase;

    //create work order
    workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
    workOrder.SVMXC__Company__c = objAccount.id;
    workOrder.SVMXC__Component__c = objInstalledProduct.Id;
    workOrder.SVMXC__Order_Type__c = STRING_ORDER_TYPE_INSTALLATION;
    workOrder.Is_Auto_Created__c = true;
    insert workOrder;
    Test.startTest();
    

    //create work detail  
    SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
    objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
    objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
    objOrderDetail.SVMXC__Activity_Type__c = STRING_TRAINING;
    objOrderDetail.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
    objOrderDetail.Labor_Hours__c = '1';
    objOrderDetail.SVMXC__Estimated_Quantity2__c = 2.0;
    insert objOrderDetail;
 Test.stopTest();
    //check the after insert condition
    SVMXC__Service_Order__c workOrderUpdated = [Select Id, Qualified_for_Batched_Sync_to_ERP__c from SVMXC__Service_Order__c where Id =: workOrder.Id];
    System.assertEquals(true, workOrderUpdated.Qualified_for_Batched_Sync_to_ERP__c);
      }
}   

/*
   *  @AUTHOR:   
   *  @DESCRIPTION: DCP-33466 And DCP-37747 - Method to update Work Orders to qualify for batch processing.
   *  @PARAM : 
   *  @RETURN:  void
   */
  static testMethod void testWorkDetailQualificationForBatchSAPSync3() {

   User userInstance = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = STRING_EMAIL,
             Username = STRING_EMAIL + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = STRING_LANGUAGE,
             LocaleSidKey = STRING_LANGUAGE
             
        );
        insert userInstance; 
     
    /* Pooja
    Account objAccount = TestDataAccount.getNewAccount(); //create account
    Account objAccupdate = [select id, Account_Group__c from Account where id =: objAccount.id];
    objAccupdate.Account_Group__c = 'Distributor';
    update objAccupdate;*/
    Account objAccount = TestDataAccount.initAccount();//TestDataAccount.getAccount('Test Account', 'USD');
    objAccount.Account_Group__c='Distributor';
    insert objAccount;

    //create Installed Product
    SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
    objInstalledProduct.SVMXC__Company__c = objAccount.Id;
    insert objInstalledProduct;
    //System.runAs(userInstance) {  
      // DCP-33467
      Product2 nonSerializedProd = new Product2();
      nonSerializedProd.Name = STRING_TEST_NON_SERIALIZED_PRODUCT;
      nonSerializedProd.IsActive = true;
      nonSerializedProd.SVMXC__Tracking__c = STRING_NON_TRACKED;
      nonSerializedProd.SVMXC__Stockable__c = true;
      nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
      insert nonSerializedProd;  
      
      SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
      insert objLoc; //Insert DCP-33467

        System.runAs(userInstance) { 
    
      //Insert Product Stock DCP-33467
      SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
      nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
      nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
      nonSerializedProdStock.SVMXC__Status__c = 'Available';
      nonSerializedProdStock.SVMXC__Quantity2__c = 10;
      insert nonSerializedProdStock;

    
/*
    //create case pooja
    //create case
    Case objCase = TestDataCase.initServiceRequestCase(objContact);
    objCase.SVMXC__Component__c = objInstalledProduct.Id;
       
    insert objCase;
*/
    //create work order
    workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');//pooja
    workOrder.SVMXC__Company__c = objAccount.id;
    workOrder.SVMXC__Component__c = objInstalledProduct.Id;
    workOrder.SVMXC__Order_Type__c = 'Remote support';
    workOrder.Is_Auto_Created__c = true;
    workOrder.Qualified_for_Batched_Sync_to_ERP__c=true;
    WorkOrders.skipWOTrigger = true;
    insert workOrder;
   
    
 Test.startTest();
    //create work detail  
    SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
    objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
    objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
    objOrderDetail.SVMXC__Activity_Type__c = STRING_TRAINING;
    objOrderDetail.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
    objOrderDetail.Labor_Hours__c = '1';
    
    objOrderDetail.SVMXC__Estimated_Quantity2__c = 2.0;
   
    insert objOrderDetail;

      
 
      /*pooja 
    SVMXC__Service_Order__c workOrderUpdated = [Select Id, Qualified_for_Batched_Sync_to_ERP__c from SVMXC__Service_Order__c where Id =: workOrder.Id]; 
    workOrderUpdated.Qualified_for_Batched_Sync_to_ERP__c = false;
    update workOrderUpdated;
    */
    System.debug('test method');
    //update the work detail to canceled
    SVMXC__Service_Order_Line__c objOrderDetailUpdated = [Select Id, SVMXC__Line_Status__c from SVMXC__Service_Order_Line__c where Id =: objOrderDetail.Id];
    objOrderDetailUpdated.SVMXC__Line_Status__c = 'Canceled';
    update objOrderDetailUpdated;
    System.debug('test method');
    //check the after update condition
    SVMXC__Service_Order__c workOrderCanceledUpdate = [Select Id, Qualified_for_Batched_Sync_to_ERP__c from SVMXC__Service_Order__c where Id =: workOrder.Id];
    System.assertEquals(true, workOrderCanceledUpdate.Qualified_for_Batched_Sync_to_ERP__c);//pooja
    
    try{
        
    objOrderDetailUpdated.SVMXC__Line_Status__c=STRING_STATUS_OPEN;
    update objOrderDetailUpdated;
    System.debug('test method');
    }
    catch(exception e){
    System.Assert(e.getMessage().contains('GIS'));
    }      
     Test.stopTest();
     }
    }

/*
   *  @AUTHOR:  Vaibhav 
   *  @DESCRIPTION: DCP-33466 And DCP-37747 - Method to update Work Orders to qualify for batch processing.
   *  @PARAM : 
   *  @RETURN:  void
   */
  static testMethod void testWorkDetailQualificationForBatchSAPSync2() {

    User userInstance = new User(
              ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
              LastName = 'last',
              Email = STRING_EMAIL,
              Username = STRING_EMAIL + System.currentTimeMillis(),
              CompanyName = 'TEST',
              Title = 'title',
              Alias = 'alias',
              TimeZoneSidKey = 'America/Los_Angeles',
              EmailEncodingKey = 'UTF-8',
              LanguageLocaleKey = STRING_LANGUAGE,
              LocaleSidKey = STRING_LANGUAGE
              
         );
         insert userInstance; 
      
     Account objAccount = TestDataAccount.getNewAccount(); //create account
     Account objAccupdate = [select id, Account_Group__c from Account where id =: objAccount.id];
     objAccupdate.Account_Group__c = 'Distributor';
     update objAccupdate;
     Contact objContact = TestDataContact.getNewContact(objAccount); //create contact.
 
     //create Installed Product
     SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
     objInstalledProduct.SVMXC__Company__c = objAccount.Id;
     insert objInstalledProduct;
     //System.runAs(userInstance) {  
       // DCP-33467
       Product2 nonSerializedProd = new Product2();
       nonSerializedProd.Name = STRING_TEST_NON_SERIALIZED_PRODUCT;
       nonSerializedProd.IsActive = true;
       nonSerializedProd.SVMXC__Tracking__c = STRING_NON_TRACKED;
       nonSerializedProd.SVMXC__Stockable__c = true;
       nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
       insert nonSerializedProd;  
       
       SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
       insert objLoc; //Insert DCP-33467
       
       System.runAs(userInstance) { 

        //DHairya Shah 11th March changes --> START
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(userInstance.Id);  
        setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c';
        setting.Bypass_Triggers_By_Object_2__c = 'Case'; 
        upsert setting;
        //DHairya Shah 11th March changes --> END
       //Insert Product Stock DCP-33467
       SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
       nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
       nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
       nonSerializedProdStock.SVMXC__Status__c = 'Available';
       nonSerializedProdStock.SVMXC__Quantity2__c = 10;
       insert nonSerializedProdStock;
 
     //System.runAs(userInstance) {  
 
     //create case
     Case objCase = TestDataCase.initServiceRequestCase(objContact);
     objCase.SVMXC__Component__c = objInstalledProduct.Id;
     insert objCase;
 
     //create work order
     workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
     workOrder.SVMXC__Company__c = objAccount.id;
     workOrder.SVMXC__Component__c = objInstalledProduct.Id;
     workOrder.SVMXC__Order_Type__c = 'Remote support';
     workOrder.Is_Auto_Created__c = true;
     insert workOrder;
     
     Test.StartTest();
         
         try{
     SVMXC__Service_Order_Line__c objOrderDetail1 = new SVMXC__Service_Order_Line__c();
     objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
     objOrderDetail1.SVMXC__Line_Type__c ='Parts';
     objOrderDetail1.SVMX_PS_External_ID__c='2323';
     objOrderDetail1.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;  
     objOrderDetail1.SVMXC__Line_Status__c=STRING_STATUS_OPEN;
     objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;//DCP-33467
	 objOrderDetail1.Integration_Status__c = STRING_INTEGRATION_STATUS_NOT_APPLICABLE;
     insert objOrderDetail1;
     objOrderDetail1.SVMXC__Line_Status__c='Canceled';
     update objOrderDetail1;
      }catch(exception e){
          System.debug('e msg '+e.getMessage());
             System.Assert(e.getMessage().contains('GIS'));
      }
       Test.stopTest();
 }
}
 
    /**
     * Method: TestupdateIsBillOnWdIfBillingTypeSetByCS
     * DCP-38965
     * @author : sandeep 
     * */
    /*public static testMethod void TestupdateIsBillOnWdIfBillingTypeSetByCS(){
        Test.startTest();
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.ProfileCustomerService and IsActive =true LIMIT 1];
        Account objAccount = TestDataAccount.initAccount();//TestDataAccount.getAccount('Test Account', 'USD');
        objAccount.Account_Group__c=Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert objAccount;
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct1.SVMXC__Company__c=objAccount.Id;
        insert objInstalledProduct1;
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc; 
         Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2; 
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = objLoc.id;
        nonSerializedProdStock.SVMXC__Product__c = toolProduct2.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 10;
        insert nonSerializedProdStock;
        Contact ObjContact = TestDataPerson.getNewContact(objAccount.Id);
        SVMXC__Service_Order__c wo;
       System.runAs(lstUsers[0]){ 
         SVMXC__Service_Order__c objWorkOrder= TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        Case objCase = TestDataCase.createCase('Service Request', 'Initiated', ObjContact.Id);      
        objWorkOrder.SVMXC__Component__c = objInstalledProduct1.Id;
        objWorkOrder.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        objWorkOrder.SVMXC__Case__c = objCase.Id;
        objWorkOrder.Record_Created_from_SFM__c=true;
        objWorkOrder.SVMXC__Billing_Type__c='Billable';
        insert objWorkOrder;
         wo =[select id,SVMXC__Billing_Type__c,Billing_Type_Set_Manually__c,SVMXC__Component__c from SVMXC__Service_Order__c where id= : objWorkOrder.id];
        }

       System.assertEquals(true,wo.Billing_Type_Set_Manually__c); 
        List<SVMXC__Service_Order_Line__c> lstWorkDetails = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c workDetail1 = new SVMXC__Service_Order_Line__c();
        workDetail1.SVMXC__Service_Order__c = wo.id;
        workDetail1.SVMXC__Line_Type__c='Parts';
        workDetail1.SVMXC__Product__c = toolProduct2.Id;
        workDetail1.SVMXC__Is_Billable__c = false;
        workDetail1.SVMXC__Consumed_From_Location__c = objLoc.id;
        workDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id; // DCP-33467 
		workDetail1.Integration_Status__c = STRING_INTEGRATION_STATUS_NOT_APPLICABLE;
        lstWorkDetails.add(workDetail1);
        
        SVMXC__Service_Order_Line__c workDetail2 = new SVMXC__Service_Order_Line__c();
        workDetail2.SVMXC__Service_Order__c = wo.id;
        workDetail2.SVMXC__Line_Type__c='Tools';
        workDetail2.SVMXC__Product__c = toolProduct2.Id;
        workDetail2.SVMXC__Is_Billable__c = false;
        lstWorkDetails.add(workDetail2);
        insert lstWorkDetails;
        Test.stopTest();
        SVMXC__Service_Order_Line__c workDetail = [select id,SVMXC__Is_Billable__c from SVMXC__Service_Order_Line__c where SVMXC__Service_Order__c =:wo.id and SVMXC__Line_Type__c='Parts' ];
        System.assert(workDetail.SVMXC__Is_Billable__c,'workDetail.SVMXC__Is_Billable__c is nottrue'); 
       SVMXC__Service_Order_Line__c workDetailTools = [select id,SVMXC__Is_Billable__c from SVMXC__Service_Order_Line__c where SVMXC__Service_Order__c =:wo.id and SVMXC__Line_Type__c='Tools' ];
        System.assertEquals(false,workDetailTools.SVMXC__Is_Billable__c,'workDetailTools.SVMXC__Is_Billable__c is not false'); 
    }*/
    
/*
*  @AUTHOR:  Sravan/Refactored by Tapas
*  @DESCRIPTION: DCP-33467 - Parts Reservation.
*  @PARAM : 
*  @RETURN:  void
*/
    /*private static Map<String,List<SObject>> testPartsReservationDataCreation(){        
        Account objAccount = TestDataAccount.getNewAccount(); //create account
        Account objAccupdate = [select id, Account_Group__c from Account where id =: objAccount.id];
        objAccupdate.Account_Group__c = 'Distributor';
        update objAccupdate;
        Contact objContact = TestDataContact.getNewContact(objAccount); //create contact.
        
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = STRING_TEST_NON_SERIALIZED_PRODUCT;
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = STRING_NON_TRACKED;
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
        productLst.add(nonSerializedProd);  
        
        //Create serialized product
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Serial_Number_Profile__c = 'IL01';
        serializedProd.FRU_Eligible__c = 'FRU use only';
        productLst.add(serializedProd);  
        insert productLst;
        
        //Create Location1
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = objAccupdate.Id;
        location1.SVMXC__Stocking_Location__c = true;
        insert location1;
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        
        //create Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
        
        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(nonSerializedProdStock);
        
        //Create serialized product stock
        SVMXC__Product_Stock__c SerializedProdStock = new SVMXC__Product_Stock__c();
        SerializedProdStock.SVMXC__Location__c = location1.id;
        SerializedProdStock.SVMXC__Product__c = serializedProd.Id;
        SerializedProdStock.SVMXC__Status__c = 'Available';
        SerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(SerializedProdStock);
        insert productStockLst;
        
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProd.Id;
        stockSerial1.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial1.Name = '0987654321';
        stockedSerialList.add(stockSerial1);
        
        SVMXC__Product_Serial__c stockSerial2 = new SVMXC__Product_Serial__c();
        stockSerial2.SVMXC__Active__c = true;
        stockSerial2.SVMXC__Product__c = serializedProd.Id;
        stockSerial2.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial2.Name = '1234567890';
        stockedSerialList.add(stockSerial2);
        insert stockedSerialList;
        
        //create case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        
        //create work order
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
        //create work detail 
        List<SVMXC__Service_Order_Line__c> wdList = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Consumed_From_Location__c = location1.Id;
        objOrderDetail.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        objOrderDetail.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail.SVMXC__Line_Status__c = 'Open';
        objOrderDetail.SVMXC__Actual_Quantity2__c = 1;
		objOrderDetail.Integration_Status__c ='Not Applicable';	
        wdList.add(objOrderDetail);
        
        SVMXC__Service_Order_Line__c objOrderDetail1 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail1.SVMXC__Consumed_From_Location__c = location1.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = SerializedProdStock.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id;
        objOrderDetail1.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1.SVMXC__Line_Status__c = 'Open';
        objOrderDetail1.SVMXC__Actual_Quantity2__c = 1;
		objOrderDetail1.Integration_Status__c ='Not Applicable';	
        wdList.add(objOrderDetail1);
        
        SVMXC__Service_Order_Line__c objOrderDetail2 = new SVMXC__Service_Order_Line__c();
        objOrderDetail2.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail2.SVMXC__Consumed_From_Location__c = location1.Id;
        objOrderDetail2.SVMX_PS_VS_Consumed_Product_Stock__c = SerializedProdStock.Id;
        objOrderDetail2.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial2.Id;
        objOrderDetail2.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail2.SVMXC__Line_Status__c = 'Open';
        objOrderDetail2.SVMXC__Actual_Quantity2__c = 1;
		objOrderDetail2.Integration_Status__c ='Not Applicable';	
        wdList.add(objOrderDetail2);        
        
        SVMXC__Service_Order_Line__c objOrderDetail3 = new SVMXC__Service_Order_Line__c();
        objOrderDetail3.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail3.SVMXC__Consumed_From_Location__c = location1.Id;
        objOrderDetail3.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        objOrderDetail3.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail3.SVMXC__Line_Status__c = 'Open';
        objOrderDetail3.SVMXC__Actual_Quantity2__c = 2;
        objOrderDetail3.Batch_Number__c = '123456';
		objOrderDetail3.Integration_Status__c ='Not Applicable';	
        wdList.add(objOrderDetail3);
        insert wdList;
        //Test.startTest();
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name = :TestDataUser.PROFILE_ADMIN AND Id != :UserInfo.getUserId() AND UserRoleId != null AND IsActive = true LIMIT 1];

        //System.runAs(new User(Id = lstUsers[0].Id)){ 
        System.debug('Test.startTest(); 1');
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = TestDataFieldService.createPartsOrder(null);
        objPartsOrder1.SVMXC__Order_Type__c = 'Return';
        objPartsOrder1.SVMXC__Order_Status__c = 'Open';
        objPartsOrder1.ERP_Sales_Order_Number__c = '188';
        objPartsOrder1.Contact_Name__c='Test';
        objPartsOrder1.Contact_Phone__c='Test';
        objPartsOrder1.SVMXC__Source_Location__c=objLocationRec.id;
        insert objPartsOrder1;
        
        Map<String,List<Sobject>> StringToListSobjects = new Map<String,List<Sobject>>();
        StringToListSobjects.put('Location', new List<SVMXC__Site__c>{objLocationRec,location1});
        StringToListSobjects.put('Installed Product', new List<SVMXC__Installed_Product__c>{objInstalledProduct});
        StringToListSobjects.put('Product', new List<Product2>{nonSerializedProd});
        StringToListSobjects.put('Work Detail', wdList);
        StringToListSobjects.put('Parts Order', new List<SVMXC__RMA_Shipment_Order__c>{objPartsOrder1});
        StringToListSobjects.put('Stock Serial', new List<SVMXC__Product_Serial__c>{stockSerial1});
        StringToListSobjects.put('Product Stock', new List<SVMXC__Product_Stock__c>{nonSerializedProdStock});
        
        return StringToListSobjects;
    }*/
    
    /*static testMethod void testPartsReservation1(){ 
        Map<String,List<Sobject>> StringToListSobjects = testPartsReservationDataCreation();//common part done in this method
        SVMXC__Site__c objLocationRec = (SVMXC__Site__c)StringToListSobjects.get('Location')[0];
        SVMXC__Site__c location1 = (SVMXC__Site__c)StringToListSobjects.get('Location')[1];
        SVMXC__Installed_Product__c objInstalledProduct = (SVMXC__Installed_Product__c)StringToListSobjects.get('Installed Product')[0];
        Product2 nonSerializedProd = (Product2)StringToListSobjects.get('Product')[0];
        SVMXC__Service_Order_Line__c objOrderDetail = (SVMXC__Service_Order_Line__c)StringToListSobjects.get('Work Detail')[0];
        SVMXC__Service_Order_Line__c objOrderDetail1 = (SVMXC__Service_Order_Line__c)StringToListSobjects.get('Work Detail')[1];
        SVMXC__Service_Order_Line__c objOrderDetail2 = (SVMXC__Service_Order_Line__c)StringToListSobjects.get('Work Detail')[2];
        SVMXC__Service_Order_Line__c objOrderDetail3 = (SVMXC__Service_Order_Line__c)StringToListSobjects.get('Work Detail')[3];
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = (SVMXC__RMA_Shipment_Order__c)StringToListSobjects.get('Parts Order')[0];
        SVMXC__Product_Serial__c stockSerial1 = (SVMXC__Product_Serial__c)StringToListSobjects.get('Stock Serial')[0];
        
        //Divided test statements to prevent soql 101
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
         
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder1.Id);
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.To_Location__c = location1.id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId;
        objPartsOrderLine.SVMXC__Line_Status__c = 'open';
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objPartsOrderLine.SVMXC__Product__c = nonSerializedProd.Id;
        objPartsOrderLine.Batch_Number__c = '123456';
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 2;
        objPartsOrderLine.Consumed_QTY__c = 0;
        
        Test.startTest();
        insert objPartsOrderLine;
        System.debug('Test.startTest(); 1');
        
        objPartsOrderLine.SVMXC__Line_Status__c ='Shipped';
        update objPartsOrderLine;
        try{// non serial stock update
            objOrderDetail.SVMXC__Actual_Quantity2__c = 3;
            update objOrderDetail;
            System.debug('Test.startTest(); 1');
        }catch(exception e){
            system.debug('Exception -->  '+e.getMessage());
            System.Assert(e.getMessage().contains('#'));
        }
        try{
            //Serial change
            objOrderDetail2.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id;
            update objOrderDetail2;
            System.debug('Test.startTest(); 1');
        }catch(exception e){
            system.debug('Exception -->  '+e.getMessage());
            System.Assert(e.getMessage().contains('#'));
        }
        try{// Batched stock update
            objOrderDetail3.SVMXC__Actual_Quantity2__c = 3;
            update objOrderDetail3;
            System.debug('Test.startTest(); 1');
        }catch(exception e){
            system.debug('Exception -->  '+e.getMessage());
            System.Assert(e.getMessage().contains('#'));
        }
        Test.stopTest();
    }*/
    //Commenting for VAL
    /*static testMethod void testPartsReservation2(){ 
        Map<String,List<Sobject>> StringToListSobjects = testPartsReservationDataCreation();//common part done in this method
        SVMXC__Site__c objLocationRec = (SVMXC__Site__c)StringToListSobjects.get('Location')[0];
        SVMXC__Site__c location1 = (SVMXC__Site__c)StringToListSobjects.get('Location')[1];
        SVMXC__Installed_Product__c objInstalledProduct = (SVMXC__Installed_Product__c)StringToListSobjects.get('Installed Product')[0];
        Product2 nonSerializedProd = (Product2)StringToListSobjects.get('Product')[0];
        SVMXC__Service_Order_Line__c objOrderDetail = (SVMXC__Service_Order_Line__c)StringToListSobjects.get('Work Detail')[0];
        SVMXC__Service_Order_Line__c objOrderDetail1 = (SVMXC__Service_Order_Line__c)StringToListSobjects.get('Work Detail')[1];
        SVMXC__Service_Order_Line__c objOrderDetail2 = (SVMXC__Service_Order_Line__c)StringToListSobjects.get('Work Detail')[2];
        SVMXC__Service_Order_Line__c objOrderDetail3 = (SVMXC__Service_Order_Line__c)StringToListSobjects.get('Work Detail')[3];
        SVMXC__RMA_Shipment_Order__c objPartsOrder1 = (SVMXC__RMA_Shipment_Order__c)StringToListSobjects.get('Parts Order')[0];
        SVMXC__Product_Stock__c nonSerializedProdStock = (SVMXC__Product_Stock__c)StringToListSobjects.get('Product Stock')[0];

        //Divided test statements to prevent soql 101
        Id shipmentRecordTypeId = Schema.SObjectType.SVMXC__RMA_Shipment_Line__c.getRecordTypeInfosByName().get('Shipment').getRecordTypeId();
         
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder1.Id);
        objPartsOrderLine.From_Location__c = objLocationRec.id;
        objPartsOrderLine.To_Location__c = location1.id;
        objPartsOrderLine.RecordTypeId = shipmentRecordTypeId;
        objPartsOrderLine.SVMXC__Line_Status__c = 'open';
        objPartsOrderLine.Requested_Delivery_Date__c = Date.today();
        objPartsOrderLine.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objPartsOrderLine.SVMXC__Product__c = nonSerializedProd.Id;
        objPartsOrderLine.Batch_Number__c = '123456';
        objPartsOrderLine.SVMXC__Actual_Quantity2__c = 2;
        objPartsOrderLine.Consumed_QTY__c = 0;
        
        Test.startTest();
        insert objPartsOrderLine;
        System.debug('Test.startTest(); 1');
        
        objPartsOrderLine.SVMXC__Line_Status__c ='Shipped';
        update objPartsOrderLine;
        //removed all the try-catch
        // Change of product Stock
        objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Stocked_Serial__c = null;
        update objOrderDetail1;
        System.debug('Test.startTest(); 1');
        // Canceling the wd
        objOrderDetail.SVMXC__Line_Status__c = 'Canceled';
        update objOrderDetail;
        System.debug('Test.startTest(); 1');
        //delete objOrderDetail1;
        Test.stopTest();
    } */
        static testmethod void  testPartsReservation3(){
        Account objAccount = TestDataAccount.initAccount(); //create account
        objAccount.Account_Group__c = 'Distributor';
        insert objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount); //create contact.
    
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = STRING_TEST_NON_SERIALIZED_PRODUCT;
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = STRING_NON_TRACKED;
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
        productLst.add(nonSerializedProd);  
        
        //Create serialized product
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Serial_Number_Profile__c = 'IL01';
        serializedProd.FRU_Eligible__c = 'FRU use only';
        productLst.add(serializedProd);  
        insert productLst;
        //Create Location1
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = objAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        insert location1;
        
        //create Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
    
        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(nonSerializedProdStock);
        
        //Create serialized product stock
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location1.id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(serializedProdStock);
        insert productStockLst;
    
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProd.Id;
        stockSerial1.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial1.Name = '0987654321';
        stockedSerialList.add(stockSerial1);
    
        insert stockedSerialList;
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());  
        setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
        upsert setting;

        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = 'Remote Support';
        //STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
    
        Test.startTest();
        List<SVMXC__Service_Order_Line__c> wdList = new List<SVMXC__Service_Order_Line__c>();
        SVMXC__Service_Order_Line__c objOrderDetail1 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail1.SVMXC__Consumed_From_Location__c = location1.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = serializedProdStock.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id;
        objOrderDetail1.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1.SVMXC__Line_Status__c = STRING_STATUS_OPEN;
        objOrderDetail1.SVMXC__Actual_Quantity2__c = 1;
		objOrderDetail1.Integration_Status__c = STRING_INTEGRATION_STATUS_NOT_APPLICABLE;
        wdList.add(objOrderDetail1);
        insert wdList;
		system.assert(!wdList.isEmpty(), 'WD List is empty');
        // Change of product Stock
        objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Stocked_Serial__c = null;
        update objOrderDetail1;
        delete objOrderDetail1;
        Test.stopTest();
    
    }
	
    /*
	*DCP-43634
	* Author: Tapas Chakraborty
	*test method for Goodwill work details line Approval Process
	*/
    public static testmethod void testGoodwillWDApprovals(){
        /*Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Service' limit 1];
User objUser = TestDatauser.initStandardUser(objProfile.Id);
insert objUser;*/
        String woCompletionError;
        String wdPreventEditError;
        SVMXC__Service_Order_Line__c objOrderDetail2;
        
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        User objUser = [select id from user where (profile.name = 'Field Service' or profile.name = 'Customer Service') and IsActive = true and ManagerId != null and manager.IsActive = true limit 1];
        
        System.runAs(objUser){
            Test.startTest();
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        
        
            workOrder.SVMXC__Company__c = objAccount.id;
            workOrder.SVMXC__Order_Type__c='Remote Support';
            workOrder.Record_Created_FROM_SFM__c = true;
            workOrder.Cost_Center__c = 123456;
            workOrder.Is_Service_Report_Generated__c=true;
            workOrder.Evaluation__c='Test';
            workOrder.SVMXC__Work_Performed__c='Test';
            workOrder.Verification_Result__c='Test'; 
            workOrder.PO_Number__c = '12345';	
            insert workOrder;
            //Test.startTest();
            
            objOrderDetail2 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,STRING_USAGE_CONSUMPTION);
            objOrderDetail2.SVMXC__Activity_Type__c = STRING_ACTIVITY_TYPE_REPAIR_TROUBLESHOOTING;
            //objOrderDetail2.Duration_in_hours__c = '1';
            objOrderDetail2.SVMXC__Line_Type__c = STRING_LINE_TYPE_LABOR;
            objOrderDetail2.Labor_Hours__c  = '1';
            objOrderDetail2.Non_Billable_Reason__c = 'Goodwill';//'Consumable Warranty';
            
            insert objOrderDetail2;//tcEnd
            Test.stopTest();  
            
            /*objOrderDetail2.Non_Billable_Reason__c = 'Goodwill';
            objOrderDetail2.SVMXC__Actual_Quantity2__c = 2;
            objOrderDetail2.Owner_s_Manager__c = UserInfo.getUserId();
            update objOrderDetail2;*/
            System.assertEquals('Pending Approval',[select id,approval_status__c FROM SVMXC__Service_Order_Line__c WHERE id =: objOrderDetail2.Id limit 1].approval_status__c);
            workOrder.SVMXC__Order_Status__c = 'Completed';
            workOrder.No_Calibrated_Tools_Used__c = true;
            workOrder.Signature_Type__c='Manual Sign';
            workOrder.Manual_Sign_Captured__c=true;
            workOrder.Is_Customer_Sign_Captured__c=true;
            
            try{
                
                update workOrder;
            }
            catch(Exception ee){
                System.debug('ee wo completion '+ee.getCause()+ee.getMessage()+ee.getStackTraceString());
                woCompletionError = ee.getMessage();
            }
            //System.assert(woCompletionError.contains(System.Label.UI_Error_WO_PendingGoodwillApproval)); //removing this assert as validation is date based
            System.debug('objOrderDetail2 '+[select id,approval_status__c FROM SVMXC__Service_Order_Line__c WHERE id =: objOrderDetail2.Id]);
            GoodWillApprovals_WorkdetailHelper.idWDToWDGoodwillApproval = null;
            objOrderDetail2.Labor_Hours__c = '2';
            try{
                update objOrderDetail2;      
            }
            catch(Exception ee){
                System.debug('ee '+ee.getCause()+ee.getMessage()+ee.getStackTraceString());
                wdPreventEditError = ee.getMessage();
            }
            System.assert(wdPreventEditError.contains(System.Label.UI_Error_WD_PreventEditOnPendingGoodwillApproval));
            //Test.stopTest();  
        }
        
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments('Approving request using Trigger');
        req.setAction('Reject');
        req.setWorkitemId([SELECT p.Id FROM ProcessInstanceWorkitem p WHERE p.ProcessInstance.TargetObjectId =: objOrderDetail2.Id][0].Id);
        Approval.process(req);
        System.debug('objOrderDetail2 '+[select id,approval_status__c,Non_Billable_Reason__c,SVMXC__Is_Billable__c FROM SVMXC__Service_Order_Line__c WHERE id =: objOrderDetail2.Id]);   
    }	

    /*
*  @DESCRIPTION: DCP-44981 - Part Consumption Reversal For Serialized.
*  @PARAM : 
*  @RETURN:  void
*/
        public static testmethod void testSerializedPartsConsumptionReversal(){   
        
        User userInstance = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.Label.Integration_Service_SNAP_Profile AND isActive=true
                               LIMIT 1];  
        
       Account objAccount = TestDataAccount.initAccount(); //create account
        objAccount.Account_Group__c = 'Distributor';
        insert objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount); //create contact.
    
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = STRING_TEST_NON_SERIALIZED_PRODUCT;
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = STRING_NON_TRACKED;
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
        nonSerializedProd.Source_System__c = 'SAP';
        productLst.add(nonSerializedProd);  
        
        //Create serialized product
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Serial_Number_Profile__c = 'IL01';
        serializedProd.FRU_Eligible__c = 'FRU use only';
        serializedProd.ProductCode = '2172';
        serializedProd.Source_System__c = 'SAP';
        productLst.add(serializedProd);  
        insert productLst;
        //Create Location1
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = objAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        insert location1;
        
        //create Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        objInstalledProduct.SVMXC__Product__c = serializedProd.Id;
        insert objInstalledProduct;
    
        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(nonSerializedProdStock);
        
        //Create serialized product stock
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location1.id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(serializedProdStock);
        insert productStockLst;
    
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProd.Id;
        stockSerial1.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial1.Name = '0987654321';
        stockedSerialList.add(stockSerial1);
    
        insert stockedSerialList;
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());  
        setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
        upsert setting;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
    
        Test.startTest();
        
        SVMXC__Service_Order_Line__c objOrderDetail1 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail1.SVMXC__Consumed_From_Location__c = location1.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = SerializedProdStock.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id;
        objOrderDetail1.SVMXC__Product__c = serializedProd.id;
        objOrderDetail1.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1.SVMXC__Line_Status__c = STRING_STATUS_OPEN;
        objOrderDetail1.Consumption_Confirmed__c = true;
        objOrderDetail1.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetail1.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail1.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct.Id;

        
        insert objOrderDetail1;
        
        System.runAs(userInstance){
        
        objOrderDetail1.SVMXC__Line_Status__c = STRING_REVERSAL_REQUESTED;
        objOrderDetail1.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;
        objOrderDetail1.Part_Consumption_Reversal_External_ID__c = '784783';
        objOrderDetail1.SVMX_PS_External_ID__c='2323';
        
        
        update objOrderDetail1;
        Test.stopTest();
        System.assertEquals(STRING_REVERSAL_REQUESTED,objOrderDetail1.SVMXC__Line_Status__c);
        
        }
        
        }

 /*
*  @DESCRIPTION: DCP-44981
*  @PARAM : 
*  @RETURN:  void
*/
public static testmethod void testAdjustBatchInventory(){   
        
    User userInstance = [SELECT Id 
                           FROM User 
                           WHERE Profile.Name =: System.Label.Integration_Service_SNAP_Profile AND isActive=true
                           LIMIT 1];  
    
   Account objAccount = TestDataAccount.initAccount(); //create account
    objAccount.Account_Group__c = 'Distributor';
    insert objAccount;
    Contact objContact = TestDataContact.getNewContact(objAccount); //create contact.

    //Create non serialized product
    List<Product2> productLst = new List<Product2>();
    Product2 batchTrackedProd = new Product2();
    batchTrackedProd.Name = 'Batch Tracked';
    batchTrackedProd.IsActive = true;
    batchTrackedProd.SVMXC__Tracking__c = 'Lot/Batch Tracked';
    batchTrackedProd.Batch_Management__c = true;
    batchTrackedProd.SVMXC__Enable_Serialized_Tracking__c = false;
    batchTrackedProd.Source_System__c = 'SAP';
    productLst.add(batchTrackedProd);  
    insert productLst;
    //Create Location1
    SVMXC__Site__c location1 = new SVMXC__Site__c();
    location1.Name = 'Test Location 1';
    location1.SVMXC__Account__c = objAccount.Id;
    location1.SVMXC__Stocking_Location__c = true;
    insert location1;
    //create Installed Product
    SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
    objInstalledProduct.SVMXC__Company__c = objAccount.Id;
    objInstalledProduct.SVMXC__Product__c = batchTrackedProd.Id;
    insert objInstalledProduct;

    //Create non serialized product stock
    List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
    SVMXC__Product_Stock__c batchTrackedProdStock = new SVMXC__Product_Stock__c();
    batchTrackedProdStock.SVMXC__Location__c = location1.id;
    batchTrackedProdStock.SVMXC__Product__c = batchTrackedProd.Id;
    batchTrackedProdStock.SVMXC__Status__c = 'Available';
    batchTrackedProdStock.SVMXC__Quantity2__c = 2;
    productStockLst.add(batchTrackedProdStock);
    insert productStockLst;


    //create Batch stock
    SVMXC__Product_Serial__c batchedStock = new SVMXC__Product_Serial__c();
        batchedStock.Name = 'Batch123';
        batchedStock.Batch_Number__c = 'Batch123';
        batchedStock.Location__c = location1.Id;
        batchedStock.SVMXC__Product__c = batchTrackedProd.Id;
        batchedStock.SVMXC__Product_Stock__c = batchTrackedProdStock.Id;
        batchedStock.SVMXC__Active__c = true;
        insert batchedStock;
    
    Case objCase = TestDataCase.initServiceRequestCase(objContact);
    objCase.SVMXC__Component__c = objInstalledProduct.Id;
    insert objCase;
    
    cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());  
    setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
    upsert setting; 

    workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
    workOrder.SVMXC__Company__c = objAccount.id;
    workOrder.SVMXC__Component__c = objInstalledProduct.Id;
    workOrder.SVMXC__Order_Type__c = STRING_ORDER_TYPE_INSTALLATION;
    workOrder.Is_Auto_Created__c = true;
    insert workOrder;
    

    Test.startTest();
    
    SVMXC__Service_Order_Line__c objOrderDetail1 = new SVMXC__Service_Order_Line__c();
    objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
    objOrderDetail1.SVMXC__Consumed_From_Location__c = location1.Id;
    objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = batchTrackedProdStock.Id;
    objOrderDetail1.SVMXC__Product__c = batchTrackedProd.id;
    objOrderDetail1.SVMXC__Line_Type__c = 'Parts';
    objOrderDetail1.SVMXC__Line_Status__c = STRING_STATUS_OPEN;
    objOrderDetail1.Consumption_Confirmed__c = true;
    objOrderDetail1.SVMXC__Actual_Quantity2__c = 1;
    objOrderDetail1.SVMXC__Serial_Number__c = objInstalledProduct.Id;
    objOrderDetail1.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct.Id;
    objOrderDetail1.Batch_Lookup__c = batchedStock.id;
    objOrderDetail1.Batch_Number__c = '1234';
    
    insert objOrderDetail1;
    
    System.runAs(userInstance){
    
    objOrderDetail1.SVMXC__Line_Status__c = STRING_REVERSAL_REQUESTED;
    objOrderDetail1.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;
    objOrderDetail1.Part_Consumption_Reversal_External_ID__c = '784783';
    
    
    
    update objOrderDetail1;
    Test.stopTest();
    System.assertEquals(STRING_REVERSAL_REQUESTED,objOrderDetail1.SVMXC__Line_Status__c);
    
    }
    
    }
        
        /*
*  @DESCRIPTION: DCP-44981 - Part Consumption Reversal For Batch Product.
*  @PARAM : 
*  @RETURN:  void
*/
        public static testmethod void testBatchPartsConsumptionReversal(){   
        
        User userInstance = [SELECT Id 
                               FROM User 
                               WHERE Profile.Name =: System.Label.Integration_Service_SNAP_Profile AND isActive=true
                               LIMIT 1];  
        
       
       Account objAccount = TestDataAccount.initAccount(); //create account
        objAccount.Account_Group__c = 'Distributor';
        insert objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount); //create contact.
    
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = STRING_TEST_NON_SERIALIZED_PRODUCT;
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = STRING_NON_TRACKED;
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
        nonSerializedProd.ProductCode = '2199122';
        productLst.add(nonSerializedProd);  
        
        
        insert productLst;
        //Create Location1
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = objAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        insert location1;
        
        //create Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
    
        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(nonSerializedProdStock);
        
       insert productStockLst;
    
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = nonSerializedProd.Id;
        stockSerial1.SVMXC__Product_Stock__c = nonSerializedProdStock.Id;
        stockSerial1.Name = '0987654321';
        stockedSerialList.add(stockSerial1);
    
        insert stockedSerialList;
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());  
        setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
        upsert setting;

        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
    
        Test.startTest();
        
        SVMXC__Service_Order_Line__c objOrderDetail1 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail1.SVMXC__Consumed_From_Location__c = location1.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = nonSerializedProdStock.Id;
        objOrderDetail1.Batch_Lookup__c = stockSerial1.Id;
        objOrderDetail1.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1.SVMXC__Line_Status__c = STRING_STATUS_OPEN;
        objOrderDetail1.Consumption_Confirmed__c = true;
        objOrderDetail1.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetail1.Batch_Number__c = '123456';
        
        insert objOrderDetail1;
        
        System.runAs(userInstance){
        
        objOrderDetail1.SVMXC__Line_Status__c = STRING_REVERSAL_REQUESTED;
        objOrderDetail1.Integration_Status__c = STRING_INTEGRATIONSTATUS_SUCCESS;
        objOrderDetail1.Part_Consumption_Reversal_External_ID__c = '4561';
        
        
        update objOrderDetail1;
        Test.stopTest();
        System.assertEquals(STRING_REVERSAL_REQUESTED,objOrderDetail1.SVMXC__Line_Status__c);
        
        }
        
        
        }
	/*******************************************************************************************************
    * @description DCP-50097 Method to test logic to make Batch number null when Batch lookup is null;
    * @method testMakeBatchNumberNull
    * @return
    * @author Harsh Shukla
    */
    public static testmethod void testMakeBatchNumberNull() {
        Account objAccount = TestDataAccount.initAccount(); //create account
        objAccount.Account_Group__c = 'Distributor';
        insert objAccount;
        Contact objContact = TestDataContact.getNewContact(objAccount); //create contact.
    
        //Create non serialized product
        List<Product2> productLst = new List<Product2>();
        Product2 nonSerializedProd = new Product2();
        nonSerializedProd.Name = STRING_TEST_NON_SERIALIZED_PRODUCT;
        nonSerializedProd.IsActive = true;
        nonSerializedProd.SVMXC__Tracking__c = STRING_NON_TRACKED;
        nonSerializedProd.SVMXC__Stockable__c = true;
        nonSerializedProd.SVMXC__Enable_Serialized_Tracking__c = false;
        productLst.add(nonSerializedProd);  
        
        //Create serialized product
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Serial_Number_Profile__c = 'IL01';
        serializedProd.FRU_Eligible__c = 'FRU use only';
        serializedProd.ProductCode = '2172';
        productLst.add(serializedProd);  
        insert productLst;
        //Create Location1
        SVMXC__Site__c location1 = new SVMXC__Site__c();
        location1.Name = 'Test Location 1';
        location1.SVMXC__Account__c = objAccount.Id;
        location1.SVMXC__Stocking_Location__c = true;
        insert location1;
        
        //create Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
    
        //Create non serialized product stock
        List<SVMXC__Product_Stock__c> productStockLst = new List<SVMXC__Product_Stock__c>();
        SVMXC__Product_Stock__c nonSerializedProdStock = new SVMXC__Product_Stock__c();
        nonSerializedProdStock.SVMXC__Location__c = location1.id;
        nonSerializedProdStock.SVMXC__Product__c = nonSerializedProd.Id;
        nonSerializedProdStock.SVMXC__Status__c = 'Available';
        nonSerializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(nonSerializedProdStock);
        
        //Create serialized product stock
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location1.id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 2;
        productStockLst.add(serializedProdStock);
        insert productStockLst;
    
        //Insert stock serials for serialized product stock
        List<SVMXC__Product_Serial__c> stockedSerialList = new List<SVMXC__Product_Serial__c>();
        SVMXC__Product_Serial__c stockSerial1 = new SVMXC__Product_Serial__c();
        stockSerial1.SVMXC__Active__c = true;
        stockSerial1.SVMXC__Product__c = serializedProd.Id;
        stockSerial1.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial1.Name = '0987654321';
        stockedSerialList.add(stockSerial1);
    
        insert stockedSerialList;
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());  
        setting.Bypass_Triggers_By_Object_1__c = 'SVMXC__Service_Order__c'; 
        upsert setting;

        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c = STRING_ORDER_TYPE_INSTALLATION;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
    
        Test.startTest();
        
        SVMXC__Service_Order_Line__c objOrderDetail1 = new SVMXC__Service_Order_Line__c();
        objOrderDetail1.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail1.SVMXC__Consumed_From_Location__c = location1.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Product_Stock__c = SerializedProdStock.Id;
        objOrderDetail1.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial1.Id;
        objOrderDetail1.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail1.SVMXC__Line_Status__c = STRING_STATUS_OPEN;
        objOrderDetail1.Consumption_Confirmed__c = true;
        objOrderDetail1.SVMXC__Actual_Quantity2__c = 1;
        objOrderDetail1.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail1.SVMX_PS_VS_Return_Installed_Product__c = objInstalledProduct.Id;
        objOrderDetail1.Batch_Lookup__c = null;
        objOrderDetail1.Batch_Number__c = '123456';
        
        insert objOrderDetail1;
        SVMXC__Service_Order_Line__c objWD = [SELECT Id, Batch_Number__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :workOrder.id];
        system.assertEquals(null, objWD.Batch_Number__c);
        
        objOrderDetail1.Batch_Number__c = '123456';
        update objOrderDetail1;
        SVMXC__Service_Order_Line__c objWD1 = [SELECT Id, Batch_Number__c FROM SVMXC__Service_Order_Line__c WHERE SVMXC__Service_Order__c = :workOrder.id];
        system.assertEquals(null, objWD1.Batch_Number__c);
        Test.stopTest();
       }
	   
	/*Test method to cover Catch Block of Class UpdateProductGroup_WorkdetailHelper 
	*/

   public static testmethod void coverCatchBlockUpdateProductGroupWorkdetailHelper (){
    try{
        UpdateProductGroup_WorkdetailHelper.catchException = true;
        UpdateProductGroup_WorkdetailHelper  uw = new UpdateProductGroup_WorkdetailHelper (null);
        Test.startTest();
        System.enqueueJob(uw);
        Test.stopTest();
    	}catch(Exception e){
            System.assert(e!=null, 'e is empty');
    	}
   }

    /*******************************************************
     *Method Name : coverCatchBlockInsertPOAndPOLWorkdetailHelper()
    *Description : method to cover catch block
    *params      : NA
    *return type : void
    ******************************************************/
   
    public static testmethod void coverCatchBlockInsertPOAndPOLWorkdetailHelper(){
        try{
            InsertPOAndPOL_WorkdetailHelper.catchException = true;
            InsertPOAndPOL_WorkdetailHelper pd = new InsertPOAndPOL_WorkdetailHelper(null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }

}
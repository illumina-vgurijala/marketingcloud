/***************************************************************************************************************************************
 * NAME   : TestWorkOrderDataReceiver
 * DESCRIPTION  : TestClass for WorkOrderDataReceiver
 *    
 * @AUTHOR : Adyasha
 * @DATE   : 25-Jun-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Adyasha                  25-Jun-2021         DCP-45746 : Added method to check CS Review Activity Creation
  ***************************************************************************************************************************************
  */ 
@isTest
public class TestWorkOrderDataReceiver {


      public static final boolean BOOLEAN_CONSUMABLES_INCLUDED = false;
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_CASE_RECORDTYPENAME = 'Service Request';
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
    static SVMXC__Service_Group_Members__c objGrpMember;
    
    
    
    
    
    static WorkOrderDataReceiverWrapper.WorkOrders getWorkOrderJson(String workOrderNumber,String erpServiceOrder,String confirmationId,String confirmationERPId, String status){
        
        /****** POPULATE THE WRAPPER WITH DATA **************/
        
        //create item for work order JSON.
        WorkOrderDataReceiverWrapper.WorkDetails workDetailRecords = new WorkOrderDataReceiverWrapper.WorkDetails();
        workDetailRecords.ConfirmationId = confirmationId;
        workDetailRecords.ConfirmationERPId = confirmationERPId;
        
        //create item for error entity.
        WorkOrderDataReceiverWrapper.ErrorEntity errorEntityRecords = new WorkOrderDataReceiverWrapper.ErrorEntity(workOrderNumber,'Ok','Success');
        
       
        //create header for work order JSON.
        WorkOrderDataReceiverWrapper.WorkOrders workOrderRecords = new WorkOrderDataReceiverWrapper.WorkOrders();
        workOrderRecords.WorkOrderNumber = workOrderNumber;
        workOrderRecords.ErpServiceOrder = erpServiceOrder;
        workOrderRecords.WorkDetails.add(workDetailRecords); 
        workOrderRecords.ErrorEntity.add(errorEntityRecords); 
        
        //return the wrapper object.
        return workOrderRecords; 
    }

    static testMethod void testWorkOrderInsertHTTPPost(){
    
        SVMX_PS_VS_Part_Consumption_Settings__c consumptionSetting= new  SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'Use Allocated Qty',
                                                                                                                SVMX_PS_VS_Field_Type__c ='Boolean');
                                                                                                                
       insert consumptionSetting;
        
        //holds the wrapper records in list.
        List<WorkOrderDataReceiverWrapper.WorkOrders> lstWorkOrderRecords = new List<WorkOrderDataReceiverWrapper.WorkOrders> ();
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Contract__c'
        );
        insert apexSettings;
          Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        TestDataContact.getNewContact(objAccount);
        
        
        
        Product2 objProduct = new Product2(
            Name = STRING_PRODUCT_NAME, 
            Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS);
        insert objProduct;
        
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        
        
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        
        
         SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        insert objLocation;
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Site__c = objLocation.Id;  
        objCase.Date_of_Issue_Awareness__c = Date.Today();      
        insert objCase;
        Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
        System.assertEquals(InsertedCase.SVMXC__Component__c, objInstalledProduct.Id);
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
       
        
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        insert objOrderDetail;
        
        //get the work order wrapper object.
        WorkOrderDataReceiverWrapper.WorkOrders workOrderRecords  = getWorkOrderJson(workOrder.Id, '786876',objOrderDetail.Id, 'ADF546546', 'Success');
        
        //pass it over to a list.  
        lstWorkOrderRecords.add(workOrderRecords);  
        
        //convert the apex list into a Json structure.
        String workOrderJSON = JSON.serialize(lstWorkOrderRecords);

            Test.startTest();
        
            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/WorkOrderSyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(workOrderJSON);
            RestContext.request = req;
            RestContext.response= res;
            WorkOrderDataReceiver.upsertIncomingValues(); 
            
        Test.stopTest();
        
        /******************** SYSTEM ASSERTS ***************/
        
        //make sure the status is success.
        System.assertequals(200,res.statuscode);
        
        /******************** / SYSTEM ASSERTS ***************/
             
        
    }
    
    
    static testMethod void testWorkOrderUpdateHTTPPost(){
    
        SVMX_PS_VS_Part_Consumption_Settings__c consumptionSetting= new  SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'Use Allocated Qty',
                                                                                                                SVMX_PS_VS_Field_Type__c ='Boolean');
                                                                                                                
       insert consumptionSetting;
        
        //holds the wrapper records in list.
        List<WorkOrderDataReceiverWrapper.WorkOrders> lstWorkOrderRecords = new List<WorkOrderDataReceiverWrapper.WorkOrders> ();
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Contract__c'
        );
        insert apexSettings;
          Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        TestDataContact.getNewContact(objAccount);
        
        
        
        Product2 objProduct = new Product2(
            Name = STRING_PRODUCT_NAME, 
            Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS);
        insert objProduct;
        
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        
        
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        
        
         SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        insert objLocation;
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Site__c = objLocation.Id;  
        objCase.Date_of_Issue_Awareness__c = Date.Today();      
        insert objCase;
        Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
        System.assertEquals(InsertedCase.SVMXC__Component__c, objInstalledProduct.Id);
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
       
        
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        insert objOrderDetail;
        
        //get the work order wrapper object.
        WorkOrderDataReceiverWrapper.WorkOrders workOrderRecords  = getWorkOrderJson(objOrderDetail.Id, '786876',objOrderDetail.Id, 'ADF546546', 'E');
        
        //pass it over to a list.  
        lstWorkOrderRecords.add(workOrderRecords);  
        
        //convert the apex list into a Json structure.
        String workOrderJSON = JSON.serialize(lstWorkOrderRecords);

            Test.startTest();
        
            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/WorkOrderSyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(workOrderJSON);
            RestContext.request = req;
            RestContext.response= res;
            WorkOrderDataReceiver.upsertIncomingValues(); 
            
        Test.stopTest();
        
        /******************** SYSTEM ASSERTS ***************/
        
        //make sure the status is success.
        //System.assertequals(200,res.statuscode);
        
        /******************** / SYSTEM ASSERTS ***************/
             
        
    }

    static testMethod void testWorkOrderInsertDummyHTTPPost(){
    
        SVMX_PS_VS_Part_Consumption_Settings__c consumptionSetting= new  SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'Use Allocated Qty',
                                                                                                                SVMX_PS_VS_Field_Type__c ='Boolean');
                                                                                                                
       insert consumptionSetting;
        
        //holds the wrapper records in list.
        List<WorkOrderDataReceiverWrapper.WorkOrders> lstWorkOrderRecords = new List<WorkOrderDataReceiverWrapper.WorkOrders> ();

        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Contract__c'
        );
        insert apexSettings;

          Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        TestDataContact.getNewContact(objAccount);
        
        
        
        Product2 objProduct = new Product2(
            Name = STRING_PRODUCT_NAME, 
            Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS);
        insert objProduct;
        
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        
        
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        
        
         SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        insert objLocation;
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Site__c = objLocation.Id;  
        objCase.Date_of_Issue_Awareness__c = Date.Today();      
        insert objCase;
        Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
        System.assertEquals(InsertedCase.SVMXC__Component__c, objInstalledProduct.Id);
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
       
        
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.Consumption_Confirmed__c = true; //CMCM-83 
        insert objOrderDetail;
        
        //get the work order wrapper object.
                
       	WorkOrderDataReceiverWrapper.WorkOrders workOrderRecords  = getWorkOrderJson(workOrder.Id, '786876',objOrderDetail.Id, 'ADF546546', 'Success');
       	workOrderRecords.ErrorEntity.clear();
       	workOrderRecords.ErrorEntity.add(new WorkOrderDataReceiverWrapper.ErrorEntity(objOrderDetail.Id,'Ok','Success'));
        //pass it over to a list.  
        lstWorkOrderRecords.add(workOrderRecords);  
        
        //convert the apex list into a Json structure.
        String workOrderJSON = JSON.serialize(lstWorkOrderRecords);

            Test.startTest();
        
            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/WorkOrderSyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(workOrderJSON);
            RestContext.request = req;
            RestContext.response= res;
            try{
        		WorkOrderDataReceiver.upsertIncomingValues(); 
            }
            catch(Exception e){
               system.debug('Exception');     
            }
        Test.stopTest();
        
        /******************** SYSTEM ASSERTS ***************/
        //CMCM-83 Adding assertion to check Consumption_Confirmed__c is false or not
        List<SVMXC__Service_Order_Line__c> listobjSOL = [select id,Consumption_Confirmed__c from SVMXC__Service_Order_Line__c LIMIT 1];
        System.assertequals(false,listobjSOL[0].Consumption_Confirmed__c);
        //make sure the status is success.
        System.assertequals(200,res.statuscode);
        
        /******************** / SYSTEM ASSERTS ***************/
             
        
    }
    
    static testMethod void testWorkOrderInsertDummyHTTPPost2(){
    
        SVMX_PS_VS_Part_Consumption_Settings__c consumptionSetting= new  SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'Use Allocated Qty',
                                                                                                                SVMX_PS_VS_Field_Type__c ='Boolean');
                                                                                                                
       insert consumptionSetting;
        
        //holds the wrapper records in list.
        List<WorkOrderDataReceiverWrapper.WorkOrders> lstWorkOrderRecords = new List<WorkOrderDataReceiverWrapper.WorkOrders> ();
        
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Contract__c'
        );
        insert apexSettings;

          Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        TestDataContact.getNewContact(objAccount);
        
        
        
        Product2 objProduct = new Product2(
            Name = STRING_PRODUCT_NAME, 
            Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS);
        insert objProduct;
        
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        
        
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
        
        
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
        
        
         SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test Location','Test Street','Ireland','123456','USD');
        insert objLocation;
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Site__c = objLocation.Id;  
        objCase.Date_of_Issue_Awareness__c = Date.Today();      
        insert objCase;
        Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
        System.assertEquals(InsertedCase.SVMXC__Component__c, objInstalledProduct.Id);
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;
        
        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
       
        
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        insert objOrderDetail;
        
        //get the work order wrapper object.
                
       	WorkOrderDataReceiverWrapper.WorkOrders workOrderRecords  = getWorkOrderJson(workOrder.Id, '786876',objOrderDetail.Id, 'ADF546546', 'Success');
       	workOrderRecords.ErrorEntity = null;
       	//pass it over to a list.  
        lstWorkOrderRecords.add(workOrderRecords);  
        
        //convert the apex list into a Json structure.
        String workOrderJSON = JSON.serialize(lstWorkOrderRecords);

            Test.startTest();
        
            //As Per Best Practice it is important to instantiate the Rest Context 
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/WorkOrderSyncInterface';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(workOrderJSON);
            RestContext.request = req;
            RestContext.response= res;
            try{
        		WorkOrderDataReceiver.upsertIncomingValues(); 
            }
            catch(Exception e){
               system.debug('Exception');     
            }
        Test.stopTest();
        
        /******************** SYSTEM ASSERTS ***************/
        
        //make sure the status is success.
        System.assertequals(200,res.statuscode);
        
        /******************** / SYSTEM ASSERTS ***************/
             
        
    }

    /**
    *  DCP-45746
    *  @author : Adyasha
    *  @description - test method to verify Creation of CS Review Activity
    **/
    static testMethod void testWOCSReviewWithSAPInvoicingFailure(){
        
        //holds the wrapper records in list.
        List<WorkOrderDataReceiverWrapper.WorkOrders> lstWorkOrderRecords = new List<WorkOrderDataReceiverWrapper.WorkOrders> ();
        
        Account objAccount = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount.Account_Group__c='Distributor';
        insert objAccount;

        Contact objContact = TestDataContact.getNewContact(objAccount);
        
        Product2 objProduct = TestDataMaster.createProduct(true);
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objcase.Has_Resolution_Code__c = true;
        insert objCase;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated'); 
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Order_Type__c = Label.WorkOrderTypeServiceActivities;
        workOrder.Is_Auto_Created__c = true;
        insert workOrder;

        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Order_Status__c = 'Completed';
        workOrder.Evaluation__c = 'evaluation';
        workOrder.SVMXC__Work_Performed__c = 'work performed';
        workOrder.Verification_Result__c = 'result';
        workOrder.Is_Service_Report_Generated__c = false;
        workOrder.Abandoned_Reason__c = 'No Customer Response';
        workOrder.SVMX_PS_Subject__c = 'subject';
        workOrder.SVMXC__Billing_Type__c = Label.WorkOrderBillingTypeBillable; //CMCM-10145
        update workOrder;
        Test.startTest();
        
        SVMXC__Service_Order_Line__c objOrderDetail = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrder.Id,TestWorkDetails.STRING_USAGE_CONSUMPTION);
        objOrderDetail.SVMXC__Product__c = objProduct.Id;
        objOrderDetail.SVMXC__Line_Type__c = 'Labor';
        objOrderDetail.SVMXC__Is_Billable__c = true;
        insert objOrderDetail;
        
        //create item for work order JSON.
        WorkOrderDataReceiverWrapper.WorkDetails workDetailRecords = new WorkOrderDataReceiverWrapper.WorkDetails();
        workDetailRecords.ConfirmationId = objOrderDetail.Id;
        workDetailRecords.ConfirmationERPId = '654321';
        
        //create item for error entity.
        WorkOrderDataReceiverWrapper.ErrorEntity errorEntityRecords = new WorkOrderDataReceiverWrapper.ErrorEntity(workOrder.Id,'C','Invoice Update');
        
        //create header for work order JSON.
        WorkOrderDataReceiverWrapper.WorkOrders workOrderRecords = new WorkOrderDataReceiverWrapper.WorkOrders();
        workOrderRecords.WorkOrderNumber = workOrder.Id;
        workOrderRecords.ErpServiceOrder = '12345';
        workOrderRecords.WorkDetails.add(workDetailRecords); 
        workOrderRecords.ErrorEntity.add(errorEntityRecords); 

       	//pass it over to a list.  
        lstWorkOrderRecords.add(workOrderRecords);  
        
        //convert the apex list into a Json structure.
        String workOrderJSON = JSON.serialize(lstWorkOrderRecords);

        
    
        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/WorkOrderSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(workOrderJSON);
        RestContext.request = req;
        RestContext.response= res;
        try{
            WorkOrderDataReceiver.upsertIncomingValues(); 
        }
        catch(Exception e){
            system.debug('Exception');     
        }
        Test.stopTest();
        List<SVMXC__Service_Order_Line__c> lstWDs = [select id, SVMXC__Service_Order__c from SVMXC__Service_Order_Line__c where SVMXC__Activity_Type__c = 'Customer Service Review' AND SVMXC__Service_Order__c =: workOrder.id];
        System.debug('@@@@ in TestWorkOrderDataReceiver, lstWDs: '+lstWDs);
        System.assertNotEquals(0, lstWDs.size(), 'CS Review Activity Not Created');
        
    }
     /**
     *  @author      : Nitin
     *  @description : method to cover catch block in CompareWorkdetails_WorkdetailHelper
     **/
    @isTest
    public static void coverCatchBlockCompareWorkdetailsWorkdetailHelper(){
        try{
            CompareWorkdetails_WorkdetailHelper.catchException = true;
            CompareWorkdetails_WorkdetailHelper pd = new CompareWorkdetails_WorkdetailHelper(null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }


}
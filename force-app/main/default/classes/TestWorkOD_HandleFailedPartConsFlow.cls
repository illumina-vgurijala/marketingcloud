/**
* @author Priya Mukherjee
* @date 14th March 2024
*
* @description CMCM-83 Test class for Work Order Detail: Handle Failed Part Consumption Flow
*/
@IsTest
public with sharing class TestWorkOD_HandleFailedPartConsFlow {
   
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CONTRACT_STATUS = 'Active';
    public static final string STRING_CASE_RECORDTYPENAME = 'Service Request';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
   
    static Case cs;
    static Account objAcc;
    static SVMXC__Service_Order__c workOrder;

    /**
    * CMCM-83
    *  @author Priya Mukherjee
    *  @description - test flow Work Order Detail: Handle Failed Part Consumption
    */
    static testMethod void testFlow(){
       
        SVMX_PS_VS_Part_Consumption_Settings__c consumptionSetting= new  SVMX_PS_VS_Part_Consumption_Settings__c(Name = 'Use Allocated Qty',SVMX_PS_VS_Field_Type__c ='Boolean');                                                                                                      
        insert consumptionSetting;
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        cs.Bypass_Triggers_By_Object_1__c = 'Case';
        cs.Bypass_Triggers_By_Object_2__c = 'SVMXC__Service_Contract__c';
        cs.Bypass_Triggers_By_Object_3__c = 'workOrder';
        cs.Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Order_Line__c';
        upsert cs cs_Apex_Settings__c.Id;
        //holds the wrapper records in list.
        List<WorkOrderDataReceiverWrapper.WorkOrders> lstWorkOrderRecords = new List<WorkOrderDataReceiverWrapper.WorkOrders> ();
       
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
       
        TestDataContact.getNewContact(objAccount);
       
        Product2 objProduct = new Product2(
            Name = STRING_PRODUCT_NAME,
            Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS);
        insert objProduct;
        system.debug('--Product created--');
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
       
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = STRING_CONTRACT_STATUS;
        insert objServiceContract;
       
        SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
        objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert objCoveredProduct;
       
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('Test1 Location','Test1 Street','Ireland','1234567','USD');
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
       
        //Create serialized product
        Product2 serializedProd = new Product2();
        serializedProd.Name = 'Test Serialized Product';
        serializedProd.IsActive = true;
        serializedProd.SVMXC__Tracking__c = 'Serialized';
        serializedProd.SVMXC__Stockable__c = true;
        serializedProd.SVMXC__Enable_Serialized_Tracking__c = true;
        serializedProd.Serial_Number_Profile__c = 'IL01';
        serializedProd.FRU_Eligible__c = 'FRU use only';
        insert serializedProd;
       
        SVMXC__Site__c location = new SVMXC__Site__c();
        location.Name = 'Test Location 1';
        location.SVMXC__Account__c = objAccount.Id;
        location.SVMXC__Stocking_Location__c = true;
        insert location;
       
        SVMXC__Product_Stock__c serializedProdStock = new SVMXC__Product_Stock__c();
        serializedProdStock.SVMXC__Location__c = location.id;
        serializedProdStock.SVMXC__Product__c = serializedProd.Id;
        serializedProdStock.SVMXC__Status__c = 'Available';
        serializedProdStock.SVMXC__Quantity2__c = 2;
        insert serializedProdStock;
       
        SVMXC__Product_Stock__c objProductStock = new SVMXC__Product_Stock__c();
        objProductStock.SVMXC__Product__c = serializedProd.Id;
        insert objProductStock;
        System.assertNotEquals(null, objProductStock.Id);
       
        SVMXC__Product_Serial__c stockSerial = new SVMXC__Product_Serial__c();
        stockSerial.SVMXC__Active__c = true;
        stockSerial.SVMXC__Product__c = serializedProd.Id;
        stockSerial.SVMXC__Product_Stock__c = serializedProdStock.Id;
        stockSerial.Name = '0987654321';
       
        insert stockSerial;
        Test.startTest();
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.Consumption_Confirmed__c = true; //CMCM-83
        objOrderDetail.SVMXC__Line_Type__c = 'Parts';
        objOrderDetail.SVMX_PS_VS_Consumed_Product_Stock__c = objProductStock.Id;
        objOrderDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c = stockSerial.Id;
        objOrderDetail.Record_Create_From_SFM__c = true;
        objOrderDetail.SVMXC__Start_Date_and_Time__c = Date.today();
        objOrderDetail.Labor_Hours__c = '1:15';
        insert objOrderDetail;
       
        //get the work order wrapper object.
        //WorkOrderDataReceiverWrapper.WorkOrders workOrderRecords  = getWorkOrderJson(workOrder.Id, '786876',objOrderDetail.Id, 'ADF546546', 'Success');
        WorkOrderRequest request = new WorkOrderRequest(workOrder.Id, '786875',objOrderDetail.Id, 'ADF546545', 'Success');
        WorkOrderDataReceiverWrapper.WorkOrders workOrderRecords = getWorkOrderJson(request);
       
        workOrderRecords.ErrorEntity.clear();
        workOrderRecords.ErrorEntity.add(new WorkOrderDataReceiverWrapper.ErrorEntity(objOrderDetail.Id,'E','Fail'));
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
        try {
            WorkOrderDataReceiver.upsertIncomingValues();
        } catch(Exception e) {
            system.debug('Exception');    
        }
       
       
        List<SVMXC__Service_Order_Line__c> listobjSOL = [select id, SVMXC__Line_Type__c , Consumption_Confirmed__c, Integration_Status__c from SVMXC__Service_Order_Line__c LIMIT 1];
        System.assertequals(false,listobjSOL[0].Consumption_Confirmed__c);
        System.assertequals('Fail',listobjSOL[0].Integration_Status__c);
        System.assertequals(200,res.statuscode);
        System.assertequals('Parts',listobjSOL[0].SVMXC__Line_Type__c);
        Integer emailCount = Limits.getLimitEmailInvocations();
        Assert.isTrue(emailCount != null, 'email not sent');
        Test.stopTest();
    }
    /**
* CMCM-83
*  @author Priya Mukherjee
*  @description - creating work Order JSON data
*/
    public class WorkOrderRequest {
        private String workOrderNumber;
        private String erpServiceOrder;
        private String confirmationId;
        private String confirmationERPId;
        private String status;
       
      /**
    * CMCM-83
    *  @author Priya Mukherjee
    *  @description - Contructor
    */
        public WorkOrderRequest(String workOrderNumber, String erpServiceOrder, String confirmationId, String confirmationERPId, String status) {
            this.workOrderNumber = workOrderNumber;
            this.erpServiceOrder = erpServiceOrder;
            this.confirmationId = confirmationId;
            this.confirmationERPId = confirmationERPId;
            this.status = status;
        }
             /**
    * CMCM-83
    *  @author Priya Mukherjee
    *  @description -Getters and Setters for workOrderNumbe
    */
        public String getWorkOrderNumber() {
            return workOrderNumber;
        }
                /**
    * CMCM-83
    *  @author Priya Mukherjee
    *  @description -Getters and Setters forerpServiceOrder
    */
       
        public String getErpServiceOrder() {
            return erpServiceOrder;
        }
       /**
    * CMCM-83
    *  @author Priya Mukherjee
    *  @description -Getters and Setters for ConfirmationId
    */
        public String getConfirmationId() {
            return confirmationId;
        }
        /**
    * CMCM-83
    *  @author Priya Mukherjee
    *  @description -Getters and Setters for ConfirmationERPId
    */
        public String getConfirmationERPId() {
            return confirmationERPId;
        }
/**
    * CMCM-83
    *  @author Priya Mukherjee
    *  @description -Getters and Setters for status
    */
        public String getStatus() {
            return status;
        }
    }
    /**
    * CMCM-83
    *  @author Priya Mukherjee
    *  @description - Updated method using the WorkOrderRequest container class
    */
    public static WorkOrderDataReceiverWrapper.WorkOrders getWorkOrderJson(WorkOrderRequest request) {
        /****** POPULATE THE WRAPPER WITH DATA **************/
       
        // Create item for work order JSON.
        WorkOrderDataReceiverWrapper.WorkDetails workDetailRecords = new WorkOrderDataReceiverWrapper.WorkDetails();
        workDetailRecords.ConfirmationId = request.getConfirmationId();
        workDetailRecords.ConfirmationERPId = request.getConfirmationERPId();
       
        // Create item for error entity.
        WorkOrderDataReceiverWrapper.ErrorEntity errorEntityRecords = new WorkOrderDataReceiverWrapper.ErrorEntity(request.getWorkOrderNumber(), 'E', 'Fail');
       
        // Create header for work order JSON.
        WorkOrderDataReceiverWrapper.WorkOrders workOrderRecords = new WorkOrderDataReceiverWrapper.WorkOrders();
        workOrderRecords.WorkOrderNumber = request.getWorkOrderNumber();
        workOrderRecords.ErpServiceOrder = request.getErpServiceOrder();
        workOrderRecords.WorkDetails.add(workDetailRecords);
        workOrderRecords.ErrorEntity.add(errorEntityRecords);
       
        // Return the wrapper object.
        return workOrderRecords;
    }  
}
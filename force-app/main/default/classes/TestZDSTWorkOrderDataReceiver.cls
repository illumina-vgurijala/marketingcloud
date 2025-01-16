/* @ author      : KD
* @ date         : 1-June-2021
* @ Description  : DCP-38933 : test class for ZDSTWorkOrderDataReceiver classes.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* KD                        3-June-2021        DCP-38933 : Initial Version
* Akshay Mohan              7-June-2021        DCP-46835: Check exclude forecast flag on opportunity
* Ashwin Kumar              31-Mar-2021        DCP-52339 Remove TestTAPS.setupDeferredObjectData
* Sai                       22-june-2023       CMCM-41: WorkOrder Creation
* Dhairya                   24-July-2024           CMCM-6756 No changes in the test class only using for deployment
* Dhairya                   11-Oct-2024           CMCM-5165 No changes in the test class only using for deployment
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestZDSTWorkOrderDataReceiver {
    public static final String TESTACCOUNT = 'TESTACCOUNT';
    public static final String TESTSITE = 'TESTSITE';
    public static final String PRODUCT1 = 'PRODUCT1';
    public static final String IP12345 = 'IP12345';
    public static final String ERP_ORDER = '1234567';
    public static final String ERP_ORDERLINE = '123543';
    public static final String TIMESTAMP = '1622640590292';
    public static final String INTERFACENAME = '/services/apexrest/ZDSTWorkOrderSyncInterface/';
    public static final String HTTPPOST = 'POST';
    public static final String WOERROR = 'Work Order not created';
    public static List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name =: Label.Integration_Service_SNAP_Profile
                                AND IsActive = TRUE
                                LIMIT 1];
    /**
     *  @author      : KD
     *  @description : Setup method
     **/
    @testSetup
    static void initializeTestData(){
        Account acc = TestDataAccount.getAccount('Test 1');
        String recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
        acc.RecordTypeId = recordtypeid;
        acc.ERP_Customer_Id__c = TESTACCOUNT;
        acc.Account_Group__c =  'Sold To';
        insert new List<Account>{acc};

        Contact con1 = TestDataPerson.initContact(acc.Id);
        con1.Email = 'kdesai@illumina.com';
        insert new List<Contact> { con1 };

        List<User> lstUsers = [SELECT Id
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service and IsActive = true
                               LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test', 'country');
        insert serviceTeam;

        SVMXC__Service_Group_Members__c technicianFAS = TestDataFieldService.createTechnician(lstUsers[0].Id, 'Test Technician', serviceTeam.Id);
        technicianFAS.SVMXC__Email__c='b@b.com';
        List<SVMXC__Service_Group_Members__c> lstFieldSupport = new List<SVMXC__Service_Group_Members__c>();
        lstFieldSupport.add(technicianFAS);
        insert lstFieldSupport;

        Account_to_Field_Support__c accToFieldSupport = TestDataFieldService.createAccountToFieldSupport(acc.Id, Label.Field_Support_User_Role_Primary_FSE, lstFieldSupport[0].Id);
        insert accToFieldSupport;

        Opportunity sOpp = TestDataOpportunity.initOpportunity(acc,Label.OpportunityRTDirectFieldServices);
        sOpp.Name = 'Service Opp';
        sOpp.Primary_Contact__c = con1.Id;
        //DCP-46835: Start- set product interest
        sOpp.StageName = 'Develop';
        sOpp.Type=Label.OpportunityTypeBillableService;
        sOpp.Product_Interest__c=Label.OpportunityProductInterestOtherServices;
        //DCP-46835: End- set product interest

        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();
        sOpp.Pricebook2Id = standardPricebook.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc,Label.OpportunityRTDirectFieldServices);
        opp2.Name = 'opp2';
        opp2.Type = 'Billable Services';
        opp2.StageName = 'Develop';
        opp2.Product_Interest__c = 'Break Fix';

        insert new List<Opportunity>{sOpp,opp2};
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry',TESTSITE,'USD');
        objLocation.ERP_Customer_ID__c = TESTSITE;
        insert objLocation;
        Product2 product = TestDataMaster.initProduct(PRODUCT1);
        product.Auto_Create_Billable_Work_Order__c = 'Auto Create Field Service Relocation Work Order';
        Product2 productBlank = TestDataMaster.initProduct('No Identity');
        insert new List<Product2> { product,productBlank};
        SVMXC__Installed_Product__c rec1 = TestDataInstalledProduct.initInstalledProduct(acc.id );
        rec1.SVMXC__Product__c = product.Id;
        rec1.ERP_Equipment_Id__c = IP12345;
        rec1.SVMXC__Site__c = objLocation.id;
        insert rec1;
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_All_Validations__c = true;
        upsert setting;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        objWorkOrder.SVMXC__Order_Type__c='Installation';
        objWorkOrder.Is_Auto_Created__c = true;
        objWorkOrder.SVMX_PS_Subject__c = 'Test WO PO Update';
        objWorkOrder.Opportunity__c = opp2.Id;
        insert objWorkOrder;

        setting.Bypass_All_Validations__c = false;
        update setting;

    }
    /**
     *  @author      : KD
     *  @description : method to test auto creation of WO
     **/
    @isTest
    static void testWOCreationProductSuccess(){
        //DCP-46835: Start- Query with name
        Opportunity objOpps = [Select id,Primary_Contact__c from Opportunity WHERE Name ='Service Opp'];
        //DCP-46835: End- Query with name
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = 'Preventative Maintenance';
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.Opportunity = objOpps.Id;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.TimeStamp = TIMESTAMP;
        objWOWrapper.SVMXC_Product = PRODUCT1;
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            update new Contact(Id=objOpps.Primary_Contact__c,OwnerId = lstUsers[0].Id);
            System.runAs(lstUsers[0]){
                httpRest(strWOJSON);
            }
        }
        Test.stopTest();
        List<SVMXC__Service_Order__c> lstWO = [Select id,ERP_Order_Number__c,SVMXC__Order_Type__c,Standalone_Work_Order_Origin__c from SVMXC__Service_Order__c where ERP_Order_Number__c =: ERP_ORDER];
        System.assert(!lstWO.isEmpty(),WOERROR);
        System.assertEquals(Label.WorkOrderTypeRelocation,lstWO[0].SVMXC__Order_Type__c,'Work Order Type not set correctly');
        System.assertEquals(ZDSTWorkOrderDataReceiver.STRING_AUTO_GENERATED,lstWO[0].Standalone_Work_Order_Origin__c,'Work Order Origin not set correctly');
        //DCP-46835: Start- Check Exclude_from_Forecast__c field
        Test.getEventBus().deliver();
        objOpps = [Select id,Exclude_from_Forecast__c from Opportunity WHERE ID =:objWOWrapper.Opportunity];
        System.debug('objOpps: '+objOpps);
        System.assert(objOpps.Exclude_from_Forecast__c,'Exclude from forecast not set');
        //DCP-46835: End- Check Exclude_from_Forecast__c field

    }
    /**
     *  @author      : KD
     *  @description : method to test failure
     **/
    @isTest
    static void testWOCreationNoProductFailure(){
        Opportunity objOpps = [Select id from Opportunity LIMIT 1];
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = Label.WorkOrderTypeRelocation;
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.TimeStamp = TIMESTAMP;
        objWOWrapper.SVMXC_Product = 'PRODUCT2';
        objWOWrapper.Opportunity = objOpps.Id;
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0]){
                try{
                    httpRest(strWOJSON);
                }catch(Exception e){
                    System.debug('Exception--->'+e);
                    System.assertEquals('Product PRODUCT2 is invalid',e.getMessage(),'Incorrect Exception thrown for Product Error');
                }
            }
        }
        System.assertEquals(1, Limits.getEmailInvocations(), 'An email has not been sent');
        Test.stopTest();
    }
    /**
     *  @author      : KD
     *  @description : method to test failure
     **/
    @isTest
    static void testWOCreationNoOwnerFailure(){
        Opportunity objOpps = [Select id from Opportunity LIMIT 1];
        Product2 objProd = [Select id,Auto_Create_Billable_Work_Order__c from Product2 where ProductCode =: PRODUCT1 LIMIT 1];
        objProd.Auto_Create_Billable_Work_Order__c = 'Auto Create Service Support Professional Service FAS Work Order';
        update objProd;
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = Label.WorkOrderTypeRelocation;
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.TimeStamp = TIMESTAMP;
        objWOWrapper.SVMXC_Product = PRODUCT1;
        objWOWrapper.Opportunity = objOpps.Id;
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0]){
                try{
                    httpRest(strWOJSON);
                }catch(Exception e){
                    System.debug('Exception--->'+e);
                    System.assertEquals('No Owner determined based on Account',e.getMessage(),'Incorrect Exception thrown for Owner Error');
                }
            }
        }
        Test.stopTest();
    }
    /**
     *  @author      : KD
     *  @description : method to test Auto WO creation from IP
     **/
    @isTest
    static void testWOCreatioIPSuccess(){
        Opportunity objOpps = [Select id,Primary_Contact__c from Opportunity LIMIT 1];
        objOpps.Product_Interest__c = Label.OpportunityProductInterestRelocation;
        update objOpps;
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = Label.WorkOrderTypeRelocation;
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.TimeStamp = TIMESTAMP;
        objWOWrapper.SVMXC_Product = PRODUCT1;
        objWOWrapper.SVMXC_Component = IP12345;
        objWOWrapper.Opportunity = objOpps.Id;
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            update new Contact(Id=objOpps.Primary_Contact__c,OwnerId = lstUsers[0].Id);
            System.runAs(lstUsers[0]){
                httpRest(strWOJSON);
            }
        }
        Test.stopTest();
        List<SVMXC__Service_Order__c> lstWO = [Select id,ERP_Order_Number__c,SVMXC__Product__c from SVMXC__Service_Order__c where ERP_Order_Number__c =: ERP_ORDER];
        System.assert(!lstWO.isEmpty(),WOERROR);
        List<SVMXC__Installed_Product__c> lstIP = [Select id,SVMXC__Product__c from SVMXC__Installed_Product__c where ERP_Equipment_ID__c =: IP12345];
        System.assertEquals(lstIP[0].SVMXC__Product__c,lstWO[0].SVMXC__Product__c,'Product not set correctly');
    }
    /**
     *  @author      : Sai
     *  @description : method to test Auto create WorkOrder
     **/
    @isTest
    static void testRelocationSuccess(){
        Opportunity objOpps = [Select id,Primary_Contact__c from Opportunity LIMIT 1];
        Product2 objProd = [Select id,Auto_Create_Billable_Work_Order__c from Product2 where ProductCode =: PRODUCT1 LIMIT 1];
        objProd.Auto_Create_Billable_Work_Order__c = '';
        update objProd;
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = Label.WorkOrderTypeRelocation;
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.TimeStamp = TIMESTAMP;
        objWOWrapper.SVMXC_Product = PRODUCT1;
        objWOWrapper.SVMXC_Component = IP12345;
        objWOWrapper.Opportunity = objOpps.Id;
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            update new Contact(Id=objOpps.Primary_Contact__c,OwnerId = lstUsers[0].Id);
            System.runAs(lstUsers[0]){
                httpRest(strWOJSON);
            }
        }
        system.runAs(lstusers[0]){
            try{
                httpRest(strWOJSON);
            }catch(Exception e){
                system.assertEquals('Outdated Payload Received',e.getMessage(),'Incorrect payload thrown for Outloaded payload');
            }
        }
        Test.stopTest();
    }
    /**
     *  @author      : KD
     *  @description : method to test Update PO
     **/
    @isTest
    static void testWOUpdatePO(){
        Opportunity objOpps = [Select id from Opportunity where Name = 'opp2' LIMIT 1];
        SVMXC__Service_Order__c objWO = [Select id,name,SVMX_PS_Subject__c from SVMXC__Service_Order__c where SVMX_PS_Subject__c = 'Test WO PO Update'];
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = Label.WorkOrderTypeRelocation;
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.TimeStamp = TIMESTAMP;
        objWOWrapper.SVMXC_Product = PRODUCT1;
        objWOWrapper.SVMXC_Component = IP12345;
        objWOWrapper.Opportunity = objOpps.Id;
        objWOWrapper.WorkOrderNumber = objWO.Name;
        objWOWrapper.PO_Number = 'PO12345';
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0]){
                httpRest(strWOJSON);
            }
            List<SVMXC__Service_Order__c> lstWO1 = [Select id,name,PO_Number__c,SVMX_PS_Subject__c,SVMXC__Billing_Type__c from SVMXC__Service_Order__c where SVMX_PS_Subject__c = 'Test WO PO Update' and PO_Number__c = 'PO12345'];
            System.assert(!lstWO1.isEmpty(),'Work Order not Updated');
            System.assertEquals('Billable',lstWO1[0].SVMXC__Billing_Type__c,'Billing Type not set');
            objWOWrapper.TimeStamp = '1622640580292';
            strWOJSON = JSON.serialize(objWOWrapper);
            System.runAs(lstUsers[0]){
                try{
                    httpRest(strWOJSON);
                }catch(Exception e){
                    System.assertEquals('Outdated Payload recieved',e.getMessage(),'Incorrect Exception thrown for Outdated Payload');
                }
            }

        }
        Test.stopTest();
    }
    /**
     *  @author      : KD
     *  @description : method to test failure
     **/
    @isTest
    static void testWOCreationNoFailure(){
        Opportunity objOpps = [Select id,Primary_Contact__c from Opportunity LIMIT 1];
        Product2 objProd = [Select id,Auto_Create_Billable_Work_Order__c from Product2 where ProductCode =: PRODUCT1 LIMIT 1];
        objProd.Auto_Create_Billable_Work_Order__c = 'Auto Create Service Support Professional Service FAS Work Order';
        update objProd;
        Account acc = [Select id from Account LIMIT 1];
        List<User> lstUsersFS = [SELECT Id
                               FROM User 
                               WHERE Profile.Name =: System.label.Field_Service and IsActive = true
                               LIMIT 1];
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test1', 'country');
        insert serviceTeam;

        SVMXC__Service_Group_Members__c technicianFAS = TestDataFieldService.createTechnician(lstUsersFS[0].Id, 'Test Technician1', serviceTeam.Id);
        technicianFAS.SVMXC__Email__c='a@b.com';
        List<SVMXC__Service_Group_Members__c> lstFieldSupport = new List<SVMXC__Service_Group_Members__c>();
        lstFieldSupport.add(technicianFAS);
        insert lstFieldSupport;

        Account_to_Field_Support__c accToFieldSupport = TestDataFieldService.createAccountToFieldSupport(acc.Id, Label.Field_Support_User_Role_Primary_FAS, lstFieldSupport[0].Id);
        insert accToFieldSupport;
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = Label.WorkOrderTypeRelocation;
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.TimeStamp = TIMESTAMP;
        objWOWrapper.SVMXC_Product = PRODUCT1;
        objWOWrapper.Opportunity = objOpps.Id;
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            update new Contact(Id=objOpps.Primary_Contact__c,OwnerId = lstUsers[0].Id);
            System.runAs(lstUsers[0]){
                try{
                    httpRest(strWOJSON);
                }catch(Exception e){
                    System.debug('Exception--->'+e);
                }
            }
        }
        Test.stopTest();
        List<SVMXC__Service_Order__c> lstWO1 = [Select id,name,PO_Number__c,SVMX_PS_Subject__c,OwnerId from SVMXC__Service_Order__c where ERP_Order_Number__c =: ERP_ORDER];
        System.assert(!lstWO1.isEmpty(),WOERROR);
        System.assertEquals(lstUsersFS[0].Id,lstWO1[0].OwnerId,'Work Order Owner not correct');
    }
    /**
     *  @author      : KD
     *  @description : method to test auto creation of WO
     **/
    @isTest
    static void testWOCreationMyIlmn(){
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = 'MY';
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.TimeStamp = TIMESTAMP;
        objWOWrapper.SVMXC_Product = PRODUCT1;
        objWOWrapper.Contact_Email = 'kdesai@illumina.com';
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0]){
                httpRest(strWOJSON);
            }
        }
        Test.stopTest();
        List<SVMXC__Service_Order__c> lstWO = [Select id,ERP_Order_Number__c,SVMXC__Order_Type__c,Standalone_Work_Order_Origin__c from SVMXC__Service_Order__c where ERP_Order_Number__c =: ERP_ORDER];
        System.assert(!lstWO.isEmpty(),WOERROR);
        System.assertEquals(ZDSTWorkOrderDataReceiver.STRING_WEB_MY_ILLUMINA_CS,lstWO[0].Standalone_Work_Order_Origin__c,'Work Order Origin not set correctly');
        System.assertEquals(Label.WorkOrderTypeRelocation,lstWO[0].SVMXC__Order_Type__c,'Work Order Type not set correctly');
    }
    /**
     *  @author      : KD
     *  @description : method to test Update PO
     **/
    @isTest
    static void testWOUpdatePOWithoutTimeStamp(){
        Opportunity objOpps = [Select id from Opportunity where Name = 'opp2' LIMIT 1];
        SVMXC__Service_Order__c objWO = [Select id,name,SVMX_PS_Subject__c from SVMXC__Service_Order__c where SVMX_PS_Subject__c = 'Test WO PO Update'];
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = Label.WorkOrderTypeRelocation;
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.SVMXC_Product = PRODUCT1;
        objWOWrapper.SVMXC_Component = IP12345;
        objWOWrapper.Opportunity = objOpps.Id;
        objWOWrapper.WorkOrderNumber = objWO.Name;
        objWOWrapper.PO_Number = 'PO12345';
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0]){
                try{
                    httpRest(strWOJSON);
                }catch(Exception e){
                    System.assertEquals('TimeStamp Missing',e.getMessage(),'Incorrect Exception thrown for TimeeStamp missing');
                }
            }

        }
        Test.stopTest();
    }
    /**
     *  @author      : KD
     *  @description : method to test auto creation of WO
     **/
    @isTest
    static void testWOCreationUnIdentifiedProductReject(){
        //DCP-46835: Start- Query with name
        Opportunity objOpps = [Select id,Primary_Contact__c from Opportunity WHERE Name ='Service Opp'];
        //DCP-46835: End- Query with name
        ZDSTWorkOrderDataReceiverWrapper.WorkOrders objWOWrapper = new ZDSTWorkOrderDataReceiverWrapper.WorkOrders();
        objWOWrapper.SVMXC_Order_Type = 'Preventative Maintenance';
        objWOWrapper.ERP_Order_Number = ERP_ORDER;
        objWOWrapper.SVMXC_Site = TESTSITE;
        objWOWrapper.SVMXC_Company = TESTACCOUNT;
        objWOWrapper.Opportunity = objOpps.Id;
        objWOWrapper.ERP_Order_Line_Number = ERP_ORDERLINE;
        objWOWrapper.TimeStamp = TIMESTAMP;
        objWOWrapper.SVMXC_Product = 'No Identity';
        
        String strWOJSON = JSON.serialize(objWOWrapper);
        Test.startTest();
        if(!lstUsers.isEmpty()){
            update new Contact(Id=objOpps.Primary_Contact__c,OwnerId = lstUsers[0].Id);
            System.runAs(lstUsers[0]){
                httpRest(strWOJSON);
            }
        }
        Test.stopTest();
        List<SVMXC__Service_Order__c> lstWO = [Select id,ERP_Order_Number__c,SVMXC__Order_Type__c from SVMXC__Service_Order__c where ERP_Order_Number__c =: ERP_ORDER];
        System.assert(lstWO.isEmpty(),WOERROR);
        List<Interface_Log__c> lstInterfaceLog = [Select id,Interface_Name__c,Json_Message__c,Result__c from Interface_Log__c where Interface_Name__c = 'ZDST Work Order Outbound' and Result__c =: ilib_LogInterface.RESULT_REJECTED];
        System.assert(!lstInterfaceLog.isEmpty(),'Correct Interfacelog picked');
        System.assert(lstInterfaceLog[0].Json_Message__c.contains(ERP_ORDER),'Inteface log not rejected correctly');
    }

    static void httpRest(String strWOJSON){
		RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = INTERFACENAME;
        req.httpMethod = HTTPPOST;
        req.requestBody = Blob.valueof(strWOJSON);
        RestContext.request = req;
        RestContext.response= res;
        ZDSTWorkOrderDataReceiver.upsertIncomingValues();
	}
}
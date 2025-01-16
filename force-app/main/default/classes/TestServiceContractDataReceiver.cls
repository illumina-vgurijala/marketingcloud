/***************************************************************************************************************************************
 * NAME   : TestServiceContractDataReceiver
 * DESCRIPTION  : TestClass for ServiceContractDataReceiver             
 * @AUTHOR : Vaibhav
 * @DATE   : 14-Oct-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vaibhav                 14-Oct-2018             Initial Version
 * Rahul Bishnoi           26-Feb-2020           Added Conditions for DCP-33359
 * Pooja                   23-Sep-2022           CodeScan Fixes
 * Dhairya                 29-02-2024            CMCM-9
 ****************************************************************************************************************************************/
@isTest
public class TestServiceContractDataReceiver {

    public static SVMXC__Site__c location1Test; //CMCM-9 added public variable to use creating SVMXC__Site__c record
    public static final string STRING_RANDOM_EXTERNAL_ID = '23456';

    /**
     * @description prepare test data.
     * @author Vaibhav
     * @param 
     * @return void 
     **/
    @testSetup static void dataSetup() {

        //DCP-32166 TestData Set up for Order Line Item
        Account acc = TestDataAccount.getNewAccount();
        Contact objContact = TestDataPerson.initContact(acc.Id);
        objContact.PGUID__c = 'abcdef';

        insert objContact;

        Apttus_Config2__Order__c ordersUpdated=new Apttus_Config2__Order__c();
        ordersUpdated.Apttus_Config2__OrderReferenceNumber__c= '1741';
        ordersUpdated.Sales_Order_Number_Unique__c='000093090';
        ordersUpdated.Apttus_Config2__Type__c= 'Standard Order';
        ordersUpdated.Order_Reason__c   =   null;   
        ordersUpdated.ERP_Quote_Number__c = '';
        ordersUpdated.Apttus_Config2__PONumber__c = '';
        ordersUpdated.Apttus_Config2__PODate__c =  null;
        ordersUpdated.Contract_Review_Status__c = '';
        ordersUpdated.Total_Price__c = 9828.00;
        ordersUpdated.Total_Price_USD__c = 9828.00;
        ordersUpdated.Apttus_Config2_SoldToAccountId_ERP_Id__c = '123456';
        ordersUpdated.Ship_To_ERP_Id__c = '123456' ;
        ordersUpdated.Bill_To_ERP_Id__c = '';
        ordersUpdated.Payer_ERP_Id__c = '';
        ordersUpdated.Apttus_Config2_SoldToAccountId_ERP_Id__c = '123456';
        ordersUpdated.Ultimate_Consignee_ERP_Id__c = '123456';
        ordersUpdated.Distributor_ERP_Id__c = '';
        ordersUpdated.PO_Type__c = '';
        ordersUpdated.Order_Status__c = '';
        ordersUpdated.Sales_Order_Number_Unique__c = '1741';
        ordersUpdated.Contact_Name__c = 'Contact person.' ;
        ordersUpdated.ASOP_Number__c = '0002398765';
        ordersUpdated.Apttus_Config2__ActivatedDate__c = System.now();
        ordersUpdated.Apttus_Config2__Status__c  = 'Activated';
        insert ordersUpdated;


        Apttus_Config2__OrderLineItem__c orderLinesUpdated=new Apttus_Config2__OrderLineItem__c();
        orderLinesUpdated.Apttus_Config2__StartDate__c= System.today();
        orderLinesUpdated.Apttus_Config2__EndDate__c= System.today().addDays(140);
        orderLinesUpdated.Apttus_Config2__Quantity__c   =   null;   
        //orderLinesUpdated.Software_Id__c = '';
        orderLinesUpdated.Apttus_Config2__OrderId__c = ordersUpdated.id;
        orderLinesUpdated.Item_Status__c = null;
        orderLinesUpdated.Apttus_Config2__Status__c  = 'Activated';
        orderLinesUpdated.Custom_License_Flag__c = true;
        orderLinesUpdated.ERP_Line_Number_Id__c = STRING_RANDOM_EXTERNAL_ID + '_' + STRING_RANDOM_EXTERNAL_ID;
        insert orderLinesUpdated;

        //CMCM-9 create Service plan record to assign while creating the service contract record
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = STRING_RANDOM_EXTERNAL_ID;
        insert sp;

        List<SVMXC__Service_Contract__c> lstServContract = new List<SVMXC__Service_Contract__c>();
        SVMXC__Service_Contract__c sc = new SVMXC__Service_Contract__c();
        sc.Name = 'listContractsUpdated';
        sc.SVMX_PS_External_ID__c = '34567';
        sc.SVMXC__Service_Plan__c = sp.id; //CMCM-9
        sc.ERP_Header_Contract_Number__c = STRING_RANDOM_EXTERNAL_ID;
        sc.ERP_Contract_Line_Number__c = STRING_RANDOM_EXTERNAL_ID;
        lstServContract.add(sc);
        
        insert lstServContract;
       
    }

    /**
     * @description prepare the replica of JSON coming from SAP.
     * @author Vaibhav
     * @param 
     * @return void 
     **/
    static ServiceContractDataReceiverWrapper.serviceContracts getserviceContractJson(string serviceContractName, string serviceContractExternalId, string coveredProductExternalId ) {
        
        Contact newContact =[select id,PGUID__c from contact where PGUID__c = 'abcdef' limit 1];
        ServiceContractDataReceiverWrapper.CoveredProducts coveredProducts = new ServiceContractDataReceiverWrapper.CoveredProducts();
        coveredProducts.ERP_Equipment_Id = coveredProductExternalId;
        List<ServiceContractDataReceiverWrapper.CoveredLocations> listCoveredLocations = new List<ServiceContractDataReceiverWrapper.CoveredLocations>();
        ServiceContractDataReceiverWrapper.CoveredLocations coveredLocations = new ServiceContractDataReceiverWrapper.CoveredLocations();
        coveredLocations.ERP_Covered_Location = STRING_RANDOM_EXTERNAL_ID;
        coveredLocations.SVMXC_Site = STRING_RANDOM_EXTERNAL_ID;
        CoveredLocations.SiteType = 'WE'; //CMCM-9 added new payload field value 
        listCoveredLocations.add(coveredLocations);
        //CMCM-9-- START added multiple site type to cover the Apex classes
        coveredLocations.ERP_Covered_Location = STRING_RANDOM_EXTERNAL_ID+'1';
        coveredLocations.SVMXC_Site = STRING_RANDOM_EXTERNAL_ID+'1';
        CoveredLocations.SiteType = 'AG'; 
        listCoveredLocations.add(coveredLocations);
        coveredLocations.ERP_Covered_Location = STRING_RANDOM_EXTERNAL_ID+'2';
        coveredLocations.SVMXC_Site = STRING_RANDOM_EXTERNAL_ID+'2';
        listCoveredLocations.add(coveredLocations);
         //CMCM-9-- END

        ServiceContractDataReceiverWrapper.serviceContracts contractRecords = new ServiceContractDataReceiverWrapper.serviceContracts();

        contractRecords.Name = 'service contract';
        contractRecords.SVMX_PS_External_ID = serviceContractExternalId;
        contractRecords.Status = 'Active';
        contractRecords.ERP_Header_Contract_Number = STRING_RANDOM_EXTERNAL_ID;
        contractRecords.SVMXC_Company = STRING_RANDOM_EXTERNAL_ID;
        contractRecords.ERP_Contract_Type = STRING_RANDOM_EXTERNAL_ID;
        contractRecords.ERP_Contract_Line_Number = STRING_RANDOM_EXTERNAL_ID;
        contractRecords.SVMXC_Start_Date = '2018-10-18';
        contractRecords.SVMXC_End_Date = '2018-10-18';
        contractRecords.SVMXC_Service_Plan = STRING_RANDOM_EXTERNAL_ID;
        contractRecords.SVMXC_Cancelation_Notes = 'Test Notes';
        contractRecords.Registration_Contact = newContact.PGUID__c;
        contractRecords.CoveredProducts.add(coveredProducts);
        contractRecords.CoveredLocations.addAll(listCoveredLocations);
        contractRecords.Registration_Contact_Email = 'ABCD@abcd.com';
        contractRecords.Workgroup_ID='ABCD';
        contractRecords.Workgroup_Name='ABCD';
        contractRecords.Zuora_Subscription_ID='ABCD';
        contractRecords.Custom_License_Flag=true;
        contractRecords.Field_Installation=false;
        contractRecords.ERP_Header_Contract_Number=STRING_RANDOM_EXTERNAL_ID;
           
        return contractRecords;
    }

    /**
     * @description create product.
     * @author Vaibhav
     * @param 
     * @return void 
     **/
    static Product2 getProduct(String name, String productCode, String materialNumber) {
        Product2 pr = new Product2();
        pr.Name = name;
        pr.ProductCode = productCode;
        pr.IsActive = true;
        pr.Material_Number__c = materialNumber;
        return pr;
    }



    
    

    /**
     * @description create a new contract through incoming JSON.
     * @author Vaibhav
     * @param 
     * @return void 
     **/
  static testMethod void testContractInsertHTTPPost() {
            
        List < ServiceContractDataReceiverWrapper.serviceContracts > listContractwithCoveredPrds = new List < ServiceContractDataReceiverWrapper.serviceContracts > ();
        ServiceContractDataReceiverWrapper.serviceContracts contractRecords = getserviceContractJson('Test Service', '34567', '33456' );
        listContractwithCoveredPrds.add(contractRecords);
        String contractJSON = JSON.serialize(listContractwithCoveredPrds);

        
        Test.startTest();
        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ServiceContractSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(contractJSON);
        RestContext.request = req;
        RestContext.response = res;
        
        ServiceContractDataReceiver.upsertIncomingValues();
        Test.stopTest();           
        System.assertequals(200, res.statuscode);
            
 
    }
    /**
     * @description Update the exisiting JSON.
     * @author Vaibhav
     * @param 
     * @return void 
     **/
    static testMethod void testContractUpdateHTTPPost() {

        //DCP-30474 Logic 
        Contact con =[select id from contact where PGUID__c = 'abcdef' limit 1];
        List < ServiceContractDataReceiverWrapper.serviceContracts > listContractwithCoveredPrds = new List < ServiceContractDataReceiverWrapper.serviceContracts > ();
        ServiceContractDataReceiverWrapper.serviceContracts contractRecords = getserviceContractJson('Test Service Updated', '34567', '22213');
        listContractwithCoveredPrds.add(contractRecords);
        String contractJSON = JSON.serialize(listContractwithCoveredPrds);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ServiceContractSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(contractJSON);
        RestContext.request = req;
        RestContext.response = res;
        ServiceContractDataReceiver.upsertIncomingValues();

        Test.stopTest();

        SVMXC__Service_Contract__c testServiceContract = [select id,Registration_Contact__c from SVMXC__Service_Contract__c limit 1];
        System.assertequals(200, res.statuscode);
        System.assertequals(con.id,testServiceContract.Registration_Contact__c);

    }
	
	 /**
     * @description Update the exisiting JSON to cancel a contract.
     * @author Naomi
     * @param 
     * @return void 
     **/
    static testMethod void testContractUpdateCanceled() {

        List < ServiceContractDataReceiverWrapper.serviceContracts > listContractwithCoveredPrds = new List < ServiceContractDataReceiverWrapper.serviceContracts > ();
        ServiceContractDataReceiverWrapper.serviceContracts contractRecords = getserviceContractJson('Test Service Updated', '34567', '22213');
        contractRecords.Status = 'Canceled';
        listContractwithCoveredPrds.add(contractRecords);
        String contractJSON = JSON.serialize(listContractwithCoveredPrds);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ServiceContractSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(contractJSON);
        RestContext.request = req;
        RestContext.response = res;
        ServiceContractDataReceiver.upsertIncomingValues();

        Test.stopTest();

        System.assertequals(200, res.statuscode);

    }

     /**
     * @description Update the exisiting JSON and product to cover the CMCM-9 US
     * @author Dhairya Shah
     * @param 
     * @return void 
     **/

     static testMethod void testCoveredLocation() {
        //DCP-30474 Logic 
        Account objAccountTest = TestDataAccount.getNewAccount(); //create account
        objAccountTest.Account_Group__c = 'Distributor';
        update objAccountTest;


        System.assertequals(true, objAccountTest!=null);

        List<SVMXC__Site__c> lstSites = new LIst<SVMXC__Site__c>();
        location1Test = new SVMXC__Site__c();
        location1Test.Name = 'Test Location 1';
        location1Test.SVMXC__Account__c = objAccountTest.Id;
        location1Test.SVMXC__Stocking_Location__c = true;
        location1Test.Type__c='Ship To';
        location1Test.ERP_Customer_ID__c=STRING_RANDOM_EXTERNAL_ID;
        lstSites.add(location1Test);

        location1Test = new SVMXC__Site__c();
        location1Test.Name = 'Test Location 2';
        location1Test.SVMXC__Account__c = objAccountTest.Id;
        location1Test.SVMXC__Stocking_Location__c = true;
        location1Test.Type__c='Sold TO';
        location1Test.ERP_Customer_ID__c=STRING_RANDOM_EXTERNAL_ID+'1';
        lstSites.add(location1Test);

        location1Test = new SVMXC__Site__c();
        location1Test.Name = 'Test Location 3';
        location1Test.SVMXC__Account__c = objAccountTest.Id;
        location1Test.SVMXC__Stocking_Location__c = true;
        location1Test.Type__c='Ultimate Consignee';
        location1Test.ERP_Customer_ID__c=STRING_RANDOM_EXTERNAL_ID+'2';
        lstSites.add(location1Test);

        insert lstSites;
        System.assertequals(3, lstSites.size());

        Product2 pd = getProduct('test Pd',STRING_RANDOM_EXTERNAL_ID,STRING_RANDOM_EXTERNAL_ID);
        pd.Service_Level__c = 'DEDICATE';
        INSERT pd;

        //Contact con =[select id from contact where PGUID__c = 'abcdef' limit 1];
        List < ServiceContractDataReceiverWrapper.serviceContracts > listContractwithCoveredPrds = new List < ServiceContractDataReceiverWrapper.serviceContracts > ();
        ServiceContractDataReceiverWrapper.serviceContracts contractRecords = getserviceContractJson('Test Service Updated', '34567', '22213');
        listContractwithCoveredPrds.add(contractRecords);
        String contractJSON = JSON.serialize(listContractwithCoveredPrds);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ServiceContractSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(contractJSON);
        RestContext.request = req;
        RestContext.response = res;
        ServiceContractDataReceiver.upsertIncomingValues();

        Test.stopTest();

        System.assertequals(200, res.statuscode);

    }


    

}
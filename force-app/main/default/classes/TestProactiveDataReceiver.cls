/**
* Description : Test class to test ProactiveDataReceiver
* Dhairya Shah       11-Oct-2024             CMCM-5165      
****
*/
@isTest
public class TestProactiveDataReceiver {

    public static final string INSTRUMENT_SERIAL = 'M99999';

    @testSetup static void dataSetup() {

        //create Account.
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        insert acc;

        //create Installed product.
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.SVMXC__Serial_Lot_Number__c = INSTRUMENT_SERIAL;
        insert objInstalledProduct;

        //create Case.
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Phone = '12334566');
        insert con;
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.SVMXC__Component__c = objInstalledProduct.Id;
        insert cs;

        //create Work Order.
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c = 'Service Activities';
        workOrder.Is_Auto_Created__c = true;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        insert workOrder;



    }



    static ProactiveDataReceiverWrapper.Proactive getProactiveJson(String instrumentSerial, String severity, string assocaitedCase) {

        /****** POPULATE THE WRAPPER WITH DATA **************/

        //create header for Service BOM JSON.
        ProactiveDataReceiverWrapper.Proactive proactiveRecords = new ProactiveDataReceiverWrapper.Proactive();
        proactiveRecords.InstrumentSerial = instrumentSerial;
        proactiveRecords.Account = '6000020002';
        proactiveRecords.Component = 'Test Component Description';
        proactiveRecords.Summary = 'Test Summary Update';
        proactiveRecords.SWErrorCode = '0192';
        proactiveRecords.Detail = 'Test Detail';
        proactiveRecords.Severity = severity;
        proactiveRecords.AssociatedCase = assocaitedCase;


        //return the wrapper object.
        return proactiveRecords;
    }

    static testMethod void testProactiveInsertHTTPPost() {
    
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Integration Service SnapLogic'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SNAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        //holds the wrapper records in list.
        List < ProactiveDataReceiverWrapper.Proactive > lstProactiveRecords = new List < ProactiveDataReceiverWrapper.Proactive > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        ProactiveDataReceiverWrapper.Proactive proactiveRecords = getProactiveJson(INSTRUMENT_SERIAL, 'Critical', '');

        //pass it over to a list.  
        lstProactiveRecords.add(proactiveRecords);

        //convert the apex list into a Json structure.
        String proactiveJSON = JSON.serialize(lstProactiveRecords);

        

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProactivesyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(proactiveJSON);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        System.runAs(u) {
        ProactiveDataReceiver.upsertIncomingValues();
        }
        Test.stopTest();

        //make sure the status is success.
        System.assert([select count() from svmxc__service_order__c] > 0);

    }


    static testMethod void testProactiveUpdateCriticalPost() {

        Case caseRecord = [Select Id, CaseNumber from Case Limit 1];
        system.debug('caseRecord ' + caseRecord);

        SVMXC__Service_Order__c workOrderRecord = [Select Id, Name, SVMXC__Case__r.CaseNumber from SVMXC__Service_Order__c Limit 1];
        system.debug('workOrderRecord ' + workOrderRecord);

        //holds the wrapper records in list.
        List < ProactiveDataReceiverWrapper.Proactive > lstProactiveRecords = new List < ProactiveDataReceiverWrapper.Proactive > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        ProactiveDataReceiverWrapper.Proactive proactiveRecords = getProactiveJson(INSTRUMENT_SERIAL, 'Critical', caseRecord.CaseNumber);

        //pass it over to a list.  
        lstProactiveRecords.add(proactiveRecords);

        //convert the apex list into a Json structure.
        String proactiveJSON = JSON.serialize(lstProactiveRecords);


        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProactivesyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(proactiveJSON);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProactiveDataReceiver.upsertIncomingValues();
        Test.stopTest();

        //make sure the status is success.
        System.assertequals(200, res.statuscode);

    }


    static testMethod void testProactiveUpdateInfoPost() {


        //holds the wrapper records in list.
        List < ProactiveDataReceiverWrapper.Proactive > lstProactiveRecords = new List < ProactiveDataReceiverWrapper.Proactive > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        ProactiveDataReceiverWrapper.Proactive proactiveRecords = getProactiveJson(INSTRUMENT_SERIAL, 'Info', '');

        //pass it over to a list.  
        lstProactiveRecords.add(proactiveRecords);

        //convert the apex list into a Json structure.
        String proactiveJSON = JSON.serialize(lstProactiveRecords);


        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProactivesyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(proactiveJSON);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProactiveDataReceiver.upsertIncomingValues();
        Test.stopTest();

        //make sure the status is success.
        System.assertequals(200, res.statuscode);

    }


    static testMethod void testProactiveQueryInstalledProduct() {

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/ProactiveSyncInterface/SVMXC__Installed_Product__c/M99999';
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List < SVMXC__Installed_Product__c > installedProdResp = ProactiveDataReceiver.getInfo();
        Test.stopTest();

        //Asset if the same installed went out as response.
        system.assertEquals('Test IP',installedProdResp[0].Name);
    }


    static testMethod void testProactiveQueryCase() {
    //status,CreatedDate field added by prashanth 
        Case caseRecord = [Select Id, CaseNumber,Status,CreatedDate from Case Limit 1];
        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        //added by prashanth
        //req.requestURI = '/services/apexrest/ProactiveSyncInterface/Case/M99999/NA/NA/NA';
        req.requestURI = '/services/apexrest/ProactiveSyncInterface/Case/M99999/'+caseRecord.Status+'/NA/'+caseRecord.CaseNumber;
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List < Case > caseResp = ProactiveDataReceiver.getInfo();
        Test.stopTest();

        //Asset if the same case went out as response.
        system.assertEquals(caseResp[0].CaseNumber, caseRecord.CaseNumber);

    }

    static testMethod void testProactiveQueryWorkOrder() {

        SVMXC__Service_Order__c workOrderRecord = [Select Id, Name,SVMXC__Order_Status__c,CreatedDate from SVMXC__Service_Order__c Limit 1];

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        //req.requestURI = '/services/apexrest/ProactiveSyncInterface/SVMXC__Service_Order__c/M99999/NA/NA/NA';
        //added by prashanth
        req.requestURI = '/services/apexrest/ProactiveSyncInterface/SVMXC__Service_Order__c/M99999/'+workOrderRecord.SVMXC__Order_Status__c+'/NA/'+workOrderRecord.Name;
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List < SVMXC__Service_Order__c > workOrderResp = ProactiveDataReceiver.getInfo();
        Test.stopTest();

        //Asset if the same work order went out as response.
        system.assertEquals(workOrderResp[0].Name, workOrderRecord.Name);

    }


    static testMethod void testProactiveQueryAccount() {

        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProactiveSyncInterface/Account/Test Acc/NA';
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List < Account > accountResp = ProactiveDataReceiver.getInfo();
        Test.stopTest();

        //Asset if the same account went out as response.
        system.assertEquals('Test Acc',accountResp[0].Name);

    }
    
    static testMethod void testProactiveUpdateDummySeverityPost() {

        Case caseRecord = [Select Id, CaseNumber from Case Limit 1];
        system.debug('caseRecord ' + caseRecord);

        SVMXC__Service_Order__c workOrderRecord = [Select Id, Name, SVMXC__Case__r.CaseNumber from SVMXC__Service_Order__c Limit 1];
        system.debug('workOrderRecord ' + workOrderRecord);

        //holds the wrapper records in list.
        List < ProactiveDataReceiverWrapper.Proactive > lstProactiveRecords = new List < ProactiveDataReceiverWrapper.Proactive > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        ProactiveDataReceiverWrapper.Proactive proactiveRecords = getProactiveJson(INSTRUMENT_SERIAL, 'DummySeverity', caseRecord.CaseNumber);

        //pass it over to a list.  
        lstProactiveRecords.add(proactiveRecords);

        //convert the apex list into a Json structure.
        String proactiveJSON = JSON.serialize(lstProactiveRecords);


        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProactivesyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(proactiveJSON);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProactiveDataReceiver.upsertIncomingValues();
        Test.stopTest();

        //make sure the status is success.
        System.assertequals(200, res.statuscode);

    }
	
	static testMethod void testProactiveUpdateWarningPost() {

        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Integration Service SnapLogic'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', FirstName='SNAP Service', LastName='Integration', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        Case caseRecord = [Select Id, CaseNumber from Case Limit 1];
        system.debug('caseRecord ' + caseRecord);

        SVMXC__Service_Order__c workOrderRecord = [Select Id, Name, SVMXC__Case__r.CaseNumber from SVMXC__Service_Order__c Limit 1];
        system.debug('workOrderRecord ' + workOrderRecord);

        //holds the wrapper records in list.
        List < ProactiveDataReceiverWrapper.Proactive > lstProactiveRecords = new List < ProactiveDataReceiverWrapper.Proactive > ();

        //get the wrapper object.
        //Passing new unique numbers will insert the data.
        ProactiveDataReceiverWrapper.Proactive proactiveRecords = getProactiveJson(INSTRUMENT_SERIAL, 'Warning', caseRecord.CaseNumber);

        //pass it over to a list.  
        lstProactiveRecords.add(proactiveRecords);

        //convert the apex list into a Json structure.
        String proactiveJSON = JSON.serialize(lstProactiveRecords);


        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProactivesyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(proactiveJSON);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        System.runAs(u) {
        ProactiveDataReceiver.upsertIncomingValues();
        }
        Test.stopTest();

        //make sure the status is success.
        System.assertequals(200, res.statuscode);

    }



}
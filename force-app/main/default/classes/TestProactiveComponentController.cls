/***************************************************************************************************************************************
* NAME         : TestProactiveComponentController
* DESCRIPTION  : Test class for ProactiveComponentController and ProactiveMetricHandlingController utility class
*                    
* @AUTHOR      : Raviteja Vakkalagadda
* @DATE        : 21-Jun-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ----------------------------------------------------------------------------------------------------------------------------------------

*****************************************************************************************************************************************/
@isTest
public class TestProactiveComponentController {
    
    static Case cs;
    public static final String STRING_ACCOUNT = 'Test Acc';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final String STRING_SHIPPING_TYPE_TRUNK = 'Trunk';
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    public static final String STRING_WO_STATUS_IN_PROGRESS = 'In Progress';
    
    /***************************************************************************************
* Author: Raviteja
* Description: Initial Test data setup of Account,contact,Product,IP,Case and Work Order
* Params :None
*****************************************************************************************/
    @testSetup
    public static void initializeTestData()
    {
        Feature.setMockFeatureFlag('ServiceAssociatedProducts', true);
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
        
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //Product Data
        Product2 objProduct=TestDataFieldService.createProduct('TestProduct','Instrument');
        objProduct.Product_Category__c = 'MiSeq';
        objProduct.ProductCode = 'TestProduct';
        insert objProduct;
        
        //Installed Product
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('TestIP', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        objInstalledProduct.Operation_Status__c='Off';
        objInstalledProduct.SVMXC__Product__c = objProduct.Id;
        objInstalledProduct.SVMXC__Serial_Lot_Number__c = 'FS10001248';
        INSERT objInstalledProduct;
        
        //Link Installed Product
        cs = TestDataCase.initServiceRequestCase(con);
        cs.SVMXC__Component__c = objInstalledProduct.Id;
        insert cs;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE_REMOTE_SUPPORT, cs.Id, 'Initiated');
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c = true; 
        Test.startTest();
        insert workOrder;
        Test.stopTest();
        
        //Proactive Run Detail Record
        Proactive_Run_Detail__c prRec = new Proactive_Run_Detail__c();
        prRec.Work_Order__c=workOrder.Id;
        prRec.Case__c=cs.Id;
        prRec.Notes__c='TestNotes';
        prRec.Run_ID__c='208848659';
        Insert prRec;
        
        
    }
    
    
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the NovaSeq product category run metrics 'save' funtionality
* Params :None
*****************************************************************************************/
    
    static testMethod void testNovaSeqMetrics() {
        String runMetrics = '{"category":"NovaSeq","runId":"214231038","serialNumber":"A00993","env":"usa","id":"2523616","isProactiveUpdate":false}';
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Installed_Product__c installedProdRec = [SELECT Id from SVMXC__Installed_Product__c limit 1];
        
        
        ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper = new ProactiveComponentController.SaveMetricRunWrapper();
        //Prepare JSON for NOVASEQ Category
        saveRunWrapper.jsonRes = '{"id":"2354117","runId":"208848659","controlSoftwareVersion":"1.7.5","proactiveLink":"https://proactiveportal-test.illumina.com/run/ipsRunId/2354117","percentPf":71.20739999999999,"gtq30Percent":90.4781,"percentGTQ30Read1":93.7227,"percentGTQ30Read2":89.65662,"yieldTotalG":1331.028,"alignedPercent":0.7439742,"errorRate":0.1994062,"side":"A","occupancyPercent":96.6557,"ucsVersion":"1.6.3.1575","rtaVersion":"v3.4.4","flowcellSerialBarcode":{"value":"HCWGWDSX2","expired":false},"flowcellPartNumber":{"value":"TestProduct","expired":false},"flowcellLotNumber":{"value":"20547919","expired":false},"flowcellExpirationDate":{"value":"2022-05-07T00:00:00.000+00:00","expired":false},"flowcellMode":{"value":"S4","expired":false},"libraryTubeSerialBarcode":{"value":"NV0341204-LIB","expired":false},"libraryTubePartNumber":{"value":"20005221","expired":false},"libraryTubeLotNumber":{"value":"1000009348","expired":false},"libraryTubeExpirationDate":{"value":"2169-12-31T00:00:00.000+00:00","expired":false},"sbsSerialBarcode":{"value":"NV3333189-RGSBS","expired":false},"sbsPartNumber":{"value":"TestProduct","expired":false},"sbsLotNumber":{"value":"20539977","expired":false},"sbsExpirationDate":{"value":"2022-04-27T00:00:00.000+00:00","expired":false},"sbsConsumableVersion":{"value":"3","expired":false},"clusterSerialBarcode":{"value":"NV3305997-RGCPE","expired":false},"clusterPartNumber":{"value":"TestProduct","expired":false},"clusterLotNumber":{"value":"20537772","expired":false},"clusterExpirationDate":{"value":"2022-04-04T00:00:00.000+00:00","expired":false},"bufferSerialBarcode":{"value":"NV5192583-BUFFR","expired":false},"bufferPartNumber":{"value":"TestProduct","expired":false},"bufferLotNumber":{"value":"50000209","expired":false},"bufferExpirationDate":{"value":"2022-03-24T00:00:00.000+00:00","expired":false},"useCustomRead1Primer":false,"useCustomRead2Primer":false,"useCustomIndexRead1Primer":false,"useCustomIndexRead2Primer":null}';
        saveRunWrapper.category = 'NovaSeq';
        saveRunWrapper.recordId = caseRec.Id;
        saveRunWrapper.runNotes = 'Test';
        saveRunWrapper.ipId = installedProdRec.Id;
        saveRunWrapper.selectedRecords = '[{"expirationDate":"2022-02-19","expired":false,"lotNumber":"20518852","partNumber":"TestProduct","selected":true,"serialNumber":"NV3225357-RGCPE"}]';
        saveRunWrapper.id = '12345';
        saveRunWrapper.env = 'usa';
        saveRunWrapper.serialNumber = 'A00992';
        saveRunWrapper.readLength = '151|10|10|151';
        saveRunWrapper.runStartDate = Date.newInstance(2021, 09, 9);
        saveRunWrapper.runEndDate = Date.newInstance(2021, 10, 10);
        saveRunWrapper.runStatus = 'Completed';
        saveRunWrapper.isProactiveUpdate = false;
        String saveRunMetrics = Json.serialize(saveRunWrapper);
        system.assertNotEquals(' ', saveRunMetrics, 'Wrapper Data Not Formed');
        
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'NovaSeq');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.getRunMetrics(runMetrics);
        ProactiveComponentController.saveMetrics(saveRunMetrics);
        test.stopTest();
    }
    
    
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the MiSeq product category run metrics 'save' funtionality
* Params :None
*****************************************************************************************/
    
    static testMethod void testMiSeqMetrics() {
        String runMetrics = '{"category":"MiSeq","runId":"214231038","serialNumber":"A00993","env":"usa","id":"2523616","isProactiveUpdate":false}';
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Installed_Product__c installedProdRec = [SELECT Id from SVMXC__Installed_Product__c limit 1];
        
        ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper = new ProactiveComponentController.SaveMetricRunWrapper();
        saveRunWrapper.jsonRes = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","fpgaVersion":"some version","flowcellRfidTagSerialNumber":{"value":"000000000-DCVKV","expired":false},"flowcellRfidTagPartNumber":{"value":"TestProduct","expired":false},"flowcellRfidTagExpirationDate":{"value":"2022-04-08T00:00:00.000+00:00","expired":false},"flowcellRfidTagLotNumber":{"value":"","expired":false},"reagentKitRfidTagSerialNumber":{"value":"MS3084532-500V2","expired":false},"reagentKitRfidTagPartNumber":{"value":"TestProduct","expired":false},"reagentKitRfidTagExpirationDate":{"value":"2022-03-22T00:00:00.000+00:00","expired":false},"reagentKitRfidTagLotNumber":{"value":"","expired":false},"pr2BottleRfidTagSerialNumber":{"value":"MS2965575-00PR2","expired":false},"pr2BottleRfidTagPartNumber":{"value":"TestProduct","expired":false},"pr2BottleRfidTagExpirationDate":{"value":"2022-05-06T00:00:00.000+00:00","expired":false},"pr2BottleRfidTagLotNumber":{"value":"","expired":false},"proactiveLink":"some link"}';
        saveRunWrapper.category = 'MiSeq';
        //Prepare JSON for MiSeq Category
        saveRunWrapper.recordId = caseRec.Id;
        saveRunWrapper.runNotes = 'Test';
        saveRunWrapper.ipId = installedProdRec.Id;
        saveRunWrapper.selectedRecords = '[{"expirationDate":"2022-02-19","expired":false,"lotNumber":"20518852","partNumber":"20031056","selected":true,"serialNumber":"NV3225357-RGCPE"}]';
        saveRunWrapper.id = '12345';
        saveRunWrapper.env = 'usa';
        saveRunWrapper.serialNumber = 'A00993';
        saveRunWrapper.readLength = '151|10|10|151';
        saveRunWrapper.isProactiveUpdate = false;
        String saveRunMetrics = Json.serialize(saveRunWrapper);
        system.assertNotEquals(' ', saveRunMetrics, 'Wrapper Data Not Formed');
        
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'MiSeq');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.getRunMetrics(runMetrics);
        ProactiveComponentController.saveMetrics(saveRunMetrics);
        test.stopTest();
    }
    
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the HiSeq product category run metrics 'save' funtionality
* Params :None
*****************************************************************************************/
    
    static testMethod void testHiSeqMetrics(){
        
        String runMetrics = '{"category":"HiSeq","runId":"214231038","serialNumber":"A00993","env":"usa","id":"2523616","isProactiveUpdate":false}';
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Installed_Product__c installedProdRec = [SELECT Id from SVMXC__Installed_Product__c limit 1];
        
        ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper = new ProactiveComponentController.SaveMetricRunWrapper();
        //Prepare JSON request for HiSeq Category
        saveRunWrapper.jsonRes = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","fcPosition":"A","flowcellType":{"value":"HiSeq 3000/4000 SR"},"rapidRunChemistry":"","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"firstBaseConfirmation":false,"controlSoftwareVersion":"some version","rtaVersion":"some version","fpgaVersion":"some version","reagentKitsSbsSerialNumber":"A","reagentKitsSbsPrime":false,"reagentKitsPeSerialNumber":"","flowcellSerialNumber":"HLHNMBBXY","proactiveLink":"some link"}';
        saveRunWrapper.category = 'HiSeq';
        saveRunWrapper.recordId = caseRec.Id;
        saveRunWrapper.runNotes = 'Test';
        saveRunWrapper.ipId = installedProdRec.Id;
        saveRunWrapper.selectedRecords = '[{"expirationDate":"2022-02-19","expired":false,"lotNumber":"20518852","partNumber":"20031056","selected":true,"serialNumber":"NV3225357-RGCPE"}]';
        saveRunWrapper.id = '12345';
        saveRunWrapper.env = 'usa';
        saveRunWrapper.serialNumber = 'A00993';
        saveRunWrapper.readLength = '151|10|10|151';
        saveRunWrapper.isProactiveUpdate = false;
        String saveRunMetrics = Json.serialize(saveRunWrapper);
        system.assertNotEquals(' ', saveRunMetrics, 'Wrapper Data Not Formed');
        
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'HiSeq');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.getRunMetrics(runMetrics);
        ProactiveComponentController.saveMetrics(saveRunMetrics); 
        test.stopTest();
    }
    
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the MiniSeq product category run metrics 'save' funtionality
* Params :None
*****************************************************************************************/
    
    
    static testMethod void testMiniSeqMetrics(){
        String runMetrics = '{"category":"MiniSeq","runId":"214231038","serialNumber":"A00993","env":"usa","id":"2523616","isProactiveUpdate":false}';
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Installed_Product__c installedProdRec = [SELECT Id from SVMXC__Installed_Product__c limit 1];
        
        ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper = new ProactiveComponentController.SaveMetricRunWrapper();
        saveRunWrapper.jsonRes = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","systemSuiteVersion":"some version","localRunManagerVersion":"some version","analysisProtalType":"some version","flowcellRfidTagSerialnumber":{"value":"000H3H7VL","expired":false},"flowcellRfidTagPartNumber":{"value":"TestProduct","expired":false},"flowcellRfidTagLotNumber":{"value":"20521545","expired":false},"flowcellRfidTagExpirationDate":{"value":"2022-02-24T00:00:00.000+00:00","expired":false},"reagentKitRfidTagSerialNumber":{"value":"ML2145830-REAGT","expired":false},"reagentKitRfidTagPartNumber":{"value":"TestProduct","expired":false},"reagentKitRfidTagLotNumber":{"value":"20519003","expired":false},"reagentKitRfidTagExpirationDate":{"value":"2022-02-24T00:00:00.000+00:00","expired":false},"usesCustomReadOnePrimer":false,"usesCustomReadTwoPrimer":false,"usesCustomIndexPrimer":false,"usesCustomIndexTwoPrimer":false,"proactiveLink":"some link"}';
        saveRunWrapper.category = 'MiniSeq';
        //Prepare request JSON for MiniSeq Category
        saveRunWrapper.recordId = caseRec.Id;
        saveRunWrapper.runNotes = 'Test';
        saveRunWrapper.ipId = installedProdRec.Id;
        saveRunWrapper.selectedRecords = '[{"expirationDate":"2022-02-19","expired":false,"lotNumber":"20518852","partNumber":"20031056","selected":true,"serialNumber":"NV3225357-RGCPE"}]';
        saveRunWrapper.id = '12345';
        saveRunWrapper.env = 'usa';
        saveRunWrapper.serialNumber = 'A00994';
        saveRunWrapper.readLength = '151|10|10|151';
        saveRunWrapper.isProactiveUpdate = false;
        String saveRunMetrics = Json.serialize(saveRunWrapper);
        system.assertNotEquals(' ', saveRunMetrics, 'Wrapper Data Not Formed');
        
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'MiniSeq');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.getRunMetrics(runMetrics);
        ProactiveComponentController.saveMetrics(saveRunMetrics); 
        test.stopTest();
    }
    
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the iSeq product category run metrics 'save' funtionality
* Params :None
*****************************************************************************************/
    
    static testMethod void testISeqMetrics(){
        
        String runMetrics = '{"category":"iSeq","runId":"214231038","serialNumber":"A00993","env":"usa","id":"2523616","isProactiveUpdate":false}';
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Installed_Product__c installedProdRec = [SELECT Id from SVMXC__Installed_Product__c limit 1];
        
        ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper = new ProactiveComponentController.SaveMetricRunWrapper();
        saveRunWrapper.jsonRes = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","occupancyPercent":15.2,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","systemSuiteVersion":"some version","firmwareVersion":"some version","localRunManagerVersion":"some version","localRunManagerRunId":13013,"flowcellEepromTagSerialNumber":{"value":"BPA73117-1317","expired":false},"flowcellEepromTagPartNumber":{"value":"TestProduct","expired":false},"flowcellEepromTagLotNumber":{"value":"20516489","expired":false},"flowcellEepromTagExpirationDate":{"value":"2022-01-27T00:00:00.000+00:00","expired":false},"reagentKitRfidTagSerialNumber":{"value":"FY0018299-FC7","expired":false},"reagentKitRfidTagPartNumber":{"value":"TestProduct","expired":false},"reagentKitRfidTagLotNumber":{"value":"20530645","expired":false},"reagentKitRfidTagExpirationDate":{"value":"2022-04-04T00:00:00.000+00:00","expired":false},"proactiveLink":"some link"}';
        saveRunWrapper.category = 'iSeq';
        saveRunWrapper.recordId = caseRec.Id;
        saveRunWrapper.runNotes = 'Test';
        //Prepare JSON request for Iseq Category
        saveRunWrapper.ipId = installedProdRec.Id;
        saveRunWrapper.selectedRecords = '[{"expirationDate":"2022-02-19","expired":false,"lotNumber":"20518852","partNumber":"20031056","selected":true,"serialNumber":"NV3225357-RGCPE"}]';
        saveRunWrapper.id = '12345';
        saveRunWrapper.env = 'usa';
        saveRunWrapper.serialNumber = 'A00994';
        saveRunWrapper.readLength = '151|10|10|151';
        saveRunWrapper.isProactiveUpdate = false;
        String saveRunMetrics = Json.serialize(saveRunWrapper);
        system.assertNotEquals(' ', saveRunMetrics, 'Wrapper Data Not Formed');
        
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'iSeq');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.getRunMetrics(runMetrics);
        ProactiveComponentController.saveMetrics(saveRunMetrics); 
        test.stopTest(); 
        
    }
    
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the NextSeq500 product category run metrics 'save' funtionality
* Params :None
*****************************************************************************************/
    
    static testMethod void testNextSeq500Metrics() {
        String runMetrics = '{"category":"NextSeq 500/550","runId":"214231038","serialNumber":"A00993","env":"usa","id":"2523616","isProactiveUpdate":false}';
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Installed_Product__c installedProdRec = [SELECT Id from SVMXC__Installed_Product__c limit 1];
        
        ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper = new ProactiveComponentController.SaveMetricRunWrapper();
        //Preparing Request format for NextSeq500
        saveRunWrapper.jsonRes = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","systemSuiteVersion":"some version","runManagementType":"","analysisWorkflowType":"","flowcellRfidTagSerialNumber":{"value":"HG3WFBGXJ","expired":false},"flowcellRfidTagPartNumber":{"value":"TestProduct","expired":false},"flowcellRfidTagExpirationDate":{"value":"2023-03-19T00:00:00.000+00:00","expired":false},"flowcellRfidTagLotNumber":{"value":"20529495","expired":false},"pr2BottleRfidTagSerialNumber":{"value":"NS4603043-BUFFR","expired":false},"pr2BottleRfidTagPartNumber":{"value":"TestProduct","expired":false},"pr2BottleRfidTagExpirationDate":{"value":"2022-02-06T00:00:00.000+00:00","expired":false},"pr2BottleRfidTagLotNumber":{"value":"20514809","expired":false},"reagentKitRfidTagSerialNumber":{"value":"NS4645125-REAGT","expired":false},"reagentKitRfidTagPartNumber":{"value":"TestProduct","expired":false},"reagentKitRfidTagExpirationDate":{"value":"2022-02-26T00:00:00.000+00:00","expired":false},"reagentKitRfidTagLotNumber":{"value":"20520891","expired":false},"usesCustomReadOnePrimer":false,"usesCustomReadTwoPrimer":false,"usesCustomIndexPrimer":false,"usesCustomIndexTwoPrimer":false,"proactiveLink":"some link"}';
        saveRunWrapper.category = 'NextSeq 500/550';
        saveRunWrapper.recordId = caseRec.Id;
        saveRunWrapper.runNotes = 'Test';
        saveRunWrapper.ipId = installedProdRec.Id;
        saveRunWrapper.selectedRecords = '[{"expirationDate":"2022-02-19","expired":false,"lotNumber":"20518852","partNumber":"20031056","selected":true,"serialNumber":"NV3225357-RGCPE"}]';
        saveRunWrapper.id = '12345';
        saveRunWrapper.env = 'usa';
        saveRunWrapper.serialNumber = 'A00994';
        saveRunWrapper.readLength = '151|10|10|151';
        saveRunWrapper.isProactiveUpdate = false;
        String saveRunMetrics = Json.serialize(saveRunWrapper);
        system.assertNotEquals(' ', saveRunMetrics, 'Wrapper Data Not Formed');
        
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'NextSeq 500/550');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.getRunMetrics(runMetrics);
        ProactiveComponentController.saveMetrics(saveRunMetrics); 
        test.stopTest();
    }
    
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the NextSeq1000 product category run metrics 'save' funtionality
* Params :None
*****************************************************************************************/
    
    static testMethod void testNextSeq1000Metrics(){
        String runMetrics = '{"category":"NextSeq 1000/2000","runId":"214231038","serialNumber":"A00993","env":"usa","id":"2523616","isProactiveUpdate":false}';
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Installed_Product__c installedProdRec = [SELECT Id from SVMXC__Installed_Product__c limit 1];
        
        ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper = new ProactiveComponentController.SaveMetricRunWrapper();
         //Preparing Request format for NextSeq1000
        saveRunWrapper.jsonRes = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","loadingConcentration":0,"occupancyPercent":15.2,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","copyServiceVersion":"some version","secondaryAnalysisPlatformVersion":"3.7.4","secondaryAnalysisWorkflow":"GenerateFastQ","secondaryAnalysisMode":"Local","flowcellSerialNumber":{"value":"AAAK5WYM5","expired":false},"flowcellPartNumber":{"value":"TestProduct","expired":false},"flowcellLotNumber":{"value":"20513538","expired":false},"flowcellExpirationDate":{"value":"2022-03-06T00:00:00.000+00:00","expired":false},"cartridgeSerialNumber":{"value":"EC0003994-EC11","expired":false},"cartridgePartNumber":{"value":"TestProduct","expired":false},"cartridgeLotNumber":{"value":"20520307","expired":false},"cartridgeExpirationDate":{"value":"2021-10-07T00:00:00.000+00:00","expired":false},"customReadOnePrimer":"None","customReadTwoPrimer":"None","customIndexOnePrimer":"None","customIndexTwoPrimer":"None","proactiveLink":"some link"}';
        saveRunWrapper.category = 'NextSeq 1000/2000';
        saveRunWrapper.recordId = caseRec.Id;
        saveRunWrapper.runNotes = 'Test';
        saveRunWrapper.ipId = installedProdRec.Id;
        saveRunWrapper.selectedRecords = '[{"expirationDate":"2022-02-19","expired":false,"lotNumber":"20518852","partNumber":"20031056","selected":true,"serialNumber":"NV3225357-RGCPE"}]';
        saveRunWrapper.id = '12345';
        saveRunWrapper.env = 'usa';
        saveRunWrapper.serialNumber = 'A00995';
        saveRunWrapper.readLength = '151|10|10|151';
        saveRunWrapper.isProactiveUpdate = false;
        String saveRunMetrics = Json.serialize(saveRunWrapper);
        system.assertNotEquals(' ', saveRunMetrics, 'Wrapper Data Not Formed');
        
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'NextSeq 1000/2000');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.getRunMetrics(runMetrics);
        ProactiveComponentController.saveMetrics(saveRunMetrics); 
        test.stopTest();
    }
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the Genotyping product category run metrics 'save' funtionality
* Params :None
******************************************************************************************/
    
    static testMethod void testGenotypingMetrics(){
        String runMetrics = '{"category":"MA Scanners","runId":"214231038","serialNumber":"A00993","env":"usa","id":"2523616","isProactiveUpdate":false}';
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Installed_Product__c installedProdRec = [SELECT Id from SVMXC__Installed_Product__c limit 1];
        
        ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper = new ProactiveComponentController.SaveMetricRunWrapper();
         //Preparing Request format for  Genotyping/MA Scanner
        saveRunWrapper.jsonRes = '{"id":"1822733","runId":"661664","beadChipBarcode":"205329990058","applicationName":"iScan Control Software","controlSoftwareVersion":"some version","fpgaVersion":"some version","copyServiceVersion":"some version","proactiveLink":"some link"}';
        saveRunWrapper.category = 'MA Scanners';
        saveRunWrapper.recordId = caseRec.Id;
        saveRunWrapper.runNotes = 'Test';
        saveRunWrapper.ipId = installedProdRec.Id;
        saveRunWrapper.selectedRecords = '[{"expirationDate":"2022-02-19","expired":false,"lotNumber":"20518852","partNumber":"20031056","selected":true,"serialNumber":"NV3225357-RGCPE"}]';
        saveRunWrapper.id = '12345';
        saveRunWrapper.env = 'usa';
        saveRunWrapper.serialNumber = 'A00996';
        saveRunWrapper.readLength = '151|10|10|151';
        saveRunWrapper.runStartDate = Date.newInstance(2021, 09, 9);
        saveRunWrapper.runEndDate = Date.newInstance(2021, 10, 10);
        saveRunWrapper.runStatus = 'Completed';
        saveRunWrapper.isProactiveUpdate = false;
        String saveRunMetrics = Json.serialize(saveRunWrapper);
        system.assertNotEquals(' ', saveRunMetrics, 'Wrapper Data Not Formed');
        
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'Genotyping');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.getRunMetrics(runMetrics);
        ProactiveComponentController.saveMetrics(saveRunMetrics); 
        test.stopTest();
    }
    
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the runs returned section
* Params :None
*****************************************************************************************/
    
    static testMethod void testFetchRuns(){
        
        
        String category = 'Novaseq';
        String jsonRes = '{"id":"2354117","runId":"208848659","controlSoftwareVersion":"1.7.5","proactiveLink":"https://proactiveportal-test.illumina.com/run/ipsRunId/2354117","percentPf":71.20739999999999,"gtq30Percent":90.4781,"percentGTQ30Read1":93.7227,"percentGTQ30Read2":89.65662,"yieldTotalG":1331.028,"alignedPercent":0.7439742,"errorRate":0.1994062,"side":"A","occupancyPercent":96.6557,"ucsVersion":"1.6.3.1575","rtaVersion":"v3.4.4","flowcellSerialBarcode":{"value":"HCWGWDSX2","expired":false},"flowcellPartNumber":{"value":"TestProduct","expired":false},"flowcellLotNumber":{"value":"20547919","expired":false},"flowcellExpirationDate":{"value":"2022-05-07T00:00:00.000+00:00","expired":false},"flowcellMode":{"value":"S4","expired":false},"libraryTubeSerialBarcode":{"value":"NV0341204-LIB","expired":false},"libraryTubePartNumber":{"value":"20005221","expired":false},"libraryTubeLotNumber":{"value":"1000009348","expired":false},"libraryTubeExpirationDate":{"value":"2169-12-31T00:00:00.000+00:00","expired":false},"sbsSerialBarcode":{"value":"NV3333189-RGSBS","expired":false},"sbsPartNumber":{"value":"TestProduct","expired":false},"sbsLotNumber":{"value":"20539977","expired":false},"sbsExpirationDate":{"value":"2022-04-27T00:00:00.000+00:00","expired":false},"sbsConsumableVersion":{"value":"3","expired":false},"clusterSerialBarcode":{"value":"NV3305997-RGCPE","expired":false},"clusterPartNumber":{"value":"TestProduct","expired":false},"clusterLotNumber":{"value":"20537772","expired":false},"clusterExpirationDate":{"value":"2022-04-04T00:00:00.000+00:00","expired":false},"bufferSerialBarcode":{"value":"NV5192583-BUFFR","expired":false},"bufferPartNumber":{"value":"TestProduct","expired":false},"bufferLotNumber":{"value":"50000209","expired":false},"bufferExpirationDate":{"value":"2022-03-24T00:00:00.000+00:00","expired":false},"useCustomRead1Primer":false,"useCustomRead2Primer":false,"useCustomIndexRead1Primer":false,"useCustomIndexRead2Primer":null}';
        SVMXC__Installed_Product__c ipRec = [SELECT Id,SVMXC__Serial_Lot_Number__c,Name,Product_Category__c from SVMXC__Installed_Product__c limit 1];
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Service_Order__c workOrdRec = [SELECT Id from SVMXC__Service_Order__c limit 1];
        Proactive_Run_Detail__c prRec = new Proactive_Run_Detail__c();
        prRec.Work_Order__c = workOrdRec.Id;
        Insert prRec;
        system.assertNotEquals(null, prRec.Id, 'Proactive Record Not created');
        
        String runsData= '{"sDate":"2021-09-13","eDate":"2021-09-27","serialNumbers":"A00993","objectName":"Case"}';
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.fetchRuns(runsData);
        ProactiveRunsReturnedWrapper prRun = new ProactiveRunsReturnedWrapper('2366996','Test',40,'Test','Test',10,'Test','Test','Test','Test','Test','Test');
        
        
        system.assert(successProactiveMock!= NULL,'successProactiveMock is not initiated');
        system.assert(prRun!= NULL,'ProactiveRunsReturnedWrapper Wrapper data null');
        test.stopTest();
        ProactiveComponentController.getCaseDetails(caseRec.Id);
        
        ProactiveComponentController.getWODetails(workOrdRec.Id);
        ProactiveComponentController.getCategory(ipRec.Name);
        ProactiveComponentController.fetchAdditionalProducts(jsonRes,category);
        ProactiveComponentController.fetchProactiveRunDetailRec(prRec.Id);
        
    }
    
    
    /***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the fetchAdditionalProducts for HiSeq Category
* Params :None
*****************************************************************************************/
    
    static testMethod void testFetchAdditionalProds(){
        String category = 'HiSeq';
        String jsonRes = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","fcPosition":"A","flowcellType":{"value":"HiSeq 3000/4000 SR"},"rapidRunChemistry":"","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"firstBaseConfirmation":false,"controlSoftwareVersion":"some version","rtaVersion":"some version","fpgaVersion":"some version","reagentKitsSbsSerialNumber":"A","reagentKitsSbsPrime":false,"reagentKitsPeSerialNumber":"","flowcellSerialNumber":"HLHNMBBXY","proactiveLink":"some link"}';
        
        List<ProactiveComponentController.additionalProdWrapper> addWrapLst = new List<ProactiveComponentController.additionalProdWrapper>();
        addWrapLst = ProactiveComponentController.fetchAdditionalProducts(jsonRes,category);
        system.assertNotEquals(null, addWrapLst, 'Additional Products Not fetched');
    }


/***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the fetchAdditionalProducts for NextSeq500 Category
* Params :None
*****************************************************************************************/
    
static testMethod void testFetchAdditionalProdsNext500(){
    String category = 'NextSeq 500/550';
    String jsonRes = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","systemSuiteVersion":"some version","runManagementType":"","analysisWorkflowType":"","flowcellRfidTagSerialNumber":{"value":"HG3WFBGXJ","expired":false},"flowcellRfidTagPartNumber":{"value":"TestProduct","expired":false},"flowcellRfidTagExpirationDate":{"value":"2023-03-19T00:00:00.000+00:00","expired":false},"flowcellRfidTagLotNumber":{"value":"20529495","expired":false},"pr2BottleRfidTagSerialNumber":{"value":"NS4603043-BUFFR","expired":false},"pr2BottleRfidTagPartNumber":{"value":"TestProduct","expired":false},"pr2BottleRfidTagExpirationDate":{"value":"2022-02-06T00:00:00.000+00:00","expired":false},"pr2BottleRfidTagLotNumber":{"value":"20514809","expired":false},"reagentKitRfidTagSerialNumber":{"value":"NS4645125-REAGT","expired":false},"reagentKitRfidTagPartNumber":{"value":"TestProduct","expired":false},"reagentKitRfidTagExpirationDate":{"value":"2022-02-26T00:00:00.000+00:00","expired":false},"reagentKitRfidTagLotNumber":{"value":"20520891","expired":false},"usesCustomReadOnePrimer":false,"usesCustomReadTwoPrimer":false,"usesCustomIndexPrimer":false,"usesCustomIndexTwoPrimer":false,"proactiveLink":"some link"}';
    List<ProactiveComponentController.additionalProdWrapper> addWrapLst = new List<ProactiveComponentController.additionalProdWrapper>();
    addWrapLst = ProactiveComponentController.fetchAdditionalProducts(jsonRes,category);
    system.assertNotEquals(null, addWrapLst, 'Additional Products Not fetched');
}
    
/***************************************************************************************
* Author: Raviteja
* Description: Test Method to cover the fetchAdditionalProducts for NextSeq500 Category
* Params :None
*****************************************************************************************/
    
static testMethod void testFetchAdditionalProdsNext1000(){
    
    String category = 'NextSeq 1000/2000';
    String jsonRes = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","loadingConcentration":"A","occupancyPercent":15.2,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","copyServiceVersion":"some version","secondaryAnalysisPlatformVersion":"3.7.4","secondaryAnalysisWorkflow":"GenerateFastQ","secondaryAnalysisMode":"Local","flowcellSerialNumber":{"value":"AAAK5WYM5","expired":false},"flowcellPartNumber":{"value":"TestProduct","expired":false},"flowcellLotNumber":{"value":"20513538","expired":false},"flowcellExpirationDate":{"value":"2022-03-06T00:00:00.000+00:00","expired":false},"cartridgeSerialNumber":{"value":"EC0003994-EC11","expired":false},"cartridgePartNumber":{"value":"TestProduct","expired":false},"cartridgeLotNumber":{"value":"20520307","expired":false},"cartridgeExpirationDate":{"value":"2021-10-07T00:00:00.000+00:00","expired":false},"customReadOnePrimer":"None","customReadTwoPrimer":"None","customIndexOnePrimer":"None","customIndexTwoPrimer":"None","proactiveLink":"some link"}';
    
    List<ProactiveComponentController.additionalProdWrapper> addWrapLst = new List<ProactiveComponentController.additionalProdWrapper>();
    addWrapLst = ProactiveComponentController.fetchAdditionalProducts(jsonRes,category);

    system.assertNotEquals(null, addWrapLst, 'Additional Products Not fetched');
    }
    
    static testMethod void testfetchFeatureFlag() {
          Feature.setMockFeatureFlag('ServiceAssociatedProducts', true);
          Boolean isOn;
          System.Test.startTest();
          isOn = Feature.isOn('ServiceAssociatedProducts');
          System.Test.stopTest();
          System.assertEquals(true, isOn);
         
     }
    
    /***************************************************************************************
    * Author: Priya Mukherjee
    * Description: Test Method to cover the fetchAdditionalProducts for NextSeqX Series Category
    * Params :None
    *****************************************************************************************/
     static testMethod void testNovaSeqXMetrics() {
        String runMetrics = '{"category":"NovaSeq X Series","runId":"214231038","serialNumber":"A00993","env":"usa","id":"2523616","isProactiveUpdate":false}';
        
        Case caseRec = [SELECT Id from Case limit 1];
        SVMXC__Installed_Product__c installedProdRec = [SELECT Id from SVMXC__Installed_Product__c limit 1];
        
        
        ProactiveComponentController.SaveMetricRunWrapper saveRunWrapper = new ProactiveComponentController.SaveMetricRunWrapper();
        //Prepare JSON for NOVASEQ Category
        saveRunWrapper.jsonRes = '{"id":"2354117","runId":"208848659","controlSoftwareVersion":"1.7.5","proactiveLink":"https://proactiveportal-test.illumina.com/run/ipsRunId/2354117","percentPf":71.20739999999999,"gtq30Percent":90.4781,"percentGTQ30Read1":93.7227,"percentGTQ30Read2":89.65662,"yieldTotalG":1331.028,"alignedPercent":0.7439742,"errorRate":0.1994062,"side":"A","occupancyPercent":96.6557,"ucsVersion":"1.6.3.1575","rtaVersion":"v3.4.4","flowcellSerialBarcode":{"value":"HCWGWDSX2","expired":false},"flowcellPartNumber":{"value":"TestProduct","expired":false},"flowcellLotNumber":{"value":"20547919","expired":false},"flowcellExpirationDate":{"value":"2022-05-07T00:00:00.000+00:00","expired":false},"flowcellMode":{"value":"S4","expired":false},"libraryTubeSerialBarcode":{"value":"NV0341204-LIB","expired":false},"libraryTubePartNumber":{"value":"20005221","expired":false},"libraryTubeLotNumber":{"value":"1000009348","expired":false},"libraryTubeExpirationDate":{"value":"2169-12-31T00:00:00.000+00:00","expired":false},"sbsSerialBarcode":{"value":"NV3333189-RGSBS","expired":false},"sbsPartNumber":{"value":"TestProduct","expired":false},"sbsLotNumber":{"value":"20539977","expired":false},"sbsExpirationDate":{"value":"2022-04-27T00:00:00.000+00:00","expired":false},"sbsConsumableVersion":{"value":"3","expired":false},"clusterSerialBarcode":{"value":"NV3305997-RGCPE","expired":false},"clusterPartNumber":{"value":"TestProduct","expired":false},"clusterLotNumber":{"value":"20537772","expired":false},"clusterExpirationDate":{"value":"2022-04-04T00:00:00.000+00:00","expired":false},"bufferSerialBarcode":{"value":"NV5192583-BUFFR","expired":false},"bufferPartNumber":{"value":"TestProduct","expired":false},"bufferLotNumber":{"value":"50000209","expired":false},"bufferExpirationDate":{"value":"2022-03-24T00:00:00.000+00:00","expired":false},"useCustomRead1Primer":false,"useCustomRead2Primer":false,"useCustomIndexRead1Primer":false,"useCustomIndexRead2Primer":null}';
        saveRunWrapper.category = 'NovaSeq X Series';
        saveRunWrapper.recordId = caseRec.Id;
        saveRunWrapper.runNotes = 'Test';
        saveRunWrapper.ipId = installedProdRec.Id;
        saveRunWrapper.selectedRecords = '[{"expirationDate":"2022-02-19","expired":false,"lotNumber":"20518852","partNumber":"TestProduct","selected":true,"serialNumber":"NV3225357-RGCPE"}]';
        saveRunWrapper.id = '12345';
        saveRunWrapper.env = 'usa';
        saveRunWrapper.serialNumber = 'A00992';
        saveRunWrapper.readLength = '151|10|10|151';
        saveRunWrapper.runStartDate = Date.newInstance(2021, 09, 9);
        saveRunWrapper.runEndDate = Date.newInstance(2021, 10, 10);
        saveRunWrapper.runStatus = 'Completed';
        saveRunWrapper.isProactiveUpdate = false;
        String saveRunMetrics = Json.serialize(saveRunWrapper);
        system.assertNotEquals(' ', saveRunMetrics, 'Wrapper Data Not Formed');
        
        test.startTest();
        string successResponse = '200';
        TestProactiveMockClass successProactiveMock = new TestProactiveMockClass(200,successResponse,'NovaSeq');     
        Test.setMock(HttpCalloutMock.class, successProactiveMock);
        ProactiveComponentController.getRunMetrics(runMetrics);
        ProactiveComponentController.saveMetrics(saveRunMetrics);
        test.stopTest();
    }
    

}
/**
 *    @author: Vaibhav
 *    @date:   19-Mar-2021
 *    @description:  test class for LMSCertificationDataReceiver
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *            Sagar Madkaikar                11 Aug 2021        CMCP-21 Added method testLMSCertificationSyncHTTPPostWithoutProductFamily()
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
@isTest 
private class TestLMSCertificationDataReceiver {
      public static final String STRING_PRODUCT_FAMILY_AUTOLOADER_2 = 'Autoloader - 2';
	  public static final String STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT = 'Instrument';

    /*
    * @Description: setup data.
    */
    @TestSetup
    public static void testData() {

        //create LMS Certification Mapping Record.
        LMS_Certification_Mapping__c lmsCertificationMappingObj = new LMS_Certification_Mapping__c();
        lmsCertificationMappingObj.Active__c = true;
        lmsCertificationMappingObj.Certification_Name__c = 'CS: FSE iScan Certification';
        lmsCertificationMappingObj.Product_Family__c = STRING_PRODUCT_FAMILY_AUTOLOADER_2;
        lmsCertificationMappingObj.Certification_ID__c = '00010040';

        insert lmsCertificationMappingObj;
        
        //insert User
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Unique_Id__c = '100292',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'

        );
        insert u;
        System.assert(u.Id != null);

        
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        insert acc;
        system.assertNotEquals(null,acc.id);

        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam('Test', 'country');
        insert serviceTeam;
        system.assertNotEquals(null,serviceTeam.id);

        SVMXC__Service_Group_Members__c technician = TestDataFieldService.createTechnician(UserInfo.getUserId(), 'Test Technician', serviceTeam.id);
        technician.SVMXC__Email__c = 'a@b.com';
        technician.SVMXC__Salesforce_User__c = u.id;
        insert technician;
        system.assertNotEquals(null,technician.id);

        SVMXC__Service_Group_Members__c technicianFAS = TestDataFieldService.createTechnician(UserInfo.getUserId(), 'Test Technician', serviceTeam.id);
        technicianFAS.SVMXC__Email__c = 'b@b.com';
        insert technicianFAS;
        system.assertNotEquals(null,technicianFAS.id);

        Account_to_Field_Support__c accToFieldSupport = TestDataFieldService.createAccountToFieldSupport(acc.id, 'Primary Field Service Engineer', technician.id);
        insert accToFieldSupport;
        system.assertNotEquals(null,accToFieldSupport.id);

        Account_to_Field_Support__c accToFieldSupportFSM = TestDataFieldService.createAccountToFieldSupport(acc.id, 'Primary Field Application Scientist', technicianFAS.id);
        insert accToFieldSupportFSM;
        system.assertNotEquals(null,accToFieldSupportFSM.id);

        //insert event
        Event objEvent = new Event(subject = 'unavailable');
        objEvent.StartDateTime = System.now().addDays(-1);
        objEvent.EndDateTime = System.now().addDays(1);
        insert objEvent;
        System.assert(objEvent.Id != null);

        //insert product
        Product2 objProduct = TestDataFieldService.createProduct('Test Product', STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT);
        objProduct.Family = STRING_PRODUCT_FAMILY_AUTOLOADER_2;
        insert objProduct;
        System.assert(objProduct.Id != null);

        //insert product
        Product2 objProduct2 = TestDataFieldService.createProduct('Test Product 2', STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT);
        objProduct2.Family = STRING_PRODUCT_FAMILY_AUTOLOADER_2;
        insert objProduct2;
        System.assert(objProduct2.Id != null);

        //insert expertise (Service group product)
        SVMXC__Service_Group_Product__c objExpertise = new SVMXC__Service_Group_Product__c(SVMXC__Product__c = objProduct.Id,
            SVMXC__Group_Member__c = technician.Id,
            SVMXC__Service_Group__c = serviceTeam.Id);
        insert objExpertise;
        System.assert(objExpertise.id != null);

    }

    /*
    * @Description: method to test incoming json (postive scenario).
    */
    static testMethod void positiveTestLMSCertificationSyncHTTPPost() {
    string incomingJSON = '{\"MetaData\":{\"EventCreatedDate\":\"2021-03-01T19:20:14.125\"},\"Content\":{\"Certification_Progress_Action_Date\":\"16-Feb-21\",\"Certification_Assignment_Created_On\":\"16-Feb-21\",\"Certification_Assignment_Updated_On\":\"16-Feb-21\",\"Person_Full_Name\":\"Tracy Solomon\",\"Student_Certification_Status\":\"Acquired\",\"Certification_Name\":\"DCP 4 Certification\",\"Certification_Version\":\"3\",\"Certification_ID\":\"00010040\",\"Student_Certification_Assigned_On\":\"16-Feb-21\",\"Student_Certification_Acquired_On\":\"16-Feb-21\",\"Student_Certification_Due_Date\":\"2-Mar-21\",\"Student_Certification_Expiration_Date\":\"2-Mar-21\",\"Person_Username\":\"3187\",\"Person_Person_No\":\"100292\",\"Person_SAM_Account\":\"tsolomon\",\"Person_Email\":\"tsolomon@illumina.com\",\"Person_Employee_Type\":\"Employee\",\"Person_Domain\":\"Internal\"}}';
    
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/LMSCertificationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(incomingJSON);
        RestContext.request = req;
        RestContext.response= res;
        LMSCertificationDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200,res.statuscode);
        //assert the checkbox should be true for product serviced record. 
        SVMXC__Service_Group_Product__c productServiced = [Select Id,Active_Certification__c from SVMXC__Service_Group_Product__c Limit 1];
        System.assertequals(true,productServiced.Active_Certification__c);
        
    }
    
    /*
    * @Description: method to test incoming json (negative scenario).
    */
    static testMethod void negativeTestLMSCertificationSyncHTTPPost() {
    string incomingJSON = '{\"MetaData\":{\"EventCreatedDate\":\"2021-03-01T19:20:14.125\"},\"Content\":{\"Certification_Progress_Action_Date\":\"16-Feb-21\",\"Certification_Assignment_Created_On\":\"16-Feb-21\",\"Certification_Assignment_Updated_On\":\"16-Feb-21\",\"Person_Full_Name\":\"Tracy Solomon\",\"Student_Certification_Status\":\"Acquired\",\"Certification_Name\":\"DCP 4 Certification\",\"Certification_Version\":\"3\",\"Certification_ID\":\"00010040\",\"Student_Certification_Assigned_On\":\"16-Feb-21\",\"Student_Certification_Acquired_On\":\"16-Feb-21\",\"Student_Certification_Due_Date\":\"2-Mar-21\",\"Student_Certification_Expiration_Date\":\"2-Mar-21\",\"Person_Username\":\"3187\",\"Person_Person_No\":\"106192\",\"Person_SAM_Account\":\"tsolomon\",\"Person_Email\":\"tsolomon@illumina.com\",\"Person_Employee_Type\":\"Employee\",\"Person_Domain\":\"Internal\"}}';
    
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/LMSCertificationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(incomingJSON);
        RestContext.request = req;
        RestContext.response= res;
        String responseBack = LMSCertificationDataReceiver.upsertIncomingValues();
        Boolean containsError = responseBack.contains('Error');

        Test.stopTest();
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200,res.statuscode);
        System.assertequals(true,containsError);
        
        
    }

     /*
    * @Description: method to test incoming json (negative scenario).
    */
    static testMethod void testCreateProductServicedForDCPProducts() {
    
    List<Product2> productsList = [Select Id from Product2 Limit 100];
    Test.startTest();
    LMSCertificationDataReceiver.createProductServicedForDCPProducts(new set<Id>{productsList[0].Id});
    Test.stopTest();
    List<SVMXC__Service_Group_Product__c> productServiced = [Select Id,Active_Certification__c from SVMXC__Service_Group_Product__c Limit 100];
    System.assertequals(4,productServiced.size());
        
    }

    /*
    * @Description: method  to test coverage of productQueueable.
    */
    static testMethod void testCreateInstrumentProducts() {
    Test.startTest();
    //insert product
        Product2 objProduct3 = TestDataFieldService.createProduct('Test objProduct3 ', STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT);
        objProduct3.Family = STRING_PRODUCT_FAMILY_AUTOLOADER_2;
        objProduct3.Service_Product_Type__c = STRING_SERVICE_PRODUCT_TYPE_INSTRUMENT;
        insert objProduct3;
    Test.stopTest();
    List<SVMXC__Service_Group_Product__c> productServiced = [Select Id,Active_Certification__c from SVMXC__Service_Group_Product__c limit 100];
    System.assertequals(4,productServiced.size());
    }

    /*
    * @author Sagar Madkaikar
    * @date   17-Aug-2021
    * @Description: CMCP-21:method to test incoming json(Without a Product Family in LMS Mapping Object)
    */
    static testMethod void testLMSCertificationSyncHTTPPostWithoutProductFamily() {

        string incomingJSON = '{\"MetaData\":{\"EventCreatedDate\":\"2021-03-01T19:20:14.125\"},\"Content\":{\"Certification_Progress_Action_Date\":\"16-Feb-21\",\"Certification_Assignment_Created_On\":\"16-Feb-21\",\"Certification_Assignment_Updated_On\":\"16-Feb-21\",\"Person_Full_Name\":\"Tracy Solomon\",\"Student_Certification_Status\":\"Acquired\",\"Certification_Name\":\"DCP 4 Certification\",\"Certification_Version\":\"3\",\"Certification_ID\":\"00010040\",\"Student_Certification_Assigned_On\":\"16-Feb-21\",\"Student_Certification_Acquired_On\":\"16-Feb-21\",\"Student_Certification_Due_Date\":\"2-Mar-21\",\"Student_Certification_Expiration_Date\":\"2-Mar-21\",\"Person_Username\":\"3187\",\"Person_Person_No\":\"100292\",\"Person_SAM_Account\":\"tsolomon\",\"Person_Email\":\"tsolomon@illumina.com\",\"Person_Employee_Type\":\"Employee\",\"Person_Domain\":\"Internal\"}}';
    
        LMS_Certification_Mapping__c lmsMappingIns = [Select Id,Certification_Name__c,Product_Family__c from LMS_Certification_Mapping__c where Certification_Name__c='CS: FSE iScan Certification' limit 1];
        lmsMappingIns.Product_Family__c=null;
        update lmsMappingIns;
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/LMSCertificationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(incomingJSON);
        RestContext.request = req;
        RestContext.response= res;
        LMSCertificationDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.assertequals(200,res.statuscode,'status code not equal to 200');
       } 
    
}
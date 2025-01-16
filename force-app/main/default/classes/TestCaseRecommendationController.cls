/***************************************************************************************************************************************
 * NAME   : TestCaseRecommendationController
 * DESCRIPTION  : TestClass for TestCaseRecommendationController
 *         
 *  
 * @AUTHOR : Shahnawaz
 * @DATE   : 06-08-2022 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shahnawaz            06-08-2022           Initial Version
 * Gladis               08-June-2022         DCP-54039 added method to cover IP with no active contracts and case follow up recommendations
  ****************************************************************************************************************************************/ 
  @isTest(SeeAllData = false)  
  public with sharing class TestCaseRecommendationController {

      public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
      public static final string STRING_CASE_STATUS = 'Initiated';
      public static final string STRING_CASE_ORIGIN = 'Phone - CS';
      public static final String STRING_ACCOUNT = 'Test Acc';
      public static final String BUSINESS_ISSUE = 'Business Issue';
      public static final string STRING_LOCATION = 'Test Location';
      public static final string STRING_STREET = 'Test Street';
      public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
      public static final string STRING_CURRENCY = 'USD';
      public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
      public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
      public static final string STRING_PRODUCT_CODE = 'Test 1234';
      public static Case cs;
      public static Field_Action_Notification__c fan;
      /**  
      *  @AUTHOR - Sheikh Shahnawaz
      *  @RETURN - List<Recommendation>
      *  return  recommendation With Name : "This account is a hot site with at least one open elevation"
      */
      static testMethod void filterRecommendationForElevationAccount() {
              Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
              acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
              insert acc;
          
              Contact con = TestDataPerson.getNewContact(acc.Id);
              Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
              
              Case objCase  = new Case(    
                  Status = 'Initiated',
                  Subject = 'test' ,
                  Description= 'test',
                  Origin = 'Phone-CP',
                  Date_of_Issue_Awareness__c=System.today() -2,
                  Awareness_Date_Difference_Reason__c = 'Logistical delay',
                  ContactId = con.Id,
                  AccountId = acc.Id,
                  RecordTypeId = idCaseRecordTypeId
              );
              insert objCase;
              Test.startTest();
              List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
              
              Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId(); 
              SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                   SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                                   SVMXC__Order_Status__c from 
                                                   SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
              System.assertNotEquals(null,workOrder,'work order is null');
              
              Elevations__c techElev = new Elevations__c();
              techElev.RecordTypeId = technicalElevationRecordType;
              techElev.Elevation_Category__c = 'Standard Technical';
              techElev.Elevation_Status__c = 'Open';
              techElev.Elevation_Owner__c = lstUsers[0].Id;
              techElev.Elevation_Manager__c = lstUsers[0].Id;
              techElev.Plan_of_Action__c = 'test';
              techElev.Work_Order__c = workOrder.Id;
              insert techElev;
              Test.stopTest();
  
              Recommendation recom = new Recommendation();
              recom.name = 'This account is a hot site with at least one open elevation';
              recom.description = 'This account is a hot site with at least one open elevation';
              recom.acceptancelabel ='Accept';
              recom.rejectionlabel = 'Reject';
              List<Recommendation> lstRecomm = new List<Recommendation>();
              lstRecomm.add(recom);
  
              List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
              CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
              inputRequest.recordId=objCase.Id;
              inputRequest.recommendations = lstRecomm;
              inputRequests.add(inputRequest);
              List<List<Recommendation>> listOfrecomm = CaseRecommendationController.generateRecommendation(inputRequests);
              System.assertNotEquals(null,listOfrecomm,' listOfrecomm returned not null');
      }
        /**  
      *  @AUTHOR - Sheikh Shahnawaz
      *  @RETURN - List<Recommendation>
      *  return  recommendations With Name :  "This Contact and/or Installed Product has another Open Case"
                                           :  " Potential Duplicate: This Account has another Opened Case within the last 8 hour"
                                           :  "This Installed Product does not have an Active Service Contract Associated with"
                                           :  "This Case has a Product that may be related to a FAN"
  
      */
      static testmethod void filterRecommendations() {
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert acc;
    
        Contact con = TestDataPerson.getNewContact(acc.Id);
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(acc.Id);
          insert objServiceContract;
          SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
          insert objLocation;
  
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          insert objInstalledProduct;
          
        Test.startTest();
        Case objCase  = new Case(    
            Status = 'Initiated',
            Subject = 'test' ,
            Description= 'test',
            Origin = 'Phone-CP',
            Date_of_Issue_Awareness__c=System.today() -2,
            Awareness_Date_Difference_Reason__c = 'Logistical delay',
            ContactId = con.Id,
            AccountId = acc.Id,
            RecordTypeId = idCaseRecordTypeId
        );
        insert objCase;
        Case objCase2  = new Case(    
            Status = 'Initiated',
            Subject = 'test' ,
            Description= 'test',
            Origin = 'Phone-CP',
            Date_of_Issue_Awareness__c=System.today() -2,
            Awareness_Date_Difference_Reason__c = 'Logistical delay',
            ContactId = con.Id,
            AccountId = acc.Id,
            RecordTypeId = idCaseRecordTypeId
        );
        insert objCase2;
        Test.stopTest();   
            Recommendation recom = new Recommendation();
            recom.name = 'This Contact and or Installed Product has another Open Case';
            recom.description = 'This Contact and or Installed Product has another Open Case';
            recom.acceptancelabel ='Accept';
            recom.rejectionlabel = 'Reject';
            Recommendation recom2 = new Recommendation();
            recom2.name = 'Potential Duplicate This Account has another Opened Case within the last 8 hour';
            recom2.description = 'This Contact and or Installed Product has another Open Case';
            recom2.acceptancelabel ='Accept';
            recom2.rejectionlabel = 'Reject';
  
            List<Recommendation> lstRecomm = new List<Recommendation>();
            lstRecomm.add(recom);
            lstRecomm.add(recom2);

            List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
            CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
            inputRequest.recordId=objCase.Id;
            inputRequest.recommendations = lstRecomm;
            inputRequests.add(inputRequest);
            List<List<Recommendation>> lstRecommendations = CaseRecommendationController.generateRecommendation(inputRequests);
            System.assertNotEquals(null,lstRecommendations,' lstRecommendations returned not null');
      
    }
      /**  
    *  @AUTHOR - Sheikh Shahnawaz
    *  @RETURN - List<Recommendation>
    *  return  recommendations With Name :  "This Contact and/or Installed Product has another Open Case"
                                         :  " Potential Duplicate: This Account has another Opened Case within the last 8 hour"
                                         :  "This Installed Product does not have an Active Service Contract Associated with"
                                         :  "This Case has a Product that may be related to a FAN"

    */
    static testmethod void filterRecommendations2() {
      Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
      acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
      insert acc;
  
      Contact con = TestDataPerson.getNewContact(acc.Id);
      Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
      SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(acc.Id);
        insert objServiceContract;
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;
        
      Test.startTest();
      Case objCase  = new Case(    
          Status = 'Initiated',
          Subject = 'test' ,
          Description= 'test',
          Origin = 'Phone-CP',
          Date_of_Issue_Awareness__c=System.today() -2,
          Awareness_Date_Difference_Reason__c = 'Logistical delay',
          ContactId = con.Id,
          AccountId = acc.Id,
          RecordTypeId = idCaseRecordTypeId
      );
      insert objCase;
      Case objCase2  = new Case(    
          Status = 'Initiated',
          Subject = 'test' ,
          Description= 'test',
          Origin = 'Phone-CP',
          Date_of_Issue_Awareness__c=System.today() -2,
          Awareness_Date_Difference_Reason__c = 'Logistical delay',
          ContactId = con.Id,
          AccountId = acc.Id,
          RecordTypeId = idCaseRecordTypeId
      );
      insert objCase2;
      Test.stopTest();  
          Recommendation recom3 = new Recommendation(); 
          recom3.name = 'This Installed Product does not have an Active Service Contract Associated with';
          recom3.description = 'This Contact and or Installed Product has another Open Case';
          recom3.acceptancelabel ='Accept';
          recom3.rejectionlabel = 'Reject';


          Recommendation recom4 = new Recommendation();
          recom4.name = 'This Case has a Product that may be related to a FAN';
          recom4.description = 'This Case has a Product that may be related to a FAN';
          recom4.acceptancelabel ='Accept';
          recom4.rejectionlabel = 'Reject';
          List<Recommendation> lstRecomm = new List<Recommendation>();
          lstRecomm.add(recom3);
          lstRecomm.add(recom4);

          List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
          CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
          inputRequest.recordId=objCase.Id;
          inputRequest.recommendations = lstRecomm;
          inputRequests.add(inputRequest);
          List<List<Recommendation>> lstRecommendations = CaseRecommendationController.generateRecommendation(inputRequests);
          System.assertNotEquals(null,lstRecommendations,' lstRecommendations returned not null');
    
  }
  /* testSetup method */
      @testSetup
      public static void initializeTestData() {
          // To create a FAN record of record type "Notification"
          FAN =TestDataFieldService.createFAN('Notification');
          insert FAN;
    }
  
    /**  
      *  @AUTHOR - Sheikh Shahnawaz
      *  This methods creates Impacted Product under same product as Product of created Case.
      *  Used to cover "checkForPotentialMatchedFans" on CaseRecommendationController class
      */
      public static testMethod void newFieldActionItem() {
          initializeTestData();
  
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.ProductCode='TestProduct0006';
          objProduct.Source_System__c='SAP';
          insert objProduct;
  
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Product__c=objProduct.Id;
          insert objInstalledProduct;
  
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase.Product_Serial_Number__c='Test11';
          
          insert objCase;
              
          List<Impacted_Products_Serials_Lots__c> lstimpprod=new List<Impacted_Products_Serials_Lots__c>();
          lstimpprod.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN.Id,Serial_Number__c='Test11'));
          lstimpprod.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN.Id,Lot_Number__c='Test12'));
          lstimpprod.add(new Impacted_Products_Serials_Lots__c(Field_Action_Notification__c=FAN.Id,Product__c=objProduct.Id));
          insert lstimpprod;
  
          Recommendation recom = new Recommendation();
          recom.name = 'This Case has a Product that may be related to a FAN';
          recom.description = 'This Case has a Product that may be related to a FAN';
          recom.acceptancelabel ='Accept';
          recom.rejectionlabel = 'Reject';
          List<Recommendation> lstRecomm = new List<Recommendation>();
          lstRecomm.add(recom);
          objCase.SVMXC__Product__c = objProduct.Id;
          Update objCase ;
          List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
          CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
          inputRequest.recordId=objCase.Id;
          inputRequest.recommendations = lstRecomm;
          inputRequests.add(inputRequest);
          CaseRecommendationController.generateRecommendation(inputRequests);
          List<FANRecordListController.DataWrapper> lstdatawrapper = new List<FANRecordListController.DataWrapper>();
          try {
          Test.StartTest();            
              lstdatawrapper=FANRecordListController.getwrapperList(objCase.Id);
              system.assertNotEquals(null,lstdatawrapper);
          Test.StopTest();
          }
          catch(Exception e) {
              system.assertEquals(null,lstdatawrapper,' lstdatawrapper is null');
          }
    }
    /**  
      *  @AUTHOR - Gladis
      *  @RETURN - List<Recommendation>
      *  @Description  DCP-54039 test method for recommendation With Name 
                    : "This Installed Product does not have an Active Service Contract Associated with"
                    and "This Case has not been updated in two days"

      */
      static testMethod void filterRecommendationForIPWithNoActiveContracts() {

        Id myId = UserInfo.getUserId();
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = myId;
        insert csapex;

        Account acc1 = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc1.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
        insert acc1;
    
        Product2 objProduct1 = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct1.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct1.ProductCode='TestProduct0006';
        insert objProduct1;
  
        SVMXC__Installed_Product__c objInstalledProduct1 = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct1.SVMXC__Product__c=objProduct1.Id;
        insert objInstalledProduct1;

        Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase1.SVMXC__Component__c = objInstalledProduct1.Id; 
        objCase1.Product_Serial_Number__c='Test11';
        insert objCase1;
       
        List<Recommendation> lstRec = new List<Recommendation>();                                     
        Recommendation recom2 = new Recommendation();
        recom2.name = 'This Installed Product does not have an Active Service Contract Associated with';
        recom2.description = 'This Installed Product does not have an Active Service Contract Associated with it. If service is required, please follow the Billable Workflow for your region';
        recom2.acceptancelabel ='Accept';
        recom2.rejectionlabel = 'Reject';
        lstRec.add(recom2);

        Recommendation recom1 = new Recommendation();
        recom1.name = 'This Case has not been updated in two days';
        recom1.description = 'This Case has not been updated in two days';
        recom1.acceptancelabel ='Accept';
        recom1.rejectionlabel = 'Reject';
        lstRec.add(recom1);

        Test.startTest();
        List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
        CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
        inputRequest.recordId=objCase1.Id;
        inputRequest.recommendations = lstRec;
        inputRequests.add(inputRequest);
        List<List<Recommendation>> listOfrecomm = CaseRecommendationController.generateRecommendation(inputRequests);
        System.assertNotEquals(null, listOfrecomm,' listOfrecomm returned not null');
        Test.StopTest();
    }

    /**  
      *  @AUTHOR - Rohan Rathod
      *  Testing 
      *  Used to check Loop in field service team logic
      */
      public static testMethod void testLoopTeam() {
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.Product_Serial_Number__c='Test11';
        insert objCase;
        
        Recommendation recom = new Recommendation();
        recom.name = 'This Case has been opened for longer than seven days.';
        recom.description = 'This Case has been opened for longer than seven days.';
        recom.acceptancelabel ='Accept';
        recom.rejectionlabel = 'Reject';
        List<Recommendation> lstRecomm = new List<Recommendation>();
        lstRecomm.add(recom);
        Update objCase ;
        Test.startTest();
        List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
        CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
        inputRequest.recordId=objCase.Id;
        inputRequest.recommendations = lstRecomm;
        inputRequests.add(inputRequest);
        List<List<Recommendation>> listOfrecomm = CaseRecommendationController.generateRecommendation(inputRequests);
        System.assertNotEquals(null, listOfrecomm,' list Of recomm returned not null');
        Test.StopTest();
    }

    /**
    * @description To test Review comments recommendation
    * @author Rohan | 07-01-2022 
    * @return testMethod 
    **/
    public static testMethod void testReviewComments() {
        Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
        acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
        acc.Field_Comments__c = 'TS do not process replacements';
        insert acc;

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.Product_Serial_Number__c='Test11';
        objCase.AccountId = acc.ID;
        insert objCase;
        
        Recommendation recom = new Recommendation();
        recom.name = 'This Account has a specialized Replacement Process per the Field Comments';
        recom.description = 'This Account has a specialized Replacement Process per the Field Comments';
        recom.acceptancelabel ='Accept';
        recom.rejectionlabel = 'Reject';
        List<Recommendation> lstRecomm = new List<Recommendation>();
        lstRecomm.add(recom);
        Update objCase ;
        Test.startTest();
        List<CaseRecommendationController.CaseRecommendationRequest> inputRequests = new  List<CaseRecommendationController.CaseRecommendationRequest>();
        CaseRecommendationController.CaseRecommendationRequest inputRequest = new CaseRecommendationController.CaseRecommendationRequest();
        inputRequest.recordId=objCase.Id;
        inputRequest.recommendations = lstRecomm;
        inputRequests.add(inputRequest);
        List<List<Recommendation>> listOfrecomm = CaseRecommendationController.generateRecommendation(inputRequests);
        System.assertNotEquals(null, listOfrecomm,' list Of recomm returned not null');
        Test.StopTest();
    }
}

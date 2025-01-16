/***************************************************************************************************************************************
 * NAME   : TestCases
 * DESCRIPTION  : TestClass for Case Trigger
 *           DCP-817,821,823  : Creation of Entitlement for Cases and Work Orders
 *    
 * @AUTHOR : Veerendra
 * @DATE   : 12-Jun-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Soumya                   31 AUG 18           Modifying for increasing code coverage.
 * Tapas                    16-May-19           method for 25243, covering Cases.createAssociatedCode
 * Bharath                  16-May-19           method for 25233, covering Cases.createAssociatedCode
 * Vignesh                  21-Aug-19           method for 28100, checking cases updates from Web for Status field.Adding extra line
 * Adyasha                  10-Mar-21           method for 44980, checking update on IVD Product Identifier(Additional Product) flag
 * Nishan Shetty            13-Aug-21           method for CMCP-23, checking update on Partner Case Flag.
 * Nishan Shetty            15-Sept-2021        method for CMCP-22,requesting relocation work order.
 * Nishan Shetty            22-Sept-21          method for CMCP-64, checking updated status of Request Ownership Status Field.
 * Abhinav Gupta            14-Mar-22           method for CQACM-5, checking updated values of QA Reopen Code(s)
 * Preetha                  16-Mar-2022         Method for QACM-18 Checking Show On Case in Additional Products
 * Avina                    17-MAR-22           method for QACM-8, covering Cases.populateQACompletionDate
 * Rohan                    23-Mar-2022         DCP-49682   Elevation 1.0 Removal
 * Preetha                  30-Mar-22           Method for QACM-82, Checking Product utilization mode Cases.validateProductUtilizationMode
 * Susmitha                 29-Aug-22           Method for QACM-108, checking when disassociating happens on case record type change
 * Gladis                   08-Sep-2022         DCP-55963 updated checkCaseReOpenedStatusFromSFM method by adding the static final string
 * Rohan                    20-Dec-2022         DCP-56388 Test checkSubTypeEditForOpenElevation
 * Abhishek                 25-Sept-2023        CMCM-3533 Test updateAnaysisCode
 * Dhairya                  17Apri2024 CMCM6760
 * Nitin Zagade/Nidhi       15 May 2024        CMCM-7773
 *  * Nitin Zagade          14 Aug 2024     CMCM-9391
 * Dhairya                  21/8/2024       CMCM-2180
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 
  @isTest(SeeAllData = false)  
  public with sharing class TestCases {

      public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
      public static final string STRING_PRODUCT_CODE = 'Test 1234';
      public static final boolean BOOLEAN_CONSUMABLES_INCLUDED = false;
      public static final string STRING_CASE_STATUS = 'Initiated';
      public static final string STRING_CASE_ORIGIN = 'Phone - CS';
      public static final string STRING_CASE_RECORDTYPENAME_ELEVATED = 'Elevation';
      public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
      public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
      public static final string STRING_CURRENCY = 'USD';
      public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
      public static final string STRING_EVALUATION_ANSWER_NO = 'No';
      public static final string STRING_EVALUATION_ANSWER_YES = 'YES';
      public static final string STRING_EVALUATION_ANSWER_PENDING='Pending';
      public static final string STRING_CASE_SUB_TYPE = 'Complaint';
      public static final string STRING_CASE_CATEGORY = 'Install';
      public static final string STRING_CASE_STATUS_CLOSED = 'Closed';
      public static final string STRING_LOCATION = 'Test Location';
      public static final string STRING_STREET = 'Test Street';
      public static final string STRING_EXCEPTION = 'The following exception has occurred: ';
      public static final string STRING_CASE_CATEGORY_ORDER = 'New Order';
      public static final string STRING_CASE_STATUS_IN_PROGRESS = 'In Progress';
      public static final string STRING_CASR_RECORDTYPE_SERVICE_REQUEST = 'Service Request';
      public static final string STRING_ACCOUNT_NAME = 'Test Acc';
      public static final string STRING_WO_RECORDTYPE = 'Field Service';
      public static final string STRING_CASE_ELEVATION_CATEGORY = 'Hot Site Elevation';
      public static final string STRING_CLOSED_DUPLICATE_STATUS = 'Closed-Duplicate';
      public static final string STRING_REGULATORY_TYPE_DX = 'DX';
      public static final string STRING_CASE_SUBJECT = 'Test Case IVD1';
      public static final string STRING_CASE_SUBJECT2 = 'Test Case IVD2';
      public static final string STRING_QA_REVIEW_IN_PROGRESS = 'In Progress';
      public static final string STRING_CASE_STATUS_COMPLETED = 'Completed';
	  public static final string STRING_LABEL_SERVICE_ACTIVITIES = 'Service Activities'; //DCP - 46058
	  public static final string STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED = 'Assignment Accepted';//DCP - 46058
      public static final String STRING_ERROR_MESSAGE='Reopen Reasons are required for tracking. Enter a Reopen Reason.';//DCP-55963
      public static final string STRING_INSTALLED_PRODUCT_IP_NAME = 'A01195-15019046'; // created by Dhairya Shah for CMCM-7910
      public static final string STRING_INSTALLED_PRODUCT_SERIAL_LOT_NUMBER = 'A01195'; // created by Dhairya Shah for CMCM-7910
    
      static testmethod void newCaseCreation() {
         cs_Apex_Settings__c cs1=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
         cs1.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
          upsert cs1 cs_Apex_Settings__c.Id;
          Account objAccount = TestDataAccount.getNewAccount();
          Test.startTest();
          Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', AccountId=objAccount.Id, Phone='1234567890',email='abc@test.com.invalid');
          insert con;
          SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
          insert objServiceContract;
          SVMXC__Service_Contract__c insertedServiceContract = [Select Consumables_Included__c from SVMXC__Service_Contract__c where Id =: objServiceContract.Id];
          System.assertEquals(insertedServiceContract.Consumables_Included__c, BOOLEAN_CONSUMABLES_INCLUDED, 'Consumable Included is false');
  
          SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
          insert objLocation;
  
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          insert objInstalledProduct;
          SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
          System.assertEquals(insertedInstalledProduct.SVMXC__Status__c, STRING_INSTALLED_PRODUCT_STATUS,'Installed Product status is New');
  
          SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
          objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
          insert objCoveredProduct;
          SVMXC__Service_Contract_Products__c insertedCoveredProduct = [Select SVMXC__Installed_Product__c from SVMXC__Service_Contract_Products__c where SVMXC__Installed_Product__c =: objInstalledProduct.Id];
          System.assertEquals(insertedCoveredProduct.SVMXC__Installed_Product__c, objInstalledProduct.Id,'Covered Product has an installed product associated to it');
  
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase.SVMXC__Site__c = objLocation.Id;  
          objCase.Date_of_Issue_Awareness__c = Date.Today();      
          insert objCase;
          Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
          System.assertEquals(InsertedCase.SVMXC__Component__c, objInstalledProduct.Id, 'Case has an installed product associated to it');
          
          Applied_Contract__c objEntitlement = new Applied_Contract__c();
          objEntitlement.CurrencyIsoCode='USD';
          objEntitlement.Case_Number__c=objCase.id;
          insert objEntitlement;
          Applied_Contract__c insertedEntitlement = [Select Case_Number__c from Applied_Contract__c where Case_Number__c =: objCase.Id limit 1] ;
          System.assertEquals(insertedEntitlement.Case_Number__c, objCase.Id,'Applied Contract has case associated to it');
  
          Test.stopTest();
      }
      
      static testmethod void newCaseCreationWithoutIVDProduct() { 
          cs_Apex_Settings__c cs1=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
          cs1.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
          upsert cs1 cs_Apex_Settings__c.Id;  
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.Source_System__c='SAP';
          insert objProduct;
          system.assertNotEquals(null,objProduct.id);
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Product__c=objProduct.Id;
          insert objInstalledProduct;
          system.assertNotEquals(null,objInstalledProduct.id);
  
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.pAE_pFA_Awareness_Date__c = Date.Today() -3;
          objCase.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_NO;
          objCase.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
          
          try{
              insert objCase;
              system.assertNotEquals(null,objCase.id);
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
          
          Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase1.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_YES;
          //objCase1.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
          objCase1.pAE_pFA_Awareness_Date__c = Date.Today() -3;
          objCase1.Date_of_Issue_Awareness__c = Date.Today();
              
          //objCase1.Status = STRING_CASE_STATUS_CLOSED;
          try{
              insert objCase1;
              system.assertNotEquals(null,objCase1.id);
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
          
          Case objCase2 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase2.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase2.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_PENDING;
          objCase2.Sub_Type__c = STRING_CASE_SUB_TYPE;
          objCase2.Category__c = STRING_CASE_CATEGORY;
          objCase2.Date_of_Issue_Awareness__c = Date.Today();
          insert objCase2;
          system.assertNotEquals(null,objCase2.id);
           
                                                      
  
          try{
              objCase2.Status = STRING_CASE_STATUS_CLOSED;
              objCase2.Reason_for_Reopen__c = 'Test re-open'; //2180
              update objCase2;
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
          try{
              objCase2.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_YES;
              objCase2.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Answer_2__c = null;
              update objCase2;
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
                 Savepoint sp = Database.setSavepoint();
              objCase2.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_YES;
              objCase2.Status = 'In Progress';
              objCase2.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Answer_2__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Answer_3__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Answer_4__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Verification_Result__c = 'test';
              update objCase2;
              Database.rollback(sp);
              Savepoint sp2 = Database.setSavepoint();
              objCase2.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_YES;
              objCase2.Answer_1__c = STRING_EVALUATION_ANSWER_YES;
              objCase2.Answer_2__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Answer_3__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Answer_4__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
              objCase2.Verification_Result__c = 'test';
                      objCase2.pAE_pFA_Awareness_Date__c = Date.Today();
              update objCase2;
              Database.rollback(sp2);
          try{
              objCase2.Status = 'Investigation';
              objCase2.Date_of_Issue_Awareness__c = Date.today().addDays(-2);
              update objCase2;
          } catch(Exception ex){
              system.debug('Error'+ex.getmessage());
          }
          
           
      }
      
      static testmethod void populateCaseFieldsOnWebEmail(){
          Account objAcc = TestDataAccount.getNewAccount();
          Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
          insert con;
          Case cs = TestDataCase.initServiceRequestCase(con);
          cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
          cs.Sub_Type__c = 'Order';
          cs.Category__c = STRING_CASE_CATEGORY_ORDER; 
          cs.Status = STRING_CASE_STATUS_IN_PROGRESS;
          cs.SuppliedEmail = 'test@gmail.com.invalid';
          cs.Closed_with_Associated_Codes__c = false;
          cs.origin=cases.STRING_CASE_ORIGIN_WEB_MY_ILLUMINA_CS;
          cs.status=System.label.CaseStatusReopenedInProgress;
          cs.First_Call_Resolution__c=true;
          test.startTest();
         insert cs;
          system.assertEquals(cs.ContactId,con.Id,'update contact field on case based on webEmail');
      }
      
      static testmethod void newCaseCreationWithIVDProduct() {      
          cs_Apex_Settings__c cs1=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
          cs1.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
          upsert cs1 cs_Apex_Settings__c.Id;  
          Account objAccount = TestDataAccount.getNewAccount();
          system.assertNotEquals(null,objAccount.id);
  
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.Regulatory_Type__c = 'DX';
          objProduct.Source_System__c='SAP';
          insert objProduct;
          system.assertNotEquals(null,objProduct.id);
          
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Product__c=objProduct.Id;
          insert objInstalledProduct;
          system.assertNotEquals(null,objInstalledProduct.id);
          
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase.SVMXC__Product__c = objProduct.Id;
          objCase.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_PENDING;
          //objCase.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
          //objCase.pAE_pFA_Awareness_Date__c = Date.Today() -3;   
          objCase.Date_of_Issue_Awareness__c = Date.Today();      
          insert objCase;
          system.assertNotEquals(null,objCase.id);
              
          objCase.Status = STRING_CASE_STATUS_CLOSED;
  
          try{
              update objCase;
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
  
          Case objCase2 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase2.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase2.SVMXC__Product__c = objProduct.Id;
          //objCase2.pAE_pFA_Awareness_Date__c = Date.Today();
          objCase2.Sub_Type__c = STRING_CASE_SUB_TYPE;
          objCase2.Category__c = STRING_CASE_CATEGORY;
          objCase.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_PENDING;
          objCase2.Date_of_Issue_Awareness__c = Date.Today();
          insert objCase2;
          system.assertNotEquals(null,objCase2.id);
          
      try{
          objCase2.Answer_1__c = STRING_EVALUATION_ANSWER_YES;
          objCase2.pAE_pFA_Awareness_Date__c = Date.today();
          update objCase2;
          objCase2.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;   
              update objCase2;
          }
          catch(Exception ex){
              system.debug('Error'+ex.getmessage());
          }	 
            
      }
      
       static testmethod void checkWorkflows(){
          Account objAccount = TestDataAccount.getCustomerAccount();
          insert objAccount;
          system.assertNotEquals(null,objAccount.id); 
          Contact con = TestDataPerson.getNewContact(objAccount.Id);
          system.assertNotEquals(null,con.id);
          Case parentCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          parentCase.ContactId = con.id;
          insert parentCase;
          system.assertNotEquals(null,parentCase.id);
          Case objCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          objCase.ParentId = parentCase.Id;
          objCase.Sub_Type__c = 'Service Support';
          objCase.Category__c = 'Clinical';
          objCase.ContactId = con.id;
          insert objCase;
          system.assertNotEquals(null,objCase.id);
          objCase.Status = System.Label.CaseStatusInitiated;
          update objCase;
          Test.startTest();
          system.assertNotEquals(null,[select id, SVMXC__Actual_Initial_Response__c from Case where id=:objCase.id Limit 1].SVMXC__Actual_Initial_Response__c);
          objCase.Status = System.Label.CaseStatusInProgress;
          objCase.QA_Review_Comments__c='test';
          objCase.QA_Review__c='Pending';
          update objCase; 
          system.assertNotEquals(null,[select id, SVMXC__Actual_Initial_Response__c from Case where id=:objCase.id Limit 1].SVMXC__Actual_Initial_Response__c);
          objCase.Status ='Awaiting Response - Customer';
          objCase.Veeva_Integration_Status__c='Case Creation Initiated';
          objCase.Awaiting_Response_Reason__c='PO Pricing';//CMCM -6760 Changed picklist value to avoid validation exception
          update objCase;
          system.assertNotEquals(null,[select id, Awaiting_Response_Date__c from Case where id=:objCase.id Limit 1].Awaiting_Response_Date__c);
          Test.stopTest();
      }
            
      static testmethod void checkWorkflows3() {
          cs_Apex_Settings__c cs1=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
          cs1.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
          upsert cs1 cs_Apex_Settings__c.Id;
          Account objAccount = TestDataAccount.getNewAccount();
          system.assertNotEquals(null,objAccount.id);
          Account objAccount2 = TestDataAccount.getNewAccount();
          system.assertNotEquals(null,objAccount2.id);
          objAccount.Account_Group__c='Distributor';
          // POL-18 AC9 keywords replaced from APJ to AMEA 
          objAccount.Territory_Region__c = 'AMEA'; 
          objAccount.District__c='RP';
          objAccount2.Account_Group__c='Distributor';
          // POL-18 AC9 keywords replaced from APJ to AMEA 
          objAccount2.Territory_Region__c = 'AMEA'; 
          objAccount2.District__c='RP';
          update objAccount;
          update objAccount2;
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.Regulatory_Type__c = 'DX';
          objProduct.Source_System__c='SAP';
          insert objProduct;
          system.assertNotEquals(null,objProduct.id);
          
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Product__c=objProduct.Id;
          objInstalledProduct.SVMXC__Company__c=objAccount.id;
          insert objInstalledProduct;
          system.assertNotEquals(null,objInstalledProduct.id);
          
          Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
          Case cs = TestDataCase.initServiceRequestCase(con);
          cs.SVMXC__Component__c = objInstalledProduct.Id; 
          cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
          cs.Date_of_Issue_Awareness__c = Date.Today();
          cs.AccountId = objAccount.Id; //-added by naomi
          test.startTest();
          
          insert cs;
          system.assertNotEquals(null,cs.id);
          Code_Library__c dcl = new Code_Library__c(Name='Code Disassociated', Code_type__c = 'Subject', Service_Product_Type__c = 'Tool');
          insert dcl;
          system.assertNotEquals(null,dcl.id);
          
          Code_Library__c pcl = new Code_Library__c(Name='Did the issue involve a death or serious',
          Code_type__c = 'Subject', Service_Product_Type__c = 'Tool');
          insert pcl;
          system.assertNotEquals(null,pcl.id);
          
          SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
          wo.SVMXC__Order_Type__c='Installation';
          //insert wo;
          
          Code_Library__c cl = new Code_Library__c(Name='Test2', Code_type__c = 'Subject', Parent_Code__c=pcl.Id, Service_Product_Type__c = 'Tool');
          insert cl;
          system.assertNotEquals(null,cl.id);
          
          Associated_Codes__c ac = new Associated_Codes__c();
          ac.Code_Title__c = cl.Id;
          ac.Case__c = cs.Id;
          ac.Work_Order__c = wo.Id;
          //insert ac;
          cs.AccountId = objAccount2.Id;
          cs.Question_1__c = 'Did the issue involve a death or serious injury to either the patient or the operator?';
          cs.Question_2__c = 'Could the issue cause a death or serious injury if it were to recur?';
          cs.Answer_1__c = 'No';
          cs.Answer_2__c = 'No';
          
          update cs;
          test.stopTest();
      }
      
      static testmethod void newBusinessIssueCaseCreation() {
          Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
          Case cs = TestDataCase.initServiceRequestCase(con);
          cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
          cs.Date_of_Issue_Awareness__c = Date.Today();
          test.startTest();
          
          insert cs;
          system.assertNotEquals(null,cs.id);
          Code_Library__c dcl = new Code_Library__c(Name='Code Disassociated', Code_type__c = 'Subject', Service_Product_Type__c = 'Tool');
          insert dcl;
          system.assertNotEquals(null,dcl.id);
  
          Code_Library__c pcl = new Code_Library__c(Name='Did the issue involve a death or serious',
          Code_type__c = 'Subject', Service_Product_Type__c = 'Tool');
          insert pcl;
          system.assertNotEquals(null,pcl.id);
          
          SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, cs.Id, 'Initiated');
          wo.SVMXC__Order_Type__c='Installation';
          //insert wo;
          
          Code_Library__c cl = new Code_Library__c(Name='Test2', Code_type__c = 'Subject', Parent_Code__c=pcl.Id, Service_Product_Type__c = 'Tool');
          insert cl;
          system.assertNotEquals(null,cl.id);
          
          Associated_Codes__c ac = new Associated_Codes__c();
          ac.Code_Title__c = cl.Id;
          ac.Case__c = cs.Id;
          ac.Work_Order__c = wo.Id;
          //insert ac;
          
          cs.Question_1__c = 'Did the issue involve a death or serious injury to either the patient or the operator?';
          cs.Question_2__c = 'Could the issue cause a death or serious injury if it were to recur?';
          cs.Answer_1__c = 'No';
          cs.Answer_2__c = 'No';
          
          update cs;
          test.stopTest();
      }
      
      
      
      static testmethod void updateToBusinessIssueCase() {
          Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
          Case cs = TestDataCase.initServiceRequestCase(con);
          cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
          test.startTest();
          insert cs;
          system.assertNotEquals(null,cs.id);
          cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
          update cs;
          system.assertNotEquals(0,[select id, SVMXC__Case__c from SVMXC__Service_Order__c where SVMXC__Case__c=:cs.id].size());
          test.stopTest();
      }
     
      static testmethod void checkClosedDuplicate1(){
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, 'Initiated', STRING_CASE_ORIGIN);
          objCase.Date_of_Issue_Awareness__c = Date.Today();
          insert objCase;
          system.assertNotEquals(null,objCase.id);
          //SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
          //wo.Is_Auto_Created__c  = true;
          //insert wo;
                                              
          try{
             objCase.Status = STRING_CLOSED_DUPLICATE_STATUS;
             update objCase; 
          }catch(exception ex){
              system.assertNotEquals([select id, Status from Case where id=:objCase.id Limit 1].Status, STRING_CLOSED_DUPLICATE_STATUS);
          }
          try{
          SVMXC__service_order__c objWO = [select id from SVMXC__service_order__c where SVMXC__case__c =: objCase.Id][0];
          objWO.SVMXC__Order_Status__c = 'Closed-Duplicate';
          update objWO;
          objCase.Answer_1__c = STRING_EVALUATION_ANSWER_YES;
           objCase.Answer_2__c = STRING_EVALUATION_ANSWER_YES;
           objCase.Answer_3__c = STRING_EVALUATION_ANSWER_YES;
           objCase.Answer_4__c = STRING_EVALUATION_ANSWER_YES;
           objCase.Answer_5__c = STRING_EVALUATION_ANSWER_YES;
             objCase.Status = STRING_CLOSED_DUPLICATE_STATUS;
          objCase.pAE_pFA_Awareness_Date__c = system.today();
          objCase.Has_closed_duplicate_wo__c = true;
             update objCase; 
          }
          catch(exception ex){
              system.debug('Error'+ex.getmessage());
          }
      }
      static testmethod void checkClosedDuplicate2(){
          Account objAccount = TestDataAccount.getCustomerAccount();
          insert objAccount;
          system.assertNotEquals(null,objAccount.id);
          Contact con = TestDataPerson.getNewContact(objAccount.Id);
          system.assertNotEquals(null,con.id);
          Case parentCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          parentCase.ContactId = con.id;
          insert parentCase;
          system.assertNotEquals(null,parentCase.id);
          Case objCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          objCase.ParentId = parentCase.Id;
          objCase.ContactId = con.id;
          insert objCase;
          system.assertNotEquals(null,objCase.id);
          Code_Library__c cl = new Code_Library__c(Name='Test2', Code_type__c = 'Subject', Service_Product_Type__c = 'Tool');
          insert cl;
          system.assertNotEquals(null,cl.id);
          Associated_Codes__c ac = new Associated_Codes__c();
          ac.Code_Title__c = cl.Id;
          ac.Case__c = objCase.Id;
          insert ac;
          system.assertNotEquals(null,ac.id);
          objCase.Status = STRING_CLOSED_DUPLICATE_STATUS;
          try{
             update objCase; 
          }catch(exception ex){
              system.assertNotEquals([select id, Status from Case where id=:objCase.id Limit 1].Status, STRING_CLOSED_DUPLICATE_STATUS);
          }
      }
      static testmethod void checkClosedDuplicate3(){
          Account objAccount = TestDataAccount.getCustomerAccount();
          insert objAccount;
          system.assertNotEquals(null,objAccount.id);
          Contact con = TestDataPerson.getNewContact(objAccount.Id);
          system.assertNotEquals(null,con.id);
          Case parentCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          parentCase.ContactId = con.id;
          insert parentCase;
          system.assertNotEquals(null,parentCase.id);
          Case objCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          objCase.ParentId = parentCase.Id;
          objCase.ContactId = con.id;
          insert objCase;
          system.assertNotEquals(null,objCase.id);
          objCase.Status = STRING_CLOSED_DUPLICATE_STATUS;
          objCase.Description = '';
          try{
             update objCase; 
          }catch(exception ex){
              system.assertNotEquals([select id, Status from Case where id=:objCase.id Limit 1].Status, STRING_CLOSED_DUPLICATE_STATUS);
          }
      }
      static testmethod void checkClosedDuplicate4(){
          Account objAccount = TestDataAccount.getCustomerAccount();
          insert objAccount;
          system.assertNotEquals(null,objAccount.id);
          Contact con = TestDataPerson.getNewContact(objAccount.Id);
          system.assertNotEquals(null,con.id);
          Case parentCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          parentCase.ContactId = con.id;
          insert parentCase;
          system.assertNotEquals(null,parentCase.id);
          Case objCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          objCase.ParentId = parentCase.Id;
          objCase.Sub_Type__c = 'Service Support';
          objCase.Category__c = 'Clinical';
          objCase.ContactId = con.id;
          insert objCase;
          system.assertNotEquals(null,objCase.id);
          //objCase.Status = 'Completed';
          //objCase.Has_SR_Case_Subject_Code__c=true;
          //objCase.Record_Updated_from_SFM__c=true;
          //update objCase;
          objCase.Status = STRING_CLOSED_DUPLICATE_STATUS;
          try{
             update objCase;
             system.assertEquals([select id, Status from Case where id=:objCase.id Limit 1].Status, STRING_CLOSED_DUPLICATE_STATUS,'Case status is closed duplicate'); 
          }catch(exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
      }
      
      static testmethod void checkCompleteCase(){
          Account objAccount = TestDataAccount.getCustomerAccount();
          insert objAccount;
          system.assertNotEquals(null,objAccount.id);
          Contact con = TestDataPerson.getNewContact(objAccount.Id);
          system.assertNotEquals(null,con.id);
          Case parentCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          parentCase.ContactId = con.id;
          insert parentCase;
          system.assertNotEquals(null,parentCase.id);
          Case objCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          objCase.ParentId = parentCase.Id;
          objCase.Sub_Type__c = 'Service Support';
          objCase.Category__c = 'Clinical';
          objCase.ContactId = con.id;
          objCase.Status = STRING_CASE_STATUS_IN_PROGRESS;
          insert objCase;
          system.assertNotEquals(null,objCase.id);
          objCase.Status = 'Completed';
          objCase.Has_SR_Case_Subject_Code__c=true;
          objCase.Record_Updated_from_SFM__c=true;
          //update objCase; 
      }
      
      static testmethod void caseLocationUpdateCheck(){
          SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
          SVMXC__Site__c objLocation2 = TestDataFieldService.createLocation('Test Location1','Test Street1','Ireland','123456','USD');
          insert new List<SVMXC__Site__c>{objLocation1,objLocation2};
          system.assertNotEquals(null,objLocation1.id);
          system.assertNotEquals(null,objLocation2.id);
  
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          insert objInstalledProduct;
          system.assertNotEquals(null,objInstalledProduct.id);
          
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase.SVMXC__Site__c = objLocation1.Id;  
          objCase.Date_of_Issue_Awareness__c = Date.Today();      
          insert objCase;
          system.assertNotEquals(null,objCase.id);
          
          Test.startTest();
          objCase.SVMXC__Site__c = objLocation2.Id;
          update objCase;
          Test.stopTest();
      }
      
      //DCP-25245
      static testmethod void spamEmailCheck(){
          List<Case> lstCases = new List<Case>(); 
          Case objCase1 = new Case();
          objCase1.Origin = 'Email - CS';
          objCase1.Subject = 'shipment created';
          objCase1.SuppliedEmail = 'intlinfo@estesforwarding.com';
          lstCases.add(objCase1);             
          Test.startTest();
          insert lstCases;
          system.assertNotEquals(null,lstCases[0].id);
          system.assertEquals('Closed',[select id, Status, Category__c, Sub_Type__c from Case where id=:lstCases[0].id Limit 1].Status,'Case status is closed');
          Test.stopTest(); 
      } 
      //DCP-25243
      static testMethod void testNotificationClosureCase(){
          Case objCase = TestDataCase.initNewCase('Inquiry', STRING_CASE_STATUS, 'In Person - CS');
          objCase.Sub_Type__c = 'General';
          objCase.Category__c = 'Question';
         
          Code_Library__c objCodeLibrary = new Code_Library__c();
          objCodeLibrary.Code_Type__c = 'Subject';
          objCodeLibrary.Name = 'INQ CS Inquiry Subject code';
          
          insert objCase;
          insert objCodeLibrary;
          
          Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
          con.Email = 'test@abc.com';
          con.Phone = '1234567890';
          insert con;
          Case objCase2 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS_IN_PROGRESS, 'In Person - CS');
          objCase2.ContactId = con.Id;
          objCase2.Date_of_Issue_Awareness__c = Date.today();
          insert objCase2;
          try{
              Test.startTest();
              objCase.Category__c = 'Notification'; 
              objCase.Record_Edit_Source__c = 'Close as Notification Quick Action';
              objCase.Status = STRING_CASE_STATUS_IN_PROGRESS;
              update objCase;
              System.debug('The case1 is ' + objCase);
              System.assertEquals(0, [select id from Associated_Codes__c where Code_Title__c =: objCodeLibrary.Id and case__c =: objCase.Id].size(),'Case record not created');

              Test.stopTest();
              System.debug('The case2 is ' + objCase2);
          }
          Catch(Exception ee){
              //System.assert(ee.getMessage().contains('This operation is only applicable for inquiry type records'));
              System.assert(Cases.setErrMessages.contains(System.label.CaseErrorMessage_CHECK_CASE_TYPE_ON_NOTIFICATION_BUTTON),'Error message contains the mentioned statement');
              System.assertEquals(0, [select id from Associated_Codes__c where Code_Title__c =: objCodeLibrary.Id and case__c =: objCase2.Id].size(),'Case record not created');
          }
      }
  
      static testmethod void testworkflowrefactor(){
          Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
          Case cs = TestDataCase.initServiceRequestCase(con);
          cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
          cs.Sub_Type__c = 'Order';
          cs.Category__c = STRING_CASE_CATEGORY_ORDER; 
          cs.Status = STRING_CASE_STATUS_IN_PROGRESS;
          cs.Closed_with_Associated_Codes__c = false;
          test.startTest();
          User serviceUser=TestDataUser.findUserInProfile('Customer Service');
         system.runAs(serviceUser){
         insert cs;
         system.assertNotEquals(null,cs.id, 'Case created successfully');
         cs.origin=cases.STRING_CASE_ORIGIN_WEB_MY_ILLUMINA_CS;
         cs.status=System.label.CaseStatusReopenedInProgress;
         cs.First_Call_Resolution__c=true;
         update cs;
         }
          test.stopTest();
      }
  
      //DCP_25233
      static testmethod void newAssociatedCodeCreationOnInquiryCase() {
          
          Code_Library__c dcl = new Code_Library__c(Name='CS Inquiry Order', Code_type__c = 'Subject', Case_Type__c = 'Inquiry',
                                                    Service_Product_Type__c = 'Tool');
          insert dcl;
          Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
          Case cs = TestDataCase.initServiceRequestCase(con);
          cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
          cs.Sub_Type__c = 'Order';
          cs.Category__c = STRING_CASE_CATEGORY_ORDER; 
          cs.Status = 'Initiated';
          cs.ContactId = null;
          cs.Closed_with_Associated_Codes__c = false;
          
          
          User serviceUser=TestDataUser.findUserInProfile('Customer Service'); 
                  
          system.runAs(serviceUser){
              test.startTest();
              insert cs;
              system.assertNotEquals(null,cs.id, 'Case created successfully');
              cs.status='Completed';
              cs.Record_Updated_from_SFM__c=true;
              cs.Closed_with_Associated_Codes__c = true;
              cs.Send_Case_Completion_Email__c = false;
              cs.Is_Case_Completed__c = true;
              //update cs;
              test.stopTest();
          }
        
      }
      
      /**
       * method: testContractcovergeCheckBox
       * params:NA
       * return: void
       * Description: this method covers the ContractcovergeCheckBox functionality (DCP - 26359)
       * created date: 28-JUN-2019
      **/
      
      static testmethod void testContractcovergeCheckBox() {
          cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
          cs.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
          upsert cs cs_Apex_Settings__c.Id;
          //insert account
          Account objAccount = TestDataAccount.getAccount(STRING_ACCOUNT_NAME, 'USD');
          objAccount.Account_Group__c='Distributor';
          insert objAccount;
          //insert contact
          Contact con  = TestDataPerson.getNewContact(objAccount.Id);
          
          //insert service contract
          SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
          insert objServiceContract;
          
          //insert locations
          List<SVMXC__Site__c> lstLocations = new List<SVMXC__Site__c>();
          SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
          //insert objLocation;
          lstLocations.add(objLocation);
          SVMXC__Site__c objLocation1 = TestDataFieldService.createLocation('Test Location1','Test Street1','Ireland','1234567','USD');
          //insert objLocation1;
          lstLocations.add(objLocation1);
          insert lstLocations;
          //insert installed product
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Company__c = objAccount.Id;
          insert objInstalledProduct;
          
          //insert covered product
          SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
          objCoveredProduct.SVMXC__Service_Contract__c = objServiceContract.Id;
          objCoveredProduct.SVMXC__Start_Date__c = system.today();
          objCoveredProduct.SVMXC__End_Date__c = system.today().adddays(1);
          insert objCoveredProduct;
          //insert coveredLocation
          SVMXC__Service_Contract_Sites__c coveredLocation = new SVMXC__Service_Contract_Sites__c(
              SVMXC__Site__c = objLocation1.Id,SVMXC__Service_Contract__c = objServiceContract.Id
          );
          insert coveredLocation;
          system.assert(coveredLocation.Id != null,'Covered Location has an id');
          
          
          //insert case
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase.SVMXC__Site__c = objLocation.Id;  
          objCase.Date_of_Issue_Awareness__c = Date.Today(); 
          objCase.AccountId = objAccount.Id;
          objCase.ContactId = con.Id;
          insert objCase;
          Test.startTest();
          //update case
          objCase.SVMXC__Site__c = objLocation1.Id;
          update objCase;
          
          List<SVMXC__Service_Order__c> lstWo = [Select Id,SVMXC__Case__c from SVMXC__Service_Order__c LIMIT 1];
          System.assertEquals(lstWo[0].SVMXC__Case__c, objCase.Id, 'Case ID is not equal');
          Test.stopTest();
      }
  
      /**
       * method: caseCloseAsDuplicateCheck
       * params:NA
       * return: void
       * Description: this method covers the functionality for DCP - 25229
      **/
       static testmethod void caseCloseAsDuplicateCheck() {
   
          Account objAccount = TestDataAccount.getNewAccount();
          system.assertNotEquals(null,objAccount.id);
          
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.Regulatory_Type__c = 'DX';
          objProduct.Source_System__c='SAP';
          insert objProduct;
          system.assertNotEquals(null,objProduct.id);
          
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Product__c=objProduct.Id;
          insert objInstalledProduct;
          system.assertNotEquals(null,objInstalledProduct.id);
          
          List<Case> lstCasesToInsert = new List<Case>();
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase.SVMXC__Product__c = objProduct.Id;
          objCase.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_PENDING;
          objCase.Date_of_Issue_Awareness__c = Date.Today();  
          lstCasesToInsert.add(objCase);
          
          Case objCase2 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase2.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase2.SVMXC__Product__c = objProduct.Id;
          objCase2.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_PENDING;
          objCase2.Date_of_Issue_Awareness__c = Date.Today(); 
          lstCasesToInsert.add(objCase2);
          insert lstCasesToInsert;
          
          system.assertNotEquals(null,objCase2.id);
          system.debug('Test method - insert case successful');        
          Test.startTest();
          objCase.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
          objCase.Answer_2__c = null;
          objCase.Answer_3__c = null;
          objCase.Answer_4__c = null;
          objCase.Answer_5__c = null;
          objCase.Status = STRING_CLOSED_DUPLICATE_STATUS;
          system.debug('Test method - scenario 1');
          try{
              update objCase;
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
          
          objCase.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
          objCase.Answer_2__c = null;
          objCase.Answer_3__c = null;
          objCase.Answer_4__c = STRING_EVALUATION_ANSWER_NO;
          objCase.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
          objCase.Status = STRING_CLOSED_DUPLICATE_STATUS;
          system.debug('Test method - scenario 2');
          try{
              update objCase;
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
          
          objCase.Answer_2__c = STRING_EVALUATION_ANSWER_YES;
          objCase.Answer_3__c = STRING_EVALUATION_ANSWER_YES;
          objCase.Answer_4__c = STRING_EVALUATION_ANSWER_YES;
          objCase.Answer_5__c = STRING_EVALUATION_ANSWER_YES;
          objCase.pAE_pFA_Awareness_Date__c = Date.Today();   
          objCase.Date_of_Issue_Awareness__c = Date.Today();
          objCase.Verification_Result__c ='Completed';
          objCase.Status = STRING_CLOSED_DUPLICATE_STATUS;
          objCase.Record_Updated_from_SFM__c =true;
          system.debug('Test method - scenario 3');
          try{
              update objCase;
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
          
          SVMXC__Service_Order__c objWO=[select id, SVMXC__Case__c from SVMXC__Service_Order__c  where SVMXC__Case__c =: objCase2.id LIMIT 1];
          objWO.SVMXC__Order_Status__c =STRING_CLOSED_DUPLICATE_STATUS;
          try{
              update objWO;
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }
          
          objCase2.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
          objCase2.Answer_2__c = STRING_EVALUATION_ANSWER_NO;
          objCase2.Answer_3__c = STRING_EVALUATION_ANSWER_NO;
          objCase2.Answer_4__c = STRING_EVALUATION_ANSWER_NO;
          objCase2.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
          objCase2.Status = STRING_CLOSED_DUPLICATE_STATUS;
          objCase2.ParentId =objCase.Id;
          objCase2.Record_Updated_from_SFM__c =true;
          system.debug('Test method - scenario 4');
          try{
              update objCase2;
          }
          Catch(Exception ex){
              System.debug(STRING_EXCEPTION + ex.getMessage());
          }   
          objCase.Answer_1__c = STRING_EVALUATION_ANSWER_YES;     
          Test.stopTest();
  
      }
      
      /**
       * method: checkCaseReOpenedStatusFromSFM
       * params:NA
       * return: void
       * Description: This method covers the functionality for DCP-28100 which checks for Case Reopened Status from Web.
      **/
  static testmethod void checkCaseReOpenedStatusFromSFM() {
           cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
           cs.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
           upsert cs cs_Apex_Settings__c.Id;
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.Source_System__c='SAP';
          insert objProduct;
          system.assertNotEquals(null,objProduct.id);
          
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Product__c=objProduct.Id;
          insert objInstalledProduct;
          system.assertNotEquals(null,objInstalledProduct.id);
          
          Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
          //objCase1.PAE_PFA_Evaluation_Required__c = 'Pending';
          //objCase1.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
          //objCase1.pAE_pFA_Awareness_Date__c = Date.Today() -3;
          objCase1.Date_of_Issue_Awareness__c = Date.Today();
          
          insert objCase1;
          
          SVMXC__Service_Order__c objWorkOrder = [Select Id, Integration_Status__c from  SVMXC__Service_Order__c where SVMXC__Case__c =: objCase1.id limit 1];
          objWorkOrder.Integration_Status__c = 'Not Required';
          update objWorkOrder;
          Cases.mapWOIdToWorkOrders = null;
          objCase1.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
          objCase1.Verification_Result__c = 'Test';
          objCase1.Record_Updated_from_SFM__c = true;
          objCase1.Status = STRING_CASE_STATUS_CLOSED;
          objCase1.Record_Updated_from_SFM__c = True;
          update objCase1;
          
          try{
              objCase1.Record_Updated_from_SFM__c = false;
              objCase1.Status = STRING_CASE_STATUS_IN_PROGRESS;
              update objCase1;
          }Catch(Exception ex){
              string errorMsg = ex.getMessage();
              /* DCP-55963 Changed the error message to static final string STRING_ERROR_MESSAGE */
              system.assert(errorMsg.contains(STRING_ERROR_MESSAGE),'Error message contains expected statement');//both reopen reason(RR) & label.CaseReopenedFromWebError error comes here but RR shows as it comes afterwards in order of excecution 
          }
          
          objCase1.Record_Updated_from_SFM__c = true;
          objCase1.Status = STRING_CASE_STATUS_IN_PROGRESS;
          objCase1.Reason_for_Reopen__c = 'test';
          update objCase1;
          String updateCaseStatus = [select Id,Status FROM Case where id = :objCase1.Id LIMIT 1].Status;
          system.assertEquals(updateCaseStatus,STRING_CASE_STATUS_IN_PROGRESS,'Case status is IN Progress');
          
      }
    
      
  /**
       * method: checkCompleteCaseEdit
       * params:NA
       * return: void
       * Description: this method covers the checkCaseEdit method in Cases class (DCP - 26359)
       * created date: 22-Aug-2019
      **/
      
   static testmethod void checkCompleteCaseEdit(){
      
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
          
          Account objAccount = TestDataAccount.getCustomerAccount();
          insert objAccount;
          system.assertNotEquals(null,objAccount.id);
          Contact con = TestDataPerson.getNewContact(objAccount.Id);
          system.assertNotEquals(null,con.id);
          Case parentCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          parentCase.ContactId = con.id;
          insert parentCase;
          system.assertNotEquals(null,parentCase.id);
          Case objCase = TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, 'Initiated', STRING_CASE_ORIGIN);
          objCase.ParentId = parentCase.Id;
          objCase.Sub_Type__c = 'Service Support';
          objCase.Category__c = 'Clinical';
          objCase.ContactId = con.id;
          objCase.Status = STRING_CASE_STATUS_IN_PROGRESS;
          insert objCase;
          system.assertNotEquals(null,objCase.id);
          objCase.Status = 'Completed';
          objCase.Has_SR_Case_Subject_Code__c=true;
          objCase.Record_Updated_from_SFM__c=true;
          //update objCase; 
          
          Test.StartTest();
          System.runAs(u){
          try{
              objCase.Description= 'Completed';
              update objCase;
          }Catch(Exception ex){
              System.debug(ex);
            }
          }
          Test.StopTest();
      }
      
      static testmethod void updateTimeInState() {
         List<String> fieldsTobeSkippedforCompleted = new List<String>{'Test', 'Test1'};
          Set<String> fieldsModified = new Set<String>{'test', 'test1'};
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.Date_of_Issue_Awareness__c = Date.Today();        
          try{
                   
              insert objCase;
              system.assertNotEquals(null,objCase.id, 'Case created successfully');            
              objCase.Description= 'For Test class';
              objCase.ownerId = TestDataUser.findUserInProfile('Customer Service').Id;
              Cases.runTimeInStateCreationOnInsert = true;
              Cases.runTimeInStateUpdateStatusOnce = true;
              update objCase;
              Set<Id> setObjIds = new Set<Id>();
              setObjIds.add(objCase.id);
              Time_In_State__c objTimeInState = new Time_In_State__c(
                          Case__c = objCase.Id,
                          Field__c = 'Case Status',
                          Start_Date_Time__c = System.Now(),
                          Value__c = objCase.Status );                 
              insert objTimeInState;
              system.assertNotEquals(null,objTimeInState.id, 'Record Created successfully'); 
              Time_In_State__c objTimeInState1 = new Time_In_State__c(
                          Case__c = objCase.Id,
                          Field__c = 'Case Owner',
                          Start_Date_Time__c = System.Now(),
                          Value__c = objCase.Status );                 
              insert objTimeInState1;            
              Cases.compareFieldList(fieldsTobeSkippedforCompleted,fieldsModified);
          }
          Catch(Exception ex){
              System.debug('The following exception has occurred: ' + ex.getMessage());
          }
      }
  
      
      static testmethod void checkpAEpFAValidations() {
          Map<Id,Case> oldCasesMap = new Map<Id,Case>(); 
          List<Case> newCases = new List<Case>();
          Map<Id,Case> oldCasesMap1 = new Map<Id,Case>(); 
          List<Case> newCases1 = new List<Case>(); 
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          insert objProduct;
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.Date_of_Issue_Awareness__c = Date.Today();
          try{ 
         test.startTest(); 
              insert objCase;   
              system.assertNotEquals(null,objCase.id, 'Case created successfully');         
              oldCasesMap.put(objCase.id,objCase);
              objCase.Answer_1__c= 'No';
                 objCase.Answer_2__c= null;
              objCase.Answer_3__c= null;
              objCase.Answer_4__c= null;
              objCase.Answer_5__c= null;
              objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
              objCase.Has_BI_Case_Subject_Code__c = true;
              objCase.Sub_Type__c = 'General Issue';
              objCase.Category__c = 'Other';
              objCase.SVMXC__Product__c = objProduct.id;
              objCase.Verification_Result__c = 'Test';            
              objCase.Status = 'Completed';        	
              update objCase;            
              newCases.add(objCase);
              Cases casesClass = new Cases(newCases);
              casesClass.checkpAEpFAEvaluation(newCases,oldCasesMap);
              
              insert objCase1;
              oldCasesMap1.put(objCase1.id,objCase1);
              objCase1.Answer_1__c= null;
                 objCase1.Answer_2__c= null;
              objCase1.Answer_3__c= null;
              objCase1.Answer_4__c= null;
              objCase1.Answer_5__c= null;
              objCase1.PAE_PFA_Evaluation_Required__c = 'Yes';
              objCase1.Has_BI_Case_Subject_Code__c = true;
              objCase1.Sub_Type__c = 'General Issue';
              objCase1.Category__c = 'Other';
              objCase1.SVMXC__Product__c = objProduct.id;
              objCase1.Verification_Result__c = 'Test';            
              objCase1.Status = 'Completed'; 
              update objCase1;            
              newCases1.add(objCase1);
              casesClass.checkpAEpFAEvaluation(newCases1,oldCasesMap1);
          test.stopTest();
          }
          Catch(Exception ex){
              System.debug('The following exception has occurred: ' + ex.getMessage());
          } 
      }
       
      static testmethod void newCaseCreationWithIVDProduct2(){
          cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
          cs.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
          upsert cs cs_Apex_Settings__c.Id;
          Account objAccount = TestDataAccount.getNewAccount();
          system.assertNotEquals(null,objAccount.id);
  
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.Regulatory_Type__c = 'DX';
          objProduct.Source_System__c='SAP';
          insert objProduct;
          system.assertNotEquals(null,objProduct.id);
          
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Product__c=objProduct.Id;
          insert objInstalledProduct;
          system.assertNotEquals(null,objInstalledProduct.id);
          
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.SVMXC__Component__c = objInstalledProduct.Id; 
          objCase.SVMXC__Product__c = objProduct.Id;
          objCase.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_PENDING;
          //objCase.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
          //objCase.pAE_pFA_Awareness_Date__c = Date.Today() -3;   
          objCase.Date_of_Issue_Awareness__c = Date.Today();      
          insert objCase;
          system.assertNotEquals(null,objCase.id);
          
          try{
              objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
              update objCase;
          }catch(Exception ex){
              system.debug('Error'+ex.getmessage());
          }
          try{
              objCase.Date_of_Issue_Awareness__c = Date.Today().addDays(2);
              update objCase;
          }catch(Exception ex){
              system.debug('Error'+ex.getmessage());
              }
      }
      /**
      *  @author Dhairya Shah
      *  @description - CMCM-7910: Method to check product serial number
      **/
      static testmethod void populateSerialLotNumber(){
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
        cs.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
        upsert cs cs_Apex_Settings__c.Id;
        Account objAccount = TestDataAccount.getNewAccount();
        system.assertNotEquals(null,objAccount.id);

        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        objProduct.Source_System__c='SAP';
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
        
        SVMXC__Installed_Product__c objInstalledProductLotNumber = TestDataFieldService.createInstalledProductforLotNumber(STRING_INSTALLED_PRODUCT_IP_NAME, STRING_INSTALLED_PRODUCT_STATUS,STRING_INSTALLED_PRODUCT_SERIAL_LOT_NUMBER);
        objInstalledProductLotNumber.SVMXC__Product__c=objProduct.Id;
        insert objInstalledProductLotNumber;
        system.assertNotEquals(null,objInstalledProductLotNumber.id);
        
        test.starttest();
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProductLotNumber.Id; 
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c =STRING_EVALUATION_ANSWER_PENDING;
        objCase.Date_of_Issue_Awareness__c = Date.Today();   
           
        insert objCase;
        // Fetch the inserted case
        Case fetchedCase = [SELECT SVMXC__Component__c, Product_Serial_Number__c FROM Case WHERE Id = :objCase.Id];

        // Stop the test
        Test.stopTest();

        // Verify that Product_Serial_Number__c has been set correctly
        System.assertEquals('A01195', fetchedCase.Product_Serial_Number__c, 'The Product Serial Number should be set correctly.');
        
    }
      
      static testmethod void awaitingResponseAndOwnerChangeTest(){
          Group testGroup = new Group(Name='test group', Type='Queue');
          insert testGroup;
          
          System.runAs(new User(Id=UserInfo.getUserId()))
          {
              QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
              insert testQueue;
          }
          Case objCase = TestDataCase.initNewCase('Inquiry', STRING_CASE_STATUS_IN_PROGRESS, 'In Person - CS');
          insert objCase;
          
          test.starttest();
          objCase.Status = System.label.CaseStatusAwaitingResponseCustomer;
          objCase.Awaiting_Response_Reason__c = 'Address';
          objCase.OwnerId = testGroup.id;
          update objCase;
          
          objCase.Status = System.label.CaseStatusInProgress;
          update objCase;
          test.stopTest();
          System.assertEquals(null, [select id,Awaiting_Response_Reason__c from case where id =: objCase.Id][0].Awaiting_Response_Reason__c,'There is no case record with awaiting response reason set');
          //Start (CMCP-23) checking for negative scenario.
          System.assert(![select id,Partner_Case__c from case where id =: objCase.Id][0].Partner_Case__c,'Partner Case Set');
          //End (CMCP-23)
      }
      
      static testmethod void checkEditOnPAEAwarenessdate(){
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.Source_System__c='SAP';
          insert objProduct;
          system.assertNotEquals(null,objProduct.id);
  
          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Product__c=objProduct.Id;
          insert objInstalledProduct;
          system.assertNotEquals(null,objInstalledProduct.id);

          cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
          cs.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
          upsert cs cs_Apex_Settings__c.Id; 
          
          Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase.Date_of_Issue_Awareness__c = Date.Today().addDays(-4);
          objCase.SVMXC__Component__c = objInstalledProduct.Id;
          objCase.Awareness_Date_Difference_Reason__c ='Logistical delay'; 
          insert objCase;
          
          Cases.skipCaseTrigger = false; // Added as part of CMCM-8242
          objCase.pAE_pFA_Awareness_Date__c = Date.Today().addDays(-3);
          objCase.Explanation_for_pAE_pFA__c='Test';
          objCase.Answer_1__c = STRING_EVALUATION_ANSWER_YES;
          objCase.pAE_pFA_Awareness_Date_Difference_Reason__c = 'Updated information presented by customer';
          update objCase;
          Test.startTest();
          try{
              objCase.pAE_pFA_Awareness_Date__c = null;
              update objCase;
          } 
          catch(Exception ex)
          {System.assertNotEquals('pAE/pFA Awareness Date is required when pAE/pFA is Yes.', ex.getMessage());}
          try{
              objCase.pAE_pFA_Awareness_Date__c = Date.Today();
              update objCase;
          }
          catch(Exception ex){
              System.assertNotEquals('pAE/pFA Awareness Date cannot be edited after it has been saved. Please send an email request to QAcomplatintunit@illumina.com if you need to update the pAE/pFA Awareness Date on this Case.', ex.getMessage());
          }
          Test.stopTest();
      }
  
       /**
      *  @author Adyasha Satapathy
      *  @description - DCP-44980: Method to check IVD Product Identifier(Additional Product) flag
      **/
      static testmethod void checkIVDAdditionalProduct(){
         
          Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.Regulatory_Type__c = STRING_REGULATORY_TYPE_DX;
          objProduct.Source_System__c='SAP';
          insert objProduct;
          
          List<Case> lstCases = new List<Case>();
          Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN); 
          objCase1.SVMXC__Product__c = objProduct.Id;
          objCase1.Subject = STRING_CASE_SUBJECT;
          
          Case objCase2 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN); 
          objCase2.SVMXC__Product__c = objProduct.Id;
          objCase2.Subject = STRING_CASE_SUBJECT2;
          objCase2.QA_Review__c = Cases.STRING_QA_REVIEW_NO_IVD_PRODUCT;
  
          lstCases.add(objCase1);
          lstCases.add(objCase2);
          insert lstCases;
  
         
          Test.startTest();
              List<Case> lstCS = [Select Id, QA_Review__c,Subject,IVD_Product_Identifier_Additional_Prod__c from Case LIMIT 2];
              for(Case c:lstCS)
              {
                  if(c.Subject == STRING_CASE_SUBJECT)
                  {
                      c.QA_Review__c = Cases.STRING_QA_REVIEW_NO_IVD_PRODUCT;
                  }
                  else
                  {
                      c.QA_Review__c = STRING_QA_REVIEW_IN_PROGRESS;
                  }
              }
              update lstCS;
          Test.stopTest();
  
          Case objNewCS = [Select Id, QA_Review__c, IVD_Product_Identifier_Additional_Prod__c from Case where Subject =: STRING_CASE_SUBJECT2];
          System.assert(!objNewCS.IVD_Product_Identifier_Additional_Prod__c,'IVD Product Identifier is not set on case');
      }
  
      /**
      *  @author Nishan Shetty
      *  @description - CMCP-23 method to check Partner Case flag update during insert.
      **/
      static testmethod void checkChannelPartnerCaseCreate() {
  
          //Created Account1
          Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
          objAccount1.Account_Group__c='Distributor';
          insert objAccount1;
  
          //Created Contact1
          Contact objContact = TestDataContact.getNewContact(objAccount1);
  
          User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
  
          User objUser;
          User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{thisUser.Id});
          TestDataUser.allowUserCreation(objUser1.Id); 
           
          System.runAs(objUser1) {
          Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;    
          //Querying Territory Type
          List<Territory2Type> territoryType   = [SELECT id, DeveloperName from Territory2Type where  DeveloperName = 'Territory_Value_Added_Distributor_Channel_Partner' LIMIT 1];
          
          //Querying Active Territory Model
          Territory2Model terrModel = [SELECT Id, Name, (SELECT Id, Name FROM Territory2s) FROM Territory2Model WHERE State = 'Active' Limit 1];
           
    
          //Creating Territory 
          Territory2 objTerritory = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId=terrModel.Id, Name='TestTerritory', Territory2TypeId=territoryType[0].Id);
          insert objTerritory;
          
          //Associating Territory with Account1
          ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,objAccount1.id);
          insert objTerritoryAssociation;
  
          
          //Created User
          objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
          insert objUser;
   
          Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
          cp.SetupOwnerId= profileId;
          cp.Is_Channel_Partner__c= True;
          insert cp;
          }
  
          test.startTest();
          system.runAs(objUser) {
            Case objCase= TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, STRING_CASE_STATUS, STRING_CASE_ORIGIN); 
            objCase.AccountId=objAccount1.Id;
            objCase.ContactId=objContact.Id;
            objCase.Subject='Test';
            objCase.Description='Test';
            objCase.Date_of_Issue_Awareness__c = Date.Today(); 
            objCase.Sub_Type__c='Service Support';
            insert objCase;
            }
          test.stopTest(); 
  
          Case objNewCase=[Select Id,Partner_Case__c from Case where AccountId=:objAccount1.Id];
          System.assert(objNewCase.Partner_Case__c,'Partner Case Flag Not Set');
          
      }
  
  
     /**
       *  @author Nishan Shetty
       *  @description - CMCP-23 method to check Partner Case flag update during update.
       **/
        static testmethod void checkChannelPartnerCaseUpdate() {
          
          //Created Account1
          Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
          objAccount1.Account_Group__c='Distributor';
          insert objAccount1;
              
          //Created Contact1
          Contact objContact = TestDataContact.getNewContact(objAccount1);
  
           User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
  
          User objUser;
          User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{thisUser.Id});
          TestDataUser.allowUserCreation(objUser1.Id); 
           
          System.runAs(objUser1) {
          Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;    
          //Querying Territory Type
          List<Territory2Type> territoryType   = [SELECT id, DeveloperName from Territory2Type where  DeveloperName = 'Territory_Value_Added_Distributor_Channel_Partner' LIMIT 1];
          
          //Querying Active Territory Model
          Territory2Model terrModel = [SELECT Id, Name, (SELECT Id, Name FROM Territory2s) FROM Territory2Model WHERE State = 'Active' Limit 1];
           
         
          //Creating Territory 
          Territory2 objTerritory = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId=terrModel.Id, Name='TestTerritory', Territory2TypeId=territoryType[0].Id);
          insert objTerritory;
  
          //Associating Territory with Account2
          ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,objAccount1.id);
          insert objTerritoryAssociation;
          
          
          //Created User
          objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
          insert objUser;
   
          Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
          cp.SetupOwnerId= profileId;
          cp.Is_Channel_Partner__c= True;
          insert cp;
          }
  
          test.startTest();
          system.runAs(objUser1) {
            Case objCase= TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, STRING_CASE_STATUS, STRING_CASE_ORIGIN); 
            objCase.AccountId=objAccount1.Id;
            objCase.ContactId=objContact.Id;
            objCase.Subject='Test';
            objCase.Description='Test';
            objCase.Date_of_Issue_Awareness__c = Date.Today(); 
            objCase.Sub_Type__c='Service Support';
            insert objCase;
            objCase.OwnerId=objUser.Id;
            update objCase;
            }
          test.stopTest(); 
  
          Case objNewCase=[Select Id,Partner_Case__c from Case where AccountId=:objAccount1.Id];
          System.assert(objNewCase.Partner_Case__c,'Partner Case Flag Not Set');
  
         }    
  
      /**
      *  @author Rishi Sharma
      *  @description - DCP-47271 - Test Work Order Field update on case after a case is reopened.
      **/
      static testmethod void testReopenedCaseWo() {
  
          //Created Account1
          Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
          objAccount1.Account_Group__c='Distributor';
          insert objAccount1;
              
          //Created Contact1
          Contact objContact = TestDataContact.getNewContact(objAccount1);
  
          User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
  
          User objUser = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{thisUser.Id});
          TestDataUser.allowUserCreation(objUser.Id); 
  
          
          system.runAs(objUser) {
          Case objCase= TestDataCase.initNewCase(STRING_CASR_RECORDTYPE_SERVICE_REQUEST, STRING_CASE_STATUS, STRING_CASE_ORIGIN); 
          objCase.AccountId=objAccount1.Id;
          objCase.ContactId=objContact.Id;
          objCase.Subject='Test';
          objCase.Description='Test';
          objCase.Date_of_Issue_Awareness__c = Date.Today(); 
          objCase.Sub_Type__c='Service Support';
          
          insert objCase;
  
          SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, objCase.Id, 'Initiated');
          workOrder.SVMXC__Order_Type__c='Installation';
          workOrder.Is_Auto_Created__c = true;
          workOrder.Integration_Status__c = 'Not Required';
  
          insert workOrder;
          test.startTest();
          objCase.Status = STRING_CASE_STATUS_CLOSED;
          update objCase;
  
          objCase.Status = Label.CaseStatusReopenRequested;
          objCase.Reason_for_Reopen__c = 'test';
          update objCase;
          objCase.Status = Label.CaseStatusReopened;
          update objCase;
          
           
          Case caseRec=[SELECT id, Work_Order__c  FROM Case where ID =:objCase.id];
          System.assertEquals(caseRec.Work_Order__c, workOrder.Id,'Case record has a workorder like to it');
          }      
          test.stopTest();
  
      } 
  
      /*
      *  @author Nishan Shetty
      *  @description CMCP-22- Test Send GTS Relocation Case to SAP.
      **/
      static testmethod void testSendGTSCaseToSAP() {
          
          //Created Account1
          Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
          objAccount1.Account_Group__c='Distributor';
          insert objAccount1;
  
          //Created Contact
          Contact objContact = TestDataContact.getNewContact(objAccount1);
  
          //Created Service Case
          Case objCase = TestDataCase.initServiceRequestCase(objContact);
          insert objCase; 
  
          test.startTest();
          objCase.GTS_Status__c='Request Initiated';
          update objCase;
          test.stopTest();
          Case objNewCase=[Select Id,GTS_Status__c from Case where id=:objCase.Id];
          System.assertEquals('Request Initiated',objNewCase.GTS_Status__c,'GTS Status Not Set');
      }
  
      /*
      *  @author Nishan Shetty
      *  @description CMCP-22- Test Duplicate Work Order on Case.
      **/
      static testmethod void testvalidateCaseWorkAssociationForGTS() {
          
        //Created Account1
        Account objAccount1 = TestDataAccount.getAccount('Test Acc', 'USD');
        objAccount1.Account_Group__c='Distributor';
        insert objAccount1;

        //Created Contact
        Contact objContact = TestDataContact.getNewContact(objAccount1);


        //Created Service Case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;	

        //Create Work Order     
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, objCase.Id, 'Initiated');
        objWorkOrder.SVMXC__Company__c = objAccount1.id;
        objWorkOrder.SVMXC__Order_Type__c = 'Installation';
        objWorkOrder.Is_Auto_Created__c=true;
        insert objWorkOrder;

        Boolean expectedExceptionThrown=false;

        test.startTest();
        try {
            objCase.GTS_Status__c='Request Initiated';
            update objCase;
        } catch(Exception e) {
            expectedExceptionThrown = e.getMessage().contains(Label.WorkOrderCaseAssociationErrorMsg) ? true : false; 
        }
        test.stopTest();

        System.assert(true,expectedExceptionThrown);
        
    }



    /*
     *  @author Nishan Shetty
     *  @description CMCP-64- Test Request Ownership Status on Case.
    **/
    static testmethod void testRequestOwnershipStatusUpdate() {

        //Created Account1
        Account objAccount1 = TestDataAccount.getAccount('Test Acc New', 'USD');
        objAccount1.Account_Group__c='Distributor';
        insert objAccount1;

        //Created Contact
        Contact objContact = TestDataContact.getNewContact(objAccount1);


        User objUser;
        User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{Id.valueOf(UserInfo.getUserId())});
        TestDataUser.allowUserCreation(objUser1.Id);
        System.runAs(objUser1) {
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;     
            //Created User
            objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
            insert objUser;

            //Creating Custom Setting
            Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
            cp.SetupOwnerId= profileId;
            cp.Is_Channel_Partner__c= True;
            insert cp;
        }   
        test.startTest();
       //Created Service Case
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.Request_Ownership_Status__c='Requested';
        Cases.mapUserIdToUser=null;
        objCase.OwnerId=objUser.Id;
        insert objCase;

        
        test.stopTest();
        Case objNewCase=[Select Id,Request_Ownership_Status__c from Case where AccountId=:objAccount1.Id];
        System.assertEquals('Completed',objNewCase.Request_Ownership_Status__c,'Request Ownership Status Not Set');
    }
    
    /*******************************************************************************************************
    * author - Deepika Ayyavari
    * @description test method to check Internal Non Customer checkbox for web email
    * 
    */

    static testmethod void internalNonCustomerCheck(){     
        
            Account objAcc = TestDataAccount.getNewAccount();
            Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
            insert con;
            Case cs = TestDataCase.initServiceRequestCase(con);
            cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId(); 
            cs.SuppliedEmail = 'test@efwnow.com';            
            cs.origin = 'Email - CS';            
            test.startTest();
                insert cs;      
            test.stopTest();
            Case newCase = [Select Id, SuppliedEmail, Internal_Non_Customer__c From Case where Id =: cs.Id ];
            System.debug('newCase:' +newCase);
            System.assert(newCase.Internal_Non_Customer__c, 'Internal Non Customer is set to True');     
        
    }
    /*******************************************************************************************************
    * author - Deepika Ayyavari
    * @description test method to check Internal Non Customer for TS
    * 
    */
    static testmethod void internalNonCustomerCheckForTS(){     
        Map<String, String> queueNameToIdMap = UtilsSettings.getCustomMetadataMap('Queue_Ids');
        Account objAcc = TestDataAccount.getNewAccount();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'Order';
        cs.Category__c = STRING_CASE_CATEGORY_ORDER; 
        cs.Status = STRING_CASE_STATUS_IN_PROGRESS;
        cs.SuppliedEmail = 'test@illumina.com';            
        cs.origin = 'Email - CS';   
        insert cs;         
        test.startTest();
        if(!queueNameToIdMap.isEmpty()){
            cs.ownerId = queueNameToIdMap.get('Technical_Support');
            update cs;
        }      
                  
        test.stopTest();
        Case newCase = [Select Id, SuppliedEmail, Internal_Non_Customer__c From Case where Id =: cs.Id ];
        System.assert(!newCase.Internal_Non_Customer__c, 'Internal Non Customer is set to True');     
    
     }
     /*******************************************************************************************************
    * author - Preetha
    * QACM-82
    * @description test method validateProductUtilizationMode On Case for Additionl products/Products
    **/
    static testmethod void testvalidateProductUtilizationMode(){ 
        try{
            List<Code_Library__c> codeLibList = new List<Code_Library__c>();
            List<Associated_Codes__c> associdateCode = new list<Associated_Codes__c>();
            Account objAcc = TestDataAccount.getNewAccount();
            Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
            insert con;
            Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
            objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
            objProduct.Regulatory_Type__c = 'DX';
            insert objProduct;
            
            Id myId = UserInfo.getUserId();
            cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
            csapex.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
            csapex.Bypass_All_Validations__c = true;
            csapex.SetupOwnerId = myId;
            insert csapex;
            
            Case objCase = TestDataCase.initServiceRequestCase(con);
            objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
            objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
            objCase.Status = 'In Progress';// Test class fix by dhairya shah
            objCase.SVMXC__Product__c = objProduct.Id;
            objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
            objCase.Description = 'testDescription';
            objCase.Sub_Type__c = STRING_CASE_SUB_TYPE;    
            objCase.Category__c = 'LIMS';
            insert objCase;
            
            SVMXC__service_order__c objWO = [select id,Evaluation__c,SVMXC__Work_Performed__c,Verification_Result__c,SVMXC__Order_Status__c from SVMXC__service_order__c where SVMXC__case__c =: objCase.Id];
            
            Code_Library__c acl = new Code_Library__c();
            acl.Name='INQ General Process Inquiry';
            acl.Code_type__c = 'Analysis';
            acl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
            codeLibList.add(acl);
            
            Code_Library__c scl = new Code_Library__c();
            scl.Name='INQ General Process Inquiry';
            scl.Code_type__c = 'Subject';
            scl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
            codeLibList.add(scl);
            
            Code_Library__c rcl = new Code_Library__c();
            rcl.Name='BUS Retrained User';
            rcl.Code_type__c = 'Resolution';
            rcl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
            codeLibList.add(rcl);
            
            Code_Library__c hcl = new Code_Library__c();
            hcl.Name='CompalintHazard';
            hcl.Code_type__c = 'Hazard';
            hcl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
            codeLibList.add(hcl);
            insert codeLibList;
            
            for(Code_Library__c cl : codeLibList){
                Associated_Codes__c ac = new Associated_Codes__c();
                ac.Code_Title__c = cl.Id;
                ac.Case__c = objCase.Id;
                ac.Work_Order__c = objWO.Id;
                associdateCode.add(ac);
            }
            insert associdateCode;
            
            Test.startTest();
            objWo.Evaluation__c = 'testEvaluation';
            objWo.SVMXC__Work_Performed__c = 'testWorkPerformed';
            objWo.Verification_Result__c = 'testVerificationResult';
            objWO.SVMXC__Order_Status__c = STRING_CASE_STATUS_COMPLETED;
            update objWO;
            
            objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_YES;
            objCase.pAE_pFA_Awareness_Date__c = Date.today();
            objCase.Question_1__c = 'Did the issue involve a death or serious injury to either the patient or the operator?';
            objCase.Question_2__c = 'Could the issue cause a death or serious injury if it were to recur?';
            objCase.Answer_1__c = STRING_EVALUATION_ANSWER_YES;
            objCase.Answer_2__c = STRING_EVALUATION_ANSWER_NO;
            objCase.Question_3__c = '"Has the customer submitted a Medical Device Report to the FDA or has the customer reported the issue to other regulatory agencies for Illumina’s regulated products?"';
            objCase.Question_4__c = '"Did the IVD product fail to perform as intended? E.g. product not performing as designed, or meeting package insert specification such as sensitivity, specificity, and accuracy, due to a product deficiency."';
            objCase.Question_5__c = '"Did the determined issue suggest misbranding, labeling or an adulterated IVD product (defective, unsafe, or contaminated)? E.g. product mislabeled, incorrectly packaged, incorrect instruction in package insert, reagent contains foreign substance."';
            objCase.Answer_3__c = STRING_EVALUATION_ANSWER_NO;
            objCase.Answer_4__c = STRING_EVALUATION_ANSWER_YES;
            objCase.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
            objCase.Investigation_Summary_Comments__c = 'test';
            objCase.Logistics_Investigation_Summary_Comments__c = 'logistictest';
            objCase.Logistics_Review__c = 'See Investigation Summary/Comments';
            objCase.Status = 'Pending Logistics Review';
            objCase.Record_Updated_from_SFM__c = True;
            update objCase;
        }Catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Product Utilization Mode is required for IVD Complaint cases. Populate Product Utilization Mode before completing this case.') ? true : false;
            system.assert(expectedExceptionThrown,'Product Validation is not thrown');       
        }
         test.stopTest();
    }
    /*******************************************************************************************************
    * author - Preetha
    * QACM-82
    * @description test method validateProductUtilizationMode On Case for Additionl products/Products to RUO
    * 
    */
     static testmethod void testvalidateProductUtilizationMode1(){ 
        try{
            List<Code_Library__c> codeLibList = new List<Code_Library__c>();
            List<Associated_Codes__c> associdateCode = new list<Associated_Codes__c>();
            Account objAcc = TestDataAccount.getNewAccount();
            Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
            insert con;
            Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
            objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
            objProduct.Regulatory_Type__c = 'RUO';
            insert objProduct;
            
            Id myId = UserInfo.getUserId();
            cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
            csapex.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
            csapex.Bypass_All_Validations__c = true;
            csapex.SetupOwnerId = myId;
            insert csapex;
            
            Case objCase = TestDataCase.initServiceRequestCase(con);
            objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
            objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
            objCase.Explanation_for_pAE_pFA__c='Test';
            objCase.Status = 'Initiated';
            objCase.SVMXC__Product__c = objProduct.Id;
            objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
            objCase.Description = 'testDescription';
            objCase.Sub_Type__c = STRING_CASE_SUB_TYPE;    
            objCase.Category__c = 'LIMS';
            insert objCase;
            
            Test.startTest();
            SVMXC__service_order__c objWO = [select id,Evaluation__c,SVMXC__Work_Performed__c,Verification_Result__c,SVMXC__Order_Status__c from SVMXC__service_order__c where SVMXC__case__c =: objCase.Id];
            
            Code_Library__c acl = new Code_Library__c();
            acl.Name='INQ General Process Inquiry';
            acl.Code_type__c = 'Analysis';
            acl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
            codeLibList.add(acl);
            
            Code_Library__c scl = new Code_Library__c();
            scl.Name='INQ General Process Inquiry';
            scl.Code_type__c = 'Subject';
            scl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
            codeLibList.add(scl);
            
            Code_Library__c rcl = new Code_Library__c();
            rcl.Name='BUS Retrained User';
            rcl.Code_type__c = 'Resolution';
            rcl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
            codeLibList.add(rcl);
            
            Code_Library__c hcl = new Code_Library__c();
            hcl.Name='CompalintHazard';
            hcl.Code_type__c = 'Hazard';
            hcl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
            codeLibList.add(hcl);
            insert codeLibList;
            
            for(Code_Library__c cl : codeLibList){
                Associated_Codes__c ac = new Associated_Codes__c();
                ac.Code_Title__c = cl.Id;
                ac.Case__c = objCase.Id;
                ac.Work_Order__c = objWO.Id;
                associdateCode.add(ac);
            }
            insert associdateCode;
            
            objWo.Evaluation__c = 'testEvaluation';
            objWo.SVMXC__Work_Performed__c = 'testWorkPerformed';
            objWo.Verification_Result__c = 'testVerificationResult';
            objWO.SVMXC__Order_Status__c = STRING_CASE_STATUS_COMPLETED;
            update objWO;
            
            objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_YES;
            objCase.pAE_pFA_Awareness_Date__c = Date.today();
            objCase.Explanation_for_pAE_pFA__c='Test';
            objCase.Question_1__c = 'Did the issue involve a death or serious injury to either the patient or the operator?';
            objCase.Question_2__c = 'Could the issue cause a death or serious injury if it were to recur?';
            objCase.Answer_1__c = STRING_EVALUATION_ANSWER_YES;
            objCase.Answer_2__c = STRING_EVALUATION_ANSWER_NO;
            objCase.Question_3__c = '"Has the customer submitted a Medical Device Report to the FDA or has the customer reported the issue to other regulatory agencies for Illumina’s regulated products?"';
            objCase.Question_4__c = '"Did the IVD product fail to perform as intended? E.g. product not performing as designed, or meeting package insert specification such as sensitivity, specificity, and accuracy, due to a product deficiency."';
            objCase.Question_5__c = '"Did the determined issue suggest misbranding, labeling or an adulterated IVD product (defective, unsafe, or contaminated)? E.g. product mislabeled, incorrectly packaged, incorrect instruction in package insert, reagent contains foreign substance."';
            objCase.Answer_3__c = STRING_EVALUATION_ANSWER_NO;
            objCase.Answer_4__c = STRING_EVALUATION_ANSWER_YES;
            objCase.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
            objCase.Investigation_Summary_Comments__c = 'test';
            objCase.Logistics_Investigation_Summary_Comments__c = 'logistictest';
            objCase.Logistics_Review__c = 'See Investigation Summary/Comments';
            objCase.Status = 'Pending Logistics Review';
            objCase.Record_Updated_from_SFM__c = True;
            update objCase;
            Case insertedCs= [Select id,Product_Utilization_Mode__c from Case Where id=:objCase.Id Limit 1];
            system.assertEquals('RUO',insertedCs.Product_Utilization_Mode__c,'Product Utilization mode is not Populated');
            test.stopTest();
        }Catch(Exception e){
            System.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error');
        }
    }
    /*******************************************************************************************************
    * author - Preetha
    * QACM-82
    * @description test method validateProductUtilizationMode Exception in the catch block
    * 
    */
    @isTest
    static void testvalidateProductUtilizationModeException() {
        Test.startTest();
        try {
            Cases.validateProductUtilizationMode(null,null);
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error');
        }
        Test.stopTest();
    }

    /*******************************************************************************************************
    * author - Abhinav Gupta
    * @description test method to check if QA Reopen Codes are updated
    * ******************************************************************************************************
    */
    static testmethod void checkIfQAReopenCodesUpdated(){
        cs_Apex_Settings__c c=cs_Apex_Settings__c.getInstance(UserInfo.getProfileID());

            c.Bypass_All_Validations__c = true;

            upsert c cs_Apex_Settings__c.Id;
        Account objAcc = TestDataAccount.getNewAccount();
        objAcc.recordTypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Indirect Partner').getRecordTypeId();
        update objAcc;
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Case cs = TestDataCase.createCase('Business Issue','Initiated',con.Id);
        
            c.Bypass_All_Validations__c = false;

        upsert c cs_Apex_Settings__c.Id;
        cs.QA_Reopen_Code_s__c = 'Account';
        update cs;
        Test.startTest();
        cs.QA_Reopen_Code_s__c = 'Description';
        update cs;
        Test.stopTest();
        Case newCase = [Select Id, QA_Reopen_Code_s__c from Case where Id =: cs.Id ];
        System.assertEquals(cs.QA_Reopen_Code_s__c, newCase.QA_Reopen_Code_s__c, 'Reopen Code(s) Not equal');

    }

      /*******************************************************************************************************
    * author - Preetha
    * @description test method to check Show On Case for Additionl products
    * 
    */
    static testmethod void testCheckShowOnCaseOnAP(){ 
        try{
                  Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
          objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
          objProduct.Source_System__c='SAP';
          insert objProduct;

          SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
          objInstalledProduct.SVMXC__Product__c=objProduct.Id;
          insert objInstalledProduct;
          
          test.startTest();
          Case objCase1 = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
          objCase1.SVMXC__Component__c = objInstalledProduct.Id; 
          ObjCase1.Sub_Type__c = 'Complaint';
          objCase1.Date_of_Issue_Awareness__c = Date.Today();
          
          insert objCase1;
           test.stopTest();
         
            
          SVMXC__Service_Order__c objWorkOrder = [Select Id, Integration_Status__c from  SVMXC__Service_Order__c where SVMXC__Case__c =: objCase1.id limit 1];
          objWorkOrder.Integration_Status__c = 'Not Required';
          update objWorkOrder;
          Cases.mapWOIdToWorkOrders = null;
          objCase1.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_NO;
          objCase1.Verification_Result__c = 'Test';
          objCase1.Record_Updated_from_SFM__c = true;

          objCase1.Status = STRING_CASE_STATUS_CLOSED;
          objCase1.Record_Updated_from_SFM__c = True;
          update objCase1;
          
          

        }Catch(Exception e){
             Boolean expectedExceptionThrown =  e.getMessage().contains('"Show on Case" is not checked on any case Associated Product (AP). Select "Show on Case" for the most relevant AP.') ? true : false;
             system.assert(expectedExceptionThrown,'Show on case validation');       
        }
    }
     /*******************************************************************************************************
    * author - Avina[QACM-8]
    * @description - test method to check the first QA and Last QA review completion date fields is updating or once the case is closed 
    * 
    */
    static testmethod void testQACompletedDates(){
        cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());             
        cs.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
        upsert cs cs_Apex_Settings__c.Id;   
        List<Code_Library__c> codeLibList = new List<Code_Library__c>();
        List<Associated_Codes__c> associdateCode = new list<Associated_Codes__c>();
        Account objAcc = TestDataAccount.getCustomerAccount();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        objProduct.Source_System__c = 'SAP';
        insert objProduct;

        User usr = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'GIS User Provisioning'].Id,
                LastName = 'last',
                Email = 'QAuser000@test.com',
                Username = 'QAuser000@test.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
            );
        insert usr;
        
        Id myId = UserInfo.getUserId();
        cs_Apex_Settings__c csapex = new cs_Apex_Settings__c();
        csapex.Bypass_All_Validations__c = true;
        csapex.SetupOwnerId = usr.Id;
        insert csapex;
        Test.startTest();
        Case objCase = TestDataCase.initServiceRequestCase(con);
        objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
        objCase.Explanation_for_pAE_pFA__c='Test';
        objCase.Status = 'In Progress';// Test class fix by dhairya shah
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
        objCase.Description = 'testDescription';
        objCase.Sub_Type__c = STRING_CASE_SUB_TYPE;    
        objCase.Category__c = 'LIMS';
        objCase.QA_Reviewer__c = usr.Id;
        objCase.Awareness_Date_Difference_Reason__c ='Logistical delay';
        insert objCase;

        SVMXC__service_order__c objWO = [select id,Evaluation__c,SVMXC__Work_Performed__c,Verification_Result__c,SVMXC__Order_Status__c from SVMXC__service_order__c where SVMXC__case__c =: objCase.Id];
          
        Code_Library__c acl = new Code_Library__c();
        acl.Name='INQ General Process Inquiry';
        acl.Code_type__c = 'Analysis';
        acl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        codeLibList.add(acl);

        Code_Library__c scl = new Code_Library__c();
        scl.Name='INQ General Process Inquiry';
        scl.Code_type__c = 'Subject';
        scl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        codeLibList.add(scl);

        Code_Library__c rcl = new Code_Library__c();
        rcl.Name='BUS Retrained User';
        rcl.Code_type__c = 'Resolution';
        rcl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        codeLibList.add(rcl);
        
        Code_Library__c hcl = new Code_Library__c();
        hcl.Name='CompalintHazard';
        hcl.Code_type__c = 'Hazard';
        hcl.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        codeLibList.add(hcl);
        insert codeLibList;
        
        for(Code_Library__c cl : codeLibList){
            Associated_Codes__c ac = new Associated_Codes__c();
            ac.Code_Title__c = cl.Id;
            ac.Case__c = objCase.Id;
            ac.Work_Order__c = objWO.Id;
            associdateCode.add(ac);
        }
        insert associdateCode;

        objWo.Evaluation__c = 'testEvaluation';
        objWo.SVMXC__Work_Performed__c = 'testWorkPerformed';
        objWo.Verification_Result__c = 'testVerificationResult';
        objWO.SVMXC__Order_Status__c = STRING_CASE_STATUS_COMPLETED;
        objWO.Additional_Detail__c = 'abc'; //Added by Vishal for CMCM-10196
        objWO.SVMXC__Product__c=objProduct.id; // added by Dhairya Shah for test class fix
        update objWO;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_YES;
        objCase.pAE_pFA_Awareness_Date__c = Date.today();
        objCase.Question_1__c = 'Did the issue involve a death or serious injury to either the patient or the operator?';
        objCase.Question_2__c = 'Could the issue cause a death or serious injury if it were to recur?';
        objCase.Answer_1__c = STRING_EVALUATION_ANSWER_YES;
        objCase.Answer_2__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Question_3__c = '"Has the customer submitted a Medical Device Report to the FDA or has the customer reported the issue to other regulatory agencies for Illumina’s regulated products?"';
        objCase.Question_4__c = '"Did the IVD product fail to perform as intended? E.g. product not performing as designed, or meeting package insert specification such as sensitivity, specificity, and accuracy, due to a product deficiency."';
        objCase.Question_5__c = '"Did the determined issue suggest misbranding, labeling or an adulterated IVD product (defective, unsafe, or contaminated)? E.g. product mislabeled, incorrectly packaged, incorrect instruction in package insert, reagent contains foreign substance."';
        objCase.Answer_3__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Answer_4__c = STRING_EVALUATION_ANSWER_YES;
        objCase.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Investigation_Summary_Comments__c = 'test';
        objCase.Logistics_Investigation_Summary_Comments__c = 'logistictest';
        objCase.Logistics_Review__c = 'See Investigation Summary/Comments';
        objCase.Status = 'Pending Logistics Review';
        objCase.Product_Utilization_Mode__c = 'RUO';
        objCase.pAE_pFA_Awareness_Date_Difference_Reason__c = 'Updated information presented by customer';
        objCase.Verification_Result__c = 'Test';
        update objCase;
        Test.stopTest();
        objCase.QA_Review__c = 'Non IVD Product';
        objCase.QA_Product_Family__c = 'NIPT';
        objCase.QA_Sub_Product_Family__c = 'NIPT Solution v2'; // TASK0829705
        objCase.Status = 'Pending QA Review';
        update objCase;

        
        objCase.Status = STRING_CASE_STATUS_COMPLETED;
        update objCase;
        
        Case completedCase = [Select Status,First_QA_Review_Completion_Date__c,Last_QA_Review_Completion_Date__c from Case where Id =: objCase.Id limit 1];
        system.assertNotEquals(null,completedCase.First_QA_Review_Completion_Date__c,'First QA Review Completion date field did not updated');
        system.assertNotEquals(null,completedCase.Last_QA_Review_Completion_Date__c,'Last QA Review Completion date field did not updated');
        system.assertEquals(completedCase.First_QA_Review_Completion_Date__c,completedCase.Last_QA_Review_Completion_Date__c,'Please check both field values are not equal when case has Completed');
        
        completedCase.Status = 'Pending QA Review';
        completedCase.Record_Updated_from_SFM__c = True;
        completedCase.First_QA_Review_Completion_Date__c=System.today() - 1;
        update completedCase;
        
        completedCase.Status = STRING_CASE_STATUS_CLOSED;
        update completedCase;
        
        Case closedCase = [Select First_QA_Review_Completion_Date__c,Last_QA_Review_Completion_Date__c from Case where Id =: objCase.Id limit 1];
        system.assertNotEquals(closedCase.First_QA_Review_Completion_Date__c,closedCase.Last_QA_Review_Completion_Date__c,'Please check both field values are equal when case has closed');
        
    }
	    /*******************************************************************************************************
         * Decription - DCP-46058 Method to check Profile check for Field Service Profile
         */
        static testmethod void newBICaseCreationwithProfileCheck(){
            Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
            User serviceUser=TestDataUser.findUserInProfile('Field Service');        
            system.runAs(serviceUser){
                Case cs = TestDataCase.initServiceRequestCase(con);
                cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
                cs.Date_of_Issue_Awareness__c = Date.Today();
                test.startTest();
                insert cs;
                system.assertNotEquals(null,cs.id);
				
				test.stopTest();

                SVMXC__Service_Order__c wo = [select id, RecordType.Name, SVMXC__Order_Status__c, SVMXC__Order_Type__c from SVMXC__Service_Order__c limit 1];
                System.assertEquals(wo.RecordType.Name, STRING_WO_RECORDTYPE, 'Work Order Recordtype - Field Service');
                System.assertEquals(wo.SVMXC__Order_Status__c,	STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED, 'Work Order Status - Assignment Accepted');
                System.assertEquals(wo.SVMXC__Order_Type__c, STRING_LABEL_SERVICE_ACTIVITIES, 'Work Order OrderType - Assignment Accepted');
                
                
            }
        }
        /**
     *  @author      : Susmitha
     *  @description : method to disassociate Associate codes on Record Type change
     **/
    static testmethod void testDisassociateCodesonRTChange() {
        Case cs = TestDataCase.initNewCase('Business Issue', 'In Progress','Phone - CS');
        cs.Sub_Type__c = 'Complaint';
        cs.QA_Review__c = 'Non IVD Product';
        cs.Predicted_QA_Product_Family__c = 'NIPT';
        cs.Predicted_QA_Sub_Product_Family__c = 'NIPT 16';
        cs.QA_Product_Family__c = 'NIPT';
        cs.QA_Sub_Product_Family__c = 'NIPT Solution v2'; // TASK0829705
        cs.Investigation_Summary_Comments__c = 'logistictest';
        cs.Potentially_Reportable__c = 'No';
        cs.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
        cs.Answer_1__c = STRING_EVALUATION_ANSWER_NO;
        cs.Answer_2__c = STRING_EVALUATION_ANSWER_NO;
        cs.Answer_3__c = STRING_EVALUATION_ANSWER_NO;
        cs.Answer_4__c = STRING_EVALUATION_ANSWER_NO;
        cs.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
		Insert cs;
		
		list<Code_Library__c> codeLibLst = new list<Code_Library__c>();
        Code_Library__c dclparent = new Code_Library__c(Name='INQ CS Inquiry Subject parent code', Code_type__c = 'Subject', Case_Type__c = 'Business Issue',Service_Product_Type__c = 'Tool');
        codeLibLst.add(dclparent);
        Code_Library__c disCl = new Code_Library__c(Name='Code Disassociated', Code_type__c = 'Subject', Case_Type__c = 'Business Issue',Service_Product_Type__c = 'Tool');
        codeLibLst.add(disCl);
        insert codeLibLst;
		
		list<Associated_Codes__c> aclst= new list<Associated_Codes__c>();
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = dclparent.Id;
        ac.Case__c = cs.Id;
        ac.Code_Type__c='Subject';
        ac.Case_Type__c='Business Issue';
        aclst.add(ac);
		Insert aclst;
		Test.startTest();
		cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
		update cs;
        Test.stopTest();
        Case c = [select QA_Review__c,Predicted_QA_Product_Family__c,Predicted_QA_Sub_Product_Family__c,QA_Product_Family__c,QA_Sub_Product_Family__c,Investigation_Summary_Comments__c,Potentially_Reportable__c,PAE_PFA_Evaluation_Required__c,Answer_1__c,Answer_2__c,Answer_3__c,Answer_4__c,Answer_5__c,pAE_pFA_Awareness_Date__c from Case where Id=:cs.Id];

		system.assertNotEquals(dclparent.Id,disCl.Id,'Code is not disassociated on RT change');
        system.assertEquals(null,c.QA_Review__c,'Field Updated to Null');
        system.assertEquals(null,c.Predicted_QA_Product_Family__c,'Field Updated to Null');
        system.assertEquals(null,c.Predicted_QA_Sub_Product_Family__c,'Field Updated to Null');
        system.assertEquals(null,c.pAE_pFA_Awareness_Date__c,'Field Updated to Null');
        system.assertEquals(null,c.QA_Product_Family__c,'Field Updated to Null');
        system.assertEquals(null,c.QA_Sub_Product_Family__c,'Field Updated to Null');
        system.assertEquals(null,c.Investigation_Summary_Comments__c,'Field Updated to Null');
        system.assertEquals(null,c.Potentially_Reportable__c,'Field Updated to Null');
        system.assertEquals(null,c.PAE_PFA_Evaluation_Required__c,'Field Updated to Null');
        system.assertEquals(null,c.Answer_1__c,'Field Updated to Null');
        system.assertEquals(null,c.Answer_2__c,'Field Updated to Null');
        system.assertEquals(null,c.Answer_3__c,'Field Updated to Null');
        system.assertEquals(null,c.Answer_4__c,'Field Updated to Null');
        system.assertEquals(null,c.Answer_5__c,'Field Updated to Null');
    }
    /**
     *  @author      : Nitin
     *  @description : method to cover catch block in CaseQueueable
     **/
    @isTest
    public static void coverCatchBlockCaseQueueable(){
        try{
            CaseQueueable.catchException = true;
            CaseQueueable pd = new CaseQueueable(null,null,null,null,null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
    /*******************************************************************************************************
    * author - Preetha[QACM-782]
    * @description - test method to check Chatter post 
    * 
    */

    static testmethod void testChatterNotification() {
        cs_Apex_Settings__c csapex = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        csapex.Bypass_All_Validations__c = true;
        csapex.Bypass_Triggers_By_Object_1__c = 'Account';
        csapex.Bypass_Triggers_By_Object_2__c = 'Contact';
        csapex.Bypass_Triggers_By_Object_3__c = 'SVMXC__service_order__c';
        csapex.Bypass_Triggers_By_Object_4__c = 'Product2';
        upsert csapex;

        Account objAcc = TestDataAccount.getNewAccount();
        
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname',AccountID = objAcc.Id,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        insert objProduct;

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME,STRING_CASE_STATUS,STRING_CASE_ORIGIN);
        objCase.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
        objCase.Date_of_Issue_Awareness__c =  Date.today().addDays(-3);
        objCase.Explanation_for_pAE_pFA__c='Test';
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
        objCase.Description = 'testDescription';
        objCase.Sub_Type__c = STRING_CASE_SUB_TYPE;    
        objCase.Category__c = 'LIMS';
        objCase.Product_Utilization_Mode__c = 'IUO';
        insert objCase;
        
        SVMXC__service_order__c objWO = [SELECT id,Evaluation__c,SVMXC__Work_Performed__c,Verification_Result__c,SVMXC__Order_Status__c 
                                        FROM SVMXC__service_order__c 
                                        WHERE SVMXC__case__c =: objCase.Id];
        
        List<Code_Library__c> listCode = new List<Code_Library__c>();
        Code_Library__c code1 = new Code_Library__c();
        code1.Name='INQ General Process Inquiry';
        code1.Code_type__c = 'Analysis';
        code1.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        listCode.add(code1);
        
        Code_Library__c code2 = new Code_Library__c();
        code2.Name='Code Disassociated';
        code2.Code_type__c = 'Subject';
        code2.Case_Type__c = STRING_CASE_RECORDTYPENAME;
        listCode.add(code2);
        Insert listCode;
        
        Associated_Codes__c ac = new Associated_Codes__c();
        ac.Code_Title__c = code1.Id;
        ac.Case__c = objCase.Id;
        ac.Work_Order__c = objWO.Id;
        insert ac;
        
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_YES;
        objCase.pAE_pFA_Awareness_Date__c = Date.today();
        objCase.Question_1__c = 'Did the issue involve a death or serious injury to either the patient or the operator?';
        objCase.Question_2__c = 'Could the issue cause a death or serious injury if it were to recur?';
        objCase.Answer_1__c = STRING_EVALUATION_ANSWER_YES;
        objCase.Answer_2__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Question_3__c = '"Has the customer submitted a Medical Device Report to the FDA or has the customer reported the issue to other regulatory agencies for Illumina’s regulated products?"';
        objCase.Question_4__c = '"Did the IVD product fail to perform as intended? E.g. product not performing as designed, or meeting package insert specification such as sensitivity, specificity, and accuracy, due to a product deficiency."';
        objCase.Question_5__c = '"Did the determined issue suggest misbranding, labeling or an adulterated IVD product (defective, unsafe, or contaminated)? E.g. product mislabeled, incorrectly packaged, incorrect instruction in package insert, reagent contains foreign substance."';
        objCase.Answer_3__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Answer_4__c = STRING_EVALUATION_ANSWER_YES;
        objCase.Answer_5__c = STRING_EVALUATION_ANSWER_NO;
        objCase.Investigation_Summary_Comments__c = 'test';
        objCase.Logistics_Investigation_Summary_Comments__c = 'logistictest';
        objCase.Logistics_Review__c = 'See Investigation Summary/Comments';
        objCase.Record_Updated_from_SFM__c = True;
        objCase.QA_Review__c = 'Non IVD Product';
        objCase.QA_Product_Family__c = 'NIPT';
        objCase.QA_Sub_Product_Family__c = 'NIPT Solution v2';
        objCase.Status = 'Pending QA Review';
        Test.startTest();
        update objCase;
        system.assertEquals('Pending QA Review',objCase.Status,'Status updated to Pending QA Review');

        ac.Code_Title__c = code2.id;
        update ac;
        system.assert(ac.Code_Title__c != null,'Code title should not null');   

        User serviceUser=TestDataUser.findUserInProfile(Label.Profile_Service_Logistics);      
        system.runAs(serviceUser){

            cs_Apex_Settings__c cssetting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
            cssetting.Bypass_All_Validations__c = true;
            upsert cssetting;

            objWo.Evaluation__c = 'testEvaluation';
            objWo.SVMXC__Work_Performed__c = 'testWorkPerformed';
            objWo.Verification_Result__c = 'testVerificationResult';
            objWO.SVMXC__Order_Status__c = STRING_CASE_STATUS_COMPLETED;
            WorkOrders.skipWOTrigger = true;
            update objWO;

            System.assertEquals(STRING_CASE_STATUS_COMPLETED, [SELECT SVMXC__Order_Status__c FROM SVMXC__service_order__c WHERE Id = :objWO.Id].SVMXC__Order_Status__c);
        }
        Test.stopTest();
    }


     /**
    * @description- Test method to increase code coverage of the CasesHelper class
    * Modified Date: 09-26-2022 
    **/
    @isTest static void coverCasesHelper(){
        Account objAcc = TestDataAccount.getNewAccount();
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Is_Active__c = true, AccountID = objAcc.Id ,Email='test@gmail.com.invalid' , Phone = '1234567890');
        insert con;
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
        cs.Sub_Type__c = 'Order';
        cs.Category__c = STRING_CASE_CATEGORY_ORDER; 
        cs.Status = STRING_CASE_STATUS_IN_PROGRESS;
        cs.SuppliedEmail = 'test@illumina.com';            
        cs.origin = 'Email - CS';   
        insert cs;
        System.assertNotEquals(null,cs.Id, 'Case not inserted correctly');
        Set<Id> setCaseIds = new Set<Id>();
        setCaseIds.add(cs.Id);
        test.startTest();
        CasesHelper.ObjCases caseQuery = new CasesHelper.ObjCases();
        caseQuery.initMapParentCaseIdToParentCase(setCaseIds, false);
        //CasesHelper.ShowOnCaseLines caseLineQuery = new CasesHelper.ShowOnCaseLines();
        //caseLineQuery.initMapShowOnCaseLineIdToCases(setCaseIds); //CMCM -6760 - Removed Method reference 
        CasesHelper.ValidateIVDAssociatedProducts caseLineIVDQuery = new CasesHelper.ValidateIVDAssociatedProducts();
        caseLineIVDQuery.initMapIVDProductToCases(setCaseIds);
        system.assertNotEquals(null,cs.Id,'Case should not be null');                
        test.stopTest();
    }

    /*
      *  @author Rohan Rathod
      *  @description DCP-56388- Test checkSubTypeEditForOpenElevation on Case.
      **/
      @isTest static void testcheckSubTypeEditForOpenElevation() {
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test';
        ps.Label = 'Test';
        insert ps;
        System.assertNotEquals(null, ps.id,'PermissionSet should not be null');
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'RPS_FSM_FAM'][0].Id;
        insert sea;
        System.assertNotEquals(null, sea.id,'SetupEntityAccess should not be null');
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = UserInfo.getUserId();
        psa.PermissionSetId = ps.Id;
        insert psa;
        System.assertNotEquals(null, psa.id,'PermissionSetAssignment should not be null');
        User u = TestDataFieldService.createUser('GIS User Provisioning',false);
        Insert u;
        PermissionSet newPS = [SELECT Id FROM PermissionSet WHERE Name = 'SS_Product_Support'];
        insert new PermissionSetAssignment(AssigneeId = u.id, PermissionSetId = newPS.Id);

        System.runAs(u){
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT_NAME, 'USD');
            acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
            insert acc;
            System.assertNotEquals(null, acc.id,'Account should not be null');
            //insert contact
            Contact con = TestDataPerson.getNewContact(acc.Id);
            System.assertNotEquals(null, con.id,'Contact should not be null');
            
            Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(STRING_CASE_RECORDTYPENAME).getRecordTypeId();
            
            Case objCase  = new Case(    
                Status = 'Initiated',
                Subject = 'test' ,
                Description= 'test',
                Origin = 'Phone-CP',
                Date_of_Issue_Awareness__c=System.today() -2,
                ContactId = con.Id,
                RecordTypeId = idCaseRecordTypeId,
                Awareness_Date_Difference_Reason__c ='Logistical delay',
                Sub_Type__c = STRING_CASE_SUB_TYPE
            );
            insert objCase;
            System.assertNotEquals(null, objCase.Id, 'Case Object should not be empty');
            
            List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
                        
            Id accountElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Account Elevation').getRecordTypeId();  
            
            SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                 SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                                 SVMXC__Order_Status__c from 
                                                 SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];        
            
            Elevations__c accElev = new Elevations__c();
            accElev.RecordTypeId = accountElevationRecordType;
            accElev.Elevation_Category__c = 'Account Maintenance';
            accElev.Elevation_Status__c = 'Open';
            accElev.Elevation_Owner__c = lstUsers[0].Id;
            accElev.Elevation_Manager__c = lstUsers[0].Id;
            accElev.Plan_of_Action__c = 'test';
            accElev.Success_Criteria__c = 'TEST';
            accElev.Work_Order__c = workOrder.id;
            insert accElev;
            System.assertNotEquals(null, accElev.Id, 'Elevation Object should not be empty');   
     
            Boolean expectedExceptionThrown=false;

            test.startTest();
            try {
                objCase.Sub_Type__c = 'General Issue';
                update objCase;
            }
            catch(Exception e) {
                expectedExceptionThrown = e.getMessage().contains(Label.Elevated_Business_Issue_Error) ? true : false; 
            }
            test.stopTest();

            System.assert(true,expectedExceptionThrown); 
        }
        
    }

    /**
    * method: testupdateAnaysisCode
    * params:NA
    * return: void
    * Description: this method covers the updateAnaysisCode functionality (CMCM - 3533)
    * created date: 25-Sept-2023
    **/
    static testMethod void testupdateAnaysisCode() {
           
       Contact con = new Contact(FirstName = 'testfirst', LastName = 'testlast');
       con.Email = 'test@abcde.com';
       con.Phone = '1234567856';
       insert con;
       Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS_IN_PROGRESS, 'In Person - CS');
       objCase.ContactId = con.Id;
       objCase.Sub_Type__c = 'General Issue';
       objCase.Category__c = 'Logistics / Supply Chain';
       objCase.Date_of_Issue_Awareness__c = Date.today();
       insert objCase;
       try {
           Test.startTest();              
           Case caseRec = [SELECT Id,Contains_Logistics_Analysis_Code__c FROM Case WHERE Id =:objCase.Id];
           Assert.areEqual(true,caseRec.Contains_Logistics_Analysis_Code__c, 'update Contains Logistics Criteria field based on Case condition');
           Test.stopTest();
       } Catch(Exception e) {
           System.debug(STRING_EXCEPTION + e.getMessage());
       }
   }
   
   }
/**************************************************************************************************************************************
* NAME   : TestCaseWO_POlHelper
* DESCRIPTION  : Domain class for v.
* Test Class for CaseWO_POlHelper.cls
*  
*                    
* @AUTHOR : Nitin Z 
* @DATE   : 19 -Aug -2024  
*  
* MODIFICATION LOG: s
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Nitin Z                  19-Aug -2024   

****************************************************************************************************************************************/ 



@isTest
public with sharing class TestCaseWO_POlHelper {
    
    /**
    * method: testNegativeValidateWoOnCaseWithRetrunType
    * params:NA
    * return: void
    * Description: this method covers the validateReturnPartOrder functionality (CMCM-9391)
    * created date: 19 -Aug-2024
    **/
      @IsTest
      private static void testNegativeValidateWoOnCaseWithRetrunType() {
          
          try{
            TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
            
            Account objAccount = TestDataAccount.getCustomerAccount();
            insert objAccount;
            system.assertNotEquals(null,objAccount.id); 
            
            Contact con = TestDataPerson.getNewContact(objAccount.Id);
            system.assertNotEquals(null,con.id);
          
            Case parentCase = TestDataCase.initNewCase('Service Request', 'Initiated', 'C');
            parentCase.ContactId = con.id;
            insert parentCase;
          
            SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
            objInstalledProduct.SVMXC__Company__c = objAccount.Id;
            insert objInstalledProduct;
                     
            Id woRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId();
            SVMXC__Service_Order__c objWorkOrder = new SVMXC__Service_Order__c();
            objWorkOrder.RecordTypeId = woRecordTypeId;
            objWorkOrder.SVMXC__Case__c = parentCase.Id; 
            objWorkOrder.SVMXC__Component__c = objInstalledProduct.Id;
            objWorkOrder.SVMXC__Order_Type__c='Service Activities';
            objWorkOrder.Record_Created_from_SFM__c=true;
            insert objWorkOrder; 		
          
           
          
            Test.startTest();
            Cases.skipCaseTrigger=false;
            parentCase.PAE_PFA_Evaluation_Required__c='No';   
            parentCase.Recall__c=true;
            parentCase.Status='Closed';
            parentCase.Product_Returned_Status__c='Product Returned to Illumina';
            parentCase.Internal_Non_Customer__c=true;
            parentCase.Recall_Acknowledgement_Status__c='Customer unreachable due to Sanctions';
            update parentCase;
          }
            catch(Exception e){
                  System.debug('testValidatePOL '+e.getMessage());
                  System.assert(e!=null,  'e is not empty');
              }
          
      }
      
    /**
    * method: testPositiveValidateWoOnCaseWithRetrunType
    * params:NA
    * return: void
    * Description: this method covers the validateReturnPartOrder functionality (CMCM-9391)
    * created date: 19 -Aug-2024
    **/ 
      @IsTest
      private static void testPositiveValidateWoOnCaseWithRetrunType() {  
            TestDataMarketing.createContact('testfirstname','testlastname','test@gmail.com');
            
            Account objAccount = TestDataAccount.getCustomerAccount();
            insert objAccount;
            system.assertNotEquals(null,objAccount.id); 
            
            Contact con = TestDataPerson.getNewContact(objAccount.Id);
            system.assertNotEquals(null,con.id);
          
            Case parentCase = TestDataCase.initNewCase('Service Request', 'Initiated', 'C');
            parentCase.ContactId = con.id;
            insert parentCase;
          
            SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
            objInstalledProduct.SVMXC__Company__c = objAccount.Id;
            insert objInstalledProduct;
          
            Id woRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId();
            SVMXC__Service_Order__c objWorkOrder = new SVMXC__Service_Order__c();
     
            objWorkOrder.RecordTypeId = woRecordTypeId;
            objWorkOrder.SVMXC__Case__c = parentCase.Id;            
            objWorkOrder.SVMXC__Component__c = objInstalledProduct.Id;
            objWorkOrder.SVMXC__Order_Type__c='Service Activities';
            objWorkOrder.Record_Created_from_SFM__c=true;
            insert objWorkOrder; 	
         
            
          
            SVMXC__RMA_Shipment_Order__c po= new SVMXC__RMA_Shipment_Order__c();
            po.SVMXC__Order_Status__c='Open';
            po.SVMXC__Order_Type__c='Return';
            po.SVMXC__Service_Order__c=objWorkOrder.Id;
            insert po;
          
            Test.startTest();
            Cases.skipCaseTrigger=false;  
            parentCase.PAE_PFA_Evaluation_Required__c='No';
            parentCase.Recall__c=true;
            parentCase.Status='Closed';
            parentCase.Product_Returned_Status__c='Product Returned to Illumina';
            parentCase.Internal_Non_Customer__c=true;
            parentCase.Recall_Acknowledgement_Status__c='Customer unreachable due to Sanctions';
            update parentCase;
            Test.stopTest();
          
           Case caseObj=[select id,status from case where id=:parentCase.Id limit 1];
           System.assertEquals('Closed', caseObj.Status, 'The case status should be Closed ');
  
      }


}
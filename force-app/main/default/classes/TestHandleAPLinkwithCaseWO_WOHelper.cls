//TestHandleAPLinkwithCaseWO_WOHelper 
/*
* @ author       : Siddartha Reddy Kalam
* @ date         : 20-March-2024
* @ Description  : Test class for HandleAPLinkwithCaseWO_WOHelper class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                              Date                               Description
* Siddartha Reddy Kalam                  20-March-2024                        Initial version - CMCM-5782
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestHandleAPLinkwithCaseWO_WOHelper {
	
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    
    /**
    * method : initializeTestData
    * Description: method is to create test data.
    * params: NA
    * return: void
    * author: Siddartha Reddy Kalam
    **/
    @testSetup
    public static void initializeTestData() {
        Feature.setMockFeatureFlag('ServiceAssociatedProducts', true);
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        setting.Bypass_Triggers_By_Object_1__c = 'Associated_Product__c';
        setting.Bypass_Triggers_By_Object_2__c = 'Account';
        setting.Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c';
        setting.Bypass_Triggers_By_Object_4__c = 'Contact';
        upsert setting;
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c = 'Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null,'Account got created');

        //insert Contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact got created');
            
        //insert Case
        Case cs = TestDataCase.initServiceRequestCase(con);
        cs.Status = 'Initiated';
        insert cs;
        System.assert(cs.Id != null, 'Case got created');
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = acc.Id;
        insert objInstalledProduct; 
        
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c = 'Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test';
        wo.SVMXC__Contact__c = con.id;
        wo.Record_Created_from_SFM__c = true;
        AssociatedProduct.isTestRunning = TRUE; // added by dhairya shah
        insert wo;

        List<Associated_Product__c> assocProducts = new List<Associated_Product__c>{
            new Associated_Product__c(Case__c = cs.Id, Installed_Product__c = objInstalledProduct.Id, Account__c = acc.id),
            new Associated_Product__c(Is_Primary__c=true,Work_Order__c = wo.Id, Installed_Product__c = objInstalledProduct.Id, Account__c = acc.id),
            new Associated_Product__c(Work_Order__c = wo.Id, Installed_Product__c = objInstalledProduct.Id, Account__c = acc.id)
        };
       insert assocProducts; 
    }
    
    /**
    * method : initializeTestData
    * Description: method is to insert WO with case to link associated products related to case with WO.
    * params: NA
    * return: void
    * author: Siddartha Reddy Kalam
    **/
    @IsTest
    public static void testupdateAPsfromCaseonWO(){
        Test.startTest();
        Case cs1 = [select id from case where Status ='Initiated' Limit 1];
        System.assert(cs1.Id != null, 'fetched Case id');
        List<Associated_Product__c> insertedassocProducts = [SELECT Id FROM Associated_Product__c WHERE Case__c =: cs1.Id Limit 3];
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c='Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test';
        wo.SVMXC__Case__c = cs1.Id;
        wo.Record_Created_from_SFM__c=true;
        try{
            AssociatedProduct.isTestRunning = TRUE;
            insert wo;
        }catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.AssociatedProduct_AccountContactRelation_Error),'Error');
        }
        SVMXC__Service_Order__c wo1 = [select id from SVMXC__Service_Order__c where id=:wo.id Limit 1];
        System.assert(wo1.Id != null, 'Work order got created');
        List<Associated_Product__c> updatedProducts = [SELECT Id FROM Associated_Product__c WHERE Work_Order__c =: wo1.Id Limit 3];
        System.assertEquals(updatedProducts.size(), insertedassocProducts.size(), 'All records that are inserted on case updated successfully');
	    Test.stopTest();         
    }

    /**
    * method : initializeTestData
    * Description: method is to update WO with case if case and WO both has associated products with primary record then throw error.
    * params: NA
    * return: void
    * author: Siddartha Reddy Kalam
    **/
    @IsTest
    public static void testcheckAPhasIsPrimary(){

        Case cs1 = [select id from case where Status ='Initiated' Limit 1];
        System.assert(cs1.Id != null, 'fetched Case id');
        SVMXC__Service_Order__c insertedwo = [select id from SVMXC__Service_Order__c Limit 1];
        System.assert(insertedwo.Id != null, 'fetched WO id');

        insertedwo.SVMXC__Case__c = cs1.Id;
        try{
            Test.startTest();
            update insertedwo;
            Test.stopTest(); 
        }catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.CheckAPofCaseWOHasIsprimary),'Error');
        }
    }

    /**
    * method : initializeTestData
    * Description: method is to update WO with case to link associated products related to case with WO and WO's ap records with case.
    * params: NA
    * return: void
    * author: Siddartha Reddy Kalam
    **/
    @IsTest
    public static void testverifyCaseIsChanged(){
        Case cs1 = [select id from case where Status ='Initiated' Limit 1];
        System.assert(cs1.Id != null, 'fetched Case id');

        List<Associated_Product__c> listupdateassocProducts = new List<Associated_Product__c>();
        List<Associated_Product__c> insertedassocProducts = [SELECT Id FROM Associated_Product__c WHERE Is_Primary__c = true Limit 1];
        for(Associated_Product__c objAP: insertedassocProducts){
            objAP.Is_Primary__c = false;
            listupdateassocProducts.add(objAP);
        }
        update listupdateassocProducts;
        SVMXC__Service_Order__c insertedwo = [select id from SVMXC__Service_Order__c Limit 1];
        System.assert(insertedwo.Id != null, 'fetched WO id');
        insertedwo.SVMXC__Case__c = cs1.Id;
        Test.startTest();
        AssociatedProduct.isTestRunning = TRUE; // added by dhairya shah
        update insertedwo;
        Test.stopTest(); 
        SVMXC__Service_Order__c wo1 = [select id from SVMXC__Service_Order__c where id =: insertedwo.Id Limit 1];
        System.assert(wo1.Id != null, 'Work order got created');
        List<Associated_Product__c> updatedProducts = [SELECT Id FROM Associated_Product__c WHERE Work_Order__c =: wo1.Id and Case__c =:cs1.Id Limit 1];
        System.assertEquals(updatedProducts.size(), listupdateassocProducts.size(), 'All records that are inserted on case/WO updated successfully');
    }
    
}
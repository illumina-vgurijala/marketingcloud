/***************************************************************************************************************************************
 * NAME   : TestAssociatedProductsHelper
 * DESCRIPTION  : TestClass for AssociatedProductsHelper 
 * @AUTHOR : Nitin Zagade 
 * @DATE   : 24-Jun -2024 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Nitin Zagade            24-Jun -2024             Initial Version
 ****************************************************************************************************************************************/ 
@isTest
public with sharing class TestAssociatedProductsHelper {

    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_LOCATION = 'Test Location';
    public static final string STRING_STREET = 'Test Street';
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    

     /*
   * @Description- test setup method
   */
  @testSetup
  static void setupTestData() {
      Feature.setMockFeatureFlag('ServiceAssociatedProducts', true);

      //ACCOUNT DML
      List<Account> acc = new List<Account>();
      Account objAccount = TestDataAccount.getAccount('Test Account 1', 'USD');
      objAccount.Account_Group__c = 'Distributor';
      objAccount.Clinical_Type__c = 'Clinical';
      acc.add(objAccount);

      Account objAccount1 = TestDataAccount.getAccount('Test Account 2', 'USD');
      objAccount1.Account_Group__c = 'Distributor';
      objAccount1.Clinical_Type__c = 'Clinical';
      acc.add(objAccount1);

      INSERT acc;
      
      //CONTACT DML
      Contact con = TestDataContact.getNewContact(objAccount);

      //PRODUCT DML
      Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
      objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
      objProduct.Regulatory_Type__c = 'DX';
      objProduct.Source_System__c = 'SAP';
      INSERT objProduct;

      //SUBSCRIPTION DML
      SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
      objServiceContract.ERP_Contract_Type__c = 'Software (ZWS)';
      INSERT objServiceContract;

      //LOCATION DML
      SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
      INSERT objLocation;

      //INSTALLEDPRODUCT DML
      SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
      objInstalledProduct.SVMXC__Company__c = objAccount.Id;
      objInstalledProduct.SVMXC__Site__c = objLocation.id;
      objInstalledProduct.SVMXC__Product__c = objProduct.id;
      objInstalledProduct.SVMXC__Serial_Lot_Number__c = 'test123';
      INSERT objInstalledProduct;

      // Insert Service Orders
      SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
      wo.Evaluation__c = 'Test';
      wo.SVMXC__Work_Performed__c = 'Test';
      wo.Verification_Result__c = 'Test';
      wo.SVMXC__Contact__c = con.id;
      AssociatedProduct.isTestRunning = TRUE; // added by dhairya shah
      INSERT wo;

      Case objCase = TestDataCase.initServiceRequestCase(con);
      objCase.Status = 'Initiated';
      INSERT objCase;
  }


     /**
     *  CMCM-8106
     *  @author : Nitin Zagade
     *  @description - it test if IVD_Product_Identifier_Additional_Prod__c is changed to the true when product is inserted 
     **/
    @isTest
    static void testUpdateIVDIdentifierOnCase() {

        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];   
        Test.startTest();
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1];
        
        List<Associated_Product__c> apcList = new List<Associated_Product__c>();
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(objCase.Id, wo.Id, objProduct.Id, null, null);
        apc.Is_Primary__c = false;
        apc.Product_Lot_Number__c = '7563833';
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = false;
        apcList.add(apc);
        AssociatedProduct.isTestRunning = TRUE;
            try{
                INSERT apcList;
                objCase = [SELECT Id,IVD_Product_Identifier_Additional_Prod__c FROM Case  where id=: apc.case__c  LIMIT 1];
                System.assert(true, objCase.IVD_Product_Identifier_Additional_Prod__c);
            }
            catch(Exception e){
                system.debug('Exception->'+e);            
            }
       Test.stoptest();
    }

     /**
     *  CMCM-8106
     *  @author : Nitin Zagade
     *  @description - it test if IVD_Product_Identifier_Additional_Prod__c is changed to false  when product is delete 
     **/
    @isTest
    static void testUpdateCaseWithAdditionalIVDFalse() {

        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];   
     
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1];
        
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(objCase.Id, wo.Id, objProduct.Id, null, null);
        apc.Is_Primary__c = false;
        apc.Product_Lot_Number__c = '7563833';
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = false;
        AssociatedProduct.isTestRunning = TRUE;
        INSERT  apc;

        Test.startTest();
        DELETE  apc;
        Test.stoptest();

        objCase = [SELECT Id,IVD_Product_Identifier_Additional_Prod__c FROM Case  where id=: objCase.id  LIMIT 1];
        System.debug('IVD_Product_Identifier_Additional_Prod__c '+objCase.IVD_Product_Identifier_Additional_Prod__c);
        Assert.areEqual(false , objCase.IVD_Product_Identifier_Additional_Prod__c , 'IVD Product Identifier Additional Prod not set to false');  
    }

      /**
     *  CMCM-8106
     *  @author : Nitin Zagade
     *  @description - to test if  IVD_Product_Identifier_Additional_Prod__c on the Case is changed when Product on the AP is changed  
     **/

    @isTest
    static void testUpdateAPProductChange() {

        Product2 objProduct2 = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct2.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct2.Regulatory_Type__c = 'RUO';
        objProduct2.Source_System__c = 'SAP';
        INSERT objProduct2;

        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];   
     
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1];
        
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(objCase.Id, wo.Id, objProduct.Id, null, null);
        apc.Is_Primary__c = false;
        apc.Product_Lot_Number__c = '7563833';
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = false;
        AssociatedProduct.isTestRunning = TRUE;
      

        Test.startTest();
        INSERT  apc;
        Test.stoptest();

        objCase = [SELECT Id,IVD_Product_Identifier_Additional_Prod__c FROM Case  where id=: objCase.id  LIMIT 1];
        Assert.areEqual(true , objCase.IVD_Product_Identifier_Additional_Prod__c , 'IVD Product Identifier Additional Prod not set to true');  

        apc.Product__c=objProduct2.Id;
        update apc;
        apc = [SELECT Id,IVD_Product_Identifier__c FROM Associated_Product__c  where id=: apc.id  LIMIT 1];
        System.debug('IVD_Product_Identifier__c '+apc.IVD_Product_Identifier__c);


        objCase = [SELECT Id,IVD_Product_Identifier_Additional_Prod__c FROM Case  where id=: objCase.id  LIMIT 1];
        System.debug('IVD_Product_Identifier_Additional_Prod__c '+objCase.IVD_Product_Identifier_Additional_Prod__c);
        Assert.areEqual(false , objCase.IVD_Product_Identifier_Additional_Prod__c , 'IVD Product Identifier Additional Prod not set to false');  
    
    }

   
}
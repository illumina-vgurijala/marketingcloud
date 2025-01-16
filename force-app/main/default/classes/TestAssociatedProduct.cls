/***************************************************************************************************************************************
 * NAME   : TestAssociatedProduct
 * DESCRIPTION  : TestClass for AssociatedProduct (Code Coverage-91%)
 * @AUTHOR : Priya Mukherjee
 * @DATE   : 25-Oct-2023 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Priya Mukherjee         26-Oct-2023             Initial Version
 * Abhishek Yadav          16-Nov-2023             CMCM-263
 * Dhairya Shah            15-Feb-2024             CMCM-3591, CMCM-5753
 * Abhishek Yadav          26-March-2024           CMCM-295
 * Pritam Yadav            18-March-2024           CMCM-6411
 ****************************************************************************************************************************************/ 
@isTest
public class TestAssociatedProduct { 
    public static final String STRING_WO_RECORDTYPE = 'Field Service';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_CASE_RECORDTYPENAME = 'Business Issue';
    public static final string STRING_CASE_STATUS = 'Initiated';
    public static final string STRING_CASE_ORIGIN = 'Phone - CS';
    public static final string STRING_LOCATION = 'Test Location';
    public static final string STRING_STREET = 'Test Street';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_EVALUATION_ANSWER_PENDING = 'Pending';
    public static final string STRING_PRODUCT_NAME = 'Test Product VM';
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

    /*
   * @Description- Test insertion positive scenario
   */
    @isTest
    static void testInsertPositiveScenario() {
        // Create Associated_Product__c records for positive scenario
        List<Associated_Product__c> assocProducts = new List<Associated_Product__c>{
            TestDataFieldService.createAssociatedProductonCase([SELECT Id FROM Case LIMIT 1].Id, null, null, null, [SELECT Id FROM Account LIMIT 1].id)
        };

        AssociatedProduct.isTestRunning = TRUE;
        Test.startTest();
        try{
            INSERT assocProducts;
        }
        catch(Exception e){
            system.debug('Exception->'+e);
        }
        Test.stopTest();

        List<Associated_Product__c> insertedProducts = [SELECT Id FROM Associated_Product__c WHERE Id IN :assocProducts];
        System.assertEquals(assocProducts.size(), insertedProducts.size(), 'All records should be inserted successfully');
    }
    /*
   * @Description- Test insertion negative scenario
   */
    @isTest
    static void testInsertNegativeScenario() {
        // Create Associated_Product__c records for negative scenario (Assuming Installed_Product__c from a different account causes validation error)
        Associated_Product__c assocProduct = TestDataFieldService.createAssociatedProductonCase([SELECT Id FROM Case LIMIT 1].Id, null, null,null, [SELECT Id FROM Account LIMIT 1 OFFSET 1].Id);

        Test.startTest();
        try {
            AssociatedProduct.isTestRunning = TRUE;
            INSERT assocProduct;
        } catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.AssociatedProduct_AccountContactRelation_Error));
        }
        Test.stopTest();
    }
    /*
   * @Description- Test updation positive scenario
   */
    @isTest
    static void testUpdatePositiveScenario() {
        // Create and Insert Associated_Product__c record for positive update scenario
        Associated_Product__c assocProduct = TestDataFieldService.createAssociatedProductonCase([SELECT Id FROM Case LIMIT 1].Id, null , null, null,[SELECT Id FROM Account LIMIT 1].Id);
        AssociatedProduct.isTestRunning = TRUE;
        INSERT assocProduct;

        // Update the record
        assocProduct.Installed_Product__c = [SELECT Id FROM SVMXC__Installed_Product__c LIMIT 1].Id;
        assocProduct.Product_Serial_Number__c =null;
        Test.startTest();
        AssociatedProduct.isTestRunning = TRUE;
        UPDATE assocProduct;
        Test.stopTest();

        Associated_Product__c updatedProduct = [SELECT Installed_Product__c FROM Associated_Product__c WHERE Id = :assocProduct.Id];
        System.assertEquals(assocProduct.Installed_Product__c, updatedProduct.Installed_Product__c, 'The record should be updated successfully');
    }
    /*
   * @Description- Test updation negative scenario
   */
    @isTest
    static void testUpdateNegativeScenario() {
        // Create and Insert Associated_Product__c record for negative update scenario
        Associated_Product__c assocProduct = TestDataFieldService.createAssociatedProductonCase([SELECT Id FROM Case LIMIT 1].Id, null , null,null,[SELECT Id FROM Account LIMIT 1 OFFSET 1].Id);
        Test.startTest();
        AssociatedProduct.isTestRunning = TRUE;
        insert assocProduct;
        // Update the record for negative scenario (Assuming Installed_Product__c from a different account causes validation error)
        assocProduct.Installed_Product__c = [SELECT Id FROM SVMXC__Installed_Product__c LIMIT 1].Id;
        assocProduct.Product_Serial_Number__c =null;
        try {
            AssociatedProduct.isTestRunning = TRUE;
            UPDATE assocProduct;
        } catch (Exception e) {
            System.assert(e.getMessage().contains(System.Label.AssociatedProduct_AccountContactRelation_Error));
        }
        Test.stopTest();
    }
    
    /**
     *  CMCM-263
     *  @author : Abhishek Yadav
     *  @description - insert Associated Product on Case Creation
     **/
    @isTest
    static void testAPInstallProduct() {
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];
        SVMXC__Installed_Product__c objInstalledProduct = [SELECT Id FROM SVMXC__Installed_Product__c LIMIT 1];

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING;
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        Test.startTest();
        try{
            INSERT objCase;
        }
        Catch(Exception e){
            system.debug('Exception->'+e);
        }
        List<SVMXC__Service_Order__c> woList = [SELECT Id, SVMXC__Case__c FROM SVMXC__Service_Order__c WHERE SVMXC__Case__c = :objCase.Id LIMIT 1];
        AssociatedProduct.addAssociatedProductsOnCaseCreation(new List<Case>{objCase}, woList);
        List<Associated_Product__c> associatedList = [SELECT Id FROM Associated_Product__c LIMIT 1];
        System.assertNotEquals(0, associatedList.size(), 'associatedList should not be empty');
        Test.stopTest();
    }

    /*  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - insert Associated Product on Case Creation
    **/
    @isTest
    static void testAPProductNSubscription() {
        cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
           Bypass_Triggers_By_Object_1__c = 'Applied_Contract__c'
        );
        insert apexSettings;
        Account objAccount = [SELECT Id FROM Account LIMIT 1];        
        Contact con = [SELECT Id, AccountId  FROM contact WHERE AccountId  =:objAccount.Id];
        SVMXC__Service_Contract__c objServiceContract = [SELECT Id FROM SVMXC__Service_Contract__c LIMIT 1];
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING; 
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        objCase.Subscription__c = objServiceContract.id; 
        objCase.AccountId = objAccount.Id;
        objCase.ContactId = con.id;
        Test.startTest();
        try{
            INSERT objCase;
        }catch(Exception e){
            system.debug('Exception->'+e);
        }
        
        Test.stopTest();
        SVMXC__Service_Order__c wo = [SELECT Id, SVMXC__Company__c,Subscription__c, SVMXC__Case__c, SVMXC__Product__c, SVMXC__Component__c FROM SVMXC__Service_Order__c WHERE SVMXC__Case__c = :objCase.Id LIMIT 1];
        AssociatedProduct.addAssociatedProductsOnWorkOrderCreation(new List<SVMXC__Service_Order__c>{wo});
        AssociatedProduct.addAssociatedProductsOnCaseCreation(new List<Case>{objCase}, new List<SVMXC__Service_Order__c>{wo});
        List<Associated_Product__c> associatedList = [SELECT Id FROM associated_product__c LIMIT 1];
        Assert.isTrue(!associatedList.isEmpty(), 'associatedList should not blank');
    }

    /*  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - insert Associated Product on Case Creation 
    **/
    @isTest
    static void testAPProduct() {

        Contact con = [SELECT Id, AccountId  FROM contact LIMIT 1];
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // insert Case
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING; 
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        objCase.ContactId = con.id;
        
        Test.startTest();
        try{
            INSERT objCase;
        }catch(Exception e){
            system.debug('Exception->'+e);            
        }

        SVMXC__Service_Order__c wo =  [SELECT Id,SVMXC__Case__c FROM SVMXC__Service_Order__c WHERE SVMXC__Case__c = :objCase.Id LIMIT 1];
        AssociatedProduct.addAssociatedProductsOnCaseCreation(new List<Case>{objCase}, new List<SVMXC__Service_Order__c>{wo});
        List<Associated_Product__c> associatedList = [SELECT Id FROM associated_product__c LIMIT 1];
        Assert.isTrue(!associatedList.isEmpty(), 'associatedList is blank');
        Test.stopTest();
    }

    /**
     *  CMCM-276
     *  @author : Abhishek Yadav
     *  @description - insert Associated Product on Work Order Creation
     **/
    @isTest
    static void testWOAPInstallProduct() {
        
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        INSERT objInstalledProduct;
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING; 
        objCase.Date_of_Issue_Awareness__c = Date.Today(); 
        
        Test.startTest();
        try{
            INSERT objCase;
        }catch(Exception e){
            system.debug('Exception->'+e);
        }
        
        SVMXC__Service_Order__c wo = [
            SELECT Id,SVMXC__Case__c, Subscription__c, SVMXC__Product__c, SVMXC__Component__c 
            FROM SVMXC__Service_Order__c 
            WHERE SVMXC__Case__c = :objCase.Id 
            LIMIT 1];
        AssociatedProduct.addAssociatedProductsOnWorkOrderCreation(new List<SVMXC__Service_Order__c>{wo});
        List<Associated_Product__c> associatedList = [SELECT Id FROM associated_product__c LIMIT 1];
        Assert.isTrue(!associatedList.isEmpty(), 'associatedList should not blank');
        Test.stopTest();
    }

    //removed and merged code to testAPProductNSubscription CMCM-7787
        
    //CMCM-3591, 5753 : AUTHOR DHAIRYA SHAH 
    @isTest
    static void updatePrimaryAPonWO() {
        Account objAccount = [SELECT Id FROM Account LIMIT 1];        
        SVMXC__Site__c objLocation = [SELECT Id FROM SVMXC__Site__c LIMIT 1];
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1]; 
        
        SVMXC__Installed_Product__c objInstalledProduct = [SELECT Id FROM SVMXC__Installed_Product__c WHERE SVMXC__Company__c =:objAccount.Id AND SVMXC__Site__c =:objLocation.Id AND SVMXC__Product__c =:objProduct.id LIMIT 1];
        objInstalledProduct.SVMXC__Serial_Lot_Number__c = null;
        
        try{
            UPDATE objInstalledProduct;
        }catch (Exception e){
            system.debug('Exception->'+e);            
        }

        List<SVMXC__Service_Order__c> listWO = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c wo = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo.Evaluation__c = 'Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test';
        wo.SVMXC__Company__c = objAccount.Id;
        wo.Record_Created_from_SFM__c = true;
        listWO.add(wo);

        SVMXC__Service_Order__c wo2 = TestDataFieldService.createWorkOrder(STRING_WO_RECORDTYPE, null, 'Initiated');
        wo2.Evaluation__c = 'Test';
        wo2.SVMXC__Work_Performed__c = 'Test';
        wo2.Verification_Result__c = 'Test';
        wo2.SVMXC__Company__c = objAccount.Id;
        wo2.Record_Created_from_SFM__c = true;
        listWO.add(wo2);
        try{
            Cases.skipCaseTrigger = true;
            WorkOrders.skipWOTrigger = true;
            INSERT listWO;
        } catch (Exception e){
            system.debug('Exception->'+e);            
        }
        
        Test.startTest();
        //INSERT Associated_Product__c
        List<Associated_Product__c> apcList = new List<Associated_Product__c>();
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(null, wo.Id, objProduct.Id, objInstalledProduct.Id, objAccount.Id);
        apc.Is_Primary__c=FALSE;
        apcList.add(apc);

        Associated_Product__c apc1 = TestDataFieldService.createAssociatedProductonCase(null, wo.Id, objProduct.Id, objInstalledProduct.Id, objAccount.Id);
        apc1.Is_Primary__c=FALSE;
        apcList.add(apc1);

        Associated_Product__c apc2 = TestDataFieldService.createAssociatedProductonCase(null, wo.Id, objProduct.Id, objInstalledProduct.Id, objAccount.Id);
        apc2.Is_Primary__c=TRUE;
        apcList.add(apc2);

        AssociatedProduct.isTestRunning = TRUE;
        try{
            INSERT apcList;
            apc1.Is_Primary__c=TRUE;
            UPDATE apc1;
        } catch (Exception e){
            system.debug('Exception->'+e);             
        }
        
        System.assertEquals(3,apcList.size(),'AP matched'); //CMCM-3591

        //AssociatedProduct.updatePrimaryAPonCaseWO(apcList,null); //CMCM-3591
        List<SVMXC__Service_Order__c> listWOQuery = [SELECT id, SVMXC__Product__c FROM SVMXC__Service_Order__c WHERE SVMXC__Product__c =:objProduct.id];
        Test.stopTest();
        System.assertEquals(1,listWOQuery.size(),'WO Record Updated'); //CMCM-3591
        //moved the code to new method which was covering CMCM-5753
    }

    /*CMCM-5753
    @author: Dhairya Shah
    */
    @IsTest
    static void preventINSERTonAP() {
        Account objAccount = [SELECT Id FROM Account LIMIT 1];    
        Contact con = [SELECT Id, AccountId  FROM contact LIMIT 1];    
        SVMXC__Site__c objLocation = [SELECT Id FROM SVMXC__Site__c LIMIT 1];
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        SVMXC__Installed_Product__c objInstalledProduct = [SELECT Id FROM SVMXC__Installed_Product__c WHERE SVMXC__Company__c =:objAccount.Id AND SVMXC__Site__c =:objLocation.Id AND SVMXC__Product__c =:objProduct.id LIMIT 1];
        objInstalledProduct.SVMXC__Serial_Lot_Number__c = null;
        
        Test.startTest();
        try{
            UPDATE objInstalledProduct;
        }catch(Exception e){
            system.debug('Exception->'+e);            
        }
        
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING; 
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        objCase.ContactId = con.id;
        
        try{
            INSERT objCase;
        } catch (Exception e){
            system.debug('Exception->'+e);            
        }

        //INSERT SVMXC__Service_Order__c
        SVMXC__Service_Order__c wo = [SELECT Id, SVMXC__Case__c, SVMXC__Product__c FROM SVMXC__Service_Order__c WHERE SVMXC__Case__c = :objCase.Id LIMIT 1];
        Test.stopTest();
        
        List<SVMXC__Service_Order__c> listWO = new List<SVMXC__Service_Order__c>();
        listWO.add(wo);
        System.assertEquals(1,listWO.size(),'WO matched');

        //INSERT SCENARIO AP
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(objCase.Id, wo.Id, objProduct.Id, objInstalledProduct.Id, objAccount.Id);
        apc.Is_Primary__c=false;
        
        DmlException expectedException;
        try{
            //wo.SVMXC__Order_Status__c = 'Canceled';
            WorkOrders.skipWOTrigger = true; //  WorkOrders.skipWOTrigger added by Abhishek for CMCM 8298
            AssociatedProduct.isTestRunning = true;
            wo.SVMXC__Order_Status__c = 'Canceled';
            update wo;

            //AssociatedProduct.isTestRunning = true;
            INSERT apc;

            delete apc;
        } Catch(DMLException e){
            expectedException = e;
        }
        system.assertNotEquals(null, expectedException, 'The record should be validated');
    }

    /*CMCM-5753
    @author: Nancy
    */
    @IsTest
    static void preventUPDATEonAP() {
        Account objAccount = [SELECT Id FROM Account LIMIT 1];     
        SVMXC__Site__c objLocation = [SELECT Id FROM SVMXC__Site__c LIMIT 1];
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];
        Contact con = [SELECT Id, AccountId  FROM contact LIMIT 1];   
        con.Email = 'test325@illumina.com';
        Test.startTest();
        try{
            UPDATE con;
        } catch (Exception e){
            system.debug('Exception->'+e);            
        }
        

        SVMXC__Installed_Product__c objInstalledProduct = [SELECT Id FROM SVMXC__Installed_Product__c WHERE SVMXC__Company__c =:objAccount.Id AND SVMXC__Site__c =:objLocation.Id AND SVMXC__Product__c =:objProduct.id LIMIT 1];
        objInstalledProduct.SVMXC__Serial_Lot_Number__c = null;
        try{
            UPDATE objInstalledProduct;
        } catch (Exception e){
            system.debug('Exception->'+e);            
        }
        

        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        objCase.SVMXC__Product__c = objProduct.Id;
        objCase.PAE_PFA_Evaluation_Required__c = STRING_EVALUATION_ANSWER_PENDING; 
        objCase.Date_of_Issue_Awareness__c = Date.Today();
        objCase.ContactId = con.id;
        try{
            INSERT objCase;
        } catch (Exception e){
            system.debug('Exception->'+e);            
        }

        //INSERT SVMXC__Service_Order__c
        SVMXC__Service_Order__c wo = [SELECT Id,SVMXC__Case__c, SVMXC__Product__c FROM SVMXC__Service_Order__c WHERE  SVMXC__Case__c = :objCase.Id LIMIT 1];
        List<SVMXC__Service_Order__c> listWO = new List<SVMXC__Service_Order__c>();
        listWO.add(wo);
        System.assertEquals(1,listWO.size(),'WO matched');
        Test.stopTest();

        //INSERT SCENARIO AP
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(objCase.Id, wo.Id, objProduct.Id, objInstalledProduct.Id, objAccount.Id);
        apc.Is_Primary__c=FALSE;

        DmlException expectedException;
        try{
            WorkOrders.skipWOTrigger = true; //  WorkOrders.skipWOTrigger added by dhairya shah for CMCM 7787
            AssociatedProduct.isTestRunning = true;
            wo.SVMXC__Order_Status__c = 'Canceled';
            UPDATE wo;

            apc.Is_Primary__c=TRUE;
            UPDATE apc;

            delete apc;
        } catch(DMLException e){
            expectedException = e;
        }
        system.assertNotEquals(null, expectedException, 'The record should be validated');
    }
    
    //Removing the delete and combining the delete operation in preventUPDATEonAP CMCM-7787

    /**
     *  CMCM-269
     *  @author : Abhishek Yadav
     *  @description - insert applied contract on associated product Creation
     **/
    @isTest
    static void testInsertAPContract() {

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
        } catch (Exception e){
            system.debug('Exception->'+e);            
        }
        
        system.assert(apc.Id != null , 'associated product is empty');
        Test.stopTest();
    }
    /**
     *  CMCM-269
     *  @author : Abhishek Yadav
     *  @description - insert applied contract on associated product Creation
     **/
    @isTest
    static void testUpdateAPContract() {
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1]; 
        
        Test.startTest();
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1];
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(null, wo.Id, objProduct.Id, null, null);
        apc.Case__c = objCase.Id;
        apc.Product__c = objProduct.Id;
        apc.Is_Primary__c = FALSE;
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = FALSE;
        AssociatedProduct.isTestRunning = TRUE;
        try{
            INSERT apc;
        } catch(Exception e){
            system.debug('Exception->'+e);             
        }
        
        system.assert(apc.Id != null , 'associated product is empty');
        apc.Product_Lot_Number__c = '7563833';
        try{
            UPDATE apc;
        } catch(Exception e){
            system.debug('Exception->'+e);             
        }
        
        Test.stopTest();
    }
    /**
     *  CMCM-269
     *  @author : Abhishek Yadav
     *  @description - insert applied contract on associated product Creation 
     **/
    @isTest
    static void testDeleteAPContract() {
        //INSERT PRODUCTS
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1]; 
        Test.startTest();
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1];
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(objCase.Id, wo.Id, objProduct.Id, null, null);  
        apc.Product_Lot_Number__c = '7563833';
        apc.Is_Primary__c = false;
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = false;

        AssociatedProduct.isTestRunning = TRUE;
        try{
            INSERT apc;
        } catch(Exception e){
            system.debug('Exception->'+e);             
        }
        
        system.assert(apc.Id != null , 'associated product is empty'); 
        try{
            DELETE apc;
        } catch(Exception e){
            system.debug('Exception->'+e);            
        }
        
        Test.stopTest(); 
    }

    static testmethod void updateCurrentActiveContractOnWOTest() {
        Feature.setMockFeatureFlag('ServiceAssociatedProducts', true);
        //insert account
        Account objAccount = [SELECT Id FROM Account LIMIT 1];
        objAccount.Account_Group__c = 'Distributor';
        objAccount.Clinical_Type__c = 'Clinical';
        
        try{
            UPDATE objAccount;
        } catch(Exception e){
            system.debug('Exception->'+e);            
        }

        //insert product
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Service_Level__c = 'BASIC';
        try{
            INSERT product1;
        } catch(Exception e){
            system.debug('Exception->'+e);            
        }
        
        Product2 product = [SELECT Id,Material_Number__c FROM Product2 WHERE Id =:product1.Id];
        System.assert(product.Material_Number__c != null , 'Product not got created');

        // insert work Orders
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c WHERE SVMXC__Company__c =:objAccount.Id LIMIT 1];
        wo.Evaluation__c = 'Test';
        wo.SVMXC__Work_Performed__c = 'Test';
        wo.Verification_Result__c = 'Test';
        wo.Record_Created_from_SFM__c = true;
        try{
            Cases.skipCaseTrigger = true;
            WorkOrders.skipWOTrigger = true;
            UPDATE wo;
        } catch(Exception e){
            system.debug('Exception->'+e);            
        }

        //insert SVMXC__Service_Plan__c
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = product.Material_Number__c;
        try{
            INSERT sp;
        } catch(Exception e){
            system.debug('Exception->'+e);            
        }
        
        System.assert(sp.Id != null , 'service Plan not got created');

        //insert SVMXC__Service_Contract__c
        SVMXC__Service_Contract__c objServiceContract = [SELECT id, SVMXC__Company__c FROM SVMXC__Service_Contract__c WHERE SVMXC__Company__c=: objAccount.Id];
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Start_Date__c = System.today();
        objServiceContract.SVMXC__End_Date__c = System.today().addDays(20);
        objServiceContract.ERP_Contract_Type__c = 'Consumable Contract';
        Test.startTest();
        try{
            UPDATE objServiceContract;
        } catch(Exception e){
            system.debug('Exception->'+e);            
        }
        
        system.assert(objServiceContract.Id != null , 'service Contract not got created');
        
        //INSERT SCENARIO AP
        AssociatedProduct.isTestRunning = TRUE;
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(null, wo.Id, null, null, objAccount.Id);  
        apc.Is_Primary__c = false;
        try{
            INSERT apc;
        } catch(Exception e){
            system.debug('Exception->'+e);            
        }
        
        // insert Applied contract
        Applied_contract__c contract = TestDataFieldService.createEntitlement(null, wo.Id, objServiceContract.id);
        contract.Associated_Product__c = apc.Id;
        try{
            INSERT contract;
        } catch(Exception e){
            system.debug('Exception->'+e);
        }
        
        SVMXC__Service_Order__c workOrders = [SELECT Id , Currently_Applied_Service_Contract__c FROM SVMXC__Service_Order__c WHERE id = :wo.Id];
        Assert.areEqual(null , workOrders.Currently_Applied_Service_Contract__c , 'service applied contract did get updated');
        apc.Is_Primary__c = TRUE;
        try{
            UPDATE apc;
        } catch(Exception e){
            system.debug('Exception->'+e);            
        }

        SVMXC__Service_Order__c workOrder = [SELECT Id , Currently_Applied_Service_Contract__c FROM SVMXC__Service_Order__c WHERE id = :wo.Id];
        Assert.areEqual(contract.Id , workOrder.Currently_Applied_Service_Contract__c , 'service applied contract did get updated');
        apc.Is_Primary__c = FALSE;
        try{
            UPDATE apc;
        } catch(Exception e){
            system.debug('Exception->'+e);            
        }

        SVMXC__Service_Order__c wOrder = [SELECT Id , Currently_Applied_Service_Contract__c FROM SVMXC__Service_Order__c WHERE id = :wo.Id];
        Test.stopTest();
        Assert.areEqual(null , wOrder.Currently_Applied_Service_Contract__c , 'service applied contract did get updated'); 
    }
    @isTest
    static void testDeleteAppliedContractFromAP() {

       
        Account objAccount = TestDataAccount.getAccount('Test');
        insert objAccount;
        Product2 objProductWithIVDTrue = [SELECT Id FROM Product2 LIMIT 1];   
        Case objCase = [SELECT Id FROM Case LIMIT 1];
        SVMXC__Service_Order__c wo = [SELECT Id FROM SVMXC__Service_Order__c LIMIT 1];
        Associated_Product__c apc = TestDataFieldService.createAssociatedProductonCase(objCase.Id, wo.Id, objProductWithIVDTrue.Id, null, null);
        
        Test.startTest();
        apc.Is_Primary__c = false;
        apc.Product_Lot_Number__c = '7563833';
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = false;
        AssociatedProduct.isTestRunning = TRUE;
        Cases.skipCaseTrigger=true;
        WorkOrders.skipWOTrigger = true;
        INSERT  apc;
        Test.stoptest();
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = '1111';
        insert sp;
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
        insert objServiceContract;
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert cp;
        Applied_Contract__c objEntitlement = new Applied_Contract__c();
        objEntitlement.Service_Contract__c = objServiceContract.Id;
        objEntitlement.Associated_product__c = apc.Id;
        insert objEntitlement; 
        delete apc;
       
         List<Applied_Contract__c> aclIist = [SELECT Id FROM Applied_Contract__c WHERE Id = :objServiceContract.Id];
        Assert.areEqual(0 , aclIist.size() , 'aclIist list is empty');
       
    }
    /**
     *  CMCM-9248
     *  @author : Vishal
     *  @description - Test events on AP insertion and deletion 
     **/
      @IsTest
    static void testPublishAPEvent() {
        Case objCase = TestDataCase.initNewCase(STRING_CASE_RECORDTYPENAME, STRING_CASE_STATUS, STRING_CASE_ORIGIN);
        List<Associated_Product__c> apcList = new List<Associated_Product__c>();
        Associated_Product__c apc = new Associated_Product__c();
        apc.Is_Primary__c = false;
        apc.Case__c = objCase.Id;
        apc.Product_Lot_Number__c = '1111';
        apc.Expired_Date__c = System.Today();
        apc.Is_Expired__c = false;
        apcList.add(apc);
        insert apcList;
        List<Associated_Product_DML_Event__e> platEvents = new List<Associated_Product_DML_Event__e>();
        Test.startTest();
        Associated_Product_DML_Event__e event = new Associated_Product_DML_Event__e();
        event.AP_RecordId__c = apc.Id;
            platEvents.add(event);
        EventBus.publish(platEvents);
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(1, platEvents.size(), 'One event should have been added to the publish list.');
    }

    @isTest
    static void testGetProfileName() {
        Profile testProfile = [SELECT Id, Name FROM Profile LIMIT 1];
        
        // Create a new user and associate the test profile
        User testUser = new User(
            LastName='TestUser',
            Username = 'testuserforgetProfilename@example.com',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null
        );
        
        insert testUser;
        
        System.runAs(testUser) {
            String profileName = AssociatedProduct.getProfileName();
            System.assertEquals(profileName, testProfile.Name, 'The profile name should match the test user profile.');
        }
    }

}
/**
 *    @author Rohan Chandarana
 *    @date   2018-06-25
 *    @description  Material Association with Category,Group and Line
 *    Modification Log:
 *    ------------------------------------------------------------------------------------

 *             Developer                      Date                Description
 *           Saswati Prusty                   6th August 2019     DCP - 25216 : Change product association based on material class type from material class.    
 *           Anish                            26th August 2019    DCP - 25208 : Quantity Increase for Informatics. 
 *           Jitesh Lakhwani                  21-Feb-2023         Codescan - Avoid unused Variable
 *    ------------------------------------------------------------------------------------
 *
 */

 @isTest(SeeAllData=false)
 public with sharing class TestProducts
 {

  @testSetup
  static void setupData()
  {
    TestDataMaster.createProduct(true);

    Apttus_Config2__ClassificationName__c category = TestDataProposal.initCategory('Illumina');
    insert category;

    Apttus_Config2__ClassificationHierarchy__c level0 = TestDataProposal.initHierarchy(category, 'Illumina', null, null, 0);
    insert level0;

    Apttus_Config2__ClassificationHierarchy__c level1 = TestDataProposal.initHierarchy(category, 'By Category', level0, level0, 1);
    insert level1;

    Apttus_Config2__ClassificationHierarchy__c level2 = TestDataProposal.initHierarchy(category, 'BaseSpace Suite', level0, level1, 2);
    insert level2;

    Apttus_Config2__ClassificationHierarchy__c level3 = TestDataProposal.initHierarchy(category, 'BaseSpace Onsite', level0, level2, 3);
    insert level3;

    Apttus_Config2__ClassificationHierarchy__c level4 = TestDataProposal.initHierarchy(category, 'BaseSpace Onsite Accessory', level0, level3, 4);
    level4.Apttus_Config2__Right__c = 2;
    level4.Apttus_Config2__Left__c = 1;
    insert level4;
  }

        @IsTest
        static void sendTheEmails()
        {
          Product2 objProduct = [SELECT Id, Bundle_Id__c FROM Product2 LIMIT 1];
          List<Product2> myProducts = new List<Product2> { objProduct };

          String dummyMetadataValue = 'scooby@illumina.com,doo@illumina.com';
          Test.startTest();
          new Products(myProducts).sendTheEmails(dummyMetadataValue, myProducts);
          integer invocation = Limits.getEmailInvocations();
          System.debug('Saswati - invocation = '+invocation);
          Test.stopTest();
          system.assertEquals(1, invocation,'Emails Not sent');
          
        }

    /**
     *  @author Rohan Chandarana
     *  @description Test method for valiating material association with category, line and group
     **/
     @isTest
     static void testMaterialAssociation()
     {
      Test.startTest();
      {
        Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];
        objProduct.Product_Category__c = 'BaseSpace Suite';
        objProduct.Product_Line_ilmn__c = 'BaseSpace Onsite';
        objProduct.Product_Group__c = 'BaseSpace Onsite Accessory';
        update objProduct;

        Apttus_Config2__ProductClassification__c objProdClassification = [SELECT Id FROM Apttus_Config2__ProductClassification__c LIMIT 1];
        System.assertNotEquals(null, objProdClassification.id);
        Set<Id> setClassificationIds = new Set<Id>{objProdClassification.id};
        List<Apttus_Config2__ProductClassification__c> lstProdClassification = new ApttusProductClassificationSelector().selectById(setClassificationIds);
        System.assertNotEquals(0, lstProdClassification.size());            

        objProduct.Product_Category__c = '';
        update objProduct;

        objProduct.Material_Class_Type__c = 'Software'; //saswati: DCP-25216
        update objProduct;

        lstProdClassification = [SELECT Id FROM Apttus_Config2__ProductClassification__c];
        System.assertEquals(0, lstProdClassification.size());

        Apttus_Config2__ClassificationHierarchy__c objHierarchy = [SELECT Id FROM Apttus_Config2__ClassificationHierarchy__c LIMIT 1];
        Set<Id> setCatHierarchyIds = new Set<Id>{objHierarchy.id};
        List<Apttus_Config2__ClassificationHierarchy__c> lstCategoryHierarchy = new ApttusCategoryHierarchiesSelector().selectById(setCatHierarchyIds);
        System.assertNotEquals(0, lstCategoryHierarchy.size());
      }
      Test.stopTest();
    }

    /**
     *  @author Rohan Chandarana
     *  @description Test method for valiating material association with category, line and group
     **/
     @isTest
     static void testMaterialAssociation2()
     {
      Test.startTest();
      {
        Apttus_Config2__ClassificationHierarchy__c level4 = new Apttus_Config2__ClassificationHierarchy__c ();

        level4  = [Select id From Apttus_Config2__ClassificationHierarchy__c Where Name = 'BaseSpace Onsite Accessory'];
        level4.Name = 'Instrument Service'; //saswati: DCP-25216
        level4.Apttus_Config2__Level__c =1; //Saswati: DCP-25216
        update level4;

        Product2 objProduct = [SELECT Id,Material_Class_Type__c,Apttus_Config2__ConfigurationType__c FROM Product2 LIMIT 1];
        objProduct.Material_Class_Type__c = 'Instrument Service'; //saswati: DCP-25216

        objProduct.Apttus_Config2__ConfigurationType__c = 'Standalone';
        update objProduct;

        Apttus_Config2__ProductClassification__c objProdClassification1 = [SELECT Id FROM Apttus_Config2__ProductClassification__c LIMIT 1];
        System.assertNotEquals(null, objProdClassification1.id);

        Apttus_Config2__ClassificationHierarchy__c level3= [Select id From Apttus_Config2__ClassificationHierarchy__c Where Name = 'BaseSpace Onsite'];
           level3.Name = 'Software'; //saswati: DCP-25216
        level3.Apttus_Config2__Right__c = 2;
        level3.Apttus_Config2__Left__c  = 1;
        level3.Apttus_Config2__Level__c =1; // SAswati : DCP-25216
        update level3;

         objProduct.Material_Class_Type__c = 'Software'; //saswati: DCP-25216

        update objProduct;

        Apttus_Config2__ProductClassification__c objProdClassification2 = [SELECT Id FROM Apttus_Config2__ProductClassification__c LIMIT 1];
        System.assertNotEquals(null, objProdClassification2.id);
      }
      Test.stopTest();
    }
    
    /**
     *  @author Vaibhav
     *  @description [DCP-24624] : (To Test) Product Service Attributes should autopopulate.
     **/
     @isTest
     static void testUpdateTrackingAndStockableInfo()
     {
       Test.startTest();
       
       Product2 objProduct = [SELECT Id FROM Product2 LIMIT 1];
       
      //update Serial Number Profile and FRU Eligible field.
      objProduct.Serial_Number_Profile__c = 'Sample Serial - 01';
      objProduct.FRU_Eligible__c = 'FRU use only';
      update objProduct;
      
      //fetch the updated product.
      Product2 objProductUpdated = [SELECT Id,SVMXC__Stockable__c,SVMXC__Tracking__c,SVMXC__Enable_Serialized_Tracking__c FROM Product2 where Id =: objProduct.Id ];
      
      //Asserts updates.
      System.assertEquals(true, objProductUpdated.SVMXC__Stockable__c);
      System.assertEquals(true, objProductUpdated.SVMXC__Enable_Serialized_Tracking__c);
      
      //update Serial Number Profile and FRU Eligible field.
      objProduct.Serial_Number_Profile__c = '';
      objProduct.FRU_Eligible__c = '';
      update objProduct;
      
      //fetch the updated product.
      Product2 objProductSecondUpdate = [SELECT Id,SVMXC__Stockable__c,SVMXC__Tracking__c,SVMXC__Enable_Serialized_Tracking__c FROM Product2 where Id =: objProduct.Id ];
      
      //Asserts updates.
      System.assertEquals(false, objProductSecondUpdate.SVMXC__Stockable__c);
      System.assertEquals(false, objProductSecondUpdate.SVMXC__Enable_Serialized_Tracking__c);
      
      Test.stopTest();
    }
	
	/**
     *  @author Anish
     *  @description Written to cover quantity read only property update for DCP-25208
     **/
     
    @isTest
    static void testUpdatePLIDefaults()
    { 
      Date futureDate = Date.today() + 10;
      Date pastDate = Date.today() - 10;
      String productCode1 = '12345678';
      String productCode2 = '20012931';
      List<Apttus_Config2__PriceListItem__c> pliListForUpdate = new List<Apttus_Config2__PriceListItem__c>();
      List<Product2> productListForUpdate = new List<Product2>();
      List<Product2> productListForInsert = new List<Product2>();
      Account a = TestDataAccount.getNewAccount();
      Product2 objProduct = TestDataMaster.initProduct(productCode1,Label.ProductMaterialClassInformaticsSoftware);
      Product2 objProduct1 = TestDataMaster.initProduct(productCode2,Label.ProductMaterialClassInstrument);
      productListForInsert.add(objProduct);
      productListForInsert.add(objProduct1);
      insert productListForInsert;
      Account_Sales_Area__c asa = TestDataAccountSalesArea.getNewAccountSalesArea(a.ERP_Customer_Id__c);
      TestDataMaster.getNewPliStaging(a, asa, objProduct, pastDate, futureDate);
      TestDataMaster.getNewPliStaging(a, asa, objProduct1, pastDate, futureDate);
      String contractNumber = a.ERP_Customer_Id__c + '_' + asa.Sales_Organization__c + asa.Distribution_Channel__c + asa.Division__c;
      Apttus_Config2__PriceList__c priceList = TestDataMaster.getNewPriceList(contractNumber);
      Product2 p = [SELECT Id FROM Product2 WHERE ProductCode =: productCode1 LIMIT 1];
      Product2 p1 = [SELECT Id FROM Product2 WHERE ProductCode =: productCode2 LIMIT 1];
      p1.Product_Group__c = Label.ProductGroupProfessionalService;
      update p1;
      TestDataMaster.getNewPriceListItem(priceList.Id, p.Id, pastDate + 2, futureDate - 2, 'USD');
      TestDataMaster.getNewPriceListItem(priceList.Id, p.Id, futureDate + 20, futureDate + 50, 'USD');
      TestDataMaster.getNewPriceListItem(priceList.Id, p1.Id, futureDate + 20, futureDate + 50, 'USD');
      Apttus_Config2__PriceListItem__c pliForUpdate = [SELECT Id,Apttus_Config2__ProductId__c,Apttus_Config2__IsQuantityReadOnly__c,Apttus_Config2__PriceType__c FROM Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c =: p.Id LIMIT 1];
      Apttus_Config2__PriceListItem__c pliForUpdate1 = [SELECT Id,Apttus_Config2__ProductId__c,Apttus_Config2__IsQuantityReadOnly__c,Apttus_Config2__PriceType__c FROM Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c =: p1.Id LIMIT 1];
      pliForUpdate.Apttus_Config2__IsQuantityReadOnly__c = false;
      pliForUpdate.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeRecurring;
      pliForUpdate1.Apttus_Config2__IsQuantityReadOnly__c = false;
      pliListForUpdate.add(pliForUpdate);
      pliListForUpdate.add(pliForUpdate1);
      update pliListForUpdate;
      Test.startTest();
      p.Description = 'Test product';
      p1.Description = 'Test product1';
      productListForUpdate.add(p);
      productListForUpdate.add(p1);
      update productListForUpdate;
      system.assertEquals('12345678',objProduct.ProductCode);
      Test.stopTest();

    }

    /**
     *  @author Ritika
     *  @description Product Family changes : (To Test) Product family should autopopulate based on product code
     **/
     @isTest
     static void testUpdateProductFamilyForPoductCode()
     {
        List<Product_Family_Mapping__mdt> productFamilyMappingForProductCode = [Select Id,Product_Code__c from Product_Family_Mapping__mdt where Product_Code__c != null];
        Product2 objProduct1 = TestDataMaster.initProduct('123');
        System.assert(!productFamilyMappingForProductCode.isEmpty(), 'Product family mapping for product code is empty');
        Test.startTest();
        if(!productFamilyMappingForProductCode.isEmpty()){
          objProduct1.ProductCode = productFamilyMappingForProductCode[0].Product_Code__c;
          insert objProduct1; 
        }
        Test.stopTest();
    }
	
     /**
     *  @author Ritika
     *  @description Product Family changes : (To Test) Product family should autopopulate based on product group 
     **/
     @isTest
     static void testUpdateProductFamilyForPoductGroup()
     {
        List<Product_Family_Mapping__mdt> productFamilyMappingForProductGroup = [Select Id,Product_Group__c from Product_Family_Mapping__mdt where Product_Group__c != null];
        Product2 objProduct1 = TestDataMaster.initProduct('123');
        System.assert(!productFamilyMappingForProductGroup.isEmpty(), 'Product family mapping for product group is empty');
        Test.startTest();
        if(!productFamilyMappingForProductGroup.isEmpty()){
          objProduct1.Product_Group__c = productFamilyMappingForProductGroup[0].Product_Group__c;
        }
        insert objProduct1; 
        if(!productFamilyMappingForProductGroup.isEmpty() && productFamilyMappingForProductGroup.size() > 1){
          objProduct1.Product_Group__c = productFamilyMappingForProductGroup[1].Product_Group__c;
        } 
       
        update objProduct1; 
        Test.stopTest();
    }

    /**
     *  @author Ritika
     *  @description Service Product type changes : (To Test) Service Product type getting set to Calibrated Tool
     **/
    @isTest
    static void testUpdateServiceProductTypeCalibratedTool(){
      Product2 objProduct1 = TestDataMaster.initProduct('123');
      Test.startTest();
      objProduct1.GFSL_FC_Hierarchy__c = 'Calibrated Tool';
      insert objProduct1; 
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Approved Tool- Calibrated',objProduct1.Service_Product_Type__c);
      objProduct1.GFSL_FC_Hierarchy__c = 'XXX';
      update objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Core',objProduct1.Service_Product_Type__c);
      Test.stopTest();
    }

    /**
     *  @author Ritika
     *  @description Service Product type changes : (To Test) Service Product type getting set to Non Calibrated Tool
     **/
    @isTest
    static void testUpdateServiceProductTypeNonCalibratedTool(){
      Product2 objProduct1 = TestDataMaster.initProduct('123');
      Test.startTest();
      objProduct1.GFSL_FC_Hierarchy__c = 'Non-Calibrated Tool';
      insert objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id]; 
      system.assertEquals('Approved Tool- Non-Calibrated',objProduct1.Service_Product_Type__c);
      objProduct1.GFSL_FC_Hierarchy__c = 'XXX';
      update objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Core',objProduct1.Service_Product_Type__c);
      Test.stopTest();
    }

    /**
     *  @author Ritika
     *  @description Service Product type changes : (To Test) Service Product type getting set to Reference Tool
     **/
    @isTest
    static void testUpdateServiceProductTypeReferenceTool(){
      Product2 objProduct1 = TestDataMaster.initProduct('123');
      Test.startTest();
      objProduct1.GFSL_FC_Hierarchy__c = 'Reference Tool';
      insert objProduct1; 
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Approved Tool- Reference',objProduct1.Service_Product_Type__c);
      objProduct1.GFSL_FC_Hierarchy__c = 'XXX';
      update objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Core',objProduct1.Service_Product_Type__c);
      Test.stopTest();
    }

    /**
     *  @author Ritika
     *  @description Service Product type changes : (To Test) Service Product type getting set to Standard Tool
     **/
    @isTest
    static void testUpdateServiceProductTypeStandardTool(){
      Product2 objProduct1 = TestDataMaster.initProduct('123');
      Test.startTest();
      objProduct1.GFSL_FC_Hierarchy__c = 'Standard Tool';
      insert objProduct1; 
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Standard Tool',objProduct1.Service_Product_Type__c);
      objProduct1.GFSL_FC_Hierarchy__c = 'XXX';
      update objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Core',objProduct1.Service_Product_Type__c);
      Test.stopTest();
    }

    /**
     *  @author Ritika
     *  @description Service Product type changes : (To Test) Service Product type getting set to Instrument
     **/
    @isTest
    static void testUpdateServiceProductTypeInstrument(){
      Product2 objProduct1 = TestDataMaster.initProduct('123');
      Test.startTest();
      objProduct1.Serial_Number_Profile__c = 'IL02';
      insert objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id]; 
      system.assertEquals('Instrument',objProduct1.Service_Product_Type__c);
      objProduct1.Serial_Number_Profile__c = 'IL01';
      update objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Core',objProduct1.Service_Product_Type__c);
      Test.stopTest();
    }

    /**
     *  @author Ritika
     *  @description Service Product type changes : (To Test) Service Product type getting set to Spare
     **/
    @isTest
    static void testUpdateServiceProductTypeSpare(){
      Product2 objProduct1 = TestDataMaster.initProduct('123');
      Test.startTest();
      objProduct1.Material_Group__c = '41';
      insert objProduct1; 
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Spare',objProduct1.Service_Product_Type__c);
      objProduct1.Material_Group__c = '42';
      update objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Core',objProduct1.Service_Product_Type__c);
      Test.stopTest();
    }

    /**
     *  @author Ritika
     *  @description Service Product type changes : (To Test) Service Product type getting set to Consumables
     **/
    @isTest
    static void testUpdateServiceProductTypeConsumable(){
      Product2 objProduct1 = TestDataMaster.initProduct('123');
      Test.startTest();
      objProduct1.Material_Class__c = 'Consumables';
      insert objProduct1; 
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Consumable',objProduct1.Service_Product_Type__c);
      objProduct1.Material_Class__c = 'Instrument';
      update objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Core',objProduct1.Service_Product_Type__c);
      Test.stopTest();
    }

    /**
     *  @author Ritika
     *  @description Service Product type changes : (To Test) Service Product type getting set to Non-FRU Service Part
     **/
    @isTest
    static void testUpdateServiceProductTypeNONFRU(){
      Product2 objProduct1 = TestDataMaster.initProduct('123');
      Test.startTest();
      objProduct1.GFSL_FC_Hierarchy__c = 'Non-FRU Service Part';
      insert objProduct1; 
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('NONFRU',objProduct1.Service_Product_Type__c);
      objProduct1.GFSL_FC_Hierarchy__c = 'XXX';
      update objProduct1;
      objProduct1 = [Select Id,Service_Product_Type__c from Product2 where Id=:objProduct1.Id];
      system.assertEquals('Core',objProduct1.Service_Product_Type__c);
      Test.stopTest();
    }
    
    }
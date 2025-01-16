/**
* 
*
* @desc TestProductDataReceiver [CodeScan Fix]
*/
@isTest(isparallel=false)
private class TestProductDataReceiver {

    private static final String PRODUCT_CODE_1 = '15141312';
    private static final String PRODUCT_LOCAL_NAME_1 = 'Translated Name';

    @isTest static void testProductInsertHTTPPost()
    {
        User u = TestDataUser.findUserInProfile('System Administrator');
        u.EmployeeNumber = '100031';
        u.User_Active_until__c = System.today()+30;
        update u;

        List<ProductWrapper.Product> productWithProductSalesArea = new List<ProductWrapper.Product>();

        List<ProductWrapper.ProductSalesArea> psa1 = new List<ProductWrapper.ProductSalesArea>();
        List<ProductWrapper.ProductSalesArea> psa2 = new List<ProductWrapper.ProductSalesArea>();
        List<ProductWrapper.ProductLocalization> loc1 = new List<ProductWrapper.ProductLocalization>();

        ProductWrapper.ProductSalesArea psaRecord1 = new ProductWrapper.ProductSalesArea();
        psaRecord1.Category_Group='TestCategory1';
        psaRecord1.Distribution_Chain_Specific_Status='TestDistributionChainStatus1';
        psaRecord1.Distribution_Channel='TestDistributionChannel1';
        psaRecord1.Sales_Organization='TestSalesOrganization1';
        psaRecord1.ERP_Product_Sales_Area_ID='extId1';
        psa1.add(psaRecord1);

        ProductWrapper.ProductSalesArea psaRecord2 = new ProductWrapper.ProductSalesArea();
        psaRecord2.Category_Group='TestCategory2';
        psaRecord2.Distribution_Chain_Specific_Status='TestDistributionChainStatus2';
        psaRecord2.Distribution_Channel='TestDistributionChannel2';
        psaRecord2.Sales_Organization='TestSalesOrganization2';
        psaRecord2.ERP_Product_Sales_Area_ID='extId2';
        psa1.add(psaRecord2);

        ProductWrapper.ProductSalesArea psaRecord3 = new ProductWrapper.ProductSalesArea();
        psaRecord3.Category_Group='TestCategory3';
        psaRecord3.Distribution_Chain_Specific_Status='TestDistributionChainStatus3';
        psaRecord3.Distribution_Channel='TestDistributionChannel3';
        psaRecord3.Sales_Organization='TestSalesOrganization3';
        psaRecord3.ERP_Product_Sales_Area_ID='extId3';
        psa2.add(psaRecord3);

        ProductWrapper.ProductSalesArea psaRecord4 = new ProductWrapper.ProductSalesArea();
        psaRecord4.Category_Group='TestCategory4';
        psaRecord4.Distribution_Chain_Specific_Status='TestDistributionChainStatus4';
        psaRecord4.Distribution_Channel='TestDistributionChannel4';
        psaRecord4.Sales_Organization='TestSalesOrganization4';
        psaRecord4.ERP_Product_Sales_Area_ID='extId4';
        psa2.add(psaRecord4);

        ProductWrapper.ProductLocalization locRecord1 = new ProductWrapper.ProductLocalization();
        locRecord1.Preferred_Language = 'Chinese trad.';
        locRecord1.ProductCode = PRODUCT_CODE_1;
        locRecord1.Product_Localization_ID = PRODUCT_CODE_1 + '_Chinese trad.';
        locRecord1.Product_Name_Local = PRODUCT_LOCAL_NAME_1;
        loc1.add(locRecord1);

        ProductWrapper.Product productRecord1 = new ProductWrapper.Product();
        productRecord1.Name='TestProduct1';
        productRecord1.ProductCode = PRODUCT_CODE_1;
        productRecord1.Commercial_Launch_Date='20180906';
        productRecord1.Cross_Plant_Material_Status='Z3';
        productRecord1.Material_Group='41';
        productRecord1.Number_Of_Samples='21';
        productRecord1.End_of_Sale_Date='20180920';
        productRecord1.End_of_Ship_Date='20180925';
        productRecord1.End_of_Service_Date='20180930';
        productRecord1.Design_Critical_Part=false;
        productRecord1.Decontamination_Required=false;
        productRecord1.Product_Manager='1000511';
        productRecord1.Dangerous_Good = FALSE;
        productRecord1.Auto_Create_Billable_Work_Order = 'CRLO';
        productRecord1.Open_Offer_Product_Category = 'SERVICES';
        productRecord1.Open_Offer_Product = true;
        productRecord1.productSalesArea=new List<ProductWrapper.ProductSalesArea>();
        productRecord1.productSalesArea.addAll(psa1);
        productRecord1.productLocalization = new List<ProductWrapper.ProductLocalization>(loc1);
        productWithProductSalesArea.add(productRecord1);

        ProductWrapper.Product productRecord2 = new ProductWrapper.Product();
        productRecord2.Name='TestProduct2';
        productRecord2.ProductCode='123456';
        productRecord2.Commercial_Launch_Date='20180906';
        productRecord2.Number_Of_Samples='22';
        productRecord2.End_of_Sale_Date='20180920';
        productRecord2.End_of_Ship_Date='20180925';
        productRecord2.End_of_Service_Date='20180930';
        productRecord2.Cross_Plant_Material_Status='Z5';
        productRecord2.Product_Manager='100031';
        productRecord2.Material_Class='CONSUMABLES';
        productRecord2.Custom_Product=true;
        productRecord2.Replenishment_Eligible=null;
        productRecord2.Dangerous_Good = FALSE;
        productRecord2.Auto_Create_Billable_Work_Order = 'CCLO';
        productRecord2.Open_Offer_Product_Category = 'NEXTSEQ 550 (TG)';
        productRecord2.Open_Offer_Product = true;
        productRecord2.productSalesArea=new List<ProductWrapper.ProductSalesArea>();
        productRecord2.productSalesArea.addAll(psa2);
        productWithProductSalesArea.add(productRecord2);

        ProductWrapper.Product productRecord3 = new ProductWrapper.Product();
        productRecord3.Name='TestProduct3';
        productRecord3.Commercial_Launch_Date='20180906';
        productRecord3.ProductCode='654321';
        productRecord3.Number_Of_Samples='22';
        productRecord3.End_of_Sale_Date='20180920';
        productRecord3.End_of_Ship_Date='20180925';
        productRecord3.End_of_Service_Date='20180930';
        productRecord3.Cross_Plant_Material_Status='Z5';
        productRecord3.Product_Manager='100031';
        productRecord3.Material_Class='CONSUMABLES';
        productRecord3.Safety_Critical_Part=true;
        productRecord3.RMA_Required=true;
        productRecord3.Dangerous_Good = FALSE;
        productRecord3.Auto_Create_Billable_Work_Order = 'DCWO';
        productRecord3.Open_Offer_Product_Category = '';
        productRecord3.Open_Offer_Product = false;
        productRecord3.productSalesArea=new List<ProductWrapper.ProductSalesArea>();
        productWithProductSalesArea.add(productRecord3);

        String productJSON = JSON.serialize(productWithProductSalesArea);

        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProductMaterialSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(productJSON);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        ProductDataReceiver.upsertIncomingValues();
        Test.stopTest();

        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200, res.statuscode);

        //Code scan fix making list size dynamic
        Integer productListSize = productWithProductSalesArea.size();

        List<Product2> productForAssert = [SELECT id, product_manager__c, Auto_Create_Billable_Work_Order__c, Name, 
                                           Open_Offer_Product_Category__c, Open_Offer_Product__c FROM Product2 LIMIT :productListSize];

        System.assertEquals(3, productForAssert.size());
        System.assertEquals(null, productForAssert[0].Product_Manager__c);
        System.assertEquals(u.Id, productForAssert[1].Product_Manager__c);
        System.assertEquals(u.Id, productForAssert[2].Product_Manager__c);

        System.assertEquals('Auto Create Field Service Relocation Work Order',productForAssert[0].Auto_Create_Billable_Work_Order__c);
        System.assertEquals('Auto Create Service Support Clarity LIMS Work Order',productForAssert[1].Auto_Create_Billable_Work_Order__c);
        System.assertEquals(null,productForAssert[2].Auto_Create_Billable_Work_Order__c);

        System.assert(productForAssert[0].Open_Offer_Product__c, 'Open Offer Product should be TRUE');
        System.assert(productForAssert[1].Open_Offer_Product__c, 'Open Offer Product should be TRUE');
        System.assert(!productForAssert[2].Open_Offer_Product__c, 'Open Offer Product should be FALSE');

        System.assertEquals('SERVICES', productForAssert[0].Open_Offer_Product_Category__c, 'Open Offer Category should be SERVICES as added in product 1');
        System.assertEquals('NEXTSEQ 550 (TG)', productForAssert[1].Open_Offer_Product_Category__c, 'Open Offer Category should be SERVICES as added in product 2');
        System.assertEquals(null, productForAssert[2].Open_Offer_Product_Category__c, 'Open Offer Category should be SERVICES as added in product 3');

        List<Product_Localization__c> localizationRecords = [SELECT Id, Preferred_Language__c, Product_Name_Local__c FROM Product_Localization__c WHERE Product__c = :productForAssert[0].Id];
        System.assertEquals(1, localizationRecords.size());
        System.assertEquals(PRODUCT_LOCAL_NAME_1, localizationRecords[0].Product_Name_Local__c);
    }

    @isTest static void testProductUpdateHTTPPost()
    {
        Product2 p=new Product2();
        p.Name='TestProductUpdated';
        p.Serial_Number_Profile__c='';
        p.ProductCode = PRODUCT_CODE_1;
        p.Material_Number__c = PRODUCT_CODE_1;
        insert p;
        System.debug('Log for update insert product:'+p);

        List<Product2> assignIdTOPSA=new List<Product2>();
        assignIdTOPSA=[Select id,Name,product_manager__c,Serial_Number_Profile__c from Product2 where ProductCode= :PRODUCT_CODE_1];

        Product_Sales_Area__c psa=new Product_Sales_Area__c();
        psa.Product__c=assignIdTOPSA[0].Id;
        psa.Category_Group__c='TestCategory1';
        psa.Sales_Organization__c='TestSalesOrgUpdated';
        psa.Distribution_Channel__c='TestDistributionChannel';
        psa.Distribution_Chain_Specific_Status__c='TestDistributionChainSpecificStatus';
        psa.ERP_Product_Sales_Area_Id__c='extId1';
        insert psa;
        System.debug('Log for update insert Product Sales Area');

        List<ProductWrapper.Product> productWithProductSalesArea=new List<ProductWrapper.Product>();

        List<ProductWrapper.ProductSalesArea> psa1=new List<ProductWrapper.ProductSalesArea>();

        ProductWrapper.ProductSalesArea psaRecord1=new ProductWrapper.ProductSalesArea();
        psaRecord1.Category_Group='TestCategory1';
        psaRecord1.Distribution_Chain_Specific_Status='TestDistributionChainStatus1';
        psaRecord1.Distribution_Channel='TestDistributionChannel1';
        psaRecord1.Sales_Organization='TestSalesOrganization1';
        psaRecord1.ERP_Product_Sales_Area_ID='extId1';
        psa1.add(psaRecord1);

        ProductWrapper.ProductSalesArea psaRecord2=new ProductWrapper.ProductSalesArea();
        psaRecord2.Category_Group='TestCategory2';
        psaRecord2.Distribution_Chain_Specific_Status='TestDistributionChainStatus2';
        psaRecord2.Distribution_Channel='TestDistributionChannel2';
        psaRecord2.Sales_Organization='TestSalesOrganization2';
        psaRecord2.ERP_Product_Sales_Area_ID='extId2';
        psa1.add(psaRecord2);

        ProductWrapper.Product productRecord1=new ProductWrapper.Product();
        productRecord1.Name='TestProductUpdated1';
        productRecord1.ProductCode = PRODUCT_CODE_1;
        productRecord1.Commercial_Launch_Date='20180906';
        productRecord1.Cross_Plant_Material_Status='Z3';
        productRecord1.Serial_Number_Profile='IL02';
        productRecord1.Number_Of_Samples='21';
        productRecord1.End_of_Sale_Date='20180920';
        productRecord1.End_of_Ship_Date='20180925';
        productRecord1.End_of_Service_Date='20180930';
        productRecord1.Product_Manager='1000511';
        productRecord1.Dangerous_Good = FALSE;
        productRecord1.productSalesArea=new List<ProductWrapper.ProductSalesArea>();
        productRecord1.productSalesArea.addAll(psa1);
        productWithProductSalesArea.add(productRecord1);

        String productJSON = JSON.serialize(productWithProductSalesArea);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProductMaterialSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(productJSON);
        RestContext.request = req;
        RestContext.response= res;
        ProductDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.debug('Rest Status Code for Update: '+res.statusCode);
        System.assertEquals(200, res.statusCode);

        List<Product2> productForAssert=new List<Product2>();
        productForAssert=[Select id,Name,product_manager__c,Serial_Number_Profile__c from Product2 where ProductCode = :PRODUCT_CODE_1];

        System.debug('product Serial Number' +productForAssert[0].Name);
        System.assertEquals('TestProductUpdated1', productForAssert[0].Name);
        System.assertEquals('IL02', productForAssert[0].Serial_Number_Profile__c);
        System.assertEquals(null, productForAssert[0].Product_Manager__c);
    }

    @isTest static void testProductInsertHTTPPostException()
    {
        List<ProductWrapper.ProductSalesArea> psa1=new List<ProductWrapper.ProductSalesArea>();

        ProductWrapper.ProductSalesArea psaRecord1=new ProductWrapper.ProductSalesArea();
        psaRecord1.Category_Group='TestCategory1';
        psaRecord1.Distribution_Chain_Specific_Status='TestDistributionChainStatus1';
        psaRecord1.Distribution_Channel='TestDistributionChannel1';
        psaRecord1.Sales_Organization='TestSalesOrganization1';
        psaRecord1.ERP_Product_Sales_Area_ID='extId1';
        psa1.add(psaRecord1);

        ProductWrapper.ProductSalesArea psaRecord2=new ProductWrapper.ProductSalesArea();
        psaRecord2.Category_Group='TestCategory2';
        psaRecord2.Distribution_Chain_Specific_Status='TestDistributionChainStatus2';
        psaRecord2.Distribution_Channel='TestDistributionChannel2';
        psaRecord2.Sales_Organization='TestSalesOrganization2';
        psaRecord2.ERP_Product_Sales_Area_ID='extId2';
        psa1.add(psaRecord2);

        List<ProductWrapper.ProductSalesArea> pw=new List<ProductWrapper.ProductSalesArea>();
        pw.addAll(psa1);
        String productJSON = JSON.serialize(pw);

        Test.startTest();

        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/ProductMaterialSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(productJSON);
        RestContext.request = req;
        RestContext.response= res;
        ProductDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.debug('Rest Status Code for Exception: '+res.statusCode);
        System.assertNotEquals(200, res.statusCode);
    }

}
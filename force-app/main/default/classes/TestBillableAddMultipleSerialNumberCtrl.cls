/**
*    @author: Kushagra Desai
*    @date:   09-May-2021
*    @description:  Test class for  BillableAddMultipleSerialNumberCtrl
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestBillableAddMultipleSerialNumberCtrl {
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    @testSetup 
    static void setupData(){
        Account acc = TestDataAccount.getNewAccount();
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        opp.Type = 'Upsell with Service Contract Renewal';
        opp.Sold_to_Sales_Organization__c = 'Test Sales Organization';
        opp.Sold_to_Distribution_Channel__c = 'Test Distribution Channel';
        opp.Direct_Sale_to_Ultimate_Consignee__c = true;
        opp.Current_Ultimate_Consignee__c = acc.id;
        update opp;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        List<Product2> lstProduct = new List<Product2>();
        Product2 objProduct = TestDataMaster.createProduct(false);
        objProduct.Material_Class__c = Label.ProductMaterialClassDocumentTraining;
        objProduct.End_Of_Sale_Date__c = Date.today()-1;
        objProduct.End_Of_Service_Date__c = Date.today();
        objProduct.SVMXC__Product_Type__c = 'Instrument';
        lstProduct.add(objProduct);

        insert lstProduct;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries()); 
        Apttus_Config2__AssetLineItem__c objAssetLine = TestDataApttusAsset.getNewAssetLineItem(acc.Id, acc.Id, lstProduct.get(0).Id);
        objAssetLine.Serial_Number__c = 'SerialNumber1';
        update objAssetLine;
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        insert proposal;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        List<Product_Sales_Area__c> listProductSalesArea = new List<Product_Sales_Area__c>();
        Product_Sales_Area__c productSalesArea = new Product_Sales_Area__c();
        productSalesArea.Product__c = objProduct.id;
        productSalesArea.Sales_Organization__c = 'Test Sales Organization';
        productSalesArea.Distribution_Channel__c = 'Test Distribution Channel';
        productSalesArea.Distribution_Chain_Specific_Status__c = 'Blocked for Shipment';
        listProductSalesArea.add(productSalesArea);
        insert listProductSalesArea;
        TestDataProposal.getNewCart(proposal);
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
        List<Apttus_Config2__PriceListItem__c> lstPriceList = new List<Apttus_Config2__PriceListItem__c>();
        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(objProduct, priceList);
        priceListItem.Apttus_Config2__PriceType__c = Label.PriceListItemPriceTypeOneTime;
        lstPriceList.add(priceListItem);
    
        insert lstPriceList;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        Apttus_Config2__ConfigCustomClasses__c configCustomClass = TestDataProposal.getNewConfigCustomClass();
        configCustomClass.Apttus_Config2__PricingCallbackClass__c = 'ApttusPricingCallback';
        configCustomClass.Name = 'System Properties';
        update configCustomClass;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
        TestDataProposal.getNewConfigLineItemCustomField();
        TestDataProposal.getNewConfigLineItemCustomField1();
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    @isTest
    static void testAddSerailNumber(){
        Account acc = [Select Id from Account limit 1];
        Apttus_Proposal__Proposal__c proposal = [Select id From Apttus_Proposal__Proposal__c LIMIT 1];
        List<Product2> lstProduct = [Select id From Product2 LIMIT 10];
        lstProduct.get(0).Material_Class__c = Label.ProductMaterialClassInformaticsSoftware;
        update lstProduct.get(0);
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries()); 

        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        update objProductConfig;
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        List<Apttus_CPQApi.CPQ.SelectedProductDO> selectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
        Apttus_CPQApi.CPQ.SelectedProductDO selectProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selectProduct.ProductId = lstProduct.get(0).Id;
        selectProduct.Quantity = 1;
        selectProduct.SellingTerm = 12;
        selectProduct.StartDate = Date.today();
        selectProduct.EndDate = Date.today() + 365;
        selectedProducts.add(selectProduct);

        Test.setCurrentPageReference(new PageReference('Page.BillableAddMultipleSerialNumber'));
        System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id );
        BillableAddMultipleSerialNumberCtrl objClass = new BillableAddMultipleSerialNumberCtrl();
        objClass.redirectToCart();
        // Service part
        SVMXC__Installed_Product__c instProd1 = TestDataInstalledProduct.getNewInstalledProduct(acc.Id);
        Product2 objProd = new Product2(Name = 'Test',Serial_Number_Profile__c = 'IL02');
        objProd.Product_Group__c = 'MiSeq Dx';
        objProd.Run_Product_Family_Mapping__c = TRUE;
        objProd.Family = 'MiSeq - MSQ - Dx';
        insert objProd; 

        instProd1.SVMXC__Product__c = objProd.Id;
        instProd1.Operation_Status__c = 'On';
        instProd1.SVMXC__Serial_Lot_Number__c = 'INS-1';
        update new List<SVMXC__Installed_Product__c> {instProd1};
        System.debug('List installed Product-->'+[Select id,SVMXC__Company__c,Service_Product_Type__c,SVMXC__Serial_Lot_Number__c from SVMXC__Installed_Product__c LIMIT 100]);
        Apttus_CPQApi.CPQ.AddMultiProductRequestDO addMultiProductRequest = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
        addMultiProductRequest.CartId = objProductConfig.Id;
        addMultiProductRequest.SelectedProducts = selectedProducts;
        Apttus_CPQApi.CPQWebService.addMultiProducts(addMultiProductRequest);
        List<Apttus_Config2__LineItem__c> lineItemList = [select Id,Serial_Number__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        Apttus_Config2__LineItem__c lineitem = lineItemList.get(0);
        lineitem.Serial_Number__c = 'SerialNumber1';
        update lineItemList;
        List<Apttus_Config2__LineItem__c> lineItemList1 = [select Id,Serial_Number__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        system.debug('Line Items-->'+lineItemList1);
        Test.startTest();
        String strJSON = BillableAddMultipleSerialNumberCtrl.initRecord(objProductConfig.Id);
        System.debug('Return JSON-->'+strJSON);
        List<BillableAddMultipleSerialNumberCtrl.LineDetails> lstLineDetail = (List<BillableAddMultipleSerialNumberCtrl.LineDetails>)JSON.deserialize(
            UtilsObject.getJSONPart(strJSON,
            '{"lstLineDetails": ',
            ', "idCurrentUCId":'),
        List<BillableAddMultipleSerialNumberCtrl.LineDetails>.class);
        String strUC = (String)JSON.deserialize(
            UtilsObject.getJSONPart(strJSON,
            ', "idCurrentUCId": ',
            ', "boolIsRelocation": '),
        String.class);
        System.debug('Current UC-->'+strUC);
        System.assertEquals(strUC,acc.id,'Current UC is not correct');
        System.assertEquals(1,lstLineDetail.size(),'Line Detail count not matching');
        strJSON = BillableAddMultipleSerialNumberCtrl.getInstalledProduct(strUC,'["INS-2"]',false);
        system.debug('getInstalledProduct-->'+strJSON);
        List<BillableAddMultipleSerialNumberCtrl.InstalledProduct> lstIPDetail = (List<BillableAddMultipleSerialNumberCtrl.InstalledProduct>)JSON.deserialize(
            UtilsObject.getJSONPart(strJSON,
            '{"lstIPDetails": ',
            '}'),
        List<BillableAddMultipleSerialNumberCtrl.InstalledProduct>.class);
        System.assertEquals(1,lstIPDetail.size(),'IP list dont match');
        BillableAddMultipleSerialNumberCtrl.saveLine(lineItemList1[0].id,'["NewSerial","NewSerial2"]');
        List<Apttus_Config2__LineItem__c> lineItemList2 = [select Id,Serial_Number__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:objProductConfig.Id];
        System.assertEquals('NewSerial,NewSerial2',lineItemList2[0].Serial_Number__c,'Serial number not updated');
        try{
            BillableAddMultipleSerialNumberCtrl.saveLine('','["NewSerial","NewSerial2"]');
        }catch(Exception e){
            System.assertEquals('Invalid id: ',e.getMessage(),'Wrong Exception Caught');
        }
        try{
            BillableAddMultipleSerialNumberCtrl.getInstalledProduct('','["INS-1"]',false);
        }catch(Exception e){
            System.assertEquals('Invalid id: ',e.getMessage(),'Wrong Exception Caught');
        }
        Test.stopTest();
    }
}
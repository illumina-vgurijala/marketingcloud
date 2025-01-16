/* @ author       : Indra Ganesan
* @ date         : 05-18-2018
* @ Description  : TestOpportunityLineItems is the test class for OpportunityLineItems
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Indra Ganesan        05-18-2018                  US-598             Initial version
* Indra Ganesan        06-14-2018                  US-2987            Modified
* Govind Dubey .       06-28-2018                  US-2433            Modified for deletion scenario
* Govind Dubey         07-13-2018                  DCP-607            Switching Cycle test data
* Akash Kumar          06-08-2018                  DCP-7708           Added Method to test prevent delete of Oppotunity Line Items Without Quote
* Akash Kumar          06-08-2018                  DCP-7708           Added Method to test prevent delete of Oppotunity Line Items With Quote
* Rahul Sharma         02-01-2019                  DCP-22903          Removed logic for auto switch record type for field services
* Satya Swain          10-09-2019                  INC0225110         Added clearOpportunityCache
* Rahul Sharma         02-01-2019                  DCP-22903           Removed logic for auto switch record type for field services
* Arnab Modak          08-29-2019                  DCP-28663          Added method to deleted FixedBundleSKU from getting synced from Quote
* Satya Swain          12-12-2019                  INC0244077         Fix too many SOQL Queries as part of INC0244077
* Saurav Bhandari      13-11-2019                  DCP-28965          Added method to check the CRF Logic
* Adyasha Satapathy    17-09-2020                  DCP-40052          Added method to check Record Type switch to Standard based on conditions of Opportunity Line Items
* Gladis               10-May-2021                 DCP-46225          Updated value 'Services' to 'Break Fix' for Field_Service, Product_Interest__c field.
* Jitesh Lakhwani      21-Feb-2023                                    Codescan - Avoid unused Variable
*/
@isTest(isParallel = false)
public with sharing class TestOpportunityLineItems {

    // NOTE: move these constants to Opportunities
    public static final String RT_FIELD_SERVICES = 'Field_Services';
    public static final String RT_INDIRECT_REORDER = 'Indirect_Re_Order';
    public static final String RT_DIRECT_REORDER = 'Re_Order';
    public static final String RT_INDIRECT_FS = 'Indirect_Field_Services';

    // NOTE: this too, or should it be in base class?
    public static Map<String, Schema.RecordTypeInfo> rts = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();

    /**
     *  @author      : Todd Newman
     *  @description : check ICE product lines populated on opportunity
     **/
    private static testMethod void iceProductLinesPropagateToOpportunity()
    {
        List<String> productGroupValues = getProductGroupValues();
        Integer intValueCount = productGroupValues.size();
        if (intValueCount < 2) return;
        String group1 = productGroupValues.get(0);
        String group2 = productGroupValues.get(intValueCount - 1);

        Product2 objProduct1 = TestDataMaster.initProduct('Cookie');
        Product2 objProduct2 = TestDataMaster.initProduct('Brownie');
        objProduct1.Product_Group__c = group1;
        objProduct2.Product_Group__c = group2;
        insert new List<Product2> { objProduct1, objProduct2 };
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objProduct1.Id, 200);
        PricebookEntry pbe2 = TestDataMaster.getNewStandardPrice(objProduct2.Id, 200);
        Account objAccount = TestDataAccount.getNewAccount();
        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAccount);
        OpportunityLineItem oli1 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, true);
        OpportunityLineItem oli2 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, true);

        
        {
            Opportunity afterInsert = [SELECT Id, ICE_Opportunity_Product_Lines__c FROM Opportunity WHERE Id = :objOpportunity.Id][0];
            System.assertEquals(group1, afterInsert.ICE_Opportunity_Product_Lines__c);

            OpportunityLineItem oli3 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe2.Id, true);
            Opportunity afterAdd = [SELECT Id, ICE_Opportunity_Product_Lines__c FROM Opportunity WHERE Id = :objOpportunity.Id][0];
            System.assert(afterAdd.ICE_Opportunity_Product_Lines__c.contains(group1));
            System.assert(afterAdd.ICE_Opportunity_Product_Lines__c.contains(group2));
            Test.startTest();
            delete oli1;
            Opportunity afterDelete1 = [SELECT Id, ICE_Opportunity_Product_Lines__c FROM Opportunity WHERE Id = :objOpportunity.Id][0];
            System.assert(afterDelete1.ICE_Opportunity_Product_Lines__c.contains(group1));
            System.assert(afterDelete1.ICE_Opportunity_Product_Lines__c.contains(group2));

            delete oli2;
            Opportunity afterDelete2 = [SELECT Id, ICE_Opportunity_Product_Lines__c FROM Opportunity WHERE Id = :objOpportunity.Id][0];
            System.assertEquals(group2, afterDelete2.ICE_Opportunity_Product_Lines__c);

            delete oli3;
            Opportunity afterDelete3 = [SELECT Id, ICE_Opportunity_Product_Lines__c FROM Opportunity WHERE Id = :objOpportunity.Id][0];
            System.assertEquals(null, afterDelete3.ICE_Opportunity_Product_Lines__c);
        }
        Test.stopTest();
    }

    private static List<String> getProductGroupValues()
    {
        List<String> values = new List<String>();
        List<Schema.PicklistEntry> entries = Product2.Product_Group__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry entry : entries)
            if (entry.isActive())
                values.add(entry.getLabel());

        System.debug(values);
        return values;
    }

    /**
     *  @author      :Indra Ganesan
     *  @description :test method for populateProductTypeOnOpportunity
     **/
    private static testMethod void productTypesPropagateToOpportunity()
    {
        System.debug('rts: '+rts);
        //Create Test Data
        Account objAccount = TestDataAccount.getCustomerAccount();
        Account objAccDistributor = TestDataAccount.getAccount('Distributor Partner');
        objAccDistributor.Account_Group__c = 'Distributor';
        insert new List<Account>{objAccount,objAccDistributor};
        Product2 objProduct = TestDataMaster.createProductOfTypeInstrument(true);
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
        Product2 objProduct2 = TestDataMaster.createProduct(true);
        PricebookEntry pbe2 = TestDataMaster.getNewStandardPrice(objProduct2.Id, 200);
        List<Opportunity> lstOpps = new List<Opportunity>();
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        lstOpps.add(objOpportunity);
        //DCP-46225 Updated value 'Services' to 'Break Fix' for Field_Service, Product_Interest__c field.
        Opportunity objFieldServOpportunity = TestDataOpportunity.initOpportunity(objAccount,rts.get(RT_FIELD_SERVICES).getRecordTypeId(),'Develop','Billable Services','Break Fix');
        lstOpps.add(objFieldServOpportunity);
        System.debug('@@'+rts.get(RT_INDIRECT_REORDER));
        Opportunity objIndReOrderOpportunity = TestDataOpportunity.initOpportunity(objAccount,rts.get(RT_INDIRECT_REORDER).getRecordTypeId(),'Develop','Renewal - Software No Upsell','Software');
        objIndReOrderOpportunity.Distributor__c = objAccDistributor.Id;
        lstOpps.add(objIndReOrderOpportunity);
        //Added by Rahul for DCP-22903
        Opportunity objDirectReorderOpp = TestDataOpportunity.initOpportunity(objAccount,rts.get(RT_DIRECT_REORDER).getRecordTypeId(),'Develop','Renewal - Software No Upsell','Software');
        lstOpps.add(objDirectReorderOpp);
        insert lstOpps;
        //Opportunity Line Item creation
        OpportunityLineItem oli1 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, false);
        OpportunityLineItem oli2 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, false);
        OpportunityLineItem oli3 = TestDataMaster.createOpportunityProduct(objFieldServOpportunity.Id, pbe1.Id, false);
        OpportunityLineItem oli4 = TestDataMaster.createOpportunityProduct(objFieldServOpportunity.Id, pbe1.Id, false);
        OpportunityLineItem oli5 = TestDataMaster.createOpportunityProduct(objIndReOrderOpportunity.Id, pbe1.Id, false);
        OpportunityLineItem oli6 = TestDataMaster.createOpportunityProduct(objDirectReorderOpp.Id, pbe1.Id, false);
        insert new List<OpportunityLineItem>{oli1,oli2,oli3,oli4,oli5,oli6};
        Set<Id> oliIdsSet = new Set<Id> { oli1.Id, oli2.Id };

        //Querying the Opportunity to get the Product Type
        List<Opportunity> lstOpp = [SELECT Id, Product_Type__c,Are_Products_Added_by_Channel_Partner__c,StageName,RecordType.DeveloperName,ICE_Opportunity_Product_Lines__c FROM Opportunity WHERE Id = :objOpportunity.Id LIMIT 1];
        System.assert(lstOpp[0].Product_Type__c.contains('Instrument'));
        //Insertion of New Opportunity Line Item
        Test.startTest();
        OpportunityLineItem newOli = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe2.Id, true);
        oliIdsSet.add(newOli.Id);
        lstOpp = [SELECT Id, Product_Type__c, Are_Products_Added__c, Are_Products_Added_by_Channel_Partner__c, StageName, RecordType.DeveloperName FROM Opportunity WHERE Id = :objOpportunity.Id LIMIT 1];
        System.assert(lstOpp[0].Product_Type__c.contains('Instrument'));
        System.assertEquals(true, lstOpp[0].Are_Products_Added__c);

        //deleting OpportunityLineItems
        delete new List<OpportunityLineItem>{oli1,oli2};
        lstOpp = [SELECT Id, Product_Type__c,Are_Products_Added_by_Channel_Partner__c,StageName,RecordType.DeveloperName FROM Opportunity WHERE Id = :objOpportunity.Id LIMIT 1];
        System.assert(lstOpp[0].Product_Type__c.contains('Services'));
        List<OpportunityLineItem> lstOppLnItemLst = [SELECT Id FROM OpportunityLineItem WHERE Id IN :oliIdsSet];
        delete lstOppLnItemLst;
        lstOpp = [SELECT Id, Product_Type__c, Are_Products_Added_by_Channel_Partner__c, Are_Products_Added__c , StageName,RecordType.DeveloperName FROM Opportunity WHERE Id = :objOpportunity.Id LIMIT 1];
        System.assertEquals(null, lstOpp[0].Product_Type__c);
        delete new List<OpportunityLineItem>{oli3,oli4,oli6};
        lstOpp = [SELECT Id, Product_Type__c, Are_Products_Added_by_Channel_Partner__c, Are_Products_Added__c , StageName, RecordType.DeveloperName FROM Opportunity WHERE Id = :objDirectReorderOpp.Id LIMIT 1];
        System.assertEquals(null, lstOpp[0].Product_Type__c);
        System.assertEquals(false, lstOpp[0].Are_Products_Added__c);
        Test.stopTest();
    }

    /**
     *  @author      :Akash Kumar
     *  @description :test method for preventOpportunityProductDeletion withOut Quote
     **/
    private static testMethod void preventDeleteOpportunityProductsWithOutQuote()
    {
        List<OpportunityLineItem> lstOppLineItem = new List<OpportunityLineItem>();
        Account objAccount = TestDataAccount.getNewAccount();
        Product2 objProduct = TestDataMaster.createProduct(true);
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        insert objOpportunity;
        OpportunityLineItem objOppLineItem1 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, true);
        OpportunityLineItem objOppLineItem2 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, true);
        lstOppLineItem.add(objOppLineItem1);
        lstOppLineItem.add(objOppLineItem2);

        Test.startTest();
        delete objOppLineItem1;
        Test.stopTest();
        List<OpportunityLineItem> lstOppLineItemUpdated = [Select Id,Name from OpportunityLineItem where OpportunityId =: objOpportunity.Id];
        System.assertEquals(1,lstOppLineItemUpdated.size());
    }

    /**
     *  @author      :Akash Kumar
     *  @description :test method for preventOpportunityProductDeletion with Quote
     **/
    public static testMethod void preventDeleteOpportunityProductsWithQuote()
    {
        String strErrorMessage = '';

        Account objAccount = TestDataAccount.getNewAccount();
        Product2 objProduct = TestDataMaster.createProduct(true);
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        objOpportunity.Price_List__c='AMR-USD-US-01';
        insert objOpportunity;
        Test.startTest();
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        OpportunityLineItem objOppLineItem1 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, true);
        Apttus_Proposal__Proposal__c proposal1 = TestDataProposal.initProposal(objAccount.id, objOpportunity.id, 'Test Proposal1', priceList.id, true, 'Draft', 'None');
        insert proposal1;

        // opportunity was created in this transaction, clear query cache for update
        OpportunitySelector.clearOpportunityCache();
        Test.stopTest();
        try {
            delete objOppLineItem1;
        } catch(Exception e) {
            System.debug('@@@' + e.getMessage());
            strErrorMessage = e.getMessage();
        }
        System.assert(strErrorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') && strErrorMessage.contains('Products cannot be added or modified once a quote has been generated. Please contact your Partner Account Manager.'), 'Validation rule is not fired as expected.');
    }

     /**
     *  @author      :Arnab Modak
     *  @description :test method to delete Fixed Bundle SKU Line Item
     **/
    public static testMethod void deleteFixedBundleSKUOnSyncFromQuote()
    {
        Account objAccount = TestDataAccount.getNewAccount();
        
        //FixedBundleSKU Product
        Product2 objFixedBundleProduct = TestDataMaster.initProduct('Pizza','Services');
        objFixedBundleProduct.Apttus_Config2__ConfigurationType__c = 'Bundle';
        objFixedBundleProduct.Material_Class_Type__c = Label.FixedBundleMatClassType;
        insert objFixedBundleProduct;
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objFixedBundleProduct.Id, 500);
        
        //FixedBundle Component Product
        Product2 objCompProduct = TestDataMaster.getNewProduct('Toppings');
        PricebookEntry pbe2 = TestDataMaster.getNewStandardPrice(objCompProduct.Id, 200);

        //Linking Bundle and Component product
        TestDataMaster.linkBundleComponent(objFixedBundleProduct.Id,objCompProduct.Id);

        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        insert objOpportunity;

        //Opportunity Line Item creation
        OpportunityLineItem oli1 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, false);
        OpportunityLineItem oli2 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe2.Id, false);
        List<OpportunityLineItem> lstOppLineItem =  new List<OpportunityLineItem>{oli1,oli2};
        insert lstOppLineItem;

        List<OpportunityLineItem> lstOLIDel = [Select id from OpportunityLineItem where Id =: oli1.id];
        System.assertEquals(0,lstOLIDel.size());


    }

    /**
     *  @author      :Saurav Bhandari
     *  @description :test method to check the CRF logic implementation 
     **/
    public static testMethod void productTypeInstrumentOLI()
    {   
        // Account creation
        Account objAccount = TestDataAccount.getNewAccount();
        
        // Product and PriceBook creation
        Product2 objProduct = TestDataMaster.createProductOfTypeInstrument(true);
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
       // objProduct.Auto_Create_Install_Work_Order__c = true;
        objProduct.IsActive = true;
        objProduct.Service_Product_Type__c ='Instrument';
        objProduct.Serial_Number_Profile__c = 'IL02';
        update objProduct;
        
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
        Product2 objProduct2 = TestDataMaster.createProduct(true);
        PricebookEntry pbe2 = TestDataMaster.getNewStandardPrice(objProduct2.Id, 200);
        
        // Opportunity Creation
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount);
        objOpportunity.Is_Customer_Readiness_Form_Required__c = false;
        insert objOpportunity;
        System.assertEquals(false, objOpportunity.Is_Customer_Readiness_Form_Required__c);
        
        test.startTest();
            //Opportunity Line Item creation
            OpportunityLineItem oli1 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, false);
            OpportunityLineItem oli2 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe2.Id, false);
            List<OpportunityLineItem> lstOppLineItem =  new List<OpportunityLineItem>{oli1,oli2};
            insert lstOppLineItem;
            System.assertEquals(2,lstOppLineItem.size());
            
            objOpportunity = [Select Is_Customer_Readiness_Form_Required__c FROM Opportunity WHERE Id=:objOpportunity.Id];
            System.assertEquals(true, objOpportunity.Is_Customer_Readiness_Form_Required__c);
            delete oli1;
            
            objOpportunity = [Select Is_Customer_Readiness_Form_Required__c FROM Opportunity WHERE Id=:objOpportunity.Id];
            system.debug('@@@objOpportunity:'+objOpportunity.Is_Customer_Readiness_Form_Required__c);
            System.assertEquals(false, objOpportunity.Is_Customer_Readiness_Form_Required__c);
            delete oli2;

            objOpportunity = [Select Is_Customer_Readiness_Form_Required__c FROM Opportunity WHERE Id=:objOpportunity.Id];
            System.assertEquals(false, objOpportunity.Is_Customer_Readiness_Form_Required__c);
            OpportunityLineItem oli3 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, false);
            insert oli3;
            objOpportunity = [Select Is_Customer_Readiness_Form_Required__c FROM Opportunity WHERE Id=:objOpportunity.Id];
            System.assertEquals(true, objOpportunity.Is_Customer_Readiness_Form_Required__c);
        test.stopTest();
    }


    /**
     *  @author      :Adyasha Satapathy
     *  @description :test method to check shorter sales cycle - record type switch implementation
     **/
    public static testMethod void recTypeSwitchToStandard()
    {   
        // Account creation
        Account objAccount = TestDataAccount.getNewAccount();
        
        // Product and PriceBook creation
        Product2 objProduct = TestDataMaster.createProductOfTypeInstrument(false);
        // objProduct.Auto_Create_Install_Work_Order__c = true;
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.IsActive = true;
        objProduct.Material_Class__c = System.Label.ProductMaterialClassInstrument;
        objProduct.Service_Product_Type__c = System.Label.ProductClassInstrument;
        insert objProduct;
        
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objProduct.Id, 2000);
        Product2 objProduct2 = TestDataMaster.createProduct(true);
        PricebookEntry pbe2 = TestDataMaster.getNewStandardPrice(objProduct2.Id, 3000);
        
        // Opportunity Creation
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount,RT_DIRECT_REORDER);
        objOpportunity.StageName = System.Label.OpportunityStageDevelop;
        objOpportunity.Type = System.Label.OpportunityTypeRenewalSoftwareNoUpsell;
        objOpportunity.Product_Interest__c = System.Label.ProductInterestSoftware;
        objOpportunity.RecordTypeId = Opportunities.RECORD_TYPE_MAP.get(RT_DIRECT_REORDER).getRecordTypeId();

        Opportunity objOpportunity2 = TestDataOpportunity.initOpportunity(objAccount,RT_INDIRECT_FS);
        objOpportunity2.StageName = System.Label.OpportunityStageDevelop;
        objOpportunity2.Type = System.Label.OpportunityTypeBillableService;
        objOpportunity2.Product_Interest__c = System.Label.ProductInterestServices;
        objOpportunity2.RecordTypeId = Opportunities.RECORD_TYPE_MAP.get(RT_INDIRECT_FS).getRecordTypeId();

        List<Opportunity> lstOpp =  new List<Opportunity>{objOpportunity,objOpportunity2};
        insert lstOpp;
        
        test.startTest();
            //Opportunity Line Item creation
            OpportunityLineItem oli1 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe1.Id, false);
            oli1.Product2Id = objProduct.Id;
            OpportunityLineItem oli2 = TestDataMaster.createOpportunityProduct(objOpportunity.Id, pbe2.Id, false);
            oli2.Product2Id = objProduct2.Id;
            OpportunityLineItem oli3 = TestDataMaster.createOpportunityProduct(objOpportunity2.Id, pbe1.Id, false);
            oli3.Product2Id = objProduct.Id;
            OpportunityLineItem oli4 = TestDataMaster.createOpportunityProduct(objOpportunity2.Id, pbe2.Id, false);
            oli4.Product2Id = objProduct2.Id;
            List<OpportunityLineItem> lstOppLineItem =  new List<OpportunityLineItem>{oli1,oli2,oli3,oli4};
            OpportunityLineItems.boolRunBeforeInsertLogic = true;
            insert lstOppLineItem;
            
            List<OpportunityLineItem> lstOpportunityLineItem = [
                select
                Id,
                OpportunityId,
                Opportunity.Is_Record_Type_Switched_To_Standard__c,
                Opportunity.RecordTypeName__c,
                Opportunity.RecordType.DeveloperName
                from OpportunityLineItem LIMIT 4];

            for(OpportunityLineItem objOLI: lstOpportunityLineItem)
            {
                System.assertEquals(true, objOLI.Opportunity.Is_Record_Type_Switched_To_Standard__c, 'Flag should be true');
                System.assertEquals(objOLI.Opportunity.RecordType.DeveloperName, objOLI.Opportunity.RecordTypeName__c, 'Opportunity.RecordTypeName should be equals to Opportunity.RecordType.DeveloperName');
            }
            
            delete lstOpportunityLineItem;
            List<Opportunity> lstOpportunity = [Select Id,Is_Record_Type_Switched_To_Standard__c from Opportunity LIMIT 2];
            for(Opportunity objOpp: lstOpportunity)
            {
                System.assertEquals(false, objOpp.Is_Record_Type_Switched_To_Standard__c, 'Flag should be false');
            }
        test.stopTest();
    }

}
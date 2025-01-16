/**
*  @author Milan Savaliya
*  @date 2018-10-26
*  @description  
*  Modification Log:
*  ------------------------------------------------------------------------------------
*      Developer          Date        Description
*      Milan            2018-10-26
*      Joshith K        2020-04-27     added asserts for cart line item fields and updated testmethod. 
*	   Joshith K        2020-09-11 	   Apttus_Config2__IncentiveCode__c added in configLineItemCustomField.
*  ------------------------------------------------------------------------------------
**/
@isTest(SeeAllData=false isParallel=false)
private class TestOpportunitySyncToQuotes {

    /**
    *  @author Milan Savaliya
    *  @description Test Data Setup for Sync  Attachment tO oPP
    **/
    @testSetup
    static voId setupData()
    {
        Apttus_Config2__ConfigLineItemCustomFields__c configLineItemCustomField = new Apttus_Config2__ConfigLineItemCustomFields__c();
        configLineItemCustomField.Name = 'System Properties';
        configLineItemCustomField.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__HasIncentives__c,Apttus_Config2__IncentiveCode__c';
        insert configLineItemCustomField;

        Apttus_Config2__PriceList__c obPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert obPriceList;
    
        Product2 product = TestDataMaster.initProduct('Brownie', 'Services');
        Product2 productTwo = TestDataMaster.initProduct('Cookie', 'Services');
        Product2 productThree = TestDataMaster.initProduct('Cake', 'Services');
        insert new List<Product2> {product, productTwo, productThree};

        Apttus_Config2__PriceListItem__c priceListItem = TestDataProposal.initPriceListItem(product, obPriceList);
        Apttus_Config2__PriceListItem__c priceListItemTwo = TestDataProposal.initPriceListItem(productTwo, obPriceList);
        Apttus_Config2__PriceListItem__c priceListItemThree = TestDataProposal.initPriceListItem(productThree, obPriceList);
        insert new List<Apttus_Config2__PriceListItem__c> {priceListItem, priceListItemTwo, priceListItemThree};

        Account objAccount = TestDataAccount.initAccount();
        objAccount.Account_Group__c = 'Distributor';
        insert objAccount;

        List<Opportunity> lstOpp= new List<Opportunity>();
        Opportunity objOpportunity = TestDataOpportunity.initOpportunity(objAccount, 'Indirect_Standard');
        objOpportunity.Distributor__c = objAccount.Id;
        objOpportunity.Ultimate_Consignee__c = objAccount.Id;
        objOpportunity.Direct_Sale_to_Ultimate_Consignee__c = false;
        objOpportunity.Price_List__c = obPriceList.Name;
        lstOpp.add(objOpportunity);
        
         //create opp without line items
        Opportunity objOpportunityNew = TestDataOpportunity.initOpportunity(objAccount, 'Indirect_Standard');
        objOpportunityNew.Name='Opp Without Lines';
        objOpportunityNew.Distributor__c = objAccount.Id;
        objOpportunityNew.Ultimate_Consignee__c = objAccount.Id;
        objOpportunityNew.Direct_Sale_to_Ultimate_Consignee__c = false;
        objOpportunityNew.Price_List__c = obPriceList.Name;
        lstOpp.add(objOpportunityNew);

        insert lstOpp;
        System.debug('####BatchToCloneOppLineToCart objOpportunity:' + objOpportunity);

        List<OpportunityLineItem> lstOpportunityLineItems = new List<OpportunityLineItem>();
        Integer counter = 2;
        for(Product2 objProduct : [SELECT Id FROM Product2 LIMIT 3])
        {
            PricebookEntry objPricebookEntry = TestDataMaster.getNewStandardPrice(objProduct.Id, 200);
            OpportunityLineItem oli = TestDataOpportunity.initOpportunityLineItem(lstOpp.get(0).Id, objPricebookEntry.Id, 14, 11);
            oli.Quantity = counter * 5;
            oli.Shipping_In_Close_Quarter__c = counter + 2;
            oli.Shipping_In_1Q_After_Close_Quarter__c = counter + 1;
            oli.Shipping_In_2Q_After_Close_Quarter__c = counter;
            lstOpportunityLineItems.add(oli);

            counter = counter + 1;
        }
        insert lstOpportunityLineItems;
        List<Apttus_Proposal__Proposal__c> listQuotes = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c objQuote = TestDataProposal.initProposal(
            lstOpp.get(0).AccountId, lstOpp.get(0).Id, 'Test Proposal',
            obPriceList.Id, true,
            ApttusProposals.APPROVAL_STAGE_DRAFT, ApttusProposals.APPROVAL_STATUS_NONE
        );
        listQuotes.add(objQuote);
        Apttus_Proposal__Proposal__c objQuoteNew = TestDataProposal.initProposal(
            lstOpp.get(1).AccountId, lstOpp.get(1).Id, ' Proposal To Opp Without Lines',
            obPriceList.Id, true,
            ApttusProposals.APPROVAL_STAGE_DRAFT, ApttusProposals.APPROVAL_STATUS_NONE
        );
        listQuotes.add(objQuoteNew);
        insert listQuotes;
        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.getNewCart(objQuote);
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = TestDataProposal.initProposalLineItem(objQuote, product);
		proposalLineItem.Apttus_QPConfig__HasIncentives__c = false;
		proposalLineItem.Apttus_QPConfig__ConfigurationId__c = testCart.id;
		Apttus_Proposal__Proposal_Line_Item__c proposalLineItem2 = TestDataProposal.initProposalLineItem(objQuote, productTwo);
		proposalLineItem2.Apttus_QPConfig__HasIncentives__c = false;
		proposalLineItem2.Apttus_QPConfig__ConfigurationId__c = testCart.id;
		insert new List<Apttus_Proposal__Proposal_Line_Item__c> {proposalLineItem, proposalLineItem2};
    }

    @isTest
    private static voId testAfterUpdate()
    {
        List<Apttus_Config2__ProductConfiguration__c> listCart;
        List<OpportunityLineItem> opptLineItems;
        List<Apttus_Config2__LineItem__c> cartLineItems;
        
        Test.startTest();
        {   
            Apttus_Proposal__Proposal__c objProposal = [Select Id, Apttus_Proposal__Opportunity__c FROM Apttus_Proposal__Proposal__c where Apttus_Proposal__Opportunity__r.Name != 'Opp Without Lines' LIMIT 1];
        
            List<Apttus_Config2__ConfigCustomClasses__c> listConfigCustomClasses = [SELECT Id FROM Apttus_Config2__ConfigCustomClasses__c];
            if (!listConfigCustomClasses.isEmpty())
            {
                delete listConfigCustomClasses;
            }

            List<OpportunitySyncToQuote__e> listPlatformEvent = new List<OpportunitySyncToQuote__e>();
            for(Apttus_Proposal__Proposal__c objQuoteProposal:[Select Id, Apttus_Proposal__Opportunity__c FROM Apttus_Proposal__Proposal__c])
            { 
                OpportunitySyncToQuote__e oppprtunitySyncToQuote = new OpportunitySyncToQuote__e(QuoteId__c = objQuoteProposal.Id);
                listPlatformEvent.add(oppprtunitySyncToQuote);
            }

            List<Apttus_Proposal__Proposal_Line_Item__c> objProposalLineItems = new ApttusProposalLineItemsSelector().selectByQuoteId(new Set<Id>{objProposal.id});
            new UtilsCart.LineItemWrapper(objProposalLineItems[0]);
            //multiple records in same instance     
            EventBus.publish(listPlatformEvent);
            Test.getEventBus().deliver();
            //Adding temporary coverage for ApttusUpdatePriceForCart
            ApttusUpdatePriceForCart.runTestBoolIsPricePending = true;
            List<Apttus_Config2__ProductConfiguration__c> prodConfig = new ApttusProductConfigurationsSelector().selectProductConfigurationByQuotIds(new Set<ID> {objProposal.id});
            UtilsCart.doReprice(prodConfig[0].id);
            new ApttusUpdatePriceForCart(prodConfig[0].id).updateRepriceFlagOnQuote(prodConfig[0].id);

            listCart = [SELECT Id
            FROM Apttus_Config2__ProductConfiguration__c
            WHERE Apttus_QPConfig__Proposald__c = :objProposal.Id];

            opptLineItems = 
            [SELECT Id, Quantity, Shipping_In_Close_Quarter__c, Shipping_In_1Q_After_Close_Quarter__c, Shipping_In_2Q_After_Close_Quarter__c, Product2.ProductCode
            FROM OpportunityLineItem];

            cartLineItems =
                [SELECT Id, Apttus_Config2__Quantity__c, Shipping_In_Close_Quarter__c, Shipping_In_1Q_After_Close_Quarter__c, Shipping_In_2Q_After_Close_Quarter__c, Apttus_Config2__ProductId__r.ProductCode
                FROM Apttus_Config2__LineItem__c];

            }
        Test.stopTest();

        Assert.isFalse(listCart.isEmpty(), 'Cart Was not created for Opp Line Item Sync');

        Map<String,Apttus_Config2__LineItem__c> mapCartLines = new Map <String,Apttus_Config2__LineItem__c>();
        for(Apttus_Config2__LineItem__c objCartLine:cartLineItems){
            mapCartLines.put(objCartLine.Apttus_Config2__ProductId__r.ProductCode,objCartLine);
        }
        for (Integer i = 0; i < opptLineItems.size(); i++)
        {
            System.debug('TTN n ' + opptLineItems.get(i).Product2.ProductCode + ' vs ' + cartLineItems.get(i).Apttus_Config2__ProductId__r.ProductCode);
            System.debug('TTN q ' + opptLineItems.get(i).Quantity + ' vs ' + cartLineItems.get(i).Apttus_Config2__Quantity__c);
            System.debug('TTN ' + opptLineItems.get(i).Shipping_In_Close_Quarter__c + ' vs ' + cartLineItems.get(i).Shipping_In_Close_Quarter__c);
            System.debug('TTN ' + opptLineItems.get(i).Shipping_In_1Q_After_Close_Quarter__c + ' vs ' + cartLineItems.get(i).Shipping_In_1Q_After_Close_Quarter__c);
            System.debug('TTN ' + opptLineItems.get(i).Shipping_In_2Q_After_Close_Quarter__c + ' vs ' + cartLineItems.get(i).Shipping_In_2Q_After_Close_Quarter__c);
            Assert.areEqual(opptLineItems.get(i).Quantity, mapCartLines.get(opptLineItems.get(i).Product2.ProductCode).Apttus_Config2__Quantity__c);
            Assert.areEqual(opptLineItems.get(i).Shipping_In_Close_Quarter__c, mapCartLines.get(opptLineItems.get(i).Product2.ProductCode).Shipping_In_Close_Quarter__c);
            Assert.areEqual(opptLineItems.get(i).Shipping_In_1Q_After_Close_Quarter__c, mapCartLines.get(opptLineItems.get(i).Product2.ProductCode).Shipping_In_1Q_After_Close_Quarter__c);
            Assert.areEqual(opptLineItems.get(i).Shipping_In_2Q_After_Close_Quarter__c, mapCartLines.get(opptLineItems.get(i).Product2.ProductCode).Shipping_In_2Q_After_Close_Quarter__c);
            
        }
    }

}
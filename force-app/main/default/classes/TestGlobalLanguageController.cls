/**
*    @author Akash Kumar
*    @date   2018-08-28
*    @description  DCP-9539: Test Class For Global Language Controller
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*           Akash                          07-27-2018          Test Class For Global Language Controller
*           Roopal Verma                   09-26-2018          Renamed Post pricing message to Post_Pricing_Message_List__c and Global_language to Post_Pricing_Message__c
*           Anish Pathak                   19-09-2019          DCP-28436: Added coverage for Brazil template
*           Anish Pathak                   21-09-2020          DCP-29629: Added coverage for Canada template
*           Jitesh Lakhwani                20-Sept-2022        @100% Class : PostPricingMessageSelector Test Coverage
*           Pravallika, Gundreddy          28-nov-2022         POL-57: Update APJ and EMEA References to AMEA and Europe respectively

*/  
@isTest(isParallel = false)
public with sharing Class TestGlobalLanguageController {
 
    /**
*  @author Akash Kumar
*  @description Test Data Setup for Global Language Controller methods
**/
    @testSetup
    static void setupData()
    {
        Account acc = TestDataAccount.getCustomerAccount();
        acc.Territory_Region__c = 'AMEA'; //POL-57
        insert acc;
        TestDataPerson.getNewContact(acc.Id);
        
        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();
        
        Id pricebookId = standardPricebook.id;
        System.assertNotEquals(null, pricebookId);
        
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        opp.Pricebook2Id = pricebookId;
        update opp;
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
        proposal.Preferred_Language__c = 'English';
        insert proposal;
		
		Apttus_Proposal__Proposal__c proposalBrazil = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal Brazil', priceList.id, true, 'Draft', 'None');
        proposalBrazil.Preferred_Language__c = 'English';
        insert proposalBrazil;
        
        Apttus_Proposal__Proposal__c proposalBrazil1 = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal Brazil1', priceList.id, true, 'Draft', 'None');
        proposalBrazil1.Preferred_Language__c = 'English';
        insert proposalBrazil1;
		
        Apttus_Proposal__Proposal__c proposalCanada = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal Canada', priceList.id, true, 'Draft', 'None');
        proposalCanada.Preferred_Language__c = 'English';
        insert proposalCanada;//DCP-29629

        Post_Pricing_Messages__c ppmCompletePurchase1 = new Post_Pricing_Messages__c();
        ppmCompletePurchase1.Name = 'Complete Purchase 1 EN';
        ppmCompletePurchase1.PicklistValue__c = 'Complete Purchase #1';
        ppmCompletePurchase1.Active__c = true;
        ppmCompletePurchase1.Preferred_Language__c = 'English';
        ppmCompletePurchase1.Region__c = 'AMEA'; //POL-57
        ppmCompletePurchase1.Value__c = 'All discounts offered on this quotation are contingent upon a purchase order being provided to Illumina for all the products and/or services quoted herein prior to the expiration date. Illumina will not accept a purchase order against this quotation until this condition has been met.';
        insert ppmCompletePurchase1;

        Post_Pricing_Messages__c tradeIn = new Post_Pricing_Messages__c();
        tradeIn.Name = 'Trade-in Lang (Allow Decommission) EN';
        tradeIn.Active__c = true;
        tradeIn.PicklistValue__c = 'Trade-in Language (Allow Decommission)';
        tradeIn.Preferred_Language__c = 'English';
        tradeIn.Region__c = 'AMEA'; //POL-57
        tradeIn.Value__c = 'Illumina is pleased to offer the special pricing listed above';
        insert tradeIn;

        Post_Pricing_Messages__c threeQuotes = new Post_Pricing_Messages__c();
        threeQuotes.Name = 'Quote Linking Language #3 EN';
        threeQuotes.PicklistValue__c = 'Quote Linking Language (Linking three quotes)';
        threeQuotes.Active__c = true;
        threeQuotes.Preferred_Language__c = 'English';
        threeQuotes.Region__c = 'AMEA'; //POL-57
        threeQuotes.Value__c = 'All discounts offered on this Quotation |#AAAAA| are contingent upon a purchase order being provided to Illumina a for Quotation |#BBBBBB|, Quotation |#CCCCCC| prior to the expiration of this quotation. Illumina will not accept any purchase order against this quote until this condition has been met.';
        insert threeQuotes;

        Post_Pricing_Messages__c chinaQuotes = new Post_Pricing_Messages__c();
        chinaQuotes.Name = '下取りをする場合の文言（デコミッションがない場合）';
        chinaQuotes.PicklistValue__c = '下取りをする場合の文言（デコミッションがない場合）';
        chinaQuotes.Active__c = true;
        chinaQuotes.Preferred_Language__c = 'Chinese';
        chinaQuotes.Region__c = 'AMEA'; //POL-57
        chinaQuotes.Value__c = '下取りをする場合の文言（デコミッションがない場合）';
        insert chinaQuotes;

        Post_Pricing_Messages__c brazilQuotes = new Post_Pricing_Messages__c();
        brazilQuotes.Name = 'Brazil Project Information';
        brazilQuotes.PicklistValue__c = 'Brazil Project Information';
        brazilQuotes.Active__c = true;
        brazilQuotes.Preferred_Language__c = 'Portuguese';
        brazilQuotes.Region__c = 'AMEA'; //POL-57
        brazilQuotes.Value__c = 'CNPJ/CPF :|BRAZIL PROJECT INFO|';
        insert brazilQuotes;

        Post_Pricing_Messages__c nonStandard = new Post_Pricing_Messages__c();
        nonStandard.Name = 'Non-Standard Post Pricing Message EN';
        nonStandard.PicklistValue__c = 'Non-Standard Post Pricing Message';
        nonStandard.Active__c = true;
        nonStandard.Preferred_Language__c = 'English';
        nonStandard.Region__c = 'AMEA'; //POL-57
        nonStandard.Value__c = '| |';
        insert nonStandard;

        Post_Pricing_Messages__c canadian = new Post_Pricing_Messages__c();
        canadian.Name = 'Canadian Foundation for Innovation';
        canadian.PicklistValue__c = 'Canadian Foundation for Innovation';
        canadian.Active__c = true;
        canadian.Preferred_Language__c = 'English';
        canadian.Region__c = 'AMEA'; //POL-57
        canadian.Value__c = 'As part of the Canadian Foundation for Innovation, the above products will be provided to Customer at their indicated discount. This calculates to a |AAAA NUMBERFIELD|% in-kind contribution on the overall subtotal of |AAAA NUMBERFIELD|.';
        insert canadian;
}
    
    /*  @author Akash Kumar
*  @description Test method for GlobalLanguageController methods
**/
    @isTest
    static void testGlobalLanguageControllerMethods(){
        Map<String,String> fieldNameToMessage = new Map<String,String>();
        List < Post_Pricing_Message__mdt > lstPostPricingListMdt = [Select Id, DeveloperName, Value__c, PicklistValue__c
                                                         from Post_Pricing_Message__mdt];
        for (Post_Pricing_Message__mdt p : lstPostPricingListMdt) {
            fieldNameToMessage.put(p.PickListValue__c, p.Value__c);
        }
        String strCompPurchase = fieldNameToMessage.get('Complete Purchase #1');
        String strTradeInDecommision = fieldNameToMessage.get('Trade-in Language (Allow Decommission)');
        String strLinkingQuotes = fieldNameToMessage.get('Quote Linking Language (Linking three quotes)');
        String strTradeInDecommisionJap = fieldNameToMessage.get('下取りをする場合の文言（デコミッションがない場合）');
		String strBrazilProjInfo = fieldNameToMessage.get('Brazil Project Information');//DCP-28436
        Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [Select id,Post_Pricing_Message__c,Preferred_Language__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        objProposal.Post_Pricing_Message_List__c = System.Label.PPM_Complete_Purchase_2_schedule_required;
        update objProposal;
        
		Apttus_Proposal__Proposal__c objProposalBrazil = [Select id,Post_Pricing_Message__c,Preferred_Language__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal Brazil'];
        Apttus_Proposal__Proposal__c objProposalBrazil1 = [Select id,Post_Pricing_Message__c,Preferred_Language__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal Brazil1'];
        objProposalBrazil.Post_Pricing_Message_List__c = 'Brazil Project Information';
        update objProposalBrazil;
		
		Apttus_Proposal__Proposal__c objProposalCanada = [Select id,Post_Pricing_Message__c,Preferred_Language__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal Canada'];
        objProposalCanada.Post_Pricing_Message_List__c = 'Canadian Foundation for Innovation In-Kind Contribution';
        update objProposalCanada;
		
        Test.startTest();

        String strloadString=GlobalLanguageController.loadData(objProposal.Id);
        System.assert(strloadString!=null,'Data not Loaded');

        String strGlLang1=GlobalLanguageController.populateGlobalLanguageOnChange('Complete Purchase #1',objProposal.Id);
        System.assert(strGlLang1!=null,'Data not Loaded');

        String strGlLang2=GlobalLanguageController.populateGlobalLanguageOnChange('Non-Standard Post Pricing Message',objProposal.Id);
        System.assert(strGlLang2!=null,'Data not Loaded');

        String strGlLang3=GlobalLanguageController.populateGlobalLanguageOnChange('Quote Linking Language (Linking three quotes)',objProposal.Id);
        System.assert(strGlLang3!=null,'Data not Loaded');

        String strGlLang4=GlobalLanguageController.populateGlobalLanguageOnChange('Trade-in Language (Allow Decommission)',objProposal.Id);
        System.assert(strGlLang4!=null,'Data not Loaded');

        GlobalLanguageController.saveProposal(objProposal.Id,'Complete Purchase #2 (schedule required)',strCompPurchase);
        Apttus_Proposal__Proposal__c objProposal1 = [Select id,Post_Pricing_Message__c From Apttus_Proposal__Proposal__c where id=:objProposal.Id];
        System.assert(objProposal1.Post_Pricing_Message__c!=null,'Data Not Loaded');

        GlobalLanguageController.saveProposal(objProposal.Id,'Non-Standard Post Pricing Message','testSave');
        System.assert(objProposal1.Post_Pricing_Message__c!=null,'Data Not Loaded');

        String strGlLang5=GlobalLanguageController.populateGlobalLanguageOnChange('Non-Standard Post Pricing Message',objProposal.Id);
        System.assert(strGlLang5!=null,'Data not Loaded');

        GlobalLanguageController.saveProposal(objProposal.Id,'Trade-in Language (Allow Decommission)',strTradeInDecommision);
        System.assert(objProposal1.Post_Pricing_Message__c!=null,'Data Not Loaded');

        String strGlLang6=GlobalLanguageController.populateGlobalLanguageOnChange('Trade-in Language (Allow Decommission)',objProposal.Id);
        System.assert(strGlLang6!=null,'Data not Loaded');
        
        GlobalLanguageController.saveProposal(objProposal.Id,'Quote Linking Language (Linking three quotes)',strLinkingQuotes);
        System.assert(objProposal1.Post_Pricing_Message__c!=null,'Data Not Loaded');
        
        String strGlLang7=GlobalLanguageController.populateGlobalLanguageOnChange('Quote Linking Language (Linking three quotes)',objProposal.Id);
        System.assert(strGlLang7!=null,'Data not Loaded');

        Apttus_Proposal__Proposal__c objProposal6 = [Select id,Post_Pricing_Message__c,Preferred_Language__c From Apttus_Proposal__Proposal__c where id=:objProposal.Id];
        objProposal6.Preferred_Language__c = 'Japanese';
        update objProposal6;

        String strGlLang9=GlobalLanguageController.populateGlobalLanguageOnChange('下取りをする場合の文言（デコミッションがない場合）',objProposal6.Id);
        System.assert(strGlLang9!=null,'Data not Loaded');

        GlobalLanguageController.saveProposal(objProposal6.Id,'下取りをする場合の文言（デコミッションがない場合）',strTradeInDecommisionJap);
        Apttus_Proposal__Proposal__c objProposal7 = [Select id,Post_Pricing_Message__c From Apttus_Proposal__Proposal__c where id=:objProposal6.Id];
        System.assert(objProposal7.Post_Pricing_Message__c!=null,'Data Not Loaded');

        String strGlLang11=GlobalLanguageController.populateGlobalLanguageOnChange('下取りをする場合の文言（デコミッションがない場合）',objProposal7.Id);
        System.assert(strGlLang11!=null,'Data not Loaded');
		
		/* DCP-28436 - Brazil PPM code coverage */
        GlobalLanguageController.saveProposal(objProposalBrazil.Id,'Brazil Project Information',strBrazilProjInfo);
        Apttus_Proposal__Proposal__c objProposal19 = [Select id,Post_Pricing_Message__c From Apttus_Proposal__Proposal__c where id=:objProposalBrazil.Id];
        Apttus_Proposal__Proposal__c objProposal21 = [Select id,Post_Pricing_Message__c From Apttus_Proposal__Proposal__c where id=:objProposalBrazil1.Id];
        
        
        GlobalLanguageController.populateGlobalLanguageOnChange('Brazil Project Information',objProposal21.Id);
        
        String strGlLang20=GlobalLanguageController.populateGlobalLanguageOnChange('Brazil Project Information',objProposal19.Id);
        System.assert(strGlLang20!=null,'Data not Loaded');
		
		/* DCP-29629 - Canada PPM code coverage */
        GlobalLanguageController.saveProposal(objProposalCanada.Id,'Brazil Project Information',strBrazilProjInfo);
        Apttus_Proposal__Proposal__c objProposal23 = [Select id,Post_Pricing_Message__c From Apttus_Proposal__Proposal__c where id=:objProposalCanada.Id];
        
        String strGlLang23=GlobalLanguageController.populateGlobalLanguageOnChange('Canadian Foundation for Innovation',objProposal23.Id);
        System.assert(strGlLang23!=null,'Data not Loaded');

        Test.stopTest();
    }

    /* @author Jitesh Lakhwani
    *  @description Test method for selectPostPricingMessageByName methods for PostPricing
    **/
    @isTest
    static void testSelectPostPricingMessageByName(){

        Test.startTest();

        PostPricingMessageSelector objPostPricingMessageSelector = new PostPricingMessageSelector();
        List<Post_Pricing_Messages__c> ppmList = objPostPricingMessageSelector.selectPostPricingMessageByName('Canadian Foundation for Innovation');

        System.assertEquals(1, ppmList.size(), 'Canadian foundation for Innovation is found ');

        Test.stopTest();
    }
}
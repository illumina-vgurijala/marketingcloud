/*
* @author Illumina
* @Date N/A
* @Description  Test Class for Quotation Data Receiver Class
Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
*      Jitesh Lakhwani              25-July-2022        DCP-54361 : Show Applied Promo's on Quote Header level.
*    -----------------------------------------------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=false)
private class TestQuotationDataReceiver {

    private static final String NAME_OPP = 'test';
	
    
	/**
    *   Test data setup
	**/
    @TestSetup
	public static void testData(){
    account objAcc =TestDataAccount.getAccount('TestQuote');
    objAcc.ERP_Customer_Id__c='8976';
    objAcc.Account_Group__c='Ultimate Consignee';
    insert objAcc;
    account objAcc1 = TestDataAccount.getAccount('TestQuote1');
    objAcc1.ERP_Customer_Id__c='6724';
    objAcc1.Account_Group__c='Distributor';
    insert objAcc1;
    Customer_Master_Data__c customerData = new Customer_Master_Data__c(name='Test1',ERP_Customer_Id__c='12345');
    insert customerData;
    
    Opportunity objOpps = TestDataOpportunity.initOpportunity(objAcc);
    objOpps.Name =NAME_OPP;
    objOpps.Price_List__c = NAME_OPP;
    objOpps.Distributor__c = objAcc1.Id;
    insert objOpps;

    List<Promotions__c> promoObjList = new List<Promotions__c>();
    Promotions__c promo1Obj = new Promotions__c(Name = 'PROMOTION1', Promotion_Code__c = 'PROMO_CODE_1');
    promoObjList.add(promo1Obj);
    Promotions__c promo2Obj = new Promotions__c(Name = 'PROMOTION2', Promotion_Code__c = 'PROMO_CODE_2');
    promoObjList.add(promo2Obj);
    Promotions__c promo3Obj = new Promotions__c(Name = 'PROMOTION3', Promotion_Code__c = 'PROMO_CODE_3');
    promoObjList.add(promo3Obj);

    insert promoObjList;
    
    Apttus_Config2__Incentive__c objIncentive=new Apttus_Config2__Incentive__c();
    objIncentive.Apttus_Config2__IncentiveCode__c='PROMO1';
    objIncentive.Master_Promotions__c = promo1Obj.Id;
    objIncentive.Apttus_Config2__Sequence__c=1;
    insert objIncentive;
    Apttus_Config2__Incentive__c objIncentive1=new Apttus_Config2__Incentive__c();
    objIncentive1.Apttus_Config2__IncentiveCode__c='PROMO2';
    objIncentive1.Master_Promotions__c = promo2Obj.Id;
    objIncentive1.Apttus_Config2__Sequence__c=1;
    insert objIncentive1;
    Apttus_Config2__Incentive__c objIncentive2=new Apttus_Config2__Incentive__c();
    objIncentive2.Apttus_Config2__IncentiveCode__c='PROMO3';
    objIncentive2.Master_Promotions__c = promo3Obj.Id;
    objIncentive2.Apttus_Config2__Sequence__c=1;
    insert objIncentive2;
    Apttus_Config2__Incentive__c objIncentive3=new Apttus_Config2__Incentive__c();
    objIncentive3.Apttus_Config2__IncentiveCode__c='PROMO4';
    objIncentive3.Apttus_Config2__Sequence__c=1;
    insert objIncentive3;
    Apttus_Config2__Incentive__c objIncentive4=new Apttus_Config2__Incentive__c();
    objIncentive4.Apttus_Config2__IncentiveCode__c='PROMO5';
    objIncentive4.Apttus_Config2__Sequence__c=1;
    insert objIncentive4;
}
/**
    *   Test Quote insert via HTTP Post
**/

	static testMethod void testQuoteInsertHTTPPost(){
        List<QuotationDataRecieverWrapper.QuoteWrapper> quotes=new List<QuotationDataRecieverWrapper.QuoteWrapper>();
        List<QuotationDataRecieverWrapper.ProposalLineitemWrapper> ql1=new List<QuotationDataRecieverWrapper.ProposalLineitemWrapper>();
        //List<QuotationDataRecieverWrapper.ProposalLineitemWrapper> ql2=new List<QuotationDataRecieverWrapper.ProposalLineitemWrapper>();
        QuotationDataRecieverWrapper.ProposalLineitemWrapper line1=new QuotationDataRecieverWrapper.ProposalLineitemWrapper();
        QuotationDataRecieverWrapper.Promotion promo1=new QuotationDataRecieverWrapper.Promotion();
        QuotationDataRecieverWrapper.Promotion promo2=new QuotationDataRecieverWrapper.Promotion();
        QuotationDataRecieverWrapper.Promotion promo3=new QuotationDataRecieverWrapper.Promotion();
        QuotationDataRecieverWrapper.Promotion promo4=new QuotationDataRecieverWrapper.Promotion();
        QuotationDataRecieverWrapper.Promotion promo5=new QuotationDataRecieverWrapper.Promotion();
        List<QuotationDataRecieverWrapper.Promotion> promos=new List<QuotationDataRecieverWrapper.Promotion>();
        
        Opportunity objOpps = [select id from Opportunity where Name = :NAME_OPP limit 1];
        
        line1.ERP_Line_number = '12121';
        line1.Apttus_Proposal_Quantity = '11';
        line1.Apttus_QPConfig_NetPrice = '123.3';
        line1.CurrencyIsoCode = 'USD';
        line1.Applied_Discount_Amount = '13';
        line1.Serial_Number = 'YHD675';
        line1.Apttus_QPConfig_StartDate = '2018-09-28';
        line1.Apttus_QPConfig_EndDate = '2019-08-30';
        line1.Project_Id = 'THST3435';
        line1.Attempted_Beadtypes = '1542';
        line1.Add_On_Attempted_Beadtypes = 'GTRFD';
        line1.Apttus_QPConfig_ListPrice = '764576';
        line1.Applied_Discount_Details = 'Discont Dis';
        line1.Apttus_QPConfig_AdjustmentType = 'A';
        line1.Apttus_QPConfig_StartDate = '20221217';
        promo1.Promo_Channel = 'Channel';
        promo1.Promo_T_C = 'Promotion T n C';
        promo1.PromotionCode = 'PROMO1';
        promo1.PromotionCodeName = 'PROMO1';
        promos.add(promo1);
        promo2.Promo_Channel = 'Channel';
        promo2.Promo_T_C = 'Promotion T n C';
        promo2.PromotionCode = 'PROMO2';
        promo2.PromotionCodeName = 'PROMO2';
        promos.add(promo2);
        promo3.Promo_Channel = 'Channel';
        promo3.Promo_T_C = 'Promotion T n C';
        promo3.PromotionCode = 'PROMO3';
        promo3.PromotionCodeName = 'PROMO3';
        promos.add(promo3);
        promo4.Promo_Channel = 'Channel';
        promo4.Promo_T_C = 'Promotion T n C';
        promo4.PromotionCode = 'PROMO4';
        promo4.PromotionCodeName = 'PROMO4';
        promos.add(promo4);
        promo5.Promo_Channel = 'Channel';
        promo5.Promo_T_C = 'Promotion T n C';
        promo5.PromotionCode = 'PROMO5';
        promo5.PromotionCodeName = 'PROMO5';
        promos.add(promo5);
        line1.Promotion = new List<QuotationDataRecieverWrapper.Promotion>();
        line1.Promotion.addall(promos);
        ql1.add(line1);
        QuotationDataRecieverWrapper.ProposalLineitemWrapper line2=new QuotationDataRecieverWrapper.ProposalLineitemWrapper();
        line2.ERP_Line_number = '12123';
        line2.Apttus_Proposal_Quantity = '111';
        line2.Apttus_QPConfig_NetPrice = '123.3';
        line2.CurrencyIsoCode = 'USD';
        line2.Applied_Discount_Amount = '13';
        line2.Serial_Number = 'YHD675';
        line2.Apttus_QPConfig_StartDate = '2018-09-28';
        line2.Apttus_QPConfig_EndDate = '2019-08-30';
        line2.Project_Id = 'THST3435';
        line2.Attempted_Beadtypes = '1542';
        line2.Add_On_Attempted_Beadtypes = 'GTRFD';
        line2.Apttus_QPConfig_ListPrice = '764576';
        line2.Applied_Discount_Details = 'Discont Dis';
        line2.Apttus_QPConfig_AdjustmentType = 'N';
        line2.Reason_For_Rejection = 'Rejected';
        ql1.add(line2);

        QuotationDataRecieverWrapper.QuoteWrapper quote1 = new QuotationDataRecieverWrapper.QuoteWrapper();
        quote1.SAP_Quote = 'SAP-123';
        quote1.Apttus_Proposal_ExpectedEndDate = '20190928';
        quote1.Apttus_QPConfig_PricingDate = '20181001';
        quote1.Apttus_Proposal_Quote_Stage = 'Draft';
        quote1.Apttus_Proposal_Account = '8976';
        quote1.Ship_To = '12345';
        quote1.Bill_To = '12345';
        quote1.Payer = '12345';
        quote1.Ultimate_Consignee ='8976';
        quote1.Distributor = '6724';
        quote1.Apttus_Proposal_Opportunity = objOpps.id;
        quote1.Discount_Justification = 'Justified';
        quote1.Inco_term_1 = 'CFR: Costs and freight'; //picklist
        quote1.Apttus_Proposal_Payment_Term = '1 Year'; //picklist
        quote1.Web_Visible = 'W_N';
        quote1.CurrencyIsoCode = 'USD';
        quote1.Estimated_Freight = '198';
        quote1.Estimated_Freight_USD = '1.9';
        quote1.Estimated_Tax = '56';
        quote1.Estimated_Tax_USD = '0.56';
        quote1.Apttus_Proposal_Quote_Stage = 'Initial';
        quote1.Promo_Code_1= 'PROMO1';
        quote1.Promo_Code_2 = 'PROMO2';
        quote1.Promo_Code_3 ='PROMO3';
        quote1.Apttus_QPConfig_PricingDate = '20221217';
        quote1.ProposalLineitemWrapper = new List<QuotationDataRecieverWrapper.ProposalLineitemWrapper>();
        quote1.ProposalLineitemWrapper.addall(ql1);
        quotes.add(quote1);
		String quotesJSON = JSON.serialize(quotes);
        system.debug('Quotes JSON : '+ quotesJSON);


        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/QuotationSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(quotesJSON);
        RestContext.request = req;
        RestContext.response= res;
        QuotationDataReceiver.upsertIncomingValues();

        Test.stopTest();
        System.debug('Rest Status Code for insert: '+res.statusCode);
        System.assertequals(200,res.statuscode, 'Status Code should be 200');

        Apttus_Proposal__Proposal__c proposal = [SELECT id, Applied_Promo_1__c, Applied_Promo_2__c, Applied_Promo_3__c FROM Apttus_Proposal__Proposal__c WHERE SAP_Quote__c = 'SAP-123' LIMIT 1];

        System.assertNotEquals(null, proposal.Applied_Promo_1__c,'Applied Promo Code should NOT be null');
	}
}
/* @ author      : Dushyant Srivastava
* @ date         : 24th November 2021
* @ Description  : TestApttusEmailCartController is the test class for ApttusEmailCartController
*/
@isTest
public class TestApttusEmailCartController {
	public static final String PAGE_APTTUS_EMAIL_CART = 'Page.ApttusEmailCart';
    public static final String STRDRAFT = 'draft';
    public static final String STRNONE = 'None';
	/**
	*  @author Dushyant Srivastava
	*  @description Test Data Setup
	**/
	@testSetup
	static void setupData()
	{
		Account acc = TestDataAccount.getAccount('Test Account','USD');
		insert acc;

		Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
		
        Contact con = TestDataPerson.initContact(acc.Id);
        con.email = 'axs@scs.com';
        insert con;

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Price_List__c = priceList.Name;
        insert opp;

        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, STRDRAFT, STRNONE);
        proposal.Apttus_QPConfig__PricingDate__c = System.today()+1;
        proposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
        proposal.Apttus_Proposal__Primary_Contact__c = con.id;
        proposal.Invalid_Quote__c = false;
        proposal.SAP_Quote__c='SAP dummy';
        insert proposal;

        List<Id> lstEmailTemplateIds = TestDataEmailTemplate.getEmailTemplates();
    }
	/**
	*  @author Dushyant Srivastava
	*  @description Cart Email Test Method
	**/
	@isTest
    static void testCartEmail()
    {
        Contact con = [Select id, name from Contact Limit 1];

		Apttus_Proposal__Proposal__c proposal = [Select id,name,Apttus_Proposal__Primary_Contact__r.Name,Apttus_QPConfig__PriceListId__c, Quote_Sub_Type__c, Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal' LIMIT 1];
		proposal.Apttus_Proposal__Primary_Contact__c = con.id;
        update proposal;

        MockApttusSAPConnector.strQuoteNumber = proposal.name;
		
        // Create cart
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = proposal.Id;
        Apttus_CPQApi.CPQWebService.createCart(request);
		
		Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id, Promo_Name_1__c, Promo_Name_2__c, Promo_Name_3__c, Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c, Apttus_QPConfig__Proposald__r.Quote_Type__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c from Apttus_Config2__ProductConfiguration__c LIMIT 1];
        objProductConfig.Apttus_Config2__IsPricePending__c = true;
        update objProductConfig;
		
		Test.setCurrentPageReference(new PageReference(PAGE_APTTUS_EMAIL_CART));
        System.currentPageReference().getParameters().put('businessObjectId', proposal.Id);
        System.currentPageReference().getParameters().put('flow', 'NGDefault');
        System.currentPageReference().getParameters().put('Id',objProductConfig.Id );

        ApttusEmailCartController objApttusEmailCartController = new ApttusEmailCartController();
        objApttusEmailCartController.emailCart();
        objApttusEmailCartController.redirectToCart();
		
		System.assertEquals('Test Proposal',proposal.Apttus_Proposal__Proposal_Name__c);
	}
}
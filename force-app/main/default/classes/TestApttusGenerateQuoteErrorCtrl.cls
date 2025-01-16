/*
 * @Author: Kushagra Desai
 * @Date: 2018-11-07
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Kushagra Desai                5-APR-2019                    DCP-24602 -Error stroing on generate
*  Kushagra Desai               7-July-2018                   Added Assert : ApttusGenerateQuoteErrorController()
*  Nishan Shetty                17-Jan-2022                   CodeScanFix- [Assert Argument Order]
*  Nishan Shetty                10-Oct-2022                   CodeScanFix [Method name should not start with Capital].
*  Adyasha Satapathy            12-Oct-2022                   Code Scan Fixes(Method Naming Convention)
*/
@isTest(isParallel=false)
public with sharing class TestApttusGenerateQuoteErrorCtrl {
	@isTest 
	static void apttusGenerateQuoteErrorController() {//CodeScanFix
		Account acc = TestDataAccount.getNewAccount();
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        insert opp;
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, 'Draft', 'None');
		insert proposal;
		Test.setCurrentPageReference(new PageReference('Page.ApttusGenerateQuoteError'));
		System.currentPageReference().getParameters().put('id',proposal.id);
		Test.startTest();
		ApttusGenerateQuoteErrorController objGenQuoteError=new ApttusGenerateQuoteErrorController();
        objGenQuoteError.redirectToQuote();
        objGenQuoteError.loadError();
        Test.stopTest();
        System.assertEquals(true,String.isBlank(proposal.SAP_Errors__c),'Error returned in MockCallout');//CodeScanFix [Assert Argument Order]
	}
	
	
}
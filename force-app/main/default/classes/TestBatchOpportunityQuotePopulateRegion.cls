/*@ author       : Satya Swain  
* @ date         : 12-12-2018
* @ Description  : Test class for batch to update child opportunities and quotation records when territory region is changed on account
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Satya Swain          	12-12-2018              Initial version
* KD 					18-June-2021			DCP-46224 : Update Relocation_type
* Arif,Dalali           28-Nov-2022             POL-57: Update APJ and EMEA References to AMEA and EUR respectively

*/
@isTest(isParallel=false)
public class TestBatchOpportunityQuotePopulateRegion{

	public static boolean dontRun = false;

	/**
    *  @author      : Satya Swain
    *  @description : Test Data Setup
    **/
    @testSetup
    public static void setupData(){
		dontRun = true;
    	Account acc1 = TestDataAccount.getAccount('Account 1');
        acc1.BillingCountryCode = 'US';
        acc1.BillingStateCode = 'AK';
        acc1.ERP_Customer_Id__c = '123456';
        
        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.ERP_Customer_Id__c = '345678';
        
        Account acc3 = TestDataAccount.getAccount('Account 3');
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'AK';
        acc3.ERP_Customer_Id__c = '567890';
        acc3.Account_Group__c = 'Distributor';
        
        Account acc4 = TestDataAccount.getAccount('Account 4');
        acc4.ERP_Customer_Id__c = '789012';
        acc4.BillingCountryCode = 'US';
        acc4.BillingStateCode = 'AK';
        acc4.Account_Group__c = 'Distributor';
        
        Account acc5 = TestDataAccount.getAccount('Account 5');
        acc5.BillingCountryCode = 'US';
        acc5.BillingStateCode = 'AK';
        acc5.ERP_Customer_Id__c = '565456';
        acc5.Account_Group__c = 'Distributor';
       

        insert new List<Account>{acc1,acc2,acc3,acc4,acc5};

        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('01-AMR-USD');
        insert objPriceList;

        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id;
		opp1.Current_Ultimate_Consignee__c = acc1.Id; //DCP-46224
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Ultimate_Consignee__c = acc1.Id;
		opp2.Current_Ultimate_Consignee__c = acc2.Id; //DCP-46224
        opp2.Distributor__c = acc3.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = true;
        Opportunity opp3 = TestDataOpportunity.initOpportunity(acc4,Label.OpportunityRTDirectStandard);
        opp3.Name = 'opp3';
        opp3.Ultimate_Consignee__c = acc1.Id;
        Opportunity opp4 = TestDataOpportunity.initOpportunity(acc4,Label.OpportunityRTIndirectStandard);
        opp4.Name = 'opp4';
        opp4.Ultimate_Consignee__c = acc3.Id;
        opp4.Distributor__c = acc5.Id;
        opp4.Direct_Sale_to_Ultimate_Consignee__c = true;
        Opportunity opp5 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTIndirectStandard);
        opp5.Name = 'opp5';
        opp5.Ultimate_Consignee__c = acc3.Id;
        opp5.Distributor__c = acc5.Id;
        opp5.Direct_Sale_to_Ultimate_Consignee__c = false;

        insert new List<Opportunity>{opp1,opp2,opp3,opp4,opp5};

        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(opp1.AccountId, opp1.id, 'Test Proposal 1', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(opp2.AccountId, opp2.id, 'Test Proposal 2', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        Apttus_Proposal__Proposal__c objProp3 = TestDataProposal.initProposal(opp3.AccountId, opp3.id, 'Test Proposal 3', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        Apttus_Proposal__Proposal__c objProp4 = TestDataProposal.initProposal(opp4.AccountId, opp4.id, 'Test Proposal 4', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        Apttus_Proposal__Proposal__c objProp5 = TestDataProposal.initProposal(opp5.AccountId, opp5.id, 'Test Proposal 5', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        insert new List<Apttus_Proposal__Proposal__c>{objProp1,objProp2,objProp3,objProp4,objProp5};
    }

    /**
    *  @author Satya Swain
    *  @description Test method for update region fields on opportunity and quotation
    **/
    static testmethod void checkRegionUpdateOnOpportunityAndQuote(){
    	List<Account> lstAccount = [SELECT Id, Name, Territory_Region__c from Account];
    	
    	Set<Id> setUpdatedAccountIds = new Set<Id>();
    	
    	Test.startTest();
    	
    	for(Account acc : lstAccount){
    		if(acc.Name == 'Account 1'){
    			acc.Territory_Region__c = 'AMR';
    		}
    		if(acc.Name == 'Account 2'){
    			acc.Territory_Region__c = 'EUR'; //POL-57
    		}
    		if(acc.Name == 'Account 3'){
    			acc.Territory_Region__c = 'AMEA'; //POL-57
    		}
    		if(acc.Name == 'Account 4'){
    			acc.Territory_Region__c = 'AMR';
    		}
    		if(acc.Name == 'Account 5'){
    			acc.Territory_Region__c = 'EUR'; //POL-57
    		}
    		setUpdatedAccountIds.add(acc.Id);
       	}
       	update lstAccount;

       	Database.executeBatch(new BatchOpportunityAndQuotePopulateRegion(setUpdatedAccountIds), 200);
       	
       	Test.stopTest();
       	
       	List<Opportunity> lstOpportunity = [SELECT Id, Name, Sold_To_Account_Region__c, Ultimate_Consignee_Region__c,AccountId,Ultimate_Consignee__c,Relocation_Type__c FROM Opportunity];
    	List<Apttus_Proposal__Proposal__c> lstQuotation = [SELECT Id,Name,Apttus_Proposal__Proposal_Name__c,Sold_To_Account_Region__c,Ultimate_Consignee_Region__c FROM Apttus_Proposal__Proposal__c];
    	for(Opportunity opp : lstOpportunity){
    		if(opp.Name == 'opp1'){
    			System.assertEquals('EUR',opp.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on oportunity: '+opp.Name); //POL-57
    			System.assertEquals('AMR',opp.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on opportunity: '+opp.Name);
				//DCP-46224
				System.assertEquals(Label.OpportunityRelocationStandard,opp.Relocation_Type__c,'Relocation Type Standard not set correctly');
			}
    		if(opp.Name == 'opp2'){
    			System.assertEquals('EUR',opp.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on oportunity: '+opp.Name); //POL-57
    			System.assertEquals('AMR',opp.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on opportunity: '+opp.Name);
				//DCP-46224
				System.assertEquals(Label.OpportunityRelocationTransRegion,opp.Relocation_Type__c,'Relocation Type trans region not set correctly');
    		}
    		if(opp.Name == 'opp3'){
    			System.assertEquals('AMR',opp.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on oportunity: '+opp.Name);
    			System.assertEquals('AMR',opp.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on opportunity: '+opp.Name);
    		}
    		if(opp.Name == 'opp4'){
    			System.assertEquals('AMR',opp.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on oportunity: '+opp.Name);
    			System.assertEquals('AMEA',opp.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on opportunity: '+opp.Name);	//POL-57
    		}
    		if(opp.Name == 'opp5'){
    			System.assertEquals('EUR',opp.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on oportunity: '+opp.Name); //POL-57
    			System.assertEquals('AMEA',opp.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on opportunity: '+opp.Name);	//POL-57
    		}
    	}
    	for(Apttus_Proposal__Proposal__c objQuotation : lstQuotation){
    		if(objQuotation.Name == 'Test Proposal 1'){
    			System.assertEquals('EUR',objQuotation.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on quotation: '+objQuotation.Name); //POL-57
    			System.assertEquals('AMR',objQuotation.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on quotation: '+objQuotation.Name);
    		}
			if(objQuotation.Name == 'Test Proposal 2'){
    			System.assertEquals('EUR',objQuotation.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on quotation: '+objQuotation.Name); //POL-57
    			System.assertEquals('AMR',objQuotation.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on quotation: '+objQuotation.Name);
    		}
    		if(objQuotation.Name == 'Test Proposal 3'){
    			System.assertEquals('AMR',objQuotation.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on quotation: '+objQuotation.Name);
    			System.assertEquals('AMR',objQuotation.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on quotation: '+objQuotation.Name);
    		}
    		if(objQuotation.Name == 'Test Proposal 4'){
    			System.assertEquals('AMR',objQuotation.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on quotation: '+objQuotation.Name);
    			System.assertEquals('AMEA',objQuotation.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on quotation: '+objQuotation.Name); //POL-57
    		}
    		if(objQuotation.Name == 'Test Proposal 5'){
    			System.assertEquals('EUR',objQuotation.Sold_To_Account_Region__c,'Territory Region of Sold To Account not updated on quotation: '+objQuotation.Name); //POL-57
    			System.assertEquals('AMEA',objQuotation.Ultimate_Consignee_Region__c,'Territory Region of Ultimate Consignee not updated on quotation: '+objQuotation.Name); //POL-57
    		}
    	}
    }
}
/*@ author       : Roopal Verma
* @ date         : 29-11-2018
* @ Description  : Batch to update child opportunities and quotation record for Sales area extension.
* Test Class for 75%: TestBatchUpdateChildRecordsForNewASA, TestCustomerMasterDataReceiver
* Test Class for 90%: TestBatchUpdateChildRecordsForNewASA, TestCustomerMasterDataReceiver
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Roopal Verma          29-11-2018                 Initial version
* Satya Swain			28-08-2019				   Added partial success for update as part of PRB0042658
* KD                    29-Jun-2021                DCP-46226: Payment term defaulting for Greater china
* Todd                  02-Sep-2021                DCP-49395: add deferrable support
* Iram Malik			05-Jul-2022				   Codescan fix: remove unused local variable
* Jitesh Lakhwani       6-July-2022		           Code Scan fixes of Comments
* Iram Malik			14-Jul-2022				   Codescan Fix: logic inversion
* Nitin Reddy			12-sep-2022				   CMSI-206 Instrumentation 
*/
global inherited sharing class BatchUpdateChildRecordsForNewASA extends ilib_BatchDeferrable {
	private static final String LOG_TITLE = 'BatchUpdateChildRecordsForNewASA';
	public static final String NULLSTR = 'Null';
	/**
    * @description: Parameter wrapper for easy serialization.
    * @param : None
    * @return: None
    */
    public class Inputs
    {
        public List<Account_Sales_Area__c> lstNewASA;

		/**
		* @description: Parameterized Constructor of Input wrapper class
		* @param : List<Account_Sales_Area__c> lstNewASA
		* @return: None
		*/
        public Inputs(List<Account_Sales_Area__c> lstNewASA)
        {
            this.lstNewASA = lstNewASA;
        }
    }
    private Inputs inputs;

    /* required to reinstantiate after deferral */
    global BatchUpdateChildRecordsForNewASA() { }

	/* specify sales area records which define quote/opportunity children that will be updated */
    global BatchUpdateChildRecordsForNewASA(List<Account_Sales_Area__c> lstNewASA) {
        this.inputs = new Inputs(lstNewASA);
    }

	/* determine scope of child records */
    global override Database.QueryLocator start(Database.BatchableContext bc)
    {
		ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
		ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);
		ilib_LogEvent.push(LOG_TITLE + '.start()');
  		Set<Id> setAccountId = UtilsCollection.getSetOfIds(inputs.lstNewASA, 'Account__c');
        Set<String> setQuoteStage = new Set<String> { Label.QuoteStageDraft, Label.QuoteStageApprovalRequired };
        Set<String> setOppStage = Opportunities.CLOSED_STATUSES;
		ilib_LogEvent.info('setAccountId : '+setAccountId);
		ilib_LogEvent.info('setQuoteStage : '+setQuoteStage);
		ilib_LogEvent.info('setOppStage : '+setOppStage);
		// DCP-46226
        String query = 'SELECT Id,Name,Sales_Area_Ultimate_Consignee__c,Sales_Area_Sold_To__c,Ship_To_Sales_Org__c,'
            + 'Sales_Area_Distributor__c,AccountId,Ultimate_Consignee__c,Distributor__c,RecordTypeId,RecordType.DeveloperName,Product_Interest__c,Account.BillingCountry, ' // DCP-46226
            + 'Sales_Org_Override__c,Direct_Sale_to_Ultimate_Consignee__c,Billing_Country_Sold_To__c, '
            + '(SELECT Id,Apttus_Proposal__Proposal_Name__c,Bill_To__c, '
            + 'Payer__c, Apttus_Proposal__Payment_Term__c, Ship_To__c,Apttus_Proposal__Approval_Stage__c,'
            + 'Inco_Term_1__c,Opportunity_Record_Type__c,Direct_Sale_to_Ultimate_Consignee__c,Apttus_Proposal__Opportunity__c '
            + 'FROM R00N70000001yUfDEAU '
            + 'WHERE Apttus_Proposal__Approval_Stage__c IN :setQuoteStage AND Invalid_Quote__c = false) '
            + ' FROM Opportunity '
            + ' WHERE (StageName NOT IN :setOppStage '
            + 'AND ( AccountId IN :setAccountId OR Ultimate_Consignee__c IN :setAccountId OR Distributor__c IN :setAccountId ) )';
		ilib_LogEvent.info('query : '+query);
		ilib_LogEvent.pop();
		ilib_LogEvent.emit();
        return Database.getQueryLocator(query);
    }

	/* update child records */
    global override void execute(Database.BatchableContext bc, list<Sobject> scope)
    {
		ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
		ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
		List<Opportunity> lstOpportunity = (List<Opportunity>)scope;
		ilib_LogEvent.info('lstOpportunity : '+UtilsCollection.getSetOfIds(lstOpportunity));
		
		Map<Id, Opportunity> idToOpp = new Map<Id, Opportunity>(lstOpportunity);

		Set<String> setASAERPId = new Set<String>();
		setASAERPId = UtilsCollection.getSetOfStrings(inputs.lstNewASA, 'ERP_Account_Sales_Area_Id__c');
		ilib_LogEvent.info('setASAERPId : '+setASAERPId);
		

		Set<Id> setAccountId = new Set<Id>();
  		setAccountId = UtilsCollection.getSetOfIds(inputs.lstNewASA, 'Account__c');
		
		for (Opportunity opp:lstOpportunity)
        {
			setAccountId.add(opp.AccountId);
			setAccountId.add(opp.Ultimate_Consignee__c);
			setAccountId.add(opp.Distributor__c);
		}
		ilib_LogEvent.info('setAccountId : '+setAccountId);
		Map<Id, Account> idToAccount = new Map<Id, Account>(new AccountsSelector().selectAccounts(setAccountId));

		
		Map<String, List<Apttus_Proposal__Proposal__c>> soldToERPIdToProposal = new Map<String, List<Apttus_Proposal__Proposal__c>>()
            , ucERPIdToProposal = new Map<String, List<Apttus_Proposal__Proposal__c>>();
		Map<String, List<Account_Sales_Area__c>> uCERPToDistSalesArea = new Map<String, List<Account_Sales_Area__c>>();
		Map<Id, String> disIdToUCERP = new Map<Id, String>();
		Map<String, String> soldToERPToSAERP = new Map<String, String>()
            , ucERPToSAERP = new Map<String, String>()
            , accountERPToCountry = new Map<String, String>();

		Map<Id, List<Opportunity>> changedSoldToIdToOpp = new Map<Id, List<Opportunity>>()
            , changedUCIdToOpp = new Map<Id, List<Opportunity>>()
            , changedDisIdToOpp = new Map<Id, List<Opportunity>>();

		Boolean booIndirectDeal;
		List<Opportunity> lstOppReturnSA = new List<Opportunity>();
		List<Opportunity> lstOppReturned = new List<Opportunity>();

		//Creating maps and sets for AutomatePricelistFieldsService method
		for (Opportunity opp : lstOpportunity)
        {
			List<Opportunity> lstUCOpp = changedUCIdToOpp.get(opp.Ultimate_Consignee__c);
			List<Opportunity> lstDisOpp = changedDisIdToOpp.get(opp.Distributor__c);

			String strRecordTypeName = Opportunities.getIdToRecordType().get(opp.RecordTypeId).getDeveloperName();
			booIndirectDeal= Opportunities.INDIRECT_RECORD_TYPES.contains(strRecordTypeName);
			ilib_LogEvent.message('strRecordTypeName : '+strRecordTypeName);
			ilib_LogEvent.message('booIndirectDeal : '+booIndirectDeal);
			if (setASAERPId.contains(opp.Sales_Area_Sold_To__c) || (opp.Sales_Area_Sold_To__c == null && opp.AccountId != null))
            {
				List<Opportunity> lstSoldToOpp = changedSoldToIdToOpp.get(opp.AccountId);
                if (lstSoldToOpp == null || lstSoldToOpp.isEmpty())
                    lstSoldToOpp = new List<Opportunity>();
                lstSoldToOpp.add(opp);
                changedSoldToIdToOpp.put(opp.AccountId, lstSoldToOpp);
			}

			if (setASAERPId.contains(opp.Sales_Area_Ultimate_Consignee__c) || (opp.Sales_Area_Ultimate_Consignee__c == null && opp.Ultimate_Consignee__c != null))
            {
				if (lstUCOpp == null || lstUCOpp.isEmpty())
					lstUCOpp = new List<Opportunity>();
				lstUCOpp.add(opp);
				changedUCIdToOpp.put(opp.Ultimate_Consignee__c, lstUCOpp);
				if (opp.Sales_Area_Sold_To__c == null)
                {
                    List<Opportunity> lstSoldToOpp = changedSoldToIdToOpp.get(opp.AccountId);
                    if (lstSoldToOpp == null)
                        lstSoldToOpp = new List<Opportunity>();
                    lstSoldToOpp.add(opp);
                    changedUCIdToOpp.put(opp.AccountId, lstSoldToOpp);
                }
			}

			if (booIndirectDeal)
            {
				if (setASAERPId.contains(opp.Sales_Area_Distributor__c) || (opp.Sales_Area_Distributor__c == null && opp.Distributor__c != null))
                {
					if (lstDisOpp == null || lstDisOpp.isEmpty())
						lstDisOpp = new List<Opportunity>();
					lstDisOpp.add(opp);
					changedDisIdToOpp.put(opp.Distributor__c, lstDisOpp);
					if (opp.Sales_Area_Sold_To__c == null)
                    {
	                    List<Opportunity> lstSoldToOpp = changedSoldToIdToOpp.get(opp.AccountId);
                        if (lstSoldToOpp == null)
                            lstSoldToOpp = new List<Opportunity>();
	                    lstSoldToOpp.add(opp);
	                    changedDisIdToOpp.put(opp.AccountId, lstSoldToOpp);
	                }
				}
			}

			if (String.isBlank(opp.Sales_Area_Sold_To__c) || String.isBlank(opp.Sales_Area_Ultimate_Consignee__c) || (booIndirectDeal && String.isBlank(opp.Distributor__c)))
            {
				AutomatePricelistFieldsService.stampSalesAreaIdFields(changedSoldToIdToOpp,changedUCIdToOpp,changedDisIdToOpp,true);
				lstOppReturnSA.add(opp);
			}

			if ((!booIndirectDeal && (changedSoldToIdToOpp != null || changedUCIdToOpp != null)) || (booIndirectDeal && changedDisIdToOpp != null))
            {
				AutomatePricelistFieldsService.stampPricelistFields(changedSoldToIdToOpp,changedUCIdToOpp,changedDisIdToOpp,changedSoldToIdToOpp.keySet(),true);
				lstOppReturned.add(opp);
			}

			if (opp.R00N70000001yUfDEAU != null)
            {
				//Creating maps for AutomateBillToShipToService method
				for ( Apttus_Proposal__Proposal__c objProposal : opp.R00N70000001yUfDEAU)
                {
					String strSoldToERPId = idToAccount.get(opp.AccountId).ERP_Customer_Id__c;
					String strUCERPId = idToAccount.get(opp.Ultimate_Consignee__c).ERP_Customer_Id__c;
					ilib_LogEvent.fine('strSoldToERPId : '+strSoldToERPId);
					ilib_LogEvent.fine('strUCERPId : '+strUCERPId);
					if (setASAERPId.contains(opp.Sales_Area_Sold_To__c))
                    {
						if (String.isNotBlank(strSoldToERPId))
                        {
							if (soldToERPIdToProposal.containsKey(strSoldToERPId))
								soldToERPIdToProposal.get(strSoldToERPId).add(objProposal);
							else
								soldToERPIdToProposal.put(strSoldToERPId, new List<Apttus_Proposal__Proposal__c>{objProposal});
								soldToERPToSAERP.put(strSoldToERPId,opp.Sales_Area_Sold_To__c);
						}
					}

					if (booIndirectDeal)
                    {
						String strDisERPId = idToAccount.get(opp.Distributor__c).ERP_Customer_Id__c;
						ilib_LogEvent.fine('strDisERPId : '+strDisERPId);
						disIdToUCERP.put(opp.Distributor__c,strUCERPId);
						if (setASAERPId.contains(opp.Sales_Area_Distributor__c)
							&& String.isNotBlank(strDisERPId)
							&& !opp.Direct_Sale_to_Ultimate_Consignee__c
                        ) {
                            if (ucERPIdToProposal.containsKey(strDisERPId))
                                ucERPIdToProposal.get(strDisERPId).add(objProposal);
                            else
                                ucERPIdToProposal.put(strDisERPId, new List<Apttus_Proposal__Proposal__c>{objProposal});
						}
						else if (opp.Direct_Sale_to_Ultimate_Consignee__c)
                        {
                            if(ucERPIdToProposal.containsKey(strUCERPId))
                                ucERPIdToProposal.get(strUCERPId).add(objProposal);
                            else
                                ucERPIdToProposal.put(strUCERPId, new List<Apttus_Proposal__Proposal__c>{objProposal});
						}
					}
					else
                    {
						if (setASAERPId.contains(opp.Sales_Area_Ultimate_Consignee__c))
                        {
							if (String.isNotBlank(strUCERPId))
                            {
								if (ucERPIdToProposal.containsKey(strUCERPId))
									ucERPIdToProposal.get(strUCERPId).add(objProposal);
								else
    								ucERPIdToProposal.put(strUCERPId, new List<Apttus_Proposal__Proposal__c>{objProposal});
			    				ucERPToSAERP.put(strUCERPId,opp.Sales_Area_Ultimate_Consignee__c);
		    					accountERPToCountry.put(strUCERPId,idToAccount.get(opp.Ultimate_Consignee__c).BillingCountry);
	    					}
				    	}
				    }
    			}

				if(disIdToUCERP != null)
                {
					Set<Id> setDistributorId = new Set<Id>();
					List<Account_Sales_Area__c> lstAccountSalesArea = new List<Account_Sales_Area__c>();
					setDistributorId = disIdToUCERP.keyset();
					ilib_LogEvent.message('setDistributorId : '+setDistributorId);
					if (!setDistributorId.isEmpty())
                    {
						lstAccountSalesArea = new AccountSalesAreaSelector().selectAccountSaleaArea(setDistributorId);
						for (Account_Sales_Area__c asa : lstAccountSalesArea)
                        {
							String strUCERPId = disIdToUCERP.get(asa.Account__c);
							ilib_LogEvent.fine('strUCERPId : '+strUCERPId);
							if(uCERPToDistSalesArea.containsKey(strUCERPId))
								uCERPToDistSalesArea.get(strUCERPId).add(asa);
							else
							uCERPToDistSalesArea.put(strUCERPId,new List<Account_Sales_Area__c> {asa});
						}
					}
				}
			}
		}
		ilib_LogEvent.info('changedSoldToIdToOpp : '+(changedSoldToIdToOpp != Null ? String.valueof(changedSoldToIdToOpp.keySet()):NULLSTR));
		ilib_LogEvent.info('changedUCIdToOpp : '+(changedUCIdToOpp != Null ? String.valueof(changedUCIdToOpp.keySet()):NULLSTR));
		ilib_LogEvent.info('changedDisIdToOpp : '+(changedDisIdToOpp != Null ? String.valueof(changedDisIdToOpp.keySet()):NULLSTR));
		ilib_LogEvent.info('soldToERPIdToProposal : '+(soldToERPIdToProposal != Null ? String.valueof(soldToERPIdToProposal.keySet()):NULLSTR));
		ilib_LogEvent.info('ucERPIdToProposal : '+(ucERPIdToProposal != Null ? String.valueof(ucERPIdToProposal.keySet()):NULLSTR));
		ilib_LogEvent.info('uCERPToDistSalesArea : '+(uCERPToDistSalesArea != Null ? String.valueof(uCERPToDistSalesArea.keySet()):NULLSTR));
		ilib_LogEvent.info('soldToERPToSAERP : '+soldToERPToSAERP);
		ilib_LogEvent.info('ucERPToSAERP : '+ucERPToSAERP);
		ilib_LogEvent.info('accountERPToCountry : '+accountERPToCountry);
		if (lstOppReturnSA != null)
        {
			// Added for PRB0042658
			List<Database.SaveResult> srListOppReturnSA = Database.update(lstOppReturnSA, false);
			ApexExceptions.emitSaveErrors(srListOppReturnSA, LOG_TITLE);
		}
		//DCP-46226
		Map<Id,Apttus_Proposal__Proposal__c> idToProposalUpdated = AutomateBillToShipToService.setBillToShipTo(soldToERPIdToProposal, ucERPIdToProposal, uCERPToDistSalesArea, soldToERPToSAERP, ucERPToSAERP, accountERPToCountry,idToOpp);
		ilib_LogEvent.info('idToProposalUpdated : '+(idToProposalUpdated != Null ? String.valueof(idToProposalUpdated.keySet()):NULLSTR));
		if (idToProposalUpdated != null)
        {
			// Added for PRB0042658
			List<Database.SaveResult> srListProposalReturned = Database.update(idToProposalUpdated.values(), false);
			ApexExceptions.emitSaveErrors(srListProposalReturned, LOG_TITLE);
		}

		if (lstOppReturned != null)
        {
			// Added for PRB0042658
			List<Database.SaveResult> srListOptyReturned = Database.update(lstOppReturned, false);
			ApexExceptions.emitSaveErrors(srListOptyReturned, LOG_TITLE);
		}
		ilib_LogEvent.pop();
		ilib_LogEvent.emit();
	}

	/* no op */
    global override void finish(Database.BatchableContext bc) {
		ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
		ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);
		ilib_LogEvent.push(LOG_TITLE + '.finish()');
		ilib_LogEvent.pop();
		ilib_LogEvent.emit();
	 }


    // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************

    /* simple input serialization */
    public override String serializeInputs()
    {
		ilib_LogEvent.push(LOG_TITLE + '.serializeInputs()');
		ilib_LogEvent.pop();
        return JSON.serialize(inputs);
    }

    /* simple input deserialization */
    public override void restoreInputs(String serializedInputs)
    {
		ilib_LogEvent.push(LOG_TITLE + '.restoreInputs()');
        this.inputs = (BatchUpdateChildRecordsForNewASA.Inputs)JSON.deserialize(serializedInputs, BatchUpdateChildRecordsForNewASA.Inputs.class);
		ilib_LogEvent.pop();
    }

    /* default val */
    public override Integer getDefaultBatchSize()
    {
		ilib_LogEvent.push(LOG_TITLE + '.getDefaultBatchSize()');
		ilib_LogEvent.info('Returning 100');
		ilib_LogEvent.pop();
        return 100;
    }

}
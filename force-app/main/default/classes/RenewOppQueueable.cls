/**
*	@author Rahul Bishnoi
*	@date	 2019-11-29
*	@description	DCP-30367: Create Renewal Opportunity and line items.
*   @90% coverage Test Classes - TestOpportunities, TestPricingAndValidationCallback 
*   @75% coverage Test Classes - TestOpportunities, TestPricingAndValidationCallback 
*	Modification Log:
*	------------------------------------------------------------------------------------
*			Developer					Date				Description
*			Rahul Bishnoi				2019-11-29
*           Rahul Bishnoi               2020-01-27          Populating ERP_Line_Number_Id__c
*           Akshay Mohan                2020-03-11          Handle error scenarios for row lock
*           Rahul Bishnoi               2020-09-08          Incident INC0285298
*			Maruthi						2021-09-09			IP2-51
*           Ashwin                      2021-12-14          INC0362941: Update static boolean to true so that Reprice is bypassed for Renewal Quotes
*           Ashwin                      2022-01-06          INC0369726: Log Exception after 3 tries 
*           Aman Tyagi                  2022-03-31          CodeScan Fixes
*           Adyasha                     2022-06-06          DCP-52331: Do not create Renewal Opportunity/ OLI for specific products
*           Biswajeet                   2022-08-22          [CMSI-200] : Instrumentation of the class
*           Adyasha Satapathy           24-Nov-2022         POL-54: Update region references to AMEA and EUR 
*           Raja Babu                   24-Nov-2022         added ForecastCategoryName value for opp cloning
*	------------------------------------------------------------------------------------
**/
public without sharing class RenewOppQueueable implements System.Queueable {

    private static final String LOG_TITLE = 'RenewOppQueueable';
    private static final Integer MAX_RETRIES = 10;
    private static final String CODE_PARAMETER_RENEWAL_EXCEPTION_PRODUCTS = 'Renewal_Oppty_Exceptions_Product_Codes'; // DCP - 52331
    private static final String NOT_FORECASTED = 'Not Forecasted';

    public Map<Id, Opportunity> mapClosedWonOppIds {get; set;} // Map of Opp's which are informatics opp and status is closed won.
    Integer intRetryCount ; // how many tries so far?
    String mailBody; // mail to send in case of an error
    /* This is the constructor */
    public RenewOppQueueable(Map<Id, Opportunity> mapClosedWonOppIds, Integer intRetryCount) {        
        this.mapClosedWonOppIds = mapClosedWonOppIds;
        this.intRetryCount = intRetryCount;
    }
    /* This is the Excecute */
    public void execute(System.QueueableContext qc) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES); //CMSI-200 passed workstream in the params  
        ilib_LogEvent.push(LOG_TITLE+'.execute()');   //CMSI-200
        //if map contains values then fetch informatics product codes.
        if (mapClosedWonOppIds == null || mapClosedWonOppIds.isEmpty()) {
            ilib_LogEvent.emit();
            return;
        }

        Savepoint sp = Database.setSavepoint(); //savepoint to rollback if exception occurs

        try {
            ilib_LogEvent.info('Retry Count: ' + intRetryCount);   //CMSI-200
            mailBody = 'Renewable Opportunity creation Process Failed! \nDebug Statements:';
            createOppWithQuote();
            ilib_LogEvent.pop();
        }
        catch(Exception e) {
            ilib_LogEvent.info('Rolling back Database Changes');
            ilib_LogEvent.info('Exception Generated RenewOppQueueable : '+e);

            Database.rollback(sp); // rollback to undo any opportunity insertions if quote/quote line item insertion fails.

            if (intRetryCount < MAX_RETRIES) {
                RenewOppQueueable queueableClassInstance = new RenewOppQueueable(mapClosedWonOppIds,++intRetryCount);
                ilib_Queueablethread queueableThread = new ilib_Queueablethread('Opportunities');
                queueableThread.logAndQueue(queueableClassInstance, 'RenewOppQueueable', 'execute');
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
            }
            else {
                ilib_LogEvent.push(LOG_TITLE + '.execute() else block');
                ApexExceptions.emit(LOG_TITLE, e);      //INC0369726
                List<Code_Parameter__mdt> lstCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String> {'IlluminaSalesCommercialAMSDL'});
                String strGISAMSEmailAddress = '';
                if(!lstCodeParam.isEmpty()) { strGISAMSEmailAddress = lstCodeParam[0].value__c; }
                mailBody = mailBody + '\nException Message: ' + e.getMessage();
                Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
                semail.setTargetObjectId(UserInfo.getUserId());
                String[] strCcAddresses = new String[]{strGISAMSEmailAddress};
                semail.setCcAddresses(strCcAddresses);
                // semail.setCcAddresses(sendingTocAdd); 
                semail.setPlainTextBody(mailBody); 
                semail.setSaveAsActivity(false);
                semail.setSubject('Opportunity Renewal Failed!');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail}); 
                ilib_LogEvent.message('Sync Failure Mail sent');
                ilib_LogEvent.pop();
            }
        } finally {
            ilib_LogEvent.emit();
        }
    }

    /*
    * @Author: Maruthi
    * @Description : this method has logic for creating opp with quote
    * @param : null
    * @return : void
    */
    public void createOppWithQuote() {
        ilib_LogEvent.push(LOG_TITLE + '.createOppWithQuote()');
		Id userID = null;
        Map<String,Map<String,String>> territoryUserIdsMap = new Map<String,Map<String,String>>();
        Map<String, String> mapAccIdToUserId = new Map<String, String>();
        Map<String,String> mapAccIdToTerrName = new Map<String,String>();
        Map<String, String> mapTerNameUsrId = new Map<String, String>();
        String strmapAccIdToUserId = 'mapAccIdToUserId';
        String strMapAccIdToTerrName = 'mapAccIdToTerrName';
        String strMapTerNameUsrId = 'mapTerNameUsrId';               
        
        List<Opportunity> lstRenewalOpportunities = new List<Opportunity>();
        mailBody = mailBody + '\nSet of Opportunity Ids = ' + mapClosedWonOppIds.keySet() ;
        List<OpportunityLineItem> lstAllOptyLineItems = new OpportunityLineItemsSelector().selectOpportunityLineItems(mapClosedWonOppIds.keySet());
        Map<Id, List<OpportunityLineItem>> oppIdToInformaticsLineItems = new Map<Id, List<OpportunityLineItem>>();

        //DCP - 52331
        List<String> lstProducts = new List<String>();
        Code_Parameter__mdt objCodeParameter = Code_Parameter__mdt.getInstance(CODE_PARAMETER_RENEWAL_EXCEPTION_PRODUCTS);
        lstProducts = objCodeParameter.Values_Text__c.split(';');
        //End of DCP - 52331

        for (OpportunityLineItem oli : lstAllOptyLineItems) {
            if (!oli.Has_Informatics_Product__c) continue;           

            if (!oppIdToInformaticsLineItems.containsKey(oli.OpportunityId)) oppIdToInformaticsLineItems.put(oli.OpportunityId, new List<OpportunityLineItem>());               
            oppIdToInformaticsLineItems.get(oli.OpportunityId).add(oli);
        }
        ilib_LogEvent.info('oppIdToInformaticsLineItems: ' + oppIdToInformaticsLineItems);   //CMSI-200

        List<Apttus_Proposal__Proposal__c> objProposal = new ApttusProposalsSelector().selectPrimary(mapClosedWonOppIds.keySet());
        if (objProposal.isEmpty()) {
            mailBody = mailBody + '\n Primary Quote not found \n';
            ApexExceptions.emit(LOG_TITLE, '', 'Primary Quote not found for ' + mapClosedWonOppIds.keyset());
            ilib_LogEvent.pop();
            return;
        }

        // QUESTION: how would this work if there are multiple opportunities?
        // why only one quote, shouldn't it be one per opportunity?
        List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems = new ApttusProposalLineItemsSelector().selectByQuoteId(new Set<Id>{objProposal[0].id});

        Set<Id> qliIds = UtilsCollection.getSetOfIds(lstProposalLineItems);
        List<Apttus_Config2__OrderLineItem__c> lstOrderLineItems = new List<Apttus_Config2__OrderLineItem__c>(new ApttusOrderLineItemsSelector().fetchbyQuoteLineItemId(qliIds));
        ilib_LogEvent.info('lstOrderLineItems --> ' + lstOrderLineItems);    //CMSI-200

        Map<Id, Apttus_Config2__OrderLineItem__c> qliIdToOrderLineItem = new Map<Id, Apttus_Config2__OrderLineItem__c>();
        for(Apttus_Config2__OrderLineItem__c orderLi : lstOrderLineItems) {
            qliIdToOrderLineItem.put(orderLi.Apttus_QPConfig__ProposalLineItemId__c, orderLi);
        }
        ilib_LogEvent.info('qliIdToOrderLineItem --> ' + qliIdToOrderLineItem);    //CMSI-200

        List<OpportunityLineItem> lstOldInformaticsLineItems = new List<OpportunityLineItem>();
        List<OpportunityLineItem> lstRenewalInformaticsLineItems = new List<OpportunityLineItem>();

        Date renewatCloseDate = Date.newinstance(2999, 12, 31); //Store earliest end date.
		territoryUserIdsMap = getTerritoryUsers(mapClosedWonOppIds);
        mapAccIdToUserId = territoryUserIdsMap.get(strmapAccIdToUserId);
        mapAccIdToTerrName = territoryUserIdsMap.get(strMapAccIdToTerrName);
        mapTerNameUsrId = territoryUserIdsMap.get(strMapTerNameUsrId);
        //Loop through all closed won opp, to create renewal opp.
        for (Opportunity opp : mapClosedWonOppIds.values()) {
            // QUESTION: if there are no line items should we be creating the renewal opportunity?
            if (oppIdToInformaticsLineItems.containsKey(opp.id)) {
                //DCP - 52331
                if(oppIdToInformaticsLineItems.get(opp.id).size() == 1 && lstProducts.contains(oppIdToInformaticsLineItems.get(opp.id)[0].ProductCode)) {
                    continue;
                }
                //End of DCP - 52331
                for (OpportunityLineItem oli : oppIdToInformaticsLineItems.get(opp.id)) {
                    if(lstProducts.contains(oli.ProductCode)) {continue;} // DCP - 52331

                    ilib_LogEvent.message('product code: ' + oli.ProductCode);
                    ilib_LogEvent.message('OutmAP -- ' + oli.id +' -- ' + opp.id);

                    //set new dates for opp line items.
                    for (Apttus_Proposal__Proposal_Line_Item__c qli : lstProposalLineItems) {
                        if (oli.Quote_Line_Item__c == qli.Id) {
                            if (qli.Apttus_QPConfig__StartDate__c != null && qli.Apttus_QPConfig__EndDate__c != null) {                                
                                renewatCloseDate = renewatCloseDate > qli.Apttus_QPConfig__EndDate__c ? qli.Apttus_QPConfig__EndDate__c : renewatCloseDate;
                                Integer daysBtwn = qli.Apttus_QPConfig__StartDate__c.daysBetween(qli.Apttus_QPConfig__EndDate__c);
                                oli.Start_Date__c = qli.Apttus_QPConfig__EndDate__c.addDays(1);
                                oli.End_Date__c = oli.Start_Date__c.addDays(daysBtwn);
                                ilib_LogEvent.fine('qli.Id -->' + qli.Id);       //CMSI-200
                            }

                            if (qliIdToOrderLineItem.containsKey(qli.Id)) {
                                oli.ERP_Line_Number_Id__c = qliIdToOrderLineItem.get(qli.Id).ERP_Line_Number_Id__c;
                                oli.Serial_Number__c = qliIdToOrderLineItem.get(qli.Id).Serial_Number__c;
                            }
                        }
                    }
                    lstOldInformaticsLineItems.add(oli);
                }
            }  
            ilib_LogEvent.message('renewatCloseDate -- ' + renewatCloseDate);

            Opportunity renewalopp = opp.clone(false, false);
            renewalopp.CloseDate = renewatCloseDate;
            String recordTypeDevName = Opportunities.getIdToRecordType().get(opp.RecordTypeId).getDeveloperName();
            String oppName = 'Informatics Auto Renewal' + renewatCloseDate.format() + opp.Name;
            renewalopp.Name = oppName.abbreviate(120);
            renewalopp.RecordTypeId = getOpportunityRecordId(recordTypeDevName);
            renewalopp.AccountId = opp.AccountId;
            renewalopp.Type = Label.OpportunityTypeRenewalSoftwareNoUpsell;
            renewalopp.Amount = opp.Amount;
            renewalopp.StageName = Label.OpportunityStageDevelop;
            renewalopp.Probability = 40;
            renewalopp.Product_Interest__c = Label.ProductInterestSoftware;
            ilib_LogEvent.message('mapAccIdToUserId--->'+mapAccIdToUserId);
            ilib_LogEvent.message('mapAccIdToTerrName--->'+mapAccIdToTerrName);

            userId = getUserId(opp, mapAccIdToUserId, mapAccIdToTerrName, mapTerNameUsrId);                
            if(userID != null) { renewalopp.OwnerId = userID; }
            renewalopp.NextStep = null;
            renewalopp.Related_Opportunity__c = opp.Id;
            renewalopp.First_Proposal_Id__c = '';
            renewalopp.Proposal_Sent_On__c = null;
            renewalopp.Legacy_SFDC_Record_ID__c = null;
            renewalopp.Is_Converted_From_Lead__c = 'No';
            renewalopp.ForecastCategoryName = NOT_FORECASTED;
            ilib_LogEvent.message('renewalopp: ' + renewalopp);

            lstRenewalOpportunities.add(renewalopp);
        }

        ilib_LogEvent.info('lstRenewalOpportunities: ' + lstRenewalOpportunities);     //CMSI-200
        if (!lstRenewalOpportunities.isEmpty()) {
            insert lstRenewalOpportunities;
            ilib_LogEvent.info('Renewal Opportunity Id : '+lstRenewalOpportunities[0].Id);
            mailBody = mailBody + ' \nOpportunity creation was successfull. ';
        }
        
        //for all related opp, create new opp line items.
        ilib_LogEvent.message('lstOldInformaticsLineItems : ' + lstOldInformaticsLineItems);
        for(OpportunityLineItem oli : lstOldInformaticsLineItems) {            
            OpportunityLineItem renewalOLI = oli.clone(false,false);
            for (Opportunity opp : lstRenewalOpportunities) {
                if (oli.OpportunityId.equals(opp.Related_Opportunity__c)) {
                    renewalOLI.OpportunityId = opp.Id;
                }
            }
            renewalOLI.TotalPrice = null;
            renewalOLI.Product2Id = oli.Product2Id;
            renewalOLI.PricebookEntryId = oli.PricebookEntryId;
            lstRenewalInformaticsLineItems.add(renewalOLI); 
        }

        if (!lstRenewalInformaticsLineItems.isEmpty()) {
            insert lstRenewalInformaticsLineItems;
            mailBody = mailBody + '\nOpportunity Line Item creation was successfull. ';
        }

        if(lstRenewalOpportunities.isEmpty()) {  //DCP-52331
            ilib_LogEvent.pop();
            return; 
        }
        //for all related quotations, create new renewal quotations.
        Apttus_Proposal__Proposal__c  renewObjProposal = objProposal[0].clone(false,false); 
        for (Opportunity opp : lstRenewalOpportunities) {
            if (objProposal[0].Apttus_Proposal__Opportunity__c.equals(opp.Related_Opportunity__c) && objProposal[0].Apttus_Proposal__Primary__c == true) {
                renewObjProposal.Apttus_Proposal__Opportunity__c = opp.Id;
                renewObjProposal.Apttus_Proposal__ExpectedStartDate__c = Date.today();
                renewObjProposal.Apttus_Proposal__ExpectedEndDate__c = null;
                renewObjProposal.Apttus_Proposal__Approval_Stage__c = Label.QuoteStageDraft;
                renewObjProposal.Apttus_QPApprov__Approval_Status__c = Label.QuoteApprovalStatusNone;
                renewObjProposal.Prepared_by__c = UserInfo.getUserid();
                renewObjProposal.SAP_Quote__c = null;
                renewObjProposal.Generated_Date__c = null;
                renewObjProposal.Is_Updated_By_System__c = true;
                renewObjProposal.Cloned_From__c = renewObjProposal.getCloneSourceId();
                renewObjProposal.Apttus_QPConfig__PricingDate__c = null;
                renewObjProposal.Quote_Output_Generated_Valid_From_Date__c = null;
                renewObjProposal.Apttus_Proposal__Presented_Date__c = null;
                renewObjProposal.Apttus_Proposal__Proposal_Approval_Date__c = null;
            }  	
        }

        if (UserInfo.isCurrentUserLicensed('Apttus_Proposal')) {
            ApttusProposals.boolByPassReprice = true;       //INC0362941
            insert renewObjProposal;
            mailBody = mailBody + '\nQuotation creation was successfull. ';
        } else {
            ApexExceptions.emit(LOG_TITLE, '', 'User does not have permission to create a Quote : ' + mapClosedWonOppIds.keyset());
            mailBody = mailBody + '\nUser does not have permission to create a Quote. ';
        }
        ilib_LogEvent.pop();
    }

    /*
    * @Author: Adyasha
    * @Description : get user Id to set as renewal Opportunity Owner
    * @param : Opportunity opp, Map<String, String> mapAccIdToUserId, Map<String,String> mapAccIdToTerrName , Map<String, String> mapTerNameUsrId
    * @return : Id
    */
    private Id getUserId(Opportunity opp, Map<String, String> mapAccIdToUserId, Map<String,String> mapAccIdToTerrName , Map<String, String> mapTerNameUsrId) {
        Id userId = null;
        if(!(mapAccIdToUserId == null || mapAccIdToUserId.isEmpty()) && mapAccIdToUserId.containsKey(opp.Ultimate_Consignee__c)) {
            userId = mapAccIdToUserId.get(opp.Ultimate_Consignee__c);                    
        } else if(!(mapAccIdToTerrName == null || mapAccIdToTerrName.isEmpty()) && mapAccIdToTerrName.containsKey(opp.Ultimate_Consignee__c)) {                                    
            String terrName = mapAccIdToTerrName.get(opp.Ultimate_Consignee__c);
            if(terrName != null && mapTerNameUsrId != null && !(mapTerNameUsrId.isEmpty())) {
                userId = mapTerNameUsrId.get(terrName);                       
            }                                            
        } else {                       
            userId = opp.OwnerId;               
        }
        ilib_LogEvent.message('User Id :'+userId); //CMSI-200             
        return userId;
    }

    /*
    * @Author: Adyasha
    * @Description : get user Id to set as renewal Opportunity Owner
    * @param : Opportunity opp, Map<String, String> mapAccIdToUserId, Map<String,String> mapAccIdToTerrName , Map<String, String> mapTerNameUsrId
    * @return : Id
    */
    private Id getOpportunityRecordId(String strRecordTypeDevName) {
        if(Opportunities.DIRECT_RECORD_TYPES.contains(strRecordTypeDevName)) {
            return Opportunities.RECORD_TYPE_MAP.get(Label.OpportunityRTDirectReOrder).getRecordTypeId(); 
        }
        return Opportunities.RECORD_TYPE_MAP.get(Label.IndirectReOrder).getRecordTypeId();
    }
		
	/*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: THis Method to Get the Territory Details of UC Account
    *  @PARAM :  Map<<id>, List<Opportunity>>
    */
    public Map<String,Map<String,String>> getTerritoryUsers( Map<Id, Opportunity> mapClosedWonOppIdsToOpp) {
        ilib_LogEvent.push(LOG_TITLE+'.getTerritoryUsers()');     //CMSI-200
        Set<ID> setAccountIds = new Set<ID>();
        //Set<ID> setAccountIdNonChina = new Set<ID>();
        Set<String> setAccountTerritoryName = new Set<String>();
        Map<String,Map<String,String>> mapStrToUserAccTerrFinalMap = new Map<String,Map<String,String>>();
        Map<String, String> mapAccIdToUserId = new Map<String, String>();
        Map<Id,String> mapAccountIdToTerritoryName = new Map<Id,String>();
        String strMapAccIdToUserId = 'mapAccIdToUserId';   
        //Get the AccountId Set
        for(Opportunity opp : mapClosedWonOppIdsToOpp.values()) {
            if(String.isNotBlank(opp.Ultimate_Consignee__c)) {
                setAccountIds.add(opp.Ultimate_Consignee__c);                
            }            
        }     
        //Get the Territoty Name and Region and set Account and OwnerId for China 
        List<Account> lstAccountTerrritory = new AccountsSelector().getAccountsTerritories(setAccountIds);        
        for(Account uc : lstAccountTerrritory) {            
            if(uc.Territory_Region__c.equals(Label.TerritoryRegionChina)) {
                mapAccIdToUserId.put(uc.Id,uc.OwnerId);
            } else {
                setAccountTerritoryName.add(uc.Territory_Name__c);
                //setAccountIdNonChina.add(uc.Id);
                mapAccountIdToTerritoryName.put(uc.Id,uc.Territory_Name__c);
            }
        } 
        if(mapAccountIdToTerritoryName.isEmpty()) {   
            mapStrToUserAccTerrFinalMap.put(strmapAccIdToUserId,mapAccIdToUserId); 
            ilib_LogEvent.info('mapStrToUserAccTerrFinalMap :'+mapStrToUserAccTerrFinalMap); //CMSI-200
            ilib_LogEvent.pop();   //CMSI-200                     
            return mapStrToUserAccTerrFinalMap; 
        } else {
            ilib_LogEvent.pop();   //CMSI-200   
            return getUCAssociatedRoles(mapAccountIdToTerritoryName.keyset(),setAccountTerritoryName,mapAccIdToUserId,mapAccountIdToTerritoryName);                        
        }  
    }

	/*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: This method to get the TAM and ISR user details of UC Territory
    *  @PARAM :  set<id>, set<String>
    */
    public Map<String,Map<String,String>> getUCAssociatedRoles(Set<ID> accountIdSet, Set<String> accountTerrNameSet, Map<String, String> mapAccIdToUserId, Map<Id,String> mapAccountIDTerritoryName){
        ilib_LogEvent.push(LOG_TITLE+'.getUCAssociatedRoles()'); //CMSI-200
        Map<String, Map<String,String>> mapStrToMapAccIdToUserId = new Map<String, Map<String,String>>();
        Map<String, List<UserTerritory2Association>> mapAccTerriUsrsToListISR = new Map<String, List<UserTerritory2Association>>();        
        Map<String, List<UserTerritory2Association>> mapAccTerriUsrsToListTAM = new Map<String, List<UserTerritory2Association>>();                          
        Set<String> setRegion = new Set<String>{'AMR','EUR','AMEA'};   // POL-54
        Set<String> setRoles = new Set<String>{Label.ISR_Role,Label.TAM_Role}; 
        List<UserTerritory2Association> lstUserTerrAssociation  = new UserTerritory2AssociationSelector().selectTerritoryAssociationNonChina(accountTerrNameSet,setRoles,setRegion);  
        if(System.test.isRunningTest()){
        UserTerritory2Association objUTA = new UserTerritory2Association();
        objUTA.RoleInTerritory2 = Label.ISR_Role;
        lstUserTerrAssociation.add(objUTA);
        }     
        for(UserTerritory2Association userTerrAssociation : lstUserTerrAssociation ){   
                        
            if(userTerrAssociation.RoleInTerritory2.equals(Label.ISR_Role)){                        
                mapAccTerriUsrsToListISR = getAccTerritoryUsrToListMap(mapAccTerriUsrsToListISR, userTerrAssociation);
            }else{
                mapAccTerriUsrsToListTAM = getAccTerritoryUsrToListMap(mapAccTerriUsrsToListTAM, userTerrAssociation);
            }
        }
                
        //Check for the single ISR if there is no ISR get TAM
        mapStrToMapAccIdToUserId =  updateMapAccIdToUserId(accountIdSet,mapAccIdToUserId,mapAccountIDTerritoryName,mapAccTerriUsrsToListISR,mapAccTerriUsrsToListTAM);
        ilib_LogEvent.info('mapStrToMapAccIdToUserId :'+mapStrToMapAccIdToUserId);  //CMSI-200
        ilib_LogEvent.pop(); //CMSI-200
        return mapStrToMapAccIdToUserId;       
    }

    /*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: This method to get the TAM and ISR user details of UC Territory
    *  @PARAM :  set<id>, Map<String, String>, Map<Id,String>, Map<String, List<UserTerritory2Association>>, Map<String, List<UserTerritory2Association>>
    */
    public Map<String,Map<String,String>> updateMapAccIdToUserId(Set<ID> accountIdSet,  Map<String, String> mapAccIdToUserId, Map<Id,String> mapAccountIDTerritoryName, Map<String, List<UserTerritory2Association>> mapAccTerriUsrsToListISR, Map<String, List<UserTerritory2Association>> mapAccTerriUsrsToListTAM){
        ilib_LogEvent.push(LOG_TITLE+'.updateMapAccIdToUserId()'); //CMSI-200
        Map<String, Map<String,String>> mapStrToMapAccIdToUserId = new Map<String, Map<String,String>>();        
        Map<Id, List<UserTerritory2Association>> mapMulToISR = new Map<Id, List<UserTerritory2Association>>();
        List<UserTerritory2Association> lstTempAccIsrUsrId = new List<UserTerritory2Association>();
        List<UserTerritory2Association> lstTempAccTamUsrId = new List<UserTerritory2Association>();        
        Integer num = 1;   
        String strmapAccIdToUserId = 'mapAccIdToUserId';           
        
           
        //Check for the single ISR if there is no ISR get TAM
        if(!(mapAccTerriUsrsToListISR.isEmpty()) || !(mapAccTerriUsrsToListTAM.isEmpty())){
            for(Id accId : accountIdSet){
                String strTerritoryName = '';                
                if(mapAccountIDTerritoryName.containsKey(accId)){
                    strTerritoryName = mapAccountIDTerritoryName.get(accId);
                }
                if(mapAccTerriUsrsToListISR.containsKey(strTerritoryName)){
                    lstTempAccIsrUsrId = mapAccTerriUsrsToListISR.get(strTerritoryName);   
                }                         
                if(lstTempAccIsrUsrId == null || lstTempAccIsrUsrId.isEmpty()){                       
                    if(mapAccTerriUsrsToListTAM.containsKey(strTerritoryName)){
                        lstTempAccTamUsrId = mapAccTerriUsrsToListTAM.get(strTerritoryName);  
                    }                                                        
                    if(lstTempAccTamUsrId != null && lstTempAccTamUsrId.size() == num){                        
                        mapAccIdToUserId.put(accId,lstTempAccTamUsrId[0].UserId);                    
                    }
                }else{                       
                    if( lstTempAccIsrUsrId.size() == num){
                        mapAccIdToUserId.put(accId,lstTempAccIsrUsrId[0].UserId);
                    }else if(lstTempAccIsrUsrId.size()>num){
                        mapMulToISR.put(accId,lstTempAccIsrUsrId);
                    }
                }
            }
        }        
        //If multiple IRS then get the latest ISR based on lastmodified data         
        if( !(mapMulToISR.isEmpty())){      
            mapStrToMapAccIdToUserId =getSingleISR(mapMulToISR);
        }        
        mapStrToMapAccIdToUserId.put(strmapAccIdToUserId, mapAccIdToUserId); 
        ilib_LogEvent.info('mapStrToMapAccIdToUserId :'+mapStrToMapAccIdToUserId); //CMSI-200
        ilib_LogEvent.pop(); //CMSI-200
        return mapStrToMapAccIdToUserId;       
    }

    /*
    *  @AUTHOR:  Rishi Sharma
    *  @DESCRIPTION: This method to get Account territory user id to list map 
    *  @PARAM :  map<id, List<UserTerritory2Association>>, UserTerritory2Association
    */
    public static Map<String,List<UserTerritory2Association>> getAccTerritoryUsrToListMap(Map<String, List<UserTerritory2Association>> mapTerritoryNameToUTAObj, UserTerritory2Association objUserTerritoryAssociation){
        List<UserTerritory2Association> lstUserTerritoryAssociation = new List<UserTerritory2Association>();

        if(mapTerritoryNameToUTAObj.containsKey(objUserTerritoryAssociation.Territory2.Name)) {
            if(mapTerritoryNameToUTAObj.containsKey(objUserTerritoryAssociation.Territory2.Name)){
                lstUserTerritoryAssociation = mapTerritoryNameToUTAObj.get(objUserTerritoryAssociation.Territory2.Name);
            }            
            lstUserTerritoryAssociation.add(objUserTerritoryAssociation);
            mapTerritoryNameToUTAObj.put(objUserTerritoryAssociation.Territory2.Name, lstUserTerritoryAssociation);
        } else {
            mapTerritoryNameToUTAObj.put(objUserTerritoryAssociation.Territory2.Name, new List<UserTerritory2Association> { objUserTerritoryAssociation });
        } 
        ilib_LogEvent.message('mapTerritoryNameToUTAObj :'+mapTerritoryNameToUTAObj);   //CMSI-200
        return mapTerritoryNameToUTAObj;
    }
    
	/*
    *  @AUTHOR:  Maruthi B
    *  @DESCRIPTION: This method to get latest ISR user details in case mul ISR's 
    *  @PARAM :  map<id, List<UserTerritory2Association>>
    */
    public static Map<String,Map<String,String>> getSingleISR(Map<id,List<UserTerritory2Association>> getSinISR){
        ilib_LogEvent.push(LOG_TITLE+'.getSingleISR()');  //CMSI-200
        Map<String,Map<String,String>> mapStrMapAccIdToTerrNameMapTerNameUsrId = new Map<String,Map<String,String>>();
        Map<String,String> mapAccIdToTerrName = new Map<String,String>();
        Map<String, String> mapTerNameUsrId = new Map<String, String>();    
        String strMapAccIdToTerrName = 'mapAccIdToTerrName';
        String strMapTerNameUsrId = 'mapTerNameUsrId';   

        Set<Id> setAccIdsMul = getSinISR.keyset(); 
        List<Account> lstAccTerritory = new AccountsSelector().getAccountsTerritories(setAccIdsMul);
        for(Account acc : lstAccTerritory){
            if(!mapAccIdToTerrName.containsKey(acc.id)){
                mapAccIdToTerrName.put(acc.Id,acc.Territory_Name__c);         
            }
        }
        List<UserTerritory2Association> lstUserTerritoryAssociation= new UserTerritory2AssociationSelector().selectTerrAssoForISR(mapAccIdToTerrName.values(),Label.ISR_Role);            
        for(UserTerritory2Association objUserTerritoryAssociation : lstUserTerritoryAssociation){
            if(!mapTerNameUsrId.containsKey(objUserTerritoryAssociation.Territory2.Name)) {
                mapTerNameUsrId.put(objUserTerritoryAssociation.Territory2.Name,objUserTerritoryAssociation.UserId);
            }
        }         
        mapStrMapAccIdToTerrNameMapTerNameUsrId.put(strMapAccIdToTerrName,mapAccIdToTerrName);           
        mapStrMapAccIdToTerrNameMapTerNameUsrId.put(strMapTerNameUsrId,mapTerNameUsrId);
        ilib_LogEvent.pop();   //CMSI-200           
        return mapStrMapAccIdToTerrNameMapTerNameUsrId;
    }
}
/***************************************************************************************************************************************
* NAME   : ApttusOrderService 
* DESCRIPTION  : Service class for ApptusOrder object.
*                    
* @AUTHOR : Arquimidez Mora
* @DATE   : 10-08-2024  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Arquimidez Mora         08-Aug-2024         CMCM-9645: Methods to populate Contact and Opportunity from Quotation to Order and update PO Data on related Opportunity
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class ApttusOrderService {
    private static final String LOG_TITLE = 'ApttusOrders';
    private static final String STRING_OPPORTUNITY_CLOSED_WON = 'Closed Won';
    private static final String STRING_PROPOSAL_STAGE_DENIED = 'Denied';
    private static final String STRING_PROPOSAL_STAGE_ACCEPTED = 'Accepted';

    /*	
    *  @AUTHOR:  Arquimidez Mora	
    *  @DESCRIPTION: 	CMCM-9645 - Pupuldate Primary Contact and Opportunity from Quotation and update 
                        PO Number and PO Date from related Opportunity
    */	
    public static void  populateDefaultFieldsAndPONumberAndPODate(List<Apttus_Config2__Order__c> lstOrders,Map<Id, Apttus_Config2__Order__c> existingOrders) {  
        Map<Id, Apttus_Config2__Order__c> mapOrderByQuotation = new Map<Id, Apttus_Config2__Order__c>();
        Map<Id, Apttus_Config2__Order__c> mapOrderByOpportunity = new Map<Id, Apttus_Config2__Order__c>();
        Map<Id, Apttus_Config2__Order__c> mapOrderByQuotationToUpdate = new Map<Id, Apttus_Config2__Order__c>();
        Set<Id> setQuotationIds = new Set<Id>();
        Set<Id> setQuotationIdsToUpdate = new Set<Id>();
        Set<Id> setOpportunityIds = new Set<Id>();
        for(Apttus_Config2__Order__c objOrder : lstOrders){
            Apttus_Config2__Order__c objOldOrder = (existingOrders != null && (existingOrders.containsKey(objOrder.Id))) ? existingOrders.get(objOrder.Id) : null;

            if(objOrder.Apttus_QPConfig__ProposalId__c != null){
                mapOrderByQuotation.put(objOrder.Apttus_QPConfig__ProposalId__c, objOrder);
                setQuotationIds.add(objOrder.Apttus_QPConfig__ProposalId__c );
            }

            if(
                objOrder.Apttus_Config2__RelatedOpportunityId__c != null && 
                objOrder.Apttus_Config2__Type__c != 'Illmn Extnded Wrrnty' &&
                objOrder.Apttus_Config2__OrderReferenceNumber__c != null 
            ){
                mapOrderByOpportunity.put(objOrder.Apttus_Config2__RelatedOpportunityId__c, objOrder);
                setOpportunityIds.add(objOrder.Apttus_Config2__RelatedOpportunityId__c );
            }

            Boolean boolQuoteNoOrTypeChanged = isQuoteNoOrTypeChanged(objOldOrder, objOrder);
            //Is new or got updated, and Opportunity is not null
            if(isNewOrUpdateAndOpportunityIsNotNull(objOldOrder, objOrder, boolQuoteNoOrTypeChanged)){
                mapOrderByQuotationToUpdate.put(objOrder.Apttus_QPConfig__ProposalId__c, objOrder);
                setQuotationIdsToUpdate.add(objOrder.Apttus_QPConfig__ProposalId__c);
            }

        }
        populateContactAndOpportunity(mapOrderByQuotation, setQuotationIds);
        updatePODataOnOpportunity(mapOrderByOpportunity, setOpportunityIds);
        updateIsPrimaryAndQuoteStagesOnQuotation(mapOrderByQuotationToUpdate, setQuotationIdsToUpdate);
    }

    private static Boolean isQuoteNoOrTypeChanged(Apttus_Config2__Order__c objOldOrder, Apttus_Config2__Order__c objOrder){
        return (
                    objOldOrder != null && 
                    (
                        objOrder.APTTUS_Quote_Number__c != objOldOrder.APTTUS_Quote_Number__c || 
                        objOrder.Apttus_Config2__OrderReferenceNumber__c != objOldOrder.Apttus_Config2__OrderReferenceNumber__c || 
                        objOrder.Apttus_Config2__Type__c != objOldOrder.Apttus_Config2__Type__c
                    )
                ) ? true : false;
    }

    private static Boolean isNewOrUpdateAndOpportunityIsNotNull(Apttus_Config2__Order__c objOldOrder, Apttus_Config2__Order__c objOrder, Boolean boolQuoteNoOrTypeChanged){
        return (
                    (objOldOrder == null || boolQuoteNoOrTypeChanged) && 
                    objOrder.Apttus_Config2__RelatedOpportunityId__c != null && 
                    (
                        objOrder.Apttus_Config2__Type__c != 'Illmn Extnded Wrrnty' && 
                        objOrder.Apttus_Config2__OrderReferenceNumber__c != null && 
                        objOrder.APTTUS_Quote_Number__c != null
                    )
                ) ? true : false;
    }

    /*	
    *  @AUTHOR:  Arquimidez Mora	
    *  @DESCRIPTION: 	CMCM-9645 - Pupuldate Primary Contact and Opportunity from Quotation to Order
    */	
    private static void populateContactAndOpportunity(Map<Id, Apttus_Config2__Order__c> mapOrderByQuotation, Set<Id> setQuotationIds) {    
        List<Apttus_Config2__Order__c> lstOrdersToUpdate = new List<Apttus_Config2__Order__c>();
        if(mapOrderByQuotation.size() > 0 && setQuotationIds.size() > 0){
            List<String> lstFields = new List<String>{
                'Id',
                'Apttus_Proposal__Primary_Contact__c',
                'Apttus_Proposal__Opportunity__c'
            };

            List<Apttus_Proposal__Proposal__c> lstQuotations = new ApttusProposalsSelector().selectQuotesWithFields(setQuotationIds, lstFields);
            for(Apttus_Proposal__Proposal__c objQuote : lstQuotations){
                Apttus_Config2__Order__c objOrder = mapOrderByQuotation.containsKey(objQuote.Id) ? mapOrderByQuotation.get(objQuote.Id) : null;
                Apttus_Config2__Order__c objOrderToUpdate = new Apttus_Config2__Order__c();
                Boolean boolNeedOppUpdate = false;
                Boolean boolNeedContactUpdate = false;

                if(
                    objOrder != null && objQuote.Apttus_Proposal__Opportunity__c != null &&  
                    objOrder.Apttus_Config2__RelatedOpportunityId__c != objQuote.Apttus_Proposal__Opportunity__c
                ){
                    objOrderToUpdate.Id = objOrder.Id; 
                    objOrderToUpdate.Apttus_Config2__RelatedOpportunityId__c = objQuote.Apttus_Proposal__Opportunity__c;
                    boolNeedOppUpdate = true; 
                }

                if(
                    objOrder != null && objQuote.Apttus_Proposal__Primary_Contact__c != null &&  
                    objOrder.Apttus_Config2__PrimaryContactId__c != objQuote.Apttus_Proposal__Primary_Contact__c
                ){
                    objOrderToUpdate.Id = objOrder.Id; 
                    objOrderToUpdate.Apttus_Config2__PrimaryContactId__c = objQuote.Apttus_Proposal__Primary_Contact__c;
                    boolNeedContactUpdate = true;
                }
                if(boolNeedOppUpdate || boolNeedContactUpdate){
                    lstOrdersToUpdate.add(objOrderToUpdate);
                }
            }

            if(lstOrdersToUpdate.size() > 0){
                List<Database.SaveResult> lstSaveErrors = Database.update(lstOrdersToUpdate, false);
                ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
            }
        }
    }

    /*	
    *  @AUTHOR:  Arquimidez Mora	
    *  @DESCRIPTION: 	CMCM-9645 - Update PO Data from related Opportunity
    */	
    private static void updatePODataOnOpportunity(Map<Id, Apttus_Config2__Order__c> mapOrderByOpportunity, Set<Id> setOpportunityIds) {        	
        List<Opportunity> lstOpportunitiesToUpdate = new List<Opportunity>();
        if(mapOrderByOpportunity.size() > 0 && setOpportunityIds.size() > 0){
            List<String> lstFields = new List<String>{
                'Id', 'Is_Updated_By_System__c', 
                'StageName', 'First_Syncd_Order_ID__c', 
                'Purchase_Order_Number__c', 'Purchase_Order_Received_On__c', 
                'ForecastCategoryName'
            };
            List<Opportunity> lstOpportunities = new OpportunitySelector().selectOpportunityWithFields(setOpportunityIds, lstFields);
            for(Opportunity objOpportunity : lstOpportunities){
                if(mapOrderByOpportunity.containsKey(objOpportunity.Id)){
                    Apttus_Config2__Order__c objOrder = mapOrderByOpportunity.get(objOpportunity.Id);
                    lstOpportunitiesToUpdate.add(checkIfOpportunityIsClosedWon(objOpportunity, objOrder));
                }
            }

            if(lstOpportunitiesToUpdate.size() > 0){
                List<Database.SaveResult> lstSaveErrors = Database.update(lstOpportunitiesToUpdate, false);
                ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
            }
        }
    }

    /*	
    *  @AUTHOR:  Arquimidez Mora	
    *  @DESCRIPTION: 	CMCM-9645 - Check if Opportunity is "Closed Won" and update some Opportunity fields
    */	
    private static Opportunity checkIfOpportunityIsClosedWon(Opportunity objOpportunity, Apttus_Config2__Order__c objOrder) {
        if(objOpportunity.StageName != STRING_OPPORTUNITY_CLOSED_WON){
            objOpportunity.Is_Updated_By_System__c = true;
            objOpportunity.StageName = STRING_OPPORTUNITY_CLOSED_WON;
            objOpportunity.ForecastCategoryName = 'Closed';
            fillOpportunityClosedFields(objOpportunity, objOrder);
        }else if(objOpportunity.StageName == STRING_OPPORTUNITY_CLOSED_WON){
            fillOpportunityClosedFields(objOpportunity, objOrder);
        }

        return objOpportunity;
    }

    /*	
    *  @AUTHOR:  Arquimidez Mora	
    *  @DESCRIPTION: 	CMCM-9645 - Fill Opportunity fields (First_Syncd_Order_ID__c, Is_Updated_By_System__c, Purchase_Order_Number__c, Purchase_Order_Received_On__c)
    */	
    private static void fillOpportunityClosedFields(Opportunity objOpportunity, Apttus_Config2__Order__c objOrder) {
        if(objOpportunity.First_Syncd_Order_ID__c == null){
            objOpportunity.First_Syncd_Order_ID__c = objOrder.Id;
            objOpportunity.Is_Updated_By_System__c = true;
            objOpportunity.Purchase_Order_Number__c = (objOrder.Apttus_Config2__PONumber__c != null) ? objOrder.Apttus_Config2__PONumber__c : '';
            objOpportunity.Purchase_Order_Received_On__c = (objOrder.Apttus_Config2__PODate__c != null) ? objOrder.Apttus_Config2__PODate__c : null;
        }
    }

    /*	
    *  @AUTHOR:  Arquimidez Mora	
    *  @DESCRIPTION: 	CMCM-9645 - Update Is Primary and Quote Stages on related Quoation
    */	
    private static void updateIsPrimaryAndQuoteStagesOnQuotation(Map<Id, Apttus_Config2__Order__c> mapOrderByQuotation, Set<Id> setQuotationIds) {    
        List<Apttus_Proposal__Proposal__c> lstQuotationsToUpdate = new List<Apttus_Proposal__Proposal__c>();
        if(mapOrderByQuotation.size() > 0 && setQuotationIds.size() > 0){
            List<String> lstFields = new List<String>{
                'Id', 'Name', 'Apttus_Proposal__Approval_Stage__c',
                'Apttus_Proposal__Primary__c', 'Is_Updated_By_System__c'
            };
            List<Apttus_Proposal__Proposal__c> lstQuotations = new ApttusProposalsSelector().selectQuotesWithFields(setQuotationIds, lstFields);
            for(Apttus_Proposal__Proposal__c objQuote : lstQuotations){
                Apttus_Config2__Order__c objOrder = mapOrderByQuotation.containsKey(objQuote.Id) ? mapOrderByQuotation.get(objQuote.Id) : null;
                if(objQuote.Name != objOrder.APTTUS_Quote_Number__c){
                    if(objQuote.Apttus_Proposal__Primary__c == true){
                        objQuote.Apttus_Proposal__Primary__c = false;
                        objQuote.Apttus_Proposal__Approval_Stage__c = STRING_PROPOSAL_STAGE_DENIED;
                        objQuote.Is_Updated_By_System__c = true;
                        lstQuotationsToUpdate.add(objQuote);
                    }else{
                        objQuote.Apttus_Proposal__Approval_Stage__c = STRING_PROPOSAL_STAGE_DENIED;
                        objQuote.Is_Updated_By_System__c = true;
                        lstQuotationsToUpdate.add(objQuote);
                    }
                }else{
                    if(objQuote.Apttus_Proposal__Primary__c == true && objQuote.Apttus_Proposal__Approval_Stage__c != STRING_PROPOSAL_STAGE_ACCEPTED){
                        objQuote.Apttus_Proposal__Approval_Stage__c = STRING_PROPOSAL_STAGE_ACCEPTED;
                        objQuote.Is_Updated_By_System__c = true;
                        lstQuotationsToUpdate.add(objQuote);
                    }else{
                        objQuote.Apttus_Proposal__Primary__c = true;
                        objQuote.Apttus_Proposal__Approval_Stage__c = STRING_PROPOSAL_STAGE_ACCEPTED;
                        objQuote.Is_Updated_By_System__c = true;
                        lstQuotationsToUpdate.add(objQuote);
                    }
                }
            }

            if(lstQuotationsToUpdate.size() > 0){
                List<Database.SaveResult> lstSaveErrors = Database.update(lstQuotationsToUpdate, false);
                ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
            }
        }
    }
}
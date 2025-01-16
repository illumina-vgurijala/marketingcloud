/***************************************************************************************************************************************
* NAME   : ProductConfigurationService 
* DESCRIPTION  : Service class for ApptusProductConfiguration object.
*                    
* @AUTHOR : Arquimidez Mora
* @DATE   : 21-08-2024  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Arquimidez Mora         21-Aug-2024          CMCM-9986: Methods to update by pass syn to opportunity
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class ApttusProductConfigurationService {

    private static final String LOG_TITLE = 'ApttusProductConfigurationService';
    public static final String STRING_PRODUCT_CONFIG_STATUS_FINALIZED = 'Finalized';
    private static final List<String> LIST_QUOTE_FIELDS = new List<String>{
        'Id', 'Apttus_Proposal__Opportunity__c', 'Apttus_Proposal__Primary__c', 'Estimated_Freight__c', 
        'Estimated_Tax__c', 'Promotion_JSON__c', 'SAP_Errors__c', 'SAP_Promotion__c', 
        'Sub_Total__c', 'Total_Discount__c', 'Total_Net__c'
    };

    /*  @AUTHOR - Arquimidez Mora
    *  @RETURN - Void
    *  @DESCRIPTION - CMCM-9986 method update opportunity line items and quotations.
    **/
    public static void updateByPassSyncToOpportunity(List<Apttus_Config2__ProductConfiguration__c> lstProductConfig, Map<Id, sObject> mapOldRecords){
        Map<Id, Apttus_Config2__ProductConfiguration__c> mapProductConfig = new Map<Id, Apttus_Config2__ProductConfiguration__c>();
        Set<Id> setQuotationIds = new Set<Id>();

        for(Apttus_Config2__ProductConfiguration__c objProductConfig : lstProductConfig){
            Apttus_Config2__ProductConfiguration__c objOldProductConfig = (Apttus_Config2__ProductConfiguration__c)mapOldRecords.get(objProductConfig.Id);

            if(
                objProductConfig.Apttus_Config2__Status__c != objOldProductConfig.Apttus_Config2__Status__c && 
                objProductConfig.Apttus_Config2__Status__c == STRING_PRODUCT_CONFIG_STATUS_FINALIZED && 
                objProductConfig.Apttus_QPConfig__Proposald__c != null
            ){
                setQuotationIds.add(objProductConfig.Apttus_QPConfig__Proposald__c);
                mapProductConfig.put(objProductConfig.Apttus_QPConfig__Proposald__c, objProductConfig);
            }
        }

        if(!setQuotationIds.isEmpty()){
            updateQuotationData(setQuotationIds, mapProductConfig);
        }
    }

    /*  @AUTHOR - Arquimidez Mora
    *  @RETURN - Void
    *  @DESCRIPTION - CMCM-9986 method update quotation with product configuration data.
    **/
    private static void updateQuotationData(Set<Id> setQuotationIds, Map<Id, Apttus_Config2__ProductConfiguration__c> mapProductConfig){
        Set<Id> setOpportunityIds = new Set<Id>();
        List<Apttus_Proposal__Proposal__c> lstQuotationsToUpdate = new List<Apttus_Proposal__Proposal__c>();

        List<Apttus_Proposal__Proposal__c> lstQuotations = new ApttusProposalsSelector().selectQuotesWithFields(setQuotationIds, LIST_QUOTE_FIELDS);

        for(Apttus_Proposal__Proposal__c objQuote : lstQuotations){
            Apttus_Config2__ProductConfiguration__c objProductConfig = mapProductConfig.get(objQuote.Id);
            if(objQuote.Apttus_Proposal__Primary__c == true){
                setOpportunityIds.add(objQuote.Apttus_Proposal__Opportunity__c);
            }
            objQuote.Estimated_Freight__c = objProductConfig.Estimated_Freight__c;
            objQuote.Estimated_Tax__c = objProductConfig.Estimated_Tax__c;
            objQuote.Promotion_JSON__c = objProductConfig.Promotion_JSON__c;
            objQuote.SAP_Errors__c = objProductConfig.SAP_Errors__c;
            objQuote.SAP_Promotion__c = objProductConfig.SAP_Promotion__c;
            objQuote.Sub_Total__c = objProductConfig.Sub_Total__c;
            objQuote.Total_Discount__c = objProductConfig.Total_Discount__c;
            objQuote.Total_Net__c = objProductConfig.Total_Net__c;
            lstQuotationsToUpdate.add(objQuote);
        }

        if(!setOpportunityIds.isEmpty()){
            updateOpportunityLineItems(setOpportunityIds);
        }

        if(!lstQuotationsToUpdate.isEmpty()){
            List<Database.SaveResult> lstSaveErrors = Database.update(lstQuotationsToUpdate, false);
            ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
        }
    }

    /*  @AUTHOR - Arquimidez Mora
    *  @RETURN - Void
    *  @DESCRIPTION - CMCM-9986 method update By pass on Opportunity Line Items.
    **/
    private static void updateOpportunityLineItems(Set<Id> setOpportunityIds){
        List<OpportunityLineItem> lstOpportunityLineToUpdate = new List<OpportunityLineItem>();
        try {
            List<OpportunityLineItem> lstOpportunityLineItems = new OpportunityLineItemsSelector().selectOpportunityLineItems(setOpportunityIds);
    
            for(OpportunityLineItem objOpportunityLine : lstOpportunityLineItems){
                objOpportunityLine.By_Pass_Sync_To_Opportunity__c = true;
                lstOpportunityLineToUpdate.add(objOpportunityLine);
            }
    
            if(!lstOpportunityLineToUpdate.isEmpty()){
                List<Database.SaveResult> lstSaveErrors = Database.update(lstOpportunityLineToUpdate, false);
                ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
            }
        } catch (Exception ex) {
            ilib_LogEvent.info('*** Exception Message : ' + ex.getMessage());
        }
    }

    /*  @AUTHOR - Arquimidez Mora
    *  @RETURN - Void
    *  @DESCRIPTION - CMCM-9986 method check if related quotation is a clone and then update EffectiveDate and Expected Start Date fields from Product Configuration.
    **/
    public static void updateDatesIfProposalIsClone(List<Apttus_Config2__ProductConfiguration__c> lstProductConfig){
        List<Apttus_Config2__ProductConfiguration__c> lstProductConfigToUpdate = new List<Apttus_Config2__ProductConfiguration__c>();
        List<Apttus_Proposal__Proposal__c> lstQueryQuotations = new List<Apttus_Proposal__Proposal__c>();
        Map<Id, Apttus_Proposal__Proposal__c> mapQuotations = new Map<Id, Apttus_Proposal__Proposal__c>();
        Set<Id> setQuotationIds = new Set<Id>();

        for(Apttus_Config2__ProductConfiguration__c objProductConfig : lstProductConfig){
            if(objProductConfig.Apttus_QPConfig__Proposald__c != null){
                setQuotationIds.add(objProductConfig.Apttus_QPConfig__Proposald__c);
            }
        }

        if(!setQuotationIds.isEmpty()){
            lstQueryQuotations = new ApttusProposalsSelector().selectQuotesWithFields(setQuotationIds, new List<String>{
                'Id', 'Apttus_QPConfig__PricingDate__c', 'Cloned_From__c'
            });
            for(Apttus_Proposal__Proposal__c objProposal : lstQueryQuotations){
                mapQuotations.put(objProposal.Id, objProposal);
            }
            for(Apttus_Config2__ProductConfiguration__c objProductConfig : lstProductConfig){
                Apttus_Config2__ProductConfiguration__c objProductConfigToUpdate = new Apttus_Config2__ProductConfiguration__c();
                objProductConfigToUpdate.Id = objProductConfig.Id;
                Apttus_Proposal__Proposal__c objProposal = mapQuotations.get(objProductConfig.Apttus_QPConfig__Proposald__c);
                if(
                    objProductConfig.Apttus_QPConfig__Proposald__c != null && 
                    objProductConfig.Apttus_Config2__AncestorId__c != null && 
                    objProductConfig.Apttus_Config2__VersionNumber__c == 1 && 
                    objProposal.Cloned_From__c != null
                ){
                    objProductConfigToUpdate.Apttus_Config2__EffectiveDate__c = objProposal.Apttus_QPConfig__PricingDate__c;
                    objProductConfigToUpdate.Apttus_Config2__ExpectedStartDate__c = objProposal.Apttus_QPConfig__PricingDate__c.date();
                    lstProductConfigToUpdate.add(objProductConfigToUpdate);
                }
            }
        }

        if(!lstProductConfigToUpdate.isEmpty()){
            List<Database.SaveResult> lstSaveErrors = Database.update(lstProductConfigToUpdate, false);
            ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE);
        }
    }
}
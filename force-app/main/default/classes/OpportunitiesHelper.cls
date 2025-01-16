/**
*    Author        Rishab
*    Date          2021-04-05
*    Description   Opportunity Helper class
*    Test Class     TestOpportunities
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                Description
*     Rishab Wali                    05-Apr-2021         Initial Version 
*     Khushbu                        04-Sept-2022        DCP-56658- get accounthierarchy data to populate approval hierarchy owner
*     Rajbabu Boopalan               04-Nov-2023         CMCM-4516 CPU Timeout error on submit for approval
*     Raja Babu                      26-June-2024        PRB0048852 Method Name: updateCloseDateToToday:- Duplicate Renewal Opportunity for Informatic opportunity
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class OpportunitiesHelper {

    private static Map<Id, Schema.RecordTypeInfo> idToRecordType;
    public static final Set<String> DIRECT_RECORD_TYPES = new Set<String> { Label.OpportunityRTDirectFieldServices, Label.OpportunityRTDirectReOrder, Label.OpportunityRTDirectStandard };
    public static final Set<String> INDIRECT_RECORD_TYPES = new Set<String> { Label.OpportunityRTIndirectStandard, Label.IndirectReOrder, Label.IndirectFieldServices };
    public static Map<Id, Id> mapOwnerIdApprovalHierarchy = new Map<Id, Id>();

    /* Method to get recordId map*/ 
    public static Map<Id, Schema.RecordTypeInfo> getIdToRecordType()
    {
        if (idToRecordType == null) { idToRecordType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosById(); }
        return idToRecordType;
    }

    /*Method to Update Market Segment and Clinical Type */
    public static void updateMarketSegmentClinicalType(List<Opportunity> oppList , Map<Id,Opportunity> oldOpportunityMap)
    {
        Set<Id> ucIdSet = new Set<Id>();
        Set<Id> oppUpdateIdSet = new Set<Id>(); 

        for(Opportunity opp : oppList)
        {
            if(opp.Ultimate_Consignee__c != null  && opp.Ultimate_Consignee__c != oldOpportunityMap.get(opp.Id).Ultimate_Consignee__c)
            {
                ucIdSet.add(opp.Ultimate_Consignee__c);
                oppUpdateIdSet.add(opp.Id);
            }
        }

        if(!ucIdSet.isEmpty())
        {
            Map<Id,Account> accIdToAccountMap = new Map<Id,Account>(new AccountsSelector().selectAccounts(ucIdSet));
            for(Opportunity oppty : oppList)
            {
                if(accIdToAccountMap.containsKey(oppty.Ultimate_Consignee__c))
                { 
                    updateOppClinicalType(oppty, accIdToAccountMap);
                    if(accIdToAccountMap.get(oppty.Ultimate_Consignee__c).Market_Segment__c == Opportunities.UCMARKETSEGMENTMULTIPLE)
                    {
                        oppty.Is_Updated_By_System__c = true;
                        oppty.Market_Segment__c = null; 
                    }
                    else
                    {
                        oppty.Market_Segment__c = accIdToAccountMap.get(oppty.Ultimate_Consignee__c).Market_Segment__c;
                    } 
                }
            }
        }
    }

    /*Method to Update Opportunity Fields from Ultimate Consignee */
    public static void updateOpportunityFromUltimateConsignee(List<Opportunity> lstOpportunity)
    {
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> opportunityIdWithUCBlankSet = new Set<Id>();
        Set<Id> opportunityIdWithoutUCBlankSet = new Set<Id>();
        Set<Id> opportunityIdWithMarketSegmentBlankSet = new Set<Id>();
        for(Opportunity opp : lstOpportunity)
        {
            if(opp.AccountId != null && opp.Ultimate_Consignee__c == null 
              && (getIdToRecordType().get(opp.RecordTypeId).getDeveloperName() == System.Label.FieldServices
              || getIdToRecordType().get(opp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTDirectReOrder
              || getIdToRecordType().get(opp.RecordTypeId).getDeveloperName() == System.Label.OpportunityRTDirectStandard) 
              )
              {
                  opp.Ultimate_Consignee__c = opp.AccountId;
                  accountIdSet.add(opp.AccountId);
                  opportunityIdWithUCBlankSet.add(opp.Id);
              }
              if(opp.Ultimate_Consignee__c != null && String.isBlank(opp.Clinical_Type__c))
              {
                accountIdSet.add(opp.Ultimate_Consignee__c);
                opportunityIdWithoutUCBlankSet.add(opp.Id);
              }
              if(opp.Ultimate_Consignee__c != null && String.isBlank(opp.Market_Segment__c))
              {
                accountIdSet.add(opp.Ultimate_Consignee__c);
                opportunityIdWithMarketSegmentBlankSet.add(opp.Id);
              }
        }

        if(!accountIdSet.isEmpty())
        {
            Map<Id,Account> accIdToAccountMap = new Map<Id,Account>(new AccountsSelector().selectAccounts(accountIdSet));
            for(Opportunity oppty : lstOpportunity)
            {
                updateOpprtunityFields(oppty, accIdToAccountMap, opportunityIdWithUCBlankSet, opportunityIdWithoutUCBlankSet, opportunityIdWithMarketSegmentBlankSet);
            }
        }
    }

    /* method to update Opportunity fields*/
    private static void updateOpprtunityFields(Opportunity oppty, Map<Id,Account> accIdToAccountMap, 
                                    Set<Id> opportunityIdWithUCBlankSet, Set<Id> opportunityIdWithoutUCBlankSet,
                                    Set<Id> opportunityIdWithMarketSegmentBlankSet) {
        

        if(opportunityIdWithUCBlankSet.contains(oppty.Id) && accIdToAccountMap.containsKey(oppty.AccountId))
        {
            oppty.Clinical_Type__c = accIdToAccountMap.get(oppty.AccountId).Clinical_Type__c;
        }
        if(opportunityIdWithoutUCBlankSet.contains(oppty.Id) && accIdToAccountMap.containsKey(oppty.Ultimate_Consignee__c))
        {
            oppty.Clinical_Type__c = accIdToAccountMap.get(oppty.Ultimate_Consignee__c).Clinical_Type__c;
        }
        if(opportunityIdWithMarketSegmentBlankSet.contains(oppty.Id) && accIdToAccountMap.containsKey(oppty.Ultimate_Consignee__c))
        {
            Account objOppUC = accIdToAccountMap.get(oppty.Ultimate_Consignee__c);
            if(objOppUC.Market_Segment__c != Opportunities.UCMARKETSEGMENTMULTIPLE && String.isNotBlank(objOppUC.Market_Segment__c))
            {
                oppty.Market_Segment__c = objOppUC.Market_Segment__c;
            }
        }
    }

    /*Method to update Opp Clinical Type*/
    private static void updateOppClinicalType(Opportunity oppty, Map<Id,Account> accIdToAccountMap) 
    {
        if(oppty.Clinical_Type__c != accIdToAccountMap.get(oppty.Ultimate_Consignee__c).Clinical_Type__c)
        {
            oppty.Clinical_Type__c = accIdToAccountMap.get(oppty.Ultimate_Consignee__c).Clinical_Type__c;
        }
    }

    /**
     *  @author Khushbu Vasani
     *  @description  Method to return approval hierarchy record id DCP-56658
     *  @parameter Opp and Quote/Proposal
     *  @return  owner id of account
     **/
    public static Id getAccountHierarchy(Id accountOwnerID)
    { 
        getApprovalHierarchyData();
        
        if(mapOwnerIdApprovalHierarchy.containsKey(accountOwnerID))
        {
            return mapOwnerIdApprovalHierarchy.get(accountOwnerID);
        }
        return null;
    }

     /**
     *  @author Khushbu Vasani
     *  @description  Method to return account owner DCP-56658
     *  @parameter Opp and Quote/Proposal
     *  @return  owner id of account
     **/
    public static Id getAccountOwnerId(Opportunity objOpp, Apttus_Proposal__Proposal__c objProposal)
    {
        boolean booIndirectDeal = INDIRECT_RECORD_TYPES.contains(objOpp.RecordType.DeveloperName);
        
        Id accountOwnerID;
        if(objOpp.Transborder_Flag__c || objProposal.Indirect_Transregion_Flag__c)
        {
            if (booIndirectDeal)
            {
                accountOwnerID = objOpp.Distributor__r.Owner.Id;
            }
            else
            {
                accountOwnerID = objOpp.Ultimate_Consignee__r.Owner.Id;
            }
        }
        else
        {
            if (booIndirectDeal) 
            {
                accountOwnerID = objOpp.Ultimate_Consignee__r.Owner.Id;
            }
            else
            {
                accountOwnerID = objOpp.Account.Owner.Id;
            }
        }

        return accountOwnerID;
    }

     /**
     *  @author Khushbu Vasani
     *  @description  Method to return account owner DCP-56658
     *  @parameter Opp and Quote/Proposal
     *  @return  owner id of account
     **/
    public static Account getAccountIdBasedOnProposal(Apttus_Proposal__Proposal__c objProposal)
    {
        boolean booIndirectDeal = INDIRECT_RECORD_TYPES.contains(objProposal.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName);
       
        Account accountId;
        if(objProposal.Apttus_Proposal__Opportunity__r.Transborder_Flag__c || objProposal.Indirect_Transregion_Flag__c)
        {
            if (booIndirectDeal)
            {
                accountId = objProposal.Apttus_Proposal__Opportunity__r.Distributor__r;
            }
            else
            {
                accountId = objProposal.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r;
            }
        }
        else
        {
            if (booIndirectDeal) 
            {
                accountId = objProposal.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r;
            }
            else
            {
                accountId = objProposal.Apttus_Proposal__Opportunity__r.Account;
            }
        }

        return accountId;
    }

    private static void getApprovalHierarchyData()
    {       
        if (mapOwnerIdApprovalHierarchy.isEmpty())
        {
            //CMCM-4516
            List<Approval_Hierarchy__c> lstApprovalHierarchy = new ApprovalHierarchiesSelector().selectAllRecords();
            //List<Approval_Hierarchy__c> lstApprovalHierarchy = selectAllRecords();
           
            for(Approval_Hierarchy__c objApprovalHierarchy : lstApprovalHierarchy)
            {
                if(!mapOwnerIdApprovalHierarchy.containsKey(objApprovalHierarchy.Approver_Level_1__c))
                {
                    if(Label.CPQ_Sales_Hierarchy.equals(objApprovalHierarchy.Approval_Hierarchy_Type__c)){
                        mapOwnerIdApprovalHierarchy.put(objApprovalHierarchy.Approver_Level_1__c, objApprovalHierarchy.Id);
                    }
                }
            }
        }
    }

    /**
     *  @author Raja Babu
     *  @description  convert workflow Opportunity: Update Close Date For Closed Opportunity
     *  @parameter NewOppList and mapOfOldOpp
     *  @return  CloseDate
     **/
    public static void updateCloseDateToToday(List<Opportunity> lstOpps, Map<Id,Opportunity> idToOldOpps){
        for(Opportunity opp:lstOpps){
            if(opp.stageName != idToOldOpps.get(opp.Id).stageName && Opportunities.OPPTY_CLOSED_STAGES.contains(opp.StageName)){
                opp.closeDate = date.today();
            }
        }
    }

    //CMCM-4516
    /*private static List<Approval_Hierarchy__c> selectAllRecords() {
        return [
            SELECT 
            id,
            Approver_Level_1__c,
            Approver_Level_2__c, 
            Approver_Level_3__c, 
            Approver_Level_4__c, 
            Approver_Level_5__c, 
            Approver_Level_6__c,
            Approval_Hierarchy_Type__c
            FROM Approval_Hierarchy__c
        ];
    }*/
}
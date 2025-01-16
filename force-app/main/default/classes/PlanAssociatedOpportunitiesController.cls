/**
 *    @author Adyasha Satapathy
 *    @date   15-November-2021
 *    @description : DCP-50392 : Controller class for genericPlanAssociatedOpportunities LWC
 *	  @Test Class Coverage: 90% --> TestPlanAssociatedOppsController , 75% --> TestPlanAssociatedOppsController
 *    Modification Log:
 *    ----------------------------------------------------------------------------------------------- 
 *    Developer             Date                      Description
 *    Adyasha           15-November-2021            Initial Version
 *    Adyasha           23-March-2022               DCP-52242: Modified logic for Overlay Plan to retrieve opportunities based on accounts added
 *    Maruthi           07-Sep-2022                 DCP-54459: Modified logic for prepareSetAccountForAccountPlanObjective and ObjectiveOpportunityRelationshipWrapper class
 *    -----------------------------------------------------------------------------------------------        
 */
public with sharing class PlanAssociatedOpportunitiesController
{
    private static final String LOG_TITLE = 'PlanAssociatedOpportunitiesController';
    private static Id planRecordId = null;
    private static Boolean boolNoAccountsAdded = false;

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: Fetch Opportunities for Display
    *  @PARAM :  String Objective Id, String objectType
    *  @RETURN:  JSON String
    */
    @AuraEnabled
    public static String fetchOpportunitiesToDisplay(String strRecordId, String strObjectType, List<Id> lstAccountIdsFromATO)
    {    
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try{
            ilib_LogEvent.emit();
            return loadData(strRecordId,null,strObjectType,true,lstAccountIdsFromATO);
        }
        catch(Exception e)
        {
            ApexExceptions.emit(LOG_TITLE, strRecordId, e);
            throw new AuraHandledException(e.getMessage());  
        }
    }

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: wired method for Fetch Opportunities for Display
    *  @PARAM :  String Objective Id, String objectType
    *  @RETURN:  JSON String
    */
    @AuraEnabled(cacheable=true)
    public static String fetchAssociatedOpportunities(String strRecordId,String strObjectiveId,String strObjectType)
    {
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try{
            ilib_LogEvent.emit();
            return loadData(strRecordId,strObjectiveId,strObjectType,false,null);
        }
        catch(Exception e)
        {
            ApexExceptions.emit(LOG_TITLE, strRecordId, e);
            throw new AuraHandledException(e.getMessage());  
        }
    }
    
    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: Fetch Opportunities associated to objective
    *  @PARAM :  String Plan Id, String objectType
    *  @RETURN:  JSON String
    */
    @AuraEnabled            
    public static String loadData(String strRecordId,String strObjectiveId,String strObjectType, Boolean isCreate, List<Id> lstAccountIdsFromATO)
    {
        ilib_LogEvent.push(LOG_TITLE + '.loadData()');
        
        List<ObjectiveOpportunityRelationshipWrapper> lstRelationshipWrapper = new List<ObjectiveOpportunityRelationshipWrapper>();
        List<ObjectiveOpportunityRelationshipWrapper> lstOpportunityWrapper = new List<ObjectiveOpportunityRelationshipWrapper>();
        List<Objective_Opportunity_Relationship__c> lstObjectiveOpportunityRelationship = null;
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setExistingOpportunityIds = new Set<Id>();
        Set<String> setTerritoryCode = new Set<String>();            
        Boolean isTerritoryPlanObjective = checkIfTerritoryPlanObjective(strObjectType);

        ilib_LogEvent.message('PlanAssociatedOpportunitiesController.inside loadData');
        ilib_LogEvent.message('strObjectType ::: '+strObjectType);
        ilib_LogEvent.message('strRecordId ::: '+strRecordId);

        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> lstPickList = fieldResult.getPicklistValues();
        
        if(isTerritoryPlanObjective)
        {   
            prepareSetAccountForTerritoryPlanObjective(strRecordId,strObjectiveId,setTerritoryCode,setAccountIds,isCreate,lstAccountIdsFromATO);                                    
        }
        else 
        {
            prepareSetAccountForAccountPlanObjective(strRecordId, setAccountIds);                
        }
        
        if(!isCreate)
        {
            lstObjectiveOpportunityRelationship = new ObjectiveOpportunityRelationshipSelector().selectAssociationByObjectiveIds(new Set<Id>{strObjectiveId},isTerritoryPlanObjective);

            for(Objective_Opportunity_Relationship__c objRelationship : lstObjectiveOpportunityRelationship)
            {
                lstRelationshipWrapper.add(new ObjectiveOpportunityRelationshipWrapper(objRelationship));
                setExistingOpportunityIds.add(objRelationship.Opportunity__c);
            }
        }
        
        List<Opportunity> lstOpportunity = new OpportunitySelector().selectOpportunitiesByAccountRecordIds(setAccountIds);
        
        for(Opportunity objOpportunity : lstOpportunity) 
        {
            if(!setExistingOpportunityIds.contains(objOpportunity.Id))
            {
                lstOpportunityWrapper.add(new ObjectiveOpportunityRelationshipWrapper(objOpportunity));
            }
        }
        ilib_LogEvent.pop();
        return '{"lstObjectiveOppRelationshipWrapper": '+JSON.serialize(lstRelationshipWrapper)+','
                +'"lstOpportunityWrapper": '+JSON.serialize(lstOpportunityWrapper)+','
                +'"planRecordId": '+JSON.serialize(planRecordId)+','
                +'"isTerritoryPlanObjective": '+JSON.serialize(isTerritoryPlanObjective)+','
                +'"boolNoAccountsAdded": '+JSON.serialize(boolNoAccountsAdded)+','
                +'"opportunityStageValues": '+JSON.serialize(lstPickList)+'}';    

    }

    /*
    *  @AUTHOR:         Adyasha
    *  @DESCRIPTION:    Delete Objective Opportunity Relationship Records
    *  @PARAM :         List of Objective Opportunity Relationship Records
    *  @RETURN:         String
    */
    @AuraEnabled
    public static String deleteAssociatedOpportunities(List<String> lstRecordIds)
    {
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try
        {
            List<Objective_Opportunity_Relationship__c> lstRecordsToDelete = new List<Objective_Opportunity_Relationship__c>();
            
            for(String recordId : lstRecordIds)
            {
                lstRecordsToDelete.add(new Objective_Opportunity_Relationship__c(id = recordId)); 
            }

            delete lstRecordsToDelete;
            ilib_LogEvent.emit();
            return  Label.UI_Message_OOR_Delete.replace('{0}',String.valueOf(lstRecordsToDelete.size()));
        }
        catch(Exception e)
        {
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(e.getMessage());  
        }
    }

    /*
    *  @AUTHOR:         Adyasha
    *  @DESCRIPTION:    Create Objective Opportunity Relationship Records
    *  @PARAM :         List of Opportunity Ids, objective Id, Object Type
    *  @RETURN:         String
    */
    @AuraEnabled
    public static String addAssociatedOpportunities(String strRecordData)
    {
        ilib_LogEvent.setTitle(LOG_TITLE); 
        try
        {
            List<Objective_Opportunity_Relationship__c> lstObjectiveOpportunityRelationshipRecords = (List<Objective_Opportunity_Relationship__c>)JSON.deserializeStrict(strRecordData, List<Objective_Opportunity_Relationship__c>.class);
            insert lstObjectiveOpportunityRelationshipRecords;
            ilib_LogEvent.emit();
            return Label.UI_Message_OOR_Create.replace('{0}',String.valueOf(lstObjectiveOpportunityRelationshipRecords.size()));
        }
        catch(Exception e)
        {
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(e.getMessage());  
        }
    }

    private static void prepareSetAccountForTerritoryPlanObjective(String strRecordId,String strObjectiveId,Set<String> setTerritoryCode, Set<Id> setAccountIds, Boolean isCreate, List<Id> lstAccountIdsFromATO)
    {
        Plan__c objPlan = new PlanSelector().getTerritoryPlanbyId(strRecordId)[0];

        planRecordId = objPlan.Id;
        //DCP-52242
        if(objPlan.RecordType.DeveloperName == Label.PlanOverlay)
        {
            if(isCreate)
            {
                setAccountIds.addAll(lstAccountIdsFromATO);  
            }
            else {
                List<Plan_Objective_Account__c> lstPlanObjectiveAccount = new PlanObjectiveAccountSelector().getAccountByPlanObjectiveId(strObjectiveId);            
                setAccountIds.addAll(UtilsCollection.getSetOfIds(lstPlanObjectiveAccount,'Account__c'));
                if(setAccountIds.isEmpty()) { boolNoAccountsAdded = true; }
            }
        }
        else 
        {
            if(userinfo.getUserType() == Label.UserTypeStandard && String.isNotBlank(objPlan.Territory_Code__c))
            {
                setTerritoryCode.add(objPlan.Territory_Code__c);
            }
            if(objPlan.RecordType.DeveloperName == Label.Plan_Indirect)
            {
                if(String.isNotBlank(objPlan.Territory_Code__c))
                {
                    setTerritoryCode.add(objPlan.Territory_Code__c);
                }

                if(String.isNotBlank(objPlan.Channel_Partner_Territory_Code__c))
                {
                    setTerritoryCode.add(objPlan.Channel_Partner_Territory_Code__c);
                }
            }            
            
            ilib_LogEvent.message('setTerritoryCode ::: '+setTerritoryCode);

            for(ObjectTerritory2Association objObjectTerritory2Association : new ObjectTerritory2AssociationsSelector().getByTerritoryCode(setTerritoryCode))
            {            
                setAccountIds.add(objObjectTerritory2Association.objectId);                
            }
        }
    }

    private static void prepareSetAccountForAccountPlanObjective(String strRecordId, Set<Id> setAccountIds)
    {
        if(String.isNotBlank(strRecordId))
        {
            Account_Plan__c objAccountPlan = new AccountPlanSelector().getAccountPlanByAccountPlanRecordId(strRecordId);        
            planRecordId = strRecordId;
            List<Account> accHirList = new AccountsSelector().getAccountsHierarchy(String.valueOf(objAccountPlan.Account_Name__r.Ultimate_Parent_Id__c), objAccountPlan.Account_Name__r.Ultimate_Parent__c);//DCP-54459
            setAccountIds.addAll(UtilsCollection.getSetOfIds(accHirList,'Id'));
        }
    }

    private static Boolean checkIfTerritoryPlanObjective(String strObjectType)
    {
        Boolean isTerritoryPlanObjective = false;
        if(strObjectType == Label.UI_Label_Objective_API)
        {
            isTerritoryPlanObjective =  true;
        }
        return isTerritoryPlanObjective;
    }   

    /*
    *  @AUTHOR:  Adyasha
    *  @DESCRIPTION: Wrapper class for storing Objective Opportunity Relationship Data
    */
    public class ObjectiveOpportunityRelationshipWrapper
    {
        public String strRecordID;
        public String strOpportunityURL;
        public String strOpportunityName;
        public String strOwnerURL;
        public String strOwnerName;
        public Boolean boolRelatedToTerritoryPlan;        
        public String strOpportunityId;
        public String strOpportunityRecordType;
        public String strOpportunityStageName;
        public String strOpportunityCloseDate;
        public String strOpportunityProbability;
        public String strOpportunityAmount;
        public String strOpportunityMarketSegment;
        public String strOpportunityProductType;
        public String strAmount;     
		public String strAccountName;//DCP-54459
        public String erpId;//DCP-54459
        public String parentAccount;//DCP-54459

        /* constructor with relationship as parameter*/
        public ObjectiveOpportunityRelationshipWrapper(Objective_Opportunity_Relationship__c relationship)
        {            
            this.strRecordID = relationship.Id;
            this.strOpportunityURL = '/'+relationship.Opportunity__c;
            this.strOpportunityName = relationship.Opportunity__r.Name;
            this.strOwnerName = relationship.Opportunity__r.Owner.Name;
            this.strOwnerURL = '/'+relationship.Opportunity__r.OwnerId;
            this.strOpportunityRecordType = relationship.Opportunity__r.RecordType.Name;
            this.strOpportunityStageName = relationship.Opportunity__r.StageName;
            this.strOpportunityProbability = String.valueOf(relationship.Opportunity__r.Probability);
            this.strOpportunityCloseDate = String.valueOf(relationship.Opportunity__r.CloseDate);
            this.strAmount = relationship.Opportunity__r.Amount == null ? '0.00' : String.valueOf(relationship.Opportunity__r.Amount);
            this.strOpportunityAmount = relationship.Opportunity__r.CurrencyIsoCode + ' ' + strAmount;
            this.strOpportunityMarketSegment = relationship.Opportunity__r.Market_Segment__c;
            this.strOpportunityProductType = relationship.Opportunity__r.Product_Type__c;
			this.strAccountName = relationship.Opportunity__r.Account.Name;//DCP-54459
            this.erpId = relationship.Opportunity__r.Account.ERP_Customer_Id__c;//DCP-54459
            this.parentAccount = relationship.Opportunity__r.Account.Ultimate_Parent__c;//DCP-54459
        }

        /* constructor with opportunity as parameter*/
        public ObjectiveOpportunityRelationshipWrapper(Opportunity objOpportunity)
        {  
            this.strOpportunityId = objOpportunity.Id;
            this.strOpportunityURL = '/' + objOpportunity.Id;
            this.strOpportunityName = objOpportunity.Name;            
            this.strOpportunityRecordType = objOpportunity.RecordType.Name;
            this.strOpportunityStageName = objOpportunity.StageName;
            this.strOpportunityProbability = String.valueOf(objOpportunity.Probability);
            this.strOpportunityCloseDate = String.valueOf(objOpportunity.CloseDate);
            this.strAmount = objOpportunity.Amount == null ? '0.00' : String.valueOf(objOpportunity.Amount);
            this.strOpportunityAmount = objOpportunity.CurrencyIsoCode + ' ' + strAmount; 
            this.strOpportunityMarketSegment = objOpportunity.Market_Segment__c;
            this.strOpportunityProductType = objOpportunity.Product_Type__c;            
            this.strOwnerName = objOpportunity.Owner.Name;
			this.strAccountName = objOpportunity.Account.Name;//DCP-54459
            this.erpId = objOpportunity.Account.ERP_Customer_Id__c;//DCP-54459
            this.parentAccount = objOpportunity.Account.Ultimate_Parent__c ;//DCP-54459
        }
    }
}


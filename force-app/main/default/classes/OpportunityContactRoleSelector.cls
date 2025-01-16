/**
*    @author Govind Dubey
*    @date   2018-05-25
*    @description    DCP-1010,548: Opportunities Selector class
*    Modification Log:
*    ----------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey                25 May 2018            Opportunities Selector Class
*             Indra Ganesan               03 Aug 2018            Modification done for DCP-7387
*             Jitesh Lakhwani             6-July-2022            Code Scan fixes of Comments
*             Rishab Wali                 31-Aug-2022            DCP-55949 Waterfall Changes
*             Deep Diwakar               June-29-2023            DCP-60098: Removed whitespace from selectInvalidOppContactIds method query
*             Deep Diwakar                Aug-15-2023            DCP-60131: Added selectOpenOpptyContRoleByContactId method
*    ------------------------------------------------------------------------------------------- 
*                    
*/
public with sharing class OpportunityContactRoleSelector extends ilib_SObjectSelector{
    
    /**
     * @description  This method will return the SObjectType of the Opportunity Contact Role Object
     * @param : None
     * @return : Schema.SObjectType
    */
	public Schema.SObjectType getSObjectType()
    {
        return OpportunityContactRole.sObjectType;
    }
    
    /**
     *  @author  Govind Dubey 
     *  @description Retrieve list of fields for OpportunityContactRole sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           OpportunityContactRole.isPrimary,
            OpportunityContactRole.Role,
           OpportunityContactRole.contactId,
           OpportunityContactRole.id,
           OpportunityContactRole.OpportunityId
       };
    }
    
    /**
     *  @author Govind Dubey
     *  @description Fetch OpportunityContactRole for the opportuties
     *  @param opportunityIds Set of Opportunity Ids
     *  @return OpportunityContactRoleList List of OpportunityContactRole
     **/
    public List<OpportunityContactRole> selectRoles(Set<Id> opportunityIds) 
    {
        return (List<OpportunityContactRole>) Database.query(
            newQueryFactory().setCondition('OpportunityId IN :opportunityIds').toSOQL()
        );
    }
	
	/**
     *  @author Pankaj Singla
     *  @description Fetch OpportunityContactRole for the opportunities
     *  @param opportunityIds Set of Opportunity Ids
        @param Contact Marketing Status to be considered for the process
     *  @return OpportunityContactRoleList List of OpportunityContactRole
     **/
    public List<OpportunityContactRole> selectAllOppContactIds(Set<Id> opportunityIds,string strOpenOpportunity) 
    {
        return (List<OpportunityContactRole>) Database.query(
        newQueryFactory().selectField('contact.Disposition_Code__c')
                  .selectField('contact.Marketing_Contact_Status__c')
                  .selectField('Opportunity.stagename')
            	  .selectField('contact.Waterfall_Engaged_Date__c')
            	  .selectField('contact.Waterfall_Qualified_Date__c')
				  .selectField('contact.Waterfall_Stage__c')
                  .selectField('contact.Waterfall_Sales_Accepted_Date__c')
                  .selectField('contact.Waterfall_Opportunity_Date__c')
            	  .selectField('contact.Waterfall_Closed_Won_Date__c')
            	  .selectField('Opportunity.Type') //DCP-55949
            	  .selectField('Opportunity.LeadSource') //DCP-55949
                  .selectField('Contact.Last_Responded_Campaign_Date__c') //DCP-55949
                  .setCondition('OpportunityId IN :opportunityIds and contact.Marketing_Contact_Status__c =:strOpenOpportunity').toSOQL());
    }
    
    /**
     *  @author Pankaj Singla
     *  @description Fetch OpportunityContactRole for the opportunities
     *  @param setContactIds Set of Contact Ids
        @param Contact Marketing Status to be considered for the process
        @param setClosedOpportunityStatusString: set of closed opportunities stage values
     *  @return OpportunityContactRoleList List of OpportunityContactRole
     **/
     
    public List<OpportunityContactRole> selectInvalidOppContactIds(Set<Id> setContactIds,set<string> setClosedOpportunityStatusString,string strOpenOpportunity) 
    {
        return (List<OpportunityContactRole>) Database.query(
        newQueryFactory().selectField('contact.Disposition_Code__c')
                  .selectField('contact.Marketing_Contact_Status__c')
                  .selectField('Opportunity.stagename')
                  .setCondition('ContactId in:setContactIds and contact.Marketing_Contact_Status__c =:strOpenOpportunity and Opportunity.stagename not in :setClosedOpportunityStatusString').toSOQL());
    }
    
    /**
     *  @description Fetch OpportunityContactRole for the opportunities
     *  @param setContactIds Set of Contact Ids
     *  @param setClosedOpportunityStatusString: set of closed opportunities stage values
     *  @return OpportunityContactRoleList List of OpportunityContactRole
     **/
	public List<OpportunityContactRole> selectValidContactOppAssociations(Set<Id> setContactIds,set<String> setClosedOpportunityStatusString) 
    {
        return (List<OpportunityContactRole>) Database.query(
        newQueryFactory().selectField('contact.Disposition_Code__c')
                  .selectField('contact.Marketing_Contact_Status__c')
                  .selectField('Opportunity.stagename')
                  .setCondition('ContactId in:setContactIds and Opportunity.stagename not in:setClosedOpportunityStatusString').toSOQL());
    }

        /**
     *  @author: Deep Diwakar
     *  @description Fetch OpportunityContactRole for the opportunities
     *  @param opportunityIds Set of OpportunityContactRole Ids
        @param Contact Marketing Status to be considered for the process
     *  @return OpportunityContactRoleList List of OpportunityContactRole
     **/
    public List<OpportunityContactRole> selectOpenOpptyContRoleByContactId(Set<Id> setContactIds, Set<String> openOpptyStages) {
        return (List<OpportunityContactRole>) Database.query(
            newQueryFactory().selectField('Contact.Disposition_Code__c')
                      .selectField('Contact.Marketing_Contact_Status__c')
                      .selectField('Contact.Waterfall_Engaged_Date__c')
                      .selectField('Contact.Waterfall_Qualified_Date__c')
                      .selectField('Contact.Waterfall_Stage__c')
                      .selectField('Contact.Waterfall_Sales_Accepted_Date__c')
                      .selectField('Contact.Waterfall_Opportunity_Date__c')
                      .selectField('Contact.Waterfall_Closed_Won_Date__c')
                      .selectField('Contact.Last_Responded_Campaign_Date__c')
                      .selectField('Opportunity.Type')
                      .selectField('Opportunity.Stagename')
                      .selectField('Opportunity.LeadSource')
                      .setCondition('ContactId IN :setContactIds and Opportunity.Stagename IN : openOpptyStages').toSOQL());
    }
}
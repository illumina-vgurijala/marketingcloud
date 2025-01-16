/**
*    @author Pankaj Singla
*    @date   2018-10-15
*    @description    CampaignMember Selector class
*    Modification Log:
*    ----------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                15 Oct 2018           CampaignMember Selector Class
*			  Pankaj Singla				   04 Jun 2020			 DCP-35844 Added new method selectCampaignMembersInsertScoring
*             Nishan Shetty                08 Jun 2021           SPQ-15  Added new method selectCampaignMembers.
*             Nishan Shetty                24 Jun 2021           SPQ-45  Added fields in getSObjectFieldList method and added selectCampaignMembersListCampaign method.  
*             Rishi Sharma				   28 Jun 2021	         SPQ-37  Added 4 new methods selectCampaignMembersLead, selectCampaignMembersContact, 
*																 selectOrderedMarketingCampaignMembersContact and selectOrderedMarketingCampaignMembersLead		
*             Rishab Wali                  31 Aug 2021           [DCP-49604] Adding Query Instrumentation   
*             Deep Diwakar                 Sept-10-2021          DCP-49866: Adding Lead.isConverted field in query
*             Rishab Wali                  29 Nov 2021           [DCP-49756] Update Most Recent Activity Field on Leads    
*             Deep Diwakar                 June-18-2023          CMCM-1160: Added new Campaign_Subregion__c field   		
*    ------------------------------------------------------------------------------------------- 
*                    
*/
public with sharing class CampaignMemberSelector extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'CampaignMemberSelector';
    public static final String MARKETING_QUERY_LOGS = 'MarketingQueryLogs';
    public static final String STRING_CREATED_DATE = 'CreatedDate';

    /*Method - getSObjectType() , Params - None*/
    public Schema.SObjectType getSObjectType()
    {
        return CampaignMember.sObjectType;
    }
    
    /*Method - getSObjectFieldList() , Params - None , Description - Fields to be included in the query*/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           CampaignMember.CampaignId,
           CampaignMember.ContactId,
           CampaignMember.LeadId,
           CampaignMember.id,
           CampaignMember.Name,
           CampaignMember.Type,
           CampaignMember.Status,
           CampaignMember.HasResponded,
           CampaignMember.Campaign_Member_Owner__c,//SPQ-45
           CampaignMember.Campaign_Attribution__c,//SPQ-45
           CampaignMember.Last_Form_Submission_URL__c,//SPQ-45
           CampaignMember.Opt_In_Status__c,//SPQ-45
           CampaignMember.Last_Marketing_Campaign__c,//SPQ-45
           CampaignMember.et4ae5__Activity__c,//SPQ-45
           CampaignMember.Free_Trial_End_Date__c,//SPQ-45
           CampaignMember.Free_Trial_iCredit_Balance__c,//SPQ-45
           CampaignMember.Free_Trial_Start_Date__c,//SPQ-45
           CampaignMember.Free_Trial_Subscription_ID__c,//SPQ-45
           CampaignMember.Last_Form_Submission_URL__c,//SPQ-45
           CampaignMember.Last_Marketing_Campaign__c,//SPQ-45
           CampaignMember.Legacy_SFDC_Record_ID__c,//SPQ-45
           CampaignMember.Subscription_Status__c,//SPQ-45
           CampaignMember.CurrencyIsoCode,//SPQ-45
           CampaignMember.HasOptedOutOfEmail,//SPQ-45
           CampaignMember.HasOptedOutOfFax,//SPQ-45
           CampaignMember.FirstName,//SPQ-45
           CampaignMember.LastName,//SPQ-45
           CampaignMember.CompanyOrAccount//SPQ-45


       };
    }
    
    /*Method - selectCampaignMembersList
      ReturnType - List<CampaignMember>
      Param - List<CampaignMember> 
      */
    public List<CampaignMember> selectCampaignMembersList(List<CampaignMember> lstCampaignMember) 
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            Set<Id> setCampainMemberIds = UtilsCollection.getSetOfIds(lstCampaignMember);
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignMembersList',UtilsCollection.serializeIds(setCampainMemberIds));
        }

        List<CampaignMember> res =  (List<CampaignMember>) Database.query(
                                        newQueryFactory().selectField('Campaign.Type')
                                        .selectField('Lead.Webinar_Attended_Date__c')
                                        .selectField('Lead.Email')
                                        .selectField('Contact.Email')            
                                        .selectField('Lead.Webinar_Attended_Date__c')
                                        .selectField('Contact.Webinar_Attended_Date__c')
                                        .selectField('Lead.LeadSource')
                                        .selectField('Lead.Id')
                                        .selectField('Lead.CreatedBy.Name') 
                                        .selectField('Lead.CreatedDate')
                                        .selectField('Lead.isConverted')
                                        .selectField('Lead.First_Responded_Campaign__c')
                                        .selectField('Lead.First_Responded_Campaign_Date__c')
                                        .selectField('Campaign.Do_not_score__c')
                                        .selectField('Campaign.Name')
                                        .selectField('Campaign.Channel__c')
                                        .selectField('Campaign.Campaign_Region__c')
                                        .selectField('Campaign.Do_not_score__c')
                                        .selectField('Campaign.Campaign_District__c')
                                        .selectField('Campaign.Campaign_Subregion__c')
                                        .selectField('Campaign.Organization_Ownership__c')
                                        .selectField('Lead.Marketing_Score__c')
                                        .selectField('Contact.Marketing_Score__c')
                                        .selectField('Lead.Marketing_Suppression__c')
                                        .selectField('Contact.Marketing_Suppression__c')
                                        .selectField('Contact.First_Responded_Campaign__c')
                                        .selectField('Contact.First_Responded_Campaign_Date__c')
                                        .setCondition('id IN :lstCampaignMember').toSOQL()
                                    );

            if (Feature.isOn(MARKETING_QUERY_LOGS)){
                    logger.stop(res.size());
            }
            return res;                        
    }

    /**
     *  @author Pankaj Singla
     *  @description Select campaignMember for contact id and CampaignIds
     *  @param setContactIds  set of contact Ids
     *  @param setCampaignIds  set of campaign Ids
     *  @return List of CampaignMember
     **/ 
    public List<CampaignMember> selectCampaignMembersListContact(Set<String> setContactIds,Set<String> setCampaignIds) 
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            String strInput = UtilsCollection.serializeIds(setContactIds) + '::' +  UtilsCollection.serializeIds(setCampaignIds);
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignMembersListContact' , strInput);
        }

        List<CampaignMember> res = (List<CampaignMember>) Database.query(
            newQueryFactory()       
            .setCondition('CampaignId in:setCampaignIds and ContactId in :setContactIds').toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res; 
    }

    /**
     *  @author Pankaj Singla
     *  @description Select campaignMember for contact id and CampaignIds
     *  @param setLeadIds  set of Lead Ids
     *  @param setCampaignIds  set of campaign Ids
     *  @return List of CampaignMember
     **/

    public List<CampaignMember> selectCampaignMembersListLead(Set<String> setLeadIds,Set<String> setCampaignIds)
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            String strInput = UtilsCollection.serializeIds(setLeadIds) + '::' +  UtilsCollection.serializeIds(setCampaignIds);
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignMembersListLead' , strInput);
        }

        List<CampaignMember> res = (List<CampaignMember>) Database.query(
            newQueryFactory()       
            .setCondition('CampaignId in:setCampaignIds and LeadId in :setLeadIds').toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }

     /**
     *  @author Rishi Sharma
     *  @description Select campaignMember for lead id and CampaignIds
     *  @param setLeadIds  set of Lead Ids
     *  @param setCampaignIds  set of campaign Ids
     *  @return List of CampaignMember
     **/

    public List<CampaignMember> selectOrderedMarketingCampaignMembersLead(Set<Id> setLeadIds)
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOrderedMarketingCampaignMembersLead',UtilsCollection.serializeIds(setLeadIds));
        }

        List<CampaignMember> res = (List<CampaignMember>) Database.query(
            newQueryFactory()  
            .selectField('CampaignId')
            .selectField(STRING_CREATED_DATE)
            .setCondition('Campaign.Organization_Ownership__c = \'Marketing\' and LeadId in :setLeadIds')
            .addOrdering(STRING_CREATED_DATE, ilib_QueryFactory.SortOrder.ASCENDING).toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }

	 /**
     *  @author Rishi Sharma
     *  @description Select Marketing campaignMember for contact id and CampaignIds
     *  @param setContactIds  set of contact Ids
     *  @return List of CampaignMember
     **/

    public List<CampaignMember> selectOrderedMarketingCampaignMembersContact(Set<Id> setContactIds)
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectOrderedMarketingCampaignMembersContact',UtilsCollection.serializeIds(setContactIds));
        }

        List<CampaignMember> res = (List<CampaignMember>) Database.query(
            newQueryFactory()  
            .selectField('CampaignId')
            .selectField(STRING_CREATED_DATE)
            .setCondition('Campaign.Organization_Ownership__c = \'Marketing\' and ContactId in :setContactIds')
            .addOrdering(STRING_CREATED_DATE, ilib_QueryFactory.SortOrder.ASCENDING).toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }

    /**
     *  @author Rishi Sharma
     *  @description Select Sales campaignMember for contact id and CampaignIds
     *  @param setContactIds  set of contact Ids
     *  @param cmId set of Campaign Member Ids
     *  @return List of CampaignMember
     **/

    public List<CampaignMember> selectCampaignMembersContact(Set<Id> setContactIds, Set<Id> cmId)
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            String strInput = UtilsCollection.serializeIds(setContactIds) + '::' +  UtilsCollection.serializeIds(cmId);
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignMembersContact' , strInput);
        }

        List<CampaignMember> res = (List<CampaignMember>) Database.query(
            newQueryFactory()       
            .setCondition('ContactId in :setContactIds and Id NOT IN: cmId').toSOQL()
        );
        
        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;

    }

     /**
     *  @author Rishi Sharma
     *  @description Select Marketing campaignMember for contact id and CampaignIds
     *  @param setLeadIds  set of contact Ids
     *  @param cmId set of Campaign Member Ids
     *  @return List of CampaignMember
     **/

    public List<CampaignMember> selectCampaignMembersLead(Set<Id> setLeadIds, Set<Id> cmId)
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            String strInput = UtilsCollection.serializeIds(setLeadIds) + '::' +  UtilsCollection.serializeIds(cmId);
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignMembersLead' , strInput);
        }

        List<CampaignMember> res = (List<CampaignMember>) Database.query(
            newQueryFactory()       
            .setCondition('LeadId in :setLeadIds and Id NOT IN: cmId').toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;        
    }        

    /*
     *  @author Nishan Shetty
     *  @description Select campaignMember
     *  @param setCampainMemberIds Set of campaignmember Ids
     *  @return List of CampaignMember
     */
    public List<CampaignMember> selectCampaignMembers(Set<Id> setCampainMemberIds) {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignMembers',UtilsCollection.serializeIds(setCampainMemberIds));
        }

        List<CampaignMember> res = (List<CampaignMember>) Database.query(
             newQueryFactory().selectField('Campaign.Name')
            .selectField('Campaign_Member_Notes__c')
			.selectField('Campaign.Organization_Ownership__c') //DCP-49756
            .selectField('LastModifiedDate') //DCP-49756
            .setCondition('id IN :setCampainMemberIds').toSOQL()
        );

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
    /*
     *  @author Nishan Shetty [SPQ-45]
     *  @description Select campaignMember
     *  @param setCampaignIds Set of campaign Ids
     *  @return List of CampaignMember
     */
    public List<CampaignMember> selectCampaignMembersListCampaign(Set<Id> setCampaignIds) {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignMembersListCampaign',UtilsCollection.serializeIds(setCampaignIds));
        }

        List<CampaignMember> res = (List<CampaignMember>) Database.query(
             newQueryFactory().selectField('Campaign.Name')
            .selectField('Campaign_Member_Notes__c')
            .setCondition('CampaignId IN :setCampaignIds').toSOQL()
        );
        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }


}

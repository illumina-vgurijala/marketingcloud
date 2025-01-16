/**
*    @author Roopal Verma
*    @date   2020-01-16
*    @description    Campaign Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Roopal Verma                  16 Jan 2020         Campaign Selector class
*             Nishan Shetty                 08 Jun 2021         (SPQ-15) selectCampaigns method to retrieve 
*                                                                Campaigns.
*             Rishab Wali                  31 Aug 2021           [DCP-49604] Adding Query Instrumentation  
*             Deep Diwakar                 Aug-08-2024           CMCM-9421: Added one field in selectCampaign method
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class CampaignSelector extends ilib_SObjectSelector {

    public static final string LOG_TITLE = 'CampaignSelector';
    public static final String MARKETING_QUERY_LOGS = 'MarketingQueryLogs';

    /*
     *  @author                     : Roopal Verma
     *  @description                : Get sObjectType.
     *  @return                     : sObjectType for Campaign.
     * 
    */
    public Schema.SObjectType getSObjectType() {
        return Campaign.sObjectType;
    }
    
    /**
    *  @author  Roopal Verma
    *  @description Retrieve list of fields for Campaign Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Campaign.id
        }; 
    }
    
    /**
    *  @author Roopal Verma
    *  @description Fetch the Campaign
    *  @param Zuora Product Id 
    *  @return List of Accounts  
    **/
    public List<Campaign> selectCampaign(Set<String> setZuoraProductId) {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaign',UtilsCollection.serializeIds(setZuoraProductId));
        }

        List<Campaign> res = (List<Campaign>) Database.query(
                                    newQueryFactory().selectField('Product__r.Zuora_Product_ID__c').setCondition('Product__r.Zuora_Product_ID__c IN: setZuoraProductId').toSOQL()
        );

        if(Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res; 
    } 
    
    /*
     *  @author Rishi Sharma
     *  @description Select Campaign 
     *  @param setCampaignIds Set of Campaign Ids
     *  @return List of Campaign
     */
    public List<Campaign> selectCampaignOrganizationOwnership( Set<Id> setCampaignIds) {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignOrganizationOwnership',UtilsCollection.serializeIds(setCampaignIds));
        }

        List<Campaign> res = (List<Campaign>) Database.query(
            newQueryFactory()
            .selectField('Organization_Ownership__c')
            .selectField('Type')
            .setCondition('id IN :setCampaignIds').toSOQL()
            );

        if(Feature.isOn(MARKETING_QUERY_LOGS)){
           logger.stop(res.size());
        }
        return res;             
    }
    
    /*
     *  @author Nishan Shetty
     *  @description Select campaignMember 
     *  @param setCampaignIds Set of Campaign Ids
     *  @return List of Campaign
     */
    public List<Campaign> selectCampaigns( Set<Id> setCampaignIds) {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaign',UtilsCollection.serializeIds(setCampaignIds));
        }

        List<Campaign> res = (List<Campaign>) Database.query(
            newQueryFactory()
            .selectField('Name')
            .selectField('Type')
            .setCondition('id IN :setCampaignIds').toSOQL()
            );

        if(Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(res.size());
            }
            return res;   
    }
    
}
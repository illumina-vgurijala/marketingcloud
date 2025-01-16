/**
*    @author: Pankaj 
*    @date:   10-Sept-2018
*    @description:  selector class for campaign member status
*    Test Class - TestCampaignMemberSelector
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        10-Sept-2018        Selector class for campaign member status object
*             Rishab Wali                   21-Nov-2022         [DCP-58632] Added Query Instrumentation
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class CampaignMemberStatusSelector extends ilib_SObjectSelector {
    
    private static final String LOG_TITLE = 'CampaignMemberStatusSelector';
    private static final String STRMARKETINGQUERYLOGS = 'MarketingQueryLogs';

    /*
    *  Description: Constructor CampaignMemberStatusSelector created
    */

    public CampaignMemberStatusSelector()
    {
        super(false, false, false, false);
        
    }
    /*
    *  Description: getSObjectType created
    */

    public Schema.SObjectType getSObjectType()
    {
        return CampaignMemberStatus.sObjectType;
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description Retrieve list of fields for Campaign member status sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            CampaignMemberStatus.CampaignId,
            CampaignMemberStatus.HasResponded,
            CampaignMemberStatus.IsDefault,
            CampaignMemberStatus.Label,
            CampaignMemberStatus.SortOrder,
            CampaignMemberStatus.id
            
            
        };
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description sort the records using sortorder 
     *  
     **/
    public override String getOrderBy() {
        return 'SortOrder ASC';
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description Fetch the list of CampaignMemberStatus Records
     *  @param List of campaign records - Trigger.New
     **/
    public List<CampaignMemberStatus> selectCampaignMemberStatus(List<Campaign> lstCampaign) 
    {

        ilib_LogQuery logger = null;

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            Set<Id> setCampaignIds = UtilsCollection.getSetOfIds(lstCampaign);
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignMemberStatus',UtilsCollection.serializeIds(setCampaignIds));
        }

        List<CampaignMemberStatus> res = (List<CampaignMemberStatus>) Database.query(newQueryFactory().setCondition('CampaignId in :lstCampaign').toSOQL());
        
        if(Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger.stop(res.size());
        }
        return res; 
    }   
    
    
}
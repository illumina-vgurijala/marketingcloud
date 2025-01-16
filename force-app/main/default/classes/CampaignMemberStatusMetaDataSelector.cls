/**
*    @author: Pankaj 
*    @date:   10-Sept-2018
*    @description:  selector class for campaign member status
*    Test Class - TestCampaignMemberSelector
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        10-Sept-2018        Selector class for CampaignMemberStatusMetaData
*             Rishab Wali                   21-Sept-2022        [DCP-56317] Adding new Channel field in the custom metadata selector
*             Rishab Wali                   21-Nov-2022         [DCP-58632] Added Query Instrumentation
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class CampaignMemberStatusMetaDataSelector extends ilib_SObjectSelector {
    
    private static final String LOG_TITLE = 'CampaignMemberStatusMetaDataSelector';
    private static final String STRMARKETINGQUERYLOGS = 'MarketingQueryLogs';

    /*
    *  Description: CampaignMemberStatusMetaDataSelector created
    */

    public CampaignMemberStatusMetaDataSelector()
    {
        super(false, false, false, false);
        
    }
    /*
    *  Description: getSObjectType created
    */

    public Schema.SObjectType getSObjectType()
    {
        return Campaign_Member_Status__mdt.sObjectType;
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description Retrieve list of fields for CampaignMemberStatusMetaData 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Campaign_Member_Status__mdt.Campaign_Member_Status_Label__c,
            Campaign_Member_Status__mdt.Campaign_Type__c,
            Campaign_Member_Status__mdt.HasResponded__c,
            Campaign_Member_Status__mdt.IsDefault__c,
            Campaign_Member_Status__mdt.Sort_Order__c,
            Campaign_Member_Status__mdt.MasterLabel,
            Campaign_Member_Status__mdt.DeveloperName,
            Campaign_Member_Status__mdt.Active__c,
            Campaign_Member_Status__mdt.Campaign_Channel__c  //DCP-56317
        };
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description Sort the records by Sort_Order__c
     *  
     **/
     
    public override String getOrderBy() {
        return 'Sort_Order__c ASC';
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description Fetch the list of CampaignMemberStatusMetaData where Active is true
     *  
     **/ 
    public List<Campaign_Member_Status__mdt> selectCampaignMemberMetaRecords() 
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCampaignMemberMetaRecords','All active records');
        }

        List<Campaign_Member_Status__mdt> res = (List<Campaign_Member_Status__mdt>) Database.query(newQueryFactory().setCondition('Active__c = true').toSOQL());

        if(Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger.stop(res.size());
        }

        return res;
    }   
    
    
}
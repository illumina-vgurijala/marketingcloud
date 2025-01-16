/**
*    @author Pankaj Singla
*    @date   2020-06-04
*    @description  ProspectScoringMetadata selector class
*    Test Class - TestCampaignMemberSelector
*    Modification Log:
*    ----------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                04 Jun 2020          Initial Build	
*             Aman Tyagi                   31 March 2022        Codescan Fixes		
*             Rishab Wali                  21-Nov-2022          [DCP-58632] Added Query Instrumentation  
*    ------------------------------------------------------------------------------------------- 
*/
public with sharing class ProspectScoringMetadataSelector extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'ProspectScoringMetadataSelector';
    private static final String STRMARKETINGQUERYLOGS = 'MarketingQueryLogs';

    /*
    * @Author: Pankaj Singla 
    * @Description : method to get the sObject type
    * @param :null
    */
    public Schema.SObjectType getSObjectType()
    {
        return Prospect_Scoring_Metadata__mdt.sObjectType;
    }

    /*
    * @Author: Pankaj Singla 
    * @Description : method to get the sObject field list
    * @param :null
    * @return : List<Schema.SObjectField>
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
        Prospect_Scoring_Metadata__mdt.Id,
        Prospect_Scoring_Metadata__mdt.DeveloperName,
        Prospect_Scoring_Metadata__mdt.Campaign_Type__c,
        Prospect_Scoring_Metadata__mdt.Campaign_Channel__c,
        Prospect_Scoring_Metadata__mdt.Member_Status__c,
        Prospect_Scoring_Metadata__mdt.AMR__c,
        Prospect_Scoring_Metadata__mdt.China__c,
        Prospect_Scoring_Metadata__mdt.Corporate__c,
        Prospect_Scoring_Metadata__mdt.EUR__c,
        Prospect_Scoring_Metadata__mdt.AMEA__c,
        Prospect_Scoring_Metadata__mdt.EMEA__c,
        Prospect_Scoring_Metadata__mdt.Japan__c,
        Prospect_Scoring_Metadata__mdt.SAPAC__c,
        Prospect_Scoring_Metadata__mdt.IsActive__c,
        Prospect_Scoring_Metadata__mdt.Primary_Key_Value__c
           
       };
    }
	/**
     *  @author Pankaj Singla
     *  @description Select Active records of metadata
     *  @return List of Prospect_Scoring_Metadata__mdt
     **/
    public List<Prospect_Scoring_Metadata__mdt> selectActiveRecords(){
       
        ilib_LogQuery logger = null;

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectActiveRecords','All active records');
        }
       
        List<Prospect_Scoring_Metadata__mdt> res = (List<Prospect_Scoring_Metadata__mdt>) Database.query(newQueryFactory().setCondition('IsActive__c =true').toSOQL());

        if(Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger.stop(res.size());
        }
        return res;
    }
}
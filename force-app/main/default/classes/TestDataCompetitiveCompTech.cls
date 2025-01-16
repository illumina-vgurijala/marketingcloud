/**
*    @author: Kushagra Desai
*    @date:   03-Sept-2019
*    @description:  Data creation class for Competitive_Complementary_Technology__c
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Vivek R                       06-Oct-22           Codescan fixes: added comments
*             Gerardo Garcia                30-Jan-24           Add initForOpportunity method CMCM-4485
*             Gerardo Garcia                28-Feb-24           Replace fields to new fields CompetitorName__c and ProductName__c due CCT phase 1
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
 public with sharing class TestDataCompetitiveCompTech {

    /**
     *  @author      : Kushagra Desai
     *  @description : Method to create Data Order through the Id of the account record
     *  @param       : Account
     *  @return      : Competitive_Complementary_Technology__c
    */
    public static Competitive_Complementary_Technology__c getNewCompetitiveCompTech(Account a) {
        Competitive_Complementary_Technology__c cct  = initCompetitiveCompTech(a.Id);
        insert cct;
        return cct;
    }
    /**
     *  @author      : Kushagra Desai
     *  @description : Method to create Data Order through the Id of the account record
     *  @param       : Id
     *  @return      : Competitive_Complementary_Technology__c
    */
	 public static Competitive_Complementary_Technology__c initCompetitiveCompTech(String accId){
        Competitive_Complementary_Technology__c cct =  new Competitive_Complementary_Technology__c();
        cct.Account__c = accId;
        cct.CompetitorName__c = 'GenapSys';
        cct.Product_Category__c = 'Instrument';
        cct.ProductName__c = 'Genius (Benchtop Sequencer)';
        cct.Number_Of_Units__c = 1;
        cct.Is_In_Use__c = 'Unknown';
        cct.RecordTypeId = CompetitiveTechnologySelector.getAccountTypeId();
        return cct;
    }

    /**
     *  @author      : Gerardo Garcia
     *  @description : Creates CCT for opportunity
     *  @param       : opportunityId id for Opportunity_Name__c
     *  @param       : isPrimary Is_Primary_Competitor__c
     *  @return      : Competitive_Complementary_Technology__c
    */
	 public static Competitive_Complementary_Technology__c initForOpportunity(Id opportunityId, Boolean isPrimary){
        Competitive_Complementary_Technology__c cct =  new Competitive_Complementary_Technology__c();
        cct.Opportunity_Name__c = opportunityId;
        cct.CompetitorName__c = 'GenapSys';
        cct.Product_Category__c = 'Instrument';
        cct.ProductName__c = 'Genius (Benchtop Sequencer)';
        cct.Competitive_Positioning__c = 'Competitor Slightly Favored';
        cct.Primary_Competitor__c = isPrimary;
        cct.Dollar_Per_Gb__c = 10;
        cct.RecordTypeId = CompetitiveTechnologySelector.getOpportunityTypeId();
        return cct;
    }
}
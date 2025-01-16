/**
*    @date          18 Sep 2020
*    @description   StandingQuoteOpportunityProduct domain class
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Tapas Chakraborty             18 Sep 2020          Initial Version
*             Aman Tyagi                    31 Mar 2022          CodeScan Fixes
*    ------------------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class StandingQuoteOpportunityProducts extends ilib_SObjectDomain{
    public final static String LOG_TITLE = 'Standing Quote Opportunity Products';
    /**
     * Boilerplate which is required for base class instantiation logic 
     **/
    public StandingQuoteOpportunityProducts(List<Standing_Quote_Opportunity_Product__c> sObjectList)
    {
        super(sObjectList);
    }
    /**
     * Boilerplate which is required for base class instantiation logic 
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
		/**
		 * Boilerplate which is required for base class instantiation logic 
		 **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new StandingQuoteOpportunityProducts(sObjectList);
        }
    }

    /*
    * @Author:  Tapas Chakraborty
    * @Description : this method has logic for before insert
    * @param : null
    * @return :void
    */
    public override void onBeforeInsert(){
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE);
        try{
        populateCurrencyFromOpp((List<Standing_Quote_Opportunity_Product__c>)records);
        ilib_LogEvent.pop();
        }catch(Exception e){
        System.debug('Error Message is  '+e.getMessage());
        ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SALES );
    }
    }
    
    /**
     * @author Tapas
     * @date   18 Sep 2020
     * @description    DCP-40569 update currency on SQ opp products from opp
     * after update trigger method
    **/ 
	private void populateCurrencyFromOpp(List<Standing_Quote_Opportunity_Product__c> lstSQOP){
        Set<Id> setOppIds = new Set<Id>();
        
        for(Standing_Quote_Opportunity_Product__c objSQOP : lstSQOP){
            setOppIds.add(objSQOP.Opportunity__c);
        }
        
        Map<Id,Opportunity> idToOpp = new Map<Id, Opportunity>(new OpportunitySelector().selectOpportunities(setOppIds));
        
        for(Standing_Quote_Opportunity_Product__c objSQOP : lstSQOP){
            objSQOP.CurrencyIsoCode = idToOpp.get(objSQOP.Opportunity__c).CurrencyIsoCode;
        }
    }
    
    
        
}
/**
*    @author  Vishnu Priya Duggineni
*    @date   2018-10-29
*    @description    US-10492: Promotions for Channel Partners Incentive object selector
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------
*    Developer                       Date                  Description
*    ----------------------------------------------------------------------------------------------------------------------
*    Vishnu Priya Duggineni          2018-10-29            Original  Version
*    Kushagra Desai                  2018-12-06            Added new funtion
*    Roopal Verma                    2019-07-05            DCP-25340, Added method getPromotionsById for promotion approval
*    Satya Swain                     2019-08-01            INC0216277 change Promo Filter to hide expired promos
*    Raja Siva Krishna               2020-09-09            DCP-40230   Added method getPromotionsByUserAndRegion for promotion filter
*    Jitesh Lakhwani                 2022-07-20            DCP-54361   Added new field 'Master_Promotions__c'
*    Adithi Acharya                  2023-01-10            Codescan fix (Avoid duplicate literals)
*    Vinay S Reddy                   2023-10-27            CMCM1482 updates
*/

public with sharing class ApttusIncentivesPromotionsSelector extends ilib_SObjectSelector{

    private static final String STRING_NAME = 'Name'; //codescanfix
   
   /**
    *  @author Vishnu Priya Duggineni 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Incentives
    **/
   public Schema.SObjectType getSObjectType(){
        return Apttus_Config2__Incentive__c.sObjectType;
   }
    
   /**
    *  @author  Vishnu Priya Duggineni 
    *  @description Retrieve list of fields for Apttus Incentives sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
   public List<Schema.SObjectField> getSObjectFieldList()
   {
        return new List<Schema.SObjectField> {
            Apttus_Config2__Incentive__c.Id,
            Apttus_Config2__Incentive__c.Name,
            Apttus_Config2__Incentive__c.Apttus_Config2__IncentiveCode__c ,
            Apttus_Config2__Incentive__c.Apttus_Config2__ExpirationDate__c ,
            Apttus_Config2__Incentive__c.Promotion_Redemption_Method__c ,
            Apttus_Config2__Incentive__c.Apttus_Config2__Description__c ,
            Apttus_Config2__Incentive__c.Promotion_Terms_and_Conditions__c,
            Apttus_Config2__Incentive__c.Promo_Channel__c,
            Apttus_Config2__Incentive__c.External_Id__c,
            Apttus_Config2__Incentive__c.Apttus_Config2__EffectiveDate__c,
            Apttus_Config2__Incentive__c.Apttus_Config2__ExpirationDate__c,//DCP-40230
            Apttus_Config2__Incentive__c.Regions__c,//DCP-40230
            Apttus_Config2__Incentive__c.Distribution_Channel__c,//DCP-40230
            Apttus_Config2__Incentive__c.Approval_Required__c,//DCP-40230
            Apttus_Config2__Incentive__c.Promotion_Channel_Description__c,//DCP-40230
            Apttus_Config2__Incentive__c.Promotion_Details__c,//DCP-40230
            Apttus_Config2__Incentive__c.Sales_Description__c,//DCP-40230
            Apttus_Config2__Incentive__c.Limit_View__c,//DCP-40230
            Apttus_Config2__Incentive__c.Master_Promotions__c, // DCP-54361
            Apttus_Config2__Incentive__c.Marketing_Trade_In__c //CMCM 1482
        };
    }
    /*
    * @author Vishnu Priya Duggineni
    * @date   10-29-2018
    * @description  get records by all promotions from apttus incentives.
    * @param none
    * @return List of Incentive promotions
    */
   public List<Apttus_Config2__Incentive__c> getIncentivePromotions()
   {
         return (List<Apttus_Config2__Incentive__c>) Database.query(
            newQueryFactory().
            selectField(STRING_NAME).
            selectField('Apttus_Config2__IncentiveCode__c').
            selectField('Apttus_Config2__ExpirationDate__c').
            selectField('Promotion_Redemption_Method__c').
            selectField('Apttus_Config2__Description__c').
            selectField('Promo_Channel__c').
            selectField('Marketing_Trade_In__c').
            setcondition('Apttus_Config2__Active__c = true').toSOQL()
        );
    }

    /*
    * @author Kristiyan Petkov
    * @date   11-13-2018
    * @description  get records by all active promotions from apttus incentives with expiration date greater than today.
    * @param none
    * @return List of Incentive promotions
    */
    public List<Apttus_Config2__Incentive__c> getActivePromotions()
    {
         System.debug('@@@ Inside getActivePromotions method');
         String strTodaysDate = String.ValueOf(Date.today());
         String strCondition = 'Apttus_Config2__Active__c = true and Promotion_Redemption_Method__c = \'E\' AND Apttus_Config2__EffectiveDate__c <= '+strTodaysDate+' AND Apttus_Config2__ExpirationDate__c >= '+strTodaysDate;
         String strQuery =  newQueryFactory().
                            selectField(STRING_NAME).
                            selectField('Promo_Channel__c').                  
                            setcondition(strCondition).toSOQL();
         System.debug('@@@ Query : '+strQuery);
         return (List<Apttus_Config2__Incentive__c>) Database.query(strQuery);               
    }
    /*
    * @author Kushagra Desai
    * @date   29-11-2018
    * @description  get records by Apttus_Config2__IncentiveCode__c
    * @param PromoCode`
    * @return List of Incentive promotions
    */
    public List<Apttus_Config2__Incentive__c> getPromotions(Set<String> promoCode)
    {
         return (List<Apttus_Config2__Incentive__c>) Database.query(
            newQueryFactory().
            setcondition('Apttus_Config2__IncentiveCode__c IN: promoCode').toSOQL()
        );   
    }
	
	/*
    * @author Roopal Verma
    * @date   03-07-2019
    * @description  get records by Apttus_Config2__Incentive__c.Id
    * @param IncentiveId
    * @return List of Incentive promotions
    */
    public List<Apttus_Config2__Incentive__c> getPromotionsById(Set<Id> incentiveId)
    {
         return (List<Apttus_Config2__Incentive__c>) Database.query(
            newQueryFactory().
            selectField(STRING_NAME).
            selectField('Apttus_Config2__IncentiveCode__c').
            setcondition('Apttus_Config2__Incentive__c.Id IN: incentiveId').toSOQL()
        );   
    }

    /*
    * @author Raja Siva Krishna
    * @date   09-09-2020
    * @description  get records by salesOps, Regions__c
    * @params isSalesOps; selectedRegion, allRegions, promoChannelDesc 
    * @return List of Incentive promotions
    */
    public List<Apttus_Config2__Incentive__c> getPromotionsByUserAndRegion(Boolean isSalesOps, String selectedRegion,String allRegions,String promoChannelDesc)
    {
        String strTodaysDate = String.ValueOf(Date.today());
        String strCondition = 'Apttus_Config2__Active__c = true AND Apttus_Config2__EffectiveDate__c <= '+strTodaysDate+' AND Apttus_Config2__ExpirationDate__c >= '+strTodaysDate;

        if(String.isNotBlank(selectedRegion) && selectedRegion != 'All Regions'){
            strCondition = strCondition + ' AND Regions__c includes (\'' + selectedRegion + '\')';
        }
        else if(String.isNotBlank(selectedRegion) && selectedRegion == 'All Regions'){
            strCondition = strCondition + ' AND Regions__c includes (' + allRegions + ')';
        }
        if(isSalesOps){
            strCondition = strCondition + ' AND Promotion_Channel_Description__c includes (' + promoChannelDesc + ') ';
        }
        else{
            strCondition = strCondition + ' AND Promotion_Channel_Description__c includes (' + promoChannelDesc + ') AND Limit_View__C = False';
        }

        String strQuery =  newQueryFactory().
                           selectField(STRING_NAME).
                           selectField('Promo_Channel__c').                  
                           setcondition(strCondition).toSOQL();
        System.debug('@@@ Query : '+strQuery);
        return (List<Apttus_Config2__Incentive__c>) Database.query(strQuery);   
    }
}
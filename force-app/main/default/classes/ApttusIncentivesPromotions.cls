/**
*    @author  Vishnu Priya Duggineni
*    @date   2018-10-24
*    @description    US-10492: Promotions for Channel Partners
*    Modification Log:
*    ------------------------------------------------------------------------------------
*    Developer                       Date                  Description
*    ------------------------------------------------------------------------------------
*    Vishnu Priya Duggineni          2018-10-24            Original  Version
*    Jitesh Lakhwani                 6-July-2022           Code Scan fixes of Comments
*/

public without sharing class ApttusIncentivesPromotions{       
    /*
    *  @author: Vishnu Priya Duggineni
    *  @description: get promotions for Apttus Incentives
    *  @Return: List of promotions
    */
    @AuraEnabled
    public static List<PromotionsResult> getPromotions() {
        List<Apttus_Config2__Incentive__c> lstIncentivePromotions = new ApttusIncentivesPromotionsSelector().getIncentivePromotions();
        
        List<PromotionsResult> lstPromotions = new List<PromotionsResult>();
            if (lstIncentivePromotions.size() > 0){
                for(Apttus_Config2__Incentive__c ap: lstIncentivePromotions){
                    lstPromotions.add(new PromotionsResult(ap.Name, ap.Apttus_Config2__IncentiveCode__c, ap.Apttus_Config2__ExpirationDate__c, ap.Promotion_Redemption_Method__c, ap.Apttus_Config2__Description__c, ap.Promo_Channel__c));
                }
            }
        return lstPromotions;
    }
    
    /*
    *  @author: Vishnu Priya Duggineni
    *  @description: Wrapper class to return promotion fields 
    */
    public class PromotionsResult
    {
    
        /**
        *  @author: Vishnu Priya Duggineni
        *  @description: Wrapper class Constructor 
        *  @param : String strPromoName, String strPromoCode, Date strPromoDate, String strPromomethod, String strPromoDescription, String strPromoChannel
        * @return : None
        */
        public PromotionsResult(String strPromoName, String strPromoCode, Date strPromoDate, String strPromomethod, String strPromoDescription, String strPromoChannel){
            this.strPromoName = strPromoName;
            this.strPromoCode = strPromoCode;
            this.strPromoDate = strPromoDate;
            this.strPromomethod = strPromomethod;
            this.strPromoDescription = strPromoDescription;
            this.strPromoChannel = strPromoChannel;
        }
    
        @AuraEnabled
        public String strPromoName;
        @AuraEnabled
        public String strPromoCode;
        @AuraEnabled
        public Date strPromoDate;
        @AuraEnabled
        public String strPromomethod;
        @AuraEnabled
        public String strPromoDescription;
        @AuraEnabled
        public String strPromoChannel;
   
     }
}
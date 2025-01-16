/**
*    @author: Todd Newman
*    @date:  
*    @description: Wrapper Class to store pricing related details
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description  
*          Todd Newman                                      
*          Aman Tyagi                    30th March 2022      CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class PricingWrapper {

    public List<PriceList> priceList;

    /*
    * @Description : Wrapper class to store the price list items from SAP
    * @param: NA
    * @return: NA
    */
    public class PriceListItems {
        public String ProductId;
        public String EffectiveDate;
        public String ExpirationDate;
        public String IsActive;
        public String PriceUom;
        public String ListPrice;
        public String PriceType;
        public String PriceListItemExternalId;
		public String CurrencyIsoCode;
        public String Frequency;
        public String IsQuantityReadOnly;
        public String PriceMethod;
        //public String ConditionType; 

        /*
        * @Description : method for getting sObject
        * @param: NA
        * @return: Apttus_Config2__PriceListItem__c
        */
        public Apttus_Config2__PriceListItem__c getSObject()
        {
            UtilsRest utilRest = new UtilsRest();

            return new Apttus_Config2__PriceListItem__c(
                Apttus_Config2__EffectiveDate__c = utilRest.stringToDateTimeConversion(this.EffectiveDate),
                Apttus_Config2__ExpirationDate__c = utilRest.stringToDateTimeConversion(this.ExpirationDate),
                Apttus_Config2__Active__c = utilRest.stringToBooleanConversion(this.IsActive),
                Apttus_Config2__ListPrice__c = utilRest.stringToDecimalConversion(this.ListPrice),
                Apttus_Config2__PriceType__c = this.PriceType,
                Apttus_Config2__PriceUom__c = this.PriceUom,
                CurrencyIsoCode = this.CurrencyIsoCode,
                External_Id__c = this.PriceListItemExternalId,
                Apttus_Config2__Frequency__c = this.Frequency,
                Apttus_Config2__IsQuantityReadOnly__c = utilRest.stringToBooleanConversion(this.IsQuantityReadOnly),
                Apttus_Config2__PriceMethod__c = this.PriceMethod
            );
        }
    }
    /*
    * @Description : Wrapper class to store the price list items
    * @param: NA
    * @return: NA
    */  
    public class PriceList {
        public String Name;
        public String PriceListExternalId;
		//public String PriceType;
		public String CurrencyIsoCode;
        
        public List<PriceListItems> priceListItems;

        /*
        * @Description : method for getting sObject
        * @param: NA
        * @return: Apttus_Config2__PriceList__c
        */
        public Apttus_Config2__PriceList__c getSObject()
        {
            return new Apttus_Config2__PriceList__c(Name = this.Name,
                CurrencyIsoCode = this.CurrencyIsoCode,
                External_Id__c = this.PriceListExternalId
            );
        }
    }

}
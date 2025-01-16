/**
 * Author: Lovel Panchal
 * Date: 07-May-2024
 * Description: Controller class for Discount Grid LWC component.
 * 
 * Modification Log:
 * ------------------------------------------------------------------------------------ 
 * Developer        Date            Description
 * Lovel Panchal    07-May-2024     Created DiscountGuidanceTriggerHandler class.
 * Vandana Kuncham  28-May-2024     Added checkOverlappingPeriod method.
 * Vandana Kuncham  28-May-2024     Updated handle method.
 * Enrique Reyes    02-Dec-2024     Fixed checkOverlappingPeriod method.
 * ------------------------------------------------------------------------------------ 
 */

 public class DiscountGuidanceTriggerHandler extends ilib_SObjectDomain {

    /**
     * Handles the processing of Discount Guidance records.
     * 
     * @param newDiscounts    List of new Discount Guidance records.
     * @param oldDiscountsMap Map of old Discount Guidance records.
     */
    
    public static Set<String> channelSet = new Set<String>();
    public static Set<String> currencyCodeSet = new Set<String>();
    public static Set<String> discountTierSet = new Set<String>();
    public static Set<String> customerTypeSet = new Set<String>();
    public static Set<String> discountGridGroupSet = new Set<String>();
    public static Set<String> countrySet = new Set<String>();
    public static Set<String> pltSet = new Set<String>();
    public static String countryString;
    
    public static final String COUNTRY_STRING = 'Country';
    public static final String PLTYPE_STRING = 'Price List Type';


    /*
    Super method for class
    */
    public DiscountGuidanceTriggerHandler(List<Discount_Guidance__c> sObjectList) {
        super(sObjectList);
    }

    /**
     * Boilerplate which is required for base class instantiation logic
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*
        Constructor class
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new DiscountGuidanceTriggerHandler(sObjectList);
        }
    }

    /* Called by the trigger before record is saved in database */    
     public override void onBeforeInsert()
     { 
         List<Discount_Guidance__c> lstDiscount = (List<Discount_Guidance__c>)records;
         handle(lstDiscount, new Set<Id>());
     }

    /* Called by the trigger when a record is updated and record is saved in database */       
    public override void onBeforeUpdate(Map<Id, sObject> existingRecords)
    { 
        List<Discount_Guidance__c> lstDiscount = (List<Discount_Guidance__c>) records;
        handle(lstDiscount, existingRecords.keySet());
    }
    
     /**
     * Handles the processing of Discount Guidance records.
     * 
     * @param newDiscounts    List of new Discount Guidance records.
     * @param oldDiscountsMap Map of old Discount Guidance records.
     */
    
    public static void handle(List<Discount_Guidance__c> newDiscounts, Set<Id> discountRecordIds) {
        if (newDiscounts == null || newDiscounts.isEmpty()) {
            return;
        }

        for (Discount_Guidance__c discount : newDiscounts) {
            if (discount.Discount_Guidance_Level__c == null) {
                continue;
            }            
            if (discount.Discount_Guidance_Level__c == COUNTRY_STRING) {
                populateCountryCurrencyDate(discount);
                countrySet.addAll(discount.Country__c.split(';'));
            } else if (discount.Discount_Guidance_Level__c == PLTYPE_STRING) {
                populatePriceListTypeCurrencyDate(discount);
                pltSet.add(discount.Price_List_Type__c);
            }
        }
        
        countryString = '(\'' + String.join(countrySet, '\', \'') + '\')';
        channelSet = UtilsCollection.getSetOfStrings(newDiscounts, 'Channel__c');
        currencyCodeSet = UtilsCollection.getSetOfStrings(newDiscounts, 'CurrencyIsoCode');
        discountTierSet = UtilsCollection.getSetOfStrings(newDiscounts, 'Customer_Discount_Tier__c');
        customerTypeSet = UtilsCollection.getSetOfStrings(newDiscounts, 'Primary_Customer_Type__c');
        discountGridGroupSet = UtilsCollection.getSetOfStrings(newDiscounts, 'Discount_Grid_Group__c');
        
        countrySet.remove(null);
        pltSet.remove(null);
        channelSet.remove(null);
        currencyCodeSet.remove(null);
        discountTierSet.remove(null);
        customerTypeSet.remove(null);
        discountGridGroupSet.remove(null);

        checkOverlappingPeriod(newDiscounts, discountRecordIds);
    }

    /**
     * Populates Text_CountryCurrencyDate__c field for Country Discount Guidance.
     * 
     * @param discount The Discount_Guidance__c record.
     */
    private static void populateCountryCurrencyDate(Discount_Guidance__c discount) {
        if (String.isBlank(discount.Country__c)) {
            return;
        }
        discount.Text_CountryCurrencyDate__c = constructConcatenatedString(discount.Country__c, discount.CurrencyIsoCode, discount.Start_Date__c, discount.End_Date__c);
    }

    /**
     * Populates Text_PriceListTypeCurrencyDate__c field for Price List Type Discount Guidance.
     * 
     * @param discount The Discount_Guidance__c record.
     */
    private static void populatePriceListTypeCurrencyDate(Discount_Guidance__c discount) {
        if (String.isBlank(discount.Price_List_Type__c)) {
            return;
        }
        discount.Text_PriceListTypeCurrencyDate__c = constructConcatenatedString(discount.Price_List_Type__c, discount.CurrencyIsoCode, discount.Start_Date__c, discount.End_Date__c);
    }

    /**
     * Constructs a concatenated string using the provided fields.
     * 
     * @param field1    Field 1.
     * @param field2    Field 2.
     * @param startDate Start Date.
     * @param endDate   End Date.
     * @return Concatenated string.
     */
    private static String constructConcatenatedString(String field1, String field2, Date startDate, Date endDate) {
        return field1 + ' ' + field2 + ' ' + startDate.format() + ' ' + endDate.format();
    }

    /**
     * Checks for overlapping periods.
     * 
     * @param newDiscounts    List of new Discount Guidance records being inserted.
     * @return None.
     */
    private static void checkOverlappingPeriod(List<Discount_Guidance__c> newDiscounts, Set<Id> discountRecordIds) {
        Map<String, List<Discount_Guidance__c>> existingDGMap = new Map<String, List<Discount_Guidance__c>>();
        List<Discount_Guidance__c> existingDGRecords = new DiscountGuidanceSelector().selectDiscountGuidanceRecords(countryString, pltSet, channelSet, currencyCodeSet, discountTierSet, customerTypeSet, discountGridGroupSet, discountRecordIds);
        for (Discount_Guidance__c eachDG : existingDGRecords) {   
            String existingKey = eachDG.Discount_Guidance_Level__c + eachDG.Channel__c + eachDG.CurrencyISOCode + eachDG.Customer_Discount_Tier__c + eachDG.Primary_Customer_Type__c + eachDG.Discount_Grid_Group__c;          
            List<Discount_Guidance__c> existingDGList = new List<Discount_Guidance__c>();
            if (existingDGMap.containsKey(existingKey)) {
                existingDGList = existingDGMap.get(existingKey);  
            }
            existingDGList.add(eachDG);
            existingDGMap.put(existingKey, existingDGList);  
        }

        for (Discount_Guidance__c newDG : newDiscounts) {
            Boolean overlapCheck = false; 
            String newKey = newDG.Discount_Guidance_Level__c + newDG.Channel__c + newDG.CurrencyISOCode + newDG.Customer_Discount_Tier__c + newDG.Primary_Customer_Type__c + newDG.Discount_Grid_Group__c;
            if (existingDGMap.containsKey(newKey)) {
                List<Discount_Guidance__c> existingDGList = existingDGMap.get(newKey);
                for (Discount_Guidance__c existingDG : existingDGList) {
                    overlapCheck = setOverlapCheck(newDG, existingDG);
                    if (overlapCheck && ((newDG.Start_Date__c >= existingDG.Start_Date__c && newDG.Start_Date__c <= existingDG.End_Date__c) ||
                       (newDG.End_Date__c >= existingDG.Start_Date__c && newDG.End_Date__c <= existingDG.End_Date__c) ||
                       (newDG.Start_Date__c <= existingDG.Start_Date__c && newDG.End_Date__c >= existingDG.End_Date__c) ||
                       (newDG.Start_Date__c >= existingDG.Start_Date__c && newDG.End_Date__c <= existingDG.End_Date__c))){
                        newDG.addError(String.format(System.Label.DGOverlapError, new List<Object>{existingDG.Start_Date__c, existingDG.End_Date__c , existingDG.Name, existingDG.Id}));
                        break;
                    }
                }
                existingDGList.add(newDG);
                existingDGMap.put(newKey, existingDGList);
            } else {
                existingDGMap.put(newKey, new List<Discount_Guidance__c>{newDG});
            }
        }
    }

    private static Boolean setOverlapCheck(Discount_Guidance__c newDG, Discount_Guidance__c existingDG) {
        Boolean overlapCheck = false;
        if (newDG.Discount_Guidance_Level__c == COUNTRY_STRING) {
            List<String> existingCountriesList = new List<String>();
            List<String> newCountriesList = new List<String>();
            if (!String.isBlank(existingDG.Country__c)) {
                existingCountriesList = existingDG.Country__c.split(';');
            }
            if (!String.isBlank(newDG.Country__c)) {
                newCountriesList = newDG.Country__c.split(';');
            }    
            for (String eachCountry : newCountriesList) {
                if (existingCountriesList.Contains(eachCountry)) {
                    overlapCheck = true;
                    break;
                }
            }
        } else if (newDG.Discount_Guidance_Level__c == PLTYPE_STRING) {     
            if(newDG.Price_List_Type__c == existingDG.Price_List_Type__c) {
                overlapCheck = true;
            }
        }
        return overlapCheck;
    }    
}
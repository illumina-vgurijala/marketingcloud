/* @ author      :  Akash Kumar
* @ date         :  26-SEP-2024
* @ Description  :  SalesMarginDataCalculationService is the class for calculating various metrices pertaining to Sales Margin Data
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                 Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akash Kumar         26-SEP-2024             Initial version
*/

public with sharing class SalesMarginDataCalculationService {
    /**
     * Method to get Standard Margin At List PricePercentage based on Subsription, Non - Subscription and QuoteType
     **/
    public static Double calculateStandardMarginAtListPricePercentage(Apttus_Proposal__Proposal_Line_Item__c objQli,
                                                                        Double listPrice,
                                                                        Boolean isSubsriptionLineItem,
                                                                        Boolean isNonSubscriptionLineItem,
                                                                        String quoteType,
                                                                        Double standardCogs){

        Double standardMarginAtListPricePercent = 0;
        Double standardMarginAtListPrice = 0;    
        Double extendedListPrice = 0;                                                                  
        standardMarginAtListPrice = new SalesMarginDataCalculationService().calculateStandardMarginAtListPrice(objQli,
                                                                                                                listPrice,
                                                                                                                isSubsriptionLineItem,
                                                                                                                isNonSubscriptionLineItem,
                                                                                                                quoteType,
                                                                                                                standardCogs);

        extendedListPrice = new SalesMarginDataCalculationService().calculateExtendedListPrice(objQli,
                                                                                                listPrice,
                                                                                                isSubsriptionLineItem,
                                                                                                isNonSubscriptionLineItem,
                                                                                                quoteType);
        
                                                                            
        if(standardMarginAtListPrice != null && extendedListPrice !=null &&
            	standardMarginAtListPrice != 0 && extendedListPrice !=0){
            standardMarginAtListPricePercent = (standardMarginAtListPrice/extendedListPrice);
        }
        return standardMarginAtListPricePercent;
                                                                       
    }
	/**
     * Method to get Standard Margin At Historic Discount Percentage based on Subsription, Non - Subscription and QuoteType
     **/
    public static Double calculateStandardMarginAtHistoricDiscountPercent(Apttus_Proposal__Proposal_Line_Item__c objQli,
                                                                            Double listPrice,
                                                                            Boolean isSubsriptionLineItem,
                                                                            Boolean isNonSubscriptionLineItem,
                                                                            String quoteType,
                                                                            Double standardCogs){

        Double extendedListPrice = 0;
        Double historicDiscountExtendedListPrice = 0;
        Double standardMarginAtHistoricDiscount = 0;
        Double customerHistoricDiscount = 0;
        Double standardMarginAtHistoricDiscountPercent = 0;
    
            standardMarginAtHistoricDiscount = new SalesMarginDataCalculationService().calculateStandardMarginAtHistoricDiscount(objQli,
                                                                                                                                listPrice,
                                                                                                                                isSubsriptionLineItem,
                                                                                                                                isNonSubscriptionLineItem,
                                                                                                                                quoteType, 
                                                                                                                                standardCogs);

            extendedListPrice = new SalesMarginDataCalculationService().calculateExtendedListPrice(objQli,
                                                                                                    listPrice,
                                                                                                    isSubsriptionLineItem,
                                                                                                    isNonSubscriptionLineItem,
                                                                                                    quoteType);
                                                      
            customerHistoricDiscount = objQli.Customer_Historical_Discount__c != null ? objQli.Customer_Historical_Discount__c : 0;
            historicDiscountExtendedListPrice = (1-customerHistoricDiscount/100) * extendedListPrice;
           	
            if(historicDiscountExtendedListPrice!= null && standardMarginAtHistoricDiscount != null
                && historicDiscountExtendedListPrice!=0 && standardMarginAtHistoricDiscount !=0){
                    standardMarginAtHistoricDiscountPercent = (standardMarginAtHistoricDiscount/historicDiscountExtendedListPrice);
            }

        return standardMarginAtHistoricDiscountPercent;
    }
	/**
     * Method to get Standard Margin At Quote Proposed Price Percent based on Subsription, Non - Subscription and QuoteType
     **/
	public static Double calculateStandardMarginAtQuoteProposedPricePercent(Apttus_Proposal__Proposal_Line_Item__c objQli,
                                                                                Double listPrice,
                                                                                Boolean isSubsriptionLineItem,
                                                                                Boolean isNonSubscriptionLineItem,
                                                                                String quoteType,
                                                                                Double standardCogs){

        Double extendedListPrice = 0;
        Double proposedExtendedListPrice = 0;
        Double standardMarginAtQuoteProposedPrice = 0;
        Double standardMarginAtQuoteProposedPricePercent = 0;
        Double totalDiscountPercentage = 0;
    
            standardMarginAtQuoteProposedPrice = new SalesMarginDataCalculationService(). calculateStandardMarginAtQuoteProposedPrice(objQli,
                                                                                                                                        listPrice,
                                                                                                                                        isSubsriptionLineItem,
                                                                                                                                        isNonSubscriptionLineItem,
                                                                                                                                        quoteType, 
                                                                                                                                        standardCogs);

            extendedListPrice =  new SalesMarginDataCalculationService().calculateExtendedListPrice(objQli,
                                                                                                    listPrice,
                                                                                                    isSubsriptionLineItem,
                                                                                                    isNonSubscriptionLineItem);
            
            totalDiscountPercentage = objQli.Total_Discount_Percentage__c != null ? objQli.Total_Discount_Percentage__c : 0;                                                                          
            proposedExtendedListPrice = (1-totalDiscountPercentage/100) * extendedListPrice;
            
            if(proposedExtendedListPrice != null && standardMarginAtQuoteProposedPrice != null
                && proposedExtendedListPrice != 0 && standardMarginAtQuoteProposedPrice != 0){
                    standardMarginAtQuoteProposedPricePercent = (standardMarginAtQuoteProposedPrice/proposedExtendedListPrice);
            }
                                                                                  
        return standardMarginAtQuoteProposedPricePercent;
    }
	/**
     * Method to get Standard Margin At List Price based on Subsription, Non - Subscription and QuoteType
     **/
    public Double calculateStandardMarginAtListPrice(Apttus_Proposal__Proposal_Line_Item__c objQli, 
                                                                Double listPrice,
                                                                Boolean isSubsriptionLineItem,
                                                                Boolean isNonSubscriptionLineItem,
                                                                String quoteType,
                                                                Double standardCogs){
                                                                    
        ilib_LogEvent.push('calculateStandardMarginAtListPrice');
        
        Double standardMarginAtListPrice = 0;
        //Double standardCogs = 0;
        Double channelPartnerPrice = 0;
        Double distributorSpecificDiscount = 0;

        ilib_LogEvent.message('@@@ Parameterts for Calculation @@@');
        ilib_LogEvent.message('Line No' + objQli.Name);

        if(quoteType == Label.Direct_Quote || quoteType == Label.Indirect_Direct_UC_Quote){
            ilib_LogEvent.message('calculateStandardMarginAtListPrice direct Price for Calculation' + listPrice);
            ilib_LogEvent.message('calculateStandardMarginAtListPrice direct standardCogs' + standardCogs);
            ilib_LogEvent.message('calculateStandardMarginAtListPrice direct Quantity' + objQli.Apttus_QPConfig__Quantity2__c);
            ilib_LogEvent.message('calculateStandardMarginAtListPrice direct Term/Months' + objQli.Term_Months__c);
            ilib_LogEvent.message('calculateStandardMarginAtListPrice direct quoteType' + quoteType);

            ilib_LogEvent.message('@@@ Formula for Shippable => (((listPrice - standardCogs) * Quantity))');
            ilib_LogEvent.message('@@@ Formula for Non-Shippable => (((listPrice - standardCogs) * Quantity))*Term/Months/12');
            if(isNonSubscriptionLineItem){
                standardMarginAtListPrice = ((listPrice - standardCogs) * 
                                                objQli.Apttus_QPConfig__Quantity2__c);
            }
            else if(isSubsriptionLineItem){
                standardMarginAtListPrice = (((listPrice - standardCogs) * 
                                                objQli.Apttus_QPConfig__Quantity2__c) * 
                                                objQli.Term_Months__c/12);
            }
        }
                                                                   
        else if(quoteType == Label.Indirect_Quote){
            distributorSpecificDiscount = objQli.Distributor_Specific_Discount_Percentage__c != null ? 
                							objQli.Distributor_Specific_Discount_Percentage__c : 0;
            channelPartnerPrice = (1-distributorSpecificDiscount/100)*listPrice;
            
            ilib_LogEvent.message('distributorSpecificDiscount : ' + distributorSpecificDiscount);
            ilib_LogEvent.message('listPrice : ' + listPrice);
            ilib_LogEvent.message('channelPartnerPrice : (1-distributorSpecificDiscount/100)*listPrice : ' + channelPartnerPrice);

            ilib_LogEvent.message('calculateStandardMarginAtListPrice indirect Price for Calculation' + channelPartnerPrice);
            ilib_LogEvent.message('calculateStandardMarginAtListPrice indirect standardCogs' + standardCogs);
            ilib_LogEvent.message('calculateStandardMarginAtListPrice indirect Quantity' + objQli.Apttus_QPConfig__Quantity2__c);
            ilib_LogEvent.message('calculateStandardMarginAtListPrice indirect Term/Months' + objQli.Term_Months__c);
            ilib_LogEvent.message('calculateStandardMarginAtListPrice indirect quoteType' + quoteType);

            ilib_LogEvent.message('@@@ Formula for Shippable => (((channelPartnerPrice - standardCogs) * Quantity))');
            ilib_LogEvent.message('@@@ Formula for Non-Shippable => (((channelPartnerPrice - standardCogs) * Quantity))*Term/Months/12');
            if(isNonSubscriptionLineItem){
                standardMarginAtListPrice = (channelPartnerPrice - standardCogs) * 
                                                objQli.Apttus_QPConfig__Quantity2__c;
            }
            else if(isSubsriptionLineItem){
                standardMarginAtListPrice = (((channelPartnerPrice - standardCogs) * 
                                                objQli.Apttus_QPConfig__Quantity2__c) * 
                                                objQli.Term_Months__c/12);
            }
        }
        ilib_LogEvent.message('standardMarginAtListPrice' + standardMarginAtListPrice);
        ilib_LogEvent.pop();
  		return standardMarginAtListPrice;
    }
	/**
     * Method to get Extended ListPrice based on Subsription, Non - Subscription and QuoteType
     **/
    public Double calculateExtendedListPrice(Apttus_Proposal__Proposal_Line_Item__c objQli,
                                                Double listPrice,
                                                Boolean isSubsriptionLineItem,
                                                Boolean isNonSubscriptionLineItem,
                                                String quoteType){
                                                            
		Double extendedListPrice = 0;
        Double distributorSpecificDiscount = 0;

        ilib_LogEvent.push('calculateExtendedListPrice');
        ilib_LogEvent.message('@@@ Parameterts for Calculation @@@');
        ilib_LogEvent.message('Line No' + objQli.Name);

        if(quoteType == Label.Direct_Quote || quoteType == Label.Indirect_Direct_UC_Quote){

            ilib_LogEvent.message('calculateExtendedListPrice Direct Price for Calculation' + listPrice);
            ilib_LogEvent.message('calculateExtendedListPrice Direct Quantity' + objQli.Apttus_QPConfig__Quantity2__c);
            ilib_LogEvent.message('calculateExtendedListPrice Direct Term/Months' + objQli.Term_Months__c);

            ilib_LogEvent.message('quoteType' + quoteType);
            ilib_LogEvent.message('@@@ Formula for Shippable =>  listPrice * Quantity');
            ilib_LogEvent.message('@@@ Formula for Non-Shippable => listPrice * Quantity * Term/Months/12');
            if(isNonSubscriptionLineItem){
                extendedListPrice = listPrice * objQli.Apttus_QPConfig__Quantity2__c;
            }
            else if(isSubsriptionLineItem){
                extendedListPrice = listPrice * objQli.Apttus_QPConfig__Quantity2__c * objQli.Term_Months__c/12;
            }
        }
        else if(quoteType == Label.Indirect_Quote){
            distributorSpecificDiscount = objQli.Distributor_Specific_Discount_Percentage__c != null ? 
                							objQli.Distributor_Specific_Discount_Percentage__c : 0;
            Double channelPartnerPrice = (1-distributorSpecificDiscount/100)*listPrice;

            ilib_LogEvent.message('distributorSpecificDiscount : ' + distributorSpecificDiscount);
            ilib_LogEvent.message('listPrice : ' + listPrice);
            ilib_LogEvent.message('channelPartnerPrice : (1-distributorSpecificDiscount/100)*listPrice : ' + channelPartnerPrice);


            ilib_LogEvent.message('calculateExtendedListPrice Indirect Price for Calculation' + channelPartnerPrice);
            ilib_LogEvent.message('calculateExtendedListPrice Indirect Quantity' + objQli.Apttus_QPConfig__Quantity2__c);
            ilib_LogEvent.message('calculateExtendedListPrice Indirect Term/Months' + objQli.Term_Months__c);
            ilib_LogEvent.message('calculateExtendedListPrice Indirect quoteType' + quoteType);

            ilib_LogEvent.message('@@@ Formula for Shippable =>  channelPartnerPrice * Quantity');
            ilib_LogEvent.message('@@@ Formula for Non-Shippable => channelPartnerPrice * Quantity * Term/Months/12');
            if(isNonSubscriptionLineItem){
                extendedListPrice = channelPartnerPrice * objQli.Apttus_QPConfig__Quantity2__c;
            }
            else if(isSubsriptionLineItem){
                extendedListPrice = channelPartnerPrice * objQli.Apttus_QPConfig__Quantity2__c * objQli.Term_Months__c/12;
            }
        }
        ilib_LogEvent.message('extendedListPrice' + extendedListPrice);
        ilib_LogEvent.pop();
        return extendedListPrice;
    }
    /**
     * Method to get Extended ListPrice for Specific Use Cases
     **/
    public Double calculateExtendedListPrice(Apttus_Proposal__Proposal_Line_Item__c objQli, 
                                                Double listPrice, 
                                                Boolean isSubsriptionLineItem, 
                                                Boolean isNonSubscriptionLineItem){

        Double extendedListPrice = 0;                                           
        if(isNonSubscriptionLineItem){
            extendedListPrice = listPrice * objQli.Apttus_QPConfig__Quantity2__c;
        }
        else if(isSubsriptionLineItem){
            extendedListPrice = listPrice * objQli.Apttus_QPConfig__Quantity2__c * objQli.Term_Months__c/12;
        }
        return extendedListPrice;
    }
	/**
     * Method to get Standard Margin At Historic Discount based on Subsription, Non - Subscription and QuoteType
     **/
    private Double calculateStandardMarginAtHistoricDiscount(Apttus_Proposal__Proposal_Line_Item__c objQli,
                                                                        Double listPrice,
                                                                        Boolean isSubsriptionLineItem,
                                                                        Boolean isNonSubscriptionLineItem,
                                                                        String quoteType,
                                                                        Double standardCogs){

        Double standardMarginAtHistoricDiscount = 0;
        Double customerHistoricDiscount = 0;
        Double distributorSpecificDiscount = 0;
        Double channelPartnerPrice= 0;

		customerHistoricDiscount = objQli.Customer_Historical_Discount__c != null  ? objQli.Customer_Historical_Discount__c : 0;                                                                    
        if(quoteType == Label.Direct_Quote || quoteType == Label.Indirect_Direct_UC_Quote){
            if(isNonSubscriptionLineItem){
                standardMarginAtHistoricDiscount = (((1-customerHistoricDiscount/100) * listPrice) 
                                                        - standardCogs) * 
                                                            objQli.Apttus_QPConfig__Quantity2__c;
                                                        
            }
            else if(isSubsriptionLineItem){
                standardMarginAtHistoricDiscount = (((1-customerHistoricDiscount/100) * listPrice) 
                                                        - standardCogs) * 
                                                            objQli.Apttus_QPConfig__Quantity2__c *
                                                            objQli.Term_Months__c/12;
            }
        }
            else if(quoteType == Label.Indirect_Quote){
                distributorSpecificDiscount = objQli.Distributor_Specific_Discount_Percentage__c != null ? 
                							objQli.Distributor_Specific_Discount_Percentage__c : 0;
                channelPartnerPrice = (1-distributorSpecificDiscount/100)*listPrice;
                if(isNonSubscriptionLineItem){
                    standardMarginAtHistoricDiscount = (((1-customerHistoricDiscount/100) * channelPartnerPrice) 
                                                            - standardCogs) * 
                                                            objQli.Apttus_QPConfig__Quantity2__c;
                }
                else if(isSubsriptionLineItem){
                    standardMarginAtHistoricDiscount = (((1-customerHistoricDiscount/100) * channelPartnerPrice) 
                                                        - standardCogs) * 
                                                        objQli.Apttus_QPConfig__Quantity2__c *
                                                        objQli.Term_Months__c/12;
                }
            }
            return standardMarginAtHistoricDiscount;                                                                
        }
    /**
     * Method to get Standard Margin At Quote Proposed Price based on Subsription, Non - Subscription and QuoteType
     **/
    public Double calculateStandardMarginAtQuoteProposedPrice(Apttus_Proposal__Proposal_Line_Item__c objQli,
                                                                        Double listPrice,
                                                                        Boolean isSubsriptionLineItem,
                                                                        Boolean isNonSubscriptionLineItem,
                                                                        String quoteType,
                                                                        Double standardCogs){

        Double standardMarginAtQuoteProposedPrice = 0; 
        Double totalDiscountPercentage = 0;
        Double distributorSpecificDiscount = 0;
        Double channelPartnerPrice = 0;

        ilib_LogEvent.push('calculateStandardMarginAtQuoteProposedPrice');
        ilib_LogEvent.message('@@@ Parameterts for Calculation @@@');
        ilib_LogEvent.message('Line No' + objQli.Name);
        

        totalDiscountPercentage = objQli.Total_Discount_Percentage__c != null ? objQli.Total_Discount_Percentage__c : 0;  
        
            ilib_LogEvent.message('totalDiscountPercentage' + totalDiscountPercentage);
            ilib_LogEvent.message('calculateStandardMarginAtHistoricDiscount  Price for Calculation' + listPrice);
            ilib_LogEvent.message('calculateStandardMarginAtListPrice  standardCogs' + standardCogs);
            ilib_LogEvent.message('calculateStandardMarginAtQuoteProposedPrice Quantity' + objQli.Apttus_QPConfig__Quantity2__c);
            ilib_LogEvent.message('calculateStandardMarginAtQuoteProposedPrice Term/Months' + objQli.Term_Months__c);
            ilib_LogEvent.message('calculateStandardMarginAtQuoteProposedPrice quoteType' + quoteType);

            ilib_LogEvent.message('@@@ Formula for Shippable =>  (((1-totalDiscountPercentage/100) * listPrice) - standardCogs) * Quantity');
            ilib_LogEvent.message('@@@ Formula for Non-Shippable => ((((1-totalDiscountPercentage/100) * listPrice) - standardCogs) * Quantity * Term/Months/12');
            if(isNonSubscriptionLineItem){
                standardMarginAtQuoteProposedPrice = (((1-totalDiscountPercentage/100) * listPrice) 
                                                        - standardCogs) * 
                                                            objQli.Apttus_QPConfig__Quantity2__c;
                                                        
            }
            else if(isSubsriptionLineItem){
                standardMarginAtQuoteProposedPrice = (((1-totalDiscountPercentage/100) * listPrice) 
                                                        - standardCogs) * 
                                                            objQli.Apttus_QPConfig__Quantity2__c *
                                                            objQli.Term_Months__c/12;
            }

        ilib_LogEvent.message('standardMarginAtQuoteProposedPrice' + standardMarginAtQuoteProposedPrice);
        ilib_LogEvent.pop();
        return standardMarginAtQuoteProposedPrice;
    }
}
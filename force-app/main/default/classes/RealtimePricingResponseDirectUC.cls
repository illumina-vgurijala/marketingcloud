/*
* @Author: Kushagra Desai
* @Date:
* @Description : Class to parse response recieved from SAP during Direct UC
* Test class for 90% coverage : TestValidateQuoteAutomation, TestApttusCheckPriceController, TestPricingAndValidationCallback, TestRealTimePricingResponseReciever
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date             Description
* Kushagra Desai       12-June-2019     DCP-25189 : Dynamic creation of JSON field
* Kushagra Desai       21-June-2019     DCP-26680 : Addition Checks
* Arnab Modak          03-Oct-2019      DCP-29847 for Fixed Combination Line Items
* Satya Swain          30-Jan-2019      Added logic to populate Promotion value in Check Price for INC0219156
* Arnab Modak          21-Mar-2020      DCP-34013 - Code Refactor, changes ApttusCheckPriceDirectUCController reference to ApttusCheckPriceBaseClass
* Roopal Verma         08-Mar-2021      DCP-42729: Added method updateSDDFromTotalDiscount
* Jitesh               2022-Aug-2       DCP-54361
* Jitesh Lakhwani      02-Aug-2022      DCP-53975 Fix
* Jitesh Lakhwani      23-Aug-2022      DCP-53975, hypercare 0794448
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class RealtimePricingResponseDirectUC {

	public static final String CODEPARAMETER = 'ValidateCartFieldCheck';
    public static final String ZDSK = 'ZDSK';
    public static final String ZTDD = 'ZTDD';
    public static final String ZFDS = 'ZFDS';
    public static final String ZPNP = 'ZPNP';
    public static final String ZFXP = 'ZFXP';
    public static final String UNDERSCORE_C = '__c';
    public static final String PRICING_STATUS_PENDING = 'Pending';
    private static final String ADJUSTMENT_TYPE_PRICE_OVERRIDE = 'Price Override';
    public static final String STR_DISC_AMOUNT = 'Discount Amount';
    public static final String STR_DISC_PER = '% Discount';
    public static final String STRHTMLTAGLINESTART = '<li>';//CodeScan Fix
    public static final String STRHTMLTAGLINEEND = '</li>';//CodeScan Fix


    /**
    * @wrapper for UC response parser
    */
    public class RealtimePricingResponseDirectUCWrapper {
		public exports NAVHTOEXPORT;
		public ItmExport NAVHTOITEMEX;
		public ItmInput NAVHTOITEMIN;
		public ItemPrice NAVHTOITEMPRICE;
		public Conditions NAVHTOITEMSCOND;
		public RETErrors NAVHTORETURN;
	}

    /**
    * @wrapper for List of RET Errors
    */
	public class RETErrors{
		public List<LineRETErrors> results;
	}

    /**
    * @wrapper for Line Item RET Errors
    */
    public class LineRETErrors{
		public string Type;
		public string Message;
	}

    /**
    * @wrapper for List of exports
    */
    public class exports{
		public List<HeaderExports> results;
	}

    /**
    * @wrapper for Exports
    */
    public class HeaderExports{
		public string ZSubtotal;
		public string ZTotalTax;
		public string ZTotalFreight;
		public string ZTotalDiscount;
		public string ZOrderTotal;
	}

    /**
    * @wrapper for Line Item List of Exports
    */
    public class ItmExport{
		public List<LineItmExport> results;
	}

    /**
    * @wrapper for Line Item Exports
    */
    public class LineItmExport{
		public string ItmNumber;
		public string Material;
		public string TaxAmount;
		public string SubtotPp4Per;
		public string SubtotPp4Pu;
        public String SubtotPp4;
	}

    /**
    * @wrapper for List of Line Item Input
    */
	public class ItmInput{
		public List<ListItmInput> results;
	}

    /**
    * @wrapper for Line Item Input
    */
    public class ListItmInput{
		public string TargetQu;
	}

    /**
    * @wrapper for List of Line Item Price
    */
	public class ItemPrice{
		public List<ListItemPrice> results;
	}

    /**
    * @wrapper for Line Item Price
    */
    public class ListItemPrice{
		public String ItmNumber;
		public string UnitPrice;
		public string ExtendedValue;
		public string SubtotPp4Per;
		public String SubtotPp4;
	}

    /**
    * @wrapper for List of Line Conditions
    */
	public class Conditions{
		public List<LineConditions> results;
	}

    /**
    * @wrapper for Line Conditions
    */
    public class LineConditions{
		public string ItmNumber;
		public string KonvKbetr;
		public string KonvKwert;
		public string KonvKschl;
		public string KonhKnumaPi;
		public string KonvKrech;
	}

    /*
    * @author Kushagra Desai
    * @Description Parser method to parse incoming JSON
    * @param Sobject Apttus_Config2__ProductConfiguration__c
    * @return Boolean
    */
    public static Boolean parser(Id idProductConfiguration, String strResponseJSON)
    {
        ilib_LogEvent.push('parser');

        Map<string,string> discountCodeToName = new Map<string,string>{
            'YD04'=> label.ApprovalStepNameSalesDiscretionary,
            'ZD02'=> label.Applied_Volume_Discount,
            'ZD01'=> label.Applied_Customer_Specific_Price,
            'ZFXP'=> label.Final_Fixed_Price,
            'ZTDD'=> Label.Applied_Distributor_Discount,
            'ZD03'=> Label.Applied_Volume_Discount
        };
        Map<String,Map<String,string>> internalPicklistToExternalPicklistDiscount =  utilsSettings.getCustomMetadataPicklistMap('Apttus_Proposal__Proposal__c','ERP',false);
        discountCodeToName.putall(internalPicklistToExternalPicklistDiscount.get('Discount_Condition'));
        Boolean boolError= false;
        Boolean boolISQuoteUpdate = true;
        Set<String> setUniquePromos = new Set<String>();
        Map<String, Object> lstJsonParse = (Map<String, Object>)Json.deserializeUntyped(strResponseJSON);
        Object objResponse = lstJsonParse.get('d');
        String ser = JSON.serialize(objResponse);
        ilib_LogEvent.message('serialize Response : '+ ser);
        Integer appliedPromoCnt = 1; //DCP-54361
        Set<Id> appliedPromotionIdSet = new Set<Id>(); //DCP-54361
        Set<String> setConfigAllPromoCode = new Set<String>(); // DCP-53975 Changes
        Boolean boolIsDirectUC; // DCP-53975 Changes



        RealtimePricingResponseDirectUCWrapper objRTPResponse = (RealtimePricingResponseDirectUCWrapper) JSON.deserialize(ser, RealtimePricingResponseDirectUCWrapper.class);
        ilib_LogEvent.message('@@@ RTP Response ' + objRTPResponse);

        if(objRTPResponse != null){
        	Apttus_Config2__ProductConfiguration__c objConfig = new Apttus_Config2__ProductConfiguration__c(
                id = idProductConfiguration,SAP_Errors__c = ''
            );

        	// Over all pricing
        	if(objRTPResponse.NAVHTOEXPORT != null){
        		for(RealtimePricingResponseDirectUC.HeaderExports ex : objRTPResponse.NAVHTOEXPORT.results){
        			ilib_LogEvent.message(ex.ZOrderTotal);
                    objConfig.Total_Net__c = UtilsRest.convertStringToNumber(ex.ZOrderTotal);
                    objConfig.Total_Discount__c = UtilsRest.convertStringToNumber(ex.ZTotalDiscount);
                    objConfig.Estimated_Freight__c = UtilsRest.convertStringToNumber(ex.ZTotalFreight);
                    objConfig.Estimated_Tax__c = UtilsRest.convertStringToNumber(ex.ZTotalTax);
                    //Added as part of DCP-24589
                    objConfig.Number_of_Line_Items_During_Check_Price__c = RealtimePricingRequestDirectUC.lineNameToLineItem.values().size();
                }
        	}

            /*
            ******************************************************
            **Loop to get total discounts on lines from response**
            ******************************************************
            */
            if(objRTPResponse.NAVHTOITEMPRICE != null)
            {
            	ilib_LogEvent.message('Inside Item Structure');
				// DCP-25189 : Dynamic creation of JSON field
                List<Code_Parameter__mdt> codeParameter = [SELECT Id, DeveloperName, Value__c FROM Code_Parameter__mdt WHERE DeveloperName =: CODEPARAMETER];
                List<String> setFieldAPI = codeParameter[0].Value__c.split(',');
                for(RealtimePricingResponseDirectUC.ListItemPrice li : objRTPResponse.NAVHTOITEMPRICE.results)
                {
                	Apttus_Config2__LineItem__c localLine = RealtimePricingRequestDirectUC.lineNameToLineItem.get(RealtimePricingRequestDirectUC.sapItemToLineItem.get(String.valueOf(Integer.valueOf(li.ItmNumber))));
                    localLine.Applied_Discount_Percentage__c = UtilsRest.convertStringToNumber(li.SubtotPp4Per);

                    // DCP-25189 : Dynamic creation of JSON field
                    Map<String,String> mapFieldValue = UtilsCollection.getMapofAPInameTOValue(localLine,setFieldAPI);
                    String strLineItemJson = JSON.serializePretty(mapFieldValue);
                    localLine.Line_Item_Old_Values__c = strLineItemJson;

                    //DCP-26680 : Addition Checks
                    localLine.Line_Item_Validate_Old__c = '';

                }
            }
            if(objRTPResponse.NAVHTOITEMEX != null){
            	ilib_LogEvent.message('Inside Item Structure');
                for(RealtimePricingResponseDirectUC.LineItmExport li : objRTPResponse.NAVHTOITEMEX.results){
                	Apttus_Config2__LineItem__c localLine = RealtimePricingRequestDirectUC.lineNameToLineItem.get(RealtimePricingRequestDirectUC.sapItemToLineItem.get(String.valueOf(Integer.valueOf(li.ItmNumber))));
                    localLine.Applied_Discount_Amount__c = UtilsRest.convertStringToNumber(li.SubtotPp4);
                }
            }

        	// Item pricing
        	if(objRTPResponse.NAVHTOITEMSCOND != null){
        		for(RealtimePricingResponseDirectUC.LineConditions cond : objRTPResponse.NAVHTOITEMSCOND.results)
                {
        			Apttus_Config2__LineItem__c localLine = RealtimePricingRequestDirectUC.lineNameToLineItem.get(RealtimePricingRequestDirectUC.sapItemToLineItem.get(String.valueOf(Integer.valueOf(cond.ItmNumber))));
                    if(cond.KonvKschl == ZDSK){
                        ilib_LogEvent.message('**1-Inside condition Structure');
                        localLine.Stacked_Discount_Percentage__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                        localLine.Stacked_Discount_Amount__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                        localLine.Total_Discount_Percentage__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                        localLine.Total_Discount_Amount__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                    }

                    if(cond.KonvKschl == ZTDD){
                        ilib_LogEvent.message('**2-Inside condition Structure');
                        localLine.Distributor_Specific_Discount_Percentage__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                        localLine.Distributor_Specific_Discount__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                    }

                    updateSDDFromTotalDiscount(localLine);
                    if(cond.KonvKschl == ZFDS){
                        ilib_LogEvent.message('**3-Inside condition Structure');
                        localLine.Freight_Discount_Amount__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                    }
                    if(cond.KonvKschl == ZPNP){
                        ilib_LogEvent.message('**4-Inside condition Structure');
                        localLine.Discounted_Price_Per_Unit__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                        localLine.SAP_Net_Price__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                        localLine.Apttus_Config2__PricingStatus__c = PRICING_STATUS_PENDING;
                        //DCP-29847 for Fixed Combination Line Items
                        if(localLine.Apttus_Config2__ProductId__r.Material_Class_Type__c != Label.FixedBundleMatClassType){
                            localLine.Apttus_Config2__AdjustmentType__c = ADJUSTMENT_TYPE_PRICE_OVERRIDE;
                            localLine.Apttus_Config2__AdjustmentAmount__c = localLine.SAP_Net_Price__c;
                        }
                        localLine.Apttus_Config2__BasePriceOverride__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                        localLine.Distributor_Specific_Price__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                    }
                    if(cond.KonvKschl == 'ZL01' || cond.KonvKschl == 'ZPSV'){
                        ilib_LogEvent.message('**5-Inside condition Structure');
                        localLine.List_Price__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                        localLine.Total_List_Price__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                    }

                    if(cond.KonvKschl == ZFXP){
                        ilib_LogEvent.message('----ZFXP Condition----');
                        localLine.Fixed_Price__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                        localLine.Fixed_Price_Per_Unit__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                    }

                    if(discountCodeToName.keyset().contains(cond.KonvKschl) && UtilsRest.convertStringToNumber(cond.KonvKwert) >0){
                    	ilib_LogEvent.message('----Discount Condition----');
                        localLine.Applied_Discount_Details__c += ';'+ discountCodeToName.get(cond.KonvKschl) + ';';
                        ilib_LogEvent.message('**002-Discount detail-'+ localLine.Applied_Discount_Details__c);
                        localLine.Applied_Discount_Details__c = localLine.Applied_Discount_Details__c.removeStart('null;');
                        localLine.Applied_Discount_Details__c= localLine.Applied_Discount_Details__c.replace(';',' ');
                        ilib_LogEvent.message('**002-Discount detail-'+ localLine.Applied_Discount_Details__c);

                        // Added by Satya for INC0219156, populate promotion fields on Line Item
                        if(String.isNotBlank(cond.KonhKnumaPi)){
                            setUniquePromos.add(cond.KonhKnumaPi);
                            RealtimePricingRequestGenerator.AppliedPromo promolocal = new RealtimePricingRequestGenerator.AppliedPromo();
                            promolocal.promoCode = cond.KonhKnumaPi;
                            promolocal.conditionType = cond.KonvKschl;
                            String strLineName = RealtimePricingRequestDirectUC.sapItemToLineItem.get(String.valueOf(Integer.valueOf(cond.ItmNumber)));

                            if(!RealtimePricingRequestGenerator.lineNumberToAppliedPromos.containsKey(strLineName)){
                                RealtimePricingRequestGenerator.lineNumberToAppliedPromos.put(strLineName,new List<RealtimePricingRequestGenerator.AppliedPromo>{promolocal});
                            }
                            else{
                                RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(strLineName).add(promolocal);
                            }
                        }
                    }
        		}
        	}

        	ApttusCheckPriceBaseClass.strRETErrors = '';
        	if(objRTPResponse.NAVHTORETURN != null){
        		for(RealtimePricingResponseDirectUC.LineRETErrors ret : objRTPResponse.NAVHTORETURN.results){
        			if(ret.Type == 'E' || ret.Type == 'A'){
                        ApttusCheckPriceBaseClass.boolRETError = true;
                        ilib_LogEvent.message('ApttusCheckPriceBaseClass.strRETErrors ->'+ApttusCheckPriceBaseClass.strRETErrors);
                        ApttusCheckPriceBaseClass.strRETErrors +=  '<li>' +ret.Message + '</li>';
                        boolError = true;
                        boolISQuoteUpdate = false;
                        ilib_LogEvent.message('ApttusCheckPriceBaseClass.strRETErrors ->'+ApttusCheckPriceBaseClass.strRETErrors);
                    }
        		}
        		ApttusCheckPriceBaseClass.strRETErrors += '</ui>';
                objConfig.SAP_Errors__c = ApttusCheckPriceBaseClass.strRETErrors;
                ilib_LogEvent.message('Data Errors -- '+ ApttusCheckPriceBaseClass.strRETErrors);
        	}
            // Added for INC0219156
            if(!setUniquePromos.isEmpty()){
                List<Apttus_Config2__Incentive__c> lstIncentive = new ApttusIncentivesPromotionsSelector().getPromotions(setUniquePromos);
                for(Apttus_Config2__Incentive__c inc : lstIncentive){
                    RealtimePricingRequestDirectUC.promoCodeToIncentive.put(inc.Apttus_Config2__IncentiveCode__c,inc);
                }
            }
            // Start of DCP-54361, This is done for deletion, in case if user removes all promos this will take care of it.
            RealtimePricingRequestDirectUC.objQuote.put('Applied_Promo_1__c',null); 
            RealtimePricingRequestDirectUC.objQuote.put('Applied_Promo_2__c',null); 
            RealtimePricingRequestDirectUC.objQuote.put('Applied_Promo_3__c',null); 
            // End of DCP-54361
            //Changes of DCP-53975
            //This will get all the promo codes from the configuration of the line items.
            if(!RealtimePricingRequestDirectUC.lineNameToLineItem.isEmpty()){
       
                RealtimePricingResponseParser.getAllConfigPromoCodes(RealtimePricingRequestDirectUC.lineNameToLineItem.values()[0], setConfigAllPromoCode);
                boolIsDirectUC = RealtimePricingRequestDirectUC.lineNameToLineItem.values()[0].Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c;
                ilib_LogEvent.message('### All Configuration Promo Codes ' + setConfigAllPromoCode);
            }
            //DCP-53975 Changes End Here.

            for(String proLine : RealtimePricingRequestGenerator.lineNumberToAppliedPromos.keyset()){
                Apttus_Config2__LineItem__c localLine = RealtimePricingRequestDirectUC.lineNameToLineItem.get(proLine);
                integer intCounter = 1;
                for(RealtimePricingRequestGenerator.AppliedPromo promo : RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)){
                    localLine.put('Promo_Channel_'+intCounter+UNDERSCORE_C,RealtimePricingRequestDirectUC.promoCodeToIncentive.get(promo.promoCode).Promo_Channel__c);
                    localLine.put('Promo_Name_'+intCounter+UNDERSCORE_C,RealtimePricingRequestDirectUC.promoCodeToIncentive.get(promo.promoCode).Apttus_Config2__Description__c);
                    localLine.put('Promo_Code_'+intCounter+UNDERSCORE_C,promo.promoCode);
//                    localLine.put('Promo_T_C_'+intCounter+'__c',RealtimePricingRequestDirectUC.promoCodeToIncentive.get(promo.promoCode).Promotion_Terms_and_Conditions__c);
                    localLine.put('Promotion_'+intCounter+UNDERSCORE_C,RealtimePricingRequestDirectUC.promoCodeToIncentive.get(promo.promoCode).id);
                    intCounter++;
                    
                    //Removed the applied promo code from the configuration set DCP-53975
                    if(!setConfigAllPromoCode.isEmpty() && setConfigAllPromoCode.contains(promo.promoCode)){

                        setConfigAllPromoCode.remove(promo.promoCode);
                    }
                }
                // Start of DCP-54361, this if is added to resolve a bug where 2 same promotion where coming on Quote.
                if(RealtimePricingRequestDirectUC.promoCodeToIncentive.get(RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)[0].promoCode).Master_Promotions__c != null && !appliedPromotionIdSet.contains(RealtimePricingRequestDirectUC.promoCodeToIncentive.get(RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)[0].promoCode).Master_Promotions__c)){

                    //Update the Quote Applied Promotion field
                    RealtimePricingRequestDirectUC.objQuote.put('Applied_Promo_'+appliedPromoCnt+UNDERSCORE_C, RealtimePricingRequestDirectUC.promoCodeToIncentive.get(RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)[0].promoCode).Master_Promotions__c);
                    appliedPromotionIdSet.add(RealtimePricingRequestDirectUC.promoCodeToIncentive.get(RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)[0].promoCode).Master_Promotions__c);
                    appliedPromoCnt++;
                } 
                // End of DCP-54361
            }

            //Changes of DCP-53975, hyper care 0794448
            // This will be true when we have selected promo codes on configuration level 
            if(!setConfigAllPromoCode.isEmpty() && boolIsDirectUC == true){

                ilib_LogEvent.message('### Not Applied Promo Codes' + setConfigAllPromoCode);
                //Convert the Set into a String
                String strNotAppliedPromo = String.join(new List<String>( setConfigAllPromoCode), ', ' );

                //When we have promo codes which are not applied on line items this will give errors.
                ApttusCheckPriceBaseClass.boolWarning = true;
                ApttusCheckPriceBaseClass.strWarningMsgs += STRHTMLTAGLINESTART+LABEL.PromoNotAppliedInfoMessage.replace('{0}',strNotAppliedPromo) + STRHTMLTAGLINEEND;

                ilib_LogEvent.message('### Warning Message' + ApttusCheckPriceBaseClass.strWarningMsgs);   
            }
            //DCP-53975 Changes End Here, hyper care 0794448

        	if(boolISQuoteUpdate){
                ilib_LogEvent.message('Manual price ye hai --'+RealtimePricingRequestDirectUC.lineNameToLineItem.values());
                update RealtimePricingRequestDirectUC.lineNameToLineItem.values();
                objConfig.Apttus_Config2__IsPricePending__c = true;
                objConfig.Is_SAP_Pricing_Completed__c = false;
                update objConfig;
                update RealtimePricingRequestDirectUC.objQuote;
                ilib_LogEvent.message('Final if if if -->'+RealtimePricingRequestDirectUC.lineNameToLineItem.values());
            }
            else{
                update objConfig;
            }
        }

        ilib_LogEvent.pop();
        return boolError;
    }


   /**
    *  @author Himanshu
    * @DCP-42729- Update Sales Discretionary Discount based on Total requested discount %
    *  @param Apttus_Config2__LineItem__c
    **/
    public static void updateSDDFromTotalDiscount(Apttus_Config2__LineItem__c objlocalLine){
        if(objlocalLine.Distributor_Total_Discount__c != null && objlocalLine.Distributor_Specific_Discount_Percentage__c!= null && objlocalLine.Distributor_Total_Discount__c > 0 && objlocalLine.Distributor_Total_Discount__c >= objlocalLine.Distributor_Specific_Discount_Percentage__c){
            Decimal decTRD = ((objlocalLine.Distributor_Total_Discount__c * objlocalLine.List_Price__c)/100 );
            Decimal decDSD = ((objlocalLine.Distributor_Specific_Discount_Percentage__c) * objlocalLine.List_Price__c)/100;
            //Decimal decDSD = (objlocalLine.Distributor_Specific_Discount__c/objlocalLine.Apttus_Config2__Quantity__c);
            objlocalLine.Sales_Discretionary_Discount__c = decTRD - decDSD;
            objlocalLine.Sales_Discretionary_Type__c = STR_DISC_AMOUNT;
        }
        if(objlocalLine.Distributor_Total_Discount__c <= objlocalLine.Distributor_Specific_Discount_Percentage__c){
            objlocalLine.Sales_Discretionary_Discount__c = null;
            objlocalLine.Sales_Discretionary_Type__c = STR_DISC_PER;

        }
    }

}
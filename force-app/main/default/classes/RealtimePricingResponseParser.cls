/*
* @Author: Kushagra Desai
* @Date: 2018-11-07
* @Description : Class to parse response recieved from SAP
* Test class for 90% coverage : TestApttusCheckPriceController, TestPricingAndValidationCallback, TestRealTimePricingResponseReciever
* --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                        Description
 * Roopal                  30-05-2019                   Modifications for manual rebate, DCP-25322
 * Kushagra Desai          12-June-2019                 DCP-25908 : Update payment term
 * Kushagra Desai          13-June-2019                 DCP-25189 : Dynamic creation of JSON field
 * Saswati                 29-Sept-2019                 DCP-28565: Fapiao Code Logic
 * Arnab Modak             03-Sept-2019                 DCP-28284 : Fixed Bundle - Populating Start and End date for Service products
 * Arnab Modak             01-Oct-2019                  DCP-29847: Roll up fields for RTP Integration
 * Satya Swain             30-Jan-2019                  Added logic to populate Promotion value in Check Price for INC0219156
 * Arnab Modak             21-Mar-2020                  DCP-34013 - Code Refactor, changes ApttusCheckPriceController reference to ApttusCheckPriceBaseClass
 * Roopal Verma            21-May-2020                  DCP-30425 - Added logic for getting Beadchip name
 * Rishab Wali             2-June-2020                  DCP-34910 - Added logic for Validate Large Carts
 * Rishab Wali             25-Nov-2020                  DCP-23566 Accept ZPNP instead of ZCNP
 * Rishab Wali             12-Dec-2020                  DCP-31081 Beadchip soft error warning
 * Roopal Verma            08-Mar-2021                  DCP-42729: calling method updateSDDFromTotalDiscount for updated sales discretionary discount
 * KD                      05-May-2021                  DCP-45742 : Added Serial number in line vallidate JSON for relocation Quote
 * Adyasha                 30-Jul-2021                  DCP-49511: Warning Message for travel and labor lines during validate cart
 * Adyasha                 23-Aug-2021                  INC0340943: Added check for Product Interest 
 * Ashwin                  12-Dec-2021                  INC0362350: Move ilib_LogEvent.message inside null check block
 * Rishi                   16-Feb-2022                  DCP-52031 - Get Manual Rebate Net from SAP which will be Manual Rebate Per Unit * Quantity
 * Jitesh Lakhwani         2022-07-20                   DCP-54361 - Show Promotion on Quote Header Level.
 * Rishi Sharma            21-Jul-2022                  DCP-54311 - Beadchip name to be pulled in full
 * Jitesh Lakhwani         02-Aug-2022                     DCP-53975 Fix
 * Jitesh Lakhwani         2022-08-23                   HyperCare 0794448
 * Khushbu Vasani          2022-09-01                   DCP-56658 changes
 * Vinay S Reddy           2023-10-23                   CMCM 1482 Updates
 * ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class RealtimePricingResponseParser {

    public static final String PRICING_STATUS_PENDING = 'Pending';
    private static final String ADJUSTMENT_TYPE_PRICE_OVERRIDE = 'Price Override';
    public static final String CODEPARAMETER = 'FinalizeFieldCheck';
    public static final String CUSTOMFIELDSUFFIX = '__c';
	public static final String WARNING = 'X';
    public static final String ZFXP = 'ZFXP';
    public static final String ZB02 = 'ZB02';
    public static final String CHECKIND_B = 'B';
    public static final String ZINCO = 'ZINCO';
    public static final String ZMDLC = 'ZMDLC';
    public static final String STRHTMLTAGLINESTART = '<li>';//CodeScan Fix
    public static final String STRHTMLTAGLINEEND = '</li>';//CodeScan Fix

    public static final String PROMO1 = 'Promo1'; // DCP-53975 Changes
    public static final String PROMO2 = 'Promo2'; // DCP-53975 Changes
    public static final String PROMO3 = 'Promo3'; // DCP-53975 Changes

    public static final String ZBDD = 'ZBDD';//DCP-54311 Changes
    public static final String INTERNAL='Internal';
    public static final String EXTERNAL ='External';
    public static final String ALPHBETC='C';
    public static final String ALPHBETD ='D';
    public static final String MKTEXTERNAL ='Marketing External';
    public static final String MKTINTERNAL ='Marketing Internal';

    /*
    * @author Kushagra Desai
    * @Description Generator class to create request JSON
    * @param Sobject Apttus_Config2__ProductConfiguration__c
    * @return String containg error
    */
    public static Boolean parser(Id idProductConfiguration, String strResponseJSON)
    {
        ilib_LogEvent.push('parser');

        Map<String, String> discountCodeToName = new Map<String, String> {
            'ZNHP'=>'HeaderNSIPromo',
            'ZNGP'=>'GroupNSIPromo',
            'ZNIP'=>'ItemNSIPromo',
            'ZSHP'=>'StackPromoHdrDisc',
            'ZSGP'=>'StackPromoGrpDisc',
            'ZSIP'=>'StackableItmPromo',
            'ZNMI'=>'MultiItemNSPromo',
            'ZSMI'=>'MultiItemSPromo',
            'ZNRP'=>'Sngl.RefNSPromo',
            'ZSRP'=>'StackSngl.RefPromo',
            'ZFP1'=>'PromoShipping',
            'ZFAD'=>'FreightAdjustment',
            'ZNFP'=>'FreightNSIPromo',
            'ZNHE'=>'HeaderNSEPromo',
            'ZNGE'=>'GroupNSEPromo',
            'ZNIE'=>'ItemNSEPromo',
            'ZNRE'=>'Sngl.RefNSEPromo',
            'ZNME'=>'MultiItemNSEPromo',
            'ZNFE'=>'FreightNSEPromo',
            'YD04'=> label.ApprovalStepNameSalesDiscretionary,
            'ZD02'=> label.Applied_Volume_Discount,
            'ZD01'=> label.Applied_Customer_Specific_Price,
            'ZFXP'=> label.Final_Fixed_Price,
            'ZTDD'=> Label.Applied_Distributor_Discount,
            'ZD03'=> Label.Applied_Volume_Discount
        };

        Map<String, String> lineNumberToMaterialName = new Map<String, String>();
        Boolean boolError= false;
        Boolean boolISQuoteUpdate = true;
        Set<String> setUniquePromos = new Set<String>();
        Map<String, Object> lstJsonParse = (Map<String, Object>)Json.deserializeUntyped(strResponseJSON);
        Object objResponse = lstJsonParse.get('d');
        String ser = JSON.serialize(objResponse);
        ilib_LogEvent.message('serialize Response : '+ ser);
        RealtimePricingResponse objRTPResponse = (RealtimePricingResponse) JSON.deserialize(ser, RealtimePricingResponse.class);
        ilib_LogEvent.message('@@@ RTP Response ' + objRTPResponse);
        ilib_LogEvent.message('SAP Quote Number--'+objRTPResponse.ZzapQuot);
        List<String> lstOfEligibleMaterialNumberForOocc = new List<String>();

        Set<String> setConfigAllPromoCode = new Set<String>(); // DCP-53975 Changes
        Boolean boolIsDirectUC; // DCP-53975 Changes, Hyper care 0794448
        boolean boolDiffNgnOfSoldToAndUCAndSatisfiedCondForInfo = false;

        Integer appliedPromoCnt = 1; //DCP-54361
        Set<Id> appliedPromotionIdSet = new Set<Id>(); //DCP-54361
        boolean boolOpenOfferMaxBlank = false;

        //DCP-28284 - Billing Frequency SAP value to Salesforce value Map
        Map<String,Map<String,string>> internalPicklistToExternalPicklistQuote =  utilsSettings.getCustomMetadataPicklistMap('Apttus_Config2__LineItem__c','ERP',false);

        if(objRTPResponse != null){
            Apttus_Config2__ProductConfiguration__c objConfig = new Apttus_Config2__ProductConfiguration__c(
                Id = idProductConfiguration,
                SAP_Errors__c = ''
            );

            ilib_LogEvent.message('EV Sales Doc ----' + objRTPResponse.EvSalesDocument);
            if(RealtimePricingRequestGenerator.objQuote == null)
            {
                Apttus_Config2__ProductConfiguration__c objConf = new ApttusProductConfigurationsSelector().selectConfigWithLines(new Set<Id> {idProductConfiguration})[0];
                RealtimePricingRequestGenerator.objQuote = objConf.Apttus_QPConfig__Proposald__r;
            }

            ilib_LogEvent.message('RTP objQuote --' + RealtimePricingRequestGenerator.objQuote);
            ilib_LogEvent.message('objConfig' + objConfig.Apttus_QPConfig__Proposald__r);
            RealtimePricingRequestGenerator.objQuote.SAP_quote__c = objRTPResponse.EvSalesDocument;
            // DCP-25908 : Update payment term
            if(String.isNotBlank(RealtimePricingRequestGenerator.objQuote.Bill_To_ERP_Number__c) && String.isBlank(RealtimePricingRequestGenerator.objQuote.Apttus_Proposal__Payment_Term__c)){
                RealtimePricingRequestGenerator.objQuote.Apttus_Proposal__Payment_Term__c = (String)objRTPResponse.Pmnttrms;
            }

            /*
            Code added by Saswati for DCP-28565
            */
            ilib_LogEvent.message('#### REsponse- '+ objResponse);

            if(objRTPResponse.NAVHDRTOFAPIAO !=null)
            {
                ilib_LogEvent.message('### Inside Fapiao');
                ilib_LogEvent.message ('NAVHDRTOFAPIO - '+objRTPResponse.NAVHDRTOFAPIAO);
                ilib_LogEvent.message ('objConfig Proposal- '+objConfig.Apttus_QPConfig__Proposald__r);
                ilib_LogEvent.message ('NAVHDRTOFAPIO Results'+objRTPResponse.NAVHDRTOFAPIAO.results);
                if(objRTPResponse.NAVHDRTOFAPIAO.results!=null && objRTPResponse.NAVHDRTOFAPIAO.results.size() >0 )
                {
                    for(RealtimePricingResponse.LineFapiao lfapiao : objRTPResponse.NAVHDRTOFAPIAO.results){
                        if(lfapiao.FapiaoTypeCode!=null) { RealtimePricingRequestGenerator.objQuote.Fapiao_Type_Code__c = lfapiao.FapiaoTypeCode; }
                        if(lfapiao.FapiaoTypeDesc!=null) { RealtimePricingRequestGenerator.objQuote.Fapiao_Type_Description__c = lfapiao.FapiaoTypeDesc; }
                    }
                }
            }

            /*
            ********************************************************
            **Loop to update Quotation from  response**
            ********************************************************
            */
            if(objRTPResponse.NAVHDRTOEXP != null){             // Confirmation from SAP complete NAVHDRTOEXP will be null individual result will npt be null
                for(RealtimePricingResponse.LineExports ex : objRTPResponse.NAVHDRTOEXP.results)
                {
                    objConfig.Total_Net__c = UtilsRest.convertStringToNumber(ex.ZOrderTotal);
                    objConfig.Total_Discount__c = UtilsRest.convertStringToNumber(ex.ZTotalDiscount);
                    objConfig.Estimated_Freight__c = UtilsRest.convertStringToNumber(ex.ZTotalFreight);
                    objConfig.Estimated_Tax__c = UtilsRest.convertStringToNumber(ex.ZTotalTax);
                    objConfig.Sub_Total__c = UtilsRest.convertStringToNumber(ex.ZSubtotal);
                }
            }

            if (RealtimePricingRequestGenerator.lineNameToLineItem != null)
            {
                //DCP-29847 Rollup
                if (objRTPResponse.NAVHDRTOCND != null && objRTPResponse.NAVHDRTOCND.results != null)
                {
                    Map<Decimal,Apttus_Config2__LineItem__c> lineItemNumberToLineItemBundle = new Map<Decimal,Apttus_Config2__LineItem__c>();
                    for(Apttus_Config2__LineItem__c objCartLine: RealtimePricingRequestGenerator.lineNameToLineItem.values())
                    {
                        if ((objCartLine.Apttus_Config2__OptionId__c == null &&  objCartLine.Apttus_Config2__ProductId__r.Material_Class_Type__c == Label.FixedBundleMatClassType) || test.isRunningTest() )
                        {
                            lineItemNumberToLineItemBundle.put(objCartLine.Apttus_Config2__LineNumber__c,objCartLine);
                        }
                    }

                    if(!lineItemNumberToLineItemBundle.isEmpty())
                    {
                        for(RealtimePricingResponse.LineCondition cond : objRTPResponse.NAVHDRTOCND.results)
                        {
                            Apttus_Config2__LineItem__c localOptionLine = RealtimePricingRequestGenerator.lineNameToLineItem.get(cond.ZzapPosnr);
                            Apttus_Config2__LineItem__c bundleLine = lineItemNumberToLineItemBundle.get(localOptionLine.Apttus_Config2__LineNumber__c);

                            if(cond.CondType == 'YCO1' && !RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                                if(bundleLine!=null){
                                    if(bundleLine.Price_Override__c==null) { bundleLine.Price_Override__c = 0.00; }
                                    bundleLine.Price_Override__c += localOptionLine.Price_Override__c;
                                }
                            }

                            if(cond.CondType == 'YMUP' && RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                                if(bundleLine!=null){
                                    if(bundleLine.Customer_Premium_Amount_Per_Unit__c==null) { bundleLine.Customer_Premium_Amount_Per_Unit__c = 0.00; }
                                    bundleLine.Customer_Premium_Amount_Per_Unit__c += localOptionLine.Customer_Premium_Amount_Per_Unit__c;
                                }
                            }
                        }
                    }
                // ----- DCP-29847 ends
                }


                /*
                *******************************************
                **Loop to get all condition from response**
                *******************************************
                */

                //apttuslineNumberToLineItemMap
                if(objRTPResponse.NAVHDRTOITEMCOND != null){
                    ilib_LogEvent.message('Inside condition Structure');
                    for(RealtimePricingResponse.LineConditions cond : objRTPResponse.NAVHDRTOITEMCOND.results){
                        Apttus_Config2__LineItem__c localLine ;
                        if(RealtimePricingRequestGenerator.lineNameToLineItem.containsKey(cond.ZzapPosnr)){ localLine = RealtimePricingRequestGenerator.lineNameToLineItem.get(cond.ZzapPosnr); }

                        if(cond.KonvKschl == 'ZDSK' && !RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                            ilib_LogEvent.message('**1-Inside condition Structure');
                            // This is used in template
                            localLine.Stacked_Discount_Percentage__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                            localLine.Stacked_Discount_Amount__c = UtilsRest.convertStringToNumber(cond.Krate); // KD : Changed as part of INC0195750
                            //*****
                            localLine.Total_Discount_Percentage__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                            localLine.Total_Discount_Amount__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                        }

                        if(cond.KonvKschl == 'ZTDD' && !RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                            ilib_LogEvent.message('**2-Inside condition Structure');
                            //localLine.Distributor_Discount_Percentage__c = convertStringToNumber(cond.KonvKbetr);
                            //localLine.Distributor_Discount_Amount__c = convertStringToNumber(cond.KonvKwert);
                            localLine.Distributor_Specific_Discount_Percentage__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                            localLine.Distributor_Specific_Discount__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                        }

                        if(cond.KonvKschl == 'ZFDS' && !RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                            ilib_LogEvent.message('**3-Inside condition Structure');
                            localLine.Freight_Discount_Amount__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                        }

                        if(cond.KonvKschl == 'ZPNP' && !RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                            ilib_LogEvent.message('**4-Inside condition Structure');
                            //Changed as part of INC0196316
                            localLine.Discounted_Price_Per_Unit__c = UtilsRest.convertStringToNumber(cond.Krate);
                            //ApttuslineNumberToLineItem.get(cond.ZzapPosnr).Apttus_Config2__NetPrice__c = convertStringToNumber(cond.KonvKwert);
                            localLine.SAP_Net_Price__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                            localLine.Apttus_Config2__PricingStatus__c = PRICING_STATUS_PENDING;
                            //DCP-28284 for Fixed Combination Line Items
                            if(localLine.Apttus_Config2__ProductId__r.Material_Class_Type__c != Label.FixedBundleMatClassType){
                                localLine.Apttus_Config2__AdjustmentType__c = ADJUSTMENT_TYPE_PRICE_OVERRIDE;
                                localLine.Apttus_Config2__AdjustmentAmount__c = localLine.SAP_Net_Price__c;
                            }
                            localLine.Apttus_Config2__BasePriceOverride__c = UtilsRest.convertStringToNumber(cond.Krate);
                        }

                        if((cond.KonvKschl == 'ZL01' || cond.KonvKschl == 'ZPSV') && !RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                            ilib_LogEvent.message('**5-Inside condition Structure');
                            //ApttuslineNumberToLineItem.get(cond.ZzapPosnr).Apttus_Config2__ListPrice__c = convertStringToNumber(cond.KonvKbetr);
                            localLine.Total_List_Price__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                            localLine.List_Price__c = UtilsRest.convertStringToNumber(cond.KonvKbetr);
                        }

                        if(cond.KonvKschl == ZFXP){
                            ilib_LogEvent.message('----ZFXP Condition----');
                            localLine.Fixed_Price__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                            localLine.Fixed_Price_Per_Unit__c = UtilsRest.convertStringToNumber(cond.Krate);
                        }
                        //DCP-23566 Accept ZPNP instead of ZCNP
                        if(cond.KonvKschl == 'ZPNP' && RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                            ilib_LogEvent.message('----ZPNP Condition Direct Sale To Ultimate Consignee----');
                            localLine.Customer_Net_Price__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                            localLine.Customer_Price_Per_Unit__c = UtilsRest.convertStringToNumber(cond.Krate);
                        }

                        if(cond.KonvKschl == ZB02){
                            ilib_LogEvent.message('----ZB02 Condition----');
                            localLine.Distributor_Rebate__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                        }
                        
                        //DCP-52031 - Get Manual Rebate Net from SAP for YB01
                        if(cond.KonvKschl == 'YB01' && RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                            ilib_LogEvent.message('----YB01 Condition Direct Sale To Ultimate Consignee----');
                            localLine.Manual_Rebate__c = UtilsRest.convertStringToNumber(cond.KonvKwert);
                        }

                        if(discountCodeToName.keyset().contains(cond.KonvKschl) && UtilsRest.convertStringToNumber(cond.KonvKwert) > 0){
                            localLine.Applied_Discount_Details__c += ';'+ discountCodeToName.get(cond.KonvKschl) + ';';
                            ilib_LogEvent.message('**002-Discount detail-'+ localLine.Applied_Discount_Details__c);
                            localLine.Applied_Discount_Details__c = localLine.Applied_Discount_Details__c.removeStart('null;');
                            localLine.Applied_Discount_Details__c= localLine.Applied_Discount_Details__c.replace(';',' ');
                            ilib_LogEvent.message('**002-Discount detail-'+ localLine.Applied_Discount_Details__c);
                            if(String.isNotBlank(cond.KonhKnumaPi)){
                                setUniquePromos.add(cond.KonhKnumaPi);
                                RealtimePricingRequestGenerator.AppliedPromo promolocal = new RealtimePricingRequestGenerator.AppliedPromo();
                                promolocal.promoCode = cond.KonhKnumaPi;
                                promolocal.conditionType = cond.KonvKschl;
                                if(!RealtimePricingRequestGenerator.lineNumberToAppliedPromos.containsKey(cond.ZzapPosnr)){ RealtimePricingRequestGenerator.lineNumberToAppliedPromos.put(cond.ZzapPosnr,new List<RealtimePricingRequestGenerator.AppliedPromo>{promolocal});}
                                else{
                                    RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(cond.ZzapPosnr).add(promolocal);
                                }
                            }
                        }
                    }
                }

                /*
                ******************************************************
                **Loop to get total discounts on lines from response**
                ******************************************************
                */
                if (objRTPResponse.NAVHDRTOITM != null)
                {
                    ilib_LogEvent.message('Inside Item Structure');
                    ilib_LogEvent.message('LineItems--->'+ objRTPResponse.NAVHDRTOITM.results);     //INC0362350
					// DCP-25189 : Dynamic creation of JSON field
                    List<Code_Parameter__mdt> codeParameter = [SELECT Id, DeveloperName, Value__c FROM Code_Parameter__mdt WHERE DeveloperName =: CODEPARAMETER];
                    List<String> setFieldAPI = codeParameter[0].Value__c.split(',');
                    if (RealtimePricingRequestGenerator.intNumberOfLineItems == null)
                    {
                        RealtimePricingRequestGenerator.intNumberOfLineItems = 0;
                    }

                    for (RealtimePricingResponse.LineItems li : objRTPResponse.NAVHDRTOITM.results)
                    {
                        lineNumberToMaterialName.put(li.SapItmNumber, li.Material);

                        RealtimePricingRequestGenerator.intNumberOfLineItems++;
                        Apttus_Config2__LineItem__c localLine ;
                        if(RealtimePricingRequestGenerator.lineNameToLineItem.containsKey(li.ZzapPosnr)){ localLine = RealtimePricingRequestGenerator.lineNameToLineItem.get(li.ZzapPosnr); }

                        if(!RealtimePricingRequestGenerator.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                            localLine.Applied_Discount_Amount__c = UtilsRest.convertStringToNumber(li.SubtotPp4);
                            localLine.Applied_Discount_Percentage__c = UtilsRest.convertStringToNumber(li.SubtotPp4Per);
                            checkCriteriaForWarningMessageForOpenOffer(localLine,lstOfEligibleMaterialNumberForOocc);

                            boolDiffNgnOfSoldToAndUCAndSatisfiedCondForInfo = AccountPricingTiersService.checkCriteriaForWarningMessageForNoNgnAndDiffErpOfSoldToAndUc(localLine);
                           
                            if(!boolDiffNgnOfSoldToAndUCAndSatisfiedCondForInfo)
                            {
                                boolOpenOfferMaxBlank = AccountPricingTiersService.checkCriteriaForWarningMessageForNoADTData(localLine);
                            }

                        }
                        //DCP-28284 -> Fixed Bundle - Populating Start and End date for Service products
                        if((String.isNotBlank(li.ZzapPosnrHgLvl) && String.isNotBlank(localLine.Apttus_Config2__OptionId__c) && localline.Apttus_Config2__OptionId__r.Material_Class__c=='Services') || Test.isRunningTest() ){
                            // DCP-29847
                            localLine.Apttus_Config2__PricingStatus__c = PRICING_STATUS_PENDING;

                            //To Populate Start Date
                            String contractStartDate = li.ContractStart.subStringBetween('(',')');
                            Long longStartDate = Long.valueOf(contractStartDate);
                            Datetime strStartDate = Datetime.newInstance(longStartDate);
                            localLine.Apttus_Config2__StartDate__c = strStartDate.Date();

                            //To Populate End Date
                            String contractEndDate = li.ContractEnd.subStringBetween('(',')');
                            Long longEndDate = Long.valueOf(contractEndDate);
                            Datetime strEndDate = Datetime.newInstance(longEndDate);
                            localLine.Apttus_Config2__EndDate__c = strEndDate.Date();

                            //populate Billing frequency for Service Line Item of Fix Bundle
                            localLine.Apttus_Config2__BillingFrequency__c = internalPicklistToExternalPicklistQuote.get('Apttus_Config2__BillingFrequency__c').get(li.BillFreq);
                        }
                        //localLine.SAP_Net_Price__c = convertStringToNumber(li.ExtendedValue);
                        localLine.ERP_Line_Number__c = objRTPResponse.EvSalesDocument+'_'+li.SapItmNumber;
                        localLine.Global_Trade_Block__c = true;
                        if(localLine.Beadchip_Part_Number__c == null) { localLine.Beadchip_Name__c = null; } //DCP-30425
                        ilib_LogEvent.message('**003-Item detail-'+ localLine);
						//Added as part of DCP-25322
                        //String strLineItemJson = JSON.serializePretty(new LineItemWrapperValidate(localLine));
                        //localLine.Line_Item_Validate_Old__c = strLineItemJson;
                        // DCP-25189 : Dynamic creation of JSON field
                        Map<String,String> mapFieldValue = UtilsCollection.getMapofAPInameTOValue(localLine,setFieldAPI);

                        //DCP-28284 - adding fields in map which are not allowed to edit after validate cart in fix bundle scenario
                        if(String.isNotBlank(li.ZzapPosnrHgLvl) && String.isNotBlank(localLine.Apttus_Config2__OptionId__c) && localline.Apttus_Config2__OptionId__r.Material_Class__c=='Services'){
                            mapFieldValue.put('Apttus_Config2__BillingFrequency__c',localLine.Apttus_Config2__BillingFrequency__c);
                        }
                        // DCP-45742 : Added Serial number in line validate JSON for relocation Quote                        
                        updateMapWithSerialNumberValues(mapFieldValue, localLine);

                        String strLineItemJson = JSON.serializePretty(mapFieldValue);
                        localLine.Line_Item_Validate_Old__c = strLineItemJson;

                        RealtimePricingResponseDirectUC.updateSDDFromTotalDiscount(localLine);

                    }
                    showWarningForOpenOfferViolationMaterials(lstOfEligibleMaterialNumberForOocc);

                    showWarningForOpenOffer(boolDiffNgnOfSoldToAndUCAndSatisfiedCondForInfo, boolOpenOfferMaxBlank);

                }

                /*
                *****************************************************
                Loop to get beadchip values from response - DCP-30425
                *****************************************************
                */
                Map<String, String> mapConfigIdToPLIName = new Map<String,String>();
                if(objRTPResponse.NAVHDRTOCFGSREF != null && objRTPResponse.NAVHDRTOCFGSREF.results!=null && objRTPResponse.NAVHDRTOCFGSREF.results.size() >0){
                    ilib_LogEvent.message('objRTPResponse.NAVHDRTOCFGSREF-->'+ objRTPResponse.NAVHDRTOCFGSREF);
                    for(RealtimePricingResponse.LineRef liRef : objRTPResponse.NAVHDRTOCFGSREF.results){
                        mapConfigIdToPLIName.put(liRef.ConfigId,liRef.ZzapPosnr);
                    }
                }
                ilib_LogEvent.message('mapConfigIdToPLIName-->'+ mapConfigIdToPLIName);

                Map<String, String> mapConfigIdToInsTd = new Map<String, String>();
                if(!mapConfigIdToPLIName.isEmpty() && objRTPResponse.NAVHDRTOCFGSINST != null && objRTPResponse.NAVHDRTOCFGSINST.results!=null && objRTPResponse.NAVHDRTOCFGSINST.results.size() >0){
                    ilib_LogEvent.message('objRTPResponse.NAVHDRTOCFGSINST-->'+ objRTPResponse.NAVHDRTOCFGSINST);
                    for(RealtimePricingResponse.LineInst liInst :objRTPResponse.NAVHDRTOCFGSINST.results ){
                        mapConfigIdToInsTd.put(liInst.ConfigId, liInst.InstId);
                    }
                }
                ilib_LogEvent.message('mapConfigIdToInsTd-->'+ mapConfigIdToInsTd);
                //DCP-54311 - Beadchip name to be pulled in full
                    if(objRTPResponse.NAVITMTOTXT != null && objRTPResponse.NAVITMTOTXT.results!=null && objRTPResponse.NAVITMTOTXT.results.size() >0){
                        ilib_LogEvent.message('objRTPResponse.NAVITMTOTXT-->'+ objRTPResponse.NAVITMTOTXT);
                        setBeadchipName(objRTPResponse);
                    }

               /*
                *******************************************
                **Loop to get all LOGS from response**
                *******************************************
                */
                if (objRTPResponse.NAVHDRTOGTSLOGS != null)
                {
                    ilib_LogEvent.message('Inside Log Structure');
                    for (RealtimePricingResponse.LineLogs log : objRTPResponse.NAVHDRTOGTSLOGS.results)
                    {
                        Apttus_Config2__LineItem__c localLine = RealtimePricingRequestGenerator.lineNameToLineItem.get(log.ZzapPosnr);
                        ilib_LogEvent.message('***LOGSSSSS--> '+ log.ZzapPosnr);
                        if (String.isNotBlank(log.ZzapPosnr) && String.isNotBlank(log.QualStai))
                        {
                            if (log.CheckInd == CHECKIND_B)
                            {
                                if (Label.Quote_Embargo_Check.contains(log.QualStai)) // EMB1;EMB2;EMB3;EMB4;EMB5
                                {
                                    if(log.ItemNumber != null && lineNumberToMaterialName.containsKey(log.ItemNumber))
                                        ApttusCheckPriceController.lstFailedProducts.add(lineNumberToMaterialName.get(log.ItemNumber));
                                    localLine.Global_Trade_Block__c = false;
                                    ApttusCheckPriceBaseClass.boolEmbargoCheck = true;
                                    boolError = true;
                                }
                                if (Label.Quote_Sanctioned_Party_List_Screening.contains(log.QualStai)) // SPL1;SPL2;SPL3;SPL4;SPL5
                                {
                                    if(log.ItemNumber != null && lineNumberToMaterialName.containsKey(log.ItemNumber))
                                        ApttusCheckPriceController.lstFailedProducts.add(lineNumberToMaterialName.get(log.ItemNumber));
                                    localLine.Global_Trade_Block__c = false;
                                    ApttusCheckPriceBaseClass.boolSanctionedPartyListCheck = true;
                                    boolError = true;
                                }
                                if (Label.Quote_Legal_Control.contains(log.QualStai)) // CON2;CON3;CON4;CON4A;CON4B;CON4C;CON4D;CON4E
                                {
                                    if(log.ItemNumber != null && lineNumberToMaterialName.containsKey(log.ItemNumber))
                                        ApttusCheckPriceController.lstFailedProducts.add(lineNumberToMaterialName.get(log.ItemNumber));
                                    localLine.Global_Trade_Block__c = false;
                                    ApttusCheckPriceBaseClass.boolLegalControl = true;
                                    boolError = true;
                                }

                                // DCP-41818
                                if (log.QualStai == ZINCO)
                                {
                                    String lineNumber = log.ItemNumber;
                                    String failedMaterial = (lineNumberToMaterialName.containsKey(lineNumber) ? lineNumberToMaterialName.get(lineNumber) : '(One of the lines)');
                                    ApttusCheckPriceBaseClass.lstInstrumentCompliance.add(failedMaterial);
                                    ApttusCheckPriceController.lstFailedProducts.add(failedMaterial);
                                    localLine.Global_Trade_Block__c = false;
                                    boolError = true;
                                }
                                if (log.QualStai == ZMDLC)
                                {
                                    String lineNumber = log.ItemNumber;
                                    String failedMaterial = (lineNumberToMaterialName.containsKey(lineNumber) ? lineNumberToMaterialName.get(lineNumber) : '(One of the lines)');
                                    ApttusCheckPriceBaseClass.lstRegulatoryMedicalDevice.add(failedMaterial);
                                    ApttusCheckPriceController.lstFailedProducts.add(failedMaterial);
                                    localLine.Global_Trade_Block__c = false;
                                    boolError = true;
                                }
                            }
                        }
                    }
                }

                /*
                *******************************************
                **Loop to get all return logs from response**
                *******************************************
                */
                ApttusCheckPriceBaseClass.strRETErrors = '';
                if(objRTPResponse.NAVHDRTORET != null){
                    ilib_LogEvent.message('Inside Log Structure');
					String strWarningMessages ;
                    ApttusCheckPriceBaseClass.strRETErrors += '<ui>';
                    ApttusCheckPriceBaseClass.strWarningMsgs += '<ui>'; //DCP-49511 (To display wanring message for relocation/breakfix quotes)
                    for(RealtimePricingResponse.LineReturns ret : objRTPResponse.NAVHDRTORET.results){
                        if(ret.Type == 'E' || ret.Type == 'A'){
                            ApttusCheckPriceBaseClass.boolRETError = true;
                            ilib_LogEvent.message('ApttusCheckPriceBaseClass.strRETErrors ->'+ApttusCheckPriceBaseClass.strRETErrors);
                            ApttusCheckPriceBaseClass.strRETErrors +=  STRHTMLTAGLINESTART +ret.Message + STRHTMLTAGLINEEND;
                            boolError = true;
                            boolISQuoteUpdate = false;
                            ilib_LogEvent.message('ApttusCheckPriceBaseClass.strRETErrors ->'+ApttusCheckPriceBaseClass.strRETErrors);
                        }
                        else if(ret.Type == WARNING) //DCP-31081 Soft warning message
                        {
                            ApttusCheckPriceBaseClass.boolWarning = true;
                            strWarningMessages = ret.Message + '/n';
                            ApttusCheckPriceBaseClass.strWarningMsgs +=  STRHTMLTAGLINESTART +ret.Message + STRHTMLTAGLINEEND;
                            boolISQuoteUpdate = true;
                        }
                    }
                    ApttusCheckPriceBaseClass.strRETErrors += '</ui>';
                    ApttusCheckPriceBaseClass.strWarningMsgs += '</ui>';
                    objConfig.SAP_Errors__c = ApttusCheckPriceBaseClass.strRETErrors;
                    objConfig.SAP_Warnings__c = strWarningMessages;
                    ilib_LogEvent.message('Data Errors -- '+ ApttusCheckPriceBaseClass.strRETErrors);
                }

                // Getting Quote details and concatinating
                if(!setUniquePromos.isEmpty()){
                    List<Apttus_Config2__Incentive__c> lstIncentive = new ApttusIncentivesPromotionsSelector().getPromotions(setUniquePromos);
                    for(Apttus_Config2__Incentive__c inc : lstIncentive){
                        RealtimePricingRequestGenerator.promoCodeToIncentive.put(inc.Apttus_Config2__IncentiveCode__c,inc);
                    }
                }

               //Changes of DCP-53975
                //This will get all the promo codes from the configuration of the line items.
                if(!RealtimePricingRequestGenerator.lineNameToLineItem.isEmpty()){
                    
                    getAllConfigPromoCodes(RealtimePricingRequestGenerator.lineNameToLineItem.values()[0], setConfigAllPromoCode);
                    boolIsDirectUC = RealtimePricingRequestGenerator.lineNameToLineItem.values()[0].Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c; // Hper Care 0794448
                    ilib_LogEvent.message('### All Configuration Promo Codes ' + setConfigAllPromoCode);
                }
                //DCP-53975 Changes End Here.

                // Start of DCP-54361, This is done for deletion, in case if user removes all promos this will take care of it.
                if(boolIsDirectUC == false){

                    RealtimePricingRequestGenerator.objQuote.put('Applied_Promo_1__c',null);
                    RealtimePricingRequestGenerator.objQuote.put('Applied_Promo_2__c',null);
                    RealtimePricingRequestGenerator.objQuote.put('Applied_Promo_3__c',null);
                }
                // End of DCP-54361
                    
                    
                    List<Apttus_Config2__LineItem__c> localLinetemp = RealtimePricingRequestGenerator.lineNameToLineItem.values();
                    List<Apttus_Config2__LineItem__c> removeTradeintypeOnPromoRemoval = new List<Apttus_Config2__LineItem__c>();
                   
                    ilib_LogEvent.message('Line item List '+localLinetemp);
                    boolean msgFlag1=true;
                for(Apttus_Config2__LineItem__c localLineNew:localLinetemp){                       
                    if(localLineNew.Promotion_1__r.Marketing_Trade_In__c ==null && localLineNew.Promotion_2__r.Marketing_Trade_In__c ==null && localLineNew.Promotion_3__r.Marketing_Trade_In__c ==null &&(localLineNew.Trade_In_Type__c== MKTEXTERNAL || localLineNew.Trade_In_Type__c== MKTINTERNAL ) ){
                        localLineNew.Trade_In_Type__c = '';
                        if(msgFlag1){
                            ApttusCheckPriceBaseClass.boolWarning = true;
                            ApttusCheckPriceBaseClass.strWarningMsgs += STRHTMLTAGLINESTART + Label.Trade_In_Type_Remove_Info_message + STRHTMLTAGLINEEND;   
                            msgFlag1=false;
                        }
                    }                 
                 }
                 update removeTradeintypeOnPromoRemoval;
                  
                 boolean msgFlag=true;
                // Adding promo to respective lines
                for(String proLine : RealtimePricingRequestGenerator.lineNumberToAppliedPromos.keyset()){
                    Apttus_Config2__LineItem__c localLine = RealtimePricingRequestGenerator.lineNameToLineItem.get(proLine);
                    integer intCounter = 1;
                    boolean tempFlag=true;         //Added as part of CMCM-1482 to flag when Marketing Trade In promo code is added
                   
                    for(RealtimePricingRequestGenerator.AppliedPromo promo : RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)){
                        localLine.put('Promo_Channel_'+intCounter+CUSTOMFIELDSUFFIX,RealtimePricingRequestGenerator.promoCodeToIncentive.get(promo.promoCode).Promo_Channel__c);
                        localLine.put('Promo_Name_'+intCounter+CUSTOMFIELDSUFFIX,RealtimePricingRequestGenerator.promoCodeToIncentive.get(promo.promoCode).Apttus_Config2__Description__c);
                        localLine.put('Promo_Code_'+intCounter+CUSTOMFIELDSUFFIX,promo.promoCode);
                        localLine.put('Promotion_'+intCounter+CUSTOMFIELDSUFFIX,RealtimePricingRequestGenerator.promoCodeToIncentive.get(promo.promoCode).id);
                        
                    //Adding Logic as part of CMCM-1482
                        
                        ilib_LogEvent.message('Marketing Trade in is and is warning message displayed '+RealtimePricingRequestGenerator.promoCodeToIncentive.get(promo.promoCode).Marketing_Trade_In__c);
                    

                        if(RealtimePricingRequestGenerator.promoCodeToIncentive.get(promo.promoCode).Marketing_Trade_In__c==INTERNAL){
                            localLine.put('Trade_In_Type__c',MKTINTERNAL);
                            tempFlag=false;
                            if(msgFlag){
                            ApttusCheckPriceBaseClass.boolWarning = true;
                            ApttusCheckPriceBaseClass.strWarningMsgs += STRHTMLTAGLINESTART + Label.Trade_In_Type_Add_Info_message + STRHTMLTAGLINEEND;
                            msgFlag=false;   
                        } 
                    }
                         if(RealtimePricingRequestGenerator.promoCodeToIncentive.get(promo.promoCode).Marketing_Trade_In__c==EXTERNAL && tempFlag){
                            localLine.put('Trade_In_Type__c',MKTEXTERNAL);
                            if(msgFlag){
                            ApttusCheckPriceBaseClass.boolWarning = true;
                            ApttusCheckPriceBaseClass.strWarningMsgs += STRHTMLTAGLINESTART + Label.Trade_In_Type_Add_Info_message + STRHTMLTAGLINEEND;
                            msgFlag=false; 
                        }                      
                    }   
                        intCounter++;
                        //Removed the applied promo code from the configuration set
                        if(!setConfigAllPromoCode.isEmpty() && setConfigAllPromoCode.contains(promo.promoCode)){

                            setConfigAllPromoCode.remove(promo.promoCode);
                        }                     
                        }  
                        // Start of DCP-54361, this if is added to resolve a bug where 2 same promotion where coming on Quote.
                        if(boolIsDirectUC == false && RealtimePricingRequestGenerator.promoCodeToIncentive.get(RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)[0].promoCode).Master_Promotions__c != null && !appliedPromotionIdSet.contains(RealtimePricingRequestGenerator.promoCodeToIncentive.get(RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)[0].promoCode).Master_Promotions__c)){
                        
                        //Update the Quote Applied Promotion field
                        RealtimePricingRequestGenerator.objQuote.put('Applied_Promo_'+appliedPromoCnt+CUSTOMFIELDSUFFIX, RealtimePricingRequestGenerator.promoCodeToIncentive.get(RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)[0].promoCode).Master_Promotions__c);
                        appliedPromotionIdSet.add(RealtimePricingRequestGenerator.promoCodeToIncentive.get(RealtimePricingRequestGenerator.lineNumberToAppliedPromos.get(proLine)[0].promoCode).Master_Promotions__c);
                        appliedPromoCnt++;
                    }
                    // End of DCP-54361
                }
                //Changes of DCP-53975
                // This will be true when we have selected promo codes on configuration level 
                if(!setConfigAllPromoCode.isEmpty()  && boolIsDirectUC == false){

                    ilib_LogEvent.message('### Not Applied Promo Codes' + setConfigAllPromoCode);
                    //Convert the Set into a String
                    String strNotAppliedPromo = String.join(new List<String>( setConfigAllPromoCode), ', ' );
                    
                    //When we have promo codes which are not applied on line items this will give errors.

                    ApttusCheckPriceBaseClass.boolWarning = true;
                    ApttusCheckPriceBaseClass.strWarningMsgs += STRHTMLTAGLINESTART+LABEL.PromoNotAppliedInfoMessage.replace('{0}',strNotAppliedPromo) + STRHTMLTAGLINEEND;

                    ilib_LogEvent.message('### Warning Message' + ApttusCheckPriceBaseClass.strWarningMsgs);   
                }
                //DCP-53975 Changes End Here.
                
            }

            if(boolISQuoteUpdate){
                update RealtimePricingRequestGenerator.lineNameToLineItem.values(); //DCP-34910
                objConfig.Apttus_Config2__IsPricePending__c = true;
                objConfig.Is_SAP_Pricing_Completed__c = true;
                objConfig.Number_Of_Check_Line_Items__c = RealtimePricingRequestGenerator.intNumberOfLineItems;
                update objConfig;
                update RealtimePricingRequestGenerator.objQuote;
                ilib_LogEvent.message('Final if if if -->'+RealtimePricingRequestGenerator.lineNameToLineItem.values());
            }
            else{
                objConfig.Number_Of_Check_Line_Items__c = RealtimePricingRequestGenerator.intNumberOfLineItems;
                update objConfig;
                update RealtimePricingRequestGenerator.objQuote;
            }
        }

        ilib_LogEvent.pop();
        return boolError;
    }


    /**
    *  @author Roopal Verma
    *  @Set beadchip name on the cart DCP-30425
    *  @param RealtimePricingResponse, Map<Config Id, Proposal Line Item Id>, Map<Config Id, Instance Id>
    **/
    public static void setBeadchipName(RealtimePricingResponse objRTPResponse){
        //DCP-54311 - Beadchip name to be pulled in full
        for(RealtimePricingResponse.LineBeadchip libeadchip : objRTPResponse.NAVITMTOTXT.results){
            ilib_LogEvent.message('libeadchip-->'+libeadchip);
            if(String.isNotBlank(libeadchip.TextId) && libeadchip.TextId == ZBDD){
                Apttus_Config2__LineItem__c localLine = RealtimePricingRequestGenerator.lineNameToLineItem.get(libeadchip.ZzapPosnr);
                ilib_LogEvent.message('localLine-->'+localLine);
                if(localLine.Beadchip_Part_Number__c != null){
                    localLine.Beadchip_Name__c = libeadchip.TextLine;
                }
            }
        }
    }

    /**
    *  @author Adyasha
    *  @param Map<String,String> mapFieldValue
    *  @param Apttus_Config2__LineItem__c localLine
    **/
    public static void updateMapWithSerialNumberValues(Map<String,String> mapFieldValue, Apttus_Config2__LineItem__c objLineItem) {
        // DCP-45742 : Added Serial number in line validate JSON for relocation Quote
        //INC0340943: Added check for product interest to avoid null pointer
        if(String.isNotBlank(objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c) && objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c.contains(Label.OpportunityProductInterestRelocation)) {
            mapFieldValue.put('Serial_Number__c',objLineItem.Serial_Number__c);
        }
    }
    /**
    *  @author Himanshu
    *  @description To check for open offer warning message when validating the cart.
    *  @param Apttus_Config2__LineItem__c localLine , List<String> lstOfEligibleMaterialNumberForOocc
    **/
    public static void checkCriteriaForWarningMessageForOpenOffer (Apttus_Config2__LineItem__c localLine,List<String> lstOfEligibleMaterialNumberForOocc ) {
        Boolean  boolAppliedDiscountGreaterThanOpenOfferMax = localLine.Applied_Discount_Percentage__c > localLine.Open_Offer_Max__c;
        String strCombinationForList = localLine.Apttus_Config2__ProductId__r.Material_Number__c + ' - ' +localLine.Apttus_Config2__ProductId__r.Name;
        Boolean boolQuoteIsOpenOffer=localLine.Apttus_Config2__ProductId__r.Open_Offer_Product_Category__c!=null && localLine.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Quote_For_Open_Offer_Customer__c;
        if(boolAppliedDiscountGreaterThanOpenOfferMax && boolQuoteIsOpenOffer && !lstOfEligibleMaterialNumberForOocc.contains(strCombinationForList)) {
             ApttusCheckPriceBaseClass.boolWarning = true;
             lstOfEligibleMaterialNumberForOocc.add(strCombinationForList);
          
         }
     }
     /**
     *  @author Himanshu
     *  @description To check whether the list for open offer warning message is empty or not.
     *  @param List<String> lstOfEligibleMaterialNumberForOocc
     **/
     public static void showWarningForOpenOfferViolationMaterials (List<String> lstOfEligibleMaterialNumberForOocc) {
         if(!lstOfEligibleMaterialNumberForOocc.isEmpty()) { 
             ApttusCheckPriceBaseClass.strWarningMsgs +=  STRHTMLTAGLINESTART + Label.UI_Text_Warning_Message_For_Oocc + String.join(lstOfEligibleMaterialNumberForOocc, '<br/>') + STRHTMLTAGLINEEND;
         }
     }
     /**  @author Himanshu
     *  @description To check whether the boolean for ngn having different ngn is empty or not.
     *  @param boolean boolDiffNgnOfSoldToAndUCAndSatisfiedCondForInfo
     **/
    public static void showWarningForOpenOffer (boolean boolDiffNgnOfSoldToAndUCAndSatisfiedCondForInfo, boolean boolOpenOfferMaxBlank) {
        if(boolDiffNgnOfSoldToAndUCAndSatisfiedCondForInfo) { 
            ApttusCheckPriceBaseClass.boolWarning = true;
            ApttusCheckPriceBaseClass.strWarningMsgs +=  STRHTMLTAGLINESTART + Label.UI_Text_Warning_Message_For_Oocc_With_Diff_Ngn_Of_SoldTo_And_Uc + STRHTMLTAGLINEEND;
        }
        else if(boolOpenOfferMaxBlank)
        {
            ApttusCheckPriceBaseClass.boolWarning = true;
            ApttusCheckPriceBaseClass.strWarningMsgs +=  STRHTMLTAGLINESTART + Label.UI_Text_Warning_Message_For_Oocc_With_Diff_Erp_Of_SoldTo_And_Uc + STRHTMLTAGLINEEND;
        }
    }
     /**
    *  @author Jitesh Lakhwani as part of DCP-53975
    *  @description This method will return ALL promo codes of the configuration.
    *  @param Apttus_Config2__LineItem__c localLine
    **/
    public static void getAllConfigPromoCodes(Apttus_Config2__LineItem__c lineItem, Set<String> setAllPromoCode){
       
        if(!setAllPromoCode.contains(lineItem.Apttus_Config2__ConfigurationId__r.Promo_Name_1__c) && 
           String.isNotBlank(lineItem.Apttus_Config2__ConfigurationId__r.Promo_Name_1__c)){

            setAllPromoCode.add(lineItem.Apttus_Config2__ConfigurationId__r.Promo_Name_1__c);
        }
        if(!setAllPromoCode.contains(lineItem.Apttus_Config2__ConfigurationId__r.Promo_Name_2__c) && 
           String.isNotBlank(lineItem.Apttus_Config2__ConfigurationId__r.Promo_Name_2__c)){

            setAllPromoCode.add(lineItem.Apttus_Config2__ConfigurationId__r.Promo_Name_2__c);
        }
        if(!setAllPromoCode.contains(lineItem.Apttus_Config2__ConfigurationId__r.Promo_Name_3__c) && 
           String.isNotBlank(lineItem.Apttus_Config2__ConfigurationId__r.Promo_Name_3__c)){

            setAllPromoCode.add(lineItem.Apttus_Config2__ConfigurationId__r.Promo_Name_3__c);
        }
    }
}
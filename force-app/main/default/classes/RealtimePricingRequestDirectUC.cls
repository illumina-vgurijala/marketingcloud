/*
 * @Author: Kushagra Desai
 * @Date: 2018-12-29
 * @Description : Wrapper class to send RTP request to SAP.
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                        Description
 * Kushagra Desai       27-Mar-2019                   Passing YCO1 from Check Price during validate[DCP-24500]
 * Saswati Prusty          6-6-2019                   DCP-25191
 * Roopal Verma          08-06-2019                   DCP-25340, promotion approval regression fix
 * Arnab Modak         25-Sept-2019                   DCP-29847 RTP Changes for FixedCombination Scenario
 * Govind/Arnab         02-Dec-2019                   INC0241210 - CHange in RTP Logic for Fixed Combination to accomodate more than 2 options
 * Joshith K            03-Dec-2019                   INC0238317- changed createJSON signature and passing Line items as separate variable
 * Arnab Modak          21-Mar-2020                   DCP-34013 - Code Refactor, changes ApttusCheckPriceDirectUCController reference to ApttusCheckPriceBaseClass
 * Arnab Modak          01-Apr-2020                   SonarCube Issue Fix
 * Prem Ranjan        25-April-2022                   CodeScan Fix:Avoid Literals in If condition
 * Himanshu             30-Mar-2022                   Code Scan Fixes
 * Bharath Varma        27-Apr-2022                   INC0388495 - Updated logic to populate QtValidF and QtValidT
 * Bharath Varma        08-Jun-2022                   TASK0768041 - Used a boolean insted of checking start date == null, end date == nulll
 * ---------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class RealtimePricingRequestDirectUC {

    //SonarCube
    public static final String LINE_TYPE_PRODUCT_SERVICE = 'Product/Service';
    private static final String CONFIG_TYPE_BUNDLE = 'Bundle';
    public static final Integer ONE = 1;
    public static final Integer TWO = 2;
    public static final Integer TEN = 10;
    //INC0388495
    public static final String PROPOSALAPI = 'Apttus_QPConfig__Proposald__r';
    /**
     * @author  Kushagra Desai
     * @date   2018-12-29
     * @description wrapperclass to send RTP request to SAP.
    **/

    public class RealtimePricingRequestDirectUCWrapper {

        public String DistrChan;
        public String Division;
        public String DocType = 'ZQT';
        public String PriceDate;
        public String PriceList;
        public String QtValidF;
        public String QtValidT;
        public String SalesOrg;
        public String PoMethod = 'SFDC';


        public List<SalesPartner> NAVHTOSALESPARTNER = new List<SalesPartner>();
        public List<Condition> NAVHTOCONDITIONSIN = new List<Condition>();
        public List<Promotion> NAVHTOEXPLICITHDR = new List<Promotion>();
        public List<Schedule> NAVHTOSCHDULEIN = new List<Schedule>();
        public List<LineItem> NAVHTOITEMIN = new List<LineItem>();
        public List<Object> NAVHTOEXPORT = new List<Object>();
        public List<Object> NAVHTOITEMEX = new List<Object>();
        public List<Object> NAVHTOITEMPRICE = new List<Object>();
        public List<Object> NAVHTOITEMSCOND = new List<Object>();
        public List<Object> NAVHTORETURN = new List<Object>();
        public List<Object> NAVHTOSALESOUT = new List<Object>();
        public List<Object> NAVHTOCONDITIONSEX = new List<Object>();
        public List<ExplictLineItem> NAVHTOEXPLICITITM = new List<ExplictLineItem>();
    }
    /**
     * @author  Kushagra Desai
     * @date   2018-12-29
     * @description @description wrapper inside wrapper to send RTP request to SAP(fix code scan).
    **/
    public class ExplictLineItem{
        public string ItmNumber;
        public string ZzapPosnr;
        public string ContractStart;
        public string ContractEnd;
        public string BillFreq;
        public String ZzapPosnrHgLvl; //DCP-29847 : Sending Fixed Bundle SKU LineItem Number on Component LineItems

    }
    /**
     * @author  Kushagra Desai
     * @date   2018-12-29
     * @description @description wrapper inside wrapper to send RTP request to SAP(fix code scan).
    **/
    public class SalesPartner{
        public String PartnRole;
        public String PartnNumb;
    }
    /**
     * @author  Kushagra Desai
     * @date   2018-12-29
     * @description @description wrapper inside wrapper to send RTP request to SAP(fix code scan).
    **/
    public class Condition{
        public String ItmNumber;
        public String CondType;
        public String CondValue;
        public String Calctypcon;
    }
    /**
     * @author  Kushagra Desai
     * @date   2018-12-29
     * @description wrapper inside wrapper to send RTP request to SAP(fix code scan).
    **/
    public class Promotion{
        public string ZzapQuot;
        public String ZzpromoChannel1;
        public String ZzpromoCode1;
        public String ZzpromoChannel2;
        public String ZzpromoCode2;
        public String ZzpromoChannel3;
        public String ZzpromoCode3;
        public String ApttusCall;
    }
    /**
     * @author  Kushagra Desai
     * @date   2018-12-29
     * @description wrapper inside wrapper to send RTP request to SAP(fix code scan).
    **/
    public class LineItem{
        public String ItmNumber;
        public String Material;
        public String TargetQu = 'EA';
    }
    /**
     * @author  Kushagra Desai
     * @date   2018-12-29
     * @description wrapper inside wrapper to send RTP request to SAP(fix code scan).
    **/
    public class Schedule{
        public String ItmNumber;
        public String ReqQty;
    }
    /**
     * @author  Kushagra Desai
     * @date   2018-12-29
     * @description wrapper inside wrapper to send RTP request to SAP(fix code scan).
    **/
    public class PromotionWrapper {
        public string PromoCode;
        public string PromoChannel;
    }

    public static long DATENOW = Datetime.now().getTime();
    private static List<PromotionWrapper> lstPromoWrapper;
    public static Apttus_Proposal__Proposal__c objQuote;
    public static Map<String,Apttus_Config2__LineItem__c> lineNameToLineItem = new Map<String,Apttus_Config2__LineItem__c>();
    public static Map<String,Apttus_Config2__Incentive__c> promoCodeToIncentive = new Map<String,Apttus_Config2__Incentive__c>();
    public static Map<String,String> sapItemToLineItem = new Map<String,String>();
    public static Map<String,Apttus_Config2__PriceListItem__c> lineItemToPriceList = new Map<String,Apttus_Config2__PriceListItem__c>();
    /**
     * @author  Kushagra Desai
     * @description method to create json that is to be sent to SAP
     * @param Apttus_Config2__ProductConfiguration__c objConfig, List<Apttus_Config2__LineItem__c> lstLineItems
     * @return string
    **/
    public static string createJSONForDirectUC(Apttus_Config2__ProductConfiguration__c objConfig, List<Apttus_Config2__LineItem__c> lstLineItems)
    {
        ilib_LogEvent.push('createJSONForDirectUC');

        RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper rtpRequest = new RealtimePricingRequestDirectUC.RealtimePricingRequestDirectUCWrapper();
        ilib_LogEvent.message('Quote number--'+objConfig.Apttus_QPConfig__Proposald__r);
        objQuote = objConfig.Apttus_QPConfig__Proposald__r;
        rtpRequest.SalesOrg = (String) objQuote.Sold_to_Sales_Organization__c;
        rtpRequest.DistrChan = '02';
        rtpRequest.Division = (String) objQuote.Sold_to_Division__c;
        // INC0388495 - Update the QtValidF and QtValifT when either both are populated or when both are NOT populated
        // TASK0768041 - Added booleans instead of null checking multiple times
        Boolean startDateIsNull = objQuote.Apttus_Proposal__ExpectedStartDate__c == null;
        Boolean endDateIsNull = objQuote.Apttus_Proposal__ExpectedEndDate__c == null;
        if((startDateIsNull && endDateIsNull) || (!startDateIsNull && !endDateIsNull)){
            rtpRequest.QtValidT = RealtimePricingRequestGenerator.generateSAPDate('Apttus_Proposal__ExpectedEndDate__c',PROPOSALAPI,objConfig);
            rtpRequest.QtValidF = RealtimePricingRequestGenerator.generateSAPDate('Apttus_Proposal__ExpectedStartDate__c',PROPOSALAPI,objConfig);
        }
        else{
            // INC0388495 - If only one of them is populated, then both WtValidTand QtValidF will have the same value
            if(startDateIsNull){
                rtpRequest.QtValidT = RealtimePricingRequestGenerator.generateSAPDate('Apttus_Proposal__ExpectedEndDate__c',PROPOSALAPI,objConfig);
                rtpRequest.QtValidF = rtpRequest.QtValidT;
            }
            if(endDateIsNull){
                rtpRequest.QtValidF = RealtimePricingRequestGenerator.generateSAPDate('Apttus_Proposal__ExpectedStartDate__c',PROPOSALAPI,objConfig);
                rtpRequest.QtValidT = rtpRequest.QtValidF;
            }
        }
        // ilib_LogEvent.message('*****ApttusGenerateQuoteController.objQuote.Apttus_QPConfig__PriceListId__c--'+ApttusGenerateQuoteController.objQuote.Apttus_QPConfig__PriceListId__c);

        List<Apttus_Config2__PriceList__c> objPlist = new ApttusPriceListsSelector().selectById(new Set<Id>{(String)objQuote.Apttus_QPConfig__PriceListId__c});
        if(!objPlist.isEmpty()){
            rtpRequest.PriceList = objPlist[0].name.substring(0,2);
        }
        rtpRequest.PriceDate = RealtimePricingRequestGenerator.generateSAPDate('Apttus_QPConfig__PricingDate__c',PROPOSALAPI,objConfig);

        // Partner Structure
        Map<String, String> roleToPartnerField = new Map<String, String> {
            'SP' => 'Distributor_ERP_Number__c'
        };
        for(String strRole: roleToPartnerField.keySet()){
            RealtimePricingRequestDirectUC.SalesPartner objPartner = new RealtimePricingRequestDirectUC.SalesPartner();
            String strPartner = roleToPartnerField.get(strRole);
            objPartner.PartnRole = strRole;
            Object objPartnerNumber = objConfig.getSobject(PROPOSALAPI).get(strPartner);
            objPartner.PartnNumb = (objPartnerNumber == null ? null : String.valueOf(objPartnerNumber));
            if(String.isNotBlank(objPartner.PartnNumb)) { rtpRequest.NAVHTOSALESPARTNER.add(objPartner); }
        }

        if(String.isNotBlank(objConfig.Promotion_JSON__c)){
            lstPromoWrapper = (List<PromotionWrapper>) System.JSON.deserialize(objConfig.Promotion_JSON__c, List<PromotionWrapper>.class);
            ilib_LogEvent.message('Applied promos :'+ lstPromoWrapper);
            RealtimePricingRequestDirectUC.Promotion appliedPromo = new RealtimePricingRequestDirectUC.Promotion();
            for (Integer idx = 0; idx < lstPromoWrapper.size(); idx++){
                if(idx==0){
                    appliedPromo.ZzpromoCode1 = lstPromoWrapper[0].PromoCode;
                    appliedPromo.ZzpromoChannel1 = lstPromoWrapper[0].PromoChannel;
                }
                else if(idx== ONE){
                    appliedPromo.ZzpromoCode2 = lstPromoWrapper[1].PromoCode;
                    appliedPromo.ZzpromoChannel2 = lstPromoWrapper[1].PromoChannel;
                }
                else if(idx== TWO){
                    appliedPromo.ZzpromoCode3 = lstPromoWrapper[2].PromoCode;
                    appliedPromo.ZzpromoChannel3 = lstPromoWrapper[2].PromoChannel;
                }
            }
            appliedPromo.ZzapQuot = objQuote.Name;
            appliedPromo.ApttusCall = 'X';
            rtpRequest.NAVHTOEXPLICITHDR.add(appliedPromo);
        }
        else{
            RealtimePricingRequestDirectUC.Promotion appliedPromo = new RealtimePricingRequestDirectUC.Promotion();
            appliedPromo.ZzapQuot = objQuote.Name;
            appliedPromo.ApttusCall = 'X';
            rtpRequest.NAVHTOEXPLICITHDR.add(appliedPromo);
        }

        // Lime item structure
        Integer intSAPItmnumber = 0;
        Boolean boolFixedOption = false;
        Integer intNumberOfProduct = 0;
        Integer intNumberOfOption = 0;
        Integer intInitialSAPNumber = 10;
        Map<String,Map<String,string>> internalPicklistToExternalPicklist =  utilsSettings.getCustomMetadataPicklistMap('Apttus_Config2__LineItem__c','ERP',true);
        //DCP-29847 - To Store FixedBundleSKU LI Number on Components
        Map<Decimal,String> lineItemNumberToName = new Map<Decimal,String>();

        for (Apttus_Config2__LineItem__c objCartLine : lstLineItems)
        {
            //DCP-29847 and INC0241210
            //FixedCombination Bundle Check
            if(objCartLine.Apttus_Config2__OptionId__c == null && objCartLine.Apttus_Config2__ProductId__r.Material_Class_Type__c == Label.FixedBundleMatClassType){
                lineItemNumberToName.put(objCartLine.Apttus_Config2__LineNumber__c,objCartLine.Name);
                intNumberOfProduct++;
                intSAPItmnumber = intInitialSAPNumber*intNumberOfProduct;
            }

            //Fixed Combination Components check
            else if(objCartLine.Apttus_Config2__OptionId__c != null && objCartLine.Apttus_Config2__ProductId__r.Material_Class_Type__c == Label.FixedBundleMatClassType){
                intSAPItmnumber++;
                boolFixedOption = true;
            }

            //Any line item other than FixedCombination Bundle or Component
            else if (objCartLine.Apttus_Config2__ProductId__r.Material_Class_Type__c != Label.FixedBundleMatClassType){
                intNumberOfProduct++;
                intSAPItmnumber = intInitialSAPNumber*intNumberOfProduct;
            }

            objCartLine.Promotion_1__c = null;
            objCartLine.Promotion_2__c = null;
            objCartLine.Promotion_3__c = null;
            objCartLine.Promotion_4__c = null;
            objCartLine.Promotion_5__c = null;

            ilib_LogEvent.message('----- Final sapItemToLineItem---');
            sapItemToLineItem.put(String.valueof(intSAPItmnumber),objCartLine.name);

            objCartLine.Applied_Discount_Details__c = '';
        	lineNameToLineItem.put(objCartLine.name,objCartLine);
        	RealtimePricingRequestDirectUC.LineItem objLine = new RealtimePricingRequestDirectUC.LineItem();
        	objLine.Material = (objCartLine.Apttus_Config2__OptionId__c != null ? objCartLine.Apttus_Config2__OptionId__r.ProductCode : objCartLine.Apttus_Config2__ProductId__r.ProductCode);
            objLine.ItmNumber = String.valueof(intSAPItmnumber);

            //objLine.TargetQu = String.valueOf(objCartLine.Apttus_Config2__Quantity__c.intValue());
            Product2 objProduct = (objCartLine.Apttus_Config2__OptionId__c != null ? objCartLine.Apttus_Config2__OptionId__r : objCartLine.Apttus_Config2__ProductId__r);
            if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE)){
                rtpRequest.NAVHTOITEMIN.add(objLine);
            }
            //DCP-29847
            if(objProduct.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE && objProduct.Material_Class_Type__c == Label.FixedBundleMatClassType){ rtpRequest.NAVHTOITEMIN.add(objLine); }
            RealtimePricingRequestDirectUC.ExplictLineItem objExpLine = new RealtimePricingRequestDirectUC.ExplictLineItem();
            objExpLine.ItmNumber = String.valueof(intSAPItmnumber);
            objExpLine.ZzapPosnr = objCartLine.name;

            //Added for DCP-29847 - Sending FixedBundleSKU LI Number on Components
            objExpLine.ZzapPosnrHgLvl = objCartLine.Apttus_Config2__OptionId__c != null? lineItemNumberToName.get(objCartLine.Apttus_Config2__LineNumber__c): null;
            Datetime dtStartDate = (Datetime)objCartLine.Apttus_Config2__StartDate__c;
            String strStartDate = '\\'+'/Date(' + String.valueOf((dtStartDate == null ? DATENOW : dtStartDate.getTime())) + ')'+'\\'+'/';
            objExpLine.ContractStart = strStartDate;
            Datetime dtEndDate = (Datetime)objCartLine.Apttus_Config2__EndDate__c;
            String strEndDate = '\\'+'/Date(' + String.valueOf((dtEndDate == null ? DATENOW : dtEndDate.getTime())) + ')'+'\\'+'/';
            objExpLine.ContractEnd = strEndDate;
            objExpLine.BillFreq = internalPicklistToExternalPicklist.get('Apttus_Config2__BillingFrequency__c').get(objCartLine.Apttus_Config2__BillingFrequency__c);

            //added to skip Sku product
            if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE)){
                rtpRequest.NAVHTOEXPLICITITM.add(objExpLine);
            }

            //DCP-29847 - To include FixedCombination SKU
            if((objProduct.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE && objProduct.Material_Class_Type__c==Label.FixedBundleMatClassType)){ rtpRequest.NAVHTOEXPLICITITM.add(objExpLine); }

            RealtimePricingRequestDirectUC.Condition objLineCondition = new RealtimePricingRequestDirectUC.Condition();
            objLineCondition.CondType = 'YD04';
            objLineCondition.ItmNumber = String.valueof(intSAPItmnumber);

            objLineCondition.CondValue = String.valueOf(objCartLine.Sales_Discretionary_Discount__c);
            ilib_LogEvent.message('***Apttus_Config2__AdjustmentType__c'+objCartLine.Sales_Discretionary_Type__c);
            objLineCondition.Calctypcon = (objCartLine.Sales_Discretionary_Type__c == 'Discount Amount') ? 'N':'A';

            // condition added to skip Sku product
            if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE)){
                if(String.isNotBlank(objLineCondition.CondValue))
                    rtpRequest.NAVHTOCONDITIONSIN.add(objLineCondition);
            }

            //DCP-29847 - To include FixedCombination SKU
            if((objProduct.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE && objProduct.Material_Class_Type__c==Label.FixedBundleMatClassType)){
                if(String.isNotBlank(objLineCondition.CondValue)) { rtpRequest.NAVHTOCONDITIONSIN.add(objLineCondition); }
            }

            //DCP-24500
            // condition added to skip Sku product
            if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE) && (String.isNotBlank(String.valueOf(objCartLine.Price_Override__c))||ApttusCheckPriceBaseClass.boolConsortia))
            {
                RealtimePricingRequestDirectUC.Condition objLineCondition3 = new RealtimePricingRequestDirectUC.Condition();
                objLineCondition3.ItmNumber = String.valueof(intSAPItmnumber);

                //objLineCondition3.ItmNumber = String.valueof(intSAPItmnumber);
                objLineCondition3.CondType = 'YCO1';
                //DCP-25191 : For Direct Sale To UC Consortia Flow.
                objLineCondition3.CondValue = ApttusCheckPriceBaseClass.boolConsortia ? String.valueOf(objCartLine.Unit_Price__c) : String.valueOf(objCartLine.Price_Override__c);
                objLineCondition3.Calctypcon = 'N';
                rtpRequest.NAVHTOCONDITIONSIN.add(objLineCondition3);
            }
            RealtimePricingRequestDirectUC.Schedule objLineSchedule = new RealtimePricingRequestDirectUC.Schedule();
            objLineSchedule.ReqQty = String.valueOf(objCartLine.Apttus_Config2__Quantity__c);
            objLineSchedule.ItmNumber = String.valueof(intSAPItmnumber);

            rtpRequest.NAVHTOSCHDULEIN.add(objLineSchedule);

            //DCP-29847 and INC0241210
            if(boolFixedOption)
            {
                boolFixedOption = false;
                intNumberOfOption++;
                if(intNumberOfOption== TEN){
                    intNumberOfProduct++;
                    intNumberOfOption = 0;
                }
            }
            else{
                intNumberOfOption = 0;
            }
        }

        String  pretty = JSON.serialize(rtpRequest);
        pretty = pretty.replace('null','""');
        ilib_LogEvent.message('@@@RTP- '+pretty);

        ilib_LogEvent.pop();
        return pretty;
    }

}
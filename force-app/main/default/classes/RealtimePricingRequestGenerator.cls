/*
 * @Author: Kushagra Desai
 * @Date: 2018-11-07
 * @Description : Generator class to create request JSON
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                        Description
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Indra Ganesan        04-DEC-2018                   Modified - Added Condition YCO1 to send Price Override
 * Kushagra Desai       25-JAN-2019                   Direct Sales To UC changes and Consortia
 * Kushagra Desai       18-Mar-2019                   Removal of special character from consortia name(INC0197802)
 * Kushagra Desai       27-Mar-2019                   Passing YCO1 from Check Price during validate[DCP-24500]
 * Akshay Mohan         15-May-2019                   DCP-25194 Add PPM
 * Roopal Verma         29-May-2019                   DCP-25322, Manual Rebate
 * Kushagra Desai       30-May-2019                   DCP-25190 : Demo program
 * Kushagra Desai       10-June-2019                  DCP-25321 : Customer premium can be Zero
 * Arnab Modak          23-Aug-2019                   DCP-28284 : To send FixedBundleSKU along with components
 * Govind Dubey         24-Oct-2019                   Commented Project Id logic for INC0227087
 * Joshith K            03-Dec-2019                   INC0238317- changed createJSON signature and passing Line items as separate variable
 * Rahul Bishnoi        13-Jan-2020                   DCP-32794 Removed Software Id
 * Arnab Modak          21-Mar-2020                   DCP-34013 - Code Refactor, changes ApttusCheckPriceController reference to ApttusCheckPriceBaseClass
 * Arnab Modak          01-Apr-2020                   SonarCube Issues
 * Rishab Wali          18-May-2020                   DCP-34910 Manage Large Carts
 * Bharath Varma        03-Dec-2020                   DCP-43354 Added additional logic to send Program Type to SAP
 * Rishab Wali          25-Nov-2020                   DCP-23566 Send Discount in YD04 while Validate Cart
 * Rishab Wali          12-Jan-2021                   DCP-45251 - Beadchip Soft Warning and Consortia Product Enhancement
 * Adyasha Satapathy    12-May-2021                   DCP-46872 : Added logic to send Product Interest and Work Order to SAP
 * KD                   24-May-2021                   DCP-46276 : Added logic to send multiple serial number (,) seperated
 * KD                   2021-06-27                    DCP-46257 : Added new partner function Inventory Location
 * Anand Palla          26-Apr-2022                   CodeScan Fix-Avoid Literals in If condition
 * Aman Tyagi            31-March-2022                Codescan Fixes
 * Iram Malik             14-Jul-2022                 Codescan Fixes
 * Saddam                 08-Dec-2022                 Codescan Fix , Varaible naming convention. 

*/

public with sharing class RealtimePricingRequestGenerator {

    public static final String CODEPARAMETERNAME = 'Real_Time_Pricing_Threshold_Value'; //DCP-34910
    private static List<PromotionWrapper> lstPromoWrapper;
    public static Integer intNumberOfLineItems;
    private static final String  CONFIG_TYPE_BUNDLE = 'Bundle';
    public static Apttus_Proposal__Proposal__c objQuote;
    public static Map<String,Apttus_Config2__LineItem__c> lineNameToLineItem = new Map<String,Apttus_Config2__LineItem__c>();
    public static Map<String,List<AppliedPromo>> lineNumberToAppliedPromos = new Map<String,List<AppliedPromo>>();
    public static Map<String,Apttus_Config2__Incentive__c> promoCodeToIncentive = new Map<String,Apttus_Config2__Incentive__c>();
    public static long dateNow = Datetime.now().getTime();
    private static FINAL string DUMMYPARTNER = '31739';
    private static FINAL string PROPOSALAPI = 'Apttus_QPConfig__Proposald__r';
    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    private static final Integer INTEGER_TWO = 2;
    private static final String STRING_SE = 'SE';
    //End CodeScan Fix

    public static Map<String,String> mapProductInterestToSAPValue = new Map<String,String>{
        Label.OpportunityProductInterestBreakFix => 'ZBS1',
        Label.OpportunityProductInterestOtherServices => 'ZBS2',
        Label.OpportunityProductInterestRelocation => 'ZBS3' 
    }; //DCP-46872

    //SonarCube
    public static final String LINE_TYPE_PRODUCT_SERVICE = 'Product/Service';
    
    /*
    * @Author: Kushagra Desai 
    * @Description :wrapper class Applied Promo
    */
    public class AppliedPromo {
        public string promoCode;
        public string conditionType;
    }

    /**
    *  @author      : Kushagra Desai
    *  @description : wrapper class for Storing promotion selected by user
    *  @param       : NA
    *  @return      : NA
    **/
    public class PromotionWrapper {
        public string PromoCode;
        public string PromoChannel;
    }

    /*
    * @Author: Kushagra Desai 
    * @Description : method to generate the SAP date
    * @param :String dtVar,String objName, Sobject objConfig
    * @return :String
    */
    public static String generateSAPDate(String dtVar,String objName, Sobject objConfig)
    {
        Datetime dtDate = (Datetime)objConfig.getSobject(objName).get(dtVar);
        String strDate = '\\'+'/Date(' + String.valueOf((dtDate == null ? dateNow : dtDate.getTime())) + ')'+'\\'+'/';
        return strDate;
    }

    /**
     * @author Kushagra Desai
     * @Description Generator class to create request JSON
     * @param Sobject Apttus_Config2__ProductConfiguration__c
     * @return JSON string
     **/
    public static String createJSON(Apttus_Config2__ProductConfiguration__c objConfig, List<Apttus_Config2__LineItem__c> lstLineItems)
    {
        ilib_LogEvent.push('createJSON');

        CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
        List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
        RealtimePricingRequest rtpRequest = new RealtimePricingRequest();

        //DCP-34910 Add Line in Request (Text Line and Text Id - ZLQT)
        RealtimePricingRequest.Line objTextLineAsync  = new RealtimePricingRequest.Line();
        objTextLineAsync.TextId = 'ZLQT';
        objTextLineAsync.TextLine = '';
        if(lstLineItems.size() > Integer.valueOf(objCodeParam[0].Value__c))
        {
            objTextLineAsync.TextLine = 'X|'+objConfig.Validation_Number__c+'-'+objConfig.Id+'*'+objConfig.Apttus_QPConfig__Proposald__c+'|validate';
        }
        rtpRequest.NAVHDRTOTXT.add(objTextLineAsync);

        intNumberOfLineItems = 0;
        ilib_LogEvent.message('Quote number--'+objConfig.Apttus_QPConfig__Proposald__r);
        objQuote = objConfig.Apttus_QPConfig__Proposald__r;
        Map<String,Map<String,string>> internalPicklistToExternalPicklistQuote =  utilsSettings.getCustomMetadataPicklistMap('Apttus_Proposal__Proposal__c','ERP',true);
        //String ZzapQuot = (String) objConfig.getSobject('Apttus_QPConfig__Proposald__r').get('Name');
        String ZzapQuot = objQuote.Name;
        Map<String,String> mapOfStage = new Map<String,string>{
                Label.QuoteStageDraft => 'Initial',
                Label.QuoteStageInReview => 'Pending',
                Label.QuotationApprovalStatusApproved => 'Approved',
                Label.QuoteStageGenerated => 'Approved',
                Label.QuoteStageApprovalRequired => 'Initial',
                Label.QuoteStagePresented => 'Approved'
        };

        if(objQuote.SAP_quote__c == null){
            rtpRequest.Vbeln = '';
        }
        else{
            rtpRequest.Vbeln = (String) objQuote.SAP_quote__c;
        }

        rtpRequest.SalesOrg = (String) objQuote.Sold_to_Sales_Organization__c;
        rtpRequest.DistrChan = objQuote.Direct_Sale_to_Ultimate_Consignee__c ? '01' : (String) objQuote.Sold_to_Distribution_Channel__c;
        rtpRequest.Division = (String) objQuote.Sold_to_Division__c;

        //DCP-46872   
        for(String strProdInterestValue : mapProductInterestToSAPValue.keySet())
        {
            if(String.isNotBlank(objQuote.Apttus_Proposal__Opportunity__r.Product_Interest__c) 
            && objQuote.Apttus_Proposal__Opportunity__r.Product_Interest__c.contains(strProdInterestValue))
            {
                rtpRequest.ZzsvmxOrderType = mapProductInterestToSAPValue.get(strProdInterestValue);
                break;
            }
        }
        //End of DCP-46872

        if((objQuote.Apttus_Proposal__ExpectedStartDate__c == null && objQuote.Apttus_Proposal__ExpectedEndDate__c == null) ||(objQuote.Apttus_Proposal__ExpectedStartDate__c != null && objQuote.Apttus_Proposal__ExpectedEndDate__c != null)){
            rtpRequest.QtValidT = RealtimePricingRequestGenerator.generateSAPDate('Apttus_Proposal__ExpectedEndDate__c',PROPOSALAPI,objConfig);
            rtpRequest.QtValidF = RealtimePricingRequestGenerator.generateSAPDate('Apttus_Proposal__ExpectedStartDate__c',PROPOSALAPI,objConfig);
        }
        else{
            if(objQuote.Apttus_Proposal__ExpectedStartDate__c == null){
                rtpRequest.QtValidT = RealtimePricingRequestGenerator.generateSAPDate('Apttus_Proposal__ExpectedEndDate__c',PROPOSALAPI,objConfig);
                rtpRequest.QtValidF = rtpRequest.QtValidT;
            }
            if(objQuote.Apttus_Proposal__ExpectedEndDate__c == null){
                rtpRequest.QtValidF = RealtimePricingRequestGenerator.generateSAPDate('Apttus_Proposal__ExpectedStartDate__c',PROPOSALAPI,objConfig);
                rtpRequest.QtValidT = rtpRequest.QtValidF;
            }
        }
       // ilib_LogEvent.message('*****ApttusGenerateQuoteController.objQuote.Apttus_QPConfig__PriceListId__c--'+ApttusGenerateQuoteController.objQuote.Apttus_QPConfig__PriceListId__c);
          List<Apttus_Config2__PriceList__c> objPlist = new ApttusPriceListsSelector().selectById(new Set<Id>{(String)RealtimePricingRequestGenerator.objQuote.Apttus_QPConfig__PriceListId__c});
        if(!objPlist.isEmpty()){
            rtpRequest.PriceList = objPlist[0].name.substring(0,2);
        }
        rtpRequest.HCurr = (String) objQuote.CurrencyIsoCode;
        rtpRequest.PriceDate = RealtimePricingRequestGenerator.generateSAPDate('Apttus_QPConfig__PricingDate__c',PROPOSALAPI,objConfig);

        rtpRequest.ZzapQuot = (String) objQuote.Name;
        rtpRequest.Zzoppid = (String) objQuote.Apttus_Proposal__Opportunity__c;
        rtpRequest.Incoterms1 = (String) internalPicklistToExternalPicklistQuote.get('Inco_Term_1__c').get(objQuote.Inco_Term_1__c);
        rtpRequest.ZzmyilmnEmail = (String) objQuote.MyIllumina_User_Email__c;
        rtpRequest.Zstatus = mapOfStage.get(objQuote.Apttus_Proposal__Approval_Stage__c);
        rtpRequest.UsageInd = objQuote.Web_Visible__c ? 'W_Y' : 'W_N';
        rtpRequest.Pmnttrms = (String) objQuote.Apttus_Proposal__Payment_Term__c;
        rtpRequest.OrdReason = ((String) objQuote.Quote_Type__c == 'Direct Field Services' || (String) objQuote.Quote_Type__c == 'Indirect Field Services') ? 'ZBS' : 'ZOP';

        // Promo Code from config objects
        if(String.isNotBlank(objConfig.Promotion_JSON__c) && !objQuote.Direct_Sale_to_Ultimate_Consignee__c){
            lstPromoWrapper = (List<PromotionWrapper>) System.JSON.deserialize(objConfig.Promotion_JSON__c, List<PromotionWrapper>.class);
            ilib_LogEvent.message('Applied promos :'+ lstPromoWrapper);
            for (Integer idx = 0; idx < lstPromoWrapper.size(); idx++){
                if(idx==0){
                    rtpRequest.ZzpromoCode1 = lstPromoWrapper[0].PromoCode;
                    rtpRequest.ZzpromoChannel1 = lstPromoWrapper[0].PromoChannel;
                }
                else if(idx==INTEGER_ONE){
                    rtpRequest.ZzpromoCode2 = lstPromoWrapper[1].PromoCode;
                    rtpRequest.ZzpromoChannel2 = lstPromoWrapper[1].PromoChannel;
                }
                else if(idx==INTEGER_TWO){
                    rtpRequest.ZzpromoCode3 = lstPromoWrapper[2].PromoCode;
                    rtpRequest.ZzpromoChannel3 = lstPromoWrapper[2].PromoChannel;
                }
            }
        }

        //  ilib_LogEvent.message('Price---' + objConfig.getSobject('Apttus_QPConfig__Proposald__r').getSobject('Apttus_QPConfig__PriceListId__r'));
        //null check on id below
        // make it as single contact
        Contact objCon = new Contact();
        if(objQuote.Apttus_Proposal__Primary_Contact__c != null){
            objCon = new ContactsSelector().selectContacts(new Set<Id>{(String)objQuote.Apttus_Proposal__Primary_Contact__c})[0];
            ilib_LogEvent.message('Contact1-->'+ objCon);
            rtpRequest.ZdName = objCon.name!= null ?objCon.name : '';
            rtpRequest.ZdTelephone = objCon.phone != null ?objCon.phone : '';
            rtpRequest.ZdEmail = objCon.email!=null ? objCon.email : '';
        }

        RealtimePricingRequest.Line objTextLine = new RealtimePricingRequest.Line();
        objTextLine.TextId = 'ZQ09';
        objTextLine.TextLine = '';

        rtpRequest.NAVHDRTOTXT.add(objTextLine);

        objTextLine = new RealtimePricingRequest.Line();
        objTextLine.TextId = 'ZQ19';
        String strJunk='[delegate=';
        String strBaseUrl= String.valueOf(System.URL.getSalesforceBaseUrl());
        if(strBaseUrl.contains(strJunk)&&strBaseUrl.contains(']'))
            strBaseUrl = strBaseUrl.substring(strBaseUrl.indexOf(strJunk)+strJunk.length(),strBaseUrl.lastIndexOf(']'));
        objTextLine.TextLine =strBaseUrl + '/'+ (String) objQuote.Apttus_Proposal__Opportunity__c;

        rtpRequest.NAVHDRTOTXT.add(objTextLine);

        //added for DCP-25194
        objTextLine = new RealtimePricingRequest.Line();
        objTextLine.TextId = 'ZPPM';
        String strPPM = objConfig.Apttus_QPConfig__Proposald__r.Post_Pricing_Message__c;
        ilib_LogEvent.message('strPPM: ' + strPPM);
        objTextLine.TextLine =String.isNotBlank(strPPM)?strPPM : '' ;
        rtpRequest.NAVHDRTOTXT.add(objTextLine);

        Map<String, String> roleToPartnerField = new Map<String, String> {
                'SP' => 'Sold_To_ERP_Number__c',
                'SH' => 'Ship_To_ERP_Number__c',
                'Z3' => 'Ultimate_Consignee_ERP_Number__c',
                'BP' => 'Bill_To_ERP_Number__c',
                'Z5' => 'Distributor_ERP_Number__c',
                'PY' => 'Payer_ERP_Number__c',
                'SE' => 'Sales_Employee',
                'ZD' => 'Dummy Contact',
                'SB' => 'Inventory_Location_ERP_Number__c' //DCP-46257
                };
        List<User> objUser = new UsersSelector().selectUserEmployeeNoById(new Set<Id>{(String)objConfig.getSobject(PROPOSALAPI).get('Prepared_by__c')});
        for(String strRole: roleToPartnerField.keySet())
        {
            RealtimePricingRequest.SalesPartner objPartner = new RealtimePricingRequest.SalesPartner();
            if(strRole != 'SE' && strRole != 'ZD'){
            String strPartner = roleToPartnerField.get(strRole);

            objPartner.PartnRole = strRole;
            Object objPartnerNumber = objConfig.getSobject(PROPOSALAPI).get(strPartner);
            objPartner.PartnNumb = (objPartnerNumber == null ? null : String.valueOf(objPartnerNumber));
            }
            else if(strRole == STRING_SE){
                objPartner.PartnRole = strRole;

                if(!objUser.isEmpty()){
                objPartner.PartnNumb = objUser[0].EmployeeNumber;
                }
            }
            else if(strRole == 'ZD' && objQuote.Apttus_Proposal__Primary_Contact__c != null){
                objPartner.PartnRole = strRole;
                objPartner.PartnNumb = DUMMYPARTNER;
            }
            if(String.isNotBlank(objPartner.PartnNumb)) { rtpRequest.NAVHDRTOPRT.add(objPartner); }
        }
        Map<String,Map<String,string>> internalPicklistToExternalPicklist =  utilsSettings.getCustomMetadataPicklistMap('Apttus_Config2__LineItem__c','ERP',true);
        Integer intConfigNumber = 1;

        //DCP-28284 - To Store FixedBundleSKU LI Number on Components
        Map<Decimal,String> lineItemNumberToName = new Map<Decimal,String>();

        for (Apttus_Config2__LineItem__c objCartLine : lstLineItems)
        {
            // DCP-41818
            // NOTE: currently no mechanism for different values on different lines
            if (String.isBlank(rtpRequest.CostCenter)) rtpRequest.CostCenter = objCartLine.Cost_Center__c;

            if (objCartLine.Apttus_Config2__OptionId__c == null && objCartLine.Apttus_Config2__ProductId__r.Material_Class_Type__c == Label.FixedBundleMatClassType){
                lineItemNumberToName.put(objCartLine.Apttus_Config2__LineNumber__c,objCartLine.Name); }

            objCartLine.Global_Trade_Block__c = true;
            if(!objQuote.Direct_Sale_to_Ultimate_Consignee__c)
            {
                objCartLine.Applied_Discount_Details__c = '';
                objCartLine.Stacked_Discount_Percentage__c = null;
                objCartLine.Stacked_Discount_Amount__c = null;
                objCartLine.Distributor_Specific_Discount__c = null;
                objCartLine.Distributor_Specific_Discount_Percentage__c = null;
                objCartLine.Freight_Discount_Amount__c = null;
                objCartLine.Applied_Discount_Amount__c = null;
                objCartLine.Promotion_1__c = null;
                objCartLine.Promotion_2__c = null;
                objCartLine.Promotion_3__c = null;
                objCartLine.Promotion_4__c = null;
                objCartLine.Promotion_5__c = null;
            }
            lineNameToLineItem.put(objCartLine.name,objCartLine);
            RealtimePricingRequest.LineItem objLine = new RealtimePricingRequest.LineItem();
            objLine.Material = (objCartLine.Apttus_Config2__OptionId__c != null ? objCartLine.Apttus_Config2__OptionId__r.Material_Number__c : objCartLine.Apttus_Config2__ProductId__r.Material_Number__c);
            objLine.SapItmNumber = objCartLine.ERP_Line_Number__c != null ? objCartLine.ERP_Line_Number__c.split('_')[1] : null;
            objLine.ZzapPosnr = objCartLine.name;
            objLine.Zzbundleid = objCartLine.Apttus_Config2__ProductId__r.Bundle_Id__c;

            //Added for DCP-28284 - Sending FixedBundleSKU LI Number on Components
            objLine.ZzapPosnrHgLvl = objCartLine.Apttus_Config2__OptionId__c != null? lineItemNumberToName.get(objCartLine.Apttus_Config2__LineNumber__c): null;
            Datetime dtStartDate = (Datetime)objCartLine.Apttus_Config2__StartDate__c;
            String strStartDate = '\\'+'/Date(' + String.valueOf((dtStartDate == null ? dateNow : dtStartDate.getTime())) + ')'+'\\'+'/';
            objLine.ContractStart = strStartDate;
            Datetime dtEndDate = (Datetime)objCartLine.Apttus_Config2__EndDate__c;
            String strEndDate = '\\'+'/Date(' + String.valueOf((dtEndDate == null ? dateNow : dtEndDate.getTime())) + ')'+'\\'+'/';
            objLine.ContractEnd = strEndDate;

            // DCP - 23079
            objline.Zzsceqnr = objCartLine.Equipment_Id__c;
            //DCP-46276
            objLine.Sernr = String.isBlank(objCartLine.Serial_Number__c) ? objCartLine.Serial_Number__c : objCartLine.Serial_Number__c.replace(',',';');
            //
            objLine.BillFreq = internalPicklistToExternalPicklist.get('Apttus_Config2__BillingFrequency__c').get(objCartLine.Apttus_Config2__BillingFrequency__c);
            objLine.TargetQty = String.valueOf(objCartLine.Apttus_Config2__Quantity__c);

            //DCP-25190 : Demo program and DCP-43354 Reagent Rental
            objLine.Cstcndgrp1 = String.valueOf(objCartLine.Program_Type__c) == Label.Demo_Program ? 'Y' : null;
            objLine.Cstcndgrp4 = String.valueOf(objCartLine.Program_Type__c) == Label.OpportunityTypeRentalReagent ? 'RR' : null;

             //DCP-46872
             objLine.ZzsvmxOrd = String.isBlank(objConfig.Work_Order__c) ? null : objConfig.Work_Order__r.Name;
             //End of DCP-46872

            Product2 objProduct = (objCartLine.Apttus_Config2__OptionId__c != null ? objCartLine.Apttus_Config2__OptionId__r : objCartLine.Apttus_Config2__ProductId__r);
            ilib_LogEvent.message('type =--'+objProduct.Apttus_Config2__ConfigurationType__c);
            ilib_LogEvent.message('linetype --'+objCartLine.Apttus_Config2__LineType__c);
            ilib_LogEvent.message('Customer_Premium_Amount_Per_Unit__c---:'+objCartLine.Customer_Premium_Amount_Per_Unit__c+'  '+String.valueOf(objCartLine.Customer_Premium_Amount_Per_Unit__c));
            // condition added to skip Sku product
            if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE)){
                rtpRequest.NAVHDRTOITM.add(objLine);
            }
            //Added for DCP-28284 - Adding FixedBundleSKU
            //SonarQube Fix
            else{
                if(objCartLine.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE && objCartLine.Apttus_Config2__ProductId__r.Material_Class_Type__c==Label.FixedBundleMatClassType){
                    rtpRequest.NAVHDRTOITM.add(objLine);
                }
            }

            /****************************/
            // Beadchip and Project id
            /***************************/
            if (String.isnotBlank(objCartLine.Beadchip_Part_Number__c) || ApttusCheckPriceBaseClass.boolConsortia)  //DCP-45251 - Beadchip Soft Warning and Consortia Product Enhancement
            {
                RealtimePricingRequest.Reference objLineRef = new RealtimePricingRequest.Reference();
                objLineRef.ConfigId = String.valueOf(intConfigNumber);
                objLineRef.RootId = String.valueOf(intConfigNumber);
                objLineRef.ZzapPosnr = objCartLine.name;
                rtpRequest.NAVHDRTOCFGSREF.add(objLineRef);

                RealtimePricingRequest.Instance objLineInst = new RealtimePricingRequest.Instance();
                objLineInst.ConfigId = String.valueOf(intConfigNumber);
                objLineInst.InstId = String.valueOf(intConfigNumber);
                rtpRequest.NAVHDRTOCFGSINST.add(objLineInst);

                RealtimePricingRequest.Values objLineValues = new RealtimePricingRequest.Values();
                objLineValues.Charc = 'BEADCHIPORDERED';
                objLineValues.Value = (String) objCartLine.Beadchip_Part_Number__c;
                objLineValues.ConfigId = String.valueOf(intConfigNumber);
                objLineValues.InstId = String.valueOf(intConfigNumber);
                if (String.isNotBlank(objCartLine.Beadchip_Part_Number__c)) { rtpRequest.NAVHDRTOCFGSVAL.add(objLineValues); }
            }

            /****************************/
            // Consortia related field
            /***************************/
            if (ApttusCheckPriceBaseClass.boolConsortia)
            {
                RealtimePricingRequest.Values objLineValues1 = new RealtimePricingRequest.Values();
                objLineValues1.Charc = 'SPECIESNAME';
                //INC0197802
                String strSpecies = (String) objQuote.Apttus_Proposal__Opportunity__r.Consortium__r.Species__c;
                strSpecies = strSpecies.replaceAll('[^a-zA-Z0-9 ]', '');
                objLineValues1.Value = String.isNotBlank(strSpecies) && strSpecies.length()>30?strSpecies.substring(0,29):strSpecies;
                objLineValues1.ConfigId = String.valueOf(intConfigNumber);
                objLineValues1.InstId = String.valueOf(intConfigNumber);
                if(String.isNotBlank(objQuote.Apttus_Proposal__Opportunity__r.Consortium__r.Species__c)) { rtpRequest.NAVHDRTOCFGSVAL.add(objLineValues1);}

                RealtimePricingRequest.Values objLineValues2 = new RealtimePricingRequest.Values();
                objLineValues2.Charc = 'SPECIESCATEGORY';
                //INC0197802
                String strConsortiumName = (String) objQuote.Apttus_Proposal__Opportunity__r.Consortium__r.Name;
                strConsortiumName = strConsortiumName.replaceAll('[^a-zA-Z0-9 ]', '');
                objLineValues2.Value = String.isNotBlank(strConsortiumName) && strConsortiumName.length()>30?strConsortiumName.substring(0,29):strConsortiumName;
                objLineValues2.ConfigId = String.valueOf(intConfigNumber);
                objLineValues2.InstId = String.valueOf(intConfigNumber);
                if(String.isNotBlank(objQuote.Apttus_Proposal__Opportunity__r.Consortium__r.Name)){ rtpRequest.NAVHDRTOCFGSVAL.add(objLineValues2); }
            }

            /****************************/
            // Discount Pricing COndition
            /***************************/

            RealtimePricingRequest.Condition objLineConditionYD = new RealtimePricingRequest.Condition();
            objLineConditionYD.CondType = 'YD04';
            objLineConditionYD.ZzapPosnr = String.valueOf(objCartLine.name);
            objLineConditionYD.CondValue = String.isNotBlank(String.valueOf(objCartLine.Sales_Discretionary_Discount__c)) ? String.valueOf(objCartLine.Sales_Discretionary_Discount__c) :'0';
            objLineConditionYD.Calctypcon = (objCartLine.Sales_Discretionary_Type__c == 'Discount Amount') ? 'N':'A';
            ilib_LogEvent.message('***Apttus_Config2__AdjustmentType__c'+objCartLine.Sales_Discretionary_Type__c);
            
            if (objQuote.Direct_Sale_to_Ultimate_Consignee__c)
            {
                //DCP-23566 Send Discount in YD04 while Validate Cart
                rtpRequest.NAVHDRTOCND.add(objLineConditionYD);
            }
            else
            {
                // condition added to skip Sku product
                if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE)){
                    if(String.isNotBlank(objLineConditionYD.CondValue)) { rtpRequest.NAVHDRTOCND.add(objLineConditionYD); }
                }
                //Added for DCP-28284 - Adding FixedBundleSKU
                else if(objProduct.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objProduct.Material_Class_Type__c==Label.FixedBundleMatClassType){
                    if(String.isNotBlank(objLineConditionYD.CondValue)) { rtpRequest.NAVHDRTOCND.add(objLineConditionYD); }
                }                
            }
            ilib_LogEvent.message('***787 --'+ApttusCheckPriceBaseClass.boolConsortia);
            ilib_LogEvent.message('***788 --'+objCartLine.Total_List_Price__c);
            RealtimePricingRequest.Condition objLineCondition3 = new RealtimePricingRequest.Condition();
            objLineCondition3.ZzapPosnr = String.valueOf(objCartLine.name);
            objLineCondition3.CondType = 'YCO1';

            //DCP-24500
            if(ApttusCheckPriceBaseClass.boolConsortia){
                objLineCondition3.CondValue = String.valueof(objCartLine.Unit_Price__c);
            }else if(objCartLine.Price_Override__c != null && objCartLine.Price_Override__c != 0){
                objLineCondition3.CondValue= String.valueOf(objCartLine.Price_Override__c);
            }else if(objQuote.Direct_Sale_to_Ultimate_Consignee__c && (objCartLine.Price_Override__c == null || objCartLine.Price_Override__c == 0)){
                objLineCondition3.CondValue = String.Valueof(objCartLine.List_Price__c);
            }
            objLineCondition3.Calctypcon = 'N';
            if(ApttusCheckPriceBaseClass.boolConsortia){
                 objLineCondition3.ReasonForPriceOverride = System.Label.OpportunityTypeConsortium;
            }else if(String.isNotBlank(objCartLine.Reason_For_Price_Override__c)){
                objLineCondition3.ReasonForPriceOverride = objCartLine.Reason_For_Price_Override__c;
            }else if(objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                objLineCondition3.ReasonForPriceOverride = 'Direct Sales To UC';
            }

            // condition added to skip Sku product
            if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE)){
                if(String.isNotBlank(objLineCondition3.CondValue)) { rtpRequest.NAVHDRTOCND.add(objLineCondition3); }
            }

            if(objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                RealtimePricingRequest.Condition objLineCondition4 = new RealtimePricingRequest.Condition();
                // DCP-25321 : Customer premium
                if(objCartLine.Customer_Premium_Amount_Per_Unit__c == NULL) { objCartLine.Customer_Premium_Amount_Per_Unit__c = 0; }
                objLineCondition4.ZzapPosnr = String.valueOf(objCartLine.name);
                objLineCondition4.CondType = 'YMUP';
                objLineCondition4.CondValue = String.valueOf(objCartLine.Customer_Premium_Amount_Per_Unit__c);
                objLineCondition4.Calctypcon = 'N';
                // condition added to skip Sku product
                if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE)){
                        rtpRequest.NAVHDRTOCND.add(objLineCondition4);
                }
            }

            if(objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                RealtimePricingRequest.Condition objLineCondition5 = new RealtimePricingRequest.Condition();
                objLineCondition5.ZzapPosnr = String.valueOf(objCartLine.name);
                objLineCondition5.CondType = 'YDNT';
                objLineCondition5.CondValue = String.valueOf(objCartLine.Distributor_Specific_Price__c);
                objLineCondition5.Calctypcon = 'N';
                // condition added to skip Sku product
                if(objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                    if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE)){
                        if(String.isNotBlank(objLineCondition5.CondValue)) { rtpRequest.NAVHDRTOCND.add(objLineCondition5); }
                    }
                }
            }

            //Added as part of DCP-25322, Manual rebate condition
            if(objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                RealtimePricingRequest.Condition objLineCondition = new RealtimePricingRequest.Condition();
                objLineCondition.CondType = 'YB01';
                objLineCondition.ZzapPosnr = String.valueOf(objCartLine.name);
                if(objCartLine.Manual_Rebate_Per_Unit__c != null){
                    objLineCondition.CondValue = String.valueOf(objCartLine.Manual_Rebate_Per_Unit__c);
                }else{
                    objLineCondition.CondValue = '';
                }
                objLineCondition.Calctypcon = 'C';
                // condition added to skip Sku product
                if(objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                    if(!(objProduct.Apttus_Config2__ConfigurationType__c == CONFIG_TYPE_BUNDLE && objCartLine.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE)){
                        if(String.isNotBlank(objLineCondition.CondValue)) { rtpRequest.NAVHDRTOCND.add(objLineCondition); }
                    }
                }
            }

            intConfigNumber++;
         }

        String pretty = JSON.serializePretty(rtpRequest);

        ilib_LogEvent.pop();
        return pretty;
    }

}
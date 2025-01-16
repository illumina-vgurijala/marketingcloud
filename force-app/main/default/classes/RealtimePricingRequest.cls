/*
 * @Author: Kushagra Desai
 * @Date: 2018-11-07
 * @Description : Wrapper class to send Quote creation request to SAP.
*  Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Indra Ganesan           04-DEC-2018                 Added Reason For Price Override
* Kushagra Desai       25-JAN-2019                   Direct Sales To UC changes and Consortia
* Kushagra Desai       18-Mar-2019                   Removal of special character from consortia name(INC0197802)
* Kushagra Desai       27-Mar-2019                   Passing YCO1 from Check Price during Generate[DCP-24500]
* Akshay Mohan         15-May-2019                   DCP-25194 add PPM
* Roopal Verma         29-May-2019                   DCP-25322, Manual rebate
* Kushagra Desai       30-May-2019                   DCP-25190 : Demo program
* Saswati              27-Sep-2019                   DCP-28565 : Added Fapiao Type Field Logic
* Roopal               10-Oct-2019                   DCP-27832 : Added vatriable date30 to populate correct valid to date
* Arnab                23-Aug-2019                   DCP-28284 : Added Fix Bundle Logic
* Arnab                10-Oct-2019                   DCP-28284 : Added logic for Generate Cart
* Govind Dubey         24-Oct-2019                   Commented Project Id logic for INC0227087
* Rahul Bishnoi        13-Jan-2020                   DCP-32794 Removed Software Id
* Rahul Bishnoi        20-Jan-2020                   DCP-31269 Quote Sync to SAP Updates from Platorm Products
* Rishab Wali          18-May-2020                   DCP-34910 Managing Large Cart - Adding Parameters to request for async calls
* Prabhsimran Singh    11-June-2020                  DCP-37888 Managing Large Cart - Initialising objquote
* Bharath Varma        17-Nov-2020                   DCP-31776 Added Zzsubid and ZzAddonFlag parameters and logic to update Existing Subscriptions
* Bharath Varma        03-Dec-2020                   DCP-43354 Added additional logic to send Product Type value to SAP
* Rishab Wali          18-Dec-2020                   DCP-23566 Allow 0$ Story
* Rishab Wali          12-Jan-2021                   DCP-45251 - Beadchip Soft Warning and Consortia Product Enhancement
* Joshith K            25-Mar-2021                   INC0314618- revert code overwrite from feb release.
* Rishab Wali          23-June-2021                  DCP-47078 - Send ZDO as Order Reason when Discount Type is Donation.
* Nishan Shetty        22-April-2022                 CodeScan Fix:Avoid Literals in If condition
* Rucha Dalvi          05-July-2022                  Codescan fixes: Duplicate literals
* Vinay S Reddy        23-Oct-2023                   CMCM 1482 Updates
*-------------------------------------------------------------------------------------------------------------------------------------------------
*/

public class RealtimePricingRequest {

    public static final String CODEPARAMETERNAME = 'Real_Time_Pricing_Threshold_Value';
	public static final String TEXTIDZLQT = 'ZLQT';//DCP-37888
    public static final String TEXTZOP = 'ZOP'; //DCP-47078
    public static final String STRDONATION = 'Donation';//DCP-47078

    public String DocType = 'ZQT';
    public String CostCenter; // DCP-41818
    public String FileContent;
    public String Vbeln;
    public String SalesOrg;
    public String DistrChan;
    public String Division;
    public String QtValidT;
    public String QtValidF;
    public String PriceList;
    public String HCurr;
    public String PriceDate;  // Format expected /Date(1572048000000)/
    public String PoMethod = 'SFDC';
    public string ZzapQuot;
    public String Zzoppid;
    public String Incoterms1;
    public String ZzmyilmnEmail;
    public String Zstatus;
    public String UsageInd;
    public String Pmnttrms;
    public String OrdReason;
    public String ZzpromoCode1;
    public String ZzpromoCode2;
    public String ZzpromoCode3;
    public String ZzpromoChannel1;
    public String ZzpromoChannel2;
    public String ZzpromoChannel3;
    public String ZdName;
    public String ZdTelephone;
    public String ZdEmail;
    public String Cstcndgrp2;
    public String ZzsvmxOrderType; //DCP- 46872

    public List<Fapiao> NAVHDRTOFAPIAO = new List<Fapiao>(); //DCP-28565 : Added Fapiao
    public List<SalesPartner> NAVHDRTOPRT = new List<SalesPartner>();
    public List<Line> NAVHDRTOTXT = new List<Line>();
    public List<LineItem> NAVHDRTOITM = new List<LineItem>();
    public List<Condition> NAVHDRTOCND = new List<Condition>();
    public List<Object> NAVHDRTOGTSLOGS = new List<Object>();
    //public List<Object> NAVHDRTOITEMPRICE = new List<Object>();
    public List<Object> NAVHDRTOEXP = new List<Object>();
    public List<Object> NAVHDRTOITEMCOND = new List<Object>();
    public List<Object> NAVHDRTORET = new List<Object>();
    //Added for custom product re-order and Consortia
    public List<Reference> NAVHDRTOCFGSREF = new List<Reference>();
    public List<Values> NAVHDRTOCFGSVAL = new List<Values>();
    public List<Instance> NAVHDRTOCFGSINST = new List<Instance>();
    public List<TextItem> NAVITMTOTXT = new List<TextItem>(); //DCP -31269

    private static List<PromotionWrapper> lstPromoWrapper;

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    private static final Integer INTEGER_TWO = 2;
    private static final String STRING_SE = 'SE';
    //End CodeScan Fix

    public static final string STRING_CART_LINE_TYPE = 'Product/Service';

    /*
     * Reference datatype
     */
    public class Reference{
        public String ZzapPosnr;
        public String ConfigId;
        public String RootId;
    }

    //DCP - 31269
    /*
     * TextItem datatype
     */
    public class TextItem{
        public String ZzapPosnr;
        public String TextId;
        public String TextLine;
    }
    /*
     * Values datatype
     */
    public class Values{
        public String ConfigId;
        public String InstId;
        public String Charc;
        public String Value;
    }
    /*
     * Instance datatype
     */
    public class Instance{
        public String ConfigId;
        public String InstId;
    }

    /*
     * LineItem datatype
     */
    public class LineItem {
        public String SapItmNumber;
        public String Material;
        public String ZzapPosnr;
        public String Zzbundleid;
        public String ReasonRej;
        public String Zzsoftwareid;
        public String ContractStart;
        public String ContractEnd;
        public String BillFreq;
        public String TargetQty;
        public String Zzsceqnr;
        public String Sernr;
        public String Cstcndgrp1; // DCP-25190 : Demo program
        public String ZzapPosnrHgLvl; //DCP-28284 : Sending Fixed Bundle SKU LineItem Number on Component LineItems
        //DCP - 31269
        public String RefDoc;
        public String Region;
        public String DomainUrl;
        public String RefDocItm;
        public String OnlineFlg;
        public String LicenseFlag;
        public String Pguid;
        // DCP - 31776
        public String ZzAddonFlag = '';
        public String ZzRenewFlag;
        //DCP - 43354
        public String Cstcndgrp4;
        public String ZzsvmxOrd; //DCP-46872
        public String TradeInIndicator;

    }

    /*
     * SalesPartner datatype
     */
    public class SalesPartner {
        public String PartnRole;
        public String PartnNumb;
    }

    //DCP-28565 : Added Fapiao
    /*
     * Fapio datatype
     */
    public class Fapiao{
        public string FapiaoTypeCode;
        public string FapiaoTypeDesc;
    }

    /*
     * Line datatype
     */
    public class Line{
        public String TextId;
        public String TextLine;
        public string Langu = 'EN';
    }

    /*
     * Condition datatype
     */
    public class Condition {
        public String ZzapPosnr;
        public String CondType;
        public String CondValue;
        public String Calctypcon;
        public String ReasonForPriceOverride;
    }

    /*
     * Promotion Wrapper
     */
    public class PromotionWrapper {
        public string PromoCode;
        public string PromoChannel;
    }

    /*
     * JSON request on Generate Quote
     */
    public static string createJSONForGenerateQuote(String strQuoteID, Boolean isSendQuote)
    {
        ilib_LogEvent.push('createJSONForGenerateQuote');

        string strFapiotype =''; // DCP-28565
        string strFapiaoTypeDesc =''; // DCP-28565
        long dateNow = Datetime.now().getTime();
        long date30 = Datetime.now().addDays(30).getTime();  //DCP-27832
        String dummyPartner = '31739';

        Map<String,Map<String,string>> internalPicklistToExternalPicklistQuote =  utilsSettings.getCustomMetadataPicklistMap('Apttus_Proposal__Proposal__c','ERP',true);

        List<Apttus_Proposal__Proposal_Line_Item__c> lstQuoteLineItem = new ApttusProposalLineItemsSelector().selectByQuoteId(new set<ID>{strQuoteID});

        String costCenter = '';  // DCP-41818
        Set<Id> cartLineIds = UtilsCollection.getSetOfIds(lstQuoteLineItem, 'Apttus_QPConfig__DerivedFromId__c');
        List<Apttus_Config2__LineItem__c> cartLines = new ApttusLineItemsSelector().selectById(cartLineIds);

        for (Apttus_Config2__LineItem__c li : cartLines)
        {
            // NOTE: currently no mechanism for different values on different lines
            if (String.isNotBlank(li.Cost_Center__c))
            {
                costCenter = li.Cost_Center__c;
                break;
            }
        }

        String strJSON;
        RealtimePricingRequest rtpRequest = new RealtimePricingRequest();
        // DCP-41818
        rtpRequest.CostCenter = costCenter;

        //37888 - Logic for generate large cart
        if(ApttusGenerateQuoteController.objQuote == null) {
            ApttusGenerateQuoteController.objQuote = new ApttusProposalsSelector().selectProposalById(strQuoteID);
        }

        // Saswati : added for Fapiao.DCP-28565 -------------------
        RealtimePricingRequest.Fapiao  ofapiao = new RealtimePricingRequest.Fapiao();
        if(ApttusGenerateQuoteController.objQuote.Fapiao_Type_Code__c!=null) {
            strFapiotype = ApttusGenerateQuoteController.objQuote.Fapiao_Type_Code__c;
        }
        ofapiao.FapiaoTypeCode =strFapiotype;
        ofapiao.FapiaoTypeDesc = strFapiaoTypeDesc;
        rtpRequest.NAVHDRTOFAPIAO.add(ofapiao);
        //---------------Fapiao Over------

        ApttusGenerateQuoteController.boolConsortia = ApttusGenerateQuoteController.objQuote.Quote_Sub_Type__c ==System.Label.OpportunityTypeConsortium || ApttusGenerateQuoteController.objQuote.Quote_Sub_Type__c ==System.Label.OpportunityTypeReorderConsortiumConsumable;
        Map<String,String> mapOfStage = new Map<String,string>{
            Label.QuoteStageDraft => 'Initial',
            Label.QuoteStageInReview => 'Pending',
            Label.QuotationApprovalStatusApproved => 'Approved',
            Label.QuoteStageGenerated => 'Approved',
            Label.QuoteStageApprovalRequired => 'Initial',
            Label.QuoteStagePresented => 'Approved'
        };

        ApttusGenerateQuoteController.objQuote.SAP_Errors__c = '';
        if(ApttusGenerateQuoteController.objQuote.SAP_Quote__c == null){
            rtpRequest.Vbeln = '';
        }
        else{
            rtpRequest.Vbeln = (String) ApttusGenerateQuoteController.objQuote.SAP_Quote__c;
        }
        rtpRequest.SalesOrg = (String) ApttusGenerateQuoteController.objQuote.Sold_to_Sales_Organization__c;
        rtpRequest.DistrChan = ApttusGenerateQuoteController.objQuote.Direct_Sale_to_Ultimate_Consignee__c ? '01' : (String) ApttusGenerateQuoteController.objQuote.Sold_to_Distribution_Channel__c;
        rtpRequest.Division = (String) ApttusGenerateQuoteController.objQuote.Sold_to_Division__c;
        //DCP-46872
        for(String strProdInterestValue : RealtimePricingRequestGenerator.mapProductInterestToSAPValue.keySet())
        {
            if(String.isNotBlank(ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Opportunity__r.Product_Interest__c) 
            && ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Opportunity__r.Product_Interest__c.contains(strProdInterestValue))
            {
                rtpRequest.ZzsvmxOrderType = RealtimePricingRequestGenerator.mapProductInterestToSAPValue.get(strProdInterestValue);
                break;
            }
        }
        //End of DCP-46872
        if((ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedEndDate__c == null && ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedStartDate__c == null)||(ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedEndDate__c != null && ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedStartDate__c != null)){
            Datetime quoteValidFrom=(Datetime)ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedStartDate__c;
            String qtValidFrom='\\'+'/Date(' + String.valueOf((quoteValidFrom == null ? dateNow : quoteValidFrom.getTime())) + ')'+'\\'+'/';
            rtpRequest.QtValidF=qtValidFrom;
            Datetime quoteValidTo=(Datetime)ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedEndDate__c;
            String qtValidTo='\\'+'/Date(' + String.valueOf((quoteValidTo == null ? date30 : quoteValidTo.getTime())) + ')'+'\\'+'/';   //Modified for DCP-27832
            rtpRequest.QtValidT=qtValidTo;
        }
        else{
            if(ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedEndDate__c == null){
                Datetime quoteValidFrom=(Datetime)ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedStartDate__c;
                String qtValidFrom='\\'+'/Date(' + String.valueOf((quoteValidFrom == null ? dateNow : quoteValidFrom.getTime())) + ')'+'\\'+'/';
                String qtValidTo='\\'+'/Date(' + String.valueOf(date30) + ')'+'\\'+'/';                                                //Modified for DCP-27832
                rtpRequest.QtValidT=qtValidTo;
                rtpRequest.QtValidF=qtValidFrom;
            }
            if(ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedStartDate__c == null){
                Datetime quoteValidTo=(Datetime)ApttusGenerateQuoteController.objQuote.Apttus_Proposal__ExpectedEndDate__c;
                String qtValidTo='\\'+'/Date(' + String.valueOf((quoteValidTo == null ? dateNow : quoteValidTo.getTime())) + ')'+'\\'+'/';
                rtpRequest.QtValidT=qtValidTo;
                rtpRequest.QtValidF=qtValidTo;
            }
        }

        ilib_LogEvent.message('quote pricelist '+ApttusGenerateQuoteController.objQuote.Apttus_QPConfig__PriceListId__c);
        List<Apttus_Config2__PriceList__c> objPlist = new ApttusPriceListsSelector().selectById(new Set<Id>{(String)ApttusGenerateQuoteController.objQuote.Apttus_QPConfig__PriceListId__c});
        ilib_LogEvent.message('price list item size '+objPlist.size());
        ilib_LogEvent.message('price list item size '+objPlist);
        if(!objPlist.isEmpty()){
            rtpRequest.PriceList = objPlist[0].name.substring(0,2);
            ilib_LogEvent.message('req- pricelist'+rtpRequest.PriceList);
        }

        rtpRequest.HCurr = (String) ApttusGenerateQuoteController.objQuote.CurrencyIsoCode;
        Datetime dtPriceDate = (Datetime)ApttusGenerateQuoteController.objQuote.Apttus_QPConfig__PricingDate__c;
        String strPriceDate = '\\'+'/Date(' + String.valueOf((dtPriceDate == null ? dateNow : dtPriceDate.getTime())) + ')'+'\\'+'/';
        rtpRequest.PriceDate = strPriceDate;
        rtpRequest.ZzapQuot = (String) ApttusGenerateQuoteController.objQuote.Name;
        rtpRequest.Zzoppid = (String) ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Opportunity__c;
        rtpRequest.Incoterms1 = (String) internalPicklistToExternalPicklistQuote.get('Inco_Term_1__c').get(ApttusGenerateQuoteController.objQuote.Inco_Term_1__c);
        rtpRequest.ZzmyilmnEmail = (String) ApttusGenerateQuoteController.objQuote.MyIllumina_User_Email__c;
        rtpRequest.Zstatus = mapOfStage.get(ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Approval_Stage__c);
        rtpRequest.UsageInd = ApttusGenerateQuoteController.objQuote.Web_Visible__c ? 'W_Y' : 'W_N';
        rtpRequest.Pmnttrms = (String) ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Payment_Term__c;
        rtpRequest.OrdReason = (String) ApttusGenerateQuoteController.objQuote.Quote_Type__c == 'Direct Field Services' || (String) ApttusGenerateQuoteController.objQuote.Quote_Type__c == 'Indirect Field Services' ? 'ZBS' : 'ZOP';

        if(rtpRequest.OrdReason == TEXTZOP)
        {
            ilib_LogEvent.message('Quote is not Direct Field Service or Indirect Field Service');
            if(ApttusGenerateQuoteController.objQuote.Discount_Reason__c == STRDONATION)
            {
                rtpRequest.OrdReason = 'ZDO'; //DCP-47078
            }
            ilib_LogEvent.emit();
        }

        //null check on id below
        // make it as single contact
        // promo code from quote object
        if(String.isNotBlank(ApttusGenerateQuoteController.objQuote.Promotion_JSON__c) && !ApttusGenerateQuoteController.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
            lstPromoWrapper = (List<PromotionWrapper>) System.JSON.deserialize(ApttusGenerateQuoteController.objQuote.Promotion_JSON__c, List<PromotionWrapper>.class);
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

        Contact objCon = new Contact();
        if(ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Primary_Contact__c != null){
            objCon = new ContactsSelector().selectContacts(new Set<Id>{(String)ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Primary_Contact__c})[0];
            ilib_LogEvent.message('Contact1-->'+ objCon);
            rtpRequest.ZdName = objCon.name== null ?'': objCon.name;
            rtpRequest.ZdTelephone = objCon.phone == null ? '' : objCon.phone;
            rtpRequest.ZdEmail = objCon.email==null ? '' : objCon.email;
        }

        RealtimePricingRequest.Line objTextLine = new RealtimePricingRequest.Line();
        objTextLine.TextId = 'ZQ09';
        objTextLine.TextLine = '';

        rtpRequest.NAVHDRTOTXT.add(objTextLine);

        //DCP-37888 For generate large cart
        CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
        List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});

        RealtimePricingRequest.Line objTextLineAsync  = new RealtimePricingRequest.Line();
        objTextLineAsync.TextId = TEXTIDZLQT;
        objTextLineAsync.TextLine = '';
        if(lstQuoteLineItem.size() > Integer.valueOf(objCodeParam[0].Value__c))
        {
            if(ApttusGenerateQuoteController.objQuote.Last_Validation_Id__c == null) {
                ApttusGenerateQuoteController.objQuote.Last_Validation_Id__c = 0;
            }
            objTextLineAsync.TextLine = 'X|'+ ApttusGenerateQuoteController.objQuote.Last_Validation_Id__c + '-' + strQuoteID+'|generate';
        }
        rtpRequest.NAVHDRTOTXT.add(objTextLineAsync);

        objTextLine = new RealtimePricingRequest.Line();
        objTextLine.TextId = 'ZQ19';
        String strJunk='[delegate=';
        String strBaseUrl= String.valueOf(System.URL.getSalesforceBaseUrl());
        if(strBaseUrl.contains(strJunk)&&strBaseUrl.contains(']')) {
            strBaseUrl = strBaseUrl.substring(strBaseUrl.indexOf(strJunk)+strJunk.length(),strBaseUrl.lastIndexOf(']'));
        }

        objTextLine.TextLine = strBaseUrl+ '/'+ (String) ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Opportunity__c;

        rtpRequest.NAVHDRTOTXT.add(objTextLine);

        //added for DCP-25194
        objTextLine = new RealtimePricingRequest.Line();
        objTextLine.TextId = 'ZPPM';
        String strPPM = ApttusGenerateQuoteController.objQuote.Post_Pricing_Message__c;
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
            'SB' => 'Inventory_Location_ERP_Number__c' // DCP-46257
        };

        List<User> objUser = new UsersSelector().selectUserEmployeeNoById(new Set<Id>{(String)ApttusGenerateQuoteController.objQuote.Prepared_by__c});
        for (String strRole : roleToPartnerField.keySet()) {
            RealtimePricingRequest.SalesPartner objPartner = new RealtimePricingRequest.SalesPartner();
            if(strRole == STRING_SE)
            {
                //String strPartner = roleToPartnerField.get(strRole);
                objPartner.PartnRole = strRole;
                if(!objUser.isEmpty()){
                    objPartner.PartnNumb = objUser[0].EmployeeNumber;
                }
            }

            else if(strRole == 'ZD' && ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Primary_Contact__c != null)
            {
                //String strPartner = roleToPartnerField.get(strRole);
                objPartner.PartnRole = strRole;
                objPartner.PartnNumb = dummyPartner;
            }
            else if(strRole != 'SE' && strRole != 'ZD')
            {
                String strPartner = roleToPartnerField.get(strRole);
                objPartner.PartnRole = strRole;
                Object objPartnerNumber = ApttusGenerateQuoteController.objQuote.get(strPartner);
                objPartner.PartnNumb = (objPartnerNumber == null ? null : String.valueOf(objPartnerNumber));
            }
            if(String.isNotBlank(objPartner.PartnNumb)) {
                rtpRequest.NAVHDRTOPRT.add(objPartner);
            }
        }

        Map<String,Map<String,string>> internalPicklistToExternalPicklist =  utilsSettings.getCustomMetadataPicklistMap('Apttus_Proposal__Proposal_Line_Item__c','ERP',true);
        Integer intConfigNumber = 1;
        //DCP-28284 - To Store FixedBundleSKU LI Number on Components
        Map<Decimal,String> lineItemNumberToName = new Map<Decimal,String>();

        Set<Id> existingSub = new Set<Id>();
        for(Apttus_Proposal__Proposal_Line_Item__c objCartLine: lstQuoteLineItem) {
            if(String.isNotBlank(objCartLine.Existing_Subscription__c) && objCartLine.Existing_Subscription__c != null) {
                existingSub.add(objCartLine.Existing_Subscription__c);
            }
        }

        List<Apttus_Config2__OrderLineItem__c> lstOrderLineItems = new ApttusOrderLineItemsSelector().fetchLinesByIds(existingSub);
        Map<Id, String> mapExistingSubToZuoraSub = new Map<Id, String>();
        for(Apttus_Config2__OrderLineItem__c oli: lstOrderLineItems) {
            mapExistingSubToZuoraSub.put(oli.Id, oli.Zuora_Subscription_ID__c);
        }
        //added as part of cmcm1482   
        Map<String, Map<String,String>> toPopulateTradeInIndicator = UtilsSettings.getCustomMetadataPicklistMap('Apttus_Proposal_Proposal_Line_Item_c', 'ERP', true);

        for(Apttus_Proposal__Proposal_Line_Item__c objCartLine: lstQuoteLineItem)
        {
            //DCP-28284 - To Store FixedBundleSKU LI Number on Components
            if(objCartLine.Apttus_QPConfig__OptionId__c == null &&  objCartLine.Apttus_Proposal__Product__r.Material_Class_Type__c == Label.FixedBundleMatClassType) {
                lineItemNumberToName.put(objCartLine.Apttus_QPConfig__LineNumber__c,objCartLine.Name);
            }
            objCartLine.Applied_Discount_Details__c = '';
            ApttusGenerateQuoteController.lineNameToLineItem.put(objCartLine.name,objCartLine);
            RealtimePricingRequest.LineItem objLine = new RealtimePricingRequest.LineItem();
            RealtimePricingRequest.TextItem objTextItem = new RealtimePricingRequest.TextItem(); //DCP - 31269
            //Decimal decQuantity = objCartLine.Apttus_QPConfig__Quantity2__c;
            objLine.TargetQty = String.valueOf(objCartLine.Apttus_QPConfig__Quantity2__c);

            //DCP-25190 : Demo program and DCP-43354 Reagent Rental
            objLine.Cstcndgrp1 = String.valueOf(objCartLine.Program_Type__c) == Label.Demo_Program ? 'Y' : null;

            objLine.Cstcndgrp4 = String.valueOf(objCartLine.Program_Type__c) == Label.OpportunityTypeRentalReagent ? 'RR' : null;

            objLine.Material = (objCartLine.Apttus_QPConfig__OptionId__c == null ? objCartLine.Material_Number__c : objCartLine.Apttus_QPConfig__OptionId__r.Material_Number__c);
            objLine.SapItmNumber = objCartLine.ERP_Line_Number__c == null ? null : objCartLine.ERP_Line_Number__c.split('_')[1];
            objLine.ZzapPosnr = objCartLine.name;
            objLine.Zzbundleid = objCartLine.Apttus_Proposal__Product__r.Bundle_Id__c;

            //Added for DCP-28284 - Sending FixedBundleSKU LI Number on Components
            objLine.ZzapPosnrHgLvl = objCartLine.Apttus_QPConfig__OptionId__c == null? null : lineItemNumberToName.get(objCartLine.Apttus_QPConfig__LineNumber__c);
            Datetime dtStartDate = (Datetime)objCartLine.Apttus_QPConfig__StartDate__c;
            String strStartDate = '\\'+'/Date(' + String.valueOf((dtStartDate == null ? dateNow : dtStartDate.getTime())) + ')'+'\\'+'/';
            objLine.ContractStart = strStartDate;
            Datetime dtEndDate = (Datetime)objCartLine.Apttus_QPConfig__EndDate__c;
            String strEndDate = '\\'+'/Date(' + String.valueOf((dtEndDate == null ? dateNow : dtEndDate.getTime())) + ')'+'\\'+'/';
            objLine.ContractEnd = strEndDate;

            // DCP - 23079
            objline.Zzsceqnr = objCartLine.Equipment_Id__c;
            //DCP-46276
            objLine.Sernr = String.isBlank(objCartLine.Serial_Number__c) ? objCartLine.Serial_Number__c : objCartLine.Serial_Number__c.replace(',',';');

            // DCP - 31269
            objLine.RefDocItm = objCartLine.Previous_ERP_Contract_Line_Number__c;
            objLine.Region = objCartLine.Instance_Region__c;
            objLine.DomainUrl = objCartLine.Domain_Name__c;
            objLine.RefDoc = objCartLine.Previous_ERP_Contract_Number__c;
            objLine.ZZSOFTWAREID = objCartLine.Registrant_Contact__r.Email;
            objLine.Pguid = objCartLine.Registrant_Contact__r.PGUID__c;
            objLine.OnlineFlg = objCartLine.Is_Dragen__c?objCartLine.Server_Connectivity__c : null;
            objLine.LicenseFlag = (objCartLine.Is_Dragen__c?objCartLine.Custom_License_Setup_Required__c : objCartLine.Custom_Setup_Required__c)?'X' : '';
            objTextItem.ZzapPosnr = objCartLine.name;
            objTextItem.TextId = 'ZLFG';
            objTextItem.TextLine = String.isNotBlank(objCartLine.Custom_Licensing_Description__c)?objCartLine.Custom_Licensing_Description__c : '';

            objLine.BillFreq = internalPicklistToExternalPicklist.get('Apttus_QPConfig__BillingFrequency__c').get(objCartLine.Apttus_QPConfig__BillingFrequency__c);
             //Added as part of CMCM-1482 AC5b        
             objLine.TradeInIndicator=toPopulateTradeInIndicator?.get('Trade_In_Type__c')?.get(objCartLine.Trade_In_Type__c);
           
            rtpRequest.NAVITMTOTXT.add(objTextItem); // DCP -31269
            // DCP - 31776
            if(objCartLine.Product_Family__c == Label.InformaticsFamilyPartek)  {
                ilib_LogEvent.message('Subscription = ' + mapExistingSubToZuoraSub.get(objCartLine.Existing_Subscription__c));
                objLine.ZzAddonFlag = 'P';
            }
            else if(mapExistingSubToZuoraSub.containsKey(objCartLine.Existing_Subscription__c)) {
                ilib_LogEvent.message('Subscription = ' + mapExistingSubToZuoraSub.get(objCartLine.Existing_Subscription__c));
                objLine.ZzAddonFlag = 'X';
            }
            if(objCartLine.Renewal_Subscription__c) { objLine.ZzRenewFlag = 'X'; }

             //DCP-46872
             objLine.ZzsvmxOrd = String.isBlank(ApttusGenerateQuoteController.objQuote.Work_Order__c) ? null : ApttusGenerateQuoteController.objQuote.Work_Order__r.Name;
             //End of DCP-46872

            //Added for DCP-28284 - To send Fixed Bundle SKU
            if(objCartLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_QPConfig__LineType__c == STRING_CART_LINE_TYPE && objCartLine.Apttus_Proposal__Product__r.Material_Class_Type__c==Label.FixedBundleMatClassType){
                rtpRequest.NAVHDRTOITM.add(objLine);
            }
            else if(!(objCartLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == 'Bundle' && objCartLine.Apttus_QPConfig__LineType__c == STRING_CART_LINE_TYPE)){
                rtpRequest.NAVHDRTOITM.add(objLine);
            }

            /****************************/
            // Beadchip and Project id
            /***************************/
            if (String.isnotBlank(objCartLine.Beadchip_Part_Number__c) || ApttusGenerateQuoteController.boolConsortia) // DCP-45251 - Beadchip Soft Warning and Consortia Product Enhancement
            {
                rtpRequest = updateJSONForBeadchip(intConfigNumber, objCartLine, rtpRequest);
            }

            /****************************/
            // Consortia related field
            /***************************/
            if (ApttusGenerateQuoteController.boolConsortia)
            {
                RealtimePricingRequest.Values objLineValues1 = new RealtimePricingRequest.Values();
                objLineValues1.Charc = 'SPECIESNAME';
                // INC0197802
                String strSpecies = (String) ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Opportunity__r.Consortium__r.Species__c;
                strSpecies = strSpecies.replaceAll('[^a-zA-Z0-9 ]', '');
                objLineValues1.Value = String.isNotBlank(strSpecies) && strSpecies.length()>30?strSpecies.substring(0,29):strSpecies;
                objLineValues1.ConfigId = String.valueOf(intConfigNumber);
                objLineValues1.InstId = String.valueOf(intConfigNumber);
                if(String.isNotBlank(ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Opportunity__r.Consortium__r.Species__c)) {
                    rtpRequest.NAVHDRTOCFGSVAL.add(objLineValues1);
                }

                RealtimePricingRequest.Values objLineValues2 = new RealtimePricingRequest.Values();
                objLineValues2.Charc = 'SPECIESCATEGORY';
                //INC0197802
                String strConsortiumName = (String) ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Opportunity__r.Consortium__r.Name;
                strConsortiumName = strConsortiumName.replaceAll('[^a-zA-Z0-9 ]', '');
                objLineValues2.Value = String.isNotBlank(strConsortiumName) && strConsortiumName.length()>30?strConsortiumName.substring(0,29):strConsortiumName;
                objLineValues2.ConfigId = String.valueOf(intConfigNumber);
                objLineValues2.InstId = String.valueOf(intConfigNumber);
                if(String.isNotBlank(ApttusGenerateQuoteController.objQuote.Apttus_Proposal__Opportunity__r.Consortium__r.Name)) {
                    rtpRequest.NAVHDRTOCFGSVAL.add(objLineValues2);
                }
            }

            /****************************/
            // Discount Pricing COndition
            /***************************/
            //DCP-23566 Allow 0$ Story
            RealtimePricingRequest.Condition objLineConditionYD04 = new RealtimePricingRequest.Condition();
            objLineConditionYD04.CondType = 'YD04';
            objLineConditionYD04.ZzapPosnr = objCartLine.name;

            if(ApttusGenerateQuoteController.objQuote.Quote_Sub_Type__c == system.label.OpportunityTypeCustomProductFirstBuy){
                objLineConditionYD04.CondValue = String.isNotBlank(String.valueOf(objCartLine.Apttus_QPConfig__AdjustmentAmount__c)) ? String.valueOf(objCartLine.Apttus_QPConfig__AdjustmentAmount__c) :'0';
                objLineConditionYD04.Calctypcon = objCartLine.Apttus_QPConfig__AdjustmentType__c == 'Discount Amount' ? 'N':'A';
            } else {
                objLineConditionYD04.CondValue = String.isNotBlank(String.valueOf(objCartLine.Sales_Discretionary_Discount__c)) ? String.valueOf(objCartLine.Sales_Discretionary_Discount__c) :'0';
                objLineConditionYD04.Calctypcon = objCartLine.Sales_Discretionary_Type__c == 'Discount Amount' ? 'N':'A';
            }

            if(ApttusGenerateQuoteController.objQuote.Direct_Sale_to_Ultimate_Consignee__c)
            {
                rtpRequest.NAVHDRTOCND.add(objLineConditionYD04);
            }
            else
            {
                ilib_LogEvent.message('tsting -- '+ objLineConditionYD04);

                if(!(objCartLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_QPConfig__LineType__c == STRING_CART_LINE_TYPE)){
                    if(String.isNotBlank(objLineConditionYD04.CondValue)) {
                        rtpRequest.NAVHDRTOCND.add(objLineConditionYD04);
                    }
                }
                //For DCP-28284
                if(objCartLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_QPConfig__LineType__c == STRING_CART_LINE_TYPE && objCartLine.Apttus_Proposal__Product__r.Material_Class_Type__c==Label.FixedBundleMatClassType){
                    if(String.isNotBlank(objLineConditionYD04.CondValue)) {
                        rtpRequest.NAVHDRTOCND.add(objLineConditionYD04);
                    }
                }
            }

            RealtimePricingRequest.Condition objLineCondition3 = new RealtimePricingRequest.Condition();
            objLineCondition3.ZzapPosnr = String.valueOf(objCartLine.name);
            objLineCondition3.CondType = 'YCO1';
            // DCP-24500

            if(ApttusGenerateQuoteController.boolConsortia){
                objLineCondition3.CondValue =String.valueof(objCartLine.Max_Samples_Allowed_Per_kit__c * objCartLine.Price_per_sample__c);
            }else if(objCartLine.Price_Override__c != null && objCartLine.Price_Override__c != 0){
                objLineCondition3.CondValue= String.valueOf(objCartLine.Price_Override__c);
            }else if(ApttusGenerateQuoteController.objQuote.Direct_Sale_to_Ultimate_Consignee__c && (objCartLine.Price_Override__c == null || objCartLine.Price_Override__c == 0)){
                objLineCondition3.CondValue = String.Valueof(objCartLine.List_Price__c);
            }

            objLineCondition3.Calctypcon = 'N';
            if(ApttusGenerateQuoteController.boolConsortia){
                 objLineCondition3.ReasonForPriceOverride = System.Label.OpportunityTypeConsortium;
            }else if(String.isNotBlank(objCartLine.Reason_For_Price_Override__c)){
                objLineCondition3.ReasonForPriceOverride = objCartLine.Reason_For_Price_Override__c;
            }else if(ApttusGenerateQuoteController.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                objLineCondition3.ReasonForPriceOverride = 'Direct Sales To UC';
            }

            if(!(objCartLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_QPConfig__LineType__c == STRING_CART_LINE_TYPE)){
                if(String.isNotBlank(objLineCondition3.CondValue)) {
                    rtpRequest.NAVHDRTOCND.add(objLineCondition3);
                }
            }

            RealtimePricingRequest.Condition objLineCondition4 = new RealtimePricingRequest.Condition();
            objLineCondition4.ZzapPosnr = String.valueOf(objCartLine.name);
            objLineCondition4.CondType = 'YMUP';
            objLineCondition4.CondValue = String.valueOf(objCartLine.Customer_Premium_Amount_Per_Unit__c);
            objLineCondition4.Calctypcon = 'N';
            // condition added to skip Sku product
            if(!(objCartLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_QPConfig__LineType__c == STRING_CART_LINE_TYPE)){
                if(String.isNotBlank(objLineCondition4.CondValue)) {
                    rtpRequest.NAVHDRTOCND.add(objLineCondition4);
                }
            }
            if(ApttusGenerateQuoteController.objQuote.Direct_Sale_to_Ultimate_Consignee__c){
                RealtimePricingRequest.Condition objLineCondition5 = new RealtimePricingRequest.Condition();
                objLineCondition5.ZzapPosnr = String.valueOf(objCartLine.name);
                objLineCondition5.CondType = 'YDNT';
                objLineCondition5.CondValue = String.valueOf(objCartLine.Distributor_Specific_Price__c);
                objLineCondition5.Calctypcon = 'N';
                // condition added to skip Sku product
                if(!(objCartLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_QPConfig__LineType__c == STRING_CART_LINE_TYPE)){
                    if(String.isNotBlank(objLineCondition5.CondValue)) {
                        rtpRequest.NAVHDRTOCND.add(objLineCondition5);
                    }
                }
            }

			//DCP-25322, Adding condition for Manual rebate
            // DCP-52031 Changing Manual Rebate to Manual Rebate PEr Unit to be sent to SAP
            if(ApttusGenerateQuoteController.objQuote.Direct_Sale_to_Ultimate_Consignee__c)
            {
                RealtimePricingRequest.Condition objLineCondition5 = new RealtimePricingRequest.Condition();
                objLineCondition5.ZzapPosnr = String.valueOf(objCartLine.name);
                objLineCondition5.CondType = 'YB01';
                if(objCartLine.Manual_Rebate_Per_Unit__c != null){
                    objLineCondition5.CondValue = String.valueOf(objCartLine.Manual_Rebate_Per_Unit__c);
                }else{
                    objLineCondition5.CondValue = '';
                }
                objLineCondition5.Calctypcon = 'C';
                // condition added to skip Sku product
                if(!(objCartLine.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && objCartLine.Apttus_QPConfig__LineType__c == STRING_CART_LINE_TYPE)){
                    if(String.isNotBlank(objLineCondition5.CondValue)) {
                        rtpRequest.NAVHDRTOCND.add(objLineCondition5);
                    }
                }
            }

            intConfigNumber = intConfigNumber + 1;

        }

        if(isSendQuote){    // adding quote url to request if any file exist in quote
            Set<id> setContentDocumetId = new Set<id>();
            List<ContentDocumentLink> lstObjConDoc = (list<ContentDocumentLink>)new ContentDocumentLinksSelector().selectByQuoteId(new set<ID>{strQuoteID});
            for(ContentDocumentLink objConDoc:lstObjConDoc){
                setContentDocumetId.add(objConDoc.ContentDocumentId);
            }

            if(!setContentDocumetId.isEmpty()){
                // query the content version id and create url
                //sample url format-/services/data/v44.0/sobjects/ContentVersion/0682F0000008H7iQAE/VersionData
                list<ContentVersion>lstContentVersion=new ContentVersionsSelector().selectByContentDocumentId(setContentDocumetId);
                if(!lstContentVersion.isEmpty()){
                string url='/services/data/v44.0/sobjects/ContentVersion/'+lstContentVersion[0].id+'/VersionData';
                rtpRequest.FileContent=url;
                }
            }
        }
        strJSON = JSON.serialize(rtpRequest);
        ilib_LogEvent.message('@@@@request-'+strJSON);

        ilib_LogEvent.pop();
        return strJSON;
    }

    /*
     * Update rtpRequest parameters if Beadchip is not blank
     */
    private static RealtimePricingRequest updateJSONForBeadchip(Integer intConfigNumber, Apttus_Proposal__Proposal_Line_Item__c objCartLine, RealtimePricingRequest rtpRequest)
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
        rtpRequest.NAVHDRTOCFGSVAL.add(objLineValues);

        return rtpRequest;
    }

}
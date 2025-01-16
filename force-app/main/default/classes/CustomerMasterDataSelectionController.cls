/**
 * @author Akshay Mohan 
 * @date   30-Aug-2018
 * @description    Controller class for custom component which let's user select and search Ship To and Bill To
 * Modification Log:
 *    @Test Class for above 90% coverage.
 *    @Test Class for atleast 75% coverage.
        TestCustomerMasterDataSelectionCntrl
 *  -----------------------------------------------------------------------------------------------------------------
 *  Developer                Date                Description                                                 
 *  Akshay Mohan             30-Aug-2018         Original
 *  Akshay Mohan             26-Sep-2018         DCP-12464 sales area verification for Bill To
 *  Rahul Sharma             27-Sep-2018         DCP-12045 Changes to Ship To 
 *  Akshay Mohan             08-Oct-2018         DCP-13556 sales area verification for Distributor
 *  Akshay Mohan             15-Nov-2018         DCP-17025 sales area query change for indirect
 *  Rahul Sharma             15-Nov-2018         DCP-12852 Update Transaction Sales Area on Ship To Change
 *  Akshay Mohan             09-Apr-2018         DCP-24588 Allow search for payers
 *  Govind Dubey             06-Aug-2019         INC0196974 set quote's payment terms from payer rather than bill to
 *  Roopal Verma             11-Nov-2019         DCP-28541 added condition for default bill to/ ship to
 *  Joshith K                27-Nov-2019         INC0235038 update Sold To Organization value
 *  Todd                     16-Mar-2020         INC0255438 when sold to picked as bill to, use it as the payer as well
 *  Todd                     18-May-2020         INC0266720 same as INC0255438 but for distributor
 *  Todd                     01-Sep-2020         INC0283133 take override into account for indirect
 *  Bharath Varma            09-Mar-2021         DCP-25251: Added logic to retrieve page size from CustomMetaData
 *  Akshay Mohan             02-July-2021        DCP-46226: Add Payment Term Override logic
 *  Jitesh Lakhwani          6-July-2022         Code Scan fixes of Comments
 *  Nesar Mohan              20-July-2021        DCP-54279: Consolidate Bill To and Ship To into a single tab
 *  Vaka Vishal Reddy        22-Aug-2022         CMSI-216 Instrumentation
 *  Adithi Acharya           31-Oct-2022         DCP-56437 : Removal of Rejected Quote Stage
 *  Parthasarathy D        30-Oct-2022        DCP-56265 : Updated the method SaveSelection.
 *  -----------------------------------------------------------------------------------   
*/
public with sharing class CustomerMasterDataSelectionController {

    private static final String LOG_TITLE = 'CMD Selection Controller';

    private static final String BAN_ICON = 'utility:ban';
    private static final String CHECK_ICON = 'utility:check';                                                               //DCP-28541 check icon
    private static final String CODEPARAMETERNAME = 'BillTo_ShipTo_PageSizes';
    public static final String STRING_PROPOSALS = 'Proposals';
    public static final String STRING_EXCEPTION = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';

    /**
     * @description: CustomerMasterDataSelectionWrapper wrapper class store Customer data.
     * @param : None
     * @return : None
    */
    public class CustomerMasterDataSelectionWrapper {

        public String strName,strAddress,strCity,strState,strZip,strCountry,strPaymentTerms,strCountryCode
                        ,strASA,strRelationship,strAccountGroup,strERP,strRecordId,strIcon,strCareOf,strChkIcon;            //DCP-28541 strChkIcon, strDefault
        public Boolean strDefault, isVisible;

        /**
        * @description: CustomerMasterDataSelectionWrapper wrapper class Constructor to set Customer master data values.
        */
        public CustomerMasterDataSelectionWrapper(Customer_Master_Data__c objCMD) {
            setValues(objCMD);
        }

        /**
        * @description: CustomerMasterDataSelectionWrapper wrapper class Constructor to set Customer master data and account relationship values.
        * @param : None
        * @return : None
        */
        public CustomerMasterDataSelectionWrapper(Account_Relationship__c objRelationship){
            setValues(objRelationship.Account_Sales_Area__r.Customer_Master_Data__r);
            strRelationship = objRelationship.Relationship__c;
            strDefault = objRelationship.Default_Partner__c;                                                                        //DCP-28541
            this.strASA = objRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c;
            strPaymentTerms = objRelationship.Account_Sales_Area__r.Term_Of_Payment__c;
            this.strChkIcon = (strDefault ? CHECK_ICON : null); 
        }

        /**
        * @description: CustomerMasterDataSelectionWrapper wrapper class Constructor to set Customer master data values.
        * @param : strRelationship, strASA, strPaymentTerms, strDefault
        * @return : None
        */
        public CustomerMasterDataSelectionWrapper(String strRelationship, String strASA, String strPaymentTerms, Boolean strDefault) {
            this.strRelationship = strRelationship;
            this.strASA = strASA;
            this.strPaymentTerms = strPaymentTerms;
            this.strDefault = strDefault;                                                                                    //DCP-28541
            this.isVisible = false;
        }

        /**
        * @description: CustomerMasterDataSelectionWrapper wrapper class 'setValue' method to set field values. It is used by constructor
        * of the CustomerMasterDataSelectionWrapper class.        
        * @param : Customer_Master_Data__c objCMD
        * @return : None
        */
        public void setValues(Customer_Master_Data__c objCMD) {
            ilib_LogEvent.message('objCMD : '+objCMD);
            this.strRecordId = objCMD.Id;
            this.strName = objCMD.Name;
            this.strAddress = objCMD.Street__c;
            this.strCity = objCMD.City__c;
            this.strZip = objCMD.Zip_Postal_Code__c;
            this.strCountry = objCMD.Country__c;
            this.strState = objCMd.State_Province__c;
            this.strAccountGroup = objCMd.Account_Group__c;
            this.strERP = objCMD.ERP_Customer_Id__c;
            this.strCountryCode = objCMD.Country_Code__c;
            this.strCareOf = objCMD.Care_Of__c;
            this.isVisible = false;
        }

        /**
         * @description: 'ERP Account Sales Area Id' is not blank OR it is not equals to expected value strIcon value will be populated for Bill to account.
         * @param : String strASA
         * @return : None 
        */
        public void setIconBillTo(String strASA) {
            ilib_LogEvent.message('strASA : '+strASA);
            this.strIcon = (String.isBlank(this.strASA) || AutomateBillToShipToService.getSalesAreaFromERP(this.strASA) != strASA) 
                ? BAN_ICON
                : null;
        }

        /**
         * @description: Based on the country Ship To Icon will be populated.
         * @return : None 
         * @param : String strASA
        */
        public void setIconShipTo(String strCountry) {
            ilib_LogEvent.message('strCountry + '+strCountry);
            this.strIcon = (strCountry != this.strCountry)
                ? BAN_ICON
                : null;
        }
    }

    private static Map<String,String> getPageSize() {
        ilib_LogEvent.push(LOG_TITLE+'.getPageSize()');
        Map<String,String> pageSizes = new Map<String,String>();
        CodeParametersSelector codeParamSelector = new CodeParametersSelector();
        List<Code_Parameter__mdt> cPRMetaData = codeParamSelector.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME}); 
        if(!cPRMetaData.isEmpty()) {
            pageSizes.put('desktop', cPRMetaData[0].Value__c.split(':')[0]);
            pageSizes.put('mobile', cPRMetaData[0].Value__c.split(':')[1]);
        }
        ilib_LogEvent.info('pageSizes : '+pageSizes);
        ilib_LogEvent.pop();
        return pageSizes;


    }


    /*
    *  @author       : Akshay Mohan
    *  @description  : To Initialize the variables
    *  @param        : String strQuoteId
    *  @param        : String strType for Bill To or Ship To
    *  @return       : String
    */
    @AuraEnabled
    public static String loadPage(String strQuoteId,String strType)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.loadPage()');
        
        ilib_LogEvent.info('strQuoteId: ' + strQuoteId);
        ilib_LogEvent.info('strType: ' + strType);

        Apttus_Proposal__Proposal__c objProposal = new ApttusProposalsSelector().selectByQuoteId(new Set<Id> {strQuoteId}).get(0);
        ilib_LogEvent.info('objProposal: ' + JSON.serialize(objProposal));

        String strRecordTypeName = objProposal.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName;
        Boolean booDirectDeal = Opportunities.DIRECT_RECORD_TYPES.contains(strRecordTypeName);
        ilib_LogEvent.info('booDirectDeal: ' + booDirectDeal);

        String strOpportunityStage = objProposal.Apttus_Proposal__Opportunity__r.StageName;
        Boolean booClosedOpportunity = Opportunities.CLOSED_STATUSES.contains(strOpportunityStage);
        ilib_LogEvent.info('booClosedOpportunity: ' + booClosedOpportunity);

        String strQuoteStage = objProposal.Apttus_Proposal__Approval_Stage__c;
        String strApprovalStatus = objProposal.Apttus_QPApprov__Approval_Status__c;
        Boolean booAppReqQuote = (Label.QuoteStageApprovalRequired.equals(strQuoteStage) && Label.QuotationApprovalStatusNotSubmitted.equals(strApprovalStatus));
        ilib_LogEvent.info('booAppReqQuote: ' + booAppReqQuote);

        Boolean booInReview = Label.QuoteStageInReview.equals(strQuoteStage);
        ilib_LogEvent.info('booInReview: ' + booInReview);

        Boolean booApproved = Label.QuotationApprovalStatusApproved.equals(strQuoteStage);
        ilib_LogEvent.info('booApproved: ' + booApproved);

        Boolean booGenerated = Label.QuoteStageGenerated.equals(strQuoteStage);
        ilib_LogEvent.info('booGenerated: ' + booGenerated);

        Boolean booPresented = Label.QuoteStagePresented.equals(strQuoteStage);
        ilib_LogEvent.info('booPresented: ' + booPresented);

        Boolean booAccepted = Label.QuoteStageAccepted.equals(strQuoteStage);
        ilib_LogEvent.info('booAccepted: ' + booAccepted);

        Boolean booInvalidQuote = objProposal.Invalid_Quote__c;
        ilib_LogEvent.info('booInvalidQuote: ' + booInvalidQuote);

        String strUCCountry = objProposal.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountry;

        Boolean booShipToByDistributor = !booDirectDeal && !objProposal.Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c;
        Set<String> setAccounts = new Set<String>();
        Set<String> setASAERP = new Set<String>();
        String strSalesArea;

        if (CustomerMasterDatas.GROUP_BILL_TO.equals(strType))
        {
            setAccounts.add(objProposal.Apttus_Proposal__Opportunity__r.Account.ERP_Customer_Id__c); // sold to
            setASAERP.add(objProposal.Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c);
            strSalesArea = objProposal.Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c;
        }
        else
        {
            setAccounts.add(objProposal.Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.ERP_Customer_Id__c);
            setASAERP.add(objProposal.Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c);

            if (!booDirectDeal)
            {
                setAccounts.add(objProposal.Apttus_Proposal__Opportunity__r.Distributor__r.ERP_Customer_Id__c);
                setASAERP.add(objProposal.Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c);            
            }

            if (booShipToByDistributor)
                strSalesArea = objProposal.Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c;
            else
                strSalesArea = objProposal.Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c;           
        }
        ilib_LogEvent.info('setAccounts: ' + setAccounts);

        Boolean booSetIconShipTo = CustomerMasterDatas.GROUP_SHIP_TO.equals(strType) && booDirectDeal;

        Set<String> setPayerASAERP = new Set<String>();
        for (Account_Relationship__c objRelationship : new AccountRelationshipsSelector().selectByAccountERPSARelationship(setAccounts, setASAERP, new List<String> {CustomerMasterDatas.GROUP_PAYER}))
        {
            setPayerASAERP.add(objRelationship.Related_ERP_Customer_Id__c + '_' + AutomateBillToShipToService.getSalesAreaFromERP(objRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c));
        }

        Map<String, String> payerErpASAToPaymentTerm = new Map<String,String>();
        for (Account_Sales_Area__c objASA : new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(setPayerASAERP))
        {
            payerErpASAToPaymentTerm.put(objASA.ERP_Account_Sales_Area_Id__c, AutomateBillToShipToService.getPaymentTermOverride(objProposal.Apttus_Proposal__Opportunity__r,objASA.Term_Of_Payment__c));//DCP-46226
        }
        ilib_LogEvent.info('-----payerErpASAToPaymentTerm:'+payerErpASAToPaymentTerm);

        Map<String, CustomerMasterDataSelectionWrapper> cmdERPIdToWrapper = new Map<String, CustomerMasterDataSelectionWrapper>();
        Set<String> setRelatedERPs = new Set<String>();
        CustomerMasterDataSelectionWrapper objWrap;

        for (Account_Relationship__c objRelationship : new AccountRelationshipsSelector().selectByAccountERPSARelationship(setAccounts, setASAERP, new List<String>{strType}))
        {
            if (objRelationship.Account_Sales_Area__r.Customer_Master_Data__r!= null &&
                objRelationship.Related_ERP_Customer_Id__c == objRelationship.Account_Sales_Area__r.Customer_Master_Data__r.ERP_Customer_Id__c)
            {
                objWrap = new CustomerMasterDataSelectionWrapper(objRelationship);
            }
            else
            {
                setRelatedERPs.add(objRelationship.Related_ERP_Customer_Id__c);
                objWrap = new CustomerMasterDataSelectionWrapper(
                    objRelationship.Relationship__c,
                    objRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c,
                    payerErpASAToPaymentTerm.get(objRelationship.Related_ERP_Customer_Id__c + '_' + AutomateBillToShipToService.getSalesAreaFromERP(objRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c)),
                    objRelationship.Default_Partner__c                                    //DCP-28541 Addeed Default condition
                );
            }
            cmdERPIdToWrapper.put(objRelationship.Related_ERP_Customer_Id__c, objWrap);

            if (booSetIconShipTo)
                objWrap.setIconShipTo(strUCCountry);
        }   
        ilib_LogEvent.info('setRelatedERPs: ' + setRelatedERPs);
        ilib_LogEvent.info('cmdERPIdToWrapper: '+cmdERPIdToWrapper);

        if (CustomerMasterDatas.GROUP_SHIP_TO.equals(strType) && !booDirectDeal)
        {
            strSalesArea = objProposal.Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c;  
        }
        ilib_LogEvent.info('strSalesArea: '+strSalesArea);
        
        if (!setRelatedERPs.isEmpty())
        {
            for (Customer_Master_Data__c objCMD : new CustomerMasterDataSelector().selectByAccountERPId(setRelatedERPs))
            {
                objWrap = cmdERPIdToWrapper.get(objCMD.ERP_Customer_Id__c);
                objWrap.setValues(objCMD);
                if (booSetIconShipTo)
                    objWrap.setIconShipTo(strUCCountry);
            }
        }

        String strSalesAreaCropped = AutomateBillToShipToService.getSalesAreaFromERP(strSalesArea);
        String strDisclaimer = 'Bill To cannot be selected as it has not been extended to '
            + strSalesAreaCropped
            + '. Please create Master Data Request for extension on '
            + objProposal.Apttus_Proposal__Opportunity__r.Account.Name
            + '.'
        ;

        Map<String, String> strPageSizes = getPageSize();
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return '{"lstDirect": ' + JSON.serialize(cmdERPIdToWrapper.values())
                + ',"mapLabels": ' + JSON.serialize(getMappedLabels(strType, strDisclaimer))
                + ',"booDirectDeal": ' + JSON.serialize(booDirectDeal)
                + ',"booClosedOpportunity": ' + JSON.serialize(booClosedOpportunity)
                + ',"booInvalidQuote": ' + JSON.serialize(booInvalidQuote)
                + ',"booApproved": ' + JSON.serialize(booApproved)
                + ',"booGenerated": ' + JSON.serialize(booGenerated)
                + ',"booPresented": ' + JSON.serialize(booPresented)
                + ',"booAccepted": ' + JSON.serialize(booAccepted)
                + ',"booInReview": ' + JSON.serialize(booInReview)
                + ',"strUCCountry": ' + JSON.serialize(strUCCountry)
                + ',"booAppReqQuote": ' + JSON.serialize(booAppReqQuote)
                + ',"strSalesArea": ' + JSON.serialize(strSalesAreaCropped)
                + ',"strPageSizes": ' + JSON.serialize(strPageSizes)
            +'}';
    }

    private static Map<String, String> getMappedLabels(String strType, String strDisclaimer)
    {
        ilib_LogEvent.push(LOG_TITLE+'.getMappedLabels()');
        Map<String, String> mapLabels = new Map<String ,String>();
        mapLabels.put('AccountRelationshipShipTo', CustomerMasterDatas.GROUP_SHIP_TO);
        mapLabels.put('AccountRelationshipBillTo', CustomerMasterDatas.GROUP_BILL_TO);
        mapLabels.put('AccountGroupSoldTo', CustomerMasterDatas.GROUP_SOLD_TO);
        mapLabels.put('AccountGroupPayer', CustomerMasterDatas.GROUP_PAYER);
        if (CustomerMasterDatas.GROUP_BILL_TO.equals(strType))
            mapLabels.put('UI_Label_CMD_Selection', Label.UI_Label_CMD_Selection_Select_Bill_To);
        else
            mapLabels.put('UI_Label_CMD_Selection', Label.UI_Label_CMD_Selection_Select_Ship_To);
        mapLabels.put('UI_Label_CMD_Selection_Search_Bill_To', Label.UI_Label_CMD_Selection_Search_Bill_To);
        mapLabels.put('UI_Label_CMD_Selection_Search_Ship_To', Label.UI_Label_CMD_Selection_Search_Ship_To);
        mapLabels.put('UI_Button_CMD_Selection_Save_Related_Bill_To', Label.UI_Button_CMD_Selection_Save_Related_Bill_To);
        mapLabels.put('UI_Button_CMD_Selection_Save_Related_Ship_To', Label.UI_Button_CMD_Selection_Save_Related_Ship_To);
        mapLabels.put('UI_Button_CMD_Selection_Save_Searched_Bill_To', Label.UI_Button_CMD_Selection_Save_Searched_Bill_To);
        mapLabels.put('UI_Button_CMD_Selection_Save_Searched_Ship_To', Label.UI_Button_CMD_Selection_Save_Searched_Ship_To);
        mapLabels.put('UI_Label_No_Results', Label.UI_Label_No_Results);
        mapLabels.put('UI_ErrorMessage_Select_Record', Label.UI_ErrorMessage_Select_Record);
        mapLabels.put('UI_Label_Save_Success', Label.UI_Label_Save_Success);
        mapLabels.put('UI_ErrorMessage_RestrictQuoteOnClosedOpportunity', Label.UI_ErrorMessage_RestrictQuoteOnClosedOpportunity);
        mapLabels.put('UI_ErrorMessage_Direct_Ship_To_Invalid_Country', Label.UI_ErrorMessage_Direct_Ship_To_Invalid_Country);
        mapLabels.put('UI_ErrorMessage_QuoteInAccepted_BillTo', Label.UI_ErrorMessage_QuoteInAccepted_BillTo);
        mapLabels.put('UI_ErrorMessage_QuoteInReview_BillTo', Label.UI_ErrorMessage_QuoteInReview_BillTo);
        mapLabels.put('UI_ErrorMessage_QuoteInApproved_ShipTo', Label.UI_ErrorMessage_QuoteInApproved_ShipTo);
        mapLabels.put('UI_ErrorMessage_QuoteInReview_ShipTo', Label.UI_ErrorMessage_QuoteInReview_ShipTo);
        mapLabels.put('UI_ErrorMessage_QuoteInAccepted_ShipTo', Label.UI_ErrorMessage_QuoteInAccepted_ShipTo);
        mapLabels.put('UI_ErrorMessage_QuoteInAccepted', Label.UI_ErrorMessage_QuoteInAccepted); //DCP-54279
        mapLabels.put('UI_ErrorMessage_QuoteInReview', Label.UI_ErrorMessage_QuoteInReview);     //DCP-54279
        mapLabels.put('QuoteStageDraft', Label.QuoteStageDraft);
        mapLabels.put('QuoteApprovalStatusNone', Label.QuoteApprovalStatusNone);
        mapLabels.put('QuotationApprovalStageApproved', Label.QuotationApprovalStatusApproved);
        mapLabels.put('QuoteStageGenerated', Label.QuoteStageGenerated);
        mapLabels.put('QuoteStagePresented', Label.QuoteStagePresented);
        mapLabels.put('QuoteStageInReview', Label.QuoteStageInReview);
        mapLabels.put('QuoteStageApproved', Label.QuotationApprovalStatusApproved);
        mapLabels.put('QuoteStageAccepted', Label.QuoteStageAccepted);
        mapLabels.put('QuoteStageApprovalRequired', Label.QuoteStageApprovalRequired);
        mapLabels.put('UI_InvalidQuoteError', Label.UI_InvalidQuoteError);
        mapLabels.put('UI_Disclaimer', strDisclaimer);
        mapLabels.put('UI_ErrorMessage_Refine_Search', Label.UI_ErrorMessage_Refine_Search);

        ilib_LogEvent.info('mapLabels : '+mapLabels);
        ilib_LogEvent.pop();
        return mapLabels;
    }

    /*
    *  @author       : Akshay Mohan
    *  @description  : To Initialize the variables
    *  @param        : String strQuoteId //Added for DCP-46226
    *  @param        : List<String> lstDirectCMDIds
    *  @param        : String strType for Bill To or Ship To
    *  @param        : Boolean booDirectDeal flag to indicate direct or indirect deal
    *  @param        : String strName User entered name which needs to be searched
    *  @param        : String strUCCountry Country of the Ultimate Consignee
    *  @param        : String strSalesArea Sales Area Code
    *  @return       : String
    */
    @AuraEnabled
    public static String searchIndirectCMD(String strQuoteId,List<String> lstDirectCMDIds, String strType, Boolean booDirectDeal, String strName, String strUCCountry, String strSalesArea)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.searchIndirectCMD()');
        
        //DCP-46226: Start - Get quote details
        Apttus_Proposal__Proposal__c objProposal = new ApttusProposalsSelector().selectByQuoteId(new Set<Id> {strQuoteId}).get(0);
        ilib_LogEvent.info('objProposal: ' + JSON.serialize(objProposal));
        //DCP-46226: End - Get quote details

        ilib_LogEvent.info('lstDirectCMDIds: ' + lstDirectCMDIds);
        ilib_LogEvent.info('strType: ' + strType);
        ilib_LogEvent.info('booDirectDeal: ' + booDirectDeal);
        ilib_LogEvent.info('strName: ' + strName);
        ilib_LogEvent.info('strUCCountry: ' + strUCCountry);
        ilib_LogEvent.info('strSalesArea: ' + strSalesArea);

        Map<String, List<List<String>>> typeToAccountGroups = new Map<String, List<List<String>>>();
        //add bill to group for direct
        //DCP-24588 add payer in search results
        List<String> lstGroups = new List<String>{CustomerMasterDatas.GROUP_BILL_TO, CustomerMasterDatas.GROUP_SOLD_TO, CustomerMasterDatas.GROUP_PAYER};
        typeToAccountGroups.put(CustomerMasterDatas.GROUP_BILL_TO, new List< List<String> >{lstGroups});
        //add bill to group for indirect
        //DCP-24588 add payer in search results
        lstGroups = new List<String>{CustomerMasterDatas.GROUP_BILL_TO, CustomerMasterDatas.GROUP_SOLD_TO, CustomerMasterDatas.GROUP_DISTRIBUTOR, CustomerMasterDatas.GROUP_PAYER};
        typeToAccountGroups.get(CustomerMasterDatas.GROUP_BILL_TO).add(lstGroups);
        
        //add ship to group for direct
        lstGroups = new List<String>{CustomerMasterDatas.GROUP_SOLD_TO, CustomerMasterDatas.GROUP_ULTIMATE_CONSIGNEE, CustomerMasterDatas.GROUP_SHIP_TO};
        typeToAccountGroups.put(CustomerMasterDatas.GROUP_SHIP_TO, new List< List<String> >{lstGroups});
        //add ship to group for indirect
        lstGroups = new List<String>{CustomerMasterDatas.GROUP_SHIP_TO, CustomerMasterDatas.GROUP_SOLD_TO, CustomerMasterDatas.GROUP_DISTRIBUTOR, CustomerMasterDatas.GROUP_ULTIMATE_CONSIGNEE};
        typeToAccountGroups.get(CustomerMasterDatas.GROUP_SHIP_TO).add(lstGroups);

        lstGroups = booDirectDeal ? typeToAccountGroups.get(strType)[0] : typeToAccountGroups.get(strType)[1];
        ilib_LogEvent.info('lstGroups: ' + lstGroups);

        Boolean booSetIconShipTo = CustomerMasterDatas.GROUP_SHIP_TO.equals(strType) && booDirectDeal;
        Boolean booSetIconBillTo = CustomerMasterDatas.GROUP_BILL_TO.equals(strType);

        Set<String> setAccounts = new Set<String>(lstDirectCMDIds);

        Map<String, CustomerMasterDataSelectionWrapper> cmdERPIdToWrapper = new Map<String, CustomerMasterDataSelectionWrapper>();
        CustomerMasterDataSelectionWrapper objWrap;

        for (Customer_Master_Data__c objCMD : new CustomerMasterDataSelector().
                                                    selectByAccountGroupExceptIds(setAccounts,lstGroups,strName) ){
            objWrap = new CustomerMasterDataSelectionWrapper(objCMD);
            if (booSetIconBillTo)
                objWrap.setIconBillTo(strSalesArea);    
            if (booSetIconShipTo)
                objWrap.setIconShipTo(strUCCountry);
            cmdERPIdToWrapper.put(objCMD.ERP_Customer_Id__c, objWrap);
        }

        if (CustomerMasterDatas.GROUP_BILL_TO.equals(strType))
        {
            Set<String> setPayerASAERP = new Set<String>(); 
            for (Account_Sales_Area__c objASA : new AccountSalesAreaSelector().selectASAByCMDERP(cmdERPIdToWrapper.keySet(),strSalesArea))
            {
                setPayerASAERP.add(objASA.ERP_Account_Sales_Area_Id__c);
            }

            Map<String, String> payerErpASAToPaymentTerm = new Map<String, String>();
            for (Account_Sales_Area__c objASA : new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(setPayerASAERP))
            {
                payerErpASAToPaymentTerm.put(objASA.ERP_Account_Sales_Area_Id__c,AutomateBillToShipToService.getPaymentTermOverride(objProposal.Apttus_Proposal__Opportunity__r,objASA.Term_Of_Payment__c));//DCP-46226
            }
            ilib_LogEvent.info('---payerErpASAToPaymentTerm' + payerErpASAToPaymentTerm);
            ilib_LogEvent.info('Found ERPs: ' + cmdERPIdToWrapper.keySet());

            for (Account_Relationship__c objRelationship : new AccountRelationshipsSelector().selectByCMDERPWithASA(cmdERPIdToWrapper.keySet(),strSalesArea))
            {
                objWrap = cmdERPIdToWrapper.get(objRelationship.ERP_Customer_Id__c);
                objWrap.strASA = objRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c;
                if (CustomerMasterDatas.GROUP_PAYER.equals(objRelationship.Relationship__c))
                    objWrap.strPaymentTerms = payerErpASAToPaymentTerm.get(objRelationship.Related_ERP_Customer_Id__c+'_'+AutomateBillToShipToService.getSalesAreaFromERP(objRelationship.Account_Sales_Area__r.ERP_Account_Sales_Area_Id__c));
                if (booSetIconBillTo)
                    objWrap.setIconBillTo(strSalesArea);
            }
        }

        ilib_LogEvent.info('cmdERPIdToWrapper: ' + cmdERPIdToWrapper);
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return JSON.serialize(cmdERPIdToWrapper.values());
    }

    /*
    *  @author       : Akshay Mohan
    *  @description  : To save selection
    *  @param        : String strQuoteJSON
    *  @param        : String strJSON of selection
    *  @param        : String booDirect
    *  @param        : Boolean strType
    *  @param        : String strASA
    *  @return       : String
    */
    @AuraEnabled
    public static String saveSelection(String strQuoteJSON, String strJSONBillTo, String strJSONShipTo, String strType, Boolean booDirectDeal, String strASA)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.saveSelection()');

        ilib_LogEvent.info('strQuoteJSON: '+strQuoteJSON);
        ilib_LogEvent.info('strJSONBillTo: '+strJSONBillTo);
        ilib_LogEvent.info('strJSONShipTo: '+strJSONShipTo);
        ilib_LogEvent.info('strType: '+strType);
        ilib_LogEvent.info('booDirectDeal: '+booDirectDeal);
        ilib_LogEvent.info('strASA: '+strASA);
        // DCP-56265 changes.
        CustomerMasterDataSelectionWrapper objWrapBillTo = strJSONBillTo != null ? (CustomerMasterDataSelectionWrapper) JSON.deserialize(strJSONBillTo, CustomerMasterDataSelectionWrapper.class) : null;
        CustomerMasterDataSelectionWrapper objWrapShipTo = strJSONShipTo != null ? (CustomerMasterDataSelectionWrapper) JSON.deserialize(strJSONShipTo, CustomerMasterDataSelectionWrapper.class) : null;
        ilib_LogEvent.info('objWrapBillTo: ' + objWrapBillTo);
        ilib_LogEvent.info('objWrapShipTo: ' + objWrapShipTo);
        
        Apttus_Proposal__Proposal__c objProposal = (Apttus_Proposal__Proposal__c) JSON.deserialize(strQuoteJSON, Apttus_Proposal__Proposal__c.class);
        Apttus_Proposal__Proposal__c objProposalCurrent = new ApttusProposalsSelector().selectByQuoteId(new Set<Id> {objProposal.Id})[0];

        String errorMessage = '';
        if(objWrapShipTo != null) {
            errorMessage = saveShipToSelection(objProposal, objProposalCurrent, objWrapShipTo, booDirectDeal);
        }         
        if(objWrapBillTo != null) {
            saveBillToSelection(objProposal, objProposalCurrent, objWrapBillTo, strASA);
        }   

        ilib_LogEvent.info('Final objProposal: ' + JSON.serialize(objProposal));  
        Database.SaveResult saveResultObj =   Database.update(objProposal,false);        
        String dmlErrormsg;
        String errorMessageToDisplay = System.Label.UI_System_Error;         
        if (!saveResultObj.isSuccess() && saveResultObj.getErrors().size() > 0) {
            ApexExceptions.emitSaveErrors(new List<Database.SaveResult>{saveResultObj}, STRING_PROPOSALS);
            if(saveResultObj.getErrors()[0].getMessage().contains(STRING_EXCEPTION)) {
                dmlErrormsg = saveResultObj.getErrors()[0].getMessage().substringAfter(STRING_EXCEPTION+',');
            } else {
                dmlErrormsg = errorMessageToDisplay;
            }     
            if(!String.isBlank(errorMessage)) {
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();                
                return dmlErrormsg+';'+errorMessage;               
            }
            else {
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return dmlErrormsg;
            }              
        } 
        else if(!String.isBlank(errorMessage)) {
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return errorMessage;
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return 'Success';
    }

    private static String saveShipToSelection(Apttus_Proposal__Proposal__c objProposal, Apttus_Proposal__Proposal__c objProposalCurrent, CustomerMasterDataSelectionWrapper objWrap, Boolean booDirectDeal)
    {
        ilib_LogEvent.push(LOG_TITLE + '.saveShipToSelection()');

        List<Sales_Area__mdt> lstSalesArea = new SalesAreasSelector().selectSalesArea(new Set<String>{objWrap.strCountryCode});
        if (lstSalesArea.isEmpty()||String.isBlank(objWrap.strCountryCode))
        {
            ilib_LogEvent.pop();
            return Label.UI_ErrorMessage_CMD_Selection_Sales_Area_Country_Missing;
        }

        Sales_Area__mdt objSalesArea = lstSalesArea[0];
        if (!booDirectDeal) // indirect opportunity
        {
            objSalesArea.Distribution_Channel__c = '02';
            // INC0283133 - take override into account for indirect
            if (String.isNotBlank(objProposalCurrent.Apttus_Proposal__Opportunity__r.Sales_Org_Override__c))
            {
                objSalesArea.Sales_Organization__c = objProposalCurrent.Apttus_Proposal__Opportunity__r.Sales_Org_Override__c;
            }
            ilib_LogEvent.info('objSalesArea: ' + objSalesArea);

            List<Account_Sales_Area__c> lstSalesAreas = new AccountSalesAreaSelector()
                .selectAccountSaleaAreaByAccount(objProposalCurrent.Apttus_Proposal__Opportunity__r.Distributor__c, objSalesArea);
            if (lstSalesAreas.isEmpty())
            {
                ilib_LogEvent.pop();
                return Label.UI_ErrorMessage_CMD_Selection_Indirect_Ship_To_Sales_Area;
            }

            //INC0235038
            if (String.isBlank(objProposalCurrent.Apttus_Proposal__Opportunity__r.Sales_Org_Override__c))
            {
                objProposal.Sold_To_Sales_Organization__c = objSalesArea.Sales_Organization__c; 
                objProposal.Inco_Term_1__c = lstSalesAreas[0].Inco_Term_1__c;
            }
            else
            {
                objProposal.Sold_To_Sales_Organization__c = objProposalCurrent.Apttus_Proposal__Opportunity__r.Sales_Org_Override__c;

                String strASAERP = objWrap.strERP + '_' +
                    objProposal.Sold_To_Sales_Organization__c +
                    objSalesArea.Distribution_Channel__c +
                    objSalesArea.Division__c;
                ilib_LogEvent.info('strASAERP: ' + strASAERP);

                List<Account_Sales_Area__c> lstSalesAreasInDirect = new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(new Set<String>{strASAERP});
                ilib_LogEvent.info('1. Indirect List AccountSalesAres ' + lstSalesAreasInDirect);

                if (!lstSalesAreasInDirect.isEmpty())
                    objProposal.Inco_Term_1__c = lstSalesAreasInDirect[0].Inco_Term_1__c;
            }
            objProposal.Sold_To_Distribution_Channel__c = objSalesArea.Distribution_Channel__c;
            objProposal.Sold_To_Division__c = objSalesArea.Division__c;
        }
        else // direct opportunity
        {
            String strASAERP;
            if (String.isBlank(objProposalCurrent.Apttus_Proposal__Opportunity__r.Sales_Org_Override__c))
            {
                strASAERP = objWrap.strERP + '_' +
                    objSalesArea.Sales_Organization__c +
                    objSalesArea.Distribution_Channel__c +
                    objSalesArea.Division__c;
            }
            else
            {
                objProposal.Sold_To_Sales_Organization__c = objProposalCurrent.Apttus_Proposal__Opportunity__r.Sales_Org_Override__c;
                strASAERP = objWrap.strERP + '_' +
                    objProposal.Sold_To_Sales_Organization__c +
                    objSalesArea.Distribution_Channel__c +
                    objSalesArea.Division__c;
            }
            ilib_LogEvent.info('strASAERP: ' + strASAERP);

            List<Account_Sales_Area__c> lstSalesAreas = new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(new Set<String>{strASAERP});
            ilib_LogEvent.info('1. List AccountSalesAres ' + lstSalesAreas);

            if (!lstSalesAreas.isEmpty())
                objProposal.Inco_Term_1__c = lstSalesAreas[0].Inco_Term_1__c;
        }

        ilib_LogEvent.pop();
        return '';
    }

    private static void saveBillToSelection(Apttus_Proposal__Proposal__c objProposal, Apttus_Proposal__Proposal__c objProposalCurrent, CustomerMasterDataSelectionWrapper objWrap, String strASA)
    {
        ilib_LogEvent.push(LOG_TITLE + '.saveBillToSelection()');

        // if the user selected a CMD that is a sold to or distributor
        // use that selection as the payer
        // but get the terms from the sold to specified on the opportunity
        if (objWrap.strAccountGroup == Accounts.GROUP_SOLD_TO || objWrap.strAccountGroup == Accounts.GROUP_DISTRIBUTOR)
        {
            Account_Sales_Area__c objSoldToAsaWithPayer = getSalesAreaWithPayerForSoldTo(objProposalCurrent, true);

            objProposal.Payer__c = objWrap.strRecordId;
            objProposal.Apttus_Proposal__Payment_Term__c = AutomateBillToShipToService.getPaymentTermOverride(objProposalCurrent.Apttus_Proposal__Opportunity__r,objSoldToAsaWithPayer.Term_Of_Payment__c);//DCP-46226

            return;
        }

        // user selected either a bill to or a payer
        // query for payers related to selected account
        String strASAERP = objWrap.strERP + '_' + strASA;
        ilib_LogEvent.info('strASAERP: ' + strASAERP);
        List<Account_Relationship__c> lstPayerRelations = new AccountRelationshipsSelector()
            .selectByASAERPWithRelationship(new Set<String> { strASAERP }, CustomerMasterDatas.GROUP_PAYER);

        if (!lstPayerRelations.isEmpty())  // payers were found, this is a bill to or a payer
        {
            // by policy a bill to will only have one payer, payer will relate only to itself
            Account_Relationship__c objPayerRelationship = lstPayerRelations.get(0);
            ilib_LogEvent.info('Found payer: ' + JSON.serialize(objPayerRelationship));

            // query related ASA to set payment terms value on quote
            List<Account_Sales_Area__c> lstPayerASA = new AccountSalesAreaSelector()
                .selectAccountSaleaAreaByERP(new Set<String> { objPayerRelationship.Related_ERP_Customer_Id__c + '_' + strASA } );
            ilib_LogEvent.message('@@@@ inside saveSelection method, value of lstPayerASA: ' + lstPayerASA);
            objProposal.Apttus_Proposal__Payment_Term__c = AutomateBillToShipToService.getPaymentTermOverride(objProposalCurrent.Apttus_Proposal__Opportunity__r,lstPayerASA[0].Term_Of_Payment__c);//DCP-46226

            // if selected account is not characterized as a payer (i.e. it's a bill to)
            // then find the payer ID and set it
            if (!CustomerMasterDatas.GROUP_PAYER.equals(objWrap.strAccountGroup))
            {
                // if the relationship is to self (i.e. the bill to is its own payer)
                // then we have the CMD Id to use for the payer value
                if (objPayerRelationship.Related_ERP_Customer_Id__c == objPayerRelationship.Account_Sales_Area__r.Customer_Master_Data__r.ERP_Customer_Id__c)
                {
                    objProposal.Payer__c = objPayerRelationship.Account_Sales_Area__r.Customer_Master_Data__c;
                }
                // otherwise we need to query the CMD Id of the payer in the relationship
                else
                {
                    ilib_LogEvent.message('Querying CMD for different Related_ERP_Customer_Id__c');
                    for (Customer_Master_Data__c objCMD: new CustomerMasterDataSelector()
                        .selectByAccountERPId(new Set<String> { objPayerRelationship.Related_ERP_Customer_Id__c } )
                    ) {
                        objProposal.Payer__c = objCMD.Id;
                    }
                }
            }
        }
        // DCP-24588: no payers found on sales area of the selected bill to
        // get payer from the opportunity's sold to instead
        else if (!CustomerMasterDatas.GROUP_PAYER.equals(objWrap.strAccountGroup))
        {
            Account_Sales_Area__c objSoldToAsaWithPayer = getSalesAreaWithPayerForSoldTo(objProposalCurrent, false);

            objProposal.Payer__c = objSoldToAsaWithPayer.Customer_Master_Data__c;
            objProposal.Apttus_Proposal__Payment_Term__c = AutomateBillToShipToService.getPaymentTermOverride(objProposalCurrent.Apttus_Proposal__Opportunity__r,objSoldToAsaWithPayer.Term_Of_Payment__c);//DCP-46226
        }

        ilib_LogEvent.pop();
    }

    private static Account_Sales_Area__c getSalesAreaWithPayerForSoldTo(Apttus_Proposal__Proposal__c objProposalCurrent, Boolean isStartingFromSoldto)
    {
        ilib_LogEvent.push(LOG_TITLE+'.getSalesAreaWithPayerForSoldTo()');
        String salesAreaKey = objProposalCurrent.Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c;
        ilib_LogEvent.info('salesAreaKey: ' + salesAreaKey);

        List<Account_Relationship__c> lstPayerRelations = new AccountRelationshipsSelector().selectByASAERPWithRelationship(new Set<String> { salesAreaKey }, CustomerMasterDatas.GROUP_PAYER);
        Account_Sales_Area__c objSoldToAsaWithPayer;
        if (isStartingFromSoldto)
        {
            // default if there's a data problem and the self relationship is missing
            objSoldToAsaWithPayer = lstPayerRelations.get(0).Account_Sales_Area__r;
            // pick the one that is a relationship to self
            // meaning the sold to acting as its own payer, not some random payer linked to this sold to
            for (Account_Relationship__c objPayerRelationship : lstPayerRelations)
            {
                if (objPayerRelationship.Related_ERP_Customer_Id__c == objPayerRelationship.Account_Sales_Area__r.Customer_Master_Data__r.ERP_Customer_Id__c)
                objSoldToAsaWithPayer = objPayerRelationship.Account_Sales_Area__r;
                
            }
        }
        else
        {
            // by policy a bill to will only have one payer
            objSoldToAsaWithPayer = lstPayerRelations.get(0).Account_Sales_Area__r;
            
        }

        ilib_LogEvent.info('objSoldToAsaWithPayer : '+ objSoldToAsaWithPayer);
        ilib_LogEvent.pop();
        return objSoldToAsaWithPayer;
    }

}
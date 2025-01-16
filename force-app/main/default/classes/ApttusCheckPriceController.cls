/**
*    @author Govind Dubey
*    @date   2018-05-15
*    @description   To calculate Max discount for DCP-9024
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                   Description
*             Govind Dubey                25 Aug 2018               To calculate Max discount for DCP-9024
*             Pankaj Sharma               10 OCt 2018
*             Kushagra Desai              11 Nov 2018               Real Time Pricing and Quote Sync interface
*             Kushagra Desai              25-JAN-2019               Direct Sales To UC changes and Consortia
*             Satya Swain                 03 April 2019             Force user to Click on check price when cart values are changed
*             Roopal Verma                30-May-2019               DCP-25322, Validation for Manual Rebate
*             Kushagra Desai              30-May-2019               DCP-25190 : Demo program
*             Kushagra Desai              10-June-2019              DCP-25321 : Customer premium can be Zero [Validation removed]
*             Kushagra Desai              13-June-2019              DCP-25189
*             Kushagra Desai              13-June-2019              DCP-26680 : Code optimization
*             B Kamini                    24 Sep 2019               Sonar Qube Issue Fix
*             Arnab Modak                 25 Sep 2019               DCP-29853 For multiple quantity change when adding fix bundle
*             Saswati                     30 Sep 2019               DCP-28565 : Fapiao Type Code Validation
*             Arnab Modak                 01-Oct-2019               DCP-29847 : Added Validation Message at BundleSKU level
*             Joshith K                   03-Dec-2019               INC0238317- separate ProductConfiguration and line items in to differnt query variable and pass line items as extra argument to all dependent methods
*             Satya Swain                 10 Dec 2019               Sonar Qube Issue Fix
*             Rahul Bishnoi               1 Jan 2020                DCP-32794 Removed Field Software Id
*             Satya Swain                 10 Dec 2019               Sonar Qube Issue Fix  
*             Rahul Bishnoi               02-Dec-2019               INC0255210 - Do not allow discount more than 100%.
*             Arnab Modak                 21-Mar-2020               DCP-34013 - Refactored Class, validateCart() moved to ApttusCheckPriceBase class
*             Rishab Wali                 08-May-2020               DCP-34910 - Validate Cart Updation Logic
*             Rishab Wali                 07-Dec-2020               DCP-31081 Beadchip Error Soft Warning
*             Todd Newman                 17-Mar-2021               DCP-45737: add ilib logging
*             Adyasha Satapathy           06-May-2021               DCP-38809 Bypassing for Billable Flow 
*             Atit Kar                    21-March-2023             TASK0876760 - GTC Approval Rule update
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/

global with sharing class ApttusCheckPriceController extends ilib_RestReceiver {

    private static final String LOG_TITLE = 'CheckPriceController';

    public static final String CONFIGID = 'Id';
    public static final String CONFIGREQUESTID = 'configRequestId';
    public static final String FLOW = 'flow';
    public static final String BUSINESSOBJECTID = 'businessObjectId';
    public static final String PRICING_STATUS_PENDING = 'Pending';

    public static final String EMERGING_BU = 'Emerging BU'; //TASK0876760
    public static final String SOUTH_ASIA_SR = 'South Asia SR'; //TASK0876760

    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;

    public static final String INTEGRATION_NAME = 'Outgoing_Realtime_Pricing';
    public static final String STRING_DISCOUNT_AMOUNT = 'Discount Amount';
    private static final String EMAIL_TEMPLATE_NAME = 'PrePopulated_GTS_E_mail'; //DCP-48875
    private static final String QUOTATION_OWNER = 'Quotation.Number';
    private static final Set<String> FIND_REGION = new Set<String>{'Emabargo_Screening','Sanctioned_Party_List'};

    public static Boolean boolPricingError = false;
    public static Boolean boolRETError = false;
    public static Boolean boolEmbargoCheck = false;
    public static Boolean boolSanctionedPartyListCheck = false;
    public static Boolean boolLegalControl = false;
    public static Boolean boolQuoteError = false;
    public static string strRETErrors;
    public static String strRequstJSON;
    public static Apttus_Config2__ProductConfiguration__c objConfiguration;
    public static Set<String> lstFailedProducts = new Set<String>();
    public static Set<String> setToAddresses = new Set<String>();
    public static Set<String> setCcAddresses = new Set<String>();
    public static ilib_LogInterface.LogDetails log;
    public static Boolean boolConsortia;
    global String strConfigId;
    global string strConfigRequestId;
    global string strFlow;
    global String strBusinessObjectId;
    public Boolean boolHasError{get; set;}
    public String strErrorMsg{get;set;}
    public  Boolean boolValidationError;
    public Boolean boolPricingCompleted{get;set;}
    public static String strResponse;
    public Boolean boolDemoPromoAdded = false;
    //DCP-26680 : Code optimization
    public Boolean boolValidationStatus;
     //DCP-28565
    public Boolean boolFapiao{get;set;} // Added by Saswati
    public Boolean boolRedirect{get;set;} //DCP-34910 Added for Validate Cart Update
    public Boolean boolWarning{get;set;} //DCP-31081 Beadchip Error Soft Warning
    public String strWarningMessages{get;set;} //DCP-31081 Beadchip Error Soft Warning
    public String strJoinedWarningMessages{get;set;} //DCP-31081 Beadchip Error Soft Warning
    public Boolean boolShowWarningModal{get;set;} //DCP-31081 Beadchip Error Soft Warning
    public Boolean showGTSButton{get;set;} //DCP-48875 Open pre-populated GTS e-mail on GTS Validation block
    public static String strErrorType;
    public String strHref{set;get;}
    public String strBody{set;get;}
   /*Enum for Http Methods */
    public enum HttpMethod {HEAD, POST} 

    /*Wrapper Class for Exceptions */
    public class ValidateException extends Exception {}

    /**
    *  @author Govind Dubey
    *  @description Constructor of ApttusCheckPriceController
    **/
    public ApttusCheckPriceController()
    {
        // Added by Kamini to fix SonarQube issue
        this(ApexPages.CurrentPage().getParameters().get(CONFIGID) == null ? null : ApexPages.CurrentPage().getParameters().get(CONFIGID).escapeHtml4(),
                ApexPages.currentpage().getparameters().get(CONFIGREQUESTID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGREQUESTID).escapeHtml4(),
                ApexPages.currentpage().getparameters().get(FLOW) == null ? null : ApexPages.currentpage().getparameters().get(FLOW).escapeHtml4(),
                ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID) == null ? null : ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID).escapeHtml4());
    }
    /**DCP-38809
    *  @author Adyasha Satapathy
    *  @description Constructor with parameters
    **/
    public ApttusCheckPriceController(String strConfigId, String strConfigRequestId, String strFlow, String strBusinessObjectId){
        this.strConfigId = strConfigId;
        this.strConfigRequestId = strConfigRequestId;
        this.strFlow = strFlow;
        this.strBusinessObjectId = strBusinessObjectId;
        boolPricingCompleted = false;
        boolHasError = false;
        boolValidationError = false;
        boolValidationStatus = true;
        boolFapiao = false; // Added By Saswati
        boolRedirect = false; // DCP-34910
        boolWarning = false; //DCP-30181
        boolShowWarningModal = false; //DCP-31081
        showGTSButton = false; //DCP-48875
        strErrorType = '';
    }

    /**
    *  @author Govind Dubey
    *  @description Constructor of ApttusCheckPriceController
    *  @param NA
    *  @return pageReference
    **/
    global PageReference redirectToCart()
    {
        return ApttusCheckPriceBaseClass.redirectToCart(strConfigId, strConfigRequestId, strFlow, strBusinessObjectId);
    }

    /**
    *  @author Govind Dubey
    *  @description reprice cart
    *  @param NA
    *  @return void
    **/
    public void callSAP()
    {
        ilib_LogEvent.setTitle(LOG_TITLE);

        ApttusCheckPriceBaseClass baseClassInstance = new ApttusCheckPriceBaseClass();
        String validationValues = baseClassInstance.callSAP(false);
        this.boolHasError = Boolean.valueOf(validationValues.substringBefore('@'));
        this.boolFapiao = Boolean.valueOf(validationValues.substringBetween('@','_'));
        if(validationValues.contains('*'))
        {
            this.strErrorMsg = validationValues.substringBetween('_','*');
            this.boolRedirect = Boolean.valueOf(validationValues.substringAfter('*')); //DCP-34910 Added for Validate Cart Updation
        }
        else { //DCP-31081 Beadchip Soft warning Message
            this.strErrorMsg = validationValues.substringBetween('_','#');
            this.boolWarning  = Boolean.valueOf(validationValues.substringBetween('#'));
            this.strWarningMessages = validationValues.substringAfterLast('#');
        }

        if(this.boolWarning == true || this.boolFapiao == true) { this.boolShowWarningModal = true; }

        if(this.boolWarning == true && this.boolFapiao == true)
        {
            string joinedWarningMessage = '<ui> <li> ' + Label.UI_Error_Message_For_Fapiao_Type_Missing + ' </li> </ui> </br> ' + this.strWarningMessages;
            this.strJoinedWarningMessages = joinedWarningMessage;
        }
        
        else if(this.boolWarning == true && this.boolFapiao == false){ this.strJoinedWarningMessages = this.strWarningMessages; }
        
        else if(this.boolWarning == false && this.boolFapiao == true) { this.strJoinedWarningMessages = Label.UI_Error_Message_For_Fapiao_Type_Missing; }
        
        //DCP-48875 Create Outlook Popup
        createOutlookPopup();
        ilib_LogEvent.message('validationValues ----'+validationValues);
        ilib_LogEvent.message('boolWarning ----'+this.boolWarning);
        ilib_LogEvent.message('strWarningMessages ----'+this.strWarningMessages);
        ilib_LogEvent.message('strJoinedWarningMessages ----'+this.strJoinedWarningMessages);

        ilib_LogEvent.message('boolValues ----'+boolHasError);
        ilib_LogEvent.message('boolValues2 ----'+boolFapiao);
        ilib_LogEvent.message('boolValues3 ----'+strErrorMsg);

        ilib_LogEvent.emit();
        return;
    }

    /*Method - RepriceCart - Calls pricing method on Cart */
    global void repriceCart()
    {
        ilib_LogEvent.setTitle(LOG_TITLE);
        boolPricingCompleted = ApttusCheckPriceBaseClass.repriceCart(strConfigId);
        ilib_LogEvent.message('boolPricingCompleted : '+boolPricingCompleted);
        ilib_LogEvent.emit();
    }

    /* Added for update Validate Cart */
    public PageReference redirectToQuote()
    {
        PageReference pg = new PageReference('/'+ strBusinessObjectId);
        pg.setRedirect(true);
        return pg;
    }

    /**
    *  @author Dushyant Srivastava
    *  @description method fro sending out Emails
    *  @param NA
    *  @return null
    **/
    public void createOutlookPopup()
    {
        if(String.isNotBlank(strErrorType))
        {
            showGTSButton = true;
            strErrorType = strErrorType + strErrorType.remove('%');
            List<String> lstGetErrorTypes = strErrorType.split(',');
            //Get all the Region_to_Email_Mapping__mdt values. 
            ApttusProposalsSelector objProposalSelector = new ApttusProposalsSelector();
            Apttus_Proposal__Proposal__c objProposal = objProposalSelector.selectByQuotationId(new set<String>{this.strBusinessObjectId}).get(0);
            TenderRegiontoEmailSelector objTenderRegiontoEmailSelector = new TenderRegiontoEmailSelector();
            List<Region_to_Email_Mapping__mdt> lstRegionToEmailMapping = objTenderRegiontoEmailSelector.selectAllRecords(new set<String>(lstGetErrorTypes));
            strHref = 'mailto:';
            getEmailAddresses(lstRegionToEmailMapping, objProposal);
             
            if(setToAddresses.size() > 0){
                strHref +=  String.join(new List<String>(setToAddresses),';');
            }

            if(setCcAddresses.size() > 0){
                strHref += '?cc=';
                strHref += String.join(new List<String>(setCcAddresses),';');
            }
           
            EmailTemplate objEmailTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{EMAIL_TEMPLATE_NAME}).get(0);
            
            if(setCcAddresses.size() > 0)
                strHref += '&subject=' + objEmailTemplate.subject.replace(QUOTATION_OWNER,objProposal.SAP_Quote__c);
            else
                strHref += '?subject=' + objEmailTemplate.subject.replace(QUOTATION_OWNER,objProposal.SAP_Quote__c);
             strBody = objEmailTemplate.body;
            
            replaceBody(objProposal);
             //add failed products

            for(String failedProducts : lstFailedProducts)
            {
                strBody += '\n'+failedProducts+',';
            }

            strBody = strBody.contains(',') ? strBody.removeEnd(',') : strBody;
        }
    }

    /**
    *  @author Dushyant Srivastava
    *  @description method to getEmail Addresses
    *  @param Region_to_Email_Mapping__mdt record list
    *  @return null
    **/
    public void getEmailAddresses(List<Region_to_Email_Mapping__mdt> lstRegionToEmailMapping, Apttus_Proposal__Proposal__c objProposal){
        for(Region_to_Email_Mapping__mdt objRegionToEmailMapping : lstRegionToEmailMapping)
        {
            if(FIND_REGION.contains(objRegionToEmailMapping.MasterLabel.substringBeforeLast('_')))
            {
                String strType = objRegionToEmailMapping.MasterLabel.substringBeforeLast('_');
                //TASK0876760 : Start
                String strRegion = '_';
                if(Label.TerritoryRegionEUR.equals(objProposal.Apttus_Proposal__Opportunity__r.Territory_Region__c) ||
                    (Label.TerritoryRegionAMEA.equals(objProposal.Apttus_Proposal__Opportunity__r.Territory_Region__c) && EMERGING_BU.equals(objProposal.Business_Unit_Sold_To__c)
                        && !SOUTH_ASIA_SR.equals(objProposal.Sub_Region_Sold_To__c))){
                    strRegion = strRegion + Label.TerritoryRegionEUR;
                } else if(Label.TerritoryRegionAMEA.equals(objProposal.Apttus_Proposal__Opportunity__r.Territory_Region__c) && EMERGING_BU.equals(objProposal.Business_Unit_Sold_To__c)
                        && SOUTH_ASIA_SR.equals(objProposal.Sub_Region_Sold_To__c)){
                    strRegion = strRegion + Label.TerritoryRegionAMEA;
                } else {
                    strRegion = '_'+ objProposal.Apttus_Proposal__Opportunity__r.Territory_Region__c;
                }
                //TASK0876760 : End
                if(!objRegionToEmailMapping.MasterLabel.equals(strType + strRegion))
                {
                    continue;
                }
            }
            if(objRegionToEmailMapping.ToAddress__c != null){
                setToAddresses.addAll(objRegionToEmailMapping.ToAddress__c.split(';'));
            }
            if(objRegionToEmailMapping.CcAddress__c!= null){
                setCcAddresses.addAll(objRegionToEmailMapping.CcAddress__c.split(';'));
            }
        }       
    }

    /**
    *  @author Dushyant Srivastava
    *  @description method to replace Body Value
    *  @param Apttus_Proposal__Proposal__c record
    *  @return null
    **/
    public void replaceBody(Apttus_Proposal__Proposal__c objProposal){
        strBody = strBody.replace('Opportunity.Owner',objProposal.Apttus_Proposal__Opportunity__r.Owner.Name);
        strBody = objProposal.Name!= Null ? strBody.replace(QUOTATION_OWNER,objProposal.SAP_Quote__c) : strBody.replace(QUOTATION_OWNER,'');
        strBody = objProposal.Sold_To_ERP_Number__c!= Null ? strBody.replace('SoldToERP#',objProposal.Sold_To_ERP_Number__c) : strBody.replace('SoldToERP#','');
        strBody = objProposal.Sold_To_Account_Name__c!= Null ? strBody.replace('SoldtToName',objProposal.Sold_To_Account_Name__c) : strBody.replace('SoldtToName','');
        strBody = objProposal.Distributor_ERP_Number__c!= Null ? strBody.replace('DistributorToERP#',objProposal.Distributor_ERP_Number__c) : strBody.replace('DistributorToERP#','');
        strBody = objProposal.Distributor__r.Name!= Null ? strBody.replace('DistributorName',objProposal.Distributor__r.Name) : strBody.replace('DistributorName','');
        strBody = objProposal.Ultimate_Consignee_ERP_Number__c!= Null ? strBody.replace('UCToERP#',objProposal.Ultimate_Consignee_ERP_Number__c) : strBody.replace('UCToERP#','');
        strBody = objProposal.Ultimate_Consignee__r.Name!= Null ? strBody.replace('UCName',objProposal.Ultimate_Consignee__r.Name) : strBody.replace('UCName','');
        strBody = objProposal.Ship_To_ERP_Number__c!= Null ? strBody.replace('ShipToERP#',objProposal.Ship_To_ERP_Number__c) : strBody.replace('ShipToERP#','');
        strBody = objProposal.Ship_To__r.name!= Null ? strBody.replace('ShipName',objProposal.Ship_To__r.name) : strBody.replace('ShipName','');
        strBody = objProposal.Bill_To_ERP_Number__c!= Null ? strBody.replace('BillERP#',objProposal.Bill_To_ERP_Number__c) : strBody.replace('BillERP#','');
        strBody = objProposal.Bill_To__r.Name!= Null ? strBody.replace('BillName',objProposal.Bill_To__r.Name) : strBody.replace('BillName','');
        strBody = objProposal.Payer_ERP_Number__c!= Null ? strBody.replace('PayerERP#',objProposal.Payer_ERP_Number__c) : strBody.replace('PayerERP#','');
        strBody = objProposal.Payer__r.Name!= Null ? strBody.replace('PayerName',objProposal.Payer__r.Name) : strBody.replace('PayerName','');
        strBody = strBody.contains('()') ? strBody.replace('()','') : strBody;
    }
}
/**
*    @author Arnab Modak
*    @date   2020-03-15
*    @description -  DCP-34013 To refactor ApttusCheckPriceController and ApttusCheckPriceDirectUCController and put common logic in this class
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                   Description
*             Arnab Modak                 15 Mar 2020               DCP-34013 - Base class for code refactor of CheckPriceController classes
*             Arnab Modak                 01 Apr 2020               SonarCube Fixes
*             Rishab Wali                 08 May 2020               DCP-34910 - Updation for Large Carts
*             Rishab Wali                 07 Dec 2020               DCP-31081 Show soft error Beadchip Warning
*             Tapas C                     20 Jan 2020               TASK0555443
*             Todd Newman                 17-Mar-2021               DCP-45737: add ilib logging
*             KD                          5 May 2021                DCP-45742 : Adding serial number check
*             Adyasha Satapathy           07 May 2021               DCP-38809: Parametrised constructor for Billable Quote Automation
*             Ashwin Kumar                25-May-2021               INC0321438 - ApttusLineItemsSelector.selectLineItemsByConfigId param updated from Id to Set<Id>
*             KD                          24-May-2021               DCP-46276 : Added logic to display geenric message for Relocation Quote failure
*             KD                          7-June-2021               DCP-45926 : Added check for Labour and Estimate line.
*             Akshay Mohan                24-June-2021              DCP-46277: Add bypass for blanket PO
*             Adyasha                     30-July-2021              DCP-49511 : Updated error messages for DCP-45926 to warning messages
*             Rishi                       16-Feb-2022               DCP-52031 : Changing Manual Rebate to Manual Rebate Per Unit for Validation
*             Himanshu                    05-Dec-2022               INC0439986 : Show Registrant Contract Error Message.
*/

public with sharing class ApttusCheckPriceBaseClass {

    public static final String CONFIGID = 'id';
    public static final String CONFIGREQUESTID = 'configRequestId';
    public static final String FLOW = 'flow';
    public static final String BUSINESSOBJECTID = 'businessObjectId';
    public static final String PRICING_STATUS_PENDING = 'Pending';
    
    public static final String OPPORTUNITY_TYPE_CONSORTIUM = 'Consortium';
    public static final String OPPORTUNITY_TYPE_REORDER_CONSORTIUM_CONSUMABLE = 'Reorder - Consortium Consumable';
    public static final String SOLD_TO_SALES_ORGANIZATION = 'CN03';
    public static final String PRODUCT_CONFIG_TYPE_BUNDLE = 'Bundle';
    public static final String FIXED_BUNDLE_MATERIAL_CLASS_TYPE = 'Combination';
    public static final String DISTRIBUTION_CHANNEL_INDIRECT = 'Indirect';
    public static final String DEMO_PROGRAM = 'Demo Program';
    public static final String LINE_TYPE_PRODUCT_SERVICE = 'Product/Service';

    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public static HttpResponse response = new HttpResponse();

    public static final String INTEGRATION_NAME = 'Outgoing_Realtime_Pricing';
    public static final String STRING_DISCOUNT_AMOUNT = 'Discount Amount';
    public static final String PRICE_METHOD_FLAT_PRICE = 'Flat Price';
    public static final String SAVEDSTATUS = 'Saved';

    public static final String PREMIUM = '% Premium';  //DGP-24

    public static Boolean boolPricingError = false;
    public static Boolean boolRETError = false;
    public static Boolean boolEmbargoCheck = false;
    public static Boolean boolSanctionedPartyListCheck = false;
    public static Boolean boolLegalControl = false;
    public static List<String> lstInstrumentCompliance = new List<String>();
    public static List<String> lstRegulatoryMedicalDevice = new List<String>();
    public static Boolean boolQuoteError = false;
    public static string strRETErrors;
    public static String strRequstJSON;
    public static Apttus_Config2__ProductConfiguration__c objConfiguration;
    public static ilib_LogInterface.LogDetails log;
    public static Boolean boolConsortia;
    public static String strConfigId;
    public static string strConfigRequestId;
    public static string strFlow;
    public static String strBusinessObjectId;
    public Boolean boolHasError{get; set;}
    public static String strErrorMsg{get;set;}
    public static Boolean boolValidationError;
    public static Boolean boolError;
    public static Boolean boolPricingCompleted{get;set;}
    public static String strResponse;
    public static Boolean boolDemoPromoAdded = false;
    public Boolean boolValidationStatus;
    public static Boolean boolFapiao{get;set;}
    public static final String CODEPARAMETERNAME = 'Real_Time_Pricing_Threshold_Value'; //DCP-34910 Validate Cart Update
    public static Boolean boolWarning = false;  //DCP-31081 Show soft error Beadchip Warning
    public static String strWarningMsgs = ''; //DCP-31081 Show soft error Beadchip Warning
    public static String strHtmlLineTagStart = '<li>';//CodeScan Fix
    public static String strHtmlLineTagEnd = '</li>';//CodeScan Fix
    // DCP-45926
    public static final String CODE_PARAMETER_LABOUR_CODE = 'Labour_Product_Codes';
    public static final String CODE_PARAMETER_TRAVEL_CODE = 'Travel_Product_Codes';

    /*Enum for Http Methods */
    public enum HttpMethod {HEAD, POST}
    /*Wrapper Class for Exceptions */
    public class ValidateException extends Exception {}

    /* Class Constructor */
    public ApttusCheckPriceBaseClass() {
        
        strConfigId = ApexPages.CurrentPage().getParameters().get(CONFIGID) == null ? null : ApexPages.CurrentPage().getParameters().get(CONFIGID).escapeHtml4();
        strConfigRequestId = ApexPages.currentpage().getparameters().get(CONFIGREQUESTID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGREQUESTID).escapeHtml4();
        strFlow = ApexPages.currentpage().getparameters().get(FLOW) == null ? null : ApexPages.currentpage().getparameters().get(FLOW).escapeHtml4();
        strBusinessObjectId = ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID) == null ? null : ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID).escapeHtml4();
        boolPricingCompleted = false;
        boolHasError = false;
        boolValidationError = false;
        boolValidationStatus = true;
        boolFapiao = false; 
    }

    /* Parametrised Class Constructor for Billable Flow --> DCP:38809 */
    public ApttusCheckPriceBaseClass(Id prodconfigId)
    {
        strConfigId = prodconfigId;
        boolHasError = false;
        boolValidationError = false;
        boolValidationStatus = true;
        boolFapiao = false; 
    }

    /* Method to redirect the user to cart. */
    public static PageReference redirectToCart(String strConfigId, String strConfigRequestId, String strFlow, String strBusinessObjectId)
    {
        PageReference cartPage = Page.Apttus_Config2__Cart;

        cartPage.getParameters().put(CONFIGID, strConfigId);
        cartPage.getParameters().put(CONFIGREQUESTID, strConfigRequestId);
        cartPage.getParameters().put(FLOW, strFlow);
        cartPage.getParameters().put(BUSINESSOBJECTID, strBusinessObjectId);

        return cartPage;
    }

    /* Method to set Pricing fields as per logic */
    private void setConsortiaPricing(List<Apttus_Config2__LineItem__c> lstLineItems)
    {
        for(Apttus_Config2__LineItem__c soLineItem : lstLineItems)
        {
            Decimal decTotalListPrice;
            Decimal decUnitPrice;
            Decimal decQuantity= soLineItem.Apttus_Config2__PriceMethod__c == PRICE_METHOD_FLAT_PRICE ? 1 : soLineItem.Apttus_Config2__Quantity__c;
            if(soLineItem.Max_Samples_Allowed_Per_kit__c!=null && soLineItem.Price_per_sample__c != null && decQuantity!=null){
            decUnitPrice = soLineItem.Max_Samples_Allowed_Per_kit__c * soLineItem.Price_per_sample__c;
            decTotalListPrice = decUnitPrice * decQuantity;
            }
            soLineItem.Total_List_Price__c = decTotalListPrice;
            soLineItem.Unit_Price__c = decUnitPrice;
        }
    }

    /* Method to call SAP. */
    public String callSAP(Boolean isDirectUC)
    {
        ilib_LogEvent.push('callSAP');

        try
        {
            ilib_RestInterface.InterfaceDetails interfaceDetails;
            
            if(isDirectUC){
                ApttusCheckPriceDirectUCController instantiatedDirectUC = new ApttusCheckPriceDirectUCController();
                if(ValidateQuoteAutomation.boolIsQuoteAutomated){
                    instantiatedDirectUC = new ApttusCheckPriceDirectUCController(strConfigId,null,null,null);
                }else{
                    instantiatedDirectUC = new ApttusCheckPriceDirectUCController();
                }
                interfaceDetails = instantiatedDirectUC.interfaceDetails;
            }
            else{
                //DCP-38809: Start
                ApttusCheckPriceController instantiated;
                if(ValidateQuoteAutomation.boolIsQuoteAutomated){
                    instantiated = new ApttusCheckPriceController(strConfigId,null,null,null);
                }else{
                    instantiated = new ApttusCheckPriceController();
                }
                    
                //DCP-38809: End
                interfaceDetails = instantiated.interfaceDetails;
            }

            ilib_LogEvent.message('calling Reprice Cart');
            set<id> setConfigIds = new Set<id>{strConfigId};
            objConfiguration = new ApttusProductConfigurationsSelector().selectConfigWithLines(setConfigIds)[0];
            List<Apttus_Config2__LineItem__c> lstLineItems = new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id>{objConfiguration.id}); //INC0321438
            boolConsortia = (objConfiguration.Apttus_QPConfig__Proposald__r.Quote_Sub_Type__c==OPPORTUNITY_TYPE_CONSORTIUM || objConfiguration.Apttus_QPConfig__Proposald__r.Quote_Sub_Type__c==OPPORTUNITY_TYPE_REORDER_CONSORTIUM_CONSUMABLE);

            boolValidationError = validateCart(objConfiguration, lstLineItems, isDirectUC);
            ilib_LogEvent.message('---boolValidationError-->'+boolValidationError);
            ilib_LogEvent.message('error Msg : '+strErrorMsg);

            if(!boolValidationError){
                ilib_LogEvent.message('boolConsortia :'+boolConsortia);
                ilib_LogEvent.message('sub type  :'+objConfiguration.Apttus_QPConfig__Proposald__r.Quote_Sub_Type__c);
                ilib_LogEvent.message('Label :'+OPPORTUNITY_TYPE_CONSORTIUM);
                /*******************************/
                /*  Consortia Pricing manually */
                /*******************************/
                if(boolConsortia) { setConsortiaPricing(lstLineItems); }
                /*******************************/
                /*  Consortia Pricing ENDS */
                /*******************************/
                if(!isDirectUC){
                    strRequstJSON = RealtimePricingRequestGenerator.createJSON(objConfiguration, lstLineItems);
                    log = ilib_LogInterface.initiateLog(interfaceDetails, strRequstJSON);
                    ilib_LogEvent.message('@@@ RTP Request ' + strRequstJSON);

                    CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
                    List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
                    if(test.isRunningTest()) { objCodeParam[0].Value__c = '0' ;}
                    if(lstLineItems.size() < Integer.valueOf(objCodeParam[0].Value__c))
                    {
                        response = ApttusSAPConnector.getPrice(strRequstJSON,isDirectUC);
                        checkResponse(response,isDirectUC,strBusinessObjectId,log,objConfiguration);
                    }
                    else //DCP-34910 Async Validation Check
                    { 
                        getResponse(strRequstJSON,strBusinessObjectId,log,objConfiguration);
                        if(test.isRunningTest())
                        {
                            boolHasError = false;
                        }

                        if(!boolHasError)
                        {
                            updateProductConfig(objConfiguration,SAVEDSTATUS);
                            String timeDiff = objCodeParam[0].PickListValue__c.substringBefore(':');
                            Integer timeDifference = Integer.valueOf(timeDiff) * -1 ;
                            updateQuotation(strBusinessObjectId,true,timeDifference);
                            ilib_LogEvent.pop();
                            return String.valueOf('false@false_NoError*true');
                        }
                        else
                        {
                            //update quote Validation in progress to false
                            updateQuotation(strBusinessObjectId,false,0);    
                        }
                    }
                }
                else {
                    strRequstJSON = RealtimePricingRequestDirectUC.createJSONForDirectUC(objConfiguration, lstLineItems);
                    log = ilib_LogInterface.initiateLog(interfaceDetails, strRequstJSON);
                    ilib_LogEvent.message('@@@ RTP Request ' + strRequstJSON);
                    response = ApttusSAPConnector.getPrice(strRequstJSON,isDirectUC);
                    checkResponse(response,isDirectUC,strBusinessObjectId,log,objConfiguration);
                    ilib_LogEvent.message('@@@ RTP response ' + response);
                }
            }
        }
        catch(Exception e)
        {
            //CMSI-2 removed setLogLevelError and replaced message to error
            ilib_LogEvent.error('Error at line        : ' + e.getLineNumber());
            ilib_LogEvent.error('The following exception has occurred:++++getMessage+++ ' + e.getMessage());
            ilib_LogEvent.error('Exception type caught : ' + e.getTypeName());
            ilib_LogEvent.error('Cause                 : ' + e.getCause());
            ilib_LogEvent.error('Stack trace           : ' + e.getStackTraceString());


            if(log != null){
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, e.getLineNumber() +'-'+ e.getMessage()+'-'+ e.getTypeName()+'-'+ e.getCause() +'-'+ e.getStackTraceString(), strBusinessObjectId);
                if(!isDirectUC) { ApexExceptions.emit('ApttusCheckPriceController',log.logRecordId,e); } 
                else { ApexExceptions.emit('ApttusCheckPriceDirectUCController',log.logRecordId,e); }       
            }
            else{
                if(!isDirectUC) { ApexExceptions.emit('ApttusCheckPriceController',strBusinessObjectId,e); }
                else { ApexExceptions.emit('ApttusCheckPriceDirectUCController',strBusinessObjectId,e); }
            }
            boolHasError=true;
            strErrorMsg = Label.UI_Error_Contact_Admin;
        }

        if (!boolHasError && log != null)
        {
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, strResponse, strBusinessObjectId);
        }

        //returning boolHasError, boolFapiao, strErrorMsg {DCP-31081 Beadchip soft warning}
        ilib_LogEvent.pop();
        if (isDirectUC)
            return String.valueOf(boolHasError)+'_'+strErrorMsg;
        else
            return String.valueOf(boolHasError)+'@'+String.valueOf(boolFapiao)+'_'+strErrorMsg+'#'+boolWarning+'#'+strWarningMsgs;
    }

    /* Method to reprice cart */
    public static boolean repriceCart(String strConfigId)
    {
        ilib_LogEvent.push('repriceCart');

        Apttus_CpqApi.CPQ.UpdatePriceRequestDO updatePriceRequestDOSO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
        updatePriceRequestDOSO.CartId = strConfigId;
        Apttus_CpqApi.CPQ.UpdatePriceResponseDO updatePriceResponseDOSO = Apttus_CpqApi.CPQWebService.updatePriceForCart(updatePriceRequestDOSO);
        boolPricingCompleted = !updatePriceResponseDOSO.IsPricePending;

        ilib_LogEvent.pop();
        return boolPricingCompleted;
    }

    @TestVisible
    private Boolean validateCart(Apttus_Config2__ProductConfiguration__c objConfiguration, List<Apttus_Config2__LineItem__c> lstLineItems, Boolean isDirectUC)
    {
        ilib_LogEvent.push('callSAP');
        strErrorMsg = '';
        //DCP-25190 - Demo program validation//
        if (!isDirectUC && (String.isNotBlank(objConfiguration.Promo_Name_1__c) || String.isNotBlank(objConfiguration.Promo_Name_2__c) || String.isNotBlank(objConfiguration.Promo_Name_3__c)))
            boolDemoPromoAdded = true;

        Apttus_Config2.CustomClass.ValidationResult result;
        result = Test.isRunningTest() ? new Apttus_Config2.CustomClass.ValidationResult(boolValidationStatus) : Apttus_Config2.CPQWebService.validateCart(objConfiguration.Id) ;

        if (!result.isSuccess || (Test.isRunningTest() && !boolValidationStatus))
        {
            ilib_LogEvent.message('---- IF PART---');
            String strErrorMessage = '';
            boolHasError = true;
            if(Test.isRunningTest()) { result.Messages.add(new ApexPages.Message(ApexPages.Severity.Error, 'Test Class Running')); }
                
            for(ApexPages.Message msg : result.Messages)
            {
                strErrorMessage += msg.getSummary()+'\n';
            }
            strErrorMsg = strErrorMessage;
            ilib_LogEvent.message('---->Error--->'+strErrorMsg);
        }
        else{
            ilib_LogEvent.message('---OUT LOOP--');
            Boolean boolIsSerialNumberAdded = false;
            // DCP-45926 Starts
            List<Code_Parameter__mdt> lstCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAMETER_LABOUR_CODE,CODE_PARAMETER_TRAVEL_CODE,CreateQuoteAutomation.CODE_PARAMETER_BLANKET_QUOTE_PRODUCTS});
            Map<String,Code_Parameter__mdt> mapNameToCodeParameter = (Map<String, Code_Parameter__mdt>)UtilsCollection.getMapOfStringToSObject(lstCodeParam, 'DeveloperName', Map<String, Code_Parameter__mdt>.class);
            Boolean boolIsLabourLineAdded = false;
            Boolean boolLabourLessThanMin = false;
            Boolean boolIsTravelLineAdded = false;
            Boolean boolIsBlanketPOAdded = false;//DCP-46277
            // DCP-45926 ends
            for (Apttus_Config2__LineItem__c objLineItem: lstLineItems){
                if(String.isNotBlank(objLineItem.Serial_Number__c)){
                    boolIsSerialNumberAdded = true;
                }
                // DCP-45926 starts
                if(mapNameToCodeParameter.get(CODE_PARAMETER_LABOUR_CODE).Value__c.contains(objLineItem.Apttus_Config2__ProductId__r.ProductCode)){
                    boolIsLabourLineAdded = true;
                    if(objLineItem.Apttus_Config2__Quantity__c < Integer.valueOf(Label.BillableLabourQtyCount)){
                        boolLabourLessThanMin = true;
                    }
                }
                if(mapNameToCodeParameter.get(CODE_PARAMETER_TRAVEL_CODE).Value__c.contains(objLineItem.Apttus_Config2__ProductId__r.ProductCode)){
                    boolIsTravelLineAdded = true;
                }
                // DCP-45926 ends
                //DCP-46277: Start- Check for Blanket PO
                if(mapNameToCodeParameter.get(CreateQuoteAutomation.CODE_PARAMETER_BLANKET_QUOTE_PRODUCTS).Value__c.contains(objLineItem.Apttus_Config2__ProductId__r.ProductCode)){
                    boolIsBlanketPOAdded = true;
                }
                //DCP-46277: End- Check for Blanket PO
                //INC0255210 - Do not allow discount more than 100%.
                if(objLineItem.Sales_Discretionary_Discount__c>100 && objLineItem.Sales_Discretionary_type__c != STRING_DISCOUNT_AMOUNT)
                {
                    boolHasError = true;
                    strErrorMsg = Label.UI_Text_Invalid_Discount_Percent_Error;
                }

                if(objLineItem.Customer_Premium_Type__c == PREMIUM && objLineItem.Customer_Premium_Per_Unit__c < 0)
                {
                     boolHasError = true;
                     strErrorMsg = Label.UI_Text_Negative_Percent_Error;
                }

                else if(objLineItem.Customer_Premium_Type__c == PREMIUM && (objLineItem.Customer_Premium_Per_Unit__c < 1 || objLineItem.Customer_Premium_Per_Unit__c > 99 ))
                {
                     boolHasError = true;
                     strErrorMsg = Label.UI_Text_OutOfBound_Percent_Error;
                } 

                // DGP-385 : Show error if Approval Matrix (Record Owner) is blank on Line Item
                if(String.isBlank(objLineItem.Approval_Matrix_Record_Owner__c)) {
                    boolHasError = true;
                    strErrorMsg = Label.UI_Error_Message_Approval_Matrix_Not_Found;
                }
                
                // For DCP-29847 - Validation Message Markup YMUP
                if(objLineItem.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c == PRODUCT_CONFIG_TYPE_BUNDLE && objLineItem.Apttus_Config2__ProductId__r.Material_Class_Type__c == FIXED_BUNDLE_MATERIAL_CLASS_TYPE && objLineItem.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE && objLineItem.Customer_Premium_Amount_Per_Unit__c != null)
                {
                    boolHasError = true;
                    strErrorMsg = Label.UI_ErrorMessage_FixedComb_MarkUpAtBundle;
                }

                //For DCP-29847 - Manual Rebate YB01
                //DCP-52031 Changing Manual Rebate to Manual Rebate PEr Unit for Validation
                if(objLineItem.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c == PRODUCT_CONFIG_TYPE_BUNDLE && objLineItem.Apttus_Config2__ProductId__r.Material_Class_Type__c == FIXED_BUNDLE_MATERIAL_CLASS_TYPE && objLineItem.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE && objLineItem.Manual_Rebate_Per_Unit__c != null)
                {
                    boolHasError = true;
                    strErrorMsg = Label.UI_ErrorMessage_FixedComb_ManualRebateAtBundle;
                }

                //TASK0555443 - accept only numeric values in Cost_Center__c field.
                if(String.isNotBlank(objLineItem.Cost_Center__c))
                {   
                    Boolean isNumeric=objLineItem.Cost_Center__c.isNumeric();
                    if(!isNumeric){
                        boolHasError = true;
                        strErrorMsg = Label.UI_ErrorMessage_CostCenterNonNumeric;
                    }
                }

                if(isDirectUC)
                {
                    if(objLineItem.Apttus_Config2__PriceListItemId__c==null){
                        boolHasError = true;
                        strErrorMsg = Label.UI_Text_Pricing_Error;
                    }
                    if(objLineItem.Price_per_sample__c == null && boolConsortia)
                    {
                        boolHasError = true;
                        strErrorMsg = Label.UI_Price_Per_Sample_Missing_Error;
                    }
                    //For DCP-29853
                    if(objLineItem.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c == PRODUCT_CONFIG_TYPE_BUNDLE && objLineItem.Apttus_Config2__ProductId__r.Material_Class_Type__c == FIXED_BUNDLE_MATERIAL_CLASS_TYPE && objLineItem.Apttus_Config2__Quantity__c != 1)
                    {
                        boolHasError = true;
                        strErrorMsg = Label.UI_ErrorMessage_FixedComb_Prompt_Quantity_Change;
                    }
                }
                else
                {
                    if(!String.isBlank(objLineItem.Registrant_Contact__c) && objLineItem.Registrant_Contact__r.AccountId != objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c && objLineItem.Registrant_Contact__r.AccountId != objLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__c){
                        boolHasError = true;
                        strErrorMsg = Label.UI_ErrorMessage_Registrant_Contract;
                    }
                    //DCP-25190 - Demo program validation
                    if (objLineItem.Program_Type__c == DEMO_PROGRAM && !boolDemoPromoAdded)
                    {
                        boolHasError = true;
                        strErrorMsg = Label.Demo_Program_Error;
                    }
                    if(objLineItem.Apttus_Config2__PriceListItemId__c==null && objLineItem.LastModifiedById == UserInfo.getUserId())
                    {
                        boolHasError = true;
                        strErrorMsg = Label.UI_Text_Pricing_Error;
                    }
                    else {
                        if(objLineItem.Apttus_Config2__PriceListItemId__c==null && objLineItem.LastModifiedById != UserInfo.getUserId())
                        {
                            boolHasError = true;
                            strErrorMsg = Label.UI_Text_Quotation_Modifcation;
                        }
                    }
                    //For DCP-29847 - Validation Message Price Override YC01
                    if(objLineItem.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c == PRODUCT_CONFIG_TYPE_BUNDLE && objLineItem.Apttus_Config2__ProductId__r.Material_Class_Type__c == FIXED_BUNDLE_MATERIAL_CLASS_TYPE && objLineItem.Apttus_Config2__LineType__c == LINE_TYPE_PRODUCT_SERVICE && (objLineItem.Price_Override__c != null))
                    {
                        boolHasError = true;
                        strErrorMsg = Label.UI_ErrorMessage_FixedComb_PriceOverrideAtBundle;
                    }

                    /*
                    *   Developer: Satya Swain
                    *   Description: DCP-24589: Force user to check price if certain line item field values are changed
                    */
                    // logic to check if line items have been created post Check Price and then force user to Click on Check Price
                    if(objConfiguration.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c && objConfiguration.Apttus_QPConfig__Proposald__r.Quote_Type__c.contains(DISTRIBUTION_CHANNEL_INDIRECT))
                    {
                        if(objLineItem.Line_Item_Old_Values__c == NULL)
                        {
                            // meaning check price not performed hence no json formed
                            boolHasError = true;
                            strErrorMsg = Label.UI_ErrorMessage_Prompt_Check_Price_Skiped;
                        }
                        else
                        {
                            // DCP-25189 : Comparision of JSON field
                            Map<String,String> mapOldFieldValue = (Map<String,String>)JSON.deserialize(objLineItem.Line_Item_Old_Values__c,Map<String,String>.class);
                            for(String keyvalue : mapOldFieldValue.keySet())
                            {
                                if(mapOldFieldValue.get(keyvalue) != String.valueOf(objLineItem.get(keyvalue)))
                                {
                                    boolHasError = true;
                                    strErrorMsg = Label.UI_ErrorMessage_Prompt_Check_Price;
                                    break;
                                }
                            }
                        }
                    }
                    //logic to check if Manual Rebate is greater than Distributor specific Price, DCP-25322
                    //DCP-52031 Changing Manual Rebate to Manual Rebate Per Unit for Validation
                     if (objConfiguration.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c
                     && objLineItem.Manual_Rebate_Per_Unit__c != NULL
                     && ( objLineItem.Distributor_Specific_Discount__c == NULL
                     || integer.valueOf(objLineItem.Manual_Rebate_Per_Unit__c) * objLineItem.Apttus_Config2__Quantity__c> objLineItem.Distributor_Specific_Discount__c))
                    {
                        boolHasError = true;
                        strErrorMsg = Label.UI_ErrorMessage_Manual_Rebate;
                    } 
                }
            }
            if(!isDirectUC)
            {
                //logic to check if line items have been deleted post Check Price and then force user to click on Check Price
                if (objConfiguration.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c
                && objConfiguration.Apttus_QPConfig__Proposald__r.Quote_Type__c.contains(DISTRIBUTION_CHANNEL_INDIRECT)
                && (objConfiguration.Number_of_Line_Items_During_Check_Price__c == NULL
                || objConfiguration.Number_of_Line_Items_During_Check_Price__c != objConfiguration.Apttus_Config2__NumberOfItems__c ))
                {
                    boolHasError = true;
                    strErrorMsg = Label.UI_ErrorMessage_Prompt_Check_Price;
                }
            }
            // DCP-45742
            if(!boolIsSerialNumberAdded && String.isNotBlank(objConfiguration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c) && objConfiguration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c.contains(Label.OpportunityProductInterestRelocation)){
                boolHasError = true;
                strErrorMsg = Label.UI_ErrorMessage_SerialNumber_Mandatory;
            }
            // DCP-45926 starts
            String strQuoteType = objConfiguration.Apttus_QPConfig__Proposald__r.Quote_Type__c;
            Boolean isDirectFieldService = Label.OpportunityRTDirectFieldServicesLabel.equals(strQuoteType);
           
            if(boolLabourLessThanMin 
                && !boolIsBlanketPOAdded//DCP-46277: Bypass for Blanket PO
                && (Label.OpportunityRTIndirectDFSLabel.equals(strQuoteType)
                    || isDirectFieldService)){
                    boolHasError = true;
                    strErrorMsg += Label.UI_Message_Labour_Line_Missing;
            }
            if(isDirectFieldService
                    && String.isNotBlank(objConfiguration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c)
                        && (objConfiguration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c.contains(Label.OpportunityProductInterestRelocation) 
                            || objConfiguration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c.contains(Label.OpportunityProductInterestBreakFix))){
                if(!boolIsTravelLineAdded){//DCP-49511(Added warning messages)
                    boolWarning = true;
                    strWarningMsgs += '<li>' + Label.UI_Message_Travel_Zone_Missing + '</li>';
                }
                if(!boolIsLabourLineAdded){//DCP-49511(Added warning messages)
                    boolWarning = true;
                    strWarningMsgs += '<li>' + Label.UI_Message_Labour_Line_Missing + '</li>';
                }
            }
            // DCP-45926 ends
        
        }
        ilib_LogEvent.message('boolHasError return-->'+boolHasError);
        ilib_LogEvent.pop();
        return boolHasError;
    }

    /* DCP-34910 - Updation for Large Cart Scenario */
    private void getResponse(String strRequstJSON,String strBusinessObjectId,ilib_LogInterface.LogDetails log,Apttus_Config2__ProductConfiguration__c objConfiguration)
    {
        ilib_LogEvent.push('getResponse');

        HttpResponse resp = ApttusSAPConnector.getPrice(strRequstJSON,false);
        if(resp.getStatusCode() != HTTP_POST_SUCCESS_CODE && resp.getStatusCode() != HTTP_SUCCESS_CODE)
        {
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, resp.getBody() + resp.getStatusCode(), strBusinessObjectId);
        }
        else
        {
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, resp.getBody()+ resp.getStatusCode(), strBusinessObjectId); 
        }

        checkResponse(resp,false,strBusinessObjectId,log,objConfiguration);

        ilib_LogEvent.pop();
    }

    // TODO: make private
    //DCP-34910 Validate Cart Update
    private void checkResponse(HttpResponse response , Boolean isDirectUC , String strBusinessObjectId , ilib_LogInterface.LogDetails log ,Apttus_Config2__ProductConfiguration__c objConfiguration)
    {
        ilib_LogEvent.push('checkResponse');

        if (response.getStatusCode() != HTTP_POST_SUCCESS_CODE && response.getStatusCode() != HTTP_SUCCESS_CODE ){
            boolHasError=true;
            strErrorMsg = Label.UI_Failed_Response_Code;
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody() + response.getStatusCode(), strBusinessObjectId);
            if(isDirectUC) { ApexExceptions.emit('ApttusCheckPriceDirectUCController',log.logRecordId,response.getBody()); }
            else { ApexExceptions.emit('ApttusCheckPriceController',log.logRecordId,response.getBody()); }       
        }
        else
        {
            strResponse = response.getBody();
            ilib_LogEvent.message('Response body'+strResponse);
            if(!isDirectUC){
                boolError = RealtimePricingResponseParser.parser(objConfiguration.id ,strResponse);
                if(objConfiguration.Apttus_QPConfig__Proposald__r.Sold_To_Sales_Organization__c==SOLD_TO_SALES_ORGANIZATION && (objConfiguration.Apttus_QPConfig__Proposald__r.Fapiao_Type_Code__c==null|| String.isBlank(objConfiguration.Apttus_QPConfig__Proposald__r.Fapiao_Type_Code__c))) { boolFapiao = true; }    
            }
            else { boolError = RealtimePricingResponseDirectUC.parser(objConfiguration.id ,strResponse); }

            if(boolError){
                boolHasError = true;
                createErrorMsg(isDirectUC);//Sonar Qube Fix - DCP-34910
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,'UI Error :'+ strErrorMsg+ ' JSON Response :'+ strResponse, strBusinessObjectId);
            }
        }

        ilib_LogEvent.pop();
    }

    /* DCP-34910 Method to update quote */
    @TestVisible
    private void updateQuotation(String strBusinessObjectId, Boolean validationFlag, Integer timeDifference)
    {
        ilib_LogEvent.push('updateQuotation');

        DateTime localTime = System.now().addMinutes(timeDifference);
        Apttus_Proposal__Proposal__c objQuotation = new Apttus_Proposal__Proposal__c(
            Id = strBusinessObjectId,
            Validation_In_Progress__c = validationFlag,
            Validation_Start_Time__c = localTime,
            Async_Validation_Complete__c = false
        );
        update objQuotation;

        ilib_LogEvent.pop();
    }

    /* DCP-34910 Method to update Product Config */
    @TestVisible
    private void updateProductConfig(Apttus_Config2__ProductConfiguration__c objConfig, String currentStatus)
    {
        ilib_LogEvent.push('updateProductConfig');

        objConfig.Apttus_Config2__Status__c = currentStatus;
        objConfig.Validation_Number__c += 1;
        update objConfig;

        ilib_LogEvent.pop();
    }

    /* DCP-34910 Sonar Qube Fix */ 
    // DCP-46276      
    private void createErrorMsg(Boolean isDirectUC)
    {
        strErrorMsg = '<ui>';
        createBoolPricingError();
        createBoolRETError();
        if (!isDirectUC)
        {
            createBoolEmbargoCheckError(); 
            createBoolSanctionedPartyListCheck();
            checkBoolLegalControlError();
            checkComplainceError();
        }
        strErrorMsg += '</ui>';
    }
    /* 
    *DCP-46276 Sonar Qube Fix
    */
    public static void createBoolPricingError(){
        if (boolPricingError){
            strErrorMsg += strHtmlLineTagStart+Label.UI_Pricing_Error + strHtmlLineTagEnd;
        }
    }
    /* 
    *DCP-46276 Sonar Qube Fix
    */
    public static void createBoolRETError(){
        if (boolRETError)
        {
            ilib_LogEvent.message('RET Error -->' + strRETErrors);
            strErrorMsg += strHtmlLineTagStart+Label.UI_Data_Error + strHtmlLineTagEnd;
        }
    }
     /* 
    *DCP-46276 Sonar Qube Fix
    */
    public static void createBoolEmbargoCheckError(){
        if (boolEmbargoCheck){
            ApttusCheckPriceController.strErrorType+= 'Emabargo_Screening%,';
            strErrorMsg += strHtmlLineTagStart+ Label.UI_Embarko_Check + strHtmlLineTagEnd;
        }
    }
     /* 
    *DCP-46276 Sonar Qube Fix
    */
    public static void createBoolSanctionedPartyListCheck(){
        if (boolSanctionedPartyListCheck){
            ApttusCheckPriceController.strErrorType+= 'Sanctioned_Party_List%,';
            strErrorMsg += strHtmlLineTagStart + Label.UI_Sanctioned_Party_List_Screening + strHtmlLineTagEnd;
        }
    }
     /* 
    *DCP-46276 Sonar Qube Fix
    */
    public static void checkBoolLegalControlError(){
        if (boolLegalControl){
            strErrorMsg += strHtmlLineTagStart + Label.UI_Legal_Control + strHtmlLineTagEnd;
        }
    }
     /* 
    *DCP-46276 Sonar Qube Fix
    */
    public static void checkComplainceError(){
        // DCP-46276
        if(String.isNotBlank(objConfiguration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c) && objConfiguration.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Product_Interest__c.contains(Label.OpportunityProductInterestRelocation)){
            if(!lstInstrumentCompliance.isEmpty()){
                strErrorMsg += strHtmlLineTagStart + Label.UI_Instrument_Compliance_Relocation + strHtmlLineTagEnd;
            }
            if(!lstRegulatoryMedicalDevice.isEmpty()){
                strErrorMsg += strHtmlLineTagStart + Label.UI_Regulatory_Device_Relocation + strHtmlLineTagEnd;
            }
        }
        else{
            // DCP-41818
            String materialPlaceholderText = '(PRODUCT_CODE)'; // this value in the error labels will be replaced by the material number in the error message
            for (String materialNumber : lstInstrumentCompliance){
                strErrorMsg += strHtmlLineTagStart + Label.UI_Instrument_Compliance.replace(materialPlaceholderText, materialNumber) + strHtmlLineTagEnd;
                ApttusCheckPriceController.strErrorType+= 'Instrument_Compliance%,';
            }

            for (String materialNumber : lstRegulatoryMedicalDevice){
                strErrorMsg += strHtmlLineTagStart + Label.UI_Regulatory_Device.replace(materialPlaceholderText, materialNumber) + strHtmlLineTagEnd;
                ApttusCheckPriceController.strErrorType+= 'Regulatory_Device%,';
            }
        }
    }

}
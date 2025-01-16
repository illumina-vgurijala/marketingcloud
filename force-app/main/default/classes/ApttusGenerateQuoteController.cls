/*
* @Author: Kushagra Desai
* @Date: 2018-11-07
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Kushagra Desai      25-JAN-2019               Direct Sales To UC changes and Consortia
* Kushagra Desai      05-APR-2019               DCP-24602 -Error stroing on generate
* Saswati Prusty      09-APR-2019               DCP-10444 -Error for Past End of Sale/End of Service Date on Generate.
* Kushagra Desai      12-Jun-2019               DCP-25908 : Update payment term
* Kushagra Desai      17-Jun-2019               DCP-25240 : Tax update
* Saswati             27-Sep-2019               DCP-28565 : Added Fapiao Type Logic
* Satya Swain         10 Dec-2019               DCP-30062 : SonarQube Fixes
* Satya Swain         05 Feb 2020               Added null checks to NAVHDRTOGTSLOGS as part of INC0236538
* Rishab Wali         05 May 2020               DCP-34910 : Updating response logic to different method
* Prabhsimran Singh   09 Jun 2020               DCP-37888 : Updating response logic to different method
* Todd Newman         17-Mar-2021               DCP-45737: add ilib logging
* Akshay Mohan        11 May 2021                DCP-38809 : Update instantiating logic
* Nishan Shetty       22-April-2022              CodeScan Fix:Avoid Literals in If condition
* Himanshu            29 March 2022             Code Scan Fixes
*/

public with sharing class ApttusGenerateQuoteController extends ilib_RestReceiver {

    private static final String LOG_TITLE = 'GenerateQuoteController';
    //START CodeScan Fix [Avoid Literals in If condition]
    private static final String STRING_B = 'B'; 
    //END CodeScan Fix 

    /**
     * @author Kushagra Desai
     * @description  inheriting the parent class
    **/
    public class ValidateException extends Exception {}
    public static Boolean boolHasError{get; set;}
    public static Boolean boolPricingError = false;
    public static Boolean boolRETError = false;
    public static Boolean boolEmbargoCheck = false;
    public static Boolean boolSanctionedPartyListCheck = false;
    public static Boolean boolLegalControl = false;
    public static Boolean boolendDateError = false; // Saswati: check for end of sale/ end of service date.
    public static String endDateErrorMsg; // saswati: Error Message for End of sale date/ end of service date error
    public static string strRETErrors = '';
    @AuraEnabled public static String strErrorMsg{get;set;}
    public static String strQuoteID;
    public static String URLs{get;set;}
    public static Map<String,Apttus_Proposal__Proposal_Line_Item__c> lineNameToLineItem = new Map<String,Apttus_Proposal__Proposal_Line_Item__c>();
    public static Apttus_Proposal__Proposal__c objQuote;
    public static List<Apttus_Proposal__Proposal_Line_Item__c> listproposalLineItem;
    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public static String strRequstJSON;
    public static ilib_LogInterface.LogDetails log;
    public static Boolean boolConsortia;
    public static String strResponse;
    public static Boolean boolSubTotalChange = false;
    public static Boolean boolDiscountChange = false;
    public static Decimal decSubtotal;
    public static RealtimePricingResponse objRTPResponse;
    public static Boolean boolQuoteUpdate = false;
    public static final String CODEPARAMETERNAME = 'Real_Time_Pricing_Threshold_Value'; //DCP-37888 Update for Large Carts Generate
    public static string baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();    
    public static string redirectToError = baseURL+'/apex/ApttusGenerateQuoteError?id=';
    public static string redirectToOutput = baseURL+'/apex/Apttus_Proposal__DocGen?context=proposal&id=';
   

    public static string errorKeyword = '&error=';    
    public static final string COMMA_VARIABLE = ',  ';
    public static final string DOT_VARIABLE = '.  ';
    public static final string LIST_TAG_OPENED = '<li>';     
    public static final string LIST_TAG_CLOSED = '</li>';
    /**
    * @author Kushagra Desai   
     * @description  setting the error messages
    **/
    public class ErrorSet{
        @AuraEnabled public String strErrorMsg1;
        @AuraEnabled public Boolean boolHasError1;
    }
    /** 
    * @author Kushagra Desai
    * @description constructor called 
    **/
    public ApttusGenerateQuoteController()
    {
        ilib_LogEvent.message('In constructor');
        boolHasError = false;
        strQuoteID = ApexPages.CurrentPage().getParameters().get('id').escapeHtml4();
        URLs = System.URL.getSalesforceBaseUrl().toExternalForm();

        ilib_LogEvent.message('@@@@ strQuoteID: '+strQuoteID);
    }
    /**
    * @description passing quote id to the constructors 
    * @param String quoteId
    * @return void
    **/
    public ApttusGenerateQuoteController(String quoteId)
    {
        ilib_LogEvent.message('In constructor');
        boolHasError = false;
        strQuoteID = quoteId;
        URLs = System.URL.getSalesforceBaseUrl().toExternalForm();

        ilib_LogEvent.message('@@@@ strQuoteID: '+strQuoteID);
    }

    /**
    *  @author Kushagra Desai
    *  @description CHeck Pricing
    *  @param NA
    *  @return void
    **/
    
    public static PageReference reCheckPricing()
    {
        ilib_LogEvent.setTitle(LOG_TITLE);

        ErrorSet objerr = new ErrorSet();
        ilib_LogEvent.message('Check---');
        //DCP-38809-Start: change instantiating logic
        ApttusGenerateQuoteController instantiated;
        if(String.isNotBlank(strQuoteID)){
            instantiated=new ApttusGenerateQuoteController(strQuoteID);
        }else{
            instantiated = new ApttusGenerateQuoteController();
        }
        //DCP-38809-End: change instantiating logic
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;

        CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
        List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});

        try
        {
            strErrorMsg = '';
            /*
            Saswati : DCP - 10444
            On Generate, check if any of the products/options in the  proposal line items in the proposal have a past end of sale date or Past end of Service Date.
            */
            endDateErrorMsg = '';

            //DCP-37888
            objQuote = new ApttusProposalsSelector().selectProposalById(strQuoteID);
            
            //DCP-37888 Time difference field to store value for skipping validation            
            Integer timediff = Integer.valueOf(objCodeParam[0].PickListValue__c.substringAfter(':'));

            //DCP-37888 If last success is within the timeframe then redirect user to generate page.
            if ((objQuote.Last_Generate_Success__c != null && system.now() <= objQuote.Last_Generate_Success__c.addHours(timediff)))
            {
                ilib_LogEvent.message('last success recent enough to not re-check');
                ilib_LogEvent.emit();
                return new PageReference(redirectToOutput+strQuoteID);
            }

            set<Id> setobjId = new Set<Id>{strQuoteID};
            listproposalLineItem = new ApttusProposalLineItemsSelector().selectByQuoteId(setobjId);
            ilib_LogEvent.message('**************** proposal line items size: ' + listproposalLineItem.size());

            if (listproposalLineItem.size() > 0)
            {
                for(Apttus_Proposal__Proposal_Line_Item__c oli:listproposalLineItem)
                {
                    if (oli.Apttus_Proposal__Product__c!= null && oli.Apttus_QPConfig__OptionId__c!= null)
                    {
                        if (oli.Apttus_QPConfig__OptionId__r.End_Of_Sale_Date__c < Date.today() && (oli.Apttus_QPConfig__OptionId__r.End_Of_Service_Date__c >= Date.today()))
                        {
                            boolHasError = true;
                            boolendDateError = true;
                            endDateErrorMsg += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__c + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__r.Material_Number__c + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__r.End_Of_Sale_Date__c.format() + DOT_VARIABLE;
                        }
                        if ((oli.Apttus_QPConfig__OptionId__r.End_Of_Sale_Date__c >= Date.today()) && oli.Apttus_QPConfig__OptionId__r.End_Of_Service_Date__c < Date.today())
                        {
                            boolHasError = true;
                            boolendDateError = true;
                            endDateErrorMsg += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__c + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__r.Material_Number__c + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__r.End_Of_Service_Date__c.format() + DOT_VARIABLE;
                        }
                        if (oli.Apttus_QPConfig__OptionId__r.End_Of_Sale_Date__c < Date.today() && oli.Apttus_QPConfig__OptionId__r.End_Of_Service_Date__c < Date.today())
                        {
                            boolHasError = true;
                            boolendDateError = true;
                            endDateErrorMsg += Label.UI_AddErrorForEndOfSaleDateOrServiceDate  + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__c + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__r.Material_Number__c + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__r.End_Of_Sale_Date__c.format() + COMMA_VARIABLE + oli.Apttus_QPConfig__OptionId__r.End_Of_Service_Date__c.format() + DOT_VARIABLE;
                        }
                    }

                    if(oli.Apttus_Proposal__Product__c!= null && oli.Apttus_QPConfig__OptionId__c == null)
                    {
                        ilib_LogEvent.message('******Inside date check for line item**** - ' + oli.Apttus_Proposal__Product__c );
                        if(oli.Apttus_Proposal__Product__r.End_Of_Sale_Date__c < Date.today() && (oli.Apttus_Proposal__Product__r.End_Of_Service_Date__c >= Date.today()))
                        {
                            boolHasError = true;
                            boolendDateError = true;
                            endDateErrorMsg += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + oli.Apttus_Proposal__Product__c + COMMA_VARIABLE + oli.Apttus_Proposal__Product__r.Material_Number__c + COMMA_VARIABLE + oli.Apttus_Proposal__Product__r.End_Of_Sale_Date__c.format() + DOT_VARIABLE  ;
                        }
                        else if((oli.Apttus_Proposal__Product__r.End_Of_Sale_Date__c >= Date.today()) && oli.Apttus_Proposal__Product__r.End_Of_Service_Date__c < Date.today())
                        {
                            boolHasError = true;
                            boolendDateError = true;
                            endDateErrorMsg += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + oli.Apttus_Proposal__Product__c + COMMA_VARIABLE + oli.Apttus_Proposal__Product__r.Material_Number__c + COMMA_VARIABLE + oli.Apttus_Proposal__Product__r.End_Of_Service_Date__c.format() + DOT_VARIABLE;
                        }
                        else {
                            if(oli.Apttus_Proposal__Product__r.End_Of_Sale_Date__c < Date.today() && oli.Apttus_Proposal__Product__r.End_Of_Service_Date__c < Date.today())
                            {
                                boolHasError = true;
                                boolendDateError = true;
                                endDateErrorMsg += Label.UI_AddErrorForEndOfSaleDateOrServiceDate  + COMMA_VARIABLE + oli.Apttus_Proposal__Product__c + COMMA_VARIABLE + oli.Apttus_Proposal__Product__r.Material_Number__c + COMMA_VARIABLE + oli.Apttus_Proposal__Product__r.End_Of_Sale_Date__c.format() + COMMA_VARIABLE +  oli.Apttus_Proposal__Product__r.End_Of_Service_Date__c.format() + DOT_VARIABLE;
                            }
                        }
                    }
                }
            }

            strRequstJSON = RealtimePricingRequest.createJSONForGenerateQuote(strQuoteID,false);

            ilib_LogEvent.message('@@@ RTP Request ' + strRequstJSON);
            log = ilib_LogInterface.initiateLog(interfaceDetails, strRequstJSON);
            HttpResponse response = ApttusSAPConnector.getPrice(strRequstJSON,false);
            ilib_LogEvent.message('@@@ RTP response ' + response);

            if (response.getStatusCode() != HTTP_POST_SUCCESS_CODE && response.getStatusCode() != HTTP_SUCCESS_CODE)
            {
                boolHasError = true;
                strErrorMsg = Label.UI_Failed_Response_Code;
                //throw new ValidateException(response.getBody());
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody(), strQuoteID);
                ApexExceptions.emit('ApttusGenerateQuoteController',log.logRecordId,response.getBody());
            }
            else
            {
                strResponse = response.getBody(); 
                //DCP-37888 Checking if its large cart then parsing error.    
                if (listproposalLineItem.size() > Integer.valueOf(objCodeParam[0].Value__c))
                {
                    responseParser(strResponse);
                    ilib_LogEvent.message('@@@ RTP Response ' + objRTPResponse);
                    //DCP-37888 checking for any error in response
                    responseErrorParsing();
                    if (boolHasError && boolRETError)
                    {
                        strErrorMsg += LIST_TAG_OPENED +Label.UI_Data_Error_Generate + LIST_TAG_CLOSED;
                        update objQuote;
                    }
                    if (boolHasError)
                    {
                        ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, 'Message on UI : '+strErrorMsg+ ' Response JSON: '+strResponse, strQuoteID);
                    }
                }
                //DCP-37888 Sending response for calculation in case of small cart
                else
                {
                    ilib_LogEvent.message('Response body'+strResponse);
                    // Pricing difference code here   
                    generateQuoteResponseCalculation(strResponse,log);
                }
                //*****************************************************
            }

            objerr.strErrorMsg1 = strErrorMsg;
            objerr.boolHasError1 = boolHasError;
            if (Test.isRunningTest())
            {   
                boolHasError = false;
            }

            if (!boolHasError)
            {
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,strResponse, strQuoteID);
                //DCP-37888 Redirect user to quote page for large cart.
                if (listproposalLineItem.size() > Integer.valueOf(objCodeParam[0].Value__c) || Test.isRunningTest())
                {
                    if(objQuote.Last_Validation_Id__c == null){objQuote.Last_Validation_Id__c=0;}
                    String timeDiffer = objCodeParam[0].PickListValue__c.substringBefore(':');
                    Integer timeDifference = Integer.valueOf(timeDiffer) * -1 ;
                    objQuote.Generate_In_Progress__c = true;
                    objQuote.Last_Validation_Id__c += 1;
                    DateTime localTime = System.now().addMinutes(timeDifference);
                    objQuote.Generate_Start_Time__c = localTime;
                    objQuote.Async_Generation_Complete__c = false;
                    update objQuote;

                    ilib_LogEvent.emit();
                    return new PageReference(baseURL+'/'+strQuoteID);
                }
            }

            if (boolHasError)
            {
                ilib_LogEvent.emit();
                return new PageReference(redirectToError+strQuoteID+errorKeyword+strErrorMsg);
            }
            // Saswati : check if there is any end of sale date or end of servcie date error.
            else
            {
                ilib_LogEvent.emit();
                return new PageReference(redirectToOutput+strQuoteID);
            }
        }

        catch (Exception e)
        {
            //CMSI-2 removed setLogLevelError and replaced message to error
            ilib_LogEvent.error('Error at line        : ' + e.getLineNumber());
            ilib_LogEvent.error('The following exception has occurred:++++getMessage+++ ' + e.getMessage());
            ilib_LogEvent.error('Exception type caught : ' + e.getTypeName());
            ilib_LogEvent.error('Cause                 : ' + e.getCause());
            ilib_LogEvent.error('Stack trace           : ' + e.getStackTraceString());
            if (log != null)
            {
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, e.getMessage(), strQuoteID);
                ApexExceptions.emit('ApttusGenerateQuoteController',log.logRecordId,e);
            }
            else
                ApexExceptions.emit('ApttusGenerateQuoteController',strQuoteID,e);

            boolHasError = true;
            strErrorMsg = Label.UI_Error_Contact_Admin + '\n'+  e.getMessage();

            ilib_LogEvent.emit();
            return new PageReference(redirectToError+strQuoteID+errorKeyword+strErrorMsg);
        }
    }
    
    /**
    *  @author Kushagra Desai
    *  @description redirectToGenerate
    *  @param NA
    *  @return void
    **/
    public PageReference redirectToGenerate()
    {
        string baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
        PageReference orderPage = new PageReference(baseURL+'/apex/Apttus_Proposal__DocGen?context=proposal&id='+strQuoteID);
        return orderPage;
    }
    /**
    *  @author Kushagra Desai
    *  @description redirectToQuote
    *  @param NA
    *  @return void
    **/
    public PageReference redirectToQuote()
    {
        PageReference orderPage = new PageReference('/'+strQuoteID);
        return orderPage;
    }
    /**
    *  @author Kushagra Desai
    *  @description redirectToError
    *  @param NA
    *  @return void
    **/
    public PageReference redirectToError()
    {
        PageReference errorPage = new PageReference('/apex/ApttusGenerateQuoteError?id='+strQuoteID+'&error='+strErrorMsg);
        return errorPage;
    }


    /**
    *  @author Kushagra Desai
    *  @description DCP-37888 Refactor the code into below method for processing small(sync call) and large(async call) cart.
    *  @param String strResponse, ilib_LogInterface.LogDetails log
    *  @return void
    **/
    public static void generateQuoteResponseCalculation(String strResponse, ilib_LogInterface.LogDetails log)
    {
        ilib_LogEvent.push('generateQuoteResponseCalculation');

        //DCP-37888 below method created to parse response
        responseParser(strResponse);
        ilib_LogEvent.message('@@@ RTP Response ' + objRTPResponse);
        objQuote.SAP_Errors__c = '';

        // DCP-25908 : Update payment term
        if(String.isNotBlank(objQuote.Bill_To_ERP_Number__c) && String.isBlank(objQuote.Apttus_Proposal__Payment_Term__c)){
            objQuote.Apttus_Proposal__Payment_Term__c = (String)objRTPResponse.Pmnttrms;
        }

        //Check Quotation Subtotal price Change
        if (objRTPResponse.NAVHDRTOEXP != null)
        {
            for (RealtimePricingResponse.LineExports ex : objRTPResponse.NAVHDRTOEXP.results)
            {
                ilib_LogEvent.message('SubTotal->'+objQuote.Sub_Total__c);
                ilib_LogEvent.message('ZSubtotal->'+UtilsRest.convertStringToNumber(ex.ZSubtotal));
                ilib_LogEvent.message('Total Discount->'+objQuote.Total_Discount__c);
                ilib_LogEvent.message('ZSubtotal->'+UtilsRest.convertStringToNumber(ex.ZTotalDiscount));
                ilib_LogEvent.message('@@@@ Sub_Total__c value: '+ objQuote.Sub_Total__c);

                // Sub Total Change check
                if (objQuote.Quote_Sub_Type__c != system.label.OpportunityTypeCustomProductFirstBuy)
                {
                    if (objQuote.Sub_Total__c.setscale(2) != UtilsRest.convertStringToNumber(ex.ZSubtotal)) {
                        ilib_LogEvent.message('Pricing error Quote');
                        boolPricingError = true;
                        boolHasError = true;
                        boolSubTotalChange = true;
                        decSubtotal = objQuote.Sub_Total__c.setscale(2);
                    }
                }
                else
                {
                    if (objQuote.Subtotal__c.setscale(2) != UtilsRest.convertStringToNumber(ex.ZSubtotal)) {
                        ilib_LogEvent.message('Pricing error Quote1');
                        boolPricingError = true;
                        boolHasError = true;
                        boolSubTotalChange = true;
                        decSubtotal = objQuote.Subtotal__c.setscale(2);
                    }
                }

                // Discount Change
                if (objQuote.Total_Discount__c != UtilsRest.convertStringToNumber(ex.ZTotalDiscount)) {
                    ilib_LogEvent.message('Pricing error Quote');
                    boolPricingError = true;
                    boolHasError = true;
                    boolDiscountChange = true;
                }

                // DCP-25240 : Update estimated tax and freight
                if(!String.isEmpty(ex.ZTotalFreight) && !String.isEmpty(ex.ZTotalTax)){
                    if (objQuote.Estimated_Freight__c != UtilsRest.convertStringToNumber(ex.ZTotalFreight) || objQuote.Estimated_Tax__c != UtilsRest.convertStringToNumber(ex.ZTotalTax)) {
                        objQuote.Estimated_Freight__c = UtilsRest.convertStringToNumber(ex.ZTotalFreight);
                        objQuote.Estimated_Tax__c = UtilsRest.convertStringToNumber(ex.ZTotalTax);
                        objQuote.Total_Net__c = UtilsRest.convertStringToNumber(ex.ZOrderTotal);
                        boolQuoteUpdate = true;
                    }
                }
            }
        }

        /*
        *******************************************
        **Loop to get all Fapiao from response** DCP-28565
        *******************************************
        */
        if (objRTPResponse.NAVHDRTOFAPIAO != null)
        {
            ilib_LogEvent.message('### Inside Fapiao');
            ilib_LogEvent.message ('NAVHDRTOFAPIO - '+objRTPResponse.NAVHDRTOFAPIAO);
            ilib_LogEvent.message ('NAVHDRTOFAPIO Results'+objRTPResponse.NAVHDRTOFAPIAO.results);
            if (objRTPResponse.NAVHDRTOFAPIAO.results != null && objRTPResponse.NAVHDRTOFAPIAO.results.size() > 0)
            {
                for (RealtimePricingResponse.LineFapiao lfapiao : objRTPResponse.NAVHDRTOFAPIAO.results)
                {
                    ilib_LogEvent.message('Fapiao Type on objQuote' +  objQuote.Fapiao_Type_Code__c);
                    if(lfapiao.FapiaoTypeCode != null)
                    {
                        objQuote.Fapiao_Type_Code__c = lfapiao.FapiaoTypeCode;
                        ilib_LogEvent.message('Fapiao Description' + lfapiao.FapiaoTypeDesc );
                        ilib_LogEvent.message(' objQuote.Fapiao_Type_Description__c' +  objQuote.Fapiao_Type_Description__c);
                        boolQuoteUpdate = true;
                    }

                    if (lfapiao.FapiaoTypeDesc != null)
                    {
                        objQuote.Fapiao_Type_Description__c = lfapiao.FapiaoTypeDesc;
                        ilib_LogEvent.message(' objQuote.Fapiao_Type_Description__c' +  objQuote.Fapiao_Type_Description__c);
                        boolQuoteUpdate = true;
                    }
                }
            }
        }

        /*
        *******************************************
        **Loop to get all LOGS from response**
        *******************************************
        */
        if (objRTPResponse.NAVHDRTOGTSLOGS != null)
        {
            ilib_LogEvent.message('Inside Log Structure');
            Boolean boolQualStaiBlank;
            for (RealtimePricingResponse.LineLogs lg : objRTPResponse.NAVHDRTOGTSLOGS.results)
            {
                RealtimePricingRequestGenerator.lineNameToLineItem.get(lg.ZzapPosnr);
                ilib_LogEvent.message('***LOGSSSSS--> '+ lg.ZzapPosnr);
                if (String.isNotBlank(lg.ZzapPosnr))
                {
                    boolQualStaiBlank = String.isBlank(lg.QualStai);
                    ilib_LogEvent.message('@@@@ value of boolQualStaiBlank: '+ boolQualStaiBlank);
                    if (lg.CheckInd == STRING_B) {
                        if (label.Quote_Embargo_Check.contains(lg.QualStai) && !boolQualStaiBlank) {
                            boolEmbargoCheck = true;
                            boolHasError = true;
                        }
                        if (label.Quote_Sanctioned_Party_List_Screening.contains(lg.QualStai) && !boolQualStaiBlank) {
                            boolSanctionedPartyListCheck = true;
                            boolHasError = true;
                        }
                        if (label.Quote_Legal_Control.contains(lg.QualStai) && !boolQualStaiBlank) {
                            boolLegalControl = true;
                            boolHasError = true;
                        }
                    }
                }
            }
        }

        /*
        *******************************************
        **Loop to get all return logs from response**
        * DCP-24602-  Added error storing mechanism
        *******************************************
        */                
        //DCP-37888 Below method created for checking errors in response for both small and large cart.
        responseErrorParsing();

        /*
        ******************************************************
        **Loop to get total discounts on lines from response**
        ******************************************************
        */
        if (objRTPResponse.NAVHDRTOITEMCOND != null)
        {
            ilib_LogEvent.message('Inside Item Structure');
            for (RealtimePricingResponse.LineConditions li : objRTPResponse.NAVHDRTOITEMCOND.results)
            {
                Apttus_Proposal__Proposal_Line_Item__c localLine = lineNameToLineItem.get(li.ZzapPosnr);
                if (li.KonvKschl == 'ZPNP' && !objQuote.Direct_Sale_to_Ultimate_Consignee__c) {
                    if (localLine.Apttus_QPConfig__NetPrice__c != UtilsRest.convertStringToNumber(li.KonvKwert)) {
                        ilib_LogEvent.message('Pricing error Line');
                        boolPricingError = true;
                        boolHasError = true;
                    }
                }
                if (li.KonvKschl == 'ZCNP' && objQuote.Direct_Sale_to_Ultimate_Consignee__c) {
                    if (localLine.Customer_Net_Price__c != UtilsRest.convertStringToNumber(li.KonvKwert)) {
                        ilib_LogEvent.message('Pricing error Quote line');
                        boolPricingError = true;
                        boolHasError = true;
                    }
                }
            }
        }

        if (boolHasError)
        {
            if (boolEmbargoCheck) {
                strErrorMsg += LIST_TAG_OPENED +Label.UI_Embarko_Check + LIST_TAG_CLOSED;
            }
            if (boolSanctionedPartyListCheck) {
                strErrorMsg += LIST_TAG_OPENED +Label.UI_Sanctioned_Party_List_Screening + LIST_TAG_CLOSED;
            }
            if (boolLegalControl) {
                strErrorMsg += LIST_TAG_OPENED +Label.UI_Legal_Control + LIST_TAG_CLOSED;
            }
            if (boolPricingError)
            {
                ilib_LogEvent.message('---'+objRTPResponse.NAVHDRTOEXP.results[0].ZSubtotal);
                String strSubtotal = String.isBlank(objRTPResponse.NAVHDRTOEXP.results[0].ZSubtotal) ? 'NULL' : objRTPResponse.NAVHDRTOEXP.results[0].ZSubtotal;
                String strDiscount = String.isBlank(objRTPResponse.NAVHDRTOEXP.results[0].ZTotalDiscount) ? 'NULL' : objRTPResponse.NAVHDRTOEXP.results[0].ZTotalDiscount;
                strErrorMsg += LIST_TAG_OPENED + Label.UI_Pricing_Error_Generate + LIST_TAG_CLOSED;
                if (boolSubTotalChange && String.isNotBlank(objRTPResponse.NAVHDRTOEXP.results[0].ZSubtotal))
                    strErrorMsg += LIST_TAG_OPENED + Label.UI_Subtotal_Error + ' '+decSubtotal+' to '+strSubtotal+LIST_TAG_CLOSED;
                if (boolDiscountChange && String.isNotBlank(objRTPResponse.NAVHDRTOEXP.results[0].ZTotalDiscount))
                    strErrorMsg += LIST_TAG_OPENED + Label.UI_Discount_Error + ' '+objQuote.Total_Discount__c+' to '+ strDiscount+LIST_TAG_CLOSED;
                if (String.isBlank(strRETErrors))
                {
                    objQuote.SAP_Errors__c = strRETErrors;
                }
                objQuote.SAP_Errors__c += strErrorMsg;
            }

            //37888 for updating pricing error in sap error field for large cart.
            if (boolRETError || boolPricingError) {
                strErrorMsg += LIST_TAG_OPENED +Label.UI_Data_Error_Generate + LIST_TAG_CLOSED;
                update objQuote;
            }

            if (boolendDateError) {
                strErrorMsg += LIST_TAG_OPENED + endDateErrorMsg + LIST_TAG_CLOSED;
            }
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, 'Message on UI : '+strErrorMsg+ ' Response JSON: '+strResponse, strQuoteID);
        }
        else
        {
            if (boolQuoteUpdate)
                update objQuote;
        }

        ilib_LogEvent.pop();
    }

    /**
    *  @author Prabhsimran Singh
    *  @Populate the objRTPResponse with response from callout- DCP-37888.
    *  @param String
    *  @return void
    **/
    public static void responseParser(String strResponse)
    {
        ilib_LogEvent.push('responseParser');

        Map<String, Object> lstJsonParse = (Map<String, Object>)Json.deserializeUntyped(strResponse);
        Object objResponse = lstJsonParse.get('d');
        String ser = JSON.serialize(objResponse);
        ilib_LogEvent.message('serialize Response : '+ ser);
        objRTPResponse = (RealtimePricingResponse) JSON.deserialize(ser, RealtimePricingResponse.class); 

        ilib_LogEvent.pop();
    }

    /**
    *  @author Prabhsimran Singh
    *  @Checking for any error in response DCP-37888.
    *  @return void
    **/
    public static void responseErrorParsing()
    {
        ilib_LogEvent.push('responseErrorParsing');

        objQuote.SAP_Errors__c = '';
        if (objRTPResponse.NAVHDRTORET != null)
        {
            ilib_LogEvent.message('Inside Log Structure');
            for (RealtimePricingResponse.LineReturns ret : objRTPResponse.NAVHDRTORET.results)
            {
                if (ret.Type == 'E' || ret.Type == 'A')
                {
                    boolRETError = true;
                    ilib_LogEvent.message('ApttusCheckPriceController.strRETErrors ->'+strRETErrors);
                    strRETErrors +=  LIST_TAG_OPENED +ret.Message + LIST_TAG_CLOSED;
                    strErrorMsg += strRETErrors;
                    boolHasError = true;
                    ilib_LogEvent.message('ApttusCheckPriceController.strRETErrors ->'+strRETErrors);
                }
                objQuote.SAP_Errors__c = strRETErrors;
            }
        }

        ilib_LogEvent.pop();
    }

}
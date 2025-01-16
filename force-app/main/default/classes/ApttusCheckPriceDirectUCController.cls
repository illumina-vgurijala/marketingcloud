/**
*    @author Kushagra Desai
*    @date   2018-12-27
*    @description   Direct Sales to UC check price
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                             Description
*       Kushagra Desai          27-Mar-2019                 Passing YCO1 from Check Price during Generate[DCP-24500]
*       Saswati Prusty          03-06-2019                  DCP-25191
*       Saswati Prusty          12-06-2019                  DCP-25687
*       Kushagra Desai          13-June-2019                DCP-26680 : Code optimization
*       Arnab Modak             25 Sep 2019                 DCP-29853 For multiple quantity change when adding fix bundle
*       Anish Pathak            25-Sept-2019                Added escapeHtml4() to address sonarcube issue
*       Rahul Bishnoi           02-Dec-2020                 INC0255210 - Do not allow discount more than 100%.
*       Arnab Modak             21-Mar-2020                 DCP-34013 - Refactored Class, validateCart() moved to ApttusCheckPriceBase class
*       Todd Newman             17-Mar-2021                 DCP-45737: add ilib logging
*       Adyasha Satapathy       06-May-2021                 DCP-38809 Bypassing for Billable Flow 
*       Prem Ranjan             07-02-2022                  CodeScan Fix - Unused Private Fields.
*       Nesar Mohan             01-Apr-2022                 CodeScan Fix - Code Comments
*       Jitesh Lakhwani         02-Aug-2022                 DCP-53975 Fix
*       Jitesh Lakhwani         23-Aug-2022                 DCP-53975, hypercare 0794448
*       Jitesh Lakhwani         09-Jan-2023                 CodeScan fix
* ------------------------------------------------------------------------------------------------------------------------------------------------
*/
global with sharing class ApttusCheckPriceDirectUCController extends ilib_RestReceiver {

    private static final String LOG_TITLE = 'CheckPriceDirectUCController';

    public static final String CONFIGID = 'Id';
    public static final String CONFIGREQUESTID = 'configRequestId';
    public static final String FLOW = 'flow';
    public static final String BUSINESSOBJECTID = 'businessObjectId';
    public static final String PRICING_STATUS_PENDING = 'Pending';
    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public Boolean boolWarning{get;set;} //DCP-53975, hypercare 0794448 
    public Boolean boolShowWarningModal{get;set;} //DCP-53975, hypercare 0794448 
    public String strWarningMessage{get;set;} //DCP-53975, hypercare 0794448
    public static final String INTEGRATION_NAME = 'Outgoing Realtime_PricingCheck';
    public static Boolean boolPricingError = false;
    public static Boolean boolRETError = false;
    public static Boolean boolEmbargoCheck = false;
    public static Boolean boolSanctionedPartyListCheck = false;
    public static Boolean boolLegalControl = false;
    public static Boolean boolQuoteError = false;
    public static string strRETErrors;
    public static String strRequstJSON;
    public static String strResponse;
    public static Boolean boolConsortia =false;

    global String strConfigId;
    global string strConfigRequestId;
    global string strFlow;
    global String strBusinessObjectId;
    public Boolean boolHasError{get; set;}
    public String strErrorMsg{get;set;}
    public Boolean boolPricingCompleted{get;set;}
    public Boolean boolValidationError;//DCP-34013
    public ilib_LogInterface.LogDetails log;
    public Boolean boolValidationStatus;
    /**
     * @description : enum, HttpMethod
    */
    public enum HttpMethod {HEAD, POST}

    /**
    *  @author Govind Dubey
    *  @description Constructor of ApttusCheckPriceController
    **/
    public ApttusCheckPriceDirectUCController(){
        /* Added escapeHtml4() to address sonarcube issue- Anish*/
        this(ApexPages.currentpage().getparameters().get(CONFIGID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGID).escapeHtml4(),
                ApexPages.currentpage().getparameters().get(CONFIGREQUESTID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGREQUESTID).escapeHtml4(),
                ApexPages.currentpage().getparameters().get(FLOW) == null ? null : ApexPages.currentpage().getparameters().get(FLOW).escapeHtml4(),
                ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID) == null ? null : ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID).escapeHtml4());
    }

    /**DCP-38809
    *  @author Adyasha Satapathy
    *  @description Constructor with Parameters
    **/
    public ApttusCheckPriceDirectUCController(String strConfigId,String strConfigRequestId,String strFlow, String strBusinessObjectId){
        this.strConfigId = strConfigId;
        this.strConfigRequestId = strConfigRequestId;
        this.strFlow = strFlow;
        this.strBusinessObjectId = strBusinessObjectId;
        boolPricingCompleted = false;
        boolHasError = false;
        boolValidationStatus = true;
        boolValidationError = false;//DCP-34013
        boolWarning = false; //DCP-53975, hypercare 0794448
        boolShowWarningModal = false; //DCP-53975, hypercare 0794448
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
        String validationValues = baseClassInstance.callSAP(true);
        this.boolHasError = Boolean.valueOf(validationValues.substringBefore('_'));
        this.strErrorMsg = validationValues.substringAfter('_');

        //Start of DCP-53975, hypercare 0794448
        if(ApttusCheckPriceBaseClass.boolWarning == true && boolHasError == false) { 
            this.boolWarning = true;
            this.boolShowWarningModal = true; 
            this.strWarningMessage = ApttusCheckPriceBaseClass.strWarningMsgs;
        }
        //Start of DCP-53975, hypercare 0794448

        ilib_LogEvent.message('boolValue ----'+boolHasError);
        ilib_LogEvent.message('boolValue2 ----'+strErrorMsg);

        ilib_LogEvent.emit();
        return;
    }

    /*
    *  @author      : Kushagra Desai
    *  @description : Method to reprice Cart
    *  @param       : None
    *  @return      : void
    */

    global void repriceCart()
    {
        ilib_LogEvent.setTitle(LOG_TITLE);
        boolPricingCompleted = ApttusCheckPriceBaseClass.repriceCart(strConfigId);
        ilib_LogEvent.message('boolPricingCompleted : '+boolPricingCompleted);
        ilib_LogEvent.emit();
    }

}
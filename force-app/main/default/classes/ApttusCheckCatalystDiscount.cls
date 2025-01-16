    /**
*    @author Rahul Sharma
*    @date   2019-04-09
*    @description   To display suggested sales discount % for PCP-4
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Rahul Sharma                09 Apr 2019          To display suggested sales discount % 
*            Rahul Sharma                17 Apr 2019          Check Custom Permission and disable API call button
*            B Kamini                    10 Dec 2019          Sonar Qube Issue Fix
*            Satya Swain                 18 Feb 2021          INC0306134 : redirect to cart issue fix
*            Jitesh Lakhwani             09-Jan-2023          Codescan fix
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ApttusCheckCatalystDiscount extends ilib_RestReceiver{
    public static final String CONFIGID = 'id';
    public static final String CONFIGREQUESTID = 'configRequestId';
    public static final String FLOW = 'flow';
    public static final String BUSINESSOBJECTID = 'businessObjectId';
    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;
    /**
     * @description : enum, HttpMethod
     */
    public enum HttpMethod {HEAD, POST}
    public static final String INTEGRATION_NAME = 'Catalyst_Pricing_Guidance';
    public static Boolean boolQuoteError = false; 
    public static string strRETErrors;
    public static String strRequestJSON;
    public Apttus_Config2__ProductConfiguration__c objConfiguration;
    public ilib_LogInterface.LogDetails log;
    public String strConfigId;
    public string strConfigRequestId;
    public string strFlow;
    public String strBusinessObjectId;
    public Boolean boolHasError{get; set;}
    public String strErrorMsg{get;set;}
    public String strResponse;
    
    /**
*  @author Rahul Sharma
*  @description Constructor of ApttusCheckCatalystDiscount
**/
    public ApttusCheckCatalystDiscount(){
        // Added by Kamini to fix SonarQube issue
        strConfigId = ApexPages.CurrentPage().getParameters().get(CONFIGID).escapeHtml4();
        // Added by Satya to fix SonarQube issue
        strConfigRequestId = ApexPages.currentpage().getparameters().get(CONFIGREQUESTID) == null ? null: ApexPages.currentpage().getparameters().get(CONFIGREQUESTID).escapeHtml4();
        strFlow = ApexPages.currentpage().getparameters().get(FLOW).escapeHtml4();
        strBusinessObjectId = ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID).escapeHtml4();
        boolQuoteError = false; 
        boolHasError = false;
    }
    
    /**
*  @author Rahul Sharma
*  @description Constructor of ApttusCheckPriceController
*  @param NA
*  @return pageReference
**/
    public PageReference redirectToCart(){
        PageReference cartPage = Page.Apttus_Config2__Cart;
        cartPage.getParameters().put(CONFIGID, strConfigId);
        cartPage.getParameters().put(CONFIGREQUESTID, strConfigRequestId);
        cartPage.getParameters().put(FLOW, strFlow);
        cartPage.getParameters().put(BUSINESSOBJECTID, strBusinessObjectId);
        return cartPage;
    }
    
    /**
*  @author Rahul Sharma
*  @description call catalyst API
*  @param NA
*  @return void
**/
    public void callCatalyst(){
        boolHasError = FeatureManagement.checkPermission('Check_Catalyst_Discount');
        System.debug('Has Catalyst Permission:'+boolHasError);
        if(!boolHasError){
            boolHasError = true;
            strErrorMsg = Label.UI_Catalyst_Access_Denied;
            return;
        }
        else{
            ApttusCheckCatalystDiscount instantiated = new ApttusCheckCatalystDiscount();
            ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
            try{
                System.debug('Calling Catalyst');
                boolHasError = false;
                Set<id> setConfigIds = new Set<id>{strConfigId};
                objConfiguration = new ApttusProductConfigurationsSelector().selectConfigWithLines(setConfigIds)[0];
                strRequestJSON = ApttusCatalyst.createJSON(objConfiguration);
                log = ilib_LogInterface.initiateLog(interfaceDetails, strRequestJSON);
                    System.debug('Catalyst Request:' + strRequestJSON);
                    HttpResponse response = ApttusSAPConnector.getCatalystDiscount(strRequestJSON); 
                    System.debug('Catalyst Response:' + response);
                    if(response.getStatusCode() != HTTP_POST_SUCCESS_CODE && response.getStatusCode() != HTTP_SUCCESS_CODE ){
                        boolHasError=true;
                        strErrorMsg = Label.UI_Failed_Catalyst_Response;
                        ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody(), strBusinessObjectId);
                        ApexExceptions.emit('ApttusCheckCatalystDiscount',log.logRecordId,response.getBody());
                    }
                    else{  
                        strResponse = response.getBody(); 
                        System.debug('Catalyst Response body:'+strResponse);
                        ApttusCatalyst.parserJSON(objConfiguration.id ,strResponse);
                    }    
            }catch(Exception e){
                System.debug(LoggingLevel.ERROR,'Error at line        : ' + e.getLineNumber());
                System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
                System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
                System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
                System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
                if(log!=null){
                    ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, e.getMessage(), strBusinessObjectId);
                    ApexExceptions.emit('ApttusCheckCatalystDiscount',log.logRecordId,e);
                }    
                else
                ApexExceptions.emit('ApttusCheckCatalystDiscount',strBusinessObjectId,e);
                this.boolHasError=true;
                this.strErrorMsg = Label.UI_Error_Contact_Admin;
            }
            if(!boolHasError && log!=null)
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, strResponse, strBusinessObjectId);
            return;
        }
    }    
}
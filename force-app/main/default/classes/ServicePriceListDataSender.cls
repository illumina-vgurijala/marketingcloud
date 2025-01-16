/***************************************************************************************************************************************
* NAME         : ServicePriceListDataSender
* DESCRIPTION  : Service PriceList Data Sender to SAP
*                    
* @AUTHOR      : Digvijay
* @DATE        : 27-Aug-2020 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/

public with sharing class ServicePriceListDataSender extends ilib_RestSender {

    //map to hold data required for sedning Request
    Map<Id,GetPricingDetails.AccountInfoWrapper> mapWOToRequestData;

    //Please note: Since these 2 are different endpoints shared by SAP. 2 custom metadata records are created.
    public static final String INTERFACE_NAME = 'Get_Customer_CSP'; //http "Head" method endpoint : This is required to get xcrsf token from SAP.
    public static final String APPLICATIONJSON = 'application/json';
    
    
    //Variables to hold the object name from where this interface is triggered.
    public static final String INTERFACE_TRIGGERED_FROM_WORK_ORDER = 'Work Order';
   /*hold http actions*/
    public enum HttpMethod {HEAD,POST} 
  
 
    
    /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - Get the access token from the SAP endpoint first.
*  @PARAM : 
*  @RETURN : void
**/
    private static HttpResponse authenticate() {
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'content-type' => APPLICATIONJSON,
                'X-CSRF-TOKEN' => 'Fetch',
                'accept' => APPLICATIONJSON
                };
                    
                    //make a request to SAP endpoint by using named credential, custom metadata type recrods.
                    HttpRequest request = UtilsRest.createHttpRequest(INTERFACE_NAME, HttpMethod.HEAD.name(), headerKeyToValue);
        return UtilsRest.send(request);
    }
    
      /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - overidded callout method
*  @PARAM : String 
*  @RETURN : void
**/
    
    public override HttpResponse executeCallout(String strJson) {
        
        //get the authenticated response.
        HttpResponse authResponse = authenticate();
        HttpResponse response=null;


        //if the authResponse is "Ok" proceed ahead to extract the information.
        if (authResponse.getStatuscode() == 200) {
            
            //extract the csrf token from the header.
            String csrfToken = authResponse.getHeader('x-csrf-token');
            
            //set cookies.
            String cookie = authResponse.getHeader('set-cookie');
            
            if (cookie.indexOf(';') > -1) cookie = cookie.substring(0, cookie.indexOf(';'));
            Map < String, String > headerKeyToValue = new Map < String, String > {
                'x-csrf-token' => csrfToken,
                    'content-type' => APPLICATIONJSON,
                    'cookie' => cookie,
                    'accept' => APPLICATIONJSON
                    };
                        
                        //populate the body by created JSON.
                        String body = createJSON();
            
            //make final request with token in header.
            HttpRequest request = UtilsRest.createHttpRequest(INTERFACE_NAME , HttpMethod.POST.name(), headerKeyToValue);
            System.debug('request ===> ' + request);
            
            //set time of the callout to 120000
            request.setTimeout(2 * 60 * 1000);
            
            //set the body to the json created.
            request.setBody(body);
            
            //send the request and capture the response.
            response = UtilsRest.send(request);
            
            //check if the status code is not 400 or a bad request.
            if (String.valueOf(response.getStatuscode()).startsWith('2')) {
                
                //get the response body
                String result = response.getBody();
                System.debug('result ===> ' + result);
                
                deserializeInputs(result);           
            } else {
                 system.debug('Error Body ' +response.getBody());         
            }
            
        } else {
              
              System.debug('Code Scan');
            //Authentication Issue. Update the error on parts order.
           // lstPartOrderToUpdate.add(new SVMXC__RMA_Shipment_Order__c(Id = partsOrderId, Submit_to_SAP__c = false,Integration_Error_Message__c = 'Authentication Issue', Integration_Status__c = 'E'));

        }
        return response;
    }
    
    
     /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - callout method to initiate callout
*  @PARAM : MAP
*  @RETURN : Boolean
**/ 
    public Boolean callout(Map<Id,GetPricingDetails.AccountInfoWrapper> mapWOToRequestData)
    {
        validateRequiredMetadataFields();
        
        this.recordId = new List<Id>(mapWOToRequestData.keyset())[0];
        this.mapWOToRequestData=mapWOToRequestData;
        log = ilib_LogInterface.initiateLog(interfaceDetails);
        
        String strErrorMessage = null;
        HttpResponse res;
        try
        {
            res = calloutImpl();
        }
        catch (Exception e)
        {
            strErrorMessage = e.getMessage() + '\n' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, 'ERROR:\n' + e.getMessage());
            throw e;
        }
        
        Boolean isSuccess = String.isBlank(strErrorMessage);
        
        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? res.getBody() : 'Exception: ' + strErrorMessage),
            recordId,
            res
        );
        
        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, recordId, null, ilib_LogInterface.RESULT_FAIL, strErrorMessage);
            ApexExceptions.emit('Interface: ' + interfaceDetails.name, log.logRecordId, strErrorMessage);
        }
        
        return isSuccess;
    }
    
  /*method  definition for method from ilib_RestSender */  
    protected override ilib_CalloutData retrieveCalloutData() {
        return null;
    }
    
    
    /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - Parts Order creation in SAP (Inbound to SAP from SVMX)
*              - This Method will return String body in JSON format which will be used in HTTP request method.
*  @PARAM : 
*  @RETURN : void
**/
    public override String createJSON() {

        String strJson=null;
        if(mapWOToRequestData!=null && !mapWOToRequestData.isEmpty()){
            GetPricingDetails.AccountInfoWrapper accountInfoWrapperObj;
            for(Id key:mapWOToRequestData.keySet()){
                accountInfoWrapperObj=mapWOToRequestData.get(key);
            }
            String soltoSAERP;
            if(accountInfoWrapperObj!=null && !accountInfoWrapperObj.lstrelatedrecords.isEmpty()){
                if(accountInfoWrapperObj.salesAreaCodeSoldTo!=null){
                soltoSAERP = AutomateBillToShipToService.getSalesAreaFromERP(accountInfoWrapperObj.salesAreaCodeSoldTo);
                }
                Datetime dt = Datetime.now();
                Long timeMilliSeconds = dt.getTime();
                String dateStringStart = ''; //initialsing string for datetime format
                dateStringStart = dateStringStart.replace( '', '\\' );
                String timeMilliSecs = dateStringStart.substring(0,1) + '/Date(' + timeMilliSeconds + ')' + dateStringStart.substring(0,1) + '/';
                
                JSONGenerator cspRequest = JSON.createGenerator(true);    
                cspRequest.writeStartObject();
                if(accountInfoWrapperObj.soldtoAccountERPId!=null){
                cspRequest.writeStringField('Customer', accountInfoWrapperObj.soldtoAccountERPId); 
                }
                if(soltoSAERP!=null && soltoSAERP.length() >= 8){
                cspRequest.writeStringField('SalesOrg', soltoSAERP.substring(0, 4));
                cspRequest.writeStringField('DistiChannel',soltoSAERP.substring(4, 6));
                cspRequest.writeStringField('Division',soltoSAERP.substring(6, 8));
                }
                if(accountInfoWrapperObj.currencyCode!=null){
                cspRequest.writeStringField('SdCurr', accountInfoWrapperObj.currencyCode);
                cspRequest.writeStringField('LocalCurr', accountInfoWrapperObj.currencyCode);
                }
                cspRequest.writeStringField('PricingDate', timeMilliSecs);
                cspRequest.writeFieldName('im_material');
                cspRequest.writeStartArray();
                
                for(SVMXC__Service_Order_Line__c sobj:(List<SVMXC__Service_Order_Line__c>)accountInfoWrapperObj.lstrelatedrecords){
                   if(!String.isBlank(sobj.SVMXC__Product__r.Material_Number__c)){
                        cspRequest.writeStartObject();    
                        cspRequest.writeStringField('Matnr', sobj.SVMXC__Product__r.Material_Number__c); 
                        cspRequest.writeEndObject(); 
                    }
                }
                
                cspRequest.writeEndArray();
                cspRequest.writeFieldName('ex_prices');
                cspRequest.writeStartArray();
                cspRequest.writeEndArray();
                cspRequest.writeFieldName('ex_return');
                cspRequest.writeStartArray();
                cspRequest.writeEndArray();
                cspRequest.writeEndObject();
                
                strJson = cspRequest.getAsString();
                
            }
            
        }
        
        //String strJson = JSON.serializePretty(priceListWrapperObj);
        System.debug(LoggingLevel.INFO, 'JSON Output:\n' + strJson);
        return strJson;
        
        
    }
    
   /* this method is the last line of defense to make sure we don't send garbage to
     the target system.  Some validation will occur before the interface is called
     but we may allow retriggers by admins so we need these sanity checks here
     it builds a list of errors which are thrown to the caller
     NOTE: a return might be a better choice, will think about that for hardening (or handle in ancestor)*/
    protected override void validateFields() {
        System.debug('need to implement this method');
    }
    
     /*method  definition for method from ilib_RestSender */  
    protected override void handleResult(HTTPResponse res) {
        System.debug('res: ' + res);
    }
    
     /*method  definition for method from ilib_RestSender */  
    private void validateRequiredMetadataFields()
    {
        Boolean metadataValid = true;
        metadataValid = metadataValid && (interfaceDetails != null && !String.isBlank(interfaceDetails.name));
        if (!metadataValid)
            throw new UtilsRest.InterfaceException('Code error, set interface details for ' + getThisClassName());
    }
    
    
    /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - Process Response from SAP
*  @PARAM : Response from SAP.
*  @RETURN : void
**/
    private void deserializeInputs(String jsonInput) {
        ResponseWrapperSAP wrapResponse= new ResponseWrapperSAP();
        wrapResponse=(ResponseWrapperSAP)System.JSON.deserialize(jsonInput, ResponseWrapperSAP.class);
        Map<String ,String> mtrlNotoListPrice=new Map<String,String>();
        List<MaterialData> matResponse=new List<MaterialData>();
        
        if(wrapResponse!=null && wrapResponse.d!=null){
            
            EXPriceWrapper arrayResponse = wrapResponse.d;
            matResponse = arrayResponse.ex_prices.results;
            
        }
        
        if(matResponse!=null && !matResponse.isEmpty()){
            for(MaterialData obj:matResponse){
                mtrlNotoListPrice.put(obj.matnr,obj.unitp);
            }
            
        }

       if(mapWOToRequestData!=null && !mapWOToRequestData.isEmpty() && !mtrlNotoListPrice.isEmpty()){

           List<SVMXC__Service_Order_Line__c> lstworkDetails= new List<SVMXC__Service_Order_Line__c>();
           Map<String ,SVMXC__Service_Order__c> mapworkOrder=new Map<String,SVMXC__Service_Order__c>();
            GetPricingDetails.AccountInfoWrapper accountInfoWrapperObj;
            for(Id key:mapWOToRequestData.keySet()){
                accountInfoWrapperObj=mapWOToRequestData.get(key);
            }
            
            if(accountInfoWrapperObj!=null && !accountInfoWrapperObj.lstrelatedrecords.isEmpty()){
                for(SVMXC__Service_Order_Line__c sobj:(List<SVMXC__Service_Order_Line__c>)accountInfoWrapperObj.lstrelatedrecords){
                    if(mtrlNotoListPrice.get(sobj.SVMXC__Product__r.Material_Number__c)!=null && mtrlNotoListPrice.get(sobj.SVMXC__Product__r.Material_Number__c)!=''){
                        SVMXC__Service_Order_Line__c wdobj=new SVMXC__Service_Order_Line__c(Id=sobj.id);
                   try{
                        wdobj.SVMXC__Estimated_Price2__c=convertStringToNumber(mtrlNotoListPrice.get(sobj.SVMXC__Product__r.Material_Number__c));
                        if(!String.IsBlank(accountInfoWrapperObj.currencyCode)){

                            wdobj.CurrencyIsoCode=accountInfoWrapperObj.currencyCode;
                        if(!mapworkOrder.ContainsKey(wdobj.SVMXC__Service_Order__c))
                            mapworkOrder.put(wdobj.SVMXC__Service_Order__c,new SVMXC__Service_Order__c(id=sobj.SVMXC__Service_Order__c,CurrencyIsoCode=wdobj.CurrencyIsoCode));
                        }
                   }Catch(Exception ex){
                        wdobj.SVMXC__Estimated_Price2__c=0;
                        wdobj.Integration_Message_Details__c=Label.PricingErrorMessage;
                   }



                         lstworkDetails.add(wdobj);
                     }
                }
            }
       
            if(!lstworkDetails.isEmpty())
                update lstworkDetails;
            if(!mapworkOrder.isEmpty())
                update mapworkOrder.values();
        

               
       }
        
        System.debug('Price List Recieved: '+mtrlNotoListPrice);
        
    }
    
    /*Reponse wrapper class */   
    
    public class ResponseWrapperSAP{
        public EXPriceWrapper d;
    }
       /*Reponse wrapper class */   
    public class EXPriceWrapper{
        public ResultWrapper ex_prices;
    }
       /*Reponse wrapper class */   
    public class ResultWrapper{
        public List<MaterialData> results;
    }
       /*Reponse wrapper class */   
    public class ResponseWrapper{
        public List<MaterialData> results = new List<MaterialData>();
    } 
       /*Reponse wrapper class */   
    public class MaterialData{
        public String kunnr ; //customer
        public String matnr ; //mat number
        public String bismt; //Old Material No
        public String matxt; //Material desc 
        public String unitp; //Unit Price
        public String custp; //Customer Price
        public String konwa; //Rate Unit
        public String mvgr1; //Material Group
        public boolean isVisible= false; //isVisible
    } 
    
    
 /*method to convert string to decimal */   
    public static Decimal convertStringToNumber(String strNumber){
        if(strNumber!=null){
            String strDecimalNumber;
            if (strNumber.contains(',') || strNumber.contains('-')){
                strDecimalNumber = strNumber.replace(',','');
                strDecimalNumber = strDecimalNumber.replace('-','');
                return (String.isBlank(strDecimalNumber) ? 0 : Decimal.valueOf(strDecimalNumber));
            }
            else{
                return (String.isBlank(strNumber) ? 0 : Decimal.valueOf(strNumber));
            }
        }
        else
            return null;
        
    }
    
    
}
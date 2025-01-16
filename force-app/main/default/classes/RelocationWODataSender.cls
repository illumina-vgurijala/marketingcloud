/***************************************************************************************************************************************
* NAME         : RelocationWODataSender
* DESCRIPTION  : CMCP-22:Relocation WO Approval Data Sender Class (Inbound to SAP from SVMX)
*                    
* @AUTHOR      : 
* @DATE        : 07-Sep-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar       07-Sep-2021         CMCP-22: Initial Version
* Dhairya Shah       11-Oct-2024             CMCM-5165      
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/

public class RelocationWODataSender extends ilib_RestSender {
    

    //Please note: Since these 2 are different endpoints shared by SAP. 2 custom metadata records are created.
    //Also the API used for Relocation is the same API for Parts Order Inbound
    public static final String INTERFACE_NAME_HEAD = 'Outgoing_PartsOrder_Head'; //http "Head" method endpoint : This is required to get xcrsf token from SAP.
    public static final String INTERFACE_NAME_POST = 'Outgoing_PartsOrder_Post'; //http "POST" method endpoint : This is required to POST JSON body to SAP. 
    private static final string PO_TYPE_RELOCATION = 'Relocation';
    private static final string ORDER_REASON_RELOCATION = 'ZRL';
    private static final string GTS_STATUS_FAILED = 'Request Failed'; 
    private static final string GTS_STATUS_BLOCK = 'GTS Block';
    private static final string GTS_STATUS_APPROVED = 'GTS Approved';
    private static final string WO_STATUS_ACCEPTED = 'Assignment Accepted';
    private static final string A2FS_PARTNER_PRIMARY_FSE = 'Partner Primary Field Service Engineer';
    private static final Integer HTTP_SUCCESS_200 = 200;
    public static final String DISTRIBUTION_CHANNEL = '02';


    public String caseId = ''; //store the case id in context
    public Case caseRecord;//this will store Case record instance
    public Account_to_Field_Support__c partnerPrimaryFSEUser;//this will store Case record instance
    public String distributorAccountId = ''; //store the case owner's AccountId

    /**
    * hold http actions.
    **/
    public enum HttpMethod {HEAD,POST} 

    /**
    * hold CalloutData.
    **/
    private class CalloutData extends ilib_CalloutData {

        Case casesRecs;
        /**
        *  CalloutData Constructor.
        **/
        public CalloutData(Case casesRecs) {
            this.casesRecs = casesRecs;
        }
    }
    /**
    * hold CalloutData.
    **/
    private CalloutData data {
        get {
            return (CalloutData) idata;
        }
    }

    
    /**
    * this class uses selectors to populate CalloutData
    **/
    protected override ilib_CalloutData retrieveCalloutData() {
            CasesSelector casesSelector = new CasesSelector();
            Case casesRecs = casesSelector.selectCases(new Set < Id > {
                recordId
            })[0];

            CalloutData dataObj = new CalloutData(casesRecs);
            caseId = dataObj.casesRecs.Id;
            caseRecord = dataObj.casesRecs;
            system.debug('caseId ' +caseId);
            return dataObj;
    }

    /**
     * // this method is the last line of defense to make sure we don't send garbage to
    // the target system.  Some validation will occur before the interface is called
    // but we may allow retriggers by admins so we need these sanity checks here
    // it builds a list of errors which are thrown to the caller
    // NOTE: a return might be a better choice, will think about that for hardening (or handle in ancestor)
    **/
    protected override void validateFields() {
    }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - Relocation WO Approval in SAP (Inbound to SAP from SVMX)
     *              - This Method will return String body in JSON format which will be used in HTTP request method.
     * @DATE - 08-Sep-2021 
     * @PARAM : 
     *  @RETURN : String JSON
     **/
    public override String createJSON() {
    
        //wrapper object holder.
        RelocationWOWrapper relocationWOWrapperInstance = new RelocationWOWrapper();

        //get the Account Sales Area Record
        AccountSalesAreaSelector accSalesAreaSelector = new AccountSalesAreaSelector();
        List<Account_Sales_Area__c> salesAreaList = new List<Account_Sales_Area__c>();
        if(caseRecord.AccountId!=null) {
            salesAreaList = accSalesAreaSelector.selectAccountSaleaArea(new Set<Id>{caseRecord.AccountId});
        }
        Account_Sales_Area__c salesArea = salesAreaDistributionChannel(salesAreaList);

        //Get Case Owner's Account
        UsersSelector userSel = new UsersSelector();
        User caseOwner = userSel.selectByUserId(new Set<Id>{caseRecord.OwnerId}).get(0);
        distributorAccountId = caseOwner.contact.AccountId;

        //get A2FS Partner Primary FSE user from Case Owner's Account.
        AccountToFieldSupportSelector a2fsSelector = new AccountToFieldSupportSelector();
        List<Account_to_Field_Support__c> a2fsList = a2fsSelector.selectAccountToFieldSupportByAccountAndRole(new Set<Id>{distributorAccountId},new Set<String>{A2FS_PARTNER_PRIMARY_FSE});
        if(!a2fsList.isEmpty())
        {
            partnerPrimaryFSEUser = a2fsList[0];
        }

        //get Partner Stock Location of distributorAccountId
        LocationsSelector locSelector = new LocationsSelector();
        List<SVMXC__Site__c> stockLocationList = locSelector.selectDistributorPartnerStockLocationByAccount(new Set<Id>{distributorAccountId});
        
        //populate wrapper variables
        relocationWOWrapperInstance.SvmxPartOrdTyp = PO_TYPE_RELOCATION;//New type as "Relocation"
        relocationWOWrapperInstance.SalesOrg = salesArea!=null? salesArea.Sales_Organization__c:'';//Get it from Case.Account->Account Sales Area [0]
        relocationWOWrapperInstance.PartOrder = caseRecord.ERP_Sales_Order__c!=null?caseRecord.ERP_Sales_Order__c:'';//Map to new ERP Sales Order field. For new case it should be blank.
        relocationWOWrapperInstance.Division = salesArea!=null? salesArea.Division__c:'';//Get it from Case.Account->Account Sales Area [0]
        relocationWOWrapperInstance.DistrChan = salesArea!=null? salesArea.Distribution_Channel__c:'';//Get it from Case.Account->Account Sales Area [0]
        relocationWOWrapperInstance.Caseid=caseRecord.CaseNumber;
        relocationWOWrapperInstance.OrdReason=ORDER_REASON_RELOCATION;//This is the new field for relocation, and should be always populated with "ZRL".ERP_Customer_ID__c

        //populate NAVHDRTOPTR wrapper list variables
        relocationWOWrapperInstance.NAVHDRTOPTR = new List<RelocationWOWrapper.NAVHDRTOPTR>();
        relocationWOWrapperInstance.NAVHDRTOPTR.add(new RelocationWOWrapper.NAVHDRTOPTR('SH',caseRecord.Relocated_Location__r.SVMX_PS_External_ID__c)); //Map ERP ID of New Relocated Location field on Case
        relocationWOWrapperInstance.NAVHDRTOPTR.add(new RelocationWOWrapper.NAVHDRTOPTR('SP',caseRecord.Account.ERP_Customer_Id__c)); //Map ERP ID of Account field on Case
        relocationWOWrapperInstance.NAVHDRTOPTR.add(new RelocationWOWrapper.NAVHDRTOPTR('SB',!stockLocationList.isEmpty()?stockLocationList[0].SVMX_PS_External_ID__c:'')); //Map ERP ID of Distributor’s Account/Channel Partner’s Account Partner Stock Location ID(Case Owner's Account)
        relocationWOWrapperInstance.NAVHDRTOPTR.add(new RelocationWOWrapper.NAVHDRTOPTR('Z3',caseRecord.SVMXC__Site__r.SVMX_PS_External_ID__c)); //Map ERP ID of Location field on Case
        
        //populate NAVHDRTORET wrapper list variables. This should go as empty array i.e. [] and not null
        relocationWOWrapperInstance.NAVHDRTORET = new List<RelocationWOWrapper.NAVHDRTORET>();

        //populate NAVHDRTOITM wrapper list variables
        relocationWOWrapperInstance.NAVHDRTOITM = new List<RelocationWOWrapper.NAVHDRTOITM>();
        relocationWOWrapperInstance.NAVHDRTOITM.add(new RelocationWOWrapper.NAVHDRTOITM(caseRecord.SVMXC__Product__r.ProductCode)); //Map Product Code from Case

        //populate NAVHDRTOHDROUT wrapper list variables.This should go as empty i.e. {}
        relocationWOWrapperInstance.NAVHDRTOHDROUT = new RelocationWOWrapper.NAVHDRTOHDROUT();
        
        //create the JSON structure of the data present in relocation wrapper.
        String strJson = JSON.serializePretty(relocationWOWrapperInstance);
        System.debug(LoggingLevel.INFO, 'JSON Output:\n' + strJson);
        return strJson;
    }

    /**
     *  @AUTHOR Gagan Sindwani
     *  @DESCRIPTION - to check if Sales area Distribution channel is '02'
     **/
    public static Account_Sales_Area__c salesAreaDistributionChannel(List<Account_Sales_Area__c> salesAreaList){
        Account_Sales_Area__c salesAreaRecord = !salesAreaList.isEmpty()?salesAreaList[0]:null;
        for(Account_Sales_Area__c salesAreaRec : salesAreaList){
            if(salesAreaRec.Distribution_Channel__c == DISTRIBUTION_CHANNEL){
                salesAreaRecord = salesAreaRec;
                break;
            }
        }
        return salesAreaRecord;
    }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - Relocation WO Approval in SAP (Inbound to SAP from SVMX)
     *              - This Method will make the authentication callout and actual callout to SAP
     * @DATE - 08-Sep-2021 
     * @PARAM : String strJson
     *  @RETURN : HttpResponse
     **/
    public override HttpResponse executeCallout(String strJson) {
        //get the authenticated response.
        HttpResponse authResponse = authenticate();
        HttpResponse response=null; 

        //update the Case if we get an error during authentication / connection.
        List < Case > lstCaseToUpdate = new List < Case > ();

        //if the authResponse is "Ok" proceed ahead to extract the information.
        if (authResponse.getStatuscode() == HTTP_SUCCESS_200) {

            //extract the csrf token from the header.
            String csrfToken = authResponse.getHeader('x-csrf-token');

            //set cookies.
            String cookie = authResponse.getHeader('set-cookie');

            if (cookie.indexOf(';') > -1) {
                cookie = cookie.substring(0, cookie.indexOf(';'));
            }
            Map < String, String > headerKeyToValue = new Map < String, String > {
                'x-csrf-token' => csrfToken,
                'content-type' => 'application/json',
                'cookie' => cookie,
                'accept' => 'application/json'
            };

            //populate the body by created JSON.
            String body = createJSON();

            //make final request with token in header.
            HttpRequest request = UtilsRest.createHttpRequest(INTERFACE_NAME_POST, HttpMethod.POST.name(), headerKeyToValue);
            System.debug('request ===> ' + request);
            
            //set time of the callout to 120000
            request.setTimeout(2 * 60 * 1000);
            
            //set the body to the json created.
            request.setBody(body);
            
            //send the request and capture the response.
            response = UtilsRest.send(request);

            //CMCP-375 Bug for CMCP-22 Story:Add response body to the Log Result Details field.
            ilib_LogInterface.addMessageToLog(log, 'SAP Response : '+response.getBody());

            //check if the status code is not 400 or a bad request.
            if (String.valueOf(response.getStatuscode()).startsWith('2')) {
                
                //get the response body
                String result = response.getBody();
                System.debug('result ===> ' + result);
                
            
                //deserialize the response received into a wrapper class and make updates to Case GTS Status as required.
                deserializeInputs(result);

            } else {
                 
                system.debug('Error Body ' +response.getBody());    
                //Its an error of some kind. Update the error on parts order.
                lstCaseToUpdate.add(new Case(Id = caseId,GTS_Status__c=GTS_STATUS_FAILED, Relocation_Integration_Message__c = 'Status Code : ' +response.getStatuscode() + ' \r\n' +'Error Message : '  +response.getBody(), Relocation_Integration_Status__c = 'E'));
            }

        } else {

            //Authentication Issue. Update the error on parts order.
            lstCaseToUpdate.add(new Case(Id = caseId,GTS_Status__c=GTS_STATUS_FAILED, Relocation_Integration_Message__c = 'Authentication Issue', Relocation_Integration_Status__c = 'E'));

        }

        if (lstCaseToUpdate != null && !lstCaseToUpdate.isEmpty()) {
            update lstCaseToUpdate;		
        }
        return response;

    }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - Get the access token from the SAP endpoint first.
     *  @PARAM : 
     *  @RETURN : HttpResponse
     **/
    private static HttpResponse authenticate() {
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'x-csrf-token' => 'fetch'
        };

        //make a request to SAP endpoint by using named credential, custom metadata type recrods.
        HttpRequest request = UtilsRest.createHttpRequest(INTERFACE_NAME_HEAD, HttpMethod.HEAD.name(), headerKeyToValue);
        return UtilsRest.send(request);
    }

     /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - Updates GTS status(Block / No Block) on Case GTS Status field
     *                  Creates a relocation WO record if GTS Status is No Block
     *  @PARAM : Response from SAP.
     *  @RETURN : void
     **/
    private void deserializeInputs(String jsonInput) {
        //update the Case record with the response received

        //this wrapper holds the JSON data recieved in response. Request and Response Wrappers are same.
        //RelocationWOWrapper wrapResponse = new RelocationWOWrapper();
        //wrapResponse = (RelocationWOWrapper) System.JSON.deserialize(jsonInput, RelocationWOWrapper.class); //deserialize the json received into a wrapper class.

        //deserialize the json received into a wrapper class. Response in same as PartsOrderDataSender
        PartsOrderResponseReceiver wrapResponse = new PartsOrderResponseReceiver();
        wrapResponse = (PartsOrderResponseReceiver) System.JSON.deserialize(jsonInput, PartsOrderResponseReceiver.class); 

        //Instantiate Case to Update results
        Case caseRecToUpdate = new Case(Id = caseId);
        
        //Check Type and Message fields of NAVHDRTORET for GTS Block.
        if (wrapResponse.d.NAVHDRTORET != null && wrapResponse.d.NAVHDRTORET.results.size()>0) {
            for(PartsOrderResponseReceiver.results wrapHdrToRet:wrapResponse.d.NAVHDRTORET.results) {
                caseRecToUpdate.Relocation_Integration_Status__c =  wrapHdrToRet.Type;
                caseRecToUpdate.Relocation_Integration_Message__c = wrapHdrToRet.Message;
                if (wrapHdrToRet.Type == 'X' || wrapHdrToRet.Type=='E') { //Errors
                    caseRecToUpdate.GTS_Status__c=GTS_STATUS_FAILED;
                } else {//Success
                    caseRecToUpdate.GTS_Status__c=wrapHdrToRet.Message.containsIgnoreCase('GTS Block')?GTS_STATUS_BLOCK: GTS_STATUS_APPROVED;
                    caseRecToUpdate.Relocation_Integration_Message__c +=caseRecToUpdate.GTS_Status__c==GTS_STATUS_BLOCK? getGTSBlockMessage(wrapHdrToRet.Message):wrapHdrToRet.Message; 
                }
            }
        }
        //NAVHDRTORET==null? Then GTS has no Blocks.
        else {
            caseRecToUpdate.GTS_Status__c = GTS_STATUS_APPROVED;
            caseRecToUpdate.Relocation_Integration_Message__c = GTS_STATUS_APPROVED;
            caseRecToUpdate.Relocation_Integration_Status__c = 'S';
        }

        //Populate ERP_Sales_Order__c field on case with DocNumber received in Response
        if(wrapResponse.d.NAVHDRTOHDROUT!=null && wrapResponse.d.NAVHDRTOHDROUT.DocNumber!=null) {
            caseRecToUpdate.ERP_Sales_Order__c=wrapResponse.d.NAVHDRTOHDROUT.DocNumber;
        }

        //create WO if GTS No Block
        if(caseRecToUpdate.GTS_Status__c==GTS_STATUS_APPROVED) {
            //Create WO Record.
            createRelocationWO();
        }
        //Update Case Record with results
            update caseRecToUpdate;		
        

    }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION -Creates a relocation WO record if GTS Status is No Block
     *  @PARAM :
     *  @RETURN : void
     **/
    private void createRelocationWO() {
        SVMXC__Service_Order__c woRec = new SVMXC__Service_Order__c();
        woRec.SVMXC__Company__c = caseRecord.AccountId;
        woRec.SVMXC__Component__c = caseRecord.SVMXC__Component__c;
        woRec.SVMXC__Product__c = caseRecord.ProductId;
        woRec.SVMXC__Contact__c = caseRecord.ContactId;
        woRec.SVMXC__Site__c = caseRecord.SVMXC__Site__c;
        woRec.RecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get('Field Service').getRecordTypeId();
        woRec.SVMXC__Order_Type__c = PO_TYPE_RELOCATION;
        woRec.SVMXC__Order_Status__c = WO_STATUS_ACCEPTED;
        woRec.SVMX_PS_Origin__c = 	caseRecord.Origin;
        woRec.SVMX_PS_Subject__c = 	'Relocation for '+caseRecord.Installed_Product_Serial_Number__c+' at '+caseRecord.Account.Name;
        // Removed this line by Dhairya for CMCM - 5165 'woRec.SVMXC__Problem_Description__c = 'Relocation for '+caseRecord.Installed_Product_Serial_Number__c+' at '+caseRecord.Account.Name;'
        woRec.SVMXC__Case__c=caseRecord.Id;
        woRec.Is_Auto_Created__c = True;//Added to bypass validation rule of WO creation from SFM Only
        if(partnerPrimaryFSEUser!=null) {
            woRec.OwnerId = partnerPrimaryFSEUser.Salesforce_User_ID__c;//Partner Primary FSE from Distributor Account
            woRec.SVMXC__Group_Member__c = partnerPrimaryFSEUser.User__c;//Partner Primary FSE from Distributor Account    
        }
        insert woRec;
    }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION -Creates a custom Error Message For GTS Block
     *  @PARAM : String message
     *  @RETURN : String Error Message
     **/
    private String getGTSBlockMessage(String message)
    {   
        //Create a Map of Custom Error Message based on Error Keyword
        Map<String,String> mapKeyToMessage = new Map<String,String>();
        mapKeyToMessage.put('Instrument Compliance', 'Installed Product '+caseRecord.Installed_Product_Serial_Number__c+' failed the Instrument Compliance check.');
        mapKeyToMessage.put('Regulatory (Medical Device) / DX', 'Installed Product '+caseRecord.Installed_Product_Serial_Number__c+' failed the Regulatory (Medical Device) check.');
        mapKeyToMessage.put('Sanctioned Party List (SPL)', 'The accounts on this transaction have failed the initial Sanctioned Party List check.');
        mapKeyToMessage.put('Embargo Screening', 'One or more accounts on this transaction have failed the initial Embargo screening check.');
    
        for(String errorKey:mapKeyToMessage.keySet()) {
            if(message.contains(errorKey)) {
                return mapKeyToMessage.get(errorKey);
            } else {
                return message;
            }
        }
        return message;
    }
    
    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION -Overriden method from interface
     **/
    protected override void handleResult(HTTPResponse res) {
        System.debug('res: ' + res);
    }
    
}
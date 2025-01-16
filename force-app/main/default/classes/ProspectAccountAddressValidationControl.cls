/*@ author       : Akshay Mohan
* @ date         : 07-02-2018
* @ Description  : ProspectAccountAddressValidationComponent Apex Controller
* Test Class for 75%: TestCustomerMasterDataSender, TestProspectAccountAddressValidationCtrl
* Test Class for 90%: TestCustomerMasterDataSender, TestProspectAccountAddressValidationCtrl
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-02-2018                 DCP-4252             Initial version
* Akshay Mohan          10-04-2018                 DCP-6494             Address Doctor integration
* Ashwin Kumar          07-06-2021                 INC0327990           Added Error Handling for Address Doctor API call and default US if Response contains multiple CountryName
* Anand Palla           26-Apr-2022                                     CodeScan Fix-Avoid Literals in If condition
* Satya Swain           01-Jun-2022                DCP-53342            Added ability to check for record level access
* Jitesh Lakhwani       6-July-2022                                     Code Scan fixes of Comments
* Nitin                 12-sept-2022               CMSI-206             Instrumentation 
* Rohit Sahu            21-May-2024                CMCM-7687            Add Platform event for Account update
*/
public with sharing class ProspectAccountAddressValidationControl {
    
    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_THREE = 3;
    //End CodeScan Fix

    public static final string UTF_VARIABLE= 'UTF-8';
    private static final String LOG_TITLE = 'ProspectAccountAddressValidationControl';
    public static final String NULLSTR = 'Null';

    /**
    * @description: AddressWrapper wrapper to store account address data to a compatible format.
    * @param : None
    * @return: None
    */
    public class AddressWrapper{
        public String strStreet,strCity,strCountry,strState,strZip,strAccountId;
       
        /**
        * @description: AddressWrapper wrapper default constructor.
        * @param : None
        * @return: None
        */
        public AddressWrapper(){}

        /**
        * @description: AddressWrapper wrapper parameterized constructor.
        * @param : Map<String,Object> wrapper
        * @return: None
        */
        public AddressWrapper(Map<String,Object> wrapper){
            strStreet = (String)wrapper.get('address1');
            strCity = (String)wrapper.get('city');
            strState = (String)wrapper.get('state');
            Object objCountry = wrapper.get('countryName');     //INC0327990
            if(objCountry instanceOf List<Object>){
                strCountry = 'United States';
            }else{
                strCountry = (String)wrapper.get('countryName');
            }
            strZip = (String)wrapper.get('postalCode');

        }

        /**
        * @description: This method will check whether the address passed is matching OR not.
        * @param : AddressWrapper objOriginal - AddressWrapper object. 
        * @return: Boolean
        */

        public Boolean equals(AddressWrapper objOriginal){
            return strStreet==objOriginal.strStreet && strCity==objOriginal.strCity && strState==objOriginal.strState && strZip==objOriginal.strZip;
        }
    }
    
    /*
    *  @author       : Akshay Mohan
    *  @description  : To Initialize the variables
    *  @param        : String Address JSON of Billing Address
    *  @return       : String
    */
    @AuraEnabled
    public static String loadPage(String strAddressJSON){
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.loadPage()');
        ilib_LogEvent.info('strAddressJSON : '+strAddressJSON);
        List<AddressWrapper> lstAddress = new List<AddressWrapper>();
        AddressWrapper wrapAccDetails = (AddressWrapper)JSON.deserialize(strAddressJSON,AddressWrapper.class);
        
        //Load labels in apex to increase performance
        Map<String,String> labelToValue = new Map<String,String>();
        labelToValue.put('UI_Label_Address_Validation_No_Addresses',System.Label.UI_Label_Address_Validation_No_Addresses);

        try{            
            lstAddress = callAddressDoctorAPI(wrapAccDetails);            
        }catch(Exception e){
            ApexExceptions.emit('ProspectAccountAddressValidationControl', wrapAccDetails.strAccountId, e,ilib_LogEvent.SALES);
            labelToValue.put('UI_Label_Address_Validation_No_Addresses',System.Label.UI_Label_Address_Validation_Address_Retrieve_Failure);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        ilib_LogEvent.info('lstAddress: ' + lstAddress);

        labelToValue.put('UI_Label_Address_Validation_Provided_Address',System.Label.UI_Label_Address_Validation_Provided_Address);
        labelToValue.put('UI_Label_Address_Validation_Provided_Address_Title',System.Label.UI_Label_Address_Validation_Provided_Address_Title);
        labelToValue.put('UI_Button_Address_Validation_Submit_To_ERP',System.Label.UI_Button_Address_Validation_Submit_To_ERP);
        labelToValue.put('UI_Label_Address_Validation_Suggested_Address_Title',System.Label.UI_Label_Address_Validation_Suggested_Address_Title);
        labelToValue.put('UI_Label_Address_Validation_Suggested_Address',System.Label.UI_Label_Address_Validation_Suggested_Address);
        labelToValue.put('Account_Account_Status_Prospect_Validation',System.Label.Account_Account_Status_Prospect_Validation);
        labelToValue.put('Account_Address_Status_Submitted',System.Label.Account_Address_Status_Submitted);
        labelToValue.put('Account_Address_Status_Not_Submitted',System.Label.Account_Address_Status_Not_Submitted);
        labelToValue.put('Account_Address_Status_Verified',System.Label.Account_Address_Status_Verified);
        labelToValue.put('UI_Label_Address_Validation_Reason_For_Resubmission',System.Label.UI_Label_Address_Validation_Reason_For_Resubmission);
        labelToValue.put('UI_Error_Address_Validation_Resumbission_Reason',System.Label.UI_Error_Address_Validation_Resumbission_Reason);
        labelToValue.put('UI_Button_Address_Validation_Resubmit_To_ERP',System.Label.UI_Button_Address_Validation_Resubmit_To_ERP);
        labelToValue.put('UI_Label_Address_Validation_Verified_Message',System.Label.UI_Label_Address_Validation_Verified_Message);
        labelToValue.put('UI_Label_Segmentation_Selection_Insufficient_Access_Error',System.Label.UI_Label_Segmentation_Selection_Insufficient_Access_Error);
        ilib_LogEvent.info('labelToValue : '+labelToValue);
        Boolean booCanReSubmit=false;
        if(Schema.sObjectType.Account.fields.Re_Submission_Reason__c.isUpdateable())// check if user has permission to update the field
            booCanReSubmit = true;
        ilib_LogEvent.info('booCanReSubmit : '+booCanReSubmit);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return '{"labelToValue" : '+JSON.serialize(labelToValue)+
                ', "lstAddress" : '+JSON.serialize(lstAddress)+                
                ', "booCanReSubmit" : '+booCanReSubmit+'}';
    }
    
    /*
    *  @author       : Akshay Mohan
    *  @description  : To trigger outbound interface to ERP
    *  @param        : String Account Id
    *  @return       : NA
    */
    @AuraEnabled
    public static void submitOutboundRequest(String strAccountId){
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.submitOutboundRequest()');
        ilib_LogEvent.info('strAccountId: ' + strAccountId);
        Interface_Call__e ii = new Interface_Call__e(Name__c = 'CustomerMasterDataSender',
                                                    Related_Record__c = strAccountId);
        
        // Emit the log data via Platform Events
        EventBus.publish(ii);
        ilib_LogEvent.info('Callout done');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    *  @author       : Rohit Sahu
    *  @description  : To trigger outbound interface to ERP
    *  @param        : String Account Id
    *  @return       : NA
    */
    public static void submitUpdateOutboundRequest(Account objNewAccount){
        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.submitUpdateOutboundRequest()');
        Interface_Call__e ii = new Interface_Call__e(Name__c = 'CustomerMasterUpdateDataSender',
                                                    Related_Record__c = objNewAccount.id,
                                                    Extra_Information__c = getMapAccountUpdates(objNewAccount));
        ilib_LogEvent.message('ii: '+ JSON.serializePretty(ii));
        // Emit the log data via Platform Events
        EventBus.publish(ii);
        ilib_LogEvent.info('Callout done');
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    private static String getMapAccountUpdates(Account objNewAccount) {
        Map<String, Object> mapToSend = new Map<String, Object>();
        for (String fieldName : CustomerMasterUpdateDataSender.ACCOUNT_FIELDS_TO_UPDATE_SAP) {
            mapToSend.put(fieldName, objNewAccount.get(fieldName));
        }
        String jsonStr = JSON.serialize(mapToSend);
        ilib_LogEvent.message('Map json: ' + jsonStr);

        return jsonStr;
    }

    /*
    *  @author       : Ashwin Kumar - INC0327990
    *  @description  : To trigger Address Doctor API call and handle the response
    *  @param        : AddressWrapper of Billing Address
    *  @return       : List<AddressWrapper> containing suggested address from Address doctor API response
    */
    public static List<AddressWrapper> callAddressDoctorAPI(AddressWrapper wrapBillingAddres){
        ilib_LogEvent.push(LOG_TITLE + '.callAddressDoctorAPI()');
        List<AddressWrapper> lstAddress = new List<AddressWrapper>();
        ilib_LogEvent.info('wrapBillingAddres: ' + wrapBillingAddres);
        Interface_Parameters__mdt parameters = UtilsRest.getConnectionParameters('Address_Doctor');
        ilib_LogEvent.info('parameters: ' + parameters);
        String strURLParameters = '';//countryCode=US&address1=5100&postalCode=92123&city=San%20Diego&state=CA
        if(String.isNotBlank(wrapBillingAddres.strStreet)){
            strURLParameters+='&address1='+EncodingUtil.urlEncode(wrapBillingAddres.strStreet, UTF_VARIABLE);
        }
        if(String.isNotBlank(wrapBillingAddres.strCity)){
            strURLParameters+='&city='+EncodingUtil.urlEncode(wrapBillingAddres.strCity, UTF_VARIABLE);
        }
        if(String.isNotBlank(wrapBillingAddres.strCountry)){
            strURLParameters+='&countryCode='+EncodingUtil.urlEncode(wrapBillingAddres.strCountry, UTF_VARIABLE);
        }
        if(String.isNotBlank(wrapBillingAddres.strState)){
            strURLParameters+='&state='+EncodingUtil.urlEncode(wrapBillingAddres.strState, UTF_VARIABLE);
        }
        if(String.isNotBlank(wrapBillingAddres.strZip)){
            strURLParameters+='&postalCode='+EncodingUtil.urlEncode(wrapBillingAddres.strZip, UTF_VARIABLE);
        }
        ilib_LogEvent.info('strURLParameters: ' + strURLParameters);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(parameters.Endpoint__c+strURLParameters);
        req.setMethod('GET');
        req.setHeader('apikey', parameters.ApiKey__c);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        HttpResponse response = new Http().send(req);
        ilib_LogEvent.info('resp: ' + response);
        ilib_LogEvent.info('Body: ' + response.getBody());
        
        Integer intResponseCode =response.getStatusCode();
        ilib_LogEvent.info('intResponseCode : '+intResponseCode);
        Map<String, Object> keyToValue;
        if(intResponseCode==200 || intResponseCode == 400){
            keyToValue = (Map<String, Object> )JSON.deserializeUntyped(response.getBody());
        }
        ilib_LogEvent.info('keyToValue : '+(keyToValue != Null ? String.valueof(keyToValue.keySet()):NULLSTR));
        if(intResponseCode==200 && keyToValue!=null){
            Integer intCount = 0;
            for(Object wrapper : (List<Object>) ((Map<String,Object>)keyToValue.get('data')).get('addresses')){
                AddressWrapper wrapObj = new AddressWrapper((Map<String,Object>)wrapper);
                if(wrapObj.equals(wrapBillingAddres)) {continue; }
                if(intCount==INTEGER_THREE) { break; }
                intCount++;
                lstAddress.add(wrapObj);
            }
            ilib_LogEvent.info('intCount : '+intCount);
        }      
        ilib_LogEvent.info('lstAddress : '+lstAddress);
        ilib_LogEvent.pop();  
        return lstAddress;
    }
}
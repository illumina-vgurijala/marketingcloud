/**
* @author Rohit Sahu
* @date   2024-05-21
* @description  CMCM-7687  CSA - SFDC Updates to send value to SAP (Parthi/Bruce)
* Test code Coverage : TestCustomerMasterUpdateDataSender
* MODIFICATION LOG:  
* -------------------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                 DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------------------------------
* Rohit Sahu                2024-05-21          CMCM-7687 Initial implementation for sending update customer to SAP.
*/
public without sharing class CustomerMasterUpdateDataSender extends ilib_RestSender {

    public static final List<String> ACCOUNT_FIELDS_TO_UPDATE_SAP = new List<String> {'Clinical_Type__c', 'ERP_Customer_Id__c'};

    /*
    * @Author:  Rohit Sahu 
    * @Description : class to call out the data
    */
    private class CalloutData extends ilib_CalloutData
    {
        Account record;

        /*
        * @Author:  Rohit Sahu 
        * @Description : parameterized constructor of class CalloutData and instantiating Account 
        * @param: Account record
        * @return: NA
        */
        public CalloutData(Account record) {
            this.record = record;
        }
    }
    
    private CalloutData data {
        get { return (CalloutData)idata; }
    }
    
    /*
    * @author: Rohit Sahu 
    * @Description :method has logic to retrieve the callout Data with help of selectors
    * @param: null
    * @return: data
    */
    protected override ilib_CalloutData retrieveCalloutData() {
        AccountsSelector accSelector = new AccountsSelector();

        Account record = accSelector.selectAccounts(new Set<Id>{ recordId })[0];

        mergeExtraInfoIntoRecord(record);
        ilib_LogEvent.message('merge result:' + JSON.serializePretty(record));

        CalloutData data = new CalloutData(record);
        return data;
    }

    private void mergeExtraInfoIntoRecord(Account record) {
        Map<String, Object> extraInformationMap =  (Map<String, Object>) JSON.deserializeUntyped(this.extraInformation);
        for(String field : ACCOUNT_FIELDS_TO_UPDATE_SAP) {
            if(extraInformationMap.containsKey(field)) {
                record.put(field, extraInformationMap.get(field));
            }
        }
    }
    
    /**
    *  @author Rohit Sahu
    *  @description   this method is the last line of defense to make sure we don't send garbage to
    *      the target system.  Some validation will occur before the interface is called
    *      but we may allow retriggers by admins so we need these sanity checks here
    *      it builds a list of errors which are thrown to the caller
    */
    protected override void validateFields() { }
    
    
    /**
    *  @author  Rohit Sahu
    *  @description    convert CalloutData to JSON
    */
    protected override String createJSON() {
        ilib_LogEvent.message('Json Called');
        
        CustomerMasterWrapper.AccountHeader cmwAccountHeader = new CustomerMasterWrapper.AccountHeader(data.record);
        
        String strJson = JSON.serialize(cmwAccountHeader,true);
        return strJson;
    }
    
    /*
    * @Author: Rohit Sahu 
    * @Description : this method has logic to handle result based on the Http response
    * @param: HTTPResponse res
    * @return: void
    */
    protected override void handleResult(HTTPResponse res) {
        ilib_LogEvent.message('res:' + res);

        if(SUCCESS_STATUS_CODES.contains(res.getStatusCode())) {
            Account objAccount = data.record;
            FeedItem post = new FeedItem();
            post.ParentId = objAccount.LastModifiedById;
            post.Body = 'Account '+ objAccount.Name +' submitted Update to ERP.';
            insert post;
        } else {
            ilib_LogEvent.error('res:' + res);
        }
    }
}
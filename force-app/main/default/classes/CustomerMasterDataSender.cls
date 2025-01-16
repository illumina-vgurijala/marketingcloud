/**
 * @author Akshay Mohan
 * @date   2018-07-02
 * @description    DCP-358: Customer Creation from SFDC to SAP MDG (INT_MDM-030-004)
 * Modification Log: *       --------
 * Akshay Mohan         02/07/2018      :   Comments Updated    Original Version
 * Karthik Madugula     06/09/2018      :   DCP-9649 Updates
 * Aman Tyagi           30 March 2022   :   CodeScan Fixes
 */
public class CustomerMasterDataSender extends ilib_RestSender {

    /*
    * @Author:  Akshay Mohan 
    * @Description : class to call out the data
    */
    private class CalloutData extends ilib_CalloutData
    {
        Account record;
        List<Sales_Area__mdt> salesAreas;

        /*
        * @Author:  Akshay Mohan 
        * @Description : parameterized constructor of class CalloutData and instantiating Account 
        * @param: Account record, List<Sales_Area__mdt> salesAreas
        * @return: NA
        */
        public CalloutData(Account record, List<Sales_Area__mdt> salesAreas) {
            this.record = record;
            this.salesAreas = salesAreas;
        }
    }
    
    private CalloutData data {
        get { return (CalloutData)idata; }
    }
    
    // this class uses selectors to populate CalloutData

    /*
    * @Author:  Akshay Mohan 
    * @Description :method has logic to retrieve the callout Data with help of selectors
    * @param: null
    * @return: NA
    */
    protected override ilib_CalloutData retrieveCalloutData()
    {
        AccountsSelector accSelector = new AccountsSelector();
        SalesAreasSelector saSelector = new SalesAreasSelector();
        List<Sales_Area__mdt> salesAreas = new List<Sales_Area__mdt>();
        
        Account record = accSelector.selectAccounts(new Set<Id>{ recordId })[0];
        
        if (String.isNotBlank(record.BillingCountryCode))
            salesAreas  = saSelector.selectSalesAreas(record.BillingCountryCode);

        System.debug('retrieveCalloutData Interface:::');
        CalloutData data = new CalloutData(record, salesAreas);
        return data;
    }

    /**
     *  @author  Akshay Mohan
     *  @description   this method is the last line of defense to make sure we don't send garbage to
     *      the target system.  Some validation will occur before the interface is called
     *      but we may allow retriggers by admins so we need these sanity checks here
     *      it builds a list of errors which are thrown to the caller
     */
    protected override void validateFields() { }

    /**
     *  @author  Akshay Mohan
     *  @description    convert CalloutData to JSON
     */
    protected override String createJSON()
    {
        System.debug('Json Called');

        List<CustomerMasterWrapper.SalesArea> lstSalesAreas = new List<CustomerMasterWrapper.SalesArea>();
        for (Sales_Area__mdt sa : data.salesAreas)
            lstSalesAreas.add(new CustomerMasterWrapper.SalesArea(sa));

        CustomerMasterWrapper.AccountHeader cmwAccountHeader = new CustomerMasterWrapper.AccountHeader(data.record, lstSalesAreas);

        String strJson = JSON.serializePretty(cmwAccountHeader);
        System.debug(LoggingLevel.INFO, 'JSON Output:\n' + strJson);
        return strJson;
    }

    /*
    * @Author: Karthik Madugula 
    * @Description : this method has logic to handle result based on the Http response
    * @param: HTTPResponse res
    * @return: void
    */
    protected override void handleResult(HTTPResponse res)
    {
        System.debug('res: '+res);
        Account objAccount = data.record;
        FeedItem post = new FeedItem();
        post.ParentId = objAccount.LastModifiedById;
        if(SUCCESS_STATUS_CODES.contains(res.getStatusCode())){
            if(Label.Account_Account_Status_Prospect_Validation!=objAccount.Account_Status__c){
                objAccount.Account_Status__c = Label.Account_Account_Status_Prospect_Validation;
                objAccount.Address_Status__c = Label.Account_Address_Status_Submitted;
                update objAccount;
            }
            post.Body = 'Account '+objAccount.Name+' submitted to ERP.';
            insert post;
        }
    }

}
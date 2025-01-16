/**
* @author Satya Swain
* @date   2018-10-30
* @description    US-736: Indicate Not Renewing Asset
* Modification Log:
* ------------------------------------------------------------------
*       Satya Swain         2018-07-27            Original Version 
*       Govind Dubey        2019-09-24            SonarQube Fixes
*       Himanshu            2019-03-29            Code Scan Fixes  
*       Prem Ranjan         20-Feb-2023           CodeScan Fixes (APEX) Variable Naming Conventions
//SonarQube Fixes 10-12-2019
* ------------------------------------------------------------------
**/
public with sharing class ApttusTerminateAssetRenewalController {
    public Id idQuotation{get;set;}
    public Id idConfigRequest;
    public Id idTempConfigRequest;
    public String strFlow;
    public static final String RECURRING = 'Recurring';
    public static final String CANCELLED = 'Cancelled';
    List<Apttus_Config2__AssetLineItem__c> lstAssetLine;
    public static final String CONFIGID = 'Id';
    public static final String CONFIGREQUESTID = 'configRequestId';
    public static final String FLOW = 'flow';
    public static final String BUSINESSOBJECTID = 'businessObjectId';
    private Integer pageSize= 10;
    Integer intNoOfPages;
    Public Integer noOfRecords{get; set;}
    public Map<Id,Apttus_Config2__AssetLineItem__c> idToAssetLineItem = new Map<Id,Apttus_Config2__AssetLineItem__c>();
    Set<Id> setLineItemAssetIds = new Set<Id>();
    List<Apttus_Config2__LineItem__c> lstLineItem;
    List<Apttus_Proposal__Proposal__c> lstQuotation;
    /**
    * @author  Satya Swain
    * @description Constructor for base class
    **/
    public ApttusTerminateAssetRenewalController(){
        // Modified as part of SonarQube Fixes
        idConfigRequest = ApexPages.CurrentPage().getParameters().get(CONFIGID).escapeHtml4();
        idTempConfigRequest = ApexPages.currentpage().getparameters().get(CONFIGREQUESTID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGREQUESTID).escapeHtml4();
        strFlow = ApexPages.currentpage().getparameters().get(FLOW) == null ? null : ApexPages.currentpage().getparameters().get(FLOW).escapeHtml4();
        idQuotation = ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID).escapeHtml4();
        System.debug('@@@'+idConfigRequest+' '+idTempConfigRequest+' '+strFlow+' '+idQuotation);
        if(idConfigRequest != null){         
            lstLineItem = new ApttusLineItemsSelector().selectLineItemsByConfigIdAndAssetLineItemId(idConfigRequest);
            if(!lstLineItem.isEmpty()){
                for(Apttus_Config2__LineItem__c objLineItem : lstLineItem){
                    setLineItemAssetIds.add(objLineItem.Apttus_Config2__AssetLineItemId__c);
                }
            }
        }
        if(idQuotation != null && idConfigRequest != null) {         
            lstQuotation = new ApttusProposalsSelector().selectByQuoteId(new Set<Id>{idQuotation});    
        }
        
    }    
    public ApexPages.StandardSetController con {
        
        get {
            if(con == null) {
                String strUC = lstQuotation.get(0).Ultimate_Consignee__c;
                String strSoldTo = lstQuotation.get(0).Apttus_Proposal__Account__c;
                con = new ApexPages.StandardSetController(Database.getQueryLocator(getStringQuery(strSoldTo,strUC,setLineItemAssetIds)));
                con.setPageSize(pageSize);
                noOfRecords = con.getResultSize();
                Decimal pages = noOfRecords / pageSize;
                intNoOfPages = (Integer)pages.round(System.RoundingMode.CEILING);
            }
            return con;
        }
        set;
    }
    /*
    *  @author       : Satya Swain
    *  @description  : get List of AssetLineItems
    *  @param        : NA
    *  @return       : List of AssetLineItems
    */
    public List<Apttus_Config2__AssetLineItem__c> getAssetLineItems(){
        lstAssetLine = (List<Apttus_Config2__AssetLineItem__c>)con.getRecords();
        return lstAssetLine;
    }
    /*
    *  @author       : Satya Swain
    *  @description  : get String of Query for StandardSetController
    *  @param        : strSoldTo- Sold to Account ID, strUC- Ultimate Consignee Id, setLineItemAssetIds- set of LineItem Ids
    *  @return       : String
    */
    public String getStringQuery(String strSoldTo,String strUC,Set<Id> setLineItemAssetIds){
        strUc = String.escapeSingleQuotes(strUC);
        strSoldTo = String.escapeSingleQuotes(strSoldTo);
        String strBaseQuery = 'SELECT Id, Name, Apttus_Config2__ProductId__r.Name,Apttus_Config2__IsInactive__c, Apttus_Config2__AccountId__r.Name,Ultimate_Consignee__r.Name,Apttus_QPConfig__ProposalId__c, Reason_Not_Renewing__c,Is_Customer_Not_Renewing__c,Status__c FROM Apttus_Config2__AssetLineItem__c WHERE Apttus_Config2__IsInactive__c = false AND Apttus_Config2__AccountId__c = :strSoldTo AND Ultimate_Consignee__c = :strUC AND Apttus_Config2__PriceType__c=:RECURRING AND Apttus_Config2__AssetStatus__c!=:CANCELLED';
        if(!setLineItemAssetIds.isEmpty()){
            strBaseQuery += ' AND Id NOT IN :setLineItemAssetIds';
        }
        return strBaseQuery;
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Save Record and redirect to cart
    *  @param        : NA
    *  @return       : PageReference
    */
    public PageReference saveAssets() {
        Boolean boolErrorFound = checkForErrors();
        if(boolErrorFound){
            showError();
        }else{
            updateRecords();
            con.save();
            return redirectToCart();
        }
        return NULL;
    }
    
    /*
    *  @author       : Satya Swain
    *  @description  : Cancel button redirection
    *  @param        : NA
    *  @return       : PageReference
    */
    public PageReference cancel(){
        con.cancel();
        return redirectToCart();
    }
    
    /*
    *  @author       : Satya Swain
    *  @description  : Method to redirect to page
    *  @param        : NA
    *  @return       : PageReference
    */
    public PageReference redirectToCart(){
        PageReference cartPage = new pagereference('/apex/apttus_Config2__Cart?id='+idConfigRequest+'&configRequestId='+idTempConfigRequest+'&flow'+strFlow+'&businessObjectId='+idQuotation+'#!/assetsgrid');
        return cartPage;
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Method to goto First Page
    *  @param        : NA
    *  @return       : void
    */
    public void firstPage(){
        if(checkForErrors() == true){
            showError();
        }else{
            updateRecords();
            con.save();
            con.setpageNumber(1);
        }
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Method to goto Previous Page
    *  @param        : NA
    *  @return       : void
    */
    public void previous(){
        if(checkForErrors() == true){
            showError();
        }else{
            Integer pageNumber = con.getPageNumber();
            updateRecords();
            con.save();
            con.setpageNumber(pageNumber-1);
        }
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Method to goto Next Page
    *  @param        : NA
    *  @return       : void
    */
    public void next(){
        if(checkForErrors() == true){
            showError();
        }else{
            Integer pageNumber = con.getPageNumber();
            updateRecords();
            con.save();
            con.setpageNumber(pageNumber+1);
        }
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Method to goto Last Page
    *  @param        : NA
    *  @return       : void
    */
    public void lastPage(){
        if(checkForErrors() == true){
            showError();
        }else{
            Integer pageNumber = intNoOfPages + 1;
            updateRecords();
            con.save();
            con.setpageNumber(pageNumber);
        }
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Method to check for Previous Page
    *  @param        : NA
    *  @return       : void
    */
    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Method to check for Next Page
    *  @param        : NA
    *  @return       : void
    */
    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Method to check for errors in page
    *  @param        : NA
    *  @return       : Boolean
    */
    public Boolean checkForErrors(){
        Boolean boolErrorFound = false;
        
        if(!lstAssetLine.isEmpty()){
            for(Apttus_Config2__AssetLineItem__c objALI : lstAssetLine){
                idToAssetLineItem.put(objALI.Id,objALI);
                if(idToAssetLineItem.get(objALI.Id).Reason_Not_Renewing__c == NULL && idToAssetLineItem.get(objALI.Id).Is_Customer_Not_Renewing__c == true){
                    boolErrorFound = true;
                }
            }
        }
        return boolErrorFound;    
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Method to update records based on user's edit
    *  @param        : NA
    *  @return       : void
    */
    public void updateRecords(){
        if(!lstAssetLine.isEmpty()){
            for(Apttus_Config2__AssetLineItem__c objALI : lstAssetLine){
                if(idToAssetLineItem.get(objALI.Id).Id == NULL){
                    idToAssetLineItem.put(objALI.Id,objALI);
                }
                if(idToAssetLineItem.get(objALI.Id).Reason_Not_Renewing__c != NULL && idToAssetLineItem.get(objALI.Id).Is_Customer_Not_Renewing__c == false){
                    idToAssetLineItem.get(objALI.Id).Reason_Not_Renewing__c = NULL;
                } 
            }
        }
    }
    /*
    *  @author       : Satya Swain
    *  @description  : Method to show error message
    *  @param        : NA
    *  @return       : void
    */
    public void showError(){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,' '+System.Label.UI_ErrorMessage_ReasonNotRenewingBlank));
    }
}
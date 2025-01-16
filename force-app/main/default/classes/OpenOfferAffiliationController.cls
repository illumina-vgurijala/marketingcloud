/**
 * @author Nesar Mohan 
 * @date   29-Aug-2022
 * @description    DCP-54439 : Controller class for custom component which lets user select Agreement Affiliates
 * Test class for 75%+ coverage : TestOpenOfferAffiliationController
 * Test class for 90%+ coverage : TestOpenOfferAffiliationController
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Nesar Mohan             29-Aug-2022         DCP-54439: Initial Version
*  -----------------------------------------------------------------------------------          
*/

public with sharing class OpenOfferAffiliationController {

    private static final String LOG_TITLE = 'OpenOfferAffiliationController';
    public static final Set<String> SET_READONLY_STATUSES = new Set<String>{Label.AgreementStatusFullySigned,Label.AgreementStatusCategoryInEffect};
    public static final Set<String> ACCOUNT_STATUS_VALUES = new Set<String> {'Active', 'Pending Obsolete','Pending Validation','Pending Upgrade','Active Prospect','Prospect Validation','Unverified','Cancelled'};

    /*
    *  @author       : Satya Swain
    *  @description  : To Initialize the component data
    *  @param        : String agreementId
    *  @return       : String JSON
    */
    @AuraEnabled(cacheable=true)
    public static String loadPage(String strAgreementId) {
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push(LOG_TITLE + '.loadPage()');
        ilib_LogEvent.message('strAgreementId: ' + strAgreementId);
        OpenOfferAgreementDetailWrapper objAgreementDetailWrapper = null;
        OpenOfferAffiliatesWrapper objAffiliateWrapper = null;        
        List<OpenOfferAffiliatesWrapper> lstOpenOfferAffiliatesWrapper = new List<OpenOfferAffiliatesWrapper>();
        Set<String> setCustomerERPIds = new Set<String>();
        Set<String> setAffiliateERPIds = new Set<String>();
        List<Account> lstAccountsInHierarchy = new List<Account>();
        Map<String,String> mapLabels = new Map<String,String>();
        Map<Id, Account> mapIdToAccount = new Map<Id, Account>();
        Map<String, Account> mapERPCustomerIdToAccount = new Map<String, Account>();
        
        try {
            Integer intCounter = -1;                
            for(Agreement_Account_Relationship__c objAgreementAccountRelationship : new AgreementAccountRelationshipSelectors().selectByAgreementId(new Set<Id>{strAgreementId})) {
                intCounter += 1;
                objAffiliateWrapper = new OpenOfferAffiliatesWrapper(objAgreementAccountRelationship,intCounter);
                lstOpenOfferAffiliatesWrapper.add(objAffiliateWrapper);
                setAffiliateERPIds.add(objAgreementAccountRelationship.Account__r.ERP_Customer_Id__c);
            }
            Apttus__APTS_Agreement__c objAgreement = new ApttusAgreementSelectors().selectAgreements(new Set<Id>{strAgreementId})[0];
            Boolean boolComponentReadOnly = SET_READONLY_STATUSES.contains(objAgreement.Apttus__Status_Category__c) || SET_READONLY_STATUSES.contains(objAgreement.Apttus__Status__c);
            if(!String.isBlank(objAgreement.Account_National_Group_Number__c)) {
                Set<String> setNationalGroupNumbers = new Set<String>{objAgreement.Account_National_Group_Number__c};
                lstAccountsInHierarchy = new AccountsSelector().selectAccountsForNationalGroupNumbers(setNationalGroupNumbers);
                
                for(Account objAccountInHierarchy : lstAccountsInHierarchy) {
                    setCustomerERPIds.add(objAccountInHierarchy.ERP_Customer_Id__c);
                    mapIdToAccount.put(objAccountInHierarchy.Id, objAccountInHierarchy);
                }

                List<Account_Sales_Area__c> lstAccountSalesArea = new AccountSalesAreaSelector().getAcntSalesAreaByAccountNGN(setNationalGroupNumbers,ACCOUNT_STATUS_VALUES);
                if(lstAccountSalesArea != null && !lstAccountSalesArea.isEmpty()) {
                    for(Account_Sales_Area__c objAccSalesArea : lstAccountSalesArea) {
                        if(String.isBlank(objAccSalesArea.Account__r.National_Group_Number__c)) { continue; }
                        if(objAccSalesArea.Sales_Organization__c == objAgreement.Sales_Org__c && objAccSalesArea.Distribution_Channel__c == objAgreement.Distribution_Channel__c) {                            
                            mapERPCustomerIdToAccount.put(objAccSalesArea.Account__r.ERP_Customer_Id__c,mapIdToAccount.get(objAccSalesArea.Account__c));
                        }
                    }
                }                
            } else {
                setCustomerERPIds.add(objAgreement.Apttus__Account__r.ERP_Customer_Id__c);
            }

            mapLabels.put('UI_Label_No_Results',Label.UI_Label_No_Results);
            mapLabels.put('UI_Message_Affiliates_Saved',Label.UI_Message_Affiliates_Saved);
            mapLabels.put('UI_Message_Affiliate_Selection_Error',Label.UI_Message_Affiliate_Selection_Error);
            mapLabels.put('UI_Section_Account_Included_In_Agreement',Label.UI_Section_Account_Included_In_Agreement);
            mapLabels.put('UI_Section_Account_Excluded_From_Agreement',Label.UI_Section_Account_Excluded_From_Agreement);
            mapLabels.put('UI_Section_Other_Account_Included_In_Agreement',Label.UI_Section_Other_Account_Included_In_Agreement);
                        
            objAgreementDetailWrapper = new OpenOfferAgreementDetailWrapper();
            objAgreementDetailWrapper.boolComponentReadOnly = boolComponentReadOnly;
            objAgreementDetailWrapper.lstCustomerERPsInHierarchy = new List<String>(setCustomerERPIds);
            objAgreementDetailWrapper.lstOpenOfferAffiliatesWrapper = lstOpenOfferAffiliatesWrapper;
            objAgreementDetailWrapper.mapLabels = mapLabels;
            objAgreementDetailWrapper.mapERPCustomerIdToAccount = mapERPCustomerIdToAccount;
            objAgreementDetailWrapper.lstAffiliateERPIds = new List<String>(setAffiliateERPIds);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return JSON.serialize(objAgreementDetailWrapper);
    }

    /*
    *  @author       : Satya Swain
    *  @description  : Method to save affiliates of agreements
    *  @param        : String affiliatesUpdateList, String affiliatesDeletionList
    *  @return       : String message
    */
    @AuraEnabled
    public static String upsertAffiliates(String affiliatesUpdateList, String affiliatesDeletionList) {
        List<Agreement_Account_Relationship__c> lstAgreementAccountRelationshipsForUpdate = null;
        List<Agreement_Account_Relationship__c> lstAgreementAccountRelationshipsForDelete = null;
        
        try {
            lstAgreementAccountRelationshipsForUpdate = (List<Agreement_Account_Relationship__c>) JSON.deserialize(affiliatesUpdateList, List<Agreement_Account_Relationship__c>.class);
            if(!String.isBlank(affiliatesDeletionList)) {
                lstAgreementAccountRelationshipsForDelete = (List<Agreement_Account_Relationship__c>) JSON.deserialize(affiliatesDeletionList, List<Agreement_Account_Relationship__c>.class);
            }
            
            if(lstAgreementAccountRelationshipsForUpdate != null && !lstAgreementAccountRelationshipsForUpdate.isEmpty()) {                
                upsert lstAgreementAccountRelationshipsForUpdate;
            }
            if(lstAgreementAccountRelationshipsForDelete != null && !lstAgreementAccountRelationshipsForDelete.isEmpty()) {
                delete lstAgreementAccountRelationshipsForDelete;
            }
            return Label.Success;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
    *  @author:         Satya
    *  @description:    wrapper class to store list of affiliates
    */
    public class OpenOfferAgreementDetailWrapper {
        Boolean boolComponentReadOnly;
        List<String> lstCustomerERPsInHierarchy;
        List<OpenOfferAffiliatesWrapper> lstOpenOfferAffiliatesWrapper;
        Map<String,String> mapLabels;
        Map<String, Account> mapERPCustomerIdToAccount;
        List<String> lstAffiliateERPIds;
    }

    /*
    *  @author:         Satya
    *  @description:    wrapper class to store list of affiliates
    */
    public class OpenOfferAffiliatesWrapper {
        String id;
        String accountName;
        String accountId;
        String customerERPNumber;
        Boolean includeInAnnualConsumableSpend;
        Boolean optInReceivingOpenOfferDiscount;
        Boolean considerForGFDiscountCalculation;
        Integer intIndex; 
        
        /* constructor */
        public OpenOfferAffiliatesWrapper(Agreement_Account_Relationship__c objAgreementAccountRelationship, Integer intIndex) {
            this.id = objAgreementAccountRelationship.Id;
            this.accountName = objAgreementAccountRelationship.Account__r.Name;
            this.accountId = '/'+objAgreementAccountRelationship.Account__c;
            this.customerERPNumber = objAgreementAccountRelationship.Customer_ERP_Number__c;
            this.includeInAnnualConsumableSpend = objAgreementAccountRelationship.Include_In_Annual_Consumable_Spend__c;
            this.optInReceivingOpenOfferDiscount = objAgreementAccountRelationship.Opt_In_Receiving_Open_Offer_Discount__c;
            this.considerForGFDiscountCalculation = objAgreementAccountRelationship.Consider_for_GF_Discount_Calculation__c;
            this.intIndex = intIndex;
        }
    }
}
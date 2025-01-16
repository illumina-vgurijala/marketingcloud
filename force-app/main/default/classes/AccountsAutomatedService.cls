/**
*    @author     Gerardo Garcia 
*    @date       16-Aug-2024 
*    @description : Handler class for Automated process with system context 
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Gerardo Garcia              07-Aug-24               CMCM-9578 - add status populators
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class AccountsAutomatedService {

    private static final String LOG_TITLE = 'AccountsAutomatedService';

    /**
     * @author: Gerardo Garcia
     * @description: updates Tier if Account's ParentId has changed.
     * @param: Account new record from trigger.
     * @param: Account old record from trigger.
     * @param: Map of Parent accounts.
     */
    public static void updateTierWhenParentIDIsAvailable(Account newRecord, Account oldRecord, Map<Id, Account> parentAccounts){
        ilib_LogEvent.push(LOG_TITLE + '.updateTierWhenParentIDIsAvailable()');
        if(String.isNotBlank(newRecord.ParentId) && (newRecord.ParentId != oldRecord.ParentId)) {
            //ParentId changed
            Account parentAccount = parentAccounts.get(newRecord.ParentId);
            newRecord.Tier__c = parentAccount.Tier__c;
        }
        ilib_LogEvent.pop();
    }

    /**
     * @author: Gerardo Garcia
     * @description: Updates District_Sales_Manager__c and Territory_Account_Manager__c to CORS 
     * from related account and update them async.
     * @param: List<Account> target accounts.
     * @param: Set<Id> target ids accounts.
     */
    public static void updateTAMandDSMvalues(List<Account> accounts, Set<Id> accountsIds) {
        ilib_LogEvent.push(LOG_TITLE + '.updateTAMandDSMvalues()');
        List<Contract_Order_Routing_Sheet__c> relCors = new CORSSelector().selectCORSFromAccountsAndStatus(accountsIds, new Set<String>{'Open','In Review'});
        Map<Id, Account> mapAccounts = new Map<Id, Account>(accounts);

        for(Contract_Order_Routing_Sheet__c entry : relCors) {
            Account relAcc = mapAccounts.get(entry.Account__c);
            entry.District_Sales_Manager__c = relAcc.Owner.ManagerId;
            entry.Territory_Account_Manager__c = relAcc.OwnerId;
        }

        ilib_LogEvent.message('updateTAMandDSMvalues@@: '+ JSON.serializePretty(relCors));

        if(!relCors.isEmpty())
            update relCors;
        ilib_LogEvent.pop();
    }

    /**
     * @author: Gerardo Garcia
     * @description:    Populates children accounts Tier__c with the same values as Parent's.
     * @param:  List<Account> target parent accounts
     */
    public static void accountUpdateTierForChildProspects(List<Account> changedAccounts) {
        ilib_LogEvent.push(LOG_TITLE + '.accountUpdateTierForChildProspects()');

        if(changedAccounts.isEmpty()) return;

        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, Account> mapParentAccounts = new Map<Id, Account>(changedAccounts);
        Set<Id> parentAccounts = UtilsCollection.getSetOfIds(changedAccounts, 'id');
        // get Children Accounts
        List<Account> childrenAccounts = new AccountsSelector().getChildrenAccounts(parentAccounts);

        ilib_LogEvent.message('Tier changed parentAccounts:' + JSON.serializePretty(changedAccounts));

        for(Account childAccount : childrenAccounts) {
            if(childAccount.RecordTypeId != AccountsService.PROSPECT_ID) continue;

            Account parentAccount = mapParentAccounts.get(childAccount.ParentId);
            if(parentAccount.Tier__c != childAccount.Tier__c) {
                childAccount.Tier__c = parentAccount.Tier__c;
                accountsToUpdate.add(childAccount);
            }
        }

        ilib_LogEvent.message('accountsToUpdate:' + JSON.serializePretty(accountsToUpdate));

        if(!accountsToUpdate.isEmpty())
            update accountsToUpdate;

        ilib_LogEvent.pop();
    }

    /**
     * @author: Gerardo Garcia
     * @description: Updates Suspension_Rejection_Reason__c if a blocker is filled otherwise will be nulled.
     * @param: Account record.
     */
    public static void updateSuspensionRejectionReason(Account acc){
        ilib_LogEvent.push(LOG_TITLE + '.updateSuspensionRejectionReason()');
        List<String> susRejReason = new List<String>();
        if(String.isNotBlank(acc.Credit_Block__c)) susRejReason.add(AccountsService.REJECT_CREDIT);
        if(String.isNotBlank(acc.Order_Block__c)) susRejReason.add(AccountsService.REJECT_ORDER);
        if(String.isNotBlank(acc.Delivery_Block__c)) susRejReason.add(AccountsService.REJECT_DELIVERY);
        if(String.isNotBlank(acc.Billing_Issue__c)) susRejReason.add(AccountsService.REJECT_BILLING);
        if(String.isNotBlank(acc.Sales_Block__c)) susRejReason.add(AccountsService.REJECT_SALES);

        if(!susRejReason.isEmpty())
            acc.Suspension_Rejection_Reason__c = String.join(susRejReason,';');
        else
            acc.Suspension_Rejection_Reason__c = null;

        ilib_LogEvent.pop();
    }

    /**
     * @author: Gerardo Garcia
     * @description: Sets Account_Status__c depending on bussiness logic.
     * @param:  Account - Target record to be populated
     */
    public static void setStatus(Account record, Account oldRecord) {
        ilib_LogEvent.push(LOG_TITLE + '.setStatus()');
        setStatusObsolete(record);
        setStatusPendingObsolete(record);
        setStatusSuspend(record);
        setStatusActive(record, oldRecord);
        setStatusCancelled(record);
        ilib_LogEvent.pop();
    }

    private static void setStatusObsolete(Account acc) {
        if(acc.Account_Group__c == Accounts.ACCOUNTGROUP_LEGACY 
            && !hasProspectRecordTypes(acc)) {
            acc.Account_Status__c = Label.AccountStatusObsolete;
        }
    }

    private static void setStatusPendingObsolete(Account acc) {
        // Record types that are NOT Indirect, Customer, Illumina are discarded.
        if(hasProspectRecordTypes(acc))
            return;

        // Mark as "Pending Obsolete".
        if(acc.Mark_For_Deletion__c && acc.Account_Group__c != Accounts.ACCOUNTGROUP_LEGACY) {
            acc.Account_Status__c = Label.AccountStatusPendingObsolete;
        }
    }

    private static void setStatusSuspend(Account acc) {
        // Record types that are NOT Indirect, Customer, Illumina are discarded.
        if(!hasProspectRecordTypes(acc))
        {
            // Mark as "Suspended".
            if(!acc.Mark_For_Deletion__c 
                && acc.Account_Group__c != Accounts.ACCOUNTGROUP_LEGACY 
                && String.isNotBlank(acc.Suspension_Rejection_Reason__c)) {
                acc.Account_Status__c = Label.AccountStatusSuspended;
            }
        } else { // Prospect Record Types
            if(String.isNotBlank(acc.Suspension_Rejection_Reason__c)) {
                acc.Account_Status__c = Label.AccountStatusSuspended;
            }
        }
    }

    private static void setStatusActive(Account acc, Account oldAcc) {
        // Record types that are NOT Indirect, Customer, Illumina are discarded.
        if(!hasProspectRecordTypes(acc)) {
             // Mark as "Active".
            if(!acc.Mark_For_Deletion__c 
                && acc.Account_Group__c != Accounts.ACCOUNTGROUP_LEGACY 
                && String.isBlank(acc.Suspension_Rejection_Reason__c)) {
                acc.Account_Status__c = Label.AccountPlanStatusActive;
            } 
        } else if(!acc.Mark_For_Deletion__c && hasBlockFieldsChanged(acc, oldAcc) && String.isBlank(acc.Suspension_Rejection_Reason__c)) {
                acc.Account_Status__c = Label.Account_Account_Status_Active_Prospect;
        }
    }

    private static Boolean hasBlockFieldsChanged(Account newObj, Account oldObj) {
        return (newObj.Mark_For_Deletion__c != oldObj.Mark_For_Deletion__c) ||
            (newObj.Credit_Block__c  != oldObj.Credit_Block__c ) ||
            (newObj.Delivery_Block__c  != oldObj.Delivery_Block__c ) ||
            (newObj.Order_Block__c  != oldObj.Order_Block__c ) ||
            (newObj.Sales_Block__c != oldObj.Sales_Block__c) ||
            (newObj.Billing_Issue__c   != oldObj.Billing_Issue__c  );
    }

    private static void setStatusCancelled(Account acc) {
        if(hasProspectRecordTypes(acc) && acc.Mark_For_Deletion__c) {
            acc.Account_Status__c = Label.AccountStatusCancelled;
        } 
    }

    private static Boolean hasProspectRecordTypes(Account acc) {
        return acc.RecordTypeId == AccountsService.PROSPECT_ID 
        || acc.RecordTypeId == AccountsService.CHANNEL_PARTNER_PROSPECT_ID;
    }
}
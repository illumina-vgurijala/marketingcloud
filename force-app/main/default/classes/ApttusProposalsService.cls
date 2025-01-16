/**
*    @author 
*    @date   
*    @description    
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-06          DCP-38809: Add isApprovalSubmitButtonVisible,isGenerateButtonVisible
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public without sharing class ApttusProposalsService {

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param Apttus_Proposal_Proposal_c objProposal
	*	@return Boolean
	**/
    public static Boolean isApprovalSubmitButtonVisible(Apttus_Proposal__Proposal__c objProposal){
        return isButtonVisible(objProposal.Submit_For_Approval__c);
    }
    /**DCP-38809
	*	@author Akshay Mohan
	*	@param Apttus_Proposal_Proposal_c objProposal
	*	@return Boolean
	**/
    public static Boolean isGenerateButtonVisible(Apttus_Proposal__Proposal__c objProposal){
        return isButtonVisible(objProposal.Generate__c);
    }
    private static Boolean isButtonVisible(String strButtonField){
        return String.isNotBlank(strButtonField) 
                && strButtonField.startsWith('<a href="/apex/');
    }

    /**called on quote insert
	*	@author 
	*	@param List<Apttus_Proposal__Proposal__c> newRecords
	*	@return void
	**
    public static void shareWithUCUsers(List<Apttus_Proposal__Proposal__c> newRecords)
    {
        shareWithUCUsers(newRecords, null, null);
    }
    /**called on opportunity update (change Sold To or UC)
	*	@author 
	*	@param List<Apttus_Proposal__Proposal__c> newRecords, Map<Id, Opportunity> idToOldOpportunities
	*	@return void
	**
    public static void shareWithUCUsers(List<Apttus_Proposal__Proposal__c> newRecords, Map<Id, Opportunity> idToOldOpportunities)
    {
        shareWithUCUsers(newRecords, idToOldOpportunities, null);
    }
    /**called on account update (change owners)
	*	@author 
	*	@param List<Apttus_Proposal__Proposal__c> newRecords, Map<Id, Account> idToOldAccounts
	*	@return void
	**
    public static void shareWithUCUsers(List<Apttus_Proposal__Proposal__c> newRecords, Map<Id, Account> idToOldAccounts)
    {
        shareWithUCUsers(newRecords, null, idToOldAccounts);
    }
    /**Apex sharing for UC owners
	*	@author 
	*	@param List<Apttus_Proposal__Proposal__c> newRecords, Map<Id, Opportunity> idToOldOpportunities, Map<Id, Account> idToOldAccounts
	*	@return void
	**
    public static void shareWithUCUsers(List<Apttus_Proposal__Proposal__c> newRecords, Map<Id, Opportunity> idToOldOpportunities, Map<Id, Account> idToOldAccounts)
    {
        ilib_LogEvent.rootTitle = 'Quote UC Sharing';
        ilib_LogEvent.push('ApttusProposalsService.shareWithUCUsers');

        // calculate shares to be added and removed
        Map<Id, UserIds> quoteIdToUCUsers = filterRecordsToShareToUC(newRecords, idToOldOpportunities, idToOldAccounts);

        Map<Id, Set<Id>> quoteIdToAddedUserIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> quoteIdToRemovedUserIds = new Map<Id, Set<Id>>();

        // map above is quote ID to users for both adding and removing
        // split that into each operation
        for (Id quoteId : quoteIdToUCUsers.keySet())
        {
            UserIds userIds = quoteIdToUCUsers.get(quoteId);

            if (!userIds.usersToRemove.isEmpty())
                quoteIdToRemovedUserIds.put(quoteId, userIds.usersToRemove);
            if (!userIds.usersToAdd.isEmpty())
                quoteIdToAddedUserIds.put(quoteId, userIds.usersToAdd);
        }

        // execute the removes, then the adds
        if (!quoteIdToRemovedUserIds.isEmpty())
        {
            ilib_LogEvent.message('quoteIdToRemovedUserIds ' + quoteIdToRemovedUserIds);
            removeSharingFromUsers(quoteIdToRemovedUserIds);
        }

        if (!quoteIdToAddedUserIds.isEmpty())
        {
            ilib_LogEvent.message('quoteIdToAddedUserIds ' + quoteIdToAddedUserIds);
            addSharingToUsers(quoteIdToAddedUserIds);
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
	*	@author 
	*	@param Map<Id, Set<Id>> recordIdToUserIds
	*	@return void
	**
    private static void addSharingToUsers(Map<Id, Set<Id>> recordIdToUserIds)
    {
        if (recordIdToUserIds.isEmpty()){ return;}

        List<Apttus_Proposal__Proposal__Share> shares = new List<Apttus_Proposal__Proposal__Share>();

        for (Id recordId : recordIdToUserIds.keySet())
        {
            if (recordId == null || recordIdToUserIds.get(recordId) == null || recordIdToUserIds.get(recordId).size() == 0) continue;
            for (Id userId : recordIdToUserIds.get(recordId))
                shares.add(new Apttus_Proposal__Proposal__Share(
                    UserOrGroupId = userId,
                    ParentId = recordId,
                    AccessLevel = 'Edit',
                    // use a custom row cause so that TAPS runs won't remove these shares
                    RowCause = Schema.Apttus_Proposal__Proposal__Share.RowCause.Indirect_Owner__c)
                );
        }

        List<Database.SaveResult> allResults = Database.insert(shares, false);
        for (Integer i = 0; i < allResults.size(); i++)
        {
            Database.SaveResult res = allResults.get(i);
            if (!res.isSuccess())
                documentDmlError(shares.get(i), res.getErrors());
            else
                ilib_LogEvent.message('Quote share inserted successfully for ' + shares.get(i));
        }
    }

    private static void removeSharingFromUsers(Map<Id, Set<Id>> recordToUserIds)
    {
        List<Apttus_Proposal__Proposal__Share> extantShareRecords =
            [SELECT Id, ParentId, UserOrGroupId
             FROM Apttus_Proposal__Proposal__Share
             WHERE ParentId IN :recordToUserIds.keySet()
             AND RowCause = :Schema.Apttus_Proposal__Proposal__Share.RowCause.Indirect_Owner__c];

        // filter to make sure we only delete the records that match the input map
        for (Integer i = extantShareRecords.size() - 1; i >= 0; i--)
        {
            Apttus_Proposal__Proposal__Share share = extantShareRecords.get(i);

            Id recId = share.ParentId;
            if (!recordToUserIds.containsKey(recId))
            {
                extantShareRecords.remove(i);
                continue;
            }

            Set<Id> userIds = recordToUserIds.get(recId);
            if (!userIds.contains(share.UserOrGroupId))
                extantShareRecords.remove(i);
        }

        List<Database.DeleteResult> allResults = Database.delete(extantShareRecords, false);
        for (Integer i = 0; i < allResults.size(); i++)
        {
            Database.DeleteResult res = allResults.get(i);
            if (!res.isSuccess())
                documentDmlError(extantShareRecords.get(i), res.getErrors());
            else
                ilib_LogEvent.message('Quote share deleted successfully for ' + extantShareRecords.get(i));
        }
    }

    private static void documentDmlError(Apttus_Proposal__Proposal__Share shareRecord, List<Database.Error> errors)
    {
        String allErrorsString = '';
        for (Database.Error e : errors)
            allErrorsString += e.getMessage() + '\n\n';

        ilib_LogEvent.message('DML error for ' + shareRecord + ', error is ' + allErrorsString);
    }

    private static Map<Id, Account> getRelatedAccountMap(List<Opportunity> opptDetails, Map<Id, Opportunity> idToOldOpportunities)
    {
        Boolean isUpdate = (idToOldOpportunities != null);

        // collect all relevant account IDs
        Set<Id> relatedAccountIds = UtilsCollection.getSetOfIds(opptDetails, 'AccountId');
        relatedAccountIds.addAll(UtilsCollection.getSetOfIds(opptDetails, 'Ultimate_Consignee__c'));
        if (isUpdate)
        {
            relatedAccountIds.addAll(UtilsCollection.getSetOfIds(idToOldOpportunities.values(), 'AccountId'));
            relatedAccountIds.addAll(UtilsCollection.getSetOfIds(idToOldOpportunities.values(), 'Ultimate_Consignee__c'));
        }
        ilib_LogEvent.message('relatedAccountIds ' + relatedAccountIds);

        return new Map<Id, Account>(new AccountsSelector().selectAccounts(relatedAccountIds));
    }

    // business logic --
    // sold to and UC owners are different
    //    AND
    // opp owner and UC owners are different
    //
    // in this method we have to manage both adds and removes
    // normally we'd query for removes but standard objects don't have custom sharing reasons
    // so we can't distinguish differing sharing reasons
    // that's why the return type includes two sets of users (add and remove)
    private static Map<Id, UserIds> filterRecordsToShareToUC(List<Apttus_Proposal__Proposal__c> newRecords, Map<Id, Opportunity> idToOldOpportunities, Map<Id, Account> idToOldAccounts)
    {
        Boolean isInsert = (idToOldOpportunities == null && idToOldAccounts == null);
        Boolean isUpdate = (idToOldOpportunities != null);
        Boolean isUpdateAccount = (idToOldAccounts != null);
        ilib_LogEvent.message('Operation: isInsert ' + isInsert + ', isUpdate ' + isUpdate + ', isUpdateAccount ' + isUpdateAccount);

        // get details of accounts (sold to and UC) related to these quotes
        Set<Id> opportunityIds = UtilsCollection.getSetOfIds(newRecords, 'Apttus_Proposal__Opportunity__c');
        Map<Id, Opportunity> idToOpportunity = new Map<Id, Opportunity>(new OpportunitySelector().selectById(opportunityIds));
        Map<Id, Account> idToAccount = getRelatedAccountMap(idToOpportunity.values(), idToOldOpportunities);

        // map quote Id to users who should be shared as well as not anymore
        Map<Id, UserIds> filteredIdToSharedUserIds = new Map<Id, UserIds>();
        for (Apttus_Proposal__Proposal__c newRecord : newRecords)
        {
            // relevant owner is on the opportunity, not the quote
            Opportunity parentOpportunity = idToOpportunity.get(newRecord.Apttus_Proposal__Opportunity__c);
            if (parentOpportunity == null) continue;

            // collect new owner IDs
            Id newOwnerId = parentOpportunity.OwnerId;
            Id newSoldToOwnerId = (idToAccount.get(parentOpportunity.AccountId) == null ? null : idToAccount.get(parentOpportunity.AccountId).OwnerId);
            Id newUCOwnerId = (idToAccount.get(parentOpportunity.Ultimate_Consignee__c) == null ? null : idToAccount.get(parentOpportunity.Ultimate_Consignee__c).OwnerId);

            if (isInsert)
            {
                // business logic
                ilib_LogEvent.message('Insert: for ' + newRecord.Id + ' : newOwnerId ' + newOwnerId + ', newSoldToOwnerId ' + newSoldToOwnerId + ', newUCOwnerId ' + newUCOwnerId);
                if (newOwnerId != newUCOwnerId && newSoldToOwnerId != newUCOwnerId)
                {
                    // share with UC owner
                    if (newUCOwnerId != null)
                        filteredIdToSharedUserIds.put(newRecord.Id, new UserIds(new Set<Id>{ newUCOwnerId }, new Set<Id>()));
                }
            }
            else if (isUpdate)
            {
                // collect old owner IDs
                Opportunity oldRecord = idToOldOpportunities.get(newRecord.Apttus_Proposal__Opportunity__c);
                Id oldOwnerId = (oldRecord == null ? null : oldRecord.OwnerId);
                Id oldSoldToOwnerId = (oldRecord == null || oldRecord.AccountId == null || idToAccount.get(oldRecord.AccountId) == null ? null : idToAccount.get(oldRecord.AccountId).OwnerId);
                Id oldUCOwnerId = (oldRecord == null || oldRecord.Ultimate_Consignee__c == null || idToAccount.get(oldRecord.Ultimate_Consignee__c) == null ? null : idToAccount.get(oldRecord.Ultimate_Consignee__c).OwnerId);

                // did anything relevant change?
                if (newOwnerId == oldOwnerId && newSoldToOwnerId == oldSoldToOwnerId && newUCOwnerId == oldUCOwnerId)
                    continue;

                // business logic
                ilib_LogEvent.message('Update new IDs: for ' + newRecord.Id + ' : newOwnerId ' + newOwnerId + ', newSoldToOwnerId ' + newSoldToOwnerId + ', newUCOwnerId ' + newUCOwnerId);
                ilib_LogEvent.message('Update old IDs: for ' + newRecord.Id + ' : oldOwnerId ' + oldOwnerId + ', oldSoldToOwnerId ' + oldSoldToOwnerId + ', oldUCOwnerId ' + oldUCOwnerId);
                Boolean willShareNewOwner = (newUCOwnerId != null && newOwnerId != newUCOwnerId && newSoldToOwnerId != newUCOwnerId);
                Boolean didShareOldOwner = (oldUCOwnerId != null && oldOwnerId != oldUCOwnerId && oldSoldToOwnerId != oldUCOwnerId);

                // share/remove with new/old UC owner
                Set<Id> usersToAdd = new Set<Id>();
                Set<Id> usersToRemove = new Set<Id>();
                if (willShareNewOwner) usersToAdd.add(newUCOwnerId);
                if (didShareOldOwner) usersToRemove.add(oldUCOwnerId);

                if (usersToAdd.isEmpty() && usersToRemove.isEmpty())
                    continue;

                filteredIdToSharedUserIds.put(newRecord.Id, new UserIds(usersToAdd, usersToRemove));
            }
            else if (isUpdateAccount)
            {
                // collect old owner IDs via account
                Id oldSoldToOwnerId = (idToOldAccounts.get(parentOpportunity.AccountId) == null ? null : idToOldAccounts.get(parentOpportunity.AccountId).OwnerId);
                Id oldUCOwnerId = (idToOldAccounts.get(parentOpportunity.Ultimate_Consignee__c) == null ? null : idToOldAccounts.get(parentOpportunity.Ultimate_Consignee__c).OwnerId);

                // did anything relevant change?
                if (newSoldToOwnerId == oldSoldToOwnerId && newUCOwnerId == oldUCOwnerId)
                    continue;

                // business logic
                ilib_LogEvent.message('Update new IDs: for ' + newRecord.Id + ' : newOwnerId ' + newOwnerId + ', newSoldToOwnerId ' + newSoldToOwnerId + ', newUCOwnerId ' + newUCOwnerId);
                ilib_LogEvent.message('Update old IDs: for ' + newRecord.Id + ' : newOwnerId ' + newOwnerId + ', oldSoldToOwnerId ' + oldSoldToOwnerId + ', oldUCOwnerId ' + oldUCOwnerId);
                Boolean willShareNewOwner = (newOwnerId != newUCOwnerId && newSoldToOwnerId != newUCOwnerId);
                Boolean didShareOldOwner = (newOwnerId != oldUCOwnerId && oldSoldToOwnerId != oldUCOwnerId);

                // share/remove with new/old UC owner
                Set<Id> usersToAdd = new Set<Id>();
                Set<Id> usersToRemove = new Set<Id>();
                if (willShareNewOwner) usersToAdd.add(newUCOwnerId);
                if (didShareOldOwner) usersToRemove.add(oldUCOwnerId);

                if (usersToAdd.isEmpty() && usersToRemove.isEmpty())
                    continue;

                filteredIdToSharedUserIds.put(newRecord.Id, new UserIds(usersToAdd, usersToRemove));
            }
        }
        ilib_LogEvent.message('filteredIdToSharedUserIds ' + filteredIdToSharedUserIds);

        return filteredIdToSharedUserIds;
    }

    /**
	*	@author 
	*	
	**
    public class UserIds
    {
        /**
        *	@author 
        *	@param Set<Id> usersToAdd, Set<Id> usersToRemove
        *	@return NA
        **
        public UserIds(Set<Id> usersToAdd, Set<Id> usersToRemove)
        {
            this.usersToAdd = usersToAdd;
            this.usersToRemove = usersToRemove;
        }

        public Set<Id> usersToAdd;
        // did not write remove logic
        // perhaps should pass in old opportunity map instead of old quote map
        public Set<Id> usersToRemove;
    }
    */
}
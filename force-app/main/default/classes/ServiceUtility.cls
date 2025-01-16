/**
* @author Shivani Jain
* @date 2nd September 2022
*
* @description DCP-43629 Utility Class for adding reusable methods related to Service
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shivani Jain            20-02-2023          DCP-59060 - Add Check for Sold To Account Status to Parts Order Sold To Population Logic
*/ 
public with sharing class ServiceUtility {
      
    private static final String LOG_TITLE = 'ServiceUtility';
    private static final Set<String> SET_EXCLUDE_ACCOUNT_STATUS = new Set<String> {'Suspended', 'Obsolete', 'Cancelled', 'Rejected', 'Unverified', 'Pending Obsolete'};

    /*******************************************************************************************************
    * @description DCP-43629 To get Sold To Account in the Account Hierarchy 
    * @param recIdToAccId Map<Id,Id> 
    * @param recIdtoSoldAccId  Map<Id,Id> 
    * @return Map<Id,Id>
    */
    public static Map<Id,Id> getSoldToAccFromAccHierarchy(Map<Id,Id> recIdToAccId, Map<Id,Id> recIdtoSoldAccId) { 
        ilib_LogEvent.push(LOG_TITLE + 'getSoldToAccFromAccHierarchy');

        Set<Id> setAccountId = new set<Id>();

        setAccountId.addAll(recIdToAccId.values());
        // logic to get the sold to account from the account hierarchy
        for(Account objAcc : new AccountsSelector().getParentAccount(setAccountId)) {
            for(Id recId: recIdToAccId.keyset()){
                if(recIdToAccId.containskey(recId) && recIdToAccId.get(recId)== objAcc.Id && objAcc.Account_Group__c !=null 
                        && objAcc.Account_Group__c == WorkOrders.STRING_ACCOUNT_ACCOUNTGROUP_SOLDTO) {
                    //START - DCP-59060
                    if(!SET_EXCLUDE_ACCOUNT_STATUS.contains(objAcc.Account_Status__c)) {
                        recIdtoSoldAccId.put(recId, objAcc.Id);
                    } else {
                        recIdtoSoldAccId.put(recId, null);
                    }
                    //END- DCP-59060
                    recIdToAccId.remove(recId);
                } else if(recIdToAccId.containskey(recId) && recIdToAccId.get(recId)== objAcc.Id && objAcc.parentid!=null) {
                    recIdToAccId.put(recId, objAcc.parentid);
                } else {
                    recIdToAccId.remove(recId); 
                }
            }
        }
        
        if(!recIdToAccId.isEmpty()) {
            getSoldToAccFromAccHierarchy(recIdToAccId, recIdtoSoldAccId);
        }

        ilib_LogEvent.pop();
        
        return recIdtoSoldAccId;
    }
}

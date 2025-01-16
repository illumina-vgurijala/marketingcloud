/**
* @author Shivani Jain
* @date 30th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Account & IP 
*/ 
public with sharing class ValidateAndAssignAccount_WOHelper {

    /*DCP-24619
    *  @AUTHOR:  Nitin Sood
    *  @DESCRIPTION: To validate and assign Account on Installed Product
    *  return : void
    */
    public static void validateAndAssignAccountOnIP(List<Sobject> records) {
                
        Set<Id> setContactIdsForAccount = new Set<Id>();
        Set<Id> setInstalledProduct = new  Set<Id>();
        Map<Id, set<Id>> contactIdToRelatedAccountIds = new Map<Id, set<Id>>();
        Map<Id, Id> contactIdToAccountId = new Map<Id, Id>(); 
        Map<Id, SVMXC__Installed_Product__c> iPIdToAccountId=new Map<Id, SVMXC__Installed_Product__c>();
        

        populateIpAndContactIdsSet(records, setInstalledProduct, setContactIdsForAccount);
        
        populateIPIdToAccountId(setInstalledProduct, iPIdToAccountId);
        
        //fetching directly and indirectly related accounts with contact linked with work order
        if(!setContactIdsForAccount.isEmpty()) {
            populateAccountRoleCollections(contactIdToRelatedAccountIds, contactIdToAccountId);
        }
        
        String profileName = fetchProfileName(setContactIdsForAccount, setInstalledProduct);

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            
            if(objWorkOrder.SVMXC__Component__c != null && IPIdToAccountId.containsKey(objWorkOrder.SVMXC__Component__c) ) {
                //checking if contact is directly or indirectly related to the account which is linked with the installed product(related to work order)
                if(objWorkOrder.SVMXC__Contact__c != null && contactIdToAccountId.containsKey(objWorkOrder.SVMXC__Contact__c) && IPIdToAccountId.get(objWorkOrder.SVMXC__Component__c).SVMXC__Company__c  != contactIdToAccountId.get(objWorkOrder.SVMXC__Contact__c) &&  contactIdToRelatedAccountIds.containsKey(objWorkOrder.SVMXC__Contact__c) && !contactIdToRelatedAccountIds.get(objWorkOrder.SVMXC__Contact__c).contains(IPIdToAccountId.get(objWorkOrder.SVMXC__Component__c).SVMXC__Company__c) ){
                    //if logged in user is not an integration user or  system admin then execute the validation 
                    if(profileName != null && !profileName.containsIgnoreCase('integration') && !profileName.equalsIgnoreCase(WorkOrders.STRING_SYSTEM_ADMINISTRATOR)){                        
                        objWorkOrder.addError(System.Label.WO_IPAccountContactValidationErrorMessage);
                    }
                    //INC0401086
                    else{
                        objWorkOrder.SVMXC__Contact__c = null;
                    }
                } else {
                    //assigining account from IP to work order if contact is null
                    objWorkOrder.SVMXC__Company__c =  IPIdToAccountId.get(objWorkOrder.SVMXC__Component__c).SVMXC__Company__c;
                }
            }
            //if IP is not present in work order then account will be derived from contact
            else if(objWorkOrder.SVMXC__Component__c == null && objWorkOrder.SVMXC__Contact__c != null && objWorkOrder.SVMXC__Company__c != null) {
                if(contactIdToAccountId.containsKey(objWorkOrder.SVMXC__Contact__c) && contactIdToAccountId.get(objWorkOrder.SVMXC__Contact__c) != objWorkOrder.SVMXC__Company__c && contactIdToRelatedAccountIds.containsKey(objWorkOrder.SVMXC__Contact__c) && !contactIdToRelatedAccountIds.get(objWorkOrder.SVMXC__Contact__c).contains(objWorkOrder.SVMXC__Company__c ) ){
                    //if logged in user is not an integration user or  system admin then execute the validation 
                    if(profileName != null && !profileName.containsIgnoreCase('integration') && !profileName.equalsIgnoreCase(WorkOrders.STRING_SYSTEM_ADMINISTRATOR)) {
                        objWorkOrder.addError(System.Label.WO_AccountContactValidationErrorMessage);
                    }
                } else{
                    if(contactIdToAccountId.containsKey(objWorkOrder.SVMXC__Contact__c) && !contactIdToRelatedAccountIds.get(objWorkOrder.SVMXC__Contact__c).contains(objWorkOrder.SVMXC__Company__c )){
                        objWorkOrder.SVMXC__Company__c = contactIdToAccountId.get(objWorkOrder.SVMXC__Contact__c);  
                    }                   
                }
            }
            //if IP and Account both are not present on Work Order then assign account which is directly related to contact.
            else if(objWorkOrder.SVMXC__Component__c == null && objWorkOrder.SVMXC__Contact__c != null && objWorkOrder.SVMXC__Company__c == null) {                  
                if(objWorkOrder.SVMXC__Company__c == null && contactIdToAccountId.containsKey(objWorkOrder.SVMXC__Contact__c)){
                    objWorkOrder.SVMXC__Company__c = contactIdToAccountId.get(objWorkOrder.SVMXC__Contact__c);                    
                }
            }                          
        }       
    }

     /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: Check for IP , Account or contact change in WorkOrder
    *  @PARAM : Map<Id , Sobject> 
    *  @RETURN:  void
    */
    public static void checkforIPvalidationNeed(Map<Id, SObject> oldRecords, List<Sobject> records) {
        // for 24619    
        List<SVMXC__Service_Order__c> lstUpdatedWorkOrders = new List<SVMXC__Service_Order__c>();
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records){
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)); 

            // for 24619
            if(objOldWorkOrder.SVMXC__Component__c != objWorkOrder.SVMXC__Component__c || objOldWorkOrder.SVMXC__Contact__c != objWorkOrder.SVMXC__Contact__c 
                    || objOldWorkOrder.SVMXC__Company__c != objWorkOrder.SVMXC__Company__c) {
                lstUpdatedWorkOrders.add(objWorkOrder);
            }
        }

        // for 24619
        if(!lstUpdatedWorkOrders.isEmpty()) {
            validateAndAssignAccountOnIP(lstUpdatedWorkOrders);
        }
    }

    /*******************************************************************************************************
     * @description populate profileName
     * @param setContactIdsForAccount Set<Id>
     * @param setInstalledProduct Set<Id>
     * @return Boolean
     */
    private static String fetchProfileName(Set<Id> setContactIdsForAccount, Set<Id> setInstalledProduct) {
        String profileName = null;

       //fetching logged in user's profile 
       if(profileName == null && !(setContactIdsForAccount.isEmpty() && setInstalledProduct.isEmpty())) {
            if (!String.isBlank(WorkOrders.loggedInUserProfileName)) {
                profileName = WorkOrders.loggedInUserProfileName;
            }
        }

        return profileName;
    }

    /*******************************************************************************************************
     * @description populate Ip And Contact Ids Set
     * @param records List<Sobject>
     * @param setInstalledProduct Set<Id>
     * @param setContactIdsForAccount Set<Id>
     * @return Boolean
     */
    private static void populateIpAndContactIdsSet(List<Sobject> records, Set<Id> setInstalledProduct, Set<Id> setContactIdsForAccount) {
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            
            if(objWorkOrder.SVMXC__Component__c != null) {
                setInstalledProduct.add(objWorkOrder.SVMXC__Component__c);
            }
        
            if(objWorkOrder.SVMXC__Contact__c != null ) {            
                setContactIdsForAccount.add(objWorkOrder.SVMXC__Contact__c);    
            } 
        }
    }

    /*******************************************************************************************************
     * @description populate iPIdToAccountId
     * @param setInstalledProduct Set<Id>
     * @param iPIdToAccountId Map<Id, SVMXC__Installed_Product__c>
     * @param setWorkOrderIdsForHealthCheck Set<Id>
     * @return void
     */
    private static void populateIPIdToAccountId(Set<Id> setInstalledProduct, Map<Id, SVMXC__Installed_Product__c> iPIdToAccountId) {
        //calling method for fetching installed product account and location which is related to Work Order
        if(!setInstalledProduct.isEmpty()) {
            for(SVMXC__Installed_Product__c objIP: WorkOrders.lstInstalledProductrecords){
                IPIdToAccountId.put(objIP.Id, objIP);
            }
        }  
    }

    /*******************************************************************************************************
     * @description populate contactIdToRelatedAccountIds & contactIdToAccountId
     * @param contactIdToRelatedAccountIds Map<Id, set<Id>>
     * @param contactIdToAccountId Map<Id, Id>
     * @return void
     */
    private static void populateAccountRoleCollections(Map<Id, set<Id>> contactIdToRelatedAccountIds, Map<Id, Id> contactIdToAccountId) {
        for(AccountContactRelation objAccConRelation : WorkOrders.lstAccountContactRelRecords) {
            if(objAccConRelation.ContactId != null ) {
                if(contactIdToRelatedAccountIds.containsKey(objAccConRelation.ContactId)) {
                    contactIdToRelatedAccountIds.get(objAccConRelation.ContactId).add(objAccConRelation.AccountId);
                } else {
                    contactIdToRelatedAccountIds.put(objAccConRelation.ContactId,new set<Id>{objAccConRelation.AccountId});
                }
            }
            if(objAccConRelation.ContactId != null && objAccConRelation.IsDirect) {
                contactIdToAccountId.put(objAccConRelation.ContactId, objAccConRelation.AccountId);
            }               
        }
    }

}

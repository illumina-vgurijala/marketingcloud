/*****************************************************************************************************************
 * Class Name: AfterInsert_InstalledProductHelper
 * 
 * Description: Helper class for logic on after insert context of Installed Product
 * 
 * Author: Raviteja
 * 
 * Date: 27-03-2022
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Raviteja Vakkalagadda      27-03-2022                       Helper class for logic on after insert context of Installed Product.
 * 
 ******************************************************************************************************************/
public with sharing class AfterInsert_InstalledProductHelper {
    /*
     * @description: Method to process the new IP's and send the email notification to Account Team
     * @author: Raviteja Vakkalagadda
     * @date: 03/28/2022
     * @returns: void
    */
    public static void processNewIpsToSendEmailNotification(List<SVMXC__Installed_Product__c> lstInstalledProducts) {
        set < String > setAccountIds = new set < String > ();
        set < Id > setProductIds = new set < Id > ();
        List < SVMXC__Installed_Product__c > listInstalledProducts = new List < SVMXC__Installed_Product__c > ();
        Map<Id, Set<SVMXC__Installed_Product__c>> locationIdForSharingToIPRecord = new Map<Id, Set<SVMXC__Installed_Product__c>>();  //locationIdToIPs

        

        for (SVMXC__Installed_Product__c objInstalledProduct : lstInstalledProducts) {
                //setInstalledProductIds.add(objInstalledProduct.Id);

                if (String.isNotBlank(objInstalledProduct.SVMXC__Status__c) && objInstalledProduct.SVMXC__Status__c.EqualsIgnoreCase('Shipped')) {

                    If(String.isNotBlank(objInstalledProduct.SVMXC__Product__c)) {
                        setProductIds.add(objInstalledProduct.SVMXC__Product__c); //store products to check Create Install WO checkbox.
                    }
    
                    if(String.isNotBlank(objInstalledProduct.SVMXC__Company__c)) {
                        setAccountIds.add(objInstalledProduct.SVMXC__Company__c); //store the qualified accounts
                    }
    
                    listInstalledProducts.add(objInstalledProduct); //store the current in context IP record to be passed in generic sendemail class.
                }

                if(objInstalledProduct.SVMXC__Site__c!= NULL) {
                    if(!locationIdForSharingToIPRecord.containsKey(objInstalledProduct.SVMXC__Site__c)) {
                        locationIdForSharingToIPRecord.put(objInstalledProduct.SVMXC__Site__c, new Set<SVMXC__Installed_Product__c>());
                    }
                    locationIdForSharingToIPRecord.get(objInstalledProduct.SVMXC__Site__c).add(objInstalledProduct);
                }
               
            }

            if (!setAccountIds.isEmpty() && !setProductIds.isEmpty() && !listInstalledProducts.isEmpty() &&
                new ProductsSelector().selectAutoWOCreationProducts(setProductIds).size() > 0) {
                sendEmailNotificationToAccountTeam(setAccountIds, lstInstalledProducts);
            }

            prepareListForCPLocationSharing(locationIdForSharingToIPRecord);
    }

    /**
     * @author Vaibhav
     * @description  [DCP-28404] - Send email notification to the local account team of the Account on the Installed Product (primary FAS, primary FSE, FSM, FAM)
     */
    private static void sendEmailNotificationToAccountTeam(set < String > setAccountIds, List < SVMXC__Installed_Product__c > lstInstalledProducts) {

        set < String > setUserRole = new set < String > { 'Primary Field Application Scientist', 'Primary Field Service Engineer', 'Field Service Manager', 'Field Application Manager' }; //specific user roles
        Map < Id, Map < String, Account_to_Field_Support__c >> accountIdToFSERoles = ServiceUtilityCollection.fetchAccountRoles(setAccountIds, setUserRole); //fetch FSE roles for the account.
        SendEmailNotification.getSendEmailParamaters('Installed_Product_Ship_Notification', lstInstalledProducts, accountIdToFSERoles, 'SVMXC__Company__c'); // sendEmail by reading the custom metadata record.

    }

     /*
     * @description: Method to process the new IP's and send the email notification to Account Team
     * @author: Raviteja Vakkalagadda
     * @date: 03/28/2022
     * @returns: void
    */
    public static void prepareListForCPLocationSharing(Map<Id, Set<SVMXC__Installed_Product__c>> locationIdForSharingToIPRecord) {
        for(SVMXC__Site__c locRec : new LocationsSelector().selectLocationsFromIds(locationIdForSharingToIPRecord.keySet())) {
            if(locRec.SVMXC__Account__c == null && (locRec.Type__c == 'Partner Stock' || locRec.Type__c == 'Distributor')) {
                InstalledProducts.lstInstalledProductsForCPLocationSharing.addAll(locationIdForSharingToIPRecord.get(locRec.Id));
            }
        }
    }
}
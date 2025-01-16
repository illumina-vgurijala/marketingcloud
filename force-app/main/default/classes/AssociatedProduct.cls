/**************************************************************************************************************************************
* NAME   : AssociatedProduct
* DESCRIPTION  : Domain class for AssociatedProductTrigger.
* Test Class- TestAssociatedProduct.cls
*  
*                    
* @AUTHOR : Priya Mukherjee
* @DATE   : 23-Oct-2023  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Priya Mukherjee         26-Oct-2023         Initial Version. Added logic for CMCM-301 to Enforc existing validations - IP, Account/Contact.
* Abhishek Yadav          16-Nov-2023         Added Logic for CMCM-263
* Dhairya Shah			      15-Feb-2024         Made major changes for for 3591 as we now to call our updatePrimaryAPonCaseWO 
                                              and dissaccociatePrimaryAPonCaseWO from trigger context
* Dhairya Shah CMCM-5753
* Abhishek Yadav          27-Feb-2024          Added Logic for CMCM-273
* Abhishek Yadav          26-March-2024        Added Logic for CMCM-295
* Pritam Yadav            27-March-2024        Added logic for CMCM-6411
****************************************************************************************************************************************/ 
public without sharing class AssociatedProduct extends ilib_SObjectDomain { 
    public static final String LOG_TITLE = 'AssociatedProducts';
    public static Map<Id, String> subscriptionProductMap = new Map<Id, String>();
    public static Map<Id,String> serviceContractProductMap = new Map<Id, String>();
    public static Set<Id> workOrderRelatedcaseIds = new Set<Id>();
    public static Set<Id> workOrderRelatedSubscriptionsId = new Set<Id>();
    public static Map<Id,List<Associated_Product__c>> caseAssociatedMap = new Map<Id,List<Associated_Product__c>>();
    public static Map<Id, SVMXC__Service_Order__c> caseIdWorkOrderMap = new Map<Id, SVMXC__Service_Order__c>();
    public static Map<Id,SVMXC__Installed_Product__c> installProductMap = new Map<Id,SVMXC__Installed_Product__c>();
    public static Map<Id,Associated_Product__c> workOrderAssociatedMap = new Map<Id,Associated_Product__c>();
    public static Map<Id, Id> businessIssueWorkOrderMap = new Map<Id, Id>();
    public static final String ASSOCIATED_PRODUCT_FEATURE_FLAG = 'ServiceAssociatedProducts';
    public static Map<Id, SVMXC__Service_Order__c> workOrderIdCaseMap = new Map<Id, SVMXC__Service_Order__c>();
    public static Set<String> subscriptionProductCodeSet = new Set<String>();
    public static final String INSERT_ENTITLEMENT_CHECK_CONTRACTCOVERAGE = 'insertConsumableWarrantyContract';
    public static final String INSERT_APPLIED_CONTRACT_ENTITLEMENT = 'insertAppliedContractEntitlement';
    public static final String INSERT_UPDATE_ENTITLEMENT_CHECK_CONTRACTCOVERAGE = 'updateConsumableWarrantyContract';
    public static final String UPDATE_APPLIED_CONTRACT_ENTITLEMENT = 'updateAppliedContractEntitlement';
    public static final String DELETE_ENTITLEMENT_CHECK_CONTRACTCOVERAGE = 'deleteConsumableWarrantyContract';
    public static final String DELETE_APPLIED_CONTRACT_ENTITLEMENT = 'deleteAppliedContractEntitlement';
    public static final String ISPRIMARY = 'isPrimary';
    public static string closeVarStr = Label.ClosedStatus;
    public static final String STRING_AP_QUEUEABLE ='APQueueable';
    public static Map<Id,String> apProductLotMap = new Map<Id,String>();//CMCM - 6411
    public static final String ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG = 'AssociatedProductsOptimization'; //CMCM - 6733
    public static  Boolean isTestRunning = false; //CMCM - 7542
    public static boolean skipAPTrigger = false; //CMCM - 8136
    public static boolean isAPLinkwithCaseWOUpdate = false; //CMCM - 8136
    public static final String INTEGRATION = 'integration';
    public static boolean addPrimaryOnInsert = false; //CMCM - 8090 making it false as per CR comments
    public static Set<Id> isInstallProductIdChanged = new Set<Id>();
    //CMCM - 6733  declare the below variables as a public static variable
    public static List<Case> casesWithContact = new List<Case>(); 
    public static List<SVMXC__Service_Order__c> workOrderWithContact = new List<SVMXC__Service_Order__c>();
    public static List<SVMXC__Installed_Product__c> ipList = new List<SVMXC__Installed_Product__c>();
    public static List<AccountContactRelation> acrList = new List<AccountContactRelation>();
    public static List<Product2> productsList = new List<Product2>(); 
    public static List<SVMXC__Service_Contract__c> lstSubscription = new List<SVMXC__Service_Contract__c>();
    public static List<Associated_product__c> apList = new List<Associated_product__c>();
    public static List<Associated_Product__c> existingAP = new List<Associated_Product__c>();
    public static List<SVMXC__Service_Order__c> lstworkOrder = new List<SVMXC__Service_Order__c>();  
    public static List<Product2> prodList = new List<Product2>(); 
    public static List<Applied_Contract__c> appliedContract = new  List<Applied_Contract__c>();
    public static List<Associated_Product__c> listAssociatedProducts = new List<Associated_Product__c>();  
    public static List<Associated_Product__c> installProductAPs = new List<Associated_Product__c>();
    public static Set<Id> appliedContractIds = new Set<Id>();
    private static Map<Id, Case> mapToUpdateCase = new Map<Id, Case> (); // CMCM-8242
    private static Map<Id, SVMXC__Service_Order__c> mapToUpdateWO = new Map<Id, SVMXC__Service_Order__c> (); // CMCM-8242
    private static String profileNameHolderVar = '';
    public static List<Profile> profileList = new List<Profile>();
    public static boolean skipWOUpdateOnAPUpdate = false; // CMCM-12852 flag added to akip WO update

    /*
    * Constructor
    */
    public AssociatedProduct(List<Associated_Product__c> sObjectList) {
        super(sObjectList);
    }
    /*
    * Constructor
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new AssociatedProduct(sObjectList);
        }
    }
    
    /*
    * @Description- Before insert logic
    */
    public override void onBeforeInsert() {
        ilib_LogEvent.push(LOG_TITLE + '.onBeforeInsert');
        if((Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || isTestRunning) && !getProfileName().containsIgnoreCase(INTEGRATION)) {
            List<Associated_Product__c> newRecord = (List<Associated_Product__c>) trigger.new;
            handleAssociatedProductsInsertOrUpdate(newRecord);
            preventCRUDonAP(newRecord); //cmcm-5753
        }
        if(Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || isTestRunning) {
            populateField(records);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    } 
    
    /*
    * @Description- Before update logic
    */
    public override void onBeforeUpdate(Map<Id, SObject> mapOld) {
        ilib_LogEvent.push(LOG_TITLE + '.onBeforeUpdate');
        List<Associated_Product__c> newRecord = new List<Associated_Product__c>();
        if(!skipAPTrigger) {
            if((Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || isTestRunning) && !getProfileName().containsIgnoreCase(INTEGRATION)) {
                newRecord = (List<Associated_Product__c>) trigger.new;
                handleAssociatedProductsInsertOrUpdate(newRecord);
                preventCRUDonAP(newRecord); //cmcm-5753
            }
        }
        if(isAPLinkwithCaseWOUpdate) {
            if((Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || isTestRunning) && !getProfileName().containsIgnoreCase(INTEGRATION)) {
                newRecord = (List<Associated_Product__c>) trigger.new;
                handleAssociatedProductsInsertOrUpdate(newRecord);
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    * @author - Dhairya Shah
    * @Description- Before Delete logic for CMCM 5753 
    */
    public override void onBeforeDelete() {
        ilib_LogEvent.push(LOG_TITLE + '.onBeforeDelete');
        if((Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || isTestRunning) && !getProfileName().containsIgnoreCase(INTEGRATION)) {
            preventCRUDonAP(records); //CMCM-5753
            prepareAppliedContractToBeDelete(records);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
  
    /*
    * @Description - on After Insert
    */
    public override void onAfterInsert() {
        ilib_LogEvent.push(LOG_TITLE + '.onAfterInsert');
        WorkOrders.setServContractIds.clear();
        if(Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || isTestRunning) {
            // Below if condition added by Dhairya Shah for CMCM 8090
            if(addPrimaryOnInsert){
                mapToUpdateCase = new Map<Id, Case>();
                mapToUpdateWO = new Map<Id,SVMXC__Service_Order__c> (); 
                updatePrimaryAPonCaseWO(records, null);
            }
            synchoronousMethodCallsAfterInsert (records); //new method added By dhairya shah for CMCM 7787
            populateAppliedContractonWOAfterInsert(records);
            caseWoDML(mapToUpdateCase, mapToUpdateWO); // CMCM-8242, shared DMLs within single method
            (new AssociatedProductsHelper(AssociatedProductsHelper.OPERATION_INSERT,(Map<Id,Associated_Product__c>)Trigger.oldMap,(Map<Id,Associated_Product__c>)Trigger.newmap)).updateIVDOnCase();
            publishAPEvent (records); //CMCM-9248
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /*
     * Description - on After Update
	 * return - void
     */
    public override void onAfterUpdate(Map<Id, SObject> mapOld) {
        ilib_LogEvent.push(LOG_TITLE + '.onAfterUpdate');
        if(!skipAPTrigger) {
            if(Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || isTestRunning) {
                mapToUpdateCase = new Map<Id, Case> (); // CMCM-8242
                mapToUpdateWO = new Map<Id, SVMXC__Service_Order__c> (); // CMCM-8242
                updatePrimaryAPonCaseWO(records,(Map<Id,Associated_Product__c>)mapOld); //CMCM -3591
                synchoronousMethodCallsAfterupdate (records, (Map<Id,Associated_Product__c>)mapOld );
                populateAppliedContractonWOAfterUpdate(records , (Map<Id,Associated_Product__c>)mapOld);
                caseWoDML(mapToUpdateCase, mapToUpdateWO); // CMCM-8242, shared DMLs within single method
                (new AssociatedProductsHelper(AssociatedProductsHelper.OPERATION_UPDATE,(Map<Id,Associated_Product__c>)Trigger.oldMap,(Map<Id,Associated_Product__c>)Trigger.newmap)).updateIVDOnCase();
                publishAPEvent (records); //CMCM-9248
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
     * Description - on After Update
	 * return - void
     */
    public override void onAfterDelete() {
        if(Feature.isOn(ASSOCIATED_PRODUCT_FEATURE_FLAG) || isTestRunning) {
            dissaccociatePrimaryAPonCaseWO(records);//CMCM -  3591 changes on after delete primary AP records 
            asynchoronousMethodCallsAfterdelete (records);
            (new AssociatedProductsHelper(AssociatedProductsHelper.OPERATION_DELETE,(Map<Id,Associated_Product__c>)Trigger.oldMap,(Map<Id,Associated_Product__c>)Trigger.newmap)).updateIVDOnCase();
            publishAPEvent (records); //CMCM-9248
        }
    }

    /*
    * @Description- handle insert/ update logic
    */
    private void handleAssociatedProductsInsertOrUpdate(List<Associated_Product__c> assocProducts) {
        ilib_LogEvent.push(LOG_TITLE + '.handleAssociatedProductsInsertOrUpdate');
        Map<Id, Associated_Product__c> caseApMap = new Map<Id, Associated_Product__c>();
        Set<Id> apRelatedcaseIds = new Set<Id>();
        Set<Id> apRelatedWOIds = new Set<Id>();
        Map<Id, Associated_Product__c> workOrderApMap = new Map<Id, Associated_Product__c>();

        for (Associated_Product__c ap : assocProducts) {
            if(ap.Case__c != null && ap.Installed_Product__c != null ){
                caseApMap.put(ap.id,ap);
                apRelatedcaseIds.add(ap.Case__c);
            }
            if(ap.Work_Order__c != null && ap.Installed_Product__c != null){
                workOrderApMap.put(ap.Id,ap);
                apRelatedWOIds.add(ap.Work_Order__c);
            }
        }
        
        ilib_LogEvent.message('caseApMap--' + caseApMap);
        ilib_LogEvent.message('apRelatedcaseIds--' + apRelatedcaseIds);
        ilib_LogEvent.message('workOrderApMap--' + workOrderApMap);
        ilib_LogEvent.message('apRelatedWOIds--' + apRelatedWOIds);
        if(caseApMap!=null && !caseApMap.isEmpty() && apRelatedcaseIds!=null && !apRelatedcaseIds.isEmpty()){
            validateCaseRelations(caseApMap,apRelatedcaseIds); //CMCM-3591 FR REVIEW
        }
        if(workOrderApMap!=null && !workOrderApMap.isEmpty() && apRelatedWOIds!=null && !apRelatedWOIds.isEmpty()){
            validateWorkOrderRelations(workOrderApMap,apRelatedWOIds); //CMCM-3591 FR REVIEW
        }
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /*
    * @Description- handle Case insert/ update logic
    */
    private void validateCaseRelations(Map<Id,Associated_Product__c> assocProductsMap,Set<Id> caseIds) {
        ilib_LogEvent.push(LOG_TITLE + '.validateCaseRelations');
        Map<Id,Associated_Product__c> newassocProductsMap = new Map<Id,Associated_Product__c>();
        //CMCM - 6733 Added an empty check with a feature flag check
        if(casesWithContact == null || casesWithContact.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG)){
            casesWithContact = new CasesSelector().selectCasesWithNonNullContact(caseIds);
        }
        Map<Id,Id> casesContactMap = new Map<Id,Id>();
        if(casesWithContact != null && !casesWithContact.isEmpty()) {
            for (Case caseRecord : casesWithContact) {
                casesContactMap.put(caseRecord.id,caseRecord.contactId);
            }
        }
        ilib_LogEvent.message('casesContactMap--' + casesContactMap);
        if(assocProductsMap != null && !assocProductsMap.isEmpty()){
            for (Id ap : assocProductsMap.keySet()) {
                if(casesContactMap.containskey(assocProductsMap.get(ap).Case__c)) {
                  newassocProductsMap.put(ap,assocProductsMap.get(ap));  
                }
            }
        }
        
        ilib_LogEvent.message('newassocProductsMap--' + newassocProductsMap);
        ilib_LogEvent.message('casesContactMap values--' + casesContactMap.values());
        ilib_LogEvent.message('casesContactMap.size()--' + casesContactMap.size());
        ilib_LogEvent.message('newassocProductsMap.size()--' +newassocProductsMap.size());
        
        if(casesContactMap != null && !casesContactMap.isEmpty() && newassocProductsMap != null && !newassocProductsMap.isEmpty()){ //CMCM-3591 FR REVIEW
            validateRelations(newassocProductsMap, casesContactMap.values());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /*
    * @Description- handle WO insert/ update logic
    */
    private void validateWorkOrderRelations(Map<Id,Associated_Product__c> assocProductsMap,Set<Id> workOrderIds) {
        ilib_LogEvent.push(LOG_TITLE + '.validateWorkOrderRelations');
        Map<Id,Associated_Product__c> newassocProductsMap = new Map<Id,Associated_Product__c>();
        Map<Id,Id> woContactMap = new Map<Id,Id>();
        if(workOrderIds != null && !workOrderIds.isEmpty() && assocProductsMap != null && !assocProductsMap.isEmpty()) {
            //CMCM - 6733 Added an empty check with a feature flag check assigned variable as a public.
            if(workOrderWithContact == null || workOrderWithContact.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG)){
                workOrderWithContact = new WorkOrdersSelector().selectWorkOrdersWithNonNullContact(workOrderIds);
            }
            if(workOrderWithContact != null && !workOrderWithContact.isEmpty()){
                for (SVMXC__Service_Order__c workOrderRecord : workOrderWithContact) {
                    if (workOrderRecord.SVMXC__Contact__c != null && workOrderRecord.SVMXC__Company__c != null ) {
                        woContactMap.put(workOrderRecord.id , workOrderRecord.SVMXC__Contact__c);
                    }
                }
            }
            if(assocProductsMap.keySet() != null && !assocProductsMap.keySet().isEmpty()){
                for (Id ap : assocProductsMap.keySet()) {
                    if(woContactMap.containskey(assocProductsMap.get(ap).Work_Order__c)) {
                        newassocProductsMap.put(ap,assocProductsMap.get(ap));  
                    }
                }
            }
            ilib_LogEvent.message('woContactMap--' + woContactMap);
            ilib_LogEvent.message('newassocProductsMap --' + newassocProductsMap);
            ilib_LogEvent.message('newassocProductsMap.size() --' + newassocProductsMap.size());
        	ilib_LogEvent.message('woContactMap.size() --' + woContactMap.size());
        }
        if(woContactMap != null && !woContactMap.isEmpty() && newassocProductsMap != null &&!newassocProductsMap.isEmpty()){ //CMCM-3591 FR REVIEW
            validateRelations(newassocProductsMap, woContactMap.values());
        }
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /*
    * @Description- handle validation of account contact relation logic
    */
    private static void validateRelations(Map<id, Associated_Product__c> apMap, List<Id> contactIds) {
        ilib_LogEvent.push(LOG_TITLE + '.validateRelations');
        
        cs_Apex_Settings__c apexSetting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());        
        // Added skip condition for GIS Illumina user, Q3'24 Regression issue
        if (profileNameHolderVar.containsIgnoreCase(INTEGRATION) ||
                apexSetting.Bypass_All_Validations__c ||
                UserInfo.getName().contains(System.Label.GIS_Illumina_UserName)) {
            return;
        }
        Set<Id> installedProductIds = new Set<Id>();
        if(apMap!=null && !apMap.isEmpty() && contactIds!=null && !contactIds.isEmpty()){
            for (Associated_Product__c ap : apMap.values()) {
                if(ap.Installed_Product__c != null){
                    installedProductIds.add(ap.Installed_Product__c);
                }
            }
            ilib_LogEvent.message('installedProductIds--' + installedProductIds);
            Map<Id,SVMXC__Installed_Product__c> ipMap = new Map<Id,SVMXC__Installed_Product__c>();
            Set<Id> accountIds = new Set<Id>();
            //CMCM - 6733 Added an empty check with a feature flag check 
            if((installedProductIds!=null && !installedProductIds.isEmpty()) && (isInstallProductIdChanged != installedProductIds || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG))){
                ipList = new InstalledProductsSelector().selectRelatedInstalledProducts(installedProductIds);
                isInstallProductIdChanged = installedProductIds;
            }
            if(ipList != null && !ipList.isEmpty()){
                for (SVMXC__Installed_Product__c ip : ipList) {
                    if (ip.SVMXC__Company__c != null) {
                        accountIds.add(ip.SVMXC__Company__c);
                        ipMap.put(ip.Id,ip);
                    }
                }
            }
            
            ilib_LogEvent.message('accountIds--' + accountIds);
            ilib_LogEvent.message('contactIds--' + contactIds);
            if((acrList ==null  || acrList.isEmpty()) && (!accountIds.isEmpty() && accountIds != null && !contactIds.isEmpty() && contactIds != null)) {
                acrList = new AccountContactRelationsSelector().getAccountContactRelactionByAccountIdAndContactId(accountIds, contactIds);
            }
            Map<Id, AccountContactRelation> relationsMap = new Map<Id, AccountContactRelation>();
            if(accountIds != null && !accountIds.isEmpty() && contactIds != null && !contactIds.isEmpty()){ //added null checks for 6733
                for (AccountContactRelation rel : acrList) {
                    if (rel.IsActive) {
                        relationsMap.put(rel.AccountId,rel);
                    }
                }
            }
            ilib_LogEvent.message('relationsMap--' + relationsMap);
            Id accountId;
            
                for (Associated_Product__c ap : apMap.values()) {
                    
                    if (ipMap.containsKey(ap.Installed_Product__c)){
                        accountId = ipMap.get(ap.Installed_Product__c).SVMXC__Company__c;
                    }
                    ilib_LogEvent.message('accountId--' + accountId);
                    if (!relationsMap.containsKey(accountId)) {
                        ap.addError(System.Label.AssociatedProduct_AccountContactRelation_Error);
                    }
                }
            ilib_LogEvent.message('Validation Complete');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        
    }

    /**
     * @Description- method to get current user profile name
     * @return  `String`
     */
    @TestVisible
    private static String getProfileName() {
        String profileName = '';
        ilib_LogEvent.push(LOG_TITLE + '.getProfileName');
        
        // Check if profileName is already set
        if (profileList == null || profileList.isEmpty()) {
            try {
                // Get the current user's Profile ID
                Id currentUserProfileId = UserInfo.getProfileId();
                
                // Fetch profile details using ProfilesSelector
                profileList = new ProfilesSelector().getProfilesById(new Set<Id>{currentUserProfileId});
                
                // Check if profiles were found and then set the profile name
                if (!profileList.isEmpty()) {
                    profileName = profileList[0].Name;
                    profileNameHolderVar = profileName;
                } else {
                    ilib_LogEvent.message('No profiles found for current user');
                }
            } catch (Exception e) {
                ilib_LogEvent.message('Exception occurred: ' + e.getMessage());
            }
        } else {
            ilib_LogEvent.message('Profile name already set: ' + profileName);
        }
        
        ilib_LogEvent.message('Exiting getProfileName method');
        ilib_LogEvent.pop();
        
        return profileName;
    }

     /**
    *  CMCM-197
    *  @author : Abhishek Yadav
    *  @description - prepare subscription map
    **/
    private static Map<Id,Id> getSubscriptionMap(Set<Id> subscriptionIds) {
        Map<Id,Id> subProductMap = new Map<Id,Id>();
        if(subscriptionIds != null && !subscriptionIds.isEmpty()) {
            Map<String,SVMXC__Service_Contract__c> productCodeBYServiceContactMap = new Map<String,SVMXC__Service_Contract__c>();
            Map<String,Id> productCodeBYProductIdMap = new Map<String,Id>();
            productCodeBYServiceContactMap = getServiceContract(subscriptionIds);
            //CMCM - 6733 Added an empty check with a feature flag check for productsList
            if(productsList == null || productsList == null || productsList.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
                productsList = new ProductsSelector().fetchProductId(subscriptionProductCodeSet);
            }
            if(productsList != null && !productsList.isEmpty()){
                for(Product2 prodObj : productsList) {
                    productCodeBYProductIdMap.put(prodObj.ProductCode,prodObj.Id);
                }
            }
            for (Id subsId : subscriptionIds) {
                if (productCodeBYProductIdMap != null && productCodeBYServiceContactMap != null && productCodeBYServiceContactMap.containsKey(subsId) && productCodeBYProductIdMap.containsKey(productCodeBYServiceContactMap.get(subsId).ProductCode__c)) {
                    subProductMap.put(subsId , productCodeBYProductIdMap.get(productCodeBYServiceContactMap.get(subsId).ProductCode__c));
                }
            }
        }
        return subProductMap;
    }
    /**
    *  CMCM-197
    *  @author : Abhishek Yadav
    *  @description - Helper method of getSubscriptionMap
    **/
    private static Map<String,SVMXC__Service_Contract__c> getServiceContract(Set<Id> subscriptionIds) {
        Map<String,SVMXC__Service_Contract__c> productCodeBYServiceContactMap = new Map<String,SVMXC__Service_Contract__c>();
        //CMCM - 6733 Added an empty check with a feature flag check for lstSubscription
        if(lstSubscription == null || lstSubscription.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
            lstSubscription = new ServiceContractSelector().selectServiceContracts(subscriptionIds);
        }
        if(lstSubscription != null && !lstSubscription.isEmpty()){
            for(SVMXC__Service_Contract__c smcObj : lstSubscription) {
                if(smcObj.ProductCode__c != null) {
                    subscriptionProductCodeSet.add(smcObj.ProductCode__c);
                    productCodeBYServiceContactMap.put(smcObj.Id ,smcObj);
                }
            }
        }
        return productCodeBYServiceContactMap;
    }
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - populate Account , Product and Location
    **/
    public static void populateField(List<sObject> associatedProductList) {
        ilib_LogEvent.push(LOG_TITLE + '.populateField');
        Set<Id> installProductids = new Set<Id>();
        Set<Id> subscriptionId = new Set<Id>();
        List<SVMXC__Service_Contract__c> serviceContractList = new List<SVMXC__Service_Contract__c>();
        Map<Id,Id> subProductMap = new Map<Id,Id>();
        if(associatedProductList != null && !associatedProductList.isEmpty()){
            for (Associated_Product__c insAssociatedPro : (List<Associated_Product__c>) associatedProductList) {
                if(insAssociatedPro.Installed_Product__c != null) {
                    installProductids.add(insAssociatedPro.Installed_Product__c);
                }
                if(insAssociatedPro.Subscription__c != null) {
                    subscriptionId.add(insAssociatedPro.Subscription__c);
                }
            }
        }
        
        if(installProductids != null && !installProductids.isEmpty()) {
            //CMCM - 6733 Added an empty check with a feature flag check for ipList
            if(ipList == null || ipList.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
                ipList = new InstalledProductsSelector().selectRelatedInstalledProducts(installProductids);
            }
        }
        if (subscriptionId != null && !subscriptionId.isEmpty()) {
            subProductMap = getSubscriptionMap(subscriptionId);
        }
        if(ipList != null && !ipList.isEmpty()){
            for(SVMXC__Installed_Product__c installProduct : ipList) {
                installProductMap.put(installProduct.Id, installProduct);
            }
        }
        populateFieldHelper(associatedProductList , subProductMap);
        ilib_LogEvent.message('ipList--' + ipList);
        ilib_LogEvent.message('serviceContractList--' + serviceContractList);
        ilib_LogEvent.message('installProductMap--' + installProductMap);
        ilib_LogEvent.message('subProductMap--' + subProductMap);
    }
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - helper method of populateField
    **/
    public static void populateFieldHelper(List<sObject> associatedProductList , Map<Id,Id> subProductMap) {
        if(associatedProductList != null && !associatedProductList.isEmpty()){
            for (Associated_Product__c insAP : (List<Associated_Product__c>) associatedProductList) {
                if(insAP.Installed_Product__c != null) {
                    // popuate InstallProduct related info
                    populateInstallProductRelatedInfo(insAP);
                }
                if(insAP.Subscription__c != null && subProductMap.containsKey(insAP.Subscription__c) && subProductMap.get(insAP.Subscription__c) != null) {
                    insAP.Product__c = subProductMap.get(insAP.Subscription__c);
                }
            }
        }
    }
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - populate Install Product Related Info on Associated Product
    **/
    public static void populateInstallProductRelatedInfo(Associated_Product__c insAP) {
        if (installProductMap.containsKey(insAP.Installed_Product__c) && installProductMap.get(insAP.Installed_Product__c).SVMXC__Product__c != null) {
            insAP.Product__c = installProductMap.get(insAP.Installed_Product__c).SVMXC__Product__c;
        }
        if (installProductMap.containsKey(insAP.Installed_Product__c) && installProductMap.get(insAP.Installed_Product__c).SVMXC__Company__c != null) {
            insAP.Account__c = installProductMap.get(insAP.Installed_Product__c).SVMXC__Company__c;
        }
        if (installProductMap.containsKey(insAP.Installed_Product__c) && installProductMap.get(insAP.Installed_Product__c).SVMXC__Site__c != null) {
            insAP.Location__c =  installProductMap.get(insAP.Installed_Product__c).SVMXC__Site__c;
        }
    }
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - insert Associated Product on Case Creation
    **/
    public static void addAssociatedProductsOnCaseCreation (List<sObject> csList, List<SVMXC__Service_Order__c> woList) {
        ilib_LogEvent.push(LOG_TITLE + '.addAssociatedProductsOnCaseCreation');        
        createCaseRelatedMap(csList , woList);
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>();
        if(csList != null && !csList.isEmpty()){
            for(case cs : (List<Case>) csList) {
                // check if AP is already created from Work Order
                if((workOrderAssociatedMap.containsKey(cs.Work_Order__c) && workOrderAssociatedMap.get(cs.Work_Order__c) != null) || (workOrderAssociatedMap.containsKey(cs.Id) && workOrderAssociatedMap.get(cs.Id) != null)) {
                    Associated_Product__c assocProd = workOrderAssociatedMap.containsKey(cs.Work_Order__c) ? workOrderAssociatedMap.get(cs.Work_Order__c) : workOrderAssociatedMap.get(cs.Id);
                    assocProd.Case__c = cs.id;
                    insertAssociatedProd.add(assocProd);
                    return;
                }
               // handle multiple lookup on case
               List<Associated_Product__c> multipleAssProdList =  populateAssociatedProduct(cs);
                if (!multipleAssProdList.isEmpty()) {
                        insertAssociatedProd.addAll(multipleAssProdList);
                }
                // if there is single loopkup on Install product , Subscription & Product
                List<Associated_Product__c> singleAssProdList = singleAssociatedProduct(cs);
                if (!singleAssProdList.isEmpty()) {
                    insertAssociatedProd.addAll(singleAssProdList);
                }
            }
        }
		ilib_LogEvent.message('insertAssociatedProd--' + insertAssociatedProd);
        ilib_LogEvent.message('subscriptionProductMap--' + subscriptionProductMap);
        if (insertAssociatedProd!=null && !insertAssociatedProd.isEmpty()) {
            upsert insertAssociatedProd;
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
     /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - helper method of addAssociatedProductsOnCaseCreation for creating
    **/
    private static void createCaseRelatedMap(List<sObject> csList ,List<SVMXC__Service_Order__c> woList) {
        Set<Id> subsId = new Set<Id>();
        if(csList!=null && !csList.isEmpty()){
            for(case cse : (List<Case>) csList) {
                if (cse.Subscription__c != null) {
                    subsId.add(cse.Subscription__c);
                }
                if(cse.Work_Order__c != null) {
                    businessIssueWorkOrderMap.put(cse.Work_Order__c,cse.Id);
                }
            }
        }
        if (subsId != null && !subsId.isEmpty()) {
            subscriptionProductMap = getSubscriptionMap(subsId);
        }
        createCaseRelatedMapHelper(woList);
    }
     /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - helper method of createCaseRelatedMapHelpers
    **/
    private static void createCaseRelatedMapHelper(List<SVMXC__Service_Order__c> woList) {
        if(woList != null && !woList.isEmpty()){
            for(SVMXC__Service_Order__c wo : woList) {
                caseIdWorkOrderMap.put(wo.SVMXC__Case__c,wo);
                businessIssueWorkOrderMap.put(wo.Id,wo.SVMXC__Case__c);
            }
        }
        
        //CMCM - 6733 Added an empty check with a feature flag check for apList & used variable in for loop
        if(apList == null || apList.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
            apList = new AssociatedProductSelector().selectAPwithWorkOrder(businessIssueWorkOrderMap.keySet());
        }

        //for (Associated_product__c ap : new AssociatedProductSelector().selectAPwithWorkOrder(businessIssueWorkOrderMap.keySet())) { //CMCM - 6733
        if(apList != null && !apList.isEmpty()){
            for(Associated_product__c ap :apList){
                if (ap.Work_Order__c != null) {
                   workOrderAssociatedMap.put(ap.Work_Order__c,ap);
                }
                if (ap.Case__c != null) {
                    workOrderAssociatedMap.put(ap.Case__c,ap);
                }
            }
        }
    }
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - helper method of addAssociatedProductsOnCaseCreation
    **/
    private static List<Associated_Product__c> populateAssociatedProduct(Case cs) {
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>(); 
        // if product and Subscription are populated and Subscription's product same as Associated product
        if(cs.SVMXC__Product__c != null && cs.Subscription__c != null && subscriptionProductMap.get(cs.Subscription__c) != null && cs.SVMXC__Product__c == subscriptionProductMap.get(cs.Subscription__c) && String.isBlank(cs.SVMXC__Component__c)) {
            Associated_Product__c prodsubAP = associatedSubscription(cs , true);
            prodsubAP.Product__c = cs.SVMXC__Product__c;
            insertAssociatedProd.add(prodsubAP);
        }
        // if Install product and  Subscription are populated
        if(!String.isBlank(cs.SVMXC__Component__c) && !String.isBlank(cs.Subscription__c)) {
            Associated_Product__c installAP = associatedInstallProduct(cs);
            insertAssociatedProd.add(installAP);
            Associated_Product__c subAP = associatedSubscription(cs , false);
            insertAssociatedProd.add(subAP); 
        }
        // if product and  Subscription are populated and Subscription's product not same as product
        if(cs.SVMXC__Product__c != null && cs.Subscription__c != null && String.isBlank(cs.SVMXC__Component__c)  && (subscriptionProductMap.get(cs.Subscription__c) == null || cs.SVMXC__Product__c != subscriptionProductMap.get(cs.Subscription__c))) {
            Associated_Product__c prodAP = associatedProd(cs);
            insertAssociatedProd.add(prodAP);
            Associated_Product__c subscriptionAP = associatedSubscription(cs , false);
            insertAssociatedProd.add(subscriptionAP);
        }
        return insertAssociatedProd;
    }
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - helper method of addAssociatedProductsOnCaseCreation
    **/
    private static List<Associated_Product__c> singleAssociatedProduct(Case cs) {
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>();
        // if Install product is populated and Subscription is not populated
        if(!String.isBlank(cs.SVMXC__Component__c) && String.isBlank(cs.Subscription__c)) {
            Associated_Product__c installProdAP = associatedInstallProduct(cs);
            installProdAP.Product__c = !String.isBlank(cs.SVMXC__Product__c) ? cs.SVMXC__Product__c : null;
            insertAssociatedProd.add(installProdAP);
        }
        // if product is populated and Subscription , Install Product not populated
        if(cs.SVMXC__Product__c != null && cs.Subscription__c == null && String.isBlank(cs.SVMXC__Component__c)) {
            Associated_Product__c productAP = associatedProd(cs);
            insertAssociatedProd.add(productAP);
        }
        // if Subscription is populated and product , Install Product not populated
        if(cs.SVMXC__Product__c == null && cs.Subscription__c != null && String.isBlank(cs.SVMXC__Component__c)) {
            Associated_Product__c subscriptionAP = associatedSubscription(cs , true);
            insertAssociatedProd.add(subscriptionAP);
        }
        return insertAssociatedProd;
    }
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - create Associated_Product__c instance with install product lookup
    **/
    private static Associated_Product__c associatedInstallProduct(Case cs) {
        Associated_Product__c installProdAP = new Associated_Product__c();
        installProdAP.Case__c = cs.Id;
        installProdAP.Installed_Product__c  = cs.SVMXC__Component__c;
        installProdAP.Is_Primary__c = true;
        installProdAP.Work_Order__c = caseIdWorkOrderMap.containsKey(cs.Id) ? caseIdWorkOrderMap.get(cs.Id).Id : cs.Work_Order__c != null ? cs.Work_Order__c : null;
        return installProdAP;
    }
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - create Associated_Product__c instance with product lookup
    **/
    private static Associated_Product__c associatedProd(Case cs) {
        Associated_Product__c prodAP = new Associated_Product__c();
        prodAP.Case__c = cs.Id;
        prodAP.Product__c = cs.SVMXC__Product__c;
        prodAP.Is_Primary__c = true;
        prodAP.Work_Order__c = caseIdWorkOrderMap.containsKey(cs.Id) ? caseIdWorkOrderMap.get(cs.Id).Id : cs.Work_Order__c != null ? cs.Work_Order__c : null;
        return prodAP;
    }
    /**
    *  CMCM-263
    *  @author : Abhishek Yadav
    *  @description - create Associated_Product__c instance with Subscription__c lookup
    **/
    private static Associated_Product__c associatedSubscription(Case cs , Boolean isPrimary) {
        Associated_Product__c subscriptionAP = new Associated_Product__c();
        subscriptionAP.Case__c = cs.Id;
        subscriptionAP.Account__c = cs.AccountId;
        subscriptionAP.Subscription__c = cs.Subscription__c;
        subscriptionAP.Is_Primary__c = isPrimary;
        subscriptionAP.Work_Order__c = caseIdWorkOrderMap.containsKey(cs.Id) ? caseIdWorkOrderMap.get(cs.Id).Id : cs.Work_Order__c != null ? cs.Work_Order__c : null;
        return subscriptionAP;
    }
    /**
    *  CMCM-276
    *  @author : Abhishek Yadav
    *  @description - insert Associated Product on Work Order Creation
    **/
    public static void addAssociatedProductsOnWorkOrderCreation (List<sObject> workOrderList) {
        ilib_LogEvent.push(LOG_TITLE + '.addAssociatedProductsOnWorkOrderCreation');
        Savepoint sp = Database.setSavepoint();      
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>();
        createWorkRelatedMap(workOrderList);
        if(workOrderList != null && !workOrderList.isEmpty()){ //adding null checks CMCM-6733
            for(SVMXC__Service_Order__c workOrder : (List<SVMXC__Service_Order__c>) workOrderList) {
                // Case is Populated on Work Order and it contains Associated Product
                if (caseAssociatedMap.containsKey(workOrder.SVMXC__Case__c) && caseAssociatedMap.get(workOrder.SVMXC__Case__c) != null) {
                    List<Associated_Product__c> apCaseRelatedList = caseAssociatedMap.get(workOrder.SVMXC__Case__c);
                    for(Associated_Product__c ap : apCaseRelatedList) {
                        ap.Work_Order__c = workOrder.id;
                        insertAssociatedProd.add(ap);
                    }
                } else {
                    // handle multiple lookup on Work Order
                    List<Associated_Product__c> multipleAssProdList =  populateWOAssociatedProduct(workOrder);
                    if (!multipleAssProdList.isEmpty()) {
                        insertAssociatedProd.addAll(multipleAssProdList);
                    }
                    // if there is single loopkup on Install product , Subscription & Product
                    List<Associated_Product__c> singleAssProdList = singleWOAssociatedProduct(workOrder);
                    if (!singleAssProdList.isEmpty()) {
                        insertAssociatedProd.addAll(singleAssProdList);
                    }
                }
            }
        }
        
        ilib_LogEvent.message('workOrderRelatedcaseIds--' + workOrderRelatedcaseIds);
        ilib_LogEvent.message('workOrderIdCaseMap--' + workOrderIdCaseMap);
        ilib_LogEvent.message('workOrderRelatedSubscriptionsId--' + workOrderRelatedSubscriptionsId);
        ilib_LogEvent.message('workOrderList--' + workOrderList);
        ilib_LogEvent.message('caseAssociatedMap--' + caseAssociatedMap);
        ilib_LogEvent.message('insertAssociatedProd--' + insertAssociatedProd);
        if (insertAssociatedProd!=null && !insertAssociatedProd.isEmpty()) {
            try {
                upsert insertAssociatedProd;
            }catch(Exception e) {
            //catch the exception 
                ApexExceptions.emit('AssociatedProducts.addAssociatedProductsOnWorkOrderCreation', e);
                Database.rollback(sp);
                throw e;
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *  CMCM-276
    *  @author : Abhishek Yadav
    *  @description - create Work order Related Map data
    **/
    private static void createWorkRelatedMap(List<sObject> workOrderList) {
        if(workOrderList != null && !workOrderList.isEmpty()){ //adding null checks CMCM-6733
            for(SVMXC__Service_Order__c serviceOrder : (List<SVMXC__Service_Order__c>) workOrderList) {
                if (serviceOrder.SVMXC__Case__c != null) {
                    workOrderRelatedcaseIds.add(serviceOrder.SVMXC__Case__c);
                }
                workOrderIdCaseMap.put(serviceOrder.Id , serviceOrder);
                if (serviceOrder.Subscription__c != null) {
                    workOrderRelatedSubscriptionsId.add(serviceOrder.Subscription__c);
                }
            }
        }
        
        if(workOrderRelatedSubscriptionsId != null && !workOrderRelatedSubscriptionsId.isEmpty()) {
            serviceContractProductMap = getSubscriptionMap(workOrderRelatedSubscriptionsId);
        }
        if(workOrderRelatedcaseIds != null && !workOrderRelatedcaseIds.isEmpty()) {
            // Added query on selector class
            //CMCM - 6733 Added an empty check with a feature flag check for existingAP
            if(existingAP == null || existingAP.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
                existingAP = new AssociatedProductSelector().selectAPwithCase(workOrderRelatedcaseIds);
            }
        }
        if(UpdateAPwithIPProductSub_CaseHelper.apBIList != null) {
            existingAP.addAll(UpdateAPwithIPProductSub_CaseHelper.apBIList);
        }
        if(existingAP != null && !existingAP.isEmpty()) {
            for(Associated_Product__c ap : existingAP) {
                if(UpdateAPwithIPProductSub_CaseHelper.apBICaseIds != null && UpdateAPwithIPProductSub_CaseHelper.apBICaseIds.contains(ap.Case__c) && ap.Id != null) {
                    ap.Is_Primary__c = false;
                }
                if(!caseAssociatedMap.containskey(ap.Case__c))
                    caseAssociatedMap.put(ap.Case__c, new List<Associated_Product__c>());
                caseAssociatedMap.get(ap.Case__c).add(ap);
            }
        }
    }
	/**
    *  CMCM-276
    *  @author : Abhishek Yadav
    *  @description - helper method of addAssociatedProductsOnworkOrderrdOrderCreation
    **/
    private static List<Associated_Product__c> populateWOAssociatedProduct(SVMXC__Service_Order__c workOrder) {
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>(); 
        // if product and  Subscription are populated and Subscription's product same as product
        if(workOrder.SVMXC__Product__c != null && workOrder.Subscription__c != null && serviceContractProductMap.get(workOrder.Subscription__c) != null && workOrder.SVMXC__Product__c == serviceContractProductMap.get(workOrder.Subscription__c) && String.isBlank(workOrder.SVMXC__Component__c)) {
            Associated_Product__c prodsubAP = associatedWOSubscription(workOrder , true);
            insertAssociatedProd.add(prodsubAP);
        }
        // if Install product and  Subscription are populated
        if(!String.isBlank(workOrder.SVMXC__Component__c) && !String.isBlank(workOrder.Subscription__c)) {
            Associated_Product__c installAP = associatedWOInstallProduct(workOrder);
            insertAssociatedProd.add(installAP);
            Associated_Product__c subAP = associatedWOSubscription(workOrder , false);
            insertAssociatedProd.add(subAP);
        }
        // if product and  Subscription are populated and Subscription's product not same as product
        if(workOrder.SVMXC__Product__c != null && workOrder.Subscription__c != null && String.isBlank(workOrder.SVMXC__Component__c)  && (serviceContractProductMap.get(workOrder.Subscription__c) == null || workOrder.SVMXC__Product__c != serviceContractProductMap.get(workOrder.Subscription__c))) {
            Associated_Product__c prodAP = associatedWOProd(workOrder);
            insertAssociatedProd.add(prodAP);
            Associated_Product__c subscriptionAP = associatedWOSubscription(workOrder , false);
            insertAssociatedProd.add(subscriptionAP);
        }
        return insertAssociatedProd;
    }
    /**
    *  CMCM-276
    *  @author : Abhishek Yadav
    *  @description - helper method of addAssociatedProductsOnworkOrderrdOrderCreation
    **/
    private static List<Associated_Product__c> singleWOAssociatedProduct(SVMXC__Service_Order__c workOrder) {
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>();
        // if Install product is populated and Subscription is not populated
        if(!String.isBlank(workOrder.SVMXC__Component__c) && String.isBlank(workOrder.Subscription__c)) {
            Associated_Product__c installProdAP = associatedWOInstallProduct(workOrder);
            insertAssociatedProd.add(installProdAP);
        }
        // if product is populated and Subscription , Install Product not populated
        if(workOrder.SVMXC__Product__c != null && workOrder.Subscription__c == null && String.isBlank(workOrder.SVMXC__Component__c)) {
            Associated_Product__c productAP = associatedWOProd(workOrder);
            insertAssociatedProd.add(productAP);
        }
        // if Subscription is populated and product , Install Product not populated
        if(workOrder.SVMXC__Product__c == null && workOrder.Subscription__c != null && String.isBlank(workOrder.SVMXC__Component__c)) {
            Associated_Product__c subscriptionAP = associatedWOSubscription(workOrder , true);
            insertAssociatedProd.add(subscriptionAP);
        }
        return insertAssociatedProd;
    }
    /**
    *  CMCM-276
    *  @author : Abhishek Yadav
    *  @description - create Associated_Product__c instance with install product lookup
    **/
    private static Associated_Product__c associatedWOInstallProduct(SVMXC__Service_Order__c workOrder) {
        Associated_Product__c installProdAP = new Associated_Product__c();
            installProdAP.Work_Order__c = workOrder.Id;
            installProdAP.Installed_Product__c  = workOrder.SVMXC__Component__c;
            installProdAP.Is_Primary__c = true;
            installProdAP.Case__c = workOrderIdCaseMap.containsKey(workOrder.Id) ? workOrderIdCaseMap.get(workOrder.Id).SVMXC__Case__c : null;
        return installProdAP;
    }
    /**
    *  CMCM-276
    *  @author : Abhishek Yadav
    *  @description - create Associated_Product__c instance with product lookup
    **/
    private static Associated_Product__c associatedWOProd(SVMXC__Service_Order__c workOrder) {
        Associated_Product__c prodAP = new Associated_Product__c();
            prodAP.Work_Order__c = workOrder.Id;
            prodAP.Product__c = workOrder.SVMXC__Product__c;
            prodAP.Is_Primary__c = true;
            prodAP.Case__c = workOrderIdCaseMap.containsKey(workOrder.Id) ? workOrderIdCaseMap.get(workOrder.Id).SVMXC__Case__c : null;
        return prodAP;
    }
    /**
    *  CMCM-276
    *  @author : Abhishek Yadav
    *  @description - create Associated_Product__c instance with Subscription__c lookup
    **/
    private static Associated_Product__c associatedWOSubscription(SVMXC__Service_Order__c workOrder , Boolean isPrimary) {
        Associated_Product__c subscriptionAP = new Associated_Product__c();
            subscriptionAP.Work_Order__c = workOrder.Id;
            subscriptionAP.Account__c = workOrder.SVMXC__Company__c ;
            subscriptionAP.Subscription__c = workOrder.Subscription__c;
            subscriptionAP.Is_Primary__c = isPrimary;
            subscriptionAP.Case__c = workOrderIdCaseMap.containsKey(workOrder.Id) ? workOrderIdCaseMap.get(workOrder.Id).SVMXC__Case__c : null;
        return subscriptionAP; 
    }
    
     /*
     * @author:         Dhairya Shah - CMCM-3591
     * @description:    Method to update the case and Work order based on updated primary Associated product
     * @param:          String, List<Associated_Product__c>,  Map<id, Associated_Product__c>, String
     */
    public static void updatePrimaryAPonCaseWO(List<Associated_Product__c> listUpdatedAp, Map<id, Associated_Product__c> oldMap){
        List<String> closeVar = closeVarStr.split(',');
        List<Case> listToUpdateCase = new List<Case>();
        List<SVMXC__Service_Order__c> listToUpdateWO = new List<SVMXC__Service_Order__c>();
        //AFTER UPDATE STARTS
        if(listUpdatedAp!=null && !listUpdatedAp.isEmpty()){
            //cmcm-6411 - START
            Set<Id> apIds = new Set<Id>();
            for(Associated_Product__c objassociatedProd : listUpdatedAp){
                apIds.add(objassociatedProd.Id);
            }
            //CMCM - 6733 Added an empty check with a feature flag check for installProductAPs
            if(installProductAPs == null || installProductAPs.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
                installProductAPs = new AssociatedProductSelector().selectAPwithIP(apIds);
            }
            //cmcm-6411 - START
            if (installProductAPs != null && !installProductAPs.isEmpty()) {
                for(Associated_Product__c installAP : installProductAPs) {
                    apProductLotMap.put(installAP.Id , installAP.Installed_Product__r.SVMXC__Serial_Lot_Number__c);
                }
            }
            //cmcm-6411 - END
            mapToUpdateCase = new Map<Id, Case> (updateCaseForAP(listUpdatedAp,closeVar,oldMap));
            mapToUpdateWO =  new Map<Id, SVMXC__Service_Order__c> (updateWOForAP(listUpdatedAp,closeVar,oldMap));
        }
    }

    /*
     * @author:         Dhairya Shah - CMCM-3591
     * @description:    DML for Case and WO
     * @param:          List Case, List WO
     */
    public static void caseWoDML(Map<Id, Case> mapToUpdateCase, Map<Id, SVMXC__Service_Order__c> mapToUpdateWO){
        if(mapToUpdateCase!=null && !mapToUpdateCase.isEmpty() ){
            try{
                if(UpdateAPwithIPProductSub_CaseHelper.apBIList.isEmpty()) {
                    cases.skipCaseTrigger = true;
                    cases.isPrimaryAPUpdate = true;
                    UPDATE mapToUpdateCase.values();
                }
            }
            catch(DMLException e){
                throw new AuraHandledException(e.getMessage());
            }
        }

        if(mapToUpdateWO!=null && !mapToUpdateWO.isEmpty() && !skipWOUpdateOnAPUpdate){
            try{
                WorkOrders.skipWOTrigger = true;
                WorkOrders.isPrimaryAPUpdate = true;
                UPDATE mapToUpdateWO.values();
            }
            catch(DMLException e){
                System.debug('EX'+e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        }
    }

    /*
     * @author:         Dhairya Shah - CMCM-5796
     * @description:    Method to update the case based on primary Associated product
     * @param:          List Associated_Product__c, List string, List String, Map<id, Associated_Product__c> 
     */
    public static List<Case> updateCaseForAP(List<Associated_Product__c> listAP,List<String> closeVar,Map<id, Associated_Product__c> oldMap){
        List<Case> listToUpdateCase = new List<Case>();
        Map<Id,List<Case>> mapListToUpdateCase = new Map<Id,List<Case>>();
        if(listAP!=null && !listAP.isEmpty()){
            for(Associated_Product__c objAP : listAP){
                if(objAP.Is_Primary__c == true && !closeVar.contains(objAP.Order_Status__c) && !closeVar.contains(objAP.Work_Order__r.Case_Status__c)){
                    if(mapListToUpdateCase.containsKey(objAP.Case__c)){
                        mapListToUpdateCase.put(objAP.Case__c,getUpdatedCaseBasedOnCond(objAP,false,true));
                    }else{
                        mapListToUpdateCase.put(objAP.Case__c,getUpdatedCaseBasedOnCond(objAP,false,true));
                    }
                } else if(oldMap!=null && objAP.Case__c!=null && !closeVar.contains(objAP.Order_Status__c) && !closeVar.contains(objAP.Work_Order__r.Case_Status__c) && !mapListToUpdateCase.containsKey(objAP.Case__c) && objAP.Is_Primary__c!=oldMap.get(objAP.Id).Is_Primary__c){
                    mapListToUpdateCase.put(objAP.Case__c,getUpdatedCaseBasedOnCond(objAP,false,false));
                }
            }
        }
        if(mapListToUpdateCase!=null && !mapListToUpdateCase.isEmpty()){
            for(Id key: mapListToUpdateCase.keySet()){
                listToUpdateCase.addAll(mapListToUpdateCase.get(key));
            }
        }
        return listToUpdateCase;
    }

    
    /*
     * @author:         Dhairya Shah - CMCM-5796
     * @description:    Method to update Work order based primary Associated product
     * @param:          List Associated_Product__c, string, List String, Map<id, Associated_Product__c>
     */
    public static List<SVMXC__Service_Order__c> updateWOForAP(List<Associated_Product__c> listAP,List<String> closeVar,Map<id, Associated_Product__c> oldMap){
        Map<Id,List<SVMXC__Service_Order__c>> mapListToUpdateWO = new Map<Id,List<SVMXC__Service_Order__c>>();
        List<SVMXC__Service_Order__c> listToUpdateWO = new List<SVMXC__Service_Order__c>();
        if(listAP!=null && !listAP.isEmpty()){
            for(Associated_Product__c objAP : listAP){
                if(objAP.Is_Primary__c ==true && !closeVar.contains(objAP.Order_Status__c) && !closeVar.contains(objAP.Work_Order__r.Case_Status__c)){
                    if(mapListToUpdateWO.containsKey(objAP.Work_Order__c)){
                        mapListToUpdateWO.remove(objAP.Work_Order__c);
                        mapListToUpdateWO.put(objAP.Work_Order__c,getUpdatedWOBasedOnCond(objAP,false,true));
                    }else{
                        mapListToUpdateWO.put(objAP.Work_Order__c,getUpdatedWOBasedOnCond(objAP,false,true));
                    }
                }else if(oldMap!=null && !closeVar.contains(objAP.Order_Status__c) && !closeVar.contains(objAP.Work_Order__r.Case_Status__c) && !mapListToUpdateWO.containsKey(objAP.Work_Order__c) && objAP.Is_Primary__c!=oldMap.get(objAP.Id).Is_Primary__c){
                    mapListToUpdateWO.put(objAP.Work_Order__c,getUpdatedWOBasedOnCond(objAP,false,false));
                }
            }
        }
        if(mapListToUpdateWO!=null && !mapListToUpdateWO.IsEmpty()){
            for(Id key: mapListToUpdateWO.keySet()){
                listToUpdateWO.addAll(mapListToUpdateWO.get(key));
            }
        }
        return listToUpdateWO;
    }
    /*
     * @author:         Dhairya Shah - CMCM-5796
     * @description:    Method to update the case and Work order based on deleted primary Associated product
     * @param:          List<Associated_Product__c>
     */
    @AuraEnabled
    public static void dissaccociatePrimaryAPonCaseWO(List<Associated_Product__c> listDeletedAP){
        List<String> closeVar = closeVarStr.split(',');
        Savepoint sp = Database.setSavepoint();
        List<Case> listToUpdateCase = new List<Case>();
        List<SVMXC__Service_Order__c> listToUpdateWO = new List<SVMXC__Service_Order__c>();
        try{
            if(listDeletedAP!=null && !listDeletedAP.isEmpty()){
                for(Associated_Product__c asp : listDeletedAP){
                    if(asp.Is_Primary__c==true){
                        if((asp.case__c != null && !closeVar.contains(asp.Case_Status__c))){
                            listToUpdateCase = getUpdatedCaseBasedOnCond(asp,true,true);
                        }
                        if((asp.Work_Order__c !=null && !closeVar.contains(asp.Order_Status__c))){
                            listToUpdateWO = getUpdatedWOBasedOnCond(asp,true,true);
                        }
                    }
                }
            }
            caseWoDML(new Map<Id, Case> (listToUpdateCase), new Map <Id, SVMXC__Service_Order__c> (listToUpdateWO));
        }
        catch(Exception e){
            Database.rollback(sp);
            Database.releaseSavepoint(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
     /*
     * @author:         Dhairya Shah 
     * @description:    This method is called from AssociatedProduct.updatePrimaryAPonCaseWO for updating case records
     * @param:          Associated_Product__c, boolean, boolean
     */
    private static List<Case> getUpdatedCaseBasedOnCond(Associated_Product__c objAP,boolean isDeleted, boolean isPrimary){
        List<Case> listCase = new List<Case>();
        List<String> closeVar = closeVarStr.split(',');
        if((objAP.Case__c!=null && !closeVar.contains(objAP.Case_Status__c) ) && ((isDeleted ==true && isPrimary ==true) || isPrimary==false)){ 
            Case objCase = new Case(id=objAP.Case__c);
            objCase.SVMXC__Component__c = null;
            objCase.SVMXC__Product__c = null;
            objCase.Product_Serial_Number__c = '';
            objCase.Product_Lot_Number__c = '';
            objCase.Subscription__c =null;
            objCase.Expired_Reagent__c = false;
            objCase.Software_Version__c = '';
            // Added for INC0558856 fix
            objCase.SVMXC__Site__c = null;
            listCase.add(objCase);
        }
        else if(objAP.Case__c!=null && !closeVar.contains(objAP.Case_Status__c) && isDeleted == false && isPrimary == true){
            Case objCase = new Case(id=objAP.Case__c);
            objCase.SVMXC__Component__c = objAP.Installed_Product__c;
            objCase.SVMXC__Product__c = objAP.Product__c;
            objCase.Subscription__c =objAP.Subscription__c;
            //CMCM-6411 - START
            if(!string.isBlank(objAP.Product_Serial_Number__c)) {
                objCase.Product_Serial_Number__c = objAP.Product_Serial_Number__c; //CMCM-5334
            } else {
                objCase.Product_Serial_Number__c = apProductLotMap.get(objAP.Id);
            } 
            //CMCM-6411 - END            
            objCase.Product_Lot_Number__c = objAP.Product_Lot_Number__c;
            objCase.Expired_Reagent__c = objAP.Is_Expired__c;
            objCase.Software_Version__c = objAP.Software_Version__c;
            // Added for INC0558856 fix
            objCase.SVMXC__Site__c = objAP.Location__c;
            listCase.add(objCase);
        }
        return listCase;
    }

    /*
     * @author:         Dhairya Shah 
     * @description:    This method is called from AssociatedProduct.updatePrimaryAPonCaseWO for updating WO records
     * @param:          Associated_Product__c, boolean, boolean
     */
    private static List<SVMXC__Service_Order__c>  getUpdatedWOBasedOnCond(Associated_Product__c objAP,boolean isDeleted, boolean isPrimary){
        List<SVMXC__Service_Order__c> listWO = new List<SVMXC__Service_Order__c>();
        List<String> closeVar = closeVarStr.split(',');
        if((objAP.Work_Order__c!=null && !closeVar.contains(objAP.Order_Status__c)) && ((isDeleted ==true && isPrimary ==true) || isPrimary==false)){ 
            SVMXC__Service_Order__c objSO = new SVMXC__Service_Order__c(id=objAP.Work_Order__c);
            objSO.SVMXC__Component__c = null;
            objSO.SVMXC__Product__c = null;
            objSO.Subscription__c =null;
            objSO.Product_Serial_Number__c = null;
            objSO.Product_Lot_Number__c = null;
            // Added for INC0558856 fix
            objSO.SVMXC__Site__c = null;
            listWO.add(objSO);
        }
        else if(objAP.Work_Order__c!=null && !closeVar.contains(objAP.Order_Status__c) && isDeleted == false && isPrimary == true){
            SVMXC__Service_Order__c objSO = new SVMXC__Service_Order__c(id=objAP.Work_Order__c);
            objSO.SVMXC__Component__c = objAP.Installed_Product__c;
            objSO.SVMXC__Product__c = objAP.Product__c;
            objSO.Subscription__c =objAP.Subscription__c;
            //CMCM-6411 - START
            if(!string.isBlank(objAP.Product_Serial_Number__c)) {
                objSO.Product_Serial_Number__c = objAP.Product_Serial_Number__c; //CMCM-5334
            }  else {
                objSO.Product_Serial_Number__c = apProductLotMap.get(objAP.Id);    
            }
            //CMCM-6411 - END
            objSO.Product_Lot_Number__c = objAP.Product_Lot_Number__c;
            // Added for INC0558856 fix
            objSO.SVMXC__Site__c = objAP.Location__c;
            listWO.add(objSO);
        }
        return listWO;
    }

     /*
     * @author:         Dhairya Shah 
     * @description:    This method is called from AssociatedProduct.updatePrimaryAPonCaseWO 
     * @param:          AssociatedProductsWrapper wrapper
     */
    private static List<Id> wrapperList(AssociatedProductsWrapper wrapper){
        List<Id> recIds = new List<Id>();
        if(wrapper.fields!=null){
            for(AssociatedProductsWrapper.cls_fields cls : wrapper.fields){
                recIds.add(cls.id);
            }
        }else{
            recIds.add(wrapper.id);
        }
        return recIds;
    }

    /*
     * @author:         Dhairya Shah 
     * @description:    This method is called from AssociatedProduct.updatePrimaryAPonCaseWO 
     * @param:          AssociatedProductsWrapper wrapper, string
     */
    private static List<Associated_Product__c> wrapperAssProdList(AssociatedProductsWrapper wrapper,String aspdTrue){
        List<Associated_Product__c> records = new List<Associated_Product__c>();
        if(wrapper.fields!=null){
            for(AssociatedProductsWrapper.cls_fields cls : wrapper.fields){
                Associated_Product__c asp = new Associated_Product__c();
                asp.Id = cls.id;
                if(cls.isPrimary!=null){
                    asp.Is_Primary__c= cls.isPrimary;
                }
                else if(aspdTrue.contains(ISPRIMARY)){
                    asp.Is_Primary__c= false;
                }
                if(cls.expiredDate!=null){
                    asp.Expired_Date__c = Date.ValueOf(cls.expiredDate);
                }
                if(cls.serialNumber!=null){
                    asp.Product_Serial_Number__c = cls.serialNumber;
                }
                if(cls.lotNumber!=null){
                    asp.Product_Lot_Number__c = cls.lotNumber;
                }
                if(cls.isExpired!=null){
                    asp.Is_Expired__c = cls.isExpired;
                }
                if(cls.version!=null){
                    asp.Software_Version__c = cls.version;
                }
                records.add(asp);
            }
        } else {
            Associated_Product__c asp = new Associated_Product__c();
            asp.Id = wrapper.id;
            if(wrapper.isPrimary!=null){
                asp.Is_Primary__c= wrapper.isPrimary;
            }
            else if(aspdTrue.contains(ISPRIMARY)){
                asp.Is_Primary__c= false;
            }
            if(wrapper.expiredDate!=null){
                asp.Expired_Date__c = Date.ValueOf(wrapper.expiredDate);
            }
            if(wrapper.serialNumber!=null){
                asp.Product_Serial_Number__c = wrapper.serialNumber;
            }
            if(wrapper.lotNumber!=null){
                asp.Product_Lot_Number__c = wrapper.lotNumber;
            }
            if(wrapper.isExpired!=null){
                asp.Is_Expired__c = wrapper.isExpired;
            }
            if(wrapper.version!=null){
                asp.Software_Version__c = wrapper.version;
            }
            records.add(asp);
        }
        return records;
    }
    
    /**
    *  CMCM-269
    *  @author : Abhishek Yadav
    *  @description - 
    **/
    private static Boolean checkConsumableWarranty (Associated_Product__c associatedProduct) {
        return associatedProduct.Material_Class__c == 'Consumables' && associatedProduct.Product_Lot_Number__c != null && associatedProduct.Expired_Date__c != null && associatedProduct.Is_Expired__c == false;
    }
    /**
    *  CMCM-269
    *  @author : Abhishek Yadav
    *  @description - 
    **/
    private static Boolean checkConsumableWarranty (Associated_Product__c associatedProduct , Map<Id, Associated_Product__c> mapOldapRecs) {
        Associated_Product__c oldAp = mapOldapRecs.get(associatedProduct.Id);
        return oldAp.Material_Class__c != associatedProduct.Material_Class__c || oldAp.Product_Lot_Number__c != associatedProduct.Product_Lot_Number__c || oldAp.Expired_Date__c != associatedProduct.Expired_Date__c || oldAp.Is_Expired__c != associatedProduct.Is_Expired__c;
    }
    /**
    *  CMCM-7787
    *  @author : Dhairya Shah
    *  @description -     //synchoronousMethodCallsAfterInsert
    **/
    public static void synchoronousMethodCallsAfterInsert (List<Sobject> records) {
        ilib_Queueablethread  queueableThread = new ilib_Queueablethread('AssociatedProductsAfterInsert');
        Set<Id> associatedProductIds = new Set<Id>();
        Set<Id> entitlementAssociatedProductIds = new Set<Id>();
        associatedProductIds = getAssociatedProductIds(records);  
        entitlementAssociatedProductIds = getEntitlementAssociatedProductIds(records);
        //InsertEntitlementAndcheckContractCoverage  
        if(associatedProductIds != null && !associatedProductIds.isEmpty()) {
            syncMethod(INSERT_ENTITLEMENT_CHECK_CONTRACTCOVERAGE, associatedProductIds , null , null , null , null);
        }
        if(entitlementAssociatedProductIds != null && !entitlementAssociatedProductIds.isEmpty()) {
            syncMethod(INSERT_APPLIED_CONTRACT_ENTITLEMENT, entitlementAssociatedProductIds , null , null , null , null);
        } 
        if(!queueableThread.lstQueueableJobs.isEmpty()) {
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        } 
    }

    /**
    *  CMCM-7787
    *  @author : Dhairya Shah
    *  @description - syncMethod
    **/
    public static void syncMethod (String strMethodtoExecute , Set<Id> setAssociatedProductIds , Set<Id> setCaseIds , Set<Id> setWorkOrderIds , Set<Id> setInstallProductIds , Set<Id> setSubscriotionIds) {
        String strMethodtoExecute1 = strMethodtoExecute;
        Set<Id> setAssociatedProductIds1 = setAssociatedProductIds;
        Set<Id> setCaseIds1 = setCaseIds;
        Set<Id> setWorkOrderIds1 = setWorkOrderIds;
        Set<Id> setInstallProductIds1 = setInstallProductIds;
        Set<Id> setSubscriotionIds1 = setSubscriotionIds;
        try {
            insertConsumableWarrantyContract(strMethodtoExecute1, setAssociatedProductIds1);
            updateConsumableWarrantyContract(strMethodtoExecute1, setCaseIds1, setWorkOrderIds1);

            insertAppliedContractEntitlement(strMethodtoExecute1, setAssociatedProductIds1);
            updateAppliedContractEntitlement(strMethodtoExecute1, setAssociatedProductIds1);

        } catch(Exception e) {
            ApexExceptions.emit('AssociatedProduct', e, ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        } 
    }

     /**
    *  CMCM-7787
    *  @author : Dhairya Shah
    *  @description -     //insertConsumableWarrantyContract
    **/
    public static void insertConsumableWarrantyContract(String strMethodtoExecute1, Set<Id> setAssociatedProductIds1) {
        if(strMethodtoExecute1 == 'insertConsumableWarrantyContract' && !setAssociatedProductIds1.IsEmpty()) {
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertConsumableWarrantyContract(setAssociatedProductIds1);
        }
    }

    /**
    *  CMCM-7787
    *  @author : Dhairya Shah
    *  @description -     //updateConsumableWarrantyContract
    **/
    public static void updateConsumableWarrantyContract(String strMethodtoExecute1, Set<Id> setCaseIds1, Set<Id> setWorkOrderIds1) {
        if(strMethodtoExecute1 == 'updateConsumableWarrantyContract' && (!setCaseIds1.IsEmpty() || !setWorkOrderIds1.isEmpty())) {
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().updateConsumableWarrantyContract(setCaseIds1 , setWorkOrderIds1);
        }
    }

    /**
    *  CMCM-7787
    *  @author : Dhairya Shah
    *  @description -     //insertAppliedContractEntitlement
    **/
    public static void insertAppliedContractEntitlement(String strMethodtoExecute1, Set<Id> setAssociatedProductIds1) {
        if(strMethodtoExecute1 == 'insertAppliedContractEntitlement' && !setAssociatedProductIds1.IsEmpty()) {
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertAppliedContractEntitlement(setAssociatedProductIds1);
        }
    }

    /**
    *  CMCM-7787
    *  @author : Dhairya Shah
    *  @description -     //updateAppliedContractEntitlement
    **/
    public static void updateAppliedContractEntitlement(String strMethodtoExecute1, Set<Id> setAssociatedProductIds1) {
        if(strMethodtoExecute1 == 'updateAppliedContractEntitlement' && !setAssociatedProductIds1.IsEmpty()) {
            new ServiceUtilityCollection.ServiceSystemUtilityCollection().updateAppliedContractEntitlement(setAssociatedProductIds1);
        }
    }
    
    /**
    *  CMCM-269
    *  @author : Abhishek Yadav
    *  @description - 
    **/
    public static void synchoronousMethodCallsAfterupdate(List<Sobject> records, Map<Id, Associated_Product__c> mapOldapRecs) {
        Set<Id> caseIds = new Set<Id>();
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> entitlementAssociatedProductIds = new Set<Id>();
        if(records != null && !records.isEmpty() && mapOldapRecs != null && !mapOldapRecs.isEmpty()){ //adding null checks for CMCM-6733
            for (Associated_Product__c associatedProduct : (List<Associated_Product__c>)records) {
                if (associatedProduct.Case__c != null) {
                    if (checkConsumableWarranty(associatedProduct , mapOldapRecs)) {
                        caseIds.add(associatedProduct.Case__c);
                    }
                }
                if (associatedProduct.Work_Order__c != null) {
                    if (checkConsumableWarranty(associatedProduct , mapOldapRecs)) {
                        workOrderIds.add(associatedProduct.Work_Order__c);
                    }
                }
                if((associatedProduct.Case__c != null || associatedProduct.Work_Order__c != null) && checkEntitlement(associatedProduct , mapOldapRecs)) {
                    entitlementAssociatedProductIds.add(associatedProduct.Id);
                }
            }
        }
        synchoronousMethodCallsAfterupdateUtil(caseIds , workOrderIds , entitlementAssociatedProductIds);
    }

    /**
    *  CMCM-7787
    *  @author : Dhairya Shah
    *  @description -     //synchoronousMethodCallsAfterupdateUtil
    **/
    public static void synchoronousMethodCallsAfterupdateUtil(Set<Id> caseIds , Set<Id> workOrderIds , Set<Id> entitlementAssociatedProductIds) {
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('AssociatedProductAfterUpdate');
        if((caseIds != null || workOrderIds != null)  && (!caseIds.isEmpty() || !workOrderIds.isEmpty())) {
            syncMethod(INSERT_UPDATE_ENTITLEMENT_CHECK_CONTRACTCOVERAGE, null , caseIds , workOrderIds , null , null);
        } 
        if(entitlementAssociatedProductIds != null && !entitlementAssociatedProductIds.isEmpty()) {
            syncMethod(UPDATE_APPLIED_CONTRACT_ENTITLEMENT, entitlementAssociatedProductIds, null, null , null , null);
        } 
        if(!queueableThread.lstQueueableJobs.isEmpty()) {
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        } 
    }

    /**
    *  CMCM-269
    *  @author : Abhishek Yadav
    *  @description - 
    **/
    public static void asynchoronousMethodCallsAfterdelete(List<Sobject> records) {
        Set<Id> caseIds = new Set<Id>();
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> associatedProductIds = new Set<Id>();
        if(records != null && !records.isEmpty()){
            for (Associated_Product__c associatedProduct : (List<Associated_Product__c>)records) {
                associatedProductIds.add(associatedProduct.Id);
                if (associatedProduct.Case__c != null) {
                    caseIds.add(associatedProduct.Case__c);
                }
                if (associatedProduct.Work_Order__c != null) {
                    workOrderIds.add(associatedProduct.Work_Order__c);
                }
            }
        }
        asynchoronousMethodCallsAfterdeleteQueueCall(associatedProductIds , caseIds , workOrderIds);
    }
    /**
    *  CMCM-273
    *  @author : Abhishek Yadav
    *  @description - queueable call
    **/
    public static void asynchoronousMethodCallsAfterdeleteQueueCall(Set<Id> associatedProductIds , Set<Id> caseIds , Set<Id> workOrderIds) {
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('AssociatedProductAfterDelete');

        //InsertEntitlementAndcheckContractCoverage  
        if((caseIds != null || workOrderIds != null)  && (!caseIds.isEmpty() || !workOrderIds.isEmpty())) {
            queueableThread.logandQueue(new APQueueable(DELETE_ENTITLEMENT_CHECK_CONTRACTCOVERAGE, associatedProductIds , caseIds , workOrderIds , null),STRING_AP_QUEUEABLE,DELETE_ENTITLEMENT_CHECK_CONTRACTCOVERAGE);
        }
        if(associatedProductIds != null && !associatedProductIds.isEmpty() && appliedContractIds != null && !appliedContractIds.isEmpty()) {
            queueableThread.logandQueue(new APQueueable(DELETE_APPLIED_CONTRACT_ENTITLEMENT, null, null, null , appliedContractIds),STRING_AP_QUEUEABLE,DELETE_APPLIED_CONTRACT_ENTITLEMENT); 
        } 
        if(!queueableThread.lstQueueableJobs.isEmpty()) {
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        } 
    }
    private static Set<Id> getAssociatedProductIds(List<Sobject> records) {
        Set<Id> associatedProductIds = new Set<Id>();
        if(records != null && !records.isEmpty()){ //adding null checks for CMCM-6733
            for (Associated_Product__c associatedProduct : (List<Associated_Product__c>)records) {
                if (associatedProduct.Case__c != null) {
                    if (checkConsumableWarranty(associatedProduct)) {
                        associatedProductIds.add(associatedProduct.id);
                    }
                }
                if (associatedProduct.Work_Order__c != null) {
                    if (checkConsumableWarranty(associatedProduct)) {
                        associatedProductIds.add(associatedProduct.Id);
                    }
                }
            }
        }
        return associatedProductIds;
    }

    /*
     * @author:         Dhairya Shah - CMCM-5753
     * @description:    Method to using On CRUD Check error message
     * @param:          List Associated_Product__c
     */
    public static void preventCRUDonAP(List<Associated_Product__c> aspList){
        List<String> closeVar = closeVarStr.split(',');
        if(aspList!=null && !aspList.isEmpty()){ //adding null checks for CMCM-6733
            for(Associated_Product__c asp : aspList){
                if(asp.Case__c !=null && closeVar.contains(asp.Case_Status__c)){
                    asp.addError(System.Label.ErrorMessagePreventCRUDonAP);
                }else if(asp.Work_Order__c !=null && closeVar.contains(asp.Order_Status__c)){
                    asp.addError(System.Label.ErrorMessagePreventCRUDonAP);
                }
            }
        }
    }
    /*
     * @author:         Abhishek Yadav - CMCM-273
     * @description:    check for Entitlement
     * @param:          List sObject
     */
    private static Boolean checkEntitlement(Associated_Product__c associatedProduct) {
        return associatedProduct.Installed_Product__c != null || associatedProduct.Subscription__c != null;
    }
    /*
     * @author:         Abhishek Yadav - CMCM-273
     * @description:    check for Entitlement
     * @param:          List sObject
     */
    private static Boolean checkEntitlement(Associated_Product__c associatedProduct , Map<Id, Associated_Product__c> mapOldapRecs) {
        Associated_Product__c oldAp = mapOldapRecs.get(associatedProduct.Id);
        return oldAp.Case__c != associatedProduct.Case__c || oldAp.Work_Order__c != associatedProduct.Work_Order__c || oldAp.Installed_Product__c != associatedProduct.Installed_Product__c || oldAp.Subscription__c != associatedProduct.Subscription__c;
    }
    /*
     * @author:         Abhishek Yadav - CMCM-273
     * @description:    check for Entitlement 
     * @param:          List sObject
     */
    private static Set<Id> getEntitlementAssociatedProductIds(List<Sobject> records) {
        Set<Id> associatedProductIds = new Set<Id>();
        if(records != null && !records.isEmpty()){ //adding null checks for CMCM-6733
            for (Associated_Product__c associatedProduct : (List<Associated_Product__c>)records) {
                if (associatedProduct.Case__c != null && checkEntitlement(associatedProduct)) {
                    associatedProductIds.add(associatedProduct.id);
                }
                if (associatedProduct.Work_Order__c != null && checkEntitlement(associatedProduct)) {
                    associatedProductIds.add(associatedProduct.Id);
                }
            }
        }
        return associatedProductIds;
    }
    /**
    *  @author Siddartha Reddy Kalam
    *  @description - CMCM-5782: To get AP record based on provided WO Id's.
    *  @parameters : setWOIds : Set<Id> - Set of WO record Ids
    *  @return : List of Associated Products Records
    **/
    public static List<Associated_Product__c> linkAPsfromWO(Set<Id> workOrderIds){
        //CMCM - 6733 Added an empty check with a feature flag check for listAssociatedProducts
        if(listAssociatedProducts == null || listAssociatedProducts.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
            listAssociatedProducts = new AssociatedProductSelector().selectAPwithWorkOrder(workOrderIds);
        }
        return listAssociatedProducts;
    }

    /**
    *  @author Siddartha Reddy Kalam
    *  @description - CMCM-5782: To get AP record based on provided Case Id's.
    *  @parameters : setCaseIds : Set<Id> - Set of Case Ids from WO
    *  @return : List of Associated Products Records
    **/
    public static List<Associated_Product__c> linkAPsfromCase(Set<Id> caseIds){
        //CMCM - 6733 Added an empty check with a feature flag check for listAssociatedProducts
        if(listAssociatedProducts == null || listAssociatedProducts.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
            listAssociatedProducts = new AssociatedProductSelector().selectAPwithCase(caseIds);
        }
        return listAssociatedProducts;
    }
    /**
    *  @author Abhishek Yadav
    *  @description - CMCM-295: To update Applied Contrcat record on WO.
    *  @parameters : list<Sobject> records: List of Applied Contract
    *  @return : List of Associated Products Records
    **/
    public static void populateAppliedContractonWOAfterInsert(List<Sobject> records) {
        ilib_LogEvent.push(LOG_TITLE + '.populateAppliedContractonWO');
        Map<Id,Id> apIdWOMap = new Map<Id,Id>();
        if(records != null && !records.isEmpty()){ //adding null checks for CMCM-6733
            for (Associated_Product__c associatedProduct : (List<Associated_Product__c>)records) {
                if (associatedProduct.Is_Primary__c && associatedProduct.Work_order__c != null) {
                    apIdWOMap.put(associatedProduct.Id , associatedProduct.Work_order__c);
                }
            }
        }
        populateAppliedContractonWOHelper(apIdWOMap);
        ilib_LogEvent.pop();
    }
    private static void populateAppliedContractonWOHelper(Map<Id,Id> apIdWOMap) {
        map<Id, List<Applied_Contract__c>> mapIdtoListAppliedContract = new map<Id, List<Applied_Contract__c>>();
        set<string> setItemNumbers = new set<string>();
        if (apIdWOMap != null && !apIdWOMap.isEmpty()) { //adding null checks for CMCM-6733
            //CMCM - 6733 Added an empty check with a feature flag check for appliedContract
            if(appliedContract == null || appliedContract.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
                appliedContract = new AppliedContractsSelector().selectActiveAppliedContractForWO(apIdWOMap.keySet());
            }
        }
        if (appliedContract != null && !appliedContract.isEmpty()) {
            for (Applied_Contract__c ac : appliedContract) {
                if(!mapIdtoListAppliedContract.containsKey(ac.Associated_Product__c)) {
                    mapIdtoListAppliedContract.put(ac.Associated_Product__c, new List<Applied_Contract__c>());
                }
                mapIdtoListAppliedContract.get(ac.Associated_Product__c).add(ac);
                if(ac.Service_Contract__r.SVMXC__Service_Plan__c != null && ac.Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c != null) {
                    setItemNumbers.add(string.valueOf(ac.Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c));
                } 
            }
            ilib_LogEvent.info('setItemNumbers : '+setItemNumbers);
        }
        updateCurrentActiveContractOnWO(setItemNumbers,apIdWOMap,mapIdtoListAppliedContract);
    }
    private static void updateCurrentActiveContractOnWO(set<string> setItemNumbers ,Map<Id,Id> apIdWOMap,Map<Id, List<Applied_Contract__c>> mapIdtoListAppliedContract)  {
        map<string, Integer> mapServiceLevelToRank = new map<string, Integer>();
        map<string, Integer> mapMaterialNumberToRank = new map<string, Integer>();
        //CMCM - 6733 created new public static variable 'prodList' & Added an empty check with a feature flag check for prodList
        if(prodList == null || prodList.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
            prodList = new ProductsSelector().selectProductsForMaterialNumber(setItemNumbers);
        }
        for(ServiceLevelRanking__mdt objServiceLevelRank : ServiceLevelRanking__mdt.getAll().values()) {
			mapServiceLevelToRank.put(objServiceLevelRank.MasterLabel, Integer.valueOf(objServiceLevelRank.Rank__c));
		}
        ilib_LogEvent.info('mapServiceLevelToRank : ' + (mapServiceLevelToRank != Null ? String.valueof(mapServiceLevelToRank.keySet()):'Null'));

        if(prodList != null && !prodList.isEmpty()) { //adding null checks for CMCM-6733
			//for(Product2 objProd: new ProductsSelector().selectProductsForMaterialNumber(setItemNumbers)) { //CMCM - 6733
            //CMCM - 6733 used 'prodList' public variable in for loop
                for(Product2 objProd: prodList){
				if(objProd.Service_Level__c != null && mapServiceLevelToRank.containsKey(objProd.Service_Level__c)) {
					mapMaterialNumberToRank.put(objProd.Material_Number__c, mapServiceLevelToRank.get(objProd.Service_Level__c));
				} else {
					mapMaterialNumberToRank.put(objProd.Material_Number__c, 1);
				}
			}
		}
        ilib_LogEvent.info('mapMaterialNumberToRank : ' + (mapMaterialNumberToRank != Null ? String.valueof(mapMaterialNumberToRank.keySet()):'Null'));
        updateCurrentActiveContractOnWOHepler(apIdWOMap,mapIdtoListAppliedContract,mapMaterialNumberToRank); 

    }
    private static void updateCurrentActiveContractOnWOHepler(Map<Id,Id> apIdWOMap,Map<Id, List<Applied_Contract__c>> mapIdtoListAppliedContract,map<string, Integer> mapMaterialNumberToRank) {
        List<SVMXC__Service_Order__c> lstWorkOrder = new List<SVMXC__Service_Order__c>();
        if(apIdWOMap != null && !apIdWOMap.isEmpty() && mapIdtoListAppliedContract != null && !mapIdtoListAppliedContract.isEmpty() && mapMaterialNumberToRank != null && !mapMaterialNumberToRank.isEmpty()){ //adding null checks for CMCM-6733
            for(Id idAP : apIdWOMap.keySet()) {
                String woId = apIdWOMap.get(idAP);
                SVMXC__Service_Order__c objWO = mapToUpdateWO.get(woId) != null ? 
                        mapToUpdateWO.get(woId) : new SVMXC__Service_Order__c(id=woId);
                Id idCurrentAppliedContract = null;
                integer intHighestRank = 0;
                if(mapIdtoListAppliedContract.containsKey(idAP)) {
                    idCurrentAppliedContract = mapIdtoListAppliedContract.get(idAP)[0].Id;
                    if(mapIdtoListAppliedContract.get(idAP)[0].Service_Contract__r.SVMXC__Service_Plan__c != null 
                      && mapIdtoListAppliedContract.get(idAP)[0].Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c != null 
                      && mapMaterialNumberToRank.containsKey(string.valueOf(mapIdtoListAppliedContract.get(idAP)[0].Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c))) {
                           intHighestRank = mapMaterialNumberToRank.get(string.valueOf(mapIdtoListAppliedContract.get(idAP)[0].Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c));
                    }
                    for(Applied_Contract__c objAppliedContract : mapIdtoListAppliedContract.get(idAP)) {
                        if(objAppliedContract.Service_Contract__r.SVMXC__Service_Plan__c != null 
                        && objAppliedContract.Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c != null 
                        && mapMaterialNumberToRank.containsKey(string.valueOf(objAppliedContract.Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c)) 
                        && mapMaterialNumberToRank.get(string.valueOf(objAppliedContract.Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c)) > intHighestRank) {
                                intHighestRank = mapMaterialNumberToRank.get(string.valueOf(objAppliedContract.Service_Contract__r.SVMXC__Service_Plan__r.Item_Number__c));
                                idCurrentAppliedContract = objAppliedContract.Id;
                            }
                    }
                }
                objWO.Currently_Applied_Service_Contract__c = idCurrentAppliedContract;
                mapToUpdateWO.put(objWO.Id, objWO);
            }
        }
        
        ilib_LogEvent.info('lstWorkOrder : '+UtilsCollection.getSetOfIds(lstWorkOrder));
    }
    /**
    *  @author Abhishek Yadav
    *  @description - CMCM-295: To update Applied Contrcat record on WO.
    *  @parameters : list<Sobject> records: List of Applied Contract
    *  @return : List of Associated Products Records
    **/
    public static void populateAppliedContractonWOAfterUpdate(List<Sobject> records , Map<Id, Associated_Product__c> mapOldapRecs) {
        Map<Id,Id> apIdWOMap = new Map<Id,Id>();
        Set<Id> workOrderIds = new Set<Id>();
        List<SVMXC__Service_Order__c> updatelstworkOrder = new List<SVMXC__Service_Order__c>();
        if(records != null && !records.isEmpty() && mapOldapRecs != null && !mapOldapRecs.isEmpty()){ //adding null checks for CMCM-6733
            for (Associated_Product__c associatedProduct : (List<Associated_Product__c>)records) {
                Associated_Product__c oldAp = mapOldapRecs.get(associatedProduct.Id);
                if (oldAp.Is_Primary__c != associatedProduct.Is_Primary__c && associatedProduct.Is_Primary__c && associatedProduct.Work_order__c != null) {
                    apIdWOMap.put(associatedProduct.Id , associatedProduct.Work_order__c);
                } else if (oldAp.Is_Primary__c && !associatedProduct.Is_Primary__c && associatedProduct.Work_order__c != null) {
                    workOrderIds.add(associatedProduct.Work_order__c);
                }
            }
        }
        if (workOrderIds != null && !workOrderIds.isEmpty()) {
            // query the work order and remove the applied contract lookup
            //CMCM - 6733 Added an empty check with a feature flag check for lstworkOrder
            if(lstworkOrder == null || lstworkOrder.isEmpty() || Feature.isOn(ASSOCIATED_PRODUCTS_OPTIMIZATION_FEATURE_FLAG) || isTestRunning){
                lstworkOrder = new WorkOrdersSelector().selectWorkOrderId(workOrderIds);
            }
            if(lstworkOrder != null && !lstworkOrder.isEmpty()){
                for (SVMXC__Service_Order__c wo : lstworkOrder) {
                    SVMXC__Service_Order__c objSO = mapToUpdateWO.get(wo.Id) != null ? 
                        mapToUpdateWO.get(wo.Id) : new SVMXC__Service_Order__c(id=wo.Id);
                    objSO.Currently_Applied_Service_Contract__c = null;
                    mapToUpdateWO.put(objSO.Id, objSO);
                }
            }
        }
        populateAppliedContractonWOHelper(apIdWOMap);
    }
    /**
    *  @author Abhishek Yadav
    *  @description - CMCM-8298: To delete Applied Contrcat record on AP.
    *  @parameters : list<Sobject> records: List of Associated Product
    *  @return : void
    **/
    public static void prepareAppliedContractToBeDelete(List<Sobject> records) {
        Set<Id> setAssociatedProduct = new Set<Id>();
        List<Applied_Contract__c> toBeDeletedAppliedContract = new List<Applied_Contract__c>();
        for (Associated_Product__c associatedProduct : (List<Associated_Product__c>)records) {
                setAssociatedProduct.add(associatedProduct.Id);
        }
        // query applied contract
        toBeDeletedAppliedContract = new AppliedContractsSelector().selectAssociatedProductEntitlements(setAssociatedProduct);
        for(Applied_Contract__c ap : toBeDeletedAppliedContract) {
            appliedContractIds.add(ap.Id);
        }
    }
    /**
    *  @author Vishal
    *  @description - CMCM-9248: Publish event on AP DML operations.
    *  @parameters : list<Sobject> records: List of Associated Product
    *  @return : void
    **/
    public static void publishAPEvent(List<Sobject> records){
        List<Associated_Product_DML_Event__e> events = new List<Associated_Product_DML_Event__e>();
        for (Associated_Product__c ap :  (List<Associated_Product__c>)records) {
            Associated_Product_DML_Event__e event = new Associated_Product_DML_Event__e();
            event.AP_RecordId__c = ap.Id;
            events.add(event);
        }
        if (!events.isEmpty()) {
            EventBus.publish(events);
        } 


    }
}
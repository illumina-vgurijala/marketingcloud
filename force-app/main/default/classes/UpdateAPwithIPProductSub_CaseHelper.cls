/**************************************************************************************************************************************
* NAME   : UpdateAPwithIPProductSub_CaseHelper
* DESCRIPTION  : Domain class for Cases.
* Test Class- TestUpdateAPwithIPProductSub_CaseHelper.cls
*  
*                    
* @AUTHOR : Abhishek Yadav
* @DATE   : 27-Nov-2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav         27-Nov-2024          Initial Version. Added logic for CMCM-11352
****************************************************************************************************************************************/
public with sharing class UpdateAPwithIPProductSub_CaseHelper {
    public static final String LOG_TITLE = 'UpdateAPwithIPProductSub_CaseHelper';
    public static final Id SERVICE_REQUEST_CASE_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
    public static final Id BUSINESS_ISSUE_CASE_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();     
    public static final Id INQUIRY_CASE_RECORDTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Inquiry').getRecordTypeId();
    public static List<Associated_Product__c> apBIList = new List<Associated_Product__c>();
    public static Set<Id> apBICaseIds = new Set<Id>();
    /**
    *  CMCM-11352
    *  @author : Abhishek Yadav
    *  @description - upsert Associated Product on Case Record Type Chnage
    **/
    public static void isCaseIPProdorSUbchanged(List<Case> csList , Map<Id,Case> oldMap , List<SVMXC__Service_Order__c> woList) {
        ilib_LogEvent.push(LOG_TITLE + '.isCaseIPProdorSUbchanged');
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>();
        Map<Id,SVMXC__Service_Order__c> caseIdWoMap = new Map<Id,SVMXC__Service_Order__c>();
        Set<Id> caseIds = (new Map<Id, Case>(csList)).keySet();
        for(SVMXC__Service_Order__c wo : woList) {
            caseIdWoMap.put(wo.SVMXC__Case__c,wo);
        }
        for(Case cs : new CasesSelector().selectCases(caseIds)) {
            Case oldCase = oldMap.get(cs.Id);
            // for converting the record Type from Inquery to BI
            if((oldCase.recordTypeId == INQUIRY_CASE_RECORDTYPE && cs.recordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE) || (oldCase.recordTypeId == SERVICE_REQUEST_CASE_RECORDTYPE && cs.recordTypeId == BUSINESS_ISSUE_CASE_RECORDTYPE)) {
                // handle multiple lookup on case
                List<Associated_Product__c> multipleAssProdList =  populateAssociatedProduct(cs , caseIdWoMap , oldCase);
                if (!multipleAssProdList.isEmpty()) {
                    apBICaseIds.add(cs.Id);
                    insertAssociatedProd.addAll(multipleAssProdList);
                }
                 // if there is single loopkup on Install product , Subscription & Product
                List<Associated_Product__c> singleAssProdList = singleAssociatedProduct(cs , caseIdWoMap , oldCase);
                if (!singleAssProdList.isEmpty()) {
                    apBICaseIds.add(cs.Id);
                    insertAssociatedProd.addAll(singleAssProdList);
                }
            }
        }
        if(!insertAssociatedProd.isEmpty()) {
            apBIList.addall(insertAssociatedProd);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *  CMCM-11352
    *  @author : Abhishek Yadav
    *  @description - create instance of Associated Products
    **/
    private static List<Associated_Product__c> populateAssociatedProduct(Case cs , Map<Id,SVMXC__Service_Order__c> caseIdWoMap , Case oldCase) {
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>(); 
        // if product and  Subscription are populated and Subscription's product same as product
        if(((oldCase.SVMXC__Product__c == null && oldCase.Subscription__c == null) || (oldCase.SVMXC__Product__c != cs.SVMXC__Product__c && oldCase.Subscription__c != cs.Subscription__c)) && cs.SVMXC__Product__c != null && cs.Subscription__c != null && cs.Subscription__r.Product_Name__c != null && cs.SVMXC__Product__r.Name == cs.Subscription__r.Product_Name__c && String.isBlank(cs.SVMXC__Component__c)) {
            Associated_Product__c prodsubAP = associatedSubscription(cs , caseIdWoMap , true);
            insertAssociatedProd.add(prodsubAP);
        }
        insertAssociatedProd.addall(populateAssociatedProductHelper(cs , caseIdWoMap , oldCase));
        return insertAssociatedProd;
    }

    private static List<Associated_Product__c> populateAssociatedProductHelper(Case cs , Map<Id,SVMXC__Service_Order__c> caseIdWoMap , Case oldCase) {
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>(); 
        // if Install product and  Subscription are populated
        if(((oldCase.SVMXC__Component__c == null && oldCase.Subscription__c == null) || (oldCase.SVMXC__Component__c != cs.SVMXC__Component__c && oldCase.Subscription__c != cs.Subscription__c)) && !String.isBlank(cs.SVMXC__Component__c) && !String.isBlank(cs.Subscription__c)) {
            Associated_Product__c installAP = associatedInstallProduct(cs , caseIdWoMap);
            insertAssociatedProd.add(installAP);
            Associated_Product__c subAP = associatedSubscription(cs , caseIdWoMap , false);
            insertAssociatedProd.add(subAP);
        }
        // if product and  Subscription are populated and Subscription's product not same as product
        if(((oldCase.SVMXC__Product__c == null && oldCase.Subscription__c == null) || (oldCase.SVMXC__Product__c != cs.SVMXC__Product__c && oldCase.Subscription__c != cs.Subscription__c)) && cs.SVMXC__Product__c != null && cs.Subscription__c != null && String.isBlank(cs.SVMXC__Component__c)  && (cs.Subscription__r.Product_Name__c == null || cs.SVMXC__Product__r.Name != cs.Subscription__r.Product_Name__c)) {            
            Associated_Product__c prodAP = associatedProd(cs , caseIdWoMap);
            insertAssociatedProd.add(prodAP);
            Associated_Product__c subscriptionAP = associatedSubscription(cs , caseIdWoMap , false);
            insertAssociatedProd.add(subscriptionAP);
        }
        return insertAssociatedProd;
    }
    /**
    *  CMCM-11352
    *  @author : Abhishek Yadav
    *  @description - create single Associated Products
    **/
    private static List<Associated_Product__c> singleAssociatedProduct(Case cs , Map<Id,SVMXC__Service_Order__c> caseIdWoMap , Case oldCase) {
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>();
        // if Install product is populated and Subscription & Product is not populated or remain same
        if((oldCase.SVMXC__Component__c == null || oldCase.SVMXC__Component__c != cs.SVMXC__Component__c) && !String.isBlank(cs.SVMXC__Component__c) && (String.isBlank(cs.Subscription__c) || oldCase.Subscription__c == cs.Subscription__c)) {
            Associated_Product__c installProdAP = associatedInstallProduct(cs , caseIdWoMap);
            installProdAP.Product__c = !String.isBlank(cs.SVMXC__Product__c) ? cs.SVMXC__Product__c : null;
            insertAssociatedProd.add(installProdAP);
        }
        // if product is populated and Subscription , Install Product not populated or remain same
        if((oldCase.SVMXC__Product__c == null || oldCase.SVMXC__Product__c != cs.SVMXC__Product__c) && cs.SVMXC__Product__c != null && (cs.Subscription__c == null || oldCase.Subscription__c == cs.Subscription__c) && (String.isBlank(cs.SVMXC__Component__c) || oldCase.SVMXC__Component__c == cs.SVMXC__Component__c)) {
            Associated_Product__c productAP = associatedProd(cs , caseIdWoMap);
            insertAssociatedProd.add(productAP);
        }
        // if Subscription is populated and product , Install Product not populated or remain same
        insertAssociatedProd.addall(singleAssociatedProductHelper(cs , caseIdWoMap , oldCase));
        return insertAssociatedProd;
    }
    private static List<Associated_Product__c> singleAssociatedProductHelper(Case cs , Map<Id,SVMXC__Service_Order__c> caseIdWoMap , Case oldCase) {
        List<Associated_Product__c> insertAssociatedProd = new List<Associated_Product__c>();
        if((oldCase.Subscription__c == null || oldCase.Subscription__c != cs.Subscription__c) && cs.Subscription__c != null && (cs.SVMXC__Product__c == null || oldCase.SVMXC__Product__c == cs.SVMXC__Product__c) && (String.isBlank(cs.SVMXC__Component__c) || oldCase.SVMXC__Component__c == cs.SVMXC__Component__c)) {
            Associated_Product__c subscriptionAP = associatedSubscription(cs , caseIdWoMap , true);
            insertAssociatedProd.add(subscriptionAP);
        }
        return insertAssociatedProd;
    }
    /**
    *  CMCM-11352
    *  @author : Abhishek Yadav
    *  @description - create Associated_Product__c instance with install product lookup
    **/
    private static Associated_Product__c associatedInstallProduct(Case cs , Map<Id,SVMXC__Service_Order__c> caseIdWoMap) {
        Associated_Product__c installProdAP = new Associated_Product__c();
            installProdAP.Case__c = cs.Id;
            installProdAP.Installed_Product__c  = cs.SVMXC__Component__c;
            installProdAP.Is_Primary__c = true;
            installProdAP.Work_Order__c = caseIdWoMap.containsKey(cs.Id) ? caseIdWoMap.get(cs.Id).Id : null;
        return installProdAP;
    }
    /**
    *  CMCM-11352
    *  @author : Abhishek Yadav
    *  @description - create Associated_Product__c instance with product lookup
    **/
    private static Associated_Product__c associatedProd(Case cs , Map<Id,SVMXC__Service_Order__c> caseIdWoMap) {
        Associated_Product__c prodAP = new Associated_Product__c();
            prodAP.Case__c = cs.Id;
            prodAP.Product__c = cs.SVMXC__Product__c;
            prodAP.Is_Primary__c = true;
            prodAP.Work_Order__c = caseIdWoMap.containsKey(cs.Id) ? caseIdWoMap.get(cs.Id).Id : null;
        return prodAP;
    }
    /**
    *  CMCM-11352
    *  @author : Abhishek Yadav
    *  @description - create Associated_Product__c instance with Subscription__c lookup
    **/
    private static Associated_Product__c associatedSubscription(Case cs , Map<Id,SVMXC__Service_Order__c> caseIdWoMap, Boolean isPrimary) {
        Associated_Product__c subscriptionAP = new Associated_Product__c();
            subscriptionAP.Case__c = cs.Id;
            subscriptionAP.Subscription__c = cs.Subscription__c;
            subscriptionAP.Is_Primary__c = isPrimary;
            subscriptionAP.Work_Order__c = caseIdWoMap.containsKey(cs.Id) ? caseIdWoMap.get(cs.Id).Id : null;
        return subscriptionAP;
    }
}
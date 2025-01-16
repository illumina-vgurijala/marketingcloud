/*****************************************************************************************************************
 * Class Name: AutoPopulateWOField_WOHelper
 * Description: Helper class to auto populate work order fields
 * Author: Pooja Shalwadi
 * 
 * Date: 28-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Pooja                   28-Dec-2021                      POC: auto-populate Product family and Repair Protocol for Before event
 * Shivani                 15-Dec-2022                      DCP-52634 - Populate Ssubscription fields
 * Shivani                 20-Dec-2022                      DCP-58614 - Optimize logic for Repair Protocols
 * Priya                   13-Nov-2023                      CMCM-3104 - Work Order SLA Terms field to be Read Only 
 * Nancy                   26-Sep-2024                      CMCM-10494 - Work Order Trigger Long Term Optimization - Part 2
 ******************************************************************************************************************/
public with sharing class AutoPopulateWOField_WOHelper {

    private static final STRING RP_MANDATORY_METADATA = 'Repair_Protocol_Families';   //DCP-58614 -Dummy Commit
    public static List<SVMXC__Service_Contract_Products__c> lstCoveredProducts = new List<SVMXC__Service_Contract_Products__c>(); //CMCM-10494
    //DCP-49644
    /*******************************************************************************************************
    * @description DCP-49644: POC: helper method to update Product Family and Repair Protocol on WO
    * @Author:Pooja
    */
    public static void autoPopulateWOFields(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder, Map<Id,Product2> allProductRecMap) {
        if(objOldWorkOrder==null || (objOldWorkOrder!=null && objWorkOrder.SVMXC__Product__c!=objOldWorkOrder.SVMXC__Product__c )) {
            
            String strProdFamily=null;
            if(objWorkOrder.SVMXC__Product__c!=null && allProductRecMap.containsKey(objWorkOrder.SVMXC__Product__c) && 
            allProductRecMap.get(objWorkOrder.SVMXC__Product__c).Family!=null) {
                strProdFamily=allProductRecMap.get(objWorkOrder.SVMXC__Product__c).Family;
            }
            
            populateProductFamilyAndRepairs(objWorkOrder,strProdFamily);
        }
    }

    /*******************************************************************************************************
    * @description DCP-49644: POC: helper method to update Product family & Repair Protocol on WO
    * @Author:Pooja
    */
    public static void populateProductFamilyAndRepairs(SVMXC__Service_Order__c objWO, String productFamilyStr) {
        String productFamiliesToVerify = Code_Parameter__mdt.getInstance(RP_MANDATORY_METADATA).PickListValue__c;  //DCP-58614

        objWO.Product_Family__c = productFamilyStr;//Update product family
        if(productFamilyStr == null || (productFamilyStr != null && String.isNotBlank(productFamiliesToVerify) 
                && productFamiliesToVerify.contains('"'+ productFamilyStr + '"'))) {  //DCP-58614 [usiing Metadata record]
            objWO.Repair_protocols__c = '';
        } else {
            objWO.Repair_protocols__c = WorkOrders.STRING_RP_NOT_APPLICABLE;
        }
            
    }

    /*******************************************************************************************************
    * @description DCP-54018: Work Order Optimization
    * @param records records
    * @return void
    */
    public static void populateFieldsBeforeInsert(List<sObject> records,  List<Product2> lstProducts) {
        Map<Id,Product2> allProductRecMap = new Map<Id,Product2>(lstProducts);//POC: DCP-49644

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>) records) {

            //POC: DCP-49644: Pooja :  Product family update on WO
            autoPopulateWOFields(objWorkOrder, null, allProductRecMap);
            //POC: DCP-49644: Pooja :END

            //DCP-37657:AC-5:To mark Training Required as true for all installation work orders
            if(objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_INSTALLATION) {
                objWorkOrder.Training_Required__c = true;
            }

            //DCP-844
            //If the work order is selected for auto dispatch then assign technician to it based on the role
            if(objWorkOrder.Is_Auto_Dispatch__c && objWorkOrder.SVMXC__Company__c != null && objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_INSTALLATION
                && objWorkOrder.Partner_Installation_WO__c == false || 
                    (String.isNotBlank(objWorkOrder.Origin__c) && objWorkOrder.Origin__c.EqualsIgnoreCase(WorkOrders.STRING_EMAIL_PROACTIVE_TS))) {
                objWorkorder.Field_Support_User_Role__c = null;    
            }
        }

    }
    
    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To populate Fields on Work Orders from Case and Installed Products
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public static void populateWorkOrderFieldsfromCaseandIP(List<Sobject> records, List<Case> lstCaserecords,  List<SVMXC__Installed_Product__c> lstInstalledProductrecords) {
        Map<id, Case> caseIdToCaseRec = new Map<id, Case>();
        Map<id, SVMXC__Installed_Product__c> ipIdToIPRec = new Map<id, SVMXC__Installed_Product__c>();

        //DCP-33452 added 2 fields Follow_up_Needed__c & Next_Steps__c.
        for(Case objCase: lstCaserecords) {
            caseIdToCaseRec.put(objCase.Id, objCase);
        }
        
        //Refactor WorkFlow - Work Order : Update Product Group for ICE
        for(SVMXC__Installed_Product__c objIP: lstInstalledProductrecords) {
            ipIdToIPRec.put(objIP.Id, objIP);
        }
        //End of Refactor WorkFlow - Work Order : Update Product Group for ICE
    
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>) records) {
        
            if((objWorkOrder.SVMXC__Case__c != null && Trigger.isInsert) || WorkOrders.isCaseUpdated) {
                assignCaseFieldsOnWO(objWorkOrder, caseIdToCaseRec);
            } 
            
            populateSiteAndICEProds(objWorkOrder, ipIdToIPRec);

            //DCP-25645
            if(objWorkOrder.SVMXC__Component__c != null && ipIdToIPRec.containsKey(objWorkOrder.SVMXC__Component__c)) {
                objWorkOrder.Service_BOM__c = ipIdToIPRec.get(objWorkOrder.SVMXC__Component__c).Service_Bill_Of_Materials__r.Name;
            
            }
        }

    }

    /*
    * DEscription
    */
    private static void populateSiteAndICEProds(SVMXC__Service_Order__c objWorkOrder,  Map<id, SVMXC__Installed_Product__c> ipIdToIPRec) {
        //Updated from else if to if for PRB0044900
        if((objWorkOrder.SVMXC__Component__c != null && Trigger.isInsert) || WorkOrders.isIPorProdUpdated) {
            if(ipIdToIPRec.containsKey(objWorkOrder.SVMXC__Component__c)) {
                //Refactor WorkFlow - Work Order : Update Product Group for ICE
                if(objWorkOrder.SVMXC__Case__c == null) {
                    objWorkOrder.SVMXC__Site__c = ipIdToIPRec.get(objWorkOrder.SVMXC__Component__c).SVMXC__Site__c;
                }
                objWorkOrder.ICE_WO_Products__c = ipIdToIPRec.get(objWorkOrder.SVMXC__Component__c).SVMXC__Product__r.Product_Group__c;
                //End of Refactor WorkFlow - Work Order : Update Product Group for ICE
            }
        }
    }

    /**Assign Field value from case to work Order  */
    public static void assignCaseFieldsOnWO(SVMXC__Service_Order__c objWorkOrder ,  Map<id, Case> caseIdToCaseRec ){

        if(caseIdToCaseRec != null && !caseIdToCaseRec.isEmpty() && caseIdToCaseRec.containskey(objWorkOrder.SVMXC__Case__c)) {
			objWorkOrder.SVMXC__Company__c = caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).AccountId;
			objWorkOrder.SVMXC__Component__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).SVMXC__Component__c;
			objWorkOrder.SVMXC__Contact__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).ContactId;
			objWorkOrder.SVMXC__Entitlement_Notes__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).SVMXC__Entitlement_Notes__c;
			objWorkOrder.SVMXC__Priority__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Priority;
            if(objWorkOrder.SVMX_PS_Subject__c != caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Description){
                objWorkOrder.Notes__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Description;
            }
			objWorkOrder.SVMXC__Product__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).SVMXC__Product__c;
			objWorkOrder.SVMXC__Site__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).SVMXC__Site__c;
			
            //Added as part of DCP-46053
            if(String.isBlank(objWorkOrder.Product_Lot_Number__c)){
                objWorkOrder.Product_Lot_Number__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Product_Lot_Number__c;
            }
            if(String.isBlank(objWorkOrder.Product_Serial_Number__c)){
			    objWorkOrder.Product_Serial_Number__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Product_Serial_Number__c;
            }
            //DCP-46053 ends.
			if(caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).contactId != null){
				objWorkOrder.SVMX_PS_Contact_Email__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).contact.Email;
			}
			if(caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).contactId != null){
				objWorkOrder.SVMX_PS_Contact_Phone__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).contact.Phone;
			}
			objWorkOrder.SVMX_PS_Origin__c  =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Origin;
			objWorkOrder.SVMX_PS_Subject__c =  caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Subject;
			//Moved as no addiitonal check is required. Change done for INC0321791
			objWorkOrder.Case_Subject__c = caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Subject;
			objWorkOrder.Case_Description__c = caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Description;
			objWorkOrder.Case_Next_Steps__c = caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Next_Steps__c;
			objWorkOrder.Case_Follow_up_Needed__c = caseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Follow_up_Needed__c;
        }
    }

    /*
    *  @AUTHOR:  Digvijay (code refractoring)
    *  @DESCRIPTION: To Populate Contact Fields on work Order
    *  @PARAM :  List<Sobject>  
    *  return : void
    */ 
    public static void populateContactFieldsonWorkOrder(List<Sobject> records) {
        Map<Id, Contact> contactIdToRecord =new Map<Id, Contact>();
         Map < Id, SVMXC__Service_Group_Members__c > idToFieldSupport = new Map < Id, SVMXC__Service_Group_Members__c > ();

        for(Contact objCont: WorkOrders.lstContactRecords) {
            ContactIdToRecord.put(objCont.Id, objCont);
        }

        if(!WorkOrders.lstServiceGroupMembers.IsEmpty()) {
             for(SVMXC__Service_Group_Members__c obj: WorkOrders.lstServiceGroupMembers) {
                IdToFieldSupport.put(obj.id, obj);
            }
        }
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            
            populateEmailAndPhone(objWorkOrder, ContactIdToRecord);

            //DCP-33497 if contact preferred language is available
            //INC0424658 Adding blank check for Contact_Preferred_Language__c
            if(String.IsBlank(objWorkOrder.Contact_Preferred_Language__c) && objWorkOrder.SVMXC__Contact__c != null 
                    && ContactIdToRecord.containsKey(objWorkOrder.SVMXC__Contact__c) && ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c) != null 
                    && !String.isBlank(ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c).Preferred_Language__c)) {
                objWorkOrder.Contact_Preferred_Language__c=ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c).Preferred_Language__c;
            } else if(String.IsBlank(objWorkOrder.Contact_Preferred_Language__c) && objWorkOrder.SVMXC__Group_Member__c != null 
                    && IdToFieldSupport.containsKey(objWorkOrder.SVMXC__Group_Member__c) && IdToFieldSupport.get(objWorkOrder.SVMXC__Group_Member__c) != null
                    &&!String.isBlank(IdToFieldSupport.get(objWorkOrder.SVMXC__Group_Member__c).Preferred_Service_Report_Language__c)) {
                //if field support  preferred language is available and contact preferred language is not available
                objWorkOrder.Contact_Preferred_Language__c = IdToFieldSupport.get(objWorkOrder.SVMXC__Group_Member__c).Preferred_Service_Report_Language__c;
            } else if(String.IsBlank(objWorkOrder.Contact_Preferred_Language__c) && (objWorkOrder.SVMXC__Contact__c == null && objWorkOrder.SVMXC__Group_Member__c == null)
                    || (ContactIdToRecord.containsKey(objWorkOrder.SVMXC__Contact__c) && ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c) != null 
                        && String.isBlank(ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c).Preferred_Language__c)
                        && IdToFieldSupport.containsKey(objWorkOrder.SVMXC__Group_Member__c) && IdToFieldSupport.get(objWorkOrder.SVMXC__Group_Member__c) != null 
                        && String.isBlank(IdToFieldSupport.get(objWorkOrder.SVMXC__Group_Member__c).Preferred_Service_Report_Language__c))) {
                //if field support  preferred language  and contact preferred language are not available
                objWorkOrder.Contact_Preferred_Language__c = WorkOrders.STRING_WO_CONTACT_PREFERRED_LANGUAGE_ENGLISH;
                
            }
        }
    }

    /*
    *  Description
    */ 
    private static void populateEmailAndPhone(SVMXC__Service_Order__c objWorkOrder,  Map<Id, Contact> contactIdToRecord) {
        //Refactor WorkFlow - WorkOrderUpdateContactPhoneAndContactEmail
        if(objWorkOrder.SVMXC__Contact__c !=null  && ContactIdToRecord.containsKey(objWorkOrder.SVMXC__Contact__c)) {
                objWorkOrder.SVMX_PS_Contact_Email__c = ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c).Email;
            objWorkOrder.SVMX_PS_Contact_Phone__c = ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c).Phone;
        }
    }

    /*
    *  @AUTHOR:  Digvijay (code refractoring)
    *  @DESCRIPTION: Installation and PM Work Order Assignment 
    *  @PARAM :  List<Sobject>  
    *  return : void
    */
    public static void populateAppliedContractandSLATermsonWorkOrder(List<Sobject> records, Channel_Partner_Profile_Settings__c channelPartner) {
        Integer maxLength = 255;
        Map<Id, List<String>> mapEntitlements=new Map<Id, List<String>>();
        Map<Id, List<String>> mapERPEntitlements=new Map<Id, List<String>>();
        //CMCM-10494 - Start
        Set<Id> setIPIds = new Set<Id>();

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {  
            if(objWorkOrder.SVMXC__Component__c != null){
                setIPIds.add(objWorkOrder.SVMXC__Component__c);
            }
        }

        if(Trigger.isInsert && setIPIds!=null && !setIPIds.isEmpty() && lstCoveredProducts.isEmpty()){   
            lstCoveredProducts = new CoveredProductSelector().selectActiveCoveredProducts(setIPIds);
        }

        mapEntitlements = getEntitlementsForWO(lstCoveredProducts, WorkOrders.lstCoveredLocations);
        mapERPEntitlements = getEntitlementsForERPWO(lstCoveredProducts, WorkOrders.lstCoveredLocations);
        //CMCM-10494 - End

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {  
            //logic to update Applied_Service_Contract__c field on WO
            List<String> lstContractNames = new List<String>();
            List<String> lstERPContractNames = new List<String>();
            
            addTolstContractNames(objWorkOrder, mapEntitlements, lstContractNames);
            addTolstERPContractNames(objWorkOrder, mapERPEntitlements, lstERPContractNames);
            ServiceContractAndEntitlement_WOHelper.updateAppliedContractOnWorkOrder(objWorkOrder, lstContractNames, maxLength);
            objWorkOrder.Service_Contract_ERP_Header__c =  !lstERPContractNames.isEmpty() ? String.join(lstERPContractNames, ',') : null;           
            //Refactor WorkFlow - WorkOrder:Update Is Customer Sign Mandatory
			// Installation condition has been removed as part of DCP-45359 & DCP-46827(added CP check)
            if(objWorkOrder.SVMXC__Billing_Type__c == WorkOrders.STRING_LABEL_BILLABLE && !channelPartner.Is_Channel_Partner__c) {
                objWorkOrder.Is_Customer_Sign_Mandatory__c = true;
            }
        }
    }

    /*
    * DEscription
    */
    private static void addTolstContractNames(SVMXC__Service_Order__c objWorkOrder, Map<Id, List<String>> mapEntitlements, List<String> lstContractNames) {
        if(objWorkOrder.SVMXC__Component__c != null && !mapEntitlements.isEmpty() && mapEntitlements.containsKey(objWorkOrder.SVMXC__Component__c) && mapEntitlements.get(objWorkOrder.SVMXC__Component__c) != null){
            lstContractNames.addAll(mapEntitlements.get(objWorkOrder.SVMXC__Component__c));
        }
        if(objWorkOrder.SVMXC__Site__c != null && !mapEntitlements.isEmpty() && mapEntitlements.containsKey(objWorkOrder.SVMXC__Site__c) && mapEntitlements.get(objWorkOrder.SVMXC__Site__c) != null) {  
            lstContractNames.addAll(mapEntitlements.get(objWorkOrder.SVMXC__Site__c));
        }
    }

    /*
    * DEscription
    */
    private static void addTolstERPContractNames(SVMXC__Service_Order__c objWorkOrder, Map<Id, List<String>> mapERPEntitlements,  List<String> lstERPContractNames) {
        if(objWorkOrder.SVMXC__Component__c != null && !mapERPEntitlements.isEmpty() && mapERPEntitlements.containsKey(objWorkOrder.SVMXC__Component__c) && mapERPEntitlements.get(objWorkOrder.SVMXC__Component__c) != null){
            lstERPContractNames.addAll(mapERPEntitlements.get(objWorkOrder.SVMXC__Component__c));
        }
        
        if(objWorkOrder.SVMXC__Site__c != null && !mapERPEntitlements.isEmpty() && mapERPEntitlements.containsKey(objWorkOrder.SVMXC__Site__c) && mapERPEntitlements.get(objWorkOrder.SVMXC__Site__c) != null){
            lstERPContractNames.addAll(mapERPEntitlements.get(objWorkOrder.SVMXC__Site__c));
        }
    }

    /* 
     *  @method getEntitlementsForWO
     *  @DESCRIPTION -  get the entitlements for based on location and installed product.
     *  @PARAM : List of covered products and covered locations from which contracts would be attached to work order
     *  @RETURN : map of id, list of contract names
     */
    public static Map<Id, List<String>> getEntitlementsForWO(List<SVMXC__Service_Contract_Products__c> lstCoveredProducts , List<SVMXC__Service_Contract_Sites__c> lstCoveredLocations){
        Map<Id, List<String>> mapEntitlements = new Map<Id, List<String>>();
        for(SVMXC__Service_Contract_Products__c coveredProduct : lstCoveredProducts){
            if(!mapEntitlements.containsKey(coveredProduct.SVMXC__Installed_Product__c)){
                mapEntitlements.put(coveredProduct.SVMXC__Installed_Product__c, new List<String> {});
            }
            mapEntitlements.get(coveredProduct.SVMXC__Installed_Product__c).add(coveredProduct.SVMXC__Service_Contract__r.Name);
        }
        if(lstCoveredLocations  != null && !lstCoveredLocations.isEmpty()){
            for(SVMXC__Service_Contract_Sites__c coveredLocation : lstCoveredLocations){
                if(!mapEntitlements.containsKey(coveredLocation.SVMXC__Site__c)){
                    mapEntitlements.put(coveredLocation.SVMXC__Site__c, new List<String> {});
                }
                mapEntitlements.get(coveredLocation.SVMXC__Site__c).add(coveredLocation.SVMXC__Service_Contract__r.Name);
            }
        }
        System.debug('mapEntitlements--:'+mapEntitlements);
        return mapEntitlements;
    }

    /* 
     *  @method getEntitlementsForERPWO
     *  @DESCRIPTION -  get the entitlements for based on location and installed product for ERP Header.
     *  @PARAM : List of covered products and covered locations from which contracts would be attached to work order
     *  @RETURN : map of id, list of ERP Header Contract Name
     */
    public static Map<Id, List<String>> getEntitlementsForERPWO(List<SVMXC__Service_Contract_Products__c> lstCoveredProducts , List<SVMXC__Service_Contract_Sites__c> lstCoveredLocations){
        
        Map<Id, List<String>> mapERPEntitlements = new Map<Id, List<String>>();
        for(SVMXC__Service_Contract_Products__c coveredProduct : lstCoveredProducts){
           
            if(!mapERPEntitlements.containsKey(coveredProduct.SVMXC__Installed_Product__c)){
                mapERPEntitlements.put(coveredProduct.SVMXC__Installed_Product__c, new List<String> {});
            }
            
            mapERPEntitlements.get(coveredProduct.SVMXC__Installed_Product__c).add(coveredProduct.SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c);
        }
        if(lstCoveredLocations  != null && !lstCoveredLocations.isEmpty()){
            for(SVMXC__Service_Contract_Sites__c coveredLocation : lstCoveredLocations){
                if(! mapERPEntitlements.containsKey(coveredLocation.SVMXC__Site__c)){
                     mapERPEntitlements.put(coveredLocation.SVMXC__Site__c, new List<String> {});
                }
             
                mapERPEntitlements.get(coveredLocation.SVMXC__Site__c).add(coveredLocation.SVMXC__Service_Contract__r.ERP_Header_Contract_Number__c);
            }
        }
        
       return mapERPEntitlements;
    }    

    /**
	* Method: updateWOFieldsFromIP
	* Description: RITM0415785 -  used to update SLA terms and Instrument down fields on work order from Installed product.
	* Params: List of Work orders
	* return: void
	**/
    public static void updateWOFieldsFromIP(List<Sobject> records, Map<Id, sObject> oldRecords) {
		//map of installed products
        Map<id, SVMXC__Installed_Product__c> ipIdToIPRec = new Map<id, SVMXC__Installed_Product__c>();
        List<SVMXC__Service_Order__c> lstWorkOrdersForReQuotingCheck = new List<SVMXC__Service_Order__c>(); //DCP-38810

        for(SVMXC__Installed_Product__c objIP: WorkOrders.lstInstalledProductrecords) {
            ipIdToIPRec.put(objIP.Id, objIP);
        }

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            //INC0319842
            SVMXC__Service_Order__c objOldWorkOrder = oldRecords != null && !oldRecords.isEmpty() ? (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)) : null;

            populateSLATerm(objWorkOrder, objOldWorkOrder, ipIdToIPRec);
            //DCP-38810
            if(Trigger.IsUpdate && objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED
                    && objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES && objWorkOrder.SVMXC__Billing_Type__c == WorkOrders.STRING_LABEL_BILLABLE && !objWorkOrder.Partner_Work_Order__c) {
                lstWorkOrdersForReQuotingCheck.add(objWorkOrder);
            }
        }
        if(!lstWorkOrdersForReQuotingCheck.isEmpty()) {
            PromptReQuoteOnBillableWO.verifyIfRequotingIsRequiredForWO(lstWorkOrdersForReQuotingCheck);
        }
        //End of DCP-38810
    }

    /**
	* Method: populateSLATerm
	* Description:populate SLA Term
	* Params: objWorkOrder and objOldWorkOrder
	* return: void
	**/
    private static void populateSLATerm(SVMXC__Service_Order__c objWorkOrder, SVMXC__Service_Order__c objOldWorkOrder, Map<id, SVMXC__Installed_Product__c> ipIdToIPRec ) {
        
        if(objWorkOrder.SVMXC__Component__c != null) {
            if(ipIdToIPRec.containsKey(objWorkOrder.SVMXC__Component__c) 
                    && (Trigger.IsInsert || (objOldWorkOrder != null && objOldWorkOrder.SVMXC__Component__c != objWorkOrder.SVMXC__Component__c))) {
            objWorkOrder.SVMXC__SLA_Terms__c = ipIdToIPRec.get(objWorkOrder.SVMXC__Component__c).Currently_Active_Service_Contract__r.SVMXC__Service_Level__c;
                    }
        //CMCM-3104 Start
        } else {
            objWorkOrder.SVMXC__SLA_Terms__c = null;
        }
        //CMCM-3104 end
        
    }

    /*******************************************************************************************************
    * @description DCP-52634 Method to populate fields from Subscription
    * @param objWorkOrder SVMXC__Service_Order__c
    * @return void
    */
    public static void populateFieldsFromSubscription(SVMXC__Service_Order__c objWorkOrder, SVMXC__Service_Order__c objOldWorkOrder, Map<Id, SVMXC__Installed_Product__c> mapIPRecs) {
        Boolean checkSubscription = objWorkOrder.Subscription__c!=null && !WorkOrders.mapOfSubscription.isEmpty() && WorkOrders.mapOfSubscription.containsKey(objWorkOrder.Subscription__c) ? true :false;
                
        

        if(checkSubscription || (objOldWorkOrder != NULL && objOldWorkOrder.Subscription__c != objWorkOrder.Subscription__c)) {
            objWorkOrder.Subscription_License_Status__c = checkSubscription ? WorkOrders.mapOfSubscription.get(objWorkOrder.Subscription__c).Status__c : '';
            objWorkOrder.Registrant_Email_Address__c = checkSubscription ? WorkOrders.mapOfSubscription.get(objWorkOrder.Subscription__c).Registration_Contact_Email__c : '';
            objWorkOrder.Domain_Name__c = checkSubscription ? WorkOrders.mapOfSubscription.get(objWorkOrder.Subscription__c).Domain_URL_Pattern__c : '';
            objWorkOrder.Workgroup_Name__c = checkSubscription ? WorkOrders.mapOfSubscription.get(objWorkOrder.Subscription__c).Workgroup_Name__c : '';
            objWorkOrder.SubscriptionID__c = checkSubscription ? WorkOrders.mapOfSubscription.get(objWorkOrder.Subscription__c).Zuora_Subscription_ID__c : '';
        }
        populateProductFromIPOrSubscription(objOldWorkOrder, objWorkOrder, mapIPRecs);
    }

    /*******************************************************************************************************
    * @description DCP-52634 Method to populate Product from IP/Subscription
    */
    private static void populateProductFromIPOrSubscription(SVMXC__Service_Order__c objOldWorkOrder, SVMXC__Service_Order__c objWorkOrder, Map<Id, SVMXC__Installed_Product__c> mapIPRecs) {
        if(objOldWorkOrder == NULL || objOldWorkOrder.Subscription__c != objWorkOrder.Subscription__c || objOldWorkOrder.SVMXC__Component__c != objWorkOrder.SVMXC__Component__c) {
            if(objWorkOrder.SVMXC__Component__c == NULL && objWorkOrder.Subscription__c != NULL && WorkOrders.mapOfSubscription.containsKey(objWorkOrder.Subscription__c)) {
                objWorkOrder.SVMXC__Product__c = WorkOrders.productCodeBYProductIdMap !=null && !WorkOrders.productCodeBYProductIdMap.isEmpty() ? WorkOrders.productCodeBYProductIdMap.get(WorkOrders.mapOfSubscription.get(objWorkOrder.Subscription__c).ProductCode__c) : null;
                // DCP-52634
            } else if (objWorkOrder.SVMXC__Component__c != NULL &&  mapIPRecs.containsKey(objWorkOrder.SVMXC__Component__c)) {
                objWorkOrder.SVMXC__Product__c = mapIPRecs.get(objWorkOrder.SVMXC__Component__c).SVMXC__Product__c;
            }
        }
    }
}
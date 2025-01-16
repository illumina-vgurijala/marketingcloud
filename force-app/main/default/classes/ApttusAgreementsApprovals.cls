/**
 *    @author Roopal Verma
 *    @date   30-Sep-2020
 *    @description    Agreement line item approvals class
 *    Modification Log:
 *   ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date               Description
 *     Roopal                     30-Aug-2020          Initial Version
 *     Tapas                      17-Nov-2020          Add addError lines to populateDiscount and calculateDiscount methods
 *     Satya Swain                26-Nov-2020          TASK0540831: Adding bypass logic for Discontinued Line Items
 *     Joshith K                  04-Dec-2020          INC0298925:Convert date time(Effective date and expiration date) of pricelist item to date type for comparing.
 *     Joshith K                  07-Dec-2020          TASK0545375:update calculate discount logic considering only agreement start date.
 *     Prabhsimran Singh          04-Mar-2021          INC0309188:update setapprovals() and updateagreement() for auto approval logic
 *     Prabhsimran Singh          25-Mar-2021          TASK0578569:Updated calculateROApprovals()
 *     Bharath Varma              27-Sep-2021          DCP-49431: Added method to trigger MFN Approvals
 *   -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *      Prem Ranjan             10-Sep-2021              DCP-49596 - Ability to trigger PPM Approvals along with Discount Approvals  
 *      Prem Ranjan             25-April-2022            CodeScan Fix:Avoid Literals in If condition
 *      Preetha                 27-Jun-2022             CMSI-90 Instrumenting the class
 *      Rajbabu                 04-Oct-2024            CMCM-11370: ByPass Special Programs RT when it has an approval category 
 * -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 * */
public with sharing class ApttusAgreementsApprovals 
{
    /*
    * @Roopal
    * List of Approval category LOVs
    */
    public enum ApprovalCategory {MATERIAL_GROUP, MATERIAL_NUMBER, DISCOUNT, MATERIAL_GROUP_CUSTOM, MATERIAL_NUMBER_CUSTOM, DISCOUNT_CUSTOM, CLM_SALES_HIERARCHY, MFN_APPROVALS} //DCP-31789
    private static Set<Id> setAgreementId;
    private static String strpriceList;
    private static Set<Id> setProductId;
    private static Set<String> setCustomerERP;
    private static Set<String> setCustomerERPFromAgreement;
    private static Set<Id> setAccountOwnerIds;
    private static Set<Id> setAgreementIdsWithHierarchyError;
    private static Set<Id> setAgreementIdsWithMatrixError;
    private static Set<Id> setAccountIds;
    private static String strCustomerERPSalesId;
    private static Map<Id,Id> mapAgreementHierarchyDiscount;
    private static Map<String,String> mapAliToERPSalesId;
    private static List<Apttus__APTS_Agreement__c> lstAgreement;
    private static Map<Id,Apttus__APTS_Agreement__c> mapAliAgreementIdToAgreement;
    private static Map<String,Account_Sales_Area__c> mapAliToAccountSalesArea;
    public static Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct;
    private static Set<String> setAllProducts;
    private static Set<Id> setAgreementToUpdate;
    private static Set<Id> setAgreementToRevert;
    private static Set<Id> setAllAgreementIds;
    private static Map<Id, Approval_Hierarchy__c> ownerToApprovalHierarchy;
    private static Map<Id,Apttus__APTS_Agreement__c> idToAgreement;
    private static Map<Id,Account> mapAgreementAccountForPriceGroup;
    private static List<Apttus_Config2__PriceListItem__c> lstpli;
    private static Map<String,Map<String,List<Apttus_Config2__PriceListItem__c>>>mapProductPricelist;
    private static Map<String, Account> customerERPToAccount;
    public static final Integer MAX_APPROVAL_LEVEL = Integer.valueOf(Label.Maximum_Approval_Level);
    public static final String HIERARCHY_RECORD_OWNER = 'Record Owner';
    public static final String HIERARCHY_CUSTOM ='Custom';
    public static final String APPROVAL_TYPE_MATNUM ='Material_Number';
    public static final String APPROVAL_TYPE_MATGRP ='Material_Group';
    public static final String APPROVAL_TYPE_DISCOUNT ='Discount';
    public static Boolean isDiscountypePercentage;
    public static final String QUOTA ='Quota';
    public static final String YES ='Yes';
    public static final String LOG_TITLE = 'ApttusAgreementsApprovals';//CMSI-90
    public static Boolean listPriceZero;
	public static set<id> setUpdatedLineItems;
	private static final Integer APPROVAL_LEVEL_1 = 1; //TASK0578569
    public static final Integer HUNDRED = 100;
    public static final String MAPISEMPTY = 'map is empty';

    /*
    *@ Roopal
    * Method for setting approval fields
    */
    public static void setApprovals(List<Apttus__AgreementLineItem__c> lstAgreementLineItem, List<Apttus__APTS_Agreement__c> listAgreementsFromIntialize)
    {
        //CMSI-90
        ilib_LogEvent.push(LOG_TITLE + '.setApprovals()');
        ilib_LogEvent.info('lstAgreementLineItem ids :'+UtilsCollection.getSetOfIds(lstAgreementLineItem));
        ilib_LogEvent.info('listAgreementsFromIntialize ids :'+UtilsCollection.getSetOfIds(listAgreementsFromIntialize));
        setAgreementId = new Set<Id>();
        strpriceList = null;
        setProductId = new Set<Id>();
        setCustomerERP =new Set<String>();
        setCustomerERPFromAgreement = new Set<String>();
        setAccountOwnerIds = new Set<Id>(); //DCP-32563
        setAgreementIdsWithHierarchyError = new Set<Id>();
        setAgreementIdsWithMatrixError = new Set<Id>();
        setAccountIds = new Set<Id>();
        strCustomerERPSalesId = null;
        mapAgreementHierarchyDiscount = new Map<Id,Id>();
        mapAliToERPSalesId = new Map<String,string>();
        lstAgreement = listAgreementsFromIntialize; // Added by Saswati - 32046, SOQL Fixes and INCIDENT
        mapAliAgreementIdToAgreement = new Map<Id,Apttus__APTS_Agreement__c>();
        mapAliToAccountSalesArea = new Map<String,Account_Sales_Area__c>();
        mapCAMIdToSetProduct = new Map<Custom_Approval_Matrix__c,Set<String>>();
        setAllProducts = new Set<String>();
        setAgreementToUpdate = new Set<Id>();
        setAgreementToRevert = new Set<Id>();
        setAllAgreementIds = new Set<Id>();
        ownerToApprovalHierarchy = new Map<Id, Approval_Hierarchy__c>();

        mapAliAgreementIdToAgreement = new Map<Id,Apttus__APTS_Agreement__c>(lstAgreement);
        //CMSI-90
        ilib_LogEvent.info('mapAliAgreementIdToAgreement :'+(!mapAliAgreementIdToAgreement.isEmpty()? String.valueOf(mapAliAgreementIdToAgreement.keySet()): MAPISEMPTY));	
		setUpdatedLineItems = new set<id>();
		
        for(Apttus__AgreementLineItem__c objAgrln : lstAgreementLineItem)
        {
            setAgreementId.add(objAgrln.Apttus__AgreementId__c);
			//INC0309188 - created set of line items which are updated
			if(String.isNotBlank(objAgrln.Id)){
				setUpdatedLineItems.add(objAgrln.Id);
			}
        }

        List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix = new CustomApprovalMatrixSelector().selectActive();
         ilib_LogEvent.info('lstCustomApprovalMatrix ids :'+UtilsCollection.getSetOfIds(lstCustomApprovalMatrix));//CMSI-90
        if (lstCustomApprovalMatrix.isEmpty()){
            List<Apttus__APTS_Agreement__c> lstObjAgree = new List<Apttus__APTS_Agreement__c>();
            Set<Apttus__APTS_Agreement__c> setObjAgree = new Set<Apttus__APTS_Agreement__c>();
            setObjAgree = updateAgreementWhenNoCAM(lstAgreementLineItem,setObjAgree);
            lstObjAgree.addAll(setObjAgree); 
            update lstObjAgree;
            ilib_LogEvent.info('lstObjAgree ids :'+UtilsCollection.getSetOfIds(lstObjAgree));//CMSI-90
            ilib_LogEvent.pop();  
            return;
        }

        ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper = getCustomApprovalMatrixWrapper(lstCustomApprovalMatrix);
        ilib_LogEvent.info('customMatrixWrapper : ' + customMatrixWrapper);//CMSI-90

        Set<Id> setCAMMaterialNoId = customMatrixWrapper.setMaterialNumberMatrixIds;

        List<Custom_Approval_Matrix_Products__c> lstCAMProduct = new CustomApprovalMatrixProductSelector().selectbyCustomApprMatrixId(setCAMMaterialNoId);

        //Getting map of Custom Approval Matrix To Set of Products from Custom approval matrix product records
        mapCAMIdToSetProduct = ApttusProposalLineItems.getMapCAMIdToSetProducts(lstCAMProduct,mapCAMIdToSetProduct,customMatrixWrapper);
        ilib_LogEvent.info('mapCAMIdToSetProduct : ' +mapCAMIdToSetProduct);//CMSI-90

        //Getting set of all products in Custom Approval matrix products records
        if(!mapCAMIdToSetProduct.isEmpty()){
            for (Set<String> setProdMatNo : mapCAMIdToSetProduct.values()){
                setAllProducts.addAll(setProdMatNo);
            }
        }
        ilib_LogEvent.info('setAllProducts : ' + setAllProducts);//CMSI-90

        //Getting lists of Customer ERP ids
        for(Apttus__AgreementLineItem__c ali : lstAgreementLineItem)
        {
            strCustomerERPSalesId = generateStrCustomerErpID(ali,mapAliAgreementIdToAgreement);
            String keyAliToErpSalesId = String.valueOf(ali.Line_Type__c)+String.valueOf(ali.Discount_Type__c)+String.valueOf(ali.RecordTypeId)+strCustomerERPSalesId;
            mapAliToERPSalesId.put(keyAliToErpSalesId, strCustomerERPSalesId);
            //ilib_LogEvent.message('@@@@ mapAliToERPSalesId' + mapAliToERPSalesId);
    
            setCustomerERP.add(strCustomerERPSalesId);
            setCustomerERPFromAgreement.add(ali.Customer_ERP_Number__c);
            
            getSetProductId(ali);
        }

        Map<Id, Product2> mapIdToProduct = new Map<Id,Product2>(new ProductsSelector().selectProducts(setProductId));
        ilib_LogEvent.info('mapIdToProduct :'+(!mapIdToProduct.isEmpty()? String.valueOf(mapIdToProduct.keySet()):MAPISEMPTY));//CMSI-90

        //Logic for getting Pricelist from Account sales area
        List<Account> lstAccounts = new AccountsSelector().selectAccountsForERPCustomerIds(setCustomerERPFromAgreement);
        ilib_LogEvent.info('lstAccounts ids :'+UtilsCollection.getSetOfIds(lstAccounts));//CMSI-90

        customerERPToAccount = new Map<String, Account>();
        if(!lstAccounts.isEmpty())
        {
            getCustomerERPToAccount(lstAccounts);
        }
        ilib_LogEvent.info('customerERPToAccount : '+ customerERPToAccount);//CMSI-90

        List<Account_Sales_Area__c> lstAccSalesArea = new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(setCustomerERP);
        ilib_LogEvent.info('lstAccSalesArea ids :'+UtilsCollection.getSetOfIds(lstAccSalesArea));//CMSI-90
        getMapAliToAccountSalesArea(lstAgreementLineItem,lstAccSalesArea);
           
        Set<String> priceListNames = new Set<String>();
        if(!lstAccSalesArea.isEmpty())
        {
            priceListNames = getPriceListNames(lstAccSalesArea,priceListNames);
            strpriceList = lstAccSalesArea.get(0).Price_List__c;
        }
        lstpli = new PriceListItemsSelector().selectByProductIdsAndPriceList(setProductId,priceListNames);
        ilib_LogEvent.info('~~~ Ids of PLI - '+ UtilsCollection.getSetOfIds(lstpli));//CMSI-90
        mapProductPricelist= new Map<String,Map<String,List<Apttus_Config2__PriceListItem__c>>>();
        for(Apttus_Config2__PriceListItem__c objPricelistItem :lstpli){
            if(!mapProductPricelist.containskey(objPricelistItem.Apttus_Config2__ProductId__c)){
                Map<String,List<Apttus_Config2__PriceListItem__c>> pricelistToItem=new Map<String,List<Apttus_Config2__PriceListItem__c>>();
                pricelistToItem.put(objPricelistItem.Apttus_Config2__PriceListId__r.Name,new List<Apttus_Config2__PriceListItem__c>{objPricelistItem});
                mapProductPricelist.put(objPricelistItem.Apttus_Config2__ProductId__c,pricelistToItem);
            }else{
                if(!mapProductPricelist.get(objPricelistItem.Apttus_Config2__ProductId__c).containskey(objPricelistItem.Apttus_Config2__PriceListId__r.Name))
                {
                    mapProductPricelist.get(objPricelistItem.Apttus_Config2__ProductId__c).put(objPricelistItem.Apttus_Config2__PriceListId__r.Name,new List<Apttus_Config2__PriceListItem__c>{objPricelistItem});

                }else {
                    mapProductPricelist.get(objPricelistItem.Apttus_Config2__ProductId__c).get(objPricelistItem.Apttus_Config2__PriceListId__r.Name).add(objPricelistItem);
                }
            }
        }
        
        for(Apttus__APTS_Agreement__c objAgreement:lstAgreement)
        {
            setAccountIds.add(objAgreement.Apttus__Account__c);//dcp-32046
            getSetAccountOwnerIds(objAgreement);
        }
        mapAgreementAccountForPriceGroup = new Map<Id,Account>(new AccountsSelector().selectAccounts(setAccountIds));
        
        ilib_LogEvent.info('mapAgreementAccountForPriceGroup :'+(!mapAgreementAccountForPriceGroup.isEmpty()? String.valueOf(mapAgreementAccountForPriceGroup.keySet()):MAPISEMPTY));//CMSI-90

        List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations = new ApprovalPriorityMetadataSelector().selectAllPriorityCombinations();
        ilib_LogEvent.info('lstPriorityCOmbinations'+lstPriorityCOmbinations);//CMSI-90
        
        ownerToApprovalHierarchy = getApprovalHierarchyByAccountOwner(setAccountOwnerIds); //map of account owner Id to Approval hierarchy
        
        idToAgreement  = new Map<Id,Apttus__APTS_Agreement__c>(new ApttusAgreementSelectors().selectAgreements(setAgreementId));
        ilib_LogEvent.info('idToAgreement :'+(!idToAgreement.isEmpty()? String.valueOf(idToAgreement.keySet()):MAPISEMPTY));//CMSI-90        
        calculateLineLevelApprovals(lstAgreementLineItem,customMatrixWrapper,mapIdToProduct,lstPriorityCOmbinations);    
        ilib_LogEvent.pop(); //CMSI-90
    }

    /*
    *@ Roopal
    * Method for calulating approval fields and updating Quotes and Line Items
    */
    public static void calculateLineLevelApprovals(List<Apttus__AgreementLineItem__c> lstAgreementLineItem,ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper,Map<Id, Product2> mapIdToProduct,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations)
    {
        //CMSI-90
        ilib_LogEvent.push(LOG_TITLE + '.calculateLineLevelApprovals()');
        ilib_LogEvent.info('lstAgreementLineItem ids :'+UtilsCollection.getSetOfIds(lstAgreementLineItem));
        ilib_LogEvent.info('customMatrixWrapper :'+customMatrixWrapper);
        ilib_LogEvent.info('mapIdToProduct :'+(!mapIdToProduct.isEmpty()? String.valueOf(mapIdToProduct.keySet()):MAPISEMPTY));
        ilib_LogEvent.info('lstPriorityCOmbinations :'+UtilsCollection.getSetOfIds(lstPriorityCOmbinations));
        
        for(Apttus__AgreementLineItem__c ali: lstAgreementLineItem)
            {
            String strApprovalCategory = '';
            Integer intApprovalLevelRecordOwner = null;
            String strApprovalStatus = null;
            Id idApprovalHierarchyDiscount = null;
            String strDistributionChannel =null;
            Boolean boolApprovalFoundMNRO = false;
            Boolean boolApprovalFoundMGRO = false;
            Boolean boolApprovalFoundDisRO = false;
            Integer intApprovalLevelMaterialNumCustom = null;
            Id idApprovalHierarchyMaterialNumCustom = null;
            Integer intApprovalLevelMaterialGroupCustom = null;
            Id idApprovalHierarchyMaterialGroupCustom = null;
            Integer intApprovalLevelDiscountCustom = null;
            Id idApprovalHierarchyDiscountCustom = null;
            ApprovalResult approvalResults = new ApprovalResult();
            strDistributionChannel = getDistributionChannel(ali);
            
            //Added bypass as part of TASK0540831
            if(ali.Discontinued__c != YES)
            {
                //Calculating discount from pricelist
                populateDiscount(ali,mapAliToAccountSalesArea,lstpli,mapAliAgreementIdToAgreement);
                
                approvalResults = calculateROApprovals(ali,customMatrixWrapper,idToAgreement,strDistributionChannel,mapCAMIdToSetProduct,mapIdToProduct,approvalResults,lstPriorityCOmbinations);
                strApprovalStatus = approvalResults.strApprovalStatus;
                strApprovalCategory = approvalResults.strApprovalCategory;
                idApprovalHierarchyDiscount = approvalResults.idApprovalHierarchyDiscount;
                intApprovalLevelRecordOwner = approvalResults.intApprovalLevelRecordOwner;
                boolApprovalFoundMNRO = approvalResults.boolApprovalFoundMNRO;
                boolApprovalFoundMGRO = approvalResults.boolApprovalFoundMGRO;
                boolApprovalFoundDisRO = approvalResults.boolApprovalFoundDisRO;
                ilib_LogEvent.message('resultROApprovals : ' + approvalResults);

                approvalResults = calculateCustomApprovals(ali,customMatrixWrapper,idToAgreement,strDistributionChannel,mapCAMIdToSetProduct,mapIdToProduct,boolApprovalFoundMNRO,boolApprovalFoundMGRO,boolApprovalFoundDisRO,strApprovalCategory,approvalResults,lstPriorityCOmbinations);
                strApprovalCategory = approvalResults.strApprovalCategory;
                intApprovalLevelMaterialGroupCustom = approvalResults.intApprovalLevelMaterialGroupCustom;
                intApprovalLevelMaterialNumCustom = approvalResults.intApprovalLevelMaterialNumCustom;
                intApprovalLevelDiscountCustom = approvalResults.intApprovalLevelDiscountCustom;
                idApprovalHierarchyDiscountCustom = approvalResults.idApprovalHierarchyDiscountCustom;
                idApprovalHierarchyMaterialGroupCustom = approvalResults.idApprovalHierarchyMaterialGroupCustom;
                idApprovalHierarchyMaterialNumCustom = approvalResults.idApprovalHierarchyMaterialNumCustom;
                ilib_LogEvent.message('resultCustomApproval' + approvalResults);

                //DCP-49431
                approvalResults = calculateMFNApprovals(ali, idToAgreement,approvalResults);
                strApprovalCategory = approvalResults.strApprovalCategory;
                strApprovalStatus = approvalResults.strApprovalStatus;
            }

            ali.Approval_Level_Discount__c = intApprovalLevelDiscountCustom;
            ali.Approval_Level_Material_Group__c = intApprovalLevelMaterialGroupCustom;
            ali.Approval_Level_Material_Number__c = intApprovalLevelMaterialNumCustom; 
            ali.Approval_Hierarchy_Discount__c = idApprovalHierarchyDiscountCustom;
            ali.Approval_Hierarchy_Material_Group__c = idApprovalHierarchyMaterialGroupCustom;
            ali.Approval_Hierarchy_Material_Number__c = idApprovalHierarchyMaterialNumCustom;
            ali.Approval_Hierarchy_Record_Owner__c = idApprovalHierarchyDiscount;
            ali.Approval_Level_RO_Discount__c = intApprovalLevelRecordOwner;
            ali.Approval_Category__c = strApprovalCategory;
            ali.Apttus_Approval__Approval_Status__c = strApprovalStatus;
            // DCP-49431
            ali.is_MFN_Line_Item__c = approvalResults.mfnLineItem;
            ilib_LogEvent.message('updated ali'+ ali);
            
            mapAgreementHierarchyDiscount=getMapAgreementHierarchyDiscount(ali,mapAgreementHierarchyDiscount);
            setAgreementToUpdate = getsetAgreementToRevert(ali,setAgreementToUpdate);
            ilib_LogEvent.message('@@@ UpdateAgreement_RevertAgreement -'+setAgreementToUpdate+'_'+setAgreementToRevert);

            setAllAgreementIds.add(ali.Apttus__AgreementId__c);
        }
        ilib_LogEvent.message('^^^ setAgreementIdsWithHierarchyError_setAgreementIdsWithMatrixError ' + setAgreementIdsWithHierarchyError+'_'+setAgreementIdsWithMatrixError);

        updateAgreement(setAgreementToUpdate,setAgreementToRevert,setAllAgreementIds,setAgreementIdsWithHierarchyError,setAgreementIdsWithMatrixError, lstAgreementLineItem,mapAgreementHierarchyDiscount); 
        ilib_LogEvent.pop();//CMSI-90

    }   

    /*
    *@ Roopal
    * Method for getting account based on price group
    */
    private static Account getAccountForPriceGroup(Apttus__AgreementLineItem__c ali, Apttus__APTS_Agreement__c objAgreement)
    {
        Account objAccount = NULL;
        //Apttus__APTS_Agreement__c objAgreement = idToAgreement.get(ali.Apttus__AgreementId__c);
        if(ApttusAgreementLineItems.lineTypeForApprovals.contains(ali.Line_Type__c) || ApttusAgreementLineItems.lineTypeForApprovals.contains(ali.Line_Type_1__c))
        {
            if(mapAgreementAccountForPriceGroup.containskey(objAgreement.Apttus__Account__c))
                objAccount = mapAgreementAccountForPriceGroup.get(objAgreement.Apttus__Account__c);
        }
        else
        {
            if(customerERPToAccount.containskey(ali.Customer_ERP_Number__c))
                objAccount = customerERPToAccount.get(ali.Customer_ERP_Number__c);
        }
        ilib_LogEvent.message('objAccount :'+objAccount);//CMSI-90
        return objAccount;
    }

    /*
    *@ Roopal
    *Method of calculating discount % from discount amount 
    */
    private static Decimal calculateDiscount(Apttus__AgreementLineItem__c ali,Map<String,Account_Sales_Area__c> mapAliToAccountSalesArea, List<Apttus_Config2__PriceListItem__c> lstPLI, Id productId,Map<Id,Apttus__APTS_Agreement__c> mapAliAgreementIdToAgreement)
    {
        Decimal discountResult = null;                    
        String strCustomerERPSalesId = generateStrCustomerErpID(ali,mapAliAgreementIdToAgreement);
        String keyAliToErpSalesId=String.valueOf(ali.Line_Type__c) + String.valueOf(ali.Discount_Type__c) + String.valueOf(ali.RecordTypeId) + strCustomerERPSalesId;
        ilib_LogEvent.message('@@@@ mapAliToAccountSalesArea key exist :'+mapAliToAccountSalesArea.containsKey(KeyAliToErpSalesId)+mapAliToAccountSalesArea.get(keyAliToErpSalesId));
        ilib_LogEvent.message('calculateDiscount check conditions productId '+productId);
        ilib_LogEvent.message('calculateDiscount check conditions  ALI '+ali);
        if(!mapAliToAccountSalesArea.containsKey(keyAliToErpSalesId)){
            return discountResult;
        }
        ilib_LogEvent.message('lstPLI ids :'+UtilsCollection.getSetOfIds(lstPLI));//CMSI-90
        if(!lstPLI.IsEmpty())
        {
            Apttus_Config2__PriceListItem__c objpli=getPriceListItem(productId,keyAliToErpSalesId,ali);
            if(objpli==null){
                return discountResult;
            }
            if(objpli.Apttus_Config2__ListPrice__c == 0
            &&!isDiscountypePercentage){
                listPriceZero = true;
                ali.addError(System.Label.UI_Error_AgreementLineItem_ListPriceZero.replace('Material Number(s)',ali.Material_Number__c));
            }
            else{
                if( ali.Discount_Type__c ==  System.Label.AliDiscountTypeAmount)
                {
                    discountResult = ((ali.Discount__c/objpli.Apttus_Config2__ListPrice__c) * 100).setscale(2);
                    ali.Discount_Amount__c = (ali.Discount__c).setscale(2);
                    ali.Customer_Price__c = (objpli.Apttus_Config2__ListPrice__c - ali.Discount_Amount__c).setscale(2);              
                }
                else if( ali.Discount_Type__c == System.Label.AliDiscountTypeFixedPrice )
                {                
                    discountResult = (((objpli.Apttus_Config2__ListPrice__c - ali.Discount__c)/objpli.Apttus_Config2__ListPrice__c) * 100).setscale(2);
                    ali.Discount_Amount__c = (objpli.Apttus_Config2__ListPrice__c - ali.Discount__c).setscale(2);
                    ali.Customer_Price__c = (ali.Discount__c).setscale(2);                   
                }
                else
                {                
                    discountResult = ali.Discount__c;
                    ali.Discount_Amount__c = ((ali.Discount__c * objpli.Apttus_Config2__ListPrice__c)/100).setscale(2);
                    ali.Customer_Price__c = (objpli.Apttus_Config2__ListPrice__c - ali.Discount_Amount__c).setscale(2);   
                }
                ali.Apttus__ListPrice__c = (objpli.Apttus_Config2__ListPrice__c).setscale(2); 
            }

        }
           
        ilib_LogEvent.message('@@@@@ Value of Discount result - ' + discountResult);
        return discountResult;
    }

    /*
    *@ Roopal
    *Method for generating custom ERP ID
    */
    private static String generateStrCustomerErpID(Apttus__AgreementLineItem__c agreementLineItem, Map<Id,Apttus__APTS_Agreement__c> mapAliAgreementIdToAgreement)
    {
        String strCustomerERPSalesId = null;
        if(ApttusAgreementLineItems.lineTypeForApprovals.contains(agreementLineItem.Line_Type__c) || ApttusAgreementLineItems.lineTypeForApprovals.contains(agreementLineItem.Line_Type_1__c) && mapAliAgreementIdToAgreement.containskey(agreementLineItem.Apttus__AgreementId__c)) 
        {
            ilib_LogEvent.message('Map contains Agreement Id for Price Group Check ');
            strCustomerERPSalesId =  mapAliAgreementIdToAgreement.get(agreementLineItem.Apttus__AgreementId__c).Account_ERP_Number__c +'_' + agreementLineItem.Sales_Org__c + agreementLineItem.Distribution_Channel__c + System.Label.AccountSalesAreaDivision; // (00 to be put in label - division value)
        }
        else
        {
            strCustomerERPSalesId = agreementLineItem.Customer_ERP_Number__c +'_' + agreementLineItem.Sales_Org__c + agreementLineItem.Distribution_Channel__c + System.Label.AccountSalesAreaDivision; // (00 to be put in label - division value)
        }
        ilib_LogEvent.message('strCustomerERPSalesId :'+strCustomerERPSalesId);//CMSI-90
        return strCustomerERPSalesId;
    }

    /*
    *@ Roopal
    *Method to get Approval hierarchy records where first approver is account owner
    */
    private static Map<id, Approval_Hierarchy__c> getApprovalHierarchyByAccountOwner(Set<Id> setAccountOwnerIds){
        ilib_LogEvent.push(LOG_TITLE + '.getApprovalHierarchyByAccountOwner()');//CMSI-90
        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = new Map<id, Approval_Hierarchy__c>();
        if (setAccountOwnerIds.size()>0){
            List<Approval_Hierarchy__c> lstApprovalHierarchy = new ApprovalHierarchiesSelector().selectByAccountOwner(ApprovalCategory.CLM_SALES_HIERARCHY.name(), setAccountOwnerIds);
            for(Approval_Hierarchy__c objApprovalHierarchy: lstApprovalHierarchy){
                ownerToApporovalHierarchy.put(objApprovalHierarchy.Approver_Level_1__c, objApprovalHierarchy);
            }
        }
        //CMSI-90
        ilib_LogEvent.info('ownerToApporovalHierarchy :'+(!ownerToApporovalHierarchy.isEmpty()? String.valueOf(ownerToApporovalHierarchy.keySet()):MAPISEMPTY));
        ilib_LogEvent.pop();  
        return ownerToApporovalHierarchy;
    }

    /*
    *@ Roopal
    *Wrapper Method for storing custom approval matrix result
    */
    public class CustomApprovalMatrixResult {
        Integer intApprovalLevel;
        Custom_Approval_Matrix__c soApprovalMatrix;
        Id idOwner;
        boolean booldiscountlessthanLevel1;
    }

    /*
    *@ Roopal
    *Wrapper Method for storing priority information
    */
    public class PriorityResult {
        Integer intPriority;
        Custom_Approval_Matrix__c soApprovalMatrix;
        Datetime lastModifiedDate;
        boolean boolApprovalMatrixFound;
    }

    /*
    *@ Roopal
    *Wrapper Method for storing Approval parameters
    */
    public class ApprovalResult {
        Set<Id> setAgreementIdsWithHierarchyError;
        String strApprovalStatus;
        String strApprovalCategory;
        Set<Id> setAgreementIdsWithMatrixError;
        Boolean boolApprovalFoundMNRO;
        Boolean boolApprovalFoundMGRO;
        Id idApprovalHierarchyDiscount;
        Integer intApprovalLevelRecordOwner;
        Boolean boolApprovalFoundMNCust;
        Boolean boolApprovalFoundMGCust;
        Set<Id> setAgreementToRevert;
        Boolean boolApprovalFoundDisRO;
        Id idApprovalHierarchyCustom;
        Integer intApprovalLevelCustom;
        Set<Id> setAgreementToUpdate;
        Set<Id> setAllAgreementIds;
        Map<Id,Id> mapAgreementHierarchyDiscount;
        Integer intApprovalLevelDiscountCustom;
        Integer intApprovalLevelMaterialGroupCustom;
        Integer intApprovalLevelMaterialNumCustom; 
        Id idApprovalHierarchyDiscountCustom;
        Id idApprovalHierarchyMaterialGroupCustom;
        Id idApprovalHierarchyMaterialNumCustom;
        Boolean mfnLineItem; // DCP-49431

        /**
         * @Roopal
         * Wrapper for storing approval variables
         */
        public ApprovalResult(){
            setAgreementIdsWithHierarchyError = null;
            strApprovalStatus = '';
            strApprovalCategory = '';
            setAgreementIdsWithMatrixError = null;
            boolApprovalFoundMNRO = false;
            boolApprovalFoundMGRO = false;
            idApprovalHierarchyDiscount = null;
            intApprovalLevelRecordOwner = null;
            boolApprovalFoundMNCust = false;
            boolApprovalFoundMGCust = false;
            setAgreementToRevert = null;
            boolApprovalFoundDisRO = false;
            idApprovalHierarchyCustom = null;
            intApprovalLevelCustom = null;
            setAgreementToUpdate = null;
            setAllAgreementIds = null;
            mapAgreementHierarchyDiscount = null;
            intApprovalLevelDiscountCustom = null;
            intApprovalLevelMaterialGroupCustom = null;
            intApprovalLevelMaterialNumCustom = null; 
            idApprovalHierarchyDiscountCustom = null;
            idApprovalHierarchyMaterialGroupCustom = null;
            idApprovalHierarchyMaterialNumCustom = null;
            mfnLineItem = false; //DCP-49431
        }
    }

    /*
    *@ Roopal
    *Wrapper Method for storing custom approval matrix records in respective Lists/Maps
    */
    private static ApttusProposalLineItems.CustomApprovalMatrixWrapper getCustomApprovalMatrixWrapper(List<Custom_Approval_Matrix__c> lstCustomApprovalMatrix)
    {
        ilib_LogEvent.push(LOG_TITLE + '.getCustomApprovalMatrixWrapper()');//CMSI-90
        ApttusProposalLineItems.CustomApprovalMatrixWrapper objcustomMatrixWrapper = new ApttusProposalLineItems.CustomApprovalMatrixWrapper();
        for (Custom_Approval_Matrix__c objCam : lstCustomApprovalMatrix)
        {  
            objcustomMatrixWrapper.mapIdtoCAM.put(objCam.id,objCam);
            if(objCam.Approval_Hierarchy_Type__c != null)
            {
                List<String> lstAppHierarchyTypes = new List<String>();
                lstAppHierarchyTypes = objCam.Approval_Hierarchy_Type__c.split(';');
                if(objCam.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixMaterialNumber && lstAppHierarchyTypes.contains(HIERARCHY_RECORD_OWNER)) 
                {
                    objcustomMatrixWrapper.lstMatrixMaterialNumberRO.add(objCam);
                    objcustomMatrixWrapper.setMaterialNumberMatrixIds.add(objCam.Id);
                } 
                else if(objCam.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixMaterialGroup && lstAppHierarchyTypes.contains(HIERARCHY_RECORD_OWNER))
                {
                    getMapMaterialGroup(objCam,objcustomMatrixWrapper.mapMatrixtoMaterialGroupRO);
                }
                else if(objCam.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixDiscount && lstAppHierarchyTypes.contains(HIERARCHY_RECORD_OWNER))
                {
                    objcustomMatrixWrapper.lstMatrixDiscountRO.add(objCam);
                } 
                if(objCam.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixMaterialGroup && lstAppHierarchyTypes.contains(HIERARCHY_CUSTOM))
                {
                    getMapMaterialGroup(objCam,objcustomMatrixWrapper.mapMatrixtoMaterialGroupCustom);

                } 
                if(objCam.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixMaterialNumber && lstAppHierarchyTypes.contains(HIERARCHY_CUSTOM))
                {
                    objcustomMatrixWrapper.lstMatrixMaterialNumberCustom.add(objCam);
                    objcustomMatrixWrapper.setMaterialNumberMatrixIds.add(objCam.Id);
                } 
                if(objCam.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixDiscount && lstAppHierarchyTypes.contains(HIERARCHY_CUSTOM))
                {
                    objcustomMatrixWrapper.lstMatrixDiscountCustom.add(objCam);
                }
            }
        }
        //CMSI-90
        ilib_LogEvent.info('objcustomMatrixWrapper :'+objcustomMatrixWrapper);
        ilib_LogEvent.pop();  
        return objcustomMatrixWrapper;
    }

    /*
    *@ Roopal
    *Method for calculating the eligible custom approval matrix
    */
    private static CustomApprovalMatrixResult getApprovalMatrix( Apttus__AgreementLineItem__c ali, String strDistributionChannel,  List<Custom_Approval_Matrix__c> lstApprovalMatrix, Account objacc,Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSet,String strApprovalType,Map<Id, Product2> mapIdToProduct,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations){
        Integer intApprovalLevel = null;       
        Custom_Approval_Matrix__c objApprovalMatrix = null; 
        boolean booldiscountlessthanLevel1 = false;
        Decimal discount =  ali.Discount_In_Percent__c;
        Integer intPriority = null;
        Datetime lastModifiedDate = null;
        Id idOwner = null;

        if(objacc!=null)
        {
            idOwner = objacc.OwnerId;
        }
        ilib_LogEvent.message('discount++'+discount);
        if (discount!=null){
            for (Custom_Approval_Matrix__c objMatrix : lstApprovalMatrix){
                ilib_LogEvent.message('objMatrix++'+objMatrix);
                Integer intPriorityNew = null;
                Datetime lastModifiedDateNew = null;
                boolean boolApprovalMatrixFound = false;
                List<String> lstAppHierarchyTypes = new List<String>();
                lstAppHierarchyTypes = objMatrix.Approval_Hierarchy_Type__c.split(';');
                if(mapCAMIdToSet!=null && !mapCAMIdToSet.isEmpty() && mapCAMIdToSet.containsKey(objMatrix)){
                    Set<String> setValues = mapCAMIdToSet.get(objMatrix);
                    List<String> lstValues = new List<String>();
                    lstValues = getSetValues(setValues);
                    ilib_LogEvent.message('$$ setValues'+setValues);
                 if(strApprovalType == APPROVAL_TYPE_MATNUM && lstValues.contains(ali.Material_Number__c)){
                        intPriorityNew = getPriority(ali,strDistributionChannel,objMatrix,objacc,lstPriorityCOmbinations);
                        lastModifiedDateNew = objMatrix.LastModifiedDate;
                        ilib_LogEvent.message('$$ intPriorityNew'+intPriorityNew);
                        ilib_LogEvent.message('$$ lastModifiedDateNew'+lastModifiedDateNew);
                    }else if(strApprovalType == APPROVAL_TYPE_MATGRP && (ali.Apttus__ProductId__c !=null && lstValues.contains(mapIdToProduct.get(ali.Apttus__ProductId__c).Material_Group_1_Code__c)) || ((ali.Material_Group_1__c != null && lstValues.contains(ali.Material_Group_1__c)))){
                        intPriorityNew = getPriority(ali,strDistributionChannel,objMatrix,objacc,lstPriorityCOmbinations);
                        lastModifiedDateNew = objMatrix.LastModifiedDate;
                        ilib_LogEvent.message('$$ intPriorityNewMG'+intPriorityNew);
                        ilib_LogEvent.message('$$ lastModifiedDateNewMG'+lastModifiedDateNew);
                    }
                }else if(mapCAMIdToSet == null && strApprovalType == APPROVAL_TYPE_DISCOUNT){
                    intPriorityNew = getPriority(ali,strDistributionChannel,objMatrix,objacc,lstPriorityCOmbinations);
                    lastModifiedDateNew = objMatrix.LastModifiedDate;
                    ilib_LogEvent.message('$$ intPriorityNewDis'+intPriorityNew);
                    ilib_LogEvent.message('$$ lastModifiedDateNewDis'+lastModifiedDateNew);
                }
                PriorityResult priorityResults = getPriorityResult(intPriorityNew,lastModifiedDateNew,objMatrix,intPriority,lastModifiedDate,objApprovalMatrix);
                intPriority = priorityResults.intPriority;
                objApprovalMatrix = priorityResults.soApprovalMatrix;
                lastModifiedDate = priorityResults.lastModifiedDate;
                boolApprovalMatrixFound = priorityResults.boolApprovalMatrixFound;
                ilib_LogEvent.message('$$ boolApprovalMatrixFound'+boolApprovalMatrixFound);
                if(boolApprovalMatrixFound == true){
                    CustomApprovalMatrixResult calculatedResult = getCustomApprovalMatrixResult(objApprovalMatrix,discount,lstAppHierarchyTypes);
                    objApprovalMatrix = calculatedResult.soApprovalMatrix;
                    intApprovalLevel = calculatedResult.intApprovalLevel;
                    booldiscountlessthanLevel1 = calculatedResult.booldiscountlessthanLevel1;
                }

            }

        }

        CustomApprovalMatrixResult result = new CustomApprovalMatrixResult();
        result.intApprovalLevel = intApprovalLevel;
        result.soApprovalMatrix = objApprovalMatrix;
        result.idOwner = idOwner;
        result.booldiscountlessthanLevel1 = booldiscountlessthanLevel1;
        ilib_LogEvent.message('$$ result'+result);
        return result;

    }

    /*
    *@ Roopal
    *Method for getting priority for custom approval matrix
    */
    private static Integer getPriority( Apttus__AgreementLineItem__c ali, String strDistributionChannel, Custom_Approval_Matrix__c objMatrix, Account objacc,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations)
    {        
        String strAccRegion = '';
        String strAccCountry = '';
        String strRegion = objMatrix.Region__c;
        String strDistChannel = objMatrix.Distribution_Channel__c;
        String strSalesOrg = objMatrix.Sales_Organization__c;
        String strCountry = objMatrix.Country__c;
        String strCurrency = objMatrix.Currency__c;
        Integer intPriority = null;

        ilib_LogEvent.message('$$ strfirlds '+strRegion+'_'+strDistChannel+'_'+strSalesOrg+'_'+strCountry+'_'+strCurrency);

        if(objacc != null)
        {
            ilib_LogEvent.message('~~~ OBJ ACC - '+ objacc);
            strAccRegion = objacc.Territory_Region__c;
            strAccCountry = objacc.BillingCountryCode;
        }
        boolean boolSalesOrgBlank = String.isBlank(strSalesOrg);
        boolean boolRegionBlank = String.isBlank(strRegion) ;
        boolean boolDistChannelBlank = String.isBlank(strDistChannel);
        boolean boolCountryBlank = String.isBlank(strCountry);
        boolean boolCurrencyBlank = String.isBlank(strCurrency);
        boolean boolSalesOrg = (String.isBlank(strSalesOrg) ? false :strSalesOrg.contains(ali.Sales_Org__c));
        boolean boolRegionCheck = (!String.isBlank(strRegion) && !String.isBlank(strAccRegion) ? strRegion.contains(strAccRegion) :false);  
        
        boolean boolCountryConditionCheck = (String.isBlank(strCountry) ? false :strCountry.contains(strAccCountry));
        boolean boolDistributionChannelCheck = (String.isBlank(strDistChannel) ? false :strDistChannel.contains(strDistributionChannel));
        boolean boolCurrencyCheck = (String.isBlank(strCurrency) ? false :strCurrency.contains(ali.CurrencyIsoCode));

        String strCondition = boolSalesOrg+'_'+boolRegionCheck+'_'+boolCountryConditionCheck+'_'+boolDistributionChannelCheck+'_'+boolCurrencyCheck+'_'+boolSalesOrgBlank+'_'+boolRegionBlank+'_'+boolDistChannelBlank+'_'+boolCountryBlank+'_'+boolCurrencyBlank;
        ilib_LogEvent.message('strCondition'+strCondition);

        for(Approval_Priority_Combination__mdt objpriority :lstPriorityCOmbinations){
            String strMetaCond = objpriority.Sales_Org_Check__c+'_'+objpriority.Region_Check__c+'_'+objpriority.Country_Check__c+'_'+objpriority.Distribution_Channel_Check__c+'_'+objpriority.Currency_Check__c+'_'+objpriority.Sales_Org_Blank__c+'_'+objpriority.Region_Blank__c+'_'+objpriority.Distribution_Channel_Blank__c+'_'+objpriority.Country_Blank__c+'_'+objpriority.Currency_Blank__c;
            if(strCondition == strMetaCond)
            intPriority = Integer.valueOf(objpriority.Value__c);
        }
        ilib_LogEvent.message('intPriority :'+intPriority);//CMSI-90
        return intPriority;
    }
    private static void updateAgreement(Set<Id> updateAgreementIds, Set<Id> revertAgreementIds, set<Id> allAgreementIds, Set<Id> setAgreementIdsWithHierarchyError, Set<Id> setAgreementIdsWithMatrixError, List<Apttus__AgreementLineItem__c> listALI, Map<Id,Id> mapAgreementHierarchyDiscount)
    {
        ilib_LogEvent.push(LOG_TITLE + '.updateAgreement()');//CMSI-90
    //set<Id> setAgreementId = new set<Id>(agreementId);

        List<Apttus__AgreementLineItem__c> lstAgreementLineItem = new  ApttusAgreementLineItemSelectors().selectByAgreementId(allAgreementIds);
		Integer allAgreementLineItemsSize = lstAgreementLineItem.size();
        
        if( !setUpdatedLineItems.isEmpty() && (setUpdatedLineItems.size() == allAgreementLineItemsSize))
        {
            for(Apttus__AgreementLineItem__c ali: listALI)
            {
                if(ali.Approval_Category__c != null && ali.Approval_Category__c != '' 
                && ali.Apttus_Approval__Approval_Status__c == System.Label.AgreementApprovalStatusApprovalRequired 
                && !updateAgreementIds.contains(ali.Apttus__AgreementId__c))
                    updateAgreementIds.add(ali.Apttus__AgreementId__c);
                else
                    revertAgreementIds.add(ali.Apttus__AgreementId__c);

            }
        }
		//INC0309188 - Checking for only existing line items
        else if(allAgreementLineItemsSize > 0)
        {    
            for(Apttus__AgreementLineItem__c ali: lstAgreementLineItem)
            {				
				if(setUpdatedLineItems.isEmpty() || !setUpdatedLineItems.contains(ali.Id)){
					if(ali.Approval_Category__c!=null && ali.Approval_Category__c!='' 
					&& (ali.Apttus_Approval__Approval_Status__c == System.Label.AgreementApprovalStatusApprovalRequired
						|| ali.Apttus_Approval__Approval_Status__c == System.Label.AgreementApprovalStatusRejected
						|| ali.Apttus_Approval__Approval_Status__c == System.Label.AgreementApprovalStatusCancelled) 
					&& !updateAgreementIds.contains(ali.Apttus__AgreementId__c))
						updateAgreementIds.add(ali.Apttus__AgreementId__c);
					else
						revertAgreementIds.add(ali.Apttus__AgreementId__c);
			
				}
            }  
        }
		
        ilib_LogEvent.message('&&& Update Agreement Set '+updateAgreementIds);
        ilib_LogEvent.message('&&& Auto Approve Agreement Set '+ revertAgreementIds);

        
        List<Apttus__APTS_Agreement__c> lstAgreement = new  ApttusAgreementSelectors().selectAgreements(allAgreementIds);
        if(!lstAgreement.isEmpty())
        {
            Map<Id, RecordTypeInfo> agreementRecordTypeinfo = Apttus__APTS_Agreement__c.sObjectType.getDescribe().getRecordTypeInfosById();

            for( Apttus__APTS_Agreement__c objAgreement:lstAgreement)
            {
                boolean boolApprovalMatrixNotFound = false;
                boolean boolAprovalHierarchyNotFound = false;
                boolean boolIsAutoApproved = false;

                String rTName = null;
                if(agreementRecordTypeinfo.containsKey(objAgreement.RecordTypeId)) {
                    rtName = agreementRecordTypeinfo.get(objAgreement.RecordTypeId).getDeveloperName();
                }

                if(updateAgreementIds.contains(objAgreement.Id) && (objAgreement.Apttus_Approval__Approval_Status__c != System.Label.AgreementApprovalStatusPendingApproval) && (!setAgreementIdsWithMatrixError.contains(objAgreement.Id) && !setAgreementIdsWithHierarchyError.contains(objAgreement.Id)))
                {
                    objAgreement.Apttus_Approval__Approval_Status__c = System.Label.AgreementApprovalStatusApprovalRequired;
                }
                //CMCM-7846 Defect CMCM-11370 Include Special Programs to the list to byPass auto approval when category has a value
                if(revertAgreementIds.contains(objAgreement.Id) && !(updateAgreementIds.contains(objAgreement.Id)) 
                && (!setAgreementIdsWithMatrixError.contains(objAgreement.Id) && !setAgreementIdsWithHierarchyError.contains(objAgreement.Id)) 
                && ((rtName!= Label.AgreementRecordTypeChannelPartner && rtName!=Label.AgreementRecordTypeMasterService && rtName!=Label.AgreementRecordTypeStandingQuote && rtName!=Label.AgreementRecordTypeTender && rtName!=Label.AgreementRecordTypeSpecialPrograms) 
                || ((rtName==Label.AgreementRecordTypeChannelPartner || rtNAme==Label.AgreementRecordTypeMasterService || rtName==Label.AgreementRecordTypeStandingQuote || rtName==Label.AgreementRecordTypeTender || rtName==Label.AgreementRecordTypeSpecialPrograms) 
                &&  (objAgreement.Approval_Category__c==''|| objAgreement.Approval_Category__c==null))))//DCP-49596
                {
                    objAgreement.Apttus_Approval__Approval_Status__c = System.Label.AgreementApprovalStatusApproved;
                    boolIsAutoApproved = true;
                }
                if(updateAgreementIds.contains(objAgreement.Id) && !setAgreementIdsWithMatrixError.contains(objAgreement.Id) 
                && setAgreementIdsWithHierarchyError.contains(objAgreement.Id))
                {
                    boolAprovalHierarchyNotFound =true;
                    objAgreement.Apttus_Approval__Approval_Status__c = System.Label.AgreementApprovalStatusApprovalRequired;
                }
                if(!setAgreementIdsWithMatrixError.contains(objAgreement.Id) && setAgreementIdsWithHierarchyError.contains(objAgreement.Id))
                {
                    boolAprovalHierarchyNotFound =true;
                }
                if(setAgreementIdsWithMatrixError.contains(objAgreement.Id) )
                {
                    boolApprovalMatrixNotFound =true;
                }
                objAgreement.Approval_Matrix_Not_Found__c =boolApprovalMatrixNotFound ;
                objAgreement.Approval_Hierarchy_Not_Found__c = boolAprovalHierarchyNotFound;
                objAgreement.Is_Auto_Approved__c = boolIsAutoApproved;
                if(mapAgreementHierarchyDiscount.containsKey(objAgreement.Id))
                    objAgreement.Approval_Hierarchy_Discount__c=mapAgreementHierarchyDiscount.get(objAgreement.Id);
            }
        }
        ilib_LogEvent.message('lstAgreement ids :'+UtilsCollection.getSetOfIds(lstAgreement));//CMSI-90
        update lstAgreement;
        ilib_LogEvent.pop();//CMSI-90
    }  

    /*
    * @Roopal
    * Get list of agreements when there are no custom approval matrix in system
    */
    private static Set<Apttus__APTS_Agreement__c> updateAgreementWhenNoCAM (List<Apttus__AgreementLineItem__c> lstAgreementLineItem,Set<Apttus__APTS_Agreement__c> setObjAgree){
        ilib_LogEvent.push(LOG_TITLE + '.updateAgreementWhenNoCAM()');//CMSI-90
        for(Apttus__AgreementLineItem__c objALI : lstAgreementLineItem){
            Apttus__APTS_Agreement__c objAgree = new Apttus__APTS_Agreement__c(); 
            if(mapAliAgreementIdToAgreement.containskey(objALI.Apttus__AgreementId__c)){
                objAgree = mapAliAgreementIdToAgreement.get(objALI.Apttus__AgreementId__c);
                objAgree.Approval_Matrix_Not_Found__c = true;
                setObjAgree.add(objAgree);
            }
        }
        //CMSI-90
        ilib_LogEvent.info('setObjAgree ids :'+setObjAgree);
        ilib_LogEvent.pop();  
        return setObjAgree;
    }

    /*
    * @Roopal
    * Get Map of Agreement Line Item to Account Sales Area
    */
    private static void getMapAliToAccountSalesArea (List<Apttus__AgreementLineItem__c> lstAgreementLineItem,List<Account_Sales_Area__c> lstAccSalesArea){
        ilib_LogEvent.push(LOG_TITLE + '.getMapAliToAccountSalesArea()');//CMSI-90
        for(Apttus__AgreementLineItem__c ali : lstAgreementLineItem)
            {   String strCustomerERPSalesIdForAli=generateStrCustomerErpID(ali,mapAliAgreementIdToAgreement);
                String keyAliToErpSalesId=String.valueOf(ali.Line_Type__c)+String.valueOf(ali.Discount_Type__c)+String.valueOf(ali.RecordTypeId)+strCustomerERPSalesIdForAli;
                if(mapAliToERPSalesId.containskey(keyAliToErpSalesId))
                {
                    for( Account_Sales_Area__c oAccSalesArea:lstAccSalesArea)
                    {   
                        if(oAccSalesArea.ERP_Account_Sales_Area_Id__c == mapAliToERPSalesId.get(keyAliToErpSalesId))
                            mapAliToAccountSalesArea.put(keyAliToErpSalesId,oAccSalesArea);
                    
                    }
                }
            }
        ilib_LogEvent.pop(); //CMSI-90
    }

    /*
    * @Roopal
    * Get Set of account Owners
    */
    private static void getSetAccountOwnerIds (Apttus__APTS_Agreement__c objAgreement){
        if(!setAccountOwnerIds.contains(objAgreement.Apttus__Account__r.OwnerId))
        {
            setAccountOwnerIds.add(objAgreement.Apttus__Account__r.OwnerId);
        }
    }

    /*
    * @Roopal
    * Get Set of price list names
    */
    private static Set<String> getPriceListNames (List<Account_Sales_Area__c> lstAccSalesArea,Set<String> priceListNames){
        ilib_LogEvent.push(LOG_TITLE + '.getPriceListNames()');//CMSI-90
        for( Account_Sales_Area__c oAccSalesArea:lstAccSalesArea)
        {
            priceListNames.add(oAccSalesArea.Price_List__c);
        }
        ilib_LogEvent.info('priceListNames :'+priceListNames);//CMSI-90
        ilib_LogEvent.pop();//CMSI-90
        return priceListNames;
    }

    /*
    * @Roopal
    * Get Map of Customer ERP Id To Account
    */
    private static void getCustomerERPToAccount (List<Account> lstAccounts){
        ilib_LogEvent.push(LOG_TITLE + '.getCustomerERPToAccount()');//CMSI-90
        for(Account objAcc : lstAccounts)
            {
                customerERPToAccount.put(objacc.ERP_Customer_Id__c,objacc);
            }
        ilib_LogEvent.pop();//CMSI-90
    }  
    
    /*
    * @Roopal
    * Get Set of Product Id
    */
    private static void getSetProductId (Apttus__AgreementLineItem__c ali){
        if(ali.Apttus__ProductId__c != null) 
            setProductId.add(ali.Apttus__ProductId__c);
    }

    /*
    * @Roopal
    * Get Distribution Channel
    */
    private static String getDistributionChannel (Apttus__AgreementLineItem__c ali){
        String strDistributionChannel = '';
        if(ali.Distribution_Channel__c!=null)
            {
                if(ali.Distribution_Channel__c == System.Label.AgreementLineItemDistributionChannelIndirect)
                    strDistributionChannel = System.Label.DistributionChannelIndirect;
                else 
                    {
                        if(ali.Distribution_Channel__c == System.Label.AgreementLineItemDistributionChannelDirect)
                            strDistributionChannel = System.Label.DistributionChannelDirect;
                    }
            }
            ilib_LogEvent.message('strDistributionChannel :'+strDistributionChannel);//CMSI-90
            return strDistributionChannel;
    }

    /*
    * @Roopal
    * Calculating discount from pricelist
    */
    public static void populateDiscount (Apttus__AgreementLineItem__c ali,Map<String,Account_Sales_Area__c> mapAliToAccountSalesArea, List<Apttus_Config2__PriceListItem__c> lstPLI,Map<Id,Apttus__APTS_Agreement__c> mapAliAgreementIdToAgreement){
        listPriceZero = false;
        isDiscountypePercentage = ali.Discount_Type__c==System.Label.AliDiscountTypePercent;
        if(ali.Discount__c!=null)
            {   
                Decimal discountResult = calculateDiscount(ali,mapAliToAccountSalesArea,lstpli, ali.Apttus__ProductId__c,mapAliAgreementIdToAgreement);
                if(discountResult == null)
                {
					ali.Discount_In_Percent__c = ali.Discount__c;
                    if(ali.Apttus__ProductId__c != null && !listPriceZero&&!isDiscountypePercentage)
                        ali.addError(System.Label.UI_Error_AgreementLineItem_NoActivePriceListFound.replace('Material Number(s)',ali.Material_Number__c));
                    else if(isDiscountypePercentage&& ali.Discount__c > 100){
                        ali.addError(System.Label.UI_Error_AgreementLineItem_DiscountMoreThan100Percent);
                    }
                }else{
                    if(discountResult <= HUNDRED){
                        ali.Discount_In_Percent__c = discountResult;
                    }else{
                        ali.addError(System.Label.UI_Error_AgreementLineItem_DiscountMoreThan100Percent);
                    }
                }
                ilib_LogEvent.message('@@@@ ali.Discount_In_Percent__c++'+ali.Discount_In_Percent__c);
            }
    }

    /*
    * @Roopal
    * Calculating Map of Material Group wrapper
    */
    private static void getMapMaterialGroup (Custom_Approval_Matrix__c objCam,Map<Custom_Approval_Matrix__c,Set<String>> mapMatrixToMG){
        if(mapMatrixToMG.containsKey(objCam)) 
        {
            Set<String> setMatGrp = mapMatrixToMG.get(objCam);
            setMatGrp.add(objCam.Material_Group_1__c);
            mapMatrixToMG.put(objCam, setMatGrp);
        }
        else
        {
            mapMatrixToMG.put(objCam, new Set<String> { objCam.Material_Group_1__c });
        }
    }

    /*
    * @Roopal
    * To get set of material group or material number values
    */
    private static List<String> getSetValues(Set<String> setValues){
        List<String> lstValues = new List<String>();
        if(setValues != null){
            for(String strVal : setValues)
            lstValues.addAll(strVal.split(';'));
        }
        //CMSI-90
        ilib_LogEvent.message('lstValues :'+lstValues);
        return lstValues;
    }

    /*
    * @Roopal
    * Calculate levels based on discount
    */
    private static CustomApprovalMatrixResult getCustomApprovalMatrixResult(Custom_Approval_Matrix__c objMatrix,Decimal discount,List<String> lstAppHierarchyTypes){
        Boolean booldiscountlessthanLevel1 = false;
        Custom_Approval_Matrix__c objApprovalMatrix = null;
        Integer intApprovalLevel = null;
        ilib_LogEvent.message('Error fix $$'+lstAppHierarchyTypes+'_'+objMatrix);
        Decimal decMinDiscountPercent = (lstAppHierarchyTypes.contains(HIERARCHY_CUSTOM) && objMatrix.Min_Discount__c!=null?objMatrix.Min_Discount__c:(objMatrix.Agreement_Minimum_Discount__c != null ?objMatrix.Agreement_Minimum_Discount__c:0));// below level one approval skip
        ilib_LogEvent.message('decMinDiscountPercent+'+decMinDiscountPercent);
        ilib_LogEvent.message('discount+'+discount);
        if(discount>decMinDiscountPercent){
            ilib_LogEvent.message('## Inside Discount > decMin');
            for(Integer intCurrentLevel=1; intCurrentLevel<=MAX_APPROVAL_LEVEL;intCurrentLevel++){
                Decimal decMatrixDiscountPercent = (Decimal) objMatrix.get('Discount_Level_' + intCurrentLevel + '__c');
                ilib_LogEvent.message('$$ decMatrixDiscountPercent'+decMatrixDiscountPercent+'_'+intCurrentLevel+'_'+objMatrix);
                if (decMatrixDiscountPercent!=null){
                    ilib_LogEvent.message('Inside assignment if');
                    intApprovalLevel = intCurrentLevel;
                    objApprovalMatrix = objMatrix;
                    booldiscountlessthanLevel1 = false;
                    if (discount <= decMatrixDiscountPercent) break;
                }
            }
        }
        else if(discount<=decMinDiscountPercent)
        {
            objApprovalMatrix = objMatrix;
            booldiscountlessthanLevel1 = true;
			//TASK0578569 Updating approval level for level 1.
            intApprovalLevel = APPROVAL_LEVEL_1;
        }
        CustomApprovalMatrixResult result = new CustomApprovalMatrixResult();
        result.intApprovalLevel = intApprovalLevel;
        result.soApprovalMatrix = objApprovalMatrix;
        result.booldiscountlessthanLevel1 = booldiscountlessthanLevel1;
        ilib_LogEvent.message('result :'+result);//CMSI-90
        return result;
    }

    /*
    * @Roopal
    * To get priority information
    */
    public static PriorityResult getPriorityResult(Integer intPriorityNew,Datetime lastModifiedDateNew,Custom_Approval_Matrix__c objMatrix,Integer intPriority,Datetime lastModifiedDate,Custom_Approval_Matrix__c objApprovalMatrix){
        boolean boolApprovalMatrixFound = false;
        if (intPriorityNew != null && lastModifiedDateNew != null){
            if(intPriority == null || intPriority > intPriorityNew){
                intPriority = intPriorityNew;
                lastModifiedDate = lastModifiedDateNew;
                objApprovalMatrix = objMatrix;
                boolApprovalMatrixFound = true;
            }
            else if(intPriority != null && intPriority == intPriorityNew){
                if(lastModifiedDate < lastModifiedDateNew)
                objApprovalMatrix = objMatrix;
                boolApprovalMatrixFound = true;
            }
        }
        PriorityResult priorityResults = new PriorityResult();
        priorityResults.intPriority = intPriority;
        priorityResults.soApprovalMatrix = objApprovalMatrix;
        priorityResults.lastModifiedDate = lastModifiedDate;
        priorityResults.boolApprovalMatrixFound = boolApprovalMatrixFound;
        return priorityResults;
    }

    /*
    *@ Roopal
    *Method to calculate approval parameters for Material Number Record Owner Approval
    */
    private static ApprovalResult calMaterialNumberROApproval(Apttus__AgreementLineItem__c ali,ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper,Map<Id,Apttus__APTS_Agreement__c> idToAgreement,String strDistributionChannel,Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct,Map<Id, Product2> mapIdToProduct,ApprovalResult result,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations){
        Account acc;
        String strApprovalStatus = result.strApprovalStatus;
        String strApprovalCategory = result.strApprovalCategory;
        Boolean boolApprovalFoundMNRO = false;
        Id idApprovalHierarchyDiscount = null ;
        Integer intApprovalLevelRecordOwner = null;
        List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.lstMatrixMaterialNumberRO;
        String strApprovalType = APPROVAL_TYPE_MATNUM;

        Apttus__APTS_Agreement__c oagreement = idToAgreement.get(ali.Apttus__AgreementId__c);
        acc = getAccountForPriceGroup(ali,oagreement);

        CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(ali, strDistributionChannel, lstApprovalMatrix,acc,mapCAMIdToSetProduct,strApprovalType,mapIdToProduct,lstPriorityCOmbinations);

        Id idHierarchy = (ownerToApprovalHierarchy.containsKey(oagreement.Apttus__Account__r.OwnerId) ? ownerToApprovalHierarchy.get(oagreement.Apttus__Account__r.OwnerId).id : null);
        ilib_LogEvent.message('@@@idHierarchy: '+idHierarchy+'_'+objApprovalMatrix);

        if(idHierarchy == null && objApprovalMatrix.intApprovalLevel != null)
        {
            if(!objApprovalMatrix.booldiscountlessthanLevel1){
                setAgreementIdsWithHierarchyError.add(ali.Apttus__AgreementId__c);
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
                strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
                strApprovalCategory +=  ApprovalCategory.MATERIAL_NUMBER.name() + ';';
                boolApprovalFoundMNRO = true;
            }
			//TASK0578569 Added condition to update approval level and add error if hierarchy not found for level 1 also
            else if(objApprovalMatrix.booldiscountlessthanLevel1){
                setAgreementIdsWithHierarchyError.add(ali.Apttus__AgreementId__c);
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
            }
            
        }
        if(objApprovalMatrix.soApprovalMatrix == null){
            setAgreementIdsWithMatrixError.add(ali.Apttus__AgreementId__c);
            boolApprovalFoundMNRO = false;
        }
        if(idHierarchy!=null && objApprovalMatrix.intApprovalLevel!=null){
            if(!objApprovalMatrix.booldiscountlessthanLevel1){
                idApprovalHierarchyDiscount = idHierarchy;
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
                strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
                strApprovalCategory +=  ApprovalCategory.MATERIAL_NUMBER.name() + ';';
                boolApprovalFoundMNRO = true;
            }
			//TASK0578569 Added condition to populate approval level and hierarchy incase of level 1 approval level.
            else if(objApprovalMatrix.booldiscountlessthanLevel1){
                idApprovalHierarchyDiscount = idHierarchy;
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
            }
            
        }
        
        else if(objApprovalMatrix.booldiscountlessthanLevel1)
        {
            setAgreementToRevert.add(ali.Apttus__AgreementId__c); 
            boolApprovalFoundMNRO = false;
        }
		//TASK0578569 Populate hierarchy if it is not null
        if(idHierarchy!=null){
            idApprovalHierarchyDiscount = idHierarchy;
        }
        
        ilib_LogEvent.message('ROBooleanMaterialNumber'+boolApprovalFoundMNRO);

        result.strApprovalStatus = strApprovalStatus;
        result.strApprovalCategory = strApprovalCategory;
        result.boolApprovalFoundMNRO = boolApprovalFoundMNRO;
        result.idApprovalHierarchyDiscount = idApprovalHierarchyDiscount;
        result.intApprovalLevelRecordOwner = intApprovalLevelRecordOwner;
        ilib_LogEvent.message('calMaterialNumberROApproval'+result);
        return result;
    }

    /*
    *@ Roopal
    *Method to calculate approval parameters for Material Group Record Owner Approval
    */
    private static ApprovalResult calMaterialGroupROApproval(Apttus__AgreementLineItem__c ali,ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper,Map<Id,Apttus__APTS_Agreement__c> idToAgreement,String strDistributionChannel,Map<Id, Product2> mapIdToProduct,ApprovalResult result,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations){
        Account acc;
        String strApprovalStatus = result.strApprovalStatus;
        Boolean boolApprovalFoundMGRO = false;
        String strApprovalCategory = result.strApprovalCategory;
        Id idApprovalHierarchyDiscount = result.idApprovalHierarchyDiscount;
        Integer intApprovalLevelRecordOwner = result.intApprovalLevelRecordOwner;
        List<Custom_Approval_Matrix__c> lstApprovalMatrix = new List<Custom_Approval_Matrix__c>();
        Set<Custom_Approval_Matrix__c> setApprovalMatrix = customMatrixWrapper.mapMatrixtoMaterialGroupRO.keyset();
        lstApprovalMatrix.addAll(setApprovalMatrix);
        String strApprovalType = APPROVAL_TYPE_MATGRP;
        
        ilib_LogEvent.message('&&&&&& List of Matrices for Material Group - '+ UtilsCollection.getSetOfIds(lstApprovalMatrix));//CMSI-90
        Apttus__APTS_Agreement__c oagreement = idToAgreement.get(ali.Apttus__AgreementId__c);
        acc = getAccountForPriceGroup(ali,oagreement);

        CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(ali, strDistributionChannel, lstApprovalMatrix,acc,customMatrixWrapper.mapMatrixtoMaterialGroupRO,strApprovalType,mapIdToProduct,lstPriorityCOmbinations);

        Id idHierarchy = (ownerToApprovalHierarchy.containsKey(oagreement.Apttus__Account__r.OwnerId) ? ownerToApprovalHierarchy.get(oagreement.Apttus__Account__r.OwnerId).id : null);
        ilib_LogEvent.message('@@@idHierarchy: '+idHierarchy);
        
		
        if(idHierarchy == null && objApprovalMatrix.intApprovalLevel != null)
        {
            if(!objApprovalMatrix.booldiscountlessthanLevel1){
                setAgreementIdsWithHierarchyError.add(ali.Apttus__AgreementId__c);
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
                strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
                strApprovalCategory +=  ApprovalCategory.MATERIAL_GROUP.name() + ';';
                boolApprovalFoundMGRO = true;
				removeMatrixError(ali.Apttus__AgreementId__c);
                
            }
			//TASK0578569 Added condition to update approval level and add error if hierarchy not found for level 1 also
            else if(objApprovalMatrix.booldiscountlessthanLevel1){
                setAgreementIdsWithHierarchyError.add(ali.Apttus__AgreementId__c);
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
				removeMatrixError(ali.Apttus__AgreementId__c);
            }
            
        }
        if(objApprovalMatrix.soApprovalMatrix == null)
        {
            setAgreementIdsWithMatrixError.add(ali.Apttus__AgreementId__c);
            boolApprovalFoundMGRO = false;
        }
        if(idHierarchy!=null && objApprovalMatrix.intApprovalLevel!=null)
        {
            if(!objApprovalMatrix.booldiscountlessthanLevel1){
                idApprovalHierarchyDiscount = idHierarchy;
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
                strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
                strApprovalCategory +=  ApprovalCategory.MATERIAL_GROUP.name() + ';';
                boolApprovalFoundMGRO = true;
                removeMatrixError(ali.Apttus__AgreementId__c);
            }
			//TASK0578569 Added condition to populate approval level and hierarchy incase of level 1 approval level.
            else if(objApprovalMatrix.booldiscountlessthanLevel1){
                idApprovalHierarchyDiscount = idHierarchy;
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
                removeMatrixError(ali.Apttus__AgreementId__c);
            }
            
        }
        else if(objApprovalMatrix.booldiscountlessthanLevel1)
        {
            setAgreementToRevert.add(ali.Apttus__AgreementId__c); 
            boolApprovalFoundMGRO = false;
            removeMatrixError(ali.Apttus__AgreementId__c);
        }        
		//TASK0578569 Populate hierarchy if it is not null
        if(idHierarchy != null){
            idApprovalHierarchyDiscount = idHierarchy;
        }
        ilib_LogEvent.message('boolApprovalFoundMGRO'+boolApprovalFoundMGRO);
        result.strApprovalStatus = strApprovalStatus;
        result.strApprovalCategory = strApprovalCategory;
        result.boolApprovalFoundMGRO = boolApprovalFoundMGRO;
        result.idApprovalHierarchyDiscount = idApprovalHierarchyDiscount;
        result.intApprovalLevelRecordOwner = intApprovalLevelRecordOwner;
        ilib_LogEvent.message('calMaterialGroupROApproval'+result);
        return result;
    }
 
    /*
    *@ Roopal
    *Method to calculate approval parameters for Discount Record Owner Approval
    */
    private static ApprovalResult calDiscountROApproval(Apttus__AgreementLineItem__c ali,ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper,Map<Id,Apttus__APTS_Agreement__c> idToAgreement,String strDistributionChannel,Map<Id, Product2> mapIdToProduct,ApprovalResult result,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations){
        Account acc;
        String strApprovalStatus = result.strApprovalStatus;
        Boolean boolApprovalFoundDisRO = false;
        Id idApprovalHierarchyDiscount = result.idApprovalHierarchyDiscount;
        Integer intApprovalLevelRecordOwner = result.intApprovalLevelRecordOwner;
        String strApprovalCategory = result.strApprovalCategory;
        if(ali.Discount_In_Percent__c!=null && ali.Line_Type__c!=QUOTA && ali.Line_Type_1__c!=QUOTA && ali.Discontinued__c!=YES){
        List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.lstMatrixDiscountRO;
        ilib_LogEvent.message('&&&&&& List of Matrices for Discount - '+ lstApprovalMatrix);
        String strApprovalType = APPROVAL_TYPE_DISCOUNT;

        Apttus__APTS_Agreement__c oagreement = idToAgreement.get(ali.Apttus__AgreementId__c);
        
        acc = getAccountForPriceGroup(ali, oagreement);

        CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(ali, strDistributionChannel,  lstApprovalMatrix,acc,null,strApprovalType,mapIdToProduct,lstPriorityCOmbinations);
        
        Id idHierarchy = (ownerToApprovalHierarchy.containsKey(oagreement.Apttus__Account__r.OwnerId) ? ownerToApprovalHierarchy.get(oagreement.Apttus__Account__r.OwnerId).id : null);
        ilib_LogEvent.message('@@@idHierarchy: '+idHierarchy+'_'+objApprovalMatrix);
        if(idHierarchy == null && objApprovalMatrix.intApprovalLevel != null)
        {
            if(!objApprovalMatrix.booldiscountlessthanLevel1){
                setAgreementIdsWithHierarchyError.add(ali.Apttus__AgreementId__c);
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
                strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
                strApprovalCategory +=  ApprovalCategory.DISCOUNT.name() + ';';
                boolApprovalFoundDisRO = true;
                removeMatrixError(ali.Apttus__AgreementId__c);
            }
			//TASK0578569 Added condition to update approval level and add error if hierarchy not found for level 1 also
            else if(objApprovalMatrix.booldiscountlessthanLevel1){
                setAgreementIdsWithHierarchyError.add(ali.Apttus__AgreementId__c);
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
				removeMatrixError(ali.Apttus__AgreementId__c);
            }
            
        }
        if(objApprovalMatrix.soApprovalMatrix == null){
            setAgreementIdsWithMatrixError.add(ali.Apttus__AgreementId__c);
            boolApprovalFoundDisRO = false;
        }
        if(idHierarchy!=null && objApprovalMatrix.intApprovalLevel!=null){
            if(!objApprovalMatrix.booldiscountlessthanLevel1){
                idApprovalHierarchyDiscount = idHierarchy;
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
                strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
                strApprovalCategory +=  ApprovalCategory.DISCOUNT.name() + ';';
                boolApprovalFoundDisRO = true;
                removeMatrixError(ali.Apttus__AgreementId__c);
            }
			//TASK0578569 Added condition to populate approval level and hierarchy incase of level 1 approval level.
            else if(objApprovalMatrix.booldiscountlessthanLevel1){
                intApprovalLevelRecordOwner = objApprovalMatrix.intApprovalLevel;
                idApprovalHierarchyDiscount = idHierarchy;
				removeMatrixError(ali.Apttus__AgreementId__c);
            }
            
        }else if(objApprovalMatrix.booldiscountlessthanLevel1)
        {
            setAgreementToRevert.add(ali.Apttus__AgreementId__c); 
            boolApprovalFoundDisRO = false;
            removeMatrixError(ali.Apttus__AgreementId__c);
        }
		//TASK0578569 Populate hierarchy if it is not null
        if(idHierarchy != null){
            idApprovalHierarchyDiscount = idHierarchy;
        }
        
        ilib_LogEvent.message('boolApprovalFoundDisRO'+boolApprovalFoundDisRO);
    }
        result.strApprovalStatus = strApprovalStatus;
        result.strApprovalCategory = strApprovalCategory;
        result.boolApprovalFoundDisRO = boolApprovalFoundDisRO;
        result.idApprovalHierarchyDiscount = idApprovalHierarchyDiscount;
        result.intApprovalLevelRecordOwner = intApprovalLevelRecordOwner;
        ilib_LogEvent.message('calDiscountROApproval'+result);
        return result;
    }

    /*
    *@ Roopal
    *Method to calculate approval parameters for Material Number Custom Approval
    */
    private static ApprovalResult calMatNumCustomApproval(Apttus__AgreementLineItem__c ali,ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper,Map<Id,Apttus__APTS_Agreement__c> idToAgreement,String strDistributionChannel,Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct,Map<Id, Product2> mapIdToProduct,ApprovalResult result,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations){
        Account acc;
        String strApprovalStatus = result.strApprovalStatus;
        Boolean boolApprovalFoundMNCust = false;
        Id idApprovalHierarchyMaterialNumCustom = null;
        Integer intApprovalLevelMaterialNumCustom = null;
        String strApprovalCategory= result.strApprovalCategory;
        List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.lstMatrixMaterialNumberCustom;
        String strApprovalType = APPROVAL_TYPE_MATNUM;
        Apttus__APTS_Agreement__c oagreement = idToAgreement.get(ali.Apttus__AgreementId__c);
    
        acc = getAccountForPriceGroup(ali, oagreement);
        CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(ali, strDistributionChannel,  lstApprovalMatrix,acc,mapCAMIdToSetProduct,strApprovalType,mapIdToProduct,lstPriorityCOmbinations);
        ilib_LogEvent.message('@@@ objApprovalMatrix for Discount,value 1: '+objApprovalMatrix + '_' + lstApprovalMatrix);
        intApprovalLevelMaterialNumCustom = objApprovalMatrix.intApprovalLevel;
        idApprovalHierarchyMaterialNumCustom = (objApprovalMatrix.soApprovalMatrix == null ? null : objApprovalMatrix.soApprovalMatrix.Approval_Hierarchy__c);
        if(idApprovalHierarchyMaterialNumCustom!=null && intApprovalLevelMaterialNumCustom!=null && objApprovalMatrix.booldiscountlessthanLevel1!=true){
            strApprovalCategory += ApprovalCategory.MATERIAL_NUMBER_CUSTOM.name() + ';';
            strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
            boolApprovalFoundMNCust = true;
            }
        if(objApprovalMatrix.booldiscountlessthanLevel1)
            {
            setAgreementToRevert.add(ali.Apttus__AgreementId__c);
            boolApprovalFoundMNCust = false;
            }
        ilib_LogEvent.message('$$ boolApprovalFoundMNCust'+boolApprovalFoundMNCust);
        result.strApprovalStatus = strApprovalStatus;
        result.strApprovalCategory = strApprovalCategory;
        result.boolApprovalFoundMNCust = boolApprovalFoundMNCust;
        result.intApprovalLevelCustom = intApprovalLevelMaterialNumCustom;
        result.idApprovalHierarchyCustom = idApprovalHierarchyMaterialNumCustom;
        result.setAgreementToRevert = setAgreementToRevert;
        ilib_LogEvent.message('calMatNumCustomApproval'+result);
        return result;
    }

    /*
    *@ Roopal
    *Method to calculate approval parameters for Material Group Custom Approval
    */
    private static ApprovalResult calMatGroupCustomApproval(Apttus__AgreementLineItem__c ali,ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper,Map<Id,Apttus__APTS_Agreement__c> idToAgreement,String strDistributionChannel,Map<Id, Product2> mapIdToProduct,ApprovalResult result,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations){
        Account acc;
        String strApprovalStatus = result.strApprovalStatus;
        Boolean boolApprovalFoundMGCust = false;
        Id idApprovalHierarchyMaterialGroupCustom = null;
        Integer intApprovalLevelMaterialGroupCustom = null;
        String strApprovalCategory = result.strApprovalCategory;
        List<Custom_Approval_Matrix__c> lstApprovalMatrix = new List<Custom_Approval_Matrix__c>();
        Set<Custom_Approval_Matrix__c> setApprovalMatrix = customMatrixWrapper.mapMatrixtoMaterialGroupCustom.keyset();
        lstApprovalMatrix.addAll(setApprovalMatrix);
        String strApprovalType = APPROVAL_TYPE_MATGRP;
        
        Apttus__APTS_Agreement__c oagreement = idToAgreement.get(ali.Apttus__AgreementId__c);

        acc = getAccountForPriceGroup(ali, oagreement);
        
        CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(ali, strDistributionChannel, lstApprovalMatrix,acc,customMatrixWrapper.mapMatrixtoMaterialGroupCustom,strApprovalType,mapIdToProduct,lstPriorityCOmbinations);
        ilib_LogEvent.message('@@@ objApprovalMatrix for Material group custom: '+objApprovalMatrix+'_'+lstApprovalMatrix);

        intApprovalLevelMaterialGroupCustom =   objApprovalMatrix.intApprovalLevel;
        idApprovalHierarchyMaterialGroupCustom = (objApprovalMatrix.soApprovalMatrix == null ? null : objApprovalMatrix.soApprovalMatrix.Approval_Hierarchy__c);

        if(intApprovalLevelMaterialGroupCustom!=null && idApprovalHierarchyMaterialGroupCustom!=null && objApprovalMatrix.booldiscountlessthanLevel1!=true){
            strApprovalCategory += ApprovalCategory.MATERIAL_GROUP_CUSTOM.name() + ';';
            strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
            boolApprovalFoundMGCust = true;
            }
        if(objApprovalMatrix.booldiscountlessthanLevel1)
            {
            setAgreementToRevert.add(ali.Apttus__AgreementId__c);
            boolApprovalFoundMGCust = false;
            }
            ilib_LogEvent.message('$$ boolApprovalFoundMGCust'+boolApprovalFoundMGCust);
        result.strApprovalStatus = strApprovalStatus;
        result.strApprovalCategory = strApprovalCategory;
        result.boolApprovalFoundMGCust = boolApprovalFoundMGCust;
        result.intApprovalLevelCustom = intApprovalLevelMaterialGroupCustom;
        result.idApprovalHierarchyCustom = idApprovalHierarchyMaterialGroupCustom;
        result.setAgreementToRevert = setAgreementToRevert;
        ilib_LogEvent.message('calMatGroupCustomApproval'+result);
        return result;
    }

    /*
    *@ Roopal
    *Method to calculate approval parameters for Discount Custom Approval
    */
    private static ApprovalResult calDiscountCustomApproval(Apttus__AgreementLineItem__c ali,ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper,Map<Id,Apttus__APTS_Agreement__c> idToAgreement,String strDistributionChannel,Map<Id, Product2> mapIdToProduct,ApprovalResult result,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations){
        Account acc;
        String strApprovalStatus = result.strApprovalStatus;
        Id idApprovalHierarchyDiscountCustom = null;
        Integer intApprovalLevelDiscountCustom = null;
        List<Custom_Approval_Matrix__c> lstApprovalMatrix = customMatrixWrapper.lstMatrixDiscountCustom;
        String strApprovalType = APPROVAL_TYPE_DISCOUNT;
        String strApprovalCategory = result.strApprovalCategory;

        Apttus__APTS_Agreement__c oagreement = idToAgreement.get(ali.Apttus__AgreementId__c);
        
        acc = getAccountForPriceGroup(ali, oagreement);

        CustomApprovalMatrixResult objApprovalMatrix = getApprovalMatrix(ali, strDistributionChannel,  lstApprovalMatrix,acc,null,strApprovalType,mapIdToProduct,lstPriorityCOmbinations);
        ilib_LogEvent.message('@@@ objApprovalMatrix for Discount: '+objApprovalMatrix);
        
        intApprovalLevelDiscountCustom = objApprovalMatrix.intApprovalLevel;
        idApprovalHierarchyDiscountCustom = (objApprovalMatrix.soApprovalMatrix == null ? null : objApprovalMatrix.soApprovalMatrix.Approval_Hierarchy__c);
        
        if(intApprovalLevelDiscountCustom!=null && idApprovalHierarchyDiscountCustom!=null && objApprovalMatrix.booldiscountlessthanLevel1!=true){
            strApprovalCategory += ApprovalCategory.DISCOUNT_CUSTOM.name() + ';';
            strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
            }
        if(objApprovalMatrix.booldiscountlessthanLevel1)
            {
            setAgreementToRevert.add(ali.Apttus__AgreementId__c);
            }
        result.strApprovalStatus = strApprovalStatus;
        result.strApprovalCategory = strApprovalCategory;
        result.intApprovalLevelCustom = intApprovalLevelDiscountCustom;
        result.idApprovalHierarchyCustom = idApprovalHierarchyDiscountCustom;
        result.setAgreementToRevert = setAgreementToRevert;
        ilib_LogEvent.message('calDiscountCustomApproval'+result);
        return result;
    }

    /*
    *@ Roopal
    *Method to calculate Record Owner Approvals
    */
    private static ApprovalResult calculateROApprovals(Apttus__AgreementLineItem__c ali,ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper,Map<Id,Apttus__APTS_Agreement__c> idToAgreement,String strDistributionChannel,Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct,Map<Id, Product2> mapIdToProduct,ApprovalResult approvalResult,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations){
        String strApprovalCategory = approvalResult.strApprovalCategory;
        Integer intApprovalLevelRecordOwner = null;
        String strApprovalStatus = approvalResult.strApprovalStatus;
        Id idApprovalHierarchyDiscount = null;
        Boolean boolApprovalFoundMNRO = false;
        Boolean boolApprovalFoundMGRO = false;
        Boolean boolApprovalFoundDisRO = false;
        
        if(ali.Material_Number__c!=null && ali.Line_Type__c!=QUOTA && ali.Line_Type_1__c!=QUOTA && ali.Discontinued__c!=YES && setAllProducts.contains(ali.Material_Number__c))
        {
            approvalResult = calMaterialNumberROApproval(ali,customMatrixWrapper,idToAgreement,strDistributionChannel,mapCAMIdToSetProduct,mapIdToProduct,approvalResult,lstPriorityCOmbinations);
            strApprovalStatus = approvalResult.strApprovalStatus;
            strApprovalCategory = approvalResult.strApprovalCategory;
            boolApprovalFoundMNRO = approvalResult.boolApprovalFoundMNRO;
            idApprovalHierarchyDiscount = approvalResult.idApprovalHierarchyDiscount;
            intApprovalLevelRecordOwner = approvalResult.intApprovalLevelRecordOwner;
        }   // Material Group Approval for record owner
        if (boolApprovalFoundMNRO == false && ali.Line_Type__c!=QUOTA && ali.Line_Type_1__c!=QUOTA && ((ali.Apttus__ProductId__c !=null && mapIdToProduct.get(ali.Apttus__ProductId__c).Material_Group_1_Code__c != null )|| ali.Material_Group_1__c!=null) && ali.Discontinued__c!=YES)
        {
            approvalResult = calMaterialGroupROApproval(ali,customMatrixWrapper,idToAgreement,strDistributionChannel,mapIdToProduct,approvalResult,lstPriorityCOmbinations);
            strApprovalStatus = approvalResult.strApprovalStatus;
            strApprovalCategory += approvalResult.strApprovalCategory;
            boolApprovalFoundMGRO = approvalResult.boolApprovalFoundMGRO;
            idApprovalHierarchyDiscount = approvalResult.idApprovalHierarchyDiscount;
            intApprovalLevelRecordOwner = approvalResult.intApprovalLevelRecordOwner; 
       }//Discount approval for record owner
        if (boolApprovalFoundMGRO == false && boolApprovalFoundMNRO == false)
        {
            approvalResult = calDiscountROApproval(ali,customMatrixWrapper,idToAgreement,strDistributionChannel,mapIdToProduct,approvalResult,lstPriorityCOmbinations);
            strApprovalStatus = approvalResult.strApprovalStatus;
            strApprovalCategory += approvalResult.strApprovalCategory;
            boolApprovalFoundDisRO = approvalResult.boolApprovalFoundDisRO;
            idApprovalHierarchyDiscount = approvalResult.idApprovalHierarchyDiscount;
            intApprovalLevelRecordOwner = approvalResult.intApprovalLevelRecordOwner; 
        }
        
        approvalResult.strApprovalStatus =strApprovalStatus;
        approvalResult.strApprovalCategory = strApprovalCategory;
        approvalResult.idApprovalHierarchyDiscount = idApprovalHierarchyDiscount;
        approvalResult.intApprovalLevelRecordOwner = intApprovalLevelRecordOwner;
        approvalResult.boolApprovalFoundMNRO = boolApprovalFoundMNRO;
        approvalResult.boolApprovalFoundMGRO = boolApprovalFoundMGRO;
        approvalResult.boolApprovalFoundDisRO = boolApprovalFoundDisRO;
        ilib_LogEvent.message('calculateROApprovals'+approvalResult);
        return approvalResult;
    }

    /*
    *@ Roopal
    *Method to get mapAgreementHierarchyDiscount
    */
    private static Map<Id,Id> getMapAgreementHierarchyDiscount(Apttus__AgreementLineItem__c ali,Map<Id,Id> mapAgreementHierarchyDiscount){
        if(ali.Approval_Hierarchy_Record_Owner__c!=null)
            mapAgreementHierarchyDiscount.put(ali.Apttus__AgreementId__c,ali.Approval_Hierarchy_Record_Owner__c);
        return mapAgreementHierarchyDiscount;
    }

    /*
    *@ Roopal
    *Method to get setAgreementToRevert
    */
    private static Set<Id> getsetAgreementToRevert(Apttus__AgreementLineItem__c ali,Set<Id> setAgreementToUpdate){
        if(ali.Approval_Category__c != '' && ali.Approval_Category__c != null)
            {
                setAgreementToUpdate.add(ali.Apttus__AgreementId__c);
            }
        else
        {
            setAgreementToRevert.add(ali.Apttus__AgreementId__c);
        }
        ilib_LogEvent.message('setAgreementToUpdate :'+setAgreementToUpdate);//CMSI-90
        return setAgreementToUpdate;
    }

    /*
    *@ Roopal
    *Method to calculate Custom Approvals
    */
    private static ApprovalResult calculateCustomApprovals(Apttus__AgreementLineItem__c ali,ApttusProposalLineItems.CustomApprovalMatrixWrapper customMatrixWrapper,Map<Id,Apttus__APTS_Agreement__c> idToAgreement,String strDistributionChannel,Map<Custom_Approval_Matrix__c,Set<String>> mapCAMIdToSetProduct,Map<Id, Product2> mapIdToProduct,Boolean boolApprovalFoundMNRO,Boolean boolApprovalFoundMGRO,Boolean boolApprovalFoundDisRO,String strApprovalCategory,ApprovalResult approvalResults,List<Approval_Priority_Combination__mdt> lstPriorityCOmbinations){
        Boolean boolApprovalFoundMNCust = false;
        Boolean boolApprovalFoundMGCust = false;
        Integer intApprovalLevelMaterialNumCustom = null;
        Id idApprovalHierarchyMaterialNumCustom = null;
        Integer intApprovalLevelMaterialGroupCustom = null;
        Id idApprovalHierarchyMaterialGroupCustom = null;
        Integer intApprovalLevelDiscountCustom = null;
        Id idApprovalHierarchyDiscountCustom = null;
        
        // Custom approval flow
        if(boolApprovalFoundDisRO == true || boolApprovalFoundMGRO == true || boolApprovalFoundMNRO == true)
        {
            if(ali.Material_Number__c!=null && ali.Discontinued__c!=YES){
                approvalResults = calMatNumCustomApproval(ali,customMatrixWrapper,idToAgreement,strDistributionChannel,mapCAMIdToSetProduct,mapIdToProduct,approvalResults,lstPriorityCOmbinations);
                strApprovalCategory += approvalResults.strApprovalCategory;
                boolApprovalFoundMNCust = approvalResults.boolApprovalFoundMNCust;
                intApprovalLevelMaterialNumCustom = approvalResults.intApprovalLevelCustom;
                idApprovalHierarchyMaterialNumCustom = approvalResults.idApprovalHierarchyCustom; 
                setAgreementToRevert = approvalResults.setAgreementToRevert;
            }
            if (boolApprovalFoundMNCust == false &&  (ali.Apttus__ProductId__c !=null || ali.Material_Group_1__c!=null) && ali.Discontinued__c!=YES)
            {
                approvalResults = calMatGroupCustomApproval(ali,customMatrixWrapper,idToAgreement,strDistributionChannel,mapIdToProduct,approvalResults,lstPriorityCOmbinations);
                strApprovalCategory += approvalResults.strApprovalCategory;
                boolApprovalFoundMGCust = approvalResults.boolApprovalFoundMGCust;
                intApprovalLevelMaterialGroupCustom = approvalResults.intApprovalLevelCustom;
                idApprovalHierarchyMaterialGroupCustom = approvalResults.idApprovalHierarchyCustom; 
                setAgreementToRevert = approvalResults.setAgreementToRevert;
            }
            if (boolApprovalFoundMNCust == false && boolApprovalFoundMGCust == false)
            {
                if(ali.Discount_In_Percent__c!=null && ali.Line_Type__c!=QUOTA && ali.Line_Type_1__c!=QUOTA && ali.Discontinued__c!=YES)
                {
                    approvalResults = calDiscountCustomApproval(ali,customMatrixWrapper,idToAgreement,strDistributionChannel,mapIdToProduct,approvalResults,lstPriorityCOmbinations);
                    strApprovalCategory += approvalResults.strApprovalCategory;
                    intApprovalLevelDiscountCustom = approvalResults.intApprovalLevelCustom;
                    idApprovalHierarchyDiscountCustom = approvalResults.idApprovalHierarchyCustom; 
                    setAgreementToRevert = approvalResults.setAgreementToRevert;
                }
            }       
        }

        approvalResults.strApprovalCategory = strApprovalCategory;
        approvalResults.intApprovalLevelDiscountCustom = intApprovalLevelDiscountCustom;
        approvalResults.intApprovalLevelMaterialGroupCustom = intApprovalLevelMaterialGroupCustom;
        approvalResults.intApprovalLevelMaterialNumCustom = intApprovalLevelMaterialNumCustom;
        approvalResults.idApprovalHierarchyDiscountCustom = idApprovalHierarchyDiscountCustom;
        approvalResults.idApprovalHierarchyMaterialGroupCustom = idApprovalHierarchyMaterialGroupCustom;
        approvalResults.idApprovalHierarchyMaterialNumCustom = idApprovalHierarchyMaterialNumCustom;
        ilib_LogEvent.message('calculateCustomApprovals'+approvalResults);
        return approvalResults;
    }
    /*
    *@ Joshith K
    *Method to get Pricelist item  
    */
    public static Apttus_Config2__PriceListItem__c getPriceListItem(Id productId,string keyAliToErpSalesId,Apttus__AgreementLineItem__c ali){
        Apttus_Config2__PriceListItem__c selectedPricelist = null;
        Date startDate=ali.Apttus_CMConfig__StartDate__c<System.today()?System.today():ali.Apttus_CMConfig__StartDate__c;
        ilib_LogEvent.message('mapProductPricelist '+mapProductPricelist);
        ilib_LogEvent.message('mapAliToAccountSalesArea :'+(!mapAliToAccountSalesArea.isEmpty()? String.valueOf(mapAliToAccountSalesArea.keySet()):MAPISEMPTY));

        if(!mapProductPricelist.containskey(productId)
        ||!mapProductPricelist.get(productId).containskey(mapAliToAccountSalesArea.get(keyAliToErpSalesId).Price_List__c))
            return null;
        List<Apttus_Config2__PriceListItem__c> lstPLI=(mapProductPricelist.get(productId)).get(mapAliToAccountSalesArea.get(keyAliToErpSalesId).Price_List__c);
        for(Apttus_Config2__PriceListItem__c objpli: lstPLI )
        {      
            if(startDate >= dateTimeToDate(objpli.Apttus_Config2__EffectiveDate__c)
            &&startDate <= dateTimeToDate(objpli.Apttus_Config2__ExpirationDate__c))
            {   
                if(selectedPricelist==null
                ||objpli.Apttus_Config2__ListPrice__c>selectedPricelist.Apttus_Config2__ListPrice__c){
                    selectedPricelist=objpli;
                            
                }
                           
            }
        }
        //CMSI-90
        ilib_LogEvent.message('selectedPricelist ids :'+selectedPricelist);
        return selectedPricelist;
    }
    /*
    *@ Joshith 
    *Method to convert datetime to date
    */
    public static Date dateTimeToDate(DateTime objDateTime)
    {
        Date objDate = date.newinstance(objDateTime.year(), objDateTime.month(), objDateTime.day());
        ilib_LogEvent.message('objDate :'+objDate);//CMSI-90
        return objDate;
    }
	/*
    *@ Prabhsimran Singh
    * Method for removing agreementid from set of MatrixError
    */
    private static void removeMatrixError(Id agreementId){
		if(setAgreementIdsWithMatrixError.contains(agreementId))
            setAgreementIdsWithMatrixError.remove(agreementId);
	}

    /*
    *@ Bharath Varma
    * Method for Calculating MFN Approvals
    * DCP-49431
    */
    private static ApprovalResult calculateMFNApprovals(Apttus__AgreementLineItem__c ali,Map<Id,Apttus__APTS_Agreement__c> idToAgreement,ApprovalResult approvalResults){
        Boolean mfnLineItem = false;
        String oncologyLabManufacturerComparison = idToAgreement.get(ali.Apttus__AgreementId__c).Apttus__Account__r.Oncology_Lab_Manufacturer_Comparison__c;
        Boolean isAccountClinicalLabService = oncologyLabManufacturerComparison==null ? false : System.Label.Yes.contains(oncologyLabManufacturerComparison);
        if(isAccountClinicalLabService && ali.Is_MFN_NovaSeq_Consumable__c && idToAgreement.get(ali.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_USA && ali.Discount__c > decimal.valueOf(System.Label.MFN_USA_NovaSeq_Discount)) {
            mfnLineItem = true;
        }
        else if(isAccountClinicalLabService && ali.Is_MFN_NextSeq_RUO_Consumable__c && idToAgreement.get(ali.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_USA && ali.Discount__c > decimal.valueOf(System.Label.MFN_USA_NextSeq_Discount)) {
            mfnLineItem = true;
        }
        else if(isAccountClinicalLabService && ali.Is_MFN_TG_NextSeq_Consumable__c && idToAgreement.get(ali.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_USA && ali.Discount__c > decimal.valueOf(System.Label.MFN_USA_TG_NextSeq_Discount)) {
            mfnLineItem = true;
        }
        else if(isAccountClinicalLabService && ali.Is_MFN_NovaSeq_Consumable__c && idToAgreement.get(ali.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_Germany && ali.Discount__c > decimal.valueOf(System.Label.MFN_Germany_NovaSeq_Discount)) {
            mfnLineItem = true;
        }
        else if(isAccountClinicalLabService && ali.Is_MFN_NextSeq_RUO_Consumable__c && idToAgreement.get(ali.Apttus__AgreementId__c).Country_On_Account_Approvals__c == System.Label.Country_Germany && ali.Discount__c > decimal.valueOf(System.Label.MFN_Germany_NextSeq_Discount)) {
            mfnLineItem = true;
        }

        if(mfnLineItem) {
            approvalResults.strApprovalCategory += ApprovalCategory.MFN_APPROVALS.name();
            approvalResults.mfnLineItem = true;
            approvalResults.strApprovalStatus = System.Label.AgreementApprovalStatusApprovalRequired;
        }
        ilib_LogEvent.message('approvalResults :'+approvalResults);
        return approvalResults;
    }
}
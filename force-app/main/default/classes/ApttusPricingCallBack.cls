/**
*    Author: Rohan Chandarana
*    Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Satya Swain          20 August 2018                  Modified onPriceItemSet() for DCP-9374
* Govind Dubey         23 August 2018                  Modified updatePrice for max discount calculation DCP-9024
* Saswati Prusty       17th May 2019                   Modified onPriceItemSet() for DCP - 25196 
* Kushagra Desai       7-July-2019                     DCP-25598 Billing Freq Default
* Saswati              9th July 2019                   Part Of DCP - 25191
* Roopal Verma         29-AUg-2019                     DCP-26583 - Added check for End of sale
* Arnab Modak          06-Sep-2019                     DCP-28284 - To override the NetPrice for FixedBundle products
* Joshith K            09-Jan-2020                     INC0238317- Remove Query From Afterpricing add Query in Start Method
* Anish Pathak		   02-Jun-2020					   DCP-35616 - Restore Quantity to 1
* Prem Ranjan          29-06-2021                      DCP-48133 - Automated Adding Excalibur Wave 1 Products to cart
* Anish Pathak         29-09-2021                      DCP-48873 - Default Hide Contract to true if product added by Constraint Rule
* Ashwin Kumar         06-Jan-2022                     INC0364337: Avoid ApexPages.addmessage when class invoked from backend system process
* Prem Ranjan          07-02-2022                      CodeScan Fix - Unused Private Fields.
* Jitesh Lakhwani      10-May-2022                     DCP-53221 -  Default Hide Contract to true for ALL products except Products which type = Recurring and Quote Sub Type = Renewal - Service Contract No Upsell, Renewal - Software No Upsell, Upsell with Service Contract Renewal. 
                                                       removed unwanted code included the user story DCP-52386 fix along with DCP-53221 fix
* Khushbu Vasani       22-June-2022                    DCP-53200 - populate open offer max discount
* Iram Malik           05-Jul-2022                     Codescan Fix: Unused local variables
* Nesar Mohan          08-August-2022                  DCP-56258 - Prepopulate Registration contact field on the cart line item
*  Khushbu Vasani      2022-09-01                       DCP-56658 changes
* Nishan Shetty        05-Jan-2023                    CodeScan Unused Variable Fix.
**/


global with sharing class ApttusPricingCallBack implements Apttus_Config2.CustomClass.IPricingCallback3{
    private static final String ADDED_BY_CONSTRAINT_RULE = 'Constraint Rule';//DCP-48873
    private Apttus_Config2.ProductConfiguration cart;
    private Apttus_Config2.CustomClass.PricingMode mode;
    private Boolean boolConsortia;
    private static Code_Parameter__mdt objCodeParam = Code_Parameter__mdt.getInstance('Informatics_Product_Families');

    public static final String PRODUCT_SALES_AREA_GROUP = 'ZSCO';
	public static boolean boolEOSError = false; //DCP-26583 - Added for test class 
    Map<Id, Product2> mapIdToProduct = new Map<Id, Product2>();
    Map<String,Decimal> prodCodeToDuration = new Map<String,Decimal>();//DCP-48133
    List<String> quoteSubType = new List<String>{LABEL.OpportunityTypeRenewalServiceContractNoUpsell , LABEL.OpportunityTypeRenewalSoftwareNoUpsell, LABEL.OpportunityTypeUpsellwithServiceContractRenewal}; //Added as part of DCP-53221

    static final string OPENOFFERDISCOUNTPRICINGCALLBACK = 'OpenOfferDiscountPricingCallback';
    private static final string EXCEPTION_LOG_TITLE = 'ApttusPricingCallBack';
    static boolean openOfferMetaDataLoaded = false;
    public static final String ADD_ON = 'ADD-ON'; //DCP-56258

     /**
     * @owner Rohan Chandarana
     * @description Callback at the beginning of the pricing call.
     * Use the start method to initialize state
     * @param cart the cart object
     */
    global void start(Apttus_Config2.ProductConfiguration cart){
        this.cart = cart;
        Apttus_Config2__ProductConfiguration__c objProductConfig = cart.getConfigSO();
        this.boolConsortia = (objProductConfig.Quote_Sub_Type__c==System.Label.OpportunityTypeConsortium || objProductConfig.Quote_Sub_Type__c == system.label.OpportunityTypeReorderConsortiumConsumable);
        List<Apttus_Config2.LineItem> lstStandardLineItems = cart.getLineItems();
        Set<Id> setProductId = new Set<Id>();
        for(Apttus_Config2.LineItem standardLineItem : lstStandardLineItems){
            Apttus_Config2__LineItem__c soLineItem = standardLineItem.getLineItemSO();
            if(soLineItem != null){ 
                setProductId.add(soLineItem.Apttus_Config2__ProductId__c);}
        }
        mapIdToProduct = new Map<Id, Product2>(new ProductsSelector().selectProducts(setProductId));
        //DCP-48133
        List<Product_End_Date_Setting__mdt> lstProductEndDateDuration = new ProductEndDateDurationSelector().selectAllRecords();

        for(Product_End_Date_Setting__mdt objProdWithDuration : lstProductEndDateDuration)
        {
            prodCodeToDuration.put(objProdWithDuration.Product_Code__c,objProdWithDuration.Terms_Months__c);
        }
        
        // Start method gets called twice..once for base and one for adjustment mode
        if (Feature.isOn(OPENOFFERDISCOUNTPRICINGCALLBACK) && !openOfferMetaDataLoaded)
        {
            calculateOpenOfferMaxDiscountPercentage(setProductId, cart.getConfigSO().Id, lstStandardLineItems);
            openOfferMetaDataLoaded = true;
        }
    }
        
   /**
     * @owner Rohan Chandarana
     * @description Callback to indicate the pricing mode
     * @param mode the pricing mode
     */
    global void setMode(Apttus_Config2.CustomClass.PricingMode mode){
        this.mode = mode;
    }
    /*
    * @owner Satya Swain
    * @description Callback to modify editable/readonly status of line items for DCP-9374
    * @param pli the price list item
    * @param li the cart line item    
    * @return void
    */   
    global void onPriceItemSet(Apttus_Config2__PriceListItem__c pli, Apttus_Config2.LineItem li){
        system.debug('---onPriceItemSet called---');
        Apttus_Config2__LineItem__c soLineItem = li.getLineItemSO();

        
            if(soLineItem.Is_New__c){
                //auto population of registrant contact on Installed products
                if(soLineItem.Registrant_Contact__c == null && soLineItem.Apttus_Config2__LineStatus__c != Label.LineItemLineStatusRenewed && soLineItem.Apttus_Config2__ProductId__r.Informatics_SKU_Type__c!=ADD_ON  && !String.isBlank(soLineItem.Apttus_Config2__ProductId__r.Informatics_Family__c) && objCodeParam.PickListValue__c.contains(soLineItem.Apttus_Config2__ProductId__r.Informatics_Family__c )) { //DCP-56258
                    soLineItem.Registrant_Contact__c = soLineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Primary_Contact__c;
                }
			if(this.boolConsortia){
					//update cart column fields when opportunity type is equal to Consortia
					updateConsortiaDefaults(soLineItem);
				
			}
                if(soLineItem.Apttus_Config2__LineStatus__c == Label.LineItemLineStatusNew){
                    System.debug('@@@@ Price Type of The Line item: '+soLineItem.Apttus_Config2__PriceType__c);
                    System.debug('@@@@ Start Date and End Date before entering the if else block: '+soLineItem.Apttus_Config2__StartDate__c+'  '+soLineItem.Apttus_Config2__EndDate__c);
                // for new sale        
                    if(!isSubscriptionProduct(soLineItem)){
                        // for new sale and non subscription products
                        soLineItem.Apttus_Config2__BillingFrequency__c = NULL;
                        soLineItem.Apttus_Config2__IsSellingTermReadOnly__c = true;
                        // Saswati : DCP : 25196. To set Hide Contract Dates for One Time products.
                        soLineItem.Hide_Contract_Dates__c = true;

                        System.debug('@@@@ inside if, ie non subscription products');
                        System.debug('@@@@ inside if, ie Start and End date of Line Item: '+soLineItem.Apttus_Config2__StartDate__c+'  '+soLineItem.Apttus_Config2__EndDate__c);
                    }else{
                        // for new sale and subscription products
                        soLineItem.Apttus_Config2__BillingFrequency__c = Label.LineItemBillingFrequencyYearly;
                        soLineItem.Apttus_Config2__IsSellingTermReadOnly__c = false;

                        System.debug('@@@@ inside else, ie subscription products');
                        System.debug('@@@@ inside else, ie Start and End date of Line Item: '+soLineItem.Apttus_Config2__StartDate__c+'  '+soLineItem.Apttus_Config2__EndDate__c);
                      //  System.debug('@@@@ inside else , ie Start and End date of Configuration: '+soLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__ExpectedStartDate__c+'  '+soLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__ExpectedEndDate__c );
                        
                        if(soLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__ExpectedStartDate__c != NULL && soLineItem.Apttus_Config2__EndDate__c==NULL){
                            soLineItem.Apttus_Config2__EndDate__c = soLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__ExpectedStartDate__c.addMonths(12).addDays(-1);
                            System.debug('@@@@ inside else if block, start date of Configuration is NULL');
                            System.debug('@@@@ inside else if block, Start and End date of Line Item post calculation: '+soLineItem.Apttus_Config2__StartDate__c+'  '+soLineItem.Apttus_Config2__EndDate__c);
                        //DCP-48133
                        populateEndDate(soLineItem,prodCodeToDuration);
                        }
                    }
                    // To set billing freq for contract product
                    //DCP-25598 Billing Freq Default
                    if(isContractProduct(soLineItem)){
                        soLineItem.Apttus_Config2__BillingFrequency__c = Label.QLIBillingFreqZZ;
                    }
					
					if(soLineItem.Apttus_Config2__AddedBy__c == ADDED_BY_CONSTRAINT_RULE)//DCP-48873
						soLineItem.Hide_Contract_Dates__c = true;

                    //Added as part of DCP-53221 (Jitesh Lakhwani) / User Story DCP-52386 developed by Kushal Shah is also added.
                    soLineItem.Hide_Contract_Dates__c = true;
                    if(String.isNotBlank(soLineItem.Apttus_Config2__ConfigurationId__r.Quote_Sub_Type__c) && pli.Apttus_Config2__PriceType__c == Label.PriceListItemPriceTypeRecurring && quoteSubType.contains(soLineItem.Apttus_Config2__ConfigurationId__r.Quote_Sub_Type__c) && soLineItem.Apttus_Config2__ProductId__r.ProductCode != LABEL.Hide_Contract_Date_Product_Codes){

                        soLineItem.Hide_Contract_Dates__c = false;
                    }
                    //DCP-53221 Changes End Here
                }
                else if(soLineItem.Apttus_Config2__LineStatus__c == Label.LineItemLineStatusRenewed){
                    soLineItem.Apttus_Config2__BillingFrequency__c = Label.LineItemBillingFrequencyYearly;
                    soLineItem.Billing_Type__c = Label.LineItemBillingTypeUpfront;
                }
                soLineItem.Is_New__c = false;
            }
        
    }
    /** 
     * @description  : DCP-48133 : Automated Adding Excalibur Wave 1 Products to cart
     **/
    public static void populateEndDate( Apttus_Config2__LineItem__c lineItem, Map<String,Decimal> mapOfProdCodeToDuration ){
        for(String prodCodeMapping: mapOfProdCodeToDuration.keySet()){
            if(lineItem.Apttus_Config2__ProductId__r.ProductCode == prodCodeMapping){
                Integer months = Integer.valueOf(mapOfProdCodeToDuration.get(prodCodeMapping));
                lineItem.Apttus_Config2__EndDate__c = lineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__ExpectedStartDate__c.addMonths(months).addDays(-1);
            
            }
        }
    }

     /**
     * @owner Rohan Chandarana
     * @description Callback before pricing the line item collection
     * Use this method to do all required pre-processing to prepare the line items for pricing.
     * @param itemColl the line item collection to pre-process
     */  
    global void beforePricing(Apttus_Config2.ProductConfiguration.LineItemColl itemColl){
        if(Apttus_Config2.CustomClass.PricingMode.BASEPRICE == mode && this.boolConsortia){
            List<Apttus_Config2.LineItem> lstStandardLineItems = itemColl.getAllLineItems();
            for(Apttus_Config2.LineItem standardLineItem : lstStandardLineItems){
                standardLineItem.getLineItemSO();//CodeScan Fix for Unused Local Variable.
            }
        }
    }
      
    
    /**
     * @owner Rohan Chandarana
     * @description Callback before pricing the line item
     * @param itemColl the line item collection to pre-process
     * @param lineItemMO Line Item Managed Object
     */  
    global void beforePricingLineItem(Apttus_Config2.ProductConfiguration.LineItemColl itemColl, Apttus_Config2.LineItem lineItemMO){
    }
                                                  
                                                  
    /**
     * @owner Rohan Chandarana
     * Callback after pricing the line item collection
     * Use this method to do all required post-processing after line items are priced.
     * @param itemColl the line item collection to post-process
     */
    global void afterPricing(Apttus_Config2.ProductConfiguration.LineItemColl itemColl){
        
        if(Apttus_Config2.CustomClass.PricingMode.ADJUSTMENT == mode){
            List<Apttus_Config2.LineItem> lstStandardLineItems = itemColl.getAllLineItems();
            for(Apttus_Config2.LineItem standardLineItem : lstStandardLineItems){
                Apttus_Config2__LineItem__c soLineItem = standardLineItem.getLineItemSO();
				if(soLineItem != null){
					if(soLineItem.Apttus_Config2__PriceListItemId__r.Apttus_Config2__IsQuantityReadOnly__c == true && soLineItem.Apttus_Config2__Quantity__c != 1){//DCP-35616
						soLineItem.Apttus_Config2__Quantity__c = 1;
						soLineItem.Apttus_Config2__NetPrice__c = soLineItem.List_Price__c;
					}        
					if(!isSubscriptionProduct(soLineItem)){
						 soLineItem.Apttus_Config2__StartDate__c = NULL;
						 soLineItem.Apttus_Config2__EndDate__c = NULL; 
						 // Saswati : DCP : 25196. To set Hide Contract Dates for One Time products.
						 soLineItem.Hide_Contract_Dates__c = true;
					 }
					//DCP-28284 To override selling term and directly show net price
					if(mapIdToProduct.get(soLineItem.Apttus_Config2__ProductId__c).Material_Class_Type__c == Label.FixedBundleMatClassType)
                    soLineItem.Apttus_Config2__NetPrice__c = soLineItem.SAP_Net_Price__c;
				
					if(soLineItem.Apttus_Config2__AddedBy__c == ADDED_BY_CONSTRAINT_RULE)//DCP-48873
						soLineItem.Hide_Contract_Dates__c = true;
                }
            }
         }
     }

    /**
     * @owner Rohan Chandarana
     * @description Callback after pricing the line item
     * @param itemColl the line item collection to post-process
     * @param lineItemMO Line Item sObject
     */ 
    global void afterPricingLineItem(Apttus_Config2.ProductConfiguration.LineItemColl itemColl, Apttus_Config2.LineItem lineItemMO){       
    }
    
     /**
    * Owner Rohan Chandarana
    * Callback after all batches of line items are processed
    */
    global void finish(){  
        
        List<Apttus_Config2.LineItem> listLineitem  = cart.getLineItems();
        String strEOSProducts = '';                                                           //DCP-26583 <--- Start
        List<Apttus_Config2__LineItem__c> lstItem = new List<Apttus_Config2__LineItem__c>();
        Set<Id> setProposalId = new Set<Id>();
        Set<Id> setProductId = new Set<Id>();
        for (Apttus_Config2.LineItem lineItem : listLineitem) {
            Apttus_Config2__LineItem__c item = lineItem.getLineItemSO();
            if(item != null) {
                lstItem.add(item);
                setProposalId.add(item.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c);
                setProductId.add(item.Apttus_Config2__ProductId__c);
            }
        }
        Map<Id, Apttus_Proposal__Proposal__c> mapIdToProposal = new Map<Id, Apttus_Proposal__Proposal__c>(new ApttusProposalsSelector().selectById(setProposalId));
        Map<Id, Product2> mapIdToProduct = new Map<Id, Product2>(new ProductsSelector().selectProducts(setProductId));
        for (Apttus_Config2__LineItem__c item : lstItem) {  
            String strProductName = mapIdToProduct.get(item.Apttus_Config2__ProductId__c).Name; 
            if(mapIdToProposal.get(item.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c).Apttus_QPConfig__PricingDate__c != null){
                if(mapIdToProposal.get(item.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c).Apttus_QPConfig__PricingDate__c >= date.Today()){
                    if(item.End_Of_Sale_Date__c < (mapIdToProposal.get(item.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c).Apttus_QPConfig__PricingDate__c.addDays(30))){
                        if(String.isBlank(strEOSProducts)){
                                    strEOSProducts = strProductName;
                                }
                        else {
                            if(!strEOSProducts.contains(strProductName)){
                                    strEOSProducts += ', ' + strProductName;
                            }
                        }
                    }
                } else {
                    if(item.End_Of_Sale_Date__c < date.Today().addDays(30)){
                        if(String.isBlank(strEOSProducts)){ strEOSProducts = strProductName; }
                        else {
                            if(!strEOSProducts.contains(strProductName)){ strEOSProducts += ', ' + strProductName; }
                        }
                    }
                }
            }    
              if(item.Line_Description__c != null){
                item.Apttus_Config2__Description__c = item.Line_Description__c;
              }
        }
    if(!String.isBlank(strEOSProducts) && ApexPages.currentPage() != null){    //INC0364337
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Product ' + strEOSProducts +' is within 30 days of its end of sale date'));   
        boolEOSError = true;                                                                                                                             //DCP-26583 End --->
    }

  }

    /**
     * @description check if product is subscription proudct
     * @param lineItemMO Line Item sObject
     * @return boolean
     */ 
    private boolean isSubscriptionProduct(Apttus_Config2__LineItem__c soLineItem){
        boolean isSubscription = true;
        //String strProductMaterialClass = soLineItem.Product_Material_Class__c;
        if(soLineItem.Apttus_Config2__PriceType__c == Label.PriceListItemPriceTypeOneTime /*&& (strProductMaterialClass == Label.InstalledProductMaterialClassInstrument || strProductMaterialClass == Label.ProductMaterialClassConsumables || strProductMaterialClass == Label.ProductMaterialClassDocumentTraining || strProductMaterialClass == Label.InstalledProductMaterialClassServices)*/){
            isSubscription = false;
        }
        return isSubscription;
    }
    /**
     * @description check if product is contract
     * @param lineItemMO Line Item sObject
     * @return boolean
     */ 
    private boolean isContractProduct(Apttus_Config2__LineItem__c soLineItem){
        boolean isContract = false;
        List<Product_Sales_Area__c> lstProSalesArea = new ProductSalesAreaSelector().selectByProductAndRTPId(soLineItem.Apttus_Config2__ProductId__c,soLineItem.Sold_To_Sales_Organization__c,soLineItem.Sold_To_Distribution_Channel__c,PRODUCT_SALES_AREA_GROUP);
        isContract = lstProSalesArea.isEmpty() ? false:true;
        return isContract;
    }  

    /**
     * @owner Rohan Chandarana
     * @description Defaulting of Max Samples Allowed (Per kit) cart column
     * @param soLineItem Line Item sObject
     */
    private void updateConsortiaDefaults(Apttus_Config2__LineItem__c soLineItem){
        if(soLineItem.Apttus_Config2__OptionId__c != null){
            soLineItem.Max_Samples_Allowed_Per_kit__c = (soLineItem.Apttus_Config2__OptionId__r.Number_Of_Samples__c * Integer.valueof(soLineItem.Apttus_Config2__OptionId__r.Number_Of_BeadChips_Per_Sample__c)); 
        }else{
            soLineItem.Max_Samples_Allowed_Per_kit__c = soLineItem.Apttus_Config2__ProductId__r.Number_Of_Samples__c * Integer.valueof(soLineItem.Apttus_Config2__ProductId__r.Number_Of_BeadChips_Per_Sample__c);
        }
    }

    
     /**
     * @owner Khushbu Vasani
     * @description open offer max discount value
     * @param setProductId cartId lstStandardLineItems
     */
    private void calculateOpenOfferMaxDiscountPercentage(Set<Id> setProductId, Id cartId,List<Apttus_Config2.LineItem> lstStandardLineItems)
    {
        try 
        {
            Set<string> setMaterialClass = new Set<string>();
            setMaterialClass.add(Label.ProductMaterialClassConsumables);            
            setMaterialClass.add(Label.ProductMaterialClassInstrument);
            setMaterialClass.add(Label.ProductMaterialClassServices);

            List<Product2> listProducts = new List<Product2>(new ProductsSelector().selectProductsForMaterialClassType(setProductId, setMaterialClass));

            if(listProducts.isEmpty())
            {
                return;
            }
            Apttus_Config2__ProductConfiguration__c sObjConfig = new ApttusProductConfigurationsSelector().fetchCart(cartId);
            if(Opportunities.DIRECT_RECORD_TYPES.contains(sObjConfig.Apttus_QPConfig__Proposald__r.Opportunity_Record_Type__c))
            {
                Set<string> setNgnIds = getNGNDetailsForOpenOffer(sObjConfig);
                
                if(!setNgnIds.isEmpty())
                {  
                   
                    List<AccountPricingTiersService.OpenOfferPricingDiscount> listOpenOfferPricingDiscount = new AccountPricingTiersService().getOpenOfferByCustomer(setNgnIds, sObjConfig.Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PricingDate__c);
                    
                    if(listOpenOfferPricingDiscount.isEmpty())
                    {
                        return;
                    }
                
                    AccountPricingTiersService.OpenOfferPricingDiscount openOfferPricingDiscount = listOpenOfferPricingDiscount[0];

                    if(openOfferPricingDiscount != null)
                    {
                        populateOpenOfferDiscountOnLineItems(listProducts, lstStandardLineItems, openOfferPricingDiscount);
                    }                        
                }
            }
            
        } catch (Exception e)
        {
            ApexExceptions.emit(EXCEPTION_LOG_TITLE, e);
        }
    }

    /**
     * @owner Himanshu
     * @description get ngn Of Open offer Account
     * @param Apttus_Config2__ProductConfiguration__c sObjConfig
    */
    private set<String> getNGNDetailsForOpenOffer(Apttus_Config2__ProductConfiguration__c sObjConfig)
    {
        Set<string> setNgnIds = new Set<String>();
        Account objUltimateConsignee = sObjConfig.Apttus_QPConfig__Proposald__r.Ultimate_Consignee__r;
        Account objSoldTo = sObjConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__r;

        string strUcErpNgnNumber = string.isBlank(objUltimateConsignee.National_Group_Number__c) ? objUltimateConsignee.erp_customer_id__C : objUltimateConsignee.National_Group_Number__c;
        string strSoldToErpNgnNumber = string.isBlank(objSoldTo.National_Group_Number__c) ? objSoldTo.erp_customer_id__C : objSoldTo.National_Group_Number__c;

        boolean boolUcOocc = objUltimateConsignee.Open_Offer_Comparison_Customer__c || objUltimateConsignee.Signed_Open_Offer__c;
        boolean boolSoldToOocc = objSoldTo.Open_Offer_Comparison_Customer__c || objSoldTo.Signed_Open_Offer__c;
        boolean boolDiffNgn = strUcErpNgnNumber != strSoldToErpNgnNumber;
        if(boolUcOocc && !boolSoldToOocc && boolDiffNgn ) {
            setNgnIds.add(strUcErpNgnNumber);
        }
        else if(boolSoldToOocc && !boolUcOocc && boolDiffNgn) {
            setNgnIds.add(strSoldToErpNgnNumber);
        }
        else if(boolSoldToOocc && boolUcOocc && !boolDiffNgn) {
            setNgnIds.add(strUcErpNgnNumber);
        }
        
        return setNgnIds;
    }


     /**
     * @owner Khushbu Vasani
     * @description 
     * @param listProducts cartId lstStandardLineItems
     */
    private void populateOpenOfferDiscountOnLineItems(List<product2> listProducts, List<Apttus_Config2.LineItem> lstStandardLineItems, AccountPricingTiersService.OpenOfferPricingDiscount openOfferPricingDiscount)
    {       
        Map<Id, Product2> mapProductIds  = new Map<Id,Product2>(listProducts);
       // Map<string, Product2> mapProductIds = ( Map<string, Product2>)UtilsCollection.getMapOfStringToSObject(listProducts, 'Id',Map<String,Product2>.class );
        for(Apttus_Config2.LineItem standardLineItem : lstStandardLineItems){
            Apttus_Config2__LineItem__c soLineItem = standardLineItem.getLineItemSO();
            if(soLineItem == null)
            {
                continue; 
            }
            if(mapProductIds.keySet().contains(soLineItem.Apttus_Config2__ProductId__c))
            {
                Product2 prod = mapProductIds.get(soLineItem.Apttus_Config2__ProductId__c);
                
                if(prod.Material_Class__c == Label.ProductMaterialClassConsumables)
                {
                    if(openOfferPricingDiscount.categoryToConsumableDiscount != null && openOfferPricingDiscount.categoryToConsumableDiscount.containskey(prod.Open_Offer_Product_Category__c))
                    {
                        soLineItem.Open_Offer_Max__c = openOfferPricingDiscount.categoryToConsumableDiscount.get(prod.Open_Offer_Product_Category__c);
                        
                    }                    
                }
                else if(prod.Material_Class__c == Label.ProductMaterialClassInstrument)
                {
                   
                    if(openOfferPricingDiscount.categoryToInstrumentDiscount != null && openOfferPricingDiscount.categoryToInstrumentDiscount.containskey(prod.Open_Offer_Product_Category__c))
                    {
                        soLineItem.Open_Offer_Max__c = openOfferPricingDiscount.categoryToInstrumentDiscount.get(prod.Open_Offer_Product_Category__c);
                        
                    }
                    
                }
                else{
                                              
                    if(openOfferPricingDiscount.categoryToServicesDiscount != null && openOfferPricingDiscount.categoryToServicesDiscount.containskey(prod.Open_Offer_Product_Category__c))
                    {
                        soLineItem.Open_Offer_Max__c = openOfferPricingDiscount.categoryToServicesDiscount.get(prod.Open_Offer_Product_Category__c);
                    }                    
                }
            }
            
        }
                    
    }
 

}
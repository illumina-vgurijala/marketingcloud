/*@ author       : Satya Swain
* @ date         : 03 July 2018
* @ Description  : DCP 1061 Validation callback class to validate the Shipping in Close Quarter data.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Satya Swain          03 July 2018                      Initial version
* Satya Swain          16 August 2018                    Modified validateCart() for DCP-9106
* Satya Swain          12 September 2018                 Modified validateCart() for DCP-10458
* Kristiyan Petkov     18 October 2018                   Modified validateCart() for DCP-14179
* Kristiyan Petkov     26 October 2018                   Modified validateCart() for DCP-11002
* Indra Ganesan        04 December 2018                  Modified validateCart() for DCP-12936 - To Check Reason For Price Override
* Indra Ganesan        11 January 2018                   Modified as part of DCP-19156 - error message modification
* Saswati Prusty       17th May 2019                     Modified validateCart() for DCP-25196
* Roopal Verma         30 May 2019                       Modified Validate cart for DCP-25322
* Kushgra Desai        13-June-2019                      DCP-25189
* Kushagra Desai       21-June-2019                      DCP-26680 : Addition Checks
* Todd Newman          6 August 2019                     INC0219798 - take quantity into account when comparing dist price and customer price
* Anish Pathak         24 Sept 2019                      DCP-29915 - Added material numbers in error message for SFDC_SALES_BLOCK
* Roopal Verma         28 Aug 2019                       DCP-26583 - Removed End of Sale condition
* Satya Swain          23 April 2021                     TASK0584058 : Modified logic for Shipping In Close Quarter Fields
* Satya Swain          12 July 2021                      INC0330527 : Adding Logic to give priority to price override for calculating Prorated Distributor Net Price  
* Prem Ranjan          25-April-2022                     CodeScan Fix:Avoid Literals in If condition
*  Aman Tyagi           5 April 2022                      CodeScan Fixes
* Iram Malik           14-Jul-2022                        Codescan Fixes: Logic inversion
*/
global class ApttusValidationCallback implements Apttus_Config2.CustomClass.IValidationCallback3 {

    public static final String PAGE_ACTION_PARAMETER = 'pageAction';
    public static final String CHARGE_TYPE_RECURRING = 'Recurring';
    public static final String LINE_STATUS_RENEWED = 'Renewed';
    public static final String UPSELL_SERVICE_CONTRACT_OPPORTUNITY = 'Upsell with Service Contract Renewal';
    public static final String RENEWAL_SERVICE_CONTRACT_OPPORTUNITY = 'Renewal - Service Contract No Upsell';
    public static final String RENEWAL_SOFTWARE_OPPORTUNITY = 'Renewal - Software No Upsell';
    public static final String BLOCKED_FOR_SALES = 'Blocked for Sales';
    public static final String SALES_BLOCK = 'Sales Block';
    public static final String BLOCKED_FOR_SHIPMENT = 'Blocked for Shipment';
    public static final String SFDC_SALES_BLOCK = 'SFDC_SALES_BLOCK';
    public static final String INACTIVE = 'Inactive';
    public static final String CONFIG_TYPE_BUNDLE = 'Bundle';
    public static final String COMMA_VARIABLE = ',  ';
    public static final String DOT_VARIABLE = '.  ';

    public static Boolean booValidatePriceOverride = false;
    public static Boolean boolCartChanges = false;
    public static Boolean boolPriceOverrideChange = false;
    
    private String strInactiveProducts = '';
    private String strProductsUnderSalesBlock = '';
    private String strNonQuotableMaterialProducts = '';
    private String strProductSalesAresUnderSalesBlock = '';
    private String strProductsWithinEndOfSaleDate = '';
    private String strProductsPassedEndOfSaleDate = '';
    public static final String CODE_MA = 'MA';

    public static final String MKTEXTERNAL='Marketing External';
    public static final String MKTINTERNAL='Marketing Internal';
    public static final String INTERNAL='Internal';
    public static final String EXTERNAL='External';

    public static List<String> errorMessagesToEmail = new List<String>();

    private Boolean addErrorMessageOnFailure(Set<String> errorMessages, String message, Boolean failedValidation)
    {
        if (failedValidation)
            errorMessages.add(message);

        return failedValidation;
    }
    

    /**
    * @owner Satya Swain
    * @description Callback to validate the line items in the cart
    * @param cart the cart object to validate
    * @return the validation result
    */
    global Apttus_Config2.CustomClass.ValidationResult validateCart(Apttus_Config2.CustomClass.ActionParams params, Apttus_Config2.ProductConfiguration cart)
    {
        Apttus_Config2.CustomClass.ValidationResult result = new Apttus_Config2.CustomClass.ValidationResult(true);
        List <Apttus_Config2.LineItem> allLines = cart.getLineItems();
        Apttus_Config2__ProductConfiguration__c productConfigSO = cart.getConfigSO();

        if (allLines.size() == 0) return result;

        Set<String> errorMessages = new Set<String>();

        List<Apttus_Config2__LineItem__c> lineitemList = getLineItems(allLines);

        Set<Id> setProductIds = UtilsCollection.getSetOfIds(lineitemList, 'Apttus_Config2__ProductId__c');
        Map<Id, Product2> idToProduct = new Map<Id, Product2>(new ProductsSelector().selectProducts(setProductIds));

        // Validate only if finalize action invoked
        String strPageAction = Apttus_Config2.RuntimeContext.getParameters().get(PAGE_ACTION_PARAMETER);
        if (strPageAction != Label.OpportunityStageFinalize && !Test.isRunningTest())
            return result;

        String strErrorMsgEndDate = '';
        //string strErrorMsgDirectSaleToUC = '';

        for (Apttus_Config2__LineItem__c li : lineitemList)
        {
            Boolean boolConsortia = (li.Quote_Sub_Type__c == System.Label.OpportunityTypeConsortium || li.Quote_Sub_Type__c == System.Label.OpportunityTypeReorderConsortiumConsumable);

            if (!boolConsortia)
            {
                if (idToProduct.containsKey(li.Apttus_Config2__ProductId__c) && idToProduct.get(li.Apttus_Config2__ProductId__c).Custom_Product__c)
                {
                    if (idToProduct.get(li.Apttus_Config2__ProductId__c).Line_Of_Business_Code__c == CODE_MA){
                        addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Custom_Beadchip_Missing,
                            String.isBlank(li.Beadchip_Part_Number__c)
                        );
                        addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Custom_Beadchip_Missing,
                            String.isBlank(li.Project_Id__c)
                        );   
                    }
                    else
                    {
                        addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Custom_Project_Id_Missing,
                            String.isBlank(li.Project_Id__c) && idToProduct.get(li.Apttus_Config2__ProductId__c).Line_Of_Business_Code__c == 'SQ'
                        );
                    }                                   
                }

                //if (!Test.isRunningTest()){
                // Optimized condition DCP-26680
                System.debug('@@@ Inside Validation Callback,Is_SAP_Pricing_Completed__c value: ' + productConfigSO.Is_SAP_Pricing_Completed__c);
                addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_SAP_Pricing_Not_Completed,
                    !productConfigSO.Is_SAP_Pricing_Completed__c || productConfigSO.GT_Check_Pending_Count__c>0
                );
                //}

                if (li.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c == true)
                {
                    Decimal decListPrice = li.Price_Override__c == NULL ? ((li.List_Price__c == NULL) ? 0 : li.List_Price__c) : li.Price_Override__c;
                    Decimal decPremium = (li.Customer_Premium_Amount_Per_Unit__c == NULL) ? 0 : li.Customer_Premium_Amount_Per_Unit__c;
                    Decimal decCustomerNetPrice = (li.Customer_Net_Price__c == NULL) ? 0 : li.Customer_Net_Price__c;
                    Decimal decDistributorNetPrice = (li.Apttus_Config2__NetPrice__c == NULL) ? 0 : li.Apttus_Config2__NetPrice__c;

                    Decimal decYearlyCustomerNetPrice = decListPrice + decPremium;
                    Decimal decFactor = (decYearlyCustomerNetPrice == 0) ? 0 : (decCustomerNetPrice / decYearlyCustomerNetPrice) / li.Apttus_Config2__Quantity__c ;
                    // INC0219798 - take quantity into account for this comparison
                    Decimal decProratedDistributorNetPrice = decDistributorNetPrice * decFactor;

                    addErrorMessageOnFailure(errorMessages,Label.UI_ErrorMessage_CustomerPrice_Higher_Than_Distributor_Net_Price,
                        li.Customer_Net_Price__c < decProratedDistributorNetPrice
                    );                    
                }
            }
            //TASK0584058 : Throw error only if all the shipping in close quarter fields are blank
            Boolean boolAllShippingFieldsBlank = String.isBlank(String.valueOf(li.Shipping_In_Close_Quarter__c)) && String.isBlank(String.valueOf(li.Shipping_In_1Q_After_Close_Quarter__c)) && String.isBlank(String.valueOf(li.Shipping_In_2Q_After_Close_Quarter__c));
            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_BlankShippingInCloseQuarter,
                li.Apttus_Config2__LineStatus__c != Label.LineItemLineStatusCancelled && boolAllShippingFieldsBlank && li.Apttus_Config2__OptionId__c != null
            );

            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_BlankShippingInCloseQuarter,
                li.Apttus_Config2__LineStatus__c != Label.LineItemLineStatusCancelled && boolAllShippingFieldsBlank && idToProduct.containsKey(li.Apttus_Config2__ProductId__c) && idToProduct.get(li.Apttus_Config2__ProductId__c).Apttus_Config2__ConfigurationType__c!=CONFIG_TYPE_BUNDLE && li.Apttus_Config2__OptionId__c == null
            );

            Decimal decTotalShippingCloseQuarterValue = (li.Shipping_In_Close_Quarter__c == null ? 0 : li.Shipping_In_Close_Quarter__c) + (li.Shipping_In_1Q_After_Close_Quarter__c == null ? 0 : li.Shipping_In_1Q_After_Close_Quarter__c)  + (li.Shipping_In_2Q_After_Close_Quarter__c == null ? 0 : li.Shipping_In_2Q_After_Close_Quarter__c);
            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_ShippingInCloseQuarterGreaterThanQuantity,
                decTotalShippingCloseQuarterValue > li.Apttus_Config2__Quantity__c
            );

            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Renewal_Product_Blank_StartDate_EndDate,
                (li.Apttus_Config2__StartDate__c == null || li.Apttus_Config2__EndDate__c == null) && li.Apttus_Config2__PriceType__c == CHARGE_TYPE_RECURRING
            );

            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_CostCenterBlank,
                li.Applied_Discount_Details__c != null && li.Applied_Discount_Details__c.contains(Label.ApprovalStepNameSalesDiscretionary) && li.Applied_Discount_Percentage__c == 100 && li.Cost_Center__c == null
            );

            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_SoftwareTypeBlank,
                li.Product_Material_Class__c == Label.ProductMaterialClassInformaticsSoftware && li.Software_Type__c == null
            );

            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_DiscountGreaterThanHundredPercent,
                li.Applied_Discount_Details__c !=null && li.Applied_Discount_Details__c.contains(Label.ApprovalStepNameSalesDiscretionary) && li.Applied_Discount_Percentage__c > 100 && li.Sales_Discretionary_Type__c != NULL
            );

            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_BlankSalesDiscretionaryType,
                li.Sales_Discretionary_Discount__c != null && li.Sales_Discretionary_Type__c == null
            );
            
            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_RenewalStartDate,
                li.Apttus_Config2__AssetLineItemId__c != null && li.Apttus_Config2__LineStatus__c == LINE_STATUS_RENEWED && li.Apttus_Config2__StartDate__c <= li.AssetLineItem_End_Date__c
                && (li.Quote_Sub_Type__c == RENEWAL_SOFTWARE_OPPORTUNITY || li.Quote_Sub_Type__c == RENEWAL_SERVICE_CONTRACT_OPPORTUNITY || li.Quote_Sub_Type__c == UPSELL_SERVICE_CONTRACT_OPPORTUNITY)
            );

            /*
            *   Developer: Roopal Verma
            *   Description: DCP-25322: Force user to Validate if certain line item field values are changed
            */ 
            // logic to check if line items have been created post Validate and then force user to Click on Validate
            // DCP-25189 - Check any change in cart after validate
            // DCP-26680
            //if (!Test.isRunningTest()){
            System.debug('--- Changes diff----');
            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Prompt_Check_Price,li.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c == true && productConfigSO.Apttus_Config2__NumberOfItems__c != productConfigSO.Number_Of_Check_Line_Items__c);
            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Prompt_Validate,li.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c != true && productConfigSO.Apttus_Config2__NumberOfItems__c != productConfigSO.Number_Of_Check_Line_Items__c);

            Map<String,String> mapOldFieldValueCheckPrice = new Map<String,String>();
            if (li.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c && li.Line_Item_Old_Values__c != null)
                mapOldFieldValueCheckPrice = (Map<String,String>)JSON.deserialize(li.Line_Item_Old_Values__c,Map<String,String>.class);

            Map<String,String> mapOldFieldValueValidate;
            if (li.Line_Item_Validate_Old__c != null) 
                mapOldFieldValueValidate = (Map<String,String>)JSON.deserialize(li.Line_Item_Validate_Old__c,Map<String,String>.class);

            if (li.Line_Item_Validate_Old__c == null && li.Line_Item_Old_Values__c != null){
                system.debug('--- Changes diff123----');
                boolCartChanges = true;
                addErrorMessageOnFailure(errorMessages,Label.UI_ErrorMessage_Prompt_Validate,true);
            }
            else if (li.Line_Item_Validate_Old__c != null && li.Line_Item_Old_Values__c != null && li.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c)
            {
                System.debug('--- Changes diff456----');
                for (String keyvalue : mapOldFieldValueCheckPrice.keySet())
                {
                    if (mapOldFieldValueValidate.get(keyvalue) != String.valueOf(li.get(keyvalue)))
                    {
                        addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Prompt_Check_Price,true);
                        boolCartChanges = true;
                        break;
                    }
                }
            }

            if (!boolCartChanges)
            {
                System.debug('--- Changes diff789----'+mapOldFieldValueValidate);
                if (mapOldFieldValueValidate != null && !mapOldFieldValueValidate.isEmpty())
                {
                    for (String keyvalue : mapOldFieldValueValidate.keySet())
                    {
                        System.debug('--- Changes diff789 inside----');
                        System.debug('----'+String.valueOf(li.get(keyvalue)));
                        if (mapOldFieldValueValidate.get(keyvalue) != String.valueOf(li.get(keyvalue)))
                        {
                            addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Prompt_Validate,true);
                            boolCartChanges = true;
                            break;
                        }
                    }
                }
                System.debug('--- Out Changes789----');
            }
            //}
        }
        List<Apttus_Config2__LineItem__c> lstItems = new List<Apttus_Config2__LineItem__c>();
        lstItems=[Select Id,Trade_In_Type__c,Promotion_1__r.Marketing_Trade_In__c,Promotion_2__r.Marketing_Trade_In__c,Promotion_3__r.Marketing_Trade_In__c From Apttus_Config2__LineItem__c WHERE ID IN :lineitemList ];
        List<Apttus_Config2__LineItem__c> lstTradeinUpdate = new List<Apttus_Config2__LineItem__c>();
        for(Apttus_Config2__LineItem__c temp2:lstItems){
            if(temp2.Promotion_1__r.Marketing_Trade_In__c==INTERNAL || temp2.Promotion_2__r.Marketing_Trade_In__c==INTERNAL || temp2.Promotion_3__r.Marketing_Trade_In__c ==INTERNAL)
            temp2.Trade_In_Type__c = MKTINTERNAL;
            else if(temp2.Promotion_1__r.Marketing_Trade_In__c==EXTERNAL || temp2.Promotion_2__r.Marketing_Trade_In__c ==EXTERNAL || temp2.Promotion_3__r.Marketing_Trade_In__c==EXTERNAL)  
            temp2.Trade_In_Type__c = MKTEXTERNAL; 
            else if(temp2.Promotion_1__r.Marketing_Trade_In__c==null && temp2.Promotion_2__r.Marketing_Trade_In__c ==null && temp2.Promotion_3__r.Marketing_Trade_In__c==null && (temp2.Trade_In_Type__c== MKTEXTERNAL || temp2.Trade_In_Type__c== MKTINTERNAL )) 
            temp2.Trade_In_Type__c = null;          
            lstTradeinUpdate.add(temp2);
        }  
        update lstTradeinUpdate; 

        System.debug('--- Changes 1----');
        Map<String, Product_Sales_Area__c> mapProductIdToProductSalesArea = new Map<String, Product_Sales_Area__c>();
        List<Product_Sales_Area__c> listOfProductSalesArea = new List<Product_Sales_Area__c>(new ProductSalesAreaSelector().selectByProductId(setProductIds));
        for (Product_Sales_Area__c productSalesArea : listOfProductSalesArea)
        {
            mapProductIdToProductSalesArea.put(productSalesArea.Product__c, productSalesArea);
        }
        System.debug('--- Changes 2----'+mapProductIdToProductSalesArea);

        for (Apttus_Config2__LineItem__c li : lineitemList)
        {
            System.debug('--- Changes 3----'+li);
            addErrorMessageOnFailure(errorMessages, Label.UI_Text_Reason_For_Price_Override_Error,
                li.Price_Override__c != NULL && String.ISBLANK(li.Reason_For_Price_Override__c)
            );

            if (li.SAP_Cross_Plant_Status__c == INACTIVE && !errorMessages.contains(Label.UI_ErrorMessage_Inactive_Product) && !strInactiveProducts.contains(li.Apttus_Config2__ProductId__r.Name))
                strInactiveProducts += li.Apttus_Config2__ProductId__r.Name + ', ';

            System.debug('--- Changes 4----'+li);
            if ((li.Cross_Distribution_Chain_Status__c == BLOCKED_FOR_SALES ||
                 li.Cross_Distribution_Chain_Status__c == SALES_BLOCK || li.Cross_Distribution_Chain_Status__c == BLOCKED_FOR_SHIPMENT) &&
                !strProductsUnderSalesBlock.contains(li.Apttus_Config2__ProductId__r.Name)
            )
                strProductsUnderSalesBlock += li.Apttus_Config2__ProductId__r.Name + ', ';
            System.debug('--- Changes 5----'+strProductsUnderSalesBlock);

            if (li.SFDC_Block__c != NULL && li.SFDC_Block__c.Contains(SFDC_SALES_BLOCK) && !strNonQuotableMaterialProducts.contains(li.Apttus_Config2__ProductId__r.ProductCode)){//DCP-29915 - Changed ProductId__r.Name to ProductId__r.ProductCode
                if(strNonQuotableMaterialProducts != ''){//DCP-29915 - Introduced if else block to avoid comma in the end
                    strNonQuotableMaterialProducts += ','+li.Apttus_Config2__ProductId__r.ProductCode;
                }else{
                    strNonQuotableMaterialProducts += li.Apttus_Config2__ProductId__r.ProductCode;
                }
            }

            if (mapProductIdToProductSalesArea.get(li.Apttus_Config2__ProductId__c) != NULL &&
                mapProductIdToProductSalesArea.get(li.Apttus_Config2__ProductId__c).Sales_Organization__c == li.Sold_To_Sales_Organization__c &&
                mapProductIdToProductSalesArea.get(li.Apttus_Config2__ProductId__c).Distribution_Channel__c == li.Sold_To_Distribution_Channel__c &&
                (mapProductIdToProductSalesArea.get(li.Apttus_Config2__ProductId__c).Distribution_Chain_Specific_Status__c == BLOCKED_FOR_SALES ||
                 mapProductIdToProductSalesArea.get(li.Apttus_Config2__ProductId__c).Distribution_Chain_Specific_Status__c == SALES_BLOCK ||
                 mapProductIdToProductSalesArea.get(li.Apttus_Config2__ProductId__c).Distribution_Chain_Specific_Status__c == BLOCKED_FOR_SHIPMENT) &&
                !strProductSalesAresUnderSalesBlock.contains(li.Apttus_Config2__ProductId__r.Name)
            )
                strProductSalesAresUnderSalesBlock += li.Apttus_Config2__ProductId__r.Name + ', ';

            if (li.End_Of_Service_Date__c <= li.Quote_Created_Date__c + 30 && !strProductsWithinEndOfSaleDate.contains(li.Apttus_Config2__ProductId__r.Name))//DCP-26583 Removed End of Sale condition
                strProductsWithinEndOfSaleDate += li.Apttus_Config2__ProductId__r.Name + ', ';

            /*Saswati : DCP - 10444 
            Functionality : Error message on error log with material number if End of Sale date/End Of Service Date is in the past. 
            */
            if (li.Apttus_Config2__ProductId__c!= null && li.Apttus_Config2__OptionId__c == null)
            {
                System.debug('--- Changes 6----'+li.Apttus_Config2__ProductId__c+' '+li.Apttus_Config2__OptionId__c);
                if ((li.Apttus_Config2__ProductId__r.End_Of_Sale_Date__c < Date.today())&& !strProductsPassedEndOfSaleDate.contains(li.Apttus_Config2__ProductId__r.Name)  && (li.Apttus_Config2__ProductId__r.End_Of_Service_Date__c >= Date.today()))
                {
                    strProductsPassedEndOfSaleDate += li.Apttus_Config2__ProductId__r.Name + ', ';  
                    strErrorMsgEndDate += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.Name + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.Material_Number__c + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.End_Of_Sale_Date__c.format() +COMMA_VARIABLE + DOT_VARIABLE ;
                }
                else if ((li.Apttus_Config2__ProductId__r.End_Of_Service_Date__c < Date.today())&& !strProductsPassedEndOfSaleDate.contains(li.Apttus_Config2__ProductId__r.Name)  && (li.Apttus_Config2__ProductId__r.End_Of_Sale_Date__c >= Date.today()))
                {
                    strProductsPassedEndOfSaleDate += li.Apttus_Config2__ProductId__r.Name + ', ';  
                    strErrorMsgEndDate += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.Name + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.Material_Number__c + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.End_Of_Service_Date__c.format() +COMMA_VARIABLE + DOT_VARIABLE ;
                }
                else if ((li.Apttus_Config2__ProductId__r.End_Of_Sale_Date__c < Date.today()) && (li.Apttus_Config2__ProductId__r.End_Of_Service_Date__c < Date.today()) && !strProductsPassedEndOfSaleDate.contains(li.Apttus_Config2__ProductId__r.Name))
                {
                    strProductsPassedEndOfSaleDate += li.Apttus_Config2__ProductId__r.Name + ', ';
                    strErrorMsgEndDate += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.Name  + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.Material_Number__c + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.End_Of_Sale_Date__c.format() + COMMA_VARIABLE + li.Apttus_Config2__ProductId__r.End_Of_Service_Date__c.format() +', ' + DOT_VARIABLE ; 
                }
                System.debug('--- Changes 7----'+li.Apttus_Config2__ProductId__c+' '+li.Apttus_Config2__OptionId__c);
            }

            if (li.Apttus_Config2__ProductId__c!= null && li.Apttus_Config2__OptionId__c != null)
            {
                System.debug('--- Changes 8----'+li.Apttus_Config2__OptionId__r.End_Of_Sale_Date__c+' '+li.Apttus_Config2__OptionId__r.End_Of_Service_Date__c);
                if ((li.Apttus_Config2__OptionId__r.End_Of_Sale_Date__c < Date.today())&& !strProductsPassedEndOfSaleDate.contains(li.Apttus_Config2__OptionId__r.Name)  && (li.Apttus_Config2__OptionId__r.End_Of_Service_Date__c >= Date.today()))
                {
                    strProductsPassedEndOfSaleDate += li.Apttus_Config2__OptionId__r.Name + ', ';  
                    strErrorMsgEndDate += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + li.Apttus_Config2__OptionId__r.Name + COMMA_VARIABLE + li.Apttus_Config2__OptionId__r.Material_Number__c + COMMA_VARIABLE + li.End_Of_Sale_Date__c.format() +COMMA_VARIABLE + DOT_VARIABLE ;
                }
                else if ((li.Apttus_Config2__OptionId__r.End_Of_Service_Date__c < Date.today())&& !strProductsPassedEndOfSaleDate.contains(li.Apttus_Config2__OptionId__r.Name)  && (li.Apttus_Config2__OptionId__r.End_Of_Sale_Date__c >= Date.today()))
                {
                    strProductsPassedEndOfSaleDate += li.Apttus_Config2__OptionId__r.Name + ', ';  
                    strErrorMsgEndDate += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + li.Apttus_Config2__OptionId__r.Name + COMMA_VARIABLE + li.Apttus_Config2__OptionId__r.Material_Number__c + COMMA_VARIABLE + li.End_Of_Service_Date__c.format() + COMMA_VARIABLE + DOT_VARIABLE ;
                }
                else if ((li.Apttus_Config2__OptionId__r.End_Of_Sale_Date__c < Date.today()) && (li.Apttus_Config2__OptionId__r.End_Of_Service_Date__c < Date.today()) && !strProductsPassedEndOfSaleDate.contains(li.Apttus_Config2__OptionId__r.Name))
                {
                    strProductsPassedEndOfSaleDate += li.Apttus_Config2__OptionId__r.Name + ', ';
                    strErrorMsgEndDate += Label.UI_AddErrorForEndOfSaleDateOrServiceDate + COMMA_VARIABLE + li.Apttus_Config2__OptionId__r.Name  + COMMA_VARIABLE + li.Apttus_Config2__OptionId__r.Material_Number__c + COMMA_VARIABLE + li.Apttus_Config2__OptionId__r.End_Of_Sale_Date__c.format() + COMMA_VARIABLE + li.Apttus_Config2__OptionId__r.End_Of_Service_Date__c.format() + COMMA_VARIABLE + DOT_VARIABLE ;  
                }
                System.debug('--- Changes 9----');
            }
        }

        System.debug('--- Changes 10----');
        addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Inactive_Product,
            strInactiveProducts != ''
        );

        addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Product_Material_Cannot_Be_Quoted +' ' +strNonQuotableMaterialProducts+' '+ Label.UI_ErrorMessage_Product_Material_Cannot_Be_Quoted2,
            strNonQuotableMaterialProducts != ''
        );//DCP-29915 - Split the label into 2 parts and introduced dynamic material numbers

        addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Product_Under_Sales_Block,
            strProductsUnderSalesBlock != '' || strProductSalesAresUnderSalesBlock != ''
        );

        addErrorMessageOnFailure(errorMessages,strErrorMsgEndDate,
            strProductsPassedEndOfSaleDate != ''
        );

        addErrorMessageOnFailure(errorMessages, Label.UI_ErrorMessage_Product_Within_End_Of_Sale_Date,
            strProductsWithinEndOfSaleDate != ''
        );
       
        System.debug('--- Changes 11----');

        if (errorMessages.size() > 0)
        {
            System.debug('--- Changes 12----');
            result.isSuccess = false;
            for (String message : errorMessages)
               { result.Messages.add(new ApexPages.Message(ApexPages.Severity.Error, message));
                errorMessagesToEmail.add(message);
               }
        }
        return result;
    }

    /**
    * @owner Satya Swain
    * @description Callback to validate the given list ramp line items, not being used by story DCP-1061 functionality but need to be implemented as methods present in the interface class
    * @param cart the cart object associated with the ramp line items
    * @param rampLineItems the list of ramp line items
    * @return the validation result
    */
    global Apttus_Config2.CustomClass.ValidationResult validateRampLineItems(Apttus_Config2.CustomClass.ActionParams params, Apttus_Config2.ProductConfiguration cart, List<Apttus_Config2.LineItem> rampLineItems)
    {
        Apttus_Config2.CustomClass.ValidationResult result = new Apttus_Config2.CustomClass.ValidationResult(true);
        return result;
    }

    /**
    * @owner Satya Swain
    * @description Gets the list of product line items associated with Cart for DCP-1061
    * @param cart the cart object
    * @return the list of line item objects
    */
    private static List<Apttus_Config2__LineItem__C> getLineItems(List<Apttus_Config2.LineItem> allLines)
    {
        List<Apttus_Config2__LineItem__C> lineItems = new List<Apttus_Config2__LineItem__C>();
        for (Apttus_Config2.LineItem lineItemMO : allLines)
        {
            lineItems.add(lineItemMO.getLineItemSO());
        }
        return lineItems;
    }

    /**
    * @owner Satya Swain
    * @description Callback to validate the given list of asset items, not being used by story DCP-1061 functionality but need to be implemented as methods present in the interface class
    * @param cart the cart object associated with the asset items
    * @param assetItems the list of asset items
    * @return the validation result
    */
    global Apttus_Config2.CustomClass.ValidationResult validateAssetItems(Apttus_Config2.CustomClass.ActionParams params, Apttus_Config2.ProductConfiguration cart, List<Apttus_Config2__TempRenew__c> assetItems)
    {
        return new Apttus_Config2.CustomClass.ValidationResult(true);
    }

}
/**
*    @author Todd Newman
*    @date   2021-12-13
*    @description    DCP-50961: This class contains logic for handling methods to calculate Discounts on agreement lines
*    90% code coverage : TestApprovalsAgreementLineDiscount, TestApprovalsAgreementLineMFN, TestApprovalsAgreementLineMaterialGroup, TestApprovalsAgreemetLineMaterialNumber
*    75% code coverage : TestApprovalsAgreementLineDiscount, TestApprovalsAgreementLineMFN, TestApprovalsAgreementLineMaterialGroup, TestApprovalsAgreemetLineMaterialNumber
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-12-13            Initial Version
*         Biswajeet                   2022-09-05            [CMSI-211]Istrumentation of class
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsAgreementLinePriceCalculator {

    private final Approvals.SupportData supportData;

    private static final String DIVISION_DIRECT = '00';
    private static final Integer SCALE_FACTOR = 2;
    private static final String DISCOUNT_FIXED_PRICE = 'Fixed Price';
    private static final String DISCOUNT_AMOUNT = 'Discount Amount';
    private static final String DISCOUNT_PERCENT = '% Discount';
    private static final Integer MAX_DISCOUNT = 100;
   

    /* constructor */
    public ApprovalsAgreementLinePriceCalculator(Approvals.SupportData supportData) {
      
        this.supportData = supportData;
    }

    /*
    *   @description: this method is used to calculate the discounts added for different discount types 
    *   DCP-50961
    *   @params: Apttus__AgreementLineItem__c
    */
    public void calculate(Apttus__AgreementLineItem__c agreementLine)
    {
        if (agreementLine.Discount__c == null) { return; }

        String aliErpKey = String.valueOf(agreementLine.Line_Type__c)
            + String.valueOf(agreementLine.Discount_Type__c)
            + String.valueOf(agreementLine.RecordTypeId)
            + calculateSalesAreaErpKey(agreementLine);

        Boolean isPliSupportDataPresent = supportData.aliToAccountSalesArea.containsKey(aliErpKey) && !supportData.priceListItems.isEmpty();

        Apttus_Config2__PriceListItem__c objpli = isPliSupportDataPresent
            ? getPriceListItem(aliErpKey, agreementLine)
            : null;

        Decimal discountResult = calculateDiscountResult(agreementLine, objpli);
        ilib_LogEvent.message('discountResult'+discountResult);    //CMSI-211

        populatePriceFields(agreementLine, objpli, discountResult);
        addPricingErrorsToLine(agreementLine, objpli, discountResult);

        ilib_LogEvent.message('agreementLine -- '+agreementLine); //CMSI-211
    }

    private Decimal calculateDiscountResult(Apttus__AgreementLineItem__c agreementLine, Apttus_Config2__PriceListItem__c objpli)
    {
        Decimal discountResult = null;

        Integer scale = SCALE_FACTOR;

        if (objpli != null && (objpli.Apttus_Config2__ListPrice__c != 0 || agreementLine.Discount_Type__c == DISCOUNT_PERCENT))
        {
            if (agreementLine.Discount_Type__c == DISCOUNT_AMOUNT)
            {
                discountResult = ((agreementLine.Discount__c/objpli.Apttus_Config2__ListPrice__c) * 100).setscale(scale);
            }
            else if (agreementLine.Discount_Type__c == DISCOUNT_FIXED_PRICE)
            {                
                discountResult = (((objpli.Apttus_Config2__ListPrice__c - agreementLine.Discount__c) / objpli.Apttus_Config2__ListPrice__c) * 100).setscale(scale);
            }
            else
            {                
                discountResult = agreementLine.Discount__c;
            }
        }
        ilib_LogEvent.message('discountResult'+discountResult);                 //CMSI-211
        return discountResult;
    }

    private void populatePriceFields(Apttus__AgreementLineItem__c agreementLine, Apttus_Config2__PriceListItem__c objpli, Decimal discountResult)
    {
        Integer scale = SCALE_FACTOR;

        if (discountResult == null)
        {
            agreementLine.Discount_In_Percent__c = agreementLine.Discount__c;
        }
        else
        {
            if (agreementLine.Discount_Type__c == DISCOUNT_AMOUNT)
            {
                agreementLine.Discount_Amount__c = agreementLine.Discount__c.setscale(scale);
                agreementLine.Customer_Price__c = (objpli.Apttus_Config2__ListPrice__c - agreementLine.Discount_Amount__c).setscale(scale);              
            }
            else if (agreementLine.Discount_Type__c == DISCOUNT_FIXED_PRICE)
            {
                agreementLine.Discount_Amount__c = (objpli.Apttus_Config2__ListPrice__c - agreementLine.Discount__c).setscale(scale);
                agreementLine.Customer_Price__c = agreementLine.Discount__c.setscale(scale);                   
            }
            else
            {
                agreementLine.Discount_Amount__c = ((agreementLine.Discount__c * objpli.Apttus_Config2__ListPrice__c)/100).setscale(scale);
                agreementLine.Customer_Price__c = (objpli.Apttus_Config2__ListPrice__c - agreementLine.Discount_Amount__c).setscale(scale);   
            }

            agreementLine.Apttus__ListPrice__c = objpli.Apttus_Config2__ListPrice__c.setscale(scale); 

            if (discountResult <= MAX_DISCOUNT)
            {
                agreementLine.Discount_In_Percent__c = discountResult;
            }
        }
    }

    private void addPricingErrorsToLine(Apttus__AgreementLineItem__c agreementLine, Apttus_Config2__PriceListItem__c objpli, Decimal discountResult)
    {
        Boolean isListPriceZero = getIsListPriceZero(agreementLine, objpli);

        // TODO: this error looks suspiciously the same as 10 lines down, confirm
        if (objpli != null && objpli.Apttus_Config2__ListPrice__c == 0 && agreementLine.Discount_Type__c != DISCOUNT_PERCENT)
        {
            agreementLine.addError(System.Label.UI_Error_AgreementLineItem_ListPriceZero.replace('Material Number(s)', agreementLine.Material_Number__c));
        }

        if (discountResult == null)
        {
            if (agreementLine.Discount_Type__c == DISCOUNT_PERCENT && agreementLine.Discount__c > MAX_DISCOUNT)
            {
                agreementLine.addError(System.Label.UI_Error_AgreementLineItem_DiscountMoreThan100Percent);
            }
            else if (agreementLine.Apttus__ProductId__c != null && !isListPriceZero && agreementLine.Discount_Type__c != DISCOUNT_PERCENT)
            {
                agreementLine.addError(System.Label.UI_Error_AgreementLineItem_NoActivePriceListFound.replace('Material Number(s)', agreementLine.Material_Number__c));
            }
            
        }
        else
        {
            if (discountResult > MAX_DISCOUNT) {
                agreementLine.addError(System.Label.UI_Error_AgreementLineItem_DiscountMoreThan100Percent);
            }
        }
    }

    private Boolean getIsListPriceZero(Apttus__AgreementLineItem__c agreementLine, Apttus_Config2__PriceListItem__c objpli)
    {
        return objpli != null
               && objpli.Apttus_Config2__ListPrice__c == 0
               && agreementLine.Discount_Type__c != DISCOUNT_PERCENT;
    }

    private String calculateSalesAreaErpKey(Apttus__AgreementLineItem__c agreementLine)
    {
        String salesAreaErpKey = null;
        if(Approvals.lineTypeForApprovals.contains(agreementLine.Line_Type__c) || Approvals.lineTypeForApprovals.contains(agreementLine.Line_Type_1__c) && supportData.idToAgreement.containskey(agreementLine.Apttus__AgreementId__c)) 
        {
            ilib_LogEvent.message('Map contains Agreement Id for Price Group Check ');
            salesAreaErpKey = supportData.idToAgreement.get(agreementLine.Apttus__AgreementId__c).Account_ERP_Number__c +'_' + agreementLine.Sales_Org__c + agreementLine.Distribution_Channel__c + DIVISION_DIRECT;
        }
        else
        {
            salesAreaErpKey = agreementLine.Customer_ERP_Number__c +'_' + agreementLine.Sales_Org__c + agreementLine.Distribution_Channel__c + DIVISION_DIRECT;
        }
        ilib_LogEvent.message('salesAreaErpKey :'+salesAreaErpKey);             //CMSI-211
        return salesAreaErpKey;
    }

    private Apttus_Config2__PriceListItem__c getPriceListItem(String keyAliToErpSalesId, Apttus__AgreementLineItem__c ali){
        Id productId = ali.Apttus__ProductId__c;
        Apttus_Config2__PriceListItem__c selectedPricelist = null;
        Date startDate=ali.Apttus_CMConfig__StartDate__c<System.today()?System.today():ali.Apttus_CMConfig__StartDate__c;
        ilib_LogEvent.message('supportData.productIdToPriceListItem '+supportData.productIdToPriceListItem);            //CMSI-211
        ilib_LogEvent.message('supportData.aliToAccountSalesArea '+supportData.aliToAccountSalesArea);                  //CMSI-211

        if(!supportData.productIdToPriceListItem.containskey(productId)
        ||!supportData.productIdToPriceListItem.get(productId).containskey(supportData.aliToAccountSalesArea.get(keyAliToErpSalesId).Price_List__c))
        {
            return null;
        }
        List<Apttus_Config2__PriceListItem__c> lstPLI=supportData.productIdToPriceListItem.get(productId).get(supportData.aliToAccountSalesArea.get(keyAliToErpSalesId).Price_List__c);
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
        return selectedPricelist;
    }

    private Date dateTimeToDate(DateTime objDateTime)
    {
        return date.newinstance(objDateTime.year(), objDateTime.month(), objDateTime.day());
    }

}

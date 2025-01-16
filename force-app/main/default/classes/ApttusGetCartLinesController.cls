/**
 * @author Rahul Sharma
 * @date   04-Apr-2019
 * @description   PCP- Selection of Products/Cart Lines
 * Modification Log:
 *  --------------------------------------------------------------------------------------------------
 *   Developer                Date                Description                                                  
 *   Rahul Sharma          04-Apr-2019          Original Version
 *   Roopal                04-Oct-2019          Added with sharing for checkmarx fix
 *   Satya Swain           25-Sep-2019          DCP-30062: SonarQube Fixes done
 *   Ashwin Kumar          25-May-2021          INC0321438 - ApttusLineItemsSelector.selectLineItemsByConfigId param updated from Id to Set<Id>
 *   Nesar Mohan           01-Apr-2022          Codescan Fix
 * ---------------------------------------------------------------------------------------------------
 **/
public with sharing class ApttusGetCartLinesController {

    public static final String CONFIGID = 'Id';
    public static final String CONFIGREQUESTID = 'configRequestId';
    public static final String FLOW = 'flow';
    public static final String BUSINESSOBJECTID = 'businessObjectId';
    public String strConfigId;
    public string strConfigRequestId;
    public string strFlow;
    public String strBusinessObjectId;
    public List<Apttus_Config2__LineItem__c> selectedProductsList {get; set;}

    Public List<ProductsWrapper> lstProductsWrapper;
    Map<Id, Apttus_Config2__LineItem__c> mapSelectedProducts = new Map<Id, Apttus_Config2__LineItem__c>();

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Constructor of the class to initialize certain variables.
    */

    public ApttusGetCartLinesController() {
        strConfigId = ApexPages.CurrentPage().getParameters().get(CONFIGID).escapeHtml4();
        // modified by Satya as part of DCP-30062
        strConfigRequestId = ApexPages.currentpage().getparameters().get(CONFIGREQUESTID) == null ? null : ApexPages.currentpage().getparameters().get(CONFIGREQUESTID).escapeHtml4();
        strFlow = ApexPages.currentpage().getparameters().get(FLOW).escapeHtml4();
        strBusinessObjectId = ApexPages.currentpage().getparameters().get(BUSINESSOBJECTID).escapeHtml4();
        lstProductsWrapper = new List<ProductsWrapper>();
        for (Apttus_Config2__LineItem__c li : new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id> {strConfigId})) {   //INC0321438
             if (!mapSelectedProducts.containsKey(li.id)) {
                lstProductsWrapper.add(new ProductsWrapper(li, true));
            }
        }
        getProducts();
    }

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Method to return customized pageReference
    *  @Param       : None
    *  @Return      : PageReference
    */
    public PageReference redirectToCart(){
        PageReference cartPage = Page.Apttus_Config2__Cart;
        cartPage.getParameters().put(CONFIGID, strConfigId);
        cartPage.getParameters().put(CONFIGREQUESTID, strConfigRequestId);
        cartPage.getParameters().put(FLOW, strFlow);
        cartPage.getParameters().put(BUSINESSOBJECTID, strBusinessObjectId);
        return cartPage;
    }

    public ApexPages.StandardSetController con {

        get {
            if (con == null) {
                List<Apttus_Config2__LineItem__c> lstCartLines = new List<Apttus_Config2__LineItem__c>(new ApttusLineItemsSelector().selectLineItemsByConfigId(new Set<Id> {strConfigId}));   //INC0321438
                con = new ApexPages.StandardSetController(lstCartLines);
                con.setPageSize(Integer.valueOf(Label.CartLinesPageSize));
            }
            return con;
        }
        set;
    }

    /*
    *  @author      : Rahul Sharma
    *  @description : Apply sales discretionery discount from suggested sales discount 
    *  @Param       : None
    *  @Return      : PageReference
    */

    public PageReference apply() {
        getSelectedProducts();
        selectedProductsList = mapSelectedProducts.values();
        System.debug('selectedProductsList:'+selectedProductsList);
        
        List<Apttus_Config2__LineItem__c> lstUpdateLineItem = new List<Apttus_Config2__LineItem__c>();

        for(Apttus_Config2__LineItem__c objLine: selectedProductsList){
            System.debug('objLine:'+objLine);
            if(String.isBlank(objLine.Suggested_Sales_Discount_Percentage__c) || objLine.Suggested_Sales_Discount_Percentage__c=='NA')
                continue;
            if(String.isBlank(objLine.Sales_Discretionary_Type__c) || objLine.Sales_Discretionary_Type__c == Label.LineItemSalesDiscretionaryTypePercentageDiscount)
            {
                System.debug('Entering Apply %');
                objLine.Sales_Discretionary_Discount__c = Decimal.valueOf(objLine.Suggested_Sales_Discount_Percentage__c);
                objLine.Global_Trade_Block__c = false;
                if(String.isBlank(objLine.Sales_Discretionary_Type__c))
                    objLine.Sales_Discretionary_Type__c =  Label.LineItemSalesDiscretionaryTypePercentageDiscount;
                lstUpdateLineItem.add(objLine);
            }
            if(String.isNotBlank(objLine.Sales_Discretionary_Type__c) && objLine.Sales_Discretionary_Type__c == Label.LineItemSalesDiscretionaryTypeDiscountAmount)
            {
                System.debug('Entering Apply Amount');
                objLine.Sales_Discretionary_Discount__c = objLine.Suggested_Sales_Discount_Amount__c;
                objLine.Global_Trade_Block__c = false;
                lstUpdateLineItem.add(objLine);
            }
        }
        System.debug('lstUpdateLineItem:'+lstUpdateLineItem);
        if(!lstUpdateLineItem.isEmpty())
            update lstUpdateLineItem;

        PageReference cartPage = Page.Apttus_Config2__Cart;
        cartPage.getParameters().put(CONFIGID, strConfigId);
        cartPage.getParameters().put(CONFIGREQUESTID, strConfigRequestId);
        cartPage.getParameters().put(FLOW, strFlow);
        cartPage.getParameters().put(BUSINESSOBJECTID, strBusinessObjectId);
        return cartPage;
    }

    /*
    *  @author      : Rahul Sharma
    *  @description : Remove sales discretionery discount from suggested sales discount 
    *  @param       : None
    *  @Return      : PageReference
    */
    public PageReference remove() {
        getSelectedProducts();
        selectedProductsList = mapSelectedProducts.values();
        System.debug('selectedProductsList:'+selectedProductsList);

        List<Apttus_Config2__LineItem__c> lstUpdateLineItem = new List<Apttus_Config2__LineItem__c>();

        for(Apttus_Config2__LineItem__c objLine: selectedProductsList){
            objLine.Sales_Discretionary_Discount__c = null;
            objLine.Global_Trade_Block__c = false;
            lstUpdateLineItem.add(objLine);
        }
        if(!lstUpdateLineItem.isEmpty())
            update lstUpdateLineItem;

        PageReference cartPage = Page.Apttus_Config2__Cart;
        cartPage.getParameters().put(CONFIGID, strConfigId);
        cartPage.getParameters().put(CONFIGREQUESTID, strConfigRequestId);
        cartPage.getParameters().put(FLOW, strFlow);
        cartPage.getParameters().put(BUSINESSOBJECTID, strBusinessObjectId);
        return cartPage;
    }

    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }

    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }

    public Integer pageNumber {
        get {
            return con.getPageNumber();
        }
        set;
    }

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Method to return the products in the ProductsWrapper format
    *  @Param       : None
    *  @Return      : List<ProductsWrapper>
    */
    public List<ProductsWrapper> getProducts() {

        getSelectedProducts();

        lstProductsWrapper = new List<ProductsWrapper>();

        for (Apttus_Config2__LineItem__c lineItem : (List<Apttus_Config2__LineItem__c>) con.getRecords()) {
            if (mapSelectedProducts.containsKey(lineItem.id)) {
                lstProductsWrapper.add(new ProductsWrapper(lineItem, true));
            } else {
                lstProductsWrapper.add(new ProductsWrapper(lineItem, false));
            }
        }
        System.debug('lstProductsWrapper:'+lstProductsWrapper);
        return lstProductsWrapper;
    }

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Method to add selected product into mapSelectedProducts map from lstProductsWrapper
    *  @Param       : None
    *  @Return      : None
    */
    public void getSelectedProducts() {
        if (lstProductsWrapper != null) {
            for (ProductsWrapper pw : lstProductsWrapper) {
                if (pw.bool == true) {
                    mapSelectedProducts.put(pw.lineItem.id, pw.lineItem);
                } else {
                    mapSelectedProducts.remove(pw.lineItem.id);
                }
            }
        }
    }

    /*
    *  @Author      : Rahul Sharma
    *  @Description : Private inner wrapper class
    */
    private class ProductsWrapper {
        public Apttus_Config2__LineItem__c lineItem {get; set;}
        public Boolean bool {get; set;}
        
        /*
        *  @Author      : Rahul Sharma
        *  @Description : Parameterized constructor for wrapper class
        *  @Param       : Apttus_Config2__LineItem__c, Boolean
        */

        public ProductsWrapper(Apttus_Config2__LineItem__c lineItem, Boolean bool) {
            this.lineItem = lineItem;
            this.bool = bool;
        }
    }

}
/**
 *    @author Satya Swain
 *    @date   2019-04-04
 *    @description DCP-24589 Indirect: Direct Sale to UC Logic
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *           Satya Swain                    04-04-2018         used to create json to store line item values for DCP-24589
 *           Parthasarathy D                10-Oct-2022        Added method level comments.
 *           Satya Swain                    09 Dec 2022        Added Codescan fix for Variable Naming Convention
 * ---------------------------------------------------------------------------------------------------------------------
 *
 */
public class LineItemWrapper {
	public Decimal quantity;
    public Decimal salesDiscretionaryDiscount;
    public String salesDiscretionaryType;
    public Decimal priceOverride;
    public Decimal lineNumber;
    /*
    *  @author      : 
    *  @description : Parameterized Constructor.
    */
    public LineItemWrapper(Apttus_Config2__LineItem__c	objLineItem){

        this.quantity = objLineItem.Apttus_Config2__Quantity__c;
        this.salesDiscretionaryDiscount = objLineItem.Sales_Discretionary_Discount__c;
        this.salesDiscretionaryType = objLineItem.Sales_Discretionary_Type__c;
        this.priceOverride = objLineItem.Price_Override__c;
        this.lineNumber = objLineItem.Apttus_Config2__LineNumber__c;

    }
}
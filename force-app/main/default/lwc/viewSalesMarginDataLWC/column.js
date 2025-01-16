import Product from "@salesforce/label/c.UI_Text_Product";
import UI_Text_Quantity from "@salesforce/label/c.UI_Text_Quantity";
import UI_Text_List_Price_Marginal from "@salesforce/label/c.UI_Text_List_Price_Marginal";
import UI_Text_Material_Class from "@salesforce/label/c.UI_Text_Material_Class";
import UI_Text_Product_Line from "@salesforce/label/c.UI_Text_Product_Line";
import UI_Text_Price_Override from "@salesforce/label/c.UI_Text_Price_Override";
import UI_Text_Term_Months from "@salesforce/label/c.UI_Text_Term_Months";
import UI_Text_Channel_Partner_Price from "@salesforce/label/c.UI_Text_Channel_Partner_Price";
import UI_Text_DistributorCommission from "@salesforce/label/c.UI_Text_DistributorCommission";
import UI_Text_Historical_Discount_Price from "@salesforce/label/c.UI_Text_Historical_Discount_Price";
import UI_Text_Quote_Proposed_Price from "@salesforce/label/c.UI_Text_Quote_Proposed_Price";
import UI_Text_Std_Margin_At_CP_Price from "@salesforce/label/c.UI_Text_Std_Margin_At_CP_Price";
import UI_Text_Std_Margin_At_Historical_Discount from "@salesforce/label/c.UI_Text_Std_Margin_At_Historical_Discount";
import UI_Text_Std_Margin_At_Quote_Proposed_Price from "@salesforce/label/c.UI_Text_Std_Margin_At_Quote_Proposed_Price";
import UI_Text_Standard_Margin_Target from "@salesforce/label/c.UI_Text_Standard_Margin_Target";
import UI_Text_Standard_Margin_At_Quote_Proposed_Price from "@salesforce/label/c.UI_Text_Standard_Margin_At_Quote_Proposed_Price";
import UI_Text_QuoteProposedExtPrice from "@salesforce/label/c.UI_Text_QuoteProposedExtPrice";
import UI_Text_StdMarginAtListPrice from "@salesforce/label/c.UI_Text_StdMarginAtListPrice";
import UI_Text_Product_Code from "@salesforce/label/c.UI_Text_Product_Code";
import UI_Text_QuoteProposedPrice from "@salesforce/label/c.UI_Text_QuoteProposedPrice";

export const indirectColumns = [
  {
    label: Product,
    fieldName: "productName",
    type: "text",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Product_Code,      
    fieldName: "materialNumber",
    type: "text",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Product_Line,
    fieldName: "productLine",
    type: "text",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'left' },
  },
  {
    label: UI_Text_Quantity,
    fieldName: "quantity",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 50,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_List_Price_Marginal,
    fieldName: "listPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Material_Class,
    fieldName: "materialClass",
    type: "text",
    hideDefaultActions: true,
    initialWidth: 120,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Price_Override,
    fieldName: "priceOverride",
    type: "text",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Term_Months,
    fieldName: "termMonths",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Channel_Partner_Price,
    fieldName: "channelPartnerPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Historical_Discount_Price,
    fieldName: "historicalDiscount",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Quote_Proposed_Price,
    fieldName: "quoteProposedPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_QuoteProposedExtPrice,
    fieldName: "quoteExtendedPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_QuoteProposedPrice,
    fieldName: "marginAtQuotePrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Std_Margin_At_Quote_Proposed_Price,
    fieldName: "marginAtProposedPrice",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Std_Margin_At_Historical_Discount,
    fieldName: "marginAtHistoricalDiscount",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Std_Margin_At_CP_Price,
    fieldName: "marginAtListPrice",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Standard_Margin_Target,
    fieldName: "standardMarginTarget",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  }
];

export const directToUCcolumns = [
  {
    label: Product,
    fieldName: "productName",
    type: "text",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Product_Code,      
    fieldName: "materialNumber",
    type: "text",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Product_Line,
    fieldName: "productLine",
    type: "text",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'left' },
  },
  {
    label: UI_Text_Quantity,
    fieldName: "quantity",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 50,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_List_Price_Marginal,
    fieldName: "listPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Material_Class,
    fieldName: "materialClass",
    type: "text",
    hideDefaultActions: true,
    initialWidth: 120,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Price_Override,
    fieldName: "priceOverride",
    type: "text",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Term_Months,
    fieldName: "termMonths",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Historical_Discount_Price,
    fieldName: "historicalDiscount",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_DistributorCommission,
    fieldName: "distributorCommission",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Quote_Proposed_Price,
    fieldName: "quoteProposedPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_QuoteProposedExtPrice,
    fieldName: "quoteExtendedPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_QuoteProposedPrice, 
    fieldName: "marginAtQuotePrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Std_Margin_At_Quote_Proposed_Price,
    fieldName: "marginAtProposedPrice",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Std_Margin_At_Historical_Discount,
    fieldName: "marginAtHistoricalDiscount",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_StdMarginAtListPrice,
    fieldName: "marginAtListPrice",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Standard_Margin_Target,
    fieldName: "standardMarginTarget",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  }
];

export const directColumns = [
  {
    label: Product,
    fieldName: "productName",
    type: "text",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },    
  {
    label: UI_Text_Product_Code,         
    fieldName: "materialNumber",
    type: "text",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Product_Line,
    fieldName: "productLine",
    type: "text",
    wrapText: true,
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'left' },
  },
  {
    label: UI_Text_Quantity,
    fieldName: "quantity",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 60,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_List_Price_Marginal,
    fieldName: "listPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Material_Class,
    fieldName: "materialClass",
    type: "text",
    hideDefaultActions: true,
    initialWidth: 120,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Price_Override,
    fieldName: "priceOverride",
    type: "text",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Term_Months,
    fieldName: "termMonths",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Historical_Discount_Price,
    fieldName: "historicalDiscount",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 80,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Quote_Proposed_Price,
    fieldName: "quoteProposedPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_QuoteProposedExtPrice,
    fieldName: "quoteExtendedPrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_QuoteProposedPrice, 
    fieldName: "marginAtQuotePrice",
    type: "number",
    hideDefaultActions: true,
    initialWidth: 100,
    cellAttributes: { 
        alignment: 'center',
    },
  },
  {
    label: UI_Text_Std_Margin_At_Quote_Proposed_Price,
    fieldName: "marginAtProposedPrice",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { 
        alignment: 'center',
     },
  },
  {
    label: UI_Text_Std_Margin_At_Historical_Discount,
    fieldName: "marginAtHistoricalDiscount",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_StdMarginAtListPrice,
    fieldName: "marginAtListPrice",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  },
  {
    label: UI_Text_Standard_Margin_Target,
    fieldName: "standardMarginTarget",
    type: "percent",
    hideDefaultActions: true,
    initialWidth: 100,
    typeAttributes: {
      maximumFractionDigits: "2"
    },
    cellAttributes: { alignment: 'center' },
  }
];

export const lineLevelColumns = [
  {
    label: UI_Text_Product_Line,
    fieldName: "productLine",
    type: "text",
    hideDefaultActions: true
  },
  {
    label: UI_Text_Standard_Margin_At_Quote_Proposed_Price,
    fieldName: "marginAtProposedPrice",
    type: "percent",
    hideDefaultActions: true,
    typeAttributes: {
      maximumFractionDigits: "2"
    }
  },
  {
    label: UI_Text_Standard_Margin_Target,
    fieldName: "standardMarginTarget",
    type: "percent",
    hideDefaultActions: true,
    typeAttributes: {
      maximumFractionDigits: "2"
    }
  }
];

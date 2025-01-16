export const lstAffliateColumns = [
    {
      label: "Account Name",
      fieldName: "accountId",
      type: "url",
      wrapText: true,
      typeAttributes: {
        label: { fieldName: "accountName" },
        tooltip: { fieldName: "accountName" },
        target: "_blank",
      },
      sortable: true,
    },
    {
      label: "Customer ERP Number",
      fieldName: "customerERPNumber",
      type: "text",
      sortable: true,
    },
    {
      label: "Include In Annual Consumable Spend",
      fieldName: "",
      type: "button-icon",
      typeAttributes: {
        class: { fieldName: 'includeInAnnualConsumableSpend' },
        iconName: { fieldName: 'displayIconName1' },
        iconPosition: 'center',
        hideLabel: true,
        label: { 
          fieldName: 'checkboxConsumableSpend' 
        },
      },      
    },
    {
      label: "Opt In Receiving Open Offer Discount",
      fieldName: "", 
      type: "button-icon",     
      typeAttributes: {
        class: { fieldName: 'optInReceivingOpenOfferDiscount' },
        iconName: { fieldName: 'displayIconName2' },
        iconPosition: 'center' ,
        hideLabel: true,
        label: { 
          fieldName: 'checkboxOpenOfferDiscount' 
        },       
      }
    },
    {
      label: "Consider for GF Discount Calculation",
      fieldName: "",
      type: "button-icon",
      typeAttributes: {
        class: { fieldName: 'considerForGFDiscountCalculation' },
        iconName: { fieldName: 'displayIconName3' },
        iconPosition: 'center',
        hideLabel: true,
        label: { 
          fieldName: 'checkboxGFDiscount' 
        },        
      }
    }
];
  
export const mapColumnNameToIconName = {
    'includeInAnnualConsumableSpend' : 'displayIconName1',
    'optInReceivingOpenOfferDiscount' : 'displayIconName2',
    'considerForGFDiscountCalculation' : 'displayIconName3'
}
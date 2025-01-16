import lineTypeLabel from '@salesforce/label/c.UI_Label_Line_Type';
import custERPLabel from '@salesforce/label/c.UI_Label_Customer_ERP_Number';
import accountNameLabel from '@salesforce/label/c.UI_Label_Customer_Account_Name';
import materialNumberGroupLabel from '@salesforce/label/c.UI_Label_Material_Number_Group';
import materialNameGroupLabel from '@salesforce/label/c.UI_Label_Material_Name_Group';
import salesOrgLabel from '@salesforce/label/c.UI_Label_Sales_Org';
import currencyLabel from '@salesforce/label/c.UI_Label_Currency';
import discountLabel from '@salesforce/label/c.UI_Label_Discount';
import discountTypeLabel from '@salesforce/label/c.UI_Label_Discount_Type';
import discountPercentLabel from '@salesforce/label/c.UI_Label_Discount_Percentage';
import startdateLabel from '@salesforce/label/c.UI_Label_Start_Date';
import enddateLabel from '@salesforce/label/c.UI_Label_End_Date';
import ucERPLabel from '@salesforce/label/c.UI_Label_Ultimate_Consignee_ERP_Number_c';
import premiumLabel from '@salesforce/label/c.UI_Label_Premium';
import listPriceLabel from '@salesforce/label/c.UI_Label_List_Price';
import customerPriceLabel from '@salesforce/label/c.UI_Label_Customer_Price';
import lineStatus from '@salesforce/label/c.UI_Label_Line_Status';
import customerHistoricalDiscountLabel from '@salesforce/label/c.UI_Text_Customer_Historical_Discount';
import medianDiscountLabel from '@salesforce/label/c.UI_Text_Median_Discount';
import maxDiscountLabel from '@salesforce/label/c.UI_Text_Max_Discount';
import discountBeforeApprovalLabel from '@salesforce/label/c.UI_Text_Sales_Approval_Threshold';

const columnsNotCP = [

	{
		label: lineTypeLabel,
		fieldName: 'lineType',
		type: 'text',
		sortable: true,
		initialWidth: 120,
		wrapText: true
	},
	{
		label: custERPLabel,
		fieldName: 'customerERPNumber',
		type: 'text',
		sortable: true,
		initialWidth: 145,
		wrapText: true
	},
	{
		label: accountNameLabel,
		fieldName: 'accountName',
		type: 'text',
		sortable: true,
		initialWidth: 135,
		wrapText: true
	},
	{
		label: materialNumberGroupLabel,
		fieldName: 'materialNumberGroup',
		type: 'text',
		sortable: true,
		initialWidth: 150,
		wrapText: true
	},
	{
		label: materialNameGroupLabel,
		fieldName: 'materialNameGroupDesc',
		type: 'text',
		sortable: true,
		initialWidth: 185,
		wrapText: true
	},
	{
		label: salesOrgLabel,
		fieldName: 'salesOrg',
		type: 'text',
		sortable: true,
		initialWidth: 100,
		wrapText: true
	},
	{
		label: currencyLabel,
		fieldName: 'currencyValue',
		type: 'text',
		sortable: true,
		initialWidth: 100,
		wrapText: true
	},
	{
		label: listPriceLabel,
		fieldName: 'listPrice',
		type: 'text',
		sortable: true,
		initialWidth: 100,
		wrapText: true
	},
	{
		label: customerPriceLabel,
		fieldName: 'customerPrice',
		type: 'text',
		sortable: true,
		initialWidth: 100,
		wrapText: true
	},
	{
		label: discountTypeLabel,
		fieldName: 'discountType',
		type: 'text',
		sortable: true,
		initialWidth: 100,
		wrapText: true
	},            
	{
		label: discountPercentLabel,
		fieldName: 'discountPercent',
		type: 'text',
		sortable: true,
		initialWidth: 115,
		wrapText: true
	},
	{
		label: discountLabel,
		fieldName: 'discount',
		type: 'text',
		sortable: true,
		initialWidth: 100,
		wrapText: true
	},
	{
		label: customerHistoricalDiscountLabel,
		fieldName: 'customerHistoricalDiscount',
		type: 'text',
		sortable: true,
		initialWidth: 150,
		wrapText: true
	},
	{
		label: medianDiscountLabel,
		fieldName: 'medianDiscount',
		type: 'text',
		sortable: true,
		initialWidth: 145,
		wrapText: true
	},
	{
		label: maxDiscountLabel,
		fieldName: 'maxDiscount',
		type: 'text',
		sortable: true,
		initialWidth: 135,
		wrapText: true
	},
	{
		label: discountBeforeApprovalLabel,
		fieldName: 'discountBeforeApproval',
		type: 'text',
		sortable: true,
		initialWidth: 150,
		wrapText: true
	},	
	{
		label: lineStatus,
		fieldName: 'lineStatus',
		type: 'text',
		sortable: true,
		initialWidth: 120,
		wrapText: true
	},
	{
		label: startdateLabel,
		fieldName: 'startdate',
		type: 'date',
		typeAttributes: {
			month: 'numeric',
			day: 'numeric',            
			year: 'numeric',                    
		},
		sortable: true,
		initialWidth: 100,
		wrapText: true
	},
	{
		label: enddateLabel,
		fieldName: 'enddate',
		type: 'date',
		typeAttributes: {
			month: 'numeric',
			day: 'numeric',
			year: 'numeric',
		},
		sortable: true,
		initialWidth: 100,
		wrapText: true
	}
]

const columnsIsCP = [

      {
          label: custERPLabel,
          fieldName: 'customerERPNumber',
          type: 'text',
          sortable: true,
		  initialWidth: 145,
		  wrapText: true
      },
      {
          label: accountNameLabel,
          fieldName: 'accountName',
          type: 'text',
          sortable: true,
		  initialWidth: 135,
		  wrapText: true
      },
      {
          label: ucERPLabel,
          fieldName: 'ultimateconsigneeErpNumber',
          type: 'text',
          sortable: true,
		  initialWidth: 100,
		  wrapText: true
      },
      {
          label: lineTypeLabel,
          fieldName: 'lineType',
          type: 'text',
          sortable: true,
		  initialWidth: 120,
		  wrapText: true
      },
      {
          label: materialNumberGroupLabel,
          fieldName: 'materialNumberGroup',
          type: 'text',
          sortable: true,
		  initialWidth: 150,
		  wrapText: true
      },
      {
          label: materialNameGroupLabel,
          fieldName: 'materialNameGroupDesc',
          type: 'text',
          sortable: true,
		  initialWidth: 185,
		  wrapText: true
      },
      {
          label: salesOrgLabel,
          fieldName: 'salesOrg',
          type: 'text',
          sortable: true,
		  initialWidth: 100,
		  wrapText: true
      },
      {
          label: currencyLabel,
          fieldName: 'currencyValue',
          type: 'text',
          sortable: true,
		  initialWidth: 100,
		  wrapText: true
      },
      {
          label: listPriceLabel,
          fieldName: 'listPrice',
          type: 'text',
          sortable: true,
		  initialWidth: 100,
		  wrapText: true
      },
      {
          label: customerPriceLabel,
          fieldName: 'customerPrice',
          type: 'text',
          sortable: true,
		  initialWidth: 100,
		  wrapText: true
      },
      {
          label: discountPercentLabel,
          fieldName: 'discountPercent',
          type: 'text',
          sortable: true,
		  initialWidth: 115,
		  wrapText: true
      },
      {
          label: discountLabel,
          fieldName: 'discount',
          type: 'text',
          sortable: true,
		  initialWidth: 100,
		  wrapText: true
      },
      {
          label: lineStatus,
          fieldName: 'lineStatus',
          type: 'text',
          sortable: true,
		  initialWidth: 120,
		  wrapText: true
      },
      {
          label: premiumLabel,
          fieldName: 'permittedmarkupPercentage',
          type: 'text',
          sortable: true,
		  initialWidth: 100,
		  wrapText: true
      },
	  {
		label: customerHistoricalDiscountLabel,
		fieldName: 'customerHistoricalDiscount',
		type: 'text',
		sortable: true,
		initialWidth: 150,
		wrapText: true
	  },
	  {
		label: medianDiscountLabel,
		fieldName: 'medianDiscount',
		type: 'text',
		sortable: true,
		initialWidth: 145,
		wrapText: true
	},
	{
		label: maxDiscountLabel,
		fieldName: 'maxDiscount',
		type: 'text',
		sortable: true,
		initialWidth: 135,
		wrapText: true
	},
	{
		label: discountBeforeApprovalLabel,
		fieldName: 'discountBeforeApproval',
		type: 'text',
		sortable: true,
		initialWidth: 150,
		wrapText: true
	}
                                  
  ];
export {
    columnsNotCP,
	columnsIsCP 
};
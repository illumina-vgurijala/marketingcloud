;(function() {	
	angular.module('aptBase')
	.service('ObjectConstants', ObjectConstants);

	ObjectConstants.$inject = [];
	 
	function ObjectConstants() {
		var service = this;
	
		service.LineItem = {			
			LINETYPE_PRODUCT: 'Product/Service',
			LINETYPE_OPTION: 'Option',
			LINETYPE_MISC: 'Misc',
			
			PRICETYPE_ONETIME: 'One Time',
			PRICETYPE_RECURRING: 'Recurring',
			PRICETYPE_USAGE: 'Usage',
			PRICETYPE_INCLUDED_USAGE: 'Included Usage',
			
			PRICEMETHOD_PERUNIT: 'Per Unit',
			PRICEMETHOD_FLATPRICE: 'Flat Price',
			PRICEMETHOD_PERCENTAGE: 'Percentage',
			PRICEMETHOD_RELATEDPRICE: 'Related Price',
			PRICEMETHOD_TIERED_RATE: 'Tiered Rate',
			PRICEMETHOD_TIERPRICE: 'Tier Price',
			
			FREQUENCY_HOURLY: 'Hourly',
			FREQUENCY_DAILY: 'Daily',
			FREQUENCY_WEEKLY: 'Weekly',
			FREQUENCY_MONTHLY: 'Monthly',
			FREQUENCY_QUARTERLY: 'Quarterly',
			FREQUENCY_HALFYEARLY: 'Half Yearly',
			FREQUENCY_YEARLY: 'Yearly',
			FREQUENCY_ONETIME: 'One Time',
			
			STATUS_NEW: 'New',
			STATUS_EXISTING: 'Existing',
			STATUS_INCREMENTED: 'Incremented',
			STATUS_AMENDED: 'Amended',
			STATUS_RENEWED: 'Renewed',
			STATUS_UPGRADED: 'Upgraded',
			STATUS_CANCELLED: 'Cancelled',
			STATUS_TRANSIENT: 'Transient',
			
			SYNC_STATUS_PENDING: 'Pending',
			SYNC_STATUS_SYNCHRONIZED: 'Synchronized',
			
			CONFIG_STATUS_NA: 'NA',
			CONFIG_STATUS_DEFAULT_PENDING: 'Default Pending',
			CONFIG_STATUS_PENDING: 'Pending',
			CONFIG_STATUS_COMPLETE: 'Complete',

			PRICING_STATUS_PENDING: 'Pending',
			PRICING_STATUS_COMPLETE: 'Complete',

			PRICEGROUP_PRICERAMP: 'Price Ramp',		
			PRICEGROUP_NONE: 'None',

			AUTORENEWALTYPE_FIXED: 'Fixed',
			AUTORENEWALTYPE_EVERGREEN: 'Evergreen'
		};

		service.assetStatusMap = {
			CANCELLED : "Pending Cancellation",
			AMENDED : "Pending Change",
			RENEWED : "Pending Renewal",
			DEFAULT : "Pending Asset Action"
		};

		service.ChargeType = {
			// known charge types
			CHARGETYPE_NONE: 'None',
			CHARGETYPE_STANDARD_PRICE: 'Standard Price',
			CHARGETYPE_LICENSE_FEE: 'License Fee',
			CHARGETYPE_SUBSCRIPTION_FEE: 'Subscription Fee',
			CHARGETYPE_IMPLEMENTATION_FEE: 'Implementation Fee',
			CHARGETYPE_INSTALLATION_FEE: 'Installation Fee',
			CHARGETYPE_MAINTENANCE_FEE: 'Maintenance Fee',
			CHARGETYPE_ADJUSTMENT: 'Adjustment',

			// miscellaneous charge types
			CHARGETYPE_SALESTAX: 'Sales Tax',
			CHARGETYPE_SHIPPING_HANDLING: 'Shipping & Handling'
			
		};

		service.FieldType = {
			// known field types
			FIELDTYPE_DATE: 'DATE',
			FIELDTYPE_MULTIPICKLIST: 'MULTIPICKLIST',
			FIELDTYPE_CURRENCY: 'CURRENCY',
			FIELDTYPE_PERCENT: 'PERCENT',
			FIELDTYPE_PICKLIST: 'PICKLIST',
			FIELDTYPE_REFERENCE: 'REFERENCE',
			FIELDTYPE_NUMBER: 'NUMBER',
			FIELDTYPE_DOUBLE: 'DOUBLE'
		};
		
		service.allowedActions = {
			CANCEL: 'Cancel',
			AMEND: 'Amend',
			UPGRADE: 'Swap',
			RENEW: 'Renew',
			INCREMENT: 'Increment',
			DECREMENT: 'Decrement'
		}

		service.PackageNamespace = {
			QPCONFIG: 'Apttus_QPConfig',
			CMCONFIG: 'Apttus_CMConfig'
		}

		service.ProductConfiguration = {
			ROBJECT_NAME_PROPOSAL: 'Proposald__r',
			ROBJECT_NAME_AGREEMENT: 'AgreementId__r',
			ROBJECT_NAME_ORDER: 'OrderId__r',

			BOTYPE_PROPOSAL: 'Proposal',
			BOTYPE_AGREEMENT: 'Agreement',
			BOTYPE_ORDER: 'Order',

			STATUS_APPROVAL_REQUIRED: 'Approval Required',
			STATUS_PENDING_APPROVAL: 'Pending Approval',
			STATUS_READY_FOR_APPROVALS: 'Ready For Approvals'
		}

		service.ApprovalStatusField = {
			PROPOSAL_APPROVAL_STAGE: 'Apttus_Proposal__Approval_Stage__c',
			AGREEMENT_STATUS: 'Apttus__Status__c',
			ORDER_STATUS: 'Status__c'
		}

		service.RenewalDateTypes = {
		    PROPOSAL_END_DATE: 'PROPOSALENDDATE',
		    CURRENT_ASSET_END_DATE: 'CURRENTASSETENDDATE',
		    FARTHEST_ASSET_END_DATE: 'FARTHESTASSETENDDATE',
		    USER_RENEWAL_DATE: 'RENEWALDATE'
		};

		service.ProductAttributeRuleAction = {
			OBJECT_TYPE_LINE_ITEM: 'Line Item',
			OBJECT_TYPE_PRODUCT_ATTRIBUTE_VALUE: 'Product Attribute Value'

		};
		
		service.Incentive = {
			APPLICATION_METHOD_BUYXGETY: 'Buy X Get Y',
			APPLICATION_METHOD_BUYXGETX: 'Buy X Get X',
			USETYPE_PROMOTION: 'Promotion'
		};

		service.PriceRule = {
			SCOPEOPER_ALL: 'all',
			SCOPEOPER_ALL_INBUNDLE: 'all in bundle'
		};
		
		return service;

	}
 
}).call(this);
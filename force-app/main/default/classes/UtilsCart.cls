/**
*	@author Milan Savaliya
*	@date	 2018-10-23
*	@description	DCP-11786: Create Quote - Clone Products from Opportunity
*	Modification Log:
*	------------------------------------------------------------------------------------
*			Developer					Date				Description
*			Milan					 	2018-10-23
*			Rahul Bishnoi				2020-01-27			Added ERP_Line_Number_Id
*			Akshay Mohan				2021-05-06			DCP-38809: Add logic for finalize & sync
*           Adyasha Satapathy           2021-05-17          DCP-38809: Added new constructor for Cart Line Creation from Work Details
*           Rahul Bishnoi               2021-09-20          INC0345038: Updated logic to reprice cart
*           Adithi Acharya              2022-08-18          DCP-56258 :Auto Population of Informatics details
*           Arquimidez Mora             2024-12-05          CMCM-9914: Added ecomLineItemId
*	------------------------------------------------------------------------------------
**/
public class UtilsCart {
	
	
/**
*	@author Milan	savaliya
*	@Create Cart
*	@param Id of proposals
*	@return void
**/
	public static String createCartForQuote(String quoteId) {

		Apttus_CPQApi.CPQ.CreateCartRequestDO objCreateCartRequestDO = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
		objCreateCartRequestDO.QuoteId = quoteId;
		Apttus_CPQApi.CPQ.CreateCartResponseDO objCreateCartResponseDO = Apttus_CPQApi.CPQWebService.CreateCart(objCreateCartRequestDO);
		system.debug('##createCartForQuote objCreateCartResponseDO' + objCreateCartResponseDO);
		return objCreateCartResponseDO.cartId;
	}


/**
*	@author Milan	savaliya
*	@Add Products to Cart Cart
*	@param Id of proposals
*	@param list LineItemWrapper
*	@return void
**/

	public static List<Decimal> addMultiProducts(String cartId, List<LineItemWrapper> lstLineItemWrapper) {

		List<Apttus_CPQApi.CPQ.SelectedProductDO> listSelectedProductDO = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
		
		for(LineItemWrapper objLineItemWrapper : lstLineItemWrapper) {
			Apttus_CPQApi.CPQ.SelectedProductDO objSelectedProductDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
			objSelectedProductDO.ProductId = objLineItemWrapper.productId;
			objSelectedProductDO.Quantity = objLineItemWrapper.quantity;
			objSelectedProductDO.StartDate = objLineItemWrapper.startDate;
			objSelectedProductDO.EndDate = objLineItemWrapper.endDate;
			//objSelectedProductDO.SellingTerm = objSelectedProductDO.StartDate.MonthsBetween(objSelectedProductDO.EndDate);
			objSelectedProductDO.Comments = 'Added by Code';
			
			//To add custom fields in the Line Item record
			List<String> customFields = new List<String>();
		    customFields.add('Line_Description__c');
			//customFields.add('Apttus_Config2__Description__c');
			customFields.add('Shipping_In_Close_Quarter__c');
			customFields.add('Shipping_In_1Q_After_Close_Quarter__c');
			customFields.add('Shipping_In_2Q_After_Close_Quarter__c');
            customFields.add('Apttus_Config2__StartDate__c');
            customFields.add('Apttus_Config2__EndDate__c');
            customFields.add('EcomLineItemID__c');
			Apttus_Config2__LineItem__c objLineItem = new Apttus_Config2__LineItem__c();
			//objLineItem.Apttus_Config2__Description__c = objLineItemWrapper.description;
			objLineItem.Line_Description__c = objLineItemWrapper.description;
			objLineItem.Shipping_In_Close_Quarter__c = objLineItemWrapper.shippingInCloseQuarter;
			objLineItem.Shipping_In_1Q_After_Close_Quarter__c = objLineItemWrapper.shippingIn1QAfterCloseQuarter;
			objLineItem.Shipping_In_2Q_After_Close_Quarter__c = objLineItemWrapper.shippingIn2QAfterCloseQuarter;
            objLineItem.Apttus_Config2__StartDate__c = objLineItemWrapper.startDate;
            objLineItem.Apttus_Config2__EndDate__c = objLineItemWrapper.endDate;
            objLineItem.EcomLineItemID__c = objLineItemWrapper.ecomLineItemId;
			objSelectedProductDO.CustomFields = customFields;
			objSelectedProductDO.CustomData = objLineItem;
			System.debug('objSelectedProductDO :: ' + objSelectedProductDO);
			listSelectedProductDO.add(objSelectedProductDO);
		}
		
		Apttus_CPQApi.CPQ.AddMultiProductRequestDO objAddMultiProductRequestDO = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO();
		objAddMultiProductRequestDO.cartId = cartId;
		objAddMultiProductRequestDO.SelectedProducts = listSelectedProductDO;
		Apttus_CPQApi.CPQ.AddMultiProductResponseDO objAddMultiProductResponseDO = Apttus_CPQApi.CPQWebService.addMultiProducts(objAddMultiProductRequestDO);
		system.debug('##addMultiProducts objAddMultiProductResponseDO : ' + objAddMultiProductRequestDO);
		return objAddMultiProductResponseDO.LineNumbers;
	}

	/**
    *    @author Adyasha Satapathy  
    *    @description wrapper for Cart Line Creation from Work Details
    */
	public class LineItemWrapper {
		public Id productId {get; set;}
		public Decimal quantity {get; set;}
		public Date startDate {get; set;}
		public Date endDate {get; set;}
		public String description {get; set;}
		public Decimal shippingInCloseQuarter {get; set;}
		public Decimal shippingIn1QAfterCloseQuarter {get; set;}
		public Decimal shippingIn2QAfterCloseQuarter {get; set;}
		public String ERP_Line_Number_Id{get; set;}
		public String Serial_Number{get; set;}
		public String registrantContact{get;set;} //DCP-56258
		public String ecomLineItemId{get;set;} //CMCM-9914
			/**
			*	@author Adyasha Satapathy  
			*	@description paramterized constructor called
			*	@param OpportunityLineItem objOpportunityLineItem
			*	@return void
			**/
            public LineItemWrapper(OpportunityLineItem objOpportunityLineItem) {
			this.productId = objOpportunityLineItem.Product2Id;
			this.quantity = objOpportunityLineItem.Quantity;
			this.shippingInCloseQuarter = objOpportunityLineItem.Shipping_In_Close_Quarter__c;
			this.shippingIn1QAfterCloseQuarter = objOpportunityLineItem.Shipping_In_1Q_After_Close_Quarter__c;
			this.shippingIn2QAfterCloseQuarter = objOpportunityLineItem.Shipping_In_2Q_After_Close_Quarter__c;
			this.startDate = objOpportunityLineItem.Start_Date__c;
			this.endDate = objOpportunityLineItem.End_Date__c;
			this.ERP_Line_Number_Id = objOpportunityLineItem.ERP_Line_Number_Id__c;
			this.Serial_Number =  objOpportunityLineItem.Serial_Number__c;
			this.registrantContact =  objOpportunityLineItem.Quote_Line_Item__r.Registrant_Contact__c; //DCP-56258
            System.debug('Start date : ' + this.startDate + this.endDate);
			this.description = objOpportunityLineItem.Product2.Name;
            this.description += ' - ';
            this.description += objOpportunityLineItem.Product2.ProductCode == NULL ? ' ' : objOpportunityLineItem.Product2.ProductCode;
            this.description += ' - Sales Price:';
            this.description += objOpportunityLineItem.UnitPrice == NULL ? '0' : String.valueof(objOpportunityLineItem.UnitPrice);
            this.description += ' - Qty:';
            this.description += objOpportunityLineItem.Quantity == NULL ? '0' : String.valueof(objOpportunityLineItem.Quantity);
            this.description += ' - Total:';
            this.description += objOpportunityLineItem.TotalPrice == NULL ? '0' : String.valueof(objOpportunityLineItem.TotalPrice);
            this.description += ', Ship Close Quarter:';
            this.description +=  objOpportunityLineItem.Shipping_In_Close_Quarter__c == NULL ? '0' : String.valueof(objOpportunityLineItem.Shipping_In_Close_Quarter__c);
            this.description += ', Ship Close Q1:';
            this.description += objOpportunityLineItem.Shipping_In_1Q_After_Close_Quarter__c == NULL ? '0' : String.valueof(objOpportunityLineItem.Shipping_In_1Q_After_Close_Quarter__c);
            this.description += ', Ship Close Q2:';
            this.description += objOpportunityLineItem.Shipping_In_2Q_After_Close_Quarter__c == NULL ? '0' : String.valueof(objOpportunityLineItem.Shipping_In_2Q_After_Close_Quarter__c);       
		}
		/**
		*	@author Adyasha Satapathy  
		*	@description paramterized constructor called
		*	@param Apttus_Proposal__Proposal_Line_Item__c objProposalLineItem
		*	@return void
		**/
		public LineItemWrapper(Apttus_Proposal__Proposal_Line_Item__c objProposalLineItem) {
			this.productId = objProposalLineItem.Apttus_Proposal__Product__c;
			this.quantity = objProposalLineItem.Apttus_QPConfig__Quantity2__c;
			this.shippingInCloseQuarter = objProposalLineItem.Shipping_In_Close_Quarter__c;
			this.shippingIn1QAfterCloseQuarter = objProposalLineItem.Shipping_In_1Q_After_Close_Quarter__c;
			this.shippingIn2QAfterCloseQuarter = objProposalLineItem.Shipping_In_2Q_After_Close_Quarter__c;
			//this.startDate = objProposalLineItem.Apttus_QPConfig__StartDate__c;
			//this.endDate = objProposalLineItem.Apttus_QPConfig__EndDate__c;
			this.description = objProposalLineItem.Apttus_Proposal__Product__r.Name;
            this.description += ' - '; 
            this.description += objProposalLineItem.Apttus_Proposal__Product__r.ProductCode == NULL ? ' ' : objProposalLineItem.Apttus_Proposal__Product__r.ProductCode;
            this.description += ' - Sales Price:';
            this.description += objProposalLineItem.Apttus_QPConfig__NetUnitPrice__c == NULL ? '0' : String.valueof(objProposalLineItem.Apttus_QPConfig__NetUnitPrice__c);
            this.description += ' - Qty:';
            this.description += objProposalLineItem.Apttus_QPConfig__Quantity2__c == NULL ? '0' : String.valueof(objProposalLineItem.Apttus_QPConfig__Quantity2__c);
            this.description += ' - Total:';
            this.description += objProposalLineItem.Apttus_QPConfig__NetPrice__c == NULL ? '0' : String.valueof(objProposalLineItem.Apttus_QPConfig__NetPrice__c);
            this.description += ', Ship Close Quarter:';
            this.description += objProposalLineItem.Shipping_In_Close_Quarter__c == NULL ? '0' : String.valueof(objProposalLineItem.Shipping_In_Close_Quarter__c);
            this.description += ', Ship Close Q1:';
            this.description += objProposalLineItem.Shipping_In_1Q_After_Close_Quarter__c == NULL ? '0' : String.valueof(objProposalLineItem.Shipping_In_1Q_After_Close_Quarter__c);
            this.description += ', Ship Close Q2:';
            this.description += objProposalLineItem.Shipping_In_2Q_After_Close_Quarter__c == NULL ? '0' : String.valueof(objProposalLineItem.Shipping_In_2Q_After_Close_Quarter__c);
        }

		/*Added for billable Flow  - DCP  38809*/
		public LineItemWrapper(SVMXC__Service_Order_Line__c objWorkDetail) {
			this.productId = objWorkDetail.SVMXC__Product__c;
			this.quantity = objWorkDetail.SVMXC__Estimated_Quantity2__c == null ? 1 : objWorkDetail.SVMXC__Estimated_Quantity2__c;
			this.shippingInCloseQuarter = objWorkDetail.SVMXC__Estimated_Quantity2__c == null ? 1 : objWorkDetail.SVMXC__Estimated_Quantity2__c;
			this.startDate = objWorkDetail.SVMXC__Start_Date_and_Time__c == null ? null : objWorkDetail.SVMXC__Start_Date_and_Time__c.Date();
			this.endDate = objWorkDetail.SVMXC__End_Date_and_Time__c == null ? null : objWorkDetail.SVMXC__End_Date_and_Time__c.Date();
			this.Serial_Number =  String.isBlank(objWorkDetail.SVMXC__Service_Order__c) ? '' : objWorkDetail.SVMXC__Service_Order__r.Installed_Product_Serial_Number__c;
			System.debug('Start date : ' + this.startDate + this.endDate);
			this.description = objWorkDetail.SVMXC__Product__c == NULL ? '' : objWorkDetail.SVMXC__Product__r.Name + ' - ';
            this.description += objWorkDetail.SVMXC__Product__c == NULL ? '' : objWorkDetail.SVMXC__Product__r.Material_Number__c == NULL ? '' : objWorkDetail.SVMXC__Product__r.Material_Number__c;
            this.description += ' - Qty:';
            this.description += objWorkDetail.SVMXC__Estimated_Quantity2__c == null ? '1' : String.valueOf(objWorkDetail.SVMXC__Estimated_Quantity2__c);
            this.description += ', Ship Close Quarter:';
            this.description +=  objWorkDetail.SVMXC__Estimated_Quantity2__c == null ? '1' : String.valueOf(objWorkDetail.SVMXC__Estimated_Quantity2__c);
		}
	}
	
	
/**
*	@author Milan	savaliya
*	@doReprice
*	@param Id of productConfiguration
*	@return void
**/
	public static void doReprice(Id idProductConfiguration){
			ilib_Queueablethread queueableThread = new ilib_Queueablethread('doReprice');
			queueableThread.logAndQueue(new ApttusUpdatePriceForCart(idProductConfiguration), 'ApttusUpdatePriceForCart', 'execute');
			ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);
	}
	/**DCP-38809
	*	@author Akshay Mohan
	*	@Finalize Cart
	*	@param Id of Cart
	*	@return void
	**/
	public static Boolean finalizeCart(String cartId)
    {
        // create the finalize cart request          
        Apttus_CpqApi.CPQ.FinalizeCartRequestDO objFinalizeCartRequestDO = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();          
       
		// add request parameters          
        objFinalizeCartRequestDO.CartId = cartId;          
        
		// finalize the cart          
        Apttus_CpqApi.CPQ.FinalizeCartResponseDO objFinalizeCartResponseDO = Apttus_CpqApi.CPQWebService.finalizeCart(objFinalizeCartRequestDO);     
		return objFinalizeCartResponseDO.IsSuccess;
	}

	/**DCP-38809
	*	@author Akshay Mohan
	*	@Synchhronise Cart
	*	@param Id of Cart
	*	@return void
	**/
	public static Boolean synchronizeCart(String cartId)
	{
		//Pass the cartID as a parameter to the API to synchronize  quote with the updated cart items.
		Apttus_CPQApi.CPQ.SynchronizeCartRequestDO objSynchronizeCartRequestDO = new Apttus_CPQApi.CPQ.SynchronizeCartRequestDO();  
		objSynchronizeCartRequestDO.CartId  = cartId;
		Apttus_CPQApi.CPQ.SynchronizeCartResponseDO objSynchronizeCartResponseDO = Apttus_CPQApi.CPQWebService.synchronizeCart(objSynchronizeCartRequestDO);
		return objSynchronizeCartResponseDO.IsSuccess;
		
	}

}
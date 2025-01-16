/***************************************************************************************************************************************
* NAME         : IVDRDocumentSearchResponseWrapper
* DESCRIPTION  : This wrapper class holds the variable which comes back in response after integration callout is made to SAP.                   
* @AUTHOR      : Gladis
* @DATE        : 10-Dec-2021
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Gladis Evangaly        10-Dec-2021         CMCP-110: Initial Version
****************************************************************************************************************************************/
public with sharing class IVDRDocumentSearchResponseWrapper {
    
    //main class container as per SAP Success response
	public d d;

	//class container as per SAP error response
	public error error;

	/*
    * Constructor
    */
	public IVDRDocumentSearchResponseWrapper(){}

	/**
	 * @author Gladis
	 * @date    22-Dec-2021
	 * @description   class container as per SAP Success response.
	*/
	public class d {
		public List<results> results;
		public String InstId; 
		public String FileName; 
		public String Stream;
		public String FileType;
	}

	/**
	 * @author Gladis
	 * @date    22-Dec-2021
	 * @description   class container as per SAP error response.
	*/
	public class error {
		public String code;
		public Message message;
	}

	/**
	 * @author Gladis
	 * @date    22-Dec-2021
	 * @description   holds information related to success messages.
	 */
	public class results {
		@AuraEnabled public String Customer;
		@AuraEnabled public String PartnerFn; 
		@AuraEnabled public String StartDate; 
		@AuraEnabled public String EndDate; 
		@AuraEnabled public String SalesOrder;
		@AuraEnabled public String Posnr;
		@AuraEnabled public String Delivery;
		@AuraEnabled public String DeliveryDate; 
		@AuraEnabled public String Material;
		@AuraEnabled public String MatDescription;
		@AuraEnabled public String Quantity;
		@AuraEnabled public String id;
		@AuraEnabled public String value;//error message
		@AuraEnabled public String Code; //error code
		@AuraEnabled public String Stream; //stream data sent from SAP on download

	}

	/**
	 * @author Gladis
	 * @date    22-Dec-2021
	 * @description   holds information related to error messages.
	 */
	public class message {
		public String lang;
		public String value;
	}
}

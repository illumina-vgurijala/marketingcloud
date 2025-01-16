/**
*    @author: Amit Sachan
*    @date:   18-Sep-2023
*    @description:  Main class to manage Associated Products functionality
*    Modification Log:
*    ------------------------------------------------------------------------------------
*         Developer           Date             Description
*    Siddartha Reddy Kalam    28-Nov-2023      Initial version - CMCM-3980    
	Dhairya Shah			  31-Jan-24	.        CMCM-3591
*    ------------------------------------------------------------------------------------
*/
public with sharing class AssociatedProductsWrapper {
    @AuraEnabled
    public Id id { get; set; }
    @AuraEnabled
    public String name { get; set; }
    @AuraEnabled
    public String productName { get; set; }
    @AuraEnabled
    public String productId { get; set; }
    @AuraEnabled
    public String productCode { get; set; }
    @AuraEnabled
    public String type { get; set; }
    @AuraEnabled
    public Boolean isPrimary { get; set; }
    @AuraEnabled
    public Id installedProduct { get; set; }
    @AuraEnabled
    public String installedProductName { get; set; }
    @AuraEnabled
    public String serialNumber { get; set; }
    @AuraEnabled
    public Boolean ivdIdentifier { get; set; }
    @AuraEnabled
    public String subscription { get; set; }
    @AuraEnabled
    public String subscriptionId { get; set; }
    @AuraEnabled
    public String lotNumber { get; set; }
    @AuraEnabled
    public DateTime expiredDate { get; set; }
    @AuraEnabled
    public Boolean isExpired { get; set; }
    @AuraEnabled
    public String version { get; set; }
    @AuraEnabled
    public String location { get; set; }
    public cls_fields[] fields;
    public boolean isDeleted;
    // added by dhairya shah for CMCM 7944
    @AuraEnabled
    public String activeContract { get; set; }

    /*@description: -- cls_fields wrapper class with fields variable*/
	public class cls_fields {
		public boolean isPrimary;
		public String id;
        public String productName;
        public String version;
        public Boolean isExpired;
        public String lotNumber;
        public String subscription;
        public String serialNumber;
        public String installedProductName;
        public DateTime expiredDate;
        public String activeContract; // added by dhairya shah for CMCM 7944

	}
    
}

/**
 * @author 
 * @date   2018-07-10
 * @description    DCP-905:
 * Modification Log:   
 */


public class EquipmentMasterWrapper {
    
    public List<InstalledProduct> InstalledProduct;
    
		
		/*
		* @description: wrapper class which holds data related to Installed Product
		*/                      	
    public class InstalledProduct{
        public String EquipmentId;        
        public String ERPCustomerId; 
        public String AcceptanceDate;
        public String InstalledDate; 
		public String ERPLocationId;
        
		/*
        * @description Constructor: to intantiate installed product data 
        * @param installProductId SVMXC__Installed_Product__c
        */	                       		
        public InstalledProduct(SVMXC__Installed_Product__c insPrd){
            this.EquipmentId = insPrd.ERP_Equipment_Id__c;
            this.ERPCustomerId =insPrd.SVMXC__Company__r.ERP_Customer_Id__c;
            this.AcceptanceDate =String.valueOf(insPrd.Acceptance_Date__c);
            this.InstalledDate =String.valueOf(insPrd.SVMXC__Date_Installed__c); 
			this.ERPLocationId =insPrd.SVMXC__Site__r.ERP_Customer_ID__c;
        }
    
    }

}
/**
 * @author 
 * @date   2018-07-12
 * @description    DCP-903:Service Contract Synchronization to DCP(ServiceMax) 
 * Modification Log:  
   ------------------------------------------------------------------------------------
 *      Developer                      Date                 Description
 *      Vaibhav                        2018-07-12            Initial Version
 *      Gopinath Reddy                 2019-12-24            Added few more fields for updating service contract record 
 *      Rahul Bishnoi                  2020-02-25            Added Primary Contact Field for DCP-34566
 *      Maruthi                        2020-08-30            Added Registration Status Field for IP2-41
 *      Dhairya Shah                   2024-02-29            CMCM-9
 */
public class ServiceContractDataReceiverWrapper {

	/*
	*  Wrapper Class for Service Contracts  
	*/	
  	public class serviceContracts {

    /* External Id */
    public String SVMX_PS_External_ID;

    public String Name;
    public String Status;
    public String ERP_Header_Contract_Number;
    public String ERP_Contract_Type;
    public String ERP_Contract_Line_Number;
    public String SVMXC_Cancelation_Notes;

    /* Lookup variable */
    public String SVMXC_Company; // selectAccountsForERPCustomerIds
    public String SVMXC_Service_Plan; // selectServicePlanForItemNumber
    public String SVMXC_Order_Line_Item;
    public String Registration_Contact;
    
    /* SFDC ID's placeholder */
    public String SVMXC_Company_SFDC_Id; // selectAccountsForERPCustomerIds
    public String SVMXC_Service_Plan_SFDC_Id; // selectServicePlanForItemNumber
    public String SVMXC_Order_Line_Item_SFDC_Id;
    public String Registration_Contact_SFDC_Id;
    public String SVMXC_Contact_SFDC_Id;

    /* Date Fields */
    //these dates are also copied to each of the covered product.
    public String SVMXC_Start_Date;
    public String SVMXC_End_Date;

    // Created as part of DCP-30474
    public Boolean Custom_License_Flag;
    public String Domain_ID;
    public String Domain_URL_Pattern;
    public Boolean Field_Installation;
    public String Instance_Region;
    public String Dragen_Connectivity;
    
    public String Registration_Contact_Email;
    public String Workgroup_ID;
    public String Workgroup_Name;
    public String Zuora_Subscription_ID;
    public String SVMXC_Contact;

    // Created as part of DCP-34566
    public String Primary_Contact_Email;
	
	// Created as part of IP2-41
    public String Object_Status;

    //List to hold covered products records.
    public List < CoveredProducts > CoveredProducts = new List < CoveredProducts > ();

    //List to hold covered location records.
    public List < CoveredLocations > CoveredLocations = new List < CoveredLocations > ();
	
	
	/*******************************************************************************************************
    * @description Method to populate Service Contract field values
    * @return SVMXC__Service_Contract__c
    */	
    public SVMXC__Service_Contract__c getServiceContractObj() {

      //Passing few more fields as part DCP-30474
	  //Passing Registration Status as part of IP2-41
      system.debug('*# :' + this);
      SVMXC__Service_Contract__c sContract = new SVMXC__Service_Contract__c(
        Primary_Contact_Email__c = this.Primary_Contact_Email,
        SVMX_PS_External_ID__c = this.SVMX_PS_External_ID,
        Name = this.Name,
        Status__c = this.Status,
		Registration_Status__c = this.Object_Status,
        ERP_Header_Contract_Number__c = this.ERP_Header_Contract_Number,
        ERP_Contract_Type__c = this.ERP_Contract_Type,
        ERP_Contract_Line_Number__c = this.ERP_Contract_Line_Number,
        SVMXC__Cancelation_Notes__c = this.SVMXC_Cancelation_Notes,
        Custom_License_Flag__c = this.Custom_License_Flag,
        Domain_ID__c = this.Domain_ID,
        Domain_URL_Pattern__c = this.Domain_URL_Pattern,
        Field_Installation__c = this.Field_Installation,
        Instance_Region__c = this.Instance_Region,
        Dragen_Connectivity__c = this.Dragen_Connectivity,
        Registration_Contact_Email__c = this.Registration_Contact_Email,
        Workgroup_ID__c = this.Workgroup_ID,
        Workgroup_Name__c = this.Workgroup_Name,
        SVMXC__Company__c = SVMXC_Company_SFDC_Id,
        SVMXC__Service_Plan__c = SVMXC_Service_Plan_SFDC_Id,
        Registration_Contact__c = Registration_Contact_SFDC_Id,
        Order_Line_Item__c = SVMXC_Order_Line_Item_SFDC_Id,
        SVMXC__Contact__c = this.SVMXC_Contact_SFDC_Id,
        ProductCode__c = this.ERP_Contract_Type == 'Software (ZWS)' || this.ERP_Contract_Type == 'Quantity Contract (ZCQ)' || this.ERP_Contract_Type == 'Software Contract'? this.SVMXC_Service_Plan : '',
        Zuora_Subscription_ID__c = this.Zuora_Subscription_ID);
      if (!String.isBlank(SVMXC_Start_Date)) {
        sContract.SVMXC__Start_Date__c = date.valueOf(this.SVMXC_Start_Date);
      }
      if (!String.isBlank(SVMXC_End_Date)) {
        sContract.SVMXC__End_Date__c = date.valueOf(this.SVMXC_End_Date);
      }

      return sContract;
    }

  }

	/*
	* Warpper class for Covered Products
	*/	
    public class CoveredProducts {

		/* External Id and to populate installed product lookup on CoveredProduct*/
		public String ERP_Equipment_Id;
		public String ERP_Equipment_SFDC_Id;

		/*******************************************************************************************************
		* @description Method to populate Covered Product field values
		* @return SVMXC__Service_Contract_Products__c
		*/
		public SVMXC__Service_Contract_Products__c getCoveredProductsObj() {
			SVMXC__Service_Contract_Products__c coveredProduct = new SVMXC__Service_Contract_Products__c(
				SVMXC__Installed_Product__c = ERP_Equipment_SFDC_Id
			);
			return coveredProduct;
		}

  	}

	/*
	* Warpper class for Covered Location
	*/	
  	public class CoveredLocations {

		/* External Id */
		public String ERP_Covered_Location;
		public String SVMXC_Site;
    //CMCM-9 added a new field for covered location as a SiteType 
    public String SiteType;//CMCM-9 CR Change 6th March 2024)

		/*******************************************************************************************************
		* @description Method to populate Covered Location field values
		* @return SVMXC__Service_Contract_Sites__c
		*/	
    	public SVMXC__Service_Contract_Sites__c getCoveredLocationObj() {
      		SVMXC__Service_Contract_Sites__c coveredLocation = new SVMXC__Service_Contract_Sites__c(SVMX_PS_External_ID__c = this.ERP_Covered_Location + '_' + this.SVMXC_Site);
      		return coveredLocation;
   		}

  	}

}



/* Sample JSON as part of DCP-30474

URI:/services/apexrest/ServiceContractSyncInterface/

[{
    "SVMX_PS_External_ID": "12344",
    "Name": "Test_new Description",
    "Status": "Blocked",
    "ERP_Header_Contract_Number": "0045001002",
    "SVMXC_Company": "6000006999",
    "ERP_Contract_Line_Number": "000012",
    "ERP_Contract_Type": "Illmna Base Warranty",
    "SVMXC_Cancelation_Notes": "Z1",
    "SVMXC_Start_Date": "2018-08-21",
    "SVMXC_Service_Plan": "",
    "SVMXC_End_Date": "2019-08-20",
    "Custom_License_Flag":true,
    "Domain_ID":"ABCD",
    "Domain_URL_Pattern":"ABCD",
    "Field_Installation":true,
    "Instance_Region":"ABCD",
    "Dragen_Connectivity":"Online",
    "Registration_Contact_Email":"ABCD",
    "Workgroup_ID":"ABCD",
    "Workgroup_Name":"ABCD",
    "Zuora_Subscription_ID":"ABCD",
    "CoveredProducts": [{
        "ERP_Equipment_Id": "1000704958"
    }],
    "CoveredLocations": [{
        "ERP_Covered_Location": "6000000293",
        "SVMXC_Site": "6000000293"

    }]

}]


*/
/**
 * @author Akash Kumar 
 * @date   2018-07-30
 * @description    US-4113: Product Bundle Synchronization 
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                            Version
*   Akash Kumar              2018-07-30          Wrapper Class of Product and related Bundle data 		Original
*                                                Added change                                           Modified
*	Joshith K				 2018-11-02			 DCP-13185 change										Modified
*	Nesar Mohan				 2022-04-01			 CodeScan
*  -----------------------------------------------------------------------------------          
*/
public with sharing class FlexBundleWrapper {

	/*
    *  @Author		: Akash Kumar
    *  @Description	: WrapperClass
    */

	public class ProductOptionsGroup {
		public String Id;
		public String Name;
		public String ContentType;
		public String DetailPage;
		public Boolean IsHidden;
		public Boolean IsLeaf;
		public Boolean IsPicklist;
		public Decimal Left;
	}

	/*
    *  @Author		: Akash Kumar
    *  @Description	: WrapperClass
    */

	public class BundleProductWrapper {
		public String ProductCode;
		public String Apttus_Config2_ConfigurationType;
		public String Sequence;

		/*
    	*  @Author		: Akash Kumar
    	*  @Description	: WrapperClass parameterized constructor to initialize the values
    	*/

		public BundleProductWrapper(Product2 prd)
		{
			this.ProductCode = prd.ProductCode;
			this.Apttus_Config2_ConfigurationType = prd.Apttus_Config2__ConfigurationType__c;
		}

		/*
		*  @author 		: Joshith k
		*  @Description : New constructor for component product in bundle  with sequence number.
		*  @params       : product record ,sequence no 
		*/

		public BundleProductWrapper(Product2 prd, String sequence)
		{
			this.ProductCode = prd.ProductCode;
			this.Apttus_Config2_ConfigurationType = prd.Apttus_Config2__ConfigurationType__c;
			this.Sequence = sequence;
		}
	}

	/*
    *  @Author		: Akash Kumar
    *  @Description	: WrapperClass
    */

	public class ProductHeader
	{
		public String Bundle_Id;
		public String Bundle_Name;
		public List<BundleProductWrapper> Bundle_Products;
		public Datetime Apttus_Config2_EffectiveDate;
		public Datetime Apttus_Config2_ExpirationDate;
		public String Bundle_Description;
		public String Bundle_Segment;
		public String Bundle_Channel;
		public Boolean isActive;

		/*
    	*  @Author		: Akash Kumar
    	*  @Description	: WrapperClass parameterized constructor
		*  use this wrapper, passing primary Product2 details, & its related Bundle list
    	*/
		
		public ProductHeader(Product2 prd, List<BundleProductWrapper> lstBundleProducts)
		{
			if (prd.Bundle_Id__c != null && !String.isBlank(prd.Bundle_Id__c))
				this.Bundle_Id = prd.Bundle_Id__c;

			if (prd.Bundle_Name__c != null && !String.isBlank(prd.Bundle_Name__c))
				this.Bundle_Name = prd.Bundle_Name__c;

			if (prd.Apttus_Config2__EffectiveDate__c != null && !String.isBlank(String.valueOf(prd.Apttus_Config2__EffectiveDate__c)))
				this.Apttus_Config2_EffectiveDate = prd.Apttus_Config2__EffectiveDate__c;

			if (prd.Apttus_Config2__ExpirationDate__c != null && !String.isBlank(String.valueOf(prd.Apttus_Config2__ExpirationDate__c)))
				this.Apttus_Config2_ExpirationDate = prd.Apttus_Config2__ExpirationDate__c;

			if (prd.Bundle_Description__c != null && !String.isBlank(prd.Bundle_Description__c))
				this.Bundle_Description = prd.Bundle_Description__c;

			if (prd.Bundle_Segment__c != null && !String.isBlank(prd.Bundle_Segment__c))
				this.Bundle_Segment = prd.Bundle_Segment__c;

			if (prd.Bundle_Channel__c != null && !String.isBlank(prd.Bundle_Channel__c))
				this.Bundle_Channel = prd.Bundle_Channel__c;

			if (prd.IsActive != null && !String.isBlank(String.valueOf(prd.IsActive)))
				this.isActive = prd.IsActive;

			if (lstBundleProducts != null && !lstBundleProducts.isEmpty())
				this.Bundle_Products = lstBundleProducts;
		}
	}
}

/*
Sample JSON

{
  "productHeader" :[{
		"Bundle_Id":"BundleId", 
		"Bundle_Name":"BundleName",
		"Bundle_Products":[  
		  {  
			 "Sequence":null,//null for primary bundle product and values for all standalone inside bundle
			 "ProductCode":"Material1#",
			 "Apttus_Config2__ConfigurationType":"bundle" // if bundle then it is Primary Product
		  },
		  {  
			 "Sequence":"1",
			 "ProductCode":"Material2#",
			 "Apttus_Config2__ConfigurationType":"standalone" 
		  },
		  {  
			 "Sequence":"2",
			 "ProductCode":"Material3#",
			 "Apttus_Config2__ConfigurationType":"standalone"
		  }
		],
		"Apttus_Config2_EffectiveDate":"2018-07-17T18:25:43.511",
		"Apttus_Config2__ExpirationDate":"2018-12-31T18:25:43.511",
		"Description":"This where bundle decription will be sent",
		"Bundle_Segment":[  
		  "Segment1"
		],
		"Bundle_Channel":"online",
		"isActive":"active"
	}]
}

*/
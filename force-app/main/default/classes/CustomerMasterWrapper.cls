/**
 * @author Akshay Mohan
 * @date   2018-06-26
 * @description    US-351:Customer Master Synchronization to DCP (INT_MDM-030-001)
 * Modification Log:
 *       -------------------------
 *
 * Akshay Mohan         27/06/2018          Original Version
 * Digvijay Singh       07/08/2018          Modified
 * Karthik Madugula     06/09/2018          DCP-9649 & 11856 Updates
 * Swapna Satapathy     18/09/2018          DCP-11856 updates
 * Ashish Kr.			10/04/2019			DCP-24593 updates
 * Satya Swain          16/08/2019          INC0222689  
 * Roopal Verma         26/09/2019          DCP-28565, Added logic for Bank detail fields
 * Kushagra Desai       13-Dec-2019         DCP-31788 : Price group sync
 * Pankaj Sharma        02-Feb-2020         DCP-33708 : Price group description sync
 * Roopal Verma         25/11/2019          DCP-28541 Added Default_Partner 
 * Arnab Modak          18/11/2019          DCP-31058, Mapping CareOfLocal of CMD object
 * Saurav Bhandari      12-Feb-2020         DCP-28606 : Added GCP_Quality_IVD_Status__c field
 * Satya Swain          06-July-2020        INC0260877 : Remove blocks assignments
 * Prem Ranjan          24-March-2022       DCP-43591-Account: Ability to view Address data on related Accounts
 * Koustubh M           22-March-2022       INC0384102: removed 'isNotBlank()' check for field Channel_Partner_Type__c to allow empty value
 * Jitesh Lakhwani      6-July-2022         Code Scan fixes of Comments
 * Parthasarathy D      25-Aug-2022         DCP-55534
 * Gerardo Garcia       05-May-2024         CMCM-7687 add constructor for populating wrapper from account. Used on CustomerMasterUpdateDataSender.
 */

public class CustomerMasterWrapper {
    public static final String ERP_VARIABLE = 'ERP';
    private static final String SF_SYSTEM_ID = 'Salesforce';

    /** description : this is will return the data of the account relationship object.  */
    public class AccountRelationship
    {
        public String Account_Sales_Area;
        public String ERP_Customer_Id;
        public String Related_Account;
        public String ERP_Account_Relation;
        public String Relationship;
		public Boolean Default_Partner;  
                                                                  // Added for DCP-28541

        /** owner :  
         * @description : this is will prepare the data of the account relationship object and will return it.  
         * @param : none
         * @return : account relationship object 
         * */
        public Account_Relationship__c getSobject()
        {
            Account_Relationship__c accRelObj=new Account_Relationship__c();
            accRelObj.Account_Sales_Area__c=this.Account_Sales_Area;
            accRelObj.ERP_Account_Relationship_Id__c=this.ERP_Account_Relation;
            if(this.Related_Account != null ){//DCP-43591
                Customer_Master_Data__c cmdObj = new Customer_Master_Data__c(ERP_Customer_Id__c = this.Related_Account);
                accRelObj.Related_Account__r=cmdObj;
            }
            accRelObj.Relationship__c=this.Relationship;//objectToPicklistValueMap.get('Relationship__c').get(this.Relationship);
            accRelObj.ERP_Customer_Id__c=this.ERP_Customer_Id;
            accRelObj.Related_ERP_Customer_Id__c = this.Related_Account;
            accRelObj.isInactive__c = false;
            accRelObj.Default_Partner__c = this.Default_Partner == null ? false : this.Default_Partner;                                             //Added for DCP-28541
            return accRelObj;
        }
    }
    /** DCP-55534
     * description : this is will return the data of the account discount tier object.  */
    public class DiscountTiers {
        public Integer Consumable_Tier;
        public Integer Instrument_Tier;
        public Integer Service_Tier;        
       
        // Method to return the object instance.
        /* @description : this is will prepare the data of the Account Discount Tier and will return it.  
         * @param : Sales Area and Discount Type.
         * @return : Account Discount Tier object
         * */
        public Account_Discount_Tier__c getSobject(SalesArea objSalesArea, String strDiscountType) {
            Account_Discount_Tier__c objAdt = new Account_Discount_Tier__c();
            objAdt.ERP_Customer_Id__c = objSalesArea.ERP_Customer_Id;
            objAdt.Sales_Area__c = objSalesArea.Sales_Organization;
            objAdt.Distribution_Channel__c = objSalesArea.Distribution_Channel;
            objAdt.isInactive__c = false;
            if(strDiscountType == System.Label.AccountDiscountTierTypeConsumables) {
                objAdt.Discount_Type__c = System.Label.AccountDiscountTierTypeConsumables;
                objAdt.Pricing_Tier__c = objSalesArea.DiscountTiers.Consumable_Tier;
                objAdt.External_Id__c = objSalesArea.ERP_Customer_Id + '-' + objSalesArea.Sales_Organization + '-' + objSalesArea.Distribution_Channel + '-' + System.Label.AccountDiscountTierTypeConsumables;
            } else if(strDiscountType == System.Label.AccountDiscountTierTypeInstrument) {
                objAdt.Discount_Type__c = System.Label.AccountDiscountTierTypeInstrument;
                objAdt.Pricing_Tier__c = objSalesArea.DiscountTiers.Instrument_Tier;
                objAdt.External_Id__c = objSalesArea.ERP_Customer_Id + '-' + objSalesArea.Sales_Organization + '-' + objSalesArea.Distribution_Channel + '-' + System.Label.AccountDiscountTierTypeInstrument;
            } else if(strDiscountType == System.Label.AccountDiscountTierTypeServices) {
                objAdt.Discount_Type__c = System.Label.AccountDiscountTierTypeServices;
                objAdt.Pricing_Tier__c = objSalesArea.DiscountTiers.Service_Tier;
                objAdt.External_Id__c = objSalesArea.ERP_Customer_Id + '-' + objSalesArea.Sales_Organization + '-' + objSalesArea.Distribution_Channel + '-' + System.Label.AccountDiscountTierTypeServices;
            }
            return objAdt;
        }
    }
    /**
     * @description : bank group wrapper to store bank details
     */
	public class BankGroup //DCP-28565
        {
            public String Bank_Account_Number; 
            public String Bank_Name;
            public String Bank_Branch;
            public String Street;
            public String City;
            public String Region;
            public String Country;
        } 

    /**
     * @description : Sales area wrapper to store sales area details
     */
    public class SalesArea
    {
        public String ERP_Account_Sales_Area_Id;
        public String ERP_Customer_Id;
        public String Company_Code;
        public boolean IsInactive;
        public String Id;
        public String Sales_Organization;
        public String Division;
        public String Distribution_Channel;
        public String Price_List_Type;
        public List<AccountRelationship> AccountRelationship;
        public String CurrencyIsoCode;
        public String Term_Of_Payment;
        public String Transportation_Zone;
        public String Contract_Number;
        public String Incoterm1;
        public String Incoterm2;
        public String Account;
        public String Customer_Master_Data;
        //DCP-24593 : Ashish Kr.
        public String Channel_Partner_License_Expiration_Date;
        public String Channel_Partner_License_Number;
        public String Clinical_Institution_License_Exp_Date;
        public String Clinical_Institution_License_Number;
        //DCP-31788 : Price group sync
        public string Price_Group;
        //DCP-33708 : Price Group desc sync
        public string Price_Group_Description;
        //DCP-55534
        public DiscountTiers DiscountTiers; 

        /**
        * @description : Sales area wrapper class default constructor
        */
        public SalesArea() { }

        /**
        * @description : Sales area wrapper class parameterized constructor where sales area meta deta is passed to populate sales area.
        * @param : Sales_Area__mdt sa
        */
        public SalesArea(Sales_Area__mdt sa)
        {
            this.Company_Code = sa.Company_Code__c;
            this.Sales_Organization = sa.Sales_Organization__c;
            this.Division = sa.Division__c;
            this.Distribution_Channel = sa.Distribution_Channel__c;
            this.Price_List_Type = sa.Price_List_Type__c;
            this.Term_Of_Payment = sa.Term_Of_Payment__c;
            this.Transportation_Zone = sa.Transportation_Zone__c;
        }

        /**
        * @description : Sales area wrapper class parameterized constructor to populate sales area along with account relationship.
        * @param : Sales_Area__mdt sa, List<AccountRelationship> AccountRelationship
        */
        public SalesArea(Sales_Area__mdt sa, List<AccountRelationship> AccountRelationship)
        {
            this.ERP_Account_Sales_Area_Id= null;
            this.Company_Code = sa.Company_Code__c;
            this.Sales_Organization = sa.Sales_Organization__c;
            this.Division = sa.Division__c;
            this.Distribution_Channel = sa.Distribution_Channel__c;
            this.Price_List_Type = sa.Price_List_Type__c;
            this.AccountRelationship= new List<AccountRelationship>();
            this.Term_Of_Payment = sa.Term_Of_Payment__c;
            this.Transportation_Zone = sa.Transportation_Zone__c;
        }

        /**
        * Method Name : getSObject   
        * @description : this will create an sales area object and will populate the populate the data for the same.
        * @param : None
        * @return Account Sales Area. 
        */
        public Account_Sales_Area__c getSObject()
        {
            Account_Sales_Area__c  s1 = new Account_Sales_Area__c(
                    Sales_Organization__c=this.Sales_Organization,
                    Distribution_Channel__c=this.Distribution_Channel,
                    ERP_Account_Sales_Area_Id__c = this.ERP_Account_Sales_Area_Id,
                    IsInactive__c=this.IsInactive,
                    Price_List_Type__c=this.Price_List_Type,
                    Company_Code__c=this.Company_Code,
                    Division__c=this.Division,
                    CurrencyIsoCode = this.CurrencyIsoCode,
                    Term_Of_Payment__c=this.Term_Of_Payment,
                    Contract_Number__c=this.Contract_Number,
//             Incoterm1__c=objectToPicklistValueMap.get('Incoterm1__c').get(this.Incoterm1),
                    Inco_Term_1__c=this.Incoterm1,//objectToPicklistValueMap.get('Inco_Term_1__c').get(this.Incoterm1),
                    Incoterm2__c=this.Incoterm2,
                    Customer_Master_Data__c = this.Customer_Master_Data,
                    Account__c = this.Account,
                	//DCP-24593 : Ashish Kr.
                	Channel_Partner_License_Expiration_Date__c = QuotationDataRecieverWrapper.stringTODateFormatConversion(this.Channel_Partner_License_Expiration_Date),
                    Channel_Partner_License_Number__c = this.Channel_Partner_License_Number,
                    Clinical_Institution_License_Exp_Date__c = QuotationDataRecieverWrapper.stringTODateFormatConversion(this.Clinical_Institution_License_Exp_Date),
                    Clinical_Institution_License_Number__c = this.Clinical_Institution_License_Number,
                    Price_Group__c = this.Price_Group,
                    Price_Group_Description__c = this.Price_Group_Description
            );
            return s1;
        }

    }

    /**
    * @description : Account header class is a wrapper class for account / sales area / bank details of the customer.  
    */
    public class AccountHeader
    {
        public String Order_Block;
        public String Name;
        public String Full_Name;
        public String Street_Line1;
        public String Street_Line2;
        public String BillingStreet;
        public String BillingPostalCode;
        public String BillingCity;
		//DCP-18720 : Tushar
        public String BillingCountry;
        public String BillingCountryCode;
        public String BillingStateCode;
        public String Phone;
        public String PhoneValidityStartDate;
        public String PhoneValidityEndDate;
        public String CorrespondenceLanguageCode;
        public String CurrencyIsoCode;
        public String Account_Group;
        public String AddressRepresentationCodeName;
        public String AddressRepresentationCodeAddress;
        public String NameLocal;
        public String Street_2_Local;
        public String Street_Local;
        public String Zip_Postal_Code;
        public String City_Local;
        public String Country_Local;
        public String State_Province_Local;
        public String Id;
        public String SystemID;
        public String RequesterEmailId;
        public String InternalID;
        public String RoleCode;
        public String CategoryCode;
        public String PricingProcedureDeterminationCode;
        public String TransportServiceLevelCode;
        public String TaxGroupCode;
        public String GLAccountID;
        public String ParentERPCustomerId;
        public List<SalesArea> SalesArea;
        public String Channel_Partner_Type;
        public String Contractnumber;
        public String AccountNumber;
        public String Indicator;
        public String Website;
        public String isDeleted;
        public String ERP_Customer_Id;
        public String ParentAccount;
        public String ExternalId;
        public boolean Mark_For_Deletion;
        public String Care_Of;
        public String Care_Of_Local;
        public String Global_Group_Number;
        public String National_Group_Number;
        public String Sales_Group_Number;
        public String Global_Group_Name;
        public String National_Group_Name;
        public String Sales_Group_Name;
        public String Preferred_language;
        public String Zip_Postal_Code_Local;
        public String Account_Name_Local;
        public String BillingStateName;
        public String BillingCountryName;
		public String Tax_Id;
		public List<CustomerMasterWrapper.BankGroup> BankGroup;                 //DCP-28565
		public String GCP_Quality_IVD_Status;                                   //DCP-28606
        public string ClinicalType ;                                            //CMCM-7687

        /**  
        * @description : Account Header default constuctor.
        **/
        public AccountHeader() { }

        /**  
        * @description : Account Header constuctor to populate the account header details along with sales area.
        */
        public AccountHeader(Account acc, List<SalesArea> SalesArea)
        {
            Map<String, Map<String,String>> fieldAPIToPicklistValueMap=UtilsSettings.getCustomMetadataPicklistMap('Account',ERP_VARIABLE, true);
            this.Full_Name = acc.Name;
            this.Name = acc.Name.abbreviate(80);
            this.isDeleted = 'false';
            this.ExternalId = acc.ERP_Customer_Id__c;
            this.BillingStreet = acc.BillingStreet;
            this.BillingPostalCode = acc.BillingPostalCode;
            this.BillingCity = acc.BillingCity;
            this.BillingCountryCode = acc.BillingCountryCode;
            this.BillingStateCode = acc.BillingStateCode;
            this.Phone = acc.Phone;
            this.PhoneValidityStartDate = '1000-01-01';
            this.PhoneValidityEndDate  = '9999-12-31';
            this.CorrespondenceLanguageCode = 'EN';
            this.CurrencyIsoCode = acc.CurrencyIsoCode;
            this.NameLocal = acc.NameLocal;
            this.AddressRepresentationCodeName =  String.isBlank(acc.NameLocal) ? null : 'I';
            this.AddressRepresentationCodeAddress =  String.isBlank(acc.NameLocal) ? null : 'I';
            this.Street_2_Local = (String.isNotBlank(acc.Street_2_Local__c) && (acc.Street_2_Local__c).length() > 60) ? (acc.Street_2_Local__c).substring(0,60) : acc.Street_2_Local__c;
            this.Street_Local = (String.isNotBlank(acc.Street_Local__c) && (acc.Street_Local__c).length() > 40) ? (acc.Street_Local__c).substring(0,40) : (acc.Street_Local__c);
            this.City_Local = acc.City_Local__c;
            //DCP-20818 : Tushar
            this.Country_Local = acc.Country_Local__c;
            this.State_Province_Local = acc.State_Province_Local__c;

            if (fieldAPIToPicklistValueMap.get('Account_Group__c').containskey(acc.Account_Group__c))
                this.Account_Group = fieldAPIToPicklistValueMap.get('Account_Group__c').get(acc.Account_Group__c);

            String strId =acc.AccountId_18_Char_Id__c;
            System.debug('*****Line226****'+acc.AccountId_18_Char_Id__c);
            this.Id = strId;
            this.SystemID = SF_SYSTEM_ID;
            this.RequesterEmailId = acc.LastModifiedBy.Email;
            this.RoleCode = 'FLCU01';
            this.CategoryCode = '2';
            this.PricingProcedureDeterminationCode = '1';
            this.TransportServiceLevelCode = '01';
            this.TaxGroupCode = '1';
            this.GLAccountID = '121000';
            this.SalesArea = SalesArea;
            this.InternalID = strId.substring(strId.length() - 10, strId.length());
            this.Channel_Partner_Type = acc.Channel_Partner_Type__c;
            this.AccountNumber = acc.ERP_Customer_Id__c;
            this.ParentERPCustomerId = acc.Parent.ERP_Customer_Id__c;
            this.Website = acc.Website;
            this.Zip_Postal_Code_Local = acc.Zip_Postal_Code_Local__c;
            this.Care_Of = acc.Care_Of__c;
            this.Care_Of_Local = acc.Care_Of_Local__c;
        }

        /**  
        * Method Name : AccountHeader
        * @description : Account Header default constuctor. CMCM-7687
        * @param : acc
        * @return :NA
        */
        public AccountHeader(Account acc) {
            Map<String, Map<String,String>> objectToPicklistValueMap = UtilsSettings.getCustomMetadataPicklistMap('Account','ERP', true);
            String accountgroup = acc.Account_Group__c != null? objectToPicklistValueMap.get('Account_Group__c').get(acc.Account_Group__c) : null;

            ilib_LogEvent.message('accountgroup:' + accountgroup);
            String strId = acc.AccountId_18_Char_Id__c;
            this.Id = strId;
            ilib_LogEvent.message('acc:' + JSON.serializePretty(acc));
            this.Account_Group = accountgroup; 
            this.CategoryCode = '2';
            this.InternalID = strId.substring(strId.length() - 10,strId.length());
            this.ID = acc.ID;
            this.ERP_Customer_Id = acc.ERP_Customer_Id__c;
            this.SystemID = SF_SYSTEM_ID;
            this.ClinicalType = acc.Clinical_Type__c;
        }

        /**
        * Method Name : getSObject   
        * @description : this will create an Account object and will populate the populate the data for the same.
        * @param : None
        * @return Account 
        */
        public Account getSObject()
        {

            Account s1 = new Account(
                    Name = this.Full_Name,
                    BillingCity=this.BillingCity,
                    BillingCountryCode=this.BillingCountryCode,
                    BillingPostalCode=this.BillingPostalCode,
                    BillingStateCode=this.BillingStateCode,
                    BillingStreet=this.Street_Line1+'\r\n'+ this.Street_Line2,
                    CurrencyIsoCode=this.CurrencyIsoCode,
                    ERP_Customer_Id__c=this.ERP_Customer_Id,
                    Phone=this.Phone,
                    Account_Group__c=this.Account_Group,//objectToPicklistValueMap.get('Account_Group__c').get(this.Account_Group),
                    NameLocal=this.NameLocal,
                    City_Local__c=this.City_Local,
                    Zip_Postal_Code_Local__c=this.Zip_Postal_Code_Local,
                    Street_Local__c=this.Street_Local,
                    Street_2_Local__c=this.Street_2_Local,
                    Country_Local__c=this.Country_Local,
                    State_Province_Local__c=this.State_Province_Local,
                    Id=this.id==''?null:this.id,
                    Mark_For_Deletion__c=this.Mark_For_Deletion,
                    Care_Of__c=this.Care_Of,
                    Care_Of_Local__c=this.Care_Of_Local,
                    Order_Block__c=this.Order_Block,
                    Global_Group_Number__c=this.Global_Group_Number,
                    National_Group_Number__c=this.National_Group_Number,
                    Sales_Group_Number__c=this.Sales_Group_Number,
                    Global_Group_Name__c=this.Global_Group_Name,
                    National_Group_Name__c=this.National_Group_Name,
                    Sales_Group_Name__c=this.Sales_Group_Name,
                    Preferred_Language__c=this.Preferred_language,
					GCP_Quality_IVD_Status__c = String.isBlank(this.GCP_Quality_IVD_Status) ? '' : this.GCP_Quality_IVD_Status == 'Y' ? System.Label.GCPQualityIVDStatusQualified : this.GCP_Quality_IVD_Status == System.Label.GCPQualityIVDStatusQualified ? System.Label.GCPQualityIVDStatusQualified : this.GCP_Quality_IVD_Status == 'N' ? System.Label.GCPQualityIVDStatusNotQualified : this.GCP_Quality_IVD_Status == System.Label.GCPQualityIVDStatusNotQualified ? System.Label.GCPQualityIVDStatusNotQualified:'',
                    Is_Updated_By_System__c=true,
                    Channel_Partner_Type__c=this.Channel_Partner_Type //INC0384102- removed 'isNotBlank()' check for field Channel_Partner_Type__c to allow empty value
            );
            return s1;
        }

        /**
        * Method Name : getCustMastDataSobject   
        * @description : this will create an Customer master data object and will populate the populate the data for the same.
        * @param : None
        * @return Customer Master Data 
        */
        public Customer_Master_Data__c getCustMastDataSobject()
        {

            Customer_Master_Data__c custMstDataObj=new Customer_Master_Data__c();
            custMstDataObj.ERP_Customer_Id__c=this.ERP_Customer_Id;
            custMstDataObj.Global_Group_Number__c=this.Global_Group_Number;
            custMstDataObj.National_Group_Number__c=this.National_Group_Number;
            custMstDataObj.Sales_Group_Number__c=this.Sales_Group_Number;
            custMstDataObj.Account_Group__c=this.Account_Group;//objectToPicklistValueMap.get('Account_Group__c').get(this.Account_Group);
            custMstDataObj.CurrencyIsoCode=this.CurrencyIsoCode;
            custMstDataObj.SYSTEMID__c=this.SYSTEMID;
			custMstDataObj.Mark_For_Deletion__c=this.Mark_For_Deletion;
            custMstDataObj.Name = this.Name;
            custMstDataObj.Full_Customer_Name__c = this.Full_Name;
            custMstDataObj.Care_Of__c=this.Care_Of;
            custMstDataObj.Care_Of_Local__c	=this.Care_Of_Local; //DCP-31058
            custMstDataObj.Order_Block__c=this.Order_Block;
            custMstDataObj.Street__c=this.Street_Line1;
            custMstDataObj.Street_2__c=this.Street_Line2;//DCP-29731
            custMstDataObj.Zip_Postal_Code__c=this.BillingPostalCode;
            custMstDataObj.City__c=this.BillingCity;
			//DCP-18720 : Tushar
            custMstDataObj.Country__c=this.BillingCountryName;
            custMstDataObj.Country_Code__c=this.BillingCountryCode;
            custMstDataObj.State_Province__c=this.BillingStateName;
            custMstDataObj.Phone__c=this.Phone;
			// changed for INC0222689
            custMstDataObj.Account_Name_Local__c=this.NameLocal;
            custMstDataObj.Street_2_Local__c=this.Street_2_Local;
            custMstDataObj.Street_Local__c=this.Street_Local;
            custMstDataObj.Zip_Postal_Code_Local__c=this.Zip_Postal_Code_Local;
            custMstDataObj.City_Local__c=this.City_Local;
            custMstDataObj.Country_Local__c=this.Country_Local;
            custMstDataObj.State_Province_Local__c=this.State_Province_Local;
			custMstDataObj.Tax_ID__c=this.Tax_Id;                  //DCP-28565

            return custMstDataObj;
        }

        /**
        * Method Name : getSobjectForHierarchy   
        * @description : this will return an account object by populating ERP Customer Id.
        * @param : None
        * @return Account 
        */
        public Account getSobjectForHierarchy()
        {
            Account  s1 = new Account(
                ERP_Customer_Id__c=this.AccountNumber
            );
            return s1;
        }
    }

    

}
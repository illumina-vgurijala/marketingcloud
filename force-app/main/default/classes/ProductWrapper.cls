/**
 *    @author Sravan Panchangam
 *    @date   11-09-2018
 *    @description   Product Wrapper is used to deserialize the json and map the values to Product2 and Product_Sales_Area__c objects
 *    
 *    Test class for 75% coverage: TestProductDataReceiver
 *    Test class for 90% coverage: TestProductDataReceiver
 * 
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *      Developer                      Date                 Description
 *      Sravan Panchangam              11-09-2018           Initial Version
 *      Akshay Mohan                   12-03-2019           DCP-31253 Add field for Zuora Product Id
 *      Akshay Mohan                   01-13-2019           DCP-32360 Add fields for informatics
 *		Pankaj Singla				   08-18-2020			DCP-40232 Add field for Material Group Code
 *      Vignesh sethuramlaingam        06-03-2021           DCP-33361 - Add Logic for NONFRU
 *      Rahul Bishnoi                  03-09-2021           TASK0568354 - Commented ununsed Code
 *      Adyasha Satapathy              26-05-2021           DCP-45787: Add field for Auto Create Billable Work Order
 *      Todd Newman                    06-24-2021           DCP-47136 - add product localization related object
 *      Jitesh Lakhwani                06-16-2022           DCP-53195 - Add Field for Open Offer Product Category
 *      Vivek R                        08-23-2022           DCP-56028 - Modified field value logic for Open Offer Product
 *      Siddartha Reddy Kalam          05-30-2023           CMCM-165 - Capture source system value to be SAP 
 *      Lovel Panchal                  03-22-2024           DGP-19 - Added the Discount_Grid_Group field for Product object.
*/
public class ProductWrapper {
    //DCP-45787
    private static final string STRING_PRODUCT_API_NAME = 'Product2';
    private static final string STRING_ERP_SYSTEM = 'ERP';
    private static final string STRING_DCWO_VALUE = 'DCWO';
    private static Map<String, Map<String,String>> fieldAPIToPicklistValueMap;
    private static final string SAP = 'SAP'; //CMCM-165

    /*
     * @Author: Sravan Panchangam
     * @Description : While deserializing the Json all the values that belong to Product2 are mapped to the variables in the Product class
     */
    public class Product {
        //Added for DGP-19
        public final String discount_Grid_Group;
        public String ProductCode;
		public String Batch_Management;//[DCP-31054]
        public String Old_Material_Number;
        public String ERP_Material_Header_Description;
        public String Line_Of_Business_Code;
        public String Product_Category_Code;
        public String Product_Line_Code;
        public String Product_Group_Code;
        public String Line_Of_Business;
        public String Product_Category;
        public String Product_Line;
        public String Product_Group;
        public String Number_Of_BeadChips_Per_Sample;
        public String Number_Of_Samples;
        public String Name;
        public String Description;
        public String Material_Group_1;
        public Boolean RMA_Required;
        public String Service_Level;
        public String FRU_Eligible;
        public String Material_Class;
		public String Material_Type;
        public Boolean Custom_Product;
        public Boolean Design_Critical_Part;
        public Boolean Decontamination_Required;
        public String SFDC_Block;
        public String Temperature_Description;
        public String Storage_Conditions;
        public String Device_Identifier;
        public String Material_Group;
        public String Replenishment_Eligible;
        public String Regulatory_Type;
        public String Cross_Plant_Material_Status;
        public String Cross_Plant_Material_Status_Description;
        public String FIN_Description;
        public String Sales_Notes;
        public String Service_Notes;
        public String Gross_Weight;
        public String Weight_Unit;
        public String Product_Manager;
        public String Commercial_Launch_Date;
        public Boolean Safety_Critical_Part;
        public String GFSL_FC_Hierarchy;
        public String Condition_Type;
        public String Serial_Number_Profile;
        public String End_of_Sale_Date;
        public String End_of_Ship_Date;
        public String End_of_Service_Date;
        public String Material_Class_Type;
        public String Cross_Distribution_Chain_Status;
        public String Service_Value;
        public String Product_Level_Indicator;
        public String Web_Sellable;
		//Added for DCP-17159
        public String Product_Specific_Terms;
		//public String Family;
        //Added for DCP-31253
        public String Zuora_Product_ID;
        //Added for DCP-32360
        public Decimal DRAGEN_Throughput_Gb;
        public Decimal Number_of_iCredits;
        public Decimal Number_of_Instances;
        public Decimal Number_of_Users;
        public Decimal Storage;
        public String Subscription_Tier;
        public String Fulfillment_Path;
        public String Informatics_Family;
        public String Informatics_SKU_Type;
		//Added for DCP-40232
		public String Material_Group_1_Code;
		//Added for DCP-42724
        public Boolean Dangerous_Good;
        //Added for DCP-45787
        public String Auto_Create_Billable_Work_Order;
        //Added for DCP-53195
        public String Open_Offer_Product_Category;
        //Added for DCP-56028
        public Boolean Open_Offer_Product;
        //Added for DCP-56850
        public String Commodity_Import_Code_India_HSN;
        public String Control_Code_India_SAC;

        public List<ProductSalesArea> productSalesArea;
        public List<ProductLocalization> productLocalization;

        /*
         *@Author: Sravan Panchangam
         *@Description: String to Date format Conversion for DCP-11857 (Conversion from YYYYMMDD to YYYY-MM-DD)
         *Note: this method is added temporarily as the utilRest is moved to other folder as it has less coverage
		 */
        public DateTime stringTODateTimeFormatConversion(String dateTimeString)
        {
            if (dateTimeString == null || dateTimeString.length() != 8) return null;

            String year = dateTimeString.substring(0, 4);
            String month = dateTimeString.substring(4,6);
            String day = dateTimeString.substring(6);

            return DateTime.valueOf(year + '-' + month + '-' + day + ' 00:00:00');
        }

        /*
         * @Author: Sravan Panchangam
         * @Description : Once the values are mapped to the variables then getSobject is method is used for mapping the variables with the fields in the Product2 object
		 */
        public Product2 getSObject()
        {
            UtilsRest utilRest = new UtilsRest();
            System.debug(this.Name);

            Product2 objProduct = new Product2(
                ProductCode=this.ProductCode,
                Batch_Management__c = String.isNotBlank(this.Batch_Management) ? Boolean.valueOf(this.Batch_Management) : false,//[DCP-31054]
                Old_Material_Number__c=this.Old_Material_Number,
                ERP_Material_Header_Description__c=this.ERP_Material_Header_Description,
                Line_Of_Business_Code__c=this.Line_Of_Business_Code,
                Product_Category_Code__c=this.Product_Category_Code,
                Product_Line_Code__c=this.Product_Line_Code,
                Product_Group_Code__c=this.Product_Group_Code,
                Line_Of_Business__c=this.Line_Of_Business,
                Product_Category__c=this.Product_Category,
                Product_Line_ilmn__c=this.Product_Line,
                Product_Group__c=this.Product_Group,
                Number_Of_BeadChips_Per_Sample__c=this.Number_Of_BeadChips_Per_Sample,
                Number_Of_Samples__c= this.Number_Of_Samples!=null ? utilRest.stringToDecimalConversion(this.Number_Of_Samples):null,
                Name=this.Name,
                Description=this.Description,
                Material_Group_1__c=this.Material_Group_1,
                RMA_Required__c=this.RMA_Required!=null?this.RMA_Required:false,
                Service_Level__c=this.Service_Level,
                FRU_Eligible__c=this.FRU_Eligible,
                Material_Class__c=this.Material_Class,
                Material_Type__c=this.Material_Type,
                Custom_Product__c=this.Custom_Product!=null?this.Custom_Product:false,
                Design_Critical_Part__c=this.Design_Critical_Part!=null?this.Design_Critical_Part:false,
                Decontamination_Required__c=this.Decontamination_Required!=null?this.Decontamination_Required:false,
                SFDC_Block__c=this.SFDC_Block,
                Temperature_Description__C=this.Temperature_Description,
                Storage_Conditions__c=this.Storage_Conditions,
                Device_Identifier__c=this.Device_Identifier,
                Material_Group__c=this.Material_Group,
                Replenishment_Eligible__c=this.Replenishment_Eligible,
                Regulatory_Type__c=this.Regulatory_Type,
                Cross_Plant_Material_Status__c=this.Cross_Plant_Material_Status,
                Cross_Plant_Material_Status_Description__c=this.Cross_Plant_Material_Status_Description,
                FIN_Description__c=this.FIN_Description,
                Sales_Notes__c=this.Sales_Notes,
                Service_Notes__C=this.Service_Notes,
                Gross_Weight__C=this.Gross_Weight,
                Weight_Unit__C=this.Weight_Unit,
                Commercial_Launch_Date__C=this.stringTODateTimeFormatConversion(this.Commercial_Launch_Date),
                Safety_Critical_Part__c=this.Safety_Critical_Part!=null?this.Safety_Critical_Part:false,
                GFSL_FC_Hierarchy__C=this.GFSL_FC_Hierarchy,
                Condition_Type__C=this.Condition_Type,
                Serial_Number_Profile__C=this.Serial_Number_Profile,
                End_Of_Sale_Date__c=this.stringTODateTimeFormatConversion(this.End_of_Sale_Date),
                End_Of_Ship_Date__c=this.stringTODateTimeFormatConversion(this.End_of_Ship_Date),
                End_Of_Service_Date__c=this.stringTODateTimeFormatConversion(this.End_of_Service_Date),
                Material_Class_Type__C=this.Material_Class_Type,
                Cross_Distribution_Chain_Status__c=this.Cross_Distribution_Chain_Status,
                Service_Value__c=this.Service_Value,
                Product_Level_Indicator__c=this.Product_Level_Indicator,
                Web_Sellable__c=this.Web_Sellable,
                Material_Number__c=this.ProductCode,
                //Added for DCP-17159
                Product_Specific_Terms__c = this.Product_Specific_Terms,
                //Added for DCP-31253
                Zuora_Product_ID__c = this.Zuora_Product_ID,
                //Added for DCP-32360
                DRAGEN_Throughput_Gb__c = this.DRAGEN_Throughput_Gb,
                Number_of_iCredits__c = this.Number_of_iCredits,
                Number_of_Instances__c = this.Number_of_Instances,
                Number_of_Users__c = this.Number_of_Users,
                Storage__c = this.Storage,
                Subscription_Tier__c = this.Subscription_Tier,
                Fulfillment_Path__c = this.Fulfillment_Path,
                Informatics_Family__c = this.Informatics_Family,
                Informatics_SKU_Type__c = this.Informatics_SKU_Type,
                // Added for DCP-40232
                Material_Group_1_Code__c=this.Material_Group_1_Code,
                // Added for DCP - 42724
                Dangerous_Goods__c=this.Dangerous_Good,
                //Added for DCP-56850
                Commodity_Import_Code_India_HSN__c = this.Commodity_Import_Code_India_HSN,
                Control_Code_India_SAC__c = this.Control_Code_India_SAC,
                //Added for DGP-19
                Discount_Grid_Group__C = this.discount_Grid_Group
            );

            //CMCM-165
            objProduct.Source_System__c = SAP;

            if (objProduct.Cross_Plant_Material_Status__c == 'Z3'
                || objProduct.Cross_Plant_Material_Status__c == 'Z4'
                || objProduct.Cross_Plant_Material_Status__c == 'Y1'
                || objProduct.Cross_Plant_Material_Status__c == 'Y2'
                || objProduct.Cross_Plant_Material_Status__c == 'Y3'
                || objProduct.Cross_Plant_Material_Status__c == 'Y4'
                || objProduct.Cross_Plant_Material_Status__c == 'Y5'
                || objProduct.Cross_Plant_Material_Status__c == 'Y6'
            ) {
                objProduct.IsActive = true;
            } else {
                objProduct.IsActive = false;
            }
            
            //DCP-45787
             String strAutoCreateBillableWOValue = getFieldAPIToPicklistValueSettings().get('Auto_Create_Billable_Work_Order__c').get(this.Auto_Create_Billable_Work_Order);
             if(String.isBlank(strAutoCreateBillableWOValue) && String.isNotBlank(this.Auto_Create_Billable_Work_Order) && !STRING_DCWO_VALUE.equals(this.Auto_Create_Billable_Work_Order)){
                 throw new UtilsRest.InterfaceException('Invalid value sent for Auto Create Billable Work Order: ' + this.Auto_Create_Billable_Work_Order + ' . Please send valid value');
             }
             else{
                 objProduct.Auto_Create_Billable_Work_Order__c = strAutoCreateBillableWOValue;
             }
             //End of DCP-45787

             //DCP-53915
             objProduct.Open_Offer_Product_Category__c = String.isBlank(this.Open_Offer_Product_Category) ? null : this.Open_Offer_Product_Category;
             //End of DCP-53915
            
             //DCP-56028
             objProduct.Open_Offer_Product__c = this.Open_Offer_Product!=null && this.Open_Offer_Product;
             //End of DCP-56028

            System.debug('From Product Wrapper' + objProduct);
            return objProduct;
        }
    }

    /*
     * @Author: Sravan Panchangam
     * @Description : While deserializing the Json all the values that are belonged to Product_Sales_Area__c are mapped to the variables in the ProductSalesArea class
    */
    public class ProductSalesArea {
        public String Distribution_Chain_Specific_Status;
        public String Sales_Organization;
        public String Distribution_Channel;
        public String Category_Group;
        public String ERP_Product_Sales_Area_ID;

        /*
         * @Author: Sravan Panchangam
         * @Description : After deserializing the values are mapped to the variables then getSobject is method is used for mapping the variables with the fields in the Product_Sales_Area__c object
		*/
        public Product_Sales_Area__c getSObject()
        {
            Product_Sales_Area__c objProductSalesArea = new Product_Sales_Area__c(
                Distribution_Chain_Specific_Status__c = this.Distribution_Chain_Specific_Status,
                Sales_Organization__c = this.Sales_Organization,
                Distribution_Channel__c = this.Distribution_Channel,
                Category_Group__c = this.Category_Group,
                ERP_Product_Sales_Area_Id__c = this.ERP_Product_Sales_Area_ID
            );

            return objProductSalesArea;
        }
    }

    /*
     * @Author: Todd
     * @Description: wrapper class for a Product_Localization__c record containing field names matching the interface JSON fields
    */
    public class ProductLocalization {
        public String Product_Localization_ID;
        public String ProductCode;
        public String Preferred_Language;
        public String Product_Name_Local;

        /*
         * @Author: Todd
         * @Description: convert the wrapper class to a Product_Localization__c SObject
		*/
        public Product_Localization__c getSObject()
        {
            return new Product_Localization__c(
                Product_Localization_ID__c = this.Product_Localization_ID,
                Preferred_Language__c = this.Preferred_Language,
                Product_Name_Local__c = this.Product_Name_Local,
                Name = this.Product_Name_Local
            );
        }
    }

    /**
     * @author Adyasha
     * @description returns map of String to map of key value pairs for Product Picklist Fields
     **/
    public static Map<String, Map<String,String>> getFieldAPIToPicklistValueSettings()
    {
        if (fieldAPIToPicklistValueMap == null)
        {
            fieldAPIToPicklistValueMap = UtilsSettings.getCustomMetadataPicklistMap(STRING_PRODUCT_API_NAME, STRING_ERP_SYSTEM, false);
        }
        return fieldAPIToPicklistValueMap;
    }
}
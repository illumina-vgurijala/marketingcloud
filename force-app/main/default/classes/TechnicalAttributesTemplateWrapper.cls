/***************************************************************************************************************************************
* NAME         : TechnicalAttributesTemplateWrapper
* DESCRIPTION  : DCP-54367 : Wrapper Class to hold Technical Attributes Template JSON
*                    
* @AUTHOR : Sagar Madkaikar
* @DATE   : 08-07-2020 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Sagar Madkaikar         20-07-2022           DCP-54367 Initial Version.   

****************************************************************************************************************************************/
public with sharing class TechnicalAttributesTemplateWrapper {
   
    public List<TechnicalAttributeFields> fields{get;set;}


    /*
     * Description - Wrapper Class TechnicalAttributeFields
     */
    public class TechnicalAttributeFields {
        public String title {get;set;}
        public String description {get;set;}
        public List<TechnicalAttributes> technicalAttributes {get;set;}
        
    
    }
    /*
     * Description - Wrapper Class TechnicalAttributes
     */
    public class TechnicalAttributes {
        public String label {get;set;}
        public String typeField {get;set;}
        public String sequence {get;set;}
        public String defaultValue {get;set;}
        public String unit {get;set;}
        public String readOnly {get;set;}
        public String format {get;set;}
        public String req {get;set;}
    }
        
    
}

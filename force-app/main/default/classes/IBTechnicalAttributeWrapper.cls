/***************************************************************************************************************************************
* NAME   : WorkOrders
* DESCRIPTION  : Domain class for WorkOrderTrigger.
*                    
* @AUTHOR : Digvjay Singh
* @DATE   : 17-Dec-2019 
* 
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Digvijay             17-Dec-2019          Initial Version. Added  for DCP-31083 .

******************************************************************************************************************************************/

public class IBTechnicalAttributeWrapper{
        
        public list<fields> fields{get;set;}

   /*
    * @Description- Wrapper Object
    */        
    public class technicalAttributes{
        public String readOnly{get;set;}
        public String picklistSfId{get;set;}
        public String sequence{get;set;}
        public String picklistId{get;set;}
        public String type{get;set;}
        public String label{get;set;}
        public String unit{get;set;}
        public String format{get;set;}
        public String defaultValue{get;set;}
    }

   /*
    * @Description- Wrapper Object
    */    
    public class fields{
        public String title{get;set;}
        public list<technicalAttributes> technicalAttributes{get;set;}
        public String description{get;set;}
    }
    
}
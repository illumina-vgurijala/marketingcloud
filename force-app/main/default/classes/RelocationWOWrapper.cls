/***************************************************************************************************************************************
* NAME         : RelocationWOWrapper
* DESCRIPTION  : Relocation Work Order Request from SVMX to GTS
*                
*                    
* @AUTHOR      : Sagar Madkaikar
* @DATE        : 07-Sep-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar       07-Sep-2021         CMCP-22: Initial Version
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/

public class RelocationWOWrapper {

    public String SvmxPartOrdTyp;
	public String SalesOrg;
	public String PartOrder;
	public String Division;
	public String DistrChan;
	public String Caseid;
	public String OrdReason;
	public List<NAVHDRTORET> NAVHDRTORET;
	public List<NAVHDRTOPTR> NAVHDRTOPTR;
	public List<NAVHDRTOITM> NAVHDRTOITM;
	public NAVHDRTOHDROUT NAVHDRTOHDROUT;
	

	/*
    * @author Sagar Madkaikar
    * @date   07-Sep-2021
    * @Description: CMCP-22:Inner Class
    */
    public class NAVHDRTOPTR {
		public String PartnRole;
		public String PartnNumb;

		/*
		* @author Sagar Madkaikar
		* @date   07-Sep-2021
		* @Description: CMCP-22:Inner Class Constructor
		*/
        public NAVHDRTOPTR(String PartnRole,String PartnNumb) {
            this.PartnRole=PartnRole;
            this.PartnNumb=PartnNumb;
        }
	}

	/*
    * @author Sagar Madkaikar
    * @date   07-Sep-2021
    * @Description: CMCP-22:Inner Class
    */
	public class NAVHDRTOHDROUT {
	}

	/*
    * @author Sagar Madkaikar
    * @date   07-Sep-2021
    * @Description: CMCP-22:Inner Class
    */
	public class NAVHDRTORET {
		/*public String Type;
		public String Parameter;
		public String MessageV4;
		public String MessageV3;
		public String MessageV2;
		public String MessageV1;
		public String Message;
		public String LogNo;
		public String LogMsgNo;
		public String Id;
		public String Field;*/
	}

	
	/*
    * @author Sagar Madkaikar
    * @date   07-Sep-2021
    * @Description: CMCP-22:Inner Class
    */
	public class NAVHDRTOITM {
		public String TargetQty;
		public String Material;
		public String ItmNumber;
		public String ItemCateg;
		/*
		* @author Sagar Madkaikar
		* @date   07-Sep-2021
		* @Description: CMCP-22:Inner Class Constructor
		*/
        public NAVHDRTOITM(String Material) {
            this.TargetQty='1.0000';//Default to one assuming that once case per instrument relocation will be created in Salesforce system.
            this.Material=Material;//Product code from the case
            this.ItmNumber='00010';//Considering the fact that the relocation will always have one instrument with on quantity, this should be 00010.
            this.ItemCateg='ZGTS';//This is a new field for relocation, and should be always populated with "ZGTS".
        }
	}

	/*
    * @author Sagar Madkaikar
    * @date   07-Sep-2021
    * @Description: CMCP-22:JSON parser method
    */
	
	public static RelocationWOWrapper parse(String json) {
		return (RelocationWOWrapper) System.JSON.deserialize(json, RelocationWOWrapper.class);
	}
}

/***************************************************************************************************************************************
* NAME         : PartsOrderResponseReceiver
* DESCRIPTION  : This class holds the variable which comes back in response after P2P integration callout is made from SVMX to SAP.                   
* @AUTHOR      : 
* @DATE        : 21-Aug-2018
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class PartsOrderResponseReceiver {

		/*
         * Constructor
         */

public PartsOrderResponseReceiver(){}

    //main class container as per SAP response
    public d d;
	
		/*
         * Constructor
         */	
    public class d {

        public NAVHDRTOITMOUT NAVHDRTOITMOUT;
        public NAVHDRTOHDROUT NAVHDRTOHDROUT;
        public NAVHDRTORET NAVHDRTORET;
		public String SvmxPartOrd;

    }

    
	
  /*
  * @description: Wrapper class holds information related to error/success messages.   
  */
    public class results {

        public String Type;
        public String Id;
        public String Message;
        public String LogNo;
        public String LogMsgNo;
        public String MessageV1;
        public String MessageV2;
        public String MessageV3;
        public String MessageV4;
        public String Parameter;
        public Integer Row;
        public String Field;
        public String ItmNumber;
        public String Material;
        public String TargetQty;
        public String PartOrdLn;
        public String Priority;
        public String ExpShpDt;
        public String ExpDelDt;

    }

  
	
	/*
  * @description: Wrapper class holds information related to child object (Part Order line)
  */
    public class NAVHDRTOITMOUT {
        public results[] results;
    }

	
		/*
    * @description: Wrapper class holds information related to header object (Part Order)
    */	
    public class NAVHDRTOHDROUT {
        //unique SAP number that will be updated in SVCMX.
        public String PartOrder;
        //Salesforce record id.
        public String SvmxPartOrd;
        public String DocNumber;
    }

    //class to hold error array.
	
		/*
     * @description: Wrapper class hold error array.
     */	
    public class NAVHDRTORET {
        public results[] results;
    }




}
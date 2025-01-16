/*
 * @Author: Kushagra Desai
 * @Date: 2018-11-07
 * @Description : Wrapper class to store RTP response to SAP.
 * @ Test class Coverage: 100% - TestApttusCheckPriceController.cls
 * @ Test class Coverage: 75% - TestApttusCheckPriceController.cls
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Rishi Sharma            21-Jul-2022                  DCP-54311 - Beadchip name to be pulled in full
 * Vinay S Reddy           23-Oct-2023                   CMCM 1482 Updates
 * ---------------------------------------------------------------------------------------------------------------------------------------
*/

public class RealtimePricingResponse {
    public String DocType = 'ZQT';
    public String EvSalesDocument;
    public String FileContent;
    public String Vbeln;
    public String SalesOrg;
    public String DistrChan;
    public String Division;
    public String QtValidT;
    public String QtValidF;
    public String PriceList;
    public String HCurr;
    public String PriceDate;  // Which format is needed
    public String PoMethod;
    public string ZzapQuot;
    public String Zzoppid;
    public String Incoterms1;
    public String ZzmyilmnEmail;
    public String Zstatus; // Check cross table
    public String UsageInd;
    public String Pmnttrms;
    public String OrdReason; // Check logic
    public String ZzpromoCode1;
    public String ZzpromoCode2;
    public String ZzpromoCode3;
    public String ZzpromoChannel1;
    public String ZzpromoChannel2;
    public String ZzpromoChannel3;
    public String ZdName;
    public String ZdTelephone;
    public String ZdEmail;
    public String Cstcndgrp2;
    public Items NAVHDRTOITM;
    public Exports NAVHDRTOEXP;
    public Conditions NAVHDRTOITEMCOND;
    public Partners NAVHDRTOPRT;
    public Returns NAVHDRTORET;
    public Logs NAVHDRTOGTSLOGS;
    public Fapiao NAVHDRTOFAPIAO; //added by saswati
    public Condition NAVHDRTOCND; //DCP-29847
    public Beadchip NAVHDRTOCFGSVAL; //DCP-30425
    public Reference NAVHDRTOCFGSREF; //DCP-30425
    public Instance NAVHDRTOCFGSINST; //DCP-30425
    public Line NAVHDRTOTXT; //DCP-34910
    public Beadchip NAVITMTOTXT; //DCP-54311
    public String TradeInIndicator; //added as part of cmcm1482
    
    /* 
     *  @description : Wrapper class for the list of LineItems
    */
    public class Items {
        public List<LineItems> results;
    }

    /* 
     *  @description : Wrapper class for LineItems
    */
    public class LineItems {
        public String ZzapPosnr;
        public String SapItmNumber;
        public String Material;
        public String TargetQty;
        public String Zzbundleid;
        public String Zzsoftwareid;
        public String ReasonRej;
        public String ContractStart;
        public String ContractEnd;
        public String BillFreq;
        public String ExtendedValue;
        public String SubtotPp4;
        public String SubtotPp4Pu;
        public String SubtotPp4Per;
        public string UnitPrice;
        public String ZzapPosnrHgLvl; //DCP-28284 -> Fixed Bundle - To send Bundle LineItem Number for Component Products
        public String TradeInIndicator; //added as part of CMCM 1482
    }

    /* 
     *  @description : Wrapper class for list of LineExports
    */
    public class Exports {
        public List<LineExports> results;
    }

    /* 
     *  @description : Wrapper class for LineExports
    */
    public class LineExports {
        public string ZOrderTotal;
        public string ZSubtotal;
        public string ZTotalDiscount;
        public string ZTotalFreight;
        public string ZTotalTax;
        public string IsQuoteSuccess;
        public string IsGtsSuccess;
        public string IsAttachSuccess;
    }

    /* 
     *  @description : Wrapper class for list of LineConditions
    */
    public class Conditions {
       public List<LineConditions> results;
    }

    /* 
     *  @description : Wrapper class for LineConditions
    */
    public class LineConditions {
        public string ZzapPosnr;
        public string ItmNumber;
        public string KonvKschl;
        public string KonhKnumaPi;
        public string KonvKbetr;
        public string KonvKrech;
        public string KonvKwert;
        public string Krate;
    }

    /* 
     *  @description : Wrapper class for list of LinePartners
    */
    public class Partners {
       public List<LinePartners> results;
    }

    /* 
     *  @description : Wrapper class for LinePartners
    */
    public class LinePartners {
        public string PartnRole;
        public string PartnNumb;
        public string name;
        public string Country;
        public string Telephone;
    }

    /* 
     *  @description : Wrapper class for list of LineReturns
    */
    public class Returns {
       public List<LineReturns> results;
    }

    /* 
     *  @description : Wrapper class for LineReturns
    */
    public class LineReturns {
        public string Type;
        public string Message;
    }

    /* 
     *  @description : Wrapper class for list of LineLogs
    */
    public class Logs {
       public List<LineLogs> results;
    }

    /* 
     *  @description : Wrapper class for LineLogs
    */
    public class LineLogs {
        public string ZzapPosnr;
        public string ItemNumber;
        public string CheckInd;
        public string ServicText;
        public string StatusText;
        public string ServStah;
        public string QualStah;
        public string ServStai;
        public string QualStai;
    }
    /*added by saswati
    for DCP-28565
    */
    /* 
     *  @description : Wrapper class for list of LineFapiao
    */
    public class Fapiao {
         public List<LineFapiao> results;
    }

    /* 
     *  @description : Wrapper class for LineFapiao
    */
    public class LineFapiao {
        public string FapiaoTypecode;
        public string FapiaoTypeDesc;
    } 

    // DCP-29847
    /* 
     *  @description : Wrapper class for list of LineCondition
    */
    public class Condition {
         public List<LineCondition> results;
    }
    
    /* 
     *  @description : Wrapper class for LineCondition
    */
    public class LineCondition {
        public String ZzapPosnr;
        public String CondType;
        public String CondValue;
        public String Calctypcon;
        public String ReasonForPriceOverride;
    }

    //DCP-34910
    /* 
     *  @description : Wrapper class for list of LineItem
    */
    public class Line {
        public List<LineItem> results;
    }

    /* 
     *  @description : Wrapper class for LineItem
    */
    public class LineItem{
        public String TextId;
        public String TextLine;
        public string Langu;
    }

    //DCP-30425 <-- Start
    /* 
     *  @description : Wrapper class for list of LineBeadchip
    */
    public class Beadchip {
        public List<LineBeadchip> results;
    }
    //DCP-54311 changes

    /* 
     *  @description : Wrapper class for LineBeadchip
    */
    public class LineBeadchip {
        public String ZzapPosnr;
        public String SapItmNumber;
        public String TextId;
        public String Langu;
        public String TextLine;
    }

    /* 
     *  @description : Wrapper class for list of LineRef
    */
    public class Reference {
        public List<LineRef> results;
    }

    /* 
     *  @description : Wrapper class for LineRef
    */
    public class LineRef {
        public String ZzapPosnr;
        public String ConfigId;
    }

    /* 
     *  @description : Wrapper class for list of LineInst
    */
    public class Instance {
        public List<LineInst> results;
    }

    /* 
     *  @description : Wrapper class for LineInst
    */
    public class LineInst {
        public String ConfigId;
        public String InstId;
    }
    //DCP-30425 End -->

}
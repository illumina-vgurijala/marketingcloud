/*
Main response wrapper for COGS data
*/
public class COGS_ResponseWrapper {
    public cls_d d;

    /*
    Data structure containing metadata and various attributes related to sales documents
    */
    public class cls_d {
        public cls_metadata metadata;
        public String vbeln;        // 4613783
        public String docType;      // 
        public String salesOrg;     // 
        public String distrChan;    // 
        public String division;     // 
        public String qtValidT;     // 
        public String qtValidF;     // 
        public String zzsvmxOrderType; // 
        public String priceList;    // 
        public String hCurr;        // 
        public String priceDate;    // 
        public String poMethod;     // 
        public String zzapQuot;     // 
        public String zzoppid;      // 
        public String incoterms1;   // 
        public String incoterms2;   // 
        public String zzmyilmnEmail; // 
        public String zstatus;      // 
        public String pmnttrms;     // 
        public String ordReason;    // 
        public String usageInd;     // 
        public String zzpromoCode1; // 
        public String zzpromoCode2; // 
        public String zzpromoCode3; // 
        public String zzpromoChannel1; // 
        public String zzpromoChannel2; // 
        public String zzpromoChannel3; // 
        public String cstcndgrp2;   // 
        public String custGrp2;     // 
        public String refDocL;      // 
        public String zdName;       // 
        public String zdTelephone;  // 
        public String zdEmail;      // 
        public String pguidPurch;   // 
        public String fileContent;  // 
        public String evSalesDocument; // 
        public String costCenter;   // 
        public cls_NAVHDRTOCND navhdrtocnd;
        public cls_NAVHDRTOITM navhdrtoitm;
        public cls_NAVHDRTOPRT navhdrtoprt;
        public cls_NAVHDRTORET navhdrtoret;
        public cls_NAVHDRTOTXT navhdrtotxt;
        public cls_NAVHDRTOINP navhdrtoinp;
        public cls_NAVHDRTOCFGSBLOB navhdrtocfgsblob;
        public cls_NAVHDRTOCFGSINST navhdrtocfgsinst;
        public cls_NAVHDRTOCFGSPARTOF navhdrtocfgspartof;
        public cls_NAVHDRTOCFGSREF navhdrtocfgsref;
        public cls_NAVHDRTOCFGSREFINST navhdrtocfgsrefinst;
        public cls_NAVHDRTOCFGSVAL navhdrtocfgsval;
        public cls_NAVHDRTOCFGSVK navhdrtocfgsvk;
        public cls_NAVHDRTOKEYS navhdrtokeys;
        public cls_NAVHDRTOLOGSWT navhdrtologswt;
        public cls_NAVHDRTOSENDER navhdrtosender;
        public cls_NAVHDRTOPARADD navhdrtoparadd;
        public cls_NAVHDRTOPARCNG navhdrtoparcng;
        public cls_NAVHDRTOGTSLOGS navhdrtogtslogs;
        public cls_NAVHDRTOITEMCOND navhdrtoitemcond;
        public cls_NAVHDRTOEXP navhdrtoexp;
        public cls_NAVHDRTOFAPIAO navhdrtofapiao;
        public cls_NAVITMTOTXT navitmtotxt;
    }

    /*
    Metadata information for the response
    */
    public class cls_metadata {
        public String id;
        public String uri;
        public String type;    // ZQ2C_INT_QUOTE_CONV_SRV.SALES_ITEM_COND
    }

    /*
    Header for conditions in the navigation structure
    */
    public class cls_NAVHDRTOCND {
        public cls_deferred deferred;
    }

    /*
    Represents a deferred resource for linking
    */
    public class cls_deferred {
        public String uri;     // http://URL
    }

    /*
    Header for items in the navigation structure
    */
    public class cls_NAVHDRTOITM {
        public cls_deferred deferred;
    }

    /*
    Header for partners in the navigation structure
    */
    public class cls_NAVHDRTOPRT {
        public cls_deferred deferred;
    }

    /*
    Header for returns containing results
    */
    public class cls_NAVHDRTORET {
        public cls_results[] results;
    }

    /*
    Result item with associated metadata and attributes
    */
    public class cls_results {
        public cls_metadata metadata;
        public String itmNumber;   // 000050
        public String zzapPosnr;   // LI-0001384221
        public String konvKschl;   // VPRS
        public String konhKnumaPi; // 
        public String konvKoaid;   // 
        public String konvKbetr;   // 1,049.89
        public String konvKrech;   // C
        public String konvKwert;   // 6,562.55
        public String krate;       // 1,312.51
        public String message;     // 1,312.51
        public String type;        // 1,312.51
    }

    /*
    Header for text items in the navigation structure
    */
    public class cls_NAVHDRTOTXT {
        public cls_deferred deferred;
    }

    /*
    Header for inputs in the navigation structure
    */
    public class cls_NAVHDRTOINP {
        public cls_deferred deferred;
    }

    /*
    Header for configuration blobs in the navigation structure
    */
    public class cls_NAVHDRTOCFGSBLOB {
        public cls_deferred deferred;
    }

    /*
    Header for configuration instances in the navigation structure
    */
    public class cls_NAVHDRTOCFGSINST {
        public cls_deferred deferred;
    }

    /*
    Header for configurations that are part of another
    */
    public class cls_NAVHDRTOCFGSPARTOF {
        public cls_deferred deferred;
    }

    /*
    Header for configuration references in the navigation structure
    */
    public class cls_NAVHDRTOCFGSREF {
        public cls_deferred deferred;
    }

    /*
    Header for configuration reference instances in the navigation structure
    */
    public class cls_NAVHDRTOCFGSREFINST {
        public cls_deferred deferred;
    }

    /*
    Header for configuration values in the navigation structure
    */
    public class cls_NAVHDRTOCFGSVAL {
        public cls_deferred deferred;
    }

    /*
    Header for configuration SVK in the navigation structure
    */
    public class cls_NAVHDRTOCFGSVK {
        public cls_deferred deferred;
    }

    /*
    Header for keys in the navigation structure
    */
    public class cls_NAVHDRTOKEYS {
        public cls_deferred deferred;
    }

    /*
    Header for log switch in the navigation structure
    */
    public class cls_NAVHDRTOLOGSWT {
        public cls_deferred deferred;
    }

    /*
    Header for sender information in the navigation structure
    */
    public class cls_NAVHDRTOSENDER {
        public cls_deferred deferred;
    }

    /*
    Header for partner addresses in the navigation structure
    */
    public class cls_NAVHDRTOPARADD {
        public cls_deferred deferred;
    }

    /*
    Header for partner changes in the navigation structure
    */
    public class cls_NAVHDRTOPARCNG {
        public cls_deferred deferred;
    }

    /*
    Header for GTS logs in the navigation structure
    */
    public class cls_NAVHDRTOGTSLOGS {
        public cls_deferred deferred;
    }

    /*
    Header for item conditions containing results
    */
    public class cls_NAVHDRTOITEMCOND {
        public cls_results[] results;
    }

    /*
    Header for export information in the navigation structure
    */
    public class cls_NAVHDRTOEXP {
        public cls_deferred deferred;
    }

    /*
    Header for API A/O in the navigation structure
    */
    public class cls_NAVHDRTOFAPIAO {
        public cls_deferred deferred;
    }

    /*
    Header for item texts in the navigation structure
    */
    public class cls_NAVITMTOTXT {
        public cls_deferred deferred;
    }

    /*
    Parse JSON string into a COGS_ResponseWrapper object
    */
    public static COGS_ResponseWrapper parse(String json) {
        return (COGS_ResponseWrapper) System.JSON.deserialize(json, COGS_ResponseWrapper.class);
    }
}
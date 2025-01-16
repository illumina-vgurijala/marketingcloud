/*
* @author : Sravan Panchangam
* @description :DCP-9865 ASOP Integration
* @Date: 2018/09/27
* Modification Log:
*       ------------------------------------------------------------------------------------
*        Developer             Date                 Description
*        Sravan Panchangam      2018/09/27          Initial Version
*        Aman Tyagi             2022-03-31          CodeScan Fixes
*       ------------------------------------------------------------------------------------
*/
public class ApttusOrdersAttachmentWrapper {

    /*
    * @Author: Sravan Panchangam
    * @Description : request class
    */
    public Class RequestBodyJson{
        Public String Sales_Order_Number_Unique;
        public List<RelatedAttachments> relatedAttachments;
        /*
        * @Author: Sravan Panchangam
        * @Description : this method has logic for getting related attachments
        * @return: List<RelatedAttachments>
        * @param :null
        */
		public List<RelatedAttachments> getRelatedAttachments(){
            return this.relatedAttachments;
        }
    }

    /*
    * @Author: Sravan Panchangam
    * @Description : class for storing related attachments
    */ 
    public Class RelatedAttachments{
        public String AttachmentVersionData;
        public String AttachmentFileName;
        //public String fileType;
    }
    
}
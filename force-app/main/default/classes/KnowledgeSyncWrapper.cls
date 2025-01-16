/**
 *    @author KD
 *    @date   8-Dec-2020
 *    @description Knowledge Sync wrapper
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *             Sarath Pullanikkatt            17-Apr-2021         Added Document Number Column
 *    ---------------------------------------------------------------------------------------------------------------------
 *
 */
public with sharing class KnowledgeSyncWrapper {
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   Wrapper to store FileContent
     */
    public class FileContent{
        public String id;
        public String type;
        public String description;
        public String name;
        public string format;
        public List<ProfileAssignment> assignedToProfiles;
        public List<ContentProperties> properties;
    }
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   Wrapper to store ProfileAssignment
     */
    public class ProfileAssignment{
        public String name;
        public String type;
    }
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   Wrapper to store ContentProperties
     */
    public class ContentProperties{
        public String name;
        public List<String> values;
    }
    /**
     * @author Adyasha
     * @date    4-Jan-2021
     * @description   Wrapper to store ContentDetails
     */
    public class ContentDetails{
        public String id;
        public String contentProfileId;
        public String libraryContentId;
        public String libraryContentVersionId;
    }
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   Wrapper to store Library Content Details
     */
    public class LibraryContentDetails{
        public String strLibraryContentId;
        public String strDocumentNumber;
        public String strContentName;
        public String strType;
        public String strFormat;
        public Boolean boolIsDeleted;
        public Boolean boolIsPublished;
        public String strLibraryContentURL;
        public String strTeamSiteId;
        public String strProfileId;
        public DateTime dtCreatedDate;
        public DateTime dtCModifiedDate;
        public String strContentProfileName;
        /**
        * @author KD
        * @date    8-Dec-2020
        * @description   Constructor 
        */
        public LibraryContentDetails(String strLibraryContentDetails){
            List<String> lstLibraryContentDetail = strLibraryContentDetails.split(',');
            this.strLibraryContentId = lstLibraryContentDetail[0];
            this.strDocumentNumber = lstLibraryContentDetail[1];
            this.strContentName = lstLibraryContentDetail[2];
            this.strFormat = lstLibraryContentDetail[6];
            this.strType = lstLibraryContentDetail[5];
            this.boolIsDeleted = Boolean.valueOf(lstLibraryContentDetail[7]);
            this.boolIsPublished = Boolean.valueOf(lstLibraryContentDetail[8]);
            this.strLibraryContentURL = lstLibraryContentDetail[10];
            this.strTeamSiteId = lstLibraryContentDetail[13];
            if(lstLibraryContentDetail.size() == 16)
                this.strContentProfileName = String.isBlank(lstLibraryContentDetail[15]) ? 'N/A' : lstLibraryContentDetail[15];
            else
                this.strContentProfileName = 'N/A';
        }
    }
}
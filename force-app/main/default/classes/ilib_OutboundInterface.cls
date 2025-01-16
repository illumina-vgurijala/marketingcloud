/*@ author       : Akshay Mohan
* @ date         : 07-20-2018
* @ Description  : Interface to be implemented for making putbound calls
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan        	07-20-2018                 US-358            Initial version
* Gerardo Garcia        06-24-2024                 CMCM-8480 add method setExtraInformation
*/
public interface ilib_OutboundInterface {
    Boolean callout(Id recordId);
    void setExtraInformation(String extraInformation);
}
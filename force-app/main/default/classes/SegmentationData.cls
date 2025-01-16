/**
*    @author: Pankaj 
*    @date:   26-Nov-2019
*    @description:  segmentationData- Wrapper class to hold the segment ID and priority. This is used to implement
                    sorting of custom data type
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 26 Nov 2019        Initial Development
                  
*    ------------------------------------------------------------------------------------ 
*                    
*/

global  class SegmentationData implements Comparable {

    public Integer intPriority;
    public String strSegmentIdFinal;
    
    /*
    * @author Pankaj Singla
    * @date   26-Nov-2019 
    * @description: This method is used to compare 2 objects of SegmentationData type
    * params :compareTo- The object to compare to
    *return An Integer value that is the result of the comparison.
    */
    global Integer compareTo(Object compareTo){
        SegmentationData compareToEmp = (SegmentationData)compareTo;
        if (intPriority == compareToEmp.intPriority) return 0;
        if (intPriority > compareToEmp.intPriority) return 1;
        return -1;  
    }
}
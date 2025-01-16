/**
* @author Shivani Jain
* @date 6th April 2022
*
* @description DCP-49914 Optimze We Chat for Comment and Case	
*/
public with sharing class StripHTMLTagsHelper {
    
    static final String LOG_TITLE = 'StripHTMLTagsHelper';

    /*******************************************************************************************************
    * @description Strip html tags from rich text
    * @param richTextWrapper List<StringWrapper>
    * @return List<StringWrapper>
    */
    @InvocableMethod(label='Strip HTML Tags' 
        description='Strip HTML Tags' category='Rich Text to Plain Text')
    public static List<StringWrapper> stripHTMLTags(List<StringWrapper> richTextWrapper) {
        List<StringWrapper> result = new List<StringWrapper>();
        String plainText = '';
        
        try {
            if(richTextWrapper != NULL && !richTextWrapper.isEmpty()) {
                String richText = richTextWrapper[0].textVar;
                plainText = preserveLineBreaksAndStrip(richText);
            } else {
                plainText = '';
            }
            result.add(new StringWrapper(plainText));
        } catch(Exception ex) {
            ApexExceptions.emit(LOG_TITLE, ex); 
        }
        return result;

    }

    /*******************************************************************************************************
    * @description Strip html tags from rich text while preserving line breaks
    * @param textValue Rich Text value
    * @return String
    */
    private static String preserveLineBreaksAndStrip(String textValue) {
        String lineBreakTag = '<br>';
        String lineBreakTagReplacement = '~linebreak~';
        String lineBreakWithpTag = '<p>&nbsp;</p>';
        String textValProcess = textValue;

        textValProcess = textValProcess.replaceAll(lineBreakTag, lineBreakTagReplacement);
        textValProcess = textValProcess.stripHtmlTags();
        textValProcess = textValProcess.replaceAll(lineBreakTagReplacement, lineBreakWithpTag);
        return textValProcess;
    }

    /*******************************************************************************************************
    * @description Wrapper for Flow variable
    */
    public class StringWrapper {
        @InvocableVariable
        public String textVar;

        /***************************************************************************************************
        * @description Constructor
        */
        public StringWrapper(String textVar){
            this.textVar = textVar;
        }

        /***************************************************************************************************
        * @description Constructor
        */
        public StringWrapper() { }
    }
}
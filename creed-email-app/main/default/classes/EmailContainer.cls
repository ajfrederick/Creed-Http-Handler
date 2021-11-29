/**
 * @name EmailContainer
 * @description wrapper class to get email content and info predictably no matter the source.
 * These get loaded up and passed around and unloaded by the entire application.
**/
public class EmailContainer {

/**
 * FIELDS
**/

    // email to addresses
    public String[] ToAddresses {
        get {
            if( ToAddresses == null ) ToAddresses = new String[]{};
            return ToAddresses;
        }
        set;
    }

    // email cc addresses
    public String[] CcAddresses {
        get {
            if( CcAddresses == null ) CcAddresses = new String[]{};
            return CcAddresses;
        }
        set;
    }

    // email Bcc addresses
    public String[] BccAddresses {
        get {
            if( BccAddresses == null ) BccAddresses = new String[]{};
            return BccAddresses;
        }
        set;
    }

    // all addresses
    public String[] allAddresses {
        get {
            allAddresses = new String[]{};

            allAddresses.addAll( ToAddresses );
            allAddresses.addAll( CcAddresses );
            allAddresses.addAll( BccAddresses );

            return allAddresses;
        }
        set;
    }

    // email from address
    public String FromAddress {get;set;}

    // email from name
    public String FromName {get;set;}

    // email template
    public EmailTemplate template {get;set;}

    // email content
    private EmailContent content {get;set;}

    // optional record Id to be used for whatId
    public Id whatId {get;set;}

    // optional contact, user or lead Id to be used for whoId
    public Id whoId {get;set;}

    // external unique identifier given by email clients and salesforce email client
    public String messageId  {get;set;}

    // external unique identifier given by email clients and salesforce email client
    public String inReplyTo {get;set;}

    // attachment data to be used to created ContentVersions (files) if need be
    public AttachmentData[] attachments {
        get {
            if( attachments == null ) attachments = new AttachmentData[]{};
            return attachments;
        }
        set;
    }

    // Ids of ContentVersion (file) records that will be used to send attachments
    public String[] versionIds {
        get {
            if( versionIds == null ) versionIds = new String[]{};
            return versionIds;
        }
        set;
    }

/**
 * CONSTRUCTOR
**/

    public EmailContainer(){

    }

/**
 * ACTION METHODS
**/

    /**
     * @name setContent
     * @description sets email subject and content for an outgoing or incoming email given a subject, HtmlBody, and PlaintextBody
     * all formatted as Strings on a new EmailContent object.
     * @param String Subject
     * @param String HtmlBody
     * @param String PlainTextBody
     * @return void
    **/
    public void setContent( String Subject, String HtmlBody, String PlainTextBody ){

        HtmlBody = checkBodyLength( HtmlBody );
        PlainTextBody = checkBodyLength( PlainTextBody );

        EmailContent cont = new EmailContent();
        cont.Subject = Subject;
        cont.HtmlBody = wrapHTMLBody(HtmlBody);
        cont.PlainTextBody = PlainTextBody;

        content = cont;
    }

    /**
     * @name getContent
     * @description get email contact
     * @return void
    **/
    public EmailContent getContent(){
        return content;
    }

    /**
     * @name getSubject
     * @description gets the email contents subject
     * @return String
    **/
    public String getSubject(){
        if( content == null ) return null;

        return content.Subject;
    }

    /**
     * @name getHTMLBody
     * @description gets the email contents HTML Body
     * @return String
    **/
    public String getHTMLBody(){
        if( content == null ) return null;
        
        return content.HtmlBody;
    }

    /**
     * @name getPlainTextBody
     * @description gets the email contents Plain Text Body
     * @return String
    **/
    public String getPlainTextBody(){
        if( content == null ) return null;

        return content.PlainTextBody;
    }

    /**
     * @name setSubject
     * @description sets the email contents subject
     * @param String Subject
     * @return void
    **/
    public void setSubject( String Subject ){
        if( content == null ) content = new EmailContent();

        content.Subject = Subject;
    }

    /**
     * @name setHTMLBody
     * @description sets the email contents HTML Body
     * @param String HtmlBody
     * @return void
    **/
    public void setHTMLBody( String HtmlBody ){
        if( content == null ) content = new EmailContent();

        content.HtmlBody = checkBodyLength( HtmlBody );
    }

    /**
     * @name setPlainTextBody
     * @description sets the email contents Plain text Body
     * @param String PlainTextBody
     * @return void
    **/
    public void setPlainTextBody( String PlainTextBody ){
        if( content == null ) content = new EmailContent();

        content.PlainTextBody = checkBodyLength( PlainTextBody );
    }

    /**
     * @name setAttachment
     * @description adds AttachementData when an outgoing or 
     * incoming email contains a binary attachment which is formatted
     * as Blob data
     * @param String filename
     * @param Blob body
     * @return void
    **/
    public void setAttachment( String filename, Blob body ){
        attachments.add( new AttachmentData( filename, body ) );
    }

    /**
     * @name setAttachment
     * @description adds AttachementData when an outgoing or 
     * incoming email contains a text attachment which is formatted as a String
     * @param String filename
     * @param String (base64) body
     * @return void
    **/
    public void setAttachment( String filename, String body ){
        Blob bodyBlob = EncodingUtil.base64Decode(body);

        attachments.add( new AttachmentData( filename, bodyBlob ) );
    }

    /**
     * @name addVersionId
     * @description adds a ContentVersion Id after a file is inserted to the database or is already in the database
     * @param String versionId
     * @return void
    **/
    public void addVersionId( String versionId ){
        versionIds.add(versionId);
    }

    /**
     * @name addVersionId
     * @description sets all ContentVersion Ids
     * @param String ids
     * @return void
    **/
    public void setVersionIds( String[] ids ){
        versionIds = ids;
    }

    /**
     * @name getVersionIds
     * @description gets actual file ids for message attachments
     * @param none
     * @return String[] versionIds
    **/
    public String[] getVersionIds(){
        return versionIds;
    }

    /**
     * @name setQuote
     * @description wraps message history in quote div for a new outgoing message
     * @param String quote
     * @return void
    **/
    public void setQuote( String quote ){
        if( content == null ){
            System.debug('Content for EmailContainer.cls must be set before set the quoted email in the body');
            return;
        }

        content.HtmlBody += '<br/>' + wrapQuotedHTMLBody(quote);
    }

/**
 * UTILITY METHODS
**/

    /**
     * @name hasToAddresses
     * @description checks to see if ToAddresses of type String[] is empty or not
     * @return Boolean
     */
    public Boolean hasToAddresses(){
        return !ToAddresses.isEmpty();
    }

    /**
     * @name hasTemplate
     * @description checks to see if template of type EmailTemplate is null or not
     * @return Boolean
     */
    public Boolean hasTemplate(){
        return template != null;
    }

    /**
     * @name hasContent
     * @description checks to see if content of type EmailContent is null or not
     * @return Boolean
     */
    public Boolean hasContent(){
        return content != null;
    }

    /**
     * @name hasWhatId
     * @description checks to see if whatId of type Id is null or not
     * @return Boolean
     */
    public Boolean hasWhatId(){
        return whatId != null;
    }

    /**
     * @name hasWhoId
     * @description checks to see if whoId of type Id is null or not
     * @return Boolean
     */
    public Boolean hasWhoId(){
        return whoId != null;
    }

    /**
     * @name hasMessageId
     * @description checks to see if messageId of type String is blank or not
     * @return Boolean
     */
    public Boolean hasMessageId(){
        return !String.isBlank( messageId );
    }

    /**
     * @name hasInReplyTo
     * @description checks to see if inReplyTo of type String is empty or not
     * @return Boolean
     */
    public Boolean hasInReplyTo(){
        return !String.isBlank( inReplyTo );
    }

    /**
     * @name wrapHTMLBody
     * @description takes HTMLBody and wraps it in a div with class of creed-message
     * @param String HtmlBody
     * @return String
     */
    public String wrapHTMLBody( String HtmlBody ){
        return '<div class="creed-message">' + HtmlBody +'</div>';
    }

    /**
     * @name wrapQuotedHTMLBody
     * @description takes a String and wraps it in a div with class of creed-message-quote
     * @param String quote
     * @return String
     */
    private String wrapQuotedHTMLBody( String quote ){
        return '<div class="creed-message-quote">' + quote +'</div>';
    }

    /**
     * @name checkBodyLength
     * @description there is a character limit of 4000 for EmailMessage body. Unfortunately we'll have to truncate extra long email bodies
     * @param String body
     * @return String
     */
    private String checkBodyLength( String body ){
        if( body.length() > 30000 ) body = body.substring( 0, 29999 ) + '... (original message truncated due to size)';

        return body;
    }


/**
 * CLASSES
**/

    public class EmailContent {
        public String Subject {get;set;}
        public String HtmlBody {get;set;}
        public String PlainTextBody {get;set;}
    }

    public class AttachmentData {

        public String filename {get;set;}
        public String extension {get;set;}
        public Blob body {get;set;}
        public String contentType {get;set;}

        public AttachmentData( String fn, Blob b ){
            filename = fn;
            body = b;

            setContentType( filename );
        }

        private void setContentType( String filename ){
            Map<String, String> contentTypes = Utils.contentTypes;

            extension = filename.substringAfterLast('.');

            contentType = '';

            if( !String.isBlank(extension) && contentTypes.containsKey(extension) ){
               contentType = contentTypes.get(extension);
            }
        }
    }
}
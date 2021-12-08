/**
 * @name OLSRestServiceHelper
 * @description this class helps parse the JSON that is delivered to the apex rest service class OnlineStoreCustomerRestService.cls
 * as well as deliver contact that is loaded with all the values from the parsed JSON.
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public without sharing class OLSRestServiceHelper {

/**
 * FIELDS
 */

    public String requestBody;
    public ClientSideCustomer customer;

/**
* CONSTRUCTOR
*/

    public OLSRestServiceHelper( String b ) {
        requestBody = b;
    }

/**
* ACTION METHODS
*/  
    /**
     * @name parseRequest
     * @description parses the JSON sent in the request to the OnlineStoreCustomerRestService.cls
     * @param ClientSideCustomer customer
     * @return Contact
     */
    public void parseRequest(){
        customer = (ClientSideCustomer) JSON.deserialize( requestBody, ClientSideCustomer.class );
    }

    /**
     * @name getNewContact
     * @description gets Instance of contact (Online Store Customer) for insert
     * @param ClientSideCustomer customer
     * @return Contact
     */
    public Contact getNewContact(){
        if( customer == null ) return null;

        Boolean paymentSuccessful = customer.paymentDetails.paymentSuccessful == 'true' ? true : customer.paymentDetails.paymentSuccessful == 'false' ? false : null;
        
        String amount = customer.amount.replace('$','');

        Decimal initalPaymentAmount = isDecimal(amount) ? Decimal.valueOf(amount) : null;

        Contact newContact = new Contact(
            FirstName = customer.firstName,
            LastName = customer.lastName,
            Email = customer.email,
            Phone = customer.phone,
            MailingCity = customer.address.city,
            MailingState = customer.address.state,
            MailingPostalCode = customer.address.zip,
            Initial_Payment_Amount__c = initalPaymentAmount,
            Product_Purchased__c = customer.product,
            Brochure_Key__c = customer.brochureKey,
            Brochure_URL__c = customer.brochureUrl,
            CAID__c = customer.preEnrollment.caid,
            State_Acronym__c = customer.preEnrollment.stateAcronym,
            Customer_Id__c = customer.paymentDetails.customerId,
            Payment_Successful__c = paymentSuccessful,
            Payment_Type__c = customer.paymentDetails.paymentType,
            Payment_Frequency__c = customer.paymentDetails.paymentFrequency
        );

        if( !String.isBlank(customer.address.addressLine2) ){
            newContact.MailingStreet = customer.address.addressLine1 + ' ' + customer.address.addressLine2;
        } else {
            newContact.MailingStreet = customer.address.addressLine1;
        }

        Id olsRecordTypeId = OLSTriggerHelper.getRecordTypeId('Online_Store_Customer');

        if( olsRecordTypeId != null ){
            newContact.RecordTypeId = olsRecordTypeId;
        }

        return newContact;
    }

    /**
     * @name isDecimal
     * @description this is to avoid errors if the amount from the JSON is malformed
     * @param String amount
     * @return Decimal
     */
    private Boolean isDecimal( String amount ){
        String isDecimalRegEx = '^[+-]?([0-9]+\\.?[0-9]*|\\.[0-9]+)$';

        Pattern decimalPattern = Pattern.compile( isDecimalRegEx );

        Matcher decimalMatcher = decimalPattern.matcher( amount );

        return decimalMatcher.matches();
    }

/**
* CLASSES
*/
    // this is the exact format we are expecting for a customer object from the DDMN WebApps Online Store
    
    public class ClientSideCustomer {
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String email {get;set;}
        public AddressData address {get;set;}
        public String phone {get;set;}
        public String accessCode {get;set;}
        public String amount {get;set;}
        public String product {get;set;}
        public String brochureKey {get;set;}
        public String brochureUrl {get;set;}
        public PreEnrollment preEnrollment {get;set;}
        public String postBackUrl {get;set;}
        public PaymentDetails paymentDetails {get;set;}
        public Enrollment enrollment {get;set;}
    }

    public class AddressData {
        public String addressLine1 {get;set;}
        public String addressLine2 {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String zip {get;set;}
    }

    public class PaymentDetails {
        public String paymentSuccessful {get;set;}
        public String paymentType {get;set;}
        public String customerId {get;set;}
        public String transactionId {get;set;}
        public String transactionDate {get;set;}
        public String paymentAuthNumber {get;set;}
        public String bankAccountType {get;set;}
        public String paymentFrequency {get;set;}
        public String callingApplication {get;set;}
        public String paymentErrorMessage {get;set;}
    }

    public class PreEnrollment {
        public String status {get;set;}
        public String stateAcronym {get;set;}
        public String preEnrollmentId {get;set;}
        public String caid {get;set;}
    }

    public class Enrollment {
        public String status {get;set;}
        public String enrollmentId {get;set;}
    }
}
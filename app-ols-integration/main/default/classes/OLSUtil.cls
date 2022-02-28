/**
 * @name OLSUtil
 * @description helper for OnlineStoreCustomerTrigger.trigger and throughout the application
 * 
 * @author Creed Interactive (Andrew Frederick) October 2021
 */
public class OLSUtil {

/**
 * FIELDS
 */

    private static final String fromAddress = System.Label.OLS_Email_From_Address;

    private static final String fromAddressNE = System.Label.OLS_Email_From_Address_NE;

    // A list of record type developer/api names that we will use to get the recordType Ids to use below
    private static final String[] RecordTypeNames = new String[]{
        'Online_Store_Customer'
    };
    
    private static Map<String, Id> RecordTypeIdsByName = new Map<String, Id>();

    /**
     * This static block is to ensure there are no problems constructing the class when accessing the Schema describe and the 
     * getRecordTypeInfosByDeveloperName. If the record type was deleted or the name was changed then you will
     * incur an 'attempt to de-referece a null object error'.
     */
    static {
        DescribeSobjectResult describe = Contact.SObjectType.getDescribe();
        
        Map<String, Schema.RecordTypeInfo> recordTypes = describe.getRecordTypeInfosByDeveloperName();

        for( String name : RecordTypeNames ){

            if( recordTypes.containsKey( name ) ){
                RecordTypeIdsByName.put( name, recordTypes.get( name ).getRecordTypeId() );
            } else {
                RecordTypeIdsByName.put( name, null ); // this will only happen if the record type was deleted or the name was changed for the list above
            }
        }
    }
    
/**
 * TRIGGER METHODS
 */

    /**
     * @name afterInsert
     * @description gets called in trigger after insert
     * @param Contact[] customers
     * @return none
     */
    public static void afterInsert( Contact[] newList ){
        Contact[] customers = sortOnlineStoreCustomers( newList );

        sendEmails( customers );
    }

    /**
     * @name afterUpdate
     * @description gets called in trigger after update
     * @param Contact[] customers
     * @return none
     */
    public static void afterUpdate( Contact[] newList ){
        Contact[] customers = sortOnlineStoreCustomers( newList );

        sendEmails( customers );
    }

/**
 * ACTION METHODS
 */

    /**
     * @name sendEmails
     * @description gets called in trigger after insert handler
     * @param Contact[] customers
     * @return none
     */
    private static void sendEmails( Contact[] customers ){
        if( customers.isEmpty() ) return;
        
        Contact[] customersNotNE = new Contact[]{};
        Contact[] customersNE = new Contact[]{};

        for( Contact customer : customers ){

            if( customer.State_Acronym__c == 'ddne_core' ){
                customersNE.add(customer);
            } else {
                customersNotNE.add(customer);
            }
        }

        sendEmailsNotNE( customersNotNE );
        sendEmailsNE( customersNE );

        scheduleJob();
    }

    /**
     * @name sendEmailsNotNE
     * @description sends emails to customers from MN and ND
     * @param Contact[] customers
     * @return none
     */
    private static void sendEmailsNotNE( Contact[] customers ){
        if( customers.isEmpty() ) return;

        EmailParcelFactoryOLS parcelFactory = new EmailParcelFactoryOLS( customers );
        parcelFactory.setTemplate( 'Online_Store_Customer_Welcome' );
        parcelFactory.setOrgWideEmailAddressId( fromAddress );

        sendFinal( parcelFactory, customers );
    }

    /**
     * @name sendEmailsNE
     * @description sends emails to customers from NE. The distinction was made to avoid confusion for NE people
     * since there is a Delta Dental NE "branch" organization.
     * @param Contact[] customers
     * @return none
     */
    private static void sendEmailsNE( Contact[] customers ){
        if( customers.isEmpty() ) return;

        EmailParcelFactoryOLS parcelFactory = new EmailParcelFactoryOLS( customers );
        parcelFactory.setTemplate( 'Online_Store_Customer_Welcome_NE' ); // Template is NE specific
        parcelFactory.setOrgWideEmailAddressId( fromAddressNE ); // And From Address is NE specific

        sendFinal( parcelFactory, customers );
    }

    /**
     * @name sendFinal
     * @description sends emails to customers from NE. The distinction was made to avoid confusion for NE people
     * since there is a Delta Dental NE "branch" organization.
     * @param Contact[] customers
     * @return none
     */
    private static void sendFinal( EmailParcelFactory parcelFactory, Contact[] customers ){
        ContentVersion[] versions = getContentVersions(customers);

        parcelFactory.addVersionIdsByName( versions );
        parcelFactory.build();

        EmailFactoryOutbound emailFactory = new EmailFactoryOutbound( parcelFactory );
        emailFactory.build();

        EmailPost emailPost = new EmailPost( emailFactory );
        emailPost.addTriggerHook( new OLSTriggerHook() );
        emailPost.post();
    }

/**
 * UTILITY METHODS
 */

    /**
     * @name sendEmails
     * @description gets Brochure PDFs for email's attachment
     * @param Contact[] customers
     * @return none
     */
    private static ContentVersion[] getContentVersions( Contact[] customers ){
        ContentVersion[] versions = new ContentVersion[]{};

        String[] brochureKeys = new String[]{};

        for( Contact customer : customers ){

            if( !String.isBlank( customer.Brochure_Key__c ) ){
                brochureKeys.add( customer.Brochure_Key__c );
            }
        }

        try {

            if( brochureKeys.isEmpty() ){
                throw new BrochureKeyException('No brochure keys associated with these customer records.');
            }

            versions.addAll([SELECT
                Id,
                Title,
                VersionData,
                Brochure_Key__c
                    FROM ContentVersion
                    WHERE Brochure_Key__c IN :brochureKeys]);

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e, customers);
            handler.handle();
        }

        return versions;
    }

    /**
     * @name sortOnlineStoreCustomers
     * @description sorts out Contacts that are Online Store Customers that have been delivered emails.
     * @param String name
     * @return Id
     */
    private static Contact[] sortOnlineStoreCustomers( Contact[] newList ){
        Contact[] customers = new Contact[]{};

        for( Contact customer : newList ){
            if( isNewSuccessfulOnlineStoreCustomer( customer ) ){
                customers.add( customer );
            }
        }

        return customers;
    }

    /**
     * @name scheduleJob
     * @description schedules the job to email bounce reports to selected individuals if there isn't one already.
     * @param none
     * @return none
     */
    private static void scheduleJob(){
        AsyncApexJob job;

        try {

            job = [SELECT
                    Id
                        FROM AsyncApexJob
                        WHERE ApexClass.Name = 'OLSBounceReportJob'
                        AND JobType = 'ScheduledApex'
                        AND 
                        ( 
                            Status != 'Aborted'
                            OR Status != 'Completed'
                            OR Status != 'Failed'
                        )
                        LIMIT 1];

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.debug();
        }

        if( job != null ) return;

        String jobName = 'OLS Bounce Report Email';

        // job for every Monday at 6am
        String everyWeek = '0 0 6 ? * MON';

        // FOR TESTING: job for every Day at 6am
        String everyDay = '0 0 6 * * ?';

        // FOR TESTING: job for 3 minutes from now
        String threeMinutesFromNow = getThreeMinutesFromNow();

        OLSBounceReportJob schedulable = new OLSBounceReportJob();

        System.schedule(jobName, everyWeek, schedulable);
    }

    /**
     * @name getRecordTypeId
     * @description get RecordTypeId by name
     * @param String name
     * @return Id
     */
    public static Id getRecordTypeId( String name ){
        Id recordTypeId;
        
        try {

            recordTypeId = RecordTypeIdsByName.get( name );

            if( recordTypeId == null ){
                throw new RecordTypeException('Record Type ' + name + ' for Contacts does not exist. Or the developer is searching for this record type on the wrong Object.');
            }

        } catch( Exception e ){
            CreedExceptionHandler handler = new CreedExceptionHandler(e);
            handler.handle();
        }

        return recordTypeId;
    }

    /**
     * @name isNewSuccessfulOnlineStoreCustomer
     * @description this checks to make sure a contact record is indeed an Online Store Customer.
     * 1) is an online store customer contact record
     * 2) and an email hasn't been sent yet.
     * 3) and that the payment has been successful
     * @param Contact customer 
     * @return Boolean
     */
    public static Boolean isNewSuccessfulOnlineStoreCustomer( Contact customer ){
        return isOnlineStoreCustomer( customer ) && (!customer.Email_Sent__c) && customer.Payment_Successful__c;
    }

    /**
     * @name isOnlineStoreCustomer
     * @description this checks to make sure a contact record is indeed an Online Store Customer.
     * 1) First we want to make sure the RecordType exists
     * 2) we want to make sure that the Contact record has a the Online_Store_Customer RecordTypeId
     * @param Contact customer 
     * @return Boolean
     */
    public static Boolean isOnlineStoreCustomer( Contact customer ){
        return getRecordTypeId('Online_Store_Customer') != null && customer.RecordTypeId == getRecordTypeId('Online_Store_Customer');
    }

    /**
     * @name getThreeMinutesFromNow
     * @description a cron expression fro 3 minutes from now. For Testing purposes.
     * @return String
     */
    private static String getThreeMinutesFromNow(){
        DateTime now = DateTime.now();

        Integer threeMinutesFromNow = now.minute() + 3;

        String ret = now.second() + ' ';
        ret += threeMinutesFromNow + ' ';
        ret += now.hour() + ' ';
        ret += now.day() + ' ';
        ret += now.month() + ' ';
        ret += '?';

        return ret;
    }

/**
 * CLASSES
 */

    public class RecordTypeException extends Exception {}
    public class BrochureKeyException extends Exception {}
}
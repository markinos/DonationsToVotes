CREATE DATABASE IF NOT EXISTS dotes2votes;
USE dotes2votes;

SET FOREIGN_KEY_CHECKS = 0;

#Donors table
#A list of donors that give money to politicians.
DROP TABLE IF EXISTS DONORS;
CREATE TABLE DONORS (
	
    #PRIMARY KEY: Unique identifier but the number is useless
	DONOR_ID			integer				NOT NULL AUTO_INCREMENT, #to add: ZEROFILL AUTO_INCREMENT

    #FOREIGN KEY: The district the donor hails from when they donated
    DISTRICT			integer(2)			NULL, #either use NULL for non-WA or use DISTRICT = 50 for out of state and DISTRICT = 0 for unknown
    
   	#Donor's name in the format "Firstname M Lastname" with M being the middle initial
    DonorName			char (255)			NOT NULL,

	#Employer if listed, null if not
    Role				enum ('committee',
							  'company',
							  'organization',
                              'person',
                              'unknown',
                              'self'
                              )				NOT NULL,
    
    #CONSTRAINTS
    CONSTRAINT			DONORS_PK			PRIMARY KEY (DONOR_ID),
	CONSTRAINT 		    DONORS_DIST_FK		FOREIGN KEY (DISTRICT)
											REFERENCES  LOCATIONS (DISTRICT)
    
);

#Politicians table
#These are our state senators and representatives. Their name and their relevant representation
#information is provided.
DROP TABLE IF EXISTS POLITICIANS;
CREATE TABLE POLITICIANS (

    #PRIMARY KEY: Unique identifier but the number is useless
	POL_ID				integer				NOT NULL AUTO_INCREMENT,

    #FOREIGN KEY: The district the politician allegedly represents
    DISTRICT			integer(2)			NOT NULL,

	#Their name in the format "Firstname M Lastname" with M being the middle initial
    PoliticianName		char (255)			NOT NULL,
    
    #House, Senate, or null
    Chamber				enum('STATE SENATOR',
							 'STATE REPRESENTATIVE'
						)					NOT NULL,
    
   	#The political party--other should not be used as of this session 
	Party				enum('D',
							 'R',
                             'I',
                             'L',
                             'O', #aka made up bullshit party
                             'NO'
						)					NOT NULL,
    
    #The link to the politicians page or profile
    Link				text				NULL,

    #Percentage of donations raised out of district (by value)
    Cuckold				decimal(5,2)		NULL, #suggested use of NULL for members who cuckold score is 0 but have very few (<5?) donations

#information technically available via detailed sql queries; this information also available in csv files but would be redundant
#    #The amount of money raised
#    Raised				decimal(11,2)		NOT NULL,
#
#    #How many donations the politician has recieved
#    Donations			integer				NOT NULL,
                            	
    #CONSTRAINTS
	CONSTRAINT 		    POLITICIANS_PK 		PRIMARY KEY (POL_ID),
	CONSTRAINT 		    POLITICIANS_DIST_FK	FOREIGN KEY (DISTRICT)
											REFERENCES  LOCATIONS (DISTRICT)
                                            
);

#Locations
#More detailed information on each location
DROP TABLE IF EXISTS LOCATIONS;
CREATE TABLE LOCATIONS (

	#PRIMARY KEY: Unique identifier that is the district number itself
	DISTRICT			integer(2)			NOT NULL,
    
    #The link to the wikipedia page
    Link				text				NULL,
    
    #A very pretty map of the district
    Map					text				NULL,
    
    #CONSTRAINTS
    CONSTRAINT			LOCATIONS_PK		PRIMARY KEY (DISTRICT),
    CONSTRAINT			DISTRICT_LIMIT		CHECK (DISTRICT >= 0 AND DISTRICT <= 50) #either use NULL for non-WA or use DISTRICT = 50 for out of state and DISTRICT = 0 for unknown

);

#Zipcodes
#Table of zipcode-district relationships
DROP TABLE IF EXISTS ZIPCODES;
CREATE TABLE ZIPCODES (

	#PRIMARY KEY: Unique identifier that is the zip code in question.
	ZIPCODE				integer(5)			NOT NULL,
    
    #FOREIGN KEY: The district number associated with this zip code.
    DISTRICT			integer(2)			NULL, #either use NULL for non-WA or use DISTRICT = 50 for out of state and DISTRICT = 0 for unknown
    
    #CONSTRAINTS
    CONSTRAINT			ZIPCODES_PK			PRIMARY KEY (ZIPCODE),
    CONSTRAINT 		    ZIPCODES_DIST_FK	FOREIGN KEY (DISTRICT)
											REFERENCES  LOCATIONS (DISTRICT)
    
);

#Bills table
#Table of all the bills, their names, summaries, and any other relevant info.
#Note that bills don't need a house-senate enum because the first two letters
#of a bill denote that.
DROP TABLE IF EXISTS BILLS;
CREATE TABLE BILLS (

	#PRIMARY KEY The usually 7 character name that denotes a bill (e.g. HB 3708, SB 1202)
	BILL_NAME			char (32)			NOT NULL,
    
    #The technical full name of the bill
    FullName			char (255)			NOT NULL,
    
    #The full summary of the bill (this may be quite long)
    Summary				text				NULL,

	#CONSTRAINTS
	CONSTRAINT 		    BILL_PK   			PRIMARY KEY (BILL_NAME)
    
);

#Keywords table
#Called Topic or Summary on the websites, this is a one-to-few words indicator
#of a politically sensitive issue--note that the offical legislative site structures
#bills to be searchable in this fashion.
DROP TABLE IF EXISTS KEYWORDS;
CREATE TABLE KEYWORDS (

	#COMPOSITE KEY: FOREIGN KEY: Keyword that describes in short a politically relevant issue (also subject, topic).
	KEYWORD				char (255)			NOT NULL,

	#COMPOSITE KEY: FOREIGN KEY: The bill name this topic appears in
	BILL_NAME			char (32)			NOT NULL,
	
    #CONSTRAINTS
    CONSTRAINT			KEYWORDS_PK			PRIMARY KEY (BILL_NAME, KEYWORD),
	CONSTRAINT 		    KEYWORDS_BILL_FK 	FOREIGN KEY (BILL_NAME)
											REFERENCES  BILLS (BILL_NAME)
                                            
);

#Votes table
#Contains a list of all the votes on all the bills.
DROP TABLE IF EXISTS VOTES;
CREATE TABLE VOTES (

	#COMPOSITE KEY: FOREIGN KEY: The house or senate voting member
	POL_ID				integer				NOT NULL,

	#COMPOSITE KEY: FOREIGN KEY: The bill name the person vote on.
	BILL_NAME			char (32)			NOT NULL,
    
    #How the person voted on this bill
	Vote				enum ('y',
							  'n',
							  'o'
							  
						)					NOT NULL,
                        
	#Whether this person is also a sponsor of the bill
    Sponsor				bool				NOT NULL,
    
    #CONSTRAINTS
    CONSTRAINT			VOTES_PK			PRIMARY KEY (POL_ID, BILL_NAME),
	CONSTRAINT 		    VOTES_POL_FK	 	FOREIGN KEY (POL_ID)
											REFERENCES  POLITICIANS (POL_ID),
    CONSTRAINT 		    VOTES_BILL_FK 		FOREIGN KEY (BILL_NAME)
											REFERENCES  BILLS (BILL_NAME)
                                            
);

#Donations table
#Records donations from any entity to any other entity
DROP TABLE IF EXISTS DONATIONS;
CREATE TABLE DONATIONS (

    #PRIMARY KEY: Unique identifier but the number is useless
    BRIBE_ID			integer				NOT NULL AUTO_INCREMENT,
	
    #FOREIGN KEY: The person giving the money
	DONOR_ID			integer				NOT NULL,
    
    #FOREIGN KEY: The person recieving the money
	POL_ID				integer				NOT NULL,
    
    #The date the donation was filed on
	DonationDate		date				NOT NULL,
    
    #The amount of the donation
    Amount				decimal(11,2)		NOT NULL,

	#Whether this is considered self-funding (some self donor ids are not candidate names)
    SelfFunding			boolean				NOT NULL,
    
    #CONSTRAINTS
    CONSTRAINT			DONATIONS_PK		PRIMARY KEY (BRIBE_ID),
	CONSTRAINT 		    DONATIONS_DONOR_FK	FOREIGN KEY (DONOR_ID)
											REFERENCES  DONORS (DONOR_ID),
	CONSTRAINT 		    DONATIONS_POL_FK	FOREIGN KEY (POL_ID)
											REFERENCES  POLITICIANS (POL_ID)
                                            
);

SET FOREIGN_KEY_CHECKS =1;
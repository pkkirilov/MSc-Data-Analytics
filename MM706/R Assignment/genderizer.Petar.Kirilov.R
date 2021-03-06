dset <- read.csv("titanic-b.csv") #load the dataset in the R environment
dset$Gender <- NA                 #create an empty column called Gender to the dataframe
install.packages("stringr")       #install the package required to split the name field
library(stringr)                  #load the package
install.packages("gender")        #install the package required to identify gender based on first name
library(gender)                   #load the package
install_genderdata_package()      #download the name database. When prompted, press 1
splits <- as.data.frame(str_split_fixed(dset$Name, ", ", 2)) #extracts the name column and convert into surname and the rest of the nanem
dset$Surname <- splits$V1         #append the surname column
splits <- as.data.frame(str_split_fixed(splits$V2, " ", 2)) #separate title from first name
dset$Title <- splits$V1           #append the title column
dset$Firstnames <- splits$V2      #append the first names column
#after observation, one of the name fields has not been separated
splits <- as.data.frame(str_split_fixed(dset$Surname[dset$Title == ""], " ", 3)) #split the name field
dset$Title[dset$Title == ""] <- splits$V2 #append the title in the Title column
dset[dset$Title == "Lucy",]       #it is evident that record is not in the usual format
gender(as.character(dset$Title[dset$Title == "Lucy"])) #run the gender package to identify the gender
dset$Gender[dset$Title == "Lucy"] <- "Female" #as the gender identified was female, we can append Female for the records
dset$Gender[dset$Title == "Mr" | dset$Title == "Master"] <- "Male" #adds Male to the gender column
dset$Gender[dset$Title == "Ms" | dset$Title == "Mrs" | dset$Title == "Miss"] <- "Female" #adds Female to the gender column
nas <- dset[is.na(dset$Gender),]  #add the unclassified (NA's) genders to a new dataframe
dset <- dset[!is.na(dset$Gender),]#remove the unclassified (NA's) gender from DF (will be appended later)
nas$Firstnames <- sub("(\\w+).*", "\\1", nas$Firstnames) #select only first name
nas$Gender1 <- as.data.frame(gender(as.character(nas$Firstnames), method = 'kantrowitz')) #allocate gender
nas$Gender <- nas$Gender1$gender  #append gender in right column
nas <- within(nas, rm(Gender1))   #discard the not needed columns
nas2 <- nas[!complete.cases(nas$Gender) | nas$Gender == "either",]  #extract only NAs and 'either'
nas <- nas[complete.cases(nas$Gender),] #remove NAs from the dataframe
nas <- nas[nas$Gender != "either",] #remove 'either' from the dataframe
nas3 <- as.data.frame(gender(as.character(nas2$Firstnames), method = "ipums")) #allocate gender using other name database
nas2 <- merge(nas2, nas3, by.x = "Firstnames", by.y = "name", all.x = TRUE) #merge the identified genders
nas2 <- nas2[!duplicated(nas2),]  #remove duplicates caused by merging dataframes of different lenghts
nas2$Gender <- nas2$gender        #append the gender classification to the correct column
nas2 <- within(nas2, rm(gender, proportion_male, proportion_female, year_min, year_max)) #remove the columns that are not needed
nas <- rbind(nas, nas2)           #collate the newly identified genders with the rest of the data
#need to match gender to title in order to improve accuracy
table <- nas[,c(13,15)]           #add the Title and Gender column to a table to look at the proportion of Males/Females
table$Gender[is.na(table$Gender)] <- 0 #assign 0 to NA values to be visible in prop.table function
round(prop.table(table(table), 2)*100)      #from the table it is evident that the majority (90.7%) with title "Sig" are males, 
#thus we can conclude all names with title "Sig" are males and the rest were incorrectly 
#assigned or not found; similarly, names with title "Fr" 85.71% males; 
nas$Gender[nas$Title == "Sig."] <- "Male"
#function to capitalise genders
capFirst <- function(s) {
  paste(toupper(substring(s, 1, 1)), substring(s, 2), sep = "")
}
nas$Gender <- capFirst(nas$Gender)#capitalise the genders by using the above function
dset <- rbind(dset, nas)          #attach the records with the identified genders
dset <- within(dset, rm(Surname, Title, Firstnames)) #remove not needed columns
dset <- dset[, c(1,13,2:12)]      #rearrange the Gender column to be the second one
write.csv(dset, file = "titanic-b-genderised.csv", row.names = FALSE) #create a csv file
rm(list = ls())                   #clear the working directory


#----- DATABASE CREATION ----

create database employee;
use employee;
#---------------------------

#----- TABLE CREATION -----

create table Departments(
department_id int primary key auto_increment,
department_name varchar(100) not null
);

create table Locations(
location_id int primary key auto_increment,
location varchar(30) not null
);

create table Employees(
employee_id int primary key auto_increment,
employee_name varchar(50) not null,
gender enum ('M','F'),
age int,
hire_date date,
designation varchar(100),
department_id int,
location_id int,
salary decimal(10,2),
foreign key(department_id) references Departments(department_id),
foreign key(location_id) references Locations(location_id)
);
#-----------------------------------------------------

#------- ALTER TABLES FOR PRIMARY KEY CUSTOMIZATION ---------------
alter table Locations auto_increment = 1;
alter table Departments auto_increment = 101;
alter table Employees auto_increment = 1001;
#  -------------------------------------------------------------

# ------ ALTER TABLES FOR CONSTRAINTS -------------------------------
alter table Locations add constraint name_constraint unique(location);
alter table Departments add constraint name_constraint_dept unique(department_name);
alter table Employees add constraint CHK_Age CHECK (age >= 18);
alter table Employees alter column hire_date set default (CURRENT_DATE);
#------------------------------------------------------------------------------


/*
2. Table Alteration (ALTER): Consider the following scenarios and write the SQL
statements to alter the structure of the tables accordingly:
*/
/*
⦿ Add a new column named "email" to the Employees table to store
employee email addresses.
*/

ALTER TABLE Employees ADD COLUMN email varchar(50);

/*
⦿ Modify the data type of the "designation" column in the Employees
table to support a wider range of values.
*/
ALTER TABLE Employees MODIFY COLUMN designation varchar(200);

/*
⦿ Drop the “age” column from the Employees table.
*/
alter table Employees DROP COLUMN age;

/*⦿ Rename the “hire_date” column to “date_of_joining”.*/
ALTER TABLE Employees 
RENAME COLUMN hire_date TO date_of_joining;


/*
3. Table Renaming (RENAME): Rewrite the SQL statements to rename the
following tables:
*/
/*
⦿ Rename the "Departments" table to "Departments_Info".
*/
RENAME TABLE Departments TO Departments_Info;

/*⦿ Rename the "Location" table to "LocationsInfo".*/
RENAME TABLE Locations TO LocationsInfo; 

/*4. Table Truncation (TRUNCATE): Write an SQL statement to truncate the
Employees table.
*/
TRUNCATE TABLE Employees;


-- 1. Drop the Employees table
DROP TABLE Employees;

-- 2. Drop the employee database
DROP DATABASE IF EXISTS employee;


-- Check if columns, types, and defaults are correct
DESCRIBE Employees;
DESCRIBE Departments_Info;
DESCRIBE Locationsinfo;




--Create Database LearnBay_DA_Project;

Use LearnBay_Da_Project;

--Checking the Data
Select * From Company_Data;


--1.	What is the total revenue by Industry Sector?
Select Format(sum(Revenue)/1000000000, 'N') + 'Billion' as 'Total_Revenue'
From Company_Data



--2.	How many Directors are Male and Female?
Select 
Sum(Case When Gender = 'M' then 1 Else 0 End) as 'Number of Male Directors',
Sum(Case When Gender = 'F' then 1 Else 0 End) as 'Number of Female Directors'
From Company_Data;



--3.	How many CEOs are there who are female and over 50 yrs of age?
Select count(Director_ID) as 'Female_CEOs'
From Company_Data
Where (Gender = 'F') and (CEO = 1) and (Age > 50);



--4.	What is the total revenue per Industry Sector for Directors that have a Retirement_Age_Directors_Years recorded?

--Alter Table Company_Data
--Alter Column Retirement_Age_Directors_Years float;

--Alter Table Company_Data
--Alter Column Resignation_date datetime;

EXEC sp_help 'Company_Data'

Select Industry_Sector, Format(sum(Revenue)/1000000000, 'N') + ' Billions' as 'Total_Revenue'
From Company_Data
Where Retirement_Age_Directors is not null
Group by Industry_Sector
Order by 2 desc;


Select Industry_Sector, Sum(Case When Retirement_Age_Directors is not null THEN Revenue else 0 END) as 'Total Revenue'
From Company_Data
Group by Industry_Sector;



--5.	How many Directors that have a Retirement_Age_Directors_Years recorded are over the age of 60?
Select count(Retirement_Age_Directors) as Retiered_directors_over60
From Company_Data
Where Retirement_Age_Directors > 60;




--6.	How many Directors have a Board_Membership of "Member" or "Chair", Resignation_date recorded and Retirement_Age_Directors_Years recorded?
Select 
Sum(Case When Board_Membership like 'Member' then 1 Else 0 End) as 'Member_Director',
Sum(Case When Board_Membership like 'Chair' then 1 Else 0 End) as 'Chair_Director'
From Company_Data
Where (Resignation_date is not null) and (Retirement_Age_Directors is not null);




--7.	What is the total revenue per Industry_Sector for Directors that have a Retirement_Age_Directors_Years recorded and served as Chair?
Select Industry_Sector, Format(sum(Revenue)/1000000000, 'N') + ' Billion' as Total_Revenue
From Company_Data
Where (Retirement_Age_Directors is not null) and (Board_Membership like 'Chair')
Group by Industry_Sector
Order by 2 ;





--8.	What is the total revenue per Industry_Sector for Directors who have a Retirement_Age_Directors_Years recorded, 
--have served as "Chair", have a Resignation_date recorded, and have been appointed to the board after 01-01-2015?

Select Industry_Sector, Format(sum(Revenue)/1000000000, 'N') + ' Billion' as Total_Revenue
From Company_Data
Where (Retirement_Age_Directors is not null) and (Board_Membership like 'Chair') and (Resignation_date is not null) and (Board_joining_date > 2015-01-01)
Group by Industry_Sector
Order by 2 desc;





--9.	How many Directors have a Retirement_Age_Directors_Years recorded, have served as a "Member", 
--have a Resignation_date recorded, and have been appointed to the board before 01-01-2010?

Select count(Director_ID) as Number_of_Directors
From Company_Data
Where Retirement_Age_Directors is not null
and Board_Membership like 'Member'
and Resignation_date is not null
and Board_joining_date < '2010-01-01';





--10.	What is the average revenue per Industry_Sector for Directors who joined the board before 01-01-2010, 
--have a Board_Membership of "Chair" or "Member", have a Resignation_date recorded, and have a Retirement_Age_Directors_Years recorded?

Select Industry_Sector, Format(avg(Revenue)/1000000000, 'N') + ' Billion' as Total_Revenue
From Company_Data
Where Board_joining_date < '2010-01-01'
and (Board_Membership like 'Chair' or Board_Membership like 'Member')
and Resignation_date is not null
and Retirement_Age_Directors is not null
Group by Industry_Sector
Order by 2 desc;

--=================================================================================================================================

--Year over year share of Female Directors in Companies, How the share of Female vs Male Directors is changing in Companies

With Yearly_Directors As (
    Select
        Year(Board_joining_date) as Year,
        Count(Director_ID) as Total_Directors,
        Sum(Case When Gender = 'F' Then 1 Else 0 END) as Female_Directors
    From Company_Data
    Group By YEAR(Board_joining_date)
	--Order by 1
)
Select
    Yearly_Directors.Year,
    (Yearly_Directors.Female_Directors *100/ Yearly_Directors.Total_Directors)  as 'Female Director Percentage % '
From Yearly_Directors
Order By Yearly_Directors.Year;


--Creating a View
Create View YoY_Female_Directors
AS
With Yearly_Directors As (
    Select
        Year(Board_joining_date) as Year,
        Count(Director_ID) as Total_Directors,
        Sum(Case When Gender = 'F' Then 1 Else 0 END) as Female_Directors
    From Company_Data
    Group By YEAR(Board_joining_date)
	--Order by 1
)
Select
    Yearly_Directors.Year,
    (Yearly_Directors.Female_Directors *100/ Yearly_Directors.Total_Directors)  as 'Female Director Percentage % '
From Yearly_Directors
--ORDER BY Yearly_Directors.Year;
GO

Select * From YoY_Female_Directors

--DAX PowerBI
--YoY_Female = COUNTROWS(FILTER(Data_Pjt_New, Data_Pjt_New[Gender] = "F" ))*100/ COUNTROWS(Data_Pjt_New)

--==============================================================================================================


--Find out Male vs Female Director share in different Industry_Sectors and Revenue Category
--Revenue Catrgory - 
--$100M to < $300M
--$300M to < $1B
--Below $100M
--20 B and Above
--$3B to < $10B
--$10B to < $20B

Create View Male_vs_Female_Director_Share
AS
With 
    CTE_Revenue_Category As (
        Select 
            Director_ID, 
            Industry_Sector,
            Gender,
            Case 
                When Revenue >= 100000000 AND Revenue < 300000000 Then '$100M to < $300M'
                When Revenue >= 300000000 AND Revenue < 1000000000 Then '$300M to < $1B'
                When Revenue < 100000000 Then 'Below $100M'
                When Revenue >= 20000000000 Then '$20B and Above'
                When Revenue >= 3000000000 AND Revenue < 10000000000 Then '$3B to < $10B'
                When Revenue >= 10000000000 AND Revenue < 20000000000 Then '$10B to < $20B'
                ELSE 'Other'
            END as Revenue_Category
        FROM 
            Company_Data
    )
    SELECT
        CTE_Revenue_Category.Revenue_Category,
        CTE_Revenue_Category.Industry_Sector,
        SUM(Case When Gender = 'M' Then 1 Else 0 END) as Male_Directors,
        SUM(Case When Gender = 'F' Then 1 Else 0 END) as Female_Directors,
        SUM(Case When Gender = 'M' Then 1 Else 0 END) * 100 / COUNT(Director_ID) as 'Male_Percentage %',
        SUM(Case When Gender = 'F' Then 1 Else 0 END) * 100 / COUNT(Director_ID) as 'Female_Percentage %'
    From CTE_Revenue_Category
    Group By CTE_Revenue_Category.Revenue_Category, CTE_Revenue_Category.Industry_Sector
    Order By CTE_Revenue_Category.Industry_Sector,CTE_Revenue_Category.Revenue_Category
GO

-- DAX Function
--Revenue_Categories = IF(AND(Data_Pjt_New[Revenue]>=0,Data_Pjt_New[Revenue]<100000000),"Below $100M",
--IF(AND(Data_Pjt_New[Revenue]>=100000000,Data_Pjt_New[Revenue]<300000000),"$100M to < $300M",
--IF(AND(Data_Pjt_New[Revenue]>=300000000,Data_Pjt_New[Revenue]<1000000000),"$300M to < $1B",
--IF(AND(Data_Pjt_New[Revenue]>=1000000000,Data_Pjt_New[Revenue]<3000000000),"$1B to < $3B",
--IF(AND(Data_Pjt_New[Revenue]>=3000000000,Data_Pjt_New[Revenue]<10000000000),"$3B to < $10B",
--IF(AND(Data_Pjt_New[Revenue]>=10000000000,Data_Pjt_New[Revenue]<20000000000),"$10B to < $20B",
--IF(Data_Pjt_New[Revenue]>=20000000000,"20B and Above","Other")))))))

--Male_Directors = COUNTROWS(FILTER(Data_Pjt_New, Data_Pjt_New[Gender] = "M"))
--Female_Directors = COUNTROWS(FILTER(Data_Pjt_New, Data_Pjt_New[Gender] = "F"))

--%_Male_Director = [Male_Directors]*100/COUNTROWS(Data_Pjt_New)
--%_Female_Directors = [Female_Directors]*100/COUNT(Data_Pjt_New[Director_ID])


--===================================================================================================================


--% of Directors in mentioned Age Category 
--40 Years or Below
--41 to 60 Years
--61 to 72 Years
--Above 72 Years

Create View Perc_of_Directors_Age_Category
AS
With Age_Category As (
	Select Director_ID,
	Case When Age <= 40 Then 'Director_Below_40'
		 When Age > 40 AND Age <= 60 Then 'Director_Between_41_to_60'
		 When Age > 60 AND Age <= 72 Then 'Director_Between_61_to_72'
		 When Age > 72  Then 'Director_Above_72'
		 Else 'Other'
	End as Age_Category
	From Company_Data
)
Select Age_Category,
	   Count(Director_ID) as Total_Directors,
	   Count(Director_ID) * 100 / (Select Count(Director_ID) From Company_Data) as '% Percentage'
From Age_Category
Group by Age_Category
--Order by Age_Category;
GO


-- DAX Function
--Age_Caetgories = IF(AND(Data_Pjt_New[Age]>=0,Data_Pjt_New[Age]<=40),"40 Years or Below",
--IF(AND(Data_Pjt_New[Age]>40,Data_Pjt_New[Age]<=60),"41 to 60 Years",
--IF(AND(Data_Pjt_New[Age]>60,Data_Pjt_New[Age]<=72),"61 to 72 Years",
--IF(Data_Pjt_New[Age]>72,"Above 72 Years","Other"))))


--==================================================================================================================


--% of Companies disclosing Retirement age of Directors

Create View Perc_Companies_disclosing_Retirement_age_Directors
As
Select count(Distinct Case When Retirement_Age_Directors is not null Then Company_Name Else null End)*100 / Count(Distinct Company_Name) AS '% Companies_Disclosing_Retirement_Age_Directors'
From Company_Data;
GO
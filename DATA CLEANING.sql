-- data cleaning

select * from layoffs;

-- 1. remove duplicates
-- 2. standardize the data(issues like speeling)
-- 3. null values & blank values
-- 4. remove rows/columns that aren't necessary

-- create some kind of staging dataset so that we do not change the raw data.if we make any kinda mistakes we want the raw daat available
-- do not work on raw data!!
create table layoffs_staging
like layoffs;

select * from layoffs_staging;   #table created

-- insert data in layoffs to layoffs_staging
insert layoffs_staging
select *
from layoffs;

select * from layoffs_staging;   #data inserted successfully

-- 1.REMOVING DUPLICATES
-- if there is any unique column like id's removing duplicates would be very easy. but here we do not have any
select *,
row_number() over(partition by company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
from layoffs_staging;
 
 -- put this into subquery or cte here cte
 
 with duplicate_cte as
 (
select *,
row_number() over(partition by company,location, industry, total_laid_off, percentage_laid_off, `date`,stage,country,funds_raised_millions) as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num>1;

-- lets take a look on duplicates
select * from layoffs_staging
where company ='Casper';

-- try delete
 with duplicate_cte as
 (
select *,
row_number() over(partition by company,location, industry, total_laid_off, percentage_laid_off, `date`,stage,country,funds_raised_millions) as row_num
from layoffs_staging
)
delete 
from duplicate_cte
where row_num>1;   #didn't work

-- lets filter on using row_num column by create another staging2
-- creating table layoffs_staging2(right click on layoffs_staging in schemas-copy to clipboard-create statement)
-- add another column row_num to the code and change name to staging2
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select* from layoffs_staging2;  #table created

insert into layoffs_staging2
select *,
row_number() over(partition by company,location, industry, total_laid_off, percentage_laid_off, `date`,stage,country,funds_raised_millions) as row_num
from layoffs_staging;      # data inserted

-- check table
select* from layoffs_staging2;

-- filtering
select * from layoffs_staging2
where row_num >1;

-- deleting
delete 
from layoffs_staging2
where row_num>1;

-- check
select * from layoffs_staging2
where row_num >1;    #done deleted


-- 2.STANDARDIZING DATA
-- finding issues in every column and cleaning
-- filtering company column
select distinct(company)
from layoffs_staging2;
 
select distinct(trim(company))
from layoffs_staging2;     #trim removes white spaces. in 1,2 rows theres white space which is now removed

select company,trim(company)
from layoffs_staging2;    # view difference
 
update layoffs_staging2
set company = trim(company);   #updated into the table
 
 -- filtering in industry column
 select industry
 from layoffs_staging2;
 
 select distinct industry
 from layoffs_staging2;
 
 select distinct industry
 from layoffs_staging2
 order by 1;    #order by 1st column
 
 -- we can see crypto, crypto currency, cryptocurrency all are same so lets check that
 select * from layoffs_staging2
 where industry like 'crypto%';    
 
 -- update all of 'em to single name crypto
 update layoffs_staging2
 set industry ='crypto'
 where industry like 'crypto%';    #updated
 
 -- let's check
select industry from layoffs_staging2
 where industry like 'crypto%';    #doneee
 
 -- filtering location
 select location
 from layoffs_staging2;
 
select distinct location
 from layoffs_staging2
 order by 1;    #looks pretty good
 
 -- filtering country
 select distinct country
 from layoffs_staging2
 order by 1;   #there's a dot on united states. lets remove it
 
 select *
 from layoffs_staging2
 where country like 'United States.'
 order by 1;          
 
 -- lets trim
 select distinct country, trim(country)
 from layoffs_staging2
 where country like 'United States.'
 order by 1;          #trim didnt fix
 
 -- use trailing
  select distinct country, trim(trailing '.' from country)
 from layoffs_staging2
 where country like 'United States.'
 order by 1;       # doneee
 
 -- lets updatethe table
 update layoffs_staging2
 set country = trim(trailing '.' from country)
 where country like 'united states%';
 
 -- check
 select country from layoffs_staging2
 where country like 'united states%';    # dot is removed
 
 -- filtering date to date format instead of text
select `date`,
str_to_date(`date`, '%m/%d/%Y')   #date format
from layoffs_staging2;
 
 -- update the table
 update layoffs_staging2
 set `date` = str_to_date(`date`, '%m/%d/%Y') ;   
 
 -- check table
 select * from layoffs_staging2;   #done updated
 
 
 -- in schemas the dat ecolumn is in text format lets change it to date format
 alter table layoffs_staging2
 modify column `date` date;   #worked
 
 -- 3.WORKING WITH NULL AND BLANK VALUES
-- LETS START WITH TOTAL LAID OFF COLUMN
select * from layoffs_staging2
where total_laid_off is null; 

select * from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- checking industry
select distinct industry
from layoffs_staging2; 

-- filter
select *
from layoffs_staging2
where industry is null 
or industry = '';   #there are few

select * from layoffs_staging2
where company='airbnb';    #uodate the industry with travel

select t1.industry, t2.industry
 from layoffs_staging2 as t1
join layoffs_staging t2
on t1.company=t2.company     #this is imp because what if there are other airbnb's of diff company and diff loactions?
 where (t1.industry is null or t1.industry = '')
 and t2.industry is not null;
 
 -- lets update
 update layoffs_staging2 as t1
 join layoffs_staging2 as t2
 on t1.company=t2.company
 set t1.industry=t2.industry
 where (t1.industry is null or t1.industry ='')
 and t2.industry is not null;
 
 update layoffs_staging2
 set industry =null
 where industry ='';
 
  update layoffs_staging2 as t1
 join layoffs_staging2 as t2
 on t1.company=t2.company
 set t1.industry=t2.industry
 where t1.industry is null 
 and t2.industry is not null;         #airbnb's done
 
 -- check table
 select * from layoffs_staging2
 where industry is null;        #bally's still null
 
  select * from layoffs_staging2
  where company like 'bally%';    #only have 1 row so we cannot populate
  
  -- we cant populate all the remaining null date with the existing data. if we had comapny 
  -- if we had comapny total before laid off then we might populat ethe laid off data by calculations like using subtractions.
  
  select * from layoffs_staging2
  where total_laid_off is null
  and percentage_laid_off is null;
  
  delete 
  from layoffs_staging2
  where total_laid_off is null
  and percentage_laid_off is null;   #deleted nulls
  
  select * from layoffs_staging2;
  
  -- we dont need row_num column anyomore so lets remove
  alter table layoffs_staging2
  drop row_num;
  
 
 

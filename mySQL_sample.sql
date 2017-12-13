
##### Create funder success rate columns

use water;

## total count
DROP TABLE IF EXISTS funder_total;
CREATE TEMPORARY TABLE funder_total
SELECT 1 dummy,funder,COUNT(*) total
FROM waterpoints
GROUP BY funder;

## functional count
DROP TABLE IF EXISTS funder_functional;
CREATE TEMPORARY TABLE funder_functional
SELECT funder,COUNT(*) functional
FROM waterpoints
WHERE status_group = 'functional'
GROUP BY funder;


## 'functional needs repair' count
DROP TABLE IF EXISTS funder_needsrepair;
CREATE TEMPORARY TABLE funder_needsrepair
SELECT funder,COUNT(*) needsrepair
FROM waterpoints
WHERE status_group = 'functional needs repair'
GROUP BY funder;


## 'non functional' count
DROP TABLE IF EXISTS funder_nonfunctional;
CREATE TEMPORARY TABLE funder_nonfunctional
SELECT funder,COUNT(*) nonfunctional
FROM waterpoints
WHERE status_group = 'non functional'
GROUP BY funder;

## Join the three category tables
DROP TABLE IF EXISTS funder_counts;
CREATE TEMPORARY TABLE funder_counts
SELECT *
FROM funder_total
left join funder_functional using(funder)
left join funder_needsrepair using(funder)
left join funder_nonfunctional using(funder);

## Calculate percentages for funders with at least five waterpoints
DROP TABLE IF EXISTS funder_stats;
CREATE TEMPORARY TABLE funder_stats
SELECT funder,
	functional/total as funder_functional,
	needsrepair/total as funder_needsrepair,
    nonfunctional/total as funder_nonfunctional
FROM funder_counts
WHERE total >= 5;


## Calculate averages
DROP TABLE IF EXISTS funder_averages;
CREATE TEMPORARY TABLE funder_averages
SELECT 
	1 dummy,
	avg(funder_functional) as funder_functional,
	avg(funder_needsrepair) as funder_needsrepair,
    avg(funder_nonfunctional) as funder_nonfunctional
FROM funder_stats;

## Impute mean column score for funders with fewer than ten waterpoints
DROP TABLE IF EXISTS funder_imputed;
CREATE TEMPORARY TABLE funder_imputed
SELECT 
funder, funder_functional, funder_needsrepair, funder_nonfunctional
FROM funder_total left join funder_averages using(dummy)
where funder_total.total < 5;

## Connect the rows with calculated and imputed values
DROP TABLE IF EXISTS funders;
CREATE TABLE funders
SELECT * FROM funder_stats
UNION 
SELECT * from funder_imputed;


##### Merge original tables and calculated field tables, export to csv

use water;

SELECT *
FROM waterpoints
join funders using(funder)
join installers using(installer)
join waterpoints_plus using(id, status_group)
join funder_installers using(funder_installer)
join region_code_data using(region_code)
join lga_data using(lga)
join ward_data using(ward)

INTO OUTFILE 'C:\\ProgramData\\MySQL\\MySQL Server 5.7\\Uploads\\1146.csv' 
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n';
;



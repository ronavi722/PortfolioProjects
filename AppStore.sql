--------------------------------------------------Appstore Analysis---------------------------------------------------------------
/*
	The client, a startup interested in creating an app for the Apple App Store, is in need of an analysis of existing apps in the 
	store. They are looking for insights into specific categories or types of apps that would aid in developing the right app based 
	on these insights.
*/

-----------------------------------------------------------------------------------------------------------------------------------

-- Merging the four separate datasets into a unified dataset.

CREATE TABLE  appleStore_description_combined (
    id INT,
    track_name VARCHAR(255),
    size_bytes BIGINT,
    app_desc TEXT
);

INSERT INTO apple_store.dbo.appleStore_description_combined (id, track_name, size_bytes, app_desc)
SELECT id, track_name, size_bytes, app_desc 
FROM apple_store.dbo.appleStore_description1
UNION ALL
SELECT id, track_name, size_bytes, app_desc FROM apple_store.dbo.appleStore_description2
UNION ALL
SELECT id, track_name, size_bytes, app_desc FROM apple_store.dbo.appleStore_description3
UNION ALL
SELECT id, track_name, size_bytes, app_desc FROM apple_store.dbo.appleStore_description4;

-- first look of the combined dataset.

select *
from apple_store.dbo.appleStore_description_combined;

-- first look of the apple store dataset .

select *
from apple_store.dbo.AppleStore;

-------------------------------------------------------------------------------------------------------------------------------------------
-- Inspecting the data for any inconsistencies or errors that require cleaning.

-- Checking for unique apps in the both the datasets

select COUNT(Distinct id) as uniqueAppId
from apple_store.dbo.AppleStore;

select COUNT(Distinct id) as uniqueAppId
from apple_store.dbo.appleStore_description_combined;

-- checking for null values in the key fields of the dataset

select COUNT(*)
from apple_store.dbo.AppleStore
where track_name is null or prime_genre is null or user_rating is null ;

select COUNT(*)
from apple_store.dbo.appleStore_description_combined
where app_desc is null ;

/*
	The dataset is free from any discrepancies and does not necessitate any cleaning.
*/
-----------------------------------------------------------------------------------------------------------------------------------

-- Exploratory Data Analysis

-- 1.Number of apps per genere

select prime_genre,COUNT(*) no_apps
from apple_store.dbo.AppleStore
group by prime_genre
order by 2 desc;

--2.Overview of the user rating

select MAX(user_rating) as max_rating,
	   MIN(user_rating) as min_rating,
	   AVG(user_rating) as avg_rating
from apple_store.dbo.AppleStore;

--3.Which got higher rating paid apps or free apps

with app_cte as (
	select case	
		when price > 0 then 'paid'
		else 'free' end  as app_type,
	   user_rating 
	from apple_store.dbo.AppleStore)
select app_type,AVG(user_rating) as avg_rating
from app_cte
group by  app_type
order by 2 desc;

-- 5.Checking if apps with more supported language have higher rating

with app_cte as (
	select case 
		when lang_num < 10 then '< 10 languages'
		when lang_num > 10 and lang_num <30 then '10-30 language'
		else '>30 language'
		end as total_lang,
		user_rating
	from apple_store.dbo.AppleStore)
select total_lang,AVG(user_rating) as avg_rating
from app_cte
group by total_lang
order by 2 desc;

-- 6.Average rating of genere

select top 10 prime_genre,AVG(user_rating) as avg_rating
from apple_store.dbo.AppleStore
group by prime_genre
order by 2;

--7.Correlation between the app's decription and user rating

with app_cte as(
	select case 
		when LEN(cast (b.app_desc as varchar(max))) < 500 then 'short'
		when LEN(cast (b.app_desc as varchar(max))) between 500 and  1000 then 'medium'
		else 'long' end as desc_length,
		user_rating
	from apple_store.dbo.AppleStore as a
	join apple_store.dbo.appleStore_description_combined as b
	on a.id=b.id)
select desc_length,AVG(user_rating) as avg_rating
from app_cte
group by desc_length
order by 2 desc;

--8.Check the top rated app in each genere 

with app_cte as (
	select prime_genre,track_name,user_rating,
		   RANK() over(partition by prime_genre order by user_rating desc,rating_count_tot desc) as app_ranking
	from apple_store.dbo.AppleStore
	)
select prime_genre,track_name,user_rating
from app_cte
where app_ranking=1;

-----------------------------------------------------------------------------------------------------------------------------------
/*
	Recomedations to the client,
		1.Paid apps vs free apps-
			• The higher average user rating for paid apps suggests that users who invest in and use the app may have greater 
			  engagement and perceive higher value, potentially leading to better ratings. Therefore, considering the app's 
			  apparent quality, it could be justified to set a certain price for it.

		2.Langusages support-
			• Apps supporting a moderate number of languages, specifically between 10 and 30, exhibit the highest average ratings. 
			  Therefore, it emphasizes that the key is not the quantity of supported languages but rather focusing on selecting 
			  the right languages for the app

		3.Genres with significant market opportunities- 
			• Categories within finance and books where existing apps have lower user ratings indicate unmet user expectations. 
			  This presents a market opportunity to develop high-quality apps in these categories, addressing user needs better 
			  than existing apps, potentially leading to higher ratings and increased market penetration.

		4.Apps Description length-
			• We observed a positive correlation between the app's description length and user ratings. This implies that users 
			  value apps with a clear understanding of their purpose and functionality before installation. Therefore, a 
			  well-crafted description can effectively set clear expectations, potentially leading to increased user satisfaction.

		5. Target ratings-
			• On average, all apps have a rating of 3.5. To stand out from the crowd, the app should aim for a rating above 3.5.

		6. High competitve league-
			• Games and entertainment categories have a high volume of apps, indicating a potentially saturated market. While 
			  entering this sector poses challenges due to intense competition, the high demand suggests opportunities for those 
			  apps which can distinguish themselves in the competitive landscape.

*/

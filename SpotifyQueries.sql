-- SQL Project -- Spotify Dataset

-- creating table

DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify(
 artist VARCHAR(255),
 track VARCHAR(255),
 album VARCHAR(255),
 album_type VARCHAR(50),
 danceability FLOAT,
 energy FLOAT,
 loudness FLOAT,
 speechiness FLOAT,
 acousticness FLOAT,
 instrumentalness FLOAT,
 liveness FLOAT,
 valence FLOAT,
 tempo FLOAT,
 duration_min FLOAT,
 title VARCHAR(255),
 channel VARCHAR(255),
 views FLOAT,
 likes BIGINT,
 comments BIGINT,
 licensed BOOLEAN,
 official_video BOOLEAN,
 stream BIGINT,
 energy_liveness FLOAT,
 most_played_on VARCHAR(50)
);
SELECT * FROM spotify
LIMIT10;

-- listing all columns in table
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'spotify';

SELECT "Likes"
FROM spotify
LIMIT 10;

-- EDA
SELECT COUNT(*) FROM spotify

SELECT COUNT(DISTINCT "Artist") FROM spotify;

SELECT COUNT(DISTINCT "Album") FROM spotify;

SELECT DISTINCT "Album_type" FROM spotify;

SELECT MAX("Duration_min") FROM spotify;

SELECT MIN("Duration_min") FROM spotify;

SELECT * FROM spotify 
WHERE "Duration_min" = 0;

DELETE FROM spotify 
WHERE "Duration_min" = 0;

SELECT * FROM spotify 
WHERE "Duration_min" = 0;

-- Retriving names of tracks with over 1B streams
SELECT * FROM spotify
WHERE "Stream" >= 1000000000;

-- List Albums along with the artist
SELECT "Artist","Album" FROM spotify

-- Finding and sorting average dancability per albumn
SELECT "Artist","Album", avg("Danceability") as avg_danceability
FROM spotify
GROUP BY "Artist","Album"
ORDER BY avg_danceability desc;

-- Listing only tracks which include the official music video 
SELECT 
    "Track",
    SUM("Views") as total_views,
    SUM("Likes") as total_likes
FROM spotify
WHERE "official_video" = 'TRUE'
GROUP BY 1
ORDER BY 2 desc
LIMIT 5;


-- Finidng most viewed track off each album
SELECT "Album", "Track", SUM("Views")
FROM spotify
GROUP BY 1, 2
ORDER BY 3 DESC


-- Finding tracks that have more streams on spotify than youtube and sorting by differnece
SELECT 
    t1.*,
    (streamed_on_spotify - streamed_on_youtube) AS "Difference"

FROM
(SELECT 
    "Track",
    COALESCE(SUM(CASE WHEN "most_playedon" = 'Youtube' THEN "Stream" END),0) as "streamed_on_youtube",
    COALESCE(SUM(CASE WHEN "most_playedon" = 'Spotify' THEN "Stream" END),0) as "streamed_on_spotify"
FROM spotify
GROUP BY 1
) AS t1
WHERE 
    streamed_on_spotify > streamed_on_youtube
    AND 
    streamed_on_youtube <> 0
ORDER BY "Difference" DESC;

-- Finding top 3 most-viewed tracks for each artist using window

WITH ranking_artist
AS
(SELECT
    "Artist",
    "Track",
    SUM("Views") as total_view,
    DENSE_RANK() OVER(PARTITION BY "Artist" ORDER BY SUM("Views") DESC) as rank
FROM spotify
GROUP BY 1, 2
ORDER BY 1, 3 DESC
)
SELECT * FROM ranking_artist
WHERE rank <= 3

-- Cumulative share per artist
WITH t AS (
    SELECT
    "Artist",
    "Track",
    SUM("Stream") as track_streams
    FROM spotify
    GROUP BY 1,2
)
, ordered AS(
    SELECT
    "Artist",
    "Track",
    track_streams,
    SUM(track_streams) OVER (PARTITION BY "Artist") AS artist_total,
    ROW_NUMBER() OVER (PARTITION BY "Artist" ORDER BY track_streams DESC) AS pos
    FROM t
)
SELECT
    "Artist",
    "Track",
    track_streams,
    pos,
    SUM(track_streams) OVER(
        PARTITION BY "Artist"
        ORDER BY track_streams DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_streams,
    CASE
    WHEN NULLIF(artist_total, 0) IS NULL THEN 0
    ELSE 1.0* SUM(track_streams) OVER (
        PARTITION BY "Artist"
        ORDER BY track_streams DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )/ artist_total
    END AS cumulative_share
FROM ordered 
ORDER BY "Artist", pos;



-- Cummulative share of streams of artists by top 5 tracks ordered
WITH t AS (
    SELECT
    "Artist",
    "Track",
    SUM("Stream") as track_streams
    FROM spotify
    GROUP BY 1,2
)
, ordered AS(
    SELECT
    "Artist",
    "Track",
    track_streams,
    SUM(track_streams) OVER (PARTITION BY "Artist") AS artist_total,
    ROW_NUMBER() OVER (PARTITION BY "Artist" ORDER BY track_streams DESC) AS pos
    FROM t
)
SELECT "Artist",
    MAX(CASE WHEN pos = 5 THEN cumulative_streams END) AS top5_share
FROM (
    SELECT "Artist","Track",track_streams,pos,
        SUM(track_streams) OVER (PARTITION BY "Artist" ORDER BY track_streams DESC) AS cumulative_streams,
        SUM(track_streams) OVER (PARTITION BY "Artist") AS artist_total
    FROM ordered
) x
GROUP BY "Artist"
HAVING COUNT(*) >= 5
ORDER BY top5_share DESC;

-- Global ranking vs catalog ranking 
WITH t AS(
    SELECT "Artist", "Track", SUM("Stream") AS track_streams
    FROM spotify
    GROUP BY 1,2
)

SELECT 
    "Artist",
    "Track",
    track_streams,
    DENSE_RANK() OVER (ORDER BY track_streams DESC) AS global_rank,
    DENSE_RANK() OVER (PARTITION BY "Artist" ORDER BY track_streams DESC) AS artist_rank,
    CUME_DIST() OVER (ORDER BY track_streams) AS global_cume_dist,
    CUME_DIST() OVER (PARTITION BY "Artist" ORDER BY track_streams) AS artist_cume_dist
FROM t
ORDER BY global_rank;


-- Listing #1 songs by individual artists global ranking
WITH t AS(
    SELECT "Artist", "Track", SUM("Stream") AS track_streams
    FROM spotify
    GROUP BY 1,2
),
r AS (
    SELECT "Artist","Track",track_streams,
        DENSE_RANK() OVER (ORDER BY track_streams DESC) AS global_rank,
        DENSE_RANK() OVER (PARTITION BY "Artist" ORDER BY track_streams DESC) AS artist_rank
    FROM t
)
SELECT *
FROM r
WHERE artist_rank = 1
ORDER BY global_rank;
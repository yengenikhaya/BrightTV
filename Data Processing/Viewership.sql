SELECT * FROM bright_tv_viewership LIMIT 10;
--Converting time zone


SELECT
  RecordDate2 AS sa_ts,
  to_utc_timestamp(RecordDate2, 'Africa/Johannesburg') AS utc_ts
FROM bright_tv_viewership;

--Date Range Checking--
----------------------
SELECT min(RecordDate2), max(RecordDate2) FROM bright_tv_viewership;

--Check the Nulls from Viewership--

SELECT
  COALESCE(Channel2, 'None')    AS Channel2,
  COALESCE(ROUND(UserID0, 0), 0) AS UserID0,
  COALESCE(ROUND(userid4, 0), 0)    AS userid
  

FROM bright_tv_viewership;

--Channels--

SELECT DISTINCT(Channel2) FROM bright_tv_viewership
GROUP BY Channel2
ORDER BY Channel2 DESC;

--Convert the time stemps to SAST and extract the date and time components while creating a tome of the day bucket--

WITH base AS (
  SELECT
    UserID0,
    from_utc_timestamp(RecordDate2, 'Africa/Johannesburg') AS sast_ts,
    DATE(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) AS sast_date,
    DATE_FORMAT(
      from_utc_timestamp(RecordDate2, 'Africa/Johannesburg'),
      'HH:mm:ss'
    ) AS sast_time
  FROM bright_tv_viewership
)

SELECT
  CASE
    WHEN sast_time BETWEEN '05:00:00' AND '11:59:59' THEN 'Morning Viewer'
    WHEN sast_time BETWEEN '12:00:00' AND '16:59:59' THEN 'Afternoon Viewer'
    WHEN sast_time BETWEEN '17:00:00' AND '20:59:59' THEN 'Evening Viewer'
    ELSE 'Night Viewer'
  END AS viewer_type,
  COUNT(UserID0) AS viewers
FROM base
GROUP BY viewer_type
ORDER BY viewers DESC;

--Average duration--

SELECT
  ROUND(AVG(`Duration 2`), 2) AS avg_duration
FROM bright_tv_viewership
WHERE `Duration 2` IS NOT NULL;

SELECT
  from_utc_timestamp(RecordDate2, 'Africa/Johannesburg') AS sast_ts,

  DATE(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) AS sast_date,

  DATE_FORMAT(
    from_utc_timestamp(RecordDate2, 'Africa/Johannesburg'),
    'EEEE'
  ) AS day_of_week,

  CASE
    WHEN DAYOFWEEK(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) = 1
      THEN 7
    ELSE DAYOFWEEK(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) - 1
  END AS day_of_week_num

FROM bright_tv_viewership;

---Moonie Code--

WITH base AS (
  SELECT
    -- Clean user IDs
    CAST(UserID0 AS INT) AS user_id,
    CAST(userid4 AS INT) AS viewer_id,

    -- Clean channel
    COALESCE(Channel2, 'None') AS channel,

    -- Original timestamp (UTC)
    RecordDate2 AS utc_ts,

    -- Convert UTC → SAST
    from_utc_timestamp(RecordDate2, 'Africa/Johannesburg') AS sast_ts,

    -- Separate SAST date & time
    DATE(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) AS sast_date,
    DATE_FORMAT(
      from_utc_timestamp(RecordDate2, 'Africa/Johannesburg'),
      'HH:mm:ss'
    ) AS sast_time
  FROM bright_tv_viewership
),

enriched AS (
  SELECT
    *,
    -- Viewer time-of-day classification
    CASE
      WHEN sast_time BETWEEN '05:00:00' AND '11:59:59' THEN 'Morning Viewer'
      WHEN sast_time BETWEEN '12:00:00' AND '16:59:59' THEN 'Afternoon Viewer'
      WHEN sast_time BETWEEN '17:00:00' AND '20:59:59' THEN 'Evening Viewer'
      ELSE 'Night Viewer'
    END AS viewer_type
  FROM base
)

SELECT
  viewer_type,
  channel,
  COUNT(user_id) AS viewers,
  MIN(sast_date) AS min_view_date,
  MAX(sast_date) AS max_view_date
FROM enriched
GROUP BY viewer_type, channel
ORDER BY viewers DESC;
--- Kill switch--

  WITH users AS (
  SELECT
    CAST(UserID AS INT) AS user_id,

    CASE
      WHEN Gender IS NULL OR trim(Gender) = '' THEN 'None'
      WHEN Race IS NULL OR trim(Race) = '' THEN 'None'
      WHEN Race  = '' THEN 'None'
     WHEN Race  = ' ' THEN 'None'

      ELSE Gender
    END AS gender,

    COALESCE(Race,' ','None') AS Race,
    COALESCE(Province, 'None') AS province,

    CAST(Age AS INT) AS age,

    CASE
      WHEN Age IS NULL THEN 'Nono'
      WHEN Age < 13 THEN 'Child'
      WHEN Age BETWEEN 13 AND 18 THEN 'Teenager'
      WHEN Age BETWEEN 19 AND 30 THEN 'Young Adult'
      WHEN Age BETWEEN 31 AND 50 THEN 'Adult'
      WHEN Age BETWEEN 51 AND 65 THEN 'Middle Aged'
      WHEN Age >= 66 THEN 'Senior'
      ELSE 'Other'
    END AS age_group
  FROM bright_tv_user_profiles
),

viewership AS (
  SELECT
    CAST(UserID0 AS INT) AS user_id,
    COALESCE(Channel2, 'None') AS channel,

    -- Original UTC timestamp
    RecordDate2 AS utc_ts,

    -- Convert UTC to SAST
    from_utc_timestamp(RecordDate2, 'Africa/Johannesburg') AS sast_ts,

    -- Separate SAST date & time
    DATE(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) AS sast_date,
    DATE_FORMAT(
      from_utc_timestamp(RecordDate2, 'Africa/Johannesburg'),
      'HH:mm:ss'
    ) AS sast_time,

    -- (Optional) Day name (useful for reporting)
    DATE_FORMAT(
      from_utc_timestamp(RecordDate2, 'Africa/Johannesburg'),
      'EEEE'
    ) AS day_of_week,

    -- Day number with Monday as 1 and Sunday as 7
    CASE
      WHEN DAYOFWEEK(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) = 1
        THEN 7
      ELSE DAYOFWEEK(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) - 1
    END AS day_of_week_num_mon_start,

    -- Viewer time of day classification
    CASE
      WHEN DATE_FORMAT(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
           BETWEEN '05:00:00' AND '11:59:59'
        THEN 'Morning Viewer'
      WHEN DATE_FORMAT(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
           BETWEEN '12:00:00' AND '16:59:59'
        THEN 'Afternoon Viewer'
      WHEN DATE_FORMAT(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
           BETWEEN '17:00:00' AND '20:59:59'
        THEN 'Evening Viewer'
      ELSE 'Night Viewer'
    END AS viewer_type
  FROM bright_tv_viewership
)

SELECT
  v.user_id,

  -- Viewership info
  v.channel,
  v.utc_ts,
  v.sast_ts,
  v.sast_date,
  v.sast_time,
  v.day_of_week,
  v.day_of_week_num_mon_start,
  v.viewer_type,

  -- User attributes
  u.gender,
  u.race,
  u.province,
  u.age,
  u.age_group

FROM viewership v
LEFT JOIN users u
  ON v.user_id = u.user_id;
--k--

WITH users AS (
  SELECT
    CAST(UserID AS INT) AS user_id,

    -- Clean Gender (NULL or blank -> None)
    CASE
      WHEN Gender IS NULL OR trim(Gender) = '' THEN 'None'
      ELSE Gender
    END AS gender,

    -- Clean Race (NULL or blank -> None)
    CASE
      WHEN Race IS NULL OR trim(Race) = '' THEN 'None'
      ELSE Race
    END AS race,

    -- Flag rows where Race is NULL/blank in the source (to FIND blanks)
    CASE
      WHEN Race IS NULL OR trim(Race) = '' THEN 1
      ELSE 0
    END AS is_race_blank,

    -- Clean Province (NULL or blank -> None)
    CASE
      WHEN Province IS NULL OR trim(Province) = '' THEN 'None'
      ELSE Province
    END AS province,

    CAST(Age AS INT) AS age,

    CASE
      WHEN Age IS NULL THEN 'None'
      WHEN Age < 13 THEN 'Child'
      WHEN Age BETWEEN 13 AND 18 THEN 'Teenager'
      WHEN Age BETWEEN 19 AND 30 THEN 'Young Adult'
      WHEN Age BETWEEN 31 AND 50 THEN 'Adult'
      WHEN Age BETWEEN 51 AND 65 THEN 'Middle Aged'
      WHEN Age >= 66 THEN 'Senior'
      ELSE 'Other'
    END AS age_group
  FROM bright_tv_user_profiles
),

viewership AS (
  SELECT
    CAST(UserID0 AS INT) AS user_id,
    COALESCE(Channel2, 'None') AS channel,

    -- Original UTC timestamp
    RecordDate2 AS utc_ts,

    -- Convert UTC to SAST
    from_utc_timestamp(RecordDate2, 'Africa/Johannesburg') AS sast_ts,

    -- Separate SAST date & time
    DATE(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) AS sast_date,
    DATE_FORMAT(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg'), 'HH:mm:ss') AS sast_time,

    -- Day name
    DATE_FORMAT(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg'), 'EEEE') AS day_of_week,

    -- Day number Monday=1 ... Sunday=7
    CASE
      WHEN DAYOFWEEK(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) = 1 THEN 7
      ELSE DAYOFWEEK(from_utc_timestamp(RecordDate2, 'Africa/Johannesburg')) - 1
    END AS day_of_week_num_mon_start,

    -- Viewer time of day classification
    CASE
      WHEN DATE_FORMAT(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
           BETWEEN '05:00:00' AND '11:59:59' THEN 'Morning Viewer'
      WHEN DATE_FORMAT(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
           BETWEEN '12:00:00' AND '16:59:59' THEN 'Afternoon Viewer'
      WHEN DATE_FORMAT(from_utc_timestamp(RecordDate2,'Africa/Johannesburg'),'HH:mm:ss')
           BETWEEN '17:00:00' AND '20:59:59' THEN 'Evening Viewer'
      ELSE 'Night Viewer'
    END AS viewer_type
  FROM bright_tv_viewership
)

SELECT
  v.user_id,

  -- Viewership info
  v.channel,
  v.utc_ts,
  v.sast_ts,
  v.sast_date,
  v.sast_time,
  v.day_of_week,
  v.day_of_week_num_mon_start,
  v.viewer_type,

  -- User attributes
  u.gender,
  u.race,
  u.is_race_blank,
  u.province,
  u.age,
  u.age_group

FROM viewership v
LEFT JOIN users u
  ON v.user_id = u.user_id

;



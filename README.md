<H1> GeoForecast (COP3530 - Project 3) </h1>
The world's least reasonable whether forecasting service! Predict the temperature at any date/time at any point in the continential US by utilizing over 250,000 records of data collected by a Tesla Model 3 while on multiple cross-country roadtrips. Want a more refined prediction? Simply ask us to drive to your desired location and your prediction will be improved. Easy!


<h2> Table of Contents </h2>

- [Usage](#usage)
- [Examples and Comparisons](#examples-and-comparisons)
- [Data Used](#data-used)
- [Video Demonstration](#video-demonstration)
- [Running GeoForecast](#running-geoforecast)
	- [Dependencies](#dependencies)
  	- [Getting Up and Running](#getting-up-and-running)

# Usage
Below is the starting page of GeoForecast. On this page, you can specify the following:
- the location of your requested temperature prediction (or input specific latitude and longitude coordinates)
- (optionally) the inital search radius in meters (defaults to 2,000m // 2km // 1.2 miles)
- the date of your requested temperature prediction (click the calendar icon or manually input, defaults to current date)
- the time of your requested temperature prediction (click the clock icon or manually input, defaults to current time)
- the sorting method (slightly affects performance, both can be selected at the same time for comparison (see server logs for times), defaults to heap sort)
- to show extra data for debugging purposes

Click "Get Forecast" to generate your temperature prediction. _Note that computation time varies dramatically based on number of nearby records and distance to the closest record._

<img width="1440" alt="image" src="https://github.com/1ptqc-KD-97bsBG-pVJG/COP3530-Project3/assets/76831037/1d6418e7-3283-40f5-b032-c9dc6e4ad670">

Once your temperature prediction has been computed, it will be displayed prominently on the below page. GeoForecast will also list the following information about your temperature prediction:
- the user specified date and time of the temperature prediction
- a confidence level, generated using a custom algorithm that takes into account amount of nearby data, amount of relevant (filtered) nearby data, physical distance to nearby data, temporal distance to relevant data, and more.
- the number of nearby datapoints (records)
- the number of relevant (filtered) datapoints (a subset of the nearby datasets, obtained using a complex custom filtering algorithm that determines relevance by based on day of the year / season and time of day
- a map of the first 1,000 nearby and relevant datapoints (blue), along with the user-specified point that was used to generate the temperature prediction (red)

To generate another temperature prediction, click the "New Search" button at the bottom of the screen.

![image](https://github.com/1ptqc-KD-97bsBG-pVJG/COP3530-Project3/assets/76831037/2efd4823-7b90-4f45-b5b1-0bfa1ea9ff0f)

# Examples and Comparisons
Below are a handful of examples of GeoForecast's temperature predictions from across the country, along with Google's prediction of the weather at the same loctation / time.

<img width="1254" alt="image" src="https://github.com/1ptqc-KD-97bsBG-pVJG/COP3530-Project3/assets/76831037/a1fcf7fc-335b-4c20-826e-9f0176928685">

<img width="1258" alt="image" src="https://github.com/1ptqc-KD-97bsBG-pVJG/COP3530-Project3/assets/76831037/c0b1383e-9ab5-4b1c-b92d-34a26aa1842f">

<img width="1230" alt="image" src="https://github.com/1ptqc-KD-97bsBG-pVJG/COP3530-Project3/assets/76831037/fd92395c-a385-4005-86f7-c054ef4f6122">

<img width="1261" alt="image" src="https://github.com/1ptqc-KD-97bsBG-pVJG/COP3530-Project3/assets/76831037/15ea1201-4cd4-4e7d-8e69-64f7613365fa">

<img width="1250" alt="image" src="https://github.com/1ptqc-KD-97bsBG-pVJG/COP3530-Project3/assets/76831037/f2193ba0-ae41-4f07-b15a-27e3d8e7535b">

# Data Used
GeoForecast uses data from a 2018 Tesla Model 3, process and stored by the service TeslaFi. Below is a map of GeoForecast's data, darker blue represents a higher concentration of data. The data is provided on this repository in the file: "cleaned_output.csv"

<img width="1184" alt="image" src="https://github.com/1ptqc-KD-97bsBG-pVJG/COP3530-Project3/assets/76831037/43a116bd-f5ea-40ca-ad67-f387bb0ff0c4">

# Video Demonstration
A video demonstration of this project can be found at this link: https://youtu.be/2ILcIZTztTw

# Running GeoForecast
## Dependencies
GeoForecast is a Ruby on Rails webapp with additional dependencies. Below is a list of each and its respective version. It is reccommended to use the specified version as others have not been tested and cannot be guaranteed to work.
- Ruby (3.0.4)
- Rails (7.0.8)
- PostgreSQL (14)
- PostGIS
	- Requires xCode and Xcode Command Line Tools on MacOS
- Bootstrap (installation not required)

## Getting Up and Running
GeoForecast is a relatively standard Rails 7 app. After installing all required dependencies:
- Create a database using `rails db:create`, the migrate using `rails db:migrate`
	- Note that the default database user for development is: "postgres" with a password of "password", ensure this user exists and has superuser privilages
 - Run the rake file "import.rake" using this command: `bundle exec rake db:import_temperature_records`
	- This will convert the raw text data in "cleaned_output.csv" into point objects using PostGIS. This process will take approximately 10 minutes.
 - Start the Rails server using `rails s`
 - Navigate to "localhost:3000"
 - Have fun predicting temperatures with GeoForecast!
 - Remove all other weather forecasting apps from your life and rely entirely on GeoForecast.

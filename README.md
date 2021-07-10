Original App Design Project - README Template
===

# Nostalgia

## Table of Contents
1. [Overview](#Overview)
1. [Product Spec](#Product-Spec)
1. [Wireframes](#Wireframes)
2. [Schema](#Schema)

## Overview
### Description

An itinerary planning app - input various destinations on a map and receive the fastest way to travel through all of them. You can input specific times for the start and end as well as fix times for certain locations (for reservations, etc.). These itineraries will be saved as trips that you can look back on later. The itineraries can be shared or made collaborative so that they can be shared with other users and have the destinations edited, etc. Itineraries for a certain location will be saved on a public database that can be accessed by all users who are looking for something to do in a city. 

Optional:
Saved trips will also keep track of your actual location during the trip and will show you a side by side of planned vs actual trips. Can also access your camera roll and show you pictures that were taken in each location during the trip. 

### App Evaluation
[Evaluation of your app across the following attributes]
- **Category:** Travel, Social
- **Mobile:** maps, camera, location, audio
- **Story:** Allows users to plan their travels with ease, search for itineraries in new locations, and can and recount their experiences in the future.
- **Market:** Anyone that takes pictures and travels would enjoy this app. Ability to share trips with friends and make collaborative trips allows users to create an efficient plan for a group trip.
- **Habit:** Users are saved the time of having to plan anytime they go somewhere, which is a useful feature that warrants reuse. 
- **Scope:** Can input destinations and times and receive a schedule for the day. Can also see an actaul map of their journey as well as pictures that were taken.

## Product Spec

### 1. User Stories (Required and Optional)

**Required Must-have Stories**

* User can create a new account
* User can login
* User can input destinations/reservations and receive an itinerary based on stops and travel times for the day
* User can create colaborative trips where multiple people can edit stops
* User can view trip destinations/times/details on a map
* User can view a list of all their future and past trips

**Optional Nice-to-have Stories**

* User can search for destinations in a certain city
* User can search for other itineraries made for that city
* User can add photos to each location in a trip/ have them taken from their camera roll and added automatically
* User can track their actual movement during the trip versus their planned journey
* User can see what songs they were listening to during trips
* User can add journal entries for days/locations
* User can add calender integration
* User can receive reminders to stick to times on itinerary

### 2. Screen Archetypes

* Login Screen
    * User can login
* Registration Screen
    * User can create a new account
* Map View
    * User can view trips on map screen
* Home Screen
    * Can view all created trips
* Creation Screen
    * Can create a new trip and share with others
* Search Screen
    * Can search for destinations, locations and other users
* Location Screen
    * Shows details for a certain location, can add destination to trip from here
* Profile Screen
    * View your own profile/others profiles

### 3. Navigation

**Tab Navigation** (Tab to Screen)

* Search (for other users)
* Map
* Profile

**Flow Navigation** (Screen to Screen)

* Search
   * User
   * Location
* Profile
    * Settings
* Home
   * Creation
   * Map
* Login
   * Registration

## Wireframes
<img src="/wireframe.png" width=600>

### [BONUS] Digital Wireframes & Mockups

### [BONUS] Interactive Prototype

## Schema 

### Models
User

| Property | Type | Description |
| --- | --- | --- |
| Name | String | name of user |
| ID | String | unique identifier for each user |
| Username | String | used by other users to find each other on app |
| Future Trips | Array | an array of planned trips stored in trip objects |
| Past Trips | Array | an array of past trips stored in trip objects |

Trip

| Property | Type | Description |
| --- | --- | --- |
| Name | String | name of trip |
| ID | String | unique identifier for each trip |
| Destinations | Array | an array of destination objects that represent the stops on each trip |
| Owner | User | the person who created the trip |
| Users | Array | an array of user objects that represent who is shared on the trip |
| Location | JSON Object | location of the broader geographical area in which this trip takes place | 

Destination

| Property | Type | Description |
| --- | --- | --- |
| Name | String | name of destination |
| Order | Number | order of destination in trip |
| Time | DateTime | scheduled time of destination on trip | 
| Details | String | url to yelp page |
| Fixed | Boolean | whether or not the time of the destination needs to be fixed (not changed) |
| Location | JSON Object | location of the destination | 


### Networking

## Network Request By Screen

* Home Screen
   * (GET) Fetching all posts for a user
* Creation Screen
   * (POST) Create a new trip
   * (POST) Create a new destination for trip
   * (PUT) Add new users to a trip
   * (PUT) Add new destinations to a trip
   * (PUT) Change the order of destinations
   * (PUT) Make a destination fixed
* Login Screen
   * (GET) Fetch user logging in
* Registration Screen
   * (POST) Create new user
* Map View
   * (GET) Get trip
   * (GET) Get destinations for trip
* Search Screen
   * (GET) Fetch location info from API
* Location Screen
   * (GET) Fetch location info from API
* Profile Screen
   * (PUT) Update user info

- [Create basic snippets for each Parse network request]
- [OPTIONAL: List endpoints if using existing API such as Yelp]

#!/bin/bash

# Define the base URL for the Flask API
BASE_URL="http://localhost:5000/api"

# Flag to control whether to echo JSON output
ECHO_JSON=false

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    --echo-json) ECHO_JSON=true ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done


###############################################
#
# Health checks
#
###############################################

# Function to check the health of the service
check_health() {
  echo "Checking health status..."
  curl -s -X GET "$BASE_URL/health" | grep -q '"status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Service is healthy."
  else
    echo "Health check failed."
    exit 1
  fi
}

# Function to check the database connection
check_db() {
  echo "Checking database connection..."
  curl -s -X GET "$BASE_URL/db-check" | grep -q '"database_status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Database connection is healthy."
  else
    echo "Database check failed."
    exit 1
  fi
}


##########################################################
#
# Meals
#
##########################################################

create_meal() {
  meal=$1
  cuisine=$2
  price=$3
  difficulty=$4

  echo "Adding meal ($meal - $cuisine, $price, $difficulty) to the meal catalog..."
  curl -s -X POST "$BASE_URL/create-meal" -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price, \"difficulty\":\"$difficulty\"}" | grep -q '"status": "success"'

  if [ $? -eq 0 ]; then
    echo "Meal added successfully."
  else
    echo "Failed to add meal."
    exit 1
  fi
}

clear_meals() {
  echo "Clearing the meals..."
  curl -s -X DELETE "$BASE_URL/clear-meals" | grep -q '"status": "success"'
}

delete_meal_by_id() {
  meal_id=$1

  echo "Deleting song by ID ($meal_id)..."
  response=$(curl -s -X DELETE "$BASE_URL/delete-meal/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal deleted successfully by ID ($meal_id)."
  else
    echo "Failed to delete song by ID ($meal_id)."
    exit 1
  fi
}

# get_all_songs() {
#   echo "Getting all songs in the playlist..."
#   response=$(curl -s -X GET "$BASE_URL/get-all-songs-from-catalog")
#   if echo "$response" | grep -q '"status": "success"'; then
#     echo "All songs retrieved successfully."
#     if [ "$ECHO_JSON" = true ]; then
#       echo "Songs JSON:"
#       echo "$response" | jq .
#     fi
#   else
#     echo "Failed to get songs."
#     exit 1
#   fi
# }

get_meal_by_id() {
  meal_id=$1

  echo "Getting meal by ID ($meal_id)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-id/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by ID ($meal_id)."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (ID $meal_id):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by ID ($meal_id)."
    exit 1
  fi
}

get_meal_by_name() {
  meal_name=$1

  echo "Getting meal by name (name: '$meal_name')..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-name/$meal_name")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by name."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (by name):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by name."
    exit 1
  fi
}

# get_random_song() {
#   echo "Getting a random song from the catalog..."
#   response=$(curl -s -X GET "$BASE_URL/get-random-song")
#   if echo "$response" | grep -q '"status": "success"'; then
#     echo "Random song retrieved successfully."
#     if [ "$ECHO_JSON" = true ]; then
#       echo "Random Song JSON:"
#       echo "$response" | jq .
#     fi
#   else
#     echo "Failed to get a random song."
#     exit 1
#   fi
# }


############################################################
#
# Battle
#
############################################################

# add_song_to_playlist() {
#   artist=$1
#   title=$2
#   year=$3

#   echo "Adding song to playlist: $artist - $title ($year)..."
#   response=$(curl -s -X POST "$BASE_URL/add-song-to-playlist" \
#     -H "Content-Type: application/json" \
#     -d "{\"artist\":\"$artist\", \"title\":\"$title\", \"year\":$year}")

#   if echo "$response" | grep -q '"status": "success"'; then
#     echo "Song added to playlist successfully."
#     if [ "$ECHO_JSON" = true ]; then
#       echo "Song JSON:"
#       echo "$response" | jq .
#     fi
#   else
#     echo "Failed to add song to playlist."
#     exit 1
#   fi
# }

# remove_song_from_playlist() {
#   artist=$1
#   title=$2
#   year=$3

#   echo "Removing song from playlist: $artist - $title ($year)..."
#   response=$(curl -s -X DELETE "$BASE_URL/remove-song-from-playlist" \
#     -H "Content-Type: application/json" \
#     -d "{\"artist\":\"$artist\", \"title\":\"$title\", \"year\":$year}")

#   if echo "$response" | grep -q '"status": "success"'; then
#     echo "Song removed from playlist successfully."
#     if [ "$ECHO_JSON" = true ]; then
#       echo "Song JSON:"
#       echo "$response" | jq .
#     fi
#   else
#     echo "Failed to remove song from playlist."
#     exit 1
#   fi
# }

# remove_song_by_track_number() {
#   track_number=$1

#   echo "Removing song by track number: $track_number..."
#   response=$(curl -s -X DELETE "$BASE_URL/remove-song-from-playlist-by-track-number/$track_number")

#   if echo "$response" | grep -q '"status":'; then
#     echo "Song removed from playlist by track number ($track_number) successfully."
#   else
#     echo "Failed to remove song from playlist by track number."
#     exit 1
#   fi
# }

# clear_playlist() {
#   echo "Clearing playlist..."
#   response=$(curl -s -X POST "$BASE_URL/clear-playlist")

#   if echo "$response" | grep -q '"status": "success"'; then
#     echo "Playlist cleared successfully."
#   else
#     echo "Failed to clear playlist."
#     exit 1
#   fi
# }


############################################################
#
# Leaderboard
#
############################################################

get_meal_leaderboard() {
  echo "Getting meal leaderboard sorted by by wins, battles, or win percentage"
  response=$(curl -s -X GET "$BASE_URL/leaderboard")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal leaderboard retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Leaderboard JSON (sorted by wins):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get song leaderboard."
    exit 1
  fi
}


# Health checks
check_health
check_db

# Clear the catalog
clear_meals

# Create meals
create_meal "Tacos" "Mexican" 10 "MED"
create_meal "Pizza" "Italian" 15 "LOW" 
create_meal "Dumpling" "Chinese" 12 "LOW"
create_meal "Hamburger" "American" 6 "LOW"
create_meal "Pho" "Vietnamese" 15 "MED"
# create_meal "The Beatles" "Let It Be" 1970 "Rock" 180
# create_meal "Queen" "Bohemian Rhapsody" 1975 "Rock" 180
# create_mea "Led Zeppelin" "Stairway to Heaven" 1971 "Rock" 180

delete_meal_by_id 1

get_meal_by_id 2


get_meal_by_name "Pizza"
# get_random_song

# clear_playlist

# add_song_to_playlist "The Rolling Stones" "Paint It Black" 1966
# add_song_to_playlist "Queen" "Bohemian Rhapsody" 1975
# add_song_to_playlist "Led Zeppelin" "Stairway to Heaven" 1971
# add_song_to_playlist "The Beatles" "Let It Be" 1970

# remove_song_from_playlist "The Beatles" "Let It Be" 1970
# remove_song_by_track_number 2

# get_all_songs_from_playlist

# add_song_to_playlist "Queen" "Bohemian Rhapsody" 1975
# add_song_to_playlist "The Beatles" "Let It Be" 1970

# move_song_to_beginning "The Beatles" "Let It Be" 1970
# move_song_to_end "Queen" "Bohemian Rhapsody" 1975
# move_song_to_track_number "Led Zeppelin" "Stairway to Heaven" 1971 2
# swap_songs_in_playlist 1 2

# get_all_songs_from_playlist
# get_song_from_playlist_by_track_number 1

# get_playlist_length_duration

# play_current_song
# rewind_playlist

# play_entire_playlist
# play_current_song
# play_rest_of_playlist

get_meal_leaderboard

echo "All tests passed successfully!"

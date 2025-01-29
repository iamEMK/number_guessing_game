#!/bin/bash

# Connect to PostgreSQL
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
TRIES=0

# Get username
echo "Enter your username:"
read USERNAME

# Check if username exists in database
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")
if [[ -z $USER_INFO ]]
then
  # If user doesn't exist, create new user
  INSERT_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # If user exists, get their stats
  echo "$USER_INFO" | while IFS="|" read GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi
# Start the game
echo "Guess the secret number between 1 and 1000:"

while true; do
  read GUESS
  
  # Check if input is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi
  # Increment tries
  ((TRIES++))

  # Check guess
  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    echo "You guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
    
    # Update user statistics
    if [[ -z $USER_INFO ]]
    then
      # First game for new user
      UPDATE_STATS=$($PSQL "UPDATE users SET games_played = 1, best_game = $TRIES WHERE username = '$USERNAME'")
    else
      # Update existing user's stats
      echo "$USER_INFO" | while IFS="|" read GAMES_PLAYED BEST_GAME
      do
        if [[ $BEST_GAME -eq 0 || $TRIES -lt $BEST_GAME ]]
        then
          BEST_GAME=$TRIES
        fi
        ((GAMES_PLAYED++))
        UPDATE_STATS=$($PSQL "UPDATE users SET games_played = $GAMES_PLAYED, best_game = $BEST_GAME WHERE username = '$USERNAME'")
      done
    fi
    break
  elif [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  else
    echo "It's lower than that, guess again:"
  fi
done
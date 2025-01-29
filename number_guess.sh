#!/bin/bash

# Create database if it doesn't exist
if ! psql -U freecodecamp -lqt | cut -d \| -f 1 | grep -qw number_guess; then
  createdb -U freecodecamp number_guess
fi

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Create users table if not exists
$PSQL "CREATE TABLE IF NOT EXISTS users (
  username VARCHAR(22) PRIMARY KEY,
  games_played INT DEFAULT 0,
  best_game INT
);"

echo "Enter your username:"
read username

# Escape single quotes for SQL
escaped_username=$(echo "$username" | sed "s/'/''/g")

# Check if user exists
user_info=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$escaped_username'")

if [[ -z $user_info ]]; then
  echo "Welcome, $username! It looks like this is your first time here."
else
  IFS='|' read -r games_played best_game <<< "$user_info"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

secret_number=$(( RANDOM % 1000 + 1 ))
number_of_guesses=0
next_prompt="initial"

while true; do
  case $next_prompt in
    initial) echo "Guess the secret number between 1 and 1000:" ;;
    higher) echo "It's higher than that, guess again:" ;;
    lower) echo "It's lower than that, guess again:" ;;
    invalid) echo "That is not an integer, guess again:" ;;
  esac

  read guess
  ((number_of_guesses++))
  
  if [[ ! $guess =~ ^-?[0-9]+$ ]]; then
    next_prompt="invalid"
    continue
  fi

  if [[ $guess -eq $secret_number ]]; then
    break
  elif [[ $guess -lt $secret_number ]]; then
    next_prompt="higher"
  else
    next_prompt="lower"
  fi
done

echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"

# Update user stats
if [[ -z $user_info ]]; then
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES ('$escaped_username', 1, $number_of_guesses)" >/dev/null
else
  $PSQL "UPDATE users SET games_played = games_played + 1, best_game = LEAST(best_game, $number_of_guesses) WHERE username='$escaped_username'" >/dev/null
fi